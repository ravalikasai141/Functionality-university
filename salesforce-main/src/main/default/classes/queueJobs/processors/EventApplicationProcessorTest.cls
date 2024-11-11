@isTest
public class EventApplicationProcessorTest {
    static Id accountRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
        .get('Student_Account')
        .getRecordTypeId();

    static Id opportunityApprenticeApplicationRecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName()
        .get('Apprentice_Application')
        .getRecordTypeId();

    static Id opportunityStudentInterestRecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName()
        .get('Student_Interest')
        .getRecordTypeId();

    static String TEST_APPLICANT_ID = '1';
    static String TEST_APPLICATION_ID = 'cd6a04b6-9990-4e30-8421-5ed7819c13c9';
    static String TEST_APPLICATION_ID2 = 'cd6a04b6-9990-4e30-8421-5ed7819c13c8';
    static String TEST_COUNTRY_CODE = 'GB';
    static String EXPECTED_ONE_SUCCESS = 'Expected one successful job';
    static String EXPECTED_NO_FAILURES = 'Expected no failed jobs';

    static String TEST_QUAL_SUBJECT = 'Afrikaans';
    static String TEST_QUAL_TYPE = 'BTEC Extended Certificate (NQF/ASL)';
    static String TEST_QUAL_INSTITUTION = 'Abbey College, Manchester';

    static final String TEST_SPONSOR_NULL_ASSERT = 'Sponsor field should not be populated as Event Tuition was SELF_FUND.';
    static final String TEST_RECORD_SOURCE_ASSERT = 'Created Opportunity Record Source should equal "Join".';

    @TestSetup
    static void setup() {
        AssignmentUsers__c assignmentUser = new AssignmentUsers__c();
        assignmentUser.Default_Admissions_Owner__c = UserInfo.getUserId().left(15);
        insert assignmentUser;

        List<Owner_Assignment__c> ownerAssignmentList = new List<Owner_Assignment__c>();
        Id userId = [
            SELECT Id
            FROM User
            WHERE UserRole.Name = 'Sales Team [+Record Assignment]' AND IsActive = TRUE
            ORDER BY Name
            LIMIT 1
        ]
        .Id;
        Id admissionsUserId = [
            SELECT Id
            FROM User
            WHERE UserRole.Name = 'Domestic Team [+Record Assignment]' AND IsActive = TRUE
            ORDER BY Name
            LIMIT 1
        ]
        .Id;
        ownerAssignmentList.add(
            new Owner_Assignment__c(Name = 'Sales Team [+Record Assignment]', Last_Assignee__c = userId)
        );
        ownerAssignmentList.add(
            new Owner_Assignment__c(Name = 'Domestic Team [+Record Assignment]', Last_Assignee__c = admissionsUserId)
        );

        insert ownerAssignmentList;

        insert new Account(FirstName = 'Test', LastName = 'Test', RecordTypeId = accountRecordTypeId);
        Account acc = [SELECT Id, PersonContactId FROM Account WHERE LastName = 'Test'];

        Opportunity opp = new Opportunity(
            Name = 'Test-Opp',
            Application_Id__c = TEST_APPLICATION_ID2,
            AccountId = acc.Id,
            StageName = 'Application',
            RecordTypeId = opportunityApprenticeApplicationRecordTypeId,
            CloseDate = Date.today()
        );
        insert opp;

        insert new KSB__c(
            Code__c = 'existing-test-1',
            Question__c = 'existing-question-1',
            Answer__c = '1',
            Experience_Information__c = 'existing experience 1 test',
            Opportunity__c = opp.Id
        );

        insert new KSB__c(
            Code__c = 'test-2',
            Question__c = 'existing-question-2',
            Answer__c = '2',
            Experience_Information__c = 'existing experience 2 test',
            Opportunity__c = opp.Id
        );

        insert new Hub_Account__c(
            Auth0_Id__c = TEST_APPLICANT_ID,
            Student__c = acc.Id,
            Hub_Username__c = 'test@test.com'
        );

        insert new Country_List__c(
            country_code_2__c = TEST_COUNTRY_CODE,
            Valid_Nationality__c = true,
            Name = 'Great Britain'
        );

        List<Qualification_Type__c> typeQualifications = new List<Qualification_Type__c>{
            new Qualification_Type__c(Type_Code__c = '1A', Name = TEST_QUAL_TYPE),
            new Qualification_Type__c(Type_Code__c = 'GY', Name = '1st4sport Level 3 Certificate in Coaching Tennis')
        };
        insert typeQualifications;

        List<Qualification_Subject__c> subjectQualifications = new List<Qualification_Subject__c>{
            new Qualification_Subject__c(Subject_Code__c = 'A81', Name = TEST_QUAL_SUBJECT),
            new Qualification_Subject__c(Subject_Code__c = '53M', Name = '3D Animation and Multimedia')
        };
        insert subjectQualifications;

        List<Qualification_Institution__c> institutionQualifications = new List<Qualification_Institution__c>{
            new Qualification_Institution__c(Institution_Code__c = '10008891', Name = TEST_QUAL_INSTITUTION),
            new Qualification_Institution__c(Institution_Code__c = '10018028', Name = '24/7 College')
        };
        insert institutionQualifications;

        //Insert two qualifications for test
        insert new Qualification__c(
            Student__c = acc.personContactId,
            Qualification_Date__c = Date.today(),
            Status__c = 'Actual',
            HESA_Grade__c = 'B+',
            Year_Of_Completion__c = '2023',
            Subject_Name__c = TEST_QUAL_SUBJECT,
            Qualification_Type_Name__c = TEST_QUAL_TYPE,
            Qualification_Institution_Name__c = TEST_QUAL_INSTITUTION,
            Qualification_Type__c = typeQualifications[0].Id,
            Qualification_Subject__c = subjectQualifications[0].id,
            Qualification_Institution__c = institutionQualifications[0].id
        );

        Programme__c programme = new Programme__c(Name = 'Test programme');

        insert programme;

        Product2 product = new Product2(
            Name = 'Test Course',
            Programme__c = programme.Id,
            BPP_ProductFactoryID__c = 'test-123',
            Instance_Id__c = 'test-1234',
            Start_Date__c = Date.today(),
            // Provide a location longer than the max length of the Opportunity name field to force trimming
            Location__c = TestUtilities.generateValueOfLength(121)
        );

        insert product;

        insert new PricebookEntry(
            IsActive = true,
            Product2Id = product.Id,
            UnitPrice = 10,
            Pricebook2Id = Test.getStandardPricebookId()
        );
    }

    @isTest
    static void itShouldUpdateAccountWithMatchingOpp() {
        // GIVEN a queue job
        ApplicationSchema eventSchema = createTestSchema();
        eventSchema.productId = 'invalid';
        ApplicationSchema.Address schemaAddress = eventSchema.personalDetails.address;
        ApplicationSchema.EmergencyContact schemaEmerContact = eventSchema.personalDetails.emergencyContact;
        ApplicationSchema.PersonalInfo schemaInfo = eventSchema.personalDetails.personalInfo;
        ApplicationSchema.EqualityAndDiversity schemaEqualityDiversity = eventSchema.backgroundInformation.equalityAndDiversity;
        ApplicationSchema.LineManagerInformation schemaManager = eventSchema.employerInformation.lineManagerInformation;
        ApplicationSchema.CompanyInformation schemaCompany = eventSchema.employerInformation.companyInformation;
        ApplicationSchema.LmrAnswers lineManagerAnswers = eventSchema.LineManagerReviewConfirmation.LmrAnswers;
        ApplicationSchema.CodeDetail countryOfBirth = eventSchema.backgroundInformation.nationality.countryOfBirth;
        ApplicationSchema.CodeDetail countryOfNationality = eventSchema.backgroundInformation.nationality.countryOfNationality;
        ApplicationSchema.CodeDetail countryOfPermanentResidency = eventSchema.backgroundInformation.nationality.countryOfPermanentResidency;

        Queue_Job__c queueJob = new Queue_Job__c(Job_Content__c = JSON.serialize(eventSchema));

        // AND a Hub Account with matching applicantId
        Hub_Account__c hubAccount = [SELECT Id FROM Hub_Account__c WHERE Auth0_Id__c = :TEST_APPLICANT_ID LIMIT 1];
        Assert.isNotNull(hubAccount);

        // AND an Opp with matching ApplicationId
        Account account = [SELECT id FROM Account LIMIT 1];
        insert new Opportunity(
            name = 'Test',
            Application_Id__c = TEST_APPLICATION_ID,
            accountid = account.Id,
            StageName = 'Application',
            CloseDate = Date.today(),
            Application_Reference__c = 'wrong123'
        );

        // AND an address
        Address__c address = new Address__c(Student__c = account.Id, Type__c = 'Home');
        insert address;

        // AND a country with matching ISO code
        Country_List__c country = [SELECT Id FROM Country_List__c WHERE country_code_2__c = :TEST_COUNTRY_CODE LIMIT 1];
        Assert.isNotNull(country);

        // WHEN the event processor is run
        Test.startTest();
        EventApplicationProcessor processor = new EventApplicationProcessor();
        processor.pricebookId = System.Test.getStandardPricebookId();
        processor.processImpl(new List<Queue_Job__c>{ queueJob });
        Test.stopTest();

        // THEN the queue job is successful
        Assert.areEqual(1, processor.successfulJobs.size(), EXPECTED_ONE_SUCCESS);
        Assert.areEqual(0, processor.failedJobs.size(), EXPECTED_NO_FAILURES);

        // AND the account was updated
        List<Account> accountsAfter = [
            SELECT
                id,
                PersonTitle,
                Salutation,
                FirstName,
                LastName,
                Middle_Name__pc,
                PersonEmail,
                Personal_Email__pc,
                PersonMobilePhone,
                PersonBirthdate,
                NI_Number__pc,
                Parent_Guardian_First_Name__pc,
                Parent_Guardian_Last_Name__pc,
                Parent_Guardian_Relationship__pc,
                Parent_Guardian_Mobile__pc,
                Parent_Guardian_Email__pc,
                Emergency_Contact_First_Name__pc,
                Emergency_Contact_Last_Name__pc,
                Emergency_Contact_Relationship__pc,
                Emergency_Contact_Mobile__pc,
                Emergency_Contact_Email__pc,
                Is_Local_Authority_Care__c,
                Care_Experience_Level__c,
                Criminal_conviction_details__c,
                Criminal_Conviction__pc,
                Sexual_Orientation__pc,
                Religion__pc,
                SFDC_Ethnic_Code_Select__pc,
                Gender__pc,
                Gender_Identity__pc,
                SFDC_Country_of_Birth__pc,
                Primary_Nationality__pc,
                Country_of_Residence__pc,
                Primary_Learning_Difficulty__c,
                Secondary_Learning_Difficulty__c,
                Can_inform_employer_is_care_leaver__c,
                Would_like_to_receive_bursary__c,
                Has_been_paid_a_care_leavers_bursary__c,
                Other_Primary_Learning_Difficulty__c,
                Has_Learning_Needs__c,
                Other_Secondary_Learning_Difficulty__c,
                Ethnicity_ESFA__pc,
                Student_Type__pc
            FROM Account
        ];

        Assert.areEqual(1, accountsAfter.size());
        Account accountAfter = accountsAfter[0];

        Assert.areEqual(schemaInfo.title, accountAfter.Salutation);
        Assert.areEqual(schemaInfo.firstName, accountAfter.FirstName);
        Assert.areEqual(schemaInfo.lastName, accountAfter.LastName);
        Assert.areEqual(schemaInfo.middleName, accountAfter.Middle_Name__pc);
        Assert.areEqual(schemaInfo.emailAddress, accountAfter.PersonEmail);
        Assert.areEqual(schemaInfo.emailAddress, accountAfter.Personal_Email__pc);
        Assert.areEqual(schemaInfo.mobilePhone, accountAfter.PersonMobilePhone);
        Assert.areEqual(schemaInfo.dateOfBirth, accountAfter.PersonBirthdate);
        Assert.areEqual(schemaInfo.niNumber, accountAfter.NI_Number__pc);

        // Guardian
        Assert.areEqual(schemaInfo.guardianInfo.firstName, accountAfter.Parent_Guardian_First_Name__pc);
        Assert.areEqual(schemaInfo.guardianInfo.lastName, accountAfter.Parent_Guardian_Last_Name__pc);
        Assert.areEqual(schemaInfo.guardianInfo.relationship, accountAfter.Parent_Guardian_Relationship__pc);
        Assert.areEqual(schemaInfo.guardianInfo.mobilePhone, accountAfter.Parent_Guardian_Mobile__pc);
        Assert.areEqual(schemaInfo.guardianInfo.emailAddress, accountAfter.Parent_Guardian_Email__pc);

        // Emergency Contact
        Assert.areEqual(schemaEmerContact.firstName, accountAfter.Emergency_Contact_First_Name__pc);
        Assert.areEqual(schemaEmerContact.lastName, accountAfter.Emergency_Contact_Last_Name__pc);
        Assert.areEqual(schemaEmerContact.relationship, accountAfter.Emergency_Contact_Relationship__pc);
        Assert.areEqual(schemaEmerContact.mobilePhone, accountAfter.Emergency_Contact_Mobile__pc);
        Assert.areEqual(schemaEmerContact.emailAddress, accountAfter.Emergency_Contact_Email__pc);

        // Equality and Diversity
        Assert.areEqual(
            schemaEqualityDiversity.criminalConvictionDescription,
            accountAfter.Criminal_conviction_details__c
        );
        Assert.areEqual(schemaEqualityDiversity.ethnicity.codeHESA, accountAfter.SFDC_Ethnic_Code_Select__pc);
        Assert.areEqual(schemaEqualityDiversity.ethnicity.codeESFA, accountAfter.Ethnicity_ESFA__pc);
        Assert.areEqual(schemaEqualityDiversity.gender.name, accountAfter.Gender__pc);
        Assert.areEqual(
            schemaEqualityDiversity.isCriminalConviction ? 'Yes' : 'No',
            accountAfter.Criminal_Conviction__pc
        );
        Assert.areEqual(schemaEqualityDiversity.religion.code, accountAfter.Religion__pc);
        Assert.areEqual(schemaEqualityDiversity.sameGenderAsBirth.code, accountAfter.Gender_Identity__pc);
        Assert.areEqual(schemaEqualityDiversity.sexualOrientation.code, accountAfter.Sexual_Orientation__pc);
        Assert.areEqual(
            schemaEqualityDiversity.careExperience.careExperienceLevel,
            accountAfter.Care_Experience_Level__c
        );
        Assert.areEqual(
            schemaEqualityDiversity.careExperience.isLocalAuthorityCare,
            accountAfter.Is_Local_Authority_Care__c
        );
        Assert.areEqual(true, accountAfter.Can_inform_employer_is_care_leaver__c);
        Assert.areEqual(true, accountAfter.Would_like_to_receive_bursary__c);
        Assert.areEqual(true, accountAfter.Has_been_paid_a_care_leavers_bursary__c);

        //Nationality
        Country_List__c birthCode = [
            SELECT Id, country_code_2__c
            FROM Country_List__c
            WHERE Id = :accountAfter.SFDC_Country_of_Birth__pc
            LIMIT 1
        ];

        Country_List__c nationalityCode = [
            SELECT Id, country_code_2__c
            FROM Country_List__c
            WHERE Id = :accountAfter.Primary_Nationality__pc
            LIMIT 1
        ];

        Assert.areEqual(birthCode.country_code_2__c, countryOfBirth.code);
        Assert.areEqual(nationalityCode.country_code_2__c, countryOfNationality.code);
        Assert.areEqual(accountAfter.Country_of_Residence__pc, countryOfPermanentResidency.name);
        Assert.areEqual(accountAfter.Student_Type__pc, 'Domestic');

        //Learning Needs
        Assert.areEqual(
            schemaEqualityDiversity.learningNeeds.primaryDifficulty.code,
            accountAfter.Primary_Learning_Difficulty__c
        );
        Assert.areEqual(schemaEqualityDiversity.learningNeeds.isLearningNeed.name, accountAfter.Has_Learning_Needs__c);
        Assert.areEqual(
            schemaEqualityDiversity.learningNeeds.secondaryDifficultyOther,
            accountAfter.Other_Secondary_Learning_Difficulty__c
        );
        Assert.isNotNull(accountAfter.Secondary_Learning_Difficulty__c);
        Assert.areEqual('Other', accountAfter.Other_Primary_Learning_Difficulty__c);

        Set<String> secondaryLearning = new Set<String>();
        secondaryLearning.addAll(accountAfter.Secondary_Learning_Difficulty__c.split(';'));

        for (ApplicationSchema.CodeDetail learningSchema : schemaEqualityDiversity.learningNeeds.secondaryDifficulty) {
            Assert.isTrue(secondaryLearning.contains(learningSchema.code));
        }

        // AND the Opportunity Address, Line Manager and Company   details were updated
        List<Opportunity> opps = [
            SELECT
                Id,
                Address_Street_1__c,
                Address_Street_2__c,
                Address_City__c,
                Address_Zip_Postal_Code__c,
                Address_Lookup_Country__c,
                Application_Id__c,
                Line_Manager_First_Name__c,
                Line_Manager_Last_Name__c,
                Line_Manager_Email__c,
                Line_Manager_Job_Title__c,
                Line_Manager_Telephone__c,
                Application_Reference__c,
                Company_Street_1__c,
                Company_Street_2__c,
                Company_Street_3__c,
                Company_City__c,
                Company_Zip_Postal_Code__c,
                Company_Lookup_Country__c,
                Product_Id_Text__c,
                Professional_Qualification__c,
                In_role_less_than_nine_months__c,
                Fewer_than_50_employees__c,
                EPA__c,
                EPAO__c,
                Academic_Reference_First_Name__c,
                Academic_Reference_Last_Name__c,
                Academic_Reference_Phone__c,
                Academic_Reference_Email__c,
                Academic_Reference_Relation__c,
                Tuition__c,
                Sponsor_First_Name__c,
                Sponsor_Last_Name__c,
                Sponsor_Email__c,
                Sponsoring_Organization__c,
                Sponsor_Phone__c,
                Sponsoring_Purchase_Order__c,
                Product_Level__c,
                Category__c,
                Section_JSON__c
            FROM Opportunity
            WHERE Application_Id__c = :TEST_APPLICATION_ID
        ];
        Assert.areEqual(1, opps.size());
        Opportunity oppAfter = opps[0];

        Assert.areEqual(eventSchema.productId, oppAfter.Product_Id_Text__c);
        Assert.areEqual(eventSchema.awardingBody, oppAfter.Professional_Qualification__c);
        Assert.areEqual(eventSchema.clientName, oppAfter.Category__c);
        Assert.areEqual(eventSchema.product.EPA, oppAfter.EPA__c);
        Assert.areEqual(eventSchema.product.EPAO, oppAfter.EPAO__c);
        Assert.areEqual(schemaAddress.line1, oppAfter.Address_Street_1__c);
        Assert.areEqual(schemaAddress.line2, oppAfter.Address_Street_2__c);
        Assert.areEqual(schemaAddress.city, oppAfter.Address_City__c);
        Assert.areEqual(schemaAddress.postalCode, oppAfter.Address_Zip_Postal_Code__c);
        Assert.areEqual(country.Id, oppAfter.Address_Lookup_Country__c);
        Assert.areEqual(eventSchema.applicationId, oppAfter.Application_Id__c);
        Assert.areEqual(schemaManager.firstName, oppAfter.Line_Manager_First_Name__c);
        Assert.areEqual(schemaManager.lastName, oppAfter.Line_Manager_Last_Name__c);
        Assert.areEqual(schemaManager.jobTitle, oppAfter.Line_Manager_Job_Title__c);
        Assert.areEqual(schemaManager.emailAddress, oppAfter.Line_Manager_Email__c);
        Assert.areEqual(schemaManager.mobilePhone, oppAfter.Line_Manager_Telephone__c);
        Assert.areEqual('wrong123', oppAfter.Application_Reference__c);
        Assert.areEqual(schemaCompany.line1, oppAfter.Company_Street_1__c);
        Assert.areEqual(schemaCompany.line2, oppAfter.Company_Street_2__c);
        Assert.areEqual(schemaCompany.line3, oppAfter.Company_Street_3__c);
        Assert.areEqual(schemaCompany.city, oppAfter.Company_City__c);
        Assert.areEqual(schemaCompany.postalCode, oppAfter.Company_Zip_Postal_Code__c);
        Assert.areEqual(country.Id, oppAfter.Company_Lookup_Country__c);
        Assert.areEqual(eventSchema.academicReference.firstName, oppAfter.Academic_Reference_First_Name__c);
        Assert.areEqual(eventSchema.academicReference.lastName, oppAfter.Academic_Reference_Last_Name__c);
        Assert.areEqual(eventSchema.academicReference.mobilePhone, oppAfter.Academic_Reference_Phone__c);
        Assert.areEqual(eventSchema.academicReference.emailAddress, oppAfter.Academic_Reference_Email__c);
        Assert.areEqual(eventSchema.academicReference.relationship, oppAfter.Academic_Reference_Relation__c);
        Assert.areEqual('Sponsorship', oppAfter.Tuition__c);
        Assert.areEqual(eventSchema.tuitionFees.sponsorInfo.firstName, oppAfter.Sponsor_First_Name__c);
        Assert.areEqual(eventSchema.tuitionFees.sponsorInfo.lastName, oppAfter.Sponsor_Last_Name__c);
        Assert.areEqual(eventSchema.tuitionFees.sponsorInfo.emailAddress, oppAfter.Sponsor_Email__c);
        Assert.areEqual(eventSchema.tuitionFees.sponsorInfo.organisationName, oppAfter.Sponsoring_Organization__c);
        Assert.areEqual(eventSchema.tuitionFees.sponsorInfo.mobilePhone, oppAfter.Sponsor_Phone__c);
        Assert.areEqual(eventSchema.tuitionFees.sponsorInfo.purchaseOrderNumber, oppAfter.Sponsoring_Purchase_Order__c);
        Assert.areEqual('Yes', oppAfter.In_role_less_than_nine_months__c, 'Expect to be Yes');
        Assert.areEqual('Yes', oppAfter.Fewer_than_50_employees__c, 'Expect to be Yes');
        Assert.areEqual(eventSchema.product.academicLevel, oppAfter.Product_Level__c);

        // AND an address was updated
        List<Address__c> addresses = [
            SELECT
                Id,
                Student__c,
                Active__c,
                Type__c,
                Street_1__c,
                Street_2__c,
                City__c,
                Zip_Postal_Code__c,
                Lookup_Country__c,
                Record_Source__c
            FROM Address__c
        ];

        Assert.areEqual(1, addresses.size());
        Address__c addressAfter = addresses[0];

        Assert.areEqual(address.Id, addressAfter.Id);
        Assert.areEqual(accountAfter.Id, addressAfter.Student__c);
        Assert.areEqual(true, addressAfter.Active__c);
        Assert.areEqual('Home', addressAfter.Type__c);
        Assert.areEqual(schemaAddress.line1, addressAfter.Street_1__c);
        Assert.areEqual(schemaAddress.line2, addressAfter.Street_2__c);
        Assert.areEqual(schemaAddress.city, addressAfter.City__c);
        Assert.areEqual(schemaAddress.postalCode, addressAfter.Zip_Postal_Code__c);
        Assert.areEqual(country.Id, addressAfter.Lookup_Country__c);
        Assert.areEqual('Hub', addressAfter.Record_Source__c);
    }

    @isTest
    static void itShouldCreateOppWithMatchingApplicationType() {
        // GIVEN a queue job
        ApplicationSchema eventSchema = createTestSchema();
        eventSchema.applicationType = 'UNIVERSITY';
        Queue_Job__c queueJob = new Queue_Job__c(Job_Content__c = JSON.serialize(eventSchema));

        Id userId = [
            SELECT Id
            FROM User
            WHERE UserRole.Name = 'Domestic Team [+Record Assignment]' AND IsActive = TRUE
            ORDER BY Name
            LIMIT 1
        ]
        .Id;
        List<Owner_Assignment__c> ownerAssignmentList = new List<Owner_Assignment__c>();
        ownerAssignmentList.add(
            new Owner_Assignment__c(Name = 'Domestic Team [+Record Assignment]', Last_Assignee__c = userId)
        );
        insert ownerAssignmentList;

        // WHEN the event processor is run
        Test.startTest();
        EventApplicationProcessor processor = new EventApplicationProcessor();
        processor.pricebookId = System.Test.getStandardPricebookId();
        processor.processImpl(new List<Queue_Job__c>{ queueJob });
        Test.stopTest();

        // THEN the queue job is successful
        Assert.areEqual(1, processor.successfulJobs.size(), EXPECTED_ONE_SUCCESS);
        Assert.areEqual(0, processor.failedJobs.size(), EXPECTED_NO_FAILURES);

        List<Opportunity> opps = [
            SELECT Id, Application_Id__c, StageName, BPP_Sub_Status__c, RecordTypeId, Record_Source__c
            FROM Opportunity
            WHERE Application_Id__c = :TEST_APPLICATION_ID
        ];
        Assert.areEqual(1, opps.size());
        Opportunity oppAfter = opps[0];

        Assert.areEqual(eventSchema.applicationId, oppAfter.Application_Id__c);
        Assert.areEqual('Application Started', oppAfter.StageName);
        Assert.areEqual('Recent Activity', oppAfter.BPP_Sub_Status__c);
        Assert.areEqual(opportunityStudentInterestRecordTypeId, oppAfter.RecordTypeId);
        Assert.areEqual('Join', oppAfter.Record_Source__c, TEST_RECORD_SOURCE_ASSERT);
    }

    @isTest
    static void itShouldCreateOppForNoMatch() {
        // GIVEN a queue job
        ApplicationSchema eventSchema = createTestSchema();
        eventSchema.tuitionFees.fundingType = 'SELF_FUNDED';

        ApplicationSchema.Address schemaAddress = eventSchema.personalDetails.address;
        ApplicationSchema.PersonalInfo schemaInfo = eventSchema.personalDetails.personalInfo;
        ApplicationSchema.CompanyInformation schemaCompany = eventSchema.employerInformation.companyInformation;

        Queue_Job__c queueJob = new Queue_Job__c(Job_Content__c = JSON.serialize(eventSchema));

        // AND a Hub Account with matching applicantId
        Hub_Account__c hubAccount = [SELECT Id FROM Hub_Account__c WHERE Auth0_Id__c = :TEST_APPLICANT_ID LIMIT 1];
        Assert.isNotNull(hubAccount);

        // WHEN the event processor is run
        Test.startTest();
        EventApplicationProcessor processor = new EventApplicationProcessor();
        processor.pricebookId = System.Test.getStandardPricebookId();
        processor.processImpl(new List<Queue_Job__c>{ queueJob });
        Test.stopTest();

        // THEN the queue job is successful
        Assert.areEqual(1, processor.successfulJobs.size(), EXPECTED_ONE_SUCCESS);
        Assert.areEqual(0, processor.failedJobs.size(), EXPECTED_NO_FAILURES);

        // AND the account was updated
        List<Account> accountsAfter = [SELECT id, FirstName, LastName FROM Account];

        Assert.areEqual(1, accountsAfter.size());
        Account accountAfter = accountsAfter[0];
        Assert.areEqual(schemaInfo.firstName, accountAfter.FirstName);
        Assert.areEqual(schemaInfo.lastName, accountAfter.LastName);

        Product2 product = [
            SELECT Id, Location__c, Start_Date__c, Programme__c, Programme__r.Name
            FROM Product2
            WHERE Name = 'Test Course'
        ];

        // AND an Opportunity was created
        List<Opportunity> opps = [
            SELECT
                Id,
                Name,
                Full_Name__c,
                Address_Street_1__c,
                Address_Street_2__c,
                Address_City__c,
                Address_Zip_Postal_Code__c,
                Address_Lookup_Country__r.country_code_2__c,
                Application_Id__c,
                Course_Instance__c,
                Programme_Application__c,
                Personal_Statement_Body__c,
                Application_Reference__c,
                Professional_Qualification__c,
                EPA__c,
                Tuition__c,
                Sponsor_First_Name__c,
                Sponsor_Last_Name__c,
                Sponsor_Email__c,
                Sponsoring_Organization__c,
                Sponsor_Phone__c,
                Sponsoring_Purchase_Order__c,
                Record_Source__c
            FROM Opportunity
            WHERE Application_Id__c = :TEST_APPLICATION_ID
        ];
        Assert.areEqual(1, opps.size());
        Opportunity oppAfter = opps[0];

        Assert.areEqual(product.Id, oppAfter.Course_Instance__c);
        Assert.areEqual(product.Programme__c, oppAfter.Programme_Application__c);
        Assert.areEqual(schemaAddress.line1, oppAfter.Address_Street_1__c);
        Assert.areEqual(schemaAddress.line2, oppAfter.Address_Street_2__c);
        Assert.areEqual(schemaAddress.city, oppAfter.Address_City__c);
        Assert.areEqual(schemaAddress.postalCode, oppAfter.Address_Zip_Postal_Code__c);
        Assert.areEqual(TEST_COUNTRY_CODE, oppAfter.Address_Lookup_Country__r.country_code_2__c);
        Assert.areEqual(eventSchema.applicationId, oppAfter.Application_Id__c);
        Assert.areEqual(eventSchema.applicationReference, oppAfter.Application_Reference__c);
        Assert.areEqual(eventSchema.awardingBody, oppAfter.Professional_Qualification__c);
        Assert.areEqual(eventSchema.product.EPA, oppAfter.EPA__c);
        Assert.areEqual(
            eventSchema.personalStatement.statement,
            oppAfter.Personal_Statement_Body__c,
            'Personal_Statement_Body__c not populated'
        );
        Assert.areEqual(
            schemaCompany.companyName,
            oppAfter.Sponsoring_Organization__c,
            'Sponsoring Organization field should be populated by Event Company Name as Event Tuition value is not SPONSORSHIP.'
        );
        Assert.areEqual('Self-funded', oppAfter.Tuition__c);
        Assert.isNull(oppAfter.Sponsor_First_Name__c, TEST_SPONSOR_NULL_ASSERT);
        Assert.isNull(oppAfter.Sponsor_Last_Name__c, TEST_SPONSOR_NULL_ASSERT);
        Assert.isNull(oppAfter.Sponsor_Email__c, TEST_SPONSOR_NULL_ASSERT);
        Assert.isNull(oppAfter.Sponsor_Phone__c, TEST_SPONSOR_NULL_ASSERT);
        Assert.isNull(oppAfter.Sponsoring_Purchase_Order__c, TEST_SPONSOR_NULL_ASSERT);
        Assert.areEqual('Join', oppAfter.Record_Source__c, TEST_RECORD_SOURCE_ASSERT);

        // AND an address was created
        List<Address__c> addresses = [
            SELECT
                Id,
                Student__c,
                Active__c,
                Type__c,
                Street_1__c,
                Street_2__c,
                City__c,
                Zip_Postal_Code__c,
                Lookup_Country__r.country_code_2__c,
                Record_Source__c
            FROM Address__c
        ];

        Assert.areEqual(1, addresses.size());
        Address__c address = addresses[0];

        Assert.areEqual(accountAfter.Id, address.Student__c);
        Assert.areEqual(true, address.Active__c);
        Assert.areEqual('Home', address.Type__c);
        Assert.areEqual(schemaAddress.line1, address.Street_1__c);
        Assert.areEqual(schemaAddress.line2, address.Street_2__c);
        Assert.areEqual(schemaAddress.city, address.City__c);
        Assert.areEqual(schemaAddress.postalCode, address.Zip_Postal_Code__c);
        Assert.areEqual(TEST_COUNTRY_CODE, address.Lookup_Country__r.country_code_2__c);
        Assert.areEqual('Hub', address.Record_Source__c);
    }

    @isTest
    static void itShouldFailWhenNoneFound() {
        // GIVEN a queue job
        ApplicationSchema eventSchema = createTestSchema();
        ApplicationSchema.Address schemaAddress = eventSchema.personalDetails.address;
        ApplicationSchema.EmergencyContact schemaEmerContact = eventSchema.personalDetails.emergencyContact;
        ApplicationSchema.PersonalInfo schemaInfo = eventSchema.personalDetails.personalInfo;
        ApplicationSchema.EqualityAndDiversity schemaEqualityDiversity = eventSchema.backgroundInformation.equalityAndDiversity;

        Queue_Job__c queueJob = new Queue_Job__c(Job_Content__c = JSON.serialize(eventSchema));

        // AND no objects to match on exist
        delete [SELECT id FROM Hub_Account__c];
        delete [SELECT id FROM Opportunity];
        delete [SELECT id FROM Account];

        // WHEN the event processor is run
        Test.startTest();
        EventApplicationProcessor processor = new EventApplicationProcessor();
        processor.pricebookId = System.Test.getStandardPricebookId();
        processor.processImpl(new List<Queue_Job__c>{ queueJob });
        Test.stopTest();

        // THEN the queue job failed
        Assert.areEqual(0, processor.successfulJobs.size(), EXPECTED_ONE_SUCCESS);
        Assert.areEqual(1, processor.failedJobs.size(), EXPECTED_NO_FAILURES);
    }

    @isTest
    static void itShouldHandleMissingEventData() {
        // GIVEN a queue job
        Queue_Job__c queueJob = new Queue_Job__c(Job_Content__c = '{}');

        // WHEN the event processor is run
        Test.startTest();
        EventApplicationProcessor processor = new EventApplicationProcessor();
        processor.pricebookId = System.Test.getStandardPricebookId();
        processor.processImpl(new List<Queue_Job__c>{ queueJob });
        Test.stopTest();

        // THEN the queue job has failed
        Assert.areEqual(0, processor.successfulJobs.size(), 'Expected no successful jobs');
        Assert.areEqual(1, processor.failedJobs.size(), 'Expected one failed job');
        Assert.areEqual(
            'Required value(s) Applicant Id, Application Id, Personal Details: First Name, Personal Details: Last Name are null in event payload',
            processor.failedJobs.values()[0],
            'Expected one failed job'
        );
    }

    @isTest
    static void itShouldHandleDuplicateApplicationIds() {
        String applicantIdTwo = '2';

        // GIVEN two Accounts
        Account accountOne = [SELECT Id FROM Account LIMIT 1];

        Account accountTwo = new Account(
            FirstName = 'Old FirstName 1',
            LastName = 'Old LastName 1',
            RecordTypeId = accountRecordTypeId
        );
        insert accountTwo;

        insert new Hub_Account__c(
            Auth0_Id__c = applicantIdTwo,
            Student__c = accountTwo.Id,
            Hub_Username__c = 'Account2@Account2.com'
        );

        // AND two queue jobs
        ApplicationSchema eventSchemaOne = createTestSchema();
        eventSchemaOne.productId = 'invalid';
        eventSchemaOne.applicantId = TEST_APPLICANT_ID;
        eventSchemaOne.personalDetails.personalInfo.firstName = 'FirstName 1';
        eventSchemaOne.personalDetails.address.line1 = 'Personal Address 1';
        eventSchemaOne.employerInformation.companyInformation.line1 = 'Company Address 1';

        ApplicationSchema eventSchemaTwo = createTestSchema();
        eventSchemaTwo.productId = 'invalid';
        eventSchemaTwo.applicantId = applicantIdTwo;
        eventSchemaTwo.personalDetails.personalInfo.firstName = 'FirstName 2';
        eventSchemaTwo.personalDetails.address.line1 = 'Personal Address 2';
        eventSchemaTwo.employerInformation.companyInformation.line1 = 'Company Address 2';

        // AND both events have the same Application Id
        String applicationId = 'Application 1';
        eventSchemaOne.applicationId = applicationId;
        eventSchemaTwo.applicationId = applicationId;

        // AND one the second of the two queue jobs is newer
        Queue_Job__c queueJobOne = new Queue_Job__c(
            Job_Content__c = JSON.serialize(eventSchemaOne),
            Event_Time__c = DateTime.now() - 7
        );

        Queue_Job__c queueJobTwo = new Queue_Job__c(
            Job_Content__c = JSON.serialize(eventSchemaTwo),
            Event_Time__c = DateTime.now()
        );

        // WHEN the event processor is run
        Test.startTest();
        EventApplicationProcessor processor = new EventApplicationProcessor();
        processor.processImpl(new List<Queue_Job__c>{ queueJobOne, queueJobTwo });
        Test.stopTest();

        // THEN both queue jobs are successful
        Assert.areEqual(2, processor.successfulJobs.size(), 'Expected two successful jobs');
        Assert.areEqual(0, processor.failedJobs.size(), EXPECTED_NO_FAILURES);

        // AND only the Account for the latest Event was updated
        Map<String, Account> accountToAuthId = new Map<String, Account>();
        for (Hub_Account__c currentHubAccount : [
            SELECT Auth0_Id__c, Student__r.FirstName
            FROM Hub_Account__c
            ORDER BY Auth0_Id__c
        ]) {
            accountToAuthId.put(currentHubAccount.Auth0_Id__c, currentHubAccount.Student__r);
        }

        Assert.areNotEqual(
            eventSchemaOne.personalDetails.personalInfo.firstName,
            accountToAuthId.get(eventSchemaOne.applicantId).FirstName
        );

        Assert.areEqual(
            eventSchemaTwo.personalDetails.personalInfo.firstName,
            accountToAuthId.get(eventSchemaTwo.applicantId).FirstName
        );

        // AND the Opportunity for the latest Event was created and is linked to the expected Account
        List<Opportunity> opps = [
            SELECT Company_Street_1__c, AccountId
            FROM Opportunity
            WHERE Application_Id__c = 'Application 1'
        ];

        Assert.areEqual(1, opps.size());
        Assert.areEqual(accountToAuthId.get(eventSchemaTwo.applicantId).Id, opps[0].AccountId);
        Assert.areEqual(eventSchemaTwo.employerInformation.companyInformation.line1, opps[0].Company_Street_1__c);

        // AND the Address for the latest Event was updated and is linked to the expected Account
        List<Address__c> addresses = [
            SELECT Street_1__c, Student__c
            FROM Address__c
        ];

        Assert.areEqual(1, addresses.size());
        Assert.areEqual(accountToAuthId.get(eventSchemaTwo.applicantId).Id, addresses[0].Student__c);
        Assert.areEqual(eventSchemaTwo.personalDetails.address.line1, addresses[0].Street_1__c);
    }

    @isTest
    static void itShouldHandleDuplicateApplicantIds() {
        // AND two queue jobs with the same Applicant Id
        ApplicationSchema eventSchemaOne = createTestSchema();
        eventSchemaOne.productId = 'invalid';
        eventSchemaOne.applicationId = 'Application 1';
        eventSchemaOne.personalDetails.personalInfo.firstName = 'FirstName 1';
        eventSchemaOne.personalDetails.address.line1 = 'Personal Address 1';
        eventSchemaOne.employerInformation.companyInformation.line1 = 'Company Address 1';

        ApplicationSchema eventSchemaTwo = createTestSchema();
        eventSchemaTwo.productId = 'invalid';
        eventSchemaTwo.applicationId = 'Application 2';
        eventSchemaTwo.personalDetails.personalInfo.firstName = 'FirstName 2';
        eventSchemaTwo.personalDetails.address.line1 = 'Personal Address 2';
        eventSchemaTwo.employerInformation.companyInformation.line1 = 'Company Address 2';

        // AND one the second of the two queue jobs is newer
        Queue_Job__c queueJobOne = new Queue_Job__c(
            Job_Content__c = JSON.serialize(eventSchemaOne),
            Event_Time__c = DateTime.now() - 7
        );

        Queue_Job__c queueJobTwo = new Queue_Job__c(
            Job_Content__c = JSON.serialize(eventSchemaTwo),
            Event_Time__c = DateTime.now()
        );

        // WHEN the event processor is run
        Test.startTest();
        EventApplicationProcessor processor = new EventApplicationProcessor();
        processor.processImpl(new List<Queue_Job__c>{ queueJobOne, queueJobTwo });
        Test.stopTest();

        // THEN both queue jobs are successful
        Assert.areEqual(2, processor.successfulJobs.size(), 'Expected two successful jobs');
        Assert.areEqual(0, processor.failedJobs.size(), EXPECTED_NO_FAILURES);

        Map<String, Account> accountToAuthId = new Map<String, Account>();
        for (Hub_Account__c currentHubAccount : [
            SELECT Auth0_Id__c, Student__r.FirstName
            FROM Hub_Account__c
            ORDER BY Auth0_Id__c
        ]) {
            accountToAuthId.put(currentHubAccount.Auth0_Id__c, currentHubAccount.Student__r);
        }

        // AND only the Account for the latest Event was updated
        Assert.areEqual(
            eventSchemaTwo.personalDetails.personalInfo.firstName,
            accountToAuthId.get(eventSchemaTwo.applicantId).FirstName
        );

        // AND both Opportunities were created
        List<Opportunity> opps = [
            SELECT Company_Street_1__c, AccountId
            FROM Opportunity
            WHERE Application_Id__c IN ('Application 1', 'Application 2')
        ];

        Assert.areEqual(2, opps.size());
        Assert.areEqual(accountToAuthId.get(eventSchemaOne.applicantId).Id, opps[0].AccountId);
        Assert.areEqual(eventSchemaOne.employerInformation.companyInformation.line1, opps[0].Company_Street_1__c);

        Assert.areEqual(accountToAuthId.get(eventSchemaTwo.applicantId).Id, opps[0].AccountId);
        Assert.areEqual(eventSchemaTwo.employerInformation.companyInformation.line1, opps[1].Company_Street_1__c);

        // AND the Address for the latest Event was updated and is linked to the expected Account
        List<Address__c> addresses = [
            SELECT Street_1__c, Student__c
            FROM Address__c
        ];

        Assert.areEqual(1, addresses.size());
        Assert.areEqual(accountToAuthId.get(eventSchemaTwo.applicantId).Id, addresses[0].Student__c);
        Assert.areEqual(eventSchemaTwo.personalDetails.address.line1, addresses[0].Street_1__c);
    }

    @isTest
    static void itShouldCreateKSBSAgainstTheOpportunity() {
        // GIVEN We have a schema with KSBS
        ApplicationSchema eventSchema = createTestSchema();
        eventSchema.productId = null;
        Queue_Job__c queueJob = new Queue_Job__c(Job_Content__c = JSON.serialize(eventSchema));

        // WHEN the event is processed
        System.Test.startTest();

        EventApplicationProcessor processor = new EventApplicationProcessor();
        processor.processImpl(new List<Queue_Job__c>{ queueJob });

        System.Test.stopTest();

        // THEN I expect new KSBS to be related to the opportunity
        Assert.areEqual(1, processor.successfulJobs.size(), 'Expected a successful job');
        Assert.areEqual(0, processor.failedJobs.size(), EXPECTED_NO_FAILURES);

        Opportunity opp = [SELECT Id FROM Opportunity WHERE Application_Id__c = :TEST_APPLICATION_ID];
        Set<String> ksbCodes = new Set<String>();

        for (KSB__c ksb : [SELECT Code__c FROM KSB__c WHERE Opportunity__c = :opp.Id]) {
            ksbCodes.add(ksb.Code__c);
        }

        Assert.areEqual(2, ksbCodes.size());
        Assert.isTrue(ksbCodes.contains('test-1'));
        Assert.isTrue(ksbCodes.contains('test-2'));
    }

    @isTest
    static void itShouldUpdateKSBSAgainstTheOpportunity() {
        // GIVEN We have a schema with KSBS
        ApplicationSchema eventSchema = createTestSchema();
        eventSchema.productId = null;
        eventSchema.applicationId = TEST_APPLICATION_ID2;
        Queue_Job__c queueJob = new Queue_Job__c(Job_Content__c = JSON.serialize(eventSchema));

        // WHEN the event is processed
        System.Test.startTest();

        EventApplicationProcessor processor = new EventApplicationProcessor();
        processor.processImpl(new List<Queue_Job__c>{ queueJob });

        System.Test.stopTest();

        // THEN I expect new KSBS to be related to the opportunity
        Assert.areEqual(1, processor.successfulJobs.size(), 'Expected a successful job');
        Assert.areEqual(0, processor.failedJobs.size(), EXPECTED_NO_FAILURES);

        Opportunity opp = [SELECT Id FROM Opportunity WHERE Application_Id__c = :TEST_APPLICATION_ID2];
        Map<String, KSB__c> ksbs = new Map<String, KSB__c>();

        for (KSB__c ksb : [
            SELECT Code__c, Answer__c, Experience_Information__c, Question__c
            FROM KSB__c
            WHERE Opportunity__c = :opp.Id
        ]) {
            ksbs.put(ksb.Code__c, ksb);
        }

        Assert.areEqual(3, ksbs.size());
        Assert.isTrue(ksbs.keySet().contains('existing-test-1'));
        Assert.isTrue(ksbs.keySet().contains('test-1'));
        Assert.isTrue(ksbs.keySet().contains('test-2'));
        Assert.areEqual(ksbs.get('test-2').Answer__c, '2');
        Assert.areEqual(ksbs.get('test-2').Question__c, 'question-2');
        Assert.areEqual(ksbs.get('test-2').Experience_Information__c, 'experience 2 test');
    }

    @isTest
    static void itShouldCreateUpdateQualifications() {
        Account account = [SELECT Id, PersonContactId FROM Account WHERE LastName = 'Test'];

        // GIVEN a queue job
        ApplicationSchema eventSchema = createTestSchema();

        List<ApplicationSchema.Qualification> schemaQualifications = eventSchema.educationAndSkills.educationHistory.qualifications;

        Queue_Job__c queueJob = new Queue_Job__c(Job_Content__c = JSON.serialize(eventSchema));

        // WHEN the event processor is run
        System.Test.startTest();
        EventApplicationProcessor processor = new EventApplicationProcessor();
        processor.pricebookId = System.Test.getStandardPricebookId();
        processor.processImpl(new List<Queue_Job__c>{ queueJob });
        System.Test.stopTest();

        // THEN the queue job is successful
        Assert.areEqual(1, processor.successfulJobs.size(), EXPECTED_ONE_SUCCESS);
        Assert.areEqual(0, processor.failedJobs.size(), EXPECTED_NO_FAILURES);

        //AND the Qualifications were synced
        List<Qualification__c> qualifications = [
            SELECT
                Id,
                Student__c,
                HESA_Grade__c,
                Country_of_Study__r.country_code_2__c,
                Qualification_Institution__r.Institution_Code__c,
                Qualification_Subject__r.Subject_Code__c,
                Qualification_Type__r.Type_Code__c,
                Year_Of_Completion__c,
                Examing_Body__c,
                Subject_Name__c
            FROM Qualification__c
            WHERE Student__c = :account.PersonContactId
        ];

        Assert.areEqual(2, qualifications.size());

        for (Integer i = 0; i < schemaQualifications.size(); i++) {
            ApplicationSchema.Qualification schemaQualification;
            if (qualifications[i].Subject_Name__c == TEST_QUAL_SUBJECT) {
                schemaQualification = schemaQualifications[0];
            } else {
                schemaQualification = schemaQualifications[1];
            }

            Assert.areEqual(schemaQualification.grade, qualifications[i].HESA_Grade__c);
            Assert.areEqual(schemaQualification.yearCompletedExpected, qualifications[i].Year_Of_Completion__c);
            Assert.areEqual(schemaQualification.type.code, qualifications[i].Qualification_Type__r.Type_Code__c);
            Assert.areEqual(
                schemaQualification.subject.code,
                qualifications[i].Qualification_Subject__r.Subject_Code__c
            );
            Assert.areEqual(
                schemaQualification.awardingInstitution.code,
                qualifications[i].Qualification_Institution__r.Institution_Code__c
            );
            Assert.areEqual(schemaQualification.examiningBody, qualifications[i].Examing_Body__c);
            Assert.areEqual(schemaQualification.country.code, qualifications[i].Country_of_Study__r.country_code_2__c);
        }
    }

    @isTest
    static void itShouldUpdateEmployeeRoleAgainstOpp() {
        // GIVEN a queue job
        ApplicationSchema eventSchema = createTestSchema();

        ApplicationSchema.Role schemaRole = eventSchema.employerInformation.role;

        Queue_Job__c queueJob = new Queue_Job__c(Job_Content__c = JSON.serialize(eventSchema));

        // AND an Opp with matching ApplicationId
        Account account = [SELECT id FROM Account WHERE LastName = 'Test'];

        insert new Opportunity(
            name = 'Test',
            Application_Id__c = TEST_APPLICATION_ID,
            accountid = account.Id,
            StageName = 'Application',
            CloseDate = Date.today(),
            Application_Reference__c = 'wrong123'
        );

        // WHEN the event processor is run
        Test.startTest();
        EventApplicationProcessor processor = new EventApplicationProcessor();
        processor.pricebookId = System.Test.getStandardPricebookId();
        processor.processImpl(new List<Queue_Job__c>{ queueJob });
        Test.stopTest();

        // THEN the queue job is successful
        Assert.areEqual(1, processor.successfulJobs.size(), EXPECTED_ONE_SUCCESS);
        Assert.areEqual(0, processor.failedJobs.size(), EXPECTED_NO_FAILURES);

        // AND the Opportunity  Role details were updated
        Opportunity oppAfter = [
            SELECT
                Id,
                Job_Title_Apprentice__c,
                Job_Description_Apprentice__c,
                Job_Started_On_Apprentice__c,
                Weekly_Contracted_Hours_Apprentice__c,
                Safety_Knowledge_Apprentice__c,
                Product_Id_Text__c
            FROM Opportunity
            WHERE Application_Id__c = :TEST_APPLICATION_ID
        ];

        Assert.areEqual(schemaRole.jobTitle, oppAfter.Job_Title_Apprentice__c);
        Assert.areEqual(schemaRole.jobDescription, oppAfter.Job_Description_Apprentice__c);
        Assert.areEqual(schemaRole.jobStartDate, oppAfter.Job_Started_On_Apprentice__c);
        Assert.areEqual(schemaRole.weeklyContractedHours, oppAfter.Weekly_Contracted_Hours_Apprentice__c);
        Assert.areEqual(schemaRole.safetyQueryKnowledge, oppAfter.Safety_Knowledge_Apprentice__c);
    }

    @isTest
    private static void itShouldNotOverwriteAccountFieldsWithBlanks() {
        Account account = [SELECT Id FROM Account WHERE LastName = 'Test'];

        // GIVEN we have a schema where some account fields are blank
        ApplicationSchema schema = createTestSchema();
        schema.personalDetails.personalInfo.firstName = '';
        schema.personalDetails.personalInfo.lastName = null;

        Queue_Job__c queueJob = new Queue_Job__c(Job_Content__c = JSON.serialize(schema));
        // WHEN the event is processed
        System.Test.startTest();

        EventApplicationProcessor processor = new EventApplicationProcessor();
        processor.pricebookId = System.Test.getStandardPricebookId();
        processor.processImpl(new List<Queue_Job__c>{ queueJob });

        System.Test.stopTest();
        // THEN I expect the fields to remain as they were previously
        Account out = [SELECT FirstName, LastName FROM Account WHERE ID = :account.Id];

        Assert.areEqual('Test', out.FirstName);
        Assert.areEqual('Test', out.LastName);
    }

    @isTest
    static void itShouldCreateExternalDocuments() {
        Account account = [SELECT id FROM Account LIMIT 1];

        TestUtilities.mockKillswitch(killswitch.JOIN2_DOC_KILLSWITCH, false);

        // GIVEN a queue job with DocumentAndEvidence section
        ApplicationSchema eventSchema = addDocumentAndEvidence(createTestSchema());

        Queue_Job__c queueJob = new Queue_Job__c(Job_Content__c = JSON.serialize(eventSchema));

        // WHEN the event processor is run
        Test.startTest();
        EventApplicationProcessor processor = new EventApplicationProcessor();
        processor.pricebookId = System.Test.getStandardPricebookId();
        processor.processImpl(new List<Queue_Job__c>{ queueJob });
        Test.stopTest();

        // THEN the queue job is successful
        Assert.areEqual(0, processor.failedJobs.size(), EXPECTED_NO_FAILURES);

        // AND the documents were created
        List<External_Document__c> documents = [
            SELECT
                Type__c,
                Category__c,
                Opportunity__r.Application_Id__c,
                Country__r.country_code_2__c,
                Qualification__c,
                Awarding_Institution__c,
                Document_ID__c,
                Status__c,
                Not_Available__c,
                Student__c
            FROM External_Document__c
        ];

        Assert.areEqual(4, documents.size(), 'Expect 4 documents');
        Integer generalDocuments = 0;
        Integer eduHistoryDocuments = 0;
        Integer nameChangedDocuments = 0;

        for (External_Document__c document : documents) {
            ApplicationSchema.DocumentInformation docSchema;

            if (document.Type__c == 'GENERAL' && document.Category__c == 'Name_Change') {
                docSchema = eventSchema.documentsAndEvidence.backgroundInformation.nameChanged;
                Assert.areEqual(docSchema.documents[0].documentId, document.Document_ID__c);
                nameChangedDocuments++;
            } else if (document.Type__c == 'GENERAL' && document.Document_ID__c != null) {
                docSchema = eventSchema.documentsAndEvidence.backgroundInformation.generalDocuments[0];
                Assert.areEqual('GENERAL', document.Type__c);
                Assert.areEqual(docSchema.categoryCode, document.Category__c);
                Assert.areEqual(docSchema.documents[0].documentId, document.Document_ID__c);
                generalDocuments++;
            } else if (document.Type__c == 'GENERAL' && document.Document_ID__c == null) {
                docSchema = eventSchema.documentsAndEvidence.backgroundInformation.generalDocuments[1];
                Assert.areEqual('GENERAL', document.Type__c);
                Assert.areEqual(docSchema.categoryCode, document.Category__c);
                Assert.isNull(document.Document_ID__c);
                generalDocuments++;
            } else if (document.Type__c == 'EDUCATION_HISTORY') {
                docSchema = eventSchema.documentsAndEvidence.backgroundInformation.educationHistoryDocuments[0];
                Assert.areEqual('EDUCATION_HISTORY', document.Type__c);
                Assert.areEqual(docSchema.documents[0].documentId, document.Document_ID__c);
                eduHistoryDocuments++;
            } else {
                Assert.fail(document.Type__c + ' not expected type');
            }

            Assert.areEqual(eventSchema.applicationId, document.Opportunity__r.Application_Id__c);
            Assert.areEqual(docSchema.country?.code, document.Country__r.country_code_2__c);
            Assert.areEqual(docSchema.type?.name, document.Qualification__c);
            Assert.areEqual(docSchema.awardingInstitution.name, document.Awarding_Institution__c);
            Assert.areEqual(docSchema.notAvailable, document.Not_Available__c);
            Assert.areEqual(account.Id, document.Student__c);
            Assert.areEqual('Pending', document.Status__c);
        }

        Assert.areEqual(2, generalDocuments, 'Expect 2 general documents');
        Assert.areEqual(1, eduHistoryDocuments, 'Expect 1 education history document');
        Assert.areEqual(1, nameChangedDocuments, 'Expect 1 name changed document');
    }

    @isTest
    static void itShouldUpdateExternalDocuments() {
        TestUtilities.mockKillswitch(killswitch.JOIN2_DOC_KILLSWITCH, false);
        // GIVEN a queue job with DocumentAndEvidence section
        ApplicationSchema eventSchema = addDocumentAndEvidence(createTestSchema());

        Queue_Job__c queueJob = new Queue_Job__c(Job_Content__c = JSON.serialize(eventSchema));

        // AND an Opp with matching ApplicationId
        Account account = [SELECT id FROM Account LIMIT 1];
        Opportunity opp = new Opportunity(
            name = 'Test',
            Application_Id__c = eventSchema.applicationId,
            accountid = account.Id,
            StageName = 'Application',
            CloseDate = Date.today()
        );
        insert opp;

        Country_List__c country = [SELECT Id FROM Country_List__c WHERE country_code_2__c = :TEST_COUNTRY_CODE LIMIT 1];

        // AND some pre-existing documents
        ApplicationSchema.DocumentsInformation docsInfoSchema = eventSchema.documentsAndEvidence.backgroundInformation;
        insert new List<External_Document__c>{
            new External_Document__c(
                Type__c = 'GENERAL',
                Category__c = docsInfoSchema.generalDocuments[0].categoryCode,
                Document_ID__c = docsInfoSchema.generalDocuments[0].documents[0].documentId,
                Opportunity__c = opp.Id
            ),
            new External_Document__c(
                Type__c = 'GENERAL',
                Category__c = docsInfoSchema.generalDocuments[1].categoryCode,
                Opportunity__c = opp.Id
            ),
            new External_Document__c(
                Type__c = 'EDUCATION_HISTORY',
                Qualification__c = docsInfoSchema.educationHistoryDocuments[0].type?.name,
                Awarding_Institution__c = docsInfoSchema.educationHistoryDocuments[0].awardingInstitution.name,
                Country__c = country.Id,
                Opportunity__c = opp.Id
            ),
            new External_Document__c(Type__c = 'Name Changed', Opportunity__c = opp.Id)
        };

        // WHEN the event processor is run
        Test.startTest();
        EventApplicationProcessor processor = new EventApplicationProcessor();
        processor.pricebookId = System.Test.getStandardPricebookId();
        processor.processImpl(new List<Queue_Job__c>{ queueJob });
        Test.stopTest();

        // THEN the queue job is successful
        Assert.areEqual(0, processor.failedJobs.size(), EXPECTED_NO_FAILURES);

        // AND the documents were created
        List<External_Document__c> documents = [
            SELECT
                Type__c,
                Document_ID__c,
                Status__c,
                Category__c,
                Qualification__c,
                Awarding_Institution__c,
                Opportunity__c
            FROM External_Document__c
        ];

        Assert.areEqual(4, documents.size(), 'Expect 4 documents');
        Integer generalDocuments = 0;
        Integer eduHistoryDocuments = 0;
        Integer nameChangedDocuments = 0;

        for (External_Document__c document : documents) {
            ApplicationSchema.DocumentInformation docSchema;

            if (document.Type__c == 'GENERAL' && document.Category__c == 'Name_Change') {
                docSchema = docsInfoSchema.nameChanged;
                nameChangedDocuments++;
            } else if (document.Type__c == 'GENERAL' && document.Document_ID__c != null) {
                docSchema = docsInfoSchema.generalDocuments[0];
                generalDocuments++;
            } else if (document.Type__c == 'GENERAL' && document.Document_ID__c == null) {
                docSchema = docsInfoSchema.generalDocuments[1];
                generalDocuments++;
            } else if (document.Type__c == 'EDUCATION_HISTORY') {
                docSchema = docsInfoSchema.educationHistoryDocuments[0];
                eduHistoryDocuments++;
            } else {
                Assert.fail(document.Type__c + ' not expected type');
            }

            if (!docSchema.notAvailable) {
                Assert.areEqual(docSchema.documents[0].documentId, document.Document_ID__c);
            } else {
                Assert.isNull(document.Document_ID__c);
            }
        }

        Assert.areEqual(2, generalDocuments, 'Expect 2 general documents');
        Assert.areEqual(1, eduHistoryDocuments, 'Expect 1 education history document');
        Assert.areEqual(1, nameChangedDocuments, 'Expect 1 name changed document');
    }

    @isTest
    static void itShouldUpdateExistingExternalDocumentsUsingDocId() {
        TestUtilities.mockKillswitch(killswitch.JOIN2_DOC_KILLSWITCH, false);
        // GIVEN a queue job with DocumentAndEvidence section
        String matchingId = 'DocumentGUID';

        ApplicationSchema.DocumentInformation generalDocument = new ApplicationSchema.DocumentInformation();
        generalDocument.categoryCode = 'learningDifficulty';
        generalDocument.notAvailable = false;
        generalDocument.documents.add(new ApplicationSchema.Document(matchingId));

        ApplicationSchema eventSchema = createTestSchema();
        eventSchema.documentsAndEvidence.backgroundInformation.generalDocuments.add(generalDocument);

        // AND a pre-existing document with a matching Document Id but no Category
        External_Document__c existingDoc = new External_Document__c(Category__c = '', Document_ID__c = matchingId);
        insert existingDoc;

        // WHEN the event processor is run
        Test.startTest();
        EventApplicationProcessor processor = new EventApplicationProcessor();
        processor.pricebookId = System.Test.getStandardPricebookId();
        processor.processImpl(new List<Queue_Job__c>{ new Queue_Job__c(Job_Content__c = JSON.serialize(eventSchema)) });
        Test.stopTest();

        // THEN the queue job is successful
        Assert.areEqual(0, processor.failedJobs.size(), EXPECTED_NO_FAILURES);

        // AND no additional documents were created
        List<External_Document__c> documents = [
            SELECT Category__c, Document_ID__c
            FROM External_Document__c
        ];

        Assert.areEqual(1, documents.size(), 'Expect 1 document');

        // AND the category should have been updated
        Assert.areNotEqual(
            existingDoc.Category__c,
            documents[0].Category__c,
            'Expect document Category__c to have been updated'
        );
        Assert.areEqual(
            generalDocument.categoryCode,
            documents[0].Category__c,
            'Expect document Category__c to have been updated'
        );
    }

    @isTest
    private static void itShouldUpdateTermsAndConditions() {
        // GIVEN We have an application
        ApplicationSchema eventSchema = createTestSchema();
        Queue_Job__c queueJob = new Queue_Job__c(Job_Content__c = JSON.serialize(eventSchema));

        // WHEN the application is processed
        System.Test.startTest();
        EventApplicationProcessor processor = new EventApplicationProcessor();
        processor.pricebookId = System.Test.getStandardPricebookId();
        processor.processImpl(new List<Queue_Job__c>{ queueJob });
        System.Test.stopTest();

        // THEN the queue job is successful
        Assert.areEqual(1, processor.successfulJobs.size(), EXPECTED_ONE_SUCCESS);
        Assert.areEqual(0, processor.failedJobs.size(), EXPECTED_NO_FAILURES);

        // AND the terms and privacy details were updated
        Opportunity oppAfter = [
            SELECT Terms_and_Conditions_Read_on__c, Has_Read_Privacy_Notice__c
            FROM Opportunity
            WHERE Application_Id__c = :TEST_APPLICATION_ID
        ];

        Assert.areEqual(
            eventSchema.privacyTermsAndConditions.applicantTermsAndConditions.readOn,
            oppAfter.Terms_and_Conditions_Read_on__c
        );
        Assert.areEqual(true, oppAfter.Has_Read_Privacy_Notice__c);
    }

    @isTest
    private static void itShouldNotCreateNameChangeDocumentsIfNotNeeded() {
        // GIVEN a queue job with DocumentAndEvidence section
        ApplicationSchema eventSchema = addDocumentAndEvidence(createTestSchema());

        // AND the is no name change requirement
        eventSchema.documentsAndEvidence.backgroundInformation.nameChanged.isNameSameAsApplication = true;

        Queue_Job__c queueJob = new Queue_Job__c(Job_Content__c = JSON.serialize(eventSchema));

        // AND an Opp with matching ApplicationId
        Account account = [SELECT id FROM Account LIMIT 1];

        Opportunity opp = new Opportunity(
            name = 'Test',
            Application_Id__c = eventSchema.applicationId,
            accountid = account.Id,
            StageName = 'Application',
            CloseDate = Date.today()
        );

        insert opp;

        // WHEN the event processor is run
        Test.startTest();
        EventApplicationProcessor processor = new EventApplicationProcessor();
        processor.pricebookId = System.Test.getStandardPricebookId();
        processor.processImpl(new List<Queue_Job__c>{ queueJob });
        Test.stopTest();

        // THEN the queue job is successful
        Assert.areEqual(0, processor.failedJobs.size(), EXPECTED_NO_FAILURES);

        // AND the documents were created
        List<External_Document__c> documents = [
            SELECT
                Type__c,
                Document_ID__c,
                Status__c,
                Category__c,
                Qualification__c,
                Awarding_Institution__c,
                Opportunity__c
            FROM External_Document__c
        ];

        Integer nameChangedDocuments = 0;

        for (External_Document__c document : documents) {
            ApplicationSchema.DocumentInformation docSchema;

            if (document.Type__c == 'Name Changed') {
                nameChangedDocuments++;
            }
        }

        Assert.areEqual(0, nameChangedDocuments, 'Expect no name changed document');
    }

    @isTest
    private static void itShouldSetOTJTHFromClone() {
        // GIVEN we have a queue job that is applicationCreated
        // AND the job contains a value for off the job training hours
        ApplicationSchema eventSchema = createTestSchema();
        eventSchema.employerInformation.role.overallOffTheJobTrainingHours = 204.4;
        Queue_Job__c queueJob = new Queue_Job__c(
            Job_Content__c = JSON.serialize(eventSchema),
            Job_Type__c = 'applicationCreated'
        );

        // WHEN this job is processed
        Test.startTest();
        EventApplicationProcessor processor = new EventApplicationProcessor();
        processor.pricebookId = System.Test.getStandardPricebookId();
        processor.processImpl(new List<Queue_Job__c>{ queueJob });
        Test.stopTest();

        // THEN I expect it to set the OTJTH preserved field
        Opportunity opp = [SELECT OOTJTH_Preserved__c FROM Opportunity WHERE Application_Id__c = :TEST_APPLICATION_ID];

        Assert.areEqual(eventSchema.employerInformation.role.overallOffTheJobTrainingHours, opp.OOTJTH_Preserved__c);
    }

    static ApplicationSchema createTestSchema() {
        ApplicationSchema eventSchema = new ApplicationSchema();
        eventSchema.applicationId = TEST_APPLICATION_ID;
        eventSchema.applicantId = TEST_APPLICANT_ID;
        eventSchema.applicationType = 'APPRENTICESHIP';
        eventSchema.productId = 'test-1234';
        eventSchema.applicationReference = 'ref987';
        eventSchema.privacyTermsAndConditions.privacyNotice.hasRead = true;
        eventSchema.privacyTermsAndConditions.applicantTermsAndConditions.readOn = Date.today();
        eventSchema.awardingBody = 'Something Professional';
        eventSchema.clientName = 'The Client';
        eventSchema.product.EPA = 12;
        eventSchema.product.EPAO = 'Acme';
        eventSchema.product.academicLevel = 'Level 6';
        eventSchema.product.startOn = DateTime.now();
        eventSchema.product.endOn = DateTime.now();

        ApplicationSchema.PersonalInfo personalInfo = eventSchema.personalDetails.personalInfo;
        personalInfo.title = 'title';
        personalInfo.firstName = 'firstName';
        personalInfo.lastName = 'lastName';
        personalInfo.middleName = 'middleName';
        personalInfo.emailAddress = 'email@email.invalid';
        personalInfo.mobilePhone = '+441234567891';
        personalInfo.dateOfBirth = Date.newInstance(2000, 1, 1);
        personalInfo.niNumber = 'NI-00001';

        ApplicationSchema.GuardianInfo guardian = personalInfo.guardianInfo;
        guardian.firstName = 'guardian_firstName';
        guardian.lastName = 'guardian_lastName';
        guardian.relationship = 'guardian_relationshipType';
        guardian.mobilePhone = '+4412341234567';
        guardian.emailAddress = 'guardian@email.invalid';

        ApplicationSchema.EmergencyContact emergencyContact = eventSchema.personalDetails.emergencyContact;
        emergencyContact.firstName = 'emergencyContact_firstName';
        emergencyContact.lastName = 'emergencyContact_lastName';
        emergencyContact.relationship = 'emergencyContact_relationshipType';
        emergencyContact.mobilePhone = '+44123424681';
        emergencyContact.emailAddress = 'emergencycontact@email.invalid';

        ApplicationSchema.EqualityAndDiversity equalityAndDiversity = eventSchema.backgroundInformation.equalityAndDiversity;
        equalityAndDiversity.criminalConvictionDescription = 'something criminal';
        equalityAndDiversity.isCriminalConviction = true;
        equalityAndDiversity.sexualOrientation.code = '98~ Prefer not to say';
        equalityAndDiversity.religion.code = '20~ No religion';
        equalityAndDiversity.ethnicity.codeHESA = '998~ Prefer not to say';
        equalityAndDiversity.ethnicity.codeESFA = '34~ Any Other White background';
        equalityAndDiversity.sameGenderAsBirth.code = '98~ Prefer not to say';
        equalityAndDiversity.gender.name = 'Female';

        ApplicationSchema.CodeDetail learningNeedExample1 = new ApplicationSchema.CodeDetail();
        learningNeedExample1.code = '1';
        learningNeedExample1.name = 'Autism';

        ApplicationSchema.CodeDetail learningNeedExample2 = new ApplicationSchema.CodeDetail();
        learningNeedExample2.code = '2';
        learningNeedExample2.name = 'Aspergers';

        ApplicationSchema.LearningNeeds learningNeeds = equalityAndDiversity.learningNeeds;
        learningNeeds.primaryDifficulty.code = '2';
        learningNeeds.secondaryDifficulty.add(learningNeedExample1);
        learningNeeds.secondaryDifficulty.add(learningNeedExample2);
        learningNeeds.secondaryDifficultyOther = 'something else';
        learningNeeds.isLearningNeed.name = 'Yes';

        equalityAndDiversity.learningNeeds.primaryDifficultyOther = 'Other';

        ApplicationSchema.CareExperience careExperience = equalityAndDiversity.careExperience;
        careExperience.careExperienceLevel = 'Yes';
        careExperience.isLocalAuthorityCare = 'Yes';
        careExperience.isInformEmployer = true;
        careExperience.isRequestCareLeaverBursary = true;
        careExperience.isAlreadyReceivedCareLeaverBursary = true;

        ApplicationSchema.Address address = eventSchema.personalDetails.address;
        address.line1 = 'address_line1';
        address.line2 = 'address_line2';
        address.city = 'address_town';
        address.postalCode = 'B1 1AA';
        address.country.code = 'GB';

        ApplicationSchema.LineManagerInformation manager = eventSchema.employerInformation.LineManagerInformation;
        manager.firstName = 'manager_firstName';
        manager.lastName = 'manager_lastName';
        manager.jobTitle = 'manager_JobTitle';
        manager.emailAddress = 'manager@manager.invalid';
        manager.mobilePhone = '+441234567891';

        ApplicationSchema.LmrAnswers lineManagerAnswers = eventSchema.LineManagerReviewConfirmation.LmrAnswers;
        lineManagerAnswers.isApplicantInRoleLessThan9Month = true;
        lineManagerAnswers.isFewerThan50Employees = true;

        ApplicationSchema.CompanyInformation company = eventSchema.employerInformation.companyInformation;
        company.companyName = 'Test_Company';
        company.line1 = 'Company_line1';
        company.line2 = 'Company_line2';
        company.line3 = 'Company_line3';
        company.city = 'Company_City';
        company.postalCode = 'N14 3QA';
        company.country.code = 'GB';

        ApplicationSchema.Role role = eventSchema.employerInformation.role;
        role.jobTitle = 'Dev';
        role.jobDescription = 'Test test';
        role.jobStartDate = Date.newInstance(2000, 10, 21);
        role.weeklyContractedHours = 40;
        role.safetyQueryKnowledge = 'YES';

        ApplicationSchema.CodeDetail countryOfBirth = eventSchema.backgroundInformation.nationality.countryOfBirth;
        countryOfBirth.code = 'GB';
        countryOfBirth.name = 'Great Britain';

        ApplicationSchema.CodeDetail countryOfNationality = eventSchema.backgroundInformation.nationality.countryOfNationality;
        countryOfNationality.code = 'GB';
        countryOfNationality.name = 'Great Britain';

        ApplicationSchema.CodeDetail countryOfPermanentResidency = eventSchema.backgroundInformation.nationality.countryOfPermanentResidency;
        countryOfPermanentResidency.code = 'GB';
        countryOfPermanentResidency.name = 'Great Britain';

        ApplicationSchema.AcademicReference academicReference = eventSchema.academicReference;
        eventSchema.academicReference.firstName = 'arefFirst';
        eventSchema.academicReference.lastName = 'arefLast';
        eventSchema.academicReference.mobilePhone = '07712345678';
        eventSchema.academicReference.emailAddress = 'areffirstlast@mail.invalid.com';
        eventSchema.academicReference.relationship = 'aref';

        ApplicationSchema.PersonalStatement personalStatement = eventSchema.personalStatement;
        personalStatement.statement = 'Test Personal Statement Content';

        ApplicationSchema.TuitionFees tuitionFees = eventSchema.tuitionFees;
        tuitionFees.fundingType = 'SPONSORSHIP';
        tuitionFees.sponsorInfo.firstName = 'sponFirst';
        tuitionFees.sponsorInfo.lastName = 'sponLast';
        tuitionFees.sponsorInfo.emailAddress = 'sponfirstlast@mail.invalid.com';
        tuitionFees.sponsorInfo.organisationName = 'spon';
        tuitionFees.sponsorInfo.mobilePhone = '07787654321';
        tuitionFees.sponsorInfo.purchaseOrderNumber = '100';

        ApplicationSchema.KSBS ksb1 = new ApplicationSchema.KSBS();
        ksb1.code = 'test-1';
        ksb1.question = 'question-1';
        ksb1.answer = '1';
        ksb1.experienceInfo = 'experience test';

        ApplicationSchema.KSBS ksb2 = new ApplicationSchema.KSBS();
        ksb2.code = 'test-2';
        ksb2.question = 'question-2';
        ksb2.answer = '2';
        ksb2.experienceInfo = 'experience 2 test';

        ApplicationSchema.SelfAssessment selfAssessment = eventSchema.educationAndSkills.selfAssessment;
        selfAssessment.ksbs.add(ksb1);
        selfAssessment.ksbs.add(ksb2);

        List<ApplicationSchema.Qualification> qualifications = eventSchema.educationAndSkills.educationHistory.qualifications;
        ApplicationSchema.Qualification firstQualification = new ApplicationSchema.Qualification();
        firstQualification.awardingInstitution.code = '10008891';
        firstQualification.awardingInstitution.name = TEST_QUAL_INSTITUTION;
        firstQualification.country.code = 'GB';
        firstQualification.country.name = 'Great Britain';
        firstQualification.grade = 'B+';
        firstQualification.yearCompletedExpected = '2023';
        firstQualification.examiningBody = 'AQA';
        firstQualification.subject.code = 'A81';
        firstQualification.subject.name = TEST_QUAL_SUBJECT;
        firstQualification.type.code = '1A';
        firstQualification.type.name = TEST_QUAL_TYPE;
        qualifications.add(firstQualification);

        ApplicationSchema.Qualification secondQualification = new ApplicationSchema.Qualification();
        secondQualification.awardingInstitution.code = '10018028';
        secondQualification.awardingInstitution.name = '24/7 College';
        secondQualification.country.code = 'GB';
        secondQualification.country.name = 'Great Britain';
        secondQualification.grade = 'A';
        secondQualification.yearCompletedExpected = '2025';
        secondQualification.examiningBody = 'AQA';
        secondQualification.subject.code = '53M';
        secondQualification.subject.name = '3D Animation and Multimedia';
        secondQualification.type.code = 'GY';
        secondQualification.type.name = '1st4sport Level 3 Certificate in Coaching Tennis';
        qualifications.add(secondQualification);

        List<ApplicationSchema.Stage> stages = eventSchema.stages;
        ApplicationSchema.Stage stage = new ApplicationSchema.Stage();
        stage.code = 'APPLICATION_FORM';
        stage.duration = null;
        stage.status = 'IN_PROGRESS';
        stage.startedOn = DateTime.now();
        stage.completedOn = null;

        List<ApplicationSchema.Section> sections = new List<ApplicationSchema.Section>();
        ApplicationSchema.Section firstSection = new ApplicationSchema.Section();
        firstSection.code = 'PERSONAL_DETAILS';
        firstSection.status = 'COMPLETED';
        firstSection.subSections = null;
        sections.add(firstSection);

        ApplicationSchema.Section secondSection = new ApplicationSchema.Section();
        secondSection.code = 'BACKGROUND_INFORMATION';
        secondSection.status = 'IN_PROGRESS';
        secondSection.subSections = null;
        sections.add(secondSection);

        stage.sections = sections;
        stages.add(stage);

        return eventSchema;
    }

    static ApplicationSchema addDocumentAndEvidence(ApplicationSchema eventSchema) {
        ApplicationSchema.DocumentsInformation documentSchema = eventSchema.documentsAndEvidence.backgroundInformation;

        ApplicationSchema.DocumentInformation generalDocument = new ApplicationSchema.DocumentInformation();
        generalDocument.categoryCode = 'learningDifficulty';
        generalDocument.notAvailable = false;
        generalDocument.documents.add(new ApplicationSchema.Document('GUID1'));
        documentSchema.generalDocuments.add(generalDocument);

        ApplicationSchema.DocumentInformation notAvailableDocument = new ApplicationSchema.DocumentInformation();
        notAvailableDocument.notAvailable = true;
        documentSchema.generalDocuments.add(notAvailableDocument);

        ApplicationSchema.DocumentInformation eduHistoryDocument = new ApplicationSchema.DocumentInformation();
        eduHistoryDocument.type.name = 'Maths GCSE';
        eduHistoryDocument.awardingInstitution.name = 'Secondary School';
        eduHistoryDocument.country.code = 'GB';
        eduHistoryDocument.notAvailable = false;
        eduHistoryDocument.documents.add(new ApplicationSchema.Document('GUID2'));
        documentSchema.educationHistoryDocuments.add(eduHistoryDocument);

        documentSchema.nameChanged = new ApplicationSchema.DocumentInformation();
        documentSchema.nameChanged.isNameSameAsApplication = false;
        documentSchema.nameChanged.notAvailable = false;
        documentSchema.nameChanged.documents.add(new ApplicationSchema.Document('GUID3'));

        return eventSchema;
    }
}
