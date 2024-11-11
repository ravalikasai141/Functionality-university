public class Booking_SponsorshipService {
  	private Booking_AccountService accountService;
    
    public Booking_SponsorshipService(Booking_AccountService accountService) {
        this.accountService = accountService;
    }
    
    public List<Sponsorship__c> findSponsorshipForOpportunity(String opportunityId) {
        return [Select Id, Company__c, Training_Manager__c, Student__c, Opportunity__c, Active__c from Sponsorship__c where Opportunity__c = :opportunityId];
    }
    
    public List<Sponsorship__c> findSponsorshipForAccount(String studentAccountProfileId) {
        Account studentAccount = accountService.getStudentAccountByProfileId(studentAccountProfileId);
        return [Select Id, Company__c, Training_Manager__c, Student__c, Opportunity__c, Active__c from Sponsorship__c where Student__c = :studentAccount.Id];
    }
    
    public void deactiveSponsorshipsForAccount(String studentAccountProfileId) {
        List<Sponsorship__c> sponsorships = this.findSponsorshipForAccount(studentAccountProfileId);
        
        for(Sponsorship__c sponsor:sponsorships) {
            if(sponsor.Active__c == true){
                sponsor.Active__c = false;
                update sponsor;
            }
        } 
    }
    
    public Sponsorship__c createActiveSponsorship(String studentAccountProfileId, Id opportunityId, String companyProfileId, String trainingManagerProfileId) {
		Account studentAccount = accountService.getStudentAccountByProfileId(studentAccountProfileId);
        Account companyAccount = accountService.getBusinessAccountByProfileId(companyProfileId);
  
    	this.deactiveSponsorshipsForAccount(studentAccountProfileId);
        Sponsorship__c sponsor = new Sponsorship__c();
        sponsor.Active__c = true;
        sponsor.Company__c = companyAccount.Id;
        sponsor.Opportunity__c = opportunityId;
        sponsor.Student__c = studentAccount.Id; 
        if(trainingManagerProfileId != null) {
            Contact trainingManager = accountService.getTraingingManagerByProfile(trainingManagerProfileId, companyProfileId);
            sponsor.Training_Manager__c = trainingManager.Id;
        }
        
        insert sponsor;
        return sponsor;
    }
}