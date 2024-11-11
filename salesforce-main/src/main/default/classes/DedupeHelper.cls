/***********************************************************************
 Name:  DedupeHelper
=======================================================================
Purpose: Helper class for RFIReceiver and Dedupe classes
=======================================================================
History                                                                
VERSION    AUTHOR             DATE              DETAIL                              
1.0      David Lovejoy     26/03/2020      INITIAL DEVELOPMENT   
1.1      David Lovejoy     06/04/2021      TWEAKS   
1.2      David Lovejoy     03/12/2021      TWEAKS
1.3      Richard Still     28/01/2022      Trim whitespace in verifyPostInput()
***********************************************************************/

public with sharing class DedupeHelper {
    public class DedupeHelperException extends Exception {
    }

    public static String formatResponseId(String incomingString) {
        String idFormat;
        String recId;
        String[] response = incomingString.split('=');
        idFormat = response[response.size() - 1];
        recId = idFormat.replace(']', '');
        return recId;
    }

    public static String verifyPostInput(String input) {
        if (String.isBlank(input)) {
            return null;
        }
        return input.trim();
    }

    public static String createQuery(String objectType, String recordType, Id recordId, Boolean convertedLead) {
        String query;
        String fields;
        Id recordTypeId;
        if (objectType == 'Account' && recordType == 'Prospective Student') {
            recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
                .get('Student_Account')
                .getRecordTypeId();
            Id lockedRecType = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
                .get('Locked_Student_Account')
                .getRecordTypeId();
            fields = 'Id, RecordTypeId, PersonContactId, FirstName, LastName, OwnerId, GDPR_Opt_In__c, GDPR_Modified__c, PersonHomePhone, Preferred_Phone__pc, Personal_Email__pc, Preferred_Email__pc, GA_Client_ID__pc, Hashed_Email__pc, PersonTitle';
            query = (!convertedLead
                ? 'SELECT ' +
                  fields +
                  ' FROM Account WHERE Id = \'' +
                  recordId +
                  '\' AND (RecordTypeId = \'' +
                  recordTypeId +
                  '\' OR RecordTypeId = \'' +
                  lockedRecType +
                  '\')'
                : 'SELECT ' + fields + ' FROM Account WHERE Id = \'' + recordId + '\'');
        } else if (objectType == 'Contact' && recordType == 'Business Development') {
            recordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName()
                .get('BD_Contact')
                .getRecordTypeId();
            fields = 'Id, RecordTypeId, AccountId, FirstName, LastName, OwnerId, GDPR_Opt_In__c, GDPR_Modified__c, Work_Phone__c, Preferred_Phone__c, Work_Email__c, Preferred_Email__c, Title, GA_Client_ID__c';
            query = (!convertedLead
                ? 'SELECT ' +
                  fields +
                  ' FROM Contact WHERE Id = \'' +
                  recordId +
                  '\' AND RecordTypeId = \'' +
                  recordTypeId +
                  '\''
                : 'SELECT ' + fields + ' FROM Contact WHERE Id = \'' + recordId + '\'');
        } else if (objectType == 'Lead') {
            recordTypeId = (recordType == 'Prospective Student'
                ? Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName()
                      .get('Prospective_Student')
                      .getRecordTypeId()
                : Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName()
                      .get('Business_Development')
                      .getRecordTypeId());
            fields = 'Id, RecordTypeId, IsConverted, ConvertedAccountId, ConvertedContactId, FirstName, LastName, OwnerId, GDPR_Opt_In__c, GDPR_Modified__c, Home_Phone__c, Work_Phone__c, Preferred_Phone__c, Personal_Email__c, Work_Email__c, Preferred_Email__c, GA_Client_ID__c, GClid_Information__c, Title, Company, Description, Available_Levy__c, Area_of_Interest__c, rfi_Course_of_Interest__c, Marketing_Campaign_ID__c, Marketing_Media_Source__c, Marketing_Medium__c, LeadSource, Lead_Source_Recent__c, Lead_Source_Title_Recent__c, Status, Lead_Source_Title__c, Lead_Subsource__c, Lead_Subsource_Recent__c, Hashed_Email__c';
            query =
                'SELECT ' +
                fields +
                ' FROM Lead WHERE Id = \'' +
                recordId +
                '\' AND RecordTypeId = \'' +
                recordTypeId +
                '\'';
        }
        return query;
    }

    public static Account updateAccountFields(
        Account a,
        String firstname,
        String gaClientId,
        String hashedEmail,
        String lastname,
        String phone,
        String email,
        Boolean optOut,
        String title
    ) {
        /* update where NULL */
        if (a.FirstName == null && firstname != null) {
            a.FirstName = firstname;
        }
        if (a.GA_Client_ID__pc == null && gaClientId != null) {
            a.GA_Client_ID__pc = gaClientId;
        }
        if (a.Hashed_Email__pc == null && hashedEmail != null) {
            a.Hashed_Email__pc = hashedEmail;
        }
        if (a.LastName == null && lastname != null) {
            a.LastName = lastname;
        }
        if (a.PersonHomePhone == null && phone != null) {
            a.PersonHomePhone = phone;
        }
        if (a.Personal_Email__pc == null && email != null) {
            a.Personal_Email__pc = email;
        }
        if (a.Preferred_Email__pc == null) {
            a.Preferred_Email__pc = 'Personal';
        }
        if (a.Preferred_Phone__pc == null) {
            a.Preferred_Phone__pc = 'Home';
        }
        /* ------------------ */

        /* update */
        if (optOut != null) {
            a.GDPR_Opt_In__c = (optOut ? false : true);
            a.GDPR_Modified__c = System.now();
        }
        if (title != null) {
            a.PersonTitle = title;
        }
        /* ------------------ */

        return a;
    }

    public static Contact updateContactFields(
        Contact c,
        String firstname,
        String gaClientId,
        String lastname,
        String phone,
        String email,
        Boolean optOut,
        String title
    ) {
        /* update where NULL */
        if (c.FirstName == null && firstname != null) {
            c.FirstName = firstname;
        }
        if (c.GA_Client_ID__c == null && gaClientId != null) {
            c.GA_Client_ID__c = gaClientId;
        }
        if (c.LastName == null && lastname != null) {
            c.LastName = lastname;
        }
        if (c.Preferred_Email__c == null) {
            c.Preferred_Email__c = 'Work';
        }
        if (c.Preferred_Phone__c == null) {
            c.Preferred_Phone__c = 'Work';
        }
        if (c.Work_Phone__c == null && phone != null) {
            c.Work_Phone__c = phone;
        }
        if (c.Work_Email__c == null && email != null) {
            c.Work_Email__c = email;
        }
        /* ------------------ */

        /* update */
        if (optOut != null) {
            c.GDPR_Modified__c = System.now();
            c.GDPR_Opt_In__c = (optOut ? false : true);
        }
        if (title != null) {
            c.Title = title;
        }
        /* ------------------ */

        return c;
    }

    // maps Lead fields where possible
    public static Lead mapLeadFields(RFIReceiver.RFI rfi, String recordType, Lead lead, Boolean doUpdate) {
        Id recType = (recordType == 'Prospective Student'
            ? Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName().get('Prospective_Student').getRecordTypeId()
            : Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName()
                  .get('Business_Development')
                  .getRecordTypeId());
        Lead l = (lead != null ? lead : new Lead());
        if (l.Id == null) {
            l.RecordTypeId = recType;
            if (rfi.e_comments != null) {
                l.Description = rfi.e_comments;
            }
            if (rfi.GA_Client_ID != null) {
                l.GA_Client_ID__c = rfi.GA_Client_ID;
            }
            if (rfi.GA_Gclid != null) {
                l.GClid_Information__c = rfi.GA_Gclid;
            }
            if (rfi.e_hashed_email != null) {
                l.Hashed_Email__c = rfi.e_hashed_email;
            }
            if (rfi.e_lead_source != null) {
                l.LeadSource = rfi.e_lead_source;
                l.Lead_Source_Recent__c = rfi.e_lead_source;
            }
            if (rfi.e_source_title != null) {
                l.Lead_Source_Title__c = rfi.e_source_title;
            }
            if (rfi.e_sub_source != null) {
                l.Lead_Subsource__c = rfi.e_sub_source;
            }
            l.Lead_Source_Timestamp__c = System.now();
        } else {
            if (l.Description == null && rfi.e_comments != null) {
                l.Description = rfi.e_comments;
            }
            if (l.GA_Client_ID__c == null && rfi.GA_Client_ID != null) {
                l.GA_Client_ID__c = rfi.GA_Client_ID;
            }
            if (l.GClid_Information__c == null && rfi.GA_Gclid != null) {
                l.GClid_Information__c = rfi.GA_Gclid;
            }
            if (l.Hashed_Email__c == null && rfi.e_hashed_email != null) {
                l.Hashed_Email__c = rfi.e_hashed_email;
            }
            if (rfi.e_lead_source != null) {
                if (l.LeadSource == null) {
                    l.LeadSource = rfi.e_lead_source;
                }
                l.Lead_Source_Recent__c = rfi.e_lead_source;
            }
        }
        l.Lead_Source_Timestamp_Recent__c = System.now();
        if (rfi.e_campaign != null) {
            l.Marketing_Campaign_ID__c = rfi.e_campaign;
        }
        if (rfi.e_first_name != null) {
            l.FirstName = rfi.e_first_name;
        }
        if (rfi.e_last_name != null) {
            l.LastName = rfi.e_last_name;
        }
        if (rfi.e_medium != null) {
            l.Marketing_Medium__c = rfi.e_medium;
        }
        if (rfi.e_source != null) {
            l.Marketing_Media_Source__c = rfi.e_source;
        }
        if (rfi.e_source_title != null) {
            l.Lead_Source_Title_Recent__c = rfi.e_source_title;
        }
        if (rfi.e_sub_source != null) {
            l.Lead_Subsource_Recent__c = rfi.e_sub_source;
        }
        if (rfi.e_programme_of_interest != null) {
            l.rfi_Course_of_Interest__c = rfi.e_programme_of_interest;
        }
        if (rfi.e_opt_out != null) {
            l.GDPR_Opt_In__c = (rfi.e_opt_out ? false : true);
            l.GDPR_Modified__c = System.now();
        }
        if (rfi.e_email != null) {
            if (rfi.RecordType == 'Prospective Student') {
                l.Personal_Email__c = rfi.e_email;
                l.Preferred_Email__c = 'Personal';
            } else {
                l.Work_Email__c = rfi.e_email;
                l.Preferred_Email__c = 'Work';
            }
        }
        if (rfi.e_phone != null) {
            if (rfi.RecordType == 'Prospective Student') {
                l.Home_Phone__c = rfi.e_phone;
                l.Preferred_Phone__c = 'Home';
            } else {
                l.Work_Phone__c = rfi.e_phone;
                l.Preferred_Phone__c = 'Work';
            }
        }
        if (rfi.RecordType == 'Business Development') {
            if (rfi.e_company != null) {
                l.Company = rfi.e_company;
            }
            if (rfi.e_enquiry != null) {
                l.Area_of_Interest__c = rfi.e_enquiry;
            }
            if (rfi.e_levy != null) {
                l.Available_Levy__c = (rfi.e_levy ? true : false);
            }
            if (rfi.e_title != null) {
                l.Title = rfi.e_title;
            }
        }
        if (doUpdate) {
            Database.update(l, getAllowSaveOptions());
        }
        return l;
    }

    public static Lead createLead(RFIReceiver.RFI rfi, String recordType) {
        Lead l = mapLeadFields(rfi, recordType, null, false);

        Database.DMLOptions dml = new Database.DMLOptions();
        dml.assignmentRuleHeader.useDefaultRule = true;
        Database.SaveResult saveResult = Database.insert(l, dml);
        if (!saveResult.isSuccess()) {
            List<String> errors = new List<String>();
            for (Database.Error error : saveResult.getErrors()) {
                errors.add(error.getMessage());
            }
            String errorMessage = String.join(errors, ' | ');
            throw new DedupeHelperException(
                'DedupeHelper - Failed to create Lead due to the following: ' + errorMessage
            );
        }
        return l;
    }

    // Method to handle Task creation for created/updated record
    public static Task taskCreationHandler(
        SObject submittedRFIRecord,
        RFIReceiver.RFI rfi,
        Id personContactId,
        Id accountId
    ) {
        String objectType = submittedRFIRecord.Id.getSObjectType().getDescribe().getName();
        Id whatId;
        Id whoId;

        if (objectType == 'Account') {
            whatId = submittedRFIRecord.Id;
            whoId = personContactId;
        } else if (objectType == 'Contact') {
            whatId = accountId;
            whoId = submittedRFIRecord.Id;
        } else {
            whoId = submittedRFIRecord.Id;
        }
        return createContactRequestTask(rfi, whatId, whoId);
    }

    // Contact Request Task creation for Account/Contact/Lead (after RFI has succussfully submitted a record)
    public static Task createContactRequestTask(RFIReceiver.RFI rfi, Id whatId, Id whoId) {
        User u = [SELECT Id FROM User WHERE FirstName = 'Marketing' AND LastName = 'Cloud' AND isActive = TRUE];
        Task t = new Task(
            ActivityDate = System.today(),
            Course__c = rfi.e_programme_of_interest,
            Description = rfi.e_comments,
            GA_Client_ID__c = rfi.GA_Client_ID,
            GClid_Information__c = rfi.GA_Gclid,
            Lead_Source_Title__c = rfi.e_source_title,
            Lead_Source__c = rfi.e_lead_source,
            Lead_Subsource__c = rfi.e_sub_source,
            Marketing_Campaign_ID__c = rfi.e_campaign,
            Marketing_Media_Source__c = rfi.e_source,
            Marketing_Medium__c = rfi.e_medium,
            OwnerId = u.Id,
            Priority = 'Normal',
            RecordTypeId = Schema.Sobjecttype.Task.getRecordTypeInfosByName().get('Contact Request').getRecordTypeId(),
            Status = 'Completed',
            Subject = 'Form: RFI Form - New 2020',
            Type = 'Form Submission',
            WhatId = whatId,
            WhoId = whoId
        );
        Boolean optOut = (rfi.e_opt_out != null ? rfi.e_opt_out : null);
        if (optOut != null) {
            t.Marketing_Contact_Preference__c = (optOut ? false : true);
        }
        return t;
    }

    public static Boolean updateFieldDecision(String oldValue, String newValue) {
        return newValue != null && oldValue != newValue;
    }

    public static String generateRandomString(Integer length) {
        final String chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopqrstuvwxyz';
        String str = '';
        while (str.length() <= length) {
            Integer idx = Math.mod(Math.abs(Crypto.getRandomInteger()), chars.length());
            str += chars.substring(idx, idx + 1);
        }
        return str;
    }

    public static Database.DMLOptions getAllowSaveOptions() {
        Database.DMLOptions dml = new Database.DMLOptions();
        dml.DuplicateRuleHeader.AllowSave = true;
        return dml;
    }
}
