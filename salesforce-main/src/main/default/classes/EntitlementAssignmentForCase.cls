/*
This is a helper class for CaseHandlerForProcessBuilder
Description :The assignEntitlementForValidatedUserCase function will create an Entitlement process for the Student Account and will associate with the Case.
If the Student Account already have an Entitlement process,then the existing Entilement process will be associated with the Case.
the assignEntitlementForNonValidatedUserCase function will identify the coressponding Entitlement Process for the Non Validated user and will associate with the Case.
*/

public class EntitlementAssignmentForCase
{
    Public static map<String,SlaProcess> slaProcessMap;
    public static map<Id,RecordType> recordTypeMap;
    Static{
          slaProcessMap = new map<String,SlaProcess>();
          for(SlaProcess currSlaProcess : [SELECT Name FROM SlaProcess]){
              slaProcessMap.put(currSlaProcess.Name,currSlaProcess);    
          }
          recordTypeMap = new map<Id,RecordType>([SELECT Id,Name FROM RecordType WHERE SobjectType='Case']);
    }    
    public static void assignEntitlementForValidatedUserCase(List<Case> caseLst){
        List<Case> caseForNonValidatedUser = new List<Case>();
        List<Case > caseLstForProcessing = [SELECT Entitlementid,recordtypeId,AccountId,account.Name FROM case WHERE id in : caseLst];
        System.Debug('caseLstForProcessing bf'+caseLstForProcessing );
        Set<Id> accountIds = new Set<Id>();
        Map<Id,List<Entitlement>> entitlementMap = new Map<Id,List<Entitlement>>();        
        for(Case currCase : caseLstForProcessing){
            if(currCase.AccountId != Null){
                accountIds.add(currCase.AccountId);
            }
        }
        for(Entitlement currEntitlement : [SELECT id,AccountId,case_group__c FROM Entitlement WHERE AccountId in : accountIds]){
                if(entitlementMap.containsKey(currEntitlement.AccountId)){
                    entitlementMap.get(currEntitlement.AccountId).add(currEntitlement);
                }else{
                    entitlementMap.put(currEntitlement.AccountId,new List<Entitlement>{currEntitlement});    
                }
        }
            
            List<case> caseWithoutEntitlementProcess =  new list<case>();
            List<Entitlement> entitlementLstForCreation = new List<Entitlement>(); 
            for(Case currCase : caseLstForProcessing){ 
                currCase.EntitlementId = Null;
                if(entitlementMap.containsKey(currCase.AccountId)){
                    for(Entitlement currEntitlement : entitlementMap.get(currCase.AccountId)){
                        if(currEntitlement.case_group__c == recordTypeMap.get(currCase.recordtypeId).Name){                        
                            currCase.Entitlementid = currEntitlement.id;
                        }
                    }
                }
                
                if(currCase.EntitlementId == Null){
                    entitlementLstForCreation.add(new Entitlement(AccountId = currCase.AccountId,case_group__c = recordTypeMap.get(currCase.recordtypeId).Name,Name = recordTypeMap.get(currCase.recordtypeId).Name + '_Entitlement_Process_for_' +currCase.account.Name, SlaProcessId = slaProcessMap.get(recordTypeMap.get(currCase.recordtypeId).Name).Id,StartDate = System.today() ));
                    caseWithoutEntitlementProcess.add(currCase);  
                }
            }
            
            try{
                if(entitlementLstForCreation.size() > 0)
                    insert entitlementLstForCreation;    
            }catch(Exception ex){
                System.debug('Exception '+ex);
            }
            update caseLstForProcessing;             
            if(caseWithoutEntitlementProcess.size() > 0){
                assignEntitlementForValidatedUserCase(caseWithoutEntitlementProcess);    
            }
            
    }
     public static void assignEntitlementForNonValidatedUserCase(List<Case> caseLst){
        
        map<String,Entitlement> entitlementMap = new map<String,Entitlement>();
        for(Entitlement currEntitlement : [SELECT id,AccountId,name FROM Entitlement WHERE case_group__c = Null]){
            entitlementMap.put(currEntitlement.Name,currEntitlement);
        }
        List<Case> caseForProcessing = [SELECT Entitlementid,recordtypeId,AccountId FROM case WHERE id in : caseLst];
        for(Case currCase : caseForProcessing){
            currCase.Entitlementid = Null;
            if(recordTypeMap.containsKey(currCase.recordtypeId)){    
                if(entitlementMap.containsKey(recordTypeMap.get(currCase.recordtypeId).Name)){     
                            currCase.Entitlementid = entitlementMap.get(recordTypeMap.get(currCase.recordtypeId).Name).Id;
                }
            }
        }
         update caseForProcessing;
    }
}