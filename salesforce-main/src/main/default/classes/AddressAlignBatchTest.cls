@isTest
private class AddressAlignBatchTest {
    @TestSetup
    static void setup() {
        Process_Bypasses__c setting = new Process_Bypasses__c();
        setting.Bypass_All_Triggers__c = true;
        setting.SetupOwnerId = UserInfo.getUserId();
        insert setting;
    }

    @isTest
    private static void itShouldCleanUpAddresses() {
        // GIVEN accounts with addresses
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

        // WHEN the batch is executed
        System.Test.startTest();
        Database.executeBatch(new AddressAlignBatch(), 1);
        System.Test.stopTest();

        List<Address__c> updatedAddresses = [
            SELECT Id, type__c, Permanent_Home__c, Primary_Billing__c, Primary_Delivery__c, Term_Time__c
            FROM Address__c
        ];

        // THEN I expect addresses to be created
        Assert.areEqual(4, updatedAddresses.size());

        // AND checkboxes unchecked
        for (Address__c address : updatedAddresses) {
            if (address.type__c == 'Billing') {
                Assert.isFalse(address.Permanent_Home__c);
                Assert.isTrue(address.Primary_Billing__c);
                Assert.isFalse(address.Primary_Delivery__c);
                Assert.isFalse(address.Term_Time__c);
            } else if (address.type__c == 'Mailing') {
                Assert.isFalse(address.Permanent_Home__c);
                Assert.isFalse(address.Primary_Billing__c);
                Assert.isTrue(address.Primary_Delivery__c);
                Assert.isFalse(address.Term_Time__c);
            } else if (address.type__c == 'Home') {
                Assert.isTrue(address.Permanent_Home__c);
                Assert.isFalse(address.Primary_Billing__c);
                Assert.isFalse(address.Primary_Delivery__c);
                Assert.isFalse(address.Term_Time__c);
            } else if (address.type__c == 'Term Time') {
                Assert.isTrue(address.Term_Time__c);
                Assert.isFalse(address.Permanent_Home__c);
                Assert.isFalse(address.Primary_Billing__c);
                Assert.isFalse(address.Primary_Delivery__c);
            }
        }
    }
}
