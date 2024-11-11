public class EventDocumentUploadedProcessor extends BaseProcessor {
    private static final Map<String, String> STATUS_MAPPING = new Map<String, String>{
        'pendingUpload' => 'Pending',
        'uploaded' => 'Pending',
        'pendingScan' => 'Pending',
        'completed' => 'Uploaded',
        'failed' => 'Failed',
        'documentDeleted' => 'Deleted'
    };

    /**
     * deserialize event payload and upsert records
     * @param  queueJobs queueJobs to process
     */
    public void processImpl(List<Queue_Job__c> queueJobs) {
        Map<String, JobDetails> documentIdToDetails = new Map<String, JobDetails>();
        List<String> userIds = new List<String>();

        for (Queue_Job__c queueJob : queueJobs) {
            DocumentSchema event = (DocumentSchema) JSON.deserialize(queueJob.Job_Content__c, DocumentSchema.class);

            if (event.documentId == null) {
                failedJobs.put(queueJob, 'Required value(s) Document ID are null in event payload');
                continue;
            }

            String calculatedStatus = queueJob.Job_Type__c == 'documentDeleted' ? queueJob.Job_Type__c : event.status;

            if (!STATUS_MAPPING.containsKey(calculatedStatus)) {
                failedJobs.put(queueJob, 'Invalid status provided.');
                continue;
            }

            userIds.add(event.authUserId);

            // de-dupe
            if (documentIdToDetails.containsKey(event.documentId)) {
                JobDetails jobDetails = documentIdToDetails.get(event.documentId);
                successfulJobs.add(jobDetails.queueJob);
            }

            documentIdToDetails.put(event.documentId, new JobDetails(queueJob, event, calculatedStatus));
        }

        Map<String, Id> authIdToHubAccount = new Map<String, Id>();
        for (Hub_Account__c hubAccount : [
            SELECT Id, Auth0_Id__c, Student__c
            FROM Hub_Account__c
            WHERE Auth0_Id__c IN :userIds
        ]) {
            authIdToHubAccount.put(hubAccount.Auth0_Id__c, hubAccount.Student__c);
        }

        Map<String, External_Document__c> documentsToUpdate = new Map<String, External_Document__c>();
        for (JobDetails jobDetail : documentIdToDetails.values()) {
            External_Document__c docToUpdate = new External_Document__c(
                Name = jobDetail.event.documentName,
                Status__c = jobDetail.status,
                Content_Type__c = jobDetail.event.contentType,
                Document_ID__c = jobDetail.event.documentId,
                Version__c = jobDetail.event.version,
                User_ID__c = jobDetail.event.authUserId
            );

            if (authIdToHubAccount.containsKey(jobDetail.event.authUserId)) {
                docToUpdate.Student__c = authIdToHubAccount.get(jobDetail.event.authUserId);
            }

            if (!Killswitch.isEnabled(Killswitch.JOIN2_DOC_KILLSWITCH)) {
                docToUpdate.Type__c = jobDetail.event.documentType;
                docToUpdate.Category__c = jobDetail.event.documentCategory;
            }

            documentsToUpdate.put(jobDetail.event.documentId, docToUpdate);
        }

        List<Database.UpsertResult> upsertResult = Database.Upsert(
            documentsToUpdate.values(),
            External_Document__c.Document_ID__c.getDescribe().getSObjectField(),
            false
        );

        for (Integer i = 0; i < upsertResult.size(); i++) {
            Database.UpsertResult result = upsertResult[i];

            String documentId = documentsToUpdate.values()[i].Document_ID__c;
            Queue_Job__c queueJob = documentIdToDetails.get(documentId).queueJob;

            if (!result.isSuccess()) {
                processDMLErrors(queueJob, result.getErrors());
                continue;
            }

            successfulJobs.add(queueJob);
        }
    }

    private class JobDetails {
        public Queue_Job__c queueJob;
        public DocumentSchema event;
        public String status;

        public JobDetails(Queue_Job__c queueJob, DocumentSchema event, String status) {
            this.queueJob = queueJob;
            this.event = event;
            this.status = STATUS_MAPPING.get(status);
        }
    }
}
