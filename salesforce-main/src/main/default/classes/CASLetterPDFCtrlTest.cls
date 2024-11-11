@isTest
private class CASLetterPDFCtrlTest {
    @TestSetup
    static void makeData(){
        PC_Bundle__c bundle = CreateTestData.createBundle('bId33242', 'fName', 3243.3);

        PC_Item__c pcItem = new PC_Item__c();
        pcItem.PC_Bundle__c = bundle.Id;
        pcItem.PC_Bundle_Id__c = bundle.PC_Bundle_Id__c;
        insert pcItem;
    }
    
    @isTest
    static void CASLetterTest1(){
        Product2 product = createProduct('Test Course Instance');
        Account account = TestDataFactory.createAccount(true, true, null, 0);
        Opportunity opportunity = initialiseOpportunity(account.Id, product.Id, true);
        
        Id contactId = [SELECT PersonContactId FROM Account WHERE Id =: account.Id].PersonContactId;
        createQualificationRecords('Test Qualification Institution', contactId);
        createPayment(500, account.Id);
        
        PageReference PDf =  Page.CASLetterPDF;
        PDf.getParameters().put('Id',opportunity.Id);
 
        Test.setCurrentPage(PDf);
        CASLetterPDFCtrl.getCASLetterPDFData();
    }
    
    @isTest
    static void CASLetterTest2(){
        Product2 product = createProduct('Test Course Instance');
        
        Account account = TestDataFactory.createAccount(false, true, null, 0);
        account.Ever_Studied_in_UK_Before__c = 'Yes';
        insert account;
        
        Opportunity opportunity = initialiseOpportunity(account.Id, product.Id, true);

        Id contactId = [SELECT PersonContactId FROM Account WHERE Id =: account.Id].PersonContactId;
        createQualificationRecords('Test Qualification Institution', contactId);
        createPayment(500, account.Id);
        
      	Opportunity oppRecord = [SELECT Id FROM Opportunity WHERE Id =:Opportunity.id];
        oppRecord.CAS_status__c = 'Issued';
        update oppRecord;
        
        PageReference PDf =  Page.CASLetterPDF;
        PDf.getParameters().put('Id',opportunity.Id);
 
        Test.setCurrentPage(PDf);
        CASLetterPDFCtrl.getCASLetterPDFData();
    }
    
    @isTest
    static void test_CasLetter_OppWithSpecificCourseLocation() {
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
        
        PageReference PDf =  Page.CASLetterPDF;
        PDf.getParameters().put('Id',opportunity.Id);
 
        Test.setCurrentPage(PDf);
        CASLetterPDFCtrl.getCASLetterPDFData();

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
        opportunity.Passport__c = 'Outstanding';
        opportunity.Degree_Transcript__c = 'Outstanding';
        opportunity.Degree_Certificate__c = 'Outstanding';
        opportunity.Proof_of_Exemptions__c = 'Outstanding';
        opportunity.Visa_Confirmation__c = 'Outstanding';
        opportunity.EU_Settlement_Evidence__c = 'Outstanding';
        opportunity.BCAT__c = 'Outstanding';
        opportunity.Inn_of_Court__c = 'Outstanding';
        opportunity.Certificate_of_Academic_Standing__c = 'Outstanding';
        opportunity.Faculty_Approval__c = 'Outstanding';
        opportunity.ACCA_Status_Report__c = 'Outstanding';
        opportunity.School_Leaving_Level_3_Certificate__c = 'Outstanding';
        opportunity.Highest_Qualification_Certificate__c = 'Outstanding';
        opportunity.Highest_Qualification_Transcript__c = 'Outstanding';
        opportunity.Confirmation_of_Contact_Details__c = 'Outstanding';
        opportunity.English_Language_Certificate__c = 'Outstanding';
        opportunity.BRP__c = 'Outstanding';
        opportunity.GDL_PGDL_Transcript__c = 'Outstanding';
        opportunity.Stamped_Entry_Clearance__c = 'Outstanding';
        opportunity.CAS_status__c = 'Not Required';
        opportunity.CAS_Letter_Sent__c = False;
        //opportunity.BPP_CAS_Number__c = '6546576OH98';
        opportunity.BPP_Date_CAS_Issued__c = Date.valueOf('2023-01-01');
        opportunity.BPP_CAS_Start_Date__c = Date.valueOf('2027-03-03');
        opportunity.BPP_CAS_End_Date__c = Date.valueOf('2026-02-02');
        opportunity.BPP_CAS_Last_Updated__c = Date.valueOf('2027-01-01');
        opportunity.BPP_Last_Enrolment_Date__c = Date.valueOf('2023-03-01');
        opportunity.BPP_Course_Level__c = 'RQF Level 7';
        opportunity.BPP_Previous_Course_Level__c = 'RQF Level 6';
        opportunity.CAS_Progression_Justification__c = 'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.';
        

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

  
}