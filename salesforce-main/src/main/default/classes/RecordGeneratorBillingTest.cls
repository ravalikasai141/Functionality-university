@isTest
private class RecordGeneratorBillingTest {
    @isTest
    private static void itShouldGenerateBillingRecords() {
        // GIVEN an Org has been refreshed
        // WHEN checking for Billing records
        List<Billing_Rule_Mapping__c> billingRuleMappingListBefore = [SELECT Id FROM Billing_Rule_Mapping__c];
        List<blng__TaxTreatment__c> taxTreatmentListBefore = [SELECT Id FROM blng__TaxTreatment__c];
        List<blng__TaxRule__c> taxRuleListBefore = [SELECT Id FROM blng__TaxRule__c];
        List<blng__TaxRate__c> taxRateListBefore = [SELECT Id FROM blng__TaxRate__c];
        List<blng__TaxIntegration__c> taxIntegrationListBefore = [SELECT Id FROM blng__TaxIntegration__c];
        List<blng__RevenueRecognitionTreatment__c> revRecogTreatmentListBefore = [SELECT Id FROM blng__RevenueRecognitionTreatment__c];
        List<blng__RevenueRecognitionRule__c> revRecogRuleListBefore = [SELECT Id FROM blng__RevenueRecognitionRule__c];
        List<blng__RevenueDistributionMethod__c> revDistnMethodListBefore = [SELECT Id FROM blng__RevenueDistributionMethod__c];
        List<blng__BillingTreatment__c> billingTreatmentListBefore = [SELECT Id FROM blng__BillingTreatment__c];
        List<blng__BillingRule__c> billingRuleListBefore = [SELECT Id FROM blng__BillingRule__c];
        List<blng__FinanceBook__c> financeBookListBefore = [SELECT Id FROM blng__FinanceBook__c];
        List<blng__GLTreatment__c> gLTreatmenListBefore = [SELECT Id FROM blng__GLTreatment__c];
        List<blng__GLRule__c> gLRuleListBefore = [SELECT Id FROM blng__GLRule__c];
        List<blng__GLAccount__c> gLAccountListBefore = [SELECT Id FROM blng__GLAccount__c];
        List<blng__LegalEntity__c> legalEntityListBefore = [SELECT Id FROM blng__LegalEntity__c];

        // THEN no Billing records should be found
        Assert.areEqual(0, billingRuleMappingListBefore.size());
        Assert.areEqual(0, taxTreatmentListBefore.size());
        Assert.areEqual(0, taxRuleListBefore.size());
        Assert.areEqual(0, taxRateListBefore.size());
        Assert.areEqual(0, taxIntegrationListBefore.size());
        Assert.areEqual(0, revRecogTreatmentListBefore.size());
        Assert.areEqual(0, revRecogRuleListBefore.size());
        Assert.areEqual(0, revDistnMethodListBefore.size());
        Assert.areEqual(0, billingTreatmentListBefore.size());
        Assert.areEqual(0, billingRuleListBefore.size());
        Assert.areEqual(0, financeBookListBefore.size());
        Assert.areEqual(0, gLTreatmenListBefore.size());
        Assert.areEqual(0, gLRuleListBefore.size());
        Assert.areEqual(0, gLAccountListBefore.size());
        Assert.areEqual(0, legalEntityListBefore.size());

        // GIVEN the above
        // WHEN the RecordGeneratorBilling class runs
        Test.startTest();
        RecordGeneratorBilling.generateBillingRecords();
        Test.stopTest();

        List<Billing_Rule_Mapping__c> billingRuleMappingListAfter = [SELECT Id FROM Billing_Rule_Mapping__c];
        List<blng__TaxTreatment__c> taxTreatmentListAfter = [SELECT Id FROM blng__TaxTreatment__c];
        List<blng__TaxRule__c> taxRuleListAfter = [SELECT Id FROM blng__TaxRule__c];
        List<blng__TaxRate__c> taxRateListAfter = [SELECT Id FROM blng__TaxRate__c];
        List<blng__TaxIntegration__c> taxIntegrationListAfter = [SELECT Id FROM blng__TaxIntegration__c];
        List<blng__RevenueRecognitionTreatment__c> revRecogTreatmentListAfter = [SELECT Id FROM blng__RevenueRecognitionTreatment__c];
        List<blng__RevenueRecognitionRule__c> revRecogRuleListAfter = [SELECT Id FROM blng__RevenueRecognitionRule__c];
        List<blng__RevenueDistributionMethod__c> revDistnMethodListAfter = [SELECT Id FROM blng__RevenueDistributionMethod__c];
        List<blng__BillingTreatment__c> billingTreatmentListAfter = [SELECT Id FROM blng__BillingTreatment__c];
        List<blng__BillingRule__c> billingRuleListAfter = [SELECT Id FROM blng__BillingRule__c];
        List<blng__FinanceBook__c> financeBookListAfter = [SELECT Id FROM blng__FinanceBook__c];
        List<blng__GLTreatment__c> gLTreatmenListAfter = [SELECT Id FROM blng__GLTreatment__c];
        List<blng__GLRule__c> gLRuleListAfter = [SELECT Id FROM blng__GLRule__c];
        List<blng__GLAccount__c> gLAccountListAfter = [SELECT Id FROM blng__GLAccount__c];
        List<blng__LegalEntity__c> legalEntityListAfter = [SELECT Id FROM blng__LegalEntity__c];

        // THEN Billing records should be created
        Assert.areNotEqual(0, billingRuleMappingListAfter.size());
        Assert.areNotEqual(0, taxTreatmentListAfter.size());
        Assert.areNotEqual(0, taxRuleListAfter.size());
        Assert.areNotEqual(0, taxRateListAfter.size());
        Assert.areNotEqual(0, taxIntegrationListAfter.size());
        Assert.areNotEqual(0, revRecogTreatmentListAfter.size());
        Assert.areNotEqual(0, revRecogRuleListAfter.size());
        Assert.areNotEqual(0, revDistnMethodListAfter.size());
        Assert.areNotEqual(0, billingTreatmentListAfter.size());
        Assert.areNotEqual(0, billingRuleListAfter.size());
        Assert.areNotEqual(0, financeBookListAfter.size());
        Assert.areNotEqual(0, gLTreatmenListAfter.size());
        Assert.areNotEqual(0, gLRuleListAfter.size());
        Assert.areNotEqual(0, gLAccountListAfter.size());
        Assert.areNotEqual(0, legalEntityListAfter.size());
    }

    @isTest
    private static void itShouldDeleteBillingRecords() {
        // GIVEN the RecordGeneratorBilling class runs
        Test.startTest();
        RecordGeneratorBilling.generateBillingRecords();
        Test.stopTest();

        List<Billing_Rule_Mapping__c> billingRuleMappingListBefore = [SELECT Id FROM Billing_Rule_Mapping__c];
        List<blng__TaxTreatment__c> taxTreatmentListBefore = [SELECT Id FROM blng__TaxTreatment__c];
        List<blng__TaxRule__c> taxRuleListBefore = [SELECT Id FROM blng__TaxRule__c];
        List<blng__TaxRate__c> taxRateListBefore = [SELECT Id FROM blng__TaxRate__c];
        List<blng__TaxIntegration__c> taxIntegrationListBefore = [SELECT Id FROM blng__TaxIntegration__c];
        List<blng__RevenueRecognitionTreatment__c> revRecogTreatmentListBefore = [SELECT Id FROM blng__RevenueRecognitionTreatment__c];
        List<blng__RevenueRecognitionRule__c> revRecogRuleListBefore = [SELECT Id FROM blng__RevenueRecognitionRule__c];
        List<blng__RevenueDistributionMethod__c> revDistnMethodListBefore = [SELECT Id FROM blng__RevenueDistributionMethod__c];
        List<blng__BillingTreatment__c> billingTreatmentListBefore = [SELECT Id FROM blng__BillingTreatment__c];
        List<blng__BillingRule__c> billingRuleListBefore = [SELECT Id FROM blng__BillingRule__c];
        List<blng__FinanceBook__c> financeBookListBefore = [SELECT Id FROM blng__FinanceBook__c];
        List<blng__GLTreatment__c> gLTreatmenListBefore = [SELECT Id FROM blng__GLTreatment__c];
        List<blng__GLRule__c> gLRuleListBefore = [SELECT Id FROM blng__GLRule__c];
        List<blng__GLAccount__c> gLAccountListBefore = [SELECT Id FROM blng__GLAccount__c];
        List<blng__LegalEntity__c> legalEntityListBefore = [SELECT Id FROM blng__LegalEntity__c];

        // AND Billing records are created
        Assert.areNotEqual(0, billingRuleMappingListBefore.size());
        Assert.areNotEqual(0, taxTreatmentListBefore.size());
        Assert.areNotEqual(0, taxRuleListBefore.size());
        Assert.areNotEqual(0, taxRateListBefore.size());
        Assert.areNotEqual(0, taxIntegrationListBefore.size());
        Assert.areNotEqual(0, revRecogTreatmentListBefore.size());
        Assert.areNotEqual(0, revRecogRuleListBefore.size());
        Assert.areNotEqual(0, revDistnMethodListBefore.size());
        Assert.areNotEqual(0, billingTreatmentListBefore.size());
        Assert.areNotEqual(0, billingRuleListBefore.size());
        Assert.areNotEqual(0, financeBookListBefore.size());
        Assert.areNotEqual(0, gLTreatmenListBefore.size());
        Assert.areNotEqual(0, gLRuleListBefore.size());
        Assert.areNotEqual(0, gLAccountListBefore.size());
        Assert.areNotEqual(0, legalEntityListBefore.size());

        // WHEN the deleteRecords method is run
        RecordGeneratorBilling.deleteBillingRecords();

        List<Billing_Rule_Mapping__c> billingRuleMappingListAfter = [SELECT Id FROM Billing_Rule_Mapping__c];
        List<blng__TaxTreatment__c> taxTreatmentListAfter = [SELECT Id FROM blng__TaxTreatment__c];
        List<blng__TaxRule__c> taxRuleListAfter = [SELECT Id FROM blng__TaxRule__c];
        List<blng__TaxRate__c> taxRateListAfter = [SELECT Id FROM blng__TaxRate__c];
        List<blng__TaxIntegration__c> taxIntegrationListAfter = [SELECT Id FROM blng__TaxIntegration__c];
        List<blng__RevenueRecognitionTreatment__c> revRecogTreatmentListAfter = [SELECT Id FROM blng__RevenueRecognitionTreatment__c];
        List<blng__RevenueRecognitionRule__c> revRecogRuleListAfter = [SELECT Id FROM blng__RevenueRecognitionRule__c];
        List<blng__RevenueDistributionMethod__c> revDistnMethodListAfter = [SELECT Id FROM blng__RevenueDistributionMethod__c];
        List<blng__BillingTreatment__c> billingTreatmentListAfter = [SELECT Id FROM blng__BillingTreatment__c];
        List<blng__BillingRule__c> billingRuleListAfter = [SELECT Id FROM blng__BillingRule__c];
        List<blng__FinanceBook__c> financeBookListAfter = [SELECT Id FROM blng__FinanceBook__c];
        List<blng__GLTreatment__c> gLTreatmenListAfter = [SELECT Id FROM blng__GLTreatment__c];
        List<blng__GLRule__c> gLRuleListAfter = [SELECT Id FROM blng__GLRule__c];
        List<blng__GLAccount__c> gLAccountListAfter = [SELECT Id FROM blng__GLAccount__c];
        List<blng__LegalEntity__c> legalEntityListAfter = [SELECT Id FROM blng__LegalEntity__c];

        // THEN the Billing records are deleted
        Assert.areEqual(0, billingRuleMappingListAfter.size());
        Assert.areEqual(0, taxTreatmentListAfter.size());
        Assert.areEqual(0, taxRuleListAfter.size());
        Assert.areEqual(0, taxRateListAfter.size());
        Assert.areEqual(0, taxIntegrationListAfter.size());
        Assert.areEqual(0, revRecogTreatmentListAfter.size());
        Assert.areEqual(0, revRecogRuleListAfter.size());
        Assert.areEqual(0, revDistnMethodListAfter.size());
        Assert.areEqual(0, billingTreatmentListAfter.size());
        Assert.areEqual(0, billingRuleListAfter.size());
        Assert.areEqual(0, financeBookListAfter.size());
        Assert.areEqual(0, gLTreatmenListAfter.size());
        Assert.areEqual(0, gLRuleListAfter.size());
        Assert.areEqual(0, gLAccountListAfter.size());
        Assert.areEqual(0, legalEntityListAfter.size());
    }
}