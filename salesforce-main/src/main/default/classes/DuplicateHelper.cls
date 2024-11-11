/**
 * Helper class for managing duplicate records based on prevailing factors.
 */
public with sharing class DuplicateHelper {
    /**
     * Determines the winning record ID based on prevailing factors and matching record IDs.
     *
     * @param objectType     The object type for which prevailing factors are considered.
     * @param matchingIds    Set of matching record IDs.
     * @return Winning record ID or null if no winning record is found.
     */
    public static Id determineWinningRecordId(String objectType, Set<Id> matchingIds) {
        List<Prevailing_Factor__mdt> prevailingFactorList = getPrevailingFactors(objectType);
        List<String> pfFieldReferenceList = populatePrevailingFactorFieldList(prevailingFactorList);

        objectType = (objectType == 'Student' ? 'Account' : objectType);
        Map<Id, SObject> recordsMatchedMap = queryMatchingRecords(objectType, matchingIds, pfFieldReferenceList);

        Map<Id, SObject> fallbackMap = new Map<Id, SObject>();
        fallbackMap.putAll(recordsMatchedMap);

        List<PrevailingFactor> pfList = buildPrevailingFactorObjects(
            prevailingFactorList,
            matchingIds,
            recordsMatchedMap
        );
        Id winningId = determinePrevailingFactorMatch(pfList);

        return (winningId != null)
            ? winningId
            : retrieveWinningRecordId(recordsMatchedMap, prevailingFactorList.get(0).Field__c);
    }

    /**
     * Retrieves the list of active prevailing factors for a specific object type (sorted by Index__c value).
     *
     * @param objectType The object type for which prevailing factors are retrieved.
     * @return List of active prevailing factors that relate to trigger record type.
     */
    private static List<Prevailing_Factor__mdt> getPrevailingFactors(String objectType) {
        Map<String, Prevailing_Factor__mdt> prevailingFactors = Prevailing_Factor__mdt.getAll();
        List<PrevailingFactorComparator> factorComparators = new List<PrevailingFactorComparator>();

        for (String prevailingFactorName : prevailingFactors.keyset()) {
            Prevailing_Factor__mdt pf = prevailingFactors.get(prevailingFactorName);
            if (pf.Object__c == objectType && pf.Active__c) {
                factorComparators.add(new PrevailingFactorComparator(pf));
            }
        }
        factorComparators.sort();

        List<Prevailing_Factor__mdt> prevailingFactorList = new List<Prevailing_Factor__mdt>();
        for (PrevailingFactorComparator factorComparator : factorComparators) {
            prevailingFactorList.add(factorComparator.prevailingFactor);
        }
        return prevailingFactorList;
    }

    /**
     * Populates and returns a list of fields referenced in prevailing factors of type 'Field reference'.
     *
     * @param prevailingFactorList List of Prevailing_Factor__mdt objects representing prevailing factors.
     * @return List of fields categorized as 'Field reference' fields.
     */
    private static List<String> populatePrevailingFactorFieldList(List<Prevailing_Factor__mdt> prevailingFactorList) {
        List<String> pfFieldReferenceList = new List<String>();
        for (Prevailing_Factor__mdt pf : prevailingFactorList) {
            pfFieldReferenceList.add(pf.Field__c);
        }
        return pfFieldReferenceList;
    }

    /**
     * Queries matching records based on the specified object type, Ids and field list.
     *
     * @param objectType    The object type for which records are queried.
     * @param matchingIds   Set of IDs representing the matching records.
     * @param pfFieldReferenceList   List of fields to be included in the query.
     * @return Map of record IDs to SObjects based on the query results.
     */
    private static Map<Id, SObject> queryMatchingRecords(
        String objectType,
        Set<Id> matchingIds,
        List<String> pfFieldReferenceList
    ) {
        pfFieldReferenceList.add('RecordTypeId');
        String fieldList = String.join(pfFieldReferenceList, ', ');
        String queryTemplate = 'SELECT {0} FROM {1} WHERE Id IN :matchingIds ORDER BY LastModifiedDate DESC';
        String query = String.format(queryTemplate, new List<String>{ fieldList, objectType });
        return new Map<Id, SObject>((List<SObject>) Database.query(query));
    }

    /**
     * Builds PrevailingFactor objects based on the provided Prevailing_Factor__mdt records.
     *
     * @param prevailingFactorList A list of Prevailing_Factor__mdt records to process.
     * @param matchingIds A set of record Ids considered as matching.
     * @param recordsMatchedMap A map containing matched records with their associated Ids.
     * @return A list of PrevailingFactor objects populated with field values based on matchingIds and recordsMatchedMap.
     */
    private static List<PrevailingFactor> buildPrevailingFactorObjects(
        List<Prevailing_Factor__mdt> prevailingFactorList,
        Set<Id> matchingIds,
        Map<Id, SObject> recordsMatchedMap
    ) {
        List<PrevailingFactor> pfList = new List<PrevailingFactor>();
        for (Prevailing_Factor__mdt prevailingFactor : prevailingFactorList) {
            if (prevailingFactor.Condition__c == 'Field reference') {
                PrevailingFactor pf = new PrevailingFactor();
                pf.field = prevailingFactor.Field__c;
                pf.objectType = (prevailingFactor.Object__c == 'Student' ? 'Account' : prevailingFactor.Object__c);
                pf.recordType = prevailingFactor.Record_Type__c;
                buildPrevailingFactorMap(matchingIds, recordsMatchedMap, pf);
                pfList.add(pf);
            }
        }
        return pfList;
    }

    /**
     * Builds a map of record Ids and their corresponding field values for a given PrevailingFactor object.
     *
     * @param matchingIds A set of record Ids considered as matching.
     * @param recordsMatchedMap A map containing matched records with their associated Ids.
     * @param pf The PrevailingFactor object containing information about the field and record types to consider.
     */
    private static void buildPrevailingFactorMap(
        Set<Id> matchingIds,
        Map<Id, SObject> recordsMatchedMap,
        PrevailingFactor pf
    ) {
        for (Id recordId : matchingIds) {
            SObject record = recordsMatchedMap.get(recordId);
            String recordType = String.valueOf(record.get('RecordTypeId'));
            String recordTypeName = getRecordTypeName(pf.objectType, recordType);

            if (pf.recordType == 'N/A' || recordTypeName.contains(pf.recordType)) {
                pf.recordFieldMap.put(recordId, record.get(pf.field) != null);
            }
        }
    }

    /**
     * Determines the prevailing factor match based on the list of PrevailingFactor objects and a map of matched records.
     *
     * @param pfList A list of PrevailingFactor objects representing prevailing factors to evaluate.
     * @return The Id of the winning record if a match is found; otherwise, null.
     */
    private static Id determinePrevailingFactorMatch(List<PrevailingFactor> pfList) {
        for (PrevailingFactor pf : pfList) {
            Boolean hasValue = false;
            Boolean hasNoValue = false;

            for (Id recordId : pf.recordFieldMap.keySet()) {
                Boolean fieldValue = pf.recordFieldMap.get(recordId);
                if (fieldValue) {
                    hasValue = true;
                } else {
                    hasNoValue = true;
                }

                if (hasValue && hasNoValue) {
                    return recordId;
                }
            }
        }
        return null;
    }

    /**
     * Retrieves the winning record ID from a map based on a deciding field.
     *
     * @param recordsMatchedMap A map containing records matched based on certain conditions.
     * @param decidingField The field used to decide the winning record.
     * @return The winning record Id.
     */
    private static Id retrieveWinningRecordId(Map<Id, SObject> recordsMatchedMap, String decidingField) {
        Id winningId;
        if (decidingField == 'LastModifiedDate') {
            DateTime mostRecentlyModified;
            Map<DateTime, Id> lastModifiedMap = new Map<DateTime, Id>();
            for (Id recordId : recordsMatchedMap.keySet()) {
                SObject obj = recordsMatchedMap.get(recordId);
                DateTime lastModified = (DateTime) obj.get(decidingField);

                if (!lastModifiedMap.containsKey(lastModified)) {
                    lastModifiedMap.put(lastModified, recordId);
                }

                if (mostRecentlyModified == null || lastModified > mostRecentlyModified) {
                    mostRecentlyModified = lastModified;
                }
            }
            winningId = lastModifiedMap.get(mostRecentlyModified);
        }
        return winningId;
    }

    /**
     * Retrieves the record type name for a given object type and record type ID.
     *
     * @param objectType Object type associated with the record.
     * @param recordType Record type ID of the record.
     * @return Record type name.
     */
    public static String getRecordTypeName(String objectType, String recordType) {
        return Schema.getGlobalDescribe()
            .get(objectType)
            .getDescribe()
            .getRecordTypeInfosById()
            .get(recordType)
            .getName();
    }

    /**
     * Strips special characters from the provided string, leaving only alphanumeric characters
     * and spaces.
     *
     * @param providedString The input string from which special characters are to be stripped.
     * @return A new string with only alphanumeric characters and spaces.
     */
    public static String stripSpecialCharsFromString(String providedString) {
        return providedString.replaceAll('[^\\w\\s]', '');
    }

    /**
     * Represents a Prevailing Factor record.
     */
    private class PrevailingFactor {
        String field;
        String objectType;
        String recordType;
        Map<Id, Boolean> recordFieldMap = new Map<Id, Boolean>();
    }
}
