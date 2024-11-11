/**
 * Batch job to create Student Courses from Opportunities
 */
global class StudentCoursesOppBatch implements Database.Batchable<SObject> {
    /**
     * Queries all opportunities where status is confirmed
     * @param bc BatchableContext
     * @return  Database QueryLocator
     */
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(
            [
                SELECT Id, accountId
                FROM Opportunity
                WHERE
                    Course_Instance__c != NULL
                    AND RecordType.DeveloperName IN ('Student_Application', 'Locked_Application')
                    AND StageName IN (
                        'Accepted - Pmt Received',
                        'Accepted - Conditional Firm',
                        'Accepted - Unconditional Firm',
                        'Degree Apprenticeship'
                    )
            ]
        );
    }

    /**
     * Creates student courses where they do not already exist
     * @param bc Batchable Context
     * @param opportunities List of opportunities
     */
    public void execute(Database.BatchableContext bc, List<Opportunity> opportunities) {
        StreamingService.preventStream = true;

        Set<Id> createdOpportunities = new Set<Id>();
        Set<Id> opportunityIds = new Set<Id>();

        for (Opportunity opp : opportunities) {
            opportunityIds.add(opp.Id);
        }

        for (Student_Course__c course : [
            SELECT Opportunity__c
            FROM Student_Course__c
            WHERE Opportunity__c IN :opportunityIds
        ]) {
            createdOpportunities.add(course.Opportunity__c);
        }

        List<Student_Course__c> toInsert = new List<Student_Course__c>();

        for (Opportunity opportunity : opportunities) {
            if (createdOpportunities.contains(opportunity.Id)) {
                continue;
            }

            toInsert.add(new Student_Course__c(Student__c = opportunity.accountId, Opportunity__c = opportunity.Id));
        }

        if (!toInsert.isEmpty()) {
            insert toInsert;
        }
    }

    public void finish(Database.BatchableContext bc) {
    }
}
