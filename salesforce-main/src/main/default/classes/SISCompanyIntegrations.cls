global with sharing class SISCompanyIntegrations {
    private static final String soapEnv = 'xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" ';
    private static final String tns = 'xmlns:tns="http://platform.apollogrp.edu/services/apolloglobal/crm/company/v1"> ';
    public static Boolean bFailSIS = false;
    
    WebService static String SISCompanyInt (String AccountId) {
        System.debug('@SISCompanyIntegrations SISCompanyInt: Entered');
        String query = Util.getAllFieldsSOQL('Account', 'Id = \'' + AccountId + '\'');
        Account acc  =[Select Id, Profile_Company_ID__c, SIS_Company_ID__c, Sponsor_Hold_Status__c, Sponsor_Contact__c,
            Invoice_Method__c, Invoice_Delivery__c, Booking_Requirements__c, Owner.Name, Correspondence_Detail__c,Payment_Terms__c, 
            Credit_Limit__c, Website, Discount__c, Reporting_Required__c
            From account Where Id =: accountID Limit 1];
        String result = SISCompanyIntegrations.CreateSISCompanyInfo(acc);
        System.debug('@SISCompanyIntegrations result: ' + result);
        if(result == 'OK'){
        	return 'Application Submitted Successfully';
        }
        else{
        	return result;
        }
    }
    public static String CreateSISCompanyInfo(Account newAccount) {
        System.debug('@SISCompanyIntegrations CreateSISCompanyInfo: Entered');
        String requestStr = '<soapenv:Envelope ' + soapEnv + tns +
            '  <soapenv:Header/>' +
            '  <soapenv:Body>' +
            '    <tns:createUpdateSISCompanyRequest>' +
            '       <tns:sponsorInfo>';
            
        if(newAccount.Profile_Company_ID__c != null && newAccount.Profile_Company_ID__c != ''){
            requestStr += '<tns:profileCompanyId>' + newAccount.Profile_Company_ID__c.escapeXML() + '</tns:profileCompanyId>';
        }
        if(newAccount.SIS_Company_ID__c != null && newAccount.SIS_Company_ID__c != ''){
            requestStr += '<tns:sisCompanyId>' + newAccount.SIS_Company_ID__c.escapeXML() + '</tns:sisCompanyId>';
        }
        if(newAccount.Sponsor_Contact__c != null && newAccount.Sponsor_Contact__c != ''){
            requestStr += '<tns:sponsorContact>' + newAccount.Sponsor_Contact__c.escapeXML() + '</tns:sponsorContact>';
        }
        if(newAccount.Invoice_Method__c != null && newAccount.Invoice_Method__c != ''){
            requestStr += '<tns:invoiceMethod>' + newAccount.Invoice_Method__c + '</tns:invoiceMethod>';
        }
        if(newAccount.Invoice_Delivery__c != null && newAccount.Invoice_Delivery__c != ''){
            requestStr += '<tns:invoiceDeleveryPreference>' + newAccount.Invoice_Delivery__c + '</tns:invoiceDeleveryPreference>';
        }
        if(newAccount.Booking_Requirements__c != null && newAccount.Booking_Requirements__c != ''){
            requestStr += '<tns:bookingRequirement>' + newAccount.Booking_Requirements__c.escapeXML() + '</tns:bookingRequirement>';
        }
        if(newAccount.Owner.Name != null && newAccount.Owner.Name != ''){
            requestStr += '<tns:accountOwner>' + newAccount.Owner.Name + '</tns:accountOwner>';
        }
        if(newAccount.Correspondence_Detail__c != null && newAccount.Correspondence_Detail__c != ''){
            requestStr += '<tns:correspondenceDetail>' + newAccount.Correspondence_Detail__c + '</tns:correspondenceDetail>';
        }
        if(newAccount.Payment_Terms__c != null && newAccount.Payment_Terms__c != ''){
            requestStr += '<tns:paymentTerms>' + newAccount.Payment_Terms__c + '</tns:paymentTerms>';
        }
        if(newAccount.Credit_Limit__c != null){
            requestStr += '<tns:creditLimit>' + newAccount.Credit_Limit__c + '</tns:creditLimit>';
        }
        if(newAccount.Website != null && newAccount.Website != ''){
            requestStr += '<tns:url>' + newAccount.Website.escapeXML() + '</tns:url>';
        }
        if(newAccount.Discount__c != null){
            requestStr += '<tns:discount>' + newAccount.Discount__c + '</tns:discount>';
        }
        String reportingRequired;
        if (newAccount.Reporting_Required__c == true){
            reportingRequired = '1';
        }
        else{
            reportingRequired = '0';
        }
        requestStr += '<tns:reportingRequired>' + reportingRequired + '</tns:reportingRequired>';   
        requestStr += '</tns:sponsorInfo></tns:createUpdateSISCompanyRequest>' + 
            '</soapenv:Body></soapenv:Envelope>';
        
        Http h = new Http();
        HttpRequest req = BPPIntegrationConfig.getData(requestStr);
        req.setTimeout(120000);
        system.debug('xml' + requestStr);   
        system.debug(req.toString());
        HttpResponse res = null;
        if (Test.isRunningTest()){
            res = new HttpResponse();
            if (bFailSIS){
                res.setStatus('Internal Error');
                res.setStatusCode(500);
                String strErrorSoap = '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/"><soapenv:Header><gateway:transactionId xmlns:gateway="http://platform.apollogrp.edu/gateway">C692894B-1CF0-E61B-10AF-BAB03FBB22F8</gateway:transactionId></soapenv:Header><soapenv:Body><soapenv:Fault><faultcode>SOAP-ENV:Server</faultcode><faultstring>Error occurred invoking underlying service implementation</faultstring><detail xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/"><ns2:serviceFault xmlns:ns2="http://platform.apollogrp.edu/schemas/2010/05/28/ServiceFault"><ns2:componentCode>15</ns2:componentCode><ns2:transactionId>C692894B-1CF0-E61B-10AF-BAB03FBB22F8</ns2:transactionId><ns2:errorCode>PLATFORM-999</ns2:errorCode><ns2:errorDescription>PreparedStatementCallback; SQL [INSERT INTO SZBSPON(SZBSPON_SPRIDEN_ID, SZBSPON_SPONSOR, SZBSPON_SPONSOR_Type, SZBSPON_SPONSOR_Hold_Status, SZBSPON_SPONSOR_CONTACT, SZBSPON_ACTIVITY_DATE, SZBSPON_USER_ID, SZBSPON_SPRIDEN_PIDM, SZBSPON_VAT_NUMBER, SZBSPON_EU_TAX_REGISTERED, SZBSPON_COUNTRY_ISO, SZBSPON_INVOICE_METHOD, SZBSPON_INVOICE_DELIVERY, SZBSPON_BOOKING, SZBSPON_OWNER, SZBSPON_CORRESPOND, SZBSPON_TERMS, SZBSPON_LIMIT, SZBSPON_URL, SZBSPON_DISCOUNT, SZBSPON_REPORTING_REQUIRED) VALUES  (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)]; ORA-01400: cannot insert NULL into ("AGCUSTOM"."SZBSPON"."SZBSPON_SPONSOR"); nested exception is java.sql.SQLIntegrityConstraintViolationException: ORA-01400: cannot insert NULL into ("AGCUSTOM"."SZBSPON"."SZBSPON_SPONSOR")</ns2:errorDescription></ns2:serviceFault></detail></soapenv:Fault></soapenv:Body></soapenv:Envelope>';
                res.setBody(strErrorSoap);
            }
            else{
            	String strResponse = '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:bnr="http://platform.apollogrp.edu/services/apolloglobal/crm/company/v1"><soapenv:Header><gateway:transactionId xmlns:gateway="http://platform.apollogrp.edu/gateway">A02BBF28-1481-6010-8CD7-D02B84C0DCCE</gateway:transactionId></soapenv:Header><soapenv:Body><bnr:createUpdateSISCompanyResponse><bnr:sisCompanyId>BP0015424</bnr:sisCompanyId></bnr:createUpdateSISCompanyResponse></soapenv:Body></soapenv:Envelope>';
            	res.setStatusCode(200);
            	res.setStatus('OK');
            	res.setBody(strResponse);
            }
        }
        else{
            res = h.send(req);
        }
        system.debug('@SISCompanyIntegrations CreateSISCompanyInfo: getStatus' + res.getStatus());
        system.debug('@SISCompanyIntegrations CreateSISCompanyInfo: getBody' + res.getBody());
        String resultXml = res.getBody();
        String result = resultXml;
        if (result.indexOf('<bnr:sisCompanyId>') != -1) {
            
            result = result.substring(result.indexOf('<bnr:sisCompanyId>') + 18);
            result = result.substring(0, 9);
            newAccount.SIS_Company_ID__c = result;
            update newAccount;
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
}