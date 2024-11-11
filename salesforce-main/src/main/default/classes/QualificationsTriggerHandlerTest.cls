@isTest
public class QualificationsTriggerHandlerTest {
	public static testmethod void showHighestQualificationCode(){
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
        opp1.Cycle_Override__c = 'Use Student Cycle';
        opp1.CloseDate = Date.valueOf('2015-02-27'); 
        opp1.BNR_Application_Decision_Comment__c = 'ABCD';
        opp1.SFDC_Attribute_Code_Select__c = 'FT~ Full Time Student';
        opp1.SFDC_Admissions_ADMT_Code_Select__c = 'DI~ Direct';
        opp1.SFDC_Admissions_STYPE_Code_Select__c = 'R~ Returning';
        opp1.SFDC_Admissions_RESD_Code_Select__c = 'E~ EU National';
        opp1.SFDC_Cohort_Code_Select__c = 'C6~ Cohort June';
        opp1.stageName = 'Closed Won';
        opp1.Enrolment_Status__c = 'N/A';
        insert opp1;
        
        Id conId = [select Id, name, PersonContactId from Account where Id =:a1.Id].PersonContactId;
        system.debug('@@conId@@'+conId);
        
        Qualification_Subject__c qualsub = new Qualification_Subject__c();
        qualsub.Name = 'Test Qualification subject';
        qualsub.Subject_Code__c = 'PMO';
        insert qualsub;
        
        Highest_Qualification__c highqual = new Highest_Qualification__c();
        highqual.Name = 'Test Highest Qualification';
        highqual.Code__c = 'PMO01';
        highqual.Rank__c = 9;
        insert highqual;
        
        Highest_Qualification__c highqual2 = new Highest_Qualification__c();
        highqual2.Name = 'Test Highest Qualification';
        highqual2.Code__c = 'PMO02';
        highqual2.Rank__c = 2;
        insert highqual2;
        
        Qualification_Type__c qualtype = new Qualification_Type__c();
        qualtype.Name = 'Test Qualification Type';
        qualtype.Highest_Qualification__c = highqual.Id;
        qualtype.Type_Code__c = 'PMO';
        insert qualtype;
        
        Qualification_Institution__c qualinst = new Qualification_Institution__c();
        qualinst.Name = 'Test Qualification Institution';
        qualinst.Institution_Code__c = 'PMO';
        Insert qualinst;
        
        Qualification_Type__c qualtype2 = new Qualification_Type__c();
        qualtype2.Name = 'Test Qualification Type2';
        qualtype2.Highest_Qualification__c = highqual2.Id;
        qualtype2.Type_Code__c = 'PMT';
        insert qualtype2;
        
        Qualification_Institution__c qualinst2 = new Qualification_Institution__c();
        qualinst2.Name = 'Test Qualification Institution2';
        qualinst2.Institution_Code__c = 'PMT';
        Insert qualinst2;
        
        Qualification__c qual = new Qualification__c();
        qual.Student__c = conId;
        qual.Qualification_Subject__c = qualsub.Id;
        qual.Qualification_Type__c = qualtype.Id;
        qual.Status__c = 'Actual';
        qual.Qualification_Institution__c = qualinst.Id;
        qual.Qualification_Date__c =date.ValueOf('1968-09-21');
        insert qual;
        
        qual.Qualification_Type__c = qualtype2.Id;
        qual.Qualification_Institution__c = qualinst2.Id;
        update qual; 
    }

    @isTest
    public static void itShouldSyncSubject() {
        // GIVEN a Qualification with Subject
        Qualification_Type__c qualtype = new Qualification_Type__c();
        qualtype.Name = 'Test Qualification Type';
        qualtype.Type_Code__c = 'PMO';
        insert qualtype;

        Qualification_Subject__c qualsub = new Qualification_Subject__c();
        qualsub.Name = 'Test Qualification subject';
        qualsub.Subject_Code__c = 'PMO';
        insert qualsub;

        Id accountRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
            .get('Student_Account')
            .getRecordTypeId();

        Account acc = new Account(FirstName = 'Test', LastName = 'Test', RecordTypeId = accountRecordTypeId);
        insert acc;
        Id conId = [SELECT Id, name, PersonContactId FROM Account WHERE Id = :acc.Id].PersonContactId;

        Qualification__c qual = new Qualification__c(
            Qualification_Subject__c = qualsub.Id,
            Qualification_Type__c = qualtype.Id,
            Student__c = conId
        );

        // WHEN qualification is inserted
        insert qual;

        // THEN the subject name field is updated
        Qualification__c updatedQual = [SELECT id, Subject_Name__c FROM Qualification__c WHERE id = :qual.Id];

        Assert.areEqual(qualsub.Name, updatedQual.Subject_Name__c);
    }
}
