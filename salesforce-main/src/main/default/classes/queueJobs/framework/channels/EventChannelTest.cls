@isTest
public class EventChannelTest {
    @isTest
    static void itShouldSuccessfullySchedule() {
        // GIVEN a time that the schedule should be run
        String cronTestExpression = '0 0 0 31 12 ? 2099';
        CronTrigger cronTriggerResults;

        Test.startTest();

        // WHEN the EventChannel is scheduled
        String jobId = System.schedule('EventChannelTest', cronTestExpression, new EventChannel());

        // Retrieve the Job details once scheduled
        cronTriggerResults = [
            SELECT Id, CronExpression, TimesTriggered, NextFireTime
            FROM CronTrigger
            WHERE id = :jobId
        ];

        Test.stopTest();

        // THEN the cron expression should match what we provided
        Assert.areEqual(cronTestExpression, cronTriggerResults.CronExpression);

        // AND it should be pending execution
        Assert.areEqual(0, cronTriggerResults.TimesTriggered);

        // AND the job should have been scheduled when we expect
        Assert.areEqual('2099-12-31 00:00:00', String.valueOf(cronTriggerResults.NextFireTime));
    }
}
