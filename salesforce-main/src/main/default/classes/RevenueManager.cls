public with sharing class RevenueManager {
    /*public static void processBookingLineRevenue(List<Booking_Line__c> bookingLines) {
        List<blng.RevenueRecognitionResponse> revenueResponses = RevenueScheduleGenerator.generateFromBookingLines(bookingLines);
        for (blng.RevenueRecognitionResponse response : revenueResponses) {
            System.debug(response);
        }
    }*/

    public static void processDeliveryRevenue(List<Delivery__c> deliveries) {
        List<blng.RevenueRecognitionResponse> revenueResponses = RevenueScheduleGenerator.generateFromDeliveries(deliveries);
        for (blng.RevenueRecognitionResponse response : revenueResponses) {
            if (response.totalNumberOfInputsWithErrors > 0) {
                deliveries.get(0).addError('The system has encountered an issue whilst attempting to generate a Revenue Schedule record: ' + response.inputValidationStatus);
            } else {
                System.debug('@processDeliveryRevenue SUCCESS: ' + response.jobId + ' : ' + response.inputValidationStatus);
            }
        }
    }
}