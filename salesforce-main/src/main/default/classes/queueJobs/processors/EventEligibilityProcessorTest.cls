@isTest
public class EventEligibilityProcessorTest {
    static Id accountRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
        .get('Student_Account')
        .getRecordTypeId();

    static Id opportunityRecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName()
        .get('Apprentice Application')
        .getRecordTypeId();

    static String TEST_APPLICATION_ID = 'cd6a04b6-9990-4e30-8421-5ed7819c13c9';

    @TestSetup
    static void setup() {
        Account account = new Account(FirstName = 'Test', LastName = 'Test', RecordTypeId = accountRecordTypeId);
        insert account;

        insert new Opportunity(
            name = 'Test',
            Application_Id__c = TEST_APPLICATION_ID,
            accountid = account.Id,
            StageName = 'Application',
            CloseDate = Date.today(),
            RecordTypeId = opportunityRecordTypeId
        );
    }

    @isTest
    static void itShouldUpdateEligibilityFields() {
        // GIVEN an Opportunity (Setup)

        // AND a queue job
        EligibilitySchema eventSchema = createTestSchema();

        Queue_Job__c queueJob = new Queue_Job__c(Job_Content__c = JSON.serialize(eventSchema));

        // WHEN the event processor is run
        Test.startTest();
        EventEligibilityProcessor processor = new EventEligibilityProcessor();
        processor.processImpl(new List<Queue_Job__c>{ queueJob });
        Test.stopTest();

        // THEN the queue job is successful
        Assert.areEqual(1, processor.successfulJobs.size(), 'Expected one successful job');
        Assert.areEqual(0, processor.failedJobs.size(), 'Expected no failed jobs');

        // AND the eligability fields should be updated
        List<Opportunity> opps = [
            SELECT Id, Application_Id__c, Eligibility_Status__c, Eligibility_JSON__c, Eligibility_Text__c
            FROM Opportunity
        ];
        Assert.areEqual(1, opps.size());
        Opportunity oppAfter = opps[0];

        EligibilitySchema deserializedEligibility = (EligibilitySchema) JSON.deserialize(
            oppAfter.Eligibility_JSON__c,
            EligibilitySchema.class
        );
        Assert.areEqual(eventSchema.applicationId, oppAfter.Application_Id__c);
        Assert.areEqual(eventSchema.eligibility.templateCode, deserializedEligibility.eligibility.templateCode);
        Assert.areEqual(eventSchema.eligibility.submittedOn, deserializedEligibility.eligibility.submittedOn);
        Assert.areEqual(eventSchema.eligibility.isEligible, oppAfter.Eligibility_Status__c);
        Assert.isTrue(
            oppAfter.Eligibility_Text__c.contains(
                'Eligibility Status: ELIGIBLE | Date Submitted: 08/08/2023 | Template: August2023'
            )
        );
        Assert.areEqual(eventSchema.eligibility.summaryText, deserializedEligibility.eligibility.summaryText);
    }

    @isTest
    static void itShouldCloseIllegibleOpportunities() {
        // GIVEN an Opportunity (Setup)

        // AND a queue job with a illegible status
        EligibilitySchema eventSchema = createTestSchema();
        eventSchema.eligibility.isEligible = 'NOT_ELIGIBLE';

        Queue_Job__c queueJob = new Queue_Job__c(Job_Content__c = JSON.serialize(eventSchema));

        // WHEN the event processor is run
        Test.startTest();
        EventEligibilityProcessor processor = new EventEligibilityProcessor();
        processor.processImpl(new List<Queue_Job__c>{ queueJob });
        Test.stopTest();

        // THEN the queue job is successful
        Assert.areEqual(1, processor.successfulJobs.size(), 'Expected one successful job');
        Assert.areEqual(0, processor.failedJobs.size(), 'Expected no failed jobs');

        // AND the eligibility fields should be updated
        List<Opportunity> opps = [
            SELECT
                Id,
                Application_Id__c,
                Eligibility_Status__c,
                Eligibility_JSON__c,
                StageName,
                BPP_Cancellation_Reason__c,
                BPP_Sub_Status__c
            FROM Opportunity
        ];
        Assert.areEqual(1, opps.size());
        Opportunity oppAfter = opps[0];

        EligibilitySchema deserializedEligibility = (EligibilitySchema) JSON.deserialize(
            oppAfter.Eligibility_JSON__c,
            EligibilitySchema.class
        );
        Assert.areEqual(eventSchema.applicationId, oppAfter.Application_Id__c);
        Assert.areEqual(eventSchema.eligibility.templateCode, deserializedEligibility.eligibility.templateCode);
        Assert.areEqual(eventSchema.eligibility.submittedOn, deserializedEligibility.eligibility.submittedOn);
        Assert.areEqual(eventSchema.eligibility.isEligible, oppAfter.Eligibility_Status__c);

        // AND the Opportunity should have been closed
        Assert.areEqual('Closed Lost', oppAfter.StageName);
        Assert.areEqual('Not eligible', oppAfter.BPP_Sub_Status__c);
        Assert.areEqual('appNotEligible', oppAfter.BPP_Cancellation_Reason__c);
    }

    @isTest
    static void itShouldFailIfNoOppFound() {
        // GIVEN a queue job with an event that does not have a matching Opportunity
        EligibilitySchema eventSchema = createTestSchema();
        eventSchema.applicationId = 'InvalidApplicationId';

        Queue_Job__c queueJob = new Queue_Job__c(Job_Content__c = JSON.serialize(eventSchema));

        // WHEN the event processor is run
        Test.startTest();
        EventEligibilityProcessor processor = new EventEligibilityProcessor();
        processor.processImpl(new List<Queue_Job__c>{ queueJob });
        Test.stopTest();

        // THEN the queue job is successful
        Assert.areEqual(0, processor.successfulJobs.size(), 'Expected one successful job');
        Assert.areEqual(1, processor.failedJobs.size(), 'Expected no failed jobs');

        // AND no opp has been created
        List<Opportunity> opps = [
            SELECT Id, Application_Id__c, Eligibility_Status__c, Eligibility_JSON__c
            FROM Opportunity
            WHERE Application_Id__c = :eventSchema.applicationId
        ];
        Assert.areEqual(0, opps.size());
    }

    @isTest
    static void itShouldHandleMissingEventData() {
        // GIVEN a queue job with no event data
        Queue_Job__c queueJob = new Queue_Job__c(Job_Content__c = '{}');

        // WHEN the event processor is run
        Test.startTest();
        EventEligibilityProcessor processor = new EventEligibilityProcessor();
        processor.processImpl(new List<Queue_Job__c>{ queueJob });
        Test.stopTest();

        // THEN the queue job has failed
        Assert.areEqual(0, processor.successfulJobs.size(), 'Expected no successful jobs');
        Assert.areEqual(1, processor.failedJobs.size(), 'Expected one failed job');
        Assert.areEqual(
            'Required value null in event payload',
            processor.failedJobs.values()[0],
            'Expected one failed job'
        );
    }

    @isTest
    static void itShouldHandleMultipleJobsForOneOpportunity() {
        // GIVEN an Opportunity (Setup)

        // AND two queue jobs to update the same Opportunity with the second job being newer
        // Job One
        EligibilitySchema eventSchemaOne = createTestSchema();
        eventSchemaOne.eligibility.isEligible = 'ELIGIBLE';

        Queue_Job__c queueJobOne = new Queue_Job__c(
            Job_Content__c = JSON.serialize(eventSchemaOne),
            Event_Time__c = DateTime.now() - 7
        );

        // Job Two
        EligibilitySchema eventSchemaTwo = createTestSchema();
        eventSchemaTwo.eligibility.isEligible = 'NOT_ELIGIBLE';

        Queue_Job__c queueJobTwo = new Queue_Job__c(
            Job_Content__c = JSON.serialize(eventSchemaTwo),
            Event_Time__c = DateTime.now()
        );

        // WHEN the event processor is run
        Test.startTest();
        EventEligibilityProcessor processor = new EventEligibilityProcessor();
        processor.processImpl(new List<Queue_Job__c>{ queueJobOne, queueJobTwo });
        Test.stopTest();

        // THEN both queue jobs should be successful
        Assert.areEqual(2, processor.successfulJobs.size(), 'Expected two successful jobs');
        Assert.areEqual(0, processor.failedJobs.size(), 'Expected no failed jobs');

        // AND only one Opportunity should have been updated
        List<Opportunity> opps = [
            SELECT Eligibility_Status__c
            FROM Opportunity
        ];

        // AND the Opportunity should have been updated from the latest Event
        Assert.areEqual(1, opps.size());
        Assert.areEqual(eventSchemaTwo.eligibility.isEligible, opps[0].Eligibility_Status__c);
    }

    static EligibilitySchema createTestSchema() {
        EligibilitySchema eventSchema = new EligibilitySchema();
        eventSchema.applicationId = TEST_APPLICATION_ID;
        eventSchema.eligibility = new EligibilitySchema.Eligibility();
        eventSchema.eligibility.templateCode = 'August2023';
        eventSchema.eligibility.isEligible = 'ELIGIBLE';
        eventSchema.eligibility.submittedOn = Date.newInstance(2023, 8, 8);
        eventSchema.eligibility.summaryText = '<ul><li>Test Summary</li></ul>';

        return eventSchema;
    }
}
