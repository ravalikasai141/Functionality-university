/**
 * Queueable to allow us to send a Http Request to NewRelic
 * off the back of the Log Trigger
 */
public class LogQueueable implements Queueable, Database.AllowsCallouts {
    /**
     * List of logs to send
     */
    private List<Object> logs;

    /**
     * Used to keep track of retries if the callout
     * fails
     */
    @TestVisible
    private Integer retries = 0;

    /**
     * Default Construct
     * @param logs List of logs
     */
    public LogQueueable(List<Object> logs) {
        this.logs = logs;
    }

    /**
     * Executes the Queueable and sends logs to NewRelic via
     * the client class
     * @param context QueueableContext
     */
    public void execute(QueueableContext context) {
        NewRelicClient client = new NewRelicClient();
        
        try {
            client.send(logs);
        } catch (CalloutException e) {
            retries++;

            if (retries > 3) {
                throw e;
            }
            
            if (!System.Test.isRunningTest()) {
                System.enqueueJob(this, 1);
            }
        }
    }
}
