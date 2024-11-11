/***********************************************************************
 Name:  RFIReceiver
=======================================================================
Purpose: Transition of RFI Form from Marketing to Salesforce via REST
=======================================================================
History                                                                
VERSION    AUTHOR             DATE              DETAIL                              
1.0      David Lovejoy     24/03/2020      INITIAL DEVELOPMENT   
***********************************************************************/

@RestResource(urlMapping='/v1.0/RFIReceiver/*')
global with sharing class RFIReceiver {
    public class RFIReceiverException extends Exception {
    }

    global class Response {
        public Response() {
        }
        global String response { get; set; }

        public Response(String response) {
            this.response = response;
        }
    }

    global class RFI {
        global String e_campaign;
        global String e_source;
        global String e_medium;
        global String e_email;
        global String e_phone;
        global String e_title;
        global String e_last_name;
        global String GA_Gclid;
        global String GA_Client_ID;
        global String e_current_bpp_student;
        global String e_programme_of_interest;
        global Boolean e_opt_out;
        global String e_first_name;
        global String e_source_title;
        global String e_sub_source;
        global String e_lead_source;
        global String e_uk_eu_student;
        global String e_comments;
        global String RecordType;
        global String FormName;
        global String e_company;
        global String e_hashed_email;
        global Boolean e_levy;
        global String e_enquiry;

        public RFI cleanUp() {
            // Get all fields of the object dynamically
            String jsonString = JSON.serialize(this);
            Map<String, Object> fieldMap = (Map<String, Object>) JSON.deserializeUntyped(jsonString);
            Map<String, Object> newMap = new Map<String, Object>();

            // Clean up each field using the DedupeHelper.verifyPostInput method
            for (String fieldName : fieldMap.keySet()) {
                if (fieldMap.get(fieldName) instanceof String) {
                    newMap.put(fieldName, DedupeHelper.verifyPostInput(String.valueOf(fieldMap.get(fieldName))));
                }
                if (fieldMap.get(fieldName) instanceof Boolean) {
                    Boolean booleanValue = fieldMap.get(fieldName) == null
                        ? false
                        : Boolean.valueOf(fieldMap.get(fieldName));
                    newMap.put(fieldName, booleanValue);
                }
            }

            // Convert the map to JSON string
            String mapToJsonString = JSON.serialize(newMap);
            // Deserialize the JSON string into MyClass instance
            return (RFI) JSON.deserialize(mapToJsonString, RFI.class);
        }
    }

    @HttpPost
    global static Response doPost(RFI rfi) {
        try {
            rfi = rfi.cleanUp();
            DedupeAccount.Response checkAccountExists;
            DedupeLead.Response checkLeadExists;
            DedupeContact.Response checkContactExists;
            String recId;
            String query;
            sObject submittedRFIRecord;
            Id personContactId;
            Id accountId;

            if (rfi.RecordType == 'Prospective Student') {
                // Check if Account Exist
                checkAccountExists = checkAccountExists(rfi);

                if (String.valueOf(checkAccountExists).contains('001')) {
                    recId = DedupeHelper.formatResponseId(String.valueOf(checkAccountExists));
                }

                if (recId != null) {
                    query = DedupeHelper.createQuery('Account', rfi.RecordType, recId, false);
                    Account a = Database.query(query);
                    a = DedupeHelper.updateAccountFields(
                        a,
                        rfi.e_first_name,
                        rfi.GA_Client_ID,
                        rfi.e_hashed_email,
                        rfi.e_last_name,
                        rfi.e_phone,
                        rfi.e_email,
                        rfi.e_opt_out,
                        rfi.e_title
                    );
                    Database.update(a, DedupeHelper.getAllowSaveOptions());
                    submittedRFIRecord = a;
                    personContactId = a.PersonContactId;
                } else {
                    // Check if Lead Exist
                    checkLeadExists = checkLeadExists(rfi);

                    if (String.valueOf(checkLeadExists).contains('00Q')) {
                        recId = DedupeHelper.formatResponseId(String.valueOf(checkLeadExists));
                    }

                    if (recId != null) {
                        query = DedupeHelper.createQuery('Lead', rfi.RecordType, recId, false);
                        Lead l = Database.query(query);
                        if (!l.IsConverted) {
                            DedupeHelper.mapLeadFields(rfi, rfi.RecordType, l, true);
                            submittedRFIRecord = l;
                        } else {
                            query = DedupeHelper.createQuery('Account', rfi.RecordType, l.ConvertedAccountId, true);
                            Account a = Database.query(query);
                            a = DedupeHelper.updateAccountFields(
                                a,
                                rfi.e_first_name,
                                rfi.GA_Client_ID,
                                rfi.e_hashed_email,
                                rfi.e_last_name,
                                rfi.e_phone,
                                rfi.e_email,
                                rfi.e_opt_out,
                                rfi.e_title
                            );
                            Database.update(a, DedupeHelper.getAllowSaveOptions());
                            submittedRFIRecord = a;
                            personContactId = a.PersonContactId;
                        }
                    } else {
                        Lead l = DedupeHelper.createLead(rfi, 'Prospective Student');
                        System.debug('@RFIReceiver@ Lead Created: ' + l);
                        submittedRFIRecord = l;
                    }
                }
            } else if (rfi.RecordType == 'Business Development') {
                // Check if Contact Exist
                checkContactExists = checkContactExists(rfi);

                if (String.valueOf(checkContactExists).contains('003')) {
                    recId = DedupeHelper.formatResponseId(String.valueOf(checkContactExists));
                }

                if (recId != null) {
                    query = DedupeHelper.createQuery('Contact', rfi.RecordType, recId, false);
                    Contact c = Database.query(query);
                    c = DedupeHelper.updateContactFields(
                        c,
                        rfi.e_first_name,
                        rfi.GA_Client_ID,
                        rfi.e_last_name,
                        rfi.e_phone,
                        rfi.e_email,
                        rfi.e_opt_out,
                        rfi.e_title
                    );
                    Database.update(c, DedupeHelper.getAllowSaveOptions());
                    submittedRFIRecord = c;
                    accountId = c.AccountId;
                } else {
                    // Check if Lead Exist
                    checkLeadExists = checkLeadExists(rfi);

                    if (String.valueOf(checkLeadExists).contains('00Q')) {
                        recId = DedupeHelper.formatResponseId(String.valueOf(checkLeadExists));
                    }

                    if (recId != null) {
                        query = DedupeHelper.createQuery('Lead', rfi.RecordType, recId, false);
                        Lead l = Database.query(query);
                        if (!l.IsConverted) {
                            DedupeHelper.mapLeadFields(rfi, rfi.RecordType, l, true);
                            submittedRFIRecord = l;
                        } else {
                            query = DedupeHelper.createQuery('Contact', rfi.RecordType, l.ConvertedContactId, true);
                            Contact c = Database.query(query);
                            DedupeHelper.updateContactFields(
                                c,
                                rfi.e_first_name,
                                rfi.GA_Client_ID,
                                rfi.e_last_name,
                                rfi.e_phone,
                                rfi.e_email,
                                rfi.e_opt_out,
                                rfi.e_title
                            );
                            Database.update(c, DedupeHelper.getAllowSaveOptions());
                            submittedRFIRecord = c;
                        }
                    } else {
                        Lead l = DedupeHelper.createLead(rfi, 'Business Development');
                        submittedRFIRecord = l;
                    }
                }
            } else {
                return new Response('RFIReceiver Error: "RecordType" not recognised');
            }

            if (submittedRFIRecord == null) {
                throw new RFIReceiverException(
                    'RFIReceiver Error: Unable to find existing record or create new Lead record.'
                );
            }

            insert DedupeHelper.taskCreationHandler(submittedRFIRecord, rfi, personContactId, accountId);
            return new Response('Success');
        } catch (Exception ex) {
            String error = '[' + ex.getLineNumber() + '] ' + ex.getMessage() + ' ' + ex.getStackTraceString();
            handleException(error, rfi);
            return new Response('RFIReceiver Error: ' + error);
        } finally {
            Log.send();
        }
    }

    private static DedupeLead.Response checkLeadExists(RFI rfi) {
        DedupeLead.CheckLead lead = new DedupeLead.CheckLead();
        lead.recordType = (rfi.RecordType != null ? rfi.RecordType : null);
        lead.email = (rfi.e_email != null ? rfi.e_email : null);
        lead.firstname = (rfi.e_first_name != null ? rfi.e_first_name : null);
        lead.lastname = (rfi.e_last_name != null ? rfi.e_last_name : null);
        lead.phone = (rfi.e_phone != null ? rfi.e_phone : null);
        return DedupeLead.doPost(lead);
    }

    private static DedupeAccount.Response checkAccountExists(RFI rfi) {
        DedupeAccount.CheckAccount account = new DedupeAccount.CheckAccount();
        account.email = (rfi.e_email != null ? rfi.e_email : null);
        account.firstname = (rfi.e_first_name != null ? rfi.e_first_name : null);
        account.lastname = (rfi.e_last_name != null ? rfi.e_last_name : null);
        account.phone = (rfi.e_phone != null ? rfi.e_phone : null);
        return DedupeAccount.doPost(account);
    }

    private static DedupeContact.Response checkContactExists(RFI rfi) {
        DedupeContact.CheckContact contact = new DedupeContact.CheckContact();
        contact.recordType = (rfi.RecordType != null ? rfi.RecordType : null);
        contact.accountName = (rfi.e_company != null ? rfi.e_company : null);
        contact.email = (rfi.e_email != null ? rfi.e_email : null);
        contact.firstname = (rfi.e_first_name != null ? rfi.e_first_name : null);
        contact.lastname = (rfi.e_last_name != null ? rfi.e_last_name : null);
        contact.phone = (rfi.e_phone != null ? rfi.e_phone : null);
        return DedupeContact.doPost(contact);
    }

    private static void handleException(String error, RFIReceiver.RFI rfi) {
        String subject = 'RFIReceiver Error';
        Log.debug(subject + ': ' + error + '\n' + rfi);
        Log.critical(error);
        EmailUtilities.submitSystemAlertEmail(subject, error);
    }
}
