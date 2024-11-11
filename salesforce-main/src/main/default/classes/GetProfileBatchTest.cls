@isTest
private class GetProfileBatchTest {
    @TestSetup
    private static void setup() {
        Country_List__c country = new Country_List__c(
            Name = 'United Kingdom',
            Valid_Domicile__c = true,
            Valid_Nationality__c = true,
            country_code_2__c = 'GB',
            ISO_CODE__c = 'GB',
            enabled__c = true
        );
        insert country;

        Account account = new Account(
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName()
                .get('Student Account')
                .getRecordTypeId(),
            FirstName = 'TestAccount',
            LastName = 'Student',
            PersonBirthdate = Date.newInstance(2002, 2, 1),
            Preferred_Email__pc = 'Personal',
            Preferred_Phone__pc = 'Mobile',
            PersonEmail = 'john2@john.com',
            Personal_Email__pc = 'john2@john.com',
            PersonMobilePhone = '+447716123222',
            Account_Type__c = 'General',
            VAT_Code__pc = '123456789',
            Domicile__pc = 'XF~ England',
            AR_Customer_Number__c = '27356632',
            Country_of_Permanent_Address__c = country.Id,
            Primary_Nationality__pc = country.Id,
            Student_Type__pc = 'Domestic',
            Legal_Entity__c = 'UC~COL',
            Parent_Guardian_Occupation__pc = '0000~ Not stated',
            SFDC_Disability_Status_Code_Select__pc = '0~ No Known Disability'
        );
        insert account;

        Opportunity opp = new Opportunity(
            RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName()
                .get('Application')
                .getRecordTypeId(),
            AccountId = account.Id,
            Name = 'Test Opportunity',
            StageName = 'Accepted - Pmt Received',
            CloseDate = Date.today() + 30,
            Enrolment_Status__c = 'Acceptance'
        );
        insert opp;
    }

    @isTest
    private static void itShouldBeAbleToRetrieveAProfileId() {
        // GIVEN We have an Opportunity with a related Account that requires a Profile Id
        // WHEN we include this opp in a query and run the batch
        System.Test.startTest();

        GetProfileBatch batch = new GetProfileBatch('SELECT AccountId FROM Opportunity');
        Database.executeBatch(batch);

        System.Test.stopTest();
        // THEN I expect it to process successfully
        Account account = [SELECT PS_Profile_Services_ID__pc FROM Account WHERE LastName = 'Student'];
        List<ContentVersion> versions = [SELECT Id FROM ContentVersion];

        Assert.areNotEqual(null, account.PS_Profile_Services_ID__pc);
        Assert.isTrue(versions.isEmpty());
    }

    @isTest
    private static void itShouldReportErrors() {
        // GIVEN We have an Opportunity with a related Account that requires a Profile Id
        // AND this Account already has a Profile Id
        Account account = [SELECT Id FROM Account WHERE LastName = 'Student'];
        account.PS_Profile_Services_ID__pc = 'ba618412-c3d7-4752-67yu-17c52bfc20c8';
        update account;

        // WHEN we include this opp in a query and run the batch
        System.Test.startTest();

        GetProfileBatch batch = new GetProfileBatch('SELECT AccountId FROM Opportunity');
        Database.executeBatch(batch);

        System.Test.stopTest();
        // THEN I expect it to create an error csv
        List<ContentVersion> versions = [SELECT Id FROM ContentVersion];

        Assert.isFalse(versions.isEmpty());
    }
}
