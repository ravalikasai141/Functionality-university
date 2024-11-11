@isTest
private class LogTest {
    @TestSetup
    private static void setUp() {
        insert new Log_Setting__c(
            SetupOwnerId = UserInfo.getOrganizationId(),
            Debug__c = 'DebugTransport',
            Warn__c = null,
            Error__c = 'PlatformEventTransport'
        );
    }

    @isTest
    private static void itShouldBeAbleToSendLogs() {
        MockHttpClient mock = new MockHttpClient();
        mock.addResponse('@', 202);

        System.Test.startTest();
        System.Test.setMock(HttpCalloutMock.class, mock);
        // Given we have logs to send
        // When we send the logs
        Log.debug('Test debug');
        Log.error('Test error');
        Log.error('Test error 2');
        Log.send();
        Log.critical('Test critical');

        System.Test.getEventBus().deliver();
        System.Test.stopTest();

        // Then I expect it to send an API request
        Assert.areEqual(1, mock.processedRequests);
    }

    @isTest
    private static void itShouldNotSendLogsWhereNoTransportExists() {
        // Given we have logs to send
        // AND the log level has no transport
        // When we send the logs
        Log.warn('Test warning');
        Log.send();

        // Then I expect no logs to be sent
        Assert.areEqual(0, Log.logs.size());
    }

    @isTest
    private static void itShouldNotSendLogsWhenSeverityIsUnknown() {
        // Given we have logs to send
        // AND the log level is unknown
        // When we send the logs
        Log.create('INVALID', 'Test warning');
        Log.send();

        // Then I expect no logs to be sent
        Assert.areEqual(0, Log.logs.size());
    }
}
