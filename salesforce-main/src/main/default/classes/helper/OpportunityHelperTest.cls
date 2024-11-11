@isTest
private class OpportunityHelperTest {
    private static final String TEST_APPLICATION_ID = 'cd6a04b6-9990-4e30-8421-5ed7819c13c9';

    private static final Id ACCOUNT_RECORD_TYPE_ID = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
        .get('Student_Account')
        .getRecordTypeId();

    private static final Id OPPORTUNITY_STUDENT_INTEREST_RECORD_TYPE_ID = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName()
        .get('Student_Interest')
        .getRecordTypeId();

    @TestSetup
    static void setup() {
        AssignmentUsers__c assignmentUser = new AssignmentUsers__c(Default_Admissions_Owner__c = UserInfo.getUserId().left(15));
        insert assignmentUser;

        User admissionsUser = [SELECT Id FROM User WHERE UserRole.Name = 'Domestic Team [+Record Assignment]' AND IsActive = true ORDER BY Name LIMIT 1];
        List<Owner_Assignment__c> ownerAssignmentList = new List<Owner_Assignment__c>{
            new Owner_Assignment__c(Name = 'Domestic Team [+Record Assignment]', Last_Assignee__c = admissionsUser.Id)
        };
        insert ownerAssignmentList;

        Account testAccount = new Account(FirstName = 'Test', LastName = 'Test', RecordTypeId = ACCOUNT_RECORD_TYPE_ID);
        insert testAccount;

        Opportunity testOpportunity = new Opportunity(
            Name = 'Test-Opp',
            Application_Id__c = TEST_APPLICATION_ID,
            AccountId = testAccount.Id,
            StageName = 'Application Started',
            RecordTypeId = OPPORTUNITY_STUDENT_INTEREST_RECORD_TYPE_ID,
            CloseDate = Date.today()
        );
        insert testOpportunity;
    }

    @isTest
    static void itShouldGetAdmissionsOwner() {
        // GIVEN
        Opportunity testOpportunity = [SELECT Id, AccountId FROM Opportunity WHERE Application_Id__c = :TEST_APPLICATION_ID LIMIT 1];
        Test.setCreatedDate(testOpportunity.Id, Date.today().addMonths(-4));

        Map<String, Id> testOpportunityOwnerMap = new Map<String, Id>();
        testOpportunityOwnerMap.put(testOpportunity.AccountId, AssignmentUsers__c.getInstance().Default_Admissions_Owner__c);

        // WHEN
        Map<String, Id> resultOpportunityOwnerMap = OpportunityHelper.getOpportunityOwner(new List<String>{testOpportunity.AccountId});

        // THEN
        System.assertEquals(testOpportunityOwnerMap, resultOpportunityOwnerMap);
    }

    @isTest
    static void itShouldGetOpportunityOwner() {
        // GIVEN
        Opportunity testOpportunity = [SELECT OwnerId, AccountId FROM Opportunity WHERE Application_Id__c = :TEST_APPLICATION_ID LIMIT 1];

        Map<String, Id> testOpportunityOwnerMap = new Map<String, Id>();
        testOpportunityOwnerMap.put(testOpportunity.AccountId, testOpportunity.OwnerId);

        // WHEN
        Map<String, Id> resultOpportunityOwnerMap = OpportunityHelper.getOpportunityOwner(new List<String>{testOpportunity.AccountId});

        // THEN
        System.assertEquals(testOpportunityOwnerMap, resultOpportunityOwnerMap);
    }
}
