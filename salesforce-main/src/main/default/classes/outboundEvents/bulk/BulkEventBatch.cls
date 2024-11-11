/**
 * Generic batch job that sends out events directly via the event API
 */
public class BulkEventBatch implements Database.Batchable<SObject>, Database.AllowsCallouts {

    /**
     * Instance of the serializer class
     */
    private Serializer serializer;

    /**
     * The event name
     */
    private String eventName;

    /**
     * The query to use in start
     */
    private String query;

    /**
     * Construct to set batch details
     * @param query The query to find event trigger records
     * @param eventName The event name
     * @param serializer The instance of the serializer
     */
    public BulkEventBatch(String query, String eventName, Serializer serializer) {
        this.query = query;
        this.eventName = eventName;
        this.serializer = serializer;
    }

    /**
     * Returns the query locator from the given query
     * @param bc BatchableContext
     * @return  Querylocator
     */
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(query);
    }

    /**
     * Adds records to serializer, serializes and sends direct to event api
     * @param bc Batchable Context
     * @param records Records to add to serializer
     */
    public void execute(Database.BatchableContext bc, List<SObject> records) {
        for (SObject record : records) {
            serializer.addRecord(record);
        }

        List<Map<String, Object>> payloads = new List<Map<String, Object>> ();
        List<Map<String, Object>> details = serializer.serialize();

        if (details.isEmpty()) {
            return;
        }

        for (Map<String, Object> detail : details) {
            payloads.add(
                EventApiClient.wrapEvent(
                    DateTime.now(),
                    eventName,
                    detail
            ));
        }

        new EventApiClient().send(JSON.serialize(payloads));
    }

    public void finish(Database.BatchableContext bc) {}
}