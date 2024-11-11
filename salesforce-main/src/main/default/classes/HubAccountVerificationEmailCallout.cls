global with sharing class HubAccountVerificationEmailCallout {
    webService static String sendVerificationEmail(Hub_Account__c hubAccount) {
        if (hubAccount == null) {
            return null;
        }

        String response;
        String responseToUser;
        List<Hub_Account__c> hubAccountToUpdate = new List<Hub_Account__c>();

        AWSsampleAPIUtil.AuthToken at = AWSsampleAPIUtil.getAccessToken();

        String body = '{"userId" : "' + hubAccount.Auth0_Id__c + '"}';
        String endpoint = AWSsampleAPIUtil.retrieveAWSEndpoint() + '/user/username/verify';

        HttpRequest httpRequest = new HttpRequest();
        httpRequest.setMethod('POST');
        httpRequest.setEndpoint(endpoint);
        httpRequest.setHeader('Authorization', 'Bearer ' + at.token);
        httpRequest.setHeader('Content-Type', 'application/json');
        httpRequest.setBody(body);

        Integration_Log__c integ = new Integration_Log__c();
        try {
            HttpResponse httpResponse = new Http().send(httpRequest);
            response = httpResponse.getStatusCode() + ': ' + httpResponse.getBody();

            if (httpResponse.getStatusCode() == 200) {
                hubAccountToUpdate.add(hubAccount);
                responseToUser = 'Success';
            } else {
                String message;
                if (response.length() > 5) {
                    Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(
                        httpResponse.getBody()
                    );
                    message = (String) responseMap.get('message');
                } else {
                    message = 'Something went wrong. Please contact your Salesforce Administrator.';
                }
                responseToUser = '\nError: ' + message;
            }
        } catch (System.Exception e) {
            responseToUser = '\nError: ' + String.valueOf(e.getMessage());
            response += ' : ' + String.valueOf(e.getMessage());
        } finally {
            integ = AWSsampleAPIUtil.createIntegrationLog('HUB', endpoint, response, hubAccount.Id);
            insert integ;

            if (hubAccountToUpdate.size() > 0) {
                update hubAccountToUpdate;
            }

            if (!at.valid) {
                update at.authToken;
            }
        }

        return responseToUser;
    }
}
