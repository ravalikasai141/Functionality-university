@RestResource(urlMapping='/v1.0/UpdateStudentProvisioning/*')
global with sharing class UpdateStudentProvisioning {
    global class Response {    
        global String status { get; set; }        
        public Response(String status) {      
            this.status = status;    
        }  
    }

    global class Request {
        global String profileId { get; set; }
        global String userName { get; set; }
        global String passWord { get; set; }
        global String emailAddress { get; set; }
    }
     
    @HttpPost    
    global static Response doPost(List<Request> provisioningUpdateList) {
        Map<String, String> requestUserNameMap = new Map<String, String>();
        Map<String, String> requestPassWordMap = new Map<String, String>();
        Map<String, String> requestEmailAddressMap = new Map<String, String>();
        for (Request req : provisioningUpdateList) {
            requestUserNameMap.put(req.profileId, req.userName);
            requestPassWordMap.put(req.profileId, req.passWord);
            requestEmailAddressMap.put(req.profileId, req.emailAddress);
        } 
        
        List<Contact> contactList = [SELECT Id, PS_Profile_Services_ID__c, Username__c, Password__c, Email_Address__c FROM Contact WHERE PS_Profile_Services_ID__c IN :requestUserNameMap.keySet()];
        for (Contact c : contactList) {
            c.Username__c = requestUserNameMap.get(c.PS_Profile_Services_ID__c); 
            c.Password__c = requestPassWordMap.get(c.PS_Profile_Services_ID__c);
            c.Email_Address__c = requestEmailAddressMap.get(c.PS_Profile_Services_ID__c);
            if (c.BPP_Email__c == null && (requestEmailAddressMap.get(c.PS_Profile_Services_ID__c).contains('my.bpp.com') || requestEmailAddressMap.get(c.PS_Profile_Services_ID__c).contains('@my.apolloglobaluat.com'))) {
                c.BPP_Email__c = requestEmailAddressMap.get(c.PS_Profile_Services_ID__c);
            }
        }        
        update contactList;
        
        return new Response('Success');
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
        
        List<Request> lstRequest = new List<Request>();
        Request req = new Request();
        req.profileId = '1234f567-bc23-42e8-924c-1234asdf5678';
        req.userName = 'testuser';
        req.passWord = 'testpassword';
        req.emailAddress = 'testuser@abc.com';
        lstRequest.add(req);
        UpdateStudentProvisioning.Response res = UpdateStudentProvisioning.doPost(lstRequest);     
    } 
}