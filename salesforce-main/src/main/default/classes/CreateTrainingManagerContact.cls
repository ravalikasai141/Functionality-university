@RestResource(urlMapping='/v1.0/CreateTrainingManagerContact')

/*********************************************************
* Inserts a single Contact into the SFDC instance. 
*
* CreateTMDto : Single Contact in JSON format. Example: 
{
{
    "trainingMGR":
            {
                "companyProfileId": "2f1f4767-e5b6-956a-8277-03fde57a268b",
                "tMgr": {
                    "attributes": {
                        "type": "Contact"
                    },
                    "FirstName": "Joey",
                    "LastName": "JoBomber",
                    "Middle_Name__c": "James",
                    "Preferred_First_Name__c": "Joe",
                    "Salutation": "Mr.",
                    "AA_Suffix__c": "III",
                    "Title": "",
                    "Birthdate": "1979-03-23",
                    "Business_Unit__c": "",
                    "Cost_Centre_Number__c": "",
                    "Gender__c": "Male",
                    "VAT_Code__c": "",
                    "Work_Phone__c": "",
                    "MobilePhone": "",
                    "OtherPhone": "",
                    "HomePhone": "",
                    "Preferred_Phone__c": "",
                    "Home_Phone__c": "555-555-5555",
                    "Preferred_Phone__c": "555-555-5555",
                    "PS_Profile_Services_ID__c": "fbb4f6be-0d0a-4a3c-8136-c61322ec4c2b",
                    "Other_Email__c": "JJJ@gmail.com",
                    "BNR_Banner_ID__c": "BP0038331",
                    "Personal_Email__c": "",
                    "Work_Email__c": "",
                    "BPP_Email__c": "",
                    "Billing_Email__c": "",
                    "Preferred_email__c": "JJJ@gmail.com"
                },
                "addresses": [
                    {
                        "attributes": {
                            "type": "Address__c"
                        },
                        "Primary__c": "",
                        "City__c": "PHOENIX",
                        "Zip_Postal_Code__c": "1714452",
                        "Text_Country__c": "USA",
                        "Text_State__c": "US-MS",
                        "Text_Locality__c": "",
                        "Type__c": "Mailing",
                        "Street_1__c": "ChangedAgn",
                        "Street_2__c": "Prt323r",
                        "Street_3__c": "Prnt333r",
                        "Street_4__c": "Homme3me3enex2 4ur STREET"
                    },
                    {
                        "attributes": {
                            "type": "Address__c"
                        },
                        "Primary__c": "",
                        "City__c": "PHOENIX",
                        "Zip_Postal_Code__c": "1714462",
                        "Text_Country__c": "USA",
                        "Text_State__c": "US-MS",
                        "Text_Locality__c": "",
                        "Type__c": "Billing",
                        "Street_1__c": "123",
                        "Street_2__c": "1233 ",
                        "Street_3__c": "111222",
                        "Street_4__c": "123 2 STREET"
                    }
                ]
            }
}


*
*********************************************************/

global with sharing class CreateTrainingManagerContact 
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
        
        public Response(String status, String code, String result, String tmId) 
        {
            this.status = status;
            this.code = code;
            this.result=result;
            this.id=tmId;
            
	    }
    }
    
    global class CreateTMDto{
    	public String companyProfileId;
    	public Contact tMgr;
    	public list<Address__c> addresses;
    }
    
    @HttpPost
    global static Response doPost(CreateTMDto trainingMGR) 
    {
    	String status = 'Success';
        String LogStatus = 'Success';
        String code = '201';
        String result = 'TRUE';
        RestResponse res = RestContext.response;
		res.statusCode = 200;
		String reqJSON = '';
		String companyId = null;

	    map<String, Id> countryCode = new map<String, Id>();
      	map<String, Id> stateCode = new map<String, Id>();
      	map<String, Id> localityCode = new map<String, Id>();
      	
      	list<country_list__c> countries;
      	list<State_Province__c> states;
      	list<Locality__c> localities;
      	list<Address__c> insertAdd = new list<Address__c>();
      	list<Account> uniqueAccountList;
      	
      	String tmId = '0';

		list<Contact> contactList;
 		
    	Set<String> uniqueprofileIds = new Set<String>();
    	
    	if( trainingMGR.tMgr != null && trainingMGR.companyProfileId != '' && trainingMGR.companyProfileId != null)
    	{
    		uniqueAccountList = [Select Id, PS_Profile_Services_ID__pc, Profile_Company_ID__c From Account Where (Profile_Company_ID__c = :trainingMGR.companyProfileId)];
    	}
      	
      	if(uniqueAccountList.size()>1)
      	{
      		status = 'Failure 1: More than one company with the profile id : ' + trainingMGR.companyProfileId;
      		LogStatus = ':\n' + status;
            res.statusCode = 300;
            code = '300';
            result = 'FALSE'; 
            return new Response(status,
					            code,
					            result,
					            tmId);
            
      	}
 		
 		
 		
 		//Deserialize and Load Contact from JSON
 		Contact trainMGR = trainingMGR.tMgr;
 		trainMGR.AccountId=uniqueAccountList[0].Id;
 		
		//Get RecordTypeID for Training Manager
		Id tmRecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Training Manager').getRecordTypeId();
	
	        //Attempt to Insert the Training Manager Contact
	        try
	        {
	    	
			//Check if JSON is null and return 400 for malformed JSON
	        if(trainingMGR.tMgr == null)
	        {
	        	status = 'Failure 2 : JSON passed is an empty String. Please check to make sure your JSON is well formed and complete.';
	            LogStatus = 'Error:\n' + status;
	            writeLog(trainingMGR, LogStatus);
	            res.statusCode = 400;
	            code = '400';
	            result = 'FALSE'; 
	        	
	        }else
		    {
		        contactList = [Select Id, PS_Profile_Services_ID__c From Contact Where (PS_Profile_Services_ID__c = :trainingMGR.tMgr.PS_Profile_Services_ID__c)];
	
				if(contactList.size()>0)
				{
		        	status = 'Failure 1 : Training manager with PS_Profile_Services_ID__pc ' + trainingMGR.tMgr.PS_Profile_Services_ID__c + ' exists.';
		            LogStatus = 'Error:\n' + status;
		            writeLog(trainingMGR, LogStatus);
		            res.statusCode = 300;
		            code = '300';
		            result = 'FALSE'; 
					
				}else
				{
			        
			 		trainMGR.RecordTypeId = tmRecordTypeId;
			 		
			        insert trainMGR;
			        
			        //Set response for Training Manager SFDC ID.
			        tmId = trainMGR.Id;
			        
			        //Populate country/State/city codes
			  		if(trainingMGR.addresses != null)
			  		{
			          	countries = [Select Id, ISO_CODE__c From country_list__c Where ISO_CODE__c != '' AND 
			                         ISO_CODE__c != null];
			            for (country_list__c cntry : countries)
			            {
			                countryCode.put(cntry.ISO_CODE__c.toUpperCase(), cntry.Id);
			            }
			          	states = [Select Id, ISO_Code__c From State_Province__c Where ISO_Code__c != '' AND 
			            	      ISO_Code__c != null];
			            for (State_Province__c stt : states)
			            {
			                stateCode.put(stt.ISO_Code__c.toUpperCase(), stt.Id);
			            }
			          	localities = [Select Id, Banner_Code__c From Locality__c Where Banner_Code__c != '' AND 
			                          Banner_Code__c != null];
			            for (Locality__c lcty : localities)
			            {
			                localityCode.put(lcty.Banner_Code__c.toUpperCase(), lcty.Id);
			            }
			      	
			
				  		for(Address__c adds: trainingMGR.addresses)
				  		{
				    		Address__c add = new Address__c();
				    		add = adds; 
				    		add.Training_Manager__c = trainMGR.Id;
				    		
				    		if(add.Text_Country__c != null && add.Text_Country__c != '')
				    		{
				        		if (countryCode.containsKey(add.Text_Country__c.toUpperCase()))
				        		{
				                  	add.Lookup_Country__c = countryCode.get(add.Text_Country__c.toUpperCase());
				                }
				    		}
				    		
				    		if(add.Text_State__c != null && add.Text_State__c != '')
				    		{
				            	if (stateCode.containsKey(add.Text_State__c.toUpperCase()))
				            	{
				                    add.State_Province__c = stateCode.get(add.Text_State__c.toUpperCase());
				                }
				    		}
				    		
				    		if(add.Text_Locality__c != null && add.Text_Locality__c != '')
				    		{
				                if (localityCode.containsKey(add.Text_Locality__c.toUpperCase()))
				                {
				                    add.Locality__c = localityCode.get(add.Text_Locality__c.toUpperCase());
				                }
				    		}
				            insertAdd.add(add);
				  		}
				  		insert insertAdd;
			  		}		
				}
	        }
	        
	        }catch (Exception e) 
	        { 
	            writeLog(trainingMGR, 'Failure 2' + ':\n' + e.getLineNumber() + ': ' + e.getTypeName() + ' - ' + e.getMessage() + '\n' + e.getStackTraceString());
	            res.statusCode = 500;
	            return new Response('Failure 2' + ':\n' + e.getTypeName() + ' - ' + e.getMessage() + ' - ' + e.getStackTraceString(),
	            '500',
	            'FALSE',
	            tmId);
	        }
	        
	         writeLog(trainingMGR, LogStatus);
	
	         return new Response(status,
						         code,
						         result,
						         tmId); 
    	
    }

	/*********************************************************
	* Writes out to the Log in SFDC 
	*
	* trainingMGR : The JSON object passed into the service.
	* Status      : The status string that contains any message 
	*               to enter into the log.
	*
	*********************************************************/
    
    private static void writeLog(CreateTMDto trainingMGR, String Status)
    {
        Integration_Log_Incoming__c log = new Integration_Log_Incoming__c();
        log.Request_Body__c = JSON.serialize(trainingMGR);
        log.Request_Date__c = Datetime.now();
        log.Service_Name__c = 'CreateTrainingManagerContactWebService';
        String details = Status;
        log.Details__c = details;
        insert log;
    }    
    
}