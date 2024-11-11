/**********************************************************************
Name: PurgeOldTasksBatch
Purpose: Deletes Tasks that are older than 12 months                 
-------                                                             
History                                                             
-------                                                             
VERSION  AUTHOR             DATE              DETAIL                              
0.1 -   David Lovejoy     15/10/2019      INITIAL DEVELOPMENT  
***********************************************************************/
global class PurgeOldTasksBatch implements Database.Batchable<Sobject>, Database.Stateful
{
    global Database.QueryLocator start(Database.BatchableContext BC)
    {
        if(Test.isRunningTest()){
            return Database.getQueryLocator([SELECT Id FROM Task LIMIT 1]);
        } else {
            return Database.getQueryLocator([SELECT Id FROM Task WHERE LastModifiedDate < LAST_N_MONTHS:12 LIMIT 49000]);
        }
    }
    global void execute(Database.BatchableContext BC, List<Task> scope)
    {
        system.debug('scope items are'+scope);

        if(scope.size()>0){
			delete scope;
        }
        
    }
    global void finish(Database.BatchableContext BC)
    {
        
    }
}