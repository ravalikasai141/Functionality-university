/**
 * Processor for the Application withdrew events
 */
public class EventWithdrewProcessor extends BaseProcessor {
    private Map<String, Queue_Job__c> applicationToQueue = new Map<String, Queue_Job__c>();
    private Map<String, ApplicationWithdrewSchema> applicationToSchema = new Map<String, ApplicationWithdrewSchema>();

    private Map<String, Opportunity> oppsToUpdate = new Map<String, Opportunity>();
    private Map<String, List<KSB__c>> applicationIdToKSBsToDelete = new Map<String, List<KSB__c>>();
    private Map<String, List<External_Document__c>> applicationIdToExternalDocumentsToDelete = new Map<String, List<External_Document__c>>();
    private Map<String, List<Application_Review__c>> applicationIdToApplicationReviewsToDelete = new Map<String, List<Application_Review__c>>();

    /**
     * Processes the queue jobs and updates relevant applications
     * @param queueJobs List of queue jobs to process
     */
    public void processImpl(List<Queue_Job__c> queueJobs) {
        // deserialize event
        deserializeEvents(queueJobs);

        for (Opportunity opp : [
            SELECT
                Id,
                Application_ID__c,
                StageName,
                BPP_Sub_Status__c,
                BPP_Cancellation_Reason__c,
                recordType.DeveloperName,
                (SELECT Id FROM KSBs__r),
                (SELECT Id FROM External_Documents__r),
                (SELECT Id FROM Application_Reviews__r)
            FROM Opportunity
            WHERE Application_Id__c IN :applicationToSchema.keySet()
        ]) {
            applicationToSchema.remove(opp.Application_Id__c);

            applicationIdToKSBsToDelete.put(opp.Application_Id__c, opp.KSBs__r);
            applicationIdToExternalDocumentsToDelete.put(opp.Application_Id__c, opp.External_Documents__r);
            applicationIdToApplicationReviewsToDelete.put(opp.Application_Id__c, opp.Application_Reviews__r);

            switch on opp.recordType.DeveloperName {
                when 'Student_Application' {
                    opp.StageName = 'Cancelled';
                }
                when 'Student_Interest' {
                    opp.StageName = 'No Longer Interested';
                }
                when 'Apprentice_Application' {
                    opp.StageName = 'Closed Lost';
                }
            }

            opp.BPP_Sub_Status__c = 'Withdrawn';
            opp.BPP_Cancellation_Reason__c = 'appWithdrawApplicant';

            //Update opportunity to withdrawn
            oppsToUpdate.put(opp.Application_Id__c, opp);
        }

        // Any jobs remaining in the applicationToSchema map are missing in Salesforce and should be failed
        for (String missingApplicationId : applicationToSchema.keySet()) {
            failedJobs.put(
                applicationToQueue.get(missingApplicationId),
                'The given Application Id does not exist in Salesforce.'
            );
        }

        processDML();
    }

    /**
     * Processes the DML and updates given opportunities
     */
    private void processDML() {
        Set<String> successfulApplicationIds = oppsToUpdate.keySet();

        // Process updating Opportunities
        List<Database.SaveResult> oppResults = Database.Update(oppsToUpdate.values(), false);
        for (Integer i = 0; i < oppResults.size(); i++) {
            Database.SaveResult oppResult = oppResults[i];
            if (!oppResult.isSuccess()) {
                String applicationId = new List<String>(oppsToUpdate.keySet())[i];
                processDMLErrors(applicationToQueue.get(applicationId), oppResult.getErrors());
                successfulApplicationIds.remove(applicationId);

                // Stop any further records from being processed
                applicationIdToKSBsToDelete.remove(applicationId);
                applicationIdToExternalDocumentsToDelete.remove(applicationId);
                applicationIdToApplicationReviewsToDelete.remove(applicationId);
            }
        }

        // KSBs
        // Map any remaining Application Reviews by the Application Id of the Opp they are linked to
        Map<SObject, String> ksbToApplicationId = mapObjectsByAppId(applicationIdToKSBsToDelete);

        List<Database.DeleteResult> ksbResults = Database.Delete(
            (List<KSB__c>) (new List<SObject>(ksbToApplicationId.keySet())),
            false
        );
        for (Integer i = 0; i < ksbResults.size(); i++) {
            Database.DeleteResult ksbResult = ksbResults[i];
            if (!ksbResult.isSuccess()) {
                String applicationId = ksbToApplicationId.values()[i];
                processDMLErrors(applicationToQueue.get(applicationId), ksbResult.getErrors());
                successfulApplicationIds.remove(applicationId);

                // Stop any further records from being processed
                applicationIdToExternalDocumentsToDelete.remove(applicationId);
                applicationIdToApplicationReviewsToDelete.remove(applicationId);
            }
        }

        // EXTERNAL DOCUMENTS
        // Map any remaining Application Reviews by the Application Id of the Opp they are linked to
        Map<SObject, String> externalDocsToApplicationId = mapObjectsByAppId(applicationIdToExternalDocumentsToDelete);

        List<Database.DeleteResult> externalDocResults = Database.Delete(
            (List<External_Document__c>) (new List<SObject>(externalDocsToApplicationId.keySet())),
            false
        );
        for (Integer i = 0; i < externalDocResults.size(); i++) {
            Database.DeleteResult externalDocResult = externalDocResults[i];
            if (!externalDocResult.isSuccess()) {
                String applicationId = externalDocsToApplicationId.values()[i];
                processDMLErrors(applicationToQueue.get(applicationId), externalDocResult.getErrors());
                successfulApplicationIds.remove(applicationId);

                // Stop any further records from being processed
                applicationIdToApplicationReviewsToDelete.remove(applicationId);
            }
        }

        // APPLICATION REVIEWS
        // Map any remaining Application Reviews by the Application Id of the Opp they are linked to
        Map<SObject, String> appReviewsToApplicationId = mapObjectsByAppId(applicationIdToApplicationReviewsToDelete);

        List<Database.DeleteResult> appReviewResults = Database.Delete(
            (List<Application_Review__c>) (new List<SObject>(appReviewsToApplicationId.keySet())),
            false
        );
        for (Integer i = 0; i < appReviewResults.size(); i++) {
            Database.DeleteResult appReviewResult = appReviewResults[i];
            if (!appReviewResult.isSuccess()) {
                String applicationId = appReviewsToApplicationId.values()[i];
                processDMLErrors(applicationToQueue.get(applicationId), appReviewResult.getErrors());
                successfulApplicationIds.remove(applicationId);

            }
        }

        // Mark any remaining jobs as successful
        for (String applicationId : successfulApplicationIds) {
            successfulJobs.add(applicationToQueue.get(applicationId));
        }
    }

    /**
     *  Flattens a map of Application Ids to all records linked to it to a map of those records to their Application Ids
     *
     *  @param mapToConvert A Map of Application Ids to a list of records linked to it
     *  @return A flattened map of those records to their associated Application Ids
     */
    private Map<SObject, String> mapObjectsByAppId(Map<String, List<SObject>> mapToConvert) {
        Map<SObject, String> sObjectToAppId = new Map<SObject, String>();

        for (String applicationId : mapToConvert.keySet()) {
            for (SObject recordKey : mapToConvert.get(applicationId)) {
                sObjectToAppId.put(recordKey, applicationId);
            }
        }

        return sObjectToAppId;
    }

    /**
     * deserializes job content and adds to lists to be processed
     * @param  queueJobs Queue Jobs being processed
     */
    public void deserializeEvents(List<Queue_Job__c> queueJobs) {
        for (Queue_Job__c queueJob : queueJobs) {
            ApplicationWithdrewSchema event = (ApplicationWithdrewSchema) JSON.deserialize(
                queueJob.Job_Content__c,
                ApplicationWithdrewSchema.class
            );

            Map<String, String> requiredFieldMap = new Map<String, String>{ 'Application Id' => event?.applicationId };

            // Identify any required fields which are blank so we can fail the job
            List<String> requiredFieldErrors = new List<String>();
            for (String potentialError : requiredFieldMap.keySet()) {
                if (String.isBlank(requiredFieldMap.get(potentialError))) {
                    requiredFieldErrors.add(potentialError);
                }
            }

            if (!requiredFieldErrors.isEmpty()) {
                failedJobs.put(
                    queueJob,
                    'Required value(s) ' + String.join(requiredFieldErrors, ', ') + ' are null in event payload'
                );
                continue;
            }

            // If we have already mapped an event with a given Application Id, mark whichever is oldest as successful
            if (applicationToQueue.containsKey(event.applicationId)) {
                Queue_Job__c duplicateJob = applicationToQueue.get(event.applicationId);

                if (queueJob.Event_Time__c <= duplicateJob.Event_Time__c) {
                    successfulJobs.add(queueJob);
                    continue;
                }

                successfulJobs.add(duplicateJob);
            }

            applicationToQueue.put(event.applicationId, queueJob);
            applicationToSchema.put(event.applicationId, event);
        }
    }
}
