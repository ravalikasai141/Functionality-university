@isTest
global class AWSCalloutMock implements HttpCalloutMock{
    global HttpResponse respond (HTTPRequest req) {
        HttpResponse response = new HttpResponse();
        response.setHeader('Content-Type', 'application/json');
        response.setStatusCode(200);
        response.setBody('{"status":"OK"}');
        return response;
    }
}