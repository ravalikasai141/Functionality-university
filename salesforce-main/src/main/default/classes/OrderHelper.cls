public class OrderHelper {
    @testVisible
    private static List<Messaging.SingleEmailMessage> messageList = new List<Messaging.SingleEmailMessage>();

    public static void updateOrderAddress(List<Order> orderList) {
        Set<Id> addressIds = new Set<Id>();
        Map<Id, Address__c> addressMap = new Map<Id, Address__c>();
        for (Order order : orderList) {
            if (order.Ship_To_Address__c != null) {
                addressIds.add(order.Ship_To_Address__c);
            }
            if (order.Bill_To_Address__c != null) {
                addressIds.add(order.Bill_To_Address__c);
            }
        }
        
        if (addressIds.size() > 0) {
            for (Address__c address : [SELECT Id, City__c, Lookup_Country__c, Lookup_Country__r.Name, Zip_Postal_Code__c, Street_1__c, Street_2__c, Street_3__c, Delivery_Instructions__c FROM Address__c WHERE Id =: addressIds]) {
                addressMap.put(address.Id, address);
            }
            System.debug('@OrderHelper updateOrderAddress addressMap: ' + addressMap);
            if (addressMap.size() > 0) {
                for (Order order : orderList) {
                    if (addressMap.containsKey(order.Ship_To_Address__c)) {
                        setOrderAddressValues(order, addressMap, order.Ship_To_Address__c, 'Shipping');
                    }
                    if (addressMap.containsKey(order.Bill_To_Address__c)) {
                        setOrderAddressValues(order, addressMap, order.Bill_To_Address__c, 'Billing');
                    }
                }
            }
        }
    }

    public static void setOrderAddressValues(Order order, Map<Id, Address__c> addressMap, Id orderAddressId, String addressType) {
        String addressLine2 = (addressMap.get(orderAddressId).Street_2__c != null ? addressMap.get(orderAddressId).Street_2__c : null);
        String addressLine3 = (addressMap.get(orderAddressId).Street_3__c != null ? addressMap.get(orderAddressId).Street_3__c : null);
        order.Delivery_Instructions__c = addressMap.get(orderAddressId).Delivery_Instructions__c;

        if (addressType == 'Shipping') {
            order.ShippingCity = addressMap.get(orderAddressId).City__c;
            order.ShippingCountry = addressMap.get(orderAddressId).Lookup_Country__r.Name;
            order.ShippingPostalCode = addressMap.get(orderAddressId).Zip_Postal_Code__c;
            order.ShippingStreet = addressMap.get(orderAddressId).Street_1__c;
            if (addressLine2 != null) order.ShippingStreet += '\n' + addressLine2;
            if (addressLine3 != null) order.ShippingStreet += '\n' + addressLine3;
            order.Shipping_Address_Country__c = addressMap.get(orderAddressId).Lookup_Country__c;
        } else if (addressType == 'Billing') {
            order.BillingCity = addressMap.get(order.Bill_To_Address__c).City__c;
            order.BillingCountry = addressMap.get(order.Bill_To_Address__c).Lookup_Country__r.Name;
            order.BillingPostalCode = addressMap.get(order.Bill_To_Address__c).Zip_Postal_Code__c;
            order.BillingStreet = addressMap.get(order.Bill_To_Address__c).Street_1__c;
            if (addressLine2 != null) order.BillingStreet += '\n' + addressLine2;
            if (addressLine3 != null) order.BillingStreet += '\n' + addressLine3;
        }
    }

    public static void priceCalculationFailureAlert(Map<Id,Order> newMap, Map<Id,Order> oldMap) {
        Set<Id> orderIds = new Set<Id>();
        for (Order order : newMap.values()) {
            Order oldOrder = oldMap.get(order.Id);
            if (oldOrder.SBQQ__PriceCalcStatus__c != order.SBQQ__PriceCalcStatus__c && order.SBQQ__PriceCalcStatus__c == 'Failed') {
                orderIds.add(order.Id);
            }
        }

        if (orderIds.size() > 0) {
            System.debug('@OrderHelper priceCalculationFailureAlert entered');
            List<Order> orderList = [SELECT Id, OrderNumber, SBQQ__PriceCalcStatusMessage__c, Owner.Name, Owner.Email FROM Order WHERE Id IN: orderIds];
            System.debug('@OrderHelper priceCalculationFailureAlert orderList.size(): ' + orderList.size());
            sendPriceCalculationFailureEmail(orderList);
        }
    }

    public static void sendPriceCalculationFailureEmail(List<Order> orderList) {
        String userEmailAddressesFromLabel = Label.OrderHelperRecipientList;
        String[] ccAddresses = userEmailAddressesFromLabel.split(';');
        
        String orgName = UserHelper.getOrgName();
        for (Order order : orderList) {
            Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
            String toEmail = (Test.IsRunningTest() || order.Owner.Name == 'Middleware' ? ccAddresses.get(0) : order.Owner.Email);
            message.setToAddresses(new List<String>{toEmail});
            message.setCcAddresses(ccAddresses);
            message.subject = orgName + 'Order ' + order.OrderNumber + ' - Price Calculation Job failure';
            String body = 'To ' + order.Owner.Name + ', <br/><br/>';
            body += 'The Price Calculation job has failed for Order ' + order.OrderNumber + '. The Order will remain in an uninvoicable state until this is rectified.<br/>';
            body += 'To fix this, please follow the instructions found on <a href="https://wiki.bpp.com/display/BPP/Salesforce+-+Training+Documents#SalesforceTrainingDocuments-top">this Wiki article</a> (<a href="https://wiki.bpp.com/download/attachments/1081871/Order%20Price%20Calculation%20Job%20failure.docx?version=1&modificationDate=1654869358802&api=v2">link to document download</a>)<br/><br/>';
            body += 'Kind Regards, <br/><br/> Salesforce Admin';
            message.setHtmlBody(body);
            messageList.add(message);
        }

        for (Messaging.SingleEmailMessage message : messageList) {
            System.debug('@OrderHelper sendPriceCalculationFailureEmail message: ' + message);
        }

        if (!Test.isRunningTest()) {
            List<Messaging.SendEmailResult> emailResultList = Messaging.sendEmail(messageList);
            for (Messaging.SendEmailResult emailResult : emailResultList) {
                System.debug('@OrderHelper sendPriceCalculationFailureEmail emailResult: ' + emailResult);
            }
        }
    }
}