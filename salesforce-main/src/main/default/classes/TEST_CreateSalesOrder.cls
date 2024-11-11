@isTest()
public class TEST_CreateSalesOrder {
    static testMethod void myUnitTest() {
        country_list__c cntry = CreateTestData.createCountry1();
        State_Province__c stt = CreateTestData.createStateProvince();
        Locality__c lct = CreateTestData.createLocality();
        Account a = CreateTestData.createAccount1(cntry);
        Address__c addr = CreateTestData.createAddress(a, null, null, cntry, stt, lct, true, 'Billing');
        Opportunity o = CreateTestData.createOpportunity(a);
        Programme__c pgrm = CreateTestData.createProgram();
        Product2 pd = CreateTestData.createProduct(pgrm,'OFFERING');
        
        Test.startTest();
            Opportunity_Product__c oppPrd = CreateTestData.createOppProduct(o, pd, true);
            String result = CreateSalesOrder.SalesOrderInfo(o.id);
        Test.stopTest();
    }
    
    static testMethod void myUnitTest2() {
        country_list__c cntry = CreateTestData.createCountry1();
        State_Province__c stt = CreateTestData.createStateProvince();
        Locality__c lct = CreateTestData.createLocality();
        Account a = CreateTestData.createAccount1(cntry);
        Address__c addr = CreateTestData.createAddress(a, null, null, cntry, stt, lct, true, 'Billing');
        Opportunity o = CreateTestData.createOpportunity(a);
        Programme__c pgrm = CreateTestData.createProgram();
        Product2 pd = CreateTestData.createProduct(pgrm,'OFFERING');
        
        Test.startTest();
            Opportunity_Product__c oppPrd = CreateTestData.createOppProduct(o, pd, true);
            String result = RegenerateSalesOrderCtrl.SalesOrder(o.id);
        Test.stopTest();
    }
}