@isTest
public with sharing class ApplicationSchemaTest {
    @isTest
    static void itShouldSetValuesOnSchema() {
        // GIVEN test data
        String applicationId = '70038b9e-9c61-47c1-a7c7-15013ccf48d1';
        String applicantId = '6B29FC40-CA47-1067-B31D-00DD010662DA';

        // AND a ApplicationSchema
        ApplicationSchema schema = new ApplicationSchema();

        Test.startTest();

        // WHEN values are set on the schema
        schema.applicationId = applicationId;
        schema.applicantId = applicantId;

        Test.stopTest();

        // THEN the schema values have been set
        Assert.areEqual(applicationId, schema.applicationId);
        Assert.areEqual(applicantId, schema.applicantId);
    }
}
