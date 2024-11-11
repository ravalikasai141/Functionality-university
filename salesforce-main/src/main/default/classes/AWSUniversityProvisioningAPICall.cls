global class AWSUniversityProvisioningAPICall {
    public class JSONDigital {
        public String userId;
        public String userName;
        public String personEmail;
        public String firstname;
        public String lastname;
        public String phone;
        public String bannerId;
        public String ProductInstanceID;
        public Boolean marketingoptin;
        public List<DigitalContent> digitalContent;
    }

    public class DigitalContent {
        public Boolean active;
        public String hostsystem;
        public String name;
        public String programme;
        public String systemreference;
        public String title;
    }

    @future(callout=true)
    public static void awsProvisioningCallout(Id accountId, Id opportunityId) {
        Id recordId;
        String response;
        AWSsampleAPIUtil.AuthToken at = AWSsampleAPIUtil.getAccessToken();

        JSONDigital json = new JSONDigital();
        if (accountId != null) {
            recordId = accountId;
            json = generateAccountPayload(accountId);
        }
        if (opportunityId != null) {
            recordId = opportunityId;
            json = generateOpportunityPayload(opportunityId);
        }
        if (json != null && recordId != null) {
            Integration_Log__c integ = new Integration_Log__c();
            String endpoint = AWSsampleAPIUtil.retrieveAWSEndpoint() + '/student/admit';
            String message = System.JSON.serialize(json);

            HttpRequest httpRequest = new HttpRequest();
            httpRequest.setMethod('POST');
            httpRequest.setBody(message);
            httpRequest.setEndpoint(endpoint);
            httpRequest.setHeader('Authorization', 'Bearer ' + at.token);
            httpRequest.setHeader('Content-Type', 'application/json');

            try {
                HttpResponse httpResponse = new Http().send(httpRequest);
                response = httpResponse.getStatusCode() + ': ' + httpResponse.getBody();
            } catch (System.Exception e) {
                response += ' : ' + String.valueOf(e.getMessage());
            } finally {
                integ = AWSsampleAPIUtil.createIntegrationLog('HUB', endpoint, response, recordId);
                insert integ;

                if (!at.valid) {
                    update at.authToken;
                }
            }
        }
    }

    private static JSONDigital generateAccountPayload(Id accountId) {
        List<DigitalContent> digitalContentList = new List<DigitalContent>();
        Set<Id> programmeIds = new Set<Id>();
        String productInstanceID;

        Account account = [
            SELECT Id, FirstName, LastName, Phone, Email_Address__pc, PersonEmail, BNR_Banner_ID__pc
            FROM Account
            WHERE Id = :accountId
        ];
        for (Opportunity opp : [
            SELECT
                Id,
                AccountId,
                StageName,
                BNR_Curriculum_Status_Code__c,
                Programme_Application__c,
                Course_Instance__r.ProductCode
            FROM Opportunity
            WHERE
                AccountId = :accountId
                AND (StageName = 'Accepted - Conditional Firm'
                OR StageName = 'Accepted - Unconditional Firm'
                OR StageName = 'Accepted - Pmt Received')
        ]) {
            productInstanceID = opp.Course_Instance__r.ProductCode;
            if (opp.Programme_Application__c != null) {
                programmeIds.add(opp.Programme_Application__c);
            }
        }

        if (programmeIds.size() > 0) {
            digitalContentList = buildDigitalContentArray(programmeIds);
        }

        JSONDigital json = new JSONDigital();
        json.userId = account.Id;
        json.username = account.Email_Address__pc;
        json.personEmail = account.Email_Address__pc;
        json.firstname = account.FirstName;
        json.lastname = account.LastName;
        json.phone = account.Phone;
        json.bannerId = account.BNR_Banner_ID__pc;
        json.marketingoptin = false;
        json.ProductInstanceID = productInstanceID;
        json.digitalContent = digitalContentList;
        return json;
    }

    private static JSONDigital generateOpportunityPayload(Id opportunityId) {
        List<DigitalContent> digitalContentList = new List<DigitalContent>();

        Opportunity opportunity = [
            SELECT
                Id,
                StageName,
                Course_Instance__r.ProductCode,
                Programme_Application__c,
                AccountId,
                Account.FirstName,
                Account.LastName,
                Account.Phone,
                Account.Email_Address__pc,
                Account.BNR_Banner_ID__pc,
                Account.HUB_Student__c
            FROM Opportunity
            WHERE Id = :opportunityId
        ];
        String productInstanceID = opportunity.Course_Instance__r.ProductCode;
        Set<Id> programmeIds = new Set<Id>{ opportunity.Programme_Application__c };

        if (programmeIds.size() > 0) {
            digitalContentList = buildDigitalContentArray(programmeIds);
        }

        JSONDigital json = new JSONDigital();
        json.userId = opportunity.AccountId;
        json.username = opportunity.Account.Email_Address__pc;
        json.personEmail = opportunity.Account.Email_Address__pc;
        json.firstname = opportunity.Account.FirstName;
        json.lastname = opportunity.Account.LastName;
        json.phone = opportunity.Account.Phone;
        json.bannerId = opportunity.Account.BNR_Banner_ID__pc;
        json.marketingoptin = false;
        json.ProductInstanceID = productInstanceID;
        json.digitalContent = digitalContentList;
        return json;
    }

    private static List<DigitalContent> buildDigitalContentArray(Set<Id> programmeIds) {
        List<DigitalContent> digitalContentList = new List<DigitalContent>();
        List<Digital_Content__c> digilist = [
            SELECT Id, Active__c, Name, Programme__c, Host_System__c, System_Reference__c, Title__c
            FROM Digital_Content__c
            WHERE Active__c = TRUE AND Programme__c = :programmeIds
        ];
        if (digilist.size() > 0) {
            for (Digital_Content__c obj : digilist) {
                DigitalContent dc = new DigitalContent();
                dc.active = obj.Active__c;
                dc.hostsystem = obj.Host_System__c;
                dc.name = obj.Name;
                dc.programme = obj.Programme__c;
                dc.systemreference = obj.System_Reference__c;
                dc.title = obj.Title__c;
                digitalContentList.add(dc);
            }
        }
        return digitalContentList;
    }
}
