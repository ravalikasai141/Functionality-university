global class BPP_BatchCreditNoteLineSnapshot implements Database.Batchable<sObject>{
    
    global final string query;
    
    private Date dateParameter;

    global BPP_BatchCreditNoteLineSnapshot(Date dateParam){
        dateParameter = dateParam;
        // Get credit note lines where credit note balance is not zero, line balance is not zero and line status is neither draft not cancelled
        query = 'SELECT blng__CreditNote__r.blng__Account__c, blng__CreditNote__r.blng__Account__r.Name, blng__CreditNote__r.blng__Account__r.BPP_Account_Number__c, blng__CreditNote__r.blng__Balance__c, blng__CreditNote__r.blng__CreditNoteDate__c, blng__CreditNote__r.BPP_Credit_Note_Reason__c, blng__CreditNote__r.id, blng__CreditNote__r.name, blng__Balance__c, blng__BillingGLTreatment__r.blng__CreditGLAccount__c, blng__BillingGLTreatment__r.blng__CreditGLAccount__r.blng__GLAccountNumber__c, blng__Allocations__c, blng__Unallocations__c, blng__NetAllocations__c, blng__Refunds__c, blng__RefundsAllocations__c, blng__RefundsUnallocations__c, blng__BillingGLTreatment__r.blng__DebitGLAccount__c, blng__BillingGLTreatment__r.blng__DebitGLAccount__r.blng__GLAccountNumber__c, blng__Debits__c, blng__BillingGLTreatment__c, Id, blng__Status__c, blng__Subtotal__c, blng__TaxAmount__c, blng__TotalAmount__c, blng__InvoiceLine__c, blng__InvoiceLine__r.blng__Invoice__r.Name, blng__InvoiceLine__r.blng__Invoice__c, blng__StartDate__c, blng__EndDate__c, blng__CreditNote__r.blng__Account__r.Client_Category__c, blng__CreditNote__r.blng__Account__r.BillingCountry, blng__Product__r.Name, blng__Product__r.Qualification__c, blng__Product__r.Level_PQ__c, blng__Product__r.Paper__c, blng__LegalEntity__r.Name, blng__LegalEntity__r.BPP_Reporting_Legal_Entity_Name__c FROM blng__CreditNoteLine__c WHERE blng__CreditNote__r.blng__Balance__c != 0 AND blng__Balance__c != 0 AND ((blng__Status__c != \'Draft\' AND blng__Status__c != \'Cancelled\') OR (blng__Status__c = \'Draft\' AND Is_Test__c = true))';
    } 
    
    global Database.QueryLocator start(Database.BatchableContext BC){
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext BC, List<sObject> scope){
        List<Credit_Note_Line_Snapshot__c> creditNoteLineSnapshotsToCreate = new List<Credit_Note_Line_Snapshot__c>();
        for(Sobject s : scope){
            blng__CreditNoteLine__c      cnl  = (blng__CreditNoteLine__c) s;
            Credit_Note_Line_Snapshot__c cnls = new Credit_Note_Line_Snapshot__c();
            
            // Calculate days since credit note date
            Date    creditNoteDate          = cnl.blng__CreditNote__r.blng__CreditNoteDate__c;
            Integer daysSinceCreditNoteDate = creditNoteDate.daysBetween(dateParameter);
            
            // Assign fields to snapshot record
            cnls.Account__c                     = cnl.blng__CreditNote__r.blng__Account__c;
            cnls.Account_ID__c                  = cnl.blng__CreditNote__r.blng__Account__c;
            cnls.Account_Name__c                = cnl.blng__CreditNote__r.blng__Account__r.Name;
            cnls.Account_Number__c              = cnl.blng__CreditNote__r.blng__Account__r.BPP_Account_Number__c;
            cnls.Credit_Note_Balance__c         = cnl.blng__CreditNote__r.blng__Balance__c;
            cnls.Credit_Note_Date__c            = cnl.blng__CreditNote__r.blng__CreditNoteDate__c;
            cnls.Credit_Note_Reason__c          = cnl.blng__CreditNote__r.BPP_Credit_Note_Reason__c;
            cnls.Credit_Note_ID__c              = cnl.blng__CreditNote__r.id;
            cnls.Credit_Note_Number__c          = cnl.blng__CreditNote__r.name;
            cnls.Line_Balance__c                = cnl.blng__Balance__c;
            cnls.Line_Credit_Account_ID__c      = cnl.blng__BillingGLTreatment__r.blng__CreditGLAccount__c;
            cnls.Line_Credit_Account_Number__c  = cnl.blng__BillingGLTreatment__r.blng__CreditGLAccount__r.blng__GLAccountNumber__c;
            cnls.Line_Allocations__c            = cnl.blng__Allocations__c;
            cnls.Line_Unallocations__c          = cnl.blng__Unallocations__c;
            cnls.Line_Net_Allocations__c        = cnl.blng__NetAllocations__c;
            cnls.Line_Refunds__c                = cnl.blng__Refunds__c;
            cnls.Line_Refunds_Allocations__c    = cnl.blng__RefundsAllocations__c;
            cnls.Line_Refunds_Unallocations__c  = cnl.blng__RefundsUnallocations__c;
            cnls.Line_Debit_Account_ID__c       = cnl.blng__BillingGLTreatment__r.blng__DebitGLAccount__c;
            cnls.Line_Debit_Account_Number__c   = cnl.blng__BillingGLTreatment__r.blng__DebitGLAccount__r.blng__GLAccountNumber__c;
            cnls.Line_Debits__c                 = cnl.blng__Debits__c;
            cnls.Line_GL_Treatment_ID__c        = cnl.blng__BillingGLTreatment__c;
            cnls.Line_ID__c                     = cnl.Id;
            cnls.Line_Status__c                 = cnl.blng__Status__c;
            cnls.Line_Subtotal__c               = cnl.blng__Subtotal__c;
            cnls.Line_Tax_Amount__c             = cnl.blng__TaxAmount__c;
            cnls.Line_Total_Amount__c           = cnl.blng__TotalAmount__c;
            cnls.Line_Invoice_Line_ID__c        = cnl.blng__InvoiceLine__c;
            cnls.Line_Invoice_Number__c         = cnl.blng__InvoiceLine__r.blng__Invoice__r.Name;
            cnls.Line_Invoice_ID__c             = cnl.blng__InvoiceLine__r.blng__Invoice__c;
            cnls.Snapshot_Date__c               = dateParameter;
            cnls.Days_Since_Credit_Note_Date__c = daysSinceCreditNoteDate;
            cnls.Line_Start_Date__c             = cnl.blng__StartDate__c;
            cnls.Line_End_Date__c               = cnl.blng__EndDate__c;
            cnls.Account_Client_Category__c     = cnl.blng__CreditNote__r.blng__Account__r.Client_Category__c;
            cnls.Account_Country__c             = cnl.blng__CreditNote__r.blng__Account__r.BillingCountry;
            cnls.Product_Name__c                = cnl.blng__Product__r.Name;
            cnls.Product_Body__c                = cnl.blng__Product__r.Qualification__c;
            cnls.Product_Level__c               = cnl.blng__Product__r.Level_PQ__c;
            cnls.Product_Paper__c               = cnl.blng__Product__r.Paper__c;
            cnls.Legal_Entity_Name__c           = cnl.blng__LegalEntity__r.Name;
            cnls.Reporting_Legal_Entity_Name__c = cnl.blng__LegalEntity__r.BPP_Reporting_Legal_Entity_Name__c;
                   
            
            // Add snapshot to list to create
            creditNoteLineSnapshotsToCreate.add(cnls);
        }  
        insert creditNoteLineSnapshotsToCreate;
    }
    
    global void finish(Database.BatchableContext BC){
        system.debug('Snapshot run for date: '+dateParameter.format());
    }
}