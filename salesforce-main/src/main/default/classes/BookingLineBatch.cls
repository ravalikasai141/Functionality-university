public class BookingLineBatch implements Schedulable, Database.Batchable<sObject>, Database.Stateful {
    private Map<String, String> fieldMapping = new Map<String, String>{
        'Id'                        => 'Booking_Line__c',
            'blng_Account__c'           => 'blng__Account__c',
            'blng_Order__c'             => 'blng__Order__c',
            'blng_OrderProduct__c'      => 'blng__OrderProduct__c',
            'blng_MatchingId__c'        => 'blng__MatchingId__c',
            'blng_StartDateTime__c'     => 'blng__StartDateTime__c',
            'blng_EndDateTime__c'       => 'blng__EndDateTime__c',
            'Booking__c'                => 'Booking__c',
            'Student__c'                => 'Student__c',
            'Instance__c'               => 'Instance__c',
            'Session__c'                => 'Session__c',
            'Rev_Rec_Date__c'           => 'Rev_Rec_Date__c',
            'PO_Number__c'              => 'PO_Number__c',
            'Booking__r.OwnerId'        => 'OwnerId'
            };
                private String objectName = 'Booking_Line__c';
    private String query;
    private String dateFieldName = 'blng_StartDateTime__c';
    private String boolField = 'Batch_Processed__c';
    private String statusField = 'On_Hold__c';
    private String statusValue = 'Cancelled';
    private Map<Id, List<String>> userIdToErrors;
    
    private String processName = Label.BATCH_Process_Name;
    private String errorMessageHeader = Label.BATCH_Error_Message_header;
    private String errorMessageLine = Label.BATCH_Error_Message;
    private String errorMessageNoReply = Label.BATCH_Error_no_reply;
    
    public BookingLineBatch() {
        this.userIdToErrors = new Map<Id, List<String>>();
        String whereClause = buildWhereClause('blng_StartDateTime__c', boolField, this.statusField, this.statusValue);
        this.query = buildQueryString(fieldMapping.keySet(), this.objectName, whereClause);
        System.debug(query);
    }
    
    public BookingLineBatch(String dateFieldName, String boolField, String statusField, String statusValue) {
        this.userIdToErrors = new Map<Id, List<String>>();
        this.dateFieldName = dateFieldName != null ? dateFieldName : this.dateFieldName;
        this.boolField = boolField != null ? boolField : this.boolField;
        this.statusField = statusField != null ? statusField : this.statusField;
        this.statusValue = statusValue != null ? statusValue : this.statusValue;
        String whereClause = buildWhereClause(this.dateFieldName, this.boolField, this.statusField, this.statusValue);
        this.query = buildQueryString(fieldMapping.keySet(), this.objectName, whereClause);
        System.debug(this.query);
    }
    
    private String buildWhereClause(String dateFieldName, String boolField, String statusField, String statusValue) {
        //Datetime dateToCalc = Date.today().addDays(-numOfDays);
        //String formattedDateTime = dateToCalc.format('yyyy-MM-dd\'T\'hh:mm:ss\'Z\'');
        statusValue = '\'' + statusValue + '\'';
        return String.format(
            '{0} = TODAY AND {1} = FALSE AND {2} != {3}', 
            new List<String>{dateFieldName, boolField, statusField, statusValue}
        );
    }
    
    private String buildQueryString(Set<String> fieldNames, String objectName, String whereClause) {
        String queryString = String.format(
            'SELECT {0} FROM {1}', 
            new List<String>{
                String.join(new List<String>(fieldMapping.keySet()), ','),
                    this.objectName
                    }
        );
        return queryString + ' WHERE ' + whereClause;
    }
    
    public void execute(SchedulableContext SC) {
        Database.executeBatch(this);
    }
    
    public static String cronBuilder(Datetime dateToStart) {
        return dateToStart.second() + ' '
            + dateToStart.minute() + ' '
            + dateToStart.hour() + ' '
            + dateToStart.day() + ' '
            + dateToStart.month() + ' '
            + '? '
            + dateToStart.year();
    }
    
    public Database.QueryLocator start(Database.BatchableContext BC){
        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext BC, List<sObject> scope){
        List<sObject> recordsToInsert = new List<sObject>();
        for(sObject sobj : scope) {
            blng__Usage__c usage = new blng__Usage__c();
            for(String bookingLineField : fieldMapping.keySet()) {
                Object fieldValue   = bookingLineField.contains('.') 
                    ? getParentFieldValue(sobj, bookingLineField) 
                    : sobj.get(bookingLineField);
                
                usage.put(fieldMapping.get(bookingLineField), fieldValue);
            }
            usage.put('blng__Quantity__c',1);
            recordsToInsert.add(usage);
            sobj.put(boolField, true);
        }
        try{
            insert recordsToInsert;
        } catch (DmlException e) {
            System.debug('Error is ' + e.getCause() + e.getMessage());
        }
        
        List<Database.SaveResult> saveResults = Database.insert(recordsToInsert, false);
        Map<Id, List<String>> errorsMap = processSaveResults(saveResults, scope);
        mergeErrors(this.userIdToErrors, errorsMap);
        saveResults = Database.update(scope, false);
        errorsMap = processSaveResults(saveResults, recordsToInsert);
        mergeErrors(this.userIdToErrors, errorsMap);
    }
    
    private Object getParentFieldValue(SObject inputSObject,String fieldName){
        if(inputSObject != null) {
            if (fieldName.contains('.')) {
                String nextFieldOrRelation = fieldName.substringAfter('.');
                String parentSObject = fieldName.substringBefore('.');
                return getParentFieldValue((SObject)inputSObject.getSObject(parentSObject), nextFieldOrRelation);
            } else {
                return inputSObject.get(fieldName);
            }
        }else {
            return null;
        }
    }
    
    private Map<Id, List<String>> processSaveResults(List<Database.SaveResult> saveResults, List<sObject> records) {
        Map<Id, List<String>> userIdToErrors = new Map<Id, List<String>>();
        for(Integer i=0; i<saveResults.size(); i++) {
            Database.SaveResult result = saveResults[i];
            if(!result.isSuccess()) {
                List<Database.Error> errors = result.getErrors();
                sObject originalRecord = records[i];
                Id userId = (Id) getParentFieldValue(originalRecord, 'Booking__r.OwnerId');
                String recordId = originalRecord.Id;
                List<String> errorMessages = new List<String>();
                for(Database.Error err : errors) {
                    errorMessages.add(
                        buildSingleErrorMessage(recordId, err.getMessage())
                    );
                }
                if(!userIdToErrors.containsKey(userId)) {
                    userIdToErrors.put(userId, new List<String>());
                }
                userIdToErrors.get(userId).addAll(errorMessages);
            }
        }
        return userIdToErrors;
    }
    
    private String buildSingleErrorMessage(Id recordId, String errorMessage) {
        return String.format(this.errorMessageLine, new List<String>{recordId, errorMessage});
    }
    
    private Map<Id, List<String>> mergeErrors(Map<Id, List<String>> targetMap, Map<Id, List<String>> newMap) {
        for(Id userId : newMap.keySet()) {
            if(!targetMap.containsKey(userId)) {
                targetMap.put(userId, new List<String>()); 
            }
            targetMap.get(userId).addAll(newMap.get(userId));
        }
        return targetMap;
    }
    
    private Map<Id, String> buildUserIdToErrorMessageMap(Map<Id, List<String>> userIdToErrors) {
        Map<Id, String> userIdToErrorMessageMap = new Map<Id, String>();
        for(Id userId : userIdToErrors.keySet()) {
            String message = String.format(this.errorMessageHeader, new List<String>{processName});
            message += '\n';
            for(String error : userIdToErrors.get(userId)) {
                message += error;
            }
            message += '\n';
            message += this.errorMessageNoReply;
            userIdToErrorMessageMap.put(userId, message);
        }
        return userIdToErrorMessageMap;
    }
    
    public void finish(Database.BatchableContext BC){
        Map<Id, String> userIdToErrorMessageMap = buildUserIdToErrorMessageMap(this.userIdToErrors);
        EmailUtils.sendEmailToUsers(userIdToErrorMessageMap, this.processName);
    }
    
    
}