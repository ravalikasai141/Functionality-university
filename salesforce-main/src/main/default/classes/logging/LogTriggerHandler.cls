/**
 * Handles log events in bulk, this will result in a queueable that
 * sends all the given logs to New Relic via an API.
 */
public without sharing class LogTriggerHandler {
    /**
     * Processes the logs and creates a queueable to send them to
     * New Relic via API.
     * @param logs The given list of logs from trigger
     */
    public void process(List<Log__e> logs) {
        List<Object> payload = new List<Object>();

        for (Log__e log : logs) {
            Map<String, Object> detail = (Map<String, Object>) JSON.deserializeUntyped(log.Data__c);
            payload.add(detail);
        }

        System.enqueueJob(new LogQueueable(payload));
    }
}
