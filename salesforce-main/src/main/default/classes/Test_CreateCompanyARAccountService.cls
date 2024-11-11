/**
 * This class contains unit tests for validating the behavior of Apex classe 
 * CreateCompanyARAccountService 
 */
@isTest
private class Test_CreateCompanyARAccountService {

    static testMethod void myUnitTest() {
        country_list__c cntry = CreateTestData.createCountry1();
        State_Province__c stt = new State_Province__c(Name = 'Unit Test', ISO_Code__c = '123');
        insert stt;
        Locality__c lct = new Locality__c(Name = 'Unit Test', Banner_Code__c = '123');
        insert lct;
        
        Account a = new Account();
        a.Name='Inftes';
        a.RecordTypeId=Schema.sObjectType.Account.getRecordTypeInfosByName().get('Business Development Account').getRecordTypeId();
        a.Phone='8015555556';
        a.Profile_Company_ID__c = '1234f567-bc23-42e8-924c-1234asdf5678';
        a.Customer_Type__c = 'Key Client';       
        a.Account_Category__c = 'Customer - FTSE 350 or Equal';
        a.Sector_Level_1__c = 'Financial Services';
        a.Sector_Level_2__c = 'Broker';
        insert a;
        
        Address__c add1 = new Address__c();
        //StopRecursion.Dorun = true;
        add1.Student__c = a.Id; 
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
        
        
        string validSIS = CreateCompanyARAccountService.validationRulesForSIS(a.Id);        
        string validAR = CreateCompanyARAccountService.validationRulesForAR(a.Id);
        a.SIS_Company_ID__c = 'Bp343d32';
        a.Legal_Entity__c = 'UC';
        update a;
        CreateCompanyARAccountService.testFail = false;
        CreateCompanyARAccountService.companyARAccInt(a.Id);
        CreateCompanyARAccountService.testFail = true;
        CreateCompanyARAccountService.companyARAccInt(a.Id);
        
        validAR = CreateCompanyARAccountService.validationRulesForAR(a.Id);
        validSIS = CreateCompanyARAccountService.validationRulesForSIS(a.Id);
    }
    
    static testMethod void myUnitTest2() {
        country_list__c cntry = CreateTestData.createCountry1();
        State_Province__c stt = new State_Province__c(Name = 'Unit Test', ISO_Code__c = '123');
        insert stt;
        Locality__c lct = new Locality__c(Name = 'Unit Test', Banner_Code__c = '123');
        insert lct;
        
        Account a = new Account();
        a.Name='Inftes';
        a.RecordTypeId=Schema.sObjectType.Account.getRecordTypeInfosByName().get('Business Development Account').getRecordTypeId();
        a.Phone='8015555556';
        a.Profile_Company_ID__c = '1234f567-bc23-42e8-924c-1234asdf5678';
        a.Customer_Type__c = 'Key Client';       
        a.Account_Category__c = 'Customer - FTSE 350 or Equal';
        a.Sector_Level_1__c = 'Financial Services';
        a.Sector_Level_2__c = 'Broker';
        insert a;
        
        Address__c add1 = new Address__c();
        //StopRecursion.Dorun = true;
        add1.Student__c = a.Id; 
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
        
        
        string validSIS = CreateCompanyARAccountService.validationRulesForSIS(a.Id);        
        string validAR = CreateCompanyARAccountService.validationRulesForAR(a.Id);
        a.Legal_Entity__c = 'UC';
        a.Acronym_short_title__c = 'test';
        update a;
        CreateCompanyARAccountService.testFail = false;
        CreateARSISServiceController.ARSISService(a.Id);
    }
    
    static testMethod void myUnitTest3() {
        country_list__c cntry = CreateTestData.createCountry1();
        State_Province__c stt = new State_Province__c(Name = 'Unit Test', ISO_Code__c = '123');
        insert stt;
        Locality__c lct = new Locality__c(Name = 'Unit Test', Banner_Code__c = '123');
        insert lct;
        
        Account a = new Account();
        a.Name='Inftes';
        a.RecordTypeId=Schema.sObjectType.Account.getRecordTypeInfosByName().get('Business Development Account').getRecordTypeId();
        a.Phone='8015555556';
        a.Customer_Type__c = 'Key Client';       
        a.Account_Category__c = 'Customer - FTSE 350 or Equal';
        a.Sector_Level_1__c = 'Financial Services';
        a.Sector_Level_2__c = 'Broker';
        insert a;
        
        Address__c add1 = new Address__c();
        //StopRecursion.Dorun = true;
        add1.Student__c = a.Id; 
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
        
        
        string validSIS = CreateCompanyARAccountService.validationRulesForSIS(a.Id);        
        string validAR = CreateCompanyARAccountService.validationRulesForAR(a.Id);
        a.SIS_Company_ID__c = 'Bp343d32';
        a.Legal_Entity__c = 'UC';
        update a;
        CreateCompanyARAccountService.testFail = false;
        CreateARSISServiceController.ARSISService(a.Id);
    }
    
    static testMethod void myUnitTest4() {
        country_list__c cntry = CreateTestData.createCountry1();
        State_Province__c stt = new State_Province__c(Name = 'Unit Test', ISO_Code__c = '123');
        insert stt;
        Locality__c lct = new Locality__c(Name = 'Unit Test', Banner_Code__c = '123');
        insert lct;
        
        Account a = new Account();
        a.Name='Inftes';
        a.RecordTypeId=Schema.sObjectType.Account.getRecordTypeInfosByName().get('Business Development Account').getRecordTypeId();
        a.Profile_Company_ID__c = '1234f567-bc23-42e8-924c-1234asdf5678';
        a.Phone='8015555556';
        a.Customer_Type__c = 'Key Client';       
        a.Account_Category__c = 'Customer - FTSE 350 or Equal';
        a.Sector_Level_1__c = 'Financial Services';
        a.Sector_Level_2__c = 'Broker';
        insert a;
        
        Address__c add1 = new Address__c();
        //StopRecursion.Dorun = true;
        add1.Student__c = a.Id; 
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
        
        
        string validSIS = CreateCompanyARAccountService.validationRulesForSIS(a.Id);        
        string validAR = CreateCompanyARAccountService.validationRulesForAR(a.Id);
        a.SIS_Company_ID__c = 'Bp343d32';
        a.Legal_Entity__c = 'UC';
        a.AR_Global_Customer_Number__c = '73910481';
        update a;
        CreateCompanyARAccountService.testFail = false;
        CreateCompanyARAccountService.companyARAccInt(a.Id);
        CreateCompanyARAccountService.testFail = true;
        CreateCompanyARAccountService.companyARAccInt(a.Id);
        
        CreateARSISServiceController.ARSISService(a.Id);
    }
}