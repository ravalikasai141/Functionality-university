/**
 * Processor for creating a Case data
 */
public class EventCaseProcessor extends BaseProcessor {
    @testVisible
    private static final string AUTH0_ID_ERROR = 'auth0Id does not exist in Salesforce.';

    @testVisible
    private static final string GENERIC_FAILURE = 'One or more jobs failed to process resulting in all jobs in the same batch failing. Please resolve.';

    private Map<Id, Queue_Job__c> queueJobIdToQueueJob = new Map<Id, Queue_Job__c>();
    private Map<String, CaseJobDetails> auth0IdsToJobDetails = new Map<String, CaseJobDetails>();
    private Map<String, Product2> identifierToProduct = new Map<String, Product2>();
    private Set<String> allProductIds = new Set<String>();
    private Set<String> allInstanceIds = new Set<String>();
    private Map<String, Hub_Account__c> auth0IdToHubAccount = new Map<String, Hub_Account__c>();
    private Map<String, Account> accountIdToAccount = new Map<String, Account>();
    private Set<String> allAuth0Ids = new Set<String>();

    // Maps containing records to be inserted or updated
    private Map<Id, Case> queueJobIdToCaseToInsert = new Map<Id, Case>();

    private Integer failedDMLCount = 0;
    private static final Integer RETRY_DML_COUNT_LIMIT = 1;

    /**
     * Update the Accounts linked to the given Queue Jobs with new personal information, including Addresses
     * @param  queueJobs jobs to be processed
     */
    public void processImpl(List<Queue_Job__c> queueJobs) {
        // Allow user case updated events
        StreamingService.allowedEvents.add('queryFormUpdated');

        // Extract data from Event, run initial validation, deduplicate and create more accessible data structures
        deserializeEvents(queueJobs);

        // Using data extracted above, create Account update and Address upsert records
        processSchemas();

        // Attempt to save the DML, removing invalid jobs and attempting to re-run *failedDMLCount* amount of times if there are any failures
        processRecordDML();
    }

    /**
     * Deserialize events on the given Queue Jobs into Schemas, validate for early issues and map into data structures
     * @param  queueJobs Queue Jobs being processed
     */
    void deserializeEvents(List<Queue_Job__c> queueJobs) {
        Map<Queue_Job__c, CaseJobDetails> jobsToSchema = new Map<Queue_Job__c, CaseJobDetails>();

        // Loop over all queue jobs, deserialize them and extract any details that are required for later processing
        for (Queue_Job__c queueJob : queueJobs) {
            CaseSchema event = (CaseSchema) JSON.deserialize(queueJob.Job_Content__c, CaseSchema.class);

            // Identify any required fields which are blank so we can fail the job
            List<String> requiredFieldErrors = new List<String>();
            checkRequiredFieldErrors(event, requiredFieldErrors);

            if (!requiredFieldErrors.isEmpty()) {
                failedJobs.put(
                    queueJob,
                    'Required value(s) ' + String.join(requiredFieldErrors, ', ') + ' are null in event payload'
                );
                continue;
            }

            // remove prefix for PCV2 instances
            if (event.productId != null && event.productId != '') {
                allProductIds.add(event.productId);
            }
            if (event.instanceId != null && event.instanceId != '') {
                String instanceId = event.instanceId?.remove('PCV2-');
                allInstanceIds.add(instanceId);
            }

            CaseJobDetails jobDetails = new CaseJobDetails();
            jobDetails.schema = event;
            jobDetails.queueJob = queueJob;
            jobDetails.auth0Id = event.auth0Id;
            allAuth0Ids.add(event.auth0Id);

            jobsToSchema.put(queueJob, jobDetails);
        }

        if (!allProductIds.isEmpty() || !allInstanceIds.isEmpty()) {
            retrieveProducts();
        }
        retrieveAccounts();

        // Loop over the Queue Jobs again, ensure that User Ids are valid and further process data into a more useful format
        for (Queue_Job__c currentQueueJob : jobsToSchema.keySet()) {
            CaseJobDetails currentJobDetails = jobsToSchema.get(currentQueueJob);

            Hub_Account__c relatedHubAccount = auth0IdToHubAccount.get(currentJobDetails.auth0Id);

            // If we have been given a auth0Id that does not exist in Salesforce
            if (relatedHubAccount == null) {
                failedJobs.put(currentQueueJob, AUTH0_ID_ERROR);
                continue;
            }

            String accountId = auth0IdToHubAccount.get(currentJobDetails.auth0Id).Student__c;

            // Once we are certain that we have the Account Id relating to this Queue Job, retrieve the Account including all details and set it on the class
            currentJobDetails.account = accountIdToAccount.get(accountId);

            // Deduplicate any jobs which have updates for the same Account and add the final job to be processed to a Map for later usage
            Queue_Job__c duplicate = auth0IdsToJobDetails.get(accountId)?.queueJob;
            if (duplicate != null) {
                if (duplicate.Event_Time__c > currentQueueJob.Event_Time__c) {
                    // if job in map is newer, set current job as successful and skip
                    successfulJobs.add(currentQueueJob);
                    continue;
                }
                // if current job is newer, set job in map as successful
                successfulJobs.add(duplicate);
            }
            auth0IdsToJobDetails.put(accountId, currentJobDetails);
            queueJobIdToQueueJob.put(currentQueueJob.Id, currentQueueJob);
        }
    }

    /**
     * Checks for required field errors in a CaseSchema event object and populates the provided requiredFieldErrors list with any errors found.
     * The method creates a map of required field names and their corresponding values from the CaseSchema event object.
     */
    private void checkRequiredFieldErrors(CaseSchema event, List<String> requiredFieldErrors) {
        Map<String, String> requiredFieldMap = new Map<String, String>{
            'Auth0Id' => event?.auth0Id,
            'Query Id' => event?.queryId,
            'Query Type' => event?.queryType,
            'Query Subtype' => event?.subQueryType
        };

        for (String potentialError : requiredFieldMap.keySet()) {
            if (String.isBlank(requiredFieldMap.get(potentialError))) {
                requiredFieldErrors.add(potentialError);
            }
        }
    }

    /**
     * Builds a SOQL query for retrieving Product2 records based on specified criteria.
     *
     * @return The constructed SOQL query as a String, or null if both allInstanceIds and allProductIds are empty.
     */
    private String buildProductQuery() {
        String productQuery = 'SELECT Id, Instance_Id__c, BNR_Program_Code__c FROM Product2';
        String productCondition = '';
        if (!allInstanceIds.isEmpty() || !allProductIds.isEmpty()) {
            productQuery += ' WHERE ';

            if (!allInstanceIds.isEmpty()) {
                productCondition += ' Instance_Id__c IN :allInstanceIds';
            }

            String programCodeClause = 'BNR_Program_Code__c IN :allProductIds';
            if (!allProductIds.isEmpty() && !allInstanceIds.isEmpty()) {
                productCondition += ' AND ' + programCodeClause;
            } else if (!allProductIds.isEmpty()) {
                productCondition += ' ' + programCodeClause;
            }

            return productQuery += productCondition;
        }
        return null;
    }

    /**
     * Retrieves products from the database and populates the identifierToProduct map.
     * The method builds a product query, executes it, and iterates through the resulting list
     */
    private void retrieveProducts() {
        String productQuery = buildProductQuery();
        List<Product2> productList = Database.query(productQuery);
        for (Product2 product : productList) {
            if (product.Instance_Id__c != null) {
                identifierToProduct.put(product.Instance_Id__c, product);
            }

            if (product.BNR_Program_Code__c != null) {
                identifierToProduct.put(product.BNR_Program_Code__c, product);
            }
        }
    }

    /**
     * Retrieves accounts from the database and populates the accountIdToAccount and auth0IdToHubAccount maps.
     * The method queries for accounts that are linked to Hub Accounts, identified by the provided Auth0 IDs.
     */
    private void retrieveAccounts() {
        // Query out any Accounts which are linked to Hub Accounts identified on the Queue Jobs
        for (Account currentAccount : [
            SELECT
                Id,
                PersonContactId,
                (SELECT Id, Student__c, Auth0_Id__c FROM Hub_Accounts__r WHERE Auth0_Id__c IN :allAuth0Ids)
            FROM Account
            WHERE Id IN (SELECT Student__c FROM Hub_Account__c WHERE Auth0_Id__c IN :allAuth0Ids)
        ]) {
            accountIdToAccount.put(currentAccount.Id, currentAccount);

            for (Hub_Account__c currentHubAccount : currentAccount.Hub_Accounts__r) {
                auth0IdToHubAccount.put(currentHubAccount.Auth0_Id__c, currentHubAccount);
            }
        }
    }

    /**
     * Create or Update records using data structures created earlier, run validation and create additional
     * data structures containing only records ready for DML actions
     */
    void processSchemas() {
        // Assign case using active case assignment rule
        AssignmentRule aRule = [
            SELECT id
            FROM AssignmentRule
            WHERE SobjectType = 'Case' AND Active = TRUE
        ];

        //Creating the DMLOptions for "Assign using active assignment rules" checkbox
        Database.DMLOptions dmlOpts = new Database.DMLOptions();
        dmlOpts.assignmentRuleHeader.assignmentRuleId = aRule.id;

        for (String currentAuth0Id : auth0IdsToJobDetails.keySet()) {
            Boolean jobFailed = false;
            CaseJobDetails currentJobDetails = auth0IdsToJobDetails.get(currentAuth0Id);
            CaseSchema caseSchema = currentJobDetails.schema;

            Queue_Job__c queueJob = currentJobDetails.queueJob;
            String productId = caseSchema.productId;
            String trimmedInstanceId = caseSchema.instanceId?.remove('PCV2-');

            // Insert the Case information
            Case caseToUpdate = new Case(
                Origin = 'Web',
                RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName()
                    .get('Student_Query')
                    .getRecordTypeId(),
                Query_Type__c = caseSchema.queryType,
                Query_Subtype__c = caseSchema.subQueryType,
                Description = caseSchema.queryDescription,
                School__c = caseSchema.school,
                ContactId = currentJobDetails.account.PersonContactId,
                Query_Id__c = caseSchema.queryId
            );

            if (
                (productId != '' && identifierToProduct.containsKey(productId)) ||
                (trimmedInstanceId != '' && identifierToProduct.containsKey(trimmedInstanceId))
            ) {
                Product2 product = productId != '' && identifierToProduct.containsKey(productId)
                    ? identifierToProduct.get(productId)
                    : identifierToProduct.get(trimmedInstanceId);
                caseToUpdate.productId = product.id;
            }

            caseToUpdate.setOptions(dmlOpts);

            // If the job has been marked as failed, continue the loop to the DML maps
            if (jobFailed) {
                continue;
            }

            queueJobIdToCaseToInsert.put(queueJob.Id, caseToUpdate);
        }
    }

    /**
     * Process records created in earlier methods by Inserting or Updated records depending, allowing for X amount of retries, removing
     * any Queue Jobs which were identified as will fail before each retry
     */
    void processRecordDML() {
        Map<Id, List<Database.Error>> jobsToFailToErrors = new Map<Id, List<Database.Error>>();
        Set<Id> successfullyProcessedJobIds = new Set<Id>();
        Savepoint savePoint = Database.setSavepoint();

        List<Database.UpsertResult> caseResults = Database.upsert(
            queueJobIdToCaseToInsert.values(),
            Case.Query_Id__c,
            false
        );
        for (Integer i = 0; i < caseResults.size(); i++) {
            Database.upsertResult result = caseResults[i];
            Id relatedJobId = new List<Id>(queueJobIdToCaseToInsert.keySet())[i];

            if (!result.isSuccess()) {
                jobsToFailToErrors.put(relatedJobId, result.getErrors());
            } else {
                successfullyProcessedJobIds.add(relatedJobId);
            }
        }

        // If there we no failures, succeed the jobs
        if (jobsToFailToErrors.isEmpty()) {
            for (Id queueJobId : successfullyProcessedJobIds) {
                successfulJobs.add(queueJobIdToQueueJob.get(queueJobId));
            }
            return;
        }

        // Otherwise, if there were any failures we must rollback all DML as to not end up with Case Updates persisting.
        // To do so, work out which we know will be successful, and re-processes only those
        Database.rollback(savePoint);

        // Loop over any jobs containing DML that failed, fail the job and remove any records associated with the job from our Insert/Update maps
        // so that they are not re-processed
        for (Id queueJobId : jobsToFailToErrors.keySet()) {
            processDMLErrors(queueJobIdToQueueJob.get(queueJobId), jobsToFailToErrors.get(queueJobId));
            queueJobIdToCaseToInsert.remove(queueJobId);
        }

        // If we have reached or surpassed the threshold to retry the jobs which succeeded on the previous DML run attempt, fail all remaining jobs
        if (RETRY_DML_COUNT_LIMIT <= failedDMLCount) {
            // If the retry also fails, fail all remaining jobs
            for (Id remainingJobId : queueJobIdToCaseToInsert.keySet()) {
                failedJobs.put(queueJobIdToQueueJob.get(remainingJobId), GENERIC_FAILURE);
            }

            return;
        }
        failedDMLCount++;

        // Otherwise if we are still able to retry the DML, do so
        processRecordDML();
    }

    /**
     * Wrapper class to store different data pertaining to a single Queue Job
     */
    private class CaseJobDetails {
        private CaseSchema schema;
        private String auth0Id;
        private Queue_Job__c queueJob;
        private Account account;
    }
}
