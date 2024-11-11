public with sharing class AWSsampleAPIcallCancelled {
    public static HttpCalloutMock mock = null;

    @future(callout=true)
    public static void awsBookingCancelledCallout(Set<Id> bookingIds) {
        if (bookingIds.isEmpty()) {
            return;
        }

        List<Booking__c> bookingListToUpdate = new List<Booking__c>();
        List<Integration_Log__c> integrationListToInsert = new List<Integration_Log__c>();

        AWSsampleAPIUtil.AuthToken at = AWSsampleAPIUtil.getAccessToken();

        List<Booking__c> bookingList = [
            SELECT Id, Instance__r.Instance_ID__c, Hub_Account__r.Hub_Username__c
            FROM Booking__c
            WHERE Id = :bookingIds AND Instance__r.Instance_ID__c != NULL AND Hub_Account__r.Hub_Username__c != NULL
        ];
        for (Booking__c booking : bookingList) {
            String message = constructMessage(booking);

            String endpoint =
                AWSsampleAPIUtil.retrieveAWSEndpoint() +
                '/booking/cancelled?message=' +
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
                    booking.BookedAPI__c = false;
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
            insert integrationListToInsert;
        }
        if (bookingListToUpdate.size() > 0) {
            update bookingListToUpdate;
        }
        if (!at.valid) {
            update at.authToken;
        }
    }

    private static String constructMessage(Booking__c booking) {
        return '{"email": "' +
            booking.Hub_Account__r.Hub_Username__c +
            '","productId": "' +
            booking.Instance__r.Instance_ID__c +
            '"}';
    }
}
