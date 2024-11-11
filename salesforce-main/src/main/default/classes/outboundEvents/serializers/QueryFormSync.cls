public without sharing class QueryFormSync implements Serializer {

    /**
     * The set of Case ids that form part of this event
     */
    private Set<Id> caseIds;

    /**
     * List of cases related to the case ids
     */
    private List<Case> cases;

    /**
     * A set of student account ids
     */
    public Set<Id> accountIds;

    /**
     * A map of Auth0 Id's keyed by Account Id
     */
    private Map<Id, List<String>> authIds;

    public QueryFormSync() {
        caseIds = new Set<Id>();
        cases = new List<Case>();
        accountIds = new Set<Id>();
    }

    /**
     * Adds the given Case to the id list
     * @param record SObject to add to the record
     */
    public void addRecord(SObject record) {
        switch on record.getSObjectType().getDescribe().getName() {
            when 'Case' {
                caseIds.add(record.Id);
            }
        }
    }

    /**
     * Creates a list of event payloads
     * @return  Payloads to send to an Emitter
     */
    public List<Map<String, Object>> serialize() {
        List<Map<String, Object>> payloads = new List<Map<String, Object>>();

        // Fetch cases and List of AuthIds
        fetchCases();
        fetchAuthIds();

        for (Case cs : cases) {
            if (!authIds.containsKey(cs.AccountId)) {
                continue;
            } 
            Map<String, Object> payload = new Map<String, Object>{
                'auth0Ids' => authIds.get(cs.AccountId),
                'externalId' => cs.Query_Id__c,
                'caseName' => cs.CaseNumber,
                'status' => cs.Status,
                'updatedDate' => cs.LastModifiedDate
            };

            payloads.add(payload);
        }
        return payloads;
    }

    /**
     * Fetches the cases using the related case set
     */
    private void fetchCases() {
        cases = new List<Case>();
        for (Case cs : [
            SELECT
                Id,
                Query_Id__c,
                CaseNumber,
                Status,
                LastModifiedDate,
                AccountId 
            FROM Case
            WHERE Id IN :caseIds
            AND Origin = 'Web'
            AND Query_Id__c != null
        ]) {
            cases.add(cs);
            accountIds.add(cs.AccountId);
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