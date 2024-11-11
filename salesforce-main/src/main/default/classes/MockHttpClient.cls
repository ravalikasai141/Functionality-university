/**
 * A mock http handler that allows the use of ordered responses for
 * multiple calls.
 */
@isTest
global class MockHttpClient implements HttpCalloutMock {

    /**
     * A map of responses keyed by the order in which they
     * should be returned.
     */
    private Map<String, HttpResponse> responseMap;

    /**
     * Keeps track of how many requests have been processed
     * and which response to return
     */
    @TestVisible
    private Integer processedRequests;

    /**
     * List of requests sent
     */
    @TestVisible
    private List<HttpRequest> requests;

    public MockHttpClient() {
        responseMap = new Map<String, HttpResponse> ();
        requests = new List<HttpRequest> ();
        processedRequests = 0;
    }

    /**
     * Adds a response to the response map to be returned
     * on the given order
     * @param key Either numerical order or '@'
     * @param response The HttpResponse to return in this order
     */
    public void addResponse(String key, HttpResponse response) {
        responseMap.put(key, response);
    }

    /**
     * Adds a response to the response map to be returned
     * on the given order
     * @param key Either numerical order or '@'
     * @param statusCode The Http Status code to return
     */
    public void addResponse(String key, Integer statusCode) {
        HttpResponse response = new HttpResponse();
        response.setStatusCode(statusCode);
        addResponse(key, response);
    }

    /**
     * Adds a response to the response map to be returned
     * on the given order
     * @param key Either numerical order or '@'
     * @param statusCode The Http Status code to return
     * @param body The response body
     */
    public void addResponse(String key, Integer statusCode, String body) {
        HttpResponse response = new HttpResponse();
        response.setStatusCode(statusCode);
        response.setBody(body);
        addResponse(key, response);
    }

    /**
     * Responds to a Http Request
     * @param request HttpRequest object send to client
     * @return  The response for the given request
     */
    global HttpResponse respond(HttpRequest request) {
        processedRequests++;
        requests.add(request);
        return getResponse();
    }

    /**
     * Determines the HttpResponse to return for this
     * request
     * @return  The specific response for this request
     */
    private HttpResponse getResponse() {
        String responseKey = String.valueOf(processedRequests);

        // If there is a specific response for this request
        if (responseMap.containsKey(responseKey)) {
            return responseMap.get(responseKey);
        }

        // If there is a catch all response set
        if (responseMap.containsKey('@')) {
            return responseMap.get('@');
        }

        // Otherwise we return a 200
        HttpResponse response = new HttpResponse();
        response.setStatusCode(200);
        return response;
    }
}