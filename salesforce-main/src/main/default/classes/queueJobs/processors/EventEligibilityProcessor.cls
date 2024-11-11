/**
 * Processor for the Eligibility events
 */
public class EventEligibilityProcessor extends BaseProcessor {
    private Map<String, EligibilityJobDetails> applicationIdToDetails = new Map<String, EligibilityJobDetails>();

    /**
     * Update a related opp from event.
     * @param  queueJobs queueJobs description
     */
    public void processImpl(List<Queue_Job__c> queueJobs) {
        // deserialize event
        deserializeEvents(queueJobs);

        // find Account
        Map<String, Opportunity> applicationToOpp = new Map<String, Opportunity>();
        for (Opportunity opp : [
            SELECT Id, Application_Id__c
            FROM Opportunity
            WHERE Application_Id__c IN :applicationIdToDetails.keySet()
        ]) {
            // Update opp's addresses
            EligibilitySchema schema = applicationIdToDetails.get(opp.Application_Id__c).schema;

            opp.Eligibility_Status__c = schema.eligibility.isEligible;
            opp.Eligibility_JSON__c = JSON.serialize(schema);

            String eliStatus = schema.eligibility.isEligible != null ? schema.eligibility.isEligible : 'N/A';
            String eliSubmitted = schema.eligibility.submittedOn != null
                ? schema.eligibility.submittedOn.formatGMT('MM/dd/YYYY')
                : 'N/A';
            String eliTemplate = schema.eligibility.templateCode != null ? schema.eligibility.templateCode : 'N/A';

            opp.Eligibility_Text__c =
                'Eligibility Status: ' +
                eliStatus +
                ' | Date Submitted: ' +
                eliSubmitted +
                ' | Template: ' +
                eliTemplate +
                '\n';

            for (EligibilitySchema.Answer answer : schema.eligibility.answers) {
                opp.Eligibility_Text__c +=
                    '\n' +
                    answer.question +
                    (answer.eligible ? ' (Eligible)' : ' (Ineligible)') +
                    '\n' +
                    answer.summaryText +
                    '\n';
            }

            if (!String.isBlank(schema.eligibility.summaryText)) {
                opp.Eligibility_Text__c += '\nSummary\n';

                opp.Eligibility_Text__c += schema.eligibility.summaryText.replaceAll('<(?:/(?:p|li)|(?:p)/)>', '$0~~')
                    .stripHtmlTags()
                    .replaceAll('~~', '\n');
            }

            // If the Application has been marked as illegible, close it
            if (opp.Eligibility_Status__c == 'NOT_ELIGIBLE') {
                opp.StageName = 'Closed Lost';
                opp.BPP_Sub_Status__c = 'Not eligible';
                opp.BPP_Cancellation_Reason__c = 'appNotEligible';
            }

            applicationToOpp.put(opp.Application_Id__c, opp);
        }

        // fail for events we didn't find an opp for
        for (String applicationId : applicationIdToDetails.keySet()) {
            if (!applicationToOpp.containsKey(applicationId)) {
                failedJobs.put(
                    applicationIdToDetails.get(applicationId).queueJob,
                    'No Opp found with matching applicationId'
                );
            }
        }

        processDML(applicationToOpp);
    }

    /**
     * Preforms any DML inserts and updates for the provided records
     * @param  applicationToOpp  A map of Application Ids to Opportunities to update
     */
    private void processDML(Map<String, Opportunity> applicationToOpp) {
        // Update any opps
        List<Database.SaveResult> oppResults = Database.Update(applicationToOpp.values(), false);
        for (Integer i = 0; i < oppResults.size(); i++) {
            Database.SaveResult result = oppResults[i];

            String applicationId = (new List<String>(applicationToOpp.keySet()))[i];
            EligibilityJobDetails jobDetails = applicationIdToDetails.get(applicationId);

            if (result.isSuccess()) {
                successfulJobs.add(jobDetails.queueJob);
                continue;
            }

            processDMLErrors(jobDetails.queueJob, result.getErrors());
        }
    }

    /**
     * Deserializes job content and adds to lists to be processed
     * @param  queueJobs Queue Jobs being processed
     */
    public void deserializeEvents(List<Queue_Job__c> queueJobs) {
        for (Queue_Job__c queueJob : queueJobs) {
            EligibilitySchema event = (EligibilitySchema) JSON.deserialize(
                queueJob.Job_Content__c,
                EligibilitySchema.class
            );

            // If any required values aren't present, skip
            if (String.isBlank(event.applicationId)) {
                failedJobs.put(queueJob, 'Required value null in event payload');
                continue;
            }

            // If we have already mapped an event with a given Application Id, mark whichever is oldest as successful
            if (applicationIdToDetails.containsKey(event.applicationId)) {
                Queue_Job__c duplicateJob = applicationIdToDetails.get(event.applicationId).queueJob;

                if (queueJob.Event_Time__c <= duplicateJob.Event_Time__c) {
                    successfulJobs.add(queueJob);
                    continue;
                }

                successfulJobs.add(duplicateJob);
            }

            EligibilityJobDetails jobDetails = new EligibilityJobDetails();
            jobDetails.schema = event;
            jobDetails.queueJob = queueJob;

            applicationIdToDetails.put(event.applicationId, jobDetails);
        }
    }

    // Class to store details relating to the event
    private class EligibilityJobDetails {
        public EligibilitySchema schema;
        public Queue_Job__c queueJob;
    }
}
