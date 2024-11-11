@isTest
public class testRFIController {
private static testMethod  void rfi_controllerTest1() {
    
    /*
    RFI_ROUTING__c rfiRouting = new RFI_ROUTING__c();
    rfiRouting.rfi_Are_you_currently_studying_with_us__c = null;
    rfiRouting.are_you_eu_uk__c = 'UK (EU) Student';
    rfiRouting.rfi_Area_of_Interest__c = 'Human Resources';
    rfiRouting.Rfi_Level_of_study__c = 'Undergraduate';
    rfiRouting.RFI_Course_of_Interest__c = 'CIMA';
    rfiRouting.Name = 'Test';
    rfiRouting.Create_Task__c = true;
    system.debug('Inserting rfiRouting');
    insert rfiRouting;
    */
    
    RFI_ROUTING__c rfiRouting = new RFI_ROUTING__c();
    rfiRouting.rfi_Are_you_currently_studying_with_us__c = 'No';
    rfiRouting.are_you_eu_uk__c = 'UK (EU) Student';
    rfiRouting.rfi_Area_of_Interest__c = 'Human Resources';
    rfiRouting.Rfi_Level_of_study__c = 'Undergraduate';
    rfiRouting.RFI_Course_of_Interest__c = 'CIMA';
    rfiRouting.Name = 'Test';
    rfiRouting.Create_Task__c = true;
    rfiRouting.Destination_queue__c = 'Test Queue';
    rfiRouting.Destination_Role__c = 'Test Role';
    //rfiRouting.Destination_user__c = '00520000001imuI';
    rfiRouting.Department__c = 'Test Dept'; 
    system.debug('Inserting rfiRouting');
    insert rfiRouting;  
    system.debug('*****rfiRouting: ' + rfiRouting);
    
    country_list__c countryList = new country_list__c();
    countryList.Name = 'UNITED KINGDOM';
    countryList.country_code_2__c = 'GB'; 
    countryList.enabled__c = true;
    //countryList.ISO_CODE__c = 'UK';
    system.debug('*****Inserting countryList');
    insert countryList;
    
    country_list__c countryList_All = new country_list__c();
    countryList_All.Name = 'UNITED STATES';
    countryList_All.country_code_2__c = 'US';
    countryList_All.enabled__c = true;
    insert countryList_All;
            
    
    
    //start test
    //create controller object instance to test against
    ApexPages.StandardController con = new ApexPages.StandardController(new rfi_temp__c());               
    RFIcontrollerFixv3 Ctlr = new RFIcontrollerFixv3(con);
    // point the test instance to a page 
    PageReference pageRef1 = new PageReference('/apex/rfi_fixv3');
    Test.setCurrentPage(pageRef1);
            
    
    Ctlr.thelead.rfi_Are_you_EU_UK__c = 'UK (EU) Student';
    Ctlr.thelead.Rfi_Level_of_study__c = 'Undergraduate';
    Ctlr.thelead.rfi_Area_of_Interest__c = 'Human Resources';
    Ctlr.thelead.rfi_Course_of_Interest__c = 'CIMA';
    Ctlr.thelead.rfi_Start_Year__c = '2014';
    Ctlr.thelead.rfi_Start_Month__c = '01';
    Ctlr.thelead.rfi_Are_you_currently_studying_with_us__c = 'No';
    Ctlr.thelead.rfi_How_did_you_hear_about_us__c = 'Test';
    Ctlr.thelead.FirstName = 'Test';
    Ctlr.thelead.LastName = 'Test';
    Ctlr.thelead.Email = 'test@fake.com';
    Ctlr.thelead.Phone = '888-555-1234';
    Ctlr.existingStudent = 'No';
    //Ctlr.thelead.Country = 'UNITED KINGDOM';
    Ctlr.thelead.Country__c = countryList.id;
    Ctlr.thelead.PostalCode = '60512';
    Ctlr.thelead.RFI_Opt_In__c = true;
    Ctlr.thelead.rfi_What_is_your_query_about__c = 'Booking a New Course';
    //Ctlr.thelead.srn__c = '12345';
    Ctlr.thelead.rfi_What_are_you_Studying__c = 'Test';
    Ctlr.levelOfStudyVal = 'Test';
    Ctlr.selectedLevel0 = 'Undergraduate';
    Ctlr.selectedLevel1 = 'Human Resources';
    Ctlr.selectedLevel2 = 'CIMA';
    
       
    test.starttest();   
    
    Ctlr.getCountries();
    Ctlr.dummyMethod();
    Ctlr.bookNewCourse();
    Ctlr.existingStudentCheck();
    Ctlr.reloadCourseField();
    List<selectOption> level0 = Ctlr.level0Items; 
    List<selectOption> level1 = Ctlr.level1Items;
    List<selectOption> level2 = Ctlr.level2Items;
    Ctlr.thelead.srn__c = '12345';
        
    Ctlr.save();
    
    //end test
    test.stoptest(); 

   }
}