@isTest
private class RecordPurgeTest {
    private static final String ACCOUNT_CREATED_TODAY = '1. AccountCreatedToday';
    private static final String ACCOUNT_CREATED_1_WEEK_AGO = '2. AccountCreatedOneWeekAgo';
    private static final String ACCOUNT_FOR_INVALID_PURGE_RULES = '3. AccountForInvalidPurgeRules';

    @testSetup
    static void setup() {
        List<Account> accountsToInsert = new List<Account>{
            new Account(Name = ACCOUNT_CREATED_TODAY),
            new Account(Name = ACCOUNT_CREATED_1_WEEK_AGO),
            new Account(Name = ACCOUNT_FOR_INVALID_PURGE_RULES)
        };
        insert accountsToInsert;

        // Set the second Accounts created date to 1 weeks ago
        Test.setCreatedDate(accountsToInsert[1].Id, Date.today().addDays(-7));
    }

    @isTest
    public static void itShouldScheduleCorrectly() {
        // GIVEN a Cron Trigger of a date in the future
        String cronExpression = '0 0 0 01 01 ? 2099';

        System.Test.startTest();

        // WHEN the Record Purge class is scheduled
        String purgeJobId = System.schedule('Record Purge Test', cronExpression, new RecordPurge());

        System.Test.stopTest();

        CronTrigger cronTriggerResult = [
            SELECT Id, NextFireTime
            FROM CronTrigger
            WHERE id = :purgeJobId
        ];

        // THEN the job should have been scheduled
        Assert.areEqual('2099-01-01 00:00:00', String.valueOf(cronTriggerResult.NextFireTime));
    }

    @isTest
    public static void itShouldNotProcessInvalidQueries() {
        // GIVEN some Record Purge Rules
        // One to delete an Account created today
        Record_Purge_Rules__c validRuleToday = new Record_Purge_Rules__c(
            Name = 'Valid Rule (Today)',
            Criteria__c = 'Name = \'' + ACCOUNT_CREATED_TODAY + '\'',
            Retention_Days__c = 0,
            SObject_Name__c = 'Account',
            Active__c = true
        );

        // One to delete the an Account created 2 weeks ago (Should not find any matches)
        Record_Purge_Rules__c validRuleOneWeek = new Record_Purge_Rules__c(
            Name = 'Valid Rule (2 Weeks)',
            Criteria__c = 'Name = \'' + ACCOUNT_CREATED_1_WEEK_AGO + '\'',
            Retention_Days__c = 14,
            SObject_Name__c = 'Account',
            Active__c = true
        );

        // One to delete the an Account created today (But with an invalid query)
        Record_Purge_Rules__c invalidRule = new Record_Purge_Rules__c(
            Name = 'Invalid Rule',
            Criteria__c = 'Name = \'' + ACCOUNT_FOR_INVALID_PURGE_RULES + '\' AND SomeFilterThatIsInvalid',
            Retention_Days__c = 0,
            SObject_Name__c = 'Account',
            Active__c = true
        );

        insert new List<Record_Purge_Rules__c>{ validRuleToday, validRuleOneWeek, invalidRule };

        // AND there is at least one user added to the Admin_Alert_Recipients group
        TestUtilities.addUsersToGroup(new List<User>{ new User(Id = UserInfo.getUserId()) }, 'Admin_Alert_Recipients');

        System.Test.startTest();

        // WHEN the Record Purge class is executed
        RecordPurge testRecordPurge = new RecordPurge();
        testRecordPurge.execute(null);

        System.Test.stopTest();

        // THEN two Accounts should remain
        List<Account> accountResults = [SELECT Id, Name FROM Account ORDER BY Name ASC];
        Assert.areEqual(2, accountResults.size());

        // AND the first Account should be for the 1 week old Account
        Assert.areEqual(ACCOUNT_CREATED_1_WEEK_AGO, accountResults[0].Name);

        // AND the second Account should be for the invalid purge rule
        Assert.areEqual(ACCOUNT_FOR_INVALID_PURGE_RULES, accountResults[1].Name);

        // AND an email should have been submitted
        Assert.areEqual(RecordPurge.PURGE_RULE_FAILURE_SUBJECT, EmailUtilities.ResultingEmailMessage.subject);
    }
}
