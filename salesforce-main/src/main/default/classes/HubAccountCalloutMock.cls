@isTest
global class HubAccountCalloutMock implements HttpCalloutMock{
    global HttpResponse respond (HTTPRequest req) {
        HttpResponse response = new HttpResponse();
        response.setHeader('Content-Type', 'application/json');
        response.setStatusCode(200);
        response.setBody('{"email": "test2@bpp.com","email_verified":"false","success": true}');
        return response;
    }
}