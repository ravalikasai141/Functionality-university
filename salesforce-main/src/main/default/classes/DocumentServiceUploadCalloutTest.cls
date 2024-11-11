@isTest
public class DocumentServiceUploadCalloutTest {
    public static final String PRESIGNED_URL = 'salesforce.test.com';

    @TestSetup
    static void makeData() {
        Account studentAccount = new Account(
            FirstName = 'Test',
            LastName = 'Student',
            Preferred_Email__pc = 'Work',
            Work_Email__pc = 'teststudent1@mail.invalid',
            Preferred_Phone__pc = 'Mobile',
            PersonMobilePhone = '+447716123748',
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
                .get('Student_Account')
                .getRecordTypeId()
        );
        insert studentAccount;

        Hub_Account__c hubAccount = new Hub_Account__c(
            Student__c = studentAccount.Id,
            Hub_Username__c = studentAccount.Work_Email__pc,
            Auth0_Id__c = 'auth0|qwertyuiop'
        );
        insert hubAccount;

        Opportunity studentOpportunity = new Opportunity(
            AccountId = studentAccount.Id,
            Name = studentAccount.Name + ' Test Opp',
            StageName = 'Application',
            CloseDate = System.today(),
            RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName()
                .get('Student_Application')
                .getRecordTypeId()
        );
        insert studentOpportunity;
    }

    private static List<External_Document__c> initialiseExternalDocumentList(Id oppId, String auth0Id) {
        External_Document__c externalDocument = new External_Document__c(
            Category__c = 'CategoryTest',
            Content_Type__c = 'Document',
            Name = 'NameTest',
            Opportunity__c = oppId,
            User_ID__c = auth0Id
        );
        return new List<External_Document__c>{ externalDocument };
    }

    private static List<ContentVersion> initialiseContentVersionList(Id oppId) {
        Blob bodyBlob = Blob.valueOf('DocumentServiceUploadCalloutTest document.');
        ContentVersion contentVersion = new ContentVersion(
            Title = 'SampleTitle',
            PathOnClient = 'SampleTitle.doc',
            VersionData = bodyBlob,
            FirstPublishLocationId = oppId
        );
        return new List<ContentVersion>{ contentVersion };
    }

    private static List<DocumentServiceUploadCallout.FlowOutput> callUploadDocument(Id oppId, String auth0Id) {
        DocumentServiceUploadCallout.FlowInput flowInput = new DocumentServiceUploadCallout.FlowInput();
        flowInput.documentsToUpload = initialiseExternalDocumentList(oppId, auth0Id);
        flowInput.contentVersionList = initialiseContentVersionList(oppId);
        List<DocumentServiceUploadCallout.FlowOutput> flowOutputList = DocumentServiceUploadCallout.uploadDocument(
            new List<DocumentServiceUploadCallout.FlowInput>{ flowInput }
        );
        return flowOutputList;
    }

    private static List<External_Document__c> retrieveExternalDocumentRecords() {
        return new List<External_Document__c>(
            [
                SELECT Category__c, Content_Type__c, Name, Opportunity__c, User_ID__c
                FROM External_Document__c
            ]
        );
    }

    @isTest
    private static void itShouldReturnAUrlAndUploadDocument() {
        TestUtilities.mockKillswitch(Killswitch.DOCUMENT_SERVICE_KILLSWITCH, false);

        //GIVEN an Opportunity
        Opportunity opp = [SELECT Id, AccountId FROM Opportunity LIMIT 1];
        String auth0Id = [SELECT Auth0_Id__c FROM Hub_Account__c WHERE Student__c = :opp.AccountId].Auth0_Id__c;

        MockHttpClient mock = new MockHttpClient();
        mock.addResponse('@', 200, '{"data":{"getPresignedUploadUrl":{"preSignedUrl":"' + PRESIGNED_URL + '"}}}');

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, mock);
        // WHEN uploadDocument is called
        List<DocumentServiceUploadCallout.FlowOutput> flowOutputList = callUploadDocument(opp.Id, auth0Id);
        Test.stopTest();

        // THEN there should be a single option returned
        Assert.areEqual(1, flowOutputList.size(), 'One result should returned from Flow.');
        Assert.areEqual(true, flowOutputList.get(0).uploadResults.get(0).inserted, 'Record should have been created.');

        //AND an External Document record should have been created
        List<External_Document__c> externalDocumentList = retrieveExternalDocumentRecords();
        Assert.areEqual(1, externalDocumentList.size(), 'One External Document record should have been created.');
        Assert.areEqual(
            'CategoryTest',
            externalDocumentList.get(0).Category__c,
            'External Document Category should match input.'
        );
        Assert.areEqual(
            'Document',
            externalDocumentList.get(0).Content_Type__c,
            'External Document Content Type should match input.'
        );
        Assert.isTrue(
            externalDocumentList.get(0).Name.contains('NameTest'),
            'External Document Name should contain input.'
        );
        Assert.areEqual(
            opp.Id,
            externalDocumentList.get(0).Opportunity__c,
            'External Document Opportunity should match input.'
        );
        Assert.areEqual(
            auth0Id,
            externalDocumentList.get(0).User_ID__c,
            'External Document User Id should match input.'
        );
    }

    @isTest
    private static void itShouldHandleErrorResponse() {
        TestUtilities.mockKillswitch(Killswitch.DOCUMENT_SERVICE_KILLSWITCH, false);

        //GIVEN an Opportunity
        Opportunity opp = [SELECT Id, AccountId FROM Opportunity LIMIT 1];
        String auth0Id = [SELECT Auth0_Id__c FROM Hub_Account__c WHERE Student__c = :opp.AccountId].Auth0_Id__c;

        MockHttpClient mock = new MockHttpClient();
        mock.addResponse('@', 500);

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, mock);
        // WHEN uploadDocument is called
        List<DocumentServiceUploadCallout.FlowOutput> flowOutputList = callUploadDocument(opp.Id, auth0Id);
        Test.stopTest();

        // THEN there should be a single option returned
        Assert.areEqual(1, flowOutputList.size(), 'One result should returned from Flow.');
        Assert.areEqual(
            false,
            flowOutputList.get(0).uploadResults.get(0).inserted,
            'Record should have failed to create.'
        );

        //AND an External Document record should not have been created
        List<External_Document__c> externalDocumentList = retrieveExternalDocumentRecords();
        Assert.areEqual(0, externalDocumentList.size(), 'No External Document record should have been created.');
    }
}
