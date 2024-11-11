@RestResource(urlMapping='/v1.0/CreateCoachFaculty')

/*********************************************************
* Inserts a single Faculty into the SFDC instance of type
* Coach. 
*
* CreateCoachDto : Single Faculty in JSON format. Example: 

{
    "coachDto":
            {
                "coach":
                        {
                            "attributes": {
                                "type": "Faculty__c"
                            },
                            "First_Name__c": "Joey",
                            "Last_Name__c": "JoBomber",
                            "Middle_Name__c": "James",
                            "Date_of_Birth__c": "1979-03-23",
                            "Phone__c": "",
                            "Profile_Services_ID__c": "fbb4f6be-0d0a-4a3c-8000-c61322ec4c2b",
                            "Staff_Email_Add__c": "JJJ@gmail.com",
                            "Banner_ID__c": "BP0038331",
                            "Email__c": "",
                            "City__c": "PHOENIX",
                            "Postal_Code__c": "1714452",
                            "Text_Country__c": "USA",
                            "Text_State__c": "US-MO",
                            "Text_Locality__c": "",
                            "Street_1__c": "ChangedAgn",
                            "Street_2__c": "Prt323r",
                            "Street_3__c": "Prnt333r",
                            "Street_4__c": "Homme3me3enex2 4ur STREET"

                        }
            }
}


*
*********************************************************/

global with sharing class CreateCoachFaculty 
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
        
        public Response(String status, String code, String result, String coachId) 
        {
            this.status = status;
            this.code = code;
            this.result=result;
            this.id=coachId;
            
	    }
    }
    
    global class CreateCoachDto{
    	public Faculty__c coach;
    }
    
    @HttpPost
    global static Response doPost(CreateCoachDto coachDto) 
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
      	
      	String coachId = '0';

		list<Faculty__c> facultyList;
 		
    	Set<String> uniqueprofileIds = new Set<String>();
    	
 		
		//Get RecordTypeID for Coach
		Id coachRecordTypeId = Schema.SObjectType.Faculty__c.getRecordTypeInfosByName().get('Faculty').getRecordTypeId();
	
	        //Attempt to Insert the Coach Faculty
	        try
	        {
	    	
			//Check if JSON is null and return 400 for malformed JSON
	        if(coachDto.coach == null)
	        {
	        	status = 'Failure 2 : JSON passed is an empty String. Please check to make sure your JSON is well formed and complete.';
	            LogStatus = 'Error:\n' + status;
	            writeLog(coachDto, LogStatus);
	            res.statusCode = 400;
	            code = '400';
	            result = 'FALSE'; 
	        	
	        }else
		    {
		        facultyList = [Select Id, Profile_Services_ID__c From Faculty__c Where (Profile_Services_ID__c = :coachDto.coach.Profile_Services_ID__c)];
	
				if(facultyList.size()>0)
				{
		        	status = 'Failure 1 : Coach with PS_Profile_Services_ID__pc ' + coachDto.coach.Profile_Services_ID__c + ' exists.';
		            LogStatus = 'Error:\n' + status;
		            writeLog(coachDto, LogStatus);
		            res.statusCode = 300;
		            code = '300';
		            result = 'FALSE'; 
					
				}else
				{
			        
					//Deserialize and Load Faculty from JSON
 					Faculty__c coachFaculty = coachDto.coach;

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
		      	
		
		    		if(coachDto.coach.Text_Country__c != null && coachDto.coach.Text_Country__c != '')
		    		{
		        		if (countryCode.containsKey(coachDto.coach.Text_Country__c))
		        		{
		                  	coachFaculty.Country__c = countryCode.get(coachDto.coach.Text_Country__c.toUpperCase());
		                }
		    		}
		    		
		    		if(coachDto.coach.Text_State__c != null && coachDto.coach.Text_State__c != '')
		    		{
		            	if (stateCode.containsKey(coachDto.coach.Text_State__c))
		            	{
		                    coachFaculty.State_Province__c = stateCode.get(coachDto.coach.Text_State__c.toUpperCase());
		                }
		    		}
		    		
		    		if(coachDto.coach.Text_Locality__c != null && coachDto.coach.Text_Locality__c != '')
		    		{
		                if (localityCode.containsKey(coachDto.coach.Text_Locality__c))
		                {
		                    coachFaculty.Locality__c = localityCode.get(coachDto.coach.Text_Locality__c.toUpperCase());
		                }
		    		}
		    	
					
					coachFaculty.RecordTypeId = coachRecordTypeId;
			 		coachFaculty.Role__c = 'COACH';
			        
			        


			        insert coachFaculty;
			        //Set response for Coach SFDC ID.
			        coachId = coachFaculty.Id;
			  				
				}
	        }
	        writeLog(coachDto, LogStatus);
	
	        return new Response(status,
						         code,
						         result,
						         coachId); 
	        
	        }catch (Exception e) 
	        { 
	            writeLog(coachDto, 'Failure 2' + ':\n' + e.getLineNumber() + ': ' + e.getTypeName() + ' - ' + e.getMessage() + '\n' + e.getStackTraceString());
	            res.statusCode = 500;
	            return new Response('Failure 2' + ':\n' + e.getTypeName() + ' - ' + e.getMessage() + ' - ' + e.getStackTraceString(),
	            '500',
	            'FALSE',
	            coachId);
	        }
	        
    	
    }

	/*********************************************************
	* Writes out to the Log in SFDC 
	*
	* coachDto : The JSON object passed into the service.
	* Status      : The status string that contains any message 
	*               to enter into the log.
	*
	*********************************************************/
    
    private static void writeLog(CreateCoachDto coachDto, String Status)
    {
        Integration_Log_Incoming__c log = new Integration_Log_Incoming__c();
        log.Request_Body__c = JSON.serialize(coachDto);
        log.Request_Date__c = Datetime.now();
        log.Service_Name__c = 'CreateCoachFaculty';
        String details = Status;
        log.Details__c = details;
        insert log;
    }    
}