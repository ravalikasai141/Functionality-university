@RestResource(urlMapping='/v1.0/CreateUpdateCompanyAccount')

/*********************************************************
* Inserts a single Company Account if no Profile_Company_ID__c
* is supplied in the JSON or Updates the Company Account that 
* has the supplied Profile_Company_ID__c. 
*
* CreateCompanyDto : Single Company in JSON format. Example: 

{
    "coDTO":
            {
                "company": {
                    "attributes": {
                        "type": "Account"
                    },
                    "Name": "This is a New Business Account",
                    "Profile_Company_ID__c": "2f1f4767-e5b6-556a-8277-03fde57a268b",
                    "SIS_Company_ID__c": "2f1f4767-e5b6-556a-8277-03fde57a268b",
                    "VAT_number__c": "1234",
                    "Acronym_short_title__c": "Test",
                    "Customer_Type__c": "",
                    "Sector_Level_1__c": "Law",
                    "Sector_Level_2__c": "Law Firm",
                    "Payment_Terms__c": "30 days",
                    "Credit_Limit__c": "",
                    "Phone": "Phone"
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
                        "City__c": "PHOENIX",
                        "Primary__c": "",
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

global with sharing class CreateUpdateCompanyAccount {
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
        
        public Response(String status, String code, String result, String companyId) 
        {
            this.status = status;
            this.code = code;
            this.result=result;
            this.id=companyId;
            
            
	    }
    }
	/*********************************************************
	* Comapny DTO Example is above. This is the primary JSON
	* Data Transfer Object.
	*
	*********************************************************/
    
    global class CompanyDTO 
    {
        public Account company;
        public list<Address__c> addresses;
    }
    
	/*********************************************************
	* Request handler for REST call
	*
	* coDTO : DTO past through the Post as JSON
	*
	*********************************************************/
   
    @HttpPost
    global static Response doPost(CompanyDTO coDTO) 
    {
    	return ProcessCompanyAccount(coDTO);
    }

	/*********************************************************
	* Method to process the REST Post
	*
	* coDTO : DTO past as JSON
	*
	*********************************************************/
    
    global static Response ProcessCompanyAccount(CompanyDTO coDTO) 
    {
    	String status = 'Success';
        String LogStatus;
        String Fresponse;
        String companyId = '0';
        String code = '201';
        String result = 'TRUE';
        RestResponse res = RestContext.response;
		res.statusCode = 200;
        
        list<Account> uniqueaccountList;

  		list<Account> insertAcc = new list<Account>();
  		list<Address__c> insertAdd = new list<Address__c>();
      	list<Address__c> incomingAdd = new list<Address__c>();
      	
      	map<String, Id> countryCode = new map<String, Id>();
      	map<String, Id> stateCode = new map<String, Id>();
      	map<String, Id> localityCode = new map<String, Id>();
      	
      	list<country_list__c> countries;
      	list<State_Province__c> states;
      	list<Locality__c> localities;

        try 
        {
        	Set<String> uniqueprofileIds = new Set<String>();
        	
        	if( coDTO.company != null && coDTO.company.Profile_Company_ID__c != '' && coDTO.company.Profile_Company_ID__c != null)
        	{
        		uniqueprofileIds.add(coDTO.company.Profile_Company_ID__c);
	            uniqueaccountList = [Select Id, PS_Profile_Services_ID__pc, Profile_Company_ID__c From Account Where (PS_Profile_Services_ID__pc IN :uniqueprofileIds) OR (Profile_Company_ID__c IN :uniqueprofileIds)];
        	}
      	
      	    //Check that picklist values passed in exist in target picklists
      	    //Load Picklist Values from SFDC for comparison with passed in values
  			list<String> sector1Options =  getPicklistValues('Account', 'Sector_Level_1__c');
  			list<String> sector2Options =  getPicklistValues('Account', 'Sector_Level_2__c');
  			list<String> paymentOptions =  getPicklistValues('Account', 'Payment_Terms__c');
      		
          	//Check Sector Level 1 is in the SFDC picklist for that object. If no value is passed in, do not check.
          	if(!setContains(sector1Options,coDTO.company.Sector_Level_1__c) && coDTO.company.Sector_Level_1__c!='' && coDTO.company.Sector_Level_1__c!=null)
          	{
        		status = 'Failure 1.1 : Sector Level 1 value not found in picklist. Value : ' + coDTO.company.Sector_Level_1__c;
        		LogStatus = 'Failure 1.1 ' + ':\n' + status;
	            res.statusCode = 500;
	            code = '500';
	            result = 'FALSE'; 
	            writeLog(coDTO, LogStatus);
	            return new Response(status,
							        code,
							        result,
							        companyId); 
	            
          		
          	}

          	//Check Sector Level 2 is in the SFDC picklist for that object. If no value is passed in, do not check.
          	if(!setContains(sector2Options,coDTO.company.Sector_Level_2__c) && coDTO.company.Sector_Level_2__c!='' && coDTO.company.Sector_Level_2__c!=null)
          	{
        		status = 'Failure 1.2 : Sector Level 2 value not found in picklist. Value : ' + coDTO.company.Sector_Level_2__c;
        		LogStatus = 'Failure 1.2 ' + ':\n' + status;
	            res.statusCode = 500;
	            code = '500';
	            result = 'FALSE'; 
	            writeLog(coDTO, LogStatus);
	            return new Response(status,
							        code,
							        result,
							        companyId); 
          		
          	}

          	//Check Payment Terms is in the SFDC picklist for that object. If no value is passed in, do not check.
          	if(!setContains(paymentOptions,coDTO.company.Payment_Terms__c) && coDTO.company.Payment_Terms__c!='' && coDTO.company.Payment_Terms__c!=null)
          	{
        		status = 'Failure 1.3 : Payment Terms value not found in picklist. Value : ' + coDTO.company.Payment_Terms__c;
        		LogStatus = 'Failure 1.3 ' + ':\n' + status;
	            res.statusCode = 500;
	            code = '500';
	            result = 'FALSE'; 
	            writeLog(coDTO, LogStatus);
	            return new Response(status,
							        code,
							        result,
							        companyId); 
          		
          	}          	
      	
          	
          	if(uniqueaccountList.size()==1)
          	{
          		Account updateCompanyAccount = coDTO.company;
          		updateCompanyAccount.Id = uniqueaccountList[0].Id;
          		update updateCompanyAccount;
          		status = 'Success';
          		LogStatus = ':\n' + status;
          		companyId = updateCompanyAccount.Id;
          	}else if(uniqueaccountList.size()>1)
          	{
          		status = 'Failure1 : More than one Company with that profile id.';
          		LogStatus = ':\n' + status;
	            res.statusCode = 300;
	            code = '300';
	            result = 'FALSE'; 
          	}
          	else
          	{
          		

	          	
		        //Get RecordTypeID for Training Manager
				Id coRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Business Development Account').getRecordTypeId();
          		
          		if(coDTO.company != null)
          		{
          			Account acc = new Account();
                	acc = coDTO.company;
                	acc.RecordTypeId = coRecordTypeId;
                	insertAcc.add(acc);
            	}
            	else
            	{
            		status = 'Failure 2 : No Company information found in Request';
            		LogStatus = 'Failure 2 ' + ':\n' + status;
		            res.statusCode = 500;
		            code = '500';
		            result = 'FALSE'; 
            	}
            	
            	if(coDTO.addresses != null)
            	{
        			incomingAdd.addAll(coDTO.addresses);
        		}
        		
	          	insert insertAcc;
	          	companyId = insertAcc[0].Id;
          
          
	          	
	          	//Prep countries/states/localites for inserting Addresses
	          	if(incomingAdd.size() > 0)
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
	          	}
	          	
              	if(insertAcc[0].Id != null)
              	{
              		if(coDTO.addresses != null)
              		{
                  		for(Address__c adds: coDTO.addresses)
                  		{
                    		Address__c add = new Address__c();
                    		add = adds; 
                    		add.Student__c = insertAcc[0].Id;
                    		
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
              		}
                 }
	            insert insertAdd;
	        }
	        writeLog(coDTO, LogStatus);
	        return new Response(status,
	        '201',
	        'TRUE',
	        companyId); 
        }
        catch (Exception e) 
        {
        	Fresponse =  'Failure' + ':\n' + e.getTypeName() + ' - ' + e.getMessage();
        	res.statusCode = 500;
            writeLog(coDTO, 'Failure' + ':\n' + e.getLineNumber() + ': ' + e.getTypeName() + ' - ' + e.getMessage() + '\n' + e.getStackTraceString());
			return new Response(Fresponse,
                    '500',
                    'FALSE',
                    companyId);
        }
    }
    
    
	/***********************************************************************
	* Retrieves the picklist values (as a list) from SFDC given
	* the SObject name and field name 
	*
	* ObjectApi_name : The name of the SObject ex. Account.
	* Field_name     : The name of the Field on that SObject 
	*                  passed. Must be a picklist. ex. Payment_Terms__c
	*
	***********************************************************************/
   public static List<String> getPicklistValues(String ObjectApi_name,String Field_name)
   { 

	  	List<String> lstPickvals=new List<String>();
	  
	    //From the Object Api name retrieving the SObject
	  	Schema.SObjectType targetType = Schema.getGlobalDescribe().get(ObjectApi_name);
	    Sobject Object_name = targetType.newSObject();
	    
	 	 //grab the sobject that was passed
	 	Schema.sObjectType sobject_type = Object_name.getSObjectType();
	 	
	    //describe the sobject
	    Schema.DescribeSObjectResult sobject_describe = sobject_type.getDescribe(); 
	    
	    //get a map of fields for the passed sobject
	    Map<String, Schema.SObjectField> field_map = sobject_describe.fields.getMap(); 
	    
	    //grab the list of picklist values for the passed field on the sobject
	    List<Schema.PicklistEntry> pick_list_values = field_map.get(Field_name).getDescribe().getPickListValues(); 
	    
	    //for all values in the picklist list
	    for (Schema.PicklistEntry a : pick_list_values) 
	    { 
	    	//add the value  to our final list
	        lstPickvals.add(a.getValue());
	   	}
	
	  return lstPickvals;
   }
   
	/***********************************************************************
	* Checks if a Set contains the String passed.
	* Returns true if String is in Set, false is not.
	*
	* Options : List of the Strings contianing the Options in a Picklist.
	* Target  : Target String to look for in the picklist. 
	*
	***********************************************************************/
   public static Boolean setContains(list<String> Options, String Target)
   {
   	Set<String> opSet = new Set<String>();
          		
	opSet.addAll(Options);
   	
   	return opSet.contains(Target);
   	
   } 

	/*********************************************************
	* Writes out to the Log in SFDC 
	*
	* trainingMGR : The JSON object passed into the service.
	* Status      : The status string that contains any message 
	*               to enter into the log.
	*
	*********************************************************/
    
    private static void writeLog(CompanyDTO coDTO, String Status)
    {
        Integration_Log_Incoming__c log = new Integration_Log_Incoming__c();
        log.Request_Body__c = JSON.serialize(coDTO);
        log.Request_Date__c = Datetime.now();
        log.Service_Name__c = 'CreateStudentAccount';
        log.Details__c = Status;
        insert log;
    }
}