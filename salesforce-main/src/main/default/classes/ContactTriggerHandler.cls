public class ContactTriggerHandler extends TriggerHandler {
    private static Set<Id> userExclusionSet = UserHelper.createUserExclusionSet();
    private static String trainingManagerRT = Schema.Sobjecttype.Contact.getRecordTypeInfosByDeveloperName()
        .get('Training_Manager')
        .getRecordTypeId();
    private static Map<Id, Contact> oldContactMap = (Map<Id, Contact>) Trigger.oldMap;

    public ContactTriggerHandler() {
        oldContactMap = (Map<Id, Contact>) Trigger.oldMap;
    }

    public override void beforeInsert() {
        if (!TriggerSettings__c.getInstance().ContactTrigger_primaryBillingBypass__c) {
            ContactTriggerHandler.primaryBillingContactCheck();
        }
    }

    public override void beforeUpdate() {
        if (!TriggerSettings__c.getInstance().ContactTrigger_primaryBillingBypass__c) {
            ContactTriggerHandler.primaryBillingContactCheck();
        }
        if (!TriggerSettings__c.getInstance().ContactTrigger_activeTrainingManager__c) {
            ContactTriggerHandler.activeTrainingManagerCheck();
        }
    }

    public override void afterUpdate() {
        ContactTriggerHandler.updateProfileAssociation();
    }

    public static void primaryBillingContactCheck() {
        Set<Id> accountIds = new Set<Id>();
        for (Contact contact : (List<Contact>) Trigger.new) {
            if (contact.AccountId != null) {
                accountIds.add(contact.AccountId);
            }
        }

        Map<Id, List<Contact>> accountContactMap = new Map<Id, List<Contact>>();
        for (Account account : [
            SELECT Id, (SELECT Id FROM Contacts WHERE Primary_Billing_Contact__c = TRUE)
            FROM Account
            WHERE Id IN :accountIds
        ]) {
            accountContactMap.put(account.Id, account.Contacts);
        }

        for (Contact contact : (List<Contact>) Trigger.new) {
            List<Contact> accountsContactList = (contact.AccountId == null ||
                accountContactMap.get(contact.AccountId).isEmpty()
                ? null
                : accountContactMap.get(contact.AccountId));
            if (accountsContactList != null && accountsContactList.size() > 1) {
                contact.addError(
                    'You can only have one Primary Billing Contact per Account.\n Please review existing contacts and the Bill to Contact field on Account first.'
                );
            }
        }
    }

    public static void activeTrainingManagerCheck() {
        System.debug('activeTrainingManagerCheck');

        List<Sponsorship__c> sponsorshipList = [
            SELECT Id, Training_Manager__c
            FROM Sponsorship__c
            WHERE Training_Manager__c IN :Trigger.newMap.keySet() AND Active__c = TRUE
        ];

        Set<Id> managersWithSponsorships = new Set<Id>();

        for (Sponsorship__c sponsorship : sponsorshipList) {
            managersWithSponsorships.add(sponsorship.Training_Manager__c);
        }

        for (Contact contact : (List<Contact>) Trigger.new) {
            if (
                !contact.Active__c &&
                contact.PS_Profile_Services_ID__c != null &&
                contact.RecordTypeId == trainingManagerRT &&
                oldContactMap.get(contact.id).Active__c &&
                managersWithSponsorships.contains(contact.Id)
            ) {
                Trigger.newMap
                    .get(contact.Id)
                    .addError('There are Active sponsorship records for this Training manager');
            }
        }
    }

    public static void updateProfileAssociation() {
        System.debug('removeProfileAssociation');
        Map<String, String> profileServiceIdToContactIdMap = new Map<String, String>();

        for (Contact contact : (List<Contact>) Trigger.new) {
            ContactTriggerHandler.srcTargetProfileCheck(contact);
            if (
                contact.PS_Profile_Services_ID__c != null &&
                contact.PS_Profile_Services_ID__c != oldContactMap.get(contact.Id).PS_Profile_Services_ID__c &&
                (!userExclusionSet.contains(UserInfo.getUserId()) || Test.isRunningTest())
            ) {
                profileServiceIdToContactIdMap.put(contact.PS_Profile_Services_ID__c, contact.Id);
            }
            if (
                contact.PS_Profile_Services_ID__c != null &&
                contact.RecordTypeId == trainingManagerRT &&
                (!userExclusionSet.contains(UserInfo.getUserId()) || Test.isRunningTest())
            ) {
                KPMGTrainingMgrIntegrations.UpdateTrainingManagerInfo(contact.PS_Profile_Services_ID__c, contact.Id);
            }
        }
        if (profileServiceIdToContactIdMap.size() > 0) {
            PersonIdentitiesIntegrations.PersonIdentityUpdate(profileServiceIdToContactIdMap);
        }
    }

    public static void srcTargetProfileCheck(Contact contact) {
        if (
            contact.PS_Profile_Services_ID__c != null &&
            contact.RecordTypeId == trainingManagerRT &&
            (oldContactMap.get(contact.id).PS_Profile_Services_ID__c != contact.PS_Profile_Services_ID__c ||
            oldContactMap.get(contact.id).Active__c != contact.Active__c) &&
            (!userExclusionSet.contains(UserInfo.getUserId()) || Test.isRunningTest())
        ) {
            if (!contact.Active__c && oldContactMap.get(contact.id).Active__c) {
                ProfileAssociation.srcTargetdeleteProfileAssociation(
                    contact.Account.Profile_Company_ID__c,
                    contact.PS_Profile_Services_ID__c,
                    'CompanyTrainingManager',
                    contact.id
                );
            }
            if (contact.AccountId != null) {
                ProfileAssociation.srcTargetProfileAssociation(
                    contact.Account.Profile_Company_ID__c,
                    contact.PS_Profile_Services_ID__c,
                    'CompanyTrainingManager',
                    contact.id
                );
            }
        }
    }
}
