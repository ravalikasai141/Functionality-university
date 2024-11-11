public class LeadOwnerReassignment {

public static Boolean firstRun = true;

public static ID reassignLead(Id leadid, ID userid, String rolename) {

               Lead l = [Select id,Name, ownerid, owner.name, rfi_Are_you_currently_studying_with_us__c,rfi_Area_of_Interest__c,rfi_Course_of_Interest__c,
                        rfi_Are_you_EU_UK__c,Rfi_Level_of_study__c from Lead where id=: leadid];
                    Set<ID> userIDSet = new Set<ID>();
                    List<USer> ulist = new List<User>();
                    List<Group> qlist = new List<Group>();  
                    Set<ID> existingSet = new Set<ID>();
                    Boolean done = false;                  
                    ID newOwnerid ;
                    if(done == false) {                    
                        if(rolename != null) {
                            ulist = [Select Id from User where userrole.developerName =: rolename and isactive = true order by Name];
                        }
                     }   
                        system.debug('***************ulist '+ulist);                    
                   
                        //ulist = [Select Id from User where userrole.Name =: 'DomesticTeamRecordAssignment' and isactive = true];
                        if(ulist.size() > 0) {
                           for(User u : ulist) {
                               if(u.id != userid) {
                                   userIDSet.add(u.id);
                               }
                            }                    
                        }
                        
                        system.debug('useridset.size()' + useridset.size());

                        List<AggregateResult> leadList = new List<AggregateResult>();
                        List<User> userlist1 = new List<User>();
                        leadList = [SELECT OwnerId,Owner.Name,  Count(id) FROM Lead where ownerid in:userIDSet and (CreatedDate = TODAY OR Owner_Change_Date__c = TODAY) group by ownerid, Owner.Name order by count(ownerid), Owner.Name];    
                          
                        if(leadList.size() == 0) {
                             if(ulist.size() > 0) {
                                 l.ownerid = ulist[0].Id;
                                 newOwnerid = ulist[0].Id;
                                 done = true;
                             }                               
                        }
                        
                        system.debug('leadlist.size(): ' + leadlist.size());
                        system.debug('done: ' + done);
                        if(leadlist.size() > 0 && done == false) {                            
                            system.debug('***************leadlist '+leadlist);    
                            for(AggregateResult g : leadList) {
                                existingSet.add((ID)g.get('OwnerId'));
                            }
                            if(existingSet.size() == userIdSet.size()) {                                                
                                l.ownerid = (ID)leadList[0].get('OwnerId');   
                                newOwnerid = (ID)leadList[0].get('OwnerId');                   
                                done = true;
                            }
                             else {
                              for(ID i : existingSet) {
                                   if(userIDSet.contains(i)) { userIDset.remove(i); }
                                   
                                 }                    
                              //List<ID> finalIDList = new List<ID>();
                              //finalIDList.addAll(userIDSet);                         
                               List<User> finalUserList = new List<User>();
                               finalUserList = [Select Id, Name from User where Id in: userIDSet order by Name];        
                               if(finalUserList.size() > 0) {
                                   l.ownerid = finalUserList[0].Id;
                                   newOwnerid = finalUserList[0].Id;
                                   done = true;
                               }                                                                                                                  
                            }
                       }
                       LeadOwnerReassignment.firstRun = false;
                   
                      //Database.SaveResult sr;
                      
                      //if(done = true) {                                                                  
                        // try {
                             //update l;
                            // LeadOwnerReassignment.firstRun = false;
                             //sr  = database.update(l);
                             //if(sr.isSuccess() == True) {
                               //  LeadOwnerReassignment.firstRun = false;
                             //}                             
                        // } Catch(DMLException ex1) { System.debug('Exception1    '+ ex1); }             
                    //}
                    system.debug('**************** '+l.ownerid);
                 //if(thelead.owner.type != 'Queue') 
                   if(done == true) {                 
                       Task t = new Task();
                       t.whoid = l.id;
                       t.ownerid = newOwnerid;
                       t.Subject = 'A New Lead is Assigned to you';                       
                   try {
                       insert t;
                   } Catch(DMLException ex){ system.debug('exception '+ex);  }
                   system.debug('*********************task '+t.owner.Name +'   '+ t);
                   }
                   
       return newOwnerid ;
       
        }


}