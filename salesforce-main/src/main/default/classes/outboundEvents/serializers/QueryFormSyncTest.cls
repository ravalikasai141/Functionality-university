@isTest
private class QueryFormSyncTest {

    @TestSetup
    private static void setUp() {
        
        Account account = new Account(
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName()
            .get('Student Account')
            .getRecordTypeId(),
            FirstName = 'Test',
            LastName = 'Tester',
            Salutation = 'Mr',
            Personal_Email__pc = 'test@bpp.com',
            Preferred_Email__pc = 'Personal',
            BNR_Banner_ID__pc = 'test-1'
        );
        
        insert account;

        Account acc = [SELECT Id, PersonContactId FROM Account WHERE Id = :account.Id];
        
        Hub_Account__c hubAccount = new Hub_Account__c(
            Student__c = account.Id, 
            Hub_Username__c = 'test@bpp.com', 
            Auth0_Id__c = 'auth|test-123');
        
        insert hubAccount;
        
        insert new Case(
            RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName()
            .get('Student Query')
            .getRecordTypeId(),
            AccountId = account.Id,
            ContactId = acc.PersonContactId,
            Status = 'New',
            Origin = 'Web',
            Query_Type__c = 'Assessments',
            Query_Subtype__c = 'How do I access my results and feedback',
            Study_Location__c ='Leeds',
            Query_Id__c = 'test-123'
        );
    }
    
    @isTest
    private static void itShouldBuildTheCorrectPayload() {
        // Given we have a Web case 
        Case cs = [SELECT Id, CaseNumber, Query_Id__c, Status, LastModifiedDate, AccountId, ContactId FROM Case];
        
        // WHEN this is passed to the case query form sync handler
        Serializer serializer = new QueryFormSync();
        serializer.addRecord(cs);
        
        // THEN I expect it to include Auth0 id in the payload
        List<Map<String, Object>> payload = serializer.serialize();
        List<String> authIds = (List<String>) payload.get(0).get('auth0Ids');
        
        Assert.areEqual(1, authIds.size());
        Assert.areEqual('auth|test-123', authIds.get(0));
        
        String status = (String) payload.get(0).get('status');
        Assert.areEqual('New', status);
    }
    
    @isTest
    private static void itShouldSerializeExcludingCasesWithNoHubAccount() {
        // GIVEN we have a case
        Case cs = [SELECT Id, CaseNumber, Query_Id__c, Status, LastModifiedDate, AccountId, ContactId FROM Case];

        // AND there are no Hub Accounts
        delete [SELECT Id FROM Hub_Account__c];

        // WHEN this is passed to the case query form sync handler
        Serializer serializer = new QueryFormSync();
        serializer.addRecord(cs);

        // THEN I expect it to serialize it correctly
        List<Map<String, Object>> payload = serializer.serialize();
        Assert.isTrue(payload.isEmpty(), 'I expect there to be no payloads');
    }
}