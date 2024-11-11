/**
 *  This class creates batches of Queue Job records of a given Channel which are subsequently sent to their associated processor
 */
public class QueueJobBatch implements Database.Batchable<Queue_Job__c>, Database.AllowsCallouts, Database.Stateful {
    @testVisible
    private static Messaging.SingleEmailMessage failedUpdateEmail;

    /**
     *  List of Queue Jobs ready to be mapped then processed
     */
    @testVisible
    private List<Queue_Job__c> providedQueueJobs;

    /**
     *  List of Queue Jobs which will be upserted in finish()
     */
    @testVisible
    private List<Queue_Job__c> returnJobs = new List<Queue_Job__c>();

    // Define the top level schema for each Processor along with the class name indicator for that Processor
    public static Map<String, ProcessorDetail> typeToProcessorDetail = new Map<String, ProcessorDetail>{
        'userAccountUpdated' => new ProcessorDetail(UserAccountUpdatedSchema.class, 'userAccountUpdated'),
        'applicationCreated' => new ProcessorDetail(ApplicationSchema.class, 'Application'),
        'applicationUpdated' => new ProcessorDetail(ApplicationSchema.class, 'Application'),
        'documentUploaded' => new ProcessorDetail(DocumentSchema.class, 'DocumentUploaded'),
        'documentFailed' => new ProcessorDetail(DocumentSchema.class, 'DocumentUploaded'),
        'documentDeleted' => new ProcessorDetail(DocumentSchema.class, 'DocumentUploaded'),
        'applicationStageChanged' => new ProcessorDetail(ApplicationStageSchema.class, 'Stage'),
        'applicationWithdrew' => new ProcessorDetail(ApplicationWithdrewSchema.class, 'Withdrew'),
        'applicationEligibilitySubmitted' => new ProcessorDetail(EligibilitySchema.class, 'Eligibility'),
        'queryFormSubmitted' => new ProcessorDetail(CaseSchema.class, 'Case'),
        'applicationAppPackGenerated' => new ProcessorDetail(AppPackSchema.class, 'AppPack'),
        'requestCallbackForm' => new ProcessorDetail(RequestForInformationSchema.class, 'RequestForInformation')
    };

    /**
     *  Default unused constructor
     */
    public QueueJobBatch() {
    }

    /**
     * Constructor to query out any relevant Queue Jobs to be processed, update their Statuses
     * and pass them to the individual batch instances
     *
     * @param  channelName  The channel type of the Queue Jobs that should be processed in this batch
     * @param  queryLimit  The amount of Queue Job records that should be processed in this batch
     */
    public QueueJobBatch(String channelName, Integer queryLimit) {
        providedQueueJobs = [
            SELECT
                Name,
                Event_Time__c,
                Channel__c,
                Job_Type__c,
                Errors__c,
                Status__c,
                Failure_Count__c,
                Job_Content__c,
                OwnerId
            FROM Queue_Job__c
            WHERE Channel__c = :channelName AND Status__c = 'Pending'
            ORDER BY Event_Time__c, Name
            LIMIT :queryLimit
        ];

        for (Queue_Job__c currentJob : providedQueueJobs) {
            currentJob.Status__c = 'Processing';

            // Get the schema for the given event
            Type schemaType = typeToProcessorDetail.get(currentJob.Job_Type__c)?.schemaClass;

            if (schemaType == null) {
                continue;
            }

            try {
                // Retrieve the unique key from the retrieved schema
                currentJob.Unique_Key__c = ((EventSchema) schemaType.newInstance())
                    .getUniqueKey(currentJob.Job_Content__c);
            } catch (Exception error) {
                currentJob.Status__c = 'Failed';
                String errorMessage = 'Queue Job Batch error: "' + error.getMessage() + '"';

                QueueJobUtilities.updateErrorMessages(currentJob, errorMessage);
            }
        }

        update providedQueueJobs;
    }

    /**
     *  Passes to the execute method the jobs that were set via the constructor
     *
     *  @param  bc  The batchable context object
     *  @return  An iterable of the records set in constructor which will be split across all batches "execute" methods
     */
    public Iterable<Queue_Job__c> start(Database.BatchableContext bc) {
        return providedQueueJobs;
    }

    /**
     *  Processes the list of provided Queue Job records, creates and then executes any processors using the Job Type of each record
     *
     *  @param  bc  The batchable context object
     *  @param  queueJobs  The records which are to be processed in this specific batch run
     */
    public void execute(Database.BatchableContext bc, List<Queue_Job__c> queueJobs) {
        // Map all jobs together by their Channel and Job Type concatenated to form part of its related Processors class name
        Map<String, List<Queue_Job__c>> queueJobsByJobType = new Map<String, List<Queue_Job__c>>();
        for (Queue_Job__c job : queueJobs) {
            // Do not process any jobs that have been failed in the constructor
            if (job.Status__c != 'Processing') {
                continue;
            }

            String jobType = job.Job_Type__c.replaceAll('\\s+', '');

            // Sometimes we have the same processor for two events
            if (typeToProcessorDetail.containsKey(jobType)) {
                jobType = typeToProcessorDetail.get(jobType).jobType;
            }

            // remove all spaces and append "Processor" to the end
            String processorName = (job.Channel__c + jobType).replaceAll('\\s+', '') + 'Processor';

            if (queueJobsByJobType.containsKey(processorName)) {
                queueJobsByJobType.get(processorName).add(job);
            } else {
                queueJobsByJobType.put(processorName, new List<Queue_Job__c>{ job });
            }
        }

        // Loop over all channel + job types that must be processed and cast them into
        for (String processorName : queueJobsByJobType.keySet()) {
            Type processorType = Type.forName(processorName);

            // If a matching Processor is identified, create an instance of it and process all Queue Jobs of that type using this processor
            if (processorType != null) {
                returnJobs.addAll(
                    ((Processor) processorType.newInstance()).process(queueJobsByJobType.get(processorName))
                );
                continue;
            }

            // Otherwise loop over each of the Queue Jobs of this type and mark them as failed
            for (Queue_Job__c currentJob : queueJobsByJobType.get(processorName)) {
                currentJob.Status__c = 'Blocked';
                String errorMessage = 'Processor type ' + processorName + ' not found.';

                returnJobs.add(QueueJobUtilities.updateErrorMessages(currentJob, errorMessage));
            }
        }
    }

    /**
     *  {@inheritDoc}
     *
     *  Upsert any returned Queue Jobs and email the Admin team to inform them of any failures if there are any
     *
     *  @param  bc  The batchable context object
     */
    public void finish(Database.BatchableContext bc) {
        List<Queue_Job__c> failedJobs = new List<Queue_Job__c>();

        try {
            // Update the Jobs to set their statuses
            Database.upsert(returnJobs, false);

            // Extract failed jobs so we can send any required notifications
            for (Queue_Job__c job : returnJobs) {
                if (job.Status__c == 'Failed') {
                    failedJobs.add(job);
                }
            }

            if (failedJobs.size() > 0) {
                QueueJobUtilities.buildAndSendFailedJobsEmail(failedJobs);
            }
        } catch (Exception ex) {
            Log.critical('Queue jobs failed to update: ' + ex.getMessage() + ' ' + ex.getStackTraceString());
            buildAndSendUnhandledError(ex.getMessage(), returnJobs);
        }
    }

    /**
     *  Builds up and sends an email to members of the Admin Alert Recipient group with the details of all
     *  jobs which failed to upsert
     *
     *  @param  exceptionMessage  The batchable context object
     *  @param  queueJobs  The records which the Admin team should be informed about
     */
    @testVisible
    private static void buildAndSendUnhandledError(String exceptionMessage, List<Queue_Job__c> queueJobs) {
        String body = 'Queue Jobs have failed to update: ' + exceptionMessage + ' | Jobs: ' + JSON.serialize(queueJobs);
        failedUpdateEmail = EmailUtilities.submitSystemAlertEmail('Queue Job Update has failed', body);
    }

    /**
     * Wrapper class to store details around a Processes class and the primary schema it should deserialize into
     */
    private class ProcessorDetail {
        private Type schemaClass;
        private String jobType;

        private ProcessorDetail(Type schemaClass, String jobType) {
            this.schemaClass = schemaClass;
            this.jobType = jobType;
        }
    }
}
