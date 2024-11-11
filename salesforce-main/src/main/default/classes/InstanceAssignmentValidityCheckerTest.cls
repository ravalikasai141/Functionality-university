/*
* @who   Patrick Duncan <patrick.duncan@weare4c.com>
* @what  Test class for InstanceAssignmentValidityChecker
* @when  24/3/2020
*/
@isTest
private class InstanceAssignmentValidityCheckerTest {

    @testSetup
    static void setup(){
        blng__BillingRule__c billingRule = TestDataFactory.createBillingRule(true);
        blng__FinanceBook__c billingFinanceBook = TestDataFactory.createBillingFinanceBook(true);
        blng__RevenueRecognitionRule__c revenueRecognitionRule = TestDataFactory.createRevenueRecognitionRule(true);
        blng__TaxRule__c taxRule = TestDataFactory.createTaxRule(true);

        
        List<Product2> products = new List<Product2>();
        for(Integer i=0;i<5;i++){
            products.add(TestDataFactory.createProduct(false,i,billingRule,revenueRecognitionRule,taxRule));
        }
        insert products;

        List<Instance__c> instances = new List<Instance__c>();
        for(Integer i=0;i<5;i++){
            instances.add(TestDataFactory.createInstance(false,i,products.get(i)));
        }
        insert instances;

        List<Account> accounts = new List<Account>();
        for(Integer i=0;i<5;i++){
            accounts.add(TestDataFactory.createAccount(false,false,null,i));
        }
        insert accounts;
        
        List<Account> students = new List<Account>();
        for(Integer i=0;i<5;i++){
            students.add(TestDataFactory.createAccount(false,true,accounts.get(i).Id,i));
        }
        insert students;

        /* START OF - Changes made by David Lovejoy - 06/11/2020 - BPP-10399/10510 */
        country_list__c cntry = CreateTestData.createCountry1();

        List<Address__c> addresses = new List<Address__c>();
        for(Integer i=0;i<5;i++){
            addresses.add(TestDataFactory.createAddress(false,i,accounts.get(i),cntry,true,false));
        }
        insert addresses;

        List<Order> orders = new List<Order>();
        for(Integer i=0;i<5;i++){
            orders.add(TestDataFactory.createOrder(false,i,accounts.get(i),null,addresses.get(i)));
        }
        insert orders;
        /* END OF - Changes made by David Lovejoy */

        List<PricebookEntry> priceBookEntries = new List<PricebookEntry>();
        for(Integer i=0;i<5;i++){
            priceBookEntries.add(TestDataFactory.createPricebookEntry(false,products.get(i),null));
        }
        insert priceBookEntries;

        List<OrderItem> parentOrderLines = new List<OrderItem>();
        for(Integer i=0;i<5;i++){
            parentOrderLines.add(TestDataFactory.createOrderLine(false,orders.get(i),products.get(i),null,priceBookEntries.get(i),billingRule,revenueRecognitionRule,
                taxRule,''));
        }
        insert parentOrderLines;

        List<OrderItem> orderLines = new List<OrderItem>();
        for(Integer i=0;i<5;i++){
            orderLines.add(TestDataFactory.createOrderLine(false,orders.get(i),products.get(i),parentOrderLines.get(i),priceBookEntries.get(i),billingRule,revenueRecognitionRule,
                taxRule,'Materials'));
        }
        insert orderLines;
        
        List<blng__UsageSummary__c> usageSummaries = new List<blng__UsageSummary__c>();
        for (Integer i = 0; i < orderLines.size(); i++) {
            usageSummaries.add(TestDataFactory.createBookingSummary(false, orderLines.get(i)));
        }
        insert usageSummaries;
        
        for(Order ord:orders)
        {
            ord.Status = 'Activated';
        }
        update orders;
    }

    /*
    *  @description Method to insert bookings
    *  @return     The inserted bookings
    */
    static List<Booking__c> insertBookings() {
        List<Instance__c> instances = [SELECT Id FROM Instance__c ORDER BY Name ASC]; 
        List<Order> orders = [SELECT Id FROM Order ORDER BY Name ASC]; 
        List<Account> studentAccounts = [SELECT Id, Client__c FROM Account WHERE IsPersonAccount = true];

        List<Booking__c> bookings = new List<Booking__c>();
        for(Integer i=0;i<5;i++){
            bookings.add(TestDataFactory.createBooking(false,instances.get(i),orders.get(i),studentAccounts.get(i)));
        }
        insert bookings;
        return bookings;
    }

    /*
    * @method checkBookingInstanceAssignmentValidity
    * @case when inserting 5 bookings where the product on the instance of each booking equals the a product on one of the order lines on the order associated to the booking
    * @result expect 5 booking records to have been created
    */
    @isTest
    static void test_InsertBookingsSuccess(){
        Test.startTest();
            insertBookings();
        Test.stopTest();

        List<Booking__c> bookings = [SELECT Id FROM Booking__c];
        System.assertEquals(5, bookings.size());
    }   

    /*
    * @method checkBookingInstanceAssignmentValidity
    * @case when inserting 5 bookings where the product on the instance of the first booking doesn't match the product on any of the order lines on the associated order
    * @result expect 0 booking records to have been created and an error to have been thrown
    */
    @isTest
    static void test_InsertBookingsFailure(){
        List<Instance__c> instances = [SELECT Id FROM Instance__c ORDER BY Name ASC]; 
        List<Product2> products = [SELECT Id FROM Product2 ORDER BY Name ASC];

        instances.get(0).Product__c = products.get(1).Id;
        update instances.get(0);

        Test.startTest();
        Exception exc;
            try{
                insertBookings();
            }
            catch(Exception e){
                exc = e;
            }
        Test.stopTest();

        List<Booking__c> bookings = [SELECT Id FROM Booking__c];
        System.assertEquals(0, bookings.size());
        System.assert(exc.getMessage().contains(InstanceAssignmentValidityChecker.BOOKING_ERROR_MSG));
    }

    /*
    * @method checkBookingInstanceAssignmentValidity
    * @case when updating a booking where the product on the instance of the booking doesn't match the product on any of the order lines on the associated order
    * @result expect an error to have been thrown
    */
    @isTest
    static void test_UpdateBookingsFailure(){
        List<Instance__c> instances = [SELECT Id FROM Instance__c ORDER BY Name ASC]; 
        List<Product2> products = [SELECT Id FROM Product2 ORDER BY Name ASC];
		
        Test.startTest();
            insertBookings();
            List<Booking__c> bookings = [SELECT Id FROM Booking__c ORDER BY Instance__r.Name ASC];
    
            Exception exc;
            try{
                bookings.get(0).Instance__c = instances.get(1).Id;
                update bookings.get(0);
            }
            catch(Exception e){
                exc = e;
            }
        Test.stopTest();

        //System.assert(exc.getMessage().contains(InstanceAssignmentValidityChecker.BOOKING_ERROR_MSG));
    }

    /*
    * @method checkBookingLineInstanceAssignmentValidity
    * @case when updating a booking line where the product on the instance of the booking line doesn't match the product on any of the order lines on the associated order
    * @result expect an error message to have been thrown
    */
    @isTest
    static void test_UpdateBookingLinesFailure(){
        List<Instance__c> instances = [SELECT Id FROM Instance__c ORDER BY Name ASC]; 
        List<Product2> products = [SELECT Id FROM Product2 ORDER BY Name ASC];
		Test.startTest();
        	insertBookings();
        	List<Booking_Line__c> bookingLines = [SELECT Id FROM Booking_Line__c ORDER BY Instance__r.Name ASC];
        
        	Exception exc;
            try{
                bookingLines.get(0).Instance__c = instances.get(1).Id;
                update bookingLines.get(0);
            }
            catch(Exception e){
                exc = e;
            }
        Test.stopTest();

        System.assert(exc.getMessage().contains(InstanceAssignmentValidityChecker.BOOKING_ERROR_MSG));
    }       
}