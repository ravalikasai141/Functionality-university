public without sharing class InstituteBodyTriggerHandler {
    /**
     * Ensures only a unique combination of student and qualification
     * @param bodies List of institute bodies being created/updated
     */
    public static void checkUniqueQualification(List<Institute_Body__c> bodies) {
        Map<Id, Set<String>> studentQualifications = new Map<Id, Set<String>>();
        Set<Id> studentIds = new Set<Id>();
        Set<Id> bodyIds = new Set<Id>();

        for (Institute_Body__c body : bodies) {
            studentIds.add(body.Student__c);
            bodyIds.add(body.Id);
        }

        for (Institute_Body__c body : [
            SELECT Student__c, Institute_Body__c
            FROM Institute_Body__c
            WHERE Student__c IN :studentIds
            AND Id NOT IN :bodyIds
        ]) {
            Set<String> qualifications = new Set<String>();
            if (studentQualifications.containsKey(body.Student__c)) {
                qualifications = studentQualifications.get(body.Student__c);
            }

            qualifications.add(body.Institute_Body__c);
            studentQualifications.put(body.Student__c, qualifications);
        }

        for (Institute_Body__c body : bodies) {
            Set<String> qualifications = studentQualifications.get(body.Student__c);

            if (qualifications == null) {
                continue;
            }

            if (qualifications.contains(body.Institute_Body__c)) {
                body.addError('Institute_Body__c', 'A record already exists for this institute body.');
            }
        }
    }
}
