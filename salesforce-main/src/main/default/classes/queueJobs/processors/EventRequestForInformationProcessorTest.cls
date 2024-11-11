@isTest
private class EventRequestForInformationProcessorTest {
    @isTest
    private static void itShouldCreateLeadOnNoMatch() {
        // GIVEN a queue job
        RequestForInformationSchema eventSchema = createTestSchema();

        Queue_Job__c queueJob = new Queue_Job__c(Job_Content__c = JSON.serialize(eventSchema));

        // WHEN the processor is called
        EventRequestForInformationProcessor processor = new EventRequestForInformationProcessor();
        processor.processImpl(new List<Queue_Job__c>{ queueJob });

        // THEN theres one successfull job
        Assert.areEqual(1, processor.successfulJobs.size(), 'Job is processed successfully');
        Assert.areEqual(0, processor.failedJobs.size(), 'No failed jobs');

        // AND a Lead has been created
        List<Lead> createdLeads = [
            SELECT
                Id,
                Description,
                GA_Client_ID__c,
                GClid_Information__c,
                Hashed_Email__c,
                LeadSource,
                Lead_Source_Recent__c,
                Lead_Source_Title__c,
                Lead_Subsource__c,
                Lead_Source_Timestamp__c,
                Lead_Source_Timestamp_Recent__c,
                Marketing_Campaign_ID__c,
                FirstName,
                LastName,
                Marketing_Medium__c,
                Marketing_Media_Source__c,
                Lead_Source_Title_Recent__c,
                Lead_Subsource_Recent__c,
                rfi_Course_of_Interest__c,
                GDPR_Opt_In__c,
                Personal_Email__c,
                Preferred_Email__c,
                Home_Phone__c,
                Preferred_Phone__c
            FROM Lead
        ];
        Assert.areEqual(1, createdLeads.size());

        Lead createdLead = createdLeads[0];
        Assert.areEqual(eventSchema.comments, createdLead.Description);
        Assert.areEqual(eventSchema.gaClientId, createdLead.GA_Client_ID__c);
        Assert.areEqual(eventSchema.gaGclId, createdLead.GClid_Information__c);
        Assert.areEqual(eventSchema.hashedEmail, createdLead.Hashed_Email__c);
        Assert.areEqual(eventSchema.leadSource, createdLead.LeadSource);
        Assert.areEqual(eventSchema.leadSource, createdLead.Lead_Source_Recent__c);
        Assert.areEqual(eventSchema.sourceTitle, createdLead.Lead_Source_Title__c);
        Assert.areEqual(eventSchema.subSource, createdLead.Lead_Subsource__c);
        Assert.isNotNull(createdLead.Lead_Source_Timestamp__c);
        Assert.isNotNull(createdLead.Lead_Source_Timestamp_Recent__c);
        Assert.areEqual(eventSchema.analytics_campaign, createdLead.Marketing_Campaign_ID__c);
        Assert.areEqual(eventSchema.firstName, createdLead.FirstName);
        Assert.areEqual(eventSchema.lastName, createdLead.LastName);
        Assert.areEqual(eventSchema.analytics_medium, createdLead.Marketing_Medium__c);
        Assert.areEqual(eventSchema.analytics_source, createdLead.Marketing_Media_Source__c);
        Assert.areEqual(eventSchema.sourceTitle, createdLead.Lead_Source_Title_Recent__c);
        Assert.areEqual(eventSchema.subSource, createdLead.Lead_Subsource_Recent__c);
        Assert.areEqual(eventSchema.programmeOfInterest, createdLead.rfi_Course_of_Interest__c);
        Assert.areEqual(!eventSchema.optOut, createdLead.GDPR_Opt_In__c);
        Assert.areEqual(eventSchema.email.toLowerCase(), createdLead.Personal_Email__c);
        Assert.areEqual('Personal', createdLead.Preferred_Email__c);
        Assert.areEqual(eventSchema.phone, createdLead.Home_Phone__c);
        Assert.areEqual('Home', createdLead.Preferred_Phone__c);
    }

    @isTest
    private static void itShouldUpdateLeadOnMatch() {
        // GIVEN a Lead and a queue job
        RequestForInformationSchema eventSchema = createTestSchema();

        Id leadProspectRtId = Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName()
            .get('Prospective_Student')
            .getRecordTypeId();

        insert new Lead(
            RecordTypeId = leadProspectRtId,
            FirstName = eventSchema.firstName,
            LastName = eventSchema.lastName,
            Personal_Email__c = eventSchema.email,
            Preferred_Email__c = 'Personal'
        );

        Queue_Job__c queueJob = new Queue_Job__c(Job_Content__c = JSON.serialize(eventSchema));

        // WHEN the processor is called
        EventRequestForInformationProcessor processor = new EventRequestForInformationProcessor();
        processor.processImpl(new List<Queue_Job__c>{ queueJob });

        // THEN theres one successfull job
        Assert.areEqual(1, processor.successfulJobs.size(), 'Job is processed successfully');
        Assert.areEqual(0, processor.failedJobs.size(), 'No failed jobs');

        // AND a Lead has been updated
        List<Lead> updatedLeads = [
            SELECT
                Id,
                Description,
                GA_Client_ID__c,
                GClid_Information__c,
                Hashed_Email__c,
                LeadSource,
                Lead_Source_Recent__c,
                Lead_Source_Title__c,
                Lead_Subsource__c,
                Lead_Source_Timestamp__c,
                Lead_Source_Timestamp_Recent__c,
                Marketing_Campaign_ID__c,
                FirstName,
                LastName,
                Marketing_Medium__c,
                Marketing_Media_Source__c,
                Lead_Source_Title_Recent__c,
                Lead_Subsource_Recent__c,
                rfi_Course_of_Interest__c,
                GDPR_Opt_In__c,
                Personal_Email__c,
                Preferred_Email__c,
                Home_Phone__c,
                Preferred_Phone__c
            FROM Lead
        ];
        Assert.areEqual(1, updatedLeads.size());

        Lead createdLead = updatedLeads[0];
        Assert.areEqual(eventSchema.comments, createdLead.Description);
        Assert.areEqual(eventSchema.gaClientId, createdLead.GA_Client_ID__c);
        Assert.areEqual(eventSchema.gaGclId, createdLead.GClid_Information__c);
        Assert.areEqual(eventSchema.hashedEmail, createdLead.Hashed_Email__c);
        Assert.areEqual(eventSchema.leadSource, createdLead.LeadSource);
        Assert.areEqual(eventSchema.leadSource, createdLead.Lead_Source_Recent__c);
        Assert.isNotNull(createdLead.Lead_Source_Timestamp_Recent__c);
        Assert.areEqual(eventSchema.analytics_campaign, createdLead.Marketing_Campaign_ID__c);
        Assert.areEqual(eventSchema.firstName, createdLead.FirstName);
        Assert.areEqual(eventSchema.lastName, createdLead.LastName);
        Assert.areEqual(eventSchema.analytics_medium, createdLead.Marketing_Medium__c);
        Assert.areEqual(eventSchema.analytics_source, createdLead.Marketing_Media_Source__c);
        Assert.areEqual(eventSchema.sourceTitle, createdLead.Lead_Source_Title_Recent__c);
        Assert.areEqual(eventSchema.subSource, createdLead.Lead_Subsource_Recent__c);
        Assert.areEqual(eventSchema.programmeOfInterest, createdLead.rfi_Course_of_Interest__c);
        Assert.areEqual(!eventSchema.optOut, createdLead.GDPR_Opt_In__c);
        Assert.areEqual(eventSchema.email.toLowerCase(), createdLead.Personal_Email__c);
        Assert.areEqual('Personal', createdLead.Preferred_Email__c);
        Assert.areEqual(eventSchema.phone, createdLead.Home_Phone__c);
        Assert.areEqual('Home', createdLead.Preferred_Phone__c);
    }

    @isTest
    private static void itShouldUpdateAccountOnMatch() {
        // GIVEN a Lead and a queue job
        RequestForInformationSchema eventSchema = createTestSchema();

        Id studentAccountRT = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
            .get('Student_Account')
            .getRecordTypeId();

        insert new Account(
            RecordTypeId = studentAccountRT,
            FirstName = eventSchema.firstName,
            LastName = eventSchema.lastName,
            Personal_Email__pc = eventSchema.email,
            Preferred_Email__pc = 'Personal',
            PersonHomePhone = eventSchema.phone,
            Preferred_Phone__pc = 'Home'
        );

        Queue_Job__c queueJob = new Queue_Job__c(Job_Content__c = JSON.serialize(eventSchema));

        // WHEN the processor is called
        EventRequestForInformationProcessor processor = new EventRequestForInformationProcessor();
        processor.processImpl(new List<Queue_Job__c>{ queueJob });

        // THEN theres one successfull job
        Assert.areEqual(1, processor.successfulJobs.size(), 'Job is processed successfully');
        Assert.areEqual(0, processor.failedJobs.size(), 'No failed jobs');

        // AND a Lead has been updated
        List<Account> updatedAccounts = [
            SELECT
                Id,
                FirstName,
                GA_Client_ID__pc,
                Hashed_Email__pc,
                LastName,
                PersonHomePhone,
                Personal_Email__pc,
                Preferred_Email__pc,
                Preferred_Phone__pc,
                GDPR_Opt_In__c,
                PersonTitle
            FROM Account
        ];
        Assert.areEqual(1, updatedAccounts.size());

        Account updatedAccount = updatedAccounts[0];
        Assert.areEqual(eventSchema.firstname, updatedAccount.FirstName);
        Assert.areEqual(eventSchema.gaClientId, updatedAccount.GA_Client_ID__pc);
        Assert.areEqual(eventSchema.hashedEmail, updatedAccount.Hashed_Email__pc);
        Assert.areEqual(eventSchema.lastname, updatedAccount.LastName);
        Assert.areEqual(eventSchema.phone, updatedAccount.PersonHomePhone);
        Assert.areEqual(eventSchema.email.toLowerCase(), updatedAccount.Personal_Email__pc);
        Assert.areEqual('Personal', updatedAccount.Preferred_Email__pc);
        Assert.areEqual('Home', updatedAccount.Preferred_Phone__pc);
        Assert.areEqual(!eventSchema.optOut, updatedAccount.GDPR_Opt_In__c);
        Assert.areEqual(eventSchema.jobTitle, updatedAccount.PersonTitle);
    }
    /* Will pass once SF-1316 is merged
    @isTest
    private static void itShouldUpdateContactOnMatch() {
        // GIVEN a Lead and a queue job
        RequestForInformationSchema eventSchema = createTestSchema();
        eventSchema.recordType = 'Business Development';

        Id bdContactRT = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName()
            .get('BD_Contact')
            .getRecordTypeId();

        Account account = new Account(Name = eventSchema.company);
        insert account;

        insert new Contact(
            accountId = account.Id,
            RecordTypeId = bdContactRT,
            FirstName = eventSchema.firstName,
            LastName = eventSchema.lastName,
            Personal_Email__c = eventSchema.email,
            Preferred_Email__c = 'Work',
            HomePhone = eventSchema.phone,
            Preferred_Phone__c = 'Work'
        );

        Queue_Job__c queueJob = new Queue_Job__c(Job_Content__c = JSON.serialize(eventSchema));

        // WHEN the processor is called
        EventRequestForInformationProcessor processor = new EventRequestForInformationProcessor();
        processor.processImpl(new List<Queue_Job__c>{ queueJob });

        // THEN theres one successfull job
        Assert.areEqual(1, processor.successfulJobs.size(), 'Job is processed successfully');
        Assert.areEqual(0, processor.failedJobs.size(), 'No failed jobs');

        // AND a Lead has been updated
        List<Contact> updatedContacts = [
            SELECT
                Id,
                FirstName,
                GA_Client_ID__c,
                LastName,
                Preferred_Email__c,
                Preferred_Phone__c,
                HomePhone,
                Personal_Email__c,
                GDPR_Opt_In__c,
                Title
            FROM Contact
        ];
        Assert.areEqual(1, updatedContacts.size());

        Contact updatedContact = updatedContacts[0];
        Assert.areEqual(eventSchema.firstname, updatedContact.FirstName);
        Assert.areEqual(eventSchema.gaClientId, updatedContact.GA_Client_ID__c);
        Assert.areEqual(eventSchema.lastname, updatedContact.LastName);
        Assert.areEqual('Work', updatedContact.Preferred_Email__c);
        Assert.areEqual('Work', updatedContact.Preferred_Phone__c);
        Assert.areEqual(eventSchema.phone, updatedContact.HomePhone);
        Assert.areEqual(eventSchema.email, updatedContact.Personal_Email__c);
        Assert.areEqual(!eventSchema.optOut, updatedContact.GDPR_Opt_In__c);
        Assert.areEqual(eventSchema.jobTitle, updatedContact.Title);
    }*/

    @isTest
    private static void itShouldFailOnRequiredFieldsForProspectiveStudent() {
        RequestForInformationSchema eventSchema = createTestSchema();
        eventSchema.lastName = '';

        Queue_Job__c queueJob = new Queue_Job__c(Job_Content__c = JSON.serialize(eventSchema));

        EventRequestForInformationProcessor processor = new EventRequestForInformationProcessor();
        processor.processImpl(new List<Queue_Job__c>{ queueJob });

        Assert.areEqual(1, processor.failedJobs.size(), 'I expect the job to fail due to missing required fields');
    }

    @isTest
    private static void itShouldFailOnRequiredFieldsForBusinessDevelopment() {
        RequestForInformationSchema eventSchema = createTestSchema();
        eventSchema.lastName = '';
        eventSchema.company = '';
        eventSchema.recordType = 'Business Development';

        Queue_Job__c queueJob = new Queue_Job__c(Job_Content__c = JSON.serialize(eventSchema));

        EventRequestForInformationProcessor processor = new EventRequestForInformationProcessor();
        processor.processImpl(new List<Queue_Job__c>{ queueJob });

        Assert.areEqual(1, processor.failedJobs.size(), 'I expect the job to fail due to missing required fields');
    }

    static RequestForInformationSchema createTestSchema() {
        RequestForInformationSchema eventSchema = new RequestForInformationSchema();
        eventSchema.analytics_campaign = 'test-campaign';
        eventSchema.analytics_source = 'test-campaign';
        eventSchema.analytics_medium = 'test-campaign';
        eventSchema.email = 'rfi@test.com';
        eventSchema.phone = '+441132021111';
        eventSchema.jobTitle = 'test-jobTitle';
        eventSchema.lastName = 'test-lastName';
        eventSchema.gaGclId = 'test-gclId';
        eventSchema.gaClientId = 'test-clientId';
        eventSchema.currentBppStudent = 'test-bppstudent';
        eventSchema.programmeOfInterest = 'test-page';
        eventSchema.optOut = false;
        eventSchema.firstName = 'test-firstName';
        eventSchema.sourceTitle = 'test-title';
        eventSchema.subSource = 'test-subSource';
        eventSchema.leadSource = 'test-leadSource';
        eventSchema.ukEuStudent = 'test-student';
        eventSchema.comments = 'test-comments';
        eventSchema.recordType = 'Prospective Student';
        eventSchema.formName = 'test-formName';
        eventSchema.company = 'test-company';
        eventSchema.hashedEmail = 'test-hashedEmail';
        eventSchema.levyPayer = false;

        return eventSchema;
    }
}
