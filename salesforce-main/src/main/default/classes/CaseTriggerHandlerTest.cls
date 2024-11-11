@isTest
public class CaseTriggerHandlerTest {
    @TestSetup
    private static void setup() {
        Id studentAccount = Schema.SObjectType.Account.getRecordTypeInfosByName()
            .get('Student Account')
            .getRecordTypeId();

        Id apprenticeOnboarding = Schema.Sobjecttype.Case.getRecordTypeInfosByName()
            .get('Apprentice Onboarding')
            .getRecordTypeId();

        Id apprenticeApplication = Schema.SObjectType.Opportunity.getRecordTypeInfosByName()
            .get('Apprentice Application')
            .getRecordTypeId();

        insert new List<Case>{
            new Case(
                Subject = 'Test Case',
                RecordTypeId = apprenticeOnboarding,
                Query_Type__c = 'General Query',
                Origin = 'Email',
                Status = 'New'
            )
        };

        List<Account> accounts = new List<Account>{
            new Account(FirstName = 'Test', LastName = 'Test', RecordTypeId = studentAccount),
            new Account(FirstName = 'Test2', LastName = 'Test2', RecordTypeId = studentAccount)
        };

        insert accounts;

        insert new List<Opportunity>{
            new Opportunity(
                RecordTypeId = apprenticeApplication,
                AccountId = accounts[0].Id,
                Name = 'Test Opportunity1',
                StageName = 'Application',
                Application_Id__c = 'test-1234',
                CloseDate = Date.today() + 30
            ),
            new Opportunity(
                RecordTypeId = apprenticeApplication,
                AccountId = accounts[1].Id,
                Name = 'Test Opportunity2',
                StageName = 'Application',
                Application_Id__c = 'test-4321',
                CloseDate = Date.today() + 30
            ),
            new Opportunity(
                RecordTypeId = apprenticeApplication,
                AccountId = accounts[1].Id,
                Name = 'Test Opportunity3',
                StageName = 'Application',
                Application_Id__c = 'test-4444',
                CloseDate = Date.today() + 30
            )
        };
    }

    static testMethod void testSendStatusHolidayLetter() {
        Test.startTest();
        country_list__c cntry = CreateTestData.createCountry1();

        Account a1 = CreateTestData.createAccount1(cntry);
        a1.BNR_Banner_ID__pc = 'BP1234567';
        update a1;

        Id conId = [SELECT Id, name, PersonContactId FROM Account WHERE Id = :a1.Id].PersonContactId;

        State_Province__c stt = CreateTestData.createStateProvince();
        Locality__c lct = CreateTestData.createLocality();
        Contact tmC = CreateTestData.createTMContact();
        Address__c addr = CreateTestData.createAddress(a1, null, tmC, cntry, stt, lct, true, 'Mailing');
        try {
            addr = CreateTestData.createAddress(a1, null, tmC, cntry, stt, lct, false, 'Home');
        } catch (Exception e) {
        }

        Programme__c prgrm = CreateTestData.createProgram();
        Product2 prd = CreateTestData.createProduct(prgrm, 'OFFERING');

        Opportunity opp1 = new Opportunity();
        opp1.AccountId = a1.id;
        opp1.Name = 'test';
        opp1.StageName = 'Accepted - Conditional Firm';
        opp1.Enrolment_Status__c = 'Acceptance';
        opp1.Cycle_Override__c = 'Use Student Cycle';
        opp1.CloseDate = Date.valueOf('2015-02-27');
        opp1.BNR_Application_Decision_Comment__c = 'ABCD';
        opp1.SFDC_Attribute_Code_Select__c = 'FT~ Full Time Student';
        opp1.SFDC_Admissions_ADMT_Code_Select__c = 'DI~ Direct';
        opp1.SFDC_Admissions_STYPE_Code_Select__c = 'R~ Returning';
        opp1.SFDC_Admissions_RESD_Code_Select__c = 'E~ EU National';
        opp1.SFDC_Cohort_Code_Select__c = 'C6~ Cohort June';
        opp1.BNR_Curriculum_Status_Code__c = 'REGISTERED';
        opp1.Course_Instance__c = prd.Id;
        opp1.Programme_Application__c = prgrm.Id;
        insert opp1;

        Case cse = new Case();
        cse.RecordTypeId = Schema.sObjectType.Case.getRecordTypeInfosByName().get('Student Query').getRecordTypeId();
        cse.Query_Type__c = 'Letter requests';
        cse.Query_Subtype__c = 'I would like to request a Bank, Status or Council Tax letter';
        cse.Origin = 'Web';
        cse.Status = 'New';
        cse.ContactId = conId;
        cse.Study_Location__c = 'Doncaster';
        cse.School__c = 'Business';
        cse.SuppliedEmail = 'john@john.com';
        cse.Student_ID_Number__c = 'BP1234567';
        insert cse;
        Test.stopTest();
    }

    @isTest
    private static void doNotUpdateApprenticeOnboardingCasesForMultipleOpportunities() {
        //GIVEN an Apprentice Onboarding Case
        Case caseObj = [
            SELECT AccountId
            FROM Case
            WHERE Subject = 'Test Case'
        ];
        //AND a Student with only one valid Opportunity against it
        Account acc = [SELECT Id, FirstName, LastName, RecordTypeId FROM Account WHERE LastName = 'Test2'];

        //WHEN the Case has been updated to relate to the Student Account
        System.Test.startTest();

        caseObj.AccountId = acc.Id;
        update caseObj;

        System.Test.stopTest();
        //THEN I expect the Opportunity field on the Case to be updated to the existing Opportunity
        Case caseOut = [
            SELECT Opportunity__c
            FROM Case
            WHERE Id = :caseObj.Id
        ];

        Assert.areEqual(caseOut.Opportunity__c, null);
    }

    @isTest
    private static void updateApprenticeOnboardingCasesForSingleOpportunity() {
        //GIVEN an Apprentice Onboarding Case
        Case caseObj = [
            SELECT AccountId
            FROM Case
            WHERE Subject = 'Test Case'
        ];

        //AND a Student with only one valid Opportunity against it
        Account acc = [SELECT Id, FirstName, LastName, RecordTypeId FROM Account WHERE LastName = 'Test'];

        //WHEN the Case has been updated to relate to the Student Account
        System.Test.startTest();

        caseObj.AccountId = acc.Id;
        update caseObj;

        System.Test.stopTest();

        //THEN I expect the Opportunity field on the Case to be updated to the existing Opportunity
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Application_Id__c = 'test-1234'];

        Case caseOut = [
            SELECT Opportunity__c
            FROM Case
            WHERE Id = :caseObj.Id
        ];

        Assert.areEqual(caseOut.Opportunity__c, opp.Id);
    }
}
