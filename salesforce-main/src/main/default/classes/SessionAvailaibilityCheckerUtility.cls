/*
* @who   Patrick Duncan <patrick.duncan@weare4c.com>
* @what  Utility class for SessionAvailabilityChecker
* @when  14/1/2020
*/
public with sharing class SessionAvailaibilityCheckerUtility {

	private static List<String> bookingFieldsToIgnore = new List<String>{'Material_Price__c','Tuition_Price__c','LastModifiedDate','SystemModstamp', 'Count_of_Material_Lines__c'};

	/*
	*  @description    Method for building a map of session id -> Session
   	*  @param  deassignedSessionsAggregateMap  			Map of session id -> integer
   	*  @param  assignedSessionsAggregateMap  			Map of session id -> integer
   	*  @return    										Map of session id -> Session for all session ids in the parameters
	*/
	public static Map<Id,Session__c> getSessionMap(Map<Id,Integer> deassignedSessionsAggregateMap, Map<Id,Integer> assignedSessionsAggregateMap){
		return new Map<Id,Session__c>([SELECT Instance__c, Available__c, Booked__c FROM Session__c WHERE Id IN :deassignedSessionsAggregateMap.keySet() OR Id IN :assignedSessionsAggregateMap.keySet()]);
	}

	/*
	*  @description    Method for building a map of instance id -> instance
   	*  @param  instanceIds  			List of instance ids
   	*  @return    						Map of instance id -> instance 
	*/
	public static Map<Id,Instance__c> getInstanceMap(List<Id> instanceIds){
		return new Map<Id,Instance__c>([SELECT Id, Availability__c, Start_Date__c, Product__c, (SELECT Session_Product__c, Session_Date__c FROM Sessions__r) FROM Instance__c WHERE Id IN :instanceIds]);
	}

	/*
	*  @description    Method for building a map of order line id -> order line
   	*  @param  orderLineIds  			List of order line ids
   	*  @return    						Map of order line id -> order line 
	*/
	public static Map<Id,OrderItem> getOrderLineMap(List<Id> orderLineIds){
		return new Map<Id,OrderItem>([SELECT Product2Id, Family__c, SBQQ__RequiredBy__r.Product2Id FROM OrderItem WHERE Id IN :orderLineIds]);
	}

	/*
	*  @description    Method for building a map of booking id -> booking
   	*  @param  bookingIds  				List of booking ids
   	*  @return    						Map of booking id -> booking 
	*/
	public static Map<Id,Booking__c> getBookingMap(List<Id> bookingIds){
		return new Map<Id,Booking__c>([SELECT Booking_Confirmed_Date__c, CreatedDate, RecordTypeId, Status__c FROM Booking__c WHERE Id IN :bookingIds]);
	}

	/*
	*  @description    Method for building a map of booking line id -> booking line
   	*  @param  bookingLineIds  			Set of booking line ids
   	*  @return    						Map of booking line id -> booking line 
	*/
	public static Map<Id,Booking_Line__c> getBookingLineMap(Set<Id> bookingLineIds){
		return new Map<Id,Booking_Line__c>([SELECT Id FROM Booking_Line__c WHERE Id IN :bookingLineIds]);
	}

	/*
	*  @description Method for filtering a set of booking lines down to those whose bookings arent cancelled
   	*  @param  oldMap   		Old bookings lines before update
   	*  @return   				Set of filtered booking lines ids
	*/
	public static Set<Id> getBookingLineIdsWithoutCancelledBookings(Map<Id,Booking_Line__c> oldMap){
		return new Map<Id,Booking_Line__c>([SELECT Id FROM Booking_Line__c WHERE Id IN :oldMap.keySet() AND Booking__r.Booking_Cancelled__c = FALSE]).keySet();
	}

	/*
	*  @description Generic method for getting all elements in a map, whose key also appears in a set
   	*  @param  sobjectMap   	SObject map to be compared
   	*  @param  ids 				Set of ids to be compared
   	*  @return   				Map of union 
	*/
	public static Map<Id,SObject> getUnionOfSObjectMapAndSet(Map<Id,SObject> sobjectMap, Set<Id> ids){
		Map<Id,SObject> mapToReturn = new Map<Id,SObject>();
		for(Id sobjectId:ids){
			if(sobjectMap.containsKey(sobjectId)){
				mapToReturn.put(sobjectId, sobjectMap.get(sobjectId));
			}
		}
		return mapToReturn;
	}

	/*
	*  @description Generic method for getting all elements in a map which have been updated on a specific field
   	*  @param  oldMap   	Old map of SObjects before update
   	*  @param  newMap 		New map of SObjects after update
   	*  @param  fieldName 	Api name of field
   	*  @return   			Set of record ids which have been updated on field
	*/
	public static Set<Id> filterSObjectsOnUpdatedField(Map<Id,SObject> oldMap, Map<Id,SObject> newMap, String fieldName){
		Set<Id> filteredSobjectIds = new Set<Id>();
		for(Id id:oldMap.keySet()){
			if(oldMap.get(id).get(fieldName) != newMap.get(id).get(fieldName)){
				filteredSobjectIds.add(id);
			}
		}
		return filteredSobjectIds;
	}

	/*
	*  @description Method to prevent recursive trigger on booking by ignoring updates to rollup fields by comparing whether there is an update on a non-ignored field
   	*  @param  oldMap   	Old map of SObjects before update
   	*  @param  newMap 		New map of SObjects after update
   	*  @return   			Flag whether any of the updated fields are not in the ignore list (whether its a real update)
	*/
	public static Boolean isRealBookingUpdate(Map<Id,SObject> oldMap, Map<Id,SObject> newMap){
		Boolean realUpdate = false;
		Set<String> updatedBookingFields = getUpdatedSObjectFields(oldMap, newMap, 'Booking__c');
		for(String field:updatedBookingFields){
			if(!bookingFieldsToIgnore.contains(field)){
				System.debug('Updated field that is not ignored: ' + field);
				realUpdate = true;
				break;
			}
		}
		return realUpdate;
	}

	/*
	*  @description Generic method to get the api name of all fields which have been updated between old and new map of SObjects
   	*  @param  oldMap   	Old map of SObjects before update
   	*  @param  newMap 		New map of SObjects after update
   	*  @param  sobjectName 	Api name of SObject
   	*  @return   			Set of field api names which have been updated
	*/
	private static Set<String> getUpdatedSObjectFields(Map<Id,SObject> oldMap, Map<Id,SObject> newMap, String sobjectName){
		SObjectType bookingType = Schema.getGlobalDescribe().get(sobjectName);
		Map<String,Schema.SObjectField> mfields = bookingType.getDescribe().fields.getMap();
		Set<String> updatedSObjectFields = new Set<String>();
		for(Id sobjectId:oldMap.keySet()){
			for(String key:mfields.keyset()){
				Schema.SObjectField field =  mfields.get(key);
				if(oldMap.get(sobjectId).get(field) != newMap.get(sobjectId).get(field)){
					updatedSObjectFields.add(field.getDescribe().getName());
				}
			}
		}
		return updatedSObjectFields;
	}

	/*
	*  @description Generic method to get all sobjects whose field has been set to cancelled
   	*  @param  oldMap   	Old map of SObjects before update
   	*  @param  newMap 		New map of SObjects after update
   	*  @param  fieldName 	Api name of field to look at
   	*  @return   			Set of ids of sobjects whose field has been set to cancelled
	*/
	public static Set<Id> getCancelledSObjectIds(Map<Id,SObject> oldMap, Map<Id,SObject> newMap, String fieldName){
		Set<Id> sobjectIds = new Set<Id>();
		for(Id sobjectId:oldMap.keySet()){
			if(oldMap.get(sobjectId).get(fieldName) != 'Cancelled' && newMap.get(sobjectId).get(fieldName) == 'Cancelled'){
				sobjectIds.add(sobjectId);
			}
		}
		return sobjectIds;
	}

	/*
	*  @description Generic method to get all sobjects whose field has been updated from cancelled to another value
   	*  @param  oldMap   	Old map of SObjects before update
   	*  @param  newMap 		New map of SObjects after update
   	*  @param  fieldName 	Api name of field to look at
   	*  @return   			Set of ids of sobjects whose field has been updated from cancelled to another value
	*/
	public static Set<Id> getUncancelledSObjectIds(Map<Id,SObject> oldMap, Map<Id,SObject> newMap, String fieldName){
		Set<Id> sobjectIds = new Set<Id>();
		for(Id sobjectId:oldMap.keySet()){
			if(oldMap.get(sobjectId).get(fieldName) == 'Cancelled' && newMap.get(sobjectId).get(fieldName) != 'Cancelled'){
				sobjectIds.add(sobjectId);
			}
		}
		return sobjectIds;
	}

	/*
	*  @description Generic method to get all sobjects whose field is not equal to cancelled before or after update
   	*  @param  oldMap   	Old map of SObjects before update
   	*  @param  newMap 		New map of SObjects after update
   	*  @param  fieldName 	Api name of field to look at
   	*  @return   			Set of ids of sobjects whose field is not equal to cancelled before or after update
	*/
	public static Set<Id> getActiveSObjectIds(Map<Id,SObject> oldMap, Map<Id,SObject> newMap, String fieldName){
		Set<Id> sobjectIds = new Set<Id>();
		for(Id sobjectId:oldMap.keySet()){
			if(oldMap.get(sobjectId).get(fieldName) != 'Cancelled' || newMap.get(sobjectId).get(fieldName) != 'Cancelled'){
				sobjectIds.add(sobjectId);
			}
		}
		return sobjectIds;
	}

	/*
	*  @description Generic method for getting all SObjects in a list whose id also exists in a set of ids
   	*  @param  sobjects  	List of SObjects
   	*  @param  sobjectIds   Set of SObject ids
   	*  @return    			List of SObjects which are in both list & set
	*/
	public static List<SObject> getSObjectsInIdSet(List<SObject> sobjects, Set<Id> sobjectIds){
		List<SObject> sobjectsToReturn = new List<SObject>();
		if(sobjectIds == null){
			sobjectsToReturn = sobjects;
		}
		else{
			for(Id sobjectId:sobjectIds){
				for(SObject obj:sobjects){
					if(sobjectId == obj.Id){
						sobjectsToReturn.add(obj);
					}
				}
			}
		}
		return sobjectsToReturn;
	}

	/*
	*  @description  Generic Method for creating map of sobject id to lookup id or vise versa
   	*  @param  sobjects  			SObjects to get id and lookup from
   	*  @param  fieldName   			Lookup field api name
	*  @param  sObjectIdAsKey   	Boolean flag if true, map is sobject id to lookup id otherwise, vise versa
   	*  @return    					Map id -> id
	*/
	public static Map<Id,Id> createSObjectIdFieldValueMap(List<SObject> sobjects, String fieldName, Boolean sObjectIdAsKey){
		Map<Id,Id> sObjectToFieldValueMap = new Map<Id,Id>();
		for(SObject obj:sobjects){
			if(sobjectIdAsKey){
				sObjectToFieldValueMap.put((Id) obj.get('Id'), (Id) obj.get(fieldName));
			}
			else{
				sObjectToFieldValueMap.put((Id) obj.get(fieldName),(Id) obj.get('Id'));
			}
		}
		return sObjectToFieldValueMap;
	}

	/*
	*  @description  Generic method for creating map of lookup id to sobject
   	*  @param  sobjects  			SObjects to get sobject and lookup from
   	*  @param  fieldName   			Lookup field api name
   	*  @return    					Map id -> SObject
	*/
	public static Map<Id,SObject> createIdToSObjectMap(List<SObject> objects, String fieldName){
		Map<Id,SObject> idToSObjectMap = new Map<Id,SObject>();
		for(SObject obj:objects){
			idToSObjectMap.put((Id) obj.get(fieldName), obj);
		}
		return idToSObjectMap;
	}
}