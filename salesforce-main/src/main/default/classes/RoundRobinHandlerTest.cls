@isTest
public class RoundRobinHandlerTest {
    @testSetup
    static void testSetup() {
        String ownerId = UserInfo.getUserId().left(15);
        AssignmentUsers__c assignmentUser = new AssignmentUsers__c();
        assignmentUser.Default_Lead_Owner__c = ownerId;
        assignmentUser.Default_Admissions_Owner__c = ownerId;
        insert assignmentUser;
        
        Id userId = [SELECT Id FROM User WHERE UserRole.Name = 'BD Sales User' AND IsActive = true ORDER BY Name LIMIT 1].Id;
        Id userId2 = [SELECT Id FROM User WHERE UserRole.Name = 'Domestic Team [+Record Assignment]' AND IsActive = true ORDER BY Name LIMIT 1].Id;
        Id userId3 = [SELECT Id FROM User WHERE UserRole.Name = 'QC' AND IsActive = true ORDER BY Name LIMIT 1].Id;
        
        List<Owner_Assignment__c> ownerAssignmentList = new List<Owner_Assignment__c>();
        ownerAssignmentList.add(new Owner_Assignment__c(Name = 'BD Sales User', Last_Assignee__c = userId));
        ownerAssignmentList.add(new Owner_Assignment__c(Name = 'Domestic Team [+Record Assignment]', Last_Assignee__c = userId2));
        ownerAssignmentList.add(new Owner_Assignment__c(Name = 'QC', Last_Assignee__c = userId3));
        insert ownerAssignmentList;

        Database.DMLOptions dbDML = new Database.DMLOptions(); 
        dbDML.DuplicateRuleHeader.allowSave = true;
        dbDML.DuplicateRuleHeader.runAsCurrentUser = true;

        List<Account> accountList = new List<Account>();
        for (Integer i = 0; i < 2; i++) {
            accountList.add(new Account(Name = 'Account ' + i, OwnerId = userId, RecordTypeId = Schema.Sobjecttype.Account.getRecordTypeInfosByName().get('Business Development Account').getRecordTypeId()));
        }
        Database.insert(accountList, dbDML);

        List<Opportunity> opportunityList = new List<Opportunity>();
        for (Integer i = 0; i < 2; i++) {
            opportunityList.add(new Opportunity(AccountId = accountList.get(i).Id, CloseDate = System.today(), Name = 'Opportunity ' + i, OwnerId = userId, RecordTypeId = Schema.Sobjecttype.Opportunity.getRecordTypeInfosByName().get('Business Development').getRecordTypeId(), StageName = 'Quoting', BPP_Sub_Status__c = 'Other'));
        }
        Database.insert(opportunityList, dbDML);

        List<Lead> leadList = new List<Lead>();
        for (Integer i = 0; i < 2; i++) {
            leadList.add(new Lead(Company = 'TestCompany', FirstName = 'Test', LastName = 'Lead ' + i, OwnerId = userId, RecordTypeId = Schema.Sobjecttype.Lead.getRecordTypeInfosByName().get('Business Development').getRecordTypeId(), Status = 'New'));
        }
        Database.insert(leadList, dbDML);
    }
    
    @isTest
    static void test_reassignRecords_RecordChange() {
        String defaultLeadOwner = AssignmentUsers__c.getInstance().Default_Lead_Owner__c;
        String defaultOwner = AssignmentUsers__c.getInstance().Default_Admissions_Owner__c;
        
        Account account = [SELECT Id, OwnerId FROM Account LIMIT 1];
        account.OwnerId = defaultOwner;
        update account;
        
        Opportunity opportunity = [SELECT Id, OwnerId FROM Opportunity LIMIT 1];
        opportunity.OwnerId = defaultOwner;
        update opportunity;
        
        Lead lead = [SELECT Id, OwnerId FROM Lead LIMIT 1];
        lead.OwnerId = defaultLeadOwner;
        update lead;
        
        Account accountAfter = [SELECT OwnerId FROM Account WHERE Id =: account.Id LIMIT 1];
        Opportunity opportunityAfter = [SELECT OwnerId FROM Opportunity WHERE Id =: opportunity.Id LIMIT 1];
        Lead leadAfter = [SELECT OwnerId FROM Lead WHERE Id =: lead.Id LIMIT 1];
        System.assert(accountAfter.OwnerId != defaultOwner);
        System.assert(opportunityAfter.OwnerId != defaultOwner);
        System.assert(leadAfter.OwnerId != defaultLeadOwner);
    }
}