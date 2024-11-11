public class RoundRobinHandler {
    private static Set<Id> userIdsToReassign = new Set<Id>();
    private static Set<String> targetRoles = new Set<String>();
    private static List<ReassignmentWrapper> reassignmentWrapperList = new List<ReassignmentWrapper>();

    /* Performs a list of operations for redistributing Accounts/Opportunities/Leads. Triggered by a record being assigned to one of the default role owners */
    public static void reassignRecords(Map<Id, List<SObject>> userOwnedRecordsMap, List<Account> accountList, List<Opportunity> opportunityList, List<Lead> leadList) {
        for (Id currentOwnerId : userOwnedRecordsMap.keyset()) {
            ReassignmentWrapper reassignmentWrapper = new ReassignmentWrapper();
            reassignmentWrapper.currentOwnerId = currentOwnerId;
            String sourceRole = UserHelper.obtainReassignmentSourceRole(currentOwnerId);
            reassignmentWrapper.targetRole = obtainReassignmentTargetRole(sourceRole);
            reassignmentWrapperList.add(reassignmentWrapper);
            userIdsToReassign.add(currentOwnerId);
            targetRoles.add(reassignmentWrapper.targetRole);
        }
        performRoundRobinLogic(userOwnedRecordsMap, null, reassignmentWrapperList, targetRoles, userIdsToReassign, true, accountList, opportunityList, leadList);
    }

    //@future(callout = true)
    /* Performs a list of operations for redistributing Account (w/ associated Opportunities) and Leads. Triggered by User deactivation */
    /*public static void reassignRecords(Set<Id> userIds) {
        List<String> userRoleList = Label.DeactivatedUserRoleReassignment.split(';');
        List<User> userListToReassign = [SELECT Id, Name, UserRole.Name, UserRole.RollupDescription FROM User WHERE Id IN: userIds AND UserRole.RollupDescription IN: userRoleList];
        if (userListToReassign.size() > 0) {
            for (User user : userListToReassign) {
                ReassignmentWrapper reassignmentWrapper = new ReassignmentWrapper();
                reassignmentWrapper.currentOwnerId = user.Id;
                reassignmentWrapper.targetRole = obtainReassignmentTargetRole(user.UserRole.RollupDescription);
                reassignmentWrapperList.add(reassignmentWrapper);
                userIdsToReassign.add(user.Id);
                targetRoles.add(reassignmentWrapper.targetRole);
            }
            Map<Id, List<Id>> userOwnedRecordsMap = generateUserOwnedRecordsMap(userIdsToReassign);
            performRoundRobinLogic(null, userOwnedRecordsMap, reassignmentWrapperList, targetRoles, userIdsToReassign, false, null, null, null);
        }
    }*/
    
    /* Returns the String value of the target Role based on a User's Role Description */
    public static String obtainReassignmentTargetRole(String userRoleDisplayName) {
        String targetRole;
        switch on userRoleDisplayName {
            when 'Admissions', 'Admissions Mgmt' {
                targetRole = 'Domestic Team [+Record Assignment]';
            }
            when 'BD Sales Manager' {
                targetRole = 'BD Sales User';
            }
            when 'Client Services Manager' {
                targetRole = 'Client Services User';
            }
            when 'Customer Service Mgmt' {
                targetRole = 'Customer Service';
            }
            when 'International Mgmt' {
                targetRole = 'International';
            }
            when 'Sales Mgmt', 'Sales Team' {
                targetRole = 'Sales Team [+Record Assignment]';
            }
            when 'Qualifying Centre', 'Qualifying Centre Mgmt' {
                targetRole = 'QC';
            }
            when else {
                targetRole = userRoleDisplayName;
            }
        }
        return targetRole;
    }
    
    /* Creates Map of User Ids with the Account/Lead Ids owned by said User Id. This is used to determine which records need to be be redistributed when the User (the key of the Map) is deactivated */
    /*private static Map<Id, List<Id>> generateUserOwnedRecordsMap(Set<Id> userIds) {
        Set<Id> accountIds = new Set<Id>();
        Map<Id, List<Id>> userOwnedRecordsMap = new Map<Id, List<Id>>();
        for (Account account : [SELECT Id, OwnerId FROM Account WHERE OwnerId IN: userIds ORDER BY Id]) {
            List<Id> accountIdsForMap = userOwnedRecordsMap.get(account.OwnerId);
            if (accountIdsForMap == null) {
                accountIdsForMap = new List<Id>();
                userOwnedRecordsMap.put(account.OwnerId, accountIdsForMap);
            }    
            accountIdsForMap.add(account.Id);
            accountIds.add(account.Id);
        }
        for (Opportunity opportunity : [SELECT Id, OwnerId FROM Opportunity WHERE OwnerId IN: userIds AND AccountId NOT IN: accountIds ORDER BY Id]) {
            List<Id> opportunityIdsForMap = userOwnedRecordsMap.get(opportunity.OwnerId);
            if (opportunityIdsForMap == null) {
                opportunityIdsForMap = new List<Id>();
                userOwnedRecordsMap.put(opportunity.OwnerId, opportunityIdsForMap);
            }    
            opportunityIdsForMap.add(opportunity.Id);
        }
        for (Lead lead : [SELECT Id, OwnerId FROM Lead WHERE OwnerId IN: userIds AND IsConverted = false AND Status != 'No Further Action' ORDER BY Id]) {
            List<Id> leadIdsForMap = userOwnedRecordsMap.get(lead.OwnerId);
            if (leadIdsForMap == null) {
                leadIdsForMap = new List<Id>();
                userOwnedRecordsMap.put(lead.OwnerId, leadIdsForMap);
            }    
            leadIdsForMap.add(lead.Id);
        }
        return userOwnedRecordsMap;
    }*/

    /* Executes the main Round Robin Logic and updates relevant records */
    private static void performRoundRobinLogic(Map<Id, List<SObject>> userOwnedRecordsMapFromRecordChange, Map<Id, List<Id>> userOwnedRecordsMapFromUserDeactivation, List<ReassignmentWrapper> reassignmentWrapperList, Set<String> targetRoles, Set<Id> userIdsToReassign, Boolean triggeredByRecordChange, List<Account> accountList, List<Opportunity> opportunityList, List<Lead> leadList) {
        if (triggeredByRecordChange) {
            addRecordIdsToReassignmentWrapper(userOwnedRecordsMapFromRecordChange, reassignmentWrapperList);
        } /*else {
            addRecordIdsToReassignmentWrapper(userOwnedRecordsMapFromUserDeactivation, reassignmentWrapperList);
        }*/
        Map<String, List<Id>> targetRoleUserMap = generateTargetRoleUserMap(targetRoles, userIdsToReassign);
        Map<String, Owner_Assignment__c> ownerAssignmentMap = generateOwnerAssignmentMap(targetRoles);
        Map<String, Id> targetRoleLastAssignmentMap = generateTargetRoleLastAssignmentMap(ownerAssignmentMap.values());
        Map<String, Id> ownerAssignmentNewOwnerIdMap = completeReassignmentWrapper(targetRoles, targetRoleUserMap, targetRoleLastAssignmentMap, reassignmentWrapperList);
        List<Owner_Assignment__c> ownerAssignmentListToUpdate = generateOwnerAssignmentListToUpdate(ownerAssignmentMap, ownerAssignmentNewOwnerIdMap);

        System.debug('@performRoundRobinLogic: DEBUG START');
            System.debug('generateTargetRoleUserMap - START');
            for (String key : targetRoleUserMap.keyset()) {
                System.debug('key: ' + key);
                for (Id value : targetRoleUserMap.get(key)) {
                    System.debug('value: '+ value);
                }
            }
            System.debug('generateTargetRoleUserMap - END\n');
        
            System.debug('ownerAssignmentMap - START');
            for (String key : ownerAssignmentMap.keyset()) {
                System.debug('key: ' + key + ' | value: ' + ownerAssignmentMap.get(key));
            }
            System.debug('ownerAssignmentMap - END\n');
        
            System.debug('targetRoleLastAssignmentMap - START');
            for (String key : targetRoleLastAssignmentMap.keyset()) {
                System.debug('key: ' + key + ' | value: ' + targetRoleLastAssignmentMap.get(key));
            }
            System.debug('targetRoleLastAssignmentMap - END\n');
        
            System.debug('ownerAssignmentNewOwnerIdMap - START');
            for (String key : ownerAssignmentNewOwnerIdMap.keyset()) {
                System.debug('key: ' + key + ' | value: ' + ownerAssignmentNewOwnerIdMap.get(key));
            }
            System.debug('ownerAssignmentNewOwnerIdMap - END\n');
        System.debug('@performRoundRobinLogic: DEBUG END');

		if (triggeredByRecordChange) {
            if (accountList != null && accountList.size() > 0) {
				updateAccountOwnerOnRecordChange(accountList, reassignmentWrapperList);
                //updateOpportunityOwnerOnAccountOwnerChange(accountList);
			} else if (opportunityList != null && opportunityList.size() > 0) {
				updateOpportunityOwnerOnRecordChange(opportunityList, reassignmentWrapperList);
			} else if (leadList != null && leadList.size() > 0) {
				updateLeadOwnerOnRecordChange(leadList, reassignmentWrapperList);
			}
            updateRecords(ownerAssignmentListToUpdate, null, null, null, true);
		} /*else {
			List<Account> accountListToUpdate = generateAccountListToUpdateForUserDeactivation(reassignmentWrapperList);
            List<Opportunity> opportunityListToUpdate = generateOpportunityListToUpdateForUserDeactivation(reassignmentWrapperList, accountListToUpdate);
            List<Lead> leadListToUpdate = generateLeadListToUpdateForUserDeactivation(reassignmentWrapperList);
            updateRecords(ownerAssignmentListToUpdate, accountListToUpdate, opportunityListToUpdate, leadListToUpdate, false);
		}*/
    }

    /* Populates each ReassignmentWrapper with the record this owned by the deactivated User(s). Ignores deactivated User(s) that do not own a record */
    private static void addRecordIdsToReassignmentWrapper(Map<Id, List<SObject>> userOwnedRecordsMap, List<ReassignmentWrapper> reassignmentWrapperList) {
        List<ReassignmentWrapper> reassignmentWrapperForMultipleRecordsList = new List<ReassignmentWrapper>();
        Integer i = 0;
        while (i < reassignmentWrapperList.size()) {
            ReassignmentWrapper reassignmentWrapper = reassignmentWrapperList.get(i);
            if (userOwnedRecordsMap.get(reassignmentWrapper.currentOwnerId) == null) {
                reassignmentWrapperList.remove(i);
            } else {
                Integer j = 0;
                for (SObject record : userOwnedRecordsMap.get(reassignmentWrapper.currentOwnerId)) {
                    if (j == 0) {
                        reassignmentWrapper.record = record;
                    } else {
                        ReassignmentWrapper reassignmentWrapperForMultipleRecord = new ReassignmentWrapper();
                        reassignmentWrapperForMultipleRecord.currentOwnerId = reassignmentWrapper.currentOwnerId;
                        reassignmentWrapperForMultipleRecord.targetRole = reassignmentWrapper.targetRole;
                        reassignmentWrapperForMultipleRecord.record = record;
                        reassignmentWrapperForMultipleRecordsList.add(reassignmentWrapperForMultipleRecord);
                    }
                    j++;
                }
                i++;
            }
        }
        reassignmentWrapperList.addAll(reassignmentWrapperForMultipleRecordsList);
    }
    
    /* Populates each ReassignmentWrapper with the record Ids that are owned by the deactivated User(s). Ignores deactivated User(s) that do not own a record */
    /*private static void addRecordIdsToReassignmentWrapper(Map<Id, List<Id>> userOwnedRecordsMap, List<ReassignmentWrapper> reassignmentWrapperList) {
        List<ReassignmentWrapper> reassignmentWrapperForMultipleRecordIdsList = new List<ReassignmentWrapper>();
        Integer i = 0;
        while (i < reassignmentWrapperList.size()) {
            ReassignmentWrapper reassignmentWrapper = reassignmentWrapperList.get(i);
            if (userOwnedRecordsMap.get(reassignmentWrapper.currentOwnerId) == null) {
                reassignmentWrapperList.remove(i);
            } else {
                Integer j = 0;
                for (Id recordId : userOwnedRecordsMap.get(reassignmentWrapper.currentOwnerId)) {
                    if (j == 0) {
                        reassignmentWrapper.recordId = recordId;
                    } else {
                        ReassignmentWrapper reassignmentWrapperForMultipleRecordIds = new ReassignmentWrapper();
                        reassignmentWrapperForMultipleRecordIds.currentOwnerId = reassignmentWrapper.currentOwnerId;
                        reassignmentWrapperForMultipleRecordIds.targetRole = reassignmentWrapper.targetRole;
                        reassignmentWrapperForMultipleRecordIds.recordId = recordId;
                        reassignmentWrapperForMultipleRecordIdsList.add(reassignmentWrapperForMultipleRecordIds);
                    }
                    j++;
                }
                i++;
            }
        }
        reassignmentWrapperList.addAll(reassignmentWrapperForMultipleRecordIdsList);
    }*/
    
    /* Creates Map of Role Name and the Ids of the Users on said Role. This is utilised during the round robin logic to which Users each record needs to be assigned to */
    private static Map<String, List<Id>> generateTargetRoleUserMap(Set<String> targetRoles, Set<Id> userIdsToReassign) {
        Map<String, List<Id>> targetRoleUserMap = new Map<String, List<Id>>();
        for (User user : [SELECT Id, UserRole.Name FROM User WHERE UserRole.Name IN: targetRoles AND Id NOT IN: userIdsToReassign AND IsActive = true AND Name NOT IN('Study Visas') ORDER BY Name]) {
            List<Id> userIdsForMap = targetRoleUserMap.get(user.UserRole.Name);
            if (userIdsForMap == null) {
                userIdsForMap = new List<Id>();
                targetRoleUserMap.put(user.UserRole.Name, userIdsForMap);
            }    
            userIdsForMap.add(user.Id);
        }
        return targetRoleUserMap;
    }

    /* Retrieves Owner_Assignment__c records based on target Role(s) */
    private static Map<String, Owner_Assignment__c> generateOwnerAssignmentMap(Set<String> targetRoles) {
        Map<String, Owner_Assignment__c> ownerAssignmentMap = new Map<String, Owner_Assignment__c>();
        for (Owner_Assignment__c ownerAssignment : [SELECT Id, Name, Last_Assignee__c FROM Owner_Assignment__c WHERE Name IN: targetRoles]) {
            ownerAssignmentMap.put(ownerAssignment.Name, ownerAssignment);
        }
        return ownerAssignmentMap;
    }

    /* Creates Map of Owner_Assignment__c record's Name and Last_Assignee__c values. This is utilised during the round robin logic to determine who the last assignee was for each Role */
    private static Map<String, Id> generateTargetRoleLastAssignmentMap(List<Owner_Assignment__c> ownerAssignmentList) {
        Map<String, Id> targetRoleLastAssignmentMap = new Map<String, Id>();
        for (Owner_Assignment__c ownerAssignment : ownerAssignmentList) {
            targetRoleLastAssignmentMap.put(ownerAssignment.Name, ownerAssignment.Last_Assignee__c);
        }
        return targetRoleLastAssignmentMap;
    }
    
    /* Handler method that loops through each target Role and assigns a new OwnerId against each ReassignmentWrapper (using round round logic found in referenced addNewOwnerIdToReassignmentWrapper method) */
    private static Map<String, Id> completeReassignmentWrapper(Set<String> targetRoles, Map<String, List<Id>> targetRoleUserMap, Map<String, Id> targetRoleLastAssignmentMap, List<ReassignmentWrapper> reassignmentWrapperList) {
        Map<String, Id> ownerAssignmentNewOwnerIdMap = new Map<String, Id>();
        for (String targetRole : targetRoles) {
            List<Id> targetRoleUserList = targetRoleUserMap.get(targetRole);
            Map<Id, Integer> userIdIterationMap = generateUserIdIterationMap(targetRoleUserList);
            Id lastAssignee = targetRoleLastAssignmentMap.get(targetRole);

            List<ReassignmentWrapper> reassignmentWrappersRelatedToTargetRoleList = new List<ReassignmentWrapper>();
            for (ReassignmentWrapper reassignmentWrapper : reassignmentWrapperList) {
                if (reassignmentWrapper.targetRole == targetRole) {
                    reassignmentWrappersRelatedToTargetRoleList.add(reassignmentWrapper);
                }
            }
            Map<String, Id> ownerAssignmentNewOwnerIdMapPerRole = addNewOwnerIdToReassignmentWrapper(targetRole, targetRoleUserList, userIdIterationMap, lastAssignee, reassignmentWrappersRelatedToTargetRoleList);
            ownerAssignmentNewOwnerIdMap.putAll(ownerAssignmentNewOwnerIdMapPerRole);
        }
        System.debug('reassignmentWrapperList - START');
        for (ReassignmentWrapper reassignmentWrapper : reassignmentWrapperList) {
            System.debug('recordId: ' + reassignmentWrapper.recordId + ', targetRole: ' + reassignmentWrapper.targetRole + ', currentOwnerId: ' + reassignmentWrapper.currentOwnerId + ', newOwnerId: ' + reassignmentWrapper.newOwnerId + ', record: ' + reassignmentWrapper.record);
        }
        System.debug('reassignmentWrapperList - END\n');
        return ownerAssignmentNewOwnerIdMap;
    }

    /* Creates Map of User Id and an Integer value. This is utilised during the round robin logic to cycle through each active User on a target Role */
    private static Map<Id,Integer> generateUserIdIterationMap(List<Id> userIds) {
        Map<Id, Integer> userIdIterationMap = new Map<Id, Integer>();
        Integer i = 0;
        for (Id userId : userIds){
            userIdIterationMap.put(userId, i);
            i++;
        }
        return userIdIterationMap;
    }

    /* Populates each ReassignmentWrapper with the newOwnerId (using Round Robin logic to cycle through active Users on target Role) */
    private static Map<String, Id> addNewOwnerIdToReassignmentWrapper(String targetRole, List<Id> targetRoleUserList, Map<Id, Integer> userIdIterationMap, Id lastAssignee, List<ReassignmentWrapper> reassignmentWrapperList) {
        Id newOwnerId;
        Integer userIdIterationMapSize = userIdIterationMap.size();
        Integer lastAssigneeIteration = (userIdIterationMap.get(lastAssignee) != null ? userIdIterationMap.get(lastAssignee) : 0);
        Integer reassignmentWrapperListIteration = 0;
        while (reassignmentWrapperListIteration != reassignmentWrapperList.size()) {
            ReassignmentWrapper reassignmentWrapper = reassignmentWrapperList.get(reassignmentWrapperListIteration);
            lastAssigneeIteration = ((lastAssigneeIteration + 1) > (userIdIterationMapSize - 1) ? 0 : (lastAssigneeIteration + 1));
            newOwnerId = targetRoleUserList.get(lastAssigneeIteration);
            reassignmentWrapper.newOwnerId = newOwnerId;
            reassignmentWrapperListIteration++;
        }
        Map<String, Id> ownerAssignmentNewOwnerId = new Map<String, Id>();
        ownerAssignmentNewOwnerId.put(targetRole, newOwnerId);
        return ownerAssignmentNewOwnerId;
    }

    /* Creates a List of Owner_Assignment__c records where each Last_Assignee__c value requires updating */
    private static List<Owner_Assignment__c> generateOwnerAssignmentListToUpdate(Map<String, Owner_Assignment__c> ownerAssignmentMap, Map<String, Id> ownerAssignmentNewOwnerIdMap) {
        List<Owner_Assignment__c> ownerAssignmentList = new List<Owner_Assignment__c>();
        for (String key : ownerAssignmentNewOwnerIdMap.keySet()) {
            Owner_Assignment__c ownerAssignment = ownerAssignmentMap.get(key);
            if (ownerAssignment.Last_Assignee__c != ownerAssignmentNewOwnerIdMap.get(key)) {
                ownerAssignment.Last_Assignee__c = ownerAssignmentNewOwnerIdMap.get(key);
                ownerAssignmentList.add(ownerAssignment);
            }
        }
        return ownerAssignmentList;
    }

    private static void updateAccountOwnerOnRecordChange(List<Account> accountList, List<ReassignmentWrapper> reassignmentWrapperList) {
        for (Account account : accountList) {
            for (ReassignmentWrapper reassignmentWrapper : reassignmentWrapperList) {
                if (account == reassignmentWrapper.record) {
                    account.OwnerId = reassignmentWrapper.newOwnerId;
                }
            }
        }
    }

    /*private static void updateOpportunityOwnerOnAccountOwnerChange(List<Account> accountList) {
        List<Opportunity> opportunityListToUpdate = new List<Opportunity>();
        Set<Id> accountIds = new Set<Id>();
        for (Account account : accountList) {
            if (account.Id != null) {
                accountIds.add(account.Id);
            }
        }
        if (accountIds.size() > 0) {
            List<Opportunity> opportunityList = [SELECT Id, AccountId FROM Opportunity WHERE AccountId IN: accountIds];
            for (Account account : accountList) {
                for (Opportunity opportunity : opportunityList) {
                    if (account.Id == opportunity.AccountId) {
                        opportunity.OwnerId = account.OwnerId;
                        opportunityListToUpdate.add(opportunity);
                    }
                }
            }
        }
        if (opportunityListToUpdate.size() > 0) {
            update opportunityListToUpdate;
        }
    }*/

    private static void updateOpportunityOwnerOnRecordChange(List<Opportunity> opportunityList, List<ReassignmentWrapper> reassignmentWrapperList) {
        for (Opportunity opportunity : opportunityList) {
            for (ReassignmentWrapper reassignmentWrapper : reassignmentWrapperList) {
                if (opportunity == reassignmentWrapper.record) {
                    opportunity.OwnerId = reassignmentWrapper.newOwnerId;
                }
            }
        }
    }

    private static void updateLeadOwnerOnRecordChange(List<Lead> leadList, List<ReassignmentWrapper> reassignmentWrapperList) {
        for (Lead lead : leadList) {
            for (ReassignmentWrapper reassignmentWrapper : reassignmentWrapperList) {
                if (lead == reassignmentWrapper.record) {
                    lead.OwnerId = reassignmentWrapper.newOwnerId;
                }
            }
        }
    }

    /* Creates a List of Account records where each OwnerId requires updating */
    /*private static List<Account> generateAccountListToUpdateForUserDeactivation(List<ReassignmentWrapper> reassignmentWrapperList) {
        List<Account> accountListToUpdate = new List<Account>();
        for (ReassignmentWrapper reassignmentWrapper : reassignmentWrapperList) {
            if (String.valueOf(reassignmentWrapper.recordId).substring(0,3).contains('001')) {
                Account account = new Account(Id = reassignmentWrapper.recordId, OwnerId = reassignmentWrapper.newOwnerId);
                accountListToUpdate.add(account);
            }
        }
        return accountListToUpdate;
    }*/

    /* Creates a List of Opportunity records where each OwnerId requires updating */
    /*private static List<Opportunity> generateOpportunityListToUpdateForUserDeactivation(List<ReassignmentWrapper> reassignmentWrapperList, List<Account> accountList) {
        Set<Id> deactivatedUserIds = new Set<Id>();
        Set<Id> opportunityIds = new Set<Id>();
        Map<Id, Account> accountMap = new Map<Id, Account>();
        List<Opportunity> opportunityListToUpdate = new List<Opportunity>();
        for (ReassignmentWrapper reassignmentwrapper : reassignmentWrapperList) {
            if (String.valueOf(reassignmentWrapper.recordId).substring(0,3).contains('001')) {
                deactivatedUserIds.add(reassignmentWrapper.currentOwnerId);
            }
        }
        for (Account account : accountList) {
            accountMap.put(account.Id, account);
        }
        for (Opportunity opportunity : [SELECT Id, AccountId FROM Opportunity WHERE OwnerId IN: deactivatedUserIds AND AccountId IN: accountMap.keyset()]) {
            Account account = accountMap.get(opportunity.AccountId);
            if (account != null) {
                opportunity.OwnerId = account.OwnerId;
                opportunityListToUpdate.add(opportunity);
                opportunityIds.add(opportunity.Id);
            }
        }
        for (ReassignmentWrapper reassignmentWrapper : reassignmentWrapperList) {
            if (String.valueOf(reassignmentWrapper.recordId).substring(0,3).contains('006')) {
                Opportunity opportunity = new Opportunity(Id = reassignmentWrapper.recordId, OwnerId = reassignmentWrapper.newOwnerId);
                if (!opportunityIds.contains(opportunity.Id)) {
                    opportunityListToUpdate.add(opportunity);
                }
            }
        }
        return opportunityListToUpdate;
    }*/

    /* Creates a List of Lead records where each OwnerId requires updating */
    /*private static List<Lead> generateLeadListToUpdateForUserDeactivation(List<ReassignmentWrapper> reassignmentWrapperList) {
        List<Lead> leadListToUpdate = new List<Lead>();
        for (ReassignmentWrapper reassignmentWrapper : reassignmentWrapperList) {
            if (String.valueOf(reassignmentWrapper.recordId).substring(0,3).contains('00Q')) {
                Lead lead = new Lead(Id = reassignmentWrapper.recordId, OwnerId = reassignmentWrapper.newOwnerId);
                leadListToUpdate.add(lead);
            }
        }
        return leadListToUpdate;
    }*/

    /* Performs the update DML on the records that require changing */
    private static void updateRecords(List<Owner_Assignment__c> ownerAssignmentListToUpdate, List<Account> accountListToUpdate, List<Opportunity> opportunityListToUpdate, List<Lead> leadListToUpdate, Boolean triggeredByRecordChange) {
        System.debug('ownerAssignmentListToUpdate - START');
        if (ownerAssignmentListToUpdate.size() > 0) {
            for (Owner_Assignment__c ownerAssignment : ownerAssignmentListToUpdate) {
                System.debug(ownerAssignment);
            }
            update ownerAssignmentListToUpdate;
        }
        System.debug('ownerAssignmentListToUpdate - END\n');

        System.debug('accountListToUpdate - START');
        if (accountListToUpdate != null && accountListToUpdate.size() > 0) {
            for (Account account : accountListToUpdate) {
                System.debug(account);
            }
            Database.update(accountListToUpdate, triggeredByRecordChange);
        }
        System.debug('accountListToUpdate - END\n');

        System.debug('opportunityListToUpdate - START');
        if (opportunityListToUpdate != null && opportunityListToUpdate.size() > 0) {
            for (Opportunity opportunity : opportunityListToUpdate) {
                System.debug(opportunity);
            }
            Database.update(opportunityListToUpdate, triggeredByRecordChange);
        }
        System.debug('opportunityListToUpdate - END\n');

        System.debug('leadListToUpdate - START');
        if (leadListToUpdate != null && leadListToUpdate.size() > 0) {
            for (Lead lead : leadListToUpdate) {
                System.debug(lead);
            }
           Database.update(leadListToUpdate, triggeredByRecordChange);
        }
        System.debug('leadListToUpdate - END\n');
    }
    
    private class ReassignmentWrapper {
        Id currentOwnerId, newOwnerId, recordId;
        String targetRole;
        SObject record;
    }
}