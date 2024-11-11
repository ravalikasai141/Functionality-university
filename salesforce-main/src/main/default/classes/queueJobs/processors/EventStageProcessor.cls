/**
 * Processor for the Application Stage change events
 */
public class EventStageProcessor extends BaseProcessor {
    private Map<String, Queue_Job__c> applicationToQueue = new Map<String, Queue_Job__c>();
    private Map<String, ApplicationStageSchema> applicationToSchema = new Map<String, ApplicationStageSchema>();
    private Map<String, Opportunity> oppsToUpdate = new Map<String, Opportunity>();
    private Map<String, Id> opportunityRecordTypeIds = new Map<String, Id>{
        'Student_Interest' => Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName()
            .get('Student_Interest')
            .getRecordTypeId(),
        'Student_Application' => Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName()
            .get('Student_Application')
            .getRecordTypeId()
    };

    /**
     * Processes the queue jobs and updates relevent applications
     * @param queueJobs List of queue jobs to process
     */
    public void processImpl(List<Queue_Job__c> queueJobs) {
        // deserialize event
        deserializeEvents(queueJobs);

        for (Opportunity opp : [
            SELECT Id, Application_ID__c, StageName, BPP_Sub_Status__c, RecordTypeId
            FROM Opportunity
            WHERE Application_Id__c IN :applicationToSchema.keySet()
        ]) {
            ApplicationStageSchema schema = applicationToSchema.remove(opp.Application_Id__c);

            DateTime eventTime = applicationToQueue.get(opp.Application_Id__c).Event_Time__c;

            switch on schema.currentStage {
                when 'BPP_REVIEW' {
                    processBPPReview(opp, eventTime, schema);
                }
                when 'LINE_MANAGER_REVIEW' {
                    if (opp.StageName == 'Line Manager Review') {
                        opp.BPP_Sub_Status__c = 'Awaiting Applicant Signoff';
                        oppsToUpdate.put(opp.Application_Id__c, opp);
                    } else {
                        addStatusFailure(applicationToQueue.get(opp.Application_Id__c), opp);
                    }
                }
                when 'ACCEPTANCE' {
                    if (opp.StageName == 'Line Manager Review') {
                        opp.StageName = 'Acceptance';
                        opp.BPP_Sub_Status__c = 'New';

                        oppsToUpdate.put(opp.Application_Id__c, opp);
                    } else {
                        addStatusFailure(applicationToQueue.get(opp.Application_Id__c), opp);
                    }
                }
            }
        }

        // Any jobs remaining in the applicationToSchema map are missing in Salesforce and should be failed
        for (String missingApplicationId : applicationToSchema.keySet()) {
            failedJobs.put(
                applicationToQueue.get(missingApplicationId),
                'The given Application Id does not exist in Salesforce.'
            );
        }

        processDML(oppsToUpdate);
    }

    /**
     * Processes the queue jobs and updates relevent applications of review status
     * @param opp Opportunity
     */
    private void processBPPReview(Opportunity opp, DateTime eventTime, ApplicationStageSchema schema) {
        if (opp.StageName == 'Application') {
            opp.StageName = 'BPP Review';
            opp.BPP_Sub_Status__c = 'Not Started';
            opp.Application_Date__c = eventTime?.date();

            oppsToUpdate.put(opp.Application_Id__c, opp);
        } else if (opp.StageName == 'BPP Review' && opp.BPP_Sub_Status__c == 'Awaiting Information') {
            opp.BPP_Sub_Status__c = 'Not Started';
            opp.Resubmission_Date__c = eventTime;

            oppsToUpdate.put(opp.Application_Id__c, opp);
        } else if (
            opp.RecordTypeId == opportunityRecordTypeIds.get('Student_Interest') &&
            schema.currentStageStatus == 'IN_PROGRESS'
        ) {
            opp.StageName = 'Application';
            opp.RecordTypeId = opportunityRecordTypeIds.get('Student_Application');
            opp.Application_Date__c = eventTime?.date();

            oppsToUpdate.put(opp.Application_Id__c, opp);
        } else {
            addStatusFailure(applicationToQueue.get(opp.Application_Id__c), opp);
        }
    }

    /**
     * Processes the DML and updates given opportunities
     * @param opportunities Map of application id => opportunities
     */
    private void processDML(Map<String, Opportunity> opportunities) {
        // update any opps
        List<Database.SaveResult> oppResults = Database.Update(opportunities.values(), false);

        for (Integer i = 0; i < oppResults.size(); i++) {
            Database.SaveResult result = oppResults[i];

            if (!result.isSuccess()) {
                String applicationId = (new List<String>(opportunities.keySet()))[i];
                processDMLErrors(applicationToQueue.get(applicationId), result.getErrors());
                opportunities.remove(applicationId);
            }
        }

        // Mark jobs as successful
        for (String applicationId : opportunities.keySet()) {
            successfulJobs.add(applicationToQueue.get(applicationId));
        }
    }

    /**
     * deserializes job content and adds to lists to be processed
     * @param  queueJobs Queue Jobs being processed
     */
    public void deserializeEvents(List<Queue_Job__c> queueJobs) {
        for (Queue_Job__c queueJob : queueJobs) {
            ApplicationStageSchema event = (ApplicationStageSchema) JSON.deserialize(
                queueJob.Job_Content__c,
                ApplicationStageSchema.class
            );

            Map<String, String> requiredFieldMap = new Map<String, String>{
                'Application Id' => event?.applicationId,
                'Stage' => event?.currentStage
            };

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

            applicationToQueue.put(event.applicationId, queueJob);
            applicationToSchema.put(event.applicationId, event);
        }
    }

    /**
     * Fails an opportunity based on incorrect status/sub status values
     * @param jobId The queue job id
     * @param opp The opportunity that failed
     */
    private void addStatusFailure(Queue_Job__c job, Opportunity opp) {
        failedJobs.put(
            job,
            'Current application stage (' +
                opp.StageName +
                ' - ' +
                opp.BPP_Sub_Status__c +
                ') is not valid for this event.'
        );
    }
}
