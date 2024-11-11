@isTest
private class OpportunityTriggerHandlerTest {
    @TestSetup
    private static void setup() {
        Id opportunityRecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName()
            .get('Apprentice_Application')
            .getRecordTypeId();

        Id accountRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
            .get('Student_Account')
            .getRecordTypeId();

        Id applicationRtId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName()
            .get('Application')
            .getRecordTypeId();

        Id businessDevAccountRTId = Schema.SObjectType.Account.getRecordTypeInfosByName()
            .get('Business Development Account')
            .getRecordTypeId();

        Id trainingManagerRTId = Schema.SObjectType.Contact.getRecordTypeInfosByName()
            .get('Training Manager')
            .getRecordTypeId();

        Country_List__c country = new Country_List__c(
            Name = 'TestCountry',
            Country_Code_2__c = 'TC',
            Valid_Nationality__c = true,
            Valid_Domicile__c = true
        );
        insert country;

        Programme__c programme = new Programme__c(Name = 'Test programme');

        insert programme;

        Account clientAccount = new Account(FirstName = 'BD', LastName = 'Test', RecordTypeId = businessDevAccountRTId);

        List<Product2> products = new List<Product2>{
            new Product2(
                Name = 'Test Course',
                Programme__c = programme.Id,
                BPP_ProductFactoryID__c = 'test-123',
                Instance_Id__c = 'test-1234',
                Location__c = 'London',
                Start_Date__c = Date.today(),
                End_Date__c = Date.today() + 365
            ),
            new Product2(
                Name = 'Test Product 2',
                Programme__c = programme.Id,
                BPP_ProductFactoryID__c = 'test2-232',
                Instance_Id__c = 'test2-123',
                Location__c = 'Birmingham',
                Start_Date__c = Date.today(),
                End_Date__c = Date.today() + 365
            )
        };

        insert products;

        insert new List<PricebookEntry>{
            new PricebookEntry(
                IsActive = true,
                Product2Id = products[0].Id,
                UnitPrice = 10,
                Pricebook2Id = Test.getStandardPricebookId()
            ),
            new PricebookEntry(
                IsActive = true,
                Product2Id = products[1].Id,
                UnitPrice = 10,
                Pricebook2Id = Test.getStandardPricebookId()
            )
        };

        List<Account> accounts = new List<Account>{
            new Account(FirstName = 'Test', LastName = 'Test', RecordTypeId = accountRecordTypeId),
            new Account(
                FirstName = 'Bob',
                LastName = 'Dylan',
                RecordTypeId = accountRecordTypeId,
                Legal_Entity__c = 'UC~COL'
            ),
            new Account(FirstName = 'John', LastName = 'Smith', RecordTypeId = accountRecordTypeId),
            new Account(FirstName = 'Jane', LastName = 'Smith', RecordTypeId = accountRecordTypeId)
        };

        insert accounts;

        List<Contact> contacts = new List<Contact>{
            new contact(FirstName = 'Line', LastName = 'Manager'),
            new contact(
                FirstName = 'Line',
                LastName = 'Manager2',
                AccountId = clientAccount.Id,
                RecordtypeId = trainingManagerRTId,
                Work_Email__c = 'test@email.com',
                Preferred_Email__c = 'Work'
            )
        };

        insert contacts;

        List<Opportunity> opps = new List<Opportunity>{
            new Opportunity(
                RecordTypeId = opportunityRecordTypeId,
                AccountId = accounts[0].Id,
                Name = 'Test Opportunity1',
                StageName = 'Application',
                BPP_Sub_Status__c = 'Not Started',
                CloseDate = Date.today() + 30,
                Application_Id__c = 'test-1234',
                Pricebook2Id = Test.getStandardPricebookId()
            ),
            new Opportunity(
                RecordTypeId = opportunityRecordTypeId,
                AccountId = accounts[1].Id,
                Name = 'Test Opportunity2',
                StageName = 'Application',
                CloseDate = Date.today() + 30,
                Application_Id__c = 'test-4321',
                Course_Instance__c = products[1].Id,
                Pricebook2Id = Test.getStandardPricebookId(),
                Line_Manager__c = contacts[0].Id,
                Weekly_Contracted_Hours_Apprentice__c = 20,
                EPA__c = 7
            ),
            new Opportunity(
                RecordTypeId = applicationRtId,
                AccountId = accounts[2].Id,
                Name = 'Test Opportunity3',
                StageName = 'Accepted - Pmt Pending',
                CloseDate = Date.today() + 30,
                Application_Id__c = 'test-32874',
                Course_Instance__c = products[0].Id,
                Enrolment_Status__c = 'N/A',
                Pricebook2Id = Test.getStandardPricebookId()
            ),
            new Opportunity(
                RecordTypeId = applicationRtId,
                AccountId = accounts[3].Id,
                Name = 'Test Opportunity4',
                StageName = 'Accepted - Pmt Received',
                CloseDate = Date.today() + 30,
                Application_Id__c = 'test-234234',
                Course_Instance__c = products[0].Id,
                Enrolment_Status__c = 'Acceptance',
                Pricebook2Id = Test.getStandardPricebookId()
            ),
            new Opportunity(
                RecordTypeId = opportunityRecordTypeId,
                AccountId = accounts[1].Id,
                Name = 'Test Opportunity5',
                StageName = 'Application',
                CloseDate = Date.today() + 30,
                Application_Id__c = 'test-1111',
                Line_Manager__c = contacts[1].Id,
                Application_Type__c = 'Degree Apprenticeship',
                Client__c = clientAccount.id,
                Address_Lookup_Country__c = country.Id
            ),
            new Opportunity(
                RecordTypeId = opportunityRecordTypeId,
                AccountId = accounts[1].Id,
                Name = 'Test Opportunity6',
                StageName = 'Application',
                CloseDate = Date.today() + 30,
                Application_Id__c = 'test-2222',
                Application_Type__c = 'Degree Apprenticeship',
                Line_Manager__c = contacts[0].Id,
                Client__c = clientAccount.id
            )
        };

        insert opps;

        insert new List<Contact>{
            new Contact(
                FirstName = 'Test',
                LastName = 'Tester1',
                Email = 'test1@test-email.com',
                Work_Email__c = 'test1@test-email.com',
                Preferred_Email__c = 'Work',
                RecordtypeId = trainingManagerRTId
            ),
            new Contact(
                FirstName = 'Test',
                LastName = 'Tester2',
                Email = 'test1@test-email.com',
                Work_Email__c = 'test1@test-email.com',
                Preferred_Email__c = 'Work',
                RecordtypeId = trainingManagerRTId
            ),
            new Contact(
                FirstName = 'Test',
                LastName = 'Tester3',
                Email = 'test2@test-email.com',
                Work_Email__c = 'test2@test-email.com',
                Preferred_Email__c = 'Work',
                RecordtypeId = trainingManagerRTId
            )
        };
    }

    @isTest
    private static void itShouldSetLineManagerWhenOneContactMatches() {
        Opportunity opp = [SELECT Id, Line_Manager_Email__c FROM Opportunity WHERE Application_Id__c = 'test-1234'];
        // GIVEN we have a line manager email set
        opp.Line_Manager_Email__c = 'test2@test-email.com';
        // AND there is one exact contact match
        // WHEN the opportunity is updated
        System.Test.startTest();

        update opp;

        System.Test.stopTest();

        Opportunity out = [SELECT Line_Manager__c, Client__c FROM Opportunity WHERE Id = :opp.Id];
        Contact contact = [SELECT Id, AccountId FROM Contact WHERE LastName = 'Tester3'];

        // THEN I expect the Line Manager to be set
        Assert.areEqual(contact.Id, out.Line_Manager__c);
        Assert.areEqual(contact.AccountId, out.Client__c);
    }

    @isTest
    private static void itShouldSetTheClientWhenLineManagerSet() {
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Application_Id__c = 'test-1234'];
        Contact contact = [SELECT Id, AccountId FROM Contact WHERE LastName = 'Tester3'];
        // GIVEN we have a line manager set
        opp.Line_Manager__c = contact.Id;

        // WHEN the opportunity is updated
        System.Test.startTest();

        update opp;

        System.Test.stopTest();

        Opportunity out = [SELECT Line_Manager__c, Client__c FROM Opportunity WHERE Id = :opp.Id];

        // THEN I expect the Client to be set
        Assert.areEqual(contact.Id, out.Line_Manager__c);
        Assert.areEqual(contact.AccountId, out.Client__c);
    }

    @isTest
    private static void itShouldNotSetLineManagerIfMultipleMatchesAreFound() {
        Opportunity opp = [SELECT Id, Line_Manager_Email__c FROM Opportunity WHERE Application_Id__c = 'test-1234'];
        // GIVEN we have a line manager email set
        opp.Line_Manager_Email__c = 'test1@test-email.com';
        // AND there is more than one exact contact match
        // WHEN the opportunity is updated
        System.Test.startTest();

        update opp;

        System.Test.stopTest();

        // THEN I expect the Line Manager is not set
        Opportunity out = [SELECT Line_Manager__c, Client__c FROM Opportunity WHERE Id = :opp.Id];
        Assert.isNull(out.Line_Manager__c);
        Assert.isNull(out.Client__c);
    }

    @isTest
    private static void itShouldCreateALineItemWhenAnOpportunityIsCreatedWithAProduct() {
        Id opportunityRecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName()
            .get('Apprentice_Application')
            .getRecordTypeId();

        Account account = [SELECT Id FROM Account WHERE LastName = 'Dylan'];

        // GIVEN we have a product
        Product2 product = [SELECT Id FROM Product2 WHERE Name = 'Test Course'];

        // WHEN we create a new opportunity
        System.Test.startTest();

        Opportunity opp = new Opportunity(
            RecordTypeId = opportunityRecordTypeId,
            AccountId = account.Id,
            Name = 'Test Opp3',
            StageName = 'Application',
            CloseDate = Date.today() + 30,
            Application_Id__c = 'test-68363',
            Course_Instance__c = product.Id,
            Pricebook2Id = Test.getStandardPricebookId()
        );

        insert opp;

        System.Test.stopTest();

        // THEN we expect it create a line item
        List<OpportunityLineItem> items = [
            SELECT Id, Product2Id
            FROM OpportunityLineItem
            WHERE OpportunityId = :opp.Id
        ];

        Assert.areEqual(1, items.size());
        Assert.areEqual(product.Id, items[0].Product2Id);
    }

    @isTest
    private static void itShouldCreateALineItemWhenOpportunityIsUpdatedWithProduct() {
        // GIVEN we have an opportunity and product
        Opportunity opp = [SELECT Id, Course_Instance__c FROM Opportunity WHERE Application_Id__c = 'test-1234'];
        Product2 product = [SELECT Id FROM Product2 WHERE Name = 'Test Course'];
        // WHEN we relate the product to the opportunity
        System.Test.startTest();

        opp.Course_Instance__c = product.Id;
        update opp;

        System.Test.stopTest();
        // THEN we expect it to create a line item
        List<OpportunityLineItem> items = [SELECT Id FROM OpportunityLineItem WHERE OpportunityId = :opp.Id];

        Assert.areEqual(1, items.size());
    }

    @isTest
    private static void itShouldNotCreateALineItemIfAProductIdExistedBeforeUpdating() {
        // GIVEN we have an opportunity with a product already set
        Opportunity opp = [SELECT Id, Course_Instance__c FROM Opportunity WHERE Application_Id__c = 'test-4321'];
        Product2 product = [SELECT Id FROM Product2 WHERE Name = 'Test Course'];
        // WHEN reassinging a product
        System.Test.startTest();

        opp.Course_Instance__c = product.Id;
        update opp;

        System.Test.stopTest();
        // THEN It should NOT generate a new line item
        List<OpportunityLineItem> items = [SELECT Id FROM OpportunityLineItem WHERE OpportunityId = :opp.Id];

        Assert.areEqual(1, items.size());
    }
    @isTest
    private static void itShouldUpdateStudentAccountFieldsWhenApplicationMovesToStage() {
        // GIVEN we have an Account and an opportunity with Application Not Started
        Account acc = [SELECT Id FROM Account WHERE FirstName = 'Test'];
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Application_Id__c = 'test-1234'];

        // WHEN We update this opportunity to the right stagename
        System.Test.startTest();
        opp.StageName = 'Acceptance';
        opp.BPP_Sub_Status__c = 'Completed';
        update opp;
        System.Test.stopTest();

        // THEN I expect pre-populate 3 student account fields
        Account updatedAcc = [
            SELECT Id, Account_Tax_Category__c, Student_Type__pc, Billing_Type__c
            FROM Account
            WHERE Id = :acc.Id
        ];
        Assert.areEqual('Domestic Customer', updatedAcc.Account_Tax_Category__c);
        Assert.areEqual('Domestic', updatedAcc.Student_Type__pc);
        Assert.areEqual('In Advance', updatedAcc.Billing_Type__c);
    }

    @isTest
    private static void itShouldCreateStudentCoursesWhenOpportunityMovesToStage() {
        // GIVEN we have an opportunity with a product set
        Opportunity opp = [SELECT Id, StageName FROM Opportunity WHERE Name = 'Test Opportunity3'];

        // WHEN We update this opportunity to the right stagename
        System.Test.startTest();

        opp.StageName = 'Accepted - Pmt Received';
        update opp;

        System.Test.stopTest();

        // THEN I expect a Student Course to be created
        List<Student_Course__c> courses = [SELECT Id FROM Student_Course__c WHERE Opportunity__c = :opp.Id];

        Assert.areEqual(1, courses.size());
    }

    @isTest
    private static void itShouldDeleteStudentCoursesWhenOpportunityIsDeleted() {
        // GIVEN we have an opportunity that is related to a student course
        Opportunity opp = [SELECT Id, AccountId FROM Opportunity WHERE Name = 'Test Opportunity4'];
        List<Student_Course__c> initial = [SELECT Id FROM Student_Course__c WHERE Opportunity__c = :opp.Id];
        Id accountId = opp.AccountId;

        Assert.areEqual(1, initial.size());
        // WHEN we delete the opportunity
        System.Test.startTest();

        delete opp;

        System.Test.stopTest();

        // THEN I expect the student course to be deleted as well
        List<Student_Course__c> out = [SELECT Id FROM Student_Course__c WHERE Student__c = :accountId];

        Assert.isTrue(out.isEmpty());
    }

    @isTest
    private static void itShouldUpdateOpportunityNameOnProductUpdate() {
        // GIVEN we have an existing opportunity
        Opportunity opp = [SELECT Id, Name FROM Opportunity WHERE Application_Id__c = 'test-1234'];

        // AND a different Product
        Product2 product = [SELECT Id FROM Product2 WHERE Name = 'Test Product 2'];

        // WHEN we relate the product to the opportunity
        System.Test.startTest();

        opp.Course_Instance__c = product.Id;
        update opp;

        System.Test.stopTest();

        // THEN we expect it to have updated the Opportunity name
        Opportunity updatedOpp = [SELECT Id, Name FROM Opportunity WHERE Id = :opp.Id];
        Assert.areNotEqual(opp.Name, updatedOpp.Name);
        Assert.areEqual('Test - Test programme - Birmingham - ' + Date.today().year(), updatedOpp.Name);
    }

    @isTest
    private static void itShouldUpdateAddressFieldsOnApprenticeOpps() {
        // GIVEN we have an opportunity with Company Address fields set
        Country_List__c country = [SELECT Id FROM Country_List__c WHERE Name = 'TestCountry'];

        Opportunity opp = [
            SELECT
                Id,
                Company_Lookup_Country__c,
                Company_Street_1__c,
                Company_Street_2__c,
                Company_City__c,
                Company_Zip_Postal_Code__c
            FROM Opportunity
            WHERE Application_ID__c = 'test-1234'
        ];

        opp.Company_Lookup_Country__c = country.Id;
        opp.Company_Street_1__c = 'Test1';
        opp.Company_Street_2__c = 'Test2';
        opp.Company_City__c = 'TestCity';
        opp.Company_Zip_Postal_Code__c = 'B109DQ';

        // WHEN it is updated
        System.Test.startTest();

        update opp;

        System.Test.stopTest();

        // THEN I expect the data to be replicated on other address fields
        Opportunity out = [
            SELECT Street_Address__c, City__c, Postal_Code__c, Country__c
            FROM Opportunity
            WHERE Id = :opp.Id
        ];

        Assert.areEqual('Test1, Test2', out.Street_Address__c);
        Assert.areEqual('TestCity', out.City__c);
        Assert.areEqual('B109DQ', out.Postal_Code__c);
        Assert.areEqual('TestCountry', out.Country__c);
    }

    @isTest
    private static void itShouldCreateANewDeliveryAddressOnAcceptanceIfNoneAlreadyExist() {
        // GIVEN we have an opportunity

        Opportunity opp = [
            SELECT
                Id,
                Company_Lookup_Country__c,
                Company_Street_1__c,
                Company_Street_2__c,
                Company_City__c,
                Company_Zip_Postal_Code__c,
                AccountId
            FROM Opportunity
            WHERE Application_ID__c = 'test-1234'
        ];
        //WITH an Address that is not marked with Primary Delivery Address

        insert new Address__c(
            Student__c = opp.accountId,
            Street_1__c = 'Fake street',
            Type__c = 'Home',
            Primary_Delivery__c = false
        );

        // WHEN the opp's stage is change to 'Acceptance'
        System.Test.startTest();

        opp.StageName = 'Acceptance';
        update opp;

        System.Test.stopTest();

        // THEN I expect a new Address to be created with the 'Mailing' type,that is set as the primary delivery address
        List<Address__c> addressesOut = [
            SELECT Student__c, Street_1__c, Type__c, Primary_Delivery__c
            FROM Address__c
            WHERE Student__c = :opp.AccountId
        ];

        Address__c deliveryAddress = [
            SELECT Student__c, Street_1__c, Type__c, Primary_Delivery__c
            FROM Address__c
            WHERE Student__c = :opp.AccountId AND Primary_Delivery__c != FALSE
        ];

        Assert.areEqual(addressesOut.size(), 2);
        Assert.areEqual(deliveryAddress.Type__c, 'Mailing');
        Assert.areEqual(deliveryAddress.Primary_Delivery__c, true);
    }

    @isTest
    private static void itShouldCreateASponsorship() {
        // GIVEN we have an Apprentice Application Opportunity with a set Line Manager and Client
        Opportunity opp = [
            SELECT Id, AccountId, StageName, BPP_Sub_Status__c, Line_Manager__c, Client__c, Address_Lookup_Country__c
            FROM Opportunity
            WHERE Application_ID__c = 'test-1111'
        ];

        // WHEN The Opp is set to Stage 'Acceptance' And Sub Stage 'Completed'
        System.Test.startTest();

        opp.StageName = 'Acceptance';
        opp.BPP_Sub_Status__c = 'Completed';
        update opp;

        System.Test.stopTest();

        // THEN fields on the Opp and Account should be updated, along with the creation of a sponsorship
        Opportunity oppOut = [
            SELECT Training_Manager__c, Sponsorship_Level__c, Sponsorship_Percentage__c
            FROM Opportunity
            WHERE Id = :opp.Id
        ];

        Assert.areEqual(oppOut.Training_Manager__c, opp.Line_Manager__c);
        Assert.areEqual(oppOut.Sponsorship_Level__c, 'Full');
        Assert.areEqual(oppOut.Sponsorship_Percentage__c, 100);

        Account accOut = [
            SELECT Id, Training_Manager__c, Client__c, Legal_Entity__c, Country_of_Permanent_Address__c
            FROM Account
            WHERE Id = :opp.AccountId
        ];

        Assert.areEqual(accOut.Country_of_Permanent_Address__c, opp.Address_Lookup_Country__c);
        Assert.areEqual(accOut.Training_Manager__c, opp.Line_Manager__c);
        Assert.areEqual(accOut.Client__c, opp.Client__c);
        Assert.areEqual(accOut.Legal_Entity__c, 'UC~COL');

        List<Sponsorship__c> sponsorshipsOut = [SELECT Id FROM Sponsorship__c WHERE Opportunity__c = :opp.Id];

        Assert.areEqual(1, sponsorshipsOut.size());
    }

    @isTest
    private static void itShouldntUpdateTrainingManagerFieldsWithContactsOfIncorrectRecordType() {
        // GIVEN we have an Apprentice Application Opportunity with a set Client
        // AND a related Line Manager that doesn't have the 'Training Manager' Record Type.
        Opportunity opp = [
            SELECT Id, AccountId, StageName, Line_Manager__c, BPP_Sub_Status__c, Client__c
            FROM Opportunity
            WHERE Application_ID__c = 'test-2222'
        ];

        // WHEN The Opp is set to Stage 'Acceptance' And Sub Stage 'Completed'
        System.Test.startTest();

        opp.StageName = 'Acceptance';
        opp.BPP_Sub_Status__c = 'Completed';
        update opp;

        System.Test.stopTest();

        // THEN fields on the Opp and Account should be updated (excluding training manager fields), along with the creation of a sponsorship
        Opportunity oppOut = [
            SELECT Training_Manager__c
            FROM Opportunity
            WHERE Id = :opp.Id
        ];

        Assert.areEqual(oppOut.Training_Manager__c, null);
    }

    @isTest
    private static void itShouldntCreateASponsorshipWhenAValidOneAlreadyExists() {
        // Given we have an Apprentice Application Opportunity with a set Line Manager and Client
        // AND a sponsorship record already exists for the opp
        Opportunity opp = [
            SELECT Id, AccountId, StageName, BPP_Sub_Status__c, Line_Manager__c, Client__c
            FROM Opportunity
            WHERE Application_ID__c = 'test-1111'
        ];

        Account acc = [SELECT Id, PS_Profile_Services_ID__pc FROM Account WHERE Lastname = 'Dylan'];

        insert new Sponsorship__c(Opportunity__c = opp.Id, Student__c = acc.Id);

        // When The Opp is set to Stage 'Acceptance' And Sub Stage 'Completed'
        System.Test.startTest();

        opp.StageName = 'Acceptance';
        opp.BPP_Sub_Status__c = 'Completed';
        update opp;

        System.Test.stopTest();

        // THEN I expect only one sponsorship record for the given opportunity
        List<Sponsorship__c> sponsorshipsOut = [SELECT Id FROM Sponsorship__c WHERE Opportunity__c = :opp.Id];
        Assert.areEqual(1, sponsorshipsOut.size());
    }

    @isTest
    private static void itShouldSetOldContractedHours() {
        // GIVEN we have an opportunity in Line Manager Review
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Application_ID__c = 'test-1234'];
        opp.Bypass_Validation_Rule__c = true;
        opp.StageName = 'Line Manager Review';
        opp.Line_Manager__c = [SELECT Id FROM Contact LIMIT 1].Id;
        opp.BPP_Sub_Status__c = 'In Progress';

        // AND the Opportunity already has a Contracted Hours value set
        opp.Weekly_Contracted_Hours_Apprentice__c = 20;
        opp.Old_Weekly_Contracted_Hours__c = null;
        update opp;

        System.Test.startTest();

        // Clear the executedOperations map so that all trigger contexts can re-run
        TriggerExecute.executedOperations.clear();

        // WHEN the Opportunities Weekly Contracted Hours are changed
        opp.Weekly_Contracted_Hours_Apprentice__c = 30;
        update opp;

        System.Test.stopTest();

        Opportunity oppResults = [
            SELECT Id, Weekly_Contracted_Hours_Apprentice__c, Old_Weekly_Contracted_Hours__c
            FROM Opportunity
            WHERE Id = :opp.Id
        ];

        // THEN the Old Weekly Contracted Hours should have been updated to the new value
        Assert.areEqual(30, oppResults.Weekly_Contracted_Hours_Apprentice__c);
        Assert.areEqual(20, oppResults.Old_Weekly_Contracted_Hours__c);
    }

    @isTest
    private static void itShouldResetOldContractedHoursWhenContractedHoursMatches() {
        // GIVEN we have an opportunity in Line Manager Review
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Application_ID__c = 'test-1234'];
        opp.Bypass_Validation_Rule__c = true;
        opp.StageName = 'Line Manager Review';
        opp.Line_Manager__c = [SELECT Id FROM Contact LIMIT 1].Id;
        opp.BPP_Sub_Status__c = 'In Progress';

        // AND the Opportunity already has both Old and current Contracted Hours value set
        opp.Weekly_Contracted_Hours_Apprentice__c = 20;
        opp.Old_Weekly_Contracted_Hours__c = 10;
        update opp;

        System.Test.startTest();

        // Clear the executedOperations map so that all trigger contexts can re-run
        TriggerExecute.executedOperations.clear();

        // WHEN the Opportunities Weekly Contracted Hours are changed to match the current Old Hours
        opp.Weekly_Contracted_Hours_Apprentice__c = 10;
        update opp;

        System.Test.stopTest();

        Opportunity oppResults = [
            SELECT Id, Weekly_Contracted_Hours_Apprentice__c, Old_Weekly_Contracted_Hours__c
            FROM Opportunity
            WHERE Id = :opp.Id
        ];

        // THEN the Old Weekly Contracted Hours should have been cleared
        Assert.areEqual(10, oppResults.Weekly_Contracted_Hours_Apprentice__c);
        Assert.areEqual(null, oppResults.Old_Weekly_Contracted_Hours__c);
    }

    @isTest
    private static void itShouldResetOldContractedHoursWhenUpdatedToLineManagerReview() {
        // GIVEN we have an opportunity which is not Line Manager Review
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Application_ID__c = 'test-1234'];

        // AND the Opportunity already has both Old and current Contracted Hours value set
        opp.Weekly_Contracted_Hours_Apprentice__c = 20;
        opp.Old_Weekly_Contracted_Hours__c = 10;
        update opp;

        System.Test.startTest();

        // Clear the executedOperations map so that all trigger contexts can re-run
        TriggerExecute.executedOperations.clear();

        // WHEN the Opportunities is moved into Line Manager Review
        opp.Bypass_Validation_Rule__c = true;
        opp.StageName = 'Line Manager Review';
        opp.Line_Manager__c = [SELECT Id FROM Contact LIMIT 1].Id;
        opp.BPP_Sub_Status__c = 'In Progress';

        update opp;

        System.Test.stopTest();

        Opportunity oppResults = [
            SELECT Id, Weekly_Contracted_Hours_Apprentice__c, Old_Weekly_Contracted_Hours__c
            FROM Opportunity
            WHERE Id = :opp.Id
        ];

        // THEN the Old Weekly Contracted Hours should have been cleared
        Assert.areEqual(20, oppResults.Weekly_Contracted_Hours_Apprentice__c);
        Assert.areEqual(null, oppResults.Old_Weekly_Contracted_Hours__c);
    }

    @isTest
    private static void itShouldSetOOTJTHOnEPAUpdate() {
        // GIVEN we have an opportunity
        Opportunity opp = [
            SELECT Id, EPA__c
            FROM Opportunity
            WHERE Application_ID__c = 'test-4321'
        ];
        // WHEN the opportunity EPA is updated
        opp.EPA__c = 15;
        update opp;

        // THEN I expect it to sync
        Opportunity oppResults = [
            SELECT OOTJTH_Preserved__c, OOTJTH_Calculated__c
            FROM Opportunity
            WHERE Id = :opp.Id
        ];

        Assert.areEqual(oppResults.OOTJTH_Calculated__c, oppResults.OOTJTH_Preserved__c);
    }

    @isTest
    private static void itShouldCreateApplicationHistory() {
        // GIVEN we have an opportunity
        Id opportunityRecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName()
            .get('Apprentice_Application')
            .getRecordTypeId();

        Opportunity opp = [
            SELECT Id, Job_Description_Apprentice__c, Application_ID__c
            FROM Opportunity
            WHERE RecordTypeId = :opportunityRecordTypeId
            LIMIT 1
        ];
        String jobDescription = 'test Job Description';
        Assert.areNotEqual(jobDescription, opp.Job_Description_Apprentice__c);

        // WHEN one of the fields in the criteria is changed
        System.Test.startTest();
        opp.Job_Description_Apprentice__c = jobDescription;
        update opp;

        System.Test.stopTest();

        // THEN a Application History record is created
        Application_History__c history = [
            SELECT Job_Description__c, Application_ID__c
            FROM Application_History__c
            WHERE Opportunity__c = :opp.Id
        ];

        Assert.areEqual(opp.Job_Description_Apprentice__c, history.Job_Description__c);
        Assert.areEqual(opp.Application_ID__c, history.Application_ID__c);
    }

    @isTest
    private static void itShouldClearFieldsOnWithdraw() {
        // GIVEN an Opportunity
        Opportunity testOpp = [SELECT Id, EPA__c FROM Opportunity WHERE Application_Id__c = 'test-4321'];

        Assert.areEqual(7, testOpp.EPA__c);

        // WHEN the Opportunity is updated to be withdrawn
        System.Test.startTest();

        testOpp.StageName = 'Closed Lost';
        testOpp.BPP_Sub_Status__c = 'Withdrawn';
        update testOpp;

        System.Test.stopTest();

        // THEN all fields not marked as to be kept should be removed
        Opportunity testOppResults = [SELECT Application_ID__c, EPA__c FROM Opportunity WHERE Id = :testOpp.Id];
        Assert.areEqual(null, testOppResults.EPA__c);

        // AND any fields marked as being kept should be kept
        Assert.areEqual('test-4321', testOppResults.Application_ID__c);
    }
}
