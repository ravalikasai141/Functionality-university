@isTest
private class BookingTriggerHandlerTest {
    private static Id bookingRT = Schema.SObjectType.Booking__c.getRecordTypeInfosByDeveloperName()
        .get('Booking')
        .getRecordTypeId();

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

        List<Account> accounts = new List<Account>{
            new Account(
                RecordTypeId = recordTypeId,
                FirstName = 'Test',
                LastName = 'Tester',
                Salutation = 'Mr',
                PersonEmail = 'test@bpp.com',
                Preferred_Email__pc = 'Personal',
                Personal_Email__pc = 'test@bpp.com'
            ),
            new Account(
                RecordTypeId = recordTypeId,
                FirstName = 'Test',
                LastName = 'Tester 2',
                Salutation = 'Mr',
                PersonEmail = 'test2@bpp.com',
                Preferred_Email__pc = 'Personal',
                Personal_Email__pc = 'test2@bpp.com'
            )
        };

        insert accounts;

        Product2 product = new Product2(
            Name = 'Test Course',
            BPP_ProductFactoryID__c = 'test-123',
            Qualification__c = 'Apprenticeship'
        );

        Product2 product2 = new Product2(
            Name = 'Test Course 2',
            BPP_ProductFactoryID__c = 'test-123',
            Qualification__c = 'Apprenticeship'
        );

        insert new List<Product2>{ product, product2 };

        PricebookEntry pbentry = new PricebookEntry(
            IsActive = true,
            Product2Id = product.Id,
            UnitPrice = 10,
            Pricebook2Id = Test.getStandardPricebookId()
        );
        insert pbentry;

        Instance__c instance = new Instance__c(Product__c = product.Id, Instance_ID__c = 'test-321');

        Instance__c instance2 = new Instance__c(Product__c = product2.Id, Instance_ID__c = 'test-123');

        insert new List<Instance__c>{ instance, instance2 };

        Stock_Site__c site = new Stock_Site__c(Name = 'Test Site');

        insert site;

        List<Order> orders = new List<Order>{
            new Order(
                AccountId = accounts[0].Id,
                Name = 'Test order',
                Status = 'Draft',
                EffectiveDate = Date.today(),
                blng__BillingDayOfMonth__c = '1',
                Billing_Mode__c = 'Billed in Salesforce',
                Pricebook2Id = Test.getStandardPricebookId(),
                Stock_Site__c = site.Id
            ),
            new Order(
                AccountId = accounts[1].Id,
                Name = 'Test order 2',
                Status = 'Draft',
                EffectiveDate = Date.today(),
                blng__BillingDayOfMonth__c = '1',
                Billing_Mode__c = 'Billed in Salesforce',
                Pricebook2Id = Test.getStandardPricebookId(),
                Stock_Site__c = site.Id
            )
        };

        insert orders;

        List<OrderItem> orderLines = new List<OrderItem>{
            new OrderItem(
                OrderId = orders[0].Id,
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
            ),
            new OrderItem(
                OrderId = orders[1].Id,
                PricebookEntryId = pbentry.Id,
                SBQQ__Activated__c = true,
                Product2Id = product2.Id,
                SBQQ__ChargeType__c = 'One-Time',
                UnitPrice = 10,
                blng__BillingRule__c = billingRule.Id,
                blng__RevenueRecognitionRule__c = revenueRecognitionRule.Id,
                blng__TaxRule__c = taxRule.Id,
                Quantity = 1,
                SBQQ__QuotedQuantity__c = 1
            )
        };

        insert orderLines;

        orders[0].Status = 'Activated';
        orders[1].Status = 'Activated';
        update orders;
    }

    @isTest
    private static void itShouldCreateAStudentCourse() {
        Account account = [SELECT Id FROM Account WHERE LastName = 'Tester'];
        Instance__c instance = [SELECT Id FROM Instance__c WHERE Instance_ID__c = 'test-321'];
        Order order = [SELECT Id FROM Order WHERE Name = 'Test Order'];

        // GIVEN I create a new booking
        // WHEN the trigger runs
        System.Test.startTest();
        Booking__c booking = new Booking__c(
            Student__c = account.Id,
            Instance__c = instance.Id,
            Order__c = order.Id,
            Status__c = 'Confirmed',
            RecordTypeId = bookingRT
        );

        insert booking;
        Test.setMock(HttpCalloutMock.class, new AWSCalloutMock());
        System.Test.stopTest();

        // THEN I expect it to create a student course
        Student_Course__c course = [SELECT Booking__c FROM Student_Course__c WHERE Student__c = :account.Id];

        Assert.areEqual(
            booking.Id,
            course.Booking__c,
            'Student Course Booking lookup field should be populated with newly created Booking.'
        );
    }

    @isTest
    private static void itShouldNotCreateAStudentCourseIfOneExists() {
        Account account = [SELECT Id FROM Account WHERE LastName = 'Tester'];
        Instance__c instance = [SELECT Id FROM Instance__c WHERE Instance_ID__c = 'test-321'];
        Order order = [SELECT Id FROM Order WHERE Name = 'Test Order'];

        Booking__c booking = new Booking__c(
            Student__c = account.Id,
            Instance__c = instance.Id,
            Order__c = order.Id,
            Status__c = 'Confirmed',
            RecordTypeId = bookingRT
        );

        insert booking;
        Test.setMock(HttpCalloutMock.class, new AWSCalloutMock());

        // GIVEN I update a booking
        // AND the student course already exists
        // WHEN the trigger runs
        System.Test.startTest();

        update booking;

        System.Test.stopTest();

        // THEN I expect no new student courses
        List<Student_Course__c> courses = [SELECT Id FROM Student_Course__c WHERE Student__c = :account.Id];

        Assert.areEqual(1, courses.size(), 'One Student Course record should have been created.');
    }

    @isTest
    private static void itShouldNotCreateDuplicates() {
        // GIVEN some matching bookings
        Instance__c instance = [SELECT Id FROM Instance__c WHERE Instance_ID__c = 'test-321'];
        List<Order> orders = [SELECT Id, accountId FROM Order];

        List<Booking__c> bookings = new List<Booking__c>{
            new Booking__c(
                Student__c = orders[0].accountId,
                Instance__c = instance.Id,
                Order__c = orders[0].Id,
                Status__c = 'Confirmed',
                RecordTypeId = bookingRT
            ),
            new Booking__c(
                Student__c = orders[0].accountId,
                Instance__c = instance.Id,
                Order__c = orders[0].Id,
                Status__c = 'Confirmed',
                RecordTypeId = bookingRT
            ),
            new Booking__c(
                Student__c = orders[1].accountId,
                Instance__c = instance.Id,
                Order__c = orders[1].id,
                Status__c = 'Confirmed',
                RecordTypeId = bookingRT
            )
        };

        // WHEN the booking is inserted
        System.Test.startTest();

        insert bookings;
        Test.setMock(HttpCalloutMock.class, new AWSCalloutMock());

        System.Test.stopTest();

        // THEN only one student course for each student is created
        List<AggregateResult> studentCourses = [
            SELECT COUNT(id) num, Student__c
            FROM Student_Course__c
            GROUP BY Student__c
        ];
        Assert.areEqual(2, studentCourses.size(), 'Two Student Course records should have been created.');
        Assert.areEqual(
            1,
            studentCourses[0].get('num'),
            'One Student Course should have been created for Student "Tester".'
        );
        Assert.areEqual(
            1,
            studentCourses[1].get('num'),
            'One Student Course should have been created for Student "Tester 2".'
        );
    }

    private static void itShouldDeleteAStudentCourseWhenDeleted() {
        Account account = [SELECT Id FROM Account WHERE LastName = 'Tester'];
        Instance__c instance = [SELECT Id FROM Instance__c WHERE Instance_ID__c = 'test-321'];
        Order order = [SELECT Id FROM Order WHERE Name = 'Test Order'];

        Booking__c booking = new Booking__c(
            Student__c = account.Id,
            Instance__c = instance.Id,
            Order__c = order.Id,
            Status__c = 'Confirmed',
            RecordTypeId = bookingRT
        );

        insert booking;
        Test.setMock(HttpCalloutMock.class, new AWSCalloutMock());

        // GIVEN I delete an existing booking
        // WHEN the trigger runs
        System.Test.startTest();

        delete booking;

        System.Test.stopTest();

        // THEN I expect it to delete the student course tied to this record
        List<Student_Course__c> courses = [SELECT Id FROM Student_Course__c WHERE Student__c = :account.Id];

        Assert.areEqual(0, courses.size(), 'Student Course record should be deleted.');
    }
}
