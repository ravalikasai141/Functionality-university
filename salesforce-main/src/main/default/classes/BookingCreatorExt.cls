global with sharing class BookingCreatorExt {
    @testVisible
    private Integer messagesSent = 0;
    
    // Lists of error messages to return
    private List<String> nullFields;
    private List<String> overbookedInstances;
    private List<String> invalidInstances;
    private List<String> inactiveOrders; //added by Prema - BPP-13388
    private List<String> duplicateBookings; //added by Prema - BPP-13028
    private List<String> saveErrors;
    static id RecordTypeIdCBA = Schema.SObjectType.Booking__c.getRecordTypeInfosByName().get('CBA Booking').getRecordTypeId();

    // Defines if there has been an error
    public Boolean noErrors {get;set;}
    
    /* START OF - Changes made by David Lovejoy - 18/06/2021 - BPP-15491 */
    Boolean bookingTableSelect = true;
    Boolean bookingTable = false;
    Boolean bookingTableCBA = false;
    
    public PageReference showBookingTable() {
        setHideShowTableSelect(false);
        setHideShowBookingTable(true);
        setHideShowBookingTableCBA(false);
        return null;
    }
    
    public PageReference showBookingTableCBA() {
        setHideShowTableSelect(false);
        setHideShowBookingTableCBA(true);
        setHideShowBookingTable(false);
        return null;
    }
    
    public Boolean getHideShowTableSelect() {
    	return this.bookingTableSelect;
    }
    
    public void setHideShowTableSelect(Boolean s) {
    	this.bookingTableSelect = s;
    }
    
    public Boolean getHideShowBookingTable() {
    	return this.bookingTable;
    }
    
    public void setHideShowBookingTable(Boolean s) {
    	this.bookingTable = s;
    }
    
    public Boolean getHideShowBookingTableCBA() {
    	return this.bookingTableCBA;
    }
    
    public void setHideShowBookingTableCBA(Boolean s) {
    	this.bookingTableCBA = s;
    }
    /* END OF - Changes made by David Lovejoy */
    
    // CC emails addresses
    private List<String> ccAddresses = new List<String> {'davidlovejoy@bpp.com'};

    public BookingCreatorExt(ApexPages.StandardController con) {
        noErrors = true;
        nullFields = new List<String>();
        overbookedInstances = new List<String>();
        invalidInstances = new List<String>();
        inactiveOrders = new List<String>(); //added by Prema - BPP-13388
        duplicateBookings = new List<String>(); //added by Prema - BPP-13028
        saveErrors = new List<String>();
    }

    /**
    *  Saves data as Speclines
    */
    public void saveData() {
        noErrors = true;
        String jsonString = Apexpages.currentPage().getParameters().get('jsonString');
        System.debug('jsonString' + jsonString);

        nullFields = new List<String>();
        overbookedInstances = new List<String>();
        invalidInstances = new List<String>();
        inactiveOrders = new List<String>(); //added by Prema - BPP-13388
        duplicateBookings = new List<String>(); //added by Prema - BPP-13028
        saveErrors = new List<String>();

        List<Object> primaryList = (List<Object>) Json.deserializeUntyped(jsonString);
        List<Booking__c> bookings = buildBookings(primaryList);
		System.debug('@BookingCreatorExt Bookings: '+ bookings);
        if (!bookings.isEmpty() && duplicateBookings.isEmpty()) {
            List<Database.SaveResult> results = Database.insert(bookings, true);
            checkErrors(bookings, results);
        }
        System.debug('noErrors ' + noErrors);

        if (!nullFields.isEmpty() || !overbookedInstances.isEmpty() || !invalidInstances.isEmpty() || !inactiveOrders.isEmpty() || !duplicateBookings.isEmpty()) {
            noErrors = false;
            buildEmail();
        }
        
        /* START OF - Changes made by David Lovejoy - 18/06/2021 - BPP-15491 */
        setHideShowTableSelect(true);
        setHideShowBookingTable(false);
        setHideShowBookingTableCBA(false);
        /* END OF - Changes made by David Lovejoy */
    }

    /**
    *  Builds speclines from List of Objects
    *
    */
    private List<Booking__c> buildBookings(List<Object> primaryList) {
        List<Booking__c> bookingLines = new List<Booking__c>();
        List<String> studentIds = new List<String>();
        List<String> orderIds = new List<String>();
        List<String> instanceIds = new List<String>();

        for (Object primaryListItem : primaryList) {
            List<Object> secondaryList = (List<Object>) primaryListItem;
            if (secondaryList.get(0) != null) {
                studentIds.add(String.valueOf(secondaryList.get(0)));
            }
            if (secondaryList.get(2) != null) {
                instanceIds.add(String.valueOf(secondaryList.get(2)));
            }
            if (secondaryList.get(3) != null) {
                orderIds.add(String.valueOf(secondaryList.get(3)));
            }
        }

        Map<Id, Order> orderMap = new Map<Id, Order>([SELECT Id, Status, (SELECT Id, Product2Id FROM OrderItems) FROM Order WHERE Id IN :orderIds]);
        /* START OF - Changes made by David Lovejoy - 07/09/2021 - BPP-13028 */
        Map<Id, Instance__c> instanceMap = new Map<Id, Instance__c>([SELECT Id, Product__c, Paper__c, Start_Date__c FROM Instance__c WHERE Id IN :instanceIds]);
        Map<Id, List<Booking__c>> previouslyConfirmedBookingsMap = new Map<Id, List<Booking__c>>();
        List<Booking__c> bookingList = [SELECT Id, Name, Student__c, Instance__c, Instance__r.Start_Date__c, Instance__r.Paper__c FROM Booking__c WHERE Student__c IN :studentIds AND Status__c = 'Confirmed'];

        for (Id student : studentIds) {
            List<Booking__c> studentBookings = new List<Booking__c>();
            for (Booking__c booking : bookingList) {
                if (student == booking.Student__c) {
                    studentBookings.add(booking);
                }
            }
            previouslyConfirmedBookingsMap.put(student, studentBookings);
        }
        
        Integer row = 1;
        /* END OF - Changes made by David Lovejoy */
        for (Object primaryListItem : primaryList) {
            Boolean hubAccountFound = false;
            List<Object> secondaryList = (List<Object>) primaryListItem;
            Booking__c bookingItem = new Booking__c();
            bookingItem.Student__c = secondaryList.get(0) != null ? String.valueOf(secondaryList.get(0)).trim() : null; 
            bookingItem.Hub_Account__c = secondaryList.get(1) != null && String.valueOf(secondaryList.get(1)).length() > 0 ? String.valueOf(secondaryList.get(1)).trim() : null;
            bookingItem.Instance__c = secondaryList.get(2) != null ? String.valueOf(secondaryList.get(2)) : null; 
           	bookingItem.Order__c = secondaryList.get(3) != null ? String.valueOf(secondaryList.get(3)) : null; 
            bookingItem.PO_Number__c = secondaryList.get(4) != null ? String.valueOf(secondaryList.get(4)) : null; 
            bookingItem.Status__c = secondaryList.get(5) != null ? String.valueOf(secondaryList.get(5)) : null; 
            /* START OF - Changes made by David Lovejoy - 16/12/2020 - BPP-11720 */
            if (bookingItem.Status__c == 'On Hold') {
                bookingItem.On_Hold_Reason__c = secondaryList.get(6) != null ? String.valueOf(secondaryList.get(6)) : null; 
            }
            /* END OF - Changes made by David Lovejoy */
            /* START OF - Changes made by Prema Medasani - 26/02/2021 - BPP-12994 */
            if (String.valueOf(secondaryList.get(7)) != null && String.valueOf(secondaryList.get(7)) == 'true') {
                bookingItem.Pass_Assurance__c = true;
            } else if (String.valueOf(secondaryList.get(7)) != null && String.valueOf(secondaryList.get(7)) == 'false') {
                bookingItem.Pass_Assurance__c = false;
            }
                /* START OF - Changes made by Upender Nelluri - 22/06/2021 - BPP-15491 */
            if (secondaryList.size() > 8) { 
                bookingItem.CBA__c  = secondaryList.get(8) != null ? String.valueOf(secondaryList.get(8)) : null; 
                bookingItem.Institute_Number__c  = secondaryList.get(9) != null ? String.valueOf(secondaryList.get(9)) : null;
                bookingItem.RecordTypeId  = RecordTypeIdCBA;
            }
                /* END OF - Changes made by Upender Nelluri */

            /* END OF - Changes made by Prema Medasani */
            
            if (bookingItem.Student__c != null && bookingItem.Instance__c != null && bookingItem.Order__c != null) {
                Instance__c instance = instanceMap.get(String.valueOf(secondaryList.get(2)));
                Order order = orderMap.get(String.valueOf(secondaryList.get(3)));
                Id bookingRecordTypeId  = bookingItem.RecordTypeId != null ? String.valueOf(bookingItem.RecordTypeId) : null;
                Boolean validInstanceAssignement = InstanceAssignmentValidityChecker.isValidInstanceAssignment(instance,order.OrderItems,bookingRecordTypeId);
                
                /* START OF - Changes made by Prema Medasani - 01/03/2021 - BPP-13388 */
                if (orderMap.get(bookingItem.Order__c).Status != 'Activated') {
                    inactiveOrders.add('Booking Creator row: ' + row + ' - The Order '+order.Id+' has not been activated. Bookings can only be made against Active Orders.');
                } else if (validInstanceAssignement) {
                    bookingLines.add(bookingItem);
                } else {
                    invalidInstances.add('Booking Creator row: ' + row + ' - The course from the Instance: ' + instance.Id + ' you are booking onto for Student: ' + bookingItem.Student__c + ' has not been sold on the Order: ' + order.Id + '.');
                }
                /* END OF - Changes made by Prema Medasani */

                /* START OF - Changes made by David Lovejoy - 07/09/2021 - BPP-13028 */
                String dupe = 'Booking Creator row: ' + row + ' - Student (' + bookingItem.Student__c + ') has potential duplicate Booking(s) that match Instance ' + instance.Id + ':';
                for (Booking__c booking : previouslyConfirmedBookingsMap.get(bookingItem.Student__c)) {
                    if (instance.Id == booking.Instance__c && instance.Paper__c == booking.Instance__r.Paper__c && instance.Start_Date__c == booking.Instance__r.Start_Date__c) {
                        System.debug('@BookingCreatorExt Duplicate Booking criteria hit');
                        dupe += '<br/>Booking: ' + booking.Name + ' (' + booking.Id + ')';
                    }
                }
                dupe += '<br/>Should this be an intentional duplicate, you will need to key this Booking manually in Salesforce.';
                if (dupe.contains('Booking: ')) {
                    duplicateBookings.add(dupe);
                }
                /* END OF - Changes made by David Lovejoy */
            } else {
                noErrors = false;
                nullFields.add('Booking Creator row: ' + row + ' - Null fields: ' + bookingItem + '.');
            }
            row++;
        }
        return checkInstanceCapacity(bookingLines);
    }

    private List<Booking__c> checkInstanceCapacity(List<Booking__c> bookingLines) {
        Map<Id, List<Booking__c>> instanceToBooking = new Map<Id, List<Booking__c>>();
        
        for (Booking__c bookingLineItem : bookingLines) {
            if (!instanceToBooking.containsKey(bookingLineItem.Instance__c)) {
                instanceToBooking.put(bookingLineItem.Instance__c, new List<Booking__c>{bookingLineItem});
            } else {
                instanceToBooking.get(bookingLineItem.Instance__c).add(bookingLineItem);
            }
        }

        Map<Id, Instance__c> queriedInstances = new Map<Id, Instance__c>([SELECT Id, Availability__c FROM Instance__c WHERE Id IN :instanceToBooking.keySet()]);
        List<Booking__c> bookingsToInsert = new List<Booking__c>();

        for (Id instanceId : instanceToBooking.keySet()) {
            Integer bookingSize = instanceToBooking.get(instanceId).size();
            if (queriedInstances.containsKey(instanceId)) {
                System.debug('Instance Availability: ' + queriedInstances.get(instanceId).Availability__c);
                System.debug('Booking Size: ' + bookingSize);

                if (bookingSize > queriedInstances.get(instanceId).Availability__c) {
                    noErrors = false;
                    for (Booking__c bookingLineItem : instanceToBooking.get(instanceId)) {
                        overbookedInstances.add('Booking Capacity reached for instance: ' + instanceId + '. The following bookings have not been imported: <br/><br/>' + bookingLineItem + '<br/><br/>');
                    }
                } else {
                    bookingsToInsert.addAll(instanceToBooking.get(instanceId));
                }
            }
        }
        return bookingsToInsert;
    }
    
    /**
    *  Checks for insert errors and adds to list of errors
    *
    *  @param List<Spec_Line__c> specLines           Spec lines to associate error to
    *  @param List<Database.SaveResult> results      Save results to check for errors
    */
    private void checkErrors(List<Booking__c> bookingLines, List<Database.SaveResult> results) {
        for (Integer i = 0; i <= results.size() - 1; i++) {
            Database.SaveResult sr = results.get(i);
            Booking__c currentBooking = bookingLines.get(i);

            if (!sr.isSuccess()) {
                for (Database.Error err : sr.getErrors()) {
                    saveErrors.add(currentBooking + ': ' + err.getStatusCode() + ': ' + err.getMessage() + '<br/><br/>');
                }
            }
        }
    }

    /**
    *  Builds and sends email to send error report
    */
    private void buildEmail() {
        String userName = UserInfo.getUserName();
        User activeUser = [Select FirstName, Email From User where Username = : userName limit 1];

        Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
        message.toAddresses = new String[] {String.valueOf(activeUser.Email)};
        message.setCcAddresses(ccAddresses);
        message.subject = 'Booking Import Error';
        
        String body = 'Dear ' + activeUser.FirstName + ', <br/><br/>' + 'There has been an issue importing the following bookings: <br/><br/>';

        if (!nullFields.isEmpty()) {
            for(String error : nullFields){
                body += error + '<br/>';
            }
            body += '<br/>';
        }
        
        if (!overbookedInstances.isEmpty()) {
            for (String error : overbookedInstances) {
                body += error + '<br/>';
            }
            body += '<br/>';
        }
        
        if (!invalidInstances.isEmpty()) {
            for (String error : invalidInstances) {
                body += error + '<br/>';
            }
            body += '<br/>';
        }
       
		if (!inactiveOrders.isEmpty()) {
            for (String error : inactiveOrders) {
                body += error + '<br/>';
            }
            body += '<br/>';
        }

        if (!duplicateBookings.isEmpty()) {
            for (String error : duplicateBookings) {
                body += error + '<br/>';
            }
            body += '<br/>';
        }
		
        if (!saveErrors.isEmpty()) {
            for (String error : saveErrors) {
                body += error + '<br/>';
            }
            body += '<br/>';
        }
        
        body += '<br/><br/>Kind Regards, <br/> Salesforce Admin';
        message.setHtmlBody(body);

        Messaging.SingleEmailMessage[] messages = new List<Messaging.SingleEmailMessage> {message};
        messagesSent++;
        System.debug('messages: '+messages);
        if (!Test.isRunningTest()) {
            Messaging.SendEmailResult[] results = Messaging.sendEmail(messages);
        }
    }
}