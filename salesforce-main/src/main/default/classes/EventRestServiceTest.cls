@isTest
private class EventRestServiceTest {
    private static RestRequest mockRequest = new RestRequest();
    private static RestResponse mockResponse = new RestResponse();

    @isTest
    static void itShouldReturn201WithValidPayload() {
        String eventId = 'example-id-1';
        String eventType = new List<String>(Killswitch.INBOUND_PROCESSOR_MAP.keySet())[0];

        // GIVEN an inbound event with a valid payload
        mockInboundRestCall(
            '{' +
                '  "version": "0",' +
                '  "id": "' +
                eventId +
                '",' +
                '  "detail-type": "' +
                eventType +
                '",' +
                '  "source": "example-source",' +
                '  "account": "123412341234",' +
                '  "time": "2023-04-06T07:45:07Z",' +
                '  "region": "eu-west-2",' +
                '  "resources": [],' +
                '  "detail": {' +
                '    "data": {' +
                '      "name": "An example product",' +
                '      "code": "PROD-1234"' +
                '    }' +
                '  }' +
                '}'
        );

        // AND A killswitch exists for both processing all events as well as processing a specific event
        TestUtilities.mockKillswitch(Killswitch.BLOCK_INBOUND_EVENTS, false);
        TestUtilities.mockKillswitch(Killswitch.INBOUND_PROCESSOR_MAP.get(eventType), false);

        Test.startTest();

        // WHEN our method is called
        EventRestService.createQueueJobs();

        Test.stopTest();

        // THEN the statusCode should be returned as 201
        Assert.areEqual(201, mockResponse.statusCode);

        // AND a Queue Job has been created with matching details
        Queue_Job__c resultingQueueJob = [SELECT Job_Type__c FROM Queue_Job__c WHERE External_Id__c = :eventId];
        Assert.areEqual(eventType, resultingQueueJob.Job_Type__c);
    }

    @isTest
    static void itShouldReturn200WithDuplicatePayload() {
        String eventId = 'example-id-1';
        String eventType = new List<String>(Killswitch.INBOUND_PROCESSOR_MAP.keySet())[0];

        // GIVEN a Queue Job with a specific External Id
        Queue_Job__c existingQueueJob = new Queue_Job__c(
            Channel__c = 'Event',
            Status__c = 'Processed',
            External_Id__c = eventId,
            Job_Type__c = eventType
        );
        insert existingQueueJob;

        // AND an inbound event with a valid payload, including the same Event Id as our existing Queue Job
        mockInboundRestCall(
            '{' +
                '  "version": "0",' +
                '  "id": "' +
                eventId +
                '",' +
                '  "detail-type": "' +
                eventType +
                '",' +
                '  "source": "example-source",' +
                '  "account": "123412341234",' +
                '  "time": "2023-04-06T07:45:07Z",' +
                '  "region": "eu-west-2",' +
                '  "resources": [],' +
                '  "detail": {' +
                '    "data": {' +
                '      "name": "An example product",' +
                '      "code": "PROD-1234"' +
                '    }' +
                '  }' +
                '}'
        );

        // AND A killswitch exists for both processing all events as well as processing a specific event
        TestUtilities.mockKillswitch(Killswitch.BLOCK_INBOUND_EVENTS, false);
        TestUtilities.mockKillswitch(Killswitch.INBOUND_PROCESSOR_MAP.get(eventType), false);

        Test.startTest();

        // WHEN our method is called
        EventRestService.createQueueJobs();

        Test.stopTest();

        // THEN the statusCode should be returned as 200
        Assert.areEqual(200, mockResponse.statusCode);

        // AND the body should be returned with a duplicate event message
        Assert.areEqual(EventRestService.DUPLICATE_EVENT, mockResponse.responseBody.toString());

        // AND a no additional Queue Jobs were created
        Assert.areEqual(0, [SELECT COUNT() FROM Queue_Job__c WHERE External_Id__c != :eventId]);
    }

    @isTest
    static void itShouldReturn200IfBlockedByAllEventKillswitch() {
        String eventId = 'example-id-1';
        String eventType = 'exampleType';

        // GIVEN an inbound event with a valid payload
        mockInboundRestCall(
            '{' +
                '  "version": "0",' +
                '  "id": "' +
                eventId +
                '",' +
                '  "detail-type": "' +
                eventType +
                '",' +
                '  "source": "example-source",' +
                '  "account": "123412341234",' +
                '  "time": "2023-04-06T07:45:07Z",' +
                '  "region": "eu-west-2",' +
                '  "resources": [],' +
                '  "detail": {' +
                '    "data": {' +
                '      "name": "An example product",' +
                '      "code": "PROD-1234"' +
                '    }' +
                '  }' +
                '}'
        );

        // AND A killswitch exists
        TestUtilities.mockKillswitch(Killswitch.BLOCK_INBOUND_EVENTS, true);

        Test.startTest();

        // WHEN our method is called
        EventRestService.createQueueJobs();

        Test.stopTest();

        // AND the body should be returned with a duplicate event message
        Assert.areEqual(EventRestService.KILLSWITCH_BLOCKED, mockResponse.responseBody.toString());

        // AND a no additional Queue Jobs were created
        Assert.areEqual(0, [SELECT COUNT() FROM Queue_Job__c WHERE External_Id__c != :eventId]);
    }

    @isTest
    static void itShouldReturn200IfBlockedByJobTypeKillswitch() {
        String eventId = 'example-id-1';
        String eventType = new List<String>(Killswitch.INBOUND_PROCESSOR_MAP.keySet())[0];

        // GIVEN an inbound event with a valid payload
        mockInboundRestCall(
            '{' +
                '  "version": "0",' +
                '  "id": "' +
                eventId +
                '",' +
                '  "detail-type": "' +
                eventType +
                '",' +
                '  "source": "example-source",' +
                '  "account": "123412341234",' +
                '  "time": "2023-04-06T07:45:07Z",' +
                '  "region": "eu-west-2",' +
                '  "resources": [],' +
                '  "detail": {' +
                '    "data": {' +
                '      "name": "An example product",' +
                '      "code": "PROD-1234"' +
                '    }' +
                '  }' +
                '}'
        );

        // AND A killswitch exists for both processing all events as well as processing a specific event
        TestUtilities.mockKillswitch(Killswitch.BLOCK_INBOUND_EVENTS, false);
        TestUtilities.mockKillswitch(Killswitch.INBOUND_PROCESSOR_MAP.get(eventType), true);

        Test.startTest();

        // WHEN our method is called
        EventRestService.createQueueJobs();

        Test.stopTest();

        // AND the body should be returned with a duplicate event message
        Assert.areEqual(EventRestService.KILLSWITCH_BLOCKED, mockResponse.responseBody.toString());

        // AND a no additional Queue Jobs were created
        Assert.areEqual(0, [SELECT COUNT() FROM Queue_Job__c WHERE External_Id__c != :eventId]);
    }

    @isTest
    static void itShouldReturn400WithExpectedPropertyMissingFromPayload() {
        String eventId = 'example-id-1';
        String eventType = new List<String>(Killswitch.INBOUND_PROCESSOR_MAP.keySet())[0];

        // GIVEN an inbound event with a payload missing an expected property ("detail" for this test)
        mockInboundRestCall(
            '{' +
                '  "version": "0",' +
                '  "id": "' +
                eventId +
                '",' +
                '  "detail-type": "' +
                eventType +
                '",' +
                '  "source": "example-source",' +
                '  "account": "123412341234",' +
                '  "time": "2023-04-06T07:45:07Z",' +
                '  "region": "eu-west-2",' +
                '  "resources": []' +
                '}'
        );

        // AND A killswitch exists for both processing all events as well as processing a specific event
        TestUtilities.mockKillswitch(Killswitch.BLOCK_INBOUND_EVENTS, false);
        TestUtilities.mockKillswitch(Killswitch.INBOUND_PROCESSOR_MAP.get(eventType), false);

        Test.startTest();

        // WHEN our method is called
        EventRestService.createQueueJobs();

        Test.stopTest();

        // THEN the statusCode should be returned as 400
        Assert.areEqual(400, mockResponse.statusCode);

        // AND the body should be returned with a missing property message
        Assert.areEqual(EventRestService.MISSING_PROPERTY, mockResponse.responseBody.toString());

        // AND no Queue Jobs were created
        Assert.areEqual(0, [SELECT COUNT() FROM Queue_Job__c]);
    }

    @isTest
    static void itShouldReturn500WithUnhandledError() {
        // GIVEN an inbound event with a payload which cannot be parsed to force an unexpected error
        mockInboundRestCall('Invalid JSON Payload');

        // Run as the current user to avoid MIXED_DML errors
        System.runAs(new User(Id = UserInfo.getUserId())) {
            // AND there is at least one user added to the Admin_Alert_Recipients group
            TestUtilities.addUsersToGroup(
                new List<User>{ new User(Id = UserInfo.getUserId()) },
                'Admin_Alert_Recipients'
            );
        }

        Test.startTest();

        // WHEN our method is called
        EventRestService.createQueueJobs();

        Test.stopTest();

        // THEN the statusCode should be returned as 500
        Assert.areEqual(500, mockResponse.statusCode);

        // AND the body should be returned with an unexpected error message
        Assert.areEqual(EventRestService.UNEXPECTED_ERROR, mockResponse.responseBody.toString());

        // AND no Queue Jobs were created
        Assert.areEqual(0, [SELECT COUNT() FROM Queue_Job__c]);

        // AND an email should have been send
        Assert.areEqual(EventRestService.UNEXPECTED_EVENT_EMAIL_SUBJECT, EventRestService.failedEventEmail.subject);
    }

    /**
     *  Mocks the data received from an inbound POST event to the '/event' endpoint with a given body
     *
     *  @param  body  The body to be used in the mock request
     */
    private static void mockInboundRestCall(String body) {
        // Mock an inbound POST request to the '/event' endpoint
        mockRequest.requestURI = '/event/*';
        mockRequest.httpMethod = 'POST';
        mockRequest.requestBody = Blob.valueOf(body);

        RestContext.request = mockRequest;
        RestContext.response = mockResponse;
    }
}
