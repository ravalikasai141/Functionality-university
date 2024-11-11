/*
* @who   Patrick Duncan <patrick.duncan@weare4c.com>
* @what  Class for creating booking lines from booking trigger
* @when  14/1/2020
*/
public with sharing class BookingLineGenerator {
    
    private Map<Id,Order> orderMap;
    private Map<Id,Booking__c> bookingMap;
    private Map<Id,Instance__c> instanceMap;
    private List<BookingLineWrapper> bookingLineWrappers;
    static Id RecordTypeIdMB = Schema.SObjectType.Booking__c.getRecordTypeInfosByName().get('Material or Fee Booking').getRecordTypeId();
    static Id RecordTypeIdCBA = Schema.SObjectType.Booking__c.getRecordTypeInfosByName().get('CBA Booking').getRecordTypeId();
    
    public BookingLineGenerator(Map<Id,Booking__c> bookingMap) {
        this.bookingMap = bookingMap;
        this.bookingLineWrappers = new List<BookingLineWrapper>();
    }
    
    /*
    *  @description    Main Method for creating booking lines
    *  @param  bookingMap           Map of booking Id -> booking
    */
    public void generateBookingLines(Map<Id,Booking__c> bookingMap) {
        getOrderMap();
        getInstanceMap();
        getStubBookingWrappersAndOrderLineIds();
        decorateWrapperAndAddStartAndEndDatesToBookingLineItems();
        saveBookingLines(bookingMap);
    }
    
    /*
    *  @description    Main Method for deleting booking lines
    */
    public void deleteBookingLines() {
        delete [SELECT Id FROM Booking_Line__c WHERE Booking__c IN :this.bookingMap.keySet()];
    }
    
    /*
    *  @description    Method for building a map of order Id -> order
    */
    private void getOrderMap() {
        Map<String,String> orderIds = (Map<String,String>) SObjectUtil.getFieldValuesFromSObjectMap(this.bookingMap.values(),'Order__c','RecordTypeId');
        List<String> order = new List<String>();
        List<String> materialOrder = new List<String>();
        List<String> cbaOrder = new List<String>();
        System.debug('************orderIds' + orderIds);
        for (String oId: orderIds.keyset()) {
            System.debug('***********orderIds.get(oId)' + orderIds.get(oId));
            if (RecordTypeIdMB == orderIds.get(oId)) {
                materialOrder.add(oId);
            } else if ( RecordTypeIdCBA == orderIds.get(oId)) {
                cbaOrder.add(oId);
            } else {
                order.add(oId);
            }
        }
        System.debug('*******order'+ order);
        System.debug('*******materialOrder'+ materialOrder);
        System.debug('*******cbaOrder'+ cbaOrder);
        if (order.size() > 0) {
            this.orderMap = queryOrdersWithOrderLines(order);
        }
        if (materialOrder.size() > 0) {
            this.orderMap = queryOrdersWithOrderLinesMB(materialOrder);
        }
        if (cbaOrder.size() > 0) {
            this.orderMap = queryOrdersWithOrderLinesCBA(cbaOrder,bookingMap);
        }
        
    }
    
    /*
    *  @description    Queries for orders and child order lines whose Id is in List
    *  @param  orderIds     List of order ids
    */
    private Map<Id,Order> queryOrdersWithOrderLines(List<String> orderIds) {
        System.debug('*********queryOrdersWithOrderLines');
        return new Map<Id,Order>([
            SELECT AccountId, Account.IsPersonAccount, Account.Charge_Trigger__c, Name, OrderNumber, Order.Account.RecordTypeId, Ship_To_Address__c, Shipping_Address_Country__r.Name, ShippingStreet, ShippingCity, 
            ShippingPostalCode, Shipping_Address_Country__c, Ship_To_Address__r.Id, Deliver_Materials_to_Student__c, 
            (SELECT Product2.Family__c, UnitPrice, SBQQ__RequiredBy__r.Product2.Name, SBQQ__RequiredBy__r.Product2Id, Family__c, OrderItemNumber, Product2.Name, SBQQ__QuotedQuantity__c
            FROM OrderItems WHERE SBQQ__RequiredBy__c != NULL)
            FROM Order WHERE Id IN :orderIds
        ]);
    }
    
    private Map<Id,Order> queryOrdersWithOrderLinesMB(List<String> orderIds) {
        System.debug(' *******queryOrdersWithOrderLinesMB');
        return new Map<Id,Order>([
            SELECT AccountId, Account.IsPersonAccount, Account.Charge_Trigger__c, Name, OrderNumber, Order.Account.RecordTypeId, Ship_To_Address__c, Shipping_Address_Country__r.Name, ShippingStreet, ShippingCity, 
            ShippingPostalCode, Shipping_Address_Country__c, Ship_To_Address__r.Id, Deliver_Materials_to_Student__c, 
            (SELECT Product2.Family__c, UnitPrice, SBQQ__RequiredBy__r.Product2.Name, SBQQ__RequiredBy__r.Product2Id, Family__c, OrderItemNumber, Product2.Name, SBQQ__QuotedQuantity__c
            FROM OrderItems) 
            FROM Order WHERE Id IN :orderIds
        ]);
    }
    
    private Map<Id,Order> queryOrdersWithOrderLinesCBA(List<String> orderIds, Map<Id,Booking__c> bookingMap) {
        Id cbaProduct;
        String Name;
        Set<Id> cbaIdSet = new set<Id>();
        Set<Id> productIdSet = new Set<Id>();
        System.debug('*********bookingMap' +bookingMap);
        for (Booking__c booking : bookingMap.values()) {
            cbaIdSet.add(booking.CBA__c);
        }
        
        for (CBA__c cba : [SELECT Id,name,Product__c FROM CBA__c WHERE Id IN : cbaIdSet]) {
            productIdSet.add(cba.product__C);
        }
        
        System.debug('*********product ids' + productIdSet);
        return new Map<Id,Order>([
            SELECT AccountId, Account.IsPersonAccount, Account.Charge_Trigger__c, Name, OrderNumber, Order.Account.RecordTypeId, Ship_To_Address__c, Shipping_Address_Country__r.Name, ShippingStreet, ShippingCity, 
            ShippingPostalCode, Shipping_Address_Country__c, Ship_To_Address__r.Id, Deliver_Materials_to_Student__c, 
            (SELECT Product2.Family__c, UnitPrice, SBQQ__RequiredBy__r.Product2.Name, SBQQ__RequiredBy__r.Product2Id, Family__c, OrderItemNumber, Product2.Name, SBQQ__QuotedQuantity__c
            FROM OrderItems WHERE Product2Id IN :productIdSet)
            FROM Order WHERE Id IN :orderIds
        ]);
    }
    
    /*
    *  @description    Method for building a map of order line -> booking line wrapper by creating booking line wrappers
    */
    private void getStubBookingWrappersAndOrderLineIds() {
        Map<OrderItem, List<BookingLineWrapper>> orderLineToBookingLineWrappersMap = new Map<OrderItem, List<BookingLineWrapper>>();
        Map<Id, Product2> productsAllowMap = new Map<Id, Product2>([SELECT Id FROM Product2 WHERE (Name LIKE 'Binder - A4 Course%' OR Name LIKE 'VLE - Virtual%')]);
        System.debug('productsAllowMap======================' + productsAllowMap.keySet());
        for (Booking__c booking : this.bookingMap.values()) {
            Set<Id> uniqueProductIdSet = new Set<Id>();
            Order order = this.orderMap.get(booking.Order__c);
            Instance__c instance = (booking.Instance__c != null ? this.instanceMap.get(booking.Instance__c) : null);
            System.debug('Booking: ' + booking);
            System.debug('booking.Order__c: ' + booking.Order__c);
            System.debug('OrderMap: ' + this.orderMap);
            System.debug('Order: ' + order);
            System.debug('Number of Order Products: ' + order.OrderItems.size());
            System.debug('Instance: ' + instance);
            for (OrderItem orderProduct : order.OrderItems) {
                if (productsAllowmap.containsKey(orderProduct.product2Id) || !uniqueProductIdSet.contains(orderProduct.product2Id)) {
                    if (orderProduct.SBQQ__RequiredBy__c != NULL && instance != null && orderProduct.SBQQ__RequiredBy__r.Product2Id != instance.Product__c) {
                        System.debug('@BookingLineGenerator: Order Product - Not unique (skipping): ' + orderProduct);
                        continue;
                    } else {
                        System.debug('@BookingLineGenerator: Order Product - Unique (creating Booking Line): ' + orderProduct);
                        uniqueProductIdSet.add(orderProduct.product2Id);
                        addNewBookingWrapperStub(order, booking, orderProduct);
                    }
                }
            }
        }
    }
    
    private void addNewBookingWrapperStub(Order order, Booking__c booking, OrderItem orderLine) {
        Booking_Line__c bookingLine = new Booking_Line__c(
            blng_Account__c = order.AccountId, Booking__c = booking.Id, Student__c = booking.Student__c, blng_OrderProduct__c = orderLine.Id, Instance__c = booking.Instance__c,
            blng_Order__c = booking.Order__c, blng_PreratedAmount__c = orderLine.UnitPrice, On_Hold__c = booking.Status__c, PO_Number__c = booking.PO_Number__c, 
            Product_Family__c = orderLine.Family__c, CBA__c = booking.CBA__c,Quantity__c = 1, Charge_Trigger__c = order.Account.Charge_Trigger__c
        );
        bookingLine.BPP_Is_Material_Booking__c = (booking.RecordTypeId == RecordTypeIdMB && (bookingLine.Product_Family__c == 'Materials' || bookingLine.Product_Family__c.contains('Fee')));
        this.bookingLineWrappers.add(new BookingLineWrapper(bookingLine, booking, orderLine));
        System.debug('@BookingLineGenerator Creating new booking line: ' + bookingLine);
    }
    
    /*
    *  @description    Method for building a map of booking -> instance
    */
    private void getInstanceMap() {
        List<String> instanceIds = (List<String>) SObjectUtil.getFieldValuesFromSObjectList(this.bookingMap.values(),'Instance__c');
        this.instanceMap = queryInstances(instanceIds);
    }
    
    /*
    *  @description   method for querying all instances whose Id is within a List
    *  @param   List of instance ids
    *
    */
    private Map<Id,Instance__c> queryInstances(List<String> instanceIds) {
        return new Map<Id,Instance__c>([
            SELECT Product__c, Product__r.Name, Start_Date__c, End_Date__c, Instance_Name__c, Name, BPP_Instance_Status__c, 
            (SELECT Session_Date__c, Session_Product__c, Start_Time__c, End_Time__c FROM Sessions__r) 
            FROM Instance__c WHERE Id IN :instanceIds
        ]);
    }
    
    /*
    *  @description    Method for populating the start/end dates and a few other fields on each booking line
    */  
    private void decorateWrapperAndAddStartAndEndDatesToBookingLineItems() {
        List<Booking_Line__c> bookingLineList = new List<Booking_Line__c>();
        for (BookingLineWrapper bookingLineWrapper:this.bookingLineWrappers) {
            setInstanceOnWrapper(bookingLineWrapper);

            Booking_Line__c bookingLine = bookingLineWrapper.bookingLine;
            Booking__c booking = bookingLineWrapper.booking;
            Instance__c instance = bookingLineWrapper.instance;
            OrderItem orderProduct = bookingLineWrapper.orderLine;
            setBookingLineBillingValues(bookingLine, booking, instance, orderProduct);
            bookingLineWrapper.complete = true;

            bookingLineList.add(bookingLine);
        }
        setBookingLineUsageSummaryMatchingId(bookingLineList, this.orderMap.keySet());
    }
    
    /*
    *  @description    Method for finding the correct instance for a wrapper and setting it on the object
    */
    private void setInstanceOnWrapper(BookingLineWrapper bookingLineWrapper) {
        bookingLineWrapper.instance = this.instanceMap.get(bookingLineWrapper.booking.Instance__c);
    }
    
    public static void setBookingLineBillingValues(Booking_Line__c bookingLine, Booking__c booking, Instance__c instance, OrderItem orderProduct) {
        String bookingType = checkBookingType(bookingLine, booking, instance, orderProduct);
        Date sessionDate;
        if ((bookingType == 'Booking' && bookingLine.Product_Family__c == 'Session') || bookingType == 'CBA') {
            sessionDate = setBookingLineSession(bookingLine, instance, orderProduct, bookingType);
        }
        
        if (booking.Status__c == 'Confirmed' || Test.isRunningTest()) {
            DateTime bookingConfirmedDate = (booking.Booking_Confirmed_Date__c != null ? booking.Booking_Confirmed_Date__c : System.now());
            Date instanceStartDate = (instance != null && instance.Start_Date__c != null ? instance.Start_Date__c : null);
            setBookingLineStartAndEndDate(bookingLine, booking.RecordTypeId, instanceStartDate, bookingConfirmedDate);
            setBookingLineRevRecDate(bookingLine, booking.CreatedDate, instanceStartDate, bookingConfirmedDate, sessionDate);
        }
    }

    public static String checkBookingType (Booking_Line__c bookingLine, Booking__c booking, Instance__c instance, OrderItem orderProduct) {
        String bookingType;
        if (booking.RecordTypeId != RecordTypeIdMB && booking.RecordTypeId != RecordTypeIdCBA) {
            bookingType = 'Booking';
        } else if (booking.RecordTypeId == RecordTypeIdMB && (bookingLine.Product_Family__c == 'Materials' || bookingLine.Product_Family__c.contains('Fee'))) {
            bookingType = 'Material Booking';
        } else if (booking.RecordTypeId == RecordTypeIdCBA && bookingLine.Product_Family__c == 'Exam') {
            bookingType = 'CBA';
        }
        return bookingType;
    }

    public static void setBookingLineStartAndEndDate(Booking_Line__c bookingLine, Id bookingRecordType, Date instanceStartDate, DateTime bookingConfirmedDate) {
		DateTime bookingLineStartEndDateTimeSession;
        bookingConfirmedDate = (bookingConfirmedDate != null ? bookingConfirmedDate : System.now());
        if (bookingLine.Charge_Trigger__c == 'Booking Confirmed Date') {
            bookingLine.blng_StartDateTime__c = bookingConfirmedDate;
            bookingLine.blng_EndDateTime__c = bookingConfirmedDate;
        } else {
            if (bookingRecordType != RecordTypeIdMB && instanceStartDate != null) {
                bookingLineStartEndDateTimeSession = (instanceStartDate < datetime.now() ? bookingConfirmedDate : instanceStartDate);
            }
            bookingLine.blng_StartDateTime__c = (bookingLineStartEndDateTimeSession != null ? bookingLineStartEndDateTimeSession : bookingConfirmedDate);
            bookingLine.blng_EndDateTime__c = (bookingLineStartEndDateTimeSession != null ? bookingLineStartEndDateTimeSession : bookingConfirmedDate);
        }
    }

    public static Date setBookingLineSession(Booking_Line__c bookingLine, Instance__c instance, OrderItem orderProduct, String bookingType) {
        Session__c session = getSessionFromInstance(instance, orderProduct, bookingType);
        if (session != null) {
            bookingLine.Session__c = session.Id;
            return session.Session_Date__c;
        }
        return null;
    }

    public static void setBookingLineRevRecDate(Booking_Line__c bookingLine, DateTime bookingCreatedDate, Date instanceStartDate, DateTime bookingConfirmedDate, Date sessionDate) {
		Date revRecDate;
        bookingConfirmedDate = (bookingConfirmedDate != null ? bookingConfirmedDate : System.now());
		if (sessionDate != null) {
			revRecDate = (sessionDate < Date.today() ? Date.valueOf(bookingConfirmedDate) : sessionDate);
		} else if (instanceStartDate != null) {
			revRecDate = (instanceStartDate < datetime.now() ? Date.valueOf(bookingCreatedDate) : instanceStartDate);
		} else {
			revRecDate = Date.valueOf(bookingCreatedDate);
		}
		bookingLine.Rev_Rec_Date__c = revRecDate;
    }
     
    public static Session__c getSessionFromInstance(Instance__c instance, OrderItem orderLine, String bookingType) {
        for (Session__c session : instance.Sessions__r) {
            if (bookingType == 'Booking') {
                if (session.Session_Product__c == orderLine.Product2Id) {
                    return session;
                }
            } else {
                return session;
            }
        }
        return null;
    }

    public static void setBookingLineUsageSummaryMatchingId(List<Booking_Line__c> bookingLineList, Set<Id> orderIds) {
        List<blng__UsageSummary__c> usageSummaryList = [SELECT blng__OrderProduct__c, blng__SummaryStartDate__c, blng__SummaryEndDate__c, blng__MatchingId__c FROM blng__UsageSummary__c WHERE blng__Order__c IN: orderIds];
		
        Map<Id, List<blng__UsageSummary__c>> orderProductUsageSummaryMap = createOrderProductUsageSummaryMap(usageSummaryList);
        for (Booking_Line__c bookingLine : bookingLineList) {
            if ((bookingLine.Booking__r.Status__c == 'Confirmed' || bookingLine.On_Hold__c == 'Confirmed' && !orderProductUsageSummaryMap.isEmpty())) {
                for (blng__UsageSummary__c usageSummary : orderProductUsageSummaryMap.get(bookingLine.blng_OrderProduct__c)) {
                    if (usageSummary.blng__SummaryStartDate__c <= (bookingLine.blng_StartDateTime__c).date() && 
                        usageSummary.blng__SummaryEndDate__c >= (bookingLine.blng_EndDateTime__c).date()) {
                        bookingLine.blng_UsageSummary__c = usageSummary.Id;
                        bookingLine.blng_MatchingId__c = usageSummary.blng__MatchingId__c;
                        break;
                    }
                }
            }
        }
    }
    
    /*
    *  @description    Method for inserting the booking lines if they are completed
    */
    private void saveBookingLines(Map<Id,Booking__c> bookingMap) {
        /* START OF - Changes made by David Lovejoy - 29/03/2021 - BPP-13044 */
        List<Booking_Line__c> completeBookingLines = getCompleteBookingLines();
        List<Booking__c> bookingList = new List<Booking__c>();
        List<Order> orderList = new List<Order>();
        Set<Id> invalidBookingIds = new Set<Id>();
        Set<Id> materialBookingIds = new Set<Id>();
        Set<Id> orderIds = new Set<Id>();
        Boolean errorFound = false;
        
        for (Booking_Line__c bookingLine : completeBookingLines) {
            String error;
            if (bookingLine.Product_Family__c == 'Materials') {
                Booking__c booking = bookingMap.get(bookingLine.Booking__c);
                Order order = this.orderMap.get(booking.Order__c);
                if (order.Ship_To_Address__c == NULL && ((order.Account.IsPersonAccount) || (!order.Account.IsPersonAccount && !order.Deliver_Materials_to_Student__c))) {
                    error = 'The Order ' + order.OrderNumber + ' (' + order.AccountId + ') does not have a delivery address associated with it. Please update the Ship To Address field on this Order.';
                }
                if (order.Ship_To_Address__c != NULL && order.Shipping_Address_Country__r.Name != 'United Kingdom' && booking.BPP_Student_Phone_Number__c == NULL) {
                    error = booking.BPP_Student_Name__c + '\'s Account (' + booking.Student__c + ') does not have a phone number; this is required for an International Booking. Please add a phone number on this Account.';
                }
                if (error != null) {
                    errorFound = TRUE;
                    booking.addError(error);
                }
            }
        }

        if (!errorFound) {
            insert completeBookingLines;
        }
    }
    
    /*
    *  @description    Method for getting all the complete booking lines
    */
    private List<Booking_Line__c> getCompleteBookingLines() {
        List<Booking_Line__c> completeBookingLines = new List<Booking_Line__c>();
        for (BookingLineWrapper bookingLineWrapper:this.bookingLineWrappers) {
            if (bookingLineWrapper.complete) {
                completeBookingLines.add(bookingLineWrapper.bookingLine);
            }
        }
        return completeBookingLines;
    }
    
    public static Map<Id, List<blng__UsageSummary__c>> createOrderProductUsageSummaryMap(List<blng__UsageSummary__c> usageSummaryList) {
        Map<Id, List<blng__UsageSummary__c>> orderProductUsageSummaryMap = new Map<Id, List<blng__UsageSummary__c>>();
            for (blng__UsageSummary__c usageSummary : usageSummaryList) {
                List<blng__UsageSummary__c> recordsForMap = orderProductUsageSummaryMap.get(usageSummary.blng__OrderProduct__c);
                if (recordsForMap == null) {
                    recordsForMap = new List<blng__UsageSummary__c>();
                    orderProductUsageSummaryMap.put(usageSummary.blng__OrderProduct__c, recordsForMap);
                }    
                recordsForMap.add(usageSummary);
            }
        return orderProductUsageSummaryMap;
    }
    
    //Inner class for storing booking lines and other fields
    private class BookingLineWrapper {
        private Booking_Line__c bookingLine;
        private Booking__c booking;
        private OrderItem orderLine;
        private Instance__c instance;
        private Boolean complete;
        
        private BookingLineWrapper(Booking_Line__c bookingLine, Booking__c booking, OrderItem orderLine) {
            this.bookingLine = bookingLine;
            this.booking = booking;
            this.orderLine = orderLine;
            this.instance = instance;
            this.complete = false;
        }
    }
}