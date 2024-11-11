/**
 * BPPIntegrationConfig class handles integration configurations and provides methods to perform HTTP callouts.
 * This class is responsible for generating legacy HTTP requests based on the provided parameters and configuration settings.
 */
public without sharing class BPPIntegrationConfig {
    /**
     * Variables to determine sandbox info.
     */
    public static System.Domain domain = System.DomainParser.parse(URL.getOrgDomainUrl());
    public static String sandboxName = domain.getSandboxName();
    public static Boolean isSandbox = !String.isEmpty(domain.getSandboxName());

    /**
     * Map containing sandbox URLs based on the sandbox name.
     */
    public static final Map<String, String> SANDBOX_URL_MAP = new Map<String, String>{
        'dev' => 'https://dev-api.bppuniversity/servicegateway',
        'test' => 'https://test-api.bppuniversity/servicegateway',
        'demo' => 'https://stage-api.bppuniversity/servicegateway',
        null => 'https://api.bpp.com/servicegateway'
    };

    /**
     * Property that returns the endpoint URL based on the type of environment.
     */
    @TestVisible
    private static String endpoint {
        get {
            if (sandboxName != null && (sandboxName.contains('dev') || sandboxName.contains('cibuild'))) {
                return SANDBOX_URL_MAP.get('dev');
            }
            return SANDBOX_URL_MAP.get(sandboxName);
        }
    }

    /**
     * Property that returns callout properties including endpoint URL, certificate, and legacy configuration status.
     */
    @TestVisible
    private static CalloutProperties calloutProperties {
        get {
            CalloutProperties cp = new CalloutProperties();
            cp.certificate = isSandbox ? 'SANDBOX_CERT' : 'BPP_NOAH_PROD';
            cp.endpoint = isSandbox ? 'callout:ServiceGateway_Test' : 'callout:ServiceGateway';
            cp.legacyConfigEnabled = Killswitch.isEnabled(Killswitch.INTEGRATION_CONFIG_KILLSWITCH);
            return cp;
        }
    }

    /**
     * Generates an HTTP GET request with the provided request body.
     *
     * @param requestBody The request body for the GET request.
     * @return HttpRequest object representing the generated GET request.
     */
    public static HttpRequest getData(String requestBody) {
        return generateHttpRequest('GET', requestBody, null);
    }

    /**
     * Generates an HTTP POST request with the provided request body, content type, and extension.
     *
     * @param requestBody The request body for the POST request.
     * @param contentType The content type of the request body.
     * @param extension The extension to append to the endpoint URL.
     * @return HttpRequest object representing the generated POST request.
     */
    public static HttpRequest callRestService(String requestBody, String contentType, String extension) {
        return generateHttpRequest('POST', requestBody, extension);
    }

    /**
     * Generates an HTTP PUT request with the provided request body, content type, and extension.
     *
     * @param requestBody The request body for the PUT request.
     * @param contentType The content type of the request body.
     * @param extension The extension to append to the endpoint URL.
     * @return HttpRequest object representing the generated PUT request.
     */
    public static HttpRequest callUpdateRestService(String requestBody, String contentType, String extension) {
        return generateHttpRequest('PUT', requestBody, extension);
    }

    /**
     * Generates an HTTP DELETE request with the provided content type and extension.
     *
     * @param contentType The content type of the request body.
     * @param extension The extension to append to the endpoint URL.
     * @return HttpRequest object representing the generated DELETE request.
     */
    public static HttpRequest callDelRestService(String contentType, String extension) {
        return generateHttpRequest('DELETE', null, extension);
    }

    /**
     * Generates an HTTP request based on the provided method, request body, and extension.
     *
     * @param method The HTTP method (GET, POST, PUT, DELETE).
     * @param requestBody The request body (null for GET and DELETE requests).
     * @param extension The extension to append to the endpoint URL.
     * @return HttpRequest object representing the generated HTTP request.
     */
    public static HttpRequest generateHttpRequest(String method, String requestBody, String extension) {
        String url = calloutProperties.legacyConfigEnabled ? endpoint : calloutProperties.endpoint;
        String tenantId = calloutProperties.legacyConfigEnabled
            ? 'A801173AFBE1849BE040100A2D084350'
            : '{!$Credential.ServiceGateway.tenantId}';

        HttpRequest request = new HttpRequest();
        request.setMethod(method);
        request.setHeader('tenantId', tenantId);
        if (calloutProperties.legacyConfigEnabled) {
            request.setClientCertificateName(calloutProperties.certificate);
        }

        if (method == 'GET') {
            request.setEndpoint(url);
            request.setBody(requestBody);
            request.setHeader('Content-Type', 'text/xml; charset=utf-8');
        } else {
            if (method != 'DELETE') {
                request.setBody(requestBody);
            }
            request.setEndpoint(url + extension);
            request.setHeader('Accept-Encoding', 'gzip,deflate');
            request.setHeader('Accept', 'application/json');
            request.setHeader('Content-Type', 'application/json');
        }
        request.setTimeout(120000);
        return request;
    }

    /**
     * Inner class representing callout properties
     */
    private class CalloutProperties {
        public String endpoint;
        public String certificate;
        public Boolean legacyConfigEnabled;
    }
}
