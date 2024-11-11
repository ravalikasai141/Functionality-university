public class CaseTriggerHandler extends TriggerHandler {
    private StreamingService stream;

    private List<Case> newCases;
    private List<Case> oldCases;

    private Map<Id, Case> newCasesMap;
    private Map<Id, Case> oldCasesMap;

    /**
     *  Constructor
     */
    public CaseTriggerHandler() {
        TriggerHandler.processOnce('CaseTriggerHandler');
        stream = new StreamingService();

        newCases = Trigger.new;
        oldCases = Trigger.old;

        newCasesMap = (Map<ID, Case>) Trigger.NewMap;
        oldCasesMap = (Map<ID, Case>) Trigger.OldMap;
    }

    public override void beforeInsert() {
    }

    public override void beforeUpdate() {
        CaseTriggerHandler.associateApprenticeOnboardingCaseToOpp(newCases, oldCasesMap);
    }

    public override void beforeDelete() {
    }

    public override void afterInsert() {
        if (!TriggerSettings__c.getInstance().CaseTrigger_SendStatusHolidayLetter__c) {
            CaseTriggerHandler.SendStatusHolidayLetter(newCases);
        }
        stream.process(newCases, new Map<Id, SObject>());
    }

    public override void afterUpdate() {
        stream.process(newCases, oldCasesMap);
    }

    public override void afterDelete() {
    }

    public override void afterUndelete() {
    }

    public static void SendStatusHolidayLetter(List<Case> newCaseList) {
        if (newCaseList.size() == 1) {
            Case currentCase = newCaseList[0];

            List<String> validSubtypes = new List<String>{
                'I would like to request a Bank, Status or Council Tax letter',
                'I would like to request a holiday letter',
                'Holiday'
            };

            List<String> validStatusCodes = new List<String>{
                'REGISTERED',
                'NOT_PROGRESSING',
                'ON PLACEMENT',
                'RESIT ONLY',
                'TEMP_REGISTERED'
            };
            if (
                currentCase.RecordTypeId ==
                Schema.SObjectType.Case.getRecordTypeInfosByName().get('Student Query').getRecordTypeId()
            ) {
                if (
                    (!currentCase.Status_Letter_Sent__c) &&
                    validSubtypes.contains(currentCase.Query_Subtype__c) &&
                    currentCase.Status == 'New' &&
                    currentCase.ContactId != null &&
                    currentCase.Contact_Email__c != null &&
                    currentCase.Query_Type__c == 'Letter requests'
                ) {
                    String recipientEmail;
                    if (currentCase.SuppliedEmail != null) {
                        recipientEmail = currentCase.SuppliedEmail;
                    } else if (currentCase.Contact_Email__c != null) {
                        recipientEmail = currentCase.Contact_Email__c;
                    }
                    String subQueryValue = currentCase.Query_Subtype__c;

                    List<Account> accountList = [
                        SELECT Id, FirstName, Name, BNR_Banner_ID__pc, PersonBirthdate
                        FROM Account
                        WHERE PersonContactId = :currentCase.ContactId
                    ];
                    if (accountList.size() > 0 && accountList[0].BNR_Banner_ID__pc != null) {
                        Account account = accountList[0];
                        List<Opportunity> opportunityList = new List<Opportunity>();
                        for (Opportunity opp : [
                            SELECT
                                Id,
                                Name,
                                BNR_Curriculum_Status_Code__c,
                                Course_Instance__c,
                                Course_Instance__r.Name,
                                Course_Instance__r.End_Date__c,
                                Course_Instance__r.Start_Date__c,
                                Eligible_for_Automated_Holiday_Letter__c
                            FROM Opportunity
                            WHERE AccountId = :account.Id
                            ORDER BY Course_Instance__r.End_Date__c DESC NULLS LAST
                        ]) {
                            if (
                                validStatusCodes.contains(opp.BNR_Curriculum_Status_Code__c) &&
                                opp.Course_Instance__c != null &&
                                (subQueryValue == validSubtypes[0] || opp.Eligible_for_Automated_Holiday_Letter__c)
                            ) {
                                opportunityList.add(opp);
                            }
                        }

                        if (opportunityList.size() > 0) {
                            List<Address__c> addressList = [
                                SELECT
                                    Id,
                                    Type__c,
                                    Street_1__c,
                                    Street_2__c,
                                    Street_3__c,
                                    Street_4__c,
                                    Zip_Postal_Code__c
                                FROM Address__c
                                WHERE Student__c = :account.Id AND Active__c = TRUE
                            ];
                            String mailingAddressId, homeAddressId;
                            for (Address__c address : addressList) {
                                if (address.Type__c == 'Mailing') {
                                    mailingAddressId = address.Id;
                                }
                                if (address.Type__c == 'Home') {
                                    homeAddressId = address.Id;
                                }
                            }
                            if (recipientEmail != null && mailingAddressId != null) {
                                sendPDfEmail.sendPDf(
                                    currentCase.CaseNumber,
                                    currentCase.Thread_Id__c,
                                    currentCase.Id,
                                    recipientEmail,
                                    account.FirstName,
                                    opportunityList[0].Id,
                                    mailingAddressId,
                                    homeAddressId,
                                    subQueryValue
                                );
                            }
                        }
                    }
                }
            }
        }
    }

    public static void associateApprenticeOnboardingCaseToOpp(List<Case> cases, Map<Id, Case> oldCases) {
        Id apprenticeOnboarding = Schema.Sobjecttype.Case.getRecordTypeInfosByName()
            .get('Apprentice Onboarding')
            .getRecordTypeId();

        Map<Case, Id> caseToStudentIds = new Map<Case, Id>();

        for (Case currentCase : cases) {
            if (
                currentCase.RecordTypeId == apprenticeOnboarding &&
                currentCase.AccountId != null &&
                oldCases.get(currentCase.Id).AccountId != currentCase.AccountId
            ) {
                caseToStudentIds.put(currentCase, currentCase.AccountId);
            }
        }

        if (caseToStudentIds.isEmpty()) {
            return;
        }

        List<AggregateResult> agregateOpportunities = [
            SELECT AccountId, Max(Id) OpportunityId
            FROM Opportunity
            WHERE Recordtype.Name = 'Apprentice Application' AND AccountId IN :caseToStudentIds.values()
            GROUP BY AccountId
            HAVING COUNT(AccountId) = 1
        ];

        Map<Id, Id> accountIdToOppId = new Map<Id, Id>();
        for (AggregateResult currentAgreGateOpp : agregateOpportunities) {
            Id opportunityId = (Id) currentAgreGateOpp.get('OpportunityId');
            Id accountId = (Id) currentAgreGateOpp.get('AccountId');

            accountIdToOppId.put(accountId, opportunityId);
        }

        for (Case currentCase : caseToStudentIds.keySet()) {
            if (!accountIdToOppId.containsKey(currentCase.AccountId)) {
                continue;
            }

            currentCase.Opportunity__c = accountIdToOppId.get(currentCase.AccountId);
        }
    }
}
