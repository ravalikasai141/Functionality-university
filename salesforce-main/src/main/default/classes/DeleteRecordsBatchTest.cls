@isTest
private class DeleteRecordsBatchTest {

    @isTest
    private static void itShouldDeleteRecords() {

        Map<String, Object> accountFieldMap = new Map<String, Object>{ 'Profile_Company_ID__c' => '123456789' };

        List<Account> accountList = TestDataFactory.createAccounts(10, 'Business_Development_Account', false, accountFieldMap);
        Database.insert(accountList);

        System.assertNotEquals( 0, [ SELECT COUNT() FROM Account ] );
        
        Test.startTest();
            String query = 'Select id FROM Account';
            Integer batchSize = 10;
        	DeleteRecordsBatch deleteRecordsBatch = new DeleteRecordsBatch(query);
        	Database.executeBatch(deleteRecordsBatch, batchSize);
        Test.stopTest();

        System.assertEquals( 0, [ SELECT COUNT() FROM Account ] );

    }
}