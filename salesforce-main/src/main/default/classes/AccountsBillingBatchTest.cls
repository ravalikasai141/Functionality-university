/**********************************************************************
Name: AccountsBillingBatchTest
Purpose: Test Class for the Class(AccountsBillingBatch) which updates the Account Tax Category on eligible Accounts                
-------                                                             
History                                                             
-------                                                             
VERSION  AUTHOR             DATE              DETAIL                              
0.1 -   David Lovejoy     02/06/2021      INITIAL DEVELOPMENT  
***********************************************************************/
@isTest
public class AccountsBillingBatchTest {
    public static testmethod void test_UpdateAccountTaxCategory() {
        Id busRecordTypeId = Schema.Sobjecttype.Account.getRecordTypeInfosByName().get('Business Development Account').getRecordTypeId();
        Id stdRecordTypeId = Schema.Sobjecttype.Account.getRecordTypeInfosByName().get('Student Account').getRecordTypeId();
        
        List<Account> accountList = new List<Account>();
        accountList.add(new Account(Name = 'Domestic BusinessAccount', BillingCountry = 'United Kingdom', RecordTypeId = busRecordTypeId));
        accountList.add(new Account(Name = 'NonDomestic BusinessAccount', BillingCountry = 'France', RecordTypeId = busRecordTypeId));
        accountList.add(new Account(FirstName = 'Domestic', LastName = 'StudentAccount', BillingCountry = 'United Kingdom', RecordTypeId = stdRecordTypeId));
        accountList.add(new Account(FirstName = 'NonDomestic', LastName = 'StudentAccount', BillingCountry = 'France', RecordTypeId = stdRecordTypeId));
        insert accountList;

        System.assertEquals(NULL, accountList.get(0).Account_Tax_Category__c, 'Account Tax Category should be null at this point');
        System.assertEquals(NULL, accountList.get(1).Account_Tax_Category__c, 'Account Tax Category should be null at this point');
        System.assertEquals(NULL, accountList.get(2).Account_Tax_Category__c, 'Account Tax Category should be null at this point');
        System.assertEquals(NULL, accountList.get(3).Account_Tax_Category__c, 'Account Tax Category should be null at this point');

        Test.startTest();
        AccountsBillingBatch accountsBillingBatch = new AccountsBillingBatch();
			Integer batchSize = 6;
			Database.ExecuteBatch(accountsBillingBatch, batchSize);
        Test.stopTest();

        List<Account> accountListAfterBatch = [SELECT Account_Tax_Category__c FROM Account];
        System.assertEquals('Domestic Business', accountListAfterBatch.get(0).Account_Tax_Category__c, 'Account Tax Category should be Domestic Business');
        System.assertEquals('Rest of World Business', accountListAfterBatch.get(1).Account_Tax_Category__c, 'Account Tax Category should be Rest of World Business');
        System.assertEquals('Domestic Customer', accountListAfterBatch.get(2).Account_Tax_Category__c, 'Account Tax Category should be Domestic Customer');
        System.assertEquals('Rest of World Customer', accountListAfterBatch.get(3).Account_Tax_Category__c, 'Account Tax Category should be Rest of World Customer');
    }
}