public with sharing class HubUsernameUpdate {
    @future(callout=true)
    public static void hubUsernameUpdateCallout(Set<Id> hubAccountIds) {
        AWSsampleAPIUtil.AuthToken at = AWSsampleAPIUtil.getAccessToken();

        List<Hub_Account__c> hubAccountsToUpdate = new List<Hub_Account__c>();
        List<Integration_Log__c> integrationListToInsert = new List<Integration_Log__c>();
        List<Hub_Account__c> hubAccountList = retrieveHubAccountRecords(hubAccountIds);
        List<Hub_Account__c> existingHubAccountList = retrieveExistingHubAccountList(hubAccountList);

        for (Hub_Account__c hubAccount : hubAccountList) {
            Hub_Account__c hubAccountInProgress = new Hub_Account__c(Id = hubAccount.Id);
            Boolean hubUsernameAlreadyExists = checkHubUsernameExists(
                hubAccount.BPP_Requested_Hub_Username__c,
                existingHubAccountList
            );
            if (hubUsernameAlreadyExists) {
                hubAccountInProgress.BPP_Requested_Hub_Username__c = null;
                hubAccountInProgress.BPP_Username_Update_Status__c = 'Error';
                hubAccountInProgress.BPP_Username_Error_Message__c =
                    'The requested username: "' +
                    hubAccount.BPP_Requested_Hub_Username__c +
                    '" is present on an existing Hub Account record.';
                hubAccountsToUpdate.add(hubAccountInProgress);
            } else {
                String response;
                String message;
                String body =
                    '{"user_id" : "' +
                    hubAccount.Auth0_Id__c +
                    '","email" : "' +
                    hubAccount.BPP_Requested_Hub_Username__c +
                    '"}';
                String endpoint = AWSsampleAPIUtil.retrieveAWSEndpoint() + '/user/username';

                HttpRequest httpRequest = new HttpRequest();
                httpRequest.setMethod('PATCH');
                httpRequest.setEndpoint(endpoint);
                httpRequest.setHeader('Authorization', 'Bearer ' + at.token);
                httpRequest.setHeader('Content-Type', 'application/json');
                httpRequest.setBody(body);

                Integration_Log__c integ = new Integration_Log__c();

                try {
                    HttpResponse httpResponse = new Http().send(httpRequest);
                    Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(
                        httpResponse.getBody()
                    );
                    message = (String) responseMap.get('message');
                    response = httpResponse.getStatusCode() + ': ' + httpResponse.getBody() + ' : ' + message;
                } catch (System.Exception e) {
                    response += ' : ' + String.valueOf(e.getMessage());
                } finally {
                    hubAccountInProgress.BPP_Requested_Hub_Username__c = null;
                    hubAccountsToUpdate.add(hubAccountInProgress);

                    integ = AWSsampleAPIUtil.createIntegrationLog('HUB', endpoint, response, hubAccount.Id);
                    integrationListToInsert.add(integ);
                }
            }
        }
        if (integrationListToInsert.size() > 0) {
            insert integrationListToInsert;
        }
        if (hubAccountsToUpdate.size() > 0) {
            update hubAccountsToUpdate;
        }
        if (!at.valid) {
            update at.authToken;
        }
    }

    private static List<Hub_Account__c> retrieveHubAccountRecords(Set<Id> hubAccountIds) {
        return new List<Hub_Account__c>(
            [
                SELECT Auth0_Id__c, BPP_Requested_Hub_Username__c, Student__c
                FROM Hub_Account__c
                WHERE Id IN :hubAccountIds
            ]
        );
    }

    private static List<Hub_Account__c> retrieveExistingHubAccountList(List<Hub_Account__c> hubAccountList) {
        Set<String> newHubUsernames = new Set<String>();
        for (Hub_Account__c hubAccount : hubAccountList) {
            newHubUsernames.add(hubAccount.BPP_Requested_Hub_Username__c);
        }
        return new List<Hub_Account__c>(
            [SELECT Name, Hub_Username__c FROM Hub_Account__c WHERE Hub_Username__c IN :newHubUsernames]
        );
    }

    private static Boolean checkHubUsernameExists(
        String requestedHubUsername,
        List<Hub_Account__c> existingHubAccountList
    ) {
        Boolean hubUsernameAlreadyExists = false;
        for (Hub_Account__c existingHubAccount : existingHubAccountList) {
            if (requestedHubUsername == existingHubAccount.Hub_Username__c) {
                hubUsernameAlreadyExists = true;
            }
        }
        return hubUsernameAlreadyExists;
    }
}
