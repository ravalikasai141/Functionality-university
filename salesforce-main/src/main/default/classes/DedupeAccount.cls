/************************************************************************
 Name:  DedupeAccount
========================================================================
Purpose: REST call to check if Account exists using dedupe rules
========================================================================
History                                                                
VERSION    AUTHOR             DATE              DETAIL                              
1.0      David Lovejoy     19/03/2020      INITIAL DEVELOPMENT   
************************************************************************/

@RestResource(urlMapping='/v1.0/DedupeAccount/*')
global with sharing class DedupeAccount {
    global class Response {
        public Response() {
        }
        public String accountId { get; set; }

        public Response(String accountId) {
            this.accountId = accountId;
        }
    }

    global class CheckAccount {
        public String firstname;
        public String lastname;
        public String dob;
        public String email;
        public String phone;
    }

    public static Account createComparisonAccount(CheckAccount checkAccount) {
        String firstname = DedupeHelper.verifyPostInput(checkAccount.firstname);
        String lastname = DedupeHelper.verifyPostInput(checkAccount.lastname);
        String email = DedupeHelper.verifyPostInput(checkAccount.email);
        String phone = DedupeHelper.verifyPostInput(checkAccount.phone);
        Date dob = (checkAccount.dob != null && checkAccount.dob.length() > 0 ? Date.valueOf(checkAccount.dob) : null);

        Account account = new Account();
        account.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
            .get('Student_Account')
            .getRecordTypeId();
        account.FirstName = firstname;
        account.LastName = lastname;
        account.Home_Email__pc = email;
        account.Other_Email__pc = email;
        account.PersonEmail = email;
        account.Personal_Email__pc = email;
        account.Work_Email__pc = email;
        account.Phone = phone;
        account.PersonHomePhone = phone;
        account.PersonMobilePhone = phone;
        account.PersonOtherPhone = phone;
        account.Work_Phone__pc = phone;
        account.PersonBirthdate = dob;

        return account;
    }

    @HttpPost
    global static Response doPost(CheckAccount checkAccount) {
        try {
            Id matchedAccountId;

            Account account = createComparisonAccount(checkAccount);
            List<Account> accountList = new List<Account>{ account };

            List<DuplicateHandler.MatchingRecord> matchingRecords = DuplicateFinder.findDuplicateRecords(accountList);
            if (matchingRecords.size() == 0) {
                return new Response('null');
            } else {
                matchedAccountId = (matchingRecords.size() == 1
                    ? matchingRecords.get(0).matchingId
                    : DuplicateHandler.handleMatchingRecords(matchingRecords));
                return new Response(String.valueOf(matchedAccountId));
            }
        } catch (Exception e) {
            return new Response('DedupeAccount Error: [' + e.getLineNumber() + '] ' + e.getMessage());
        }
    }
}
