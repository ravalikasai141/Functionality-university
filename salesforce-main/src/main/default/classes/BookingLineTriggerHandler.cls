/*
* @who   Patrick Duncan <patrick.duncan@weare4c.com>
* @what  Handler class for BookingLineTrigger
* @when  14/1/2020
*/
public with sharing class BookingLineTriggerHandler {

    public static void handleAfterInsert(Map<Id,Booking_Line__c> newMap){
        List<Booking_Line__c> nonCancelledBookingLines = BookingUtility.getNonCancelledBookingLines(newMap.values());
        OrderLineBookedCalculator.calculateOrderProductsBooked(new List<Booking_Line__c>(),nonCancelledBookingLines);

        Map<Id, Booking_Line__c> bookingLinesReadyForUsageGeneration = getBookingLinesReadyForUsageGeneration(newMap.keyset());
        if (!bookingLinesReadyForUsageGeneration.isEmpty()) {
            BookingUsageGenerator.GenerationResult results = BookingUsageGenerator.generateUsages(bookingLinesReadyForUsageGeneration.values());
        }

        Set<Id> bookingLineIds = new Set<Id>();
        for (Booking_Line__c bookingLine : newMap.values()) {
            bookingLineIds.add(bookingLine.Id);
        }
        List<Booking_Line__c> bookingLineList = [
            SELECT Id, Instance__c, blng_Order__c, Student__c, Student__r.Name, Student__r.BPP_Deliver_To_Contact__r.Name, blng_Account__c,
            Student__r.RecordTypeId, BPP_Instance_Product__c, blng_OrderProduct__c, On_Hold__c, Booking__r.BPP_Student_Name__c 
            FROM Booking_Line__c WHERE Id IN: bookingLineIds
        ];
        DeliveryUtility.createDeliveryRecords(bookingLineList);
    }

    public static void handleBeforeUpdate(Map<Id,Booking_Line__c> oldMap, Map<Id,Booking_Line__c> newMap){
        Id recordTypeIdMB = Schema.SObjectType.Booking__c.getRecordTypeInfosByName().get('Material or Fee Booking').getRecordTypeId();
        Map<Id, Booking_Line__c> oldBookingLineMapToProcess = new Map<Id, Booking_Line__c>();
        Map<Id, Booking_Line__c> newBookingLineMapToProcess = new Map<Id, Booking_Line__c>();
        for (Booking_Line__c bookingLine : newMap.values()) {
            if (bookingLine.RecordTypeId != recordTypeIdMB) {
                Booking_Line__c oldBookingLine = oldMap.get(bookingLine.Id);
                oldBookingLineMapToProcess.put(oldBookingLine.Id, oldBookingLine);
                newBookingLineMapToProcess.put(bookingLine.Id, bookingLine);
            }
        }

        Set<Id> bookingLineIdsWithUpdatedInstanceLookup = SObjectUtil.filterSObjectsOnUpdatedField(oldBookingLineMapToProcess, newBookingLineMapToProcess,'Instance__c');
        Map<Id,SObject> bookingsWithUpdatedInstanceLookup = SObjectUtil.getUnionOfSObjectMapAndSet(newBookingLineMapToProcess, bookingLineIdsWithUpdatedInstanceLookup);

        InstanceAssignmentValidityChecker.checkBookingLineInstanceAssignmentValidity(bookingsWithUpdatedInstanceLookup.values());
        SessionAvailabilityChecker.filterBookingLinesAndCheckSessionAvailability(oldBookingLineMapToProcess, newBookingLineMapToProcess);
    }

    public static void handleAfterUpdate(Map<Id,Booking_Line__c> oldMap, Map<Id,Booking_Line__c> newMap){
        SessionAvailabilityChecker.updateBookingLinesWithInstanceChange(oldMap,newMap);

        Set<Id> bookingLinesWithUpdatedOrderLineLookup = SObjectUtil.filterSObjectsOnUpdatedField(oldMap,newMap,'blng_OrderProduct__c');
        Set<Id> uncancelledBookingLineIds = SObjectUtil.getUncancelledSObjectIds(oldMap,newMap,'On_Hold__c');
        Set<Id> cancelledBookingLineIds = SObjectUtil.getCancelledSObjectIds(oldMap,newMap,'On_Hold__c');
        bookingLinesWithUpdatedOrderLineLookup.removeAll(uncancelledBookingLineIds);
        bookingLinesWithUpdatedOrderLineLookup.removeAll(cancelledBookingLineIds);

        if(!bookingLinesWithUpdatedOrderLineLookup.isEmpty()){
            Map<Id,SObject> oldMapFiltered = SObjectUtil.getUnionOfSObjectMapAndSet(oldMap,bookingLinesWithUpdatedOrderLineLookup);
            Map<Id,SObject> newMapFiltered = SObjectUtil.getUnionOfSObjectMapAndSet(newMap,bookingLinesWithUpdatedOrderLineLookup);
            OrderLineBookedCalculator.calculateOrderProductsBooked(oldMapFiltered.values(),newMapFiltered.values());
        }
        if(!uncancelledBookingLineIds.isEmpty()){
            Map<Id,SObject> newMapFiltered = SObjectUtil.getUnionOfSObjectMapAndSet(newMap,uncancelledBookingLineIds);
            OrderLineBookedCalculator.calculateOrderProductsBooked(new List<Booking_Line__c>(),newMapFiltered.values());
        }
        if(!cancelledBookingLineIds.isEmpty()){
            Map<Id,SObject> oldMapFiltered = SObjectUtil.getUnionOfSObjectMapAndSet(oldMap,cancelledBookingLineIds);
            OrderLineBookedCalculator.calculateOrderProductsBooked(oldMapFiltered.values(),new List<Booking_Line__c>());
        }

        Map<Id, Booking_Line__c> bookingLinesReadyForUsageGeneration = getBookingLinesReadyForUsageGeneration(newMap.keyset());
        if (!bookingLinesReadyForUsageGeneration.isEmpty()) {
            BookingUsageGenerator.GenerationResult results = BookingUsageGenerator.generateUsages(bookingLinesReadyForUsageGeneration.values());
        }
    }
    
    private static Map<Id, Booking_Line__c> getBookingLinesReadyForUsageGeneration(Set<Id> bookingLineIds) {
        return new Map<Id, Booking_Line__c>([SELECT Id, blng_Account__c, blng_Order__c, blng_OrderProduct__c, blng_MatchingId__c, blng_StartDateTime__c, 
        	blng_EndDateTime__c, Booking__c, Student__c, Instance__c, Session__c, Rev_Rec_Date__c, PO_Number__c, Booking__r.OwnerId FROM Booking_Line__c 
        	WHERE Id IN: bookingLineIds AND On_Hold__c = 'Confirmed' AND Batch_Processed__c = FALSE AND Billing_Type__c = 'In Advance' AND Charge_Type__c = 'Usage']);
    }
}