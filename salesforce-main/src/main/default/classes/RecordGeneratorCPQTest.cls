@isTest
public class RecordGeneratorCPQTest {
    @TestSetup
    static void setup() {
        blng__TaxRule__c taxRule = new blng__TaxRule__c(
            blng__Active__c = true,
            Name = 'OSS - Outside The Scope'
        );
        insert taxRule;
    }

    @isTest
    public static void itShouldGenerateCPQRecords() {
        // GIVEN an Org has been refreshed
        // WHEN checking for CPQ records
        List<SBQQ__PriceAction__c> priceActionListBefore = [SELECT Id FROM SBQQ__PriceAction__c];
        List<SBQQ__LookupQuery__c> lookupQueryListBefore = [SELECT Id FROM SBQQ__LookupQuery__c];
        List<SBQQ__PriceCondition__c> priceConditionListBefore = [SELECT Id FROM SBQQ__PriceCondition__c];
        List<SBQQ__PriceRule__c> pricRuleListBefore = [SELECT Id FROM SBQQ__PriceRule__c];
        List<SBQQ__ErrorCondition__c> errorConditionListBefore = [SELECT Id FROM SBQQ__ErrorCondition__c];
        List<SBQQ__ProductRule__c> productRuleListBefore = [SELECT Id FROM SBQQ__ProductRule__c];

        // THEN no CPQ records should be found
        Assert.areEqual(0, priceActionListBefore.size());
        Assert.areEqual(0, lookupQueryListBefore.size());
        Assert.areEqual(0, priceConditionListBefore.size());
        Assert.areEqual(0, pricRuleListBefore.size());
        Assert.areEqual(0, errorConditionListBefore.size());
        Assert.areEqual(0, productRuleListBefore.size());

        // GIVEN the above
        // WHEN the RecordGeneratorCPQ class runs
        Test.startTest();
        RecordGeneratorCPQ.generateCPQRecords();
        Test.stopTest();

        List<SBQQ__PriceAction__c> priceActionListAfter = [SELECT Id FROM SBQQ__PriceAction__c];
        List<SBQQ__LookupQuery__c> lookupQueryListAfter = [SELECT Id FROM SBQQ__LookupQuery__c];
        List<SBQQ__PriceCondition__c> priceConditionListAfter = [SELECT Id FROM SBQQ__PriceCondition__c];
        List<SBQQ__PriceRule__c> pricRuleListAfter = [SELECT Id FROM SBQQ__PriceRule__c];
        List<SBQQ__ErrorCondition__c> errorConditionListAfter = [SELECT Id FROM SBQQ__ErrorCondition__c];
        List<SBQQ__ProductRule__c> productRuleListAfter = [SELECT Id FROM SBQQ__ProductRule__c];

        // THEN CPQ records should be created
        Assert.areNotEqual(0, priceActionListAfter.size());
        Assert.areNotEqual(0, lookupQueryListAfter.size());
        Assert.areNotEqual(0, priceConditionListAfter.size());
        Assert.areNotEqual(0, pricRuleListAfter.size());
        Assert.areNotEqual(0, errorConditionListAfter.size());
        Assert.areNotEqual(0, productRuleListAfter.size());
    }

    @isTest
    public static void itShouldDeleteCPQRecords() {
        // GIVEN the RecordGeneratorCPQ class runs
        Test.startTest();
        RecordGeneratorCPQ.generateCPQRecords();
        Test.stopTest();

        List<SBQQ__PriceAction__c> priceActionListBefore = [SELECT Id FROM SBQQ__PriceAction__c];
        List<SBQQ__LookupQuery__c> lookupQueryListBefore = [SELECT Id FROM SBQQ__LookupQuery__c];
        List<SBQQ__PriceCondition__c> priceConditionListBefore = [SELECT Id FROM SBQQ__PriceCondition__c];
        List<SBQQ__PriceRule__c> pricRuleListBefore = [SELECT Id FROM SBQQ__PriceRule__c];
        List<SBQQ__ErrorCondition__c> errorConditionListBefore = [SELECT Id FROM SBQQ__ErrorCondition__c];
        List<SBQQ__ProductRule__c> productRuleListBefore = [SELECT Id FROM SBQQ__ProductRule__c];

        // AND CPQ records are created
        Assert.areNotEqual(0, priceActionListBefore.size());
        Assert.areNotEqual(0, lookupQueryListBefore.size());
        Assert.areNotEqual(0, priceConditionListBefore.size());
        Assert.areNotEqual(0, pricRuleListBefore.size());
        Assert.areNotEqual(0, errorConditionListBefore.size());
        Assert.areNotEqual(0, productRuleListBefore.size());

        // WHEN the deleteRecords method is run
        RecordGeneratorCPQ.deleteCPQRecords();

        List<SBQQ__PriceAction__c> priceActionListAfter = [SELECT Id FROM SBQQ__PriceAction__c];
        List<SBQQ__LookupQuery__c> lookupQueryListAfter = [SELECT Id FROM SBQQ__LookupQuery__c];
        List<SBQQ__PriceCondition__c> priceConditionListAfter = [SELECT Id FROM SBQQ__PriceCondition__c];
        List<SBQQ__PriceRule__c> pricRuleListAfter = [SELECT Id FROM SBQQ__PriceRule__c];
        List<SBQQ__ErrorCondition__c> errorConditionListAfter = [SELECT Id FROM SBQQ__ErrorCondition__c];
        List<SBQQ__ProductRule__c> productRuleListAfter = [SELECT Id FROM SBQQ__ProductRule__c];

        // THEN the CPQ records are deleted
        Assert.areEqual(0, priceActionListAfter.size());
        Assert.areEqual(0, lookupQueryListAfter.size());
        Assert.areEqual(0, priceConditionListAfter.size());
        Assert.areEqual(0, pricRuleListAfter.size());
        Assert.areEqual(0, errorConditionListAfter.size());
        Assert.areEqual(0, productRuleListAfter.size());
    }
}