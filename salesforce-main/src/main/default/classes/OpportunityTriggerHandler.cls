public with sharing class OpportunityTriggerHandler {
    private static Set<Id> defaultOpportunityUserIdSet = UserHelper.defaultAccountOpportunityUserIdSet();
    private static Id apprenticeApplicationRT = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName()
        .get('Apprentice_Application')
        .getRecordTypeId();
    private static Id trainingManagerRTId = Schema.SObjectType.Contact.getRecordTypeInfosByName()
        .get('Training Manager')
        .getRecordTypeId();

    private static final List<String> FIELDS_TO_RETAIN_ON_WITHDRAWAL = new List<String>{
        'StageName',
        'BPP_Sub_Status__c',
        'BPP_Cancellation_Reason__c',
        'Application_ID__c',
        'Name',
        'AccountId',
        'CloseDate',
        'RecordTypeId',
        'OwnerId'
    };

    /**
     * Creates student courses where they dont already exist and
     * the opp satisfies the criteria
     * @param opps List of opportunities to create courses with
     */
    public static void createStudentCourses(Map<Id, Opportunity> opps) {
        Set<Id> createdCourses = new Set<Id>();
        List<Student_Course__c> toCreate = new List<Student_Course__c>();

        Set<String> stageNames = new Set<String>{
            'Accepted - Pmt Received',
            'Accepted - Conditional Firm',
            'Accepted - Unconditional Firm',
            'Degree Apprenticeship'
        };

        Set<Id> rtIds = new Set<Id>{
            Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Application').getRecordTypeId(),
            Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Locked Application').getRecordTypeId()
        };

        for (Student_Course__c course : [
            SELECT Opportunity__c
            FROM Student_Course__c
            WHERE Opportunity__c IN :opps.keySet()
        ]) {
            createdCourses.add(course.Opportunity__c);
        }

        for (Opportunity opp : opps.values()) {
            if (
                createdCourses.contains(opp.Id) ||
                !rtIds.contains(opp.RecordTypeId) ||
                opp.Course_Instance__c == null ||
                !stageNames.contains(opp.StageName)
            ) {
                continue;
            }

            toCreate.add(new Student_Course__c(Student__c = opp.AccountId, Opportunity__c = opp.Id));
        }

        if (!toCreate.isEmpty()) {
            insert toCreate;
        }
    }

    /**
     * Deletes student courses related to deleted opportunities
     * @param opps Map of deleted opps
     */
    public static void deleteCourses(Map<Id, Opportunity> opps) {
        List<Student_Course__c> toDelete = [SELECT Id FROM Student_Course__c WHERE Opportunity__c IN :opps.keySet()];

        if (!toDelete.isEmpty()) {
            delete toDelete;
        }
    }

    /**
     * Handles to pre-populate Account fields when Apprentice Application reaches 'Acceptance Complete' stage
     * @param  newOpportunitiesList List of Opportunities that have changed
     * @param oldOpps Map of old opportunities
     */
    public static void populateStudentAccountFields(
        List<Opportunity> newOpportunitiesList,
        Map<Id, Opportunity> oldOpps
    ) {
        Set<Id> accountsToUpdate = new Set<Id>();
        List<Account> updateStudentAccountFields = new List<Account>();

        for (Opportunity newOpportunity : newOpportunitiesList) {
            if (
                newOpportunity.RecordTypeId == apprenticeApplicationRT &&
                (newOpportunity.StageName == 'Acceptance' &&
                newOpportunity.BPP_Sub_Status__c == 'Completed' &&
                oldOpps.get(newOpportunity.Id).BPP_Sub_Status__c != 'Completed')
            ) {
                accountsToUpdate.add(newOpportunity.AccountId);
            }
        }

        if (accountsToUpdate.isEmpty()) {
            return;
        }

        for (Account accounts : [
            SELECT Id, Account_Tax_Category__c, Student_Type__pc, Billing_Type__c
            FROM Account
            WHERE
                Id IN :accountsToUpdate
                AND (Account_Tax_Category__c = NULL
                OR Student_Type__pc = NULL
                OR Billing_Type__c = NULL)
        ]) {
            accounts.Account_Tax_Category__c = (accounts.Account_Tax_Category__c == null)
                ? 'Domestic Customer'
                : accounts.Account_Tax_Category__c;
            accounts.Student_Type__pc = (accounts.Student_Type__pc == null) ? 'Domestic' : accounts.Student_Type__pc;
            accounts.Billing_Type__c = (accounts.Billing_Type__c == null) ? 'In Advance' : accounts.Billing_Type__c;
            updateStudentAccountFields.add(accounts);
        }

        if (!updateStudentAccountFields.isEmpty()) {
            update updateStudentAccountFields;
        }
    }

    /**
     * Creates line items for opportunities created with product id or where
     * the product id changes from null to a product
     * @param opps List of opportunities changed to created
     * @param oldMap List of previous values for opps
     */
    public static void generateLineItems(Map<Id, Opportunity> opps, Map<Id, Opportunity> oldMap) {
        List<OpportunityLineItem> lineItems = new List<OpportunityLineItem>();
        Map<Id, PricebookEntry> productToPricebook = new Map<Id, PricebookEntry>();
        Map<Id, Id> oppsToProducts = new Map<Id, Id>();

        for (Opportunity opp : opps.values()) {
            if (opp.RecordTypeId == apprenticeApplicationRT && opp.Course_Instance__c != null) {
                if (oldMap.containsKey(opp.Id) && oldMap.get(opp.Id).Course_Instance__c != null) {
                    continue;
                }

                oppsToProducts.put(opp.Id, opp.Course_Instance__c);
            }
        }

        for (PricebookEntry entry : [
            SELECT Id, UnitPrice, Product2Id
            FROM PricebookEntry
            WHERE Product2Id IN :oppsToProducts.values() AND IsActive = TRUE
        ]) {
            productToPricebook.put(entry.Product2Id, entry);
        }

        for (Id oppId : oppsToProducts.keySet()) {
            PricebookEntry entry = productToPricebook.get(oppsToProducts.get(oppId));

            if (entry == null) {
                continue;
            }

            lineItems.add(
                new OpportunityLineItem(
                    OpportunityId = oppId,
                    Product2Id = oppsToProducts.get(oppId),
                    PricebookEntryId = entry.Id,
                    UnitPrice = entry.UnitPrice,
                    Quantity = 1
                )
            );
        }

        if (!lineItems.isEmpty()) {
            insert lineItems;
        }
    }

    /**
     * Attempts to relate a contact to an Opportunity using the
     * Line Manager email field if its set. This will only relate
     * the contact if a single contact exists with the exact email
     * address match.
     * @param List<Opportunity> list of opportunities
     */
    public static void relateLineManager(List<Opportunity> opps, Map<Id, Opportunity> oldMap) {
        Set<String> lineManagerEmails = new Set<String>();
        Set<Id> lineManagerIds = new Set<Id>();
        Map<String, Contact> emailToContact = new Map<String, Contact>();
        Map<String, Contact> idToContact = new Map<String, Contact>();

        // If line manager email or line manager is set
        for (Opportunity opp : opps) {
            Opportunity oldOpp = oldMap?.get(opp.Id);
            if (
                oldOpp == null &&
                opp.Line_Manager__c != null ||
                oldOpp != null &&
                oldOpp.Line_Manager__c != opp.Line_Manager__c
            ) {
                lineManagerIds.add(opp.Line_Manager__c);
            } else if (
                oldOpp == null &&
                opp.Line_Manager_Email__c != null ||
                oldOpp != null &&
                oldOpp.Line_Manager_Email__c != opp.Line_Manager_Email__c
            ) {
                lineManagerEmails.add(opp.Line_Manager_Email__c);
            }
        }

        if (lineManagerEmails.isEmpty() && lineManagerIds.isEmpty()) {
            return;
        }

        for (Contact contact : [
            SELECT Id, Email, AccountId
            FROM Contact
            WHERE
                (Email IN :lineManagerEmails
                OR Id IN :lineManagerIds)
                AND IsPersonAccount = FALSE
                AND RecordTypeId = :trainingManagerRTId
        ]) {
            if (lineManagerIds.contains(contact.Id)) {
                idToContact.put(contact.Id, contact);

                // Only set line manager if single contact exists
            } else if (emailToContact.containsKey(contact.Email)) {
                emailToContact.remove(contact.Email);
            } else {
                emailToContact.put(contact.Email, contact);
            }
        }

        for (Opportunity opp : opps) {
            Contact lineManagerContact;
            if (lineManagerIds.contains(opp.Line_Manager__c) && idToContact.containsKey(opp.Line_Manager__c)) {
                lineManagerContact = idToContact.get(opp.Line_Manager__c);
                opp.Client__c = lineManagerContact.AccountId;
            } else if (emailToContact.containsKey(opp.Line_Manager_Email__c) && opp.Line_Manager__c == null) {
                lineManagerContact = emailToContact.get(opp.Line_Manager_Email__c);
                opp.Line_Manager__c = lineManagerContact.Id;
                opp.Client__c = lineManagerContact.AccountId;
            }
        }
    }

    /**
     * Adds company address data to other address fields on the opportunity
     * only for Apprentice Applications
     * @param opps List of opportunities that have been updated or inserted
     */
    public static void updateApprenticeApplicationAddress(List<Opportunity> opps) {
        Set<Id> countries = new Set<Id>();
        List<Opportunity> apprenticeOpps = new List<Opportunity>();

        for (Opportunity opp : opps) {
            if (opp.RecordTypeId == apprenticeApplicationRT) {
                if (
                    !String.isEmpty(opp.Company_Lookup_Country__c) && !countries.contains(opp.Company_Lookup_Country__c)
                ) {
                    countries.add(opp.Company_Lookup_Country__c);
                }

                apprenticeOpps.add(opp);
            }
        }

        Map<Id, String> countryNames = new Map<Id, String>();
        for (Country_List__c country : [SELECT Id, Name FROM Country_List__c WHERE Id IN :countries]) {
            countryNames.put(country.Id, country.Name);
        }

        for (Opportunity opp : apprenticeOpps) {
            List<String> lines = new List<String>();

            if (!String.isEmpty(opp.Company_Street_1__c)) {
                lines.add(opp.Company_Street_1__c);
            }

            if (!String.isEmpty(opp.Company_Street_2__c)) {
                lines.add(opp.Company_Street_2__c);
            }

            if (!String.isEmpty(opp.Company_Street_3__c)) {
                lines.add(opp.Company_Street_3__c);
            }

            opp.Street_Address__c = String.join(lines, ', ');
            opp.City__c = opp.Company_City__c;
            opp.Postal_Code__c = opp.Company_Zip_Postal_Code__c;

            if (countryNames.containsKey(opp.Company_Lookup_Country__c)) {
                opp.Country__c = countryNames.get(opp.Company_Lookup_Country__c);
            }
        }
    }

    /**
     * Updates the name of the Opportunity when any relevant fields have changed
     * @param newOpps  List of opportunities changed or created
     * @param oldMap   List of previous values for opps
     */
    public static void updateOpportunityName(List<Opportunity> newOpps, Map<Id, Opportunity> oldMap) {
        // Identify any Opportunities that are either new or have had their Course Instance changed
        List<Id> opportunitiesToUpdate = new List<Id>();
        for (Opportunity currentOpp : newOpps) {
            if (
                currentOpp.RecordTypeId == apprenticeApplicationRT &&
                (oldMap?.get(currentOpp.Id) == null ||
                oldMap.get(currentOpp.Id).Course_Instance__c != currentOpp.Course_Instance__c)
            ) {
                opportunitiesToUpdate.add(currentOpp.Id);
            }
        }

        if (opportunitiesToUpdate.isEmpty()) {
            return;
        }

        List<Opportunity> oppsToUpdate = [
            SELECT
                Id,
                Start_Date__c,
                End_Date__c,
                Account.LastName,
                Course_Instance__r.Start_Date__c,
                Course_Instance__r.End_Date__c,
                Course_Instance__r.Programme__r.Name,
                Course_Instance__r.Location__c
            FROM Opportunity
            WHERE Id IN :opportunitiesToUpdate
        ];

        // Loop over all identified Opportunities and update the Opportunity names
        for (Opportunity currentOpp : oppsToUpdate) {
            List<String> nameSegments = new List<String>{ currentOpp.Account.LastName };

            // If available, include the Products Programme name in the Opportunity Name
            String programmeName = currentOpp.Course_Instance__r?.Programme__r?.Name;
            if (programmeName != null) {
                nameSegments.add(programmeName);
            }

            // If available, include the Products Location in the Opportunity Name
            String productLocation = currentOpp.Course_Instance__r?.Location__c;
            if (productLocation != null) {
                nameSegments.add(productLocation);
            }

            // Set the Opportunities Start_Date__c to the Products start date if one is available and is not already set. Then use it to update the Opportunity Name
            if (currentOpp.Course_Instance__r.Start_Date__c != null) {
                if (currentOpp.Start_Date__c == null) {
                    currentOpp.Start_Date__c = currentOpp.Course_Instance__r.Start_Date__c;
                }

                nameSegments.add(String.valueOf(currentOpp.Start_Date__c.year()));
            }

            String oppName = String.join(nameSegments, ' - ');
            Boolean trimOppName = oppName.length() > 120;

            currentOpp.Name = trimOppName ? oppName.substring(0, 120) : oppName;
            currentOpp.Full_Name__c = trimOppName ? oppName : null;

            // Set End_Date__c to the Products end date if one is not already set
            if (currentOpp.Course_Instance__r.End_Date__c != null && currentOpp.End_Date__c == null) {
                currentOpp.End_Date__c = currentOpp.Course_Instance__r.End_Date__c;
            }
        }

        update oppsToUpdate;
    }

    /**
     * Manages any old Weekly Contracted Hours values when field is updated during Line Manager Review
     * @param newOppsList List of updated Opportunities
     * @param oldOppsMap Map of old opportunities by their Id
     */
    public static void handleOldWeeklyContractedHours(List<Opportunity> newOppsList, Map<Id, Opportunity> oldOppsMap) {
        for (Opportunity newOpp : newOppsList) {
            Opportunity oldOpp = oldOppsMap.get(newOpp.Id);

            // If the Weekly Contract Hours have been set back to the original value, blank the field out
            if (newOpp.Old_Weekly_Contracted_Hours__c == newOpp.Weekly_Contracted_Hours_Apprentice__c) {
                newOpp.Old_Weekly_Contracted_Hours__c = null;
                continue;
            }

            if (newOpp.StageName == 'Line Manager Review') {
                // Reset the Old Weekly Contracted hours field when the Opportunity is moved into Line Manager Review
                if (oldOpp.StageName != 'Line Manager Review') {
                    newOpp.Old_Weekly_Contracted_Hours__c = null;
                    continue;
                }

                // On the first instance of the Weekly Contracted Hours changing after entering Line Manager Review, store the old value
                if (
                    newOpp.Weekly_Contracted_Hours_Apprentice__c != oldOpp.Weekly_Contracted_Hours_Apprentice__c &&
                    newOpp.Old_Weekly_Contracted_Hours__c == null
                ) {
                    newOpp.Old_Weekly_Contracted_Hours__c = oldOpp.Weekly_Contracted_Hours_Apprentice__c;
                }
            }
        }
    }

    /**
     * Clears out any none required fields when an Opportunity is withdrawn
     * @param newOppsList List of updated Opportunities
     * @param oldOppsMap Map of old opportunities by their Id
     */
    public static void handleOpportunityWithdrawals(List<Opportunity> newOppsList, Map<Id, Opportunity> oldOppsMap) {
        Map<String, SObjectField> opportunityFieldsMap = Opportunity.sObjectType.getDescribe().fields.getMap();

        for (Opportunity newOpp : newOppsList) {
            Opportunity oldOpp = oldOppsMap.get(newOpp.Id);
            if (
                newOpp.StageName == 'Closed Lost' &&
                oldOpp.StageName != 'Closed Lost' &&
                newOpp.BPP_Sub_Status__c == 'Withdrawn' &&
                oldOpp.BPP_Sub_Status__c != 'Withdrawn'
            ) {
                // Loop over all fields that have a value
                for (String currentField : newOpp.getPopulatedFieldsAsMap().keySet()) {
                    Schema.DescribeFieldResult fieldDescribe = opportunityFieldsMap.get(currentField).getDescribe();
                    if (
                        !FIELDS_TO_RETAIN_ON_WITHDRAWAL.contains(currentField) &&
                        !currentField.contains('__r') &&
                        fieldDescribe.isUpdateable() &&
                        !fieldDescribe.isCalculated()
                    ) {
                        newOpp.put(currentField, fieldDescribe.getDefaultValue());
                    }
                }
            }
        }
    }

    public static void populateDataByCourseInstance(
        List<Opportunity> opportunities,
        Map<Id, Opportunity> oldOpportunities
    ) {
        List<Schema.PicklistEntry> plistValues = Opportunity.SFDC_Attribute_Code_Select__c.getDescribe()
            .getPicklistValues();
        Set<Id> prodIds = new Set<Id>();
        List<Product2> products = new List<Product2>();
        Id apprenticeAppRTID = Schema.sObjectType.Opportunity.getRecordTypeInfosByDeveloperName()
            .get('Apprentice_Application')
            .getRecordTypeId();

        if (opportunities != null && opportunities.size() > 0) {
            for (Opportunity opp : opportunities) {
                if (opp.Course_Instance__c != null) {
                    prodIds.add(opp.Course_Instance__c);
                }
            }

            if (prodIds.size() > 0) {
                products = [
                    SELECT
                        Id,
                        Name,
                        Programme__c,
                        Start_Date__c,
                        End_Date__c,
                        Mode__c,
                        Location__c,
                        Level__c,
                        BNR_Campus_Code__c,
                        BNR_Degree_Code__c,
                        BNR_Level_Code__c,
                        BNR_Program_Code__c,
                        BNR_Term_Code__c,
                        BNR_Attribute_Code__c,
                        BNR_Attribute_Code_2__c,
                        BNR_Attribute_Code_3__c,
                        BNR_Used_Capacity__c,
                        BNR_Max_Capacity__c,
                        Platform__c
                    FROM Product2
                    WHERE Id IN :prodIds AND Product_Type__c = 'OFFERING' AND IsActive = TRUE
                ];
            }

            for (Opportunity opportunity : opportunities) {
                Opportunity oldOpp = oldOpportunities?.get(opportunity.Id);
                if (opportunity.Record_Source__c == 'Salesforce') {
                    opportunity.SFDC_Admissions_ADMT_Code_Select__c = 'DI~ Direct';
                } else if (opportunity.Record_Source__c == 'CAB') {
                    opportunity.SFDC_Admissions_ADMT_Code_Select__c = 'LC~ Law CABs';
                } else if (opportunity.Record_Source__c == 'UCAS') {
                    opportunity.SFDC_Admissions_ADMT_Code_Select__c = '9~ UCAS';
                } else if (opportunity.Record_Source__c == 'BPTC') {
                    opportunity.SFDC_Admissions_ADMT_Code_Select__c = 'MI~ Milkround';
                } else if (opportunity.Record_Source__c == 'Direct Apps') {
                    opportunity.SFDC_Admissions_ADMT_Code_Select__c = 'DI~ Direct';
                }

                if (products.size() > 0) {
                    for (Product2 prod : products) {
                        if (opportunity.Course_Instance__c == prod.Id) {
                            if (opportunity.RecordTypeId != apprenticeAppRTID) {
                                opportunity.Start_Date__c = (prod.Start_Date__c != null ? prod.Start_Date__c : null);
                                opportunity.Product_Level__c = (prod.Level__c != null ? prod.Level__c : null);
                            }
                            opportunity.Mode__c = (prod.Mode__c != null ? prod.Mode__c : null);
                            opportunity.Location__c = (prod.Location__c != null ? prod.Location__c : null);
                            opportunity.Programme_Application__c = (prod.Programme__c != null
                                ? prod.Programme__c
                                : null);
                            // Check if course has changed to update start/end date from product
                            if (
                                (oldOpp == null || opportunity.Course_Instance__c != oldOpp.Course_Instance__c) &&
                                opportunity.RecordTypeId == apprenticeAppRTID
                            ) {
                                if (oldOpp != null || (oldOpp == null && opportunity.Start_Date__c == null)) {
                                    opportunity.Start_Date__c = prod.Start_Date__c;
                                }

                                if (oldOpp != null || (oldOpp == null && opportunity.End_Date__c == null)) {
                                    opportunity.End_Date__c = prod.End_Date__c;
                                }

                                // This should not overwrite if the opp is new and the preserved value exists
                                if (oldOpp != null || (oldOpp == null && opportunity.OOTJTH_Preserved__c == null)) {
                                    opportunity.OOTJTH_Preserved__c = opportunity.OOTJTH_Calculated__c;
                                }
                            }
                            //opportunity.Provisioning_Method__c = (prod.Platform__c != NULL ? prod.Platform__c : NULL);
                        }
                    }
                }
            }
        }
    }

    /**
     * Update Application History so extra fields can be shown in history
     * @param  newOppsMap updated opp values
     * @param  oldMap  prior opp values
     */
    public static void populateApplicationHistory(List<Opportunity> newOpps, Map<Id, Opportunity> oldMap) {
        List<Application_History__c> historyToUpdate = new List<Application_History__c>();

        for (Opportunity opp : newOpps) {
            Opportunity oldOpp;

            if (oldMap != null) {
                oldOpp = oldMap.get(opp.Id);
            }
            if (
                opp.recordTypeId == apprenticeApplicationRT &&
                (oldOpp == null ||
                oldOpp.Company_Street_1__c != opp.Company_Street_1__c ||
                oldOpp.Line_Manager_Email__c != opp.Line_Manager_Email__c ||
                oldOpp.Company_Street_2__c != opp.Company_Street_2__c ||
                oldOpp.Line_Manager_First_Name__c != opp.Line_Manager_First_Name__c ||
                oldOpp.Company_Street_3__c != opp.Company_Street_3__c ||
                oldOpp.Line_Manager_Job_Title__c != opp.Line_Manager_Job_Title__c ||
                oldOpp.Company_City__c != opp.Company_City__c ||
                oldOpp.Line_Manager_Last_Name__c != opp.Line_Manager_Last_Name__c ||
                oldOpp.Company_Lookup_Country__c != opp.Company_Lookup_Country__c ||
                oldOpp.Line_Manager_Telephone__c != opp.Line_Manager_Telephone__c ||
                oldOpp.Company_Zip_Postal_Code__c != opp.Company_Zip_Postal_Code__c ||
                oldOpp.Safety_Knowledge_Apprentice__c != opp.Safety_Knowledge_Apprentice__c ||
                oldOpp.Job_Description_Apprentice__c != opp.Job_Description_Apprentice__c ||
                oldOpp.Sponsoring_Organization__c != opp.Sponsoring_Organization__c ||
                oldOpp.Job_Started_On_Apprentice__c != opp.Job_Started_On_Apprentice__c ||
                oldOpp.Weekly_Contracted_Hours_Apprentice__c != opp.Weekly_Contracted_Hours_Apprentice__c ||
                oldOpp.Job_Title_Apprentice__c != opp.Job_Title_Apprentice__c)
            ) {
                Application_History__c history = new Application_History__c(
                    Company_Address_Line_1__c = opp.Company_Street_1__c,
                    Line_Manager_Email__c = opp.Line_Manager_Email__c,
                    Company_Address_Line_2__c = opp.Company_Street_2__c,
                    Line_Manager_First_Name__c = opp.Line_Manager_First_Name__c,
                    Company_Address_Line_3__c = opp.Company_Street_3__c,
                    Line_Manager_Job_Title__c = opp.Line_Manager_Job_Title__c,
                    Company_City__c = opp.Company_City__c,
                    Line_Manager_Last_Name__c = opp.Line_Manager_Last_Name__c,
                    Company_Country__c = opp.Company_Lookup_Country__c,
                    Line_Manager_Telephone__c = opp.Line_Manager_Telephone__c,
                    Company_Zip_Postal_Code__c = opp.Company_Zip_Postal_Code__c,
                    Safety_Knowledge__c = opp.Safety_Knowledge_Apprentice__c,
                    Job_Description__c = opp.Job_Description_Apprentice__c?.abbreviate(255),
                    Sponsoring_Organization__c = opp.Sponsoring_Organization__c,
                    Job_Started_On__c = opp.Job_Started_On_Apprentice__c,
                    Weekly_Contracted_Hours__c = opp.Weekly_Contracted_Hours_Apprentice__c,
                    Job_Title__c = opp.Job_Title_Apprentice__c,
                    Application_ID__c = opp.Application_ID__c,
                    Opportunity__c = opp.Id
                );

                historyToUpdate.add(history);
            }
        }

        if (historyToUpdate.isEmpty()) {
            return;
        }

        upsert historyToUpdate Application_ID__c;
    }

    // Creates Product Catalog Item(s) for new Opportunities (when generated via ETL - Direct Apps/CAB)
    public static void populatePCIByCourseInstance(List<Opportunity> opportunities) {
        Integer count, countPciWithBundle, countPciWithoutBundle;
        Boolean checkOppProdExists = false;
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
            if (
                oppGet.Course_Instance__c != null &&
                (oppGet.Record_Source__c == 'Direct Apps' ||
                oppGet.Record_Source__c == 'CAB' ||
                oppGet.Record_Source__c == 'UCAS')
            ) {
                prodIds.add(oppGet.Course_Instance__c);
                oppList.add(oppGet);
            }
        }

        if (prodIds.size() > 0) {
            // get Product details
            Map<Id, Product2> courseInstanceMap = new Map<Id, Product2>(
                [
                    SELECT
                        Id,
                        Name,
                        Programme__c,
                        Start_Date__c,
                        Mode__c,
                        Location__c,
                        BNR_Campus_Code__c,
                        BNR_Degree_Code__c,
                        BNR_Level_Code__c,
                        BNR_Program_Code__c,
                        BNR_Term_Code__c,
                        BNR_Attribute_Code__c,
                        BNR_Attribute_Code_2__c,
                        BNR_Attribute_Code_3__c,
                        BNR_Used_Capacity__c,
                        BNR_Max_Capacity__c,
                        IsActive
                    FROM Product2
                    WHERE Id IN :prodIds AND Product_Type__c = 'OFFERING'
                ]
            );

            // add related Opportunity & Product to Map
            for (Opportunity opp : oppList) {
                opportunityProductMap.put(opp, courseInstanceMap.get(opp.Course_Instance__c));
            }

            // get related PC_Item__c's and add to Map (Product: List of PCI_Item__c's)
            List<PC_Item__c> pciList = [
                SELECT Id, Name, PC_Bundle__c, Item_Type__c, Product__c
                FROM PC_Item__c
                WHERE Product__c IN :prodIds
            ];
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
                                productPciMap.put(prod, new List<PC_Item__c>{ pci });
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
            List<PC_Bundle__c> bundleList = [
                SELECT
                    Id,
                    Name,
                    Description__c,
                    BNR_Price__c,
                    PC_Bundle_Full_Name__c,
                    PC_Bundle_Id__c,
                    (SELECT Id, Item_Type__c, Product__c FROM PC_Items__r)
                FROM PC_Bundle__c
                WHERE Id IN :bundleIds
            ];
            for (Opportunity opp : opportunityProductMap.keyset()) {
                count = 0;
                countPciWithBundle = 0;
                countPciWithoutBundle = 0;
                Product2 p = opportunityProductMap.get(opp);

                if (opp.of_PC_Items__c > 0) {
                    checkOppProdExists = true;
                }

                for (PC_Item__c pci : productPciMap.get(p)) {
                    if (pci.PC_Bundle__c != null) {
                        countPciWithBundle++;
                    } else {
                        countPciWithoutBundle++;
                    }
                }

                if (p.BNR_Used_Capacity__c != null || p.BNR_Max_Capacity__c != null) {
                    if (p.BNR_Used_Capacity__c < p.BNR_Max_Capacity__c) {
                        if (countPciWithBundle > 0) {
                            for (PC_Item__c pci : productPciMap.get(p)) {
                                if (pci.Product__c == p.Id && pci.PC_Bundle__c != null) {
                                    for (PC_Bundle__c pciB : bundleList) {
                                        if (pciB.Id == pci.PC_Bundle__c) {
                                            for (PC_Item__c pci_r : pciB.PC_Items__r) {
                                                count++;
                                                Opportunity_Product__c oppProd = new Opportunity_Product__c();
                                                oppProd.Opportunity__c = opp.Id;
                                                oppProd.Product__c = p.Id;
                                                oppProd.Bundle_Name__c = pciB.PC_Bundle_Full_Name__c;
                                                oppProd.Bundle_Id__c = pciB.PC_Bundle_Id__c;
                                                oppProd.Product__c = pci_r.Product__c;
                                                oppProd.Course_Focus__c = (pci_r.Item_Type__c == 'OFFERING'
                                                    ? 'Primary'
                                                    : null);
                                                if (checkOppProdExists)
                                                    oppProd.Course_Focus__c = 'Secondary';
                                                else
                                                    oppProd.Course_Focus__c = (pci_r.Item_Type__c == 'OFFERING'
                                                        ? 'Primary'
                                                        : null);

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
                                if (checkOppProdExists)
                                    oppProd.Course_Focus__c = 'Secondary';
                                else
                                    oppProd.Course_Focus__c = (pci.Item_Type__c == 'OFFERING' ? 'Primary' : null);

                                oppProdList.add(oppProd);
                                break;
                            }
                        }
                    } else {
                        System.debug(
                            '@@ Product over capacity - Product Catalog Item cannot be added for ' + opp.Id + ' @@'
                        );
                    }
                } else {
                    System.debug(
                        '@@ Product Capacity fields are NULL (either BNR_Used_Capacity__c OR BNR_Max_Capacity__c) - Product Catalog Item cannot be added for ' +
                            opp.Id +
                            ' @@'
                    );
                }
            }

            // insert Opportunity_Product
            if (oppProdList.size() > 0) {
                try {
                    insert oppProdList;
                } catch (Exception e) {
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
            if (opp.AccountId != null)
                accIds.add(opp.AccountId);
            if (opp.Programme_Application__c != null)
                progIds.add(opp.Programme_Application__c);
        }

        if (accIds.size() > 0)
            accounts = [SELECT LastName, Name, IsPersonAccount FROM Account WHERE Id IN :accIds];
        if (progIds.size() > 0)
            programmes = [SELECT Name FROM Programme__c WHERE Id IN :progIds];

        for (Opportunity opportunity : opportunities) {
            if (
                opportunity.RecordTypeId == rtApp ||
                opportunity.RecordTypeId == rtInt ||
                opportunity.RecordTypeId == rtPE
            ) {
                for (Account acc : accounts) {
                    if (opportunity.AccountId == acc.Id && acc.IsPersonAccount == true) {
                        for (Programme__c prog : programmes) {
                            if (opportunity.Programme_Application__c == prog.Id) {
                                accountName = (acc.LastName != null ? acc.LastName : acc.Name);
                                programName = (prog.Name != null ? ' - ' + prog.Name : '');
                                interestArea = (opportunity.Interest_Area__c != null
                                    ? ' - ' + opportunity.Interest_Area__c
                                    : '');
                                location = (opportunity.Location__c != null ? ' - ' + opportunity.Location__c : '');
                                programDate = (opportunity.Start_Date__c != null
                                    ? ' - ' + string.valueOf(opportunity.Start_Date__c.year())
                                    : '');
                                if (opportunity.Mode__c != null) {
                                    if (opportunity.Mode__c.contains('Full Time'))
                                        mode = ' - FT';
                                    else if (opportunity.Mode__c.contains('Part Time'))
                                        mode = ' - PT';
                                }

                                // generate opportunity name using naming convention
                                if (mode != null)
                                    opportunityName =
                                        accountName +
                                        programName +
                                        interestArea +
                                        mode +
                                        location +
                                        programDate;
                                else
                                    opportunityName = accountName + programName + interestArea + location + programDate;

                                // logic for if opp name exceeds the character limit
                                if (opportunityName.length() >= 120) {
                                    opportunity.Full_Name__c = opportunityName; // populates custom field with full name
                                    opportunityName = opportunityName.substring(0, 120); // trims opportunityName variable, cutting it off after 120 chars
                                    opportunity.Name = opportunityName; // populates standard field with above
                                } else {
                                    opportunity.Name = opportunityName;
                                    opportunity.Full_Name__c = null;
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    /**
     * Set OOTJTH_Preserved__c field to the calculated value when stage is Acceptance or when the field is blanked
     * @param  newOppsList opps with new values
     * @param  oldOppsMap  opps with prior values
     */
    public static void populateTrainingHours(Map<Id, Opportunity> newOppsMap, Map<Id, Opportunity> oldOppsMap) {
        for (Opportunity opp : newOppsMap.values()) {
            Opportunity oldOpp = oldOppsMap.get(opp.Id);

            if (opp.OOTJTH_Calculated__c != null && opp.EPA__c != oldOpp.EPA__c) {
                opp.OOTJTH_Preserved__c = opp.OOTJTH_Calculated__c;
            }
        }
    }

    /* START OF - Changes made by Upender Nelluri - 22/06/2021 - BPP-14097/14098*/
    public static void prePopulateRegistrationFields(List<Opportunity> opportunities) {
        Set<Id> accountIds = new Set<Id>();
        for (Opportunity opp : opportunities) {
            accountIds.add(opp.accountId);
        }
        Map<Id, Account> Accounts = new Map<Id, Account>(
            [SELECT Id, Student_Type__pc FROM Account WHERE ID = :accountIds]
        );
        for (Opportunity opp : opportunities) {
            if (opp.StageName == 'Application') {
                opp.Passport__c = opp.Passport__c != null ? opp.Passport__c : 'Outstanding';
                opp.Confirmation_of_Contact_Details__c = opp.Confirmation_of_Contact_Details__c != null
                    ? opp.Confirmation_of_Contact_Details__c
                    : 'Outstanding';
                String studentType = (Accounts.get(opp.accountid) != null
                    ? Accounts.get(opp.accountid).Student_Type__pc
                    : null);
                if (studentType != null) {
                    if (studentType == 'Domestic') {
                        opp.English_Language_Certificate__c = opp.English_Language_Certificate__c != null
                            ? opp.English_Language_Certificate__c
                            : 'Not Applicable';
                        opp.EU_Settlement_Evidence__c = opp.EU_Settlement_Evidence__c != null
                            ? opp.EU_Settlement_Evidence__c
                            : 'Not Applicable';
                        opp.Visa_Confirmation__c = opp.Visa_Confirmation__c != null
                            ? opp.Visa_Confirmation__c
                            : 'Not Applicable';
                        opp.BRP__c = opp.BRP__c != null ? opp.BRP__c : 'Not Applicable';
                        opp.Stamped_Entry_Clearance__c = opp.Stamped_Entry_Clearance__c != null
                            ? opp.Stamped_Entry_Clearance__c
                            : 'Not Applicable';
                    }
                    if (studentType == 'EU') {
                        opp.English_Language_Certificate__c = opp.English_Language_Certificate__c != null
                            ? opp.English_Language_Certificate__c
                            : 'Outstanding';
                        opp.EU_Settlement_Evidence__c = opp.EU_Settlement_Evidence__c != null
                            ? opp.EU_Settlement_Evidence__c
                            : 'Outstanding';
                        opp.Visa_Confirmation__c = opp.Visa_Confirmation__c != null
                            ? opp.Visa_Confirmation__c
                            : 'Not Applicable';
                        opp.BRP__c = opp.BRP__c != null ? opp.BRP__c : 'Not Applicable';
                        opp.Stamped_Entry_Clearance__c = opp.Stamped_Entry_Clearance__c != null
                            ? opp.Stamped_Entry_Clearance__c
                            : 'Not Applicable';
                    }
                    if (studentType == 'International') {
                        opp.English_Language_Certificate__c = opp.English_Language_Certificate__c != null
                            ? opp.English_Language_Certificate__c
                            : 'Outstanding';
                        opp.EU_Settlement_Evidence__c = opp.EU_Settlement_Evidence__c != null
                            ? opp.EU_Settlement_Evidence__c
                            : 'Not Applicable';
                        opp.Visa_Confirmation__c = opp.Visa_Confirmation__c != null
                            ? opp.Visa_Confirmation__c
                            : 'Outstanding';
                        opp.BRP__c = opp.BRP__c != null ? opp.BRP__c : 'Outstanding';
                        opp.Stamped_Entry_Clearance__c = opp.Stamped_Entry_Clearance__c != null
                            ? opp.Stamped_Entry_Clearance__c
                            : 'Outstanding';
                    }
                }
            }
        }
    }
    /* END OF - Changes made by Upender Nelluri */

    /* START OF - Changes made by Upender Nelluri - 24/11/2021 - BPP-11487 */
    public static void populateRegistrationStatus(List<Opportunity> opportunities) {
        Id studentApplication = Schema.sObjectType.Opportunity.getRecordTypeInfosByName()
            .get('Application')
            .getRecordTypeId();
        Id studentLockedApplication = Schema.sObjectType.Opportunity.getRecordTypeInfosByName()
            .get('Locked Application')
            .getRecordTypeId();
        for (Opportunity opp : opportunities) {
            if (opp.RecordTypeId == studentApplication || opp.RecordTypeId == studentLockedApplication) {
                if (
                    opp.Passport__c != null &&
                    opp.Degree_Transcript__c != null &&
                    opp.Degree_Certificate__c != null &&
                    opp.Proof_of_Exemptions__c != null &&
                    opp.Visa_Confirmation__c != null &&
                    opp.EU_Settlement_Evidence__c != null &&
                    opp.BCAT__c != null &&
                    opp.Inn_of_Court__c != null &&
                    opp.Certificate_of_Academic_Standing__c != null &&
                    opp.Faculty_Approval__c != null &&
                    opp.ACCA_Status_Report__c != null &&
                    opp.School_Leaving_Level_3_Certificate__c != null &&
                    opp.Highest_Qualification_Certificate__c != null &&
                    opp.Highest_Qualification_Transcript__c != null &&
                    opp.Confirmation_of_Contact_Details__c != null &&
                    opp.English_Language_Certificate__c != null &&
                    opp.BRP__c != null &&
                    opp.GDL_PGDL_Transcript__c != null &&
                    opp.Stamped_Entry_Clearance__c != null
                ) {
                    if (
                        opp.Passport__c == 'Outstanding' ||
                        opp.Passport__c == 'Incomplete' ||
                        opp.Degree_Transcript__c == 'Outstanding' ||
                        opp.Degree_Transcript__c == 'Incomplete' ||
                        opp.Degree_Certificate__c == 'Outstanding' ||
                        opp.Degree_Certificate__c == 'Incomplete' ||
                        opp.Proof_of_Exemptions__c == 'Outstanding' ||
                        opp.Proof_of_Exemptions__c == 'Incomplete' ||
                        opp.Visa_Confirmation__c == 'Outstanding' ||
                        opp.Visa_Confirmation__c == 'Incomplete' ||
                        opp.EU_Settlement_Evidence__c == 'Outstanding' ||
                        opp.EU_Settlement_Evidence__c == 'Incomplete' ||
                        opp.BCAT__c == 'Outstanding' ||
                        opp.BCAT__c == 'Incomplete' ||
                        opp.Inn_of_Court__c == 'Outstanding' ||
                        opp.Inn_of_Court__c == 'Incomplete' ||
                        opp.Certificate_of_Academic_Standing__c == 'Outstanding' ||
                        opp.Certificate_of_Academic_Standing__c == 'Incomplete' ||
                        opp.Faculty_Approval__c == 'Outstanding' ||
                        opp.Faculty_Approval__c == 'Incomplete' ||
                        opp.ACCA_Status_Report__c == 'Outstanding' ||
                        opp.ACCA_Status_Report__c == 'Incomplete' ||
                        opp.School_Leaving_Level_3_Certificate__c == 'Outstanding' ||
                        opp.School_Leaving_Level_3_Certificate__c == 'Incomplete' ||
                        opp.Highest_Qualification_Certificate__c == 'Outstanding' ||
                        opp.Highest_Qualification_Certificate__c == 'Incomplete' ||
                        opp.Highest_Qualification_Transcript__c == 'Outstanding' ||
                        opp.Highest_Qualification_Transcript__c == 'Incomplete' ||
                        opp.Confirmation_of_Contact_Details__c == 'Outstanding' ||
                        opp.Confirmation_of_Contact_Details__c == 'Incomplete' ||
                        opp.English_Language_Certificate__c == 'Outstanding' ||
                        opp.English_Language_Certificate__c == 'Incomplete' ||
                        opp.BRP__c == 'Outstanding' ||
                        opp.BRP__c == 'Incomplete' ||
                        opp.GDL_PGDL_Transcript__c == 'Outstanding' ||
                        opp.GDL_PGDL_Transcript__c == 'Incomplete' ||
                        opp.Stamped_Entry_Clearance__c == 'Outstanding' ||
                        opp.Stamped_Entry_Clearance__c == 'Incomplete'
                    ) {
                        if (opp.Listed_documents_are_validated_enough__c) {
                            opp.Registration_Status__c = 'Validated - Temp Registered';
                        } else {
                            opp.Registration_Status__c = 'Outstanding';
                        }
                    } else if (
                        (opp.Passport__c == 'Validated' ||
                        opp.Passport__c == 'Not Applicable') &&
                        (opp.Degree_Transcript__c == 'Validated' ||
                        opp.Degree_Transcript__c == 'Not Applicable') &&
                        (opp.Degree_Certificate__c == 'Validated' ||
                        opp.Degree_Certificate__c == 'Not Applicable') &&
                        (opp.Proof_of_Exemptions__c == 'Validated' ||
                        opp.Proof_of_Exemptions__c == 'Not Applicable') &&
                        (opp.Visa_Confirmation__c == 'Validated' ||
                        opp.Visa_Confirmation__c == 'Not Applicable') &&
                        (opp.EU_Settlement_Evidence__c == 'Validated' ||
                        opp.EU_Settlement_Evidence__c == 'Not Applicable') &&
                        (opp.BCAT__c == 'Validated' ||
                        opp.BCAT__c == 'Not Applicable') &&
                        (opp.Inn_of_Court__c == 'Validated' ||
                        opp.Inn_of_Court__c == 'Not Applicable') &&
                        (opp.Certificate_of_Academic_Standing__c == 'Validated' ||
                        opp.Certificate_of_Academic_Standing__c == 'Not Applicable') &&
                        (opp.Faculty_Approval__c == 'Validated' ||
                        opp.Faculty_Approval__c == 'Not Applicable') &&
                        (opp.ACCA_Status_Report__c == 'Validated' ||
                        opp.ACCA_Status_Report__c == 'Not Applicable') &&
                        (opp.School_Leaving_Level_3_Certificate__c == 'Validated' ||
                        opp.School_Leaving_Level_3_Certificate__c == 'Not Applicable') &&
                        (opp.Highest_Qualification_Certificate__c == 'Validated' ||
                        opp.Highest_Qualification_Certificate__c == 'Not Applicable') &&
                        (opp.Highest_Qualification_Transcript__c == 'Validated' ||
                        opp.Highest_Qualification_Transcript__c == 'Not Applicable') &&
                        (opp.Confirmation_of_Contact_Details__c == 'Validated' ||
                        opp.Confirmation_of_Contact_Details__c == 'Not Applicable') &&
                        (opp.English_Language_Certificate__c == 'Validated' ||
                        opp.English_Language_Certificate__c == 'Not Applicable') &&
                        (opp.BRP__c == 'Validated' ||
                        opp.BRP__c == 'Not Applicable') &&
                        (opp.GDL_PGDL_Transcript__c == 'Validated' ||
                        opp.GDL_PGDL_Transcript__c == 'Not Applicable') &&
                        (opp.Stamped_Entry_Clearance__c == 'Validated' ||
                        opp.Stamped_Entry_Clearance__c == 'Not Applicable')
                    ) {
                        opp.Registration_Status__c = 'Validated';
                        opp.Listed_documents_are_validated_enough__c = false;
                    } else {
                        opp.Registration_Status__c = 'Submitted';
                    }
                } else if (opp.Listed_documents_are_validated_enough__c) {
                    opp.Registration_Status__c = 'Validated - Temp Registered';
                } else {
                    opp.Registration_Status__c = 'Not Reviewed';
                }
            }
        }
    }
    /* END OF - Changes made by Upender Nelluri */

    public static void handleOpportunityRoundRobinReassignment(
        List<Opportunity> newOpportunitiesList,
        Map<Id, Opportunity> oldMap,
        String context
    ) {
        List<Opportunity> opportunitiesToProcess = new List<Opportunity>();
        Set<Id> accountIds = new Set<Id>();
        for (Opportunity opportunity : newOpportunitiesList) {
            accountIds.add(opportunity.AccountId);
        }
        Map<Id, Account> accountMap = new Map<Id, Account>([SELECT Id, OwnerId FROM Account WHERE Id IN :accountIds]);

        for (Opportunity opportunity : newOpportunitiesList) {
            System.debug(
                '@OpportunityTriggerHandler handleOpportunityRoundRobinReassignment - opportunity.OwnerId: ' +
                opportunity.OwnerId
            );
            if (context == 'insert' && defaultOpportunityUserIdSet.contains(opportunity.OwnerId)) {
                opportunitiesToProcess.add(opportunity);
            }
            if (context == 'update') {
                /*System.debug(defaultOpportunityUserIdSet.contains(oldMap.get(opportunity.Id).OwnerId));
                System.debug(defaultOpportunityUserIdSet.contains(opportunity.OwnerId));
                System.debug(opportunity.LeadSource != null);*/
                if (
                    defaultOpportunityUserIdSet.contains(oldMap.get(opportunity.Id).OwnerId) &&
                    defaultOpportunityUserIdSet.contains(opportunity.OwnerId) &&
                    opportunity.LeadSource != null
                ) {
                    Account account = accountMap.get(opportunity.AccountId);
                    if (account != null && !defaultOpportunityUserIdSet.contains(account.OwnerId)) {
                        opportunity.OwnerId = account.OwnerId;
                    }
                } else if (
                    !defaultOpportunityUserIdSet.contains(oldMap.get(opportunity.Id).OwnerId) &&
                    defaultOpportunityUserIdSet.contains(opportunity.OwnerId)
                ) {
                    opportunitiesToProcess.add(opportunity);
                }
            }
        }
        System.debug(
            '@OpportunityTriggerHandler handleOpportunityRoundRobinReassignment - opportunitiesToProcess.size: ' +
            opportunitiesToProcess.size()
        );
        System.debug(
            '@OpportunityTriggerHandler handleOpportunityRoundRobinReassignment - opportunitiesToProcess: ' +
            opportunitiesToProcess
        );

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
            System.debug('@OpportunityTriggerHandler handleAccountRoundRobinReassignment - context: ' + context);
            RoundRobinHandler.reassignRecords(userOwnedRecordsMap, null, opportunitiesToProcess, null);
        }
    }

    public static void primaryDeliveryAddressAssignment(
        List<Opportunity> newOpportunitiesList,
        Map<Id, Opportunity> oldOpps
    ) {
        List<Opportunity> oppsInAcceptance = new List<Opportunity>();
        Set<Id> accountsToCheck = new Set<Id>();
        List<Address__c> addressesToInsert = new List<Address__c>();
        Map<Id, Address__c> accountToHomeAddress = new Map<Id, Address__c>();

        for (Opportunity newOpportunity : newOpportunitiesList) {
            if (
                newOpportunity.RecordTypeId == apprenticeApplicationRT &&
                (newOpportunity.StageName == 'Acceptance' &&
                oldOpps.get(newOpportunity.Id).StageName != 'Acceptance')
            ) {
                oppsInAcceptance.add(newOpportunity);
                accountsToCheck.add(newOpportunity.AccountId);
            }
        }

        if (oppsInAcceptance.isEmpty()) {
            return;
        }

        for (Address__c address : [
            SELECT Id, Primary_Delivery__c, Student__c
            FROM address__c
            WHERE Student__c IN :accountsToCheck AND Primary_Delivery__c = TRUE
        ]) {
            if (accountsToCheck.contains(address.Student__c)) {
                accountsToCheck.remove(address.Student__c);
            }
        }

        if (accountsToCheck.isEmpty()) {
            return;
        }

        for (Address__c address : [
            SELECT
                Student__c,
                Street_1__c,
                Street_2__c,
                Street_3__c,
                Street_4__c,
                Type__c,
                City__c,
                Lookup_Country__c,
                County_State__c,
                Delivery_Instructions__c,
                Active__c,
                Locality__c,
                Primary_Delivery__c,
                Record_Source__c,
                State_Province__c,
                Zip_Postal_Code__c
            FROM Address__C
            WHERE Student__c IN :accountsToCheck AND Type__c = 'Home'
        ]) {
            accountToHomeAddress.put(address.Student__c, address);
        }

        for (Opportunity opp : oppsInAcceptance) {
            if (!accountToHomeAddress.containsKey(opp.AccountId)) {
                continue;
            }

            Address__c clonedAddress = accountToHomeAddress.get(opp.AccountId).clone(false, true, false, false);
            clonedAddress.Type__c = 'Mailing';
            clonedAddress.Primary_Delivery__c = true;
            addressesToInsert.add(clonedAddress);
        }

        if (!addressesToInsert.isEmpty()) {
            insert addressesToInsert;
        }
    }

    /**
     * Updates the training manager and sponsorship fields on Opportunities when
     * they are moved into Acceptance - Completed.
     *
     * @param newOpps List of opportunities that have updated
     * @param oldOpps Map of old opportunities
     */
    public static void updateTrainingManager(List<Opportunity> newOpps, Map<Id, Opportunity> oldOpps) {
        Map<Id, Opportunity> filteredOpps = new Map<Id, Opportunity>();
        Set<Id> contactIds = new Set<Id>();

        for (Opportunity opp : newOpps) {
            if (
                opp.RecordTypeId == apprenticeApplicationRT &&
                opp.Application_Type__c == 'Degree Apprenticeship' &&
                opp.StageName == 'Acceptance' &&
                (opp.BPP_Sub_Status__c == 'Completed' &&
                oldOpps.get(opp.Id).BPP_Sub_Status__c != 'Completed')
            ) {
                filteredOpps.put(opp.Id, opp);
                contactIds.add(opp.Line_Manager__c);
            }
        }

        for (Contact contact : [
            SELECT Id
            FROM Contact
            WHERE Id IN :contactIds AND RecordTypeId != :trainingManagerRTId
        ]) {
            if (contactIds.contains(contact.Id)) {
                contactIds.remove(contact.Id);
            }
        }

        for (Opportunity opp : filteredOpps.values()) {
            if (contactIds.contains(opp.Line_Manager__c)) {
                opp.Training_Manager__c = opp.Line_Manager__c;
            }

            opp.Sponsorship_Level__c = 'Full';
            opp.Sponsorship_Percentage__c = 100;
            opp.Customer_Group__c = 'SELFFUND';
        }
    }

    /**
     * Updates the Account and creates a sponsorship record
     * @param newOpps List of opportunities updated
     * @param oldOpps Map of old opportunities
     */
    public static void createSponsorship(List<Opportunity> newOpps, Map<Id, Opportunity> oldOpps) {
        Map<Id, Opportunity> filteredOpps = new Map<Id, Opportunity>();
        Map<Id, Opportunity> accountToOpp = new Map<Id, Opportunity>();
        Map<Id, Account> accountsToUpdate = new Map<Id, Account>();
        List<Sponsorship__c> sponsorships = new List<Sponsorship__c>();
        Set<Id> contactIds = new Set<Id>();

        for (Opportunity opp : newOpps) {
            if (
                opp.RecordTypeId == apprenticeApplicationRT &&
                opp.Application_Type__c == 'Degree Apprenticeship' &&
                opp.StageName == 'Acceptance' &&
                (opp.BPP_Sub_Status__c == 'Completed' &&
                oldOpps.get(opp.Id).BPP_Sub_Status__c != 'Completed')
            ) {
                filteredOpps.put(opp.Id, opp);
                contactIds.add(opp.Line_Manager__c);
                accountToOpp.put(opp.AccountId, opp);
            }
        }

        for (Account account : [
            SELECT Id, Training_Manager__c, Client__c
            FROM Account
            WHERE Id IN :accountToOpp.keySet()
        ]) {
            Opportunity opp = accountToOpp.get(account.Id);

            if (opp.Training_Manager__c != null && account.Training_Manager__c == null) {
                account.Training_Manager__c = opp.Training_Manager__c;
            }

            account.Country_of_Permanent_Address__c = opp.Address_Lookup_Country__c;
            account.Client__c = opp.Client__c;
            account.Legal_Entity__c = 'UC~COL';
            accountsToUpdate.put(account.Id, account);
        }

        for (Sponsorship__c sponsorship : [
            SELECT Id, Opportunity__c
            FROM Sponsorship__c
            WHERE Opportunity__c IN :filteredOpps.keySet()
        ]) {
            if (filteredOpps.containsKey(sponsorship.Opportunity__c)) {
                filteredOpps.remove(sponsorship.Opportunity__c);
            }
        }

        for (Opportunity opp : filteredOpps.values()) {
            sponsorships.add(
                new Sponsorship__c(
                    Company__c = opp.Client__c,
                    Opportunity__c = opp.Id,
                    Student__c = opp.AccountId,
                    Training_Manager__c = opp.Training_Manager__c,
                    Active__c = false
                )
            );
        }

        update accountsToUpdate.values();

        if (!sponsorships.isEmpty()) {
            // Create sponsorships if we can - some sponsorships
            // will not be created due to validation issues or data
            // disparity and this is fine.
            Database.insert(sponsorships, false);
        }
    }

    public static void populateHESAStudentID(List<Opportunity> opportunityList) {
        Set<String> validStatuses = new Set<String>{
            'Accepted - Conditional Firm',
            'Accepted - Conditional Insurance',
            'Accepted - Pmt Pending',
            'Accepted - Pmt Received',
            'Accepted - Unconditional Firm',
            'Accepted - Unconditional Insurance',
            'Accepted - Unknown Condition Firm'
        };
        Set<Id> accountIds = new Set<Id>();
        Set<Id> programmeIds = new Set<Id>();
        Map<Id, Account> accountMap;
        Map<Id, Programme__c> programmeMap;
        List<Opportunity> eligibileOpportunityList = new List<Opportunity>();
        for (Opportunity opportunity : opportunityList) {
            if (
                opportunity.Start_Date__c != null &&
                opportunity.Start_Date__c >= Date.newInstance(2022, 8, 1) &&
                validStatuses.contains(opportunity.StageName) &&
                opportunity.Programme_Application__c != null &&
                (opportunity.RecordTypeId ==
                Schema.Sobjecttype.Opportunity.getRecordTypeInfosByName().get('Application').getRecordTypeId() ||
                opportunity.RecordTypeId ==
                Schema.Sobjecttype.Opportunity.getRecordTypeInfosByName().get('Locked Application').getRecordTypeId())
            ) {
                accountIds.add(opportunity.AccountId);
                programmeIds.add(opportunity.Programme_Application__c);
                eligibileOpportunityList.add(opportunity);
            }
        }

        if (accountIds.size() > 0) {
            accountMap = new Map<Id, Account>(
                [
                    SELECT Id, BPP_Account_Number__c
                    FROM Account
                    WHERE Id IN :accountIds AND HESA_Student_ID_SID__c = NULL
                ]
            );
        }
        if (programmeIds.size() > 0) {
            programmeMap = new Map<Id, Programme__c>(
                [
                    SELECT Id, Institute__r.Institution_Code__c
                    FROM Programme__c
                    WHERE Id IN :programmeIds AND Institute__r.Institution_Code__c != NULL
                ]
            );
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
            1 => 1,
            2 => 3,
            3 => 7,
            4 => 9,
            5 => 1,
            6 => 3,
            7 => 7,
            8 => 9,
            9 => 1,
            10 => 3,
            11 => 7,
            12 => 9,
            13 => 1,
            14 => 3,
            15 => 7,
            16 => 9
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

    /*public static String checkEligibleForBannerSubmission(Opportunity opportunity) {
        String error = '';
        String missingValueError = 'Required Account value missing: ';
        Set<String> validStatuses = new Set<String>{'Accepted - Conditional Firm', 'Accepted - Unconditional Firm', 'Accepted - Pmt Received', 'Transferred', 'Deferred Entry'};

        if (opportunity.Account.PersonBirthdate == null) {
            error += missingValueError + 'Date of Birth</br>';
        }
        if (opportunity.Account.Primary_Nationality__pc == null){
            error += missingValueError + 'Primary Nationality</br>';
        }
        if (opportunity.Account.PS_Profile_Services_ID__pc == null) {
            error += missingValueError + 'Profile Services Id</br>';
        }
        if (opportunity.Account.Student_Type__pc == null) {
            error += missingValueError + 'Student Type</br>';
        }
        if (opportunity.Account.Legal_Entity__c == null) {
            error += missingValueError + 'Legal Entity</br>';
        }
        if (opportunity.BNR_Level_Code_Text__c == 'PQ') {
            if (opportunity.Account.Account_Type__c == null) {
                error += missingValueError + 'Account Type</br>';
            }
            if (opportunity.Account.VAT_Code__pc == null) {
                error += missingValueError + 'VAT Code</br>';
            }
            if (opportunity.Account.Phone == null) {
                error += missingValueError + 'Phone Number</br>';
            }
            if (opportunity.Account.PersonEmail == null) {
                error += missingValueError + 'Email Address</br>';
            }
        } else {
            if (opportunity.Account.Country_of_Permanent_Address__c == null) {
                error += missingValueError + 'Country of Permanent Address</br>';
            }
            if (opportunity.Account.PersonBirthdate != null && opportunity.Account.Age__pc < 17) {
                error += 'Student must be at least 17 years old to submit an application</br>';
            }
        }
        if (opportunity.Account.AR_Account_Status_Code__c == 'FinancialHoldApplied') {
            error += 'Student is on Financial Hold. Application cannot be submitted</br>';
        }
        if (!validStatuses.contains(opportunity.StageName)) {
            error += 'Opportunity Status is not valid</br>';
        }

        List<Address__c> addressList = [SELECT Id, Active__c, Type__c FROM Address__c WHERE Active__c = TRUE AND Student__c =: opportunity.AccountId];
        if (addressList.size() == 0) {
            error += 'Student must have at least one active Address</br>';
        }

        List<Sponsorship__c> sponsorshipList = [SELECT Id, Active__c, Student__c FROM Sponsorship__c WHERE Active__c = TRUE AND Student__c =: opportunity.AccountId AND Opportunity__c =: opportunity.Id];
        if (sponsorshipList.size() == 0 && opportunity.Sponsorship_Level__c != null && opportunity.Sponsorship_Percentage__c != null && opportunity.Sponsorship_Amount__c != null) {
            error += 'An active Sponsorship record must be present on related Student if Opportunity Sponsorship Level/Percentage/Amount fields are populated';
        }

        return (error != '' ? error : null);
    }*/

    /* START OF - Changes made by Swayanprava Sahoo - 06/02/2023 - BPP-24827/BPP-24590 */
    public static void checkForCAS_EmailAutomation(
        List<Opportunity> newOpportunitiesList,
        List<Opportunity> oldOpportunitiesList
    ) {
        if (newOpportunitiesList.size() == 1) {
            List<Account> accountrecords = new List<Account>();
            String Emailtogo = '';
            System.debug('@@Inside CheckForCAS_EmailAutomation@@Trigger.old: ' + oldOpportunitiesList[0].CAS_status__c);
            System.debug('@@Inside CheckForCAS_EmailAutomation@@Trigger.new: ' + newOpportunitiesList[0].CAS_status__c);
            Opportunity oldOpportunityRecord = oldOpportunitiesList[0];
            Opportunity newOpportunityRecord = newOpportunitiesList[0];
            accountrecords = [
                SELECT id, FirstName, Name, PersonBirthdate, PersonEmail
                FROM Account
                WHERE id = :newOpportunityRecord.AccountId
            ];
            System.debug(accountrecords[0].PersonEmail);
            Emailtogo = accountrecords[0].PersonEmail;
            System.debug('@@newOpportunitiesList.CAS_Letter_Sent__c@@' + newOpportunityRecord.CAS_Letter_Sent__c);
            System.debug('@@newOpportunitiesList.CAS_status__c@@' + newOpportunityRecord.CAS_status__c);
            System.debug('Record type Id: ' + newOpportunityRecord.RecordTypeId);

            //Get Rcordtype Ids
            String OppoApplicationRecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName()
                .get('Application')
                .getRecordTypeId();
            String OppoLockedApplicationRecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName()
                .get('Locked Application')
                .getRecordTypeId();
            System.debug('@@Application RecordType ID@@' + OppoApplicationRecordTypeId);
            System.debug('@@Locked Application RecordType ID@@' + OppoLockedApplicationRecordTypeId);

            //CAS PDF attachment
            if (
                newOpportunityRecord.RecordTypeId == OppoApplicationRecordTypeId ||
                newOpportunityRecord.RecordTypeId == OppoLockedApplicationRecordTypeId
            ) {
                if (
                    newOpportunityRecord.CAS_status__c == 'Issued' &&
                    oldOpportunityRecord.CAS_status__c != 'Issued' &&
                    !newOpportunityRecord.CAS_Letter_Sent__c
                ) {
                    System.debug('@@Inside if for CAS PDF@@');
                    SendCASAutoReply.sendEmailWithPDfAttachment(
                        newOpportunityRecord.id,
                        accountrecords[0].Name,
                        newOpportunityRecord.CAS_status__c,
                        Emailtogo
                    );
                }
            }
        }
    }
    /* END OF - Changes made by Swayanprava Sahoo */
}
