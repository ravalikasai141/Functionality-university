@RestResource(urlMapping='/learners/*')
global with sharing class LearnerApplicationService {
    global class Response {
        public Response() {
        }
        global String response { get; set; }
        global String opportunityId { get; set; }

        public Response(String response, String opportunityId) {
            this.response = response;
            this.opportunityId = opportunityId;
        }
    }

    public class RequestWrapper {
        public String applicationDate;
        public String closeDate;
        public String offeringId;
        public String offerType;
        public String source;
        public String refereeEmail;
        public String refereeName;
        public String soc2020;
        public String socioEconomicClassification;
        public String ucasSchemeCode;
        public String ucasChoiceNumber;
    }

    @HttpPost
    global static Response doPost() {
        try {
            Blob body = RestContext.request.requestBody;
            RequestWrapper rw = (RequestWrapper) JSON.deserialize(body.toString(), RequestWrapper.class);
            System.debug(rw);
            cleanUp(rw);

            String result;
            String accountId = RestContext.request.requestURI.substringAfter('/learners/').left(18);
            String opportunityId = lookForOpportunityId(rw, accountId);
            if (opportunityId != null) {
                result = updateOpportunity(opportunityId, rw);
                if (result != null && result.startsWith('006')) {
                    return new Response(
                        'LearnerApplicationService Success: Opportunity - ' + result + ' updated',
                        result
                    );
                } else {
                    return new Response('LearnerApplicationService Opportunity Update Error: ' + result, null);
                }
            }

            result = createOpportunity(accountId, rw);
            if (result != null && result.startsWith('006')) {
                return new Response('LearnerApplicationService Success: Opportunity - ' + result + ' created', result);
            } else {
                return new Response('LearnerApplicationService Opportunity Create Error: ' + result, null);
            }
        } catch (Exception e) {
            return new Response('LearnerApplicationService Error: [' + e.getLineNumber() + '] ' + e.getMessage(), null);
        }
    }

    private static void cleanUp(RequestWrapper rw) {
        rw.applicationDate = DedupeHelper.verifyPostInput(rw.applicationDate);
        rw.closeDate = DedupeHelper.verifyPostInput(rw.closeDate);
        rw.offeringId = DedupeHelper.verifyPostInput(rw.offeringId);
        rw.offerType = DedupeHelper.verifyPostInput(rw.offerType);
        rw.source = DedupeHelper.verifyPostInput(rw.source);
        rw.refereeName = DedupeHelper.verifyPostInput(rw.refereeName);
        rw.soc2020 = DedupeHelper.verifyPostInput(rw.soc2020);
        rw.socioEconomicClassification = DedupeHelper.verifyPostInput(rw.socioEconomicClassification);
        rw.ucasChoiceNumber = DedupeHelper.verifyPostInput(rw.ucasChoiceNumber);
        rw.ucasSchemeCode = DedupeHelper.verifyPostInput(rw.ucasSchemeCode);

        rw.socioEconomicClassification = (rw.socioEconomicClassification != null
            ? LearnerService.setDropdownValueFromCode(
                  rw.socioEconomicClassification,
                  'Socio_economic_classification__c',
                  'Opportunity'
              )
            : null);
    }

    private static String lookForOpportunityId(RequestWrapper rw, String accountId) {
        DedupeOpportunity.CheckOpportunity opportunity = new DedupeOpportunity.CheckOpportunity();
        opportunity.accountId = accountId;
        opportunity.courseInstance = rw.offeringId;
        opportunity.recordSource = rw.source;
        DedupeOpportunity.Response checkOpportunityExists = DedupeOpportunity.doPost(opportunity);

        if (String.valueOf(checkOpportunityExists).contains('006')) {
            return DedupeHelper.formatResponseId(String.valueOf(checkOpportunityExists));
        }
        return null;
    }

    private static String updateOpportunity(Id id, RequestWrapper rw) {
        String result;
        String fields = 'Application_Date__c, CloseDate, Course_Instance__c, Offer_Type__c, Record_Source__c, Referee_Email__c, Referee_Name__c, SOC2020__c, Socio_economic_classification__c, Student_Status__c, UCAS_Application_Scheme_Code__c, UCAS_Choice_Number__c';
        String query = 'SELECT ' + fields + ' FROM Opportunity WHERE Id =: id';

        Opportunity opportunity = Database.query(String.escapeSingleQuotes(query));
        if (opportunity != null) {
            if (DedupeHelper.updateFieldDecision(String.valueOf(opportunity.Application_Date__c), rw.applicationDate)) {
                opportunity.Application_Date__c = Date.valueOf(rw.applicationDate);
            }
            if (DedupeHelper.updateFieldDecision(String.valueOf(opportunity.CloseDate), rw.closeDate)) {
                opportunity.CloseDate = Date.valueOf(rw.closeDate);
            }
            if (DedupeHelper.updateFieldDecision(opportunity.Course_Instance__c, rw.offeringId)) {
                opportunity.Course_Instance__c = rw.offeringId;
            }
            if (DedupeHelper.updateFieldDecision(opportunity.Offer_Type__c, rw.offerType)) {
                opportunity.Offer_Type__c = rw.offerType;
            }
            if (DedupeHelper.updateFieldDecision(opportunity.Record_Source__c, rw.source)) {
                opportunity.Record_Source__c = rw.source;
            }
            if (DedupeHelper.updateFieldDecision(opportunity.Referee_Email__c, rw.refereeEmail)) {
                opportunity.Referee_Email__c = rw.refereeEmail;
                if (DedupeHelper.updateFieldDecision(opportunity.Referee_Name__c, rw.refereeName)) {
                    opportunity.Referee_Name__c = rw.refereeName;
                }
            }
            if (DedupeHelper.updateFieldDecision(String.valueOf(opportunity.SOC2020__c), rw.soc2020)) {
                opportunity.SOC2020__c = Decimal.valueOf(rw.soc2020);
            }
            if (
                DedupeHelper.updateFieldDecision(
                    opportunity.Socio_economic_classification__c,
                    rw.socioEconomicClassification
                )
            ) {
                opportunity.Socio_economic_classification__c = rw.socioEconomicClassification;
            }
            if (DedupeHelper.updateFieldDecision(opportunity.UCAS_Application_Scheme_Code__c, rw.ucasSchemeCode)) {
                opportunity.UCAS_Application_Scheme_Code__c = rw.ucasSchemeCode;
            }
            if (
                DedupeHelper.updateFieldDecision(String.valueOf(opportunity.UCAS_Choice_Number__c), rw.ucasChoiceNumber)
            ) {
                opportunity.UCAS_Choice_Number__c = Decimal.valueOf(rw.ucasChoiceNumber);
            }

            try {
                update opportunity;
                result = opportunity.Id;
            } catch (Exception e) {
                result = 'LearnerService - Opportunity Update Error: [' + e.getLineNumber() + '] ' + e.getMessage();
            }
        }
        return result;
    }

    private static String createOpportunity(String accountId, RequestWrapper rw) {
        String result;
        Opportunity opportunity = new Opportunity();
        if (accountId != null && accountId.startsWith('001') && rw.closeDate != null) {
            Account account = [SELECT OwnerId, Student_Type__pc FROM Account WHERE Id = :accountId];
            opportunity.OwnerId = (account.Student_Type__pc == 'International'
                ? AssignmentUsers__c.getInstance().Default_International_Owner__c
                : AssignmentUsers__c.getInstance().Default_Admissions_Owner__c);
            //opportunity.OwnerId = account.OwnerId;
            opportunity.RecordTypeId = Schema.sObjectType.Opportunity.getRecordTypeInfosByName()
                .get('Application')
                .getRecordTypeId();
            opportunity.AccountId = accountId;
            opportunity.Application_Date__c = (rw.applicationDate != null ? Date.valueOf(rw.applicationDate) : null);
            opportunity.CloseDate = Date.valueOf(rw.closeDate);
            opportunity.Course_Instance__c = rw.offeringId;
            opportunity.Customer_Group__c = 'SELFFUND';
            opportunity.Name = 'Test_' + DedupeHelper.generateRandomString(10);
            opportunity.Offer_Type__c = rw.offerType;
            opportunity.Record_Source__c = rw.source;
            opportunity.Referee_Email__c = rw.refereeEmail;
            opportunity.Referee_Name__c = rw.refereeName;
            opportunity.SOC2020__c = (rw.soc2020 != null ? Integer.valueOf(rw.soc2020) : null);
            opportunity.Socio_economic_classification__c = rw.socioEconomicClassification;
            opportunity.StageName = 'Application';
            opportunity.UCAS_Application_Scheme_Code__c = rw.ucasSchemeCode;
            opportunity.UCAS_Choice_Number__c = (rw.ucasChoiceNumber != null
                ? Decimal.valueOf(rw.ucasChoiceNumber)
                : null);

            try {
                insert opportunity;
                result = opportunity.Id;
            } catch (Exception e) {
                result = 'LearnerApplicationService Error: [' + e.getLineNumber() + '] ' + e.getMessage();
            }
        }
        return result;
    }
}
