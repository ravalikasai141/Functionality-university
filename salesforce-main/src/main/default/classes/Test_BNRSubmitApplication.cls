/**
 * This class contains unit tests for validating the behavior of Apex classe BNR Submit Application
 */
@isTest
private class Test_BNRSubmitApplication {

    @isTest
    private static void unitTest1(){ 
        Legal_Entity__c settings = new Legal_Entity__c();
        settings.Name = 'UC~COL';
        settings.Name__c = 'UC~COL';
        settings.Entity__c = 'COL';
        insert settings;
        
        country_list__c cntry = CreateTestData.createCountry1();
        State_Province__c stt = CreateTestData.createStateProvince();
        Locality__c lct = CreateTestData.createLocality();
        Account a = CreateTestData.createAccount1(cntry);
        a.Domicile__pc = 'XF~ England';
        a.Student_Occupation__pc = '0000~ Not stated';
        update a;
        
        Address__c addr = CreateTestData.createAddress(a, null, null, cntry, stt, lct, true, 'Billing');
        Opportunity o = CreateTestData.createOpportunity(a);
        o.Customer_Group__c = 'SELFFUND';
        o.Sponsorship_Level__c = 'Partial';
        o.Sponsorship_Amount__c = 2000;
        o.Purchase_Order_Number__c = '1234567890';
        update o;
        
        Programme__c pgrm = CreateTestData.createProgram();
        Product2 pd = CreateTestData.createProduct(pgrm,'OFFERING');
        pd.BNR_FieldofStudy_Start_Date__c = Date.newInstance(2022, 06, 01);
        update pd;
        
        Test.startTest();
            Opportunity_Product__c oppPrd = CreateTestData.createOppProduct(o, pd, true);
            String strId = BNR_SubmitApplication.Submit(o.id);
            pgrm = CreateTestData.createErrorProgram();
            pd = CreateTestData.createErrorProduct(pgrm,'OFFERING');
            oppPrd = CreateTestData.createOppProduct(o, pd, true);
            strId = BNR_SubmitApplication.Submit(o.id);
        Test.stopTest();
    }
    
    @isTest
    private static void unitTest2(){ 
        Legal_Entity__c settings = new Legal_Entity__c();
        settings.Name = 'UC~COL';
        settings.Name__c = 'UC~COL';
        settings.Entity__c = 'COL';
        insert settings;
        
        country_list__c cntry = CreateTestData.createCountry1();
        State_Province__c stt = CreateTestData.createStateProvince();
        Locality__c lct = CreateTestData.createLocality();
        Account a = CreateTestData.createAccount1(cntry);
        a.Domicile__pc = 'XF~ England';
        a.Student_Occupation__pc = '0000~ Not stated';
        update a;
        
        Address__c addr = CreateTestData.createAddress(a, null, null, cntry, stt, lct, true, 'Billing');
        Opportunity o = CreateTestData.createOpportunity(a);
        o.Customer_Group__c = 'SELFFUND';
        o.Sponsorship_Level__c = 'Partial';
        o.Sponsorship_Amount__c = 2000;
        o.Purchase_Order_Number__c = '1234567890';
        update o;
        
        Programme__c pgrm = CreateTestData.createProgram();
        Product2 pd = CreateTestData.createProduct(pgrm,'OFFERING');
        pd.BNR_FieldofStudy_Start_Date__c = Date.newInstance(2022, 06, 01);
        update pd;
        
        Test.startTest();
            Opportunity_Product__c oppPrd = CreateTestData.createOppProduct(o, pd, true);
            String strId = BNR_SubmitApplication.Submit(o.id);
            pgrm = CreateTestData.createErrorProgram();
            pd = CreateTestData.createErrorProduct(pgrm,'OFFERING');
            oppPrd = CreateTestData.createOppProduct(o, pd, true);
            BNR_SubmitApplication.Submitnew(o.id);
        Test.stopTest();
    }
}