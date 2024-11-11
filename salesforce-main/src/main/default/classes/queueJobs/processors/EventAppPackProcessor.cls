/**
 * Processor for the app pack generation event
 */
public without sharing class EventAppPackProcessor extends BaseProcessor {
    /**
     * Map of applicationId to queue job
     */
    private Map<String, Queue_Job__c> applicationToQueue = new Map<String, Queue_Job__c>();

    /**
     * List of documents that need to be upserted
     */
    private List<External_Document__c> documentsToUpsert = new List<External_Document__c>();

    /**
     * List of events that need to be processed
     */
    private List<AppPackSchema> events = new List<AppPackSchema>();

    /**
     * Processes the given queue jobs and creates documents
     * @param queueJobs Queue jobs to process
     */
    public void processImpl(List<Queue_Job__c> queueJobs) {
        deserializeEvents(queueJobs);

        for (AppPackSchema event : events) {
            External_Document__c appPackDocument = new External_Document__c(
                Document_ID__c = event.appPackDocumentId,
                Type__c = 'Application Pack',
                Opportunity__r = new Opportunity(Application_Id__c = event.applicationId)
            );

            documentsToUpsert.add(appPackDocument);
        }

        processDML();
    }

    /**
     * Deserializes the event content and checks required fields
     * @param queueJobs List of queue jobs
     */
    private void deserializeEvents(List<Queue_Job__c> queueJobs) {
        for (Queue_Job__c job : queueJobs) {
            AppPackSchema event = (AppPackSchema) JSON.deserialize(job.Job_Content__c, AppPackSchema.class);

            Map<String, String> requiredFields = new Map<String, String>{
                'Application Id' => event?.applicationId,
                'App pack document Id' => event?.appPackDocumentId
            };

            List<String> requiredFieldErrors = new List<String>();
            for (String potentialError : requiredFields.keySet()) {
                if (String.isBlank(requiredFields.get(potentialError))) {
                    requiredFieldErrors.add(potentialError);
                }
            }

            if (!requiredFieldErrors.isEmpty()) {
                failedJobs.put(
                    job,
                    'Required value(s) ' + String.join(requiredFieldErrors, ', ') + ' are null in event payload'
                );
                continue;
            }

            applicationToQueue.put(event.applicationId, job);
            events.add(event);
        }
    }

    /**
     * Processes the DML
     */
    private void processDML() {
        List<Database.UpsertResult> docResults = Database.Upsert(
            documentsToUpsert,
            External_Document__c.Document_ID__c.getDescribe().getSObjectField(),
            false
        );
        for (Integer i = 0; i < docResults.size(); i++) {
            Database.UpsertResult result = docResults[i];
            if (!result.isSuccess()) {
                String applicationId = documentsToUpsert[i].Opportunity__r.Application_Id__c;
                processDMLErrors(applicationToQueue.get(applicationId), result.getErrors());
                applicationToQueue.remove(applicationId);
            }
        }

        for (String applicationId : applicationToQueue.keySet()) {
            successfulJobs.add(applicationToQueue.get(applicationId));
        }
    }
}
