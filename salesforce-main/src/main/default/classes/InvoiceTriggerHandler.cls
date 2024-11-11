public with sharing class InvoiceTriggerHandler {

	public static void handleAfterInsert(Map<Id,blng__Invoice__c> invoiceMap){
		InvoiceSender.sendInvoices(invoiceMap);
	}
    
}