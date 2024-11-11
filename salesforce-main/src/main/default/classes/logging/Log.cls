/**
 * The Log class deals with creating and sending logs, the create and send method
 * are separated to allow transaction based bulk sending of logs. Logs can be created
 * across the lifecycle of a transaction and then sent at the end of the transaction.
 *
 * Log destinations are governed by LogTransports and severity levels, each level has
 * a corresponding LogTransport which is defined in the Log Setting object. If the
 * level is missing a LogTransport this means it won't fire, this allows us to add
 * debug logs to the code base without having system debugs everywhere and the ability
 * to switch them on for the org or an individual user/profile.
 */
public without sharing class Log {
    /**
     * Map of logs created in this transaction keyed by Transport type
     */
    @TestVisible
    private static Map<String, List<LogSchema>> logs = new Map<String, List<LogSchema>>();

    /**
     * Log Setting instance by org default or profile/user
     */
    @TestVisible
    private static Log_Setting__c settings = Log_Setting__c.getInstance();

    /**
     * Creates a log with the given severity and message and
     * adds to the transactional store.
     *
     * @param severity The severity level, DEBUG, WARN, ERROR
     * @param message The log message content
     */
    public static void create(String severity, String message) {
        LogSchema schema = new LogSchema(severity, message);
        String transport = getTransportFromSeverity(severity);

        if (transport == null) {
            return;
        }

        List<LogSchema> logStash = new List<LogSchema>();
        if (logs.containsKey(transport)) {
            logStash = logs.get(transport);
        }

        logStash.add(schema);

        logs.put(transport, logStash);
    }

    /**
     * Sends logs based on their transport type
     */
    public static void send() {
        for (String transportType : logs.keySet()) {
            LogTransport transport = getTransport(transportType);
            transport.send(logs.get(transportType));
        }

        // ensure the log list is cleared
        Log.logs = new Map<String, List<LogSchema>>();
    }

    /**
     * Creates a DEBUG level log
     * @param message The log message content
     */
    public static void debug(String message) {
        Log.create('DEBUG', message);
    }

    /**
     * Creates a DEBUG level log with an object type
     * @param message Object message content
     */
    public static void debug(Object message) {
        Log.create('DEBUG', message.toString());
    }

    /**
     * Creates a WARN level log
     * @param message The log message content
     */
    public static void warn(String message) {
        Log.create('WARN', message);
    }

    /**
     * Creates an ERROR level log
     * @param message The log message content
     */
    public static void error(String message) {
        Log.create('ERROR', message);
    }

    /**
     * Creates and sends an ERROR level log as a critical
     * @param message The log message content
     */
    public static void critical(String message) {
        Log.create('ERROR', message);
        Log.send();
    }

    /**
     * Creates and returns an instance of the given LogTransport class
     * @param className The LogTransport class name
     * @return  Instance of LogTransport class
     */
    private static LogTransport getTransport(String className) {
        return (LogTransport) Type.forName(className).newInstance();
    }

    /**
     * Returns the LogTransport class name as defined in custom settings
     * @param severity The severity level
     * @return  LogTransport class name
     */
    private static String getTransportFromSeverity(String severity) {
        switch on severity {
            when 'DEBUG' {
                return settings.Debug__c;
            }
            when 'WARN' {
                return settings.Warn__c;
            }
            when 'ERROR' {
                return settings.Error__c;
            }
        }

        return null;
    }
}
