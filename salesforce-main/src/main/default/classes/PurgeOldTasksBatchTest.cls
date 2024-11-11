/**********************************************************************
Name: PurgeOldTasksBatchTest
Purpose: Test Class for the Class(PurgeOldTasksBatch) which deletes Tasks that are older than 12 months                
-------                                                             
History                                                             
-------                                                             
VERSION  AUTHOR             DATE              DETAIL                              
0.1 -   David Lovejoy     15/10/2019      INITIAL DEVELOPMENT  
***********************************************************************/
@isTest
public class PurgeOldTasksBatchTest
{
    public static testmethod void MassDeleteOldTaskTest()
    {
        Lead l = new Lead();
        l.RecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Prospective Student').getRecordTypeId();
        l.LastName='Test Lead';
        l.OwnerId = UserInfo.getUserId();
        insert l;

		Task t = new Task();
        t.whoid = l.id;
        t.ownerid = l.OwnerId;
        t.Subject = 'A New Lead is Assigned to you';
        insert t;

        Test.startTest();
			PurgeOldTasksBatch taskBatch = new PurgeOldTasksBatch();
			Integer batchSize = Test.isRunningTest() ? 500 : 6;
			System.debug('PurgeOldTasks Test1: size = ' + batchSize);
			Database.ExecuteBatch(taskBatch, batchSize);
        Test.stopTest();
    }
}