@isTest
private with sharing class HubAccountSyncTest {
    @TestSetup
    private static void setUp() {
        insert new Hub_Account__c(Hub_Username__c = 'test@bpp.com', Auth0_Id__c = 'auth|test-123');
    }

    @isTest
    private static void itShouldBuildTheCorrectPayload() {
        // Given we have a hub account
        Hub_Account__c hub = [SELECT Auth0_Id__c FROM Hub_Account__c WHERE Auth0_Id__c = 'auth|test-123'];

        // WHEN this is passed to the hub account sync handler
        Serializer serializer = new HubAccountSync();
        serializer.addRecord(hub);

        // THEN I expect it to include Auth0 id in the payload
        List<Map<String, Object>> payload = serializer.serialize();
        List<String> authIds = (List<String>) payload.get(0).get('userIds');

        Assert.areEqual(1, authIds.size());
        Assert.areEqual('auth|test-123', authIds.get(0));
    }
}
