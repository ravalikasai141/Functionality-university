global with sharing class HubAccountPasswordResetCallout {

    private static final String ERROR_RESULT        = '\nPlease contact IT Service Desk.'; 
    private static final String RESPONSE_SUCCESS    = 'Success'; 
    private static final String RESPONSE_ERROR      = '\nError: '; 

    /**
     * The named credential associated with events api
     */
    @TestVisible
    private String endpoint {
        get {
            System.Domain domain = System.DomainParser.parse(URL.getOrgDomainUrl());

            if (!String.isEmpty(domain.getSandboxName())) {
                return 'callout:Identity_API_Test';
            } else {
                return 'callout:Identity_API';
            }
        }
    }

    public String hubPasswordReset(Hub_Account__c hubAccount) {
        String response, responseToUser, message;
        List<Hub_Account__c> hubAccountToUpdate = new List<Hub_Account__c>();
        Integration_Log__c integ = new Integration_Log__c();

        if (hubAccount == null) {
            return response;
        } else {
            try {
                    String body = hubAccount.Auth0_Id__c;
                    Http http = new Http();
                    HttpResponse httpResponse = http.send(createRequest(body));
                    response = httpResponse.getStatusCode() + ': ' + httpResponse.getBody();
                    message = httpResponse.getBody();

                    if (httpResponse.getStatusCode() == 200) {
                        hubAccountToUpdate.add(hubAccount);
                        responseToUser = RESPONSE_SUCCESS;
                    } else {
                        responseToUser = RESPONSE_ERROR + message + ERROR_RESULT;
                    }
                } catch (System.Exception e) {
                    responseToUser = RESPONSE_ERROR + String.valueOf(e.getMessage()) + ERROR_RESULT;
                    response += ' : ' + String.valueOf(e.getMessage());
                } finally {
                    integ = AWSsampleAPIUtil.createIntegrationLog('HUB', endpoint, response, hubAccount.Id);
                    insert integ;

                    if (!hubAccountToUpdate.isEmpty()) {
                        update hubAccountToUpdate;
                    }
                }
			
        }
        return responseToUser;
    }

    /**
     *
     * @param body serialized payload to send
     * @return  HttpRequest
     */
    private HttpRequest createRequest(String body) {
        HttpRequest request = new HttpRequest();
        request.setEndpoint(endpoint);
        request.setMethod('POST');
        request.setHeader('Content-Type', 'application/json');
        request.setHeader('x-api-key', '{!$Credential.Password}');
        request.setBody(body);

        return request;
    }
}