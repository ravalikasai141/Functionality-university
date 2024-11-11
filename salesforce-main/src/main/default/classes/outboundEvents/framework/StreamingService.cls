/**
 * The StreamingService deals with syncing sObjects that have been changed or created
 * via the Object_Stream_Setting metadata
 */
public without sharing class StreamingService {
    /**
     * When set to true this will prevent streaming for this transaction
     */
    public static Boolean preventStream = false;

    /**
     * Used when preventStream is active, this allows the specified event to still
     * trigger
     */
    public static Set<String> allowedEvents = new Set<String> ();

    /**
     * The current SObject type, taken from the sObjects given
     */
    @TestVisible
    private Schema.SObjectType sObjectType;

    /**
     * A list of available streams for the sObject type given
     */
    @TestVisible
    private List<Object_Stream_Setting__mdt> streams {
        get {
            if (streams == null && canFetchStreams) {
                fetchConfig(String.valueOf(sObjectType));
            }
            return streams;
        }
        set;
    }

    /**
     * The operation type ie AFTER_DELETE
     */
    @TestVisible
    private String operation;

    /**
     * A list of records that have been updated or created
     */
    private List<SObject> records;

    /**
     * A comparison list to check previous values for update events
     */
    private Map<Id, SObject> comparison;

    /**
     * A cache of Serializer classes, used to prevent instantiating more than once
     */
    private Map<String, Serializer> serializerCache;

    /**
     * A cache of Emitter classes, used to prevent instantiating more than once
     */
    private Map<String, Emitter> emitterCache;

    /**
     * A boolean check to see if we want to fetch streams
     * useful for testing triggers
     */
    @TestVisible
    private static Boolean canFetchStreams = !System.Test.isRunningTest();

    public StreamingService() {
        serializerCache = new Map<String, Serializer>();
        emitterCache = new Map<String, Emitter>();
    }

    /**
     * Processes the given records and starts comparisons if streams are set
     * @param records A list of records that have been created or updated
     * @param comparison A map of previous values for records, can be empty but not null
     */
    public void process(List<SObject> records, Map<Id, SObject> comparison) {
        // block outbound events if killswitch enabled
        if (Killswitch.isEnabled(Killswitch.BLOCK_OUTBOUND_EVENTS)) {
            return;
        }

        sObjectType = records[0].getSObjectType();

        if ((streams == null || streams.isEmpty())) {
            return;
        }

        if (Trigger.operationType != null) {
            operation = String.valueOf(Trigger.operationType);
        }

        this.records = records;
        this.comparison = comparison;

        for (Object_Stream_Setting__mdt stream : streams) {
            // If prevent stream is on check if the event 
            if (preventStream && !allowedEvents.contains(stream.Event_Name__c)) {
                continue;
            }

            // If there are operation locks check if this is an operation
            // the event supports
            if (!String.isBlank(stream.Operation_Lock__c)) {
                Set<String> operations = getOperationTypes(stream.Operation_Lock__c);

                if (!operations.contains(operation)) {
                    continue;
                }
            }

            // Compare the list against the criteria for each event
            compare(stream);
        }
    }

    /**
     * Compares either by update or create events using the given stream
     * @param stream The stream to perform the comparison against
     */
    private void compare(Object_Stream_Setting__mdt stream) {
        List<String> fields = stream.Fields__c?.split(',');
        Set<Id> allowedRecordTypes = getRecordTypeIds(stream.Record_Types__c);

        Serializer serializer = getSerializer(stream.Serializer__c);

        for (SObject record : records) {
            if (!checkRecordIsOfRecordType(allowedRecordTypes, record)) {
                continue;
            }

            if (!comparison.containsKey(record.Id)) {
                if (checkFieldsAreSet(fields, record)) {
                    serializer.addRecord(record);
                }

                continue;
            }

            if (checkFieldHasChanged(fields, record)) {
                serializer.addRecord(record);
            }
        }

        List<Map<String, Object>> payloads = serializer.serialize();

        if (!payloads.isEmpty()) {
            Emitter emitter = getEmitter(stream.Emitter__c);
            emitter.send(stream.Event_Name__c, payloads);
        }
    }

    /**
     * Checks whether the record has key fields populated
     * @param fields The list of fields to check against
     * @param record The record to check
     * @return  True if any of the fields are populated
     */
    private Boolean checkFieldsAreSet(List<String> fields, SObject record) {
        for (String field : fields) {
            if (record.isSet(field.deleteWhitespace())) {
                return true;
            }
        }

        return false;
    }

    /**
     * Checks whether key fields have changed
     * @param fields The list of fields to check against
     * @param record The record to check
     * @return  True if any of the fields have changed
     */
    private Boolean checkFieldHasChanged(List<String> fields, SObject record) {
        for (String fieldName : fields) {
            String field = fieldName.deleteWhitespace();
            if (record.get(field) == null) {
                if (comparison.get(record.Id).get(field) != null) {
                    return true;
                }
            } else if (!record.get(field).equals(comparison.get(record.Id).get(field))) {
                return true;
            }
        }

        return false;
    }

    /**
     * Checks whether a record belongs to a list of allowed record types
     * @param recordTypes List of allowed record types
     * @param record The record to check
     * @return  False if the record is not included in one of the allowed types
     */
    private Boolean checkRecordIsOfRecordType(Set<Id> recordTypes, SObject record) {
        if (!recordTypes.isEmpty()) {
            if (!recordTypes.contains((Id) record.get('RecordTypeId'))) {
                return false;
            }
        }

        return true;
    }

    /**
     * Converts the record type names from metadata to record type ids, returns an
     * empty list if the record type names are not set (this means it allows all)
     * @param rtString Comma separated list of record type names
     * @return  A set of record type ids
     */
    private Set<Id> getRecordTypeIds(String rtString) {
        if (String.isBlank(rtString)) {
            return new Set<Id>();
        }

        Set<Id> recordTypeIds = new Set<Id>();
        for (String rtName : rtString.split(',')) {
            recordTypeIds.add(sObjectType.getDescribe().getRecordTypeInfosByName().get(rtName).getRecordTypeId());
        }

        return recordTypeIds;
    }

    /**
     * Returns a set of operation types
     * @param input The raw input from the Operation_Lock__c field
     * @return  A set of operations
     */
    private Set<String> getOperationTypes(String input) {
        Set<String> operations = new Set<String>();
        operations.addAll(input.split(','));
        return operations;
    }

    /**
     * Attempts to fetch the serializer by cache or creates a new instance
     * @param name The name of the Serializer class
     * @return  Instance of the Serializer
     */
    @TestVisible
    private Serializer getSerializer(String name) {
        if (serializerCache.containsKey(name)) {
            return serializerCache.get(name);
        }

        Serializer serializer = (Serializer) Type.forName(name).newInstance();
        serializerCache.put(name, serializer);
        return serializer;
    }

    /**
     * Attempts to fetch the emitter by cache or creates a new instance
     * @param name The name of the Emitter class
     * @return  Instance of the Emitter
     */
    @TestVisible
    private Emitter getEmitter(String name) {
        if (emitterCache.containsKey(name)) {
            return emitterCache.get(name);
        }

        Emitter emitter = (Emitter) Type.forName(name).newInstance();
        emitterCache.put(name, emitter);
        return emitter;
    }

    /**
     * Queries metadata for configuration specific to the sObject type
     * @param sObjectType The sObject type to query on
     */
    @TestVisible
    private void fetchConfig(String sObjectType) {
        streams = [
            SELECT Event_Name__c, Operation_Lock__c, Fields__c, Serializer__c, Record_Types__c, Emitter__c
            FROM Object_Stream_Setting__mdt
            WHERE SObject_Type__c = :sObjectType AND Disabled__c = FALSE
            ORDER BY Sort_Order__c
        ];
    }
}
