public class UserHelper {
    public static Set<Id> createUserExclusionSet() {
        List<String> userIdList = Label.IntegrationUserIds.split(';');
        Set<Id> integrationUserIds = new Set<Id>();
        for (String userId : userIdList) {
            integrationUserIds.add(userId);
        }
        return integrationUserIds;
    }

    public static Set<Id> defaultAccountOpportunityUserIdSet() {
        Set<Id> defaultAccountOpportunityUserIdSet = new Set<Id>{
            AssignmentUsers__c.getInstance().Default_Admissions_Owner__c, 
            AssignmentUsers__c.getInstance().Default_Sales_Owner__c
        };
        return defaultAccountOpportunityUserIdSet;
    }
    
    public static Set<Id> defaultLeadUserIdSet() {
        Set<Id> defaultLeadUserUserIdSet = new Set<Id>{
            AssignmentUsers__c.getInstance().Default_Lead_Owner__c, 
            AssignmentUsers__c.getInstance().Default_BES_Owner__c
        };
        return defaultLeadUserUserIdSet;
    }

    public static String obtainReassignmentSourceRole(Id userId) {
        String sourceRole;
        if (userId == AssignmentUsers__c.getInstance().Default_Admissions_Owner__c) {
            sourceRole = 'Admissions Mgmt';
        } else if (userId == AssignmentUsers__c.getInstance().Default_Sales_Owner__c) {
            sourceRole = 'Sales Mgmt';
        } else if (userId == AssignmentUsers__c.getInstance().Default_Lead_Owner__c) {
            sourceRole = 'Qualifying Centre Mgmt';
        } else if (userId == AssignmentUsers__c.getInstance().Default_BES_Owner__c) {
            sourceRole = 'Business Engagement Specialists';
        }
        return sourceRole;
    }

    /*public static void handleUserRoundRobinReassignment(Map<Id, User> oldMap, Map<Id, User> newMap) {
        Set<Id> userIdsToReassign = new Set<Id>();
        for (User newUser : newMap.values()) {
            User oldUser = oldMap.get(newUser.Id);
            if ((oldUser.IsActive && !newUser.IsActive)) {
                userIdsToReassign.add(newUser.Id);
            }
        }
        System.debug(userIdsToReassign);
        if (userIdsToReassign.size() > 0) {
            RoundRobinHandler.reassignRecords(userIdsToReassign);
        }
    }*/

    public static String getOrgName() {
        String orgId = UserInfo.getOrganizationId();
        String orgName;
        switch on orgId {
            when '00Dg0000006TAA8EAO' {
                orgName = 'DEV: ';
            }
            when '00Dg0000006S5LREA0' {
                orgName = 'QA: ';
            }
            when '00Dg000000066hpEAA' {
                orgName = 'UAT: ';
            }
            when '00Db0000000Z8FREA0' {
                orgName = 'Production: ';
            }
            when else {
                orgName = orgId + ': ';
            }
        }
        return orgName;
    }
}