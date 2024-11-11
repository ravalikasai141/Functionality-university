global with sharing class PersonIntegrations {
    private static final String soapEnv = 'xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" ';
    private static final String tns = 'xmlns:tns="http://platform.apollogrp.edu/services/apolloglobal/person/PersonService" ';
    private static final String prof = 'xmlns:prof="http://platform.apollogrp.edu/schemas/profile/2010/07/02/Profile" ';
    private static final String prof1 = 'xmlns:prof1="http://platform.apollogrp.edu/schemas/profile/2010/07/02/ProfileInformation" ';
    private static final String nam = 'xmlns:nam="http://platform.apollogrp.edu/schemas/profile/2010/07/02/Name" ';
    private static final String email = 'xmlns:email="http://platform.apollogrp.edu/schemas/profile/2010/07/02/EmailAddress" ';
    private static final String add = 'xmlns:add="http://platform.apollogrp.edu/schemas/profile/2010/07/02/Address" ';
    private static final String v1 ='xmlns:v1="http://platform.apollogrp.edu/services/apolloglobal/gds/v1" ';
    private static final String phon = 'xmlns:phon="http://platform.apollogrp.edu/schemas/profile/2010/07/02/Phone"> ';
    private static Boolean bFailFaculty = false;
    
    WebService static String PersonInt (String FacultyId) {
        String query = Util.getAllFieldsSOQL('Faculty__c', 'Id = \'' + FacultyId + '\'');
        string result = '';
        Faculty__c f = Database.query(query);
        Faculty__c fct  =[Select Id, Country__c, Country__r.ISO_Code__c, State_Province__c, State_Province__r.ISO_Code__c, Locality__c, Locality__r.Banner_Code__c
                          From Faculty__c Where Id =: f.Id Limit 1];
        if(f.Country__c != null){
            f.Country__c = fct.Country__c;
            f.Country__r = fct.Country__r;
        }
        if(f.State_Province__c != null){
            f.State_Province__c = fct.State_Province__c;
            f.State_Province__r = fct.State_Province__r;
        }
        if(f.Locality__c != null){
            f.Locality__c = fct.Locality__c;
            f.Locality__r = fct.Locality__r;
        }
        if(f.Role__c == 'FACULTY' || f.Role__c == 'COACH'){
            result = provisionProfile(f);
        }
        else{
            result = PersonIntegrations.CreateSISStaffPerson(f);
        }
        return result;
    } 
    
    private static String provisionProfile(Faculty__c f){
        FindProfilesRequest req = createFindProfileRequest(f);
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
                            result = ErrorDescription;
                        break;
                    }
                }
            }
            
        }
        
        system.debug('Test Response:' + res.getBody() + ' ' + studentProfileId);
        system.debug('Test Response:' + res.getStatus());
        if(studentProfileId.trim() != '' ){
            system.debug('There was a match found, exiting');
            return 'Duplicate record found.  This record matches ' + studentProfileId;
        }
        if(!Test.isRunningTest()){
            if (result != '' && result != null){
                system.debug('There was an error');
                return result;
            }
        }
        
        //Create Insert Call
        InsertProfileRequest ipr = createInsertProfileRequest(req, f);
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
                        result = ErrorDescription;
                        break;
                    }
                }
            }
            
        }
        String personId;
        
        if(Test.isRunningTest()){
            studentProfileId = '1';
            //personId = '1';
        }
        
        if(studentProfileId == ''){
            return result;
        }
        
        if (result != '' && result != null){
            system.debug('There was an error');
            return result;
        }
        f.Profile_Services_ID__c = studentProfileId;
        
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
                        result = ErrorDescription;
                        break;
                    }
                }
            }
            
        }
        
        if(personId == ''){
            return result;
        }
        
        if (result != '' && result != null){
            system.debug('There was an error');
            return result;
        }
        f.Banner_ID__c = personId;
        
        ProfileUserRequestPayload payload = new ProfileUserRequestPayload();
        ProvisionUserRequest pur = new ProvisionUserRequest();
        pur.profileId = studentProfileId;
        pur.userRole = f.Role__c;
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
                        break;
                    }
                }
            }
            
        }
        
        f.Username__c = username;
        f.Password__c = password;
        f.Staff_Email_Add__c = emailAddress;
        
        String fctRecTypeID = '';
        Map<String,String> fctRecordTypes = new Map<String,String>{}; 
            List<RecordType> r = [Select r.SobjectType, r.Name, r.developername, r.IsActive, r.Id From RecordType r where ((Sobjecttype='Faculty__c') AND (isActive =true) )];
        for(RecordType rt: r)
            fctRecordTypes.put(rt.developername,rt.Id);
        fctRecTypeID = fctRecordTypes.get('Locked_Faculty');
        f.RecordTypeId = fctRecTypeID;
        
        //  Call Liferay integrations
        if(!Test.isRunningTest()){
            LifeRayIntegration.CreateUser(studentProfileId);
        }
        
        update f;
        return 'Application Submitted Successfully';
    }
    
    
    
    private static InsertProfileRequest createInsertProfileRequest(Faculty__c fac){
        InsertProfileRequest ipr = new InsertProfileRequest();
        return ipr;
    }
    
    private static InsertProfileRequest createInsertProfileRequest( FindProfilesRequest fpr, Faculty__c fac){
        InsertProfileRequest ipr = new InsertProfileRequest();
        Profile profile = new Profile();
        ProfileInformation profileInformation = new ProfileInformation();
        profileInformation.dateOfBirth = fpr.findProfile.dateOfBirth;
        profile.profileInformation = profileInformation;
        
        ProfileFullAddress address = new ProfileFullAddress();
        address.type = 'Mailing';
        address.line1 = fac.Street_1__c;
        address.line2 = fac.Street_2__c;
        address.line3 = fac.Street_3__c;
        address.line4 = fac.Street_4__c;
        address.city = fac.City__c;
        address.stateProvince = fac.State_Province__c;
        address.postalCode = fac.Postal_Code__c;
        address.country = fac.Country__r.ISO_Code__c;   
        profile.address = new ProfileFullAddress[]{address};
            
            profile.name = fpr.findProfile.name;
        profile.emailAddress = fpr.findProfile.emailAddress;
        profile.phone = fpr.findProfile.phone;
        Affiliation affiliation = new Affiliation();
        affiliation.value = fac.Role__c;
        profile.affiliation = new Affiliation[]{affiliation};
            ipr.profile = profile;
        
        return ipr;
        
    }
    private static FindProfilesRequest createFindProfileRequest(Faculty__c fac){
        FindProfilesRequest findProfileRequest = new FindProfilesRequest();
        FindProfile findProfile = new FindProfile();
        Date dateOfBirth = fac.Date_of_Birth__c;
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
        
        if (fac.Postal_Code__c !=null && fac.Postal_Code__c != ''){
            ProfileAddress address = new ProfileAddress();
            address.type = 'Mailing';
            address.postalCode = fac.Postal_Code__c;    
            findProfile.address = new ProfileAddress[]{address}; 
                }
        
        ProfileEmailAddress emailAddress = new ProfileEmailAddress();
        emailAddress.type = 'Personal';
        emailAddress.emailAddress = fac.Email__c;
        findProfile.emailAddress = new ProfileEmailAddress[]{emailAddress};
            
            ProfileName profileName = new ProfileName();
        profileName.firstName = fac.First_Name__c;
        profileName.lastName = fac.Last_Name__c;
        profileName.type = 'Legal';
        findProfile.name = new ProfileName[]{profileName};
            
            
            if (fac.Phone__c != null && fac.Phone__c != '') {
                ProfilePhone profilePhone = new ProfilePhone();
                String pNumber=fac.Phone__c;
                
                profilePhone.type = 'Home';
                String strippedNumber = pNumber.replaceAll('\\D','');
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
                    profilePhone.areaCode = '-';
                    profilePhone.phoneNumber = '-';
                    profilePhone.countryCode = strippedNumber;
                }
                findProfile.phone = new ProfilePhone[]{profilePhone};
                    }
        
        findProfileRequest.findProfile = findProfile;
        return findProfileRequest;
    }
    
    private static String provisionBannerPerson(){
        return '';
    }
    /*    
private static String CreateSISFacultyPerson(Faculty__c fac) {
String fctRecTypeID = '';
Map<String,String> fctRecordTypes = new Map<String,String>{}; 
List<RecordType> r = [Select r.SobjectType, r.Name, r.developername, r.IsActive, r.Id From RecordType r where ((Sobjecttype='Faculty__c') AND (isActive =true) )];
for(RecordType rt: r)
fctRecordTypes.put(rt.developername,rt.Id);
fctRecTypeID = fctRecordTypes.get('Locked_Faculty');
String result = CreateSISFacultyProvisioning(fac);
if (result.indexOf('<per:profileID>') != -1) {
String strProfileId = result.substring(result.indexOf('<per:profileID>') + 15);
strProfileId = strProfileId.substring(0, 36);
fac.Profile_Services_ID__c = strProfileId;
String strBannerId = result.substring(result.indexOf('<per:bannerID>') + 14);
strBannerId = strBannerId.substring(0,9);
fac.Banner_ID__c = strBannerId;
String requestStr = '<soapenv:Envelope ' + soapEnv + v1 + '><soapenv:Header/><soapenv:Body><v1:provisionUserRequest>';
if(fac.Banner_ID__c != null || fac.Banner_ID__c != ''){
requestStr +=  '<v1:personId>' + fac.Banner_ID__c + '</v1:personId>';
}
requestStr +=  '<v1:role>'+fac.Role__c+'</v1:role>';//
requestStr +=  '</v1:provisionUserRequest></soapenv:Body></soapenv:Envelope>';

Http h = new Http();
HttpRequest req = BPPIntegrationConfig.getData(requestStr);
req.setTimeout(120000);
system.debug('XML:' + requestStr);   
system.debug(req.toString());
HttpResponse res = null;
if (Test.isRunningTest()){
res = new HttpResponse();
String strResponse = '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:ad="http://platform.apollogrp.edu/providers/apolloglobal/gds/v1" xmlns:v1="http://platform.apollogrp.edu/services/apolloglobal/gds/v1"><soapenv:Header><gateway:transactionId xmlns:gateway="http://platform.apollogrp.edu/gateway">239C144F-C486-E2FA-6079-D2B181AFE050</gateway:transactionId></soapenv:Header><soapenv:Body><v1:provisionUserResponse><v1:userName>a.galvir</v1:userName><v1:personId>BP0015240</v1:personId><v1:password>Ga052781</v1:password><v1:emailAddress>a.galvir@mybpp.bpntu.edu</v1:emailAddress><v1:alreadyProvisionedFor>NONE</v1:alreadyProvisionedFor></v1:provisionUserResponse></soapenv:Body></soapenv:Envelope>';
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
fac.Username__c = struserName1;
if (result.indexOf('<v1:personId>') != -1){
nEndIndex1 = result.indexOf('</v1:personId>');
strBannerId1 = result.substring(result.indexOf('<v1:personId>') + 13, nEndIndex1);
fac.Banner_ID__c = strBannerId1;
}
if (result.indexOf('<v1:password>') != -1){
nEndIndex1 = result.indexOf('</v1:password>');
strpassword1 = result.substring(result.indexOf('<v1:password>') + 13, nEndIndex1);
fac.Password__c = strpassword1;
}
if (result.indexOf('<v1:emailAddress>') != -1){
nEndIndex1 = result.indexOf('</v1:emailAddress>');
stremailAddress1 = result.substring(result.indexOf('<v1:emailAddress>') + 17, nEndIndex1);
fac.Staff_Email_Add__c = stremailAddress1.unescapexml();
}
if (result.indexOf('<v1:alreadyProvisionedFor>') != -1){
nEndIndex1 = result.indexOf('</v1:alreadyProvisionedFor>');
stralreadyProvisionedFor1 = result.substring(result.indexOf('<v1:alreadyProvisionedFor>') + 26, nEndIndex1);
fac.Already_Provisioned_For__c = stralreadyProvisionedFor1;
}
fac.RecordTypeId = fctRecTypeID;

//  Call Liferay integrations
LifeRayIntegration.CreateUser(fac.Profile_Services_ID__c);

update fac;
return 'Application Submitted Successfully';
}
else {
fac.Last_Error__c = result;
update fac;
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
else {
fac.Last_Error__c = result;
update fac;
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
private static String CreateSISFacultyProvisioning(Faculty__c newFaculty) {
Date dateOfBirth = newFaculty.Date_of_Birth__c;
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
if (((newFaculty.Street_1__c != null) && (newFaculty.Street_1__c != '')) || ((newFaculty.Street_2__c != null) && (newFaculty.Street_2__c != '')) || ((newFaculty.Street_3__c != null) && (newFaculty.Street_3__c != '')) || ((newFaculty.Street_4__c != null) && (newFaculty.Street_4__c != '')) || ((newFaculty.City__c != null) && (newFaculty.City__c != '')) || (newFaculty.State_Province__c != null) || (newFaculty.Locality__c != null) || ((newFaculty.Postal_Code__c != null) && (newFaculty.Postal_Code__c != '')) || (newFaculty.Country__c != null)){
requestStr += '<prof:address><add:type>Mailing</add:type>';
if((newFaculty.Street_1__c != null) && (newFaculty.Street_1__c != '')){
requestStr += '<add:line1>' + newFaculty.Street_1__c.escapeXML() + '</add:line1>';
}
if((newFaculty.Street_2__c != null) && (newFaculty.Street_2__c != '')){
requestStr += '<add:line2>' + newFaculty.Street_2__c.escapeXML() + '</add:line2>';
}
if((newFaculty.Street_3__c != null) && (newFaculty.Street_3__c != '')){
requestStr += '<add:line3>' + newFaculty.Street_3__c.escapeXML() + '</add:line3>';
} 
if((newFaculty.Street_4__c != null) && (newFaculty.Street_4__c != '')){
requestStr += '<add:line4>' + newFaculty.Street_4__c.escapeXML() + '</add:line4>';
} 
if((newFaculty.City__c != null) && (newFaculty.City__c != '')){
requestStr += '<add:city>' + newFaculty.City__c.escapeXML() + '</add:city>';
} 
if(newFaculty.State_Province__c != null){ 
requestStr += '<add:stateProvince>' + newFaculty.State_Province__r.ISO_Code__c + '</add:stateProvince>'; 
}
if(newFaculty.Locality__c != null){
requestStr += '<add:locality>' + newFaculty.Locality__r.Banner_Code__c + '</add:locality>';
}
if((newFaculty.Postal_Code__c != null) && (newFaculty.Postal_Code__c != '')){ 
requestStr += '<add:postalCode>' + newFaculty.Postal_Code__c.escapeXML() + '</add:postalCode>';
} 
if(newFaculty.Country__c != null){ 
requestStr += '<add:country>' + newFaculty.Country__r.ISO_Code__c + '</add:country>'; 
}
requestStr += '</prof:address>';
}        
if (newFaculty.Email__c != null && newFaculty.Email__c != ''){
requestStr += '<prof:emailAddress><email:type>Personal</email:type><email:emailAddress>' + newFaculty.Email__c.escapeXML() + '</email:emailAddress><email:isPrimary>true</email:isPrimary></prof:emailAddress>';
} 
if (newFaculty.Middle_Name__c != null && newFaculty.Middle_Name__c != ''){ 
requestStr += '<prof:name><nam:type>Legal</nam:type><nam:firstName>' + newFaculty.First_Name__c.escapeXML() + '</nam:firstName><nam:lastName>' + newFaculty.Last_Name__c.escapeXML() + '</nam:lastName><nam:middleName>' + newFaculty.Middle_Name__c.escapeXML() + '</nam:middleName><nam:primary>true</nam:primary></prof:name>';
}
else{
requestStr += '<prof:name><nam:type>Legal</nam:type><nam:firstName>' + newFaculty.First_Name__c.escapeXML() + '</nam:firstName><nam:lastName>' + newFaculty.Last_Name__c.escapeXML() + '</nam:lastName><nam:primary>true</nam:primary></prof:name>';
}
system.debug('Phone: ' + newFaculty.Phone__c);
String homePhone = String.valueOf(Faculty__c.Phone__c);
requestStr += BuildPhone.BuildPhoneXml(newFaculty.Phone__c, 'Home', true);
requestStr += '<prof:affiliation><prof:value>'+newFaculty.Role__c+'</prof:value></prof:affiliation>' +   //FACULTY      
'        </tns:profile>' +
'    </tns:createSISPersonRequest>' + 
'</soapenv:Body></soapenv:Envelope>';

Http h = new Http();
HttpRequest req = BPPIntegrationConfig.getData(requestStr);
req.setTimeout(120000);
system.debug('XML:' + requestStr);   
system.debug(req.toString());
HttpResponse res = null;
if (Test.isRunningTest()){
res = new HttpResponse();
if (bFailFaculty){
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
}
else{
String strResponse = '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:per="http://platform.apollogrp.edu/services/apolloglobal/person/PersonService"><soapenv:Header><gateway:transactionId xmlns:gateway="http://platform.apollogrp.edu/gateway">D3D77B5D-9261-5E81-28AE-E730F1148A3E</gateway:transactionId></soapenv:Header><soapenv:Body><per:createSISPersonResponse><per:profileID>277ac878-a579-4670-8e15-deb6ae0fc6ab</per:profileID><per:bannerID>BP0015240</per:bannerID></per:createSISPersonResponse></soapenv:Body></soapenv:Envelope>';
res.setStatusCode(200);
res.setStatus('OK');
res.setBody(strResponse);
}
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
else{
return result;
}
}
*/   
    private static String CreateSISStaffPerson(Faculty__c fac) {
        String fctRecTypeID = '';
        Map<String,String> fctRecordTypes = new Map<String,String>{}; 
            List<RecordType> r = [Select r.SobjectType, r.Name, r.developername, r.IsActive, r.Id From RecordType r where ((Sobjecttype='Faculty__c') AND (isActive =true) )];
        for(RecordType rt: r)
            fctRecordTypes.put(rt.developername,rt.Id);
        fctRecTypeID = fctRecordTypes.get('Locked_Faculty');
        String result = CreateSISStaffProvisioning(fac); 
        if (result.indexOf('<per:profileId>') != -1) {
            String strProfileId = result.substring(result.indexOf('<per:profileId>') + 15);
            strProfileId = strProfileId.substring(0, 36);
            fac.Profile_Services_ID__c = strProfileId;
            String strOpration = result.substring(result.indexOf('<per:operation>') + 15);
            strOpration = strOpration.substring(0,9);
            String requestStr = '<soapenv:Envelope ' + soapEnv + tns +'><soapenv:Header/><soapenv:Body><tns:createStaffAccountRequest>';
            if(fac.Profile_Services_ID__c != null || fac.Profile_Services_ID__c != ''){
                requestStr +=  '<tns:profileId>' + fac.Profile_Services_ID__c + '</tns:profileId>';
            }
            if(fac.Username__c != null || fac.Username__c != ''){
                requestStr +=  '<tns:userName>' + fac.Username__c + '</tns:userName>';
            }
            requestStr +=  '<tns:createSISRecordInd>' + fac.Create_Banner_Record__c + '</tns:createSISRecordInd>';
            requestStr +=  '</tns:createStaffAccountRequest></soapenv:Body></soapenv:Envelope>';
            
            Http h = new Http();
            HttpRequest req = BPPIntegrationConfig.getData(requestStr);
            req.setTimeout(120000);
            system.debug('XML:' + requestStr);   
            system.debug(req.toString());
            HttpResponse res = null;
            if (Test.isRunningTest()){
                res = new HttpResponse();
                String strResponse = '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:ad="http://platform.apollogrp.edu/providers/apolloglobal/gds/v1" xmlns:v1="http://platform.apollogrp.edu/services/apolloglobal/person/PersonService"><soapenv:Header><gateway:transactionId xmlns:gateway="http://platform.apollogrp.edu/gateway">388901E5-4610-5209-AE01-ACCCD6D78980</gateway:transactionId></soapenv:Header><soapenv:Body><v1:createStaffAccountResponse><v1:userName>ramghul</v1:userName><v1:bannerId>ramghul</v1:bannerId><v1:password>Ja040981</v1:password><v1:emailAddress>ramghul@apollogrp.edu</v1:emailAddress><v1:alreadyProvisionedFor>NONE</v1:alreadyProvisionedFor></v1:createStaffAccountResponse></soapenv:Body></soapenv:Envelope>';
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
            if (result.indexOf('<v1:userName>') != -1) {
                String struserName = '';
                String strBannerId = '';
                String strpassword = '';
                String stremailAddress = '';
                String stralreadyProvisionedFor = '';
                Integer nEndIndex;
                nEndIndex = result.indexOf('</v1:userName>');
                struserName = result.substring(result.indexOf('<v1:userName>') + 13, nEndIndex);
                fac.Username__c = struserName;
                if (result.indexOf('<v1:bannerId>') != -1){
                    nEndIndex = result.indexOf('</v1:bannerId>');
                    strBannerId = result.substring(result.indexOf('<v1:bannerId>') + 13, nEndIndex);
                    fac.Banner_ID__c = strBannerId;
                }
                if (result.indexOf('<v1:password>') != -1){
                    nEndIndex = result.indexOf('</v1:password>');
                    strpassword = result.substring(result.indexOf('<v1:password>') + 13, nEndIndex);
                    fac.Password__c = strpassword;
                }
                if (result.indexOf('<v1:emailAddress>') != -1){
                    nEndIndex = result.indexOf('</v1:emailAddress>');
                    stremailAddress = result.substring(result.indexOf('<v1:emailAddress>') + 17, nEndIndex);
                    fac.Staff_Email_Add__c = stremailAddress.unescapexml();
                }
                if (result.indexOf('<v1:alreadyProvisionedFor>') != -1){
                    nEndIndex = result.indexOf('</v1:alreadyProvisionedFor>');
                    stralreadyProvisionedFor = result.substring(result.indexOf('<v1:alreadyProvisionedFor>') + 26, nEndIndex);
                    fac.Already_Provisioned_For__c = stralreadyProvisionedFor;
                }
                fac.RecordTypeId = fctRecTypeID;
                update fac;
                return 'Application Submitted Successfully';
            }
            else {
                fac.Last_Error__c = result;
                update fac;
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
        else {
            fac.Last_Error__c = result;
            update fac;
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
    public static String CreateSISStaffProvisioning(Faculty__c newFaculty) {
        
        Date dateOfBirth = newFaculty.Date_of_Birth__c;
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
            '    <tns:createUpdatePersonInfoRequest>' +
            '       <tns:profile>';
        if (dob != null && dob != ''){
            requestStr += '<prof:profileInformation><prof1:dateOfBirth>' + dob + '</prof1:dateOfBirth></prof:profileInformation>';
        }
        if (((newFaculty.Street_1__c != null) && (newFaculty.Street_1__c != '')) || ((newFaculty.Street_2__c != null) && (newFaculty.Street_2__c != '')) || ((newFaculty.Street_3__c != null) && (newFaculty.Street_3__c != '')) || ((newFaculty.Street_4__c != null) && (newFaculty.Street_4__c != '')) || ((newFaculty.City__c != null) && (newFaculty.City__c != '')) || (newFaculty.State_Province__c != null) || (newFaculty.Locality__c != null) || ((newFaculty.Postal_Code__c != null) && (newFaculty.Postal_Code__c != '')) || (newFaculty.Country__c != null)){
            requestStr += '<prof:address><add:type>Mailing</add:type>';
            if((newFaculty.Street_1__c != null) && (newFaculty.Street_1__c != '')){
                requestStr += '<add:line1>' + newFaculty.Street_1__c.escapeXML() + '</add:line1>';
            }
            if((newFaculty.Street_2__c != null) && (newFaculty.Street_2__c != '')){
                requestStr += '<add:line2>' + newFaculty.Street_2__c.escapeXML() + '</add:line2>';
            }
            if((newFaculty.Street_3__c != null) && (newFaculty.Street_3__c != '')){
                requestStr += '<add:line3>' + newFaculty.Street_3__c.escapeXML() + '</add:line3>';
            } 
            if((newFaculty.Street_4__c != null) && (newFaculty.Street_4__c != '')){
                requestStr += '<add:line4>' + newFaculty.Street_4__c.escapeXML() + '</add:line4>';
            } 
            if((newFaculty.City__c != null) && (newFaculty.City__c != '')){
                requestStr += '<add:city>' + newFaculty.City__c.escapeXML() + '</add:city>';
            } 
            if(newFaculty.State_Province__c != null){ 
                requestStr += '<add:stateProvince>' + newFaculty.State_Province__r.ISO_Code__c + '</add:stateProvince>'; 
            }
            if(newFaculty.Locality__c != null){
                requestStr += '<add:locality>' + newFaculty.Locality__r.Banner_Code__c + '</add:locality>';
            }
            if((newFaculty.Postal_Code__c != null) && (newFaculty.Postal_Code__c != '')){ 
                requestStr += '<add:postalCode>' + newFaculty.Postal_Code__c.escapeXML() + '</add:postalCode>';
            } 
            if(newFaculty.Country__c != null){ 
                requestStr += '<add:country>' + newFaculty.Country__r.ISO_Code__c + '</add:country>'; 
            }
            requestStr += '</prof:address>';
        }        
        if (newFaculty.Email__c != null && newFaculty.Email__c != ''){
            requestStr += '<prof:emailAddress><email:type>Personal</email:type><email:emailAddress>' + newFaculty.Email__c.escapeXML() + '</email:emailAddress><email:isPrimary>true</email:isPrimary></prof:emailAddress>';
        } 
        if (newFaculty.Middle_Name__c != null && newFaculty.Middle_Name__c != ''){ 
            requestStr += '<prof:name><nam:type>Legal</nam:type><nam:firstName>' + newFaculty.First_Name__c.escapeXML() + '</nam:firstName><nam:lastName>' + newFaculty.Last_Name__c.escapeXML() + '</nam:lastName><nam:middleName>' + newFaculty.Middle_Name__c.escapeXML() + '</nam:middleName><nam:primary>true</nam:primary></prof:name>';
        }
        else{
            requestStr += '<prof:name><nam:type>Legal</nam:type><nam:firstName>' + newFaculty.First_Name__c.escapeXML() + '</nam:firstName><nam:lastName>' + newFaculty.Last_Name__c.escapeXML() + '</nam:lastName><nam:primary>true</nam:primary></prof:name>';
        }
        system.debug('Phone: ' + newFaculty.Phone__c);
        String homePhone = String.valueOf(Faculty__c.Phone__c);
        requestStr += BuildPhone.BuildPhoneXml(newFaculty.Phone__c, 'Home', true);
        requestStr += '<prof:affiliation><prof:value>'+newFaculty.Role__c+'</prof:value></prof:affiliation>' +  //STAFF       
            '        </tns:profile>' +
            '    </tns:createUpdatePersonInfoRequest>' + 
            '</soapenv:Body></soapenv:Envelope>';
        
        Http h = new Http();
        HttpRequest req = BPPIntegrationConfig.getData(requestStr);
        req.setTimeout(120000);
        system.debug('XML:' + requestStr);   
        system.debug(req.toString());
        HttpResponse res = null;
        if (Test.isRunningTest()){
            res = new HttpResponse();
            if (bFailFaculty){
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
            }
            else{
                String strResponse = '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:per="http://platform.apollogrp.edu/services/apolloglobal/person/PersonService"><soapenv:Header><gateway:transactionId xmlns:gateway="http://platform.apollogrp.edu/gateway">440E5141-DDC8-DFF7-C274-4DEC1EA546C6</gateway:transactionId></soapenv:Header><soapenv:Body><per:createUpdatePersonInfoResponse><per:profileId>6f22737d-8107-4d0a-94ec-ed18fc99198e</per:profileId><per:operation>INSERT</per:operation></per:createUpdatePersonInfoResponse></soapenv:Body></soapenv:Envelope>';
                res.setStatusCode(200);
                res.setStatus('OK');
                res.setBody(strResponse);
            }
        }
        else{
            res = h.send(req);
        }
        system.debug(res.getStatus());
        system.debug(res.getBody());
        
        String result = res.getBody();
        
        if (result.indexOf('<per:profileId>') != -1) {
            return result;
        }
        else{
            return result;
        }
    }
    
    @isTest
    private static void unitTest1() {
        Test.startTest();
        country_list__c cntry = new country_list__c(Name = 'Unit Test', ISO_Code__c = '123', country_code_2__c = '12');
        insert cntry;
        State_Province__c stt = new State_Province__c(Name = 'Unit Test', ISO_Code__c = '123');
        insert stt;
        Locality__c lct = new Locality__c(Name = 'Unit Test', Banner_Code__c = '123');
        insert lct;
        
        Faculty__c f;
        f = new Faculty__c();
        f.First_Name__c='John';
        f.Last_Name__c='Coppedge';
        f.Middle_Name__c = 'Jem';
        f.RecordTypeId=Schema.sObjectType.Faculty__c.getRecordTypeInfosByName().get('Faculty').getRecordTypeId();
        f.Email__c='john@john.com';
        f.Phone__c='8015555556';
        f.Date_of_Birth__c=Date.valueOf('1985-02-27');
        f.Role__c = 'FACULTY';
        f.Street_1__c = '120 Test Dr';
        f.Street_2__c = '120';
        f.Street_3__c = '12';
        f.Street_4__c = '1';
        f.City__c = 'Mexico City';
        f.Country__c = cntry.Id;
        f.State_Province__c = stt.Id;
        f.Locality__c = lct.Id;
        f.Postal_Code__c = '11067';
        insert f;
        String fctid = f.Id;
        PersonIntegrations.PersonInt(fctid);
        
        f = new Faculty__c();
        f.First_Name__c='John';
        f.Last_Name__c='Coppedge';
        f.RecordTypeId=Schema.sObjectType.Faculty__c.getRecordTypeInfosByName().get('Faculty').getRecordTypeId();
        f.Email__c='john@john.com';
        f.Phone__c='8015555556123';
        f.Date_of_Birth__c=Date.valueOf('1985-12-01');
        f.Role__c = 'FACULTY';
        f.Street_1__c = '120 Test Dr';
        f.Street_2__c = '120';
        f.Street_3__c = '12';
        f.Street_4__c = '1';
        f.City__c = 'Mexico City';
        f.Country__c = cntry.Id;
        f.State_Province__c = stt.Id;
        f.Postal_Code__c = '11067';
        f.Locality__c = lct.Id;
        insert f;
        String fct1id = f.Id;
        PersonIntegrations.PersonInt(fct1id);
        
        f = new Faculty__c();
        f.First_Name__c='John';
        f.Last_Name__c='Coppedge';
        f.Middle_Name__c = 'J';
        f.RecordTypeId=Schema.sObjectType.Faculty__c.getRecordTypeInfosByName().get('Faculty').getRecordTypeId();
        f.Email__c='john@john.com';
        f.Phone__c='801555';
        f.Date_of_Birth__c=Date.valueOf('1985-01-21');
        f.Role__c = 'STAFF';
        f.Street_1__c = '120 Test Dr';
        f.Street_2__c = '120';
        f.Street_3__c = '12';
        f.Street_4__c = '1';
        f.City__c = 'Mexico City';
        f.Country__c = cntry.Id;
        f.State_Province__c = stt.Id;
        f.Locality__c = lct.Id;
        f.Postal_Code__c = '11067';
        insert f;
        String fct2id = f.Id;
        PersonIntegrations.PersonInt(fct2id);
        
        f = new Faculty__c();
        f.First_Name__c='John';
        f.Last_Name__c='Coppedge';
        f.RecordTypeId=Schema.sObjectType.Faculty__c.getRecordTypeInfosByName().get('Faculty').getRecordTypeId();
        f.Email__c='john@john.com';
        f.Phone__c='801555';
        f.Date_of_Birth__c=Date.valueOf('1985-12-01');
        f.Role__c = 'STAFF';
        f.Street_1__c = '120 Test Dr';
        f.Street_2__c = '120';
        f.Street_3__c = '12';
        f.Street_4__c = '1';
        f.City__c = 'Mexico City';
        f.Country__c = cntry.Id;
        f.State_Province__c = stt.Id;
        f.Locality__c = lct.Id;
        f.Postal_Code__c = '11067';
        insert f;
        String fct3id = f.Id;
        PersonIntegrations.PersonInt(fct3id);
        test.stoptest();
    }
    
    @isTest
    private static void unitTest2() {
        country_list__c cntry = new country_list__c(Name = 'Unit Test', ISO_Code__c = '123', country_code_2__c = '12');
        insert cntry;
        State_Province__c stt = new State_Province__c(Name = 'Unit Test', ISO_Code__c = '123');
        insert stt;
        Locality__c lct = new Locality__c(Name = 'Unit Test', Banner_Code__c = '123');
        insert lct;
        
        Faculty__c f;
        f = new Faculty__c();
        f.First_Name__c='John';
        f.Last_Name__c='Coppedge';
        f.Middle_Name__c = 'Jem';
        f.RecordTypeId=Schema.sObjectType.Faculty__c.getRecordTypeInfosByName().get('Faculty').getRecordTypeId();
        f.Email__c='john@john.com';
        f.Phone__c='8015555556';
        f.Date_of_Birth__c=Date.valueOf('1985-02-27');
        f.Role__c = 'FACULTY';
        f.Street_1__c = '120 Test Dr';
        f.Street_2__c = '120';
        f.Street_3__c = '12';
        f.Street_4__c = '1';
        f.City__c = 'Mexico City';
        f.Country__c = cntry.Id;
        f.State_Province__c = stt.Id;
        f.Locality__c = lct.Id;
        f.Postal_Code__c = '11067';
        insert f;
        String fctid = f.Id;
        PersonIntegrations.bFailFaculty = true;
        PersonIntegrations.PersonInt(fctid);
    }
    
    @isTest
    private static void unitTest3() {
        country_list__c cntry = new country_list__c(Name = 'Unit Test', ISO_Code__c = '123', country_code_2__c = '12');
        insert cntry;
        State_Province__c stt = new State_Province__c(Name = 'Unit Test', ISO_Code__c = '123');
        insert stt;
        Locality__c lct = new Locality__c(Name = 'Unit Test', Banner_Code__c = '123');
        insert lct;
        
        Faculty__c f;
        f = new Faculty__c();
        f.First_Name__c='John';
        f.Last_Name__c='Coppedge';
        f.Middle_Name__c = 'Jem';
        f.RecordTypeId=Schema.sObjectType.Faculty__c.getRecordTypeInfosByName().get('Faculty').getRecordTypeId();
        f.Email__c='john@john.com';
        f.Phone__c='8015555556';
        f.Date_of_Birth__c=Date.valueOf('1985-02-27');
        f.Role__c = 'STAFF';
        f.Street_1__c = '120 Test Dr';
        f.Street_2__c = '120';
        f.Street_3__c = '12';
        f.Street_4__c = '1';
        f.City__c = 'Mexico City';
        f.Country__c = cntry.Id;
        f.State_Province__c = stt.Id;
        f.Locality__c = lct.Id;
        f.Postal_Code__c = '11067';
        insert f;
        String fctid = f.Id;
        PersonIntegrations.bFailFaculty = true;
        PersonIntegrations.PersonInt(fctid);
    }
}