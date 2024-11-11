/**
 *  @who    David Lovejoy <davidlovejoy@bpp.com>
 *  @when   17/11/2021
 *  @what   Test class to cover the CreditNoteBackingDetailGenerator class
 */
@isTest
public class CreditNoteBackingDetailGeneratorTest {
    @testSetup
    static void makeData() {
        Authorisation_Token__c authToken = TestDataFactory.createAuthorisationToken(true);

        Account account = TestDataFactory.createAccount(false, false, null, 0);
        account.Name = 'TestDataFactoryClient';
        insert account;

        Account student = TestDataFactory.createAccount(false, true, account.Id, 1);
        student.Business_Unit__pc = 'Test Unit';
        student.Client__c = account.Id;
        student.Cost_Centre_Number__pc = 'Test Cost Centre';
        student.FirstName = 'TestDataFactoryStudent';
        insert student;

        country_list__c cntry = CreateTestData.createCountry1();

        Address__c addressAccount = TestDataFactory.createAddress(true, 0, account, cntry, true, false);
        Order order = TestDataFactory.createOrder(true, 0, account, null, addressAccount);

        blng__BillingRule__c billingRule = TestDataFactory.createBillingRule(false);
        billingRule.Name = 'Common Billing Rule';
        insert billingRule;

        blng__FinanceBook__c billingFinanceBook = TestDataFactory.createBillingFinanceBook(true);
        blng__BillingTreatment__c billingTreatment = TestDataFactory.createBillingTreatment(
            true,
            billingRule,
            billingFinanceBook
        );
        blng__RevenueRecognitionRule__c revenueRecognitionRule = TestDataFactory.createRevenueRecognitionRule(true);

        blng__TaxRule__c taxRule = TestDataFactory.createTaxRule(false);
        taxRule.Name = 'Common Tax Rule';
        insert taxRule;

        Product2 product = TestDataFactory.createProduct(false, 0, billingRule, revenueRecognitionRule, taxRule);
        product.SBQQ__ChargeType__c = 'Usage';
        insert product;

        PricebookEntry pricebookEntry = TestDataFactory.createPricebookEntry(true, product, null);

        OrderItem parentOrderLine = TestDataFactory.createOrderLine(
            true,
            order,
            product,
            null,
            priceBookEntry,
            billingRule,
            revenueRecognitionRule,
            taxRule,
            ''
        );
        OrderItem materialOrderLine = TestDataFactory.createOrderLine(
            true,
            order,
            product,
            parentOrderLine,
            priceBookEntry,
            billingRule,
            revenueRecognitionRule,
            taxRule,
            'Materials'
        );

        Instance__c instance = TestDataFactory.createInstance(true, 0, product);

        blng__UsageSummary__c usageSummary = TestDataFactory.createBookingSummary(false, materialOrderLine);
        usageSummary.blng__Order__c = order.Id;
        insert usageSummary;

        insert TestDataFactory.buildDefaultLegalEntity();
    }

    @isTest
    static void itShouldCreateCreditNoteBackingDetail() {
        Instance__c instance = [SELECT Id FROM Instance__c];
        Account clientAccount = [SELECT Id FROM Account WHERE Name = 'TestDataFactoryClient'];
        Account studentAccount = [SELECT Id FROM Account WHERE FirstName = 'TestDataFactoryStudent'];
        Product2 product = [SELECT Id FROM Product2];
        blng__UsageSummary__c usageSummary = [SELECT Id, Name FROM blng__UsageSummary__c];
        Order order = [SELECT Id FROM Order];

        OrderItem orderItem = [SELECT Id FROM OrderItem WHERE Family__c = 'Materials'];
        orderItem.blng__BillableUnitPrice__c = 10;
        update orderItem;

        order.Status = 'Activated';
        update order;

        Booking__c booking = new Booking__c(
            Account__c = clientAccount.Id,
            Instance__c = instance.Id,
            Status__c = 'Cancelled',
            Status_Reason__c = 'Internal Error',
            BPP_Cancellation_Action__c = 'Don\'t Credit Fulfilled Materials',
            BPP_Cancellation_Terms__c = 'Outside',
            Order__c = order.Id,
            Student__c = studentAccount.Id,
            PO_Number__c = 'Test PO Number'
        );

        Test.startTest();
        insert booking;
        Test.setMock(HttpCalloutMock.class, new AWSCalloutMock());

        Booking_Line__c bookingLine = [SELECT Id FROM Booking_Line__c];
        bookingLine.blng_UsageSummary__c = usageSummary.Id;
        bookingLine.blng_MatchingId__c = TestDataFactory.BOOKING_SUMMARY_MATCHING_ID;
        update bookingLine;

        blng__Usage__c usage = new blng__Usage__c(
            blng__Account__c = clientAccount.Id,
            blng__Order__c = order.Id,
            blng__OrderProduct__c = orderItem.Id,
            blng__Quantity__c = 1,
            blng__Subtotal__c = 10,
            blng__UnitPrice__c = 10,
            blng__StartDateTime__c = System.today(),
            blng__EndDateTime__c = System.today(),
            blng__Status__c = 'Processed',
            blng__UsageSummary__c = usageSummary.Id,
            blng__MatchingId__c = usageSummary.Name,
            Booking_Line__c = bookingLine.Id,
            Booking__c = booking.Id,
            Instance__c = instance.Id
        );
        insert usage;

        usage.blng__MatchingId__c = TestDataFactory.BOOKING_SUMMARY_MATCHING_ID;
        update usage;

        blng__Invoice__c invoice = new blng__Invoice__c(
            blng__Account__c = clientAccount.Id,
            blng__InvoiceDate__c = System.today(),
            Customer_PO_Number__c = 'Test PO'
        );
        insert invoice;

        blng__InvoiceLine__c invoiceLine = new blng__InvoiceLine__c(
            blng__Invoice__c = invoice.Id,
            blng__UsageSummary__c = usageSummary.Id,
            blng__Product__c = product.Id
        );
        insert invoiceLine;

        invoice.blng__InvoiceStatus__c = 'Posted';
        update invoice;

        blng__CreditNote__c creditNote = new blng__CreditNote__c(
            BPP_Booking__c = booking.Id,
            blng__Status__c = 'Draft',
            BPP_Credit_Note_Reason__c = 'Automated Credit',
            blng__CreditNoteDate__c = Date.today(),
            blng__Account__c = clientAccount.Id
        );
        insert creditNote;

        blng__CreditNoteLine__c creditNoteLine = new blng__CreditNoteLine__c(
            blng__StartDate__c = Date.today(),
            blng__Subtotal__c = 30,
            blng__TotalAmount__c = 30,
            blng__Status__c = 'Draft',
            blng__Product__c = product.Id,
            blng__CreditNote__c = creditNote.Id,
            blng__InvoiceLine__c = invoiceLine.Id
        );
        insert creditNoteLine;

        List<Credit_Note_Backing_Detail__c> creditNoteBackingDetailList = [
            SELECT
                Id,
                Customer_PO_Number__c,
                Material_Price__c,
                Tuition_Price__c,
                Business_Unit__c,
                Cost_Centre__c,
                Student_Name__c,
                Course_Name__c
            FROM Credit_Note_Backing_Detail__c
        ];
        Assert.areEqual(
            1,
            creditNoteBackingDetailList.size(),
            'One Credit Note Backing Detail record should have been created.'
        );

        Credit_Note_Backing_Detail__c cnbd = creditNoteBackingDetailList.get(0);
        Assert.areEqual(
            'Test Unit',
            cnbd.Business_Unit__c,
            'Credit Note Backing Detail Business Unit should equal "Test Unit".'
        );
        Assert.areEqual(
            'Test Cost Centre',
            cnbd.Cost_Centre__c,
            'Credit Note Backing Detail Cost Centre should equal "Test Cost Centre".'
        );
        Assert.areEqual(
            'Test instance 0',
            cnbd.Course_Name__c,
            'Credit Note Backing Detail Course Name should equal "Test instance 0".'
        );
        Assert.areEqual(
            'Test PO Number',
            cnbd.Customer_PO_Number__c,
            'Credit Note Backing Detail PO Number should equal "Test PO Number".'
        );
        Assert.areEqual(
            'TestDataFactoryStudent Student',
            cnbd.Student_Name__c,
            'Credit Note Backing Detail Student Name should equal "TestDataFactoryStudent Student".'
        );
        Assert.areEqual(10, cnbd.Material_Price__c, 'Credit Note Backing Detail Material Price should equal £10.');
        Assert.areEqual(0, cnbd.Tuition_Price__c, 'Credit Note Backing Detail Tuition Price should equal £0.');

        Test.stopTest();
    }
}
