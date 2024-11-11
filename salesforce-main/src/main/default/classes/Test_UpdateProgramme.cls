/**
 * This class contains unit tests for validating the behavior of Apex classes
 * UpdateProgramme and UpdateBundle outbound services
 */
 @isTest
private class Test_UpdateProgramme {
    static testMethod void unitTest1(){
        Test.startTest();
        List<UpdateProgramme.Request> programmeList = new List<UpdateProgramme.Request>();
        UpdateProgramme.Request pmgList = new UpdateProgramme.Request();
        Programme__c prg = new Programme__c();
        prg.Name = 'ACCA (3 Papers)';
        prg.Programme_Id__c = '1234567890';
        prg.Programme_Status__c = 'Validated';
        prg.School__c = 'Business School';
        prg.Microsite_Enabled__c = true;
        prg.BNR_FieldOfStudy_Code__c = 'Test';
        pmgList.programme = prg;
        List< UpdateProgramme.Item> inst= new List< UpdateProgramme.Item>();
        UpdateProgramme.Item it = new  UpdateProgramme.Item();
        Product2 prod = new Product2();
        prod.Name = 'test';
        prod.IsActive = true;
        prod.On_Web__c = true;
        prod.Programme__c = prg.Id;
        prod.Mode__c = 'Full Time';
        prod.Location__c = 'Test - TestCity';   
        prod.Instance_Id__c = 'AAA';     
        it.instance = prod;
        List<String> bIds = new List<String>();
        bIds.add('001');
        it.bundleIds = bIds;
        inst.add(it);
        pmgList.instances = inst;
        programmeList.add(pmgList);
        UpdateProgramme.Response res = UpdateProgramme.doPost(programmeList);
        
        List<UpdateBundle.Bundle> lstB = new List<UpdateBundle.Bundle>();
        UpdateBundle.Bundle bun = new UpdateBundle.Bundle();
        bun.name = 'testb';
        bun.description = 'testde';
        bun.bundleId = '001';
        bun.itemIds = new List<String>();
        bun.itemIds.add('AAA');
        bun.childBundleIds = new List<String>();
        bun.childBundleIds.add('002');
        lstB.add(bun);
        bun = new UpdateBundle.Bundle();
        bun.name = 'testb1';
        bun.description = 'testde1';
        bun.bundleId = '002';
        bun.itemIds = new List<String>();
        bun.itemIds.add('AAA');
        bun.childBundleIds = new List<String>();
        bun.childBundleIds.add('');
        lstB.add(bun);
        UpdateBundle.Response res1 = UpdateBundle.doPost(lstB);
        
        
        List<UpdateProgramme.Request> programmeList1 = new List<UpdateProgramme.Request>();
        UpdateProgramme.Request pmgList1 = new UpdateProgramme.Request();
        pmgList1.programme = prg;
        List<UpdateProgramme.Item> inst1= new List<UpdateProgramme.Item>();
        UpdateProgramme.Item it1 = new  UpdateProgramme.Item();
        Product2 prod1 = new Product2();
        prod1.Name = 'test';
        prod1.IsActive = true;
        prod1.On_Web__c = true;
        prod1.Programme__c = prg.Id;
        prod1.Mode__c = 'Full Time';
        prod1.Location__c = 'Test - TestCity';   
        prod1.Instance_Id__c = 'AAA';     
        it1.instance = prod1;
        List<String> bIds1 = new List<String>();
        bIds1.add('001');
        bIds1.add('002');
        it1.bundleIds = bIds;
        inst1.add(it1);
        pmgList1.instances = inst1;
        programmeList1.add(pmgList1);
        UpdateProgramme.Response res2 = UpdateProgramme.doPost(programmeList1);
        
        Test.stopTest();
    }
}