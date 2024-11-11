@isTest
public class DuplicateHandlerTest {
    @testSetup
    static void makeData() {
        Account businessAccount = new Account(
            Name = 'Test BDAccount',
            Phone = '1234567890',
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
                .get('Business_Development_Account')
                .getRecordTypeId()
        );
        insert businessAccount;

        Contact businessContact = new Contact(
            AccountId = businessAccount.Id,
            FirstName = 'Test',
            LastName = 'BDContact',
            Work_Email__c = 'testbdcontact1@mail.invalid',
            RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName()
                .get('BD_Contact')
                .getRecordTypeId()
        );
        insert businessContact;

        Lead businessLead = new Lead(
            FirstName = 'Test',
            LastName = 'BDLead',
            Company = 'TestBD',
            Preferred_Email__c = 'Work',
            Work_Email__c = 'testbdlead1@mail.invalid',
            RecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName()
                .get('Business_Development')
                .getRecordTypeId()
        );
        insert businessLead;

        Lead studentLead = new Lead(
            FirstName = 'Test',
            LastName = 'StudentLead',
            Preferred_Email__c = 'Work',
            Work_Email__c = 'testbdlead1@mail.invalid',
            Preferred_Phone__c = 'Work',
            Work_Phone__c = '+447798536743',
            RecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName()
                .get('Prospective_Student')
                .getRecordTypeId()
        );
        insert studentLead;

        Account studentAccount = new Account(
            FirstName = 'Test',
            LastName = 'Student',
            Preferred_Email__pc = 'Work',
            Work_Email__pc = 'teststudent1@mail.invalid',
            Preferred_Phone__pc = 'Mobile',
            PersonMobilePhone = '+447716123748',
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
                .get('Student_Account')
                .getRecordTypeId()
        );
        insert studentAccount;
    }

    @isTest
    private static void itShouldFindDuplicateLeadAndReturnMatchedId() {
        List<Lead> leadList = new List<Lead>();
        leadList.add(
            new Lead(
                FirstName = 'Test',
                LastName = 'BDLead',
                Company = 'TestBD',
                Preferred_Email__c = 'Work',
                Work_Email__c = 'TestBD',
                RecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName()
                    .get('Business_Development')
                    .getRecordTypeId()
            )
        );
        List<DuplicateHandler.MatchingRecord> matchingRecords = DuplicateFinder.findDuplicateRecords(leadList);
        System.assert(matchingRecords.size() > 0, 'List should contain matching Lead record.');
        System.assertEquals(
            'Lead',
            matchingRecords.get(0).sObjectType,
            'Matched record sObjectType should equal "Lead".'
        );

        Lead existingLead = [SELECT Id FROM Lead LIMIT 1];
        System.assertEquals(
            existingLead.Id,
            matchingRecords.get(0).matchingId,
            'Matched record Id should match previously inserted Lead.'
        );
    }

    @isTest
    private static void itShouldFindDuplicateStudentsAndReturnMatchedId() {
        Account existingAccount = [
            SELECT
                Id,
                FirstName,
                LastName,
                PersonMobilePhone,
                Preferred_Email__pc,
                Preferred_Phone__pc,
                Work_Email__pc,
                RecordTypeId
            FROM Account
            WHERE IsPersonAccount = TRUE
            LIMIT 1
        ];

        Account newAccount = new Account();
        newAccount.FirstName = existingAccount.FirstName;
        newAccount.LastName = existingAccount.LastName;
        newAccount.Preferred_Email__pc = existingAccount.Preferred_Email__pc;
        newAccount.Work_Email__pc = existingAccount.Work_Email__pc;
        newAccount.Preferred_Phone__pc = existingAccount.Preferred_Phone__pc;
        newAccount.PersonMobilePhone = existingAccount.PersonMobilePhone;
        newAccount.RecordTypeId = existingAccount.RecordTypeId;

        Database.DMLOptions dbDML = new Database.DMLOptions();
        dbDML.DuplicateRuleHeader.allowSave = true;
        Database.insert(newAccount, dbDML);

        Account dupeAccount = new Account();
        dupeAccount.FirstName = existingAccount.FirstName;
        dupeAccount.LastName = existingAccount.LastName;
        dupeAccount.Preferred_Email__pc = existingAccount.Preferred_Email__pc;
        dupeAccount.Work_Email__pc = existingAccount.Work_Email__pc;
        dupeAccount.Preferred_Phone__pc = existingAccount.Preferred_Phone__pc;
        dupeAccount.PersonMobilePhone = existingAccount.PersonMobilePhone;
        dupeAccount.RecordTypeId = existingAccount.RecordTypeId;
        List<Account> accountList = new List<Account>();
        accountList.add(dupeAccount);

        List<DuplicateHandler.MatchingRecord> matchingRecords = DuplicateFinder.findDuplicateRecords(accountList);
        System.assert(matchingRecords.size() > 0, 'List should contain matching Student records.');

        Id winningId = DuplicateHandler.handleMatchingRecords(matchingRecords);

        Account lastModifiedAccount = [
            SELECT Id
            FROM Account
            WHERE IsPersonAccount = TRUE
            ORDER BY LastModifiedDate DESC
            LIMIT 1
        ];
        System.assertEquals(
            lastModifiedAccount.Id,
            winningId,
            'Id should have returned existing Student with most recent LastModifiedDate.'
        );
    }

    @isTest
    private static void itShouldFindDuplicateStudentAndReturnMatchedId() {
        List<Account> accountList = new List<Account>();
        accountList.add(
            new Account(
                FirstName = 'Test',
                LastName = 'Student',
                Preferred_Email__pc = 'Work',
                Work_Email__pc = 'teststudent1@mail.invalid',
                Preferred_Phone__pc = 'Mobile',
                PersonMobilePhone = '+447716123748',
                RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
                    .get('Student_Account')
                    .getRecordTypeId()
            )
        );
        List<DuplicateHandler.MatchingRecord> matchingRecords = DuplicateFinder.findDuplicateRecords(accountList);
        System.assert(matchingRecords.size() > 0, 'List should contain matching Student record.');
        System.assertEquals(
            'Student',
            matchingRecords.get(0).sObjectType,
            'Matched record sObjectType should equal "Student".'
        );

        Account existingAccount = [SELECT Id FROM Account WHERE IsPersonAccount = TRUE LIMIT 1];
        System.assertEquals(
            existingAccount.Id,
            matchingRecords.get(0).matchingId,
            'Matched record Id should match previously inserted Account.'
        );
    }

    @isTest
    private static void itShouldHandleUpgradeCategoryAndReturnMatchedId() {
        Lead existingLead = [
            SELECT
                Id,
                FirstName,
                LastName,
                Preferred_Email__c,
                Work_Email__c,
                Preferred_Phone__c,
                Work_Phone__c,
                RecordTypeId
            FROM Lead
            WHERE LastName = 'StudentLead'
            LIMIT 1
        ];

        Lead newLead = new Lead();
        newLead.FirstName = existingLead.FirstName;
        newLead.LastName = existingLead.LastName;
        newLead.Preferred_Email__c = existingLead.Preferred_Email__c;
        newLead.Work_Email__c = existingLead.Work_Email__c;
        newLead.Preferred_Phone__c = existingLead.Preferred_Phone__c;
        newLead.Work_Phone__c = existingLead.Work_Phone__c;
        newLead.RecordTypeId = existingLead.RecordTypeId;

        Database.DMLOptions dbDML = new Database.DMLOptions();
        dbDML.DuplicateRuleHeader.allowSave = true;
        Database.insert(newLead, dbDML);

        Lead dupeLead = new Lead();
        dupeLead.FirstName = existingLead.FirstName;
        dupeLead.LastName = existingLead.LastName;
        dupeLead.Preferred_Email__c = existingLead.Preferred_Email__c;
        dupeLead.Work_Email__c = existingLead.Work_Email__c;
        dupeLead.Preferred_Phone__c = existingLead.Preferred_Phone__c;
        dupeLead.Work_Phone__c = existingLead.Work_Phone__c;
        List<Lead> leadList = new List<Lead>();
        leadList.add(dupeLead);

        List<DuplicateHandler.MatchingRecord> matchingRecords = DuplicateFinder.findDuplicateRecords(leadList);
        for (DuplicateHandler.MatchingRecord mr : matchingRecords) {
            mr.category = 'Silver';
        }
        System.assert(matchingRecords.size() > 0, 'List should contain matching Lead records.');

        Id winningId = DuplicateHandler.handleMatchingRecords(matchingRecords);

        Lead lastModifiedLead = [SELECT Id FROM Lead ORDER BY LastModifiedDate DESC LIMIT 1];
        System.assertEquals(
            lastModifiedLead.Id,
            winningId,
            'Id should have returned existing Lead with most recent LastModifiedDate.'
        );
    }
}
