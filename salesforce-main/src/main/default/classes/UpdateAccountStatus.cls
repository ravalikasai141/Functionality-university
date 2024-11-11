@RestResource(urlMapping='/v1.0/UpdateAccountStatus/*')
global with sharing class UpdateAccountStatus {
  global class Response {    
        global String status { get; set; }        
        public Response(String status) {      
            this.status = status;    
        }  
    }
    
  global class AccountStatusDTO {
    public string profileId { get; set; }
    public string accountStatusCode { get; set; }
    public string reasonCode { get; set; }
    public string displayableMessage { get; set; }
  }
  
  @HttpPost
    global static Response doPost() {
        Response response;
        RestRequest req = RestContext.request;
        String reqStr = req.requestBody.toString();
        system.debug(reqStr);
        
        list<AccountStatusDTO> accStatus = (list<AccountStatusDTO>)JSON.deserialize(reqStr, list<AccountStatusDTO>.class);
        if(accStatus.size()>0){
          map<string,AccountStatusDTO> mapProfileAcc = new map<string,AccountStatusDTO>();
          for(AccountStatusDTO tempASD: accStatus){
            mapProfileAcc.put(tempASD.profileId,tempASD);
          }
            
          list<Account> lstStudentAcc = [Select a.PS_Profile_Services_ID__pc, a.AR_Reason_Code__c, a.AR_Displayable_Message__c, a.AR_Account_Status_Code__c 
                             From Account a where a.PS_Profile_Services_ID__pc in :mapProfileAcc.keyset()];
          
            list<Account> lstCompanyAcc = [Select a.Profile_Company_ID__c, a.AR_Reason_Code__c, a.AR_Displayable_Message__c, a.AR_Account_Status_Code__c 
                       From Account a where a.Profile_Company_ID__c in :mapProfileAcc.keyset()];
            
            if(lstStudentAcc.size()>0 || lstCompanyAcc.size()>0) {
                if(lstStudentAcc.size()>0){  
                    for(Account tempAcc: lstStudentAcc){
                        AccountStatusDTO asd = mapProfileAcc.get(tempAcc.PS_Profile_Services_ID__pc);
                        tempAcc.AR_Account_Status_Code__c = asd.accountStatusCode;
                        tempAcc.AR_Reason_Code__c = asd.reasonCode;
                        tempAcc.AR_Displayable_Message__c = asd.displayableMessage;
                    }
                    update lstStudentAcc;
                    response = new Response('Success');
                }
                
                if(lstCompanyAcc.size()>0){  
                    for(Account tempAcc: lstCompanyAcc){
                        AccountStatusDTO asd = mapProfileAcc.get(tempAcc.Profile_Company_ID__c);
                        tempAcc.AR_Account_Status_Code__c = asd.accountStatusCode;
                        tempAcc.AR_Reason_Code__c = asd.reasonCode;
                        tempAcc.AR_Displayable_Message__c = asd.displayableMessage;
                    }
                    update lstCompanyAcc;
                    response = new Response('Success');
                }
            }          
            else{
            response = new Response('Profile Id incorrect');
          }
            
        }
        else{
          response = new Response('Json is empty');
        }
        return response;
    }
    
    @isTest
    public static void unitTest1(){
      Account a = new Account();
        a.firstname='John';
        a.lastname='Coppedge';
        a.Salutation = 'Mr';
        a.Middle_Name__pc = 'Mex';
        a.Gender__pc = 'Male';
        a.RecordTypeId=Schema.sObjectType.Account.getRecordTypeInfosByName().get('Student Account').getRecordTypeId();
        a.Preferred_Email__pc = 'Personal';
        a.Preferred_Phone__pc = 'Mobile';
        a.Personal_Email__pc ='john@john.com';
        a.PersonMobilePhone='8015555556';
        a.PersonBirthdate=Date.valueOf('1986-02-27');
        a.PS_Profile_Services_ID__pc = '1234f567-bc23-42e8-924c-1234asdf5678';
        a.Student_Cycle__c = 'Pursue';
        a.Student_Type__pc = 'Domestic';
        insert a;
        
        List<AccountStatusDTO> lstASD = new List<AccountStatusDTO>();
        AccountStatusDTO asd= new AccountStatusDTO();
        asd.profileId = '1234f567-bc23-42e8-924c-1234asdf5678';
        asd.accountStatusCode = '354';
      asd.reasonCode = '43543';
      asd.displayableMessage = 'terils';
      
        lstASD.add(asd);
        RestRequest request = new RestRequest();
        request.addHeader('Content-Type','application/json');
        request.requestBody = Blob.valueof(Json.serialize(lstASD));
        RestContext.request = request;
        
        UpdateAccountStatus.Response res = UpdateAccountStatus.doPost();     
        asd.profileId = '1234f567-bc23-42e8-924c-1234asdf56744';
        request.requestBody = Blob.valueof(Json.serialize(lstASD));
        RestContext.request = request;
        
        res = UpdateAccountStatus.doPost();
    } 
    
    @isTest
    public static void unitTest2(){
      Account a = new Account();
        a.firstname='John';
        a.lastname='Coppedge';
        a.Salutation = 'Mr';
        a.Middle_Name__pc = 'Mex';
        a.Gender__pc = 'Male';
        a.RecordTypeId=Schema.sObjectType.Account.getRecordTypeInfosByName().get('Student Account').getRecordTypeId();
        a.Preferred_Email__pc = 'Personal';
        a.Preferred_Phone__pc = 'Mobile';
        a.Personal_Email__pc ='john@john.com';
        a.PersonMobilePhone='8015555556';
        a.PersonBirthdate=Date.valueOf('1986-02-27');
        a.Profile_Company_ID__c = '1234f567-bc23-42e8-924c-1234asdf5678';
        a.Student_Cycle__c = 'Pursue';
        a.Student_Type__pc = 'Domestic';
        insert a;
        
        List<AccountStatusDTO> lstASD = new List<AccountStatusDTO>();
        AccountStatusDTO asd= new AccountStatusDTO();
        asd.profileId = '1234f567-bc23-42e8-924c-1234asdf5678';
        asd.accountStatusCode = '354';
      asd.reasonCode = '43543';
      asd.displayableMessage = 'terils';
      
        lstASD.add(asd);
        RestRequest request = new RestRequest();
        request.addHeader('Content-Type','application/json');
        request.requestBody = Blob.valueof(Json.serialize(lstASD));
        RestContext.request = request;
        
        UpdateAccountStatus.Response res = UpdateAccountStatus.doPost();     
        asd.profileId = '1234f567-bc23-42e8-924c-1234asdf56744';
        request.requestBody = Blob.valueof(Json.serialize(lstASD));
        RestContext.request = request;
        
        res = UpdateAccountStatus.doPost();
    }   
}