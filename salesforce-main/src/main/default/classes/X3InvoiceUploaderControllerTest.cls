@isTest
private class X3InvoiceUploaderControllerTest {
    @testSetup
    static void setUp() {
        Account account = new Account(
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName()
                .get('Student Account')
                .getRecordTypeId(),
            FirstName = 'Test',
            LastName = 'Tester',
            Salutation = 'Mr',
            Personal_Email__pc = 'test@bpp.com',
            Preferred_Email__pc = 'test@bpp.com'
        );
        insert account;

        insert new Stock_Site__c(Name = 'UK Warehouse');

        Pricebook2 testPriceBook = new Pricebook2(Name = 'Standard Price Book', IsActive = true);
        insert testPriceBook;

        Product2 testProduct = new Product2(Name = 'X3 Migrated Product', BPP_ProductFactoryID__c = 'test-123');
        insert testProduct;

        insert new PricebookEntry(
            IsActive = true,
            Product2Id = testProduct.Id,
            UnitPrice = 10,
            Pricebook2Id = Test.getStandardPricebookId()
        );
    }

    @isTest
    static void test_X3InvoiceUploaderController() {
        StaticResource x3ImportTest = [SELECT Id, Body FROM StaticResource WHERE Name = 'X3Import_InvoiceTest'];
        X3InvoiceUploaderController x3IUC = new X3InvoiceUploaderController();
        x3IUC.contentFile = x3ImportTest.Body;
        x3IUC.readX3Records();
        x3IUC.checkForOrders();
        x3IUC.checkForInvoices();
        x3IUC.updateInvoiceAndInvoiceLines();
        x3IUC.getordersToInsert();
        x3IUC.getnewOrders();
        x3IUC.getupdatedOrders();
        x3IUC.getupdatedInvoices();
    }

    @isTest
    static void test_createInvoiceBatch() {
        // Retrieve Test Account and Test (Non-default) Pricebook for use in creating Order
        Account testAccount = [SELECT Id FROM Account WHERE LastName = 'Tester' LIMIT 1];
        Pricebook2 testPricebook = [SELECT Id FROM Pricebook2 WHERE Name = 'Standard Price Book' LIMIT 1];

        Order testOrder = TestDataFactory.createOrder(false, 0, testAccount, testPriceBook);
        testOrder.BPP_Internal_Comments__c = 'Migrated from X3';
        insert testOrder;

        Test.startTest();
        String CRON_EXP = '0 0 0 3 9 ? 2025';
        System.schedule('CreateInvoiceBatch', CRON_EXP, new CreateInvoiceBatch());
        Test.stopTest();
    }

    @isTest
    static void test_postInvoiceBatch() {
        // Retrieve Test Account for use in creating Invoice
        Account testAccount = [SELECT Id FROM Account WHERE LastName = 'Tester' LIMIT 1];

        blng__Invoice__c testInvoice = TestDataFactory.createInvoice(false, testAccount);
        testInvoice.blng__InvoiceStatus__c = 'Draft';
        testInvoice.Created_via_X3_Migration__c = true;
        testInvoice.External_Invoice_Number__c = 'qwertyuiop';
        insert testInvoice;

        Test.startTest();
        String CRON_EXP = '0 0 0 3 9 ? 2025';
        System.schedule('PostInvoiceBatch', CRON_EXP, new PostInvoiceBatch());
        Test.stopTest();
    }
}
