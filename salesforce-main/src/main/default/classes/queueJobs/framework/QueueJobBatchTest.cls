@isTest
public class QueueJobBatchTest {
    private static String jobType = 'Example';
    private static Integer numberOfTestJobs = 10;
    private static String channelName = 'Event';

    @testSetup
    static void setup() {
        List<Queue_Job__c> testQueueJobs = new List<Queue_Job__c>();
        for (Integer i = 0; i < numberOfTestJobs; i++) {
            testQueueJobs.add(
                new Queue_Job__c(
                    Status__c = 'Pending',
                    Channel__c = channelName,
                    Job_Type__c = jobType,
                    External_Id__c = 'ExampleJob' + i,
                    Job_Content__c = '{"eventAction":"Pass"}'
                )
            );
        }
        Database.Insert(testQueueJobs);
    }

    @isTest
    public static void itShouldBeAbleToMapQueueObjectsByType() {
        // GIVEN an error message and some Queue Jobs
        String errorMessage = 'Example error message';
        List<Queue_Job__c> jobsToIncludeInEmail = [SELECT Id, Job_Content__c, External_Id__c FROM Queue_Job__c];

        // AND there is at least one user added to the Admin_Alert_Recipients group
        TestUtilities.addUsersToGroup(new List<User>{ new User(Id = UserInfo.getUserId()) }, 'Admin_Alert_Recipients');

        System.Test.startTest();

        // WHEN the buildAndSendUnhandledError method is called
        QueueJobBatch.buildAndSendUnhandledError(errorMessage, jobsToIncludeInEmail);

        System.Test.stopTest();

        // THEN the body of the email contains the error message provided
        Assert.isTrue(QueueJobBatch.failedUpdateEmail.htmlBody.contains(errorMessage));

        // AND the Queue Jobs details have been serialized into the emails body
        for (Queue_Job__c currentJob : jobsToIncludeInEmail) {
            Assert.isTrue(QueueJobBatch.failedUpdateEmail.htmlBody.contains(currentJob.External_Id__c));
        }
    }

    @isTest
    static void itShouldProcessBatchJobs() {
        // GIVEN some pending Queue Jobs
        Map<Id, Queue_Job__c> queueJobsToTest = new Map<Id, Queue_Job__c>(
            [
                SELECT Id, Status__c
                FROM Queue_Job__c
                WHERE Job_Type__c = :jobType AND Status__c = 'Pending'
            ]
        );

        // AND batch instance with those jobs
        QueueJobBatch queueJobBatchInstance = new QueueJobBatch(channelName, numberOfTestJobs);

        System.Test.startTest();

        for (Queue_Job__c currentJob : [
            SELECT Id, Status__c
            FROM Queue_Job__c
            WHERE Job_Type__c = :jobType
        ]) {
            // AND all jobs identified before initialising are counted for
            Assert.isTrue(queueJobsToTest.containsKey(currentJob.Id));

            // AND they have all been updated to "Processing"
            Assert.areEqual('Processing', currentJob.Status__c);
            Assert.areNotEqual(queueJobsToTest.get(currentJob.Id).Status__c, currentJob.Status__c);
        }

        // WHEN the batch is executed
        Database.executeBatch(queueJobBatchInstance, numberOfTestJobs);

        System.Test.stopTest();

        // THEN the jobs should have been updated to "Processed"
        for (Queue_Job__c currentJob : [
            SELECT Status__c
            FROM Queue_Job__c
            WHERE Id IN :queueJobsToTest.keySet()
        ]) {
            Assert.areEqual('Processed', currentJob.Status__c);
        }
    }

    @isTest
    static void itShouldBlockInvalidProcessorTypes() {
        // GIVEN some pending Queue Jobs
        Map<Id, Queue_Job__c> queueJobsToTest = new Map<Id, Queue_Job__c>(
            [
                SELECT Id, Status__c
                FROM Queue_Job__c
                WHERE Job_Type__c = :jobType AND Status__c = 'Pending'
            ]
        );

        // AND the Queue Jobs have invalid Job Types
        for (Queue_Job__c currentJob : queueJobsToTest.values()) {
            currentJob.Job_Type__c = 'InvalidEventType';
        }
        update queueJobsToTest.values();

        // AND batch instance with those jobs
        QueueJobBatch queueJobBatchInstance = new QueueJobBatch(channelName, numberOfTestJobs);

        System.Test.startTest();

        for (Queue_Job__c currentJob : [
            SELECT Id, Status__c
            FROM Queue_Job__c
            WHERE Job_Type__c = :jobType
        ]) {
            // AND all jobs identified before initialising are counted for
            Assert.isTrue(queueJobsToTest.containsKey(currentJob.Id));

            // AND they have all been updated to "Processing"
            Assert.areEqual('Processing', currentJob.Status__c);
            Assert.areNotEqual(queueJobsToTest.get(currentJob.Id).Status__c, currentJob.Status__c);
        }

        // WHEN the batch is executed
        Database.executeBatch(queueJobBatchInstance, numberOfTestJobs);

        System.Test.stopTest();

        for (Queue_Job__c currentJob : [
            SELECT Id, Status__c, Last_Error__c
            FROM Queue_Job__c
            WHERE Id IN :queueJobsToTest.keySet()
        ]) {
            // THEN the jobs should have been updated to "Blocked"
            Assert.areEqual('Blocked', currentJob.Status__c);

            // AND the jobs should all have had an error message added to them
            Assert.areEqual('Processor type EventInvalidEventTypeProcessor not found.', currentJob.Last_Error__c);
        }
    }

    @isTest
    static void itShouldHandleFailedJobs() {
        // GIVEN some pending Queue Jobs
        Map<Id, Queue_Job__c> queueJobsToTest = new Map<Id, Queue_Job__c>(
            [
                SELECT Id, Status__c
                FROM Queue_Job__c
                WHERE Job_Type__c = :jobType AND Status__c = 'Pending'
            ]
        );

        // AND the Queue Jobs have invalid Job Types
        for (Queue_Job__c currentJob : queueJobsToTest.values()) {
            currentJob.Job_Content__c = '{"eventAction":"Fail"}';
        }
        update queueJobsToTest.values();

        // AND batch instance with those jobs
        QueueJobBatch queueJobBatchInstance = new QueueJobBatch(channelName, numberOfTestJobs);

        // Run as the current user to avoid MIXED_DML errors
        System.runAs(new User(Id = UserInfo.getUserId())) {
            // AND there is at least one user added to the Admin_Alert_Recipients group
            TestUtilities.addUsersToGroup(
                new List<User>{ new User(Id = UserInfo.getUserId()) },
                'Admin_Alert_Recipients'
            );
        }

        System.Test.startTest();

        for (Queue_Job__c currentJob : [
            SELECT Id, Status__c
            FROM Queue_Job__c
            WHERE Job_Type__c = :jobType
        ]) {
            // AND all jobs identified before initialising are counted for
            Assert.isTrue(queueJobsToTest.containsKey(currentJob.Id));

            // AND they have all been updated to "Processing"
            Assert.areEqual('Processing', currentJob.Status__c);
            Assert.areNotEqual(queueJobsToTest.get(currentJob.Id).Status__c, currentJob.Status__c);
        }

        // WHEN the batch is executed
        Database.executeBatch(queueJobBatchInstance, numberOfTestJobs);

        System.Test.stopTest();

        for (Queue_Job__c currentJob : [
            SELECT Id, Status__c, Last_Error__c
            FROM Queue_Job__c
            WHERE Id IN :queueJobsToTest.keySet()
        ]) {
            // THEN the jobs should have been updated to "Blocked"
            Assert.areEqual('Failed', currentJob.Status__c);

            // AND the jobs should all have had an error message added to them
            Assert.areEqual('failed', currentJob.Last_Error__c);

            // AND the email submitted should include the Jobs Id
            Assert.isTrue(QueueJobUtilities.failedJobsEmail.htmlBody.contains(currentJob.Id));
        }
    }
}
