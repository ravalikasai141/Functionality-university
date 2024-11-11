/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * All test methods in an org are executed whenever Apex code is deployed
 * to a production org to confirm correctness, ensure code
 * coverage, and prevent regressions. All Apex classes are
 * required to have at least 75% code coverage in order to be deployed
 * to a production org. In addition, all triggers must have some code coverage.
 *
 * The @isTest class annotation indicates this class only contains test
 * methods. Classes defined with the @isTest annotation do not count against
 * the org size limit for all Apex scripts.
 *
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 */
@isTest
private class EventCaseProcessorTest {
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
            )
        };
        insert accountsToInsert;

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
            )
        };
        insert hubAccountsToInsert;

        Product2 product = new Product2(
            Name = 'Test Course',
            BNR_Program_Code__c = 'test-123',
            Instance_Id__c = 'test-123'
        );

        insert product;
    }

    @isTest
    public static void itShouldFailJobsWithMissingAuth0Id() {
        // GIVEN we have a list of Accounts
        List<Account> priorAccounts = [
            SELECT id, (SELECT Auth0_Id__c FROM Hub_Accounts__r)
            FROM Account
        ];

        // AND the first Account has a valid Update defined
        Account priorAccountOne = priorAccounts[0];
        CaseSchema schemaOne = createSchemaFromAccount(priorAccountOne);

        // AND the second Account has an update defined containing a missing auth0Id
        Account priorAccountTwo = priorAccounts[1];
        CaseSchema schemaTwo = createSchemaFromAccount(priorAccountTwo);
        schemaTwo.auth0Id = 'MissingAuth0Id';

        // AND a Queue Job should exist for each of these updates
        List<Queue_Job__c> jobsToProcess = new List<Queue_Job__c>{
            createQueueJob(schemaOne),
            createQueueJob(schemaTwo)
        };
        insert jobsToProcess;

        // WHEN the event processor is run
        Test.startTest();

        EventCaseProcessor processor = new EventCaseProcessor();
        processor.processImpl(jobsToProcess);

        Test.stopTest();

        // THEN only one of the jobs should have been successful
        Assert.areEqual(1, processor.successfulJobs.size(), 'Expected one successful jobs');
        Assert.areEqual(1, processor.failedJobs.size(), 'Expected one failed jobs');

        // AND the error message on the second job should match what we expect
        Assert.areEqual(EventCaseProcessor.AUTH0_ID_ERROR, processor.failedJobs.values()[0], 'Expected error message');
    }

    @isTest
    public static void itShouldFailJobsWithMissingRequiredFieldErrors() {
        // GIVEN we have a list of Accounts
        List<Account> priorAccounts = [
            SELECT id, (SELECT Auth0_Id__c FROM Hub_Accounts__r)
            FROM Account
        ];

        // AND the first Account has a valid Update defined
        Account priorAccountOne = priorAccounts[0];
        CaseSchema schemaOne = createSchemaFromAccount(priorAccountOne);
        schemaOne.auth0Id = priorAccountOne.Hub_Accounts__r[0].Auth0_Id__c;

        // AND the second Account has an update defined containing a auth0Id linking to the first Account
        Account priorAccountTwo = priorAccounts[1];
        CaseSchema schemaTwo = createSchemaFromAccount(priorAccountTwo);
        schemaTwo.auth0Id = priorAccountOne.Hub_Accounts__r[1].Auth0_Id__c;
        schemaTwo.queryType = '';
        schemaTwo.subQueryType = '';

        // AND a Queue Job should exist for each of these updates
        List<Queue_Job__c> jobsToProcess = new List<Queue_Job__c>{
            createQueueJob(schemaOne),
            createQueueJob(schemaTwo)
        };
        insert jobsToProcess;

        // WHEN the event processor is run
        Test.startTest();

        EventCaseProcessor processor = new EventCaseProcessor();
        processor.processImpl(jobsToProcess);

        Test.stopTest();

        // THEN only one of the jobs should have been successful
        Assert.areEqual(1, processor.successfulJobs.size(), 'Expected one successful jobs');
        Assert.areEqual(1, processor.failedJobs.size(), 'Expected one failed jobs');

        // AND the error message on the second job should match what we expect
        Assert.areEqual(
            'Required value(s) Query Type, Query Subtype are null in event payload',
            processor.failedJobs.values()[0],
            'Expected missing required message'
        );
    }

    @isTest
    public static void itShouldFailJobsWithDuplicate() {
        // GIVEN we have a list of Accounts
        List<Account> priorAccounts = [
            SELECT id, (SELECT Auth0_Id__c FROM Hub_Accounts__r)
            FROM Account
        ];

        // AND the first Account has a valid Update defined
        Account priorAccountOne = priorAccounts[0];
        CaseSchema schemaOne = createSchemaFromAccount(priorAccountOne);
        schemaOne.auth0Id = priorAccountOne.Hub_Accounts__r[0].Auth0_Id__c;

        // AND the second Account has an update defined containing a auth0Id linking to the first Account
        Account priorAccountTwo = priorAccounts[0];
        CaseSchema schemaTwo = createSchemaFromAccount(priorAccountTwo);
        schemaTwo.auth0Id = priorAccountOne.Hub_Accounts__r[0].Auth0_Id__c;

        Queue_Job__c queueJobOne = createQueueJob(schemaOne);
        queueJobOne.Event_Time__c = DateTime.now().addDays(2);

        Queue_Job__c queueJobTwo = createQueueJob(schemaTwo);
        queueJobTwo.Event_Time__c = DateTime.now();

        // AND a Queue Job should exist for each of these updates
        List<Queue_Job__c> jobsToProcess = new List<Queue_Job__c>{ queueJobOne, queueJobTwo };
        insert jobsToProcess;

        // WHEN the event processor is run
        Test.startTest();

        EventCaseProcessor processor = new EventCaseProcessor();
        processor.processImpl(jobsToProcess);

        Test.stopTest();

        // THEN only one of the jobs should have been successful
        Assert.areEqual(2, processor.successfulJobs.size(), 'Expected two successful jobs');
    }

    /**
     * Creates a Queue Job with the details required to process a Case event
     * @param  CaseSchema Schemas to be serialized and included in the Queue Job
     * @return The resulting Queue Job
     */
    private static Queue_Job__c createQueueJob(CaseSchema caseSchema) {
        return new Queue_Job__c(
            Status__c = 'Processing',
            Channel__c = 'Event',
            Job_Type__c = 'queryFormSubmitted',
            Failure_Count__c = 0,
            Job_Content__c = JSON.serialize(CaseSchema),
            Event_Time__c = Datetime.now()
        );
    }

    /**
     * Generates a Case Schema based off of an Account to avoid duplicating Schema creation throughout tests
     * @param  account Accounts to generate Schemas off of
     * @return The resulting schema
     */
    private static CaseSchema createSchemaFromAccount(Account account) {
        CaseSchema schemaToReturn = new CaseSchema();
        for (Hub_Account__c currentHubAccount : account.Hub_Accounts__r) {
            schemaToReturn.auth0Id = currentHubAccount.Auth0_Id__c;
        }
        schemaToReturn.school = 'Business';
        schemaToReturn.productId = 'test-123';
        schemaToReturn.instanceId = 'test-123';
        schemaToReturn.queryType = 'Letter requests';
        schemaToReturn.subQueryType = 'I would like to request a Bank, Status or Council Tax letter';
        schemaToReturn.queryDescription = 'Letter requests - I would like to request a Bank, Status or Council Tax letter - University Student Support';
        schemaToReturn.queryId = '1f967657-0e64-46d5-0047-88b6xxcxcxfc31231ZZHH';

        return schemaToReturn;
    }
}
