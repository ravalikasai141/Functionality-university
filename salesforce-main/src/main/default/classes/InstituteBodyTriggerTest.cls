@isTest
private class InstituteBodyTriggerTest {
    @testSetup
    private static void setUp() {
        Id recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName()
            .get('Student Account')
            .getRecordTypeId();
        // Account
        Account account = new Account(
            RecordTypeId = recordTypeId,
            FirstName = 'Test',
            LastName = 'Tester',
            Salutation = 'Mr',
            Personal_Email__pc = 'test@bpp.com',
            Preferred_Email__pc = 'test@bpp.com'
        );

        insert account;

        insert new Hub_Account__c(
            Student__c = account.Id,
            Auth0_Id__c = 'sub|12345',
            Hub_Username__c = 'testuser@bpp.com'
        );

        // Institute Body
        insert new Institute_Body__c(
            Institute_Body__c = 'AAT',
            Institute_Number__c = 'ref-1234',
            Student__c = account.Id
        );
    }

    @isTest
    private static void itShouldSendAnEventWhenARecordIsCreated() {
        StreamingService.canFetchStreams = true;

        Account account = [SELECT Id FROM Account WHERE LastName = 'Tester'];
        // GIVEN we create a new Institute Body object
        // WHEN the trigger runs
        MockHttpClient mock = new MockHttpClient();
        mock.addResponse('@', 200);

        // Disable outbound events killswitch by default
        TestUtilities.mockKillswitch(killswitch.BLOCK_OUTBOUND_EVENTS, false);

        System.Test.startTest();
        System.Test.setMock(HttpCalloutMock.class, mock);

        insert new Institute_Body__c(Institute_Body__c = 'CFA', Institute_Number__c = '1', Student__c = account.Id);

        System.Test.getEventBus().deliver();
        System.Test.stopTest();

        // THEN I expect an event to be published
        Assert.areEqual(1, mock.processedRequests);
    }

    @isTest
    private static void itShouldSendAnEventWhenARecordIsUpdated() {
        StreamingService.canFetchStreams = true;

        // GIVEN we have an existing institute body object
        Institute_Body__c body = [
            SELECT Id, Institute_Number__c
            FROM Institute_Body__c
            WHERE Institute_Number__c = 'ref-1234'
        ];

        // WHEN the I update the record
        MockHttpClient mock = new MockHttpClient();
        mock.addResponse('@', 200);

        // Disable outbound events killswitch by default
        TestUtilities.mockKillswitch(killswitch.BLOCK_OUTBOUND_EVENTS, false);

        System.Test.startTest();
        System.Test.setMock(HttpCalloutMock.class, mock);

        body.Institute_Number__c = 'ref-4321';
        update body;

        System.Test.getEventBus().deliver();
        System.Test.stopTest();

        // THEN I expect an event to be published
        Assert.areEqual(1, mock.processedRequests);
    }

    @isTest
    private static void itShouldSendAnEventWhenARecordIsDeleted() {
        StreamingService.canFetchStreams = true;

        // GIVEN we have an existing institute body object
        Institute_Body__c body = [
            SELECT Id, Institute_Number__c
            FROM Institute_Body__c
            WHERE Institute_Number__c = 'ref-1234'
        ];

        // WHEN the I delete the record
        MockHttpClient mock = new MockHttpClient();
        mock.addResponse('@', 200);

        // Disable outbound events killswitch by default
        TestUtilities.mockKillswitch(killswitch.BLOCK_OUTBOUND_EVENTS, false);

        System.Test.startTest();
        System.Test.setMock(HttpCalloutMock.class, mock);

        delete body;

        System.Test.getEventBus().deliver();
        System.Test.stopTest();

        // THEN I expect an event to be published
        Assert.areEqual(1, mock.processedRequests);
    }

    @isTest
    private static void itShouldPreventMultipleInstituteBodiesWithTheSameBodyBeingCreated() {
        // GIVEN we already have an institute body
        Account account = [SELECT Id FROM Account WHERE LastName = 'Tester'];
        // WHEN we attempt to add a new one with the same body
        Boolean exceptionThrown = false;
        System.Test.startTest();

        try {
            insert new Institute_Body__c(Institute_Body__c = 'AAT', Institute_Number__c = '1', Student__c = account.Id);
        } catch (DMLException e) {
            exceptionThrown = true;
        }

        System.Test.stopTest();

        // THEN I expect it to fail
        Assert.isTrue(exceptionThrown);
    }
}
