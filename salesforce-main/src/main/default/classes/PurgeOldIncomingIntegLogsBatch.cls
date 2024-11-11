/**********************************************************************
Name: PurgeOldIncomingIntegLogsBatch
Purpose: Deletes Incoming Integration Logs that are older than 6 months                
-------                                                             
History                                                             
-------                                                             
VERSION  AUTHOR             DATE              DETAIL                              
0.1 -   David Lovejoy     17/10/2019      INITIAL DEVELOPMENT  
0.2 -   David Lovejoy     13/05/2021      UPDATE  
0.3 -   David Lovejoy     14/02/2022      UPDATE FOR BPP-19585  
***********************************************************************/
global class PurgeOldIncomingIntegLogsBatch implements Database.Batchable<Sobject>, Database.Stateful {
    global Database.QueryLocator start(Database.BatchableContext BC) {
        DateTime todaysDateMinusThreeMonths = System.today().addMonths(-3);
        String getFields = 'SELECT Id FROM Integration_Log_Incoming__c';
        String whereClause = (Test.isRunningTest() ? ' LIMIT 1' : ' WHERE CreatedDate <: todaysDateMinusThreeMonths LIMIT 49000');
        String query = getFields + whereClause;
        return Database.getQueryLocator(query);
    }
    global void execute(Database.BatchableContext BC, List<Integration_Log_Incoming__c> scope) {
        System.debug('Scope items are: ' + scope);
        if (scope.size() > 0) {
			delete scope;
        }
    }
    global void finish(Database.BatchableContext BC){}
}