public class CreateARSISServiceController {
  
    @AuraEnabled
    public static string ARSISService(Id recordId)
    { 
        system.debug('accid:::'+recordId);
        string Errormsg = '';
        string finalresult = '';
        string result = '';
        string nullARMsg = '';
        string nullSISMsg = '';
        boolean checkerror = false;
        CreateCompanyARAccountService.ARSISCalloutWrapper arsisserviceWrap;
        
        if(recordId != null)
        {
            Account acc = [Select Id, Profile_Company_ID__c from Account where Id=:recordId];
            if(acc.Profile_Company_ID__c == null)
            {
                checkerror = true;
                Errormsg = 'Profile Company ID is Required</br>';
            }
            else
            {
                nullARMsg = CreateCompanyARAccountService.validationRulesForAR(recordId);
                system.debug('@@@nullARMsg@@@'+nullARMsg);
                if(nullARMsg != null && nullARMsg != '')
                {
                    system.debug('@@@nullARMsg@@@'+nullARMsg);
                    checkerror = true;
                    Errormsg = nullARMsg;
                }
                else
                {
                    nullSISMsg = CreateCompanyARAccountService.validationRulesForSIS(recordId);
                    system.debug('@@@@nullSISMsg@@@'+nullSISMsg);
                    if(nullSISMsg != null && nullSISMsg != '')
                    {
                        system.debug('@@@@nullSISMsg@@@'+nullSISMsg);
                        checkerror = true;
                        Errormsg = nullSISMsg;
                    }
                    
                    else
                    {       
                        arsisserviceWrap = CreateCompanyARAccountService.companyARAccIntnew(recordId);
                        system.debug('@@arsisserviceWrap@@'+arsisserviceWrap);
                        system.debug('@@arsisserviceWrap Result@@'+arsisserviceWrap.newResult);
                       
                        if(arsisserviceWrap.newResult != 'Application Submitted Successfully')
                        {
                            checkerror = true;
                            Errormsg = arsisserviceWrap.newResult;
                        }
                        else
                        {
                            result = SISCompanyIntegrations.SISCompanyInt(recordId);
                            system.debug('@@@resultTWO'+result);
                            if(result == 'Application Submitted Successfully')
                            {
                                update arsisserviceWrap.acc;
                            }
                            
                            else if(result != 'Application Submitted Successfully')
                            {
                                checkerror = true;
                                Errormsg = result;
                            }
                        }
                    }
                    system.debug('@@@nullARMsg@@@'+nullARMsg);
                    system.debug('@@@@nullSISMsg@@@'+nullSISMsg);
                
                }
            }
            system.debug('@@@checkerror@@'+checkerror);
            system.debug('@@@Errormsg@@'+Errormsg);
            system.debug('@@result@@@'+result);

            if(checkerror == true && Errormsg != null)
            {
                finalresult = Errormsg;
            }
            else
            {
                finalresult = result;
            }
        }
        system.debug('@@finalresult@@@'+finalresult);
        return finalresult;
    }
}