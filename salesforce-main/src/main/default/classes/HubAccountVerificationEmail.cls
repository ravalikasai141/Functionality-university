public with sharing class HubAccountVerificationEmail {
    @InvocableMethod(label='Send Hub Verification Email')
    public static List<HubAccountUpdateHelper> getResult(List<String> inputList) {
        List<HubAccountUpdateHelper> resultList = sendVerificationEmail(inputList);
        return resultList;
    }

    private static List<HubAccountUpdateHelper> sendVerificationEmail(List<String> inputList) {
        System.debug(inputList);
        HubAccountUpdateHelper response = new HubAccountUpdateHelper();
        List<HubAccountUpdateHelper> responseWrapper = new List<HubAccountUpdateHelper>();

        if (inputList.size() == 1) {
            String auth0Id = inputList[0];

            if (auth0Id != NULL && auth0Id.length() > 0) {
                Hub_Account__c hubAccount = [SELECT Auth0_Id__c, Hub_Username__c, Email_Verified__c FROM Hub_Account__c WHERE Auth0_Id__c =: auth0Id];
                if (!hubAccount.Email_Verified__c) {
                    hubAccount.Last_Verification_Email_Sent__c = System.now();
                    String result = HubAccountVerificationEmailCallout.sendVerificationEmail(hubAccount);
                    response.outputString = result;
                } else {
                    response.outputString = '\nError: Hub Account\'s Email address is already verified.';
                }
            } else {
                if (auth0Id == NULL || auth0Id.length() == 0) {
                    response.outputString = '\nError: Auth0Id value is blank.';
                }
            }
        } else {
            response.outputString = '\nError: Something went wrong!';
        }

        responseWrapper.add(response);
        System.debug(responseWrapper);
        return responseWrapper;
    }
}