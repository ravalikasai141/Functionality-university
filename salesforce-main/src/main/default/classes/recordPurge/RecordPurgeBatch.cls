global class RecordPurgeBatch implements Database.Batchable<SObject>, Database.Stateful {
    private Record_Purge_Rules__c purgeRule;
    private Integer failedDeleteCount = 0;

    @TestVisible
    private static final String RECORD_PURGE_FAILURE_SUBJECT = 'Record Purge deletion failure';

    /**
     * Sets the purge rule that should be used for querying out any records to be purged in a given batch instance
     *
     *  @param purgeRule The record purge rule to process
     */
    public RecordPurgeBatch(Record_Purge_Rules__c purgeRule) {
        this.purgeRule = purgeRule;
    }

    /**
     * Handles querying out any records which should be purged and batching them up into individual batch jobs
     *
     *  @param batchContext The batchable context object to track the progress of the batch job
     */
    public Database.QueryLocator start(Database.BatchableContext batchContext) {
        return Database.getQueryLocator(RecordPurge.createQueryString(purgeRule, Limits.getLimitQueryLocatorRows()));
    }

    /**
     * Handles the purging of any records identified in the given batch job
     *
     *  @param batchContext The batchable context object to track the progress of the batch job
     *  @param  recordsToPurge  The records to be purged
     */
    public void execute(Database.BatchableContext bc, List<SObject> recordsToPurge) {
        for (Database.DeleteResult currentResult : Database.delete(recordsToPurge, false)) {
            if (!currentResult.isSuccess()) {
                for (Database.Error currentError : currentResult.getErrors()) {
                    // Any errors that are not because the record has already been deleted should be marked as a record deletion failure
                    if (currentError.getStatusCode() != StatusCode.ENTITY_IS_DELETED) {
                        failedDeleteCount++;
                        break;
                    }
                }
            }
        }
    }

    /**
     * Updates the given record purge rule to identify when it was last executed and submits any alert emails
     * when records could not be deleted
     *
     *  @param batchContext The batchable context object to track the progress of the batch job
     */
    public void finish(Database.BatchableContext bc) {
        // Record Purge rule updates
        purgeRule.Last_Run__c = DateTime.now();
        update purgeRule;

        // Failed Deletion email alerts
        if (failedDeleteCount > 0) {
            EmailUtilities.submitSystemAlertEmail(
                RECORD_PURGE_FAILURE_SUBJECT,
                String.format(
                    'The "{0}" Record Purge Rule has failed to delete {1} records',
                    new List<String>{ purgeRule.Name, String.valueOf(failedDeleteCount) }
                )
            );
        }
    }
}
