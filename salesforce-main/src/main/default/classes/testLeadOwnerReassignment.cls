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
private class testLeadOwnerReassignment {

    static testMethod void myUnitTest() {
        
        User thisUser = [Select Id From User where Id = :UserInfo.getUserId()];
        System.runas(thisUser) {
        
            Userrole ur = [Select Id FROM UserRole WHERE DeveloperName = 'DomesticTeamRecordAssignment'];
            //Profile p = [SELECT Id FROM Profile WHERE Name='Standard User']; 
            
            User u1 = new User(Alias = 'aNewUser', Email='anewuser@testorg.com', 
                             EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
                             LocaleSidKey='en_US', ProfileId = '00eb0000000qUodAAE', UserRoleId = ur.Id,
                             TimeZoneSidKey='America/Los_Angeles', UserName='anewuser@testorg.com');
    
            insert u1;
            User u2 = new User(Alias = 'bNewUser', Email='bnewuser@testorg.com', 
                             EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
                             LocaleSidKey='en_US', ProfileId = '00eb0000000qUodAAE', UserRoleId = ur.Id,
                             TimeZoneSidKey='America/Los_Angeles', UserName='bnewuser@testorg.com');
            insert u2;
            
            
            system.debug('u1 id: ' + u1.Id);
            system.debug('u2 id: ' + u2.Id);
            
            RFI_Owner_Change__c roc = new RFI_Owner_Change__c();
            roc.Name = 'bNewUser';
            roc.userid__c = u2.Id;
            roc.Destination_Role__c = 'DomesticTeamRecordAssignment';
            insert roc;
            
            country_list__c clist = new country_list__c(Name = 'Unit Test', ISO_Code__c = 'ABC', country_code_2__c = '12');
        insert clist;
            
            Lead l1 = New Lead();
            l1.OwnerId = u1.Id;
            l1.LastName = 'Test';
            l1.Birth_Date__c = Date.today().addYears(-20);
            l1.rfi_Are_you_EU_UK__c = 'UK (EU) Student';
            //l1.Country_of_Residence__c = 'USA';
            l1.Country_of_Residence__c = clist.id;
            insert l1;
            
            test.startTest();
            l1.OwnerId = u2.Id;
            update l1;
            test.stopTest();
            
            System.assertEquals(l1.OwnerId, u2.Id);
        }
    }
}