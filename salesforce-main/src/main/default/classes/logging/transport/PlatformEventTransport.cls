/**
 * Platform Event Log Transport is designed to work for NewRelic
 * logs, this will create an internally consumed platform event
 * which will fire logs over an API to NewRelic.
 */
public class PlatformEventTransport implements LogTransport {
    /**
     * Creates a Log__e platform event and publishes the events
     * @param logs List of logs to be sent
     */
    public void send(List<LogSchema> logs) {
        List<Log__e> outbound = new List<Log__e>();

        for (LogSchema log : logs) {
            outbound.add(new Log__e(Data__c = JSON.serialize(log)));
        }

        EventBus.publish(outbound);
    }
}
