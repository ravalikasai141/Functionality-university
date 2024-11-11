/**
 * The contract expected from an Outbound event Emitter
 */
public interface Emitter {
    /**
     * Sends a list of payloads via the emitters outbound mechanism 
     * @param eventName The name of the event
     * @param payloads The list of payloads to send
     */
    void send(String eventName, List<Map<String, Object>> payloads);
}