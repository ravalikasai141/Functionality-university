@isTest
private class OrderHelperTest {
    @testSetup
    static void testSetup() {
        Database.DMLOptions dbDML = new Database.DMLOptions(); 
        dbDML.DuplicateRuleHeader.allowSave = true;
        dbDML.DuplicateRuleHeader.runAsCurrentUser = true;

        Account clientAccount = TestDataFactory.createAccount(false, false, null, 0);
        Database.insert(clientAccount, dbDML);

        Account studentAccount = TestDataFactory.createAccount(false, true, clientAccount.Id, 1);
        Database.insert(studentAccount, dbDML);
        
        country_list__c cntry = CreateTestData.createCountry1();

        Address__c address = TestDataFactory.createAddress(false, 0, clientAccount, cntry, true, true);
        Database.insert(address, dbDML);
    }

    @isTest
    static void test_updateOrderAddress() {
        Account clientAccount = [SELECT Id FROM Account WHERE IsPersonAccount = FALSE];
        Address__c address = [SELECT Id FROM Address__c WHERE Student__c =: clientAccount.Id];
        Order order = TestDataFactory.createOrder(false, 0, clientAccount, null, address);
        order.OwnerId = UserInfo.getUserId();
        insert order;

        Order orderAfterInsert = [SELECT Id, ShippingAddress FROM Order WHERE Id = :order.Id];
        System.assert(orderAfterInsert.ShippingAddress != null);
    }

    @isTest
    static void test_priceCalculationFailureAlert() {
        Account clientAccount = [SELECT Id FROM Account WHERE IsPersonAccount = FALSE];
        Address__c address = [SELECT Id FROM Address__c WHERE Student__c =: clientAccount.Id];
        Order order = TestDataFactory.createOrder(true, 0, clientAccount, null, address);

        Order orderAfterInsert = [SELECT Id FROM Order WHERE Id =: order.Id];
        orderAfterInsert.SBQQ__PriceCalcStatus__c = 'Failed';
        
        Test.startTest();
            System.assertEquals(0, OrderHelper.messageList.size(), 'No emails should be sent yet');
            update orderAfterInsert;
            System.assertEquals(1, OrderHelper.messageList.size(), 'One email should have been sent');
        Test.stopTest();
    }
}