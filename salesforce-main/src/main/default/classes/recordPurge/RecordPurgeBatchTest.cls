@isTest
private class RecordPurgeBatchTest {
    private static final String ACCOUNT_CREATED_TODAY = '1. AccountCreatedToday';
    private static final String ACCOUNT_CREATED_1_WEEK_AGO = '2. AccountCreatedOneWeekAgo';

    private static final Id ACCOUNT_RECORD_TYPE_ID = Schema.SObjectType.Account.getRecordTypeInfosByName()
        .get('Student Account')
        .getRecordTypeId();

    @testSetup
    static void setup() {
        List<Account> accountsToInsert = new List<Account>{
            new Account(FirstName = ACCOUNT_CREATED_TODAY, LastName = '1', RecordTypeId = ACCOUNT_RECORD_TYPE_ID),
            new Account(FirstName = ACCOUNT_CREATED_1_WEEK_AGO, LastName = '2', RecordTypeId = ACCOUNT_RECORD_TYPE_ID)
        };
        insert accountsToInsert;

        // Set the second Accounts created date to 1 weeks ago
        Test.setCreatedDate(accountsToInsert[1].Id, Date.today().addDays(-7));
    }

    @isTest
    public static void itShouldNotPurgeRecordsOutOfScope() {
        // GIVEN a Purge Rule to delete all Accounts older than 4 days old
        Record_Purge_Rules__c validRuleFourDays = new Record_Purge_Rules__c(
            Name = 'Valid Rule (4 Days)',
            Criteria__c = 'FirstName LIKE \'%Account%\'',
            Retention_Days__c = 4,
            SObject_Name__c = 'Account',
            Last_Run__c = Datetime.now(),
            Active__c = true
        );
        insert validRuleFourDays;

        System.Test.startTest();

        // WHEN the record purge batch is executed
        Database.executeBatch(new RecordPurgeBatch(validRuleFourDays), 50);

        System.Test.stopTest();

        // THEN 1 Account should remain
        List<Account> accountResults = [SELECT Id, FirstName FROM Account ORDER BY Name ASC];
        Assert.areEqual(1, accountResults.size());

        // AND it should be the Account created today
        Assert.areEqual(ACCOUNT_CREATED_TODAY, accountResults[0].FirstName);

        // AND no email should have been submitted
        Assert.areEqual(null, EmailUtilities.ResultingEmailMessage);
    }

    @isTest
    public static void itShouldNotPurgeRelatedRecords() {
        // GIVEN a Purge Rule to delete all Accounts older than 4 days old
        Record_Purge_Rules__c validRule = new Record_Purge_Rules__c(
            Name = 'Valid Rule',
            Criteria__c = 'FirstName LIKE \'%Account%\'',
            Retention_Days__c = 0,
            SObject_Name__c = 'Account',
            Last_Run__c = Datetime.now(),
            Active__c = true
        );
        insert validRule;

        // AND a record linked to the first Account, restricting its deletion
        Account accountToRetain = [SELECT Id FROM Account WHERE FirstName = :ACCOUNT_CREATED_TODAY];
        insert new Hub_Account__c(
            Student__c = accountToRetain.Id,
            Auth0_Id__c = 'sub|12345',
            Hub_Username__c = 'testuser@bpp.com'
        );

        // AND there is at least one user added to the Admin_Alert_Recipients group
        TestUtilities.addUsersToGroup(new List<User>{ new User(Id = UserInfo.getUserId()) }, 'Admin_Alert_Recipients');

        System.Test.startTest();

        // WHEN the record purge batch is executed
        Database.executeBatch(new RecordPurgeBatch(validRule), 50);

        System.Test.stopTest();

        // THEN 1 Account should remain
        List<Account> accountResults = [SELECT Id FROM Account ORDER BY Name ASC];
        Assert.areEqual(1, accountResults.size());

        // AND it should be the Account that has a dependency
        Assert.areEqual(accountToRetain.Id, accountResults[0].Id);

        // AND a failure email should have been submitted
        Assert.areEqual(RecordPurgeBatch.RECORD_PURGE_FAILURE_SUBJECT, EmailUtilities.ResultingEmailMessage.subject);
    }
}
