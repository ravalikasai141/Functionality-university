@isTest
public class BookingUsageGlobalTest {
    @testSetup
    static void testSetup() {
        List<Account> accounts = new List<Account>();
        for (Integer i = 0; i < 10; i++) {
            Account acc = TestDataFactory.createAccount(false, false, null, i);
            acc.Billing_Frequency__c = 'Monthly';
            acc.Billing_Type__c = 'In Arrears';
            accounts.add(acc);
        }
        insert accounts;

        TestDataFactory.createAccount(true, true, accounts.get(0).Id, 10);
        
        country_list__c cntry = CreateTestData.createCountry1();
        
        Account studentAccount = [SELECT Id, Client__c FROM Account WHERE LastName = 'Student'];
        Address__c addresses = TestDataFactory.createAddress(true,1,accounts[0],cntry,true,false);

        List<Order> orders = new List<Order>();
        for (Integer i = 0; i < 10; i++) {
            orders.add(TestDataFactory.createOrder(false,i,accounts.get(i),null));
        }
        
        for (Order ord : orders) {
            ord.Ship_To_Address__c = addresses.id;
            ord.AccountId = accounts[0].id;
            ord.Status = 'Draft';
        }
        insert orders;
        
        blng__BillingRule__c billingRule = TestDataFactory.createBillingRule(true);
        blng__FinanceBook__c billingFinanceBook = TestDataFactory.createBillingFinanceBook(true);
        blng__BillingTreatment__c billingTreatment = TestDataFactory.createBillingTreatment(true, billingRule, billingFinanceBook);
        blng__RevenueRecognitionRule__c revenueRecognitionRule = TestDataFactory.createRevenueRecognitionRule(true);
        blng__TaxRule__c taxRule = TestDataFactory.createTaxRule(true);

        List<Product2> products = new List<Product2>();
        for (Integer i = 0; i < 10; i++) {
            products.add(TestDataFactory.createProduct(false,i,billingRule,revenueRecognitionRule,taxRule));
        }
        insert products;

        List<PricebookEntry> priceBookEntries = new List<PricebookEntry>();
        for (Integer i = 0; i < 10; i++) {
            priceBookEntries.add(TestDataFactory.createPricebookEntry(false,products.get(i),null));
        }
        insert priceBookEntries;

        List<OrderItem> parentOrderLines = new List<OrderItem>();
        for (Integer i = 0;i<5;i++) {
            OrderItem parentOrderLine = TestDataFactory.createOrderLine(false,orders.get(i),products.get(i),null,priceBookEntries.get(i),billingRule,revenueRecognitionRule,taxRule,'');
            parentOrderLine.SBQQ__RevisedOrderProduct__c = null;
            parentOrderLines.add(parentOrderLine);
        }
        insert parentOrderLines;
        
        List<OrderItem> orderLines = new List<OrderItem>();
        for (Integer i = 0; i < 10; i++) {
            OrderItem sessionOrderProduct = TestDataFactory.createOrderLine(false,orders.get(i),products.get(i),parentOrderLines.get(Math.mod(i, 5)), priceBookEntries.get(i),billingRule,revenueRecognitionRule,taxRule,'Session');
            sessionOrderProduct.SBQQ__RevisedOrderProduct__c = null;
            orderLines.add(sessionOrderProduct);
            
            OrderItem onlineSessionOrderProduct = TestDataFactory.createOrderLine(false,orders.get(i),products.get(i),parentOrderLines.get(Math.mod(i, 5)), priceBookEntries.get(i),billingRule,revenueRecognitionRule,taxRule,'Online Session');
            onlineSessionOrderProduct.SBQQ__RevisedOrderProduct__c = null;
            orderLines.add(onlineSessionOrderProduct);
        }
        insert orderLines;
        
        for (Order ord : orders) {
            ord.Status = 'Activated';
        }
        update orders;

        List<blng__UsageSummary__c> bookingSummaries = new List<blng__UsageSummary__c>();
        for (Integer i = 0;i<orderLines.size();i++) {
            blng__UsageSummary__c bookingSummary = TestDataFactory.createBookingSummary(false,orderLines.get(i));
            bookingSummary.blng__Order__c = orderLines.get(i).OrderId;
            bookingSummaries.add(bookingSummary);
        }
        System.debug('@BookingUsageGlobalTest testSetup bookingSummaries: ' + bookingSummaries);
        insert bookingSummaries;

        List<Instance__c> instances = new List<Instance__c>();
        for (Integer i = 0; i < 10; i++) {
            instances.add(TestDataFactory.createInstance(false,i,products.get(i)));
        }
        insert instances;

        List<Session__c> sessions = new List<Session__c>();
        for (Integer i = 0; i < 10; i++) {
            sessions.add(TestDataFactory.createSession(false,i,instances.get(i),products.get(i),5,10));
        }
        insert sessions;
        
        List<Booking__c> bookings = new List<Booking__c>();
        for (Integer i = 0; i < 10; i++) {
            bookings.add(TestDataFactory.createBooking(false,instances.get(i),orders.get(i),studentAccount));
        }
        insert bookings;
        
        List<Booking_Line__c> bookingLines = [SELECT Id, Batch_Processed__c FROM Booking_Line__c];
        for(Integer i = 0; i < bookingLines.size(); i++) {
            bookingLines.get(i).blng_OrderProduct__c = null;
            bookingLines.get(i).blng_MatchingId__c = String.valueOf(Math.random());
        }
        update bookingLines;
        
        BookingLineBatch testBatch = new BookingLineBatch('blng_StartDateTime__c','Batch_Processed__c', 'On_Hold__c', 'Cancelled');
        Database.executeBatch(testBatch);
        
        List<blng__Invoice__c> invoices = new List<blng__Invoice__c>();
        for (Integer i = 0; i < 10; i++) {
            blng__Invoice__c invoice = new blng__Invoice__c();
            invoice.SFBD__HoldCollections__c = false;
            invoice.blng__Account__c = accounts.get(i).Id;
            invoice.blng__InvoiceDate__c = System.today();
            invoices.add(invoice);
        }
        insert invoices;
        
        Authorisation_Token__c authToken = TestDataFactory.createAuthorisationToken(true);
    }
    
    @isTest
    static void test_GenerateusagesBatch() {
        List<blng__Usage__c> usageList = [SELECT Id FROM blng__Usage__c];
        System.debug('@BookingUsageGlobalTest testSetup usageList.size(): ' + usageList.size());
        delete usageList;
        
        Test.startTest();
            BookingUsageBatch bub = new BookingUsageBatch();
            bub.start(null);
            bub.execute(null);
            bub.execute(null, [SELECT Id, Batch_Processed__c, blng_Account__c, blng_Order__c, blng_OrderProduct__c , blng_MatchingId__c, blng_StartDateTime__c, blng_EndDateTime__c, Booking__c, Student__c, Instance__c, Session__c, Rev_Rec_Date__c, PO_Number__c,Booking__r.OwnerId FROM Booking_Line__c]);        
            bub.Finish(null);
        Test.stopTest();
        
        System.assertEquals(true, [SELECT Id, Batch_Processed__c FROM Booking_Line__c].get(0).Batch_Processed__c);
    }
    
    @isTest
    static void test_GenerateusagesBatch1() {
        List<blng__Usage__c> usageList = [SELECT Id FROM blng__Usage__c];
        System.debug('@BookingUsageGlobalTest testSetup usageList.size(): ' + usageList.size());
        delete usageList;
        
        Test.startTest();
            date Dt = date.today();
            date Dt1 = date.today();
            BookingUsageBatch bub = new BookingUsageBatch(dt);
            BookingUsageBatch bub1 = new BookingUsageBatch(dt,dt1);
        Test.stopTest();
    }
    
    @isTest
    static void test_GenerateusagesBatch2() {
        Test.startTest();
            List<blng__Usage__c> usageList = [SELECT Id,blng__Account__c,blng__Order__c,blng__OrderProduct__c, Booking__c,blng__UsageSummary__c,blng__MatchingId__c,Booking_Line__c,blng__UsageSummary__r.blng__Invoice__r.blng__InvoiceStatus__c,blng__Quantity__c,blng__EndDateTime__c ,blng__StartDateTime__c,Student__c,Instance__c,OwnerId FROM blng__Usage__c];
            System.debug('@BookingUsageGlobalTest testSetup usageList.size(): ' + usageList.size());
        
            Booking__c booking = [SELECT Id FROM Booking__c LIMIT 1];
            booking.Status__c = 'Cancelled';
            booking.Status_Reason__c = 'Deferral';
            booking.BPP_Cancellation_Action__c = 'Don\'t Credit Fulfilled Materials';
            booking.BPP_Cancellation_Terms__c = 'Outside';
            update booking;
        Test.stopTest();
    }
}