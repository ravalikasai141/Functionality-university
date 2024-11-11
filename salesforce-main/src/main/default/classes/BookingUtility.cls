/*
* @who   Patrick Duncan <patrick.duncan@weare4c.com>
* @what  Class for deciding whether Booking__c or Booking_Line__c records can be assigned a new Instance__c lookup 
			by looking at the Capacity of that Instance__c record's sessions and calculating the Booked__c field on Session__c if there is avalability 
* @when  14/1/2020
*/
public with sharing class BookingUtility {
	public static List<Booking_Line__c> getNonCancelledBookingLines(List<Booking_Line__c> bookingLines){
		List<Booking_Line__c> nonCancelledBookingLines = new List<Booking_Line__c>();
		for(Booking_Line__c bookingLine:bookingLines){
			if(bookingLine.On_Hold__c != 'Cancelled'){
				nonCancelledBookingLines.add(bookingLine);
			}
		}
		return nonCancelledBookingLines;
	}
}