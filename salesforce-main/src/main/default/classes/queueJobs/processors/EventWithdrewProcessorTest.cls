@isTest
public class EventWithdrewProcessorTest {
    private static Id accountRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
        .get('Student_Account')
        .getRecordTypeId();

    private static Id apprenticeRecordType = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName()
        .get('Apprentice_Application')
        .getRecordTypeId();

    private static Id applicationRecordType = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName()
        .get('Student_Application')
        .getRecordTypeId();

    private static Id interestRecordType = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName()
        .get('Student_Interest')
        .getRecordTypeId();

    @TestSetup
    private static void setup() {
        Account acc = new Account(FirstName = 'Test', LastName = 'Test', RecordTypeId = accountRecordTypeId);
        insert acc;

        List<Opportunity> opps = new List<Opportunity>{
            new Opportunity(
                RecordTypeId = apprenticeRecordType,
                name = 'Test Apprentice Application',
                Application_Id__c = 'test-1234',
                accountid = acc.Id,
                StageName = 'Application',
                CloseDate = Date.today()
            ),
            new Opportunity(
                RecordTypeId = applicationRecordType,
                name = 'Test Application',
                Application_Id__c = 'test-1235',
                accountid = acc.Id,
                StageName = 'Application',
                CloseDate = Date.today()
            ),
            new Opportunity(
                RecordTypeId = interestRecordType,
                name = 'Test Interest',
                Application_Id__c = 'test-1236',
                accountid = acc.Id,
                StageName = 'Application Started',
                CloseDate = Date.today()
            )
        };

        insert opps;
    }

    @isTest
    private static void itShouldUpdateTheOppToWithdrawn() {
        List<String> appIdsToTest = new List<String>{ 'test-1234', 'test-1235', 'test-1236' };
        List<Queue_Job__c> jobs = new List<Queue_Job__c>();

        for (String applicationId : appIdsToTest) {
            ApplicationWithdrewSchema schema = new ApplicationWithdrewSchema();
            schema.applicationId = applicationId;

            jobs.add(new Queue_Job__c(Job_Content__c = JSON.serialize(schema), Event_Time__c = DateTime.now()));
        }

        //WHEN the event processor is run
        System.Test.startTest();

        EventWithdrewProcessor processor = new EventWithdrewProcessor();
        processor.processImpl(jobs);

        System.Test.stopTest();

        // THEN the queue jobs are successful
        Assert.areEqual(3, processor.successfulJobs.size(), 'Expected 3 successful jobs');
        Assert.areEqual(0, processor.failedJobs.size(), 'Expected no failed jobs');

        Integer updatedOpps = 0;
        // AND the field values have been updated
        for (Opportunity oppAfter : [
            SELECT StageName, BPP_Sub_Status__c, BPP_Cancellation_Reason__c, recordType.DeveloperName
            FROM Opportunity
            WHERE Application_ID__c IN :appIdsToTest
        ]) {
            switch on oppAfter.recordType.DeveloperName {
                when 'Apprentice_Application' {
                    Assert.areEqual('Closed Lost', oppAfter.StageName, 'Stage should be closed lost');
                    Assert.areEqual('Withdrawn', oppAfter.BPP_Sub_Status__c, 'Sub-Stage should be withdrawn');
                    Assert.areEqual(
                        'appWithdrawApplicant',
                        oppAfter.BPP_Cancellation_Reason__c,
                        'Reason should be appWithdrawApplicant'
                    );
                    updatedOpps++;
                }
                when 'Student_Application' {
                    Assert.areEqual('Cancelled', oppAfter.StageName, 'Stage should be Cancelled');
                    Assert.areEqual('Withdrawn', oppAfter.BPP_Sub_Status__c, 'Sub-Stage should be withdrawn');
                    updatedOpps++;
                }
                when 'Student_Interest' {
                    Assert.areEqual('No Longer Interested', oppAfter.StageName, 'Stage should be No Longer Interested');
                    Assert.areEqual('Withdrawn', oppAfter.BPP_Sub_Status__c, 'Sub-Stage should be withdrawn');
                    updatedOpps++;
                }
            }
        }
        Assert.areEqual(3, updatedOpps);
    }

    @isTest
    private static void itShouldFailWithInvalidApp() {
        ApplicationWithdrewSchema schema = new ApplicationWithdrewSchema();
        schema.applicationId = 'test-fail';

        Queue_Job__c queueJob = new Queue_Job__c(
            Job_Content__c = JSON.serialize(schema),
            Event_Time__c = DateTime.now()
        );

        //WHEN the event processor is run
        System.Test.startTest();

        EventWithdrewProcessor processor = new EventWithdrewProcessor();
        processor.processImpl(new List<Queue_Job__c>{ queueJob });

        System.Test.stopTest();

        // THEN the queue job is unsuccessful
        Assert.areEqual(0, processor.successfulJobs.size(), 'Expected no successful jobs');
        Assert.areEqual(1, processor.failedJobs.size(), 'Expected one failed job');
    }

    @isTest
    private static void itShouldDeleteLinkedRecords() {
        // GIVEN a schema
        ApplicationWithdrewSchema schema = new ApplicationWithdrewSchema();
        schema.applicationId = 'test-1234';

        Opportunity existingOpp = [SELECT Id FROM Opportunity LIMIT 1];

        // AND and Opportunity with some KSBs
        insert new List<KSB__c>{
            new KSB__c(
                Code__c = 'ksb-1',
                Question__c = 'ksb-1',
                Answer__c = '1',
                Experience_Information__c = 'ksb 1',
                Opportunity__c = existingOpp.Id
            ),
            new KSB__c(
                Code__c = 'ksb-2',
                Question__c = 'ksb-2',
                Answer__c = '2',
                Experience_Information__c = 'ksb 2',
                Opportunity__c = existingOpp.Id
            )
        };

        // AND some external documents
        insert new List<External_Document__c>{
            new External_Document__c(
                Type__c = 'GENERAL',
                Category__c = '1',
                Document_ID__c = '1',
                Opportunity__c = existingOpp.Id
            ),
            new External_Document__c(
                Type__c = 'GENERAL',
                Category__c = '2',
                Document_ID__c = '2',
                Opportunity__c = existingOpp.Id
            )
        };

        // AND some application audits
        insert new List<Application_Audit__c>{
            new Application_Audit__c(
                Updated_By__c = 'Test 1',
                Opportunity__c = existingOpp.Id,
                Event_Date__c = DateTime.Now()
            ),
            new Application_Audit__c(
                Updated_By__c = 'Test 2',
                Opportunity__c = existingOpp.Id,
                Event_Date__c = DateTime.Now()
            )
        };

        Queue_Job__c queueJob = new Queue_Job__c(
            Job_Content__c = JSON.serialize(schema),
            Event_Time__c = DateTime.now()
        );

        //WHEN the event processor is run
        System.Test.startTest();

        EventWithdrewProcessor processor = new EventWithdrewProcessor();
        processor.processImpl(new List<Queue_Job__c>{ queueJob });

        System.Test.stopTest();

        // THEN the queue job is unsuccessful
        Assert.areEqual(1, processor.successfulJobs.size(), 'Expected 1 successful job');

        // AND all of the records should have been deleted
        Opportunity oppResults = [
            SELECT
                (SELECT Id FROM KSBs__r),
                (SELECT Id FROM External_Documents__r),
                (SELECT Id FROM Application_Reviews__r)
            FROM Opportunity
            LIMIT 1
        ];

        Assert.areEqual(0, oppResults.KSBs__r.size(), 'Expected 0 KSBs');
        Assert.areEqual(0, oppResults.External_Documents__r.size(), 'Expected 0 External Docs');
        Assert.areEqual(0, oppResults.Application_Reviews__r.size(), 'Expected 0 Application Reviews');
    }
}
