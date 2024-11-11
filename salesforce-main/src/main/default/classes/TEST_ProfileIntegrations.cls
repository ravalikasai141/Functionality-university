@isTest()
public class TEST_ProfileIntegrations
{
    static testMethod void myUnitTestP1() {
        country_list__c cntry = CreateTestData.createCountry1();
        State_Province__c stt = CreateTestData.createStateProvince();
        Locality__c lct = CreateTestData.createLocality();
        
        Account a = CreateTestData.createAccount1(cntry);
        a.personHomePhone = '444-666-9999';
        a.Work_Phone__pc = '444-666-9999';
        a.Parents_Guardian_Emergency_Phone__pc = '444-666-9999';
        a.Fax = '444-666-9999';
        a.PersonMobilePhone ='111-333-4444';
        a.Personal_Email__pc = 'ptestmeda@test.com';
        a.Work_Email__pc = 'ptestmeda@test.com';
        a.BPP_Email__pc = 'ptestmeda@test.com';
        a.Other_Email__pc = 'ptestmeda@test.com';
        a.Billing_Email__pc = 'ptestmeda@test.com';
        a.AR_Student_Finance_England_SFE__c = 'BBBB22223333F';
        update a;
                
        Address__c addr = CreateTestData.createAddress(a, null, null, cntry, stt, lct, true, 'Billing');
        Opportunity o = CreateTestData.createOpportunity(a);
        Programme__c pgrm = CreateTestData.createProgram();
        Product2 pd = CreateTestData.createProduct(pgrm,'OFFERING');
        
        list<Contact> contacts = [Select Id, AccountId From Contact Where AccountId =: a.id];
        Qualification__c qual = new Qualification__c();
        qual.Student_Institute__c = 'testabcd';
        qual.Examing_Body__c = 'test123';
        qual.Student_Institute__c = 'test';
        qual.Student__c = contacts[0].id;
        insert qual;
        
        Test.startTest();
        Opportunity_Product__c oppPrd = CreateTestData.createOppProduct(o, pd, true);
        String Result = ProfileIntegrations.ProfileInt(a.id);
        Test.stopTest();
    }  
    
    static testMethod void myUnitTest1P2() {
        Account a2 = new Account();
        a2.PS_Profile_Services_ID__pc = '1324f567-bc23-42e8-924c-1324asdf5678';
        a2.firstname='John Smith';
        a2.lastname='Smith';
        a2.Salutation = 'Mr';
        a2.Middle_Name__pc = 'Mex';
        a2.Gender__pc = 'Female';
        a2.RecordTypeId=Schema.sObjectType.Account.getRecordTypeInfosByName().get('Student Account').getRecordTypeId();
        a2.Student_Cycle__c = 'Pursue';
        a2.Student_Type__pc ='International';
        a2.PersonBirthdate =Date.valueOf('1984-10-11');
        a2.AA_Suffix__pc = 'Jr';
        a2.Preferred_First_Name__pc = 'Smith';
        a2.Previous_First_Name__pc = 'John';
        a2.Previous_Surname__pc = 'Cop';
        a2.Previous_Middle_Name__pc = 'Copp';
        
        a2.personHomePhone = '444-666-9999';
        a2.Work_Phone__pc = '444-666-9999';
        a2.Parents_Guardian_Emergency_Phone__pc = '444-666-9999';
        a2.Fax = '444-666-9999';
        a2.PersonMobilePhone ='111-333-4444';
        a2.Preferred_Phone__pc = 'Mobile';
        a2.Personal_Email__pc = 'ptestmeda@test.com';
        a2.Work_Email__pc = 'ptestmeda@test.com';
        a2.BPP_Email__pc = 'ptestmeda@test.com';
        a2.Other_Email__pc = 'ptestmeda@test.com';
        a2.Billing_Email__pc = 'ptestmeda@test.com';
        a2.Preferred_Email__pc = 'Personal';
               
        insert a2;
        country_list__c cntry1 = new country_list__c(Name = 'Unit Test', ISO_Code__c = '123', country_code_2__c = '12', enabled__c = true, Valid_Nationality__c = true);
        insert cntry1;
        
        State_Province__c stt1 = new State_Province__c(Name = 'Unit Test', ISO_Code__c = '123');
        insert stt1;
        
        Address__c addacc = new Address__c();
        addacc.Student__c = a2.Id;
        addacc.Type__c = 'Next of Kin/Emergency/Guardian';
        addacc.Street_1__c = '329 S Tonne Dr';
        addacc.Street_2__c = '123';
        addacc.Street_3__c = '123';
        addacc.Street_4__c = '12';
        addacc.City__c = 'Chicago';
        addacc.State_Province__c = stt1.Id;
        addacc.Zip_Postal_Code__c = '12345';
        addacc.Lookup_Country__c = cntry1.Id;
        insert addacc;
        ProfileIntegrations.UpdatePersonInfo(a2.PS_Profile_Services_ID__pc, a2.id);
        
    StopRecursion.Dorun = true;   
         
        
        a2.personHomePhone = null;
        a2.Work_Phone__pc = null;
        a2.Parents_Guardian_Emergency_Phone__pc = null;
        a2.Fax = null;
        a2.PersonMobilePhone = null;
        a2.Personal_Email__pc = null;
        a2.Work_Email__pc = null;
        a2.BPP_Email__pc = null;
        a2.Other_Email__pc = null;
        a2.Billing_Email__pc = null;
        a2.Preferred_Email__pc = null;
        a2.Preferred_Phone__pc = null;
        
        update a2;      
    }  
   
    static testMethod void myUnitTest2P3() {
    
    country_list__c clist = new country_list__c(Name = 'Unit Test', ISO_Code__c = 'PM2', country_code_2__c = '00', enabled__c = true, Valid_Nationality__c = true);
        insert clist;
        Lead l1 = New Lead();
        l1.LastName = 'Test';
        l1.Birth_Date__c = Date.today().addYears(-20);
        l1.rfi_Are_you_EU_UK__c = 'UK (EU) Student';
        //l1.Country_of_Residence__c = 'USA';
        l1.Country_of_Residence__c = clist.id;
        l1.Preferred_Email__c = 'Personal';
        l1.Personal_Email__c = 'test@t.com';
        l1.FirstName = 'keith';
        l1.Work_Email__c = 'ptestmeda@test.com';
        l1.Other_Email__c = 'ptestmeda@test.com';
        l1.Billing_Email__c = 'ptestmeda@test.com';
        l1.MobilePhone = '444-666-9999';
        l1.Work_Phone__c = '444-666-9999';
        l1.Parents_Guardian_Emergency_Phone__c = '555-777-8888';
        l1.Home_Phone__c = '444-666-9999';
        l1.Fax = '444-666-9999';
        l1.Preferred_Phone__c = 'Work';
        l1.Gender__c = 'Male';
        l1.Middle_Name__c = 'mid';
        l1.Salutation = 'sal';
        l1.Preferred_First_Name__c ='pref';
        insert l1;
 
        country_list__c cntry = new country_list__c(Name = 'Unit Test', ISO_Code__c = '123', country_code_2__c = '12', enabled__c = true, Valid_Nationality__c = true);
        insert cntry;
           
        State_Province__c stt = new State_Province__c(Name = 'Unit Test', ISO_Code__c = '123');
        insert stt;
              
        Address__c add1 = new Address__c();
        add1.Lead__c = l1.Id;
        add1.Type__c = 'Next of Kin/Emergency/Guardian';
        add1.Street_1__c = '329 S Tonne Dr';
        add1.Street_2__c = '123';
        add1.Street_3__c = '123';
        add1.Street_4__c = '12';
        add1.City__c = 'Chicago';
        add1.State_Province__c = stt.Id;
        add1.Zip_Postal_Code__c = '12345';
        add1.Lookup_Country__c = cntry.Id;
        insert add1;
      
        Test.startTest();
        String Result = ProfileIntegrations.ProfileLeadInt(l1.id);
        Test.stopTest();
    }
}