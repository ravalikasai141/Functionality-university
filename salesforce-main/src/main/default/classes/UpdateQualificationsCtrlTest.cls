@isTest
public class UpdateQualificationsCtrlTest {
    static testmethod void testGetCompanyProfileId_noAddress() {
        Test.startTest();
            country_list__c cntry = CreateTestData.createCountry1();
            State_Province__c stt = CreateTestData.createStateProvince();
            Locality__c lct = CreateTestData.createLocality();
            
            Account a = CreateTestData.createAccount1(cntry);
            a.personHomePhone = '555-777-8888';
            a.Work_Phone__pc = '555-777-8888';
            a.Parents_Guardian_Emergency_Phone__pc = '555-777-8888';
            a.Fax = '555-777-8888';
            a.PersonMobilePhone ='111-222-3333';
            a.Personal_Email__pc = 'ktest@test.com';
            a.Work_Email__pc = 'ktest@test.com';
            a.BPP_Email__pc = 'ktest@test.com';
            a.Other_Email__pc = 'ktest@test.com';
            a.Billing_Email__pc = 'ktest@test.com';
            a.AR_Student_Finance_England_SFE__c = 'AAAA11112222F';
            update a;
                    
            Address__c addr = CreateTestData.createAddress(a, null, null, cntry, stt, lct, true, 'Billing');
            Opportunity o = CreateTestData.createOpportunity(a);
        
        	UpdateQualificationsCtrl.updateQualifications(o.Id);
        Test.stopTest();
    }
}