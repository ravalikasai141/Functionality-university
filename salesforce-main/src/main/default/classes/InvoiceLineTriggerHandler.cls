/**
 *  @who    Duy Vu <duy.vu@weare4c.com>
 *  @when   02/07/2020
 *  @what   Handler for InvoiceLineTrigger
 */
public with sharing class InvoiceLineTriggerHandler {
    public static void afterInsert(Map <Id, blng__InvoiceLine__c> newMap) {
        InvoiceHeaderDetailsGenerator.createInvoiceHeaderDetails(newMap.values());
        InvoiceLineUtility.setBillingValues(newMap.values());
    }
}