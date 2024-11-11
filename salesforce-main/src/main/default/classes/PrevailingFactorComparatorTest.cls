@isTest
public with sharing class PrevailingFactorComparatorTest {
    @isTest
    private static void itShouldRetrievePrevailingFactorRecordsAndSortThemByIndex() {
        //GIVEN I have a collection of all Prevailing Factor records
        Map<String, Prevailing_Factor__mdt> prevailingFactors = Prevailing_Factor__mdt.getAll();
        List<PrevailingFactorComparator> factorComparators = new List<PrevailingFactorComparator>();

        for (String prevailingFactorName : prevailingFactors.keyset()) {
            factorComparators.add(new PrevailingFactorComparator(prevailingFactors.get(prevailingFactorName)));
        }

        //WHEN the PrevailingFactorComparator class sorts the Prevailing Factor records
        factorComparators.sort();

        //THEN I expect the Prevailing Factor records to be sorted in Index__c order
        for (Integer i = 0; i < Integer.valueOf(factorComparators.size()); i++) {
            Assert.isTrue(
                factorComparators.get(i).prevailingFactor.Index__c == i,
                'Prevailing Factor records should be present in the collection in Index__c order.'
            );
        }
    }
}
