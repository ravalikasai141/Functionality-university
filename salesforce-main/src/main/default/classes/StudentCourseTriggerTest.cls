@isTest
private class StudentCourseTriggerTest {
    @TestSetup
    private static void setup() {
        Authorisation_Token__c authToken = TestDataFactory.createAuthorisationToken(false);
        authToken.Expires_In__c = 1000;
        insert authToken;
        
        blng__BillingRule__c billingRule = TestDataFactory.createBillingRule(true);
        blng__FinanceBook__c billingFinanceBook = TestDataFactory.createBillingFinanceBook(true);
        blng__RevenueRecognitionRule__c revenueRecognitionRule = TestDataFactory.createRevenueRecognitionRule(true);
        blng__TaxRule__c taxRule = TestDataFactory.createTaxRule(true);
        Id recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
            .get('Student_Account')
            .getRecordTypeId();

        Account account = new Account(
            RecordTypeId = recordTypeId,
            FirstName = 'Test',
            LastName = 'Tester',
            Salutation = 'Mr',
            PersonEmail = 'test@bpp.com',
            Preferred_Email__pc = 'Personal',
            Personal_Email__pc = 'test@bpp.com'
        );

        insert account;

        insert new Hub_Account__c(
            Student__c = account.Id,
            Auth0_Id__c = 'sub|12345',
            Hub_Username__c = 'testuserproducts@bpp.com'
        );

        Product2 product = new Product2(Name = 'Test Course', BPP_ProductFactoryID__c = 'test-123');

        insert product;

        PricebookEntry pbentry = new PricebookEntry(
            IsActive = true,
            Product2Id = product.Id,
            UnitPrice = 10,
            Pricebook2Id = Test.getStandardPricebookId()
        );
        insert pbentry;

        Instance__c instance = new Instance__c(Product__c = product.Id, Instance_ID__c = 'test-321');

        insert instance;

        Stock_Site__c site = new Stock_Site__c(Name = 'Test Site');

        insert site;

        Order order = new Order(
            AccountId = account.Id,
            Name = 'Test order',
            Status = 'Draft',
            EffectiveDate = Date.today(),
            blng__BillingDayOfMonth__c = '1',
            Billing_Mode__c = 'Billed in Salesforce',
            Pricebook2Id = Test.getStandardPricebookId(),
            Stock_Site__c = site.Id
        );

        insert order;

        OrderItem orderLine = new OrderItem(
            OrderId = order.Id,
            PricebookEntryId = pbentry.Id,
            SBQQ__Activated__c = true,
            Product2Id = product.Id,
            SBQQ__ChargeType__c = 'One-Time',
            UnitPrice = 10,
            blng__BillingRule__c = billingRule.Id,
            blng__RevenueRecognitionRule__c = revenueRecognitionRule.Id,
            blng__TaxRule__c = taxRule.Id,
            Quantity = 1,
            SBQQ__QuotedQuantity__c = 1
        );

        insert orderLine;

        order.Status = 'Activated';
        update order;
    }

    @isTest
    private static void itShouldTriggerAnEvent() {
        StreamingService.canFetchStreams = true;

        Account account = [SELECT Id, FirstName, LastName, Phone FROM Account WHERE LastName = 'Tester'];
        Instance__c instance = [SELECT Id, Instance_ID__c FROM Instance__c WHERE Instance_ID__c = 'test-321'];
        Order order = [SELECT Id FROM Order WHERE Name = 'Test Order'];
        Hub_Account__c hubAccount = [SELECT Id, Hub_Username__c FROM Hub_Account__c LIMIT 1];

        MockHttpClient mock = new MockHttpClient();
        mock.addResponse('@', 200);
        
        SingleRequestMock mock2 = new SingleRequestMock(200, 'OK', '{"status":"OK"}', null);
        String message =
            '{"email": "' +
            hubAccount.Hub_Username__c +
            '","firstname": "' +
            account.FirstName +
            '","lastname": "' +
            account.LastName +
            '","phone": "' +
            account.Phone +
            '","productId": "' +
            instance.Instance_ID__c +
            '","bookingActivatedOn": "' +
            System.today() +
            '"}';
        String awsEndpoint = AWSsampleAPIUtil.retrieveAWSEndpoint();
        String endpointWithMessage = awsEndpoint + '/booking/confirmed?message=' + EncodingUtil.urlEncode(message, 'UTF-8');
        
        Map<String, HttpCalloutMock> multipleCalloutMap = new Map<String, HttpCalloutMock>();
        multipleCalloutMap.put(new EventAPIClient().endpoint, mock);
        multipleCalloutMap.put(endpointWithMessage, mock2);
        HttpCalloutMock multiCalloutMock = new MultiRequestMock(multipleCalloutMap);

        // Disable outbound events killswitch by default
        TestUtilities.mockKillswitch(killswitch.BLOCK_OUTBOUND_EVENTS, false);

        // GIVEN a student course is created as a result of a booking
        // WHEN the trigger runs
        System.Test.startTest();
        
        Booking__c booking = new Booking__c(
            Student__c = account.Id,
            Instance__c = instance.Id,
            Order__c = order.Id,
            Status__c = 'Confirmed',
            Hub_Account__c = hubAccount.Id
        );
        
        Test.setMock(HttpCalloutMock.class, multiCalloutMock);
        
        insert booking;

        System.Test.getEventBus().deliver();
        System.Test.stopTest();

        List<Object> payloads = (List<Object>) JSON.deserializeUntyped(mock.requests[0].getBody());
        Map<String, Object> payload = (Map<String, Object>) payloads.get(0);
        Map<String, Object> detail = (Map<String, Object>) payload.get('detail');
        Map<String, Object> data = (Map<String, Object>) detail.get('data');
        List<Object> productData = (List<Object>) data.get('products');
        Map<String, Object> products = (Map<String, Object>) productData[0];

        // THEN I expect it to trigger an event with the correct payload
        Assert.areEqual(1, mock.processedRequests, 'Event should contain one request.');
        Assert.areEqual('test-123', (String) products.get('productId'), 'Event Product Id should equal "test-123".');
        Assert.areEqual('test-321', (String) products.get('instanceId'), 'Event Instance Id should equal "test-321".');
    }
}