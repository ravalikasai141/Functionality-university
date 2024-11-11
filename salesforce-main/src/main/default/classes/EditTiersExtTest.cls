@isTest
public class EditTiersExtTest {
    
    @testSetup
    static void testSetup(){
        Account a = new Account();
        a.Name = 'Test Company';
        a.RecordTypeId = Schema.sObjectType.Account.getRecordTypeInfosByName().get('Business Development Account').getRecordTypeId();
        insert a;

        Opportunity opp = new Opportunity();
        opp.AccountId = a.Id;
        opp.Name = 'Test Opportunity';
        opp.RecordTypeId = Schema.Sobjecttype.Opportunity.getRecordTypeInfosByName().get('Business Development').getRecordTypeId();
        opp.StageName = 'Quoting';
        opp.BPP_Sub_Status__c = 'Other';
        opp.CloseDate = Date.Today();
        insert opp;
    }
    
    @isTest static void test_SelectOptions(){
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'Test Opportunity'];

        Test.setCurrentPage(Page.EditTiers);
        ApexPages.StandardController opportunityController = new ApexPages.StandardController(opp);
        EditTiersExt editTiersExt = new EditTiersExt(opportunityController);
        
        List<SelectOption> tier2Options = editTiersExt.getNewTier2Options();
        for (SelectOption so2: tier2Options) {
            System.debug(so2);
        }
        
        List<SelectOption> tier3Options = editTiersExt.getNewTier3Options();
        for (SelectOption so3: tier3Options) {
            System.debug(so3);
        }
        
        List<SelectOption> tier4Options = editTiersExt.getNewTier4Options();
        for (SelectOption so4: tier4Options) {
            System.debug(so4);
        }
        
        List<SelectOption> tier5Options = editTiersExt.getNewTier5Options();
        for (SelectOption so5: tier5Options) {
            System.debug(so5);
        }
        List<SelectOption> tier6Options = editTiersExt.getNewTier6Options();
        for (SelectOption so6: tier6Options) {
            System.debug(so6);
        }
    }
    
    @isTest static void verifyEditTiers(){
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'Test Opportunity'];
        Test.setCurrentPage(Page.EditTiers);
        ApexPages.StandardController opportunityController = new ApexPages.StandardController(opp);
        EditTiersExt editTiersExt = new EditTiersExt(opportunityController);
        
        Test.startTest();
            editTiersExt.tier1Options = 'Accountancy and Tax';
            editTiersExt.updateTier2Dropdown();
                editTiersExt.tier2Options = 'Apprenticeship';
                editTiersExt.updateTier3Dropdown();
                    editTiersExt.tier3Options = 'PQ';
                    editTiersExt.updateTier4Dropdown();
                    editTiersExt.tier3Options = 'Apprenticeship School (Level 2/3/4/5)';
                    editTiersExt.updateTier4Dropdown();
                editTiersExt.tier2Options = 'Bespoke';
                editTiersExt.updateTier3Dropdown();
                    editTiersExt.updateTier4Dropdown();
                editTiersExt.tier2Options = 'Public Non-Apps';
                editTiersExt.updateTier3Dropdown();
        			editTiersExt.tier3Options = 'Malaysia BPP';
                    editTiersExt.updateTier4Dropdown();
                    editTiersExt.tier3Options = 'PQ';
                    editTiersExt.updateTier4Dropdown();

            editTiersExt.tier1Options = 'Actuarial Education';
            editTiersExt.updateTier2Dropdown();
                editTiersExt.tier2Options = 'Apprenticeship';
                editTiersExt.updateTier3Dropdown();
                    editTiersExt.tier3Options = 'ActEd';
                    editTiersExt.updateTier4Dropdown();
                editTiersExt.tier2Options = 'Public Non-Apps';
                editTiersExt.updateTier3Dropdown();
                    editTiersExt.tier3Options = 'ActEd';
                    editTiersExt.updateTier4Dropdown();
        			editTiersExt.tier3Options = 'Malaysia BPP';
                    editTiersExt.updateTier4Dropdown();

            editTiersExt.tier1Options = 'Banking / Insurance / FS';
            editTiersExt.updateTier2Dropdown();
                editTiersExt.tier2Options = 'Apprenticeship';
                editTiersExt.updateTier3Dropdown();
                    editTiersExt.tier3Options = 'Apprenticeship School (Level 2/3/4/5)';
                    editTiersExt.updateTier4Dropdown();
                    editTiersExt.tier3Options = 'School of FS (Level 2/3/4/5)';
                    editTiersExt.updateTier4Dropdown();
                    editTiersExt.tier3Options = 'School of FS (Level 6/7)';
                    editTiersExt.updateTier4Dropdown();
                editTiersExt.tier2Options = 'Bespoke';
                editTiersExt.updateTier3Dropdown();
                    editTiersExt.updateTier4Dropdown();
                editTiersExt.tier2Options = 'Public Non-Apps';
                editTiersExt.updateTier3Dropdown();
                    editTiersExt.tier3Options = 'Malaysia BPP';
                    editTiersExt.updateTier4Dropdown();
        			editTiersExt.tier3Options = 'PQ';
                    editTiersExt.updateTier4Dropdown();
        			editTiersExt.tier3Options = 'PQ (FS)';
                    editTiersExt.updateTier4Dropdown();

            editTiersExt.tier1Options = 'DTS / MSC in Data Analytics';
            editTiersExt.updateTier2Dropdown();
                editTiersExt.tier2Options = 'Apprenticeship';
                editTiersExt.updateTier3Dropdown();
                    editTiersExt.tier3Options = 'School of Technology (Level 6/7)';
                    editTiersExt.updateTier4Dropdown();
                editTiersExt.tier2Options = 'Public Non-Apps';
                editTiersExt.updateTier3Dropdown();
        			editTiersExt.tier3Options = 'Malaysia BPP';
                    editTiersExt.updateTier4Dropdown();
                    editTiersExt.tier3Options = 'School of Technology';
                    editTiersExt.updateTier4Dropdown();

            editTiersExt.tier1Options = 'GDA / wrap';
            editTiersExt.updateTier2Dropdown();
                editTiersExt.tier2Options = 'Bespoke';
                editTiersExt.updateTier3Dropdown();
                    editTiersExt.tier3Options = 'School of Business';
                    editTiersExt.updateTier4Dropdown();

            editTiersExt.tier1Options = 'Health';
            editTiersExt.updateTier2Dropdown();
                editTiersExt.tier2Options = 'Apprenticeship';
                editTiersExt.updateTier3Dropdown();
                    editTiersExt.tier3Options = 'School of Nursing';
                    editTiersExt.updateTier4Dropdown();
                editTiersExt.tier2Options = 'Bespoke';
                editTiersExt.updateTier3Dropdown();
                    editTiersExt.updateTier4Dropdown();
                editTiersExt.tier2Options = 'Public Non-Apps';
                editTiersExt.updateTier3Dropdown();
        			editTiersExt.tier3Options = 'Malaysia BPP';
                    editTiersExt.updateTier4Dropdown();
                    editTiersExt.tier3Options = 'School of Health';
                    editTiersExt.updateTier4Dropdown();
                    editTiersExt.tier3Options = 'School of Nursing';
                    editTiersExt.updateTier4Dropdown();

            editTiersExt.tier1Options = 'HR / Management / Business Admin';
            editTiersExt.updateTier2Dropdown();
                editTiersExt.tier2Options = 'Apprenticeship';
                editTiersExt.updateTier3Dropdown();
                    editTiersExt.tier3Options = 'Apprenticeship School (Level 2/3/4/5)';
                    editTiersExt.updateTier4Dropdown();
                    editTiersExt.tier3Options = 'Apprenticeship School (Level 6/7)';
                    editTiersExt.updateTier4Dropdown();
        			editTiersExt.tier3Options = 'School of Business (Level 6/7)';
                    editTiersExt.updateTier4Dropdown();
                editTiersExt.tier2Options = 'Bespoke';
                editTiersExt.updateTier3Dropdown();
                    editTiersExt.updateTier4Dropdown();
        		editTiersExt.tier2Options = 'Public Non-Apps';
                editTiersExt.updateTier3Dropdown();
                    editTiersExt.tier3Options = 'Apprenticeship School (Level 2/3/4/5)';
        			editTiersExt.updateTier4Dropdown();

            editTiersExt.tier1Options = 'International';
            editTiersExt.updateTier2Dropdown();
                editTiersExt.tier2Options = 'Bespoke';
                editTiersExt.updateTier3Dropdown();
                    editTiersExt.tier3Options = 'School of Technology';
                    editTiersExt.updateTier4Dropdown();
                    editTiersExt.tier3Options = 'PD';
                    editTiersExt.updateTier4Dropdown();
                editTiersExt.tier2Options = 'Public Non-Apps';
                editTiersExt.updateTier3Dropdown();
        			editTiersExt.tier3Options = 'Apprenticeship School (Level 2/3/4/5)';
                    editTiersExt.updateTier4Dropdown();
                    editTiersExt.tier3Options = 'PD';
                    editTiersExt.updateTier4Dropdown();
                    editTiersExt.tier3Options = 'Romania BPP';
                    editTiersExt.updateTier4Dropdown();
                    editTiersExt.tier3Options = 'Channel Islands';
                    editTiersExt.updateTier4Dropdown();
        			editTiersExt.tier3Options = 'Malaysia BPP';
                    editTiersExt.updateTier4Dropdown();

            editTiersExt.tier1Options = 'Law';
            editTiersExt.updateTier2Dropdown();
                editTiersExt.tier2Options = 'Apprenticeship';
                editTiersExt.updateTier3Dropdown();
                    editTiersExt.tier3Options = 'Law School';
                    editTiersExt.updateTier4Dropdown();
                editTiersExt.tier2Options = 'Public Non-Apps';
                editTiersExt.updateTier3Dropdown();
                    editTiersExt.tier3Options = 'Law School';
                    editTiersExt.updateTier4Dropdown();
        			editTiersExt.tier3Options = 'Malaysia BPP';
                    editTiersExt.updateTier4Dropdown();

            editTiersExt.tier1Options = 'Other';
            editTiersExt.updateTier2Dropdown();
                editTiersExt.tier2Options = 'Apprenticeship';
                editTiersExt.updateTier3Dropdown();
                    editTiersExt.updateTier4Dropdown();
                editTiersExt.tier2Options = 'Bespoke';
                editTiersExt.updateTier3Dropdown();
                    editTiersExt.updateTier4Dropdown();
                editTiersExt.tier2Options = 'Other';
                editTiersExt.updateTier3Dropdown();
                    editTiersExt.updateTier4Dropdown();
                editTiersExt.tier2Options = 'Public Non-Apps';
                editTiersExt.updateTier3Dropdown();
                    editTiersExt.updateTier4Dropdown();

            editTiersExt.tier1Options = 'Other Technology Products';
            editTiersExt.updateTier2Dropdown();
                editTiersExt.tier2Options = 'Accelerated Training';
                editTiersExt.updateTier3Dropdown();
                editTiersExt.tier3Options = 'Firebrand';
                editTiersExt.updateTier4Dropdown();
                editTiersExt.tier2Options = 'Apprenticeship';
                editTiersExt.updateTier3Dropdown();
                editTiersExt.tier3Options = 'Apprenticeship School (Level 2/3/4/5)';
                editTiersExt.updateTier4Dropdown();
                editTiersExt.tier3Options = 'Estio';
                editTiersExt.updateTier4Dropdown();
                editTiersExt.tier3Options = 'Firebrand';
                editTiersExt.updateTier4Dropdown();
                editTiersExt.tier3Options = 'School of Technology';
                    editTiersExt.updateTier4Dropdown();
                editTiersExt.tier2Options = 'Bespoke';
                editTiersExt.updateTier3Dropdown();
                    editTiersExt.tier3Options = 'Data Assembly';
                    editTiersExt.updateTier4Dropdown();
                    editTiersExt.tier3Options = 'School of Technology';
                    editTiersExt.updateTier4Dropdown();
                editTiersExt.tier2Options = 'Key Skills Series';
                editTiersExt.updateTier3Dropdown();
                    editTiersExt.tier3Options = 'School of Technology';
                    editTiersExt.updateTier4Dropdown();
        		editTiersExt.tier2Options = 'Skills Bootcamps';
                editTiersExt.updateTier3Dropdown();
                    editTiersExt.tier3Options = 'Firebrand';
                    editTiersExt.updateTier4Dropdown();

            editTiersExt.tier1Options = 'Professional Development';
            editTiersExt.updateTier2Dropdown();
                editTiersExt.tier2Options = 'Bespoke';
                editTiersExt.updateTier3Dropdown();
                    editTiersExt.tier3Options = 'PD';
                    editTiersExt.updateTier4Dropdown();
                editTiersExt.tier2Options = 'Public Non-Apps';
                    editTiersExt.updateTier3Dropdown();
        				editTiersExt.tier3Options = 'Malaysia BPP';
                    	editTiersExt.updateTier4Dropdown();
                        editTiersExt.tier3Options = 'PD';
                        editTiersExt.updateTier4Dropdown();
                editTiersExt.tier2Options = 'Key Skills Series';
                editTiersExt.updateTier3Dropdown();
                    editTiersExt.tier3Options = 'PD';
                    editTiersExt.updateTier4Dropdown();
                        editTiersExt.tier4Options = 'Capability Analysis';
                        editTiersExt.updateTier5Dropdown();
                            editTiersExt.tier5Options = 'Online Demand';
                            editTiersExt.updateTier6Dropdown();
                                editTiersExt.tier6Options = '--None--';

            editTiersExt.tier1Options = 'Risk / Compliance / Financial Crime';
            editTiersExt.updateTier2Dropdown();
                editTiersExt.tier2Options = 'Apprenticeship';
                editTiersExt.updateTier3Dropdown();
                    editTiersExt.tier3Options = 'PQ (FS, Level 6/7)';
                    editTiersExt.updateTier4Dropdown();
                    editTiersExt.tier3Options = 'School of FS (Level 2/3/4/5)';
                    editTiersExt.updateTier4Dropdown();
                    editTiersExt.tier3Options = 'School of FS (Level 6/7)';
                    editTiersExt.updateTier4Dropdown();
                editTiersExt.tier2Options = 'Bespoke';
                editTiersExt.updateTier3Dropdown();
                    editTiersExt.updateTier4Dropdown();

            editTiersExt.tier1Options = 'UG / PG';
            editTiersExt.updateTier2Dropdown();
                editTiersExt.tier2Options = 'Bespoke';
                editTiersExt.updateTier3Dropdown();
                    editTiersExt.updateTier4Dropdown();
                editTiersExt.tier2Options = 'Public Non-Apps';
                editTiersExt.updateTier3Dropdown();
        			editTiersExt.tier3Options = 'Malaysia BPP';
                    editTiersExt.updateTier4Dropdown();
                    editTiersExt.tier3Options = 'School of Business';
                    editTiersExt.updateTier4Dropdown();
                        editTiersExt.tier4Options = 'MSc Management';
                        editTiersExt.updateTier5Dropdown();
                            editTiersExt.tier5Options = 'Mixed Recruitment Type';
                            editTiersExt.updateTier6Dropdown();
        
            PageReference redPage = editTiersExt.save();
        Test.stopTest();

        Opportunity verifyOpportunityUpdate = [SELECT Id, Tier_1__c, Tier_2__c, Tier_3__c, Tier_4__c, Tier_5__c, Tier_6__c FROM Opportunity where Id =: editTiersExt.opp.Id];
        System.assert(verifyOpportunityUpdate.Id != NULL);
        String oppId = (verifyOpportunityUpdate != NULL ? String.valueof(verifyOpportunityUpdate.Id) : NULL);
        String oppId15 = (oppId != NULL ? oppId.left(15) : NULL);
                        
        System.assert(verifyOpportunityUpdate.Tier_1__c == 'UG / PG');
        System.assert(verifyOpportunityUpdate.Tier_2__c == 'Public Non-Apps');
        System.assert(verifyOpportunityUpdate.Tier_3__c == 'School of Business');
        System.assert(verifyOpportunityUpdate.Tier_4__c == 'MSc Management');
        System.assert(verifyOpportunityUpdate.Tier_5__c == 'Mixed Recruitment Type');
        System.assert(verifyOpportunityUpdate.Tier_6__c == NULL);
        
        if (oppId15 != NULL) {   
        	System.assertEquals('/'+oppId15, redPage.getUrl());
        }
    }
}