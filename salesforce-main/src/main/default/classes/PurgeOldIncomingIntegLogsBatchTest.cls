/**********************************************************************
Name: PurgeOldIncomingIntegLogsBatchTest
Purpose: Test Class for the Class(PurgeOldIncomingIntegLogsBatch) which deletes Incoming Integration Logs that are older than 6 months    
-------                                                             
History                                                             
-------                                                             
VERSION  AUTHOR             DATE              DETAIL                              
0.1 -   David Lovejoy     17/10/2019      INITIAL DEVELOPMENT  
0.2 -   David Lovejoy     13/05/2021      UPDATE  
***********************************************************************/
@isTest
public class  PurgeOldIncomingIntegLogsBatchTest {
    public static testmethod void MassDeleteOldIncLogTest() {
		Integration_Log_Incoming__c log = new Integration_Log_Incoming__c();
        log.Request_Body__c = 'Test Body';
        log.Request_Date__c = Datetime.now();
        log.Service_Name__c = 'Test Name';
        log.Details__c = 'Test Details';
        insert log;

        Test.startTest();
			PurgeOldIncomingIntegLogsBatch incIntBatch = new PurgeOldIncomingIntegLogsBatch();
			Integer batchSize = Test.isRunningTest() ? 500 : 6;
			System.debug('PurgeOldIncIntLogs Test1: size = ' + batchSize);
			Database.ExecuteBatch(incIntBatch, batchSize);
        Test.stopTest();
    }
}