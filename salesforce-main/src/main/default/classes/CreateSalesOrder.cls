global with sharing class CreateSalesOrder{
    public static string endPoint = '/rest/ar/salesorder/v1/create';  
    public static Boolean bFailSIS = false;
    
    
    public class SalesOrderTypeInfo{
        public SalesOrderType createSalesOrderRequest = new SalesOrderType();
    }
       
    public class SalesOrderType {
        public string opportunityId = '';
    }
        
    
    WebService static String SalesOrderInfo(String opportunityId){
        String result;
        Opportunity opp = [Select Id From Opportunity Where Id = :opportunityId Limit 1];
        String strRet = retriggerSalesOrder(opp);
        
        result = strRet;
        return result;
    }
     
    public static String retriggerSalesOrder(Opportunity opp){
        string result;
        if (opp != null){
            SalesOrderTypeInfo sot = new SalesOrderTypeInfo();
            sot.createSalesOrderRequest.opportunityId = opp.Id;
                          
            String jsonRequest = JSON.serialize(sot);
            system.debug(jsonRequest +'createsalesorder');
            Http http = new Http();
            HttpRequest req = BPPIntegrationConfig.callRestService(jsonRequest, 'application/json', endPoint);
            
            system.debug('Final JSON: ' + req.getMethod() + ' ' + req.getEndPoint() + 'Accept-Encoding:' + req.getHeader('Accept-Encoding') +'Accept:' + req.getHeader('Accept') + 'Content-Type:' + req.getHeader('Content-Type') + 'tenantId:' + req.getHeader('tenantId') + req.getBody());
            system.debug(req.toString());
            HttpResponse res = null;
            if (Test.isRunningTest()){
                res = new HttpResponse();
                if (bFailSIS){
                    String strResponse = '{"companyId":"1234f567-bc23-42e8-924c-1234asdf5678","operation":"UPDATE"}';
                    res.setStatusCode(200);
                    res.setStatus('OK');
                    res.setBody(strResponse);
                }
                else{
                    //String strResponse = '{"self":"null","httpMethod":"DELETE","errorMessage":"Cannot find Company or Profile Record for the specified Id: 1231231231","errorCode":"PLATFORM-801","transactionId":"A563C5CD-4CA9-B1C6-392A-09377720BFAC"}';
                    String strResponse = '{"createSalesOrderResponse":{"salesOrderId":"null","Description":"errorerror"}}';
                    res.setStatusCode(200);
                    //res.setStatus('Internal Error');
                    res.setStatus('OK');
                    res.setBody(strResponse);
                }
            }
            else{
                res = http.send(req);
            }
            system.debug(res.getBody());
            system.debug(res.getStatus());
            
            /* Integration Log */
            Integration_Log__c intg = new Integration_Log__c();
            intg.Request__c =  jsonRequest;
            intg.Response__c = res.getBody();
            intg.Salesforce_ID__c = opp.Id;
            intg.Integration_Type__c = 'Create Sales Order';
            
            String salesOrderId;
            if (res.getStatus() == 'OK' && res.getStatusCode() == 200){
                //resp is a JSON string
                JSONParser parser = JSON.createParser(res.getBody());
                while (parser.nextToken() != null) {
                    if ((parser.getCurrentToken() == JSONToken.FIELD_NAME)){
                        String fieldName = parser.getText();
                        parser.nextToken();
                        if(fieldName == 'salesOrderId') {
                            salesOrderId = parser.getText();
                            if(salesOrderId != 'null'){
                                system.debug('salesOrderId' + salesOrderId);
                                result = 'Sales Order Created: ' + salesOrderId;
                                break;
                            }
                            else if(salesOrderId == 'null')
                            {
                              JSONParser jParser = JSON.createParser(res.getBody());
                                while(jParser.nextToken() !=null){
                                    if((jParser.getCurrentToken() == JSONToken.FIELD_NAME)){
                                        string fieldN = jParser.getText();
                                        jParser.nextToken();
                                        if(fieldN == 'Description'){
                                            result = jParser.getText();
                                            system.debug('Error Description: ' + result);
                                            break;
                                        }
                                    }
                                } 
                            }
                             
                        }
                    }
                }      
            }
            else{ 
                //error handling for find CreateSalesOrder call
                JSONParser jParser = JSON.createParser(res.getBody());
                while(jParser.nextToken() !=null){
                    if((jParser.getCurrentToken() == JSONToken.FIELD_NAME)){
                        string fieldN = jParser.getText();
                        jParser.nextToken();
                        if(fieldN == 'Description'){
                            result = jParser.getText();
                            system.debug('Error Description' + result);
                            break;
                        }
                    }
                }
            }
            insert intg;                    
        }
        return result;
    }   
}