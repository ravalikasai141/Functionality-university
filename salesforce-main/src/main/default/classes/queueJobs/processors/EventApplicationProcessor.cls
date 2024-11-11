/**
 * Processor for the Application Service events
 */
public class EventApplicationProcessor extends BaseProcessor {
    private Map<String, ApplicationJobDetails> applicantIdToDetails = new Map<String, ApplicationJobDetails>();
    private Map<String, ApplicationJobDetails> applicationIdToDetails = new Map<String, ApplicationJobDetails>();
    private Map<Id, ApplicationJobDetails> contactIdToJobDetails = new Map<Id, ApplicationJobDetails>();
    private Map<String, Id> compositeKeyToQualification = new Map<String, Id>();
    private Set<String> qualificationComposite = new Set<String>();
    private Map<String, Id> codeToType = new Map<String, Id>();
    private Map<String, String> nameToType = new Map<String, String>();
    private Map<String, Id> codeToSubject = new Map<String, Id>();
    private Map<String, String> nameToSubject = new Map<String, String>();
    private Map<String, Id> codeToInstitution = new Map<String, Id>();
    private Map<String, String> nameToInstitution = new Map<String, String>();
    private Map<String, External_Document__c> documentIdToExternalDocument = new Map<String, External_Document__c>();

    private Map<String, Product2> identifierToProduct = new Map<String, Product2>();
    private Map<String, Id> isoCodeToCountry = new Map<String, Id>();

    private Map<String, Id> ksbToId = new Map<String, Id>();
    private Map<String, Id> applicationIdToOpportunityOwnerId = new Map<String, Id>();

    private static final string USER_ID_ERROR = 'The given Applicant Id does not exist in Salesforce.';

    private Id opportunityApprenticeApplicationRecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName()
        .get('Apprentice_Application')
        .getRecordTypeId();

    private Id opportunityStudentInterestRecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName()
        .get('Student_Interest')
        .getRecordTypeId();

    private Id leadRecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName()
        .get('Prospective_Student')
        .getRecordTypeId();

    private LeadStatus convertStatus = [
        SELECT Id, MasterLabel
        FROM LeadStatus
        WHERE IsConverted = TRUE AND ApiName = 'Existing account'
        LIMIT 1
    ];

    @TestVisible
    private Id pricebookId {
        get {
            if (pricebookId == null) {
                pricebookId = [SELECT Id FROM Pricebook2 WHERE IsStandard = TRUE].Id;
            }
            return pricebookId;
        }
        set;
    }

    /**
     * Update a related opp and account from event. Use duplicate rules to clean up any matching leads
     * @param  queueJobs queueJobs description
     */
    public void processImpl(List<Queue_Job__c> queueJobs) {
        // Allow user account updated events
        StreamingService.allowedEvents.add('userAccountUpdated');

        // deserialize event
        deserializeEvents(queueJobs);

        Map<String, Opportunity> applicationToOpp = new Map<String, Opportunity>();
        Map<String, List<External_Document__c>> applicationToDocs = new Map<String, List<External_Document__c>>();
        Map<String, Address__c> applicantToAddress = new Map<String, Address__c>();
        Map<String, Account> applicantToAccount = new Map<String, Account>();
        Map<String, List<KSB__c>> applicantToKSBs = new Map<String, List<KSB__c>>();

        Map<String, List<Qualification__c>> applicantToQualification = new Map<String, List<Qualification__c>>();

        Map<String, Queue_Job__c> applicantToJob = new Map<String, Queue_Job__c>();
        applicationIdToOpportunityOwnerId.putAll(OpportunityHelper.getOpportunityOwner(getAccountIdList()));

        for (ApplicationJobDetails jobDetails : applicationIdToDetails.values()) {
            String applicationId = jobDetails.applicationId;
            String applicantId = jobDetails.applicantId;
            Account existingAccount = jobDetails.account;

            // Create a new Opportunity record to upsert, providing an Id or null depending on if an Opportunity was already identified
            Opportunity oppToUpsert = populateOpportunity(
                jobDetails.schema,
                existingAccount.Id,
                jobDetails?.opportunity?.Id
            );
            applicationToOpp.put(applicationId, oppToUpsert);

            // If we have already populated an Account and Address with the given Applicant Id, work out which is the latest change
            if (applicantToJob.containsKey(applicantId)) {
                if (jobDetails.queueJob.Event_Time__c <= applicantToJob.get(applicantId).Event_Time__c) {
                    continue;
                }
            }

            // If the schema contains KSBs process and build a map of KSBs to insert
            if (jobDetails.schema.educationAndSkills?.selfAssessment?.ksbs != null) {
                applicantToKSBs.put(
                    applicantId,
                    populateKSB(
                        jobDetails.schema.educationAndSkills?.selfAssessment?.ksbs,
                        applicationId,
                        jobDetails?.opportunity?.Id
                    )
                );
            }

            // Create a new Address record to upsert, providing an Id or null depending on if an Address was already identified
            if (jobDetails.schema.personalDetails?.address != null) {
                Address__c addressToUpsert = populateAddress(
                    jobDetails.schema.personalDetails.address,
                    existingAccount.Id,
                    existingAccount.Addresses__r.isEmpty() ? null : existingAccount.Addresses__r[0].id
                );
                applicantToAddress.put(applicantId, addressToUpsert);
            }

            // Create documents
            ApplicationSchema.DocumentsInformation documentsAndEvidence = jobDetails.schema
                ?.documentsAndEvidence
                ?.backgroundInformation;

            if (documentsAndEvidence != null) {
                List<External_Document__c> documents = new List<External_Document__c>();

                if (
                    documentsAndEvidence?.nameChanged != null &&
                    documentsAndEvidence?.nameChanged.isNameSameAsApplication == false
                ) {
                    documents.addAll(
                        populateDocumentsInfo(
                            new List<ApplicationSchema.DocumentInformation>{ documentsAndEvidence?.nameChanged },
                            jobDetails,
                            'Name Changed'
                        )
                    );
                }

                List<ApplicationSchema.DocumentInformation> generalDocSchema = documentsAndEvidence?.generalDocuments;

                if (generalDocSchema != null && !generalDocSchema.isEmpty()) {
                    documents.addAll(populateDocumentsInfo(generalDocSchema, jobDetails, 'GENERAL'));
                }

                List<ApplicationSchema.DocumentInformation> eduHistoryDocSchema = documentsAndEvidence
                    ?.educationHistoryDocuments;

                if (eduHistoryDocSchema != null && !eduHistoryDocSchema.isEmpty()) {
                    documents.addAll(populateDocumentsInfo(eduHistoryDocSchema, jobDetails, 'EDUCATION_HISTORY'));
                }

                applicationToDocs.put(applicationId, documents);
            }

            // Create a new Qualification record to upsert
            List<Qualification__c> qualificationsToUpsert = new List<Qualification__c>();

            List<ApplicationSchema.Qualification> qualifications = jobDetails.schema.educationAndSkills
                ?.educationHistory
                ?.qualifications;

            if (qualifications != null) {
                for (ApplicationSchema.Qualification currentQualification : qualifications) {
                    Qualification__c qualification = populateQualification(currentQualification, existingAccount);

                    if (qualification != null) {
                        qualificationsToUpsert.add(qualification);
                    }

                    contactIdToJobDetails.put(existingAccount.personContactId, applicantIdToDetails.get(applicantId));
                }
            }
            applicantToQualification.put(applicantId, qualificationsToUpsert);

            // Populate a new Account record to upsert always providing the Id we've identified
            Account accountToUpdate = populateAccount(jobDetails.schema);
            accountToUpdate.Id = existingAccount.Id;
            applicantToAccount.put(applicantId, accountToUpdate);

            // Finally populate a map of Applicant to Queue Job to identify that we have already created records for  Qualification, Address and Account for use in earlier deduplication
            applicantToJob.put(applicantId, jobDetails.queueJob);
        }

        processDML(
            applicantToAccount,
            applicationToOpp,
            applicantToAddress,
            applicantToKSBs,
            applicationToDocs,
            applicantToQualification
        );
    }

    private List<String> getAccountIdList() { 
        List<String> accountIdList = new List<String>();
        for (ApplicationJobDetails jobDetails : applicationIdToDetails.values()) {
            if (jobDetails.account != null && jobDetails.account.Id != null) {
                accountIdList.add(jobDetails.account.Id);
            }
        }
        return accountIdList;
    }

    /**
     * Preforms any DML inserts and updates for the provided records
     * @param  applicantToAcc  A map of Applicant Id (Auth0 Id's) to Accounts to update
     * @param  applicationToOpp  A map of Application Ids to Opportunities to insert/update
     * @param  applicantToAddress  A map of Applicant Id (Auth0 Id's) Ids to Addresses to insert/update
     * @param  applicantToKSBs  A map of Applicant Id (Auth0 Id's) Ids to KSBs to insert/update
     * @param  applicationToDocs  A map of Application Ids to Documents to insert/update
     * @param  applicantToQualification Qualifications to insert/update
     */
    private void processDML(
        Map<String, Account> applicantToAcc,
        Map<String, Opportunity> applicationToOpp,
        Map<String, Address__c> applicantToAddress,
        Map<String, List<KSB__c>> applicantToKSBs,
        Map<String, List<External_Document__c>> applicationToDocs,
        Map<String, List<Qualification__c>> applicantToQualification
    ) {
        // update Accounts bypassing any Account duplicate rules
        Database.DMLOptions dml = new Database.DMLOptions();
        dml.DuplicateRuleHeader.allowSave = true;
        dml.optAllOrNone = false;

        Savepoint savePoint = Database.setSavepoint();
        List<Database.SaveResult> accountUpdateResults = Database.Update(applicantToAcc.values(), dml);

        for (Integer i = 0; i < accountUpdateResults.size(); i++) {
            Database.SaveResult result = accountUpdateResults[i];

            if (!result.isSuccess()) {
                String applicantId = (new List<String>(applicantToAcc.keySet()))[i];
                ApplicationJobDetails jobDetails = applicantIdToDetails.get(applicantId);
                processDMLErrors(jobDetails.queueJob, result.getErrors());

                applicantToAcc.remove(jobDetails.applicantId);
                applicationToOpp.remove(jobDetails.applicationId);
                applicantToAddress.remove(jobDetails.applicantId);
                applicantToKSBs.remove(jobDetails.applicantId);
                applicationToDocs.remove(jobDetails.applicationId);
                applicantToQualification.remove(jobDetails.applicantId);
            }
        }

        // Create / update any opps
        List<Database.UpsertResult> oppResults = Database.Upsert(applicationToOpp.values(), false);
        for (Integer i = 0; i < oppResults.size(); i++) {
            Database.UpsertResult result = oppResults[i];
            if (!result.isSuccess()) {
                String applicationId = (new List<String>(applicationToOpp.keySet()))[i];
                ApplicationJobDetails jobDetails = applicationIdToDetails.get(applicationId);
                processDMLErrors(jobDetails.queueJob, result.getErrors());

                applicationToOpp.remove(jobDetails.applicationId);
                applicantToAddress.remove(jobDetails.applicantId);
                applicantToKSBs.remove(jobDetails.applicantId);
                applicationToDocs.remove(jobDetails.applicationId);
                applicantToQualification.remove(jobDetails.applicantId);
            }
        }

        ApplicationAudit.createAudits(applicationToOpp.keySet(), DateTime.now());

        List<KSB__c> ksbsToUpsert = new List<KSB__c>();
        for (List<KSB__c> ksb : applicantToKSBs.values()) {
            ksbsToUpsert.addAll(ksb);
        }

        // Create / Update any KSBs
        List<Database.UpsertResult> ksbResults = Database.Upsert(ksbsToUpsert, false);
        for (Integer i = 0; i < ksbResults.size(); i++) {
            Database.UpsertResult result = ksbResults[i];
            if (!result.isSuccess()) {
                String applicationId = ksbsToUpsert[i].Opportunity__r.Application_Id__c;
                ApplicationJobDetails jobDetails = applicationIdToDetails.get(applicationId);
                processDMLErrors(jobDetails.queueJob, result.getErrors());

                applicantToAddress.remove(jobDetails.applicantId);
                applicantToKSBs.remove(jobDetails.applicantId);
                applicationToDocs.remove(jobDetails.applicationId);
                applicantToQualification.remove(jobDetails.applicantId);
            }
        }

        // Create / update any addresses
        List<Database.UpsertResult> addressResults = Database.Upsert(applicantToAddress.values(), false);
        for (Integer i = 0; i < addressResults.size(); i++) {
            Database.UpsertResult result = addressResults[i];
            if (!result.isSuccess()) {
                String applicantId = (new List<String>(applicantToAddress.keySet()))[i];
                ApplicationJobDetails jobDetails = applicantIdToDetails.get(applicantId);
                processDMLErrors(jobDetails.queueJob, result.getErrors());

                applicantToAddress.remove(jobDetails.applicantId);
                applicationToDocs.remove(jobDetails.applicationId);
                applicantToQualification.remove(jobDetails.applicantId);
            }
        }

        // Create / update any Documents
        List<External_Document__c> documentsToUpsert = new List<External_Document__c>();
        for (List<External_Document__c> documents : applicationToDocs.values()) {
            documentsToUpsert.addAll(documents);
        }

        List<Database.UpsertResult> docResults = Database.Upsert(documentsToUpsert, false);
        for (Integer i = 0; i < docResults.size(); i++) {
            Database.UpsertResult result = docResults[i];
            if (!result.isSuccess()) {
                String applicationId = documentsToUpsert[i].Opportunity__r.Application_Id__c;
                ApplicationJobDetails jobDetails = applicationIdToDetails.get(applicationId);
                processDMLErrors(jobDetails.queueJob, result.getErrors());

                applicationToDocs.remove(jobDetails.applicationId);
                applicantToQualification.remove(jobDetails.applicantId);
            }
        }

        // Upsert qualifications
        List<Qualification__c> qualificationToUpsert = new List<Qualification__c>();
        for (List<Qualification__c> qualifications : applicantToQualification.values()) {
            qualificationToUpsert.addAll(qualifications);
        }

        List<Database.UpsertResult> qualificationResults = Database.Upsert(qualificationToUpsert, false);
        for (Integer i = 0; i < qualificationResults.size(); i++) {
            Database.UpsertResult result = qualificationResults[i];
            if (!result.isSuccess()) {
                ApplicationJobDetails jobDetails = contactIdToJobDetails.get(qualificationToUpsert[i].Student__c);
                processDMLErrors(jobDetails.queueJob, result.getErrors());

                applicantToQualification.remove(jobDetails.applicantId);
            }
        }

        // Mark jobs as successful
        for (String applicationId : applicationIdToDetails.keySet()) {
            ApplicationJobDetails jobDetails = applicationIdToDetails.get(applicationId);

            if (!failedJobs.containsKey(jobDetails.queueJob)) {
                successfulJobs.add(jobDetails.queueJob);
            }
        }
    }

    /**
     * deserializes job content and adds to lists to be processed
     * @param  queueJobs Queue Jobs being processed
     */
    public void deserializeEvents(List<Queue_Job__c> queueJobs) {
        Set<String> allProductIds = new Set<String>();
        Set<String> allCountryCodes = new Set<String>();
        Set<String> allDocumentIds = new Set<String>();
        Set<String> typeCodes = new Set<String>();
        Set<String> subjectCodes = new Set<String>();
        Set<String> institutionCodes = new Set<String>();

        // De-duplicate queue jobs by their Application Id
        for (Queue_Job__c queueJob : queueJobs) {
            ApplicationSchema event = (ApplicationSchema) JSON.deserialize(
                queueJob.Job_Content__c,
                ApplicationSchema.class
            );

            Map<String, String> requiredFieldMap = new Map<String, String>{
                'Applicant Id' => event?.applicantId,
                'Application Id' => event?.applicationId,
                'Personal Details: First Name' => event.personalDetails?.personalInfo?.firstName,
                'Personal Details: Last Name' => event.personalDetails?.personalInfo?.lastName
            };

            // Identify any required fields which are blank so we can fail the job
            List<String> requiredFieldErrors = new List<String>();
            for (String potentialError : requiredFieldMap.keySet()) {
                if (String.isBlank(requiredFieldMap.get(potentialError))) {
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

            // If we have already mapped an event with a given Application Id, mark whichever is oldest as successful
            if (applicationIdToDetails.containsKey(event.applicationId)) {
                Queue_Job__c duplicateJob = applicationIdToDetails.get(event.applicationId).queueJob;

                if (queueJob.Event_Time__c <= duplicateJob.Event_Time__c) {
                    successfulJobs.add(queueJob);
                    continue;
                }

                successfulJobs.add(duplicateJob);
            }

            // Extract any details that we require for querying records
            allCountryCodes.add(event.personalDetails?.address?.country?.code);
            allCountryCodes.add(event.employerInformation?.companyInformation?.country?.code);
            allCountryCodes.add(event.backgroundInformation?.nationality?.countryOfBirth?.code);
            allCountryCodes.add(event.backgroundInformation?.nationality?.countryOfNationality?.code);
            allCountryCodes.add(event.backgroundInformation?.nationality?.countryOfPermanentResidency?.code);

            ApplicationSchema.DocumentsInformation documentsInfo = event.documentsAndEvidence?.backgroundInformation;

            // Extract any details off of General Documents
            if (documentsInfo?.generalDocuments != null) {
                for (ApplicationSchema.DocumentInformation documentInfo : documentsInfo.generalDocuments) {
                    if (documentInfo.documents != null && !documentInfo.documents.isEmpty()) {
                        for (ApplicationSchema.Document document : documentInfo.documents) {
                            allDocumentIds.add(document.documentId);
                        }
                    }
                }
            }

            // Extract any details off of Education History Documents
            if (documentsInfo?.educationHistoryDocuments != null) {
                for (ApplicationSchema.DocumentInformation documentInfo : documentsInfo.educationHistoryDocuments) {
                    allCountryCodes.add(documentInfo.country?.code);

                    if (documentInfo.documents != null && !documentInfo.documents.isEmpty()) {
                        for (ApplicationSchema.Document document : documentInfo.documents) {
                            allDocumentIds.add(document.documentId);
                        }
                    }
                }
            }

            // Extract any details off of Name Changed Documents.
            List<ApplicationSchema.Document> nameChangedDocs = documentsInfo?.nameChanged?.documents;
            if (nameChangedDocs != null && !nameChangedDocs.isEmpty()) {
                for (ApplicationSchema.Document document : nameChangedDocs) {
                    allDocumentIds.add(document.documentId);
                }
            }

            // remove prefix for PCV2 products
            String productId = event.productId?.remove('PCV2-');
            allProductIds.add(productId);

            List<ApplicationSchema.Qualification> qualifications = event.educationAndSkills
                ?.educationHistory
                ?.qualifications;

            // Extract any details off of any provided qualifications for querying out records
            if (qualifications != null) {
                for (ApplicationSchema.Qualification qualification : qualifications) {
                    typeCodes.add(qualification.type?.code);
                    subjectCodes.add(qualification.subject?.code);
                    allCountryCodes.add(qualification.country?.code);
                    institutionCodes.add(qualification.awardingInstitution?.code);
                }
            }

            // Group together any relevant details needed for processing the job
            ApplicationJobDetails jobDetails = new ApplicationJobDetails();
            jobDetails.schema = event;
            jobDetails.applicantId = event.applicantId;
            jobDetails.applicationId = event.applicationId;
            jobDetails.queueJob = queueJob;

            // Map the remaining Queue Job details by their Application Id and Applicant Id for later processing
            applicationIdToDetails.put(event.applicationId, jobDetails);

            // Map the most up to date queue job against any unique account together by its job type to ensure we don't have competing Account updates
            if (applicantIdToDetails.containsKey(event.applicantId)) {
                Queue_Job__c duplicateJob = applicantIdToDetails.get(event.applicantId).queueJob;

                if (queueJob.Event_Time__c <= duplicateJob.Event_Time__c) {
                    continue;
                }
            }

            applicantIdToDetails.put(event.applicantId, jobDetails);
        }

        // Retrieve all isoCodeToCountry required for processing
        for (Country_List__c country : [
            SELECT Id, country_code_2__c
            FROM Country_List__c
            WHERE country_code_2__c IN :allCountryCodes
        ]) {
            isoCodeToCountry.put(country.country_code_2__c, country.Id);
        }

        // Retrieve all Products required for processing
        for (Product2 product : [
            SELECT Instance_Id__c, Programme__c, Programme__r.Name, Location__c, Start_Date__c, BPP_ProductFactoryID__c
            FROM Product2
            WHERE
                (Instance_Id__c IN :allProductIds
                AND Instance_Id__c != NULL)
                OR (BPP_ProductFactoryID__c IN :allProductIds
                AND BPP_ProductFactoryID__c != NULL)
        ]) {
            if (product.Instance_Id__c != null) {
                identifierToProduct.put(product.Instance_Id__c, product);
            } else {
                identifierToProduct.put(product.BPP_ProductFactoryID__c, product);
            }
        }

        // Get existing records where document not provided
        for (External_Document__c document : [
            SELECT
                Id,
                Opportunity__r.Application_Id__c,
                Opportunity__c,
                Type__c,
                Document_ID__c,
                Qualification__c,
                Awarding_Institution__c,
                Category__c,
                Country__c,
                Not_Available__c,
                Student__c
            FROM External_Document__c
            WHERE
                Opportunity__r.Application_Id__c IN :applicationIdToDetails.keySet()
                OR (Document_ID__c IN :allDocumentIds
                AND Document_ID__c != NULL)
        ]) {
            ApplicationJobDetails jobDetails = applicationIdToDetails.get(document.Opportunity__r.Application_Id__c);

            if (document.Document_ID__c != null) {
                documentIdToExternalDocument.put(document.Document_ID__c, document);

                if (jobDetails != null) {
                    jobDetails.idToDocument.put(document.Document_ID__c, document);
                }

                continue;
            }

            jobDetails.keyToDocument.put(
                document.Type__c +
                    document.Category__c +
                    document.Qualification__c +
                    document.Awarding_Institution__c +
                    document.Country__c,
                document
            );
        }

        // Retrieve all Accounts, Hub Accounts, Opportunities and Addresses required for processing
        List<String> foundApplicantIds = new List<String>();

        for (Account account : [
            SELECT
                Id,
                personContactId,
                (SELECT Auth0_Id__c FROM Hub_Accounts__r WHERE Auth0_Id__c IN :applicantIdToDetails.keySet()),
                (
                    SELECT Id, Application_Id__c
                    FROM Opportunities
                    WHERE Application_Id__c IN :applicationIdToDetails.keySet()
                ),
                (SELECT Id FROM Addresses__r WHERE Type__c = 'Home' ORDER BY LastModifiedDate DESC),
                (
                    SELECT
                        Qualification_Type__r.Type_Code__c,
                        Qualification__c.Qualification_Type_Name__c,
                        Qualification_Institution_Name__c,
                        Qualification__c.Qualification_Subject__c,
                        Qualification_Subject__r.Subject_Code__c,
                        Qualification_Institution__r.Institution_Code__c,
                        Subject_Name__c,
                        Student__c
                    FROM Qualifications__pr
                )
            FROM account
            WHERE
                account.isPersonAccount = TRUE
                AND Id IN (SELECT Student__c FROM Hub_Account__c WHERE Auth0_Id__c IN :applicantIdToDetails.keySet())
        ]) {
            // Map all Identified Accounts and Opportunity records to their corresponding events
            for (Hub_Account__c hubAccount : account.Hub_Accounts__r) {
                applicantIdToDetails.get(hubAccount.Auth0_Id__c).account = account;

                // Also list out all Accounts which we were able to identify so that we can fail any events with invalid Applicant Id's
                foundApplicantIds.add(hubAccount.Auth0_Id__c);
            }

            for (Opportunity opp : account.Opportunities) {
                applicationIdToDetails.get(opp.Application_Id__c).opportunity = opp;
            }

            // Map all identified Qualifications by their Account Id, Type code and Subject Code
            for (Qualification__c qualification : account.Qualifications__pr) {
                compositeKeyToQualification.put(generateCompositeKeyForQualification(qualification), qualification.Id);
            }
        }

        // Populate qualification maps with type and subject records matching codes in event
        for (Qualification_Type__c qualificationType : [
            SELECT Id, Type_Code__c, Name
            FROM Qualification_Type__c
            WHERE Type_Code__c IN :typeCodes AND Type_Code__c != NULL
        ]) {
            codeToType.put(qualificationType.Type_Code__c, qualificationType.Id);
            nameToType.put(qualificationType.Type_Code__c, qualificationType.Name);
        }

        for (Qualification_Subject__c qualificationSubject : [
            SELECT Id, Subject_Code__c, Name
            FROM Qualification_Subject__c
            WHERE Subject_Code__c IN :subjectCodes AND Subject_Code__c != NULL
        ]) {
            codeToSubject.put(qualificationSubject.Subject_Code__c, qualificationSubject.Id);
            nameToSubject.put(qualificationSubject.Subject_Code__c, qualificationSubject.Name);
        }

        for (Qualification_Institution__c qualificationInstitution : [
            SELECT Id, Institution_Code__c, Name
            FROM Qualification_Institution__c
            WHERE Institution_Code__c IN :institutionCodes AND Institution_Code__c != NULL
        ]) {
            codeToInstitution.put(qualificationInstitution.Institution_Code__c, qualificationInstitution.Id);
            nameToInstitution.put(qualificationInstitution.Institution_Code__c, qualificationInstitution.Name);
        }

        // Query out KSBs that are related to the Applications in the given events and store them
        // with a composite key for upserts
        for (KSB__c ksb : [
            SELECT Id, Code__c, Opportunity__c, Answer__c, Experience_Information__c, Question__c
            FROM KSB__c
            WHERE Opportunity__r.Application_Id__c IN :applicationIdToDetails.keySet()
        ]) {
            ksbToId.put(ksb.Code__c + ksb.Opportunity__c, ksb.Id);
        }

        // When multiple events update the same Account, only the most recent event is linked to the Account.
        // To link all events to the Account that will be updated, loop through and link to the identified Account.
        for (String applicationId : applicationIdToDetails.keySet()) {
            ApplicationJobDetails jobDetails = applicationIdToDetails.get(applicationId);
            ApplicationJobDetails jobDetailsFromAccount = applicantIdToDetails.get(jobDetails.applicantId);

            if (jobDetails.account == null && jobDetailsFromAccount != null) {
                jobDetails.account = jobDetailsFromAccount.account;
            }
        }

        // Finally loop over all Applications and make sure we've identified Accounts to link them to
        for (String currentApplicationId : applicationIdToDetails.keySet()) {
            ApplicationJobDetails currentJobDetails = applicationIdToDetails.get(currentApplicationId);

            if (!foundApplicantIds.contains(currentJobDetails.applicantId)) {
                // Fail any jobs which do not have an Account in Salesforce and remove them from any maps to stop further processing
                failedJobs.put(currentJobDetails.queueJob, USER_ID_ERROR);
                applicantIdToDetails.remove(currentJobDetails.applicantId);
                applicationIdToDetails.remove(currentApplicationId);
            }
        }
    }

    /**
     * Update account with data from schema
     * @param  accountToUpdate account to update
     * @param  schema          schema to update from
     * @return                 account with updated values
     */
    private Account populateAccount(ApplicationSchema schema) {
        ApplicationSchema.PersonalInfo personalInfo = schema.personalDetails?.personalInfo;
        ApplicationSchema.EmergencyContact emergencyContact = schema.personalDetails?.emergencyContact;
        ApplicationSchema.GuardianInfo guardian = personalInfo?.guardianInfo;
        ApplicationSchema.EqualityAndDiversity equalityAndDiversity = schema.backgroundInformation
            ?.equalityAndDiversity;
        ApplicationSchema.LearningNeeds learningNeeds = equalityAndDiversity?.learningNeeds;
        ApplicationSchema.CareExperience careExperience = equalityAndDiversity?.careExperience;
        ApplicationSchema.CodeDetail sexualOrientation = equalityAndDiversity?.sexualOrientation;
        ApplicationSchema.CodeDetail religion = equalityAndDiversity?.religion;
        ApplicationSchema.Ethnicity ethnicity = equalityAndDiversity?.ethnicity;
        ApplicationSchema.CodeDetail gender = equalityAndDiversity?.gender;
        ApplicationSchema.CodeDetail sameGenderAsBirth = equalityAndDiversity?.sameGenderAsBirth;
        ApplicationSchema.ContactPreferences preferences = schema.privacyTermsAndConditions?.contactPreferences;
        ApplicationSchema.CodeDetail countryOfNationality = schema.backgroundInformation
            ?.nationality
            ?.countryOfNationality;

        List<String> secondaryDifficulties = new List<String>();
        if (learningNeeds?.secondaryDifficulty != null) {
            for (ApplicationSchema.CodeDetail difficulty : learningNeeds?.secondaryDifficulty) {
                secondaryDifficulties.add(difficulty.code);
            }
        }

        Map<String, Object> accountUpdates = new Map<String, Object>{
            'Salutation' => personalInfo?.title,
            'FirstName' => personalInfo?.firstName,
            'LastName' => personalInfo?.lastName,
            'Middle_Name__pc' => personalInfo?.middleName,
            'PersonEmail' => personalInfo?.emailAddress,
            'Personal_Email__pc' => personalInfo?.emailAddress,
            'PersonBirthdate' => personalInfo?.dateOfBirth,
            'NI_Number__pc' => personalInfo?.niNumber,
            'Preferred_Email__pc' => String.isBlank(personalInfo?.emailAddress) ? '' : 'Personal',
            'Parent_Guardian_First_Name__pc' => guardian?.firstName,
            'Parent_Guardian_Last_Name__pc' => guardian?.lastName,
            'Parent_Guardian_Relationship__pc' => guardian?.relationship,
            'Parent_Guardian_Mobile__pc' => guardian?.mobilePhone,
            'Parent_Guardian_Email__pc' => guardian?.emailAddress,
            'Emergency_Contact_First_Name__pc' => emergencyContact?.firstName,
            'Emergency_Contact_Last_Name__pc' => emergencyContact?.lastName,
            'Emergency_Contact_Relationship__pc' => emergencyContact?.relationship,
            'Emergency_Contact_Mobile__pc' => emergencyContact?.mobilePhone,
            'Emergency_Contact_Email__pc' => emergencyContact?.emailAddress,
            'Gender__pc' => gender?.name,
            'Gender_Identity__pc' => sameGenderAsBirth?.code,
            'SFDC_Ethnic_Code_Select__pc' => ethnicity?.codeHESA,
            'Ethnicity_ESFA__pc' => ethnicity?.codeESFA,
            'Religion__pc' => religion?.code,
            'Sexual_Orientation__pc' => sexualOrientation?.code,
            'Criminal_conviction_details__c' => equalityAndDiversity?.criminalConvictionDescription,
            'Care_Experience_Level__c' => careExperience?.careExperienceLevel,
            'Is_Local_Authority_Care__c' => careExperience?.isLocalAuthorityCare,
            'SFDC_Country_of_Birth__pc' => isoCodeToCountry.get(
                schema.backgroundInformation?.nationality?.countryOfBirth?.code
            ),
            'Primary_Nationality__pc' => isoCodeToCountry.get(
                schema.backgroundInformation?.nationality?.countryOfNationality?.code
            ),
            'Country_of_Residence__pc' => schema.backgroundInformation?.nationality?.countryOfPermanentResidency?.name,
            'Primary_Learning_Difficulty__c' => learningNeeds?.primaryDifficulty?.code,
            'Other_Primary_Learning_Difficulty__c' => learningNeeds?.primaryDifficultyOther,
            'Can_inform_employer_is_care_leaver__c' => equalityAndDiversity?.careExperience?.isInformEmployer,
            'Would_like_to_receive_bursary__c' => equalityAndDiversity?.careExperience?.isRequestCareLeaverBursary,
            'Has_been_paid_a_care_leavers_bursary__c' => equalityAndDiversity
                ?.careExperience
                ?.isAlreadyReceivedCareLeaverBursary,
            'Has_Learning_Needs__c' => learningNeeds?.isLearningNeed?.name,
            'Other_Secondary_Learning_Difficulty__c' => learningNeeds?.secondaryDifficultyOther,
            'Secondary_Learning_Difficulty__c' => String.join(secondaryDifficulties, ';'),
            'High_Level_Needs__c' => learningNeeds?.highLevelSpecialNeeds?.name,
            'In_receipt_of_EHCP__c' => learningNeeds?.receiptEducationCarePlan?.name
        };

        Account accountToUpdate = new Account();

        for (String accountField : accountUpdates.keySet()) {
            Object value = accountUpdates.get(accountField);

            if (!String.isBlank(String.valueOf(value))) {
                accountToUpdate.put(accountField, value);
            }
        }

        if (equalityAndDiversity?.isCriminalConviction != null) {
            accountToUpdate.Criminal_Conviction__pc = equalityAndDiversity?.isCriminalConviction ? 'Yes' : 'No';
        }

        // Update the Mobile Phone fields if we have a value to update them to
        if (!String.isBlank(personalInfo?.mobilePhone)) {
            accountToUpdate.Phone = personalInfo.mobilePhone;
            accountToUpdate.PersonMobilePhone = personalInfo.mobilePhone;
            accountToUpdate.Preferred_Phone__pc = 'Mobile';
        }

        // Mark and newly checked Contact Preference Types as true
        if (preferences?.contactType != null && !preferences.contactType.isEmpty()) {
            if (preferences.contactType.contains('EMAIL')) {
                accountToUpdate.Email_Opt_In__pc = true;
            }

            if (preferences.contactType.contains('POST')) {
                accountToUpdate.Post_Opt_In__pc = true;
            }

            if (preferences.contactType.contains('PHONE')) {
                accountToUpdate.Phone_Opt_In__pc = true;
            }
        }

        // Combine all Contact Preference types into a multiselect picklist
        if (preferences?.contactChannel != null) {
            accountToUpdate.Contact_Preference_Type__pc = String.join(preferences?.contactChannel, ';');
        }

        // Update the Student type fields to Domestic, EU or International
        if (countryOfNationality?.code != null) {
            // Use a custom metadata type query to get the Nationality value based on country code
            accountToUpdate.Student_Type__pc = getNationalityValue(countryOfNationality.code);
        }

        return accountToUpdate;
    }

    // Retrieve Nationality value from Country_of_Nationality__mdt
    private String getNationalityValue(String countryCode) {
        Map<String, String> countryOfNationalityMap = new Map<String, String>();
        String nationalityValue;

        List<Country_of_Nationality__mdt> countryOfNationalityList = [
            SELECT MasterLabel, Nationality__c
            FROM Country_of_Nationality__mdt
            WHERE MasterLabel = :countryCode
            LIMIT 1
        ];

        for (Country_of_Nationality__mdt con : countryOfNationalityList) {
            countryOfNationalityMap.put(con.MasterLabel, con.Nationality__c);
        }
        if (countryOfNationalityMap.containsKey(countryCode)) {
            nationalityValue = countryOfNationalityMap.get(countryCode);
        }

        switch on nationalityValue {
            when 'EU' {
                return 'EU';
            }
            when 'UK' {
                return 'Domestic';
            }
            when else {
                return 'International';
            }
        }
    }

    /**
     *
     * @param ksbs KSB data from the event
     * @param applicationId The application ID
     * @param existingOppId The ID of the opportunity
     * @return  List if KSBs to be upserted
     */
    private List<KSB__c> populateKSB(List<ApplicationSchema.KSBS> ksbs, String applicationId, Id existingOppId) {
        List<KSB__c> ksbsToUpsert = new List<KSB__c>();

        // Loop through the ksbs given in the schema
        for (ApplicationSchema.KSBS ksb : ksbs) {
            // Check to make sure the KSB code is populated
            if (!String.isBlank(ksb.code)) {
                // Populate the KSB object
                KSB__c ksbObj = new KSB__c(
                    Code__c = ksb.code,
                    Question__c = ksb.question,
                    Answer__c = ksb.answer,
                    Experience_Information__c = ksb.experienceInfo,
                    Description__c = ksb.description,
                    Line_Manager_Workplace_Activity__c = ksb.lmWorkplaceActivity,
                    Opportunity__r = new Opportunity(Application_Id__c = applicationId)
                );

                if (ksb.isModifiedByLM != null) {
                    ksbObj.Modified_By_Line_Manager__c = ksb.isModifiedByLM;
                }

                // Check if the KSB exists
                if (existingOppId != null && ksbToId.containsKey(ksb.code + existingOppId)) {
                    ksbObj.Id = ksbToId.get(ksb.code + existingOppId);
                }

                // Add KSB to the list
                ksbsToUpsert.add(ksbObj);
            }
        }
        return ksbsToUpsert;
    }

    /**
     * Populates Opportunity from schema
     * @param  schema        data from event
     * @param  accountId     the account to link the opp to
     * @param  existingOppId id for the opp if its an update
     * @return               opp with updated values
     */
    private Opportunity populateOpportunity(ApplicationSchema schema, Id accountId, Id existingOppId) {
        ApplicationJobDetails details = applicationIdToDetails.get(schema.applicationId);
        ApplicationSchema.Address address = schema.personalDetails?.address;
        ApplicationSchema.CodeDetail country = address?.country;
        ApplicationSchema.LineManagerInformation manager = schema.employerInformation?.lineManagerInformation;
        ApplicationSchema.LmrAnswers LineManagerAnswers = schema.LineManagerReviewConfirmation?.LmrAnswers;
        ApplicationSchema.CompanyInformation company = schema.employerInformation?.companyInformation;
        ApplicationSchema.Role role = schema.employerInformation?.role;
        ApplicationSchema.PrivacyNotice privacy = schema.privacyTermsAndConditions?.privacyNotice;
        ApplicationSchema.TermsAndConditions applicantTerms = schema.privacyTermsAndConditions
            ?.applicantTermsAndConditions;
        ApplicationSchema.TermsAndConditions lineManagerTerms = schema.privacyTermsAndConditions?.lmrTermsAndConditions;
        ApplicationSchema.PersonalStatement personalStatement = schema?.personalStatement;
        ApplicationSchema.AcademicReference academicReference = schema?.academicReference;
        ApplicationSchema.TuitionFees tuitionFees = schema?.tuitionFees;
        ApplicationSchema.SponsorInfo sponsorInfo = tuitionFees?.sponsorInfo;
        Opportunity opp = new Opportunity();

        if (address != null) {
            opp.Address_Street_1__c = address.line1;
            opp.Address_Street_2__c = address.line2;
            opp.Address_Street_3__c = address.line3;
            opp.Address_City__c = address.city;
            opp.Address_Zip_Postal_Code__c = address.postalCode;
            opp.Address_Lookup_Country__c = isoCodeToCountry.get(address.country?.code);
        }

        if (manager != null) {
            opp.Line_Manager_First_Name__c = manager.firstName;
            opp.Line_Manager_Last_Name__c = manager.lastName;
            opp.Line_Manager_Job_Title__c = manager.jobTitle;
            opp.Line_Manager_Email__c = manager.emailAddress?.toLowerCase();
            opp.Line_Manager_Telephone__c = manager.mobilePhone;
        }

        if (LineManagerAnswers?.isApplicantInRoleLessThan9Month != null) {
            opp.In_role_less_than_nine_months__c = LineManagerAnswers.isApplicantInRoleLessThan9Month ? 'Yes' : 'No';
        }

        if (LineManagerAnswers?.isFewerThan50Employees != null) {
            opp.Fewer_than_50_employees__c = LineManagerAnswers.isFewerThan50Employees ? 'Yes' : 'No';
        }

        if (company != null) {
            opp.Sponsoring_Organization__c = company.companyName;
            opp.Company_Street_1__c = company.line1;
            opp.Company_Street_2__c = company.line2;
            opp.Company_Street_3__c = company.line3;
            opp.Company_Zip_Postal_Code__c = company.postalCode;
            opp.Company_City__c = company.city;
            opp.Company_Lookup_Country__c = isoCodeToCountry.get(company.country?.code);
        }

        if (role != null) {
            opp.Job_Title_Apprentice__c = role.jobTitle;
            opp.Job_Description_Apprentice__c = role.jobDescription;
            opp.Job_Started_On_Apprentice__c = role.jobStartDate;
            opp.Weekly_Contracted_Hours_Apprentice__c = role.weeklyContractedHours;
            opp.Safety_Knowledge_Apprentice__c = role.safetyQueryKnowledge;
        }

        if (privacy != null) {
            opp.Has_Read_Privacy_Notice__c = privacy.hasRead;
        }

        if (applicantTerms != null) {
            opp.Terms_and_Conditions_Read_on__c = applicantTerms.readOn;
        }

        if (lineManagerTerms != null) {
            opp.LM_Terms_and_Conditions_Read_on__c = lineManagerTerms.readOn;
        }

        if (personalStatement?.statement != null) {
            opp.Personal_Statement_Body__c = personalStatement.statement;
        }

        if (schema.clientName != null) {
            opp.Category__c = schema.clientName;
        }

        switch on schema?.apprenticeshipType?.toLowerCase() {
            when 'pq' {
                opp.Application_Type__c = 'Professional Apprenticeship';
            }
            when 'university' {
                opp.Application_Type__c = 'Degree Apprenticeship';
            }
            when else {
                opp.Application_Type__c = null;
            }
        }

        // Product details
        opp.Professional_Qualification__c = schema.awardingBody;
        opp.Product_Id_Text__c = schema.productId;
        opp.EPA__c = schema.product?.EPA;
        opp.EPAO__c = schema.product?.EPAO;
        opp.Product_Level__c = schema.product?.academicLevel;
        String trimmedProduct = schema.productId?.remove('PCV2-');

        if (details.queueJob.Job_Type__c == 'applicationCreated') {
            if (schema.product?.startOn != null) {
                opp.Start_Date__c = schema.product.startOn.date();
            }

            if (schema.product?.endOn != null) {
                opp.End_Date__c = schema.product.endOn.date();
            }

            if (schema.employerInformation?.role?.overallOffTheJobTrainingHours != null) {
                opp.OOTJTH_Preserved__c = schema.employerInformation.role.overallOffTheJobTrainingHours;
            }
        }

        if (identifierToProduct.containsKey(trimmedProduct)) {
            Product2 product = identifierToProduct.get(trimmedProduct);
            opp.Course_Instance__c = product.Id;
            opp.Programme_Application__c = product.Programme__c;
            opp.Pricebook2Id = pricebookId;
        }

        //Academic Reference details
        if (academicReference != null) {
            populateOpportunityAcademicReference(opp, academicReference);
        }

        //Tuition and Sponsorship details
        if (tuitionFees != null) {
            populateOpportunityTuitionAndSponsorship(opp, tuitionFees.fundingType, sponsorInfo);
        }

        if (schema.stages != null) {
            populateSectionJSON(opp, schema.stages);
        }

        if (existingOppId == null) {
            opp.accountId = accountId;
            opp.Name = schema.personalDetails?.personalInfo?.lastName;
            opp.Application_Id__c = schema.applicationId;
            opp.CloseDate = Date.today() + 30;
            opp.RecordTypeId = getRecordTypeId(schema);
            opp.Application_Reference__c = schema.applicationReference;
            opp.Record_Source__c = 'Join';
            if (schema.applicationType == 'UNIVERSITY') {
                opp.StageName = 'Application Started';
                opp.BPP_Sub_Status__c = 'Recent Activity';
                opp.OwnerId = applicationIdToOpportunityOwnerId.get(accountId);
            } else {
                opp.StageName = 'Application';
                opp.BPP_Sub_Status__c = 'In Progress';
            }
        } else {
            if (schema.applicationType == 'UNIVERSITY') {
                opp.BPP_Sub_Status__c = 'Recent Activity';
                opp.GoingStaleDate__c = null;
            }
            opp.id = existingOppId;
        }

        return opp;
    }

    /**
     * Retrieves the Record Type Id based on the provided ApplicationSchema.
     */
    private Id getRecordTypeId(ApplicationSchema schema) {
        Map<String, Id> recordTypeIds = new Map<String, Id>{
            'APPRENTICESHIP' => opportunityApprenticeApplicationRecordTypeId,
            'UNIVERSITY' => opportunityStudentInterestRecordTypeId
        };

        String applicationType = schema.applicationType;
        return recordTypeIds.containsKey(applicationType)
            ? recordTypeIds.get(applicationType)
            : opportunityApprenticeApplicationRecordTypeId;
    }

    /**
     * Populates the Academic Reference fields on the Opportunity.
     *
     * @param opp The Opportunity object to populate.
     * @param academicReference The AcademicReference object containing academic reference details.
     */
    private void populateOpportunityAcademicReference(
        Opportunity opp,
        ApplicationSchema.AcademicReference academicReference
    ) {
        opp.Academic_Reference_First_Name__c = academicReference?.firstName;
        opp.Academic_Reference_Last_Name__c = academicReference?.lastName;
        opp.Academic_Reference_Phone__c = academicReference?.mobilePhone;
        opp.Academic_Reference_Email__c = academicReference?.emailAddress;
        opp.Academic_Reference_Relation__c = academicReference?.relationship;
    }

    /**
     * Populates the Tuition and Sponsorship fields on the Opportunity.
     *
     * @param opp The Opportunity object to populate.
     * @param fundingType The funding type for the opportunity.
     * @param sponsorInfo The SponsorInfo object containing sponsor details (used if fundingType is 'SPONSORSHIP').
     */
    private void populateOpportunityTuitionAndSponsorship(
        Opportunity opp,
        String fundingType,
        ApplicationSchema.SponsorInfo sponsorInfo
    ) {
        Map<String, String> fieldMappings = new Map<String, String>{
            'SPONSORSHIP' => 'Sponsorship',
            'SELF_FUNDED' => 'Self-funded'
        };

        if (fieldMappings.containsKey(fundingType)) {
            opp.Tuition__c = fieldMappings.get(fundingType);

            if (fundingType == 'SPONSORSHIP') {
                opp.Sponsor_First_Name__c = sponsorInfo?.firstName;
                opp.Sponsor_Last_Name__c = sponsorInfo?.lastName;
                opp.Sponsor_Email__c = sponsorInfo?.emailAddress;
                opp.Sponsoring_Organization__c = sponsorInfo?.organisationName;
                opp.Sponsor_Phone__c = sponsorInfo?.mobilePhone;
                opp.Sponsoring_Purchase_Order__c = sponsorInfo?.purchaseOrderNumber;
            }
        }
    }

    private void populateSectionJSON(Opportunity opp, List<ApplicationSchema.Stage> stageList) {
        List<ApplicationSchema.Section> sectionList = new List<ApplicationSchema.Section>();
        for (ApplicationSchema.Stage stage : stageList) {
            if (stage.sections == null) {
                continue;
            }

            sectionList.addAll(stage.sections);
        }

        if (sectionList == null) {
            return;
        }

        opp.Section_JSON__c = JSON.serialize(sectionList);
    }

    /**
     * Update or create address with values from event
     * @param  schema     data from event
     * @param  accountId  the account the address is under
     * @param  existingAddressId  The Id of any existing Address record
     * @return            address with updated values
     */
    private Address__c populateAddress(ApplicationSchema.Address address, Id accountId, Id existingAddressId) {
        // If home address already exists, overwrite
        return new Address__c(
            Id = existingAddressId,
            Student__c = accountId,
            Active__c = true,
            Type__c = 'Home',
            Street_1__c = address.line1,
            Street_2__c = address.line2,
            City__c = address.city,
            Zip_Postal_Code__c = address.postalCode,
            Lookup_Country__c = isoCodeToCountry.get(address.country?.code),
            Record_Source__c = 'Hub'
        );
    }

    /**
     * Iterate document lists and populate them
     * @param  schemaDocInfos document lists from event
     * @param  jobDetails     variable for records relating to the event
     * @param  type           which type list the document was in
     * @return                list of updated documents
     */
    private List<External_Document__c> populateDocumentsInfo(
        List<ApplicationSchema.DocumentInformation> schemaDocInfos,
        ApplicationJobDetails jobDetails,
        String type
    ) {
        List<External_Document__c> updatedDocuments = new List<External_Document__c>();

        for (ApplicationSchema.DocumentInformation schemaDocInfo : schemaDocInfos) {
            if (schemaDocInfo?.documents != null && !schemaDocInfo?.documents?.isEmpty()) {
                for (ApplicationSchema.Document schemaDoc : schemaDocInfo.documents) {
                    updatedDocuments.add(populateDocument(schemaDocInfo, jobDetails, schemaDoc.documentId, type));
                }
                continue;
            }

            // If theres no documentIds passed create placeholder for that kind of document
            updatedDocuments.add(populateDocument(schemaDocInfo, jobDetails, null, type));
        }

        return updatedDocuments;
    }

    /**
     * Checks for matching documents and populates them or creates new
     * @param  schema     individual document from event
     * @param  jobDetails variable for records relating to the event
     * @param  documentId documentId from event
     * @param  type       which type list the document was in
     * @return            return populated document
     */
    private External_Document__c populateDocument(
        ApplicationSchema.DocumentInformation schema,
        ApplicationJobDetails jobDetails,
        String documentId,
        String type
    ) {
        External_Document__c documentToUpdate;

        if (!schema.notAvailable) {
            documentToUpdate = jobDetails.idToDocument.get(documentId);
        }

        // If theres no existing documentid, check if we have a record
        if (documentToUpdate == null) {
            // First check if we have a Document inserted that has a matching Document Id
            if (documentIdToExternalDocument.containsKey(documentId)) {
                documentToUpdate = documentIdToExternalDocument.get(documentId);
            }
            // Otherwise check if we have a document matching the composite
            else {
                documentToUpdate = jobDetails.keyToDocument.get(
                    type +
                        schema.categoryCode +
                        schema.type?.name +
                        schema.awardingInstitution?.name +
                        isoCodeToCountry.get(schema.country?.code)
                );
            }
        }

        // if theres still no match, create new
        if (documentToUpdate == null) {
            List<String> nameInfo = new List<String>{ '[Awaiting Document]', type };
            if (schema.categoryCode != null) {
                nameInfo.add(schema.categoryCode);
            }
            if (schema.type?.name != null) {
                nameInfo.add(schema.type?.name);
            }

            String docName = String.join(nameInfo, ' - ').abbreviate(80);
            documentToUpdate = new External_Document__c(Name = docName);
        } else {
            // remove found record, so its not used again if theres multiple
            jobDetails.keyToDocument.remove(
                type +
                    documentToUpdate.Category__c +
                    documentToUpdate.Qualification__c +
                    documentToUpdate.Awarding_Institution__c +
                    documentToUpdate.Country__c
            );
        }

        // populate document
        documentToUpdate.Type__c = type;
        documentToUpdate.Document_ID__c = documentId;
        documentToUpdate.User_ID__c = jobDetails.applicantId;
        documentToUpdate.Student__c = jobDetails.account.Id;
        documentToUpdate.Not_Available__c = schema.notAvailable;

        if (documentToUpdate.Opportunity__c == null) {
            documentToUpdate.Opportunity__r = new Opportunity(Application_Id__c = jobDetails.applicationId);
        }

        switch on type {
            when 'GENERAL' {
                documentToUpdate.Category__c = schema.categoryCode;
            }
            when 'EDUCATION_HISTORY' {
                documentToUpdate.Qualification__c = schema.type?.name;
                documentToUpdate.Awarding_Institution__c = schema.awardingInstitution?.name;
                documentToUpdate.Country__c = isoCodeToCountry.get(schema.country?.code);
            }
            when 'Name Changed' {
                if (!Killswitch.isEnabled(Killswitch.JOIN2_DOC_KILLSWITCH)) {
                    documentToUpdate.Type__c = 'GENERAL';
                    documentToUpdate.Category__c = 'NAME_CHANGE';
                }
            }
        }

        return documentToUpdate;
    }
    /**
     * Update or create qualification with values from event
     * @param   qualification  The current Qualification to upsert
     * @param   account        The Account that the qualifications should be linked to
     * @return  The qualification with updated values
     */
    private Qualification__c populateQualification(
        ApplicationSchema.Qualification schemaQualification,
        Account account
    ) {
        Qualification__c qualification = new Qualification__c();

        // Populate Qualification Type
        if (nameToType.containsKey(schemaQualification?.type?.code)) {
            qualification.Qualification_Type__c = codeToType.get(schemaQualification?.type?.code);
            qualification.Qualification_Type_Name__c = nameToType.get(schemaQualification?.type?.code);
        } else {
            qualification.Qualification_Type_Name__c = schemaQualification?.type?.name;
        }

        // Populate Qualification Subject
        if (nameToSubject.containsKey(schemaQualification?.subject?.code)) {
            qualification.Qualification_Subject__c = codeToSubject.get(schemaQualification?.subject?.code);
            qualification.Subject_Name__c = nameToSubject.get(schemaQualification?.subject?.code);
        } else if (schemaQualification?.subject?.code == 'OTHER') {
            qualification.Subject_Name__c = schemaQualification?.otherSubjectDetail;
        } else {
            qualification.Subject_Name__c = schemaQualification?.subject?.name?.trim();
        }

        // Populate Institution name
        if (nameToInstitution.containsKey(schemaQualification?.awardingInstitution?.code)) {
            qualification.Qualification_Institution__c = codeToInstitution.get(
                schemaQualification?.awardingInstitution?.code
            );
            qualification.Qualification_Institution_Name__c = nameToInstitution.get(
                schemaQualification?.awardingInstitution?.code
            );
        } else if (schemaQualification?.awardingInstitution?.code == '4941') {
            qualification.Qualification_Institution_Name__c = schemaQualification?.otherAwardingInstitutionDetail;
        } else {
            qualification.Qualification_Institution_Name__c = schemaQualification?.awardingInstitution?.name;
        }

        qualification.Student__c = account.PersonContactId;
        qualification.HESA_Grade__c = schemaQualification?.grade;
        qualification.Year_Of_Completion__c = schemaQualification?.yearCompletedExpected;
        qualification.Country_of_Study__c = isoCodeToCountry.get(schemaQualification?.country?.code);
        qualification.Examing_Body__c = schemaQualification?.examiningBody;

        // Generate new key to match
        String composite = generateCompositeKeyForQualification(qualification);

        // If it exists in the set, dont return it
        if (qualificationComposite.contains(composite)) {
            return null;
        }

        if (compositeKeyToQualification.containsKey(composite)) {
            qualification.Id = compositeKeyToQualification.get(composite);
        }

        qualificationComposite.add(composite);

        return qualification;
    }

    /**
     * Generates a consistent composite key for a qualification
     */
    private String generateCompositeKeyForQualification(Qualification__c qualification) {
        Set<String> keys = new Set<String>{ qualification.Student__c };

        if (qualification.Subject_Name__c != null) {
            keys.add(qualification.Subject_Name__c.trim());
        } else {
            keys.add(qualification.Qualification_Subject__r.Subject_Code__c);
        }

        if (qualification.Qualification_Type_Name__c != null) {
            keys.add(qualification.Qualification_Type_Name__c.trim());
        } else {
            keys.add(qualification.Qualification_Type__r.Type_Code__c);
        }

        if (qualification.Qualification_Institution_Name__c != null) {
            keys.add(qualification.Qualification_Institution_Name__c.trim());
        } else {
            keys.add(qualification.Qualification_Institution__r.Institution_Code__c);
        }

        String result = keys.toString();
        return result;
    }

    // Class to store details relating to the event
    private class ApplicationJobDetails {
        public ApplicationSchema schema;
        public String applicationId;
        public String applicantId;
        public Account account;
        public Opportunity opportunity;
        public Queue_Job__c queueJob;

        // Document included
        public Map<String, External_Document__c> idToDocument = new Map<String, External_Document__c>();

        // Document not available
        public Map<String, External_Document__c> keyToDocument = new Map<String, External_Document__c>();
    }
}
