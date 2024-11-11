@isTest
public class CasDataTest {
    @TestSetup
    static void makeData(){
        PC_Bundle__c bundle = CreateTestData.createBundle('bId33242', 'fName', 3243.3);

        PC_Item__c pcItem = new PC_Item__c();
        pcItem.PC_Bundle__c = bundle.Id;
        pcItem.PC_Bundle_Id__c = bundle.PC_Bundle_Id__c;
        insert pcItem;
    }

    private static Product2 createProduct(String name) {
        Product2 product = new Product2();
        product.IsActive = true;
        product.Name = name;
        product.Mode__c = 'Full Time';
        product.Product_Type__c = 'OFFERING';
        product.Start_Date__c = System.today();
        product.End_Date__c = System.today().addYears(1);
        insert product;
        
        PC_Item__c pcItem = [SELECT Id FROM PC_Item__c];
        pcItem.Product__c = product.Id;
        update pcItem;

        return product;
    }

    public static Opportunity initialiseOpportunity(Id accountId, Id productId, Boolean doInsert) {
        Opportunity opportunity = new Opportunity();
        opportunity.AccountId = accountId;
        opportunity.CloseDate = Date.valueOf('2027-01-01');
        opportunity.Course_Instance__c = productId;
        opportunity.Enrolment_Status__c = 'Acceptance';
        opportunity.Name = 'Test_' + DedupeHelper.generateRandomString(10);
        opportunity.Record_Source__c = 'UCAS';
        opportunity.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Application').getRecordTypeId();
        opportunity.StageName = 'Accepted - Conditional Firm';
        opportunity.Passport__c = 'Validated';
        opportunity.Degree_Transcript__c = 'Validated';
        opportunity.Degree_Certificate__c = 'Validated';
        opportunity.Proof_of_Exemptions__c = 'Validated';
        opportunity.Visa_Confirmation__c = 'Validated';
        opportunity.EU_Settlement_Evidence__c = 'Validated';
        opportunity.BCAT__c = 'Validated';
        opportunity.Inn_of_Court__c = 'Validated';
        opportunity.Certificate_of_Academic_Standing__c = 'Validated';
        opportunity.Faculty_Approval__c = 'Validated';
        opportunity.ACCA_Status_Report__c = 'Validated';
        opportunity.School_Leaving_Level_3_Certificate__c = 'Validated';
        opportunity.Highest_Qualification_Certificate__c = 'Validated';
        opportunity.Highest_Qualification_Transcript__c = 'Validated';
        opportunity.Confirmation_of_Contact_Details__c = 'Validated';
        opportunity.English_Language_Certificate__c = 'Validated';
        opportunity.BRP__c = 'Validated';
        opportunity.GDL_PGDL_Transcript__c = 'Validated';
        opportunity.Stamped_Entry_Clearance__c = 'Validated';
        opportunity.CAS_status__c = 'Ready to Assign';

        if (doInsert) {
            insert opportunity;
        }
        return opportunity;
    }

    private static void createQualificationRecords(String qualificationInstitutionName, Id contactId) {
        Qualification_Subject__c qualificationSubject = new Qualification_Subject__c();
        qualificationSubject.Name = 'Test Qualification Subject';
        qualificationSubject.Subject_Code__c = 'PMO';
        insert qualificationSubject;
        
        Qualification_Type__c qualificationType = new Qualification_Type__c();
        qualificationType.Name = 'Test Qualification Type';
        qualificationType.Type_Code__c = 'PMO';
        insert qualificationType;
               
        Qualification_Institution__c qualificationInstitution = new Qualification_Institution__c();
        qualificationInstitution.Name = qualificationInstitutionName;
        qualificationInstitution.Institution_Code__c = 'PMO';
        insert qualificationInstitution;

        Qualification__c qualification = new Qualification__c();
        qualification.Admissions_Request__c = true;
        qualification.Examing_Body__c = 'Test Body';
        qualification.Qualification_Date__c = System.today();
        qualification.Qualification_Subject__c = qualificationSubject.Id;
        qualification.Qualification_Type__c = qualificationType.Id;
        qualification.Qualification_Institution__c = qualificationInstitution.Id;
        qualification.Status__c = 'Actual';
        qualification.Student__c = contactId;
        insert qualification;
    }

    private static void createPayment(Decimal amount, Id accountId) {
        Payment__c payment = new Payment__c();
        payment.AR_Payment_Segment__c = 'First Instalment for CAS';
        payment.AR_Payment_Amount__c = amount;
        payment.AR_Payment_Form__c = 'Cash';
        payment.Student__c = accountId;
        insert payment;
    }

    @isTest
    static void test_CasData_OppAccountWithSingleQualificationAndPayment() {
        Product2 product = createProduct('Test Course Instance');
        Account account = TestDataFactory.createAccount(true, true, null, 0);
        Opportunity opportunity = initialiseOpportunity(account.Id, product.Id, true);

        Id contactId = [SELECT PersonContactId FROM Account WHERE Id =: account.Id].PersonContactId;
        createQualificationRecords('Test Qualification Institution', contactId);
        createPayment(500, account.Id);

        CasExportBatch batch = new CasExportBatch();
        Database.executeBatch(batch);
    }

    @isTest
    static void test_CasData_OppAccountWithSingleQualificationAndMultiplePayments() {
        Product2 product = createProduct('Test Course Instance');

        Account account = TestDataFactory.createAccount(false, true, null, 0);
        account.Ever_Studied_in_UK_Before__c = 'Yes';
        insert account;

        Opportunity opportunity = initialiseOpportunity(account.Id, product.Id, false);
        opportunity.BPP_Previous_Course_Level__c = 'RQF Level 5';
        opportunity.BPP_Course_Level__c = 'RQF Level 5';
        opportunity.Discount_Amount__c = 100;
        insert opportunity;

        Id contactId = [SELECT PersonContactId FROM Account WHERE Id =: account.Id].PersonContactId;
        createQualificationRecords('Test Qualification Institution', contactId);
        createPayment(500, account.Id);
        createPayment(800, account.Id);

        CasExportBatch batch = new CasExportBatch();
        Database.executeBatch(batch);
    }

    @isTest
    static void test_CasData_OppWithSpecificCourseLocation1() {
        Product2 product = createProduct('Test Course Instance');
        product.Location__c = 'London - Waterloo';
        update product;

        Account account = TestDataFactory.createAccount(false, true, null, 0);
        account.Ever_Studied_in_UK_Before__c = 'Yes';
        insert account;

        Opportunity opportunity = initialiseOpportunity(account.Id, product.Id, false);
        opportunity.BPP_Previous_Course_Level__c = 'RQF Level 6';
        opportunity.BPP_Course_Level__c = 'RQF Level 5';
        insert opportunity;

        CasExportBatch batch = new CasExportBatch();
        Database.executeBatch(batch);
    }

    @isTest
    static void test_CasData_OppWithSpecificCourseLocation2() {
        Product2 product = createProduct('Test Course Instance');
        product.Location__c = 'Reading';
        update product;

        Account account = TestDataFactory.createAccount(false, true, null, 0);
        account.Ever_Studied_in_UK_Before__c = 'Yes';
        insert account;

        Opportunity opportunity = initialiseOpportunity(account.Id, product.Id, false);
        opportunity.BPP_Previous_Course_Level__c = 'RQF Level 5';
        opportunity.BPP_Course_Level__c = 'RQF Level 6';
        insert opportunity;

        CasExportBatch batch = new CasExportBatch();
        Database.executeBatch(batch);
    }

    @isTest
    static void test_CasData_OppWithSpecificCourseLocation3() {
        Product2 product = createProduct('Test Course Instance');
        product.Location__c = 'Newcastle';
        update product;

        Account account = TestDataFactory.createAccount(false, true, null, 0);
        account.Ever_Studied_in_UK_Before__c = 'Yes';
        insert account;

        Opportunity opportunity = initialiseOpportunity(account.Id, product.Id, false);
        opportunity.BPP_Previous_Course_Level__c = 'RQF Level 5';
        insert opportunity;

        CasExportBatch batch = new CasExportBatch();
        Database.executeBatch(batch);
    }

    @isTest
    static void test_CasData_OppWithSpecificCourseLocation4() {
        Product2 product = createProduct('Test Course Instance');
        product.Location__c = 'Birmingham';
        update product;

        Account account = TestDataFactory.createAccount(false, true, null, 0);
        account.Ever_Studied_in_UK_Before__c = 'Yes';
        insert account;

        Opportunity opportunity = initialiseOpportunity(account.Id, product.Id, false);
        opportunity.BPP_Course_Level__c = 'RQF Level 5';
        insert opportunity;

        CasExportBatch batch = new CasExportBatch();
        Database.executeBatch(batch);
    }

    @isTest
    static void test_CasData_OppWithSpecificCourseLocation5() {
        Product2 product = createProduct('Test Course Instance');
        product.Location__c = 'London - Liverpool Street';
        update product;

        Account account = TestDataFactory.createAccount(true, true, null, 0);
        Opportunity opportunity = initialiseOpportunity(account.Id, product.Id, true);

        CasExportBatch batch = new CasExportBatch();
        Database.executeBatch(batch);
    }

    @isTest
    static void test_CasData_OppWithSpecificCourseLocation6() {
        Product2 product = createProduct('Test Course Instance');
        product.Location__c = 'Milton Keynes';
        update product;
        
        Account account = TestDataFactory.createAccount(true, true, null, 0);
        Opportunity opportunity = initialiseOpportunity(account.Id, product.Id, true);

        CasExportBatch batch = new CasExportBatch();
        Database.executeBatch(batch);
    }

    @isTest
    static void test_CasData_OppWithSpecificCourseLocation7() {
        Product2 product = createProduct('Test Course Instance');
        product.Location__c = 'Doncaster-RDASH';
        update product;

        Account account = TestDataFactory.createAccount(true, true, null, 0);
        Opportunity opportunity = initialiseOpportunity(account.Id, product.Id, true);

        CasExportBatch batch = new CasExportBatch();
        Database.executeBatch(batch);
    }

    @isTest
    static void test_CasData_OppWithSpecificCourseLocation8() {
        Product2 product = createProduct('Test Course Instance');
        product.Location__c = 'London - Shepherds Bush';
        update product;

        Account account = TestDataFactory.createAccount(true, true, null, 0);
        Opportunity opportunity = initialiseOpportunity(account.Id, product.Id, true);

        CasExportBatch batch = new CasExportBatch();
        Database.executeBatch(batch);
    }

    @isTest
    static void test_CasData_OppWithSpecificCourseLocation9() {
        Product2 product = createProduct('Test Course Instance');
        product.Location__c = 'London - Red Lion Street';
        update product;

        Account account = TestDataFactory.createAccount(true, true, null, 0);
        Opportunity opportunity = initialiseOpportunity(account.Id, product.Id, true);

        CasExportBatch batch = new CasExportBatch();
        Database.executeBatch(batch);
    }

    @isTest
    static void test_CasData_OppWithSpecificCourseLocation10() {
        Product2 product = createProduct('Test Course Instance');
        product.Location__c = 'London - London City';
        update product;

        Account account = TestDataFactory.createAccount(true, true, null, 0);
        Opportunity opportunity = initialiseOpportunity(account.Id, product.Id, true);

        CasExportBatch batch = new CasExportBatch();
        Database.executeBatch(batch);
    }

    @isTest
    static void test_CasData_OppWithSpecificCourseLocation11() {
        Product2 product = createProduct('Test Course Instance');
        product.Location__c = 'Southampton';
        update product;

        Account account = TestDataFactory.createAccount(true, true, null, 0);
        Opportunity opportunity = initialiseOpportunity(account.Id, product.Id, true);

        CasExportBatch batch = new CasExportBatch();
        Database.executeBatch(batch);
    }

    @isTest
    static void test_CasData_OppWithSpecificCourseLocation12() {
        Product2 product = createProduct('Test Course Instance');
        product.Location__c = 'London - Kings Cross';
        update product;

        Account account = TestDataFactory.createAccount(true, true, null, 0);
        Opportunity opportunity = initialiseOpportunity(account.Id, product.Id, true);

        CasExportBatch batch = new CasExportBatch();
        Database.executeBatch(batch);
    }

    @isTest
    static void test_CasData_OppWithSpecificCourseLocation13() {
        Product2 product = createProduct('Test Course Instance');
        product.Location__c = 'London - Portsoken';
        update product;
        
        Account account = TestDataFactory.createAccount(true, true, null, 0);
        Opportunity opportunity = initialiseOpportunity(account.Id, product.Id, true);

        CasExportBatch batch = new CasExportBatch();
        Database.executeBatch(batch);
    }

    @isTest
    static void test_CasData_OppWithSpecificCourseLocation14() {
        Product2 product = createProduct('Test Course Instance');
        product.Location__c = 'Bristol';
        update product;
        
        Account account = TestDataFactory.createAccount(true, true, null, 0);
        Opportunity opportunity = initialiseOpportunity(account.Id, product.Id, true);

        CasExportBatch batch = new CasExportBatch();
        Database.executeBatch(batch);
    }

    @isTest
    static void test_CasData_OppWithSpecificCourseLocation15() {
        Product2 product = createProduct('Test Course Instance');
        product.Location__c = 'Nottingham';
        update product;
        
        Account account = TestDataFactory.createAccount(true, true, null, 0);
        Opportunity opportunity = initialiseOpportunity(account.Id, product.Id, true);

        CasExportBatch batch = new CasExportBatch();
        Database.executeBatch(batch);
    }

    @isTest
    static void test_CasData_OppWithSpecificCourseLocation16() {
        Product2 product = createProduct('Test Course Instance');
        product.Location__c = 'Jersey';
        update product;
        
        Account account = TestDataFactory.createAccount(true, true, null, 0);
        Opportunity opportunity = initialiseOpportunity(account.Id, product.Id, true);

        CasExportBatch batch = new CasExportBatch();
        Database.executeBatch(batch);
    }

    @isTest
    static void test_CasData_OppWithSpecificCourseLocation17() {
        Product2 product = createProduct('Test Course Instance');
        product.Location__c = 'Cambridge';
        update product;
        
        Account account = TestDataFactory.createAccount(true, true, null, 0);
        Opportunity opportunity = initialiseOpportunity(account.Id, product.Id, true);

        CasExportBatch batch = new CasExportBatch();
        Database.executeBatch(batch);
    }

    @isTest
    static void test_CasData_OppWithSpecificCourseLocation18() {
        Product2 product = createProduct('Test Course Instance');
        product.Location__c = 'Manchester';
        update product;
        
        Account account = TestDataFactory.createAccount(true, true, null, 0);
        Opportunity opportunity = initialiseOpportunity(account.Id, product.Id, true);

        CasExportBatch batch = new CasExportBatch();
        Database.executeBatch(batch);
    }

    @isTest
    static void test_CasData_OppWithSpecificCourseLocation19() {
        Product2 product = createProduct('Test Course Instance');
        product.Location__c = 'BPP Guernsey';
        update product;
        
        Account account = TestDataFactory.createAccount(true, true, null, 0);
        Opportunity opportunity = initialiseOpportunity(account.Id, product.Id, true);

        CasExportBatch batch = new CasExportBatch();
        Database.executeBatch(batch);
    }

    @isTest
    static void test_CasData_OppWithSpecificCourseLocation20() {
        Product2 product = createProduct('Test Course Instance');
        product.Location__c = 'Leeds';
        update product;
        
        Account account = TestDataFactory.createAccount(true, true, null, 0);
        Opportunity opportunity = initialiseOpportunity(account.Id, product.Id, true);

        CasExportBatch batch = new CasExportBatch();
        Database.executeBatch(batch);
    }

    @isTest
    static void test_CasData_OppWithSpecificCourseName1() {
        Product2 product = createProduct('BSCHN Test Course Instance');
        Account account = TestDataFactory.createAccount(true, true, null, 0);
        Opportunity opportunity = initialiseOpportunity(account.Id, product.Id, true);

        CasExportBatch batch = new CasExportBatch();
        Database.executeBatch(batch);
    }

    @isTest
    static void test_CasData_OppWithSpecificCourseName2() {
        Product2 product = createProduct('Test Course Instance PDP');
        Account account = TestDataFactory.createAccount(true, true, null, 0);
        Opportunity opportunity = initialiseOpportunity(account.Id, product.Id, true);

        CasExportBatch batch = new CasExportBatch();
        Database.executeBatch(batch);
    }

    @isTest
    static void test_CasData_OppAccountWithSpecificLanguageTestType1() {
        Product2 product = createProduct('Test Course Instance');
        
        Account account = TestDataFactory.createAccount(false, true, null, 0);
        account.Language_Test_Type__pc = 'IELTS';
        account.Listening_Language_Score__pc = '4.0';
        account.Reading_Language_Score__pc = '4.0';
        account.Speaking_Language_Score__pc = '4.0';
        account.Writing_Language_Score__pc = '4.0';
        account.Overall_Language_Score__pc = '4.0';
        insert account;

        Opportunity opportunity = initialiseOpportunity(account.Id, product.Id, true);

        Id contactId = [SELECT PersonContactId FROM Account WHERE Id =: account.Id].PersonContactId;
        createQualificationRecords('Test Qualification Institution', contactId);

        CasExportBatch batch = new CasExportBatch();
        Database.executeBatch(batch);
    }

    @isTest
    static void test_CasData_OppAccountWithSpecificLanguageTestType2() {
        Product2 product = createProduct('Test Course Instance');
        
        Account account = TestDataFactory.createAccount(false, true, null, 0);
        account.Language_Test_Type__pc = 'BPP ELT';
        account.Listening_Language_Score__pc = '4.0';
        account.Reading_Language_Score__pc = '4.0';
        account.Speaking_Language_Score__pc = '4.0';
        account.Writing_Language_Score__pc = '4.0';
        account.Overall_Language_Score__pc = '4.0';
        insert account;

        Opportunity opportunity = initialiseOpportunity(account.Id, product.Id, true);

        Id contactId = [SELECT PersonContactId FROM Account WHERE Id =: account.Id].PersonContactId;
        createQualificationRecords('Test Qualification Institution', contactId);

        CasExportBatch batch = new CasExportBatch();
        Database.executeBatch(batch);
    }

    @isTest
    static void test_CasData_OppAccountWithSpecificLanguageTestType3() {
        Product2 product = createProduct('Test Course Instance');
        
        Account account = TestDataFactory.createAccount(false, true, null, 0);
        account.Language_Test_Type__pc = 'TOEFL';
        account.Listening_Language_Score__pc = '10';
        account.Reading_Language_Score__pc = '10';
        account.Speaking_Language_Score__pc = '10';
        account.Writing_Language_Score__pc = '10';
        insert account;

        Opportunity opportunity = initialiseOpportunity(account.Id, product.Id, true);

        Id contactId = [SELECT PersonContactId FROM Account WHERE Id =: account.Id].PersonContactId;
        createQualificationRecords('Test Qualification Institution', contactId);

        CasExportBatch batch = new CasExportBatch();
        Database.executeBatch(batch);
    }

    @isTest
    static void test_CasData_OppAccountWithSpecificLanguageTestType4() {
        Product2 product = createProduct('Test Course Instance');
        
        Account account = TestDataFactory.createAccount(false, true, null, 0);
        account.Language_Test_Type__pc = 'PTE';
        account.Listening_Language_Score__pc = '40';
        account.Reading_Language_Score__pc = '40';
        account.Speaking_Language_Score__pc = '40';
        account.Writing_Language_Score__pc = '40';
        account.Overall_Language_Score__pc = '40';
        insert account;

        Opportunity opportunity = initialiseOpportunity(account.Id, product.Id, true);

        Id contactId = [SELECT PersonContactId FROM Account WHERE Id =: account.Id].PersonContactId;
        createQualificationRecords('Test Qualification Institution', contactId);

        CasExportBatch batch = new CasExportBatch();
        Database.executeBatch(batch);
    }

    @isTest
    static void test_CasData_OppAccountWithSpecificLanguageTestType5() {
        Product2 product = createProduct('Test Course Instance');
        
        Account account = TestDataFactory.createAccount(false, true, null, 0);
        account.Language_Test_Type__pc = 'GCSE/GCE';
        insert account;

        Opportunity opportunity = initialiseOpportunity(account.Id, product.Id, true);

        Id contactId = [SELECT PersonContactId FROM Account WHERE Id =: account.Id].PersonContactId;
        createQualificationRecords('Test Qualification Institution', contactId);

        CasExportBatch batch = new CasExportBatch();
        Database.executeBatch(batch);
    }

    @isTest
    static void test_CasData_OppAccountWithSpecificLanguageTestType6() {
        Product2 product = createProduct('Test Course Instance');
        
        Account account = TestDataFactory.createAccount(false, true, null, 0);
        account.Language_Test_Type__pc = 'HSSC ELT Waiver';
        insert account;

        Opportunity opportunity = initialiseOpportunity(account.Id, product.Id, true);

        Id contactId = [SELECT PersonContactId FROM Account WHERE Id =: account.Id].PersonContactId;
        createQualificationRecords('Test Qualification Institution', contactId);

        CasExportBatch batch = new CasExportBatch();
        Database.executeBatch(batch);
    }

    @isTest
    static void test_CasData_OppAccountWithSpecificLanguageTestType7() {
        Product2 product = createProduct('Test Course Instance');
        
        Account account = TestDataFactory.createAccount(false, true, null, 0);
        account.Language_Test_Type__pc = 'Oxford ELT Test';
        account.Listening_Language_Score__pc = '10';
        account.Reading_Language_Score__pc = '10';
        account.Speaking_Language_Score__pc = '10';
        account.Writing_Language_Score__pc = '10';
        account.Overall_Language_Score__pc = '10';
        insert account;

        Opportunity opportunity = initialiseOpportunity(account.Id, product.Id, true);

        Id contactId = [SELECT PersonContactId FROM Account WHERE Id =: account.Id].PersonContactId;
        createQualificationRecords('Test Qualification Institution', contactId);

        CasExportBatch batch = new CasExportBatch();
        Database.executeBatch(batch);
    }

    @isTest
    static void test_CasData_OppAccountWithSpecificLanguageTestType8() {
        Product2 product = createProduct('Test Course Instance');
        
        Account account = TestDataFactory.createAccount(false, true, null, 0);
        account.Language_Test_Type__pc = 'Language Cert';
        account.Listening_Language_Score__pc = '40';
        account.Reading_Language_Score__pc = '40';
        account.Speaking_Language_Score__pc = '40';
        account.Writing_Language_Score__pc = '40';
        account.Overall_Language_Score__pc = 'Pass';
        insert account;

        Opportunity opportunity = initialiseOpportunity(account.Id, product.Id, true);

        Id contactId = [SELECT PersonContactId FROM Account WHERE Id =: account.Id].PersonContactId;
        createQualificationRecords('Test Qualification Institution', contactId);

        CasExportBatch batch = new CasExportBatch();
        Database.executeBatch(batch);
    }

    @isTest
    static void test_CasData_OppAccountWithSpecificLanguageTestType9() {
        Product2 product = createProduct('Test Course Instance');
        
        Account account = TestDataFactory.createAccount(false, true, null, 0);
        account.Ever_Studied_in_UK_Before__c = 'Yes';
        account.Language_Test_Type__pc = 'MOI';
        insert account;

        Opportunity opportunity = initialiseOpportunity(account.Id, product.Id, true);

        Id contactId = [SELECT PersonContactId FROM Account WHERE Id =: account.Id].PersonContactId;
        createQualificationRecords('Test Qualification Institution', contactId);

        CasExportBatch batch = new CasExportBatch();
        Database.executeBatch(batch);
    }
}