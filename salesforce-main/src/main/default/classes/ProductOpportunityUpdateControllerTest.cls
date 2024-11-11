@isTest
public class ProductOpportunityUpdateControllerTest {
    @TestSetup
    static void setup() {
        Id apprenticeApplicationRTId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName()
            .get('Apprentice_Application')
            .getRecordTypeId();

        Date matchingStartDate = Date.newInstance(2023, 3, 5);
        Date matchingEndDate = Date.newInstance(2024, 6, 9);

        Account account = new Account(
            FirstName = 'Test',
            LastName = 'Test',
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
                .get('Student_Account')
                .getRecordTypeId()
        );
        insert account;

        Programme__c programme = new Programme__c(Name = 'Test1Programme', Programme_Id__c = 'test-123');
        insert programme;

        Product2 product = new Product2(
            Name = 'TestCourse',
            Start_Date__c = matchingStartDate,
            End_Date__c = matchingEndDate,
            BPP_ProductFactoryID__c = 'test-123',
            Qualification__c = 'Test Qualification',
            Product_Type__c = 'OFFERING',
            IsActive = true,
            Programme__c = programme.Id
        );
        insert product;

        List<Opportunity> oppsToInsert = new List<Opportunity>{
            new Opportunity(
                RecordTypeId = apprenticeApplicationRTId,
                AccountId = account.Id,
                Name = 'OppWithMatchingDate',
                StageName = 'Application',
                CloseDate = Date.today() + 30,
                Application_Id__c = 'test-1234',
                Course_Instance__c = product.Id,
                EPA__c = 1,
                Pricebook2Id = Test.getStandardPricebookId()
            ),
            new Opportunity(
                RecordTypeId = apprenticeApplicationRTId,
                AccountId = account.Id,
                Name = 'OppWithoutMatchingDate',
                StageName = 'Application',
                CloseDate = Date.today() + 30,
                Application_Id__c = 'test-1235',
                Course_Instance__c = product.Id,
                EPA__c = 2,
                Pricebook2Id = Test.getStandardPricebookId()
            ),
            new Opportunity(
                RecordTypeId = apprenticeApplicationRTId,
                AccountId = account.Id,
                Name = 'OlderApplicableOpportunity',
                StageName = 'Application',
                CloseDate = Date.today() + 30,
                Application_Id__c = 'test-1236',
                Course_Instance__c = product.Id,
                EPA__c = 3,
                Pricebook2Id = Test.getStandardPricebookId()
            ),
            new Opportunity(
                RecordTypeId = apprenticeApplicationRTId,
                AccountId = account.Id,
                Name = 'OppWithWrongStage',
                StageName = 'Application',
                CloseDate = Date.today() + 30,
                Application_Id__c = 'test-1237',
                Course_Instance__c = product.Id,
                EPA__c = 4,
                Pricebook2Id = Test.getStandardPricebookId()
            )
        };
        insert oppsToInsert;

        // Update all of the Opportunities so as to not have their Start/End Dates reset
        oppsToInsert[0].Start_Date__c = matchingStartDate;
        oppsToInsert[0].End_Date__c = matchingEndDate;
        oppsToInsert[0].OOTJTH_Preserved__c = 100;

        oppsToInsert[1].Start_Date__c = matchingStartDate;
        oppsToInsert[1].End_Date__c = Date.newInstance(2004, 11, 21);
        oppsToInsert[1].OOTJTH_Preserved__c = 200;

        oppsToInsert[2].Start_Date__c = matchingStartDate;
        oppsToInsert[2].End_Date__c = Date.newInstance(2003, 11, 21);
        oppsToInsert[2].OOTJTH_Preserved__c = 300;

        oppsToInsert[3].Start_Date__c = matchingStartDate;
        oppsToInsert[3].End_Date__c = Date.newInstance(2004, 11, 21);
        oppsToInsert[3].OOTJTH_Preserved__c = 400;
        oppsToInsert[3].StageName = 'Acceptance';
        update oppsToInsert;

        // Set one of the valid Opportunities for ordering
        Test.setCreatedDate(oppsToInsert[2].Id, Date.newInstance(1996, 11, 21));
    }

    @isTest
    static void itShouldReturnTheCorrectNumberOfOpportunities() {
        // GIVEN a Product
        Product2 product = [SELECT Id, Start_Date__c, End_Date__c FROM Product2 LIMIT 1];

        // WHEN I call the count method
        Test.startTest();

        Integer results = ProductOpportunityUpdateController.countOpportunitiesWithMismatchedDates(
            product.Id,
            product.Start_Date__c,
            product.End_Date__c
        );

        Test.stopTest();

        // THEN it should have found the two Opportunities with matching criteria
        Assert.areEqual(2, results);
    }

    @isTest
    static void itShouldUpdateALimitedAmountOfOpps() {
        // GIVEN a Product
        Product2 product = [SELECT Id, Start_Date__c, End_Date__c FROM Product2 LIMIT 1];
        Opportunity oppToUpdate = [
            SELECT Id, Start_Date__c, End_Date__c, EPA__c, OOTJTH_Calculated__c, OOTJTH_Preserved__c
            FROM Opportunity
            WHERE Application_Id__c = 'test-1236'
            LIMIT 1
        ];

        // WHEN I call the update method with a limit of 1
        Test.startTest();

        ProductOpportunityUpdateController.ProductOpportunityUpdateSaveResults results = ProductOpportunityUpdateController.updateOpportunitiesWithMismatchedDates(
            product.Id,
            product.Start_Date__c,
            product.End_Date__c,
            1
        );

        Test.stopTest();

        // THEN it should have updated a single Opportunity
        Assert.areEqual(1, results.successCount);
        Assert.areEqual(0, results.failCount);

        // AND the Opportunity should have been the older of the two
        Opportunity oppResult = [
            SELECT Id, End_Date__c, OOTJTH_Calculated__c, OOTJTH_Preserved__c, EPA__c
            FROM Opportunity
            WHERE Id = :oppToUpdate.Id
        ];
        Assert.areNotEqual(oppToUpdate.End_Date__c, oppResult.End_Date__c);

        // AND the End Date should match the Product
        Assert.areEqual(product.End_Date__c, oppResult.End_Date__c);

        // AND the OOTJTH should have been recalculated
        Assert.areNotEqual(oppToUpdate.OOTJTH_Preserved__c, oppResult.OOTJTH_Preserved__c);
        Assert.areEqual(oppResult.OOTJTH_Calculated__c, oppResult.OOTJTH_Preserved__c);
    }
}
