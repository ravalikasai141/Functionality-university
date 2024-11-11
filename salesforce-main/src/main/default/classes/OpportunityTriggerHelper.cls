public with sharing class OpportunityTriggerHelper {
    /*private static Set<Id> defaultOpportunityUserIdSet = UserHelper.defaultAccountOpportunityUserIdSet();

    public static void populateDataByCourseInstance(List<Opportunity> opportunities) {
        List<Schema.PicklistEntry> plistValues = Opportunity.SFDC_Attribute_Code_Select__c.getDescribe().getPicklistValues();
        Set<Id> prodIds = new Set<Id>();
        List<Product2> products = new List<Product2>();

        if (opportunities != null && opportunities.size() > 0) {
            for (Opportunity opp : opportunities) {
                if (opp.Course_Instance__c != NULL) {
                    prodIds.add(opp.Course_Instance__c);
                }
            }

            if (prodIds.size() > 0) {
                products = [
                    SELECT Id, Name, Programme__c, Start_Date__c, Mode__c, Location__c, BNR_Campus_Code__c, BNR_Degree_Code__c, BNR_Level_Code__c,  BNR_Program_Code__c, BNR_Term_Code__c, BNR_Attribute_Code__c, BNR_Attribute_Code_2__c, BNR_Attribute_Code_3__c, BNR_Used_Capacity__c, BNR_Max_Capacity__c FROM Product2 
                    WHERE Id IN: prodIds AND Product_Type__c = 'OFFERING' AND IsActive = TRUE
                ];
            }

            for (Opportunity opportunity : opportunities) {
                if (opportunity.Record_Source__c == 'Salesforce') {
                    opportunity.SFDC_Admissions_ADMT_Code_Select__c = 'DI~ Direct';
                } 
                else if (opportunity.Record_Source__c == 'CAB') {
                    opportunity.SFDC_Admissions_ADMT_Code_Select__c = 'LC~ Law CABs';
                } 
                else if (opportunity.Record_Source__c == 'UCAS') {
                    opportunity.SFDC_Admissions_ADMT_Code_Select__c = '9~ UCAS';
                } 
                else if (opportunity.Record_Source__c == 'BPTC') {
                    opportunity.SFDC_Admissions_ADMT_Code_Select__c = 'MI~ Milkround';
                } 
                else if (opportunity.Record_Source__c == 'Direct Apps') {
                    opportunity.SFDC_Admissions_ADMT_Code_Select__c = 'DI~ Direct';
                }
                
                if (products.size() > 0) {
                    for (Product2 prod : products) {
                        if (opportunity.Course_Instance__c == prod.Id) {
                            opportunity.Programme_Application__c = (prod.Programme__c != NULL ? prod.Programme__c : NULL);
                            opportunity.Start_Date__c = (prod.Start_Date__c != NULL ? prod.Start_Date__c : NULL);
                            opportunity.Mode__c = (prod.Mode__c != NULL ? prod.Mode__c : NULL);
                            opportunity.Location__c = (prod.Location__c != NULL ? prod.Location__c : NULL);
                        }
                    }
                }
            }
        }
    }
    
    // Creates Product Catalog Item(s) for new Opportunities (when generated via ETL - Direct Apps/CAB)
    public static void populatePCIByCourseInstance(List<Opportunity> opportunities) {
        Integer count, countPciWithBundle, countPciWithoutBundle;
        Boolean checkOppProdExists = FALSE;
        Set<Id> prodIds = new Set<Id>();
        Set<ID> pciId = new Set<Id>();
        Set<Id> bundleIds = new Set<Id>();
        Map<Opportunity, Product2> opportunityProductMap = new Map<Opportunity, Product2>();
        Map<Product2, List<PC_Item__c>> productPciMap = new Map<Product2, List<PC_Item__c>>();
        Map<PC_Item__c, PC_Bundle__c> pciBundleMap = new Map<PC_Item__c, PC_Bundle__c>();
        List<Opportunity_Product__c> oppProdList = new List<Opportunity_Product__c>();
        List<Opportunity> oppList = new List<Opportunity>();
        
        // get related Product Ids
        for (Opportunity oppGet : opportunities) {
            if (oppGet.Course_Instance__c != NULL && (oppGet.Record_Source__c == 'Direct Apps' || oppGet.Record_Source__c == 'CAB' || oppGet.Record_Source__c == 'UCAS')) {
                prodIds.add(oppGet.Course_Instance__c);
                oppList.add(oppGet);
            }
        }
        
        if (prodIds.size() > 0) {
            // get Product details
            Map<Id, Product2> courseInstanceMap = new Map<Id, Product2>([SELECT Id, Name, Programme__c, Start_Date__c, Mode__c, Location__c, BNR_Campus_Code__c, BNR_Degree_Code__c, BNR_Level_Code__c,  
                                                                         BNR_Program_Code__c, BNR_Term_Code__c, BNR_Attribute_Code__c, BNR_Attribute_Code_2__c, BNR_Attribute_Code_3__c, BNR_Used_Capacity__c, BNR_Max_Capacity__c, IsActive FROM Product2 
                                                                         WHERE Id IN: prodIds AND Product_Type__c = 'OFFERING']);
            
            // add related Opportunity & Product to Map
            for (Opportunity opp : oppList) {
                opportunityProductMap.put(opp, courseInstanceMap.get(opp.Course_Instance__c));
            }
            
            // get related PC_Item__c's and add to Map (Product: List of PCI_Item__c's)
            List<PC_Item__c> pciList = [SELECT Id, Name, PC_Bundle__c, Item_Type__c, Product__c FROM PC_Item__c WHERE Product__c IN: prodIds];
            for (PC_Item__c pci : pciList) {
                for (Product2 prod : opportunityProductMap.values()) {
                    if (prod.IsActive) {
                        if (pci.Product__c == prod.Id && !pciId.contains(pci.Id)) {
                            if (productPciMap.containsKey(prod)) {
                                pciId.add(pci.Id);
                                List<PC_Item__c> lstPci = productPciMap.get(prod);
                                lstPci.add(pci);
                                productPciMap.put(prod, lstPci);
                            } else {
                                pciId.add(pci.Id);
                                productPciMap.put(prod, new List<PC_Item__c>{pci});
                            }
                        }
                    }
                }  
            }
            
            // get related Bundle Ids
            for (Product2 prod : productPciMap.keyset()) {
                for (PC_Item__c pci : productPciMap.get(prod)) {
                    bundleIds.add(pci.PC_Bundle__c);
                }
            }
            
            // create Opportunity_Product record for each PC_Item__c present in Bundle
            List<PC_Bundle__c> bundleList = [SELECT Id, Name, Description__c, BNR_Price__c, PC_Bundle_Full_Name__c, PC_Bundle_Id__c, (SELECT Id, Item_Type__c, Product__c FROM PC_Items__r) FROM PC_Bundle__c WHERE Id IN :bundleIds];
            for (Opportunity opp : opportunityProductMap.keyset()) {
                count = 0;
                countPciWithBundle = 0;
                countPciWithoutBundle = 0;
                Product2 p = opportunityProductMap.get(opp);
                
                if (opp.of_PC_Items__c > 0) {
                    checkOppProdExists = TRUE;
                }
                
                for (PC_Item__c pci : productPciMap.get(p)) {
                    if (pci.PC_Bundle__c != NULL) {
                        countPciWithBundle++;
                    } else {
                        countPciWithoutBundle++;
                    }
                }
                
                if (p.BNR_Used_Capacity__c != NULL || p.BNR_Max_Capacity__c != NULL) {
                    if (p.BNR_Used_Capacity__c < p.BNR_Max_Capacity__c) {
                        if (countPciWithBundle > 0) {
                            for (PC_Item__c pci : productPciMap.get(p)) {
                                if (pci.Product__c == p.Id && pci.PC_Bundle__c != NULL) {
                                    for (PC_Bundle__c pciB : bundleList) {
                                        if (pciB.Id == pci.PC_Bundle__c) {
                                            for (PC_Item__c pci_r: pciB.PC_Items__r) {
                                                count++;
                                                Opportunity_Product__c oppProd = new Opportunity_Product__c();
                                                oppProd.Opportunity__c = opp.Id;
                                                oppProd.Product__c = p.Id;
                                                oppProd.Bundle_Name__c = pciB.PC_Bundle_Full_Name__c;
                                                oppProd.Bundle_Id__c = pciB.PC_Bundle_Id__c;
                                                oppProd.Product__c = pci_r.Product__c;
                                                oppProd.Course_Focus__c = (pci_r.Item_Type__c == 'OFFERING' ? 'Primary' : NULL);
                                                if (checkOppProdExists) oppProd.Course_Focus__c = 'Secondary';
                                                else oppProd.Course_Focus__c = (pci_r.Item_Type__c == 'OFFERING' ? 'Primary' : NULL);
                                                
                                                oppProdList.add(oppProd);
                                            }
                                        }
                                    }
                                }
                            }
                        } else {
                            for (PC_Item__c pci : productPciMap.get(p)) {
                                count++;
                                Opportunity_Product__c oppProd = new Opportunity_Product__c();
                                oppProd.Opportunity__c = opp.Id;
                                oppProd.Product__c = p.Id;
                                if (checkOppProdExists) oppProd.Course_Focus__c = 'Secondary';
                                else oppProd.Course_Focus__c = (pci.Item_Type__c == 'OFFERING' ? 'Primary' : NULL);
                                
                                oppProdList.add(oppProd);
                                break;
                            }
                        }
                    } else {
                        System.debug('@@ Product over capacity - Product Catalog Item cannot be added for ' + opp.Id + ' @@');
                    }
                }  else {
                    System.debug('@@ Product Capacity fields are NULL (either BNR_Used_Capacity__c OR BNR_Max_Capacity__c) - Product Catalog Item cannot be added for ' + opp.Id + ' @@');
                }
            }
            
            // insert Opportunity_Product
            if (oppProdList.size() > 0) {
                try {
                    insert oppProdList;
                } catch (Exception e)  {
                    System.debug(e.getMessage());
                }
            }
        }
    }
    
    // Updates the name of student opportunities automatically. Handles instances where name exceeds standard field character limit	
    public static void populateOppName(List<Opportunity> opportunities) {
        String accountName, interestArea, mode, location, programName, opportunityName, programDate;
        Set<Id> oppIds = new Set<Id>();
        Set<Id> accIds = new Set<Id>();
        Set<Id> progIds = new Set<Id>();
        List<Account> accounts = new List<Account>();
        List<Programme__c> programmes = new List<Programme__c>();
        Id rtApp = Schema.sObjectType.Opportunity.getRecordTypeInfosByName().get('Application').getRecordTypeId();
        Id rtInt = Schema.sObjectType.Opportunity.getRecordTypeInfosByName().get('Interest').getRecordTypeId();
        Id rtPE = Schema.sObjectType.Opportunity.getRecordTypeInfosByName().get('PE Booking').getRecordTypeId();
        
        for (Opportunity opp : opportunities) {
            oppIds.add(opp.Id);
            if (opp.AccountId != NULL) accIds.add(opp.AccountId);
            if (opp.Programme_Application__c != NULL) progIds.add(opp.Programme_Application__c);
        }
        
        if (accIds.size() > 0) accounts = [SELECT LastName, Name, IsPersonAccount FROM Account WHERE Id IN: accIds];
        if (progIds.size() > 0) programmes = [SELECT Name FROM Programme__c WHERE Id IN: progIds];
        
        for (Opportunity opportunity : opportunities) {
            if (opportunity.RecordTypeId == rtApp || opportunity.RecordTypeId == rtInt || opportunity.RecordTypeId == rtPE) {
                for (Account acc : accounts) {
                    if (opportunity.AccountId == acc.Id && acc.IsPersonAccount == TRUE) {
                        for (Programme__c prog : programmes) {
                            if (opportunity.Programme_Application__c == prog.Id) {
                                accountName = (acc.LastName != NULL ? acc.LastName : acc.Name);
                                programName = (prog.Name != NULL ? ' - ' + prog.Name : '');
                                interestArea = (opportunity.Interest_Area__c != NULL ? ' - ' + opportunity.Interest_Area__c : '');
                                location = (opportunity.Location__c != NULL ? ' - ' + opportunity.Location__c: '');
                                programDate = (opportunity.Start_Date__c != NULL ? ' - ' + string.valueOf(opportunity.Start_Date__c.year()) : '');
                                if (opportunity.Mode__c != NULL) {
                                    if (opportunity.Mode__c.contains('Full Time')) mode = ' - FT';
                                    else if (opportunity.Mode__c.contains('Part Time')) mode = ' - PT';
                                }
                                
                                // generate opportunity name using naming convention
                                if (mode != NULL) opportunityName = accountName + programName + interestArea + mode + location + programDate;
                                else opportunityName = accountName + programName + interestArea + location + programDate;
                                
                                // logic for if opp name exceeds the character limit
                                if (opportunityName.length() >= 120) {
                                    opportunity.Full_Name__c = opportunityName;				// populates custom field with full name
                                    opportunityName = opportunityName.substring(0, 120);    // trims opportunityName variable, cutting it off after 120 chars
                                    opportunity.Name = opportunityName;						// populates standard field with above
                                } else {
                                    opportunity.Name = opportunityName;
                                    opportunity.Full_Name__c = NULL;
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    public static void prePopulateRegistrationFields(List<Opportunity> opportunities) {
        Set<Id> accountIds = new Set<Id>();
        for (Opportunity opp : opportunities) {
            accountIds.add(opp.accountId);
        }
        Map<Id,Account> Accounts = new Map<Id,Account>([SELECT Id, Student_Type__pc FROM Account WHERE ID =: accountIds]);
        for (Opportunity opp : opportunities) {
            if (opp.StageName  == 'Application') {
                opp.Passport__c = opp.Passport__c != null ? opp.Passport__c :  'Outstanding';
                opp.Confirmation_of_Contact_Details__c = opp.Confirmation_of_Contact_Details__c != null ? opp.Confirmation_of_Contact_Details__c : 'Outstanding';
                String studentType  = (Accounts.get(opp.accountid) != null ? Accounts.get(opp.accountid).Student_Type__pc : null);
                if (studentType != null) {
                    if (studentType == 'Domestic') {  
                        opp.English_Language_Certificate__c = opp.English_Language_Certificate__c  != null ? opp.English_Language_Certificate__c  :  'Not Applicable';
                        opp.EU_Settlement_Evidence__c   = opp.EU_Settlement_Evidence__c  != null ? opp.EU_Settlement_Evidence__c  :  'Not Applicable';
                        opp.Visa_Confirmation__c   = opp.Visa_Confirmation__c  != null ? opp.Visa_Confirmation__c  :  'Not Applicable';
                        opp.BRP__c   = opp.BRP__c  != null ? opp.BRP__c  :  'Not Applicable';
                        opp.Stamped_Entry_Clearance__c   = opp.Stamped_Entry_Clearance__c  != null ? opp.Stamped_Entry_Clearance__c  :  'Not Applicable';
                    }
                    if (studentType == 'EU') {  
                        opp.English_Language_Certificate__c = opp.English_Language_Certificate__c  != null ? opp.English_Language_Certificate__c  :  'Outstanding';
                        opp.EU_Settlement_Evidence__c   = opp.EU_Settlement_Evidence__c  != null ? opp.EU_Settlement_Evidence__c  :  'Outstanding';
                        opp.Visa_Confirmation__c   = opp.Visa_Confirmation__c  != null ? opp.Visa_Confirmation__c  :  'Not Applicable';
                        opp.BRP__c   = opp.BRP__c  != null ? opp.BRP__c  :  'Not Applicable';
                        opp.Stamped_Entry_Clearance__c   = opp.Stamped_Entry_Clearance__c  != null ? opp.Stamped_Entry_Clearance__c  :  'Not Applicable';
                    }
                    if (studentType == 'International') {  
                        opp.English_Language_Certificate__c = opp.English_Language_Certificate__c  != null ? opp.English_Language_Certificate__c  :  'Outstanding';
                        opp.EU_Settlement_Evidence__c   = opp.EU_Settlement_Evidence__c  != null ? opp.EU_Settlement_Evidence__c  :  'Not Applicable';
                        opp.Visa_Confirmation__c   = opp.Visa_Confirmation__c  != null ? opp.Visa_Confirmation__c  :  'Outstanding';
                        opp.BRP__c   = opp.BRP__c  != null ? opp.BRP__c  :  'Outstanding';
                        opp.Stamped_Entry_Clearance__c   = opp.Stamped_Entry_Clearance__c  != null ? opp.Stamped_Entry_Clearance__c  :  'Outstanding';
                    }
                }
            }
        }
    }
	
    public static void populateRegistrationStatus(List<Opportunity> opportunities) {
        Id studentApplication = Schema.sObjectType.Opportunity.getRecordTypeInfosByName().get('Application').getRecordTypeId();
        Id studentLockedApplication = Schema.sObjectType.Opportunity.getRecordTypeInfosByName().get('Locked Application').getRecordTypeId();
        for (Opportunity opp : opportunities) {
            if (opp.RecordTypeId == studentApplication || opp.RecordTypeId == studentLockedApplication) {
                if (opp.Passport__c != NULL && opp.Degree_Transcript__c != NULL && opp.Degree_Certificate__c != NULL && opp.Proof_of_Exemptions__c != NULL &&                                                   
                    opp.Visa_Confirmation__c != NULL && opp.EU_Settlement_Evidence__c != NULL && opp.BCAT__c != NULL && opp.Inn_of_Court__c != NULL &&                                                 
                    opp.Certificate_of_Academic_Standing__c != NULL && opp.Faculty_Approval__c != NULL && opp.ACCA_Status_Report__c != NULL && opp.School_Leaving_Level_3_Certificate__c != NULL && 
                    opp.Highest_Qualification_Certificate__c != NULL && opp.Highest_Qualification_Transcript__c != NULL && opp.Confirmation_of_Contact_Details__c != NULL && 
                    opp.English_Language_Certificate__c != NULL && opp.BRP__c != NULL && opp.GDL_PGDL_Transcript__c != NULL && opp.Stamped_Entry_Clearance__c != NULL) {
                    if (opp.Passport__c  == 'Outstanding' || opp.Passport__c  == 'Incomplete' || opp.Degree_Transcript__c  == 'Outstanding' || 
                        opp.Degree_Transcript__c  == 'Incomplete' || opp.Degree_Certificate__c  == 'Outstanding' || opp.Degree_Certificate__c  == 'Incomplete' ||                                                                             
                        opp.Proof_of_Exemptions__c  == 'Outstanding' || opp.Proof_of_Exemptions__c  == 'Incomplete' || opp.Visa_Confirmation__c  == 'Outstanding' || 
                        opp.Visa_Confirmation__c  == 'Incomplete' || opp.EU_Settlement_Evidence__c  == 'Outstanding' || opp.EU_Settlement_Evidence__c  == 'Incomplete' ||                                                                            
                        opp.BCAT__c  == 'Outstanding' || opp.BCAT__c  == 'Incomplete' || opp.Inn_of_Court__c  == 'Outstanding' || opp.Inn_of_Court__c  == 'Incomplete' ||
                        opp.Certificate_of_Academic_Standing__c  == 'Outstanding' || opp.Certificate_of_Academic_Standing__c  == 'Incomplete' ||                                                                        
                        opp.Faculty_Approval__c  == 'Outstanding' || opp.Faculty_Approval__c  == 'Incomplete' || opp.ACCA_Status_Report__c  == 'Outstanding' || 
                        opp.ACCA_Status_Report__c  == 'Incomplete' || opp.School_Leaving_Level_3_Certificate__c  == 'Outstanding' || 
                        opp.School_Leaving_Level_3_Certificate__c  == 'Incomplete' || opp.Highest_Qualification_Certificate__c  == 'Outstanding' || 
                        opp.Highest_Qualification_Certificate__c  == 'Incomplete' || opp.Highest_Qualification_Transcript__c  == 'Outstanding' || 
                        opp.Highest_Qualification_Transcript__c  == 'Incomplete' || opp.Confirmation_of_Contact_Details__c  == 'Outstanding' || 
                        opp.Confirmation_of_Contact_Details__c  == 'Incomplete' || opp.English_Language_Certificate__c  == 'Outstanding' || 
                        opp.English_Language_Certificate__c  == 'Incomplete' || opp.BRP__c  == 'Outstanding' || opp.BRP__c  == 'Incomplete' ||                                                                                 
                        opp.GDL_PGDL_Transcript__c  == 'Outstanding' || opp.GDL_PGDL_Transcript__c  == 'Incomplete' || opp.Stamped_Entry_Clearance__c == 'Outstanding'  || 
                        opp.Stamped_Entry_Clearance__c == 'Incomplete') {
                        if (opp.Listed_documents_are_validated_enough__c) {
                            opp.Registration_Status__c = 'Validated - Temp Registered';
                        }
                        else { 
                            opp.Registration_Status__c = 'Outstanding';
                        }
                    } else if ((opp.Passport__c  == 'Validated' || opp.Passport__c  == 'Not Applicable') && 
                        (opp.Degree_Transcript__c  == 'Validated' || opp.Degree_Transcript__c  == 'Not Applicable') &&                                                                                
                        (opp.Degree_Certificate__c  == 'Validated' || opp.Degree_Certificate__c  == 'Not Applicable') &&                                                                              
                        (opp.Proof_of_Exemptions__c  == 'Validated' || opp.Proof_of_Exemptions__c  == 'Not Applicable') &&                                                                               
                        (opp.Visa_Confirmation__c  == 'Validated' || opp.Visa_Confirmation__c  == 'Not Applicable') &&                                                                                
                        (opp.EU_Settlement_Evidence__c  == 'Validated' || opp.EU_Settlement_Evidence__c  == 'Not Applicable') &&                                                                             
                        (opp.BCAT__c  == 'Validated' || opp.BCAT__c  == 'Not Applicable') &&  
                        (opp.Inn_of_Court__c  == 'Validated' || opp.Inn_of_Court__c  == 'Not Applicable') &&      
                        (opp.Certificate_of_Academic_Standing__c  == 'Validated' || opp.Certificate_of_Academic_Standing__c  == 'Not Applicable') &&                                                                         
                        (opp.Faculty_Approval__c  == 'Validated' || opp.Faculty_Approval__c  == 'Not Applicable') &&                                                                            
                        (opp.ACCA_Status_Report__c  == 'Validated' || opp.ACCA_Status_Report__c  == 'Not Applicable') &&                                                                         
                        (opp.School_Leaving_Level_3_Certificate__c  == 'Validated' || opp.School_Leaving_Level_3_Certificate__c  == 'Not Applicable') &&      
                        (opp.Highest_Qualification_Certificate__c  == 'Validated' || opp.Highest_Qualification_Certificate__c  == 'Not Applicable') &&                                                                                
                        (opp.Highest_Qualification_Transcript__c  == 'Validated' || opp.Highest_Qualification_Transcript__c  == 'Not Applicable') &&                                                                               
                        (opp.Confirmation_of_Contact_Details__c  == 'Validated' || opp.Confirmation_of_Contact_Details__c  == 'Not Applicable') &&                                                                                
                        (opp.English_Language_Certificate__c  == 'Validated' ||   opp.English_Language_Certificate__c  == 'Not Applicable') &&                                                                             
                        (opp.BRP__c  == 'Validated' || opp.BRP__c  == 'Not Applicable') && 
                        (opp.GDL_PGDL_Transcript__c  == 'Validated' || opp.GDL_PGDL_Transcript__c  == 'Not Applicable') &&                                                                             
                        (opp.Stamped_Entry_Clearance__c == 'Validated'  ||   opp.Stamped_Entry_Clearance__c == 'Not Applicable')) {
                        opp.Registration_Status__c = 'Validated';
                        opp.Listed_documents_are_validated_enough__c = False ;
                    } else {
                        opp.Registration_Status__c = 'Submitted';      
                    }
                } else if (opp.Listed_documents_are_validated_enough__c) {
                    opp.Registration_Status__c = 'Validated - Temp Registered';
                }
                else {
                    opp.Registration_Status__c = 'Not Reviewed';
                }
            }
        }
    }
   
    public static void handleOpportunityRoundRobinReassignment(List<Opportunity> newOpportunitiesList, Map<Id, Opportunity> oldMap, String context) {
        List<Opportunity> opportunitiesToProcess = new List<Opportunity>();
        Set<Id> accountIds = new Set<Id>();
        for (Opportunity opportunity : newOpportunitiesList) {
            accountIds.add(opportunity.AccountId);
        }
        Map<Id, Account> accountMap = new Map<Id, Account>([SELECT Id, OwnerId FROM Account WHERE Id IN: accountIds]);

        for (Opportunity opportunity : newOpportunitiesList) {
            System.debug('@OpportunityTriggerHelper handleOpportunityRoundRobinReassignment - opportunity.OwnerId: ' + opportunity.OwnerId);
            if (context == 'insert' && defaultOpportunityUserIdSet.contains(opportunity.OwnerId)) {
                opportunitiesToProcess.add(opportunity);
            }
            if (context == 'update') {
                if (defaultOpportunityUserIdSet.contains(oldMap.get(opportunity.Id).OwnerId) && defaultOpportunityUserIdSet.contains(opportunity.OwnerId) && opportunity.LeadSource != null) {
                    Account account = accountMap.get(opportunity.AccountId);
                    if (account != null && !defaultOpportunityUserIdSet.contains(account.OwnerId)) {
                        opportunity.OwnerId = account.OwnerId;
                    }
                } else if (!defaultOpportunityUserIdSet.contains(oldMap.get(opportunity.Id).OwnerId) && defaultOpportunityUserIdSet.contains(opportunity.OwnerId)) {
                    opportunitiesToProcess.add(opportunity);
                }
            }
        }
        System.debug('@OpportunityTriggerHelper handleOpportunityRoundRobinReassignment - opportunitiesToProcess.size: ' + opportunitiesToProcess.size());
        System.debug('@OpportunityTriggerHelper handleOpportunityRoundRobinReassignment - opportunitiesToProcess: ' + opportunitiesToProcess);

        Map<Id, List<SObject>> userOwnedRecordsMap = new Map<Id, List<SObject>>();
        for (Opportunity opportunity : opportunitiesToProcess) {
            List<SObject> opportunitiesForMap = userOwnedRecordsMap.get(opportunity.OwnerId);
            if (opportunitiesForMap == null) {
                opportunitiesForMap = new List<SObject>();
                userOwnedRecordsMap.put(opportunity.OwnerId, opportunitiesForMap);
            }    
            opportunitiesForMap.add(opportunity);
        }

        if (!userOwnedRecordsMap.isEmpty()) {
            System.debug('@OpportunityTriggerHelper handleAccountRoundRobinReassignment - context: ' + context);
            RoundRobinHandler.reassignRecords(userOwnedRecordsMap, null, opportunitiesToProcess, null);
        }
    }

    public static void populateHESAStudentID(List<Opportunity> opportunityList) {
        Set<String> validStatuses = new Set<String>{
            'Accepted - Pmt Received'//, 'Accepted - Conditional Firm', 'Accepted - Conditional Insurance', 'Accepted - Unconditional Firm', 'Accepted - Unconditional Insurance', 'Closed Won', 'Complete'
        };
        Set<Id> accountIds = new Set<Id>();
        Set<Id> programmeIds = new Set<Id>();
        Map<Id, Account> accountMap;
        Map<Id, Programme__c> programmeMap;
        List<Opportunity> eligibileOpportunityList = new List<Opportunity>();

        for (Opportunity opportunity : opportunityList) {
            if (opportunity.Start_Date__c != null && validStatuses.contains(opportunity.StageName) && opportunity.Programme_Application__c != null &&
                opportunity.RecordTypeId == Schema.Sobjecttype.Opportunity.getRecordTypeInfosByName().get('Application').getRecordTypeId()) {
                accountIds.add(opportunity.AccountId);
                programmeIds.add(opportunity.Programme_Application__c);
                eligibileOpportunityList.add(opportunity);
            }
        }

        if (accountIds.size() > 0) {
            accountMap = new Map<Id, Account>([SELECT Id, BPP_Account_Number__c FROM Account WHERE Id IN: accountIds AND HESA_Student_ID_SID__c = null]);
        }
        if (programmeIds.size() > 0) {
            programmeMap = new Map<Id, Programme__c>([SELECT Id, Institute__r.Institution_Code__c FROM Programme__c WHERE Id IN: programmeIds AND Institute__r.Institution_Code__c != null]);
        }

        if ((accountMap != null && !accountMap.isEmpty()) && (programmeMap != null && !programmeMap.isEmpty())) {
            List<Account> accountList = new List<Account>();
            for (Opportunity opportunity : eligibileOpportunityList) {
                Account account = accountMap.get(opportunity.AccountId);
                Programme__c programme = programmeMap.get(opportunity.Programme_Application__c);

                if (account == null || programme == null) {
                    continue;
                }

                account.HESA_Student_ID_SID__c = generateHESAStudentID(opportunity, account, programme);
                accountList.add(account);
            }
            if (accountList.size() > 0) {
                update accountList;
            }
        }
    }

    public static String generateHESAStudentID(Opportunity opportunity, Account account, Programme__c programme) {
        String HESAStudentID = String.valueOf(opportunity.Start_Date__c.year()).right(2);
        HESAStudentID += programme.Institute__r.Institution_Code__c;
        HESAStudentID += account.BPP_Account_Number__c.right(6);
        System.debug('@generateHESAStudentID HESAStudentID 16 digit value: ' + HESAStudentID);
        HESAStudentID += generateHESASIDLastDigit(HESAStudentID);
        return HESAStudentID;
    }

    public static Map<Integer, Integer> createHESAWeightMap() {
        return new Map<Integer, Integer>{
            1 => 1, 2 => 3, 3 => 7, 4 => 9, 5 => 1, 6 => 3, 7 => 7, 8 => 9, 9 => 1, 10 => 3, 11 => 7, 12 => 9, 13 => 1, 14 => 3, 15 => 7, 16 => 9
        };
    }

    public static Integer generateHESASIDLastDigit(String HESAStudentID) {
        Map<Integer, Integer> hesaWeightMap = createHESAWeightMap();
        Integer sIDSum = 0;

        for (Integer i = 0; i < HESAStudentID.length(); i++) {
            Integer sID = Integer.valueOf(HESAStudentID.substring(i, i + 1));
            sID = sID * hesaWeightMap.get(i + 1);
            sIDSum += sID;
        }

        String sIDSumString = String.valueOf(sIDSum);
        Integer sIDLastDigit = Integer.valueOf(sIDSumString.right(1));
        return (sIDLastDigit > 0 ? (10 - sIDLastDigit) : 0);
    }
    
   public static void checkForCAS_EmailAutomation(List<Opportunity> newOpportunitiesList, List<Opportunity> oldOpportunitiesList) {
        if(newOpportunitiesList.size()==1){
            List<Account> accountrecords = new List<Account>();
            String Emailtogo='';
            System.debug('@@Inside CheckForCAS_EmailAutomation@@Trigger.old: '+ oldOpportunitiesList[0].CAS_status__c);
            System.debug('@@Inside CheckForCAS_EmailAutomation@@Trigger.new: '+ newOpportunitiesList[0].CAS_status__c);
            Opportunity oldOpportunityRecord = oldOpportunitiesList[0];
            Opportunity newOpportunityRecord = newOpportunitiesList[0];
            accountrecords = [Select id, FirstName,Name,PersonBirthdate,PersonEmail from Account where id =:newOpportunityRecord.AccountId];
            System.debug(accountrecords[0].PersonEmail);
            Emailtogo = accountrecords[0].PersonEmail;
            System.debug('@@newOpportunitiesList.CAS_Letter_Sent__c@@'+newOpportunityRecord.CAS_Letter_Sent__c);
            System.debug('@@newOpportunitiesList.CAS_status__c@@'+newOpportunityRecord.CAS_status__c);
            System.debug('Record type Id: '+newOpportunityRecord.RecordTypeId);
            
            //Get Rcordtype Ids
            String OppoApplicationRecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Application').getRecordTypeId();
            String OppoLockedApplicationRecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Locked Application').getRecordTypeId();
            System.debug('@@Application RecordType ID@@'+OppoApplicationRecordTypeId);
            System.debug('@@Locked Application RecordType ID@@'+OppoLockedApplicationRecordTypeId);
            
            //CAS PDF attachment
            if(newOpportunityRecord.RecordTypeId == OppoApplicationRecordTypeId || newOpportunityRecord.RecordTypeId == OppoLockedApplicationRecordTypeId){
                if(newOpportunityRecord.CAS_status__c == 'Issued' && oldOpportunityRecord.CAS_status__c != 'Issued' && !newOpportunityRecord.CAS_Letter_Sent__c){
                System.debug('@@Inside if for CAS PDF@@');
                SendCASAutoReply.sendEmailWithPDfAttachment(newOpportunityRecord.id,accountrecords[0].Name,newOpportunityRecord.CAS_status__c,Emailtogo);
            	}
            }
        }   
    }
    */
}