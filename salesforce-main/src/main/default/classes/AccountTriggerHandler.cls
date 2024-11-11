public class AccountTriggerHandler {
    public static Boolean inMergeContext = false;

    private static Set<Id> userExclusionSet = UserHelper.createUserExclusionSet();
    private static Set<Id> defaultAccountUserIdSet = UserHelper.defaultAccountOpportunityUserIdSet();
    public static String businessAccountRecordTypeId = Schema.SobjectType.Account.getRecordTypeInfosByName()
        .get('Business Development Account')
        .getRecordTypeId();
    public static String studentAccountRecordTypeId = Schema.SobjectType.Account.getRecordTypeInfosByName()
        .get('Student Account')
        .getRecordTypeId();
    public static String lockedStudentAccountRecordTypeId = Schema.SobjectType.Account.getRecordTypeInfosByName()
        .get('Locked Student Account')
        .getRecordTypeId();
    public static Id applicationRecordType = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName()
        .get('Student_Application')
        .getRecordTypeId();
    public static Id lockedApplicationRecordType = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName()
        .get('Locked_Application')
        .getRecordTypeId();

    public static void setPreferredEmail(List<Account> accounts) {
        for (Account account : accounts) {
            if (String.isBlank(account.Preferred_Email__pc) || !account.IsPersonAccount) {
                continue;
            }

            switch on account.Preferred_Email__pc {
                when 'Work' {
                    account.PersonEmail = account.Work_Email__pc;
                }
                when 'Personal' {
                    account.PersonEmail = account.Personal_Email__pc;
                }
                when 'BPP' {
                    account.PersonEmail = account.BPP_Email__pc;
                }
                when 'Other' {
                    account.PersonEmail = account.Other_Email__pc;
                }
                when 'Billing' {
                    account.PersonEmail = account.Billing_Email__pc;
                }
            }
        }
    }

    public static void handleBeforeChanges(List<Account> newAccountsList, Map<Id, Account> oldMap, String context) {
        System.debug('@AccountTriggerHandler handleBeforeChanges entered - context: ' + context);
        Map<Id, List<Account>> ownerToAccountsMap = new Map<Id, List<Account>>();
        List<Account> accountsToProcessForDunning = new List<Account>();
        for (Account account : newAccountsList) {
            String dobStr = String.Valueof(account.PersonBirthdate);
            account.Date_of_Birth_Text__c = dobStr;
            if (
                (context == 'insert' && account.BillingCountry != null) ||
                (context == 'update' &&
                oldMap.get(account.Id).BillingCountry != account.BillingCountry)
            ) {
                populateAccountTaxCategory(account);
            }
            if (
                (context == 'insert' &&
                ((account.IsPersonAccount && account.SFBD__DunningMethod__c == null) ||
                (!account.IsPersonAccount && account.Client_Category__c != null))) ||
                (context == 'update' &&
                (oldMap.get(account.Id).Client_Category__c != account.Client_Category__c && !account.IsPersonAccount))
            ) {
                accountsToProcessForDunning.add(account);
            }
        }

        if (accountsToProcessForDunning.size() > 0) {
            Map<String, Id> dunningMethodMap = createDunningMethodMap();
            System.debug(dunningMethodMap);
            for (Account account : accountsToProcessForDunning) {
                String dunningMethod = setDunningMethodOutput(account.Client_Category__c);
                account.SFBD__DunningMethod__c = dunningMethodMap.get(dunningMethod);
            }
        }
    }

    /**
     * Handles any logic that should run as part of an Account being merged
     * @param  accounts Accounts to include in merge checks
     */
    public static void handleAfterUpdateMerges(List<Account> accounts) {
        Map<Id, Schema.RecordTypeInfo> recordTypes = Account.sObjectType.getDescribe().getRecordTypeInfosById();

        StudentSync studentSync = new StudentSync();
        for (Account currentAccount : accounts) {
            if (recordTypes.get(currentAccount.recordTypeId).getDeveloperName() != 'Student_Account') {
                continue;
            }

            studentSync.addRecord(currentAccount);
        }

        List<Map<String, Object>> payloads = studentSync.serialize();

        if (!payloads.isEmpty()) {
            new PlatformEventEmitter().send('userAccountUpdated', payloads);
        }
    }

    /**
     * Handles any logic to update the various HESA and ESFA fields
     * @param  accounts Accounts to include in merge checks
     */
    public static void updateLearningDisabilityFields(List<Account> accounts) {
        for (Account accountToUpdate : accounts) {
            Set<String> allHESAValues = new Set<String>();
            Set<String> allESFAValues = new Set<String>();
            String primaryDifficultyESFA;

            // Identify any HESA/ESFA values for the Primary Learning Difficulty
            if (accountToUpdate.Primary_Learning_Difficulty__c != null) {
                LearningDifficultyUtilities.LearningDifficulty primaryLearningDifficulty = LearningDifficultyUtilities.difficultiesByCode.get(
                    accountToUpdate.Primary_Learning_Difficulty__c
                );

                if (primaryLearningDifficulty != null) {
                    allHESAValues.add(primaryLearningDifficulty.HESAValue);
                    allESFAValues.add(primaryLearningDifficulty.ESFAValue);

                    primaryDifficultyESFA = primaryLearningDifficulty.ESFAValue;
                }
            }

            // Identify any HESA/ESFA values for the Secondary Learning Difficulty values
            if (accountToUpdate.Secondary_Learning_Difficulty__c != null) {
                for (String currentSecondaryDifficulty : accountToUpdate.Secondary_Learning_Difficulty__c.split(';')) {
                    LearningDifficultyUtilities.LearningDifficulty secondaryLearningDifficulty = LearningDifficultyUtilities.difficultiesByCode.get(
                        currentSecondaryDifficulty
                    );

                    if (secondaryLearningDifficulty != null) {
                        allHESAValues.add(secondaryLearningDifficulty.HESAValue);
                        allESFAValues.add(secondaryLearningDifficulty.ESFAValue);
                    }
                }
            }

            accountToUpdate.Primary_Disability_ESFA__pc = primaryDifficultyESFA;
            accountToUpdate.SFDC_Disability_Type_Code_Select__pc = String.join(new List<String>(allHESAValues), ';');
            accountToUpdate.All_identified_disabilities_ESFA__pc = String.join(new List<String>(allESFAValues), ';');
        }
    }

    /**
     * If delete is part of merge, align addresses
     * @param  accounts accounts after changes
     */
    public static void handleAfterDelete(List<Account> accounts) {
        List<Id> masterRecordIds = new List<Id>();
        for (Account account : accounts) {
            if (account.MasterRecordId != null) {
                masterRecordIds.add(account.MasterRecordId);
            }
        }

        if (!masterRecordIds.isEmpty()) {
            inMergeContext = true;

            List<Address__c> addressesToUpsert = AddressAlign.queryAndAlignAddresses(masterRecordIds);
            TriggerHandler.bypass('AddressTriggerHandler');
            upsert addressesToUpsert;
            TriggerHandler.clearBypass('AddressTriggerHandler');
        }
    }

    private static void populateAccountTaxCategory(Account account) {
        String accountTaxCategory;
        if (
            account.RecordTypeId == businessAccountRecordTypeId &&
            (account.BillingCountry == 'UK' ||
            account.BillingCountry == 'United Kingdom')
        ) {
            accountTaxCategory = 'Domestic Business';
        } else if (
            account.RecordTypeId == businessAccountRecordTypeId &&
            account.BillingCountry != 'UK' &&
            account.BillingCountry != 'United Kingdom'
        ) {
            accountTaxCategory = 'Rest of World Business';
        } else if (
            account.RecordTypeId == studentAccountRecordTypeId &&
            (account.BillingCountry == 'UK' ||
            account.BillingCountry == 'United Kingdom')
        ) {
            accountTaxCategory = 'Domestic Customer';
        } else if (
            account.RecordTypeId == studentAccountRecordTypeId &&
            account.BillingCountry != 'UK' &&
            account.BillingCountry != 'United Kingdom'
        ) {
            accountTaxCategory = 'Rest of World Customer';
        }
        account.Account_Tax_Category__c = accountTaxCategory;
    }

    private static Map<String, Id> createDunningMethodMap() {
        Map<String, Id> dunningMethodMap = new Map<String, Id>();
        for (SFBD__DunningMethod__c dunningMethod : [SELECT Id, Name FROM SFBD__DunningMethod__c]) {
            dunningMethodMap.put(dunningMethod.Name, dunningMethod.Id);
        }
        return dunningMethodMap;
    }

    private static String setDunningMethodOutput(String clientCategory) {
        switch on clientCategory {
            when 'Key Client' {
                return 'Key Client';
            }
            when 'Transactional Client', 'APAC Client', 'LM Client' {
                return 'Transactional';
            }
            when 'APAC Key Client' {
                return 'APAC Key Client';
            }
            when else {
                return 'Students';
            }
        }
    }

    public static void verifyProvisioningEligibility(Map<Id, Account> oldAccountMap, List<Account> newAccountList) {
        Boolean eligibleForProvisioning = false;
        for (Account newAccount : newAccountList) {
            Account oldAccount = oldAccountMap.get(newAccount.Id);
            if (
                newAccount.Email_Address__pc != null &&
                newAccount.Password__pc != null &&
                newAccount.Email_Address__pc.contains('@my.bpp.com') &&
                newAccount.BNR_Banner_ID__pc != null &&
                newAccount.HUB_Student__c == true &&
                oldAccount.Email_Address__pc != newAccount.Email_Address__pc &&
                oldAccount.Password__pc != newAccount.Password__pc
            ) {
                eligibleForProvisioning = true;
            }
        }
        if (eligibleForProvisioning) {
            AWSUniversityProvisioningAPICall.awsProvisioningCallout(newAccountList.get(0).Id, null);
        }
    }

    public static void updateProfileIntegrationAfterUpdate(
        List<Account> accountList,
        Map<Id, Account> oldMap,
        String context,
        Integer accountListSize
    ) {
        if ((StopRecursion.DoRun && !userExclusionSet.contains(UserInfo.getUserId())) || Test.isRunningTest()) {
            System.debug('@AccountTriggerHandler updateProfileIntegrationAfterUpdate entered');
            StopRecursion.DoRun = false;

            Set<String> validRecordTypes = new Set<String>{
                studentAccountRecordTypeId,
                lockedStudentAccountRecordTypeId
            };
            Map<String, String> personInfoMap = new Map<String, String>();
            if (context == 'insert') {
                System.debug('@AccountTriggerHandler updateProfileIntegrationAfterUpdate entered isInsert');
                for (Account account : accountList) {
                    if (account.PS_Profile_Services_ID__pc != null && validRecordTypes.contains(account.RecordTypeId)) {
                        ProfileIntegrations_v2.UpdatePersonInfo_v2(
                            account.PS_Profile_Services_ID__pc,
                            account.Id,
                            null,
                            false,
                            null,
                            null
                        );
                    }
                    if (account.PS_Profile_Services_ID__pc != null) {
                        personInfoMap.put(account.PS_Profile_Services_ID__pc, account.Id);
                    }
                }
            }
            if (context == 'update' && !System.isBatch() && accountListSize < 50) {
                System.debug('@AccountTriggerHandler updateProfileIntegrationAfterUpdate entered isUpdate');
                for (Account account : accountList) {
                    Account oldAccount = oldMap.get(account.Id);
                    if (
                        account.PS_Profile_Services_ID__pc != null &&
                        oldAccount.PS_Profile_Services_ID__pc != null &&
                        validRecordTypes.contains(account.RecordTypeId) &&
                        oldAccount.OwnerId == account.OwnerId
                    ) {
                        List<String> listDeletedPhones = new List<String>();
                        List<String> listDeletedEmails = new List<String>();
                        if (hasValueBeenRemoved(oldAccount.PersonHomePhone, account.PersonHomePhone))
                            listDeletedPhones.add('Home');
                        if (hasValueBeenRemoved(oldAccount.PersonMobilePhone, account.PersonMobilePhone))
                            listDeletedPhones.add('Mobile');
                        if (hasValueBeenRemoved(oldAccount.Work_Phone__pc, account.Work_Phone__pc))
                            listDeletedPhones.add('Business');
                        if (
                            hasValueBeenRemoved(
                                oldAccount.Parents_Guardian_Emergency_Phone__pc,
                                account.Parents_Guardian_Emergency_Phone__pc
                            )
                        )
                            listDeletedPhones.add('Parent');
                        if (hasValueBeenRemoved(oldAccount.Fax, account.Fax))
                            listDeletedPhones.add('Fax');
                        if (hasValueBeenRemoved(oldAccount.Personal_Email__pc, account.Personal_Email__pc))
                            listDeletedEmails.add('Personal');
                        if (hasValueBeenRemoved(oldAccount.Work_Email__pc, account.Work_Email__pc))
                            listDeletedEmails.add('Work');
                        if (hasValueBeenRemoved(oldAccount.BPP_Email__pc, account.BPP_Email__pc))
                            listDeletedEmails.add('BPP');
                        if (hasValueBeenRemoved(oldAccount.Other_Email__pc, account.Other_Email__pc))
                            listDeletedEmails.add('Other');
                        if (hasValueBeenRemoved(oldAccount.Billing_Email__pc, account.Billing_Email__pc))
                            listDeletedEmails.add('Billing');
                        ProfileIntegrations_v2.UpdatePersonInfo_v2(
                            account.PS_Profile_Services_ID__pc,
                            account.Id,
                            null,
                            false,
                            listDeletedPhones,
                            listDeletedEmails
                        );
                    }
                    if (
                        account.PS_Profile_Services_ID__pc != null &&
                        account.PS_Profile_Services_ID__pc != oldAccount.PS_Profile_Services_ID__pc
                    ) {
                        personInfoMap.put(account.PS_Profile_Services_ID__pc, account.Id);
                    }
                    if (
                        account.RecordTypeId == businessAccountRecordTypeId &&
                        account.Profile_Company_ID__c != null &&
                        oldAccount.Profile_Company_ID__c != null &&
                        oldAccount.OwnerId == account.OwnerId
                    ) {
                        CreateCompanyProfile.UpdateCompanyInformation(
                            account.Profile_Company_ID__c,
                            account.Id,
                            'null',
                            false
                        );
                    }
                }
            }
            if (!personInfoMap.isEmpty()) {
                PersonIdentitiesIntegrations.PersonIdentityUpdate(personInfoMap);
            }
        }
    }

    private static Boolean hasValueBeenRemoved(String oldValue, String newValue) {
        return (oldValue != null && newValue == null);
    }

    public static void handleAccountRoundRobinReassignment(
        List<Account> newAccountsList,
        Map<Id, Account> oldMap,
        String context
    ) {
        List<Account> accountsToProcess = new List<Account>();
        for (Account account : newAccountsList) {
            System.debug(
                '@AccountTriggerHandler handleAccountRoundRobinReassignment - account.OwnerId: ' +
                    account.OwnerId +
                    ' : ' +
                    context
            );
            if (
                (context == 'insert' && defaultAccountUserIdSet.contains(account.OwnerId)) ||
                (context == 'update' && defaultAccountUserIdSet.contains(account.OwnerId))
            ) {
                accountsToProcess.add(account);
            }
        }
        System.debug(
            '@AccountTriggerHandler handleAccountRoundRobinReassignment - accountsToProcess.size: ' +
            accountsToProcess.size()
        );
        System.debug(
            '@AccountTriggerHandler handleAccountRoundRobinReassignment - accountsToProcess: ' + accountsToProcess
        );

        Map<Id, List<SObject>> userOwnedRecordsMap = new Map<Id, List<SObject>>();
        for (Account account : accountsToProcess) {
            List<SObject> accountsForMap = userOwnedRecordsMap.get(account.OwnerId);
            if (accountsForMap == null) {
                accountsForMap = new List<SObject>();
                userOwnedRecordsMap.put(account.OwnerId, accountsForMap);
            }
            accountsForMap.add(account);
        }

        if (!userOwnedRecordsMap.isEmpty()) {
            System.debug('@AccountTriggerHandler handleAccountRoundRobinReassignment - context: ' + context);
            RoundRobinHandler.reassignRecords(userOwnedRecordsMap, accountsToProcess, null, null);
        }
    }

    public static void populateDetailsConfirmation(List<Account> newAccounts, Map<Id, Account> oldAccountsMap) {
        Map<Id, Account> accountsToCheck = new Map<Id, Account>();
        Set<Id> recordTypes = new Set<Id>{ applicationRecordType, lockedApplicationRecordType };

        for (Account account : newAccounts) {
            Account oldAccount = oldAccountsMap?.get(account.Id);

            // Emergency contact first name or mobile are populated
            if (
                (oldAccount == null ||
                (account.Emergency_Contact_First_Name__pc != oldAccount.Emergency_Contact_First_Name__pc ||
                account.Emergency_Contact_Mobile__pc != oldAccount.Emergency_Contact_Mobile__pc)) &&
                (account.Emergency_Contact_First_Name__pc != null &&
                account.Emergency_Contact_Mobile__pc != null)
            ) {
                accountsToCheck.put(account.Id, account);
            }
        }

        if (accountsToCheck.isEmpty()) {
            return;
        }

        List<Opportunity> oppsToUpdate = new List<Opportunity>();

        for (Account account : [
            SELECT
                Id,
                (
                    SELECT Id
                    FROM Addresses__r
                    WHERE Type__c = 'Term time' AND Zip_Postal_Code__c != NULL AND Active__c = TRUE
                ),
                (
                    SELECT Id, accountId
                    FROM Opportunities
                    WHERE RecordTypeId IN :recordTypes AND StageName != 'Cancelled'
                )
            FROM Account
            WHERE Id IN :accountsToCheck.keySet()
        ]) {
            // Skip if theres no term time address
            if (account.Addresses__r.isEmpty() || account.Opportunities.isEmpty()) {
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
                accountsToCheck.get(oppsToUpdate[i].accountId).addError(errorMessage);
            }
        }
    }
}
