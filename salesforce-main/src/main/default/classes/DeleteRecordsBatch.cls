global class DeleteRecordsBatch implements Database.Batchable<sObject>{

    global final String query;

    global DeleteRecordsBatch(String q) {
        query = q;
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC){
        return Database.getQueryLocator(query);
     }
  
     global void execute(Database.BatchableContext BC, List<sObject> scope){
       try {
          delete scope;
       } catch (Exception e) {
          System.debug(e.getMessage());
       }
     }
  
     global void finish(Database.BatchableContext BC){
     }
}