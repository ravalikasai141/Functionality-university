@isTest
private class HubUsernameUpdateTest {
    @testSetup
    static void testSetup() {
        List<Account> accountList = new List<Account>();
        Account account1 = TestDataFactory.createAccount(false,true,null,1);
        Account account2 = TestDataFactory.createAccount(false,true,null,2);
        account2.PersonEmail = 'john2@john.com';
        accountList.add(account1);
        accountList.add(account2);
        insert accountList;

        List<Hub_Account__c> hubAccountList = new List<Hub_Account__c>();
        Hub_Account__c hubAccount1 = new Hub_Account__c(Student__c = account1.Id, Hub_Username__c = account1.PersonEmail, Auth0_Id__c = 'auth0|1xx23x45xx67x89012x34x05');
        Hub_Account__c hubAccount2 = new Hub_Account__c(Student__c = account2.Id, Hub_Username__c = account2.PersonEmail, Auth0_Id__c = 'auth0|9xx87x65xx43x21098x76x54');
        hubAccountList.add(hubAccount1);
        hubAccountList.add(hubAccount2);
        insert hubAccountList;

        Authorisation_Token__c authToken = TestDataFactory.createAuthorisationToken(TRUE);
    }

    @isTest
    static void test_HubUsernameUpdateCalloutSuccess() {
        Test.startTest();
            Hub_Account__c hubAccountBefore = [SELECT Id, Student__c FROM Hub_Account__c WHERE Hub_Username__c = 'john@john.com' LIMIT 1];
            hubAccountBefore.BPP_Requested_Hub_Username__c = 'newhubusername@test.com';
            update hubAccountBefore;

            Test.setMock(HttpCalloutMock.class, new AWSCalloutMock());
        Test.stopTest();    

        List<Integration_Log__c> integrationLogList = [SELECT Id FROM Integration_Log__c];
        System.assert(integrationLogList.size() > 0);
    }

    @isTest
    static void test_HubUsernameUpdateCalloutFailure() {
        Test.startTest();
        Hub_Account__c hubAccountBefore = [SELECT Id, Student__c FROM Hub_Account__c WHERE Hub_Username__c = 'john2@john.com' LIMIT 1];
            hubAccountBefore.BPP_Requested_Hub_Username__c = 'john@john.com';
            update hubAccountBefore;

            Test.setMock(HttpCalloutMock.class, new AWSCalloutMock());
        Test.stopTest();    

        Hub_Account__c hubAccountAfter = [
            SELECT Hub_Username__c, BPP_Requested_Hub_Username__c, BPP_Username_Update_Status__c, BPP_Username_Error_Message__c FROM Hub_Account__c WHERE Student__c =: hubAccountBefore.Student__c LIMIT 1
        ];
        System.assertEquals('john2@john.com', hubAccountAfter.Hub_Username__c, 'Hub Username value should not have changed');
        System.assertEquals(null, hubAccountAfter.BPP_Requested_Hub_Username__c, 'Requested Hub Username value should still be null');
        System.assertEquals('Error', hubAccountAfter.BPP_Username_Update_Status__c, 'Username Update Status value should equal "Error"');
        System.assert(hubAccountAfter.BPP_Username_Error_Message__c.contains('is present on an existing Hub Account record'));

        List<Integration_Log__c> integrationLogList = [SELECT Id FROM Integration_Log__c];
        System.assert(integrationLogList.size() == 0);
    }
}