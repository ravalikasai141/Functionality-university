public class GetProfileIdController {
    @AuraEnabled
    public static String performProfileIdCallout(Id recordId){
        System.debug('GetProfileIdController performProfileIdCallout recordId: ' + recordId);
        Account account = [SELECT Id, Name, PS_Profile_Services_ID__pc, Phone FROM Account WHERE Id =: recordId]; 
        if (account.PS_Profile_Services_ID__pc != null) {
            return 'Account already has a Profile Services ID.';
        } 
        if (account.Phone != null && account.Phone.length() < 10) {
            return 'Account\'s phone number must contain at least 10 digits.';
        }
        try {
            String result = ProfileIntegrations_v2.ProfileInt_v2(account.Id);
            System.debug('GetProfileIdController performProfileIdCallout result: ' + result);
            return result;
        } catch (Exception e) {
            System.debug('GetProfileIdController performProfileIdCallout catch message: ' + e.getMessage());
            throw new AuraHandledException('GetProfileIdController performProfileIdCallout exception thrown: ' + e.getLineNumber() + ': ' + e.getMessage());    
        }
    }
}