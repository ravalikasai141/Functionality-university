/*
This is a handler class for Entitlement Assignment Process (Apex code that will be called from Entitlement Assignment Process ) .
Description :whenever an case is created or the case record type is changed and the case status is in 'New',that case will be processed.Validated user case will be associated with an Account, Non validated user case will not be assocaited with an Account.
*/

public class CaseHandlerForProcessBuilder
{  
    @InvocableMethod
    public static void assignEntitlementForCases(List<Id> caseids){
        System.Debug('Case List'+caseids);
        List<Case> caseLst = [SELECT Accountid,Status FROM Case WHERE id in : caseids ];
    System.Debug('Case List'+caseLst );
        List<Case> caseForNonValidatedUser = new List<Case>();
        List<Case> caseForValidatedUser = new List<Case>();
        for(Case currCase : caseLst){
            if(currCase.Accountid != null && currCase.Status =='New'){
                caseForValidatedUser.add(currCase);    
            }else if(currCase.Status == 'New'){
                caseForNonValidatedUser.add(currCase); 
            }
        }
        if(caseForValidatedUser.size() > 0){
            EntitlementAssignmentForCase.assignEntitlementForValidatedUserCase(caseForValidatedUser);
        }
        if(caseForNonValidatedUser.size() > 0){
            EntitlementAssignmentForCase.assignEntitlementForNonValidatedUserCase(caseForNonValidatedUser);
        }
        
    }
}