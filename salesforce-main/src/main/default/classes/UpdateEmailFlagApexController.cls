public with sharing class UpdateEmailFlagApexController{

    @AuraEnabled
    public static boolean emailflagcheck(Id recordId) {
        integer statusnum = 0;
        integer totalEmailsonCase = 0;
        Case cc;
        boolean responsevar=false;
        system.debug('@@@rec id'+recordId);
        if(recordId != null)
        {
            cc = [select id, New_Email__c from case where Id =:recordId];
        }
        for(EmailMessage em : [select id, Status from EmailMessage where ParentId =:recordId])
        {       
            totalEmailsonCase++;
            if(em.id != null)
            {
                if(em.status == '0')
                {
                    statusnum++;
                }
            }
            
            system.debug('@@status@@'+em.status);
        }
        
        if(totalEmailsonCase > 0)
        {
            if(statusnum == 0 && cc.New_Email__c == true)
            {
                cc.New_Email__c = false;
                update cc;
                responsevar = true;
            }
        }
        return responsevar;
    }
}