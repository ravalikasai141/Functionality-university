/**
 * Handles duplicate records, performing operations on matched records.
 */
public with sharing class DuplicateHandler {
    /**
     * Populates a List of MatchingRecord instances based on DuplicateDetails and Matching Rule Category Mapping.
     *
     * @param duplicateDetails      The details of duplicate records.
     * @param matchingRuleCategoryMap  Mapping of matching rules to their corresponding categories.
     * @return List of MatchingRecord instances.
     */
    public static List<MatchingRecord> populateMatchingRecordList(
        DuplicateFinder.DuplicateDetails duplicateDetails,
        Map<String, String> matchingRuleCategoryMap
    ) {
        List<MatchingRecord> matchingRecordList = new List<MatchingRecord>();

        // Iterate through matching rules and populate MatchingRecord instances
        for (String matchingRule : duplicateDetails.matchingRuleRecordsMap.keyset()) {
            String category = matchingRuleCategoryMap.get(matchingRule).substringBefore(':');
            String index = matchingRuleCategoryMap.get(matchingRule).substringAfter(':');

            // Iterate through matching Ids for each matching rule
            for (Id matchingId : duplicateDetails.matchingRuleRecordsMap.get(matchingRule)) {
                MatchingRecord mr = new MatchingRecord();
                mr.category = category;
                mr.index = index;
                mr.matchingId = matchingId;
                mr.matchingRule = matchingRule;
                mr.sObjectType = duplicateDetails.sObjectType;
                matchingRecordList.add(mr);
            }
        }
        return matchingRecordList;
    }

    /**
     * Handles matching records, escalating categories if needed, and performs upgrades to Map if Matching Rule combination increases category.
     *
     * @param matchingRecords           List of matching records.
     * @return Id of winning record.
     */
    public static String handleMatchingRecords(List<MatchingRecord> matchingRecords) {
        String objectType = matchingRecords.get(0).sObjectType;

        Map<String, MatchingRecordGroup> categoryToRecordGroupMap = populateCategoryToRecordGroupMap(
            matchingRecords,
            objectType
        );

        Map<String, Boolean> matchingRuleCombinationMap = populateMatchingRuleCombinationMap(objectType);
        populateEscalateCategory(categoryToRecordGroupMap, matchingRuleCombinationMap);
        handleCategoryUpgrade(categoryToRecordGroupMap);

        String winningId;
        MatchingRecordGroup matchingRecordGroup = getRecordGroupByPriority(categoryToRecordGroupMap);
        if (matchingRecordGroup != null) {
            if (matchingRecordGroup.matchingIds.size() == 1) {
                winningId = DuplicateHelper.stripSpecialCharsFromString(matchingRecordGroup.matchingIds.toString());
            } else {
                winningId = DuplicateHelper.determineWinningRecordId(objectType, matchingRecordGroup.matchingIds);
            }
        }
        return winningId;
    }

    /**
     * Populates a Map of categories to their corresponding MatchingRecordGroup instances.
     *
     * @param matchingRecords       List of matching records.
     * @param objectType            The object type for matching records.
     * @return Map of categories to MatchingRecordGroup instances.
     */
    private static Map<String, MatchingRecordGroup> populateCategoryToRecordGroupMap(
        List<MatchingRecord> matchingRecords,
        String objectType
    ) {
        Map<String, MatchingRecordGroup> categoryToRecordGroupMap = new Map<String, MatchingRecordGroup>();
        for (MatchingRecord mr : matchingRecords) {
            if (!categoryToRecordGroupMap.containsKey(mr.category)) {
                categoryToRecordGroupMap.put(mr.category, new MatchingRecordGroup());
            }
            MatchingRecordGroup mrg = categoryToRecordGroupMap.get(mr.category);
            mrg.matchingIds.add(mr.matchingId);
            mrg.matchingRuleIndex.add(mr.index);
            mrg.sObjectType = objectType;
        }
        return categoryToRecordGroupMap;
    }

    /**
     * Populate Map of Matching Rule Combinations (Custom Metadata Type) and their escalation status
     *
     * @param objectType      The object type for matching rule combinations.
     * @return Map of matching rule combinations and their escalation status.
     */
    private static Map<String, Boolean> populateMatchingRuleCombinationMap(String objectType) {
        Map<String, Boolean> matchingRuleCombinationMap = new Map<String, Boolean>();
        Map<String, Matching_Rule_Combination__mdt> matchingRuleCombinations = Matching_Rule_Combination__mdt.getAll();
        for (String matchingRuleComboName : matchingRuleCombinations.keyset()) {
            Matching_Rule_Combination__mdt matchingRuleCombo = matchingRuleCombinations.get(matchingRuleComboName);
            if (matchingRuleCombo.Object__c == objectType) {
                matchingRuleCombinationMap.put(matchingRuleCombo.MasterLabel, matchingRuleCombo.Escalate_Category__c);
            }
        }
        return matchingRuleCombinationMap;
    }

    /**
     * Populates the escalate category field in the MatchingRecordGroup based on Matching Rule Combinations.
     *
     * @param categoryToRecordGroupMap         Map of categories to MatchingRecordGroup instances.
     * @param matchingRuleCombinationMap       Map of matching rule combinations and their escalation status.
     */
    private static void populateEscalateCategory(
        Map<String, MatchingRecordGroup> categoryToRecordGroupMap,
        Map<String, Boolean> matchingRuleCombinationMap
    ) {
        for (String category : categoryToRecordGroupMap.keyset()) {
            if (category != 'Gold') {
                MatchingRecordGroup mrg = categoryToRecordGroupMap.get(category);
                Set<String> matchingRuleIndex = mrg.matchingRuleIndex;

                // Determine escalateCategory based on matching rule combinations
                if (matchingRuleIndex.size() == 1) {
                    String combo = DuplicateHelper.stripSpecialCharsFromString(matchingRuleIndex.toString()) + ' NOT ';
                    mrg.escalateCategory = determineEscalationStatus(combo, matchingRuleCombinationMap);
                } else {
                    mrg.escalateCategory = determineEscalationStatus(
                        String.join(new List<String>(matchingRuleIndex), ' AND '),
                        matchingRuleCombinationMap
                    );
                }
            }
        }
    }

    /**
     * Handles category upgrades based on the escalate category status.
     *
     * @param categoryToRecordGroupMap      Map of categories to MatchingRecordGroup instances.
     */
    private static void handleCategoryUpgrade(Map<String, MatchingRecordGroup> categoryToRecordGroupMap) {
        Map<String, String> categoriesToUpgradeMap = new Map<String, String>();

        // Identify categories to upgrade, only required if escalateCategory boolean is true
        for (String category : categoryToRecordGroupMap.keySet()) {
            MatchingRecordGroup mrg = categoryToRecordGroupMap.get(category);
            if (mrg.escalateCategory) {
                String upgradedCategory = getUpgradedCategory(category);
                categoriesToUpgradeMap.put(category, upgradedCategory);
            }
        }

        // Perform category upgrades
        if (!categoriesToUpgradeMap.isEmpty()) {
            updatecategoryToRecordGroupMap(categoriesToUpgradeMap, categoryToRecordGroupMap);
        }
    }

    /**
     * Updates the categoryToRecordGroupMap with upgraded categories.
     *
     * @param categoriesToUpgradeMap        Map of original categories to upgraded categories.
     * @param categoryToRecordGroupMap      Map of categories to MatchingRecordGroup instances.
     */
    private static void updatecategoryToRecordGroupMap(
        Map<String, String> categoriesToUpgradeMap,
        Map<String, MatchingRecordGroup> categoryToRecordGroupMap
    ) {
        for (String originalCategory : categoriesToUpgradeMap.keySet()) {
            String upgradedCategory = categoriesToUpgradeMap.get(originalCategory);

            if (!categoryToRecordGroupMap.containsKey(upgradedCategory)) {
                categoryToRecordGroupMap.put(upgradedCategory, new MatchingRecordGroup());
            }

            MatchingRecordGroup upgradedMrg = categoryToRecordGroupMap.get(upgradedCategory);
            MatchingRecordGroup originalMrg = categoryToRecordGroupMap.get(originalCategory);

            // Merge matchingIds
            upgradedMrg.matchingIds.addAll(originalMrg.matchingIds);

            // Merge matchingRuleIndex
            Set<String> updatedMatchingRuleIndex = new Set<String>(upgradedMrg.matchingRuleIndex);
            updatedMatchingRuleIndex.addAll(originalMrg.matchingRuleIndex);
            upgradedMrg.matchingRuleIndex = updatedMatchingRuleIndex;

            // Remove original category from the Map
            categoryToRecordGroupMap.remove(originalCategory);
        }
    }

    /**
     * Gets the upgraded category based on the original category.
     *
     * @param category The original category to be upgraded.
     * @return The upgraded category, or the original category if no upgrade is needed.
     */
    private static String getUpgradedCategory(String category) {
        Map<String, String> categoryUpgrades = new Map<String, String>{ 'Silver' => 'Gold', 'Bronze' => 'Silver' };
        return categoryUpgrades.containsKey(category) ? categoryUpgrades.get(category) : category;
    }

    /**
     * Retrieves a MatchingRecordGroup from the given map based on priority.
     *
     * @param recordGroupMap A map containing MatchingRecordGroup instances keyed by category.
     * @return The MatchingRecordGroup for the highest-priority category found in the map,
     *         or null if none of the specified categories are present.
     */
    private static MatchingRecordGroup getRecordGroupByPriority(Map<String, MatchingRecordGroup> recordGroupMap) {
        if (recordGroupMap.containsKey('Gold')) {
            return recordGroupMap.get('Gold');
        } else if (recordGroupMap.containsKey('Silver')) {
            return recordGroupMap.get('Silver');
        } else if (recordGroupMap.containsKey('Bronze')) {
            return recordGroupMap.get('Bronze');
        } else {
            return null;
        }
    }

    /**
     * Finds and retrieves the escalation status for a given combination in the matching rule combination map.
     *
     * @param combo The combination to find in the matching rule combination map.
     * @param matchingRuleCombinationMap The map containing matching rule combinations and their escalation status.
     * @return Escalation status associated with the provided combination, or false if no match is found.
     */
    private static Boolean determineEscalationStatus(String combo, Map<String, Boolean> matchingRuleCombinationMap) {
        Boolean escalate = false;
        for (String comboName : matchingRuleCombinationMap.keyset()) {
            if (comboName.contains(combo)) {
                escalate = matchingRuleCombinationMap.get(comboName);
                break;
            }
        }
        return escalate;
    }

    /**
     * Represents a matching record.
     */
    public class MatchingRecord {
        public String index;
        public String category;
        public String sObjectType;
        public String matchingId;
        public String matchingRule;
    }

    /**
     * Represents a group of matching records with common attributes.
     */
    public class MatchingRecordGroup {
        String sObjectType;
        Boolean escalateCategory = false;
        Set<Id> matchingIds = new Set<Id>();
        Set<String> matchingRuleIndex = new Set<String>();
    }
}
