/**********************************************************************
Name: CASLetterPDFCtrl
Purpose: CASLetterPDFCtrl apex controller class is for CAS issued letter with PDF attachment for BPP-24827/BPP-24590                 
-------                                                             
History                                                             
-------                                                             
VERSION  AUTHOR             DATE              DETAIL                              
0.1 -   Swayanprava Sahoo     06/02/2023      INITIAL DEVELOPMENT  
***********************************************************************/
public class CASLetterPDFCtrl {
    public static CASLetterPDFData getCASLetterPDFData(){
        
        CASLetterPDFData casLetterPDFData = new CASLetterPDFData();
        Id oppId = apexpages.Currentpage().getparameters().get('Id');
        Set<Id> accountIds = new Set<Id>();
        Set<Id> contactIds = new Set<Id>();
        System.debug('@OpportunityId@@'+oppId);
        
        casLetterPDFData.opportunityRecord = [
            SELECT Id, AccountId, BPP_Last_Enrolment_Date__c, Course_Instance__r.Name,  Course_Instance__r.Location__c, Course_Instance__r.Start_Date__c, 
            Course_Instance__r.End_Date__c, Course_Instance__r.Level_PQ__c, Total_Sale_Price__c, Discount_Amount__c, CAS_Progression_Justification__c, 
            BPP_CAS_Officer__c, BPP_Course_Level__c, BPP_Previous_Course_Level__c, BPP_Date_CAS_Issued__c, BPP_CAS_Number__c,Programme_Application__r.Name,
            Account.PersonContactId, Account.LastName, Account.FirstName, Account.BNR_Banner_ID__pc, Account.Primary_Nationality__pr.ISO_CODE__c, 
            Account.Gender__pc, Account.SFDC_Country_of_Birth__pr.ISO_CODE__c, Account.Passport_Number__pc, Account.PersonBirthdate,  
            Account.BPP_Reason_SELT_Not_Required__c, Account.Overall_Language_Score__pc, Account.Speaking_Language_Score__pc, Account.Listening_Language_Score__pc, 
            Account.Reading_Language_Score__pc, Account.Writing_Language_Score__pc, Account.Ever_Studied_in_UK_Before__c, Account.Language_Test_Type__pc
            FROM Opportunity WHERE Id =:oppId
        ];
        
        if(casLetterPDFData.opportunityRecord != null && casLetterPDFData.opportunityRecord.AccountId != null){
            casLetterPDFData.accountRecord = [Select id, name, firstname, lastname, BNR_Banner_ID__pc,PersonBirthdate, Primary_Nationality__pr.name, Gender__pc, Passport_Number__pc, SFDC_Country_of_Birth__pr.name, Currently_in_UK_with_a_Visa__c, Preferred_Study_Location__c from Account where id =:casLetterPDFData.opportunityRecord.AccountId];
            if(casLetterPDFData.accountRecord.Id != null){
                System.debug(casLetterPDFData.opportunityRecord);
                System.debug(casLetterPDFData.accountRecord);
                
                casLetterPDFData.dateOfBirth = (casLetterPDFData.accountRecord.PersonBirthdate != null ? casLetterPDFData.accountRecord.PersonBirthdate.format() : null);
                casLetterPDFData.casIssuedDate = (casLetterPDFData.opportunityRecord.BPP_Date_CAS_Issued__c != null ? casLetterPDFData.opportunityRecord.BPP_Date_CAS_Issued__c.format() : null);
                casLetterPDFData.courseStartDate = (casLetterPDFData.opportunityRecord.Course_Instance__r.Start_Date__c != null ? casLetterPDFData.opportunityRecord.Course_Instance__r.Start_Date__c.format() : null);
                casLetterPDFData.courseEndDate = (casLetterPDFData.opportunityRecord.Course_Instance__r.End_Date__c != null ? casLetterPDFData.opportunityRecord.Course_Instance__r.End_Date__c.format() : null);
                casLetterPDFData.lastEnrolmentDate = (casLetterPDFData.opportunityRecord.BPP_Last_Enrolment_Date__c != null ? casLetterPDFData.opportunityRecord.BPP_Last_Enrolment_Date__c.format() : null);
                
                // Main study address
                System.debug('@StudyLocation@@'+casLetterPDFData.opportunityRecord.Course_Instance__r.Location__c);
                if(casLetterPDFData.opportunityRecord.Course_Instance__r.Location__c != null){
                    casLetterPDFData.mainSiteOfStudy = CasData.setMainSiteOfStudy(casLetterPDFData.opportunityRecord.Course_Instance__r.Location__c);
                }
                
                // Course fees for only first year
                casLetterPDFData.courseFeesForFirstYearOnly = CasData.setCourseFeesForFirstYearOnly(casLetterPDFData.opportunityRecord.Total_Sale_Price__c, casLetterPDFData.opportunityRecord.Discount_Amount__c, casLetterPDFData.opportunityRecord.Course_Instance__r.Start_Date__c, casLetterPDFData.opportunityRecord.Course_Instance__r.End_Date__c);
				
                // Total Course Fees Paid to date
                accountIds.add(casLetterPDFData.opportunityRecord.AccountId);
                casLetterPDFData.paymentAmountMap = CasData.createPaymentAmountMap(accountIds);
                system.debug(casLetterPDFData.paymentAmountMap.get(casLetterPDFData.accountRecord.Id));
                casLetterPDFData.paymentAmount = casLetterPDFData.paymentAmountMap.get(casLetterPDFData.accountRecord.Id);

                // Qualification details and English document used for offer
                contactIds.add(casLetterPDFData.opportunityRecord.Account.PersonContactId);
                casLetterPDFData.qualificationMap = CasData.createQualificationMap(contactIds);
                system.debug(casLetterPDFData.qualificationMap);
                System.debug('English Test Type :'+casLetterPDFData.opportunityRecord.Account.Language_Test_Type__pc);
                if(casLetterPDFData.qualificationMap != null){
                    casLetterPDFData.qualificationList = casLetterPDFData.qualificationMap.get(casLetterPDFData.opportunityRecord.Account.PersonContactId);
                	system.debug(casLetterPDFData.qualificationList);
                }
                if (casLetterPDFData.qualificationList != null && casLetterPDFData.qualificationList.size() > 0) {
                    casLetterPDFData.englishDocumentUsedForOffer = CasData.setEnglishDocumentUsedForOffer(casLetterPDFData.opportunityRecord.Account.Language_Test_Type__pc);
                    casLetterPDFData.qualificationDetails = CasData.concatenateQualificationDetails(casLetterPDFData.qualificationList, casLetterPDFData.englishDocumentUsedForOffer);
                    system.debug(casLetterPDFData.qualificationDetails);
                    system.debug(casLetterPDFData.englishDocumentUsedForOffer);
                }
                
                //CAS Progression Justification field value only if the student studied in the UK before 
                casLetterPDFData.casProgressionJustification = null;
                casLetterPDFData.everStudiedInUKBefore = false;
                if(casLetterPDFData.opportunityRecord.Account.Ever_Studied_in_UK_Before__c=='Yes'){
                    casLetterPDFData.everStudiedInUKBefore = true;
                    casLetterPDFData.casProgressionJustification = casLetterPDFData.opportunityRecord.CAS_Progression_Justification__c;
                }
            }
        }
        return casLetterPDFData;
    }
    
    public class CASLetterPDFData {
        public Opportunity opportunityRecord{get;set;}
        public Account accountRecord{get;set;}
        public String dateOfBirth{get;set;}
        public String casIssuedDate{get;set;}
        public String courseStartDate{get;set;}
        public String courseEndDate{get;set;}
        public String lastEnrolmentDate{get;set;}
        public Decimal courseFeesForFirstYearOnly{get;set;}
        public CasData.MainSiteOfStudy mainSiteOfStudy{get;set;}
        public Map<Id, List<Qualification__c>> qualificationMap{get;set;}
        public Map<Id, Decimal> paymentAmountMap{get;set;}
        public Decimal paymentAmount{get;set;}
        public String qualificationDetails{get;set;}
        public String englishDocumentUsedForOffer{get;set;}
        public List<Qualification__c> qualificationList{get;set;}
        public String casProgressionJustification{get;set;}
        public boolean everStudiedInUKBefore{get;set;}
        
    }
}