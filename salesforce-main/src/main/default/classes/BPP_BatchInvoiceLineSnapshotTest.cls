@isTest
private class BPP_BatchInvoiceLineSnapshotTest {
    @testSetup
    static void setup() {
        List<Account>              accounts     = new List<Account>();
        List<blng__Invoice__c>     invoices     = new List<blng__Invoice__c>();
        List<blng__InvoiceLine__c> invoiceLines = new List<blng__InvoiceLine__c>();
        Date                       today        = Date.today();
        
        
        // Insert 1 account
        for (Integer i=0;i<1;i++) {
            accounts.add(new Account(name           = 'Account '+i, 
                                     BillingCity    = 'London',
                                     BillingCountry = 'United Kingdom'));
        }
        
        system.debug('Inserting accounts: ' + accounts);
        
        insert accounts;

        
        // Find the account just inserted, add invoice for each
        for (Account account : [select id from Account]) {
            invoices.add(new blng__Invoice__c(blng__InvoiceStatus__c = 'Draft',
                                              blng__InvoiceDate__c   = today,
                                              blng__DueDate__c       = today + 30,
                                              blng__Account__c       = account.Id));
        }        
        
        system.debug('Inserting invoices: ' + invoices);

        insert invoices;

        // Insert a Legal Entity
        insert  TestDataFactory.buildDefaultLegalEntity();

        // Find the invoice just inserted, add invoice line
        for (blng__Invoice__c invoice : [select id from blng__Invoice__c]) {
            invoiceLines.add(new blng__InvoiceLine__c(blng__ChargeDate__c        = today,
                                                      blng__Subtotal__c          = 100,
                                                      blng__TotalAmount__c       = 100,
                                                      blng__InvoiceLineStatus__c = 'Posted',
                                                      blng__Invoice__c           = invoice.id));
        }
        
        system.debug('Inserting invoice lines: ' + invoiceLines);

        insert invoiceLines;
    }
    
    @isTest static void test() {
        Test.startTest();
        BPP_BatchInvoiceLineSnapshot myBatch = new BPP_BatchInvoiceLineSnapshot(System.today());
        ID batchProcessId = Database.executeBatch(myBatch);     
        Test.stopTest();
        
        // After the testing stops, assert expected amount of snapshot lines was created
        System.assertEquals(1, [select count() from Invoice_Line_Snapshot__c]);
    }
}