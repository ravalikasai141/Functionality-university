@isTest
private class BannerApplicationBatchTest {
    @TestSetup
    private static void setup() {
        blng__BillingRule__c billingRule = TestDataFactory.createBillingRule(true);
        blng__FinanceBook__c billingFinanceBook = TestDataFactory.createBillingFinanceBook(true);
        blng__RevenueRecognitionRule__c revenueRecognitionRule = TestDataFactory.createRevenueRecognitionRule(true);
        blng__TaxRule__c taxRule = TestDataFactory.createTaxRule(true);

        Id applicationRtId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName()
            .get('Application')
            .getRecordTypeId();

        Country_List__c country = new Country_List__c(
            Name = 'United Kingdom',
            Valid_Domicile__c = true,
            Valid_Nationality__c = true,
            country_code_2__c = 'GB',
            ISO_CODE__c = 'GB',
            enabled__c = true
        );

        insert country;

        insert new Legal_Entity__c(
            Name = 'UC~COL',
            AR_Integration__c = true,
            Entity__c = 'test-entity',
            Name__c = 'UC~COL'
        );

        Account account = new Account(
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName()
                .get('Student Account')
                .getRecordTypeId(),
            FirstName = 'TestAccount',
            LastName = 'Student2',
            PersonBirthdate = Date.newInstance(2002, 2, 1),
            Preferred_Email__pc = 'Personal',
            Preferred_Phone__pc = 'Mobile',
            PersonEmail = 'john2@john.com',
            Personal_Email__pc = 'john2@john.com',
            PersonMobilePhone = '+447716123222',
            Account_Type__c = 'General',
            VAT_Code__pc = '123456789',
            Domicile__pc = 'XF~ England',
            AR_Customer_Number__c = '27356632',
            Country_of_Permanent_Address__c = country.Id,
            Primary_Nationality__pc = country.Id,
            PS_Profile_Services_ID__pc = 'ba618412-c3d7-4752-67yu-17c52bfc20c8',
            Student_Type__pc = 'Domestic',
            AR_Account_Status_Code__c = 'test',
            AR_Global_Customer_Number__c = 'plswork',
            Legal_Entity__c = 'UC~COL',
            Parent_Guardian_Occupation__pc = '0000~ Not stated',
            SFDC_Disability_Status_Code_Select__pc = '0~ No Known Disability'
        );

        insert account;

        Programme__c programme = new Programme__c(
            Name = 'Test programme',
            Programme_Id__c = 'test-programme-code',
            BNR_FieldOfStudy_Code__c = 'test-field-of-study'
        );

        insert programme;

        Product2 product = new Product2(
            Name = 'Test Course',
            Programme__c = programme.Id,
            BPP_ProductFactoryID__c = 'test-123',
            Instance_Id__c = 'test-1234',
            Location__c = 'London',
            BNR_Term_Code__c = 'test-term-code',
            BNR_Campus_Code__c = 'test-campus-code',
            BNR_Used_Capacity__c = 0,
            BNR_Max_Capacity__c = 100,
            Product_Type__c = 'OFFERING',
            Mode__c = 'Full',
            Start_Date__c = Date.today()
        );

        insert product;

        insert new PricebookEntry(
            IsActive = true,
            Product2Id = product.Id,
            UnitPrice = 10,
            Pricebook2Id = Test.getStandardPricebookId()
        );

        Opportunity opp = new Opportunity(
            RecordTypeId = applicationRtId,
            AccountId = account.Id,
            Name = 'Test Opportunity2',
            StageName = 'Accepted - Pmt Received',
            CloseDate = Date.today() + 30,
            Enrolment_Status__c = 'Acceptance',
            Course_Instance__c = product.Id,
            Pricebook2Id = Test.getStandardPricebookId()
        );

        insert opp;

        insert new Opportunity_Product__c(
            Opportunity__c = opp.Id,
            Course_Focus__c = 'Primary',
            Product__c = product.Id
        );

        Address__c address = new Address__c(
            Student__c = account.Id,
            Type__c = 'Home',
            Street_1__c = '329 S Tonne Dr',
            Street_2__c = '123',
            Street_3__c = '123',
            Street_4__c = '12',
            City__c = 'Chicago',
            Zip_Postal_Code__c = '12345'
        );

        insert address;
    }

    @isTest
    private static void itShouldBeAbleToSendAnOpportunityToBanner() {
        // GIVEN We have an opportunity we need to send to banner
        // WHEN we include this opp in a query and run the batch
        System.Test.startTest();

        BannerApplicationBatch batch = new BannerApplicationBatch('SELECT Id FROM Opportunity');
        Database.executeBatch(batch);

        System.Test.stopTest();
        // THEN I expect it to process successfully
        Account account = [SELECT BNR_Banner_ID__pc FROM Account WHERE LastName = 'Student2'];
        List<ContentVersion> versions = [SELECT Id FROM ContentVersion];

        Assert.areNotEqual(null, account.BNR_Banner_ID__pc);
        Assert.isTrue(versions.isEmpty());
    }

    @isTest
    private static void itShouldReportErrors() {
        // GIVEN We have an opportunity we need to send to banner
        // AND this opportunity will fail
        Account account = [SELECT Id, AR_Account_Status_Code__c FROM Account WHERE LastName = 'Student2'];
        account.AR_Account_Status_Code__c = 'FinancialHoldApplied';
        update account;

        // WHEN we include this opp in a query and run the batch
        System.Test.startTest();

        BannerApplicationBatch batch = new BannerApplicationBatch('SELECT Id FROM Opportunity');
        Database.executeBatch(batch);

        System.Test.stopTest();
        // THEN I expect it to create an error csv
        List<ContentVersion> versions = [SELECT Id FROM ContentVersion];

        Assert.isFalse(versions.isEmpty());
    }
}
