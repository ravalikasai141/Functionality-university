@isTest
private class ApplicationReviewControllerTest {
    private static Id accountRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
        .get('Student_Account')
        .getRecordTypeId();

    private static Id opportunityRecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName()
        .get('Apprentice_Application')
        .getRecordTypeId();

    @TestSetup
    static void setup() {
        Account acc = new Account(FirstName = 'Test', LastName = 'Test', RecordTypeId = accountRecordTypeId);
        insert acc;

        Account client = new Account(Name = 'Acme Inc');
        insert client;

        Country_List__c country = new country_list__c(
            Name = 'United Kingdom',
            country_code_2__c = 'GB',
            Valid_Nationality__c = true
        );
        insert country;

        Address__c address = new Address__c(
            Street_1__c = 'Street0',
            Student__c = acc.Id,
            Lookup_Country__c = country.Id,
            Type__c = 'Home'
        );

        insert address;

        Opportunity opp = new Opportunity(
            RecordTypeId = opportunityRecordTypeId,
            name = 'Test',
            Application_Id__c = 'test-1234',
            accountid = acc.Id,
            StageName = 'Application',
            CloseDate = Date.today(),
            Client__c = client.Id
        );

        insert opp;

        opp.Bypass_Validation_Rule__c = true;
        opp.StageName = 'BPP Review';
        update opp;
    }

    @isTest
    private static void itShouldBeAbleToStartAFinalReview() {
        // GIVEN we have an opportunity in the acceptance stage
        Opportunity opp = [SELECT StageName, BPP_Sub_Status__c FROM Opportunity WHERE Application_ID__c = 'test-1234'];

        opp.StageName = 'Acceptance';
        opp.StageName = 'New';

        update opp;

        // WHEN we call the startFinalReview method
        ApplicationReviewController.startFinalReview(opp.Id);

        // THEN I expect the sub status to be updated
        Opportunity out = [SELECT BPP_Sub_Status__c FROM Opportunity WHERE Id = :opp.Id];

        Assert.areEqual('In Progress', out.BPP_Sub_Status__c);
    }

    @isTest
    private static void itShouldBeAbleToStartAReview() {
        // GIVEN we have an opportunity that is at BPP Review
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Application_Id__c = 'test-1234'];
        // WHEN we call the start review method
        ApplicationReviewController.startReview(opp.Id);
        // THEN I expect the sub status to update
        Opportunity out = [SELECT BPP_Sub_Status__c FROM Opportunity WHERE Id = :opp.Id];

        Assert.areEqual('In Progress', out.BPP_Sub_Status__c);
    }

    @isTest
    private static void itShouldReturnHomeAddress() {
        // GIVEN we have an account with a home address
        Account account = [SELECT Id FROM Account WHERE LastName = 'Test'];
        Address__c address = [SELECT Id FROM Address__c WHERE Student__c = :account.Id AND Type__c = 'Home'];
        // WHEN we call the getHomeAddress method
        Id addressId = ApplicationReviewController.getHomeAddress(account.Id);
        // THEN I expect it to return an address id
        Assert.areEqual(address.Id, addressId);
    }

    @isTest
    private static void itShouldBeAbleToSubmitAReview() {
        // GIVEN we have an application ready for review
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Application_Id__c = 'test-1234'];
        // WHEN we call the submit review method
        System.Test.startTest();

        ApplicationReviewController.submitReview(opp.Id, 'Test Comment', true);

        System.Test.stopTest();
        // THEN I expect it to create an Application Review
        Application_Review__c review = [SELECT Comment__c FROM Application_Review__c WHERE Application__c = :opp.Id];

        Assert.areEqual('Test Comment', review.Comment__c);
        // AND I expect it to update the application
        Opportunity out = [SELECT BPP_Sub_Status__c FROM Opportunity WHERE Id = :opp.Id];

        Assert.areEqual('Awaiting Information', out.BPP_Sub_Status__c);
    }

    @isTest
    private static void itShouldThrowAnExceptionWhenLineManagerIsMissing() {
        // GIVEN we have an application ready for review
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Application_Id__c = 'test-1234'];
        // AND the Application is missing Line Manager
        opp.Line_Manager__c = null;
        update opp;

        // WHEN we call the submit review method
        Boolean exceptionThrown = false;

        System.Test.startTest();

        try {
            ApplicationReviewController.submitReview(opp.Id, 'Test Comment', false);
        } catch (AuraHandledException e) {
            exceptionThrown = true;
        }

        System.Test.stopTest();

        // THEN i expect it to throw an exception
        Assert.isTrue(exceptionThrown);
    }

    @isTest
    private static void itShouldBeAbleToSubmitAFinalReview() {
        // GIVEN we have an application ready for a final review
        Opportunity opp = [
            SELECT Id, StageName, BPP_Sub_Status__c
            FROM Opportunity
            WHERE Application_Id__c = 'test-1234'
        ];
        opp.StageName = 'Acceptance';
        opp.BPP_Sub_Status__c = 'New';
        update opp;

        // WHEN we call the submit review method
        System.Test.startTest();

        ApplicationReviewController.submitFinalReview(opp.Id, 'Test Comment', false);

        System.Test.stopTest();

        // THEN I expect it to create an Application Review
        Application_Review__c review = [
            SELECT Feedback_Required__c, Comment__c
            FROM Application_Review__c
            WHERE Application__c = :opp.Id
        ];

        Assert.isFalse(review.Feedback_Required__c);
        Assert.areEqual('Test Comment', review.Comment__c);

        // AND I expect it to update the application
        Opportunity out = [
            SELECT BPP_Sub_Status__c, Authoriser__c, AuthorisedOn__c
            FROM Opportunity
            WHERE Id = :opp.Id
        ];

        Assert.areEqual('Completed', out.BPP_Sub_Status__c);
        Assert.isNotNull(out.Authoriser__c);
        Assert.isNotNull(out.AuthorisedOn__c);
    }

    @isTest
    private static void itShouldBeAbleToPauseAFinalReview() {
        // GIVEN we have an application ready for a final review
        Opportunity opp = [
            SELECT Id, StageName, BPP_Sub_Status__c
            FROM Opportunity
            WHERE Application_Id__c = 'test-1234'
        ];

        opp.StageName = 'Acceptance';
        opp.BPP_Sub_Status__c = 'In Progress';
        update opp;

        // WHEN we call the submit review method
        System.Test.startTest();

        ApplicationReviewController.submitFinalReview(opp.Id, 'This Application Is On Hold', true);

        System.Test.stopTest();

        // THEN I expect it to create an Application Review
        Application_Review__c review = [
            SELECT Feedback_Required__c, Comment__c
            FROM Application_Review__c
            WHERE Application__c = :opp.Id
        ];

        Assert.isFalse(review.Feedback_Required__c);
        Assert.areEqual('This Application Is On Hold', review.Comment__c);

        // AND I expect it to update the application's status to On Hold
        Opportunity out = [
            SELECT BPP_Sub_Status__c
            FROM Opportunity
            WHERE Id = :opp.Id
        ];

        Assert.areEqual('On Hold', out.BPP_Sub_Status__c);
    }

    @isTest
    private static void itShouldBeAbleToAutoPopulateAReview() {
        // GIVEN we have an open review
        String priorLearning = 'none';

        // WHEN we call the auto populate review method
        String content = ApplicationReviewController.autoPopulateReview();

        // THEN I expect it to fetch the default template for reviews
        Assert.isNotNull(content);
    }

    @isTest
    private static void itShouldUpdateOpportunityDateFields() {
        // GIVEN we have an application
        Opportunity opp = [
            SELECT Id
            FROM Opportunity
            WHERE Application_Id__c = 'test-1234'
        ];

        // AND it is linked to a Product with a different Start and End Date
        Programme__c programme = new Programme__c(Name = 'Test1Programme', Programme_Id__c = 'test-123');
        insert programme;

        Product2 product = new Product2(
            Name = 'TestCourse',
            BPP_ProductFactoryID__c = 'test-123',
            Qualification__c = 'Test Qualification',
            Programme__c = programme.Id,
            Start_Date__c = Date.today().addDays(3),
            End_Date__c = Date.today().addDays(4)
        );
        insert product;

        TriggerHandler.bypass('AddressTriggerHandler');
        opp.StageName = 'Acceptance';
        opp.BPP_Sub_Status__c = 'In Progress';
        opp.Course_Instance__c = product.Id;
        opp.Start_Date__c = Date.today().addDays(1);
        opp.End_Date__c = Date.today().addDays(2);
        update opp;

        Opportunity oppResultsBeforeTest = [
            SELECT Id, Start_Date__c, End_Date__c
            FROM Opportunity
            WHERE Id = :opp.Id
        ];

        Assert.areNotEqual(product.Start_Date__c, oppResultsBeforeTest.Start_Date__c);
        Assert.areNotEqual(product.End_Date__c, oppResultsBeforeTest.End_Date__c);

        // WHEN we call the Opportunity update method
        System.Test.startTest();

        ApplicationReviewController.updateOpportunityProductDates(opp.Id);

        System.Test.stopTest();

        // THEN I expect the Opportunity to have had its Start and End Dates updated
        Opportunity oppResultsAfterTest = [
            SELECT Id, Start_Date__c, End_Date__c
            FROM Opportunity
            WHERE Id = :opp.Id
        ];

        Assert.areEqual(product.Start_Date__c, oppResultsAfterTest.Start_Date__c);
        Assert.areEqual(product.End_Date__c, oppResultsAfterTest.End_Date__c);
    }
}
