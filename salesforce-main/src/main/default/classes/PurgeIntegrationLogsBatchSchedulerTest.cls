/**********************************************************************
Name: PurgeIntegrationLogsBatchSchedulerTest
Purpose: Test Class for the Scheduler Class 'PurgeIntegrationLogsBatchScheduler'                 
-------                                                             
History                                                             
-------                                                             
VERSION  AUTHOR             DATE              DETAIL                              
0.1 -   Prema Medasani     01/04/2019      INITIAL DEVELOPMENT  
***********************************************************************/
@isTest
Public class PurgeIntegrationLogsBatchSchedulerTest
{
   public static testmethod void execute() 
   {
      String CRON_EXP = '0 0 0 3 9 ? 2025';
      system.schedule('Scheduleclass',CRON_EXP,new PurgeIntegrationLogsBatchScheduler());

   }
}