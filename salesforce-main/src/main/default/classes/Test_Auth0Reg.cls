@istest
public class Test_Auth0Reg {
    @testSetup
    static void testSetup(){
        Lead l = new Lead();
        l.RecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName().get('Prospective_Student').getRecordTypeId();
        l.FirstName = 'Henry';
        l.LastName = 'Heimlich';
        l.Preferred_Email__c = 'Personal';
        l.Personal_Email__c = 'hh12345@mail.com';
        l.Preferred_Phone__c = 'Mobile';
        l.MobilePhone = '+447719292838';
        insert l;

        country_list__c cntry = CreateTestData.createCountry1();
        Account a = new Account();
        a.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Student_Account').getRecordTypeId();
        a.FirstName = 'Morris';
        a.LastName = 'Baguley';
        a.Preferred_Email__pc = 'Personal';
        a.Personal_Email__pc = 'mbaguley123@mail.com';
        a.Preferred_Phone__pc = 'Mobile';
        a.PersonMobilePhone = '+447713493882';
        insert a;
        
        String roleName = 'Domestic Team [+Record Assignment]';
        Id admissionsUserId = [SELECT Id FROM User WHERE UserRole.Name =: roleName AND IsActive = true ORDER BY Name LIMIT 1].Id;
        Owner_Assignment__c ownerAssignment = new Owner_Assignment__c(Name = roleName, Last_Assignee__c = admissionsUserId);
        insert ownerAssignment;
    }

    public static Auth0Reg.Registration buildReg(String firstname, String lastname, String email, String phone, Boolean optIn, String auth0Id) {
        Auth0Reg.Registration reg = new Auth0Reg.Registration();
        reg.firstname = firstname;
        reg.lastname = lastname;
        reg.email = email;
        reg.phone = phone;
        reg.optIn = optIn;
        reg.Auth0Id = auth0Id;
        return reg;
    }

    @isTest
    static void itShouldFindLeadAndConvertToAccount(){
        Lead l = [SELECT Id, FirstName, LastName, Personal_Email__c, MobilePhone FROM Lead WHERE Personal_Email__c = 'hh12345@mail.com'];
        Auth0Reg.Registration reg = buildReg(l.FirstName, l.LastName, l.Personal_Email__c, l.MobilePhone, TRUE, 'auth0|bcirbecocoencreoicr');
        String jsonMsg = JSON.serialize(reg);

        Test.startTest();
            RestRequest req = new RestRequest(); 
            RestResponse res = new RestResponse();
            req.requestURI = '/services/apexrest/v1.0/Auth0Reg';
            req.httpMethod = 'POST';
            req.requestBody = Blob.valueof(jsonMsg);
            RestContext.request = req;
            RestContext.response = res;

            Auth0Reg.Response resp = new Auth0Reg.Response('', '');
            resp = Auth0Reg.doPost(reg);

            List<Account> accountCheck = [SELECT Id, GDPR_Opt_In__c FROM Account WHERE PersonEmail = 'hh12345@mail.com'];
            System.assertEquals(1, accountCheck.size(), 'Lead found and converted');
        	System.assertEquals(TRUE, accountCheck.get(0).GDPR_Opt_In__c, 'GDPR Opt In');

            Account acc;
            if (accountCheck.size() == 1) {
                for (Account a : accountCheck) {
                    acc = a;
                }
            }

            String respString = String.valueOf(resp);
            System.assertEquals('Response:[accountId=' + acc.Id + ', response=Auth0Reg auth0|bcirbecocoencreoicr Success: Lead conversion Account - ' + acc.Id + ' updated]', respString, 'Successful Response');
        Test.stopTest();
    }
    
    @isTest
    static void itShouldFindHubAccountAndUpdateRelatedAccount(){
        Account a = [SELECT Id, FirstName, LastName, Personal_Email__pc, PersonMobilePhone FROM Account WHERE Personal_Email__pc = 'mbaguley123@mail.com'];
        Hub_Account__c hubAccount = new Hub_Account__c(
        	Auth0_Id__c = 'auth0|2fevaklduj2q233b4atqv4hbs',
            Hub_Username__c = a.Personal_Email__pc,
            Student__c = a.Id
        );
        insert hubAccount;
        
        Auth0Reg.Registration reg = buildReg(a.FirstName, a.LastName, a.Personal_Email__pc, '+447713400000', FALSE, hubAccount.Auth0_Id__c);
        String jsonMsg = JSON.serialize(reg);

        Test.startTest();
            RestRequest req = new RestRequest(); 
            RestResponse res = new RestResponse();
            req.requestURI = '/services/apexrest/v1.0/Auth0Reg';
            req.httpMethod = 'POST';
            req.requestBody = Blob.valueof(jsonMsg);
            RestContext.request = req;
            RestContext.response = res;

            Auth0Reg.Response resp = new Auth0Reg.Response('', '');
            resp = Auth0Reg.doPost(reg);

            Account acc = [SELECT Id, PersonMobilePhone, GDPR_Opt_In__c FROM Account WHERE Personal_Email__pc = 'mbaguley123@mail.com'];
            System.assertEquals('+447713400000', acc.PersonMobilePhone, 'Account found and updated');
        	System.assertEquals(FALSE, acc.GDPR_Opt_In__c, 'GDPR Opt In');

            List<Task> t = [SELECT Id FROM Task WHERE WhatId =: acc.Id];
            System.assertEquals(1, t.size(), 'Task created');

            String respString = String.valueOf(resp);
            System.debug(respString);
            System.assertEquals('Response:[accountId=' + acc.Id + ', response=Auth0Reg ' + hubAccount.Auth0_Id__c + ' Success: Account - ' + acc.Id + ' updated]', respString, 'Successful Response');
        Test.stopTest();
    }

    @isTest
    static void itShouldFindAccountAndUpdateIt(){
        Account a = [SELECT Id, FirstName, LastName, Personal_Email__pc, PersonMobilePhone FROM Account WHERE Personal_Email__pc = 'mbaguley123@mail.com'];
        Auth0Reg.Registration reg = buildReg(a.FirstName, a.LastName, a.Personal_Email__pc, '+447713400000', FALSE, 'auth0|bcirbecocoencreoicr');
        String jsonMsg = JSON.serialize(reg);

        Test.startTest();
            RestRequest req = new RestRequest(); 
            RestResponse res = new RestResponse();
            req.requestURI = '/services/apexrest/v1.0/Auth0Reg';
            req.httpMethod = 'POST';
            req.requestBody = Blob.valueof(jsonMsg);
            RestContext.request = req;
            RestContext.response = res;

            Auth0Reg.Response resp = new Auth0Reg.Response('', '');
            resp = Auth0Reg.doPost(reg);

            Account acc = [SELECT Id, PersonMobilePhone, GDPR_Opt_In__c FROM Account WHERE Personal_Email__pc = 'mbaguley123@mail.com'];
            System.assertEquals('+447713400000', acc.PersonMobilePhone, 'Account found and updated');
        	System.assertEquals(FALSE, acc.GDPR_Opt_In__c, 'GDPR Opt In');

            List<Task> t = [SELECT Id FROM Task WHERE WhatId =: acc.Id];
            System.assertEquals(1, t.size(), 'Task created');

            String respString = String.valueOf(resp);
            System.debug(respString);
            System.assertEquals('Response:[accountId=' + acc.Id + ', response=Auth0Reg auth0|bcirbecocoencreoicr Success: Account - ' + acc.Id + ' updated]', respString, 'Successful Response');
        Test.stopTest();
    }

    @isTest
    static void itShouldNotFindAccountAndCreateOne(){
        Auth0Reg.Registration reg = buildReg('Fred', 'East', 'freddyeast123@mail.com', '+447713400000', NULL, 'auth0|bcirbecocoencreoicr');
        String jsonMsg = JSON.serialize(reg);

        Test.startTest();
            RestRequest req = new RestRequest(); 
            RestResponse res = new RestResponse();
            req.requestURI = '/services/apexrest/v1.0/Auth0Reg';
            req.httpMethod = 'POST';
            req.requestBody = Blob.valueof(jsonMsg);
            RestContext.request = req;
            RestContext.response = res;

            Auth0Reg.Response resp = Auth0Reg.doPost(reg);

            List<Account> accountCheck = [SELECT Id, GDPR_Opt_In__c FROM Account WHERE PersonEmail = 'freddyeast123@mail.com'];
            System.debug(accountCheck);
            System.assertEquals(1, accountCheck.size(), 'Account created');
        	System.assertEquals(FALSE, accountCheck.get(0).GDPR_Opt_In__c, 'GDPR Opt In');

            Account acc;
            if (accountCheck.size() == 1) {
                for (Account a : accountCheck) {
                    acc = a;
                }
            }

            String respString = String.valueOf(resp);
            System.assertEquals('Response:[accountId=' + acc.Id + ', response=Auth0Reg auth0|bcirbecocoencreoicr Success: Account - ' + acc.Id + ' created]', respString, 'No Lead/Account found - Account created');
        Test.stopTest();
    }

    @isTest
    static void testBuildDate(){
        System.assertEquals(Auth0Reg.buildDate('1995','12','27'), Date.newInstance(1995, 12, 27), 'Date built with wrong values');
        System.assertEquals(Auth0Reg.buildDate(  null, '12','27'), null, 'Date built when not expected');
        System.assertEquals(Auth0Reg.buildDate('1995', null,'27'), null, 'Date built when not expected');
        System.assertEquals(Auth0Reg.buildDate('1995', '12', null), null, 'Date built when not expected');
    }
}