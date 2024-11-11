global with sharing class OutboundChecklistService {
    private static final String soapEnv = 'xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" ';
    private static final String v1 = 'xmlns:v1="http://platform.apollogrp.edu/services/apolloglobal/banner/admission/v1" ';
    private static final String chec = 'xmlns:chec="http://platform.apollogrp.edu/model/apolloglobal/banner/v1/Checklist">';
    private static Boolean bFailChecklist = false;
    
    @future(callOut=true)
    public static void UpdateOpptyChecklistInfo(String OpportunityId) {
        String query = Util.getAllFieldsSOQL('Opportunity', 'Id = \'' + OpportunityId + '\'');
        Opportunity newOpp = Database.query(query);
        String requestStr = '<soapenv:Envelope ' + soapEnv + v1 + chec +
            '  <soapenv:Header/>' +
            '  <soapenv:Body>' +
            '    <v1:addOrUpdateChecklistRequest>' +
            '       <chec:checklist>';
        
        requestStr += '<chec:OpportunityId>' + newOpp.Id + '</chec:OpportunityId>';
        
        Map<string, string> banner = ChecklistServices.getChecklistFields();
        for (string temp: banner.keyset()){
            String field = banner.get(temp);
            Date dValue = (Date)newOpp.get(banner.get(temp));
            String sDate = String.valueOf(dValue);
            requestStr += '<chec:ChecklistDetail>';
            requestStr += '<chec:ChecklistCode>' + temp + '</chec:ChecklistCode>';
            if (sDate != null && sDate != ''){
                requestStr += '<chec:ReceivedDate>' + sDate + '</chec:ReceivedDate>';
            }
            requestStr += '</chec:ChecklistDetail>';
        } 
        requestStr += '</chec:checklist></v1:addOrUpdateChecklistRequest>' + 
            '</soapenv:Body></soapenv:Envelope>';
        
        Http h = new Http();
        HttpRequest req = BPPIntegrationConfig.getData(requestStr);
        req.setTimeout(120000);
        system.debug('xml' + requestStr);   
        system.debug(req.toString());
        HttpResponse res = null;
        if (Test.isRunningTest()){
            res = new HttpResponse();
            if (bFailChecklist){
                res.setStatus('Internal Error');
                res.setStatusCode(500);
                String strErrorSoap = '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/">' + 
                                    '<soapenv:Header><gateway:' + 
                                    'transactionId xmlns:gateway="http://platform.apollogrp.edu/gateway">' + 
                                    'A4A3BF60-2BB1-2EFA-E334-8B03BE650CD0</gateway:transactionId>' + 
                                    '</soapenv:Header>' + 
                                    '<soapenv:Body>' +
                                    '<soapenv:Fault>' + 
                                    '<faultcode>SOAP-ENV:Server</faultcode>' + 
                                    '<faultstring>Error occurred invoking underlying service implementation' + 
                                    '</faultstring>' + 
                                    '<detail xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/">' + 
                                    '<ns2:serviceFault ' + 
                                    'xmlns:ns2="http://platform.apollogrp.edu/schemas/2010/05/28/ServiceFault">' + 
                                    '<ns2:componentCode>15</ns2:componentCode><ns2:transactionId>' + 
                                    'A4A3BF60-2BB1- 2EFA-E334-8B03BE650CD0</ns2:transactionId><ns2:errorCode> ' + 
                                    'PLATFORM-999</ns2:errorCode><ns2:errorDescription> ' + 
                                    'ORA-06512: at line 1' + 
                                    '</ns2:errorDescription></ns2:serviceFault></detail></soapenv:Fault>' + 
                                    '</soapenv:Body>' + 
                                    '</soapenv:Envelope>';
                res.setBody(strErrorSoap);
            }
            else{
                String strResponse = '<SOAP-ENV:Envelope xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/"><SOAP-ENV:Header><gateway:transactionId xmlns:gateway="http://platform.apollogrp.edu/gateway">830D87D3-CF88-8AD3-1314-2552E046D28C</gateway:transactionId></SOAP-ENV:Header><SOAP-ENV:Body><addOrUpdateChecklistResponse xmlns="http://platform.apollogrp.edu/services/apolloglobal/banner/admission/v1"><success>true</success></addOrUpdateChecklistResponse></SOAP-ENV:Body></SOAP-ENV:Envelope>';
                res.setStatusCode(200);
                res.setStatus('OK');
                res.setBody(strResponse);
            }
        }
        else{
            res = h.send(req);
        }
        system.debug(res.getStatus());
        system.debug(res.getBody());
        
        String result = res.getBody();
        if (res.getStatus() == 'OK' && res.getStatusCode() == 200){
            return;
        }
        else {
            newOpp.Last_Error__c = result;
            update newOpp;
            return;
        }
    }
    
    @isTest
    private static void unitTest1(){    
        country_list__c cntry = CreateTestData.createCountry1();
        State_Province__c stt = new State_Province__c(Name = 'Unit Test', ISO_Code__c = '123');
        insert stt;
        Locality__c lct = new Locality__c(Name = 'Unit Test', Banner_Code__c = '123');
        insert lct;
       
        Programme__c pgrm = new Programme__c();
        pgrm.Name = 'Test Program';
        pgrm.BNR_FieldOfStudy_Code__c = 'ELEC';
        pgrm.Microsite_Enabled__c = true;
        pgrm.Programme_Status__c = 'Validated';
        pgrm.School__c = 'Test School';
        insert pgrm;
        
        Product2 pd = new Product2();
        pd.IsActive = true;
        pd.Name = 'Test Course Instance';
        pd.Programme__c = pgrm.Id;
        pd.Mode__c = 'Full Time';
        pd.Location__c = 'London - London City';
        pd.Start_Date__c = system.today();
        pd.BNR_Admissions_Enabled__c = true;
        pd.BNR_Term_Code__c = '212121';
        pd.BNR_Attribute_Code__c = 'FT';
        pd.BNR_Level_Code__c = 'UG';
        pd.BNR_Campus_Code__c = 'LLC';
        pd.BNR_Degree_Code__c = 'MS';
        pd.BNR_Program_Code__c = 'ELEC';
        insert pd;
        
        Account a1 = new Account();
        StopRecursion.Dorun = true;
        a1.firstname='John';
        a1.lastname='Coppedge';
        a1.Salutation = 'Mr';
        a1.Middle_Name__pc = 'Mex';
        a1.Gender__pc = 'Male';
        a1.RecordTypeId=Schema.sObjectType.Account.getRecordTypeInfosByName().get('Locked Student Account').getRecordTypeId();
        a1.Student_Cycle__c = 'Pursue';
        a1.Student_Type__pc ='Domestic';
        a1.Preferred_Email__pc = 'Personal';
        a1.PersonEmail = 'john@john.com';
        a1.Personal_Email__pc ='john@john.com';
        a1.Work_Email__pc = 'john1@john.com';
        a1.BPP_Email__pc = 'john2@john.com';
        a1.Other_Email__pc = 'john3@john.com';
        a1.Billing_Email__pc = 'john4@john.com';
        a1.Preferred_Phone__pc = 'Mobile';
        a1.Phone = '8015555556';
        a1.PersonMobilePhone='8015555556';
        a1.PersonBirthdate =Date.valueOf('1986-12-07');
        a1.AA_Suffix__pc = 'Jr';
        a1.Preferred_First_Name__pc = 'Coppege';
        a1.Previous_First_Name__pc = 'John';
        a1.Previous_Surname__pc = 'Cop';
        a1.Previous_Middle_Name__pc = 'Copp';
        a1.Legal_Entity__c = 'PD';
        a1.PS_Profile_Services_ID__pc = '1234f567-bc23-42e8-924c-1234asdf5678';
        a1.BNR_Banner_ID__pc = 'BP0123456';
        a1.AR_Global_Customer_Number__c = '123456';
        a1.AR_Customer_Number__c = '123';
        insert a1;
        
        Address__c add1 = new Address__c();
        StopRecursion.Dorun = true;
        add1.Student__c = a1.Id;
        add1.Type__c = 'Home';
        add1.Street_1__c = '329 S Tonne Dr';
        add1.Street_2__c = '123';
        add1.Street_3__c = '123';
        add1.Street_4__c = '12';
        add1.City__c = 'Chicago';
        add1.Locality__c = lct.Id;
        add1.State_Province__c = stt.Id;
        add1.Zip_Postal_Code__c = '12345';
        add1.Lookup_Country__c = cntry.Id;
        insert add1;
        
        Opportunity opp1 = new Opportunity();
        StopRecursion.Dorun = true;
        opp1.AccountId = a1.id;
        opp1.Name = 'test';
        opp1.StageName = 'Accepted - Conditional Firm';
        opp1.Enrolment_Status__c = 'Acceptance';
        opp1.Cycle_Override__c = 'Use Student Cycle';
        opp1.CloseDate = Date.valueOf('2015-02-27'); 
        opp1.RecordTypeId=Schema.sObjectType.Opportunity.getRecordTypeInfosByName().get('Locked Application').getRecordTypeId();
        opp1.Course_Instance__c = pd.Id;
        opp1.Record_Source__c = 'Salesforce';
        opp1.Record_Source__c = 'CAB';
        opp1.Record_Source__c = 'UCAS';
        opp1.Record_Source__c = 'Direct Apps';  
        opp1.Record_Source__c = 'BPTC';
        insert opp1;
        opp1.BNR_CHK_ACRT__c = Date.valueOf('2015-02-27');     
        update opp1;
        
        List<ChecklistServices.BNRRequest> checklistUpdates = new List<ChecklistServices.BNRRequest>();
        ChecklistServices.BNRRequest BNR =  new ChecklistServices.BNRRequest();
        BNR.applicationId = opp1.Id;
        List<ChecklistServices.ChecklistItem> checklistItems = new List<ChecklistServices.ChecklistItem>();
        ChecklistServices.ChecklistItem ClI =  new ChecklistServices.ChecklistItem();
        ClI.bannerCode = 'ELTS';
        ClI.completionDate = Date.valueOf('2015-02-27');
        checklistItems.add(ClI);
        BNR.checklistItems = checklistItems;
        checklistUpdates.add(BNR);
        RestRequest request = new RestRequest();
        request.addHeader('Content-Type', 'application/json');
        request.requestBody = Blob.valueof(JSON.serialize(checklistUpdates));
        RestContext.request = request;
        ChecklistServices.Response res = ChecklistServices.doPost();  
    } 
    
    @isTest
    private static void unitTest2(){    
        Account a1 = new Account();
        StopRecursion.Dorun = true;
        a1.firstname='John';
        a1.lastname='Coppedge';
        a1.Salutation = 'Mr';
        a1.Middle_Name__pc = 'Mex';
        a1.Gender__pc = 'Male';
        a1.RecordTypeId=Schema.sObjectType.Account.getRecordTypeInfosByName().get('Locked Student Account').getRecordTypeId();
        a1.Student_Cycle__c = 'Pursue';
        a1.Student_Type__pc ='Domestic';
        a1.Preferred_Email__pc = 'Personal';
        a1.PersonEmail = 'john@john.com';
        a1.Personal_Email__pc ='john@john.com';
        a1.Work_Email__pc = 'john1@john.com';
        a1.BPP_Email__pc = 'john2@john.com';
        a1.Other_Email__pc = 'john3@john.com';
        a1.Billing_Email__pc = 'john4@john.com';
        a1.Preferred_Phone__pc = 'Mobile';
        a1.Phone = '8015555556';
        a1.PersonMobilePhone='8015555556';
        a1.PersonBirthdate =Date.valueOf('1986-12-07');
        a1.AA_Suffix__pc = 'Jr';
        a1.Preferred_First_Name__pc = 'Coppege';
        a1.Previous_First_Name__pc = 'John';
        a1.Previous_Surname__pc = 'Cop';
        a1.Previous_Middle_Name__pc = 'Copp';
        a1.Legal_Entity__c = 'PD';
        a1.PS_Profile_Services_ID__pc = '1234f567-bc23-42e8-924c-1234asdf5678';
        a1.BNR_Banner_ID__pc = 'BP0123456';
        a1.AR_Global_Customer_Number__c = '123456';
        a1.AR_Customer_Number__c = '123';
        insert a1;
        
        Opportunity opp1 = new Opportunity();
        StopRecursion.Dorun = true;
        opp1.AccountId = a1.id;
        opp1.Name = 'test';
        opp1.StageName = 'Accepted - Conditional Firm';
        opp1.Enrolment_Status__c = 'Acceptance';
        opp1.Cycle_Override__c = 'Use Student Cycle';
        opp1.CloseDate = Date.valueOf('2015-02-27'); 
        opp1.RecordTypeId=Schema.sObjectType.Opportunity.getRecordTypeInfosByName().get('Locked Application').getRecordTypeId();
        opp1.Record_Source__c = 'Salesforce';
        opp1.Record_Source__c = 'CAB';
        opp1.Record_Source__c = 'UCAS';
        opp1.Record_Source__c = 'BPTC';
        opp1.Record_Source__c = 'Direct Apps';  
        insert opp1;
        opp1.BNR_CHK_ACRT__c = Date.valueOf('2015-02-27');     
        update opp1;
        String OpptyId = opp1.Id;
        
        OutboundChecklistService.bFailChecklist = true;
        OutboundChecklistService.UpdateOpptyChecklistInfo(OpptyId);
    }    
}