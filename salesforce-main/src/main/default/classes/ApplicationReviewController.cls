public without sharing class ApplicationReviewController {
    /**
     * Moves the opportunity into In Progress sub stage which allows
     * a review to take place
     * @param opportunityId The related opportunity
     */
    @AuraEnabled
    public static void startReview(String opportunityId) {
        try {
            update new Opportunity(
                Id = opportunityId,
                StageName = 'BPP Review',
                BPP_Sub_Status__c = 'In Progress',
                OwnerId = UserInfo.getUserId()
            );
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
     * Moves an opportunity to In progress where it is in the Acceptance stage
     * @param opportunityId The related opportunity
     */
    @AuraEnabled
    public static void startFinalReview(String opportunityId) {
        try {
            Opportunity opp = [
                SELECT BPP_Sub_Status__c
                FROM Opportunity
                WHERE Id = :opportunityId
            ];
            opp.BPP_Sub_Status__c = 'In Progress';
            update opp;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
     * Fetches the home address related to an Application
     * @param accountId The account related to the application
     * @return  The ID of the Home Address
     */
    @AuraEnabled(cacheable=true)
    public static Id getHomeAddress(String accountId) {
        try {
            Address__c address = [SELECT Id FROM Address__c WHERE Student__c = :accountId AND Type__c = 'Home'];

            return address.Id;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
     * Submits a review against the given application
     * @param opportunityId The related application
     * @param comment The feedback comment if present
     * @param feedbackRequired A boolean to determine
     */
    @AuraEnabled
    public static void submitReview(String opportunityId, String comment, Boolean feedbackRequired) {
        try {
            // Create feedback record
            Application_Review__c review = new Application_Review__c(
                Application__c = opportunityId,
                Feedback_Required__c = feedbackRequired,
                Comment__c = comment
            );

            insert review;

            // Update opportunity
            Opportunity opp = [
                SELECT Line_Manager__c, StageName, BPP_Sub_Status__c
                FROM Opportunity
                WHERE Id = :opportunityId
            ];

            if (opp.Line_Manager__c == null && !feedbackRequired) {
                throw new SObjectException('A Line manager is required before this application can be pre-approved.');
            }

            if (feedbackRequired) {
                opp.BPP_Sub_Status__c = 'Awaiting Information';
            } else {
                opp.StageName = 'Line Manager Review';
                opp.BPP_Sub_Status__c = 'In Progress';
            }

            update opp;
        } catch (DmlException e) {
            throw new AuraHandledException(e.getDmlMessage(0));
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
     * Updates the given Opportunities Start and End Date to the given values and sets the OOTJTH Preserved field if applicable
     * to null allowing it to be re-calculated if applicable
     * @param opportunityId The related application
     */
    @AuraEnabled
    public static void updateOpportunityProductDates(String opportunityId) {
        try {
            Opportunity oppToUpdate = [
                SELECT
                    Id,
                    StageName,
                    OOTJTH_Calculated__c,
                    Course_Instance__r.Start_Date__c,
                    Course_Instance__r.End_Date__c
                FROM Opportunity
                WHERE Id = :opportunityId
            ];

            oppToUpdate.Start_Date__c = oppToUpdate.Course_Instance__r.Start_Date__c;
            oppToUpdate.End_Date__c = oppToUpdate.Course_Instance__r.End_Date__c;

            if (oppToUpdate.StageName == 'BPP Review' || oppToUpdate.StageName == 'Acceptance') {
                oppToUpdate.OOTJTH_Preserved__c = oppToUpdate.OOTJTH_Calculated__c;
            }

            update oppToUpdate;
        } catch (DmlException e) {
            throw new AuraHandledException(e.getDmlMessage(0));
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
     * Submits the final review
     * @param opportunityId The opportunity id
     * @param comment the comment associated with the final review
     */
    @AuraEnabled
    public static void submitFinalReview(String opportunityId, String comment, Boolean awaitingInformation) {
        try {
            if (!String.isEmpty(comment)) {
                Application_Review__c review = new Application_Review__c(
                    Application__c = opportunityId,
                    Feedback_Required__c = false,
                    Comment__c = comment
                );

                insert review;
            }

            Opportunity opp = [
                SELECT BPP_Sub_Status__c, Authoriser__c, AuthorisedOn__c
                FROM Opportunity
                WHERE Id = :opportunityId
            ];

            if (awaitingInformation) {
                opp.BPP_Sub_Status__c = 'On Hold';
            } else {
                opp.BPP_Sub_Status__c = 'Completed';
                opp.Authoriser__c = UserInfo.getUserId();
                opp.AuthorisedOn__c = DateTime.now();
            }

            update opp;
        } catch (DmlException e) {
            throw new AuraHandledException(e.getDmlMessage(0));
        } catch (Exception e) {
            throw new AuraHandledException(
                'Unable to submit final review, please try again or contact an administrator if this persists'
            );
        }
    }

    @AuraEnabled
    public static String autoPopulateReview() {
        try {
            return [SELECT Id, Body FROM StaticResource WHERE Name = 'BPP_Review_Feedback'].Body.toString();
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}
