@isTest
private class PlatformEventEmitterTest {
    @isTest
    private static void itShouldSendPlatformEventsToEventsAPI() {
        // GIVEN we have an event to send
        List<Map<String, Object>> payloads = new List<Map<String, Object>>{
            new Map<String, Object>{ 'test' => 'event' }
        };

        // WHEN this is emitted via the PlatformEventEmitter
        PlatformEventEmitter emitter = new PlatformEventEmitter();
        MockHttpClient mock = new MockHttpClient();
        mock.addResponse('@', 200);

        System.Test.startTest();
        System.Test.setMock(HttpCalloutMock.class, mock);

        emitter.send('testevent', payloads);

        System.Test.getEventBus().deliver();
        System.Test.stopTest();

        // THEN I expect it to send the event to the events API
        Assert.isTrue(emitter.results[0].isSuccess());
        Assert.areEqual(1, mock.processedRequests);
    }
}
