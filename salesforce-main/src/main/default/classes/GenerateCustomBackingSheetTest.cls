@isTest
public class GenerateCustomBackingSheetTest {
    @TestSetup
    static void makeData(){
        Account account = TestDataFactory.createAccount(true, false, null, 0);
        Account student = TestDataFactory.createAccount(false, true, account.Id, 1);
        student.Cost_Centre_Number__pc = 'CC# 00000';
        insert student;
        
        country_list__c cntry = CreateTestData.createCountry1();
        
        Address__c addressAccount = TestDataFactory.createAddress(true, 0, account, cntry, true, false);
        Order order = TestDataFactory.createOrder(true, 1, account, null, addressAccount);

        blng__BillingRule__c billingRule = TestDataFactory.createBillingRule(true);
        blng__FinanceBook__c billingFinanceBook = TestDataFactory.createBillingFinanceBook(true);
        blng__BillingTreatment__c billingTreatment = TestDataFactory.createBillingTreatment(true, billingRule, billingFinanceBook);
        blng__RevenueRecognitionRule__c revenueRecognitionRule = TestDataFactory.createRevenueRecognitionRule(true);
        blng__TaxRule__c taxRule = TestDataFactory.createTaxRule(true);
        
        Product2 product = TestDataFactory.createProduct(false,1,billingRule,revenueRecognitionRule,taxRule);
		product.Course_Type__c = 'Taught - Test';
		insert product;
		
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
			
			List<blng__InvoiceLine__c> invoiceLines = new List<blng__InvoiceLine__c>();
			for (blng__UsageSummary__c bookingSummary : bookingSummaries) {
				blng__InvoiceLine__c invoiceLine = new blng__InvoiceLine__c();
				invoiceLine.blng__Invoice__c = invoice.Id;
				invoiceLine.blng__UsageSummary__c = bookingSummary.Id;
				invoiceLines.add(invoiceLine);
			}
			
			blng__InvoiceLine__c invoiceLine = new blng__InvoiceLine__c();
			invoiceLine.blng__Invoice__c = invoice.Id;
			invoiceLines.add(invoiceLine);
			insert invoiceLines;
			
			List<Invoiceheader_details__c> invoiceHeaderDetails = [SELECT Id, Customer_POnumber__c, Material_Price__c,Tuition_Price__c, Cost_Centre__c, Student_Name__c, Course_Name__c FROM Invoiceheader_details__c];
			System.debug('Invoiceheader Details' + invoiceHeaderDetails);
			
			String result = GenerateCustomBackingSheet.generateCustomBackingSheet(invoice.Id);
            System.assertEquals('Success!', result);

            List<Attachment> attachments = [SELECT Id FROM Attachment WHERE ParentId =: invoice.Id];
            System.assertEquals(1, attachments.size());
        Test.stopTest();
    }
}