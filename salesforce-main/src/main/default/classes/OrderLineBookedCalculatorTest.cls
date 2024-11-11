/*
* @who   Patrick Duncan <patrick.duncan@weare4c.com>
* @what  Test class for OrderLineBookedCalculator
* @when  23/1/2020
*/
@isTest
private class OrderLineBookedCalculatorTest {

    @testSetup
    static void testSetup() {
        Database.DMLOptions dbDML = new Database.DMLOptions(); 
        dbDML.DuplicateRuleHeader.allowSave = true;
        dbDML.DuplicateRuleHeader.runAsCurrentUser = true;
        
        List<Account> accounts = new List<Account>();
        for(Integer i=0;i<10;i++){
            accounts.add(TestDataFactory.createAccount(false,false,null,i));
        }
        Database.insert(accounts, dbDML);

        List<Account> students = new List<Account>();
        for(Integer i=0;i<10;i++){
            students.add(TestDataFactory.createAccount(false,true,accounts.get(i).Id,i));
        }
		Database.insert(students, dbDML);
        
        /* START OF - Changes made by David Lovejoy - 06/11/2020 - BPP-10399/10510 */
        country_list__c cntry = CreateTestData.createCountry1();

        List<Address__c> addresses = new List<Address__c>();
        for(Integer i=0;i<10;i++){
            addresses.add(TestDataFactory.createAddress(false,i,accounts.get(i),cntry,true,false));
        }
        Database.insert(addresses, dbDML);

        List<Order> orders = new List<Order>();
        for(Integer i=0;i<10;i++){
            orders.add(TestDataFactory.createOrder(false,i,accounts.get(i),null,addresses.get(i)));
        }
        insert orders;
        /* END OF - Changes made by David Lovejoy */

        blng__BillingRule__c billingRule = TestDataFactory.createBillingRule(true);
        blng__FinanceBook__c billingFinanceBook = TestDataFactory.createBillingFinanceBook(true);
        blng__BillingTreatment__c billingTreatment = TestDataFactory.createBillingTreatment(true, billingRule, billingFinanceBook);
        blng__RevenueRecognitionRule__c revenueRecognitionRule = TestDataFactory.createRevenueRecognitionRule(true);
        blng__TaxRule__c taxRule = TestDataFactory.createTaxRule(true);

        List<Product2> products = new List<Product2>();
        for(Integer i=0;i<10;i++){
            products.add(TestDataFactory.createProduct(false,i,billingRule,revenueRecognitionRule,taxRule));
        }
        insert products;

        List<PricebookEntry> priceBookEntries = new List<PricebookEntry>();
        for(Integer i=0;i<10;i++){
            priceBookEntries.add(TestDataFactory.createPricebookEntry(false,products.get(i),null));
        }
        insert priceBookEntries;

        List<OrderItem> parentOrderLines = new List<OrderItem>();
        for(Integer i=0;i<10;i++){
            parentOrderLines.add(TestDataFactory.createOrderLine(false,orders.get(i),products.get(i),null,priceBookEntries.get(i),billingRule,revenueRecognitionRule,
                taxRule,''));
        }
        insert parentOrderLines;
        List<OrderItem> orderLines = new List<OrderItem>();
        for(Integer i=0;i<10;i++){
            orderLines.add(TestDataFactory.createOrderLine(false,orders.get(i),products.get(i),parentOrderLines.get(i),
                priceBookEntries.get(i),billingRule,revenueRecognitionRule,taxRule,'Materials'));

        }
        insert orderLines;
        
        for(Order ord:orders)
        {
            ord.Status = 'Activated';
        }
        update orders;

        List<blng__UsageSummary__c> bookingSummaries = new List<blng__UsageSummary__c>();
        for(Integer i=0;i<orderLines.size();i++){
            bookingSummaries.add(TestDataFactory.createBookingSummary(false,orderLines.get(i)));
        }
        insert bookingSummaries;

        List<Instance__c> instances = new List<Instance__c>();
        for(Integer i=0;i<10;i++){
            instances.add(TestDataFactory.createInstance(false,i,products.get(i)));
        }
        insert instances;

        List<Session__c> sessions = new List<Session__c>();
        for(Integer i=0;i<10;i++){
            sessions.add(TestDataFactory.createSession(false,i,instances.get(i),products.get(i),5,10));
        }
        insert sessions;
    }


    public static List<Booking__c> insertBookings(){
        List<Instance__c> instances = [SELECT Id FROM Instance__c ORDER BY Instance_Name__c ASC];
        List<Order> orders = [SELECT Id FROM Order ORDER BY Name ASC];
        List<Account> studentAccounts = [SELECT Id, Client__c FROM Account WHERE IsPersonAccount = true];
        
        List<Booking__c> bookings = new List<Booking__c>();
        for(Integer i=0;i<10;i++){
            for(Integer j=0;j<5;j++){
                bookings.add(TestDataFactory.createBooking(false,instances.get(i),orders.get(i),studentAccounts.get(i)));
            }
        }
        insert bookings;
        return bookings;
    }

    /*
    * @method calculateOrderProductsBooked
    * @case when creating 5 booking lines on each non-parent order line
    * @result expect each booking line to have a Booked_Quantity__c of 5
    */
    @isTest
    static void test_InsertBookingLines(){
        Test.startTest();
            insertBookings();
        Test.stopTest();

        List<OrderItem> orderLines = [SELECT Booked_Quantity__c FROM OrderItem WHERE SBQQ__RequiredBy__c != NULL];
        for(OrderItem orderline:orderLines){
            System.assertEquals(5, orderline.Booked_Quantity__c);
        }
    }

    /*
    * @method calculateOrderProductsBooked
    * @case when creating 5 booking lines on each non-parent order line and then moving all the booking lines from one order line to another
    * @result expect the order line taking on the new booking lines to have an Booked_Quantity__c of 10 and the other order lin to have an Booked_Quantity__c of 0
    */
    @isTest
    static void test_UpdateBookingLines(){
        Test.startTest();
        	insertBookings();       

        List<Booking_Line__c> bookingLinesOnOrderZero = [SELECT Id FROM Booking_Line__c WHERE blng_OrderProduct__r.Order.Name = 'Default Test Order 0'];
        OrderItem orderLineOnOrderOne =  [SELECT Id FROM OrderItem WHERE SBQQ__RequiredBy__c != NULL AND Order.Name = 'Default Test Order 1'];
        for(Booking_Line__c bookingLine:bookingLinesOnOrderZero){
            bookingLine.blng_OrderProduct__c = orderLineOnOrderOne.Id;
        }

        
            update bookingLinesOnOrderZero;
        Test.stopTest();

        OrderItem orderLineOnOrderZero =  [SELECT Booked_Quantity__c FROM OrderItem WHERE SBQQ__RequiredBy__c != NULL AND Order.Name = 'Default Test Order 0'];
        OrderItem updatedOrderLineOnOrderOne = [SELECT Booked_Quantity__c FROM OrderItem WHERE SBQQ__RequiredBy__c != NULL AND Order.Name = 'Default Test Order 1'];
        
        System.assertEquals(0, orderLineOnOrderZero.Booked_Quantity__c);
        System.assertEquals(10, updatedOrderLineOnOrderOne.Booked_Quantity__c);
    }

    /*
    * @method calculateOrderProductsBooked
    * @case when creating 5 booking lines on each non-parent order line and then deleting all of those on a single order line and then undeleting them
    * @result expect that order line to have a Booked_Quantity__c of 10
    */
    @isTest
    static void test_UndeleteBookingLines(){
        insertBookings();       

        List<Booking_Line__c> bookingLinesOnOrderZero = [SELECT Id FROM Booking_Line__c WHERE blng_OrderProduct__r.Order.Name = 'Default Test Order 0'];
        
        delete bookingLinesOnOrderZero;

        Test.startTest();
            undelete bookingLinesOnOrderZero;
        Test.stopTest();

        OrderItem updatedOrderLineOnOrderZero = [SELECT Booked_Quantity__c FROM OrderItem WHERE SBQQ__RequiredBy__c != NULL AND Order.Name = 'Default Test Order 0'];
        System.assertEquals(5, updatedOrderLineOnOrderZero.Booked_Quantity__c);
    }

    /*
    * @method calculateOrderProductsBooked
    * @case when creating 5 booking lines on each non-parent order line and then cancelling all of those on a single order line
    * @result expect that order line to have a Booked_Quantity__c of 0
    */
    @isTest
    static void test_CancelBookingLines(){
        insertBookings();       

        List<Booking_Line__c> bookingLinesOnOrderZero = [SELECT Id FROM Booking_Line__c WHERE blng_OrderProduct__r.Order.Name = 'Default Test Order 0'];
        
        for(Booking_Line__c bookingLine:bookingLinesOnOrderZero){
            bookingLine.On_Hold__c = 'Cancelled';
        }

        Test.startTest();
            update bookingLinesOnOrderZero;
        Test.stopTest();

        OrderItem updatedOrderLineOnOrderZero = [SELECT Booked_Quantity__c FROM OrderItem WHERE SBQQ__RequiredBy__c != NULL AND Order.Name = 'Default Test Order 0'];
        System.assertEquals(0, updatedOrderLineOnOrderZero.Booked_Quantity__c);
    }

    /*
    * @method calculateOrderProductsBooked
    * @case when creating 5 booking lines on each non-parent order line and then cancelling all of those on a single order line and then uncancelling them
    * @result expect that order line to have a Booked_Quantity__c of 5
    */
    /*@isTest
    static void test_UncancelBookingLines(){
        insertBookings();       

        List<Booking_Line__c> bookingLinesOnOrderZero = [SELECT Id FROM Booking_Line__c WHERE blng_OrderProduct__r.Order.Name = 'Default Test Order 0'];
        
        for(Booking_Line__c bookingLine:bookingLinesOnOrderZero){
            bookingLine.On_Hold__c = 'Cancelled';
        }

        update bookingLinesOnOrderZero;

        for(Booking_Line__c bookingLine:bookingLinesOnOrderZero){
            bookingLine.On_Hold__c = 'Confirmed';
        }

        Test.startTest();
            update bookingLinesOnOrderZero;
        Test.stopTest();

        OrderItem updatedOrderLineOnOrderZero = [SELECT Booked_Quantity__c FROM OrderItem WHERE SBQQ__RequiredBy__c != NULL AND Order.Name = 'Default Test Order 0'];
        System.assertEquals(5, updatedOrderLineOnOrderZero.Booked_Quantity__c);
    }*/
}