/**
 *  @who    David Lovejoy <davidlovejoy@bpp.com>
 *  @when   26/04/2021
 *  @what   Utility class for InvoiceLine
 */
public class InvoiceLineUtility {
    public static void setBillingValues(List<blng__InvoiceLine__c> invoiceLines) {
        Set<Id> invoiceIds = new Set<Id>();
        for (blng__InvoiceLine__c invoiceLine : invoiceLines){
            invoiceIds.add(invoiceLine.blng__Invoice__c);
        }
        
        List<blng__Invoice__c> invoiceList = [SELECT Id, blng__InvoiceDate__c, (SELECT blng__BillingGLRule__r.Name, PaymentTerm__c FROM blng__InvoiceInvoiceLines__r) FROM blng__Invoice__c WHERE Id IN: invoiceIds];
		for (blng__Invoice__c invoice : invoiceList) {
            Set<String> billingGLRuleNames = new Set<String>();
            String paymentTerm;
            for (blng__InvoiceLine__c invoiceLine : invoice.blng__InvoiceInvoiceLines__r) {
                billingGLRuleNames.add(invoiceLine.blng__BillingGLRule__r.Name);
                if (paymentTerm == null) {
                    paymentTerm = invoiceLine.PaymentTerm__c;
                }
            }
            
            Boolean result = billingGLRuleNames.contains('Combined Billing GL Rule');
            invoice.BPP_Legal_Entity__r = new blng__LegalEntity__c(
                External_Id__c = (result ? 'BPP Professional Education Ltd' : 'BPP Learning Media Ltd')
            );

            if (paymentTerm != null) {
                invoice.Payment_Term__c = paymentTerm;
                invoice.blng__DueDate__c = generateInvoiceDueDate(invoice.blng__InvoiceDate__c, paymentTerm);
            }
		}
        update invoiceList;
    }

    public static Date generateInvoiceDueDate(Date invoiceDate, String paymentTerm) {
        Date dueDate;
        if (paymentTerm == 'Due on receipt') {
            dueDate = invoiceDate;
        } else {
            Integer paymentTermFormat = Integer.valueOf(paymentTerm.substringAfter('Net '));
            dueDate = invoiceDate.addDays(paymentTermFormat);
        }
        return dueDate;
    }
}