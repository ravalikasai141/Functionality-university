public class Booking_OpportunityService {
      public class OpportunityException extends Exception{}
    
    private Booking_AccountService accountService;
    
    private static final String BOOKING_TYPE = 'PE Booking';
    private static final String STAGE = 'In Progress';
    
    public Booking_OpportunityService(Booking_AccountService accountService){
        this.accountService = accountService;
    }
    
    public Opportunity findOpportunityByOrderNumber(String orderNumber, String studentAccountProfileId) {
        Account studentAccount = accountService.getStudentAccountByProfileId(studentAccountProfileId);
        List<Opportunity> opportunities = [Select Id, Order_Number__c from Opportunity where Order_Number__c = :orderNumber and AccountId = :studentAccount.Id];
        if(opportunities.size() > 1)
            throw new OpportunityException('More than one Opportunities were found for Order Number: ' + orderNumber);
        else if (opportunities.size() == 0)
            return null;
        else
        	return opportunities[0];
    }
    
    public Opportunity createOpportunity(String orderNumber, String studentAccountProfileId, Opportunity corpOpp) {
        Account studentAccount = accountService.getStudentAccountByProfileId(studentAccountProfileId);
        Opportunity opportunity = new Opportunity();
        
        RecordType recordTypeId = [select Id from RecordType where Name = :BOOKING_TYPE and SobjectType = 'Opportunity' LIMIT 1];
        
        opportunity.AccountId = studentAccount.Id;
        opportunity.Order_Number__c = orderNumber;
        opportunity.RecordTypeId = recordTypeId.Id;
        opportunity.Name = studentAccount.Name;
        opportunity.CloseDate = Date.today();
        opportunity.StageName = STAGE;
        // WEC: Added check for Coporate opportunity and link to Corp Opp from Student Opp.
        if(corpOpp != null)
        	opportunity.Corporate_Booking__c = corpOpp.Id;
        insert opportunity;
        return opportunity;
    }
    
    /***********************************************************************
	* Creates a corporate opportunity 
	*
	* orderNumber 		: Order number that is passed in.
	* tMProfileId		: Training manager profile id passed into service.
	* companyProfileId	: Company Profile ID passed into web Service.
	* companyAccount	: Company Account
	*
	* @author WEC bill.corrie@apollo.edu
	* @returns Opportunity sObject
	***********************************************************************/
    public Opportunity createCorporateOpportunity(String orderNumber, String tMProfileId, String companyProfileId, String companyOppName) {
        Opportunity opportunity = new Opportunity();
        
        // Lookup Corporate Opportunity type
        //RecordType recordTypeId = [select Id from RecordType where Name = 'Corporate Booking' and SobjectType = 'Opportunity' LIMIT 1];
        
        // Look up Training Manager Contact by Profile ID
        Contact tManager = accountService.getTraingingManagerByProfile(tMProfileId,companyProfileId);
        
        // Lookup the Company Account
        Account oppAccount = Util.findCompanyAccountByProfile(companyProfileId);
        
        
        // Fill in the Corporate Opp fields
        if(oppAccount!=null)
			opportunity.AccountId = oppAccount.Id;
		else
			throw new OpportunityException('No Company found for Profile ID: ' + companyProfileId);
        
        if(companyOppName!=null)
        {
	        opportunity.Name = companyOppName;
        }else
	        throw new OpportunityException('No Opportunity available. ');        
	        
        if(tManager!=null)
        	opportunity.Training_Manager__c = tManager.Id;
        else
	        throw new OpportunityException('No Training Manager found for Profile ID: ' + tMProfileId);        
        opportunity.Order_Number__c = orderNumber;
        //opportunity.RecordTypeId = recordTypeId.Id;
        opportunity.CloseDate = Date.today();
        opportunity.StageName = STAGE;
        
        // Insert Opp
        insert opportunity;
        
        //Return newly created Opp
        return opportunity;
    }
}