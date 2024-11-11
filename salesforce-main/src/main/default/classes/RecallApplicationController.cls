/**
 * RecallApplicationController deals with recalling applications
 * from previous status' and sub status', the controller is used
 * along side the recallApplication LWC.
 */
public without sharing class RecallApplicationController {

    /**
     * Provides an opportunity with recall changes applied
     * @param opportunityId The opportunity id
     * @return  Opportunity with changes that would happen during the recall
     * @exception 
     */
    @AuraEnabled(cacheable=true)
    public static Opportunity getPreview(Id opportunityId) {
        try {
            Opportunity opp = convertOpp(opportunityId);

            return opp;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
     * Recalls the opportunity, updates Status and Sub Status and emits
     * an applicationStageChanged event
     * @param opportunityId The oppportunity Id
     */
    @AuraEnabled
    public static void recallOpportunity(Id opportunityId) {
        try {

            Opportunity opp = convertOpp(opportunityId);

            // Update the opportunity
            update opp;

            // Trigger event
            ApplicationRecall recall = new ApplicationRecall();
            recall.addRecord(opp);

            PlatformEventEmitter emitter = new PlatformEventEmitter();
            emitter.send('applicationStageChanged', recall.serialize());
            
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
     * Applies changes to status and sub status for recalled opportunities
     * @param opportunityId The opportunity id
     * @return  Opportunity with status and sub status changes applied
     */
    private static Opportunity convertOpp(Id opportunityId) {
        Opportunity opp = [SELECT Id, Application_Id__c, StageName, BPP_Sub_Status__c FROM Opportunity WHERE Id = :opportunityId];

        switch on opp.StageName {
            when 'BPP Review' {
                if (opp.BPP_Sub_Status__c == 'Awaiting Information') {
                    opp.BPP_Sub_Status__c = 'In Progress';
                }
            }
            when 'Line Manager Review' {
                opp.StageName = 'BPP Review';
                opp.BPP_Sub_Status__c = 'In Progress';
            }
            when 'Acceptance' {
                if (opp.BPP_Sub_Status__c == 'Completed') {
                    opp.BPP_Sub_Status__c = 'In Progress';
                }
            }
        }

        return opp;
    }
}
