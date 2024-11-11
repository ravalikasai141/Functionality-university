@isTest
public class EventDocumentUploadedProcessorTest {
    private static final String TEST_USER_ID = 'ID_123';

    @TestSetup
    static void setup() {
        Id accountRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
            .get('Student_Account')
            .getRecordTypeId();

        Account account = new Account(FirstName = 'Test', LastName = 'Test', RecordTypeId = accountRecordTypeId);
        insert account;

        insert new Hub_Account__c(
            Student__c = account.Id,
            Auth0_Id__c = TEST_USER_ID,
            Hub_Username__c = 'testuser1@bpp.com'
        );
    }

    @isTest
    static void itShouldCreateDocuments() {
        // GIVEN a queue job
        DocumentSchema eventSchema = createTestSchema();
        Queue_Job__c queueJob = new Queue_Job__c(
            Job_Type__c = 'documentUploaded',
            Job_Content__c = JSON.serialize(eventSchema)
        );

        // WHEN the processor is run
        Test.startTest();
        EventDocumentUploadedProcessor processor = new EventDocumentUploadedProcessor();
        processor.processImpl(new List<Queue_Job__c>{ queueJob });
        Test.stopTest();

        // THEN theres no failed jobs
        Assert.areEqual(0, processor.failedJobs.size());

        // AND the document was created
        List<External_Document__c> documents = [
            SELECT Id, Name, Document_ID__c, Content_Type__c, Version__c, Status__c, Student__c
            FROM External_Document__c
        ];
        Assert.areEqual(1, documents.size());
        Assert.areEqual(eventSchema.documentId, documents[0].Document_ID__c);
        Assert.areEqual(eventSchema.version, documents[0].Version__c);
        Assert.areEqual(eventSchema.contentType, documents[0].Content_Type__c);
        Assert.areEqual(eventSchema.documentName, documents[0].Name);
        Assert.areEqual('Uploaded', documents[0].Status__c);

        Hub_Account__c hubAccount = [SELECT Student__c FROM Hub_Account__c WHERE auth0_Id__c = :TEST_USER_ID];
        Assert.areEqual(hubAccount.Student__c, documents[0].Student__c);
    }

    @isTest
    static void itShouldUpdateDocuments() {
        // GIVEN a queue job
        DocumentSchema eventSchema = createTestSchema();
        Queue_Job__c queueJob = new Queue_Job__c(
            Job_Type__c = 'documentUploaded',
            Job_Content__c = JSON.serialize(eventSchema)
        );

        // AND a document
        insert new External_Document__c(Document_ID__c = eventSchema.documentId);
        External_Document__c documentBefore = [
            SELECT Status__c
            FROM External_Document__c
            WHERE Document_ID__c = :eventSchema.documentId
        ];
        Assert.areNotEqual('Uploaded', documentBefore.Status__c);

        // WHEN the processor is run
        Test.startTest();
        EventDocumentUploadedProcessor processor = new EventDocumentUploadedProcessor();
        processor.processImpl(new List<Queue_Job__c>{ queueJob });
        Test.stopTest();

        // THEN theres no failed jobs
        Assert.areEqual(0, processor.failedJobs.size(), 'Expected no failed jobs');

        // AND the document was updated
        External_Document__c documentAfter = [
            SELECT Id, Document_ID__c, Status__c
            FROM External_Document__c
            WHERE Id = :documentBefore.Id
        ];
        Assert.areEqual(eventSchema.documentId, documentAfter.Document_ID__c);
        Assert.areEqual('Uploaded', documentAfter.Status__c);
    }

    @isTest
    static void itShouldDeleteDocuments() {
        // GIVEN a queue job with a type of Deleted
        DocumentSchema eventSchema = createTestSchema();
        Queue_Job__c queueJob = new Queue_Job__c(
            Job_Type__c = 'documentDeleted',
            Job_Content__c = JSON.serialize(eventSchema)
        );

        // AND a document
        insert new External_Document__c(Document_ID__c = eventSchema.documentId);
        External_Document__c documentBefore = [
            SELECT Status__c
            FROM External_Document__c
            WHERE Document_ID__c = :eventSchema.documentId
        ];
        Assert.areNotEqual('Uploaded', documentBefore.Status__c);

        // WHEN the processor is run
        Test.startTest();
        EventDocumentUploadedProcessor processor = new EventDocumentUploadedProcessor();
        processor.processImpl(new List<Queue_Job__c>{ queueJob });
        Test.stopTest();

        // THEN there's no failed jobs
        Assert.areEqual(0, processor.failedJobs.size(), 'Expected no failed jobs');

        // AND the document was updated to deleted
        External_Document__c documentAfter = [
            SELECT Id, Document_ID__c, Status__c
            FROM External_Document__c
            WHERE Id = :documentBefore.Id
        ];
        Assert.areEqual(eventSchema.documentId, documentAfter.Document_ID__c);
        Assert.areEqual('Deleted', documentAfter.Status__c);
    }

    private static DocumentSchema createTestSchema() {
        DocumentSchema schema = new DocumentSchema();
        schema.documentName = 'example.txt';
        schema.documentId = 'D123';
        schema.contentType = 'Document';
        schema.documentType = 'General';
        schema.authUserId = TEST_USER_ID;
        schema.version = '1';
        schema.status = 'completed';

        return schema;
    }
}
