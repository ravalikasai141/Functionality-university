/**
 * The signature of a class to deserialize event payloads to
 */
public interface EventSchema {
    /**
     * Retrieves the Unique Key applicable for the given event
     *
     * @return The unique key for the event
     */
    String getUniqueKey(String jsonString);
}
