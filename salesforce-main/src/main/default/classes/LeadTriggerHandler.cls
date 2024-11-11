public class LeadTriggerHandler {
    private static Set<Id> defaultLeadUserIdSet = UserHelper.defaultLeadUserIdSet();

    public static void handleBeforeChanges(List<Lead> newLeadList) {
        for (Lead lead : newLeadList) {
            lead.Course_of_Interest_Scoring_Band__c = setCourseOfInterestScoringBand(lead.rfi_course_of_interest__c);
        }
    }
    
    public static String setCourseOfInterestScoringBand(String CoI) {
        String courseOfInterestBand;
        switch on CoI {
            when 'Bar Transfer Test', 'Barrister Training Course (BTC)', 'Higher Rights of Audience', 'Law', 'Law Conversion Course (PGDL)', 'Law Foundations Course', 'Legal Practice Course (LPC)', 'Legal Training', 'Litigation Training Course', 'Master of Laws (LLM)', 'Postgraduate Law', 'Professional Skills Course', 'PSC', 'Solicitor Apprenticeship', 'Solicitors Qualifying Examination (SQE)', 'SQE 1 and SQE 2 Preparation', 'SQE 1 Preparation', 'SQE Coaching', 'SQE Essentials for Practice', 'SQE Law Graduate', 'SQE Law Graduate (Master\'s)', 'SQE Non-Law Graduate (Master\'s)', 'SQE Preparation'{
                courseOfInterestBand = '1';
            }
            when 'ACCA', 'ACCA Applied Knowledge', 'ACCA Applied Skills', 'ACCA Foundation Level', 'ACCA Professional Level Papers', 'ACCA Strategic Professional', 'Accountancy and Tax Courses', 'Accountancy and Tax Postgraduate Courses', 'Advanced Diploma in Accounting and Finance (ACCA Route)', 'BSc Accounting and Finance', 'CIMA', 'CIMA Certificate in Business Accounting', 'CIMA Management', 'CIMA Operational', 'CIMA Strategic', 'MSc Accounting and Finance', 'MSc Accounting and Finance (Adv Diploma)'{
                courseOfInterestBand = '2';
            }
            when 'MSc Psychology (Conversion)', 'MSc Psychology (Conversion) (Online)', 'Psychology', 'Psychology Postgraduate courses'{
                courseOfInterestBand = '3';
            }
            when 'Actuarial Technician Apprenticeship', 'CTA Advanced Technical', 'CTA Application and Professional Skills', 'CTA Computer Based Examinations', 'Data and Technology', 'Data and Technology Apprenticeships', 'Data and Technology Short Courses', 'Data Fundamentals', 'Data Visualisation', 'Digital Technology Solutions Professional Degree Apprenticeship', 'Digital Transformation', 'Level 3 Data Technician Apprenticeship', 'Level 3 Information Communications Technician', 'Level 4 Data Analyst Apprenticeship', 'Level 6 Digital Technology Solutions Professional Degree Apprenticeship', 'Level 7 MSc Applied Data Analytics Apprenticeship', 'Professional Accounting Taxation Technician Level 4 Apprenticeship', 'Professional Accounting/Tax Technician Apprenticeship', 'Using Data for Decision Making'{
                courseOfInterestBand = '4';
            }
            when 'Accountancy and Tax Apprenticeships', 'Accountancy/Taxation Professional Apprenticeship', 'Accounting Taxation Professional Level 7 Apprenticeship', 'Actuary', 'Actuary Apprenticeship', 'Apprenticeship Accounting', 'Apprenticeship General', 'Apprenticeship Professional Services', 'Apprenticeship programmes', 'Assistant Accountant Apprenticeship', 'Associate Project Manager', 'Associate Project Manager Apprenticeship', 'Business Administrator', 'Business Administrator Apprenticeship', 'Chartered Manager', 'Chartered Manager Degree Apprenticeship', 'Coaching Professional', 'Compliance/Risk Officer Apprenticeship', 'Data Analyst Apprenticeship', 'Data Scientist Level 6 Apprenticeship', 'Digital Technology Solutions Specialist Degree Apprenticeship', 'Financial Services Administrator', 'Financial Services Customer Adviser', 'Financial Services Customer Adviser Apprenticeship', 'Financial Services Professional', 'Financial Services Professional Apprenticeship', 'Foundation Degree Nursing Associate Apprenticeship', 'General Apprenticeships', 'HR Consultant / Partner', 'HR Consultant / Partner Apprenticeship', 'HR Support', 'HR Support Apprenticeship', 'Improvement Specialist', 'Insurance Practitioner', 'Insurance Practitioner Apprenticeship', 'Insurance Professional', 'Insurance Professional Apprenticeship', 'Investment Operations Administrator', 'Investment Operations Administrator Apprenticeship', 'Investment Operations Specialist', 'Investment Operations Specialist Apprenticeship', 'Law Apprenticeships', 'Leadership and Management Apprenticeships', 'Mortgage Adviser', 'Mortgage Adviser Apprenticeship', 'Operations / Departmental Manager', 'Operations/Departmental Manager Apprenticeship', 'Paralegal Apprenticeship', 'Registered Nurse Degree Apprenticeship (Adult)', 'Registered Nurse Degree Apprenticeship (Child)', 'Registered Nurse Degree Apprenticeship (Mental Health)', 'Senior Compliance / Risk Specialist Apprenticeship', 'Senior Financial Services Customer Adviser', 'Senior Financial Services Customer Adviser Apprenticeship', 'Senior Insurance Professional', 'Senior Insurance Professional Apprenticeship', 'Senior Investment / Commercial Banking Professional', 'Senior Investment/Commercial Banking Professional Apprenticeship', 'Senior People Professional (HR Level 7) Apprenticeship', 'Team Leader / Supervisor', 'Team Leader/Supervisor Apprenticeship'{
                courseOfInterestBand = '5';
            }
            when else {
                courseOfInterestBand = 'X';
            }
        }
        return courseOfInterestBand;
    }

    public static void handleLeadRoundRobinReassignment(List<Lead> newLeadList, Map<Id, Lead> oldMap) {
        List<Lead> leadsToProcess = new List<Lead>();
        for (Lead lead : newLeadList) {
            System.debug('@LeadTriggerHandler handleLeadRoundRobinReassignment - lead.OwnerId: ' + lead.OwnerId);
            if (defaultLeadUserIdSet.contains(lead.OwnerId)) {
                leadsToProcess.add(lead);
            }
        }
        System.debug('@LeadTriggerHandler handleLeadRoundRobinReassignment - accountsToProcess.size: ' + leadsToProcess.size());
        System.debug('@LeadTriggerHandler handleLeadRoundRobinReassignment - accountsToProcess: ' + leadsToProcess);

        Map<Id, List<SObject>> userOwnedRecordsMap = new Map<Id, List<SObject>>();
        for (Lead lead : leadsToProcess) {
            List<SObject> leadsForMap = userOwnedRecordsMap.get(lead.OwnerId);
            if (leadsForMap == null) {
                leadsForMap = new List<SObject>();
                userOwnedRecordsMap.put(lead.OwnerId, leadsForMap);
            }    
            leadsForMap.add(lead);
        }

        if (!userOwnedRecordsMap.isEmpty()) {
            RoundRobinHandler.reassignRecords(userOwnedRecordsMap, null, null, leadsToProcess);
        }
    }
    
    /* START OF - Changes made by David Lovejoy - 09/11/21 - BPP-17997 */
    public static Boolean isLeadEligible (Lead oldLead, Lead newLead) {
        return (!oldLead.isConverted && newLead.isConverted && newLead.ConvertedAccountId != null);
    }
    
    public static void LeadConvertMapping (Lead newLead) {
        System.debug('@Entered LeadConvertMapping');
        Account account = [SELECT Id, Description, isPersonAccount FROM Account WHERE Id =: newLead.ConvertedAccountId];
        
        if (account.isPersonAccount) {
            System.debug('@LeadConvertMapping: Student Account: ' + account.isPersonAccount);
            List<Address__c> addressList = [SELECT Student__c FROM Address__c WHERE Lead__c =: newLead.Id];
            for (Address__c address: addressList){
                address.Student__c = newLead.ConvertedAccountId;
            }
            if (newLead.Birth_Date__c != null) { 
                account.PersonBirthdate = newLead.Birth_Date__c;
            }
            if (newLead.rfi_Are_you_EU_UK__c != null) {
                account.Student_Type__pc = (newLead.rfi_Are_you_EU_UK__c == 'UK Student' || newLead.rfi_Are_you_EU_UK__c == 'EU Student' ? 'Domestic' : 'International');
            }    
            if (newLead.Country_of_Residence__c != null) {
                Country_List__c countryList = [SELECT Id, Name FROM Country_List__c WHERE Id =: newLead.Country_of_Residence__c];
                account.Country_of_Residence__pc = countryList.Name;
            }
            update addressList;
            
            Database.DMLOptions dbDML = new Database.DMLOptions(); 
            dbDML.DuplicateRuleHeader.allowSave = true;
            Database.update(account, dbDML);
        }
    }
    /* END OF - Changes made by David Lovejoy */
}