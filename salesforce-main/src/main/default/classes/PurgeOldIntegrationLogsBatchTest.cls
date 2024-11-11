/**********************************************************************
Name: PurgeOldIntegrationLogsBatchTest
Purpose: Test Class for the Class(PurgeOldIntegrationLogsBatch) which Deletes 1 year old Incoming Integration logs to Maintain Data Storage                 
-------                                                             
History                                                             
-------                                                             
VERSION  AUTHOR             DATE              DETAIL                              
0.1 -   Prema Medasani     25/03/2019      INITIAL DEVELOPMENT  
0.2 -   David Lovejoy      13/05/2021      UPDATE  
***********************************************************************/
@isTest
public class PurgeOldIntegrationLogsBatchTest {
  public static testmethod void MassDeleteOldlogTest() {
    Integration_Log__c integ = new Integration_Log__c();
    integ.Request__c = 'Test Request';
    integ.Response__c = 'Test Response';
    integ.Integration_Type__c = 'HUB';
    insert integ;

    Test.startTest();
      PurgeOldIntegrationLogsBatch RegBatch = new PurgeOldIntegrationLogsBatch();
      Integer batchSize = Test.isRunningTest() ? 500 : 6;
      System.debug('batchsize= '+batchSize);
      Database.ExecuteBatch(RegBatch,batchSize);
    Test.stopTest();
  }
}