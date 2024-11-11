public with sharing class InvocableLeadUpdate {
    @InvocableMethod(label='Update Bypass Duplicate Check')
    public static void updateBypassDuplicateCheck(List<Id> leadIds) {
        List<Lead> leadList = [SELECT Lead_Bypass_Duplicate_Check__c FROM Lead WHERE Id IN: leadIds];
        List<Lead> leadListToUpdate = new List<Lead>();
        for (Lead lead : leadList) {
            if (lead.Lead_Bypass_Duplicate_Check__c) {
                lead.Lead_Bypass_Duplicate_Check__c = false;
                leadListToUpdate.add(lead);
            }
        }
        if (leadListToUpdate.size() > 0) {
            update leadListToUpdate;
        }
    }
}