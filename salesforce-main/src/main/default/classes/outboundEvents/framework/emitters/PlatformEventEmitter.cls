/**
 * An Emitter for Platform Events
 */
public class PlatformEventEmitter implements Emitter {
    @TestVisible
    private List<Database.SaveResult> results;

    /**
     * Emits Platform events for the given payloads
     * @param eventName The event name to assign the event to
     * @param payloads The list of payloads to send
     */
    public void send(String eventName, List<Map<String, Object>> payloads) {
        List<Outbound_Event__e> events = new List<Outbound_Event__e>();

        for (Map<String, Object> payload : payloads) {
            Outbound_Event__e event = new Outbound_Event__e(Detail__c = JSON.serialize(payload), Type__c = eventName);
            events.add(event);
            Log.debug(event.toString());
        }

        results = EventBus.publish(events);
        Log.send();
    }
}
