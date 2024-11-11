global with sharing class BNR_PublishEvent {
    
    private static final String soapEnv = 'xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" ';
  private static final String v1 = 'xmlns:v1="http://platform.apollogrp.edu/services/event/v1" ';
  private static final String even = 'xmlns:even="http://platform.apollogrp.edu/model/v1/Event"> ';
    
    
  WebService static String PublishEventRequest(String oppId) {        
        Opportunity opp = [Select Id, AccountId From Opportunity Where Id = : oppId];
        Account acc = [Select Id, BNR_Banner_ID__pc From Account Where Id = : opp.AccountId];
        
        Datetime current_datetime = datetime.now();
        Integer current_year = current_datetime.year();
        
        Integer current_month = current_datetime.month();
        String current_month_string = string.valueof(current_month);
        if(current_month_string.length() == 1)
          current_month_string = '0' + current_month_string;
        
        Integer current_day = current_datetime.day();
    String current_day_string = string.valueof(current_day);        
        if(current_day_string.length() == 1)
          current_day_string = '0' + current_day_string;
                
        Integer current_hour = current_datetime.hour();
        String current_hour_string = string.valueof(current_hour);   
        if(current_hour_string.length() == 1)
          current_hour_string = '0' + current_hour_string;
        
        Integer current_minute = current_datetime.minute();
        String current_minute_string = string.valueof(current_minute);   
        if(current_minute_string.length() == 1)
          current_minute_string = '0' + current_minute_string;
        
        Integer current_second = current_datetime.second();
        String current_second_string = string.valueof(current_second);
        if(current_second_string.length() == 1)
          current_second_string = '0' + current_second_string;
                 
        String timestamp = current_year +'-'+ current_month_string +'-'+ current_day_string +'T'+ current_hour_string +':' + current_minute_string +':' + current_second_string;
        
        
        String requestStr = '<soapenv:Envelope ' + soapEnv + v1 + even +
        '  <soapenv:Header/>' +
        '  <soapenv:Body>' +
        '  <v1:publishEventRequest>' +
        '  <even:event>';

     requestStr += '<even:timestamp>' + timestamp + '</even:timestamp>';
     requestStr += '<even:eventType>ALT_ID_CHANGE</even:eventType>';
     requestStr += '<even:subjectId>' + opp.Id + '</even:subjectId>';
     requestStr += '<even:payload>' + '<even:stringData>';

        requestStr += '<![CDATA[';
     requestStr += '<BannerEvent> <Field> <key>ALTERNATE_ID</key> <value>' + opp.Id + '</value> </Field> <Field> <key>ALT_ID_TYPE</key> <value>OpportunityID</value> </Field> <Field> <key>BANNER_ID</key> <value>' + acc.BNR_Banner_ID__pc + '</value> </Field> </BannerEvent>';
     requestStr += ']]>';

     requestStr += '</even:stringData></even:payload></even:event></v1:publishEventRequest></soapenv:Body></soapenv:Envelope>';
                   
        system.debug('XML_REQUEST: ' + requestStr);          
        
        Http h = new Http();
        HttpRequest req = BPPIntegrationConfig.getData(requestStr);
        req.setTimeout(120000);
        HttpResponse res = null;
        
        if (Test.isRunningTest()){
            String strResponse = '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" '+
                'xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">'+
                '<soapenv:Header>'+
                '<gateway:transactionId xmlns:gateway="http://platform.apollogrp.edu/gateway">' +
                'B729996C-0720-FFA7-7736-7F90515524FD'+
                '</gateway:transactionId></soapenv:Header>'+
                '<soapenv:Body>'+
                '<eventservice:publishEventResponse xmlns:eventservice="http://platform.apollogrp.edu/services/event/v1">'+
                '<eventservice:eventId>ID:dlaxmsgb302.apolloglobal.int-51268-1415178077473-2:5:1031:1:2</eventservice:eventId>'+
                '</eventservice:publishEventResponse>'+
                '</soapenv:Body>'+
                '</soapenv:Envelope>';

            res = new HttpResponse();
            res.setStatusCode(200);
            res.setStatus('OK');
            res.setBody(strResponse);
        }
        else{
            res = h.send(req);
        }
        system.debug(res.getStatus());
        system.debug(res.getBody());
        
        String result = res.getBody();
        
        if (result.indexOf('<eventservice:eventId>') != null) {
          result = 'Success';   
        }    
        else {
            XmlStreamReader reader = new XmlStreamReader(result);
                while(reader.hasNext()) {
                  if (reader.getEventType() == XmlTag.START_ELEMENT) {
                    if ('errorDescription' == reader.getLocalName()) {
                      reader.next();
                          if (reader.hasText()){
                            result = reader.getText();    
                          }
                    }
                  }
                }
        }
        
        return result;

    }    
}