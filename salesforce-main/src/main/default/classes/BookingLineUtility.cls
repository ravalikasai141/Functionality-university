/*
* @who   Patrick Duncan <patrick.duncan@weare4c.com>
* @what  Utility class for booking lines
* @when  29/1/2020
*/
public with sharing class BookingLineUtility {

	/*
	*  @description    Method for filtering a list of booking lines that down to those which arent cancelled 
   	*  @param  bookingLineIds  			List of booking lines to filter
   	*  @return    						Filtered list of booking lines
	*/
	public static List<Booking_Line__c> getNonCancelledBookingLines(List<Booking_Line__c> bookingLines){
		List<Booking_Line__c> nonCancelledBookingLines = new List<Booking_Line__c>();
		for(Booking_Line__c bookingLine:bookingLines){
			if(bookingLine.On_Hold__c != 'Cancelled'){
				nonCancelledBookingLines.add(bookingLine);
			}
		}
		return nonCancelledBookingLines;
	}

	/*
	*  @description    Method for building a map of booking line id -> booking line
   	*  @param  bookingLineIds  			Set of booking line ids
   	*  @return    						Map of booking line id -> booking line 
	*/
	public static Map<Id,Booking_Line__c> getBookingLineMap(Set<Id> bookingLineIds){
		return new Map<Id,Booking_Line__c>([SELECT Id, Product_Family__c FROM Booking_Line__c WHERE Id IN :bookingLineIds]);
	}

	/*
	*  @description Method for filtering a set of booking lines down to those whose bookings arent cancelled
   	*  @param  oldMap   		Old bookings lines before update
   	*  @return   				Set of filtered booking lines ids
	*/
	public static Set<Id> getBookingLineIdsWithoutCancelledBookings(Map<Id,Booking_Line__c> oldMap){
		return new Map<Id,Booking_Line__c>([SELECT Id FROM Booking_Line__c WHERE Id IN :oldMap.keySet() AND Booking__r.Booking_Cancelled__c = FALSE]).keySet();
	}

	/* START OF - Changes made by 4c - 20/01/2021 - Usages */
	/*
	*  @description Method for filtering a set of booking lines down to those confirmed and not processed
   	*  @param  bookingLineIds   		Set of booking line ids
   	*  @return   				Set of filtered booking lines ids
	*/
	public static Map<Id,Booking_Line__c> getBookingLineIdsConfirmedNotProcessed(Map<Id,Booking_Line__c> bookingLines){
		Map<Id,Booking_Line__c> bookingLinesConfirmedNotProcessed = new Map<Id,Booking_Line__c>();

		String fieldsInput = String.join(new List<String>(BookingUsageBatch.fieldMapping.keySet()), ',');

		Set<String> bkgLineIds = new Set<String>();
        for(Id key : bookingLines.keySet()) {
			bkgLineIds.add('\''+key+'\'');
        }
        
        String bkgLineIdsString = String.join(new List<String>(bkgLineIds), ',');
		String customerBillingType = '\''+'In Advance'+'\'';
        String chargeType = '\''+'Usage'+'\'';

        String query = String.format('SELECT {0} FROM Booking_Line__c WHERE On_Hold__c = {1} AND Batch_Processed__c = FALSE AND Id IN ({2}) AND blng_Account__r.Billing_Type__c = {3} AND Charge_Type__c = {4}',
		new List<String>{fieldsInput, '\''+'Confirmed'+'\'', bkgLineIdsString, customerBillingType, chargeType});

		System.debug('@BookingLineUtility: getBookingLineIdsConfirmedNotProcessed: query: ' + query);

		bookingLinesConfirmedNotProcessed = new Map<Id,Booking_Line__c>((List<Booking_Line__c>)Database.query(query));
		
		return bookingLinesConfirmedNotProcessed;
	}
	/* END OF - Changes made by 4c - Usages */

    /* START OF - Changes made by David Lovejoy - 01/11/2020 - BPP-7144/8234/8651/10399 */
	public static List<Booking_Line__c> getMaterialBookingLines(List<Booking_Line__c> bookingLines){
		List<Booking_Line__c> materialBookingLines = new List<Booking_Line__c>();
		for(Booking_Line__c bookingLine:bookingLines){
			if(bookingLine.Product_Family__c == 'Materials' || bookingLine.Product_Family__c.contains('Fee')){
				materialBookingLines.add(bookingLine);
			}
		}
		return materialBookingLines;
	}
	/* END OF - Changes made by David Lovejoy */

	/* START OF - Changes made by David Lovejoy - 07/01/2021 - BPP-11870 */
	public static void addStockMaterialDetails(List<Booking_Line__c> bookingLineList) {
		Set<Id> productIds = new Set<Id>();
		Set<Id> orderIds = new Set<Id>();
		List<OrderItem> orderItemList = new List<OrderItem>();
		List<Order> orderList = new List<Order>();
		List<SBQQ__ProductOption__c> productOptionList = new List<SBQQ__ProductOption__c>();
		Map<OrderItem, SBQQ__ProductOption__c> orderItemProdOptionMap = new Map<OrderItem, SBQQ__ProductOption__c>();
														 
		for (Booking_Line__c bookingLine : bookingLineList) {
			orderIds.add(bookingLine.blng_Order__c);
		}

		if (orderIds.size() > 0) {
			orderList = DeliveryUtility.getOrderList(orderIds);
		}

		if(orderList.size() > 0) {
			productIds = DeliveryUtility.getProductIds(orderList);
			orderItemList = DeliveryUtility.getOrderItemList(orderList);
		}

		if (productIds.size() > 0) {
			productOptionList = DeliveryUtility.getProductOptionList(productIds);
		}

		if (orderItemList.size() > 0) {
			orderItemProdOptionMap = DeliveryUtility.getOrderItemProdOptionMap(orderItemList, productOptionList, bookingLineList);
		}

		if (orderItemProdOptionMap.size() > 0) {
			for (Booking_Line__c bookingLine : bookingLineList) {
				for (Order order : orderList) {
					if (bookingLine.blng_Order__c == order.Id) {
						for (OrderItem orderItem : orderItemProdOptionMap.keyset()) {
							if (bookingLine.blng_OrderProduct__c == orderItem.Id) {
								bookingLine.Available_Stock__c = orderItem.Product2.Available_Stock__c;
                        		bookingLine.Material_Product_Code__c = orderItem.Product2.ProductCode;
								bookingLine.Quantity__c = (orderItemProdOptionMap.get(orderItem).Delivery_Default__c == 'Deliver to BPP Location' ? 1 : orderItem.SBQQ__QuotedQuantity__c);
								bookingLine.Weight__c = orderItem.Product2.Weight__c;
							}
						}
					}
				}
			}
		}
	}
    /* END OF - Changes made by David Lovejoy */
    
}