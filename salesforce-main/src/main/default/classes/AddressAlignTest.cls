@isTest
public class AddressAlignTest {
    @TestSetup
    static void setup() {
        Process_Bypasses__c setting = new Process_Bypasses__c();
        setting.Bypass_All_Triggers__c = true;
        setting.SetupOwnerId = UserInfo.getUserId();
        insert setting;

        Id recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName()
            .get('Student Account')
            .getRecordTypeId();

        Account account = new Account(
            RecordTypeId = recordTypeId,
            FirstName = 'Test',
            LastName = 'Tester',
            Salutation = 'Mr',
            PersonEmail = 'test@bpp.com',
            Preferred_Email__pc = 'Personal',
            Personal_Email__pc = 'test@bpp.com'
        );
        insert account;

        insert new List<Address__c>{
            new Address__c(
                Street_1__c = 'Street0',
                Type__c = 'Mailing',
                Primary_Delivery__c = true,
                Primary_Billing__c = true,
                Active__c = true,
                Student__c = account.Id
            ),
            new Address__c(
                Street_1__c = 'Street2',
                Type__c = 'Home',
                Term_Time__c = true,
                Active__c = true,
                Student__c = account.Id
            )
        };
    }

    @isTest
    static void itShouldCorrectlyFlattenAddresses() {
        // GIVEN an Account with Addresses
        List<Account> accountsToUpdate = [
            SELECT
                Id,
                (
                    SELECT
                        Id,
                        Type__c,
                        Primary_Billing__c,
                        Primary_Delivery__c,
                        Permanent_Home__c,
                        Term_Time__c,
                        lastModifiedDate,
                        Street_1__c
                    FROM Addresses__r
                    ORDER BY Type__c
                )
            FROM Account
            LIMIT 1
        ];

        // WHEN the createAddress method is executed
        System.Test.startTest();

        List<Address__c> addressResults = AddressAlign.alignAddresses(accountsToUpdate);

        System.Test.stopTest();

        // THEN there should be 4 addresses to upsert
        Assert.areEqual(4, addressResults.size());

        // AND each of the addresses should have a single checkbox and should be linked to the existing records where the types match
        for (Address__c address : addressResults) {
            switch on address.Type__c {
                when 'Mailing' {
                    Assert.isFalse(address.Primary_Billing__c);
                    Assert.isTrue(address.Primary_Delivery__c);
                    Assert.isFalse(address.Permanent_Home__c);
                    Assert.isFalse(address.Term_Time__c);

                    Assert.areEqual(accountsToUpdate[0].Addresses__r[0].Type__c, address.Type__c);
                    Assert.areEqual(accountsToUpdate[0].Addresses__r[0].Id, address.Id);
                }
                when 'Home' {
                    Assert.isFalse(address.Primary_Billing__c);
                    Assert.isFalse(address.Primary_Delivery__c);
                    Assert.isTrue(address.Permanent_Home__c);
                    Assert.isFalse(address.Term_Time__c);

                    Assert.areEqual(accountsToUpdate[0].Addresses__r[1].Type__c, address.Type__c);
                    Assert.areEqual(accountsToUpdate[0].Addresses__r[1].Id, address.Id);
                }
                when 'Billing' {
                    Assert.isTrue(address.Primary_Billing__c);
                    Assert.isFalse(address.Primary_Delivery__c);
                    Assert.isFalse(address.Permanent_Home__c);
                    Assert.isFalse(address.Term_Time__c);

                    Assert.areEqual(null, address.Id);
                }
                when 'Term Time' {
                    Assert.isFalse(address.Primary_Billing__c);
                    Assert.isFalse(address.Primary_Delivery__c);
                    Assert.isFalse(address.Permanent_Home__c);
                    Assert.isTrue(address.Term_Time__c);

                    Assert.areEqual(null, address.Id);
                }
            }
        }
    }

    @isTest
    static void itShouldSortToNewAddressAndExistingAddress() {
        // GIVEN an Address
        Address__c addressToCheck = [
            SELECT
                Id,
                Type__c,
                Primary_Billing__c,
                Primary_Delivery__c,
                Permanent_Home__c,
                Term_Time__c,
                lastModifiedDate,
                Street_1__c
            FROM Address__c
            WHERE Type__c = 'Mailing'
            LIMIT 1
        ];

        Map<String, AddressAlign.AddressDetails> addressesByType = new Map<String, AddressAlign.AddressDetails>();

        // WHEN the createAddress method is executed
        System.Test.startTest();

        AddressAlign.createAddress(addressesByType, addressToCheck, addressToCheck.Type__c);

        System.Test.stopTest();

        // THEN there should be a single entry in the Address Map
        Assert.areEqual(1, addressesByType.size());

        // AND the key matches the given Addresses Type
        Assert.isTrue(addressesByType.containsKey(addressToCheck.Type__c));

        // AND the existing details in the address map matches that of the provided Address
        AddressAlign.AddressDetails resultingAddressDetails = addressesByType.get(addressToCheck.Type__c);
        Assert.areEqual(
            addressToCheck.Primary_Delivery__c,
            resultingAddressDetails.existingAddress.Primary_Delivery__c
        );
        Assert.areEqual(addressToCheck.Primary_Billing__c, resultingAddressDetails.existingAddress.Primary_Billing__c);
        Assert.areEqual(addressToCheck.Type__c, resultingAddressDetails.existingAddress.Type__c);

        // AND the new details in the address map should have updated the Address to have a single checkbox
        Assert.areEqual(addressToCheck.Primary_Delivery__c, resultingAddressDetails.newAddress.Primary_Delivery__c);
        Assert.areNotEqual(addressToCheck.Primary_Billing__c, resultingAddressDetails.newAddress.Primary_Billing__c);
        Assert.areEqual(addressToCheck.Type__c, resultingAddressDetails.newAddress.Type__c);
    }
}
