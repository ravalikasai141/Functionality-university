/**********************************************************************
Name: AccountsBillingBatch
Purpose: Updates Accounts Tax Category         
-------                                                             
History                                                             
-------                                                             
VERSION  AUTHOR             DATE              DETAIL                              
0.1 -   Prema Medasani     22/03/2021     INITIAL DEVELOPMENT  
0.1 -   David Lovejoy      02/06/2021     UPDATE  
***********************************************************************/
global class AccountsBillingBatch implements Database.Batchable<Sobject>, Database.Stateful {

    global Database.QueryLocator start(Database.BatchableContext BC) {
        if (Test.isRunningTest()) {
            return Database.getQueryLocator([SELECT Id,RecordTypeId,BillingCountry,Account_Tax_Category__c FROM Account LIMIT 4]);
        } else {
            return Database.getQueryLocator([SELECT Id,RecordTypeId,BillingCountry,Account_Tax_Category__c FROM Account WHERE BillingCountry != null AND Account_Tax_Category__c != 'Exempt Business' LIMIT 49000]);
        }
    }

    global void execute(Database.BatchableContext BC, List<Account> scope) {
        String busRecordTypeId = Schema.Sobjecttype.Account.getRecordTypeInfosByName().get('Business Development Account').getRecordTypeId();
        String stdRecordTypeId = Schema.Sobjecttype.Account.getRecordTypeInfosByName().get('Student Account').getRecordTypeId();

        System.debug('AccountsToUpdate: Scope size = ' + scope.size());
        List<Account> acctoupdate = new List<Account>();

        if (scope.size() > 0) {
            for (Account a : scope) {
                if (a.RecordTypeId == busRecordTypeId && (a.BillingCountry == 'UK' || a.BillingCountry == 'United Kingdom')) {
                    a.Account_Tax_Category__c = 'Domestic Business';
                    acctoupdate.add(a);
                }
                else if (a.RecordTypeId == busRecordTypeId && a.BillingCountry != 'UK' && a.BillingCountry != 'United Kingdom') {
                    a.Account_Tax_Category__c = 'Rest of World Business';
                    acctoupdate.add(a);
                }
                else if (a.RecordTypeId == stdRecordTypeId && (a.BillingCountry == 'UK' || a.BillingCountry == 'United Kingdom')) {
                    a.Account_Tax_Category__c = 'Domestic Customer';
                    acctoupdate.add(a);
                }
                else if (a.RecordTypeId == stdRecordTypeId && a.BillingCountry != 'UK' && a.BillingCountry != 'United Kingdom') {
                    a.Account_Tax_Category__c = 'Rest of World Customer';
                    acctoupdate.add(a);
                }
            }

            if (acctoupdate.size() > 0) {
                for (Account acc : acctoupdate) {
                    system.debug('@@acctoupdate@@'+acc);
                }
                update acctoupdate;
            }
        }
    }

    global void finish(Database.BatchableContext BC){}
}