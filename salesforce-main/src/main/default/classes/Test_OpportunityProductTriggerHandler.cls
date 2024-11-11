/**
 * This class contains unit tests for validating the behavior of Apex classe OpportunityProductTriggerHandler.
 */
@isTest
private class Test_OpportunityProductTriggerHandler {

    static testMethod void myUnitTest() {
        country_list__c cntry = CreateTestData.createCountry1();
        State_Province__c stt = CreateTestData.createStateProvince();
        Locality__c lct = CreateTestData.createLocality();
        Account a = CreateTestData.createAccount1(cntry);
        Address__c addr = CreateTestData.createAddress(a, null, null, cntry, stt, lct, true, 'Billing');
        Opportunity o = CreateTestData.createOpportunity(a);
        Programme__c pgrm = CreateTestData.createProgram();
        Product2 pd = CreateTestData.createProduct(pgrm,'OFFERING');
        pd.BPP_ProductFactoryID__c = 'qwertyuiop12345xxxx';
        update pd;
        Test.startTest();
        Opportunity_Product__c oppPrd = CreateTestData.createOppProduct(o, pd, true);
        
        Product2 pd1 = CreateTestData.createProduct(pgrm,'OFFERING');
        pd1.Instance_Id__c = '3242';
        update pd1;
         Opportunity_Product__c  oppPrd1;
        try{
            oppPrd1 = CreateTestData.createOppProduct(o, pd1, false);
            oppPrd1.Course_Focus__c = 'Primary';
            update oppPrd1;
        }catch(Exception e){
            system.debug(e.getmessage());
        }
        oppPrd1.Course_Focus__c = 'Secondary';
        update oppPrd1;
        delete oppPrd;
        
        Test.stopTest();
    }
}