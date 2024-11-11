global with sharing class KPMGTrainingMgrIntegrations {
    private static final String soapEnv = 'xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" ';
    private static final String tns = 'xmlns:tns="http://platform.apollogrp.edu/services/apolloglobal/person/PersonService" ';
    private static final String prof = 'xmlns:prof="http://platform.apollogrp.edu/schemas/profile/2010/07/02/Profile" ';
    private static final String prof1 = 'xmlns:prof1="http://platform.apollogrp.edu/schemas/profile/2010/07/02/ProfileInformation" ';
    private static final String nam = 'xmlns:nam="http://platform.apollogrp.edu/schemas/profile/2010/07/02/Name" ';
    private static final String email = 'xmlns:email="http://platform.apollogrp.edu/schemas/profile/2010/07/02/EmailAddress" ';
    private static final String add = 'xmlns:add="http://platform.apollogrp.edu/schemas/profile/2010/07/02/Address" ';
    private static final String v1 ='xmlns:v1="http://platform.apollogrp.edu/services/apolloglobal/gds/v1" ';
    private static final String phon = 'xmlns:phon="http://platform.apollogrp.edu/schemas/profile/2010/07/02/Phone"> ';
    
    WebService static String TrainingMgrInt (String ContactId) {
        String query = Util.getAllFieldsSOQL('Contact', 'Id = \'' + ContactId + '\'');
        Contact c = Database.query(query);
        String result = KPMGTrainingMgrIntegrations.provisionTrainingManager(c);
        if(result == 'Application Submitted Successfully'){
            return result;
        }
        else{
            return result;
        }
    } 
    
    private static FindProfilesRequest createFindProfileRequest(Contact contact){
        FindProfilesRequest findProfileRequest = new FindProfilesRequest();
        FindProfile findProfile = new FindProfile();
        Date dateOfBirth = contact.Birthdate;
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
        findProfile.dateOfBirth = dob;
        
        findProfile.address = findAddress(contact.id);        
        
        ProfileEmailAddress emailAddress = new ProfileEmailAddress();
        emailAddress.type = 'Personal';
        emailAddress.emailAddress = contact.Personal_Email__c;
        findProfile.emailAddress = new ProfileEmailAddress[]{emailAddress};
            
            ProfileName profileName = new ProfileName();
        profileName.firstName = contact.FirstName;
        profileName.lastName = contact.LastName;
        profileName.type = 'Legal';
        findProfile.name = new ProfileName[]{profileName};
            
            List<ProfilePhone> phoneNumbers = new List<ProfilePhone>();
        
        if (contact.HomePhone != null && contact.HomePhone != '') {
            ProfilePhone profilePhone = createPhone(contact.HomePhone, 'Home');
            phoneNumbers.add(profilePhone);
        }
        if (contact.MobilePhone != null && contact.MobilePhone != '') {
            ProfilePhone profilePhone = createPhone(contact.MobilePhone, 'Mobile');
            phoneNumbers.add(profilePhone);
        }
        if (contact.Work_Phone__c != null && contact.Work_Phone__c != '') {
            ProfilePhone profilePhone = createPhone(contact.Work_Phone__c, 'Work');
            phoneNumbers.add(profilePhone);
        }
        if (contact.Fax != null && contact.Fax != '') {
            ProfilePhone profilePhone = createPhone(contact.Fax, 'Fax');
            phoneNumbers.add(profilePhone);
        }
        findProfile.phone = phoneNumbers;
        findProfileRequest.findProfile = findProfile;
        return findProfileRequest;
    }
    
    private static ProfilePhone createPhone(String phone, String type){
        system.debug('Phone: ' + phone);
        ProfilePhone profilePhone = new ProfilePhone();
        String strippedNumber = phone.replaceAll('\\D','');
        String areaCode = '';
        String phoneNumber = '';
        if (strippedNumber.length() == 10) {
            areaCode = strippedNumber.substring(0, 3);
            phoneNumber = strippedNumber.substring(3);
        }
        else if (strippedNumber.length() > 10) {
            areaCode = strippedNumber.substring(0, 3);
            phoneNumber = strippedNumber.substring(3, 10);
        }
        if (areaCode != '') {
            profilePhone.areaCode = areaCode;
            profilePhone.phoneNumber = phoneNumber;
        }else{
            profilePhone.countryCode = phone;
            profilePhone.areaCode = '-';
            profilePHone.phoneNumber = '-';
        }
        profilePhone.type = type;
        return profilePhone;
        
    }
    private static List<ProfileAddress> findAddress(Id contactId){
        list<Address__c> addresses = [Select Id, Type__c, Zip_Postal_Code__c From Address__c Where Training_Manager__c = :contactId];
        List<ProfileAddress> profileAddressList = new List<ProfileAddress>();
        for(Address__c address : addresses){
            ProfileAddress profileAddress = new ProfileAddress();
            profileAddress.postalCode = address.Zip_Postal_Code__c;
            profileAddress.type = address.Type__c;
            profileAddressList.add(profileAddress);
        }
        return profileAddressList;
    }
    
    private static List<ProfileFullAddress> findFullAddress(Id contactId){
        list<Address__c> addresses = [Select Id, Type__c, Primary__c, Street_1__c, Street_2__c, Street_3__c, Street_4__c, City__c, State_Province__c, State_Province__r.ISO_Code__c, Locality__c, Locality__r.Banner_Code__c, Zip_Postal_Code__c, Lookup_Country__c, Lookup_Country__r.ISO_CODE__c,  Active__c From Address__c Where Training_Manager__c = :contactId];
        List<ProfileFullAddress> profileAddressList = new List<ProfileFullAddress>();
        for(Address__c address : addresses){
            ProfileFullAddress profileAddress = new ProfileFullAddress();
            profileAddress.postalCode = address.Zip_Postal_Code__c;
            profileAddress.type = address.Type__c;
            profileAddress.line1 = address.Street_1__c;
            profileAddress.line2 = address.Street_2__c;
            profileAddress.line3 = address.Street_3__c;
            profileAddress.line4 = address.Street_4__c;
            profileAddress.city = address.City__c;
            profileAddress.stateProvince = address.State_Province__c;
            profileAddress.country = address.Lookup_Country__r.ISO_CODE__c;   
            profileAddressList.add(profileAddress);
        }
        return profileAddressList;
    }
    
    private static InsertProfileRequest createInsertProfileRequest( FindProfilesRequest fpr, contact contact){
        InsertProfileRequest ipr = new InsertProfileRequest();
        Profile profile = new Profile();
        ProfileInformation profileInformation = new ProfileInformation();
        profileInformation.dateOfBirth = fpr.findProfile.dateOfBirth;
        profile.profileInformation = profileInformation;
        
        profile.address = findFullAddress(contact.id);
        
        profile.name = fpr.findProfile.name;
        profile.emailAddress = fpr.findProfile.emailAddress;
        profile.phone = fpr.findProfile.phone;
        Affiliation affiliation = new Affiliation();
        affiliation.value = 'TrainingManager';
        profile.affiliation = new Affiliation[]{affiliation};
            ipr.profile = profile;
        
        return ipr;
        
    }
    
    private static String provisionTrainingManager(Contact contact){
        FindProfilesRequest req = createFindProfileRequest(contact);
        FindProfileRequestPayload fpr = new FindProfileRequestPayload();
        fpr.findProfilesRequest = req;
        system.debug('request: ' + JSON.serialize(fpr));
        HttpRequest request = BPPIntegrationConfig.callUpdateRestService(JSON.serialize(fpr), 'application/json', '/rest/profile/v2/findProfiles');
        Http http = new Http();
        HttpResponse res;
        if (Test.isRunningTest()){
            res = new HttpResponse();
            String strResponse = '{"companyId":"1234f567-bc23-42e8-924c-1234asdf5678","operation":"UPDATE"}';
            res.setStatusCode(200);
            res.setStatus('OK');
            res.setBody(strResponse);
        }
        else{
            res = http.send(request);
        }
        
        String studentProfileId = '';
        String ErrorDescription;
        String result;
        
        if (res.getStatus() == 'OK' && res.getStatusCode() == 200){
            //resp is a JSON string
            JSONParser parser = JSON.createParser(res.getBody());
            while (parser.nextToken() != null) {
                if ((parser.getCurrentToken() == JSONToken.FIELD_NAME)){
                    String fieldName = parser.getText();
                    parser.nextToken();
                    if(fieldName == 'profileId') {
                        studentProfileId = parser.getText();
                        system.debug('find: studentProfileId' + studentProfileId);
                        break;
                    }
                    if(fieldName == 'Description') {
                        ErrorDescription = parser.getText();
                        system.debug('Find Error Message' + ErrorDescription);
                        if(ErrorDescription.contains('error code [20002]'))
                            result = 'error code [20002]';
                        contact.Last_Error__c = ErrorDescription;
                        break;
                    }
                }
            }
            
        }
        
        system.debug('Test Response:' + res.getBody() + ' ' + studentProfileId);
        system.debug('Test Response:' + res.getStatus());
        if(studentProfileId.trim() != '' ){
            system.debug('There was a match found, exiting');
            update contact;
            return 'Duplicate record found.  This record matches ' + studentProfileId;
        }
        //Create Insert Call
        InsertProfileRequest ipr = createInsertProfileRequest(req, contact);
        InsertProfilePayload ipp = new InsertProfilePayload();
        ipp.insertProfileRequest = ipr;
        request = BPPIntegrationConfig.callRestService(JSON.serialize(ipp), 'application/json', '/rest/profile/v2/insertProfile');
        if(!Test.isRunningTest()){
            res = http.send(request);
        }
        system.debug('Test Response:' + res.getBody());
        system.debug('Test Response:' + res.getStatus());
        if (res.getStatus() == 'OK' && res.getStatusCode() == 200){
            //resp is a JSON string
            JSONParser parser = JSON.createParser(res.getBody());
            while (parser.nextToken() != null) {
                if ((parser.getCurrentToken() == JSONToken.FIELD_NAME)){
                    String fieldName = parser.getText();
                    parser.nextToken();
                    if(fieldName == 'profileId') {
                        studentProfileId = parser.getText();
                        system.debug('insert: studentProfileId' + studentProfileId);
                        break;
                    }
                    if(fieldName == 'Description') {
                        ErrorDescription = parser.getText();
                        system.debug('Find Error Message' + ErrorDescription);
                        if(ErrorDescription.contains('error code [20002]'))
                            result = 'error code [20002]';
                        contact.Last_Error__c = ErrorDescription;
                        
                        break;
                    }
                }
            }
            
        }
        if(Test.isRunningTest()){
            studentProfileId = '1';
        }
        
        if(studentProfileId == ''){
            update contact;
            return result;
        }
		contact.PS_Profile_Services_ID__c = studentProfileId; 

        CreateSISPersonRequestPayload bannerPayload = new CreateSISPersonRequestPayload();
        CreateSISPersonRequest banner = new CreateSISPersonRequest();
        banner.profileId = studentProfileId;
        bannerPayload.createSISPersonRequest = banner;
        request = BPPIntegrationConfig.callRestService(JSON.serialize(bannerPayload), 'application/json', '/rest/person/v2/createSISPerson');
        if(!Test.isRunningTest()){
            res = http.send(request);
        }
        system.debug('Test Response:' + res.getBody());
        system.debug('Test Response:' + res.getStatus());
        String personId;
        if (res.getStatus() == 'OK' && res.getStatusCode() == 200){
            //resp is a JSON string
            JSONParser parser = JSON.createParser(res.getBody());
            while (parser.nextToken() != null) {
                if ((parser.getCurrentToken() == JSONToken.FIELD_NAME)){
                    String fieldName = parser.getText();
                    parser.nextToken();
                    if(fieldName == 'personId') {
                        personId = parser.getText();
                        system.debug('insert: personId' + personId);
                        break;
                    }
                    if(fieldName == 'Description') {
                        ErrorDescription = parser.getText();
                        system.debug('Find Error Message' + ErrorDescription);
                        if(ErrorDescription.contains('error code [20002]'))
                            result = 'error code [20002]';
                        contact.Last_Error__c = ErrorDescription;
                        
                        break;
                    }
                }
            }
            
        }
        
        if(personId == ''){
            update contact;
            return result;
        }
        contact.BNR_Banner_ID__c = personId;
        
        ProfileUserRequestPayload payload = new ProfileUserRequestPayload();
        ProvisionUserRequest pur = new ProvisionUserRequest();
        pur.profileId = studentProfileId;
        pur.userRole = 'TRAININGMANAGER';
        pur.userName = '';
        payload.provisionUserRequest = pur;
        system.debug('Payload: ' + JSON.serialize(payload));
        request = BPPIntegrationConfig.callRestService(JSON.serialize(payload), 'application/json', '/rest/gds/v2/provisionUser');
        
        if(!Test.isRunningTest()){
            res = http.send(request);
        }
        
        system.debug('Test Response:' + res.getBody());
        system.debug('Test Response:' + res.getStatus());
        
        String username;
        String password;
        String emailAddress;
        if (res.getStatus() == 'OK' && res.getStatusCode() == 200){
            //resp is a JSON string
            JSONParser parser = JSON.createParser(res.getBody());
            while (parser.nextToken() != null) {
                if ((parser.getCurrentToken() == JSONToken.FIELD_NAME)){
                    String fieldName = parser.getText();
                    parser.nextToken();
                    if(fieldName == 'userName') {
                        username = parser.getText();
                        system.debug('insert: personId' + personId);
                        continue;
                    }
                    if(fieldName == 'password') {
                        password = parser.getText();
                        system.debug('insert: personId' + personId);
                        continue;
                    }
                    if(fieldName == 'emailAddress') {
                        emailAddress = parser.getText();
                        system.debug('insert: personId' + personId);
                        continue;
                    }
                    if(fieldName == 'Description') {
                        ErrorDescription = parser.getText();
                        system.debug('Find Error Message' + ErrorDescription);
                        if(ErrorDescription.contains('error code [20002]'))
                            result = 'error code [20002]';
                        contact.Last_Error__c = ErrorDescription;
                        
                        break;
                    }
                }
            }
            
        }
        
        contact.Username__c = username;
        contact.Password__c = password;
        contact.Training_Manager_Email__c = emailAddress;
        
        //  Call Liferay integrations
        /*if(!Test.isRunningTest()){
       	 LifeRayIntegration.CreateUser(studentProfileId);
        }*/
        
        update contact;
        return 'Application Submitted Successfully';
        
    }
    
    
    
    
    
    
/*    
    private static String CreateSISTrainingMgrPerson(Contact cont) {
        String result = CreateSISTrainingMgr(cont);
        if (result.indexOf('<per:profileID>') != -1) {
            String strProfileId = result.substring(result.indexOf('<per:profileID>') + 15);
            strProfileId = strProfileId.substring(0, 36);
            cont.PS_Profile_Services_ID__c = strProfileId;
            String strBannerId = result.substring(result.indexOf('<per:bannerID>') + 14);
            strBannerId = strBannerId.substring(0,9);
            cont.BNR_Banner_ID__c = strBannerId;
            list<Contact> existingContacts = [select id, Name, PS_Profile_Services_ID__c from Contact where PS_Profile_Services_ID__c =:cont.PS_Profile_Services_ID__c];
            system.debug('Existing Training managers' +existingContacts.size());
            if(existingContacts.size()> 0){
                String str = existingContacts[0].Name;
                return 'Potential Duplicate Record: ' + str + ' (Contact)';
            }
            else{
                String requestStr = '<soapenv:Envelope ' + soapEnv + v1 + '><soapenv:Header/><soapenv:Body><v1:provisionUserRequest>';
                if(cont.BNR_Banner_ID__c != null || cont.BNR_Banner_ID__c != ''){
                    requestStr +=  '<v1:personId>' + cont.BNR_Banner_ID__c + '</v1:personId>';
                }
                requestStr +=  '<v1:role>TRAININGMANAGER</v1:role>';
                requestStr +=  '</v1:provisionUserRequest></soapenv:Body></soapenv:Envelope>';
                
                Http h = new Http();
                HttpRequest req = BPPIntegrationConfig.getData(requestStr);
                req.setTimeout(120000);
                system.debug('XML:' + requestStr);   
                system.debug(req.toString());
                HttpResponse res = null;
                if (Test.isRunningTest()){
                    String strResponse = '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:ad="http://platform.apollogrp.edu/providers/apolloglobal/gds/v1" xmlns:v1="http://platform.apollogrp.edu/services/apolloglobal/gds/v1"><soapenv:Header><gateway:transactionId xmlns:gateway="http://platform.apollogrp.edu/gateway">239C144F-C486-E2FA-6079-D2B181AFE050</gateway:transactionId></soapenv:Header><soapenv:Body><v1:provisionUserResponse><v1:userName>a.galvir</v1:userName><v1:personId>BP0015240</v1:personId><v1:password>Ga052781</v1:password><v1:emailAddress>a.galvir@mybpp.bpntu.edu</v1:emailAddress><v1:alreadyProvisionedFor>NONE</v1:alreadyProvisionedFor></v1:provisionUserResponse></soapenv:Body></soapenv:Envelope>';
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
                
                result = res.getBody();
                if (result.indexOf('<v1:personId>') != -1) {
                    String struserName1 = '';
                    String strBannerId1 = '';
                    String strpassword1 = '';
                    String stremailAddress1 = '';
                    String stralreadyProvisionedFor1 = '';
                    Integer nEndIndex1;
                    nEndIndex1 = result.indexOf('</v1:userName>');
                    struserName1 = result.substring(result.indexOf('<v1:userName>') + 13, nEndIndex1);
                    cont.Username__c = struserName1;
                    if (result.indexOf('<v1:personId>') != -1){
                        nEndIndex1 = result.indexOf('</v1:personId>');
                        strBannerId1 = result.substring(result.indexOf('<v1:personId>') + 13, nEndIndex1);
                        cont.BNR_Banner_ID__c = strBannerId1;
                    }
                    if (result.indexOf('<v1:password>') != -1){
                        nEndIndex1 = result.indexOf('</v1:password>');
                        strpassword1 = result.substring(result.indexOf('<v1:password>') + 13, nEndIndex1);
                        cont.Password__c = strpassword1;
                    }
                    if (result.indexOf('<v1:emailAddress>') != -1){
                        nEndIndex1 = result.indexOf('</v1:emailAddress>');
                        stremailAddress1 = result.substring(result.indexOf('<v1:emailAddress>') + 17, nEndIndex1);
                        cont.Training_Manager_Email__c = stremailAddress1.unescapexml();
                    }
                    if (result.indexOf('<v1:alreadyProvisionedFor>') != -1){
                        nEndIndex1 = result.indexOf('</v1:alreadyProvisionedFor>');
                        stralreadyProvisionedFor1 = result.substring(result.indexOf('<v1:alreadyProvisionedFor>') + 26, nEndIndex1);
                        cont.Already_Provisioned_For__c = stralreadyProvisionedFor1;
                    }
                    
                    //  Call Liferay integrations
                    LifeRayIntegration.CreateUser(cont.PS_Profile_Services_ID__c);
                    
                    update cont;
                    return 'Application Submitted Successfully';
                }
                else {
                    cont.Last_Error__c = result;
                    update cont;
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
                    return result;
                } 
            }
        }
        else {
            cont.Last_Error__c = result;
            update cont;
            system.debug('Result' +result);
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
            return result;
        } 
    }
    
    public static String CreateSISTrainingMgr(Contact con) {
        list<Address__c> addresses = [Select Id, Type__c, Primary__c, Street_1__c, Street_2__c, Street_3__c, Street_4__c, City__c, State_Province__c, State_Province__r.ISO_Code__c, Locality__c, Locality__r.Banner_Code__c, Zip_Postal_Code__c, Lookup_Country__c, Lookup_Country__r.ISO_CODE__c,  Active__c From Address__c Where Training_Manager__c = :con.Id];
        system.debug('Addresses' + addresses);
        String strAddressTag = '';
        Date dateOfBirth = con.Birthdate;
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
        
        String requestStr = '<soapenv:Envelope ' + soapEnv + tns + prof + prof1 + nam + email + add + phon +
            '  <soapenv:Header/>' +
            '  <soapenv:Body>' +
            '    <tns:createSISPersonRequest>' +
            '       <tns:profile>';
        if (dob != null && dob != ''){
            requestStr += '<prof:profileInformation><prof1:dateOfBirth>' + dob + '</prof1:dateOfBirth></prof:profileInformation>';
        }
        if (addresses.size() != 0){
            for(Address__c adds : addresses){
                if(((adds.Street_1__c != null) && (adds.Street_1__c != '')) || ((adds.Street_2__c != null) && (adds.Street_2__c != '')) || (((adds.Street_3__c != null) && (adds.Street_3__c != '')) || ((adds.Street_4__c != null) && (adds.Street_4__c != ''))) || ((adds.City__c != null) && (adds.City__c != '')) || (adds.State_Province__c != null) || ((adds.Locality__c != null))  || ((adds.Zip_Postal_Code__c != null) && (adds.Zip_Postal_Code__c != '')) || (adds.Lookup_Country__c != null)){
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
                    if(adds.State_Province__c != null){
                        strAddressTag += '<add:stateProvince>' + adds.State_Province__r.ISO_Code__c + '</add:stateProvince>'; 
                    }
                    if((adds.Locality__c != null)){
                        strAddressTag += '<add:locality>' + adds.Locality__r.Banner_Code__c + '</add:locality>';
                    }
                    if((adds.Zip_Postal_Code__c != null) && (adds.Zip_Postal_Code__c != '')){
                        strAddressTag += '<add:postalCode>' + adds.Zip_Postal_Code__c.escapeXML() + '</add:postalCode>'; 
                    }
                    if(adds.Lookup_Country__c != null){ 
                        strAddressTag += '<add:country>' + adds.Lookup_Country__r.ISO_Code__c + '</add:country>';
                    }
                }
                strAddressTag += '</prof:address>';
            }
            requestStr += strAddressTag;
        }
        if (con.Personal_Email__c != null && con.Personal_Email__c != ''){
            if(con.Preferred_Email__c == 'Personal'){
                requestStr += '<prof:emailAddress><email:type>Personal</email:type><email:emailAddress>' + con.Personal_Email__c.escapeXML() + '</email:emailAddress><email:isPrimary>true</email:isPrimary></prof:emailAddress>';
            }
            else{
                requestStr += '<prof:emailAddress><email:type>Personal</email:type><email:emailAddress>' + con.Personal_Email__c.escapeXML() + '</email:emailAddress><email:isPrimary>false</email:isPrimary></prof:emailAddress>';
            }
        }
        if (con.Work_Email__c != null && con.Work_Email__c != ''){
            if(con.Preferred_Email__c == 'Work'){
                requestStr += '<prof:emailAddress><email:type>Work</email:type><email:emailAddress>' + con.Work_Email__c.escapeXML() + '</email:emailAddress><email:isPrimary>true</email:isPrimary></prof:emailAddress>';
            }
            else{
                requestStr += '<prof:emailAddress><email:type>Work</email:type><email:emailAddress>' + con.Work_Email__c.escapeXML() + '</email:emailAddress><email:isPrimary>false</email:isPrimary></prof:emailAddress>';
            }
        }
        if (con.Middle_Name__c != null && con.Middle_Name__c != ''){ 
            requestStr += '<prof:name><nam:type>Legal</nam:type><nam:firstName>' + con.FirstName.escapeXML() + '</nam:firstName><nam:lastName>' + con.LastName.escapeXML() + '</nam:lastName><nam:middleName>' + con.Middle_Name__c.escapeXML() + '</nam:middleName><nam:primary>true</nam:primary></prof:name>';
        }
        else{
            requestStr += '<prof:name><nam:type>Legal</nam:type><nam:firstName>' + con.FirstName.escapeXML() + '</nam:firstName><nam:lastName>' + con.LastName.escapeXML() + '</nam:lastName><nam:primary>true</nam:primary></prof:name>';
        }
        String homePhone = String.valueOf(con.HomePhone);
        requestStr += BuildPhone.BuildPhoneXml(con.HomePhone, 'Home', con.preferred_Phone__c == 'Home');
        String mobilePhone = String.valueOf(con.MobilePhone);
        requestStr += BuildPhone.BuildPhoneXml(con.MobilePhone, 'Mobile', con.preferred_Phone__c == 'Mobile');
        String workPhone = String.valueOf(con.Work_Phone__c);
        requestStr += BuildPhone.BuildPhoneXml(con.Work_Phone__c, 'Business', con.preferred_Phone__c == 'Work');
        String fax = String.valueOf(con.Fax);
        requestStr += BuildPhone.BuildPhoneXml(con.Fax, 'Fax', con.preferred_Phone__c == 'Fax');
        
        requestStr += '<prof:affiliation><prof:value>TrainingManager</prof:value></prof:affiliation>' +         
            '        </tns:profile>' +
            '    </tns:createSISPersonRequest>' + 
            '</soapenv:Body></soapenv:Envelope>';
        
        system.debug('XML:' + requestStr);   
        Http h = new Http();
        HttpRequest req = BPPIntegrationConfig.getData(requestStr);
        req.setTimeout(120000);
        system.debug(req.toString());
        HttpResponse res = null;
        if (Test.isRunningTest()){
            String strResponse = '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:per="http://platform.apollogrp.edu/services/apolloglobal/person/PersonService"><soapenv:Header><gateway:transactionId xmlns:gateway="http://platform.apollogrp.edu/gateway">A0208FA6-4FA2-2AB6-EB16-C7F99FDDD7D8</gateway:transactionId></soapenv:Header><soapenv:Body><per:createSISPersonResponse><per:profileID>eec3c34c-18ce-4751-8845-d82ef6ca7c83</per:profileID><per:bannerID>U00000338</per:bannerID></per:createSISPersonResponse></soapenv:Body></soapenv:Envelope>';
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
        if (result.indexOf('<per:profileID>') != -1) {
            return result;
        }
        else {
            return result;
        }
    }
*/    
    @future(callOut=true)
    public static void UpdateTrainingManagerInfo(String strProfileId, String ContactId) {
        list<Contact> contacts = [Select Id, PS_Profile_Services_ID__c, Birthdate, Personal_Email__c, Preferred_Email__c, Work_Email__c, FirstName, LastName, Middle_Name__c, Preferred_Phone__c, HomePhone, MobilePhone, Work_Phone__c, Fax From Contact Where Id = : ContactId];
        if (contacts.size() == 0){
            return;
        }
        Contact con = contacts[0];
        list<Address__c> addresses = [Select Id, Type__c, Primary__c, Street_1__c, Street_2__c, Street_3__c, Street_4__c, City__c, State_Province__c, State_Province__r.ISO_Code__c, Locality__c, Locality__r.Banner_Code__c, Zip_Postal_Code__c, Lookup_Country__c, Lookup_Country__r.ISO_CODE__c,  Active__c From Address__c Where Training_Manager__c = : con.Id];
        system.debug('Addresses' + addresses);
        String strAddressTag = '';
        Date dateOfBirth = con.Birthdate;
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
        String strProfileIdTag = '<tns:profileId>' + strProfileId + '</tns:profileId>';
        String requestStr = '<soapenv:Envelope ' + soapEnv + tns + prof + prof1 + nam + email + add + phon +
            '  <soapenv:Header/>' +
            '  <soapenv:Body>' +
            '    <tns:createUpdatePersonInfoRequest>' +
            strProfileIdTag +
            '       <tns:profile>';
        if (dob != null && dob != ''){
            requestStr += '<prof:profileInformation><prof1:dateOfBirth>' + dob + '</prof1:dateOfBirth></prof:profileInformation>';
        }
        if (addresses.size() != 0){
            for(Address__c adds : addresses){
                if(((adds.Street_1__c != null) && (adds.Street_1__c != '')) || ((adds.Street_2__c != null) && (adds.Street_2__c != '')) || (((adds.Street_3__c != null) && (adds.Street_3__c != '')) || ((adds.Street_4__c != null) && (adds.Street_4__c != ''))) || ((adds.City__c != null) && (adds.City__c != '')) || (adds.State_Province__c != null) || ((adds.Locality__c != null))  || ((adds.Zip_Postal_Code__c != null) && (adds.Zip_Postal_Code__c != '')) || (adds.Lookup_Country__c != null)){
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
                    if(adds.State_Province__c != null){
                        strAddressTag += '<add:stateProvince>' + adds.State_Province__r.ISO_Code__c + '</add:stateProvince>'; 
                    }
                    if((adds.Locality__c != null)){
                        strAddressTag += '<add:locality>' + adds.Locality__r.Banner_Code__c + '</add:locality>';
                    }
                    if((adds.Zip_Postal_Code__c != null) && (adds.Zip_Postal_Code__c != '')){
                        strAddressTag += '<add:postalCode>' + adds.Zip_Postal_Code__c.escapeXML() + '</add:postalCode>'; 
                    }
                    if(adds.Lookup_Country__c != null){ 
                        strAddressTag += '<add:country>' + adds.Lookup_Country__r.ISO_Code__c + '</add:country>';
                    }
                }
                strAddressTag += '</prof:address>';
            }
            requestStr += strAddressTag;
        }
        if (con.Personal_Email__c != null && con.Personal_Email__c != ''){
            if(con.Preferred_Email__c == 'Personal'){
                requestStr += '<prof:emailAddress><email:type>Personal</email:type><email:emailAddress>' + con.Personal_Email__c.escapeXML() + '</email:emailAddress><email:isPrimary>true</email:isPrimary></prof:emailAddress>';
            }
            else{
                requestStr += '<prof:emailAddress><email:type>Personal</email:type><email:emailAddress>' + con.Personal_Email__c.escapeXML() + '</email:emailAddress><email:isPrimary>false</email:isPrimary></prof:emailAddress>';
            }
        }
        if (con.Work_Email__c != null && con.Work_Email__c != ''){
            if(con.Preferred_Email__c == 'Work'){
                requestStr += '<prof:emailAddress><email:type>Work</email:type><email:emailAddress>' + con.Work_Email__c.escapeXML() + '</email:emailAddress><email:isPrimary>true</email:isPrimary></prof:emailAddress>';
            }
            else{
                requestStr += '<prof:emailAddress><email:type>Work</email:type><email:emailAddress>' + con.Work_Email__c.escapeXML() + '</email:emailAddress><email:isPrimary>false</email:isPrimary></prof:emailAddress>';
            }
        }
        if (con.Middle_Name__c != null && con.Middle_Name__c != ''){ 
            requestStr += '<prof:name><nam:type>Legal</nam:type><nam:firstName>' + con.FirstName.escapeXML() + '</nam:firstName><nam:lastName>' + con.LastName.escapeXML() + '</nam:lastName><nam:middleName>' + con.Middle_Name__c.escapeXML() + '</nam:middleName><nam:primary>true</nam:primary></prof:name>';
        }
        else{
            requestStr += '<prof:name><nam:type>Legal</nam:type><nam:firstName>' + con.FirstName.escapeXML() + '</nam:firstName><nam:lastName>' + con.LastName.escapeXML() + '</nam:lastName><nam:primary>true</nam:primary></prof:name>';
        }
        String homePhone = String.valueOf(con.HomePhone);
        requestStr += BuildPhone.BuildPhoneXml(con.HomePhone, 'Home', con.preferred_Phone__c == 'Home');
        String mobilePhone = String.valueOf(con.MobilePhone);
        requestStr += BuildPhone.BuildPhoneXml(con.MobilePhone, 'Mobile', con.preferred_Phone__c == 'Mobile');
        String workPhone = String.valueOf(con.Work_Phone__c);
        requestStr += BuildPhone.BuildPhoneXml(con.Work_Phone__c, 'Business', con.preferred_Phone__c == 'Work');
        String fax = String.valueOf(con.Fax);
        requestStr += BuildPhone.BuildPhoneXml(con.Fax, 'Fax', con.preferred_Phone__c == 'Fax');
        
        requestStr += '<prof:affiliation><prof:value>TrainingManager</prof:value></prof:affiliation>' +         
            '        </tns:profile>' +
            '    </tns:createUpdatePersonInfoRequest>' + 
            '</soapenv:Body></soapenv:Envelope>';
        
        system.debug('XML:' + requestStr);   
        Http h = new Http();
        HttpRequest req = BPPIntegrationConfig.getData(requestStr);
        req.setTimeout(120000);
        system.debug(req.toString());
        HttpResponse res = null;
        if (Test.isRunningTest()){
            String strResponse = '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:per="http://platform.apollogrp.edu/services/apolloglobal/person/PersonService"><soapenv:Header><gateway:transactionId xmlns:gateway="http://platform.apollogrp.edu/gateway">A0208FA6-4FA2-2AB6-EB16-C7F99FDDD7D8</gateway:transactionId></soapenv:Header><soapenv:Body><per:createSISPersonResponse><per:profileID>eec3c34c-18ce-4751-8845-d82ef6ca7c83</per:profileID><per:bannerID>U00000338</per:bannerID></per:createSISPersonResponse></soapenv:Body></soapenv:Envelope>';
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
        if (result.indexOf('<per:profileID>') != -1) {
            return;
        }
        else {
            return;
        }
    }
    
    @isTest
    private static void unitTest1() {
        Test.startTest();
        country_list__c cntry = CreateTestData.createCountry1();
        State_Province__c stt = new State_Province__c(Name = 'Unit Test', ISO_Code__c = '123');
        insert stt;
        Locality__c lct = new Locality__c(Name = 'Unit Test', Banner_Code__c = '123');
        insert lct;
        List<Address__c> addresses = new List<Address__c>();
        
        Database.DMLOptions dbDML = new Database.DMLOptions(); 
        dbDML.DuplicateRuleHeader.allowSave = true;
        dbDML.DuplicateRuleHeader.runAsCurrentUser = true;
        
        Contact c1 = new Contact();
        c1.RecordTypeId=Schema.sObjectType.Contact.getRecordTypeInfosByName().get('Training Manager').getRecordTypeId();
        c1.FirstName = 'John';
        c1.LastName = 'Smith';
        c1.Middle_Name__c = 'T';
        c1.Birthdate = Date.valueOf('1985-07-22');
        c1.Preferred_Email__c = 'Home';
        c1.Personal_Email__c = 'johnsmith1@test.com';
        c1.Work_Email__c = 'johnsmith2@test.com';
        c1.Home_Email__c = 'johnsmith3@test.com';
        c1.preferred_Phone__c = 'Home';
        c1.HomePhone = '0123456789';
        c1.MobilePhone = '456789';
        c1.Work_Phone__c = '432123456789';
        Database.insert(c1, dbDML);
        
        Address__c add1 = new Address__c();
        add1.Training_Manager__c = c1.Id;
        add1.Type__c = 'Mailing';
        add1.Street_1__c = '1234 S Test Dr';
        add1.Street_2__c = '1234';
        add1.Street_3__c = '123';
        add1.Street_4__c = '12';
        add1.City__c = 'Test City';
        add1.Locality__c = lct.Id;
        add1.State_Province__c = stt.Id;
        add1.Zip_Postal_Code__c = '12345';
        add1.Lookup_Country__c = cntry.Id;
        insert add1;
        addresses.add(add1);
        Address__c add2 = new Address__c();
        add2.Training_Manager__c = c1.Id;
        add2.Street_1__c = '1234 S Test Dr';
        add2.Street_2__c = '1234';
        add2.Street_4__c = '123';
        add2.City__c = 'Test City';
        add2.Locality__c = lct.Id;
        add2.State_Province__c = stt.Id;
        add2.Zip_Postal_Code__c = '12345';
        add2.Lookup_Country__c = cntry.Id;
        try{
            add2.Type__c = 'Mailing';
            insert add2;
        }
        catch(Exception e){
            System.Assert(e.getMessage().contains('There can be only one Address Type associated to a record.'));
        }
        
        Contact c2 = new Contact();
        c2.RecordTypeId=Schema.sObjectType.Contact.getRecordTypeInfosByName().get('Training Manager').getRecordTypeId();
        c2.FirstName = 'Joe';
        c2.LastName = 'Bloggs';
        c2.Birthdate = Date.valueOf('1986-12-01');
        c2.Preferred_Email__c = 'Personal';
        c2.Preferred_Email__c = 'Work';
        c2.Personal_Email__c = 'test@test.com';
        c2.Work_Email__c = 'test1@test.com';
        c2.Home_Email__c = 'test2@test.com';
        c2.preferred_Phone__c = 'Mobile';
        c2.HomePhone = '9876543210';
        c2.MobilePhone = '987654';
        c2.Work_Phone__c = '987654321234';
        Database.insert(c2, dbDML);
        
        Address__c add3 = new Address__c();
        add3.Training_Manager__c = c2.Id;
        add3.Type__c = 'Next of Kin/Emergency/Guardian';
        add3.Street_1__c = '1234 S Test Dr';
        add3.Street_2__c = '1234';
        add3.Street_4__c = '123';
        add3.City__c = 'Test City';
        add3.Locality__c = lct.Id;
        add3.State_Province__c = stt.Id;
        add3.Zip_Postal_Code__c = '12345';
        add3.Lookup_Country__c = cntry.Id;
        insert add3;
        addresses.add(add3);
        Address__c add4 = new Address__c();
        add4.Training_Manager__c = c2.Id;
        add4.Type__c = 'Mailing';
        add4.Street_1__c = '1234 S Test Dr';
        add4.Street_2__c = '1234';
        add4.Street_4__c = '123';
        add4.City__c = 'Test City';
        add4.Locality__c = lct.Id;
        add4.State_Province__c = stt.Id;
        add4.Zip_Postal_Code__c = '12345';
        add4.Lookup_Country__c = cntry.Id;
        insert add4;
        try{
            add4.Type__c = 'Next of Kin/Emergency/Guardian';
            update add4;
        }
        catch(Exception e){
            System.Assert(e.getMessage().contains('There can be only one Address Type associated to a record.'));
        }
        
        String ContactId = c1.Id;
        KPMGTrainingMgrIntegrations.TrainingMgrInt(ContactId);
        String ContactId2 = c2.Id;
        KPMGTrainingMgrIntegrations.TrainingMgrInt(ContactId2);
        test.stoptest();
    }
}