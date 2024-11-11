/*
* @who   Patrick Duncan <patrick.duncan@weare4c.com>
* @what  Test class for BookingCreatorExt
* @when  14/1/2020
*/
@isTest
private class BookingCreatorExtTest {

    @testSetup
    static void testSetup(){
        country_list__c cntry = CreateTestData.createCountry1();
        
        Database.DMLOptions dbDML = new Database.DMLOptions(); 
        dbDML.DuplicateRuleHeader.allowSave = true;
        dbDML.DuplicateRuleHeader.runAsCurrentUser = true;

        Account clientAccount = new Account(Name = 'TestDataFactoryClient');
        Database.insert(clientAccount, dbDML);

		Account studentAccount1 = TestDataFactory.createAccount(false,true,1);
        studentAccount1.FirstName = 'TestDataFactoryStudent1';
        studentAccount1.Client__c = clientAccount.Id;
        studentAccount1.PersonEmail = 'john1@john.com';
        Database.insert(studentAccount1, dbDML);

        Account studentAccount2 = TestDataFactory.createAccount(false,true,1);
        studentAccount2.FirstName = 'TestDataFactoryStudent2';
        studentAccount2.Client__c = clientAccount.Id;
        studentAccount2.PersonEmail = 'john2@john.com';
        Database.insert(studentAccount2, dbDML);
        
        List<Hub_Account__c> hubAccounts = new List<Hub_Account__c>();
        hubAccounts.add(new Hub_Account__c(Hub_Username__c=studentAccount1.PersonEmail, Student__c=studentAccount1.Id));
        hubAccounts.add(new Hub_Account__c(Hub_Username__c=studentAccount2.PersonEmail, Student__c=studentAccount2.Id));
        insert hubAccounts;

        List<Address__c> addresses = new List<Address__c>();
        addresses.add(TestDataFactory.createAddress(false,0,clientAccount,cntry,true,true));
        addresses.add(TestDataFactory.createAddress(false,1,studentAccount1,cntry,true,true));
        addresses.add(TestDataFactory.createAddress(false,2,studentAccount2,cntry,true,true));
        Database.insert(addresses, dbDML);

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
		for (Integer i=0;i<7;i++) {
			if (i < 2) {
                Product2 courseProduct = TestDataFactory.createProduct(false,i,billingRule,revenueRecognitionRule,taxRule);
                courseProduct.Family = 'Course';
				products.add(courseProduct);
			} if (i == 2 || i == 3) {
				Product2 sessionProduct = TestDataFactory.createProduct(false,i,billingRule,revenueRecognitionRule,taxRule);
				sessionProduct.Family = 'Session';
				sessionProduct.BPP_ProductFactoryID__c = '8a72e11d-e1b0-43b1-adae-4e0690369bf'+i+'';
				products.add(sessionProduct);
			} if (i > 3) {
				Product2 materialProduct = TestDataFactory.createProduct(false,i,billingRule,revenueRecognitionRule,taxRule);
				materialProduct.Family = 'Materials';
				materialProduct.Format__c = 'Physical';
				materialProduct.BPP_ProductFactoryID__c = '8a72e11d-e1b0-43b1-adae-4e0690369ce'+i+'';
				products.add(materialProduct);
			}
		}
		insert products;

        List<PricebookEntry> priceBookEntries = new List<PricebookEntry>();
        for(Integer i=0;i<7;i++){
            priceBookEntries.add(TestDataFactory.createPricebookEntry(false,products.get(i),null));
        }
        insert priceBookEntries;

        List<Instance__c> instances = new List<Instance__c>();
        for(Integer i=0;i<2;i++){
            instances.add(TestDataFactory.createInstance(false,i,products.get(i)));
        }
        insert instances;

        List<Session__c> sessions = new List<Session__c>();
        for(Integer i=0;i<2;i++){
            sessions.add(TestDataFactory.createSession(false,i,instances.get(i),products.get(i),0,100));
        }
        insert sessions;

        List<Order> orders = new List<Order>();
		for (Integer i=0;i<2;i++){
            orders.add(TestDataFactory.createOrder(false,i,clientAccount,null,addresses.get(0)));
		}
		insert orders;

        List<OrderItem> parentOrderLines = new List<OrderItem>();
		for(Integer i=0;i<2;i++){
            parentOrderLines.add(TestDataFactory.createOrderLine(false,orders.get(i),products.get(i),null,priceBookEntries.get(i),billingRule,revenueRecognitionRule,taxRule,''));
		}
        insert parentOrderLines;

        List<OrderItem> orderProducts = new List<OrderItem>();
		for(Integer i=0;i<7;i++){
            if (i < 2) {
                orderProducts.add(TestDataFactory.createOrderLine(false,orders.get(i),products.get(i),parentOrderLines.get(i),priceBookEntries.get(i),billingRule,revenueRecognitionRule,taxRule,'Course'));
            } if (i == 2 || i == 3) {
                orderProducts.add(TestDataFactory.createOrderLine(false,orders.get(0),products.get(0),parentOrderLines.get(0),priceBookEntries.get(i),billingRule,revenueRecognitionRule,taxRule,'Session'));
            } if (i > 3) {
                orderProducts.add(TestDataFactory.createOrderLine(false,orders.get(1),products.get(1),parentOrderLines.get(1),priceBookEntries.get(i),billingRule,revenueRecognitionRule,taxRule,'Materials'));
            }
		}
		insert orderProducts;
        
        List<blng__UsageSummary__c> usageSummaries = new List<blng__UsageSummary__c>();
        for (Integer i = 0; i < orderProducts.size(); i++) {
            usageSummaries.add(TestDataFactory.createBookingSummary(false, orderProducts.get(i)));
        }
        insert usageSummaries;
    }

    /*
    * @method saveData
    * @case when creating 10 row with all columns correctly populated
    * @result expect 10 bookings to have been created
    */
    @isTest
    static void test_CreateBooking() {
        Account clientAccount = [SELECT Id FROM Account WHERE Name = 'TestDataFactoryClient'];
        List<Instance__c> instanceList = [SELECT Id FROM Instance__c ORDER BY Instance_Name__c ASC];
        List<Order> orderList = [SELECT Id FROM Order ORDER BY Name ASC];
        for (Order order : orderList) {
            order.Status = 'Activated';
        }
        update orderList;
        
        List<Account> studentAccountList = [SELECT Id FROM Account WHERE FirstName LIKE 'TestDataFactoryStudent%'];
        Set<Id> studentIds = new Set<Id>();
        for (Account acc : studentAccountList) {
            studentIds.add(acc.Id);
        }
        List<Hub_Account__c> hubAccountList = [SELECT Id FROM Hub_Account__c WHERE Student__c IN: studentIds];

        String jsonString = '[';
        for(Integer i=0;i<2;i++){
            jsonString += '["' + studentAccountList.get(i).Id + '","' + hubAccountList.get(i).Id + '","' + instanceList.get(i).Id + '","' + orderList.get(i).Id + '","1234","","","false"],';
        }

        jsonString = jsonString.removeEnd(',');
        jsonString += ']';
        System.debug('@@jsonString@'+jsonString);

        Test.startTest();
            ApexPages.StandardController stdController = new ApexPages.StandardController(clientAccount);
            BookingCreatorExt extension = new BookingCreatorExt(stdController);
            PageReference pageRef = Page.BookingCreator;
            Test.setCurrentPage(pageRef);
            ApexPages.currentPage().getParameters().put('jsonString',jsonString);
            extension.saveData();
        Test.stopTest();

        List<Booking__c> bookings = [SELECT Id FROM Booking__c WHERE PO_Number__c = '1234'];
        System.assertEquals(2, bookings.size());
    }

    /*
    * @method saveData
    * @case when creating 10 row with all columns correctly populated
    * @result expect 10 bookings to have been created
    */
    @isTest
    static void test_CreateOnHoldBooking() {
        Account clientAccount = [SELECT Id FROM Account WHERE Name = 'TestDataFactoryClient'];
        List<Instance__c> instanceList = [SELECT Id FROM Instance__c ORDER BY Instance_Name__c ASC];
        List<Order> orderList = [SELECT Id FROM Order ORDER BY Name ASC];
        for (Order order : orderList) {
            order.Status = 'Activated';
        }
        update orderList;
        
        List<Account> studentAccountList = [SELECT Id FROM Account WHERE FirstName LIKE 'TestDataFactoryStudent%'];
        Set<Id> studentIds = new Set<Id>();
        for (Account acc : studentAccountList) {
            studentIds.add(acc.Id);
        }
        List<Hub_Account__c> hubAccountList = [SELECT Id FROM Hub_Account__c WHERE Student__c IN: studentIds];

        String jsonString = '[';
        for(Integer i=0;i<2;i++){
            jsonString += '["' + studentAccountList.get(i).Id + '","' + hubAccountList.get(i).Id + '","' + instanceList.get(i).Id + '","' + orderList.get(i).Id + '","1234","On Hold","Deferral","true"],';
        }

        jsonString = jsonString.removeEnd(',');
        jsonString += ']';
        System.debug('@@jsonString@'+jsonString);

        Test.startTest();
            ApexPages.StandardController stdController = new ApexPages.StandardController(clientAccount);
            BookingCreatorExt extension = new BookingCreatorExt(stdController);
            PageReference pageRef = Page.BookingCreator;
            Test.setCurrentPage(pageRef);
            ApexPages.currentPage().getParameters().put('jsonString',jsonString);
            extension.saveData();
        Test.stopTest();

        List<Booking__c> bookings = [SELECT Id FROM Booking__c WHERE PO_Number__c = '1234'];
        System.assertEquals(2, bookings.size());
    }

    /*
    * @method buildEmail
    * @case when creating 1 columns with the instance column set as null
    * @result expect an email to have been sent to report the error
    */
    @isTest
    static void test_CreateInvalidBooking() {
        Account clientAccount = [SELECT Id FROM Account WHERE Name = 'TestDataFactoryClient'];
        Account account = [SELECT Id FROM Account WHERE FirstName = 'TestDataFactoryStudent1' LIMIT 1];
        Hub_Account__c hubAccount = [SELECT Id FROM Hub_Account__c WHERE Student__c =: account.Id];
        Order order = [SELECT Id FROM Order LIMIT 1];
        order.Status = 'Activated';
        update order;

        /* START OF - Changes made by David Lovejoy - 04/12/2020 - BPP-11720 */
        String jsonString = '[["' + account.Id + '","' + hubAccount.Id + '",null,"' + order.Id + '","1234","Confirmed","","false"]]';
        /* END OF - Changes made by David Lovejoy */

        BookingCreatorExt extension;

        Test.startTest();
            ApexPages.StandardController stdController = new ApexPages.StandardController(account);
            extension = new BookingCreatorExt(stdController);
            PageReference pageRef = Page.BookingCreator;
            Test.setCurrentPage(pageRef);
            ApexPages.currentPage().getParameters().put('jsonString',jsonString);
            extension.saveData();
        Test.stopTest();

        System.assertEquals(1, extension.messagesSent);
    }

    /*
    * @case when creating two test Bookings without activating the Orders
    * @result expect an email to have been sent to report the error
    */
    @isTest
    static void test_CreateInactiveBooking() {
        Account clientAccount = [SELECT Id FROM Account WHERE Name = 'TestDataFactoryClient'];
        List<Instance__c> instanceList = [SELECT Id FROM Instance__c ORDER BY Instance_Name__c ASC];
        List<Order> orderList = [SELECT Id FROM Order ORDER BY Name ASC];
        
        List<Account> studentAccountList = [SELECT Id FROM Account WHERE FirstName LIKE 'TestDataFactoryStudent%'];
        Set<Id> studentIds = new Set<Id>();
        for (Account acc : studentAccountList) {
            studentIds.add(acc.Id);
        }
        List<Hub_Account__c> hubAccountList = [SELECT Id FROM Hub_Account__c WHERE Student__c IN: studentIds];

        String jsonString = '[';
        for(Integer i=0;i<2;i++){
            jsonString += '["' + studentAccountList.get(i).Id + '","' + hubAccountList.get(i).Id + '","' + instanceList.get(i).Id + '","' + orderList.get(i).Id + '","1234","","","false"],';
        }

        jsonString = jsonString.removeEnd(',');
        jsonString += ']';
        System.debug('@@jsonString@'+jsonString);

        BookingCreatorExt extension;

        Test.startTest();
            ApexPages.StandardController stdController = new ApexPages.StandardController(clientAccount);
            extension = new BookingCreatorExt(stdController);
            PageReference pageRef = Page.BookingCreator;
            Test.setCurrentPage(pageRef);
            ApexPages.currentPage().getParameters().put('jsonString',jsonString);
            extension.saveData();
        Test.stopTest();

        System.assertEquals(1, extension.messagesSent);
    }
    
    @isTest
    static void test_CreateInvalidInstanceBooking() {
        Account clientAccount = [SELECT Id FROM Account WHERE Name = 'TestDataFactoryClient'];
        Account account = [SELECT Id FROM Account WHERE FirstName = 'TestDataFactoryStudent1' LIMIT 1];
        Hub_Account__c hubAccount = [SELECT Id FROM Hub_Account__c WHERE Student__c =: account.Id];
        List<Instance__c> instanceList = [SELECT Id FROM Instance__c ORDER BY Instance_Name__c ASC];
        Instance__c instance = instanceList.get(1);
        Order order = [SELECT Id FROM Order LIMIT 1];
        order.Status = 'Activated';
        update order;

        /* START OF - Changes made by David Lovejoy - 04/12/2020 - BPP-11720 */
        String jsonString = '[["' + account.Id + '","' + hubAccount.Id + '","' + instance.Id + '","' + order.Id + '","1234","On Hold","test","false"]]';
        /* END OF - Changes made by David Lovejoy */

        BookingCreatorExt extension;

        Test.startTest();
            ApexPages.StandardController stdController = new ApexPages.StandardController(account);
            extension = new BookingCreatorExt(stdController);
            PageReference pageRef = Page.BookingCreator;
            Test.setCurrentPage(pageRef);
            ApexPages.currentPage().getParameters().put('jsonString',jsonString);
            extension.saveData();
        Test.stopTest();

        System.assertEquals(1, extension.messagesSent);
    }
}