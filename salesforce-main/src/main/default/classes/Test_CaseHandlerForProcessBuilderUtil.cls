@isTest(seeAllData = false)
public class Test_CaseHandlerForProcessBuilderUtil {
    Public static list<Entitlement> entitlementLst;
    Public static void createEntitlementProcess(){
    Map<String,SlaProcess> slaProcessMap = new map<String,SlaProcess>();
          for(SlaProcess currSlaProcess : [select id,Name from SlaProcess]){
              slaProcessMap.put(currSlaProcess.Name,currSlaProcess);    
          }
        Account testAccount = createAccount(); 
        System.Debug('Value'+slaProcessMap);
        entitlementLst = new list<Entitlement>();   
        for(RecordType currRecordType : [SELECT Id,Name FROM RecordType WHERE SobjectType='Case' and Name != :'SIS Error Escalations' and Name != 'Backlog'
                                        and Name != 'Standard' and Name != 'SyncBatch Escalation' and Name != 'Vanta Cases']){
        System.debug('Record type name'+currRecordType.name);
        System.Debug('slaprocess'+slaProcessMap.get(currRecordType.Name).Id);
            if(slaProcessMap.containsKey(currRecordType.Name))
            entitlementLst.add(New Entitlement(AccountId = testAccount.id,Name = currRecordType.Name,SlaProcessId = slaProcessMap.get(currRecordType.Name).Id,StartDate = System.today() ) );           
        }
     insert  entitlementLst; 
    }
    Public static Account createAccount(){    
        Country__c testCountry = createCountry('India', True, 'IN');
        Id MyRecTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Student Account').getRecordTypeId();
        Account testAccount = new Account(firstName = 'test', lastName = 'Account', PersonHomePhone = '7777887788',
                                         Personal_Email__pc = 'test@testaccount.com', Gender__pc = 'Male',
                                         PersonBirthdate = Date.parse('02/09/1990'),
                                         recordTypeId = MyRecTypeId, Country__c = testCountry.Id,AA_Passport_Number__c='12345',
                                         Preferred_Email__pc = 'Personal', Preferred_Phone__pc = 'Home');
        insert testAccount;
        return testAccount;
    }
    Public static Country__c createCountry(String name, Boolean active, String countryCode){        
        Country__c testCountry = new Country__c(Name = name, Active__c = active, Country_Code__c = countryCode);
        insert testCountry;        
        return testCountry;
    }
    Public static Business_Unit__c createBusinessUnit(){
        Business_Unit__c businessUnit = new Business_Unit__c(Name='Test Business Unit');
        insert businessUnit;
        return businessUnit;  
    }
    Public static Case_Group__c createCaseGroup(){
        Case_Group__c caseGroup= new Case_Group__c(Name='Test Case Group');
        insert caseGroup;
        return caseGroup;  
    }
    Public static Issues_Type__c  createIssueType(){ 
        Issues_Type__c issueType = new Issues_Type__c(Case_Group__c = createCaseGroup().id,Name = 'Test Issue type');
        insert  issueType;
        return issueType; 
    }
     Public static List<Case> createCasesForNonValidatedUser(String recordTypeName){
        if(entitlementLst == Null){
            createEntitlementProcess();
        } 
        List<Case> listOfTestCases = new List<Case>();
        Id MyRecTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get(recordTypeName).getRecordTypeId();
        Business_Unit__c businessUnit = createBusinessUnit();
        Issues_Type__c issueType = createIssueType();
        for(Integer i = 0; i < 1; i++){
            Case testCase = new Case(Case_Group__c=issueType.Case_Group__c,Issue_Type__c=issueType .id, Status= 'New', Subject= 'Case'+ i,recordTypeId = MyRecTypeId,Business_Unit__c = businessUnit.id);  
            listOfTestCases.add(testCase);            
        }
        insert listOfTestCases;
        return listOfTestCases;
    }
    Public static List<Case> createCasesForValidatedUser(String recordTypeName){
        Account testAccount = createAccount();
        List<Case> listOfTestCases = new List<Case>();
        Id MyRecTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get(recordTypeName).getRecordTypeId();
        Business_Unit__c businessUnit = createBusinessUnit();
        Issues_Type__c issueType = createIssueType();
        for(Integer i = 0; i < 1; i++){
            Case testCase = new Case(Accountid = testAccount.id,Case_Group__c=issueType.Case_Group__c,Issue_Type__c=issueType .id, Status= 'New', Subject= 'Case'+ i,recordTypeId = MyRecTypeId,Business_Unit__c = businessUnit.id);  
            listOfTestCases.add(testCase);            
        }
        insert listOfTestCases;
        return listOfTestCases;
    }
    
    Public static List<Case> createCasesForPortalUser(String recordTypeName, String Source){
        Account testAccount = createAccount();
        List<Case> listOfTestCases = new List<Case>();
        Id MyRecTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get(recordTypeName).getRecordTypeId();
        Business_Unit__c businessUnit = createBusinessUnit();
        Issues_Type__c issueType = createIssueType();
        for(Integer i = 0; i < 1; i++){
            Case testCase = new Case(Accountid = testAccount.id,Case_Group__c=issueType.Case_Group__c,Issue_Type__c=issueType .id,Origin = Source,Status= 'New', Subject= 'Case'+ i,recordTypeId = MyRecTypeId,Business_Unit__c = businessUnit.id);  
            listOfTestCases.add(testCase);            
        }
        return listOfTestCases;
    }
    Public static Case updateCaseRecordType(String recordTypeName,Case currCase){
        Id MyRecTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get(recordTypeName).getRecordTypeId();
        currCase.recordTypeId = MyRecTypeId;
        update currCase;
        return currCase;
    }
    
    
}