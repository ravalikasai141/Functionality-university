@isTest
private class AWSsampleAPIcallCancellationTest {
    @testSetup
    static void testSetup() {
        Database.DMLOptions dbDML = new Database.DMLOptions();
        dbDML.DuplicateRuleHeader.allowSave = true;
        dbDML.DuplicateRuleHeader.runAsCurrentUser = true;

        Account clientAccount = TestDataFactory.createAccount(false, false, null, 0);
        Database.insert(clientAccount, dbDML);

        Account studentAccount = TestDataFactory.createAccount(false, true, clientAccount.Id, 1);
        Database.insert(studentAccount, dbDML);
        
        Hub_Account__c hubAccount = new Hub_Account__c(
            Hub_Username__c = studentAccount.PersonEmail, 
            Student__c = studentAccount.Id
        );
        insert hubAccount;

        country_list__c cntry = new country_list__c(
            Name = 'United Kingdom',
            ISO_Code__c = 'GBR',
            country_code_2__c = 'GB'
        );
        insert cntry;

        Address__c address = TestDataFactory.createAddress(false, 0, clientAccount, cntry, true, false);
        Database.insert(address, dbDML);

        Order order = TestDataFactory.createOrder(true, 0, clientAccount, null, address);
        blng__BillingRule__c billingRule = TestDataFactory.createBillingRule(true);
        blng__FinanceBook__c billingFinanceBook = TestDataFactory.createBillingFinanceBook(true);
        blng__BillingTreatment__c billingTreatment = TestDataFactory.createBillingTreatment(
            true,
            billingRule,
            billingFinanceBook
        );
        blng__RevenueRecognitionRule__c revenueRecognitionRule = TestDataFactory.createRevenueRecognitionRule(true);
        blng__TaxRule__c taxRule = TestDataFactory.createTaxRule(true);
        Product2 product = TestDataFactory.createProduct(true, 0, billingRule, revenueRecognitionRule, taxRule);
        Instance__c instance = TestDataFactory.createInstance(true, 0, product);
        PricebookEntry priceBookEntry = (TestDataFactory.createPricebookEntry(true, product, null));
        OrderItem orderLine = TestDataFactory.createOrderLine(
            true,
            order,
            product,
            null,
            priceBookEntry,
            billingRule,
            revenueRecognitionRule,
            taxRule,
            'Materials'
        );
        Authorisation_Token__c authToken = TestDataFactory.createAuthorisationToken(true);
    }

    @isTest
    static void itShouldInitiateBookingCancelledCalloutAndCreateIntegrationLog() {
        Account studentAccount = [SELECT Id, Client__c FROM Account WHERE IsPersonAccount = TRUE];
        Hub_Account__c hubAccount = [SELECT Id FROM Hub_Account__c];

        Order order = [SELECT Id FROM Order];
        order.Status = 'Activated';
        update order;

        Instance__c instance = [SELECT Id, Instance_ID__c FROM Instance__c];

        Test.startTest();
        Booking__c booking = TestDataFactory.createBooking(false, instance, order, studentAccount);
        booking.Hub_Account__c = hubAccount.Id;
        booking.Status__c = 'Cancelled';
        booking.Status_Reason__c = 'Deferral';
        booking.BPP_Cancellation_Action__c = 'Don\'t Credit Fulfilled Materials';
        booking.BPP_Cancellation_Terms__c = 'Outside';
        insert booking;

        Test.setMock(HttpCalloutMock.class, new AWSCalloutMock());
        Test.stopTest();

        List<Integration_Log__c> integrationLogList = [SELECT Id FROM Integration_Log__c];
        Assert.isTrue(
            integrationLogList.size() > 0,
            'Integration Logs for Booking cancellation should have been created.'
        );
    }
}