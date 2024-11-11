public class DeliveryTriggerHandler {
    public static void handleAfterUpdate(List<Delivery__c> deliveryList) {
        List<Delivery__c> deliveryRecordsToGenerateRevenueFor = new List<Delivery__c>();
        for (Delivery__c delivery : deliveryList) {
            if (RevenueScheduleGenerator.isDeliveryEligible(delivery)) {
                deliveryRecordsToGenerateRevenueFor.add(delivery);
            }
        }
        if (deliveryRecordsToGenerateRevenueFor.size() > 0) {
            RevenueManager.processDeliveryRevenue(deliveryRecordsToGenerateRevenueFor);
        }
    }
}