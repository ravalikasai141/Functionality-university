/**
 * Controller class for the Product Opportunity Update LWC
 */
public with sharing class ProductOpportunityUpdateController {
    private static final Id APPRENTICE_APPLICATION_RT_ID = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName()
        .get('Apprentice_Application')
        .getRecordTypeId();

    /**
     * Queries out and returns the amount of records which are linked to the given Product and do not have a matching Start and/or End Date
     *
     * @param productId The Product that each of the Opportunities must be linked to
     * @param startDate The start date on the Product to be used to exclude Opportunities from the query
     * @param endDate The End date on the Product to be used to exclude Opportunities from the query
     *
     * @return The amount of Opportunities that were identified
     */
    @AuraEnabled
    public static Integer countOpportunitiesWithMismatchedDates(String productId, Date startDate, Date endDate) {
        return [
            SELECT COUNT()
            FROM Opportunity
            WHERE
                Course_Instance__c = :productId
                AND RecordTypeId = :APPRENTICE_APPLICATION_RT_ID
                AND StageName = 'Application'
                AND (Start_Date__c != :startDate
                OR End_Date__c != :endDate)
        ];
    }

    /**
     * Queries out and returns Opportunity records which are linked to the given Product and do not have a matching Start and/or End Date
     *
     * @param productId The Product that each of the Opportunities must be linked to
     * @param startDate The start date on the Product to be used to exclude Opportunities from the query
     * @param endDate The End date on the Product to be used to exclude Opportunities from the query
     * @param queryCount The amount of records to include in the query
     *
     * @return The Opportunities that were identified
     */
    @AuraEnabled
    public static ProductOpportunityUpdateSaveResults updateOpportunitiesWithMismatchedDates(
        String productId,
        Date startDate,
        Date endDate,
        Integer queryCount
    ) {
        List<Opportunity> oppsToUpdate = [
            SELECT Id, OOTJTH_Calculated__c
            FROM Opportunity
            WHERE
                Course_Instance__c = :productId
                AND RecordTypeId = :APPRENTICE_APPLICATION_RT_ID
                AND StageName = 'Application'
                AND (Start_Date__c != :startDate
                OR End_Date__c != :endDate)
            ORDER BY CreatedDate
            LIMIT :queryCount
        ];

        for (Opportunity currentOpp : oppsToUpdate) {
            currentOpp.Start_Date__c = startDate;
            currentOpp.End_Date__c = endDate;
            currentOpp.OOTJTH_Preserved__c = currentOpp.OOTJTH_Calculated__c;
        }

        ProductOpportunityUpdateSaveResults results = new ProductOpportunityUpdateSaveResults();
        for (Database.SaveResult currentResult : Database.Update(oppsToUpdate, false)) {
            if (currentResult.isSuccess()) {
                results.successCount++;
                continue;
            }

            results.failCount++;
        }

        return results;
    }

    public class ProductOpportunityUpdateSaveResults {
        @auraEnabled
        public Integer failCount = 0;

        @auraEnabled
        public Integer successCount = 0;
    }
}
