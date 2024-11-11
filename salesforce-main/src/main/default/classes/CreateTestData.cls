/**
 * This class contains data for validating the behavior of Apex classes
 * and triggers. 
 */
@isTest
global class CreateTestData {
    public static country_list__c createCountry1(){
        country_list__c cntry = new country_list__c(Name = 'Unit Test', ISO_Code__c = '123', country_code_2__c = '12', enabled__c = true, Valid_Domicile__c = true, Valid_Nationality__c = true);
        insert cntry;
        return cntry;
    }
    public static State_Province__c createStateProvince(){
        State_Province__c stt = new State_Province__c(Name = 'Unit Test', ISO_Code__c = '123');
        insert stt;
        return stt;
    }
    public static Locality__c createLocality(){
        Locality__c lct = new Locality__c(Name = 'Unit Test', Banner_Code__c = '123');
        insert lct;
        return lct;
    }
    public static Account createAccount1(country_list__c cntry){        
        Account a1 = new Account();
        a1.firstname='John';
        a1.lastname='Coppedge';
        a1.Salutation = 'Mr';
        a1.Middle_Name__pc = 'Mex';
        a1.Gender__pc = 'Male';
        a1.RecordTypeId=Schema.sObjectType.Account.getRecordTypeInfosByName().get('Student Account').getRecordTypeId();
        a1.Student_Cycle__c = 'Pursue';
        a1.Student_Type__pc ='Domestic';
        a1.Preferred_Email__pc = 'Personal';
        a1.PersonEmail = 'john@john.com';
        a1.Personal_Email__pc ='john@john.com';
        a1.Work_Email__pc = 'john1@john.com';
        a1.BPP_Email__pc = 'john2@john.com';
        a1.Other_Email__pc = 'john3@john.com';
        a1.Billing_Email__pc = 'john4@john.com';
        a1.Preferred_Phone__pc = 'Mobile';
        a1.Phone = '8015555556';
        a1.PersonMobilePhone='8015555556';
        a1.PersonBirthdate =Date.valueOf('1986-12-07');
        a1.AA_Suffix__pc = 'Jr';
        a1.Preferred_First_Name__pc = 'Coppege';
        a1.Previous_First_Name__pc = 'John';
        a1.Previous_Surname__pc = 'Cop';
        a1.Previous_Middle_Name__pc = 'Copp';
        a1.Primary_Nationality__pc = cntry.Id;
        a1.Country_of_Birth__pc = cntry.Id;
        a1.Legal_Entity__c = 'UC~COL';
        a1.PS_Profile_Services_ID__pc = '1234f567-bc23-42e8-924c-1234asdf5678';
        a1.SFDC_Ethnic_Code_Select__pc = '10~ White';
        a1.SFDC_Disability_Status_Code_Select__pc = '0~ No Known DisabilityUndo';
        //a1.SFDC_Disability_Type_Code_Select__pc = '0~ No Known DisabilityUndo';
        a1.Country_of_Birth__pc = 'Unit Test';
        a1.SFDC_Country_of_Birth__pc = cntry.Id;
        insert a1;
        return a1;
    }
    
    public static Address__c createAddress(Account a,Lead l,Contact c,country_list__c cntry,State_Province__c stt,Locality__c lct, Boolean isPrimary, String Type){
        Address__c add1 = new Address__c();
        StopRecursion.Dorun = true;
        if(a!=null)
            add1.Student__c = a.Id;
        if(l!=null)
            add1.Lead__c = l.Id;
        if(c!=null)
            add1.Training_Manager__c = c.Id;
        add1.Type__c = Type;
        add1.Street_1__c = '329 S Tonne Dr';
        add1.Street_2__c = '123';
        add1.Street_3__c = '123';
        add1.Street_4__c = '12';
        add1.City__c = 'Chicago';
        add1.Locality__c = lct.Id;
        add1.State_Province__c = stt.Id;
        add1.Zip_Postal_Code__c = '12345';
        add1.Lookup_Country__c = cntry.Id;
        add1.Primary__c = isPrimary;
        insert add1;
        return add1;
    }
    
    public static Opportunity createOpportunity(Account a){
        Opportunity opp1 = new Opportunity();
        opp1.AccountId = a.id;
        opp1.Name = 'test';
        opp1.StageName = 'Accepted - Conditional Firm';
        opp1.Enrolment_Status__c = 'Acceptance';
        opp1.Cycle_Override__c = 'Use Student Cycle';
        opp1.CloseDate = Date.valueOf('2015-02-27'); 
        opp1.BNR_Application_Decision_Comment__c = 'ABCD';
        opp1.SFDC_Attribute_Code_Select__c = 'FT~ Full Time Student';
        opp1.SFDC_Admissions_ADMT_Code_Select__c = 'DI~ Direct';
        opp1.SFDC_Admissions_STYPE_Code_Select__c = 'R~ Returning';
        opp1.SFDC_Admissions_RESD_Code_Select__c = 'E~ EU National';
        opp1.SFDC_Cohort_Code_Select__c = 'C6~ Cohort June';
        opp1.BNR_Level_Code_Text__c = 'AB';
        opp1.BNR_Degree_Code_Text__c = 'ABCD';
        opp1.PC_Attribute_Code__c = 'FT';
        opp1.PC_Attribute_Code_2__c = 'ACCE';
        opp1.PC_Attribute_Code_3__c = 'PT';
        opp1.SFDC_Attribute_Code_Select_v2__c = 'FT~ Full Time Student';
        
        insert opp1;
        return opp1;
    }
    
    public static Programme__c createProgram(){
        Programme__c pgrm = new Programme__c();
        pgrm.Name = 'Test Program';
        pgrm.BNR_FieldOfStudy_Code__c = 'ELEC';
        pgrm.BNR_College_Code__c = '12345678';
        pgrm.Microsite_Enabled__c = true;
        pgrm.Programme_Status__c = 'Validated';
        pgrm.School__c = 'Test School';
        pgrm.Programme_Id__c = 'SBGLD1_sb8';
        insert pgrm;
        return pgrm;
    }
    public static Programme__c createErrorProgram(){
        Programme__c pgrm = new Programme__c();
        pgrm.Name = 'Test Program';
        pgrm.Microsite_Enabled__c = true;
        pgrm.Programme_Status__c = 'Validated';
        pgrm.School__c = 'Test School';
        insert pgrm;
        return pgrm;
    }
    public static Product2 createErrorProduct(Programme__c pgrm,String typeOfPrd){
        Product2 pd = new Product2();
        pd.IsActive = true;
        pd.Name = 'Test Course Instance';
        pd.Programme__c = pgrm.Id;
        pd.Mode__c = 'Full Time';
        pd.Location__c = 'London - London City';
        pd.Start_Date__c = system.today();
        pd.BNR_Admissions_Enabled__c = true;
        pd.BNR_Attribute_Code__c = 'FT';
        pd.BNR_Level_Code__c = 'UG';
        pd.BNR_Degree_Code__c = 'MS';
        pd.BNR_Program_Code__c = 'ELEC';
        pd.Instance_Id__c = '123456789012345';
        pd.Product_Type__c = typeOfPrd;
        pd.BNR_Price__c = 32423;   
        pd.BNR_Min_Capacity__c = 5;
        pd.BNR_Max_Capacity__c = 10; 
        pd.BNR_Used_Capacity__c = 9;    
        insert pd;
        return pd;
    }
    public static Product2 createProduct(Programme__c pgrm,String typeOfPrd){
        Product2 pd = new Product2();
        pd.IsActive = true;
        pd.Name = 'Test Course Instance';
        pd.Programme__c = pgrm.Id;
        pd.Mode__c = 'Full Time';
        pd.Location__c = 'London - London City';
        pd.Start_Date__c = system.today();
        pd.BNR_Admissions_Enabled__c = true;
        pd.BNR_Term_Code__c = '212121';
        pd.BNR_Attribute_Code__c = 'FT';
        pd.BNR_Level_Code__c = 'UG';
        pd.BNR_Campus_Code__c = 'LLC';
        pd.BNR_Degree_Code__c = 'MS';
        pd.BNR_Program_Code__c = 'ELEC';
        pd.Instance_Id__c = '123456789012345';
        pd.Product_Type__c = typeOfPrd;
        pd.BNR_Min_Capacity__c = 5;
        pd.BNR_Max_Capacity__c = 10; 
        pd.BNR_Price__c = 32423;   
        
        pd.Start_Date__c = Date.valueOf('2015-06-07');
        pd.End_Date__c = Date.valueOf('2016-12-10');
        pd.BNR_FieldOfStudy_Start_Date__c = Date.valueOf('2015-06-07');
            
        insert pd;
        return pd;
    }
    
    public static Product2 createProduct(Boolean doInsert, Programme__c pgrm, String typeOfPrd){
        Product2 pd = new Product2();
        pd.IsActive = true;
        pd.Name = 'Test Course Instance';
        pd.Programme__c = pgrm.Id;
        pd.Mode__c = 'Full Time';
        pd.Location__c = 'London - London City';
        pd.Start_Date__c = system.today();
        pd.BNR_Admissions_Enabled__c = true;
        pd.BNR_Term_Code__c = '212121';
        pd.BNR_Attribute_Code__c = 'FT';
        pd.BNR_Level_Code__c = 'UG';
        pd.BNR_Campus_Code__c = 'LLC';
        pd.BNR_Degree_Code__c = 'MS';
        pd.BNR_Program_Code__c = 'ELEC';
        pd.Instance_Id__c = '123456789012345';
        pd.Product_Type__c = typeOfPrd;
        pd.BNR_Min_Capacity__c = 5;
        pd.BNR_Max_Capacity__c = 10; 
        pd.BNR_Price__c = 32423;
        pd.End_Date__c = system.today().addYears(1);
        pd.BNR_FieldOfStudy_Start_Date__c = system.today().addYears(1);
            
        if(doInsert) insert pd;
        return pd;
    }
    
    public static Product2 createProduct(Programme__c pgrm,String typeOfPrd,String name,String instanceId,String code1,String code2){
        Product2 pd = new Product2();
        pd.IsActive = true;
        pd.Name = name;
        pd.Programme__c = pgrm.Id;
        pd.Mode__c = 'Full Time';
        pd.Location__c = 'London - London City';
        pd.Start_Date__c = system.today();
        pd.BNR_Admissions_Enabled__c = true;
        pd.BNR_Term_Code__c = '212121';
        pd.BNR_Attribute_Code__c = 'FT';
        pd.BNR_Level_Code__c = 'UG';
        pd.BNR_Campus_Code__c = 'LLC';
        pd.BNR_Degree_Code__c = 'MS';
        pd.BNR_Program_Code__c = 'ELEC';
        pd.Instance_Id__c = instanceId;
        pd.Product_Type__c = typeOfPrd;
        pd.BNR_Min_Capacity__c = 5;
        pd.BNR_Max_Capacity__c = 10; 
        pd.BNR_Price__c = 32423;       
        insert pd;
        return pd;
    }
    public static Opportunity_Product__c createOppProduct(Opportunity o,Product2 pd,boolean isPrimary){
        Opportunity_Product__c oppProd = new Opportunity_Product__c();
        oppProd.Opportunity__c = o.Id;
        oppProd.Product__c = pd.Id;
        
        if (pd.Product_Type__c == 'OFFERING') {
            if (isPrimary) 
                oppProd.Course_Focus__c = 'Primary';
            else
                oppProd.Course_Focus__c = 'Secondary';
        }
        else {
            oppProd.Course_Focus__c = null; 
        }
        insert oppProd;
        return oppProd;
    }
    
    public static PC_Bundle__c createBundle(String bId, String fName, decimal price){
        PC_Bundle__c pc = new PC_Bundle__c();
        pc.BNR_Price__c= price;
        pc.PC_Bundle_Id__c = bId;
        pc.PC_Bundle_Full_Name__c = fName;
        insert pc;
        return pc;
    }
    
    public static PC_Bundle_Extension__c createBundleExtension(PC_Bundle__c parentB,PC_Bundle__c childB){
        PC_Bundle_Extension__c pce = new PC_Bundle_Extension__c();
        pce.PC_Parent_Bundle__c = parentB.id;
        pce.PC_Child_Bundle__c = childB.Id;
        pce.PC_Child_Bundle_Id__c = childB.PC_Bundle_Id__c;
        insert pce;
        return pce;
    }
    public static PC_Item__c createPCItem(Product2 prd,PC_Bundle__c pcB,Programme__c prg){
        PC_Item__c pcI = new PC_Item__c();
        pcI.Product__c = prd.Id;
        pcI.Programme__c = prg.Id;
        if(pcB!=null){
            pcI.PC_Bundle__c = pcB.Id;
            pcI.PC_Bundle_Id__c = pcB.PC_Bundle_Id__c;
        }
        insert pcI;
        return pcI;
    }
    
    public static Contact createTMContact(){
        Contact tempContact = new Contact();        
        tempContact.FirstName = 'Tommy';
        tempContact.LastName = 'Tesla';
        tempContact.Middle_Name__c = 'W';
        tempContact.Salutation = 'Mr.';
        tempContact.AA_Suffix__c = 'III';
        tempContact.Title = 'Emperor';
        tempContact.Birthdate =  date.ValueOf('1979-03-23');
        tempContact.Business_Unit__c = '';
        tempContact.Cost_Centre_Number__c = '';
        tempContact.Gender__c = 'Male';
        tempContact.VAT_Code__c = '';
        tempContact.Work_Phone__c = '';
        tempContact.MobilePhone = '';
        tempContact.OtherPhone = '';
        tempContact.HomePhone = '';
        tempContact.Preferred_Phone__c = '';
        tempContact.Home_Phone__c = '555-444-5858';
        tempContact.PS_Profile_Services_ID__c = 'fbb4f6be-2323-3434-5656-c61322ec4c2b';
        tempContact.Other_Email__c = 'TT@gmail.com';
        tempContact.BNR_Banner_ID__c = 'BP0038331';
        tempContact.Personal_Email__c = '';
        tempContact.Work_Email__c = '';
        tempContact.BPP_Email__c = '';
        tempContact.Billing_Email__c = '';
        tempContact.Preferred_email__c = 'TT@gmail.com';
        tempContact.RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Training Manager').getRecordTypeId();
        insert tempContact;
        return tempContact;
    }
}