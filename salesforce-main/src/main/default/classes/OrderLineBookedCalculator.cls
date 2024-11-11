/*
* @who   Patrick Duncan <patrick.duncan@weare4c.com>
* @what  Class for calucating the number of booking lines with a lookup to each order line and storing the result on the Booked_Quantity__c field on order line
* @when  23/1/2020
*/
public with sharing class OrderLineBookedCalculator {

    /*
    *  @description    Method for creating a map of order line id -> number of booking lines with lookups to it
    *  @param  oldBookingLines              List of old order lines (empty if insert/undelete)
    *  @param  newBookingLines              List of new order lines (empty if delete)
    */
    public static void calculateOrderProductsBooked(List<Booking_Line__c> oldBookingLines, List<Booking_Line__c> newBookingLines){
        System.debug('oldBookingLines: ' + oldBookingLines);
        System.debug('newBookingLines: ' + newBookingLines);
        Map<Id,Integer> orderProductsToDecrease = createOrderProductToNumberBookedMap(oldBookingLines);
        Map<Id,Integer> orderProductsToIncrease = createOrderProductToNumberBookedMap(newBookingLines);
        Map<Id,OrderItem> orderLineMap = getOrderLineMap(orderProductsToDecrease.keySet(),orderProductsToIncrease.keySet());
        updateOrderLines(orderProductsToDecrease,orderProductsToIncrease,orderLineMap);
    }

    /*
    *  @description    Method for creating a map of order line id -> number of booking lines with lookups to it
    *  @param  bookingLines             List of order lines to look at
    *  @return                          Map of order line id -> number of booking lines with lookups to it
    */
    public static Map<Id,Integer> createOrderProductToNumberBookedMap(List<Booking_Line__c> bookingLines){
        Map<Id,Integer> orderProductToNumberBookedMap = new Map<Id,Integer>();
        for(Booking_Line__c bookingLine:bookingLines){
            if(!orderProductToNumberBookedMap.containsKey(bookingLine.blng_OrderProduct__c)){
                orderProductToNumberBookedMap.put(bookingLine.blng_OrderProduct__c,0);
            }
            orderProductToNumberBookedMap.put(bookingLine.blng_OrderProduct__c, orderProductToNumberBookedMap.get(bookingLine.blng_OrderProduct__c)+1);
        }
        return orderProductToNumberBookedMap;
    }

    /*
    *  @description    Method for building a map of order line id -> order line
    *  @param  oldIds           Set of order line ids
    *  @param  newIds           Set of order line ids
    *  @return                  Map of order line id -> order line 
    */
    public static Map<Id,OrderItem> getOrderLineMap(Set<Id> oldIds, Set<Id> newIds){
        return new Map<Id,OrderItem>([SELECT Product2Id, Family__c, Booked_Quantity__c FROM OrderItem WHERE Id IN :oldIds OR Id IN :newIds]);
    }

    /*
    *  @description    Method for updating order lines with new value of Booked_Quantity__c
    *  @param  orderProductsToDecrease              List of order line ids
    *  @param  orderProductsToIncrease              List of order line ids
    *  @param  orderLineMap                         Map of order line id -> order line 
    */
    private static void updateOrderLines(Map<Id,Integer> orderProductsToDecrease, Map<Id,Integer> orderProductsToIncrease, Map<Id,OrderItem> orderLineMap){
        for(Id orderLineId:orderLineMap.keySet()){
            OrderItem orderLine = orderLineMap.get(orderLineId);
            Integer amountToDecrease = orderProductsToDecrease.containsKey(orderLineId) ? orderProductsToDecrease.get(orderLineId) : 0;
            Integer amountToIncrease = orderProductsToIncrease.containsKey(orderLineId) ? orderProductsToIncrease.get(orderLineId) : 0;
            if(orderLine.Booked_Quantity__c == null){
                orderLine.Booked_Quantity__c = 0;
            }
            orderLine.Booked_Quantity__c += amountToIncrease - amountToDecrease;
            
            System.debug('@OrderLineBookedCalculator orderLine: ' + orderLine);
            System.debug('@OrderLineBookedCalculator amountToDecrease: ' + amountToDecrease);
            System.debug('@OrderLineBookedCalculator amountToIncrease: ' + amountToIncrease);
            System.debug('@OrderLineBookedCalculator orderLine: ' + orderLine.Booked_Quantity__c);
        }
        if(!orderLineMap.isEmpty()){
            update orderLineMap.values();
        }   
    }
}