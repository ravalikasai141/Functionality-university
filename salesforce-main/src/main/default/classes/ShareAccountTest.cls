@isTest
private class ShareAccountTest 
{
    static testMethod void shareAccTest() 
    {
        User u = [select id, name from User where userrole.name = 'Customer Service' and isActive = true limit 1];
        system.debug('User details'+u.Name);
        
        Account a1 = new Account();
        a1.firstname='John';
        a1.lastname='Coppedge';
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
        a1.Legal_Entity__c = 'UC~COL';
        a1.PS_Profile_Services_ID__pc = '1234f567-bc23-42e8-924c-1234asdf5678';
        a1.SFDC_Ethnic_Code_Select__pc = '10~ White';
        a1.SFDC_Disability_Status_Code_Select__pc = '0~ No Known DisabilityUndo';
        //a1.SFDC_Disability_Type_Code_Select__pc = '0~ No Known DisabilityUndo';
        a1.Country_of_Birth__pc = 'Unit Test';
        insert a1;
        
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
        insert opp1;
        
        Task taskvar = new Task();
        taskvar.RecordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Admissions Task').getRecordTypeId();
        taskvar.Ownerid=u.id;
        taskvar.Status = 'In Progress';
        taskvar.Priority = 'Normal';
        //taskvar.AccountId = a1.id;
        taskvar.WhatId = a1.id;
        insert taskvar;
        
        taskvar.Status = 'Completed';
        update taskvar;
    
    }
}