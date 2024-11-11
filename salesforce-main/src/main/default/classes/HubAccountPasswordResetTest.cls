@isTest
private class HubAccountPasswordResetTest {

    public static Hub_Account__c createHubAccount(String auth0Id, String hubUserName) {

        Hub_Account__c hubAccount = new Hub_Account__c();
        hubAccount.Auth0_Id__c = auth0Id;
        hubAccount.Hub_Username__c = hubUserName;
        insert hubAccount;

        return hubAccount;
    }

    public static Hub_Account__c retrieveHubAccount(String auth0Id, String hubUserName) {

        return createHubAccount(auth0Id, hubUserName);
    }

    @isTest
    static void test_PasswordReset() {
        
        Hub_Account__c hubAccount = retrieveHubAccount('auth0|qwertyuiop', 'test1@bpp.com');

        List<String> inputList = new List<String>();
		String combinedStrings = hubAccount.Auth0_Id__c;
		inputList.add(combinedStrings);

        Test.startTest();
            Test.setMock(HttpCalloutMock.class, new HubAccountCalloutMock());
            List<HubAccountUpdateHelper> response = new List<HubAccountUpdateHelper>();
            response = HubAccountPasswordReset.getResult(inputList);

            List<Integration_Log__c> integLogList = [SELECT Id FROM Integration_Log__c WHERE Salesforce_ID__c =: hubAccount.Id];
            System.assertEquals(1, integLogList.size());

            Hub_Account__c hubAccountAfter = [SELECT Last_Password_Reset_Email_Sent__c FROM Hub_Account__c LIMIT 1];
            System.assertEquals(Date.valueOf(System.now()), Date.valueOf(hubAccountAfter.Last_Password_Reset_Email_Sent__c));
        Test.stopTest();
    }

    @isTest
    static void test_PasswordResetFailure1() {
       
        Hub_Account__c hubAccount = retrieveHubAccount('', 'test1@bpp.com');

        List<String> inputList = new List<String>();
		String combinedStrings = hubAccount.Auth0_Id__c;
		inputList.add(combinedStrings);

        Test.startTest();
            Test.setMock(HttpCalloutMock.class, new HubAccountCalloutMock());
            List<HubAccountUpdateHelper> response = new List<HubAccountUpdateHelper>();
            response = HubAccountPasswordReset.getResult(inputList);

            List<Integration_Log__c> integLogList = [SELECT Id FROM Integration_Log__c WHERE Salesforce_ID__c =: hubAccount.Id];
            System.assertEquals(0, integLogList.size());

            Hub_Account__c hubAccountAfter = [SELECT Last_Password_Reset_Email_Sent__c FROM Hub_Account__c LIMIT 1];
            System.assertEquals(NULL, hubAccountAfter.Last_Password_Reset_Email_Sent__c);
        Test.stopTest();
    }

    @isTest
    static void test_PasswordResetFailure2() {
        
        Hub_Account__c hubAccount = retrieveHubAccount('auth0|qwertyuiop', 'test1@my.bpp.com');

        List<String> inputList = new List<String>();
		String combinedStrings = hubAccount.Auth0_Id__c;
		inputList.add(combinedStrings);

        Test.startTest();
            Test.setMock(HttpCalloutMock.class, new HubAccountCalloutMock());
            List<HubAccountUpdateHelper> response = new List<HubAccountUpdateHelper>();
            response = HubAccountPasswordReset.getResult(inputList);

            List<Integration_Log__c> integLogList = [SELECT Id FROM Integration_Log__c WHERE Salesforce_ID__c =: hubAccount.Id];
            System.assertEquals(0, integLogList.size());

            Hub_Account__c hubAccountAfter = [SELECT Last_Password_Reset_Email_Sent__c FROM Hub_Account__c LIMIT 1];
            System.assertEquals(NULL, hubAccountAfter.Last_Password_Reset_Email_Sent__c);
        Test.stopTest();
    }
}