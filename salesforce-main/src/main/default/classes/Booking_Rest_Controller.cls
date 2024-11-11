@RestResource(urlMapping='/v1.0/Booking/CreateUpdateBooking')
global with sharing class Booking_Rest_Controller  {

    @HttpPost
    global static Response createUpdateBooking() {
        Response response;
        String requestBody = RestContext.request.requestBody.toString();
        BookingDTO bookingDto = (BookingDTO)JSON.deserialize(requestBody, Booking_Rest_Controller.BookingDTO.class);
        Booking_BookingService bookingService = Booking_BookingServiceFactory.getInstance();
        
        try {
            Opportunity opportunity = bookingService.createUpdateBooking(bookingDto);
            response = new Response('Success', '200', JSON.serialize(opportunity));
        }catch(Exception ex){
        	writeLog(bookingDto, 'Failure' + ':\n' + ex.getLineNumber() + ': ' + ex.getTypeName() + ' - ' + ex.getMessage() + '\n' + ex.getStackTraceString());
        	
            response = new Response('Failure', '400', ex.getLineNumber() + ': ' + ex.getTypeName() + ' - ' + ex.getMessage() + '\n' + ex.getStackTraceString());
        }
        writeLog(bookingDto, 'Success');
        
        return response;
    }
    
    global class Response 
    {
        global String status { get; set; }
        global String code { get; set; }
        global String result { get; set; }
        
        public Response(String status, String code, String result) 
        {
            this.status = status;
            this.code = code;
            this.result=result;
            
	    }
    }
    
    global with sharing class BookingDTO {
        public String studentAccountProfileId;
        public String orderNumber;
        public String companyProfileId;
        public String trainingMangerProfileId;
        public String productInstanceId;
        public List<String> detailLineItems;
        public Decimal cost;
        public String legacyProductInstanceId;
        public String legacyProductInstanceDesc;
        public String bookingStatus;
    }

	/*********************************************************
	* Writes out to the Log in SFDC 
	*
	* trainingMGR : The JSON object passed into the service.
	* Status      : The status string that contains any message 
	*               to enter into the log.
	*
	*********************************************************/
    
    private static void writeLog(BookingDTO bookingDto, String Status)
    {
        Integration_Log_Incoming__c log = new Integration_Log_Incoming__c();
        log.Request_Body__c = JSON.serialize(bookingDto);
        log.Request_Date__c = Datetime.now();
        log.Service_Name__c = 'Booking_Rest_Controller';
        String details = Status;
        log.Details__c = details;
        insert log;
    }    
    
}