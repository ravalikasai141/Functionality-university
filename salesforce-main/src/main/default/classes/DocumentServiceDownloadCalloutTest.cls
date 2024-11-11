@isTest
public class DocumentServiceDownloadCalloutTest {
    private static List<DocumentServiceDownloadCallout.FlowOutput> callGetDocumentUrl(External_Document__c document) {
        List<List<External_Document__c>> documents = new List<List<External_Document__c>>{
            new List<External_Document__c>{ document }
        };
        List<DocumentServiceDownloadCallout.FlowOutput> flowResults = DocumentServiceDownloadCallout.getDocumentUrl(
            documents
        );
        return flowResults;
    }

    private static List<DocumentServiceCalloutResult> assertCheck(
        List<DocumentServiceDownloadCallout.FlowOutput> flowResults,
        External_Document__c document
    ) {
        // THEN there should be a single option returned
        Assert.areEqual(1, flowResults.size(), 'Single option returned.');

        // AND there should have been a single document processed
        List<DocumentServiceCalloutResult> documentResults = flowResults[0].documentResults;
        Assert.areEqual(1, documentResults.size(), 'Single document processed.');

        // AND the document Id and URL should be what we expect
        Assert.areEqual(
            document.Id,
            documentResults[0].documentId,
            'documentId should match created External Document Id.'
        );
        return documentResults;
    }

    @isTest
    private static void itShouldReturnAUrl() {
        TestUtilities.mockKillswitch(Killswitch.DOCUMENT_SERVICE_KILLSWITCH, false);

        // GIVEN a document
        External_Document__c document = new External_Document__c(
            Document_ID__c = 'D-123',
            User_ID__c = 'auth|123',
            Status__c = 'Uploaded'
        );
        insert document;

        String preSignedUrl = 'salesforce.test.com';

        MockHttpClient mock = new MockHttpClient();
        mock.addResponse('@', 200, '{"data":{"getPresignedDownloadUrl":{"preSignedUrl":"' + preSignedUrl + '"}}}');

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, mock);
        // WHEN getDocumentUrl is called
        List<DocumentServiceDownloadCallout.FlowOutput> flowResults = callGetDocumentUrl(document);
        Test.stopTest();

        List<DocumentServiceCalloutResult> documentResults = assertCheck(flowResults, document);
        Assert.areEqual(preSignedUrl, documentResults[0].responseURL, 'responseURL should match preSignedURL.');
    }

    @isTest
    private static void itShouldHandleErrorResponse() {
        TestUtilities.mockKillswitch(Killswitch.DOCUMENT_SERVICE_KILLSWITCH, false);

        // GIVEN a document
        External_Document__c document = new External_Document__c(
            Document_ID__c = 'D-123',
            User_ID__c = 'auth|123',
            Status__c = 'Uploaded'
        );
        insert document;

        MockHttpClient mock = new MockHttpClient();
        mock.addResponse('@', 500);

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, mock);
        // WHEN getDocumentUrl is called
        List<DocumentServiceDownloadCallout.FlowOutput> flowResults = callGetDocumentUrl(document);
        Test.stopTest();

        List<DocumentServiceCalloutResult> documentResults = assertCheck(flowResults, document);
        Assert.isNull(documentResults[0].responseURL, 'responseURL should be null.');
    }
}
