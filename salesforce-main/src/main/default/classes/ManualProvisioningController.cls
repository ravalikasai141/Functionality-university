public without sharing class ManualProvisioningController {
    @AuraEnabled
    public static String manualProvision(Id recordId) {
        String error;
        String result;
        Boolean passedValidation = true;

        Opportunity opp = [
            SELECT
                Id,
                StageName,
                Programme_Application__c,
                Account.Email_Address__pc,
                Account.BNR_Banner_ID__pc,
                Account.HUB_Student__c
            FROM Opportunity
            WHERE Id = :recordId
        ];
        if (opp != null) {
            if (
                opp.StageName != 'Accepted - Conditional Firm' &&
                opp.StageName != 'Accepted - Unconditional Firm' &&
                opp.StageName != 'Accepted - Pmt Received'
            ) {
                passedValidation = false;
                error = 'The Opportunity Status must be one of the following:</br>* Accepted - Conditional Firm</br>* Accepted - Unconditional Firm</br>* Accepted - Pmt Received</br>';
            } else if (opp.Programme_Application__c == null) {
                passedValidation = false;
                error = 'The Opportunity must have a value in the "Programme" field.</br>';
            } else if (opp.Account.BNR_Banner_ID__pc == null) {
                passedValidation = false;
                error = 'The related Account must have a value in the "Banner ID" field.</br>';
            } else if (
                opp.Account.Email_Address__pc == null ||
                (opp.Account.Email_Address__pc != null && !opp.Account.Email_Address__pc.contains('@my.bpp.com'))
            ) {
                passedValidation = false;
                error = 'The related Account Email Address must contain "my.bpp.com".</br>';
            } else if (opp.Account.HUB_Student__c != true) {
                passedValidation = false;
                error = 'The related Account must have the "HUB Student" checkbox checked.</br>';
            }

            if (passedValidation) {
                AWSUniversityProvisioningAPICall.awsProvisioningCallout(null, opp.Id);
                result = 'Success';
            }
        }
        return (passedValidation ? result : error);
    }
}
