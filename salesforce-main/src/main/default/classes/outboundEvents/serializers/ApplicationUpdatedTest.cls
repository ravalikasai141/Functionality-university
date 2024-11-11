@isTest
private class ApplicationUpdatedTest {
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

        List<Opportunity> opps = new List<Opportunity>{
            new Opportunity(
                RecordTypeId = oppRecordTypeId,
                AccountId = account.Id,
                Name = 'Test Opportunity',
                Application_Id__c = 'test-1234',
                StageName = 'Application',
                CloseDate = Date.today() + 30
            ),
            new Opportunity(
                RecordTypeId = oppRecordTypeId,
                AccountId = account.Id,
                Name = 'Test Opportunity',
                Application_Id__c = 'test-1235',
                StageName = 'Application',
                CloseDate = Date.today() + 30
            )
        };

        insert opps;

        opps[0].Bypass_Validation_Rule__c = true;
        opps[0].StageName = 'BPP Review';
        opps[1].Bypass_Validation_Rule__c = true;
        opps[1].StageName = 'Acceptance';

        update opps;
    }

    @isTest
    private static void itShouldBeAbleToSerializeFromOpportunity() {
        // GIVEN we have an opportunity
        Opportunity opp = [SELECT Id, Application_Id__c FROM Opportunity WHERE Application_Id__c = 'test-1234'];
        // WHEN it is passed to the serializer
        Serializer serializer = new ApplicationUpdated();
        serializer.addRecord(opp);
        // THEN I expect it to output the correct payload
        List<Map<String, Object>> payload = serializer.serialize();

        Map<String, Object> data = payload.get(0);
        Assert.areEqual(opp.Application_Id__c, data.get('applicationId'));
    }

    @isTest
    private static void itShouldBeAbleToSerializeFromAcceptance() {
        // GIVEN we have an opportunity
        Opportunity opp = [SELECT Id, Application_Id__c FROM Opportunity WHERE Application_Id__c = 'test-1235'];
        // WHEN it is passed to the serializer
        Serializer serializer = new ApplicationUpdated();
        serializer.addRecord(opp);
        // THEN I expect it to output the correct payload
        List<Map<String, Object>> payload = serializer.serialize();

        Map<String, Object> data = payload.get(0);
        Assert.areEqual(opp.Application_Id__c, data.get('applicationId'));
    }
}
