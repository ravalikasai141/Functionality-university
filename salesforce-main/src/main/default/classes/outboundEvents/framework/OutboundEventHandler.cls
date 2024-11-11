/**
 * Used in the Outbound Event trigger handler, processes events
 * and enqueues the EventQueueable job
 */
public without sharing class OutboundEventHandler {

    /**
     * Processes the given events and enqueues the queuable job
     * @param events A list of events to process
     */
    public void process(List<Outbound_Event__e> events) {
        List<Object> payloads = new List<Object> ();

        for (Outbound_Event__e event : events) {
            Map<String, Object> detail = (Map<String, Object>)JSON.deserializeUntyped(event.Detail__c);
            payloads.add(
                EventApiClient.wrapEvent(
                    event.CreatedDate,
                    event.Type__c,
                    detail
            ));
        }

        System.enqueueJob(new EventQueueable(JSON.serialize(payloads)));
    }
}