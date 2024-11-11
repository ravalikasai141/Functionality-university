public without sharing class ApplicationCancelled implements Serializer {
    /**
     * The set of Opportunity ids that form part of this event
     */
    private Set<Id> opportunityIds;

    /**
     * List of opportunities related to the opportunity ids
     */
    private List<Opportunity> opportunities;

    public ApplicationCancelled() {
        opportunityIds = new Set<Id>();
        opportunities = new List<Opportunity>();
    }

    /**
     * Adds the given Opportunity to the id list
     * @param record SObject to add to the record
     */
    public void addRecord(SObject record) {
        switch on record.getSObjectType().getDescribe().getName() {
            when 'Opportunity' {
                opportunityIds.add(record.Id);
            }
        }
    }

    /**
     * Creates a list of event payloads
     * @return  Payloads to send to an Emitter
     */
    public List<Map<String, Object>> serialize() {
        List<Map<String, Object>> payloads = new List<Map<String, Object>>();

        // Fetch opportunities
        fetchOpportunities();

        DateTime now = DateTime.now();

        for (Opportunity opp : opportunities) {
            Map<String, Object> payload = new Map<String, Object>{
                'applicationId' => opp.Application_Id__c,
                'cancellationReason' => opp.BPP_Cancellation_Reason__c,
                'cancelledBy' => opp.LastModifiedBy.Name,
                'cancelledOn' => now,
                'changedProductId' => null,
                'changedAwardingBody' => opp.Changed_Professional_Qualification__c
            };

            if (opp.Changed_Course_Instance__r?.Instance_ID__c != null) {
                payload.put('changedProductId', 'PCV2-' + opp.Changed_Course_Instance__r.Instance_ID__c);
            }

            payloads.add(payload);
        }

        return payloads;
    }

    /**
     * Fetches opportunities from the given ids where the Stage, Sub Status and Cancellation Reason require an event submitting
     */
    private void fetchOpportunities() {
        opportunities = [
            SELECT
                Application_Id__c,
                BPP_Cancellation_Reason__c,
                LastModifiedBy.Name,
                Changed_Course_Instance__r.Instance_ID__c,
                Changed_Professional_Qualification__c
            FROM Opportunity
            WHERE
                Application_Id__c != NULL
                AND Id IN :opportunityIds
                AND StageName = 'Closed Lost'
                AND ((BPP_Sub_Status__c = 'Cancelled'
                AND BPP_Cancellation_Reason__c IN (
                    'appMissedDeadline',
                    'appWithdrawApplicant',
                    'appNoResponseApplicant',
                    'appNoResponseEmployer',
                    'appCloneCancelChangedEmployer',
                    'appCloneCancelChangedProgramme',
                    'appInvalid'
                ))
                OR (BPP_Sub_Status__c = 'Rejected'
                AND BPP_Cancellation_Reason__c IN (
                    'appRejectIneligibleResidency',
                    'appRejectIneligibleVisa',
                    'appRejectRoleOnboarding',
                    'appRejectRoleHop',
                    'appRejectOverqualified',
                    'appRejectFundingIssue'
                ))
                OR BPP_Sub_Status__c = 'Withdrawn')
        ];
    }
}
