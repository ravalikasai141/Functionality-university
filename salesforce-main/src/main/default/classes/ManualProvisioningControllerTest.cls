@isTest
public class ManualProvisioningControllerTest {
    @testSetup
    static void testSetup() {
        Authorisation_Token__c authToken = TestDataFactory.createAuthorisationToken(true);
        Country_List__c country = CreateTestData.createCountry1();
        Programme__c programme = CreateTestData.createProgram();

        Account account = new Account(
            FirstName = 'Test',
            LastName = 'ManualProvisioning',
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
                .get('Student_Account')
                .getRecordTypeId(),
            Student_Type__pc = 'Domestic',
            Preferred_Email__pc = 'Personal',
            Personal_Email__pc = 'test@manprovision.com',
            Preferred_Phone__pc = 'Mobile',
            PersonMobilePhone = '8015555556',
            PersonBirthdate = Date.valueOf('1986-12-07'),
            Country_of_Birth__pc = country.Id,
            Legal_Entity__c = 'UC~COL',
            Email_Address__pc = 'testmanualprov@my.bpp.com',
            BNR_Banner_ID__pc = '123456789',
            HUB_Student__c = true
        );
        insert account;

        Opportunity opportunity = new Opportunity(
            AccountId = account.Id,
            Name = 'Test ManualProvisioning',
            StageName = 'Accepted - Conditional Firm',
            Enrolment_Status__c = 'Acceptance',
            CloseDate = Date.valueOf('2015-02-27'),
            Programme_Application__c = programme.Id
        );
        insert opportunity;
    }

    @isTest
    static void itShouldSuccessfullyProvisionOpportunity() {
        Test.startTest();
        Opportunity opportunity = [SELECT Id FROM Opportunity LIMIT 1];

        Test.setMock(HttpCalloutMock.class, new AWSCalloutMock());
        String response = ManualProvisioningController.manualProvision(opportunity.Id);
        Assert.areEqual('Success', response, 'Manual Provisioning should be successful.');
        Test.stopTest();
    }

    @isTest
    static void itShouldFailProvisioningOpportunityDueToIncorrectStatus() {
        Test.startTest();
        Opportunity opportunity = [SELECT Id FROM Opportunity LIMIT 1];
        opportunity.StageName = 'Complete';
        opportunity.Enrolment_Status__c = 'N/A';
        update opportunity;

        String response = ManualProvisioningController.manualProvision(opportunity.Id);
        Assert.areEqual(
            'The Opportunity Status must be one of the following:</br>* Accepted - Conditional Firm</br>* Accepted - Unconditional Firm</br>* Accepted - Pmt Received</br>',
            response,
            'Manual Provisioning should fail due to incorrect Status.'
        );
        Test.stopTest();
    }

    @isTest
    static void itShouldFailProvisioningOpportunityDueToBlankProgramme() {
        Test.startTest();
        Opportunity opportunity = [SELECT Id FROM Opportunity LIMIT 1];
        opportunity.Programme_Application__c = null;
        update opportunity;

        String response = ManualProvisioningController.manualProvision(opportunity.Id);
        Assert.areEqual(
            'The Opportunity must have a value in the "Programme" field.</br>',
            response,
            'Manual Provisioning should fail due to blank Programme.'
        );
        Test.stopTest();
    }

    @isTest
    static void itShouldFailProvisioningOpportunityDueToBlankBannerId() {
        Test.startTest();
        Account account = [SELECT Id FROM Account LIMIT 1];
        account.BNR_Banner_ID__pc = null;
        update account;

        Opportunity opportunity = [SELECT Id FROM Opportunity LIMIT 1];

        String response = ManualProvisioningController.manualProvision(opportunity.Id);
        Assert.areEqual(
            'The related Account must have a value in the "Banner ID" field.</br>',
            response,
            'Manual Provisioning should fail due to blank Banner Id.'
        );
        Test.stopTest();
    }

    @isTest
    static void itShouldFailProvisioningOpportunityDueToIncorrectEmailType() {
        Test.startTest();
        Account account = [SELECT Id FROM Account LIMIT 1];
        account.Email_Address__pc = null;
        update account;

        Opportunity opportunity = [SELECT Id FROM Opportunity LIMIT 1];

        String response = ManualProvisioningController.manualProvision(opportunity.Id);
        Assert.areEqual(
            'The related Account Email Address must contain "my.bpp.com".</br>',
            response,
            'Manual Provisioning should fail due to incorrect Email type (must contain "@my.bpp.com").'
        );
        Test.stopTest();
    }

    @isTest
    static void itShouldFailProvisioningOpportunityDueToAccountHubStudentFalse() {
        Test.startTest();
        Account account = [SELECT Id FROM Account LIMIT 1];
        account.HUB_Student__c = false;
        update account;

        Opportunity opportunity = [SELECT Id FROM Opportunity LIMIT 1];

        String response = ManualProvisioningController.manualProvision(opportunity.Id);
        Assert.areEqual(
            'The related Account must have the "HUB Student" checkbox checked.</br>',
            response,
            'Manual Provisioning should fail due to related Account\'s Hub Student field being unchecked.'
        );
        Test.stopTest();
    }
}
