/**
 * Processor for updating a Students personal data, including Addresses
 */
public class EventUserAccountUpdatedProcessor extends BaseProcessor {
    @testVisible
    private static final string USER_ID_ERROR = 'One or more of the given User Ids either do not exist in Salesforce or are linked to different Accounts.';

    @testVisible
    private static final string DUPLICATE_ADDRESS = 'Duplicate Address found in event. Please resolve';

    @testVisible
    private static final string INVALID_COUNTRY = 'Invalid country. Please resolve';

    @testVisible
    private static final string GENERIC_FAILURE = 'One or more jobs failed to process resulting in all jobs in the same batch failing. Please resolve.';

    private Map<Id, Queue_Job__c> queueJobIdToQueueJob = new Map<Id, Queue_Job__c>();
    private Map<String, AccountUpdatedJobDetails> userIdsToJobDetails = new Map<String, AccountUpdatedJobDetails>();

    // Maps containing records to be inserted or updated
    private Map<Id, Account> queueJobIdToAccountToInsert = new Map<Id, Account>();
    private Map<Id, List<Address__c>> queueJobIdToAddressesToUpsert = new Map<Id, List<Address__c>>();
    private Map<Id, List<Institute_Body__c>> queueJobIdToQualificationToUpsert = new Map<Id, List<Institute_Body__c>>();

    private Integer failedDMLCount = 0;
    private static final Integer RETRY_DML_COUNT_LIMIT = 1;

    private static final Set<String> MY_ADDRESS_TYPES = new Set<String>{ 'Mailing', 'Billing', 'Home', 'Term time' };

    /**
     * Update the Accounts linked to the given Queue Jobs with new personal information, including Addresses
     * @param  queueJobs jobs to be processed
     */
    public void processImpl(List<Queue_Job__c> queueJobs) {
        // Prevent events being fired off the back of this transaction
        StreamingService.preventStream = true;

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
        Map<Queue_Job__c, AccountUpdatedJobDetails> jobsToSchema = new Map<Queue_Job__c, AccountUpdatedJobDetails>();
        Set<String> allUserIds = new Set<String>();

        // Loop over all queue jobs, deserialize them and extract any details that are required for later processing
        for (Queue_Job__c queueJob : queueJobs) {
            UserAccountUpdatedSchema event = (UserAccountUpdatedSchema) JSON.deserialize(
                queueJob.Job_Content__c,
                UserAccountUpdatedSchema.class
            );

            AccountUpdatedJobDetails jobDetails = new AccountUpdatedJobDetails();
            jobDetails.schema = event;
            jobDetails.queueJob = queueJob;

            // List together all User Ids associated with this job and store in a custom class for later use
            for (String currentUserId : event.userIds) {
                allUserIds.add(currentUserId);
                jobDetails.userIds.add(currentUserId);
            }

            jobsToSchema.put(queueJob, jobDetails);
        }

        Map<String, Hub_Account__c> userIdToHubAccount = new Map<String, Hub_Account__c>();
        Map<String, Account> accountIdToAccount = new Map<String, Account>();
        // Query out any Accounts which are linked to Hub Accounts identified on the Queue Jobs
        for (Account currentAccount : [
            SELECT
                Id,
                (SELECT Id, Student__c, Auth0_Id__c FROM Hub_Accounts__r WHERE Auth0_Id__c IN :allUserIds),
                (SELECT Id, Institute_Body__c, Institute_Number__c FROM Institute_Bodies__r),
                (
                    SELECT Id, Type__c
                    FROM Addresses__r
                    WHERE Type__c IN :MY_ADDRESS_TYPES
                    ORDER BY Active__c DESC, LastModifiedDate DESC
                )
            FROM Account
            WHERE Id IN (SELECT Student__c FROM Hub_Account__c WHERE Auth0_Id__c IN :allUserIds)
        ]) {
            accountIdToAccount.put(currentAccount.Id, currentAccount);

            for (Hub_Account__c currentHubAccount : currentAccount.Hub_Accounts__r) {
                userIdToHubAccount.put(currentHubAccount.Auth0_Id__c, currentHubAccount);
            }
        }

        // Loop over the Queue Jobs again, ensure that User Ids are valid and further process data into a more useful format
        for (Queue_Job__c currentQueueJob : jobsToSchema.keySet()) {
            Boolean issueWithUserIdsFound = false;
            AccountUpdatedJobDetails currentJobDetails = jobsToSchema.get(currentQueueJob);

            String accountId;
            for (String currentUserId : currentJobDetails.userIds) {
                Hub_Account__c relatedHubAccount = userIdToHubAccount.get(currentUserId);

                // If we either have been given a User Id that does not exist in Salesforce, or if any of the User Ids link to an Account different to the previous
                if (relatedHubAccount == null || (accountId != null && relatedHubAccount.Student__c != accountId)) {
                    issueWithUserIdsFound = true;
                    break;
                }

                accountId = userIdToHubAccount.get(currentUserId).Student__c;
            }

            if (issueWithUserIdsFound) {
                failedJobs.put(currentQueueJob, USER_ID_ERROR);
                continue;
            }

            // Once we are certain that we have the Account Id relating to this Queue Job, retrieve the Account including all details and set it on the class
            currentJobDetails.account = accountIdToAccount.get(accountId);

            // Deduplicate any jobs which have updates for the same Account and add the final job to be processed to a Map for later usage
            Queue_Job__c duplicate = userIdsToJobDetails.get(accountId)?.queueJob;
            if (duplicate != null) {
                if (duplicate.Event_Time__c > currentQueueJob.Event_Time__c) {
                    // if job in map is newer, set current job as successful and skip
                    successfulJobs.add(currentQueueJob);
                    continue;
                }
                // if current job is newer, set job in map as successful
                successfulJobs.add(duplicate);
            }
            userIdsToJobDetails.put(accountId, currentJobDetails);
            queueJobIdToQueueJob.put(currentQueueJob.Id, currentQueueJob);
        }
    }

    /**
     * Create or Update records using data structures created earlier, run validation on Addresses and create additional
     * data structures containing only records ready for DML actions
     */
    void processSchemas() {
        // Extract all Country ISO codes that are to be processed in this event
        Set<String> countryISOsToQuery = new Set<String>();
        for (String currentUserId : userIdsToJobDetails.keySet()) {
            UserAccountUpdatedSchema currentSchema = userIdsToJobDetails.get(currentUserId).schema;

            if (currentSchema.addresses != null) {
                for (UserAccountUpdatedSchema.Address currentAddress : currentSchema.addresses) {
                    countryISOsToQuery.add(currentAddress.country);
                }
            }
        }

        // Query out the Country List records in Salesforce that match the Country ISO codes provided in the event
        Map<String, Id> isoCodeToCountryId = new Map<String, Id>();
        for (country_list__c currentCountry : [
            SELECT Id, country_code_2__c
            FROM country_list__c
            WHERE country_code_2__c IN :countryISOsToQuery
        ]) {
            isoCodeToCountryId.put(currentCountry.country_code_2__c, currentCountry.Id);
        }

        for (String currentUserId : userIdsToJobDetails.keySet()) {
            Boolean jobFailed = false;
            AccountUpdatedJobDetails currentJobDetails = userIdsToJobDetails.get(currentUserId);
            UserAccountUpdatedSchema schema = currentJobDetails.schema;
            UserAccountUpdatedSchema.PersonalInfo personalInfo = schema.personalInfo;

            Queue_Job__c queueJob = currentJobDetails.queueJob;
            // Update the Account information
            Account accountToUpdate = new Account(
                // Personal Details
                Id = currentJobDetails.account.Id,
                Salutation = personalInfo.title,
                FirstName = personalInfo.firstName,
                LastName = personalInfo.lastName,
                Middle_Name__pc = personalInfo.middleName,
                Preferred_First_Name__pc = personalInfo.preferredName,
                PersonPronouns = personalInfo.preferredPronouns,
                PersonBirthdate = personalInfo.dateOfBirth,
                // Conditionally set the Preferred Phone field if a Mobile Phone number was provided
                PersonMobilePhone = personalInfo.mobilePhone,
                Work_Phone__pc = personalInfo.workPhone,
                PersonHomePhone = personalInfo.homePhone,
                PersonOtherPhone = '',
                // Emergency Contact
                Emergency_Contact_Relationship__pc = schema.emergencyContact.relationship,
                Emergency_Contact_First_Name__pc = schema.emergencyContact.firstName,
                Emergency_Contact_Last_Name__pc = schema.emergencyContact.lastName,
                Emergency_Contact_Email__pc = schema.emergencyContact.emailAddress,
                Emergency_Contact_Mobile__pc = schema.emergencyContact.mobilePhone,
                // Marketing Preferences
                Post_Opt_In__pc = schema.marketingPreferences.contains('Post'),
                Email_Opt_In__pc = schema.marketingPreferences.contains('Email'),
                Phone_Opt_In__pc = schema.marketingPreferences.contains('Phone'),
                Social_Media_Opt_In__pc = schema.marketingPreferences.contains('Social media'),
                SMS_Opt_In__pc = schema.marketingPreferences.contains('SMS'),
                App_Notifications_Opt_In__pc = schema.marketingPreferences.contains('Push notification')
            );

            if (!String.isBlank(accountToUpdate.PersonMobilePhone)) {
                accountToUpdate.Preferred_Phone__pc = 'Mobile';
            } else if (!String.isBlank(accountToUpdate.PersonHomePhone)) {
                accountToUpdate.Preferred_Phone__pc = 'Home';
            } else if (!String.isBlank(accountToUpdate.Work_Phone__pc)) {
                accountToUpdate.Preferred_Phone__pc = 'Work';
            } else {
                accountToUpdate.Preferred_Phone__pc = '';
            }

            Map<String, Id> qualificationToId = new Map<String, Id>();
            for (Institute_Body__c body : currentJobDetails.account.Institute_Bodies__r) {
                qualificationToId.put(body.Institute_Body__c, body.Id);
            }

            Map<Id, List<Address__c>> queueJobIdToAddressesPendingUpsert = new Map<Id, List<Address__c>>();

            if (schema.addresses != null) {
                Map<String, Address__c> typeToUpdatedAddress = new Map<String, Address__c>();

                for (UserAccountUpdatedSchema.Address currentAddress : schema.addresses) {
                    // Fail the job if the country provided cannot be found in Salesforce
                    if (!isoCodeToCountryId.containsKey(currentAddress.country) && !String.isBlank(currentAddress.country)) {
                        failedJobs.put(queueJob, INVALID_COUNTRY);
                        jobFailed = true;
                        break;
                    }

                    // If all validation has passed, build up the Address to insert/update
                    Address__c addressWithNewDetails = new Address__c(
                        Student__c = currentJobDetails.account.Id,
                        Active__c = true,
                        Type__c = (currentAddress.type == 'Delivery' ? 'Mailing' : currentAddress.type),
                        Street_1__c = currentAddress.line1,
                        Street_2__c = currentAddress.line2,
                        Street_3__c = currentAddress.line3,
                        City__c = currentAddress.town,
                        County_State__c = currentAddress.county,
                        Zip_Postal_Code__c = currentAddress.postalCode,
                        Record_Source__c = 'Hub'
                    );

                    if (!String.isBlank(currentAddress.country)) {
                        addressWithNewDetails.Lookup_Country__c = isoCodeToCountryId.get(currentAddress.country);
                    }

                    // Ensure that all checkboxes are updated according to their Type
                    addressWithNewDetails.Permanent_Home__c = currentAddress.type == 'Home';
                    addressWithNewDetails.Primary_Billing__c = currentAddress.type == 'Billing';
                    addressWithNewDetails.Primary_Delivery__c = currentAddress.type == 'Delivery';
                    addressWithNewDetails.Term_Time__c = currentAddress.type == 'Term Time';

                    // Fail the job if there are duplicate addresses found within the Event
                    if (typeToUpdatedAddress.containsKey(currentAddress.type)) {
                        failedJobs.put(queueJob, DUPLICATE_ADDRESS);
                        jobFailed = true;
                        break;
                    }
                    typeToUpdatedAddress.put(addressWithNewDetails.Type__c, addressWithNewDetails);
                }

                if (jobFailed) {
                    continue;
                }

                Set<String> foundTypes = new Set<String>();
                // Check for existing addresses to update
                for (Address__c currentAddress : currentJobDetails.account.Addresses__r) {
                    if (foundTypes.contains(currentAddress.Type__c)) {
                        continue;
                    }

                    Address__c addressToUpdate;

                    // If we already have an Address of this type against the Account we should update it, so provide the Id for the upsert
                    if (typeToUpdatedAddress.containsKey(currentAddress.Type__c)) {
                        addressToUpdate = typeToUpdatedAddress.remove(currentAddress.Type__c);
                        addressToUpdate.Id = currentAddress.Id;
                        foundTypes.add(currentAddress.Type__c);
                    } else {
                        // If the address type isn't in the event and is a type my supports, deactivate
                        currentAddress.Active__c = false;
                        addressToUpdate = currentAddress;
                    }

                    // Map together the Addresses by their Queue Job
                    if (queueJobIdToAddressesPendingUpsert.containsKey(queueJob.Id)) {
                        queueJobIdToAddressesPendingUpsert.get(queueJob.Id).add(addressToUpdate);
                        continue;
                    }

                    queueJobIdToAddressesPendingUpsert.put(queueJob.Id, new List<Address__c>{ addressToUpdate });
                }

                // Any remaining addresses are new and should be created
                for (Address__c currentAddress : typeToUpdatedAddress.values()) {
                    if (queueJobIdToAddressesPendingUpsert.containsKey(queueJob.Id)) {
                        queueJobIdToAddressesPendingUpsert.get(queueJob.Id).add(currentAddress);
                        continue;
                    }

                    queueJobIdToAddressesPendingUpsert.put(queueJob.Id, new List<Address__c>{ currentAddress });
                }
            }

            Map<Id, List<Institute_Body__c>> queueJobToQualificationPendingUpsert = new Map<Id, List<Institute_Body__c>>();
            Set<String> qualifications = new Set<String>();

            if (schema.professionalQualifications != null) {
                for (UserAccountUpdatedSchema.Qualification qualification : schema.professionalQualifications) {
                    if (String.isEmpty(qualification.reference)) {
                        continue;
                    }

                    Institute_Body__c body = new Institute_Body__c(
                        Student__c = currentJobDetails.account.Id,
                        Institute_Body__c = qualification.awardingBody,
                        Institute_Number__c = qualification.reference
                    );

                    if (qualificationToId.containsKey(qualification.awardingBody)) {
                        body.Id = qualificationToId.get(qualification.awardingBody);
                    }

                    List<Institute_Body__c> bodyList = new List<Institute_Body__c>();
                    if (queueJobToQualificationPendingUpsert.containsKey(queueJob.Id)) {
                        bodyList = queueJobToQualificationPendingUpsert.get(queueJob.Id);
                    }

                    bodyList.add(body);
                    qualifications.add(body.Institute_Body__c);
                    queueJobToQualificationPendingUpsert.put(queueJob.Id, bodyList);
                }
            }

            // If the job has been marked as failed, continue the loop before adding the Accounts and Addresses to the DML maps
            if (jobFailed) {
                continue;
            }

            queueJobIdToAccountToInsert.put(queueJob.Id, accountToUpdate);
            queueJobIdToAddressesToUpsert.putAll(queueJobIdToAddressesPendingUpsert);
            queueJobIdToQualificationToUpsert.putAll(queueJobToQualificationPendingUpsert);
        }
    }

    /**
     * Process records created in earlier methods by Inserting or Updated records depending, allowing for X amount of retries, removing
     * any Queue Jobs which were identified as will fail before each retry
     */
    void processRecordDML() {
        Map<Id, List<Database.Error>> jobsToFailToErrors = new Map<Id, List<Database.Error>>();
        Set<Id> successfullyProcessedJobIds = new Set<Id>();

        // Bypass any Account duplicate rules
        Database.DMLOptions dml = new Database.DMLOptions();
        dml.DuplicateRuleHeader.allowSave = true;
        dml.optAllOrNone = false;

        Savepoint savePoint = Database.setSavepoint();
        List<Database.SaveResult> accountUpdateResults = Database.Update(queueJobIdToAccountToInsert.values(), dml);
        for (Integer i = 0; i < accountUpdateResults.size(); i++) {
            Database.SaveResult result = accountUpdateResults[i];
            Id relatedJobId = new List<Id>(queueJobIdToAccountToInsert.keySet())[i];

            if (!result.isSuccess()) {
                jobsToFailToErrors.put(relatedJobId, result.getErrors());
            } else {
                successfullyProcessedJobIds.add(relatedJobId);
            }
        }

        // Retrieve a list of the Addresses and Qualifications that should be upserted as their Account Updates passed
        Map<Address__c, Id> addressesToUpsertToQueueJobId = new Map<Address__c, Id>();
        Map<Institute_Body__c, Id> qualificationsToUpsertToQueueJobId = new Map<Institute_Body__c, Id>();

        for (Id currentQueueJobId : queueJobIdToAccountToInsert.keySet()) {
            if (queueJobIdToAddressesToUpsert.containsKey(currentQueueJobId)) {
                for (Address__c addressToUpsert : queueJobIdToAddressesToUpsert.get(currentQueueJobId)) {
                    addressesToUpsertToQueueJobId.put(addressToUpsert, currentQueueJobId);
                }
            }

            if (queueJobIdToQualificationToUpsert.containsKey(currentQueueJobId)) {
                for (Institute_Body__c body : queueJobIdToQualificationToUpsert.get(currentQueueJobId)) {
                    qualificationsToUpsertToQueueJobId.put(body, currentQueueJobId);
                }
            }
        }

        List<Database.upsertResult> addressUpsertResults = Database.Upsert(
            new List<Address__c>(addressesToUpsertToQueueJobId.keySet()),
            false
        );

        for (Integer i = 0; i < addressUpsertResults.size(); i++) {
            Database.upsertResult result = addressUpsertResults[i];
            Id relatedJobId = addressesToUpsertToQueueJobId.values()[i];

            if (!result.isSuccess()) {
                jobsToFailToErrors.put(relatedJobId, result.getErrors());
            }
        }

        List<Database.upsertResult> qualificationUpsertResults = Database.Upsert(
            new List<Institute_Body__c>(qualificationsToUpsertToQueueJobId.keySet()),
            false
        );

        for (Integer i = 0; i < qualificationUpsertResults.size(); i++) {
            Database.upsertResult result = qualificationUpsertResults[i];
            Id relatedJobId = qualificationsToUpsertToQueueJobId.values()[i];

            if (!result.isSuccess()) {
                jobsToFailToErrors.put(relatedJobId, result.getErrors());
            }
        }

        // If there we no failures, succeed the jobs
        if (jobsToFailToErrors.isEmpty()) {
            for (Id queueJobId : successfullyProcessedJobIds) {
                successfulJobs.add(queueJobIdToQueueJob.get(queueJobId));
            }
            return;
        }

        // Otherwise, if there were any failures we must rollback all DML as to not end up with Account Updates persisting but Address updates failing.
        // To do so, work out which we know will be successful, and re-processes only those
        Database.rollback(savePoint);

        // Loop over any jobs containing DML that failed, fail the job and remove any records associated with the job from our Insert/Update maps
        // so that they are not re-processed
        for (Id queueJobId : jobsToFailToErrors.keySet()) {
            processDMLErrors(queueJobIdToQueueJob.get(queueJobId), jobsToFailToErrors.get(queueJobId));
            queueJobIdToAccountToInsert.remove(queueJobId);
            queueJobIdToAddressesToUpsert.remove(queueJobId);
            queueJobIdToQualificationToUpsert.remove(queueJobId);
        }

        // If we have reached or surpassed the threshold to retry the jobs which succeeded on the previous DML run attempt, fail all remaining jobs
        if (RETRY_DML_COUNT_LIMIT <= failedDMLCount) {
            // If the retry also fails, fail all remaining jobs
            for (Id remainingJobId : queueJobIdToAccountToInsert.keySet()) {
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
    private class AccountUpdatedJobDetails {
        private UserAccountUpdatedSchema schema;
        private List<String> userIds = new List<String>();
        private Queue_Job__c queueJob;
        private Account account;
    }
}
