global class  CreateInvoiceBatch implements Schedulable, Database.Batchable<sObject>, Database.Stateful {
    public void execute(SchedulableContext SC) {
        Database.executeBatch(this, 1);
    }

    global Database.QueryLocator start(Database.BatchableContext BC) {
        String query = (Test.isRunningTest() ?  'SELECT Id, OrderNumber, Status, BPP_Invoice__r.Name FROM Order WHERE Status = \'Activated\' AND BPP_Internal_Comments__c = \'Migrated from X3\' AND BPP_Invoice__c = null ORDER BY CreatedDate DESC LIMIT 1'
		: 'SELECT Id, OrderNumber, Status, BPP_Invoice__r.Name FROM Order WHERE Status = \'Activated\' AND BPP_Internal_Comments__c = \'Migrated from X3\' AND BPP_Invoice__c = null AND CreatedById = \'' + UserInfo.getUserId() + '\'');
        System.debug(query);
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<Order> orderList) {
        if (orderList.size() > 0){
			for (Order order : orderList) {
                order.blng__BillNow__c = true;
            }
            update orderList;
        }
    }
	
    global void finish(Database.BatchableContext BC) {
        
    }
}