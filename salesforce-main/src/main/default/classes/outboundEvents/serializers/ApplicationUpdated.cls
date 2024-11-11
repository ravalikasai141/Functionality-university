/**
 * Handles events where a BPP Admin has updated an application during the
 * BPP Review stage
 */
public without sharing class ApplicationUpdated implements Serializer {
    /**
     * Set of opportunity ids given from addRecord when record is Opportunity
     */
    public Set<Id> opportunityIds;

    /**
     * List of Applications to be processed
     */
    private List<Opportunity> opportunities;

    /**
     * Default Construct
     */
    public ApplicationUpdated() {
        opportunityIds = new Set<Id>();
        opportunities = new List<Opportunity>();
    }

    /**
     * Extracts either AccountId or OpportunityId from given records
     * @param record The record to be processed
     */
    public void addRecord(SObject record) {
        switch on record.getSObjectType().getDescribe().getName() {
            when 'Opportunity' {
                opportunityIds.add(record.Id);
            }
        }
    }

    /**
     * Builds the expected payload for the event
     * @return  Payload for the given records
     */
    public List<Map<String, Object>> serialize() {
        List<Map<String, Object>> payloads = new List<Map<String, Object>>();

        fetchOpportunities();

        for (Opportunity opp : opportunities) {
            String productId = opp.Course_Instance__r?.Instance_Id__c;

            if (!String.isBlank(productId)) {
                productId = 'PCV2-' + productId;
            }

            Map<String, Object> payload = new Map<String, Object>{
                'applicationId' => opp.Application_Id__c,
                'productId' => productId,
                'updatedBy' => opp.LastModifiedBy.Name,
                'product' => new Map<String, Object>{ 'startOn' => opp.Start_Date__c, 'endOn' => opp.End_Date__c },
                'employerInformation' => new Map<String, Object>{
                    'lineManagerInformation' => new Map<String, Object>{
                        'firstName' => opp.Line_Manager_First_Name__c,
                        'lastName' => opp.Line_Manager_Last_Name__c,
                        'jobTitle' => opp.Line_Manager_Job_Title__c,
                        'emailAddress' => opp.Line_Manager_Email__c,
                        'mobilePhone' => opp.Line_Manager_Telephone__c
                    },
                    'companyInformation' => new Map<String, Object>{
                        'companyName' => opp.Sponsoring_Organization__c,
                        'line1' => opp.Company_Street_1__c,
                        'line2' => opp.Company_Street_2__c,
                        'line3' => opp.Company_Street_3__c,
                        'city' => opp.Company_City__c,
                        'postalCode' => opp.Company_Zip_Postal_Code__c,
                        'country' => new Map<String, Object>{
                            'code' => opp.Company_Lookup_Country__r?.Country_Code_2__c
                        }
                    },
                    'role' => new Map<String, Object>{
                        'jobTitle' => opp.Job_Title_Apprentice__c,
                        'jobDescription' => opp.Job_Description_Apprentice__c,
                        'safetyQueryKnowledge' => opp.Safety_Knowledge_Apprentice__c,
                        'jobStartDate' => opp.Job_Started_On_Apprentice__c,
                        'weeklyContractedHours' => opp.Weekly_Contracted_Hours_Apprentice__c,
                        'overallOffTheJobTrainingHours' => opp.OOTJTH_Preserved__c
                    }
                }
            };

            payloads.add(payload);
        }

        return payloads;
    }

    /**
     * Uses the extracted identifiers from addRecord to fetch Opportunities
     * related to the changes
     */
    private void fetchOpportunities() {
        for (Opportunity opp : [
            SELECT
                AccountId,
                Application_Id__c,
                Course_Instance__r.Instance_ID__c,
                Job_Started_On_Apprentice__c,
                Weekly_Contracted_Hours_Apprentice__c,
                Sponsoring_Organization__c,
                Company_Street_1__c,
                Company_Street_2__c,
                Company_Street_3__c,
                Company_Zip_Postal_Code__c,
                Company_City__c,
                Line_Manager_Job_Title__c,
                Line_Manager_First_Name__c,
                Line_Manager_Last_Name__c,
                Line_Manager_Email__c,
                Line_Manager_Telephone__c,
                Company_Lookup_Country__r.Country_Code_2__c,
                Start_Date__c,
                End_Date__c,
                LastModifiedBy.Name,
                Safety_Knowledge_Apprentice__c,
                Job_Description_Apprentice__c,
                Job_Title_Apprentice__c,
                OOTJTH_Preserved__c
            FROM Opportunity
            WHERE Id IN :opportunityIds AND (StageName = 'BPP Review' OR StageName = 'Acceptance')
        ]) {
            opportunities.add(opp);
        }
    }
}
