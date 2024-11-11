/**
 * Used to send events via quick actions and LWC
 */
public without sharing class QuickActionSend {
    /**
     * Sends a student sync
     * @param record The sobject to sync from
     * @exception
     */
    @AuraEnabled
    public static void sendStudentSyncEvent(SObject record) {
        try {
            Serializer serializer = new StudentSync();
            serializer.addRecord(record);

            SendEvent(serializer, 'userAccountUpdated');
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
     * Sends the given events and payloads via the API
     * @param serializer The serializer instance
     * @param eventName The event name
     */
    private static void sendEvent(Serializer serializer, String eventName) {
        List<Map<String, Object>> payloads = new List<Map<String, Object>>();
        List<Map<String, Object>> details = serializer.serialize();

        // If details is empty, theres nothing to send
        if (details.isEmpty()) {
            return;
        }

        for (Map<String, Object> detail : details) {
            payloads.add(EventApiClient.wrapEvent(DateTime.now(), eventName, detail));
        }

        new EventApiClient().send(JSON.serialize(payloads));
    }
}
