public with sharing class OpportunityHelper {
    private static final Integer DEFAULT_CREATION_MONTHS = -3;

    /**
     * Retrieves Opportunity owners based on a list of Account IDs
     * @param accountIdList A list of Account Ids
     * @return Map of Opportunity Account IDs and their corresponding Owner IDs
     */
    public static Map<String, Id> getOpportunityOwner(List<String> accountIdList) {
        DateTime createdDateToCheck = System.now().addMonths(DEFAULT_CREATION_MONTHS);
        
        // Map to store Opportunity owners
        Map<String, Id> opportunityOwnerMap = new Map<String, Id>();

        // Query to retrieve Opportunity owners
        for (Opportunity opp : [
            SELECT AccountId, OwnerId 
            FROM Opportunity 
            WHERE AccountId IN :accountIdList 
                AND RecordType.DeveloperName IN ('Student_Application', 'Student_Interest')
                AND StageName != 'Closed Lost'
                AND CreatedDate > :createdDateToCheck
            ORDER BY RecordType.DeveloperName ASC, CreatedDate DESC
        ]) {
            // Add Opportunity owner to the map if not already present
            if (!opportunityOwnerMap.containsKey(opp.AccountId)) {
                opportunityOwnerMap.put(opp.AccountId, opp.OwnerId);
            }
        }

        // Populate the map with default owner for missing Account IDs
        for (String accountId : accountIdList) {
            if (!opportunityOwnerMap.containsKey(accountId)) {
                opportunityOwnerMap.put(accountId, AssignmentUsers__c.getInstance().Default_Admissions_Owner__c);    
            }
        }
        
        return opportunityOwnerMap;
    }   
}
