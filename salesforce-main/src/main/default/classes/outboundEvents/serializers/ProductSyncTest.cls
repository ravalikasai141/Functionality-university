@isTest
private class ProductSyncTest {
    @TestSetup
    private static void setup() {
        Programme__c programme = new Programme__c(Name = 'Test1Programme', Programme_Id__c = 'test-123');

        insert programme;

        Product2 product = new Product2(
            Name = 'TestCourse',
            BPP_ProductFactoryID__c = 'test-123',
            Programme__c = programme.Id,
            Mode__c = 'Part Time Distance Learning',
            Location__c = 'London - Waterloo',
            Start_Date__c = Date.today(),
            End_Date__c = Date.today().addDays(365),
            Eligible_For_Automated_Holiday_Letter__c = true
        );

        insert product;
    }

    @isTest
    private static void itShouldSendFromAProduct() {
        StreamingService.canFetchStreams = true;

        Programme__c programme = [SELECT Id FROM Programme__c WHERE Name = 'Test1Programme'];

        MockHttpClient mock = new MockHttpClient();
        mock.addResponse('@', 200);

        // Disable outbound events killswitch by default
        TestUtilities.mockKillswitch(killswitch.BLOCK_OUTBOUND_EVENTS, false);

        // GIVEN We insert a new product
        // WHEN the trigger runs
        System.Test.startTest();
        System.Test.setMock(HttpCalloutMock.class, mock);

        Product2 product = new Product2(
            Name = 'Test University Product',
            Programme__c = programme.Id,
            Instance_Id__c = 'test-321',
            Mode__c = 'Online',
            Location__c = 'London - Southgate',
            Start_Date__c = Date.today().addDays(10),
            End_Date__c = Date.today().addDays(375),
            Eligible_For_Automated_Holiday_Letter__c = true
        );

        insert product;

        System.Test.getEventBus().deliver();
        System.Test.stopTest();

        // THEN I expect a product sync event
        Assert.areEqual(1, mock.processedRequests);
    }

    @isTest
    private static void itShouldSendFromProgrammeUpdate() {
        StreamingService.canFetchStreams = true;

        Programme__c programme = new Programme__c(Name = 'Test1Programme', Programme_Id__c = 'test-123');
        insert programme;

        Product2 product = [SELECT Id FROM Product2 WHERE Name = 'TestCourse'];
        product.programme__c = programme.Id;

        update product;

        MockHttpClient mock = new MockHttpClient();
        mock.addResponse('@', 200);

        // Disable outbound events killswitch by default
        TestUtilities.mockKillswitch(killswitch.BLOCK_OUTBOUND_EVENTS, false);

        // GIVEN We insert a new programme
        // WHEN the trigger runs
        System.Test.startTest();
        System.Test.setMock(HttpCalloutMock.class, mock);

        //WHEN we update programme
        programme.Name = 'Updated Programme';
        update programme;

        System.Test.getEventBus().deliver();
        System.Test.stopTest();

        // THEN I expect a product sync event
        Assert.areEqual(1, mock.processedRequests);
    }

    @isTest
    private static void itShouldSendFromTermDateUpdate() {
        StreamingService.canFetchStreams = true;

        Product2 product = [SELECT Id FROM Product2 WHERE Name = 'TestCourse'];

        MockHttpClient mock = new MockHttpClient();
        mock.addResponse('@', 200);

        // Disable outbound events killswitch by default
        TestUtilities.mockKillswitch(killswitch.BLOCK_OUTBOUND_EVENTS, false);

        Term_Date__c termDate = new Term_Date__c(Start_Date__c = Date.today(), End_Date__c = Date.today().addDays(10));
        termDate.Product__c = product.Id;

        insert termDate;

        // GIVEN We insert a new TermDate
        // WHEN the trigger runs
        System.Test.startTest();
        System.Test.setMock(HttpCalloutMock.class, mock);

        //WHEN we update term date
        termDate.Start_Date__c = Date.today().addDays(1);

        update termDate;

        System.Test.getEventBus().deliver();
        System.Test.stopTest();

        // THEN I expect a product sync event
        Assert.areEqual(1, mock.processedRequests);
    }

    @isTest
    private static void itShouldSendFromAnInstance() {
        StreamingService.canFetchStreams = true;

        Product2 product = [SELECT Id FROM Product2 WHERE Name = 'TestCourse'];

        MockHttpClient mock = new MockHttpClient();
        mock.addResponse('@', 200);

        // Disable outbound events killswitch by default
        TestUtilities.mockKillswitch(killswitch.BLOCK_OUTBOUND_EVENTS, false);

        // GIVEN we insert a new instance
        // WHEN the trigger runs
        System.Test.startTest();
        System.Test.setMock(HttpCalloutMock.class, mock);

        Instance__c instance = new Instance__c(Product__c = product.Id, Instance_ID__c = 'test-123');

        insert instance;

        System.Test.getEventBus().deliver();
        System.Test.stopTest();

        // THEN I expect a product sync event
        Assert.areEqual(1, mock.processedRequests);
    }
}
