/**********************************************************************
Name: PurgeOldLeadsBatchScheduler
Purpose: Scheduler for the Class 'PurgeOldLeadsBatch'
-------
History
-------
VERSION  AUTHOR             DATE              DETAIL
0.1 -   David Lovejoy     02/12/2020      INITIAL DEVELOPMENT
***********************************************************************/
global class  PurgeOldLeadsBatchScheduler implements System.Schedulable {
   global void execute(SchedulableContext SC) {
        PurgeOldLeadsBatch bat = new PurgeOldLeadsBatch();
        Database.executeBatch(bat);
   }
}