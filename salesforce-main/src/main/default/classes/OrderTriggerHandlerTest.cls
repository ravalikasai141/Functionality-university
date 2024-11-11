@isTest
public class OrderTriggerHandlerTest {
	@isTest
    static void test_handleBeforeInsertUpdateAndDelete() {
		Account studentAccount = TestDataFactory.createAccount(false,true,null,1);
        studentAccount.FirstName = 'TestDataFactoryStudent';
        insert studentAccount;
		
		country_list__c cntry = CreateTestData.createCountry1();
		
		Address__c address1 = TestDataFactory.createAddress(false, 0, studentAccount, cntry, true, true);
        address1.Street_2__c = 'test 2';
        address1.Street_3__c = 'test 3';
        insert address1;
		
		/* test start -  handleBeforeInsert */
			Order order = TestDataFactory.createOrder(false, 0, studentAccount, null, address1);
			insert order;
			
			Order orderCheck1 = [SELECT Ship_To_Address__c, ShippingStreet FROM Order WHERE Id =: order.Id];
			System.assertEquals(address1.Id, orderCheck1.Ship_To_Address__c, 'Order Ship to Address field should have been populated on Order creation');
			System.assertEquals('10 Test Street\ntest 2\ntest 3', orderCheck1.ShippingStreet, 'Order ShippingStreet field should have been populated using Street field on Address');
		/* test end - handleBeforeInsert */
		
		/* test start -  handleBeforeUpdate */
			delete address1;
			
			Address__c address2 = TestDataFactory.createAddress(true, 1, studentAccount, cntry, true, true);
        	
        	order.Ship_To_Address__c = NULL;
			update order;
        
        	order.Bill_To_Address__c = address2.Id;
			update order;
			
			Order orderCheck2 = [SELECT Bill_To_Address__c, BillingStreet FROM Order WHERE Id =: order.Id];
			System.assertEquals('11 Test Street', orderCheck2.BillingStreet, 'Order BillingStreet field should have been updated using Street field on new Address');
		/* test end -  handleBeforeUpdate */
        
        /* test start -  handleBeforeDelete */
        	delete order;
        /* test start -  handleBeforeDelete */
	}
}