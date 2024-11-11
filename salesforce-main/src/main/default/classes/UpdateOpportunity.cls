@RestResource(urlMapping='/v1.0/UpdateApplication/*')
global with sharing class UpdateOpportunity {
    
    global class Response {
        global String status { get; set; }
        
        public Response(String status) {
            this.status = status;
        }
    }
    
    @HttpPost
    global static Response doPost(List<Opportunity> opportunityList) {
        try {           
            update opportunityList;  
            return new Response('Success');
        } catch (Exception e) { 
            return new Response('Failure');
        }
    }
    
    @isTest
    private static void unitTest1(){
        list<Opportunity> opptyLists = new list<Opportunity>();
        Opportunity Oppty = new Opportunity();
        Oppty.StageName = 'Application Submitted';
        opptyLists.add(Oppty);
        UpdateOpportunity.Response res = UpdateOpportunity.doPost(opptyLists);  
    }
    @isTest
    private static void unitTest2(){    
        list<Opportunity> opptyLists = new list<Opportunity>();
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
        
        Opportunity Oppty = new Opportunity();
        oppty.AccountId = a.id;
        oppty.Name = 'test';
        oppty.Cycle_Override__c = 'Use Student Cycle';
        oppty.CloseDate = Date.valueOf('2015-02-27');      
        oppty.StageName = 'Review';
        oppty.BNR_Application_Decision_Code__c = 'test';
        insert oppty;
        opptyLists.add(Oppty);
        UpdateOpportunity.Response res = UpdateOpportunity.doPost(opptyLists);   
    }     
}