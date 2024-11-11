/**
 *  Example Processor to prove the functionality of the Queue Job mechanism
 */
public with sharing class EventExampleProcessor extends BaseProcessor {
    /**
     * {@inheritDoc}
     */
    public void processImpl(List<Queue_Job__c> queueJobs) {
        for (Queue_Job__c queueJob : queueJobs) {
            Map<String, Object> event = (Map<String, Object>) JSON.deserializeUntyped(queueJob.Job_Content__c);
            String eventAction = (String) event.get('eventAction');

            switch on eventAction {
                when 'Fail' {
                    failedJobs.put(queueJob, 'failed');
                }
                when 'Pass' {
                    successfulJobs.add(queueJob);
                }
                when 'Retry' {
                    retryJobs.put(queueJob, 'retry');
                }
                when else {
                    failedJobs.put(queueJob, 'Invalid eventAction');
                }
            }
        }
    }
}
