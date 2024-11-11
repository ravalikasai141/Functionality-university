@isTest
public class SISCompanyIntegrationsTest {
	@isTest
    private static void unitTest1() {
    	country_list__c cntry = CreateTestData.createCountry1();
        State_Province__c stt = new State_Province__c(Name = 'Unit Test', ISO_Code__c = '123');
        insert stt;
        Locality__c lct = new Locality__c(Name = 'Unit Test', Banner_Code__c = '123');
        insert lct;
        
        Account a1 = new Account();
	    a1.Name = 'Test Company';
	    a1.Phone = '4325768903';
	    a1.Account_Category__c = 'Customer - Middle Market';
	    a1.Sector_Level_1__c = 'Financial Services';
	    a1.Sector_Level_2__c = 'Accountancy';
	    a1.Acronym_short_title__c = 'Test'; 
	    a1.VAT_number__c = '1234567890';
	    a1.EU_Tax_registered__c = true;
	    a1.Customer_Type__c = 'Key Client';
	    a1.Legal_Entity__c = 'UC~COL';
	    a1.Industry_Type_SIC__c = 'B~ Mining and quarrying';
	    a1.Use_This_One__c = true;
	    a1.RecordTypeId=Schema.sObjectType.Account.getRecordTypeInfosByName().get('Business Development Account').getRecordTypeId();
	    a1.Profile_Company_ID__c = '1234f567-bc23-42e8-924c-asdf12345678';
	    a1.SIS_Company_ID__c = 'BP0015424';
	    a1.Sponsor_Contact__c = 'Term';
	    a1.Invoice_Method__c = 'Email';
	    a1.Invoice_Delivery__c = 'Email';
	    a1.Booking_Requirements__c = 'Passport';
	    a1.Correspondence_Detail__c = 'Email';
	    a1.Payment_Terms__c = '40 Days';
	    a1.Credit_Limit__c = 7500;
	    a1.Website = 'www.test.com';
	    a1.Discount__c = 25;
	    a1.Reporting_Required__c = true;
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
        
        Address__c add2 = new Address__c();
        StopRecursion.Dorun = true;
        add2.Student__c = a1.Id;
        add2.Type__c = 'Next of Kin/Emergency/Guardian';
        add2.Street_1__c = '329 S Tonne Dr';
        add2.Street_2__c = '123';
        add2.Street_3__c = '123';
        add2.Street_4__c = '12';
        add2.City__c = 'Chicago';
        add2.Locality__c = lct.Id;
        add2.State_Province__c = stt.Id;
        add2.Zip_Postal_Code__c = '12345';
        add2.Lookup_Country__c = cntry.Id;
        insert add2;
        
        CreateCompanyProfile.CompanyInformation(a1.Id);	
   		SISCompanyIntegrations.SISCompanyInt(a1.Id);	
   	} 
   	
   	@isTest
    private static void unitTest2() {
    	Account a1 = new Account();
	    a1.Name = 'Test Company';
	    a1.Phone = '4325768903';
	    a1.Account_Category__c = 'Customer - Middle Market';
	    a1.Sector_Level_1__c = 'Financial Services';
	    a1.Sector_Level_2__c = 'Accountancy';
	    a1.Acronym_short_title__c = 'Test'; 
	    a1.VAT_number__c = '1234567890';
	    a1.EU_Tax_registered__c = true;
	    a1.Customer_Type__c = 'Key Client';
	    a1.Legal_Entity__c = 'UC~COL';
	    a1.Industry_Type_SIC__c = 'B~ Mining and quarrying';
	    a1.Use_This_One__c = true;
	    a1.RecordTypeId=Schema.sObjectType.Account.getRecordTypeInfosByName().get('Business Development Account').getRecordTypeId();
	    a1.Profile_Company_ID__c = '1234f567-bc23-42e8-924c-asdf12345678';
	    a1.SIS_Company_ID__c = 'BP0015424';
	    a1.Sponsor_Contact__c = 'Term';
	    a1.Invoice_Method__c = 'Email';
	    a1.Invoice_Delivery__c = 'Email';
	    a1.Booking_Requirements__c = 'Passport';
	    a1.Correspondence_Detail__c = 'Email';
	    a1.Payment_Terms__c = '40 Days';
	    a1.Credit_Limit__c = 7500;
	    a1.Website = 'www.test.com';
	    a1.Discount__c = 25;
	    a1.Reporting_Required__c = true;
	    insert a1;
        
        SISCompanyIntegrations.bFailSIS = true;
        CreateCompanyProfile.bFailSIS = true; 
        SISCompanyIntegrations.SISCompanyInt(a1.Id);
        CreateCompanyProfile.CompanyInformation(a1.Id);	
   	}
   	
   	@isTest
    private static void unitTest3() {
    	country_list__c cntry = CreateTestData.createCountry1();
        State_Province__c stt = new State_Province__c(Name = 'Unit Test', ISO_Code__c = '123');
        insert stt;
        Locality__c lct = new Locality__c(Name = 'Unit Test', Banner_Code__c = '123');
        insert lct;
        
    	StopRecursion.Dorun = true;
    	Account a1 = new Account();
	    a1.Name = 'Test Company';
	    a1.Phone = '4325768903';
	    a1.Account_Category__c = 'Customer - Middle Market';
	    a1.Sector_Level_1__c = 'Financial Services';
	    a1.Sector_Level_2__c = 'Accountancy';
	    a1.Acronym_short_title__c = 'Test'; 
	    a1.VAT_number__c = '1234567890';
	    a1.EU_Tax_registered__c = true;
	    a1.Customer_Type__c = 'Key Client';
	    a1.Legal_Entity__c = 'UC~COL';
	    a1.Industry_Type_SIC__c = 'B~ Mining and quarrying';
	    a1.Use_This_One__c = true;
	    a1.RecordTypeId=Schema.sObjectType.Account.getRecordTypeInfosByName().get('Business Development Account').getRecordTypeId();
	    a1.Profile_Company_ID__c = '1234f567-bc23-42e8-924c-asdf12345678';
	    a1.SIS_Company_ID__c = 'BP0015424';
	    a1.Sponsor_Contact__c = 'Term';
	    a1.Invoice_Method__c = 'Email';
	    a1.Invoice_Delivery__c = 'Email';
	    a1.Booking_Requirements__c = 'Passport';
	    a1.Correspondence_Detail__c = 'Email';
	    a1.Payment_Terms__c = '40 Days';
	    a1.Credit_Limit__c = 7500;
	    a1.Website = 'www.test.com';
	    a1.Discount__c = 25;
	    a1.Reporting_Required__c = true;
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
        
        Address__c add2 = new Address__c();
        StopRecursion.Dorun = true;
        add2.Student__c = a1.Id;
        add2.Type__c = 'Next of Kin/Emergency/Guardian';
        add2.Street_1__c = '329 S Tonne Dr';
        add2.Street_2__c = '123';
        add2.Street_3__c = '123';
        add2.Street_4__c = '12';
        add2.City__c = 'Chicago';
        add2.Locality__c = lct.Id;
        add2.State_Province__c = stt.Id;
        add2.Zip_Postal_Code__c = '12345';
        add2.Lookup_Country__c = cntry.Id;
        insert add2;
        
        a1.Payment_Terms__c = '45 Days';
        update a1;
        StopRecursion.Dorun = true;
        add2.Street_2__c = '1234';
        update add2;
        
        CreateCompanyProfile.bFailSIS = true;
        StopRecursion.Dorun = true;
        delete add2;
    } 
    
    @isTest
    private static void unitTest4() {
    	country_list__c cntry = CreateTestData.createCountry1();
        State_Province__c stt = new State_Province__c(Name = 'Unit Test', ISO_Code__c = '123');
        insert stt;
        Locality__c lct = new Locality__c(Name = 'Unit Test', Banner_Code__c = '123');
        insert lct;
        
    	StopRecursion.Dorun = true;
    	Account a1 = new Account();
	    a1.Name = 'Test Company';
	    a1.Phone = '4325768903';
	    a1.Account_Category__c = 'Customer - Middle Market';
	    a1.Sector_Level_1__c = 'Financial Services';
	    a1.Sector_Level_2__c = 'Accountancy';
	    a1.Acronym_short_title__c = 'Test'; 
	    a1.VAT_number__c = '1234567890';
	    a1.EU_Tax_registered__c = true;
	    a1.Customer_Type__c = 'Key Client';
	    a1.Legal_Entity__c = 'UC~COL';
	    a1.Industry_Type_SIC__c = 'B~ Mining and quarrying';
	    a1.Use_This_One__c = true;
	    a1.RecordTypeId=Schema.sObjectType.Account.getRecordTypeInfosByName().get('Business Development Account').getRecordTypeId();
	    a1.Profile_Company_ID__c = '1234f567-bc23-42e8-924c-asdf12345678';
	    a1.SIS_Company_ID__c = 'BP0015424';
	    a1.Sponsor_Contact__c = 'Term';
	    a1.Invoice_Method__c = 'Email';
	    a1.Invoice_Delivery__c = 'Email';
	    a1.Booking_Requirements__c = 'Passport';
	    a1.Correspondence_Detail__c = 'Email';
	    a1.Payment_Terms__c = '40 Days';
	    a1.Credit_Limit__c = 7500;
	    a1.Website = 'www.test.com';
	    a1.Discount__c = 25;
	    a1.Reporting_Required__c = true;
	    insert a1;
        
        CreateCompanyProfile.bFailSIS = false;
        StopRecursion.Dorun = true;
        a1.Payment_Terms__c = '45 Days';
        update a1;
    } 
}