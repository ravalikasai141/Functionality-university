public class RegistryListViewController{
    /*apex method to fetch wrapper of list view*/ 
    @AuraEnabled
    public static list<listViewWrapper> listValues(string objectInfo){
 
        list<listViewWrapper> oListViewWrapper = new list<listViewWrapper>();
 
      /*  Integer pageSize = recordToDisply;
      Integer offset = ((Integer)pageNumber - 1) * pageSize;*/
        
        system.debug('@@UserInfo.getName()@@'+UserInfo.getName());

        for(ListView lv : [SELECT id, Name, DeveloperName FROM ListView
                           WHERE sObjectType = : objectInfo AND (DeveloperName = 'RecentlyViewedCases' OR DeveloperName = 'My_Open_Cases1' OR DeveloperName = 'Student_Records_Case' OR DeveloperName = 'Head_of_Student_Experience_Case' OR DeveloperName = 'Academic_Admin_Case' OR DeveloperName = 'Graduation_Team_Case' OR DeveloperName = 'International_Student_Advice_Case' OR DeveloperName = 'School_Programme_Support_Case' OR DeveloperName = 'Exam_Operations_Case' OR DeveloperName = 'Bus_Tech_Attendance_Case' OR DeveloperName = 'Exam_Queries_Case' OR DeveloperName = 'Overseas_Exams_Case' OR DeveloperName = 'SLC_Queries_Case' OR DeveloperName = 'Exam_Results_Case')]){ 
            listViewWrapper oWrapper = new listViewWrapper();
            oWrapper.label = lv.Name;
            oWrapper.developerName = lv.DeveloperName;
            oListViewWrapper.add(oWrapper);
            //oListViewWrapper.sort();
        }
        
        integer statusnum = 0;
        List<Case> caselist = new List<Case>();
        List<Case> caselisttoUpdate = new List<Case>();
        Case cc;
        boolean responsevar=false;
        Map<Id, Integer> maptocheck = new Map<Id,Integer>();
       // system.debug('@@@rec id'+recordId);
        Id recordTypeId =Schema.SObjectType.Case.getRecordTypeInfosByName().get('Student Query').getRecordTypeId();
            caselist= [select Id, New_Email__c, (select id, Status from EmailMessages) from Case where RecordTypeId =: recordTypeId and Status!= 'Closed' and New_Email__c = true and createddate >= LAST_MONTH ORDER By LastModifieddate DESC limit 40000];
            
            system.debug('caselist@@@'+caselist);
            if(caselist.size()>0)
            {
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