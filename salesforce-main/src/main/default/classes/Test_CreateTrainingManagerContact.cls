@isTest()
public with sharing class Test_CreateTrainingManagerContact 
{
	static final String JSON = '{{"trainingMGR":{"companyProfileId": "2f1f4767-1111-4444-5555-03fde57a268b","tMgr": {"attributes": {"type": "Contact"},"FirstName": "Joey","LastName": "JoBomber","Middle_Name__c": "James","Preferred_First_Name__c": "Joe","Salutation": "Mr.","AA_Suffix__c": "III","Title": "","Birthdate": "1979-03-23","Business_Unit__c": "","Cost_Centre_Number__c": "","Gender__c": "Male","VAT_Code__c": "","Work_Phone__c": "","MobilePhone": "","OtherPhone": "","HomePhone": "","Preferred_Phone__c": "","Home_Phone__c": "555-555-5555","Preferred_Phone__c": "555-555-5555","PS_Profile_Services_ID__c": "fbb4f6be-0d0a-4a3c-8136-c61322ec4c2b","Other_Email__c": "JJJ@gmail.com","BNR_Banner_ID__c": "BP0038331","Personal_Email__c": "","Work_Email__c": "","BPP_Email__c": "","Billing_Email__c": "","Preferred_email__c": "JJJ@gmail.com"},"addresses": [{"attributes": {"type": "Address__c"},"Primary__c": "","City__c": "PHOENIX","Zip_Postal_Code__c": "1714452","Text_Country__c": "USA","Text_State__c": "US-MS","Text_Locality__c": "","Type__c": "Mailing","Street_1__c": "ChangedAgn","Street_2__c": "Prt323r","Street_3__c": "Prnt333r","Street_4__c": "Homme3me3enex2 4ur STREET"},{"attributes": {"type": "Address__c"},"Primary__c": "","City__c": "PHOENIX","Zip_Postal_Code__c": "1714462","Text_Country__c": "USA","Text_State__c": "US-MS","Text_Locality__c": "","Type__c": "Billing","Street_1__c": "123","Street_2__c": "1233 ","Street_3__c": "111222","Street_4__c": "123 2 STREET"}]}}';

	/*********************************************************
	* Test the REST interface. This will also test the Record
	* Type portions of Create TM.
	*
	* JSON : String defined above as the case JSON passed in.
	*********************************************************/
	
	public static testMethod void testRestCreateTrainingManagerContact ()
	{
		//Create a mock case
		CreateTrainingManagerContact.CreateTMDto TMDTO = new CreateTrainingManagerContact.CreateTMDto();
		
		// Set the Company Profile ID
		TMDTO.companyProfileId = '2f1f4767-1111-4444-5555-03fde57a268b';
		
	
		// Create Company Account to attach TM to
	    Account a = new Account();
        a.Name = 'Rockin Test Company';
        a.Acronym_short_title__c = 'Test'; 
        a.VAT_number__c = '1234567890';
        a.EU_Tax_registered__c = true;
        a.Customer_Type__c = 'Key Client';
        a.Industry_Type_SIC__c = 'B~ Mining and quarrying';
        a.Use_This_One__c = true;
        a.RecordTypeId=Schema.sObjectType.Account.getRecordTypeInfosByName().get('Business Development Account').getRecordTypeId();
        a.Profile_Company_ID__c = TMDTO.companyProfileId;
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
		
		// Create TM Contact
		Contact tempContact = new Contact();
		
		tempContact.FirstName = 'Tommy';
		tempContact.LastName = 'Tesla';
		tempContact.Middle_Name__c = 'W';
		tempContact.Salutation = 'Mr.';
		tempContact.AA_Suffix__c = 'III';
		tempContact.Title = 'Emperor';
		tempContact.Birthdate =  date.ValueOf('1979-03-23');
		tempContact.Business_Unit__c = '';
		tempContact.Cost_Centre_Number__c = '';
		tempContact.Gender__c = 'Male';
		tempContact.VAT_Code__c = '';
		tempContact.Work_Phone__c = '';
		tempContact.MobilePhone = '';
		tempContact.OtherPhone = '';
		tempContact.HomePhone = '';
		tempContact.Preferred_Phone__c = '';
		tempContact.Home_Phone__c = '555-444-5858';
		tempContact.PS_Profile_Services_ID__c = 'fbb4f6be-2323-3434-5656-c61322ec4c2b';
		tempContact.Other_Email__c = 'TT@gmail.com';
		tempContact.BNR_Banner_ID__c = 'BP0038331';
		tempContact.Personal_Email__c = '';
		tempContact.Work_Email__c = '';
		tempContact.BPP_Email__c = '';
		tempContact.Billing_Email__c = '';
		tempContact.Preferred_email__c = 'TT@gmail.com';
		TMDTO.tMgr = tempContact;

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
		TMDTO.addresses = adds;


		//Create REST request and response values and objects.
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        
        req.requestURI = '/services/apexrest/v1.0/CreateTrainingManagerContact';
        req.addHeader('httpMethod', 'POST');
        req.requestBody = Blob.valueof(JSON);
	    RestContext.request = req;
	    RestContext.response = res;


		// Test the Post method on the REST CreateCase Service
        CreateTrainingManagerContact.Response res1 = CreateTrainingManagerContact.doPost(TMDTO); 
	}
	
	public static testMethod void testNullCreateTrainingManagerContact ()
	{
		//Create a mock case
		CreateTrainingManagerContact.CreateTMDto TMDTO = new CreateTrainingManagerContact.CreateTMDto();
		
		// Set the Company Profile ID
		TMDTO.companyProfileId = '2f1f4767-1111-4444-5555-03fde57a268b';
		
	
		// Create Company Account to attach TM to
	    Account a = new Account();
        a.Name = 'Rockin Test Company';
        a.Acronym_short_title__c = 'Test'; 
        a.VAT_number__c = '1234567890';
        a.EU_Tax_registered__c = true;
        a.Customer_Type__c = 'Key Client';
        a.Industry_Type_SIC__c = 'B~ Mining and quarrying';
        a.Use_This_One__c = true;
        a.RecordTypeId=Schema.sObjectType.Account.getRecordTypeInfosByName().get('Business Development Account').getRecordTypeId();
        a.Profile_Company_ID__c = TMDTO.companyProfileId;
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
		
		// Create TM Contact
		Contact tempContact = new Contact();
/*		
		tempContact.FirstName = 'Tommy';
		tempContact.LastName = 'Tesla';
		tempContact.Middle_Name__c = 'W';
		tempContact.Salutation = 'Mr.';
		tempContact.AA_Suffix__c = 'III';
		tempContact.Title = 'Emperor';
		tempContact.Birthdate =  date.ValueOf('1979-03-23');
		tempContact.Business_Unit__c = '';
		tempContact.Cost_Centre_Number__c = '';
		tempContact.Gender__c = 'Male';
		tempContact.VAT_Code__c = '';
		tempContact.Work_Phone__c = '';
		tempContact.MobilePhone = '';
		tempContact.OtherPhone = '';
		tempContact.HomePhone = '';
		tempContact.Preferred_Phone__c = '';
		tempContact.Home_Phone__c = '555-444-5858';
		tempContact.PS_Profile_Services_ID__c = 'fbb4f6be-2323-3434-5656-c61322ec4c2b';
		tempContact.Other_Email__c = 'TT@gmail.com';
		tempContact.BNR_Banner_ID__c = 'BP0038331';
		tempContact.Personal_Email__c = '';
		tempContact.Work_Email__c = '';
		tempContact.BPP_Email__c = '';
		tempContact.Billing_Email__c = '';
		tempContact.Preferred_email__c = 'TT@gmail.com';
*/		TMDTO.tMgr = tempContact;

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
		TMDTO.addresses = adds;


		//Create REST request and response values and objects.
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        
        req.requestURI = '/services/apexrest/v1.0/CreateTrainingManagerContact';
        req.addHeader('httpMethod', 'POST');
//        req.requestBody = Blob.valueof(JSON);
	    RestContext.request = req;
	    RestContext.response = res;


		// Test the Post method on the REST CreateCase Service
        CreateTrainingManagerContact.Response res1 = CreateTrainingManagerContact.doPost(TMDTO); 
	}
}