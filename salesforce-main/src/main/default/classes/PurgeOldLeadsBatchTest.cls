/**********************************************************************
Name: PurgeOldLeadsBatchTest
Purpose: Test Class for the Class (PurgeOldLeadsBatch)
-------
History
-------
VERSION  AUTHOR             DATE              DETAIL
0.1 -   David Lovejoy     02/12/2020      INITIAL DEVELOPMENT
***********************************************************************/
@isTest
public class PurgeOldLeadsBatchTest {
    public static testmethod void MassDeleteOldLeadTest() {
        Lead l = new Lead();
        l.RecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Prospective Student').getRecordTypeId();
        l.LastName = 'PurgeOldLead';
        l.OwnerId = UserInfo.getUserId();
        insert l;
		
		Datetime datetimeThreeYearsAgo = System.Today().addYears(-3);
        Test.setCreatedDate(l.Id, datetimeThreeYearsAgo);

        Test.startTest();
			PurgeOldLeadsBatch leadBatch = new PurgeOldLeadsBatch();
            Integer batchSize = Test.isRunningTest() ? 500 : 6;
			Database.executeBatch(leadBatch, batchSize);
        Test.stopTest();
    }
}