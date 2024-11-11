@isTest
private class RecallApplicationControllerTest {
    @TestSetup
    private static void setup() {
        Id accRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName()
            .get('Student Account')
            .getRecordTypeId();
        Id oppRecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName()
            .get('Apprentice Application')
            .getRecordTypeId();

        Account account = new Account(
            RecordTypeId = accRecordTypeId,
            FirstName = 'Test',
            LastName = 'Tester',
            Salutation = 'Mr',
            Personal_Email__pc = 'test@bpp.com',
            Preferred_Email__pc = 'test@bpp.com'
        );

        insert account;

        Contact contact = new Contact(FirstName = 'Test', LastName = 'Tester', Email = 'test@bpp.com');

        insert contact;

        List<Opportunity> opps = new List<Opportunity>{
            new Opportunity(
                RecordTypeId = oppRecordTypeId,
                AccountId = account.Id,
                Name = 'Test Opportunity',
                Application_Id__c = 'test-1234',
                StageName = 'Application',
                BPP_Sub_Status__c = 'In Progress',
                CloseDate = Date.today() + 30
            ),
            new Opportunity(
                RecordTypeId = oppRecordTypeId,
                AccountId = account.Id,
                Name = 'Test Opportunity',
                Application_Id__c = 'test-1235',
                StageName = 'Application',
                Line_Manager__c = contact.Id,
                BPP_Sub_Status__c = 'In Progress',
                CloseDate = Date.today() + 30
            ),
            new Opportunity(
                RecordTypeId = oppRecordTypeId,
                AccountId = account.Id,
                Name = 'Test Opportunity',
                Application_Id__c = 'test-1236',
                StageName = 'Application',
                Line_Manager__c = contact.Id,
                BPP_Sub_Status__c = 'In Progress',
                CloseDate = Date.today() + 30
            )
        };

        insert opps;

        opps[0].StageName = 'BPP Review';
        opps[0].BPP_Sub_Status__c = 'Awaiting Information';
        opps[1].StageName = 'Line Manager Review';
        opps[2].StageName = 'Acceptance';
        opps[2].BPP_Sub_Status__c = 'Completed';

        update opps;
    }

    @isTest
    private static void itShouldBeAbleToShowAPreviewOfChanges() {
        // GIVEN we have various opportunities
        Opportunity bppReviewOpp = [SELECT Id FROM Opportunity WHERE Application_Id__c = 'test-1234'];
        Opportunity lineManagerOpp = [SELECT Id FROM Opportunity WHERE Application_Id__c = 'test-1235'];
        Opportunity acceptanceOpp = [SELECT Id FROM Opportunity WHERE Application_Id__c = 'test-1236'];

        // WHEN we request a preview of changes
        Opportunity bppOut = RecallApplicationController.getPreview(bppReviewOpp.Id);
        Opportunity lmOut = RecallApplicationController.getPreview(lineManagerOpp.Id);
        Opportunity acceptOut = RecallApplicationController.getPreview(acceptanceOpp.Id);

        // THEN i expect it to return correct updated opportunities
        Assert.areEqual('BPP Review', bppOut.StageName);
        Assert.areEqual('In Progress', bppOut.BPP_Sub_Status__c);

        Assert.areEqual('BPP Review', lmOut.StageName);
        Assert.areEqual('In Progress', lmOut.BPP_Sub_Status__c);

        Assert.areEqual('Acceptance', acceptOut.StageName);
        Assert.areEqual('In Progress', acceptOut.BPP_Sub_Status__c);
    }

    @isTest
    private static void itShouldUpdateOpportunityStatus() {
        MockHttpClient mock = new MockHttpClient();
        mock.addResponse('@', 200);

        // GIVEN we have an opportunity that we want to recall
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Application_Id__c = 'test-1234'];
        // WHEN we pass this to the controller
        System.Test.startTest();
        System.Test.setMock(HttpCalloutMock.class, mock);

        RecallApplicationController.recallOpportunity(opp.Id);

        System.Test.getEventBus().deliver();
        System.Test.stopTest();

        // THEN I expect it to update the opp
        Opportunity out = [SELECT StageName, BPP_Sub_Status__c FROM Opportunity WHERE Id = :opp.Id];

        Assert.areEqual('BPP Review', out.StageName);
        Assert.areEqual('In Progress', out.BPP_Sub_Status__c);

        // AND I expect it to emit an event
        Assert.areEqual(1, mock.processedRequests);
    }
}
