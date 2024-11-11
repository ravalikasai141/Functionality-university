@isTest
private class BPP_BatchCreditNoteLineSnapshotTest {
    
@testSetup
    static void setup() {
        List<Product2>                products        = new List<Product2>();
        List<Account>                 accounts        = new List<Account>();
        List<blng__CreditNote__c>     creditNotes     = new List<blng__CreditNote__c>();
        List<blng__CreditNoteLine__c> creditNoteLines = new List<blng__CreditNoteLine__c>();
        Date                          today           = Date.today();
        
        
        // Insert 1 product
        for (Integer i=0;i<1;i++) {
            products.add(new Product2(name           = 'Product '+i, 
                                      IsActive       = true));
        }
        
        system.debug('Inserting products: ' + products);
        
        insert products;

        
        // Insert 1 account
        for (Integer i=0;i<1;i++) {
            accounts.add(new Account(name           = 'Account '+i, 
                                     BillingCity    = 'London',
                                     BillingCountry = 'United Kingdom'));
        }
        
        system.debug('Inserting accounts: ' + accounts);
        
        insert accounts;

        
        // Find the accounts just inserted, add credit note for each
        for (Account account : [select id from Account]) {
            creditNotes.add(new blng__CreditNote__c(blng__Status__c           = 'Draft',
                                                    BPP_Credit_Note_Reason__c = 'Automated Credit',
                                                    blng__CreditNoteDate__c   = today,
                                                    blng__Account__c          = account.Id));
        }
           
        
        system.debug('Inserting credit notes: ' + creditNotes);

        insert creditNotes;
        
        
        // Find the credit note just inserted, add credit note line for each product
        for (blng__CreditNote__c creditNote : [select id from blng__CreditNote__c]) {
            for (Product2 product : [select id from Product2]) {
                creditNoteLines.add(new blng__CreditNoteLine__c(blng__StartDate__c   = today,
                                                                blng__Subtotal__c    = 100,
                                                                blng__TotalAmount__c = 100,
                                                                Is_Test__c           = true, // Force read of draft records for testing
                                                                blng__Status__c      = 'Draft',
                                                                blng__Product__c     = product.Id,                                                            
                                                                blng__CreditNote__c  = creditNote.id));
            }
        }
    
        system.debug('Inserting credit note lines: ' + creditNoteLines);
        
        insert creditNoteLines;
    }
    
    @isTest static void test() {

        Test.StartTest(); 
        BPP_BatchCreditNoteLineSnapshot myBatch = new BPP_BatchCreditNoteLineSnapshot(System.today());
        ID batchProcessId = Database.executeBatch(myBatch);     
        Test.stopTest();

        
        // After the testing stops, assert expected amount of snapshot lines was created
        // Note: testing uses "Is Test?" checkbox on credit note line to workaround issue of having two async Apex calls in the same test class
        // (the test seemed not to wait for the posting to complete)
        System.assertEquals(1, [select count() from Credit_Note_Line_Snapshot__c]);
    }
}