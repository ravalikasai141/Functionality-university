/**
 * The signature of a class to receive, process and return Queue Jobs for additional processing
 */
public interface Processor {
    /**
     * Receives, processes and returns lists of Queue Jobs
     *
     * @param  jobs  Queue Jobs to be processed by this processor
     *
     * @return Processed Queue Jobs with updated info (Status, Errors, Failure count etc.) and potentially
     * additional Queue Jobs to insert spawned from the processing of another Queue Job
     */
    List<Queue_Job__c> process(List<Queue_Job__c> jobs);
}
