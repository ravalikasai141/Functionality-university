/**
 * Processor for the Request for Information events
 */
public class EventRequestForInformationProcessor extends BaseProcessor {
    /**
     * Map of queue job and event that need to be processed
     */
    private Map<Queue_Job__c, RequestForInformationSchema> jobsToSchema = new Map<Queue_Job__c, RequestForInformationSchema>();

    private Id leadProspectRtId = Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName()
        .get('Prospective_Student')
        .getRecordTypeId();
    private Id leadBusinessRtId = Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName()
        .get('Business_Development')
        .getRecordTypeId();

    private Id studentAccountRT = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
        .get('Student_Account')
        .getRecordTypeId();
    private Id lockedRecType = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
        .get('Locked_Student_Account')
        .getRecordTypeId();

    private Id bdContactRT = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName()
        .get('BD_Contact')
        .getRecordTypeId();

    private User marketingCloudUser;

    private Map<EventDetail, Lead> leadsToCheck = new Map<EventDetail, Lead>();

    private Map<EventDetail, Contact> contactsToUpdate = new Map<EventDetail, Contact>();
    private Map<EventDetail, Account> accountsToUpdate = new Map<EventDetail, Account>();

    private Map<EventDetail, Lead> leadsToCreate = new Map<EventDetail, Lead>();

    private Map<String, String> requiredFields;

    /**
     * Processes the given queue jobs
     * @param  queueJobs queueJobs description
     */
    public void processImpl(List<Queue_Job__c> queueJobs) {
        // deserialize event
        deserializeEvents(queueJobs);

        marketingCloudUser = [
            SELECT Id
            FROM User
            WHERE FirstName = 'Marketing' AND LastName = 'Cloud' AND isActive = TRUE
        ];

        List<EventDetail> initEventDetail = new List<EventDetail>();
        Map<EventDetail, Account> accountsToCheck = new Map<EventDetail, Account>();
        Map<EventDetail, Contact> contactsToCheck = new Map<EventDetail, Contact>();

        for (Queue_Job__c queueJob : jobsToSchema.keySet()) {
            RequestForInformationSchema rfiSchema = jobsToSchema.get(queueJob);

            RFIReceiver.RFI rfi = new RFIReceiver.RFI();
            rfi.e_campaign = rfiSchema.analytics_campaign;
            rfi.e_source = rfiSchema.analytics_source;
            rfi.e_medium = rfiSchema.analytics_medium;
            rfi.e_email = rfiSchema.email;
            rfi.e_phone = rfiSchema.phone;
            rfi.e_title = rfiSchema.jobTitle;
            rfi.e_last_name = rfiSchema.lastName;
            rfi.GA_Gclid = rfiSchema.gaGclId;
            rfi.GA_Client_ID = rfiSchema.gaClientId;
            rfi.e_current_bpp_student = rfiSchema.currentBppStudent;
            rfi.e_programme_of_interest = rfiSchema.programmeOfInterest;
            rfi.e_opt_out = rfiSchema.optOut;
            rfi.e_first_name = rfiSchema.firstName;
            rfi.e_source_title = rfiSchema.sourceTitle;
            rfi.e_sub_source = rfiSchema.subSource;
            rfi.e_lead_source = rfiSchema.leadSource;
            rfi.e_uk_eu_student = rfiSchema.ukEuStudent;
            rfi.e_comments = rfiSchema.comments;
            rfi.RecordType = rfiSchema.recordType;
            rfi.FormName = rfiSchema.formName;
            rfi.e_company = rfiSchema.company;
            rfi.e_hashed_email = rfiSchema.hashedEmail;
            rfi.e_levy = rfiSchema.levyPayer;
            rfi.e_enquiry = rfiSchema.submitTimestamp;

            rfi = rfi.cleanUp();

            EventDetail eventDetail = new EventDetail();
            eventDetail.queueJob = queueJob;
            eventDetail.rfi = rfi;

            if (rfi.RecordType == 'Prospective Student') {
                accountsToCheck.put(eventDetail, checkAccountExists(rfi));
            } else if (rfi.RecordType == 'Business Development') {
                contactsToCheck.put(eventDetail, checkContactExists(rfi));
            } else {
                failedJobs.put(queueJob, 'RFIReceiver Error: "RecordType" not recognised');
            }
        }

        findMatchingProspectiveStudent(accountsToCheck);
        findMatchingBusinessDevelopment(contactsToCheck);
        findMatchingLeadRecords(leadsToCheck);

        processDML();
    }

    /**
     * deserializes job content and adds to lists to be processed
     * @param  queueJobs Queue Jobs being processed
     */
    public void deserializeEvents(List<Queue_Job__c> queueJobs) {
        for (Queue_Job__c queueJob : queueJobs) {
            RequestForInformationSchema event = (RequestForInformationSchema) JSON.deserialize(
                queueJob.Job_Content__c,
                RequestForInformationSchema.class
            );

            if (event.recordType == 'Prospective Student') {
                requiredFields = new Map<String, String>{ 'Last Name' => event?.lastName };
            }

            if (event.recordType == 'Business Development') {
                requiredFields = new Map<String, String>{ 'Last Name' => event?.lastName, 'Company' => event?.company };
            }

            List<String> requiredFieldErrors = new List<String>();
            for (String potentialError : requiredFields.keySet()) {
                if (String.isBlank(requiredFields.get(potentialError))) {
                    requiredFieldErrors.add(potentialError);
                }
            }

            if (!requiredFieldErrors.isEmpty()) {
                failedJobs.put(
                    queueJob,
                    'Required value(s) ' + String.join(requiredFieldErrors, ', ') + ' are null in event payload'
                );
                continue;
            }

            jobsToSchema.put(queueJob, event);
        }
    }

    private void findMatchingProspectiveStudent(Map<EventDetail, Account> accountsToCheck) {
        List<Datacloud.FindDuplicatesResult> duplicateAccountResults;

        if (!accountsToCheck.isEmpty()) {
            duplicateAccountResults = Datacloud.FindDuplicates.findDuplicates(accountsToCheck.values());
        }

        Map<Id, EventDetail> prospectAccountsToQuery = new Map<Id, EventDetail>();

        for (Integer i = 0; i < accountsToCheck.size(); i++) {
            Account accountToCheck = accountsToCheck.values()[i];
            EventDetail eventDetail = new List<EventDetail>(accountsToCheck.keySet())[i];
            Datacloud.FindDuplicatesResult duplicateAccountResult = duplicateAccountResults[i];
            handleDuplicates(accountToCheck, eventDetail, duplicateAccountResult, '001');

            if (eventDetail.recordId != null) {
                populateMap(prospectAccountsToQuery, eventDetail.recordId, eventDetail);
            } else {
                leadsToCheck.put(eventDetail, checkLeadExists(eventDetail.rfi));
            }
        }

        if (!prospectAccountsToQuery.isEmpty()) {
            for (Account foundAccount : [
                SELECT
                    Id,
                    RecordTypeId,
                    PersonContactId,
                    FirstName,
                    LastName,
                    OwnerId,
                    GDPR_Opt_In__c,
                    GDPR_Modified__c,
                    PersonHomePhone,
                    Preferred_Phone__pc,
                    Personal_Email__pc,
                    Preferred_Email__pc,
                    GA_Client_ID__pc,
                    Hashed_Email__pc,
                    PersonTitle
                FROM Account
                WHERE
                    Id = :prospectAccountsToQuery.keySet()
                    AND (RecordTypeId = :studentAccountRT
                    OR RecordTypeId = :lockedRecType)
            ]) {
                EventDetail eventDetail = prospectAccountsToQuery.get(foundAccount.Id);
                RFIReceiver.rfi rfi = eventDetail.rfi;
                DedupeHelper.updateAccountFields(
                    foundAccount,
                    rfi.e_first_name,
                    rfi.GA_Client_ID,
                    rfi.e_hashed_email,
                    rfi.e_last_name,
                    rfi.e_phone,
                    rfi.e_email,
                    rfi.e_opt_out,
                    rfi.e_title
                );
                eventDetail.submittedRFIRecord = foundAccount;
                eventDetail.personContactId = foundAccount.PersonContactId;

                accountsToUpdate.put(eventDetail, foundAccount);
            }
        }
    }

    private void findMatchingBusinessDevelopment(Map<EventDetail, Contact> contactsToCheck) {
        List<Datacloud.FindDuplicatesResult> duplicateContactResults;

        if (!contactsToCheck.isEmpty()) {
            duplicateContactResults = Datacloud.FindDuplicates.findDuplicates(contactsToCheck.values());
        }

        Map<Id, EventDetail> businessContactsToQuery = new Map<Id, EventDetail>();

        for (Integer i = 0; i < contactsToCheck.size(); i++) {
            Contact contactToCheck = contactsToCheck.values()[i];
            EventDetail eventDetail = new List<eventDetail>(contactsToCheck.keySet())[i];
            Datacloud.FindDuplicatesResult duplicateContactResult = duplicateContactResults[i];
            handleDuplicates(contactToCheck, eventDetail, duplicateContactResult, '003');

            if (eventDetail.recordId != null) {
                populateMap(businessContactsToQuery, eventDetail.recordId, eventDetail);
            } else {
                leadsToCheck.put(eventDetail, checkLeadExists(eventDetail.rfi));
            }
        }

        if (!businessContactsToQuery.isEmpty()) {
            for (Contact busContact : [
                SELECT
                    Id,
                    RecordTypeId,
                    AccountId,
                    FirstName,
                    LastName,
                    OwnerId,
                    GDPR_Opt_In__c,
                    GDPR_Modified__c,
                    Work_Phone__c,
                    Preferred_Phone__c,
                    Work_Email__c,
                    Preferred_Email__c,
                    Title,
                    GA_Client_ID__c
                FROM Contact
                WHERE Id = :businessContactsToQuery.keySet() AND RecordTypeId = :bdContactRT
            ]) {
                EventDetail eventDetail = businessContactsToQuery.get(busContact.Id);
                RFIReceiver.rfi rfi = eventDetail.rfi;
                DedupeHelper.updateContactFields(
                    busContact,
                    rfi.e_first_name,
                    rfi.GA_Client_ID,
                    rfi.e_last_name,
                    rfi.e_phone,
                    rfi.e_email,
                    rfi.e_opt_out,
                    rfi.e_title
                );
                eventDetail.submittedRFIRecord = busContact;
                eventDetail.accountId = busContact.AccountId;

                contactsToUpdate.put(eventDetail, busContact);
            }
        }
    }

    private void findMatchingLeadRecords(Map<EventDetail, Lead> leadsToCheck) {
        List<Datacloud.FindDuplicatesResult> duplicateLeadResults;

        if (!leadsToCheck.isEmpty()) {
            duplicateLeadResults = Datacloud.FindDuplicates.findDuplicates(leadsToCheck.values());
        }

        Map<Id, EventDetail> prospectLeadsToQuery = new Map<Id, EventDetail>();
        Map<Id, EventDetail> businessLeadsToQuery = new Map<Id, EventDetail>();

        for (Integer i = 0; i < leadsToCheck.size(); i++) {
            Lead leadToCheck = leadsToCheck.values()[i];
            EventDetail eventDetail = new List<EventDetail>(leadsToCheck.keySet())[i];
            Datacloud.FindDuplicatesResult duplicateLeadResult = duplicateLeadResults[i];
            handleDuplicates(leadToCheck, eventDetail, duplicateLeadResult, '00Q');

            if (eventDetail.recordId != null) {
                if (eventDetail.rfi.RecordType == 'Prospective Student') {
                    populateMap(prospectLeadsToQuery, eventDetail.recordId, eventDetail);
                } else if (eventDetail.rfi.RecordType == 'Business Development') {
                    populateMap(businessLeadsToQuery, eventDetail.recordId, eventDetail);
                }
            } else {
                leadsToCreate.put(
                    eventDetail,
                    DedupeHelper.mapLeadFields(eventDetail.rfi, eventDetail.rfi.recordType, null, false)
                );
            }
        }

        if (!prospectLeadsToQuery.isEmpty()) {
            Map<Id, EventDetail> convertedAccountToQuery = new Map<Id, EventDetail>();
            for (Lead foundLead : [
                SELECT
                    Id,
                    RecordTypeId,
                    IsConverted,
                    ConvertedAccountId,
                    ConvertedContactId,
                    FirstName,
                    LastName,
                    OwnerId,
                    GDPR_Opt_In__c,
                    GDPR_Modified__c,
                    Home_Phone__c,
                    Work_Phone__c,
                    Preferred_Phone__c,
                    Personal_Email__c,
                    Work_Email__c,
                    Preferred_Email__c,
                    GA_Client_ID__c,
                    GClid_Information__c,
                    Title,
                    Company,
                    Description,
                    Available_Levy__c,
                    Area_of_Interest__c,
                    rfi_Course_of_Interest__c,
                    Marketing_Campaign_ID__c,
                    Marketing_Media_Source__c,
                    Marketing_Medium__c,
                    LeadSource,
                    Lead_Source_Recent__c,
                    Lead_Source_Title_Recent__c,
                    Status,
                    Lead_Source_Title__c,
                    Lead_Subsource__c,
                    Lead_Subsource_Recent__c,
                    Hashed_Email__c
                FROM Lead
                WHERE Id = :prospectLeadsToQuery.keySet() AND RecordTypeId = :leadProspectRtId
            ]) {
                EventDetail eventDetail = prospectLeadsToQuery.get(foundLead.Id);
                RFIReceiver.rfi rfi = eventDetail.rfi;
                if (!foundLead.IsConverted) {
                    DedupeHelper.mapLeadFields(rfi, rfi.RecordType, foundLead, true);
                    eventDetail.submittedRFIRecord = foundLead;
                } else {
                    populateMap(convertedAccountToQuery, foundLead.ConvertedAccountId, eventDetail);
                }
            }

            if (!convertedAccountToQuery.isEmpty()) {
                for (Account foundAccount : [
                    SELECT
                        Id,
                        RecordTypeId,
                        PersonContactId,
                        FirstName,
                        LastName,
                        OwnerId,
                        GDPR_Opt_In__c,
                        GDPR_Modified__c,
                        PersonHomePhone,
                        Preferred_Phone__pc,
                        Personal_Email__pc,
                        Preferred_Email__pc,
                        GA_Client_ID__pc,
                        Hashed_Email__pc,
                        PersonTitle
                    FROM Account
                    WHERE Id IN :convertedAccountToQuery.keySet()
                ]) {
                    EventDetail eventDetail = convertedAccountToQuery.get(foundAccount.Id);
                    RFIReceiver.RFI rfi = eventDetail.rfi;
                    DedupeHelper.updateAccountFields(
                        foundAccount,
                        rfi.e_first_name,
                        rfi.GA_Client_ID,
                        rfi.e_hashed_email,
                        rfi.e_last_name,
                        rfi.e_phone,
                        rfi.e_email,
                        rfi.e_opt_out,
                        rfi.e_title
                    );
                    eventDetail.submittedRFIRecord = foundAccount;
                    eventDetail.personContactId = foundAccount.PersonContactId;

                    accountsToUpdate.put(eventDetail, foundAccount);
                }
            }
        }

        Map<Id, EventDetail> convertedContactToQuery = new Map<Id, EventDetail>();
        if (!businessLeadsToQuery.isEmpty()) {
            for (Lead foundLead : [
                SELECT
                    Id,
                    RecordTypeId,
                    IsConverted,
                    ConvertedAccountId,
                    ConvertedContactId,
                    FirstName,
                    LastName,
                    OwnerId,
                    GDPR_Opt_In__c,
                    GDPR_Modified__c,
                    Home_Phone__c,
                    Work_Phone__c,
                    Preferred_Phone__c,
                    Personal_Email__c,
                    Work_Email__c,
                    Preferred_Email__c,
                    GA_Client_ID__c,
                    GClid_Information__c,
                    Title,
                    Company,
                    Description,
                    Available_Levy__c,
                    Area_of_Interest__c,
                    rfi_Course_of_Interest__c,
                    Marketing_Campaign_ID__c,
                    Marketing_Media_Source__c,
                    Marketing_Medium__c,
                    LeadSource,
                    Lead_Source_Recent__c,
                    Lead_Source_Title_Recent__c,
                    Status,
                    Lead_Source_Title__c,
                    Lead_Subsource__c,
                    Lead_Subsource_Recent__c,
                    Hashed_Email__c
                FROM Lead
                WHERE Id = :businessLeadsToQuery.keySet() AND RecordType.DeveloperName = 'Business_Development'
            ]) {
                EventDetail eventDetail = businessLeadsToQuery.get(foundLead.Id);
                RFIReceiver.RFI rfi = eventDetail.rfi;
                if (!foundLead.IsConverted) {
                    DedupeHelper.mapLeadFields(rfi, rfi.RecordType, foundLead, true);
                    eventDetail.submittedRFIRecord = foundLead;
                } else {
                    populateMap(convertedContactToQuery, foundLead.ConvertedContactId, eventDetail);
                }
            }

            if (!convertedContactToQuery.isEmpty()) {
                for (Contact foundContact : [
                    SELECT
                        Id,
                        RecordTypeId,
                        AccountId,
                        FirstName,
                        LastName,
                        OwnerId,
                        GDPR_Opt_In__c,
                        GDPR_Modified__c,
                        Work_Phone__c,
                        Preferred_Phone__c,
                        Work_Email__c,
                        Preferred_Email__c,
                        Title,
                        GA_Client_ID__c
                    FROM Contact
                    WHERE Id IN :convertedContactToQuery.keySet()
                ]) {
                    EventDetail eventDetail = convertedContactToQuery.get(foundContact.Id);
                    RFIReceiver.RFI rfi = eventDetail.rfi;
                    DedupeHelper.updateContactFields(
                        foundContact,
                        rfi.e_first_name,
                        rfi.GA_Client_ID,
                        rfi.e_last_name,
                        rfi.e_phone,
                        rfi.e_email,
                        rfi.e_opt_out,
                        rfi.e_title
                    );
                    eventDetail.submittedRFIRecord = foundContact;

                    contactsToUpdate.put(eventDetail, foundContact);
                }
            }
        }
    }

    private void processDML() {
        List<EventDetail> submittedRFIRecords = new List<EventDetail>();

        if (!accountsToUpdate.isEmpty()) {
            List<Database.SaveResult> saveResults = Database.update(
                accountsToUpdate.values(),
                DedupeHelper.getAllowSaveOptions()
            );

            submittedRFIRecords.addAll(
                handleDMLErrors(
                    saveResults,
                    accountsToUpdate.values(),
                    new List<EventDetail>(accountsToUpdate.keySet())
                )
            );
        }

        if (!contactsToUpdate.isEmpty()) {
            List<Database.SaveResult> saveResults = Database.update(
                contactsToUpdate.values(),
                DedupeHelper.getAllowSaveOptions()
            );

            submittedRFIRecords.addAll(
                handleDMLErrors(
                    saveResults,
                    contactsToUpdate.values(),
                    new List<EventDetail>(contactsToUpdate.keySet())
                )
            );
        }

        if (!leadsToCreate.isEmpty()) {
            Database.DMLOptions dml = new Database.DMLOptions();
            dml.assignmentRuleHeader.useDefaultRule = true;
            List<Database.SaveResult> saveResults = Database.insert(leadsToCreate.values(), dml);

            submittedRFIRecords.addAll(
                handleDMLErrors(saveResults, leadsToCreate.values(), new List<EventDetail>(leadsToCreate.keySet()))
            );
        }

        if (!submittedRFIRecords.isEmpty()) {
            Map<EventDetail, Task> tasksToCreate = new Map<EventDetail, Task>();
            for (EventDetail eventDetail : submittedRFIRecords) {
                tasksToCreate.put(
                    eventDetail,
                    DedupeHelper.taskCreationHandler(
                        eventDetail.submittedRFIRecord,
                        eventDetail.rfi,
                        eventDetail.personContactId,
                        eventDetail.accountId
                    )
                );
            }

            List<Database.SaveResult> saveResults = Database.insert(tasksToCreate.values(), false);

            submittedRFIRecords.addAll(
                handleDMLErrors(saveResults, tasksToCreate.values(), new List<EventDetail>(tasksToCreate.keySet()))
            );
        }

        for (Queue_Job__c job : jobsToSchema.keySet()) {
            if (!failedJobs.containsKey(job)) {
                successfulJobs.add(job);
            }
        }
    }

    private void handleDuplicates(
        SObject record,
        EventDetail eventDetail,
        Datacloud.FindDuplicatesResult duplicateResult,
        String expectedType
    ) {
        List<DuplicateHandler.MatchingRecord> matchingRecords = DuplicateFinder.processDuplicates(
            new List<SObject>{ record },
            new List<Datacloud.FindDuplicatesResult>{ duplicateResult }
        );

        if (matchingRecords.size() == 0) {
            return;
        } else {
            Id matchedId = (matchingRecords.size() == 1
                ? matchingRecords.get(0).matchingId
                : DuplicateHandler.handleMatchingRecords(matchingRecords));

            if (String.valueOf(matchedId).contains(expectedType)) {
                eventDetail.recordId = DedupeHelper.formatResponseId(String.valueOf(matchedId));
            }
        }
    }

    private Lead checkLeadExists(RFIReceiver.RFI rfi) {
        DedupeLead.CheckLead lead = new DedupeLead.CheckLead();
        lead.recordType = (rfi.RecordType != null ? rfi.RecordType : null);
        lead.email = (rfi.e_email != null ? rfi.e_email : null);
        lead.firstname = (rfi.e_first_name != null ? rfi.e_first_name : null);
        lead.lastname = (rfi.e_last_name != null ? rfi.e_last_name : null);
        lead.phone = (rfi.e_phone != null ? rfi.e_phone : null);

        return DedupeLead.createComparisonLead(lead);
    }

    private Account checkAccountExists(RFIReceiver.RFI rfi) {
        DedupeAccount.CheckAccount account = new DedupeAccount.CheckAccount();
        account.email = (rfi.e_email != null ? rfi.e_email : null);
        account.firstname = (rfi.e_first_name != null ? rfi.e_first_name : null);
        account.lastname = (rfi.e_last_name != null ? rfi.e_last_name : null);
        account.phone = (rfi.e_phone != null ? rfi.e_phone : null);

        return DedupeAccount.createComparisonAccount(account);
    }

    private Contact checkContactExists(RFIReceiver.RFI rfi) {
        DedupeContact.CheckContact contact = new DedupeContact.CheckContact();
        contact.recordType = (rfi.RecordType != null ? rfi.RecordType : null);
        contact.accountName = (rfi.e_company != null ? rfi.e_company : null);
        contact.email = (rfi.e_email != null ? rfi.e_email : null);
        contact.firstname = (rfi.e_first_name != null ? rfi.e_first_name : null);
        contact.lastname = (rfi.e_last_name != null ? rfi.e_last_name : null);
        contact.phone = (rfi.e_phone != null ? rfi.e_phone : null);

        return DedupeContact.createComparisonContact(contact);
    }

    private List<EventDetail> handleDMLErrors(
        List<Database.SaveResult> saveResults,
        List<SObject> updatedRecords,
        List<EventDetail> eventDetails
    ) {
        List<EventDetail> submittedRFIRecords = new List<EventDetail>();

        for (Integer i = 0; i < updatedRecords.size(); i++) {
            EventDetail eventdetail = eventDetails[i];

            if (!saveResults[i].isSuccess()) {
                List<String> errorMessages = new List<String>();
                for (Database.Error err : saveResults[i].getErrors()) {
                    errorMessages.add(err.getStatusCode() + ': ' + err.getMessage());
                }

                failedJobs.put(eventDetail.queueJob, String.join(errorMessages, ' | '));
            } else {
                eventDetail.submittedRFIRecord = updatedRecords[i];
                submittedRFIRecords.add(eventDetail);
            }
        }

        return submittedRFIRecords;
    }

    private void populateMap(Map<Id, EventDetail> mapToUpdate, Id key, EventDetail value) {
        // if several records update the same id, use the latest
        if (mapToUpdate.containsKey(key)) {
            Queue_Job__c jobSuperseded = mapToUpdate.get(key).queueJob;
            successfulJobs.add(jobSuperseded);
        }
        mapToUpdate.put(key, value);
    }

    class EventDetail {
        public RFIReceiver.RFI rfi;
        public String recordId;
        public Queue_Job__c queueJob;

        SObject submittedRFIRecord;
        Id personContactId;
        Id accountId;
    }
}
