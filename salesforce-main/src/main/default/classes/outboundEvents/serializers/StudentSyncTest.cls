@isTest
private class StudentSyncTest {
    @TestSetup
    private static void setup() {
        Id recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName()
            .get('Student Account')
            .getRecordTypeId();

        Account account = new Account(
            RecordTypeId = recordTypeId,
            FirstName = 'Test',
            LastName = 'Tester',
            Salutation = 'Mr',
            Personal_Email__pc = 'test@bpp.com',
            Preferred_Email__pc = 'Personal',
            BNR_Banner_ID__pc = 'test-1'
        );

        insert account;

        insert new Hub_Account__c(
            Student__c = account.Id,
            Auth0_Id__c = 'sub|12345',
            Hub_Username__c = 'testuser@bpp.com'
        );

        // Add an address which relates to the student
        insert new List<Address__c>{
            new Address__c(
                Student__c = account.Id,
                Street_1__c = '5 fake drive',
                City__c = 'England',
                Zip_Postal_Code__c = '123',
                Type__c = 'Mailing'
            ),
            new Address__c(
                Student__c = account.Id,
                Street_1__c = '2 pretend house',
                City__c = 'Phoneyton',
                Zip_Postal_Code__c = 'L1E',
                Type__c = 'Home'
            )
        };
        // Add an Institute body which relates to the student
        insert new Institute_Body__c(Institute_Body__c = 'AAT', Institute_Number__c = '1', Student__c = account.Id);
    }

    @isTest
    private static void itShouldSerializeFromAnAccount() {
        // GIVEN we have an account
        Account account = [
            SELECT Id
            FROM Account
            WHERE LastName = 'Tester'
        ];

        // WHEN passed to the StudentSync class
        StudentSync sync = new StudentSync();
        sync.addRecord(account);

        List<Map<String, Object>> output = sync.serialize();
        Map<String, Object> detail = (Map<String, Object>) output.get(0);
        String SRN = (String) detail.get('studentReferenceNumber');
        Map<String, Object> personalInfo = (Map<String, Object>) detail.get('personalInfo');
        List<String> authIds = (List<String>) detail.get('userIds');
        List<Object> addresses = (List<Object>) detail.get('addresses');
        List<Object> instituteBodies = (List<Object>) detail.get('professionalQualifications');

        // THEN I expect it to serialize it correctly
        Assert.areEqual('test@bpp.com', personalInfo.get('emailAddress'), 'I expect the correct email address');
        Assert.areEqual('test-1', SRN);
        Assert.areEqual(1, output.size(), 'I expect one payload');
        Assert.areEqual(1, authIds.size(), 'I expect one hub id');
        Assert.areEqual(2, addresses.size(), 'I expect two Addresses');
        Assert.areEqual(1, instituteBodies.size(), 'I expect one Institute Body');
    }

    @isTest
    private static void itShouldSerializeFromAnAddress() {
        // GIVEN we have an address
        Address__c address = [SELECT Student__c FROM Address__c WHERE Type__c = 'Mailing' LIMIT 1];

        // WHEN passed to the StudentSync class
        StudentSync sync = new StudentSync();
        sync.addRecord(address);

        List<Map<String, Object>> output = sync.serialize();
        Map<String, Object> detail = (Map<String, Object>) output.get(0);
        List<String> authIds = (List<String>) detail.get('userIds');
        List<Object> addresses = (List<Object>) detail.get('addresses');
        List<Object> instituteBodies = (List<Object>) detail.get('professionalQualifications');

        // THEN I expect it to fetch the required objects and serialize it correctly
        Assert.areEqual(1, output.size(), 'I expect one payload');
        Assert.areEqual(1, authIds.size(), 'I expect one hub id');
        Assert.areEqual(2, addresses.size(), 'I expect two Addresses');
        Assert.areEqual(1, instituteBodies.size(), 'I expect one Institute Body');

        //AND If the Address Type is'Mailing', it should be serialized as 'Delivery'
        Map<String, Object> serializedAddress = (Map<String, Object>) addresses.get(0);
        Assert.areEqual('Delivery', serializedAddress.get('type'));
    }

    @isTest
    private static void itShouldSerializeExcludingAccountsWithNoHubAccount() {
        // GIVEN we have an account
        Account account = [
            SELECT Id
            FROM Account
            WHERE LastName = 'Tester'
        ];

        // AND there are no Hub Accounts
        delete [SELECT Id FROM Hub_Account__c];

        // WHEN passed to the StudentSync class
        StudentSync sync = new StudentSync();
        sync.addRecord(account);

        List<Map<String, Object>> output = sync.serialize();

        // THEN I expect it to serialize it correctly
        Assert.isTrue(output.isEmpty(), 'I expect there to be no payloads');
    }

    @isTest
    private static void itShouldSerializeExcludingAddressesWithNoDeterminableType() {
        // GIVEN we have an account
        Account account = [
            SELECT Id
            FROM Account
            WHERE LastName = 'Tester'
        ];

        // AND one of the Accounts addresses has no determinable type and the other only has its checkbox set
        Process_Bypasses__c setting = new Process_Bypasses__c();
        setting.Bypass_All_Triggers__c = true;
        setting.SetupOwnerId = UserInfo.getUserId();
        insert setting;

        List<Address__c> addresses = [SELECT Id FROM Address__c];
        addresses[0].Type__c = 'Term Time';
        addresses[1].Type__c = '';
        update addresses;

        delete [SELECT Id FROM Process_Bypasses__c];

        // WHEN passed to the StudentSync class
        StudentSync sync = new StudentSync();
        sync.addRecord(account);

        List<Map<String, Object>> output = sync.serialize();
        Map<String, Object> detail = (Map<String, Object>) output.get(0);
        List<String> authIds = (List<String>) detail.get('userIds');
        List<Object> addressResults = (List<Object>) detail.get('addresses');
        List<Object> instituteBodies = (List<Object>) detail.get('professionalQualifications');
        // THEN I expect it to serialize it correctly
        Assert.areEqual(1, output.size(), 'I expect one payload');
        Assert.areEqual(1, authIds.size(), 'I expect one hub id');
        Assert.areEqual(1, instituteBodies.size(), 'I expect one Institute Body');
        Assert.areEqual(1, addressResults.size(), 'I expect one Address');

        Map<String, Object> serializedAddress = (Map<String, Object>) addressResults.get(0);
        Assert.areEqual('Term time', serializedAddress.get('type'));
    }
}
