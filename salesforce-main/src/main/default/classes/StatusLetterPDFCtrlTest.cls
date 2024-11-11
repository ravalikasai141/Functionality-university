@isTest
private class StatusLetterPDFCtrlTest
{
    static testMethod void StatusLetterTest() 
    {
        
        country_list__c cntry = CreateTestData.createCountry1();
        
        Account a1 = CreateTestData.createAccount1(cntry);
        a1.BNR_Banner_ID__pc = 'BP1234567';
        update a1;
        
        Id conId = [select Id, name, PersonContactId from Account where Id =:a1.Id].PersonContactId;
        
        Address__c addr = new Address__c();
        addr.Active__c = true;
        addr.Student__c = a1.Id;
        addr.Street_1__c = 'Test Address Line 1';
        addr.City__c = 'Test City';
        addr.Zip_Postal_Code__c = 'ABC DEF';
        addr.Lookup_Country__c = cntry.Id;
        addr.Type__c = 'Mailing';
        insert addr;
        
        Address__c homeAddr = new Address__c();
        homeAddr.Active__c = true;
        homeAddr.Student__c = a1.Id;
        homeAddr.Street_1__c = 'Test Address Line 2';
        homeAddr.City__c = 'Test City1';
        homeAddr.Zip_Postal_Code__c = 'ABC DEFG';
        homeAddr.Lookup_Country__c = cntry.Id;
        homeAddr.Type__c = 'Home';
        insert homeAddr;
        
        Programme__c prgrm = CreateTestData.createProgram();
        
        Product2 prd = CreateTestData.createProduct(prgrm,'OFFERING');
        
        Opportunity opp1 = new Opportunity();
        opp1.AccountId = a1.id;
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
        opp1.BNR_Curriculum_Status_Code__c = 'REGISTERED';
        opp1.Course_Instance__c=prd.Id;
        opp1.Programme_Application__c =prgrm .Id;
        insert opp1;
        
        Test.startTest();
        Case cse = new Case();
        cse.RecordTypeId=Schema.sObjectType.Case.getRecordTypeInfosByName().get('Student Query').getRecordTypeId();
        cse.Query_Type__c = 'Letter requests';
        cse.Query_Subtype__c = 'Status Letter';
        cse.Origin = 'Web';
        cse.Status = 'New';
        cse.ContactId = conId;
        cse.Study_Location__c = 'Doncaster';
        cse.School__c='Business';
        cse.SuppliedEmail = 'john@john.com';
        insert cse;

        PageReference PDf =  Page.StatusLetterPDF;
        PDf.getParameters().put('Id',cse.Id);
        PDf.getParameters().put('oppId',opp1.id);
        PDf.getParameters().put('addId',addr.Id);
        PDf.getParameters().put('homeAddId',homeAddr.Id);
        PDf.getParameters().put('subquery','Status Letter');
        Test.setCurrentPage(PDf);
        StatusLetterPDFCtrl ctrl = new StatusLetterPDFCtrl();
        //Test.stopTest();
        
        //Test.startTest();
        Case cse1 = new Case();
        cse1.RecordTypeId=Schema.sObjectType.Case.getRecordTypeInfosByName().get('Student Query').getRecordTypeId();
        cse1.Query_Type__c = 'Letter requests';
        cse1.Query_Subtype__c = 'Bank';
        cse1.Bank_Name__c = 'HSBC';
        cse1.Origin = 'Web';
        cse1.Status = 'New';
        cse1.ContactId = conId;
        cse1.Study_Location__c = 'Doncaster';
        cse1.School__c='Business';
        cse1.SuppliedEmail = 'john@john.com';
        insert cse1;

        PageReference PDf1 =  Page.StatusLetterPDF;
        PDf1.getParameters().put('Id',cse1.Id);
        PDf1.getParameters().put('oppId',opp1.id);
        PDf1.getParameters().put('addId',addr.Id);
        PDf1.getParameters().put('homeAddId',homeAddr.Id);
        PDf1.getParameters().put('subquery','Bank');
        Test.setCurrentPage(PDf1);
        StatusLetterPDFCtrl ctrl1 = new StatusLetterPDFCtrl();
        //Test.stopTest();
        
        //Test.startTest();
        Case cse2 = new Case();
        cse2.RecordTypeId=Schema.sObjectType.Case.getRecordTypeInfosByName().get('Student Query').getRecordTypeId();
        cse2.Query_Type__c = 'Letter requests';
        cse2.Query_Subtype__c = 'I would like a Council Tax letter';
        cse2.Origin = 'Web';
        cse2.Status = 'New';
        cse2.ContactId = conId;
        cse2.Study_Location__c = 'Doncaster';
        cse2.School__c='Business';
        cse2.SuppliedEmail = 'john@john.com';
        insert cse2;

        PageReference PDf2 =  Page.StatusLetterPDF;
        PDf2.getParameters().put('Id',cse2.Id);
        PDf2.getParameters().put('oppId',opp1.id);
        PDf2.getParameters().put('addId',addr.Id);
        PDf2.getParameters().put('homeAddId',homeAddr.Id);
        PDf2.getParameters().put('subquery','I would like a Council Tax letter');
        Test.setCurrentPage(PDf2);
        StatusLetterPDFCtrl ctrl2 = new StatusLetterPDFCtrl();
        Test.stopTest();
    }
}