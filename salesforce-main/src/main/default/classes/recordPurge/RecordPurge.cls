global class RecordPurge implements Schedulable {
    private static final Integer BATCH_LIMIT = 1000;

    @TestVisible
    private static final String PURGE_RULE_FAILURE_SUBJECT = 'Invalid Record Purge Rule(s)';

    /**
     * Queries out any Record Purge Rules, ensures that the queries are valid and creates batch jobs
     * to delete any records retrieved using the Record Purge Rule content
     *
     * @param scheduleContext The schedule context object to track the progress of the schedule job
     */
    global void execute(SchedulableContext scheduleContext) {
        List<String> failedRules = new List<String>();

        for (Record_Purge_Rules__c currentRule : [
            SELECT Id, Name, Criteria__c, SObject_Name__c, Retention_Days__c
            FROM Record_Purge_Rules__c
            WHERE Active__c = TRUE
            ORDER BY SObject_Name__c, Name
        ]) {
            try {
                // Attempt to run the query, catching and alerting on query failure
                Database.query(createQueryString(currentRule, 0));

                Database.executeBatch(new RecordPurgeBatch(currentRule), BATCH_LIMIT);
            } catch (QueryException ex) {
                failedRules.add(currentRule.Name);
            }
        }

        if (!failedRules.isEmpty()) {
            EmailUtilities.submitSystemAlertEmail(
                PURGE_RULE_FAILURE_SUBJECT,
                'The following Record Purge Rules failed to process: ' + String.join(failedRules, ', ')
            );
        }
    }

    /**
     * Builds up a query string based off of a record purge rule records content
     *
     * @param purgeRule The record purge rule to based the query off of
     * @param limitValue The amount of records that should be returned by this query
     * @return The query string created using the record purge rule content
     */
    public static String createQueryString(Record_Purge_Rules__c purgeRule, Integer limitValue) {
        String retentionClause = purgeRule.Retention_Days__c <= 0
            ? '<= TODAY'
            : '< LAST_N_DAYS:' + purgeRule.Retention_Days__c;

        return String.format(
            'SELECT Id, Name FROM {0} WHERE CreatedDate {1} {2} LIMIT {3}',
            new List<String>{
                purgeRule.SObject_Name__c,
                retentionClause,
                String.isBlank(purgeRule.Criteria__c) ? '' : 'AND ' + purgeRule.Criteria__c,
                String.valueOf(limitValue)
            }
        );
    }
}
