public class eventsCallout_AC {
/*
this class forwards data to a soap callout

Chris Roberts

v0.1 Aug, 09, 2011
*/
 //this is the class method constructor 
 public eventsCallout_AC() {
  
 }

 // do the call out
 @Future(callout=true)
 public static void SendTo(List <string> theids) {
    
     //  do select here to create the data to pass to the callout     
     list <campaign> Campaigns = [SELECT Id, Name, Location__r.Name,  Programme__r.Name, IsDeleted, 
     ParentId, Type, RecordTypeId, Status, StartDate, 
     EndDate, ExpectedRevenue, BudgetedCost, ActualCost, ExpectedResponse, NumberSent, IsActive, 
     Description, NumberOfLeads, NumberOfConvertedLeads, NumberOfContacts, NumberOfResponses, 
     NumberOfOpportunities, NumberOfWonOpportunities, AmountAllOpportunities, AmountWonOpportunities, 
     OwnerId, CreatedDate, CreatedById, LastModifiedDate, LastModifiedById, SystemModstamp, 
     LastActivityDate, CampaignMemberRecordTypeId, Start_Time__c, Target_Group__c, Staging_PK__c, 
     Targeted_Faculty__c, Publication__c, Website__c, Billboard_Postcodes__c, Workplace_Company__c, 
     Delivery_Day__c, Delivery_Time__c, Email_Template_Used__c, End_of_Use_Date__c, Campaign_Member_Source__c, 
     Print_Costs__c, Handling_Costs__c, List_Costs__c, Display_Costs__c, Distribution_Costs__c, 
     Design_Costs__c, Web_Costs__c, Fax_Costs__c, SMS_Costs__c, Telemarketing_Costs__c, 
     Trade_Show_Seminar_Costs__c, Total_Costs__c, Email_Fulfilment_Costs__c, Advertising_Costs__c, 
     End_Time__c, Location__c, Location_Address__c, CNID__c, Programme__c, Level__c, School__c 
     FROM Campaign WHERE id in:theids AND RecordType.Name = 'event'];  
                
     for(Campaign CampaignRec : Campaigns ) {   
         String eventId = CampaignRec.Id;
         String eventName = CampaignRec.name; 
         String eventDescription='None';
         
         if (CampaignRec.Description != Null && CampaignRec.Description != ''){
             eventDescription= CampaignRec.Description;
         }
         String eventType = CampaignRec.type;
         String eventProductLevel = CampaignRec.Programme__r.Name;  
         String eventQualification;
         String eventSchool = CampaignRec.School__c;
         string eventMaxCapacity ='0'; // not in sfdc
         string eventCurrentCapacity= '0';// not in sfdc
         //format('yyyy-MM-dd hh:mm.ss');
         string evemtDate ='2001-01-01';
         string evemtTime ='00:00:00';
         string evemtDuration= '01:00:00';
         if (CampaignRec.Start_Time__c !=Null){
             evemtDate = datetime.valueof(CampaignRec.Start_Time__c).format('yyyy-MM-dd') ;       
             evemtTime = datetime.valueof(CampaignRec.Start_Time__c).format('hh:mm:ss');
             // calculate duration
             if( CampaignRec.End_Time__c !=Null){
                 long dur = (CampaignRec.End_Time__c.getTime() - CampaignRec.Start_Time__c.getTime()) ;      
                 evemtDuration = datetime.newInstance(dur).format('hh:mm:ss');
             }
         } 
         
         String evemtLocation = CampaignRec.Location__r.Name;
         String evemtSubLocation = CampaignRec.Location_Address__c;
         //  define the result type
         ApolloglobalComEvents2.EventSOAP callit = new ApolloglobalComEvents2.EventSOAP();
         ApolloglobalComEvents2.Response coResult = callit.AddEvent(eventId,eventName,eventDescription,eventType,eventProductLevel,eventQualification,eventSchool,eventMaxCapacity,eventCurrentCapacity,evemtDate,evemtTime,evemtDuration,evemtLocation, evemtSubLocation);
         System.debug(logginglevel.INFO, '*************** Result message *************** '+coResult.Message+' '+coResult.StatusCode);
 
     }
 } 
 
 //test method(s)
 static testMethod  void EventsCallount_AC_Test1() {   
    User acct = [SELECT Id from User limit 1];
    list<string> testmap = new list<string>();
    testmap.add(acct.id);
    test.starttest();
        //test related classes by creating instances
        eventsCallout_AC evc = new eventsCallout_AC();   
        ApolloglobalComEvents2.Event te = new ApolloglobalComEvents2.Event();
        ApolloglobalComEvents2.Response tr = new ApolloglobalComEvents2.Response();
        ApolloglobalComEvents2.EventSOAP ct = new ApolloglobalComEvents2.EventSOAP();
        SendTo(testmap);
        // ApolloglobalComEvents2.EventSOAP callit = new ApolloglobalComEvents2.EventSOAP();
        // ApolloglobalComEvents2.Response coResult = callit.AddEvent('a','b','c','d','e','f','g',1,1,Date.today(),datetime.now(),datetime.now(),'','');
    test.stoptest();
 } 
  
}