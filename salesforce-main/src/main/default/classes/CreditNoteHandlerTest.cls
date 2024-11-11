@isTest
public class CreditNoteHandlerTest {
    @testSetup
    static void testSetup() {
        List<Address__c> addresses = new List<Address__c>();
        List<Product2> products = new List<Product2>();
        List<PricebookEntry> pricebookEntries = new List<PricebookEntry>();
        List<OrderItem> orderItems = new List<OrderItem>();

        /* START -- Create Account -- */
        Account clientAccount = TestDataFactory.createAccount(false, false, null, 0);
        clientAccount.Billing_Frequency__c = 'Monthly';
        clientAccount.Billing_Type__c = 'In Arrears';
        clientAccount.Charge_Trigger__c = 'Instance Start Date';
        insert clientAccount;

        Account studentAccount = TestDataFactory.createAccount(false, true, clientAccount.Id, 1);
        insert studentAccount;
        /* END -- Create Account -- */

        /* START -- Create Addresses -- */
        Country_list__c cntry = CreateTestData.createCountry1();
        addresses.add(TestDataFactory.createAddress(false, 0, clientAccount, cntry, true, true));
        addresses.add(TestDataFactory.createAddress(false, 1, studentAccount, cntry, true, true));
        insert addresses;
        /* END -- Create Addresses -- */

        /* START -- Create Stock Site -- */
        Stock_Site__c stockSite = new Stock_Site__c(
            Name = 'UK Warehouse',
            BPP_Product_Factory_ID__c = '9bc37088-2483-46f7-b4a4-62a83fefd662'
        );
        insert stockSite;
        /* END -- Create Stock Site -- */

        /* START -- Create Study Location -- */
        Study_Location__c studyLocation = TestDataFactory.createStudyLocation(false, 0, cntry);
        insert studyLocation;
        /* END -- Create Study Location -- */

        /* START -- Create Orders -- */
        Order order = TestDataFactory.createOrder(false, 0, clientAccount, null, addresses.get(0));
        order.Billing_Type__c = 'In Arrears';
        order.BPP_Internal_Comments__c = 'Booking';
        order.Stock_Site__c = stockSite.Id;
        insert order;
        /* END -- Create Orders -- */

        /* START -- Create Rules -- */
        blng__BillingRule__c billingRule = TestDataFactory.createBillingRule(false);
        billingRule.Name = 'Common Billing Rule';
        insert billingRule;

        blng__TaxRule__c taxRule = TestDataFactory.createTaxRule(false);
        taxRule.Name = 'Common Tax Rule';
        insert taxRule;

        blng__FinanceBook__c billingFinanceBook = TestDataFactory.createBillingFinanceBook(true);
        blng__BillingTreatment__c billingTreatment = TestDataFactory.createBillingTreatment(
            true,
            billingRule,
            billingFinanceBook
        );
        blng__RevenueRecognitionRule__c revenueRecognitionRule = TestDataFactory.createRevenueRecognitionRule(true);
        /* END -- Create Rules -- */

        /* START -- Create Products -- */
        Product2 courseProduct = TestDataFactory.createProduct(false, 0, billingRule, revenueRecognitionRule, taxRule);
        courseProduct.Family = 'Course';
        courseProduct.SBQQ__ChargeType__c = 'Usage';
        insert courseProduct;

        Product2 materialProduct = TestDataFactory.createProduct(
            false,
            1,
            billingRule,
            revenueRecognitionRule,
            taxRule
        );
        materialProduct.Family = 'Materials';
        materialProduct.Format__c = 'Physical';
        materialProduct.SBQQ__ChargeType__c = 'Usage';
        materialProduct.BPP_ProductFactoryID__c = '8a72e11d-e1b0-43b1-adae-4e0690369bf9';
        insert materialProduct;
        /* END -- Create Products -- */

        /* START -- Create PricebookEntries -- */
        PricebookEntry courseProductPricebookEntry = TestDataFactory.createPricebookEntry(false, courseProduct, null);
        PricebookEntry materialProductPricebookEntry = TestDataFactory.createPricebookEntry(
            false,
            materialProduct,
            null
        );
        pricebookEntries.add(courseProductPricebookEntry);
        pricebookEntries.add(materialProductPricebookEntry);
        insert pricebookEntries;
        /* END -- Create PricebookEntries -- */

        /* START -- Create Stock Management -- */
        Stock_Management__c stockManagement = TestDataFactory.createStockManagement(
            false,
            0,
            Date.newInstance(2023, 1, 1),
            Date.newInstance(2099, 1, 1),
            materialProduct.Id,
            null,
            materialProduct.BPP_ProductFactoryID__c,
            stockSite.Id
        );
        stockManagement.Total__c = 5;
        insert stockManagement;
        /* END -- Create Stock Management -- */

        /* START -- Create Product Features -- */
        SBQQ__ProductFeature__c productFeature = new SBQQ__ProductFeature__c(
            Name = 'Materials',
            SBQQ__Number__c = 1,
            SBQQ__ConfiguredSKU__c = courseProduct.Id
        );
        insert productFeature;
        /* END -- Create Product Features -- */

        /* START -- Create Product Options -- */
        SBQQ__ProductOption__c productOption = TestDataFactory.createProductOption(
            true,
            courseProduct,
            materialProduct,
            productFeature,
            'Deliver to BPP Location'
        );
        /* END -- Create Product Options -- */

        /* START -- Create Instance -- */
        Instance__c instance = TestDataFactory.createInstance(true, 0, courseProduct, studyLocation);
        /* END -- Create Instance -- */

        /* START -- Create Sessions -- */
        Session__c session = TestDataFactory.createSession(true, 0, instance, courseProduct, 0, 10);
        /* END -- Create Sessions -- */

        /* START -- Create Parent Order Products -- */
        OrderItem parentOrderLine = TestDataFactory.createOrderLine(
            true,
            order,
            courseProduct,
            null,
            courseProductPricebookEntry,
            billingRule,
            revenueRecognitionRule,
            taxRule,
            ''
        );
        /* END -- Create Parent Order Products -- */

        /* START -- Create Child Order Products -- */
        OrderItem childOrderLine = TestDataFactory.createOrderLine(
            true,
            order,
            courseProduct,
            parentOrderLine,
            materialProductPricebookEntry,
            billingRule,
            revenueRecognitionRule,
            taxRule,
            'Material'
        );
        /* END -- Create Child Order Products -- */

        /* START -- Create Usage Summary -- */
        blng__UsageSummary__c usageSummary = TestDataFactory.createBookingSummary(false, childOrderLine);
        usageSummary.blng__Order__c = order.Id;
        insert usageSummary;
        /* END -- Create Usage Summary -- */

        order.Status = 'Activated';
        update order;

        /* START -- Create Booking -- */
        Booking__c booking = TestDataFactory.createBooking(false, instance, order, studentAccount);
        booking.Status__c = 'Confirmed';
        insert booking;
        Test.setMock(HttpCalloutMock.class, new AWSCalloutMock());
        /* END -- Create Booking -- */

        /* START -- Create Usage -- */
        BookingLineBatch testBatch = new BookingLineBatch(
            'blng_StartDateTime__c',
            'Batch_Processed__c',
            'On_Hold__c',
            'Confirmed'
        );
        Database.executeBatch(testBatch);
        /*  END -- Create Usage -- */

        /* START -- Create Invoice -- */
        blng__Invoice__c invoice = new blng__Invoice__c();
        invoice.SFBD__HoldCollections__c = false;
        invoice.blng__Account__c = clientAccount.Id;
        invoice.blng__InvoiceDate__c = System.today();
        insert invoice;
        /* END -- Create Invoice -- */

        // Insert a Legal Entity
        insert TestDataFactory.buildDefaultLegalEntity();

        /* START -- Create Invoice Line -- */
        blng__InvoiceLine__c invoiceLine = new blng__InvoiceLine__c();
        invoiceLine.blng__Invoice__c = invoice.Id;
        invoiceLine.blng__Quantity__c = 1;
        invoiceLine.blng__Product__c = materialProduct.Id;
        invoiceLine.blng__OrderProduct__c = childOrderLine.Id;
        invoiceLine.blng__UsageSummary__c = usageSummary.Id;
        insert invoiceLine;
        /* END -- Create Invoice Line -- */

        invoice.blng__InvoiceStatus__c = 'Posted';
        update invoice;

        Authorisation_Token__c authToken = TestDataFactory.createAuthorisationToken(true);
    }

    @isTest
    static void itShouldCreateACreditNoteRecord() {
        Test.startTest();
        Delivery__c delivery = [
            SELECT Id, Delivery_Status__c, Sent_for_Fulfilment_On__c, Stock_Allocated__c, Stock_Management_Name__c
            FROM Delivery__c
        ];
        delivery.Delivery_Status__c = 'Sent for Fulfilment';
        update delivery;

        Booking__c booking = [SELECT Id FROM Booking__c LIMIT 1];
        booking.Status__c = 'Cancelled';
        booking.Status_Reason__c = 'Deferral';
        booking.BPP_Cancellation_Action__c = 'Credit Fulfilled Materials';
        booking.BPP_Cancellation_Terms__c = 'Inside';
        update booking;
        Test.setMock(HttpCalloutMock.class, new AWSCalloutMock());

        List<blng__CreditNote__c> creditNote = [SELECT Id FROM blng__CreditNote__c];
        Assert.areEqual(1, creditNote.size(), 'One Credit Note record should have been created.');
        Test.stopTest();
    }
}
