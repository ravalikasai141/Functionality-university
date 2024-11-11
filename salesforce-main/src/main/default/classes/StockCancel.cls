public with sharing class StockCancel {
    @InvocableMethod(label='Cancel Stock')
    public static List<StockAllocationHelper> getResult(List<String> idList) {
        List<StockAllocationHelper> resultList = cancelStock(idList);
        return resultList;
    }
    
    private static List<StockAllocationHelper> cancelStock(List<String> idList) {
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
                Decimal shortage = stockManagement.Shortage__c;
                Decimal quantity = delivery.Quantity__c;

                shortage = shortage - quantity;
                stockManagement.Shortage__c = shortage;

                DeliveryUtility.updateStockManagementUpdateList(stockManagementToUpdate, stockManagement);
                stockManagementToUpdate.add(stockManagement);

                response.outputString = 'Success';
                responseWrapper.add(response);
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