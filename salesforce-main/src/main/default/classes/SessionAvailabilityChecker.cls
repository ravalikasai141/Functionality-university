/*
* @who   Patrick Duncan <patrick.duncan@weare4c.com>
* @what  Class for determining whether Booking__c or Booking_Line__c records can be assigned a new Instance__c lookup 
            by looking at the Capacity of that Instance__c record's sessions and calculating the Booked__c field on Session__c if there is avalability 
* @when  14/1/2020
*/
public with sharing class SessionAvailabilityChecker {
    public static final String OVER_BOOKED_SESSION_MSG = 'One or more of the selected sessions does not have the capacity to complete this transaction';
    
    /*
    *  @description Method to be called in booking update context to filter bookings into appropriate lists and check their session's availaibility
    *  @param  oldMap   Map of old bookings 
    *  @param  newMap   Map of new bookings 
    */
    public static void filterBookingsAndCheckSessionAvailability(Map<Id,Booking__c> oldMap, Map<Id,Booking__c> newMap){
        Set<Id> activeBookingLineIds = SObjectUtil.getActiveSObjectIds(oldMap,newMap,'Status__c');
        Map<Id,SObject> oldMapFiltered = SObjectUtil.getUnionOfSObjectMapAndSet(oldMap,activeBookingLineIds);
        Map<Id,SObject> newMapFiltered = SObjectUtil.getUnionOfSObjectMapAndSet(newMap,activeBookingLineIds);

        Set<Id> bookingIdsWithUpdatedInstanceLookup = SObjectUtil.filterSobjectsOnUpdatedField(oldMapFiltered, newMapFiltered, 'Instance__c');
        Set<Id> uncancelledSObjectIds = SObjectUtil.getUncancelledSObjectIds(oldMapFiltered,newMapFiltered,'Status__c');
        Set<Id> cancelledSObjectIds = SObjectUtil.getCancelledSObjectIds(oldMapFiltered,newMapFiltered,'Status__c');
        bookingIdsWithUpdatedInstanceLookup.removeAll(uncancelledSObjectIds);
        bookingIdsWithUpdatedInstanceLookup.removeAll(cancelledSObjectIds);

        if(!bookingIdsWithUpdatedInstanceLookup.isEmpty()){
            checkBookingInstanceReassignmentAvailability(oldMapFiltered.values(),newMapFiltered.values(),bookingIdsWithUpdatedInstanceLookup);
        }
        if(!uncancelledSObjectIds.isEmpty()){
            checkBookingInstanceReassignmentAvailability(new List<Booking__c>(),newMapFiltered.values(),uncancelledSObjectIds);
        }
        if(!cancelledSObjectIds.isEmpty()){
            checkBookingInstanceReassignmentAvailability(oldMapFiltered.values(),new List<Booking__c>(),cancelledSObjectIds);
            updateBookings(newMap,cancelledSObjectIds,true);
        }
    }

    /*
    *  @description Method to be called in booking line update context to filter booking lines into appropriate lists and check their session's availaibility
    *  @param  oldMap   Map of old booking lines
    *  @param  newMap   Map of new booking lines
    */
    public static void filterBookingLinesAndCheckSessionAvailability(Map<Id,Booking_Line__c> oldMap, Map<Id,Booking_Line__c> newMap){
        Set<Id> bookingLineIdsWithoutCancelledBookings = getBookingLineIdsWithoutCancelledBookings(oldMap);
        Set<Id> activeBookingLineIds = SObjectUtil.getActiveSObjectIds(oldMap,newMap,'On_Hold__c');
        Map<Id,SObject> oldMapFiltered = SObjectUtil.getUnionOfSObjectMapAndSet(oldMap,bookingLineIdsWithoutCancelledBookings);
        oldMapFiltered = SObjectUtil.getUnionOfSObjectMapAndSet(oldMapFiltered,activeBookingLineIds);
        Map<Id,SObject> newMapFiltered = SObjectUtil.getUnionOfSObjectMapAndSet(newMap,bookingLineIdsWithoutCancelledBookings);
        newMapFiltered = SObjectUtil.getUnionOfSObjectMapAndSet(newMapFiltered,activeBookingLineIds);

        Set<Id> bookingLineIdsWithUpdatedInstanceLookup = SObjectUtil.filterSObjectsOnUpdatedField(oldMapFiltered,newMapFiltered,'Instance__c');
        Set<Id> uncancelledBookingLineIds = SObjectUtil.getUncancelledSObjectIds(oldMapFiltered,newMapFiltered,'On_Hold__c');
        Set<Id> cancelledBookingLineIds = SObjectUtil.getCancelledSObjectIds(oldMapFiltered,newMapFiltered,'On_Hold__c');
        bookingLineIdsWithUpdatedInstanceLookup.removeAll(uncancelledBookingLineIds);
        bookingLineIdsWithUpdatedInstanceLookup.removeAll(cancelledBookingLineIds);

        if(!bookingLineIdsWithUpdatedInstanceLookup.isEmpty()){
            checkBookingLineInstanceReassignmentAvailability(oldMapFiltered.values(),newMapFiltered.values(),bookingLineIdsWithUpdatedInstanceLookup);
        }
        if(!uncancelledBookingLineIds.isEmpty()){
            checkBookingLineInstanceReassignmentAvailability(new List<Booking_Line__c>(),newMapFiltered.values(),uncancelledBookingLineIds);
        }
        if(!cancelledBookingLineIds.isEmpty()){
            checkBookingLineInstanceReassignmentAvailability(oldMapFiltered.values(),new List<Booking_Line__c>(),cancelledBookingLineIds);
        }
    }


    /*
    *  @description Overloaded main method for determining if sessions have capacity for new bookings and updating sessions if so
    *  @param  oldBookings   List of old bookings - empty if insert context
    *  @param  newBookings   List of new bookings - empty if delete context
    *  @param  bookingLineIds Set of booking ids to operate on
    */
    public static void checkBookingInstanceReassignmentAvailability(List<Booking__c> oldBookings, List<Booking__c> newBookings, Set<Id> bookingIds){
        Map<Id,Integer> deassignedSessionsAggregateMap = getDeassignedSessionsAggregateMap(oldBookings,bookingIds);
        Map<Id,Integer> assignedSessionsAggregateMap = getAssignedSessionsAggregateMap(newBookings,bookingIds);
        Map<Id,Session__c> sessionMap = getSessionMap(deassignedSessionsAggregateMap,assignedSessionsAggregateMap);
        Map<Id,Booking__c> sessionIdToBookingMap = getSessionIdToBookingMap(newBookings,assignedSessionsAggregateMap,sessionMap);
        Boolean invalidAssignment = evaluateSessionAvailability(deassignedSessionsAggregateMap,assignedSessionsAggregateMap,sessionMap,sessionIdToBookingMap);
        if(!invalidAssignment){
            updateSessions(deassignedSessionsAggregateMap,assignedSessionsAggregateMap,sessionMap);
        }
    }

    /*
    *  @description Overloaded main method for determining if sessions have capacity for new booking lines and updating sessions if so
    *  @param  oldBookings   List of old booking lines - empty if insert context
    *  @param  newBookings   List of new booking lines - empty if delete context
    *  @param  bookingLineIds Set of booking line ids to operate on
    */
    public static void checkBookingLineInstanceReassignmentAvailability(List<Booking_Line__c> oldBookingLines, List<Booking_Line__c> newBookingLines, Set<Id> bookingLineIds){
        Map<Id,Integer> deassignedSessionsAggregateMap = getDeassignedSessionsAggregateMap(oldBookingLines,bookingLineIds);
        Map<Id,Integer> assignedSessionsAggregateMap = getAssignedSessionsAggregateMap(newBookingLines,bookingLineIds);
        Map<Id,Session__c> sessionMap = getSessionMap(deassignedSessionsAggregateMap,assignedSessionsAggregateMap);
        Map<Id,Booking_Line__c> sessionIdToBookingLineMap = getSessionIdToBookingLineMap(newBookingLines,assignedSessionsAggregateMap,sessionMap);
        Boolean invalidAssignment = evaluateSessionAvailability(deassignedSessionsAggregateMap,assignedSessionsAggregateMap,sessionMap,sessionIdToBookingLineMap);
        if(!invalidAssignment){
            updateSessions(deassignedSessionsAggregateMap,assignedSessionsAggregateMap,sessionMap);
        }
    }

    /*
    *  @description Method for getting an aggreagate map of session ids that have been unbooked from -> number of by looking at the booking lines under each booking
    *  @param  oldBookings  List of old bookings
    *  @param  bookingIds   Set of booking ids
    *  @return              Map of session ids that have been unbooked from -> number of
    */
    public static Map<Id,Integer> getDeassignedSessionsAggregateMap(List<Booking__c> oldBookings, Set<Id> bookingIds){
        if(oldBookings.isEmpty()){
            return new Map<Id,Integer>();
        }

        List<Booking_Line__c> oldBookingLines = [SELECT Id, Instance__c, blng_OrderProduct__c, CBA__C, Booking_Record_Type__c FROM Booking_Line__c WHERE Booking__c IN :bookingIds AND (blng_OrderProduct__r.Family__c = 'Session' OR blng_OrderProduct__r.Family__c = 'Online Session' OR blng_OrderProduct__r.Family__c = 'Exam')];
        return getSessionIdToNumberAssignedMap(oldBookingLines);
    }

    /*
    *  @description Method for getting an aggreagate map of session ids that have been booked on -> number of
    *  @param  newBookings  List of new bookings
    *  @param  bookingIds   Set of booking ids
    *  @return              Map of session ids that have been booked on -> number of
    */
    public static Map<Id,Integer> getAssignedSessionsAggregateMap(List<Booking__c> newBookings, Set<Id> bookingIds){
        if(newBookings.isEmpty()){
            return new Map<Id,Integer>();
        }

        List<Booking__c> bookings = SObjectUtil.getSObjectsInIdSet(newBookings,bookingIds);

        return getSessionIdToNumberAssignedMap(bookings);
    }

    /*
    *  @description Method for getting an aggreagate map of session ids that have been booked from -> number of
    *  @param  oldBookingLines  List of old bookings lines
    *  @param  bookingLineIds   Set of booking line ids
    *  @return              Map of session ids that have been booked on -> number of
    */
    public static Map<Id,Integer> getDeassignedSessionsAggregateMap(List<Booking_Line__c> oldBookingLines, Set<Id> bookingLineIds){
        if(oldBookingLines.isEmpty()){
            return new Map<Id,Integer>();
        }

        List<Booking_Line__c> bookingLines = SObjectUtil.getSObjectsInIdSet(oldBookingLines,bookingLineIds);

        return getSessionIdToNumberAssignedMap(bookingLines);
    }

    /*
    *  @description Method for getting an aggreagate map of session ids that have been booked on -> number of
    *  @param  newBookingLines  List of new bookings lines
    *  @param  bookingLineIds   Set of booking line ids
    *  @return                  Map of session ids that have been booked on -> number of
    */
    public static Map<Id,Integer> getAssignedSessionsAggregateMap(List<Booking_Line__c> newBookingLines, Set<Id> bookingLineIds){
        if(newBookingLines.isEmpty()){
            return new Map<Id,Integer>();
        }

        List<Booking_Line__c> bookingLines = SObjectUtil.getSObjectsInIdSet(newBookingLines,bookingLineIds);
        
        return getSessionIdToNumberAssignedMap(bookingLines);
    }

    

    /*
    *  @description Method for creating a map from session id -> booking, so if a session is overbooked, an error can be thrown on the correct booking
    *  @param  newBookings                   List of new updated/inserted bookings
    *  @param  assignedSessionAggregateMap   Map containing all session ids to add to map
    *  @param  sessionMap                    Map of session id -> session
    *  @return                               Map session id -> booking
    */
    public static Map<Id,Booking__c> getSessionIdToBookingMap(List<Booking__c> newBookings, Map<Id,Integer> assignedSessionAggregateMap, Map<Id,Session__c> sessionMap){
        Map<Id,Id> sessionIdToInstanceId = SObjectUtil.createSObjectIdFieldValueMap(sessionMap.values(),'Instance__c',true);
        Map<Id,Instance__c> instanceMap = getInstanceMap(sessionIdToInstanceId.values());
        Map<Id,SObject> instanceIdToBookingMap = SObjectUtil.createIdToSObjectMap(newBookings,'Instance__c');
        Map<Id,Booking__c> sessionIdToBookingMap = new Map<Id,Booking__c>();
        for(Id sessionId:assignedSessionAggregateMap.keySet()){
            Booking__c booking = (Booking__c) instanceIdToBookingMap.get(sessionIdToInstanceId.get(sessionId));
            sessionIdToBookingMap.put(sessionId, booking);
        }
        return sessionIdToBookingMap;
    }

    /*
    *  @description  Method for creating a map from session id -> booking line, so if a session is overbooked, an error can be thrown on the correct booking line
    *  @param  newBookingLines               List of new updated/inserted booking lines
    *  @param  assignedSessionAggregateMap   Map containing all session ids to add to map
    *  @param  sessionMap                    Map of session id -> session
    *  @return                               Map session id -> booking line
    */
    public static Map<Id,Booking_Line__c> getSessionIdToBookingLineMap(List<Booking_Line__c> newBookingLines, Map<Id,Integer> assignedSessionAggregateMap, Map<Id,Session__c> sessionMap){
        Map<Id,Id> sessionIdToInstanceId = SObjectUtil.createSObjectIdFieldValueMap(sessionMap.values(),'Instance__c',true);
        Map<Id,Instance__c> instanceMap = getInstanceMap(sessionIdToInstanceId.values());
        Map<Id,SObject> instanceIdToBookingLineMap = SObjectUtil.createIdToSObjectMap(newBookingLines,'Instance__c');

        Map<Id,Booking_Line__c> sessionIdToBookingLineMap = new Map<Id,Booking_Line__c>();
        for(Id sessionId:assignedSessionAggregateMap.keySet()){
            Booking_Line__c bookingLine = (Booking_Line__c) instanceIdToBookingLineMap.get(sessionIdToInstanceId.get(sessionId));
            sessionIdToBookingLineMap.put(sessionId, bookingLine);
        }
        return sessionIdToBookingLineMap;
    }


    

    /*
    *  @description   Method for determining whether any sessions in a set have been overbooked
    *  @param  deassignedSessionsAggregateMap       Map of session id -> amount unbooked
    *  @param  assignedSessionsAggregateMap         Map of session id -> amount booked
    *  @param  sessionMap                           Map session id -> session
    *  @param  sessionIdToSObjectMap                Map of session id -> sobject - for adding custom validation exception
    *  @return                                      Boolean flag, whether any session has been overbooked
    */
    private static Boolean evaluateSessionAvailability(Map<Id,Integer> deassignedSessionsAggregateMap, Map<Id,Integer> assignedSessionsAggregateMap, Map<Id,Session__c> sessionMap, Map<Id,SObject> sessionIdToSObjectMap){
        Boolean hasErrored = false;
        for(Id assignedSessionId:assignedSessionsAggregateMap.keySet()){
            Session__c assignedSession = sessionMap.get(assignedSessionId);
            Integer deassigned = deassignedSessionsAggregateMap.containsKey(assignedSessionId) ? deassignedSessionsAggregateMap.get(assignedSessionId) : 0;
            Integer assigned = assignedSessionsAggregateMap.get(assignedSessionId);
            Integer available = (Integer) assignedSession.Available__c;
            if(available + deassigned - assigned < 0){
                SObject obj = sessionIdToSObjectMap.get(assignedSessionId);
                obj.addError(OVER_BOOKED_SESSION_MSG);
                hasErrored = true;
            }
        }
        return hasErrored;
    }

    /*
    *  @description   Overloaded method for building a map of session id -> number of booking lines looking up to that session
    *  @param  bookingLines         Booking lines with lookups to session
    *  @return                      Map of session id -> number of booking lines looking up to that session
    */
    private static Map<Id,Integer> getSessionIdToNumberAssignedMap(List<Booking_Line__c> bookingLines){
        Map<Id, Id> bookingLineIdToInstanceId = new Map<Id, Id>();
        Map<Id, Id> bookingLineIdToOrderLineId = new Map<Id, Id>();

        for (Booking_Line__c bookingLine:bookingLines) {
            bookingLineIdToInstanceId.put(bookingLine.Id, bookingLine.Instance__c);
            bookingLineIdToOrderLineId.put(bookingLine.Id, bookingLine.blng_OrderProduct__c);
        }

        Map<Id, Instance__c> instanceMap = new Map<Id, Instance__c>([SELECT Name, (SELECT Id, Session_Product__c FROM Sessions__r) FROM Instance__c WHERE Id IN :bookingLineIdToInstanceId.values()]);
        Map<Id, OrderItem> orderLineMap = new Map<Id, OrderItem>([SELECT Id, SBQQ__RequiredBy__r.Product2Id, Family__c, Product2Id FROM OrderItem WHERE Id IN :bookingLineIdToOrderLineId.values() AND (Family__c = 'Session' OR Family__c = 'Online Session' OR Family__c = 'Exam')]);
        Map<Id, Integer> sessionToNumberAssignedMap = new Map<Id, Integer>();

        for (Booking_Line__c bookingLine : bookingLines) {
            OrderItem orderLine = orderLineMap.get(bookingLineIdToOrderLineId.get(bookingLine.Id));
            if (orderLine == null) {
                continue;
            }

            Instance__c instance;
            Session__c session;
            if (bookingLine.Booking_Record_Type__c != Schema.SObjectType.Booking__c.getRecordTypeInfosByName().get('Material or Fee Booking').getRecordTypeId()) {
                instance = instanceMap.get(bookingLineIdToInstanceId.get(bookingLine.Id));
                session = (bookingLine.CBA__c != null ? BookingLineGenerator.getSessionFromInstance(instance, orderLine, 'CBA') : BookingLineGenerator.getSessionFromInstance(instance, orderLine, 'Booking'));
            }
            if (session == null) {
                continue;
            }

            if (!sessionToNumberAssignedMap.containsKey(session.Id)) {
                sessionToNumberAssignedMap.put(session.Id, 0);
            }
            sessionToNumberAssignedMap.put(session.Id, sessionToNumberAssignedMap.get(session.Id) + 1);
        }
        return sessionToNumberAssignedMap;
    }

    /*
    *  @description   Overloaded method for building a map of session id -> number of bookings looking up to that session's instance
    *  @param  bookings             Bookings with lookups to instance
    *  @return                      Map of session id -> number of bookings looking up to that session's instance
    */
    private static Map<Id,Integer> getSessionIdToNumberAssignedMap(List<Booking__c> bookings){
        Map<Id,Integer> sessionToNumberAssignedMap = new Map<Id,Integer>();
        List<Id> instanceIds = (List<String>) SObjectUtil.getFieldValuesFromSObjectList(bookings,'Instance__c');
        Map<Id,Instance__c> instanceMap = new Map<Id,Instance__c>([SELECT Id, (SELECT Id FROM Sessions__r) FROM Instance__c WHERE Id IN :instanceIds]);
        
        for(Booking__c booking:bookings){
            Instance__c instance = instanceMap.get(booking.Instance__c);
            if(instance != null){
                for(Session__c session:instance.Sessions__r){
                    if(!sessionToNumberAssignedMap.containsKey(session.Id)){
                        sessionToNumberAssignedMap.put(session.Id, 0);
                    }
                    sessionToNumberAssignedMap.put(session.Id, sessionToNumberAssignedMap.get(session.Id)+1);
                }
            }
        }
        return sessionToNumberAssignedMap;
    }

    /*
    *  @description Method to be used in before update context to update Booking_Cancelled__c field 
    *  @param  newMap       New map of bookings
    *  @param  bookingIds   Booking ids to update
    *  @param  cancelled    Boolean flag to update bookings with
    */
    public static void updateBookings(Map<Id,Booking__c> newMap, Set<Id> bookingIds, Boolean cancelled){
        for(Id bookingId:bookingIds){
            newMap.get(bookingId).Booking_Cancelled__c = cancelled;
        }
    }

    /*
    *  @description Method to update booking lines with updated instance lookup with the new session
    *  @param  oldMap       Old map of bookings lines
    *  @param  newMap       New map of bookings lines
    */
    public static void updateBookingLinesWithInstanceChange(Map<Id,Booking_Line__c> oldMap, Map<Id,Booking_Line__c> newMap){
        Set<Id> bookingLineIdsWithUpdatedInstanceLookup = SObjectUtil.filterSobjectsOnUpdatedField(oldMap, newMap, 'Instance__c');
        if (bookingLineIdsWithUpdatedInstanceLookup.size() > 0) {
            Map<Id,Id> bookingLineIdToOrderLineId = SObjectUtil.createSObjectIdFieldValueMap(newMap.values(),'blng_OrderProduct__c',true);
            Map<Id,Id> bookingLineIdToInstanceId = SObjectUtil.createSObjectIdFieldValueMap(newMap.values(),'Instance__c',true);
            Map<Id,Id> bookingLineIdToBookingId = SObjectUtil.createSObjectIdFieldValueMap(newMap.values(),'Booking__c',true);
            Map<Id,Instance__c> instanceMap = getInstanceMap(bookingLineIdToInstanceId.values());
            Map<Id,OrderItem> orderLineMap = getOrderLineMap(bookingLineIdToOrderLineId.values());
            Map<Id,Booking__c> bookingMap = getBookingMap(bookingLineIdToBookingId.values());
            Map<Id,Booking_Line__c> bookingLineMap = getBookingLineMap(bookingLineIdsWithUpdatedInstanceLookup);
            
            for (Id bookingLineId : bookingLineMap.keySet()) {
                Booking_Line__c bookingLine = bookingLineMap.get(bookingLineId);
                Booking__c booking = bookingMap.get(bookingLineIdToBookingId.get(bookingLineId));
                Instance__c instance = instanceMap.get(bookingLineIdToInstanceId.get(bookingLineId));
                OrderItem orderProduct = orderLineMap.get(bookingLineIdToOrderLineId.get(bookingLineId));
                BookingLineGenerator.setBookingLineBillingValues(bookingLine, booking, instance, orderProduct);
            }

            if (!bookingLineMap.isEmpty()) {
                update bookingLineMap.values();
            }
        }
    }

    /*
    *  @description    Method which calculates how many booking lines/bookings have been assigned/deassigned from an instance and updating it with the new value
    *  @param  deassignedSessionsAggregateMap           Map session id -> number of bookings/booking lines deassigned from that instance
    *  @param  assignedSessionsAggregateMap             Map session id -> number of bookings/booking lines assigned from that instance
    *  @param  sessionMap                               Map session id -> session
    */
    public static void updateSessions(Map<Id,Integer> deassignedSessionsAggregateMap, Map<Id,Integer> assignedSessionsAggregateMap, Map<Id,Session__c> sessionMap){
        List<Session__c> sessionsToUpdate = new List<Session__c>();
        for(Id sessionId:sessionMap.keySet()){
            Session__c sessionToUpdate = sessionMap.get(sessionId);
            Integer deassigned = deassignedSessionsAggregateMap.containsKey(sessionId) ? deassignedSessionsAggregateMap.get(sessionId) : 0;
            Integer assigned = assignedSessionsAggregateMap.containsKey(sessionId) ? assignedSessionsAggregateMap.get(sessionId) : 0;
            if(sessionToUpdate == null){
                continue;
            }
            sessionToUpdate.Booked__c += assigned - deassigned;
            sessionsToUpdate.add(sessionToUpdate);
        }
        if(!sessionsToUpdate.isEmpty()){
            update sessionsToUpdate;
        }
    }

    public static Set<Id> getBookingLineIdsWithoutCancelledBookings(Map<Id,Booking_Line__c> oldMap){
		return new Map<Id,Booking_Line__c>([SELECT Id FROM Booking_Line__c WHERE Id IN :oldMap.keySet() AND Booking__r.Booking_Cancelled__c = FALSE]).keySet();
	}

    public static Map<Id,Session__c> getSessionMap(Map<Id,Integer> deassignedSessionsAggregateMap, Map<Id,Integer> assignedSessionsAggregateMap){
		return new Map<Id,Session__c>([SELECT Instance__c, Available__c, Booked__c FROM Session__c WHERE Id IN :deassignedSessionsAggregateMap.keySet() OR Id IN :assignedSessionsAggregateMap.keySet()]);
	}

    public static Map<Id,Instance__c> getInstanceMap(List<Id> instanceIds){
		return new Map<Id,Instance__c>([SELECT Id, Availability__c, Start_Date__c, Product__c, (SELECT Session_Product__c, Session_Date__c FROM Sessions__r) FROM Instance__c WHERE Id IN :instanceIds]);
	}

    public static Map<Id,OrderItem> getOrderLineMap(List<Id> orderLineIds){
		return new Map<Id,OrderItem>([SELECT Product2Id, Family__c, SBQQ__RequiredBy__r.Product2Id FROM OrderItem WHERE Id IN :orderLineIds]);
	}

    public static Map<Id,Booking__c> getBookingMap(List<Id> bookingIds){
		return new Map<Id,Booking__c>([SELECT Booking_Confirmed_Date__c, CreatedDate, RecordTypeId, Status__c FROM Booking__c WHERE Id IN :bookingIds]);
	}

    public static Map<Id,Booking_Line__c> getBookingLineMap(Set<Id> bookingLineIds){
		return new Map<Id,Booking_Line__c>([SELECT Id, Product_Family__c FROM Booking_Line__c WHERE Id IN :bookingLineIds]);
	}

    private class BookingLineWrapper{
        private Booking_Line__c bookingLine;
        private Booking__c booking;
        private OrderItem orderLine;
        private Instance__c instance;
        private Boolean complete;
    }
}