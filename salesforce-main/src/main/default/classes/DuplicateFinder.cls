/**
 * A utility class for finding duplicate records.
 */
public with sharing class DuplicateFinder {
    public static DuplicateDetails duplicateDetails;
    public static Map<String, Matching_Rule_Category_Map__mdt> matchingRuleCategories = Matching_Rule_Category_Map__mdt.getAll();

    /**
     * Finds duplicate records in a List of SObjects and returns a List of matching records.
     *
     * @param sObjectList The List of SObjects to check for duplicates.
     * @return List of matching records found in the duplicate check.
     */
    public static List<DuplicateHandler.MatchingRecord> findDuplicateRecords(List<SObject> sObjectList) {
        return processDuplicates(sObjectList, Datacloud.FindDuplicates.findDuplicates(sObjectList));
    }

    /**
     * process matches
     * @param  duplicateResults duplicate results
     * @return List of matching records found in the duplicate check.
     */
    public static List<DuplicateHandler.MatchingRecord> processDuplicates(
        List<SObject> sObjectList,
        List<Datacloud.FindDuplicatesResult> duplicateResults
    ) {
        duplicateDetails = new DuplicateDetails();
        duplicateDetails.matchingRuleRecordsMap = new Map<String, Set<Id>>();
        duplicateDetails.sObjectType = determineSobjectType(sObjectList);

        for (Datacloud.FindDuplicatesResult duplicateResult : duplicateResults) {
            queryGetMatchResults(duplicateResult.duplicateresults);
        }

        duplicateDetails.matchingRuleCategoryMap = populateMatchingRuleCategoryMap(
            duplicateDetails.matchingRuleRecordsMap.keySet()
        );

        List<DuplicateHandler.MatchingRecord> matchingRecordList = DuplicateHandler.populateMatchingRecordList(
            duplicateDetails,
            duplicateDetails.matchingRuleCategoryMap
        );
        return matchingRecordList;
    }

    /**
     * Determines the SObject type based on the provided list of SObjects.
     *
     * @param sObjectList A list of SObjects from which to determine the SObject type.
     * @return The determined SObject type based on the provided list.
     */
    private static String determineSobjectType(List<SObject> sObjectList) {
        String sobjectType = String.valueOf(sObjectList.get(0).getSobjectType());

        if (sobjectType == 'Account') {
            String recordTypeId = (String) sObjectList.get(0).get('RecordTypeId');
            String accountType = DuplicateHelper.getRecordTypeName(sobjectType, recordTypeId);
            return (accountType == 'Student Account' ? 'Student' : 'Account');
        }
        return sobjectType;
    }

    /**
     * Processes a List of DuplicateResults to extract MatchResults.
     *
     * @param duplicateResultList List of duplicate results to process.
     */
    private static void queryGetMatchResults(List<Datacloud.DuplicateResult> duplicateResultList) {
        for (Datacloud.DuplicateResult dr : duplicateResultList) {
            if (dr.getMatchResults().size() > 0) {
                queryMatchResultList(dr.getMatchResults());
            }
        }
    }

    /**
     * Processes a List of MatchResults. Continues onto adding details to DuplicateDetails object if MatchResults exist.
     *
     * @param matchResultList List of match results to process.
     */
    private static void queryMatchResultList(List<Datacloud.MatchResult> matchResultList) {
        for (Datacloud.MatchResult mr : matchResultList) {
            if (mr.getSize() > 0) {
                addMatchingRecords(mr.getMatchRecords(), mr.getRule().left(40));
            }
        }
    }

    /**
     * Adds MatchRecord to the DuplicateDetails object based on a List of MatchRecords taken from the MatchResults.
     *
     * @param matchRecordList List of match records.
     * @param matchingRule    Matching rule associated with the match records.
     */
    private static void addMatchingRecords(List<Datacloud.MatchRecord> matchRecordList, String matchingRule) {
        Set<Id> recordIds = new Set<Id>();
        for (Datacloud.MatchRecord thisMatchRecord : matchRecordList) {
            recordIds.add(thisMatchRecord.getRecord().Id);
        }
        for (Id recordId : recordIds) {
            Set<Id> recordsForMap = duplicateDetails.matchingRuleRecordsMap.get(matchingRule);
            if (recordsForMap == null) {
                recordsForMap = new Set<Id>();
                duplicateDetails.matchingRuleRecordsMap.put(matchingRule, recordsForMap);
            }
            recordsForMap.add(recordId);
        }
    }

    /**
     * Populates a Map of Matching Rule Category Map records (Custom Metadata Type) to their corresponding category and index.
     *
     * @param matchingRulesSet Set of matching rule labels to retrieve mapping for.
     * @return Map of matching rule labels to category and index.
     */
    private static Map<String, String> populateMatchingRuleCategoryMap(Set<String> matchingRulesSet) {
        List<Matching_Rule_Category_Map__mdt> matchingRuleCategoryList = new List<Matching_Rule_Category_Map__mdt>();
        for (String matchingRule : matchingRulesSet) {
            if (
                matchingRuleCategories.containsKey(matchingRule) && matchingRuleCategories.get(matchingRule).Active__c
            ) {
                matchingRuleCategoryList.add(matchingRuleCategories.get(matchingRule));
            }
        }

        Map<String, String> matchingRuleCategoryMap = new Map<String, String>();
        for (Matching_Rule_Category_Map__mdt mrcm : matchingRuleCategoryList) {
            String categoryWithIndex = mrcm.Category__c + ':' + mrcm.Index__c;
            matchingRuleCategoryMap.put(mrcm.MasterLabel, categoryWithIndex);
        }
        return matchingRuleCategoryMap;
    }

    /**
     * Details about the duplicate records and matching rules.
     */
    public class DuplicateDetails {
        public String sObjectType;
        public Map<String, Set<Id>> matchingRuleRecordsMap;
        public Map<String, String> matchingRuleCategoryMap;
    }
}
