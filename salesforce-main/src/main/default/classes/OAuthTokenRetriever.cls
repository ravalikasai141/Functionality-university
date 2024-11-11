global with sharing class OAuthTokenRetriever {
    /**
     * The named credential associated with events api
     */
    @TestVisible
    private String endpoint {
        get {
            System.Domain domain = System.DomainParser.parse(URL.getOrgDomainUrl());

            if (!String.isEmpty(domain.getSandboxName())) {
                return 'callout:OAuth_Test';
            } else {
                return 'callout:OAuth';
            }
        }
    }

    public Map<String, Authorisation_Token__c> getNewAccessToken() {
        Map<String, Authorisation_Token__c> accessTokenMap = new Map<String, Authorisation_Token__c>();
        Authorisation_Token__c authToken = new Authorisation_Token__c();
        String response;

        HttpRequest httpRequest = createRequest();
        try {
            Http http = new Http();
            HttpResponse httpResponse = http.send(httpRequest);
            Map<String, Object> respMap = (Map<String, Object>) JSON.deserializeUntyped(httpResponse.getBody());
            if (httpResponse.getStatusCode() == 200) {
                authToken.Access_Token__c = (String) respMap.get('access_token');
                authToken.Expires_In__c = (Integer) respMap.get('expires_in');
                authToken.Scope__c = (String) respMap.get('scope');
                authToken.Authorisation_Type__c = 'BPP API Gateway';
                accessTokenMap.put(httpResponse.getBody(), authToken);
            } else {
                response = 'Error: ' + (String) respMap.get('error') + ' - ' + (String) respMap.get('error_description');
                accessTokenMap.put(response, null);
            }
        } catch (Exception e) {
            response = 'Error: [' + e.getLineNumber() + '] ' + e.getMessage();
            accessTokenMap.put(response, null);
        }

        return accessTokenMap;
    }

    /**
     * Creates an HTTP request with the necessary parameters for client credentials grant type authentication.
     *
     * @return An HTTP request object configured with the endpoint, method, headers and payload.
     */
    private HttpRequest createRequest() {
        HttpRequest httpRequest = new HttpRequest();
        httpRequest.setEndpoint(endpoint);
        httpRequest.setMethod('POST');
        httpRequest.setHeader('Content-Type', 'application/x-www-form-urlencoded');

        String payload =
            'grant_type=client_credentials' +
            '&client_id={!$Credential.OAuth.ClientId}' +
            '&client_secret={!$Credential.OAuth.ClientSecret}' +
            '&audience={!$Credential.OAuth.Audience}';
        httpRequest.setBody(payload);

        return httpRequest;
    }
}