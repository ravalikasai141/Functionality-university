/**
 * Queueable class that orchestrates sending events to the Events API
 */
public class EventQueueable implements Queueable, Database.AllowsCallouts {
    /**
     * JSON Serialized list of events
     */
    private String eventPayloads;

    /**
     * Used to keep track of retries if the callout
     * fails
     */
    @TestVisible
    private Integer retries = 0;

    /**
     * Constructor to set event payloads
     * @param eventPayloads JSON serialized list of events
     */
    public EventQueueable(String eventPayloads) {
        this.eventPayloads = eventPayloads;
    }

    /**
     * Sends event payloads to the Event API Client
     * @param context QueueableContext
     */
    public void execute(QueueableContext context) {
        EventApiClient client = new EventApiClient();

        try {
            client.send(eventPayloads);
        } catch (CalloutException e) {
            retries++;

            if (retries > 3) {
                Log.critical(
                    'Max retries reached for outbound event: ' + e.getMessage() + ' ' + e.getStackTraceString()
                );
                throw e;
            }

            if (!System.Test.isRunningTest()) {
                System.enqueueJob(this, 1);
            }
        }
    }
}
