/**
 * Utility method for handling queue job data
 */
public class QueueJobUtilities {
    @testVisible
    private static Messaging.SingleEmailMessage failedJobsEmail;

    /**
     *  Takes a Queue Job that should have a new error message set against it, updates the "Errors__c" field
     *  to include the new error in its list of errors and then sets the "Last_Error__c" field with the latest error
     *
     *  @param  job  The Queue Job that should have its error updated
     *  @param  error  The new error to set against the Queue Job
     *
     *  @return  The Queue Job with its error fields updated
     */
    public static Queue_Job__c updateErrorMessages(Queue_Job__c job, String error) {
        // Parse any existing error messages into a list of strings
        List<String> errors = new List<String>();
        if (!String.isBlank(job.Errors__c)) {
            errors = (List<String>) JSON.deserialize(job.Errors__c, List<String>.class);
        }

        // Add an additional error to the list, including a delimiter if this is not the only error
        errors.add((job.Failure_Count__c == null ? 1 : job.Failure_Count__c + 1) + '. ' + error);

        job.Last_Error__c = error.abbreviate(Queue_Job__c.Last_Error__c.getDescribe().getLength());
        job.Errors__c = JSON.serializePretty(errors);
        return job;
    }

    /**
     *  Builds up an email of Queue Jobs that have failed to process using the provided list of
     *  Queue Job records and submits it to the members of the "Admin Alert Recipient" group
     *
     *  @param  failedJobs  The Queue Job that should be included in the Email details
     */
    @testVisible
    public static void buildAndSendFailedJobsEmail(List<Queue_Job__c> failedJobs) {
        // prettier-ignore
        String emailBody = 'The following Queue Jobs have entered a failed state:<br/><br/>' +
            '<table border="1" cellpadding="3" style="border-collapse: collapse; border-width: 2px;">' +
            '<thead><tr>' +
                '<th>Job ID</th>' +
                '<th>Channel</th>' +
                '<th>Job Type</th>' +
                '<th>Failure Count</th>' +
                '<th>Last Error</th>' +
            '</tr></thead><tbody>';
        for (Queue_Job__c job : failedJobs) {
            // prettier-ignore
            emailBody += '<tr>' +
                '<td><a href="' +  (URL.getSalesforceBaseUrl().toExternalForm() + '/' + job.Id) + '">' + job.Id + '</a></td>' +
                '<td>' + job.Channel__c + '</td>' +
                '<td>' + job.Job_Type__c + '</td>' +
                '<td>' + job.Failure_Count__c + '</td>' +
                '<td>' + job.Last_Error__c + '</td>' +
            '</tr>';
        }

        emailBody += '</tbody></table>';
        failedJobsEmail = EmailUtilities.submitSystemAlertEmail('Queue Job Batch Has Job Failures', emailBody);
    }
}
