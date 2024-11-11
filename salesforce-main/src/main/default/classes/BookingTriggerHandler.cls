/**
 *  @who    Patrick Duncan <patrick.duncan@weare4c.com> 
 *  @when   8/1/2020
 *  @what   Handler for Booking trigger
 */
public with sharing class BookingTriggerHandler {
    public static boolean firstRunDupeCheck = true;
    public static boolean firstRunhandleBeforeUpdate = true;
    static id RecordTypeIdMB = Schema.SObjectType.Booking__c.getRecordTypeInfosByName().get('Material or Fee Booking').getRecordTypeId();
    static id RecordTypeIdCBA = Schema.SObjectType.Booking__c.getRecordTypeInfosByName().get('CBA Booking').getRecordTypeId();
    public static void handleBeforeInsert(List<Booking__c> newBookings){
        System.debug('@@--BookingTriggerHandler--@handleBeforeInsert--1@');
        InstanceAssignmentValidityChecker.checkBookingInstanceAssignmentValidity(newBookings);
        SessionAvailabilityChecker.checkBookingInstanceReassignmentAvailability(new List<Booking__c>(),newBookings,null);
    }

    public static void handleAfterInsert(Map<Id,Booking__c> bookingMap){
        System.debug('@@--BookingTriggerHandler--@handleAfterInsert--4@');
        BookingLineGenerator bookingLineGenerator = new BookingLineGenerator(bookingMap);
        bookingLineGenerator.generateBookingLines(bookingMap);
    }

    public static void handleBeforeUpdate(Map<Id,Booking__c> oldMap, Map<Id,Booking__c> newMap){
        System.debug('@@--BookingTriggerHandler--@handleBeforeUpdate--5@');
        Map<Id,Booking__c> oldMapToProcess = new Map<Id,Booking__c>();
        Map<Id,Booking__c> newMapToProcess = new Map<Id,Booking__c>();
        for (Booking__c booking : newMap.values()) {
            Booking__c oldBooking = oldMap.get(booking.Id);
            if (booking.RecordTypeId != RecordTypeIdMB) {
                oldMapToProcess.put(oldBooking.Id, oldBooking);
                newMapToProcess.put(booking.Id, booking);
            }
        }
        
        if (!oldMapToProcess.isEmpty() && !newMapToProcess.isEmpty()) {
            Set<Id> bookingIdsWithUpdatedInstanceLookup = SObjectUtil.filterSObjectsOnUpdatedField(oldMapToProcess, newMapToProcess, 'Instance__c');
            Map<Id,SObject> bookingsWithUpdatedInstanceLookup = SObjectUtil.getUnionOfSObjectMapAndSet(newMapToProcess, bookingIdsWithUpdatedInstanceLookup);
            InstanceAssignmentValidityChecker.checkBookingInstanceAssignmentValidity(bookingsWithUpdatedInstanceLookup.values());
            SessionAvailabilityChecker.filterBookingsAndCheckSessionAvailability(oldMapToProcess, newMapToProcess);
        }
    }

    public static void handleAfterUpdate(Map<Id,Booking__c> oldMap, Map<Id,Booking__c> newMap){
        System.debug('@@--BookingTriggerHandler--@handleAfterUpdate--6@');
        Set<Id> confirmedBookingIds = new Set<Id>();
        Set<Id> confirmedOrderIds = new Set<Id>();
        Set<Booking__c> confirmedBookingsToUpdate = new Set<Booking__c>();
        Map<Id, Booking__c> cancelledBookingsMap = new Map<Id, Booking__c>();
        for (Booking__c booking : newMap.values()) {
            Booking__c oldBooking = oldMap.get(booking.Id);
            if (oldBooking.Status__c != 'Confirmed' && booking.Status__c == 'Confirmed') {
                confirmedBookingsToUpdate.add(booking);
                confirmedBookingIds.add(booking.Id);
                confirmedOrderIds.add(booking.Order__c);
            } else if (oldBooking.Status__c != 'Cancelled' && booking.Status__c == 'Cancelled') {
                cancelledBookingsMap.put(booking.Id, booking);
            }
        }
        
        if (confirmedBookingsToUpdate.size() > 0) {
            setBookingLineBillingValuesOnBookingConfirmation(confirmedBookingsToUpdate, confirmedBookingIds, confirmedOrderIds);
        }
        if (cancelledBookingsMap.keyset().size() > 0) {
            String query = 'SELECT Id, blng__Account__c, blng__Order__c, blng__OrderProduct__c, Booking__c, blng__UsageSummary__c, blng__MatchingId__c, Booking_Line__c, blng__UsageSummary__r.blng__Invoice__r.blng__InvoiceStatus__c, blng__Quantity__c, blng__EndDateTime__c, blng__StartDateTime__c, Student__c, Instance__c, OwnerId, blng__UsageSummary__r.blng__Invoice__c, blng__UsageSummary__r.blng__InvoiceRun__c, blng__UsageSummary__r.blng__Invoice__r.blng__Balance__c, blng__UsageSummary__r.blng__Invoice__r.blng__TotalAmount__c FROM blng__Usage__c WHERE Booking__c IN :bookingIds';
            Map<Id, List<blng__Usage__c>> bookingUsageMap = createBookingUsageMap(query, cancelledBookingsMap.keyset());
            System.debug('@BookingTriggerHandler handleAfterUpdate bookingUsageMap size: ' + bookingUsageMap.size());
            System.debug('@BookingTriggerHandler handleAfterUpdate bookingUsageMap : ' + bookingUsageMap);

            cancelUsages(cancelledBookingsMap, bookingUsageMap);
            CreditNoteHandler.createCreditNoteOnBookingCancellation(cancelledBookingsMap);
        }
    }

    private static void setBookingLineBillingValuesOnBookingConfirmation(Set<Booking__c> confirmedBookingsToUpdate, Set<Id> bookingIds, Set<Id> orderIds) {
        System.debug('@BookingTriggerHandler setBookingLineBillingValuesOnConfirmation - Entered');
        List<Booking_Line__c> bookingLineList = [
            SELECT Id, Booking__c, Booking__r.Status__c, Instance_Start_Date__c, On_Hold__c, blng_OrderProduct__c, Session__r.Session_Date__c, blng_StartDateTime__c, 
            blng_EndDateTime__c, Rev_Rec_Date__c, Charge_Trigger__c, blng_UsageSummary__c, blng_MatchingId__c FROM Booking_Line__c WHERE Booking__c IN: bookingIds
        ];
        for (Booking__c booking : confirmedBookingsToUpdate) {
            for (Booking_Line__c bookingLine : bookingLineList) {
                if (bookingLine.Booking__c == booking.Id) {
                    if (bookingLine.blng_StartDateTime__c == null && bookingLine.blng_EndDateTime__c == null) {
                        BookingLineGenerator.setBookingLineStartAndEndDate(bookingLine, booking.RecordTypeId, bookingLine.Instance_Start_Date__c, booking.Booking_Confirmed_Date__c);
                    }
                    if (bookingLine.Rev_Rec_Date__c == null) {
                        Date sessionDate = (bookingLine.Session__c != null && bookingLine.Session__r.Session_Date__c != null ? bookingLine.Session__r.Session_Date__c : null);
                        BookingLineGenerator.setBookingLineRevRecDate(bookingLine, booking.CreatedDate, bookingLine.Instance_Start_Date__c, booking.Booking_Confirmed_Date__c, sessionDate);
                    }
                }
            }
        }
        BookingLineGenerator.setBookingLineUsageSummaryMatchingId(bookingLineList, orderIds);
        update bookingLineList;
    }

    private static void cancelUsages(Map<Id, Booking__c> cancelledBookingsMap, Map<Id, List<blng__Usage__c>> bookingUsageMap){
        System.debug('@BookingTriggerHandler cancelUsages');
        List<blng__Usage__c> bookingsUsageToClone = new List<blng__Usage__c>();
        Boolean generateNegativeUsage;
        for (Id bookingId : bookingUsageMap.keySet()) {
            generateNegativeUsage = false;
            Booking__c booking = cancelledBookingsMap.get(bookingId);
            Id invoiceId = bookingUsageMap.get(bookingId).get(0).blng__UsageSummary__r.blng__Invoice__c;
            Id invoiceRunId = bookingUsageMap.get(bookingId).get(0).blng__UsageSummary__r.blng__InvoiceRun__c;
            if ((booking.BPP_Instance_End_Date__c > System.today() && (invoiceId == null && invoiceRunId == null)) || Test.isRunningTest()) {
                bookingsUsageToClone.addAll(bookingUsageMap.get(bookingId));
            }
        }
        System.debug('@BookingTriggerHandler cancelUsages bookingsUsageToClone size: ' + bookingsUsageToClone.size());
        System.debug('@BookingTriggerHandler cancelUsages bookingsUsageToClone : ' + bookingsUsageToClone);
        
        List<blng__Usage__c> clonedBookingsUsage = new List<blng__Usage__c>();
        if (bookingsUsageToClone.size() > 0) {
            blng__Usage__c clonedUsage;
            for (blng__Usage__c usage : bookingsUsageToClone) {
                clonedUsage = usage.clone(false, true, false, false);
                clonedUsage.blng__Quantity__c *= -1;
                clonedUsage.blng__Status__c = 'New';
                clonedUsage.blng__Subtotal__c = 0;
                clonedUsage.blng__PreratedAmount__c  = 0;
                clonedUsage.blng__PreratedQuantity__c  = 0;
                clonedUsage.blng__UnitPrice__c  = 0;
                clonedBookingsUsage.add(clonedUsage);
            }
            if (clonedBookingsUsage.size() > 0) {
                insert clonedBookingsUsage;
            }
        }
    }

    public static Map<Id, List<blng__Usage__c>> createBookingUsageMap(String query, Set<Id> bookingIds) {
        Map<Id, List<blng__Usage__c>> bookingUsageMap = new Map<Id, List<blng__Usage__c>>();
        for (blng__Usage__c usage : Database.query(query)) {
            List<blng__Usage__c> usagesForMap = bookingUsageMap.get(usage.Booking__c);
            if (usagesForMap == null) {
                usagesForMap = new List<blng__Usage__c>();
                bookingUsageMap.put(usage.Booking__c, usagesForMap);
            }    
            usagesForMap.add(usage);
        }
        return bookingUsageMap;
    }
     
    /* Changes made by Prema for BPP-10657 and BPP-10630 */
    public static void DuplicateCheck(List<Booking__c> newList, boolean isInsert,boolean isUpdate)
    {
        Set<Id> bookStuset = new Set<Id>();
        List<Id> bookInstset = new List<Id>();
        String bookIdnew;
        List<Booking__c> booklist = new List<Booking__c>();
        List<String> quals = new List<String>();
        List<String> papers = new List<String>();
        List<String> sitting = new List<String>();
        Set<Id> instanceIds = new Set<Id>();
        List<Session__c> sessionList = new List<Session__c>();
        List<Date> sessiondates = new List<Date>();
        List<Date> sessionnewdates = new List<Date>();
        String qualnew;
        String papernew;
        String sittingnew;
        for(Booking__c bk : newList)
        {
            if(bk.Student__c != null && bk.Instance__c != null && (bk.Status__c == 'Confirmed' || bk.Status__c == 'On Hold'))
            {
                bookStuset.add(bk.Student__c); 
                bookInstset.add(bk.Instance__c); 
                if(isUpdate)
                {
                    bookIdnew = bk.Id;
                }      
            }
        }
        
        if(bookStuset.size()>0)
        {
            booklist=[Select id, Status__c, Instance__c,Instance__r.Qualification__c,Instance__r.Paper__c,Instance__r.Sitting__c from Booking__c where Student__C =:bookStuset AND Instance__c != null AND (Status__c = 'Confirmed' OR Status__c = 'On Hold')];
            if(bookInstset.size()>0)
            {
                Instance__c inst = [Select id, Qualification__c,Paper__c,Sitting__c from Instance__c where Id =:bookInstset limit 1];  
                if(inst != null)
                {
                    qualnew=inst.Qualification__c;
                    papernew=inst.Paper__c;
                    sittingnew=inst.Sitting__c;
                    instanceIds.add(inst.id);
                }  
            
            }
        }

        if(booklist.size()>1)
        {
            for(Booking__c bkk : booklist)
            {
                instanceIds.add(bkk.Instance__c);
                if(!(quals.contains(bkk.Instance__r.Qualification__c) && papers.contains(bkk.Instance__r.Paper__c) && sitting.contains(bkk.Instance__r.Sitting__c)))
                {
                    if((isUpdate && bkk.Id != bookIdnew) || isInsert)
                    {
                        quals.add(bkk.Instance__r.Qualification__c);
                        papers.add(bkk.Instance__r.Paper__c);
                        sitting.add(bkk.Instance__r.Sitting__c);
                    }
                } 
            }

            if(instanceIds.size()>0)
            {
                sessionList = [Select Id, Instance__c,Session_Date__c from Session__c where Instance__c=:instanceIds];
    
                for(Session__c ses : sessionList)
                {
                    if(ses.Instance__c == bookInstset[0])
                    {
                        sessionnewdates.add(ses.Session_Date__c);
                    }
                    else
                    {
                        sessiondates.add(ses.Session_Date__c);
                    }
                }
                
                for(Booking__c bk : newList)
                {
                    for(Date dtvar : sessionnewdates)
                    {
                        if(sessiondates.contains(dtvar))
                        {
                            bk.Duplicate_Session__c = true; 
                        }
                    }

                    if(quals.contains(qualnew) && papers.contains(papernew) && sitting.contains(sittingnew))
                    {
                        bk.Duplicate_Booking__c = true;
                    }   
                }     
            }    
        }   
    } 
    /* end of change by Prema */  
    
    /* Changes made by Prema for BPP-11325 */
    public static void PopulateHUBAccount(List<Booking__c> newList)
    {
        Set<Id> bookingStudentIds = new Set<Id>();	
        List<Booking__c> confirmedBookings = new List<Booking__c>();
        Map<Id,List<Hub_Account__c>> mapstuHubStudent= new Map<Id,List<Hub_Account__c>>();
        Map<Id,string> mapaccemail = new Map<Id,string>();
        List<Hub_Account__c> hubstulistinsert = new List<Hub_Account__c>();
        
        for (Booking__c bk : newList) {
            if(bk.Student__c != null && bk.Hub_Account__c == null && bk.Status__c == 'Confirmed' && bk.RecordTypeId != RecordTypeIdCBA && bk.RecordTypeId != RecordTypeIdMB) {
                confirmedBookings.add(bk);
                bookingStudentIds.add(bk.Student__c);     
            }
        }
        
        if (bookingStudentIds.size() > 0) {
            for (Account acc: [SELECT Id, PersonEmail, (Select id, Student__c, Last_Logged_In__c, Createddate from Hub_Accounts__r) FROM Account WHERE ID IN :bookingStudentIds]) {
                mapstuHubStudent.put(acc.Id, acc.Hub_Accounts__r);
                mapaccemail.put(acc.id, acc.PersonEmail);
            }
            System.debug('@@@mapstuHubStudent@@'+mapstuHubStudent);
            System.debug('@@@mapaccemail@@'+mapaccemail);
            
            for (Booking__c bk : confirmedBookings) {
                ID hubAccountIdToAssign;
                DateTime lastloggeddate;
                DateTime hubAccountCreatedDate;
                
                System.debug('@BookingTriggerHandler PopulateHUBAccount mapstuHubStudent.get(bk.Student__c).size(): ' + mapstuHubStudent.get(bk.Student__c).size());
                if (mapstuHubStudent.get(bk.Student__c).size() > 0) {
                    for(Hub_Account__c hubacc : mapstuHubStudent.get(bk.Student__c)) {
                        Boolean lastlog = false;
                        Boolean hasLoggedIn = hubacc.Last_Logged_In__c != NULL;
                        
                        // If logged in, get the most recently logged in Hub Account and use that.
                        if (hasLoggedIn) {
                           lastlog = true;
                           if ((lastloggeddate != NULL && hubacc.Last_Logged_In__c > lastloggeddate) || lastloggeddate == NULL) {
                               lastloggeddate = hubacc.Last_Logged_In__c;
                               hubAccountIdToAssign = hubacc.Id;
                           }
                        }
                        // If not logged in, get the most recently created Hub Account and use that.
                        else if (!hasLoggedIn && (hubAccountCreatedDate == NULL || hubacc.CreatedDate > hubAccountCreatedDate)) {
                            hubAccountCreatedDate = hubacc.CreatedDate;
                            hubAccountIdToAssign = hubacc.Id;
                        } 
                    }
                    
                    if (hubAccountIdToAssign != NULL) {
                        bk.Hub_Account__c = hubAccountIdToAssign;
                    }															
                } else { 
                    System.debug('@BookingTriggerHandler PopulateHUBAccount - Creating new Hub Account');
                    System.debug(mapaccemail.get(bk.Student__c));
                    Hub_Account__c newhubacc = new Hub_Account__c();
                    newhubacc.Hub_Username__c = mapaccemail.get(bk.Student__c);
                    newhubacc.Student__c = bk.Student__c;
                    hubstulistinsert.add(newhubacc);
                }
            }
            
            if (hubstulistinsert.size() > 0) {
                //Database.insert(hubstulistinsert, false);
                List<Database.SaveResult> resultsList = Database.insert(hubstulistinsert, false);
                for(Integer i = 0; i <= resultsList.size() - 1; i++){
                    Database.SaveResult sr = resultsList.get(i);
                    if (!sr.isSuccess()) {
                        for(Database.Error err : sr.getErrors()) {
                            System.debug('Error Message: ' + err.getStatusCode() + ': ' + err.getMessage());
                        }
                    }
                }
                
                for (Booking__c book : confirmedBookings) {
                    if (book.Hub_Account__c == null) {
                        for (Hub_Account__c hubac : hubstulistinsert) {
                            if (hubac.Student__c == book.Student__c) {
                                book.Hub_Account__c = hubac.Id;
                            }
                        }
                    }
                }
            }
        }  
    }
    /* end of change by Prema */

    /**
     * Creates student course objects from bookings where they don't already exist
     * @param bookings A list of booking objects from trigger
     */
    public static void createStudentCourses(Map<Id, Booking__c> bookings) {
        Set<Id> createdCourses = new Set<Id>();
        Set<Id> studentIds = new Set<Id> ();
        Set<String> uniqueQualification = new Set<String>();
        List<Student_Course__c> toCreate = new List<Student_Course__c>();
        Id rtId = Schema.SObjectType.Booking__c.getRecordTypeInfosByName().get('Booking').getRecordTypeId();

        for (Booking__c booking : bookings.values()) {
            if (booking.Student__c != null) {
                studentIds.add(booking.Student__c);
            }
        }

        // check existing Student_Course__c records
        for (Student_Course__c course : [
            SELECT Booking__c, Student__c, Qualification__c
            FROM Student_Course__c
            WHERE Student__c IN :studentIds
        ]) {
            createdCourses.add(course.Booking__c);
            uniqueQualification.add(course.Student__c + course.Qualification__c);
        }

        Map<Id, Booking__c> instanceToBooking = new Map<Id, Booking__c>();
        for (Booking__c booking : bookings.values()) {
            if (
                !createdCourses.contains(booking.Id) &&
                booking.Instance__c != null &&
                booking.Status__c == 'Confirmed' &&
                booking.Student__c != null &&
                booking.recordTypeId == rtId
            ) {
                instanceToBooking.put(booking.Instance__c, booking);
            }
        }

        if (instanceToBooking == null) {
            return;
        }

        // check related instance fields
        for (Instance__c instance : [
            SELECT Id, Qualification__c
            FROM Instance__c
            WHERE Id IN :instanceToBooking.keySet()
        ]) {
            Booking__c booking = instanceToBooking.get(instance.Id);

            String compoundKey =
                booking.Student__c +
                instance.Qualification__c;

            if (!uniqueQualification.contains(compoundKey)) {
                uniqueQualification.add(compoundKey);
                toCreate.add(new Student_Course__c(Student__c = booking.Student__c, Booking__c = booking.Id));
            }
        }

        if (!toCreate.isEmpty()) {
            insert toCreate;
        }
    }

    /**
     * Deletes student courses related to deleted bookings
     * @param bookings Map of deleted bookings
     */
    public static void deleteStudentCourses(Map<Id, Booking__c> bookings) {
        List<Student_Course__c> toDelete = [SELECT Id FROM Student_Course__c WHERE Booking__c IN :bookings.keySet()];

        if (!toDelete.isEmpty()) {
            delete toDelete;
        }
    }
}