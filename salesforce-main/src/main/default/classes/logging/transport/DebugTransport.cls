/**
 * DebugTransport simply debug logs - can be used to display
 * debug and non-important messages and help debugging issues
 * on non-production environments.
 */
public class DebugTransport implements LogTransport {
    /**
     * Debugs the given logs
     * @param logs List of logs
     */
    public void send(List<LogSchema> logs) {
        for (LogSchema log : logs) {
            System.debug(logString(log));
        }
    }

    /**
     * Returns a formatted string for logging
     * @param log The given log
     * @return  A log display string
     */
    private String logString(LogSchema log) {
        return String.format(
            'message={0} level={1} date={2}',
            new List<String>{ log.message, log.level, log.timestamp.toString() }
        );
    }
}
