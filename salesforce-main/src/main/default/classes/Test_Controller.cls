/**
 * This class contains unit tests for validating the behavior of Apex classe Application_wiz_controller
 */
@isTest
private class Test_Controller {
    @TestSetup
    static void setup() {
        insert new Country_List__c(
            ISO_CODE__c = 'GB',
            country_code_2__c = 'GB',
            Valid_Nationality__c = true
        );
    }

    static testMethod  void application_wiz_controllerTest1() {
        //start test
        Programme__c prg = new Programme__c();
        prg.Name = 'ACCA (3 Papers)';
        insert prg;
        Mode__c mod = new Mode__c();
        mod.Name = 'Full Time';
        insert mod;
        Campus__c cam = new Campus__c();
        cam.Display_Name__c = 'london';
        cam.Name = 'Lond';        
        insert cam;
        Product2 prod = new Product2();
        prod.Name = 'test';
        prod.IsActive = true;
        prod.On_Web__c = true;
        prod.Programme__c = prg.id;  
        prod.BPP_ProductFactoryID__c = 'qwertyuiop';
        prod.Family = 'Materials';
        prod.Standalone_Material__c = FALSE;
        insert prod;
        Web_Course_Offering__c weCo = new Web_Course_Offering__c();
        weCo.Programme__c = prg.id;
        weCo.Mode__c = mod.Id;
        weCo.Campus__c = cam.Id;
        weCo.Intake_Month__c = '12';
        weCo.Course_Instance_ID__c = prod.Id;
        weCo.Active__c = true;
        weCo.Start_Date__c =  Date.newInstance(2018, 2,1);
        insert weCo;
        test.starttest();
        PageReference pageRef1 = new PageReference('/apex/application_create_account');
        Test.setCurrentPage(pageRef1); 
        //create controller object instance to test against
        ApexPages.StandardController con = new ApexPages.StandardController(new Application_wizard__c());               
        application_wiz_controller Ctlr = new application_wiz_controller(con);
        
         Web_Course_Offering__c wco = [Select w.start_year__c, w.start_month__c, w.Programme__c, w.Mode__c, w.Id, w.Course_Instance_ID__c, w.Campus__c, w.Active__c 
                                         From Web_Course_Offering__c w 
                                        where w.Programme__r.Name = 'ACCA (3 Papers)' limit 1];
        Campus__c loc = [SELECT Id, Display_Name__c  FROM Campus__c limit 1];
        string ll = loc.id;      
        country_list__c cl = [SELECT Id, Name, enabled__c, region__c, economic_grouping__c FROM country_list__c limit 1];
        //Create the Application wizard object
        Application_wizard__c awt = new Application_wizard__c(first_name__c='TESTMETHOD',password__c='trial1234', last_name__c='TESTMETHOD',email__c='tester@test.edu');
        awt.Title__c = 'Mr';
        awt.Country_of_birth__c = cl.id;
        awt.Country_of_Domicile_Permanent_Residency__c = cl.id;
        awt.Nationality__c = cl.id;     
        awt.Security_Token__c = Ctlr.generateSecurityToken();
        awt.Security_Expiry_Date__c = system.Now().addDays(1);
        awt.Passport_date_expected__c = system.today().addDays(-1);
        awt.Visa_date_expected__c = system.today().addDays(-1);
        awt.Academic_date_expected__c = system.today().addDays(-1);
        awt.Visa_Refusal_date_expected__c = system.today().addDays(-1);
        awt.Attendance_date_expected__c = system.today().addDays(-1);
        awt.ACCA_date_expected__c = system.today().addDays(-1);
        awt.English_date_expected__c = system.today().addDays(-1);
        awt.References_date_expected__c = system.today().addDays(-1);
        string auth_id = awt.Security_Token__c;
        awt.Payment_Option__c = 'Company/Law Firm';
        awt.Are_you_currently_studying_in_UK__c = 'Yes';
        awt.Any_close_relatives_in_UK__c = 'Yes';
        awt.Planning_to_stay_with_relatives_in_uk__c = 'Yes';
        awt.staying_in_UK_after_course__c = 'Yes';
        awt.Any_criminal_convictions__c = 'Yes';
        awt.Any_Learning_Requirements__c = 'Yes';
        awt.EEA_citizen__c = 'No';
        awt.F1__c = true;awt.F2__c = true;awt.F3__c = true;awt.F4__c = true;awt.F5__c = true;
        awt.F6__c = true;awt.F7__c = true;awt.F8__c = true;awt.F9__c = true;
        awt.P1__c = true;awt.P2__c = true;awt.P3__c = true;awt.P4__c = true;
        awt.P5__c = true;awt.P6__c = true;awt.P7__c = true;
        awt.personal_statement__c = 'Please supply any additional information to support your application. This may include reasons for wanting to study your chosen course or why you feel suited to the programme for which you are applying.  Minimum 250 words.Please supply any additional information to support your application. This may include reasons for wanting to study your chosen course or why you feel suited to the programme for which you are applying.  Minimum 250 words.Please supply any additional information to support your application. This may include reasons for wanting to study your chosen course or why you feel suited to the programme for which you are applying.  Minimum 250 words.Please supply any additional information to support your application. This may include reasons for wanting to study your chosen course or why you feel suited to the programme for which you are applying.  Minimum 250 words.Please supply any additional information to support your application. This may include reasons for wanting to study your chosen course or why you feel suited to the programme for which you are applying.  Minimum 250 words.Please supply any additional information to support your application. This may include reasons for wanting to study your chosen course or why you feel suited to the programme for which you are applying.  Minimum 250 words.Please supply any additional information to support your application. This may include reasons for wanting to study your chosen course or why you feel suited to the programme for which you are applying.  Minimum 250 words.';
        awt.Are_you_currently_in_Uk_with_a_visa__c = 'Yes';
        awt.Ever_studied_in_UK_before__c = 'Yes';
        awt.kin_address_line1__c = 'scg';
        awt.kin_city__c = 'scha';
        awt.kin_country__c = cl.id;
        awt.kin_postcode__c = '23423';
        insert(awt);
        insertData();
 
        string WIZ_ID1 = awt.id;
        //string auth_id = generateSecurityToken();
        Programme__c pgm = [SELECT Id, Name, Description__c FROM Programme__c limit 1];
        string lp=pgm.id;
        Mode__c  md = [SELECT  Id, Name FROM Mode__c limit 1];
        string lm =md.id;
        //Go to the personal details page    
        pageRef1 = new PageReference('/apex/application_personal_details?wiz_id='+WIZ_ID1+'&auth_id='+auth_id);
        Test.setCurrentPage(pageRef1); 
        //create controller object instance to test against
        con = new ApexPages.StandardController(new Application_wizard__c());               
        Ctlr = new application_wiz_controller(con);
        // point the test instance to a page 
        
        // methods to test and vars to set
        Ctlr.intLocal(awt);
        Ctlr.listlocation = ll ;
        Ctlr.isEEA(cl.id);
        
        Ctlr.listprogramme= lp;
        Ctlr.listmodes= lm;
        Ctlr.listmonths='1'; 
        Ctlr.getNationality();
        Ctlr.getYears();
        Ctlr.getProgYear();
        Ctlr.getYesNo();
        Ctlr.getNoYes();
        Ctlr.setProgYear('2011');
        Ctlr.getPYear();
        Ctlr.getCountrys();
        Ctlr.getStates();
        Ctlr.progYear='2011';  
        Ctlr.getMonthss();  
        Ctlr.getModes();  
        Ctlr.getProgrammes();  
        Ctlr.getLocations();  
        Ctlr.getListmonths();
        Ctlr.getListmodes();
        Ctlr.getListlocation();
        Ctlr.getListprogramme();
        Ctlr.cancel();
        Ctlr.prev();
        Ctlr.prev1();
        Ctlr.save();
          
        Ctlr.doPDF();
        Ctlr.lastname='TESTMETHOD';
        Ctlr.email ='tester@test.edu';
        Ctlr.Username ='tester@test.edu';
        Ctlr.password = 'trial1234';        
        
        
        Ctlr.setListmonths('1');
        Ctlr.setListLocation(ll) ;
        Ctlr.setListmodes(lm);
        Ctlr.setListprogramme(lp);
        Ctlr.employment[0].Name_of_employer__c='TESTMETHOD';
        Ctlr.saveEmpNext();
        Ctlr.employment[0].Job_Title__c='TESTMETHOD';
        Ctlr.saveEmpNext();
        Ctlr.employment[0].description__c='TESTMETHOD';
        Ctlr.saveEmpNext();
        Ctlr.employment[0].from__c=system.today().addDays(-1);
        Ctlr.saveEmpNext();
        Ctlr.nextPage= 'application_international_history';
        Ctlr.saveEmpNext();
        Ctlr.saveEmp();
        Ctlr.submitapp();
        Ctlr.intLocal(awt);
        Ctlr.Redirect_UnAuthorized_Access();
        Ctlr.save();
        
        Ctlr.CreateAccount();
       // Ctlr.CreateOpportunity();
        
       
        pageRef1 = new PageReference('/apex/application_employment_history?wiz_id='+WIZ_ID1+'&auth_id='+auth_id);
       Test.setCurrentPage(pageRef1); 
       //create controller object instance to test against
        con = new ApexPages.StandardController(new Application_wizard__c());               
        Ctlr = new application_wiz_controller(con); 
        Ctlr.addnewRow_EmpHistory();
        Ctlr.saveEmpNext();
        
        pageRef1 = new PageReference('/apex/application_education_history?wiz_id='+WIZ_ID1+'&auth_id='+auth_id);
       Test.setCurrentPage(pageRef1); 
       //create controller object instance to test against
        con = new ApexPages.StandardController(new Application_wizard__c());               
        Ctlr = new application_wiz_controller(con); 
        Ctlr.nextPage= 'application_education_history';
        Ctlr.saveNextEdu();
        Ctlr.listprogramme= wco.Programme__c;
        Ctlr.listlocation = wco.Campus__c;
        Ctlr.listmodes = wco.Mode__c;
        Ctlr.listmonths = String.valueOf(wco.start_month__c);
        Ctlr.progYear = String.valueOf(wco.start_year__c);
        Ctlr.saveNextEdu();
        
        Ctlr.nextPage= 'application_attachments';
        Ctlr.saveEmpNext();
        Ctlr.nextPage= 'application_submit';
        Ctlr.saveEmpNext();
        Ctlr.nextPage= 'application_references_personal';
        Ctlr.saveEmpNext();
        Ctlr.nextPage= 'application_other_details';
        Ctlr.visalist[0].Visa_Issue_Date__c = system.today().addDays(1);
        Ctlr.saveEmpNext();
        Ctlr.visalist[0].Visa_Expiry_Date__c = system.today().addDays(-1);
        Ctlr.saveEmpNext();
        Ctlr.visalist[0].Visa_Type__c = 'Other';
        Ctlr.saveEmpNext();
        Ctlr.visalist[0].Visa_Qualification__c = 'dsdf';
        Ctlr.saveEmpNext();
        Ctlr.visalist[0].Visa_Institution__c = 'Other';
        Ctlr.saveEmpNext();
        Ctlr.visalist[0].Level_of_Studies__c = 'NQF level 1';
        Ctlr.saveEmpNext();
        Ctlr.visalist[0].Completed_Course_at_Visa_Institution__c = 'No';
        Ctlr.saveEmpNext();
        Ctlr.visalist[0].Actual_Qualification_Institution__c = 'dsdf';
        Ctlr.saveEmpNext();
        Ctlr.nextPage= 'application_employment_history';
        Ctlr.edlist[0].subject__c = 'Actual';
        Ctlr.edlisth[0].subject__c = 'Actual';
        Ctlr.edlisto[0].subject__c = 'Actual'; 
        Ctlr.saveNextEdu();
        Ctlr.edlist[0].predicted_actual__c = 'Actual';
        Ctlr.edlisth[0].predicted_actual__c = 'Actual';
        Ctlr.edlisto[0].predicted_actual__c = 'Actual';
        Ctlr.saveNextEdu();
        Ctlr.edlist[0].Grade__c = 'Actual';
        Ctlr.edlisth[0].Grade__c = 'Actual';
        Ctlr.edlisto[0].Grade__c = 'Actual';
        Ctlr.saveNextEdu();
        Ctlr.edlist[0].institution__c = 'Actual';
        Ctlr.edlisth[0].institution__c = 'Actual';
        Ctlr.edlisto[0].institution__c = 'Actual';
        Ctlr.saveNextEdu();
        Ctlr.edlist[0].Qualification__c = 'Actual';
        Ctlr.edlisth[0].Mode_of_Study__c = 'Actual';
        Ctlr.edlisto[0].Other_Qualification__c = 'Actual';
        Ctlr.saveNextEdu();
        
        Ctlr.addnewRow_HE();
        Ctlr.addnewRow_HS();
        Ctlr.addnewRow_OQ();
        //Account acc = new Account(FirstName='TESTMETHOD',Phone='3242343543',PersonBirthdate = awt.Date_of_Birth__c, LastName='TESTMETHOD',PersonEmail='tester@test.edu');
        //insert acc;
        Ctlr.submitapp();       
        Ctlr.wiz_id = null;
        Ctlr.Redirect_UnAuthorized_Access();
        test.stoptest();  
   } 
  
    static testMethod  void application_wiz_controllerTest2() {
        //start test
        test.starttest();
        PageReference pageRef1 = new PageReference('/apex/application_create_account');
        Test.setCurrentPage(pageRef1); 
        //create controller object instance to test against
        ApexPages.StandardController con = new ApexPages.StandardController(new Application_wizard__c());               
        application_wiz_controller Ctlr = new application_wiz_controller(con);
        Application_wizard__c awt = new Application_wizard__c(first_name__c='TESTMETHOD',password__c='trial1234', last_name__c='TESTMETHOD',email__c='tester@test.edu');
        awt.Country_of_birth__c = cl.id;
        awt.Country_of_Domicile_Permanent_Residency__c = cl.id;
        awt.Nationality__c = cl.id;     
        
        
        awt.Security_Token__c = Ctlr.generateSecurityToken();
        awt.Security_Expiry_Date__c = system.Now().addDays(1);
        awt.Internal_Tracking_Status__c = 'Active';
        awt.Is_english_your_first_language__c = 'No';
        awt.Minimum_1_Year_Post_Education__c = 'No';
        awt.Date_of_Birth__c = system.today().addDays(1);
        awt.telephone__c = '32423';
        awt.EEA_citizen__c = '--None--';
        awt.Do_you_have_indefinite_leave__c = 'Yes';
        string auth_id = awt.Security_Token__c;
        awt.Ever_studied_in_UK_before__c = 'Yes';
        insert(awt);
        insertData();
 
        string WIZ_ID1 = awt.id;
        
        pageRef1 = new PageReference('/apex/application_personal_details?wiz_id='+WIZ_ID1+'&auth_id='+auth_id);
        Test.setCurrentPage(pageRef1); 
        //create controller object instance to test against
        con = new ApexPages.StandardController(new Application_wizard__c());               
        Ctlr = new application_wiz_controller(con);
        Ctlr.save();
        
        Ctlr.nextPage= 'application_employment_history';
        
        //When the values are null
        Ctlr.PopulateExistingInformation();
        Ctlr.SendUserName();
        Ctlr.ResetPassword();
        Ctlr.saveFind();
        Ctlr.newUserReg();
         Ctlr.saveNextReference();  
         Ctlr.saveNextEdu();
         Ctlr.isDomestic = true;
         Ctlr.saveNextReference();
               
        Ctlr.nextPage= 'application_international_history';
        Ctlr.saveEmpNext();
        Ctlr.nextPage= 'application_other_details';
        Ctlr.saveEmpNext();
        Ctlr.nextPage= 'application_submit';
        Ctlr.isDomestic = false;
        Ctlr.saveEmpNext();
        Ctlr.saveNextReference();
        Ctlr.nextPage= 'application_attachments';
        Ctlr.isDomestic = false;
        Ctlr.saveEmpNext();
        
        Ctlr.lastname='TESTMETHOD';
        Ctlr.email ='tester@test.edu';
        Ctlr.Username ='tester@test.edu';
        //error out
        Ctlr.password = 'al1234';
        Ctlr.email2 = 'ds';
        Ctlr.password2 = 'dsd';
        Ctlr.saveFind();
        Ctlr.newUserReg();
        Ctlr.firstname = 'TESTMETH';
        Ctlr.SendUserName();
        Ctlr.ResetPassword();
        //Correct values
        Ctlr.password = 'trial1234';
        Ctlr.password2 = 'trial1234';
        Ctlr.email2 = 'tester@test.edu';        
        
        Ctlr.saveFind();
        Ctlr.firstname = 'TESTMETHOD';
        Ctlr.newUserReg();
        Ctlr.SendUserName();
        Ctlr.ResetPassword();        
        
         /*//point the test instance to a page 
         Ctlr.firstname = 'TestFN';
         Ctlr.lastname='TESTMETHOD';
         Ctlr.email='tester@test.edu';
         Ctlr.password='password';
         Ctlr.saveFind();
         Ctlr.aw.Is_english_your_first_language__c = 'No';
         Ctlr.aw.last_Name__c= Null; 
         Ctlr.aw.email__c = Null;
         Ctlr.aw.Are_yu_being_sponsored_for_the_programme__c ='Yes';
         Ctlr.progYear='2011';
         Ctlr.listmonths='9';
         Ctlr.save();*/
         
        
         awt.Submitted__c = true;
         awt.Is_english_your_first_language__c = 'Yes';
        awt.Minimum_1_Year_Post_Education__c = 'Yes';
        update awt;
        Ctlr.nextPage= 'application_employment_history';
        Ctlr.saveNextEdu();
        Ctlr.Redirect_UnAuthorized_Access();
        Ctlr.saveFind();
        auth_id=Ctlr.generateSecurityToken();
        Ctlr.Redirect_UnAuthorized_Access();
        awt.Submitted__c = false;
        awt.Internal_Tracking_Status__c = 'In-Active';
        update awt;
        Ctlr.newUserReg();
        Ctlr.saveFind();
        
        // Ctlr.save();
        test.stoptest(); 
   }
   
   static testMethod  void application_wiz_controllerTest3() {
        //start test
        Programme__c prg = new Programme__c();
        prg.Name = 'Summer School - Business';
        insert prg;
         Mode__c mod = new Mode__c();
        mod.Name = 'Full Time';
        insert mod;
        Campus__c cam = new Campus__c();
        cam.Display_Name__c = 'london';
        cam.Name = 'Lond';        
        insert cam;
        Product2 prod = new Product2();
        prod.Name = 'test';
        prod.IsActive = true;
        prod.On_Web__c = true;
        prod.Programme__c = prg.id;    
       	prod.BPP_ProductFactoryID__c = 'qwertyuiop2';
        prod.Family = 'Materials';
        prod.Standalone_Material__c = FALSE;
        insert prod;
        Web_Course_Offering__c weCo = new Web_Course_Offering__c();
        weCo.Programme__c = prg.id;
        weCo.Mode__c = mod.Id;
        weCo.Campus__c = cam.Id;
        weCo.Intake_Month__c = '12';
        weCo.Course_Instance_ID__c = prod.Id;
        weCo.Active__c = true;
        weCo.Start_Date__c =  Date.newInstance(2018, 2,1);
        insert weCo;
        Web_Course_Offering__c wco = [Select w.start_year__c, w.start_month__c, w.Programme__c, w.Mode__c, w.Id, w.Course_Instance_ID__c, w.Campus__c, w.Active__c 
                                    From Web_Course_Offering__c w 
                                    where w.Programme__r.Name = 'Summer School - Business' limit 1];
        
        test.starttest();
        PageReference pageRef1 = new PageReference('/apex/application_create_account');
        Test.setCurrentPage(pageRef1); 
        //create controller object instance to test against
        ApexPages.StandardController con = new ApexPages.StandardController(new Application_wizard__c());               
        application_wiz_controller Ctlr = new application_wiz_controller(con);
        Ctlr.lastname='TESTMETHOD';
        Ctlr.email ='tester@test.edu';
        Ctlr.password = 'trial1234';
        Ctlr.password2 = 'trial1234';
        Ctlr.email2 = 'tester@test.edu';
        Ctlr.firstname = 'TESTMETHOD';
        Ctlr.newUserReg();
        country_list__c cl = [SELECT Id, Name, enabled__c, region__c, economic_grouping__c FROM country_list__c limit 1];
        Application_wizard__c awt = new Application_wizard__c(first_name__c='TESTMETHOD',password__c='trial1234', last_name__c='TESTMETHOD',email__c='tester@test.edu');
        awt.Security_Token__c = Ctlr.generateSecurityToken();
        awt.Security_Expiry_Date__c = system.Now().addDays(1);
        awt.Internal_Tracking_Status__c = 'Active';
        awt.Payment_Option__c = 'I will';
        awt.EEA_citizen__c = 'Yes';
        awt.Is_english_your_first_language__c = 'Yes';
        
        awt.Title__c = 'Mr';
        awt.Gender__c = 'Male';
        awt.Ethnicity__c = '10 White';
        awt.Date_of_Birth__c = Date.valueOf('2000-10-30');
        awt.Address_Line_1__c = 'Bone';
        awt.Preferred_Telephone__c = 'Home';
        awt.telephone__c = '3242343543';
        awt.City__c = 'sc';
        awt.country__c = cl.id;
        awt.Postal_Code__c = '323432'; 
        awt.Country_of_birth__c = cl.id;
        awt.Country_of_Domicile_Permanent_Residency__c = cl.id;
        awt.Names_as_per_passport__c = true;
        awt.Nationality__c = cl.id;
        awt.Conditions_of_residency__c = 'dfsd';
        awt.Do_you_have_indefinite_leave__c = 'Yes';
        
        awt.personal_statement__c = 'Please supply any additional information to support your application. This may include reasons for wanting to study your chosen course or why you feel suited to the programme for which you are applying.  Minimum 250 words.Please supply any additional information to support your application. This may include reasons for wanting to study your chosen course or why you feel suited to the programme for which you are applying.  Minimum 250 words.Please supply any additional information to support your application. This may include reasons for wanting to study your chosen course or why you feel suited to the programme for which you are applying.  Minimum 250 words.Please supply any additional information to support your application. This may include reasons for wanting to study your chosen course or why you feel suited to the programme for which you are applying.  Minimum 250 words.Please supply any additional information to support your application. This may include reasons for wanting to study your chosen course or why you feel suited to the programme for which you are applying.  Minimum 250 words.Please supply any additional information to support your application. This may include reasons for wanting to study your chosen course or why you feel suited to the programme for which you are applying.  Minimum 250 words.Please supply any additional information to support your application. This may include reasons for wanting to study your chosen course or why you feel suited to the programme for which you are applying.  Minimum 250 words.';
        string auth_id = awt.Security_Token__c;
        awt.Submitted__c = true;
        awt.Mode__c = wco.Mode__c; 
        awt.Location__c = wco.Campus__c;
        awt.programme__c = wco.Programme__c;
        awt.course_year__c = String.valueOf(wco.start_year__c);
        awt.month__c = String.valueOf(wco.start_month__c);
        awt.App_Wiz_Student_Type__c = 'Domestic';
        insert(awt);
        insertData();
 
        string WIZ_ID1 = awt.id;
        
        pageRef1 = new PageReference('/apex/application_references_personal?wiz_id='+WIZ_ID1+'&auth_id='+auth_id);
       Test.setCurrentPage(pageRef1); 
       //create controller object instance to test against
        con = new ApexPages.StandardController(new Application_wizard__c());               
        Ctlr = new application_wiz_controller(con);
        Ctlr.save();
        Ctlr.Reference[0].Reference_name__c='TESTMETHOD';
        Ctlr.saveNextReference();
        Ctlr.Reference[0].Reference_Position__c = 'dsd';
        Ctlr.saveNextReference();
        Ctlr.Reference[0].Address_Line1__c = 'dfs';
        Ctlr.saveNextReference();
        Ctlr.Reference[0].reference_city__c = 'dfs';        
        
        Ctlr.saveReference();
        Ctlr.addnewReferences();
        
        Ctlr.saveNextReference();
        Ctlr.Reference[0].reference_telephone__c='abadphone';
        Ctlr.saveNextReference();
        
        Ctlr.nextPage= 'application_international_history';
        Ctlr.addnewVisa();
        Ctlr.saveEmpNext();        
        
        pageRef1 = new PageReference('/apex/application_payment_sponsorship?wiz_id='+WIZ_ID1+'&auth_id='+auth_id);
        Test.setCurrentPage(pageRef1); 
        //create controller object instance to test against
        con = new ApexPages.StandardController(new Application_wizard__c());               
        Ctlr = new application_wiz_controller(con);
        Ctlr.getPaymentOptions();
        Ctlr.Redirect_UnAuthorized_Access();
        //Ctlr.VisaUploadFile();
        
        Ctlr.isDomestic = false;
        Ctlr.saveNextReference();
        //Ctlr.submitapp1();
        /*awt.telephone__c = '9438540843';
        awt.Date_of_Birth__c = Date.newInstance(1984,12,5);
        update awt;
        Ctlr.submitapp1();
        awt.telephone__c = '9438540800';
        awt.Email__c = 'test@test1.com';
        update awt;
        Ctlr.submitapp1();
        awt.Date_of_Birth__c = Date.newInstance(1989,12,5);
        awt.Postal_Code__c = '90909';
        update awt;
        Ctlr.submitapp1();*/
        test.stopTest();
   }
   
   static testMethod  void application_wiz_controllerTest4() {
        Programme__c prg = new Programme__c();
        prg.Name = 'Summer School - Business';
        insert prg;
        Mode__c mod = new Mode__c();
        mod.Name = 'Full Time';
        insert mod;
        Campus__c cam = new Campus__c();
        cam.Display_Name__c = 'london';
        cam.Name = 'Lond';        
        insert cam;
        Product2 prod = new Product2();
        prod.Name = 'test';
        prod.IsActive = true;
        prod.On_Web__c = true;
        prod.Programme__c = prg.id;  
        prod.BPP_ProductFactoryID__c = 'qwertyuiop3';
        prod.Family = 'Materials';
        prod.Standalone_Material__c = FALSE;
        insert prod;
        Web_Course_Offering__c weCo = new Web_Course_Offering__c();
        weCo.Programme__c = prg.id;
        weCo.Mode__c = mod.Id;
        weCo.Campus__c = cam.Id;
        weCo.Intake_Month__c = '12';
        weCo.Course_Instance_ID__c = prod.Id;
        weCo.Active__c = true;
        weCo.Start_Date__c =  Date.newInstance(2018, 2,1);
        insert weCo;
        //start test
        test.starttest();
        
        PageReference pageRef1 = new PageReference('/apex/application_create_account');
        Test.setCurrentPage(pageRef1);
        //create controller object instance to test against
        ApexPages.StandardController con = new ApexPages.StandardController(new Application_wizard__c());               
        application_wiz_controller Ctlr = new application_wiz_controller(con);
        country_list__c cl = [SELECT Id, Name, enabled__c, region__c, economic_grouping__c FROM country_list__c limit 1];
        Web_Course_Offering__c wco = [Select w.start_year__c, w.start_month__c, w.Programme__c, w.Mode__c, w.Id, w.Course_Instance_ID__c, w.Campus__c, w.Active__c 
                                    From Web_Course_Offering__c w 
                                    where w.Programme__r.Name = 'Summer School - Business' limit 1];
        
        Application_wizard__c awt = new Application_wizard__c(first_name__c='TESTMETHOD',password__c='trial1234', last_name__c='TESTMETHOD',email__c='tester@test.edu');
        awt.Country_of_birth__c = cl.id;
        awt.Country_of_Domicile_Permanent_Residency__c = cl.id;
        awt.Nationality__c = cl.id;   
        awt.programme__c = wco.Programme__c;
        awt.App_Wiz_Student_Type__c = 'Domestic';
        
        awt.Security_Token__c = Ctlr.generateSecurityToken();
        awt.Security_Expiry_Date__c = system.Now().addDays(1);
        awt.Internal_Tracking_Status__c = 'Active';
        awt.Is_english_your_first_language__c = 'No';
        awt.Minimum_1_Year_Post_Education__c = 'No';
        awt.Title__c = 'Mr';
        awt.Gender__c = 'Male';
        awt.Ethnicity__c = '10 White';
        awt.Date_of_Birth__c = Date.valueOf('1980-10-30');
        awt.Address_Line_1__c = 'Bone';
        awt.Preferred_Telephone__c = 'Home';
        awt.telephone__c = '3242343543';
        awt.EEA_citizen__c = 'Yes';
        awt.Do_you_have_indefinite_leave__c = 'Yes';
        awt.Correct_Information__c = true;
        string auth_id = awt.Security_Token__c;
        awt.Submitted__c = true;
        
        awt.Mode__c = wco.Mode__c; 
        awt.Location__c = wco.Campus__c;
        awt.programme__c = wco.Programme__c;
        awt.course_year__c = String.valueOf(wco.start_year__c);
        awt.month__c = String.valueOf(wco.start_month__c);
        insert(awt);
        insertData();
        string WIZ_ID1 = awt.id;        
        
        pageRef1 = new PageReference('/apex/application_references_personal?wiz_id='+WIZ_ID1+'&auth_id='+auth_id);
        Test.setCurrentPage(pageRef1); 
        //create controller object instance to test against
        con = new ApexPages.StandardController(new Application_wizard__c());               
        Ctlr = new application_wiz_controller(con);
        Ctlr.listprogramme= wco.Programme__c;
        Ctlr.listlocation = wco.Campus__c;
        Ctlr.listmodes = wco.Mode__c;
        
        Ctlr.nextPage= 'application_education_history';
        Ctlr.saveNextEdu();
        ctlr.edlisth[0].subject__c = 'Maths';
        ctlr.edlisth[0].Grade__c = 'A';
        ctlr.edlisth[0].institution__c ='MIS';
        ctlr.edlisth[0].predicted_actual__c = 'Actual';
        ctlr.edlisth[0].Mode_of_Study__c = 'Full Time';
        ctlr.aw.is_english_your_first_language__c = 'Yes';
        
        Ctlr.nextPage= 'application_employment_history';
        Ctlr.saveNextEdu();
        ctlr.aw.is_english_your_first_language__c = 'No';
        ctlr.aw.Minimum_1_Year_Post_Education__c = 'Yes';
        Ctlr.saveNextEdu();
        Ctlr.recordAssignment(wco.Programme__c,'Domestic');
        Ctlr.startNewApplication();
        Ctlr.getOtherCountrys();
        Ctlr.getEEACountrys();
        //Ctlr.limitprograms(wco.Campus__c);
        Ctlr.Checkmonth();   
        
        //Ctlr.submitapp();
        
        //Ctlr.submitapp1();
        
      /*   awt.Email__c = 'test@test.com';
        update awt;
        Ctlr.submitapp1();
       awt.First_name__c = 'ChangeTestFN';
        awt.last_Name__c = 'ChangeTestLN';
        update awt;
        Ctlr.submitapp1();
        */
        
        Ctlr.Redirect_UnAuthorized_Access();
        
       // Account acc = new Account(FirstName='TESTMETHOD',Phone='3242343543',PersonBirthdate = awt.Date_of_Birth__c, LastName='TESTMETHOD',PersonEmail='tester@test.edu');
        //insert acc;
        //Ctlr.submitapp();
        //Ctlr.submitapp1();
        test.stopTest();
   }
   
   static testMethod  void application_wiz_controllerTest5() {
        Programme__c prg = new Programme__c();
        prg.Name = 'Summer School - Business';
        insert prg;
        Mode__c mod = new Mode__c();
        mod.Name = 'Full Time';
        insert mod;
        Campus__c cam = new Campus__c();
        cam.Display_Name__c = 'london';
        cam.Name = 'Lond';        
        insert cam;
        Product2 prod = new Product2();
        prod.Name = 'test';
        prod.IsActive = true;
        prod.On_Web__c = true;
        prod.Programme__c = prg.id; 
		prod.BPP_ProductFactoryID__c = 'qwertyuiop4';
        prod.Family = 'Materials';
        prod.Standalone_Material__c = FALSE;       
        insert prod;
        Web_Course_Offering__c weCo = new Web_Course_Offering__c();
        weCo.Programme__c = prg.id;
        weCo.Mode__c = mod.Id;
        weCo.Campus__c = cam.Id;
        weCo.Intake_Month__c = '12';
        weCo.Course_Instance_ID__c = prod.Id;
        weCo.Active__c = true;
        weCo.Start_Date__c =  Date.newInstance(2018, 2,1);
        insert weCo;
        //start test
        test.starttest();
        
        PageReference pageRef1 = new PageReference('/apex/application_create_account');
        Test.setCurrentPage(pageRef1);
        //create controller object instance to test against
        ApexPages.StandardController con = new ApexPages.StandardController(new Application_wizard__c());               
        application_wiz_controller Ctlr = new application_wiz_controller(con);
        country_list__c cl = [SELECT Id, Name, enabled__c, region__c, economic_grouping__c FROM country_list__c limit 1];
        Web_Course_Offering__c wco = [Select w.start_year__c, w.start_month__c, w.Programme__c, w.Mode__c, w.Id, w.Course_Instance_ID__c, w.Campus__c, w.Active__c 
                                    From Web_Course_Offering__c w 
                                    where w.Programme__r.Name = 'Summer School - Business' limit 1];
        
        Application_wizard__c awt = new Application_wizard__c(first_name__c='TESTMETHOD',password__c='trial1234', last_name__c='TESTMETHOD',email__c='tester@test.edu');
        awt.Country_of_birth__c = cl.id;
        awt.Country_of_Domicile_Permanent_Residency__c = cl.id;
        awt.Nationality__c = cl.id;   
        awt.programme__c = wco.Programme__c;
        awt.App_Wiz_Student_Type__c = 'Domestic';
        
        awt.Security_Token__c = Ctlr.generateSecurityToken();
        awt.Security_Expiry_Date__c = system.Now().addDays(1);
        awt.Internal_Tracking_Status__c = 'Active';
        awt.Is_english_your_first_language__c = 'No';
        awt.Minimum_1_Year_Post_Education__c = 'No';
        awt.Title__c = 'Mr';
        awt.Gender__c = 'Male';
        awt.Ethnicity__c = '10 White';
        awt.Date_of_Birth__c = Date.valueOf('2000-10-30');
        awt.Address_Line_1__c = 'Bone';
        awt.telephone__c = '3242343543';
        awt.EEA_citizen__c = 'Yes';
        awt.Do_you_have_indefinite_leave__c = 'Yes';
        awt.Correct_Information__c = true;
        string auth_id = awt.Security_Token__c;
        awt.Submitted__c = true;
        
        awt.Mode__c = wco.Mode__c; 
        awt.Location__c = wco.Campus__c;
        awt.programme__c = wco.Programme__c;
        awt.course_year__c = String.valueOf(wco.start_year__c);
        awt.month__c = String.valueOf(wco.start_month__c);
        awt.Is_english_your_first_language__c = 'No';
        awt.Minimum_1_Year_Post_Education__c = '';
        awt.eng_exam_type__c = 'Other';
        awt.eng_exam_type_other__c = '';
        awt.personal_statement__c = 'Please supply any additional information to support your application.';
        awt.Similar_course_in_other_country__c = 'Yes';
        awt.Why_UK__c = null;
        awt.Applied_to_Other_Universities__c = 'Yes';
        awt.Other_University_Details__c = null;
        awt.Intend_to_apply_for_Student_Via__c = 'No';
        awt.Type_of_Visa_intend_to_apply__c = null;
        awt.Are_you_currently_in_Uk_with_a_visa__c = 'Yes';
        awt.Ever_studied_in_UK_before__c = 'Yes';
        insert(awt);
        insertData();
        string WIZ_ID1 = awt.id;
        
        //Covers some exceptional or initial situations.
        pageRef1 = new PageReference('/apex/application_references_personal?wiz_id='+WIZ_ID1+'&auth_id='+auth_id);
        Test.setCurrentPage(pageRef1); 
        //create controller object instance to test against
        con = new ApexPages.StandardController(new Application_wizard__c());               
        Ctlr = new application_wiz_controller(con);
        Ctlr.listprogramme= wco.Programme__c;
        Ctlr.listlocation = wco.Campus__c;
        Ctlr.listmodes = wco.Mode__c;
        
        Ctlr.nextPage= 'application_employment_history';
        Ctlr.edlist[0].predicted_actual__c = 'Actual';
        Ctlr.edlisth[0].predicted_actual__c = 'Actual';
        Ctlr.edlisto[0].predicted_actual__c = 'Actual';
        Ctlr.saveNextEdu();
        Ctlr.isDomestic = false;
        Ctlr.Reference[0].Reference_Position__c = 'dsd';
        Ctlr.saveNextReference();
        
        Ctlr.employment[0].Job_Title__c='TESTMETHOD';
        Ctlr.saveEmpNext();
        Ctlr.employment[0].from__c=system.today();
        Ctlr.employment[0].to__c = system.today().addDays(-1);
        
        Ctlr.nextPage= 'application_other_details';
         Ctlr.saveEmpNext();
        Ctlr.visalist[0].Visa_Expiry_Date__c = system.today().addDays(1);
        
        Ctlr.saveEmpNext();        
        
        test.stopTest();
   }
   
 /*  static testMethod void application_wiz_controllerTest6(){
        PageReference pageRef1 = new PageReference('/apex/application_create_account');
        Test.setCurrentPage(pageRef1); 
        //create controller object instance to test against
        ApexPages.StandardController con = new ApexPages.StandardController(new Application_wizard__c());               
        application_wiz_controller Ctlr = new application_wiz_controller(con);
        
        Application_wizard__c awt = new Application_wizard__c(first_name__c='TESTMETHOD',password__c='trial1234', last_name__c='TESTMETHOD',email__c='tester@test.edu');
        awt.Title__c = 'Mr';
        //awt.Country_of_birth__c = cl.id;
        //awt.Country_of_Domicile_Permanent_Residency__c = cl.id;
        //awt.Nationality__c = cl.id;     
        awt.Security_Token__c = Ctlr.generateSecurityToken();
        awt.Security_Expiry_Date__c = system.Now().addDays(1);
        awt.Passport_date_expected__c = system.today().addDays(-1);
        awt.Visa_date_expected__c = system.today().addDays(-1);
        awt.Academic_date_expected__c = system.today().addDays(-1);
        awt.Visa_Refusal_date_expected__c = system.today().addDays(-1);
        awt.Attendance_date_expected__c = system.today().addDays(-1);
        awt.ACCA_date_expected__c = system.today().addDays(-1);
        awt.English_date_expected__c = system.today().addDays(-1);
        awt.References_date_expected__c = system.today().addDays(-1);
        string auth_id = awt.Security_Token__c;
        awt.Payment_Option__c = 'Company/Law Firm';
        awt.Are_you_currently_studying_in_UK__c = 'Yes';
        awt.Any_close_relatives_in_UK__c = 'Yes';
        awt.Planning_to_stay_with_relatives_in_uk__c = 'Yes';
        awt.staying_in_UK_after_course__c = 'Yes';
        awt.Any_criminal_convictions__c = 'Yes';
        awt.Any_Learning_Requirements__c = 'Yes';
        awt.EEA_citizen__c = 'No';
        awt.F1__c = true;awt.F2__c = true;awt.F3__c = true;awt.F4__c = true;awt.F5__c = true;
        awt.F6__c = true;awt.F7__c = true;awt.F8__c = true;awt.F9__c = true;
        awt.P1__c = true;awt.P2__c = true;awt.P3__c = true;awt.P4__c = true;
        awt.P5__c = true;awt.P6__c = true;awt.P7__c = true;
        awt.personal_statement__c = 'Please supply any additional information to support your application. This may include reasons for wanting to study your chosen course or why you feel suited to the programme for which you are applying.  Minimum 250 words.Please supply any additional information to support your application. This may include reasons for wanting to study your chosen course or why you feel suited to the programme for which you are applying.  Minimum 250 words.Please supply any additional information to support your application. This may include reasons for wanting to study your chosen course or why you feel suited to the programme for which you are applying.  Minimum 250 words.Please supply any additional information to support your application. This may include reasons for wanting to study your chosen course or why you feel suited to the programme for which you are applying.  Minimum 250 words.Please supply any additional information to support your application. This may include reasons for wanting to study your chosen course or why you feel suited to the programme for which you are applying.  Minimum 250 words.Please supply any additional information to support your application. This may include reasons for wanting to study your chosen course or why you feel suited to the programme for which you are applying.  Minimum 250 words.Please supply any additional information to support your application. This may include reasons for wanting to study your chosen course or why you feel suited to the programme for which you are applying.  Minimum 250 words.';
        awt.Are_you_currently_in_Uk_with_a_visa__c = 'Yes';
        awt.Ever_studied_in_UK_before__c = 'Yes';
        awt.kin_address_line1__c = 'scg';
        awt.kin_city__c = 'scha';
        //awt.kin_country__c = cl.id;
        awt.kin_postcode__c = '23423';
        insert(awt);
        insertData();
 
        string WIZ_ID1 = awt.id;
        /* Attachments test code.
        
        test.startTest();
        pageRef1 = new PageReference('/apex/application_attachments?wiz_id='+WIZ_ID1+'&auth_id='+auth_id);
        Test.setCurrentPage(pageRef1); 
        con = new ApexPages.StandardController(new Application_wizard__c());               
        Ctlr = new application_wiz_controller(con);
        //create controller object instance to test against
        Attachment lstAttach = [Select a.ParentId, a.OwnerId, a.Name, a.IsPrivate, a.IsDeleted, a.Id, 
                                         a.Description, a.ContentType, a.BodyLength, a.Body 
                                From Attachment a limit 1];
        Ctlr.PassportBody = lstAttach.Body;
        Ctlr.PassportName = lstAttach.Name;
        Ctlr.PassportUploadFile();
        
        Ctlr.AcademicBody = lstAttach.Body;
        Ctlr.AcademicName = lstAttach.Name;
        Ctlr.AcademicUploadFile();
        
        Ctlr.EnglishBody = lstAttach.Body;
        Ctlr.EnglishName = lstAttach.Name;
        Ctlr.EnglishUploadFile();
        
        Ctlr.ReferencesBody = lstAttach.Body;
        Ctlr.ReferencesName = lstAttach.Name;
        Ctlr.ReferencesUploadFile();
        
        Ctlr.ACCABody = lstAttach.Body;
        Ctlr.ACCAName = lstAttach.Name;
        Ctlr.ACCAUploadFile();
        
        Ctlr.VisaBody = lstAttach.Body;
        Ctlr.VisaName = lstAttach.Name;
        Ctlr.VisaUploadFile();
        
        Ctlr.AttendanceBody = lstAttach.Body;
        Ctlr.AttendanceName = lstAttach.Name;
        Ctlr.AttendanceUploadFile();
        
        Ctlr.VisaRefusalBody = lstAttach.Body;
        Ctlr.VisaRefusalName = lstAttach.Name;
        Ctlr.VisaRefusalUploadFile();
        
        Ctlr.Additional_Doc_1_Body = lstAttach.Body;
        Ctlr.Additional_Doc_1_Name = lstAttach.Name;
        Ctlr.AdditionalDoc1UploadFile();
        Ctlr.Additional_Doc_2_Body = lstAttach.Body;
        Ctlr.Additional_Doc_2_Name = lstAttach.Name;
        Ctlr.AdditionalDoc2UploadFile();
        Ctlr.Additional_Doc_3_Body = lstAttach.Body;
        Ctlr.Additional_Doc_3_Name = lstAttach.Name;
        //Ctlr.AdditionalDoc3UploadFile();
        
        Ctlr.UKVisaHistoryBody = lstAttach.Body;
        Ctlr.UKVisaHistoryName = lstAttach.Name;
        Ctlr.UKVisaHistoryUploadFile();
             
        
        Ctlr.nextPage= 'application_submit';
        Ctlr.saveEmpNext();
        Ctlr.aw.ACCA_card_uploaded__c = false;
        ctlr.aw.Passport_Copy_Uploaded__c  = false;
        ctlr.aw.Visa_copy_uploaded__c  = false;
        ctlr.aw.Academic_uploaded__c  = false;
        ctlr.aw.English_Test_uploaded__c  = false;
        ctlr.aw.References_uploaded__c  = false;
        ctlr.aw.Attendance_record_uploaded__c  = false;
        ctlr.aw.Visa_refusal_copy_uploaded__c  = false;
        ctlr.aw.UK_Visa_History_uploaded__c = false;
       
        Ctlr.VisaFileSize = 6000000;
        Ctlr.PassportFileSize = 6000000;
        Ctlr.ACCAFileSize = 6000000;
        Ctlr.AcademicFileSize = 6000000;
        Ctlr.EnglishTestFileSize = 6000000;
        Ctlr.ReferenceFileSize = 6000000;
        Ctlr.AttendanceFileSize = 6000000;
        Ctlr.VisaRefusalFileSize = 6000000;
        Ctlr.Add_Doc1_FileSize = 6000000;
        Ctlr.Add_Doc2_FileSize = 6000000;
        Ctlr.Add_Doc3_FileSize = 6000000;
        Ctlr.UKVisaHistoryFileSize = 6000000;
        Ctlr.saveEmpNext();
        
        
        test.stopTest();
    
   }*/
   public static country_list__c cl = new country_list__c();
   public static Application_wizard__c awt= new Application_wizard__c(); 
    public static void insertData() {
        cl = [SELECT Id, Name, enabled__c, region__c, economic_grouping__c FROM country_list__c limit 1];
        awt = new Application_wizard__c(first_name__c='TESTMETHOD', last_name__c='TESTMETHOD',email__c='tester@test.edu');
        awt.Title__c = 'Mr';
        awt.Gender__c = 'Male';
        awt.Ethnicity__c = '10 White';
        awt.Date_of_Birth__c = Date.valueOf('2000-10-30');
        awt.Address_Line_1__c = 'Bone';
        //aw.Address_Line_2__c = ''
        //aw.Address_Line_3__c
        awt.City__c = 'Woodfield';
        awt.Provence_State__c = 'IL';
        awt.country__c = cl.id;
        awt.Postal_Code__c = '45342';
        awt.Preferred_Telephone__c = 'Work';
        awt.telephone__c = '987587569987';
        
        awt.EEA_citizen__c = 'No';
        awt.Country_of_birth__c = cl.id;
        awt.Nationality__c = cl.id;
        awt.Country_of_Domicile_Permanent_Residency__c = cl.id;
        awt.Date_of_arrival_in_the_UK__c = Date.valueOf('2012-10-30');
        awt.Date_of_Residency__c = Date.valueOf('2012-10-30');
        awt.Conditions_of_residency__c = 'dlkfjsd';
        awt.Do_you_have_indefinite_leave__c = 'No';
        insert(awt);
    }
}