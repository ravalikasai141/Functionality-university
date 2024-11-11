global with sharing class BNR_SubmitApplication {
    private static String successMsg = 'Application Submitted Successfully';
    private static String OFFERING_PRDTYPE = 'OFFERING';
    private static Set<Id> accountIdSet = new Set<Id>();
    public static Boolean bFailSubmit = false;
    public static Boolean bFailStudentId = false;
    private static String submitApplicationRequest(Opportunity opp, Application__c app, Account accnt, list<Sponsorship__c> spn, list<Account> spnaccnt, list<Opportunity_Product__c> lstOppPrd, map<String,String> mPIdnPrimary, map<Id,Product2> mPrds) {
        String reqStr = ''; 
        String requestStr = '';                                         
        requestStr = '<soapenv:Envelope ' +
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
        //----- From here add application date and down----------------------
        Product2 p;
        for(Opportunity_Product__c temp: lstOppPrd) {
            p = mPrds.get(temp.Product__c);
            if (p.Product_Type__c == OFFERING_PRDTYPE) {
                requestStr += '<appln:CurriculumDetail>';
                if (p.Programme__r.Programme_Id__c != null && p.Programme__r.Programme_Id__c != '')
                    requestStr +='<appln:ProgramCode>' + p.Programme__r.Programme_Id__c+ '</appln:ProgramCode>';
                
                boolean isPrimary = false;              
                if (mPIdnPrimary.get(temp.Id) == 'Primary')
                    isPrimary = true;
                requestStr += '<appln:IsPrimary>' + isPrimary + '</appln:IsPrimary>';
                if (p.BNR_Term_Code__c != null && p.BNR_Term_Code__c != '')
                    requestStr += '<appln:TermCode>' + p.BNR_Term_Code__c + '</appln:TermCode>';
                if (p.BNR_Level_Code__c != null && p.BNR_Level_Code__c != '')
                    requestStr += '<appln:LevelCode>' + p.BNR_Level_Code__c+ '</appln:LevelCode>';
                if (p.BNR_Campus_Code__c != null && p.BNR_Campus_Code__c != '')
                    requestStr += '<appln:CampusCode>' + p.BNR_Campus_Code__c+ '</appln:CampusCode>';
                if (p.Programme__r.BNR_College_Code__c != null && p.Programme__r.BNR_College_Code__c != '')
                    requestStr += '<appln:CollegeCode>' + p.Programme__r.BNR_College_Code__c+ '</appln:CollegeCode>'; //temp school
                if (p.BNR_Degree_Code__c != null && p.BNR_Degree_Code__c != '')
                    requestStr += '<appln:DegreeCode>' + p.BNR_Degree_Code__c+ '</appln:DegreeCode>';
                if (p.Programme__r.BNR_FieldOfStudy_Code__c !=null && p.Programme__r.BNR_FieldOfStudy_Code__c != '')
                    requestStr += '<appln:MajorCode>' + p.Programme__r.BNR_FieldOfStudy_Code__c + '</appln:MajorCode>';
                if (p.BNR_FieldOfStudy_Start_Date__c !=null) {
                    //Format Start Date
                    Integer StartYear = p.BNR_FieldOfStudy_Start_Date__c.year();
                    Integer StartMonth = p.BNR_FieldOfStudy_Start_Date__c.month();
                    String StartMonth_string = string.valueof(StartMonth);
                    if (StartMonth_string.length() == 1)
                        StartMonth_string = '0' + StartMonth_string;
                    
                    Integer StartDay = p.BNR_FieldOfStudy_Start_Date__c.day();
                    String StartDay_string = string.valueof(StartDay);        
                    if (StartDay_string.length() == 1)
                        StartDay_string = '0' + StartDay_string;
                    
                    String FieldOfStudy_Start_Date = StartYear +'-'+ StartMonth_string +'-'+ StartDay_string;     
                    requestStr += '<appln:FieldOfStudyStartDate >' + FieldOfStudy_Start_Date + '</appln:FieldOfStudyStartDate>';
                }
                String modeV = (p.Mode__c.contains('Full') ? 'F' : 'P');
                requestStr += '<appln:FullOrPartTimeInd>' + modeV + '</appln:FullOrPartTimeInd>';
                
                if (p.Start_Date__c != null && p.End_Date__c != null) {
                    //Format Start Date
                    Integer StartYear = p.Start_Date__c.year();
                    Integer StartMonth = p.Start_Date__c.month();
                    String StartMonth_string = string.valueof(StartMonth);
                    if (StartMonth_string.length() == 1)
                      StartMonth_string = '0' + StartMonth_string;
        
                    Integer StartDay = p.Start_Date__c.day();
                    String StartDay_string = string.valueof(StartDay);        
                    if (StartDay_string.length() == 1)
                      StartDay_string = '0' + StartDay_string;
                    
                    String StartDate = StartYear +'-'+ StartMonth_string +'-'+ StartDay_string;     
                    
                    //Format End Date
                    Integer EndYear = p.End_Date__c.year();
        
                    Integer EndMonth = p.End_Date__c.month();
                    String EndMonth_string = string.valueof(EndMonth);
                    if (EndMonth_string.length() == 1)
                      EndMonth_string = '0' + EndMonth_string;
        
                    Integer EndDay = p.End_Date__c.day();
                    String EndDay_string = string.valueof(EndDay);        
                    if (EndDay_string.length() == 1)
                      EndDay_string = '0' + EndDay_string;
                    
                    String EndDate = EndYear +'-'+ EndMonth_string +'-'+ EndDay_string;   
                    
                    requestStr += '<appln:curriculumPeriod>';
                        requestStr += '<bannercode:from>' + StartDate + '</bannercode:from>';
                        requestStr += '<bannercode:to>' + EndDate + '</bannercode:to>';
                    requestStr += '</appln:curriculumPeriod>';
                }
                                  
                requestStr += '</appln:CurriculumDetail>';              
            }           
        }
        boolean appItemsPresent = true;
        for(Opportunity_Product__c temp: lstOppPrd) {
            p = mPrds.get(temp.Product__c);
            if (appItemsPresent) {
                appItemsPresent = false;
                requestStr += '<appln:ApplicationItems>';
            }
            requestStr += '<appln:items><appln:id>' + p.Instance_Id__c+ '</appln:id>';
            requestStr += '<appln:type>' + p.Product_Type__c+ '</appln:type></appln:items>';            
        }
        if (!appItemsPresent) {
            requestStr += '</appln:ApplicationItems>';
        }
        //------------change till here-------------------
        
        if (app.BNR_Admissions_ADMT_Code__c != null) {
            requestStr += '<appln:AdmissionType>' + app.BNR_Admissions_ADMT_Code__c + '</appln:AdmissionType>';
        }
        if (app.BNR_Admissions_STYPE_Code__c != null) {
            requestStr += '<appln:StudentType>' + app.BNR_Admissions_STYPE_Code__c + '</appln:StudentType>';
        }
        if (app.BNR_Admissions_RESD_Code__c != null) {
            requestStr += '<appln:ResidencyCode>' + app.BNR_Admissions_RESD_Code__c + '</appln:ResidencyCode>';
        }
        requestStr += '<appln:ApplicationDecisionCode>' + opp.SFDC_Decision_Code__c + '</appln:ApplicationDecisionCode>';
        if (app.BNR_Application_Decision_Comment__c != null) {
            requestStr += '<appln:DecisionComment><entity:ApplicationDecisionComment>' + app.BNR_Application_Decision_Comment__c + '</entity:ApplicationDecisionComment></appln:DecisionComment>';
        }
             
        if (opp.PC_Attribute_Code__c != null) {                                                                                              
            requestStr += '<appln:ApplicationAttibutes>';                                    
            if (opp.International_Student__c == True)                                                 
                requestStr += '<appln:value>IN</appln:value>';  

            if (opp.PC_Attribute_Code__c != null)                                                      
                requestStr += '<appln:value>'+ opp.PC_Attribute_Code__c +'</appln:value>';                                    
        
            if (opp.PC_Attribute_Code_2__c != null)                                                      
                requestStr += '<appln:value>'+ opp.PC_Attribute_Code_2__c +'</appln:value>';
            
            if (opp.PC_Attribute_Code_3__c != null)                                                      
                requestStr += '<appln:value>'+ opp.PC_Attribute_Code_3__c +'</appln:value>';                                    
            
            if (opp.SFDC_Attribute_Code_Select_v2__c != null) {  
                String[] listOfCodes = opp.SFDC_Attribute_Code_Select_v2__c.split(';');
                for(String atr_cd: listOfCodes) {
                    atr_cd = ExtractCode(atr_cd);
                    requestStr += '<appln:value>'+ atr_cd +'</appln:value>';
                } 
            }                                                                                    
            requestStr += '</appln:ApplicationAttibutes>';
        }                              
                                                                                                                                                                                
        if (app.BNR_Cohort_Code__c != null) {
            requestStr += '<appln:CohortCode>' + app.BNR_Cohort_Code__c + '</appln:CohortCode>';
        }
        if (accnt.SFDC_Country_of_Birth__pc != null || accnt.Primary_Nationality__pc != null) {
            requestStr += '<internationalDetail:InternationalDetail>';
            if (accnt.SFDC_Country_of_Birth__pr.ISO_CODE__c != null) {
                requestStr += '<internationalDetail:BirthCountry>' + accnt.SFDC_Country_of_Birth__pr.ISO_CODE__c + '</internationalDetail:BirthCountry>';
            }
            if (accnt.Primary_Nationality__pr.ISO_CODE__c != null) {
                requestStr += '<internationalDetail:CitizenshipCountryCode>' + accnt.Primary_Nationality__pr.ISO_CODE__c + '</internationalDetail:CitizenshipCountryCode>';
            }   
            requestStr += '</internationalDetail:InternationalDetail>';
        }
        requestStr += '<appln:ApplicationExtension>';
        requestStr += (spn.size() > 0 ? '<entity:ExtensionElement><entity:Key>INTAKE_TYPE</entity:Key><entity:Value>SPONSORED</entity:Value></entity:ExtensionElement>' : '<entity:ExtensionElement><entity:Key>INTAKE_TYPE</entity:Key><entity:Value>SELFPAY</entity:Value></entity:ExtensionElement>');
        
        String tempentity = '';
        if (accnt.Legal_Entity__c != null) {
            Legal_Entity__c cs = Legal_Entity__c.getValues(accnt.Legal_Entity__c);
            String entity = cs.Entity__c;
            Boolean ARIntegration = cs.AR_Integration__c;
            requestStr += '<entity:ExtensionElement><entity:Key>LEGAL_ENTITY_ID</entity:Key><entity:Value>' + entity + '</entity:Value></entity:ExtensionElement>';
        }                                               
        if (spnaccnt.size()>0) {
            for (Account acc: spnaccnt) {
                reqStr += '<entity:ExtensionElement><entity:Key>SPONSOR_SIS_ID</entity:Key><entity:Value>' + acc.SIS_Company_ID__c +'</entity:Value></entity:ExtensionElement>';
            }
            requestStr += reqStr;
        }
        requestStr += (accnt.AR_Discount_Eligible__c ? '<entity:ExtensionElement><entity:Key>DISCOUNT_ELIGIBLE</entity:Key><entity:Value>Y</entity:Value></entity:ExtensionElement>' : '<entity:ExtensionElement><entity:Key>DISCOUNT_ELIGIBLE</entity:Key><entity:Value>N</entity:Value></entity:ExtensionElement>');

        if (opp.Sponsorship_Level__c != null) {
            requestStr += '<entity:ExtensionElement><entity:Key>SPONSORSHIP_LEVEL</entity:Key><entity:Value>' + opp.Sponsorship_Level__c + '</entity:Value></entity:ExtensionElement>';
        }
        if (opp.Customer_Group__c != null) {
            requestStr += '<entity:ExtensionElement><entity:Key>CUSTOMER_GROUP</entity:Key><entity:Value>' + opp.Customer_Group__c + '</entity:Value></entity:ExtensionElement>';
        }
        if (opp.Sponsorship_Amount__c != null) {
            requestStr += '<entity:ExtensionElement><entity:Key>SPONSORSHIP_AMOUNT</entity:Key><entity:Value>' + opp.Sponsorship_Amount__c + '</entity:Value></entity:ExtensionElement>';
        }
        if (opp.Sponsorship_Percentage__c != null) {
            requestStr += '<entity:ExtensionElement><entity:Key>SPONSORED_PERCENTAGE</entity:Key><entity:Value>' + opp.Sponsorship_Percentage__c + '</entity:Value></entity:ExtensionElement>';
        }
        if (opp.Ap_ID__C != null)
            requestStr += '<entity:ExtensionElement><entity:Key>CRM_APPL_ID</entity:Key><entity:Value>' + opp.AP_ID__c + '</entity:Value></entity:ExtensionElement>';
            
        if (opp.Purchase_Order_Number__c != null)
            requestStr += '<entity:ExtensionElement><entity:Key>PURCH_ORDER_FORM_NUM</entity:Key><entity:Value>' + opp.Purchase_Order_Number__c + '</entity:Value></entity:ExtensionElement>';
        
        if (accnt.Age__pc < 21 && accnt.Parent_Guardian_Occupation__pc != null && accnt.Parent_Guardian_Occupation__pc != '') {
            requestStr += '<entity:ExtensionElement><entity:Key>OCCUPATION_CODE</entity:Key><entity:Value>' + ExtractCode(accnt.Parent_Guardian_Occupation__pc) + '</entity:Value></entity:ExtensionElement>';
        }
        else if (accnt.Student_Occupation__pc != null && accnt.Student_Occupation__pc != '')
        requestStr += '<entity:ExtensionElement><entity:Key>OCCUPATION_CODE</entity:Key><entity:Value>' + ExtractCode(accnt.Student_Occupation__pc) + '</entity:Value></entity:ExtensionElement>';
        
        if (accnt.Country_of_Permanent_Address__c != null)
            requestStr += '<entity:ExtensionElement><entity:Key>DOMICILE_CODE</entity:Key><entity:Value>' + accnt.Country_of_Permanent_Address__r.country_code_2__c + '</entity:Value></entity:ExtensionElement>';
                                                                                                             
        requestStr += '</appln:ApplicationExtension>';
        
        requestStr += '</appln:ApplicationDetail>';
        requestStr += '</services:submitApplicationRequest></soapenv:Body></soapenv:Envelope>';
         
        Http h = new Http();
        HttpRequest req = BPPIntegrationConfig.getData(requestStr);
        req.setTimeout(120000);
        System.debug('XML:' + requestStr);   
        System.debug(req.toString());
        HttpResponse result = null;
        if (Test.isRunningTest()) {
            result = new HttpResponse();
            if (bFailSubmit) {
                result.setStatus('Internal Error');
                result.setStatusCode(500);
                String strErrorSoap = '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/">' + 
                                    '<soapenv:Header><gateway:' + 
                                    'transactionId xmlns:gateway="http://platform.apollogrp.edu/gateway">' + 
                                    'A4A3BF60-2BB1-2EFA-E334-8B03BE650CD0</gateway:transactionId>' + 
                                    '</soapenv:Header>' + 
                                    '<soapenv:Body>' +
                                    '<soapenv:Fault>' + 
                                    '<faultcode>SOAP-ENV:Server</faultcode>' + 
                                    '<faultstring>Error occurred invoking underlying service implementation' + 
                                    '</faultstring>' + 
                                    '<detail xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/">' + 
                                    '<ns2:serviceFault ' + 
                                    'xmlns:ns2="http://platform.apollogrp.edu/schemas/2010/05/28/ServiceFault">' + 
                                    '<ns2:componentCode>15</ns2:componentCode><ns2:transactionId>' + 
                                    'A4A3BF60-2BB1- 2EFA-E334-8B03BE650CD0</ns2:transactionId><ns2:errorCode> ' + 
                                    'PLATFORM-999</ns2:errorCode><ns2:errorDescription> ' + 
                                    'ORA-06512: at line 1' + 
                                    '</ns2:errorDescription></ns2:serviceFault></detail></soapenv:Fault>' + 
                                    '</soapenv:Body>' + 
                                    '</soapenv:Envelope>';
                result.setBody(strErrorSoap);
            } else {
                result.setStatus('OK');
                result.setStatusCode(200);
                result.setBody('<?xml version="1.0" encoding="utf-8"?>\n<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:crm="http://platform.apollogrp.edu/services/apolloglobal/crm/application/v1"><soapenv:Header><gateway:transactionId xmlns:gateway="http://platform.apollogrp.edu/gateway">531F32D7-BE13-574B-A65A-871D23C91AEA</gateway:transactionId></soapenv:Header><soapenv:Body><crm:submitApplicationResponse><crm:success>true</crm:success></crm:submitApplicationResponse></soapenv:Body></soapenv:Envelope>');
            }
        } else {
            result = h.send(req);
        }
        system.debug(result.getStatus());
        system.debug(result.getBody());
        
        if (result.getStatus() == 'OK') {
            return successMsg;
        } else {
            String resultMsg = result.getBody();
            return 'ERROR:  ' + resultMsg;
        }
    }
    
    WebService static String Submit(String oppId) {
        Opportunity opp = [Select Id, SFDC_Application_Number__c, AccountId, SFDC_Term_Code_Entry_Select__c, SFDC_Curriculum_Campus_Code_Select__c,
                           SFDC_Curriculum_Program_Code_Select__c, SFDC_FieldOfStudy_Code_Select__c, BNR_Application_Decision_Comment__c,
                           SFDC_Attribute_Code_Select__c, SFDC_Admissions_ADMT_Code_Select__c, SFDC_Admissions_STYPE_Code_Select__c, 
                           SFDC_Admissions_RESD_Code_Select__c, SFDC_Curriculum_Level_Code_Select__c, SFDC_Curriculum_Degree_Code_Select__c, SFDC_Cohort_Code_Select__c,
                           BNR_Campus_Code_Text__c, BNR_Degree_Code_Text__c, BNR_FieldOfStudy_Code__c, BNR_Level_Code_Text__c, BNR_Program_Code_Text__c, BNR_Term_Code_Text__c,
                           SFDC_Decision_Code__c, Sponsorship_Level__c, Sponsorship_Amount__c, Sponsorship_Percentage__c, AP_ID__c, Purchase_Order_Number__c, 
                           SFDC_Attribute_Code_Select_v2__c, PC_Attribute_Code__c, PC_Attribute_Code_2__c, PC_Attribute_Code_3__c, Customer_Group__c, International_Student__c,CAS_status__c
                           From Opportunity Where Id = : oppId];
        Account acc = [Select Id, OwnerId, PS_Profile_Services_ID__pc, BNR_Banner_ID__pc, SFDC_Disability_Status_Code_Select__pc,
                       /*SFDC_Disability_Type_Code_Select__pc,*/ Legal_Entity__c, Student_Type__pc, AR_Customer_Number__c, AR_Global_Customer_Number__c , AR_Discount_Eligible__c, 
                       SFDC_Country_of_Birth__pc, SFDC_Country_of_Birth__pr.ISO_CODE__c, Primary_Nationality__pc, Primary_Nationality__pr.ISO_CODE__c,
                       Parent_Guardian_Occupation__pc, Student_Occupation__pc, Age__pc, Country_of_Permanent_Address__c, Country_of_Permanent_Address__r.country_code_2__c, Sexual_Orientation__pc, Gender_Identity__pc, Religion__pc
                       From Account Where Id = : opp.AccountId];
                                     
        List<Opportunity_Product__c> lstOppPrd = [Select o.Product__c, o.Opportunity__c, o.Id, o.Course_Focus__c From Opportunity_Product__c o where o.Opportunity__c =:oppId];
        if (lstOppPrd.isEmpty()) {
            return 'Product Catalog Items are required for Submitting an Application';
        }
        Map<String,String> mPIdnPrimary = new Map<String,String>();
        Set<String> prdIds = new Set<String>();
        for(Opportunity_Product__c temp: lstOppPrd) {
            mPIdnPrimary.put(temp.Id,temp.Course_Focus__c);
            prdIds.add(temp.product__c);
        }
        Map<Id,Product2> mPrds = new Map<Id,Product2>([Select p.Name, p.Programme__r.BNR_College_Code__c, p.Programme__r.BNR_FieldOfStudy_Code__c, p.BNR_FieldOfStudy_Start_Date__c, p.Programme__r.Programme_Id__c,
                                        p.Programme__c, p.Product_Type__c, p.Mode__c, p.Id, p.BNR_Program_Code__c, p.BNR_Level_Code__c, 
                                        p.BNR_Degree_Code__c, p.BNR_Campus_Code__c, p.BNR_Term_Code__c, p.BNR_Attribute_Code__c,p.Instance_Id__c,
                                        p.BNR_Max_Capacity__c, p.BNR_Min_Capacity__c, p.BNR_Used_Capacity__c, p.Start_Date__c, p.End_Date__c From Product2 p where p.Id in:prdIds]);
        
        //check if products have all the required values filled in
        String errorWithPrds = '';
        Boolean zeroOfferings = true;
        String missingValues = '';
        Boolean only1Primary = false;
        Boolean dontAllow2Primary = false;
        Product2 p;
        for(Opportunity_Product__c temp: lstOppPrd) {
            missingValues = '';
            p = mPrds.get(temp.Product__c);
            if (p.Product_Type__c == OFFERING_PRDTYPE) {
                zeroOfferings = false;
                if (p.Instance_Id__c == null || p.Instance_Id__c == '') {
                    missingValues += 'Instance Id';
                }
                if (mPIdnPrimary.get(temp.Id) == 'Primary') {
                    if (only1Primary)
                        dontAllow2Primary = true;
                    only1Primary = true;
                }
                if (p.Programme__r.Programme_Id__c == null || p.Programme__r.Programme_Id__c == '') {
                    if (missingValues != '') 
                        missingvalues = missingValues + ',';
                    missingValues += 'Program Code';
                }
                if (p.BNR_Term_Code__c == null || p.BNR_Term_Code__c == '') {
                    if (missingValues != '') 
                        missingvalues = missingValues + ',';
                    missingValues += 'Term Code';
                }
                if (p.BNR_Campus_Code__c == null || p.BNR_Campus_Code__c == '') {
                    if (missingValues != '') 
                        missingvalues = missingValues + ',';
                    missingValues += 'Campus Code';
                }
                if (p.Programme__r.BNR_FieldOfStudy_Code__c == null || p.Programme__r.BNR_FieldOfStudy_Code__c == '') {
                    if (missingValues != '') 
                        missingvalues = missingValues + ',';
                    missingValues += 'Field Of Study Code on Programme';
                }
                if (p.BNR_Max_Capacity__c <= p.BNR_Used_Capacity__c) {
                    if (missingValues != '') 
                        missingvalues = missingValues + ',';
                    missingValues += 'Product selected reached maximum capacity';
                }
                if (missingValues != '') {
                    if (errorWithPrds != '') {
                        errorWithPrds += '\n';
                    }
                    errorWithPrds += missingValues + ': Missing for Product with Name: ' + p.Name;
                }
                system.debug(p + 'product' + p.BNR_Used_Capacity__c);
                if (p.BNR_Used_Capacity__c != null)
                    p.BNR_Used_Capacity__c = p.BNR_Used_Capacity__c + 1;
                else
                    p.BNR_Used_Capacity__c = 1;
            }
        }
        
        if (zeroOfferings) { 
            errorWithPrds =  'At least one Product of type Offering is required' + (errorWithPrds ==''?errorWithPrds:'\n'+errorWithPrds);
        }
        if (!only1Primary) {
            errorWithPRds = 'At least one Primary Offering is required' + (errorWithPrds ==''?errorWithPrds:'\n'+errorWithPrds);
        }
        if (dontAllow2Primary) {
            errorWithPRds = 'Only one Primary Offering is allowed' + (errorWithPrds ==''?errorWithPrds:'\n'+errorWithPrds);
        }
        if (errorWithPrds != '') {
            return errorWithPrds;
        }
        List<Sponsorship__c> spnship = [SELECT Id, Name, Student__c, Opportunity__c, Company__c FROM Sponsorship__c WHERE (Student__c =: acc.Id AND Opportunity__c =: opp.Id AND Active__c = true)]; 
        Set<Id> allCompanyIds = new Set<Id>();
        for (Sponsorship__c spn: spnship) {
            allCompanyIds.add(spn.Company__c);
        }
        List<Account> spnacc = [SELECT Id, Name, SIS_Company_ID__c FROM Account WHERE (Id in: allCompanyIds)];              
        String result;
        String resultXml;
        ARStudentAccountService.ARCustomerFields arResult = null;
        
        if ((acc.AR_Customer_Number__c == null || acc.AR_Customer_Number__c == '') && (acc.AR_Global_Customer_Number__c == null || acc.AR_Global_Customer_Number__c == '') && (acc.Legal_Entity__c == 'UC~COL' || acc.Legal_Entity__c == 'UC~WEB')) { 
            arResult = ARStudentAccountService.CreateARStudentAccount(acc, opp);
            system.debug('ARResult' +arResult);
            if (arResult.Status == 'Success') {
                acc.AR_Customer_Number__c = arResult.ARCustomerNumber;
                system.debug('Account AR Customer Number' +acc.AR_Customer_Number__c);
                acc.AR_Global_Customer_Number__c = arResult.ARGlobalCustomerNumber;
            } else {
                acc.Last_Error__c = arResult.Status;
                result = arResult.Status;
                resultXml = result.removeStart('ERROR:  ');
                
                XmlStreamReader reader = new XmlStreamReader(resultXml);
                while(reader.hasNext()) {
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
            }
        }
        if ( ((acc.AR_Customer_Number__c != Null && acc.AR_Customer_Number__c != '') && (acc.AR_Global_Customer_Number__c!= Null && acc.AR_Global_Customer_Number__c!='')) || (acc.Legal_Entity__c != 'UC~COL' && acc.Legal_Entity__c != 'UC~WEB')) {
            result = GetStudentIdByProfileId(acc.PS_Profile_Services_ID__pc);
            if (result.indexOf('<per:studentID>') != -1) {
                result = result.substring(result.indexOf('<per:studentID>') + 15);
                result = result.substring(0, result.indexOf('<'));
                acc.BNR_Banner_ID__pc = result;
            } else {
                acc.Last_Error__c = result;
                resultXml = result;
                XmlStreamReader reader = new XmlStreamReader(resultXml);
                while(reader.hasNext()) {
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
                /*if (acc.SFDC_Disability_Type_Code_Select__pc != null) {
                    newApp.BNR_Disability_Type_Code__c = ExtractCode(acc.SFDC_Disability_Type_Code_Select__pc);
                }*/
                
                result = submitApplicationRequest(opp, newApp, acc, spnship, spnacc, lstOppPrd, mPIdnPrimary, mPrds);
                if (result.equals(successMsg)) {
                    list<RecordType> rtList = [Select Id, SobjectType, Name FROM RecordType WHERE Name LIKE 'Locked%'];
                    for (RecordType rt : rtList) {
                        if (rt.SobjectType == 'Application__c')
                            newApp.RecordTypeId = rt.Id;
                        if (rt.SobjectType == 'Account')
                            acc.RecordTypeId = rt.Id;
                        if (rt.SobjectType == 'Opportunity')
                            opp.RecordTypeId = rt.Id;
                    }
                    insert newApp;
                    opp.SFDC_Application_Number__c = newApp.Id;   
                    update opp; 
                    
                    Database.update(mPrds.values(),false);
                } else {
                    opp.Last_Error__c = result;
                    resultXml = result.removeStart('ERROR:  ');
                    XmlStreamReader reader = new XmlStreamReader(resultXml);
                    while(reader.hasNext()) {
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
                    update opp;
                }
            }
        }
        update acc;  
        return result;
    }
    
    global class submitCalloutWrapper {
        WebService Application__c newApp;
        WebService Account acc;
        WebService Opportunity opp;
        WebService String newResult;
        WebService List<Product2> prodList;
        public submitCalloutWrapper(Application__c newApp, Account acc, Opportunity opp, String newResult, List<Product2> prodList) {
            this.newApp=newApp;
            this.acc=acc;
            this.opp=opp;
            this.newResult = newResult;
            this.prodList = prodList;   
        }   
    }
    
    ////////////////////////////////new method written by Prema///////////////////////////
    WebService static submitCalloutWrapper Submitnew(String oppId) {
        String Errormsg = '';
        submitCalloutWrapper submitWrapper;
        Application__c newApp1 = new Application__c();
        
        Opportunity opp = [Select Id, SFDC_Application_Number__c, AccountId, SFDC_Term_Code_Entry_Select__c, SFDC_Curriculum_Campus_Code_Select__c,
                           SFDC_Curriculum_Program_Code_Select__c, SFDC_FieldOfStudy_Code_Select__c, BNR_Application_Decision_Comment__c,
                           SFDC_Attribute_Code_Select__c, SFDC_Admissions_ADMT_Code_Select__c, SFDC_Admissions_STYPE_Code_Select__c, 
                           SFDC_Admissions_RESD_Code_Select__c, SFDC_Curriculum_Level_Code_Select__c, SFDC_Curriculum_Degree_Code_Select__c, SFDC_Cohort_Code_Select__c,
                           BNR_Campus_Code_Text__c, BNR_Degree_Code_Text__c, BNR_FieldOfStudy_Code__c, BNR_Level_Code_Text__c, BNR_Program_Code_Text__c, BNR_Term_Code_Text__c,
                           SFDC_Decision_Code__c, Sponsorship_Level__c, Sponsorship_Amount__c, Sponsorship_Percentage__c, AP_ID__c, Purchase_Order_Number__c, 
                           SFDC_Attribute_Code_Select_v2__c, PC_Attribute_Code__c, PC_Attribute_Code_2__c, PC_Attribute_Code_3__c, Customer_Group__c, International_Student__c,CAS_status__c
                           From Opportunity Where Id = : oppId];
        Account acc = [Select Id, OwnerId, PS_Profile_Services_ID__pc, BNR_Banner_ID__pc, SFDC_Disability_Status_Code_Select__pc,
                       /*SFDC_Disability_Type_Code_Select__pc,*/ Legal_Entity__c, Student_Type__pc, AR_Customer_Number__c, AR_Global_Customer_Number__c , AR_Discount_Eligible__c, 
                       SFDC_Country_of_Birth__pc, SFDC_Country_of_Birth__pr.ISO_CODE__c, Primary_Nationality__pc, Primary_Nationality__pr.ISO_CODE__c,
                       Parent_Guardian_Occupation__pc, Student_Occupation__pc, Age__pc, Country_of_Permanent_Address__c, Country_of_Permanent_Address__r.country_code_2__c, Sexual_Orientation__pc, Gender_Identity__pc, Religion__pc
                       From Account Where Id = : opp.AccountId];
                                     
        List<Opportunity_Product__c> lstOppPrd = [Select o.Product__c, o.Opportunity__c, o.Id, o.Course_Focus__c From Opportunity_Product__c o where o.Opportunity__c =:oppId];
        if (lstOppPrd.isEmpty()) {
            Errormsg = 'Product Catalog Items are required for Submitting an Application';
            submitWrapper = new submitCalloutWrapper(null, null, null, Errormsg, null);
            return submitWrapper;
        }
        Map<String,String> mPIdnPrimary = new Map<String,String>();
        Set<String> prdIds = new Set<String>();
        for(Opportunity_Product__c temp: lstOppPrd) {
            mPIdnPrimary.put(temp.Id,temp.Course_Focus__c);
            prdIds.add(temp.product__c);
        }
        
        Map<Id,Product2> mPrds = new Map<Id,Product2>([Select p.Name, p.Programme__r.BNR_College_Code__c, p.Programme__r.BNR_FieldOfStudy_Code__c, p.BNR_FieldOfStudy_Start_Date__c, p.Programme__r.Programme_Id__c,
                                        p.Programme__c, p.Product_Type__c, p.Mode__c, p.Id, p.BNR_Program_Code__c, p.BNR_Level_Code__c, 
                                        p.BNR_Degree_Code__c, p.BNR_Campus_Code__c, p.BNR_Term_Code__c, p.BNR_Attribute_Code__c,p.Instance_Id__c,
                                        p.BNR_Max_Capacity__c, p.BNR_Min_Capacity__c, p.BNR_Used_Capacity__c, p.Start_Date__c, p.End_Date__c From Product2 p where p.Id in:prdIds]);
        
        //check if products have all the required values filled in
        String errorWithPrds = '';
        Boolean zeroOfferings = true;
        String missingValues = '';
        Boolean only1Primary = false;
        Boolean dontAllow2Primary = false;
        Product2 p;
        for (Opportunity_Product__c temp: lstOppPrd) {
            missingValues = '';
            p = mPrds.get(temp.Product__c);
            if (p.Product_Type__c == OFFERING_PRDTYPE) {
                zeroOfferings = false;
                if (p.Instance_Id__c == null || p.Instance_Id__c == '') {
                    missingValues += 'Instance Id';
                }
                if (mPIdnPrimary.get(temp.Id) == 'Primary') {
                    if (only1Primary)
                        dontAllow2Primary = true;
                    only1Primary = true;
                }
                if (p.Programme__r.Programme_Id__c == null || p.Programme__r.Programme_Id__c == '') {
                    if (missingValues != '') 
                        missingvalues = missingValues + ',';
                    missingValues += 'Program Code';
                }
                if (p.BNR_Term_Code__c == null || p.BNR_Term_Code__c == '') {
                    if (missingValues != '') 
                        missingvalues = missingValues + ',';
                    missingValues += 'Term Code';
                }
                if (p.BNR_Campus_Code__c == null || p.BNR_Campus_Code__c == '') {
                    if (missingValues != '') 
                        missingvalues = missingValues + ',';
                    missingValues += 'Campus Code';
                }
                if (p.Programme__r.BNR_FieldOfStudy_Code__c == null || p.Programme__r.BNR_FieldOfStudy_Code__c == '') {
                    if (missingValues != '') 
                        missingvalues = missingValues + ',';
                    missingValues += 'Field Of Study Code on Programme';
                }
                if (p.BNR_Max_Capacity__c <= p.BNR_Used_Capacity__c) {
                    if (missingValues != '') 
                        missingvalues = missingValues + ',';
                    missingValues += 'Product selected reached maximum capacity';
                }
                if (missingValues != '') {
                    if (errorWithPrds != '') {
                        errorWithPrds += '\n';
                    }
                    errorWithPrds += missingValues + ': Missing for Product with Name: ' + p.Name;
                }
                system.debug(p + 'product' + p.BNR_Used_Capacity__c);
                if (p.BNR_Used_Capacity__c != null)
                    p.BNR_Used_Capacity__c = p.BNR_Used_Capacity__c + 1;
                else
                    p.BNR_Used_Capacity__c = 1;
            }
        }
        
        if (zeroOfferings) { 
            errorWithPrds =  'At least one Product of type Offering is required' + (errorWithPrds ==''?errorWithPrds:'\n'+errorWithPrds);
        }
        if (!only1Primary) {
            errorWithPRds = 'At least one Primary Offering is required' + (errorWithPrds ==''?errorWithPrds:'\n'+errorWithPrds);
        }
        if (dontAllow2Primary) {
            errorWithPRds = 'Only one Primary Offering is allowed' + (errorWithPrds ==''?errorWithPrds:'\n'+errorWithPrds);
        }
        if (errorWithPrds != '') {
            submitWrapper = new submitCalloutWrapper(null, null, null, errorWithPrds, null);
            return submitWrapper;
        }
       
        List<Sponsorship__c> spnship = [SELECT Id, Name, Student__c, Opportunity__c, Company__c FROM Sponsorship__c WHERE (Student__c =: acc.Id AND Opportunity__c =: opp.Id AND Active__c = true)]; 
        Set<Id> allCompanyIds = new Set<Id>();
        for (Sponsorship__c spn: spnship) {
            allCompanyIds.add(spn.Company__c);
        }
        List<Account> spnacc = [SELECT Id, Name, SIS_Company_ID__c FROM Account WHERE (Id in: allCompanyIds)];              
        String result;
        String resultXml;
        ARStudentAccountService.ARCustomerFields arResult = null;

        System.debug(acc.AR_Customer_Number__c);
        System.debug(acc.AR_Global_Customer_Number__c);
        System.debug(acc.Legal_Entity__c);
        if ((acc.AR_Customer_Number__c == null || acc.AR_Customer_Number__c == '') && (acc.AR_Global_Customer_Number__c == null || acc.AR_Global_Customer_Number__c == '') && (acc.Legal_Entity__c == 'UC~COL' || acc.Legal_Entity__c == 'UC~WEB')) { 
            arResult = ARStudentAccountService.CreateARStudentAccount(acc, opp);
            System.debug('@BNR_SubmitApplication ARResult: ' + arResult);
            if (arResult.Status == 'Success') {
                acc.AR_Customer_Number__c = arResult.ARCustomerNumber;
                System.debug('BNR_SubmitApplication Account AR Customer Number: ' + acc.AR_Customer_Number__c);
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
            }
        }
  
        if ( ((acc.AR_Customer_Number__c != Null && acc.AR_Customer_Number__c != '') && (acc.AR_Global_Customer_Number__c!= Null && acc.AR_Global_Customer_Number__c!='')) || (acc.Legal_Entity__c != 'UC~COL' && acc.Legal_Entity__c != 'UC~WEB')) {
            result = GetStudentIdByProfileId(acc.PS_Profile_Services_ID__pc);
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
                /*if (acc.SFDC_Disability_Type_Code_Select__pc != null) {
                    newApp.BNR_Disability_Type_Code__c = ExtractCode(acc.SFDC_Disability_Type_Code_Select__pc);
                }*/
                
                result = submitApplicationRequest(opp, newApp, acc, spnship, spnacc, lstOppPrd, mPIdnPrimary, mPrds);
                
                if (result.equals(successMsg)) {
                    list<RecordType> rtList = [Select Id, SobjectType, Name FROM RecordType WHERE Name LIKE 'Locked%'];
                    for (RecordType rt : rtList) {
                        if (rt.SobjectType == 'Application__c')
                            newApp.RecordTypeId = rt.Id;
                        if (rt.SobjectType == 'Account')
                            acc.RecordTypeId = rt.Id;
                        if (rt.SobjectType == 'Opportunity')
                            opp.RecordTypeId = rt.Id;
                    }
                    newApp1 = newApp;
                    opp.SFDC_Application_Number__c = newApp.Id;
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
        submitWrapper = new submitCalloutWrapper(newApp1, acc, opp, result, mPrds.values()); 
        return submitWrapper;
    }
    
    //////////////////////////////////////////////////////////////////////////////////////
    
    public static string ExtractCode(String displayString) {
        return string.valueOf(displayString).substring(0, string.valueOf(displayString).indexOf('~'));
    }
    
    public static string ExtractBackCode(String dspString) {
        return string.valueOf(dspString).substring(string.valueOf(dspString).indexOf('~') + 1);
    }
    
    public static string GetStudentIdByProfileId(String ProfileId) {
        String requestStr = '<soapenv:Envelope ' + 
            'xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" ' +
            'xmlns:tns="http://platform.apollogrp.edu/services/apolloglobal/person/PersonService">' +
            '  <soapenv:Header/>' +
            '  <soapenv:Body>' +
            '    <tns:getStudentIDByProfileIDRequest>' +
            '      <tns:profileID>' + ProfileId  + '</tns:profileID>' +
            '    </tns:getStudentIDByProfileIDRequest>' + 
            '</soapenv:Body></soapenv:Envelope>';
            
        Http h = new Http();
        HttpRequest req = BPPIntegrationConfig.getData(requestStr);
        req.setTimeout(120000);
        system.debug('XML:' + requestStr);   
        system.debug(req.toString());
        HttpResponse res = null;
        if (Test.isRunningTest()) {
            res = new HttpResponse();
            if (bFailStudentId) {
                res.setStatus('Internal Error');
                res.setStatusCode(500);
                String strErrorSoap = '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/">' + 
                                    '<soapenv:Header><gateway:' + 
                                    'transactionId xmlns:gateway="http://platform.apollogrp.edu/gateway">' + 
                                    'A4A3BF60-2BB1-2EFA-E334-8B03BE650CD0</gateway:transactionId>' + 
                                    '</soapenv:Header>' + 
                                    '<soapenv:Body>' +
                                    '<soapenv:Fault>' + 
                                    '<faultcode>SOAP-ENV:Server</faultcode>' + 
                                    '<faultstring>Error occurred invoking underlying service implementation' + 
                                    '</faultstring>' + 
                                    '<detail xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/">' + 
                                    '<ns2:serviceFault ' + 
                                    'xmlns:ns2="http://platform.apollogrp.edu/schemas/2010/05/28/ServiceFault">' + 
                                    '<ns2:componentCode>15</ns2:componentCode><ns2:transactionId>' + 
                                    'A4A3BF60-2BB1- 2EFA-E334-8B03BE650CD0</ns2:transactionId><ns2:errorCode> ' + 
                                    'PLATFORM-999</ns2:errorCode><ns2:errorDescription> ' + 
                                    'ORA-06512: at line 1' + 
                                    '</ns2:errorDescription></ns2:serviceFault></detail></soapenv:Fault>' + 
                                    '</soapenv:Body>' + 
                                    '</soapenv:Envelope>';
                res.setBody(strErrorSoap);
            } else {
                res.setStatus('OK');
                res.setStatusCode(200);
                res.setBody('<?xml version="1.0" encoding="utf-8"?>\n<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:platform="http://platform.apollogrp.edu/gateway" xmlns:wsse="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd" xmlns:per="http://platform.apollogrp.edu/services/apolloglobal/person/PersonService"><soapenv:Header><gateway:transactionId xmlns:gateway="http://platform.apollogrp.edu/gateway">4C7D57D0-35AE-3034-1A99-30F1672ED186</gateway:transactionId></soapenv:Header><soapenv:Body><per:getStudentIDByProfileIDResponse><per:studentID>BP0015527</per:studentID></per:getStudentIDByProfileIDResponse></soapenv:Body></soapenv:Envelope>');
            }
        } else {
            res = h.send(req);
        }
        System.debug(res.getStatus());
        System.debug(res.getBody());     
        
        String result = res.getBody();  
        return result;
    }
}