@istest
public class Test_RFIReceiver {
    @testSetup
    static void testSetup() {
        Id userId = [SELECT Id FROM User WHERE UserRole.Name = 'QC' AND IsActive = TRUE ORDER BY Name LIMIT 1].Id;
        Owner_Assignment__c ownerAssignment = new Owner_Assignment__c(Name = 'QC', Last_Assignee__c = userId);
        insert ownerAssignment;

        User u = [SELECT Id FROM User WHERE FirstName = 'David' AND LastName = 'Lovejoy'];
        country_list__c cntry = CreateTestData.createCountry1();

        Account studentAccount = new Account();
        studentAccount.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
            .get('Student_Account')
            .getRecordTypeId();
        studentAccount.FirstName = 'Test';
        studentAccount.LastName = 'DedupeAccount';
        studentAccount.PersonBirthDate = Date.newInstance(1990, 5, 5);
        studentAccount.Personal_Email__pc = 'testaccount123@mail.com';
        studentAccount.Preferred_Email__pc = 'Home';
        studentAccount.PersonHomePhone = '+447713493882';
        studentAccount.Preferred_Phone__pc = 'Home';
        studentAccount.Primary_Nationality__pc = cntry.Id;
        studentAccount.Student_Type__pc = 'Domestic';
        studentAccount.UCAS_Number__pc = '12345';
        studentAccount.Gender__pc = 'Male';
        studentAccount.Legal_Entity__c = 'UC~COL';
        studentAccount.OwnerId = u.Id;
        insert studentAccount;

        Account businessAccount = new Account();
        businessAccount.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
            .get('Business_Development_Account')
            .getRecordTypeId();
        businessAccount.Name = 'Test DedupeAccount';
        businessAccount.Phone = '+447713493882';
        businessAccount.Account_Category__c = 'Customer - Small';
        businessAccount.OwnerId = u.Id;
        insert businessAccount;

        Lead studentLead = new Lead();
        studentLead.RecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName()
            .get('Prospective_Student')
            .getRecordTypeId();
        studentLead.FirstName = 'Test';
        studentLead.LastName = 'DedupeLead';
        studentLead.Status = 'New';
        studentLead.Preferred_Email__c = 'Work';
        studentLead.Work_Email__c = 'testlead123@mail.com';
        studentLead.Preferred_Phone__c = 'Work';
        studentLead.Work_Phone__c = '+447713493882';
        studentLead.rfi_Course_of_Interest__c = 'ACCA';
        studentLead.LeadSource = 'Static Data Capture';
        studentLead.Lead_Source_Recent__c = 'Web';
        studentLead.OwnerId = u.Id;
        insert studentLead;

        Lead businessLead = new Lead();
        businessLead.RecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName()
            .get('Business_Development')
            .getRecordTypeId();
        businessLead.FirstName = 'Anderson';
        businessLead.LastName = 'Hugo';
        businessLead.Status = 'New';
        businessLead.Preferred_Email__c = 'Work';
        businessLead.Work_Email__c = 'testlead345@mail.com';
        businessLead.LeadSource = 'Static Data Capture';
        businessLead.Lead_Source_Recent__c = 'Web';
        businessLead.Company = 'BPP';
        businessLead.OwnerId = u.Id;
        insert businessLead;

        Contact businessContact = new Contact();
        businessContact.RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName()
            .get('BD_Contact')
            .getRecordTypeId();
        businessContact.FirstName = 'Test';
        businessContact.LastName = 'DedupeContact';
        businessContact.AccountId = businessAccount.Id;
        businessContact.Title = 'TDC';
        businessContact.Birthdate = Date.newInstance(1990, 5, 5);
        businessContact.Email = 'testcontact123@mail.com';
        businessContact.Preferred_Email__c = 'Home';
        businessContact.Phone = '+447713493882';
        businessContact.Preferred_Phone__c = 'Home';
        businessContact.UCAS_Number__c = '12345';
        businessContact.OwnerId = u.Id;
        insert businessContact;
    }

    public static RFIReceiver.RFI buildRFIData(
        String recordType,
        String email,
        String firstname,
        String lastname,
        String phone,
        String company
    ) {
        RFIReceiver.RFI rfi = new RFIReceiver.RFI();
        rfi.e_lead_source = 'Web';
        rfi.e_sub_source = 'bpp.com';
        rfi.e_source_title = 'test Lead Source Title';
        rfi.e_current_bpp_student = 'No';
        rfi.e_opt_out = true;
        rfi.e_source = 'test Marketing Media Source';
        rfi.e_medium = 'test Marketing Medium';
        rfi.e_campaign = 'test Campaign';
        rfi.e_programme_of_interest = 'ACCA';
        rfi.e_comments = 'test comments';
        rfi.GA_Gclid = 'test GA Gclid';
        rfi.GA_Client_ID = 'test GA Client ID';
        rfi.FormName = 'RFI Student';
        rfi.e_lead_source = 'Static Data Capture';
        rfi.e_hashed_email = '3edf6tg76yu8ik';
        rfi.RecordType = (recordType != null ? recordType : null);
        rfi.e_email = (email != null ? email : null);
        rfi.e_first_name = (firstname != null ? firstname : null);
        rfi.e_last_name = (lastname != null ? lastname : null);
        rfi.e_phone = (phone != null ? phone : null);
        rfi.e_company = (company != null ? company : null);
        return rfi;
    }

    public static String sendRFIData(RFIReceiver.RFI rfi) {
        RFIReceiver.Response resp = new RFIReceiver.Response();
        resp = RFIReceiver.doPost(rfi);
        return String.valueOf(resp);
    }

    @isTest
    private static void itShouldFindExistingStudentAccountAndUpdateIt() {
        Account accountBefore = [
            SELECT Personal_Email__pc, FirstName, LastName, PersonHomePhone, GA_Client_ID__pc, Hashed_Email__pc
            FROM Account
            WHERE RecordType.Name = 'Student Account' AND Personal_Email__pc = 'testaccount123@mail.com'
            LIMIT 1
        ];
        Assert.isTrue(accountBefore.GA_Client_ID__pc == null, 'GA Client ID field should be null');
        Assert.isTrue(accountBefore.Hashed_Email__pc == null, 'Hashed Email field should be null');

        RFIReceiver.RFI rfi = buildRFIData(
            'Prospective Student',
            accountBefore.Personal_Email__pc,
            accountBefore.FirstName,
            accountBefore.LastName,
            String.valueOf(accountBefore.PersonHomePhone),
            null
        );

        Test.startTest();
        String respString = sendRFIData(rfi);
        Assert.areEqual('Response:[response=Success]', respString, 'Successful Response');
        Test.stopTest();

        Account accountAfter = [
            SELECT GA_Client_ID__pc, Hashed_Email__pc
            FROM Account
            WHERE Id = :accountBefore.Id
            LIMIT 1
        ];
        Assert.isTrue(accountAfter.GA_Client_ID__pc != null, 'GA Client ID field should be updated');
        Assert.isTrue(accountAfter.Hashed_Email__pc != null, 'Hashed Email field should be updated');
    }

    @isTest
    private static void itShouldFindExistingStudentLeadAndUpdateIt() {
        Lead leadBefore = [
            SELECT Work_Email__c, FirstName, LastName, Work_Phone__c, GA_Client_ID__c, Hashed_Email__c
            FROM Lead
            WHERE RecordType.Name = 'Prospective Student' AND Work_Email__c = 'testlead123@mail.com'
            LIMIT 1
        ];
        Assert.isTrue(leadBefore.GA_Client_ID__c == null, 'GA Client ID field should be null');
        Assert.isTrue(leadBefore.Hashed_Email__c == null, 'Hashed Email field should be null');

        RFIReceiver.RFI rfi = buildRFIData(
            'Prospective Student',
            leadBefore.Work_Email__c,
            leadBefore.FirstName,
            leadBefore.LastName,
            leadBefore.Work_Phone__c,
            null
        );

        Test.startTest();
        String respString = sendRFIData(rfi);
        Assert.areEqual('Response:[response=Success]', respString, 'Successful Response');
        Test.stopTest();

        Lead leadAfter = [
            SELECT GA_Client_ID__c, Hashed_Email__c
            FROM Lead
            WHERE Id = :leadBefore.Id
            LIMIT 1
        ];
        Assert.isTrue(leadAfter.GA_Client_ID__c != null, 'GA Client ID field should be updated');
        Assert.isTrue(leadAfter.Hashed_Email__c != null, 'Hashed Email field should be updated');
    }

    @isTest
    private static void itShouldNotFindAnExistingStudentAccountOrLeadAndCreateANewStudentLead() {
        List<Lead> leadBeforeList = [SELECT RecordTypeId FROM Lead WHERE Name = 'John Smith'];
        Assert.areEqual(0, leadBeforeList.size(), 'Lead should not exist');

        RFIReceiver.RFI rfi = buildRFIData(
            'Prospective Student',
            'testacceptance3@mail.com',
            'John',
            'Smith',
            '+447795323882',
            null
        );

        Test.startTest();
        String respString = sendRFIData(rfi);
        Assert.areEqual('Response:[response=Success]', respString, 'Successful Response');
        Test.stopTest();

        Id studentRecType = Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName()
            .get('Prospective_Student')
            .getRecordTypeId();
        List<Lead> leadAfterList = [SELECT RecordTypeId FROM Lead WHERE Name = 'John Smith'];
        Assert.areEqual(1, leadAfterList.size(), 'New Lead Inserted');
        Assert.areEqual(studentRecType, leadAfterList.get(0).RecordTypeId, 'Lead should have Student RecordTypeId');
    }

    /*@isTest
    private static void itShouldFindExistingBusinessContactAndUpdateIt() {
        Contact contactBefore = [
            SELECT Email, FirstName, LastName, Phone, GA_Client_ID__c
            FROM Contact
            WHERE RecordType.Name = 'Business Development Contact'
            LIMIT 1
        ];
        Assert.isTrue(contactBefore.GA_Client_ID__c == null, 'GA Client ID field should be null');

        RFIReceiver.RFI rfi = buildRFIData(
            'Business Development',
            contactBefore.Email,
            contactBefore.FirstName,
            contactBefore.LastName,
            String.valueOf(contactBefore.Phone),
            'Test DedupeAccount'
        );

        Test.startTest();
        String respString = sendRFIData(rfi);
        Assert.areEqual('Response:[response=Success]', respString, 'Successful Response');
        Test.stopTest();

        Contact contactAfter = [
            SELECT GA_Client_ID__c
            FROM Contact
            WHERE Id = :contactBefore.Id
            LIMIT 1
        ];
        Assert.isTrue(contactAfter.GA_Client_ID__c != null, 'GA Client ID field should be updated');
    }*/

    @isTest
    private static void itShouldFindExistingBusinessLeadAndUpdateIt() {
        Lead leadBefore = [
            SELECT Work_Email__c, FirstName, LastName, Work_Phone__c, GA_Client_ID__c, Hashed_Email__c
            FROM Lead
            WHERE RecordType.Name = 'Business Development' AND Work_Email__c = 'testlead345@mail.com'
            LIMIT 1
        ];
        Assert.isTrue(leadBefore.GA_Client_ID__c == null, 'GA Client ID field should be null');
        Assert.isTrue(leadBefore.Hashed_Email__c == null, 'Hashed Email field should be null');

        RFIReceiver.RFI rfi = buildRFIData(
            'Business Development',
            leadBefore.Work_Email__c,
            leadBefore.FirstName,
            leadBefore.LastName,
            leadBefore.Work_Phone__c,
            null
        );

        Test.startTest();
        String respString = sendRFIData(rfi);
        Assert.areEqual('Response:[response=Success]', respString, 'Successful Response');
        Test.stopTest();

        Lead leadAfter = [
            SELECT GA_Client_ID__c, Hashed_Email__c
            FROM Lead
            WHERE Id = :leadBefore.Id
            LIMIT 1
        ];
        Assert.isTrue(leadAfter.GA_Client_ID__c != null, 'GA Client ID field should be updated');
        Assert.isTrue(leadAfter.Hashed_Email__c != null, 'Hashed Email field should be updated');
    }

    @isTest
    private static void itShouldNotFindAnExistingBusinessContactOrLeadAndCreateANewBusinessLead() {
        List<Lead> leadBeforeList = [SELECT RecordTypeId FROM Lead WHERE Name = 'John Smith'];
        Assert.areEqual(0, leadBeforeList.size(), 'Lead should not exist');

        RFIReceiver.RFI rfi = buildRFIData(
            'Business Development',
            'testacceptance6@mail.com',
            'John',
            'Smith',
            '+447795323882',
            'Company Name'
        );

        Test.startTest();
        String respString = sendRFIData(rfi);
        Assert.areEqual('Response:[response=Success]', respString, 'Successful Response');
        Test.stopTest();

        Id businessRecType = Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName()
            .get('Business_Development')
            .getRecordTypeId();
        List<Lead> leadAfterList = [SELECT RecordTypeId FROM Lead WHERE Name = 'John Smith'];
        Assert.areEqual(1, leadAfterList.size(), 'New Lead Inserted');
        Assert.areEqual(businessRecType, leadAfterList.get(0).RecordTypeId, 'Lead should have BD RecordTypeId');
    }

    @isTest
    private static void isShouldReturnWithAnErrorDueToIncorrectRecordTypeValue() {
        RFIReceiver.RFI rfi = buildRFIData(
            'Test Record Type',
            'testacceptance7@mail.com',
            'Bob',
            'Failed',
            '+447795357345',
            null
        );
        rfi.e_opt_out = null;

        Test.startTest();
        String respString = sendRFIData(rfi);
        Assert.areEqual(
            'Response:[response=RFIReceiver Error: "RecordType" not recognised]',
            respString,
            'Unsuccessful Response'
        );
        Test.stopTest();
    }

    @isTest
    private static void isShouldReturnWithAnErrorDueToMissingTaskOwner() {
        delete [SELECT Id FROM Owner_Assignment__c];

        RFIReceiver.RFI rfi = buildRFIData(
            'Business Development',
            'testbilly@mail.com',
            'Billy',
            'Failed',
            '+447714324313',
            null
        );

        Test.startTest();
        String respString = sendRFIData(rfi);
        Assert.isTrue(respString.contains('RFIReceiver Error'));
        Test.stopTest();
    }
}
