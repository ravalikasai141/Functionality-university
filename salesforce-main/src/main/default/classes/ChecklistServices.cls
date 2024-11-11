@RestResource(urlMapping='/v1.0/UpdateChecklist/*')
global with sharing class ChecklistServices {
    
    global class Response {
        global String status { get; set; }
        
        public Response(String status) {
            this.status = status;
        }
    }
    
    global class BNRRequest {
        public String applicationId;
        public List<ChecklistItem> checklistItems;
        public BNRRequest() {
            checklistItems = new List<ChecklistItem>();
        }
    }
    
    global class ChecklistItem {
        public string bannerCode;
        public date completionDate;
    }
    
    @HttpPost
    global static Response doPost() {
        RestRequest req = RestContext.request;
        String reqStr = req.requestBody.toString();
        system.debug(reqStr);
        //list<BNRRequest> checklistUpdates = (list<BNRRequest>)JSON.deserialize(reqStr, list<BNRRequest>.class);
		
		list<BNRRequest> checklistUpdates = new list<BNRRequest>();
		JSONParser parser = JSON.createParser(reqStr);
		while (parser.nextToken() != null) {
			System.debug('Current token: ' +
				parser.getCurrentToken());
			System.debug('Current name: ' +
				parser.getCurrentName());
			if (parser.getCurrentToken() == JSONToken.START_OBJECT){
				ChecklistServices.BNRRequest bnrReq = (ChecklistServices.BNRRequest)parser.readValueAs(ChecklistServices.BNRRequest.class);
				System.debug(bnrReq);
				checklistUpdates.add(bnrReq);
			}
		}
        
        return updateChecklist(checklistUpdates);
    }
    
    public static Response updateChecklist(List<BNRRequest> checklistUpdates) {
        Map<String, String> checklistFields = getChecklistFields();
        Set<String> bannerCodes = new Set<String>();
        for (BNRRequest req : checklistUpdates) {
        	for (ChecklistItem cli : req.checklistItems) {
        		bannerCodes.add(cli.bannerCode);
        	}
        }
        
        set<String> oppIds = new set<String>();
        for (BNRRequest request : checklistUpdates) {
            oppIds.add(request.applicationId);
        }
        
        String oppQueryStr = 'Select Id';
        for (String bannerCode : checklistFields.keySet()) {
        	String field = checklistFields.get(bannerCode);
        	if (bannerCodes.contains(bannerCode)) {
            	oppQueryStr += ', ' + field;
        	}
        }
        oppQueryStr += ' From Opportunity Where Id IN :oppIds';
        //oppQueryStr += ' From Opportunity Where Id IN (' + String.join(oppIds, ',') + ')';
        system.debug(oppQueryStr);
        List<Opportunity> oppList = Database.query(oppQueryStr);
        Map<String, Opportunity> oppMap = new Map<String, Opportunity>();
        for (Opportunity opp : oppList) {
            oppMap.put(((String)opp.Id).substring(0,15), opp);
        }
        
        List<String> appIdsNotFound = new List<String>();
        List<String> fieldsNotFound = new List<String>();
        List<Opportunity> UpdateOppty = new List<Opportunity>();
        map<Id, Opportunity> OpptyMap = new map<Id, Opportunity>();
        
        for (BNRRequest request : checklistUpdates) {
            Opportunity opp = oppMap.get(request.applicationId.substring(0,15));
            if (opp == null){
                appIdsNotFound.add(request.applicationId);
                continue;
            }
            for (ChecklistItem ci : request.checklistItems) {
                string field = checklistFields.get(ci.bannerCode.toUpperCase());
                if (field == null){
                    fieldsNotFound.add(ci.bannerCode.toUpperCase());
                    continue;
                }
                system.debug('Field' + field);
                system.debug('Opportunity Fields before update' + opp);
                opp.put(field, ci.completionDate);
                system.debug('Opportunity Fields after update' + opp);
            }
            OpptyMap.put(opp.Id, opp);
        }
        if (appIdsNotFound.size() > 0){
            WriteLog(checkListUpdates, appIdsNotFound, 'Failure: applicationId not found');
            return new Response('Failure');
        }
        if (fieldsNotFound.size() > 0){
            WriteLog(checkListUpdates, fieldsNotFound, 'Failure: checklistItems not found');
            return new Response('Failure');
        }
        for (Opportunity opp: oppList){
        	system.debug('OppList before update' + opp);
        }
        //system.debug('OpportunityList before update' + oppList);
        //update oppList;
        //system.debug('OpportunityList after update' + oppList);
        system.debug('OpptyMap Size' + OpptyMap.size());
        system.debug('OpptyMap Values' + OpptyMap.values());
        update OpptyMap.values();
        WriteLog(CheckListUpdates, null, 'Success');
        return new Response('Success');
    }
    
    public static Map<String, String> getChecklistFields() {
        String objectName = 'Opportunity';
        Map<String, Schema.SObjectField> fMap = 
            Schema.getGlobalDescribe().get(objectName).getDescribe().Fields.getMap();
        
        Map<String, String> checklistFields = new Map<String, String>();
        for (Schema.Sobjectfield field : fMap.values()) {
            Schema.DescribeFieldResult fd = field.getDescribe();
            if (fd.getName().contains('BNR_CHK')) {
                string bannerCode = fd.getName().substring(8,fd.getName().length() - 3);
                checklistFields.put(bannerCode, fd.getName());      
            }
        } 
        return checklistFields;
    }
    
    private static void writeLog(List<BNRRequest> checkListReq, List<String> listString, String Status){
        Integration_Log_Incoming__c log = new Integration_Log_Incoming__c();
        log.Request_Body__c = JSON.serialize(checkListReq);
        log.Request_Date__c = Datetime.now();
        log.Service_Name__c = 'ChecklistServices';
        
        String details = Status + ':\n';
        if (listString != null){
            for (String str : listString) {
                details += str + '\n';
            }
        }
        log.Details__c = details;
        insert log;
    }
}