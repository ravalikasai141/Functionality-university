public without sharing class BookingUsageBatch implements Schedulable, Database.Batchable<sObject>, Database.Stateful 
{
    
    public Map<Id, List<String>> userIdToErrors;
    public BookingUsageBatch_Input__c input;
    public String query;
    public BookingUsageGenerator.GenerationResult results;
	List<BookingUsageGenerator.GenerationResult> allResultList = new List<BookingUsageGenerator.GenerationResult>();
    public static Map<String, String> fieldMapping = new Map<String, String>{ 
        'Id'                        => 'Booking_Line__c',
        'blng_Account__c'           => 'blng__Account__c',
        'blng_Order__c'             => 'blng__Order__c',
        'blng_OrderProduct__c'      => 'blng__OrderProduct__c',
        'blng_MatchingId__c'        => 'blng__MatchingId__c',
        'blng_StartDateTime__c'     => 'blng__StartDateTime__c',
        'blng_EndDateTime__c'       => 'blng__EndDateTime__c',
        'Booking__c'                => 'Booking__c',
        'Student__c'                => 'Student__c',
        'Instance__c'               => 'Instance__c',
        'Session__c'                => 'Session__c',
        'Rev_Rec_Date__c'           => 'Rev_Rec_Date__c',
        'PO_Number__c'              => 'PO_Number__c',
        'Booking__r.OwnerId'        => 'OwnerId'
    };
    
    public BookingUsageBatch() {
        System.debug('CONSTRUCTOR 1');
        input = BookingUsageBatch_Input__c.getOrgDefaults();
        this.userIdToErrors = new Map<Id, List<String>>();
        
        query = 'SELECT Id, blng_Account__c, blng_Order__c, blng_OrderProduct__c, blng_MatchingId__c, blng_StartDateTime__c, blng_EndDateTime__c, Booking__c, Student__c, Instance__c, Session__c, Rev_Rec_Date__c, PO_Number__c, Booking__r.OwnerId FROM Booking_Line__c WHERE On_Hold__c = \'Confirmed\' AND blng_OrderProduct__r.Product2.SBQQ__ChargeType__c = \'Usage\' AND Batch_Processed__c = FALSE AND Batch_failed__c = FALSE AND blng_Account__r.Billing_Type__c = \'In Arrears\' AND ((blng_Account__r.Charge_Trigger__c = \'Instance Start Date\' AND Instance_Start_Date__c <= TODAY) OR (blng_StartDateTime__c <= TODAY AND BPP_Is_Material_Booking__c = true) OR (blng_Account__r.Charge_Trigger__c = \'Booking Confirmed Date\' AND Booking__r.Booking_Confirmed_Date__c = TODAY))';
        System.debug('query : ' + query);
    }
    
    public BookingUsageBatch(date startedDate, date endedDate){
        
        System.debug('CONSTRUCTOR 2');
        Datetime endedDateTime = endedDate;
        String endedDateFormated = endedDateTime.format('YYYY-MM-dd');
        
        Datetime startedDateTime = startedDate;
        String startedDateFormated = startedDateTime.format('YYYY-MM-dd');
        
        input = BookingUsageBatch_Input__c.getOrgDefaults();
        String fieldsInput = String.join(new List<String>(fieldMapping.keySet()), ',');
        String statusInput = '\''+'Confirmed'+'\'';
        String customerBillingType = '\''+'In Arrears'+'\'';
        String chargeType = '\''+'Usage'+'\'';

        this.userIdToErrors = new Map<Id, List<String>>();
        query = String.format('SELECT {0} FROM Booking_Line__c WHERE On_Hold__c = {1} AND Batch_failed__c = TRUE AND Batch_failure_date__c >= {2} AND Batch_failure_date__c <= {3} AND blng_Account__r.Billing_Type__c = {4} AND blng_OrderProduct__r.Product2.SBQQ__ChargeType__c = {5}',
                                new List<String>{fieldsInput, statusInput,startedDateFormated,endedDateFormated, customerBillingType, chargeType}); 
        System.debug('query : ' + query);
    }
    
    public BookingUsageBatch(date selectedDate){
        
        System.debug('CONSTRUCTOR 3');
        Datetime selectedDateTime = selectedDate;
        String selectedDateFormated = selectedDateTime.format('YYYY-MM-dd');

        input = BookingUsageBatch_Input__c.getOrgDefaults();
        String fieldsInput = String.join(new List<String>(fieldMapping.keySet()), ',');
        String statusInput = '\''+'Confirmed'+'\'';
        String customerBillingType = '\''+'In Arrears'+'\'';
        String chargeType = '\''+'Usage'+'\'';

        this.userIdToErrors = new Map<Id, List<String>>();
        query = String.format('SELECT {0} FROM Booking_Line__c WHERE On_Hold__c = {1} AND Batch_failed__c = TRUE AND Batch_failure_date__c = {2} AND blng_Account__r.Billing_Type__c = {3} AND blng_OrderProduct__r.Product2.SBQQ__ChargeType__c = {5}',
                                new List<String>{fieldsInput, statusInput,selectedDateFormated, customerBillingType, chargeType}); 
        system.debug(query);
    }

    //Execute of schedulable interface
    public void execute(SchedulableContext SC) 
    {
        Database.executeBatch(this, 1);
    }

    public Database.QueryLocator start(Database.BatchableContext BC)
    {
        Database.QueryLocator QL = Database.getQueryLocator(query);
        System.debug('QL : ' + QL);
        return QL;
    }

    public void execute(Database.BatchableContext BC, List<sObject> scope)
    {
        System.debug('scope : ' + json.serialize(scope));
        results = BookingUsageGenerator.generateUsages(scope);
        System.debug('execute finish !!! ' + results);
        allResultList.add(results);
    }
    
    public void finish(Database.BatchableContext BC)
    {
		
        System.debug('get all results !!! ' +allResultList);        
        System.debug('input finish : ' + JSON.serialize(input));
        
        input.Last_run__c = Datetime.now();
        try{
            
            update input;
            
        }catch(DMLException e){
            system.debug('error msg : ' + e.getMessage());
        }
        
        //Send Email with CSV File
        Integer nbrUsageSuccess = 0;
        Integer nbrUsageFailed = 0;
        String headerCsv = 'Booking Line Id, isSuccess, Errors, Booking Usage Id \n';
        String finalCsv = headerCsv;
        String corpsCsv;
        
        if(allResultList != null)
        for(BookingUsageGenerator.GenerationResult result : allResultList) {    
            for(Integer i=0;i < result.bookingUsageSaveResults.size();i++){
                
                if(result.bookingUsageSaveResults[i].isSuccess()){
                    nbrUsageSuccess++;
                    corpsCsv = result.bookingUsageGenerated[i].get('Booking_Line__c')+','+'TRUE'+','+'No Errors'+','+result.bookingUsageSaveResults[i].getId()+'\n';  
                }else{
                    nbrUsageFailed++;
                    String errors = generateStringErrors(result.bookingUsageSaveResults[i].getErrors());
                    corpsCsv = result.bookingUsageGenerated[i].get('Booking_Line__c')+','+'FALSE'+','+errors+','+'NULL'+'\n';
                }
                finalCsv = finalCsv + corpsCsv;
            }
        }
        
        Messaging.SendEmailResult[] sendEmailResults = sendEmailWithCsv(finalCsv,  nbrUsageSuccess,  nbrUsageFailed);
        
        system.debug('Emails sent : '  +  sendEmailResults);
           
    }
    
    private static String generateStringErrors(List<Database.Error> saveResultErrors){
        
        String errors = '';
        String error;
        Integer j = 1;
        for(Database.Error err : saveResultErrors){
            error = 'Error ' +j+ ' : '+err.getMessage()+' || ';
            errors = errors+error;
            j++;
        }
        
        return errors.substringBeforeLast(' || ');
    }
    
    private static Messaging.SendEmailResult[] sendEmailWithCsv(String finalCsv, Integer nbrUsageSuccess, Integer nbrUsageFailed){
        
        Messaging.EmailFileAttachment csvAttc = new Messaging.EmailFileAttachment();
        blob csvBlob = Blob.valueOf(finalCsv);
        string csvname= 'BookingUsageResults.csv';
        csvAttc.setFileName(csvname);
        csvAttc.setBody(csvBlob);
        Messaging.SingleEmailMessage email =new Messaging.SingleEmailMessage();
        String toAddressesLabel = Label.toAddresses_UsageGeneration;
        String[] toAddresses = toAddressesLabel.split(';');
        //String[] toAddresses = new List<String>{'chakib.lemkhantar@nbs-consulting.net'};
        String subject ='Booking Usage Report - '+date.today().format();
        email.setSubject(subject);
        email.setToAddresses( toAddresses );
        String body = '1-Booking usage record success : '+nbrUsageSuccess+'\n'+'2-Booking usage record failed : '+nbrUsageFailed;
        email.setPlainTextBody(body);
        email.setFileAttachments(new Messaging.EmailFileAttachment[]{csvAttc});
        Messaging.SendEmailResult [] r;
        if (!Test.isRunningTest()) {
            r = Messaging.sendEmail(new Messaging.SingleEmailMessage[] {email});
        }
        return r;
    }
}