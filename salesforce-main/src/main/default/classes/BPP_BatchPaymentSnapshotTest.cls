@isTest
private class BPP_BatchPaymentSnapshotTest {
    @testSetup
    static void setup() {
        List<Account>              accounts     = new List<Account>();
        List<blng__Payment__c>     payments     = new List<blng__Payment__c>();
        Date                       today        = Date.today();
        
        
        // Insert 1 account
        for (Integer i=0;i<1;i++) {
            accounts.add(new Account(name           = 'Account '+i, 
                                     BillingCity    = 'London',
                                     BillingCountry = 'United Kingdom'));
        }
        
        system.debug('Inserting accounts: ' + accounts);
        
        insert accounts;

        
        // Find the account just inserted, add payment for each
        for (Account account : [select id from Account]) {
            payments.add(new blng__Payment__c(blng__Status__c      = 'Posted',
                                              blng__PaymentDate__c = today,
                                              blng__Amount__c      = 100,
                                              blng__Account__c     = account.Id));
        }        
        
        system.debug('Inserting payments: ' + payments);

        insert payments;
    }
    
    @isTest static void test() {
        Test.startTest();
        BPP_BatchPaymentSnapshot myBatch = new BPP_BatchPaymentSnapshot(System.today());
        ID batchProcessId = Database.executeBatch(myBatch);     
        Test.stopTest();
        
        // After the testing stops, assert expected amount of snapshot lines was created
        System.assertEquals(1, [select count() from Payment_Snapshot__c]);
    }
}