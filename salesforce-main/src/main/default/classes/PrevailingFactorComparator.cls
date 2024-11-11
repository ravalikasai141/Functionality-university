/**
 * Apex class used for sorting Prevailing_Factor__mdt records by their custom field: Index__c
 */
public class PrevailingFactorComparator implements Comparable {
    public Prevailing_Factor__mdt prevailingFactor;

    public PrevailingFactorComparator(Prevailing_Factor__mdt factor) {
        this.prevailingFactor = factor;
    }

    /*
     * Compares the current PrevailingFactorComparator object with the specified object for order based on Index__c field
     *
     * @param objToCompare The object to be compared
     * @return 0 if both objects have the same Index__c, 1 if the current object's Index__c is greater, -1 if the specified object's Index__c is greater
     */
    public Integer compareTo(Object objToCompare) {
        PrevailingFactorComparator factorToCompare = (PrevailingFactorComparator) objToCompare;

        Integer returnValue = 0;
        if (this.prevailingFactor.Index__c != null) {
            if (this.prevailingFactor.Index__c == factorToCompare.prevailingFactor.Index__c) {
                returnValue = 0;
            } else if (this.prevailingFactor.Index__c > factorToCompare.prevailingFactor.Index__c) {
                returnValue = 1;
            } else {
                returnValue = -1;
            }
        }
        return returnValue;
    }
}
