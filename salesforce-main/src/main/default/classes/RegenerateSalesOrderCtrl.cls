public class RegenerateSalesOrderCtrl {
    @AuraEnabled
    public static string SalesOrder(Id recordId) { 
        System.debug('@RegenerateSalesOrderCtrl SalesOrder recordId: ' + recordId);
        String result;
        
        if(recordId != null) {
            result = CreateSalesOrder.SalesOrderInfo(recordId);
        } 
        return result; 
    }
}