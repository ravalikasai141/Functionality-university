@isTest
public class updateVLEflagonAccountTest{
    /*static testmethod void HUBstudentTest(){
    
        country_list__c cntry = CreateTestData.createCountry1();
        State_Province__c stt = new State_Province__c(Name = 'Unit Test', ISO_Code__c = '123');
        insert stt;
        Locality__c lct = new Locality__c(Name = 'Unit Test', Banner_Code__c = '123');
        insert lct;
        
        Programme__c pgrm = new Programme__c();
        pgrm.Name = 'MSc Management';
        pgrm.BNR_FieldOfStudy_Code__c = 'ELEC';
        pgrm.Microsite_Enabled__c = true;
        pgrm.Programme_Status__c = 'Validated';
        pgrm.School__c = 'Test School';
        insert pgrm;
        
        Product2 pd = new Product2();
        pd.IsActive = true;
        pd.Name = 'Test Course Instance';
        pd.Programme__c = pgrm.Id;
        pd.Mode__c = 'Full Time';
        pd.Location__c = 'London - London City';
        pd.Start_Date__c = date.valueof('2021-06-11');
        pd.BNR_Admissions_Enabled__c = true;
        pd.BNR_Term_Code__c = '212121';
        pd.BNR_Attribute_Code__c = 'FT';
        pd.BNR_Level_Code__c = 'UG';
        pd.BNR_Campus_Code__c = 'LLC';
        pd.BNR_Degree_Code__c = 'MS';
        pd.BNR_Program_Code__c = 'ELEC';
        pd.Instance_Id__c = '123456789012345';
        insert pd;
        
        Account a1 = new Account();
        a1.firstname='John';
        a1.lastname='CoppedgeHUB';
        a1.Salutation = 'Mr';
        a1.Middle_Name__pc = 'Mex';
        a1.Gender__pc = 'Male';
        a1.RecordTypeId=Schema.sObjectType.Account.getRecordTypeInfosByName().get('Student Account').getRecordTypeId();
        a1.Student_Cycle__c = 'Pursue';
        a1.Student_Type__pc ='Domestic';
        a1.Preferred_Email__pc = 'Personal';
        a1.PersonEmail = 'john@john.com';
        a1.Personal_Email__pc ='john@john.com';
        a1.Work_Email__pc = 'john1@john.com';
        a1.BPP_Email__pc = 'john2@john.com';
        a1.Other_Email__pc = 'john3@john.com';
        a1.Billing_Email__pc = 'john4@john.com';
        a1.Preferred_Phone__pc = 'Mobile';
        a1.Phone = '8015555556';
        a1.PersonMobilePhone='8015555556';
        a1.PersonBirthdate =Date.valueOf('1986-12-07');
        a1.AA_Suffix__pc = 'Jr';
        a1.Preferred_First_Name__pc = 'Coppege';
        a1.Previous_First_Name__pc = 'John';
        a1.Previous_Surname__pc = 'Cop';
        a1.Previous_Middle_Name__pc = 'Copp';
        a1.Primary_Nationality__pc = cntry.Id;
        a1.Country_of_Birth__pc = cntry.Id;
        a1.Legal_Entity__c = 'UC~COL';
        a1.PS_Profile_Services_ID__pc = '1234f567-bc23-42e8-924c-1234asdf5678';
        a1.SFDC_Ethnic_Code_Select__pc = '10~ White';
        a1.SFDC_Disability_Status_Code_Select__pc = '0~ No Known DisabilityUndo';
        //a1.SFDC_Disability_Type_Code_Select__pc = '0~ No Known DisabilityUndo';
        a1.Country_of_Birth__pc = 'Unit Test';
        a1.SFDC_Country_of_Birth__pc = cntry.Id;
        insert a1;
        
        Address__c add1 = new Address__c();
        StopRecursion.Dorun = true;
        add1.Student__c = a1.Id;
        add1.Type__c = 'Home';
        add1.Street_1__c = '329 S Tonne Dr';
        add1.Street_2__c = '123';
        add1.Street_3__c = '123';
        add1.Street_4__c = '12';
        add1.City__c = 'Chicago';
        add1.Locality__c = lct.Id;
        add1.State_Province__c = stt.Id;
        add1.Zip_Postal_Code__c = '12345';
        add1.Lookup_Country__c = cntry.Id;
        insert add1;
        
        Opportunity opp1 = new Opportunity();
        opp1.AccountId = a1.id;
        opp1.Name = 'testHUB';
        opp1.StageName = 'Accepted - Conditional Firm';
        opp1.Enrolment_Status__c = 'Acceptance';
        opp1.Cycle_Override__c = 'Use Student Cycle';
        opp1.CloseDate = Date.valueOf('2015-02-27'); 
        opp1.Course_Instance__c = pd.Id; 
        opp1.Programme_Application__c = pgrm.Id;
        opp1.Start_Date__c = date.valueof('2021-06-11');
        opp1.BNR_Application_Decision_Comment__c = 'ABCD';
        opp1.SFDC_Attribute_Code_Select__c = 'FT~ Full Time Student';
        opp1.SFDC_Admissions_ADMT_Code_Select__c = 'DI~ Direct';
        opp1.SFDC_Admissions_STYPE_Code_Select__c = 'R~ Returning';
        opp1.SFDC_Admissions_RESD_Code_Select__c = 'E~ EU National';
        opp1.SFDC_Cohort_Code_Select__c = 'C6~ Cohort June';
        opp1.BNR_Level_Code_Text__c = 'AB';
        opp1.BNR_Degree_Code_Text__c = 'ABCD';
                
        insert opp1;
        //Opportunity op = [Select id, Programme_Application__r.Name, Start_Date__c from Opportunity where Id =:opp1.Id limit 1];
        //system.debug('@@op.Programme_Application__r.Name@@'+op.Programme_Application__r.Name);
        //update op;
   
    }*/
}