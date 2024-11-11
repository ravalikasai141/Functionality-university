@isTest
private class StudentCoursesOppBatchTest {
    @TestSetup
    private static void setup() {
        Id accountRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName()
            .get('Student Account')
            .getRecordTypeId();

        Account account = new Account(FirstName = 'Test', LastName = 'Test', RecordTypeId = accountRecordTypeId);
        insert account;

        Programme__c programme = new Programme__c(Name = 'Test programme');
        insert programme;

        Product2 product = new Product2(
            Name = 'Test Course',
            Programme__c = programme.Id,
            BPP_ProductFactoryID__c = 'test-123',
            Instance_Id__c = 'test-1234',
            Location__c = 'London',
            Start_Date__c = Date.today()
        );
        insert product;

        Id applicationRtId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName()
            .get('Student_Application')
            .getRecordTypeId();

        insert new Opportunity(
            RecordTypeId = applicationRtId,
            AccountId = account.Id,
            Name = 'Test Opportunity',
            StageName = 'Accepted - Pmt Received',
            CloseDate = Date.today() + 30,
            Application_Id__c = 'test-32874',
            Course_Instance__c = product.Id,
            Enrolment_Status__c = 'Acceptance'
        );
    }

    @isTest
    private static void itShouldCreateStudentCourses() {
        // GIVEN an opportunity
        delete [SELECT Id FROM Student_Course__c];
        // WHEN the batch runs
        System.Test.startTest();

        Database.executeBatch(new StudentCoursesOppBatch());

        System.Test.stopTest();

        // THEN I expect it to create a student course
        Account account = [SELECT Id FROM Account LIMIT 1];
        Student_Course__c course = [SELECT Instance_Id__c FROM Student_Course__c WHERE Student__c = :account.Id];

        Assert.areEqual('test-1234', course.Instance_Id__c);
    }

    @isTest
    private static void itShouldNotCreateStudentCourseWhenTheyExist() {
        // GIVEN an opportunity
        // AND a student course already exists - satisfied by trigger
        // WHEN the batch runs
        System.Test.startTest();

        Database.executeBatch(new StudentCoursesOppBatch());

        System.Test.stopTest();

        // THEN I expect it to skip creating a student course
        Account account = [SELECT Id FROM Account LIMIT 1];
        List<Student_Course__c> courses = [SELECT Id FROM Student_Course__c WHERE Student__c = :account.Id];

        Assert.areEqual(1, courses.size());
    }
}
