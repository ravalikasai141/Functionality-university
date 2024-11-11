@isTest
public class HandleDuplicateProfileIdsTest {
    static final String PROFILE_ID = 'a1b2c3d4e5f6g7h8i9';

    @testSetup
    static void makeData() {
        Id recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
            .get('Student_Account')
            .getRecordTypeId();

        List<Account> accountList = new List<Account>();
        for (Integer i = 0; i < 75; i++) {
            accountList.add(
                new Account(
                    FirstName = TestDataFactory.generateUniqueString(),
                    LastName = TestDataFactory.generateUniqueString(),
                    RecordTypeId = recordTypeId
                )
            );
        }
        Database.DMLOptions dml = BypassDuplicateCheck.createDMLOption();
        Database.insert(accountList, dml);
    }

    @isTest
    private static void itShouldDetermineTheWinningAccountAndRemoveProfileIdFromOthers() {
        // GIVEN Accounts exist with the same Profile Id
        List<Account> accountListBefore = [SELECT Id, PS_Profile_Services_ID__pc, RecordTypeId FROM Account];

        // Update each set of 25 Account records with the same Profile Id value.
        for (Integer i = 0; i < accountListBefore.size(); i++) {
            Integer setIndex = Integer.valueOf(Math.floor(i / 25));
            String profileIdValue = PROFILE_ID + (setIndex + 1);

            accountListBefore.get(i).Account_Bypass_Duplicate_Check__c = false;
            accountListBefore.get(i).PS_Profile_Services_ID__pc = profileIdValue;
        }
        update accountListBefore;

        // WHEN the process runs
        HandleDuplicateProfileIds.processDuplicates();

        // THEN only 3 Accounts should have the previously duplicated Profile Id (1 from block from each 25).
        AggregateResult[] results = [
            SELECT COUNT(Id) recordCount, COUNT(PS_Profile_Services_ID__pc) withProfileIdCount
            FROM Account
        ];

        Integer totalRecordCount = (Integer) results[0].get('recordCount');
        Integer withProfileIdCount = (Integer) results[0].get('withProfileIdCount');
        Integer withoutProfileIdCount = totalRecordCount - withProfileIdCount;

        Assert.areEqual(75, totalRecordCount, '75 Account records should be retrieved.');
        Assert.areEqual(3, withProfileIdCount, '3 Account records should still have a Profile Id value.');
        Assert.areEqual(72, withoutProfileIdCount, 'The remaining Account records should not have a Profile Id value.');
    }
}
