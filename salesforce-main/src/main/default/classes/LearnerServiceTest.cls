@istest
public class LearnerServiceTest {
    @testSetup
    static void testSetup() {
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

        List<Address__c> addressList = new List<Address__c>();
        addressList.add(TestDataFactory.createAddress(false, 0, account1, cntry, false, false));
        addressList.add(TestDataFactory.createAddress(false, 1, account1, cntry, false, false));
        addressList.get(0).Type__c = 'Home';
        addressList.get(1).Type__c = 'Mailing';
        insert addressList;
    }
    
    private static LearnerService.RequestWrapper buildRequestWrapper(String dob, String email, String firstname, String surname, String homePhone, String mobilePhone, Boolean optIn, String personalId, String recordSource, String salutation,
        String home1, String home2, String homePostCode, String homeCountryCode, String mailing1, String mailing2, String mailingPostCode, String mailingCountryCode) {
        LearnerService.RequestWrapper rw = new LearnerService.RequestWrapper();
        rw.careExperienceStatusCode = '97';
        rw.countryOfBirth = '12';
        rw.countryOfResidence = '12';
        rw.dateEnteredUK = '1970-01-01';
        rw.dateOfBirth = dob;
        rw.disabilities = '95';
        rw.disabilityFurtherDetails = 'N/A';
        rw.personalEmail = email;
        rw.marketingEmailOptIn = optIn;
        rw.ethnicityCode = '160';
        rw.firstname = firstname;
        rw.gender = 'Male';
        rw.homePhone = homePhone;
        rw.mobilePhone = mobilePhone;
        rw.nationality = '12';
        rw.passportExpiryDate = '2024-05-01';
        rw.passportIssueDate = '2020-05-01';
        rw.passportNumber = '193830101542';
        rw.passportPlaceOfIssue = 'Liverpool';
        rw.ucasNumber = personalId;
        rw.marketingPostOptIn = optIn;
        rw.recordSource = recordSource;
        rw.religionCode = '20';
        rw.scottishCandidateNumber = '654321';
        rw.secondaryNationality = 'GB';
        rw.surname = surname;
        rw.title = salutation;
        rw.marketingSmsOptIn = optIn;
        rw.uln = '123456';
        rw.sexualOrientationCode = '12';
        rw.mailingLine1 = mailing1;
        rw.mailingLine2 = mailing2;
        rw.mailingPostcode = mailingPostCode;
        rw.mailingCountryCode = mailingCountryCode;
        rw.homeLine1 = home1;
        rw.homeLine2 = home2;
        rw.homePostcode = homePostCode;
        rw.homeCountryCode = homeCountryCode;
        return rw;
    }

    static testMethod void TestLearnerServiceTest_AccountFound_UpdateAddress() {
        Account account = [SELECT Id, Personal_Email__pc, FirstName, LastName, PersonHomePhone, PersonBirthdate, UCAS_Number__pc FROM Account WHERE Personal_Email__pc = 'homersimpson@testmail.com'];
        LearnerService.RequestWrapper rw = buildRequestWrapper(String.valueOf(account.PersonBirthdate), account.Personal_Email__pc, account.FirstName, account.LastName, String.valueOf(account.PersonHomePhone), null, true, account.UCAS_Number__pc, 'UCAS', 'Mr', '10 Test Street', null, 'M0 1AD', '12', '11 Test Street', null, 'M1 1AD', '12');
        String jsonMsg = JSON.serialize(rw);

        Test.startTest();
            RestRequest req = new RestRequest(); 
            RestResponse res = new RestResponse();
            req.requestURI = '/services/apexrest/learners/';
            req.httpMethod = 'POST';
            req.requestBody = Blob.valueof(jsonMsg);
            RestContext.request = req;
            RestContext.response = res;

            LearnerService.Response resp = new LearnerService.Response();
            resp = LearnerService.doPost();
            String respString = String.valueOf(resp);
        	System.debug('Test 1: ' + respString);
            System.assert(respString.contains('response=LearnerService Success: Account') && respString.contains('updated'));
        Test.stopTest();
    }

    static testMethod void TestLearnerServiceTest_AccountFound_CreateAddress() {
        Account account = [SELECT Id, Personal_Email__pc, FirstName, LastName, PersonHomePhone, PersonBirthdate, UCAS_Number__pc FROM Account WHERE Personal_Email__pc = 'montgomeryburns@testmail.com'];
        LearnerService.RequestWrapper rw = buildRequestWrapper(String.valueOf(account.PersonBirthdate), account.Personal_Email__pc, account.FirstName, account.LastName, String.valueOf(account.PersonHomePhone), null, true, account.UCAS_Number__pc, 'UCAS', 'Mr', '12 Test Street', null, 'M0 1AD', '12', '13 Test Street', null, 'M1 1AD', '12');
        String jsonMsg = JSON.serialize(rw);

        Test.startTest();
            RestRequest req = new RestRequest(); 
            RestResponse res = new RestResponse();
            req.requestURI = '/services/apexrest/learners/';
            req.httpMethod = 'POST';
            req.requestBody = Blob.valueof(jsonMsg);
            RestContext.request = req;
            RestContext.response = res;

            LearnerService.Response resp = new LearnerService.Response();
            resp = LearnerService.doPost();
            String respString = String.valueOf(resp);
        	System.debug('Test 2: ' + respString);
            System.assert(respString.contains('response=LearnerService Success: Account') && respString.contains('updated'));
        Test.stopTest();
    }

    static testMethod void TestLearnerServiceTest_AccountNotFound_CreateAddress() {
        LearnerService.RequestWrapper rw = buildRequestWrapper('1986-04-19', 'testlearnerservice@testmail.com', 'Barney', 'Gumble', null, '07873829102', true, null, null, 'Mr', '12 Fresh Street', null, 'SK5 2TR', '12', 'Moe\'s Tavern', 'Main Street', 'M23 4ES', '12');
        String jsonMsg = JSON.serialize(rw);

        Test.startTest();
            RestRequest req = new RestRequest(); 
            RestResponse res = new RestResponse();
            req.requestURI = '/services/apexrest/learners/';
            req.httpMethod = 'POST';
            req.requestBody = Blob.valueof(jsonMsg);
            RestContext.request = req;
            RestContext.response = res;

            LearnerService.Response resp = new LearnerService.Response();
            resp = LearnerService.doPost();
            String respString = String.valueOf(resp);
            System.debug('Test 3: ' + respString);
            System.assert(respString.contains('response=LearnerService Success: Account') && respString.contains('created'));
        Test.stopTest();
    }
}