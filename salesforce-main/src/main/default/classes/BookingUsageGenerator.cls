public with sharing class BookingUsageGenerator {
    public static Boolean executed = false;
    public class GenerationResult {
        public List<Database.SaveResult> bookingUsageSaveResults;
        public List<Database.SaveResult> bookingLinesSaveResults;
        public List<sObject> bookingUsageGenerated;
        public List<sObject> bookingLineScope;
    }
    
    public static GenerationResult generateUsages(List<sObject> bookingLineScope) {
        if (executed) return null;
        
        GenerationResult result = new GenerationResult(); 
        result.bookingUsageGenerated = new List<sObject>();
        result.bookingLineScope = bookingLineScope;
        
        for (sObject sobj : result.bookingLineScope) {
            blng__Usage__c usage = new blng__Usage__c();
            for (String bookingLineField : BookingUsageBatch.fieldMapping.keySet()) {
                Object fieldValue   = bookingLineField.contains('.') 
                                    ? getParentFieldValue(sobj, bookingLineField) 
                                    : sobj.get(bookingLineField);
            
                usage.put(BookingUsageBatch.fieldMapping.get(bookingLineField), fieldValue);
            }
            usage.put('blng__Quantity__c',1);
            result.bookingUsageGenerated.add(usage);
            sobj.put('Batch_Processed__c', true); 
        }
        result.bookingUsageSaveResults = Database.insert(result.bookingUsageGenerated, false);
        
        for (Database.SaveResult sr : result.bookingUsageSaveResults) {
            if (sr.isSuccess()) {
                System.debug('@BookingUsageGenerator Successfully inserted Usages IDs are: ' + sr.getId());
            } else {            
                for (Database.Error err : sr.getErrors()) {
                    System.debug('@BookingUsageGenerator The following error has occurred: ' + err.getStatusCode() + ': ' + err.getMessage() + '\nUsage fields that affected this error: ' + err.getFields());                    
                }
            }
        }
        
        //Process Save Result to Update the booking Line 
        result.bookingLineScope = processSaveResult(result.bookingUsageSaveResults,result.bookingLineScope);
        result.bookingLinesSaveResults = Database.update(result.bookingLineScope, false);
        
        System.debug('bookingLineScope (size : '+result.bookingLineScope.size()+') : ' + result.bookingLineScope);
        System.debug('bookingLinesSaveResults (size : '+ (result.bookingLinesSaveResults != null ? String.valueOf(result.bookingLinesSaveResults.size()) : '0' ) +') : ' + result.bookingLinesSaveResults);
        System.debug('bookingUsageGenerated (size : '+result.bookingUsageGenerated.size()+') : ' + result.bookingUsageGenerated);
        System.debug('bookingUsageSaveResults (size : '+result.bookingUsageSaveResults.size()+') : ' + result.bookingUsageSaveResults);
        
        executed = true;
        return result;
    }
    
    private static Object getParentFieldValue(SObject inputSObject,String fieldName) {
        if(inputSObject != null)  {
            if (fieldName.contains('.')) {
                String nextFieldOrRelation = fieldName.substringAfter('.');
                String parentSObject = fieldName.substringBefore('.');
                return getParentFieldValue((SObject)inputSObject.getSObject(parentSObject), nextFieldOrRelation);
            } else {
                return inputSObject.get(fieldName);
            }
        } else {
            return null;
        }
    }
    
    private static List<sObject> processSaveResult(List<Database.SaveResult> bookingUsageSaveResults, List<sObject> bookingLineScope) {
        for (Integer i=0;i < bookingUsageSaveResults.size();i++) {
            if (bookingUsageSaveResults[i].isSuccess()) {
                bookingLineScope[i].put('Batch_failed__c',false);
                bookingLineScope[i].put('Batch_failure_date__c',null);
            } else {
                if (bookingUsageSaveResults[i].getErrors().size() > 0) {
                	bookingLineScope[i].put('Usage_Failure_Reason__c',bookingUsageSaveResults[i].getErrors()[0].getMessage());    
                }
                bookingLineScope[i].put('Batch_failed__c',true);
                bookingLineScope[i].put('Batch_failure_date__c',date.today());
            }
        }
        return bookingLineScope;
    }
}