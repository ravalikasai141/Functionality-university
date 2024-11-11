/*
* @who   David Lovejoy <davidlovejoy@bpp.com>
* @what  To create Revenue Schedule records for Booking Line and Deliveries
* @when  28/06/2021
*/
public with sharing class RevenueScheduleGenerator {
    private static blng.RevenueRecognitionInput createRevenueRecognitionInput(Id source, String sourceFieldName, Decimal revenueAmount, Date startDate, Date endDate, Id revenueRecognitionRuleId, Id legalEntityId) {
        blng.RevenueRecognitionInput input = new blng.RevenueRecognitionInput();
        input.source = source;
        input.sourceFieldName = sourceFieldName;
        input.revenueAmount = revenueAmount;
        input.startDate = startDate;
        input.endDate = endDate;
        input.revenueRecognitionRuleId = revenueRecognitionRuleId;
        input.legalEntityId = legalEntityId;
        return input;
    }

    /*public static List<blng.RevenueRecognitionResponse> generateFromBookingLines(List<Booking_Line__c> bookingLines) {
        blng.RevenueRecognitionInput[] inputs = new List<blng.RevenueRecognitionInput>();

        for (Booking_Line__c bookingLine : bookingLines) {
            if (isBookingLineEligible(bookingLine)) {
                Date revRecDate = (bookingline.Rev_Rec_Date__c < System.TODAY()) ? System.TODAY() : bookingline.Rev_Rec_Date__c;
                Id revRecRuleId = bookingLine.blng_OrderProduct__r.blng__RevenueRecognitionRule__c;
                Id legalEntityId = bookingLine.blng_OrderProduct__r.blng__LegalEntity__c;

                inputs.add(createRevenueRecognitionInput(bookingLine.Id, 'Booking_Line__c', bookingLine.blng_PreratedAmount__c, revRecDate, null, revRecRuleId, legalEntityId));
            }
        }
        return blng.RevenueRecognition.recognizeRevenue(inputs);
    }*/

    public static List<blng.RevenueRecognitionResponse> generateFromDeliveries(List<Delivery__c> deliveries) {
        blng.RevenueRecognitionInput[] inputs = new List<blng.RevenueRecognitionInput>();
        Map<Id, blng__FinancePeriod__c> legalEntityFinancePeriodMap = createLegalEntityFinancePeriodMap(deliveries);
        
        for (Delivery__c delivery : deliveries) {
            System.debug(delivery);
            blng__FinancePeriod__c financePeriod = legalEntityFinancePeriodMap.get(delivery.BPP_Legal_Entity__c);
            Date revRecDate = (delivery.Dispatched_Date__c < System.TODAY()) && financePeriod != null && financePeriod.blng__PeriodStatus__c == 'Open' ? delivery.Dispatched_Date__c : System.TODAY();
            Decimal amountToRecognize = (delivery.Booking_Line__c != null ? delivery.BPP_Revenue_Amount__c : delivery.BPP_Order_Product_Bookings__c); 
            Id revRecRuleId = delivery.BPP_Revenue_Recognition_Rule__c;
            Id legalEntityId = delivery.BPP_Legal_Entity__c;
            inputs.add(createRevenueRecognitionInput(delivery.Id, 'Delivery__c', amountToRecognize, revRecDate, null, revRecRuleId, legalEntityId));
        }
        System.debug(inputs);
        return blng.RevenueRecognition.recognizeRevenue(inputs);
    }

    /*public static Boolean isBookingLineEligible(Booking_Line__c bookingLine) {
        return bookingLine.On_Hold__c == 'Confirmed' 
            && bookingline.Rev_Rec_Date__c != null 
            && bookingLine.Revenue_Recognition_Triggered__c == FALSE 
            && bookingLine.Revenue_Recognition_Excluded__c == FALSE 
            && bookingLine.blng_OrderProduct__r.blng__RevenueRecognitionRule__r.API_Call_Identifiers__c == 'Booking Line - Full - RR Date';
    }*/

    public static Boolean isDeliveryEligible(Delivery__c delivery) {
        return delivery.Delivery_Status__c == 'Dispatched' 
            && delivery.Revenue_Recognised_Date__c != null 
            && delivery.Revenue_Recognition_Triggered__c == FALSE 
            && delivery.Revenue_Recognition_Excluded__c == FALSE 
            && delivery.BPP_API_Call_Identifier__c == 'Delivery - Full - RR Date'
            && delivery.Stock_Allocated__c == FALSE;
    }

    public static Map<Id, blng__FinancePeriod__c> createLegalEntityFinancePeriodMap(List<Delivery__c> deliveries) {
        Set<Id> legalEntityIds = new Set<Id>();
        List<Date> deliveryDispatchedDates = new List<Date>();
        for (Delivery__c delivery : deliveries) {
            legalEntityIds.add(delivery.BPP_Legal_Entity__c);
            deliveryDispatchedDates.add(delivery.Dispatched_Date__c);
        }

        Map<Id, blng__FinancePeriod__c> legalEntityFinancePeriodMap = new Map<Id, blng__FinancePeriod__c>();
        List<blng__FinancePeriod__c> financePeriodList = [SELECT Id, blng__PeriodStatus__c, blng__PeriodStartDate__c, blng__PeriodEndDate__c, blng__LegalEntity__c FROM blng__FinancePeriod__c WHERE blng__FinanceBook__r.Name = 'Revenue Finance Book' AND blng__LegalEntity__c IN: legalEntityIds];
        for (Date dispatchedDate : deliveryDispatchedDates) {
            for (blng__FinancePeriod__c financePeriod : financePeriodList) {
                if (financePeriod.blng__PeriodStartDate__c <= dispatchedDate && financePeriod.blng__PeriodEndDate__c >= dispatchedDate) {
                    legalEntityFinancePeriodMap.put(financePeriod.blng__LegalEntity__c, financePeriod);
                }
            }
        }
        return legalEntityFinancePeriodMap;
    }
}