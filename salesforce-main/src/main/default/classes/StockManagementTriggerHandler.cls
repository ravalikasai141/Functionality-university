public with sharing class StockManagementTriggerHandler {
    public static void handleAfterUpdate(Map<Id, Stock_Management__c> oldStockManagementMap, List<Stock_Management__c> stockManagementList) {
        Set<Id> stockManagementIds = new Set<Id>();
        List<Stock_Management__c> stockManagementListToProcess = new List<Stock_Management__c>();
        Map<Stock_Management__c, List<Delivery__c>> stockManagementDeliveryMap = new Map<Stock_Management__c, List<Delivery__c>>();

        for (Stock_Management__c stockManagement : stockManagementList) {
            Stock_Management__c oldStockManagement = oldStockManagementMap.get(stockManagement.Id);
            if (stockManagement.Total__c > oldStockManagement.Total__c) {
                stockManagementIds.add(stockManagement.Id);
                stockManagementListToProcess.add(stockManagement);
            }
        }

        if (stockManagementIds.size() > 0 && stockManagementListToProcess.size() > 0) {
            List<Delivery__c> deliveryList = [SELECT Id, Stock_Management__c, Allocation_Attempts__c, Added_To_Shortage__c, Quantity__c FROM Delivery__c WHERE Stock_Management__c IN: stockManagementIds AND Delivery_Status__c = 'Awaiting Allocation' ORDER BY Awaiting_Allocation_Date__c];
            for (Stock_Management__c stockManagement : stockManagementListToProcess) {
                List<Delivery__c> deliveryListToProcess = new List<Delivery__c>();
                for (Delivery__c delivery : deliveryList) {
                    if (delivery.Stock_Management__c == stockManagement.Id) {
                        deliveryListToProcess.add(delivery);                
                    }
                }
                stockManagementDeliveryMap.put(stockManagement, deliveryListToProcess);
            }

            if (!stockManagementDeliveryMap.isEmpty()) {
                DeliveryUtility.allocateStock(stockManagementDeliveryMap);
            }
        }
    }
}