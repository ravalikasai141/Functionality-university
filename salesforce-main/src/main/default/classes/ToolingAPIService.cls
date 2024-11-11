public with sharing class ToolingAPIService {
    
/** Method to update remote site settings */

    public static Boolean createUpdateRemoteSiteSetting(Id settingId, String name, String description, String url, String apiVersion, String session){
        if(String.isBlank(apiVersion)){
            apiVersion = '47.0';
        }
        if(String.isBlank(session)){
            session = UserInfo.getSessionID();
        }
        
        //prepare metadata for setting
        Map<String, Object> metadata = new Map<String, Object>();
        metadata.put('description', description);
        metadata.put('isActive', false);
        metadata.put('url', url+'xx');
        
        //prepare map for request body
        Map<String, Object> jsonObj= new Map<String, Object>();
        jsonObj.put('FullName', name);
        jsonObj.put('Metadata', metadata);
        
        String json = JSON.serialize(jsonObj);
        System.debug(json);
        String endpoint = String.valueOf(System.Url.getOrgDomainUrl().toExternalForm()) +'/services/data/v'+apiVersion+'/tooling/sobjects/RemoteProxy/';
        string method  = 'POST';
        
        //for update, make a patch request
        if(settingId != null){
            endpoint = endpoint + (settingId + '?_HttpMethod=PATCH');
        }
        
        System.debug('endpoint::'+endpoint);
        
        HttpRequest request = new HttpRequest();
        request.setHeader('Authorization', 'Bearer ' + session);
        request.setHeader('Content-Type', 'application/json');
        request.setEndpoint(endpoint);
        request.setMethod(method);
        request.setBody(json); 
        
        Http http = new Http();
        HttpResponse response = http.send(request);
        String jsonReponse = response.getBody();
        System.Debug('**** Remote Site Response: ' +  jsonReponse);
        
        //patch request is success
        if(settingId != null && String.isBlank(jsonReponse)){
            return true;
        }else{
            List<Object>results = (List<Object>)System.JSON.deserializeUntyped(jsonReponse);
            Map<String, object> mresults = (Map<String, object>)System.JSON.deserializeUntyped(System.JSON.serialize(results[0]));
            if(mresults.get('success') == true){
                return true;
            }else{
                return false;
            }
        }
    }
    
    public static List<RemoteSiteSetting> getRemoteSiteSettings(String apiVersion, String session){
        if(String.isBlank(apiVersion)){
            apiVersion = '47.0';
        }
        if(String.isBlank(session)){
            session = UserInfo.getSessionID();
        }
        
        String endpoint = String.valueOf(System.URL.getOrgDomainUrl().toExternalForm())+'/services/data/v'+apiVersion+'/tooling/query?q=Select+Id,+EndpointUrl,+Description,+IsActive,+SiteName+from+RemoteProxy';
        string method  = 'GET';
        
        HttpRequest request = new HttpRequest();
        request.setHeader('Authorization', 'Bearer ' + session);
        request.setHeader('Content-Type', 'application/json');
        request.setEndpoint(endpoint);
        request.setMethod(method); 
        
        Http http = new Http();
        HttpResponse response = http.send(request);
        RemoteSiteSettings result = (RemoteSiteSettings)JSON.deserialize(response.getBody(), ToolingAPIService.RemoteSiteSettings.class);
        return result.records;
    } 
    
    public class RemoteSiteSettings{
        public List<RemoteSiteSetting> records;
    }
    
    public class RemoteSiteSetting{
        public String Id;
        public String EndpointUrl;
        public String Description;
        public Boolean IsActive;
        public String SiteName;
    }
}