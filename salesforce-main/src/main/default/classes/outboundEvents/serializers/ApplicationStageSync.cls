public without sharing class ApplicationStageSync implements Serializer {
    /**
     * The set of Opportunity ids that form part of this event
     */
    private Set<Id> opportunityIds;

    /**
     * List of opportunities related to the opportunity ids
     */
    private List<Opportunity> opportunities;

    public ApplicationStageSync() {
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

        for (Opportunity opp : opportunities) {
            Map<String, Object> payload = new Map<String, Object>{
                'applicationId' => opp.Application_Id__c,
                'currentStage' => opp.StageName.toUpperCase().replace(' ', '_'),
                'currentStageStatus' => opp.BPP_Sub_Status__c.toUpperCase().replace(' ', '_')
            };

            if (opp.StageName == 'Line Manager Review') {
                payload.put(
                    'lineManager',
                    new Map<String, Object>{
                        'firstName' => opp.Line_Manager__r.FirstName,
                        'lastName' => opp.Line_Manager__r.LastName,
                        'email' => opp.Line_Manager__r.Email
                    }
                );
            }

            if (opp.StageName == 'Acceptance') {
                payload.put(
                    'data',
                    new Map<String, Object>{
                        'bppAuthorizerFirstName' => opp.Authoriser__r?.FirstName,
                        'bppAuthorizerLastName' => opp.Authoriser__r?.LastName,
                        'bppAuthorizedOn' => opp.AuthorisedOn__c
                    }
                );
            }

            payloads.add(payload);
        }

        return payloads;
    }

    /**
     * Fetches opportunities from the given ids where the stage is
     * in Line Manager Review
     */
    private void fetchOpportunities() {
        opportunities = [
            SELECT
                Application_Id__c,
                BPP_Sub_Status__c,
                StageName,
                Line_Manager__r.Email,
                Line_Manager__r.FirstName,
                Line_Manager__r.LastName,
                Authoriser__r.FirstName,
                Authoriser__r.LastName,
                AuthorisedOn__c
            FROM Opportunity
            WHERE
                Id IN :opportunityIds
                AND ((StageName = 'Line Manager Review'
                AND BPP_Sub_Status__c = 'In Progress')
                OR (StageName = 'Acceptance'
                AND BPP_Sub_Status__c = 'Completed')
                OR (StageName = 'Unconditional Offer'))
        ];
    }
}
