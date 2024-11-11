/**
 * The contract expected for an Outbound event Serializer, a Serializer takes sObjects
 * and organises them into a schema
 */
public interface Serializer {
    /**
     * Adds an sObject to the list which is used to create the resulting payload
     * @param record The sObject record to add to the list
     */
    void addRecord(SObject record);

    /**
     * Serializes the sObjects added into a schema for external services
     * @return  A list of payloads to send to an Emitter
     */
    List<Map<String, Object>> serialize();
}