public class EmailVerifiedcls{

    public String ObjectId {get;set;}
    public boolean display{get;set;}
    //public String ResponseCode {get;set;}
    List<Case> updatecaselist = new List<Case>();
    
    public EmailVerifiedcls() {
    ObjectId = ApexPages.currentPage().getParameters().get('ObjectId');
    if(ObjectId != null && ObjectId != '')
    {
        Case cc = [select id, CaseNumber, Status from Case where CaseNumber=:ObjectId limit 1];
        if(cc.Status == 'Closed - Unverified')
        {
            display = false;
        }
        else
        {
            display = true;
            //InitPage();
        }
    }
    //ResponseCode = ApexPages.currentPage().getParameters().get('ResponseCode');
    }
    
    public PageReference InitPage() {
        if(ObjectId != null && ObjectId != '')
        {
            List<Case> casevar = [SELECT Id, Status,CaseNumber,Createddate,(select id, TargetDate,milestoneType.Name from caseMilestones) FROM Case WHERE CaseNumber=:ObjectId];
            List<CaseMilestone> casemil = [Select Id, TargetDate,milestoneType.Name from CaseMilestone where CaseId =:casevar[0].Id];
            system.debug('@@@milestoneType.Name@@@'+casemil[0].milestoneType.Name);
            system.debug('@@@casemil List Items@@@'+casemil);
            system.debug('@@@casemil@@@'+casemil[0].TargetDate);
            
            //User us = [Select id, name from User where name = 'Contact Site Guest User'];
            //List<Group> listGrp = [SELECT Id, Type FROM Group WHERE Type = 'Queue' AND DeveloperName = 'Customer_Service_Team'];
            
            for(Case cc : casevar)
            {
                for(caseMilestone cm : cc.caseMilestones)
                {
                    if(cm.milestoneType.Name == 'CSA Email Verification' && cc.Status == 'Unverified')
                    {
                        cc.Status= 'New';
                      //  cc.OwnerId = listGrp[0].id;
                        cc.Case_Auto_Close_Date_Time__c = null;
                        cc.Email_Verification_Auto_Close__c = null;
                        cc.CS_Ready_to_Close__c = true;
                        updatecaselist.add(cc);
                    }
                }
            }
            
            if(!updatecaselist.IsEmpty()){
                Update updatecaselist;
            }
        }
        
        return null;
    }

}