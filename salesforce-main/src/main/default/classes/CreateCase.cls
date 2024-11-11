@RestResource(urlMapping='/v1.0/CreateCase')
/*********************************************************
* Inserts a single Case into the SFDC instance and adds 
* it to a queue. 
*
* CreateTMDto : Single Caser in JSON format. 
  
  
  Example: 

{
    "eCase":
            {
		"recordName": "SyncBatch Escalation",
                "errorCase": {
                    "attributes": {
                        "type": "Case"
                    },
                    "Affected_User_Identities__c": "Profilefbb4f6be-0d0a-4a3c-8136-c61322ec4c2b",
                    "Affected_User_Type__c": "Training Manager",
                    "Status": "New",
                    "Type": "Technical Integration Issue",
                    "Subject": "Banner Insert Failed",
                    "Priority": "Medium",
                    "Description": "Wow! This is a description Field!"
                }
            }
}


*
*********************************************************/

global with sharing class CreateCase 
{
	/*********************************************************
	* Response clase defining the JSON and 
	* headers for the REST Response.
	*
	* status : Success/Failure + message describing error.
	* code   : Basic SFDC REST Response return codes.
	* result : True/False depending on success or Failure.
	*
	*********************************************************/
	global class Response 
	{
       global String status { get; set; }
       global String code { get; set; }
       global String result { get; set; }
       global String id { get; set; }
        
        public Response(String status, String code, String result, String caseId) 
        {
            this.status = status;
            this.code = code;
            this.result=result;
            this.id=caseId;
            
	    }
    }
    
    global class CreateCaseDto{
     	public string recordName;
    	public Case errorCase;
    }
    
        @HttpPost
    global static Response doPost(CreateCaseDto eCase) 
    {
    	String status = 'Success';
        String LogStatus = 'Success';
        String code = '201';
        String result = 'TRUE';
        String caseId = '0';
        RestResponse res = RestContext.response;
		res.statusCode = 200;
		String reqJSON = '';

        //Attempt to Insert the Training Manager Contact
        try
	    {
			//Check if JSON is null and return 400 for malformed JSON
	        if(eCase.errorCase == null)
	        {
	        	status = 'Failure 1 : JSON passed is an empty String. Please check to make sure your JSON is well formed and complete.';
	            LogStatus = 'Error:\n' + status;
	            writeLog(eCase, LogStatus);
	            res.statusCode = 400;
	            code = '400';
	            result = 'FALSE'; 
	        	
	        }
	        
	 		Case tmpCase = (Case) eCase.errorCase;
	 		
	 		//Set Record ID from passed in name
	 		if(eCase.recordName != '' && eCase.recordName != null)
	    	{
				//Get RecordTypeID by name
				Id caseRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get(eCase.recordName).getRecordTypeId();
	     		tmpCase.RecordTypeId = caseRecordTypeId;
	    	}

	 		//Fetching the assignment rules on case
            AssignmentRule AR = new AssignmentRule();
            AR = [select id from AssignmentRule where SobjectType = 'Case' and Active = true limit 1];

            Database.DMLOptions dmlOpts = new Database.DMLOptions();

            dmlOpts.assignmentRuleHeader.useDefaultRule = true; 

            tmpCase.setOptions(dmlOpts);
	 		
	        insert tmpCase;
	
			//Set the SFDC Case Id to be passed back via the Response
			caseId = tmpCase.Id;
			
	        writeLog(eCase, LogStatus);
	
	        return new Response(status,
						        code,
						        result,
						        caseId); 
	         
        }catch (Exception e) 
        { 
            writeLog(eCase, 'Failure 2' + ':\n' + e.getLineNumber() + ': ' + e.getTypeName() + ' - ' + e.getMessage() + '\n' + e.getStackTraceString());
            res.statusCode = 500;
            return new Response('Failure 2' + ':\n' + e.getTypeName() + ' - ' + e.getMessage() + ' - ' + e.getStackTraceString(),
					            '500',
					            'FALSE',
					            caseId);
        }
        
        
    	
    }

	/*********************************************************
	* Writes out to the Log in SFDC 
	*
	* eCase       : The JSON object passed into the service.
	* Status      : The status string that contains any message 
	*               to enter into the log.
	*
	*********************************************************/
    
    private static void writeLog(CreateCaseDto eCase, String Status)
    {
        Integration_Log_Incoming__c log = new Integration_Log_Incoming__c();
        log.Request_Body__c = JSON.serialize(eCase);
        log.Request_Date__c = Datetime.now();
        log.Service_Name__c = 'CreateTrainingManagerContactWebService';
        String details = Status;
        log.Details__c = details;
        insert log;
    }    
    
    
}