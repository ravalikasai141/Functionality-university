@isTest()
public class TEST_ProfileIntegrations_v2 {
    static final String codeValue = '123';
    
    @testSetup
    static void testSetup(){
        country_list__c country = new country_list__c(Name = 'Test Country', ISO_Code__c = codeValue, country_code_2__c = '12', enabled__c = true, Valid_Domicile__c = true, Valid_Nationality__c = true);
        insert country;
        
        State_Province__c state = new State_Province__c(Name = 'Test State', ISO_Code__c = codeValue);
        insert state;
        
        Locality__c locality = new Locality__c(Name = 'Test Locality', Banner_Code__c = codeValue);
        insert locality;
        
        Account account = TestDataFactory.createAccount('Fred', 'Smith', 'Personal', 'Mobile', 'Male', 'Mr', country.Id, false, true);
    }
    
    static testMethod void itShouldCallProfileIntAndPopulateProfileId() {
        country_list__c country = [SELECT Id FROM country_list__c LIMIT 1];
        Account account = [SELECT Id FROM Account LIMIT 1];
        
        TestDataFactory.createAddress(account.Id, null, country.Id, 'Mailing');
        Opportunity opportunity = CreateTestData.createOpportunity(account);
        Programme__c programme = CreateTestData.createProgram();
        Product2 product = CreateTestData.createProduct(programme, 'OFFERING');
        
        Contact contact = [SELECT Id FROM Contact WHERE AccountId =: account.Id];
        Qualification__c qual = new Qualification__c();
        qual.Student_Institute__c = 'test';
        qual.Examing_Body__c = 'test';
        qual.Student_Institute__c = 'test';
        qual.Student__c = contact.Id;
        insert qual;
        
        Test.startTest();
        Opportunity_Product__c opportunityProduct = new Opportunity_Product__c();
        opportunityProduct.Opportunity__c = opportunity.Id;
        opportunityProduct.Product__c = product.Id;
        opportunityProduct.Course_Focus__c = 'Primary';
        insert opportunityProduct;

        String result = ProfileIntegrations_v2.ProfileInt_v2(account.Id);
        Test.stopTest();
        
        Assert.areEqual('Success', result);
        Account accountAfter = [SELECT PS_Profile_Services_ID__pc FROM Account WHERE Id =: account.Id LIMIT 1];
        Assert.areNotEqual(null, accountAfter.PS_Profile_Services_ID__pc);
    }
    
    static testMethod void itShouldTriggerProfileIntegrationsOnAccountUpdateAndSucceed() {
        country_list__c country = [SELECT Id FROM country_list__c LIMIT 1];
        Account account = TestDataFactory.createAccount('TestAccount', 'Student', 'Personal', 'Home', 'Male', 'Mr', country.Id, true, false);
        
        Test.startTest();
        update account;
        Test.stopTest();
        
        List<Integration_Log__c> integLogList = [SELECT Response__c FROM Integration_Log__c];
        verifyIntegrationLogs(integLogList, 2, 'Success');
    }
    
    static testMethod void itShouldTriggerProfileIntegrationsOnAccountUpdateWithAddressAndSucceed() {
        country_list__c country = [SELECT Id FROM country_list__c LIMIT 1];
        
        Account account = TestDataFactory.createAccount('TestAccount', 'Student', 'Personal', 'Work', 'Female', 'Mrs', country.Id, true, false);
        TestDataFactory.createAddress(account.Id, null, country.Id, 'Next of Kin/Emergency/Guardian');
        
        Test.startTest();
        update account;
        Test.stopTest();
        
        List<Integration_Log__c> integLogList = [SELECT Response__c FROM Integration_Log__c];
        verifyIntegrationLogs(integLogList, 2, 'Success');
    }
    
    static testMethod void itShouldTriggerProfileIntegrationsOnAccountUpdateWithAddressAndSucceed2() {
        country_list__c country = [SELECT Id FROM country_list__c LIMIT 1];
        
        Account account = TestDataFactory.createAccount('TestAccount', 'Student', 'BPP', 'Parents/Guardian/Emergency', 'Female', 'Mrs', country.Id, true, false);
        TestDataFactory.createAddress(account.Id, null, country.Id, 'Mailing');
        
        Test.startTest();
        update account;
        Test.stopTest();
        
        List<Integration_Log__c> integLogList = [SELECT Response__c FROM Integration_Log__c];
        verifyIntegrationLogs(integLogList, 2, 'Success');
    }
    
    static testMethod void itShouldTriggerProfileIntegrationsOnAccountUpdateAndFail() {
        Account account = TestDataFactory.createAccount(false, true, 0);
        account.PS_Profile_Services_ID__pc = '1234xxx5-xxx1-1x2x-xxx1-12345x678x9';
        insert account;
        
        Test.startTest();
        ProfileIntegrations_v2.bFailSIS = true;
        update account;
        Test.stopTest();
        
        List<Integration_Log__c> integLogList = [SELECT Response__c FROM Integration_Log__c];
        verifyIntegrationLogs(integLogList, 2, 'Exception');
    }
    
    static testMethod void itShouldCallCreatePersonInfoLeadAndPopulateProfileId() {
        country_list__c country = [SELECT Id FROM country_list__c LIMIT 1];
        Lead lead = TestDataFactory.createLead('Paulus', 'Pluto', 'Personal', 'Work', 'Male', country.Id);
        
        Test.startTest();
        String result = ProfileIntegrations_v2.ProfileLeadInt_v2(lead.Id);
        Test.stopTest();
        
        Assert.areEqual('Success', result);
        Lead leadAfter = [SELECT PS_Profile_Services_ID__c FROM Lead WHERE Id =: lead.Id LIMIT 1];
        Assert.areNotEqual(null, leadAfter.PS_Profile_Services_ID__c);
    }
    
    static testMethod void itShouldCallCreatePersonInfoLeadWithAddressAndPopulateProfileId() {
        country_list__c country = [SELECT Id FROM country_list__c LIMIT 1];
        
        Lead lead = TestDataFactory.createLead('Florence', 'Pate', 'Work', 'Home', 'Female', country.Id);
        TestDataFactory.createAddress(null, lead.Id, country.Id, 'Home');
        
        Test.startTest();
        String result = ProfileIntegrations_v2.ProfileLeadInt_v2(lead.Id);
        Test.stopTest();
        
        Assert.areEqual('Success', result);
        Lead leadAfter = [SELECT PS_Profile_Services_ID__c FROM Lead WHERE Id =: lead.Id LIMIT 1];
        Assert.areNotEqual(null, leadAfter.PS_Profile_Services_ID__c);
    }
    
    static testMethod void itShouldCallCreatePersonInfoLeadAndFail() {
        country_list__c country = [SELECT Id FROM country_list__c LIMIT 1];
        
        Lead lead = TestDataFactory.createLead('Keith', 'Test', 'Work', 'Home', 'Male', country.Id);
        TestDataFactory.createAddress(null, lead.Id, country.Id, 'Next of Kin/Emergency/Guardian');
        
        Test.startTest();
        ProfileIntegrations_v2.bFailSIS = true;
        String result = ProfileIntegrations_v2.ProfileLeadInt_v2(lead.Id);
        Test.stopTest();
        
        Assert.areNotEqual('Success', result);
        List<Integration_Log__c> integLogList = [SELECT Response__c FROM Integration_Log__c];
        verifyIntegrationLogs(integLogList, 2, 'Exception');
    }

    public static void verifyIntegrationLogs(List<Integration_Log__c> integLogList, Integer integSize, String expectedResponse) {
        Assert.areEqual(integSize, integLogList.size());
        for (Integration_Log__c integLog : integLogList) {
            if (integLog.Response__c != null) {
                Assert.isTrue(integLog.Response__c.contains(expectedResponse));
            }
        }
    }
}