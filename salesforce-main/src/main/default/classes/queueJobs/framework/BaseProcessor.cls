/**
 * Defines the base implementation of the Processor interface's methods
 */
public abstract class BaseProcessor implements Processor {
    public static final Integer MAX_FAIL_COUNT = 5;

    /**
     * Maps unsuccessfully processed jobs which will not be reprocessed to their failure message
     */
    @testVisible
    protected Map<Queue_Job__c, String> failedJobs = new Map<Queue_Job__c, String>();

    /**
     * Maps unsuccessfully processed jobs to be reprocessed to their failure message
     */
    @testVisible
    protected Map<Queue_Job__c, String> retryJobs = new Map<Queue_Job__c, String>();

    /**
     * Jobs to return for future processing
     */
    @testVisible
    protected List<Queue_Job__c> returnJobs = new List<Queue_Job__c>();

    /**
     * Successfully processed jobs
     */
    @testVisible
    protected List<Queue_Job__c> successfulJobs = new List<Queue_Job__c>();

    /**
     * {@inheritDoc}
     */
    public List<Queue_Job__c> process(List<Queue_Job__c> jobs) {
        // Prevent events being fired off the back of an inbound event
        StreamingService.preventStream = true;

        Savepoint sp = Database.setSavePoint();

        try {
            processImpl(jobs);
        } catch (Exception ex) {
            Database.rollback(sp);
            // Reset all Job outcomes determined within the implementation method
            successfulJobs.clear();
            retryJobs.clear();
            failedJobs.clear();

            // Fail all jobs that were provided with an unhandled exception message
            for (Queue_Job__c jobToFail : jobs) {
                failedJobs.put(jobToFail, ex.getMessage());
            }
        }

        returnJobs.addAll(processSuccesses());
        returnJobs.addAll(processFails());
        returnJobs.addAll(processRetries());

        return returnJobs;
    }

    /**
     * Abstract method to be uniquely implemented on each Processor to process Queue Jobs accordingly
     *
     * @param  jobs  Queue Jobs to be processed by the processor
     */
    abstract void processImpl(List<Queue_Job__c> jobs);

    /**
     * Process successful queue jobs
     *
     * @return A list of Queue Jobs with Statuses indicating successful processing
     */
    @testVisible
    protected List<Queue_Job__c> processSuccesses() {
        for (Queue_Job__c job : successfulJobs) {
            job.Status__c = 'Processed';
        }
        return successfulJobs;
    }

    /**
     * Process failed queue jobs, incrementing their failure count and updating their Error fields
     *
     * @return A list of Queue Jobs with Statuses indicating failed processing
     */
    @testVisible
    protected Set<Queue_Job__c> processFails() {
        for (Queue_Job__c currentFailedJob : failedJobs.keySet()) {
            QueueJobUtilities.updateErrorMessages(currentFailedJob, failedJobs.get(currentFailedJob));

            Decimal failCount = currentFailedJob.Failure_Count__c == null ? 1 : currentFailedJob.Failure_Count__c + 1;
            currentFailedJob.Failure_Count__c = failCount;

            currentFailedJob.Status__c = 'Failed';
        }

        return failedJobs.keySet();
    }

    /**
     * Process queue jobs to retry, incrementing their failure count and updating their Error fields, eventually
     * failing the job if the failure count surpasses the maximum count
     *
     * @return A list of Queue Jobs with Statuses indicating failed processing
     */
    @testVisible
    protected Set<Queue_Job__c> processRetries() {
        for (Queue_Job__c currentRetryJob : retryJobs.keySet()) {
            QueueJobUtilities.updateErrorMessages(currentRetryJob, retryJobs.get(currentRetryJob));

            Decimal failCount = currentRetryJob.Failure_Count__c == null ? 1 : currentRetryJob.Failure_Count__c + 1;
            currentRetryJob.Failure_Count__c = failCount;

            currentRetryJob.Status__c = currentRetryJob.Failure_Count__c >= BaseProcessor.MAX_FAIL_COUNT
                ? 'Failed'
                : 'Pending';
        }

        return retryJobs.keySet();
    }

    /**
     * Sets error message on job where DML Error has been thrown
     * @param  job    Job to fail
     * @param  errors errors to create error message from
     */
    @testVisible
    protected void processDMLErrors(Queue_Job__c job, List<Database.Error> errors) {
        List<String> errorMessages = new List<String>();
        for (Database.Error error : errors) {
            errorMessages.add(error.getMessage());
        }

        failedJobs.put(job, String.join(errorMessages, ' | '));
    }
}
