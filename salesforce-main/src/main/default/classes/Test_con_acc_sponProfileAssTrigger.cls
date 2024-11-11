/**
* This test class covers three triggers and a class
*AccountTrigger, ContactTrigger, sponsorshipProfileAssTrigger, updateProfileIntegrationOnAddress 
*and ProfileAssociation Class 
*/
@isTest
private class Test_con_acc_sponProfileAssTrigger {
    /*static testMethod void myUnitTest() {
        country_list__c cntry = new country_list__c(Name = 'Unit Test', ISO_Code__c = '123', country_code_2__c = '12');
        insert cntry;
        State_Province__c stt = new State_Province__c(Name = 'Unit Test', ISO_Code__c = '123');
        insert stt;
        Locality__c lct = new Locality__c(Name = 'Unit Test', Banner_Code__c = '123');
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
        c.Personal_Email__c ='john456@john.com';
        c.PS_Profile_Services_ID__c = '12300567-bc23-42e8-924c-1234asdf5678';
        c.Active__c = true;
        insert c;
        
        Account a1 = new Account();
        a1.firstname='John';
        a1.lastname='Coppedge';
        a1.RecordTypeId=Schema.sObjectType.Account.getRecordTypeInfosByName().get('Student Account').getRecordTypeId();
        a1.Preferred_Email__pc = 'Personal';
        a1.Preferred_Phone__pc = 'Mobile';
        a1.Personal_Email__pc ='john@john.com';
        a1.PersonMobilePhone='8015555556';
        a1.PersonBirthdate=Date.valueOf('1986-02-27');
        a1.PS_Profile_Services_ID__pc = '1234f567-bc23-42e8-924c-1234asdf5678';
        a1.Student_Cycle__c = 'Pursue';
        a1.Student_Type__pc = 'Domestic';
        insert a1;
            
        Sponsorship__c spon = new Sponsorship__c();
        spon.Active__c = true;
        spon.Company__c = a.Id;
        spon.Training_Manager__c = c.Id;
        spon.Student__c = a1.Id;
        insert spon;
        
        Account a2 = new Account();
        a2.Name = 'Test Company1';
        a2.Acronym_short_title__c = 'Test'; 
        a2.VAT_number__c = '1234567890';
        a2.EU_Tax_registered__c = true;
        a2.Customer_Type__c = 'Key Client';
        a2.Industry_Type_SIC__c = 'B~ Mining and quarrying';
        a2.Use_This_One__c = true;
        a2.RecordTypeId=Schema.sObjectType.Account.getRecordTypeInfosByName().get('Business Development Account').getRecordTypeId();
        a2.Profile_Company_ID__c = '1234f567-bc23-42e8-924c-1234asdf5678';
        a2.SIS_Company_ID__c = 'BP0015424';
        a2.Sponsor_Contact__c = 'Term';
        a2.Invoice_Method__c = 'Email';
        a2.Invoice_Delivery__c = 'Email';
        a2.Booking_Requirements__c = 'Passport';
        a2.Correspondence_Detail__c = 'Email';
        a2.Payment_Terms__c = '40 Days';
        a2.Credit_Limit__c = 7500;
        a2.Website = 'www.test.com';
        a2.Discount__c = 25;
        a2.Reporting_Required__c = true;
        insert a2;
        
        Contact co = new Contact();
        co.RecordTypeId = Schema.sObjectType.Contact.getRecordTypeInfosByName().get('Training Manager').getRecordTypeId();
        co.LastName = 'testco';
        co.FirstName = 'testf';
        co.AccountId = a2.Id;
        co.Phone = '3126608780';
        co.Email = 'testc@co.com';
        co.Birthdate = Date.newInstance(1983, 4, 5);
        co.Preferred_Email__c = 'Personal';
        co.Personal_Email__c ='john45@john.com';
        co.PS_Profile_Services_ID__c = '1234f567-bc23-42e8-924c-1234asdf5678';
        co.Active__c = true;
        insert co;
        
        spon.Active__c = false;
        update spon;
        spon.Company__c = a2.Id;
        spon.Training_Manager__c = co.Id;
        spon.Active__c = true;
        update spon;
        
        Sponsorship__c spon2 = new Sponsorship__c();
        spon2.Active__c = false;
        spon2.Company__c = a.Id;
        spon2.Training_Manager__c = c.Id;
        spon2.Student__c = a1.Id;
        insert spon2;
        try{
            spon2.Active__c = true;
            update spon2;
        }
        catch(Exception e){
            //System.Assert(e.getMessage().contains('You cannot add more then one Active Sponsership record for a Student'));
        }
        
        ProfileAssociation.bFailProf = true;
    }*/
}