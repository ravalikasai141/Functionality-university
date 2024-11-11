@isTest
public class SOPAttachmentBatchTest {
    @testSetup
	static void testSetup() {
        Account account = TestDataFactory.createAccount(true, true, null, 0);
        Attachment attachment = new Attachment(
            Body = Blob.valueOf('Test SOP Attachment'),
            Name = 'Test SOP Attachment',
            ParentId = account.Id
        );
        insert attachment;
    }

    static testmethod void test_SOPAttachmentBatch() {
        SOPAttachmentBatch batch = new SOPAttachmentBatch();
        Database.executeBatch(batch);
    }

    static testmethod void test_SOPAttachmentScheduler() {
		Test.startTest();
        SOPAttachmentBatch batch = new SOPAttachmentBatch();
			String CRON_EXP = '0 0 0 3 9 ? 2025';
			System.schedule('SOPAttachmentBatchTest', CRON_EXP, batch);
		Test.stopTest();
	}
}