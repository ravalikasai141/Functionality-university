public with sharing class HubAccountPasswordReset {
    @InvocableMethod(label='Hub Password Reset')
    public static List<HubAccountUpdateHelper> getResult(List<String> inputList) {
        List<HubAccountUpdateHelper> resultList = hubPasswordReset(inputList);
        return resultList;
    }

    private static List<HubAccountUpdateHelper> hubPasswordReset(List<String> inputList) {
        System.debug(inputList);
        HubAccountUpdateHelper response = new HubAccountUpdateHelper();
        List<HubAccountUpdateHelper> responseWrapper = new List<HubAccountUpdateHelper>();
        String auth0Id;

        if (inputList.size() == 1) {
            for (String str: inputList) {
                String[] getIndividualStr = str.split(',');
                auth0Id = getIndividualStr[0];
            }

            if (auth0Id != NULL && auth0Id.length() > 0) {
                Hub_Account__c hubAccount = [SELECT Auth0_Id__c, Hub_Username__c FROM Hub_Account__c WHERE Auth0_Id__c =: auth0Id];
                hubAccount.Last_Password_Reset_Email_Sent__c = System.now();

                if (!hubAccount.Hub_Username__c.contains('@my.bpp.com')) {
                    HubAccountPasswordResetCallout passwordResetCallout = new HubAccountPasswordResetCallout();
                    String result = passwordResetCallout.hubPasswordReset(hubAccount);
                    response.outputString = result;
                } else {
                    response.outputString = '\nError: Unfortunately, "my.bpp.com" email addresses cannot be updated via this method.';
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