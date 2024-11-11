@isTest
private class EventUserAccountUpdatedProcessorTest {
    private static final String UPDATE_PREFIX = 'New';

    @testSetup
    static void setup() {
        Id accountRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
            .get('Student_Account')
            .getRecordTypeId();

        // Create two Accounts for our tests
        List<Account> accountsToInsert = new List<Account>{
            new Account(
                FirstName = 'FirstName0',
                LastName = 'LastName0',
                Emergency_Contact_First_Name__pc = 'ECLastName0',
                RecordTypeId = accountRecordTypeId
            ),
            new Account(
                FirstName = 'FirstName1',
                LastName = 'LastName1',
                Emergency_Contact_First_Name__pc = 'ECLastName3',
                RecordTypeId = accountRecordTypeId
            ),
            //Create an Account to test Address Type
            new Account(
                FirstName = 'FirstName2',
                LastName = 'LastName2',
                Emergency_Contact_First_Name__pc = 'ECLastName0',
                RecordTypeId = accountRecordTypeId
            )
        };
        insert accountsToInsert;

        // Create two Countries for our test, using only the first for the initialised data
        List<country_list__c> testCountries = new List<country_list__c>{
            new country_list__c(Name = 'United Kingdom', country_code_2__c = 'GB', Valid_Nationality__c = true),
            new country_list__c(Name = 'United States', country_code_2__c = 'US', Valid_Nationality__c = true)
        };
        insert testCountries;

        // Create and link two Hub Accounts for each of our Accounts
        List<Hub_Account__c> hubAccountsToInsert = new List<Hub_Account__c>{
            new Hub_Account__c(
                Auth0_Id__c = 'Auth0Id0',
                Hub_Username__c = 'hub@username.invalid1',
                Student__c = accountsToInsert[0].Id
            ),
            new Hub_Account__c(
                Auth0_Id__c = 'Auth0Id1',
                Hub_Username__c = 'hub@username.invalid2',
                Student__c = accountsToInsert[0].Id
            ),
            new Hub_Account__c(
                Auth0_Id__c = 'Auth0Id2',
                Hub_Username__c = 'hub@username.invalid3',
                Student__c = accountsToInsert[1].Id
            ),
            new Hub_Account__c(
                Auth0_Id__c = 'Auth0Id3',
                Hub_Username__c = 'hub@username.invalid4',
                Student__c = accountsToInsert[1].Id
            ),
            // Create a Hub Account to test Address type.
            new Hub_Account__c(
                Auth0_Id__c = 'Auth0Id4',
                Hub_Username__c = 'hub@username.invalid5',
                Student__c = accountsToInsert[2].Id
            )
        };
        insert hubAccountsToInsert;

        // Create and link two Addresses for each of our Accounts
        List<Address__c> addressesToInsert = new List<Address__c>{
            new Address__c(
                Street_1__c = 'Street0',
                Student__c = accountsToInsert[0].Id,
                Lookup_Country__c = testCountries[0].Id,
                Type__c = 'Home'
            ),
            new Address__c(
                Street_1__c = 'Street1',
                Student__c = accountsToInsert[0].Id,
                Lookup_Country__c = testCountries[0].Id,
                Type__c = 'Billing'
            ),
            new Address__c(
                Street_1__c = 'Street2',
                Student__c = accountsToInsert[1].Id,
                Lookup_Country__c = testCountries[0].Id,
                Type__c = 'Home'
            ),
            new Address__c(
                Street_1__c = 'Street3',
                Student__c = accountsToInsert[1].Id,
                Lookup_Country__c = testCountries[0].Id,
                Type__c = 'Billing'
            ),
            // Create an Address to test Address Type
            new Address__c(
                Street_1__c = 'Street4',
                Student__c = accountsToInsert[2].Id,
                Lookup_Country__c = testCountries[0].Id,
                Type__c = 'Mailing'
            ),
            // Create an Address to test a blank Address Type
            new Address__c(
                Street_1__c = 'Street5',
                Student__c = accountsToInsert[2].Id,
                Lookup_Country__c = testCountries[0].Id,
                Type__c = 'Term time'
            ),
            // Create an Address to test types My doesn't support
            new Address__c(
                Street_1__c = 'Street6',
                Student__c = accountsToInsert[2].Id,
                Lookup_Country__c = testCountries[0].Id,
                Type__c = 'Next of Kin/Emergency/Guardian'
            )
        };
        insert addressesToInsert;

        insert new Institute_Body__c(
            Student__c = accountsToInsert[0].Id,
            Institute_Body__c = 'CFA',
            Institute_Number__c = 'reference123'
        );
    }

    @isTest
    public static void itShouldCreateAddresses() {
        // GIVEN we have no existing Addresses
        delete [SELECT Id FROM Address__c];

        Account account = [
            SELECT
                Id,
                FirstName,
                LastName,
                Emergency_Contact_First_Name__pc,
                (SELECT Auth0_Id__c FROM Hub_Accounts__r),
                (SELECT Institute_Body__c, Institute_Number__c FROM Institute_Bodies__r)
            FROM Account
            WHERE LastName = 'LastName0'
        ];

        // AND we have a new Address to add in the schema
        UserAccountUpdatedSchema schema = createSchemaFromAccount(account);
        UserAccountUpdatedSchema.Address addressToAdd = new UserAccountUpdatedSchema.Address();
        addressToAdd.country = 'GB';
        addressToAdd.type = 'Term time';
        addressToAdd.line1 = 'Example Street';
        schema.addresses.add(addressToAdd);

        List<Queue_Job__c> jobsToProcess = new List<Queue_Job__c>{ createQueueJob(schema) };
        insert jobsToProcess;

        // WHEN the event processor is run
        Test.startTest();

        EventUserAccountUpdatedProcessor processor = new EventUserAccountUpdatedProcessor();
        processor.processImpl(jobsToProcess);

        Test.stopTest();

        // THEN I expect the new Address to have been created
        Assert.areEqual(1, processor.successfulJobs.size());

        Account updatedAccount = [
            SELECT Id, (SELECT Lookup_Country__r.country_code_2__c FROM Addresses__r)
            FROM Account
            WHERE Id = :account.Id
        ];

        Assert.isFalse(updatedAccount.Addresses__r.isEmpty());
        Assert.areEqual(1, updatedAccount.Addresses__r.size());
        Assert.areEqual('GB', updatedAccount.Addresses__r[0].Lookup_Country__r.country_code_2__c);
    }

    @isTest
    public static void itShouldSkipToCreateInstituteBodies() {
        // GIVEN we have professional qualifications
        // AND we have an existing institute body against the account
        Account account = [
            SELECT
                FirstName,
                LastName,
                Emergency_Contact_First_Name__pc,
                (SELECT Auth0_Id__c FROM Hub_Accounts__r),
                (SELECT Id, Institute_Body__c, Institute_Number__c FROM Institute_Bodies__r)
            FROM Account
            WHERE LastName = 'LastName0'
        ];

        UserAccountUpdatedSchema schema = createSchemaFromAccount(account);

        UserAccountUpdatedSchema.Qualification cfaQualification = new UserAccountUpdatedSchema.Qualification();
        cfaQualification.awardingBody = 'CFA';
        cfaQualification.reference = 'newreference';
        schema.professionalQualifications.add(cfaQualification);

        UserAccountUpdatedSchema.Qualification qualification = new UserAccountUpdatedSchema.Qualification();
        qualification.awardingBody = 'ATT';
        qualification.reference = null;
        schema.professionalQualifications.add(qualification);

        List<Queue_Job__c> jobsToProcess = new List<Queue_Job__c>{ createQueueJob(schema) };
        insert jobsToProcess;

        // WHEN the event processor is run
        Test.startTest();

        EventUserAccountUpdatedProcessor processor = new EventUserAccountUpdatedProcessor();
        processor.processImpl(jobsToProcess);

        Test.stopTest();

        // THEN I expect the Queue Job to have been marked as successful
        Assert.areEqual(1, processor.successfulJobs.size());

        List<Institute_Body__c> bodies = [
            SELECT Id, Institute_Body__c, Institute_Number__c
            FROM Institute_Body__c
            WHERE Student__c = :account.Id
            ORDER BY Institute_Body__c
        ];

        // AND only the original Institute Body should remain
        Assert.areEqual(1, bodies.size(), 'No new Institute_Body__c should be created');
        Assert.areEqual('newreference', bodies[0].Institute_Number__c);
        Assert.areEqual(
            account.Institute_Bodies__r[0].Id,
            bodies[0].Id,
            'Institute Body returned does not match original Institute Body'
        );
    }

    @isTest
    public static void itShouldUpdateAccountsWithoutAddressesWithExactMatchingHubAccounts() {
        // GIVEN there are no Addresses
        delete [SELECT Id FROM Address__c];

        // AND we have a list of Accounts to update
        List<Account> priorAccounts = [
            SELECT FirstName, LastName, Emergency_Contact_First_Name__pc, (SELECT Auth0_Id__c FROM Hub_Accounts__r)
            FROM Account
        ];

        // AND the first Account has had its first name and emergency contact first name  updated
        Account priorAccountOne = priorAccounts[0];
        UserAccountUpdatedSchema schemaOne = createSchemaFromAccount(priorAccountOne);
        schemaOne.personalInfo.firstName = UPDATE_PREFIX + priorAccountOne.FirstName;
        schemaOne.emergencyContact.firstName = UPDATE_PREFIX + priorAccountOne.Emergency_Contact_First_Name__pc;

        // AND the second Account has had only its first name updated
        Account priorAccountTwo = priorAccounts[1];
        UserAccountUpdatedSchema schemaTwo = createSchemaFromAccount(priorAccountTwo);
        schemaTwo.emergencyContact.firstName = UPDATE_PREFIX + priorAccountTwo.Emergency_Contact_First_Name__pc;

        // AND a Queue Job should exist for each of these updates
        List<Queue_Job__c> jobsToProcess = new List<Queue_Job__c>{
            createQueueJob(schemaOne),
            createQueueJob(schemaTwo)
        };
        insert jobsToProcess;

        // WHEN the event processor is run
        Test.startTest();

        EventUserAccountUpdatedProcessor processor = new EventUserAccountUpdatedProcessor();
        processor.processImpl(jobsToProcess);

        Test.stopTest();

        // THEN there should be two successful Queue Jobs
        Assert.areEqual(2, processor.successfulJobs.size());

        Map<Id, Account> updatedAccounts = new Map<Id, Account>(
            [
                SELECT Id, FirstName, LastName, Emergency_Contact_First_Name__pc, (SELECT Id FROM Addresses__r)
                FROM Account
            ]
        );

        // AND the First Name and Emergency Contacts first name should have been updated for the first Account
        Account updatedAccountOne = updatedAccounts.get(priorAccountOne.Id);
        Assert.areEqual(schemaOne.personalInfo.firstName, updatedAccountOne.FirstName);
        Assert.areEqual(priorAccountOne.LastName, updatedAccountOne.LastName);
        Assert.areEqual(schemaOne.emergencyContact.firstName, updatedAccountOne.Emergency_Contact_First_Name__pc);
        Assert.isTrue(updatedAccountOne.Addresses__r.isEmpty());

        // AND the Emergency Contacts first name should have been updated for the second Account
        Account updatedAccountTwo = updatedAccounts.get(priorAccountTwo.Id);
        Assert.areEqual(priorAccountTwo.FirstName, updatedAccountTwo.FirstName);
        Assert.areEqual(priorAccountTwo.LastName, updatedAccountTwo.LastName);
        Assert.areEqual(schemaTwo.emergencyContact.firstName, updatedAccountTwo.Emergency_Contact_First_Name__pc);
        Assert.isTrue(updatedAccountTwo.Addresses__r.isEmpty());
    }

    @isTest
    public static void itShouldUpdateSingleAccountWithoutAddressesWithExactMatchingHubAccounts() {
        // GIVEN there are no Addresses
        delete [SELECT Id FROM Address__c];

        // AND we have a single Account to update
        Account priorAccount = [
            SELECT FirstName, LastName, Emergency_Contact_First_Name__pc, (SELECT Auth0_Id__c FROM Hub_Accounts__r)
            FROM Account
            LIMIT 1
        ];

        // AND it has had its first name and emergency contact first name updated
        UserAccountUpdatedSchema schema = createSchemaFromAccount(priorAccount);
        schema.personalInfo.firstName = UPDATE_PREFIX + priorAccount.FirstName;
        schema.emergencyContact.firstName = UPDATE_PREFIX + priorAccount.Emergency_Contact_First_Name__pc;

        // AND a Queue Job has been created for this update
        List<Queue_Job__c> jobsToProcess = new List<Queue_Job__c>{ createQueueJob(schema) };
        insert jobsToProcess;

        // WHEN the event processor is run
        Test.startTest();

        EventUserAccountUpdatedProcessor processor = new EventUserAccountUpdatedProcessor();
        processor.processImpl(jobsToProcess);

        Test.stopTest();

        // THEN there should be a single successful Queue Jobs
        Assert.areEqual(1, processor.successfulJobs.size());

        Map<Id, Account> updatedAccounts = new Map<Id, Account>(
            [
                SELECT Id, FirstName, LastName, Emergency_Contact_First_Name__pc, (SELECT Id FROM Addresses__r)
                FROM Account
            ]
        );

        // AND the First Name and Emergency Contacts first name should have been updated for the Account
        Account updatedAccount = updatedAccounts.get(priorAccount.Id);
        Assert.areEqual(schema.personalInfo.firstName, updatedAccount.FirstName);
        Assert.areEqual(priorAccount.LastName, updatedAccount.LastName);
        Assert.areEqual(schema.emergencyContact.firstName, updatedAccount.Emergency_Contact_First_Name__pc);
        Assert.isTrue(updatedAccount.Addresses__r.isEmpty());
    }

    @isTest
    public static void itShouldUpdateAccountsWithUpdatedAddressesWithExactMatchingHubAccounts() {
        // GIVEN we have a list of Accounts
        List<Account> priorAccounts = [
            SELECT
                FirstName,
                LastName,
                Emergency_Contact_First_Name__pc,
                (SELECT Auth0_Id__c FROM Hub_Accounts__r),
                (SELECT Street_1__c, Lookup_Country__r.country_code_2__c, Type__c, Active__c FROM Addresses__r)
            FROM Account
        ];

        // AND the the first Account's First Name and both Address line one's are updated
        Account priorAccountOne = priorAccounts[0];
        UserAccountUpdatedSchema schemaOne = createSchemaFromAccount(priorAccountOne);
        schemaOne.personalInfo.firstName = UPDATE_PREFIX + priorAccountOne.FirstName;
        schemaOne.addresses[0].line1 = UPDATE_PREFIX + priorAccountOne.addresses__r[0].Street_1__c;
        schemaOne.addresses[1].line1 = UPDATE_PREFIX + priorAccountOne.addresses__r[1].Street_1__c;

        // AND the the second Account's First Name and both Address line one's are updated
        Account priorAccountTwo = priorAccounts[1];
        UserAccountUpdatedSchema schemaTwo = createSchemaFromAccount(priorAccountTwo);
        schemaTwo.personalInfo.firstName = UPDATE_PREFIX + priorAccountTwo.FirstName;
        schemaTwo.addresses[0].line1 = UPDATE_PREFIX + priorAccountTwo.addresses__r[0].Street_1__c;
        schemaTwo.addresses[1].line1 = UPDATE_PREFIX + priorAccountTwo.addresses__r[1].Street_1__c;

        //AND addresses Type is updated
        Account priorAccountThree = priorAccounts[2];
        UserAccountUpdatedSchema schemaThree = createSchemaFromAccount(priorAccountThree);

        schemaThree.addresses.get(1).type = 'Term time';

        schemaThree.personalInfo.firstName = UPDATE_PREFIX + priorAccountThree.FirstName;
        schemaThree.addresses[0].type = 'Delivery';

        // AND remove the Next of kin address
        schemaThree.addresses.remove(2);

        // AND the second Account's first address
        schemaTwo.addresses.remove(0);

        // AND a Queue Job should exist for each of these updates
        List<Queue_Job__c> jobsToProcess = new List<Queue_Job__c>{
            createQueueJob(schemaOne),
            createQueueJob(schemaTwo),
            createQueueJob(schemaThree)
        };
        insert jobsToProcess;

        // WHEN the event processor is run
        Test.startTest();

        EventUserAccountUpdatedProcessor processor = new EventUserAccountUpdatedProcessor();
        processor.processImpl(jobsToProcess);

        Test.stopTest();

        // THEN there should three successful jobs
        Assert.areEqual(3, processor.successfulJobs.size());

        Map<Id, Account> updatedAccounts = new Map<Id, Account>(
            [
                SELECT
                    Id,
                    FirstName,
                    LastName,
                    Emergency_Contact_First_Name__pc,
                    (SELECT Auth0_Id__c FROM Hub_Accounts__r),
                    (
                        SELECT Street_1__c, Lookup_Country__r.country_code_2__c, Type__c, Active__c
                        FROM Addresses__r
                    )
                FROM Account
            ]
        );

        // AND both the First Name and Line One's of both Addresses of the first Account should have been updated
        // Account
        Account updatedAccountOne = updatedAccounts.get(priorAccountOne.Id);
        Assert.areEqual(schemaOne.personalInfo.firstName, updatedAccountOne.FirstName);
        Assert.areEqual(priorAccountOne.LastName, updatedAccountOne.LastName);

        // Address
        Assert.areEqual(2, updatedAccountOne.Addresses__r.size());
        Assert.areEqual(schemaOne.addresses[0].line1, updatedAccountOne.Addresses__r[0].Street_1__c);
        Assert.areEqual(priorAccountOne.Addresses__r[0].Type__c, updatedAccountOne.Addresses__r[0].Type__c);
        Assert.areEqual(schemaOne.addresses[1].line1, updatedAccountOne.Addresses__r[1].Street_1__c);
        Assert.areEqual(priorAccountOne.Addresses__r[1].Type__c, updatedAccountOne.Addresses__r[1].Type__c);

        // AND both the First Name and Line One's of both Addresses of the second Account should have been updated
        // Account
        Account updatedAccountTwo = updatedAccounts.get(priorAccountTwo.Id);
        Assert.areEqual(schemaOne.personalInfo.firstName, updatedAccountOne.FirstName);
        Assert.areEqual(priorAccountOne.LastName, updatedAccountOne.LastName);

        // Address
        Assert.areEqual(2, updatedAccountTwo.Addresses__r.size());

        // AND the first address is deactivated
        Assert.areEqual(false, updatedAccountTwo.Addresses__r[0].Active__c);
        Assert.areEqual(priorAccountTwo.Addresses__r[0].Type__c, updatedAccountTwo.Addresses__r[0].Type__c);

        Assert.areEqual(schemaTwo.addresses[0].line1, updatedAccountTwo.Addresses__r[1].Street_1__c);
        Assert.areEqual(priorAccountTwo.Addresses__r[1].Type__c, updatedAccountTwo.Addresses__r[1].Type__c);

        // AND the first address type is 'Mailing' for the third Account
        Account updatedAccountThree = updatedAccounts.get(priorAccountThree.Id);
        Assert.areEqual(3, updatedAccountThree.Addresses__r.size());
        Assert.areEqual(schemaThree.addresses[0].line1, updatedAccountThree.Addresses__r[0].Street_1__c);
        Assert.areEqual('Mailing', updatedAccountThree.Addresses__r[0].Type__c);

        // AND the second address should have been deactivated as it was excluded from
        Assert.areEqual(true, updatedAccountThree.Addresses__r[1].Active__c);
        Assert.areEqual('Term time', updatedAccountThree.Addresses__r[1].Type__c);

        // AND the Next of Kin address is still active
        Assert.areEqual(true, updatedAccountThree.Addresses__r[2].Active__c);
        Assert.areEqual('Next of Kin/Emergency/Guardian', updatedAccountThree.Addresses__r[2].Type__c);
    }

    @isTest
    public static void itShouldFailJobsWithDuplicateAddresses() {
        // GIVEN we have a list of Accounts
        List<Account> priorAccounts = [
            SELECT
                FirstName,
                LastName,
                Emergency_Contact_First_Name__pc,
                (SELECT Auth0_Id__c FROM Hub_Accounts__r),
                (SELECT Street_1__c, Lookup_Country__r.country_code_2__c, Type__c FROM Addresses__r)
            FROM Account
        ];

        // AND the first Account has an Update defined without duplicate addresses
        Account priorAccountOne = priorAccounts[0];
        UserAccountUpdatedSchema schemaOne = createSchemaFromAccount(priorAccountOne);
        schemaOne.personalInfo.firstName = UPDATE_PREFIX + priorAccountOne.FirstName;

        // AND the second Account has an update defined containing a duplicate address
        Account priorAccountTwo = priorAccounts[1];
        UserAccountUpdatedSchema schemaTwo = createSchemaFromAccount(priorAccountTwo);
        schemaTwo.personalInfo.firstName = UPDATE_PREFIX + priorAccountTwo.FirstName;
        schemaTwo.addresses[1].type = schemaTwo.addresses[0].type;

        // AND a Queue Job should exist for each of these updates
        List<Queue_Job__c> jobsToProcess = new List<Queue_Job__c>{
            createQueueJob(schemaOne),
            createQueueJob(schemaTwo)
        };
        insert jobsToProcess;

        // WHEN the event processor is run
        Test.startTest();

        EventUserAccountUpdatedProcessor processor = new EventUserAccountUpdatedProcessor();
        processor.processImpl(jobsToProcess);

        Test.stopTest();

        // THEN only one of the jobs should have been successful
        Assert.areEqual(1, processor.successfulJobs.size());
        Assert.areEqual(1, processor.failedJobs.size());

        // AND the error message on the second job should match what we expect
        Assert.areEqual(EventUserAccountUpdatedProcessor.DUPLICATE_ADDRESS, processor.failedJobs.values()[0]);

        Map<Id, Account> updatedAccounts = new Map<Id, Account>(
            [
                SELECT
                    Id,
                    FirstName,
                    LastName,
                    Emergency_Contact_First_Name__pc,
                    (SELECT Auth0_Id__c FROM Hub_Accounts__r),
                    (SELECT Street_1__c, Lookup_Country__r.country_code_2__c, Type__c FROM Addresses__r)
                FROM Account
            ]
        );

        // AND only the First Name should have been updated for the first Account
        Account updatedAccountOne = updatedAccounts.get(priorAccountOne.Id);
        Assert.areEqual(schemaOne.personalInfo.firstName, updatedAccountOne.FirstName);
        Assert.areEqual(priorAccountOne.LastName, updatedAccountOne.LastName);

        // AND the Addresses against the first Account have been updated as expected
        for (Integer i = 0; i < priorAccountOne.Addresses__r.size(); i++) {
            UserAccountUpdatedSchema.Address schemaAddress = schemaOne.addresses[i];
            Address__c oldAddress = priorAccountOne.Addresses__r[i];
            Address__c newAddress = updatedAccountOne.Addresses__r[i];

            Assert.areEqual(oldAddress.Type__c, newAddress.Type__c);
            Assert.areEqual(
                oldAddress.Lookup_Country__r.country_code_2__c,
                newAddress.Lookup_Country__r.country_code_2__c
            );
            Assert.areEqual(schemaAddress.line1, newAddress.Street_1__c);
        }

        // AND nothing should have been updated on the second Account
        Assert.areEqual(priorAccountTwo, updatedAccounts.get(priorAccountTwo.Id));
    }

    @isTest
    public static void itShouldDeactivateAddresssesNotIncluded() {
        // GIVEN an account with addresses
        List<Account> priorAccounts = [
            SELECT
                FirstName,
                LastName,
                Emergency_Contact_First_Name__pc,
                (SELECT Auth0_Id__c FROM Hub_Accounts__r),
                (SELECT Street_1__c, Lookup_Country__r.country_code_2__c, Type__c FROM Addresses__r)
            FROM Account
        ];

        // AND a schema with only one address type
        UserAccountUpdatedSchema schema = new UserAccountUpdatedSchema();
        schema.personalInfo.firstName = priorAccounts[0].FirstName;
        schema.personalInfo.lastName = priorAccounts[0].LastName;
        schema.emergencyContact.firstName = priorAccounts[0].Emergency_Contact_First_Name__pc;

        for (Hub_Account__c currentHubAccount : priorAccounts[0].Hub_Accounts__r) {
            schema.userIds.add(currentHubAccount.Auth0_Id__c);
        }

        Address__c addressPrior = priorAccounts[0].Addresses__r[0];
        String newStreet = 'Test Street Updated';

        UserAccountUpdatedSchema.Address addressToAdd = new UserAccountUpdatedSchema.Address();
        addressToAdd.country = addressPrior.Lookup_Country__r.country_code_2__c;
        addressToAdd.type = addressPrior.Type__c;
        addressToAdd.line1 = newStreet;
        schema.addresses.add(addressToAdd);

        // AND a Queue Job should exist for each of these updates
        List<Queue_Job__c> jobsToProcess = new List<Queue_Job__c>{ createQueueJob(schema) };
        insert jobsToProcess;

        // WHEN the event processor is run
        Test.startTest();

        EventUserAccountUpdatedProcessor processor = new EventUserAccountUpdatedProcessor();
        processor.processImpl(jobsToProcess);

        Test.stopTest();

        // THEN there should be one successful job
        Assert.areEqual(1, processor.successfulJobs.size());

        // AND one was updated and the others were deactivated
        List<Address__c> updatedAddresses = [
            SELECT id, Active__c, Type__c, Street_1__c
            FROM Address__c
            WHERE Student__c = :priorAccounts[0].id
        ];

        // AND the Addresses against the first Account have been updated as expected
        List<Address__c> deactivatedAddresses = new List<Address__c>();
        Address__c updatedAddress;

        for (Address__c address : updatedAddresses) {
            if (address.Type__c == addressPrior.Type__c) {
                Assert.isNull(updatedAddress, 'Only one address should be updated');
                updatedAddress = address;
            } else if (address.Active__c == false) {
                deactivatedAddresses.add(address);
            }
        }

        Assert.areEqual(newStreet, updatedAddress.Street_1__c);
        Assert.areEqual(1, deactivatedAddresses.size());
    }

    @isTest
    public static void itShouldFailJobsWithMissingUserIds() {
        // GIVEN we have a list of Accounts
        List<Account> priorAccounts = [
            SELECT FirstName, LastName, Emergency_Contact_First_Name__pc, (SELECT Auth0_Id__c FROM Hub_Accounts__r)
            FROM Account
        ];

        // AND the first Account has a valid Update defined
        Account priorAccountOne = priorAccounts[0];
        UserAccountUpdatedSchema schemaOne = createSchemaFromAccount(priorAccountOne);
        schemaOne.personalInfo.firstName = UPDATE_PREFIX + priorAccountOne.FirstName;

        // AND the second Account has an update defined containing a missing User Id
        Account priorAccountTwo = priorAccounts[1];
        UserAccountUpdatedSchema schemaTwo = createSchemaFromAccount(priorAccountTwo);
        schemaTwo.personalInfo.firstName = UPDATE_PREFIX + priorAccountTwo.FirstName;
        schemaTwo.userIds.add('MissingUserId');

        // AND a Queue Job should exist for each of these updates
        List<Queue_Job__c> jobsToProcess = new List<Queue_Job__c>{
            createQueueJob(schemaOne),
            createQueueJob(schemaTwo)
        };
        insert jobsToProcess;

        // WHEN the event processor is run
        Test.startTest();

        EventUserAccountUpdatedProcessor processor = new EventUserAccountUpdatedProcessor();
        processor.processImpl(jobsToProcess);

        Test.stopTest();

        // THEN only one of the jobs should have been successful
        Assert.areEqual(1, processor.successfulJobs.size());
        Assert.areEqual(1, processor.failedJobs.size());

        // AND the error message on the second job should match what we expect
        Assert.areEqual(EventUserAccountUpdatedProcessor.USER_ID_ERROR, processor.failedJobs.values()[0]);

        Map<Id, Account> updatedAccounts = new Map<Id, Account>(
            [
                SELECT
                    Id,
                    FirstName,
                    LastName,
                    Emergency_Contact_First_Name__pc,
                    (SELECT Auth0_Id__c FROM Hub_Accounts__r)
                FROM Account
            ]
        );

        // AND only the First Name should have been updated for the first Account
        Account updatedAccountOne = updatedAccounts.get(priorAccountOne.Id);
        Assert.areEqual(schemaOne.personalInfo.firstName, updatedAccountOne.FirstName);
        Assert.areEqual(priorAccountOne.LastName, updatedAccountOne.LastName);

        // AND nothing should have been updated on the second Account
        Assert.areEqual(priorAccountTwo, updatedAccounts.get(priorAccountTwo.Id));
    }

    @isTest
    public static void itShouldFailJobsWithInvalidCountry() {
        // GIVEN we have a list of Accounts
        List<Account> priorAccounts = [
            SELECT
                FirstName,
                LastName,
                Emergency_Contact_First_Name__pc,
                (SELECT Auth0_Id__c FROM Hub_Accounts__r),
                (SELECT Street_1__c, Lookup_Country__r.country_code_2__c, Type__c FROM Addresses__r)
            FROM Account
        ];

        // AND the first Account has a valid Update defined
        Account priorAccountOne = priorAccounts[0];
        UserAccountUpdatedSchema schemaOne = createSchemaFromAccount(priorAccountOne);
        schemaOne.personalInfo.firstName = UPDATE_PREFIX + priorAccountOne.FirstName;

        // AND the second Account has an update defined containing an invalid Country ISO code against one of the Addresses
        Account priorAccountTwo = priorAccounts[1];
        UserAccountUpdatedSchema schemaTwo = createSchemaFromAccount(priorAccountTwo);
        schemaTwo.personalInfo.firstName = UPDATE_PREFIX + priorAccountTwo.FirstName;
        schemaTwo.addresses[0].country = 'Invalid';

        // AND a Queue Job should exist for each of these updates
        List<Queue_Job__c> jobsToProcess = new List<Queue_Job__c>{
            createQueueJob(schemaOne),
            createQueueJob(schemaTwo)
        };
        insert jobsToProcess;

        // WHEN the event processor is run
        Test.startTest();

        EventUserAccountUpdatedProcessor processor = new EventUserAccountUpdatedProcessor();
        processor.processImpl(jobsToProcess);

        Test.stopTest();

        // THEN only one of the jobs should have been successful
        Assert.areEqual(1, processor.successfulJobs.size());
        Assert.areEqual(1, processor.failedJobs.size());

        // AND the error message on the second job should match what we expect
        Assert.areEqual(EventUserAccountUpdatedProcessor.INVALID_COUNTRY, processor.failedJobs.values()[0]);

        Map<Id, Account> updatedAccounts = new Map<Id, Account>(
            [
                SELECT
                    Id,
                    FirstName,
                    LastName,
                    Emergency_Contact_First_Name__pc,
                    (SELECT Auth0_Id__c FROM Hub_Accounts__r),
                    (SELECT Street_1__c, Lookup_Country__r.country_code_2__c, Type__c FROM Addresses__r)
                FROM Account
            ]
        );

        // AND only the First Name should have been updated for the first Account
        Account updatedAccountOne = updatedAccounts.get(priorAccountOne.Id);
        Assert.areEqual(schemaOne.personalInfo.firstName, updatedAccountOne.FirstName);
        Assert.areEqual(priorAccountOne.LastName, updatedAccountOne.LastName);

        // AND nothing should have been updated on the second Account
        Assert.areEqual(priorAccountTwo, updatedAccounts.get(priorAccountTwo.Id));
    }

    @isTest
    public static void itShouldFailJobsWithUserIdsLinkedToDifferingAccouts() {
        // GIVEN we have a list of Accounts
        List<Account> priorAccounts = [
            SELECT
                FirstName,
                LastName,
                Emergency_Contact_First_Name__pc,
                (SELECT Auth0_Id__c FROM Hub_Accounts__r),
                (SELECT Street_1__c, Lookup_Country__r.country_code_2__c, Type__c FROM Addresses__r)
            FROM Account
        ];

        // AND the first Account has a valid Update defined
        Account priorAccountOne = priorAccounts[0];
        UserAccountUpdatedSchema schemaOne = createSchemaFromAccount(priorAccountOne);
        schemaOne.personalInfo.firstName = UPDATE_PREFIX + priorAccountOne.FirstName;
        schemaOne.userIds = new List<String>{ priorAccountOne.Hub_Accounts__r[0].Auth0_Id__c };

        // AND the second Account has an update defined containing a User Id linking to the first Account
        Account priorAccountTwo = priorAccounts[1];
        UserAccountUpdatedSchema schemaTwo = createSchemaFromAccount(priorAccountTwo);
        schemaTwo.personalInfo.firstName = UPDATE_PREFIX + priorAccountTwo.FirstName;
        schemaTwo.userIds[1] = priorAccountOne.Hub_Accounts__r[1].Auth0_Id__c;

        // AND a Queue Job should exist for each of these updates
        List<Queue_Job__c> jobsToProcess = new List<Queue_Job__c>{
            createQueueJob(schemaOne),
            createQueueJob(schemaTwo)
        };
        insert jobsToProcess;

        // WHEN the event processor is run
        Test.startTest();

        EventUserAccountUpdatedProcessor processor = new EventUserAccountUpdatedProcessor();
        processor.processImpl(jobsToProcess);

        Test.stopTest();

        // THEN only one of the jobs should have been successful
        Assert.areEqual(1, processor.successfulJobs.size());
        Assert.areEqual(1, processor.failedJobs.size());

        // AND the error message on the second job should match what we expect
        Assert.areEqual(EventUserAccountUpdatedProcessor.USER_ID_ERROR, processor.failedJobs.values()[0]);

        Map<Id, Account> updatedAccounts = new Map<Id, Account>(
            [
                SELECT
                    Id,
                    FirstName,
                    LastName,
                    Emergency_Contact_First_Name__pc,
                    (SELECT Auth0_Id__c FROM Hub_Accounts__r),
                    (SELECT Street_1__c, Lookup_Country__r.country_code_2__c, Type__c FROM Addresses__r)
                FROM Account
            ]
        );

        // AND only the First Name should have been updated for the first Account
        Account updatedAccountOne = updatedAccounts.get(priorAccountOne.Id);
        Assert.areEqual(schemaOne.personalInfo.firstName, updatedAccountOne.FirstName);
        Assert.areEqual(priorAccountOne.LastName, updatedAccountOne.LastName);

        // AND nothing should have been updated on the second Account
        Assert.areEqual(priorAccountTwo, updatedAccounts.get(priorAccountTwo.Id));
    }

    @isTest
    public static void itShouldFailJobsWithInvalidAddresses() {
        // GIVEN we have a list of Accounts
        List<Account> priorAccounts = [
            SELECT
                FirstName,
                LastName,
                Emergency_Contact_First_Name__pc,
                (SELECT Auth0_Id__c FROM Hub_Accounts__r),
                (SELECT Street_1__c, Lookup_Country__r.country_code_2__c, Type__c FROM Addresses__r)
            FROM Account
        ];

        // AND the first Account has an Update defined without duplicate addresses
        Account priorAccountOne = priorAccounts[0];
        UserAccountUpdatedSchema schemaOne = createSchemaFromAccount(priorAccountOne);
        schemaOne.personalInfo.firstName = UPDATE_PREFIX + priorAccountOne.FirstName;

        // AND the second Account has an update defined containing a Street Value which is too long
        Account priorAccountTwo = priorAccounts[1];
        UserAccountUpdatedSchema schemaTwo = createSchemaFromAccount(priorAccountTwo);
        schemaTwo.personalInfo.firstName = UPDATE_PREFIX + priorAccountTwo.FirstName;
        schemaTwo.addresses[1].line1 = TestUtilities.generateValueOfFieldLength('Address__c', 'Street_1__c');

        // AND a Queue Job should exist for each of these updates
        List<Queue_Job__c> jobsToProcess = new List<Queue_Job__c>{
            createQueueJob(schemaOne),
            createQueueJob(schemaTwo)
        };
        insert jobsToProcess;

        // WHEN the event processor is run
        Test.startTest();

        EventUserAccountUpdatedProcessor processor = new EventUserAccountUpdatedProcessor();
        processor.processImpl(jobsToProcess);

        Test.stopTest();

        // THEN only one of the jobs should have been successful
        Assert.areEqual(1, processor.successfulJobs.size());
        Assert.areEqual(1, processor.failedJobs.size());

        // AND the error message on the second job should match what we expect
        Assert.isTrue(processor.failedJobs.values()[0].contains('Address Line 1: data value too large'));

        Map<Id, Account> updatedAccounts = new Map<Id, Account>(
            [
                SELECT
                    Id,
                    FirstName,
                    LastName,
                    Emergency_Contact_First_Name__pc,
                    (SELECT Auth0_Id__c FROM Hub_Accounts__r),
                    (SELECT Street_1__c, Lookup_Country__r.country_code_2__c, Type__c FROM Addresses__r)
                FROM Account
            ]
        );

        // AND only the Emergency Contacts First Name should have been updated for the first Account
        Account updatedAccountOne = updatedAccounts.get(priorAccountOne.Id);
        Assert.areEqual(schemaOne.personalInfo.firstName, updatedAccountOne.FirstName);
        Assert.areEqual(priorAccountOne.LastName, updatedAccountOne.LastName);

        // AND the Addresses against the first Account have been updated as expected
        for (Integer i = 0; i < priorAccountOne.Addresses__r.size(); i++) {
            UserAccountUpdatedSchema.Address schemaAddress = schemaOne.addresses[i];
            Address__c oldAddress = priorAccountOne.Addresses__r[i];
            Address__c newAddress = updatedAccountOne.Addresses__r[i];

            Assert.areEqual(oldAddress.Type__c, newAddress.Type__c);
            Assert.areEqual(
                oldAddress.Lookup_Country__r.country_code_2__c,
                newAddress.Lookup_Country__r.country_code_2__c
            );
            Assert.areEqual(schemaAddress.line1, newAddress.Street_1__c);
        }

        // AND nothing should have been updated on the second Account
        Assert.areEqual(priorAccountTwo, updatedAccounts.get(priorAccountTwo.Id));
    }

    @isTest
    public static void itShouldFailJobsWithInvalidPersonalDetails() {
        // GIVEN we have a list of Accounts
        List<Account> priorAccounts = [
            SELECT
                FirstName,
                LastName,
                Emergency_Contact_First_Name__pc,
                (SELECT Auth0_Id__c FROM Hub_Accounts__r),
                (SELECT Street_1__c, Lookup_Country__r.country_code_2__c, Type__c FROM Addresses__r)
            FROM Account
        ];

        // AND the first Account has an Update defined without duplicate addresses
        Account priorAccountOne = priorAccounts[0];
        UserAccountUpdatedSchema schemaOne = createSchemaFromAccount(priorAccountOne);
        schemaOne.personalInfo.firstName = UPDATE_PREFIX + priorAccountOne.FirstName;

        // AND the second Account has an update defined containing a Last Name Value which is too long
        Account priorAccountTwo = priorAccounts[1];
        UserAccountUpdatedSchema schemaTwo = createSchemaFromAccount(priorAccountTwo);
        schemaTwo.personalInfo.firstName = UPDATE_PREFIX + priorAccountTwo.FirstName;
        schemaTwo.personalInfo.lastName = TestUtilities.generateValueOfFieldLength('Contact', 'LastName');

        // AND a Queue Job should exist for each of these updates
        List<Queue_Job__c> jobsToProcess = new List<Queue_Job__c>{
            createQueueJob(schemaOne),
            createQueueJob(schemaTwo)
        };
        insert jobsToProcess;

        // WHEN the event processor is run
        Test.startTest();

        EventUserAccountUpdatedProcessor processor = new EventUserAccountUpdatedProcessor();
        processor.processImpl(jobsToProcess);

        Test.stopTest();

        // THEN only one of the jobs should have been successful
        Assert.areEqual(1, processor.successfulJobs.size());
        Assert.areEqual(1, processor.failedJobs.size());

        // AND the error message on the second job should match what we expect
        Assert.isTrue(processor.failedJobs.values()[0].contains('Last Name: data value too large'));

        Map<Id, Account> updatedAccounts = new Map<Id, Account>(
            [
                SELECT
                    Id,
                    FirstName,
                    LastName,
                    Emergency_Contact_First_Name__pc,
                    (SELECT Auth0_Id__c FROM Hub_Accounts__r),
                    (SELECT Street_1__c, Lookup_Country__r.country_code_2__c, Type__c FROM Addresses__r)
                FROM Account
            ]
        );

        // AND only the Emergency Contacts First Name should have been updated for the first Account
        Account updatedAccountOne = updatedAccounts.get(priorAccountOne.Id);
        Assert.areEqual(schemaOne.personalInfo.firstName, updatedAccountOne.FirstName);
        Assert.areEqual(priorAccountOne.LastName, updatedAccountOne.LastName);
        Assert.areEqual(schemaOne.emergencyContact.firstName, updatedAccountOne.Emergency_Contact_First_Name__pc);

        // AND the Addresses against the first Account have been updated as expected
        for (Integer i = 0; i < priorAccountOne.Addresses__r.size(); i++) {
            UserAccountUpdatedSchema.Address schemaAddress = schemaOne.addresses[i];
            Address__c oldAddress = priorAccountOne.Addresses__r[i];
            Address__c newAddress = updatedAccountOne.Addresses__r[i];

            Assert.areEqual(oldAddress.Type__c, newAddress.Type__c);
            Assert.areEqual(
                oldAddress.Lookup_Country__r.country_code_2__c,
                newAddress.Lookup_Country__r.country_code_2__c
            );
            Assert.areEqual(schemaAddress.line1, newAddress.Street_1__c);
        }

        // AND nothing should have been updated on the second Account
        Assert.areEqual(priorAccountTwo, updatedAccounts.get(priorAccountTwo.Id));
    }

    /**
     * Creates a Queue Job with the details required to process a User Account Updated event
     * @param  UserAccountUpdatedSchema Schemas to be serialized and included in the Queue Job
     * @return The resulting Queue Job
     */
    private static Queue_Job__c createQueueJob(UserAccountUpdatedSchema UserAccountUpdatedSchema) {
        return new Queue_Job__c(
            Status__c = 'Processing',
            Channel__c = 'Event',
            Job_Type__c = 'UserAccountUpdated',
            Failure_Count__c = 0,
            Job_Content__c = JSON.serialize(UserAccountUpdatedSchema)
        );
    }

    /**
     * Generates a User Account Updated Schema based off of an Account to avoid duplicating Schema creation throughout tests
     * @param  account Accounts to generate Schemas off of
     * @return The resulting schema
     */
    private static UserAccountUpdatedSchema createSchemaFromAccount(Account account) {
        UserAccountUpdatedSchema schemaToReturn = new UserAccountUpdatedSchema();
        schemaToReturn.personalInfo.firstName = account.FirstName;
        schemaToReturn.personalInfo.lastName = account.LastName;
        schemaToReturn.emergencyContact.firstName = account.Emergency_Contact_First_Name__pc;

        if (account.Addresses__r != null) {
            for (Address__c currentAddress : account.Addresses__r) {
                UserAccountUpdatedSchema.Address addressToAdd = new UserAccountUpdatedSchema.Address();
                addressToAdd.country = currentAddress.Lookup_Country__r.country_code_2__c;
                addressToAdd.type = currentAddress.Type__c;
                addressToAdd.line1 = currentAddress.Street_1__c;
                schemaToReturn.addresses.add(addressToAdd);
            }
        }

        for (Hub_Account__c currentHubAccount : account.Hub_Accounts__r) {
            schemaToReturn.userIds.add(currentHubAccount.Auth0_Id__c);
        }

        return schemaToReturn;
    }
}
