/**********************************************************************
Name: PurgeOldTasksBatchSchedulerTest
Purpose: Test Class for the Scheduler Class 'PurgeTasksBatchScheduler'                 
-------                                                             
History                                                             
-------                                                             
VERSION  AUTHOR             DATE              DETAIL                              
0.1 -   David Lovejoy     15/10/2019      INITIAL DEVELOPMENT  
***********************************************************************/
@isTest
public class PurgeOldTasksBatchSchedulerTest
{
   public static testmethod void execute() 
   {
      String CRON_EXP = '0 0 0 3 9 ? 2025';
      system.schedule('Scheduleclass',CRON_EXP,new PurgeOldTasksBatchScheduler());
   }
}