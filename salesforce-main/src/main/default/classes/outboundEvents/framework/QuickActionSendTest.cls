@isTest
private class QuickActionSendTest {
    @TestSetup
    private static void setUp() {
        Id recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName()
            .get('Student Account')
            .getRecordTypeId();

        List<Account> accounts = new List<Account>{
            new Account(
                RecordTypeId = recordTypeId,
                FirstName = 'Test',
                LastName = 'Tester',
                Salutation = 'Mr',
                Personal_Email__pc = 'test@bpp.com',
                Preferred_Email__pc = 'Personal'
            ),
            new Account(
                RecordTypeId = recordTypeId,
                FirstName = 'Test2',
                LastName = 'Tester2',
                Salutation = 'Mr',
                Personal_Email__pc = 'test2@bpp.com',
                Preferred_Email__pc = 'Personal'
            )
        };

        insert accounts;

        insert new Hub_Account__c(
            Student__c = accounts[0].Id,
            Auth0_Id__c = 'sub|12345',
            Hub_Username__c = 'testuser@bpp.com'
        );
    }

    @isTest
    private static void itShouldSendEvents() {
        // Given we have a valid account
        Account account = [SELECT Id FROM Account WHERE LastName = 'Tester'];

        MockHttpClient mock = new MockHttpClient();
        mock.addResponse('@', 200);

        // When we call the SendStudentSyncEvent method
        System.Test.startTest();
        System.Test.setMock(HttpCalloutMock.class, mock);

        QuickActionSend.sendStudentSyncEvent(account);

        System.Test.stopTest();

        // Then I expect it to fire an event
        Assert.areEqual(1, mock.processedRequests);
    }

    @isTest
    private static void itShouldNotSendEventsIfThereIsNoDataToSend() {
        // Given we have an account with no hub account
        Account account = [SELECT Id FROM Account WHERE LastName = 'Tester2'];

        MockHttpClient mock = new MockHttpClient();
        mock.addResponse('@', 200);

        // When we call the SendStudentSyncEvent method
        System.Test.startTest();
        System.Test.setMock(HttpCalloutMock.class, mock);

        QuickActionSend.sendStudentSyncEvent(account);

        System.Test.stopTest();

        // Then i expect no event to be sent
        Assert.areEqual(0, mock.processedRequests);
    }
}
