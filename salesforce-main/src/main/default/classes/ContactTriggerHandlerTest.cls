@isTest
public class ContactTriggerHandlerTest {
    @testSetup
    static void makeData() {
        Map<String, Object> accountFieldMap = new Map<String, Object>{ 'Profile_Company_ID__c' => '123456789' };

        List<Account> accountList = TestDataFactory.createAccounts(
            1,
            'Business_Development_Account',
            false,
            accountFieldMap
        );
        Database.insert(accountList);

        Map<String, Object> contactFieldMap = new Map<String, Object>{ 'AccountId' => accountList[0].Id };
        List<Contact> contactList = TestDataFactory.createContacts(2, 'Billing_Contact', false, contactFieldMap);
        contactList[0].Primary_Billing_Contact__c = true;
        Database.insert(contactList);

        Map<String, Object> trainingManagerFieldMap = new Map<String, Object>{
            'Active__c' => true,
            'PS_Profile_Services_ID__c' => '123456789',
            'Preferred_Email__c' => 'Personal',
            'Personal_Email__c' => 'test-Training_Manager@mail.com',
            'AccountId' => accountList[0].Id
        };
        List<Contact> trainingManagerContactList = TestDataFactory.createContacts(
            1,
            'Training_Manager',
            true,
            trainingManagerFieldMap
        );

        Account studentAccount = TestDataFactory.createAccount(false, true, null, 0);
        studentAccount.PS_Profile_Services_ID__pc = '1234xxx5-xxx1-1x2x-xxx1-12345x678x9';
        Database.insert(studentAccount);

        Map<String, Object> sponsorshipFieldMap = new Map<String, Object>{
            'Student__c' => studentAccount.Id,
            'Training_Manager__c' => trainingManagerContactList[0].Id
        };
        List<Sponsorship__c> sponsorshipList = TestDataFactory.createSponsorships(1, true, sponsorshipFieldMap);
    }

    @isTest
    static void test_unableToSaveMultiplePrimaryBillingContacts_beforeInsert() {
        Account account = [SELECT Id FROM Account LIMIT 1];
        Map<String, Object> contactFieldMap = new Map<String, Object>{
            'AccountId' => account.Id,
            'Primary_Billing_Contact__c' => true
        };
        List<Contact> contactsToTest = TestDataFactory.createContacts(1, 'Billing_Contact', false, contactFieldMap);
        try {
            Database.DMLOptions dml = new Database.DMLOptions();
            dml.DuplicateRuleHeader.allowSave = true;
            dml.DuplicateRuleHeader.runAsCurrentUser = true;
            Database.insert(contactsToTest, dml);
        } catch (Exception e) {
            System.debug('test_unableToSaveMultiplePrimaryBillingContacts_beforeInsert error = ' + e.getMessage());
            System.assertEquals(e.getMessage().contains('FIELD_CUSTOM_VALIDATION_EXCEPTION'), true);
        }
    }

    @isTest
    static void test_unableToSaveMultiplePrimaryBillingContacts_beforeUpdate() {
        Contact contact = [
            SELECT Id
            FROM Contact
            WHERE Primary_Billing_Contact__c = FALSE AND RecordType.DeveloperName = 'Billing_Contact'
            LIMIT 1
        ];
        contact.Primary_Billing_Contact__c = true;
        try {
            update contact;
        } catch (Exception e) {
            System.debug('test_unableToSaveMultiplePrimaryBillingContacts_beforeUpdate error = ' + e.getMessage());
            System.assertEquals(e.getMessage().contains('FIELD_CUSTOM_VALIDATION_EXCEPTION'), true);
        }
    }

    @isTest
    static void test_unableToDeactivateTrainingManagersWithSponsorships_beforeUpdate() {
        Contact contact = [
            SELECT Id
            FROM Contact
            WHERE RecordType.DeveloperName = 'Training_Manager'
            LIMIT 1
        ];
        contact.Active__c = false;
        try {
            update contact;
        } catch (Exception e) {
            System.debug(
                'test_unableToDeactivateTrainingManagersWithSponsorships_beforeUpdate error = ' + e.getMessage()
            );
            System.assertEquals(e.getMessage().contains('FIELD_CUSTOM_VALIDATION_EXCEPTION'), true);
        }
    }
}
