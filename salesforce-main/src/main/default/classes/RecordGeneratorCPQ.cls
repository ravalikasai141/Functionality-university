public class RecordGeneratorCPQ implements RecordGenerator{
    public String generateRecords(){
        generateCPQRecords();
        return 'CPQ';
    }
    
    @future
    public static void generateCPQRecords() {
        generateProductRules();
        generateErrorConditions();
        generatePriceRules();
        generatePriceConditions();
        generateLookupQueries();
        generatePriceActions();
    }

    private static void generateProductRules() {
        RecordGeneratorHelper.createRecordsFromCSV('SBQQ__ProductRule__c', 'CPQ_ProductRules', null);
    }

    private static void generateErrorConditions() {
        Map<String, Id> cpqRecordMap = new Map<String, Id>();
        cpqRecordMap = RecordGeneratorHelper.populateMapFromQuery('SBQQ__ProductRule__c', cpqRecordMap);
        RecordGeneratorHelper.createRecordsFromCSV('SBQQ__ErrorCondition__c', 'CPQ_ErrorConditions', cpqRecordMap);
    }

    private static void generatePriceRules() {
        RecordGeneratorHelper.createRecordsFromCSV('SBQQ__PriceRule__c', 'CPQ_PriceRules', null);
    }

    private static void generatePriceConditions() {
        Map<String, Id> cpqRecordMap = new Map<String, Id>();
        cpqRecordMap = RecordGeneratorHelper.populateMapFromQuery('SBQQ__PriceRule__c', cpqRecordMap);
        RecordGeneratorHelper.createRecordsFromCSV('SBQQ__PriceCondition__c', 'CPQ_PriceConditions', cpqRecordMap);
    }

    private static void generateLookupQueries() {
        Map<String, Id> cpqRecordMap = new Map<String, Id>();
        cpqRecordMap = RecordGeneratorHelper.populateMapFromQuery('SBQQ__PriceRule__c', cpqRecordMap);
        RecordGeneratorHelper.createRecordsFromCSV('SBQQ__LookupQuery__c', 'CPQ_LookupQueries', cpqRecordMap);
    }

    private static void generatePriceActions() {
        Map<String, Id> cpqRecordMap = new Map<String, Id>();
        cpqRecordMap = RecordGeneratorHelper.populateMapFromQuery('SBQQ__PriceRule__c', cpqRecordMap);
        RecordGeneratorHelper.createRecordsFromCSV('SBQQ__PriceAction__c', 'CPQ_PriceActions', cpqRecordMap);

        List<SBQQ__PriceAction__c> priceActionList = [SELECT Id FROM SBQQ__PriceAction__c WHERE SBQQ__Rule__r.Name = 'VAT Exempt' LIMIT 1];
        List<blng__TaxRule__c> taxRuleList = [SELECT Id FROM blng__TaxRule__c WHERE Name = 'OSS - Outside The Scope' LIMIT 1];
        if (priceActionList.size() == 1 && taxRuleList.size() == 1) {
            SBQQ__PriceAction__c vatExemptPA = priceActionList.get(0);
            vatExemptPA.SBQQ__Value__c = taxRuleList.get(0).Id;
            update vatExemptPA;
        }
    }

    public static void deleteCPQRecords() {
        delete [SELECT Id FROM SBQQ__PriceAction__c];
        delete [SELECT Id FROM SBQQ__LookupQuery__c];
        delete [SELECT Id FROM SBQQ__PriceCondition__c];
        delete [SELECT Id FROM SBQQ__PriceRule__c];
        delete [SELECT Id FROM SBQQ__ErrorCondition__c];
        delete [SELECT Id FROM SBQQ__ProductRule__c];
    }
}