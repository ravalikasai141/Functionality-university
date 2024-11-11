/*
* @who   Patrick Duncan <patrick.duncan@weare4c.com>
* @what  Utility class for generic sobject filtering methods
* @when  29/1/2020
*/
public with sharing class SObjectUtil {

	/*
	*  @description    Generic Method getting a set of values of a field for a list of sobjects
   	*  @param  sobjects  	List of SObjects
   	*  @param  fieldName  	Api name of field
	*/
	public static List<Object> getFieldValuesFromSObjectList(List<SObject> sobjects, String fieldName){
		Set<String> idSet = new Set<String>();
		for(SObject sObj:sobjects){
			idSet.add((String) sObj.get(fieldName));
		}
		return new List<String>(idSet);
	}
    
    public static Map<String,String> getFieldValuesFromSObjectMap(List<SObject> sobjects, String fieldName,String RecordTypeId){
        Map<String,String> idMap = new Map<String,String>();
        for(SObject sObj:sobjects){
            idMap.put((String) sObj.get(fieldName),(String) sObj.get(RecordTypeId));
        }
        return new Map<String,String>(idMap);
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
	*  @description Generic method to get the api name of all fields which have been updated between old and new map of SObjects
   	*  @param  oldMap   	Old map of SObjects before update
   	*  @param  newMap 		New map of SObjects after update
   	*  @param  sobjectName 	Api name of SObject
   	*  @return   			Set of field api names which have been updated
	*/
	public static Set<String> getUpdatedSObjectFields(Map<Id,SObject> oldMap, Map<Id,SObject> newMap, String sobjectName){
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
	*  @description  Generic Method for creating map of one sobject lookup field to another lookup field
   	*  @param  sobjects  			SObjects to get id and lookup from
   	*  @param  fromFieldName   		Lookup field id for map key
	*  @param  toFieldName   		Lookup field id for map value
   	*  @return    					Map id -> id
	*/
	public static Map<Id,Id> createSObjectFieldValuesMap(List<SObject> sobjects, String fromFieldName, String toFieldName){
		Map<Id,Id> sObjectFieldValuesMap = new Map<Id,Id>();
		for(SObject obj:sobjects){
			sObjectFieldValuesMap.put((Id) obj.get(fromFieldName), (Id) obj.get(toFieldName));
		}
		return sObjectFieldValuesMap;
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

	public static Map<SObject,SObject> createSObjectLookupMap(Map<Id,SObject> fromObjectMap, Map<Id,SObject> toObjectMap, String lookupField){
		Map<SObject,SObject> sObjectLookupMap = new Map<SObject,SObject>();
		for(SObject fromObject:fromObjectMap.values()){
			sObjectLookupMap.put(fromObject, toObjectMap.get((Id) fromObject.get(lookupField)));
		}
		return sObjectLookupMap;
	}
    
}