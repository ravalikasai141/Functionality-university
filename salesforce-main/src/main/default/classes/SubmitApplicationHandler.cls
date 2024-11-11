// Class adapted from submitAppBController and BNR_SubmitApplication for Apprentice applications
global class SubmitApplicationHandler {
    private static String successMsg = 'Application Submitted Successfully';
    @testVisible
    private static String OFFERING_PRDTYPE = 'OFFERING';

    @testVisible
    private static HttpResponse applicationResult;

    /**
     * Validat that required fields are set and send application
     * @param  recordId Id of opp for application
     * @return          error or success message
     */
    @AuraEnabled
    public static string checkApplication(Id recordId) {
        Opportunity opp = [
            SELECT
                Id,
                Name,
                AccountId,
                /* fields used (just) for validation */
                StageName,
                BPP_Sub_Status__c,
                /* fields used for request */
                SFDC_Application_Number__c,
                SFDC_Term_Code_Entry_Select__c,
                SFDC_Curriculum_Campus_Code_Select__c,
                SFDC_Curriculum_Program_Code_Select__c,
                SFDC_FieldOfStudy_Code_Select__c,
                BNR_Application_Decision_Comment__c,
                SFDC_Attribute_Code_Select__c,
                SFDC_Admissions_ADMT_Code_Select__c,
                SFDC_Admissions_STYPE_Code_Select__c,
                SFDC_Admissions_RESD_Code_Select__c,
                SFDC_Curriculum_Level_Code_Select__c,
                SFDC_Curriculum_Degree_Code_Select__c,
                SFDC_Cohort_Code_Select__c,
                BNR_Campus_Code_Text__c,
                BNR_Degree_Code_Text__c,
                BNR_FieldOfStudy_Code__c,
                BNR_Level_Code_Text__c,
                BNR_Program_Code_Text__c,
                BNR_Term_Code_Text__c,
                SFDC_Decision_Code__c,
                Sponsorship_Level__c,
                Sponsorship_Amount__c,
                Sponsorship_Percentage__c,
                AP_ID__c,
                Purchase_Order_Number__c,
                SFDC_Attribute_Code_Select_v2__c,
                PC_Attribute_Code__c,
                PC_Attribute_Code_2__c,
                PC_Attribute_Code_3__c,
                Customer_Group__c,
                International_Student__c,
                CAS_status__c,
                Course_Instance__c
            FROM Opportunity
            WHERE Id = :recordId
        ];

        Account account = [
            SELECT
                Id,
                /* fields used (just) for validation */
                AR_Account_Status_Code__c,
                Account_Type__c,
                VAT_Code__pc,
                Phone,
                PersonEmail,
                PersonBirthdate,
                /* fields used for request */
                OwnerId,
                PS_Profile_Services_ID__pc,
                BNR_Banner_ID__pc,
                SFDC_Disability_Status_Code_Select__pc,
                Legal_Entity__c,
                Student_Type__pc,
                AR_Customer_Number__c,
                AR_Global_Customer_Number__c,
                AR_Discount_Eligible__c,
                SFDC_Country_of_Birth__pc,
                SFDC_Country_of_Birth__pr.ISO_CODE__c,
                Primary_Nationality__pc,
                Primary_Nationality__pr.ISO_CODE__c,
                Parent_Guardian_Occupation__pc,
                Student_Occupation__pc,
                Age__pc,
                Country_of_Permanent_Address__c,
                Country_of_Permanent_Address__r.country_code_2__c,
                Sexual_Orientation__pc,
                Gender_Identity__pc,
                Religion__pc
            FROM Account
            WHERE Id = :opp.accountId
        ];

        if (opp == null || account == null) {
            return 'Opportunity or Acount not found';
        }
        if (account.AR_Account_Status_Code__c == 'FinancialHoldApplied') {
            return 'Student is on Financial Hold. Application cannot be submitted';
        }
        if (opp.StageName != 'Acceptance' && opp.BPP_Sub_Status__c != 'Completed') {
            return 'Submit Application Failed because the Status is not valid';
        }
        if (account.PS_Profile_Services_ID__pc == null) {
            return 'The related Account does not have a Profile ID. A Profile ID is required to submit an application';
        }

        List<Address__c> address = [
            SELECT Id, Active__c, Type__c
            FROM Address__c
            WHERE Active__c = TRUE AND Student__c = :opp.AccountId
        ];
        if (address.isEmpty()) {
            return 'At least One Active Address is Required';
        }

        List<String> requiredErrors = new List<String>();

        if (account.PersonBirthdate == null) {
            requiredErrors.add('Student Date of Birth');
        }
        if (account.Primary_Nationality__pc == null) {
            requiredErrors.add('Student Primary Nationality');
        }
        if (account.Student_Type__pc == null) {
            requiredErrors.add('Student Type');
        }
        if (account.Legal_Entity__c == null) {
            requiredErrors.add('Legal Entity');
        }

        if (!requiredErrors.isEmpty()) {
            return 'Following fields are required before submitting: ' + String.join(requiredErrors, ', ');
        }

        Legal_Entity__c cs = Legal_Entity__c.getValues(account.Legal_Entity__c);
        if (cs == null) {
            return 'Setting for Legal Entity ' + account.Legal_Entity__c + ' does not exist';
        }

        List<Sponsorship__c> sponsorship = [
            SELECT Id, Active__c, Student__c
            FROM Sponsorship__c
            WHERE Active__c = TRUE AND Student__c = :opp.AccountId AND Opportunity__c = :opp.Id
        ];
        if (
            sponsorship.isEmpty() &&
            opp.Sponsorship_Level__c != null &&
            opp.Sponsorship_Percentage__c != null &&
            opp.Sponsorship_Amount__c != null
        ) {
            return 'An Active Sponsorship record on Account should exist if Sponsorship level is Partial or Full';
        }

        submitCalloutWrapper classTwoWrap = submitApplication(opp, account);

        if (classTwoWrap.newResult != 'Application Submitted Successfully') {
            return classTwoWrap.newResult;
        }

        insert classTwoWrap.newApp;

        classTwoWrap.opp.SFDC_Application_Number__c = classTwoWrap.newApp.id;
        update classTwoWrap.opp;
        update classTwoWrap.prodList;
        update classTwoWrap.acc;

        return 'Application Submitted';
    }

    /**
     * submit Application by sending request to ARStudentAccountService, PersonService and submitApplicationRequest service
     * @param  opp opportunity to submit
     * @return     return updated records and result message
     */
    webService static submitCalloutWrapper submitApplication(Opportunity opp, Account acc) {
        Application__c newApp1 = new Application__c();

        List<Product2> products = [
            SELECT
                Name,
                Programme__r.BNR_College_Code__c,
                Programme__r.BNR_FieldOfStudy_Code__c,
                BNR_FieldOfStudy_Start_Date__c,
                Programme__r.Programme_Id__c,
                Programme__c,
                Product_Type__c,
                Mode__c,
                Id,
                BNR_Program_Code__c,
                BNR_Level_Code__c,
                BNR_Degree_Code__c,
                BNR_Campus_Code__c,
                BNR_Term_Code__c,
                BNR_Attribute_Code__c,
                Instance_Id__c,
                BNR_Max_Capacity__c,
                BNR_Min_Capacity__c,
                BNR_Used_Capacity__c,
                Start_Date__c,
                End_Date__c
            FROM Product2
            WHERE Id = :opp.Course_Instance__c
        ];

        if (products.isEmpty()) {
            return new submitCalloutWrapper('At least one Product is required');
        }

        Product2 product = products[0];

        String missingValues = '';
        if (product.Instance_Id__c == null || product.Instance_Id__c == '') {
            missingValues += 'Instance Id';
        }
        if (product.Programme__r.Programme_Id__c == null || product.Programme__r.Programme_Id__c == '') {
            if (missingValues != '')
                missingvalues = missingValues + ',';
            missingValues += 'Program Code';
        }

        if (missingValues != '') {
            return new submitCalloutWrapper(missingValues + ': Missing for Product with Name: ' + product.Name);
        }

        List<Sponsorship__c> sponsorships = [
            SELECT Id, Name, Student__c, Opportunity__c, Company__c
            FROM Sponsorship__c
            WHERE Student__c = :acc.Id AND Opportunity__c = :opp.Id AND Active__c = TRUE
        ];
        Set<Id> allCompanyIds = new Set<Id>();
        for (Sponsorship__c sponsorship : sponsorships) {
            allCompanyIds.add(sponsorship.Company__c);
        }
        List<Account> sponAccount = [SELECT Id, Name, SIS_Company_ID__c FROM Account WHERE Id IN :allCompanyIds];
        String result;
        String resultXml;
        ARStudentAccountService.ARCustomerFields arResult = null;

        if (
            (acc.AR_Customer_Number__c == null ||
            acc.AR_Customer_Number__c == '') &&
            (acc.AR_Global_Customer_Number__c == null ||
            acc.AR_Global_Customer_Number__c == '') &&
            (acc.Legal_Entity__c == 'UC~COL' ||
            acc.Legal_Entity__c == 'UC~WEB')
        ) {
            arResult = ARStudentAccountService.CreateARStudentAccount(acc, opp);
            if (arResult.Status == 'Success') {
                acc.AR_Customer_Number__c = arResult.ARCustomerNumber;
                acc.AR_Global_Customer_Number__c = arResult.ARGlobalCustomerNumber;
            } else {
                acc.Last_Error__c = arResult.Status;
                result = arResult.Status;
                resultXml = result.removeStart('ERROR:  ');

                XmlStreamReader reader = new XmlStreamReader(resultXml);
                while (reader.hasNext()) {
                    if (reader.getEventType() == XmlTag.START_ELEMENT) {
                        if ('errorDescription' == reader.getLocalName()) {
                            reader.next();
                            if (reader.hasText()) {
                                result = reader.getText();
                                result = 'ARStudentAccountService Error: ' + result;
                            }
                        }
                    }
                    reader.next();
                }

                return new submitCalloutWrapper(newApp1, acc, opp, result, new List<Product2>{ product });
            }
        }

        if (
            ((acc.AR_Customer_Number__c != null && acc.AR_Customer_Number__c != '') &&
            (acc.AR_Global_Customer_Number__c != null &&
            acc.AR_Global_Customer_Number__c != '')) ||
            (acc.Legal_Entity__c != 'UC~COL' &&
            acc.Legal_Entity__c != 'UC~WEB')
        ) {
            result = BNR_SubmitApplication.GetStudentIdByProfileId(acc.PS_Profile_Services_ID__pc);
            if (result.indexOf('<per:studentID>') != -1) {
                result = result.substring(result.indexOf('<per:studentID>') + 15);
                result = result.substring(0, result.indexOf('<'));
                acc.BNR_Banner_ID__pc = result;
            } else {
                acc.Last_Error__c = result;
                resultXml = result;
                XmlStreamReader reader = new XmlStreamReader(resultXml);
                while (reader.hasNext()) {
                    if (reader.getEventType() == XmlTag.START_ELEMENT) {
                        if ('errorDescription' == reader.getLocalName()) {
                            reader.next();
                            if (reader.hasText()) {
                                result = reader.getText();
                                result = 'StudentIDService Error: ' + result;
                            }
                        }
                    }
                    reader.next();
                }
                return new submitCalloutWrapper(newApp1, acc, opp, result, new List<Product2>{ product });
            }
            if (acc.BNR_Banner_ID__pc != null && acc.BNR_Banner_ID__pc != '') {
                Application__c newApp = new Application__c();
                newApp.PS_Profile_Services_ID__c = acc.PS_Profile_Services_ID__pc;
                newApp.BNR_Banner_ID__c = acc.BNR_Banner_ID__pc;
                newApp.BNR_Application_Decision_Comment__c = opp.BNR_Application_Decision_Comment__c;

                if (opp.SFDC_Admissions_ADMT_Code_Select__c != null) {
                    newApp.BNR_Admissions_ADMT_Code__c = ExtractCode(opp.SFDC_Admissions_ADMT_Code_Select__c);
                }
                if (opp.SFDC_Admissions_STYPE_Code_Select__c != null) {
                    newApp.BNR_Admissions_STYPE_Code__c = ExtractCode(opp.SFDC_Admissions_STYPE_Code_Select__c);
                }
                if (opp.SFDC_Admissions_RESD_Code_Select__c != null) {
                    newApp.BNR_Admissions_RESD_Code__c = ExtractCode(opp.SFDC_Admissions_RESD_Code_Select__c);
                }
                if (opp.SFDC_Cohort_Code_Select__c != null) {
                    newApp.BNR_Cohort_Code__c = ExtractCode(opp.SFDC_Cohort_Code_Select__c);
                }
                if (acc.SFDC_Disability_Status_Code_Select__pc != null) {
                    newApp.BNR_Disability_Status_Code__c = ExtractCode(acc.SFDC_Disability_Status_Code_Select__pc);
                }

                result = submitApplicationRequest(opp, newApp, acc, sponsorships, sponAccount, product);

                if (result.equals(successMsg)) {
                    newApp.RecordTypeId = Schema.SObjectType.Application__c.getRecordTypeInfosByDeveloperName()
                        .get('Locked')
                        .getRecordTypeId();

                    newApp1 = newApp;
                    opp.SFDC_Application_Number__c = newApp.Id;

                    opp.StageName = 'Closed Won';
                    opp.BPP_Sub_Status__c = 'Booked';
                } else {
                    opp.Last_Error__c = result;
                    resultXml = result.removeStart('ERROR:  ');
                    XmlStreamReader reader = new XmlStreamReader(resultXml);
                    while (reader.hasNext()) {
                        if (reader.getEventType() == XmlTag.START_ELEMENT) {
                            if ('errorDescription' == reader.getLocalName()) {
                                reader.next();
                                if (reader.hasText()) {
                                    result = reader.getText();
                                    result = 'Submit Application Service Error: ' + result;
                                }
                            }
                        }
                        reader.next();
                    }
                }
            }
        }

        return new submitCalloutWrapper(newApp1, acc, opp, result, new List<Product2>{ product });
    }

    /**
     * Construct and submit application request
     * @param  opp         opp used in appplication
     * @param  app         app used in appplication
     * @param  account     account used in appplication
     * @param  sponsorship sponsorship used in appplication
     * @param  sponAccount sponsorship Account used in appplication
     * @param  product     product used in appplication
     * @return             return description
     */
    private static String submitApplicationRequest(
        Opportunity opp,
        Application__c app,
        Account account,
        list<Sponsorship__c> sponsorship,
        list<Account> sponAccount,
        Product2 product
    ) {
        String requestStr =
            '<soapenv:Envelope ' +
            'xmlns:tns="http://platform.apollogrp.edu/model/apolloglobal/crm/v2/Application" ' +
            'xmlns:appln="http://platform.apollogrp.edu/model/apolloglobal/crm/v2/Application" ' +
            'xmlns:services="http://platform.apollogrp.edu/services/apolloglobal/crm/application/v2" ' +
            'xmlns:entity="http://platform.apollogrp.edu/model/apolloglobal/sis/v1/entity" ' +
            'xmlns:academics="http://platform.apollogrp.edu/model/apolloglobal/sis/v1/Academics" ' +
            'xmlns:types="http://platform.apollogrp.edu/model/apolloglobal/person/v1/types" ' +
            'xmlns:internationalDetail="http://platform.apollogrp.edu/model/apolloglobal/person/v1/InternationalDetail" ' +
            'xmlns:bannercode="http://platform.apollogrp.edu/model/apolloglobal/banner/v1/BannerFields" ' +
            'xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/">';
        requestStr += '<soapenv:Header/><soapenv:Body><services:submitApplicationRequest>';
        requestStr += '<appln:ApplicationDetail>';
        requestStr += '<appln:ApplicationId>' + opp.Id + '</appln:ApplicationId>';
        requestStr += '<appln:ProfileId>' + app.PS_Profile_Services_ID__c + '</appln:ProfileId>';
        requestStr += '<appln:StudentId>' + app.BNR_Banner_ID__c + '</appln:StudentId>';

        if (app.BNR_Disability_Type_Code__c != null) {
            requestStr += '<appln:StudentDisabilities>';
            if (app.BNR_Disability_Type_Code__c != null) {
                requestStr += '<entity:DisabilityCode>' + app.BNR_Disability_Type_Code__c + '</entity:DisabilityCode>';
            }
            if (app.BNR_Disability_Status_Code__c != null) {
                requestStr += '<entity:MedicalCode>' + app.BNR_Disability_Status_Code__c + '</entity:MedicalCode>';
            }
            requestStr += '</appln:StudentDisabilities>';
        }

        if (product.Product_Type__c == OFFERING_PRDTYPE) {
            requestStr += '<appln:CurriculumDetail>';
            if (product.Programme__r.Programme_Id__c != null && product.Programme__r.Programme_Id__c != '')
                requestStr += '<appln:ProgramCode>' + product.Programme__r.Programme_Id__c + '</appln:ProgramCode>';

            boolean isPrimary = true;
            requestStr += '<appln:IsPrimary>' + isPrimary + '</appln:IsPrimary>';
            if (product.BNR_Term_Code__c != null && product.BNR_Term_Code__c != '')
                requestStr += '<appln:TermCode>' + product.BNR_Term_Code__c + '</appln:TermCode>';
            if (product.BNR_Level_Code__c != null && product.BNR_Level_Code__c != '')
                requestStr += '<appln:LevelCode>' + product.BNR_Level_Code__c + '</appln:LevelCode>';
            if (product.BNR_Campus_Code__c != null && product.BNR_Campus_Code__c != '')
                requestStr += '<appln:CampusCode>' + product.BNR_Campus_Code__c + '</appln:CampusCode>';
            if (product.Programme__r.BNR_College_Code__c != null && product.Programme__r.BNR_College_Code__c != '')
                requestStr += '<appln:CollegeCode>' + product.Programme__r.BNR_College_Code__c + '</appln:CollegeCode>'; //temp school
            if (product.BNR_Degree_Code__c != null && product.BNR_Degree_Code__c != '')
                requestStr += '<appln:DegreeCode>' + product.BNR_Degree_Code__c + '</appln:DegreeCode>';
            if (
                product.Programme__r.BNR_FieldOfStudy_Code__c != null &&
                product.Programme__r.BNR_FieldOfStudy_Code__c != ''
            )
                requestStr +=
                    '<appln:MajorCode>' +
                    product.Programme__r.BNR_FieldOfStudy_Code__c +
                    '</appln:MajorCode>';
            if (product.BNR_FieldOfStudy_Start_Date__c != null) {
                //Format Start Date
                Integer StartYear = product.BNR_FieldOfStudy_Start_Date__c.year();
                Integer StartMonth = product.BNR_FieldOfStudy_Start_Date__c.month();
                String StartMonth_string = string.valueof(StartMonth);
                if (StartMonth_string.length() == 1)
                    StartMonth_string = '0' + StartMonth_string;

                Integer StartDay = product.BNR_FieldOfStudy_Start_Date__c.day();
                String StartDay_string = string.valueof(StartDay);
                if (StartDay_string.length() == 1)
                    StartDay_string = '0' + StartDay_string;

                String FieldOfStudy_Start_Date = StartYear + '-' + StartMonth_string + '-' + StartDay_string;
                requestStr +=
                    '<appln:FieldOfStudyStartDate >' +
                    FieldOfStudy_Start_Date +
                    '</appln:FieldOfStudyStartDate>';
            }
            String modeV = (product.Mode__c.contains('Full') ? 'F' : 'P');
            requestStr += '<appln:FullOrPartTimeInd>' + modeV + '</appln:FullOrPartTimeInd>';

            if (product.Start_Date__c != null && product.End_Date__c != null) {
                //Format Start Date
                Integer StartYear = product.Start_Date__c.year();
                Integer StartMonth = product.Start_Date__c.month();
                String StartMonth_string = string.valueof(StartMonth);
                if (StartMonth_string.length() == 1)
                    StartMonth_string = '0' + StartMonth_string;

                Integer StartDay = product.Start_Date__c.day();
                String StartDay_string = string.valueof(StartDay);
                if (StartDay_string.length() == 1)
                    StartDay_string = '0' + StartDay_string;

                String StartDate = StartYear + '-' + StartMonth_string + '-' + StartDay_string;

                //Format End Date
                Integer EndYear = product.End_Date__c.year();

                Integer EndMonth = product.End_Date__c.month();
                String EndMonth_string = string.valueof(EndMonth);
                if (EndMonth_string.length() == 1)
                    EndMonth_string = '0' + EndMonth_string;

                Integer EndDay = product.End_Date__c.day();
                String EndDay_string = string.valueof(EndDay);
                if (EndDay_string.length() == 1)
                    EndDay_string = '0' + EndDay_string;

                String EndDate = EndYear + '-' + EndMonth_string + '-' + EndDay_string;

                requestStr += '<appln:curriculumPeriod>';
                requestStr += '<bannercode:from>' + StartDate + '</bannercode:from>';
                requestStr += '<bannercode:to>' + EndDate + '</bannercode:to>';
                requestStr += '</appln:curriculumPeriod>';
            }

            requestStr += '</appln:CurriculumDetail>';
        }
        requestStr += '<appln:ApplicationItems>';
        requestStr += '<appln:items><appln:id>' + product.Instance_Id__c + '</appln:id>';
        requestStr += '<appln:type>' + product.Product_Type__c + '</appln:type></appln:items>';
        requestStr += '</appln:ApplicationItems>';

        if (app.BNR_Admissions_ADMT_Code__c != null) {
            requestStr += '<appln:AdmissionType>' + app.BNR_Admissions_ADMT_Code__c + '</appln:AdmissionType>';
        }
        if (app.BNR_Admissions_STYPE_Code__c != null) {
            requestStr += '<appln:StudentType>' + app.BNR_Admissions_STYPE_Code__c + '</appln:StudentType>';
        }
        if (app.BNR_Admissions_RESD_Code__c != null) {
            requestStr += '<appln:ResidencyCode>' + app.BNR_Admissions_RESD_Code__c + '</appln:ResidencyCode>';
        }
        requestStr +=
            '<appln:ApplicationDecisionCode>' +
            opp.SFDC_Decision_Code__c +
            '</appln:ApplicationDecisionCode>';
        if (app.BNR_Application_Decision_Comment__c != null) {
            requestStr +=
                '<appln:DecisionComment><entity:ApplicationDecisionComment>' +
                app.BNR_Application_Decision_Comment__c +
                '</entity:ApplicationDecisionComment></appln:DecisionComment>';
        }

        if (opp.PC_Attribute_Code__c != null) {
            requestStr += '<appln:ApplicationAttibutes>';
            if (opp.International_Student__c == true)
                requestStr += '<appln:value>IN</appln:value>';

            if (opp.PC_Attribute_Code__c != null)
                requestStr += '<appln:value>' + opp.PC_Attribute_Code__c + '</appln:value>';

            if (opp.PC_Attribute_Code_2__c != null)
                requestStr += '<appln:value>' + opp.PC_Attribute_Code_2__c + '</appln:value>';

            if (opp.PC_Attribute_Code_3__c != null)
                requestStr += '<appln:value>' + opp.PC_Attribute_Code_3__c + '</appln:value>';

            if (opp.SFDC_Attribute_Code_Select_v2__c != null) {
                String[] listOfCodes = opp.SFDC_Attribute_Code_Select_v2__c.split(';');
                for (String atr_cd : listOfCodes) {
                    atr_cd = ExtractCode(atr_cd);
                    requestStr += '<appln:value>' + atr_cd + '</appln:value>';
                }
            }
            requestStr += '</appln:ApplicationAttibutes>';
        }

        if (app.BNR_Cohort_Code__c != null) {
            requestStr += '<appln:CohortCode>' + app.BNR_Cohort_Code__c + '</appln:CohortCode>';
        }
        if (account.SFDC_Country_of_Birth__pc != null || account.Primary_Nationality__pc != null) {
            requestStr += '<internationalDetail:InternationalDetail>';
            if (account.SFDC_Country_of_Birth__pr.ISO_CODE__c != null) {
                requestStr +=
                    '<internationalDetail:BirthCountry>' +
                    account.SFDC_Country_of_Birth__pr.ISO_CODE__c +
                    '</internationalDetail:BirthCountry>';
            }
            if (account.Primary_Nationality__pr.ISO_CODE__c != null) {
                requestStr +=
                    '<internationalDetail:CitizenshipCountryCode>' +
                    account.Primary_Nationality__pr.ISO_CODE__c +
                    '</internationalDetail:CitizenshipCountryCode>';
            }
            requestStr += '</internationalDetail:InternationalDetail>';
        }
        requestStr += '<appln:ApplicationExtension>';
        requestStr += (sponsorship.size() > 0
            ? '<entity:ExtensionElement><entity:Key>INTAKE_TYPE</entity:Key><entity:Value>SPONSORED</entity:Value></entity:ExtensionElement>'
            : '<entity:ExtensionElement><entity:Key>INTAKE_TYPE</entity:Key><entity:Value>SELFPAY</entity:Value></entity:ExtensionElement>');

        if (account.Legal_Entity__c != null) {
            Legal_Entity__c cs = Legal_Entity__c.getValues(account.Legal_Entity__c);
            String entity = cs.Entity__c;
            Boolean ARIntegration = cs.AR_Integration__c;
            requestStr +=
                '<entity:ExtensionElement><entity:Key>LEGAL_ENTITY_ID</entity:Key><entity:Value>' +
                entity +
                '</entity:Value></entity:ExtensionElement>';
        }
        if (sponAccount.size() > 0) {
            String reqSponsorSIS = '';
            for (Account acc : sponAccount) {
                reqSponsorSIS +=
                    '<entity:ExtensionElement><entity:Key>SPONSOR_SIS_ID</entity:Key><entity:Value>' +
                    acc.SIS_Company_ID__c +
                    '</entity:Value></entity:ExtensionElement>';
            }
            requestStr += reqSponsorSIS;
        }
        requestStr += (account.AR_Discount_Eligible__c
            ? '<entity:ExtensionElement><entity:Key>DISCOUNT_ELIGIBLE</entity:Key><entity:Value>Y</entity:Value></entity:ExtensionElement>'
            : '<entity:ExtensionElement><entity:Key>DISCOUNT_ELIGIBLE</entity:Key><entity:Value>N</entity:Value></entity:ExtensionElement>');

        if (opp.Sponsorship_Level__c != null) {
            requestStr +=
                '<entity:ExtensionElement><entity:Key>SPONSORSHIP_LEVEL</entity:Key><entity:Value>' +
                opp.Sponsorship_Level__c +
                '</entity:Value></entity:ExtensionElement>';
        }
        if (opp.Customer_Group__c != null) {
            requestStr +=
                '<entity:ExtensionElement><entity:Key>CUSTOMER_GROUP</entity:Key><entity:Value>' +
                opp.Customer_Group__c +
                '</entity:Value></entity:ExtensionElement>';
        }
        if (opp.Sponsorship_Amount__c != null) {
            requestStr +=
                '<entity:ExtensionElement><entity:Key>SPONSORSHIP_AMOUNT</entity:Key><entity:Value>' +
                opp.Sponsorship_Amount__c +
                '</entity:Value></entity:ExtensionElement>';
        }
        if (opp.Sponsorship_Percentage__c != null) {
            requestStr +=
                '<entity:ExtensionElement><entity:Key>SPONSORED_PERCENTAGE</entity:Key><entity:Value>' +
                opp.Sponsorship_Percentage__c +
                '</entity:Value></entity:ExtensionElement>';
        }
        if (opp.Ap_ID__C != null)
            requestStr +=
                '<entity:ExtensionElement><entity:Key>CRM_APPL_ID</entity:Key><entity:Value>' +
                opp.AP_ID__c +
                '</entity:Value></entity:ExtensionElement>';

        if (opp.Purchase_Order_Number__c != null)
            requestStr +=
                '<entity:ExtensionElement><entity:Key>PURCH_ORDER_FORM_NUM</entity:Key><entity:Value>' +
                opp.Purchase_Order_Number__c +
                '</entity:Value></entity:ExtensionElement>';

        if (
            account.Age__pc < 21 &&
            account.Parent_Guardian_Occupation__pc != null &&
            account.Parent_Guardian_Occupation__pc != ''
        ) {
            requestStr +=
                '<entity:ExtensionElement><entity:Key>OCCUPATION_CODE</entity:Key><entity:Value>' +
                ExtractCode(account.Parent_Guardian_Occupation__pc) +
                '</entity:Value></entity:ExtensionElement>';
        } else if (account.Student_Occupation__pc != null && account.Student_Occupation__pc != '')
            requestStr +=
                '<entity:ExtensionElement><entity:Key>OCCUPATION_CODE</entity:Key><entity:Value>' +
                ExtractCode(account.Student_Occupation__pc) +
                '</entity:Value></entity:ExtensionElement>';

        if (account.Country_of_Permanent_Address__c != null)
            requestStr +=
                '<entity:ExtensionElement><entity:Key>DOMICILE_CODE</entity:Key><entity:Value>' +
                account.Country_of_Permanent_Address__r.country_code_2__c +
                '</entity:Value></entity:ExtensionElement>';

        requestStr += '</appln:ApplicationExtension>';

        requestStr += '</appln:ApplicationDetail>';
        requestStr += '</services:submitApplicationRequest></soapenv:Body></soapenv:Envelope>';

        Http h = new Http();
        HttpRequest req = BPPIntegrationConfig.getData(requestStr);
        req.setTimeout(120000);
        if (!Test.isRunningTest()) {
            applicationResult = h.send(req);
        }

        if (applicationResult.getStatus() == 'OK') {
            return successMsg;
        } else {
            String resultMsg = applicationResult.getBody();
            return 'ERROR:  ' + resultMsg;
        }
    }

    // Wrapper for records being updated and result message
    global class submitCalloutWrapper {
        webService Application__c newApp;
        webService Account acc;
        webService Opportunity opp;
        webService String newResult;
        webService List<Product2> prodList;
        public submitCalloutWrapper(
            Application__c newApp,
            Account acc,
            Opportunity opp,
            String newResult,
            List<Product2> prodList
        ) {
            this.newApp = newApp;
            this.acc = acc;
            this.opp = opp;
            this.newResult = newResult;
            this.prodList = prodList;
        }

        public submitCalloutWrapper(String validationErr) {
            newResult = validationErr;
        }
    }

    private static string ExtractCode(String displayString) {
        return string.valueOf(displayString).substring(0, string.valueOf(displayString).indexOf('~'));
    }
}
