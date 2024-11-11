/*
* @who   David Lovejoy <davidlovejoy@bpp.com>
* @what  Utility class for Delivery records
* @when  11/01/2021
*/
public with sharing class DeliveryUtility {
    public static List<Instance__c> getInstanceList(Set<Id> instanceIds) {
        List<Instance__c> instanceList = [SELECT Id, Start_Date__c, Study_Location__r.Address_1__c, Study_Location__r.Address_2__c, Study_Location__r.Address_3__c, Study_Location__r.City__c, Study_Location__r.Postal_Code__c, Study_Location__r.Country__c, Study_Location__r.Country__r.region__c FROM Instance__c WHERE Id IN: instanceIds];
        return instanceList;
    }

    public static List<Address__c> getAddressList(Set<Id> accountIds) {
        List<Address__c> addressList = [SELECT Student__c, Student__r.IsPersonAccount, Student__r.Name, Student__r.Phone, Student__r.PersonEmail, Student__r.BPP_Deliver_To_Contact__c, Student__r.BPP_Deliver_To_Contact__r.Name, Student__r.BPP_Deliver_To_Contact__r.Email, Student__r.BPP_Deliver_To_Contact__r.Phone, Street_1__c, Street_2__c, Street_3__c, City__c, Zip_Postal_Code__c, Lookup_Country__c, Lookup_Country__r.region__c, Primary_Delivery__c, Primary__c, Delivery_Instructions__c FROM Address__c WHERE Active__c = TRUE AND (Primary_Delivery__c = TRUE OR Primary__c = TRUE) AND Student__c IN: accountIds];
        return addressList;
    }

    public static Map<Id, List<Address__c>> createAccountAddressMap(Set<Id> accountIds, List<Address__c> addressList) {
        Map<Id, List<Address__c>> accountAddressMap = new Map<Id, List<Address__c>>();
        for (Id accountId : accountIds) {
            List<Address__c> studentAddresses = new List<Address__c>();
            for (Address__c address : addressList) {
                if (address.Student__c == accountId) {
                    studentAddresses.add(address);
                }
            }  
            accountAddressMap.put(accountId, studentAddresses);
        }
        return accountAddressMap;
    }

    public static List<Order> getOrderList(Set<Id> orderIds) {
        List<Order> orderList = [SELECT AccountId, Name, Order.Account.Name, Order.Account.RecordTypeId, Order.Account.PersonEmail, Order.Account.Company_Email__c, Order.Account.Phone, Order.Account.EORI_Number__c, Order.Account.Head_Office_Country_List__r.region__c, 
                ShippingStreet, ShippingCity, ShippingPostalCode, Shipping_Address_Country__c, Shipping_Address_Country__r.region__c, Ship_To_Address__r.Id, Ship_To_Address__r.Student__c, Ship_To_Address__r.Student__r.Name, Ship_To_Address__r.Student__r.PersonEmail, 
                Ship_To_Address__r.Student__r.Phone, Ship_To_Address__r.Student__r.BPP_Deliver_To_Contact__r.Name, Ship_To_Address__r.Student__r.BPP_Deliver_To_Contact__r.Email, Ship_To_Address__r.Student__r.BPP_Deliver_To_Contact__r.Phone, 
                Deliver_Materials_to_Student__c, Stock_Site__c, Delivery_Instructions__c, SBQQ__Quote__r.Booking_Type__c,
               (SELECT OrderId, Product2.Standalone_Material__c,Product2.Family__c, UnitPrice, SBQQ__RequiredBy__r.Product2Id, Family__c, OrderItemNumber, Product2.Name, SBQQ__QuotedQuantity__c, Product2.ProductCode, Product2.Weight__c, Product2.Available_Stock__c, 
               Product2.Format__c, Product2.Product_Financial_Dimension__c, Product2.Project_Financial_Dimension__c, Product2.Division_Financial_Dimension__c, Product2.Cost_Centre_Financial_Dimension__c FROM OrderItems) 
               FROM Order WHERE Id IN :orderIds];
        return orderList;
    }

    public static Set<Id> getProductIds(List<Order> orderList) {
        Set<Id> productIds = new Set<Id>();
        for (Order order : orderList) {
            if (!order.OrderItems.isEmpty()) {
                for (OrderItem orderItem : order.OrderItems) {
                    if (orderItem.SBQQ__RequiredBy__c == NULL && !orderItem.Product2.Name.contains('Postage')) {
                        productIds.add(orderItem.Product2Id);
                    }
                }
            }
        }
        return productIds;
    }

    public static List<OrderItem> getOrderItemList(List<Order> orderList) {
        List<OrderItem> orderItemList = new List<OrderItem>();
        for (Order order : orderList) {
            if (!order.OrderItems.isEmpty()) {
                for (OrderItem orderItem : order.OrderItems) {
                    if (orderItem.Product2.Family__c == 'Materials' && !orderItem.Product2.Name.contains('Postage') && !orderItem.Product2.Name.contains('VLE')) {
                        orderItemList.add(orderItem);
                    }
                }
            }
        }
        return orderItemList;
    }

    public static List<SBQQ__ProductOption__c> getProductOptionList(Set<Id> productIds) {
        List<SBQQ__ProductOption__c> productOptionList = new List<SBQQ__ProductOption__c>();
        for (Product2 product : [SELECT Name, (SELECT Delivery_Default__c, SBQQ__OptionalSKU__c, SBQQ__ConfiguredSKU__c FROM SBQQ__Options__r WHERE SBQQ__Feature__r.Name LIKE '%Materials' AND (NOT SBQQ__OptionalSKU__r.Name LIKE 'VLE%')) FROM Product2 WHERE Id IN: productIds]) {
            if (!product.SBQQ__Options__r.isEmpty()) {
                for (SBQQ__ProductOption__c prodOption : product.SBQQ__Options__r) {
                    productOptionList.add(prodOption);
                }
            }																	  
        }
        return productOptionList;
    }

    public static Map<OrderItem, SBQQ__ProductOption__c> getOrderItemProdOptionMap(List<OrderItem> orderItemList, List<SBQQ__ProductOption__c> productOptionList, List<Booking_Line__c> bookingLineList) {
        Map<OrderItem, SBQQ__ProductOption__c> orderItemProdOptionMap = new Map<OrderItem, SBQQ__ProductOption__c>();
        for (OrderItem orderItem : orderItemList) {
            if (productOptionList == null || productOptionList.size() == 0) {
                orderItemProdOptionMap.put(orderItem, null);
            } 
            else {
                for (Booking_Line__c bookingLine : bookingLineList) {
                    for (SBQQ__ProductOption__c prodOption : productOptionList) {
                        if (bookingLine.BPP_Instance_Product__c == prodOption.SBQQ__ConfiguredSKU__c && bookingLine.blng_OrderProduct__c == orderItem.Id && orderItem.Product2Id == prodOption.SBQQ__OptionalSKU__c) {
                            orderItemProdOptionMap.put(orderItem, prodOption);
                        }       
                    }
                }
        	}
        }
        return orderItemProdOptionMap;
    }

    public static Address__c getStudentDeliveryAddress(List<Address__c> addressList) {
        Address__c addressToUse = new Address__c();
		Boolean addressFound = FALSE;
		for (Address__c address : addressList) {
			if (address.Primary_Delivery__c == TRUE) {
				addressToUse = address;
			}
			if (addressFound == FALSE && address.Primary__c == TRUE) {
				addressToUse = address;
			}
		}
		return addressToUse;
    }

    public static void createStandaloneDeliveryRecords (Map<Id, OrderItem> oldMap, Map<Id, OrderItem> newMap) {
        Set<Id> orderIds = new Set<Id>();
        Set<Id> accountIds = new Set<Id>();
        
        for (OrderItem orderItem : newMap.values()) {
            OrderItem oldOrderItem = oldMap.get(orderItem.Id);
            if (oldOrderItem.SBQQ__Status__c != 'Activated' && orderItem.SBQQ__Status__c == 'Activated') {
                orderIds.add(orderItem.OrderId);
            }
        }
        
        if (orderIds.size() > 0) {
            Map<Id, List<Address__c>> accountAddressMap = new Map<Id, List<Address__c>>();
            List<OrderItem> validOrderItemList = new List<OrderItem>();
            List<Address__c> addressList = new List<Address__c>();
            List<Delivery__c> deliveryRecordsToInsert = new List<Delivery__c>();
            
            List<Order> orderList = getOrderList(orderIds);
            if (orderList.size() > 0) {
                for (Order order : orderList) {
                    if ((!order.OrderItems.isEmpty() && order.SBQQ__Quote__r.Booking_Type__c == 'Learning Media Only') || Test.isRunningTest()) {
                        for (OrderItem orderItem : order.OrderItems) {
                            if (orderItem.Product2.Standalone_Material__c == true) {
                                validOrderItemList.add(orderItem);
                                if (order.AccountId != NULL) {
                                    accountIds.add(order.AccountId);
                                }
                            }
                        }
                    }
                }
            }

            if (validOrderItemList.size() > 0) {
                if (accountIds.size() > 0) {
                    addressList = getAddressList(accountIds);
                }

                if (accountIds.size() > 0 && addressList.size() > 0) {
                    accountAddressMap = createAccountAddressMap(accountIds, addressList);
                }

                for (Order order : orderList) {
                    for (OrderItem orderItem : validOrderItemList) {
                        if (order.Id == orderItem.OrderId) {
                            Delivery__c delivery = createDeliveryRecordsForCustomer(order, orderItem, accountAddressMap.get(order.AccountId), null);
                            deliveryRecordsToInsert.add(delivery);
                        }
                    }
                }

                if (deliveryRecordsToInsert.size() > 0) {
                    insert deliveryRecordsToInsert;
                }
            }
        }
    }

    /*
	*  @description    Method for creating Delivery records for each booking line
   	*  @param  bookingLineList  		List of booking lines to filter
	*/
    public static void createDeliveryRecords(List<Booking_Line__c> bookingLineList) {
        Set<Id> productIds = new Set<Id>();
		Set<Id> orderIds = new Set<Id>();
		Set<Id> instanceIds = new Set<Id>();
		Set<Id> accountIds = new Set<Id>();
		List<Instance__c> instanceList = new List<Instance__c>();
		List<Address__c> addressList = new List<Address__c>();
		List<OrderItem> orderItemList = new List<OrderItem>();
		List<Order> orderList = new List<Order>();
		List<Delivery__c> deliveryRecordsToInsert = new List<Delivery__c>();
		List<SBQQ__ProductOption__c> productOptionList = new List<SBQQ__ProductOption__c>();
		Map<Id, List<Address__c>> accountAddressMap = new Map<Id, List<Address__c>>();
		Map<OrderItem, SBQQ__ProductOption__c> orderItemProdOptionMap = new Map<OrderItem, SBQQ__ProductOption__c>();

        for (Booking_Line__c bookingLine : bookingLineList) {
			instanceIds.add(bookingLine.Instance__c);
			orderIds.add(bookingLine.blng_Order__c);
			accountIds.add(bookingLine.Student__c);
			accountIds.add(bookingLine.blng_Account__c);
        }

        if (instanceIds.size() > 0) {
			instanceList = getInstanceList(instanceIds);
		}

		if (accountIds.size() > 0) {
			addressList = getAddressList(accountIds);
		}

		if (accountIds.size() > 0 && addressList.size() > 0) {
			accountAddressMap = createAccountAddressMap(accountIds, addressList);
		}

		if (orderIds.size() > 0) {
			orderList = getOrderList(orderIds);
		}

		if(orderList.size() > 0) {
			productIds = getProductIds(orderList);
			orderItemList = getOrderItemList(orderList);
		}

		if (productIds.size() > 0) {
			productOptionList = getProductOptionList(productIds);
		}
		
		if (orderItemList.size() > 0) {
			orderItemProdOptionMap = getOrderItemProdOptionMap(orderItemList, productOptionList, bookingLineList);
        }

        /* Delivery debugs - Before it starts creating records*/
        System.debug('@DeliveryUtility.createDeliveryRecords - Debug START');
        for (Instance__c instance : instanceList) {
			System.debug('Instance List: ' + instance);
		}
		for (Order order : orderList) {
			System.debug('Order List: ' + order);
		}
		for (Id productId : productIds) {
			System.debug('Product Id: ' + productId);
		}
		for (OrderItem orderItem : orderItemList) {
			System.debug('Order Product List: ' + orderItem);
		}
		for (SBQQ__ProductOption__c prodOption : productOptionList) {
			System.debug('Product Option List: ' + prodOption);
		}
        System.debug('orderItemProdOptionMap.size(): '+ orderItemProdOptionMap.size());
        for (OrderItem orderItem : orderItemProdOptionMap.keyset()) {
            System.debug('key: ' + orderItem + ' | value: ' + orderItemProdOptionMap.get(orderItem));
        }
        System.debug('@DeliveryUtility.createDeliveryRecords - Debug END');
        
        for (Booking_Line__c bookingLine : bookingLineList) {
            for (Order order : orderList) {
                if (bookingLine.blng_Order__c == order.Id) {
                    for (OrderItem orderItem : orderItemProdOptionMap.keyset()) {
                        if (bookingLine.Id != NULL && bookingLine.On_Hold__c != 'Cancelled' && bookingLine.blng_OrderProduct__c == orderItem.Id) {
                            Delivery__c delivery = null;
                            System.debug('orderItemProdOptionMap' +orderItemProdOptionMap);
                            if (orderItemProdOptionMap.get(orderItem) == null) {
                                delivery = createDeliveryRecordsForCustomer(order, orderItem, accountAddressMap.get(bookingLine.Student__c), bookingLine);
                            System.debug('***delivery'+ delivery);
                            }
                            else if (orderItemProdOptionMap.get(orderItem).Delivery_Default__c == 'Deliver to BPP Location' && instanceList.size() > 0) {
                                for (Instance__c instance : instanceList) {
                                    if (instance.Id == bookingLine.Instance__c) {
                                        delivery = createDeliveryRecordsForBppLocation(instance, order, orderItem, bookingLine);
                                    }
                                }
                            } else if (orderItemProdOptionMap.get(orderItem).Delivery_Default__c == 'Deliver to Customer' && accountAddressMap != NULL) {
                                delivery = createDeliveryRecordsForCustomer(order, orderItem, accountAddressMap.get(bookingLine.Student__c), bookingLine);
                            }
                            if (delivery != null) {
                                deliveryRecordsToInsert.add(delivery);
                            }
                        }
                    }
                }
            }
        }
        
        if (deliveryRecordsToInsert.size() > 0) {
            insert deliveryRecordsToInsert;
        }
    }

    public static Delivery__c createDeliveryRecordsForBppLocation(Instance__c instance, Order order, OrderItem orderItem, Booking_Line__c bookingLine) {
        Boolean isPhysical = TRUE;
        Delivery__c delivery = new Delivery__c();
        delivery.Order_Product__c = orderItem.Id;
        delivery.Quantity__c = 1;

        if (!order.OrderItems.isEmpty()) {
            for (OrderItem oi : order.OrderItems) {
                if (orderItem.Id == oi.Id) {
                    delivery.Available_Stock__c = oi.Product2.Available_Stock__c;
                    delivery.Material_Product_Code__c = oi.Product2.ProductCode;
                    delivery.Weight__c = oi.Product2.Weight__c;
                    /* START OF - Changes made by David Lovejoy - 01/06/2021 - BPP-15229 */
                    delivery.BPP_Division__c = (oi.Product2.Division_Financial_Dimension__c != NULL ? oi.Product2.Division_Financial_Dimension__c : NULL);
                    delivery.BPP_Product__c = (oi.Product2.Product_Financial_Dimension__c != NULL ? oi.Product2.Product_Financial_Dimension__c : NULL);
                    delivery.BPP_Project__c = (oi.Product2.Project_Financial_Dimension__c != NULL ? oi.Product2.Project_Financial_Dimension__c : NULL);
                    delivery.BPP_Cost_Center__c = (oi.Product2.Cost_Centre_Financial_Dimension__c != NULL ? oi.Product2.Cost_Centre_Financial_Dimension__c : NULL);
                    /* END OF - Changes made by David Lovejoy */
                    if (oi.Product2.Format__c != NULL) {
                        isPhysical = (oi.Product2.Format__c == 'Physical' ? TRUE : FALSE);
                        delivery.RecordTypeId = (isPhysical ? Schema.Sobjecttype.Delivery__c.getRecordTypeInfosByName().get('Physical Delivery').getRecordTypeId() : Schema.Sobjecttype.Delivery__c.getRecordTypeInfosByName().get('E-Delivery').getRecordTypeId());
                        delivery.Stock_Site__c = (isPhysical && order.Stock_Site__c != NULL ? order.Stock_Site__c : NULL);
                    }
                }
            }
        }

        delivery.Delivery_Status__c = (isPhysical ? 'Awaiting Allocation' : 'Ready for Fulfilment');
        Boolean isStudent;
        Id studentAccountId = Schema.Sobjecttype.Account.getRecordTypeInfosByName().get('Student Account').getRecordTypeId();
        if (bookingLine != NULL) {
            delivery.Booking_Line__c = bookingLine.Id;
            if (bookingLine.Student__c != NULL) {
                isStudent = bookingLine.Student__r.RecordTypeId == studentAccountId;
                delivery.Account__c = bookingLine.Student__c;
            }
            if (bookingLine.On_Hold__c == 'On Hold' && !Test.isRunningTest()) {
                delivery.Delivery_Status__c = 'On Hold';
            }
        } else {
            isStudent = order.Account.RecordTypeId == studentAccountId;
            delivery.Account__c = (order.Account.Id != NULL ? order.Account.Id : NULL);
        }

        if (isPhysical) {
            if (instance != NULL) {
                delivery.Address_Line_1__c = (instance.Study_Location__r.Address_1__c != NULL ? instance.Study_Location__r.Address_1__c : NULL);
                delivery.Address_Line_2__c = (instance.Study_Location__r.Address_2__c != NULL ? instance.Study_Location__r.Address_2__c : NULL);
                delivery.Address_Line_3__c = (instance.Study_Location__r.Address_3__c != NULL ? instance.Study_Location__r.Address_3__c : NULL);
                delivery.City__c = (instance.Study_Location__r.City__c != NULL ? instance.Study_Location__r.City__c : NULL);
                delivery.Country__c = (instance.Study_Location__r.Country__c != NULL ? instance.Study_Location__r.Country__c : NULL);
                delivery.Delivered_to_BPP_Address__c = (instance.Study_Location__r.Id != NULL ? instance.Study_Location__r.Id : NULL);
                delivery.Postal_Code__c = (instance.Study_Location__r.Postal_Code__c != NULL ? instance.Study_Location__r.Postal_Code__c : NULL);
                delivery.Requested_Delivery_Date__c = (instance.Start_Date__c != NULL ? DateUtil.addBusinessDays(instance.Start_Date__c, -2) : NULL);
                delivery.Recipient_Name__c = (isStudent ? bookingLine.Booking__r.BPP_Student_Name__c : order.Account.Name);
                if (order.Account.EORI_Number__c == NULL && order.Account.Head_Office_Country_List__r.region__c == 'EU' && instance.Study_Location__r.Country__r.region__c != NULL && instance.Study_Location__r.Country__r.region__c == 'EU') {
                    delivery.Delivery_Status__c = 'On Hold';
                }
            }
        }
        return delivery;
	}

    public static Delivery__c createDeliveryRecordsForCustomer(Order order, OrderItem orderItem, List<Address__c> addressList, Booking_Line__c bookingLine) {
        Boolean linkToOrderAddress = FALSE;
        Boolean isPhysical = TRUE;
        Delivery__c delivery = new Delivery__c();
        delivery.Booking_Line__c = (bookingLine != NULL ? bookingLine.Id : NULL);
        delivery.Order_Product__c = orderItem.Id;
        delivery.Quantity__c = (bookingLine == NULL ? orderItem.SBQQ__QuotedQuantity__c : 1);
        delivery.Requested_Delivery_Date__c = System.today();

        if (!order.OrderItems.isEmpty()) {
            for (OrderItem oi : order.OrderItems) {
                if (orderItem.Id == oi.Id) {
                    delivery.Available_Stock__c = oi.Product2.Available_Stock__c;
                    delivery.Material_Product_Code__c = oi.Product2.ProductCode;
                    delivery.Weight__c = oi.Product2.Weight__c;
                    /* START OF - Changes made by David Lovejoy - 01/06/2021 - BPP-15229 */
                    delivery.BPP_Division__c = (oi.Product2.Division_Financial_Dimension__c != NULL ? oi.Product2.Division_Financial_Dimension__c : NULL);
                    delivery.BPP_Product__c = (oi.Product2.Product_Financial_Dimension__c != NULL ? oi.Product2.Product_Financial_Dimension__c : NULL);
                    delivery.BPP_Project__c = (oi.Product2.Project_Financial_Dimension__c != NULL ? oi.Product2.Project_Financial_Dimension__c : NULL);
                    delivery.BPP_Cost_Center__c = (oi.Product2.Cost_Centre_Financial_Dimension__c != NULL ? oi.Product2.Cost_Centre_Financial_Dimension__c : NULL);
                    /* END OF - Changes made by David Lovejoy */
                    if (oi.Product2.Format__c != NULL) {
                        isPhysical = (oi.Product2.Format__c == 'Physical' ? TRUE : FALSE);
                        delivery.RecordTypeId = (isPhysical ? Schema.Sobjecttype.Delivery__c.getRecordTypeInfosByName().get('Physical Delivery').getRecordTypeId() : Schema.Sobjecttype.Delivery__c.getRecordTypeInfosByName().get('E-Delivery').getRecordTypeId());
                        delivery.Stock_Site__c = (isPhysical && order.Stock_Site__c != NULL ? order.Stock_Site__c : NULL);
                    }
                }
            }
        }

        delivery.Delivery_Status__c = (isPhysical ? 'Awaiting Allocation' : 'Ready for Fulfilment');
        if (bookingLine != NULL && bookingLine.Student__c != NULL) {
            delivery.Account__c = bookingLine.Student__c;
            if (bookingLine.On_Hold__c == 'On Hold' && !Test.isRunningTest()) {
                delivery.Delivery_Status__c = 'On Hold';
            }
        } else {
            delivery.Account__c = (order.Account.Id != NULL ? order.Account.Id : NULL);
        }
        
        if (isPhysical) {
            Boolean isStudent = order.Account.RecordTypeId == Schema.Sobjecttype.Account.getRecordTypeInfosByName().get('Student Account').getRecordTypeId();
            if (isStudent) {
                linkToOrderAddress = TRUE;
            } else {
                if (order.Deliver_Materials_to_Student__c == FALSE) {
                    linkToOrderAddress = TRUE;
                } else {
                    // Order.Account is not a Student AND Order.Deliver_Materials_to_Student__c == TRUE
                    if (addressList != NULL && !addressList.isEmpty()) {
                        Address__c address = getStudentDeliveryAddress(addressList);
                        if (address != NULL) {
                            delivery.Delivered_to_Customer_Address__c = address.Id;
                            delivery.Address_Line_1__c = address.Street_1__c;
                            delivery.Address_Line_2__c = address.Street_2__c;
                            delivery.Address_Line_3__c = address.Street_3__c;
                            delivery.City__c = address.City__c;
                            delivery.Postal_Code__c = address.Zip_Postal_Code__c;
                            delivery.Country__c = String.valueOf(address.Lookup_Country__c);
                            delivery.Delivery_Instructions__c = address.Delivery_Instructions__c;
                            delivery.Recipient_Name__c = (bookingLine == NULL && address.Student__r.IsPersonAccount ? address.Student__r.BPP_Deliver_To_Contact__r.Name : address.Student__r.Name);
                            delivery.Phone__c = address.Student__r.Phone;
                            delivery.Email__c = address.Student__r.PersonEmail;
                            if ((order.Account.EORI_Number__c == NULL && order.Account.Head_Office_Country_List__r.region__c == 'EU' && address.Lookup_Country__r.region__c != NULL && address.Lookup_Country__r.region__c == 'EU') || delivery.Recipient_Name__c == NULL) {
                                delivery.Delivery_Status__c = 'On Hold';
                            }
                        }
                    } else {
                        delivery.Delivery_Status__c = 'On Hold';
                    }
                }
            }

            if (linkToOrderAddress == TRUE) {
                // Order.Account is a Student OR Order.Deliver_Materials_to_Student__c == FALSE
                delivery.Delivered_to_Customer_Address__c = order.Ship_To_Address__r.Id;
                String[] address = (order.ShippingStreet != NULL ? order.ShippingStreet.split('\n') : NULL);
                delivery.Address_Line_1__c = (address != NULL && address.size() > 0 && !String.isBlank(address[0]) != NULL ? address[0] : NULL); 
                delivery.Address_Line_2__c = (address != NULL && address.size() > 1 && !String.isBlank(address[1]) != NULL ? address[1] : NULL);
                delivery.Address_Line_3__c = (address != NULL && address.size() > 2 && !String.isBlank(address[2]) != NULL ? address[2] : NULL);
                delivery.City__c = (order.ShippingCity != NULL ? order.ShippingCity : NULL);
                delivery.Postal_Code__c = (order.ShippingPostalCode != NULL ? order.ShippingPostalCode : NULL);
                delivery.Country__c = (order.Shipping_Address_Country__c != NULL ? String.valueOf(order.Shipping_Address_Country__c) : NULL);
                delivery.Delivery_Instructions__c = order.Delivery_Instructions__c;
                delivery.Recipient_Name__c = (isStudent ? order.Ship_To_Address__r.Student__r.Name : order.Ship_To_Address__r.Student__r.BPP_Deliver_To_Contact__r.Name);
                delivery.Phone__c = (isStudent ? order.Ship_To_Address__r.Student__r.Phone : order.Ship_To_Address__r.Student__r.BPP_Deliver_To_Contact__r.Phone);
                delivery.Email__c = (isStudent ? order.Ship_To_Address__r.Student__r.PersonEmail : order.Ship_To_Address__r.Student__r.BPP_Deliver_To_Contact__r.Email);
                if ((order.Account.EORI_Number__c == NULL && order.Account.Head_Office_Country_List__r.region__c == 'EU' && order.Shipping_Address_Country__r.region__c != NULL && order.Shipping_Address_Country__r.region__c == 'EU') || delivery.Recipient_Name__c == NULL) {
                    delivery.Delivery_Status__c = 'On Hold';
                }
            }
        }
        return delivery;
    }

    public static void allocateStock(Map<Stock_Management__c, List<Delivery__c>> stockManagementDeliveryMap) {
        List<Delivery__c> deliveryListToUpdate = new List<Delivery__c>();
        List<Stock_Management__c> stockManagementToUpdate = new List<Stock_Management__c>();

        for (Stock_Management__c stockManagement : stockManagementDeliveryMap.keyset()) {
            Decimal available = stockManagement.Available__c;
            Decimal allocated = stockManagement.Allocated__c;
            Decimal shortage = 0;
            Decimal total = stockManagement.Total__c;
            for (Delivery__c delivery : stockManagementDeliveryMap.get(stockManagement)) {
                Decimal quantity = delivery.Quantity__c;
                delivery.Allocation_Attempts__c++;
                if (available > 0 && available >= quantity) {
                    delivery.Allocation_Date__c = System.now();
                    delivery.Delivery_Status__c = 'Ready for Fulfilment';
                    delivery.Stock_Allocated__c = TRUE;
                    delivery.Added_To_Shortage__c = FALSE;
                    allocated = allocated + quantity;
                    available = available - quantity;
                } else {
                    shortage = shortage + quantity;
                    delivery.Added_To_Shortage__c = TRUE;
                    delivery.Stock_Allocated__c = FALSE;
                }
                deliveryListToUpdate.add(delivery);
            }
            Stock_Management__c stockManagementToModify = new Stock_Management__c(Id = stockManagement.Id, Allocated__c = allocated, Shortage__c = shortage, Total__c = total);
            stockManagementToUpdate.add(stockManagementToModify);
        }

        if (deliveryListToUpdate.size() > 0) {
            update deliveryListToUpdate;
        }

        if (stockManagementToUpdate.size() > 0) {
            update stockManagementToUpdate;
        }
    }

    public static Map<Delivery__c, Stock_Management__c> getStockAllocationRecords(List<String> idList) {
        List<Id> deliveryIdList = new List<Id>();
        List<Id> stockManagementIdList = new List<Id>();
        Map<Delivery__c, Stock_Management__c> deliveryStockManagementMap = new Map<Delivery__c, Stock_Management__c>();
        
        for (String id: idList) {
            String[] getIndividualIds = id.split(',');
            deliveryIdList.add(getIndividualIds[0]);
            stockManagementIdList.add(getIndividualIds[1]);
        }
    
        List<Stock_Management__c> stockManagementList = [SELECT Id, Allocated__c, Available__c, Shortage__c, Total__c, (SELECT Id, Added_To_Shortage__c, Quantity__c, Stock_Management__c FROM StockManagement__r WHERE Id IN: deliveryIdList) FROM Stock_Management__c WHERE Id =: stockManagementIdList];
        for (Stock_Management__c stockManagement : stockManagementList) {
            for (Delivery__c delivery : stockManagement.StockManagement__r) {
                deliveryStockManagementMap.put(delivery, stockManagement);
            }
        }
        
        return deliveryStockManagementMap;
    }

    public static void updateDeliveryUpdateList(List<Delivery__c> deliveryListToUpdate, Delivery__c delivery) {
        for (Integer i = 0; i < deliveryListToUpdate.size(); i++) {
            if (delivery.Id != deliveryListToUpdate[i].Id) {
                continue;
            } else {
                deliveryListToUpdate.remove(i);
            }
        }
    }
    
    public static void updateStockManagementUpdateList(List<Stock_Management__c> stockManagementToUpdate, Stock_Management__c stockManagement) {
        for (Integer i = 0; i < stockManagementToUpdate.size(); i++) {
            if (stockManagement.Id != stockManagementToUpdate[i].Id) {
                continue;
            } else {
                stockManagementToUpdate.remove(i);
            }
        }
    }
}