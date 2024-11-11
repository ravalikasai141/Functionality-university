@isTest(seeAllData = false)
public class Test_CaseHandlerForProcessBuilder{
    /* private static testMethod void checkEntitlementAssignmentForNonValidatedUserCase(){
        Test.startTest();
        List<Case> testCases = new List<Case>();        
        try{
            testCases = Test_CaseHandlerForProcessBuilderUtil.createCasesForNonValidatedUser('Academic');    
        }
        catch(DmlException ex){
        System.Debug('Exception '+ex);
        }
        limitCheck();
        List<Case> listOfCaseCreated = [SELECT Id,Entitlementid,Entitlement.Name FROM Case];
        System.Debug('inserted casse'+listOfCaseCreated);
        System.assertEquals(1, listOfCaseCreated.size()); 
        System.Assert(listOfCaseCreated[0].Entitlement.Name == 'Academic'); 
        Test.stopTest();
                  
    }
    private static testMethod void checkEntitlementAssignmentForNonValidatedUserCaseUpdate(){
        Test.startTest();
        List<Case> testCases = new List<Case>();
        try{
            testCases = Test_CaseHandlerForProcessBuilderUtil.createCasesForNonValidatedUser('Academic');     
            Test_CaseHandlerForProcessBuilderUtil.updateCaseRecordType('Technology',testCases[0]);   
        }
        catch(DmlException ex){
        System.Debug('Exception '+ex);
        }        
       
        limitCheck();
        List<Case> listOfCaseCreated = [SELECT Id,Entitlementid,Entitlement.Name FROM Case];
        System.Debug('inserted casse'+listOfCaseCreated);
        System.assertEquals(1, listOfCaseCreated.size()); 
        System.Assert(listOfCaseCreated[0].Entitlement.Name == 'Technology');
        Test.stopTest();
    }

   
    
    private static testMethod void checkEntitlementAssignmentForValidatedUserCase(){  
  Test.startTest();
        List<Case> testCases = new List<Case>();
        try{
            testCases = Test_CaseHandlerForProcessBuilderUtil.createCasesForValidatedUser('Academic');    
        }
        catch(DmlException ex){
        System.Debug('Exception '+ex);
        }
        limitCheck();
        List<Case> listOfCaseCreated = [SELECT Id,Entitlementid,Entitlement.Case_Group__c FROM Case];
        System.Debug('inserted casse'+listOfCaseCreated);
        System.assertEquals(1, listOfCaseCreated.size()); 
        System.Assert(listOfCaseCreated[0].Entitlement.Case_Group__c== 'Academic'); 
        Test.stopTest();          
    }
      private static testMethod void checkEntitlementAssignmentForValidatedUserCaseUpdate(){
        Test.startTest();
        List<Case> testCases = new List<Case>();
        try{
            testCases = Test_CaseHandlerForProcessBuilderUtil.createCasesForValidatedUser('Academic');     
            Test_CaseHandlerForProcessBuilderUtil.updateCaseRecordType('Technology',testCases[0] );   
        }
        catch(DmlException ex){
        System.Debug('Exception '+ex);
        }        
       
        limitCheck();
        List<Case> listOfCaseCreated = [SELECT Id,Entitlementid,Entitlement.case_group__c  FROM Case];
        System.Debug('inserted casse'+listOfCaseCreated);
        System.assertEquals(1, listOfCaseCreated.size()); 
        System.Assert(listOfCaseCreated[0].Entitlement.case_group__c == 'Technology');
        Test.stopTest();
    }

   
    
     
      private static void limitCheck(){
       System.assert(Limits.getDMLRows() * 100 / Limits.getLimitDMLRows() < 50);
       System.assert(Limits.getDMLStatements() * 100 / Limits.getLimitDMLStatements() < 50);
       System.assert(Limits.getAggregateQueries() * 100 / Limits.getLimitAggregateQueries() < 50);
       System.assert(Limits.getQueries() * 100 / Limits.getLimitQueries() < 50);
       System.assert(Limits.getQueryRows() * 100 / Limits.getLimitQueryRows() < 50);
    }*/

}