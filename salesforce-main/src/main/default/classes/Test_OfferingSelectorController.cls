/**
 * This class contains unit tests for validating the behavior of Apex class OfferingSelectorController.
 */
@isTest
private class Test_OfferingSelectorController {

    static testMethod void myUnitTest() {
        country_list__c cntry = CreateTestData.createCountry1();
        State_Province__c stt = CreateTestData.createStateProvince();
        Locality__c lct = CreateTestData.createLocality();
        Account a = CreateTestData.createAccount1(cntry);
        Address__c addr = CreateTestData.createAddress(a, null, null, cntry, stt, lct, true, 'Billing');
        Opportunity o = CreateTestData.createOpportunity(a);
        Programme__c pgrm = CreateTestData.createProgram();
        Product2 pd = CreateTestData.createProduct(pgrm,'OFFERING');
        //Opportunity_Product__c oppPrd = CreateTestData.createOppProduct(o, pd, true);
        Product2 pd1 = CreateTestData.createProduct(pgrm, 'OFFERING', 'name1', '0001', null, null);
        PC_Bundle__c pcB = CreateTestData.createBundle('bId33242', 'fName', 3243.3);
        PC_Bundle__c pcB1 = CreateTestData.createBundle('bId33240', 'fName1', 324.3);
        PC_Bundle_Extension__c pce = CreateTestData.createBundleExtension(pcB, pcB1);
        PC_Item__c pcI = CreateTestData.createPCItem(pd1, pcB, pgrm);
        PC_Item__c pcI1 = CreateTestData.createPCItem(pd1, null, pgrm);
        Test.startTest();
        Opportunity_Product__c oppPrd1 = new Opportunity_Product__c();
        oppPrd1.Opportunity__c = o.Id;
        Pagereference pg = new Pagereference('/apex/OfferingSelectorController');
        Test.setCurrentPage(pg);
        ApexPages.StandardController con = new ApexPages.StandardController(oppPrd1);   
        OfferingSelectorController osc = new OfferingSelectorController(con);
        
        osc.searchText = '';
        osc.searchOfferings();
        osc.searchProduct = 'name';
        osc.searchOfferings();
        
        List<OfferingSelectorController.ProductWrapper> p = osc.offeringSearchResults;
        p[0].isSelected = true;
        
        pg.getParameters().put('selectedOfferingId',pd1.Id);
        osc.offeringSelected();
        List<OfferingSelectorController.BundleWrapper> bw = osc.bundleSearchResults;
        bw[0].isSelected = true;
        pg.getParameters().put('selectedBundleId',pcb.Id);
        osc.bundleSelected();
        
        List<OfferingSelectorController.ItemWrapper> iw = osc.bundleContents;
        iw[0].isPrimary = true;
        pg.getParameters().put('selectedProductId',pd1.Id);
        osc.productPrimarySelected();
        
        osc.addProducts();
        osc.returnToOpportunity();
        
        
        oppPrd1 = new Opportunity_Product__c();
        oppPrd1.Opportunity__c = o.Id;
        con = new ApexPages.StandardController(oppPrd1);   
        osc = new OfferingSelectorController(con);
        Test.stopTest();
    }
}