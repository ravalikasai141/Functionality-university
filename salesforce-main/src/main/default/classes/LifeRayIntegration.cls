global with sharing class LifeRayIntegration {
    public static string createUserEndpoint = '/rest/login/v1/create/user';
    
    WebService static String CreateUser(String userProfileId) {
        String jsonRequest = '{"CreateUserRequest":{"userProfileId":["' + userProfileId + '"]}}';
        
        System.debug(jsonRequest);
        Http http = new Http();
        HttpRequest req = BPPIntegrationConfig.callRestService(jsonRequest, 'application/json', createUserEndpoint);
        HttpResponse res = http.send(req);
        
        System.debug('Service Response: ' + res.getBody()); 
        
        Integration_Log__c integrationLog = new Integration_Log__c();
        integrationLog.Integration_Type__c = 'Liferay Provisioning';
        integrationLog.Salesforce_ID__c = userProfileId;
        integrationLog.Request__c = jsonRequest;
        integrationLog.Response__c = res.getStatus();
        insert integrationLog;     
         
        return 'Success';  
    }
}