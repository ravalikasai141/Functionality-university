public with sharing class HubAccountTriggerHandler {
    public static void handleAfterUpdate(Map<Id, Hub_Account__c> oldMap, Map<Id, Hub_Account__c> newMap) {
        Set<Id> hubAccountIdsToUpdateInHub = new Set<Id>();
        for (Hub_Account__c newHubAccount : newMap.values()) {
            Hub_Account__c oldHubAccount = oldMap.get(newHubAccount.Id);
            if (
                newHubAccount.BPP_Requested_Hub_Username__c != null &&
                oldHubAccount.BPP_Requested_Hub_Username__c != newHubAccount.BPP_Requested_Hub_Username__c
            ) {
                hubAccountIdsToUpdateInHub.add(newHubAccount.Id);
            }
        }
        if (hubAccountIdsToUpdateInHub.size() > 0) {
            HubUsernameUpdate.hubUsernameUpdateCallout(hubAccountIdsToUpdateInHub);
        }
    }
}
