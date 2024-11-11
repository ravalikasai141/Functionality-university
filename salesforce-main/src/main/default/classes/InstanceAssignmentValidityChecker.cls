/*
* @who   Patrick Duncan <patrick.duncan@weare4c.com>
* @what  Class for checking if the product on an instance a booking or booking line is assigned to matches the 
*        product on any of the order lines asscociated with the order on the booking/booking line
* @when  24/3/2020
*/
public with sharing class InstanceAssignmentValidityChecker {
    public static String BOOKING_ERROR_MSG = 'The course from the instance you are booking on has not been sold on the order, please select a different instance';
    static id RecordTypeIdMB = Schema.SObjectType.Booking__c.getRecordTypeInfosByName().get('Material or Fee Booking').getRecordTypeId();
    static id RecordTypeIdCBA = Schema.SObjectType.Booking__c.getRecordTypeInfosByName().get('CBA Booking').getRecordTypeId();

    /*
    *  @description Method to be called in booking insert/update context to check whether the booking has been assigned a valid instance as per its associated order lines
    *  @param  bookings   List of bookings to be checked
    */
    public static void checkBookingInstanceAssignmentValidity(List<SObject> bookings){
        system.debug('@@--PREMA MEDASANI--@@checkBookingInstanceAssignmentValidity--2@');
        List<String> instanceIds = (List<String>) SObjectUtil.getFieldValuesFromSObjectList(bookings,'Instance__c');
        List<String> orderIds = (List<String>) SObjectUtil.getFieldValuesFromSObjectList(bookings,'Order__c');

        Map<Id,Instance__c> instanceMap = new Map<Id,Instance__c>([SELECT Id, Product__c FROM Instance__c WHERE Id IN :instanceIds]);
        Map<Id,Order> orderMap = new Map<Id,Order>([SELECT Id, (SELECT Id, Product2Id FROM OrderItems) FROM Order WHERE Id IN :orderIds]);

        for(SObject obj:bookings){
           
            Booking__c booking = (Booking__c) obj;
            Order orderWithOrderLines = orderMap.get(booking.Order__c);
            if(booking.RecordTypeId != RecordTypeIdMB){
                Instance__c instance = instanceMap.get(booking.Instance__c);
                Id bookingRecordTypeId = booking.RecordTypeId ;
                Boolean valid = isValidInstanceAssignment(instance, orderWithOrderLines.OrderItems , bookingRecordTypeId);
                
                if(!valid){
                    booking.addError(BOOKING_ERROR_MSG);
                }
            }
        }
    }

    /*
    *  @description Method to be called on booking line update context to check whether the booking line has been assigned a valid instance as per its associated order lines
    *  @param  bookings   List of booking lines to be checked
    */
    public static void checkBookingLineInstanceAssignmentValidity(List<SObject> bookingLines){
        List<String> instanceIds = (List<String>) SObjectUtil.getFieldValuesFromSObjectList(bookingLines,'Instance__c');
        List<String> orderIds = (List<String>) SObjectUtil.getFieldValuesFromSObjectList(bookingLines,'blng_Order__c');

        Map<Id,Instance__c> instanceMap = new Map<Id,Instance__c>([SELECT Id, Product__c FROM Instance__c WHERE Id IN :instanceIds]);
        Map<Id,Order> orderMap = new Map<Id,Order>([SELECT Id, (SELECT Id, Product2Id FROM OrderItems) FROM Order WHERE Id IN :orderIds]);

        for(SObject obj:bookingLines){
            Booking_Line__c bookingLine = (Booking_Line__c) obj;
            Order orderWithOrderLines = orderMap.get(bookingLine.blng_Order__c);
            Instance__c instance = instanceMap.get(bookingLine.Instance__c);
            Boolean valid = false;
            for(OrderItem orderLine:orderWithOrderLines.OrderItems){
                if(orderLine.Product2Id == instance.Product__c){
                    valid = true;
                }
            }
            if(!valid){
                bookingLine.addError(BOOKING_ERROR_MSG);
            }
        }
    }

    public static Boolean isValidInstanceAssignment(Instance__c instance, List<OrderItem> orderLines, id bookingRecordTypeId ){
        Boolean valid = false;
            for(OrderItem orderLine:orderLines){
                if(orderLine.Product2Id == instance.Product__c || bookingRecordTypeId == RecordTypeIdCBA){
                    valid = true;
                }
            }
        return valid;
    }
    
}