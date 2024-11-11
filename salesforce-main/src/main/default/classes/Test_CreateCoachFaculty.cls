@isTest()
public with sharing class Test_CreateCoachFaculty 
{


	/*********************************************************
	* Test the REST interface. This will also test the Record
	* Type portions of Create Coach.
	*
	*********************************************************/
	public static testMethod void testCreateCoach ()
	{
		//Create a Caoch Faculty__c
		CreateCoachFaculty.CreateCoachDto testerCoach = new CreateCoachFaculty.CreateCoachDto();
		Faculty__c tempCoach = new Faculty__c();
		
		tempCoach.First_Name__c = 'Bilbo';
		tempCoach.Last_Name__c = 'Baggins';
		tempCoach.Middle_Name__c = 'B';
		tempCoach.Date_of_Birth__c = Date.newInstance(1900, 4, 5);
		tempCoach.Profile_Services_ID__c = 'fbb4f6be-0d0a-4a3c-BILBO-c61322ec4c2b';
		tempCoach.Staff_Email_Add__c = 'bilbo@gmail.com';
		tempCoach.City__c = 'Green Bay';
		tempCoach.Postal_Code__c = '56841';
		tempCoach.Text_Country__c = 'USA';
		tempCoach.Text_State__c = 'US-WI';
		tempCoach.Text_Locality__c = '';
		tempCoach.Street_1__c = '123 Bay Street';
		tempCoach.Street_2__c = 'Apt. 4';
		tempCoach.Street_3__c = 'Box 3';
		tempCoach.Street_4__c = 'Streety Street Street';


		testerCoach.coach = tempCoach;

		//Create REST request and response values and objects.
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        
        req.requestURI = '/services/apexrest/v1.0/CreateCoachFaculty';
        req.addHeader('httpMethod', 'POST');
	    RestContext.request = req;
	    RestContext.response = res;


		// Test the Post method on the REST CreateCoach Service
        CreateCoachFaculty.Response res1 = CreateCoachFaculty.doPost(testerCoach); 
	}

	/*********************************************************
	* Test the NULL Coach passed in.
	*
	*********************************************************/
	public static testMethod void testCreateNullCoach ()
	{
		//Create a Caoch Faculty__c
		CreateCoachFaculty.CreateCoachDto testerCoach = new CreateCoachFaculty.CreateCoachDto();
		Faculty__c tempCoach = new Faculty__c();
		
		testerCoach.coach = null;

		//Create REST request and response values and objects.
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        
        req.requestURI = '/services/apexrest/v1.0/CreateCoachFaculty';
        req.addHeader('httpMethod', 'POST');
	    RestContext.request = req;
	    RestContext.response = res;


		// Test the Post method on the REST CreateCoach Service
        CreateCoachFaculty.Response res1 = CreateCoachFaculty.doPost(testerCoach); 
	}
	
	/**************************************************************
	* Test the code to check if coach exists with same profile ID.
	*
	**************************************************************/
	public static testMethod void testCreateDuplicateCoach ()
	{
		//Create a Caoch Faculty__c
		CreateCoachFaculty.CreateCoachDto testerCoach = new CreateCoachFaculty.CreateCoachDto();
		Faculty__c tempCoach = new Faculty__c();
		
		tempCoach.First_Name__c = 'Bilbo';
		tempCoach.Last_Name__c = 'Baggins';
		tempCoach.Middle_Name__c = 'B';
		tempCoach.Date_of_Birth__c = Date.newInstance(1900, 4, 5);
		tempCoach.Profile_Services_ID__c = 'fbb4f6be-0d0a-4a3c-BILBO1-c61322ec4c2b';
		tempCoach.Staff_Email_Add__c = 'bilbo@gmail.com';
		tempCoach.City__c = 'Green Bay';
		tempCoach.Postal_Code__c = '56841';
		tempCoach.Text_Country__c = 'USA';
		tempCoach.Text_State__c = 'US-WI';
		tempCoach.Text_Locality__c = '';
		tempCoach.Street_1__c = '123 Bay Street';
		tempCoach.Street_2__c = 'Apt. 4';
		tempCoach.Street_3__c = 'Box 3';
		tempCoach.Street_4__c = 'Streety Street Street';
        insert tempCoach;

		testerCoach.coach = tempCoach;

		//Create REST request and response values and objects.
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        
        req.requestURI = '/services/apexrest/v1.0/CreateCoachFaculty';
        req.addHeader('httpMethod', 'POST');
	    RestContext.request = req;
	    RestContext.response = res;


		// Test the Post method on the REST CreateCoach Service
        CreateCoachFaculty.Response res1 = CreateCoachFaculty.doPost(testerCoach); 
	}
	
}