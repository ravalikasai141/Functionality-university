/**
 * Handles serializing payloads for the `userAccountUpdated` event
 */
public without sharing class StudentSync implements Serializer {
    /**
     * A set of account ids
     */
    public Set<Id> accountIds;

    /**
     * A List of accounts to process
     */
    @TestVisible
    private List<Account> accounts;

    /**
     * A map of Auth0 Id's keyed by Account Id
     */
    private Map<Id, List<String>> authIds;

    /**
     * A collection of address payloads
     */
    private Map<Id, List<Map<String, Object>>> addressPayloads;

    /**
     * A collection of Institute Body payloads
     */
    private Map<Id, List<Map<String, Object>>> institutePayloads;

    public StudentSync() {
        accounts = new List<Account>();
        accountIds = new Set<Id>();
    }

    /**
     * Adds the given account to the map to process
     * @param record Account to process
     */
    public void addRecord(SObject record) {
        // Figure out which Sobject type is being added
        switch on record.getSObjectType().getDescribe().getName() {
            when 'Account' {
                accountIds.add(record.Id);
            }
            when 'Address__c', 'Hub_Account__c', 'Institute_Body__c' {
                accountIds.add((Id) record.get('Student__c'));
            }
        }
    }

    /**
     * Collects the various dependent records and creates payloads
     * @return  Payloads to send to an Emitter
     */
    public List<Map<String, Object>> serialize() {
        List<Map<String, Object>> payloads = new List<Map<String, Object>>();

        fetchAccounts();
        fetchAuthIds();
        fetchAddresses();
        fetchInstituteBodies();

        for (Account account : accounts) {
            List<Object> qualifications = new List<Object>();
            if (institutePayloads.containsKey(account.Id)) {
                qualifications = institutePayloads.get(account.Id);
            }

            if (!authIds.containsKey(account.Id)) {
                continue;
            }

            Map<String, Object> payload = new Map<String, Object>{
                'userIds' => authIds.get(account.Id),
                'studentReferenceNumber' => account.BNR_Banner_ID__pc,
                'personalInfo' => new Map<String, Object>{
                    'title' => account.Salutation,
                    'firstName' => account.FirstName,
                    'lastName' => account.LastName,
                    'middleName' => account.Middle_Name__pc,
                    'preferredName' => account.Preferred_First_Name__pc,
                    'emailAddress' => account.PersonEmail,
                    'dateOfBirth' => account.PersonBirthdate,
                    'mobilePhone' => account.PersonMobilePhone,
                    'workPhone' => account.Work_Phone__pc,
                    'homePhone' => account.PersonHomePhone,
                    'preferredPronouns' => account.PersonPronouns
                },
                'marketingPreferences' => getMarketingPreferences(account),
                'addresses' => addressPayloads.get(account.Id),
                'emergencyContact' => new Map<String, Object>{
                    'relationship' => account.Emergency_Contact_Relationship__pc,
                    'firstName' => account.Emergency_Contact_First_Name__pc,
                    'lastName' => account.Emergency_Contact_Last_Name__pc,
                    'emailAddress' => account.Emergency_Contact_Email__pc,
                    'mobilePhone' => account.Emergency_Contact_Mobile__pc
                },
                'professionalQualifications' => qualifications
            };

            payloads.add(payload);
        }

        return payloads;
    }

    /**
     * Fetches the accounts using the related account set
     */
    private void fetchAccounts() {
        for (Account account : [
            SELECT
                Id,
                Salutation,
                FirstName,
                LastName,
                Middle_Name__pc,
                Preferred_First_Name__pc,
                PersonEmail,
                PersonBirthdate,
                PersonMobilePhone,
                Work_Phone__pc,
                PersonHomePhone,
                Emergency_Contact_Email__pc,
                Emergency_Contact_First_Name__pc,
                Emergency_Contact_Last_Name__pc,
                Emergency_Contact_Mobile__pc,
                Emergency_Contact_Relationship__pc,
                PersonPronouns,
                Post_Opt_In__pc,
                Email_Opt_In__pc,
                Phone_Opt_In__pc,
                Social_Media_Opt_In__pc,
                SMS_Opt_In__pc,
                App_Notifications_Opt_In__pc,
                BNR_Banner_ID__pc
            FROM Account
            WHERE Id IN :accountIds
        ]) {
            accounts.add(account);
        }
    }

    /**
     * Collects the various dependent Address records and creates payloads
     */
    private void fetchAddresses() {
        addressPayloads = new Map<Id, List<Map<String, Object>>>();
        Map<Id, Map<String, Address__c>> studentToAddress = new Map<Id, Map<String, Address__c>>();

        for (Address__c address : [
            SELECT
                Type__c,
                Street_1__c,
                Street_2__c,
                Street_3__c,
                City__c,
                Zip_Postal_Code__c,
                Record_Source__c,
                Student__c,
                Lookup_Country__r.country_code_2__c
            FROM Address__c
            WHERE Student__c IN :accountIds AND Active__c = TRUE AND Type__c != NULL
        ]) {
            // De-dupe addresses
            Map<String, Address__c> typeToAddress = studentToAddress.get(address.Student__c);

            if (typeToAddress == null) {
                typeToAddress = new Map<String, Address__c>();
            }

            typeToAddress.put(address.Type__c, address);

            studentToAddress.put(address.Student__c, typeToAddress);
        }

        // add addresses to payload map
        for (Id studentId : studentToAddress.keySet()) {
            List<Map<String, Object>> addressList = new List<Map<String, Object>>();

            Map<String, Address__c> typeToAddress = studentToAddress.get(studentId);
            for (String addressType : typeToAddress.keySet()) {
                Address__c address = typeToAddress.get(addressType);

                // use addressType instead of the type field, as it may be from the flag
                Map<String, Object> addressPayload = new Map<String, Object>{
                    'type' => addressType == 'Mailing' ? 'Delivery' : addressType,
                    'line1' => address.Street_1__c,
                    'line2' => address.Street_2__c,
                    'line3' => address.Street_3__c,
                    'town' => address.City__c,
                    'postalCode' => address.Zip_Postal_Code__c,
                    'recordSource' => address.Record_Source__c,
                    'country' => address.Lookup_Country__r.country_code_2__c
                };

                addressList.add(addressPayload);
            }

            addressPayloads.put(studentId, addressList);
        }
    }

    /**
     * Collects the various dependent Institute Bodies records and creates payloads
     */
    private void fetchInstituteBodies() {
        institutePayloads = new Map<Id, List<Map<String, Object>>>();

        for (Institute_Body__c institute : [
            SELECT Institute_Body__c, Institute_Number__c, Student__c
            FROM Institute_Body__c
            WHERE Student__c IN :accountIds
        ]) {
            Map<String, Object> institutePayload = new Map<String, Object>{
                'awardingBody' => institute.Institute_Body__c,
                'reference' => institute.Institute_Number__c
            };

            List<Map<String, Object>> instituteList = institutePayloads.get(institute.Student__c);

            if (instituteList == null) {
                instituteList = new List<Map<String, Object>>();
            }

            instituteList.add(institutePayload);
            institutePayloads.put(institute.Student__c, instituteList);
        }
    }

    /**
     * Checks for field values in selected Marketing Preference fields
     * and adds them to the used list of preferences if values are present
     * @param account  Account to extract Marketing Preferences from
     * @return A list of extracted Marketing Preferences
     */

    private List<String> getMarketingPreferences(Account account) {
        List<String> preferences = new List<String>();

        if (account.Post_Opt_In__pc) {
            preferences.add('Post');
        }
        if (account.Email_Opt_In__pc) {
            preferences.add('Email');
        }
        if (account.Phone_Opt_In__pc) {
            preferences.add('Phone');
        }
        if (account.Social_Media_Opt_In__pc) {
            preferences.add('Social media');
        }
        if (account.SMS_Opt_In__pc) {
            preferences.add('SMS');
        }
        if (account.App_Notifications_Opt_In__pc) {
            preferences.add('Push notification');
        }
        return preferences;
    }

    /**
     * Fetches the related Hub Account records and processes the Auth0 Id's
     */
    private void fetchAuthIds() {
        authIds = new Map<Id, List<String>>();

        for (Hub_Account__c hubAccount : [
            SELECT Auth0_Id__c, Student__c
            FROM Hub_Account__c
            WHERE Student__c IN :accountIds AND Auth0_Id__c != NULL
        ]) {
            List<String> ids = authIds.get(hubAccount.Student__c);

            if (ids == null) {
                ids = new List<String>();
            }

            ids.Add(hubAccount.Auth0_Id__c);
            authIds.put(hubAccount.Student__c, ids);
        }
    }
}
