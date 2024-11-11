@isTest(SeeAllData=true)
private class Test_UpdateSISPerson {

  /*static testMethod void myUnitTest1(){

      Account a = new Account();
        a.firstname='John';
        a.lastname='Coppedge';
        a.RecordTypeId=Schema.sObjectType.Account.getRecordTypeInfosByName().get('Student Account').getRecordTypeId();
        a.Preferred_Email__pc = 'Personal';
        a.Preferred_Phone__pc = 'Mobile';
        a.Personal_Email__pc ='john@john.com';
        a.PersonMobilePhone='8015555556';
        a.PersonBirthdate=Date.valueOf('1986-02-27');
        a.PS_Profile_Services_ID__pc = '1234f567-bc23-42e8-924c-000012345678';
        a.Student_Cycle__c = 'Pursue';
        a.Student_Type__pc = 'Domestic';
        a.Sexual_Orientation__pc = '04~ Heterosexual';
        a.Gender_Identity__pc = '01~ Yes';
        a.Religion__pc = '03~ Christian';
        a.Parent_Guardian_Occupation__pc = '1134~ Advertising & public relations managers';
        a.Student_Occupation__pc = '3413~ Actors, entertainers';
              
        insert a;
          
        test.startTest();
        string result = UpdateSISPerson.PersonInformation(a.Id);
        test.stopTest();
  }*/
  
    static testMethod void myUnitTest2(){

      Account a1 = new Account();
        a1.firstname='John';
        a1.lastname='Coppedge';
        a1.RecordTypeId=Schema.sObjectType.Account.getRecordTypeInfosByName().get('Student Account').getRecordTypeId();
        a1.Preferred_Email__pc = 'Personal';
        a1.Preferred_Phone__pc = 'Mobile';
        a1.Personal_Email__pc ='john@john.com';
        a1.PersonMobilePhone='8015555556';
        a1.PersonBirthdate=Date.valueOf('1998-02-27');
        a1.PS_Profile_Services_ID__pc = '1234f567-bc23-42e8-924c-000012345678';
        a1.Student_Cycle__c = 'Pursue';
        a1.Student_Type__pc = 'Domestic';
        a1.Sexual_Orientation__pc = '04~ Heterosexual';
        a1.Gender_Identity__pc = '01~ Yes';
        a1.Religion__pc = '03~ Christian';
        a1.Parent_Guardian_Occupation__pc = '1134~ Advertising & public relations managers';
        a1.Student_Occupation__pc = '3413~ Actors, entertainers';
              
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
        opp1.BNR_Level_Code_Text__c = 'AB';
        opp1.BNR_Degree_Code_Text__c = 'ABCD';
        opp1.PC_Attribute_Code__c = 'FT';
        opp1.PC_Attribute_Code_2__c = 'ACCE';
        opp1.PC_Attribute_Code_3__c = 'PT';
        opp1.SFDC_Attribute_Code_Select_v2__c = 'FT~ Full Time Student';
        opp1.BNR_Term_Code_Text__c = 'test123';
        
        insert opp1;
          
        list<Contact> contacts = [Select Id, AccountId From Contact Where AccountId =: a1.Id];
                        
        Qualification__c qual1 = new Qualification__c();
        qual1.Subject__c = 'Test';
        qual1.Institution__c = 'Test';
        qual1.Grade__c = 'Test';
        qual1.HESA_Grade__c  ='test';
        qual1.NARIC_Equivalent_Grade__c = '1~ Entry level';
        qual1.NARIC_Grade_Date__c = Date.valueOf('1998-02-27'); 
        qual1.NARIC_Indicator__c = true;
        qual1.Admissions_Request__c = true;    
        qual1.Status__c = 'Test';
        qual1.Mode__c = 'Test';
        qual1.Type__c = 'Test';
        qual1.Student_Institute__c = 'Test';
        qual1.Examing_Body__c = 'Test';
        qual1.Tariff_Points__c = 1234;
        qual1.Description__c = 'Test';
        qual1.Record_Source__c = 'Test';    
        qual1.Penultimate_Year_Grade__c = 'Test';
        qual1.Penultimate_Year_Grade__c = 'Test';
        qual1.Start_Date__c = Date.valueOf('1998-02-27');
        qual1.Qualification_Date__c = Date.valueOf('1998-02-27');
        qual1.Student__c = contacts[0].Id;
        insert qual1;                
        
        test.startTest();
        string result = UpdateSISPerson.PersonInformation(a1.Id,opp1.Id);
        test.stopTest();
  }
}