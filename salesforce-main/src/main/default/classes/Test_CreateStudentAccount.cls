@isTest
private class Test_CreateStudentAccount {

    static testMethod void myUnitTest() {
        country_list__c cntry = CreateTestData.createCountry1();
        State_Province__c stt = new State_Province__c(Name = 'Unit TestState', ISO_Code__c = '1234');
        insert stt;
        Locality__c lct = new Locality__c(Name = 'Unit TestState', Banner_Code__c = '12345');
        insert lct;
        
        Account a = new Account();
        a.Name = 'Test Company';
        a.Acronym_short_title__c = 'Test'; 
        a.VAT_number__c = '1234567890';
        a.EU_Tax_registered__c = true;
        a.Customer_Type__c = 'Key Client';
        a.Industry_Type_SIC__c = 'B~ Mining and quarrying';
        a.Use_This_One__c = true;
        a.RecordTypeId=Schema.sObjectType.Account.getRecordTypeInfosByName().get('Business Development Account').getRecordTypeId();
        a.Profile_Company_ID__c = '1234f567-bc23-42e8-924c-1234asdf5678';
        a.SIS_Company_ID__c = 'BP0015424';
        a.Sponsor_Contact__c = 'Term';
        a.Invoice_Method__c = 'Email';
        a.Invoice_Delivery__c = 'Email';
        a.Booking_Requirements__c = 'Passport';
        a.Correspondence_Detail__c = 'Email';
        a.Payment_Terms__c = '40 Days';
        a.Credit_Limit__c = 7500;
        a.Website = 'www.test.com';
        a.Discount__c = 25;
        a.Reporting_Required__c = true;
        insert a;
        
        Address__c add = new Address__c();
        StopRecursion.Dorun = true;
        add.Student__c = a.Id;
        add.Type__c = 'Home';
        add.Street_1__c = '329 S Tonne Dr';
        add.Street_2__c = '123';
        add.Street_3__c = '123';
        add.Street_4__c = '12';
        add.City__c = 'Chicago';
        add.Locality__c = lct.Id;
        add.State_Province__c = stt.Id;
        add.Zip_Postal_Code__c = '12345';
        add.Lookup_Country__c = cntry.Id;
        insert add;
        
        Contact c = new Contact();
        c.RecordTypeId = Schema.sObjectType.Contact.getRecordTypeInfosByName().get('Training Manager').getRecordTypeId();
        c.LastName = 'testc';
        c.FirstName = 'testfi';
        c.AccountId = a.Id;
        c.Phone = '3126608787';
        c.Email = 'testc@con.com';
        c.Birthdate = Date.newInstance(1986, 4, 5);
        c.Preferred_Email__c = 'Personal';
        c.Personal_Email__c = 'john@johnzz.com';    
        c.PS_Profile_Services_ID__c = '12300567-bc23-42e8-924c-1234asdf5678';
        c.Active__c = true;
        insert c;
        
        List<CreateStudentAccount.StudentDTO> stdDTO = new List<CreateStudentAccount.StudentDTO>();
        CreateStudentAccount.StudentDTO std = new CreateStudentAccount.StudentDTO();
        
        Account a1 = new Account();
        a1.FirstName='John';
        a1.LastName='Coppedge';
        a1.Salutation = 'Mr';
        a1.Middle_Name__pc = 'Mex';
        a1.Gender__pc = 'Male';
        a1.Preferred_Email__pc = 'Personal';
        a1.Preferred_Phone__pc = 'Mobile';
        a1.Personal_Email__pc ='john@john.com';
        a1.PersonMobilePhone = '8015555556';
        a1.PersonBirthdate = Date.valueOf('1986-02-27');
        a1.PS_Profile_Services_ID__pc = '1234f567-bc23-42e8-924c-asdf12345678';
        a1.Student_Cycle__c = 'Pursue';
        a1.Student_Type__pc = 'Domestic';
        std.student = a1;
        
        List<Address__c> adds = new List<Address__c>();
        Address__c add1 = new Address__c();
        add1.Type__c = 'Billing';
        add1.Street_1__c = '123 S Test Dr';
        add1.Street_2__c = '12345';
        add1.Street_3__c = '1234';
        add1.Street_4__c = '123';
        add1.City__c = 'Test City';
        add1.Text_Locality__c = '12345';
        add1.Text_State__c = '1234';
        add1.Zip_Postal_Code__c = '12345';
        add1.Text_Country__c = '123';
        adds.add(add1);
        std.addresses = adds;
        
        CreateStudentAccount.SponsorshipDTO spn = new CreateStudentAccount.SponsorshipDTO();
        spn.CompanyProfileId = '1234f567-bc23-42e8-924c-1234asdf5678';
        spn.TrainingManagerProfileId = '12300567-bc23-42e8-924c-1234asdf5678';
        std.sponsor = spn;
        
        List<Qualification__c> qlfs = new List<Qualification__c>();
        Qualification__c qlf1 = new Qualification__c();
        qlf1.Examing_Body__c = 'ACCA';
        qlf1.Student_Institute__c = '1234567890';
        qlfs.add(qlf1);
        std.qualifications = qlfs;
        
        stdDTO.add(std);
                //Create REST request and response values and objects.
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        
        req.requestURI = '/services/apexrest/v1.0/CreateStudentAccount';
        req.addHeader('httpMethod', 'POST');
        //req.requestBody = Blob.valueof(JSON);
        RestContext.request = req;
        RestContext.response = res;
        
        CreateStudentAccount.Response res1 = CreateStudentAccount.doPost(stdDTO);
        
    }
}