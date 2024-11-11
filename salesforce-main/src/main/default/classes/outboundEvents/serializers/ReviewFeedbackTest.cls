@isTest
private class ReviewFeedbackTest {
    private static Id accountRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
        .get('Student_Account')
        .getRecordTypeId();

    private static Id opportunityRecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName()
        .get('Apprentice_Application')
        .getRecordTypeId();

    @TestSetup
    private static void setUp() {
        Account acc = new Account(FirstName = 'Test', LastName = 'Test', RecordTypeId = accountRecordTypeId);
        insert acc;

        Opportunity opp = new Opportunity(
            RecordTypeId = opportunityRecordTypeId,
            name = 'Test',
            Application_Id__c = 'test-1234',
            accountid = acc.Id,
            StageName = 'Application',
            CloseDate = Date.today()
        );
        insert opp;

        opp.Bypass_Validation_Rule__c = true;
        opp.StageName = 'BPP Review';
        update opp;

        Application_Review__c review = new Application_Review__c(
            Application__c = opp.Id,
            Feedback_Required__c = true,
            Comment__c = 'Test comment'
        );

        insert review;
    }

    @isTest
    private static void itShouldSerializeFromAReview() {
        // GIVEN we have a valid review object
        Application_Review__c review = [SELECT Id FROM Application_Review__c];

        // WHEN added to the serializer and serialized
        ReviewFeedback serializer = new ReviewFeedback();
        serializer.addRecord(review);

        List<Map<String, Object>> output = serializer.serialize();
        // THEN I expect it to produce the correct event
        Assert.areEqual(1, output.size());

        String applicationId = (String) output.get(0).get('applicationId');
        Map<String, Object> feedback = (Map<String, Object>) output.get(0).get('applicantFeedback');

        Assert.areEqual('test-1234', applicationId);
        Assert.areEqual('Test comment', (String) feedback.get('updateRequiredDescription'));
    }
}
