/**
 * Provides methods to handle duplicate Profile Ids across Salesforce Accounts.
 * It includes functionality to identify duplicate Profile Ids, retrieve Accounts associated with these duplicates,
 * determine winning IDs based on matching records, remove winning records from the Account map, and remove the Profile Id
 * value from remaining records.
 */
public class HandleDuplicateProfileIds {
    /**
     * Processes duplicate Profile Ids
     */
    public static void processDuplicates() {
        Set<String> profileIds = findDuplicateProfileIds();
        Map<Id, Account> accountMap = fetchAccountsByProfileIds(profileIds);
        Map<String, List<Account>> profileIdAccountMap = groupAccountsByProfileId(accountMap);
        Set<Id> winningIds = determineWinningIds(profileIdAccountMap);
        removeWinningRecordsFromMap(accountMap, winningIds);
        removeProfileIdFromRemainingRecords(accountMap);
    }

    /**
     * Locates duplicate values of Profile Ids across Account records.
     *
     * @return A set of strings representing the duplicate Profile Ids.
     */
    private static Set<String> findDuplicateProfileIds() {
        Set<String> profileIds = new Set<String>();
        List<AggregateResult> arList = [
            SELECT Count(Id), PS_Profile_Services_ID__pc
            FROM Account 
            WHERE PS_Profile_Services_ID__pc != null 
            GROUP BY PS_Profile_Services_ID__pc HAVING Count(Id) > 1
        ];
        for (AggregateResult ar : arList) {
            profileIds.add((String)ar.get('PS_Profile_Services_ID__pc'));
        }
        return profileIds;
    }

    /**
     * Fetches Accounts associated with the provided Profile Ids.
     *
     * @param profileIds A set of strings representing the Profile Ids.
     * @return A map containing the fetched Accounts, with Account Ids as keys and Account records as values.
     */
    private static Map<Id, Account> fetchAccountsByProfileIds(Set<String> profileIds) {
        return new Map<Id, Account>([
            SELECT Id, PS_Profile_Services_ID__pc, RecordTypeId
            FROM Account
            WHERE PS_Profile_Services_ID__pc IN :profileIds
            AND PS_Profile_Services_ID__pc != null
        ]);
    }

    /**
     * Groups Accounts by Profile Id.
     
     * @param accountMap A map containing the fetched Accounts, with Account Ids as keys and Account records as values.
     * @return A map where Profile Ids are keys and lists of associated Accounts are values.
     */
    private static Map<String, List<Account>> groupAccountsByProfileId(Map<Id, Account> accountMap) {
        Map<String, List<Account>> profileIdAccountMap = new Map<String, List<Account>>();
        for (Account acc : accountMap.values()) {
            List<Account> recordsForMap = profileIdAccountMap.get(acc.PS_Profile_Services_ID__pc);
            if (recordsForMap == null) {
                recordsForMap = new List<Account>();
                profileIdAccountMap.put(acc.PS_Profile_Services_ID__pc, recordsForMap);
            }    
            recordsForMap.add(acc);
        }
        return profileIdAccountMap;
    }

    /**
     * Determines winning Ids based on matching records. Uses duplicate process.
     *
     * @param profileIdAccountMap A map where Profile Ids are keys and lists of associated accounts are values.
     * @return A set of winning Account Ids.
     */
    private static Set<Id> determineWinningIds(Map<String, List<Account>> profileIdAccountMap) {
        Set<Id> winningIds = new Set<Id>();
        for (String key : profileIdAccountMap.keySet()) {
            List<DuplicateHandler.MatchingRecord> matchingRecords = DuplicateFinder.findDuplicateRecords(profileIdAccountMap.get(key));
            String winningId;
			if (matchingRecords.size() == 1) {
				winningId = matchingRecords.get(0).matchingId;
			} else if (matchingRecords.size() > 1) {
				winningId = DuplicateHandler.handleMatchingRecords(matchingRecords);
			}
			if (winningId != null) {
				winningIds.add(winningId);
			}
        }
        return winningIds;
    }

    /**
     * Removes winning records from the Account map.
     *
     * @param accountMap A map containing the fetched Accounts, with Account Ids as keys and Account records as values.
     * @param winningIds A set of winning account IDs.
     */
    private static void removeWinningRecordsFromMap(Map<Id, Account> accountMap, Set<Id> winningIds) {
        for (Id id : winningIds) {
            if (accountMap.containsKey(id)) {
                accountMap.remove(id);
            }
        }
    }

    /**
     * Removes the Profile Id value from remaining records.
     *
     * @param accountMap A map containing the fetched accounts, with Account Ids as keys and Account records as values.
     */
    private static void removeProfileIdFromRemainingRecords(Map<Id, Account> accountMap) {
        for (Id key : accountMap.keySet()) {
            Account account = accountMap.get(key);
            account.PS_Profile_Services_ID__pc = null;
        }
        Database.DMLOptions dml = BypassDuplicateCheck.createDMLOption();
        Database.update(accountMap.values(), dml);
    }
}