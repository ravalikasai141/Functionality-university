public class Booking_BookingDetailService 
{
	
	public class BookingDetailException extends Exception{}
    
    private static String NEW_LINE = '\n';
    
    public Booking_Detail__c findBookingDetailByProductInstanceId(String instanceId, String opportunityId) {
        List<Booking_Detail__c> bookingDetails = [Select Id, Product__c from Booking_Detail__c where Product__r.Instance_Id__c = :instanceId and Opportunity__c = :opportunityId];
        if(bookingDetails.size() > 1)
            throw new BookingDetailException('More than on Booking Detail was found for Product Id: ' + instanceId);
        else if (bookingDetails.size() == 0)
            return null;
        else 
            return bookingDetails[0];
    }
    
    public Booking_Detail__c createBookingDetail(String opportunityId, String instanceId, List<String> details, Integer quantity, Decimal cost, String legacyProductInstanceId, String legacyProductInstanceDesc, String bookingStatus) 
    {
    	list<String> statusOptions = Util.getPicklistValues('Booking_Detail__c', 'Status__c');
        Booking_Detail__c bookingDetail = new Booking_Detail__c();
        
        // WEC 11042014 Fix the product id being set to the first product with and instanceid of ''
    	if (instanceId!=null && instanceId!='')
    	{
        	Product2 product = [Select Id from Product2 where Instance_Id__c = :instanceId Limit 1];
        	bookingDetail.Product__c = product.Id;
    	}
    	
        bookingDetail.Opportunity__c = opportunityId;
        bookingDetail.Quantity__c = quantity;
        bookingDetail.Cost__c = cost;
        
        if(legacyProductInstanceId!=null)
        	bookingDetail.Legacy_Product__c=legacyProductInstanceId;
        	
        if (legacyProductInstanceDesc!=null)
        	bookingDetail.Legacy_Product_Name__c = legacyProductInstanceDesc;
        
		if(!Util.setContains(statusOptions,bookingStatus) && bookingStatus!='' && bookingStatus!=null)
        {
            throw new BookingDetailException('Booking Status not a valid option. Status sent: ' + bookingStatus);
          		
        }else
        	bookingDetail.Status__c = bookingStatus;
        
        String detailString = '';
        for(String detail:details) {
            detailString += detail + NEW_LINE;
        }
        
        bookingDetail.Product_Detail__c = detailString;
        insert bookingDetail;
        return bookingDetail;
    }
    
    /*******************************************************************************************
    * Find the booking detail based on a legacy product id fed into SFDC from an external 
    * product system. 
    * 
    * legacyProductInstanceId 	: The instance id of a product in an external system.
    * opportunityId				: SFDC Opp id that the booking detail belongs to.
    *
    * @returns Booking_Detail__c that has the opp and legacy product id 
    *******************************************************************************************/
    public Booking_Detail__c findBookingDetailByLegacyProductID(String legacyProductInstanceId, String opportunityId)
    {
    	// Look up the Booking Detail; pass results
        List<Booking_Detail__c> bookingDetails = [Select Id, Product__c from Booking_Detail__c where Legacy_Product__c = :legacyProductInstanceId and Opportunity__c = :opportunityId];
        
        //Found multiple results for the legacy product id
        if(bookingDetails.size() > 1)
            throw new BookingDetailException('More than on Booking Detail was found for Legacy Id: ' + legacyProductInstanceId);
        // Found no results
        else if (bookingDetails.size() == 0)
            return null;
        // Found one result
        else 
            return bookingDetails[0];
    	
    }
}