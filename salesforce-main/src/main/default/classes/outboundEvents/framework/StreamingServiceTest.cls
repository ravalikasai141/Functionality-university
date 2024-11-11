@isTest
private class StreamingServiceTest {
    @TestSetup
    static void setup() {
        Id recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName()
            .get('Student Account')
            .getRecordTypeId();

        Account testAccount = new Account(
            RecordTypeId = recordTypeId,
            FirstName = 'Test',
            LastName = 'Tester',
            Personal_Email__pc = 'test@bpp.com',
            Preferred_Email__pc = 'test@bpp.com'
        );
        insert testAccount;

        insert new Hub_Account__c(
            Student__c = testAccount.Id,
            Auth0_Id__c = 'sub|12345',
            Hub_Username__c = 'testuser@bpp.com'
        );
    }

    @isTest
    private static void itShouldBeAbleToDetectChanges() {
        // GIVEN we have an account update
        Account account = getAccount();
        Account updatedAccount = account.clone();
        updatedAccount.Id = account.Id;
        updatedAccount.Personal_Email__pc = null;

        // AND we have settings to stream account changes
        StreamingService service = new StreamingService();
        service.streams = new List<Object_Stream_Setting__mdt>{
            new Object_Stream_Setting__mdt(
                Fields__c = 'LastName, Personal_Email__pc',
                Record_Types__c = 'Student Account',
                Emitter__c = 'PlatformEventEmitter',
                Serializer__c = 'StudentSync'
            )
        };

        MockHttpClient mock = new MockHttpClient();
        mock.addResponse('@', 200);

        // Disable outbound events killswitch by default
        TestUtilities.mockKillswitch(killswitch.BLOCK_OUTBOUND_EVENTS, false);

        // WHEN the sync process is kicked off
        System.Test.startTest();
        System.Test.setMock(HttpCalloutMock.class, mock);

        service.process(new List<Account>{ updatedAccount }, new Map<Id, Account>{ account.Id => account });

        System.Test.stopTest();

        // THEN I expect an event to be created
        StudentSync serializer = (StudentSync) service.getSerializer('StudentSync');
        PlatformEventEmitter emitter = (PlatformEventEmitter) service.getEmitter('PlatformEventEmitter');

        System.assertEquals(1, serializer.accounts.size(), 'I expect 1 account to be in the change set');
        System.assertEquals(1, emitter.results.size(), 'I expect 1 result for the emitter');
        System.assert(emitter.results[0].isSuccess(), 'I expect a success result');
    }

    @isTest
    private static void itShouldDoNothingOnNoChanges() {
        // GIVEN I have an account that has not changed
        Account account = [
            SELECT Id, LastName, RecordTypeId
            FROM Account
            WHERE LastName = 'Tester'
        ];

        StreamingService service = new StreamingService();
        service.streams = new List<Object_Stream_Setting__mdt>{
            new Object_Stream_Setting__mdt(
                Fields__c = 'LastName',
                Record_Types__c = 'Student Account',
                Emitter__c = 'PlatformEventEmitter',
                Serializer__c = 'StudentSync'
            )
        };

        // WHEN this is processed by the streaming service
        System.Test.startTest();

        service.process(new List<Account>{ account }, new Map<Id, Account>{ account.Id => account });

        System.Test.stopTest();

        // THEN I expect no events
        StudentSync serializer = (StudentSync) service.getSerializer('StudentSync');

        System.assert(serializer.accounts.isEmpty(), 'I expect no accounts are processed');
    }

    @isTest
    private static void itShouldWorkOnRecordCreation() {
        // GIVEN I have a new account
        Account account = getAccount();

        // AND the settings allow creation events
        StreamingService service = new StreamingService();
        service.streams = new List<Object_Stream_Setting__mdt>{
            new Object_Stream_Setting__mdt(
                Fields__c = 'Personal_Email__pc',
                Emitter__c = 'PlatformEventEmitter',
                Serializer__c = 'StudentSync',
                Operation_Lock__c = 'AFTER_INSERT'
            )
        };

        MockHttpClient mock = new MockHttpClient();
        mock.addResponse('@', 200);

        // Disable outbound events killswitch by default
        TestUtilities.mockKillswitch(killswitch.BLOCK_OUTBOUND_EVENTS, false);

        // WHEN this is processed by the streaming service
        System.Test.startTest();
        System.Test.setMock(HttpCalloutMock.class, mock);

        service.operation = 'AFTER_INSERT';
        service.process(new List<Account>{ account }, new Map<Id, Account>{});

        System.Test.stopTest();

        // THEN I expect an event to be created
        StudentSync serializer = (StudentSync) service.getSerializer('StudentSync');
        PlatformEventEmitter emitter = (PlatformEventEmitter) service.getEmitter('PlatformEventEmitter');

        System.assertEquals(1, serializer.accounts.size(), 'I expect 1 account to be in the change set');
        System.assertEquals(1, emitter.results.size(), 'I expect 1 result for the emitter');
        System.assert(emitter.results[0].isSuccess(), 'I expect a success result');
    }

    @isTest
    private static void itShouldBeAbleToFetchConfig() {
        // GIVEN there are settings in the metadata
        // WHEN the streaming service is given an sObject type
        StreamingService service = new StreamingService();
        service.fetchConfig('Account');
        // THEN I expect it to be able to fetch configuration
        System.assert(!service.streams.isEmpty(), 'I expect at least one stream to be present');
    }

    @isTest
    private static void itShouldBlockIfKillswitchEnabled() {
        // GIVEN we have an account update
        Account account = getAccount();
        Account updatedAccount = account.clone();
        updatedAccount.Id = account.Id;
        updatedAccount.Personal_Email__pc = null;

        // AND we have settings to stream account changes
        StreamingService service = new StreamingService();
        service.streams = new List<Object_Stream_Setting__mdt>{
            new Object_Stream_Setting__mdt(
                Fields__c = 'LastName, Personal_Email__pc',
                Record_Types__c = 'Student Account',
                Emitter__c = 'PlatformEventEmitter',
                Serializer__c = 'StudentSync'
            )
        };

        // AND A killswitch exists
        TestUtilities.mockKillswitch(killswitch.BLOCK_OUTBOUND_EVENTS, true);

        MockHttpClient mock = new MockHttpClient();
        mock.addResponse('@', 200);

        // WHEN the sync process is kicked off
        System.Test.startTest();
        System.Test.setMock(HttpCalloutMock.class, mock);

        service.process(new List<Account>{ updatedAccount }, new Map<Id, Account>{ account.Id => account });

        System.Test.stopTest();

        // THEN I expect no events
        StudentSync serializer = (StudentSync) service.getSerializer('StudentSync');
    }

    @isTest
    private static void itShouldNotSubmitEventOnNoPayloads() {
        // GIVEN I have a new account
        Account account = getAccount();

        // AND there is no Hub Account associated with it (Causing an empty payload)
        delete [SELECT Id FROM Hub_Account__c];

        // AND the settings allow creation events
        StreamingService service = new StreamingService();
        service.streams = new List<Object_Stream_Setting__mdt>{
            new Object_Stream_Setting__mdt(
                Fields__c = 'Personal_Email__pc',
                Emitter__c = 'PlatformEventEmitter',
                Serializer__c = 'StudentSync'
            )
        };

        MockHttpClient mock = new MockHttpClient();
        mock.addResponse('@', 200);

        // WHEN this is processed by the streaming service
        System.Test.startTest();
        System.Test.setMock(HttpCalloutMock.class, mock);

        service.process(new List<Account>{ account }, new Map<Id, Account>{});

        System.Test.stopTest();

        // THEN I expect no events to have been created
        PlatformEventEmitter emitter = (PlatformEventEmitter) service.getEmitter('PlatformEventEmitter');
        System.assertEquals(null, emitter.results, 'I expect no results in the Emitter');
    }

    @isTest
    private static void itShouldAllowNamedEventsWhenPreventStreamIsTrue() {
        Account account = getAccount();
        Account updatedAccount = account.clone();
        updatedAccount.Id = account.Id;
        updatedAccount.Personal_Email__pc = null;

        // GIVEN we have prevent stream enabled
        // AND we have a named event
        StreamingService.preventStream = true;
        StreamingService.allowedEvents.add('userAccountUpdated');

        MockHttpClient mock = new MockHttpClient();
        mock.addResponse('@', 200);

        // WHEN changes happen
        System.Test.startTest();
        System.Test.setMock(HttpCalloutMock.class, mock);

        StreamingService service = new StreamingService();
        service.streams = new List<Object_Stream_Setting__mdt>{
            new Object_Stream_Setting__mdt(
                Event_Name__c = 'userAccountUpdated',
                Fields__c = 'Personal_Email__pc',
                Record_Types__c = 'Student Account',
                Emitter__c = 'PlatformEventEmitter',
                Serializer__c = 'StudentSync'
            )
        };

        service.process(new List<Account>{ updatedAccount }, new Map<Id, Account>{ account.Id => account });

        System.Test.stopTest();

        // THEN I expect it to allow the event to fire
        StudentSync serializer = (StudentSync) service.getSerializer('StudentSync');
        PlatformEventEmitter emitter = (PlatformEventEmitter) service.getEmitter('PlatformEventEmitter');

        System.assertEquals(1, serializer.accounts.size(), 'I expect 1 account to be in the change set');
        System.assertEquals(1, emitter.results.size(), 'I expect 1 result for the emitter');
    }

    /**
     * Fetches the Accounts used in test cases
     * @return  The test Account created in the test setup
     */
    private static Account getAccount() {
        return [
            SELECT
                Id,
                Salutation,
                FirstName,
                LastName,
                Middle_Name__pc,
                Preferred_First_Name__pc,
                Personal_Email__pc,
                PersonBirthdate,
                PersonMobilePhone,
                Work_Phone__pc,
                PersonHomePhone,
                Emergency_Contact_Email__pc,
                Emergency_Contact_First_Name__pc,
                Emergency_Contact_Last_Name__pc,
                Emergency_Contact_Mobile__pc,
                Emergency_Contact_Relationship__pc,
                RecordTypeId,
                PersonPronouns,
                Post_Opt_In__pc,
                Email_Opt_In__pc,
                Phone_Opt_In__pc,
                Social_Media_Opt_In__pc,
                SMS_Opt_In__pc,
                App_Notifications_Opt_In__pc
            FROM Account
            WHERE LastName = 'Tester'
        ];
    }
}
