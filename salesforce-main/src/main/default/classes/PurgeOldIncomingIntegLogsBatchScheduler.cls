/**********************************************************************
Name: PurgeOldIncomingIntegLogsBatchScheduler
Purpose: Scheduler for the Class 'PurgeOldIncomingIntegLogsBatch'                 
-------                                                             
History                                                             
-------                                                             
VERSION  AUTHOR             DATE              DETAIL                              
0.1 -   David Lovejoy     17/10/2019      INITIAL DEVELOPMENT  
***********************************************************************/
global class  PurgeOldIncomingIntegLogsBatchScheduler implements System.Schedulable 
{
   global void execute(SchedulableContext SC) 
   {
        PurgeOldIncomingIntegLogsBatch bat = new PurgeOldIncomingIntegLogsBatch();
        Database.executeBatch(bat); 
   }
}