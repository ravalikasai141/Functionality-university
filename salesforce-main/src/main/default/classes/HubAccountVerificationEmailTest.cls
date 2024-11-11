@isTest
private class HubAccountVerificationEmailTest {
    @isTest
    static void test_resendVerificationEmail() {
        Authorisation_Token__c authToken = TestDataFactory.createAuthorisationToken(TRUE);

        Hub_Account__c hubAccount = new Hub_Account__c();
        hubAccount.Auth0_Id__c = 'auth0|qwertyuiop';
        hubAccount.Hub_Username__c = 'test1@bpp.com';
        insert hubAccount;

        List<String> inputList = new List<String>{hubAccount.Auth0_Id__c};

        Test.startTest();
            Test.setMock(HttpCalloutMock.class, new HubAccountCalloutMock());
            List<HubAccountUpdateHelper> response = new List<HubAccountUpdateHelper>();
            response = HubAccountVerificationEmail.getResult(inputList);
            System.assertEquals('Success', response[0].outputString);

            List<Integration_Log__c> integLogList = [SELECT Id FROM Integration_Log__c WHERE Salesforce_ID__c =: hubAccount.Id];
            System.assertEquals(1, integLogList.size());
        Test.stopTest();
    }

    @isTest
    static void test_resendVerificationEmailFailure1() {
        Authorisation_Token__c authToken = TestDataFactory.createAuthorisationToken(TRUE);

        Hub_Account__c hubAccount = new Hub_Account__c();
        hubAccount.Hub_Username__c = 'test1@bpp.com';
        insert hubAccount;

        List<String> inputList = new List<String>{hubAccount.Auth0_Id__c};

        Test.startTest();
            Test.setMock(HttpCalloutMock.class, new HubAccountCalloutMock());
            List<HubAccountUpdateHelper> response = new List<HubAccountUpdateHelper>();
            response = HubAccountVerificationEmail.getResult(inputList);
            System.assertEquals('\nError: Auth0Id value is blank.', response[0].outputString);

            List<Integration_Log__c> integLogList = [SELECT Id FROM Integration_Log__c WHERE Salesforce_ID__c =: hubAccount.Id];
            System.assertEquals(0, integLogList.size());
        Test.stopTest();
    }

    @isTest
    static void test_resendVerificationEmailFailure2() {
        Authorisation_Token__c authToken = TestDataFactory.createAuthorisationToken(TRUE);

        Hub_Account__c hubAccount = new Hub_Account__c();
        hubAccount.Auth0_Id__c = 'auth0|qwertyuiop';
        hubAccount.Hub_Username__c = 'test1@bpp.com';
        hubAccount.Email_Verified__c = true;
        insert hubAccount;

        List<String> inputList = new List<String>{hubAccount.Auth0_Id__c};

        Test.startTest();
            Test.setMock(HttpCalloutMock.class, new HubAccountCalloutMock());
            List<HubAccountUpdateHelper> response = new List<HubAccountUpdateHelper>();
            response = HubAccountVerificationEmail.getResult(inputList);
            System.assertEquals('\nError: Hub Account\'s Email address is already verified.', response[0].outputString);

            List<Integration_Log__c> integLogList = [SELECT Id FROM Integration_Log__c WHERE Salesforce_ID__c =: hubAccount.Id];
            System.assertEquals(0, integLogList.size());
        Test.stopTest();
    }
}