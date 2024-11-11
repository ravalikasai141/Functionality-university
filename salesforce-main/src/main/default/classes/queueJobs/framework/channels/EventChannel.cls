/**
 * Schedulable class to periodically process events
 */
global class EventChannel extends Channel implements Schedulable {
    /**
     * Execute channel method to trigger the processing of "Event" Queue Jobs
     *
     * @param  sc  The schedulable context
     */
    global void execute(SchedulableContext sc) {
        queueChannelJobs('Event', DEFAULT_SCHEDULE_MINUTES, DEFAULT_QUERY_LIMIT, DEFAULT_BATCH_LIMIT);
    }
}
