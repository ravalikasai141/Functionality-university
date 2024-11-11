public with sharing class DuplicateRules {
    @AuraEnabled
    public static List<sObject> findDuplicates(String jsonRecord, String sobjectType) {
        if (sobjectType == 'Contact') {
            Contact recordToCheck = (Contact) JSON.deserialize(jsonRecord, Contact.class);
            List<Id> matchedIds = checkDuplicateRules(recordToCheck, 'Contact');

            if (!matchedIds.isEmpty()) {
                return [SELECT Id, Name, Email FROM Contact WHERE Id IN :matchedIds];
            }
        } else if (sobjectType == 'Account') {
            Account recordToCheck = (Account) JSON.deserialize(jsonRecord, Account.class);
            List<Id> matchedIds = checkDuplicateRules(recordToCheck, 'Account');

            if (!matchedIds.isEmpty()) {
                return [SELECT Id, Name, BPP_Account_Number__c FROM Account WHERE Id IN :matchedIds];
            }
        }
        return null;
    }

    public static List<Id> checkDuplicateRules(sObject recordToCheck, String sobjectType) {
        List<Id> matchedIds = new List<Id>();

        // Get first index as one record was passed
        List<Datacloud.FindDuplicatesResult> duplicateResults = Datacloud.FindDuplicates.findDuplicates(
            new List<sObject>{ recordToCheck }
        );

        Datacloud.FindDuplicatesResult duplicateResultEntry = duplicateResults[0];

        // Result per duplicate rule matched
        for (Datacloud.DuplicateResult duplicateResult : duplicateResultEntry.getDuplicateResults()) {
            // Result per matching rule matched
            for (Datacloud.MatchResult matchResult : duplicateResult.getMatchResults()) {
                if (matchResult.getEntityType() != sobjectType) {
                    continue;
                }
                // Records that match the rule
                for (Datacloud.MatchRecord matchRecord : matchResult.getMatchRecords()) {
                    matchedIds.add(matchRecord.getRecord().Id);
                }
            }
        }

        return matchedIds;
    }
}