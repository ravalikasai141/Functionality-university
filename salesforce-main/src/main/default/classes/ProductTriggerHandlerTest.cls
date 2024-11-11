/*
* @who   David Lovejoy <davidlovejoy@bpp.com>
* @what  Test class for ProductTrigger and ProductTriggerHandler
* @when  09/04/2021
*/
@isTest
public class ProductTriggerHandlerTest {
    @isTest
    static void test_ProductTrigger() {
        Product2 product1 = new Product2(
            Name = 'Test Product 1', BPP_ProductFactoryID__c = 'qwertyuiop', Family = 'Materials', Standalone_Material__c = FALSE
        );
        insert product1;

        Product2 product2 = new Product2(
            Name = 'Test Product 2', BPP_ProductFactoryID__c = 'qwertyuiop', Family = 'Materials', Standalone_Material__c = FALSE
        );

        Test.startTest();
		try {
			insert product2;
		} catch (Exception e) {
			System.assertEquals(true, e.getMessage().contains('We are unable to insert this Product. A duplicate Product Factory Id has been found on the following record'));
		}
		Test.stopTest();
    }
}