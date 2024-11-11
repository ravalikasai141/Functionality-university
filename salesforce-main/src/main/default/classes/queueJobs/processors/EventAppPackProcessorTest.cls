@isTest
private class EventAppPackProcessorTest {
    static Id accountRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
        .get('Student_Account')
        .getRecordTypeId();

    @TestSetup
    private static void setUp() {
        Account acc = new Account(FirstName = 'Test', LastName = 'Test', RecordTypeId = accountRecordTypeId);

        insert acc;

        Opportunity opp = new Opportunity(
            Name = 'Test-Opp',
            Application_Id__c = 'test-123',
            AccountId = acc.Id,
            StageName = 'Application',
            CloseDate = Date.today()
        );

        insert opp;

        External_Document__c existingDoc = new External_Document__c(
            Document_ID__c = 'test-existing-doc',
            Type__c = 'Application Pack',
            Opportunity__c = opp.Id
        );

        insert existingDoc;
    }

    @isTest
    private static void itShouldCreateAnAppPackDocument() {
        AppPackSchema schema = new AppPackSchema();
        schema.applicationId = 'test-123';
        schema.appPackDocumentId = 'new-id-doc';

        Queue_Job__c queueJob = new Queue_Job__c(Job_Content__c = JSON.serialize(schema));

        EventAppPackProcessor processor = new EventAppPackProcessor();
        processor.processImpl(new List<Queue_Job__c>{ queueJob });

        List<External_Document__c> docsOut = [
            SELECT Opportunity__r.Application_Id__c
            FROM External_Document__c
            WHERE Document_ID__c = 'new-id-doc'
        ];

        Assert.areEqual(1, docsOut.size(), 'I expect one document to be created');
        Assert.areEqual(
            'test-123',
            docsOut[0].Opportunity__r.Application_Id__c,
            'I expect the document to be attached to opp'
        );
    }

    @isTest
    private static void itShouldNotCreateDuplicates() {
        AppPackSchema schema = new AppPackSchema();
        schema.applicationId = 'test-123';
        schema.appPackDocumentId = 'test-existing-doc';

        Queue_Job__c queueJob = new Queue_Job__c(Job_Content__c = JSON.serialize(schema));

        EventAppPackProcessor processor = new EventAppPackProcessor();
        processor.processImpl(new List<Queue_Job__c>{ queueJob });

        List<External_Document__c> docsOut = [
            SELECT Opportunity__r.Application_Id__c
            FROM External_Document__c
            WHERE Opportunity__r.Application_Id__c = 'test-123'
        ];

        Assert.areEqual(1, docsOut.size(), 'I expect it to skip creating this document as it already exists');
    }

    @isTest
    private static void itShouldFailOnRequiredFields() {
        AppPackSchema schema = new AppPackSchema();
        schema.applicationId = 'test-123';

        Queue_Job__c queueJob = new Queue_Job__c(Job_Content__c = JSON.serialize(schema));

        EventAppPackProcessor processor = new EventAppPackProcessor();
        processor.processImpl(new List<Queue_Job__c>{ queueJob });

        Assert.areEqual(1, processor.failedJobs.size(), 'I expect the job to fail due to missing required fields');
    }
}
