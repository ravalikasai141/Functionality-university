/************************************************************************
 Name:  DedupeLead
========================================================================
Purpose: REST call to check if Lead exists using dedupe rules
========================================================================
History                                                                
VERSION    AUTHOR             DATE              DETAIL                              
1.0      David Lovejoy     19/03/2020      INITIAL DEVELOPMENT   
************************************************************************/

@RestResource(urlMapping='/v1.0/DedupeLead/*')
global with sharing class DedupeLead {
    global class Response {
        public Response() {
        }
        public String leadId { get; set; }

        public Response(String leadId) {
            this.leadId = leadId;
        }
    }

    global class CheckLead {
        public String recordType;
        public String email;
        public String phone;
        public String firstname;
        public String lastname;
    }

    public static Lead createComparisonLead(CheckLead checkLead) {
        String recordType = DedupeHelper.verifyPostInput(checkLead.recordType);
        String firstname = DedupeHelper.verifyPostInput(checkLead.firstname);
        String lastname = DedupeHelper.verifyPostInput(checkLead.lastname);
        String email = DedupeHelper.verifyPostInput(checkLead.email);
        String phone = DedupeHelper.verifyPostInput(checkLead.phone);
        Id recType = (recordType != null &&
            recordType == 'Prospective Student'
            ? Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName().get('Prospective_Student').getRecordTypeId()
            : Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName()
                  .get('Business_Development')
                  .getRecordTypeId());

        Lead lead = new Lead();
        lead.RecordTypeId = recType;
        lead.FirstName = firstname;
        lead.LastName = lastname;
        lead.Other_Email__c = email;
        lead.Email = email;
        lead.Personal_Email__c = email;
        lead.Work_Email__c = email;
        lead.Phone = phone;
        lead.Home_Phone__c = phone;
        lead.MobilePhone = phone;
        lead.Work_Phone__c = phone;

        return lead;
    }

    @HttpPost
    global static Response doPost(CheckLead checkLead) {
        try {
            Id matchedLeadId;

            Lead lead = createComparisonLead(checkLead);
            List<Lead> leadList = new List<Lead>{ lead };

            List<DuplicateHandler.MatchingRecord> matchingRecords = DuplicateFinder.findDuplicateRecords(leadList);
            if (matchingRecords.size() == 0) {
                return new Response('null');
            } else {
                matchedLeadId = (matchingRecords.size() == 1
                    ? matchingRecords.get(0).matchingId
                    : DuplicateHandler.handleMatchingRecords(matchingRecords));
                return new Response(String.valueOf(matchedLeadId));
            }
        } catch (Exception e) {
            return new Response('DedupeLead Error: [' + e.getLineNumber() + '] ' + e.getMessage());
        }
    }
}
