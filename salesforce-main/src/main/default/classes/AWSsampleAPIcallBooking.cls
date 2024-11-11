public with sharing class AWSsampleAPIcallBooking {
    public static boolean firstRun = true;
    public static HttpCalloutMock mock = null;

    @future(callout=true)
    public static void awsBookingCallout(Set<Id> bookingIds) {
        if (bookingIds.isEmpty()) {
            return;
        }

        List<Booking__c> bookingListToUpdate = new List<Booking__c>();
        List<Integration_Log__c> integrationListToInsert = new List<Integration_Log__c>();
        List<String> saveIntegrationLogErrors = new List<String>();
        List<String> saveBookingErrors = new List<String>();

        AWSsampleAPIUtil.AuthToken at = AWSsampleAPIUtil.getAccessToken();

        List<Booking__c> bookingList = [
            SELECT
                Id,
                Instance__c,
                Instance__r.Instance_ID__c,
                Student__c,
                Student__r.Firstname,
                Student__r.LastName,
                Hub_Account__r.Hub_Username__c,
                Student__r.Phone
            FROM Booking__c
            WHERE Id = :bookingIds AND Instance__r.Instance_ID__c != NULL AND Hub_Account__r.Hub_Username__c != NULL
        ];
        for (Booking__c booking : bookingList) {
            String message = constructMessage(booking);

            String endpoint =
                AWSsampleAPIUtil.retrieveAWSEndpoint() +
                '/booking/confirmed?message=' +
                EncodingUtil.urlEncode(message, 'UTF-8');

            HttpRequest httpRequest = new HttpRequest();
            httpRequest.setMethod('POST');
            httpRequest.setEndpoint(endpoint);
            httpRequest.setHeader('Authorization', 'Bearer ' + at.token);

            Integration_Log__c integ = new Integration_Log__c();
            String response;

            try {
                HttpResponse httpResponse = new Http().send(httpRequest);
                response = httpResponse.getStatusCode() + ': ' + httpResponse.getBody();
                if (httpResponse.getStatusCode() == 200) {
                    booking.BookedAPI__c = true;
                    booking.Initiate_External_Callout__c = false;
                    bookingListToUpdate.add(booking);
                }
                integ = AWSsampleAPIUtil.createIntegrationLog('HUB', endpoint, response, booking.Id);
                integrationListToInsert.add(integ);
            } catch (System.Exception e) {
                response += ' : ' + String.valueOf(e.getMessage());
                integ = AWSsampleAPIUtil.createIntegrationLog('HUB', endpoint, response, booking.Id);
                integrationListToInsert.add(integ);
            }
        }
        if (integrationListToInsert.size() > 0) {
            List<Database.SaveResult> integrationLogInsert = Database.insert(integrationListToInsert, false);
            saveIntegrationLogErrors = AWSsampleAPIUtil.retrieveDMLErrors(
                integrationLogInsert,
                integrationListToInsert
            );
        }
        if (bookingListToUpdate.size() > 0) {
            List<Database.SaveResult> bookingListUpdate = Database.update(bookingListToUpdate, false);
            saveBookingErrors = AWSsampleAPIUtil.retrieveDMLErrors(bookingListUpdate, bookingListToUpdate);
        }
        if (!at.valid) {
            update at.authToken;
        }
        if (saveIntegrationLogErrors.size() > 0 || saveBookingErrors.size() > 0) {
            AWSsampleAPIUtil.sendFailedDMLEmail(saveIntegrationLogErrors, saveBookingErrors, 'Confirmed');
        }
    }

    private static String constructMessage(Booking__c booking) {
        Date bookingActivated = System.today();
        return '{"email": "' +
            booking.Hub_Account__r.Hub_Username__c +
            '","firstname": "' +
            booking.Student__r.FirstName +
            '","lastname": "' +
            booking.Student__r.LastName +
            '","phone": "' +
            booking.Student__r.Phone +
            '","productId": "' +
            booking.Instance__r.Instance_ID__c +
            '","bookingActivatedOn": "' +
            bookingActivated +
            '"}';
    }
}
