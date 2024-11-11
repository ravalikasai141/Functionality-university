public class GetCompanyProfileIdController {
	@AuraEnabled
	public static String performCompanyProfileIdCallout(Id recordId) { 
		System.debug('GetCompanyProfileIdController performCompanyProfileIdCallout recordId: ' + recordId);
		Boolean checkError = false;
		String errorMessage = '';
		String result;

		Account acc = [SELECT Id, Profile_Company_ID__c FROM Account WHERE Id =: recordId];
		List<Address__c> addressList = [SELECT Id, Active__c, Type__c, Student__c FROM Address__c WHERE Active__c = true AND Student__c =: recordId AND Type__c = 'Billing']; 	
		if (addressList.size() == 0 && acc.Profile_Company_ID__c == null) {
		   checkError = true;
		   result = 'Account requires at least one active Billing Address.';
		}
		if (acc.Profile_Company_ID__c != null) {
		   checkError = true;
		   result = 'This Account already has a Company Profile ID value.';
		} else if (!checkError && acc.Profile_Company_ID__c == null) {
		   try{
			   result = CreateCompanyProfile.CompanyInformation(acc.Id);
			   System.debug('GetCompanyProfileIdController performCompanyProfileIdCallout result: ' + result);
		   } catch (Exception e) {
			   System.debug('GetCompanyProfileIdController performCompanyProfileIdCallout catch message: ' + e.getMessage());
			   throw new AuraHandledException('Error Exception happend'+e.getMessage());    
		   }
		}
		return result; 
	}
}