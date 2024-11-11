@isTest
private class BookingUtilityTest {
    
    /* START OF - Changes made by David Lovejoy - 16/12/2020 - commented out test class as main class does not appear to be in use */
    @testSetup
    static void testSetup(){
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
        
        List<Session__c> sessions = new List<Session__c>();
        for(Integer i=0;i<5;i++){
            for(Integer j=0;j<5;j++){
                sessions.add(TestDataFactory.createSession(false,(i*10)+j,instances.get(i),products.get(j),0,5));
            }
        }
        insert sessions;
        
        List<Account> accounts = new List<Account>();
        for (Integer i=0; i < 5; i++) {
            Account a = TestDataFactory.createAccount(false, false, null, i);
            a.Billing_Frequency__c = 'Monthly';
            a.Billing_Type__c = 'In Arrears';
            accounts.add(a);
        }
        insert accounts;
        
        //Create student account
        List<Account> studentAccounts = new List<Account>();
        for (Integer i=0; i < 5; i++) {
            Account a = TestDataFactory.createAccount(false, true, accounts.get(i).Id, i);
            studentAccounts.add(a);
        }
        insert studentAccounts;
        
        List<Order> orders = new List<Order>();
        for(Integer i=0;i<5;i++){
            orders.add(TestDataFactory.createOrder(false,i,accounts.get(i),null));
        }
        insert orders;
        
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
            for(Integer j=0;j<5;j++){
                orderLines.add(TestDataFactory.createOrderLine(false,orders.get(i),products.get(j),parentOrderLines.get(i),
                                                               priceBookEntries.get(j),billingRule,revenueRecognitionRule,taxRule,'Session'));
            }
            
        }
        insert orderLines;
        
        List<blng__UsageSummary__c> usageSummaries = new List<blng__UsageSummary__c>();
        for (Integer i = 0; i < orderLines.size(); i++) {
            usageSummaries.add(TestDataFactory.createBookingSummary(false, orderLines.get(i)));
        }
        insert usageSummaries;
        
        for (Order order : orders) {
            order.Status = 'Activated';
        }
        update orders;
        
        List<Booking__c> bookings = new List<Booking__c>();
        for(Integer i=0;i<5;i++){
            for(Integer j=0;j<3;j++){
                bookings.add(TestDataFactory.createBooking(false,instances.get(i),orders.get(i),studentAccounts.get(i)));
            }
        }
        insert bookings;
    }
    
    @isTest
    static void test_getNonCancelledBookingLines() {
        List<Booking_Line__c> bookingLineList = [SELECT Id, On_Hold__c FROM Booking_Line__c];
        List<Booking_Line__c> nonCancelledBookingLines = BookingUtility.getNonCancelledBookingLines(bookingLineList);
        System.assert(nonCancelledBookingLines.size() > 0);
    }
}