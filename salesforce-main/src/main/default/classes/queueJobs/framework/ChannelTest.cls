@isTest
public class ChannelTest {
    public static String cronExpression = '0 0 0 31 12 ? ' + String.valueOf(Datetime.now().year() + 1);
    private static Integer testRecordCount = 4;

    @testSetup
    static void setUp() {
        List<Queue_Job__c> testQueueJobs = new List<Queue_Job__c>();
        for (Integer i = 0; i < testRecordCount; i++) {
            testQueueJobs.add(
                new Queue_Job__c(
                    Status__c = 'Pending',
                    Channel__c = 'Event',
                    Job_Type__c = 'Example',
                    Job_Content__c = '{"exampleKey' + i + '": "exampleValue' + i + '"}'
                )
            );
        }

        Database.Insert(testQueueJobs);
    }

    @isTest
    static void itShouldCreateBatchJobsOfGivenType() {
        // GIVEN some details on how a channel type should be executed
        String channelType = 'Event';
        Integer minutesBetweenRuns = 1;

        // AND there are no batch jobs scheduled
        Assert.areEqual(0, [SELECT COUNT() FROM AsyncApexJob WHERE JobType = 'BatchApex']);

        System.Test.startTest();

        // WHEN the queueChannelJobs method is called using these details
        Channel.queueChannelJobs(channelType, minutesBetweenRuns, testRecordCount, testRecordCount);

        System.Test.stopTest();

        // THEN a batch job should have been scheduled
        Assert.areEqual(1, [SELECT COUNT() FROM AsyncApexJob WHERE JobType = 'BatchApex']);
    }

    @isTest
    static void itShouldHandleAnUnexpectedErrorCreatingTheBatches() {
        // GIVEN some details on how a channel type should be executed
        String channelType = 'Event';
        Integer minutesBetweenRuns = 1;

        // AND there are no batch jobs scheduled
        Assert.areEqual(0, [SELECT COUNT() FROM AsyncApexJob WHERE JobType = 'BatchApex']);

        // AND there is at least one user added to the Admin_Alert_Recipients group
        TestUtilities.addUsersToGroup(new List<User>{ new User(Id = UserInfo.getUserId()) }, 'Admin_Alert_Recipients');

        Boolean errorCaught = false;

        System.Test.startTest();

        // WHEN the queueChannelJobs method is called with an invalid batch number to force an error
        try {
            Channel.queueChannelJobs(channelType, minutesBetweenRuns, -1, testRecordCount);
        } catch (Exception ex) {
            errorCaught = true;
        }

        System.Test.stopTest();

        // THEN an email should have been submitted
        Assert.areEqual('Failed to execute new Queue Job batch', Channel.adminAlertEmail.subject);

        // AND no error should have been caught
        Assert.isFalse(errorCaught);
    }

    @isTest
    static void itShouldStartAScheduledChannel() {
        // GIVEN there are no schedules of this type in flight
        String scheduleName = 'EventChannelTest';
        String channelName = 'EventChannel';
        Assert.areEqual(0, [SELECT COUNT() FROM CronTrigger WHERE CronJobDetail.Name = :scheduleName]);

        System.Test.startTest();

        // WHEN I call the startChannel method
        Channel.startChannel(scheduleName, channelName, cronExpression);

        System.Test.stopTest();

        // THEN the channel should successfully schedule
        Assert.areEqual(1, [SELECT COUNT() FROM CronTrigger WHERE CronJobDetail.Name = :scheduleName]);
    }

    @isTest
    static void itShouldHandlingStartingAnExistingScheduledChannel() {
        // GIVEN a scheduled channel is in flight
        String scheduleName = 'EventChannelTest';
        String channelName = 'EventChannel';
        System.schedule(scheduleName, cronExpression, new EventChannel());

        Assert.areEqual(1, [SELECT COUNT() FROM CronTrigger WHERE CronJobDetail.Name = :scheduleName]);

        Boolean errorCaught = false;

        System.Test.startTest();

        // WHEN I call the startChannel method
        try {
            Channel.startChannel(scheduleName, channelName, cronExpression);
        } catch (Exception ex) {
            errorCaught = true;
        }

        System.Test.stopTest();

        // THEN the channel should still scheduled
        Assert.areEqual(1, [SELECT COUNT() FROM CronTrigger WHERE CronJobDetail.Name = :scheduleName]);

        // AND no error should have been caught
        Assert.isFalse(errorCaught);
    }

    @isTest
    static void itShouldStopAScheduledChannel() {
        // GIVEN a scheduled channel is in flight
        String scheduleName = 'EventChannelTest';
        System.schedule(scheduleName, cronExpression, new EventChannel());

        Assert.areEqual(1, [SELECT COUNT() FROM CronTrigger WHERE CronJobDetail.Name = :scheduleName]);

        System.Test.startTest();

        // WHEN I call the stopChannel method
        Channel.stopChannel(scheduleName);

        System.Test.stopTest();

        // THEN the scheduled job should have been canceled
        Assert.areEqual(0, [SELECT COUNT() FROM CronTrigger WHERE CronJobDetail.Name = :scheduleName]);
    }

    @isTest
    static void itShouldHandlingStoppingANoneExistingScheduledChannel() {
        // GIVEN there are no scheduled channels in flight
        String scheduleName = 'EventChannelTest';
        Assert.areEqual(0, [SELECT COUNT() FROM CronTrigger WHERE CronJobDetail.Name = :scheduleName]);

        Boolean errorCaught = false;

        System.Test.startTest();

        // WHEN I call the stopChannel method
        try {
            Channel.stopChannel(scheduleName);
        } catch (Exception ex) {
            errorCaught = true;
        }

        System.Test.stopTest();

        // THEN there should still be no channels in flight
        Assert.areEqual(0, [SELECT COUNT() FROM CronTrigger WHERE CronJobDetail.Name = :scheduleName]);

        // AND no error should have been caught
        Assert.isFalse(errorCaught);
    }
}
