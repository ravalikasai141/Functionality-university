public with sharing class AWSsampleAPIUtil {
    public static HttpCalloutMock mock = null;
    public static final Integer TOKEN_REAUTH_THRESHOLD = 30;

    public static AuthToken getAccessToken() {
        Authorisation_Token__c authToken = [
            SELECT LastModifiedDate, Access_Token__c, Expires_In__c
            FROM Authorisation_Token__c
            WHERE Authorisation_Type__c = 'BPP API Gateway'
            LIMIT 1
        ];
        Integer expiresIn = (authToken.Expires_In__c != null ? Integer.valueOf(authToken.Expires_In__c) : 1);
        DateTime expiredTime = authToken.LastModifiedDate.addSeconds(expiresIn - TOKEN_REAUTH_THRESHOLD);
        Boolean tokenValid = expiredTime > System.now();

        AuthToken at = new AuthToken();
        if (tokenValid) {
            at.authToken = authToken;
            at.token = authToken.Access_Token__c;
            at.valid = true;
        } else {
            OAuthTokenRetriever oAuthTokenRetriever = new OAuthTokenRetriever();
            Authorisation_Token__c newAuthToken;
            Map<String, Authorisation_Token__c> accessTokenMap = oAuthTokenRetriever.getNewAccessToken();

            for (String key : accessTokenMap.keyset()) {
                if (!key.contains('Error')) {
                    newAuthToken = accessTokenMap.get(key);
                    newAuthToken.Id = authToken.Id;
                    at.authToken = newAuthToken;
                    at.token = newAuthToken.Access_Token__c;
                    at.valid = false;
                }
            }
        }
        return at;
    }

    public static Integration_Log__c createIntegrationLog(
        String type,
        String endpoint,
        String response,
        Id salesforceId
    ) {
        Integration_Log__c integrationLog = new Integration_Log__c(
            Integration_Type__c = type,
            Request__c = endpoint,
            Response__c = response,
            Salesforce_ID__c = salesforceId
        );
        return integrationLog;
    }

    public static List<String> retrieveDMLErrors(List<Database.SaveResult> saveResultList, List<SObject> recordList) {
        List<String> saveErrors = new List<String>();

        String sObjectType = recordList.get(0).Id.getSobjectType().getDescribe().getName();
        String listType = 'List<' + sObjectType + '>';
        List<SObject> castedRecords = (List<SObject>) Type.forName(listType).newInstance();
        castedRecords.addAll(recordList);

        Integration_Log__c currentIntegrationLog;
        Booking__c currentBooking;
        for (Integer i = 0; i <= saveResultList.size() - 1; i++) {
            Database.SaveResult sr = saveResultList.get(i);

            if (sObjectType == 'Integration_Log__c') {
                currentIntegrationLog = (Integration_Log__c) castedRecords.get(i);
            } else if (sObjectType == 'Booking__c') {
                currentBooking = (Booking__c) castedRecords.get(i);
            }

            if (!sr.isSuccess()) {
                for (Database.Error err : sr.getErrors()) {
                    System.debug(err);
                    if (sObjectType == 'Integration_Log__c') {
                        saveErrors.add(
                            'Integration Log record insert, ' +
                                currentIntegrationLog.Id +
                                ',' +
                                currentIntegrationLog.Salesforce_ID__c +
                                ',' +
                                err.getStatusCode() +
                                ': ' +
                                err.getMessage() +
                                '<br/>'
                        );
                    } else if (sObjectType == 'Booking__c') {
                        saveErrors.add(
                            'Booking record update,,' +
                                currentBooking.Id +
                                ', ' +
                                err.getStatusCode() +
                                ': ' +
                                err.getMessage() +
                                '<br/>'
                        );
                    }
                }
            }
        }
        System.debug(saveErrors);
        return saveErrors;
    }

    public static void sendFailedDMLEmail(
        List<String> saveIntegrationLogErrors,
        List<String> saveBookingErrors,
        String status
    ) {
        Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
        List<String> toAddresses = new List<String>{ UserInfo.getUserName() };
        List<String> ccAddresses = new List<String>{ 'davidlovejoy@bpp.com' };
        message.setToAddresses(toAddresses);
        message.setCcAddresses(ccAddresses);

        message.subject = 'Booking ' + status + ' update contained errors (' + System.now() + ')';
        String body =
            'To whom it may concern, <br/><br/>' +
            'Please find attached csv containing errors from the "Booking ' +
            status +
            '" update.<br/>';
        body +=
            'Summary:<br/>* Number of Integration Log insert failures: ' +
            saveIntegrationLogErrors.size() +
            '<br/>* Number of Booking update failures: ' +
            saveBookingErrors.size() +
            ')<br/><br/>';
        body += 'Kind Regards, <br/><br/> Salesforce Admin';
        message.setHtmlBody(body);

        Messaging.EmailFileAttachment csvAttachment = createBookingErrorCSV(
            saveIntegrationLogErrors,
            saveBookingErrors,
            status
        );
        if (csvAttachment.getBody() != null) {
            message.setFileAttachments(new List<Messaging.EmailFileAttachment>{ csvAttachment });
            Messaging.SingleEmailMessage[] messages = new List<Messaging.SingleEmailMessage>{ message };
            if (!Test.isRunningTest()) {
                Messaging.SendEmailResult[] results = Messaging.sendEmail(messages);
            }
        }
    }

    public static Messaging.EmailFileAttachment createBookingErrorCSV(
        List<String> saveIntegrationLogErrors,
        List<String> saveBookingErrors,
        String status
    ) {
        String csvHeader = 'Transaction Type,Integration Log Id,Booking Id,Error Message';
        String rows = '';
        for (String integErrors : saveIntegrationLogErrors) {
            rows += integErrors;
        }
        for (String bookingErrors : saveBookingErrors) {
            rows += bookingErrors;
        }
        String csvFinal = (rows != '' ? csvHeader + rows : null);

        Messaging.EmailFileAttachment csvAttachment = new Messaging.EmailFileAttachment();
        if (csvFinal != null) {
            csvAttachment.setFileName('Booking ' + status + 'update errors (' + System.now() + ')');
            csvAttachment.setBody(Blob.valueOf(csvFinal));
        }
        return csvAttachment;
    }

    /**
     * Retrieves the AWS endpoint based on the org name.
     *
     * @return The AWS endpoint if available for the org; otherwise, null.
     */
    public static String retrieveAWSEndpoint() {
        String org = determineOrgName();

        String dsemDeveloperName = org + '_AWS';
        Domain_Specific_Endpoint_Mapping__mdt dsem = Domain_Specific_Endpoint_Mapping__mdt.getInstance(
            dsemDeveloperName
        );

        return dsem?.Endpoint__c;
    }

    /**
     * Determines the org name based on the Salesforce domain.
     *
     * @return The name of the org.
     */
    public static String determineOrgName() {
        System.Domain domain = System.DomainParser.parse(URL.getOrgDomainUrl());
        String org = 'Production';

        if (!String.isEmpty(domain.getSandboxName())) {
            org = domain.getSandboxName().capitalize();
            if (org.contains('dev')) {
                org = 'Dev';
            }
        }
        return org;
    }

    /**
     * Represents an authentication token.
     */
    public class AuthToken {
        public Authorisation_Token__c authToken;
        public String token;
        public Boolean valid;
    }
}
