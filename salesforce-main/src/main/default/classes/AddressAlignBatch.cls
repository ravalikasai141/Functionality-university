public class AddressAlignBatch implements Database.Batchable<SObject> {
    /**
     * Queries all Accounts which have Addresses
     * @param bc BatchableContext
     * @return  Database QueryLocator
     */
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(
            [
                SELECT Id
                FROM Account
                WHERE
                    Id IN (
                        SELECT Student__c
                        FROM Address__c
                        WHERE
                            Active__c = TRUE
                            AND ((Permanent_Home__c = TRUE
                            AND Type__c != 'Home')
                            OR (Type__c = 'Home'
                            AND Permanent_Home__c = FALSE)
                            OR (Primary_Billing__c = TRUE
                            AND Type__c != 'Billing')
                            OR (Type__c = 'Billing'
                            AND Primary_Billing__c = FALSE)
                            OR (Primary_Delivery__c = TRUE
                            AND Type__c != 'Mailing')
                            OR (Type__c = 'Mailing'
                            AND Primary_Delivery__c = FALSE)
                            OR (Term_Time__c = TRUE
                            AND Type__c != 'Term Time')
                            OR (Type__c = 'Term Time'
                            AND Term_Time__c = FALSE))
                    )
            ]
        );
    }

    /**
     * Creates one address record per type. Updates type checkboxes
     * @param bc Batchable Context
     * @param accounts List of Accounts to query Addresses from
     */
    public void execute(Database.BatchableContext bc, List<Account> accounts) {
        List<Id> accountIds = new List<Id>();
        for (Account account : accounts) {
            accountIds.add(account.Id);
        }

        TriggerHandler.bypassAllTriggers = true;
        upsert AddressAlign.queryAndAlignAddresses(accountIds);
    }

    public void finish(Database.BatchableContext bc) {
    }
}
