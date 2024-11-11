/**
 * This class contains unit tests for validating the behavior of Apex class AddressTriggerHandler
 */
@isTest
private class Test_updateFormattedPhoneonAccount {

    static testMethod void myUnitTest() {
        country_list__c cntry = CreateTestData.createCountry1();
        State_Province__c stt = CreateTestData.createStateProvince();
        Locality__c lct = CreateTestData.createLocality();
        Account a = CreateTestData.createAccount1(cntry);
        
        Contact tmC = CreateTestData.createTMContact();
        Test.startTest();
        Address__c addr = CreateTestData.createAddress(a, null, tmC, cntry, stt, lct, true, 'Mailing');
        try{
            addr = CreateTestData.createAddress(a, null, tmC, cntry, stt, lct, false, 'Home');
        }catch(Exception e){
            system.debug(e.getMessage());
        }
        Test.stopTest();
    }
    static testMethod void myUnitTest1() {
        country_list__c cntry = CreateTestData.createCountry1();
        cntry.Name = 'United Kingdom';
        update cntry;
        State_Province__c stt = CreateTestData.createStateProvince();
        Locality__c lct = CreateTestData.createLocality();
        Account a = CreateTestData.createAccount1(cntry);
        a.PersonMobilePhone = '9999999999';
        update a;
        Contact tmC = CreateTestData.createTMContact();
        Test.startTest();
        Address__c addr = CreateTestData.createAddress(a, null, tmC, cntry, stt, lct, true, 'Mailing');
        
        try{
            addr = CreateTestData.createAddress(a, null, tmC, cntry, stt, lct, false, 'Home');
            addr.Type__c = 'Mailing';
            update addr;
        }catch(Exception e){
            system.debug(e.getMessage());
        }
        Test.stopTest();
    }
    static testMethod void myUnitTest2() {
        country_list__c cntry = CreateTestData.createCountry1();
        cntry.Name = 'United Kingdom';
        update cntry;
        State_Province__c stt = CreateTestData.createStateProvince();
        Locality__c lct = CreateTestData.createLocality();
        Account a = CreateTestData.createAccount1(cntry);
        a.PersonMobilePhone = '9999999999';
        update a;
        Contact tmC = CreateTestData.createTMContact();
        Test.startTest();
        
        try{
           Address__c addr = CreateTestData.createAddress(a, null, tmC, cntry, stt, lct, false, 'Home');
            addr.Type__c = 'Mailing';
            update addr;
        }catch(Exception e){
            system.debug(e.getMessage());
        }
        Test.stopTest();
    }
}