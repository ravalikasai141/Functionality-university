@isTest
private class StudentCourseBatchTest {
    @TestSetup
    private static void setup() {
        Authorisation_Token__c authToken = TestDataFactory.createAuthorisationToken(true);
        blng__BillingRule__c billingRule = TestDataFactory.createBillingRule(true);
        blng__FinanceBook__c billingFinanceBook = TestDataFactory.createBillingFinanceBook(true);
        blng__RevenueRecognitionRule__c revenueRecognitionRule = TestDataFactory.createRevenueRecognitionRule(true);
        blng__TaxRule__c taxRule = TestDataFactory.createTaxRule(true);
        Id recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
            .get('Student_Account')
            .getRecordTypeId();
        Id bookingTypeId = Schema.SObjectType.Booking__c.getRecordTypeInfosByDeveloperName()
            .get('Booking')
            .getRecordTypeId();

        Account account = new Account(
            RecordTypeId = recordTypeId,
            FirstName = 'Test',
            LastName = 'Tester',
            Salutation = 'Mr',
            PersonEmail = 'test@bpp.com',
            Preferred_Email__pc = 'Personal',
            Personal_Email__pc = 'test@bpp.com'
        );

        insert account;

        Product2 product = new Product2(Name = 'Test Course', Qualification__c = 'ACCA');

        Product2 product2 = new Product2(Name = 'Test Course 2', Qualification__c = 'ACCA');

        insert new List<Product2>{ product, product2 };

        PricebookEntry pbentry = new PricebookEntry(
            IsActive = true,
            Product2Id = product.Id,
            UnitPrice = 10,
            Pricebook2Id = Test.getStandardPricebookId()
        );
        PricebookEntry pbentry2 = new PricebookEntry(
            IsActive = true,
            Product2Id = product2.Id,
            UnitPrice = 10,
            Pricebook2Id = Test.getStandardPricebookId()
        );
        insert new List<PricebookEntry>{ pbentry, pbentry2 };

        Instance__c instance = new Instance__c(Product__c = product.Id, Instance_ID__c = 'test-321');
        Instance__c instance2 = new Instance__c(Product__c = product.Id, Instance_ID__c = 'test-123');
        Instance__c instance3 = new Instance__c(Product__c = product2.Id, Instance_ID__c = 'test-654');

        insert new List<Instance__c>{ instance, instance2, instance3 };

        Stock_Site__c site = new Stock_Site__c(Name = 'Test Site');

        Stock_Site__c site2 = new Stock_Site__c(Name = 'Test Site 2');

        insert new List<Stock_Site__C>{ site, site2 };

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

        Order order2 = new Order(
            AccountId = account.Id,
            Name = 'Test order',
            Status = 'Draft',
            EffectiveDate = Date.today(),
            blng__BillingDayOfMonth__c = '1',
            Billing_Mode__c = 'Billed in Salesforce',
            Pricebook2Id = Test.getStandardPricebookId(),
            Stock_Site__c = site2.Id
        );

        insert new List<Order>{ order, order2 };

        OrderItem orderLine = new OrderItem(
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
            SBQQ__QuotedQuantity__c = 1
        );

        OrderItem orderLine2 = new OrderItem(
            OrderId = order2.Id,
            PricebookEntryId = pbentry2.Id,
            SBQQ__Activated__c = true,
            Product2Id = product2.Id,
            SBQQ__ChargeType__c = 'One-Time',
            UnitPrice = 10,
            blng__BillingRule__c = billingRule.Id,
            blng__RevenueRecognitionRule__c = revenueRecognitionRule.Id,
            blng__TaxRule__c = taxRule.Id,
            Quantity = 1,
            SBQQ__QuotedQuantity__c = 1
        );

        insert new List<OrderItem>{ orderLine, orderLine2 };

        order.Status = 'Activated';
        update order;

        order2.Status = 'Activated';
        update order2;

        insert new List<Booking__c>{
            new Booking__c(
                Student__c = account.Id,
                RecordTypeId = bookingTypeId,
                Instance__c = instance.Id,
                Order__c = order.Id,
                Status__c = 'Confirmed'
            ),
            new Booking__c(
                Student__c = account.Id,
                RecordTypeId = bookingTypeId,
                Instance__c = instance2.Id,
                Order__c = order.Id,
                Status__c = 'Confirmed'
            ),
            new Booking__c(
                Student__c = account.Id,
                RecordTypeId = bookingTypeId,
                Instance__c = instance3.Id,
                Order__c = order2.Id,
                Status__c = 'Confirmed'
            )
        };
        Test.setMock(HttpCalloutMock.class, new AWSCalloutMock());
    }

    @isTest
    private static void itShouldCreateStudentCourses() {
        // GIVEN we have a confirmed booking
        delete [SELECT Id FROM Student_Course__c];
        // WHEN the batch runs
        System.Test.startTest();

        Database.executeBatch(new StudentCoursesBatch());

        System.Test.stopTest();

        // THEN I expect it to create a student course
        Account account = [SELECT Id FROM Account WHERE LastName = 'Tester'];
        Student_Course__c course = [SELECT Instance_Id__c FROM Student_Course__c WHERE Student__c = :account.Id];

        Assert.areEqual('test-321', course.Instance_Id__c, 'Student Course Instance Id should equal "test-321".');
    }

    @isTest
    private static void itShouldNotCreateStudentCourseWhenTheyExist() {
        // GIVEN we have confirmed bookings
        // AND these bookings have identical Student and Qualification values
        // WHEN the batch runs
        System.Test.startTest();
        Account account = [SELECT Id FROM Account WHERE LastName = 'Tester'];
        List<Student_Course__c> existingCourses = [SELECT Id FROM Student_Course__c WHERE Student__c = :account.Id];
        delete existingCourses;

        Database.executeBatch(new StudentCoursesBatch());

        System.Test.stopTest();

        // THEN I expect it to only create one student course
        List<Student_Course__c> courses = [SELECT Id FROM Student_Course__c WHERE Student__c = :account.Id];

        Assert.areEqual(1, courses.size(), 'One Student Course record should have been created.');
    }
}
