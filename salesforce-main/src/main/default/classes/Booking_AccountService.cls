public class Booking_AccountService {
    public class AccountException extends Exception{}
    public class ContactException extends Exception{}
    
    public Booking_AccountService() {}
    
    public Account getStudentAccountByProfileId(String studentAccountProfileId) {
        List<Account> accounts = [Select Id, Name, PS_Profile_Services_ID__pc from Account where PS_Profile_Services_ID__pc = :studentAccountProfileId];
        if (accounts.size() != 1)
            throw new AccountException('More than one, or no, Student Account was found for Id ' + studentAccountProfileId);
        return accounts[0];
    }
    
    public Account getBusinessAccountByProfileId(String companyAccountProfileId){
         List<Account> accounts = [Select Id, Name, Profile_Company_ID__c from Account where Profile_Company_ID__c = :companyAccountProfileId];
        if (accounts.size() != 1)
            throw new AccountException('More than one, or no, Business Account was found for Id ' + companyAccountProfileId);
        return accounts[0];
    }
    
    public Contact getTraingingManagerByProfile(String trainingManagerProfileId, String companyProfileId) {
        Account companyAccount = getBusinessAccountByProfileId(companyProfileId);
        List<Contact> contacts = [Select Id, PS_Profile_Services_ID__c, AccountId from Contact where PS_Profile_Services_ID__c = :trainingManagerProfileId];
        if(contacts.size() != 1)
            throw new AccountException('More than one, or no, Training Manager was found for Id ' + trainingManagerProfileId);
        Contact trainingManager = contacts[0];
        if(trainingManager.AccountId != companyAccount.Id)
            throw new AccountException('Trainging Manager Id: ' + trainingManagerProfileId + ' Does not belong to Account: ' + companyAccount.Id);
            
        return contacts[0];
    }
}