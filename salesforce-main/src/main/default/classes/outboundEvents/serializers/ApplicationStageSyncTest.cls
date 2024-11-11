@isTest
private class ApplicationStageSyncTest {
    @TestSetup
    private static void setUp() {
        Id accRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName()
            .get('Student Account')
            .getRecordTypeId();
        Id oppRecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName()
            .get('Apprentice Application')
            .getRecordTypeId();
        Id trainingManagerRTId = Schema.SObjectType.Contact.getRecordTypeInfosByName()
            .get('Training Manager')
            .getRecordTypeId();
        Id oppApplicationRecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName()
            .get('Student_Application')
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

        Contact contact = new Contact(
            FirstName = 'Test',
            LastName = 'Tester',
            Work_Email__c = 'test@bpp.com',
            Preferred_Email__c = 'Work',
            Email = 'test@bpp.com',
            RecordTypeId = trainingManagerRTId
        );

        insert contact;

        Opportunity opp = new Opportunity(
            RecordTypeId = oppRecordTypeId,
            AccountId = account.Id,
            Name = 'Test Opportunity',
            Application_Id__c = 'test-1234',
            Line_Manager__c = contact.Id,
            StageName = 'Application',
            CloseDate = Date.today() + 30
        );

        insert opp;

        Opportunity oppAppl = new Opportunity(
            RecordTypeId = oppApplicationRecordTypeId,
            AccountId = account.Id,
            Name = 'Test Opportunity',
            Application_Id__c = 'test-12345',
            Line_Manager__c = contact.Id,
            StageName = 'Unconditional Offer',
            CloseDate = Date.today() + 30
        );

        insert oppAppl;
    }

    @isTest
    private static void itShouldBuildTheCorrectPayloadAtLineManagerStage() {
        // GIVEN we have an opp at line manager review stage
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Application_Id__c = 'test-1234'];

        opp.Bypass_Validation_Rule__c = true;
        opp.StageName = 'Line Manager Review';
        opp.BPP_Sub_Status__c = 'In Progress';
        update opp;

        // WHEN this is sent to the serializer
        Serializer serializer = new ApplicationStageSync();
        serializer.addRecord(opp);

        List<Map<String, Object>> payloads = serializer.serialize();
        Map<String, Object> payload = payloads[0];

        Assert.areEqual('LINE_MANAGER_REVIEW', payload.get('currentStage'));
        Assert.areEqual('IN_PROGRESS', payload.get('currentStageStatus'));

        Map<String, Object> lineManager = (Map<String, Object>) payload.get('lineManager');

        // THEN I expect it to build the correct payload
        Assert.areEqual('test-1234', payload.get('applicationId'));
        Assert.areEqual('Tester', lineManager.get('lastName'));
        Assert.areEqual('test@bpp.com', lineManager.get('email'));
    }

    @isTest
    private static void itShouldBuildTheCorrectPayloadAtAcceptance() {
        // GIVEN we have an opp at Acceptance stage
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Application_Id__c = 'test-1234'];

        opp.Bypass_Validation_Rule__c = true;
        opp.StageName = 'Acceptance';
        opp.BPP_Sub_Status__c = 'Completed';
        opp.AuthorisedOn__c = Datetime.now();
        update opp;

        // WHEN this is sent to the serializer
        Serializer serializer = new ApplicationStageSync();
        serializer.addRecord(opp);

        List<Map<String, Object>> payloads = serializer.serialize();
        Map<String, Object> payload = payloads[0];
        Map<String, Object> data = (Map<String, Object>) payload.get('data');

        System.debug(payload);

        // THEN I expect it to
        Assert.areEqual('ACCEPTANCE', payload.get('currentStage'));
        Assert.areEqual('COMPLETED', payload.get('currentStageStatus'));
        Assert.isNotNull((DateTime) data.get('bppAuthorizedOn'));
    }

    @isTest
    private static void itShouldBuildTheCorrectPayloadAtStatusUnconOffer() {
        // GIVEN we have an opp at Unconditional Offer stage
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Application_Id__c = 'test-12345'];

        opp.Bypass_Validation_Rule__c = true;
        opp.StageName = 'Unconditional Offer';
        update opp;

        // WHEN this is sent to the serializer
        Serializer serializer = new ApplicationStageSync();
        serializer.addRecord(opp);

        List<Map<String, Object>> payloads = serializer.serialize();
        Map<String, Object> payload = payloads[0];

        // THEN I expect it to
        Assert.areEqual('UNCONDITIONAL_OFFER', payload.get('currentStage'));
        Assert.areEqual('test-12345', payload.get('applicationId'));
    }
}
