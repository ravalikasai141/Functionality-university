/**********************************************************************
Name: PurgeOldLeadsBatchSchedulerTest
Purpose: Test Class for the Scheduler Class 'PurgeLeadsBatchScheduler'
-------
History
-------
VERSION  AUTHOR             DATE              DETAIL
0.1 -   David Lovejoy     02/12/2020      INITIAL DEVELOPMENT
***********************************************************************/
@isTest
public class PurgeOldLeadsBatchSchedulerTest{
	public static testmethod void execute() {
		String CRON_EXP = '0 0 0 3 9 ? 2025';
		system.schedule('Scheduleclass', CRON_EXP, new PurgeOldLeadsBatchScheduler());
	}
}