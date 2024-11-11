@isTest
private class Test_OpportunityTriggerHelper {
	/*
    @testSetup
	static void testSetup(){
		country_list__c cntry = CreateTestData.createCountry1();
        State_Province__c stt = CreateTestData.createStateProvince();
        Locality__c lct = CreateTestData.createLocality();
        Account a = CreateTestData.createAccount1(cntry);
        Address__c addr = CreateTestData.createAddress(a, null, null, cntry, stt, lct, true, 'Billing');

        Qualification_Institution__c qi = new Qualification_Institution__c(Name = 'BPP University', Institution_Code__c = '12345678');
        insert qi;

        Programme__c pgrm = new Programme__c(
            Name = 'Test Program',
            BNR_FieldOfStudy_Code__c = 'ELEC',
            BNR_College_Code__c = '12345678',
            Microsite_Enabled__c = true,
            Programme_Status__c = 'Validated',
            School__c = 'Test School',
            Programme_Id__c = 'SBGLD1_sb8'
        );
        insert pgrm;

        Product2 pd = CreateTestData.createProduct(pgrm,'OFFERING');
		
		Id userId = [SELECT Id FROM User WHERE UserRole.Name = 'Sales Team [+Record Assignment]' AND IsActive = true ORDER BY Name LIMIT 1].Id;
        Owner_Assignment__c ownerAssignment = new Owner_Assignment__c(Name = 'Sales Team [+Record Assignment]', Last_Assignee__c = userId);
        insert ownerAssignment;

        Account account = new Account(Name = 'Round Robin 0', OwnerId = userId, RecordTypeId = Schema.Sobjecttype.Account.getRecordTypeInfosByName().get('Business Development Account').getRecordTypeId());
        insert account;

        List<Opportunity> opportunityList = new List<Opportunity>();
        for (Integer i = 0; i < 2; i++) {
            opportunityList.add(new Opportunity(AccountId = account.Id, CloseDate = System.today(), Name = 'Round Robin ' + i, OwnerId = userId, RecordTypeId = Schema.Sobjecttype.Opportunity.getRecordTypeInfosByName().get('Business Development').getRecordTypeId(), StageName = 'Quoting', BPP_Sub_Status__c = 'Other'));
        }
        insert opportunityList;
    }

    static testMethod void createOppWithOnePciAndBundle() {
        Account a = [SELECT Id FROM Account WHERE PersonEmail = 'john@john.com'];
        Product2 pd1 = [SELECT Id FROM Product2 WHERE Name = 'Test Course Instance'];
        Programme__c pgrm = [SELECT Id FROM Programme__c WHERE Name = 'Test Program'];
        PC_Bundle__c pcB = CreateTestData.createBundle('bId33242', 'fName', 3243.3);
        PC_Item__c pcI = CreateTestData.createPCItem(pd1, pcB, pgrm);
		
		Database.DMLOptions dbDML = new Database.DMLOptions(); 
		dbDML.DuplicateRuleHeader.allowSave = true;
		dbDML.DuplicateRuleHeader.runAsCurrentUser = true;

        Test.startTest();
            Opportunity opp1 = new Opportunity();
            opp1.AccountId = a.id;
            opp1.Name = 'test';
            opp1.StageName = 'Accepted - Conditional Firm';
            opp1.Enrolment_Status__c = 'Acceptance';
            opp1.Cycle_Override__c = 'Use Student Cycle';
            opp1.CloseDate = Date.valueOf('2015-02-27'); 
            opp1.BNR_Application_Decision_Comment__c = 'ABCD';
            opp1.SFDC_Attribute_Code_Select__c = 'FT~ Full Time Student';
            opp1.SFDC_Admissions_ADMT_Code_Select__c = 'DI~ Direct';
            opp1.SFDC_Admissions_STYPE_Code_Select__c = 'R~ Returning';
            opp1.SFDC_Admissions_RESD_Code_Select__c = 'E~ EU National';
            opp1.SFDC_Cohort_Code_Select__c = 'C6~ Cohort June';
            opp1.BNR_Level_Code_Text__c = 'AB';
            opp1.BNR_Degree_Code_Text__c = 'ABCD';
            opp1.PC_Attribute_Code__c = 'FT';
            opp1.PC_Attribute_Code_2__c = 'ACCE';
            opp1.PC_Attribute_Code_3__c = 'PT';
            opp1.SFDC_Attribute_Code_Select_v2__c = 'FT~ Full Time Student';
            opp1.Record_Source__c = 'Direct Apps';
            opp1.Course_Instance__c = pd1.id;
			Database.insert(opp1, dbDML);

            List<Opportunity> checkOpp = [SELECT Programme_Application__c, Mode__c, Location__c, Start_Date__c FROM Opportunity WHERE Id =: opp1.Id];
            for(Opportunity o : checkOpp){
                System.assertEquals(pgrm.Id, o.Programme_Application__c, 'Programme');
                System.assertEquals('Full Time', o.Mode__c, 'Mode');
                System.assertEquals('London - London City', o.Location__c, 'Location');
            }

            List<Opportunity_Product__c> oppProdList = [SELECT Opportunity__c, Product__c, Bundle_Name__c, Bundle_Id__c, Course_Focus__c FROM Opportunity_Product__c WHERE Opportunity__c =: opp1.Id];
            for(Opportunity_Product__c op : oppProdList){
                System.assertEquals(opp1.Id, op.Opportunity__c, 'Opportunity Id');
                System.assertEquals(pd1.Id, op.Product__c, 'Product');
                System.assertEquals('bId33242', op.Bundle_Id__c, 'Bundle Id');
                System.assertEquals('Primary', op.Course_Focus__c, 'Course Focus');
            }

        Test.stopTest();
    }

    static testMethod void createOppWithMultiplePciAndBundle() {
        Account a = [SELECT Id FROM Account WHERE PersonEmail = 'john@john.com'];
        Product2 pd1 = [SELECT Id FROM Product2 WHERE Name = 'Test Course Instance'];
        Programme__c pgrm = [SELECT Id FROM Programme__c WHERE Name = 'Test Program'];
        PC_Bundle__c pcB = CreateTestData.createBundle('bId33242', 'fName', 3243.3);
        PC_Item__c pcI1 = CreateTestData.createPCItem(pd1, pcB, pgrm);
        PC_Item__c pcI2 = CreateTestData.createPCItem(pd1, pcB, pgrm);
        PC_Item__c pcI3 = CreateTestData.createPCItem(pd1, pcB, pgrm);
		
		Database.DMLOptions dbDML = new Database.DMLOptions(); 
		dbDML.DuplicateRuleHeader.allowSave = true;
		dbDML.DuplicateRuleHeader.runAsCurrentUser = true;

        Test.startTest();
            Opportunity opp1 = new Opportunity();
            opp1.AccountId = a.id;
            opp1.Name = 'test';
            opp1.StageName = 'Accepted - Conditional Firm';
            opp1.Enrolment_Status__c = 'Acceptance';
            opp1.Cycle_Override__c = 'Use Student Cycle';
            opp1.CloseDate = Date.valueOf('2015-02-27'); 
            opp1.BNR_Application_Decision_Comment__c = 'ABCD';
            opp1.SFDC_Attribute_Code_Select__c = 'FT~ Full Time Student';
            opp1.SFDC_Admissions_ADMT_Code_Select__c = 'DI~ Direct';
            opp1.SFDC_Admissions_STYPE_Code_Select__c = 'R~ Returning';
            opp1.SFDC_Admissions_RESD_Code_Select__c = 'E~ EU National';
            opp1.SFDC_Cohort_Code_Select__c = 'C6~ Cohort June';
            opp1.BNR_Level_Code_Text__c = 'AB';
            opp1.BNR_Degree_Code_Text__c = 'ABCD';
            opp1.PC_Attribute_Code__c = 'FT';
            opp1.PC_Attribute_Code_2__c = 'ACCE';
            opp1.PC_Attribute_Code_3__c = 'PT';
            opp1.SFDC_Attribute_Code_Select_v2__c = 'FT~ Full Time Student';
            opp1.Record_Source__c = 'Direct Apps';
            opp1.Course_Instance__c = pd1.id;
			Database.insert(opp1, dbDML);

            List<Opportunity> checkOpp = [SELECT Programme_Application__c, Mode__c, Location__c, Start_Date__c FROM Opportunity WHERE Id =: opp1.Id];
            for(Opportunity o : checkOpp){
                System.assertEquals(pgrm.Id, o.Programme_Application__c, 'Programme');
                System.assertEquals('Full Time', o.Mode__c, 'Mode');
                System.assertEquals('London - London City', o.Location__c, 'Location');
            }

            List<Opportunity_Product__c> oppProdList = [SELECT Opportunity__c, Product__c, Bundle_Name__c, Bundle_Id__c, Course_Focus__c FROM Opportunity_Product__c WHERE Opportunity__c =: opp1.Id];
            for(Opportunity_Product__c op : oppProdList){
                System.assertEquals(opp1.Id, op.Opportunity__c, 'Opportunity Id');
                System.assertEquals(pd1.Id, op.Product__c, 'Product');
                System.assertEquals('bId33242', op.Bundle_Id__c, 'Bundle Id');
                System.assertEquals('Primary', op.Course_Focus__c, 'Course Focus');
            }

        Test.stopTest();
    }

    static testMethod void createOppWithPciNoBundle() {
        Account a = [SELECT Id FROM Account WHERE PersonEmail = 'john@john.com'];
        Product2 pd1 = [SELECT Id FROM Product2 WHERE Name = 'Test Course Instance'];
        Programme__c pgrm = [SELECT Id FROM Programme__c WHERE Name = 'Test Program'];
        PC_Item__c pcI = CreateTestData.createPCItem(pd1, null, pgrm);
		
		Database.DMLOptions dbDML = new Database.DMLOptions(); 
		dbDML.DuplicateRuleHeader.allowSave = true;
		dbDML.DuplicateRuleHeader.runAsCurrentUser = true;

        Test.startTest();
            Opportunity opp1 = new Opportunity();
            opp1.AccountId = a.id;
            opp1.Name = 'test';
            opp1.StageName = 'Accepted - Conditional Firm';
            opp1.Enrolment_Status__c = 'Acceptance';
            opp1.Cycle_Override__c = 'Use Student Cycle';
            opp1.CloseDate = Date.valueOf('2015-02-27'); 
            opp1.BNR_Application_Decision_Comment__c = 'ABCD';
            opp1.SFDC_Attribute_Code_Select__c = 'FT~ Full Time Student';
            opp1.SFDC_Admissions_ADMT_Code_Select__c = 'DI~ Direct';
            opp1.SFDC_Admissions_STYPE_Code_Select__c = 'R~ Returning';
            opp1.SFDC_Admissions_RESD_Code_Select__c = 'E~ EU National';
            opp1.SFDC_Cohort_Code_Select__c = 'C6~ Cohort June';
            opp1.BNR_Level_Code_Text__c = 'AB';
            opp1.BNR_Degree_Code_Text__c = 'ABCD';
            opp1.PC_Attribute_Code__c = 'FT';
            opp1.PC_Attribute_Code_2__c = 'ACCE';
            opp1.PC_Attribute_Code_3__c = 'PT';
            opp1.SFDC_Attribute_Code_Select_v2__c = 'FT~ Full Time Student';
            opp1.Record_Source__c = 'Direct Apps';
            opp1.Course_Instance__c = pd1.id;
			Database.insert(opp1, dbDML);

            List<Opportunity> checkOpp = [SELECT Programme_Application__c, Mode__c, Location__c, Start_Date__c FROM Opportunity WHERE Id =: opp1.Id];
            for(Opportunity o : checkOpp){
                System.assertEquals(pgrm.Id, o.Programme_Application__c, 'Programme');
                System.assertEquals('Full Time', o.Mode__c, 'Mode');
                System.assertEquals('London - London City', o.Location__c, 'Location');
            }

            List<Opportunity_Product__c> oppProdList = [SELECT Opportunity__c, Product__c, Bundle_Name__c, Bundle_Id__c, Course_Focus__c FROM Opportunity_Product__c WHERE Opportunity__c =: opp1.Id];
            System.assertEquals(1, oppProdList.size(), 'Opportunity_Product__c size');

        Test.stopTest();
    }

    static testMethod void createMultipleOppWithOnePciAndBundle() {
        List<Opportunity> opportunities = new List<Opportunity>();
        Account a = [SELECT Id FROM Account WHERE PersonEmail = 'john@john.com'];
        Product2 pd1 = [SELECT Id FROM Product2 WHERE Name = 'Test Course Instance'];
        Programme__c pgrm = [SELECT Id FROM Programme__c WHERE Name = 'Test Program'];
        PC_Bundle__c pcB = CreateTestData.createBundle('bId33242', 'fName', 3243.3);
        PC_Item__c pcI = CreateTestData.createPCItem(pd1, pcB, pgrm);
		
		Database.DMLOptions dbDML = new Database.DMLOptions(); 
		dbDML.DuplicateRuleHeader.allowSave = true;
		dbDML.DuplicateRuleHeader.runAsCurrentUser = true;

        Test.startTest();
            Opportunity opp1 = new Opportunity();
            opp1.AccountId = a.id;
            opp1.Name = 'test1';
            opp1.StageName = 'Accepted - Conditional Firm';
            opp1.Enrolment_Status__c = 'Acceptance';
            opp1.Cycle_Override__c = 'Use Student Cycle';
            opp1.CloseDate = Date.valueOf('2015-02-01'); 
            opp1.BNR_Application_Decision_Comment__c = 'ABCD';
            opp1.SFDC_Attribute_Code_Select__c = 'FT~ Full Time Student';
            opp1.SFDC_Admissions_ADMT_Code_Select__c = 'DI~ Direct';
            opp1.SFDC_Admissions_STYPE_Code_Select__c = 'R~ Returning';
            opp1.SFDC_Admissions_RESD_Code_Select__c = 'E~ EU National';
            opp1.SFDC_Cohort_Code_Select__c = 'C6~ Cohort June';
            opp1.BNR_Level_Code_Text__c = 'AB';
            opp1.BNR_Degree_Code_Text__c = 'ABCD';
            opp1.PC_Attribute_Code__c = 'FT';
            opp1.PC_Attribute_Code_2__c = 'ACCE';
            opp1.PC_Attribute_Code_3__c = 'PT';
            opp1.SFDC_Attribute_Code_Select_v2__c = 'FT~ Full Time Student';
            opp1.Record_Source__c = 'Direct Apps';
            opp1.Course_Instance__c = pd1.id;
            opportunities.add(opp1);

            Opportunity opp2 = new Opportunity();
            opp2.AccountId = a.id;
            opp2.Name = 'test2';
            opp2.StageName = 'Accepted - Conditional Firm';
            opp2.Enrolment_Status__c = 'Acceptance';
            opp2.Cycle_Override__c = 'Use Student Cycle';
            opp2.CloseDate = Date.valueOf('2015-02-02'); 
            opp2.BNR_Application_Decision_Comment__c = 'ABCD';
            opp2.SFDC_Attribute_Code_Select__c = 'FT~ Full Time Student';
            opp2.SFDC_Admissions_ADMT_Code_Select__c = 'DI~ Direct';
            opp2.SFDC_Admissions_STYPE_Code_Select__c = 'R~ Returning';
            opp2.SFDC_Admissions_RESD_Code_Select__c = 'E~ EU National';
            opp2.SFDC_Cohort_Code_Select__c = 'C6~ Cohort June';
            opp2.BNR_Level_Code_Text__c = 'AB';
            opp2.BNR_Degree_Code_Text__c = 'ABCD';
            opp2.PC_Attribute_Code__c = 'FT';
            opp2.PC_Attribute_Code_2__c = 'ACCE';
            opp2.PC_Attribute_Code_3__c = 'PT';
            opp2.SFDC_Attribute_Code_Select_v2__c = 'FT~ Full Time Student';
            opp2.Record_Source__c = 'Direct Apps';
            opp2.Course_Instance__c = pd1.id;
            opportunities.add(opp2);

            Opportunity opp3 = new Opportunity();
            opp3.AccountId = a.id;
            opp3.Name = 'test3';
            opp3.StageName = 'Accepted - Conditional Firm';
            opp3.Enrolment_Status__c = 'Acceptance';
            opp3.Cycle_Override__c = 'Use Student Cycle';
            opp3.CloseDate = Date.valueOf('2015-02-03'); 
            opp3.BNR_Application_Decision_Comment__c = 'ABCD';
            opp3.SFDC_Attribute_Code_Select__c = 'FT~ Full Time Student';
            opp3.SFDC_Admissions_ADMT_Code_Select__c = 'DI~ Direct';
            opp3.SFDC_Admissions_STYPE_Code_Select__c = 'R~ Returning';
            opp3.SFDC_Admissions_RESD_Code_Select__c = 'E~ EU National';
            opp3.SFDC_Cohort_Code_Select__c = 'C6~ Cohort June';
            opp3.BNR_Level_Code_Text__c = 'AB';
            opp3.BNR_Degree_Code_Text__c = 'ABCD';
            opp3.PC_Attribute_Code__c = 'FT';
            opp3.PC_Attribute_Code_2__c = 'ACCE';
            opp3.PC_Attribute_Code_3__c = 'PT';
            opp3.SFDC_Attribute_Code_Select_v2__c = 'FT~ Full Time Student';
            opp3.Record_Source__c = 'Direct Apps';
            opp3.Course_Instance__c = pd1.id;
            opportunities.add(opp3);
            
            Database.insert(opportunities, dbDML);

            List<Opportunity> checkOpp1 = [SELECT Programme_Application__c, Mode__c, Location__c, Start_Date__c FROM Opportunity WHERE Id =: opp1.Id];
            for(Opportunity o1 : checkOpp1){
                System.assertEquals(pgrm.Id, o1.Programme_Application__c, 'Programme');
                System.assertEquals('Full Time', o1.Mode__c, 'Mode');
                System.assertEquals('London - London City', o1.Location__c, 'Location');
            }

            List<Opportunity_Product__c> oppProdList1 = [SELECT Opportunity__c, Product__c, Bundle_Name__c, Bundle_Id__c, Course_Focus__c FROM Opportunity_Product__c WHERE Opportunity__c =: opp1.Id];
            for(Opportunity_Product__c op1 : oppProdList1){
                System.assertEquals(opp1.Id, op1.Opportunity__c, 'Opportunity Id');
                System.assertEquals(pd1.Id, op1.Product__c, 'Product');
                System.assertEquals('bId33242', op1.Bundle_Id__c, 'Bundle Id');
                System.assertEquals('Primary', op1.Course_Focus__c, 'Course Focus');
            }

            List<Opportunity> checkOpp2 = [SELECT Programme_Application__c, Mode__c, Location__c, Start_Date__c FROM Opportunity WHERE Id =: opp2.Id];
            for(Opportunity o2 : checkOpp2){
                System.assertEquals(pgrm.Id, o2.Programme_Application__c, 'Programme');
                System.assertEquals('Full Time', o2.Mode__c, 'Mode');
                System.assertEquals('London - London City', o2.Location__c, 'Location');
            }

            List<Opportunity_Product__c> oppProdList2 = [SELECT Opportunity__c, Product__c, Bundle_Name__c, Bundle_Id__c, Course_Focus__c FROM Opportunity_Product__c WHERE Opportunity__c =: opp2.Id];
            for(Opportunity_Product__c op2 : oppProdList2){
                System.assertEquals(opp2.Id, op2.Opportunity__c, 'Opportunity Id');
                System.assertEquals(pd1.Id, op2.Product__c, 'Product');
                System.assertEquals('bId33242', op2.Bundle_Id__c, 'Bundle Id');
                System.assertEquals('Primary', op2.Course_Focus__c, 'Course Focus');
            }

            List<Opportunity> checkOpp3 = [SELECT Programme_Application__c, Mode__c, Location__c, Start_Date__c FROM Opportunity WHERE Id =: opp3.Id];
            for(Opportunity o3 : checkOpp3){
                System.assertEquals(pgrm.Id, o3.Programme_Application__c, 'Programme');
                System.assertEquals('Full Time', o3.Mode__c, 'Mode');
                System.assertEquals('London - London City', o3.Location__c, 'Location');
            }

            List<Opportunity_Product__c> oppProdList3 = [SELECT Opportunity__c, Product__c, Bundle_Name__c, Bundle_Id__c, Course_Focus__c FROM Opportunity_Product__c WHERE Opportunity__c =: opp3.Id];
            for(Opportunity_Product__c op3 : oppProdList3){
                System.assertEquals(opp3.Id, op3.Opportunity__c, 'Opportunity Id');
                System.assertEquals(pd1.Id, op3.Product__c, 'Product');
                System.assertEquals('bId33242', op3.Bundle_Id__c, 'Bundle Id');
                System.assertEquals('Primary', op3.Course_Focus__c, 'Course Focus');
            }

        Test.stopTest();
    }

    static testMethod void createMulitpleOppWithPciNoBundle() {
        List<Opportunity> opportunities = new List<Opportunity>();
        Account a = [SELECT Id FROM Account WHERE PersonEmail = 'john@john.com'];
        Product2 pd1 = [SELECT Id FROM Product2 WHERE Name = 'Test Course Instance'];
        Programme__c pgrm = [SELECT Id FROM Programme__c WHERE Name = 'Test Program'];
        PC_Item__c pcI = CreateTestData.createPCItem(pd1, null, pgrm);
		
		Database.DMLOptions dbDML = new Database.DMLOptions(); 
		dbDML.DuplicateRuleHeader.allowSave = true;
		dbDML.DuplicateRuleHeader.runAsCurrentUser = true;

        Test.startTest();
            Opportunity opp1 = new Opportunity();
            opp1.AccountId = a.id;
            opp1.Name = 'test1';
            opp1.StageName = 'Accepted - Conditional Firm';
            opp1.Enrolment_Status__c = 'Acceptance';
            opp1.Cycle_Override__c = 'Use Student Cycle';
            opp1.CloseDate = Date.valueOf('2015-02-01'); 
            opp1.BNR_Application_Decision_Comment__c = 'ABCD';
            opp1.SFDC_Attribute_Code_Select__c = 'FT~ Full Time Student';
            opp1.SFDC_Admissions_ADMT_Code_Select__c = 'DI~ Direct';
            opp1.SFDC_Admissions_STYPE_Code_Select__c = 'R~ Returning';
            opp1.SFDC_Admissions_RESD_Code_Select__c = 'E~ EU National';
            opp1.SFDC_Cohort_Code_Select__c = 'C6~ Cohort June';
            opp1.BNR_Level_Code_Text__c = 'AB';
            opp1.BNR_Degree_Code_Text__c = 'ABCD';
            opp1.PC_Attribute_Code__c = 'FT';
            opp1.PC_Attribute_Code_2__c = 'ACCE';
            opp1.PC_Attribute_Code_3__c = 'PT';
            opp1.SFDC_Attribute_Code_Select_v2__c = 'FT~ Full Time Student';
            opp1.Record_Source__c = 'Direct Apps';
            opp1.Course_Instance__c = pd1.id;
            opportunities.add(opp1);

            Opportunity opp2 = new Opportunity();
            opp2.AccountId = a.id;
            opp2.Name = 'test2';
            opp2.StageName = 'Accepted - Conditional Firm';
            opp2.Enrolment_Status__c = 'Acceptance';
            opp2.Cycle_Override__c = 'Use Student Cycle';
            opp2.CloseDate = Date.valueOf('2015-02-02'); 
            opp2.BNR_Application_Decision_Comment__c = 'ABCD';
            opp2.SFDC_Attribute_Code_Select__c = 'FT~ Full Time Student';
            opp2.SFDC_Admissions_ADMT_Code_Select__c = 'DI~ Direct';
            opp2.SFDC_Admissions_STYPE_Code_Select__c = 'R~ Returning';
            opp2.SFDC_Admissions_RESD_Code_Select__c = 'E~ EU National';
            opp2.SFDC_Cohort_Code_Select__c = 'C6~ Cohort June';
            opp2.BNR_Level_Code_Text__c = 'AB';
            opp2.BNR_Degree_Code_Text__c = 'ABCD';
            opp2.PC_Attribute_Code__c = 'FT';
            opp2.PC_Attribute_Code_2__c = 'ACCE';
            opp2.PC_Attribute_Code_3__c = 'PT';
            opp2.SFDC_Attribute_Code_Select_v2__c = 'FT~ Full Time Student';
            opp2.Record_Source__c = 'Direct Apps';
            opp2.Course_Instance__c = pd1.id;
            opportunities.add(opp2);

            Opportunity opp3 = new Opportunity();
            opp3.AccountId = a.id;
            opp3.Name = 'test3';
            opp3.StageName = 'Accepted - Conditional Firm';
            opp3.Enrolment_Status__c = 'Acceptance';
            opp3.Cycle_Override__c = 'Use Student Cycle';
            opp3.CloseDate = Date.valueOf('2015-02-03'); 
            opp3.BNR_Application_Decision_Comment__c = 'ABCD';
            opp3.SFDC_Attribute_Code_Select__c = 'FT~ Full Time Student';
            opp3.SFDC_Admissions_ADMT_Code_Select__c = 'DI~ Direct';
            opp3.SFDC_Admissions_STYPE_Code_Select__c = 'R~ Returning';
            opp3.SFDC_Admissions_RESD_Code_Select__c = 'E~ EU National';
            opp3.SFDC_Cohort_Code_Select__c = 'C6~ Cohort June';
            opp3.BNR_Level_Code_Text__c = 'AB';
            opp3.BNR_Degree_Code_Text__c = 'ABCD';
            opp3.PC_Attribute_Code__c = 'FT';
            opp3.PC_Attribute_Code_2__c = 'ACCE';
            opp3.PC_Attribute_Code_3__c = 'PT';
            opp3.SFDC_Attribute_Code_Select_v2__c = 'FT~ Full Time Student';
            opp3.Record_Source__c = 'Direct Apps';
            opp3.Course_Instance__c = pd1.id;
            opportunities.add(opp3);
            
            Database.insert(opportunities, dbDML);

            List<Opportunity> checkOpp1 = [SELECT Programme_Application__c, Mode__c, Location__c, Start_Date__c FROM Opportunity WHERE Id =: opp1.Id];
            for(Opportunity o1 : checkOpp1){
                System.assertEquals(pgrm.Id, o1.Programme_Application__c, 'Programme');
                System.assertEquals('Full Time', o1.Mode__c, 'Mode');
                System.assertEquals('London - London City', o1.Location__c, 'Location');
            }

            List<Opportunity_Product__c> oppProdList1 = [SELECT Opportunity__c, Product__c, Bundle_Name__c, Bundle_Id__c, Course_Focus__c FROM Opportunity_Product__c WHERE Opportunity__c =: opp1.Id];
            System.assertEquals(1, oppProdList1.size(), 'Opportunity_Product__c size');

            List<Opportunity> checkOpp2 = [SELECT Programme_Application__c, Mode__c, Location__c, Start_Date__c FROM Opportunity WHERE Id =: opp2.Id];
            for(Opportunity o2 : checkOpp2){
                System.assertEquals(pgrm.Id, o2.Programme_Application__c, 'Programme');
                System.assertEquals('Full Time', o2.Mode__c, 'Mode');
                System.assertEquals('London - London City', o2.Location__c, 'Location');
            }

            List<Opportunity_Product__c> oppProdList2 = [SELECT Opportunity__c, Product__c, Bundle_Name__c, Bundle_Id__c, Course_Focus__c FROM Opportunity_Product__c WHERE Opportunity__c =: opp2.Id];
            System.assertEquals(1, oppProdList2.size(), 'Opportunity_Product__c size');

            List<Opportunity> checkOpp3 = [SELECT Programme_Application__c, Mode__c, Location__c, Start_Date__c FROM Opportunity WHERE Id =: opp3.Id];
            for(Opportunity o3 : checkOpp3){
                System.assertEquals(pgrm.Id, o3.Programme_Application__c, 'Programme');
                System.assertEquals('Full Time', o3.Mode__c, 'Mode');
                System.assertEquals('London - London City', o3.Location__c, 'Location');
            }

            List<Opportunity_Product__c> oppProdList3 = [SELECT Opportunity__c, Product__c, Bundle_Name__c, Bundle_Id__c, Course_Focus__c FROM Opportunity_Product__c WHERE Opportunity__c =: opp3.Id];
            System.assertEquals(1, oppProdList3.size(), 'Opportunity_Product__c size');

        Test.stopTest();
    }
    
    static testMethod void createApplicationOpportunity() {
        Account a = [SELECT Id FROM Account WHERE PersonEmail = 'john@john.com'];
		
		Database.DMLOptions dbDML = new Database.DMLOptions(); 
		dbDML.DuplicateRuleHeader.allowSave = true;
		dbDML.DuplicateRuleHeader.runAsCurrentUser = true;
        
        Test.startTest();
            Opportunity opp1 = new Opportunity();
            opp1.AccountId = a.id;
            opp1.Name = 'test1';
            opp1.StageName = 'Application';
            opp1.Enrolment_Status__c = 'N/A';
            opp1.CloseDate = Date.valueOf('2015-02-01');
            Database.insert(opp1, dbDML);
            
            a.Student_Type__pc = 'EU';
            Database.update(a, dbDML);
            
            Opportunity opp2 = new Opportunity();
            opp2.AccountId = a.id;
            opp2.Name = 'test2';
            opp2.StageName = 'Application';
            opp2.Enrolment_Status__c = 'N/A';
            opp2.CloseDate = Date.valueOf('2015-02-01');
            Database.insert(opp2, dbDML);
            
            a.Student_Type__pc = 'International';
            Database.update(a, dbDML);
            
            Opportunity opp3 = new Opportunity();
            opp3.AccountId = a.id;
            opp3.Name = 'test1';
            opp3.StageName = 'Application';
            opp3.Enrolment_Status__c = 'N/A';
            opp3.CloseDate = Date.valueOf('2015-02-01');
            Database.insert(opp3, dbDML);
        Test.stopTest();
    }
    
    static testMethod void testRegistrationStatusOutstanding() {
        Account a = [SELECT Id FROM Account WHERE PersonEmail = 'john@john.com'];
		
		Database.DMLOptions dbDML = new Database.DMLOptions(); 
		dbDML.DuplicateRuleHeader.allowSave = true;
		dbDML.DuplicateRuleHeader.runAsCurrentUser = true;

        Test.startTest();
            Opportunity opp = new Opportunity();
        	opp.RecordTypeId = Schema.Sobjecttype.Opportunity.getRecordTypeInfosByName().get('Application').getRecordTypeId();
            opp.AccountId = a.id;
            opp.Name = 'test';
            opp.StageName = 'Application';
            opp.CloseDate = Date.valueOf('2021-02-03'); 
            opp.Passport__c = 'Outstanding';
            opp.Degree_Transcript__c = 'Outstanding';
            opp.Degree_Certificate__c = 'Outstanding';
            opp.Proof_of_Exemptions__c = 'Outstanding';
            opp.Visa_Confirmation__c = 'Outstanding';
            opp.EU_Settlement_Evidence__c = 'Outstanding';
            opp.BCAT__c = 'Outstanding';
            opp.Inn_of_Court__c = 'Outstanding';
            opp.Certificate_of_Academic_Standing__c = 'Outstanding';
            opp.Faculty_Approval__c = 'Outstanding';
        	opp.ACCA_Status_Report__c = 'Outstanding';
            opp.School_Leaving_Level_3_Certificate__c = 'Outstanding';
            opp.Highest_Qualification_Certificate__c = 'Outstanding';
            opp.Highest_Qualification_Transcript__c = 'Outstanding';
            opp.Confirmation_of_Contact_Details__c = 'Outstanding';
            opp.English_Language_Certificate__c = 'Outstanding';
            opp.BRP__c = 'Outstanding';
            opp.GDL_PGDL_Transcript__c = 'Outstanding';
            opp.Stamped_Entry_Clearance__c = 'Outstanding';
            Database.insert(opp, dbDML);

            Opportunity checkOpp = [SELECT Registration_Status__c FROM Opportunity WHERE Id =: opp.Id];
            System.assertEquals('Outstanding', checkOpp.Registration_Status__c);

        Test.stopTest();
    }
    
    static testMethod void testRegistrationStatusSubmitted() {
        Account a = [SELECT Id FROM Account WHERE PersonEmail = 'john@john.com'];
		
		Database.DMLOptions dbDML = new Database.DMLOptions(); 
		dbDML.DuplicateRuleHeader.allowSave = true;
		dbDML.DuplicateRuleHeader.runAsCurrentUser = true;

        Test.startTest();
            Opportunity opp = new Opportunity();
        	opp.RecordTypeId = Schema.Sobjecttype.Opportunity.getRecordTypeInfosByName().get('Application').getRecordTypeId();
            opp.AccountId = a.id;
            opp.Name = 'test';
            opp.StageName = 'Application';
            opp.CloseDate = Date.valueOf('2021-02-03'); 
            opp.Passport__c = 'Submitted';
            opp.Degree_Transcript__c = 'Validated';
            opp.Degree_Certificate__c = 'Not Applicable';
            opp.Proof_of_Exemptions__c = 'Submitted';
            opp.Visa_Confirmation__c = 'Validated';
            opp.EU_Settlement_Evidence__c = 'Not Applicable';
            opp.BCAT__c = 'Submitted';
            opp.Inn_of_Court__c = 'Validated';
            opp.Certificate_of_Academic_Standing__c = 'Not Applicable';
            opp.Faculty_Approval__c = 'Submitted';
            opp.School_Leaving_Level_3_Certificate__c = 'Validated';
            opp.ACCA_Status_Report__c = 'Not Applicable';
            opp.Highest_Qualification_Certificate__c = 'Submitted';
            opp.Highest_Qualification_Transcript__c = 'Validated';
            opp.Confirmation_of_Contact_Details__c = 'Not Applicable';
        	opp.English_Language_Certificate__c = 'Not Applicable';
            opp.BRP__c = 'Not Applicable';
            opp.GDL_PGDL_Transcript__c = 'Not Applicable';
            opp.Stamped_Entry_Clearance__c = 'Not Applicable';
            Database.insert(opp, dbDML);

            Opportunity checkOpp = [SELECT Registration_Status__c FROM Opportunity WHERE Id =: opp.Id];
            System.assertEquals('Submitted', checkOpp.Registration_Status__c);

        Test.stopTest();
    }

    static testMethod void testRegistrationStatusValidated() {
        Account a = [SELECT Id FROM Account WHERE PersonEmail = 'john@john.com'];
		
		Database.DMLOptions dbDML = new Database.DMLOptions(); 
		dbDML.DuplicateRuleHeader.allowSave = true;
		dbDML.DuplicateRuleHeader.runAsCurrentUser = true;

        Test.startTest();
            Opportunity opp = new Opportunity();
        	opp.RecordTypeId = Schema.Sobjecttype.Opportunity.getRecordTypeInfosByName().get('Application').getRecordTypeId();
            opp.AccountId = a.id;
            opp.Name = 'test';
            opp.StageName = 'Application';
            opp.CloseDate = Date.valueOf('2021-02-03'); 
            opp.Passport__c = 'Validated';
            opp.Degree_Transcript__c = 'Validated';
            opp.Degree_Certificate__c = 'Not Applicable';
            opp.Proof_of_Exemptions__c = 'Validated';
            opp.Visa_Confirmation__c = 'Validated';
            opp.EU_Settlement_Evidence__c = 'Not Applicable';
            opp.BCAT__c = 'Validated';
            opp.Inn_of_Court__c = 'Validated';
            opp.Certificate_of_Academic_Standing__c = 'Not Applicable';
            opp.Faculty_Approval__c = 'Validated';
            opp.School_Leaving_Level_3_Certificate__c = 'Validated';
            opp.ACCA_Status_Report__c = 'Not Applicable';
            opp.Highest_Qualification_Certificate__c = 'Validated';
            opp.Highest_Qualification_Transcript__c = 'Validated';
            opp.Confirmation_of_Contact_Details__c = 'Not Applicable';
        	opp.English_Language_Certificate__c = 'Not Applicable';
            opp.BRP__c = 'Not Applicable';
            opp.GDL_PGDL_Transcript__c = 'Not Applicable';
            opp.Stamped_Entry_Clearance__c = 'Not Applicable';
            Database.insert(opp, dbDML);

            Opportunity checkOpp = [SELECT Registration_Status__c FROM Opportunity WHERE Id =: opp.Id];
            System.assertEquals('Validated', checkOpp.Registration_Status__c);

        Test.stopTest();
    }

    @isTest
	static void test_reassignRecords_OpportunityReassignment() {
		List<Opportunity> opportunityListBefore = [SELECT Id, OwnerId FROM Opportunity WHERE Name LIKE 'Round Robin%'];
        Id ownerIdBefore = opportunityListBefore.get(0).OwnerId;
		for (Opportunity opportunity : opportunityListBefore) {
			opportunity.OwnerId = Label.Default_Sales_Owner;
		}
		
        Test.startTest();
		    update opportunityListBefore;
        Test.stopTest();

        List<Opportunity> opportunityListAfter = [SELECT Id, OwnerId FROM Opportunity];
        for (Opportunity opportunity : opportunityListAfter) {
			System.assert(opportunity.OwnerId != ownerIdBefore);
			System.assert(opportunity.OwnerId != Label.Default_Sales_Owner);
		}
	}

    static testMethod void test_populateHESAStudentID() {
        Account a = [SELECT Id, HESA_Student_ID_SID__c FROM Account WHERE PersonEmail = 'john@john.com'];
        Product2 pd1 = [SELECT Id FROM Product2 WHERE Name = 'Test Course Instance'];
        Programme__c pgrm = [SELECT Id FROM Programme__c WHERE Name = 'Test Program'];
        PC_Bundle__c pcB = CreateTestData.createBundle('bId33242', 'fName', 3243.3);
        PC_Item__c pcI = CreateTestData.createPCItem(pd1, pcB, pgrm);
        
        Database.DMLOptions dbDML = new Database.DMLOptions(); 
        dbDML.DuplicateRuleHeader.allowSave = true;
        dbDML.DuplicateRuleHeader.runAsCurrentUser = true;
    
        Test.startTest();
            Opportunity opp1 = new Opportunity();
        	opp1.RecordTypeId = Schema.Sobjecttype.Opportunity.getRecordTypeInfosByName().get('Application').getRecordTypeId();
            opp1.AccountId = a.id;
            opp1.Name = 'test';
            opp1.StageName = 'Accepted - Conditional Firm';
            opp1.Enrolment_Status__c = 'Acceptance';
            opp1.Cycle_Override__c = 'Use Student Cycle';
            opp1.CloseDate = Date.valueOf('2015-02-27'); 
            opp1.BNR_Application_Decision_Comment__c = 'ABCD';
            opp1.SFDC_Attribute_Code_Select__c = 'FT~ Full Time Student';
            opp1.SFDC_Admissions_ADMT_Code_Select__c = 'DI~ Direct';
            opp1.SFDC_Admissions_STYPE_Code_Select__c = 'R~ Returning';
            opp1.SFDC_Admissions_RESD_Code_Select__c = 'E~ EU National';
            opp1.SFDC_Cohort_Code_Select__c = 'C6~ Cohort June';
            opp1.BNR_Level_Code_Text__c = 'AB';
            opp1.BNR_Degree_Code_Text__c = 'ABCD';
            opp1.PC_Attribute_Code__c = 'FT';
            opp1.PC_Attribute_Code_2__c = 'ACCE';
            opp1.PC_Attribute_Code_3__c = 'PT';
            opp1.SFDC_Attribute_Code_Select_v2__c = 'FT~ Full Time Student';
            opp1.Record_Source__c = 'Direct Apps';
            opp1.Course_Instance__c = pd1.id;
            Database.insert(opp1, dbDML);
        Test.stopTest();
        
        System.assert(a.HESA_Student_ID_SID__c == null);
        opp1.StageName = 'Accepted - Pmt Received';
        update opp1;
        
        Account afterOppStatusChange = [SELECT Id, HESA_Student_ID_SID__c FROM Account WHERE Id =: a.Id];
        System.assert(afterOppStatusChange.HESA_Student_ID_SID__c != null);
    }*/
}