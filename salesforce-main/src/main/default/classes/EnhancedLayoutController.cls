/**
 * Controller class for the EnhancedLayout LWC
 */
public with sharing class EnhancedLayoutController {
    @TestVisible
    private static Map<String, List<LayoutField>> fieldConfig = new Map<String, List<LayoutField>>{
        // Apprentice Application Details
        'Opp_Appr_Details' => new List<LayoutField>{
            new LayoutField('Opportunity', 'Name'),
            new LayoutField('Opportunity', 'StageName'),
            new LayoutField('Opportunity', 'Application_Reference__c'),
            new LayoutField('Opportunity', 'BPP_Sub_Status__c'),
            new LayoutField('Opportunity', 'Application_Date__c'),
            new LayoutField('Opportunity', 'BPP_Cancellation_Reason__c'),
            new LayoutField('Opportunity', 'Resubmission_Date__c'),
            new LayoutField('Opportunity', 'AccountId'),
            new LayoutField('Opportunity', 'Days_In_Current_Sub_Status__c'),
            new LayoutField('Account', 'Account.ULN__pc'),
            new LayoutField('Opportunity', 'Eligibility_Status__c'),
            new LayoutField('Opportunity', 'BD_Opportunity__c'),
            new LayoutField('Opportunity', 'Category__c'),
            new LayoutField('Opportunity', 'Division__c'),
            new LayoutField('Opportunity', 'Application_Type__c')
        },
        // Learner Personal Details
        'Opp_Appr_PDetail' => new List<LayoutField>{
            new LayoutField('Opportunity', 'AccountId'),
            new LayoutField('Account', 'Account.Personal_Email__pc'),
            new LayoutField('Account', 'Account.Salutation'),
            new LayoutField('Account', 'Account.PersonMobilePhone'),
            new LayoutField('Account', 'Account.FirstName'),
            new LayoutField('Account', 'Account.PersonBirthdate'),
            new LayoutField('Account', 'Account.LastName'),
            new LayoutField('Account', 'Account.Age__pc'),
            new LayoutField('Account', 'Account.NI_Number__pc'),
            new LayoutField('Account', 'Account.Middle_Name__pc')
        },
        // Client Details
        'Opp_Appr_ClientDetails' => new List<LayoutField>{
            new LayoutField('Account', 'Client__r.Name'),
            new LayoutField('Account', 'Client__r.BPP_Account_Number__c'),
            new LayoutField('Account', 'Client__r.Account_Managed__c'),
            new LayoutField('Account', 'Client__r.Client_Category__c'),
            new LayoutField('Account', 'Client__r.Account_Tax_Category__c'),
            new LayoutField('Account', 'Client__r.Addressable_Levy_pot__c'),
            new LayoutField('Account', 'Client__r.AnnualRevenue'),
            new LayoutField('Account', 'Client__r.Apprenticeship_Service_Account_Owner__c'),
            new LayoutField('Account', 'Client__r.Bodies_With_Levy_Permissions__c'),
            new LayoutField('Account', 'Client__r.Levy_pot__c'),
            new LayoutField('Account', 'Client__r.NumberOfEmployees'),
            new LayoutField('Account', 'Client__r.Pays_Into_Apprenticeship_Levy__c')
        },
        // Line Manager Details
        'Opp_Appr_LMDetails' => new List<LayoutField>{
            new LayoutField('Contact', 'Line_Manager__r.Name'),
            new LayoutField('Contact', 'Line_Manager__r.Title'),
            new LayoutField('Contact', 'Line_Manager__r.Email'),
            new LayoutField('Contact', 'Line_Manager__r.Phone'),
            new LayoutField('Contact', 'Line_Manager__r.MobilePhone')
        }
    };

    @TestVisible
    private class LayoutField {
        private String parentObject;
        private String fieldName;

        @TestVisible
        private LayoutField(String parentObject, String fieldName) {
            this.parentObject = parentObject;
            this.fieldName = fieldName;
        }
    }

    /**
     * Queries out all Fields to render for the given Section, extracts any field details and finally enriches with data for these fields on the given record
     * @return  List of all Fields to render and their details
     */
    @AuraEnabled(cacheable=true)
    public static EnhancedLayoutDetails retrieveFieldDetails(String sectionAPIName, String recordId) {
        List<LayoutField> layoutFields = fieldConfig.get(sectionAPIName);

        if (layoutFields == null || layoutFields.isEmpty()) {
            return null;
        }

        EnhancedLayoutDetails detailsToReturn = new EnhancedLayoutDetails();
        Set<String> fieldsToQuery = new Set<String>();
        Map<String, DescribeSObjectResult> objectToSObjectResult = new Map<String, DescribeSObjectResult>();

        for (LayoutField fieldSetting : layoutFields) {
            EnhancedLayoutField fieldDetails = new EnhancedLayoutField();
            detailsToReturn.fields.add(fieldDetails);

            // Retrieve the SObject Describe for the given field
            DescribeSObjectResult currentObjectDescribe = objectToSObjectResult.get(fieldSetting.parentObject);

            // Cache the SObject Results
            if (currentObjectDescribe == null) {
                currentObjectDescribe = Schema.getGlobalDescribe().get(fieldSetting.parentObject)?.getDescribe();

                if (currentObjectDescribe == null) {
                    fieldDetails.errorMessage = 'SObject Provided does not exist.';
                    continue;
                }

                objectToSObjectResult.put(fieldSetting.parentObject, currentObjectDescribe);
            }

            // Split the field up into its individual segments
            fieldDetails.fieldSegments = fieldSetting.fieldName.split('\\.');
            fieldDetails.fullPath = fieldSetting.fieldName;

            // Extract the details of the current field
            DescribeFieldResult currentFieldDescribe = currentObjectDescribe.fields.getMap()
                .get(fieldDetails.fieldSegments[fieldDetails.fieldSegments.size() - 1])
                ?.getDescribe();

            // If the field could not be found, return with an error
            if (currentFieldDescribe == null) {
                fieldDetails.errorMessage = 'Field does not exist.';
                continue;
            }

            // If the field could be found but is not readable by the user, return with a missing permissions flag
            if (!currentFieldDescribe.isAccessible()) {
                fieldDetails.missingPermissions = true;
                continue;
            }

            // If all prior checks pass, allow the field to be queried and extract any details of the field ready to return
            fieldsToQuery.add(fieldSetting.fieldName);

            fieldDetails.label = currentFieldDescribe.getLabel();
            fieldDetails.type = String.valueOf(currentFieldDescribe.getType());

            // If the field is a picklist we also need to return any picklist values and their API names
            if (fieldDetails.type == 'PICKLIST' || fieldDetails.type == 'MULTIPICKLIST') {
                for (Schema.PicklistEntry picklistEntry : currentFieldDescribe.getPicklistValues()) {
                    fieldDetails.picklistValuesToLabels.put(picklistEntry.getValue(), picklistEntry.getLabel());
                }
            }

            // If the field is a reference we also need to return the Name value of the linked record as to not display the records Id
            if (fieldDetails.type == 'REFERENCE') {
                // To achieve this, clone the current records segment
                fieldDetails.lookupFieldSegments = fieldDetails.fieldSegments.clone();

                // Replace the lookup (Id) field with its equivalent relationship field and also the records "Name"
                fieldDetails.lookupFieldSegments.remove(fieldDetails.fieldSegments.size() - 1);
                fieldDetails.lookupFieldSegments.add(currentFieldDescribe.getRelationshipName());
                fieldDetails.lookupFieldSegments.add('Name');

                fieldsToQuery.add(String.join(fieldDetails.lookupFieldSegments, '.'));
            }
        }

        if (fieldsToQuery.isEmpty()) {
            return detailsToReturn;
        }

        // Query out the record and all fields that were identified and return as a string to return the data identically to how it was queried out
        detailsToReturn.queryResultsString = JSON.serialize(
            Database.query(
                string.format(
                    'SELECT Id, {0} FROM {1} WHERE Id = \'\'{2}\'\' LIMIT 1',
                    new List<string>{
                        String.join(new List<String>(fieldsToQuery), ', '),
                        ((Id) recordId).getSObjectType().getDescribe().getName(),
                        recordId
                    }
                )
            )
        );

        return detailsToReturn;
    }

    public class EnhancedLayoutDetails {
        @auraEnabled
        public String queryResultsString;

        @auraEnabled
        public List<EnhancedLayoutField> fields = new List<EnhancedLayoutField>();
    }

    public class EnhancedLayoutField {
        @auraEnabled
        public String label;

        @auraEnabled
        public String type;

        @auraEnabled
        public String fullPath;

        @auraEnabled
        public String errorMessage;

        @auraEnabled
        public Boolean missingPermissions = false;

        @auraEnabled
        public Map<String, String> picklistValuesToLabels = new Map<String, String>();

        @auraEnabled
        public List<String> fieldSegments = new List<String>();

        @auraEnabled
        public List<String> lookupFieldSegments;
    }
}
