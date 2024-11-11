public class listViewController {
    /*apex method to fetch wrapper of list view*/ 
    @AuraEnabled
    public static list<listViewWrapper> listValues(string objectInfo){
 
        list<listViewWrapper> oListViewWrapper = new list<listViewWrapper>();
 
        /*for(ListView lv : [SELECT id, Name, DeveloperName FROM ListView
                           WHERE sObjectType = : objectInfo order by Name ASC]){ 
                           system.debug('@@lv.Name@'+lv.Name+'@@lv.Developer Name@@'+lv.DeveloperName);
            listViewWrapper oWrapper = new listViewWrapper();
            oWrapper.label = lv.Name;
            oWrapper.developerName = lv.DeveloperName;
            oListViewWrapper.add(oWrapper);
        }*/
        
        if(UserInfo.getName() == 'Nina Kay' || UserInfo.getName() == 'Prema Medasani' || UserInfo.getName() == 'Jayne Platt')
        {
            for(ListView lv : [SELECT id, Name, DeveloperName FROM ListView
                           WHERE sObjectType = : objectInfo AND (DeveloperName = 'All_Open_CS_cases' OR DeveloperName = 'My_Open_CS_cases' OR DeveloperName = 'My_Closed' OR DeveloperName = 'CS_cases_Closed' OR DeveloperName = 'Unverified_CS_Cases' OR DeveloperName = 'RecentlyViewedCases')])
            { 
                listViewWrapper oWrapper = new listViewWrapper();
                oWrapper.label = lv.Name;
                oWrapper.developerName = lv.DeveloperName;
                oListViewWrapper.add(oWrapper);
            }
        }
        
        else
        {
            for(ListView lv : [SELECT id, Name, DeveloperName FROM ListView
                           WHERE sObjectType = : objectInfo AND (DeveloperName = 'All_Open_CS_cases' OR DeveloperName = 'My_Open_CS_cases' OR DeveloperName = 'My_Closed' OR DeveloperName = 'CS_cases_Closed' OR DeveloperName = 'RecentlyViewedCases')])
            { 
            listViewWrapper oWrapper = new listViewWrapper();
            oWrapper.label = lv.Name;
            oWrapper.developerName = lv.DeveloperName;
            oListViewWrapper.add(oWrapper);
            }
        }
        
                integer statusnum = 0;
        List<Case> caselist = new List<Case>();
        List<Case> caselisttoUpdate = new List<Case>();
        Case cc;
        boolean responsevar=false;
        Map<Id, Integer> maptocheck = new Map<Id,Integer>();
       // system.debug('@@@rec id'+recordId);
        Id recordTypeId =Schema.SObjectType.Case.getRecordTypeInfosByName().get('Customer Service').getRecordTypeId();
            caselist= [select Id, New_Email__c, (select id, Status from EmailMessages) from Case where RecordTypeId =: recordTypeId and Status!= 'Closed' ORDER By LastModifieddate DESC limit 49000];
            
            system.debug('caselist@@@'+caselist);
            for(Case cca: caselist)
            {
                integer numbervar = 0;
                for(EmailMessage em : cca.EmailMessages)
                {
                    if(em.Status == '0')
                    {
                        numbervar = 1;
                    }
                    maptocheck.put(cca.Id,numbervar);
                }
            }
            
            system.debug('maptocheck@@@'+maptocheck);
            for(Case cs : caselist)
            {
                if(maptocheck.containsKey(cs.id))
                {
                    if(maptocheck.get(cs.id) == 0)
                    {
                        if(cs.New_Email__c == true)
                        {
                            cs.New_Email__c = false;
                            caselisttoUpdate.add(cs);
                        }
                    }
                    
                }
            }
            system.debug('caselisttoUpdate.size()@@@'+caselisttoUpdate.size());
            system.debug('caselisttoUpdate@@'+caselisttoUpdate);
            if(caselisttoUpdate.size()>0)
            {
                update caselisttoUpdate;
            }
        
        
        
        return oListViewWrapper; 
    }
 
    /*wrapper class to store listView details*/ 
    public class listViewWrapper{
        @AuraEnabled public string label{get;set;} 
        @AuraEnabled public string developerName{get;set;} 
    }
}