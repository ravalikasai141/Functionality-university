@isTest
private class ApplicationCancelledTest {
    @TestSetup
    private static void setup() {
        Account account = new Account(
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName()
                .get('Student Account')
                .getRecordTypeId(),
            FirstName = 'Test',
            LastName = 'Tester',
            Salutation = 'Mr',
            Personal_Email__pc = 'test@bpp.com',
            Preferred_Email__pc = 'test@bpp.com'
        );
        insert account;

        insert new Opportunity(
            RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName()
                .get('Apprentice Application')
                .getRecordTypeId(),
            AccountId = account.Id,
            Name = 'Test Opportunity',
            Application_Id__c = 'test-1234',
            StageName = 'Application',
            CloseDate = Date.today() + 30
        );
    }

    @isTest
    private static void itShouldSubmitCancelEventOnCancellation() {
        // GIVEN we have an opp at Acceptance stage
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Application_Id__c = 'test-1234'];

        opp.Bypass_Validation_Rule__c = true;
        opp.StageName = 'Closed Lost';
        opp.BPP_Sub_Status__c = 'Rejected';
        opp.BPP_Cancellation_Reason__c = 'appRejectFundingIssue';
        update opp;

        // WHEN this is sent to the serializer
        Serializer serializer = new ApplicationCancelled();
        serializer.addRecord(opp);

        List<Map<String, Object>> payloads = serializer.serialize();

        // THEN I expect it to
        Assert.areEqual('appRejectFundingIssue', payloads[0].get('cancellationReason'));
        Assert.isNotNull((DateTime) payloads[0].get('cancelledOn'));
    }
    @isTest
    private static void itShouldSubmitCancelEventOnCancellationWithAppInvalid() {
        // GIVEN we have an opp at Application stage
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Application_Id__c = 'test-1234'];

        opp.Bypass_Validation_Rule__c = true;
        opp.StageName = 'Closed Lost';
        opp.BPP_Sub_Status__c = 'Cancelled';
        opp.BPP_Cancellation_Reason__c = 'appInvalid';
        update opp;

        // WHEN this is sent to the serializer
        Serializer serializer = new ApplicationCancelled();
        serializer.addRecord(opp);

        List<Map<String, Object>> payloads = serializer.serialize();

        // THEN I expect it to
        Assert.areEqual('appInvalid', payloads[0].get('cancellationReason'));
        Assert.isNotNull((DateTime) payloads[0].get('cancelledOn'));
    }
}
