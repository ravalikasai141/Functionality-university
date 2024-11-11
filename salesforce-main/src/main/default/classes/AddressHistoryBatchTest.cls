@isTest (SeeAllData=true)
public class AddressHistoryBatchTest {
    @isTest
    static void test_AddressHistoryBatch() {
        AddressHistoryBatch batch = new AddressHistoryBatch();
        Database.executeBatch(batch);
    }

    @isTest
    static void test_AddressHistoryBatchSchedule() {
		Test.startTest();
			String CRON_EXP = '0 0 0 3 9 ? 2025';
			System.schedule('AddressHistoryBatch_Test', CRON_EXP, new AddressHistoryBatch());
		Test.stopTest();
	}
}