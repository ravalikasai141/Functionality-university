@isTest
public class SubmitApplicationHandlerTest {
    @TestSetup
    static void setup() {
        Id opportunityRecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName()
            .get('Apprentice_Application')
            .getRecordTypeId();

        Id accountRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
            .get('Student_Account')
            .getRecordTypeId();

        Legal_Entity__c setting = new Legal_Entity__c();
        setting.Name = 'UC~COL';
        setting.Entity__c = 'COL';
        setting.AR_Integration__c = true;
        insert setting;

        Country_List__c country = new Country_List__c(
            Name = 'United Kingdom',
            Valid_Domicile__c = true,
            Valid_Nationality__c = true,
            country_code_2__c = 'GB',
            ISO_CODE__c = 'GB',
            enabled__c = true
        );
        insert country;

        Programme__c programme = new Programme__c(
            Name = 'Test programme',
            Programme_Id__c = 'P-123',
            BNR_FieldOfStudy_Code__c = '123',
            BNR_College_Code__c = '123'
        );
        insert programme;

        Product2 product = new Product2(
            Name = 'Test Course',
            BPP_ProductFactoryID__c = 'test-123',
            Instance_Id__c = 'test-1234',
            Programme__c = programme.Id,
            Mode__c = 'Full',
            Start_Date__c = Date.today(),
            End_Date__c = Date.today() + 365,
            BNR_FieldOfStudy_Start_Date__c = Date.today(),
            Product_Type__c = SubmitApplicationHandler.OFFERING_PRDTYPE,
            BNR_Degree_Code__c = '123',
            BNR_Campus_Code__c = '123',
            BNR_Level_Code__c = '123',
            BNR_Term_Code__c = '123'
        );
        insert product;

        Account acc = new Account(
            FirstName = 'Test',
            LastName = 'Test',
            RecordTypeId = accountRecordTypeId,
            PS_Profile_Services_ID__pc = 'ID-123',
            PersonBirthdate = Date.newInstance(2002, 2, 1),
            Primary_Nationality__pc = country.Id,
            Student_Type__pc = 'Domestic',
            Legal_Entity__c = 'UC~COL',
            Country_of_Permanent_Address__c = country.Id
        );
        insert acc;

        insert new Address__c(Type__c = 'Home', Street_1__c = '1', Student__c = acc.Id);

        Opportunity opp = new Opportunity(
            RecordTypeId = opportunityRecordTypeId,
            AccountId = acc.Id,
            Name = 'Test Opportunity',
            StageName = 'Application',
            CloseDate = Date.today() + 30,
            Application_Id__c = 'test-1234',
            Pricebook2Id = Test.getStandardPricebookId(),
            Course_Instance__c = product.Id,
            Purchase_Order_Number__c = '123',
            Sponsorship_Level__c = 'Partial',
            Sponsorship_Amount__c = 10.0,
            Customer_Group__c = 'group',
            SFDC_Attribute_Code_Select_v2__c = 'UC~COL',
            PC_Attribute_Code__c = '123',
            PC_Attribute_Code_2__c = '123',
            PC_Attribute_Code_3__c = '123'
        );
        insert opp;

        opp.StageName = 'Acceptance';
        opp.BPP_Sub_Status__c = 'Completed';
        update opp;
    }

    @isTest
    private static void itShouldSubmitApplicationSuccessfully() {
        // Mock respose from submitApplication
        SubmitApplicationHandler.applicationResult = new HttpResponse();
        SubmitApplicationHandler.applicationResult.setStatus('OK');
        SubmitApplicationHandler.applicationResult.setStatusCode(200);
        SubmitApplicationHandler.applicationResult.setBody(
            '<?xml version="1.0" encoding="utf-8"?>\n<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:platform="http://platform.apollogrp.edu/gateway" xmlns:wsse="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd" xmlns:per="http://platform.apollogrp.edu/services/apolloglobal/person/PersonService"><soapenv:Header><gateway:transactionId xmlns:gateway="http://platform.apollogrp.edu/gateway">4C7D57D0-35AE-3034-1A99-30F1672ED186</gateway:transactionId></soapenv:Header><soapenv:Body><per:getStudentIDByProfileIDResponse><per:studentID>BP0015527</per:studentID></per:getStudentIDByProfileIDResponse></soapenv:Body></soapenv:Envelope>'
        );
        // ARStudentAccountService and BNR_SubmitApplication mock result for tests within the class
        UpdateSISPerson.mockResponse = '{"companyId":"1234f567-bc23-42e8-924c-1234asdf5678","operation":"UPDATE", "success":true}';

        // GIVEN an Opp
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'Test Opportunity'];

        // WHEN checkApplication is called
        System.Test.startTest();
        String returnedMessage = SubmitApplicationHandler.checkApplication(opp.Id);
        System.Test.stopTest();

        // THEN a message is returned
        Assert.areEqual('Application Submitted', returnedMessage);
    }

    @isTest
    private static void itShouldShowErrorForFailedSubmitApplication() {
        // Mock respose from submitApplication
        SubmitApplicationHandler.applicationResult = new HttpResponse();
        SubmitApplicationHandler.applicationResult.setStatus('Internal Error');
        SubmitApplicationHandler.applicationResult.setStatusCode(500);
        SubmitApplicationHandler.applicationResult.setBody(
            '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/">' +
                '<soapenv:Header><gateway:' +
                'transactionId xmlns:gateway="http://platform.apollogrp.edu/gateway">' +
                'A4A3BF60-2BB1-2EFA-E334-8B03BE650CD0</gateway:transactionId>' +
                '</soapenv:Header>' +
                '<soapenv:Body>' +
                '<soapenv:Fault>' +
                '<faultcode>SOAP-ENV:Server</faultcode>' +
                '<faultstring>Error occurred invoking underlying service implementation' +
                '</faultstring>' +
                '<detail xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/">' +
                '<ns2:serviceFault ' +
                'xmlns:ns2="http://platform.apollogrp.edu/schemas/2010/05/28/ServiceFault">' +
                '<ns2:componentCode>15</ns2:componentCode><ns2:transactionId>' +
                'A4A3BF60-2BB1- 2EFA-E334-8B03BE650CD0</ns2:transactionId><ns2:errorCode> ' +
                'PLATFORM-999</ns2:errorCode><ns2:errorDescription> ' +
                'ORA-06512: at line 1' +
                '</ns2:errorDescription></ns2:serviceFault></detail></soapenv:Fault>' +
                '</soapenv:Body>' +
                '</soapenv:Envelope>'
        );

        // GIVEN an Opp
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'Test Opportunity'];

        // WHEN checkApplication is called
        System.Test.startTest();
        String returnedMessage = SubmitApplicationHandler.checkApplication(opp.Id);
        System.Test.stopTest();

        // THEN a message is returned
        Assert.isTrue(
            returnedMessage.contains('Submit Application Service Error'),
            'Expected: Submit Application Service Error, Actual: ' + returnedMessage
        );
    }

    @isTest
    private static void itShouldHandleARStudentAccountServiceError() {
        UpdateSISPerson.mockResponse = '{"companyId":"1234f567-bc23-42e8-924c-1234asdf5678","operation":"UPDATE", "success":true}';
        ARStudentAccountService.bFailARStudent = true;

        // GIVEN an Opp
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'Test Opportunity'];

        // WHEN checkApplication is called
        System.Test.startTest();
        String returnedMessage = SubmitApplicationHandler.checkApplication(opp.Id);
        System.Test.stopTest();

        // THEN a message is returned
        Assert.isTrue(
            returnedMessage.contains('ARStudentAccountService Error'),
            'Expect \'ARStudentAccountService Error\''
        );
    }

    @isTest
    private static void itShouldHandleStudentIDServiceError() {
        UpdateSISPerson.mockResponse = '{"companyId":"1234f567-bc23-42e8-924c-1234asdf5678","operation":"UPDATE", "success":true}';
        BNR_SubmitApplication.bFailStudentId = true;

        // GIVEN an Opp
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'Test Opportunity'];

        // WHEN checkApplication is called
        System.Test.startTest();
        String returnedMessage = SubmitApplicationHandler.checkApplication(opp.Id);
        System.Test.stopTest();

        // THEN a message is returned
        Assert.isTrue(returnedMessage.contains('StudentIDService Error'), 'Expect \'StudentIDService Error\'');
    }
}
