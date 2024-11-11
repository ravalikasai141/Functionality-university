public class RFIcontrollerFixv3 {
 
 public string selectedLevel0 {get; set;}
 public string selectedLevel1 {get; set;}
 public string selectedLevel2 {get; set;} 
 public Boolean bookNewCourse;
 public Boolean isCoursePicklistEmpty = true;

    public RFIcontrollerFixv3(ApexPages.StandardController controller) {
        bookNewCourse = False;
        existingStudent = 'none';
        levelOfStudyVal  = '';
        rt = [Select r.Id from RecordType r where DeveloperName ='RFI_Form' limit 1];
        // system.debug('************'+rt);
        thelead = new Lead();
        thelead.recordtypeid = rt.Id;
        countryList = new List<country_list__c>();
        countryInitList = new List<country_list__c>();
        countryList = [Select Id, Name from country_list__c where enabled__c = True and Name != 'UNITED KINGDOM' order by Name];
        countryInitList = [Select Id, Name from Country_List__c where enabled__c =True and Name = 'UNITED KINGDOM' limit 1];
    }
    
    public List<selectOption> level0Items {
        get {
            List<selectOption> options = new List<selectOption>();               
            Set<String> areaSet = new Set<String>(); 
            options.add(new SelectOption('','-- Choose a Level of Study--'));
            List <RFI_Routing__c> lList = [Select id, rfi_Are_you_currently_studying_with_us__c,are_you_eu_uk__c,rfi_Area_of_Interest__c,
                                                  Rfi_Level_of_study__c,RFI_Course_of_Interest__c from RFI_Routing__c 
                                            where rfi_Are_you_currently_studying_with_us__c = 'No' and
                                                  are_you_eu_uk__c =: thelead.rfi_Are_you_EU_UK__c];
            System.debug('Routing List Size: ' + lList.size());
            for (RFI_Routing__c r: lList){
                if(!areaSet.contains(r.Rfi_Level_of_study__c)) {
                    options.add(new SelectOption(r.Rfi_Level_of_study__c,r.Rfi_Level_of_study__c));
                    areaSet.add(r.Rfi_Level_of_study__c);            
                }     
            }      
            system.debug('**********************area options '+options);
            return options;           
        }
        set;
    }    
    
    public List<selectOption> level1Items {
        get {
            list<selectOption> options = new list<selectOption>();               
            Set<String> areaSet = new Set<String>(); 
            options.add(new SelectOption('','-- Choose an Area of Interest--'));
            list <RFI_Routing__c> rList = [Select id, rfi_Are_you_currently_studying_with_us__c,are_you_eu_uk__c,rfi_Area_of_Interest__c,
                                                  Rfi_Level_of_study__c,RFI_Course_of_Interest__c from RFI_Routing__c 
                                            where rfi_Are_you_currently_studying_with_us__c = 'No' and
                                                  are_you_eu_uk__c =: thelead.rfi_Are_you_EU_UK__c and Rfi_Level_of_study__c =: selectedLevel0
                                            order by rfi_Area_of_Interest__c];
            System.debug('Routing List Size: ' + rList.size());
            for (RFI_Routing__c r: rList) {
                if(!areaSet.contains(r.rfi_Area_of_Interest__c)) {
                    options.add(new SelectOption(r.rfi_Area_of_Interest__c,r.rfi_Area_of_Interest__c));
                    areaSet.add(r.rfi_Area_of_Interest__c);            
                }     
            }      
            system.debug('**********************area options '+options);
            return options;           
        }
        set;
    }
        
        
    public List<selectOption> level2Items {
        get {
            List<selectOption> options = new List<selectOption>();
            Set<String> courseSet = new Set<String>();       
            if (selectedLevel1 != NULL) {
                options.add(new SelectOption('','-- Choose a Course of Interest--'));
                List<RFI_Routing__c> clist = new List<RFI_Routing__c>();
                clist = [Select id, rfi_Are_you_currently_studying_with_us__c,are_you_eu_uk__c,rfi_Area_of_Interest__c,Rfi_Level_of_study__c,
                     RFI_Course_of_Interest__c from RFI_Routing__c 
                     where rfi_Are_you_currently_studying_with_us__c = 'No' and
                     are_you_eu_uk__c =: thelead.rfi_Are_you_EU_UK__c and 
                     Rfi_Level_of_study__c =: selectedLevel0 and 
                     rfi_Area_of_Interest__c =: selectedLevel1 order by RFI_Course_of_Interest__c];
                  
               if(clist.size() >0) {
                  isCoursePickListEmpty = true;
                  if (clist[0].RFI_Course_of_Interest__c != null) isCoursePickListEmpty = false;
                     if (isCoursePickListEmpty == false) system.debug('isCoursePickListEmpty = false');
                for (RFI_Routing__c r: clist)
                    {
                    if(r.RFI_Course_of_Interest__c != null && !courseSet.contains(r.RFI_Course_of_Interest__c)) {
                        options.add(new SelectOption(r.RFI_Course_of_Interest__c, r.RFI_Course_of_Interest__c));
                        courseSet.add(r.RFI_Course_of_Interest__c);            
                        }
                    }
                }
            }
            system.debug('**********************course options '+options);         
            return options;                               
           }
        set;
    }       
            
  
    public List<SelectOption> getCountries() {
        List<SelectOption> options = new List<SelectOption>();
        Set<String> courseSet = new Set<String>();       
        If(countryInitList.size() > 0){
            options.add(new SelectOption(countryInitList[0].Id,countryInitList[0].Name));
        }
        if(countryList.size() >0) {
      
            for(Country_List__c c : countryList) {
                options.add(new SelectOption(c.Id,c.Name));
            
            }
        
        }
        return options;
    }
    
    
    public PageReference dummyMethod() {
        system.debug('******** in method ******');
        if(levelOfStudyVal != '') {
           system.debug('*******************'+levelOfStudyVal);
           thelead.Rfi_Level_of_study__c = levelOfStudyVal;
        }
        system.debug('*******************'+levelOfStudyVal+'*********'+thelead.srn__c+'*********'+thelead);
        return null;
    }
    
    public PageReference existingStudentCheck() {
        system.debug('******************'+thelead.rfi_Are_you_currently_studying_with_us__c+'*******'+existingStudent);

        if(thelead.rfi_Are_you_currently_studying_with_us__c == 'Yes') {
            existingStudent = 'Yes';
        }
        else {
            existingStudent  = 'No';
            thelead.rfi_What_is_your_query_about__c = '';
            thelead.rfi_Query_Notes__c = '';
            //thelead.rfi_What_are_you_Studying__c = '';
            thelead.SRN__c = '';            
        }
        return null;
    }

    public PageReference bookNewCourse() {
       system.debug('******************'+thelead.rfi_What_is_your_query_about__c+'*******');

        if(thelead.rfi_What_is_your_query_about__c == 'Booking a New Course') {
            existingStudent = 'No';
            bookNewCourse = True;
            
            system.debug('*******values*******'+queryVal+ ' '+queryNotes +' '+study+ ' '+srn);
        }
        return null;
    }
    
    public PageReference reloadCourseField() {    
        return null;
    }
    
    //getters and setters
    public RecordType rt {get;set;}   
    public Lead thelead {get;set;}
    public String existingStudent {get; set;}

   
    public String levelOfStudyVal {get; set;}
    public String textData;
    public String queryVal {get; set;}
    public String queryNotes {get; set;}
    public String srn {get; set;}
    public String study {get; set;}
    public List<Lead> leadList;
    public List<country_list__c> countryList;
    public List<country_list__c> countryInitList;    
    public Boolean startDateFlag;    
    
    //country_list__c uk = [Select uk.Name, uk.Id, uk.ISO_Code__c From country_list__c uk where Name = 'United Kingdom'];
    
  // button methods
    public pageReference save() {
        thelead.Rfi_Level_of_study__c = selectedLevel0;
        thelead.rfi_Area_of_Interest__c = selectedLevel1;
        thelead.rfi_Course_of_Interest__c = selectedLevel2;           
        startDateFlag = False;       
        PageReference pr;
        string year; //= String.valueOf(system.today().year());
        if(thelead.rfi_start_year__c != null) {
            year = thelead.rfi_start_year__c;
        }      
        string month; //= String.valueOf(system.today().month());
        if(thelead.rfi_start_month__c != null) {
            month = thelead.rfi_start_month__c;
        }      
       
        Date applicationStartDate;
       
        if(thelead.rfi_start_month__c != null && thelead.rfi_start_year__c != null) {
            Integer y = integer.valueOf(year);
            Integer m = integer.valueOf(month);
            Integer days = date.daysInMonth(y, m);
            string day = String.valueOf(days);
            string stringDate = year + '-' + month + '-' + day;
            Date courseStartDate = date.valueOf(stringDate);      
            applicationStartDate = date.valueOf(year + '-' + month + '-' + '01');
              
            if(courseStartDate < system.Today()) {
                startDateFlag = True;
            }
        }     
       
        if(thelead.firstname == Null  || thelead.firstname == ''  || thelead.lastname == Null || thelead.lastname == '' || thelead.email == Null || thelead.email == '' ||  thelead.phone == '' || 
            //(existingStudent == 'No' && thelead.PostalCode == null) || 
            //(existingStudent == 'No' && thelead.PostalCode == '') ||
            //(existingStudent == 'No' && thelead.country == null) || 
            //(existingStudent == 'No' && thelead.country == '') ||
            thelead.rfi_Are_you_EU_UK__c == Null || 
            thelead.rfi_Are_you_EU_UK__c == '' || 
           (existingStudent == 'No' && thelead.rfi_Area_of_Interest__c == '') || 
           (existingStudent == 'No' && thelead.rfi_Area_of_Interest__c == Null) ||
           (existingStudent == 'Yes' && thelead.srn__c == '') ||   
           (existingStudent == 'Yes' && thelead.srn__c == Null) ||
           (existingStudent == 'Yes' && thelead.rfi_What_are_you_Studying__c == '') ||   
           (existingStudent == 'Yes' && thelead.rfi_What_are_you_Studying__c == Null)       
           ){
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL,'*'));
        } 
        else if(thelead.rfi_How_did_you_hear_about_us__c == null && thelead.rfi_Are_you_currently_studying_with_us__c == 'No') {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL,'How did you hear about us?: You must enter a value'));          
        } 
        else if(startDateFlag == True) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL,'Please enter a valid future start date(Month/Year)'));          
        } 
        else if(thelead.Country__c == countryInitList[0].Id && thelead.PostalCode == null) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL,'Postcode is required for UK students')); 
        }
        else if (existingStudent == 'No' && thelead.RFI_Course_of_Interest__c == null && isCoursePicklistEmpty == false)
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL,'You must select a Course of Interest'));          
        else {
            if(thelead.rfi_Are_you_currently_studying_with_us__c == 'Yes' && existingStudent == 'No') {
                thelead.rfi_What_is_your_query_about__c = queryVal;
                thelead.rfi_Query_Notes__c = queryNotes;
                thelead.SRN__c = srn;           
            }
            if(applicationStartDate != null) {
               thelead.Anticipated_Start_Date__c = applicationStartDate;
            }           
            if(existingStudent == 'Yes' && thelead.rfi_What_are_you_Studying__c != null) {
               thelead.Rfi_Level_of_study__c = thelead.rfi_What_are_you_Studying__c;
            }  
            leadList = new List<Lead>();
            if(thelead.srn__c != null && thelead.srn__c != '') {               
               leadList = [Select rfi_What_are_you_Studying__c from Lead where srn__c =: thelead.srn__c];
            }
            thelead.rfi_are_you_a__c = thelead.rfi_Are_you_EU_UK__c;
           
            if(thelead.phone != null) {
               thelead.Preferred_Phone__c = 'Home';
               thelead.Home_Phone__c = thelead.Phone;           
            }
           
            if(thelead.Email != null) {
               thelead.Preferred_Email__c = 'Work';
               thelead.Personal_Email__c = thelead.Email;
            }
           
            if(thelead.Country__c != null) {
               country_list__c c = [Select c.Name, c.Id, c.ISO_Code__c From country_list__c c where id =: thelead.Country__c];
               //thelead.Country_of_Residence__c = c.Name;
               thelead.Country_of_Residence__c = c.Id;
            }
           
            if(thelead.RFI_Opt_In__c == True) {
               thelead.RFI_Opt_In__c = False;
               thelead.HasOptedOutOfEmail = True;
               thelead.Phone_Opt_Out__c = True;
               thelead.Mail_Opt_Out__c = True;
               thelead.Text_Message_Opt_Out__c = True;               
            }
            Boolean s  = False;
            try {
                Database.DMLOptions dmo = new Database.DMLOptions();
                dmo.assignmentRuleHeader.useDefaultRule= true;
                thelead.setOptions(dmo);
                Database.UpsertResult upsertResults = Database.upsert(thelead);
                if(upsertResults.isSuccess() == true) {
                    s =true;
                }
            }catch(DMLException ex) {
                ApexPages.addMessages(ex);
            }           
               
            //Insert new address record, only postal code and country are captured on RFI            
            Address__c ad = new Address__c(Lead__c = thelead.Id);
            ad.Zip_Postal_Code__c = thelead.PostalCode;
            ad.Lookup_Country__c = thelead.Country__c;
            //ad.Street_1__c = thelead.Street;
            //ad.Lookup_State__c = thelead.State__c;
            //ad.City__c = thelead.City;
            ad.Type__c = 'Mailing'; 
            ad.Active__c = true;
            insert ad;
            //boolean isDupe = RFIDupeCheck.checkleadForDupe(thelead);                   
                              
            if(s == true) { 
                Lead l = [Select id,Name, ownerid, owner.name, rfi_Are_you_currently_studying_with_us__c,rfi_Area_of_Interest__c,
                                 rfi_Course_of_Interest__c,rfi_Are_you_EU_UK__c,Rfi_Level_of_study__c from Lead where id=: thelead.id];
                list<RFI_Routing__c> assignmentList = new list<RFI_Routing__c>();
                if(bookNewCourse == True) {                              
                    assignmentList = [Select id, create_task__c, Destination_queue__c, Destination_Role__c, Destination_user__c,
                                             Department__c from RFI_Routing__c 
                                       where rfi_Are_you_currently_studying_with_us__c = 'No' and
                                             rfi_Area_of_Interest__c =: l.rfi_Area_of_Interest__c and                                  
                                             RFI_Course_of_Interest__c =: l.RFI_Course_of_Interest__c and 
                                             are_you_eu_uk__c =: l.rfi_Are_you_EU_UK__c and 
                                             Rfi_Level_of_study__c =: l.Rfi_Level_of_study__c limit 1];     
                } 
                else {
                    assignmentList = [Select id, create_task__c, Destination_queue__c, Destination_Role__c, Destination_user__c,
                                             Department__c from RFI_Routing__c 
                                       where rfi_Are_you_currently_studying_with_us__c =: l.rfi_Are_you_currently_studying_with_us__c and
                                             rfi_Area_of_Interest__c =: l.rfi_Area_of_Interest__c and                                  
                                             RFI_Course_of_Interest__c =: l.RFI_Course_of_Interest__c and 
                                             are_you_eu_uk__c =: l.rfi_Are_you_EU_UK__c and 
                                             Rfi_Level_of_study__c =: l.Rfi_Level_of_study__c limit 1];     
                }
                system.debug('l.rfi_Are_you_currently_studying_with_us__c: ' + l.rfi_Are_you_currently_studying_with_us__c);
                system.debug('l.rfi_Area_of_Interest__c: ' + l.rfi_Area_of_Interest__c);
                system.debug('l.RFI_Course_of_Interest__c: ' + l.RFI_Course_of_Interest__c);
                system.debug('l.rfi_Are_you_EU_UK__c: ' + l.rfi_Are_you_EU_UK__c);
                system.debug('l.Rfi_Level_of_study__c: ' + l.Rfi_Level_of_study__c);
              

                //Round robin Logic                
                system.debug('***************assignmentlist '+assignmentlist);                    

                if(assignmentList.size() > 0) {                
                    Set<ID> userIDSet = new Set<ID>();
                    List<USer> ulist = new List<User>();
                    List<Group> qlist = new List<Group>();  
                    Boolean done = false;                  
                    list<RFI_Owner_Change__c> rfilist = new list<RFI_Owner_Change__c>();
                    rfilist = [Select Name, Userid__c, Destination_Role__c from RFI_Owner_Change__c];
                    
                    if(assignmentList[0].Destination_user__c != null) {
                        l.ownerid = assignmentList[0].Destination_user__c;
                        done = true;                    
                    }
                    if(assignmentList[0].Destination_Queue__c != null && done == false) {
                        qlist = [Select id, Name, DeveloperName from Group 
                                  where Type= 'Queue' and developerName =: assignmentList[0].Destination_Queue__c];
                        if(qlist.size() > 0) {
                            l.ownerid  = qlist[0].id;
                            done = true;                               
                        }                          
                    }                    
                    system.debug('***************qlist '+qlist);                    
                    if(done == false) {                    
                        if(assignmentList[0].Destination_role__c != null) {
                            ulist = [Select Id from User where userrole.developerName =: assignmentList[0].Destination_role__c and isactive = true order by Name];
                        }
                        system.debug('***************ulist '+ulist);                    
                   
                        //ulist = [Select Id from User where userrole.Name =: 'DomesticTeamRecordAssignment' and isactive = true];
                        if(ulist.size() > 0) {
                           for(User u : ulist) {
                               userIDSet.add(u.id);
                            }                    
                        }
                        
                        if(rfilist.size() > 0) {
                            for(RFI_Owner_Change__c r: rfilist) {
                                userIDSet.remove(r.userid__c);
                            }
                        }                 
                        //User u1 = [Select id from user where name = 'Kate Hayes' and isactive = true];                   
                        //userIdset.add(u1.id);  
                        List<AggregateResult> leadList = new List<AggregateResult>();
                        List<User> userlist1 = new List<User>();
                        leadList = [SELECT OwnerId,Owner.Name,  Count(id) FROM Lead where ownerid in:userIDSet and (CreatedDate = TODAY OR Owner_Change_Date__c = TODAY) group by ownerid, Owner.Name order by count(ownerid), Owner.Name];    
                        
                        Set<ID> existingSet = new Set<ID>();
                        if(leadList.size() == 0 && done == false) {
                            if(ulist.size() > 0) {
                                l.ownerid = ulist[0].Id;
                                done = true;
                            }                               
                        }
                        
                        if(leadlist.size() > 0 && done == false) {                            
                            system.debug('***************leadlist '+leadlist);                    

                            for(AggregateResult g : leadList) {
                                existingSet.add((ID)g.get('OwnerId'));
                            }
                        
                            if(existingSet.size() == userIdSet.size()) {
                                l.ownerid = (ID)leadList[0].get('OwnerId');                     
                                done = true;                               
                            } 
                            else {                          
                                for(ID i : existingSet) {
                                    if(userIDSet.contains(i)) { userIDset.remove(i); }                                   
                                }                         
                                list<User> finalUserList = new list<User>();
                                finalUserList = [Select Id, Name from User where Id in: userIDSet order by Name];        
                                if(finalUserList.size() > 0) {
                                    l.ownerid = finalUserList[0].Id;
                                    done = true;
                                }                                                                                                                  
                            }
                        }                            
                    }
                    Database.SaveResult sr;
                    if(done = true) {
                        try {
                            LeadOwnerReassignment.firstRun = false;
                            sr  = database.update(l);
                            system.debug('**********LeadOwnerReassignment.firstRun '+LeadOwnerReassignment.firstRun);
                                                         
                        } catch(DMLException ex1) { System.debug('Exception1    '+ ex1); }             
                    }                  
                    if(assignmentList[0].Create_Task__c == true && done == true && sr.isSuccess() == true) {                 
                        Task t = new Task();
                        t.whoid = l.id;
                        t.ownerid = l.ownerid;
                        t.Subject = 'A New Lead is Assigned to you';                       
                        try {
                            insert t;
                        } catch(DMLException ex){ system.debug('exception '+ex);  }           
                    }
                }               
                pr = new PageReference('/apex/THANKYOURFI'); 
                pr.setRedirect(true);
            }
        }
             
        return pr;
    }
}