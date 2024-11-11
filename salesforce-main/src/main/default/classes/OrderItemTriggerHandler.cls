public with sharing class OrderItemTriggerHandler {
    public static void handleBeforeInsert(List<OrderItem> orderItemList) {
        if (orderItemList.size() > 0) {
            Set<Id> orderIds = new Set<Id>();
            Set<Id> productIds = new Set<Id>();
            Set<Id> quoteLineIds = new Set<Id>();
            for (OrderItem orderItem : orderItemList) {
                orderIds.add(orderItem.OrderID);
                productIds.add(orderItem.Product2Id);
                quoteLineIds.add(orderItem.SBQQ__QuoteLine__c);
            }

            Map<Id, Order> orderMap = createOrderMap(orderIds);
            //Map<Id, Product2> productMap = createProductMap(productIds);
            //Map<Id, SBQQ__QuoteLine__c> quoteLineMap = createQuoteLineMap(quoteLineIds);

            for (OrderItem orderItem : orderItemList) {
                if (orderItem.OrderId != null) {
                    Order order = orderMap.get(orderItem.OrderId);
                    setBillingAndRevenueRecognitionRule(orderItem, order);
                    orderItem.PaymentTerm__c = order.SBQQ__PaymentTerm__c;

                    /*if (orderItem.Product2Id != null && orderItem.SBQQ__QuoteLine__c != null) {
                        setLegalEntity(orderItem, orderMap.get(orderItem.OrderId), productMap.get(orderItem.Product2Id), quoteLineMap.get(orderItem.SBQQ__QuoteLine__c));
                    }*/
                }
                orderItem.blng__TaxCountry__c = 'United Kingdom'; 
            }  
        }
    }

    public static void handleBeforeUpdate(Map<Id, OrderItem> oldOrderItemMap, List<OrderItem> orderItemList) {
        Set<Id> orderIds = new Set<Id>();
        List<OrderItem> orderItemsEligibleForHoldBillingUpdate = new List<OrderItem>();
        for (OrderItem orderItem : orderItemList) {
            OrderItem oldOrderItem = oldOrderItemMap.get(orderItem.Id);
            if (oldOrderItem.SBQQ__Status__c != 'Activated' && orderItem.SBQQ__Status__c == 'Activated') {
                orderIds.add(orderItem.OrderId);
                orderItemsEligibleForHoldBillingUpdate.add(orderItem);
            }
            if (oldOrderItem.blng__InvoiceRunProcessingStatus__c != 'Completed' && orderItem.blng__InvoiceRunProcessingStatus__c == 'Completed') {
                orderItem.BPP_Completed_Date__c = System.today();
            }
        }

        if (orderItemsEligibleForHoldBillingUpdate.size() > 0) {
            Map<Id, Order> orderMap = createOrderMap(orderIds);
            setHoldBilling(orderItemsEligibleForHoldBillingUpdate, orderMap);
        }
    }

    public static void handleAfterUpdate (Map<Id, OrderItem> oldMap, Map<Id, OrderItem> newMap) {
        DeliveryUtility.createStandaloneDeliveryRecords(oldMap, newMap);
    }

    private static void setBillingAndRevenueRecognitionRule(OrderItem orderItem, Order order) {
        System.debug('@OrderItemTriggerHandler setBillingAndRevenueRecognitionRule');
        System.debug('Order Billing Mode: ' + order.Billing_Mode__c);
        System.debug('Order Booking Type: ' + order.Booking_Type__c);
        System.debug('Order Product Family: ' + orderItem.Product2.Family);

        if (order.Billing_Mode__c == 'Billed off-system') {
            orderItem.blng__BillingRule__c = Label.BR_DNB; 
            orderItem.blng__RevenueRecognitionRule__c = Label.RR_0; 
        } else if (order.Booking_Type__c == 'Learning Media Only' && orderItem.Product2.Family == 'Materials') {
            orderItem.blng__RevenueRecognitionRule__c = Label.RR_3;
        }
    }

    private static void setLegalEntity(OrderItem orderItem, Order order, Product2 product, SBQQ__QuoteLine__c quoteLine) {
        System.debug('@OrderItemTriggerHandler setLegalEntity');
        System.debug('Order Product: ' + orderItem);
        System.debug('Order: ' + order);

        String customerGroup = order.Account.Customer_Group__c;
        String legalEntityName = product.BPP_Legal_Entity__r.Name;
        String billingRuleName = quoteLine.Billing_Rule__r.Name;
        String taxRuleName = quoteLine.Tax_Rule__r.Name;
        System.debug('customerGroup: ' + customerGroup);
        System.debug('legalEntityName: ' + legalEntityName);
        System.debug('billingRuleName: ' + billingRuleName);
        System.debug('taxRuleName: ' + taxRuleName);
        String billingCategory, taxCategory;

        if (customerGroup == 'Intercompany') {
            billingCategory = 'INT';
        } else if (billingRuleName.contains('Combined GL')) {
            billingCategory = 'CMB';
        } else if (billingRuleName.contains('Standard GL')) {
            billingCategory = 'STD';
        } else {
            billingCategory = 'STD';
        }

        if (taxRuleName.startsWith('STD') || taxRuleName == 'Write-Off - STD Tax') {
            taxCategory = 'STD';
        } else if (taxRuleName.startsWith('EXE')) {
            taxCategory = 'EXE';
        } else if (taxRuleName.startsWith('OSS')) {
            taxCategory = 'OSS';
        } else if (taxRuleName.startsWith('ZER')) {
            taxCategory = 'ZER';
        } else {
            taxCategory = 'STD';
        }

        System.debug('billingCategory: ' + billingCategory);
        System.debug('taxCategory: ' + taxCategory);

        Map<Id, blng__LegalEntity__c> legalEntityMap = createLegalEntityMap();
        for (blng__LegalEntity__c legalEntity : legalEntityMap.values()) {
            if (legalEntity.BPP_Billing_Category__c == billingCategory && legalEntity.BPP_Tax_Category__c == taxCategory && legalEntity.BPP_Reporting_Legal_Entity_Name__c == legalEntityName) {
                System.debug('Legal Entity found: ' + legalEntity.Id + ', ' + legalEntity.Name);
                orderItem.blng__LegalEntity__c = legalEntity.Id;
                break;
            }
        }
    }

    private static void setHoldBilling(List<OrderItem> orderItemList, Map<Id, Order> orderMap) {
        System.debug('@OrderItemTriggerHandler setHoldBilling');
        System.debug('Order Product Hold Billing: ' + orderItem.blng__HoldBilling__c);
        System.debug('Order Booking Type: ' + order.Booking_Type__c);
        System.debug('Order Billing Mode: ' + order.Billing_Mode__c);

        Set<String> eligibleBookingTypes = new Set<String>{'Apprenticeship bookings', 'Channel Island bookings', 'Fixed Price Key Client Invoiced Off System', 'Learning Media Only', 'Malaysia Bookings', 'Poland bookings', 'Romania Bookings'};
        for (OrderItem orderItem : orderItemList) {
            Order order = orderMap.get(orderItem.OrderId);
            if (orderItem.blng__HoldBilling__c != 'Yes' && (eligibleBookingTypes.contains(order.Booking_Type__c) || order.Billing_Mode__c == 'Billed off-system')) {
                orderItem.blng__HoldBilling__c = 'Yes';
            }
        }
    }

    private static Map<Id, Order> createOrderMap(Set<Id> orderIds) {
        return new Map<Id, Order>([SELECT Id, Account.Customer_Group__c, Billing_Mode__c, Booking_Type__c, SBQQ__PaymentTerm__c FROM Order WHERE Id IN: orderIds]);
    }

    private static Map<Id, SBQQ__QuoteLine__c> createQuoteLineMap(Set<Id> quoteLineIds) {
        return new Map<Id, SBQQ__QuoteLine__c>([SELECT Billing_Rule__r.Name, Tax_Rule__r.Name, SBQQ__Quote__r.SBQQ__Account__r.Customer_Group__c FROM SBQQ__QuoteLine__c WHERE Id IN: quoteLineIds]);
    }

    private static Map<Id, Product2> createProductMap(Set<Id> productIds) {
        return new Map<Id, Product2>([SELECT Id, BPP_Legal_Entity__r.Name FROM Product2 WHERE Id IN: productIds]);
    }

    private static Map<Id, blng__LegalEntity__c> createLegalEntityMap() {
        return new Map<Id, blng__LegalEntity__c>([SELECT Id, Name, BPP_Billing_Category__c, BPP_Tax_Category__c, BPP_Reporting_Legal_Entity_Name__c FROM blng__LegalEntity__c WHERE BPP_Billing_Category__c != null AND BPP_Tax_Category__c != null AND BPP_Reporting_Legal_Entity_Name__c != null]);
    }
}