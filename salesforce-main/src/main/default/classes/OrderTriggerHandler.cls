/*
* Who - Patrick Duncan <patrick.duncan@weare4c.com> 
* What - Handler class for OrderTrigger
* When - 6/8/20
*/
public class OrderTriggerHandler {
    public static void handleBeforeInsert(Map<Id,Order> newMap, List<Order> orderList){
        OrderHelper.updateOrderAddress(orderList);    
    }
    
    public static void handleBeforeUpdate(Map<Id,Order> newMap, Map<Id,Order> oldMap, List<Order> orderList){ 
        for (Order order : newMap.values()) {
            if ((oldMap.get(order.Id).Ship_To_Address__c != newMap.get(order.Id).Ship_To_Address__c) || (oldMap.get(order.Id).Bill_To_Address__c != newMap.get(order.Id).Bill_To_Address__c)) {
                OrderHelper.updateOrderAddress(orderList); 
            }
        }
        
        /*List<Order> ordersToBeUpdated = new List<Order>(); //Initialise new list of orders
        for (Order newOrder : orderList) { //loop order record(s) (newOrder) from trigger
            Order oldOrder = (Order)Trigger.oldMap.get(newOrder.Id); //obtain existing vales from order record & save to variable
            if (oldOrder.blng__BillNow__c != newOrder.blng__BillNow__c) { //compare existing v saved values. If different then...
                ordersToBeUpdated.add(newOrder); //add active order record to list
            }
        } //next loop item
        if (ordersToBeUpdated.size() > 0) { //check there are records to update. If so...
        	OrderUtility.IncrementBillNowRequests(ordersToBeUpdated);
        } //call method within class, passing records to be updated as list variable*/
    }
    
    public static void handleAfterInsert(Map<Id,Order> newMap){
        InvoiceConsolidation.processNewOrders(newMap);
    }
    
    public static void handleAfterUpdate(Map<Id, Order> newMap, Map<Id, Order> oldMap) {
        InvoiceConsolidation.processUpdateOrders(newMap, oldMap);
        OrderHelper.priceCalculationFailureAlert(newMap, oldMap);
    }

    public static void handleBeforeDelete(Map<Id, Order> oldMap) {
        for (Order order : [SELECT Id, (SELECT Id FROM Bookings__r) FROM Order WHERE Id IN: oldMap.values()]) {
            if (!order.Bookings__r.isEmpty()) {
                oldMap.get(order.Id).addError('Unable to delete an Order which has an associated Booking.');
            }
        }
    }
}