public without sharing class StudentProductSync implements Serializer {
    /**
     * Set of student ids related to this event
     */
    public Set<Id> studentIds;

    /**
     * A map of Auth0 Id's keyed by Account Id
     */
    private Map<Id, List<String>> authIds;

    /**
     * A map of product payloads keyed by Account Id
     */
    private Map<Id, List<Map<String, Object>>> products;

    public StudentProductSync() {
        studentIds = new Set<Id>();
    }

    /**
     * Creates the student id list
     * @param record The SObject that triggered the event
     */
    public void addRecord(SObject record) {
        // Figure out which Sobject type is being added
        switch on record.getSObjectType().getDescribe().getName() {
            when 'Student_Course__c', 'Hub_Account__c' {
                studentIds.add((Id) record.get('Student__c'));
            }
        }
    }

    /**
     * Collects the user ids and products and builds the payloads
     * @return  List of payloads for event emitter
     */
    public List<Map<String, Object>> serialize() {
        List<Map<String, Object>> payloads = new List<Map<String, Object>>();

        fetchAuthIds();
        fetchStudentCourses();

        // Build payloads
        for (Id studentId : studentIds) {
            if (!authIds.containsKey(studentId)) {
                continue;
            }

            if (!products.containsKey(studentId)) {
                continue;
            }

            Map<String, Object> payload = new Map<String, Object>{
                'userIds' => authIds.get(studentId),
                'products' => products.get(studentId)
            };

            payloads.add(payload);
        }

        return payloads;
    }

    /**
     * Fetches student courses related to the student ids
     */
    private void fetchStudentCourses() {
        products = new Map<Id, List<Map<String, Object>>>();
        Set<String> uniqueStudentProducts = new Set<String>();

        for (Student_Course__c course : [
            SELECT Student__c, Product_Id__c, Instance_Id__c
            FROM Student_Course__c
            WHERE Student__c IN :studentIds
        ]) {
            String compoundKey = course.Student__c + course.Instance_Id__c;

            if (uniqueStudentProducts.contains(compoundKey)) {
                continue;
            }

            List<Map<String, Object>> courses = products.get(course.Student__c);
            if (courses == null) {
                courses = new List<Map<String, Object>>();
            }
            courses.add(
                new Map<String, Object>{ 'productId' => course.Product_Id__c, 'instanceId' => course.Instance_Id__c }
            );

            products.put(course.Student__c, courses);
            uniqueStudentProducts.add(compoundKey);
        }
    }

    /**
     * Fetches the auth ids related to the given student ids
     */
    private void fetchAuthIds() {
        authIds = new Map<Id, List<String>>();

        for (Hub_Account__c hubAccount : [
            SELECT Auth0_Id__c, Student__c
            FROM Hub_Account__c
            WHERE Student__c IN :studentIds AND Auth0_Id__c != NULL AND Student__c != NULL
        ]) {
            List<String> ids = authIds.get(hubAccount.Student__c);

            if (ids == null) {
                ids = new List<String>();
            }

            ids.Add(hubAccount.Auth0_Id__c);
            authIds.put(hubAccount.Student__c, ids);
        }
    }
}
