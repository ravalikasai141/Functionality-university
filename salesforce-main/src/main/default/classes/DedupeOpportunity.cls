@RestResource(urlMapping='/v1.0/DedupeOpportunity/*')
global with sharing class DedupeOpportunity {
    global class Response {
        public Response() {}
        public String opportunityId { get; set; }
        
        public Response(String opportunityId) {
            this.opportunityId = opportunityId;
        }
    }

    global class CheckOpportunity {
        public String accountId;
        public String courseInstance;
        public String recordSource;
    }

    @HttpPost
    global static Response doPost(CheckOpportunity opportunity) {
        try {
            String accountId, recordTypeId, courseInstance, recordSource;
            accountId = DedupeHelper.verifyPostInput(opportunity.accountId);
            courseInstance = DedupeHelper.verifyPostInput(opportunity.courseInstance);
            recordSource = DedupeHelper.verifyPostInput(opportunity.recordSource);
            
            Opportunity matchedOpportunity = opportunityCheck(accountId, courseInstance, recordSource);
            if (matchedOpportunity != NULL) {
                return new Response(String.valueOf(matchedOpportunity.Id));
            } else {
                return new Response('null');
            }
        } catch (Exception e) { 
            return new Response('DedupeOpportunity Error: [' + e.getLineNumber() + '] ' + e.getMessage());
        }
    }

    public static Opportunity opportunityCheck(String accountId, String courseInstance, String recordSource) {
        Opportunity oppFound;

        List<Opportunity> opportunityList = [
            SELECT Id FROM Opportunity 
            WHERE AccountId =: accountId AND Course_Instance__c =: courseInstance AND Record_Source__c =: recordSource AND RecordType.Name IN('Application', 'Locked Application')
            ORDER BY CreatedDate DESC
        ];
        
        if (opportunityList.size() > 0 ? true : false) {
            oppFound = opportunityList.get(0);
            System.debug('@DedupeOpportunity opportunityCheck - match found');
        }
        return oppFound;
    }
}