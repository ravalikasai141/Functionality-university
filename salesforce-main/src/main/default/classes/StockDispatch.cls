public class StockDispatch {
    @InvocableMethod(label='Dispatch Stock')
    public static List<StockAllocationHelper> getResult(List<String> idList) {
        List<StockAllocationHelper> resultList = dispatchStock(idList);
        return resultList;
    }
    
    private static List<StockAllocationHelper> dispatchStock(List<String> idList) {
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
                Decimal allocated = stockManagement.Allocated__c;
                Decimal total = stockManagement.Total__c;
                Decimal quantity = delivery.Quantity__c;

                delivery.Stock_Management__c = NULL;
                delivery.Stock_Allocated__c = FALSE;
                allocated = allocated - quantity;
                total = total - quantity;
                stockManagement.Allocated__c = allocated;
                stockManagement.Total__c = total;

                DeliveryUtility.updateDeliveryUpdateList(deliveryListToUpdate, delivery);
                DeliveryUtility.updateStockManagementUpdateList(stockManagementToUpdate, stockManagement);
                deliveryListToUpdate.add(delivery);
                stockManagementToUpdate.add(stockManagement);

                response.outputString = 'Success';
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