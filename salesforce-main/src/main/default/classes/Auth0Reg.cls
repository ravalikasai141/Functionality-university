/***********************************************************************
Name:  Auth0Reg
=======================================================================
Purpose: Handle Auth0 Learner Registration via REST
=======================================================================
History                                                                
VERSION    AUTHOR             DATE              DETAIL                              
1.0      David Lovejoy     15/06/2020      INITIAL DEVELOPMENT   
1.0      Richard Still     26/11/2020      Updates for BPP-4182 / BPP-11273
1.0      David Lovejoy     16/11/2021      Updates for BPP-18177
1.0      David Lovejoy     22/11/2021      Updates for BPP-16501
1.0      Richard Still     08/12/2021      BPP-18314 - add 3 fields for marketing
1.0      Richard Still     09/12/2021      BPP-18245 - Lead convert, make Hub_Account__c and a lead Opportunity
1.0      David Lovejoy     20/01/2022      Updates for BPP-19103
1.0      Swayanprava Sahoo 24/02/2022      Updates for BPP-18849
1.0      Swayanprava Sahoo 14/04/2022      Updates for BPP-20378
1.0      David Lovejoy     22/08/2023      Updates for BPP-26619
***********************************************************************/

@RestResource(urlMapping='/v1.0/Auth0Reg/*')
global with sharing class Auth0Reg {
    private static Id studentInterestRecordType = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName()
        .get('Student_Interest')
        .getRecordTypeId();

    private static Id studentRecType = Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName()
        .get('Prospective_Student')
        .getRecordTypeId();

    private static Id taskRecordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName()
        .get('Direct_Application_Milestone')
        .getRecordTypeId();

    private static Id studentAccountRecordType = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
        .get('Student_Account')
        .getRecordTypeId();

    global class Response {
        global String response { get; set; }
        global String accountId { get; set; }

        public Response(String response, String accountId) {
            this.response = response;
            this.accountId = accountId;
        }
    }

    // define fields to be accepted from incoming json
    global class Registration {
        global String firstname;
        global String lastname;
        global String email;
        global String phone;
        global Boolean optIn;
        global String auth0id;
        global String leadsource;
        global String hashedEmail;
        global String gaGclId;
        global String gaClientId;

        public void cleanUp() {
            this.firstname = DedupeHelper.verifyPostInput(firstname);
            this.lastname = DedupeHelper.verifyPostInput(lastname);
            this.email = DedupeHelper.verifyPostInput(email);
            this.phone = DedupeHelper.verifyPostInput(phone);
            this.leadsource = DedupeHelper.verifyPostInput(leadsource);
            this.hashedEmail = DedupeHelper.verifyPostInput(hashedEmail);
            this.gaGclId = DedupeHelper.verifyPostInput(gaGclId);
            this.gaClientId = DedupeHelper.verifyPostInput(gaClientId);
            if (this.optIn == null) {
                this.optIn = false;
            }
        }
    }

    @HttpPost
    global static Response doPost(Registration reg) {
        try {
            // clean up input fields as needed
            reg.cleanUp();

            Hub_Account__c hubAccount = lookForHubAccount(reg);
            if (hubAccount?.Student__c != null) {
                Account updAccount = updateAccount(hubAccount.Student__c, reg);
                return new Response(
                    'Auth0Reg ' + reg.auth0id + ' Success: Account - ' + updAccount.Id + ' updated',
                    updAccount.Id
                );
            }

            String accountId = lookForAccountId(reg);
            if (accountId != null) {
                Account updAccount = updateAccount(accountId, reg);
                return new Response(
                    'Auth0Reg ' + reg.auth0id + ' Success: Account - ' + updAccount.Id + ' updated',
                    updAccount.Id
                );
            }

            String leadId = lookForLeadId(reg);
            if (leadId != null) {
                // if we found a Lead, convert + update converted Account
                Account leadAccount = leadToAccount(leadId, reg);
                if (leadAccount != null) {
                    return new Response(
                        'Auth0Reg ' +
                            reg.auth0id +
                            ' Success: Lead conversion Account - ' +
                            leadAccount.Id +
                            ' updated',
                        leadAccount.Id
                    );
                }
            }

            //otherwise, add a new Account
            Account newAccount = createAccount(reg);
            return new Response(
                'Auth0Reg ' + reg.auth0id + ' Success: Account - ' + newAccount.Id + ' created',
                newAccount.Id
            );
        } catch (Exception e) {
            return new Response(
                'Auth0Reg ' + reg.auth0id + ' Error: [' + e.getLineNumber() + '] ' + e.getMessage(),
                null
            );
        } finally {
            Log.send();
        }
    }

    public static Account leadToAccount(Id id, Registration reg) {
        Lead lead = getLeadById(id);

        if (lead.IsConverted) {
            // if already converted, update the resultant Account
            return updateAccount(lead.ConvertedAccountId, reg);
        }

        // otherwise convert fresh lead and update account
        Account accountFromLead = doLeadConvert(lead, reg);

        if (accountFromLead != null) {
            addInterestOpportunity(lead, accountFromLead);
        }

        return accountFromLead;
    }

    private static void addInterestOpportunity(Lead convertedLead, Account account) {
        String opportunityName = buildOpportunityName(convertedLead, account);

        if (opportunityName == account.LastName) {
            //the only info in the Opportunity name is the students surname - no point making an opportunity
            return;
        }

        Opportunity opportunity = new Opportunity();
        opportunity.RecordTypeId = studentInterestRecordType;
        opportunity.AccountId = account.Id;
        opportunity.Name = opportunityName;
        opportunity.StageName = 'Shop';
        opportunity.CloseDate = System.today() + 7;
        opportunity.OwnerId = account.OwnerId;

        Date startDate = buildDate(convertedLead.rfi_Start_Year__c, convertedLead.rfi_Start_Month__c, '1');
        if (startDate != null) {
            opportunity.Desired_Start_Date__c = startDate;
            opportunity.Start_Date__c = startDate;
        }

        System.SObjectAccessDecision decision = Security.stripInaccessible(
            AccessType.CREATABLE,
            new List<Opportunity>{ opportunity }
        );
        insert decision.getRecords().get(0);

        // need this to add in the ID from the create api call
        opportunity = (Opportunity) decision.getRecords().get(0);
    }

    private static String buildOpportunityName(Lead convertedLead, Account account) {
        set<String> oppNameStrings = new Set<String>{
            account.LastName,
            firstNonNull(convertedLead.rfi_Course_of_Interest__c, convertedLead.Area_of_Interest__c),
            convertedLead.rfi_Start_Year__c
        };
        oppNameStrings.remove('');
        oppNameStrings.remove(null);

        return (concatStringList(new List<String>(oppNameStrings), ' - '));
    }

    private static Lead getLeadById(Id id) {
        return [
            SELECT
                Id,
                OwnerId,
                Owner.IsActive,
                RecordTypeId,
                FirstName,
                LastName,
                MobilePhone,
                Home_Phone__c,
                Preferred_Phone__c,
                Personal_Email__c,
                Preferred_Email__c,
                IsConverted,
                ConvertedAccountId,
                Hashed_Email__c,
                GClid_Information__c,
                GA_Client_ID__c,
                rfi_Course_of_Interest__c,
                Rfi_Level_of_study__c,
                rfi_Start_Year__c,
                rfi_Start_Month__c,
                Area_of_Interest__c,
                Location_of_Interest__c,
                Mode_of_Interest__c
            FROM Lead
            WHERE Id = :id
        ];
    }

    private static Account doLeadConvert(Lead lead, Registration reg) {
        if (lead.RecordTypeId != studentRecType) {
            Log.debug('Lead convert was skipped, as recordType is not Prospective_Student');
            return null;
        }

        // apply new data to Lead before converting it
        Database.SaveResult leadUpdate = updateLead(lead, reg);

        if (!leadUpdate.isSuccess()) {
            for (Database.Error err : leadUpdate.getErrors()) {
                Log.debug('The following error has occurred: ' + err.getStatusCode() + ': ' + err.getMessage());
            }

            return null;
        }

        // then convert it to an Account
        Database.LeadConvertResult leadConvert = convertLead(Lead);

        if (!leadConvert.isSuccess()) {
            Log.debug('The following errors have occurred: ' + leadConvert.getErrors());
        }

        return updateAccount(leadConvert.getAccountId(), reg);
    }

    public static Database.SaveResult updateLead(Lead lead, Registration reg) {
        lead.FirstName = firstNonNull(reg.firstname, lead.FirstName);
        lead.LastName = firstNonNull(reg.lastname, lead.LastName);

        lead.Personal_Email__c = firstNonNull(reg.email, lead.Personal_Email__c);
        if (lead.Preferred_Email__c == null) {
            lead.Preferred_Email__c = 'Personal';
        }

        setPhoneNumber(
            firstNonNull(reg.phone, lead.Home_Phone__c != null ? lead.Home_Phone__c : lead.MobilePhone),
            lead
        );
        lead.GDPR_Opt_In__c = reg.optIn;

        if (lead.OwnerId.getSobjectType().getDescribe().getName() != 'User') {
            lead.OwnerId = UserInfo.getUserId();
        } else {
            if (!lead.Owner.IsActive) {
                User u = [SELECT Id FROM User WHERE Name = 'Thomas Alston'];
                lead.OwnerId = u.Id;
            }
        }
        lead.LeadSource = reg.leadsource;

        lead.Hashed_Email__c = firstNonNull(reg.hashedEmail, lead.Hashed_Email__c);
        lead.GClid_Information__c = firstNonNull(reg.gaGclId, lead.GClid_Information__c);
        lead.GA_Client_ID__c = firstNonNull(reg.gaGclId, lead.GA_Client_ID__c);

        // apply data update to Lead before converting
        Database.SaveResult leadUpdate = Database.update(lead, false);
        return leadUpdate;
    }

    public static Database.LeadConvertResult convertLead(Lead lead) {
        LeadStatus convertStatus = [
            SELECT Id, MasterLabel
            FROM LeadStatus
            WHERE IsConverted = TRUE
            WITH SECURITY_ENFORCED
            LIMIT 1
        ];

        Database.LeadConvert leadConv = new Database.LeadConvert();
        leadConv.setLeadId(lead.id);
        leadConv.setConvertedStatus(convertStatus.MasterLabel);
        leadConv.setDoNotCreateOpportunity(true);

        Database.LeadConvertResult leadConvertResult = Database.convertLead(leadConv);
        return leadConvertResult;
    }

    public static Account createAccount(Registration reg) {
        Account acc = new Account();
        acc.FirstName = reg.firstname;
        acc.RecordTypeId = studentAccountRecordType;
        acc.LastName = reg.lastname;

        if (reg.email != null && reg.email.endsWithIgnoreCase('@my.bpp.com')) {
            acc.BPP_Email__pc = reg.email;
        } else {
            acc.Personal_Email__pc = reg.email;
        }
        acc.Preferred_Email__pc = (acc.BPP_Email__pc != null ? 'BPP' : 'Personal');

        acc.GDPR_Opt_In__c = reg.optIn;
        acc.PersonLeadSource = reg.leadsource;

        acc.GA_Client_ID__pc = reg.gaClientId;
        acc.GClid_Information__pc = reg.gaGclId;
        acc.Hashed_Email__pc = reg.hashedEmail;
        setPhoneNumber(reg.phone, acc);

        System.SObjectAccessDecision decision = Security.stripInaccessible(
            AccessType.CREATABLE,
            new List<Account>{ acc }
        );
        insert decision.getRecords().get(0);

        // need this to add in the ID from the create api call
        acc = (Account) decision.getRecords().get(0);
        createTask(acc);
        upsertHubAccount(acc, reg);

        return acc;
    }

    private static Account updateAccount(Id id, Registration reg) {
        // get existing Account data for any comparisons
        Account acc = [
            SELECT
                Id,
                RecordTypeId,
                IsPersonAccount,
                FirstName,
                LastName,
                OwnerId,
                Preferred_Phone__pc,
                PersonHomePhone,
                PersonMobilePhone,
                Preferred_Email__pc,
                Personal_Email__pc,
                GA_Client_ID__pc,
                GClid_Information__pc,
                Hashed_Email__pc
            FROM Account
            WHERE Id = :id
        ];

        if (!acc.IsPersonAccount) {
            return null;
        }

        acc.GDPR_Opt_In__c = reg.optIn;
        acc.PersonLeadSource = reg.leadsource;
        acc.GA_Client_ID__pc = firstNonNull(reg.gaClientId, acc.GA_Client_ID__pc);
        acc.GClid_Information__pc = firstNonNull(reg.gaGclId, acc.GClid_Information__pc);
        acc.Hashed_Email__pc = firstNonNull(reg.hashedEmail, acc.Hashed_Email__pc);

        if (!reg.auth0id.startsWith('waad|')) {
            acc.FirstName = (acc.FirstName != reg.firstname ? reg.firstname : acc.FirstName);
            acc.LastName = (acc.LastName != reg.lastname ? reg.lastname : acc.LastName);

            String accountEmail = firstNonNull(reg.email, acc.Personal_Email__pc);
            if (accountEmail.endsWithIgnoreCase('@my.bpp.com')) {
                acc.BPP_Email__pc = accountEmail;
            } else {
                acc.Personal_Email__pc = accountEmail;
            }

            if (acc.Preferred_Email__pc == null && acc.Personal_Email__pc != null) {
                acc.Preferred_Email__pc = 'Personal';
            }

            setPhoneNumber(
                firstNonNull(reg.phone, acc.PersonHomePhone != null ? acc.PersonHomePhone : acc.PersonMobilePhone),
                acc
            );
        }

        Database.DMLOptions dbDML = new Database.DMLOptions();
        dbDML.DuplicateRuleHeader.allowSave = true;
        System.SObjectAccessDecision decision = Security.stripInaccessible(
            AccessType.UPDATABLE,
            new List<Account>{ acc }
        );
        Database.update(decision.getRecords().get(0), dbDML);

        createTask(acc);
        upsertHubAccount(acc, reg);

        return acc;
    }

    public static void upsertHubAccount(Account account, Registration reg) {
        // find by auth0Id or Email or Student__c
        List<Hub_Account__c> matches = [
            SELECT Id, Student__c, Hub_Username__c, Auth0_Id__c
            FROM Hub_Account__c
            WHERE Hub_Username__c = :reg.email OR Auth0_Id__c = :reg.auth0Id
            LIMIT 2
        ];

        if (matches.size() > 1) {
            Log.debug(
                'Unhandled case - Multiple HUB_Account__c objects were matched by query: ' +
                    reg.email +
                    ', ' +
                    reg.auth0Id
            );
            return;
        }

        if (matches.size() == 1) {
            Hub_Account__c existing = matches.get(0);

            if (!String.isBlank(existing.Auth0_Id__c)) {
                return;
            }

            existing.Auth0_Id__c = reg.auth0Id;
            System.SObjectAccessDecision decision = Security.stripInaccessible(
                AccessType.UPDATABLE,
                new List<Hub_Account__c>{ existing }
            );
            update (Hub_Account__c) decision.getRecords().get(0);
            return;
        }

        Hub_Account__c hub = new Hub_Account__c();
        hub.Student__c = account.Id;
        hub.Auth0_Id__c = reg.auth0id;
        hub.Hub_Username__c = reg.email;
        System.SObjectAccessDecision decision = Security.stripInaccessible(
            AccessType.CREATABLE,
            new List<Hub_Account__c>{ hub }
        );

        insert (Hub_Account__c) decision.getRecords().get(0);
    }

    public static void createTask(Account a) {
        if (taskExists(a.Id)) {
            return;
        }

        User u = [
            SELECT Id
            FROM User
            WHERE FirstName = 'Marketing' AND LastName = 'Cloud' AND isActive = TRUE
            WITH SECURITY_ENFORCED
        ];

        Task task = new Task();
        task.RecordTypeId = taskRecordTypeId;
        task.Priority = 'Normal';
        task.Status = 'Completed';
        task.Subject = 'Learner Registered on Hub';
        task.Type = 'Registration';
        task.WhatId = a.Id;
        task.OwnerId = u.Id;

        System.SObjectAccessDecision decision = Security.stripInaccessible(
            AccessType.CREATABLE,
            new List<Task>{ task }
        );
        insert decision.getRecords();

        // Print stripped records
        for (SObject strippedTask : decision.getRecords()) {
            Log.debug(strippedTask);
        }

        // Print modified indexes
        Log.debug(decision.getModifiedIndexes());
    }

    private static Boolean taskExists(Id accountId) {
        Integer existingTasks = [
            SELECT COUNT()
            FROM Task
            WHERE WhatId = :accountId AND RecordTypeId = :taskRecordTypeId AND Subject = 'Learner Registered on Hub'
            WITH SECURITY_ENFORCED
        ];

        return existingTasks > 0;
    }

    private static String lookForLeadId(Registration reg) {
        // look for a matching Lead
        DedupeLead.CheckLead lead = new DedupeLead.CheckLead();
        lead.firstname = reg.firstname;
        lead.lastname = reg.lastname;
        lead.email = reg.email;
        lead.phone = reg.phone;

        DedupeLead.Response checkLeadExists = DedupeLead.doPost(lead);

        if (String.valueOf(checkLeadExists).contains('00Q')) {
            return DedupeHelper.formatResponseId(String.valueOf(checkLeadExists));
        }

        return null;
    }

    private static Hub_Account__c lookForHubAccount(Registration reg) {
        List<Hub_Account__c> hubAccounts = [
            SELECT Id, Student__c, Auth0_Id__c, Hub_Username__c
            FROM Hub_Account__c
            WHERE Auth0_Id__c = :reg.auth0id OR Hub_Username__c = :reg.email
        ];

        Map<String, Hub_Account__c> hubAccountByAuthId = new Map<String, Hub_Account__c>();
        Map<String, Hub_Account__c> hubAccountByUsername = new Map<String, Hub_Account__c>();
        for (Hub_Account__c hubAccount : hubAccounts) {
            hubAccountByAuthId.put(hubAccount.Auth0_Id__c, hubAccount);
            hubAccountByUsername.put(hubAccount.Hub_Username__c, hubAccount);
        }

        if (hubAccountByAuthId.containsKey(reg.auth0id)) {
            return hubAccountByAuthId.get(reg.auth0id);
        }

        if (hubAccountByUsername.containsKey(reg.email)) {
            return hubAccountByUsername.get(reg.email);
        }

        return null;
    }

    private static String lookForAccountId(Registration reg) {
        // look for a matching account
        DedupeAccount.CheckAccount account = new DedupeAccount.CheckAccount();
        account.firstname = reg.firstname;
        account.lastname = reg.lastname;
        account.email = reg.email;
        account.phone = reg.phone;

        DedupeAccount.Response checkAccountExists = DedupeAccount.doPost(account);

        if (String.valueOf(checkAccountExists).contains('001')) {
            return DedupeHelper.formatResponseId(String.valueOf(checkAccountExists));
        }

        return null;
    }

    private static String firstNonNull(String preferred, String fallback) {
        if (preferred != null) {
            return preferred;
        } else {
            return fallback;
        }
    }

    public static void setPhoneNumber(String phone, SObject obj) {
        switch on obj.getSObjectType().getDescribe().getName() {
            when 'Lead' {
                Lead lead = (Lead) obj;
                if (phoneIsUkMobile(phone)) {
                    lead.MobilePhone = phone;
                }
                lead.Home_Phone__c = phone;
                lead.Preferred_Phone__c = (lead.MobilePhone != null ? 'Mobile' : 'Home');
            }
            when 'Account' {
                Account account = (Account) obj;
                if (phoneIsUkMobile(phone)) {
                    account.PersonMobilePhone = phone;
                }
                account.PersonHomePhone = phone;
                account.Preferred_Phone__pc = (account.PersonHomePhone != null ? 'Home' : null);
            }
        }
    }

    public static Boolean phoneIsUkMobile(String phone) {
        return String.isNotEmpty(phone) &&
            (phone.startsWith('07') ||
            phone.startsWith('+447') ||
            phone.startsWith('00447'));
    }

    @TestVisible
    private static Date buildDate(String year, String month, String day) {
        if (year == null || month == null || day == null) {
            return null;
        }

        return Date.valueOf(year + '-' + month + '-' + day);
    }

    private static String concatStringList(List<String> strings, String separator) {
        String concat = String.join(strings, separator);
        String replaced = concat.replaceAll(separator + separator, '');
        return replaced.removeEnd(separator);
    }
}
