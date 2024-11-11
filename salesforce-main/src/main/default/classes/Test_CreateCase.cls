@isTest()
public with sharing class Test_CreateCase 
{

	static final String JSON = '{"eCase": {"recordName": "SyncBatch Escalation","errorCase": {"attributes": {"type": "Case"},"Affected_User_Identities__c": "Profilefbb4f6be-0d0a-4a3c-8136-c61322ec4c2b","Affected_User_Type__c": "Training Manager","Status": "New","Type": "Technical Integration Issue","Subject": "Banner Insert Failed","Priority": "Medium","Description": "Wow! This is a description Field!"}}}';

	/*********************************************************
	* Test the REST interface. This will also test the Record
	* Type portions of Create Case.
	*
	* JSON : String defined above as the case JSON passed in.
	*********************************************************/
	public static testMethod void testRestCreateCase ()
	{
		//Create a mock case
		CreateCase.CreateCaseDto testerCase = new CreateCase.CreateCaseDto();
		testerCase.recordName = 'SyncBatch Escalation';
		Case tempCase = new Case();
		
		tempCase.Affected_User_Identities__c = 'Profilefbb4f6be-0d0a-4a3c-8136-c61322ec4c2b';
		tempCase.Affected_User_Type__c = 'Training Manager';
		tempCase.Status = 'New';
		tempCase.Type = 'Technical Integration Issue';
		tempCase.Subject = 'Banner Insert Failed';
		tempCase.Priority = 'Medium';
		tempCase.Description = 'Description';
		testerCase.errorCase = tempCase;

		//Create REST request and response values and objects.
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        
        req.requestURI = '/services/apexrest/v1.0/CreateCase';
        req.addHeader('httpMethod', 'POST');
        req.requestBody = Blob.valueof(JSON);
	    RestContext.request = req;
	    RestContext.response = res;


		// Test the Post method on the REST CreateCase Service
        CreateCase.Response res1 = CreateCase.doPost(testerCase); 
	}

}