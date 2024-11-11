global class BPP_BatchInvoiceLineSnapshot implements Database.Batchable<sObject>{
    
    global final string query;
    
    private Date dateParameter;

    global BPP_BatchInvoiceLineSnapshot(Date dateParam){
        dateParameter = dateParam;
        // Get invoice lines where invoice balance is not zero, line balance is not zero and line status is neither draft not cancelled
        query = 'SELECT Id, name, blng__LegalEntity__r.Name, blng__LegalEntity__r.BPP_Reporting_Legal_Entity_Name__c, blng__Invoice__r.id, blng__Invoice__r.name, blng__Invoice__r.blng__InvoiceDate__c, blng__Invoice__r.blng__DueDate__c, blng__InvoiceLineStatus__c, blng__ARStatus__c, blng__Subtotal__c, blng__TaxAmount__c, blng__TotalAmount__c, blng__Credits__c, blng__Debits__c, blng__Payments__c, blng__NegativeLineConversion__c, blng__Balance__c, blng__Invoice__r.blng__Balance__c, blng__BillingGLTreatment__c, blng__BillingGLTreatment__r.blng__CreditGLAccount__c, blng__BillingGLTreatment__r.blng__DebitGLAccount__c, blng__BillingGLTreatment__r.blng__CreditGLAccount__r.blng__GLAccountNumber__c, blng__BillingGLTreatment__r.blng__DebitGLAccount__r.blng__GLAccountNumber__c, blng__Invoice__r.blng__Account__c, blng__Invoice__r.blng__Account__r.name, blng__Invoice__r.blng__Account__r.BPP_Account_Number__c, blng__StartDate__c, blng__EndDate__c, blng__Invoice__r.blng__Account__r.SFBD__CollectionsAgent__r.Name,blng__Invoice__r.blng__Account__r.Client_Category__c, blng__Invoice__r.blng__Account__r.BillingCountry, blng__OrderProduct__r.Product2.Qualification__c, blng__OrderProduct__r.Product2.Level_PQ__c, blng__OrderProduct__r.Product2.Paper__c FROM blng__InvoiceLine__c WHERE blng__Invoice__r.blng__Balance__c != 0 AND blng__Balance__c != 0 AND blng__InvoiceLineStatus__c != \'Draft\' AND blng__InvoiceLineStatus__c != \'Cancelled\'';
    } 
    
    global Database.QueryLocator start(Database.BatchableContext BC){
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext BC, List<sObject> scope){
        List<Invoice_Line_Snapshot__c> invoiceLineSnapshotsToCreate = new List<Invoice_Line_Snapshot__c>();
        for(Sobject s : scope){
            blng__InvoiceLine__c     il  = (blng__InvoiceLine__c) s;
            Invoice_Line_Snapshot__c ils = new Invoice_Line_Snapshot__c();
            
            // Calculate days since invoice dates
            Date invoiceDate                = il.blng__Invoice__r.blng__InvoiceDate__c;
            Date invoiceDueDate             = il.blng__Invoice__r.blng__DueDate__c;
            if (invoiceDate == null || invoiceDueDate == null) {
                continue;
            } else {
                Integer daysSinceInvoiceDate    = invoiceDate.daysBetween(dateParameter);
                Integer daysSinceInvoiceDueDate = invoiceDueDate.daysBetween(dateParameter);
                
                // Assign fields to snapshot record
                ils.Account__c                       = il.blng__Invoice__r.blng__Account__c;
                ils.Account_ID__c                    = il.blng__Invoice__r.blng__Account__c;
                ils.Account_Name__c                  = il.blng__Invoice__r.blng__Account__r.Name;
                ils.Account_Number__c                = il.blng__Invoice__r.blng__Account__r.BPP_Account_Number__c;
                ils.Invoice_Balance__c               = il.blng__Invoice__r.blng__Balance__c;
                ils.Invoice_Date__c                  = il.blng__Invoice__r.blng__InvoiceDate__c;
                ils.Invoice_Due_Date__c              = il.blng__Invoice__r.blng__DueDate__c;
                ils.Invoice_ID__c                    = il.blng__Invoice__r.id;
                ils.Invoice_Number__c                = il.blng__Invoice__r.name;
                ils.Line_AR_Status__c                = il.blng__ARStatus__c;
                ils.Line_Balance__c                  = il.blng__Balance__c;
                ils.Line_Credit_Account_ID__c        = il.blng__BillingGLTreatment__r.blng__CreditGLAccount__c;
                ils.Line_Credit_Account_Number__c    = il.blng__BillingGLTreatment__r.blng__CreditGLAccount__r.blng__GLAccountNumber__c;
                ils.Line_Credits__c                  = il.blng__Credits__c;
                ils.Line_Debit_Account_ID__c         = il.blng__BillingGLTreatment__r.blng__DebitGLAccount__c;
                ils.Line_Debit_Account_Number__c     = il.blng__BillingGLTreatment__r.blng__DebitGLAccount__r.blng__GLAccountNumber__c;
                ils.Line_Debits__c                   = il.blng__Debits__c;
                ils.Line_GL_Treatment_ID__c          = il.blng__BillingGLTreatment__c;
                ils.Line_ID__c                       = il.Id;
                ils.Line_Negative_Line_Conversion__c = il.blng__NegativeLineConversion__c;
                ils.Line_Payment__c                  = il.blng__Payments__c;
                ils.Line_Status__c                   = il.blng__InvoiceLineStatus__c;
                ils.Line_Subtotal__c                 = il.blng__Subtotal__c;
                ils.Line_Tax_Amount__c               = il.blng__TaxAmount__c;
                ils.Line_Total_Amount__c             = il.blng__TotalAmount__c;
                ils.Snapshot_Date__c                 = dateParameter;
                ils.Days_Since_Invoice_Date__c       = daysSinceInvoiceDate;
                ils.Days_Since_Invoice_Due_Date__c   = daysSinceInvoiceDueDate;
                ils.Line_Start_Date__c               = il.blng__StartDate__c;
                ils.Line_End_Date__c                 = il.blng__EndDate__c;
                ils.Account_Collector_Assigned__c    = il.blng__Invoice__r.blng__Account__r.SFBD__CollectionsAgent__r.Name;
                ils.Account_Client_Category__c       = il.blng__Invoice__r.blng__Account__r.Client_Category__c;
                ils.Account_Country__c               = il.blng__Invoice__r.blng__Account__r.BillingCountry;
                ils.Product_Body__c                  = il.blng__OrderProduct__r.Product2.Qualification__c;
                ils.Product_Level__c                 = il.blng__OrderProduct__r.Product2.Level_PQ__c;
                ils.Product_Paper__c                 = il.blng__OrderProduct__r.Product2.Paper__c;
                ils.Legal_Entity_Name__c             = il.blng__LegalEntity__r.Name;
                ils.Reporting_Legal_Entity_Name__c   = il.blng__LegalEntity__r.BPP_Reporting_Legal_Entity_Name__c;
                       
                
                // Add snapshot to list to create
                invoiceLineSnapshotsToCreate.add(ils);
            }
        }
        if (invoiceLineSnapshotsToCreate.size() > 0) {
        	insert invoiceLineSnapshotsToCreate;
        }
    }
    
    global void finish(Database.BatchableContext BC){
        system.debug('Snapshot run for date: '+dateParameter.format());
    }
}