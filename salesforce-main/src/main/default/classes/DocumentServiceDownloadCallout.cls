/**
 * A class representing functionality for downloading documents and handling related callouts.
 */
public class DocumentServiceDownloadCallout extends DocumentServiceCallout {
    /**
     * Represents output data for the getDocumentUrl method in a Flow.
     */
    public class FlowOutput {
        /**
         * List of DocumentServiceCalloutResult objects containing document callout results.
         */
        @InvocableVariable(label='Document Results')
        public List<DocumentServiceCalloutResult> documentResults = new List<DocumentServiceCalloutResult>();
    }

    /**
     * Retrieves document URLs and returns a list of FlowOutput objects.
     *
     * @param documents A list of lists of External_Document__c objects to retrieve URLs for.
     * @return A list of FlowOutput objects containing document callout results.
     */
    @InvocableMethod
    public static List<FlowOutput> getDocumentUrl(List<List<External_Document__c>> documents) {
        if (Killswitch.isEnabled(Killswitch.DOCUMENT_SERVICE_KILLSWITCH)) {
            return null;
        }

        DocumentServiceDownloadCallout downloadCallout = new DocumentServiceDownloadCallout();
        FlowOutput flowOutput = downloadCallout.processDocuments(documents[0]);
        return new List<FlowOutput>{ flowOutput };
    }

    /**
     * Processes a list of External_Document__c objects and returns a FlowOutput object containing document callout results.
     *
     * @param documents A list of External_Document__c objects to process.
     * @return A FlowOutput object containing document callout results.
     */
    private FlowOutput processDocuments(List<External_Document__c> documents) {
        FlowOutput flowOutput = new FlowOutput();
        for (External_Document__c document : documents) {
            DocumentServiceCallout.DocumentServiceUtil dsu = new DocumentServiceCallout.DocumentServiceUtil();
            dsu.documentCalloutResult.documentId = document.Id;
            dsu.action = 'Download';

            String graphqlQuery = generateBody(document);
            try {
                dsu.response = performCallout(graphqlQuery);
                handleResponse(dsu);
            } catch (Exception e) {
                handleFailedResponse('Error occured when retrieving document url', e.getMessage());
                throw e;
            }
            flowOutput.documentResults.add(dsu.documentCalloutResult);
        }
        return flowOutput;
    }

    /**
     * Generates a GraphQL query body based on the provided External_Document__c object.
     *
     * @param document The External_Document__c object for which to generate the GraphQL query body.
     * @return The generated GraphQL query body as a String.
     */
    private String generateBody(External_Document__c document) {
        return 'query Query {' +
            'getPresignedDownloadUrl(input: { ' +
            'documentId: "' +
            document.Document_ID__c +
            '", ' +
            'auth0Id: "' +
            document.User_ID__c +
            '"' +
            '}) {preSignedUrl}}';
    }

    /**
     * Performs a callout using the provided GraphQL query and returns the HTTP response.
     *
     * @param graphqlQuery The GraphQL query to perform.
     * @return The HTTP response received from the callout.
     */
    private HTTPResponse performCallout(String graphqlQuery) {
        return callService(graphqlQuery);
    }
}
