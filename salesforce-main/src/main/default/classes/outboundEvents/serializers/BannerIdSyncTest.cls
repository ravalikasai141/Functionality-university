@isTest
private class BannerIdSyncTest {
    static final String MATCHING_BANNERID = 'Payload Banner Id should match Student Banner Id';
    static final String MATCHING_AUTHID = 'Payload authId should match Student authId';
    static final String ONE_PAYLOAD = 'Output should contain one payload';
    static final String ONE_AUTHID = 'Payload should contain one authId';
    static final String HUBACCOUNT_AUTHID = 'sub|12345';

    @TestSetup
    private static void setup() {
        Id recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
            .get('Student_Account')
            .getRecordTypeId();

        List<Account> accountList = new List<Account>();
        for (Integer i = 1; i <= 2; i++) {
            Account account = new Account();
            account.RecordTypeId = recordTypeId;
            account.FirstName = 'Test' + i;
            account.LastName = 'Tester' + i;
            account.Salutation = 'Mr';
            account.Personal_Email__pc = 'test' + i + '@bpp.com';
            account.Preferred_Email__pc = 'Personal';
            account.BNR_Banner_ID__pc = 'test-' + i;
            accountList.add(account);
        }
        insert accountList;

        insert new Hub_Account__c(
            Student__c = accountList.get(0).Id,
            Auth0_Id__c = HUBACCOUNT_AUTHID,
            Hub_Username__c = 'testuser1@bpp.com'
        );
    }

    public static Account retrieveAccount(String name) {
        return [
            SELECT Id
            FROM Account
            WHERE LastName = :name
            LIMIT 1
        ];
    }

    public static SerializedData serializeData(SObject record) {
        BannerIdSync sync = new BannerIdSync();
        sync.addRecord(record);

        SerializedData sd = new SerializedData();
        sd.output = sync.serialize();
        sd.detail = (!sd.output.isEmpty() ? (Map<String, Object>) sd.output.get(0) : new Map<String, Object>());
        sd.studentRefNum = (String) sd.detail.get('bannerID');
        sd.authIds = (List<String>) sd.detail.get('userIds');
        return sd;
    }

    @isTest
    private static void itShouldSerializeFromAnAccount() {
        // GIVEN we have an account
        Account account = retrieveAccount('Tester1');

        // WHEN passed to the BannerIdSync class
        SerializedData sd = serializeData(account);

        // THEN I expect it to serialize it correctly
        Assert.areEqual('test-1', sd.studentRefNum, MATCHING_BANNERID);
        Assert.areEqual(HUBACCOUNT_AUTHID, sd.authIds.get(0), MATCHING_AUTHID);
        Assert.areEqual(1, sd.output.size(), ONE_PAYLOAD);
        Assert.areEqual(1, sd.authIds.size(), ONE_AUTHID);
    }

    @isTest
    private static void itShouldSerializeFromAHubAccount() {
        // GIVEN we have an account
        Account account = retrieveAccount('Tester2');

        Hub_Account__c hubAccount = new Hub_Account__c(
            Student__c = account.Id,
            Auth0_Id__c = HUBACCOUNT_AUTHID + 'x',
            Hub_Username__c = 'testuser2@bpp.com'
        );
        insert hubAccount;

        // WHEN passed to the BannerIdSync class
        SerializedData sd = serializeData(hubAccount);

        // THEN I expect it to serialize it correctly
        Assert.areEqual('test-2', sd.studentRefNum, MATCHING_BANNERID);
        Assert.areEqual(HUBACCOUNT_AUTHID + 'x', sd.authIds.get(0), MATCHING_AUTHID);
        Assert.areEqual(1, sd.output.size(), ONE_PAYLOAD);
        Assert.areEqual(1, sd.authIds.size(), ONE_AUTHID);
    }

    @isTest
    private static void itShouldSerializeExcludingAccountsWithNoHubAccount() {
        // GIVEN we have an account
        Account account = retrieveAccount('Tester1');

        // AND there are no Hub Accounts
        delete [SELECT Id FROM Hub_Account__c];

        // WHEN passed to the BannerIdSync class
        SerializedData sd = serializeData(account);

        // THEN I expect it to serialize it correctly
        Assert.isTrue(sd.output.isEmpty(), 'I expect there to be no payloads');
    }

    class SerializedData {
        List<Map<String, Object>> output;
        Map<String, Object> detail;
        String studentRefNum;
        List<String> authIds;
    }
}
