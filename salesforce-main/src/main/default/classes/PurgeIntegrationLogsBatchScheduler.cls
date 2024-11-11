/**********************************************************************
Name: PurgeIntegrationLogsBatchScheduler
Purpose: Scheduler for the Class 'PurgeOldIntegrationLogsBatch'                 
-------                                                             
History                                                             
-------                                                             
VERSION  AUTHOR             DATE              DETAIL                              
0.1 -   Prema Medasani     01/04/2019      INITIAL DEVELOPMENT  
***********************************************************************/
global class  PurgeIntegrationLogsBatchScheduler implements System.Schedulable 
{
   global void execute(SchedulableContext SC) 
   {
        PurgeOldIntegrationLogsBatch bat=new PurgeOldIntegrationLogsBatch();
        Database.executeBatch(bat); 
   }
}