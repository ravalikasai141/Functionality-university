@isTest
private class BaseProcessorTest {
    @testSetup
    static void setup() {
        List<Queue_Job__c> queueJobsToInsert = new List<Queue_Job__c>();
        for (Integer i = 0; i < 4; i++) {
            queueJobsToInsert.add(
                new Queue_Job__c(
                    Status__c = 'Processing',
                    Channel__c = 'Event',
                    Job_Type__c = 'Example',
                    Failure_Count__c = 0
                )
            );
        }
        Database.Insert(queueJobsToInsert);
    }

    @isTest
    public static void itShouldProcessSuccesses() {
        // This can be any processor class but cannot be BaseProcessor directly due to it being abstract
        EventExampleProcessor processor = new EventExampleProcessor();

        // GIVEN some Queue Jobs
        List<Queue_Job__c> testQueueJobs = [SELECT Id, Status__c FROM Queue_Job__c WHERE Status__c = 'Processing'];
        processor.successfulJobs = testQueueJobs;

        System.Test.startTest();

        // WHEN the processSuccesses method is called
        List<Queue_Job__c> returnedJobs = processor.processSuccesses();

        System.Test.stopTest();

        // THEN the jobs should have been updated to Processed
        for (Queue_Job__c currentJob : returnedJobs) {
            Assert.areEqual('Processed', currentJob.Status__c);
        }
    }

    @isTest
    public static void itShouldProcessFails() {
        // This can be any processor class but cannot be BaseProcessor directly due to it being abstract
        EventExampleProcessor processor = new EventExampleProcessor();
        String testError = 'An example error';

        // GIVEN some Queue Jobs which have been inserted into the failedJobs Map along with a test error message
        for (Queue_Job__c currentJob : [
            SELECT Id, Status__c, Failure_Count__c, Errors__c
            FROM Queue_Job__c
            WHERE Status__c = 'Processing'
        ]) {
            processor.failedJobs.put(currentJob, testError);
        }

        System.Test.startTest();

        // WHEN the processFails method is called
        Set<Queue_Job__c> returnedJobs = processor.processFails();

        System.Test.stopTest();

        // THEN the jobs should have been updated to Failed, failure count incremented and error fields updated
        for (Queue_Job__c currentJob : returnedJobs) {
            Assert.areEqual('Failed', currentJob.Status__c);
            Assert.areEqual(1, currentJob.Failure_Count__c);
            Assert.areEqual(testError, currentJob.Last_Error__c);
            Assert.areEqual('[ "1. ' + testError + '" ]', currentJob.Errors__c);
        }
    }

    @isTest
    public static void itShouldProcessRetriesBelowTheFailThreshold() {
        // This can be any processor class but cannot be BaseProcessor directly due to it being abstract
        EventExampleProcessor processor = new EventExampleProcessor();
        String testError = 'An example error';

        // GIVEN some Queue Jobs
        for (Queue_Job__c currentJob : [
            SELECT Id, Status__c, Failure_Count__c, Errors__c
            FROM Queue_Job__c
            WHERE Status__c = 'Processing'
        ]) {
            // AND they are below the failure threshold
            currentJob.Failure_Count__c = 0;

            // AND they have been inserted into the retryJobs Map along with a test error message
            processor.retryJobs.put(currentJob, testError);
        }

        System.Test.startTest();

        // WHEN the processRetries method is called
        Set<Queue_Job__c> returnedJobs = processor.processRetries();

        System.Test.stopTest();

        // THEN the jobs should have been updated to Failed, failure count incremented and error fields updated
        for (Queue_Job__c currentJob : returnedJobs) {
            Assert.areEqual('Pending', currentJob.Status__c);
            Assert.areEqual(1, currentJob.Failure_Count__c);
            Assert.areEqual(testError, currentJob.Last_Error__c);
            Assert.areEqual('[ "1. ' + testError + '" ]', currentJob.Errors__c);
        }
    }

    @isTest
    public static void itShouldProcessRetriesAboveOrAtTheFailThreshold() {
        // This can be any processor class but cannot be BaseProcessor directly due to it being abstract
        EventExampleProcessor processor = new EventExampleProcessor();
        String testError = 'An example error';

        // GIVEN some Queue Jobs
        for (Queue_Job__c currentJob : [
            SELECT Id, Status__c, Failure_Count__c, Errors__c
            FROM Queue_Job__c
            WHERE Status__c = 'Processing'
        ]) {
            // AND they are about to reach the failure threshold
            currentJob.Errors__c = '[ "1. One", "2. Two", "3. Three", "4. Four" ]';
            currentJob.Failure_Count__c = BaseProcessor.MAX_FAIL_COUNT - 1;

            // AND they have been inserted into the retryJobs Map along with a test error message
            processor.retryJobs.put(currentJob, testError);
        }

        System.Test.startTest();

        // WHEN the processRetries method is called
        Set<Queue_Job__c> returnedJobs = processor.processRetries();

        System.Test.stopTest();

        // THEN the jobs should have been updated to Failed, failure count incremented and error fields updated
        for (Queue_Job__c currentJob : returnedJobs) {
            Assert.areEqual('Failed', currentJob.Status__c);
            Assert.areEqual(5, currentJob.Failure_Count__c);
            Assert.areEqual(testError, currentJob.Last_Error__c);
            Assert.areEqual(
                '[ "1. One", "2. Two", "3. Three", "4. Four", "5. ' + testError + '" ]',
                currentJob.Errors__c
            );
        }
    }

    @isTest
    public static void itShouldFormatDMLErrors() {
        // GIVEN some Errors
        // Create an account without required fields
        Database.SaveResult result = Database.insert(new Account(), false);
        List<Database.Error> err = result.getErrors();

        Queue_Job__c job = new Queue_Job__c();
        
        System.Test.startTest();

        // WHEN processDMLErrors is called
        EventExampleProcessor processor = new EventExampleProcessor();
        processor.processDMLErrors(job, err);

        System.Test.stopTest();

        // THEN the failed jobs is populated with an error message
        Assert.areEqual(1, processor.failedJobs.size());
        Assert.areEqual('Required fields are missing: [Name]', processor.failedJobs.values()[0]);
    }
}
