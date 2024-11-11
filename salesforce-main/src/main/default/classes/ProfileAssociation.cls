global with sharing class ProfileAssociation {
	public static Boolean bFailProf = false;
	public static string endPoint = '/rest/profile/v1/association';
	/*
    * Three services are called here: Association of Company and Training manager
    * Association of Training manager and Student and
    * Association of Company and Student.
	* Source,target and corresponding association type for these services are sent over.
	*/
	 
    public class profassociation{
    	public insertProfileAssociationDTO insertProfileAssociationRequest = new insertProfileAssociationDTO();
    }
    
    public class insertProfileAssociationDTO{
        public String sourceProfileId;
        public String targetProfileId;
        public String associationType;
    }
    
    @future(callout=true)
	public static void srcTargetProfileAssociation(string sourceProfileId,string targetProfileId,string associationType,string recordId){
		profassociation pro = new profassociation();
		pro.insertProfileAssociationRequest.sourceProfileId = sourceProfileId;
		pro.insertProfileAssociationRequest.targetProfileId = targetProfileId;
		pro.insertProfileAssociationRequest.associationType = associationType;
		string request = Json.serialize(pro);
		string strRes = callService(Json.serialize(pro));
		/*if(strRet.contains('Error')){
        	spon.Last_Error__c = spon.Last_Error__c + ' AssociateStudentToTMService: '+strRet;
        }
        update spon;*/
        Integration_Log__c integrationLog = new Integration_Log__c();
        integrationLog.Integration_Type__c = 'Insert: '+associationType;
        integrationLog.Salesforce_ID__c = recordId;
        integrationLog.Request__c = request;
        integrationLog.Response__c = strRes;
        insert integrationLog; 			 
	}	
	
	public static String callService(String jsonRequest) {
    	String result;    	
    	Http http = new Http();
    	Httprequest req = BPPIntegrationConfig.callRestService(jsonRequest, 'application/json', endPoint);
        
        HttpResponse res = null;
        if (Test.isRunningTest()){
        	res = new HttpResponse();
        	if (bFailProf){
        		res.setStatus('Internal Error');
                res.setStatusCode(500);
                String strErrorSoap = '{"self":"null","httpMethod":"POST","errorMessage":"Cannot find Company or Profile Record for the specified Id: 1231231231","errorCode":"PLATFORM-801","transactionId":"A563C5CD-4CA9-B1C6-392A-09377720BFAC"}';
                res.setBody(strErrorSoap);
        	}
        	else{
        		String strResponse = '{"insertProfileAssociationResponse":{"isSuccessful":true}}';    
        		res.setStatusCode(200);
            	res.setStatus('OK');
            	res.setBody(strResponse);
        	}
        }
        else{
            res = http.send(req);
        }
        system.debug(jsonRequest);
        system.debug(res.getStatus());
        system.debug(res.getBody());
        if (res.getStatus() == 'OK' && res.getStatusCode() == 200){
            result = 'Success';
        }
        else{
          	JSONParser jParser = JSON.createParser(res.getBody());
               	while(jParser.nextToken() !=null){
               		if((jParser.getCurrentToken() == JSONToken.FIELD_NAME)){
               			string fieldN = jParser.getText();
               			jParser.nextToken();
               			if(fieldN == 'errorMessage'){
               				result = jParser.getText();
               				system.debug('errorMessage' + result);
               				break;
               			}
               		}
               	}
            result = 'Error: ' + result;
        }
        return res.getBody();//result;
    }
    
    public class profdelassociation{
    	public deleteProfileAssociationDTO deleteProfileAssociationRequest = new deleteProfileAssociationDTO();
    }
    
    public class deleteProfileAssociationDTO{
        public String sourceProfileId;
        public String targetProfileId;
        public String associationType;
    }
    
    @future(callout=true)
	public static void srcTargetdeleteProfileAssociation(string sourceProfileId,string targetProfileId,string associationType,string recordId){
		profdelassociation prod = new profdelassociation();
		prod.deleteProfileAssociationRequest.sourceProfileId = sourceProfileId;
		prod.deleteProfileAssociationRequest.targetProfileId = targetProfileId;
		prod.deleteProfileAssociationRequest.associationType = associationType;
		string request = Json.serialize(prod);
		string EndP = endPoint + '?sourceProfileId=' + sourceProfileId + '&associationType=' + associationType + '&targetProfileId=' + targetProfileId;
		string strRes = callDelService(Json.serialize(prod), EndP);
		
		Integration_Log__c integrationLog = new Integration_Log__c();
        integrationLog.Integration_Type__c = 'Delete: '+associationType;
        integrationLog.Salesforce_ID__c = recordId;
        integrationLog.Request__c = request;
        integrationLog.Response__c = strRes;
        insert integrationLog;
	}
	
    public static String callDelService(String jsonRequest, String Endpt) {
    	String result;    	
    	Http http = new Http();
    	Httprequest req = BPPIntegrationConfig.callDelRestService('application/json', Endpt);
        
        HttpResponse res = null;
        if (Test.isRunningTest()){
        	res = new HttpResponse();
        	if (bFailProf){
        		res.setStatus('Internal Error');
                res.setStatusCode(500);
                String strErrorSoap = '{"self":"null","httpMethod":"DELETE","errorMessage":"Cannot find Company or Profile Record for the specified Id: 1231231231","errorCode":"PLATFORM-801","transactionId":"A563C5CD-4CA9-B1C6-392A-09377720BFAC"}';
                res.setBody(strErrorSoap);
        	}
        	else{
        		String strResponse = '{"deleteProfileAssociationResponse":{"isSuccessful":true}}';    
        		res.setStatusCode(200);
            	res.setStatus('OK');
            	res.setBody(strResponse);
        	}
        }
        else{
            res = http.send(req);
        }
        system.debug(jsonRequest);
        system.debug(res.getStatus());
        system.debug(res.getBody());
        if (res.getStatus() == 'OK' && res.getStatusCode() == 200){
            result = 'Success';
        }
        else{
          	JSONParser jParser = JSON.createParser(res.getBody());
               	while(jParser.nextToken() !=null){
               		if((jParser.getCurrentToken() == JSONToken.FIELD_NAME)){
               			string fieldN = jParser.getText();
               			jParser.nextToken();
               			if(fieldN == 'errorMessage'){
               				result = jParser.getText();
               				system.debug('errorMessage' + result);
               				break;
               			}
               		}
               	}
            result = 'Error: ' + result;
        }
        return res.getBody();//result;
    }
}