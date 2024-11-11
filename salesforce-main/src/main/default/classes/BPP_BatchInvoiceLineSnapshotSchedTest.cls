@isTest
private class BPP_BatchInvoiceLineSnapshotSchedTest {    
    @isTest 
    static void test() {
        Test.startTest();
        	String jobName = 'BPP_BatchInvoiceLineSnapshotScheduler Test';
            BPP_BatchInvoiceLineSnapshotScheduler batch = new BPP_BatchInvoiceLineSnapshotScheduler();
            String CRON_EXP = '0 0 0 3 9 ? 2025';
            System.schedule(jobName, CRON_EXP, batch);
            CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE CronJobDetail.Name =: jobName];
        Test.stopTest();
        
        System.debug('Cron expression: ' + ct.CronExpression);
        System.assertEquals('0 0 0 3 9 ? 2025', ct.CronExpression);
    }
}