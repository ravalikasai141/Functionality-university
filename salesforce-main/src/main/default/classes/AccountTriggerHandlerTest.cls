@isTest
public class AccountTriggerHandlerTest {
    @testSetup
    static void testSetup() {
        AssignmentUsers__c assignmentUser = new AssignmentUsers__c();
        assignmentUser.Default_Admissions_Owner__c = UserInfo.getUserId().left(15);
        insert assignmentUser;

        Id admissionsUserId = [
            SELECT Id
            FROM User
            WHERE UserRole.Name = 'Domestic Team [+Record Assignment]' AND IsActive = TRUE
            ORDER BY Name
            LIMIT 1
        ]
        .Id;

        Owner_Assignment__c ownerAssign = new Owner_Assignment__c(
            Name = 'Domestic Team [+Record Assignment]',
            Last_Assignee__c = admissionsUserId
        );
        insert ownerAssign;

        Account account = new Account(
            FirstName = 'Round',
            LastName = 'RobinTest',
            OwnerId = admissionsUserId,
            BillingCountry = 'UK',
            RecordTypeId = Schema.Sobjecttype.Account.getRecordTypeInfosByName()
                .get('Student Account')
                .getRecordTypeId()
        );
        insert account;

        List<SFBD__DunningMethod__c> dunningMethodList = new List<SFBD__DunningMethod__c>();
        dunningMethodList.add(new SFBD__DunningMethod__c(Name = 'Key Client'));
        dunningMethodList.add(new SFBD__DunningMethod__c(Name = 'Transactional'));
        dunningMethodList.add(new SFBD__DunningMethod__c(Name = 'Students'));
        insert dunningMethodList;
    }

    @isTest
    static void test_reassignRecords_AccountReassignment() {
        Account accountBefore = [SELECT Id, OwnerId FROM Account];
        System.debug(accountBefore);
        Id ownerIdBefore = accountBefore.OwnerId;
        accountBefore.OwnerId = AssignmentUsers__c.getInstance().Default_Admissions_Owner__c;

        Test.startTest();
        update accountBefore;
        Test.stopTest();

        Account accountAfter = [SELECT Id, OwnerId FROM Account];
        System.assert(accountAfter.OwnerId != ownerIdBefore);
        System.assert(accountAfter.OwnerId != AssignmentUsers__c.getInstance().Default_Admissions_Owner__c);
    }

    @isTest
    static void test_dunningMethodUpdates() {
        TriggerExecute.bypassTrigger = true;

        Account clientAccount = new Account(Name = 'TestDataFactoryClient');
        clientAccount.Billing_Type__c = 'In Advance';
        clientAccount.Charge_Trigger__c = 'Instance Start Date';
        clientAccount.Client_Category__c = 'Key Client';
        insert clientAccount;

        Account studentAccount = TestDataFactory.createAccount(false, true, clientAccount.Id, 1);
        studentAccount.FirstName = 'TestDataFactoryStudent';
        insert studentAccount;

        Set<Id> accountIds = new Set<Id>{ clientAccount.Id, studentAccount.Id };

        List<Account> accountList = [SELECT Name, SFBD__DunningMethod__r.Name FROM Account WHERE Id IN :accountIds];
        Assert.areEqual(accountList.get(0).SFBD__DunningMethod__r.Name, 'Key Client');
        Assert.areEqual(accountList.get(1).SFBD__DunningMethod__r.Name, 'Students');

        clientAccount.Client_Category__c = 'Transactional Client';
        update clientAccount;

        Account clientAccountAfterUpdate = [
            SELECT SFBD__DunningMethod__r.Name
            FROM Account
            WHERE Id = :clientAccount.Id
        ];
        Assert.areEqual(clientAccountAfterUpdate.SFBD__DunningMethod__r.Name, 'Transactional');
    }

    @isTest
    private static void itShouldUpdatePersonEmailFromPersonal() {
        // Given we create an account with a personal email
        // When the trigger runs
        System.Test.startTest();

        Account acc = TestDataFactory.createAccount(true, true, 1);

        System.Test.stopTest();

        // Then I expect the PersonEmail to be personal email
        Assert.areEqual(acc.PersonEmail, acc.Personal_Email__pc);
    }

    @isTest
    private static void itShouldUpdatePersonEmailFromWorkEmail() {
        Account acc = TestDataFactory.createAccount(true, true, 1);

        TriggerExecute.bypassTrigger = true;

        System.Test.startTest();

        acc.Preferred_Email__pc = 'Work';
        acc.Work_Email__pc = 'testwork@bpp.com';
        update acc;

        System.Test.stopTest();

        Account out = [SELECT PersonEmail FROM Account WHERE Id = :acc.Id];

        Assert.areEqual(out.PersonEmail, acc.Work_Email__pc);
    }

    @isTest
    private static void itShouldUpdatePersonEmailFromBPPEmail() {
        Account acc = TestDataFactory.createAccount(true, true, 1);

        TriggerExecute.bypassTrigger = true;

        System.Test.startTest();

        acc.Preferred_Email__pc = 'BPP';
        acc.BPP_Email__pc = 'testbpp@bpp.com';
        update acc;

        System.Test.stopTest();

        Account out = [SELECT PersonEmail FROM Account WHERE Id = :acc.Id];

        Assert.areEqual(out.PersonEmail, acc.BPP_Email__pc);
    }

    @isTest
    private static void itShouldUpdatePersonEmailFromOtherEmail() {
        Account acc = TestDataFactory.createAccount(true, true, 1);

        TriggerExecute.bypassTrigger = true;

        System.Test.startTest();

        acc.Preferred_Email__pc = 'Other';
        acc.Other_Email__pc = 'testother@bpp.com';
        update acc;

        System.Test.stopTest();

        Account out = [SELECT PersonEmail FROM Account WHERE Id = :acc.Id];

        Assert.areEqual(out.PersonEmail, acc.Other_Email__pc);
    }

    @isTest
    private static void itShouldUpdatePersonEmailFromBillingEmail() {
        Account acc = TestDataFactory.createAccount(true, true, 1);

        TriggerExecute.bypassTrigger = true;

        System.Test.startTest();

        acc.Preferred_Email__pc = 'Billing';
        acc.Billing_Email__pc = 'testbilling@bpp.com';
        update acc;

        System.Test.stopTest();

        Account out = [SELECT PersonEmail FROM Account WHERE Id = :acc.Id];

        Assert.areEqual(out.PersonEmail, acc.Billing_Email__pc);
    }

    @isTest
    private static void itShouldCheckAddressesOnMerge() {
        // GIVEN accounts with addresses
        List<Account> accounts = new List<Account>{
            new Account(FirstName = 'Test', LastName = 'Account 1'),
            new Account(FirstName = 'Test', LastName = 'Account 2')
        };
        insert accounts;

        insert new List<Address__c>{
            new Address__c(Type__c = 'Home', Street_1__c = '1', Student__c = accounts[0].Id),
            new Address__c(Type__c = 'Home', Street_1__c = '2', Student__c = accounts[1].Id),
            new Address__c(Type__c = 'Term Time', Street_1__c = '3', Student__c = accounts[1].Id)
        };

        insert new List<Hub_Account__c>{
            new Hub_Account__c(
                Student__c = accounts[0].Id,
                Auth0_Id__c = 'sub|123456',
                Hub_Username__c = 'testuser1@bpp.com'
            ),
            new Hub_Account__c(
                Student__c = accounts[1].Id,
                Auth0_Id__c = 'sub|654321',
                Hub_Username__c = 'testuser2@bpp.com'
            )
        };

        MockHttpClient mock = new MockHttpClient();
        mock.addResponse('@', 200);

        // Disable outbound events killswitch by default
        TestUtilities.mockKillswitch(killswitch.BLOCK_OUTBOUND_EVENTS, false);

        // WHEN accounts are merged
        System.Test.startTest();
        System.Test.setMock(HttpCalloutMock.class, mock);

        // Clear the executedOperations map so that all trigger contexts can re-run
        TriggerExecute.executedOperations.clear();

        merge accounts[0] accounts[1];

        System.Test.getEventBus().deliver();
        Test.stopTest();

        // THEN it should have three addresses
        List<Address__c> mergedAddresses = [
            SELECT id, Type__c, Street_1__c, Active__c
            FROM Address__c
            WHERE Student__c IN :accounts
            ORDER BY Street_1__c
        ];
        Assert.areEqual(3, mergedAddresses.size());

        // AND one of the Street 1 or Street 2 values are inactive (Unpredictable due to the use of LastModifiedDate)
        Assert.isTrue(mergedAddresses[0].Active__c || mergedAddresses[1].Active__c);
        Assert.isFalse(mergedAddresses[0].Active__c && mergedAddresses[1].Active__c);

        // AND the Street 3 value should be active
        Assert.isTrue(mergedAddresses[2].Active__c);

        // AND the event should have been submitted
        System.assertEquals(1, mock.processedRequests);
    }

    @isTest
    static void itShouldSetContactDetailsConfirmation() {
        // GIVEN a Person account, Address and Opportunity
        Account studentAccount = [SELECT id FROM account WHERE lastName = 'RobinTest'];
        insert new Address__c(Type__c = 'Term time', Student__c = studentAccount.Id, Zip_Postal_Code__c = 'B01');

        Opportunity oppBefore = new Opportunity(
            Name = 'Test-Opp',
            AccountId = studentAccount.Id,
            RecordTypeId = AccountTriggerHandler.applicationRecordType,
            StageName = 'Application',
            CloseDate = Date.today()
        );
        insert oppBefore;

        // reset tracked operations
        TriggerExecute.reset();

        // WHEN Emergency Contact is set
        studentAccount.Emergency_Contact_First_Name__pc = 'Name';
        studentAccount.Emergency_Contact_Mobile__pc = '012345';

        System.Test.startTest();
        update studentAccount;

        System.Test.stopTest();

        // THEN Confirmation_of_Contact_Details__c is set to 'Validated'
        Opportunity oppAfter = [
            SELECT id, Confirmation_of_Contact_Details__c
            FROM Opportunity
            WHERE Id = :oppBefore.Id
        ];
        Assert.areEqual('Validated', oppAfter.Confirmation_of_Contact_Details__c);
    }

    @isTest
    static void itShouldCombineLearningDifficultyData() {
        // GIVEN a Person account
        Account studentAccount = [SELECT id FROM account WHERE lastName = 'RobinTest'];

        // reset tracked operations
        TriggerExecute.reset();

        // WHEN Primary Learning Disability and Secondary Learning Disability fields are set
        System.Test.startTest();

        studentAccount.Primary_Learning_Difficulty__c = '11';
        studentAccount.Secondary_Learning_Difficulty__c = '10;12';

        update studentAccount;

        System.Test.stopTest();

        // THEN the ESFA and HESA fields should have been updated as expected
        Account accountResults = [
            SELECT
                Primary_Disability_ESFA__pc,
                SFDC_Disability_Type_Code_Select__pc,
                All_identified_disabilities_ESFA__pc
            FROM account
            WHERE Id = :studentAccount.Id
        ];
        Assert.areEqual('96~ Other learning difficulty', accountResults.Primary_Disability_ESFA__pc);

        // AND the ESFA values have been combined
        List<String> expectedESFAValues = new List<String>{ '96~ Other learning difficulty', '97~ Other disability' };
        for (String currentValue : expectedESFAValues) {
            Assert.isTrue(accountResults.All_identified_disabilities_ESFA__pc.contains(currentValue));
        }

        // AND the HESA values have been combined (Excluding duplicates)
        List<String> expectedHESAValues = new List<String>{
            '96~ An impairment, health condition or learning difference not listed above',
            '51~ Learning difference such as dyslexia, dyspraxia or AD(H)D'
        };
        for (String currentValue : expectedHESAValues) {
            Assert.isTrue(accountResults.SFDC_Disability_Type_Code_Select__pc.contains(currentValue));
        }
    }
}
