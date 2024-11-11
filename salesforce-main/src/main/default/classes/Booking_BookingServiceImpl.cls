public class Booking_BookingServiceImpl implements Booking_BookingService {
    
    public class BookingDetailException extends Exception{}
    
    private Booking_SponsorshipService sponsorshipService;
    
    private Booking_OpportunityService opportunityService;
    
    private Booking_BookingDetailService bookingDetailService;
    
    private static Integer QUANTITY = 1;
    
    public Booking_BookingServiceImpl() {
        sponsorshipService = new Booking_SponsorshipService(new Booking_AccountService());
        opportunityService = new Booking_OpportunityService(new Booking_AccountService());    
        bookingDetailService = new Booking_BookingDetailService();
    }
    
    public Opportunity createUpdateBooking(Booking_Rest_Controller.BookingDTO bookingDto) {
        Opportunity corpOpp;
        
        if((bookingDto.companyProfileId != '' && bookingDto.companyProfileId != null) && (bookingDto.orderNumber != '' && bookingDto.orderNumber != null))
        {
            Account oppAccount = Util.findCompanyAccountByProfile(bookingDto.companyProfileId);
            Opportunity tempOpp = Util.findOppByOrderNumber(oppAccount.Id,bookingDto.orderNumber);
            if(tempOpp == null)
            {
                corpOpp = opportunityService.createCorporateOpportunity(bookingDto.orderNumber, bookingDto.trainingMangerProfileId, bookingDto.companyProfileId,oppAccount.Name + '- Opp');
            }
            else 
            {  
                //SA - else corporate booking opportunity already exists
                corpOpp = tempOpp; 
            }
        }
        
        Opportunity opportunity = opportunityService.findOpportunityByOrderNumber(bookingDto.orderNumber, bookingDto.studentAccountProfileId);
        if(opportunity == null)
            opportunity = opportunityService.createOpportunity(bookingDto.orderNumber, bookingDto.studentAccountProfileId,corpOpp);
        

    // WEC: Commmented out due to Plan B effort
/*        
        if(bookingDto.companyProfileId != null) {
            sponsorshipService.createActiveSponsorship(bookingDto.studentAccountProfileId, opportunity.Id, bookingDto.companyProfileId, bookingDto.trainingMangerProfileId);
        }
 */       
        //WEC Added if no product id to support plan b. This will skip Booking Detail if there is no product ID.
        if(bookingDto.productInstanceId != '' && bookingDto.productInstanceId != null)
        {
            Booking_Detail__c bookingDetail = bookingDetailService.findBookingDetailByProductInstanceId(bookingDto.productInstanceId, opportunity.Id);
            if(bookingDetail == null)
                bookingDetail = bookingDetailService.createBookingDetail(opportunity.Id, bookingDto.productInstanceId, bookingDto.detailLineItems, Quantity, bookingDto.cost,bookingDto.legacyProductInstanceId, bookingDto.legacyProductInstanceDesc,bookingDto.bookingStatus);
        }else if (bookingDto.legacyProductInstanceId != '' && bookingDto.legacyProductInstanceId != null)
        {
            Booking_Detail__c bookingDetail = bookingDetailService.findBookingDetailByLegacyProductID(bookingDto.legacyProductInstanceId, opportunity.Id);
            if(bookingDetail == null)
                bookingDetail = bookingDetailService.createBookingDetail(opportunity.Id, bookingDto.productInstanceId, bookingDto.detailLineItems, Quantity, bookingDto.cost,bookingDto.legacyProductInstanceId, bookingDto.legacyProductInstanceDesc,bookingDto.bookingStatus);
            else
            {
                // Update booking detail status
                list<String> statusOptions = Util.getPicklistValues('Booking_Detail__c', 'Status__c');

                if(!Util.setContains(statusOptions,bookingDto.bookingStatus) && bookingDto.bookingStatus!='' && bookingDto.bookingStatus!=null)
                {
                    throw new BookingDetailException('Booking Status not a valid option. Status sent: ' + bookingDto.bookingStatus);
                        
                }else
                    bookingDetail.Status__c = bookingDto.bookingStatus;
                
                //Update Booking Detail Legacy Product Description
                bookingDetail.Legacy_Product_Name__c = bookingDto.legacyProductInstanceDesc;
                
                update bookingDetail;
            
            }
            
        }
        return opportunity;
        
    }
    
}