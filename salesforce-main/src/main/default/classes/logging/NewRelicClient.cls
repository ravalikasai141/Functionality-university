/**
 * Used to send logs to New Relic via the v1 log endpoint
 */
public without sharing class NewRelicClient {
    /**
     * Ensures we are using the correct endpoint for sandboxes and production
     */
    private String endpoint {
        get {
            System.Domain domain = System.DomainParser.parse(URL.getOrgDomainUrl());

            if (!String.isEmpty(domain.getSandboxName())) {
                return 'callout:Log_API_Test';
            } else {
                return 'callout:Log_API';
            }
        }
    }

    /**
     * Sends the given list of logs to New Relic Log endpoint
     * @param logs List of logs to send
     * @exception CalloutException thrown when we recieve a non 200 response
     */
    public void send(List<Object> logs) {
        Http http = new Http();
        HttpResponse response = http.send(createRequest(logs));

        if (response.getStatusCode() >= 300) {
            throw new CalloutException('Unable to process log, status: ' + response.getStatusCode());
        }
    }

    /**
     * Creates the request needed to send bulk logs to New Relic
     * @param logs List of logs to serialize
     * @return  Request for New Relic
     */
    private HttpRequest createRequest(List<Object> logs) {
        HttpRequest request = new HttpRequest();
        request.setEndpoint(endpoint);
        request.setMethod('POST');
        request.setHeader('Content-Type', 'application/json');
        request.setHeader('Api-Key', '{!$Credential.Password}');

        Map<String, Object> data = new Map<String, Object>{
            'common' => new Map<String, Object>{
                'attributes' => new Map<String, String>{
                    'logtype' => 'accesslogs',
                    'service' => 'salesforce',
                    'hostname' => URL.getSalesforceBaseUrl().getHost()
                }
            },
            'logs' => logs
        };

        request.setBody(JSON.serialize(new List<Object>{ data }));
        return request;
    }
}
