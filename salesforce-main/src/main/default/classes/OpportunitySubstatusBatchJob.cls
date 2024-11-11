public class OpportunitySubstatusBatchJob implements Schedulable, Database.Batchable<SObject> {
    private List<Opportunity> opportunitiesList = new List<Opportunity>();
    @testVisible private static Messaging.SingleEmailMessage failedUpdateEmail;
    @testVisible public Map<String, Integer> ageThresholds = new Map<String, Integer>();

    /**
     * Constructor to query out any relevant Opportunities to be processed
     */
    public OpportunitySubstatusBatchJob() {
        populateAgeThresholds();
    }

    private void populateAgeThresholds() {
        // Fetch records from Custom Metadata
        List<Opportunity_Age_Threshold__mdt> metadataRecords = Opportunity_Age_Threshold__mdt.getAll().values();
        for (Opportunity_Age_Threshold__mdt record : metadataRecords) {
            ageThresholds.put(record.MasterLabel, Integer.valueOf(record.Age_Threshold__c));
        }
    }

    //Execute of schedulable interface
    public void execute(SchedulableContext SC) 
    {
        Database.executeBatch(this, 50);
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        DateTime dateToCalcForFirstStage = DateTime.now().addDays(-ageThresholds.get('Recent Activity'));
        DateTime dateToCalcForSecondStage = DateTime.now().addDays(-ageThresholds.get('Going Stale'));

        return Database.getQueryLocator(
            [
                SELECT Id, BPP_Sub_Status__c, LastModifiedDate, GoingStaleDate__c
                FROM Opportunity
                WHERE
                    RecordType.DeveloperName = 'Student_Interest'
                    AND StageName IN ('Application Started', 'Application in Progress')
                    AND BPP_Sub_Status__c IN ('Recent Activity', 'Going Stale')
                    AND (LastModifiedDate < :dateToCalcForFirstStage OR LastModifiedDate < :dateToCalcForSecondStage)
            ]
        );
    }

    public void execute(Database.BatchableContext bc, List<Opportunity> opportunities) {
        for (Opportunity currentOpportunity : opportunities) {
            processOpportunity(currentOpportunity);
        }

        try {
            Database.upsert(opportunitiesList, false);
        } catch (Exception ex) {
            buildAndSendUnhandledError(ex.getMessage());
        }
    }

    private void processOpportunity(Opportunity currentOpportunity) {
        if (isEligibleForStage(currentOpportunity, 'Recent Activity')) {
            currentOpportunity.BPP_Sub_Status__c = 'Going Stale';
            currentOpportunity.GoingStaleDate__c = Datetime.now();
        } else if (isEligibleForStage(currentOpportunity, 'Going Stale')) {
            currentOpportunity.BPP_Sub_Status__c = 'Stale';
        } else {
            return;
        }
        opportunitiesList.add(currentOpportunity);
    }

    private boolean isEligibleForStage(Opportunity currentOpportunity, String subStatus) {
        Integer daysThreshold = ageThresholds.get(subStatus);
        if (daysThreshold == null) {
            // Handle case where metadata record is not found
            return false;
        }
        Datetime thresholdDate = DateTime.now().addDays(-daysThreshold);
        Datetime goingStaleDate = currentOpportunity.GoingStaleDate__c;
        return currentOpportunity.BPP_Sub_Status__c == subStatus && currentOpportunity.LastModifiedDate < thresholdDate && (goingStaleDate == null || goingStaleDate < thresholdDate);
    }

    public void finish(Database.BatchableContext bc) {
    }

    @testVisible
    private void buildAndSendUnhandledError(String exceptionMessage) {
        String body =
            'Opportunities have failed to update: ' +
            exceptionMessage +
            ' | Opportunities: ' +
            JSON.serialize(opportunitiesList);
        failedUpdateEmail = EmailUtilities.submitSystemAlertEmail('Opportunities Update has failed', body);
    }
}