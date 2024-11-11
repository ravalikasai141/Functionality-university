/**
 *  Abstract class for specific channel methods to process Queue Jobs
 */
public abstract class Channel implements Schedulable {
    @testVisible
    private static Messaging.SingleEmailMessage adminAlertEmail;

    public static final Integer DEFAULT_BATCH_LIMIT = 50;
    public static final Integer DEFAULT_QUERY_LIMIT = 50;
    public static final Integer DEFAULT_SCHEDULE_MINUTES = 1;

    /**
     *  Executes queue for the provided channel type then reschedules the Channel
     *  for the defined time in the future
     *
     *  @param  channel           Channel of the job that should begin processing
     *  @param  scheduleMinutes   The number of minutes to wait before running the channel class
     *  @param  queryLimit        The maximum limit of each query
     *  @param  batchLimit        The maximum amount of records each batch can process
     */
    public static void queueChannelJobs(
        String channel,
        Integer scheduleMinutes,
        Integer queryLimit,
        Integer batchLimit
    ) {
        String scheduleName = channel + 'Channel';

        // Cancel the in-flight channel job to allow us to schedule again as soon as required
        stopChannel(scheduleName);

        // If the flex queue is full, don't restart the channel. flex queue allows up to 100 batch jobs in holding
        if ([SELECT COUNT() FROM AsyncApexJob WHERE JobType = 'BatchApex' AND Status = 'Holding'] > 99) {
            String body = 'No new Queue Jobs have been ingested as the Flex Queue is full.';
            adminAlertEmail = EmailUtilities.submitSystemAlertEmail('Flex Queue is full', body);
        }
        // Otherwise, if there is at least one job of this type to process, do so
        else if (
            ![SELECT Id FROM Queue_Job__c WHERE Channel__c = :channel AND Status__c = 'Pending' LIMIT 1].isEmpty()
        ) {
            Savepoint sp = Database.setSavePoint();
            try {
                Database.executeBatch(new QueueJobBatch(channel, queryLimit), batchLimit);
            } catch (Exception ex) {
                Database.rollback(sp);
                String body = 'Failed to execute Queue Job batch of type "' + channel + '": ' + ex.getMessage();
                adminAlertEmail = EmailUtilities.submitSystemAlertEmail('Failed to execute new Queue Job batch', body);
            }
        }

        // Calculate the exact time X minutes into the future, determined by the extending Channel class
        DateTime xMinutesFromNow = DateTime.now().addMinutes(scheduleMinutes);
        String nextScheduleTime = xMinutesFromNow.second() + ' ' + xMinutesFromNow.minute() + ' * * * ?';

        // Schedule this job to run again in X minutes
        startChannel(scheduleName, scheduleName, nextScheduleTime);
    }

    /**
     *  Creates the channel for queues to begin processing jobs
     *
     *  @param  scheduleName  The name of queue job that should be picked up by the scheduled job
     *  @param  channelName  The name of channel class to schedule
     *  @param  startTime  The time that the new instance of channel should be ran
     */
    public static void startChannel(String scheduleName, String channelName, String startTime) {
        try {
            System.schedule(scheduleName, startTime, (Channel) Type.forName(channelName).newInstance());
        } catch (System.AsyncException e) {
            // The schedule already exist, we can safely ignore this
        }
    }

    /**
     *  Stops the given schedule
     *
     *  @param  scheduleName  The name of the scheduled job which should be stopped
     */
    public static void stopChannel(String scheduleName) {
        try {
            System.abortJob([SELECT Id FROM CronTrigger WHERE CronJobDetail.Name = :scheduleName].Id);
        } catch (System.QueryException e) {
            // The schedule does not exist, we can safely ignore this
        }
    }
}
