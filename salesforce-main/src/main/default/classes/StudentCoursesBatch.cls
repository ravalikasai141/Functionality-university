/**
 * Batch job to create Student Courses from existing Booking objects
 */
global class StudentCoursesBatch implements Database.Batchable<SObject> {
    /**
     * Queries all bookings where status is confirmed
     * @param bc BatchableContext
     * @return  Database QueryLocator
     */
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(
            [
                SELECT Id, Student__c, Instance__r.Qualification__c
                FROM Booking__c
                WHERE
                    Status__c = 'Confirmed'
                    AND RecordTypeId = :Schema.SObjectType.Booking__c.getRecordTypeInfosByName()
                        .get('Booking')
                        .getRecordTypeId()
                    AND Instance__c != NULL
                    AND Student__c != NULL
            ]
        );
    }

    /**
     * Creates student courses where they do not already exist
     * @param bc Batchable Context
     * @param bookings List of bookings
     */
    public void execute(Database.BatchableContext bc, List<Booking__c> bookings) {
        StreamingService.preventStream = true;

        Set<String> uniqueQualification = new Set<String>();
        Set<Id> createdBookings = new Set<Id>();
        Set<Id> studentIds = new Set<Id>();

        for (Booking__c booking : bookings) {
            studentIds.add(booking.Student__c);
        }

        for (Student_Course__c course : [
            SELECT Booking__c, Student__c, Qualification__c
            FROM Student_Course__c
            WHERE Student__c IN :studentIds
        ]) {
            createdBookings.add(course.Booking__c);
            uniqueQualification.add(course.Student__c + course.Qualification__c);
        }

        List<Student_Course__c> toInsert = new List<Student_Course__c>();

        for (Booking__c booking : bookings) {
            String compoundKey = booking.Student__c + booking.Instance__r.Qualification__c;

            if (createdBookings.contains(booking.Id) || uniqueQualification.contains(compoundKey)) {
                continue;
            }

            uniqueQualification.add(compoundKey);
            toInsert.add(new Student_Course__c(Student__c = booking.Student__c, Booking__c = booking.Id));
        }

        if (!toInsert.isEmpty()) {
            insert toInsert;
        }
    }

    public void finish(Database.BatchableContext bc) {
    }
}
