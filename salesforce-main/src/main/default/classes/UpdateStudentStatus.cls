@RestResource(urlMapping='/v1.0/UpdateStudentStatus/*')
global with sharing class UpdateStudentStatus {
    global class Response {    
        global String status { get; set; }        
        public Response(String status) {      
            this.status = status;    
        }  
    }

    global class Request {
        global String profileId { get; set; }
        global String studentStatus { get; set; }
    }
     
    @HttpPost    
    global static Response doPost(List<Request> statusUpdateList) {
        Map<String, String> requestMap = new Map<String, String>();
        for (Request req : statusUpdateList) {
            requestMap.put(req.profileId, req.studentStatus);
        } 
        
        List<Contact> contactList = [SELECT Id, BNR_Student_Status_Code__c, PS_Profile_Services_ID__c
                                     FROM Contact
                                     WHERE PS_Profile_Services_ID__c IN :requestMap.keySet()];
                                     
        for (Contact c : contactList) {
            c.BNR_Student_Status_Code__c = requestMap.get(c.PS_Profile_Services_ID__c); 
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
        req.studentStatus = 'AS';
        lstRequest.add(req);
        UpdateStudentStatus.Response res = UpdateStudentStatus.doPost(lstRequest);     
    } 
}