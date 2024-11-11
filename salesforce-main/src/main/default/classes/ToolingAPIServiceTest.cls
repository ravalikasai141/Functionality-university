@isTest
private class ToolingAPIServiceTest {
    
    @isTest
    private static void itShouldGetAllRemoteSiteSetting() {
        Test.setMock(HttpCalloutMock.class, new ToolingAPIMock(testRemoteSiteSettingGetQueryResponse, 200));
        Test.startTest();
        List<ToolingAPIService.RemoteSiteSetting> result = ToolingAPIService.getRemoteSiteSettings('', '');
        Test.stopTest();
        System.assertNotEquals(null,result); 
    }
    
    @isTest
    private static void itShouldDeactivateRemoteSiteSetting() {
        Test.setMock(HttpCalloutMock.class, new ToolingAPIMock(testRemoteSiteSettingQueryResponse, 200));
        Test.startTest();
        Boolean result = ToolingAPIService.createUpdateRemoteSiteSetting('0rp0X0000006CucQAE', 'Cloud_8_ContactWorld', 'Description 1', 'http://www.EndpointUrl.com', '', '');
        Test.stopTest();
        System.assertEquals(true,result); 
    }
    
    private static String testRemoteSiteSettingGetQueryResponse = '{'
        + '"records": [{'
        + '"Id": "0rp0X0000006CucQAE",'
        + '"EndpointUrl": "http://www.EndpointUrl.com",'
        + '"Description": "Description 1",'
        + '"IsActive": true,'
        + '"SiteName": "Cloud_8_ContactWorld"'
        + '}]'
        + '}';
    
    private static String testRemoteSiteSettingQueryResponse = '[{'
        + '"success" : true'
        + '}]';
    
    public class ToolingAPIMock implements HttpCalloutMock {
        private String testResponse;
        private Integer testStatusCode;
        
        public ToolingAPIMock(String testResponse, Integer testStatusCode){
            this.testResponse = testResponse;
            this.testStatusCode = testStatusCode;
        }
        
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setBody(testResponse);
            res.setStatusCode(testStatusCode);
            return res;
        }
    }
    
}