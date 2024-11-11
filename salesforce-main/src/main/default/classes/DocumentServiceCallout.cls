/**
 * An abstract class providing functionality for document service callouts.
 */
public abstract class DocumentServiceCallout {
    /**
     * Generates a GraphQL query body based on the provided External_Document__c object.
     *
     * @param document The External_Document__c object for which to generate the GraphQL query body.
     * @return The generated GraphQL query body as a String.
     */
    abstract String generateBody(External_Document__c document);

    /**
     * Performs a callout using the provided GraphQL query and returns the HTTP response.
     *
     * @param graphqlQuery The GraphQL query to perform.
     * @return The HTTP response received from the callout.
     */
    abstract HTTPResponse performCallout(String graphqlQuery);

    /**
     * Retrieves the endpoint for the callout based on the org's domain.
     *
     * @return The endpoint URL for the callout.
     */
    protected String getEndpoint() {
        System.Domain domain = System.DomainParser.parse(URL.getOrgDomainUrl());

        if (!String.isEmpty(domain.getSandboxName())) {
            return 'callout:Document_Service_Test';
        } else {
            return 'callout:Document_Service';
        }
    }

    /**
     * Calls the document service with the provided GraphQL query and returns the HTTP response.
     *
     * @param graphqlQuery The GraphQL query to send in the callout.
     * @return The HTTP response received from the document service.
     */
    protected HTTPResponse callService(String graphqlQuery) {
        HttpRequest request = new HttpRequest();
        request.setEndpoint(getEndpoint());
        request.setMethod('POST');
        request.setHeader('Content-Type', 'application/json');
        request.setHeader('x-api-key', '{!$Credential.Password}');

        Map<String, Object> reqBody = new Map<String, Object>{ 'query' => graphqlQuery };
        request.setBody(JSON.serialize(reqBody));

        Http http = new Http();
        return http.send(request);
    }

    /**
     * Handles the response from the document service callout.
     *
     * @param dsu The DocumentServiceUtil object containing the callout response.
     */
    public void handleResponse(DocumentServiceUtil dsu) {
        if (dsu.response.getStatusCode() == 200) {
            GraphQLResponse deserializedResponse = (GraphQLResponse) JSON.deserialize(
                dsu.response.getBody(),
                GraphQLResponse.class
            );

            Map<String, String> actionToUrlMap = new Map<String, String>{
                'Download' => deserializedResponse?.data?.getPresignedDownloadUrl?.preSignedUrl,
                'Upload' => deserializedResponse?.data?.getPresignedUploadUrl?.preSignedUrl
            };

            String responseURL = actionToUrlMap.get(dsu.action);
            if (String.isNotBlank(responseURL)) {
                dsu.documentCalloutResult.responseURL = responseURL;
            }
            if (dsu.action == 'Upload') {
                dsu.documentCalloutResult.documentId = deserializedResponse?.data?.getPresignedUploadUrl?.documentId;
            }
        } else {
            handleFailedResponse(
                dsu.response.getStatusCode() + ' Error returned from document service',
                dsu.response.getStatus()
            );
        }
    }

    /**
     * Handles a failed response from the document service callout.
     *
     * @param subject The subject of the alert email.
     * @param body The body of the alert email.
     */
    public void handleFailedResponse(String subject, String body) {
        EmailUtilities.submitSystemAlertEmail(subject, body);
    }

    /**
     * Inner class representing the structure of the GraphQL response.
     */
    public class GraphQLResponse {
        public List<Error> errors = new List<Error>();
        public Data data = new Data();
    }

    /**
     * Inner class representing an error message in the GraphQL response.
     */
    public class Error {
        public String message;
    }

    /**
     * Inner class representing the data structure of the GraphQL response.
     */
    public class Data {
        public PresignedDownloadUrl getPresignedDownloadUrl = new PresignedDownloadUrl();
        public PresignedUploadUrl getPresignedUploadUrl = new PresignedUploadUrl();
    }

    /**
     * Inner class representing the structure of the GraphQL response containing a preSignedDownloadUrl.
     */
    public class PresignedDownloadUrl {
        public String preSignedUrl;
    }

    /**
     * Inner class representing the structure of the GraphQL response containing a preSignedUploadUrl.
     */
    public class PresignedUploadUrl {
        public String preSignedUrl;
        public String documentId;
    }

    /**
     * Inner class representing utility data for document service callouts.
     */
    public class DocumentServiceUtil {
        public HTTPResponse response;
        public String action;
        public DocumentServiceCalloutResult documentCalloutResult = new DocumentServiceCalloutResult();
        public External_Document__c document = new External_Document__c();
    }
}
