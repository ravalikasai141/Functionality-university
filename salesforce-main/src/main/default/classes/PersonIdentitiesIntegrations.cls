global with sharing class PersonIdentitiesIntegrations {
    private static final String soapEnv = 'xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" ';
    private static final String prof = 'xmlns:prof="http://platform.apollogrp.edu/wsdl/sif/profile/2010/07/02/ProfileService" ';
    private static final String ent = 'xmlns:ent="http://platform.apollogrp.edu/schemas/2010/06/01/Entity" ';
    private static final String iden = 'xmlns:iden="http://platform.apollogrp.edu/schemas/profile/2010/07/02/Identity" ';
    private static final String ext = 'xmlns:ext="http://platform.apollogrp.edu/model/extension" ';
    
    @future(callOut=true)
    public static void PersonIdentityUpdate(Map<String, String> personInfo){
        if (personInfo != null){
            for (String ProfileId : personInfo.keySet()){
                PersonIdent(ProfileId, personInfo.get(ProfileId));
            }
        }
    }
    
    public static String PersonIdent(String ProfileId, String Identity) {
        
         String requestStr = '<soapenv:Envelope ' + soapEnv + prof + ent + iden + ext + 
            '>  <soapenv:Header/>' +
            '  <soapenv:Body>' +
            '    <prof:insertProfileIdentitiesRequest>';
            
            requestStr += '<prof:profileId>' + ProfileId + '</prof:profileId>';   
            requestStr += '<prof:identity><iden:type>SALESFORCE_ID</iden:type><iden:value>' + 
                            Identity + '</iden:value></prof:identity>' +
                '       </prof:insertProfileIdentitiesRequest>'  +
                '    </soapenv:Body>' +
                '</soapenv:Envelope>';
        
        system.debug('xml' + requestStr);   
        Http h = new Http();
        HttpRequest req = BPPIntegrationConfig.getData(requestStr);
        System.debug(req.toString());
        HttpResponse res = null;
        if (Test.isRunningTest()){
            String strRes = '<SOAP-ENV:Envelope xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/"><SOAP-ENV:Header><gateway:transactionId xmlns:gateway="http://platform.apollogrp.edu/gateway">007ADFB3-23A5-1A31-CA59-A2AB58FCD031</gateway:transactionId></SOAP-ENV:Header><SOAP-ENV:Body><insertProfileIdentitiesResponse xmlns="http://platform.apollogrp.edu/wsdl/sif/profile/2010/07/02/ProfileService"/></SOAP-ENV:Body></SOAP-ENV:Envelope>';
            res = new HttpResponse();
            res.setStatus('OK');
            res.setStatusCode(200);
            res.setBody(strRes);
        }
        else{
            res = h.send(req);
        }
        system.debug(res.getStatus());
        system.debug(res.getBody());
        String result = res.getBody();
        return '';
    }
}