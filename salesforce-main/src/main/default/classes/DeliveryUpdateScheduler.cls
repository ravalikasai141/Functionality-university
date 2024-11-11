/**********************************************************************
Name: DeliveryUpdateScheduler
Purpose: Scheduler for the Class 'DeliveryUpdateBatch'                 
-------                                                             
History                                                             
-------                                                             
VERSION  AUTHOR             DATE              DETAIL                              
0.1 -   David Lovejoy     19/01/2021      INITIAL DEVELOPMENT  
***********************************************************************/
global class DeliveryUpdateScheduler implements System.Schedulable {
    global void execute(SchedulableContext SC) {
        DeliveryUpdateBatch bat = new DeliveryUpdateBatch();
        Database.executeBatch(bat, 200); 
    }
}