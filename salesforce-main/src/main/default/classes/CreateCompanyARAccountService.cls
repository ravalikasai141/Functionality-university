global with sharing class CreateCompanyARAccountService {
    private static final String soapEnv = 'xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" ';
    private static final String tns = 'xmlns:tns="http://platform.apollogrp.edu/services/apolloglobal/ar/company/v1">';
    public static boolean testFail{get;set;}
    webservice static string companyARAccInt(string accountId) {
        System.debug('@CreateCompanyARAccountService companyARAccInt: Entered');
        String query = Util.getAllFieldsSOQL('Account', 'Id = \'' + accountId + '\'');
        Account acc = [Select Id, Profile_Company_ID__c, Legal_Entity__c, AR_Global_Customer_Number__c, AR_Customer_Number__c From account Where Id =: accountID Limit 1];
        String result = CreateCompanyARAccountService.createARAccountInfo(acc);
        System.debug('@CreateCompanyARAccountService result: ' + result);
        if(result == 'OK')
            return 'Application Submitted Successfully';
        else
            return result;
    }
    
    public static string createARAccountInfo(Account accountInfo){
        System.debug('@CreateCompanyARAccountService createARAccountInfo: Entered');
        String requestStr = '<soapenv:Envelope ' + soapEnv + tns + 
            '  <soapenv:Header/>' +
            '  <soapenv:Body>' +
            '    <tns:createUpdateARCompanyAccountRequest>';
        requestStr += '<tns:profileCompanyId>'+ accountInfo.Profile_Company_ID__c +'</tns:profileCompanyId>';
        requestStr += '<tns:legalEntity>' + BNR_SubmitApplication.ExtractBackCode(accountInfo.Legal_Entity__c) +'</tns:legalEntity>';
        requestStr += '</tns:createUpdateARCompanyAccountRequest>' + 
            '</soapenv:Body></soapenv:Envelope>';
        
        Http h = new Http();
        HttpRequest req = BPPIntegrationConfig.getData(requestStr);
        req.setMethod('POST');
        req.setTimeout(120000);
        system.debug('xml' + requestStr);   
        system.debug(req.toString());
        HttpResponse res = null;
        if (Test.isRunningTest()){
            res = new HttpResponse();
            
            res.setStatus('OK');
            String strResponse;
            if(!testFail){
                strResponse = '<?xml version="1.0" encoding="utf-8"?>'+
                            '<SOAP-ENV:Envelope xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/">'+
                            '<SOAP-ENV:Header><gateway:transactionId xmlns:gateway="http://platform.apollogrp.edu/gateway">' +
                            'E3C89563-E0BE-7907-ED14-238B68A03FEB</gateway:transactionId></SOAP-ENV:Header><SOAP-ENV:Body>'+
                            '<createUpdateARCompanyAccountResponse xmlns="http://platform.apollogrp.edu/services/apolloglobal/ar/company/v1">'+
                            '<ARGlobalCustomerNumber>22565469596</ARGlobalCustomerNumber><ARCustomerNumber>902609</ARCustomerNumber>'+
                            '</createUpdateARCompanyAccountResponse></SOAP-ENV:Body></SOAP-ENV:Envelope>';
                res.setStatusCode(200);                         
            }
            else{
                strResponse ='<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/">'+
                             '<soapenv:Header><gateway:transactionId xmlns:gateway="http://platform.apollogrp.edu/gateway">'+
                             '78567E41-22AE-46C8-24FF-DF53C913DD98</gateway:transactionId></soapenv:Header>'+
                             '<soapenv:Body><soapenv:Fault><faultcode>SOAP-ENV:Server</faultcode>'+
                             '<faultstring>Error occurred invoking underlying service implementation</faultstring>'+
                             '<detail xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/">'+ 
                             '<ns2:serviceFault xmlns:ns2="http://platform.apollogrp.edu/schemas/2010/05/28/ServiceFault">'+
                             '<ns2:componentCode>25</ns2:componentCode><ns2:transactionId>78567E41-22AE-46C8-24FF-DF53C913DD98</ns2:transactionId>'+
                             '<ns2:errorCode>PLATFORM-999</ns2:errorCode><ns2:errorDescription>Error occured while creating CustomerAccount in AR.</ns2:errorDescription>'+
                             '</ns2:serviceFault></detail></soapenv:Fault></soapenv:Body></soapenv:Envelope>';
                res.setStatusCode(400);
            }
            
            res.setBody(strResponse);
        }
        else{
            res = h.send(req);
        }
        system.debug('@CreateCompanyARAccountService createARAccountInfo getStatus: ' + res.getStatus());
        system.debug('@CreateCompanyARAccountService createARAccountInfo getBody: ' + res.getBody());
        
        String resultXML = res.getBody();
        String result = resultXml;
        if(res.getStatus() == 'OK' && res.getStatusCode() == 200){
            system.debug('Response: ' + res.getBody());
            String arGlobalCustomerNumber = '';
            String arCustomerNumber = '';
            XmlStreamReader reader = new XmlStreamReader(resultXml);
            while(reader.hasNext()) {
                if (reader.getEventType() == XmlTag.START_ELEMENT) {
                    if ('ARGlobalCustomerNumber' == reader.getLocalName()) {
                        reader.next();
                        if (reader.hasText()){
                            result = reader.getText();
                            accountInfo.AR_Global_Customer_Number__c = result;
                        }
                    }
                    if ('ARCustomerNumber' == reader.getLocalName()) {
                        reader.next();
                        if (reader.hasText()){
                            result = reader.getText();
                            accountInfo.AR_Customer_Number__c = result;
                        }
                    }
                }
                if(reader.getEventType() == XmlTag.END_ELEMENT && 'ARCustomerNumber' == reader.getLocalName()){
                    break;
                }
                reader.next();
            }
            update accountInfo;
            return 'OK';
        }
        else {
            XmlStreamReader reader = new XmlStreamReader(resultXml);
            while(reader.hasNext()) {
                if (reader.getEventType() == XmlTag.START_ELEMENT) {
                    if ('errorDescription' == reader.getLocalName()) {
                        reader.next();
                        if (reader.hasText()){
                            result = reader.getText();
                        }
                    }
                }
                reader.next();
            }
            return result;
        }
   }
   
   
   /////////////////////////////////New Method written by Prema for Lightning Action on 06/01/2020
   
   
   global class ARSISCalloutWrapper
    {
        webservice Account acc;
        webservice String newResult;
        
        public ARSISCalloutWrapper(Account acc,  String newResult)
        {  
            this.acc=acc;
            this.newResult = newResult;     
        }   
    }
    
    global List<ARSISCalloutWrapper> lstw = new List<ARSISCalloutWrapper>();
   
   
   webservice static ARSISCalloutWrapper companyARAccIntnew(string accountId) 
   {
        ARSISCalloutWrapper ARSISWrapper;
        String finalResult;
        String query = Util.getAllFieldsSOQL('Account', 'Id = \'' + accountId + '\'');
        Account accountInfo  =[Select Id, Profile_Company_ID__c, Legal_Entity__c, AR_Global_Customer_Number__c, AR_Customer_Number__c From account Where Id =: accountID Limit 1];
        //String result = CreateCompanyARAccountService.createARAccountInfo(acc);
        
       // public static string createARAccountInfo(Account accountInfo){
        String requestStr = '<soapenv:Envelope ' + soapEnv + tns + 
            '  <soapenv:Header/>' +
            '  <soapenv:Body>' +
            '    <tns:createUpdateARCompanyAccountRequest>';
        requestStr += '<tns:profileCompanyId>'+ accountInfo.Profile_Company_ID__c +'</tns:profileCompanyId>';
        requestStr += '<tns:legalEntity>' + BNR_SubmitApplication.ExtractBackCode(accountInfo.Legal_Entity__c) +'</tns:legalEntity>';
        //requestStr += '<tns:companyGroup>CLIENT</tns:companyGroup>';
        requestStr += '</tns:createUpdateARCompanyAccountRequest>' + 
            '</soapenv:Body></soapenv:Envelope>';
        
        Http h = new Http();
        HttpRequest req = BPPIntegrationConfig.getData(requestStr);
        req.setMethod('POST');
        req.setTimeout(120000);
        system.debug('xml' + requestStr);   
        system.debug(req.toString());
        HttpResponse res = null;
        if (Test.isRunningTest()){
            res = new HttpResponse();
            
            res.setStatus('OK');
            String strResponse;
            if(!testFail){
                strResponse = '<?xml version="1.0" encoding="utf-8"?>'+
                            '<SOAP-ENV:Envelope xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/">'+
                            '<SOAP-ENV:Header><gateway:transactionId xmlns:gateway="http://platform.apollogrp.edu/gateway">' +
                            'E3C89563-E0BE-7907-ED14-238B68A03FEB</gateway:transactionId></SOAP-ENV:Header><SOAP-ENV:Body>'+
                            '<createUpdateARCompanyAccountResponse xmlns="http://platform.apollogrp.edu/services/apolloglobal/ar/company/v1">'+
                            '<ARGlobalCustomerNumber>22565469596</ARGlobalCustomerNumber><ARCustomerNumber>902609</ARCustomerNumber>'+
                            '</createUpdateARCompanyAccountResponse></SOAP-ENV:Body></SOAP-ENV:Envelope>';
                res.setStatusCode(200);                         
            }
            else{
                strResponse ='<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/">'+
                             '<soapenv:Header><gateway:transactionId xmlns:gateway="http://platform.apollogrp.edu/gateway">'+
                             '78567E41-22AE-46C8-24FF-DF53C913DD98</gateway:transactionId></soapenv:Header>'+
                             '<soapenv:Body><soapenv:Fault><faultcode>SOAP-ENV:Server</faultcode>'+
                             '<faultstring>Error occurred invoking underlying service implementation</faultstring>'+
                             '<detail xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/">'+ 
                             '<ns2:serviceFault xmlns:ns2="http://platform.apollogrp.edu/schemas/2010/05/28/ServiceFault">'+
                             '<ns2:componentCode>25</ns2:componentCode><ns2:transactionId>78567E41-22AE-46C8-24FF-DF53C913DD98</ns2:transactionId>'+
                             '<ns2:errorCode>PLATFORM-999</ns2:errorCode><ns2:errorDescription>Error occured while creating CustomerAccount in AR.</ns2:errorDescription>'+
                             '</ns2:serviceFault></detail></soapenv:Fault></soapenv:Body></soapenv:Envelope>';
                res.setStatusCode(400);
            }
            
            res.setBody(strResponse);
        }
        else{
            res = h.send(req);
        }
        system.debug(res.getStatus());
        system.debug(res.getBody());
        
        String resultXML = res.getBody();
        String result = resultXml;
        if(res.getStatus() == 'OK' && res.getStatusCode() == 200){
            system.debug('Response: ' + res.getBody());
            String arGlobalCustomerNumber = '';
            String arCustomerNumber = '';
            XmlStreamReader reader = new XmlStreamReader(resultXml);
            while(reader.hasNext()) {
                if (reader.getEventType() == XmlTag.START_ELEMENT) {
                    if ('ARGlobalCustomerNumber' == reader.getLocalName()) {
                        reader.next();
                        if (reader.hasText()){
                            result = reader.getText();
                            accountInfo.AR_Global_Customer_Number__c = result;
                        }
                    }
                    if ('ARCustomerNumber' == reader.getLocalName()) {
                        reader.next();
                        if (reader.hasText()){
                            result = reader.getText();
                            accountInfo.AR_Customer_Number__c = result;
                        }
                    }
                }
                if(reader.getEventType() == XmlTag.END_ELEMENT && 'ARCustomerNumber' == reader.getLocalName()){
                    break;
                }
                reader.next();
            }
            
            
            //update accountInfo;
            //return 'OK';
            finalResult = 'Application Submitted Successfully';
            ARSISWrapper = new ARSISCalloutWrapper(accountInfo, finalResult);
            return ARSISWrapper;
        }
        else {
            XmlStreamReader reader = new XmlStreamReader(resultXml);
            while(reader.hasNext()) {
                if (reader.getEventType() == XmlTag.START_ELEMENT) {
                    if ('errorDescription' == reader.getLocalName()) {
                        reader.next();
                        if (reader.hasText()){
                            result = reader.getText();
                        }
                    }
                }
                reader.next();
            }
            ARSISWrapper = new ARSISCalloutWrapper(accountInfo, result);
            return ARSISWrapper;
            
            //return result;
        }
   }

   //////////////////////////////////////////////////////////////////////////////////////
   
    webservice static string validationRulesForAR(string accountID){
        System.debug('@CreateCompanyARAccountService validationRulesForAR: Entered');
        Account acc  =[Select Id, Profile_Company_ID__c, Legal_Entity__c, AR_Global_Customer_Number__c,
                              AR_Customer_Number__c From account Where Id =: accountID Limit 1];
        
        string nullARMsg = '';
        if(acc.AR_Global_Customer_Number__c !=null){
            nullARMsg += 'Global Customer Number already Exits\n';
        }
        if(acc.AR_Customer_Number__c != null){
            nullARMsg += 'Customer Number already Exits\n';
        }
        if(acc.AR_Customer_Number__c == null || acc.AR_Global_Customer_Number__c ==null){
            if(acc.Legal_Entity__c == null){                
                nullARMsg += 'Missing Required Fields for AR service are:\n' + '' +'Legal Entity is required\n';
            }           
        }
        System.debug('@CreateCompanyARAccountService nullARMsg: ' + nullARMsg);
        return nullARMsg;               
    }
    
    webservice static string validationRulesForSIS(string accountId){
        System.debug('@CreateCompanyARAccountService validationRulesForSIS: Entered');
        Account acc  =[Select Id, Acronym_short_title__c,SIS_Company_ID__c 
                         From Account Where Id =: accountID Limit 1];
        
        string nullSISMsg = '';
        if(acc.SIS_Company_ID__c != null){
            nullSISMsg += 'SIS Company ID already Exits\n';
        }
        if(acc.SIS_Company_ID__c == null){
            if(acc.Acronym_short_title__c == null){             
                nullSISMsg += 'Missing Required Fields for SIS company Id are:\n' + '' +'Acronym (short title) is required\n';
            }
        }
        System.debug('@CreateCompanyARAccountService nullSISMsg: ' + nullSISMsg);
        return nullSISMsg;  
    }
}