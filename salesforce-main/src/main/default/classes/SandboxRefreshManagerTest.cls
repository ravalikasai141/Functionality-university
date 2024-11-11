@isTest
private class SandboxRefreshManagerTest {
    
    @isTest static void testMySandboxPrep() {
        Test.setMock(HttpCalloutMock.class, new ToolingAPIMock(testRemoteSiteSettingQueryResponse, 200));
        Test.startTest();
        Test.testSandboxPostCopyScript(
            new SandboxRefreshManager(),
            UserInfo.getOrganizationId(),
            UserInfo.getOrganizationId(),
            UserInfo.getOrganizationName()
        );
        Test.stopTest();
        System.assertNotEquals(0,[select count() from blng__TaxTreatment__c]); 
    }
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