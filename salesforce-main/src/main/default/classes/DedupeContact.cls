/************************************************************************
 Name:  DedupeContact
========================================================================
Purpose: REST call to check if Contact exists using dedupe rules
========================================================================
History                                                                
VERSION    AUTHOR             DATE              DETAIL                              
1.0      David Lovejoy     19/03/2020      INITIAL DEVELOPMENT   
************************************************************************/

@RestResource(urlMapping='/v1.0/DedupeContact/*')
global with sharing class DedupeContact {
    global class Response {
        public Response() {
        }
        public String contactId { get; set; }

        public Response(String contactId) {
            this.contactId = contactId;
        }
    }

    global class CheckContact {
        public String accountName;
        public String recordType;
        public String firstname;
        public String lastname;
        public String email;
        public String phone;
    }

    public static Contact createComparisonContact(CheckContact checkContact) {
        String recordType = DedupeHelper.verifyPostInput(checkContact.recordType);
        String accountName = DedupeHelper.verifyPostInput(checkContact.accountName);
        String firstname = DedupeHelper.verifyPostInput(checkContact.firstname);
        String lastname = DedupeHelper.verifyPostInput(checkContact.lastname);
        String email = DedupeHelper.verifyPostInput(checkContact.email);
        String phone = DedupeHelper.verifyPostInput(checkContact.phone);

        Contact contact = new Contact();
        contact.RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName()
            .get('BD_Contact')
            .getRecordTypeId();
        contact.FirstName = firstname;
        contact.LastName = lastname;
        contact.Home_Email__c = email;
        contact.Other_Email__c = email;
        contact.Email = email;
        contact.Personal_Email__c = email;
        contact.Work_Email__c = email;
        contact.Phone = phone;
        contact.HomePhone = phone;
        contact.MobilePhone = phone;
        contact.OtherPhone = phone;
        contact.Work_Phone__c = phone;

        return contact;
    }

    @HttpPost
    global static Response doPost(CheckContact checkContact) {
        try {
            Id matchedContactId;

            Contact contact = createComparisonContact(checkContact);
            List<Contact> contactList = new List<Contact>{ contact };

            List<DuplicateHandler.MatchingRecord> matchingRecords = DuplicateFinder.findDuplicateRecords(contactList);
            if (matchingRecords.size() == 0) {
                return new Response('null');
            } else {
                matchedContactId = (matchingRecords.size() == 1
                    ? matchingRecords.get(0).matchingId
                    : DuplicateHandler.handleMatchingRecords(matchingRecords));
                return new Response(String.valueOf(matchedContactId));
            }
        } catch (Exception e) {
            return new Response('DedupeContact Error: [' + e.getLineNumber() + '] ' + e.getMessage());
        }
    }
}
