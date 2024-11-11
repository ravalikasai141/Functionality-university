@isTest
private class EventQueueableTest {

    @isTest
    private static void itShouldRetryWhenFailed() {
        // GIVEN we have an event to send
        // AND the Events API rejects the events
        MockHttpClient mock = new MockHttpClient();
        mock.addResponse('@', 400);

        // WHEN the events are being processed
        System.Test.startTest();
        System.Test.setMock(HttpCalloutMock.class, mock);

            EventQueueable queue = new EventQueueable('[{}]');
            queue.execute(null);

        System.Test.stopTest();

        // THEN I expect it to retry up to 3 times
        Assert.areEqual(1, queue.retries);
    }

    @isTest
    private static void itShouldThrowExceptionAtMaximumRetries() {
        // GIVEN an event has already retried 3 times
        MockHttpClient mock = new MockHttpClient();
        mock.addResponse('@', 400);

        Boolean exceptionThrown = false;

        // WHEN the event is processed and fails
        System.Test.startTest();
        System.Test.setMock(HttpCalloutMock.class, mock);

            EventQueueable queue = new EventQueueable('[{}]');
            queue.retries = 3;

            try {
                queue.execute(null);
            } catch (CalloutException e) {
                exceptionThrown = true;
            }

        System.Test.stopTest();

        // THEN I expect an exception to be thrown
        Assert.isTrue(exceptionThrown);
    }
}