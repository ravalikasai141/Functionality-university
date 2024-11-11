public with sharing class Util 
{
    public class UtilityException extends Exception{}
	
    public static string getCreatableFieldsSOQL(String objectName, String whereClause) {
        String selects = '';         
        if (whereClause == null || whereClause == '') { return null; }         
        
        // Get a map of field name and field token        
        Map<String, Schema.SObjectField> fMap = 
            Schema.getGlobalDescribe().get(objectName.toLowerCase()).getDescribe().Fields.getMap();        
        list<string> selectFields = getCreatableFields(objectName);      
        
        if (!selectFields.isEmpty()) {            
            for (string s:selectFields) {                
                selects += s + ',';           
            }            
            if (selects.endsWith(',')) {
                selects = selects.substring(0,selects.lastIndexOf(','));
            }         
        }         
        
        return 'SELECT ' + selects + ' FROM ' + objectName + ' WHERE ' + whereClause;      
    }
    
    public static string getAllFieldsSOQL(String objectName, String whereClause) {
        String selects = '';         
        if (whereClause == null || whereClause == '') { return null; }         
        
        // Get a map of field name and field token        
        Map<String, Schema.SObjectField> fMap = 
            Schema.getGlobalDescribe().get(objectName.toLowerCase()).getDescribe().Fields.getMap();        
        list<string> selectFields = new list<string>();         
        
        if (fMap != null) {            
            for (Schema.SObjectField ft : fMap.values()) { 
                // loop through all field tokens (ft)                
                Schema.DescribeFieldResult fd = ft.getDescribe(); 
                // describe each field (fd)     
                selectFields.add(fd.getName()); 
            }        
        }
        
        if (!selectFields.isEmpty()) {            
            for (string s:selectFields) {                
                selects += s + ',';           
            }            
            if (selects.endsWith(',')) {
                selects = selects.substring(0,selects.lastIndexOf(','));
            }         
        }         
        
        return 'SELECT ' + 'Owner.Name,' + selects + ' FROM ' + objectName + ' WHERE ' + whereClause;     
    }
    
    public static string getAllUpdateableFieldsSOQL(String objectName, String whereClause) {
        String selects = '';         
        if (whereClause == null || whereClause == '') { return null; }         
        
        // Get a map of field name and field token        
        Map<String, Schema.SObjectField> fMap = 
            Schema.getGlobalDescribe().get(objectName.toLowerCase()).getDescribe().Fields.getMap();        
        list<string> selectFields = new list<string>();         
        
        if (fMap != null) {            
            for (Schema.SObjectField ft : fMap.values()) { 
                // loop through all field tokens (ft)                
                Schema.DescribeFieldResult fd = ft.getDescribe();
                
                if (fd.isUpdateable()) { 
                    // field is updatable     
                    selectFields.add(fd.getName());
                } 
            }        
        }
        
        if (!selectFields.isEmpty()) {            
            for (string s:selectFields) {                
                selects += s + ',';           
            }            
            if (selects.endsWith(',')) {
                selects = selects.substring(0,selects.lastIndexOf(','));
            }         
        }         
        
        return 'SELECT ' + selects + ' FROM ' + objectName + ' WHERE ' + whereClause;     
    }
    
    public static List<string> getCreatableFields(String objectName) {
        // Get a map of field name and field token        
        Map<String, Schema.SObjectField> fMap = 
            Schema.getGlobalDescribe().get(objectName.toLowerCase()).getDescribe().Fields.getMap();        
        list<string> selectFields = new list<string>();         
        
        if (fMap != null) {            
            for (Schema.SObjectField ft : fMap.values()) { 
                // loop through all field tokens (ft)                
                Schema.DescribeFieldResult fd = ft.getDescribe(); 
                // describe each field (fd)   
                                 
                if (fd.isCreateable()) { 
                    // field is creatable                    
                    selectFields.add(fd.getName());                
                }            
            }        
        }
        
        return selectFields;      
    }
    
    public static List<string> getUpdateableFields(String objectName) {
        // Get a map of field name and field token        
        Map<String, Schema.SObjectField> fMap = 
            Schema.getGlobalDescribe().get(objectName.toLowerCase()).getDescribe().Fields.getMap();        
        list<string> selectFields = new list<string>();         
        
        if (fMap != null) {            
            for (Schema.SObjectField ft : fMap.values()) { 
                // loop through all field tokens (ft)                
                Schema.DescribeFieldResult fd = ft.getDescribe(); 
                // describe each field (fd)   
                                 
                if (fd.isUpdateable()) { 
                    // field is creatable                    
                    selectFields.add(fd.getName());                
                }            
            }        
        }
        
        return selectFields;      
    }
    
    
    public static List<string> getAllFields(String objectName) {
        // Get a map of field name and field token        
        Map<String, Schema.SObjectField> fMap = 
            Schema.getGlobalDescribe().get(objectName.toLowerCase()).getDescribe().Fields.getMap();        
        list<string> selectFields = new list<string>();         
        
        if (fMap != null) {            
            for (Schema.SObjectField ft : fMap.values()) { 
                // loop through all field tokens (ft)                
                Schema.DescribeFieldResult fd = ft.getDescribe(); 
                // describe each field (fd)   
                                  
                selectFields.add(fd.getName());                
                           
            }        
        }
        
        return selectFields;      
    }
    
    @isTest(seeAllData=true)
    private static void testgetCreatableFieldsSOQL(){
        String strQuery = getCreatableFieldsSOQL('Account','isDelete = false');
    }
    
    @isTest(seeAllData=true)
    private static void testgetAllFieldsSOQL(){
        String strQuery = getAllFieldsSOQL('Account', 'isDelete = false');
    }
    
    @isTest(seeAllData=true)
    private static void testgetAllUpdateableFieldsSOQL(){
        String strQuery = getAllUpdateableFieldsSOQL('Account', 'isDelete = false');
    }
    
    @isTest(seeAllData=true)
    private static void testgetCreatableFields(){
        List<String> fields = getCreatableFields('Account');
    }
    
    @isTest(seeAllData=true)
    private static void testgetUpdateableFields(){
        List<String> fields = getUpdateableFields('Account');
    }
    
    @isTest(seeAllData=true)
    private static void testgetAllFields(){
        List<String> fields = getAllFields('Account');
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
   
	/***********************************************************************
	* Looks up the Account based on the Profile ID passed in.
	*
	* ProfileId : PS_Profile_Services_ID__pc to search for.
	*
	* @author WEC bill.corrie@apollo.edu
	* @returns Account sObject
	***********************************************************************/
   public static Account findStudentAccountByProfile(String ProfileId)
   {

        list<Account> uniqueList;

		if( ProfileId != '' && ProfileId != null)
		{
        	uniqueList = [Select Id, PS_Profile_Services_ID__pc, Name From Account Where PS_Profile_Services_ID__pc = :ProfileId];
	        	
		}

     	if(uniqueList.size()==0)
      	{
      		throw new UtilityException('No Student Account found with Profile ID : ' + ProfileId);
      	}else if(uniqueList.size()>1)
      	{
      		throw new UtilityException('Multiple Student Accounts found with Profile ID : ' + ProfileId);
      	}
      	
      	return uniqueList[0];
   	
   } 

	/***********************************************************************
	* Looks up the Account based on the Profile ID passed in.
	*
	* ProfileId : Profile_Company_ID__c to search for.
	*
	* @author WEC bill.corrie@apollo.edu
	* @returns Account sObject
	***********************************************************************/
   public static Account findCompanyAccountByProfile(String ProfileId)
   {
        list<Account> uniqueList;

		if( ProfileId != '' && ProfileId != null)
		{
	        uniqueList = [Select Id, Profile_Company_ID__c, Name From Account Where Profile_Company_ID__c = :ProfileId];
		}

     	if(uniqueList.size()==0)
      	{
      		throw new UtilityException('No Company Account found with Profile ID : ' + ProfileId);
      	}else if(uniqueList.size()>1)
      	{
      		throw new UtilityException('Multiple Company Accounts found with Profile ID : ' + ProfileId);
      	}
      	
      	return uniqueList[0];
   	
   } 

	/***********************************************************************
	* Looks up the Faculty__c (Coach) based on the Profile ID passed in.
	*
	* ProfileId : Profile_Services_ID__c to search for.
	*
	* @author WEC bill.corrie@apollo.edu
	* @returns Faculty__c sObject
	***********************************************************************/
   public static Faculty__c findCoachFacultyByProfile(String ProfileId)
   {
        list<Faculty__c> uniqueList;

		if( ProfileId != '' && ProfileId != null)
		{
	        uniqueList = [Select Id, Profile_Services_ID__c, Name From Faculty__c Where Profile_Services_ID__c = :ProfileId];
		}

     	if(uniqueList.size()==0)
      	{
      		throw new UtilityException('No Coach found with Profile ID : ' + ProfileId);
      	}else if(uniqueList.size()>1)
      	{
      		throw new UtilityException('Multiple Coaches found with Profile ID : ' + ProfileId);
      	}
      	
      	return uniqueList[0];
   	
   } 
    
	/***********************************************************************
	* Looks up the Opportunity on an account based on the Order Number 
	* passed in.
	*
	* OppAccount : SFDC Id of Account to search on.
	* OrderNumber: Order Number to search for on the Opp.
	*
	* @author WEC bill.corrie@apollo.edu
	* @returns Opportunity sObject
	***********************************************************************/
   public static Opportunity findOppByOrderNumber(String OppAccount, String OrderNumber)
   {
        list<Opportunity> uniqueList;

		if( OrderNumber != '' && OrderNumber != null)
		{
	        uniqueList = [Select Id,Name From Opportunity Where Account.Id = :OppAccount and Order_Number__c = :OrderNumber];
		}

     	if(uniqueList.size()==0)
      	{
      		return null;
      	}else if(uniqueList.size()>1)
      	{
      		throw new UtilityException('Multiple Opportunities found with Order Number : ' + OrderNumber);
      	}
      	
      	return uniqueList[0];
   	
   } 
    
}