@isTest
private class StudentProductSyncTest {
    @TestSetup
    private static void setup(){
        blng__BillingRule__c billingRule = TestDataFactory.createBillingRule(true);
        blng__FinanceBook__c billingFinanceBook = TestDataFactory.createBillingFinanceBook(true);
        blng__RevenueRecognitionRule__c revenueRecognitionRule = TestDataFactory.createRevenueRecognitionRule(true);
        blng__TaxRule__c taxRule = TestDataFactory.createTaxRule(true);
        Id recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Student Account').getRecordTypeId();

        Account account = new Account(
            RecordTypeId = recordTypeId,
            FirstName = 'Test',
            LastName = 'Tester',
            Salutation = 'Mr',
            Personal_Email__pc = 'test@bpp.com',
            Preferred_Email__pc = 'test@bpp.com'
        );

        insert account;

        insert new Hub_Account__c(
            Student__c = account.Id,
            Auth0_Id__c = 'sub|12345',
            Hub_Username__c = 'testuser@bpp.com'
        );

        Product2 product = new Product2(
            Name = 'Test Course',
            BPP_ProductFactoryID__c = 'test-123'
        );

        insert product;

        PricebookEntry pbentry =  new PricebookEntry(
            IsActive = true,
            Product2Id = product.Id,
            UnitPrice = 10,
            Pricebook2Id = Test.getStandardPricebookId()
        );
        insert pbentry;

        Instance__c instance = new Instance__c(
            Product__c = product.Id,
            Instance_ID__c = 'test-321'
        );

        insert instance;

        Stock_Site__c site = new Stock_Site__c(Name = 'Test Site');

        insert site;

        Order order = new Order(
            AccountId = account.Id,
            Name = 'Test order',
            Status = 'Draft',
            EffectiveDate = Date.today(),
            blng__BillingDayOfMonth__c = '1',
            Billing_Mode__c = 'Billed in Salesforce',
            Pricebook2Id = Test.getStandardPricebookId(),
            Stock_Site__c = site.Id
        );

        insert order;

        OrderItem orderLine = new OrderItem (
            OrderId = order.Id,
            PricebookEntryId = pbentry.Id,
            SBQQ__Activated__c = true,
            Product2Id = product.Id,
            SBQQ__ChargeType__c = 'One-Time',
            UnitPrice = 10,
            blng__BillingRule__c = billingRule.Id,
            blng__RevenueRecognitionRule__c = revenueRecognitionRule.Id,
            blng__TaxRule__c = taxRule.Id,
            Quantity = 1,
            SBQQ__QuotedQuantity__c=1
        );

        insert orderLine;

        order.Status = 'Activated';
        update order;   

        Booking__c booking = new Booking__c(
            Student__c = account.Id,
            Order__c = order.id,
            Instance__c = instance.Id
        );

        insert booking;

        insert new Student_Course__c(
            Student__c = account.Id,
            Booking__c = booking.Id
        );

        insert new Student_Course__c(
            Student__c = account.Id,
            Booking__c = booking.Id
        );
    }

    @isTest
    private static void itShouldSerializeFromAStudentCourse() {
        // GIVEN we have student courses
        // WHEN this is passed to the serializer
        StudentProductSync sync = new StudentProductSync();
        
        for (Student_Course__c course : [SELECT Student__c FROM Student_Course__c]) {
            sync.addRecord(course);
        }
        
        List<Map<String, Object>> output = sync.serialize();
        List<String> authIds = (List<String>)output.get(0).get('userIds');
        List<Map<String, Object>> products = (List<Map<String, Object>>)output.get(0).get('products');

        // THEN I expect it to be able to fetch all the details for this event
        Assert.areEqual(1, authIds.size());
        Assert.areEqual(1, products.size());

        //AND that only one event to be produced as the two student courses share an instance
        Assert.areEqual(1, output.size());
    }
}