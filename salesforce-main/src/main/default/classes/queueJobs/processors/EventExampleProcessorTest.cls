@isTest
private class EventExampleProcessorTest {
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
    public static void itShouldUpdateQueueJobErrorMessages() {
        Map<String, String> jobActionToExpectedError = new Map<String, String>{
            'Fail' => 'failed',
            'Pass' => null,
            'Retry' => 'retry',
            'Other' => 'Invalid eventAction'
        };

        // GIVEN some Queue Jobs, one for each different Event Action type
        Map<String, Queue_Job__c> jobActionToQueueJobs = new Map<String, Queue_Job__c>();
        for (String currentActionType : jobActionToExpectedError.keySet()) {
            jobActionToQueueJobs.put(
                currentActionType,
                new Queue_Job__c(
                    Status__c = 'Processing',
                    Job_Content__c = '{"eventAction": "' + currentActionType + '"}'
                )
            );
        }

        EventExampleProcessor processor = new EventExampleProcessor();

        System.Test.startTest();

        // WHEN the processors processImpl method is called
        processor.processImpl(jobActionToQueueJobs.values());

        System.Test.stopTest();

        // THEN each of the Queue Jobs should have been added a return list
        Assert.areEqual(2, processor.failedJobs.size());
        Assert.areEqual(1, processor.retryJobs.size());
        Assert.areEqual(1, processor.successfulJobs.size());

        for (String currentAction : jobActionToQueueJobs.keySet()) {
            Queue_Job__c currentJob = jobActionToQueueJobs.get(currentAction);
            String expectedError = jobActionToExpectedError.get(currentAction);

            // AND each of the jobs oTher than for the "Pass" action should have an error message linked to it
            switch on currentAction {
                when 'Pass' {
                    Assert.isTrue(processor.successfulJobs.contains(currentJob));
                }
                when 'Retry' {
                    Assert.isTrue(processor.retryJobs.containsKey(currentJob));
                    Assert.areEqual(expectedError, processor.retryJobs.get(currentJob));
                }
                when 'Fail', 'Other' {
                    Assert.isTrue(processor.failedJobs.containsKey(currentJob));
                    Assert.areEqual(expectedError, processor.failedJobs.get(currentJob));
                }
            }
        }
    }
}
