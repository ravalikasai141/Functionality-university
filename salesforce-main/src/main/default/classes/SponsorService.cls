global with sharing class SponsorService{
  public static Boolean bFailProf = false;
  public static string create_endPoint = '/rest/soa/banner/sponsor/v1/create';
  //public static string update_endPoint = '/rest/soa/banner/sponsor/v1/update';  
  public static string inactivate_endPoint = '/rest/soa/banner/sponsor/v1/inactivate';  
  
  
  //CreateSponsorAssociation
  public class createSponAssociation{
      public createSponAssociationDTO createSponsorAssociationRequest = new createSponAssociationDTO();
  }
    
  public class createSponAssociationDTO{
      public String StudentProfileID;
      public String CompanyProfileID;
      public String SponsorshipLevel;
      public String SponsorshipAmount;
      public String SponsorshipPercentage;
  }
    
  @future(callout=true)
  public static void createSponsorAssociation(string StudentProfileID, string CompanyProfileID, string SponsorshipLevel, string SponsorshipAmount, string SponsorshipPercentage, string recordId){
    createSponAssociation pro = new createSponAssociation();
    pro.createSponsorAssociationRequest.StudentProfileID = StudentProfileID;
    pro.createSponsorAssociationRequest.CompanyProfileID = CompanyProfileID;
    pro.createSponsorAssociationRequest.SponsorshipLevel = SponsorshipLevel;  
    pro.createSponsorAssociationRequest.SponsorshipAmount = SponsorshipAmount;  
    pro.createSponsorAssociationRequest.SponsorshipPercentage = SponsorshipPercentage;  
    
    string request = Json.serialize(pro);
    string strRes = callCreateService(Json.serialize(pro));
    /*if(strRet.contains('Error')){
          spon.Last_Error__c = spon.Last_Error__c + ' AssociateStudentToTMService: '+strRet;
        }
        update spon;*/
        Integration_Log__c integrationLog = new Integration_Log__c();
        integrationLog.Integration_Type__c = 'createSponAssociation';
        integrationLog.Salesforce_ID__c = recordId;
        integrationLog.Request__c = request;
        integrationLog.Response__c = strRes;
        insert integrationLog;        
  }  
  
  public static String callCreateService(String jsonRequest) {
      String result;      
      Http http = new Http();
      Httprequest req = BPPIntegrationConfig.callRestService(jsonRequest, 'application/json', create_endPoint);
        
        HttpResponse res = null;
        if (Test.isRunningTest()){
          res = new HttpResponse();
          if (bFailProf){
            //res.setStatus('Internal Error');
            //    res.setStatusCode(500);
            //    String strErrorSoap = '{"self":"null","httpMethod":"POST","errorMessage":"Cannot find Company or Profile Record for the specified Id: 1231231231","errorCode":"PLATFORM-801","transactionId":"A563C5CD-4CA9-B1C6-392A-09377720BFAC"}';
            //    res.setBody(strErrorSoap);
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
    
  /*Not being used
  //UpdateStudentSponsorship  
  public class updateStudentSponsor{
      public updateStudentSponsorDTO updateStudentSponsorshipRequest = new updateStudentSponsorDTO();
  }
    
  public class updateStudentSponsorDTO{
      public String StudentProfileID;
      public String CompanyProfileID;
      public String SponsorshipLevel;
      public String SponsorshipAmount;
      public String SponsorshipPercentage;
      public String OldCompanyProfileID;
  }
    
  @future(callout=true)
  public static void updateStudentSponsorship(string StudentProfileID, string CompanyProfileID, string SponsorshipLevel, string SponsorshipAmount, string SponsorshipPercentage, string OldCompanyProfileID, string recordId){
    updateStudentSponsor pro_update = new updateStudentSponsor();
    pro_update.updateStudentSponsorshipRequest.StudentProfileID = StudentProfileID;
    pro_update.updateStudentSponsorshipRequest.CompanyProfileID = CompanyProfileID;
    pro_update.updateStudentSponsorshipRequest.SponsorshipLevel = SponsorshipLevel;  
    pro_update.updateStudentSponsorshipRequest.SponsorshipAmount = SponsorshipAmount;  
    pro_update.updateStudentSponsorshipRequest.SponsorshipPercentage = SponsorshipPercentage;  
    pro_update.updateStudentSponsorshipRequest.OldCompanyProfileID = OldCompanyProfileID;
      
    string request = Json.serialize(pro_update);
    string strRes = callUpdateService(Json.serialize(pro_update));
    //if(strRet.contains('Error')){
    //      spon.Last_Error__c = spon.Last_Error__c + ' AssociateStudentToTMService: '+strRet;
    //    }
    //    update spon;
    
        Integration_Log__c integrationLog = new Integration_Log__c();
        integrationLog.Integration_Type__c = 'updateStudentSponsor';
        integrationLog.Salesforce_ID__c = recordId;
        integrationLog.Request__c = request;
        integrationLog.Response__c = strRes;
        insert integrationLog;        
  }  
  
  public static String callUpdateService(String jsonRequest) {
      String result;      
      Http http = new Http();
      Httprequest req = BPPIntegrationConfig.callRestService(jsonRequest, 'application/json', update_endPoint);
        
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
  */    
      
  //InactivateSponsorAssociation
  public class inactivateSponAssociation{
      public inactivateSponAssociationDTO inactivateSponsorAssociationRequest = new inactivateSponAssociationDTO();
  }
    
  public class inactivateSponAssociationDTO{
      public String StudentProfileID;
      public String CompanyProfileID;
  }
    
  @future(callout=true)
  public static void inactivateSponsorAssociation(string StudentProfileID, string CompanyProfileID, string recordId){
    inactivateSponAssociation pro_inactivate = new inactivateSponAssociation();
    pro_inactivate.inactivateSponsorAssociationRequest.StudentProfileID = StudentProfileID;
    pro_inactivate.inactivateSponsorAssociationRequest.CompanyProfileID = CompanyProfileID;

    string request = Json.serialize(pro_inactivate);
    string strRes = callInactivateService(Json.serialize(pro_inactivate));
    /*if(strRet.contains('Error')){
          spon.Last_Error__c = spon.Last_Error__c + ' AssociateStudentToTMService: '+strRet;
        }
        update spon;*/
        Integration_Log__c integrationLog = new Integration_Log__c();
        integrationLog.Integration_Type__c = 'inactivateSponAssociation';
        integrationLog.Salesforce_ID__c = recordId;
        integrationLog.Request__c = request;
        integrationLog.Response__c = strRes;
        insert integrationLog;        
  }  
  
  public static String callInactivateService(String jsonRequest) {
      String result;      
      Http http = new Http();
      Httprequest req = BPPIntegrationConfig.callRestService(jsonRequest, 'application/json', inactivate_endPoint);
        
        HttpResponse res = null;
        if (Test.isRunningTest()){
          res = new HttpResponse();
          if (bFailProf){
            //res.setStatus('Internal Error');
            //    res.setStatusCode(500);
            //    String strErrorSoap = '{"self":"null","httpMethod":"POST","errorMessage":"Cannot find Company or Profile Record for the specified Id: 1231231231","errorCode":"PLATFORM-801","transactionId":"A563C5CD-4CA9-B1C6-392A-09377720BFAC"}';
            //    res.setBody(strErrorSoap);
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
}