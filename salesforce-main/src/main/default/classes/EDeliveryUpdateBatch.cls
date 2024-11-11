/**********************************************************************
Name: EDeliveryUpdateBatch
Purpose: Updates E-Delivery records (where Delivery_Status__c = 'Ready for Fulfilment') to 'Sent for Fulfillment'
-------                                                             
History                                                             
-------                                                             
VERSION  AUTHOR             DATE              DETAIL                              
0.1 -   David Lovejoy     28/04/2021      INITIAL DEVELOPMENT  
0.2 -   David Lovejoy     29/11/2021      BPP-15675
***********************************************************************/
global class EDeliveryUpdateBatch implements Database.Batchable<Sobject>, Database.Stateful {
    List<String> saveErrors = new List<String>();
    private static String deliveryType = 'E-Delivery';

    global Database.QueryLocator start(Database.BatchableContext BC) {
        String getFields = 'SELECT Fulfilment_Id__c, Name, Id, Account__r.Name, Email__c, Material_Product_Code__c FROM Delivery__c';
        String whereClause = (Test.isRunningTest() ? ' WHERE Delivery_Status__c = \'Ready for Fulfilment\' LIMIT 1' : ' WHERE Delivery_Status__c = \'Ready for Fulfilment\' AND RecordType.Name =: deliveryType LIMIT 49000');
        String query = getFields + whereClause;

        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<Delivery__c> deliveryList) {
        System.debug('Delivery records to be updated: ' + deliveryList.size());

        if (deliveryList.size() > 0) {
            for (Delivery__c delivery : deliveryList) {
                delivery.Delivery_Status__c = 'Sent for Fulfilment';
            }
            saveErrors = DeliveryBatchHelper.updateDeliveryRecords(deliveryList);
        }
    }
    
    global void finish(Database.BatchableContext BC) {
        if (saveErrors.size() > 0) { 
            DeliveryBatchHelper.sendFailedDeliveryUpdateEmail(deliveryType, saveErrors);
        } else {
            DeliveryBatchHelper.sendFailedDeliveryUpdateEmail(deliveryType, null);
        }
    }
}