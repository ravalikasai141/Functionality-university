public class application_wiz_controller {
/*
Application wizard controller
controls the wizard pages for a new student application

Chris Roberts

V0.1    Aug 8, 2011
*/
public String dummy {set; get;}
public Boolean domestic {set; get;}
public Boolean isDomestic {get;set;}
public Boolean isNewUser=false;
//public Boolean getisDomestic()
//{
//return isDomestic;
//}
public Boolean displayACCAPanel {get; set;}
public String email2 {get; set;}
public String password2 {get; set;}
public Map<String, String> checkListMap {get; set;}
public String personDetails {get; set;}
public String courseDetails {get; set;}
public String languagechecklist {get; set;}
public String nationalitychecklist {get; set;}


//payment options
public List<SelectOption> getPaymentOptions() {
    List<SelectOption> options = new List<SelectOption>(); 
    options.add(new SelectOption('I will','I will')); 
    options.add(new SelectOption('Parent/Guardian','Parent/Guardian')); 
    options.add(new SelectOption('Company/Law Firm','Company/Law Firm')); 
    options.add(new SelectOption('Government/International Agency','Government/International Agency')); 
    
    return options; 
}       
/*
public Boolean getshowPayoptionTable() {
    if(aw != null && aw.Payment_Option__c != null) {
    
        if(aw.Payment_Option__c == 'Company/Law Firm' || aw.Payment_Option__c == 'Government/International Agency') {
            return true;
        }
    }        
   return false;
}
*/

// constructor
public application_wiz_controller(ApexPages.StandardController controller) {
    //displayACCAPanel = False;     new code. on 9/9
    dummy ='dummyVal';        
    domestic = True;
    System.debug('****Constructor***'+isDomestic);
    //  isDomestic = True;
        
    personDetails = 'No';
    courseDetails = 'No';
    languagechecklist = 'No';
    nationalitychecklist = 'No';        

    countrylist = [SELECT Id, Name, sort_order__c, economic_grouping__c FROM country_list__c WHERE enabled__c = true ORDER BY sort_order__c ASC];
    
    //stateList = [Select s.Name, s.IsDeleted, s.Id, s.ISO_Code__c From State_Province__c s where s.IsDeleted = false];
    stateList = [Select s.Name, s.IsDeleted, s.Id, s.ISO_Code__c From State_Province__c s where s.IsDeleted = false AND s.Country__r.name = 'United Kingdom'];
    
    nationalitylist  = [SELECT Id, Name, country_code_2__c,NATIONALITY__C, sort_order__c, enabled__c, region__c, 
                                                    economic_grouping__c FROM country_list__c WHERE enabled__c = true and NATIONALITY__C !=Null 
                                                    ORDER BY NATIONALITY__C];
   /* weblist = [SELECT Id, OwnerId, IsDeleted, Name, CreatedDate, CreatedById, LastModifiedDate, LastModifiedById, 
                                                    SystemModstamp, Programme__c, Mode__c, Campus__c, Intake_Month__c,start_date__c, 
                                                    Redirect_URL__c, Redirect_Enabled__c, Active__c FROM Web_Course_Offering__c];
                                                    */
    list <Web_Course_Offering__c> wc  =    [SELECT Id, Campus__c, start_date__c, start_year__c FROM Web_Course_Offering__c 
                                                        WHERE CALENDAR_YEAR(start_date__c) >= :date.today().year() AND 
                                                        Active__c = True ORDER BY start_year__c];
                
    list <string> campusid =new list <string>();

    ymap = new  map <Integer, Integer>();
    /*for(Web_Course_Offering__c wo:wc) {
        campusid.add(wo.Campus__c);
        if(wo.start_date__c >= (date.today())) {
                    ymap.put(Integer.valueOf(wo.start_year__c),Integer.valueOf(wo.start_year__c));
        }
    }*/
    // get the wizard id passed along
    if(wiz_id == Null ) {// 
        if(ApexPages.currentPage().getParameters().get('wiz_id')!= null && ApexPages.currentPage().getParameters().get('auth_id')!= null ) {
            wiz_id = ApexPages.currentPage().getParameters().get('wiz_id');
            auth_id = ApexPages.currentPage().getParameters().get('auth_id');
            aw =  [SELECT Id, OwnerId,Mode__c, Password__c, Minimum_1_Year_Post_Education__c, Eng_Exam_Date__c, 
                          Preferred_Telephone__c, Ethnicity__c, SFDC_Select_Disability_Status_Code__c, Marketing_Opt_Out__c,
                          Modules__c, App_Wiz_Student_Type__c, Submitted__c,
                          IsDeleted, Name, Location__c, course_year__c,         
                          CreatedDate, CreatedById,LastModifiedDate, LastModifiedById, Web_Course_Offering__c,SystemModstamp,
                          is_english_your_first_language__c,EEA_citizen__c, Are_yu_being_sponsored_for_the_programme__c, 
                          Title__c, First_name__c, last_Name__c,Nationality__c,Gender__c, Date_of_Birth__c, 
                          Email__c, telephone__c, Programme__c,month__c, 
                          extract_date__c,ready_for_extract__c,
                          Address__c, City__c, Country__c, Postal_Code__c,State_Province__c,//added lookup state 
                          Country_of_birth__c, Country_of_Domicile_Permanent_Residency__c, Date_of_Residency__c, 
                          Conditions_of_residency__c, Date_of_arrival_in_the_UK__c, 
                          Exam_type__c, Exam_Result__c, 
                          Name_of_organisation__c, Authorising_name__c, 
                          Purchase_order_Number_where_necessary__c, Street_Address__c, 
                          sponsorCity__c, sponsorCountry__c, sponsorPostal_Code__c, sponsorTelephone__c, sponsorEmail__c,
                          Passport_Copy_Uploaded__c, Visa_copy_uploaded__c, Academic_uploaded__c, English_Test_uploaded__c, 
                          References_uploaded__c, ACCA_card_uploaded__c, Attendance_record_uploaded__c, Visa_refusal_copy_uploaded__c, 
                          personal_statement__c,Address_Line_1__c, Address_Line_2__c ,Address_Line_3__c , 
                          Do_you_have_indefinite_leave__c,
                          Names_as_per_passport__c, eng_exam_type__c, eng_exam_type_other__c, Correct_Information__c, 
                          eng_exam_result__c, Academic_date_expected__c, ACCA_date_expected__c, English_date_expected__c, Visa_Refusal_date_expected__c, 
                          Passport_date_expected__c, References_date_expected__c, Visa_date_expected__c, Attendance_date_expected__c, 
                          Language_Section_Complete__c,Nationality_section_complete__c,Personal_Details_Complete__c,Course_Details_Complete__c ,
                          Username__c, sms_mrkting__c, post_mrkting__c, telephone_mrkting__c, email_mrkgting__c, Payment_Option__c,
                          Annual_Income__c, number_of_family_members__c, father_occupation__c, mother_occupation__c, monthly_expense_in_UK__c,cash__c,          
                          Similar_course_in_other_country__c, why_UK__c, Applied_to_Other_Universities__c, Other_University_Details__c, Hours_per_week__c,
                          Are_you_currently_in_Uk_with_a_visa__c,Current_Visa_Type__c,Other_Visa_Type__c,Are_you_currently_studying_in_UK__c,Current_course_in_UK__c,
                          Intend_to_apply_for_Student_Via__c,Type_of_Visa_intend_to_apply__c,ever_studied_in_UK_before__c,Most_recent_course_studied_in_UK__c,
                          Applied_fro_Student_Visa_before__c, Have_you_been_refused__c, Passport_Number__c,expecting_to_work_part_time__c, how_many_hours_part_time__c,
                          bringing_dependents__c, Any_close_relatives_in_UK__c, relatives_contact_details_in_UK__C, Planning_to_stay_with_relatives_in_uk__c, duration_of_stay_with_relatives__c,
                          staying_in_UK_after_course__c, future_job__c, Any_criminal_convictions__c, Criminal_conviction_details__c, Any_Learning_Requirements__c, Learning_Requirement_Details__c,
                          kin_name__c, kin_address_line1__c, kin_address_line2__c,kin_address_line3__c, kin_city__c, kin_State_Province__c, //kin state lookup field
                          kin_country__c, kin_postcode__c, kin_contact_telephone__c, kin_email__c,
                          How_did_you_hear_about_us__c, Other_Source__c, Agent_Name__c, why_did_you_choose_to_study_with_us__c, Other_Details__c, Personal_statement_complete__c, Course_Section_Complete__c,
                          Immigration_History_Complete__c, General_Information_Complete__c, Other_Information_Complete__c, next_of_kin_section_complete__c,
                          Visa_Refusal_Copy_File_Name__c, Visa_File_Name__c, References_File_Name__c, Passport_File_Name__c, English_Lang_File_Name__c, Attendence_Record_file_Name__c, 
                          Academic_File_Name__c, ACCA_File_Name__c, Additional_Doc_1_File_Name__c, Additional_Doc_2_File_Name__c, Additional_Doc_3_File_Name__c,
                          Additional_Doc_1_Description__c, Additional_Doc_2_Description__c, Additional_Doc_3_Description__c,                                
                          F1__c,F2__c,F3__c,F4__c,F5__c,F6__c,F7__c,F8__c,F9__c,P1__c,P2__c,P3__c,P4__c,P5__c,P6__c,P7__c,
                          Security_Token__c, Security_Expiry_Date__c, UK_Visa_History_File_Name__c, UK_Visa_History_date_expected__c, UK_Visa_History_uploaded__c, Domicile__c
                     FROM Application_wizard__c 
                    WHERE id=:wiz_id and Internal_Tracking_Status__c = 'Active']; 
          
                  /*  old code for Domestic vs. International
                  if(aw.Nationality__c != null && aw.Country_of_Domicile_Permanent_Residency__c != null) {
                      System.debug('***Checking Id***'+aw.Nationality__c);
                      System.debug('***Checking Id***'+aw.Country_of_Domicile_Permanent_Residency__c);
                      String idNationality = aw.Nationality__c;
                      String idPermanentResidency = aw.Country_of_Domicile_Permanent_Residency__c;
                      if(idNationality != null)
                        idNationality =idNationality.trim();
                      if(idPermanentResidency != null)
                        idPermanentResidency =idPermanentResidency.trim();
                      system.debug('****checking2***'+ idNationality);
                      System.debug('****checking3***'+ idPermanentResidency);
                      //if I enter any countries in the Country of Nationality and Country of Residence other than United States, 
                      //then the Domestic application would appear for me to fill out
                      if(!idNationality.contains('a0Q20000005LNNMEA4') && !idPermanentResidency.contains('a0Q20000005LNNMEA4') )
                          isDomestic = true;
                      else
                          isDomestic = false;
                      System.debug('***checking4***'+isDomestic );  
                  }
                  */
                system.debug(ApexPages.currentPage() + 'ApexPages.currentPage()');
       /*       if(aw.Submitted__c){
                    
                }*/
                //Domestic vs. International logic: 'isDomestic' drives how the entire application appears
                if(aw.EEA_citizen__c == 'Yes')
                        isDomestic = true;    
                else if(aw.Do_you_have_indefinite_leave__c == 'Yes')
                    isDomestic = true;                      
                else 
                        isDomestic = false;
            
                if(aw.Date_of_Birth__c == null)
                    isNewUser = true;
                else
                    isNewUser = false;
                   
                //default location instance
                  listmodes=aw.mode__c;    
                  listlocation=aw.location__c;
                  listprogramme=aw.programme__c; 
                  listmonths=aw.month__c;
                  progYear= string.valueOf(aw.course_year__c);  // year of selected course in wiz
                  
                  checkdummy1();            //new code. on 9/9
                  
                  map<string,string> mlist = new map<string,string>();
                  mlist.put('1','January');
                  mlist.put('2','February');
                  mlist.put('3','March');
                  mlist.put('4','April');
                  mlist.put('5','May');
                  mlist.put('6','June');
                  mlist.put('7','July');
                  mlist.put('8','August');
                  mlist.put('9','September');
                  mlist.put('10','October');
                  mlist.put('11','November');
                  mlist.put('12','December');
                  monthname=  mlist.get(aw.month__c);
              
          } else {
               if([SELECT count() FROM Application_wizard__c WHERE  last_Name__c =:lastname AND Email__c=:email limit 1] == 1) {
                   Application_wizard__c  aww = [SELECT Id FROM Application_wizard__c WHERE  last_Name__c =:lastname AND Email__c=:email limit 1];
                   wiz_id = aww.id;
                   //errorMessage('Constructor if 2');
               } else {
                   wiz_id=null;
                   //errorMessage('Constructor if 3'+ApexPages.currentPage().getUrl() );
                   //errorMessage('Constructor if 3 nxt'+ApexPages.currentPage().getParameters().get('nextPageURL'));               
                   //errorMessage('Constructor if 3 prv'+ApexPages.currentPage().getParameters().get('nextPageURL'));               
               }
          } 
      }
      else{
        //errorMessage('Constructor if 1');
      }      
      
      // create a hs ed list if required 
      if([SELECT count() FROM application_wizard_eduction__c WHERE wizard__c= :wiz_id AND type__c = 'hs' limit 1] == 1 ){
          edlist =[select Id, predicted_actual__c,Country_of_Study__c, subject__c, Subject_Lookup__c, wizard__c, Grade__c, year_of_completion__c, Qualification_Date__c, full_time__c, institution__c, Institution_Lookup__c, title_of_award__c, iteration__c, type__c, Type_Lookup__c, Qualification__c FROM application_wizard_eduction__c WHERE wizard__c=:wiz_id AND type__c = 'hs'];
      
      } else {
          edlist = new list <application_wizard_eduction__c>();
          for (Integer i =  1; i <=1; i++) {
              edlist.add(new application_wizard_eduction__c(iteration__c=i,wizard__c=wiz_id, type__c = 'hs' ));
          }
      } 
      
      // create a he ed list if required 
      if([SELECT count() FROM application_wizard_eduction__c WHERE wizard__c= :wiz_id AND type__c = 'he' limit 1] == 1 ){
          edlisth =[select Id, Mode_of_Study__c, Country_of_Study__c,predicted_actual__c, subject__c, Subject_Lookup__c, wizard__c, Grade__c, year_of_completion__c, Qualification_Date__c, full_time__c, institution__c, Institution_Lookup__c, title_of_award__c, iteration__c, type__c, Type_Lookup__c FROM application_wizard_eduction__c WHERE wizard__c=:wiz_id AND type__c = 'he'];
      
      } else {
          edlisth = new list <application_wizard_eduction__c>();
          for (Integer i =  1; i <=1; i++) {
              edlisth.add(new application_wizard_eduction__c(iteration__c=i,wizard__c=wiz_id, type__c = 'he' ));
          }
      }
      
      // create an other qualification ed list if required 
      if([SELECT count() FROM application_wizard_eduction__c WHERE wizard__c= :wiz_id AND type__c = 'oq' limit 1] == 1 ){
          edlisto =[select Id, predicted_actual__c,Country_of_Study__c, subject__c, Subject_Lookup__c, wizard__c, Grade__c, year_of_completion__c, Qualification_Date__c, full_time__c, institution__c, Institution_Lookup__c, title_of_award__c, iteration__c, type__c, Type_Lookup__c, Other_Qualification__c FROM application_wizard_eduction__c WHERE wizard__c=:wiz_id AND type__c = 'oq'];
      
      } else {
          edlisto = new list <application_wizard_eduction__c>();
          for (Integer i =  1; i <=1; i++) {
              edlisto.add(new application_wizard_eduction__c(iteration__c=i,wizard__c=wiz_id, type__c = 'oq' ));
          }
      }             
      
      //create an ACCA iterable list
      if([SELECT count() FROM application_wizard_eduction__c WHERE wizard__c= :wiz_id limit 1] == 1 ){
          //accaEDList =[select Id, subject__c, wizard__c, full_time__c, iteration__c FROM application_wizard_eduction__c WHERE wizard__c=:wiz_id];
          accaEDList = new list <application_wizard_eduction__c>();
          for (Integer i =  1; i <=16; i++) {
              accaEDList.add(new application_wizard_eduction__c(iteration__c=i,wizard__c=wiz_id, type__c = 'he', full_time__c=false));
          }               
      } else {
          accaEDList = new list <application_wizard_eduction__c>();
          for (Integer i =  1; i <=16; i++) {
              accaEDList.add(new application_wizard_eduction__c(iteration__c=i,wizard__c=wiz_id, type__c = 'he', full_time__c=false));
          }          
      }       
      
      // create a employment list if required
      if([SELECT count() FROM Application_wizard_employment__c WHERE Application_wiz__c =:wiz_id  limit 1] == 1)  {
          employment = [SELECT Id, Name_of_employer__c, Job_Title__c, From__c, To__c, Application_wiz__c, description__c, iteration__c FROM Application_wizard_employment__c WHERE Application_wiz__c =:wiz_id];
      } else {
          employment = new list <Application_wizard_employment__c>();
          for (Integer i = 1; i <=1; i++) {
              employment.add(new Application_wizard_employment__c(iteration__c=i,application_wiz__c=wiz_id));
          } 
      } 
    //select Id, Reference_name__c, Reference_Position__c, reference_street__c, reference_city__c, reference_postal__c, reference_country__c, reference_telephone__c, reference_email__c, reference_date__c, Application_wiz__c, iteration__c from Application_wizard_reference__c  
     //reference 
            // create a employment list if required
      if([SELECT count() FROM Application_wizard_reference__c WHERE Application_wiz__c =:wiz_id  limit 1] == 1)  {
          reference = [SELECT Id,Address_Line1__c, Address_Line2__c, Address_Line3__c,Reference_State_Province__c, Reference_name__c, Reference_Position__c, reference_street__c, reference_city__c, reference_postal__c, reference_country__c, reference_telephone__c, reference_email__c, reference_date__c, Application_wiz__c, iteration__c FROM  Application_wizard_reference__c WHERE Application_wiz__c =:wiz_id];
      } else {
          reference = new list <Application_wizard_reference__c>();
          for (Integer i = 1; i <=1; i++) {
              reference.add(new Application_wizard_reference__c(iteration__c=''+i+'',application_wiz__c=wiz_id));
          } 
      }  
      
      //create a visa list
      if([SELECT count() FROM Application_Wizard_Visa__c WHERE Application_wizard__c =:wiz_id  limit 1] == 1)  {
          visalist = [SELECT Id, Application_wizard__c, iteration__c, Actual_Qualification_Institution__c, Completed_Course_at_Visa_Institution__c,
                      Level_of_Studies__c, Other_Visa_Type__c, Visa_Expiry_Date__c, Visa_Institution__c, Visa_Issue_Date__c, Visa_Qualification__c,
                      Visa_Type__c FROM Application_Wizard_Visa__c WHERE Application_wizard__c =:wiz_id];
      } else {
          visalist = new list <Application_Wizard_Visa__c>();
          for (Integer i = 1; i <=1; i++) {
              visalist.add(new Application_Wizard_Visa__c(iteration__c=i, Application_wizard__c=wiz_id));
          } 
      } 
                
    }  
    
    public pageReference Redirect_UnAuthorized_Access() {
        if(wiz_id == Null ) {// 
                if(ApexPages.currentPage().getParameters().get('wiz_id')!= null && ApexPages.currentPage().getParameters().get('auth_id')!= null ) {
                    string wiz_id1 = ApexPages.currentPage().getParameters().get('wiz_id');
                        auth_id = ApexPages.currentPage().getParameters().get('auth_id');
                aw =  [SELECT Submitted__c,Security_Token__c, Security_Expiry_Date__c
                         FROM Application_wizard__c 
                        WHERE id=:wiz_id1 and Internal_Tracking_Status__c = 'Active'];
                }
        }
        if(aw!=null){ 
            if(aw.Submitted__c){
                PageReference pr = new PageReference('/apex/application_login');
                pr.setRedirect(true);              
                return  pr; 
            }
            else if(aw.Security_Token__c != auth_id || aw.Security_Expiry_Date__c < system.now()){
                //.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Surname/Family name is Required'));
                PageReference pr = new PageReference('/apex/application_login');
                pr.setRedirect(true);              
                //pr.
                return  pr;         
            }
            else{
                return null;
            }
        }
        else{
            return null;
        }          
     }
   
    public void PassportUploadFile() {      
        Attachment PassportAttachment  = new Attachment();  
        PassportAttachment.Body = PassportBody;  
        PassportAttachment.Name = PassportName;
        system.debug(PassportFilesize + 'passportfile');
        PassportAttachment.Description = 'Passport Documents';          
        PassportAttachment.ParentId = aw.Id;  
        system.debug(aw.Id + 'aw.id111');
        insert PassportAttachment;   
    }
    
    public void AcademicUploadFile() {
        Attachment AcademicAttachment  = new Attachment();  
        AcademicAttachment.Body = AcademicBody;  
        AcademicAttachment.Name = AcademicName;
        AcademicAttachment.Description = 'Academic Documents';  
        AcademicAttachment.ParentId = aw.Id;  
        insert AcademicAttachment;
    }
    
    public void EnglishUploadFile() {
        Attachment EnglishAttachment  = new Attachment();  
        EnglishAttachment.Body = EnglishBody;  
        EnglishAttachment.Name = EnglishName;
        system.debug(EnglishTestFilesize + 'passportfile');
        EnglishAttachment.Description = 'English Exam Document';  
        EnglishAttachment.ParentId = aw.Id;  
        insert EnglishAttachment;
    }
    
    public void ReferencesUploadFile() {
        Attachment ReferencesAttachment  = new Attachment();  
        ReferencesAttachment.Body = ReferencesBody;  
        ReferencesAttachment.Name = ReferencesName;
        ReferencesAttachment.Description = 'References';  
        ReferencesAttachment.ParentId = aw.Id;  
        insert ReferencesAttachment;
    }
    
    public void ACCAUploadFile() {
        Attachment ACCAAttachment  = new Attachment();  
        ACCAAttachment.Body = ACCABody;  
        ACCAAttachment.Name = ACCAName;  
        ACCAAttachment.Description = 'ACCA Document';
        ACCAAttachment.ParentId = aw.Id;  
        insert ACCAAttachment;
    }
    
    public void VisaUploadFile() {
        Attachment VisaAttachment  = new Attachment();  
        VisaAttachment.Body = VisaBody;  
        VisaAttachment.Name = VisaName;  
        VisaAttachment.Description = 'Visa Document';
        VisaAttachment.ParentId = aw.Id;  
        insert VisaAttachment;
    }
    
    public void AttendanceUploadFile() {
        Attachment AttendanceAttachment  = new Attachment();  
        AttendanceAttachment.Body = AttendanceBody;  
        AttendanceAttachment.Name = AttendanceName; 
        AttendanceAttachment.Description = 'Attendance document'; 
        AttendanceAttachment.ParentId = aw.Id;  
        insert AttendanceAttachment;
    }
    
    public void VisaRefusalUploadFile() {
        Attachment VisaRefusalAttachment  = new Attachment();  
        VisaRefusalAttachment.Body = VisaRefusalBody;  
        VisaRefusalAttachment.Name = VisaRefusalName; 
        VisaRefusalAttachment.Description = 'Visa Refusal Document'; 
        VisaRefusalAttachment.ParentId = aw.Id;  
        insert VisaRefusalAttachment;
    } 
    
    public void UKVisaHistoryUploadFile() {
        Attachment UKVisaHistoryAttachment  = new Attachment();  
        UKVisaHistoryAttachment.Body = UKVisaHistoryBody;  
        UKVisaHistoryAttachment.Name = UKVisaHistoryName; 
        UKVisaHistoryAttachment.Description = 'UK Visa History Document'; 
        UKVisaHistoryAttachment.ParentId = aw.Id;  
        insert UKVisaHistoryAttachment;
    } 
     
    public void AdditionalDoc1UploadFile() {
        Attachment AdditionalDoc1Attachment  = new Attachment();  
        AdditionalDoc1Attachment.Body = Additional_Doc_1_Body;  
        AdditionalDoc1Attachment.Name = Additional_Doc_1_Name;  
        AdditionalDoc1Attachment.Description = aw.Additional_Doc_1_Description__c;
        AdditionalDoc1Attachment.ParentId = aw.Id;  
        insert AdditionalDoc1Attachment;
    }
    
    public void AdditionalDoc2UploadFile() {
        Attachment AdditionalDoc2Attachment  = new Attachment();  
        AdditionalDoc2Attachment.Body = Additional_Doc_2_Body;  
        AdditionalDoc2Attachment.Name = Additional_Doc_2_Name;  
        AdditionalDoc2Attachment.Description = aw.Additional_Doc_2_Description__c;
        AdditionalDoc2Attachment.ParentId = aw.Id;  
        insert AdditionalDoc2Attachment;
    }
    
    public void AdditionalDoc3UploadFile() {
        Attachment AdditionalDoc3Attachment  = new Attachment();  
        AdditionalDoc3Attachment.Body = Additional_Doc_3_Body;  
        AdditionalDoc3Attachment.Name = Additional_Doc_3_Name;  
        AdditionalDoc3Attachment.Description = aw.Additional_Doc_3_Description__c;
        AdditionalDoc3Attachment.ParentId = aw.Id;  
        insert AdditionalDoc3Attachment;
    }   
    
      //getters-setters 
      //navigation vars 
      public string wiz_id{get; set;} 
      public string auth_id{get; set;} 
      public string nextPage{get; set;}  
      public string prevPage{get; set;}    
      public string  curPage{get; set;} 
      
      public string PassportName { get; set; }
      public string VisaName { get; set; }
      public string AcademicName { get; set; }
      public string EnglishName { get; set; }
      public string ReferencesName { get; set; }
      public string ACCAName { get; set; } 
      public string AttendanceName { get; set; }
      public string VisaRefusalName { get; set; }
      public string UKVisaHistoryName { get; set; }
      public string Additional_Doc_1_Name { get; set; }
      public string Additional_Doc_2_Name { get; set; }
      public string Additional_Doc_3_Name { get; set; }
            
      public blob PassportBody { get; set; }
      public blob VisaBody { get; set; }
      public blob AcademicBody { get; set; }
      public blob EnglishBody { get; set; }
      public blob ReferencesBody { get; set; }
      public blob ACCABody { get; set; }
      public blob AttendanceBody { get; set; }
      public blob VisaRefusalBody { get; set; }
      public blob UKVisaHistoryBody { get; set; }
      public blob Additional_Doc_1_Body { get; set; }
      public blob Additional_Doc_2_Body { get; set; }
      public blob Additional_Doc_3_Body { get; set; }  
      
      public decimal PassportFileSize { get; set; }
      public decimal VisaFileSize { get; set; }
      public decimal AcademicFileSize { get; set; }
      public decimal EnglishTestFileSize { get; set; }
      public decimal ReferenceFileSize { get; set; }
      public decimal ACCAFileSize { get; set; }
      public decimal AttendanceFileSize { get; set; }
      public decimal VisaRefusalFileSize { get; set; }
      public decimal UKVisaHistoryFileSize { get; set; }
      public decimal Add_Doc1_FileSize { get; set; }
      public decimal Add_Doc2_FileSize { get; set; }
      public decimal Add_Doc3_FileSize { get; set; }      
            
      public list <Campus__c> locationlist {get; set;} 
      public list <Mode__c> modelist {get; set;} 
      public list <string> months {get; set;} 
      public list <Programme__c> programlist {get; set;} 
      public list <country_list__c> countrylist {get; set;}
      public list <State_Province__c> stateList {get; set;}      
      public list <country_list__c> nationalitylist {get; set;}  
      public list <Web_Course_Offering__c> weblist {get; set;} 
      public list <application_wizard_eduction__c> edlist { get; set;}
      public list <application_wizard_eduction__c> edlisth { get; set;}
      public list <application_wizard_eduction__c> edlisto { get; set;}
      public list <Application_wizard_employment__c> employment {get; set;}
      public list <Application_wizard_reference__c> reference {get; set;}
      public list <application_wizard_eduction__c> accaEDList{ get; set;}  
      public list <Application_Wizard_Visa__c> visalist{get; set;} 
      public string lastname{get; set;}  
      public string firstname{get; set;}
      public string email{get; set;}
      public string password{get; set;}  
      public date dateofbirth{get;set;}
      
      public Boolean mrkgting_opt_out{get; set;} 
      public Boolean email_mrkgting{get; set;} 
      public Boolean post_mrkgting{get; set;} 
      public Boolean telephone_mrkgting{get; set;} 
      public Boolean sms_mrkgting{get; set;} 
               
      public Application_wizard__c aw {get; set;}
      public string monthname{get; set;}
      public map <Integer, Integer> ymap  {get; set;}
      public String Username {get; set;}
      // action methods  
      
     //addnewrow() methods for Employment History page
     public void addnewRow_EmpHistory() {
        employment.add(new Application_wizard_employment__c(iteration__c=employment.size()+1,application_wiz__c=wiz_id));
         
         system.debug('********************************** ' + edlisth.size() + '************** '+ edlisth);
     }
      
     //addnewrow() methods for education page
     public void addnewRow_HE() {
         edlisth.add(new application_wizard_eduction__c(iteration__c=edlisth.size()+1,wizard__c=wiz_id, type__c = 'he' )); 
         system.debug('********************************** ' + edlisth.size() + '************** '+ edlisth);
     }
     
     public void addnewRow_HS() {
         edlist.add(new application_wizard_eduction__c(iteration__c=edlist.size()+1,wizard__c=wiz_id, type__c = 'hs' )); 
     }
     
     public void addnewRow_OQ() {
         edlisto.add(new application_wizard_eduction__c(iteration__c=edlisto.size()+1,wizard__c=wiz_id, type__c = 'oq' )); 
     }         
     
     public void addnewReferences() {
        integer r = reference.size()+1;
         reference.add(new Application_wizard_reference__c(iteration__c= '' + r,Application_wiz__c =wiz_id)); 
         system.debug('********************************** ' + reference.size() + '************** '+ reference);
     }
     
     public void addnewVisa() {
        visalist.add(new Application_Wizard_Visa__c(iteration__c = visalist.size()+1, Application_wizard__c = wiz_id)); 
     }
     
   /*  public void deleteReferences() {
        //integer r = reference.size()-1;            
         //reference.add(new Application_wizard_reference__c(iteration__c= '' + r,Application_wiz__c =wiz_id)); 
         //system.debug('********************************** ' + reference.size() + '************** '+ reference);
     }*/
  
  public pageReference cancel() { 
      PageReference pr = new PageReference('/apex/application_login');
      //if the cancel button is pressed redirect the browser to the off site page
      pr.setRedirect(true);              
      return  pr;    
  }
  
      //New code.
  public pageReference PopulateExistingInformation() {      
      PageReference pr = new PageReference('/apex/application_personal_details?wiz_id=' + wiz_id+'&auth_id='+auth_id);
      pr.setRedirect(true);              
      return  pr;         
  }
  
  public pageReference doPDF(){  
      PageReference pr = new PageReference('/apex/applicationwizPDF'+'?wiz_id='+wiz_id+'&auth_id='+auth_id);  
      pr.setRedirect(true);                  
      return  pr;   
  }
  
  public pageReference SendUserName() { 
        String requiredf = 'NO';
        PageReference pr;
       
       if(email == '' || email == null) {
               requiredf ='Yes';
               ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Email is Required'));
        }
        
        if(firstname == '' || firstname == null) {
               requiredf ='Yes';
               ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Forname is Required'));
        }
        
        if(lastname == '' || lastname == null) {
               requiredf ='Yes';
               ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Surname/Family name is Required'));
        }
        
        if(requiredf =='NO') {  
            if([SELECT count() FROM Application_wizard__c WHERE Email__c =: email AND First_name__c =:firstname AND last_Name__c =:lastname limit 1] == 1) {
              Application_wizard__c  aww = [SELECT Username__c, Email__c FROM Application_wizard__c WHERE  Email__c =: email AND First_name__c =:firstname AND last_Name__c =:lastname limit 1];
              
              String [] toAddresses = new String[] {aww.Email__c};
              
              Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
              email.setSubject('From BPP Direct application System for Username');
              email.setToAddresses(toAddresses);
              email.setPlainTextBody('Thanks for applying to BPP. Here is the Username:' + aww.Username__c +' . ' );
              email.setHtmlBody('<p>Thanks for applying to BPP. <br/>Here is the Username:' + aww.Username__c +' . </p>');
              if (!Test.isRunningTest()) {
                Messaging.SendEmailResult [] r = Messaging.sendEmail(new Messaging.SingleEmailMessage[] {email});
              }
              
              pr = new PageReference('/apex/application_login'); 
              pr.setRedirect(true); 
           }
           else {
                 ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Incorrect Details'));
                 requiredf = 'incorrectvalues';
                 pr = null;             
           }   
        }
        return pr;
  }  
  
  public pageReference ResetPassword() { 
        String requiredf = 'NO';
        PageReference pr;
       
       if(email == '' || email == null) {
               requiredf ='Yes';
               ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Email is Required'));
        }
        
        if(firstname == '' || firstname == null) {
               requiredf ='Yes';
               ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'First Name is Required'));
        }
        
        if(lastname == '' || lastname == null) {
               requiredf ='Yes';
               ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Last Name is Required'));
        }
        
        if(requiredf =='NO') {  
            if([SELECT count() FROM Application_wizard__c WHERE Email__c =: email AND First_name__c =:firstname AND last_Name__c =:lastname limit 1] == 1) {
              Application_wizard__c  aww = [SELECT id,Password__c, Email__c, First_name__c, Request_Password__c
                                             FROM Application_wizard__c WHERE  Email__c =: email AND First_name__c =:firstname AND last_Name__c =:lastname limit 1];
              
         /*     String [] toAddresses = new String[] {aww.Email__c};
              
              Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
              
              EmailTemplate emTem = [Select  e.Name,e.Id,e.DeveloperName, e.Description From EmailTemplate e 
                                                where e.DeveloperName='DA_Auto_Response_Template_Password_Request'];
     List<Contact> contList = [Select  c.Id 
                                      From Contact c 
                                      where c.lastname like 'kadlec' Limit 1 ];
            //if (contList.size() == 0)
              //  return;
          
            Contact cont = contList[0];  
            email.setEmailPriority('High');
            email.setSaveAsActivity(false); 
            email.setTargetObjectId(aww.Id);
            email.setTemplateId(emTem.Id);
            email.setWhatId(aww.Id);
     
     
              //email.setSubject('BPP Direct Application System');
              email.setToAddresses(toAddresses);
              //email.setPlainTextBody('Thanks for applying to BPP. Here is the Password:' + aww.Password__c +' . ' );
           
             // email.setHtmlBody('Dear ' + aww.First_name__c + ', <br/> Thanks for applying to BPP! <br/><br/>Your password is: ' + aww.Password__c);
             
             try{
                Messaging.SendEmailResult [] r = Messaging.sendEmail(new Messaging.SingleEmailMessage[] {email});       
            }
            catch(Exception e){
                system.debug(e + 'Send email');
            }
             // Messaging.SendEmailResult [] r = Messaging.sendEmail(new Messaging.SingleEmailMessage[] {email});
              */
              aww.request_Password__c = true;
              update aww;
              pr = new PageReference('/apex/application_password_sent'); 
              pr.setRedirect(true); 
          
           }
           else {
                 ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Incorrect Details'));
                 requiredf = 'incorrectvalues';
                 pr = null;             
           }   
        }
        return pr;        
  }
  
  // this is the first page    it calls the lookup to load the existing data or save the new data
    public pageReference saveFind() {
        String requiredf = 'NO';
        PageReference pr;
        if(Username == '' || Username == null) {
            requiredf ='Yes';
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Email is Required'));
        } 
        if(password == '' || password == null) {
               requiredf ='Yes';
               ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Password is Required'));
        }
        if(requiredf =='NO') { 
            if([SELECT count() FROM Application_wizard__c WHERE  password__c =: password AND Email__c =: Username limit 1] == 1) {
                Application_wizard__c  aww = [SELECT Id, Submitted__c, Internal_Tracking_Status__c, App_Wiz_Student_Type__c, Marketing_Opt_Out__c,
                                                     Security_Token__c, Security_Expiry_Date__c, First_name__c, last_Name__c, Email__c, Password__c 
                                              FROM Application_wizard__c 
                                              WHERE password__c =: password AND Email__c =:Username AND Internal_Tracking_Status__c != 'User Deleted' ORDER BY CreatedDate DESC limit 1];
                //AND Internal_Tracking_Status__c = 'Active' 
                
                if(aww.Submitted__c == False && aww.Internal_Tracking_Status__c == 'Active') { //active application found, login
                    aww.Security_Token__c = generateSecurityToken();
                    aww.Security_Expiry_Date__c = system.Now().addDays(1);
                    auth_id = aww.Security_Token__c;
                    
                    wiz_id = aww.id;  
                    if(aww.App_Wiz_Student_Type__c == 'Domestic')
                        isDomestic = true;
                    else
                        isDomestic = false;
                    update aww;      
                }
                else if(aww.Submitted__c == True && aww.Internal_Tracking_Status__c == 'Active') { //submitted application found, create new aw record
                    pr = createNewApplication(aww);
                    pr.setRedirect(true); 
                    requiredf = 'incorrectvalues';
                }
                else if(aww.Internal_Tracking_Status__c == 'In-Active') { //inactive application found, create new aw record (status set by workflow after 12 months if application is not submitted)
                    pr = createNewApplication(aww);
                    pr.setRedirect(true); 
                    requiredf = 'incorrectvalues';
                }                
            }        
            else {
                 ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Incorrect Email or Password'));
                 requiredf = 'incorrectvalues';
                 pr = null;             
            }         
        }
         
        if(requiredf == 'Yes') {
            pr= null;
        }
        
        if(requiredf == 'NO') {         
            pr = new PageReference('/apex/application_checklist_status'+'?wiz_id='+wiz_id+'&auth_id='+auth_id); 
            //pr = new PageReference('/apex/application_personal_details'+'?wiz_id='+wiz_id); 
            pr.setRedirect(true); 
        }
        return pr;
    }
    
  public string generateSecurityToken(){
    Integer len = 15;
    blob blobKey = Crypto.generateAesKey(128);
    String key = EncodingUtil.convertToHex(blobKey);
    String sToken = key.substring(0,len);
    System.debug('************ '+sToken);       
    return sToken;
  } 
  
   public pageReference newUserReg() { 
       //New user flag, no need to show checklist page in case of new user
       isNewUser = true;
       String requiredf = 'NO';
       PageReference pr;
        /*
        if(Username == '' || Username == null) {
               requiredf ='Yes';
               ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Username is Required'));
        } else if([SELECT count() FROM Application_wizard__c WHERE  Username__c =:Username limit 1] >= 1) {
           requiredf ='Yes';
           ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Username already exists'));        
        }
        */
        if(firstname == null || firstname == '') {
           requiredf ='Yes';
           ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'First name is required'));        
        } 
        if(lastname == '' || lastname == null) {
           requiredf ='Yes';
           ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Surname/Family name is required.'));
        } 
        
        if(email == '' || email == null) {
           requiredf ='Yes';
           ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Email is required.'));
        } else if([SELECT count() FROM Application_wizard__c WHERE  Email__c=:email AND Internal_Tracking_Status__c = 'Active' limit 1] >= 1) {
           requiredf ='Yes';
           ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Email address is already registered.'));        
        }
        
        if(password == '' || password == null) {
           requiredf ='Yes';
           ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Password is required.'));
        } 
        else if( password.length() <8 || password.length() > 16){   
           requiredf ='Yes';
           ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Password length must be at least 8 and maximum 16 characters.'));
        }
        if(email != null && email != email2) {
           requiredf ='Yes';
           ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Email addresses do not match.'));        
        }        
        if(password != null && password != password2) {
           requiredf ='Yes';
           ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Passwords do not match.'));        
        }  
        
        
        if(requiredf =='NO') {          
            System.debug('***Else***New user***'+Username);
            aw = new Application_wizard__c(Email__c = email, last_Name__c = lastname, First_name__c = firstname, 
                                            password__c = password, Username__c = Username, Marketing_Opt_Out__c = mrkgting_opt_out);
                                            //email_mrkgting__c = email_mrkgting, post_mrkting__c = post_mrkgting, telephone_mrkting__c = telephone_mrkgting, sms_mrkting__c = sms_mrkgting
                                           
            // update the database and get the id for the record we insert
            try {
                aw.Security_Token__c = generateSecurityToken();
                aw.Security_Expiry_Date__c = system.Now().addDays(1);
                auth_id = aw.Security_Token__c; 
               Database.UpsertResult upsertResults = Database.upsert(aw);
               //Database.SaveResult upsertResults = Database.insert(aw);  
               wiz_id = upsertResults.Id;
            }Catch(DMLException ex) {
               ApexPages.addMessages(ex);
            } 
        }   
        
    if(requiredf == 'Yes') {
        pr= null;
    }
    if(requiredf == 'NO') {
          pr = new PageReference('/apex/application_personal_details'+'?wiz_id='+wiz_id+'&auth_id='+auth_id);    
          //pr = new PageReference('/apex/application_checklist_status'+'?wiz_id='+wiz_id); 
          pr.setRedirect(true); 
    }
      return pr;     
  }

     public void checkdummy1() {
         if(listprogramme != null) {
             Programme__c p1 = [SELECT Id, Name, Description__c FROM Programme__c where id=:listprogramme];  
             if(p1.Name.startswith('ACCA')) {
                 displayACCAPanel = True;
             } else {
                 displayACCAPanel = False;             
             }
         }
     }
 
   public pageReference saveReference() {     
/*   
    if( aw.telephone__c != Null )  { 
        string s = aw.telephone__c;
        String reg = '[\\+ 0-9()\\.\\-]{'+s.length()+'}';
        Pattern phonePattern = Pattern.compile(reg);
       
        Matcher phoneMatcher = phonePattern.matcher(s);   
        if(PhoneMatcher.matches() == false) {
           requiredf ='Yes';
           ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,phoneMatcher.matches()+s+' Personal Details: Main Contact telephone is INVALID'));
        }
    }
  */       
      Database.upsert(reference);
      return null;
  }
  
 public pageReference saveNextReference() {
 String requiredf = 'NO';
  PageReference pr;
    for(Application_wizard_reference__c ref : reference) { 
        integer activerow =0;
        if(ref.Reference_name__c != '' && ref.Reference_name__c != Null) { 
            activerow = 1;
        }
        if(ref.Reference_Position__c != '' && ref.Reference_Position__c != Null){
            activerow = 1;
        }
        if(ref.Address_Line1__c !='' && ref.Address_Line1__c !=null){
                    activerow = 1;
        }
        if(ref.reference_city__c != '' && ref.reference_city__c != Null){
                    activerow = 1;
        }
        if(activerow !=0) {
            if(ref.Reference_name__c == '' || ref.Reference_name__c == null) {
                   requiredf ='Yes';
                   ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Refrence name is required'));
            }             
            if(ref.Reference_Position__c == '' || ref.Reference_Position__c == Null) {
                   requiredf ='Yes';
                   ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Reference Position is required'));
            }  
            if(ref.Address_Line1__c =='' || ref.Address_Line1__c ==Null) {
                   requiredf ='Yes';
                   ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Reference Address Line 1 is required'));
            }  
            if(ref.reference_city__c == '' || ref.reference_city__c == Null) {
                   requiredf ='Yes';
                   ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Reference City is required'));
            }  
            /*
            if(ref.reference_postal__c == '' || ref.reference_postal__c == null) {
                   requiredf ='Yes';
                   ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,' Postal Missing  on Row '+ref.iteration__c));
            }  
            if(ref.reference_telephone__c == '' || ref.reference_telephone__c == Null) {
                   requiredf ='Yes';
                   ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,' Telephone Missing  on Row '+ref.iteration__c));
            }  
            if(ref.reference_email__c == '' ||  ref.reference_email__c == null) {
                   requiredf ='Yes';
                   ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,' Email Missing  on Row '+ref.iteration__c));
            }  
            if(ref.reference_date__c == Null )  {
                   requiredf ='Yes';
                   ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,' Date Missing  on Row '+ref.iteration__c));
            } 
    
            if( ref.reference_telephone__c != '' && ref.reference_telephone__c !=null)  { 
                string s = ref.reference_telephone__c;
                String reg = '[\\+ 0-9()\\-\\.]{'+s.length()+'}';
                Pattern phonePattern = Pattern.compile(reg);
               
                Matcher phoneMatcher = phonePattern.matcher(s);   
                if(PhoneMatcher.matches() == false) {
                   requiredf ='Yes';
                   ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,' Telephone is INVALID on Row '+ref.iteration__c));
                }
             }
             */
        }
    } 
    
    if(!isDomestic){ //only require the personal statement for international apps
        if(aw == null || aw.personal_statement__c == Null )  {
                requiredf ='Yes';
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,' Personal statement details are missing'));
        } else if (aw.personal_statement__c != null) {
                string[] ss = aw.personal_statement__c.split(' ');
                if(ss.size() < 250) {
                        requiredf ='Yes';
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,' Personal statement must have minimum 250 words'));      
                }
        }
    }
    
    if(requiredf =='NO') {          
             // update the database and get the id for the record we insert
       try{
           Database.upsert(reference);
           aw.Personal_statement_complete__c = 'Yes';
           Database.upsert(aw);
           pr = new PageReference('/apex/'+nextPage+'?wiz_id='+wiz_id+'&auth_id='+auth_id);
           pr.setRedirect(true); 
       }catch(DMLException ex) {
           errorMessage('ex'+ex);
       }
    } else {
    
    pr= null;
    }   
      return pr;
  }
 /* 
  public pageReference saveEdu() {
     list <application_wizard_eduction__c> listed;
     if(nextPage== 'application_education_history'){
          listed = edlist.deepclone();
     } 
     
     if(nextPage== 'application_employment_history'){
          listed = edlisth.deepclone();
     }
  
  
         String requiredf = 'NO';
         PageReference pr;
         for(application_wizard_eduction__c eds : listed) { 
                integer activerow =0;
            // common fields
            if(eds.predicted_actual__c != '' && eds.predicted_actual__c != Null) { 
                activerow = 1;
            }
            if(eds.subject__c != '' && eds.subject__c != Null) { 
                activerow = 1;
            }        
        if(eds.Grade__c != '' && eds.Grade__c != Null) { 
            activerow = 1;
        }         
        //higher ed specific fields
        if(nextPage== 'application_employment_history') {
         //full_time__c, institution__c, title_of_award__c
         
            if(eds.institution__c != '' && eds.institution__c != Null) { 
                activerow = 1;
            } 
            if(eds.title_of_award__c != '' && eds.title_of_award__c != Null) { 
                activerow = 1;
            } 
         }
                
         if(activerow !=0) {
            //common fields
            if(eds.predicted_actual__c == '' || eds.predicted_actual__c == null) {
                   requiredf ='Yes';
                   ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Actual Predicted Missing on Row '+eds.iteration__c));
            } 
            if(eds.subject__c  == '' || eds.subject__c  == null) {
                   requiredf ='Yes';
                   ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Subject Missing on Row '+eds.iteration__c));
            } 
            if(eds.Grade__c  == '' || eds.Grade__c  == null) {
                   requiredf ='Yes';
                   ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Grade Missing on Row '+eds.iteration__c));
            }
            //higher ed fields
            if(nextPage== 'application_employment_history') {
                if(eds.title_of_award__c  == '' || eds.title_of_award__c  == null) {
                       requiredf ='Yes';
                       ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Title of Award is Missing on Row '+eds.iteration__c));
                }
                if(eds.institution__c  == '' || eds.institution__c  == null) {
                       requiredf ='Yes';
                       ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Institution Name is Missing on Row '+eds.iteration__c));
                }
            }               
                }
        } 
    if(requiredf =='NO') {          
             // update the database and get the id for the record we insert
        if(nextPage== 'application_education_history'){
      
             Database.upsert(edlist); 
         } 
         
         if(nextPage== 'application_employment_history'){
             Database.upsert(edlisth);
         }
         //pr = new PageReference('/apex/'+nextPage+'?wiz_id='+wiz_id+'&auth_id='+auth_id);
       pr.setRedirect(true); 
    } else {
    
    //pr= null;
    }      
    return null;
  }
  */
public pageReference saveNextEdu() {
    // nextPage = ApexPages.currentPage().getParameters().get('nextPage');
    // row validation logic
    String requiredf = 'NO';
    integer ACCACount =0;
    list <application_wizard_eduction__c> listed;
    list <application_wizard_eduction__c> listed_he;
    list <application_wizard_eduction__c> listed_hs;
    list <application_wizard_eduction__c> listed_oq;
    
    if(nextPage == 'application_education_history') {
        if(listprogramme != null) {
            Programme__c p1 = [SELECT Id, Name, Description__c 
                               FROM Programme__c where id=:listprogramme];  
            string s = null;
            if(p1.Name.startswith('ACCA')) {
                if(aw.F1__c){
                    if(s==null)  s = 'ACCA - Knowledge - F1';
                    else s = s + ';' + 'ACCA - Knowledge - F1';
                    ACCACount +=1;                        
                }
                if(aw.F2__c){
                    if(s==null) s= 'ACCA - Knowledge - F2';
                    else s= s + ';' + 'ACCA - Knowledge - F2';
                    ACCACount +=1;                        
                }
                if(aw.F3__c){
                    if(s==null) s= 'ACCA - Knowledge - F3';
                    else s= s + ';' + 'ACCA - Knowledge - F3';
                    ACCACount +=1;                        
                }
                if(aw.F4__c){
                    if(s==null) s = 'ACCA - Skills - F4';
                    else s = s + ';' + 'ACCA - Skills - F4';
                    ACCACount +=1;                        
                }
                if(aw.F5__c){
                    if(s==null) s= 'ACCA - Skills - F5';
                    else s= s + ';' + 'ACCA - Skills - F5';
                    ACCACount +=1;                        
                }
                if(aw.F6__c){
                    if(s==null) s= 'ACCA - Skills - F6';
                    else s= s + ';' + 'ACCA - Skills - F6';
                    ACCACount +=1;                      
                }
                if(aw.F7__c){
                    if(s==null) s = 'ACCA - Skills - F7';
                    else s = s + ';' + 'ACCA - Skills - F7'; 
                    ACCACount +=1;                      
                }
                if(aw.F8__c){
                    if(s==null) s= 'ACCA - Skills - F8';
                    else s= s + ';' + 'ACCA - Skills - F8';  
                    ACCACount +=1;                      
                }
                if(aw.F9__c){
                    if(s==null) s= 'ACCA - Skills - F9';
                    else s= s + ';' + 'ACCA - Skills - F9'; 
                    ACCACount +=1;                      
                }
                if(aw.P1__c){
                    if(s==null) s = 'ACCA - Essentials - P1';
                    else s = s + ';' + 'ACCA - Essentials - P1';
                    ACCACount +=1;
                }
                if(aw.P2__c){
                    if(s==null) s = 'ACCA - Essentials - P2';
                    else s = s + ';' + 'ACCA - Essentials - P2';
                    ACCACount +=1;
                }
                if(aw.P3__c){
                    if(s==null) s = 'ACCA - Essentials - P3';
                    else s = s + ';' + 'ACCA - Essentials - P3';
                    ACCACount +=1;
                }
                if(aw.P4__c){
                    if(s==null) s = 'ACCA - Options - P4';
                    else s = s + ';' + 'ACCA - Options - P4';
                    ACCACount +=1;
                }
                if(aw.P5__c){
                    if(s==null) s = 'ACCA - Options - P5';
                    else s = s + ';' + 'ACCA - Options - P5';
                    ACCACount +=1;
                }
                if(aw.P6__c){
                    if(s==null) s = 'ACCA - Options - P6';
                    else s = s + ';' + 'ACCA - Options - P6';
                    ACCACount +=1;
                }
                if(aw.P7__c){
                    if(s==null) s = 'ACCA - Options - P7';
                    else s = s + ';' + 'ACCA - Options - P7';
                    ACCACount +=1;
                }
                aw.Modules__c = s;
                system.debug('herehere');
                for(application_wizard_eduction__c accaED : accaEDList) {
                    if(accaED.full_time__c) {
                        ACCACount +=1;
                    }   
                }
                if(ACCACount < 1) {
                    requiredf ='Yes';
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'You must choose at least 1 ACCA Course'));
                }
                system.debug('Hi How are you?'+ accaEDList); 
                system.debug('accaEDList.size()'+ accaEDList.size());             
            } 
            else{
                aw.F1__c = false;aw.F2__c = false;aw.F3__c = false;aw.F4__c = false;aw.F5__c = false;
                aw.F6__c = false;aw.F7__c = false;aw.F8__c = false;aw.F9__c = false;
                aw.P1__c = false;aw.P2__c = false;aw.P3__c = false;aw.P4__c = false;
                aw.P5__c = false;aw.P6__c = false;aw.P7__c = false;
                aw.Modules__c = s;
            }               
        }
        if(listprogramme == null) {
            requiredf ='Yes';
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Choose a Program to continue'));
        }
        if(listmodes == null) {
            requiredf ='Yes';
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Choose a Mode to continue'));
        }
        if(listlocation == null) {
            requiredf ='Yes';
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Choose a Location to continue'));
        }
        if(progYear == null) {
            requiredf ='Yes';
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Choose a Year to continue'));
        }
        if(listmonths == null) {
            requiredf ='Yes';
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Choose a Month to continue'));
        }
    }  
    if(nextPage== 'application_employment_history'){
        listed_he = edlisth.deepclone();
        listed_hs = edlist.deepclone();
        listed_oq = edlisto.deepclone();
                        
        //Higher Education validation
        for(application_wizard_eduction__c eds : listed_he) { 
            integer activerow =0;
            if(eds.Type_Lookup__c != Null) { activerow = 1; }
            if(eds.Subject_Lookup__c != Null) { activerow = 1; }
            if(eds.Institution_Lookup__c != Null) { activerow = 1; }
            if(eds.Grade__c != '' && eds.Grade__c != Null) { activerow = 1; }
            if(eds.predicted_actual__c != '' && eds.predicted_actual__c != Null) { activerow = 1; }
            if(eds.Qualification_Date__c != Null) { activerow = 1; }
            if(eds.Mode_of_Study__c != '' && eds.Mode_of_Study__c != Null) { activerow = 1; }
            if(activerow !=0) {
                if(eds.Type_Lookup__c  == null) {
                    requiredf ='Yes';
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Type missing on Higher Education row '+eds.iteration__c));
                }                 
                if(eds.Subject_Lookup__c  == null) {
                    requiredf ='Yes';
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Subject missing on Higher Education row '+eds.iteration__c));
                } 
                if(eds.Institution_Lookup__c  == null) {
                    requiredf ='Yes';
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Awarding Institution is missing on Higher Education row '+eds.iteration__c));
                }
                if(eds.Grade__c  == '' || eds.Grade__c  == null) {
                    requiredf ='Yes';
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Grade/Class of Degree missing on Higher Education row '+eds.iteration__c));
                }
                else if(eds.Grade__c.length() > 5) {
                   requiredf ='Yes';
                   ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Grade/Class of Degree is limited to 5 characters on Higher Education Row '+eds.iteration__c));
                }
                if(eds.predicted_actual__c == '' || eds.predicted_actual__c == null) {
                    requiredf ='Yes';
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Actual or Predicted missing on Higher Education row '+eds.iteration__c));
                } 
                if(eds.Qualification_Date__c == null) {
                    requiredf ='Yes';
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Qualification Date missing on Higher Education row '+eds.iteration__c));
                } 
                /*
                else if(eds.Qualification_Date__c > system.now()) {
                    requiredf ='Yes';
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Qualification Date should not be a future date on Higher Education row '+eds.iteration__c));
                } 
                */
                if(eds.Mode_of_Study__c == '' || eds.Mode_of_Study__c == null) {
                    requiredf ='Yes';
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Mode of Study missing on Higher Education row '+eds.iteration__c));
                }  
            }
        }
        //A Levels and GCSEs validation
        for(application_wizard_eduction__c eds : listed_hs) { 
            integer activerow =0;
            // common fields
            if(eds.Type_Lookup__c != Null) { activerow = 1; } 
            if(eds.Subject_Lookup__c != Null) { activerow = 1; }     
            if(eds.Institution_Lookup__c != Null) { activerow = 1; } 
            if(eds.Qualification__c != '' && eds.Qualification__c != Null) { activerow = 1; }
            if(eds.Grade__c != '' && eds.Grade__c != Null) { activerow = 1; }
            if(eds.predicted_actual__c != '' && eds.predicted_actual__c != Null) { activerow = 1; }
            if(eds.Qualification_Date__c != Null) { activerow = 1; }
            if(activerow !=0) {
                if(eds.Type_Lookup__c  == null) {
                   requiredf ='Yes';
                   ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Type missing on A Levels and GCSEs row '+eds.iteration__c));
                } 
                if(eds.Subject_Lookup__c  == null) {
                   requiredf ='Yes';
                   ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Subject missing on A Levels and GCSEs row '+eds.iteration__c));
                } 
                if(eds.Institution_Lookup__c  == null) {
                    requiredf ='Yes';
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Awarding Institution is missing on A Levels and GCSEs row '+eds.iteration__c));
                }
                if(eds.Qualification__c  == '' || eds.Qualification__c  == null) {
                    requiredf ='Yes';
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Qualification missing on A Levels and GCSEs row '+eds.iteration__c));
                }   
                if(eds.Grade__c  == '' || eds.Grade__c  == null) {
                    requiredf ='Yes';
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Grade missing on A Levels and GCSEs row '+eds.iteration__c));
                }
                else if(eds.Grade__c.length() > 5) {
                   requiredf ='Yes';
                   ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Grade is limited to 5 characters on A Levels and GCSEs Row '+eds.iteration__c));
                }
                if(eds.predicted_actual__c == '' || eds.predicted_actual__c == null) {
                    requiredf ='Yes';
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Actual or Predicted missing on A Levels and GCSEs row '+eds.iteration__c));
                }     
                if(eds.Qualification_Date__c == null) {
                    requiredf ='Yes';
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Qualification Date missing on A Levels and GCSEs row '+eds.iteration__c));
                } 
                /*
                else if(eds.Qualification_Date__c > system.now()) {
                    requiredf ='Yes';
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Qualification Date should not be a future date on A Levels and GCSEs row '+eds.iteration__c));
                } 
                */
            }
        }
        //Other Qualifications
        for(application_wizard_eduction__c eds : listed_oq) { 
            integer activerow =0;
            // common fields
            if(eds.Type_Lookup__c != Null) { activerow = 1; }   
            if(eds.Subject_Lookup__c != Null) { activerow = 1; }    
            if(eds.Institution_Lookup__c != Null) { activerow = 1; }   
            if(eds.Other_Qualification__c != '' && eds.Other_Qualification__c != Null) { activerow = 1; }              
            if(eds.Grade__c != '' && eds.Grade__c != Null) { activerow = 1; }
            if(eds.predicted_actual__c != '' && eds.predicted_actual__c != Null) { activerow = 1; }
            if(eds.Qualification_Date__c != Null) { activerow = 1; }
            if(activerow !=0) {
                if(eds.Type_Lookup__c  == null) {
                    requiredf ='Yes';
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Type missing on Other Qualifications row '+eds.iteration__c));
                } 
                if(eds.Subject_Lookup__c  == null) {
                    requiredf ='Yes';
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Subject missing on Other Qualifications row '+eds.iteration__c));
                } 
                if(eds.Institution_Lookup__c  == null) {
                    requiredf ='Yes';
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Awarding Institution is missing on Other Qualifications row '+eds.iteration__c));
                }  
                if(eds.Other_Qualification__c  == '' || eds.Other_Qualification__c  == null) {
                    requiredf ='Yes';
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Qualification missing on Other Qualifications row '+eds.iteration__c));
                }   
                if(eds.Grade__c  == '' || eds.Grade__c  == null) {
                    requiredf ='Yes';
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Grade missing on Other Qualifications row '+eds.iteration__c));
                }
                else if(eds.Grade__c.length() > 5) {
                   requiredf ='Yes';
                   ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Grade is limited to 5 characters on Other Qualifications Row '+eds.iteration__c));
                }
                if(eds.predicted_actual__c == '' || eds.predicted_actual__c == null) {
                    requiredf ='Yes';
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Actual or Predicted missing on Other Qualifications row '+eds.iteration__c));
                }       
                if(eds.Qualification_Date__c == null) {
                    requiredf ='Yes';
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Qualification Date missing on Other Qualifications row '+eds.iteration__c));
                } 
                /*
                else if(eds.Qualification_Date__c > system.now()) {
                    requiredf ='Yes';
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Qualification Date should not be a future date on Other Qualifications row '+eds.iteration__c));
                } 
                */
            }
        }
        if(aw.is_english_your_first_language__c == '' || aw.is_english_your_first_language__c == null) {
            requiredf ='Yes';
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Is English your first language? is required'));
        }       
        if(aw.is_english_your_first_language__c == 'No' && (aw.Minimum_1_Year_Post_Education__c == '' || aw.Minimum_1_Year_Post_Education__c == null)) {
            requiredf ='Yes';
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,' Have you completed a minimum of 1 year post 18 education, taught in English? is required'));
        } 
        if(aw.is_english_your_first_language__c == 'No' && aw.Minimum_1_Year_Post_Education__c == 'No') {
            if(aw.eng_exam_type__c == '' || aw.eng_exam_type__c == null) {
                requiredf ='Yes';
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Exam Type is required'));
            }       
            if(aw.Eng_Exam_Date__c == null) {
                requiredf ='Yes';
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Date Completed/To be Completed is required'));
            }       
            /*if(aw.eng_exam_result__c == '' || aw.eng_exam_result__c == null) {
                requiredf ='Yes';
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Exam Result is required'));
            }*/                       
        } 
        if(aw.eng_exam_type__c == 'Other') {
            if(aw.eng_exam_type_other__c == '' || aw.eng_exam_type_other__c == null) {
                requiredf ='Yes';
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Please specify the type of exam'));
            }                       
        }
    } 
    
    PageReference pr;
    
    if(requiredf =='NO') {  
        // update the database and get the id for the record we insert
        if(nextPage== 'application_education_history'){
             aw.Location__c=listlocation;
             aw.Programme__c=listprogramme;
             aw.Mode__c=listmodes;
             //aw.course_year__c=decimal.valueof(progYear);
             aw.course_year__c=progYear;
             aw.Month__c=listmonths;
             aw.Course_Details_Complete__c = 'Yes';
             try{
                Database.upsert(aw);
             }catch(DMLException ex) {
                errorMessage('ex'+ex);
             }
             //Database.upsert(edlist); 
         } 
         
         if(nextPage== 'application_employment_history'){
             Database.upsert(edlisth);
             Database.upsert(edlist);
             Database.upsert(edlisto);
             aw.Language_Section_Complete__c = 'Yes';
             if(aw.is_english_your_first_language__c == 'Yes'){
                aw.Minimum_1_Year_Post_Education__c = null;
                aw.eng_exam_type__c = null;
                aw.Eng_Exam_Date__c = null;
                aw.eng_exam_type_other__c = null;
                aw.eng_exam_result__c = null;
             }
             else if(aw.Minimum_1_Year_Post_Education__c == 'Yes'){
                aw.eng_exam_type__c = null;
                aw.Eng_Exam_Date__c = null;
                aw.eng_exam_type_other__c = null;
                aw.eng_exam_result__c = null;
             }
             
             Database.upsert(aw);               
         }
         pr = new PageReference('/apex/'+nextPage+'?wiz_id='+wiz_id+'&auth_id='+auth_id);
         pr.setRedirect(true); 
    } else { pr = null; }  
    return pr;
}
  
public pageReference saveEmp() {
    Database.upsert(employment);
    return null;    
}      
   
  public pageReference saveEmpNext() {
    String requiredf = 'NO'; 
               
    if(nextPage == 'application_international_history' || nextPage == 'application_other_details') {
        if(aw.Payment_Option__c == null) {
            requiredf ='Yes';
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Payment of Fees is missing'));
        }                
        else if(aw.Payment_Option__c == 'Company/Law Firm' || aw.Payment_Option__c == 'Government/International Agency') {
            aw.Are_yu_being_sponsored_for_the_programme__c= 'Yes';
        }
        else if(aw.Payment_Option__c == 'I will' || aw.Payment_Option__c == 'Parent/Guardian') {
            aw.Are_yu_being_sponsored_for_the_programme__c= 'No';
        }               
    }        
    PageReference pr;
    for(application_wizard_employment__c emps : employment) { 
        integer activerow =0;
        if(emps.Name_of_employer__c != '' && emps.Name_of_employer__c != Null) { activerow = 1; }
        if(emps.Job_Title__c != '' && emps.Job_Title__c != Null) { activerow = 1; }
        if(emps.Name_of_employer__c != '' && emps.description__c != Null) { activerow = 1; }
        if(emps.From__c != Null) { activerow = 1; }        
        if(emps.To__c != Null) { activerow = 1; } 
        if(emps.From__c > emps.To__c){ activerow = 1; }
        if(activerow !=0) {
            if(emps.Name_of_employer__c == '' || emps.Name_of_employer__c == null) {
                   requiredf ='Yes';
                   ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Name of employer is Missing on Row '+emps.iteration__c));
            } 
            if(emps.Job_Title__c  == '' || emps.Job_Title__c  == null) {
                   requiredf ='Yes';
                   ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Job title is Missing on Row '+emps.iteration__c));
            } 
            if(emps.from__c  == null) {
                   requiredf ='Yes';
                   ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'From Date is Missing on Row '+emps.iteration__c));
            }
            if(emps.from__c  > emps.To__c) {
               requiredf ='Yes';
               ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'From Date cannot be greater than to date on Row '+emps.iteration__c));
            }  
            if(emps.description__c  == '' || emps.description__c  == null) {
                   requiredf ='Yes';
                   ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Description is Missing on Row '+emps.iteration__c));
            }
            else if(emps.description__c.length() > 255) {
                   requiredf ='Yes';
                   ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Description is limited to 255 characters on Row '+emps.iteration__c));
            }         
        }
    }
    if(nextPage == 'application_other_details'){
        if(!isDomestic){
            if(aw.Similar_course_in_other_country__c == null){
                requiredf ='Yes';
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'International History: Is a similar course available in your country is required.'));
            }
            else if(aw.Similar_course_in_other_country__c == 'Yes' && aw.Why_UK__c == null){
                requiredf ='Yes';
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'International History: Why have you chosen to study in the UK is required.'));             
            }
            if(aw.Applied_to_Other_Universities__c == null){
                requiredf ='Yes';
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'International History: Have you applied to other universities is required.'));
            }
            else if(aw.Applied_to_Other_Universities__c == 'Yes' && aw.Other_University_Details__c == null){
                requiredf ='Yes';
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'International History: Applied university details are required.'));
            }
            if(aw.Hours_per_week__c == null){
                requiredf ='Yes';
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'International History: Class attendance hours per week is required.'));
            }
                        
            //Immigration History section validation
            if(aw.Are_you_currently_in_Uk_with_a_visa__c == null){
                requiredf ='Yes';
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'International History: Are you currently in the UK on a Visa is required.'));
            }
            if(aw.Ever_studied_in_UK_before__c == null){
                requiredf ='Yes';
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'International History: Have you ever lived/studied in the UK on a Visa is required.'));
            }
            
            //Validation for Visa related list
            list <Application_Wizard_Visa__c> listed_visa;
            listed_visa = visalist.deepclone();
                        
            if(aw.Are_you_currently_in_Uk_with_a_visa__c == 'Yes' || aw.Ever_studied_in_UK_before__c == 'Yes') {        
                for(Application_Wizard_Visa__c visa : listed_visa) { 
                    integer activerow = 0;
                    if(visa.Visa_Issue_Date__c != Null) { activerow = 1; }
                    if(visa.Visa_Expiry_Date__c != Null) { activerow = 1; }
                    if(visa.Visa_Type__c != '' && visa.Visa_Type__c != Null) { activerow = 1; }
                    if(visa.Other_Visa_Type__c != '' && visa.Other_Visa_Type__c != Null) { activerow = 1; }
                    if(visa.Visa_Qualification__c != '' && visa.Visa_Qualification__c != Null) { activerow = 1; }
                    if(visa.Visa_Institution__c != '' && visa.Visa_Institution__c != Null) { activerow = 1; }
                    if(visa.Level_of_Studies__c != '' && visa.Level_of_Studies__c != Null) { activerow = 1; }
                    if(visa.Completed_Course_at_Visa_Institution__c != '' && visa.Completed_Course_at_Visa_Institution__c != Null) { activerow = 1; }
                    if(visa.Actual_Qualification_Institution__c != '' && visa.Actual_Qualification_Institution__c != Null) { activerow = 1; }      
                            
                    if(activerow != 0) {                            
                        if(visa.Visa_Issue_Date__c == null) {
                            requiredf ='Yes';
                            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Visa Issue Date is missing on Visa ' + visa.iteration__c));
                        }
                        else if(visa.Visa_Issue_Date__c > system.now()){
                            requiredf ='Yes';
                            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Visa Issue Date cannot be a future date on Visa ' + visa.iteration__c));
                        }                        
                        if(visa.Visa_Expiry_Date__c == null) {
                            requiredf ='Yes';
                            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Visa Expiry Date is missing on Visa ' + visa.iteration__c));
                        }
                        else if(visa.Visa_Issue_Date__c > visa.Visa_Expiry_Date__c){
                            requiredf ='Yes';
                            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Visa Expiry Date cannot be before visa issue date on Visa ' + visa.iteration__c));
                        }
                        if(visa.Visa_Type__c == '' || visa.Visa_Type__c  == null) {
                            requiredf ='Yes';
                            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Visa Type is missing on Visa ' + visa.iteration__c));
                        }
                        if(visa.Visa_Type__c == 'Other' && visa.Other_Visa_Type__c  == null) {
                            requiredf ='Yes';
                            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Other Visa Type is missing on Visa ' + visa.iteration__c));
                        }               
                        if(visa.Visa_Qualification__c == '' || visa.Visa_Qualification__c == null) {
                            requiredf ='Yes';
                            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Visa Qualification is missing on Visa ' + visa.iteration__c));
                        } 
                        if(visa.Visa_Institution__c == '' || visa.Visa_Institution__c == null) {
                            requiredf ='Yes';
                            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Visa Institution is missing on Visa ' + visa.iteration__c));
                        }  
                        if(visa.Level_of_Studies__c == '' || visa.Level_of_Studies__c == null) {
                            requiredf ='Yes';
                            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Level of Studies is missing on Visa ' + visa.iteration__c));
                        }  
                        if(visa.Completed_Course_at_Visa_Institution__c == '' || visa.Completed_Course_at_Visa_Institution__c == null) {
                            requiredf ='Yes';
                            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Completed Course at Visa Institution is missing on Visa ' + visa.iteration__c));
                        } 
                        if(visa.Completed_Course_at_Visa_Institution__c == 'No' && visa.Actual_Qualification_Institution__c  == null) {
                            requiredf ='Yes';
                            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Actual Qualification and Institution where you completed the course is missing on Visa ' + visa.iteration__c));
                        }               
                    }
                    if(visa.iteration__c == 1 && activerow == 0) { //this is the first visa record and it is blank
                        requiredf ='Yes';
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'You must enter information for at least one Visa'));
                    }
                } //end for loop
            } //end if
                
            /*else if(aw.Are_you_currently_in_Uk_with_a_visa__c == 'Yes'){
                if(aw.Current_Visa_Type__c == null){
                    requiredf ='Yes';
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'International History: Current visa type is required.'));
                }
                else if(aw.Current_Visa_Type__c == 'Other' && aw.Other_Visa_Type__c == null){
                    requiredf ='Yes';
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'International History: Other visa type is required.'));
                }
            }
            if(aw.Are_you_currently_studying_in_UK__c == null){
                requiredf ='Yes';
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'International History: Are you currently studying in the UK is required.'));
            }
            else if(aw.Are_you_currently_studying_in_UK__c == 'Yes' && aw.Current_course_in_UK__c == null){
                requiredf ='Yes';
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'International History: Current course in the UK is required.'));
            }*/
            
            if(aw.Intend_to_apply_for_Student_Via__c == null){
                requiredf ='Yes';
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'International History: Intend to apply for Tier 4 visa is required.'));
            }
            else if(aw.Intend_to_apply_for_Student_Via__c == 'No' && aw.Type_of_Visa_intend_to_apply__c == null){
                requiredf ='Yes';
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'International History: What type of visa do you intend to apply for is required.'));
            }
            
            /*if(aw.Ever_studied_in_UK_before__c == null){
                requiredf ='Yes';
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'International History: Have you ever studied in UK before is required.'));
            }
            else if(aw.Ever_studied_in_UK_before__c == 'Yes' && aw.Most_recent_course_studied_in_UK__c == null){
                requiredf ='Yes';
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'International History: Most recent course studied in the UK is required.'));
            }
            if(aw.Applied_fro_Student_Visa_before__c == null){
                requiredf ='Yes';
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'International History: Have you ever applied for a student visa before is required.'));
            }*/
            
            if(aw.Have_you_been_refused__c == null){
                requiredf ='Yes';
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'International History: Have you been refused a UK visa before is required.'));
            }
            if(aw.Passport_Number__c == null){
                requiredf ='Yes';
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'International History: Passport number is required.'));
            }
        }
    } 
    if(nextPage == 'application_submit') {
        if(!isDomestic){
            if(aw != null && aw.Passport_date_expected__c == null && aw.Passport_Copy_Uploaded__c == false && PassportName == null) {
                requiredf ='Yes';
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Upload passport copy or choose the date expected.'));
            }
            else if(aw != null && aw.Passport_date_expected__c != null && aw.Passport_Copy_Uploaded__c == false && PassportName == null){
                if(aw.Passport_date_expected__c < system.now()){
                    requiredf = 'Yes';
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Please choose a correct future date passport copy is expected.'));
                }
            }
            
            if(aw != null && aw.Visa_date_expected__c == null && aw.Visa_copy_uploaded__c == false && VisaName == null) {
                requiredf ='Yes';
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Upload Visa copy or choose the date expected.'));
            }
            else if(aw != null && aw.Visa_date_expected__c != null && aw.Visa_copy_uploaded__c == false && VisaName == null) {
                if(aw.Visa_date_expected__c < system.now()){
                    requiredf = 'Yes';
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Please choose a correct future date Visa copy is expected.'));
                }
            }
            
            if(aw != null && aw.Academic_date_expected__c == null && aw.Academic_uploaded__c == false && AcademicName == null) {
                requiredf ='Yes';
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Upload academic certificates or choose the date expected.'));
            }
            else if(aw != null && aw.Academic_date_expected__c != null && aw.Academic_uploaded__c == false && AcademicName == null) {
                if(aw.Academic_date_expected__c < system.now()){
                    requiredf = 'Yes';
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Please choose a correct future date academic certificates are expected.'));
                }
            }
            if(aw != null && aw.English_date_expected__c == null && aw.English_Test_uploaded__c == false && EnglishName == null) {
                requiredf ='Yes';
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Upload English language test result or choose the date expected.'));
            }
            else if(aw != null && aw.English_date_expected__c != null && aw.English_Test_uploaded__c == false && EnglishName == null) {
                if(aw.English_date_expected__c < system.now()){
                    requiredf = 'Yes';
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Please choose a correct future date English language test result is expected.'));
                }
            }
            
            if(aw != null && aw.References_date_expected__c == null && aw.References_uploaded__c == false && ReferencesName == null) {
                requiredf ='Yes';
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Upload references or choose the date expected.'));
            }
            else if(aw != null && aw.References_date_expected__c != null && aw.References_uploaded__c == false && ReferencesName == null) {
                if(aw.References_date_expected__c < system.now()){
                    requiredf = 'Yes';
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Please choose a correct future date references are expected.'));
                }
            }
            
            if(aw != null && aw.Attendance_date_expected__c == null && aw.Attendance_record_uploaded__c == false && AttendanceName == null && AW.Ever_studied_in_UK_before__c == 'Yes') {
                requiredf ='Yes';
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Upload attendance record or choose the date expected.'));
            }
            else if(aw != null && aw.Attendance_date_expected__c != null && aw.Attendance_record_uploaded__c == false && AttendanceName == null && AW.Ever_studied_in_UK_before__c == 'Yes') {
                if(aw.Attendance_date_expected__c < system.now()){
                    requiredf = 'Yes';
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Please choose a correct future date attendence is expected.'));
                }
            }
            if(aw != null && aw.UK_Visa_History_uploaded__c == false && UKVisaHistoryName == null){
                requiredf ='Yes';
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Please Upload your UK VISA History Form to proceed.'));
            }
            /*if(aw != null && aw.Visa_Refusal_date_expected__c == null && aw.Visa_refusal_copy_uploaded__c == false && VisaRefusalName == null) {
                requiredf ='Yes';
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Upload Visa refusal copy or choose the date expected.'));
            }
            else if(aw != null && aw.Visa_Refusal_date_expected__c != null && aw.Visa_refusal_copy_uploaded__c == false  && VisaRefusalName == null) {
                if(aw.Visa_Refusal_date_expected__c < system.now()){
                    requiredf = 'Yes';
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL,'Please choose a correct future date Visa refusal copy is expected.'));
                }
            }
            */
        }
        if(listprogramme != null) {
            Programme__c p1 = [SELECT Id, Name, Description__c 
                               FROM Programme__c where id=:listprogramme]; 
            if(p1.Name.startswith('ACCA')){
                if(aw != null && aw.ACCA_date_expected__c == null && aw.ACCA_card_uploaded__c == false && ACCAName == null) {
                    requiredf ='Yes';
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Upload proof of ACCA registration or choose the date expected.'));
                }
                else if(aw != null && aw.ACCA_date_expected__c != null && aw.ACCA_card_uploaded__c == false && ACCAName == null) {
                    if(aw.ACCA_date_expected__c < system.now()){
                            requiredf = 'Yes';
                            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Please choose a correct future date proof of ACCA registration is expected.'));
                        }
                }
                else if(aw != null && aw.ACCA_card_uploaded__c == false && ACCAName != null){
                    if(ACCAFileSize > 5000000){
                        requiredf = 'Yes';
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'ACCA copy file size cannot be greater than 5MB.'));
                        ACCABody = null;
                        ACCAName = null;
                        ACCAFileSize = null;
                    }
                }
            }
        }
        if(aw != null && aw.Passport_Copy_Uploaded__c == false && PassportName != null){
            if(PassportFileSize > 5000000){
                requiredf = 'Yes';
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Passport copy file size cannot be greater than 5MB.'));
                PassportBody = null;
                PassportName = null;
                PassportFileSize = null;
            }
        }
        if(aw != null && aw.Visa_copy_uploaded__c == false && VisaName != null){
            if(VisaFileSize > 5000000){
                requiredf = 'Yes';
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Visa copy file size cannot be greater than 5MB.'));
                VisaBody = null;
                VisaName = null;
                VisaFileSize = null;
            }
        }
        if(aw != null && aw.Academic_uploaded__c == false && AcademicName != null){
            if(AcademicFileSize > 5000000){
                requiredf = 'Yes';
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Academic copy file size cannot be greater than 5MB.'));
                AcademicBody = null;
                AcademicName = null;
                AcademicFileSize = null;
            }
        }
        if(aw != null && aw.English_Test_uploaded__c == false && EnglishName != null){
            if(EnglishTestFileSize > 5000000){
                requiredf = 'Yes';
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'English Test copy file size cannot be greater than 5MB.'));
                EnglishBody = null;
                EnglishName = null;
                EnglishTestFileSize=null;
            }
        }
        if(aw != null && aw.References_uploaded__c == false && ReferencesName != null){
            if(ReferenceFileSize > 5000000){
                requiredf = 'Yes';
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Reference copy file size cannot be greater than 5MB.'));
                ReferencesBody = null;
                ReferencesName = null;
                ReferenceFileSize = null;
            }
        }           
        if(aw != null && aw.Attendance_record_uploaded__c == false && AttendanceName != null){
            if(AttendanceFileSize > 5000000){
                requiredf = 'Yes';
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Attendence copy file size cannot be greater than 5MB.'));
                AttendanceBody = null;
                AttendanceName = null;
                AttendanceFileSize = null;
            }
        }
        if(aw != null && aw.Visa_refusal_copy_uploaded__c == false && VisaRefusalName != null){
            if(VisaRefusalFileSize > 5000000){
                requiredf = 'Yes';
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Visa Refusal copy file size cannot be greater than 5MB.'));
                VisaRefusalBody = null;
                VisaRefusalName = null;
                VisaRefusalFileSize = null;
            }
        }
        if(aw != null && aw.UK_Visa_History_uploaded__c == false && UKVisaHistoryName != null){
            if(UKVisaHistoryFileSize > 5000000){
                requiredf = 'Yes';
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'UK Visa History form file size cannot be greater than 5MB.'));
                UKVisaHistoryBody = null;
                UKVisaHistoryName = null;
                UKVisaHistoryFileSize = null;
            }
        }
        if(aw != null && Additional_Doc_1_Name != null){
            if(Add_Doc1_FileSize > 5000000){
                requiredf = 'Yes';
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Additional Document 1 file size cannot be greater than 5MB.'));
                Additional_Doc_1_Body = null;
                Additional_Doc_1_Name = null;
                Add_Doc1_FileSize = null;
            }
        }
        if(aw != null && Additional_Doc_2_Name != null){
            if(Add_Doc2_FileSize > 5000000){
                requiredf = 'Yes';
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Additional Document 2 file size cannot be greater than 5MB.'));
                Additional_Doc_2_Body = null;
                Additional_Doc_2_Name = null;
                Add_Doc2_FileSize = null;
            }
        }
        if(aw != null && Additional_Doc_3_Name != null){
            if(Add_Doc3_FileSize > 5000000 && Add_Doc3_FileSize < 10000000){
                requiredf = 'Yes';
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Additional Document 3 file size cannot be greater than 5MB.'));
                Additional_Doc_3_Body = null;
                Additional_Doc_3_Name = null;
                Add_Doc3_FileSize = null;
            }
        /*  else if(Add_Doc3_FileSize > 10000000){
                requiredf = 'Yes';
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Additional Document 3 file size cannot be greater than 10MB.'));
                Additional_Doc_3_Body = null;
                Additional_Doc_3_Name = null;
                Add_Doc3_FileSize = null;
            }
            else{
                system.debug(Add_Doc3_FileSize + 'Add_Doc3_FileSize');
                system.debug(Additional_Doc_3_Name + 'Additional_Doc_3_Name');
            }*/
        }
        
    }

    if(nextPage == 'application_attachments') {
        if(!isDomestic){
            if(aw.how_many_hours_part_time__c == null){
                requiredf ='Yes';
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Other Details: How many hours you are expecting to work while you study is required.'));
            }
            if(aw.Bringing_dependents__c == null){
                requiredf ='Yes';
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Other Details: Are you planning to bring dependents to the UK is required.'));
            }
            if(aw.Any_close_relatives_in_UK__c == null){
                requiredf ='Yes';
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Other Details: Any close relatives in UK is required.'));
            }
            else if(aw.Any_close_relatives_in_UK__c =='Yes' && aw.relatives_contact_details_in_UK__c ==null ){
                requiredf ='Yes';
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Other Details: Address of close relatives is required.'));
            }
            if(aw.Planning_to_stay_with_relatives_in_uk__c == null){
                requiredf ='Yes';
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Other Details: Planning to stay with relatives in the UK is required.'));
            }
            else if(aw.Planning_to_stay_with_relatives_in_uk__c =='Yes' && aw.duration_of_stay_with_relatives__c ==null ){
                requiredf ='Yes';
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Other Details: Address of relatives/friends where you plan to stay is required.'));
            }
            if(aw.staying_in_UK_after_course__c == null){
                requiredf ='Yes';
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Other Details: Planning to stay in the UK after course completion is required.'));
            }
            if(aw.future_job__c == null ){
                requiredf ='Yes';
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Other Details: Kind of job you would be looking for after course completion is required.'));
            }
            else if(aw.future_job__c.length() > 255){
                requiredf ='Yes';
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Other Details: Kind of job you would be looking for after course completion is limited to 255 characters.'));
            }
        } 
        if(aw.Any_criminal_convictions__c == null ){
            requiredf ='Yes';
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Other Details: Do you have any criminal convictions is required.'));
        }       
        else if(aw.Any_criminal_convictions__c=='Yes' && aw.Criminal_conviction_details__c ==null ){
            requiredf ='Yes';
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Other Details: Details related to criminal conviction are required.'));
        }
        if(aw.Any_Learning_Requirements__c == null ){
            requiredf ='Yes';
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Other Details: Do you have any learning requirements is required.'));
        }
        else if(aw.Any_Learning_Requirements__c =='Yes' && aw.SFDC_Select_Disability_Status_Code__c == null ){
            requiredf ='Yes';
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Other Details: Please specify the learning requirement.'));
        }
        
        if(!isDomestic) {
            if(aw != null && aw.kin_name__c == null) {
                requiredf ='Yes';
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Other Details: Next of Kin name is required.'));
            }
            
            if(aw != null && aw.kin_address_line1__c == null) {
                requiredf ='Yes';
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Other Details: Next of Kin address line 1 is required.'));
            }
            
            if(aw != null && aw.kin_city__c == null) {
                requiredf ='Yes';
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Other Details: Next of Kin city is required.'));
            }
            
            if(aw != null && aw.kin_country__c == null) {
                requiredf ='Yes';
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Other Details: Next of Kin country is required.'));
            }
            
            if(aw != null && aw.kin_contact_telephone__c == null) {
                requiredf ='Yes';
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Other Details: Next of Kin telephone is required.'));
            }
             
            if(aw != null && aw.kin_email__c == null) {
                requiredf ='Yes';
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Other Details: Next of Kin email is required.'));
            }
            if(aw != null && aw.kin_postcode__c == null) {
                requiredf ='Yes';
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Other Details: Next of Kin post code is required.'));
            }
        }
    }
    system.debug(requiredf+'91100000'); 
    if(requiredf == 'Yes'){
        ACCABody = null;
                        ACCAName = null;
                        ACCAFileSize = null;
                        PassportBody = null;
                PassportName = null;
                PassportFileSize = null;
                VisaBody = null;
                VisaName = null;
                VisaFileSize = null;
                AcademicBody = null;
                AcademicName = null;
                AcademicFileSize = null;
                EnglishBody = null;
                EnglishName = null;
                EnglishTestFileSize=null;
                ReferencesBody = null;
                ReferencesName = null;
                ReferenceFileSize = null;
        AttendanceBody = null;
                AttendanceName = null;
                AttendanceFileSize = null;
                VisaRefusalBody = null;
                VisaRefusalName = null;
                VisaRefusalFileSize = null;
                UKVisaHistoryName = null;
                UKVisaHistoryBody = null;
                UKVisaHistoryFileSize = null;       
                Additional_Doc_1_Body = null;
                Additional_Doc_1_Name = null;
                Add_Doc1_FileSize = null;
                Additional_Doc_2_Body = null;
                Additional_Doc_2_Name = null;
                Add_Doc2_FileSize = null;
                Additional_Doc_3_Body = null;
                Additional_Doc_3_Name = null;
                Add_Doc3_FileSize = null;
    }
    if(requiredf =='NO') {          
        if(nextPage == 'application_submit') { 
            if(PassportName != null) {
                system.debug('911111'); 
                PassportName = PassportName.substringBefore('.') + '_Passport' + '.' + PassportName.substringAfter('.');
                PassportUploadFile();
                aw.Passport_File_Name__c = PassportName;
                aw.Passport_date_expected__c = null;
                aw.Passport_Copy_Uploaded__c = true; 
            } 
            
            if(AcademicName != null) {
                AcademicName = AcademicName.substringBefore('.') + '_Academic_cert' + '.' + AcademicName.substringAfter('.');
                AcademicUploadFile();
                aw.Academic_File_Name__c = AcademicName;
                aw.Academic_date_expected__c = null;
                aw.Academic_uploaded__c = true;
            }
    
            if(EnglishName != null) {
                EnglishName = EnglishName.substringBefore('.') + '_Eng_Lang' + '.' + EnglishName.substringAfter('.');
                EnglishUploadFile();
                aw.English_Lang_File_Name__c = EnglishName;
                aw.English_date_expected__c = null;
                aw.English_Test_uploaded__c = true;
            }
    
            if(ReferencesName != null) {
                ReferencesName = ReferencesName.substringBefore('.') + '_Reference' + '.' + ReferencesName.substringAfter('.');
                ReferencesUploadFile();
                aw.References_File_Name__c = ReferencesName; 
                aw.References_date_expected__c = null;
                aw.References_uploaded__c = true;
            }
    
            if(ACCAName != null) {
                ACCAName = ACCAName.substringBefore('.') + '_ACCA' + '.' + ACCAName.substringAfter('.');
                ACCAUploadFile();                
                aw.ACCA_File_Name__c = ACCAName;
                aw.ACCA_date_expected__c = null;
                aw.ACCA_card_uploaded__c = true;
            }
    
            if(!isDomestic) {
                if(VisaName != null) {
                    VisaName = VisaName.substringBefore('.') + '_Visa' + '.' + VisaName.substringAfter('.');
                    VisaUploadFile();
                    aw.Visa_File_Name__c = VisaName;
                    aw.Visa_date_expected__c = null;
                    aw.Visa_copy_uploaded__c = true;
                }
                
                if(AttendanceName != null) {
                    AttendanceName = AttendanceName.substringBefore('.') + '_Attendence' + '.' + AttendanceName.substringAfter('.');
                    AttendanceUploadFile();
                    aw.Attendence_Record_file_Name__c = AttendanceName;
                    aw.Attendance_date_expected__c = null;
                    aw.Attendance_record_uploaded__c = true;
                }
                
                if(VisaRefusalName != null) {
                    VisaRefusalName = VisaRefusalName.substringBefore('.') + '_VisaRefusal' + '.' + VisaRefusalName.substringAfter('.');
                    VisaRefusalUploadFile();
                    aw.Visa_Refusal_Copy_File_Name__c = VisaRefusalName;
                    aw.Visa_Refusal_date_expected__c = null;
                    aw.Visa_refusal_copy_uploaded__c = true;
                }
                
                if(UKVisaHistoryName != null) {
                    UKVisaHistoryName = UKVisaHistoryName.substringBefore('.') + '_UKVisaHistory' + '.' + UKVisaHistoryName.substringAfter('.');
                    UKVisaHistoryUploadFile();
                    aw.UK_Visa_History_File_Name__c = UKVisaHistoryName;
                    aw.UK_Visa_History_date_expected__c = null;
                    aw.UK_Visa_History_uploaded__c = true;
                }
            }
            
            if(Additional_Doc_1_Name != null) {
                Additional_Doc_1_Name = Additional_Doc_1_Name.substringBefore('.') + '_Other_1' + '.' + Additional_Doc_1_Name.substringAfter('.');
                AdditionalDoc1UploadFile();
                aw.Additional_Doc_1_File_Name__c = Additional_Doc_1_Name;
            }
            
            if(Additional_Doc_2_Name != null) {
                Additional_Doc_2_Name = Additional_Doc_2_Name.substringBefore('.') + '_Other_2' + '.' + Additional_Doc_2_Name.substringAfter('.');
                AdditionalDoc2UploadFile();
                aw.Additional_Doc_2_File_Name__c = Additional_Doc_2_Name;
            }
            
            if(Additional_Doc_3_Name != null) {
                Additional_Doc_3_Name = Additional_Doc_3_Name.substringBefore('.') + '_Other_3' + '.' + Additional_Doc_3_Name.substringAfter('.');
                AdditionalDoc3UploadFile();
                aw.Additional_Doc_3_File_Name__c = Additional_Doc_3_Name;
            }
            
            Database.upsert(aw);    
        }
        
        if(nextPage == 'application_international_history') {
            Database.upsert(aw);
        }   
        
        if(nextPage == 'application_other_details') {
            aw.Course_Section_Complete__c = 'Yes';
            aw.Immigration_History_Complete__c = 'Yes';
            Database.upsert(visalist);
            Database.upsert(aw);
        } 
        
        if(nextPage == 'application_attachments') {
            aw.General_Information_Complete__c = 'Yes';
            aw.Other_Information_Complete__c = 'Yes';
            aw.next_of_kin_section_complete__c = 'Yes';
            Database.upsert(aw);
        } 
        if(nextPage == 'application_references_personal')  
            Database.upsert(employment); 
            pr = new PageReference('/apex/'+nextPage+'?wiz_id='+wiz_id+'&auth_id='+auth_id);
       
            pr.setRedirect(true); 
        } else {   
            pr= null;
        }  
      return pr;
  }
  
   
  // Previous page routine
    public pageReference prev() { 
        //update the database and get the id for the record we insert
         //  Database.UpsertResult upsertResults = Database.upsert(acc); 
        //   string  ID = upsertResults.Id;
        PageReference pr = null;
        if(wiz_id !=null && auth_id!= null && prevPage!=null ){
            system.debug('prevPageprevPageprevPage '+ prevPage);
            pr = new PageReference('/apex/'+prevPage+'?wiz_id='+wiz_id+'&auth_id='+auth_id);
            //pr = new PageReference('/apex/'+Document.  nextPageURl);
            pr.setRedirect(true);
        }
        else{
            errorMessage('here '+wiz_id+'auth '+auth_id+'prev '+prevPage);
        }
      return pr;
        
  }
  
  // Previous page routine
    public pageReference prev1() { 
         PageReference pr;
        if(prevPage!=null){
        system.debug('prevPageprevPageprevPage '+ prevPage);
        pr = new PageReference('/apex/application_submit?wiz_id='+wiz_id+'&auth_id='+auth_id);
        pr.setRedirect(true);
        }
        else{
            pr = null;
        }
      return pr;
  }
  
  // page 2 save routine it upserts the application wizard object
  public pageReference save() {
   PageReference pr;
   //aw.Location__c=listlocation;
   //aw.Programme__c=listprogramme;
   //aw.Mode__c=listmodes;
   //aw.course_year__c=decimal.valueof(progYear);
   //aw.Month__c=listmonths;
   
/*
   Web_Course_Offering__c wcoid ;
   if ([SELECT count() FROM Web_Course_Offering__c WHERE campus__c =:listlocation AND Programme__c = :listprogramme AND Mode__c = :listmodes AND 
                                                        start_year__c = :decimal.valueof(progYear) AND  start_month__c = :decimal.valueof(listmonths) limit 1] == 1) {   
       wcoid =[SELECT Id FROM Web_Course_Offering__c WHERE campus__c =:listlocation AND Programme__c = :listprogramme AND 
                                                Mode__c = :listmodes AND start_year__c = :decimal.valueof(progYear) AND  
                                                start_month__c = :decimal.valueof(listmonths) limit 1];
       aw.Web_Course_Offering__c = wcoid.Id;
   }
  */ 
    /*
    Integer days = null;
    Integer age = null;
    if(aw.Date_of_Birth__c != null){
        Integer days1 = aw.Date_of_Birth__c.daysBetween(Date.Today());
        age = Integer.valueOf(days1/365.2425);
    }
    */
    
        integer age = null;
        if(aw.Date_of_Birth__c != null){
            integer birthDateMonth = aw.Date_of_Birth__c.Month();
            integer birthDateDay   = aw.Date_of_Birth__c.day();
            
            integer DateMonth = Date.Today().Month();
            integer DateDay   = Date.Today().day();
            system.debug('---------------->'+system.today().day());
            Date personDateCalc = Date.newInstance(2000,birthDateMonth,birthDateDay);
            Date myDateCalc = Date.newInstance(2000,DateMonth,DateDay);
            system.debug('++++++++++++'+personDateCalc);
            system.debug('++++++++++++'+myDateCalc);
            system.debug('++++++++++++'+Date.Today().Year()+aw.Date_of_Birth__c.Year());
            if(personDateCalc <= myDateCalc){
                system.debug('=========1');
                age = Date.Today().Year() - aw.Date_of_Birth__c.Year();
            }else{
                system.debug('=========2');
                age = Date.Today().Year() - aw.Date_of_Birth__c.Year()-1;
            }
        }
    
    string requiredf ='NO';
    if( aw.Title__c == Null ) {
       requiredf ='Yes';
       ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Personal Details: Title is required'));
    } 
    
    if( aw.last_Name__c == Null ) {
       requiredf ='Yes';
       ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Personal Details: Surname/Family Name is required'));
    }  
    if( aw.First_name__c == Null ) {
       requiredf ='Yes';
       ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Personal Details: Fornames is required'));
    }     
    if( aw.Gender__c == Null ) {
       requiredf ='Yes';
       ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Personal Details: Gender is required'));
    }      
    if( aw.Date_of_Birth__c == Null ) {         
       requiredf ='Yes';
       ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Personal Details: Date of Birth is required'));
    }
    else if(age < 17){
        requiredf ='Yes';
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Personal Details: Age cannot be less than 17years')); 
        return null;           
    }
         
    
    if(aw.Ethnicity__c == Null ) {
       requiredf ='Yes';
       ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Personal Details: Ethnicity is required'));
    }
    
    if(aw.Address_Line_1__c == Null ) {
       requiredf ='Yes';
       ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Personal Details: Address Line 1 is required'));
    }
    
    if( aw.City__c == Null ) {
       requiredf ='Yes';
       ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Personal Details: Correspondence City is required'));
    }
    if( aw.country__c == Null ) {
       requiredf ='Yes';
       ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Personal Details: Correspondence Country is required'));
    }    
    if( aw.Postal_Code__c == Null ) {
       requiredf ='Yes';
       ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Personal Details: Correspondence Postcode is required'));
    }
      
    if( aw.Preferred_Telephone__c == Null ) {
       requiredf ='Yes';
       ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Personal Details: Preferred Telephone is required'));
    } 
             
    if( aw.telephone__c == Null ) {
       requiredf ='Yes';
       ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Personal Details: Main Contact telephone is required'));
    } 
        
    if( aw.telephone__c != Null )  { 
        string s = aw.telephone__c;
        String reg = '[\\+ 0-9()\\.\\-]{'+s.length()+'}';
        Pattern phonePattern = Pattern.compile(reg);
       
        Matcher phoneMatcher = phonePattern.matcher(s);   
        if(PhoneMatcher.matches() == false) {
           requiredf ='Yes';
           ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,phoneMatcher.matches()+s+' Personal Details: Main Contact telephone is INVALID'));
        }
    }
    
    if( aw.Email__c == Null ) {
       requiredf ='Yes';
       ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Personal Details: Email is required'));
    }  
    
    if( aw.Names_as_per_passport__c != True ) {
       requiredf ='Yes';
       ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Personal Details: Confirm that you have entered your names as they appear in your passport is required'));
    }  
    
    if( aw.EEA_citizen__c == '--None--' ) {
       requiredf ='Yes';
       ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Nationality: I am a citizen of the EEA or Switzerland is required'));
    }     
    if( aw.Country_of_birth__c == Null ) {
       requiredf ='Yes';
       ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Nationality: Country of Birth is required'));
    }    
    if( aw.Nationality__c == Null ) {
       requiredf ='Yes';
       ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Nationality: Nationality is required'));
    }    
    if( aw.Country_of_Domicile_Permanent_Residency__c == Null ) {
       requiredf ='Yes';
       ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Nationality: Country of Domicile Permanent Residency is required'));
    } 
    /*
    if(aw.EEA_citizen__c == 'No') { 
        if( aw.Date_of_arrival_in_the_UK__c == Null) {
            requiredf ='Yes';
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Nationality: Date of arrival in the UK is required'));
        }            
        
        if( aw.Date_of_Residency__c == Null ) {
            requiredf ='Yes';
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Nationality: Date of residency is required'));
        }
    }
    
    if( aw.Conditions_of_residency__c == Null ) {
        requiredf ='Yes';
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Nationality: Conditions of residency is required'));
    } 
    */
    if( aw.Do_you_have_indefinite_leave__c == Null ) {
       requiredf ='Yes';
       ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Nationality: Do you have indefinite leave to remain is required'));
    } 
        
        //Domestic vs. International logic: 'isDomestic' drives how the entire application appears 
    if(aw.EEA_citizen__c == 'Yes'){
        isDomestic = true;
        aw.App_Wiz_Student_Type__c = 'Domestic';
    }
    else if(aw.Do_you_have_indefinite_leave__c == 'Yes'){
        isDomestic = true;
        aw.App_Wiz_Student_Type__c = 'Domestic';
    }                    
    else{
        isDomestic = false;
        aw.App_Wiz_Student_Type__c = 'International';
    }                  
    if(requiredf =='NO') {          
      // update the database and get the id for the record we insert
          aw.Personal_Details_Complete__c = 'Yes';
          //Newly added.
          aw.Nationality_section_complete__c = 'Yes';
          Database.UpsertResult upsertResults = Database.upsert(aw); 
          System.debug('****checking5***'+ aw);
          wiz_id = upsertResults.Id;
          if(upsertResults.Id != null) {
              personDetails = 'Yes';
          }
           
          System.debug('***checking6***'+isDomestic );
          pr = new PageReference('/apex/application_course_selection?wiz_id='+wiz_id+'&auth_id='+auth_id);      
          
          pr.setRedirect(true); 
    } else {    
        pr= null;
    }          
    return pr;
  }

 // page 7 save routine it upserts the application wizard object and srends a email with pdf to the applicant submitapp
  public pageReference submitapp() { 
    string requiredf ='NO';
    
    if(!aw.Correct_Information__c) {
        requiredf ='Yes';
       ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'You must check the Correct information checkbox.'));
    }
    if(requiredf =='NO') {
        aw.ready_for_extract__c=true;
        // update the database and get the id for the record we insert
        Database.UpsertResult upsertResults = Database.upsert(aw); 
        wiz_id = upsertResults.Id;
        return submitapp1();
        //PageReference pr =  new PageReference('/apex/application_summary'+'?wiz_id='+wiz_id);
        //pr.setRedirect(true); 
        //return pr;
    } else {
        return null;
    }    
  } 
     
  public pageReference submitapp1() { 
      Direct_app_assign__c daa = [select Id, IsDeleted, Name, SetupOwnerId, CreatedDate, CreatedById, LastModifiedDate, 
                                         LastModifiedById, SystemModstamp, User__c, Student_Type__c,email__c 
                                  from Direct_app_assign__c 
                                  WHERE name='International'];
      string intemail = daa.email__c;
      daa = [select Id, IsDeleted, Name, SetupOwnerId, CreatedDate, CreatedById, LastModifiedDate, LastModifiedById, 
                                SystemModstamp, User__c, Student_Type__c, email__c from Direct_app_assign__c WHERE name='Domestic'];
      string domemail = daa.email__c;
      string adminemail; 
      
      String [] toAddresses = new String[] {aw.Email__c};
      system.debug(aw.Email__c+'emTem1234');     
      // Reference the page
      PageReference pdf =  new PageReference('/apex/applicationwizPDF'+'?wiz_id='+wiz_id+'&auth_id='+auth_id);
      pdf.getParameters().put('p','p');
      Blob b;
      if(!aw.submitted__c)
        b = pdf.getContent();
      // Create an email
      Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
      //email.setSubject('From BPP Direct application System');
         
      //Call Account Owner Assignment method to match the routing rules
      ownerId = recordAssignment(aw.programme__c,aw.App_Wiz_Student_Type__c); 
      
      list<Account> lstPossAccs = [SELECT Id,FirstName,LastName,Phone,PersonEmail,PersonBirthDate,PersonMailingPostalCode 
                                   FROM Account
                                   WHERE (FirstName = : aw.First_name__c And LastName = : aw.last_Name__c) 
                                      OR Phone=: aw.telephone__c OR PersonEmail =: aw.Email__c 
                                      OR PersonBirthdate =: aw.Date_of_Birth__c OR PersonMailingPostalCode = :aw.Postal_Code__c];
      boolean oldAccount = false;
      string possibleAccId;
      for(Account temp:lstPossAccs){
        if(temp.FirstName == aw.First_name__c && temp.LastName == aw.last_Name__c && temp.PersonBirthdate == aw.Date_of_Birth__c && temp.PersonEmail == aw.Email__c){
            oldAccount = true;
            possibleAccId = temp.Id;
            Acc = temp;
            break;
        }
        if(temp.FirstName == aw.First_name__c && temp.LastName == aw.last_Name__c && temp.PersonBirthdate == aw.Date_of_Birth__c && temp.Phone == aw.telephone__c){
            oldAccount = true;
            possibleAccId = temp.Id;
            Acc = temp;
            break;
        }
        if(temp.PersonBirthdate == aw.Date_of_Birth__c && temp.Phone == aw.telephone__c && temp.PersonEmail == aw.Email__c){
            oldAccount = true;
            possibleAccId = temp.Id;
            Acc = temp;
            break;
        }
        if(temp.FirstName == aw.First_name__c && temp.LastName == aw.last_Name__c && temp.PersonMailingPostalCode == aw.Postal_Code__c && temp.PersonEmail == aw.Email__c){
            oldAccount = true;
            possibleAccId = temp.Id;
            Acc = temp;
            break;
        }
        if(temp.FirstName == aw.First_name__c && temp.LastName == aw.last_Name__c && temp.PersonMailingPostalCode == aw.Postal_Code__c && temp.Phone == aw.telephone__c){
            oldAccount = true;
            possibleAccId = temp.Id;
            Acc = temp;
            break;
        }
        if(temp.FirstName == aw.First_name__c && temp.LastName == aw.last_Name__c && temp.Phone == aw.telephone__c && temp.PersonEmail == aw.Email__c){
            oldAccount = true;
            possibleAccId = temp.Id;
            Acc = temp;
            break;
        }   
      }
           
      //Search for existing account
      /*if([SELECT count() FROM Account 
          WHERE FirstName = : aw.First_name__c AND LastName = : aw.last_Name__c 
                 AND Phone=: aw.telephone__c AND PersonEmail =: aw.Email__c 
                 AND PersonBirthdate =: aw.Date_of_Birth__c limit 1] == 1) {
        Acc = [SELECT Id FROM Account WHERE FirstName = : aw.First_name__c AND LastName = : aw.last_Name__c 
                        AND Phone=: aw.telephone__c AND PersonEmail =: aw.Email__c AND PersonBirthdate =: aw.Date_of_Birth__c limit 1];
        */
        if(oldAccount){           
        //If existing account is found, then update all account details         
        country_list__c country;
        Acc.recordtypeId = Schema.Sobjecttype.Account.getRecordTypeInfosByName().get('Student Account').getRecordTypeId();
        Acc.Student_Cycle__c = 'pursue'; 
        
        /* no longer setting owner or student type for exising accounts
        Acc.OwnerId = ownerId;
        if(isDomestic) 
            Acc.Student_Type__pc = 'Domestic';
        else
            Acc.Student_Type__pc = 'International';
        */
                
        //Personal Details**********************************
        Acc.Salutation = aw.Title__c;
        Acc.FirstName = aw.First_name__c;
        Acc.LastName = aw.last_Name__c;
        Acc.Gender__pc = aw.Gender__c;
        Acc.SFDC_Select_Ethnic_Code__pc = aw.Ethnicity__c; //Mapping to legacy field for now
        //Acc.SFDC_Ethnic_Code_Select__pc = aw.Ethnicity__c; //Populates the SIS Field with Ethnicity value
        system.debug('ACCCCCCC' + Acc);    
        Acc.Domicile__pc = aw.Domicile__c;            
        Acc.PersonBirthdate = aw.Date_of_Birth__c;
        
        //Address moved to maptoAddress account
        
        Acc.telephone__c = aw.telephone__c;     //Main contact telephone
        
        Acc.Preferred_Phone__pc = aw.Preferred_Telephone__c;
        
        if(aw.Preferred_Telephone__c == 'Home') { Acc.PersonHomePhone = aw.telephone__c; }
        if(aw.Preferred_Telephone__c == 'Work') { Acc.Work_Phone__pc = aw.telephone__c; }
        if(aw.Preferred_Telephone__c == 'Mobile') { Acc.PersonMobilePhone = aw.telephone__c; }
        if(aw.Preferred_Telephone__c == 'Other') { Acc.PersonOtherPhone = aw.telephone__c; }            
        //Acc.PersonEmail = aw.Email__c;
        Acc.Preferred_Email__pc = 'Personal';
        Acc.Personal_Email__pc = aw.Email__c;
        
        if(aw.Marketing_Opt_Out__c == True) {
            Acc.PersonHasOptedOutOfEmail = True;
            Acc.No_Mail_Hardcopy__pc = True;
            Acc.No_Phone__pc = True;
            Acc.No_SMS__pc = True;
        }
        else {
            Acc.PersonHasOptedOutOfEmail = False;
            Acc.No_Mail_Hardcopy__pc = False;
            Acc.No_Phone__pc = False;
            Acc.No_SMS__pc = False;
        }
        
        //Nationality**********************************
        Acc.EEA_citizen__c = aw.EEA_citizen__c;     //I am a citizen of the EEA: 
        if(aw.Country_of_birth__c != null) {
            country = [SELECT Id, Name FROM country_list__c where Id = : aw.Country_of_birth__c];
            if(country != null){ Acc.Country_of_Birth__pc = country.Name; }        
        }
        if(aw.Nationality__c != null) {
            country = [SELECT Id, Name FROM country_list__c where Id = : aw.Nationality__c];
            if(country != null){ Acc.Nationality__pc = country.Name; }     
        }
        if(aw.Country_of_Domicile_Permanent_Residency__c != null) {
            country = [SELECT Id, Name FROM country_list__c where Id = : aw.Country_of_Domicile_Permanent_Residency__c];
            if(country != null){ Acc.Country_of_Residence__pc = country.Name; }    
        }
        Acc.UK_First_Entry_Date__pc = aw.Date_of_arrival_in_the_UK__c;
        Acc.UK_Permanent_Residence_Date__pc = aw.Date_of_Residency__c;
        Acc.Conditions_of_residency__c = aw.Conditions_of_residency__c;     //Conditions of residence: 
        if(aw.Do_you_have_indefinite_leave__c == 'Yes') { Acc.Visa_Type__pc = 'Indefinite Leave to Remain'; }
    
        //Language**********************************
        Acc.First_Language__pc = aw.is_english_your_first_language__c;      //Is English your first language?: 
        Acc.Minimum_1_Year_Post_Education__c = aw.Minimum_1_Year_Post_Education__c;
        Acc.Language_Test_Type__pc = aw.eng_exam_type__c;       //Exam type: 
        Acc.eng_exam_type_other__c = aw.eng_exam_type_other__c;
        Acc.Eng_Exam_Date__c = aw.Eng_Exam_Date__c;
        Acc.Exam_Result__c = aw.eng_exam_result__c;     //Exam result: 
        
        //Financial Capacity**********************************
        Acc.Annual_Family_Income__pc = aw.Annual_Income__c;
        Acc.Family_Members__pc = aw.number_of_family_members__c;
        Acc.Father_s_Occupation__pc = aw.father_occupation__c;
        Acc.Mother_s_Occupation__pc = aw.mother_occupation__c;
        Acc.Monthly_Expenses__pc = aw.monthly_expense_in_UK__c;
        Acc.Cash_on_Hand__c = aw.cash__c;     //How much money do you plan to carry with you when you first arrive in the UK?
    
        //Immigration History**********************************
        Acc.Currently_in_UK_with_a_Visa__c = aw.Are_you_currently_in_Uk_with_a_visa__c;     //Are you currently in the UK on a Visa?  Yes/No
        Acc.Ever_Studied_in_UK_Before__c = aw.ever_studied_in_UK_before__c;      //Have you ever studied in the UK before?  Yes/No
        //if(aw.Do_you_have_indefinite_leave__c != 'Yes') { Acc.Visa_Type__pc = aw.Current_Visa_Type__c; }
        //Acc.Other_Visa_Type__c = aw.Other_Visa_Type__c;     //Other Visa Type
        //Acc.Are_you_currently_studying_in_UK__c = aw.Are_you_currently_studying_in_UK__c;       //Are you currently studying in the UK?  Yes/No
        //Acc.Current_course_in_UK__c = aw.Current_course_in_UK__c;       //If yes, please give details
        Acc.Intend_to_apply_for_Student_Visa__c = aw.Intend_to_apply_for_Student_Via__c;        //Do you intend to apply for a Tier 4 student Visa in order to study at BPP?  Yes/No
        Acc.Type_of_Visa_intend_to_apply__c = aw.Type_of_Visa_intend_to_apply__c;               //If No, please explain
        //Acc.Most_recent_course_studied_in_UK__c = aw.Most_recent_course_studied_in_UK__c;       //If yes, please give details
        //Acc.Previously_Applied_for_Visa__pc = aw.Applied_fro_Student_Visa_before__c;
        Acc.Previously_Refused_for_Visa__pc = aw.Have_you_been_refused__c;
        Acc.Passport_Number__pc = aw.Passport_Number__c;
    
        //General Information**********************************
        Acc.Staying_With_Relatives__pc = aw.Planning_to_stay_with_relatives_in_uk__c;
        Acc.Staying_With_Relatives_Detail__pc = aw.duration_of_stay_with_relatives__c;
        
        //Future Plans**********************************
        Acc.Remain_in_Country__pc = aw.staying_in_UK_after_course__c;
        Acc.Job_Type_Graduation__pc = aw.future_job__c;
        
        //Other Information**********************************
        Acc.Criminal_Conviction__pc = aw.Any_criminal_convictions__c;
        Acc.Criminal_conviction_details__c = aw.Criminal_conviction_details__c;     //If yes, give details
        if(aw.Any_Learning_Requirements__c =='Yes') { Acc.Disability_Needs__pc = true; }
        else { Acc.Disability_Needs__pc = false; }   
        //Acc.Special_Needs_Disability_Support__pc = aw.Learning_Requirement_Details__c;      //If yes, give details
        Acc.SFDC_Select_Disability_Status_Code__pc = aw.SFDC_Select_Disability_Status_Code__c;
        
        //Next Of Kin********************************** Addresss
        Acc.kin_name__c = aw.kin_name__c;   //Name
        Acc.kin_contact_telephone__c = aw.kin_contact_telephone__c;     //Main contact  Telephone
        Acc.kin_email__c = aw.kin_email__c;     //Email
      
        //Attachments Expected Dates**********************************     
        Acc.Passport_Copy_Expected_Date__c = aw.Passport_date_expected__c;
        Acc.Academic_Cert_Expected_Date__c = aw.Academic_date_expected__c;
        Acc.English_Lang_Test_Expected_Date__c = aw.English_date_expected__c;
        Acc.References_Expected_Date__c = aw.References_date_expected__c;
        Acc.ACCA_Reg_Card_Expected_Date__c = aw.ACCA_date_expected__c;
        Acc.Visa_Copy_Expected_Date__c = aw.Visa_date_expected__c;
        Acc.Attendance_Record_Expected_Date__c = aw.Attendance_date_expected__c;
        Acc.Visa_Refusal_Copy_Expected_Date__c = aw.Visa_Refusal_date_expected__c;    
      
        //Update the account record
        update Acc;
        //Create an opportunity for this application and associate to the account
        if(!aw.submitted__c){
            CreateOpportunity();
            insert Opp; 
            oaa.Opportunity__c=Opp.id;
            Database.upsert(oaa);
        }                      
        
      } else { 
        //no matching account, so create a new account
        CreateAccount();
        insert Acc;    
        
        //Create an opportunity for this application and associate to the new account
        CreateOpportunity();
        insert Opp;
        Oaa.Opportunity__c=Opp.id;
        Database.upsert(Oaa);
      }
      system.debug(Opp.Id + 'here we are 111');
     
     Account aaa = [Select a.PersonContactId, a.ParentId, a.OwnerId, a.Id From Account a where a.Id = :Acc.Id limit 1];
     
     //Attach related list data
     mapEducationToQualification(aaa.PersonContactId);
     mapEmploymentOfAppToAccount(aaa.PersonContactId);
     mapReferencesOfApptoAccount(aaa.PersonContactId);
     mapVisasOfAppToAccount(aaa.PersonContactId);
     mapAttachmentsApptoAcc();     
     //create address related list
     mapAddressToAccount(Acc);
     
     //insert an Opportunity_Product__c record based on course instance
     addProductCatalogItem(Opp);
     
     //Attach the PDF to the aw record
     Attachment att = new Attachment();
     att.name  = aw.Id+'.pdf';
     att.ParentId = Oaa.Id;
     att.IsPrivate = False;
     att.ContentType ='.pdf';
     if(!aw.submitted__c)
        att.body = b;
     else
        att.body = Blob.valueof('abcd'); 
     att.description = 'application for rec id '+aw.Id;
     insert att;
     aw.submitted__c = true;
     aw.Submit_Application_Date__c = system.today();
     Database.upsert(aw);  
     
     //Send confirmation email to applicant
     //email.setToAddresses(toAddresses);
     string emailTemplate = null;
     if(isDomestic){
        emailTemplate = 'DA_Auto_Response_Template_Application_Submitted';
     }
     else{
        emailTemplate = 'DA_Auto_Response_Template_Application_Submitted_Intl';
     }
     EmailTemplate emTem = [Select  e.Name,e.Id,e.DeveloperName, e.Description From EmailTemplate e 
                                                where e.DeveloperName=:emailTemplate];
     
     //email.setPlainTextBody('Thanks for applying to BPP.  A member of our admissions team will be in touch with you shortly.');
     //email.setHtmlBody('<p>Thanks for applying to BPP. <br/>A member of our admissions team will be in touch with you shortly.</p>');
     OrgWideEmailAddress[] owea = [select Id from OrgWideEmailAddress where Address = 'bppenquiriesteam@bpp.com'];
     if ( owea.size() > 0 ) {
        email.setOrgWideEmailAddressId(owea[0].Id);
     }
     system.debug('email.setOrgwideemail123098');
     email.setEmailPriority('High');
     email.setSaveAsActivity(false); 
     email.setTargetObjectId(aaa.PersonContactId);
     email.setTemplateId(emTem.Id);
     email.setWhatId(Opp.Id);//wiz_id before we provided it
     system.debug(emTem.DeveloperName+'emTem1234');
     
     //Create an email attachment
     Messaging.EmailFileAttachment efa = new Messaging.EmailFileAttachment();
     efa.setFileName('BPP_Application.pdf'); 
     efa.setBody(b); //attach the PDF
     email.setFileAttachments(new Messaging.EmailFileAttachment[] {efa});
     // send it, ignoring any errors (bad!)
     if (!Test.isRunningTest()){
        try {
           Messaging.SendEmailResult [] r = Messaging.sendEmail(new Messaging.SingleEmailMessage[] {email});       
        }
        catch(Exception e){
           system.debug(e + 'Send email');
        }
     }
               
     PageReference pr = new PageReference('/apex/application_completed?wiz_id='+wiz_id+'&auth_id='+auth_id);
     //PageReference pr =  new PageReference('/apex/application_summary'+'?wiz_id='+wiz_id);
     pr.setRedirect(true); 
     return pr;
  }
  
  Account Acc = new Account();
  Opportunity Opp = new Opportunity();
  Opportunity_Application_Attachment__c Oaa = new Opportunity_Application_Attachment__c();
  
  public string ownerId{get;set;}
  public string DomesticOwnerId{get;set;}
  public void CreateOpportunity() {
    //Opportunity Opp = new Opportunity();
    Opp.OwnerId = ownerId;
    system.debug(ownerId + 'program dapps');
    Opp.AccountId = Acc.Id;
    Opp.recordtypeId = Schema.Sobjecttype.Opportunity.getRecordTypeInfosByName().get('Application').getRecordTypeId();// '01220000000ce6t';
    Opp.Name = aw.First_name__c + '' + aw.last_Name__c;
    Opp.Cycle_Override__c = 'Use Student Cycle';
    Opp.StageName = 'Application';
    Opp.CloseDate = Date.Today();
    Opp.Application_Wizard_ID__c = wiz_id;
    //Opp.Application_Submit_Date__c = aw.Submit_Application_Date__c;
    Opp.Record_Source__c = 'Direct Apps';
    //Course details**********************************  
    Web_Course_Offering__c wco = [Select w.start_year__c, w.start_month__c, w.Programme__c, w.Mode__c, w.Id, w.Course_Instance_ID__c, w.Campus__c, w.Active__c 
                                    From Web_Course_Offering__c w
                                    where w.Mode__c = :aw.Mode__c and w.Campus__c = :aw.Location__c and w.Programme__c = :aw.programme__c
                                    and w.start_year__c = :integer.valueOf(aw.course_year__c) and w.start_month__c = :integer.valueOf(aw.month__c) limit 1];
    
    Opp.Course_Instance__c = wco.Course_Instance_ID__c;
    //Opp.Course_Instance__c = '01tP0000001Ibjh';
    //Opp.Course_Instance__c = '01tW0000000CCJ7';
    
    /*
    Do not need to set any of these values since they will be set automatically on the 
    Oppty based on the course instance
    
    Opp.course_year__c = aw.course_year__c;
    
    if(aw.Location__c != null) {
        Campus__c campus = [SELECT Name, Id FROM Campus__c WHERE Id = : aw.Location__c];
        if(campus != null)
                Opp.Location__c = campus.Name;
    }
    if(aw.Mode__c != null) {
        Mode__c Mode = [SELECT Name, Id FROM Mode__c WHERE Id = : aw.Mode__c];
        if(mode != null)
                Opp.Mode__c     = mode.Name;
    }
   */
    
    Opp.Modules__c = aw.Modules__c;  //for ACCA course modules
    
    //Academic References**********************************
    Opp.Personal_Statement_Body__c = aw.personal_statement__c;
    
    //Sponsorship**********************************
    Opp.Payment_Option__c = aw.Payment_Option__c;   //Who will be responsible for payment of your fees?
    Opp.Sponsoring_Organization__c = aw.Name_of_organisation__c;
    Opp.Sponsor_Name__c = aw.Authorising_name__c;
    Opp.Sponsoring_Purchase_Order__c = aw.Purchase_order_Number_where_necessary__c;
    Opp.Street_Address__c = aw.Street_Address__c; //Street address: 
    Opp.city__c = aw.sponsorCity__c;    //City: 
    if(aw.sponsorCountry__c != null) {
        country_list__c country = [SELECT Id, Name FROM country_list__c where Id = : aw.sponsorCountry__c];
        if(country != null)
                Opp.Country__c = country.Name;  
    }
    Opp.Postal_Code__c = aw.sponsorPostal_Code__c;
    Opp.Sponsor_Phone__c = aw.sponsorTelephone__c;
    Opp.Sponsor_Email__c = aw.sponsorEmail__c;
    
    //Course**********************************
    Opp.Similar_Course_Available__c = aw.Similar_course_in_other_country__c;
    Opp.Why_UK__c = aw.why_UK__c;    //If yes, why have you chosen to study in the UK
    Opp.Applied_to_Other_University__c = aw.Applied_to_Other_Universities__c;
    Opp.Other_University_Details__c = aw.Other_University_Details__c;       //If yes, please give details
    Opp.Hours_Per_Week_Study__c = aw.Hours_per_week__c;
    
    //General Information**********************************
    //Opp.expecting_to_work_part_time__c = aw.expecting_to_work_part_time__c;     //Are you expecting to work part time while you study?  Yes/No
    //Opp.how_many_hours_part_time__c = aw.how_many_hours_part_time__c;       //If Yes, how many hours
    Opp.Hours_Per_Week_Work__c = aw.how_many_hours_part_time__c;
    Opp.bringing_dependents__c = aw.bringing_dependents__c;     //Are you planning to bring dependents to the UK while studying? Yes/No
    Opp.Any_close_relatives_in_UK__c = aw.Any_close_relatives_in_UK__c;     //Do you have any close relatives in the UK? Yes/No
    Opp.relatives_contact_details_in_UK__c = aw.relatives_contact_details_in_UK__c;     //If yes, please specify address details and contact details
    
    //Final Comments**********************************
    Opp.How_did_you_hear_about_us__c = aw.How_did_you_hear_about_us__c;
    Opp.Other_Source__c = aw.Other_Source__c;       //Other details
    Opp.Agent_Name__c = aw.Agent_Name__c;
    Opp.Why_did_you_choose_to_study_with_us__c = aw.why_did_you_choose_to_study_with_us__c;
    Opp.Other_Details__c = aw.Other_Details__c;  
   
  }
  
  public void CreateAccount() { 
    //Account Acc = new Account();
    //Acc.Name = 'test';
    //Acc.Name = aw.First_name__c + '' + aw.last_Name__c;
    country_list__c country;
    Acc.OwnerId = ownerId;
    Acc.recordtypeId = Schema.Sobjecttype.Account.getRecordTypeInfosByName().get('Student Account').getRecordTypeId();
    if(isDomestic){ 
        Acc.Student_Type__pc = 'Domestic';
        //Acc.OwnerId = DomesticOwnerId;
    }
    else{
        Acc.Student_Type__pc = 'International';        
    }
    Acc.Student_Cycle__c = 'pursue';    
    
    //Personal Details**********************************
    Acc.PersonLeadSource = 'Direct Apps';
    Acc.Record_Source__pc = 'Direct Apps';
    Acc.Salutation = aw.Title__c;
    Acc.FirstName = aw.First_name__c;
    Acc.LastName = aw.last_Name__c;
    Acc.Gender__pc = aw.Gender__c;
    Acc.SFDC_Select_Ethnic_Code__pc = aw.Ethnicity__c; //Mapping to legacy field for now
    //Acc.SFDC_Ethnic_Code_Select__pc= aw.Ethnicity__c; //Populates the SIS Field with Ethnicity value
    system.debug('ACCCCCCC' + Acc);
    Acc.Domicile__pc = aw.Domicile__c;  
    Acc.PersonBirthdate = aw.Date_of_Birth__c;
    //pushed to map addressto account
    
    Acc.telephone__c = aw.telephone__c;     //Main contact telephone
    
    Acc.Preferred_Phone__pc = aw.Preferred_Telephone__c;
    
    if(aw.Preferred_Telephone__c == 'Home') {
        Acc.PersonHomePhone = aw.telephone__c;
    }
    if(aw.Preferred_Telephone__c == 'Work') {
        Acc.Work_Phone__pc = aw.telephone__c;
    }
    if(aw.Preferred_Telephone__c == 'Mobile') {
        Acc.PersonMobilePhone = aw.telephone__c;
    }
    if(aw.Preferred_Telephone__c == 'Other') {
        Acc.PersonOtherPhone = aw.telephone__c;
    }
        
    //Acc.PersonEmail = aw.Email__c;
    Acc.Preferred_Email__pc = 'Personal';
    Acc.Personal_Email__pc = aw.Email__c;
    
    if(aw.Marketing_Opt_Out__c == True) {
            Acc.PersonHasOptedOutOfEmail = True;
            Acc.No_Mail_Hardcopy__pc = True;
            Acc.No_Phone__pc = True;
            Acc.No_SMS__pc = True;
    }
    else {
            Acc.PersonHasOptedOutOfEmail = False;
            Acc.No_Mail_Hardcopy__pc = False;
            Acc.No_Phone__pc = False;
            Acc.No_SMS__pc = False;
    }
        
    //Nationality**********************************
    Acc.EEA_citizen__c = aw.EEA_citizen__c;     //I am a citizen of the EEA: 
    if(aw.Country_of_birth__c != null) {
        country = [SELECT Id, Name FROM country_list__c where Id = : aw.Country_of_birth__c];
        if(country != null)
                Acc.Country_of_Birth__pc = country.Name;        
    }
    if(aw.Nationality__c != null) {
        country = [SELECT Id, Name FROM country_list__c where Id = : aw.Nationality__c];
        if(country != null)
                Acc.Nationality__pc = country.Name;     
    }
    if(aw.Country_of_Domicile_Permanent_Residency__c != null) {
        country = [SELECT Id, Name FROM country_list__c where Id = : aw.Country_of_Domicile_Permanent_Residency__c];
        if(country != null)
                Acc.Country_of_Residence__pc = country.Name;    
    }
    Acc.UK_First_Entry_Date__pc = aw.Date_of_arrival_in_the_UK__c;
    Acc.UK_Permanent_Residence_Date__pc = aw.Date_of_Residency__c;
    Acc.Conditions_of_residency__c = aw.Conditions_of_residency__c;     //Conditions of residence: 
    if(aw.Do_you_have_indefinite_leave__c == 'Yes') {
        Acc.Visa_Type__pc = 'Indefinite Leave to Remain';
    }
    
    //Language**********************************
    Acc.First_Language__pc = aw.is_english_your_first_language__c;      //Is English your first language?: 
    Acc.Minimum_1_Year_Post_Education__c = aw.Minimum_1_Year_Post_Education__c;
    Acc.Language_Test_Type__pc = aw.eng_exam_type__c;       //Exam type: 
    Acc.eng_exam_type_other__c = aw.eng_exam_type_other__c;
    Acc.Eng_Exam_Date__c = aw.Eng_Exam_Date__c;
    Acc.Exam_Result__c = aw.eng_exam_result__c;     //Exam result: 
    
    //Financial Capacity**********************************
    Acc.Annual_Family_Income__pc = aw.Annual_Income__c;
    Acc.Family_Members__pc = aw.number_of_family_members__c;
    Acc.Father_s_Occupation__pc = aw.father_occupation__c;
    Acc.Mother_s_Occupation__pc = aw.mother_occupation__c;
    Acc.Monthly_Expenses__pc = aw.monthly_expense_in_UK__c;
    Acc.Cash_on_Hand__c = aw.cash__c;     //How much money do you plan to carry with you when you first arrive in the UK?
    
    //Immigration History**********************************
    Acc.Currently_in_UK_with_a_Visa__c = aw.Are_you_currently_in_Uk_with_a_visa__c;     //Are you currently in the UK on a Visa?  Yes/No
    Acc.Ever_Studied_in_UK_Before__c = aw.ever_studied_in_UK_before__c;      //Have you ever studied in the UK before?  Yes/No
    //if(aw.Do_you_have_indefinite_leave__c != 'Yes') { Acc.Visa_Type__pc = aw.Current_Visa_Type__c; }
    //Acc.Other_Visa_Type__c = aw.Other_Visa_Type__c;     //Other Visa Type
    //Acc.Are_you_currently_studying_in_UK__c = aw.Are_you_currently_studying_in_UK__c;       //Are you currently studying in the UK?  Yes/No
    //Acc.Current_course_in_UK__c = aw.Current_course_in_UK__c;       //If yes, please give details
    Acc.Intend_to_apply_for_Student_Visa__c = aw.Intend_to_apply_for_Student_Via__c;        //Do you intend to apply for a Tier 4 student Visa in order to study at BPP?  Yes/No
    Acc.Type_of_Visa_intend_to_apply__c = aw.Type_of_Visa_intend_to_apply__c;               //If No, please explain
    //Acc.Most_recent_course_studied_in_UK__c = aw.Most_recent_course_studied_in_UK__c;       //If yes, please give details
    //Acc.Previously_Applied_for_Visa__pc = aw.Applied_fro_Student_Visa_before__c;
    Acc.Previously_Refused_for_Visa__pc = aw.Have_you_been_refused__c;
    Acc.Passport_Number__pc = aw.Passport_Number__c;
    
    //General Information**********************************
    Acc.Staying_With_Relatives__pc = aw.Planning_to_stay_with_relatives_in_uk__c;
    Acc.Staying_With_Relatives_Detail__pc = aw.duration_of_stay_with_relatives__c;
    
    //Future Plans**********************************
    Acc.Remain_in_Country__pc = aw.staying_in_UK_after_course__c;
    Acc.Job_Type_Graduation__pc = aw.future_job__c;
    
    //Other Information**********************************
    Acc.Criminal_Conviction__pc = aw.Any_criminal_convictions__c;
    Acc.Criminal_conviction_details__c = aw.Criminal_conviction_details__c;     //If yes, give details
    if(aw.Any_Learning_Requirements__c =='Yes')
        Acc.Disability_Needs__pc = true;
    else
            Acc.Disability_Needs__pc = false;   
    //Acc.Special_Needs_Disability_Support__pc = aw.Learning_Requirement_Details__c;      //If yes, give details
    Acc.SFDC_Select_Disability_Status_Code__pc = aw.SFDC_Select_Disability_Status_Code__c;
    
    //Next Of Kin********************************** pushed to map address to account
    Acc.kin_name__c = aw.kin_name__c;   //Name
   
    Acc.kin_contact_telephone__c = aw.kin_contact_telephone__c;     //Main contact  Telephone
    Acc.kin_email__c = aw.kin_email__c;     //Email
    
    //Attachments Expected Dates**********************************     
    Acc.Passport_Copy_Expected_Date__c = aw.Passport_date_expected__c;
    Acc.Academic_Cert_Expected_Date__c = aw.Academic_date_expected__c;
    Acc.English_Lang_Test_Expected_Date__c = aw.English_date_expected__c;
    Acc.References_Expected_Date__c = aw.References_date_expected__c;
    Acc.ACCA_Reg_Card_Expected_Date__c = aw.ACCA_date_expected__c;
    Acc.Visa_Copy_Expected_Date__c = aw.Visa_date_expected__c;
    Acc.Attendance_Record_Expected_Date__c = aw.Attendance_date_expected__c;
    Acc.Visa_Refusal_Copy_Expected_Date__c = aw.Visa_Refusal_date_expected__c;    
  }
  
  //specilaized getters and setters for cascading pick lists
    // String value for the listlocation 
    public String listlocation;

    // String value for the listprogramme 
    public String listprogramme;
    
    // String value for the listmodes 
    public String listmodes;
    
    // String value for the listmonths 
    public String listmonths;
    //program year 
    public string progYear;
    
    //Getter for the program year value
    public String getProgYear() {    
        return progYear; 
    }
    
    // Setter for the program year value 
    public void setProgYear(String s) { this.progYear = s; }    
    
    //Getter for the listmodes value
    public String getListmonths() {
        return this.listmonths; 
    }
    
    // Setter for the listmonths value 
    public void setListmonths(String s) { this.listmonths = s; }  
    
    //Getter for the listmodes value
    public String getListmodes() {    
            return this.listmodes; 
    }
    
    // Setter for the listmodes value 
    public void setListmodes(String s) { this.listmodes = s; }
    
    // Getter for the listlocation value 
    public String getListlocation() {  
        return this.listlocation; 
    }
    
    // Setter for the listlocation value 
    public void setListlocation(String s) { this.listlocation = s; }

    // Getter for the listprogramme value 
    public String getListprogramme() { 
        //defaults      
        return this.listprogramme; 
    }
    
    //Setter for the listprogramme value
    public void setListprogramme(String s) { this.listprogramme = s; }
  
 //list methods 
 public List<SelectOption> getLocations() {
    List<SelectOption> optionList = new List<SelectOption>();
    optionList.add(new SelectOption('','Please select')); 
    if(listmodes != NULL) {
        map<string, string> loclist = new map<string, string>();
        for (Web_Course_Offering__c li : [SELECT Id, Campus__r.Display_Name__c, Campus__c, start_year__c, start_date__c 
                                          FROM Web_Course_Offering__c   
                                          WHERE Active__c = True AND Campus__c != Null AND programme__c = :listprogramme 
                                          AND Mode__c = :listmodes]){//AND start_year__c =:decimal.ValueOf(progYear)
            if(li.start_date__c >= (date.today()))
                loclist.put(li.campus__c, li.Campus__r.Display_Name__c);
        }
        for (string lockey: loclist.keySet()){    
            optionList.add(new SelectOption(lockey, loclist.get(lockey) ));
        }
        if(OptionList.size() < 2 ){
            optionList.add(new SelectOption('0','No Available Courses')); 
        }
    }
    return optionList;
}  

public List<SelectOption> getYesNo() {
      List<SelectOption> optionList = new List<SelectOption>();
      optionList.add(new SelectOption('--None--','--None--'));
      optionList.add(new SelectOption('Yes','Yes'));
      optionList.add(new SelectOption('No','No'));
      return optionList;
  } 
   
public List<SelectOption> getNoYes() {
      List<SelectOption> optionList = new List<SelectOption>();
      optionList.add(new SelectOption('No','No'));
      optionList.add(new SelectOption('Yes','Yes'));
      return optionList;
  } 

 // list of Programmes
 public List<SelectOption> getProgrammes() {
      List<SelectOption> optionList = new List<SelectOption>();
      optionList.add(new SelectOption('','Please select'));
      //if(listlocation != NULL && progYear != Null) {
     list<Web_Course_Offering__c> wco = [SELECT Id, programme__c, start_date__c, start_month__c, Start_year__c, Start_day__c 
                                           FROM Web_Course_Offering__c 
                                          WHERE Active__c = True AND start_month__c !=null AND Course_Instance_Id__c !=null
                                          AND Course_Instance_Id__r.Product_Type__c = 'OFFERING'
                                          order BY programme__c];    
     set<string> progIds = new set<string>();
     for(Web_Course_Offering__c tempWCO : wco){
        if(tempWCO.start_date__c >= (date.today()))
            progIds.add(tempWCO.programme__c);
     }
     programlist = [SELECT Id, Name, Description__c FROM Programme__c where id in :progIds order by Name];
            
     // WHERE ID in :limitprograms(listlocation)
     for (Programme__c li : programlist ){        
        optionList.add(new SelectOption(li.id, li.name));
     } 
     // }
     return optionList;
  }
  
  public List<SelectOption> getModes() {
      List<SelectOption> optionList = new List<SelectOption>();
      optionList.add(new SelectOption('','Please select'));
      if(listprogramme != NULL) {
      //if(listlocation != NULL && listprogramme != NULL && progYear != Null) {
          modelist = [SELECT  Id, Name FROM Mode__c WHERE ID in :limitmodes('campus', listprogramme)];  
          for (Mode__c li : modelist ){        
              optionList.add(new SelectOption(li.id, li.name));
          }
      }
      return optionList;
  } 
  public string teststr{get;set;}
  
  public void Checkmonth() {
        getMonthss();
  }
  
   public List<SelectOption> getMonthss() {
      List<SelectOption> optionList = new List<SelectOption>();
      optionList.add(new SelectOption('','Please select'));
      map<string,string> mlist = new map<string,string>();
      mlist.put('1','January');
      mlist.put('2','February');
      mlist.put('3','March');
      mlist.put('4','April');
      mlist.put('5','May');
      mlist.put('6','June');
      mlist.put('7','July');
      mlist.put('8','August');
      mlist.put('9','September');
      mlist.put('10','October');
      mlist.put('11','November');
      mlist.put('12','December');
     // if(progYear== Null) {progYear='2011';}
      if(listmodes != NULL && progYear != Null) { 
         for (Web_Course_Offering__c li : [SELECT Id, start_date__c, start_month__c, Start_year__c, Start_day__c 
                                           FROM Web_Course_Offering__c 
                                           WHERE start_year__c = :decimal.valueOf(progYear) AND Active__c = True AND 
                                           Campus__c= :listlocation AND programme__c = :listprogramme AND Mode__c = :listmodes AND 
                                           start_month__c!=0 AND start_month__c !=null ORDER BY start_month__c ]){       
             teststr =progYear;
             if(li.start_date__c >= (date.today())) {    
                  optionList.add(new SelectOption(''+integer.valueOf(li.start_month__c), mlist.get(''+integer.valueOf(li.start_month__c)) ));
             }       
         }
      } 
      return optionList;
  } 
  
    // business methods
  
   //limit ids for the programs based on campus id
      //limit ids for the programs based on campus id
 /* public list <string> limitprograms(string campus) {
      list <string> ids = new  list <string>() ;
      for(Web_Course_Offering__c wc: [SELECT Id, Programme__c, Mode__c, Campus__c, Intake_Month__c, Redirect_URL__c, 
                                             Redirect_Enabled__c, Active__c 
                                        FROM Web_Course_Offering__c 
                                       WHERE Active__c = True AND Campus__c= :campus AND start_year__c= :decimal.valueof(progYear)]){
          ids.add(wc.Programme__c);
      }
      return ids;
  }*/
  
  public list <string> limitmodes(string campus, string programmes) {
      list <string> ids = new  list <string>() ;
      // WHERE Active__c = True AND Campus__c = :campus AND Programme__c = :programmes 
      // AND start_year__c= :decimal.valueof(progYear)
      for(Web_Course_Offering__c wc: [SELECT Id, Programme__c, Mode__c, Campus__c, Intake_Month__c, Redirect_URL__c, 
                                             Redirect_Enabled__c, Active__c 
                                        FROM Web_Course_Offering__c                                                                    
                                       WHERE Active__c = True AND Programme__c = :programmes]){
          ids.add(wc.mode__c);
      }
      return ids;
  }
 
  public List<SelectOption> getCountrys() {
      List<SelectOption> optionList = new List<SelectOption>();      
      for (country_list__c li : countrylist ){        
          optionList.add(new SelectOption(li.id, li.name));
      }
      return optionList;
  }
  
    public list<SelectOption> getStates() {
        list<SelectOption> optionList = new list<SelectOption>();
        optionList.add(new SelectOption('','Please select'));
        for(State_Province__c st: stateList){
            optionList.add(new SelectOption(st.id,st.name));
        }
        return optionList;
    }
    
  public void checkDomestic() {
 /*
      String s = ApexPages.CurrentPage().getParameters().get('domestic1');
      if(s == 'Yes') {
          Domestic = True;
      }
      else {
          Domestic = False;
      }
      system.debug('***************************** '+ Domestic);    */  
  }  
  
  public List<SelectOption> getEEACountrys() {
      List<SelectOption> optionList = new List<SelectOption>();
      for (country_list__c li : countrylist ){
          if(li.economic_grouping__c == 'EEA' || li.name == 'Switzerland') {        
              optionList.add(new SelectOption(li.id, li.name));
          }
      }
      return optionList;
  }
  
  public List<SelectOption> getOtherCountrys() {
      List<SelectOption> optionList = new List<SelectOption>();
      for (country_list__c li : countrylist ){        
          if(li.economic_grouping__c != 'EEA' && li.name != 'Switzerland') {        
              optionList.add(new SelectOption(li.id, li.name));
          }
      }
      return optionList;
  }
  
  /* original getYears() method
   public List<SelectOption> getYears() {
      List<SelectOption> optionList = new List<SelectOption>();
      date myDate = date.today();
      Integer yr = myDate.year();
      for (Integer i =  yr; i > yr-50; i--) {
         string y = String.valueOf(i);
         optionList.add(new SelectOption(y,y));
      }
      return optionList;
  }
  */
  
  public List<SelectOption> getYears() {
      List<SelectOption> optionList = new List<SelectOption>();
      date myDate = date.today();
      Integer yr = myDate.year() + 5;
      for (Integer i =  yr; i > yr-60; i--) {
         string y = String.valueOf(i);
         optionList.add(new SelectOption(y,y));  
      }
      return optionList;
  }
  
  /* original getPYear() method
  public List<SelectOption> getPYear() {
      List<SelectOption> optionList = new List<SelectOption>();
      optionList.add(new SelectOption('','Please select'));
          //for(Integer yrs : ymap.keySet()) {
            for(Integer yrs : available_years.keySet()) {
              //if (yrs == yr){
                  string y = String.valueOf(yrs);
                  optionList.add(new SelectOption(y,y));
              //}
         // }
      }
      optionList.sort();
      return optionList;
  }
  */

  public List<SelectOption> getPYear() {
    List<SelectOption> optionList = new List<SelectOption>();
    optionList.add(new SelectOption('','Please select'));
    set<Decimal> year = new set<Decimal>();
    for (Web_Course_Offering__c li : [SELECT Campus__c, start_date__c, Start_year__c, Start_day__c 
                                        FROM Web_Course_Offering__c 
                                       WHERE CALENDAR_YEAR(start_date__c) >= :date.today().year() AND Active__c = True AND 
                                             Campus__c= :listlocation AND programme__c = :listprogramme AND Mode__c = :listmodes 
                                             ORDER BY start_year__c]){
        if(li.start_date__c >= (date.today())) {
            year.add(li.start_year__c);  
        }
    }
    for(Decimal y:year){
        optionList.add(new SelectOption(''+integer.valueOf(y), ''+integer.valueOf(y)));
    }
    optionList.sort();
    return optionList;
  }
  
public string intLocal(Application_wizard__c awc) {
    String retval='International';
    //default 
    // get the testing points
    Boolean birth;
    Boolean domicile;
    Boolean nationality;
    if(awc != null)
        birth = isEEA(awc.Country_of_birth__c);
        if(awc != null)
            nationality = isEEA(awc.Nationality__c);
        Boolean citizen = True;
        if(awc.EEA_citizen__c != 'Yes'){
            citizen = False;
        }
        Boolean residency = False;
        if (awc.Date_of_Residency__c != Null) {
            residency = True;
        }
        if(awc != null && awc.Country_of_Domicile_Permanent_Residency__c != null) {
            domicile = isEEA(awc.Country_of_Domicile_Permanent_Residency__c);
            country_list__c cl = [SELECT Id, Name, enabled__c, region__c, economic_grouping__c FROM country_list__c WHERE Id =:awc.Country_of_Domicile_Permanent_Residency__c];
            if(cl != null && cl.name == 'United Kingdom' && residency == True){
                retval='Domestic';
            }   
        } 
        // calculate if Domestic
        if(birth == True){
            retval='Domestic';
        }
        if(nationality == True){
            retval='Domestic';
        }
        if(domicile == True && residency == True){
            retval='Domestic';
        }
        return retval;
 }
 
 public Boolean isEEA(String Cid) {
  Boolean retval = False;
  country_list__c cl;
  if(Cid != null)
        cl = [SELECT Id, Name, enabled__c, region__c, economic_grouping__c FROM country_list__c WHERE Id =:Cid];
  //if (  cl.economic_grouping__c =='EEA') 
  if (cl != null && cl.economic_grouping__c =='EEA') {
     retval = True;
  }
  return retval;
 }
 
    public List<SelectOption> getNationality() {
      List<SelectOption> optionList = new List<SelectOption>();
      for (country_list__c li : nationalitylist ){        
          optionList.add(new SelectOption(li.id, li.NATIONALITY__C));
      }
      return optionList;
  }

//Start new Application
public PageReference startNewApplication() {
    aw.Internal_Tracking_Status__c = 'User Deleted';
    //string familyName = aw.last_Name__c;
    //string email = aw.Email__c;
    //string password = aw.Password__c;     
    system.debug(aw.Name +'1234422');       
    update aw;
    
    Application_wizard__c awNew = new Application_wizard__c();
    awNew.First_name__c = aw.First_name__c;
    awNew.last_Name__c = aw.last_Name__c;
    awNew.Email__c =aw.Email__c;
    awNew.Password__c = aw.Password__c;
    awNew.Internal_Tracking_Status__c = 'Active';
    awNew.New_App_User_Request__c = true; 
    //awNew.email_mrkgting__c = aw.email_mrkgting__c;
    //awNew.post_mrkting__c = aw.post_mrkting__c;
    //awNew.telephone_mrkting__c = aw.telephone_mrkting__c;
    //awNew.sms_mrkting__c = aw.sms_mrkting__c;
    awNew.Marketing_Opt_Out__c = aw.Marketing_Opt_Out__c;
    
    awNew.Security_Token__c = generateSecurityToken();
    awNew.Security_Expiry_Date__c = system.Now().addDays(1);
    auth_id = awNew.Security_Token__c;
    system.debug(wiz_id+'here i am');
    Database.UpsertResult upsertResults = Database.upsert(awNew); 
    wiz_id = upsertResults.Id;
    PageReference pr =  new PageReference('/apex/application_personal_details'+'?wiz_id='+wiz_id+'&auth_id='+auth_id);
    pr.setRedirect(true); 
    return pr;                
}
     
//Create New Application - called if the user was already submitted or if application is in-active
public PageReference createNewApplication(Application_wizard__c aww) {   
    Application_wizard__c awNew = new Application_wizard__c();
    awNew.First_name__c = aww.First_name__c;
    awNew.last_Name__c = aww.last_Name__c;
    awNew.Email__c = aww.Email__c;
    awNew.Password__c = aww.Password__c;
    awNew.Internal_Tracking_Status__c = 'Active';
    awNew.Marketing_Opt_Out__c = aww.Marketing_Opt_Out__c; 
    
    awNew.Security_Token__c = generateSecurityToken();
    awNew.Security_Expiry_Date__c = system.Now().addDays(1);
    auth_id = awNew.Security_Token__c;
    system.debug(wiz_id+'here i am');
    Database.UpsertResult upsertResults = Database.upsert(awNew); 
    wiz_id = upsertResults.Id;
    PageReference pr =  new PageReference('/apex/application_personal_details'+'?wiz_id='+wiz_id+'&auth_id='+auth_id);
    //pr.setRedirect(true); 
    return pr;                
}
        
 //Mapping Education Related list of App wizard to Qualification Related list of Account
public void mapEducationToQualification(string personContactId){
    list<Application_wizard_eduction__c> listAppEduc = [Select a.Country_of_Study__c,a.year_of_completion__c, a.wizard__c, a.type__c, a.title_of_award__c, a.subject__c, 
                                                               a.predicted_actual__c, a.iteration__c, a.institution__c, a.full_time__c,a.Grade__c, 
                                                               a.Qualification__c, a.Other_Qualification__c, a.Name, a.Mode_of_Study__c, a.Id,
                                                               a.Institution_Lookup__c, a.Subject_Lookup__c, a.Type_Lookup__c, a.Qualification_Date__c
                                                          From Application_wizard_eduction__c a where a.wizard__c =:wiz_id];
    
    list<Qualification__c> listInsertQualification = new list<Qualification__c>();
    for(Application_wizard_eduction__c tempEdu : listAppEduc){
        if(tempEdu.Subject_Lookup__c != null){
            Qualification__c qualification = new Qualification__c();
            //qualification.Type__c = tempEdu.type__c;
            if(tempEdu.type__c == 'he')
                qualification.Type__c = 'Higher Ed';
            if(tempEdu.type__c == 'hs')
                qualification.Type__c = 'A Levels & GCSE';  
            if(tempEdu.type__c == 'oq')
                qualification.Type__c = 'Other Qual';
            qualification.Subject__c = tempEdu.subject__c;
            qualification.Institution__c = tempEdu.institution__c;
            if(tempEdu.Qualification__c !=null)
                qualification.Qualification__c = tempEdu.Qualification__c;
            else
                qualification.Qualification__c = tempEdu.Other_Qualification__c;
            qualification.HESA_Grade__c = tempEdu.Grade__c;
            qualification.Status__c = tempEdu.predicted_actual__c;
            qualification.Year_Of_Completion__c = tempEdu.year_of_completion__c;
            qualification.Mode__c = tempEdu.Mode_of_Study__c;
            qualification.Country_of_Study__c = tempEdu.Country_of_Study__c;
            qualification.Student__c = personContactId;
            
            qualification.Qualification_Type__c = tempEdu.Type_Lookup__c;
            qualification.Qualification_Subject__c = tempEdu.Subject_Lookup__c;
            qualification.Qualification_Institution__c = tempEdu.Institution_Lookup__c;
            qualification.Qualification_Date__c = tempEdu.Qualification_Date__c;
                        
            listInsertQualification.add(qualification);
        }       
    } 
    if(listInsertQualification.size()>0)
        Database.upsert(listInsertQualification);
} 

//Mapping Employment History Related list of App wizard to Employment Related list of Account
public void mapEmploymentOfAppToAccount(string personContactId){
    list<Application_wizard_employment__c> listAppEmp = [Select a.description__c, a.To__c, a.Name_of_employer__c, a.Job_Title__c, a.From__c, a.Application_wiz__c 
                                                           From Application_wizard_employment__c a
                                                          where a.Application_wiz__c = :wiz_id];
    list<Employment_History__c> listInsertEmp = new list<Employment_History__c>();
    for(Application_wizard_employment__c tempEmp : listAppEmp){
        if(tempEmp.Name_of_employer__c != null){
            Employment_History__c empHistory = new Employment_History__c();
            empHistory.Employer_Name__c = tempEmp.Name_of_employer__c;
            empHistory.Title__c = tempEmp.Job_Title__c;
            empHistory.Start_Date__c = tempEmp.From__c;
            empHistory.End_Date__c = tempEmp.To__c;
            empHistory.Description__c = tempEmp.description__c;
            empHistory.Student__c = personContactId;
            listInsertEmp.add(empHistory); 
        }
    }                                   
    if(listInsertEmp.size()>0)
        Database.upsert(listInsertEmp);                
}

//Mapping References Related list of App wizard to References Related list of Account
public void mapReferencesOfApptoAccount(string personContactId){
    list<Application_wizard_reference__c> listAppRef = [Select a.reference_telephone__c, a.reference_street__c, a.reference_postal__c, 
                                                            a.reference_email__c, a.reference_date__c, a.reference_city__c, a.Reference_State_Province__c, // a.Region__c, 
                                                            a.Reference_name__c, a.Reference_country__c, a.Reference_Position__c, a.Name, 
                                                            a.Personal_Statement__c, a.Application_wiz__c, a.Address_Line3__c, a.Address_Line2__c, a.Address_Line1__c 
                                                          From Application_wizard_reference__c a
                                                         where a.Application_wiz__c = :wiz_id];
    list<Reference__c> listInsertReference = new list<Reference__c>();
    
    /*list<country_list__c> country = [SELECT Id, Name FROM country_list__c];
    map<string,string> countryIdName = new map<string,string>();
    for(country_list__c tempCoun : country){
        countryIdName.put(tempCoun.id,tempCoun.Name);
    }*/
    for(Application_wizard_reference__c tempRef: listAppRef){
        if(tempRef.Reference_name__c != null){
            Reference__c reference = new Reference__c();
            reference.Name__c = tempRef.Reference_name__c;
            reference.Position__c = tempRef.Reference_Position__c;
            reference.Date__c = tempRef.reference_date__c;
            reference.Address_1__c = tempRef.Address_Line1__c;
            reference.Address_2__c = tempRef.Address_Line2__c;
            reference.Address_3__c = tempRef.Address_Line3__c;
            reference.City__c = tempRef.reference_city__c;
            reference.State_Province__c = tempRef.Reference_State_Province__c;
            reference.Postal_Code__c = tempRef.reference_postal__c;
            reference.Country__c = tempRef.Reference_country__c;
            /*if(tempRef.Reference_country__c!=null)
                reference.Country__c = countryIdName.get(tempRef.Reference_country__c);*/
            reference.Phone__c = tempRef.reference_telephone__c;
            reference.Email__c = tempRef.reference_email__c;
            reference.Description__c = tempRef.Personal_Statement__c;
            reference.Student__c = personContactId;
            listInsertReference.add(reference);
        }
    }
    if(listInsertReference.size()>0)
        Database.upsert(listInsertReference);
}

//Mapping Visa Related list of App wizard to Visa Related list of Account
public void mapVisasOfAppToAccount(string personContactId){
    list<Application_Wizard_Visa__c> listAppVisa = [Select a.Application_wizard__c, a.Actual_Qualification_Institution__c, a.Completed_Course_at_Visa_Institution__c, 
                                                    a.Level_of_Studies__c, a.Other_Visa_Type__c, a.Visa_Expiry_Date__c, a.Visa_Institution__c, 
                                                    a.Visa_Issue_Date__c, a.Visa_Qualification__c, a.Visa_Type__c 
                                                    From Application_Wizard_Visa__c a
                                                    where a.Application_wizard__c = :wiz_id];
    list<Visa__c> listInsertVisa = new list<Visa__c>();
    for(Application_Wizard_Visa__c tempVisa : listAppVisa){
        if(tempVisa.Visa_Issue_Date__c != null){
            Visa__c Visa = new Visa__c();
            Visa.Visa_Issue_Date__c = tempVisa.Visa_Issue_Date__c;
            Visa.Visa_Expiry_Date__c = tempVisa.Visa_Expiry_Date__c;
            Visa.Visa_Type__c = tempVisa.Visa_Type__c;
            Visa.Other_Visa_Type__c = tempVisa.Other_Visa_Type__c;
            Visa.Visa_Qualification__c = tempVisa.Visa_Qualification__c;
            Visa.Visa_Institution__c = tempVisa.Visa_Institution__c;
            Visa.Level_of_Studies__c = tempVisa.Level_of_Studies__c;
            Visa.Completed_Course_at_Visa_Institution__c = tempVisa.Completed_Course_at_Visa_Institution__c;
            Visa.Actual_Qualification_Institution__c = tempVisa.Actual_Qualification_Institution__c;     
            Visa.Student__c = personContactId;
            listInsertVisa.add(Visa); 
        }
    }                                   
    if(listInsertVisa.size()>0)
        Database.upsert(listInsertVisa);                
}

//Map attachments from the wiz to the Account
public void mapAttachmentsApptoAcc(){
    list<Attachment> lstAttach = [Select a.ParentId, a.OwnerId, a.Name, a.IsPrivate, a.IsDeleted, a.Id, 
                                         a.Description, a.ContentType, a.BodyLength, a.Body From Attachment a
                                   where a.ParentId =:wiz_id];
    list<Attachment> lstInsertAttach = new list<Attachment>();
    list<Account_Application_Attachments__c> Aaa = [Select Id from Account_Application_Attachments__c a
                                              where a.Account__c =:Acc.Id limit 1];
    Account_Application_Attachments__c Aaa1;
    if(Aaa.size() == 0){
        Aaa1 = new Account_Application_Attachments__c(); 
        Aaa1.Account__c = Acc.Id;
        Database.upsert(Aaa1);
    }
    else{
        Aaa1 = Aaa[0];  
    }           
        
    for(Attachment tempAttach : lstAttach){
        Attachment attachment  = new Attachment();  
        attachment.Body = tempAttach.Body;  
        attachment.Name = tempAttach.Name;
        attachment.Description = tempAttach.Description;          
        attachment.ParentId = Aaa1.Id; 
        lstInsertAttach.add(attachment);
    }
    insert lstInsertAttach;
    
    system.debug(lstAttach.size());
}

//Owner Reassignment
public string recordAssignment(string program,string studentType){
        Programme__c prog = [SELECT Id, Name, DA_Acc_Assig_Prog_Type__c 
                               FROM Programme__c 
                               where id=:program ];
        system.debug(program + 'program dapps11');
        string oId = null;
        string typeProgram = studentType + '_'+ prog.DA_Acc_Assig_Prog_Type__c;
        list<Direct_Apps_Owner_Reassignment__c> DAOwnerR = Direct_Apps_Owner_Reassignment__c.getall().values();
        for(Direct_Apps_Owner_Reassignment__c daor: DAOwnerR){
            if(daor.Name.contains(typeProgram)){
                oId = daor.Dest_Owner_Or_Role_ID__c;
                break;
            }
            else if(daor.Name.contains(studentType + '_Default') && oId == null){
                oId = daor.Dest_Owner_Or_Role_ID__c;
            }
            /*if(daor.Name.contains(studentType + '_Account')){
                DomesticOwnerId = daor.Dest_Owner_Or_Role_ID__c;
            }*/
                  
        }
        system.debug(ownerId + 'program dapps');
        return oId;     
    }

/**
 * Map address from wizard to Account.
 */
public void mapAddressToAccount(Account Acc){
    //Pulling out all the existing address on the account
    list<Address__c> existingAddress = [Select a.Zip_Postal_Code__c, a.Type__c, a.Student__c, a.Street_3__c, a.Street_2__c, a.Street_1__c,  
                                               a.Name, a.Lookup_Country__c, a.Lead__c, a.Id, a.City__c, a.Active__c 
                                          From Address__c a where a.Student__c =:Acc.id and a.Active__c = true];
    map<string,Address__c> mTypeAdd = new map<string,Address__c>();
    list<Address__c> lstUpsertAddress = new list<Address__c>();
    Address__c pMailingAdd;
    Address__c pKinAdd; 
    if(existingAddress.size()>0){
        //Creating a map of type of address and the address.
        for(Address__c temp: existingAddress){
            mTypeAdd.put(temp.Type__c,temp);
        }
        /* If the address already has of the type mailing or other then it should be updated 
           or else it should be inserted. */
        
        if(mTypeAdd.containsKey('Mailing')){
            pMailingAdd =  mTypeAdd.get('Mailing');             
        }else{
            pMailingAdd = new Address__c();            
        }
        if(mTypeAdd.containsKey('Next of Kin/Emergency/Guardian')){
            pKinAdd = mTypeAdd.get('Next of Kin/Emergency/Guardian');   
        }else{
            pKinAdd = new Address__c();
        }
    }else{
        pMailingAdd = new Address__c(); 
        pKinAdd = new Address__c();
    }
    pMailingAdd.Student__c = Acc.Id;
    pMailingAdd.Street_1__c = aw.Address_Line_1__c;
    pMailingAdd.Street_2__c = aw.Address_Line_2__c;
    pMailingAdd.Street_3__c = aw.Address_Line_3__c;
    pMailingAdd.City__c = aw.City__c;
    pMailingAdd.State_Province__c = aw.State_Province__c;
    if(aw.country__c != null) {
        pMailingAdd.Lookup_Country__c = aw.country__c;
    }
    pMailingAdd.Type__c = 'Mailing';
    pMailingAdd.Active__c = true;    
    pMailingAdd.Zip_Postal_Code__c = aw.Postal_Code__c;
    lstUpsertAddress.add(pMailingAdd);
    
    if(aw.kin_address_line1__c != null || aw.kin_country__c!=null || aw.kin_postcode__c != null){           
        pKinAdd.Student__c = Acc.Id;
        pKinAdd.Street_1__c = aw.kin_address_line1__c;
        pKinAdd.Street_2__c = aw.kin_address_line2__c;
        pKinAdd.Street_3__c = aw.kin_address_line3__c;        
        pKinAdd.City__c = aw.kin_city__c;
        pKinAdd.State_Province__c = aw.kin_State_Province__c;
        if(aw.kin_country__c != null) {
            pKinAdd.Lookup_Country__c = aw.kin_country__c;
        }
        pKinAdd.Type__c = 'Next of Kin/Emergency/Guardian';
        pKinAdd.Active__c = true;    
        pKinAdd.Zip_Postal_Code__c = aw.kin_postcode__c;
        lstUpsertAddress.add(pKinAdd);
    }
    upsert lstUpsertAddress;
}

public void addProductCatalogItem(opportunity opp){
    //PC_Item__c PCItem = [Select Id, Product__c 
    //From PC_Item__c 
    //Where Product__c =: opp.Course_Instance__c And PC_Bundle__c = null And PC_Bundle_Id__c = null];
    //Opportunity_PC_Item__c oppPCItem = new Opportunity_PC_Item__c();
    //oppPCItem.Opportunity__c = opp.Id;
    //oppPCItem.PC_Item__c = PCItem.Id; 
    //oppPCItem.Course_Focus__c = 'Primary';
    //insert oppPCItem;   
    
    //Updated code after change from 'Opportunity_PC_Item__c' records to 'Opportunity_Product__c'
    Opportunity_Product__c oppProduct = new Opportunity_Product__c();
    oppProduct.Opportunity__c = opp.Id;
    oppProduct.Product__c = opp.Course_Instance__c;
    oppProduct.Course_Focus__c = 'Primary';
    
    insert oppProduct;
           
    //remove values from the legacy fields
    opp.Course_Instance__c = null;
    opp.Programme_Application__c = null;
    opp.Mode__c = null;
    opp.Location__c = null;
    
    opp.BNR_Program_Code_Text__c = null;
    opp.BNR_Degree_Code_Text__c = null;
    opp.BNR_Campus_Code_Text__c = null;
    
    opp.BNR_Level_Code_Text__c = null;
    opp.BNR_Term_Code_Text__c = null;
    opp.BNR_FieldOfStudy_Code__c = null;  
    
    update opp;     
}

public void errorMessage(string ex){
    Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
    email.setSubject('Error from BPP Direct application while moving to page: '+ nextPage);
    email.setToAddresses(new string[] {'rex.famatid@synegen.com','keith.kadlec@apollogrp.edu','srikar.beemagouni@synegen.com'});
    email.setPlainTextBody('Message :' + ex );
    email.setHtmlBody('<p>Message: </p>' + ex);
    if (!Test.isRunningTest()){
        Messaging.SendEmailResult [] r = Messaging.sendEmail(new Messaging.SingleEmailMessage[] {email});
    }
  }
}