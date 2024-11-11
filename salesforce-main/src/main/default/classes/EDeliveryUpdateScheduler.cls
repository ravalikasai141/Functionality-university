/**********************************************************************
Name: DeliveryUpdateScheduler
Purpose: Scheduler for the Class 'EDeliveryUpdateBatch'                 
-------                                                             
History                                                             
-------                                                             
VERSION  AUTHOR             DATE              DETAIL                              
0.1 -   David Lovejoy     28/04/2021      INITIAL DEVELOPMENT  
***********************************************************************/
global class EDeliveryUpdateScheduler implements System.Schedulable {
    global void execute(SchedulableContext SC) {
        EDeliveryUpdateBatch bat = new EDeliveryUpdateBatch();
        Database.executeBatch(bat, 200); 
    }
}