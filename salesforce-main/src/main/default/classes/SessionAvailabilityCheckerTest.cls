/*
* @who   Patrick Duncan <patrick.duncan@weare4c.com>
* @what  Test class for SessionAvailabilityChecker
* @when  14/1/2020
*/
@isTest
private class SessionAvailabilityCheckerTest {

    @testSetup
    static void testSetup(){
        Authorisation_Token__c authToken = TestDataFactory.createAuthorisationToken(TRUE);
        blng__BillingRule__c billingRule = TestDataFactory.createBillingRule(true);
        blng__FinanceBook__c billingFinanceBook = TestDataFactory.createBillingFinanceBook(true);
        blng__RevenueRecognitionRule__c revenueRecognitionRule = TestDataFactory.createRevenueRecognitionRule(true);
        blng__TaxRule__c taxRule = TestDataFactory.createTaxRule(true);

        List<Product2> products = new List<Product2>();
        for (Integer i=0;i<5;i++) {
            products.add(TestDataFactory.createProduct(false,i,billingRule,revenueRecognitionRule,taxRule));
        }
        insert products;

        List<Instance__c> instances = new List<Instance__c>();
        for (Integer i=0;i<5;i++) {
            instances.add(TestDataFactory.createInstance(false,i,products.get(i)));
        }
        insert instances;

        List<Session__c> sessions = new List<Session__c>();
        for (Integer i=0;i<5;i++) {
            for (Integer j=0;j<5;j++) {
                sessions.add(TestDataFactory.createSession(false,(i*10)+j,instances.get(i),products.get(j),0,5));
            }
        }
        insert sessions;
        
        Database.DMLOptions dbDML = new Database.DMLOptions(); 
        dbDML.DuplicateRuleHeader.allowSave = true;
        dbDML.DuplicateRuleHeader.runAsCurrentUser = true;

        List<Account> accounts = new List<Account>();
        for(Integer i=0;i<5;i++){
            accounts.add(TestDataFactory.createAccount(false,false,null,i));
        }
        Database.insert(accounts, dbDML);
        
        List<Account> students = new List<Account>();
        for(Integer i=0;i<5;i++){
            students.add(TestDataFactory.createAccount(false,true,accounts.get(i).Id,i));
        }
        Database.insert(students, dbDML);
        
        /* START OF - Changes made by David Lovejoy - 06/11/2020 - BPP-10399/10510 */
        country_list__c cntry = new country_list__c(Name = 'United Kingdom', ISO_Code__c = 'GBR', country_code_2__c = 'GB');
        insert cntry;

        List<Address__c> addresses = new List<Address__c>();
        for (Integer i=0;i<5;i++) {
            addresses.add(TestDataFactory.createAddress(false,i,accounts.get(i),cntry,true,false));
        }
        Database.insert(addresses, dbDML);

        List<Order> orders = new List<Order>();
        for (Integer i=0;i<5;i++) {
            orders.add(TestDataFactory.createOrder(false,i,accounts.get(i),null,addresses.get(i)));
        }
        insert orders;
        /* END OF - Changes made by David Lovejoy */

        List<PricebookEntry> priceBookEntries = new List<PricebookEntry>();
        for (Integer i=0;i<5;i++) {
            priceBookEntries.add(TestDataFactory.createPricebookEntry(false,products.get(i),null));
        }
        insert priceBookEntries;

        
        List<OrderItem> parentOrderLines = new List<OrderItem>();
        for (Integer i=0;i<5;i++) {
            parentOrderLines.add(TestDataFactory.createOrderLine(false,orders.get(i),products.get(i),null,priceBookEntries.get(i),billingRule,revenueRecognitionRule,taxRule,''));
        }
        insert parentOrderLines;
        
        List<OrderItem> orderLines = new List<OrderItem>();
        for (Integer i=0;i<5;i++) {
            for (Integer j=0;j<5;j++) {
                orderLines.add(TestDataFactory.createOrderLine(false,orders.get(i),products.get(j),parentOrderLines.get(i),priceBookEntries.get(j),billingRule,revenueRecognitionRule,taxRule,'Session'));
            }
        }
        insert orderLines;
        
        List<blng__UsageSummary__c> usageSummaries = new List<blng__UsageSummary__c>();
        for (Integer i = 0; i < orderLines.size(); i++) {
            usageSummaries.add(TestDataFactory.createBookingSummary(false, orderLines.get(i)));
        }
        insert usageSummaries;
        
        for (Order ord:orders) {
            ord.Status = 'Activated';
        }
        update orders;

        List<Booking__c> bookings = new List<Booking__c>();
        /* END OF - Changes made by Prema Medasani */
        for (Integer i=0;i<5;i++) {
            for (Integer j=0;j<3;j++) {
                bookings.add(TestDataFactory.createBooking(false,instances.get(i),orders.get(i),students.get(i)));
            }
        }
        insert bookings;
    }
    
    /*
    * @method checkBookingInstanceReassignmentAvailability
    * @case when inserting 3 bookings onto each instance, with each session on each instance having a capacity of 5
    * @result expect the availability of the instance to be 5 - 3 = 2
    */
    @isTest
    static void test_InstanceAvailability() {
       List<Instance__c> instances = [SELECT Id, Availability__c FROM Instance__c ORDER BY Name ASC];
       System.debug('@@@instances -- 1@@@'+instances);
       for(Instance__c instance:instances){
            System.assertEquals(2, instance.Availability__c);
       }
    }

    /*
    * @method checkBookingInstanceReassignmentAvailability
    * @case when updating the instance on 2 bookings assigned to instance 0, to instance 1
    * @result expect the availability of the deassigned instance to be 2 + 2 = 4 and the assigned instance to be 2 - 2 = 0
    */
    @isTest
    static void test_SuccessfulBookingReassign() {
       List<Instance__c> instances = [SELECT Id, Availability__c FROM Instance__c ORDER BY Name ASC];
       System.debug('@@@instances -- 2222@@@'+instances);
        List<Booking__c> bookingsToReassign = [SELECT Id FROM Booking__c WHERE Instance__c = :instances.get(0).Id];
        for(Integer i=0;i<2;i++){
                bookingsToReassign.get(i).Instance__c = instances.get(1).Id;
        }
        Test.startTest();
            update bookingsToReassign;
        Test.stopTest();

        List<Instance__c> deassignedInstance = [SELECT Availability__c FROM Instance__c WHERE Id = :instances.get(0).Id];
        List<Instance__c> assignedInstance = [SELECT Availability__c FROM Instance__c WHERE Id = :instances.get(1).Id];

        System.assertEquals(4, deassignedInstance.get(0).Availability__c);
        System.assertEquals(0, assignedInstance.get(0).Availability__c);
    }
    
    /*
    * @method checkBookingInstanceReassignmentAvailability
    * @case when updating the instance on 3 bookings assigned to instance 0, to instance 1 and 2 bookings assigned to instance 1, to instance 2
    * @result expect the availability of instance 0 to be 2 + 3 = 5, availability of instance 1 to be 2 + 2 - 3 = 1 and instance 2 to be 2 - 2 = 0 
    */
    /* START OF - Changes made by Prema Medasani - 16/12/2020 - BPP-12124 - Soql Issue for Deployment */
   /* @isTest
    static void test_SuccessfulBookingReassign_2() {
        Test.startTest();
        List<Instance__c> instances = [SELECT Id, Availability__c FROM Instance__c ORDER BY Name ASC];
        List<Booking__c> bookingsToReassignToInstanceOne = [SELECT Id FROM Booking__c WHERE Instance__c = :instances.get(0).Id];
        //List<Booking__c> bookingsToReassignToInstanceTwo = [SELECT Id FROM Booking__c WHERE Instance__c = :instances.get(1).Id];

        for(Integer i=0;i<3;i++){
        bookingsToReassignToInstanceOne.get(i).Instance__c = instances.get(1).Id;
        }
        //for(Integer i=0;i<2;i++){
        //bookingsToReassignToInstanceTwo.get(i).Instance__c = instances.get(2).Id;
        //}

        List<Booking__c> allBookingsToReassign = bookingsToReassignToInstanceOne;
        //allBookingsToReassign.addAll(bookingsToReassignToInstanceTwo);
        
        
            update allBookingsToReassign;
        Test.stopTest();

        List<Instance__c> instanceZero = [SELECT Availability__c FROM Instance__c WHERE Id = :instances.get(0).Id];
        List<Instance__c> instanceOne = [SELECT Availability__c FROM Instance__c WHERE Id = :instances.get(1).Id];
        //List<Instance__c> instanceTwo = [SELECT Availability__c FROM Instance__c WHERE Id = :instances.get(2).Id];


        System.assertEquals(5, instanceZero.get(0).Availability__c);
        System.assertEquals(1, instanceOne.get(0).Availability__c);
        //System.assertEquals(0, instanceTwo.get(0).Availability__c);
    }*/
    /* END OF - Changes made by Prema Medasani */

    /*
    * @method checkBookingInstanceReassignmentAvailability
    * @case when updating the instance on 3 bookings assigned to instance 0, to instance 1
    * @result expect the a custom validation error to have been thrown, as the maximum capacity of the instance's session has been exceeded 
    */
    @isTest
    static void test_OverassignBookings() {
        List<Instance__c> instances = [SELECT Id, Availability__c FROM Instance__c ORDER BY Name ASC];
        List<Booking__c> bookingsToReassign = [SELECT Id FROM Booking__c WHERE Instance__c = :instances.get(0).Id];
        for(Booking__c booking:bookingsToReassign){
                booking.Instance__c = instances.get(1).Id;
        }

        Exception finalException;
        Test.startTest();
            try{
                update bookingsToReassign;
            }
            catch(Exception e){
                finalException = e;
            }
        Test.stopTest();

        System.assert(finalException.getMessage().contains(SessionAvailabilityChecker.OVER_BOOKED_SESSION_MSG));
    }


    /*
    * @method checkBookingLineInstanceReassignmentAvailability
    * @case when updating the instance on 2 bookings lines assigned to instance 0, to instance 1
    * @result expect the sessions previously related to the updated booking lines on instance 0 to have a availability of 2 + 2 = 4 and the 
    *         sessions now related to the updated booking lines on instance 1 to have a availability of 2 - 2 = 0 and the session lookups on the updated booking lines to be the session on 
    */
    /*@isTest
    static void test_SuccessfulBookingLineReassign(){
        List<Instance__c> instances = [SELECT Id, Availability__c FROM Instance__c ORDER BY Name ASC];
        List<Product2> products = [SELECT Id FROM Product2 ORDER BY Name ASC];

        List<Session__c> sessionToDeassignFrom = [SELECT Id FROM Session__c WHERE Instance__c = :instances.get(0).Id AND Session_Product__c = :products.get(0).Id];
        List<Booking_Line__c> bookingLinesToReassign = [SELECT Id, Product_Family__c FROM Booking_Line__c WHERE Session__c = :sessionToDeassignFrom.get(0).Id];

        for(Integer i=0;i<2;i++){
            bookingLinesToReassign.get(i).Instance__c = instances.get(1).Id;
        }

        Test.startTest();
            update bookingLinesToReassign;
        Test.stopTest();

        List<Session__c> deassignedSession = [SELECT Available__c, Booked__c FROM Session__c WHERE Instance__c = :instances.get(0).Id AND Session_Product__c = :products.get(0).Id];
        List<Session__c> assignedSession = [SELECT Available__c, Booked__c FROM Session__c WHERE Instance__c = :instances.get(1).Id AND Session_Product__c = :products.get(0).Id];
        List<Booking_Line__c> updatedBookingLines = [SELECT Session__c FROM Booking_Line__c WHERE Id = :bookingLinesToReassign.get(0).Id OR Id = :bookingLinesToReassign.get(1).Id];

        System.assertEquals(4, deassignedSession.get(0).Available__c);
        System.assertEquals(0, assignedSession.get(0).Available__c);
        System.assertEquals(assignedSession.get(0).Id, updatedBookingLines.get(0).Session__c);
    }*/

    /*
    * @method checkBookingLineInstanceReassignmentAvailability
    * @case when updating the instance on 3 bookings lines assigned to instance 0, to instance 1 and 2 booking lines assigned to instance 1, to instance 2
    * @result expect the sessions previously related to the booking lines reassigned to instance 1 to have an availability of 2 + 3 = 5, the sessions related to instance 1 which were 
    *         previously related to the booking lines now assigned to instance 2 and now related to the booking lines previously assigned to instance 1 to have a availability of 2 + 2 - 3 = 1
    *         and the sessions now related to the booking lines assigned to instance 2 to have an availability of 2 - 2 = 0
    */
    /*@isTest
    static void test_SuccessfulBookingLineReassign_2(){
        List<Instance__c> instances = [SELECT Id, Availability__c FROM Instance__c ORDER BY Name ASC];
        List<Product2> products = [SELECT Id FROM Product2 ORDER BY Name ASC];

        List<Session__c> sessionsOnInstanceZero = [SELECT Id FROM Session__c WHERE Instance__c = :instances.get(0).Id AND Session_Product__c = :products.get(0).Id];
        List<Booking_Line__c> bookingLinesToReassignToInstanceOne = [SELECT Id, Product_Family__c FROM Booking_Line__c WHERE Session__c = :sessionsOnInstanceZero.get(0).Id];

        List<Session__c> sessionsOnInstanceOne = [SELECT Id FROM Session__c WHERE Instance__c = :instances.get(1).Id AND Session_Product__c = :products.get(0).Id];
        List<Booking_Line__c> bookingLinesToReassignToInstanceTwo = [SELECT Id, Product_Family__c FROM Booking_Line__c WHERE Session__c = :sessionsOnInstanceOne.get(0).Id];

        
        for(Integer i=0;i<3;i++){
            bookingLinesToReassignToInstanceOne.get(i).Instance__c = instances.get(1).Id;
        }

        for(Integer i=0;i<2;i++){
            bookingLinesToReassignToInstanceTwo.get(i).Instance__c = instances.get(2).Id;
        }
        
        List<Booking_Line__c> bookingLinesToReassign = bookingLinesToReassignToInstanceOne;
        bookingLinesToReassign.addAll(bookingLinesToReassignToInstanceTwo);

        Test.startTest();
            update bookingLinesToReassign;
        Test.stopTest();

        List<Session__c> updatedSessionsOnInstanceZero = [SELECT Available__c, Booked__c FROM Session__c WHERE Instance__c = :instances.get(0).Id AND Session_Product__c = :products.get(0).Id];
        List<Session__c> updatedSessionsOnInstanceOne = [SELECT Available__c, Booked__c FROM Session__c WHERE Instance__c = :instances.get(1).Id AND Session_Product__c = :products.get(0).Id];
        List<Session__c> updatedSessionsOnInstanceTwo = [SELECT Available__c, Booked__c FROM Session__c WHERE Instance__c = :instances.get(2).Id AND Session_Product__c = :products.get(0).Id];

        System.assertEquals(5, updatedSessionsOnInstanceZero.get(0).Available__c);
        System.assertEquals(1, updatedSessionsOnInstanceOne.get(0).Available__c);
        System.assertEquals(0, updatedSessionsOnInstanceTwo.get(0).Available__c);
    }*/

    /*
    * @method checkBookingLineInstanceReassignmentAvailability
    * @case when updating the instance on 3 bookings lines assigned to instance 0, to instance 1 
    * @result expect a custom validation error to have been thrown as the maximum capacity on the sessions on instance 1 has been exceeded  
    */
    @isTest
    static void test_OverassignBookingLines(){
        List<Instance__c> instances = [SELECT Id, Availability__c FROM Instance__c ORDER BY Name ASC];
        List<Product2> products = [SELECT Id FROM Product2 ORDER BY Name ASC];

        List<Session__c> sessionToDeassignFrom = [SELECT Id FROM Session__c WHERE Instance__c = :instances.get(0).Id AND Session_Product__c = :products.get(0).Id];
        List<Booking_Line__c> bookingLinesToReassign = [SELECT Id FROM Booking_Line__c WHERE Session__c = :sessionToDeassignFrom.get(0).Id];

        for(Integer i=0;i<3;i++){
            bookingLinesToReassign.get(i).Instance__c = instances.get(1).Id;
        }
        
        Exception finalException;

        Test.startTest();
            try{
                update bookingLinesToReassign;
            }
            catch(Exception e){
                finalException = e;
            }
        Test.stopTest();

        System.assert(finalException.getMessage().contains(SessionAvailabilityChecker.OVER_BOOKED_SESSION_MSG));
    }

    /*
    * @method filterBookingsAndCheckSessionAvailability
    * @case when updating the status on all booking assigned to instance 0 to cancelled 
    * @result expect the sessions on instance 0 to have maximum capacity again and the flag Booking_Cancelled__c on each booking to be true
    */
    @isTest
    static void test_CancelBookings(){
        List<Instance__c> instances = [SELECT Id, Availability__c FROM Instance__c ORDER BY Name ASC];
        List<Booking__c> bookingsToReassign = [SELECT Id FROM Booking__c WHERE Instance__c = :instances.get(0).Id LIMIT 2];
        for(Integer i=0;i<2;i++){
                bookingsToReassign.get(i).Status__c = 'Cancelled';
                /* START OF - Changes made by David Lovejoy - 18/11/2020 - BPP-10628 */
                bookingsToReassign.get(i).Status_Reason__c = 'Deferral';
                bookingsToReassign.get(i).BPP_Cancellation_Action__c='Don\'t Credit Fulfilled Materials';
                bookingsToReassign.get(i).BPP_Cancellation_Terms__c='Outside';
                /* END OF - Changes made by David Lovejoy */
        }

        Test.startTest();
            update bookingsToReassign;
            Test.setMock(HttpCalloutMock.class, new AWSCalloutMock());
        Test.stopTest();

        List<Instance__c> deassignedInstance = [SELECT Availability__c FROM Instance__c WHERE Id = :instances.get(0).Id];
        List<Booking__c> updatedBookings = [SELECT Booking_Cancelled__c FROM Booking__c WHERE Instance__c = :instances.get(0).Id LIMIT 2];

        System.assertEquals(4, deassignedInstance.get(0).Availability__c);
        for(Integer i=0;i<2;i++){
            System.assert(updatedBookings.get(i).Booking_Cancelled__c);
        }
    }

    /*
    * @method filterBookingsAndCheckSessionAvailability
    * @case when updating the status on all booking assigned to instance 0 from a value not cancelled to cancelled 
    * @result expect the sessions on instance 0 to have have an availability of 5 - 3 = 2 and the flag Booking_Cancelled__c on each booking to be false
    
    @isTest
    static void test_UncancelBookings(){
        Test.startTest();
        List<Instance__c> instances = [SELECT Id, Availability__c FROM Instance__c ORDER BY Name ASC];
        List<Booking__c> bookingsToReassign = [SELECT Id FROM Booking__c WHERE Instance__c = :instances.get(0).Id];
        for(Integer i=0;i<2;i++){
                bookingsToReassign.get(i).Status__c = 'Cancelled';
                bookingsToReassign.get(i).Status_Reason__c = 'Deferral';
				bookingsToReassign.get(i).BPP_Cancellation_Action__c='Don\'t Credit Fulfilled Materials';
                bookingsToReassign.get(i).BPP_Cancellation_Terms__c='Outside';
        }
        update bookingsToReassign;

        for(Integer i=0;i<2;i++){
            bookingsToReassign.get(i).Status__c = 'Confirmed';
            bookingsToReassign.get(i).Status_Reason__c = null;
            bookingsToReassign.get(i).BPP_Cancellation_Action__c = null;
            bookingsToReassign.get(i).BPP_Cancellation_Terms__c = null;
        }
        
        update bookingsToReassign;
        Test.stopTest();

        List<Instance__c> deassignedInstance = [SELECT Availability__c FROM Instance__c WHERE Id = :instances.get(0).Id];
        List<Booking__c> updatedBookings = [SELECT Booking_Cancelled__c FROM Booking__c WHERE Instance__c = :instances.get(0).Id];


        //System.assertEquals(2, deassignedInstance.get(0).Availability__c);
        for(Integer i=0;i<2;i++){
           // System.assert(!updatedBookings.get(i).Booking_Cancelled__c);
        }
    }*/

    /*
    * @method filterBookingsAndCheckSessionAvailability
    * @case when updating the instance lookup on all bookings, with a status of cancelled, from instance 0 to instance 1
    * @result expect the availaibity of the sessions on all sessions to be unchanged
    */
    @isTest
    static void test_UpdateCancelledBookings(){
        Test.startTest();
        List<Instance__c> instances = [SELECT Id, Availability__c FROM Instance__c ORDER BY Name ASC];
        List<Booking__c> bookingsToUpdate = [SELECT Id FROM Booking__c WHERE Instance__c = :instances.get(0).Id LIMIT 2];

        for(Integer i=0;i<2;i++){
                bookingsToUpdate.get(i).Status__c = 'Cancelled';
                /* START OF - Changes made by David Lovejoy - 18/11/2020 - BPP-10628 */
                bookingsToUpdate.get(i).Status_Reason__c = 'Deferral';
				bookingsToUpdate.get(i).BPP_Cancellation_Action__c='Don\'t Credit Fulfilled Materials';
                bookingsToUpdate.get(i).BPP_Cancellation_Terms__c='Outside';
                /* END OF - Changes made by David Lovejoy */
        }

        update bookingsToUpdate;
        Test.setMock(HttpCalloutMock.class, new AWSCalloutMock());

        for(Integer i=0;i<2;i++){
            bookingsToUpdate.get(i).Instance__c = instances.get(1).Id;
        }

        update bookingsToUpdate;
        Test.setMock(HttpCalloutMock.class, new AWSCalloutMock());
        Test.stopTest();

        List<Instance__c> deassignedInstance = [SELECT Availability__c FROM Instance__c WHERE Id = :instances.get(0).Id];
        List<Instance__c> assignedInstance = [SELECT Availability__c FROM Instance__c WHERE Id = :instances.get(1).Id];
        List<Booking__c> updatedBookings = [SELECT Booking_Cancelled__c FROM Booking__c WHERE Instance__c = :instances.get(0).Id LIMIT 2];

        System.assertEquals(4, deassignedInstance.get(0).Availability__c);
        System.assertEquals(2, assignedInstance.get(0).Availability__c);
        
    }

    /*
    * @method filterBookingLinesAndCheckSessionAvailability
    * @case when updating all booking lines on instance 0 to have a status of cancelled (on hold = cancelled)
    * @result expect the availaibity of the sessions to be at maximum again
    */
    @isTest
    static void test_CancelBookingLines(){
        List<Instance__c> instances = [SELECT Id, Availability__c FROM Instance__c ORDER BY Name ASC];
        List<Product2> products = [SELECT Id FROM Product2 ORDER BY Name ASC];

        List<Session__c> sessionToDeassignFrom = [SELECT Id FROM Session__c WHERE Instance__c = :instances.get(0).Id AND Session_Product__c = :products.get(0).Id];
        List<Booking_Line__c> bookingLinesToReassign = [SELECT Id FROM Booking_Line__c WHERE Session__c = :sessionToDeassignFrom.get(0).Id];

        for(Integer i=0;i<2;i++){
            bookingLinesToReassign.get(i).On_Hold__c = 'Cancelled';
			
        }

        Test.startTest();
            update bookingLinesToReassign;
        Test.stopTest();

        List<Session__c> deassignedSession = [SELECT Available__c, Booked__c FROM Session__c WHERE Instance__c = :instances.get(0).Id AND Session_Product__c = :products.get(0).Id];

        System.assertEquals(4, deassignedSession.get(0).Available__c);
    }

    /*
    * @method filterBookingLinesAndCheckSessionAvailability
    * @case when updating all booking lines on instance 0 status from not cancelled to cancelled
    * @result expect the availaibity of the sessions to be 5 - 3 = 2
    */
    @isTest
    static void test_UncancelBookingLines(){
        Test.startTest();
        List<Instance__c> instances = [SELECT Id, Availability__c FROM Instance__c ORDER BY Name ASC];
        List<Product2> products = [SELECT Id FROM Product2 ORDER BY Name ASC];

        List<Session__c> sessionToDeassignFrom = [SELECT Id FROM Session__c WHERE Instance__c = :instances.get(0).Id AND Session_Product__c = :products.get(0).Id];
        List<Booking_Line__c> bookingLinesToReassign = [SELECT Id FROM Booking_Line__c WHERE Session__c = :sessionToDeassignFrom.get(0).Id];

        for(Integer i=0;i<2;i++){
            bookingLinesToReassign.get(i).On_Hold__c = 'Cancelled';
        }

        update bookingLinesToReassign;

        for(Integer i=0;i<2;i++){
            bookingLinesToReassign.get(i).On_Hold__c = 'Confirmed';
        }

            update bookingLinesToReassign;
        Test.stopTest();

        List<Session__c> deassignedSession = [SELECT Available__c, Booked__c FROM Session__c WHERE Instance__c = :instances.get(0).Id AND Session_Product__c = :products.get(0).Id];

        System.assertEquals(2, deassignedSession.get(0).Available__c);
    }

    /*
    * @method filterBookingLinesAndCheckSessionAvailability
    * @case when updating all bookings lines on instance 0 status from not cancelled to cancelled and all booking lines under those bookings status from not cancelled to cancelled
    * @result expect the availaibity the availiablity of the session on instance one to have been only increased once 2 + 3 = 5
    */
    @isTest
    static void test_CancelBookingLines_2(){
        Test.startTest();
        List<Instance__c> instances = [SELECT Id, Availability__c FROM Instance__c ORDER BY Name ASC];
        List<Product2> products = [SELECT Id FROM Product2 ORDER BY Name ASC];

        List<Booking__c> bookingsToCancel = [SELECT Id FROM Booking__c WHERE Instance__c = :instances.get(0).Id LIMIT 2];

        for(Integer i=0;i<2;i++){
                bookingsToCancel.get(i).Status__c = 'Cancelled';
                /* START OF - Changes made by David Lovejoy - 18/11/2020 - BPP-10628 */
                bookingsToCancel.get(i).Status_Reason__c = 'Deferral';
                bookingsToCancel.get(i).BPP_Cancellation_Action__c='Don\'t Credit Fulfilled Materials';
				bookingsToCancel.get(i).BPP_Cancellation_Terms__c='Outside';
                /* END OF - Changes made by David Lovejoy */
        }

        update bookingsToCancel;
        Test.setMock(HttpCalloutMock.class, new AWSCalloutMock());

        List<Session__c> sessionToDeassignFrom = [SELECT Id FROM Session__c WHERE Instance__c = :instances.get(0).Id AND Session_Product__c = :products.get(0).Id];
        List<Booking_Line__c> bookingLinesToCancel = [SELECT Id FROM Booking_Line__c WHERE Session__c = :sessionToDeassignFrom.get(0).Id AND (Booking__c = :bookingsToCancel.get(0).Id 
                                                        OR Booking__c = :bookingsToCancel.get(1).Id)];


        system.debug('@@bookingLinesToCancel@@'+bookingLinesToCancel);
        for(Integer i=0;i<2;i++){
            bookingLinesToCancel.get(i).On_Hold__c = 'Cancelled';
        }

        
        update bookingLinesToCancel;
        Test.setMock(HttpCalloutMock.class, new AWSCalloutMock());
        Test.stopTest();

        List<Session__c> deassignedSession = [SELECT Available__c, Booked__c FROM Session__c WHERE Instance__c = :instances.get(0).Id AND Session_Product__c = :products.get(0).Id];

        System.assertEquals(4, deassignedSession.get(0).Available__c);
    }
}