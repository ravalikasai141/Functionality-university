@isTest (SeeAllData=true)
public class LoginHistoryBatchTest {
    static testmethod void test_loginHistoryBatchTest() {
        LoginHistoryBatch batch = new LoginHistoryBatch(System.today().addDays(-20), System.today());
        Database.executeBatch(batch);
    }

    static testmethod void test_loginHistoryScheduler() {
		Test.startTest();
            LoginHistoryBatch batch = new LoginHistoryBatch(System.today().addDays(-20), System.today());
			String CRON_EXP = '0 0 0 3 9 ? 2025';
			System.schedule('LoginHistoryBatch', CRON_EXP, batch);
		Test.stopTest();
	}
}