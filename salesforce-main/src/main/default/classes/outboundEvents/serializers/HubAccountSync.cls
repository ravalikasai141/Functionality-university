/**
 * This event serializer is used to sync the deletion of userIds on external systems
 */
public without sharing class HubAccountSync implements Serializer {
    /**
     * A set of Auth0 Ids
     */
    private Set<String> userIds;

    public HubAccountSync() {
        userIds = new Set<String>();
    }

    /**
     * processes a record and adds to the userIds set
     * @param record Currently only supports Hub Account
     */
    public void addRecord(SObject record) {
        if (record.getSObjectType().getDescribe().getName() == 'Hub_Account__c') {
            userIds.add((String) record.get('Auth0_Id__c'));
        }
    }

    /**
     * Serializes the data we gathered during addRecord
     * @return  Payloads of data
     */
    public List<Map<String, Object>> serialize() {
        List<Map<String, Object>> payloads = new List<Map<String, Object>>();

        for (String userId : userIds) {
            Map<String, Object> payload = new Map<String, Object>{ 'userIds' => new List<String>{ userId } };

            payloads.add(payload);
        }

        return payloads;
    }
}
