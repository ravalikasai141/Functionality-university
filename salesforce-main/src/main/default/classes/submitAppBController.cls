public class submitAppBController {
    @AuraEnabled
    public static string submitApp(Id recordId) { 
        System.debug('@submitAppBController Opportunity Id: ' + recordId);
        String Errormsg = '';
        String finalresult = '';
        Boolean checkerror = false;
        
        List<Address__c> address = new List<Address__c>();
        List<Sponsorship__c> sponsorship = new List<Sponsorship__c>();
        BNR_SubmitApplication.submitCalloutWrapper classTwoWrap;
        
        Opportunity opp = [SELECT Id, Name, AccountId, Account.AR_Account_Status_Code__c, Stage_Text__c, BNR_Level_Code_Text__c, Account.Account_Type__c, Account.VAT_Code__pc, Account.Phone, Account.PersonEmail, Account.PersonBirthdate, Account.Primary_Nationality__pc, Account.Age__pc, Account.Country_of_Permanent_Address__c, Account.Country_of_Permanent_Address__r.country_code_2__c, Account.PS_Profile_Services_ID__pc, Account.Student_Type__pc, Account.Legal_Entity__c, Sponsorship_Level__c, Sponsorship_Percentage__c, Sponsorship_Amount__c FROM Opportunity WHERE Id =: recordId]; 
        if (opp != null) {
            if (opp.Account.AR_Account_Status_Code__c == 'FinancialHoldApplied') {
                checkerror = true;
                Errormsg = 'Student is on Financial Hold. Application cannot be submitted</br>';
            } else if (opp.Stage_Text__c != 'Accepted - Conditional Firm' && opp.Stage_Text__c != 'Accepted - Unconditional Firm' && opp.Stage_Text__c != 'Accepted - Pmt Received' && opp.Stage_Text__c != 'Transferred' && opp.Stage_Text__c != 'Deferred Entry'){
                checkerror = true;
                Errormsg = 'Submit Application Failed because the Status is not valid</br>';
            } else {
                address = [SELECT Id, Active__c, Type__c FROM Address__c WHERE Active__c = TRUE AND Student__c =: opp.AccountId];
                if (address.size() == 0) {
                    checkerror = true;
                    Errormsg = 'At least One Active Address is Required</br>';
                }
                if (opp.Account.PersonBirthdate == null) {
                    checkerror = true;
                    Errormsg = 'Student Date of Birth is Required</br>';
                }
                if (opp.Account.Primary_Nationality__pc == null){
                    checkerror = true;
                    Errormsg = 'Student Primary Nationality is Required</br>';
                }
                if (opp.BNR_Level_Code_Text__c == 'PQ') {
                    if (opp.Account.Account_Type__c == null) {
                        checkerror = true;
                        Errormsg = 'Account Type is Required</br>';
                    }
                    if (opp.Account.VAT_Code__pc == null) {
                        checkerror = true;
                        Errormsg = 'VAT Code is Required</br>';
                    }
                    if (opp.Account.Phone == null) {
                        checkerror = true;
                        Errormsg = 'At least One Phone is Required</br>';
                    }
                    if (opp.Account.PersonEmail == null) {
                        checkerror = true;
                        Errormsg = 'At least One Email is Required</br>';
                    }
                }
            
                if ((opp.Account.PersonBirthdate != null) && (opp.BNR_Level_Code_Text__c != 'PQ')) {
                    if (opp.Account.Age__pc < 17) {
                        checkerror = true;
                        Errormsg = 'Student must be at least 17 years old</br>';
                    }
                }
                if (opp.BNR_Level_Code_Text__c != 'PQ') {
                    if (opp.Account.Country_of_Permanent_Address__c == null) {
                        checkerror = true;
                        Errormsg = 'Country of Permanent Address is Required</br>';
                    }
                }
                if (opp.Account.PS_Profile_Services_ID__pc == null) {
                    checkerror = true;
                    Errormsg = 'The related Account does not have a Profile ID. A Profile ID is required to submit an application</br>';
                }
                if (opp.Account.Student_Type__pc == null) {
                    checkerror = true;
                    system.debug('@@Errormsg@@'+Errormsg);
                    Errormsg = Errormsg+ 'Student Type is Required</br>';
                    system.debug('@@Errormsg@@'+Errormsg);
                }
                if (opp.Account.Legal_Entity__c == null) {
                    checkerror = true;
                    Errormsg = 'Legal Entity is Required</br>';
                }
                
                sponsorship = [SELECT Id, Active__c, Student__c FROM Sponsorship__c WHERE Active__c = TRUE AND Student__c =: opp.AccountId AND Opportunity__c =: opp.Id];
                if (sponsorship.size() == 0 && opp.Sponsorship_Level__c != null && opp.Sponsorship_Percentage__c != null && opp.Sponsorship_Amount__c != null) {
                    checkerror = true;
                    Errormsg = 'An Active Sponsorship record on Account should exist if Sponsorship level is Partial or Full</br>';
                }
            }
            
            if (!checkerror){
                classTwoWrap = BNR_SubmitApplication.Submitnew(opp.Id);
                System.debug('@@classTwoWrap@@'+classTwoWrap);
                System.debug('@@classTwoWrap Result@@'+classTwoWrap.newResult);

                if (classTwoWrap.newResult != 'Application Submitted Successfully') { 
                    System.debug('@submitAppBController Entered BNR');
                    finalresult = classTwoWrap.newResult; 
                    System.debug('@submitAppBController Entered BNR result: ' + finalresult);
                }
                else{
                    System.debug('@submitAppBController Entered else BNR');
                    String result_updatesisperson = UpdateSISPerson.PersonInformationnew(classTwoWrap.acc,classTwoWrap.opp);
                    System.debug('@submitAppBController result_updatesisperson: ' + result_updatesisperson);
                    insert classTwoWrap.newApp;

                    classTwoWrap.opp.SFDC_Application_Number__c = classTwoWrap.newApp.id;
                    update classTwoWrap.opp;
                    update classTwoWrap.prodList;
                    update classTwoWrap.acc;
                    
                    finalresult = result_updatesisperson;
                    System.debug('@submitAppBController Entered else BNR result' + finalresult);
                }
           }
        }

        System.debug('@submitAppBController checkerror: ' + checkerror);
        System.debug('@submitAppBController Errormsg: ' + Errormsg);
        return (!checkerror ? finalresult : Errormsg);         
   }
}