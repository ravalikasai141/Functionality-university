@isTest
private class BPP_BatchCreditNoteLineSnapshotSchedTest {    
    @isTest 
    static void test() {
        Test.startTest();
        	String jobName = 'BPP_BatchCreditNoteLineSnapshot Test';
            BPP_BatchCreditNoteLineSnapshotScheduler batch = new BPP_BatchCreditNoteLineSnapshotScheduler();
            String CRON_EXP = '0 0 0 3 9 ? 2025';
            System.schedule(jobName, CRON_EXP, batch);
            CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE CronJobDetail.Name =: jobName];
        Test.stopTest();
        
        System.debug('Cron expression: ' + ct.CronExpression);
        System.assertEquals('0 0 0 3 9 ? 2025', ct.CronExpression);
    }
}