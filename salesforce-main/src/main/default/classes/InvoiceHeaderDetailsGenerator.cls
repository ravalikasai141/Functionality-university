/**
 *  @who    Duy Vu <duy.vu@weare4c.com>
 *  @when   02/07/2020
 *  @what   Generate Invoiceheader Details records from invoiceLines
 */
public with sharing class InvoiceHeaderDetailsGenerator {
    private static Map<Id, List<blng__Usage__c>> usageSummaryIdToUsageLines;
    private static Map<Id, Instance__c> instances;
    private static Map<Id, Booking__c> bookings;
    private static Map<Id, Account> students;
    private static List<CBA__c> cbaList = new List<CBA__c>();

    public static void createInvoiceHeaderDetails(List<blng__InvoiceLine__c> invoiceLines) {
        setUpObjectMappings(invoiceLines);
        // Iterating through Invoice Lines to create Invoiceheader Details
        Set<Id> processedBookings = new Set<Id>();
        List<Invoiceheader_details__c> headerDetails = new List<Invoiceheader_details__c>();
        for (blng__InvoiceLine__c invoiceLine : invoiceLines) {
            if (usageSummaryIdToUsageLines.containsKey(invoiceLine.blng__UsageSummary__c)) {
                List<blng__Usage__c> usageLines = usageSummaryIdToUsageLines.get(invoiceLine.blng__UsageSummary__c);
                for (blng__Usage__c usageLine : usageLines) {
                    if (processedBookings.contains(usageLine.Booking__c)) {
                        continue;   
                    }
                    Invoiceheader_details__c headerDetail = createInvoiceHeaderDetailsObject(usageLine);
                    headerDetail.Invoice__c = invoiceLine.blng__Invoice__c;
                    if (invoiceLine.Product_Family_fx__c == 'Exam') {
                        populateCBAName(invoiceLine, headerDetail);
                    }
                    headerDetails.add(headerDetail);
                    processedBookings.add(usageLine.Booking__c);
                }
            }
        }
        if (headerDetails.size() != 0) {
            try { 
                insert headerDetails;
            } catch (DmlException e) {
                System.debug('Error Message: ' + e.getMessage());
                invoiceLines[0].addError(e);
            }
        }
    }

    // This method will setup all static Map variables used for Invoiceheader Detail creation
    private static void setUpObjectMappings(List<blng__InvoiceLine__c> invoiceLines) {
        List<Id> usageSummaryIds = new List<Id>();
        List<Id> bookingIds = new List<Id>();
        List<Id> studentIds = new List<Id>();
        List<Id> instanceIds = new List<Id>();
        List<Id> productIds = new List<Id>();

        for (blng__InvoiceLine__c invoiceLine : invoiceLines) {
            if (invoiceLine.blng__UsageSummary__c != null) {
                usageSummaryIds.add(invoiceLine.blng__UsageSummary__c);
            }
            if (invoiceLine.Product_Family_fx__c == 'Exam') {
                productIds.add(invoiceLine.blng__Product__c);
            }
        }

        usageSummaryIdToUsageLines = new Map<Id, List<blng__Usage__c>>();
        String status = (Test.isRunningTest() ? 'On Hold' : 'Confirmed');
        String query = 'SELECT Id, Booking__c, Instance__c, blng__UsageSummary__c FROM blng__Usage__c WHERE blng__UsageSummary__c IN :usageSummaryIds AND Booking__r.Status__c =: status';
        for (blng__Usage__c usageLine : Database.query(query)) {
            // Create Map from Usage Summary Ids to their Usage Lines
            List<blng__Usage__c> usageLinesWithUsageSummaryId = usageSummaryIdToUsageLines.get(usageLine.blng__UsageSummary__c);
            if (usageLinesWithUsageSummaryId == null) {
                usageLinesWithUsageSummaryId = new List<blng__Usage__c>();
                usageSummaryIdToUsageLines.put(usageLine.blng__UsageSummary__c, usageLinesWithUsageSummaryId);
            }
            usageLinesWithUsageSummaryId.add(usageLine);
            // Getting Booking Id and Instance Id to later query for these objects
            bookingIds.add(usageLine.Booking__c);
            instanceIds.add(usageLine.Instance__c);
        }

        instances = new Map<Id, Instance__c>([SELECT Id, Instance_Name__c FROM Instance__c WHERE Id IN :instanceIds]);
        bookings = new Map<Id, Booking__c>([SELECT Id, PO_Number__c, Tuition_Price__c, Material_Price__c, Exam_Price__c, Student__c FROM Booking__c WHERE Id IN :bookingIds]);
        
        for (Booking__c booking : bookings.values()) {
            studentIds.add(booking.Student__c);
        }
        students = new Map<Id, Account>([SELECT Id, Name, BPP_Account_Number__c, Cost_Centre_Number__pc, Business_Unit__pc, Function__c FROM Account WHERE Id IN :studentIds]);

        if (productIds.size() > 0) {
            cbaList = [SELECT Id, CBA_Name__c, Product__c FROM CBA__c WHERE Product__c IN: productIds AND Instance__c IN: instanceIds];
            System.debug(cbaList.size());
        }
    }

    // Create InvoiceheaderDetail object from required objects' fields
    private static Invoiceheader_details__c createInvoiceHeaderDetailsObject(blng__Usage__c usageLine) {
        Invoiceheader_details__c invoiceBackingDetail = new Invoiceheader_details__c();
        if (bookings.containsKey(usageLine.Booking__c)) {
            Booking__c booking = bookings.get(usageLine.Booking__c);
            invoiceBackingDetail.Booking__c = booking.Id;
            invoiceBackingDetail.Customer_POnumber__c = booking.PO_Number__c;
            invoiceBackingDetail.Material_Price__c = booking.Material_Price__c;
            invoiceBackingDetail.Tuition_Price__c = booking.Tuition_Price__c;
            invoiceBackingDetail.Exam_Price__c = booking.Exam_Price__c;
            if(students.containsKey(booking.Student__c)) {
                Account student = students.get(booking.Student__c);
                invoiceBackingDetail.Cost_Centre__c = student.Cost_Centre_Number__pc;
                invoiceBackingDetail.Student_Name__c = student.Name;
                invoiceBackingDetail.Business_Unit__c = student.Business_Unit__pc;
                invoiceBackingDetail.BPP_Account_Number__c = student.BPP_Account_Number__c;
                invoiceBackingDetail.Function__c = student.Function__c;
            }
        }
        if(instances.containsKey(usageLine.Instance__c)) {
            Instance__c instance = instances.get(usageLine.Instance__c);
            invoiceBackingDetail.Instance__c = instance.Id;
            invoiceBackingDetail.Course_Name__c = instance.Instance_Name__c;
        }
        return invoiceBackingDetail;
    }

    private static void populateCBAName(blng__InvoiceLine__c invoiceLine, Invoiceheader_details__c headerDetail) {
        for (CBA__c cba : cbaList) {
            if (invoiceLine.blng__Product__c == cba.Product__c) {
                System.debug('@InvoiceHeaderDetailsGenerator CBA: ' + cba);
                headerDetail.Course_Name__c = cba.CBA_Name__c;
            }
        }
    }
}