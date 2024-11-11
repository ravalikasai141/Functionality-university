@istest
public class LearnerApplicationServiceTest {
    @testSetup
    static void testSetup(){
        String ownerId = UserInfo.getUserId().left(15);
        AssignmentUsers__c assignmentUser = new AssignmentUsers__c();
        assignmentUser.Default_Admissions_Owner__c = ownerId;
        assignmentUser.Default_International_Owner__c = ownerId;
        insert assignmentUser;

        Id userId = [SELECT Id FROM User WHERE UserRole.Name = 'Domestic Team [+Record Assignment]' AND IsActive = true ORDER BY Name LIMIT 1].Id;
        Owner_Assignment__c ownerAssignment = new Owner_Assignment__c(Name = 'Domestic Team [+Record Assignment]', Last_Assignee__c = userId);
        insert ownerAssignment;
        
        country_list__c cntry = CreateTestData.createCountry1();
        Account account1 = new Account();
        account1.FirstName = 'Homer';
        account1.LastName = 'Simpson';
        account1.PersonBirthDate = Date.newInstance(1970,05,05);
        account1.Personal_Email__pc = 'homersimpson@testmail.com';
        account1.Preferred_Email__pc = 'Home';
        account1.PersonHomePhone = '+447713493882';
        account1.Preferred_Phone__pc = 'Home';
        account1.Primary_Nationality__pc = cntry.Id;
        account1.Student_Type__pc = 'Domestic';
        account1.UCAS_Number__pc = 'UCAS10293847';
        account1.Gender__pc = 'Male';
        account1.Legal_Entity__c = 'UC~COL';
        account1.OwnerId = AssignmentUsers__c.getInstance().Default_Admissions_Owner__c;
        insert account1;

        Account account2 = new Account();
        account2.FirstName = 'Montgomery';
        account2.LastName = 'Burns';
        account2.PersonBirthDate = Date.newInstance(1950,05,05);
        account2.Personal_Email__pc = 'montgomeryburns@testmail.com';
        account2.Preferred_Email__pc = 'Home';
        account2.PersonHomePhone = '+447715839209';
        account2.Preferred_Phone__pc = 'Home';
        account2.Primary_Nationality__pc = cntry.Id;
        account2.Student_Type__pc = 'Domestic';
        account2.UCAS_Number__pc = 'UCAS03938272';
        account2.Gender__pc = 'Male';
        account2.Legal_Entity__c = 'UC~COL';
        account2.OwnerId = AssignmentUsers__c.getInstance().Default_Admissions_Owner__c;
        insert account2;

        Programme__c pgrm = new Programme__c(
            Name = 'Test Program',
            BNR_FieldOfStudy_Code__c = 'ELEC',
            BNR_College_Code__c = '12345678',
            Microsite_Enabled__c = true,
            Programme_Status__c = 'Validated',
            School__c = 'Test School',
            Programme_Id__c = 'SBGLD1_sb8'
        );
        insert pgrm;

        Product2 pd = CreateTestData.createProduct(pgrm, 'OFFERING');
        PC_Bundle__c pcB = CreateTestData.createBundle('bId33242', 'fName', 3243.3);
        PC_Item__c pcI = CreateTestData.createPCItem(pd, pcB, pgrm);

        Opportunity opportunity = new Opportunity();
        opportunity.AccountId = account2.Id;
        opportunity.CloseDate = Date.valueOf('2027-01-01');
        opportunity.Course_Instance__c = pd.Id;
        opportunity.Enrolment_Status__c = 'Acceptance';
        opportunity.Name = 'Test';
        opportunity.Record_Source__c = 'UCAS';
        opportunity.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Application').getRecordTypeId();
        opportunity.StageName = 'Accepted - Conditional Firm';
        insert opportunity;
    }

    private static LearnerApplicationService.RequestWrapper buildRequestWrapper(Id productId) {
        LearnerApplicationService.RequestWrapper rw = new LearnerApplicationService.RequestWrapper();
        rw.applicationDate = '2023-05-01';
        rw.closeDate = '2023-05-01';
        rw.offeringId  = productId;
        rw.offerType = 'Conditional';
        rw.source = 'UCAS';
        rw.refereeEmail = 'testemail123@testmail.com';
        rw.refereeName = 'Sterling Archer';
        rw.soc2020 = '1111';
        rw.socioEconomicClassification = '01';
        rw.ucasChoiceNumber = '1';
        rw.ucasSchemeCode = 'UC01';
        return rw;
    }

    static testMethod void TestLearnerApplicationServiceTest_CreateOpportunity() {
        Account account = [SELECT Id FROM Account WHERE Personal_Email__pc = 'homersimpson@testmail.com'];
        Product2 product = [SELECT Id FROM Product2 WHERE Name = 'Test Course Instance'];
        LearnerApplicationService.RequestWrapper rw = buildRequestWrapper(product.Id);
        String jsonMsg = JSON.serialize(rw);

        Test.startTest();
            RestRequest req = new RestRequest(); 
            RestResponse res = new RestResponse();
            req.requestURI = '/services/apexrest/learners/'+ account.Id +'/applications';
            req.httpMethod = 'POST';
            req.requestBody = Blob.valueof(jsonMsg);
            RestContext.request = req;
            RestContext.response = res;

            LearnerApplicationService.Response resp = new LearnerApplicationService.Response();
            resp = LearnerApplicationService.doPost();
            String respString = String.valueOf(resp);
        	System.debug('Test 1: ' + respString);
            System.assert(respString.contains('response=LearnerApplicationService Success: Opportunity') && respString.contains('created'));
        Test.stopTest();
    }

    static testMethod void TestLearnerApplicationServiceTest_UpdateOpportunity() {
        Account account = [SELECT Id FROM Account WHERE Personal_Email__pc = 'montgomeryburns@testmail.com'];
        Product2 product = [SELECT Id FROM Product2 WHERE Name = 'Test Course Instance'];
        LearnerApplicationService.RequestWrapper rw = buildRequestWrapper(product.Id);
        String jsonMsg = JSON.serialize(rw);

        Test.startTest();
            RestRequest req = new RestRequest(); 
            RestResponse res = new RestResponse();
            req.requestURI = '/services/apexrest/learners/'+ account.Id +'/applications';
            req.httpMethod = 'POST';
            req.requestBody = Blob.valueof(jsonMsg);
            RestContext.request = req;
            RestContext.response = res;

            LearnerApplicationService.Response resp = new LearnerApplicationService.Response();
            resp = LearnerApplicationService.doPost();
            String respString = String.valueOf(resp);
        	System.debug('Test 2: ' + respString);
            System.assert(respString.contains('response=LearnerApplicationService Success: Opportunity') && respString.contains('updated'));
        Test.stopTest();
    }
}