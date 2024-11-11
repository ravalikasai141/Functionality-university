public class StockAllocation {
    @InvocableMethod(label='Allocate Stock')
    public static List<StockAllocationHelper> getResult(List<String> idList) {
        List<StockAllocationHelper> resultList = allocateStock(idList);
        return resultList;
    }
    
    private static List<StockAllocationHelper> allocateStock(List<String> idList) {
        System.debug(idList);
        StockAllocationHelper response = new StockAllocationHelper();
        List<StockAllocationHelper> responseWrapper = new List<StockAllocationHelper>();
        List<Delivery__c> deliveryListToUpdate = new List<Delivery__c>();
        List<Stock_Management__c> stockManagementToUpdate = new List<Stock_Management__c>();
        Map<Delivery__c, Stock_Management__c> deliveryStockManagementMap = new Map<Delivery__c, Stock_Management__c>();

        try {
            deliveryStockManagementMap = DeliveryUtility.getStockAllocationRecords(idList);

            for (Delivery__c delivery : deliveryStockManagementMap.keyset()) {
                Stock_Management__c stockManagement = deliveryStockManagementMap.get(delivery);
                Decimal available = stockManagement.Available__c;
                Decimal allocated = stockManagement.Allocated__c;
                Decimal shortage = stockManagement.Shortage__c;
                Decimal quantity = delivery.Quantity__c;

                if (available > 0 && available >= quantity) {
                    delivery.Added_To_Shortage__c = FALSE;
                    delivery.Allocation_Date__c = System.now();
                    delivery.Delivery_Status__c = 'Ready for Fulfilment';
                    delivery.Stock_Allocated__c = TRUE;
                    allocated = allocated + quantity;
                    response.outputString = 'Success';
                } else {
                    if (delivery.Added_To_Shortage__c == FALSE) {
                        shortage = shortage + quantity;
                        delivery.Added_To_Shortage__c = TRUE;
                    }
                    response.outputString = 'Failure';
                }

                stockManagement.Allocated__c = allocated;
                stockManagement.Shortage__c = shortage;
                
                DeliveryUtility.updateDeliveryUpdateList(deliveryListToUpdate, delivery);
                DeliveryUtility.updateStockManagementUpdateList(stockManagementToUpdate, stockManagement);
                deliveryListToUpdate.add(delivery);
                stockManagementToUpdate.add(stockManagement);
                
                responseWrapper.add(response);
            }

            if (deliveryListToUpdate.size() > 0) {
                update deliveryListToUpdate;
            }

            if (stockManagementToUpdate.size() > 0) {
                update stockManagementToUpdate;
            }
        } catch (Exception e) {
            response.outputString = 'Error: [' + e.getLineNumber() + '] | ' + e.getMessage();
            responseWrapper.add(response);
        }

        System.debug(responseWrapper);
        return responseWrapper;
    }
}