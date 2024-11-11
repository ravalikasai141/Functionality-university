public class RecordGeneratorBilling implements RecordGenerator{
    public String generateRecords(){
        generateBillingRecords();
        return 'Billing';
    }
    
    @future
    public static void generateBillingRecords() {
        generateLegalEntityRecords();
        generateGLAccounts();
        generateGLRules();
        generateFinanceBooks();
        generateBillingRules();
        generateRevenueDistributionMethods();
        generateRevenueRecognitionRules();
        generateTaxIntegrations();
        generateTaxRules();
        generateGLTreatments();
        generateBillingTreatments();
        generateRevenueRecognitionTreatments();
        generateTaxRates();
        generateTaxTreatments();
        generateBillingRuleMappings();
    }

    private static void generateLegalEntityRecords() {
        RecordGeneratorHelper.createRecordsFromCSV('blng__LegalEntity__c', 'Billing_LegalEntity', null);
        Map<String, Id> legalEntityMap = RecordGeneratorHelper.populateMapFromQuery('blng__LegalEntity__c', null);
        updateChildLegalEntities(legalEntityMap);
    }
    
    private static void generateGLAccounts() {
    	RecordGeneratorHelper.createRecordsFromCSV('blng__GLAccount__c', 'Billing_GLAccounts', null);
    }
    
    private static void generateGLRules() {
    	RecordGeneratorHelper.createRecordsFromCSV('blng__GLRule__c', 'Billing_GLRules', null);
    }

    private static void generateFinanceBooks() {
        RecordGeneratorHelper.createRecordsFromCSV('blng__FinanceBook__c', 'Billing_FinanceBooks', null);
    }

    private static void generateBillingRules() {
        RecordGeneratorHelper.createRecordsFromCSV('blng__BillingRule__c', 'Billing_BillingRules', null);
    }
    
    private static void generateRevenueDistributionMethods() {
        RecordGeneratorHelper.createRecordsFromCSV('blng__RevenueDistributionMethod__c', 'Billing_RevenueDistributionMethods', null);
    }
    
    private static void generateRevenueRecognitionRules() {
        RecordGeneratorHelper.createRecordsFromCSV('blng__RevenueRecognitionRule__c', 'Billing_RevenueRecognitionRules', null);
    }

    private static void generateTaxIntegrations() {
        RecordGeneratorHelper.createRecordsFromCSV('blng__TaxIntegration__c', 'Billing_TaxIntegrations', null);
    }

    private static void generateTaxRules() {
        RecordGeneratorHelper.createRecordsFromCSV('blng__TaxRule__c', 'Billing_TaxRules', null);
    }

    private static void generateGLTreatments() {
        Map<String, Id> billingRecordMap = new Map<String, Id>();
        billingRecordMap = RecordGeneratorHelper.populateMapFromQuery('blng__LegalEntity__c', billingRecordMap);
        billingRecordMap = RecordGeneratorHelper.populateMapFromQuery('blng__GLAccount__c', billingRecordMap);
        billingRecordMap = RecordGeneratorHelper.populateMapFromQuery('blng__GLRule__c', billingRecordMap);
        RecordGeneratorHelper.createRecordsFromCSV('blng__GLTreatment__c', 'Billing_GLTreatments', billingRecordMap);
    }

    private static void generateBillingTreatments() {
        Map<String, Id> billingRecordMap = new Map<String, Id>();
        billingRecordMap = RecordGeneratorHelper.populateMapFromQuery('blng__LegalEntity__c', billingRecordMap);
        billingRecordMap = RecordGeneratorHelper.populateMapFromQuery('blng__GLRule__c', billingRecordMap);
        billingRecordMap = RecordGeneratorHelper.populateMapFromQuery('blng__FinanceBook__c', billingRecordMap);
        billingRecordMap = RecordGeneratorHelper.populateMapFromQuery('blng__BillingRule__c', billingRecordMap);
        RecordGeneratorHelper.createRecordsFromCSV('blng__BillingTreatment__c', 'Billing_BillingTreatments', billingRecordMap);
    }

    private static void generateRevenueRecognitionTreatments() {
        Map<String, Id> billingRecordMap = new Map<String, Id>();
        billingRecordMap = RecordGeneratorHelper.populateMapFromQuery('blng__LegalEntity__c', billingRecordMap);
        billingRecordMap = RecordGeneratorHelper.populateMapFromQuery('blng__GLRule__c', billingRecordMap);
        billingRecordMap = RecordGeneratorHelper.populateMapFromQuery('blng__FinanceBook__c', billingRecordMap);
        billingRecordMap = RecordGeneratorHelper.populateMapFromQuery('blng__RevenueRecognitionRule__c', billingRecordMap);
        billingRecordMap = RecordGeneratorHelper.populateMapFromQuery('blng__RevenueDistributionMethod__c', billingRecordMap);
        RecordGeneratorHelper.createRecordsFromCSV('blng__RevenueRecognitionTreatment__c', 'Billing_RevenueRecognitionTreatments', billingRecordMap);
    }

    private static void generateTaxRates() {
        Map<String, Id> billingRecordMap = new Map<String, Id>();
        billingRecordMap = RecordGeneratorHelper.populateMapFromQuery('blng__LegalEntity__c', billingRecordMap);
        RecordGeneratorHelper.createRecordsFromCSV('blng__TaxRate__c', 'Billing_TaxRates', billingRecordMap);
    }

    private static void generateTaxTreatments() {
        Map<String, Id> billingRecordMap = new Map<String, Id>();
        billingRecordMap = RecordGeneratorHelper.populateMapFromQuery('blng__LegalEntity__c', billingRecordMap);
        billingRecordMap = RecordGeneratorHelper.populateMapFromQuery('blng__GLRule__c', billingRecordMap);
        billingRecordMap = RecordGeneratorHelper.populateMapFromQuery('blng__TaxIntegration__c', billingRecordMap);
        billingRecordMap = RecordGeneratorHelper.populateMapFromQuery('blng__TaxRule__c', billingRecordMap);
        RecordGeneratorHelper.createRecordsFromCSV('blng__TaxTreatment__c', 'Billing_TaxTreatments', billingRecordMap);
    }

    private static void generateBillingRuleMappings() {
        Map<String, Id> billingRecordMap = new Map<String, Id>();
        billingRecordMap = RecordGeneratorHelper.populateMapFromQuery('blng__BillingRule__c', billingRecordMap);
        billingRecordMap = RecordGeneratorHelper.populateMapFromQuery('blng__TaxRule__c', billingRecordMap);
        RecordGeneratorHelper.createRecordsFromCSV('Billing_Rule_Mapping__c', 'Billing_BillingRuleMappings', billingRecordMap);
    }

    private static void updateChildLegalEntities(Map<String, Id> legalEntityMap) {
        List<blng__LegalEntity__c> childLegalEntityList = new List<blng__LegalEntity__c>();
        for (String legalEntityName : legalEntityMap.keyset()) {
            if (legalEntityName.contains('CI-')) {
                childLegalEntityList.add(new blng__LegalEntity__c(Id = legalEntityMap.get(legalEntityName), BPP_Parent_Legal_Entity__c = legalEntityMap.get('BPP (CI) Ltd')));
            } else if (legalEntityName.contains('LM-')) {
                childLegalEntityList.add(new blng__LegalEntity__c(Id = legalEntityMap.get(legalEntityName), BPP_Parent_Legal_Entity__c = legalEntityMap.get('BPP Learning Media Ltd')));
            } else if (legalEntityName.contains('PE-')) {
                childLegalEntityList.add(new blng__LegalEntity__c(Id = legalEntityMap.get(legalEntityName), BPP_Parent_Legal_Entity__c = legalEntityMap.get('BPP Professional Education Ltd')));
            } else if (legalEntityName.contains('CO-')) {
                childLegalEntityList.add(new blng__LegalEntity__c(Id = legalEntityMap.get(legalEntityName), BPP_Parent_Legal_Entity__c = legalEntityMap.get('BPP University Limited')));
            }
        }
        update childLegalEntityList;
    }

    public static void deleteBillingRecords() {
        delete [SELECT Id FROM Billing_Rule_Mapping__c];
        delete [SELECT Id FROM blng__TaxTreatment__c];
        delete [SELECT Id FROM blng__TaxRule__c];
        delete [SELECT Id FROM blng__TaxRate__c];
        delete [SELECT Id FROM blng__TaxIntegration__c];
        delete [SELECT Id FROM blng__RevenueRecognitionTreatment__c];
        delete [SELECT Id FROM blng__RevenueRecognitionRule__c];
        delete [SELECT Id FROM blng__RevenueDistributionMethod__c];
        delete [SELECT Id FROM blng__BillingTreatment__c];
        delete [SELECT Id FROM blng__BillingRule__c];
        delete [SELECT Id FROM blng__FinanceBook__c];
        delete [SELECT Id FROM blng__GLTreatment__c];
        delete [SELECT Id FROM blng__GLRule__c];
        delete [SELECT Id FROM blng__GLAccount__c];
        delete [SELECT Id FROM blng__LegalEntity__c];
    }
}