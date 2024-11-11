@isTest
private class QueueJobUtilitiesTest {
    @isTest
    public static void itShouldUpdateQueueJobErrorMessages() {
        // GIVEN an Queue Job with an existing error message
        Queue_Job__c testJob = new Queue_Job__c(
            Status__c = 'Processing',
            Last_Error__c = 'Existing Error',
            Failure_Count__c = 1,
            Errors__c = '[ "1. Existing Error" ]'
        );

        String newErrorMessage = 'New Error';

        System.Test.startTest();

        // WHEN the updateErrorMessages method is called
        Queue_Job__c queueJobResults = QueueJobUtilities.updateErrorMessages(testJob, newErrorMessage);

        System.Test.stopTest();

        // THEN the Last Error field should be updated
        Assert.areEqual(newErrorMessage, queueJobResults.Last_Error__c);

        // AND the Errors field should have been added to
        Assert.areEqual('[ "1. Existing Error", "2. ' + newErrorMessage + '" ]', queueJobResults.Errors__c);
    }

    @isTest
    static void itShouldBuildQueueJobFailureEmail() {
        // GIVEN some failed Queue Jobs
        List<Queue_Job__c> testQueueJobs = new List<Queue_Job__c>();
        for (Integer i = 0; i < 4; i++) {
            testQueueJobs.add(
                new Queue_Job__c(
                    Channel__c = 'Event',
                    Job_Type__c = 'Example',
                    Failure_Count__c = 1,
                    Last_Error__c = 'Existing Error'
                )
            );
        }
        insert testQueueJobs;

        // Run as the current user to avoid MIXED_DML errors
        System.runAs(new User(Id = UserInfo.getUserId())) {
            // AND there is at least one user added to the Admin_Alert_Recipients group
            TestUtilities.addUsersToGroup(
                new List<User>{ new User(Id = UserInfo.getUserId()) },
                'Admin_Alert_Recipients'
            );
        }

        System.Test.startTest();

        // WHEN the buildAndSendFailedJobsEmail method is called
        QueueJobUtilities.buildAndSendFailedJobsEmail(testQueueJobs);

        System.Test.stopTest();

        // THEN an Email should have been submitted
        Assert.areEqual('Queue Job Batch Has Job Failures', QueueJobUtilities.failedJobsEmail.subject);

        for (Queue_Job__c currentJob : testQueueJobs) {
            // AND the email submitted should include the Jobs Id
            Assert.isTrue(QueueJobUtilities.failedJobsEmail.htmlBody.contains(currentJob.Id));
        }
    }
}
