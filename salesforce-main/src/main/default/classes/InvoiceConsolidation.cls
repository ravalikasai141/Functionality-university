/**
 *  @who    Duy Vu <duy.vu@weare4c.com>
 *  @when   14/08/2020
 *  @what   Invoice Consolidation class to generate invoiceGroupId for Order Products from given Orders
 */

public class InvoiceConsolidation {
    public static void processNewOrders(Map<Id,Order> orderMap) {
        List<Order> ordersToConsolidate = new List<Order>();
        for (Order order : orderMap.values()) {
            if(order.Status == 'Activated' && order.Invoice_Consolidation__c) {
                ordersToConsolidate.add(order);
            }
        }

        System.debug(ordersToConsolidate.size());
        if(!ordersToConsolidate.isEmpty()) {
            System.debug('EnteredTheProcessor');
            consolidateOrderProducts(ordersToConsolidate);
        }
        // System.debug('EnteredTheProcessor' );

      //  updateOrderProductDates(orderMap);
    }

    public static void processUpdateOrders(Map<Id, Order> newMap, Map<Id, Order> oldMap) {
        List<Order> ordersToConsolidate = new List<Order>();
        List<Order> ordersToRemoveGrouping = new List<Order>();
        for (Order order : newMap.values()) {
            if(order.Status == 'Activated' && order.Invoice_Consolidation__c) {
                Order oldOrder = oldMap.get(order.Id);
                if(oldOrder.Status != 'Activated' || !oldOrder.Invoice_Consolidation__c) {
                      ordersToConsolidate.add(order);
                  }
            } else if(!order.Invoice_Consolidation__c) {
                ordersToRemoveGrouping.add(order);
            }
        }
        if(!ordersToConsolidate.isEmpty()) {
            consolidateOrderProducts(ordersToConsolidate);
        }
        if(!ordersToRemoveGrouping.isEmpty()) {
            removeGroupingForOrderProducts(ordersToRemoveGrouping);
        }
    }

    /*public static void processUpdateAccount(Map<Id, Account> newMap, Map<Id, Account> oldMap) {
        List<Id> accountIdsWithChangedInvoiceSeparation = new List<Id>();
        for (Account account : newMap.values()) {
            if(account.Invoice_Separation__c != oldMap.get(account.Id).Invoice_Separation__c) {
                accountIdsWithChangedInvoiceSeparation.add(account.Id);
            }
        }
        List<Order> orders = retrieveOrders(accountIdsWithChangedInvoiceSeparation);

        List<Order> ordersToConsolidate = new List<Order>();
        for (Order order : orders) {
            if(order.Status == 'Activated' && order.Invoice_Consolidation__c) {
                ordersToConsolidate.add(order);
            }
        }
        if(!ordersToConsolidate.isEmpty()) {
            consolidateOrderProducts(ordersToConsolidate);
        }
    }*/

    public static void consolidateOrderProducts(List<Order> orders) {
        System.debug('ConsolidationPrderProducts is running');
        List<Id> orderIds = new List<Id>();
        List<Id> accountIds = new List<Id>();
        List<Id> product2Ids = new List<Id>();
        for (Order order : orders) {
            orderIds.add(order.Id);
            accountIds.add(order.AccountId);
        }
        List<OrderItem> orderProducts = retrieveOrderProducts(orderIds);

        // Setting up map from Order Id to its Order Products
        Map<Id, List<OrderItem>> orderIdToOrderProducts = new Map<Id, List<OrderItem>>();
        for (OrderItem orderProduct : orderProducts) {
            List<OrderItem> orderProductsFromOrder;
            if(orderIdToOrderProducts.containsKey(orderProduct.OrderId)) {
                orderProductsFromOrder = orderIdToOrderProducts.get(orderProduct.OrderId);

            } else {
                orderProductsFromOrder = new List<OrderItem>();
                orderIdToOrderProducts.put(orderProduct.OrderId, orderProductsFromOrder);
            }
            orderProductsFromOrder.add(orderProduct);
            product2Ids.add(orderProduct.Product2Id);

        }

        Map<Id, Account> accounts = retrieveAccountMap(accountIds);
        Map<Id, Product2> products = retrieveProductMap(product2Ids);

        for(Order order : orders) {
            if (accounts.containsKey(order.AccountId) && orderIdToOrderProducts.containsKey(order.Id)) {
                Account account = accounts.get(order.AccountId);
                List<OrderItem> orderProductsFromOrder = orderIdToOrderProducts.get(order.Id);
                generateInvoiceGroupId(orderProductsFromOrder, account, products);
            }
        }
        try {
            update orderProducts;
        } catch (DmlException e) {
            System.debug(e);
            orders.get(0).addError(e);
        }
    }

/*    public static void updateOrderProductDates(Map<Id, Order> orders) {
        List<Id> orderIds = new List<Id>();

        for (Id orderId : orders.keySet()) {
            orderIds.add(orderId);
        }

        List<OrderItem> orderProducts = retrieveOrderProducts(orderIds);

        System.debug('Amount of items ' + orderProducts.size());
        System.debug('Amount of orders ' + orderIds.size());

        for (OrderItem orderProduct : orderProducts) {
            orderProduct.ServiceDate = orders.get(orderProduct.OrderId).EffectiveDate;
            System.debug('Updated with this date: ' + orderProduct.ServiceDate);
        }

        try {
            update orderProducts;
        } catch (DmlException e) {
            System.debug(e);
            orders.values().get(0).addError(e);
        }
    }*/

    private static void generateInvoiceGroupId(List<OrderItem> orderProducts, Account account, Map<Id, Product2> products) {
        List<String> invoiceSeparationValues = new List<String>{''};
        if(account.Invoice_Separation__c != null) {
            invoiceSeparationValues = account.Invoice_Separation__c.split(';');
        }
        Boolean sitting = invoiceSeparationValues.contains('Sitting');
        Boolean qualification = invoiceSeparationValues.contains('Qualification');
        Boolean paper = invoiceSeparationValues.contains('Paper');
        Boolean level = invoiceSeparationValues.contains('Level');
        system.debug( '**************orderProducts******' + orderProducts);
        Map<Id,Id> bundleOrderProducts = new Map<Id,Id>();//BPP-18727 New map to hold the Parent orderline id and associated product id
        for(OrderItem orderProduct : orderProducts) {
            if(orderProduct.SBQQ__RequiredBy__c == null){
                bundleOrderProducts.put(orderProduct.id,orderProduct.Product2Id );
                    }
        }
        for(OrderItem orderProduct : orderProducts) {
            Id product2Id = orderProduct.Product2Id ; 
            if(orderProduct.SBQQ__RequiredBy__c != null ){
                Id requiredById = orderProduct.SBQQ__RequiredBy__c ;
                if(bundleOrderProducts.containsKey(requiredById)){
                    product2Id = bundleOrderProducts.get(requiredById); 
                }
            }
            if(products.containsKey(product2Id)) {
                Product2 product = products.get(product2Id);
                List<String> params = new List<String>();
                // {Sitting} part
                if(sitting) {
                    params.add(product.Sitting__c);
                } else {
                    params.add('');
                }
                // {Qualification} part
                if(qualification) {
                    params.add(product.Qualification__c);
                } else {
                    params.add('');
                }
                // {Paper} part
                if (paper) {
                    params.add(product.Paper__c);
                } else {
                    params.add('');
                }
                // {Level} part
                if (level) {
                    params.add(product.Level_PQ__c);
                } else {
                    params.add('');
                }
                // {CustomGroup} part
                if (orderProduct.Custom_Group__c != null) {
                    params.add(orderProduct.Custom_Group__c);
                } else {
                    params.add('');
                }
                system.debug('params'+ params);
                String invoiceGroupId = String.format('{0}{1}{2}{3}{4}', params);
                if(invoiceGroupId != '') {
                    orderProduct.blng__InvoiceGroupId__c = invoiceGroupId;
                    orderProduct.blng__InvoiceGrouping__c = 'Invoice Group ID';
                } else {
                    orderProduct.blng__InvoiceGroupId__c = '';
                    orderProduct.blng__InvoiceGrouping__c = '';
                }
                
            }
        }
    }

    private static void removeGroupingForOrderProducts(List<Order> orders) {
        List<Id> orderIds = new List<Id>();
        for (Order order : orders) {
            orderIds.add(order.Id);
        }
        List<OrderItem> orderProducts = retrieveOrderProducts(orderIds);
        List<OrderItem> orderProductListToUpdate = new List<OrderItem>();
        
        for (OrderItem orderProduct : orderProducts) {
            if (orderProduct.blng__InvoiceGroupId__c != '' && orderProduct.blng__InvoiceGrouping__c != '') {
                orderProduct.blng__InvoiceGroupId__c = '';
            	orderProduct.blng__InvoiceGrouping__c = '';
                orderProductListToUpdate.add(orderProduct);
            }
        }
		
        if (orderProductListToUpdate.size() > 0) {
            try {
                update orderProductListToUpdate;
            } catch (DmlException e) {
                System.debug(e);
                orders.get(0).addError(e);
            }
        }
    }
    
    private static List<Order> retrieveOrders(List<Id> accountIds) {
        return [SELECT Id, AccountId, Status, Invoice_Consolidation__c FROM Order WHERE AccountId IN : accountIds];
    }

    private static List<OrderItem> retrieveOrderProducts(List<Id> orderIds) {
        return [SELECT Id, OrderId, Product2Id, Custom_Group__c, SBQQ__RequiredBy__c, ServiceDate, blng__InvoiceGroupId__c, blng__InvoiceGrouping__c FROM OrderItem WHERE OrderId IN :orderIds];
    }

    private static Map<Id, Account> retrieveAccountMap(List<Id> accountIds) {
        return new Map<Id, Account>([SELECT Id, Invoice_Separation__c FROM Account WHERE Id IN :accountIds]);
    }

    private static Map<Id, Product2> retrieveProductMap(List<Id> product2Ids) {
        return new Map<Id, Product2>([SELECT Id, Sitting__c, Qualification__c, Paper__c, Level_PQ__c
                                                            FROM Product2 WHERE Id IN :product2Ids]);
    }
}