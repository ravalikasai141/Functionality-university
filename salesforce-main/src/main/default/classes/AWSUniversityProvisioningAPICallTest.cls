@isTest
private class AWSUniversityProvisioningAPICallTest {
    @testSetup
    static void testSetup() {
        Authorisation_Token__c authToken = TestDataFactory.createAuthorisationToken(true);
        Account account = TestDataFactory.createAccount(true, true, 0);

        Programme__c programme = new Programme__c();
        programme.Name = 'Test Program';
        programme.BNR_FieldOfStudy_Code__c = 'ELEC';
        programme.Microsite_Enabled__c = true;
        programme.Programme_Status__c = 'Validated';
        programme.School__c = 'Test School';
        insert programme;

        Product2 product = new Product2();
        product.IsActive = true;
        product.Name = 'Test Course Instance';
        product.Programme__c = programme.Id;
        product.Mode__c = 'Full Time';
        product.Location__c = 'London - London City';
        product.Start_Date__c = system.today();
        product.BNR_Admissions_Enabled__c = true;
        product.BNR_Term_Code__c = '212121';
        product.BNR_Attribute_Code__c = 'FT';
        product.BNR_Level_Code__c = 'UG';
        product.BNR_Campus_Code__c = 'LLC';
        product.BNR_Degree_Code__c = 'MS';
        product.BNR_Program_Code__c = 'ELEC';
        product.Instance_Id__c = '123456789012345';
        product.BNR_Min_Capacity__c = 5;
        product.BNR_Max_Capacity__c = 10;
        product.BNR_Price__c = 32423;
        product.Start_Date__c = Date.valueOf('2015-06-07');
        product.End_Date__c = Date.valueOf('2016-12-10');
        product.BNR_FieldOfStudy_Start_Date__c = Date.valueOf('2015-06-07');
        product.Platform__c = 'HUB';
        insert product;

        PC_Bundle__c pcB = CreateTestData.createBundle('bId33242', 'fName', 3243.3);
        PC_Item__c pcI = CreateTestData.createPCItem(product, pcB, programme);

        Digital_Content__c dc = new Digital_Content__c();
        dc.Active__c = true;
        dc.Host_System__c = 'Totara';
        dc.Programme__c = programme.Id;
        dc.System_Reference__c = 'Test';
        dc.Title__c = 'Test';
        insert dc;

        Opportunity opp = new Opportunity();
        opp.AccountId = account.Id;
        opp.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName()
            .get('Student_Application')
            .getRecordTypeId();
        opp.Name = 'test';
        opp.Enrolment_Status__c = 'Acceptance';
        opp.StageName = 'Accepted - Conditional Firm';
        opp.Cycle_Override__c = 'Use Student Cycle';
        opp.CloseDate = Date.valueOf('2015-02-27');
        opp.BNR_Application_Decision_Comment__c = 'ABCD';
        opp.SFDC_Attribute_Code_Select__c = 'FT~ Full Time Student';
        opp.SFDC_Admissions_ADMT_Code_Select__c = 'DI~ Direct';
        opp.SFDC_Admissions_STYPE_Code_Select__c = 'R~ Returning';
        opp.SFDC_Admissions_RESD_Code_Select__c = 'E~ EU National';
        opp.SFDC_Cohort_Code_Select__c = 'C6~ Cohort June';
        opp.BNR_Curriculum_Status_Code__c = 'ACTIVE';
        opp.Programme_Application__c = programme.Id;
        opp.Course_Instance__c = product.Id;
        insert opp;
    }

    @isTest
    static void itShouldInitialiseProvisioningCalloutFromAccountAndCreateAnIntegrationLog() {
        Account account = [SELECT Id FROM Account LIMIT 1];

        Test.startTest();
        account.HUB_Student__c = true;
        account.BNR_Banner_ID__pc = '12345678';
        account.Email_Address__pc = 'test@my.bpp.com';
        account.Password__pc = 'abc123';
        update account;

        Test.setMock(HttpCalloutMock.class, new AWSCalloutMock());
        Test.stopTest();

        List<Integration_Log__c> integrationLogList = [SELECT Id FROM Integration_Log__c];
        Assert.isTrue(
            integrationLogList.size() > 0,
            'Integration Logs for provisioning callout should have been created.'
        );
    }
}
