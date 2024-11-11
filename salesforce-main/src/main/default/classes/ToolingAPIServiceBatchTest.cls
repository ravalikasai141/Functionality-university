@isTest
private class ToolingAPIServiceBatchTest {
    
    @isTest
    private static void deactivateRemoteSiteSettingTest() {
        Test.setMock(HttpCalloutMock.class, new ToolingAPIMock(testRemoteSiteSettingQueryResponse, 200));
        Test.startTest();
        Id batchId = Database.executeBatch(new ToolingAPIServiceBatch(), 1);
        Test.stopTest();
        System.assertNotEquals(null,batchId); 
    }
    
    @isTest
    private static void deactivateRemoteSiteSettingErrorTest() {
        Test.setMock(HttpCalloutMock.class, new ToolingAPIMock(testRemoteSiteSettingQueryErrorResponse, 200));
        Test.startTest();
        Id batchId = Database.executeBatch(new ToolingAPIServiceBatch(), 1);
        Test.stopTest();
        System.assertNotEquals(null,batchId); 
    }

    
    private static String testRemoteSiteSettingQueryResponse = '[{'
        + '"success" : true'
        + '}]';
    
    private static String testRemoteSiteSettingQueryErrorResponse = '[{'
        + '"success" : false'
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