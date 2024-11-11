/**
 * A class representing the functionality to upload documents and handle related callouts.
 */
public class DocumentServiceUploadCallout extends DocumentServiceCallout {
    /**
     * Represents input data for the uploadDocument method in a Flow.
     */
    public class FlowInput {
        /**
         * List of External_Document__c records to upload.
         */
        @InvocableVariable(label='Documents to Upload' required=true)
        public List<External_Document__c> documentsToUpload;

        /**
         * List of ContentVersion records associated with the documents to upload.
         */
        @InvocableVariable(label='Content Version records' required=true)
        public List<ContentVersion> contentVersionList;
    }

    /**
     * Represents output data for the uploadDocument method in a Flow.
     */
    public class FlowOutput {
        /**
         * List of upload results as strings.
         */
        @InvocableVariable(label='Upload Results')
        public List<DocumentServiceCalloutResult> uploadResults = new List<DocumentServiceCalloutResult>();
    }

    /**
     * Uploads documents and returns a list of FlowOutput objects.
     *
     * @param flowInputList A list of FlowInput objects containing documents and content versions to upload.
     * @return A list of FlowOutput objects containing upload results.
     */
    @InvocableMethod
    public static List<FlowOutput> uploadDocument(List<FlowInput> flowInputList) {
        if (Killswitch.isEnabled(Killswitch.DOCUMENT_SERVICE_KILLSWITCH)) {
            return null;
        }

        List<External_Document__c> documentList = flowInputList.get(0).documentsToUpload;
        List<ContentVersion> contentVersionList = flowInputList.get(0).contentVersionList;

        DocumentServiceUploadCallout uploadCallout = new DocumentServiceUploadCallout();
        List<DocumentServiceCallout.DocumentServiceUtil> dsuList = uploadCallout.processDocuments(
            documentList,
            contentVersionList
        );

        List<String> errors = uploadCallout.uploadDocuments(dsuList, contentVersionList);
        List<String> insertDocumentResultsList = uploadCallout.insertExternalDocumentRecords(dsuList, errors);
        return uploadCallout.populateFlowOutputList(insertDocumentResultsList);
    }

    /**
     * Processes a list of External_Document__c objects and returns a list of DocumentServiceUtil objects.
     * Callout returns a preSignedUrl value for each document.
     *
     * @param documents A list of External_Document__c objects to process.
     * @return A list of DocumentServiceUtil objects containing processing results.
     */
    private List<DocumentServiceCallout.DocumentServiceUtil> processDocuments(
        List<External_Document__c> documentList,
        List<ContentVersion> contentVersionList
    ) {
        List<DocumentServiceCallout.DocumentServiceUtil> dsuList = new List<DocumentServiceCallout.DocumentServiceUtil>();
        for (External_Document__c document : documentList) {
            DocumentServiceCallout.DocumentServiceUtil dsu = new DocumentServiceCallout.DocumentServiceUtil();
            dsu.documentCalloutResult.documentId = document.Id;
            dsu.action = 'Upload';

            ContentVersion cv = contentVersionList.get(0);
            document.Name = document.Name + '.' + cv.FileExtension;
            dsu.document = document;

            String graphqlQuery = generateBody(document);
            try {
                dsu.response = performCallout(graphqlQuery);
                handleResponse(dsu);
                dsu.document.Document_ID__c = dsu.documentCalloutResult.documentId;
            } catch (Exception e) {
                handleFailedResponse('Error occured when retrieving document url', e.getMessage());
                throw e;
            }
            dsuList.add(dsu);
        }
        return dsuList;
    }

    /**
     * Generates a GraphQL query body based on the provided External_Document__c object.
     *
     * @param document The External_Document__c object for which to generate the GraphQL query body.
     * @return The generated GraphQL query body as a String.
     */
    private String generateBody(External_Document__c document) {
        return 'query Query {' +
            'getPresignedUploadUrl(input: { ' +
            'auth0Id: "' +
            document.User_ID__c +
            '", ' +
            'contentType: ' +
            document.Content_Type__c +
            ', ' +
            'documentCategory: "' +
            document.Category__c +
            '", ' +
            'documentName: "' +
            document.Name +
            '", ' +
            'documentSensitivity: "sensitive", ' +
            'documentType: ' +
            (String.isBlank(document.Type__c) ? null : '"' + document.Type__c + '"') +
            ', ' +
            'readUserIds: null' +
            '}) {documentId preSignedUrl}}';
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

    /**
     * Loops through the provided lists of DocumentServiceUtil and ContentVersion objects and
     * passes these to the performUploadCallout method.
     *
     * @param dsuList A list of DocumentServiceUtil objects containing document upload information.
     * @param contentVersionList A list of ContentVersion objects containing document content.
     * @return A list of potential errors where previous call did not return a url. Null if no errors.
     */
    private List<String> uploadDocuments(
        List<DocumentServiceCallout.DocumentServiceUtil> dsuList,
        List<ContentVersion> contentVersionList
    ) {
        List<String> errors = new List<String>();
        for (Integer i = 0; i < dsuList.size(); i++) {
            DocumentServiceCallout.DocumentServiceUtil dsu = dsuList.get(i);
            String endpoint = dsu.documentCalloutResult.responseURL;

            External_Document__c document = dsu.document;
            if (endpoint == null) {
                errors.add('Insert failed: ' + document.Name + ' (' + document.Content_Type__c + ')');
                dsu.document = null;
            } else {
                performUploadCallout(endpoint, contentVersionList.get(i).VersionData);
            }
        }
        return errors;
    }

    /**
     * Performs an upload callout to the preSignedUrl endpoint with the provided file blob.
     *
     * @param endpoint The endpoint to which the upload callout is made.
     * @param fileBlob The Blob data representing the file to upload.
     */
    private void performUploadCallout(String endpoint, Blob fileBlob) {
        HttpRequest request = new HttpRequest();
        request.setEndpoint(endpoint);
        request.setMethod('PUT');
        request.setBodyAsBlob(fileBlob);

        Http http = new Http();
        try {
            HttpResponse response = http.send(request);
            if (response.getStatusCode() != 200) {
                handleFailedResponse(
                    response.getStatusCode() + ' Error occured when uploading document',
                    response.getStatus()
                );
            }
        } catch (Exception e) {
            handleFailedResponse('Error occured when uploading document', e.getMessage());
            throw e;
        }
    }

    /**
     * Inserts External_Document__c records and returns a list of insertion result messages.
     *
     * @param documents A list of External_Document__c objects to insert.
     * @param errors A list of Strings containing potential errors.
     * @return A list of insertion result messages.
     */
    private List<String> insertExternalDocumentRecords(
        List<DocumentServiceCallout.DocumentServiceUtil> dsuList,
        List<String> errors
    ) {
        List<String> insertDocumentResultsList = new List<String>();
        List<External_Document__c> documents = new List<External_Document__c>();
        for (DocumentServiceCallout.DocumentServiceUtil dsu : dsuList) {
            if (dsu.document != null) {
                documents.add(dsu.document);
            }
        }
        List<Database.SaveResult> documentResults = Database.insert(documents, false);

        for (Integer i = 0; i < documentResults.size(); i++) {
            External_Document__c document = documents.get(i);
            String recordInfo = document.Name + ' (' + document.Content_Type__c + ')';

            List<String> insertErrors = new List<String>();
            Database.SaveResult result = documentResults[i];
            if (!result.isSuccess()) {
                for (Database.Error error : result.getErrors()) {
                    insertErrors.add(error.getMessage());
                }
            }
            String resultMessage = (insertErrors.size() > 0
                ? 'Insert failed: ' + recordInfo + '. Failure Reason: ' + String.join(insertErrors, ' | ')
                : 'Insert success: ' + recordInfo);
            insertDocumentResultsList.add(resultMessage);
        }
        for (String str : errors) {
            insertDocumentResultsList.add(str);
        }
        return insertDocumentResultsList;
    }

    /**
     * Populates a list of FlowOutput objects with the provided insertion result messages.
     *
     * @param insertDocumentResultsList A list of insertion result messages to populate the FlowOutput objects.
     * @return A list of FlowOutput objects populated with insertion result decision and messages.
     */
    private List<FlowOutput> populateFlowOutputList(List<String> insertDocumentResultsList) {
        FlowOutput flowOutput = new FlowOutput();
        for (String result : insertDocumentResultsList) {
            String decision = result.substringBefore(':');

            DocumentServiceCalloutResult dsu = new DocumentServiceCalloutResult();
            dsu.inserted = (decision.contains('failed') ? false : true);
            dsu.documentDetail = result.substringAfter(': ');

            flowOutput.uploadResults.add(dsu);
        }
        return new List<FlowOutput>{ flowOutput };
    }
}
