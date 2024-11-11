/**
 * A variation of the ApplicationStageSync, this class creates payloads
 * for the applicationStageChanged event specifically for recalled
 * applications. This event is not used in the StreamingService and is
 * manually invoked during the recall process.
 */
public without sharing class ApplicationRecall implements Serializer {
    /**
     * A list of opportunities that have been recalled
     */
    private List<Opportunity> opportunities;

    /**
     * Default construct
     */
    public ApplicationRecall() {
        opportunities = new List<Opportunity>();
    }

    /**
     * Creates the opportunities list with the given records
     * @param record SObject record
     */
    public void addRecord(SObject record) {
        switch on record.getSObjectType().getDescribe().getName() {
            when 'Opportunity' {
                opportunities.add((Opportunity) record);
            }
        }
    }

    /**
     * Creates and returns a list of payloads for the
     * applicationStageChanged events based on the list
     * of Opportunities given
     * @return  Payload for the applicationStageChanged event
     */
    public List<Map<String, Object>> serialize() {
        List<Map<String, Object>> payloads = new List<Map<String, Object>>();

        for (Opportunity opp : opportunities) {
            Map<String, Object> payload = new Map<String, Object>{
                'applicationId' => opp.Application_Id__c,
                'recall' => true,
                'currentStage' => opp.StageName.toUpperCase().replace(' ', '_'),
                'currentStageStatus' => opp.BPP_Sub_Status__c.toUpperCase().replace(' ', '_')
            };

            payloads.add(payload);
        }

        return payloads;
    }
}
