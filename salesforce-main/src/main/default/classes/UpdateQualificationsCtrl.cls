public class UpdateQualificationsCtrl {
    @AuraEnabled
    public static String updateQualifications(String opportunityId) {
        String result;
        if (opportunityId != null) {
            System.debug('@UpdateQualificationsCtrl updateQualifications opportunityId: ' + opportunityId);
            Opportunity opp = [SELECT Id, AccountId FROM Opportunity WHERE Id =: opportunityId];
            try {
                result = UpdateSISPerson.PersonInformation(opp.accountId, opportunityId);
                System.debug('@UpdateQualificationsCtrl updateQualifications result: ' + result);
            } catch (Exception e) {
                System.debug('@UpdateQualificationsCtrl updateQualifications error: ' + e.getMessage());
                throw new AuraHandledException('UpdateQualificationsCtrl updateQualifications error occurred: ' + e.getMessage()); 
            }
        }
        return result;       
    }
}