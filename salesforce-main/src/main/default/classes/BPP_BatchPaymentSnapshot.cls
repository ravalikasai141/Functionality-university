global class BPP_BatchPaymentSnapshot implements Database.Batchable<sObject>{
    
    global final string query;
    
    private Date dateParameter;

    global BPP_BatchPaymentSnapshot(Date dateParam){
        dateParameter = dateParam;
        // Get payments where payment balance is not zero, line balance is not zero and line status is neither draft not cancelled
        query = 'SELECT blng__LegalEntity__r.Name, blng__LegalEntity__r.BPP_Reporting_Legal_Entity_Name__c, blng__Account__r.Client_Category__c, blng__Account__r.BillingCountry, blng__Account__c, blng__Account__r.Name, blng__Account__r.BPP_Account_Number__c, blng__PaymentDate__c, blng__Allocations__c, blng__Unallocations__c, blng__Refunds__c, blng__Status__c, Name, Id, blng__Amount__c, blng__Balance__c, blng__ImpactAmount__c, blng__GLTreatment__r.blng__CreditGLAccount__c, blng__GLTreatment__r.blng__CreditGLAccount__r.blng__GLAccountNumber__c, blng__GLTreatment__r.blng__DebitGLAccount__c, blng__GLTreatment__r.blng__DebitGLAccount__r.blng__GLAccountNumber__c, blng__GLTreatment__c, blng__Invoice__c, blng__Invoice__r.name, BPP_Bank_Account__c, BPP_Bank_Account__r.Name, blng__GatewayID__c, blng__PaymentGateway__c, blng__PaymentGateway__r.Name, blng__LegalEntity__c, blng__PaymentDescription__c, blng__Transaction__c, blng__Transaction__r.Name, blng__Transaction__r.blng__Type__c, blng__Transaction__r.blng__Status__c, blng__PaymentMethod__c, blng__PaymentMethod__r.Name, blng__PaymentMode__c, blng__PaymentType__c FROM blng__Payment__c WHERE blng__Balance__c != 0 AND blng__Status__c = \'Posted\'';
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC){
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext BC, List<sObject> scope){
        List<Payment_Snapshot__c> paymentSnapshotsToCreate = new List<Payment_Snapshot__c>();
        for(Sobject s : scope){
            blng__Payment__c p = (blng__Payment__c) s;
            Payment_Snapshot__c ps = new Payment_Snapshot__c();
            
            // Calculate days since payment date
            Date paymentDate             = p.blng__PaymentDate__c;
            Integer daysSincePaymentDate = paymentDate.daysBetween(dateParameter);
            
            // Assign fields to snapshot record
            ps.Account__c                        = p.blng__Account__c;
            ps.Account_ID__c                     = p.blng__Account__c;
            ps.Account_Name__c                   = p.blng__Account__r.Name;
            ps.Account_Number__c                 = p.blng__Account__r.BPP_Account_Number__c;
            ps.Payment_Date__c                   = p.blng__PaymentDate__c;
            ps.Payment_Allocations__c            = p.blng__Allocations__c;
            ps.Payment_Unallocations__c          = p.blng__Unallocations__c;
            ps.Payment_Refunds__c                = p.blng__Refunds__c;
            ps.Payment_Status__c                 = p.blng__Status__c;
            ps.Payment_Name__c                   = p.Name;
            ps.Payment_ID__c                     = p.Id;
            ps.Payment_Amount__c                 = p.blng__Amount__c;
            ps.Payment_Balance__c                = p.blng__Balance__c;
            ps.Payment_Impact_Amount__c          = p.blng__ImpactAmount__c;
            ps.Payment_Credit_Account_ID__c      = p.blng__GLTreatment__r.blng__CreditGLAccount__c;
            ps.Payment_Credit_Account_Number__c  = p.blng__GLTreatment__r.blng__CreditGLAccount__r.blng__GLAccountNumber__c;
            ps.Payment_Debit_Account_ID__c       = p.blng__GLTreatment__r.blng__DebitGLAccount__c;
            ps.Payment_Debit_Account_Number__c   = p.blng__GLTreatment__r.blng__DebitGLAccount__r.blng__GLAccountNumber__c;
            ps.Payment_GL_Treatment_ID__c        = p.blng__GLTreatment__c;
            ps.Payment_Invoice_ID__c             = p.blng__Invoice__c;
            ps.Payment_Invoice_Number__c         = p.blng__Invoice__r.name;
            ps.Payment_Bank_Account_ID__c        = p.BPP_Bank_Account__c;
            ps.Payment_Bank_Account_Name__c      = p.BPP_Bank_Account__r.Name;
            ps.Payment_Gateway_Transaction_ID__c = p.blng__GatewayID__c;
            ps.Payment_Gateway_ID__c             = p.blng__PaymentGateway__c;
            ps.Payment_Gateway_Name__c           = p.blng__PaymentGateway__r.Name;
            ps.Payment_Legal_Entity_ID__c        = p.blng__LegalEntity__c;
            ps.Payment_Description__c            = p.blng__PaymentDescription__c;
            ps.Payment_Transaction_ID__c         = p.blng__Transaction__c;
            ps.Payment_Transaction_Name__c       = p.blng__Transaction__r.Name;
            ps.Payment_Transaction_Type__c       = p.blng__Transaction__r.blng__Type__c;
            ps.Payment_Transaction_Status__c     = p.blng__Transaction__r.blng__Status__c;
            ps.Snapshot_Date__c                  = dateParameter;
            ps.Payment_Method_ID__c              = p.blng__PaymentMethod__c;
            ps.Payment_Method_Name__c            = p.blng__PaymentMethod__r.Name;
            ps.Payment_Mode__c                   = p.blng__PaymentMode__c;
            ps.Days_Since_Payment_Date__c        = daysSincePaymentDate;
            ps.Account_Client_Category__c        = p.blng__Account__r.Client_Category__c;
            ps.Account_Country__c                = p.blng__Account__r.BillingCountry;
            ps.Payment_Type__c                   = p.blng__PaymentType__c;
            ps.Legal_Entity_Name__c              = p.blng__LegalEntity__r.Name;
            ps.Reporting_Legal_Entity_Name__c    = p.blng__LegalEntity__r.BPP_Reporting_Legal_Entity_Name__c;            
                        
            // Add snapshot to list to create
            paymentSnapshotsToCreate.add(ps);
        }  
        insert paymentSnapshotsToCreate;
    }
    
    global void finish(Database.BatchableContext BC){
        system.debug('Snapshot run for date: '+dateParameter.format());
    }
}