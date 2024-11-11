public without sharing class EventApiClient {
    /**
     * The named credential associated with events api
     */
    @TestVisible
    private String endpoint {
        get {
            System.Domain domain = System.DomainParser.parse(URL.getOrgDomainUrl());

            if (!String.isEmpty(domain.getSandboxName())) {
                return 'callout:Events_API_Test';
            } else {
                return 'callout:Events_API';
            }
        }
    }

    /**
     * Sends the given events to the Events API
     * @param eventPayload JSON serialized list of events
     */
    public void send(String eventPayload) {
        Http http = new Http();
        HttpResponse response = http.send(createRequest(eventPayload));

        if (response.getStatusCode() >= 300) {
            throw new CalloutException('Unable to process outbound event, status: ' + response.getStatusCode());
        }
    }

    /**
     * Wraps an event in the payload expected by the Events API
     * @param created The datetime for event
     * @param name event name
     * @param event the payload for the event
     * @return  Event payload map
     */
    public static Map<String, Object> wrapEvent(DateTime created, String name, Map<String, Object> event) {
        return new Map<String, Object>{
            'time' => created,
            'source' => 'salesforce',
            'detailType' => name,
            'detail' => new Map<String, Object>{ 'data' => event }
        };
    }

    /**
     *
     * @param body serialized payload of events to send
     * @return  HttpRequest
     */
    private HttpRequest createRequest(String body) {
        HttpRequest request = new HttpRequest();
        request.setEndpoint(endpoint);
        request.setMethod('POST');
        request.setHeader('Content-Type', 'application/json');
        request.setHeader('x-api-key', '{!$Credential.Password}');
        request.setBody(body);

        return request;
    }
}
