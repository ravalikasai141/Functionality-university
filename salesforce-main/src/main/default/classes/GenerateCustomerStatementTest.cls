@isTest
public class GenerateCustomerStatementTest {
    @TestSetup
    static void makeData(){
        Account account = TestDataFactory.createAccount(true, false, null, 0);

        country_list__c cntry = CreateTestData.createCountry1();
        
        Address__c addressAccount = TestDataFactory.createAddress(true, 0, account, cntry, true, false);
        Order order = TestDataFactory.createOrder(true, 0, account, null, addressAccount);

        blng__BillingRule__c billingRule = TestDataFactory.createBillingRule(true);
        blng__FinanceBook__c billingFinanceBook = TestDataFactory.createBillingFinanceBook(true);
        blng__BillingTreatment__c billingTreatment = TestDataFactory.createBillingTreatment(true, billingRule, billingFinanceBook);
        blng__RevenueRecognitionRule__c revenueRecognitionRule = TestDataFactory.createRevenueRecognitionRule(true);
        blng__TaxRule__c taxRule = TestDataFactory.createTaxRule(true);
        
        Product2 product = TestDataFactory.createProduct(true, 0, billingRule, revenueRecognitionRule, taxRule);

        PricebookEntry pricebookEntry = TestDataFactory.createPricebookEntry(false, product, null);
        pricebookEntry.UnitPrice = 300;
        insert pricebookEntry;

        OrderItem parentOrderLine = TestDataFactory.createOrderLine(true, order, product, null, priceBookEntry, billingRule, revenueRecognitionRule, taxRule, '');
        OrderItem materialOrderLine = TestDataFactory.createOrderLine(true, order, product, parentOrderLine, priceBookEntry, billingRule, revenueRecognitionRule, taxRule, 'Materials');

        blng__UsageSummary__c usageSummary = TestDataFactory.createBookingSummary(false, materialOrderLine);
        usageSummary.blng__Order__c = order.Id;
        insert usageSummary;

        // Insert a Legal Entity
        insert TestDataFactory.buildDefaultLegalEntity();

        blng__Invoice__c invoice = new blng__Invoice__c(blng__Account__c = account.Id, blng__InvoiceDate__c = System.today(), Customer_PO_Number__c = 'Test PO');
        insert invoice;

        blng__InvoiceLine__c invoiceLine = new blng__InvoiceLine__c(blng__Invoice__c = invoice.Id, blng__UsageSummary__c = usageSummary.Id, blng__Product__c = product.Id);
        insert invoiceLine;

        blng__Payment__c payment = new blng__Payment__c(blng__Status__c = 'Posted', blng__PaymentDate__c = Date.today(), blng__Amount__c = 50, blng__Account__c = account.Id);
        insert payment;

        blng__CreditNote__c creditNote = new blng__CreditNote__c(blng__Status__c = 'Draft', BPP_Credit_Note_Reason__c = 'Automated Credit', blng__CreditNoteDate__c = Date.today(), blng__Account__c = account.Id);
        insert creditNote;

        blng__CreditNoteLine__c creditNoteLine = new blng__CreditNoteLine__c(blng__StartDate__c = Date.today(), blng__Subtotal__c = 30, blng__TotalAmount__c = 30, blng__Status__c = 'Draft', blng__Product__c = product.Id, blng__CreditNote__c = creditNote.Id);
        insert creditNoteLine;

        blng__DebitNote__c debitNote = new blng__DebitNote__c(blng__Status__c = 'Draft', blng__DebitNoteDate__c = Date.today(), blng__Account__c = account.Id);
        insert debitNote;

        blng__DebitNoteLine__c debitNoteLine = new blng__DebitNoteLine__c(blng__StartDate__c = Date.today(), blng__Subtotal__c = 20, blng__Status__c = 'Draft', blng__Product__c = product.Id, blng__DebitNote__c = debitNote.Id);
        insert debitNoteLine;
    }

    @isTest
    static void test_generateCustomerStatement() {
        Test.startTest();
            blng__Invoice__c invoice = [SELECT Id, Name FROM blng__Invoice__c];
            blng__Payment__c payment = [SELECT Id, Name FROM blng__Payment__c];
            blng__CreditNote__c creditNote = [SELECT Id, Name FROM blng__CreditNote__c];
            blng__DebitNote__c debitNote = [SELECT Id, Name FROM blng__DebitNote__c];
            Account account = [SELECT Id, Name FROM Account];
            
            blng__AccountBalanceSnapshot__c accountBalanceSnapshot = new blng__AccountBalanceSnapshot__c(
                Name = account.Name,
                blng__Account__c = account.Id,
                blng__SnapshotDate__c = Date.today(),
                blng__InvoiceAgingBucket1__c = 300,
                blng__Invoices__c = invoice.Name + ' GBP 300',
                blng__UnappliedPayments__c = payment.Name + ' GBP 50',
                blng__UnappliedCreditNotes__c = creditNote.Name + ' GBP 30',
                blng__UnappliedDebitNotes__c = debitNote.Name + ' GBP 20'
            );
            insert accountBalanceSnapshot;

            String result = GenerateCustomerStatement.generateCustomerStatement(account.Id);
            System.assertEquals('Success!', result);

            List<Attachment> attachments = [SELECT Id FROM Attachment WHERE ParentId =: account.Id];
            System.assertEquals(1, attachments.size());
        Test.stopTest();
    }

    @isTest
    static void test_generateCustomerStatementNoSnapshot() {
        Test.startTest();
            Account account = [SELECT Id, Name FROM Account];

            String result = GenerateCustomerStatement.generateCustomerStatement(account.Id);
            System.assertEquals('Something went wrong', result);
        Test.stopTest();
    }
}