@isTest
private class ApplicationRecallTest {
    @TestSetup
    private static void setUp() {
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

        Opportunity opp = new Opportunity(
            RecordTypeId = oppRecordTypeId,
            AccountId = account.Id,
            Name = 'Test Opportunity',
            Application_Id__c = 'test-1234',
            StageName = 'Application',
            BPP_Sub_Status__c = 'In Progress',
            CloseDate = Date.today() + 30
        );

        insert opp;

        opp.StageName = 'BPP Review';
        update opp;
    }

    @isTest
    private static void itShouldBeAbleToSerializeAnOpportunity() {
        // GIVEN we have an Opportunity that has been recalled
        Opportunity opp = [
            SELECT Application_Id__c, StageName, BPP_Sub_Status__c
            FROM Opportunity
            WHERE Application_Id__c = 'test-1234'
        ];
        // WHEN This is passed to the serializer
        ApplicationRecall serializer = new ApplicationRecall();
        serializer.addRecord(opp);

        List<Map<String, Object>> payloads = serializer.serialize();
        Map<String, Object> payload = payloads.get(0);

        // THEN i expect the correct payload to be produced
        Assert.areEqual('BPP_REVIEW', payload.get('currentStage'));
        Assert.areEqual('IN_PROGRESS', payload.get('currentStageStatus'));
    }
}
