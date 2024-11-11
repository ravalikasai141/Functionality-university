/**
 * Flattens Addresses with multiple checkboxes into individual records
 */
public class AddressAlign {
    /**
     * Queries addresses. Creates one address record per type. Updates type checkboxes
     * @param accountIds List of account ids
     */
    public static List<Address__c> queryAndAlignAddresses(List<Id> accountIds) {
        List<Account> accountsToCheck = [
            SELECT
                Id,
                name,
                (
                    SELECT
                        Id,
                        Type__c,
                        Primary_Billing__c,
                        Primary_Delivery__c,
                        Permanent_Home__c,
                        Term_Time__c,
                        lastModifiedDate,
                        Accommodation_Type__c,
                        Active__c,
                        City__c,
                        County_State__c,
                        Delivery_Instructions__c,
                        Lead__c,
                        Locality__c,
                        Lookup_Country__c,
                        Primary__c,
                        Profile_Company_ID__c,
                        Profile_Services_ID__c,
                        Record_Source__c,
                        Related_Record_Type_ID__c,
                        State_Province__c,
                        Street_1__c,
                        Street_2__c,
                        Street_3__c,
                        Street_4__c,
                        Student__c,
                        Text_Country__c,
                        Text_Locality__c,
                        Text_State__c,
                        Training_Manager__c,
                        Zip_Postal_Code__c
                    FROM Addresses__r
                    WHERE Active__c = TRUE AND Type__c IN ('Home', 'Mailing', 'Billing', 'Term Time')
                )
            FROM Account
            WHERE Id IN :accountIds AND IsPersonAccount = TRUE
        ];

        return alignAddresses(accountsToCheck);
    }

    /**
     * Creates one address record per type. Updates type checkboxes
     * @param accounts List of Accounts
     */
    @TestVisible
    private static List<Address__c> alignAddresses(List<Account> accounts) {
        List<Address__c> addressesToUpsert = new List<Address__c>();

        for (Account account : accounts) {
            Map<String, AddressDetails> addressesByType = new Map<String, AddressDetails>();

            // Loop over each Address and flatten their checkboxes into individual addresses for each checkbox being evaluated which is true
            for (Address__c address : account.Addresses__r) {
                if (address.Permanent_Home__c) {
                    createAddress(addressesByType, address, 'Home');
                }

                if (address.Primary_Billing__c) {
                    createAddress(addressesByType, address, 'Billing');
                }

                if (address.Primary_Delivery__c) {
                    createAddress(addressesByType, address, 'Mailing');
                }

                if (address.Term_Time__c) {
                    createAddress(addressesByType, address, 'Term time');
                }
            }

            Map<String, Address__c> alreadyProcessedPicklistTypes = new Map<String, Address__c>();

            // Re-loop over the Addresses and enrich/inject the existing map with that address data
            for (Address__c address : account.Addresses__r) {
                // If we've already processed a record of the given Type, identify which is newer and update the Id to the most recently updated one, deactivating any others as they are duplicate records
                if (alreadyProcessedPicklistTypes.containsKey(address.Type__c)) {
                    Address__c duplicateAddress = alreadyProcessedPicklistTypes.get(address.Type__c);

                    if (address.lastModifiedDate <= duplicateAddress.lastModifiedDate) {
                        address.Permanent_Home__c = false;
                        address.Primary_Billing__c = false;
                        address.Primary_Delivery__c = false;
                        address.Term_Time__c = false;
                        address.Active__c = false;
                        addressesToUpsert.add(address);
                        continue;
                    } else {
                        duplicateAddress.Permanent_Home__c = false;
                        duplicateAddress.Primary_Billing__c = false;
                        duplicateAddress.Primary_Delivery__c = false;
                        duplicateAddress.Term_Time__c = false;
                        duplicateAddress.Active__c = false;
                        addressesToUpsert.add(duplicateAddress);
                    }
                }

                // If we've not created any Addresses with the current Type using checkboxes, calculate which Checkbox should be selected based on the type and insert the record as it will now have the correct data
                if (!addressesByType.containsKey(address.Type__c)) {
                    address.Permanent_Home__c = address.Type__c == 'Home';
                    address.Primary_Billing__c = address.Type__c == 'Billing';
                    address.Primary_Delivery__c = address.Type__c == 'Mailing';
                    address.Term_Time__c = address.Type__c == 'Term time';

                    AddressDetails newAddressDetails = new AddressDetails();
                    newAddressDetails.newAddress = address;

                    addressesByType.put(address.Type__c, newAddressDetails);
                }
                // Otherwise if we've already created an Address record for the current Type picklist value we can simply inject the Id of the record onto it to make it an update
                else {
                    Address__c AddressToUpdate = addressesByType.get(address.Type__c).newAddress;
                    AddressToUpdate.Id = address.Id;
                }

                // Once we've finished processing the current Type picklist value, flag it as already have been processed for de-duplication later on
                alreadyProcessedPicklistTypes.put(address.Type__c, address);
            }

            // Finally extract the final address records that we must upsert
            for (AddressDetails addressDetails : addressesByType.values()) {
                addressesToUpsert.add(addressDetails.newAddress);
            }
        }
        return addressesToUpsert;
    }

    /**
     * Creates unique Address records
     * @param  addressesByType     All Addresses which have already been created
     * @param  address             The current Address being processed
     * @param  identifier          The current Checkbox being processed
     */
    public static void createAddress(
        Map<String, AddressDetails> addressesByType,
        Address__c address,
        String identifier
    ) {
        if (
            addressesByType.containsKey(identifier) &&
            addressesByType.get(identifier).existingAddress.lastModifiedDate > address.lastModifiedDate
        ) {
            return;
        }

        Address__c newAddress = address.clone(false, true, false, false);
        newAddress.Type__c = identifier;
        newAddress.Permanent_Home__c = identifier == 'Home';
        newAddress.Primary_Billing__c = identifier == 'Billing';
        newAddress.Primary_Delivery__c = identifier == 'Mailing';
        newAddress.Term_Time__c = identifier == 'Term time';

        AddressDetails addressDetails = new AddressDetails();
        addressDetails.existingAddress = address;
        addressDetails.newAddress = newAddress;

        addressesByType.put(identifier, addressDetails);
    }

    // Class to store details relating to the Address
    @TestVisible
    private class AddressDetails {
        public Address__c existingAddress;
        public Address__c newAddress;
    }
}