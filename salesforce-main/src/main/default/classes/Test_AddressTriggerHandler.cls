/**
 * This class contains unit tests for validating the behavior of Apex class AddressTriggerHandler
 */
@isTest
private class Test_AddressTriggerHandler {
    @TestSetup
    static void setup() {
        Process_Bypasses__c setting = new Process_Bypasses__c();
        setting.Bypass_All_Triggers__c = true;
        setting.SetupOwnerId = UserInfo.getUserId();
        insert setting;

        Id studentRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName()
            .get('Student Account')
            .getRecordTypeId();

        Id nonStudentRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName()
            .get('Business Development Account')
            .getRecordTypeId();

        Account studentAccount = new Account(
            RecordTypeId = studentRecordTypeId,
            FirstName = 'Test',
            LastName = 'Tester',
            Salutation = 'Mr',
            PersonEmail = 'test@bpp.com',
            Preferred_Email__pc = 'Personal',
            Personal_Email__pc = 'test@bpp.com'
        );
        insert studentAccount;

        Account bizDevAccount = new Account(RecordTypeId = nonStudentRecordTypeId, Name = 'Thisisa Test');
        insert bizDevAccount;

        insert new List<Address__c>{
            new Address__c(
                Student__c = studentAccount.Id,
                Street_1__c = 'Test St',
                Type__c = 'Home',
                Primary_Billing__c = true,
                Primary_Delivery__c = true,
                Term_Time__c = true
            ),
            new Address__c(
                Student__c = bizDevAccount.Id,
                Street_1__c = 'Fake street',
                Type__c = 'Home',
                Primary_Billing__c = true,
                Primary_Delivery__c = true,
                Permanent_Home__c = true
            )
        };

        delete [SELECT Id FROM Process_Bypasses__c];
    }

    static testMethod void myUnitTest() {
        country_list__c cntry = CreateTestData.createCountry1();
        State_Province__c stt = CreateTestData.createStateProvince();
        Locality__c lct = CreateTestData.createLocality();
        Account a = CreateTestData.createAccount1(cntry);
        Contact tmC = CreateTestData.createTMContact();
        Test.startTest();
        Address__c addr = CreateTestData.createAddress(a, null, tmC, cntry, stt, lct, true, 'Billing');
        try {
            addr = CreateTestData.createAddress(a, null, tmC, cntry, stt, lct, true, 'Home');
        } catch (Exception e) {
            system.debug(e.getMessage());
        }
        Test.stopTest();
    }

    @isTest
    static void itShouldSyncAddressType() {
        delete [SELECT Id FROM Address__c];

        // GIVEN an address
        Account account = new Account(FirstName = 'FirstName', LastName = 'LastName');
        insert account;

        Address__c address = new Address__c(Street_1__c = 'Street', Student__c = account.Id, Type__c = 'Home');
        insert address;

        // WHEN the type is updated
        address.Type__c = 'Mailing';

        Test.startTest();
        update address;
        Test.stopTest();

        // THEN the type checkbox should be updated
        Address__c updatedAddress = [SELECT id, Type__c, Primary_Delivery__c FROM Address__c WHERE Id = :address.Id];
        Assert.areEqual('Mailing', updatedAddress.Type__c);
        Assert.areEqual(true, updatedAddress.Primary_Delivery__c);
    }

    @isTest
    static void itShouldCorrectlyFlattenAddresses() {
        // GIVEN some address data which is invalid (All checkboxes ticked)
        List<Address__c> newAddresses = [
            SELECT
                Id,
                Type__c,
                Active__c,
                Street_1__c,
                Primary_Billing__c,
                Permanent_Home__c,
                Primary_Delivery__c,
                Term_Time__c,
                Student__c
            FROM Address__c
            WHERE Street_1__c = 'Test St'
        ];

        // WHEN the flattenAddressTypes method is executed
        System.Test.startTest();

        AddressTriggerHandler.flattenAddressTypes(newAddresses);

        System.Test.stopTest();

        // THEN there should have been be 4 addresses
        List<Address__c> addressResults = [
            SELECT Id, Type__c, Street_1__c, Primary_Billing__c, Permanent_Home__c, Primary_Delivery__c, Term_Time__c
            FROM Address__c
            WHERE Street_1__c = 'Test St'
            ORDER BY Type__c
        ];

        Assert.areEqual(4, addressResults.size());

        // AND each of the addresses should have a single checkbox and a correct matching Type
        for (Address__c address : addressResults) {
            switch on address.Type__c {
                when 'Mailing' {
                    Assert.isFalse(address.Primary_Billing__c);
                    Assert.isTrue(address.Primary_Delivery__c);
                    Assert.isFalse(address.Permanent_Home__c);
                    Assert.isFalse(address.Term_Time__c);
                }
                when 'Home' {
                    Assert.isFalse(address.Primary_Billing__c);
                    Assert.isFalse(address.Primary_Delivery__c);
                    Assert.isTrue(address.Permanent_Home__c);
                    Assert.isFalse(address.Term_Time__c);

                    // AND the Address with a matching Type should be an update
                    Assert.areEqual(addressResults[1].Type__c, address.Type__c);
                    Assert.areEqual(addressResults[1].Id, address.Id);
                }
                when 'Billing' {
                    Assert.isTrue(address.Primary_Billing__c);
                    Assert.isFalse(address.Primary_Delivery__c);
                    Assert.isFalse(address.Permanent_Home__c);
                    Assert.isFalse(address.Term_Time__c);
                }
                when 'Term Time' {
                    Assert.isFalse(address.Primary_Billing__c);
                    Assert.isFalse(address.Primary_Delivery__c);
                    Assert.isFalse(address.Permanent_Home__c);
                    Assert.isTrue(address.Term_Time__c);
                }
            }
        }
    }
    @isTest
    static void itShouldntTriggerAddressFlatteningForNoneStudentAccounts() {
        // GIVEN an Address related to a non Student Account with address data which is invalid (All checkboxes ticked)
        List<Address__c> newAddresses = [
            SELECT
                Id,
                Type__c,
                Active__c,
                Street_1__c,
                Primary_Billing__c,
                Permanent_Home__c,
                Primary_Delivery__c,
                Term_Time__c,
                Student__c
            FROM Address__c
            WHERE Street_1__c = 'Fake street'
        ];

        // WHEN the flattenAddressTypes method is executed
        System.Test.startTest();

        AddressTriggerHandler.flattenAddressTypes(newAddresses);

        System.Test.stopTest();

        //THEN the Address should have all of the primary fields filled

        List<Address__c> addressResults = [
            SELECT Id, Type__c, Street_1__c, Primary_Billing__c, Permanent_Home__c, Primary_Delivery__c
            FROM Address__c
            WHERE Street_1__c = 'Fake street'
        ];

        Assert.isTrue(addressResults[0].Primary_Billing__c);
        Assert.isTrue(addressResults[0].Primary_Delivery__c);
        Assert.isTrue(addressResults[0].Permanent_Home__c);
    }

    @isTest
    static void checkForDuplicateTest() {
        delete [SELECT Id FROM Address__c];

        // GIVEN an address
        Account account = [SELECT Id FROM Account LIMIT 1];

        List<Address__c> addressesToInsert = new List<Address__c>{
            new Address__c(Street_1__c = 'Street', Student__c = account.Id, Type__c = 'Home', Active__c = true),
            new Address__c(Street_1__c = 'Street 2', Student__c = account.Id, Type__c = 'Mailing', Active__c = true)
        };
        insert addressesToInsert;

        Address__c address2 = addressesToInsert[1];
        address2.Type__c = 'Home';
        address2.Active__c = true;

        Database.SaveResult result = Database.update(address2, false);
        Assert.areEqual(false, result.isSuccess());
    }

    @isTest
    static void itShouldSetContactDetailsConfirmation() {
        // GIVEN a Person account with Emergency Contact and Opportunity
        Account studentAccount = [SELECT id FROM Account WHERE lastName = 'Tester'];
        studentAccount.Emergency_Contact_First_Name__pc = 'Name';
        studentAccount.Emergency_Contact_Mobile__pc = '012345';
        update studentAccount;

        Opportunity oppBefore = new Opportunity(
            Name = 'Test-Opp',
            AccountId = studentAccount.Id,
            RecordTypeId = AddressTriggerHandler.applicationRecordType,
            StageName = 'Application',
            CloseDate = Date.today()
        );
        insert oppBefore;

        // WHEN an Address is added

        System.Test.startTest();

        insert new Address__c(Type__c = 'Term time', Student__c = studentAccount.Id, Zip_Postal_Code__c = 'B01');

        System.Test.stopTest();

        // THEN Confirmation_of_Contact_Details__c is set to 'Validated'
        Opportunity oppAfter = [
            SELECT id, Confirmation_of_Contact_Details__c
            FROM Opportunity
            WHERE Id = :oppBefore.Id
        ];
        Assert.areEqual('Validated', oppAfter.Confirmation_of_Contact_Details__c);
    }
}
