public with sharing class Create_IntegrationLog {
    public static void writeIncomingLog(String serviceName, String request, String response){
        Integration_Log_Incoming__c log = new Integration_Log_Incoming__c();
        log.Request_Body__c = request;//JSON.serialize(stdDTO);
        log.Request_Date__c = Datetime.now();
        log.Service_Name__c = serviceName;//'CreateStudentAccount';
        log.Details__c = response;
        insert log;
    }
}