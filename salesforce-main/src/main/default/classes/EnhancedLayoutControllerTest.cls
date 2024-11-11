@isTest
public class EnhancedLayoutControllerTest {
    @TestSetup
    static void setup() {
        insert new Account(FirstName = 'TestFN', LastName = 'TestLN');
    }

    @isTest
    static void itShouldRetrieveFieldDetails() {
        // GIVEN some Enhanced Layout Field metadata records exist
        EnhancedLayoutController.fieldConfig = new Map<String, List<EnhancedLayoutController.LayoutField>>{
            'TestSection' => new List<EnhancedLayoutController.LayoutField>{
                new EnhancedLayoutController.LayoutField('Account', 'Account.FirstName'),
                new EnhancedLayoutController.LayoutField('Account', 'Account.LastName')
            }
        };

        // AND an Opportunity
        Account account = [SELECT id, FirstName, LastName FROM Account LIMIT 1];

        Opportunity testOpportunity = new Opportunity(
            name = 'Test',
            Application_Id__c = '1',
            accountId = account.Id,
            StageName = 'Application',
            CloseDate = Date.today(),
            Application_Reference__c = '1'
        );
        insert testOpportunity;

        // WHEN I call the method to retrieve the field details
        Test.startTest();

        EnhancedLayoutController.EnhancedLayoutDetails testResults = EnhancedLayoutController.retrieveFieldDetails(
            'TestSection',
            testOpportunity.Id
        );

        Test.stopTest();

        List<SObject> queryResults = (List<SObject>) JSON.deserialize(
            testResults.queryResultsString,
            List<SObject>.class
        );

        // THEN it should have returned two fields
        Assert.areEqual(2, testResults.fields.size());
        Assert.areEqual('First Name', testResults.fields[0].label);
        Assert.areEqual('Last Name', testResults.fields[1].label);

        SObject accountObject = queryResults[0].getSObject('Account');
        Assert.areEqual(account.FirstName, accountObject.get('FirstName'));
        Assert.areEqual(account.LastName, accountObject.get('LastName'));
    }

    @isTest
    static void itShouldHandleInvalidFieldDetails() {
        // GIVEN some Enhanced Layout Field metadata records exist, two with invalid data and one with valid data
        EnhancedLayoutController.fieldConfig = new Map<String, List<EnhancedLayoutController.LayoutField>>{
            'TestSection' => new List<EnhancedLayoutController.LayoutField>{
                new EnhancedLayoutController.LayoutField('Account', 'Account.FakeField'),
                new EnhancedLayoutController.LayoutField('FakeObject', 'FakeObject.FakeField'),
                new EnhancedLayoutController.LayoutField('Opportunity', 'Name')
            }
        };

        // AND an Opportunity
        Account account = [SELECT id, FirstName, LastName FROM Account LIMIT 1];

        Opportunity testOpportunity = new Opportunity(
            name = 'Test',
            Application_Id__c = '1',
            accountId = account.Id,
            StageName = 'Application',
            CloseDate = Date.today(),
            Application_Reference__c = '1'
        );
        insert testOpportunity;

        // WHEN I call the method to retrieve the field details
        Test.startTest();

        EnhancedLayoutController.EnhancedLayoutDetails testResults = EnhancedLayoutController.retrieveFieldDetails(
            'TestSection',
            testOpportunity.Id
        );

        Test.stopTest();

        List<SObject> queryResults = (List<SObject>) JSON.deserialize(
            testResults.queryResultsString,
            List<SObject>.class
        );

        // THEN it should have returned three fields, two with error messages and one with data
        Assert.areEqual(3, testResults.fields.size());
        Assert.areEqual('Field does not exist.', testResults.fields[0].errorMessage);
        Assert.areEqual('SObject Provided does not exist.', testResults.fields[1].errorMessage);
        Assert.areEqual('Name', testResults.fields[2].label);

        // AND the data retrieved should be correct
        Assert.areEqual(testOpportunity.Name, queryResults[0].get('Name'));
    }

    @isTest
    static void itShouldRetrieveUniqueFieldDetails() {
        // GIVEN some Enhanced Layout Field metadata records exist, one a lookup and another a picklist
        EnhancedLayoutController.fieldConfig = new Map<String, List<EnhancedLayoutController.LayoutField>>{
            'TestSection' => new List<EnhancedLayoutController.LayoutField>{
                new EnhancedLayoutController.LayoutField('Opportunity', 'AccountId'),
                new EnhancedLayoutController.LayoutField('Opportunity', 'StageName')
            }
        };

        // AND an Opportunity
        Account account = [SELECT id, Name FROM Account LIMIT 1];

        Opportunity testOpportunity = new Opportunity(
            name = 'Test',
            Application_Id__c = '1',
            accountId = account.Id,
            StageName = 'Application',
            CloseDate = Date.today(),
            Application_Reference__c = '1'
        );
        insert testOpportunity;

        // WHEN I call the method to retrieve the field details
        Test.startTest();

        EnhancedLayoutController.EnhancedLayoutDetails testResults = EnhancedLayoutController.retrieveFieldDetails(
            'TestSection',
            testOpportunity.Id
        );

        Test.stopTest();

        List<SObject> queryResults = (List<SObject>) JSON.deserialize(
            testResults.queryResultsString,
            List<SObject>.class
        );

        // THEN it should have returned two fields
        Assert.areEqual(2, testResults.fields.size());
        Assert.isTrue(testResults.fields[0].label.contains('Account'), 'First field label contains "Account"');
        Assert.areEqual('Status', testResults.fields[1].label);

        // AND the picklist values should have been populated
        Assert.isFalse(testResults.fields[1].picklistValuesToLabels.isEmpty());

        // AND the query should have returned both the Id and the Name of the lookup
        Assert.areEqual(account.Id, queryResults[0].get('AccountId'));
        SObject accountObject = queryResults[0].getSObject('Account');
        Assert.areEqual(account.Name, accountObject.get('Name'));
    }
}
