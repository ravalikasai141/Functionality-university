/**
 *  Custom REST service class to handle incoming event calls
 */
@RestResource(urlMapping='/event')
global with sharing class EventRestService {
    @testVisible
    private static Messaging.SingleEmailMessage failedEventEmail;

    @testVisible
    private static final String MISSING_PROPERTY = 'The provided data did not have values set for one or more of "id", "detail-type", "time" or "detail"';

    @testVisible
    private static final String DUPLICATE_EVENT = 'Job with provided Id already exists within Salesforce';

    @testVisible
    private static final String UNEXPECTED_ERROR = 'Unexpected Salesforce error';

    @testVisible
    private static final String UNEXPECTED_EVENT_EMAIL_SUBJECT = 'Event Rest Service failed to ingress Event';

    @testVisible
    private static final String KILLSWITCH_BLOCKED = 'Event ignored due to killswitch';

    /**
     *  Handles a POST request for the REST service.
     */
    @HttpPost
    global static void createQueueJobs() {
        try {
            // Extract all data from the event and create a corresponding Queue Job
            Map<String, Object> eventData = (Map<String, Object>) JSON.deserializeUntyped(
                RestContext.request.requestBody.toString()
            );

            String jobType = (String) eventData.get('detail-type');

            // Ignore if killswitch for all inbound events or for this event enabled
            if (
                Killswitch.isEnabled(Killswitch.BLOCK_INBOUND_EVENTS) ||
                (Killswitch.INBOUND_PROCESSOR_MAP.containsKey(jobType) &&
                Killswitch.isEnabled(Killswitch.INBOUND_PROCESSOR_MAP.get(jobType)))
            ) {
                createRestResponse(200, KILLSWITCH_BLOCKED);
                return;
            }

            // Validate that all required properties have been included in the event
            if (
                !(eventData.containsKey('id') &&
                eventData.containsKey('detail-type') &&
                eventData.containsKey('time') &&
                eventData.containsKey('detail'))
            ) {
                createRestResponse(400, MISSING_PROPERTY);
                return;
            }

            // Ensure that we have not already processed this event
            String jobId = (String) eventData.get('id');
            if ([SELECT COUNT() FROM Queue_Job__c WHERE External_Id__c = :jobId] > 0) {
                createRestResponse(200, DUPLICATE_EVENT);
                return;
            }

            // Convert the eventTime string into DateTime type. Conversion must be done this way as it is the only
            // way that Salesforce supports consuming ISO 8601 Date Time formats
            DateTime eventTime = (DateTime) JSON.deserialize(JSON.serialize(eventData.get('time')), DateTime.class);

            // consume data if we find it. Use detail if not, so that we have the event
            Map<String, Object> eventDetails = (Map<String, Object>) eventData.get('detail');
            eventDetails = eventDetails.containsKey('data')
                ? (Map<String, Object>) eventDetails.get('data')
                : eventDetails;

            insert new Queue_Job__c(
                Channel__c = 'Event',
                Status__c = 'Pending',
                Event_Time__c = eventTime,
                External_Id__c = jobId,
                Job_Type__c = jobType,
                Job_Content__c = JSON.serializePretty(eventDetails)
            );

            createRestResponse(201, '');
        } catch (Exception ex) {
            Log.critical('Event ingress failed to process event: ' + ex.getMessage() + ' ' + ex.getStackTraceString());

            failedEventEmail = EmailUtilities.submitSystemAlertEmail(
                UNEXPECTED_EVENT_EMAIL_SUBJECT,
                string.format(
                    'An event failed to ingress into Salesforce.<br><br>Error: "{0}".<br><br> Body: "{1}".',
                    new List<string>{ ex.getMessage(), RestContext.request.requestBody.toString() }
                )
            );

            createRestResponse(500, UNEXPECTED_ERROR);
        }
    }

    /**
     *  Constructs a RestResponse which will be sent back to the consumer
     *
     *  @param  code  The status code to send back to the consumer
     *  @param  responseBodyMsg  An optional message to return in the response body
     */
    private static void createRestResponse(Integer code, String responseBodyMsg) {
        // create a response from the context and assign our specified code
        RestResponse response = RestContext.response;
        response.statusCode = code;
        response.responseBody = Blob.valueOf(responseBodyMsg);
    }
}
