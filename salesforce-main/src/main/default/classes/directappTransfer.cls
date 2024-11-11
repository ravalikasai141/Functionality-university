global class directappTransfer implements Schedulable{
/*
description: this class is executed by a timed apex every 10 minutes
it does the ETL between the application wizard and the standard objects.
Author: Chris Roberts
Created: Sept/19/2011
Current Version: 1.0 Sept/19/2011
*/
 public void directappTransfer() {
 }

   global void execute(SchedulableContext SC) {
    dodirectappTransfer(); 
   }

// this is the main method that does the ETL process public void ProcessData(){
 //get the application list that is ready and has not been extracted
public void dodirectappTransfer(){
/*
 RecordType personaccount = [SELECT Id FROM RecordType where DeveloperName ='Student_Account'];
 RecordType opportunitytype = [SELECT Id FROM RecordType where DeveloperName ='Student_Application'];

// build list objects to be used to reduce DML and SOQL.
list <Application_wizard__c> awl = [SELECT Id, Course_Instance__c ,Web_Course_Offering__r.Course_Instance_ID__c ,
     last_Name__c, Email__c, Programme__c,  First_name__c, 
     Gender__c, Date_of_Birth__c, Address__c, City__c, Provence_State__c, Postal_Code__c, telephone__c, Date_of_Residency__c, 
     Conditions_of_residency__c, Date_of_arrival_in_the_UK__c,  Exam_type__c,  Exam_Result__c, Name_of_organisation__c,
     Authorising_name__c, Purchase_order_Number_where_necessary__c, Street_Address__c, sponsorCity__c, sponsorPostal_Code__c, 
     sponsorTelephone__c, sponsorEmail__c, personal_statement__c, month__c, intake_month__c, country__c, sponsorCountry__c, 
     Country_of_birth__c, Country_of_Domicile_Permanent_Residency__c, Location__c, Mode__c, ready_for_extract__c, 
     extract_date__c, Nationality__c, EEA_citizen__c, Are_yu_being_sponsored_for_the_programme__c, 
     is_english_your_first_language__c ,  country__r.Name, Title__c, 
     Country_of_birth__r.Name, Country_of_Domicile_Permanent_Residency__r.Name, Location__r.Display_Name__c, 
     Mode__r.Name, Nationality__r.Name, Programme__r.Name, sponsorCountry__r.Name  FROM Application_wizard__c 
     WHERE ready_for_extract__c = True AND  extract_date__c = Null]; 


 List <country_list__c> cl = [SELECT Id, Name, enabled__c, region__c, economic_grouping__c FROM country_list__c];

 
 Direct_app_assign__c daa = [select Id, IsDeleted, Name, SetupOwnerId, CreatedDate, CreatedById, LastModifiedDate, 
     LastModifiedById, SystemModstamp, User__c, Student_Type__c, email__c from Direct_app_assign__c WHERE name='International'];
 string intowner = daa.User__c;
 string intemail = daa.email__c;
 
 daa = [select Id, IsDeleted, Name, SetupOwnerId, CreatedDate, CreatedById, LastModifiedDate, LastModifiedById, SystemModstamp, 
     User__c, Student_Type__c, email__c from Direct_app_assign__c WHERE name='Domestic'];
 string domowner = daa.User__c;
 string domemail = daa.email__c;
   

 // loop thgrough the application to get the education set and refrences and employment
    for (Application_wizard__c aw : awl) {
        List <Opportunity> opp = new List <Opportunity>();
        List <Qualification__c> qual = new List<Qualification__c>();
        List <Employment_History__c> emp = new List<Employment_History__c>();
        List <Reference__c> ref = new List <Reference__c>();
         // related education
         List <Application_wizard_eduction__c> awe = [SELECT Id, Name, subject__c, wizard__c, Grade__c, year_of_completion__c, 
             full_time__c, institution__c, title_of_award__c, iteration__c, type__c, Country_of_Study__c, predicted_actual__c 
             FROM Application_wizard_eduction__c WHERE wizard__c = :aw.Id ORDER BY type__c];
         // related references 
         List <Application_wizard_reference__c> awr = [SELECT Id,  Reference_name__c, Reference_Position__c, 
             reference_street__c, reference_city__c, reference_postal__c, reference_telephone__c, reference_email__c, 
             reference_date__c, Application_wiz__c, iteration__c, Reference_country__c 
             FROM Application_wizard_reference__c WHERE Application_wiz__c = :aw.Id];
         // related employment
         List <Application_wizard_employment__c> awp = [SELECT Id,  Name_of_employer__c, Job_Title__c, From__c, 
             To__c, Application_wiz__c, description__c, iteration__c FROM Application_wizard_employment__c 
             WHERE Application_wiz__c = :aw.Id];
         
         
         //Maping section
         
         //Build the account record
         Account acc = new Account();
         //Correspondence address         
         acc.PersonMailingStreet             = aw.Address__c;
         acc.PersonMailingCity               = aw.City__c;
         acc.PersonMailingState              = aw.Provence_State__c;          
         acc.PersonMailingCountry            = aw.country__r.Name;
         acc.PersonMailingPostalCode         = aw.Postal_Code__c;

         //personal details
         acc.PersonBirthDate                 = aw.Date_of_Birth__c;
         acc.Country_of_Birth__pc            = aw.Country_of_birth__r.Name;
         acc.FirstName                       = aw.First_name__c;
         acc.LastName                        = aw.last_Name__c;
         acc.Gender__pc                      = aw.Gender__c;
         acc.Personal_Email__pc              = aw.Email__c; 
         acc.PersonTitle                     = aw.Title__c;
         //acc.IsPersonAccount                = True;
         acc.Country_of_Residence__pc        = aw.Country_of_Domicile_Permanent_Residency__r.Name;
         acc.UK_Permanent_Residence_Date__pc = aw.Date_of_arrival_in_the_UK__c;
         acc.Nationality__pc                 = aw.Nationality__r.Name;
         acc.Student_Type__pc                = intLocal(aw,cl);
         acc.Language_Test_Type__pc          = aw.Exam_type__c; 
         acc.Language_Test_Score__pc         = aw.Exam_Result__c;
         acc.RecordTypeId                    = personaccount.Id;
         // addaccount record ownerid here 
          if(intLocal(aw,cl) == 'International') {
              acc.OwnerId = intowner;
          } else {
              acc.OwnerId = domowner;
          }

         //acc.Conditions_of_Entry__c          = aw.Conditions_of_residency__c;
         //EEA_citizen__c
         
         //sponsorCountry__r.Name 
         // Location__r.Display_Name__c
         acc.Preferred_Email__pc ='Home';
         // insert the Account and get the ID and the contact id
         //insert(acc); 
         
         Database.SaveResult asr = Database.insert(acc); 
         if(!asr.isSuccess()){
            //Database.Error err = asr.getErrors();
            System.debug(logginglevel.DEBUG, '************************** error was '+asr.getErrors()+' **********');
         }
 
         
         System.debug(logginglevel.DEBUG, '************************** Account id is '+acc.Id+' ****************************');
         System.debug(logginglevel.DEBUG, '************************** Account contact id is '+acc.PersonContactId+' ****************************');
         Account acct;
         if(acc.Id !=Null) {
            acct = [SELECT PersonContactId FROM Account WHERE Id=:acc.Id];
         }
         System.debug(logginglevel.DEBUG, '************************** Account contact id is '+acct.PersonContactId+' ****************************');

         // build Opportunity 
         System.debug(logginglevel.DEBUG, '************************** CourseInstance is '+aw.Web_Course_Offering__r.Course_Instance_ID__c +' ****************************');
         
         Opportunity op = new Opportunity(); 
         op.name                             = ''+aw.First_name__c+''+aw.last_Name__c;
         op.CloseDate                        = date.today();
         op.StageName                        = 'Application';
         op.Application_Date__c              = date.today();
         op.Sponsorship_Type__c              = aw.Are_yu_being_sponsored_for_the_programme__c; 
         op.Sponsor_Phone__c                 = aw.sponsorTelephone__c;
         op.Sponsoring_Purchase_Order__c     = aw.Purchase_order_Number_where_necessary__c;
         op.Personal_Statement_Body__c       = aw.personal_statement__c;
         op.Course_Instance__c               = aw.Web_Course_Offering__r.Course_Instance_ID__c;
         op.AccountId                        = acc.Id;
         op.Contact_Name__c                  = acct.PersonContactId;
         op.RecordTypeId                     = opportunitytype.id;
          //Authorising_name__c string      Opportunity "Sponsor_First_Name__c Sponsor_Last_Name__c"
         //Name_of_organisation__c string      Opportunity Sponsoring_Organization__c
          //add opportunity record ownerid here
          if(intLocal(aw,cl) == 'International') {
              op.OwnerId = intowner;
          } else {
              op.OwnerId = domowner;
          }
         // insert opportunity and get the ID 
         Database.SaveResult osr = Database.insert(op); 
         if(!osr.isSuccess()){
           // Database.Error err = osr.getErrors();
            System.debug(logginglevel.DEBUG, '************************** error was '+osr.getErrors()+' **********');
         }        
         //insert(op);
         System.debug(logginglevel.DEBUG,'************************** Opportunity id is '+op.Id+' ****************************');

         
         
         
         //  do education 
          Qualification__c Qualification ;
         for(Application_wizard_eduction__c ed:awe) {
             // populate the Qualification__c 
             Qualification      = new Qualification__c();
             if(ed.full_time__c == True) { 
                 Qualification.Mode__c           = 'Full Time';
             } else { 
                 Qualification.Mode__c           = 'Part Time';
             }
             Qualification.student__c            = op.Contact_Name__c;
             Qualification.Institution__c        = ed.Institution__c;
             Qualification.Status__c             = ed.predicted_actual__c;
             Qualification.Subject__c            = ed.Subject__c;
             Qualification.Grade__c              = ed.Grade__c;
             Qualification.Type__c               = ed.title_of_award__c;
            
             Qualification.Qualification_Date__c = date.parse('01/01/'+ed.year_of_completion__c);
            // add instance 
             qual.add(Qualification);
         }
         System.debug(logginglevel.DEBUG, '************************** insert Qualification **********');

         Database.SaveResult[] qsr = Database.insert(qual);
         // Iterate through the Save Results      
         for(Database.SaveResult sr:qsr){
           if(!sr.isSuccess()){
              Database.Error err = sr.getErrors()[0];
              System.debug(logginglevel.DEBUG, '************************** error was '+sr.getErrors()[0]+' **********');
           }
         }
         //insert(qual);
     
         //do employment
         for(Application_wizard_employment__c employ :awp) {
             Employment_History__c empl          = new Employment_History__c();
             empl.student__c                     = acct.PersonContactId;
             empl.Start_Date__c                  = employ.From__c;
             empl.End_Date__c                    = employ.To__c;
             empl.Title__c                       = employ.Job_Title__c;
             empl.Employer_Name__c               = employ.Name_of_employer__c;
             empl.Description__c                 = employ.description__c;           
            // add instance
             emp.add(empl);
         }
         System.debug(logginglevel.DEBUG, '************************** insert employment **********');
         Database.SaveResult[] esr = Database.insert(emp);
         // Iterate through the Save Results      
         for(Database.SaveResult sr:esr){
           if(!sr.isSuccess()){
              Database.Error err = sr.getErrors()[0];
              System.debug(logginglevel.DEBUG, '************************** error was '+sr.getErrors()[0]+' **********');
           }
         }
         //insert(emp);
     
         //do reference 
         for(Application_wizard_reference__c refr :awr) {
            Reference__c refrence                    = new Reference__c(Application__c = op.Id);
            refrence.Date__c                         = refr.reference_date__c;
            refrence.Email__c                        = refr.reference_email__c;
            refrence.Postal_Code__c                  = refr.reference_postal__c;
            refrence.Address_1__c                    = refr.reference_street__c;
            refrence.Phone__c                        = refr.reference_telephone__c;
            refrence.Country__c                      = refr.Reference_country__c;
            refrence.student__c                     = acct.PersonContactId;
            // add instance
            ref.add(refrence);
         }
         System.debug(logginglevel.DEBUG, '************************** insert reference **********');
         Database.SaveResult[] rsr = Database.insert(ref);
         // Iterate through the Save Results      
         for(Database.SaveResult sr:rsr){
           if(!sr.isSuccess()){
              Database.Error err = sr.getErrors()[0];
              System.debug(logginglevel.DEBUG, '************************** error was '+sr.getErrors()[0]+' **********');
           }
         }
         //insert(ref);
         
         
         // update the extract date in Application_wizard__c
         Application_wizard__c awu = new Application_wizard__c(id= aw.id , extract_date__c = datetime.now(),
         ready_for_extract__c = false );
         
         update(awu);
    
         // send the email on this insert
         string adminemail;
          if (intLocal(aw,cl) == 'International') {
              adminemail = intemail;
          } else {
              adminemail = domemail;
          }
          
          //PageReference dummy = new PageReference('/');
          //String host = dummy.getHeaders().get('Host');
          String host = URL.getSalesforceBaseUrl().toExternalForm() + '/';
          String [] toAddresses = new String[] {adminemail };
 
          // Create an email
          Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
          email.setSubject('From BPP Direct application System');
          string thetxtbody  = 'New Application Information \r\n\r\n Account: '+host+acc.Id+'\r\n\r\n Opportunity: '+host+op.id+'\r\n\r\n Attached is the References documents (if any). \r\n' ;
          string thehtmlbody = 'New Application Information \r\n\r\n Account: <a href ="'+host+acc.id+'">'+host+acc.id+'</a>\r\n\r\n Opportunity: <a href="'+host+op.id+'">'+host+op.id+'</a>\r\n\r\n Attached is the References documents (if any). \r\n' ;
          email.setToAddresses(toAddresses);
          email.setPlainTextBody(thetxtbody);
          email.setHtmlBody(thehtmlbody);
 
          List <Attachment> Att = [select Id, ParentId, Name, ContentType, BodyLength, Body, Description from Attachment WHERE ParentId = :aw.Id];
          List <Messaging.EmailFileAttachment> efa = new List <Messaging.EmailFileAttachment>();
          for (Attachment fa: Att) { 
             // Create an email attachment
             // no null length attachments
             if(fa.Body !=Null) {
                 Messaging.EmailFileAttachment efa1 = new Messaging.EmailFileAttachment();
                 efa1.setFileName(fa.name); // neat - set name of PDF
                 efa1.setBody(fa.Body); //attach the PDF
                 efa1.setInline(False); // make them attachments not inline
                 efa.add(efa1);
             }
          }
          if( efa.size() > 0 ) {
              email.setFileAttachments(efa);
          }
          // send it, ignoring any errors (bad!)
          Messaging.SendEmailResult [] r = Messaging.sendEmail(new Messaging.SingleEmailMessage[] {email});  
     }
 }

 public string intLocal(Application_wizard__c awc, List <country_list__c> cll ) {
  //default
  String retval='International';
  // get the testing points
  Boolean birth = isEEA(awc.Country_of_birth__c, cll);
  Boolean domicile = isEEA(awc.Country_of_Domicile_Permanent_Residency__c, cll);
  Boolean nationality = isEEA(awc.Nationality__c,cll);
  Boolean citizen = True;
  if(awc.EEA_citizen__c == 'No'){
      citizen = False;
  }
  Boolean residency = False;
  if (awc.Date_of_Residency__c != Null) {
      residency = True;
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
  for (country_list__c cl:cll){
      //country_list__c cl = [SELECT Id, Name, enabled__c, region__c, economic_grouping__c FROM country_list__c WHERE Id =:awc.Country_of_Domicile_Permanent_Residency__c];
      if(cl.Id == awc.Country_of_Domicile_Permanent_Residency__c) {
          if(cl.name == 'United Kingdom' && residency == True){
              retval='Domestic';
          }
      }
  }
  return retval;
 }

public Boolean isEEA(String Cid, list<country_list__c> cll) {
  Boolean retval = False;
  //country_list__c cl = [SELECT Id, Name, enabled__c, region__c, economic_grouping__c FROM country_list__c WHERE Id =:Cid];
 for (country_list__c cl:cll){
      if (cl.Id == Cid){
          if ( cl.economic_grouping__c =='EEA') {
             retval = True;
          }
      }
  }
  return retval;
 }
 
   static testMethod  void directappTransferTest1() {
      //start test
    
    
 Application_wizard__c AWW = new  Application_wizard__c();
 AWW.last_Name__c ='METHOD';
 AWW.Email__c ='me@you.com';
 AWW.Title__c ='DR';
 AWW.First_name__c ='TEST';
 AWW.Gender__c ='Male';
 AWW.Date_of_Birth__c =Null;
 AWW.Address__c ='123 main';
 AWW.City__c ='London';
 AWW.Provence_State__c ='';
 AWW.Postal_Code__c ='atestcode';
 AWW.telephone__c ='1234567890';
 AWW.Date_of_Residency__c =Null;
 AWW.Conditions_of_residency__c ='';
 AWW.Date_of_arrival_in_the_UK__c =Null;
 AWW.Exam_type__c ='';
 AWW.Exam_Result__c ='';
 AWW.Name_of_organisation__c ='';
 AWW.Authorising_name__c ='';
 AWW.Purchase_order_Number_where_necessary__c ='';
 AWW.Street_Address__c ='';
 AWW.sponsorCity__c ='';
 AWW.sponsorPostal_Code__c ='';
 AWW.sponsorTelephone__c ='';
 AWW.sponsorEmail__c ='';
 AWW.personal_statement__c ='';
 AWW.month__c ='';
 AWW.intake_month__c ='';
 
 Programme__c  prog = [select id from Programme__c limit 1];
 AWW.Programme__c= prog.id;
 
  country_list__c country = [select id from country_list__c where name =: 'United Kingdom' limit 1];
 AWW.country__c =country.id;

 list<country_list__c> countries = [select id from country_list__c limit 3];
 AWW.sponsorCountry__c =countries[0].id;
 AWW.Country_of_birth__c =countries[1].id;
 AWW.Country_of_Domicile_Permanent_Residency__c =countries[2].id;
 
 campus__c camp = [select id from Campus__c limit 1];
 AWW.Location__c = camp.id;
 
 mode__c mod = [select id from Mode__c limit 1];
 AWW.Mode__c = mod.id;
 
 
 AWW.Nationality__c =country.id;
 AWW.EEA_citizen__c ='YES';
 AWW.Are_yu_being_sponsored_for_the_programme__c ='Yes';
 AWW.is_english_your_first_language__c ='YES';
 AWW.ready_for_extract__c = True;
 AWW.extract_date__c = Null;
 
 Web_Course_Offering__c wco = [select id from Web_Course_Offering__c limit 1];
 AWW.Web_Course_Offering__c= wco.id;
 
  insert(AWW);
  
 Application_wizard_eduction__c ed = new  Application_wizard_eduction__c();
       ed.predicted_actual__c = 'Actual';
       ed.Subject__c = 'test';
       ed.Grade__c = 'a';
       ed.title_of_award__c = 'first';
       ed.year_of_completion__c = '1901';
       ed.wizard__c = AWW.id;
       ed.full_time__c = True;
 insert ed;
 
  Application_wizard_eduction__c ed2 = new  Application_wizard_eduction__c();
       ed2.predicted_actual__c = 'Actual';
       ed2.Subject__c = 'test';
       ed2.Grade__c = 'a';
       ed2.title_of_award__c = 'first';
       ed2.year_of_completion__c = '1901';
       ed2.wizard__c = AWW.id;
       ed2.full_time__c = false;
   insert ed2;

  Opportunity op = [select id from Opportunity limit 1];
    
    Account acct = [SELECT PersonContactId FROM Account limit 1];  
    Application_wizard_reference__c ref = new Application_wizard_reference__c();
            ref.Application_wiz__c = aww.id;
      ref.reference_Date__c     = System.Date.today();          
            ref.reference_Email__c    = 'ref@ref.com';         
            ref.reference_Postal__c  = '123456';
            ref.reference_street__c    = '123 Main';    
            ref.reference_telePhone__c   ='1234567890';
            ref.reference_Country__c = country.id;
            // add instance
            insert ref;
 
 Application_wizard__c AWW2 = new  Application_wizard__c();
 AWW2.last_Name__c ='METHOD';
 AWW2.Email__c ='me@you.com';
 AWW2.Title__c ='DR';
 AWW2.First_name__c ='TEST';
 AWW2.Gender__c ='Male';
 AWW2.Date_of_Birth__c =Null;
 AWW2.Address__c ='123 main';
 AWW2.City__c ='London';
 AWW2.Provence_State__c ='';
 AWW2.Postal_Code__c ='atestcode';
 AWW2.telephone__c ='1234567890';
 AWW2.Date_of_Residency__c =Null;
 AWW2.Conditions_of_residency__c ='';
 AWW2.Date_of_arrival_in_the_UK__c =Null;
 AWW2.Exam_type__c ='';
 AWW2.Exam_Result__c ='';
 AWW2.Name_of_organisation__c ='';
 AWW2.Authorising_name__c ='';
 AWW2.Purchase_order_Number_where_necessary__c ='';
 AWW2.Street_Address__c ='';
 AWW2.sponsorCity__c ='';
 AWW2.sponsorPostal_Code__c ='';
 AWW2.sponsorTelephone__c ='';
 AWW2.sponsorEmail__c ='';
 AWW2.personal_statement__c ='';
 AWW2.month__c ='';
 AWW2.intake_month__c ='';
 
 Programme__c  prog2 = [select id from Programme__c limit 1];
 AWW2.Programme__c= prog2.id;
 
  country_list__c country2 = [select id from country_list__c where name =: 'France' limit 1];
 AWW2.country__c =country2.id;

 list<country_list__c> countries2 = [select id from country_list__c limit 3];
 AWW2.sponsorCountry__c =countries2[0].id;
 AWW2.Country_of_birth__c =countries2[1].id;
 AWW2.Country_of_Domicile_Permanent_Residency__c =countries2[2].id;
 
 campus__c camp2 = [select id from Campus__c limit 1];
 AWW2.Location__c = camp2.id;
 
 mode__c mod2 = [select id from Mode__c limit 1];
 AWW2.Mode__c = mod2.id;
 
 
 AWW2.Nationality__c =country2.id;
 AWW2.EEA_citizen__c ='YES';
 AWW2.Are_yu_being_sponsored_for_the_programme__c ='Yes';
 AWW2.is_english_your_first_language__c ='YES';
 AWW2.ready_for_extract__c = True;
 AWW2.extract_date__c = Null;
 
 Web_Course_Offering__c wco2 = [select id from Web_Course_Offering__c limit 1];
 AWW2.Web_Course_Offering__c= wco2.id;
 insert(AWW2);
 //FROM Application_wizard__c WHERE ready_for_extract__c = True AND  extract_date__c = Null];
      
      
     test.starttest();
       
       
       PageReference pageRef1 = new PageReference('/apex/applicationwiz2');
       Test.setCurrentPage(pageRef1); 
       //create controller object instance to test against
        //ApexPages.StandardController con = new ApexPages.StandardController(new Application_wizard__c());               
      
        directappTransfer Ctlr = new directappTransfer();
        // point the test instance to a page 
         Ctlr.dodirectappTransfer();
        
         
        test.stoptest(); 
*/
   }
}