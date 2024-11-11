@isTest()
public class Booking_BookingService_TEST {

    private static final String STUDENT_PROFILE = 'student-abc123';
    private static final String TM_PROFILE = 'tm-abc123';
    private static final String COMPANY_PROFILE = 'company-abc123';
    private static final String PRODUCT_ID = '99999';
    
    public static testMethod void testCreateUpdateBooking() {
        
        Booking_Rest_Controller.BookingDTO dto = new Booking_Rest_Controller.BookingDTO();
        dto.studentAccountProfileId = STUDENT_PROFILE;
        dto.orderNumber = '101';
        dto.productInstanceId = PRODUCT_ID;
        dto.trainingMangerProfileId = TM_PROFILE;
        dto.companyProfileId = COMPANY_PROFILE;
        List<String> details = new List<String>();
        details.add('testing details');
        dto.detailLineItems = details;
        dto.cost = 1.00;
        
        createMockStudentData();
        Booking_BookingService serviceUnderTest = new Booking_BookingServiceImpl();
        serviceUnderTest.createUpdateBooking(dto);
    }
    
    private static void createMockStudentData() {
        RecordType recordtype = [Select Id, DeveloperName From RecordType Where SobjectType = 'Account' AND DeveloperName =: 'Student_Account' Limit 1];   
        Account studentAccount = new Account();
        studentAccount.RecordTypeId = recordType.Id;
        studentAccount.FirstName = 'UNIT';
        studentAccount.LastName = 'Test';
        studentAccount.Preferred_Email__pc = 'Personal';
        studentAccount.PersonEmail = 'john@john.com';
        studentAccount.Personal_Email__pc ='john@john.com';
        studentAccount.PS_Profile_Services_ID__pc = STUDENT_PROFILE;
        insert studentAccount;
        
        Product2 product = new Product2();
        product.Name = 'Unit Test Product';
        product.Instance_Id__c = PRODUCT_ID;
        insert product;
        
        recordtype = [Select Id, DeveloperName From RecordType Where SobjectType = 'Account' AND DeveloperName =: 'Business_Development_Account' Limit 1];   
        Account companyAccount = new Account();
        companyAccount.RecordTypeId = recordType.Id;
        companyAccount.Name = 'Unit Company';
        companyAccount.Profile_Company_ID__c = COMPANY_PROFILE;
        insert companyAccount;
        
        recordtype = [Select Id, DeveloperName From RecordType Where SobjectType = 'Contact' AND DeveloperName =: 'Training_Manager' Limit 1];   
        Contact trainingManager = new Contact();
        trainingManager.RecordTypeId = recordType.Id;
        trainingManager.PS_Profile_Services_ID__c = TM_PROFILE;
        trainingManager.AccountId = companyAccount.Id;
        trainingManager.FirstName = 'Unit';
        trainingManager.LastName = 'Test';
        trainingManager.Preferred_Email__c = 'Personal';
        trainingManager.Personal_Email__c ='john123@john.com';
        trainingManager.Active__c = true;
        insert trainingManager;
                
    }
    
}