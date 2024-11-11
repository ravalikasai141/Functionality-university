public class Booking_BookingServiceFactory {

    public static Booking_BookingService getInstance() {
        if (Test.isRunningTest())
            return new MockBookingService();
        else 
            return new Booking_BookingServiceImpl();
    }
    
    public class MockBookingService implements Booking_BookingService {
        public Opportunity createUpdateBooking(Booking_Rest_Controller.BookingDTO bookingDto){
            return null;
        }
    }
    
}