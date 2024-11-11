/**********************************************************************
Name: DeliveryUpdateBatch
Purpose: Updates Delivery records (where Delivery_Status__c = 'Ready for Fulfilment') to 'Sent for Fulfillment'
-------                                                             
History                                                             
-------                                                             
VERSION  AUTHOR             DATE              DETAIL                              
0.1 -   David Lovejoy     19/01/2021      INITIAL DEVELOPMENT  
0.2 -   David Lovejoy     29/11/2021      BPP-15675
***********************************************************************/
global class DeliveryUpdateBatch implements Database.Batchable<Sobject>, Database.Stateful {
    List<String> saveErrors = new List<String>();
    private static String deliveryType = 'Physical Delivery';

    global Database.QueryLocator start(Database.BatchableContext BC) {
        String getFields = 'SELECT Fulfilment_Id__c, Name, Account__r.Name, Email__c, Phone__c, Recipient_Name__c, Consolidated_Address__c, City__c, Postal_Code__c, Country__c, Country__r.Name, Country_Code__c, Requested_Delivery_Date__c, BPP_Shipping_Method__c, Material_Product_Code__c, Quantity__c, EORI_Number__c, Stock_Site__r.Name, Id, BPP_Delivery_Line_Total_Price__c, Order_Product__r.ListPrice, Order_Product__r.BPP_Discount_Amount__c, Order_Product__r.BPP_Discount_Percent__c, BPP_Division__c, BPP_Cost_Center__c, BPP_Project__c, BPP_Product__c FROM Delivery__c';
        String whereClause = (Test.isRunningTest() ? ' WHERE Delivery_Status__c = \'Ready for Fulfilment\' LIMIT 1' : ' WHERE Delivery_Status__c = \'Ready for Fulfilment\' AND Stock_Allocated__c = TRUE AND RecordType.Name =: deliveryType LIMIT 49000');
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