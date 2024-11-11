/**
 * ApplicationAudit class fetches audit records and field history records
 * to produce a consolidated list of changes
 */
public without sharing class ApplicationAudit {
    /**
     * A map of history data sorted by time
     */
    private Map<DateTime, Map<String, Object>> sortData;

    /**
     * The opportunity id related to the request
     */
    private Id opportunityId;

    /**
     * List of related ksb ids
     */
    private Set<Id> ksbIds;

    /**
     * List of related document ids
     */
    private Set<Id> documentIds;

    /**
     * List of related Application History Ids
     */
    private Set<Id> appHistoryIds;

    /**
     * List of related application review ids
     */
    private Set<Id> reviewIds;

    /**
     * List of related qualification ids
     */
    private Set<Id> qualificationIds;

    /**
     * A map that provides a reference name
     */
    private Map<Id, String> identifierFields;

    /**
     * Default construct
     */
    public ApplicationAudit() {
        sortData = new Map<DateTime, Map<String, Object>>();
    }

    /**
     * Creates Application audits from the given opportunities
     * @param applicationIds A set of application ids to create the audits against
     * @param start Start datetime of the event - must be before the DML actions
     */
    public static void createAudits(Set<String> applicationIds, DateTime start) {
        List<Application_Audit__c> audits = new List<Application_Audit__c>();

        for (Opportunity opp : [SELECT Id, StageName FROM Opportunity WHERE Application_Id__c IN :applicationIds]) {
            String role = 'Student';

            if (opp.StageName == 'Line Manager Review') {
                role = 'Line Manager';
            }

            audits.add(new Application_Audit__c(Updated_By__c = role, Opportunity__c = opp.Id, Event_Date__c = start));
        }

        insert audits;
    }

    /**
     * Fetches field tracking and audit history for the given opportunity
     * @param opportunityId The opportunity id relating to the audit
     * @return  A list of combined history
     */
    public List<Object> fetchAudit(Id opportunityId) {
        List<Map<String, Object>> data = new List<Map<String, Object>>();
        this.opportunityId = opportunityId;

        fetchData();
        fetchFromAudit();

        // fetch history
        fetchFromHistoryTracking(
            'Opportunity',
            'OpportunityFieldHistory',
            'OpportunityId',
            new Set<Id>{ opportunityId },
            new Set<String>{
                'StageName',
                'BPP_Sub_Status__c',
                'OwnerId',
                'Programme_Application__c',
                'Start_Date__c',
                'Sponsoring_Organization__c'
            },
            false
        );
        fetchFromHistoryTracking('Opportunity', 'Application_History__history', 'ParentId', appHistoryIds, null, true);
        fetchFromHistoryTracking(
            'KSB',
            'KSB__history',
            'ParentId',
            ksbIds,
            new Set<String>{ 'Answer__c', 'Experience_Information__c' },
            true
        );
        fetchFromHistoryTracking(
            'External Document',
            'External_Document__history',
            'ParentId',
            documentIds,
            null,
            false
        );

        List<DateTime> sortedKeys = new List<DateTime>(sortData.keySet());
        sortedKeys.sort();
        for (Integer i = sortedKeys.size() - 1; i >= 0; i--) {
            data.add(sortData.get(sortedKeys[i]));
        }

        return data;
    }

    /**
     * Fetches the related audit records
     */
    private void fetchFromAudit() {
        List<Application_Audit__c> audits = [
            SELECT Opportunity__c, Updated_By__c, Event_Date__c
            FROM Application_Audit__c
            WHERE Opportunity__c = :opportunityId
            ORDER BY CreatedDate DESC
        ];

        for (Application_Audit__c audit : audits) {
            sortData.put(
                audit.Event_Date__c,
                new Map<String, Object>{
                    'field' => audit.Updated_By__c + ' submitted changes',
                    'object' => 'Application',
                    'updated' => audit.Event_Date__c,
                    'updatedBy' => audit.Updated_By__c
                }
            );
        }
    }

    /**
     * Fetches the history tracking for the given SObject
     * @param objectName The output name of the SObject
     * @param trackingObject The history tracking SObject
     * @param parentField The name of the parentId field ie OpportunityId
     * @param parentIds A set of ids to query against
     */
    private void fetchFromHistoryTracking(
        String objectName,
        String trackingObject,
        String parentField,
        Set<Id> parentIds,
        Set<String> fields,
        Boolean suppressCreation
    ) {
        String query = String.format(
            'SELECT Field, NewValue, OldValue, CreatedDate, CreatedBy.Name, {0} FROM {1} WHERE {0} IN :parentIds',
            new List<String>{ parentField, trackingObject }
        );

        if (fields != null) {
            query += ' AND Field IN :fields';
        }

        if (suppressCreation) {
            query += ' AND Field != \'created\'';
        }

        query += ' ORDER BY CreatedDate DESC';

        for (SObject history : Database.query(query)) {
            Map<String, Object> historyObj = new Map<String, Object>{
                'field' => history.get('Field'),
                'object' => objectName,
                'newValue' => history.get('NewValue'),
                'oldValue' => history.get('OldValue'),
                'updated' => history.get('CreatedDate'),
                'updatedBy' => history.getSobject('CreatedBy').get('Name')
            };

            if (identifierFields.containsKey((Id) history.get(parentField))) {
                historyObj.put('identifier', identifierFields.get((Id) history.get(parentField)));
            }

            if (sortData.containsKey((DateTime) history.get('CreatedDate'))) {
                Map<String, Object> parent = sortData.get((DateTime) history.get('CreatedDate'));

                if (parent.containsKey('_children')) {
                    List<Object> children = (List<Object>) parent.get('_children');

                    children.add(historyObj);
                } else {
                    Map<String, Object> parentClone = parent.clone();
                    List<Object> children = new List<Object>();
                    children.add(parentClone);
                    children.add(historyObj);

                    parent.put('field', '');
                    parent.put('newValue', '');
                    parent.put('oldValue', '');
                    parent.put('identifier', '');
                    parent.put('_children', children);
                }
            } else {
                sortData.put((DateTime) history.get('CreatedDate'), historyObj);
            }
        }
    }

    /**
     * Fetches the data needed to get field history from all relevent records
     */
    private void fetchData() {
        ksbIds = new Set<Id>();
        documentIds = new Set<Id>();
        appHistoryIds = new Set<Id>();
        reviewIds = new Set<Id>();
        qualificationIds = new Set<Id>();
        identifierFields = new Map<Id, String>();

        Opportunity opp = [
            SELECT (SELECT Id, Question__c FROM KSBs__r), (SELECT Id, Name FROM External_Documents__r)
            FROM Opportunity
            WHERE Id = :opportunityId
        ];

        for (KSB__c ksb : opp.KSBs__r) {
            ksbIds.add(ksb.Id);
            identifierFields.put(ksb.Id, ksb.Question__c);
        }

        for (External_Document__c doc : opp.External_Documents__r) {
            documentIds.add(doc.Id);
            identifierFields.put(doc.Id, doc.Name);
        }

        appHistoryIds = new Map<Id, Application_History__c>(
                [SELECT id FROM Application_History__c WHERE Opportunity__c = :opportunityId]
            )
            .keySet();
    }
}
