@isTest
public with sharing class Test_BypassDuplicateCheck {
    public static Integer i = 2;
    public static Id newRecordType = Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName()
        .get('Prospective_Student')
        .getRecordTypeId();
    public static Id startingRecordType = Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName()
        .get('Business_Development')
        .getRecordTypeId();
    public static String uniqueString = TestDataFactory.generateUniqueString();
    public static Map<String, Object> additionalFields = new Map<String, Object>{
        'FirstName' => 'Test Lead ' + uniqueString,
        'LastName' => 'Test Lead ' + uniqueString,
        'RecordTypeId' => startingRecordType,
        'Personal_Email__c' => 'test@test.test',
        'Preferred_Email__c' => 'Personal',
        'MobilePhone' => '+447234567890',
        'Preferred_Phone__c' => 'Mobile',
        'Company' => 'Test Company'
    };

    @isTest
    public static void duplicateRecordsCanBeInserted() {
        //GIVEN a number of Leads have the same details
        List<Lead> leadList = TestDataFactory.createLeads(2, false, additionalFields);
        List<BypassDuplicateCheck.Inputs> inputList = new List<BypassDuplicateCheck.Inputs>();
        for (Lead leadRecord : leadList) {
            BypassDuplicateCheck.Inputs input = new BypassDuplicateCheck.Inputs();
            input.recordToSave = leadRecord;
            input.insertOrUpdate = 'insert';
            inputList.add(input);
        }

        //WHEN the duplicates are passed to the BypassDuplicateCheck class
        Test.startTest();
        List<BypassDuplicateCheck.OutPuts> output = BypassDuplicateCheck.execute(inputList);

        //THEN both records are inserted regardless of any duplicate rules
        Test.stopTest();
        Assert.isTrue([SELECT Id FROM Lead].size() == i, 'Incorrect number of Leads inserted');
    }

    @isTest
    public static void duplicateRecordCanBeUpdated() {
        //GIVEN a number of Leads have the same details
        List<Lead> leadList = TestDataFactory.createLeads(2, false, additionalFields);
        List<BypassDuplicateCheck.Inputs> inputList = new List<BypassDuplicateCheck.Inputs>();
        for (Lead leadRecord : leadList) {
            BypassDuplicateCheck.Inputs input = new BypassDuplicateCheck.Inputs();
            input.recordToSave = leadRecord;
            input.insertOrUpdate = 'insert';
            inputList.add(input);
        }
        List<BypassDuplicateCheck.OutPuts> insertOutput = BypassDuplicateCheck.execute(inputList);

        List<BypassDuplicateCheck.Inputs> updateList = new List<BypassDuplicateCheck.Inputs>();
        BypassDuplicateCheck.Inputs updateRecord = new BypassDuplicateCheck.Inputs();
        Lead leadRecord = (Lead) inputList[0].recordToSave;
        leadRecord.RecordTypeId = newRecordType;
        leadRecord.Company = null;
        updateRecord.recordToSave = leadRecord;
        updateRecord.insertOrUpdate = 'update';
        updateList.add(updateRecord);

        //WHEN an existing duplicate is passed to the BypassDuplicateCheck class to be updated
        Test.startTest();
        List<BypassDuplicateCheck.OutPuts> updateOutput = BypassDuplicateCheck.execute(updateList);

        //THEN the duplicate record is updated regardless of any duplicate rules
        Test.stopTest();

        System.debug([SELECT Id, Name, RecordTypeId FROM Lead WHERE RecordTypeId = :newRecordType].size());
        Assert.isTrue(
            [SELECT Id FROM Lead WHERE RecordTypeId = :newRecordType].size() > 0,
            'Lead record type not updated'
        );
    }
}
