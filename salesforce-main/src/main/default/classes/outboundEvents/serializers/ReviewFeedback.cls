public without sharing class ReviewFeedback implements Serializer {
    /**
     * A Set of Application Review ids to process
     */
    private Set<Id> reviewIds;

    /**
     * List of Application Ids related to the set of ids
     */
    private List<Application_Review__c> reviews;

    /**
     * Default Construct
     */
    public ReviewFeedback() {
        reviewIds = new Set<Id>();
        reviews = new List<Application_Review__c>();
    }

    /**
     * Adds the given record to the process list
     * @param record The sObject to add to the process list
     */
    public void addRecord(SObject record) {
        switch on record.getSObjectType().getDescribe().getName() {
            when 'Application_Review__c' {
                reviewIds.add(record.Id);
            }
        }
    }

    /**
     * Serializes the list of objects into events
     */
    public List<Map<String, Object>> serialize() {
        List<Map<String, Object>> payloads = new List<Map<String, Object>>();

        fetchReviews();

        for (Application_Review__c review : reviews) {
            Map<String, Object> payload = new Map<String, Object>{
                'applicationId' => review.Application__r.Application_Id__c,
                'currentStage' => 'BPP_REVIEW',
                'currentStageStatus' => 'AWAITING_INFORMATION',
                'applicantFeedback' => new Map<String, Object>{ 'updateRequiredDescription' => review.Comment__c }
            };

            payloads.add(payload);
        }

        return payloads;
    }

    /**
     * Fetch reviews from the given list where feedback is required
     */
    private void fetchReviews() {
        reviews = [
            SELECT Application__r.Application_ID__c, Comment__c
            FROM Application_Review__c
            WHERE Id IN :reviewIds AND Feedback_Required__c = TRUE
        ];
    }
}
