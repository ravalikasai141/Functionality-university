/**
 *  @who    Duy Vu <duy.vu@weare4c.com>
 *  @when   02/07/2020
 *  @what   Helper for InvoiceHeaderDetailsGenerator
 */
@isTest
public class InvoiceHeaderDetailsGeneratorTest {
    @TestSetup
    static void makeData(){
        Database.DMLOptions dbDML = new Database.DMLOptions(); 
        dbDML.DuplicateRuleHeader.allowSave = true;
        dbDML.DuplicateRuleHeader.runAsCurrentUser = true;
        
        Account account = TestDataFactory.createAccount(false, false, null, 0);
        account.Billing_Frequency__c = 'Monthly';
        account.Billing_Type__c = 'In Arrears';
        Database.insert(account, dbDML);
        
        Account student = TestDataFactory.createAccount(false, true, account.Id, 1);
        student.Cost_Centre_Number__pc = 'CC# 00000';
        student.Client__c = account.Id;
        Database.insert(student, dbDML);
        
        country_list__c cntry = CreateTestData.createCountry1();
        
        Address__c addressAccount = TestDataFactory.createAddress(false, 0, account, cntry, true, false);
		Database.insert(addressAccount, dbDML);        
        
        Order order = TestDataFactory.createOrder(false, 1, account, null, addressAccount);
        order.SBQQ__PaymentTerm__c = 'Net 30';
        insert order;

        blng__BillingRule__c billingRule = TestDataFactory.createBillingRule(true);
        blng__FinanceBook__c billingFinanceBook = TestDataFactory.createBillingFinanceBook(true);
        blng__BillingTreatment__c billingTreatment = TestDataFactory.createBillingTreatment(true, billingRule, billingFinanceBook);
        blng__RevenueRecognitionRule__c revenueRecognitionRule = TestDataFactory.createRevenueRecognitionRule(true);
        blng__TaxRule__c taxRule = TestDataFactory.createTaxRule(true);
        
        Product2 product = TestDataFactory.createProduct(true,1,billingRule,revenueRecognitionRule,taxRule);
        PricebookEntry pricebookEntry = TestDataFactory.createPricebookEntry(true, product, null);

        OrderItem parentOrderLine = TestDataFactory.createOrderLine(true,order,product,null,priceBookEntry,billingRule,revenueRecognitionRule, taxRule,'');

        List<OrderItem> orderLines = new List<OrderItem>();
        orderLines.add(TestDataFactory.createOrderLine(false, order, product, parentOrderLine, priceBookEntry, billingRule, revenueRecognitionRule, taxRule, 'Materials'));
        orderLines.add(TestDataFactory.createOrderLine(false, order, product, parentOrderLine, priceBookEntry, billingRule, revenueRecognitionRule, taxRule, 'Session'));
        orderLines.add(TestDataFactory.createOrderLine(false, order, product, parentOrderLine, priceBookEntry, billingRule, revenueRecognitionRule, taxRule, 'Online Session'));
        insert orderLines;

        List<blng__UsageSummary__c> bookingSummaries = new List<blng__UsageSummary__c>();
        for(Integer i=0;i<orderLines.size();i++){
            blng__UsageSummary__c bookingSummary = TestDataFactory.createBookingSummary(false,orderLines.get(i));
            bookingSummary.blng__Order__c = order.Id;
            bookingSummaries.add(bookingSummary);
        }
        insert bookingSummaries;
        
        // create instance 
        Instance__c instance = TestDataFactory.createInstance(false, 1, product);
        instance.Instance_Name__c = 'TEST Instance';
        instance.Start_Date__c = Date.today();
        insert instance;

        order.Status = 'Activated';
        update order;
        
        Booking__c booking = TestDataFactory.createBooking(false, instance, order, student);
        booking.PO_Number__c = 'PO# 999';
        try {
            insert booking;
        } catch (DmlException e) {
            System.debug('error is ' + e.getMessage() + e.getCause());
        }

        List<Booking_Line__c> bookingLines = [SELECT Id, Batch_Processed__c FROM Booking_Line__c];
        for(Integer i = 0; i < bookingLines.size(); i++) {
            bookingLines.get(i).blng_OrderProduct__c = null;
            bookingLines.get(i).blng_MatchingId__c = String.valueOf(Math.random());
        }
        update bookingLines;

        BookingLineBatch testBatch = new BookingLineBatch('blng_StartDateTime__c','Batch_Processed__c', 'On_Hold__c', 'Cancelled');
        Database.executeBatch(testBatch);

        // Insert a Legal Entity
        insert TestDataFactory.buildDefaultLegalEntity();

        blng__Invoice__c invoice = new blng__Invoice__c();
        invoice.SFBD__HoldCollections__c = false;
        invoice.blng__Account__c = account.Id;
        invoice.blng__InvoiceDate__c = System.today();
        insert invoice;
    }

    @isTest
    static void createInvoiceHeaderDetails() {
        Test.startTest();
			blng__Invoice__c invoice = [SELECT Id, Name FROM blng__Invoice__c];
			List<blng__UsageSummary__c> bookingSummaries = [SELECT Id FROM blng__UsageSummary__c];
			List<blng__Usage__c> usageLines = [SELECT Id FROM blng__Usage__c];
			for(Integer i = 0; i < usageLines.size(); i++) {
				usageLines.get(i).blng__UsageSummary__c = bookingSummaries.get(i).Id;
			}
			update usageLines;
			System.debug('This is modified usageLines ' + usageLines);
			
			List<blng__InvoiceLine__c> invoiceLines = new List<blng__InvoiceLine__c>();
			for (blng__UsageSummary__c bookingSummary : bookingSummaries) {
				blng__InvoiceLine__c invoiceLine = new blng__InvoiceLine__c();
				invoiceLine.blng__Invoice__c = invoice.Id;
				invoiceLine.blng__UsageSummary__c = bookingSummary.Id;
                invoiceLine.PaymentTerm__c = 'Net 30';
				invoiceLines.add(invoiceLine);
			}
			// Test for One-time charged product (eg.Postage)
			blng__InvoiceLine__c invoiceLine = new blng__InvoiceLine__c();
			invoiceLine.blng__Invoice__c = invoice.Id;
			invoiceLines.add(invoiceLine);
			insert invoiceLines;
			
			List<Invoiceheader_details__c> invoiceHeaderDetails = [SELECT Id, Customer_POnumber__c, Material_Price__c,Tuition_Price__c, Cost_Centre__c, Student_Name__c, Course_Name__c FROM Invoiceheader_details__c];
			// System.debug('Invoiceheader Details' + invoiceHeaderDetails);
			
			System.assertEquals(1, invoiceHeaderDetails.size(), 'There should be 1 InvoiceheaderDetail object created');
			Invoiceheader_details__c invoiceHeaderDetail = invoiceHeaderDetails.get(0);
			System.assertEquals('PO# 999', invoiceHeaderDetail.Customer_POnumber__c, 'Customer PO number should be populated');
			System.assertEquals(10, invoiceHeaderDetail.Material_Price__c, 'Material Price should be populated');
			// System.assertEquals(20, invoiceHeaderDetail.Tuition_Price__c, 'Tuition Price should be populated');
			System.assertEquals('CC# 00000', invoiceHeaderDetail.Cost_Centre__c, 'Customer PO number should be populated');
			System.assertEquals('Test account 1 Student', invoiceHeaderDetail.Student_Name__c, 'Student Name should be populated');
			System.assertEquals('TEST Instance', invoiceHeaderDetail.Course_Name__c, 'Course name should be populated');
        Test.stopTest();
    }
}