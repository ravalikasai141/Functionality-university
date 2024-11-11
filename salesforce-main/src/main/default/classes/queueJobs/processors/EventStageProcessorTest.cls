@isTest
public class EventStageProcessorTest {
    private static String applicationId1 = 'test-4321';
    private static String applicationId2 = 'test-1234';
    private static Id accountRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
        .get('Student_Account')
        .getRecordTypeId();

    private static Map<String, Id> opportunityRecordTypeIds = new Map<String, Id>{
        'Apprentice_Application' => getOpportunityRecordTypeId('Apprentice_Application'),
        'Student_Interest' => getOpportunityRecordTypeId('Student_Interest'),
        'Student_Application' => getOpportunityRecordTypeId('Student_Application')
    };

    private static Id getOpportunityRecordTypeId(String recordType) {
        return Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get(recordType).getRecordTypeId();
    }

    @TestSetup
    private static void setup() {
        Account acc = new Account(FirstName = 'Test', LastName = 'Test', RecordTypeId = accountRecordTypeId);
        insert acc;

        Contact contact = new Contact(FirstName = 'Test', LastName = 'Tester', Email = 'test@bpp.com');
        insert contact;

        Opportunity opp1 = createOpportunity('Apprentice_Application', applicationId2, 'Application', acc, contact);
        insert opp1;

        Opportunity opp2 = createOpportunity('Apprentice_Application', applicationId1, 'Application', acc, contact);
        insert opp2;

        opp2.Bypass_Validation_Rule__c = true;
        opp2.StageName = 'Line Manager Review';
        update opp2;

        Opportunity opp3 = createOpportunity('Student_Interest', 'test-12345', 'Application Started', acc, contact);
        insert opp3;
    }

    private static Opportunity createOpportunity(
        String recordType,
        String applicationId,
        String stageName,
        Account acc,
        Contact contact
    ) {
        return new Opportunity(
            RecordTypeId = opportunityRecordTypeIds.get(recordType),
            name = 'Test',
            Application_Id__c = applicationId,
            accountid = acc.Id,
            Line_Manager__c = contact.Id,
            StageName = stageName,
            CloseDate = Date.today()
        );
    }

    @isTest
    private static void itShouldUpdateTheOppWithNewStageAndSubStage() {
        //Given a queue job that provides the stage "BPP_REVIEW"
        ApplicationStageSchema schema = new ApplicationStageSchema(applicationId2, 'BPP_REVIEW', 'Not Started');

        Queue_Job__c queueJob = new Queue_Job__c(
            Job_Content__c = JSON.serialize(schema),
            Event_Time__c = DateTime.now()
        );

        //WHEN the event processor is run
        System.Test.startTest();

        EventStageProcessor processor = new EventStageProcessor();
        processor.processImpl(new List<Queue_Job__c>{ queueJob });

        System.Test.stopTest();

        // THEN the queue job is successful
        Assert.areEqual(1, processor.successfulJobs.size(), 'Expected one successful job');
        Assert.areEqual(0, processor.failedJobs.size(), 'Expected no failed jobs');

        Opportunity oppAfter = [
            SELECT StageName, BPP_Sub_Status__c, Application_Date__c
            FROM Opportunity
            WHERE Application_Id__c = :applicationId2
        ];

        //AND the field values have been updated
        Assert.areEqual(oppAfter.StageName, 'BPP Review');
        Assert.areEqual(oppAfter.BPP_Sub_Status__c, 'Not Started');
        Assert.areEqual(oppAfter.Application_Date__c, Date.today());
    }

    @isTest
    private static void itShouldUpdateTheOppWithNewRecordTypeAndStageName() {
        //Given a queue job that provides the stage "BPP_REVIEW"
        Queue_Job__c queueJob = new Queue_Job__c(
            Job_Content__c = JSON.serialize(new ApplicationStageSchema('test-12345', 'BPP_REVIEW', 'IN_PROGRESS')),
            Event_Time__c = DateTime.now()
        );
        // WHEN the event is processed
        System.Test.startTest();
        new EventStageProcessor().processImpl(new List<Queue_Job__c>{ queueJob });
        System.Test.stopTest();

        Opportunity oppAfter = [
            SELECT StageName, Application_Date__c, RecordTypeId
            FROM Opportunity
            WHERE Application_Id__c = 'test-12345'
        ];

        //THEN the field values have been updated
        Assert.areEqual(oppAfter.StageName, 'Application');
        Assert.areEqual(oppAfter.RecordTypeId, opportunityRecordTypeIds.get('Student_Application'));
        Assert.areEqual(oppAfter.Application_Date__c, Date.today());
    }

    @isTest
    private static void itShouldFailQueueJobWhenStageNameIsNotApplication() {
        // GIVEN we have an event for an application that is already in BPP REVIEW
        ApplicationStageSchema schema = new ApplicationStageSchema(applicationId1, 'BPP_REVIEW', 'Not Started');

        Queue_Job__c queueJob = new Queue_Job__c(Job_Content__c = JSON.serialize(schema));

        // WHEN the processor runs
        System.Test.startTest();

        EventStageProcessor processor = new EventStageProcessor();
        processor.processImpl(new List<Queue_Job__c>{ queueJob });

        System.Test.stopTest();

        // THEN I expect it to fail the queue job
        Assert.areEqual(1, processor.failedJobs.size(), 'Expect 1 failed job');
    }

    @isTest
    private static void itShouldCaterForReSubmissions() {
        // GIVEN we have an opportunity
        Opportunity opp = [
            SELECT Bypass_Validation_Rule__c, StageName, BPP_Sub_Status__c
            FROM Opportunity
            WHERE Application_Id__c = :applicationId2
        ];
        // AND the opportunity is awaiting feedback
        opp.Bypass_Validation_Rule__c = true;
        opp.StageName = 'BPP Review';
        opp.BPP_Sub_Status__c = 'Awaiting Information';

        update opp;

        // WHEN the event is processed
        ApplicationStageSchema schema = new ApplicationStageSchema(applicationId2, 'BPP_REVIEW', 'IN PROGRESS');

        Queue_Job__c queueJob = new Queue_Job__c(Job_Content__c = JSON.serialize(schema));

        System.Test.startTest();

        EventStageProcessor processor = new EventStageProcessor();
        processor.processImpl(new List<Queue_Job__c>{ queueJob });

        System.Test.stopTest();

        // THEN I expect it to go back to Not Started
        Opportunity oppAfter = [
            SELECT BPP_Sub_Status__c
            FROM Opportunity
            WHERE Application_Id__c = :applicationId2
        ];

        Assert.areEqual(oppAfter.BPP_Sub_Status__c, 'Not Started');
    }

    @isTest
    private static void itShouldMoveIntoAwaitingSignOff() {
        // GIVEN we have an event for an opportunity at line manager review stage
        ApplicationStageSchema schema = new ApplicationStageSchema(
            applicationId1,
            'LINE_MANAGER_REVIEW',
            'AWAITING_APPLICANT_SIGNOFF'
        );

        Queue_Job__c queueJob = new Queue_Job__c(Job_Content__c = JSON.serialize(schema));

        // WHEN the event is processed
        System.Test.startTest();

        EventStageProcessor processor = new EventStageProcessor();
        processor.processImpl(new List<Queue_Job__c>{ queueJob });

        System.Test.stopTest();

        // THEN I expect it to move into awaiting sign off
        Opportunity oppAfter = [
            SELECT StageName, BPP_Sub_Status__c
            FROM Opportunity
            WHERE Application_Id__c = :applicationId1
        ];

        Assert.areEqual('Line Manager Review', oppAfter.StageName);
        Assert.areEqual('Awaiting Applicant Signoff', oppAfter.BPP_Sub_Status__c);
    }

    @isTest
    private static void itShouldMoveIntoAcceptance() {
        // GIVEN we have an event for an opportunity at acceptance stage
        Queue_Job__c queueJob = new Queue_Job__c(
            Job_Content__c = JSON.serialize(new ApplicationStageSchema(applicationId1, 'ACCEPTANCE', 'NEW'))
        );

        // WHEN the event is processed
        System.Test.startTest();

        new EventStageProcessor().processImpl(new List<Queue_Job__c>{ queueJob });

        System.Test.stopTest();

        // THEN I expect it to move into Acceptance with status of new
        Opportunity opp = [
            SELECT StageName, BPP_Sub_Status__c
            FROM Opportunity
            WHERE Application_Id__c = :applicationId1
        ];

        Assert.areEqual('Acceptance', opp.StageName);
        Assert.areEqual('New', opp.BPP_Sub_Status__c);
    }
}
