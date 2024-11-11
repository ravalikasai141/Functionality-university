/**
 *  @who    David Lovejoy <davidlovejoy@bpp.com>
 *  @when   12/11/2021
 *  @what   Generate Credit Note Backing Detail records from Credit Note Lines
 */
public with sharing class CreditNoteBackingDetailGenerator {
    private static Map<Id, List<blng__Usage__c>> usageSummaryIdToUsageLinesMap;
    private static Map<Id, Instance__c> instances;
    private static Map<Id, Booking__c> bookings;
    private static Map<Id, Account> students;
    private static List<blng__InvoiceLine__c> invoiceLineList = new List<blng__InvoiceLine__c>();

    public static void createCreditNoteBackingDetailRecords(List<blng__CreditNoteLine__c> creditNoteLineList) {
        setUpObjectMappings(creditNoteLineList);
        Set<Id> processedBookings = new Set<Id>();
        List<Credit_Note_Backing_Detail__c> backingDetailList = new List<Credit_Note_Backing_Detail__c>();

        for (blng__CreditNoteLine__c creditNoteLine : creditNoteLineList) {
            for (blng__InvoiceLine__c invoiceLine : invoiceLineList) {
                if (creditNoteLine.blng__InvoiceLine__c == invoiceLine.Id && usageSummaryIdToUsageLinesMap.containsKey(invoiceLine.blng__UsageSummary__c)) {
                    List<blng__Usage__c> usageLines = usageSummaryIdToUsageLinesMap.get(invoiceLine.blng__UsageSummary__c);
                    for (blng__Usage__c usageLine : usageLines) {
                        if (processedBookings.contains(usageLine.Booking__c)) {
                            continue;   
                        }
                        Credit_Note_Backing_Detail__c backingDetail = createIndividualCreditNoteBackingDetail(usageLine);
                        backingDetail.Credit_Note__c = creditNoteLine.blng__CreditNote__c;
                        backingDetailList.add(backingDetail);
                        processedBookings.add(usageLine.Booking__c);
                    }
                }
            }
        }
        
        for (Credit_Note_Backing_Detail__c cnbd : backingDetailList) {
            System.debug(cnbd);
        }

        if (backingDetailList.size() > 0) {
            try { 
                insert backingDetailList;
            } catch (DmlException e) {
                System.debug('Error Message: ' + e.getMessage());
                creditNoteLineList[0].addError(e);
            }
        }
    }

    private static void setUpObjectMappings(List<blng__CreditNoteLine__c> creditNoteLineList) {
        Set<Id> creditNoteIds = new Set<Id>();
        List<Id> invoiceLineIds = new List<Id>();
        List<Id> usageSummaryIds = new List<Id>();
        List<Id> bookingIds = new List<Id>();
        List<Id> studentIds = new List<Id>();
        List<Id> instanceIds = new List<Id>();

        for (blng__CreditNoteLine__c creditNoteLine : creditNoteLineList) {
            if (creditNoteLine.blng__CreditNote__c != null) creditNoteIds.add(creditNoteLine.blng__CreditNote__c);
            if (creditNoteLine.blng__InvoiceLine__c != null) invoiceLineIds.add(creditNoteLine.blng__InvoiceLine__c);
        }

        for (blng__CreditNote__c creditNote : [SELECT BPP_Booking__c, BPP_Booking__r.Student__c FROM blng__CreditNote__c WHERE Id IN: creditNoteIds]) {
            if (creditNote.BPP_Booking__c != null) bookingIds.add(creditNote.BPP_Booking__c);
            if (creditNote.BPP_Booking__r.Student__c != null) studentIds.add(creditNote.BPP_Booking__r.Student__c);
        }

        invoiceLineList = [SELECT blng__UsageSummary__c FROM blng__InvoiceLine__c WHERE Id IN: invoiceLineIds];
        for (blng__InvoiceLine__c invoiceLine : invoiceLineList) {
            if (invoiceLine.blng__UsageSummary__c != null) usageSummaryIds.add(invoiceLine.blng__UsageSummary__c);
        }

        System.debug('@CreditNoteBackingDetailGenerator - setUpObjectMappings');
        System.debug('creditNoteIds = ' + creditNoteIds.size() + ' : ' + creditNoteIds);
        System.debug('invoiceLineIds = ' + invoiceLineIds.size() + ' : ' + invoiceLineIds);
        System.debug('bookingIds = ' + bookingIds.size() + ' : ' + bookingIds);
        System.debug('studentIds = ' + studentIds.size() + ' : ' + studentIds);
        System.debug('usageSummaryIds = ' + usageSummaryIds.size() + ' : ' + usageSummaryIds);

        usageSummaryIdToUsageLinesMap = new Map<Id, List<blng__Usage__c>>();
        String query = (bookingIds.size() > 0 ? 'SELECT Id, Booking__c, Instance__c, blng__UsageSummary__c FROM blng__Usage__c WHERE Booking__c IN: bookingIds AND blng__UsageSummary__c IN: usageSummaryIds' : 'SELECT Id, Booking__c, Instance__c, blng__UsageSummary__c FROM blng__Usage__c WHERE blng__UsageSummary__c IN :usageSummaryIds');
        for (blng__Usage__c usage : Database.query(query)) {
            System.debug('usage:' + usage);
            List<blng__Usage__c> usageLinesWithUsageSummaryId = usageSummaryIdToUsageLinesMap.get(usage.blng__UsageSummary__c);
            if (usageLinesWithUsageSummaryId == null) {
                usageLinesWithUsageSummaryId = new List<blng__Usage__c>();
                usageSummaryIdToUsageLinesMap.put(usage.blng__UsageSummary__c, usageLinesWithUsageSummaryId);
            }
            usageLinesWithUsageSummaryId.add(usage);
            if (usage.Booking__c != null) bookingIds.add(usage.Booking__c);
            if (usage.Instance__c != null) instanceIds.add(usage.Instance__c);
        }

        System.debug('usageSummaryIdToUsageLinesMap');
        for (Id key : usageSummaryIdToUsageLinesMap.keyset()) {
            System.debug('key: ' + key);
            for (blng__Usage__c value : usageSummaryIdToUsageLinesMap.get(key)) {
                System.debug('value: ' + value);
            }
        }

        instances = new Map<Id, Instance__c>([SELECT Id, Instance_Name__c FROM Instance__c WHERE Id IN :instanceIds]);
        bookings = new Map<Id, Booking__c>([SELECT Id, Material_Price__c, PO_Number__c, Student__c, Tuition_Price__c FROM Booking__c WHERE Id IN :bookingIds]);
        for (Booking__c booking : bookings.values()) {
            if (booking.Student__c != null) studentIds.add(booking.Student__c);
        }

        students = new Map<Id, Account>([SELECT Id, Business_Unit__pc, Cost_Centre_Number__pc, Name FROM Account WHERE Id IN :studentIds]);
    }

    private static Credit_Note_Backing_Detail__c createIndividualCreditNoteBackingDetail(blng__Usage__c usageLine) {
        Credit_Note_Backing_Detail__c creditNoteBackingDetail = new Credit_Note_Backing_Detail__c();
        if (bookings.containsKey(usageLine.Booking__c)) {
            Booking__c booking = bookings.get(usageLine.Booking__c);
            creditNoteBackingDetail.Customer_PO_Number__c = booking.PO_Number__c;
            creditNoteBackingDetail.Material_Price__c = booking.Material_Price__c;
            creditNoteBackingDetail.Tuition_Price__c = booking.Tuition_Price__c;
            if (students.containsKey(booking.Student__c)) {
                Account student = students.get(booking.Student__c);
                creditNoteBackingDetail.Business_Unit__c = student.Business_Unit__pc;
                creditNoteBackingDetail.Cost_Centre__c = student.Cost_Centre_Number__pc;
                creditNoteBackingDetail.Student_Name__c = student.Name;
            }
        }
        if (instances.containsKey(usageLine.Instance__c)) {
            Instance__c instance = instances.get(usageLine.Instance__c);
            creditNoteBackingDetail.Course_Name__c = instance.Instance_Name__c;
        }
        return creditNoteBackingDetail;
    }
}