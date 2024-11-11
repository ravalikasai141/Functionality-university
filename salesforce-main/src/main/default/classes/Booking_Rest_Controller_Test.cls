@isTest()
public class Booking_Rest_Controller_Test {

    private static final String JSON = '{"studentAccountProfileId" : "dd9719ff-e032-49fd-95ef-22d47a90d9bc","orderNumber" : "10101","companyProfileId" : null,"trainingMangerProfileId" : null,"productInstanceId" : "OFF100101016803","detailLineItems" : ["Line 1", "Line 2", "Line 3"],"cost" : "100.00"}';
    
    public static testMethod void runCreateUpdateBooking_success() {
        System.RestContext.request = new RestRequest();
        RestContext.request.requestURI = '/services/apexrest/v1.0/Booking/CreateUpdateBooking';
        RestContext.request.requestBody = Blob.valueof(JSON);
//        RestContext.request.addHeader('requestBody', JSON);
        RestContext.request.addHeader('httpMethod', 'POST');
        Booking_Rest_Controller.createUpdateBooking(); 
    }
    
}