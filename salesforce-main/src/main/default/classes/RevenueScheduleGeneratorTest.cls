@isTest
public class RevenueScheduleGeneratorTest {
    @testSetup
	static void testSetup() {
        country_list__c cntry = CreateTestData.createCountry1();

        Account clientAccount = new Account(Name = 'TestDataFactoryClient');
        insert clientAccount;

		Account studentAccount = TestDataFactory.createAccount(false, true, clientAccount.Id, 1);
        studentAccount.FirstName = 'TestDataFactoryStudent';
        studentAccount.Client__c = clientAccount.Id;
        insert studentAccount;

        List<Address__c> addresses = new List<Address__c>();
        addresses.add(TestDataFactory.createAddress(false, 0, clientAccount, cntry, true, true));
        addresses.add(TestDataFactory.createAddress(false, 1, studentAccount, cntry, true, true));
        insert addresses;

        Opportunity opp = new Opportunity(AccountId = clientAccount.Id, Name = 'Test Opp', StageName = 'Quoting', BPP_Sub_Status__c = 'Other', CloseDate = Date.today(), RecordTypeId = Schema.Sobjecttype.Opportunity.getRecordTypeInfosByName().get('PQ Booking').getRecordTypeId());
        insert opp;

        Stock_Site__c stockSite = new Stock_Site__c(Name = 'UK Warehouse', BPP_Product_Factory_ID__c = '9bc37088-2483-46f7-b4a4-62a83fefd662');
		insert stockSite;

        Study_Location__c studyLocation = TestDataFactory.createStudyLocation(false, 0, cntry);
		insert studyLocation;

        blng__BillingRule__c billingRule = TestDataFactory.createBillingRule(false);
        billingRule.Name = 'Test Combined GL';
        insert billingRule;

		blng__TaxRule__c taxRule = TestDataFactory.createTaxRule(false);
        taxRule.Name = 'EXE';
        insert taxRule;

		blng__RevenueRecognitionRule__c revenueRecognitionRule = TestDataFactory.createRevenueRecognitionRule(false);
        revenueRecognitionRule.API_Call_Identifiers__c = 'Delivery - Full - RR Date';
        insert revenueRecognitionRule;

		blng__FinanceBook__c billingFinanceBook = TestDataFactory.createBillingFinanceBook(false);
        billingFinanceBook.Name = 'Revenue Finance Book';
        insert billingFinanceBook;

		blng__BillingTreatment__c billingTreatment = TestDataFactory.createBillingTreatment(true, billingRule, billingFinanceBook);
        
        blng__LegalEntity__c legalEntity1 = new blng__LegalEntity__c(blng__Active__c = true, BPP_Is_Parent__c = true, Name = 'BPP Learning Media Ltd');
        insert legalEntity1;
        blng__LegalEntity__c legalEntity2 = new blng__LegalEntity__c(blng__Active__c = true, BPP_Billing_Category__c = 'CMB', BPP_Parent_Legal_Entity__c = legalEntity1.Id, BPP_Tax_Category__c = 'EXE', Name = 'LM-EXE-CMB');
        insert legalEntity2;
        blng__FinancePeriod__c billingfinancePeriod = new blng__FinancePeriod__c(Name = 'Test Finance Period', blng__FinanceBook__c = billingFinanceBook.Id, blng__PeriodStartDate__c = Date.newInstance(2021,05,01), blng__PeriodEndDate__c = Date.newInstance(2021,05,31), blng__PeriodStatus__c = 'Open', blng__LegalEntity__c = legalEntity2.Id);
        insert billingfinancePeriod;

        SBQQ__Quote__c quote = new SBQQ__Quote__c(SBQQ__Account__c = clientAccount.Id, SBQQ__Opportunity2__c = opp.Id, SBQQ__Primary__c = true, SBQQ__Type__c = 'Quote', SBQQ__Status__c = 'Raised', SBQQ__BillingFrequency__c = 'Monthly', Billing_Type__c = 'In Advance');
        insert quote;

        List<Product2> products = new List<Product2>();
		for (Integer i = 0; i < 3; i++) {
			if (i == 0) {
                Product2 courseProduct = TestDataFactory.createProduct(false, i, billingRule, revenueRecognitionRule, taxRule);
                courseProduct.BPP_ProductFactoryID__c = '9bc37088-2483-46f7-b4a4-62a83fefd662';
                courseProduct.Family = 'Course';
                courseProduct.BPP_Legal_Entity__c = legalEntity1.Id;
				products.add(courseProduct);
			} if (i == 1) {
				Product2 materialProduct1 = TestDataFactory.createProduct(false, i, billingRule, revenueRecognitionRule, taxRule);
				materialProduct1.BPP_ProductFactoryID__c = '8a72e11d-e1b0-43b1-adae-4e0690369bf9';
				materialProduct1.Family = 'Materials';
				materialProduct1.Format__c = 'Physical';
				materialProduct1.BPP_Legal_Entity__c = legalEntity1.Id;
				materialProduct1.Name = 'Material 1';
				products.add(materialProduct1);
			} if (i == 2) {
				Product2 materialProduct2 = TestDataFactory.createProduct(false, i, billingRule, revenueRecognitionRule, taxRule);
				materialProduct2.BPP_ProductFactoryID__c = '8a72e11d-e1b0-43b1-adae-4e0690369ce0';
				materialProduct2.Family = 'Materials';
				materialProduct2.Format__c = 'Physical';
				materialProduct2.BPP_Legal_Entity__c = legalEntity1.Id;
				materialProduct2.Name = 'Material 2';
				products.add(materialProduct2);
			}
		}
		insert products;

        List<SBQQ__ProductFeature__c> productFeatures = new List<SBQQ__ProductFeature__c>();
        productFeatures.add(new SBQQ__ProductFeature__c(Name = 'Materials', SBQQ__Number__c = 10, SBQQ__ConfiguredSKU__c = products.get(0).Id));
		insert productFeatures;

		List<SBQQ__ProductOption__c> productOptions = new List<SBQQ__ProductOption__c>();
        productOptions.add(TestDataFactory.createProductOption(false, products.get(0), products.get(1), productFeatures.get(0), 'Deliver to BPP Location'));
        productOptions.add(TestDataFactory.createProductOption(false, products.get(0), products.get(2), productFeatures.get(0), 'Deliver to BPP Location'));
		insert productOptions;

        List<PricebookEntry> priceBookEntries = new List<PricebookEntry>();
		for (Integer i = 0; i < 3; i++) {
			priceBookEntries.add(TestDataFactory.createPricebookEntry(false, products.get(i), null));
		}
		insert priceBookEntries;

        List<Stock_Management__c> stockManagementList = new List<Stock_Management__c>();
        Stock_Management__c sm1 = TestDataFactory.createStockManagement(false, 0, Date.newInstance(2021, 1, 1), Date.newInstance(2099, 1, 1), products.get(1).Id, null, products.get(1).BPP_ProductFactoryID__c, stockSite.Id);
        sm1.Total__c = 10;
        stockManagementList.add(sm1);
        Stock_Management__c sm2 = TestDataFactory.createStockManagement(false, 1, Date.newInstance(2021, 1, 1), Date.newInstance(2099, 1, 1), products.get(2).Id, null, products.get(2).BPP_ProductFactoryID__c, stockSite.Id);
        sm2.Total__c = 10;
        stockManagementList.add(sm2);
		insert stockManagementList;

        Instance__c instance = TestDataFactory.createInstance(true, 0, products.get(0), studyLocation);

        List<SBQQ__QuoteLine__c> quoteLines = new List<SBQQ__QuoteLine__c>();
        for (Integer i = 0; i < 3; i++) {
            SBQQ__QuoteLine__c quoteLine = new SBQQ__QuoteLine__c(SBQQ__Quote__c = quote.Id, SBQQ__Product__c = products.get(i).Id, SBQQ__Quantity__c = 1, Billing_Rule__c = billingRule.Id, Tax_Rule__c = taxRule.Id);
            quoteLines.add(quoteLine);
        }
        insert quoteLines;
        // link Quote Lines to each Order Products

        Order order = TestDataFactory.createOrder(false, 0, clientAccount, null, addresses.get(0));
        order.Stock_Site__c = stockSite.Id;
		insert order;

        OrderItem parentOrderLine = TestDataFactory.createOrderLine(true, order, products.get(0), null, priceBookEntries.get(0), billingRule, revenueRecognitionRule, taxRule, '');

        List<OrderItem> orderProducts = new List<OrderItem>();
		for (Integer i = 0; i < 3; i++) {
            if (i == 0) {
                OrderItem orderItemCourse = TestDataFactory.createOrderLine(false, order, products.get(i), parentOrderLine, priceBookEntries.get(i), billingRule, revenueRecognitionRule, taxRule, 'Course');
                orderItemCourse.SBQQ__QuoteLine__c = quoteLines.get(0).Id;
                orderProducts.add(orderItemCourse);
            } if (i > 0) {
                OrderItem orderItemMaterial = TestDataFactory.createOrderLine(false, order, products.get(i), parentOrderLine, priceBookEntries.get(i), billingRule, revenueRecognitionRule, taxRule, 'Materials');
                orderItemMaterial.SBQQ__QuoteLine__c = quoteLines.get(i).Id;
                orderProducts.add(orderItemMaterial);
            }
		}
		insert orderProducts;
        
        List<blng__UsageSummary__c> usageSummaries = new List<blng__UsageSummary__c>();
        for (Integer i = 0; i < orderProducts.size(); i++) {
            usageSummaries.add(TestDataFactory.createBookingSummary(false, orderProducts.get(i)));
        }
        insert usageSummaries;
    }

    public static void insertBooking(){
		Instance__c instance = [SELECT Id FROM Instance__c];
        Order order = [SELECT Id FROM Order];
		Account clientAccount = [SELECT Id FROM Account WHERE Name = 'TestDataFactoryClient'];
		Account studentAccount = [SELECT Id FROM Account WHERE FirstName = 'TestDataFactoryStudent'];

        Booking__c booking = new Booking__c(
            Account__c = clientAccount.Id, 
            Instance__c = instance.Id, 
            Status__c = 'On Hold', 
            On_Hold_Reason__c = 'Test Reason', 
            Order__c = order.Id, 
            Student__c = studentAccount.Id
        );
        System.debug(booking);
		insert booking;
    }

    @isTest
    static void test_RevenueScheduleCreation() {
        Test.startTest();
            Order order = [SELECT Id FROM Order];
            order.Status = 'Activated';
            update order;

            insertBooking();

        Test.stopTest();

        List<Delivery__c> deliveryListBefore = [SELECT Id, Delivery_Status__c FROM Delivery__c];
        for (Delivery__c del : deliveryListBefore) {
            del.Delivery_Status__c = 'Sent for Fulfilment';
        }
        update deliveryListBefore;

        Date dt = Date.newInstance(2021,05,15);
        List<Delivery__c> deliveryListAfter = [SELECT Id FROM Delivery__c];
        for (Delivery__c del : deliveryListAfter) {
            del.Delivery_Status__c = 'Dispatched';
            del.Dispatched_Date__c = dt;
        }
        update deliveryListAfter;
    }
}