public with sharing class CreditNoteHandler {
    public static void createCreditNoteOnBookingCancellation(Map<Id, Booking__c> cancelledBookingsMap) {
        System.debug('@CreditNoteHandler createCreditNoteOnBookingCancellation - Entered');
        Map<Id, List<Booking_Line__c>> bookingLineMap = createBookingLineMap(cancelledBookingsMap.keyset());
        Set<Id> orderItemIds = createOrderItemIdSet(bookingLineMap);
        Map<Id, List<blng__InvoiceLine__c>> invoiceLineMap = createInvoiceLineMap(orderItemIds);
        Map<Id, Id> bookingsToProcessMap = new Map<Id, Id>();
        for (Id bookingId : cancelledBookingsMap.keySet()) {
            if (!bookingLineMap.isEmpty() && bookingLineMap.get(bookingId).get(0) != null) {
				populateBookingsToProcessMap(bookingLineMap.get(bookingId).get(0), invoiceLineMap, bookingsToProcessMap);                
            }
        }
        System.debug('@CreditNoteHandler createCreditNoteOnBookingCancellation bookingsToProcessMap size: ' + bookingsToProcessMap.size());
        System.debug('@CreditNoteHandler createCreditNoteOnBookingCancellation bookingsToProcessMap : ' + bookingsToProcessMap);

        if (bookingsToProcessMap.size() > 0) {
            List<blng__CreditNote__c> creditNoteList = new List<blng__CreditNote__c>();
            populateCreditNoteList(bookingsToProcessMap, cancelledBookingsMap, creditNoteList);
        
            if (creditNoteList.size() > 0) {
                System.debug('@CreditNoteHandler creditNoteList size: ' + creditNoteList.size());
                for (blng__CreditNote__c creditNote : creditNoteList) {
                    System.debug('creditNote: ' + creditNote);
                }
                try {
                    insert creditNoteList;
                } catch (Exception e) {
                    System.debug('@CreditNoteHandler Credit Note Insert Error: [' + e.getLineNumber() + '] ' + e.getMessage());
                }

                List<blng__CreditNoteLine__c> creditNoteLineList = new List<blng__CreditNoteLine__c>();
                for (blng__CreditNote__c creditNote : creditNoteList) {
                    populateCreditNoteLineList(cancelledBookingsMap.get(creditNote.BPP_Booking__c), bookingLineMap.get(creditNote.BPP_Booking__c), invoiceLineMap, creditNoteLineList, creditNote.Id);
                }

                if (creditNoteLineList.size() > 0) {
                    System.debug('@CreditNoteHandler creditNoteLineList size: ' + creditNoteLineList.size());
                    for (blng__CreditNoteLine__c creditNoteLine : creditNoteLineList) {
                        System.debug('creditNoteLine: ' + creditNoteLine);
                    }
                    try {
                        insert creditNoteLineList;
                    } catch (Exception e) {
                        System.debug('@CreditNoteHandler Credit Note Line Insert Error: [' + e.getLineNumber() + '] ' + e.getMessage());
                    }

                    updateCreditNoteLines(creditNoteLineList);
                    postCreditNote(creditNoteList);
                }
            }
        }
    }

    public static Map<Id, List<Booking_Line__c>> createBookingLineMap(Set<Id> bookingIds) {
        Map<Id, List<Booking_Line__c>> bookingLineMap = new Map<Id, List<Booking_Line__c>>();
        for (Booking_Line__c bookingLine : [
            SELECT Id, Booking__c, Product_Family__c, Delivery__c, Delivery__r.Delivery_Status__c, Delivery__r.RecordType.Name, blng_OrderProduct__c, blng_OrderProduct__r.Product2Id, blng_PreratedAmount__c
            FROM Booking_Line__c WHERE Booking__c IN: bookingIds
        ]) {
            List<Booking_Line__c> bookingLineForMap = bookingLineMap.get(bookingLine.Booking__c);
            if (bookingLineForMap == null) {
                bookingLineForMap = new List<Booking_Line__c>();
                bookingLineMap.put(bookingLine.Booking__c, bookingLineForMap);
            }    
            bookingLineForMap.add(bookingLine);
        }
        return bookingLineMap;
    }

    private static Set<Id> createOrderItemIdSet(Map<Id, List<Booking_Line__c>> bookingLineMap) {
        Set<Id> orderItemIds = new Set<Id>();
        for (Id key : bookingLineMap.keyset()) {
            for (Booking_Line__c bookingLine : bookingLineMap.get(key)) {
                orderItemIds.add(bookingLine.blng_OrderProduct__c);
            }
        }
        return orderItemIds;
    }

    public static Map<Id, List<blng__InvoiceLine__c>> createInvoiceLineMap(Set<Id> orderItemIds) {
        Map<Id, List<blng__InvoiceLine__c>> invoiceLineMap = new Map<Id, List<blng__InvoiceLine__c>>();
        for (blng__InvoiceLine__c invoiceLine : [
            SELECT Id, blng__Balance__c, blng__LegalEntity__c, blng__OrderProduct__r.blng__BillingRule__c, blng__OrderProduct__r.blng__TaxRule__c, 
            blng__OrderProduct__r.blng__TaxCountry__c, blng__Product__c, blng__Subtotal__c, blng__TaxAmount__c, blng__TotalAmount__c, blng__Invoice__c, blng__Invoice__r.blng__Balance__c, 
            blng__Invoice__r.blng__InvoiceStatus__c, blng__Invoice__r.blng__TotalAmount__c FROM blng__InvoiceLine__c WHERE blng__OrderProduct__c IN: orderItemIds
        ]) {
            List<blng__InvoiceLine__c> invoiceLineForMap = invoiceLineMap.get(invoiceLine.blng__OrderProduct__c);
            if (invoiceLineForMap == null) {
                invoiceLineForMap = new List<blng__InvoiceLine__c>();
                invoiceLineMap.put(invoiceLine.blng__OrderProduct__c, invoiceLineForMap);
            }    
            invoiceLineForMap.add(invoiceLine);
        }
        return invoiceLineMap;
    }

    private static void populateBookingsToProcessMap(Booking_Line__c bookingLine, Map<Id, List<blng__InvoiceLine__c>> invoiceLineMap, Map<Id, Id> bookingsToProcessMap) {
        if (invoiceLineMap.get(bookingLine.blng_OrderProduct__c) != null) {
            for (blng__InvoiceLine__c invoiceLine : invoiceLineMap.get(bookingLine.blng_OrderProduct__c)) {
                if (bookingLine.blng_OrderProduct__r.Product2Id == invoiceLine.blng__Product__c && invoiceLine.blng__Invoice__r.blng__InvoiceStatus__c == 'Posted') {
                    bookingsToProcessMap.put(bookingLine.Booking__c, invoiceLine.blng__Invoice__c);
                }
            }
        }
    }

    private static void populateCreditNoteList(Map<Id, Id> bookingsToProcessMap, Map<Id, Booking__c> cancelledBookingsMap, List<blng__CreditNote__c> creditNoteList) {
        Set<String> advanceSet = new Set<String>{'Advance','In Advance'};
        Set<String> arrearsSet = new Set<String>{'Arrears','In Arrears'};
        Id materialBookingRecordTypeId = Schema.SObjectType.Booking__c.getRecordTypeInfosByName().get('Material or Fee Booking').getRecordTypeId();
        for (Id bookingId : bookingsToProcessMap.keySet()) {
            Booking__c booking = cancelledBookingsMap.get(bookingId);
            if (booking.BPP_Cancellation_Terms__c == 'Inside' && (advanceSet.contains(booking.BPP_Billing_Type__c) || (arrearsSet.contains(booking.BPP_Billing_Type__c) && booking.BPP_Instance_End_Date__c > System.today()) || (arrearsSet.contains(booking.BPP_Billing_Type__c) && booking.RecordTypeId == materialBookingRecordTypeId))) {
                blng__CreditNote__c creditNote = new blng__CreditNote__c(
                    blng__Account__c = booking.TECH_StudentClient__c,
                    blng__CreditNoteDate__c = System.today(),
                    blng__EffectiveTaxDate__c = System.today(),
                    blng__RelatedInvoice__c = bookingsToProcessMap.get(bookingId),
                    blng__TaxCountry__c = 'United Kingdom',
                    BPP_Booking__c = bookingId,
                    BPP_Credit_Note_Reason__c = 'Automated Credit'
                );
                creditNoteList.add(creditNote);
            }
        }
    }

    private static void populateCreditNoteLineList(Booking__c booking, List<Booking_Line__c> bookingLineList, Map<Id,List<blng__InvoiceLine__c>> invoiceLineMap, List<blng__CreditNoteLine__c> creditNoteLineList, Id creditNoteId) {
        for (Booking_Line__c bookingLine : bookingLineList) {
            for (blng__InvoiceLine__c invoiceLine : invoiceLineMap.get(bookingLine.blng_OrderProduct__c)) {
                if (bookingLine.blng_OrderProduct__r.Product2Id == invoiceLine.blng__Product__c) {
                    String deliveryStatus = bookingLine.Delivery__r.Delivery_Status__c;
                    if (bookingLine.Product_Family__c == 'Materials' && booking.BPP_Cancellation_Action__c == 'Don\'t Credit Fulfilled Materials' && 
                        bookingLine.Delivery__r.RecordType.Name == 'Physical Delivery' && (deliveryStatus == 'Sent for Fulfilment' || deliveryStatus == 'Dispatched')) {
                        continue;
                    }
                    if ((booking.BPP_Cancellation_Action__c == 'Credit Fulfilled Materials' && (deliveryStatus == 'Sent for Fulfilment' || deliveryStatus == 'Dispatched')) || 
                    (bookingLine.Delivery__r.RecordType.Name == 'E-Delivery' && (deliveryStatus == 'Sent for Fulfilment' || deliveryStatus == 'Dispatched')) ||
                    ((deliveryStatus != 'Sent for Fulfilment' || deliveryStatus != 'Dispatched'))) {
                        blng__CreditNoteLine__c creditNoteLine = new blng__CreditNoteLine__c(
                            blng__BillingRule__c = invoiceLine.blng__OrderProduct__r.blng__BillingRule__c,
                            blng__CalculateTax__c = false,
                            blng__CreditNote__c = creditNoteId,
                            blng__CreditNoteLineDate__c = System.today(),
                            blng__EffectiveTaxDate__c = System.today(),
                            blng__InvoiceLine__c = invoiceLine.Id,
                            blng__LegalEntity__c = invoiceLine.blng__LegalEntity__c,
                            blng__Product__c = invoiceLine.blng__Product__c,
                            blng__StartDate__c = System.today(),
                            blng__Subtotal__c = bookingLine.blng_PreratedAmount__c,
                            blng__TaxCountry__c = invoiceLine.blng__OrderProduct__r.blng__TaxCountry__c,
                            blng__TaxRule__c = invoiceLine.blng__OrderProduct__r.blng__TaxRule__c
                        );
                        creditNoteLineList.add(creditNoteLine);
                    } 
                }
            }
        }
    }

    private static void updateCreditNoteLines(List<blng__CreditNoteLine__c> creditNoteLineList) {
        Set<Id> invoiceLineIds = new Set<Id>();
        for (blng__CreditNoteLine__c creditNoteLine : creditNoteLineList) {
            invoiceLineIds.add(creditNoteLine.blng__InvoiceLine__c);
        }
        
        if (invoiceLineIds.size() > 0) {
            Map<Id, blng__InvoiceLine__c> invoiceLineMap = new Map<Id, blng__InvoiceLine__c>([SELECT Id, blng__Quantity__c, blng__TaxAmount__c FROM blng__InvoiceLine__c WHERE Id IN: invoiceLineIds]);
            List<blng__CreditNoteLine__c> creditNoteLineListToUpdate = new List<blng__CreditNoteLine__c>();
            for (blng__CreditNoteLine__c creditNoteLine : creditNoteLineList) {
                if (creditNoteLine.blng__InvoiceLine__c != null) {
                    blng__InvoiceLine__c invoiceLine = invoiceLineMap.get(creditNoteLine.blng__InvoiceLine__c);
                    if (invoiceLine.blng__TaxAmount__c != null && invoiceLine.blng__Quantity__c != null) {
                        creditNoteLine.blng__TaxAmount__c = (invoiceLine.blng__TaxAmount__c / invoiceLine.blng__Quantity__c);
                        creditNoteLineListToUpdate.add(creditNoteLine);
                    }
                }
            }
            if (creditNoteLineListToUpdate.size() > 0) {
                for (blng__CreditNoteLine__c creditNoteLine : creditNoteLineList) {
                    System.debug(creditNoteLine.blng__TaxAmount__c);
                }
                try {
                    update creditNoteLineListToUpdate;
                } catch (Exception e) {
                    System.debug('@CreditNoteHandler Credit Note Line Update Error: [' + e.getLineNumber() + '] ' + e.getMessage());
                }
            }
        }
    }

    private static void postCreditNote(List<blng__CreditNote__c> creditNoteList) {
        for (blng__CreditNote__c creditNote : creditNoteList) {
            String result = blng.CreditNoteAPI.postTaxForCreditNote(creditNote.Id);
            System.debug('@CreditNoteHandler postCreditNote result for ' + creditNote.Id + ': ' + result);
        }
    }
}