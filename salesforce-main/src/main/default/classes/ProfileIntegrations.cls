global with sharing class ProfileIntegrations {

    private static final String soapEnv = 'xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" ';
    private static final String tns = 'xmlns:tns="http://platform.apollogrp.edu/services/apolloglobal/person/PersonService" ';
    private static final String prof = 'xmlns:prof="http://platform.apollogrp.edu/schemas/profile/2010/07/02/Profile" ';
    private static final String prof1 = 'xmlns:prof1="http://platform.apollogrp.edu/schemas/profile/2010/07/02/ProfileInformation" ';
    private static final String ext = 'xmlns:ext="http://platform.apollogrp.edu/model/extension" ';
    private static final String add = 'xmlns:add="http://platform.apollogrp.edu/schemas/profile/2010/07/02/Address" ';
    private static final String nam = 'xmlns:nam="http://platform.apollogrp.edu/schemas/profile/2010/07/02/Name" ';
    private static final String email = 'xmlns:email="http://platform.apollogrp.edu/schemas/profile/2010/07/02/EmailAddress" ';
    private static final String nat = 'xmlns:nat="http://platform.apollogrp.edu/schemas/profile/2010/07/02/Nationality" ';
    private static final String cit = 'xmlns:cit="http://platform.apollogrp.edu/schemas/profile/2010/07/02/Citizenship" ';
    private static final String phon = 'xmlns:phon="http://platform.apollogrp.edu/schemas/profile/2010/07/02/Phone"> ';

    WebService static String ProfileInt (String AccountId) {
        String query = Util.getAllFieldsSOQL('Account', 'Id = \'' + AccountId + '\'');
        Account acc = Database.query(query);
        
        Account acct  =[Select Id, Primary_Nationality__pc, Primary_Nationality__pr.ISO_CODE__c 
                        From Account Where Id =: acc.Id Limit 1];
        if(acc.Primary_Nationality__pc != null){
            acc.Primary_Nationality__pc = acct.Primary_Nationality__pc;
            acc.Primary_Nationality__pr = acct.Primary_Nationality__pr;
            acc.Primary_Nationality__pr.ISO_Code__c = acct.Primary_Nationality__pr.ISO_Code__c;
        }
        
        String result = ProfileIntegrations.CreatePersonInfo(acc);
        if (result.contains('Potential Duplicate Record:'))
        {
            return result;
        }
        else if(result.contains('error code [20002]')){
            return 'Error: Minimum information for profile creation not available.  Minimum 3 fields are required out of: Name [First or Last],Date Of Birth,Postal code [Home,Mailing and Work], Email [Home,Personal and Work], Phone';
        }
        else if(result ==''){
            return 'Application Submitted Successfully';
        }
        else{
            return result;
        }
    }
    
    public static String CreatePersonInfo(Account newAccount) {
    List<Address__c> addresses = [Select Id, Type__c, Primary__c, Street_1__c, Street_2__c, Street_3__c, Street_4__c, City__c, State_Province__c, State_Province__r.ISO_Code__c, Locality__c, Locality__r.Banner_Code__c, Zip_Postal_Code__c, Lookup_Country__c, Lookup_Country__r.ISO_CODE__c,  Active__c From Address__c Where Student__c = :newAccount.Id];
    system.debug('Addresses' + addresses);
        String requestStr = '<soapenv:Envelope ' + soapEnv + tns + prof + prof1 + ext + nam + email + add + nat + cit + phon +
            '  <soapenv:Header/>' +
            '  <soapenv:Body>' +
            '    <tns:createUpdatePersonInfoRequest>' +
            '       <tns:profile>';
        String strAddressTag = '';
        String strDOBTag = '';
        String dob = '';
        requestStr += '<prof:profileInformation>';
        if(newAccount.AR_Student_Finance_England_SFE__c != null && newAccount.AR_Student_Finance_England_SFE__c != ''){
            requestStr += '<ext:extensionfield><ext:key>STUDENT_FINANCE_ID</ext:key><ext:value>' + newAccount.AR_Student_Finance_England_SFE__c + '</ext:value></ext:extensionfield>';
        }
        Date dateOfBirth = newAccount.PersonBirthdate;
        if (dateOfBirth != null){
            dob = dateOfBirth.year() + '-';
            if (dateOfBirth.month() < 10)
                dob += '0' + dateOfBirth.month() + '-'; 
            else
                dob += dateOfBirth.month() + '-';
            if (dateOfBirth.day() < 10)
                dob += '0' + dateOfBirth.day(); 
            else
                dob += dateOfBirth.day();
            dob += 'T00:00:00.000-07:00';   
        }
        if (dob != null && dob != ''){
            strDOBTag += '<prof1:dateOfBirth>' + dob + '</prof1:dateOfBirth>';
        }
        requestStr += strDOBTag;
        String gender = newAccount.Gender__pc;
        String gender_passed = '';
        if (gender != null){
            if (gender == 'Male')
                gender_passed = 'M';
            else
                gender_passed = 'F';
        }
        if (gender_passed != null && gender_passed != ''){
            requestStr += '<prof1:gender>' + gender_passed + '</prof1:gender>';
        }
        requestStr += '</prof:profileInformation>';
        
        if (addresses.size() != 0){
            for(Address__c adds : addresses){
                if(((adds.Street_1__c != null) && (adds.Street_1__c != '')) || ((adds.Street_2__c != null) && (adds.Street_2__c != '')) || (((adds.Street_3__c != null) && (adds.Street_3__c != '')) || ((adds.Street_4__c != null) && (adds.Street_4__c != ''))) || ((adds.City__c != null) && (adds.City__c != '')) || ((adds.State_Province__c != null)) || ((adds.Locality__c != null))  || ((adds.Zip_Postal_Code__c != null) && (adds.Zip_Postal_Code__c != '')) || (adds.Lookup_Country__c != null)){
                    if(adds.Type__c == 'Next of Kin/Emergency/Guardian'){
                        strAddressTag += '<prof:address><add:type>Parent</add:type>';
                    }
                    else{
                        strAddressTag += '<prof:address><add:type>' + adds.Type__c + '</add:type>';
                    }
                    if((adds.Street_1__c != null) && (adds.Street_1__c != '')){
                        strAddressTag += '<add:line1>' + adds.Street_1__c.escapeXML() + '</add:line1>';
                    }
                    if((adds.Street_2__c != null) && (adds.Street_2__c != '')){
                        strAddressTag += '<add:line2>' + adds.Street_2__c.escapeXML() + '</add:line2>';
                    }
                    if((adds.Street_3__c != null) && (adds.Street_3__c != '')){
                        strAddressTag += '<add:line3>' + adds.Street_3__c.escapeXML() + '</add:line3>';
                    }
                    if((adds.Street_4__c != null) && (adds.Street_4__c != '')){
                        strAddressTag += '<add:line4>' + adds.Street_4__c.escapeXML() + '</add:line4>';
                    }
                    if((adds.City__c != null) && (adds.City__c != '')){
                        strAddressTag += '<add:city>' + adds.City__c.escapeXML() + '</add:city>';
                    }    
                    if((adds.State_Province__c != null)){
                        strAddressTag += '<add:stateProvince>' + adds.State_Province__r.ISO_Code__c + '</add:stateProvince>'; 
                    }
                    if((adds.Locality__c != null)){
                        strAddressTag += '<add:locality>' + adds.Locality__r.Banner_Code__c + '</add:locality>';
                    }
                    if((adds.Zip_Postal_Code__c != null) && (adds.Zip_Postal_Code__c != '')){
                        strAddressTag += '<add:postalCode>' + adds.Zip_Postal_Code__c.escapeXML() + '</add:postalCode>'; 
                    }
                    if(adds.Lookup_Country__c != null){ 
                        strAddressTag += '<add:country>' + adds.Lookup_Country__r.ISO_CODE__c + '</add:country>';
                    }
                }
                strAddressTag += '</prof:address>';
            }
            requestStr += strAddressTag;
        }   
        
        if (newAccount.Personal_Email__pc != null && newAccount.Personal_Email__pc != ''){
            if(newAccount.Preferred_Email__pc == 'Personal'){
                requestStr += '<prof:emailAddress><email:type>Personal</email:type><email:emailAddress>' + newAccount.Personal_Email__pc.escapeXML() + '</email:emailAddress><email:isPrimary>true</email:isPrimary></prof:emailAddress>';
            }
            else{
                requestStr += '<prof:emailAddress><email:type>Personal</email:type><email:emailAddress>' + newAccount.Personal_Email__pc.escapeXML() + '</email:emailAddress><email:isPrimary>false</email:isPrimary></prof:emailAddress>';
            }
        }
        if (newAccount.Work_Email__pc != null && newAccount.Work_Email__pc != ''){
            if(newAccount.Preferred_Email__pc == 'Work'){
                requestStr += '<prof:emailAddress><email:type>Work</email:type><email:emailAddress>' + newAccount.Work_Email__pc.escapeXML() + '</email:emailAddress><email:isPrimary>true</email:isPrimary></prof:emailAddress>';
            }
            else{
                requestStr += '<prof:emailAddress><email:type>Work</email:type><email:emailAddress>' + newAccount.Work_Email__pc.escapeXML() + '</email:emailAddress><email:isPrimary>false</email:isPrimary></prof:emailAddress>';
            }
        }
        if (newAccount.BPP_Email__pc != null && newAccount.BPP_Email__pc != ''){
            if(newAccount.Preferred_Email__pc == 'BPP'){
                requestStr += '<prof:emailAddress><email:type>BPP</email:type><email:emailAddress>' + newAccount.BPP_Email__pc.escapeXML() + '</email:emailAddress><email:isPrimary>true</email:isPrimary></prof:emailAddress>';
            }
            else{
                requestStr += '<prof:emailAddress><email:type>BPP</email:type><email:emailAddress>' + newAccount.BPP_Email__pc.escapeXML() + '</email:emailAddress><email:isPrimary>false</email:isPrimary></prof:emailAddress>';
            }
        }
        if (newAccount.Other_Email__pc != null && newAccount.Other_Email__pc != ''){
            if(newAccount.Preferred_Email__pc == 'Other'){
                requestStr += '<prof:emailAddress><email:type>Other</email:type><email:emailAddress>' + newAccount.Other_Email__pc.escapeXML() + '</email:emailAddress><email:isPrimary>true</email:isPrimary></prof:emailAddress>';
            }
            else{
                requestStr += '<prof:emailAddress><email:type>Other</email:type><email:emailAddress>' + newAccount.Other_Email__pc.escapeXML() + '</email:emailAddress><email:isPrimary>false</email:isPrimary></prof:emailAddress>';
            }
        }
        if (newAccount.Billing_Email__pc != null && newAccount.Billing_Email__pc != ''){
            if(newAccount.Preferred_Email__pc == 'Billing'){
                requestStr += '<prof:emailAddress><email:type>Billing</email:type><email:emailAddress>' + newAccount.Billing_Email__pc.escapeXML() + '</email:emailAddress><email:isPrimary>true</email:isPrimary></prof:emailAddress>';
            }
            else{
                requestStr += '<prof:emailAddress><email:type>Billing</email:type><email:emailAddress>' + newAccount.Billing_Email__pc.escapeXML() + '</email:emailAddress><email:isPrimary>false</email:isPrimary></prof:emailAddress>';
            }
        }
        
        if ((newAccount.LastName != null && newAccount.LastName != '') || (newAccount.FirstName != null && newAccount.FirstName != '')){ 
            requestStr += '<prof:name><nam:type>Legal</nam:type>';
            if (newAccount.FirstName != null && newAccount.FirstName != ''){
                requestStr += '<nam:firstName>' + newAccount.FirstName.escapeXML() + '</nam:firstName>';
            }
            requestStr += '<nam:lastName>' + newAccount.LastName.escapeXML() + '</nam:lastName>';
            if (newAccount.Middle_Name__pc != null && newAccount.Middle_Name__pc != ''){
                requestStr += '<nam:middleName>' + newAccount.Middle_Name__pc.escapeXML() + '</nam:middleName>';
            }
            if (newAccount.Salutation != null && newAccount.Salutation != ''){
                requestStr += '<nam:prefix>' + newAccount.Salutation + '</nam:prefix>';
            }
            if (newAccount.AA_Suffix__pc != null && newAccount.AA_Suffix__pc != ''){
                requestStr += '<nam:suffix>' + newAccount.AA_Suffix__pc.escapeXML() + '</nam:suffix>';
            }
            if (newAccount.Preferred_First_Name__pc != null && newAccount.Preferred_First_Name__pc != ''){
                requestStr += '<nam:preferredName>' + newAccount.Preferred_First_Name__pc.escapeXML() + '</nam:preferredName>';
            }
            requestStr += '<nam:primary>true</nam:primary></prof:name>';
        }
        
        String homePhone = String.valueOf(newAccount.personHomePhone);
        requestStr += BuildPhone.BuildPhoneXml(newAccount.personHomePhone, 'Home', newAccount.preferred_Phone__pc == 'Home');
        String mobilePhone = String.valueOf(newAccount.PersonMobilePhone);
        requestStr += BuildPhone.BuildPhoneXml(newAccount.personMobilePhone, 'Mobile', newAccount.preferred_Phone__pc == 'Mobile');
        String workPhone = String.valueOf(newAccount.Work_Phone__pc);
        requestStr += BuildPhone.BuildPhoneXml(newAccount.Work_Phone__pc, 'Business', newAccount.preferred_Phone__pc == 'Work');
        String parentPhone = String.valueOf(newAccount.Parents_Guardian_Emergency_Phone__pc);
        requestStr += BuildPhone.BuildPhoneXml(newAccount.Parents_Guardian_Emergency_Phone__pc, 'Parent', newAccount.preferred_Phone__pc == 'Parents/Guardian/Emergency');
        String fax = String.valueOf(newAccount.Fax);
        requestStr += BuildPhone.BuildPhoneXml(newAccount.Fax, 'Fax',false);
        if (newAccount.Primary_Nationality__pc != null) {
            requestStr += '<prof:citizenship><cit:country>' + newAccount.Primary_Nationality__pr.ISO_CODE__c + '</cit:country></prof:citizenship>';
        }
        requestStr += '<prof:affiliation><prof:value>Student</prof:value></prof:affiliation>';
        if(newAccount.Student_Type__pc == 'Domestic'){
            requestStr += '<prof:nationalityDetails><nat:nationalityStatus>DOMESTIC</nat:nationalityStatus></prof:nationalityDetails>';
        }
        else if(newAccount.Student_Type__pc == 'International'){
            requestStr += '<prof:nationalityDetails><nat:nationalityStatus>INTERNATIONAL</nat:nationalityStatus></prof:nationalityDetails>';
        }
        requestStr += '</tns:profile></tns:createUpdatePersonInfoRequest></soapenv:Body></soapenv:Envelope>';
        
        Http h = new Http();
        HttpRequest req = BPPIntegrationConfig.getData(requestStr);
        req.setTimeout(120000);
        system.debug('XML' + requestStr);   
        system.debug(req.toString());
        HttpResponse res = null;
        if (Test.isRunningTest()){
            String strResponse = '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" ' + 
                    'xmlns:per="http://platform.apollogrp.edu/services/apolloglobal/person/PersonService">' + 
                    '<soapenv:Header>' + 
                    '<gateway:transactionId xmlns:gateway="http://platform.apollogrp.edu/gateway">' + 
                    '2868FEAA-CB14-1BA7-78B5-9DAB5FF54945' + 
                    '</gateway:transactionId>' + 
                    '</soapenv:Header>' + 
                    '<soapenv:Body>' + 
                    '<per:createUpdatePersonInfoResponse>' + 
                    '<per:profileId>' + 
                    '1234f567-bc23-42e8-924c-1234asdf5678' + 
                    '</per:profileId>' + 
                    '</per:createUpdatePersonInfoResponse>' + 
                    '</soapenv:Body>' + 
                    '</soapenv:Envelope>';

            res = new HttpResponse();
            res.setStatusCode(200);
            res.setStatus('OK');
            res.setBody(strResponse);
        }
        else{
            res = h.send(req);
        }
        system.debug(res.getStatus());
        system.debug(res.getBody());
        
        String result = res.getBody();
        if (result.indexOf('<per:profileId>') != -1) {
            
            result = result.substring(result.indexOf('<per:profileId>') + 15);
            result = result.substring(0, 36);
            
            newAccount.PS_Profile_Services_ID__pc = result;
            List<Lead> existingLeads = [select id, Name, PS_Profile_Services_ID__c from Lead where PS_Profile_Services_ID__c =:newAccount.PS_Profile_Services_ID__pc and IsConverted = false];
            system.debug('Existing Leads' +existingLeads.size());
            List<Account> existingAccs = [select id, Name, PS_Profile_Services_ID__pc from Account where PS_Profile_Services_ID__pc =:newAccount.PS_Profile_Services_ID__pc];
            if(existingLeads.size()> 0 || existingAccs.size()> 0){
                if(existingLeads.size()> 0){
                    String str = existingLeads[0].Name;
                    return 'Potential Duplicate Record: ' + str + ' (Lead)';
                }
                else{
                    String str = existingAccs[0].Name;
                    return 'Potential Duplicate Record: ' + str + ' (Account)';
                }               
            }
            else{
                update newAccount;
                return '';
            }
        }
        else if(result.contains('error code [20002]')){
            newAccount.Last_Error__pc = result;
            update newAccount;
            return result;
        }
        else{
            XmlStreamReader reader = new XmlStreamReader(result);
            while(reader.hasNext()) {
                if (reader.getEventType() == XmlTag.START_ELEMENT) {
                    if ('errorDescription' == reader.getLocalName()) {
                        reader.next();
                        if (reader.hasText()){
                            result = reader.getText();
                        }
                    }
                }
                reader.next();
            }
            newAccount.Last_Error__pc = result;
            update newAccount;
            return result;
        }
    }
    
    WebService static String ProfileLeadInt (String LeadId) {
        String query = Util.getAllFieldsSOQL('Lead', 'Id = \'' + LeadId + '\'');
        Database.query(query);
        Lead ld = Database.query(query);
        String result = ProfileIntegrations.CreatePersonInfo1(ld);
        if (result.contains('Potential Duplicate Record:'))
        {
            return result;
        }
        else if(result.contains('error code [20002]')){
            return 'Error: Minimum information for profile creation not available.  Minimum 3 fields are required out of: Name [First or Last],Date Of Birth,Postal code [Home,Mailing and Work], Email [Home,Personal and Work], Phone';
        }
        else if(result == ''){
            return 'Application Submitted Successfully';
        }
        else{
            return result;
        }
    }
    public static String  CreatePersonInfo1(Lead newLead){
    List<Address__c> addresses = [Select Id, Type__c, Primary__c, Street_1__c, Street_2__c, Street_3__c, Street_4__c, City__c, State_Province__c, State_Province__r.ISO_Code__c, Locality__c, Locality__r.Banner_Code__c, Zip_Postal_Code__c, Lookup_Country__c, Lookup_Country__r.ISO_CODE__c,  Active__c From Address__c Where Lead__c = :newLead.Id];
    system.debug('Addresses' + addresses.size());
        String requestStr = '<soapenv:Envelope ' + soapEnv + tns + prof + prof1 + nam + email + add + phon +
            '  <soapenv:Header/>' +
            '  <soapenv:Body>' +
            '    <tns:createUpdatePersonInfoRequest>' +
            '       <tns:profile>';
        String strAddressTag = '';
        String strDOBTag = '';
        String dob = '';
        requestStr += '<prof:profileInformation>';
        Date dateOfBirth = newLead.Birth_Date__c;
        if (dateOfBirth != null){
            dob = dateOfBirth.year() + '-';
            if (dateOfBirth.month() < 10)
                dob += '0' + dateOfBirth.month() + '-'; 
            else
                dob += dateOfBirth.month() + '-';
            if (dateOfBirth.day() < 10)
                dob += '0' + dateOfBirth.day(); 
            else
                dob += dateOfBirth.day();
            dob += 'T00:00:00.000-07:00';   
        }
        if (dob != null && dob != ''){
            strDOBTag += '<prof1:dateOfBirth>' + dob + '</prof1:dateOfBirth>';
        }
        requestStr += strDOBTag;
        String gender = newLead.Gender__c;
        String gender_passed = '';
        if (gender != null){
            if (gender == 'Male')
                gender_passed = 'M';
            else
                gender_passed = 'F';
        }
        if (gender_passed != null && gender_passed != ''){
            requestStr += '<prof1:gender>' + gender_passed + '</prof1:gender>';
        }
        requestStr += '</prof:profileInformation>';
        
        
        if (addresses.size() != 0){
            for(Address__c adds : addresses){
                if(((adds.Street_1__c != null) && (adds.Street_1__c != '')) || ((adds.Street_2__c != null) && (adds.Street_2__c != '')) || (((adds.Street_3__c != null) && (adds.Street_3__c != '')) || ((adds.Street_4__c != null) && (adds.Street_4__c != ''))) || ((adds.City__c != null) && (adds.City__c != '')) || ((adds.State_Province__c != null)) || ((adds.Locality__c != null))  || ((adds.Zip_Postal_Code__c != null) && (adds.Zip_Postal_Code__c != '')) || (adds.Lookup_Country__c != null)){
                    if(adds.Type__c == 'Next of Kin/Emergency/Guardian'){
                        strAddressTag += '<prof:address><add:type>Parent</add:type>';
                    }
                    else{
                        strAddressTag += '<prof:address><add:type>' + adds.Type__c + '</add:type>';
                    }
                    if((adds.Street_1__c != null) && (adds.Street_1__c != '')){
                        strAddressTag += '<add:line1>' + adds.Street_1__c.escapeXML() + '</add:line1>';
                    }
                    if((adds.Street_2__c != null) && (adds.Street_2__c != '')){
                        strAddressTag += '<add:line2>' + adds.Street_2__c.escapeXML() + '</add:line2>';
                    }
                    if((adds.Street_3__c != null) && (adds.Street_3__c != '')){
                        strAddressTag += '<add:line3>' + adds.Street_3__c.escapeXML() + '</add:line3>';
                    }
                    if((adds.Street_4__c != null) && (adds.Street_4__c != '')){
                        strAddressTag += '<add:line4>' + adds.Street_4__c.escapeXML() + '</add:line4>';
                    }
                    if((adds.City__c != null) && (adds.City__c != '')){
                        strAddressTag += '<add:city>' + adds.City__c.escapeXML() + '</add:city>';
                    }    
                    if((adds.State_Province__c != null)){
                        strAddressTag += '<add:stateProvince>' + adds.State_Province__r.ISO_Code__c + '</add:stateProvince>'; 
                    }
                    if((adds.Locality__c != null)){
                        strAddressTag += '<add:locality>' + adds.Locality__r.Banner_Code__c + '</add:locality>';
                    }
                    if((adds.Zip_Postal_Code__c != null) && (adds.Zip_Postal_Code__c != '')){
                        strAddressTag += '<add:postalCode>' + adds.Zip_Postal_Code__c.escapeXML() + '</add:postalCode>'; 
                    }
                    if(adds.Lookup_Country__c != null){ 
                        strAddressTag += '<add:country>' + adds.Lookup_Country__r.ISO_CODE__c + '</add:country>';
                    }
                }
                strAddressTag += '</prof:address>';
            }
            requestStr += strAddressTag;
        }   
        
        if (newLead.Personal_Email__c!= null && newLead.Personal_Email__c != ''){
            if(newLead.Preferred_Email__c == 'Personal'){
                requestStr += '<prof:emailAddress><email:type>Personal</email:type><email:emailAddress>' + newLead.Personal_Email__c.escapeXML() + '</email:emailAddress><email:isPrimary>true</email:isPrimary></prof:emailAddress>';
            }
            else{
                requestStr += '<prof:emailAddress><email:type>Personal</email:type><email:emailAddress>' + newLead.Personal_Email__c.escapeXML() + '</email:emailAddress><email:isPrimary>false</email:isPrimary></prof:emailAddress>';
            }
        }
        if (newLead.Work_Email__c != null && newLead.Work_Email__c != ''){
            if(newLead.Preferred_Email__c == 'Work'){
                requestStr += '<prof:emailAddress><email:type>Work</email:type><email:emailAddress>' + newLead.Work_Email__c.escapeXML() + '</email:emailAddress><email:isPrimary>true</email:isPrimary></prof:emailAddress>';
            }
            else{
                requestStr += '<prof:emailAddress><email:type>Work</email:type><email:emailAddress>' + newLead.Work_Email__c.escapeXML() + '</email:emailAddress><email:isPrimary>false</email:isPrimary></prof:emailAddress>';
            }
        }
        if (newLead.Other_Email__c != null && newLead.Other_Email__c != ''){
            if(newLead.Preferred_Email__c == 'Other'){
                requestStr += '<prof:emailAddress><email:type>Other</email:type><email:emailAddress>' + newLead.Other_Email__c.escapeXML() + '</email:emailAddress><email:isPrimary>true</email:isPrimary></prof:emailAddress>';
            }
            else{
                requestStr += '<prof:emailAddress><email:type>Other</email:type><email:emailAddress>' + newLead.Other_Email__c.escapeXML() + '</email:emailAddress><email:isPrimary>false</email:isPrimary></prof:emailAddress>';
            }
        }
        if (newLead.Billing_Email__c != null && newLead.Billing_Email__c != ''){
            if(newLead.Preferred_Email__c == 'Billing'){
                requestStr += '<prof:emailAddress><email:type>Billing</email:type><email:emailAddress>' + newLead.Billing_Email__c.escapeXML() + '</email:emailAddress><email:isPrimary>true</email:isPrimary></prof:emailAddress>';
            }
            else{
                requestStr += '<prof:emailAddress><email:type>Billing</email:type><email:emailAddress>' + newLead.Billing_Email__c.escapeXML() + '</email:emailAddress><email:isPrimary>false</email:isPrimary></prof:emailAddress>';
            }
        }
        
        if ((newLead.LastName != null && newLead.LastName != '') || (newLead.FirstName != null && newLead.FirstName != '')){ 
            requestStr += '<prof:name><nam:type>Legal</nam:type>';
            if (newLead.FirstName != null && newLead.FirstName != ''){
                requestStr += '<nam:firstName>' + newLead.FirstName.escapeXML() + '</nam:firstName>';
            }
            requestStr += '<nam:lastName>' + newLead.LastName.escapeXML() + '</nam:lastName>';
            if (newLead.Middle_Name__c != null && newLead.Middle_Name__c != ''){
                requestStr += '<nam:middleName>' + newLead.Middle_Name__c.escapeXML() + '</nam:middleName>';
            }
            if (newLead.Salutation != null && newLead.Salutation != ''){
                requestStr += '<nam:prefix>' + newLead.Salutation + '</nam:prefix>';
            }
            if (newLead.Preferred_First_Name__c != null && newLead.Preferred_First_Name__c != ''){
                requestStr += '<nam:preferredName>' + newLead.Preferred_First_Name__c.escapeXML() + '</nam:preferredName>';
            }
            requestStr += '<nam:primary>true</nam:primary></prof:name>';
        }
        
        String homePhone = String.valueOf(newLead.Home_Phone__c);
        requestStr += BuildPhone.BuildPhoneXml(newLead.Home_Phone__c, 'Home', newLead.preferred_Phone__c == 'Home');
        String mobilePhone = String.valueOf(newLead.MobilePhone);
        requestStr += BuildPhone.BuildPhoneXml(newLead.MobilePhone, 'Mobile', newLead.preferred_Phone__c == 'Mobile');
        String workPhone = String.valueOf(newLead.Work_Phone__c);
        requestStr += BuildPhone.BuildPhoneXml(newLead.Work_Phone__c, 'Business', newLead.preferred_Phone__c == 'Work');
        String parentPhone = String.valueOf(newLead.Parents_Guardian_Emergency_Phone__c);
        requestStr += BuildPhone.BuildPhoneXml(newLead.Parents_Guardian_Emergency_Phone__c, 'Parent', newLead.preferred_Phone__c == 'Parents/Guardian/Emergency');
        String fax = String.valueOf(newLead.Fax);
        requestStr += BuildPhone.BuildPhoneXml(newLead.Fax, 'Fax', newLead.preferred_Phone__c == 'Fax');
        
        requestStr += '<prof:affiliation><prof:value>Student</prof:value></prof:affiliation>' +         
            '        </tns:profile>' +
            '    </tns:createUpdatePersonInfoRequest>' + 
            '</soapenv:Body></soapenv:Envelope>';
        
        Http h = new Http();
        HttpRequest req = BPPIntegrationConfig.getData(requestStr);
        req.setTimeout(120000);
        system.debug('XML' + requestStr);   
        system.debug(req.toString());
        HttpResponse res = null;
        if (Test.isRunningTest()){
            String strResponse = '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" ' + 
                    'xmlns:per="http://platform.apollogrp.edu/services/apolloglobal/person/PersonService">' + 
                    '<soapenv:Header>' + 
                    '<gateway:transactionId xmlns:gateway="http://platform.apollogrp.edu/gateway">' + 
                    '2868FEAA-CB14-1BA7-78B5-9DAB5FF54945' + 
                    '</gateway:transactionId>' + 
                    '</soapenv:Header>' + 
                    '<soapenv:Body>' + 
                    '<per:createUpdatePersonInfoResponse>' + 
                    '<per:profileId>' + 
                    '1234f567-bc23-42e8-924c-1234asdf5678' + 
                    '</per:profileId>' + 
                    '</per:createUpdatePersonInfoResponse>' + 
                    '</soapenv:Body>' + 
                    '</soapenv:Envelope>';

            res = new HttpResponse();
            res.setStatusCode(200);
            res.setStatus('OK');
            res.setBody(strResponse);
        }
        else{
            res = h.send(req);
        }
        system.debug(res.getStatus());
        system.debug(res.getBody());
        String resultXml = res.getBody();
        String result = resultXml;
        if (res.getStatus() == 'OK' && res.getStatusCode() == 200){
            XmlStreamReader reader = new XmlStreamReader(resultXml);
            while(reader.hasNext()) {
                if (reader.getEventType() == XmlTag.START_ELEMENT) {
                    if ('profileId' == reader.getLocalName()) {
                        reader.next();
                        if (reader.hasText()){
                            result = reader.getText();
                        }
                    }
                }
                reader.next();
            }
            newLead.PS_Profile_Services_ID__c = result;
            List<Lead> existingLeads = [select id, Name, PS_Profile_Services_ID__c from Lead where PS_Profile_Services_ID__c =:newLead.PS_Profile_Services_ID__c and IsConverted = false];
            system.debug('Existing Leads' +existingLeads.size());
            List<Account> existingAccs = [select id, Name, PS_Profile_Services_ID__pc from Account where PS_Profile_Services_ID__pc =:newLead.PS_Profile_Services_ID__c];
            if(existingLeads.size()> 0 || existingAccs.size()> 0){
                if(existingLeads.size()> 0){
                    String str = existingLeads[0].Name;
                    return 'Potential Duplicate Record: ' + str + ' (Lead)';
                }
                else{
                    String str = existingAccs[0].Name;
                    return 'Potential Duplicate Record: ' + str + ' (Account)';
                }               
            }
            else{
                update newLead;
                return '';
            }
        }
        else if(result.contains('error code [20002]')){
                newLead.Last_Error__c = result;
                update newLead;
                return result;
        }
        else{
            XmlStreamReader reader = new XmlStreamReader(result);
            while(reader.hasNext()) {
                if (reader.getEventType() == XmlTag.START_ELEMENT) {
                    if ('errorDescription' == reader.getLocalName()) {
                        reader.next();
                        if (reader.hasText()){
                            result = reader.getText();
                        }
                    }
                }
                reader.next();
            }
            newLead.Last_Error__c = result;
            update newLead;
            return result;
        }
    }
    
    @future(callOut=true)
    public static void UpdatePersonInfo(String strProfileId, String AccountId) {
        List<Account> accounts = [Select Id, PS_Profile_Services_ID__pc, FirstName, LastName, Middle_Name__pc,AA_Suffix__pc, Salutation, Preferred_First_Name__pc,Previous_First_Name__pc, Previous_Surname__pc, Previous_Middle_Name__pc,
                                  PersonBirthdate, Gender__pc, Preferred_Phone__pc, personHomePhone, personMobilePhone, Work_Phone__pc, Parents_Guardian_Emergency_Phone__pc, Fax, Preferred_Email__pc, Personal_Email__pc, Work_Email__pc, Other_Email__pc, BPP_Email__pc, Billing_Email__pc, 
                                  PersonMailingStreet, PersonMailingCity, PersonMailingState, PersonMailingPostalCode, PersonMailingCountry, PersonOtherStreet, PersonOtherCity, PersonOtherState, PersonOtherPostalCode, PersonOtherCountry, AR_Student_Finance_England_SFE__c, Student_Type__pc, Primary_Nationality__pc, Primary_Nationality__pr.ISO_CODE__c 
                                  From Account Where Id = :AccountId];
                             
        if (accounts.size() == 0){
            return;
        }
        Account acc = accounts[0];
        List<Address__c> addresses = [Select Id, Type__c, Primary__c, Street_1__c, Street_2__c, Street_3__c, Street_4__c, City__c, State_Province__c, State_Province__r.ISO_Code__c, Locality__c, Locality__r.Banner_Code__c, Zip_Postal_Code__c, Lookup_Country__c, Lookup_Country__r.ISO_CODE__c,  Active__c From Address__c Where Student__c = :acc.Id];
        system.debug('Addresses' + addresses);
        
        String strProfileIdTag = '<tns:profileId>' + strProfileId + '</tns:profileId>';
        String requestStr = '<soapenv:Envelope ' + soapEnv + tns + prof + prof1 + ext + nam + email + add + nat + cit + phon +
            '  <soapenv:Header/>' +
            '  <soapenv:Body>' +
            '    <tns:createUpdatePersonInfoRequest>' + 
            strProfileIdTag +
            '       <tns:profile>';
        String strAddressTag = '';
        String strDOBTag = '';
        requestStr += '<prof:profileInformation>';
        if(acc.AR_Student_Finance_England_SFE__c != null && acc.AR_Student_Finance_England_SFE__c != ''){
            requestStr += '<ext:extensionfield><ext:key>STUDENT_FINANCE_ID</ext:key><ext:value>' + acc.AR_Student_Finance_England_SFE__c + '</ext:value></ext:extensionfield>';
        }
        Date dateOfBirth = acc.PersonBirthdate;
        String dob = '';
        if (dateOfBirth != null){
            dob = dateOfBirth.year() + '-';
            if (dateOfBirth.month() < 10)
                dob += '0' + dateOfBirth.month() + '-'; 
            else
                dob += dateOfBirth.month() + '-';
            if (dateOfBirth.day() < 10)
                dob += '0' + dateOfBirth.day(); 
            else
                dob += dateOfBirth.day();
            dob += 'T00:00:00.000-07:00';   
        }
        if (dob != null && dob != ''){
            strDOBTag += '<prof1:dateOfBirth>' + dob + '</prof1:dateOfBirth>';
        }
        requestStr += strDOBTag;
        String gender = acc.Gender__pc;
        String gender_passed = '';
        if (gender != null){
            if (gender == 'Male')
                gender_passed = 'M';
            else
                gender_passed = 'F';
        }
        if (gender_passed != null && gender_passed != ''){
            requestStr += '<prof1:gender>' + gender_passed + '</prof1:gender>';
        }
        requestStr += '</prof:profileInformation>';
        
        if (addresses.size() != 0){
            for(Address__c adds : addresses){
                if(((adds.Street_1__c != null) && (adds.Street_1__c != '')) || ((adds.Street_2__c != null) && (adds.Street_2__c != '')) || (((adds.Street_3__c != null) && (adds.Street_3__c != '')) || ((adds.Street_4__c != null) && (adds.Street_4__c != ''))) || ((adds.City__c != null) && (adds.City__c != '')) || ((adds.State_Province__c != null)) || ((adds.Locality__c != null))  || ((adds.Zip_Postal_Code__c != null) && (adds.Zip_Postal_Code__c != '')) || (adds.Lookup_Country__c != null)){
                    if(adds.Type__c == 'Next of Kin/Emergency/Guardian'){
                        strAddressTag += '<prof:address><add:type>Parent</add:type>';
                    }
                    else{
                        strAddressTag += '<prof:address><add:type>' + adds.Type__c + '</add:type>';
                    }
                    if((adds.Street_1__c != null) && (adds.Street_1__c != '')){
                        strAddressTag += '<add:line1>' + adds.Street_1__c.escapeXML() + '</add:line1>';
                    }
                    if((adds.Street_2__c != null) && (adds.Street_2__c != '')){
                        strAddressTag += '<add:line2>' + adds.Street_2__c.escapeXML() + '</add:line2>';
                    }
                    if((adds.Street_3__c != null) && (adds.Street_3__c != '')){
                        strAddressTag += '<add:line3>' + adds.Street_3__c.escapeXML() + '</add:line3>';
                    }
                    if((adds.Street_4__c != null) && (adds.Street_4__c != '')){
                        strAddressTag += '<add:line4>' + adds.Street_4__c.escapeXML() + '</add:line4>';
                    }
                    if((adds.City__c != null) && (adds.City__c != '')){
                        strAddressTag += '<add:city>' + adds.City__c.escapeXML() + '</add:city>';
                    }    
                    if((adds.State_Province__c != null)){
                        strAddressTag += '<add:stateProvince>' + adds.State_Province__r.ISO_Code__c + '</add:stateProvince>'; 
                    }
                    if((adds.Locality__c != null)){
                        strAddressTag += '<add:locality>' + adds.Locality__r.Banner_Code__c + '</add:locality>';
                    }
                    if((adds.Zip_Postal_Code__c != null) && (adds.Zip_Postal_Code__c != '')){
                        strAddressTag += '<add:postalCode>' + adds.Zip_Postal_Code__c.escapeXML() + '</add:postalCode>'; 
                    }
                    if(adds.Lookup_Country__c != null){ 
                        strAddressTag += '<add:country>' + adds.Lookup_Country__r.ISO_CODE__c + '</add:country>';
                    }
                }
                strAddressTag += '</prof:address>';
            }
            requestStr += strAddressTag;
        }   
        
        if (acc.Personal_Email__pc != null && acc.Personal_Email__pc != ''){
            if(acc.Preferred_Email__pc == 'Personal'){
                requestStr += '<prof:emailAddress><email:type>Personal</email:type><email:emailAddress>' + acc.Personal_Email__pc.escapeXML() + '</email:emailAddress><email:isPrimary>true</email:isPrimary></prof:emailAddress>';
            }
            else{
                requestStr += '<prof:emailAddress><email:type>Personal</email:type><email:emailAddress>' + acc.Personal_Email__pc.escapeXML() + '</email:emailAddress><email:isPrimary>false</email:isPrimary></prof:emailAddress>';
            }
        }
        if (acc.Work_Email__pc != null && acc.Work_Email__pc != ''){
            if(acc.Preferred_Email__pc == 'Work'){
                requestStr += '<prof:emailAddress><email:type>Work</email:type><email:emailAddress>' + acc.Work_Email__pc.escapeXML() + '</email:emailAddress><email:isPrimary>true</email:isPrimary></prof:emailAddress>';
            }
            else{
                requestStr += '<prof:emailAddress><email:type>Work</email:type><email:emailAddress>' + acc.Work_Email__pc.escapeXML() + '</email:emailAddress><email:isPrimary>false</email:isPrimary></prof:emailAddress>';
            }
        }
        if (acc.BPP_Email__pc != null && acc.BPP_Email__pc != ''){
            if(acc.Preferred_Email__pc == 'BPP'){
                requestStr += '<prof:emailAddress><email:type>BPP</email:type><email:emailAddress>' + acc.BPP_Email__pc.escapeXML() + '</email:emailAddress><email:isPrimary>true</email:isPrimary></prof:emailAddress>';
            }
            else{
                requestStr += '<prof:emailAddress><email:type>BPP</email:type><email:emailAddress>' + acc.BPP_Email__pc.escapeXML() + '</email:emailAddress><email:isPrimary>false</email:isPrimary></prof:emailAddress>';
            }
        }
        if (acc.Other_Email__pc != null && acc.Other_Email__pc != ''){
            if(acc.Preferred_Email__pc == 'Other'){
                requestStr += '<prof:emailAddress><email:type>Other</email:type><email:emailAddress>' + acc.Other_Email__pc.escapeXML() + '</email:emailAddress><email:isPrimary>true</email:isPrimary></prof:emailAddress>';
            }
            else{
                requestStr += '<prof:emailAddress><email:type>Other</email:type><email:emailAddress>' + acc.Other_Email__pc.escapeXML() + '</email:emailAddress><email:isPrimary>false</email:isPrimary></prof:emailAddress>';
            }
        }
        if (acc.Billing_Email__pc != null && acc.Billing_Email__pc != ''){
            if(acc.Preferred_Email__pc == 'Billing'){
                requestStr += '<prof:emailAddress><email:type>Billing</email:type><email:emailAddress>' + acc.Billing_Email__pc.escapeXML() + '</email:emailAddress><email:isPrimary>true</email:isPrimary></prof:emailAddress>';
            }
            else{
                requestStr += '<prof:emailAddress><email:type>Billing</email:type><email:emailAddress>' + acc.Billing_Email__pc.escapeXML() + '</email:emailAddress><email:isPrimary>false</email:isPrimary></prof:emailAddress>';
            }
        }
        
        if ((acc.FirstName != null && acc.FirstName != '') || (acc.LastName != null && acc.LastName != '')){ 
            requestStr += '<prof:name><nam:type>Legal</nam:type>';
            if (acc.FirstName != null && acc.FirstName != ''){
                requestStr += '<nam:firstName>' + acc.FirstName.escapeXML() + '</nam:firstName>';
            }
            requestStr += '<nam:lastName>' + acc.LastName.escapeXML() + '</nam:lastName>';
            if (acc.Middle_Name__pc != null && acc.Middle_Name__pc != ''){
                requestStr += '<nam:middleName>' + acc.Middle_Name__pc.escapeXML() + '</nam:middleName>';
            }
            if (acc.Salutation != null && acc.Salutation != ''){
                requestStr += '<nam:prefix>' + acc.Salutation + '</nam:prefix>';
            }
            if (acc.AA_Suffix__pc != null && acc.AA_Suffix__pc != ''){
                requestStr += '<nam:suffix>' + acc.AA_Suffix__pc.escapeXML() + '</nam:suffix>';
            }
            if (acc.Preferred_First_Name__pc != null && acc.Preferred_First_Name__pc != ''){
                requestStr += '<nam:preferredName>' + acc.Preferred_First_Name__pc.escapeXML() + '</nam:preferredName>';
            }
            requestStr += '<nam:primary>true</nam:primary></prof:name>';
        }
        
        String homePhone = String.valueOf(acc.personHomePhone);
        requestStr += BuildPhone.BuildPhoneXml(acc.personHomePhone, 'Home', acc.preferred_Phone__pc == 'Home');
        String mobilePhone = String.valueOf(acc.PersonMobilePhone);
        requestStr += BuildPhone.BuildPhoneXml(acc.personMobilePhone, 'Mobile', acc.preferred_Phone__pc == 'Mobile');
        String workPhone = String.valueOf(acc.Work_Phone__pc);
        requestStr += BuildPhone.BuildPhoneXml(acc.Work_Phone__pc, 'Business', acc.preferred_Phone__pc == 'Work');
        String parentPhone = String.valueOf(acc.Parents_Guardian_Emergency_Phone__pc);
        requestStr += BuildPhone.BuildPhoneXml(acc.Parents_Guardian_Emergency_Phone__pc, 'Parent', acc.preferred_Phone__pc == 'Parents/Guardian/Emergency');
        String fax = String.valueOf(acc.Fax);
        requestStr += BuildPhone.BuildPhoneXml(acc.Fax, 'Fax',false);
        if (acc.Primary_Nationality__pc != null) {
            requestStr += '<prof:citizenship><cit:country>' + acc.Primary_Nationality__pr.ISO_CODE__c + '</cit:country></prof:citizenship>';
        }
        requestStr += '<prof:affiliation><prof:value>Student</prof:value></prof:affiliation>';
        if(acc.Student_Type__pc == 'Domestic'){
            requestStr += '<prof:nationalityDetails><nat:nationalityStatus>DOMESTIC</nat:nationalityStatus></prof:nationalityDetails>';
        }
        else if(acc.Student_Type__pc == 'International'){
            requestStr += '<prof:nationalityDetails><nat:nationalityStatus>INTERNATIONAL</nat:nationalityStatus></prof:nationalityDetails>';
        }
        requestStr += '</tns:profile></tns:createUpdatePersonInfoRequest></soapenv:Body></soapenv:Envelope>';
        
        Http h = new Http();
        HttpRequest req = BPPIntegrationConfig.getData(requestStr);
        req.setTimeout(120000);
        system.debug('XML' + requestStr);   
        system.debug(req.toString());
        HttpResponse res = null;
        if (Test.isRunningTest()){
            String strResponse = '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" ' + 
                    'xmlns:per="http://platform.apollogrp.edu/services/apolloglobal/person/PersonService">' + 
                    '<soapenv:Header>' + 
                    '<gateway:transactionId xmlns:gateway="http://platform.apollogrp.edu/gateway">' + 
                    '2868FEAA-CB14-1BA7-78B5-9DAB5FF54945' + 
                    '</gateway:transactionId>' + 
                    '</soapenv:Header>' + 
                    '<soapenv:Body>' + 
                    '<per:createUpdatePersonInfoResponse>' + 
                    '<per:profileId>' + 
                    '1234f567-bc23-42e8-924c-1234asdf5678' + 
                    '</per:profileId>' + 
                    '</per:createUpdatePersonInfoResponse>' + 
                    '</soapenv:Body>' + 
                    '</soapenv:Envelope>';

            res = new HttpResponse();
            res.setStatusCode(200);
            res.setStatus('OK');
            res.setBody(strResponse);
        }
        else{
            res = h.send(req);
        }
        system.debug(res.getStatus());
        system.debug(res.getBody());
        
        String result = res.getBody();
        if (result.indexOf('<per:profileId>') != -1) {
                
                result = result.substring(result.indexOf('<per:profileId>') + 15);
                result = result.substring(0, 36);
                return;
        }
        else {
            return;
        }
    }
}