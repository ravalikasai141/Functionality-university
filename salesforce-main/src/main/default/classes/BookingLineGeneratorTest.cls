@isTest
public class BookingLineGeneratorTest {
    private static final String SINGLE_ORDER_CHECK = 'One Order should have been created';

    @testSetup
    static void testSetup() {
        List<Address__c> addresses = new List<Address__c>();
        List<Order> orders = new List<Order>();
        List<Product2> parentProducts = new List<Product2>();
        List<Product2> childProducts = new List<Product2>();
        List<PricebookEntry> priceBookEntries = new List<PricebookEntry>();
        List<SBQQ__ProductFeature__c> productFeatures = new List<SBQQ__ProductFeature__c>();
        List<SBQQ__ProductOption__c> productOptions = new List<SBQQ__ProductOption__c>();
        List<Instance__c> instances = new List<Instance__c>();
        List<Session__c> sessions = new List<Session__c>();
        List<OrderItem> orderProducts = new List<OrderItem>();
        List<blng__UsageSummary__c> usageSummaries = new List<blng__UsageSummary__c>();

        /* START -- Create Account -- */
        Account clientAccount = new Account(Name = 'TestDataFactoryClient');
        clientAccount.Billing_Type__c = 'In Advance';
        clientAccount.Charge_Trigger__c = 'Instance Start Date';
        insert clientAccount;

        Account studentAccount = TestDataFactory.createAccount(false, true, clientAccount.Id, 1);
        studentAccount.FirstName = 'TestDataFactoryStudent';
        insert studentAccount;
        /* END -- Create Account -- */

        /* START -- Create Addresses -- */
        country_list__c cntry = CreateTestData.createCountry1();
        addresses.add(TestDataFactory.createAddress(false, 0, clientAccount, cntry, true, true));
        addresses.add(TestDataFactory.createAddress(false, 1, studentAccount, cntry, true, true));
        insert addresses;
        /* END -- Create Addresses -- */

        /* START -- Create Hub Account -- */
        Hub_Account__c hubAccount = new Hub_Account__c(
            Hub_Username__c = studentAccount.PersonEmail,
            Student__c = studentAccount.Id
        );
        insert hubAccount;
        /* END -- Create Hub Account -- */

        /* START -- Create Study Location -- */
        Study_Location__c studyLocation = TestDataFactory.createStudyLocation(false, 0, cntry);
        insert studyLocation;
        /* END -- Create Study Location -- */

        /* START -- Create Orders -- */
        Order orderBooking = TestDataFactory.createOrder(false, 0, clientAccount, null, addresses.get(0));
        orderBooking.BPP_Internal_Comments__c = 'Booking';
        orders.add(orderBooking);

        Order orderCBABooking = TestDataFactory.createOrder(false, 1, clientAccount, null, addresses.get(0));
        orderCBABooking.BPP_Internal_Comments__c = 'CBA Booking';
        orders.add(orderCBABooking);

        Order orderMaterialOrFeeBooking = TestDataFactory.createOrder(false, 2, clientAccount, null, addresses.get(0));
        orderMaterialOrFeeBooking.BPP_Internal_Comments__c = 'Material or Fee Booking';
        orders.add(orderMaterialOrFeeBooking);

        insert orders;
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

        /* START -- Create Main Products -- */
        // Course Product for 'Booking' record type
        Product2 productBooking = TestDataFactory.createProduct(false, 0, billingRule, revenueRecognitionRule, taxRule);
        productBooking.Family = 'Course';
        productBooking.SBQQ__ChargeType__c = 'Usage';
        parentProducts.add(productBooking);

        // Exam Product for 'CBA Booking' record type
        Product2 productCBABooking = TestDataFactory.createProduct(
            false,
            1,
            billingRule,
            revenueRecognitionRule,
            taxRule
        );
        productCBABooking.Family = 'Exam';
        productCBABooking.Name = 'CBA Test Product';
        productCBABooking.Qualification__c = 'ICAEW';
        productCBABooking.SBQQ__ChargeType__c = 'Usage';
        parentProducts.add(productCBABooking);

        // Material Product for 'Material or Fee Booking' record type
        Product2 productMaterialOrFeeBooking = TestDataFactory.createProduct(
            false,
            2,
            billingRule,
            revenueRecognitionRule,
            taxRule
        );
        productMaterialOrFeeBooking.Family = 'Materials';
        productMaterialOrFeeBooking.SBQQ__ChargeType__c = 'One-Time';
        parentProducts.add(productMaterialOrFeeBooking);

        insert parentProducts;
        /* END -- Create Main Products -- */

        /* START -- Create Child Products -- */
        // Session Product for Course Product
        Product2 productBookingSession = TestDataFactory.createProduct(
            false,
            0,
            billingRule,
            revenueRecognitionRule,
            taxRule
        );
        productBookingSession.Family = 'Session';
        childProducts.add(productBookingSession);

        // Material Product for Course Product
        Product2 productBookingMaterial = TestDataFactory.createProduct(
            false,
            0,
            billingRule,
            revenueRecognitionRule,
            taxRule
        );
        productBookingMaterial.Family = 'Materials';
        productBookingMaterial.Format__c = 'Physical';
        childProducts.add(productBookingMaterial);

        insert childProducts;
        /* END -- Create Child Products -- */

        /* START -- Create PriceBookEntries -- */
        PricebookEntry pricebookEntryProductBooking = TestDataFactory.createPricebookEntry(false, productBooking, null);
        priceBookEntries.add(pricebookEntryProductBooking);
        PricebookEntry pricebookEntryProductCBABooking = TestDataFactory.createPricebookEntry(
            false,
            productCBABooking,
            null
        );
        priceBookEntries.add(pricebookEntryProductCBABooking);
        PricebookEntry pricebookEntryProductMaterialOrFeeBooking = TestDataFactory.createPricebookEntry(
            false,
            productMaterialOrFeeBooking,
            null
        );
        priceBookEntries.add(pricebookEntryProductMaterialOrFeeBooking);
        PricebookEntry pricebookEntryProductBookingSession = TestDataFactory.createPricebookEntry(
            false,
            productBookingSession,
            null
        );
        priceBookEntries.add(pricebookEntryProductBookingSession);
        PricebookEntry pricebookEntryProductBookingMaterial = TestDataFactory.createPricebookEntry(
            false,
            productBookingMaterial,
            null
        );
        priceBookEntries.add(pricebookEntryProductBookingMaterial);
        insert priceBookEntries;
        /* END -- Create PriceBookEntrys -- */

        /* START -- Create Product Features -- */
        SBQQ__ProductFeature__c productBookingSessionFeature = new SBQQ__ProductFeature__c(
            Name = 'Session',
            SBQQ__Number__c = 1,
            SBQQ__ConfiguredSKU__c = productBooking.Id
        );
        productFeatures.add(productBookingSessionFeature);
        SBQQ__ProductFeature__c productBookingMaterialFeature = new SBQQ__ProductFeature__c(
            Name = 'Materials',
            SBQQ__Number__c = 2,
            SBQQ__ConfiguredSKU__c = productBooking.Id
        );
        productFeatures.add(productBookingMaterialFeature);
        insert productFeatures;
        /* END -- Create Product Features -- */

        /* START -- Create Product Options -- */
        productOptions.add(
            TestDataFactory.createProductOption(
                false,
                productBooking,
                productBookingSession,
                productBookingSessionFeature,
                null
            )
        );
        productOptions.add(
            TestDataFactory.createProductOption(
                false,
                productBooking,
                productBookingMaterial,
                productBookingMaterialFeature,
                'Deliver to BPP Location'
            )
        );
        insert productOptions;
        /* END -- Create Product Options -- */

        /* START -- Create Instance -- */
        Instance__c instanceProductBooking = TestDataFactory.createInstance(false, 0, productBooking, studyLocation);
        instances.add(instanceProductBooking);

        Instance__c instanceProductCBABooking = new Instance__c();
        instanceProductCBABooking.RecordTypeId = Schema.SObjectType.Instance__c.getRecordTypeInfosByDeveloperName()
            .get('CBA_Instance')
            .getRecordTypeId();
        instanceProductCBABooking.Instance_Name__c = 'CBA - South - 01/02/2023 - Afternoon';
        instanceProductCBABooking.Sitting__c = 'CBA DEC23';
        instanceProductCBABooking.Start_Date__c = System.today();
        instanceProductCBABooking.End_Date__c = System.today();
        instanceProductCBABooking.BPP_Instance_Status__c = 'Active';
        instanceProductCBABooking.Session_Duration__c = 'Afternoon';
        instances.add(instanceProductCBABooking);

        insert instances;
        /* END -- Create Instance -- */

        /* START -- Create Sessions -- */
        sessions.add(TestDataFactory.createSession(false, 0, instanceProductBooking, productBookingSession, 0, 10));

        Session__c session = new Session__c();
        session.Instance__c = instanceProductCBABooking.Id;
        session.BPP_PF_SessionId__c = String.valueOf(1);
        session.Session_Date__c = Date.today();
        session.Start_Time__c = '10:00:00';
        session.End_Time__c = '12:00:00';
        session.Booked__c = 0;
        session.Session_Capacity__c = 10;
        sessions.add(session);

        insert sessions;
        /* END -- Create Sessions -- */

        /* START -- Create CBA -- */
        CBA__c cba = new CBA__c();
        cba.Product__c = productCBABooking.Id;
        cba.Instance__c = instanceproductCBABooking.Id;

        insert cba;
        /* END -- Create CBA -- */

        /* START -- Create Parent Order Product for Booking record type -- */
        OrderItem parentOrderItem = TestDataFactory.createOrderLine(
            false,
            orderBooking,
            productBooking,
            null,
            pricebookEntryProductBooking,
            billingRule,
            revenueRecognitionRule,
            taxRule,
            ''
        );
        insert parentOrderItem;
        /* END -- Create Parent Order Product for Booking record type -- */

        /* START -- Create Order Products -- */
        for (Integer i = 0; i < 4; i++) {
            if (i == 0) {
                orderProducts.add(
                    TestDataFactory.createOrderLine(
                        false,
                        orderBooking,
                        productBooking,
                        parentOrderItem,
                        pricebookEntryProductBookingSession,
                        billingRule,
                        revenueRecognitionRule,
                        taxRule,
                        'Session'
                    )
                );
            }
            if (i == 1) {
                orderProducts.add(
                    TestDataFactory.createOrderLine(
                        false,
                        orderBooking,
                        productBooking,
                        parentOrderItem,
                        pricebookEntryProductBookingMaterial,
                        billingRule,
                        revenueRecognitionRule,
                        taxRule,
                        'Materials'
                    )
                );
            }
            if (i == 2) {
                orderProducts.add(
                    TestDataFactory.createOrderLine(
                        false,
                        orderCBABooking,
                        productCBABooking,
                        null,
                        pricebookEntryProductCBABooking,
                        billingRule,
                        revenueRecognitionRule,
                        taxRule,
                        'Exam'
                    )
                );
            }
            if (i == 3) {
                orderProducts.add(
                    TestDataFactory.createOrderLine(
                        false,
                        orderMaterialOrFeeBooking,
                        productMaterialOrFeeBooking,
                        null,
                        pricebookEntryProductMaterialOrFeeBooking,
                        billingRule,
                        revenueRecognitionRule,
                        taxRule,
                        'Materials'
                    )
                );
            }
        }
        insert orderProducts;
        /* END -- Create Order Products -- */

        /* START -- Create Usage Summaries -- */
        for (Integer i = 0; i < orderProducts.size(); i++) {
            usageSummaries.add(TestDataFactory.createBookingSummary(false, orderProducts.get(i)));
        }
        insert usageSummaries;
        /* END -- Create Usage Summaries -- */

        Authorisation_Token__c authToken = TestDataFactory.createAuthorisationToken(true);
    }

    public static Boolean updateOrder(Order order) {
        order.Status = 'Activated';

        Boolean orderUpdated = false;
        Database.SaveResult orderSaveResult = Database.update(order, true);
        if (orderSaveResult.isSuccess()) {
            orderUpdated = true;
        }
        return orderUpdated;
    }

    @isTest
    static void itShouldCreateAnOnHoldBookingWithTwoBookingLines() {
        List<Order> orderList = [SELECT Id FROM Order WHERE BPP_Internal_Comments__c = 'Booking'];
        Assert.areEqual(1, orderList.size(), SINGLE_ORDER_CHECK);

        Order order = orderList.get(0);
        Boolean orderUpdated = updateOrder(order);
        if (orderUpdated) {
            Account clientAccount = [SELECT Id FROM Account WHERE Name = 'TestDataFactoryClient' LIMIT 1];
            Account studentAccount = [SELECT Id FROM Account WHERE FirstName = 'TestDataFactoryStudent' LIMIT 1];
            Instance__c instance = [SELECT Id FROM Instance__c WHERE RecordType.Name = 'Instance' LIMIT 1];

            Booking__c booking = new Booking__c();
            booking.Account__c = clientAccount.Id;
            booking.Instance__c = instance.Id;
            booking.Status__c = 'On Hold';
            booking.On_Hold_Reason__c = 'Test Reason';
            booking.Order__c = order.Id;
            booking.RecordTypeId = Schema.SObjectType.Booking__c.getRecordTypeInfosByDeveloperName()
                .get('Booking')
                .getRecordTypeId();
            booking.Student__c = studentAccount.Id;

            Boolean bookingInserted = false;
            Database.SaveResult bookingSaveResult = Database.insert(booking, true);
            if (bookingSaveResult.isSuccess()) {
                bookingInserted = true;
            }

            if (bookingInserted) {
                List<Booking_Line__c> bookingLineList = [
                    SELECT Id, Product_Family__c
                    FROM Booking_Line__c
                    WHERE Booking__c = :booking.Id
                ];
                Assert.areEqual(2, bookingLineList.size(), 'Two Booking Lines should have been created.');
                Assert.areEqual(
                    'Session',
                    bookingLineList.get(0).Product_Family__c,
                    'First Booking Line should be for Session Product.'
                );
                Assert.areEqual(
                    'Materials',
                    bookingLineList.get(1).Product_Family__c,
                    'Second Booking Line should be for Material Product.'
                );
            }
        }
    }

    @isTest
    static void itShouldCreateAnOnHoldBookingUpdateToConfirmedAndTriggerConfirmedCallout() {
        List<Order> orderList = [SELECT Id FROM Order WHERE BPP_Internal_Comments__c = 'Booking'];
        Assert.areEqual(1, orderList.size(), SINGLE_ORDER_CHECK);

        Order order = orderList.get(0);
        Boolean orderUpdated = updateOrder(order);
        if (orderUpdated) {
            Account clientAccount = [SELECT Id FROM Account WHERE Name = 'TestDataFactoryClient' LIMIT 1];
            Account studentAccount = [SELECT Id FROM Account WHERE FirstName = 'TestDataFactoryStudent' LIMIT 1];
            Instance__c instance = [SELECT Id FROM Instance__c WHERE RecordType.Name = 'Instance' LIMIT 1];
            Hub_Account__c hubAccount = [SELECT Id FROM Hub_Account__c LIMIT 1];

            Booking__c booking = new Booking__c();
            booking.Account__c = clientAccount.Id;
            booking.Instance__c = instance.Id;
            booking.Status__c = 'On Hold';
            booking.On_Hold_Reason__c = 'Test Reason';
            booking.Order__c = order.Id;
            booking.RecordTypeId = Schema.SObjectType.Booking__c.getRecordTypeInfosByDeveloperName()
                .get('Booking')
                .getRecordTypeId();
            booking.Student__c = studentAccount.Id;
            booking.Hub_Account__c = hubAccount.Id;

            Boolean bookingInserted = false;
            Database.SaveResult bookingSaveResult = Database.insert(booking, true);
            if (bookingSaveResult.isSuccess()) {
                bookingInserted = true;
            }

            if (bookingInserted) {
                List<blng__Usage__c> usageList = [SELECT Id FROM blng__Usage__c];

                List<Booking_Line__c> bookingLineList = [
                    SELECT Id, Product_Family__c
                    FROM Booking_Line__c
                    WHERE Booking__c = :booking.Id
                ];
                for (Booking_Line__c bookingLine : bookingLineList) {
                    bookingLine.blng_StartDateTime__c = null;
                    bookingLine.blng_EndDateTime__c = null;
                    bookingLine.Rev_Rec_Date__c = null;
                }
                update bookingLineList;

                Test.startTest();
                Booking__c bookingAfter = [SELECT Id FROM Booking__c WHERE Id = :booking.Id];
                bookingAfter.Status__c = 'Confirmed';
                update bookingAfter;
                Test.setMock(HttpCalloutMock.class, new AWSCalloutMock());
                Test.stopTest();

                List<Integration_Log__c> integrationLogList = [SELECT Id FROM Integration_Log__c];
                Assert.isTrue(
                    integrationLogList.size() > 0,
                    'Integration Logs for Booking confirmation should have been created.'
                );
            }
        }
    }

    @isTest
    static void itShouldCreateAnOnHoldBookingUpdateToCancelledAndTriggerConfirmedCallout() {
        List<Order> orderList = [SELECT Id FROM Order WHERE BPP_Internal_Comments__c = 'Booking'];
        Assert.areEqual(1, orderList.size(), SINGLE_ORDER_CHECK);

        Order order = orderList.get(0);
        Boolean orderUpdated = updateOrder(order);
        if (orderUpdated) {
            Account clientAccount = [SELECT Id FROM Account WHERE Name = 'TestDataFactoryClient' LIMIT 1];
            Account studentAccount = [SELECT Id FROM Account WHERE FirstName = 'TestDataFactoryStudent' LIMIT 1];
            Instance__c instance = [SELECT Id FROM Instance__c WHERE RecordType.Name = 'Instance' LIMIT 1];
            Hub_Account__c hubAccount = [SELECT Id FROM Hub_Account__c LIMIT 1];

            Booking__c booking = new Booking__c();
            booking.Account__c = clientAccount.Id;
            booking.Instance__c = instance.Id;
            booking.Status__c = 'Confirmed';
            booking.Order__c = order.Id;
            booking.RecordTypeId = Schema.SObjectType.Booking__c.getRecordTypeInfosByDeveloperName()
                .get('Booking')
                .getRecordTypeId();
            booking.Student__c = studentAccount.Id;
            booking.Hub_Account__c = hubAccount.Id;

            Boolean bookingInserted = false;
            Database.SaveResult bookingSaveResult = Database.insert(booking, true);
            if (bookingSaveResult.isSuccess()) {
                bookingInserted = true;
            }

            if (bookingInserted) {
                Test.startTest();
                Booking__c bookingAfter = [SELECT Id FROM Booking__c WHERE Id = :booking.Id];
                bookingAfter.Status__c = 'Cancelled';
                bookingAfter.Status_Reason__c = 'Internal Error';
                bookingAfter.BPP_Cancellation_Action__c = 'Don\'t Credit Fulfilled Materials';
                bookingAfter.BPP_Cancellation_Terms__c = 'Outside';
                update bookingAfter;
                Test.setMock(HttpCalloutMock.class, new AWSCalloutMock());
                Test.stopTest();

                List<Integration_Log__c> integrationLogList = [SELECT Id FROM Integration_Log__c];
                Assert.isTrue(
                    integrationLogList.size() > 0,
                    'Integration Logs for Booking cancellation should have been created.'
                );
            }
        }
    }

    @isTest
    static void itShouldCreateAnOnHoldCBABookingWithABookingLine() {
        List<Order> orderList = [SELECT Id FROM Order WHERE BPP_Internal_Comments__c = 'CBA Booking'];
        Assert.areEqual(1, orderList.size(), SINGLE_ORDER_CHECK);

        Order order = orderList.get(0);
        Boolean orderUpdated = updateOrder(order);
        if (orderUpdated) {
            Account clientAccount = [SELECT Id FROM Account WHERE Name = 'TestDataFactoryClient' LIMIT 1];
            Account studentAccount = [SELECT Id FROM Account WHERE FirstName = 'TestDataFactoryStudent' LIMIT 1];
            Instance__c instance = [SELECT Id FROM Instance__c WHERE RecordType.Name = 'CBA Instance' LIMIT 1];
            CBA__c cba = [SELECT Id FROM CBA__c LIMIT 1];

            Booking__c booking = new Booking__c();
            booking.Account__c = clientAccount.Id;
            booking.CBA__c = cba.Id;
            booking.Instance__c = instance.Id;
            booking.Institute_Number__c = '12345';
            booking.Status__c = 'On Hold';
            booking.On_Hold_Reason__c = 'Test Reason';
            booking.Order__c = order.Id;
            booking.RecordTypeId = Schema.SObjectType.Booking__c.getRecordTypeInfosByDeveloperName()
                .get('CBA_Booking')
                .getRecordTypeId();
            booking.Student__c = studentAccount.Id;

            Boolean bookingInserted = false;
            Database.SaveResult bookingSaveResult = Database.insert(booking, true);
            if (bookingSaveResult.isSuccess()) {
                bookingInserted = true;
            }

            if (bookingInserted) {
                List<Booking_Line__c> bookingLineList = [
                    SELECT Id, Product_Family__c
                    FROM Booking_Line__c
                    WHERE Booking__c = :booking.Id
                ];
                Assert.areEqual(1, bookingLineList.size(), 'One Booking Line should have been created.');
                Assert.areEqual(
                    'Exam',
                    bookingLineList.get(0).Product_Family__c,
                    'Booking Line should be for Exam Product.'
                );
            }
        }
    }

    @isTest
    static void itShouldCreateAnOnHoldMaterialOrFeeBookingWithABookingLine() {
        List<Order> orderList = [SELECT Id FROM Order WHERE BPP_Internal_Comments__c = 'Material or Fee Booking'];
        Assert.areEqual(1, orderList.size(), SINGLE_ORDER_CHECK);

        Order order = orderList.get(0);
        Boolean orderUpdated = updateOrder(order);
        if (orderUpdated) {
            Account clientAccount = [SELECT Id FROM Account WHERE Name = 'TestDataFactoryClient' LIMIT 1];
            Account studentAccount = [SELECT Id FROM Account WHERE FirstName = 'TestDataFactoryStudent' LIMIT 1];

            Booking__c booking = new Booking__c();
            booking.Account__c = clientAccount.Id;
            booking.Status__c = 'On Hold';
            booking.On_Hold_Reason__c = 'Test Reason';
            booking.Order__c = order.Id;
            booking.RecordTypeId = Schema.SObjectType.Booking__c.getRecordTypeInfosByDeveloperName()
                .get('Material_Booking')
                .getRecordTypeId();
            booking.Student__c = studentAccount.Id;

            Boolean bookingInserted = false;
            Database.SaveResult bookingSaveResult = Database.insert(booking, true);
            if (bookingSaveResult.isSuccess()) {
                bookingInserted = true;
            }

            if (bookingInserted) {
                List<Booking_Line__c> bookingLineList = [
                    SELECT Id, Product_Family__c
                    FROM Booking_Line__c
                    WHERE Booking__c = :booking.Id
                ];
                Assert.areEqual(1, bookingLineList.size(), 'One Booking Line should have been created.');
                Assert.areEqual(
                    'Materials',
                    bookingLineList.get(0).Product_Family__c,
                    'Booking Line should be for Material Product.'
                );
            }
        }
    }
}
