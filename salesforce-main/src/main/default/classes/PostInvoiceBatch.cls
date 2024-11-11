global class  PostInvoiceBatch implements Schedulable, Database.Batchable<sObject>, Database.Stateful {
    public void execute(SchedulableContext SC) {
        Database.executeBatch(this, 1);
    }

    global Database.QueryLocator start(Database.BatchableContext BC) {
        String query = (Test.IsRunningTest() ? 'SELECT Id FROM blng__Invoice__c WHERE blng__InvoiceStatus__c = \'Draft\' AND Created_via_X3_Migration__c = true AND External_Invoice_Number__c != null ORDER BY CreatedDate DESC LIMIT 1'
		: 'SELECT Id FROM blng__Invoice__c WHERE blng__InvoiceStatus__c = \'Draft\' AND Created_via_X3_Migration__c = true AND External_Invoice_Number__c != null AND CreatedDate = TODAY AND CreatedById = \'' + UserInfo.getUserId() + '\'');
        System.debug(query);
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<blng__Invoice__c> invoiceList) {
        if (invoiceList.size() > 0){
			for (blng__Invoice__c invoice : invoiceList) {
                invoice.blng__InvoiceStatus__c = 'Posted';
            }
            update invoiceList;
        }
    }
	
    global void finish(Database.BatchableContext BC) {
        
    }
}