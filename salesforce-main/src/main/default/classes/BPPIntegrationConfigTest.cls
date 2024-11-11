@isTest
public class BPPIntegrationConfigTest {
    /**
     * Common variables used in multiple methods.
     */
    public static final String GET_REQUEST_BODY =
        '<soapenv:Body><tns:createUpdateARCompanyAccountRequest>' +
        '<tns:profileCompanyId>TEST</tns:profileCompanyId><tns:legalEntity>XX</tns:legalEntity>' +
        '</tns:createUpdateARCompanyAccountRequest></soapenv:Body>';

    public static final String GET_RESPONSE_BODY =
        '<?xml version="1.0" encoding="utf-8"?>' +
        '<SOAP-ENV:Envelope xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/">' +
        '<SOAP-ENV:Body></SOAP-ENV:Body></SOAP-ENV:Envelope>';

    public static final Map<String, Object> OBJECT_MAP = new Map<String, Object>{
        'FirstName' => TestDataFactory.generateUniqueString(),
        'LastName' => TestDataFactory.generateUniqueString()
    };

    public static final String POST_REQUEST_BODY = JSON.serialize(OBJECT_MAP);
    public static final String POST_EXTENSION = '/rest/profile/v2/findProfiles';
    public static final String POST_RESPONSE_BODY = '{"companyId":"0000x000-xx00-00x0-000x","operation":"UPDATE"}';
    public static final String DELETE_RESPONSE_BODY = '{"delete":{"isSuccessful":true}}';
    public static final String CONTENT_TYPE = 'application/json';
    public static final String ASSERT_SUCCESS_RESPONSE_CODE = 'Response status code should be 200.';
    public static final String ASSERT_SUCCESS_RESPONSE_BODY = 'Response body should match expected body.';

    /**
     * Sets up common mock HTTP response for the test methods.
     *
     * @param killswitchValue Boolean value indicating whether the killswitch is enabled.
     * @param responseBody The response body to be used in the mock HTTP response.
     */
    private static void commonSetup(Boolean killswitchValue, String responseBody) {
        TestUtilities.mockKillswitch(Killswitch.INTEGRATION_CONFIG_KILLSWITCH, killswitchValue);
        MockHttpClient mock = new MockHttpClient();
        mock.addResponse('@', 200, responseBody);
        System.Test.setMock(HttpCalloutMock.class, mock);
    }

    /**
     * Performs an HTTP callout and returns the response.
     *
     * @param request The HTTP request to be sent.
     * @return HttpResponse object representing the HTTP response.
     */
    private static HttpResponse performCallout(HttpRequest request) {
        Test.startTest();
        Http http = new Http();
        HttpResponse response = http.send(request);
        Test.stopTest();
        return response;
    }

    /**
     * Tests the scenario where a GET callout is performed with the killswitch off.
     */
    @isTest
    static void itShouldPerformGetCalloutWithKillswitchOff() {
        commonSetup(false, GET_RESPONSE_BODY);
        HttpRequest request = BPPIntegrationConfig.getData(GET_REQUEST_BODY);
        HttpResponse response = performCallout(request);

        Assert.areEqual(200, response.getStatusCode(), ASSERT_SUCCESS_RESPONSE_CODE);
        Assert.areEqual(GET_RESPONSE_BODY, response.getBody(), ASSERT_SUCCESS_RESPONSE_BODY);
    }

    /**
     * Tests the scenario where a GET callout is performed with the killswitch on.
     */
    @isTest
    static void itShouldPerformGetCalloutWithKillswitchOn() {
        commonSetup(true, GET_RESPONSE_BODY);
        HttpRequest request = BPPIntegrationConfig.getData(GET_REQUEST_BODY);
        HttpResponse response = performCallout(request);

        Assert.areEqual(200, response.getStatusCode(), ASSERT_SUCCESS_RESPONSE_CODE);
        Assert.areEqual(GET_RESPONSE_BODY, response.getBody(), ASSERT_SUCCESS_RESPONSE_BODY);
    }

    /**
     * Tests the scenario where a POST callout is performed with the killswitch off.
     */
    @isTest
    static void itShouldPerformPOSTCalloutWithKillswitchOff() {
        commonSetup(false, POST_RESPONSE_BODY);
        HttpRequest request = BPPIntegrationConfig.callRestService(POST_REQUEST_BODY, CONTENT_TYPE, POST_EXTENSION);
        HttpResponse response = performCallout(request);

        Assert.areEqual(200, response.getStatusCode(), ASSERT_SUCCESS_RESPONSE_CODE);
        Assert.areEqual(POST_RESPONSE_BODY, response.getBody(), ASSERT_SUCCESS_RESPONSE_BODY);
    }

    /**
     * Tests the scenario where a PUT callout is performed with the killswitch off.
     */
    @isTest
    static void itShouldPerformPUTCalloutWithKillswitchOff() {
        commonSetup(false, POST_RESPONSE_BODY);
        HttpRequest request = BPPIntegrationConfig.callUpdateRestService(
            POST_REQUEST_BODY,
            CONTENT_TYPE,
            POST_EXTENSION
        );
        HttpResponse response = performCallout(request);

        Assert.areEqual(200, response.getStatusCode(), ASSERT_SUCCESS_RESPONSE_CODE);
        Assert.areEqual(POST_RESPONSE_BODY, response.getBody(), ASSERT_SUCCESS_RESPONSE_BODY);
    }

    /**
     * Tests the scenario where a DELETE callout is performed with the killswitch off.
     */
    @isTest
    static void itShouldPerformDELETECalloutWithKillswitchOff() {
        commonSetup(false, DELETE_RESPONSE_BODY);
        HttpRequest request = BPPIntegrationConfig.callDelRestService(CONTENT_TYPE, POST_EXTENSION);
        HttpResponse response = performCallout(request);

        Assert.areEqual(200, response.getStatusCode(), ASSERT_SUCCESS_RESPONSE_CODE);
        Assert.areEqual(DELETE_RESPONSE_BODY, response.getBody(), ASSERT_SUCCESS_RESPONSE_BODY);
    }
}
