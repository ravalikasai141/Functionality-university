/**
 * Handles serializing payloads for the `auth0SRNMappingUpdated` event
 */
public without sharing class BannerIdSync implements Serializer {
    /**
     * A set of account ids
     */
    public Set<Id> accountIds;

    /**
     * A List of accounts to process
     */
    @TestVisible
    private List<Account> accounts;

    /**
     * A map of Auth0 Id's keyed by Account Id
     */
    private Map<Id, List<String>> authIds;

    public BannerIdSync() {
        accounts = new List<Account>();
        accountIds = new Set<Id>();
    }

    /**
     * Adds the given account to the map to process
     * @param record Account to process
     */
    public void addRecord(SObject record) {
        // Figure out which Sobject type is being added
        switch on record.getSObjectType().getDescribe().getName() {
            when 'Account' {
                accountIds.add(record.Id);
            }
            when 'Hub_Account__c' {
                accountIds.add((Id) record.get('Student__c'));
            }
        }
    }

    /**
     * Collects the various dependent records and creates payloads
     * @return  Payloads to send to an Emitter
     */
    public List<Map<String, Object>> serialize() {
        List<Map<String, Object>> payloads = new List<Map<String, Object>>();

        fetchAccounts();
        fetchAuthIds();

        for (Account account : accounts) {
            if (!authIds.containsKey(account.Id)) {
                continue;
            }

            Map<String, Object> payload = new Map<String, Object>{
                'userIds' => authIds.get(account.Id),
                'bannerID' => account.BNR_Banner_ID__pc
            };

            payloads.add(payload);
        }

        return payloads;
    }

    /**
     * Fetches the accounts using the related account set
     */
    private void fetchAccounts() {
        for (Account account : [
            SELECT Id, BNR_Banner_ID__pc
            FROM Account
            WHERE Id IN :accountIds
        ]) {
            accounts.add(account);
        }
    }

    /**
     * Fetches the related Hub Account records and processes the Auth0 Id's
     */
    private void fetchAuthIds() {
        authIds = new Map<Id, List<String>>();

        for (Hub_Account__c hubAccount : [
            SELECT Auth0_Id__c, Student__c
            FROM Hub_Account__c
            WHERE Student__c IN :accountIds AND Auth0_Id__c != NULL
        ]) {
            List<String> ids = authIds.get(hubAccount.Student__c);

            if (ids == null) {
                ids = new List<String>();
            }

            ids.Add(hubAccount.Auth0_Id__c);
            authIds.put(hubAccount.Student__c, ids);
        }
    }
}
