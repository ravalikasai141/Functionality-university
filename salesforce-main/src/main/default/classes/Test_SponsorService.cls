@isTest(SeeAllData=true)
private class Test_SponsorService {

    static testMethod void myUnitTest1(){
		Database.DMLOptions dbDML = new Database.DMLOptions(); 
		dbDML.DuplicateRuleHeader.allowSave = true;
		dbDML.DuplicateRuleHeader.runAsCurrentUser = true;

        Account a = new Account();
        a.firstname='John';
        a.lastname='Coppedge';
        a.RecordTypeId=Schema.sObjectType.Account.getRecordTypeInfosByName().get('Student Account').getRecordTypeId();
        a.Preferred_Email__pc = 'Personal';
        a.Preferred_Phone__pc = 'Mobile';
        a.Personal_Email__pc ='john@john.com';
        a.PersonMobilePhone='8015555556';
        a.PersonBirthdate=Date.valueOf('1986-02-27');
        a.PS_Profile_Services_ID__pc = '1234f567-bc23-42e8-924c-000012345678';
        a.BNR_Banner_ID__pc = 'BP0110547';
        a.Student_Cycle__c = 'Pursue';
        a.Student_Type__pc = 'Domestic';
        a.Sexual_Orientation__pc = '04~ Heterosexual';
        a.Gender_Identity__pc = '01~ Yes';
        a.Religion__pc = '03~ Christian';
        a.Parent_Guardian_Occupation__pc = '1134~ Advertising & public relations managers';
        a.Student_Occupation__pc = '3413~ Actors, entertainers'; 
        a.Legal_Entity__c = 'UC~COL';
        Database.insert(a, dbDML);
        
        Opportunity opp = new Opportunity();
        opp.RecordTypeId=Schema.sObjectType.Opportunity.getRecordTypeInfosByName().get('Application').getRecordTypeId();
        opp.AccountId = a.id;
        opp.Name = 'test';
        opp.Cycle_Override__c = 'Use Student Cycle';
        opp.CloseDate = Date.valueOf('2015-02-27');      
        opp.StageName = 'Review';
        opp.BNR_Application_Decision_Code__c = 'test';
        opp.Sponsorship_Level__c = 'Partial';
        opp.Sponsorship_Amount__c = 2400;
        Database.insert(opp, dbDML);
        
        Account a1 = new Account();
        a1.Name = 'Test Company';
        a1.Phone = '4325768903';
        a1.Account_Category__c = 'Customer - Middle Market';
        a1.Sector_Level_1__c = 'Financial Services';
        a1.Sector_Level_2__c = 'Accountancy';
        a1.Acronym_short_title__c = 'Test'; 
        a1.VAT_number__c = '1234567890';
        a1.EU_Tax_registered__c = true;
        a1.Customer_Type__c = 'Key Client';
        a1.Legal_Entity__c = 'UC~COL';
        a1.Industry_Type_SIC__c = 'B~ Mining and quarrying';
        a1.Use_This_One__c = true;
        a1.RecordTypeId=Schema.sObjectType.Account.getRecordTypeInfosByName().get('Business Development Account').getRecordTypeId();
        a1.Profile_Company_ID__c = '1234f567-bc23-42e8-924c-asdf12345678';
        a1.SIS_Company_ID__c = 'BP0015424';
        a1.Sponsor_Contact__c = 'Term';
        a1.Invoice_Method__c = 'Email';
        a1.Invoice_Delivery__c = 'Email';
        a1.Booking_Requirements__c = 'Passport';
        a1.Correspondence_Detail__c = 'Email';
        a1.Payment_Terms__c = '40 Days';
        a1.Credit_Limit__c = 7500;
        a1.Website = 'www.test.com';
        a1.Discount__c = 25;
        a1.Reporting_Required__c = true;
        Database.insert(a1, dbDML);
        
        Contact c1 = new Contact();
        c1.RecordTypeId = Schema.sObjectType.Contact.getRecordTypeInfosByName().get('Training Manager').getRecordTypeId();
        c1.LastName = 'testc';
        c1.FirstName = 'testfi';
        c1.AccountId = a1.Id;
        c1.Preferred_Phone__c = 'Personal';
        c1.MobilePhone = '3126608787';
        c1.Preferred_Email__c = 'Personal';
        c1.Personal_Email__c = 'testc@con.com';
        c1.Birthdate = Date.newInstance(1986, 4, 5);
        c1.PS_Profile_Services_ID__c = '12300567-bc23-42e8-924c-asdfghij5678';
        c1.Active__c = true;
        Database.insert(c1, dbDML);
               
        Sponsorship__c Spon = new Sponsorship__c();
        Spon.Active__c = true;
        Spon.Student__c = a.Id;
        Spon.Opportunity__c = opp.Id;
		Spon.Company__c = a1.Id;
        Spon.Training_Manager__c = c1.Id;
        insert Spon;
            
        Spon.Active__c = false;
        update Spon;    
    }
    
    static testMethod void myUnitTest2(){
		Database.DMLOptions dbDML = new Database.DMLOptions(); 
		dbDML.DuplicateRuleHeader.allowSave = true;
		dbDML.DuplicateRuleHeader.runAsCurrentUser = true;
		
        Account a = new Account();
        a.firstname='John';
        a.lastname='Coppedge';
        a.RecordTypeId=Schema.sObjectType.Account.getRecordTypeInfosByName().get('Student Account').getRecordTypeId();
        a.Preferred_Email__pc = 'Personal';
        a.Preferred_Phone__pc = 'Mobile';
        a.Personal_Email__pc ='john@john.com';
        a.PersonMobilePhone='8015555556';
        a.PersonBirthdate=Date.valueOf('1986-02-27');
        a.PS_Profile_Services_ID__pc = '1234f567-bc23-42e8-924c-000012345678';
        a.Student_Cycle__c = 'Pursue';
        a.Student_Type__pc = 'Domestic';
        a.Sexual_Orientation__pc = '04~ Heterosexual';
        a.Gender_Identity__pc = '01~ Yes';
        a.Religion__pc = '03~ Christian';
        a.Parent_Guardian_Occupation__pc = '1134~ Advertising & public relations managers';
        a.Student_Occupation__pc = '3413~ Actors, entertainers'; 
        a.Legal_Entity__c = 'UC~COL';
        Database.insert(a, dbDML);
        
        Opportunity opp = new Opportunity();
        opp.RecordTypeId=Schema.sObjectType.Opportunity.getRecordTypeInfosByName().get('Application').getRecordTypeId();
        opp.AccountId = a.id;
        opp.Name = 'test';
        opp.Cycle_Override__c = 'Use Student Cycle';
        opp.CloseDate = Date.valueOf('2015-02-27');      
        opp.StageName = 'Review';
        opp.BNR_Application_Decision_Code__c = 'test';
        opp.Sponsorship_Level__c = 'Partial';
        opp.Sponsorship_Amount__c = 2400;
        Database.insert(opp, dbDML);
        
        Account a1 = new Account();
        a1.Name = 'Test Company';
        a1.Phone = '4325768903';
        a1.Account_Category__c = 'Customer - Middle Market';
        a1.Sector_Level_1__c = 'Financial Services';
        a1.Sector_Level_2__c = 'Accountancy';
        a1.Acronym_short_title__c = 'Test'; 
        a1.VAT_number__c = '1234567890';
        a1.EU_Tax_registered__c = true;
        a1.Customer_Type__c = 'Key Client';
        a1.Legal_Entity__c = 'UC~COL';
        a1.Industry_Type_SIC__c = 'B~ Mining and quarrying';
        a1.Use_This_One__c = true;
        a1.RecordTypeId=Schema.sObjectType.Account.getRecordTypeInfosByName().get('Business Development Account').getRecordTypeId();
        a1.Profile_Company_ID__c = '1234f567-bc23-42e8-924c-asdf12345678';
        a1.SIS_Company_ID__c = 'BP0015424';
        a1.Sponsor_Contact__c = 'Term';
        a1.Invoice_Method__c = 'Email';
        a1.Invoice_Delivery__c = 'Email';
        a1.Booking_Requirements__c = 'Passport';
        a1.Correspondence_Detail__c = 'Email';
        a1.Payment_Terms__c = '40 Days';
        a1.Credit_Limit__c = 7500;
        a1.Website = 'www.test.com';
        a1.Discount__c = 25;
        a1.Reporting_Required__c = true;
        Database.insert(a1, dbDML);
        
        Contact c1 = new Contact();
        c1.RecordTypeId = Schema.sObjectType.Contact.getRecordTypeInfosByName().get('Training Manager').getRecordTypeId();
        c1.LastName = 'testc';
        c1.FirstName = 'testfi';
        c1.AccountId = a1.Id;
        c1.Preferred_Phone__c = 'Personal';
        c1.MobilePhone = '3126608787';
        c1.Preferred_Email__c = 'Personal';
        c1.Personal_Email__c = 'testc@con.com';
        c1.Birthdate = Date.newInstance(1986, 4, 5);
        c1.PS_Profile_Services_ID__c = '12300567-bc23-42e8-924c-asdfghij5678';
        c1.Active__c = true;
        Database.insert(c1, dbDML);
               
        Sponsorship__c Spon = new Sponsorship__c();
        Spon.Active__c = true;
        Spon.Student__c = a.Id;
        Spon.Opportunity__c = opp.Id;
		Spon.Company__c = a1.Id;
        Spon.Training_Manager__c = c1.Id;
        insert Spon;
            
        Spon.Active__c = false;
        update Spon;    
    }
}