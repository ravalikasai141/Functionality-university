/**********************************************************************
Name: PurgeOldTasksBatchScheduler
Purpose: Scheduler for the Class 'PurgeOldTasksBatch'                 
-------                                                             
History                                                             
-------                                                             
VERSION  AUTHOR             DATE              DETAIL                              
0.1 -   David Lovejoy     15/10/2019      INITIAL DEVELOPMENT  
***********************************************************************/
global class  PurgeOldTasksBatchScheduler implements System.Schedulable 
{
   global void execute(SchedulableContext SC) 
   {
        PurgeOldTasksBatch bat = new PurgeOldTasksBatch();
        Database.executeBatch(bat); 
   }
}