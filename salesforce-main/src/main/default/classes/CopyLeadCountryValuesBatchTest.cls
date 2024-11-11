@isTest
public class CopyLeadCountryValuesBatchTest {
    @isTest
    static void CopyLeadCountryValuesTest() {
        Id leadRecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByName()
            .get('Prospective Student')
            .getRecordTypeId();

        List<Lead> leadsToInsert = new List<Lead>{
            new Lead(RecordTypeId = leadRecordTypeId, LastName = 'Test LeadPM1', Country_of_Birth_old__c = 'India'),
            new Lead(
                RecordTypeId = leadRecordTypeId,
                LastName = 'Test LeadPM2',
                Country_of_Birth_old__c = 'United Kingdom'
            ),
            new Lead(
                RecordTypeId = leadRecordTypeId,
                LastName = 'Test LeadPM3',
                Country_of_Birth_old__c = 'Brazil',
                Country_of_Residence_old__c = 'Spain'
            )
        };
        insert leadsToInsert;

        insert new List<country_list__c>{
            new country_list__c(Name = 'India', country_code_2__c = 'IN'),
            new country_list__c(Name = 'United Kingdom', country_code_2__c = 'GB'),
            new country_list__c(Name = 'Brazil', country_code_2__c = 'BR'),
            new country_list__c(Name = 'Spain', country_code_2__c = 'ES')
        };

        Test.startTest();

        CopyLeadCountryValuesBatch testBatch = new CopyLeadCountryValuesBatch();
        Database.ExecuteBatch(testBatch, 500);

        Test.stopTest();

        Lead leadResults = [
            SELECT Id, Country_of_Birth__r.Name
            FROM Lead
            WHERE id = :leadsToInsert[2].id
        ];

        System.assertEquals('Brazil', leadResults.Country_of_Birth__r.Name);
    }
}
