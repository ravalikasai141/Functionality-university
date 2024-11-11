/**
 * LogTransport is used to send logs to a specific destination
 */
public interface LogTransport {
    /**
     * Sends or processes the list of Logs
     * @param logs List of logs to be sent
     */
    void send(List<LogSchema> logs);
}
