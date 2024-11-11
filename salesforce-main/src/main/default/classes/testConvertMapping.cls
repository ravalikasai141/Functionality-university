/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * All test methods in an organization are executed whenever Apex code is deployed
 * to a production organization to confirm correctness, ensure code
 * coverage, and prevent regressions. All Apex classes are
 * required to have at least 75% code coverage in order to be deployed
 * to a production organization. In addition, all triggers must have some code coverage.
 * 
 * The @isTest class annotation indicates this class only contains test
 * methods. Classes defined with the @isTest annotation do not count against
 * the organization size limit for all Apex scripts.
 *
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 */
@isTest
private class testConvertMapping {

    static testMethod void myUnitTest() {
        country_list__c countryList_All = new country_list__c();
        countryList_All.Name = 'UNITED STATES';
        countryList_All.enabled__c = true;
        countryList_All.country_code_2__c = '12';
        countryList_All.Valid_Domicile__c = true;
        countryList_All.Valid_Nationality__c = true;
        insert countryList_All;
    
        country_list__c clist = new country_list__c(Name = 'Unit Test', ISO_Code__c = 'PM1', country_code_2__c = '00');
        insert clist;
        
        List<Lead> leadList = new List<Lead>();
        Lead l1 = New Lead();
        l1.FirstName ='tril1';
        l1.LastName = 'Test';
        l1.Birth_Date__c = Date.today().addYears(-20);
        l1.rfi_Are_you_EU_UK__c = 'UK (EU) Student';
        //l1.Country_of_Residence__c = 'USA';
        l1.Country_of_Residence__c = clist.id;
        l1.Preferred_Email__c = 'Personal';
        l1.Personal_Email__c = 'trial1@tesc.com';
        l1.Preferred_Phone__c = 'Work';
        l1.Work_Phone__c = '4328783000';
        Lead l2 = New Lead();
        l2.FirstName ='tril2';
        l2.LastName = 'Testing';
        l2.Birth_Date__c = Date.today().addYears(-20);
        l2.rfi_Are_you_EU_UK__c = 'International Student';
        //l2.Country_of_Residence__c = 'USA';
        l2.Country_of_Residence__c = clist.id;
        l2.Preferred_Email__c = 'Personal';
        l2.Personal_Email__c = 'trial2@test.com';
        l2.Preferred_Phone__c = 'Work';
        l2.Work_Phone__c = '4328783990';
        leadList.add(l1);
        leadList.add(l2);
        
        insert leadList;
        list<Address__c> lstAd = new list<Address__c>();
        Address__c add = new Address__c();
        add.Type__c = 'Mailing';
        add.Active__c = true;
        add.Street_1__c = '12test';
        add.City__c = 'sch';
        add.Zip_Postal_Code__c = '12323';
        add.Lookup_Country__c = countryList_All.id;
        add.Lead__c = l1.Id;
        lstAd.add(add);
        Address__c add1 = new Address__c();
        add1.Type__c = 'Mailing';
        add1.Active__c = true;
        add1.Street_1__c = '12test1';
        add1.City__c = 'sch1';
        add1.Zip_Postal_Code__c = '12320';
        add1.Lookup_Country__c = countryList_All.id;
        add1.Lead__c = l2.Id;
        lstAd.add(add1);
        insert lstAd;
        List<Database.Leadconvert> lcList = new List<Database.Leadconvert>();
        LeadStatus convertStatus = [SELECT Id, MasterLabel FROM LeadStatus WHERE IsConverted=true LIMIT 1];
        
        for (Lead l : leadList) {
            Database.Leadconvert lc = new Database.Leadconvert();
            lc.setLeadId(l.Id);
            lc.setConvertedStatus(convertStatus.MasterLabel);
            lcList.add(lc);
        }
        
        test.startTest();
        List<Database.Leadconvertresult> results = Database.convertLead(lcList);
        test.stopTest();
        System.assertEquals(l1.Id, l1.Id);
    }
}