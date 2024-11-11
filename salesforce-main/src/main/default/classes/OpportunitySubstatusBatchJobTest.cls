@isTest
public class OpportunitySubstatusBatchJobTest {
    private static String TEST_APPLICATION_ID1 = 'cd6a04b6-9990-4e30-8421-5ed7819c13c9';
    private static String TEST_APPLICATION_ID2 = 'cd6a04b3-9990-4e37-8530-5ed4581c13c8';
    private static String TEST_APPLICATION_ID3 = 'cd6a04b6-9990-4e30-8421-5ed7819c13c8';
    private static Id accountRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
        .get('Student_Account')
        .getRecordTypeId();

    private static Id opportunityRecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName()
        .get('Student_Interest')
        .getRecordTypeId();

    @testSetup
    static void setUp() {
        insert new Account(FirstName = 'Test', LastName = 'Test', RecordTypeId = accountRecordTypeId);
        Account acc = [SELECT Id, PersonContactId FROM Account WHERE LastName = 'Test'];
        
        List<Opportunity> allOpps = new List<Opportunity>();
        allOpps.add(
            createOpportunity('Application Started', 'Recent Activity', acc, TEST_APPLICATION_ID1)
        );
        allOpps.add(createOpportunity('Application Started', 'Going Stale', acc, TEST_APPLICATION_ID2));
        Opportunity opp3 = createOpportunity(
            'Application Started',
            'Recent Activity',
            acc,
            TEST_APPLICATION_ID3
        );
        opp3.LastModifiedDate = DateTime.now();
        opp3.CreatedDate = DateTime.now();
        allOpps.add(opp3);
        insert allOpps;
    }

    private static Opportunity createOpportunity(
        String stageName,
        String substatus,
        Account acc,
        String applicationId
    ) {
        return new Opportunity(
            Name = 'Test Opportunity',
            Application_Id__c = applicationId,
            AccountId = acc.Id,
            StageName = stageName,
            BPP_Sub_Status__c = substatus,
            RecordTypeId = opportunityRecordTypeId,
            CloseDate = Date.today(),
            LastModifiedDate = DateTime.now().addDays(-5),
            CreatedDate = DateTime.now().addDays(-7)
        );
    }

    @isTest
    static void itShouldProcessBatchJobs() {
        // GIVEN some Jobs
        Map<Id, Opportunity> jobsToTest = new Map<Id, Opportunity>(
            [
                SELECT Id, BPP_Sub_Status__c
                FROM Opportunity
                WHERE
                    StageName IN ('Application Started', 'Application in Progress')
                    AND BPP_Sub_Status__c IN ('Going Stale', 'Stale')
            ]
        );
        // AND batch instance with those jobs
        OpportunitySubstatusBatchJob jobBatchInstance = new OpportunitySubstatusBatchJob();
        jobBatchInstance.ageThresholds.put('Recent Activity', -1);
        jobBatchInstance.ageThresholds.put('Going Stale', -1);

        System.Test.startTest();
        // WHEN the batch is executed
        Database.executeBatch(jobBatchInstance, 50);

        System.Test.stopTest();

        // THEN the Opportunity BPP_Sub_Status__c should have been updated to "Going Stale"
        for (Opportunity currentOpportunity : [
            SELECT BPP_Sub_Status__c
            FROM Opportunity
            WHERE Id IN :jobsToTest.keySet()
        ]) {
            Assert.areNotEqual(
                jobsToTest.get(currentOpportunity.Id).BPP_Sub_Status__c,
                currentOpportunity.BPP_Sub_Status__c
            );
        }
    }
    
    @isTest
    static void itShouldScheduleBatchJob() {
        // GIVEN some Jobs
        OpportunitySubstatusBatchJob jobBatchInstance = new OpportunitySubstatusBatchJob();
        
        System.Test.startTest();
        // WHEN the batch is executed
        DateTime sched = DateTime.now().addMinutes(1);
        String nextScheduleTime = String.valueOf(sched.second()) + ' ' + String.valueOf(sched.minute()) + ' * * * ?';
        String scheduleName = 'OpportunitySubstatusBatchJobTest';
        try {
            System.schedule(scheduleName, nextScheduleTime, jobBatchInstance);
        } catch (System.AsyncException e) {
            // schedule already exists, not an issue
        }
        System.Test.stopTest();

        // THEN the Job should successfully schedule
        Assert.areEqual(1, [SELECT COUNT() FROM CronTrigger WHERE CronJobDetail.Name = :scheduleName]);
    }
}