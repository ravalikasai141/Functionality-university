global with sharing class ARStudentAccountService {
    private static final String soapEnv = 'xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" ';
    private static final String tns = 'xmlns:tns="http://platform.apollogrp.edu/services/apolloglobal/ar/student/v1"> ';
    public static Boolean bFailARStudent = false;
    
    public static ARCustomerFields CreateARStudentAccount(Account newAccount, Opportunity newOpp){
    	ARCustomerFields ARCodes = new ARCustomerFields();
    	String requestStr = '<soapenv:Envelope ' + soapEnv + tns +
    	    '  <soapenv:Header/>' +
    	    '  <soapenv:Body>' +
    	    '     <tns:createARStudentAccountRequest>';
    	requestStr += '<tns:profileStudentId>' + newAccount.PS_Profile_Services_ID__pc +'</tns:profileStudentId>';
    	String tempentity = '';
        Boolean ARIntegrationCheck = false;
        if(newAccount.Legal_Entity__c != null){
        	Legal_Entity__c cs = Legal_Entity__c.getValues(newAccount.Legal_Entity__c);
            String entity = cs.Entity__c;
            Boolean ARIntegration = cs.AR_Integration__c;
            if (ARIntegration){
                ARIntegrationCheck = True;
            }
            requestStr += '<tns:legalEntity>' + entity +'</tns:legalEntity>';
        }     	

        requestStr += '<tns:customerGroup>' + newOpp.Customer_Group__c + '</tns:customerGroup>';
                
    	/*if(newAccount.Student_Type__pc == 'Domestic'){
    		requestStr += '<tns:studentGroup>STUDENT</tns:studentGroup>';    	
    	}
    	else{
    		requestStr += '<tns:studentGroup>INTSTUDENT</tns:studentGroup>';    	
    	}*/
    	requestStr += '</tns:createARStudentAccountRequest>' + 
            '</soapenv:Body></soapenv:Envelope>';
        
        Http h = new Http();
        HttpRequest req = BPPIntegrationConfig.getData(requestStr);
        req.setTimeout(120000);
        system.debug('xml' + requestStr);   
        system.debug(req.toString());
        HttpResponse res = null;
        if (Test.isRunningTest()){
            res = new HttpResponse();
            if (bFailARStudent){
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
            	String strResponse = '<SOAP-ENV:Envelope xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/"><SOAP-ENV:Header><gateway:transactionId xmlns:gateway="http://platform.apollogrp.edu/gateway">E085B46F-D14C-FCDD-5337-72D01822FCF6</gateway:transactionId></SOAP-ENV:Header><SOAP-ENV:Body><createARStudentAccountResponse xmlns="http://platform.apollogrp.edu/services/apolloglobal/ar/student/v1"><ARGlobalCustomerNumber>22565467343</ARGlobalCustomerNumber><ARCustomerNumber>902491</ARCustomerNumber></createARStudentAccountResponse></SOAP-ENV:Body></SOAP-ENV:Envelope>';
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
        String resultXml = res.getBody();
        String result = resultXml;
        if (res.getStatus() == 'OK' && res.getStatusCode() == 200){
            XmlStreamReader reader = new XmlStreamReader(resultXml);
            while(reader.hasNext()) {
                if (reader.getEventType() == XmlTag.START_ELEMENT) {
                    if ('ARGlobalCustomerNumber' == reader.getLocalName()) {
                        reader.next();
                        if (reader.hasText()){
                            result = reader.getText();
                            newAccount.AR_Global_Customer_Number__c = result;
                        }
                    }
                    if ('ARCustomerNumber' == reader.getLocalName()) {
                        reader.next();
                        if (reader.hasText()){
                            result = reader.getText();
                            newAccount.AR_Customer_Number__c = result;
                        }
                    }
                }
                reader.next();
            }
            ARCodes.ARCustomerNumber = newAccount.AR_Customer_Number__c;
            ARCodes.ARGlobalCustomerNumber = newAccount.AR_Global_Customer_Number__c;
            ARCodes.Status = 'Success';
            return ARCodes;
        }
        else{
        	ARCodes.Status = result;
            return ARCodes;
        }
    }
    
    public class ARCustomerFields {
    	public string ARCustomerNumber {get;set;}
    	public string ARGlobalCustomerNumber {get;set;}
    	public string Status {get;set;}   	
    }
}