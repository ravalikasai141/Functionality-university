@isTest
public class DeliveryUtilityTest {

	@testSetup
	static void testSetup() {
        country_list__c cntry = CreateTestData.createCountry1();

        Account clientAccount = new Account(Name = 'TestDataFactoryClient');
        clientAccount.Billing_Type__c = 'In Advance';
        clientAccount.Charge_Trigger__c = 'Instance Start Date';
        insert clientAccount;

		Account studentAccount = TestDataFactory.createAccount(false,true,clientAccount.Id,1);
        studentAccount.FirstName = 'TestDataFactoryStudent';
        insert studentAccount;

        List<Address__c> addresses = new List<Address__c>();
        addresses.add(TestDataFactory.createAddress(false,0,clientAccount,cntry,true,true));
        addresses.add(TestDataFactory.createAddress(false,1,studentAccount,cntry,true,true));
        insert addresses;

        Stock_Site__c stockSite = new Stock_Site__c(Name = 'UK Warehouse', BPP_Product_Factory_ID__c = '9bc37088-2483-46f7-b4a4-62a83fefd662');
		insert stockSite;
        System.debug('DeliveryUtilityTest - Setup: Stock Site inserted: ' + stockSite);

        Study_Location__c studyLocation = TestDataFactory.createStudyLocation(false,0,cntry);
		insert studyLocation;

        blng__BillingRule__c billingRule = TestDataFactory.createBillingRule(true);
		blng__FinanceBook__c billingFinanceBook = TestDataFactory.createBillingFinanceBook(true);
		blng__BillingTreatment__c billingTreatment = TestDataFactory.createBillingTreatment(true, billingRule, billingFinanceBook);
		blng__RevenueRecognitionRule__c revenueRecognitionRule = TestDataFactory.createRevenueRecognitionRule(true);
		blng__TaxRule__c taxRule = TestDataFactory.createTaxRule(true);

        List<Product2> products = new List<Product2>();
		for (Integer i=0;i<6;i++) {
			if (i < 3) {
                // Three courses: 1st for non-standalone Deliver to BPP Location, 2nd for non-standalone Deliver to Customer, 3rd for standalone Deliver to Customer
                Product2 courseProduct = TestDataFactory.createProduct(false,i,billingRule,revenueRecognitionRule,taxRule);
                courseProduct.Family = 'Course';
				products.add(courseProduct);
			} if (i == 3) {
                // Material Product for 1st Product
				Product2 materialProduct1 = TestDataFactory.createProduct(false,i,billingRule,revenueRecognitionRule,taxRule);
				materialProduct1.Family = 'Materials';
				materialProduct1.Format__c = 'Physical';
				materialProduct1.BPP_ProductFactoryID__c = '8a72e11d-e1b0-43b1-adae-4e0690369bf9';
				materialProduct1.Standalone_Material__c = FALSE;
				products.add(materialProduct1);
			} if (i == 4) {
                // Material Product for 2nd Product
				Product2 materialProduct2 = TestDataFactory.createProduct(false,i,billingRule,revenueRecognitionRule,taxRule);
				materialProduct2.Family = 'Materials';
				materialProduct2.Format__c = 'Physical';
				materialProduct2.BPP_ProductFactoryID__c = '8a72e11d-e1b0-43b1-adae-4e0690369ce0';
				materialProduct2.Standalone_Material__c = FALSE;
				products.add(materialProduct2);
			} if (i == 5) {
                // Material Product for 3rd Product
				Product2 materialProduct3 = TestDataFactory.createProduct(false,i,billingRule,revenueRecognitionRule,taxRule);
				materialProduct3.Family = 'Materials';
				materialProduct3.Format__c = 'Digital';
				materialProduct3.BPP_ProductFactoryID__c = '8a72e11d-e1b0-43b1-adae-4e0690369df1';
				materialProduct3.Standalone_Material__c = TRUE;
				products.add(materialProduct3);
			}
		}
		insert products;
        for (Product2 product : products) {
            System.debug('DeliveryUtilityTest - Setup: Product inserted: ' + product);
        }

        List<SBQQ__ProductFeature__c> productFeatures = new List<SBQQ__ProductFeature__c>();
        for (Integer i=0;i<3;i++) {
            // Product Feature for the three course Products
            SBQQ__ProductFeature__c productFeature = new SBQQ__ProductFeature__c(Name = 'Materials', SBQQ__Number__c = 10, SBQQ__ConfiguredSKU__c = products.get(i).Id);
            productFeatures.add(productFeature);
        }
		insert productFeatures;

		List<SBQQ__ProductOption__c> productOptions = new List<SBQQ__ProductOption__c>();
		for (Integer i=0;i<6;i++) {
			if (i == 3) {
                // Product Option for 1st Course Product
				productOptions.add(TestDataFactory.createProductOption(false,products.get(0),products.get(i),productFeatures.get(0),'Deliver to BPP Location'));
			} if (i == 4) {
                // Product Option for 2nd Course Product
				productOptions.add(TestDataFactory.createProductOption(false,products.get(1),products.get(i),productFeatures.get(1),'Deliver to Customer'));
			} if (i == 5) {
                // Product Option for 3rd Course Product
				productOptions.add(TestDataFactory.createProductOption(false,products.get(2),products.get(i),productFeatures.get(2),'Deliver to Customer'));
			}
		}
		insert productOptions;

        List<PricebookEntry> priceBookEntries = new List<PricebookEntry>();
		for (Integer i=0;i<6;i++) {
			priceBookEntries.add(TestDataFactory.createPricebookEntry(false,products.get(i),null));
		}
		insert priceBookEntries;

        List<Stock_Management__c> stockManagementList = new List<Stock_Management__c>();
		for (Integer i=0;i<6;i++) {
			if (i == 3) {
                // Stock Management record for 1st Course Product's Material (non-standalone)
				Stock_Management__c stockManagement1 = TestDataFactory.createStockManagement(false,i,Date.newInstance(2021,1,1),Date.newInstance(2099,1,1),
                                                        products.get(i).Id,null,products.get(i).BPP_ProductFactoryID__c, stockSite.Id);
				stockManagementList.add(stockManagement1);
			} if (i == 4) {
                // Stock Management record for 2nd Course Product's Material (non-standalone)
				Stock_Management__c stockManagement2 = TestDataFactory.createStockManagement(false,i,Date.newInstance(2021,1,1),Date.newInstance(2099,1,1),
                                                        products.get(i).Id,null,products.get(i).BPP_ProductFactoryID__c, stockSite.Id);
				stockManagementList.add(stockManagement2);
			} if (i == 5) {
                // Stock Management record for 3rd Course Product's Material (standalone)
				Stock_Management__c stockManagement3 = TestDataFactory.createStockManagement(false,i,Date.newInstance(2021,1,1),Date.newInstance(2099,1,1),
                                                        null,products.get(i).Id,products.get(i).BPP_ProductFactoryID__c, stockSite.Id);
				stockManagementList.add(stockManagement3);
			}
		}
		insert stockManagementList;
        for (Stock_Management__c stockManagement : stockManagementList) {
            System.debug('DeliveryUtilityTest - Setup: Stock Management inserted: ' + stockManagement);
        }

        List<Instance__c> instances = new List<Instance__c>();
		for (Integer i=0;i<3;i++){
            // Create Instance on each of the three Course Products
			instances.add(TestDataFactory.createInstance(false,i,products.get(i),studyLocation));
		}
		insert instances;

        List<Order> orders = new List<Order>();
		for (Integer i=0;i<3;i++){
            // Create three Orders
            Order order = TestDataFactory.createOrder(false, i, clientAccount, null, addresses.get(0));
            order.Stock_Site__c = stockSite.Id;
            orders.add(order);
		}
		insert orders;
        for (Order order : orders) {
            System.debug('DeliveryUtilityTest - Setup: Order inserted: ' + order);
        }

        List<OrderItem> parentOrderLines = new List<OrderItem>();
		for(Integer i=0;i<3;i++){
            parentOrderLines.add(TestDataFactory.createOrderLine(false,orders.get(i),products.get(i),null,priceBookEntries.get(i),billingRule,revenueRecognitionRule,taxRule,''));
		}
        insert parentOrderLines;

        List<OrderItem> orderProducts = new List<OrderItem>();
		for(Integer i=0;i<6;i++){
            if (i < 3) {
                // Order Product for the three Course Products
                orderProducts.add(TestDataFactory.createOrderLine(false,orders.get(i),products.get(i),parentOrderLines.get(i),priceBookEntries.get(i),billingRule,revenueRecognitionRule,taxRule,'Course'));
            } if (i == 3) {
                // Order Product (Material) for 1st Course Product
                orderProducts.add(TestDataFactory.createOrderLine(false,orders.get(0),products.get(0),parentOrderLines.get(0),priceBookEntries.get(i),billingRule,revenueRecognitionRule,taxRule,'Materials'));
            } if (i == 4) {
                // Order Product (Material) for 2nd Course Product
                orderProducts.add(TestDataFactory.createOrderLine(false,orders.get(1),products.get(1),parentOrderLines.get(1),priceBookEntries.get(i),billingRule,revenueRecognitionRule,taxRule,'Materials'));
            } if (i == 5) {
                // Order Product (Material) for 3rd Course Product
                orderProducts.add(TestDataFactory.createOrderLine(false,orders.get(2),products.get(2),parentOrderLines.get(2),priceBookEntries.get(i),billingRule,revenueRecognitionRule,taxRule,'Materials'));
            }
		}
		insert orderProducts;
        for (OrderItem orderItem : orderProducts) {
            System.debug('DeliveryUtilityTest - Setup: Order Product inserted: ' + orderItem);
        }
        
        List<blng__UsageSummary__c> usageSummaries = new List<blng__UsageSummary__c>();
        for (Integer i = 0; i < orderProducts.size(); i++) {
            usageSummaries.add(TestDataFactory.createBookingSummary(false, orderProducts.get(i)));
        }
        insert usageSummaries;
    }

    static void activateOrders() {
		List<Order> orderList = [SELECT Id FROM Order WHERE Status = 'Draft'];
		for (Order order : orderList) {
			order.Status = 'Activated';
		}
		update orderList;
	}

    public static List<Booking__c> insertBookings(){
		List<Instance__c> instances = [SELECT Id FROM Instance__c ORDER BY Instance_Name__c ASC];
        List<Order> orders = [SELECT Id FROM Order ORDER BY Name ASC];
		Account clientAccount = [SELECT Id FROM Account WHERE Name = 'TestDataFactoryClient'];
		Account studentAccount = [SELECT Id FROM Account WHERE FirstName = 'TestDataFactoryStudent'];

        List<Booking__c> bookings = new List<Booking__c>();
        for(Integer i=0;i<3;i++){
            // Create three Bookings
            Booking__c booking = new Booking__c(
                Account__c = clientAccount.Id,
                Instance__c = instances.get(i).Id,
                Status__c = 'On Hold',
                On_Hold_Reason__c = 'Test Reason',
                Order__c = orders.get(i).Id,
                Student__c = studentAccount.Id
            );
            bookings.add(booking);
        }
		insert bookings;

        for (Booking__c booking : bookings) {
            System.debug('DeliveryUtilityTest - Create: Booking inserted: ' + booking);
        }

        return bookings;
    }

    @isTest
    static void test_createStandaloneDeliveryRecords() {
        Order order = [SELECT Id, (SELECT Id FROM OrderItems WHERE Product2.Standalone_Material__c = TRUE) FROM Order WHERE Name = 'Default Test Order 2'];
        System.assertEquals(1, order.OrderItems.size(), 'Related Order Product should contain one Standalone Material');

        Integer deliveryCountBefore = [SELECT COUNT() FROM Delivery__c];
        System.assertEquals(0, deliveryCountBefore, 'There should be no Delivery records at this point');

        Test.startTest();
            activateOrders();
        Test.stopTest();

		Integer deliveryCountAfter = [SELECT COUNT() FROM Delivery__c];
        System.assertEquals(1, deliveryCountAfter, 'One Delivery record should have been created on Order activation');

        EDeliveryUpdateBatch mybatch = new EDeliveryUpdateBatch();
        Database.executeBatch(mybatch);
    }

    /*@isTest
    static void test_createDeliveryRecordsForBPPLocation() {
        Order order = [SELECT Id, (SELECT Id FROM OrderItems) FROM Order WHERE Name = 'Default Test Order 0'];
        Id orderProductId;
        for (OrderItem orderProduct : order.OrderItems) {
            orderProductId = orderProduct.Id;
        }

        Integer deliveryCountBefore = [SELECT COUNT() FROM Delivery__c];
        System.assertEquals(0, deliveryCountBefore, 'There should be no Delivery records at this point');

        Test.startTest();
            activateOrders();
            insertBookings();
        Test.stopTest();
        
        List<Delivery__c> deliveryList = [SELECT Id, Quantity__c, Order_Product__r.Product2Id FROM Delivery__c WHERE Order_Product__c =: orderProductId];
        System.assertEquals(1, deliveryList.size(), 'One Delivery record should have been created on the above');
    }*/

    @isTest
    static void test_createDeliveryRecordsForCustomerDeliverMaterialsToStudentFalse() {
        Order order = [SELECT Id, (SELECT Id FROM OrderItems) FROM Order WHERE Name = 'Default Test Order 1'];
        Id orderProductId;
        for (OrderItem orderProduct : order.OrderItems) {
            orderProductId = orderProduct.Id;
        }

        Integer deliveryCountBefore = [SELECT COUNT() FROM Delivery__c];
        System.assertEquals(0, deliveryCountBefore, 'There should be no Delivery records at this point');

        Test.startTest();
            activateOrders();
            insertBookings();
        Test.stopTest();
    }

    /*@isTest
    static void test_createDeliveryRecordsForCustomerDeliverMaterialsToStudentTrue() {
        Order order = [SELECT Id, (SELECT Id FROM OrderItems) FROM Order WHERE Name = 'Default Test Order 1'];
        order.Deliver_Materials_to_Student__c = TRUE;
        update order;

        Id orderProductId;
        for (OrderItem orderProduct : order.OrderItems) {
            orderProductId = orderProduct.Id;
        }

        Integer deliveryCountBefore = [SELECT COUNT() FROM Delivery__c];
        System.assertEquals(0, deliveryCountBefore, 'There should be no Delivery records at this point');

        Test.startTest();
            activateOrders();
            insertBookings();
        Test.stopTest();

        List<Delivery__c> deliveryList = [SELECT Id, Quantity__c, Order_Product__r.Product2Id FROM Delivery__c WHERE Order_Product__c =: orderProductId AND Delivery_Status__c = 'Awaiting Allocation'];
        System.assertEquals(1, deliveryList.size(), 'One Delivery record should have been created on the above');
    }*/

    @isTest
    static void test_allocateStockSuccess() {
        Test.startTest();
            activateOrders();
            insertBookings();
        Test.stopTest();

        Stock_Management__c stockManagementBefore = [SELECT Id, Shortage__c, (SELECT Id, Added_To_Shortage__c, Allocation_Attempts__c, Delivery_Status__c FROM StockManagement__r LIMIT 1) FROM Stock_Management__c LIMIT 1];
        Delivery__c deliveryBefore = stockManagementBefore.StockManagement__r;

        System.assertEquals(1, stockManagementBefore.Shortage__c, 'Stock Management Shortage value should have increased to 1 during Delivery record insertion (Delivery Auto Allocate = TRUE AND Stock Management Availble = 0)');
        System.assertEquals(TRUE, deliveryBefore.Added_To_Shortage__c, 'Delivery Added To Shortage value should be TRUE');
        System.assertEquals(1, deliveryBefore.Allocation_Attempts__c, 'Delivery Allocation Attempts value should be 1');
        System.assertEquals('Awaiting Allocation', deliveryBefore.Delivery_Status__c, 'Delivery Status should be "Awaiting Allocation" (initial status)');

        stockManagementBefore.Total__c = 1;
        update stockManagementBefore;
        
        Stock_Management__c stockManagementAfter = [SELECT Shortage__c, (SELECT Id, Added_To_Shortage__c, Allocation_Attempts__c, Delivery_Status__c FROM StockManagement__r LIMIT 1) FROM Stock_Management__c WHERE Id =: stockManagementBefore.Id];
        Delivery__c deliveryAfter = stockManagementAfter.StockManagement__r;

        System.assertEquals(0, stockManagementAfter.Shortage__c, 'Stock Management Shortage value should have updated to 0 after successful allocation');
        System.assertEquals(FALSE, deliveryAfter.Added_To_Shortage__c, 'Delivery Added To Shortage value should have updated to FALSE after successful allocation');
        System.assertEquals(2, deliveryAfter.Allocation_Attempts__c, 'Delivery Allocation Attempts value should have updated to 2');
        System.assertEquals('Ready for Fulfilment', deliveryAfter.Delivery_Status__c, 'Delivery Status should be "Ready for Fulfilment" (after successful allocation)');
    }

    @isTest
    static void test_allocateStockFailure() {
        Test.startTest();
            activateOrders();
            insertBookings();
        Test.stopTest();

        Stock_Management__c stockManagementBefore = [SELECT Id, Shortage__c, (SELECT Id, Added_To_Shortage__c, Allocation_Attempts__c, Delivery_Status__c FROM StockManagement__r LIMIT 1) FROM Stock_Management__c LIMIT 1];
        Delivery__c deliveryBefore = stockManagementBefore.StockManagement__r;
        deliveryBefore.Quantity__c = 5;
        update deliveryBefore;

        System.assertEquals(1, stockManagementBefore.Shortage__c, 'Stock Management Shortage value should have increased to 1 during Delivery record insertion (Delivery Auto Allocate = TRUE AND Stock Management Availble = 0)');
        System.assertEquals(TRUE, deliveryBefore.Added_To_Shortage__c, 'Delivery Added To Shortage value should be TRUE');
        System.assertEquals(1, deliveryBefore.Allocation_Attempts__c, 'Delivery Allocation Attempts value should be 1');
        System.assertEquals('Awaiting Allocation', deliveryBefore.Delivery_Status__c, 'Delivery Status should be "Awaiting Allocation" (initial status)');

        stockManagementBefore.Total__c = 1;
        update stockManagementBefore;
        
        Stock_Management__c stockManagementAfter = [SELECT Shortage__c, (SELECT Id, Added_To_Shortage__c, Allocation_Attempts__c, Delivery_Status__c FROM StockManagement__r LIMIT 1) FROM Stock_Management__c WHERE Id =: stockManagementBefore.Id];
        Delivery__c deliveryAfter = stockManagementAfter.StockManagement__r;

        System.assertEquals(5, stockManagementAfter.Shortage__c, 'Stock Management Shortage value should have updated to 5 after failed allocations (Delivery Quantity being larger than the related Stock Management Total)');
        System.assertEquals(TRUE, deliveryAfter.Added_To_Shortage__c, 'Delivery Added To Shortage value should have updated to FALSE after failed allocation');
        System.assertEquals(2, deliveryAfter.Allocation_Attempts__c, 'Delivery Allocation Attempts value should have updated to 2');
        System.assertEquals('Awaiting Allocation', deliveryAfter.Delivery_Status__c, 'Delivery Status should remain at "Awaiting Allocation" (after failed allocation)');
    }

    static testmethod void test_GenerateDeliveryUpdateBatchJob() {
        Test.startTest();
            activateOrders();
            insertBookings();
        Test.stopTest();

        Stock_Management__c stockManagementBefore = [SELECT Id, Shortage__c, (SELECT Id, Delivery_Status__c, Stock_Allocated__c FROM StockManagement__r LIMIT 1) FROM Stock_Management__c LIMIT 1];
        Delivery__c delivery = stockManagementBefore.StockManagement__r;
        
        stockManagementBefore.Total__c = 1;
        update stockManagementBefore;

        Delivery__c deliveryBeforeBatch = [SELECT Id, Delivery_Status__c, Sent_for_Fulfilment_On__c, Stock_Allocated__c FROM Delivery__c WHERE Id =: delivery.Id];
        System.assertEquals('Ready for Fulfilment', deliveryBeforeBatch.Delivery_Status__c, 'Delivery Status should be "Ready for Fulfilment" (after successful allocation)');
        System.assertEquals(TRUE, deliveryBeforeBatch.Stock_Allocated__c, 'Delivery Stock Allocated should be TRUE (after successful allocation)');

        DeliveryUpdateBatch mybatch = new DeliveryUpdateBatch();
        Database.executeBatch(mybatch);
	}

    static testmethod void test_GenerateEDeliveryUpdateBatchJob() {
        Test.startTest();
            activateOrders();
            insertBookings();
        Test.stopTest();

        Stock_Management__c stockManagementBefore = [SELECT Id, Shortage__c, (SELECT Id, Delivery_Status__c, Stock_Allocated__c FROM StockManagement__r LIMIT 1) FROM Stock_Management__c LIMIT 1];
        Delivery__c delivery = stockManagementBefore.StockManagement__r;
        
        stockManagementBefore.Total__c = 1;
        update stockManagementBefore;

        Delivery__c deliveryBeforeBatch = [SELECT Id, Delivery_Status__c, Sent_for_Fulfilment_On__c, Stock_Allocated__c FROM Delivery__c WHERE Id =: delivery.Id];
        System.assertEquals('Ready for Fulfilment', deliveryBeforeBatch.Delivery_Status__c, 'Delivery Status should be "Ready for Fulfilment" (after successful allocation)');
        System.assertEquals(TRUE, deliveryBeforeBatch.Stock_Allocated__c, 'Delivery Stock Allocated should be TRUE (after successful allocation)');

        EDeliveryUpdateBatch mybatch = new EDeliveryUpdateBatch();
        Database.executeBatch(mybatch);
	}
    
    static testmethod void test_DeliveryUpdateBatchHelper() {
        Instance__c instance = [SELECT Id FROM Instance__c WHERE Instance_Name__c = 'Test instance 2'];
		Account clientAccount = [SELECT Id FROM Account WHERE Name = 'TestDataFactoryClient'];
		Account studentAccount = [SELECT Id FROM Account WHERE FirstName = 'TestDataFactoryStudent'];
        Order order = [SELECT Id, (SELECT Id FROM OrderItems) FROM Order WHERE Name = 'Default Test Order 2'];
        
        order.Status = 'Activated';   
        update order;
        
        Booking__c booking = new Booking__c(
            Account__c = clientAccount.Id,
            Instance__c = instance.Id,
            Status__c = 'On Hold',
            On_Hold_Reason__c = 'Test Reason',
            Order__c = order.Id,
            Student__c = studentAccount.Id
        );
        Test.startTest();
            insert booking;
        Test.stopTest();

        List<Delivery__c> deliveryList = [SELECT Id, Delivery_Status__c, Sent_for_Fulfilment_On__c, Stock_Allocated__c FROM Delivery__c];
        System.debug(deliveryList.size());
        for (Delivery__c del : deliveryList) {
            del.Booking_Line__c = NULL;
        }
        update deliveryList;
        
        Product2 product = [SELECT Id FROM Product2 WHERE BPP_ProductFactoryID__c = '8a72e11d-e1b0-43b1-adae-4e0690369df1'];
        product.Standalone_Material__c = FALSE;
        update product;

        DeliveryUpdateBatch mybatch = new DeliveryUpdateBatch();
        Database.executeBatch(mybatch);
	}

    static testmethod void test_GenerateDeliveryUpdateBatchScheduler() {
		Test.startTest();
			String CRON_EXP = '0 0 0 3 9 ? 2025';
			System.schedule('DeliveryUpdateBatch', CRON_EXP, new DeliveryUpdateScheduler());
		Test.stopTest();
	}

    static testmethod void test_GenerateEDeliveryUpdateBatchScheduler() {
		Test.startTest();
			String CRON_EXP = '0 0 0 3 9 ? 2025';
			System.schedule('EDeliveryUpdateBatch', CRON_EXP, new EDeliveryUpdateScheduler());
		Test.stopTest();
	}
}