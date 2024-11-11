@isTest
private class BulkEventBatchTest {
    @TestSetup
    private static void setup() {
        Programme__c programme = new Programme__c(Name = 'Test1Programme', Programme_Id__c = 'test-123');

        insert programme;

        Product2 product = new Product2(
            Name = 'TestCourse',
            BPP_ProductFactoryID__c = 'test-123',
            Qualification__c = 'Test Qualification',
            Programme__c = programme.Id
        );

        insert product;
    }

    @isTest
    private static void itShouldBeAbleToSendEvents() {
        // Given we have an event to send
        String eventName = 'productTermsUpdated';
        String query = 'SELECT Id FROM Product2';
        ProductSync serializer = new ProductSync();

        MockHttpClient mock = new MockHttpClient();
        mock.addResponse('@', 200);

        // When we run the batch class
        System.Test.startTest();
        System.Test.setMock(HttpCalloutMock.class, mock);

        Database.executeBatch(new BulkEventBatch(query, eventName, serializer));

        System.Test.stopTest();

        // Then I expect it to send the events to the REST service
        Assert.areEqual(1, mock.processedRequests);
    }
}
