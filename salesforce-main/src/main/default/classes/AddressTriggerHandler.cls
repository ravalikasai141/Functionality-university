/**
 *  Custom trigger handler for Address object
 */
public class AddressTriggerHandler extends TriggerHandler {
    private static Set<Id> userExclusionSet = UserHelper.createUserExclusionSet();
    private static StreamingService stream = new StreamingService();

    private List<Address__c> newAddresses;
    private List<Address__c> oldAddresses;

    private Map<Id, Address__c> newAddressesMap;
    private Map<Id, Address__c> oldAddressesMap;

    public static Id applicationRecordType = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName()
        .get('Student_Application')
        .getRecordTypeId();
    public static Id lockedApplicationRecordType = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName()
        .get('Locked_Application')
        .getRecordTypeId();

    /**
     *  Constructor
     */
    public AddressTriggerHandler() {
        TriggerHandler.processOnce('AddressTriggerHandler');

        newAddresses = Trigger.new;
        oldAddresses = Trigger.old;

        newAddressesMap = (Map<ID, Address__c>) Trigger.NewMap;
        oldAddressesMap = (Map<ID, Address__c>) Trigger.OldMap;
    }

    /**
     *  {@inheritDocs}
     */
    public override void beforeInsert() {
        checkForDuplicates(newAddresses, null, 'insert');
        clearInactiveAddresses(newAddresses, null);
        populateDetailsConfirmation(newAddresses, null);
    }

    /**
     *  {@inheritDocs}
     */
    public override void beforeUpdate() {
        checkForDuplicates(newAddresses, oldAddressesMap, 'update');
        clearInactiveAddresses(newAddresses, oldAddressesMap);
        populateDetailsConfirmation(newAddresses, oldAddressesMap);
    }

    /**
     *  {@inheritDocs}
     */
    public override void beforeDelete() {
    }

    /**
     *  {@inheritDocs}
     */
    public override void afterInsert() {
        flattenAddressTypes(newAddresses);
        stream.process(newAddresses, new Map<Id, SObject>());
        updateProfileIntegrationOnAddress(newAddresses, oldAddresses, false);
    }

    /**
     *  {@inheritDocs}
     */
    public override void afterUpdate() {
        flattenAddressTypes(newAddresses);
        stream.process(newAddresses, oldAddressesMap);
        updateProfileIntegrationOnAddress(newAddresses, oldAddresses, false);
    }

    /**
     *  {@inheritDocs}
     */
    public override void afterDelete() {
        stream.process(oldAddresses, new Map<Id, SObject>{});
        updateProfileIntegrationOnAddress(newAddresses, oldAddresses, true);
    }

    /**
     *  {@inheritDocs}
     */
    public override void afterUndelete() {
    }

    public static void checkForDuplicates(List<Address__c> newAddressList, Map<Id, Address__c> oldMap, String context) {
        System.debug('@AddressTriggerhandler checkForDuplicates entered');
        Set<Id> relatedAddressIds = new Set<Id>();
        Set<String> addressTypes = new Set<String>();
        for (Address__c address : newAddressList) {
            if (address.Student__c != null) {
                relatedAddressIds.add(address.Student__c);
            }
            if (address.Lead__c != null) {
                relatedAddressIds.add(address.Lead__c);
            }
            if (address.Training_Manager__c != null) {
                relatedAddressIds.add(address.Training_Manager__c);
            }
            addressTypes.add(address.Type__c);
        }
        
        List<Address__c> addressesList = [SELECT Name, Id, Type__c, Student__c, Lead__c, Training_Manager__c, Primary__c, Active__c FROM Address__c WHERE ((Student__c IN: relatedAddressIds) OR (Lead__c IN: relatedAddressIds) OR (Training_Manager__c IN: relatedAddressIds))];
        if (addressesList.size() > 0) {
            checkForDuplicateAddressTypes(newAddressList, addressesList, addressTypes, oldMap, context);
            checkForDuplicatePrimaryBillingDelivery(newAddressList);
            checkForDuplicatePermanentHomeAddress(newAddressList);
        }
    }

    private static void checkForDuplicateAddressTypes(List<Address__c> newAddressList, List<Address__c> existingAddressList, Set<String> addressTypes, Map<Id, Address__c> oldMap, String context) {
        System.debug('@AddressTriggerhandler checkForDuplicateAddressTypes entered');
        String errorMessage = 'There can be only one Address Type associated to a record.';
        Map<Id, Set<String>> addressTypeMap = new Map<Id, Set<String>>();
        for (Address__c address : existingAddressList) {
            if (addressTypes.contains(address.Type__c) && address.Active__c) {
                if (address.Student__c != null) {
                    if (!addressTypeMap.containsKey(address.Student__c)) {
                        addressTypeMap.put(address.Student__c, new Set<String>());
                    }
                    addressTypeMap.get(address.Student__c).add(address.Type__c);
                }
                if (address.Lead__c != null) {
                    if (!addressTypeMap.containsKey(address.Lead__c)) {
                        addressTypeMap.put(address.Lead__c, new Set<String>());
                    }
                    addressTypeMap.get(address.Lead__c).add(address.Type__c);
                }
                if (address.Training_Manager__c != null) {
                    if (!addressTypeMap.containsKey(address.Training_Manager__c)) {
                        addressTypeMap.put(address.Training_Manager__c, new Set<String>());
                    }
                    addressTypeMap.get(address.Training_Manager__c).add(address.Type__c);
                }
            }
        }
        
        for (Address__c address : newAddressList) {
            Boolean addressValidation = (((addressTypeMap.containsKey(address.Student__c) && addressTypeMap.get(address.Student__c).contains(address.Type__c)) || 
            (addressTypeMap.containsKey(address.Lead__c) && addressTypeMap.get(address.Lead__c).contains(address.Type__c)) || 
            (addressTypeMap.containsKey(address.Training_Manager__c) && addressTypeMap.get(address.Training_Manager__c).contains(address.Type__c))));
            if (context == 'insert' && addressValidation) {
                address.addError(errorMessage);
            } else if (context == 'update' && addressValidation && address.Type__c != oldMap.get(address.Id).Type__c) {
                address.addError(errorMessage);
            }
        }
    }

    private static void checkForDuplicatePrimaryBillingDelivery(List<Address__c> newAddressList) {
        System.debug('@AddressTriggerhandler checkForDuplicatePrimaryBillingDelivery entered');
        Set<Id> accountIds = new Set<Id>();
        for (Address__c address : newAddressList) {
            accountIds.add(address.Student__c);
        }
    
        Map<Id, List<Address__c>> accountAddressMap = new Map<Id, List<Address__c>>();
        for (Account acc: [SELECT Id, (SELECT Id, Name, Primary__c, Primary_Billing__c, Primary_Delivery__c, LastModifiedDate, Student__r.Phone FROM Addresses__r WHERE Active__c = true) FROM Account WHERE Id IN: accountIds]) {
            accountAddressMap.put(acc.Id, acc.Addresses__r);
        }
    
        for (Address__c address : newAddressList) {
            Boolean throwError = false;
            if ((address.Student__c == null) || (address.Student__c != null && accountAddressMap.get(address.Student__c).size() == 0)) {
                continue;
            } else {
                for (Address__c existingAddress : accountAddressMap.get(address.Student__c)) {
                    if (address.Id != existingAddress.Id) {
                        if ((address.Primary_Billing__c && address.Primary_Delivery__c) && (existingAddress.Primary_Billing__c && existingAddress.Primary_Delivery__c) ||
                        (address.Primary_Billing__c && existingAddress.Primary_Billing__c) || (address.Primary_Delivery__c && existingAddress.Primary_Delivery__c)) {
                            throwError = true;
                        }
                    }
                }
            }
            if (throwError) {
                address.addError('An Account can only have one Address marked as \'Primary Billing?\' or \'Primary Delivery?\' associated to it.');
            }
        }
    }

    private static void checkForDuplicatePermanentHomeAddress(List<Address__c> newAddressList) {
        System.debug('@AddressTriggerhandler checkForDuplicatePermanentHomeAddress entered');
        Set<Id> accountIds = new Set<Id>();
        for (Address__c address : newAddressList) {
            accountIds.add(address.Student__c);
        }
    
        Map<Id, List<Address__c>> accountAddressMap = new Map<Id, List<Address__c>>();
        for (Account acc: [SELECT Id, (SELECT Id, Name, Permanent_Home__c, LastModifiedDate, Student__r.Phone FROM Addresses__r WHERE Active__c = true) FROM Account WHERE Id IN: accountIds]) {
            accountAddressMap.put(acc.Id, acc.Addresses__r);
        }
    
        for (Address__c address : newAddressList) {
            Boolean throwError = false;
            if ((address.Student__c == null) || (address.Student__c != null && accountAddressMap.get(address.Student__c).size() == 0)) {
                continue;
            } else {
                for (Address__c existingAddress : accountAddressMap.get(address.Student__c)) {
                    if (address.Id != existingAddress.Id) {
                        if (address.Permanent_Home__c && existingAddress.Permanent_Home__c) {
                            throwError = true;
                        }
                    }
                }
            }
            if (throwError) {
                address.addError('An Account can only have one Address marked as \'Permanent Home\' associated to it.');
            }
        }
    }
  
    public static void updateProfileIntegrationOnAddress(List<Address__c> newAddressList, List<Address__c> oldAddressList, Boolean addressDeleted) {
        System.debug('@AddressTriggerhandler updateProfileIntegrationOnAddress entered');
        if (StopRecursion.DoRun && (!userExclusionSet.contains(UserInfo.getUserId()) || Test.isRunningTest())) {
            StopRecursion.DoRun = false;
            
            String trainingManagerRecordTypeId = Schema.SobjectType.Contact.getRecordTypeInfosByName().get('Training Manager').getRecordTypeId();
            String businessAccountRecordTypeId = Schema.SobjectType.Account.getRecordTypeInfosByName().get('Business Development Account').getRecordTypeId();
            Set<String> validAccountRecordTypes = new Set<String>{
                businessAccountRecordTypeId, 
                Schema.SobjectType.Account.getRecordTypeInfosByName().get('Student Account').getRecordTypeId(), 
                Schema.SobjectType.Account.getRecordTypeInfosByName().get('Locked Student Account').getRecordTypeId()
            };
            
            List<Address__c> addressList = (!addressDeleted ? newAddressList : oldAddressList);
            if ((!addressDeleted) || (addressDeleted && !System.isBatch())) {
                for (Address__c address : addressList) {
                    if (address.Student__c != null && validAccountRecordTypes.contains(address.Related_Record_Type_ID__c)) {
                        if (address.Profile_Services_ID__c != null) {
                            System.debug('@AddressTriggerhandler updateProfileIntegrationOnAddress UpdatePersonInfo_v2 entered');
                            ProfileIntegrations_v2.UpdatePersonInfo_v2(address.Profile_Services_ID__c, address.Student__c, address.Type__c, addressDeleted, null, null);
                        }
                        if (address.Profile_Company_ID__c != null && address.Related_Record_Type_ID__c == businessAccountRecordTypeId) {
                            System.debug('@AddressTriggerhandler updateProfileIntegrationOnAddress UpdateCompanyInformation entered');
                            CreateCompanyProfile.UpdateCompanyInformation(address.Profile_Company_ID__c, address.Student__c, address.Type__c, addressDeleted);
                        }
                    } 
                    /*if (address.Training_Manager__c != null) {
                        if (address.Profile_Services_ID__c != null && address.Related_Record_Type_ID__c == trainingManagerRecordTypeId) {
                            System.debug('@AddressTriggerhandler updateProfileIntegrationOnAddress UpdateTrainingManagerInfo entered');
                            KPMGTrainingMgrIntegrations.UpdateTrainingManagerInfo(address.Profile_Services_ID__c, address.Training_Manager__c);
                        }
                    }*/
                }
            }
        }
    }

    /**
     * Updates any Addresses with multiple checkbox fields checked into individual Address records
     * @param  newAddressList addresses to sync
     */
    public static void flattenAddressTypes(List<Address__c> newAddressList) {
        Set<Id> accountIdsToQuery = new Set<Id>();

        // Loop over the Addresses that have been updated and extract the Student Id of any which have type and checkbox mismatches
        for (Address__c newAddress : newAddressList) {
            // For the Home, Billing, Mailing and Term Time types, check if either the Checkbox is set and the Type does not match, or that the Type is set and the Checkbox does not match
            Boolean homeCheckboxOutOfSync = ((newAddress.Permanent_Home__c && newAddress.Type__c != 'Home') ||
            (newAddress.Type__c == 'Home' && !newAddress.Permanent_Home__c));

            Boolean billingCheckboxOutOfSync = ((newAddress.Primary_Billing__c && newAddress.Type__c != 'Billing') ||
            (newAddress.Type__c == 'Billing' && !newAddress.Primary_Billing__c));

            Boolean deliveryCheckboxOutOfSync = ((newAddress.Primary_Delivery__c && newAddress.Type__c != 'Mailing') ||
            (newAddress.Type__c == 'Mailing' && !newAddress.Primary_Delivery__c));

            Boolean termTimeCheckboxOutOfSync = ((newAddress.Term_Time__c && newAddress.Type__c != 'Term Time') ||
            (newAddress.Type__c == 'Term Time' && !newAddress.Term_Time__c));

            if (
                newAddress.Active__c &&
                (homeCheckboxOutOfSync ||
                billingCheckboxOutOfSync ||
                deliveryCheckboxOutOfSync ||
                termTimeCheckboxOutOfSync)
            ) {
                accountIdsToQuery.add(newAddress.Student__c);
            }
        }

        if (accountIdsToQuery.isEmpty()) {
            return;
        }

        List<Address__c> addressesToUpsert = AddressAlign.queryAndAlignAddresses(new List<Id> (accountIdsToQuery));

        // To avoid running the Triggers excessively and to avoid submitting duplicate events, bypass
        // the Triggers for the duration of the Address upsert
        TriggerHandler.bypass('AddressTriggerHandler');
        upsert addressesToUpsert;
        TriggerHandler.clearBypass('AddressTriggerHandler');
    }

    /**
     * Updates Primary and Term Time checkbox to false for the in active addresses
     */
    public static void clearInactiveAddresses(List<Address__c> newAddressList, Map<Id, Address__c> oldAddressesMap) {
        for (Address__c address : newAddressList) {
            Address__c oldAddress; 
            if (oldAddressesMap != null) {
                oldAddress = oldAddressesMap.get(address.Id);
            }
            if ( (oldAddress != null && !address.Active__c && oldAddress.Active__c) || !address.Active__c) {
                address.Primary_Billing__c = false;
                address.Primary_Delivery__c = false;
                address.Primary__c = false;
                address.Term_Time__c = false;
            }
        }
    }

    public static void populateDetailsConfirmation(List<Address__c> newAddresses, Map<Id, Address__c> oldAddressMap) {
        Map<Id, List<Address__c>> accountIdToAddress = new Map<Id, List<Address__c>>();
        Set<Id> recordTypes = new Set<Id>{ applicationRecordType, lockedApplicationRecordType };

        for (Address__c address : newAddresses) {
            Address__c oldAddress = oldAddressMap?.get(address.Id);

            // address created / updated to active term time
            if (
                address.Zip_Postal_Code__c != null &&
                address.Type__c == 'Term time' &&
                address.Active__c &&
                (oldAddress == null ||
                oldAddress.Type__c != 'Term time' ||
                !oldAddress.Active__c ||
                oldAddress.Zip_Postal_Code__c == null)
            ) {
                List<Address__c> addresses = accountIdToAddress.get(address.Student__c);
                if (addresses == null) {
                    addresses = new List<Address__c>();
                }

                addresses.add(address);
                accountIdToAddress.put(address.Student__c, addresses);
            }
        }

        if (accountIdToAddress.isEmpty()) {
            return;
        }

        List<Opportunity> oppsToUpdate = new List<Opportunity>();

        for (Account account : [
            SELECT
                Id,
                (
                    SELECT Id, accountId
                    FROM Opportunities
                    WHERE RecordTypeId IN :recordTypes AND StageName != 'Cancelled'
                )
            FROM Account
            WHERE
                Emergency_Contact_First_Name__pc != NULL
                AND Emergency_Contact_Mobile__pc != NULL
                AND Id IN :accountIdToAddress.keySet()
        ]) {
            // Skip if theres no Opportunities
            if (account.Opportunities.isEmpty()) {
                continue;
            }

            for (Opportunity opp : account.Opportunities) {
                opp.Confirmation_of_Contact_Details__c = 'Validated';
                oppsToUpdate.add(opp);
            }
        }

        List<Database.SaveResult> oppResults = Database.Update(oppsToUpdate, false);
        for (Integer i = 0; i < oppResults.size(); i++) {
            Database.SaveResult result = oppResults[i];
            if (!result.isSuccess()) {
                List<String> errors = new List<String>();
                for (Database.Error error : result.getErrors()) {
                    errors.add(error.getMessage());
                }
                String errorMessage = String.join(errors, ' | ');
                for (Address__c address : accountIdToAddress.get(oppsToUpdate[i].accountId)) {
                    address.addError(errorMessage);
                }
            }
        }
    }
}
