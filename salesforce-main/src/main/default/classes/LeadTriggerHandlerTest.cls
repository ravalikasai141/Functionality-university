@isTest
public class  LeadTriggerHandlerTest {
    @testSetup
	static void testSetup() {
        AssignmentUsers__c assignmentUser = new AssignmentUsers__c();
        assignmentUser.Default_Lead_Owner__c = UserInfo.getUserId().left(15);
        insert assignmentUser;
        
        Id userId = [SELECT Id FROM User WHERE UserRole.Name = 'QC' AND IsActive = true ORDER BY Name LIMIT 1].Id;
        Owner_Assignment__c ownerAssignment = new Owner_Assignment__c(Name = 'QC', Last_Assignee__c = userId);
        insert ownerAssignment;

        List<Lead> leadList = new List<Lead>();
        for (Integer i = 0; i < 2; i++) {
            leadList.add(new Lead(Company = 'TestCompany', FirstName = 'Round', LastName = 'Robin ' + i, OwnerId = userId, RecordTypeId = Schema.Sobjecttype.Lead.getRecordTypeInfosByName().get('Business Development').getRecordTypeId(), Status = 'New'));
        }
        insert leadList;
    }

    @isTest
	static void test_reassignRecords_LeadReassignment() {
        String defaultLeadOwner = AssignmentUsers__c.getInstance().Default_Lead_Owner__c;
        
		List<Lead> leadListBefore = [SELECT Id, OwnerId FROM Lead];
        Id ownerIdBefore = leadListBefore.get(0).OwnerId;
		for (Lead lead : leadListBefore) {
			lead.OwnerId = defaultLeadOwner;
		}
		
        Test.startTest();
		    update leadListBefore;
        Test.stopTest();

        List<Lead> leadListAfter = [SELECT Id, OwnerId FROM Lead];
        for (Lead lead : leadListAfter) {
			System.assert(lead.OwnerId != ownerIdBefore);
			System.assert(lead.OwnerId != defaultLeadOwner);
		}
	}
}