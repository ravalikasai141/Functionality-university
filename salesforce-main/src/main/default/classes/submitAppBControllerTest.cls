@isTest
public class submitAppBControllerTest {
    @testSetup
	static void testSetup() {
		Database.DMLOptions dbDML = new Database.DMLOptions(); 
		dbDML.DuplicateRuleHeader.allowSave = true;
		dbDML.DuplicateRuleHeader.runAsCurrentUser = true;
		
        Account studentAccount = new Account(
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Student Account').getRecordTypeId(),
            FirstName = 'TestAccount',
            LastName = 'Student2',
            PersonBirthdate = Date.newInstance(2002,2,1),
            Preferred_Email__pc = 'Personal',
            Preferred_Phone__pc = 'Mobile',
            PersonEmail = 'john2@john.com',
            Personal_Email__pc = 'john2@john.com',
            PersonMobilePhone ='+447716123222',
            Account_Type__c = 'General', 
            VAT_Code__pc = '123456789',  
            Domicile__pc = 'XF~ England', 
            PS_Profile_Services_ID__pc = 'ba618412-c3d7-4752-67yu-17c52bfc20c8', 
            Student_Type__pc = 'Domestic', 
            AR_Account_Status_Code__c = 'test',
            Legal_Entity__c = 'UC~COL',
            Parent_Guardian_Occupation__pc = '0000~ Not stated',
            SFDC_Disability_Status_Code_Select__pc = '0~ No Known Disability'
            //SFDC_Disability_Type_Code_Select__pc = '0~ No Known Disability'
        );
		Database.insert(studentAccount, dbDML);

        Opportunity opportunity = new Opportunity(
            Name = 'TestOpportunity2', 
            AccountId = studentAccount.Id,
            CloseDate = System.today(),
            Enrolment_Status__c = 'Acceptance',
            StageName = 'Accepted - Conditional Firm', 
            BNR_Level_Code_Text__c = 'Code Text', 
            Sponsorship_Level__c = 'Partial', 
            Sponsorship_Percentage__c = 50,
            SFDC_Admissions_STYPE_Code_Select__c = '0~ Undeclared',
            SFDC_Admissions_RESD_Code_Select__c = '0~ Undeclared',
            SFDC_Cohort_Code_Select__c = 'C7~ Cohort July'
        );
		Database.insert(opportunity, dbDML);

        Address__c address = new Address__c(
            Student__c = studentAccount.Id,
            Type__c = 'Home',
            Street_1__c = '329 S Tonne Dr',
            Street_2__c = '123',
            Street_3__c = '123',
            Street_4__c = '12',
            City__c = 'Chicago',
            Zip_Postal_Code__c = '12345'
        );
		Database.insert(address, dbDML);
    }

    @isTest
    public static void unitTest4() {
        Test.startTest();
			Database.DMLOptions dbDML = new Database.DMLOptions(); 
			dbDML.DuplicateRuleHeader.allowSave = true;
			dbDML.DuplicateRuleHeader.runAsCurrentUser = true;
		
            Account acc = [SELECT Id FROM Account WHERE Name = 'TestAccount Student2'];
            acc.AR_Account_Status_Code__c = 'FinancialHoldApplied';
            Database.update(acc, dbDML);

            Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'TestOpportunity2'];

            String result = submitAppBController.submitApp(opp.Id);
            System.debug(result);
        Test.stopTest();
    }

    @isTest
    public static void unitTest5() {
        Test.startTest();
            Account acc = [SELECT Id FROM Account WHERE Name = 'TestAccount Student2'];
            Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'TestOpportunity2'];

            String result = submitAppBController.submitApp(opp.Id);
            System.debug(result);
        Test.stopTest();
    }

    @isTest
    public static void unitTest6() {
        Test.startTest();
			Database.DMLOptions dbDML = new Database.DMLOptions(); 
			dbDML.DuplicateRuleHeader.allowSave = true;
			dbDML.DuplicateRuleHeader.runAsCurrentUser = true;
		
            Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'TestOpportunity2'];

            Address__c address = [SELECT Id FROM Address__c];
            address.Student__c = NULL;
            Database.update(address, dbDML);

            String result = submitAppBController.submitApp(opp.Id);
            System.debug(result);
        Test.stopTest();
    }

    @isTest
    public static void unitTest7() {
        Test.startTest();
			Database.DMLOptions dbDML = new Database.DMLOptions(); 
			dbDML.DuplicateRuleHeader.allowSave = true;
			dbDML.DuplicateRuleHeader.runAsCurrentUser = true;
		
            Account acc = [SELECT Id FROM Account WHERE Name = 'TestAccount Student2'];
            acc.PersonBirthdate = null;
            Database.update(acc, dbDML);
            
            Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'TestOpportunity2'];

            String result = submitAppBController.submitApp(opp.Id);
            System.debug(result);
        Test.stopTest();
    }

    @isTest
    public static void unitTest8() {
        Test.startTest();
            country_list__c cntry = new country_list__c(Name = 'United Kingdom', ISO_Code__c = 'GBR', country_code_2__c = 'GB');
            insert cntry;
			
			Database.DMLOptions dbDML = new Database.DMLOptions(); 
			dbDML.DuplicateRuleHeader.allowSave = true;
			dbDML.DuplicateRuleHeader.runAsCurrentUser = true;

            Account acc = [SELECT Id FROM Account WHERE Name = 'TestAccount Student2'];
            acc.Primary_Nationality__pc = cntry.Id;
            acc.Account_Type__c = null;
            acc.VAT_Code__pc = null;
            acc.Phone = null;
            acc.Preferred_Email__pc = null;
            acc.Preferred_Phone__pc = null;
            acc.PersonEmail = null;
            acc.Personal_Email__pc = null;
            acc.PersonMobilePhone = null;
            Database.update(acc, dbDML);
            
            Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'TestOpportunity2'];
            opp.BNR_Level_Code_Text__c = 'PQ';
            Database.update(opp, dbDML);

            String result = submitAppBController.submitApp(opp.Id);
            System.debug(result);
        Test.stopTest();
    }
	
	@isTest
    public static void unitTestNoARStatusCode() {
        Test.startTest();
			Database.DMLOptions dbDML = new Database.DMLOptions(); 
			dbDML.DuplicateRuleHeader.allowSave = true;
			dbDML.DuplicateRuleHeader.runAsCurrentUser = true;
		
            Account acc = [SELECT Id FROM Account WHERE Name = 'TestAccount Student2'];
        	acc.AR_Account_Status_Code__c = 'FinancialHoldApplied';
        	Database.update(acc, dbDML);

            Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'TestOpportunity2'];
            opp.StageName = 'Confirmed';
            opp.Enrolment_Status__c = null;
            Database.update(opp, dbDML);

            String result = submitAppBController.submitApp(opp.Id);
            System.debug(result);
        Test.stopTest();
    }
	
	@isTest
    public static void unitTestWrongStatus() {
        Test.startTest();
			Database.DMLOptions dbDML = new Database.DMLOptions(); 
			dbDML.DuplicateRuleHeader.allowSave = true;
			dbDML.DuplicateRuleHeader.runAsCurrentUser = true;
		
            Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'TestOpportunity2'];
            opp.StageName = 'Closed Won';
            opp.Enrolment_Status__c = null;
        	opp.BNR_Level_Code_Text__c = 'PQ';
            Database.update(opp, dbDML);

            String result = submitAppBController.submitApp(opp.Id);
            System.debug(result);
        Test.stopTest();
    }
	
	@isTest
    public static void unitTestNoAddressOrSponsorship() {
        Test.startTest();
			delete [SELECT Id FROM Address__c];
			delete [SELECT Id FROM Sponsorship__c];
        
        	Database.DMLOptions dbDML = new Database.DMLOptions(); 
			dbDML.DuplicateRuleHeader.allowSave = true;
			dbDML.DuplicateRuleHeader.runAsCurrentUser = true;
        
        	Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'TestOpportunity2'];
            opp.StageName = 'Closed Won';
            opp.Enrolment_Status__c = null;
        	opp.Sponsorship_Amount__c = 50;
            Database.update(opp, dbDML);

            String result = submitAppBController.submitApp(opp.Id);
            System.debug(result);
        Test.stopTest();
    }
	
	@isTest
    public static void unitTestNulls() {
        Test.startTest();
			Database.DMLOptions dbDML = new Database.DMLOptions(); 
			dbDML.DuplicateRuleHeader.allowSave = true;
			dbDML.DuplicateRuleHeader.runAsCurrentUser = true;
		
            Account acc = [SELECT Id FROM Account WHERE Name = 'TestAccount Student2'];
        	acc.PersonBirthdate = null;
        	acc.Account_Type__c = null;
        	acc.VAT_Code__pc = null;
        	acc.Phone = null;
        	acc.PersonEmail = null;
        	acc.Domicile__pc = null;
        	acc.PS_Profile_Services_ID__pc = null;
        	acc.Student_Type__pc = null;
        	acc.Legal_Entity__c = null;
        	Database.update(acc, dbDML);
			
			Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'TestOpportunity2'];
            opp.StageName = 'Closed Won';
            opp.Enrolment_Status__c = null;
        	opp.BNR_Level_Code_Text__c = 'PQ';
            Database.update(opp, dbDML);

            String result = submitAppBController.submitApp(opp.Id);
            System.debug(result);
        Test.stopTest();
    }
	
	@isTest
    public static void unitTestNullsNotPQ() {
        Test.startTest();
			Database.DMLOptions dbDML = new Database.DMLOptions(); 
			dbDML.DuplicateRuleHeader.allowSave = true;
			dbDML.DuplicateRuleHeader.runAsCurrentUser = true;
		
            Account acc = [SELECT Id FROM Account WHERE Name = 'TestAccount Student2'];
        	acc.PersonBirthdate = System.today().addYears(-15);
        	acc.Domicile__pc = null;
        	acc.PS_Profile_Services_ID__pc = null;
        	acc.Student_Type__pc = null;
        	acc.Legal_Entity__c = null;
        	Database.update(acc, dbDML);
			
			Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'TestOpportunity2'];
            opp.StageName = 'Accepted - Conditional Firm';
            opp.Enrolment_Status__c = null;
        	opp.BNR_Level_Code_Text__c = null;
            Database.update(opp, dbDML);

            String result = submitAppBController.submitApp(opp.Id);
            System.debug(result);
        Test.stopTest();
    }
    
    @isTest
    public static void unitTestNullsPQ1() {
        Test.startTest();
			Database.DMLOptions dbDML = new Database.DMLOptions(); 
			dbDML.DuplicateRuleHeader.allowSave = true;
			dbDML.DuplicateRuleHeader.runAsCurrentUser = true;
		
            Account acc = [SELECT Id FROM Account WHERE Name = 'TestAccount Student2'];
        	acc.PersonBirthdate = System.today().addYears(-15);
        	acc.Domicile__pc = null;
        	acc.PS_Profile_Services_ID__pc = null;
        	acc.Student_Type__pc = null;
        	acc.Legal_Entity__c = null;
        	acc.Account_Type__c = null;
        	Database.update(acc, dbDML);
			
			Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'TestOpportunity2'];
            opp.StageName = 'Accepted - Conditional Firm';
            opp.Enrolment_Status__c = null;
        	opp.BNR_Level_Code_Text__c = 'PQ';
            Database.update(opp, dbDML);

            String result = submitAppBController.submitApp(opp.Id);
            System.debug(result);
        Test.stopTest();
    }
    
    @isTest
    public static void unitTestNullsPQ2() {
        Test.startTest();
			Database.DMLOptions dbDML = new Database.DMLOptions(); 
			dbDML.DuplicateRuleHeader.allowSave = true;
			dbDML.DuplicateRuleHeader.runAsCurrentUser = true;
		
            Account acc = [SELECT Id FROM Account WHERE Name = 'TestAccount Student2'];
        	acc.PersonBirthdate = System.today().addYears(-15);
        	acc.Domicile__pc = null;
        	acc.PS_Profile_Services_ID__pc = null;
        	acc.Student_Type__pc = null;
        	acc.Legal_Entity__c = null;
        	acc.VAT_Code__pc = null;
        	Database.update(acc, dbDML);
			
			Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'TestOpportunity2'];
            opp.StageName = 'Accepted - Conditional Firm';
            opp.Enrolment_Status__c = null;
        	opp.BNR_Level_Code_Text__c = 'PQ';
            Database.update(opp, dbDML);

            String result = submitAppBController.submitApp(opp.Id);
            System.debug(result);
        Test.stopTest();
    }
    
    @isTest
    public static void unitTestSuccess() {
        Test.startTest();
            country_list__c cntry = new country_list__c(Name = 'United Kingdom', ISO_Code__c = 'GBR', country_code_2__c = 'GB', Valid_Nationality__c = true, Valid_Domicile__c = true);
            insert cntry;
            
            Database.DMLOptions dbDML = new Database.DMLOptions(); 
        	dbDML.DuplicateRuleHeader.allowSave = true;
        	dbDML.DuplicateRuleHeader.runAsCurrentUser = true;
            
            Account acc = [SELECT Id FROM Account WHERE Name = 'TestAccount Student2'];
            acc.Primary_Nationality__pc = cntry.Id;
        	acc.Country_of_Permanent_Address__c = cntry.Id;
            Database.update(acc, dbDML);
            
            Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'TestOpportunity2'];
    
            String result = submitAppBController.submitApp(opp.Id);
            System.debug(result);
        Test.stopTest();
    }
}