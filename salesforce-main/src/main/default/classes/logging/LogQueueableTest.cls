@isTest
private class LogQueueableTest {
    @isTest
    private static void itShouldRetryWhenFailed() {
        // GIVEN the NewRelic API rejects the events
        MockHttpClient mock = new MockHttpClient();
        mock.addResponse('@', 400);

        // WHEN the logs are being processed
        System.Test.startTest();
        System.Test.setMock(HttpCalloutMock.class, mock);

        LogQueueable queue = new LogQueueable(new List<Object>());
        queue.execute(null);

        System.Test.stopTest();

        // THEN I expect it to increase the retries
        Assert.areEqual(1, queue.retries);
    }

    @isTest
    private static void itShouldThrowExceptionAtMaximumRetries() {
        // GIVEN a set of logs has already retried 3 times
        MockHttpClient mock = new MockHttpClient();
        mock.addResponse('@', 400);

        Boolean exceptionThrown = false;

        // WHEN the log is processed and fails
        System.Test.startTest();
        System.Test.setMock(HttpCalloutMock.class, mock);

        LogQueueable queue = new LogQueueable(new List<Object>());
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
