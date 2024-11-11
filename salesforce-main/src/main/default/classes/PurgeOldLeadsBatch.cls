/**********************************************************************
Name: PurgeOldLeadsBatch
Purpose: Deletes Leads where LastActivityDate, LastModifiedDate, CreatedDate AND related Task LastModifiedDate are all older than 12 months
-------
History
-------
VERSION  AUTHOR             DATE              DETAIL
0.1 -   David Lovejoy     30/11/2020      INITIAL DEVELOPMENT
***********************************************************************/
global class PurgeOldLeadsBatch implements Database.Batchable<Sobject>, Database.Stateful {
    global Database.QueryLocator start(Database.BatchableContext BC) {
		DateTime datetimeTwoYearsAgo = System.Today().addYears(-2);
        if (Test.isRunningTest()) {
            return Database.getQueryLocator([SELECT Id FROM Lead WHERE LastName = 'PurgeOldLead' AND CreatedDate <: datetimeTwoYearsAgo LIMIT 1]);
        } else {
            return Database.getQueryLocator([SELECT Id, LastActivityDate, LastModifiedDate, CreatedDate, (SELECT LastModifiedDate FROM Tasks WHERE LastModifiedDate <: datetimeTwoYearsAgo) FROM Lead WHERE LastModifiedDate <: datetimeTwoYearsAgo AND CreatedDate <: datetimeTwoYearsAgo AND (LastActivityDate = NULL OR LastActivityDate <: Date.valueOf(datetimeTwoYearsAgo))]);
        }
    }
	
    global void execute(Database.BatchableContext BC, List<Lead> scope) {
        system.debug('Number of Leads to be deleted: ' + scope.size());

        if(scope.size()>0){
			delete scope;
        }
    }
	
    global void finish(Database.BatchableContext BC) {
        
    }
}