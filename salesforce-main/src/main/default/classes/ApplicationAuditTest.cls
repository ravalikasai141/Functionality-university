@isTest
public class ApplicationAuditTest {
    @TestSetup
    static void setup() {
        Id accountRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
            .get('Student_Account')
            .getRecordTypeId();

        Id opportunityRecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName()
            .get('Apprentice_Application')
            .getRecordTypeId();

        Account acc = new Account(FirstName = 'Test', LastName = 'Test', RecordTypeId = accountRecordTypeId);
        insert acc;

        Opportunity opp = new Opportunity(
            AccountId = acc.Id,
            Name = 'TestOpportunity',
            Application_Id__c = 'test-application',
            StageName = 'Application',
            CloseDate = Date.today() + 30,
            RecordTypeId = opportunityRecordTypeId,
            Application_Reference__c = 'APP20000'
        );

        insert opp;

        ApplicationAudit.createAudits(new Set<String>{ 'test-application' }, DateTime.now());
    }

    @isTest
    private static void itShouldReturnHistory() {
        // Given we have an opportunity with history and audits
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Application_Id__c = 'test-application'];

        // When we call the fetchAudit method
        ApplicationAudit audit = new ApplicationAudit();
        List<Object> history = audit.fetchAudit(opp.Id);

        // Then I expect it to return the history
        Assert.isFalse(history.isEmpty());
    }
}
