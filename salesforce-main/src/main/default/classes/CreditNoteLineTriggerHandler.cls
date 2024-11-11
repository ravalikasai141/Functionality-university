/**
 *  @who    David Lovejoy <davidlovejoy@bpp.com>
 *  @when   12/11/2021
 *  @what   Handler for CreditNoteLineTrigger
 */
public with sharing class CreditNoteLineTriggerHandler {
    public static void afterInsert(Map <Id, blng__CreditNoteLine__c> newMap) {
        CreditNoteBackingDetailGenerator.createCreditNoteBackingDetailRecords(newMap.values());
    }
}