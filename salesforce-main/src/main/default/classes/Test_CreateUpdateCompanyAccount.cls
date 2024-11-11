@isTest()
public with sharing class Test_CreateUpdateCompanyAccount {
	static final String JSON = '{"coDTO":{"company": {"attributes": {"type": "Account"},"Name": "This is a New Business Account","Profile_Company_ID__c": "2f1f4767-e5b6-556a-8277-03fde57a268b","SIS_Company_ID__c": "2f1f4767-e5b6-556a-8277-03fde57a268b","VAT_number__c": "1234","Acronym_short_title__c": "Test","Customer_Type__c": "","Sector_Level_1__c": "Law","Sector_Level_2__c": "Law Firm","Payment_Terms__c": "30 days","Credit_Limit__c": "","Phone": "Phone"},"addresses": [{"attributes": {"type": "Address__c"},"Primary__c": "","City__c": "PHOENIX","Zip_Postal_Code__c": "1714452","Text_Country__c": "USA","Text_State__c": "US-MS","Text_Locality__c": "","Type__c": "Mailing","Street_1__c": "ChangedAgn","Street_2__c": "Prt323r","Street_3__c": "Prnt333r","Street_4__c": "Homme3me3enex2 4ur STREET"},{"attributes": {"type": "Address__c"},"City__c": "PHOENIX","Primary__c": "","Zip_Postal_Code__c": "1714462","Text_Country__c": "USA","Text_State__c": "US-MS","Text_Locality__c": "","Type__c": "Billing","Street_1__c": "123","Street_2__c": "1233 ","Street_3__c": "111222","Street_4__c": "123 2 STREET"}]}}';

	/*********************************************************
	* Test the REST interface. This will also test the Record
	* Type portions of Create Update Company Account.
	* TEST UPDATE.
	*
	* JSON : String defined above as the case JSON passed in.
	*********************************************************/
	public static testMethod void testUpdateCompanyAccount ()
	{
		//Create a mock Company DTO
		CreateUpdateCompanyAccount.CompanyDTO coDTO = new CreateUpdateCompanyAccount.CompanyDTO();
		
	
		// Create Company Account to test update
	    Account a = new Account();
        a.Name = 'Rockin Test Company';
        a.Acronym_short_title__c = 'Test'; 
        a.VAT_number__c = '1234567890';
        a.EU_Tax_registered__c = true;
        a.Customer_Type__c = 'Key Client';
        a.Industry_Type_SIC__c = 'B~ Mining and quarrying';
        a.Use_This_One__c = true;
        a.RecordTypeId=Schema.sObjectType.Account.getRecordTypeInfosByName().get('Business Development Account').getRecordTypeId();
        a.Profile_Company_ID__c = '2f1f4767-e5b6-556a-9999-03fde57a268b';
        a.SIS_Company_ID__c = 'BP0015424';
        a.Sponsor_Contact__c = 'Term';
        a.Invoice_Method__c = 'Email';
        a.Invoice_Delivery__c = 'Email';
        a.Booking_Requirements__c = 'Passport';
        a.Correspondence_Detail__c = 'Email';
        a.Payment_Terms__c = '40 Days';
        a.Credit_Limit__c = 7500;
        a.Website = 'www.test.com';
        a.Discount__c = 25;
        a.Reporting_Required__c = true;
        insert a;	
		
		// Create Business Account to insert
		Account tempAccount = new Account();
		
        tempAccount.Name = 'Rockin Test Company';
        tempAccount.Acronym_short_title__c = 'Test'; 
        tempAccount.VAT_number__c = '1234567890';
        tempAccount.EU_Tax_registered__c = true;
        tempAccount.Customer_Type__c = 'Key Client';
        tempAccount.Industry_Type_SIC__c = 'B~ Mining and quarrying';
        tempAccount.Use_This_One__c = true;
        tempAccount.RecordTypeId=Schema.sObjectType.Account.getRecordTypeInfosByName().get('Business Development Account').getRecordTypeId();
        tempAccount.Profile_Company_ID__c = '2f1f4767-e5b6-556a-0789-03fde57a268b';
        tempAccount.SIS_Company_ID__c = 'BP0015424';
        tempAccount.Sponsor_Contact__c = 'Term';
        tempAccount.Invoice_Method__c = 'Email';
        tempAccount.Invoice_Delivery__c = 'Email';
        tempAccount.Booking_Requirements__c = 'Passport';
        tempAccount.Correspondence_Detail__c = 'Email';
        tempAccount.Payment_Terms__c = '40 Days';
        tempAccount.Credit_Limit__c = 7500;
        tempAccount.Website = 'www.test.com';
        tempAccount.Discount__c = 25;
        tempAccount.Reporting_Required__c = true;
        tempaccount.Sector_Level_1__c = 'Law';
        tempaccount.Sector_Level_2__c = 'Law Firm';
        tempaccount.Payment_Terms__c = '30 days';        
		coDTO.company = tempAccount;

		//Create list of addresses
        List<Address__c> adds = new List<Address__c>();
		Address__c add1 = new Address__c();
		add1.Type__c = 'Billing';
		add1.Street_1__c = '123 S Test Dr';
		add1.Street_2__c = '12345';
		add1.Street_3__c = '1234';
		add1.Street_4__c = '123';
		add1.City__c = 'Test City';
		add1.Text_Locality__c = '12345';
		add1.Text_State__c = '1234';
		add1.Zip_Postal_Code__c = '12345';
		add1.Text_Country__c = '123';
		adds.add(add1);
		coDTO.addresses = adds;


		//Create REST request and response values and objects.
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        
        req.requestURI = '/services/apexrest/v1.0/CreateUpdateCompanyAccount';
        req.addHeader('httpMethod', 'POST');
        //req.requestBody = Blob.valueof(JSON);
	    RestContext.request = req;
	    RestContext.response = res;


		// Test the Post method on the REST CreateCase Service
        CreateUpdateCompanyAccount.Response res1 = CreateUpdateCompanyAccount.doPost(coDTO); 
		system.debug(res1);
        
	}
	
	/*********************************************************
	* Test the REST interface. This will also test the Record
	* Type portions of Create Update Company Account.
	* TEST CREATE.
	*
	* JSON : String defined above as the case JSON passed in.
	*********************************************************/
	public static testMethod void testCreateCompanyAccount ()
	{
		//Create a mock Company DTO
		CreateUpdateCompanyAccount.CompanyDTO coDTO = new CreateUpdateCompanyAccount.CompanyDTO();
		
	
		// Create Company Account to test update
	    Account a = new Account();
        a.Name = 'Rockin Test Company';
        a.Acronym_short_title__c = 'Test'; 
        a.VAT_number__c = '1234567890';
        a.EU_Tax_registered__c = true;
        a.Customer_Type__c = 'Key Client';
        a.Industry_Type_SIC__c = 'B~ Mining and quarrying';
        a.Use_This_One__c = true;
        a.RecordTypeId=Schema.sObjectType.Account.getRecordTypeInfosByName().get('Business Development Account').getRecordTypeId();
        a.Profile_Company_ID__c = '2f1f4767-e5b6-556a-0909-03fde57a268b';
        a.SIS_Company_ID__c = 'BP0015424';
        a.Sponsor_Contact__c = 'Term';
        a.Invoice_Method__c = 'Email';
        a.Invoice_Delivery__c = 'Email';
        a.Booking_Requirements__c = 'Passport';
        a.Correspondence_Detail__c = 'Email';
        a.Payment_Terms__c = '40 Days';
        a.Credit_Limit__c = 7500;
        a.Website = 'www.test.com';
        a.Discount__c = 25;
        a.Reporting_Required__c = true;
        insert a;	
		
		// Create Business Account to insert
		Account tempAccount = new Account();
		
        tempAccount.Name = 'Rockin Test Company';
        tempAccount.Acronym_short_title__c = 'Test'; 
        tempAccount.VAT_number__c = '1234567890';
        tempAccount.EU_Tax_registered__c = true;
        tempAccount.Customer_Type__c = 'Key Client';
        tempAccount.Industry_Type_SIC__c = 'B~ Mining and quarrying';
        tempAccount.Use_This_One__c = true;
        tempAccount.RecordTypeId=Schema.sObjectType.Account.getRecordTypeInfosByName().get('Business Development Account').getRecordTypeId();
        tempAccount.Profile_Company_ID__c = '2f1f4767-e5b6-556a-0000-03fde57a268b';
        tempAccount.SIS_Company_ID__c = 'BP0015424';
        tempAccount.Sponsor_Contact__c = 'Term';
        tempAccount.Invoice_Method__c = 'Email';
        tempAccount.Invoice_Delivery__c = 'Email';
        tempAccount.Booking_Requirements__c = 'Passport';
        tempAccount.Correspondence_Detail__c = 'Email';
        tempAccount.Payment_Terms__c = '40 Days';
        tempAccount.Credit_Limit__c = 7500;
        tempAccount.Website = 'www.test.com';
        tempAccount.Discount__c = 25;
        tempAccount.Reporting_Required__c = true;
        tempaccount.Sector_Level_1__c = 'Law';
        tempaccount.Sector_Level_2__c = 'Law Firm';
        tempaccount.Payment_Terms__c = '30 days';        
		coDTO.company = tempAccount;

		//Create list of addresses
        List<Address__c> adds = new List<Address__c>();
		Address__c add1 = new Address__c();
		add1.Type__c = 'Billing';
		add1.Street_1__c = '123 S Test Dr';
		add1.Street_2__c = '12345';
		add1.Street_3__c = '1234';
		add1.Street_4__c = '123';
		add1.City__c = 'Test City';
		add1.Text_Locality__c = '12345';
		add1.Text_State__c = '1234';
		add1.Zip_Postal_Code__c = '12345';
		add1.Text_Country__c = '123';
		adds.add(add1);
		coDTO.addresses = adds;


		//Create REST request and response values and objects.
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        
        req.requestURI = '/services/apexrest/v1.0/CreateUpdateCompanyAccount';
        req.addHeader('httpMethod', 'POST');
        //req.requestBody = Blob.valueof(JSON);
	    RestContext.request = req;
	    RestContext.response = res;


		// Test the Post method on the REST CreateCase Service
        CreateUpdateCompanyAccount.Response res1 = CreateUpdateCompanyAccount.doPost(coDTO); 
		system.debug(res1);
        
	}
	
	/*********************************************************
	* Test the REST interface. This will also test the Record
	* Type portions of Create Update Company Account.
	* TEST EMPTY COMPANY.
	*
	* JSON : String defined above as the case JSON passed in.
	*********************************************************/
	public static testMethod void testCreateBlankCompanyAccount ()
	{
		//Create a mock Company DTO
		CreateUpdateCompanyAccount.CompanyDTO coDTO = new CreateUpdateCompanyAccount.CompanyDTO();


		//Create REST request and response values and objects.
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        
        req.requestURI = '/services/apexrest/v1.0/CreateUpdateCompanyAccount';
        req.addHeader('httpMethod', 'POST');
        //req.requestBody = Blob.valueof(JSON);
	    RestContext.request = req;
	    RestContext.response = res;


		// Test the Post method on the REST CreateCase Service
        CreateUpdateCompanyAccount.Response res1 = CreateUpdateCompanyAccount.doPost(coDTO); 
		system.debug(res1);
        
	}	
	
	/*********************************************************
	* Test the picklist logic.
	* TEST PICKLIST.
	*
	* JSON : String defined above as the case JSON passed in.
	*********************************************************/
	public static testMethod void testPicklistCompanyAccount ()
	{
		//Create a mock Company DTO
		CreateUpdateCompanyAccount.CompanyDTO coDTO = new CreateUpdateCompanyAccount.CompanyDTO();
		
	
		// Create Company Account to test update
	    Account a = new Account();
        a.Name = 'Rockin Test Company';
        a.Acronym_short_title__c = 'Test'; 
        a.VAT_number__c = '1234567890';
        a.EU_Tax_registered__c = true;
        a.Customer_Type__c = 'Key Client';
        a.Industry_Type_SIC__c = 'B~ Mining and quarrying';
        a.Use_This_One__c = true;
        a.RecordTypeId=Schema.sObjectType.Account.getRecordTypeInfosByName().get('Business Development Account').getRecordTypeId();
        a.Profile_Company_ID__c = '2f1f4767-e5b6-556a-0505-03fde57a268b';
        a.SIS_Company_ID__c = 'BP0015424';
        a.Sponsor_Contact__c = 'Term';
        a.Invoice_Method__c = 'Email';
        a.Invoice_Delivery__c = 'Email';
        a.Booking_Requirements__c = 'Passport';
        a.Correspondence_Detail__c = 'Email';
        a.Payment_Terms__c = '40 Days';
        a.Credit_Limit__c = 7500;
        a.Website = 'www.test.com';
        a.Discount__c = 25;
        a.Reporting_Required__c = true;
        insert a;	
		
		// Create Business Account to insert
		Account tempAccount = new Account();
		
        tempAccount.Name = 'Rockin Test Company';
        tempAccount.Acronym_short_title__c = 'Test'; 
        tempAccount.VAT_number__c = '1234567890';
        tempAccount.EU_Tax_registered__c = true;
        tempAccount.Customer_Type__c = 'Key Client';
        tempAccount.Industry_Type_SIC__c = 'B~ Mining and quarrying';
        tempAccount.Use_This_One__c = true;
        tempAccount.RecordTypeId=Schema.sObjectType.Account.getRecordTypeInfosByName().get('Business Development Account').getRecordTypeId();
        tempAccount.Profile_Company_ID__c = '2f1f4767-e5b6-556a-0087-03fde57a268b';
        tempAccount.SIS_Company_ID__c = 'BP0015424';
        tempAccount.Sponsor_Contact__c = 'Term';
        tempAccount.Invoice_Method__c = 'Email';
        tempAccount.Invoice_Delivery__c = 'Email';
        tempAccount.Booking_Requirements__c = 'Passport';
        tempAccount.Correspondence_Detail__c = 'Email';
        tempAccount.Payment_Terms__c = '40 Days';
        tempAccount.Credit_Limit__c = 7500;
        tempAccount.Website = 'www.test.com';
        tempAccount.Discount__c = 25;
        tempAccount.Reporting_Required__c = true;
        tempaccount.Sector_Level_1__c = '';
        tempaccount.Sector_Level_2__c = '';
        tempaccount.Payment_Terms__c = '';        
		coDTO.company = tempAccount;

		//Create list of addresses
        List<Address__c> adds = new List<Address__c>();
		Address__c add1 = new Address__c();
		add1.Type__c = 'Billing';
		add1.Street_1__c = '123 S Test Dr';
		add1.Street_2__c = '12345';
		add1.Street_3__c = '1234';
		add1.Street_4__c = '123';
		add1.City__c = 'Test City';
		add1.Text_Locality__c = '12345';
		add1.Text_State__c = '1234';
		add1.Zip_Postal_Code__c = '12345';
		add1.Text_Country__c = '123';
		adds.add(add1);
		coDTO.addresses = adds;


		//Create REST request and response values and objects.
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        
        req.requestURI = '/services/apexrest/v1.0/CreateUpdateCompanyAccount';
        req.addHeader('httpMethod', 'POST');
        //req.requestBody = Blob.valueof(JSON);
	    RestContext.request = req;
	    RestContext.response = res;


		// Test the Post method on the REST CreateCase Service
        CreateUpdateCompanyAccount.Response res1 = CreateUpdateCompanyAccount.doPost(coDTO); 
		system.debug(res1);
        
	}
}