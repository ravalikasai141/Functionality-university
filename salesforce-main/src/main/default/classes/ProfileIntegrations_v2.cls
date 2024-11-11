global with sharing class ProfileIntegrations_v2{
    public static string endPoint_findmatch = '/rest/profile/v2/findProfiles';
    public static string endPoint_insert = '/rest/profile/v2/insertProfile';
    public static string endPoint_update = '/rest/profile/v2/updateProfile';
    
    public static Boolean bFailSIS = false;
    
    WebService static String ProfileInt_v2(String accountId){
        String result;
        
        String query = Util.getAllFieldsSOQL('Account', 'Id = \'' + accountId + '\'');
        Account acc = Database.query(query);
        
        Account acct  = [Select Id, Primary_Nationality__pc, Primary_Nationality__pr.ISO_CODE__c 
                        From Account Where Id =: acc.Id Limit 1];
        if(acc.Primary_Nationality__pc != null){
            acc.Primary_Nationality__pc = acct.Primary_Nationality__pc;
            acc.Primary_Nationality__pr = acct.Primary_Nationality__pr;
            acc.Primary_Nationality__pr.ISO_Code__c = acct.Primary_Nationality__pr.ISO_Code__c;
        }
        
        String strRet = CreatePersonInfo_v2(acc);
        result = strRet;
        
        if(result == 'error code [20002]'){
            return 'Error: Minimum information for profile creation not available.  Minimum 3 fields are required out of: Name [First and Last],Date Of Birth,Postal code [Home,Mailing and Work], Email [Home,Personal and Work], Phone';
        }
        else         
          return result;
  }
    
    //for findMatch****************************
    public class findProfileRequest {
        public find_profileTypeInfo findProfilesRequest = new find_profileTypeInfo();
    }
    
    public class find_profileTypeInfo {
        public find_profileType findProfile = new find_profileType();
    }
    
    public class find_profileType {
      public List<find_NameType> name = new List<find_NameType>(); 
        public string dateOfBirth = '';
        public List<find_AddressType> address = new List<find_AddressType>();
    public List<find_EmailType> emailAddress = new List<find_EmailType>();  
        public List<find_PhoneType> phone = new List<find_PhoneType>();  
  }
       
    public class find_NameType {
      public string type = '';
        public string firstName = '';
        public string lastName = '';
    }
    
    public class find_AddressType {
        public string type = '';
        public string postalCode = '';
    }
    
    public class find_EmailType {
        public string type = '';
        public string emailAddress = '';
    }
    
    public class find_PhoneType {
        public string type = '';
        public string areaCode = '';
        public string phoneNumber = '';
        public string countryCode = '';
    }
    //********************************************
    
    //for insertProfile***************************
    public class insertProfileRequest {
        public profileTypeInfo insertProfileRequest = new profileTypeInfo();
    }
    
    public class profileTypeInfo {
        public profileType profile = new profileType();
    }
        
    public class profileType {        
        public bioType bio = new bioType();
        public familyInformationType familyInformation = new familyInformationType(); 
        public profileInformationType profileInformation = new profileInformationType();
        public List<inst_AddressType> address = new List<inst_AddressType>();
        public List<inst_EmailType> emailAddress = new List<inst_EmailType>(); 
        public List<inst_NameType> name = new List<inst_NameType>(); 
        public List<inst_PhoneType> phone = new List<inst_PhoneType>(); 
        public List<PictureType> picture = new List<PictureType>(); 
        public citizenshipType citizenship = new citizenshipType();
        public List<socialNetworkType> socialNetwork = new List<socialNetworkType>(); 
        public List<socialEmploymentType> socialEmployment = new List<socialEmploymentType>();
        public List<socialEducationCredentialType> socialEducationCredential = new List<socialEducationCredentialType>();
        public List<personalMarkerType> personalMarker = new List<personalMarkerType>();
        public identityBlockDTO identityBlock = new identityBlockDTO();
        public List<affiliationType> affiliation = new List<affiliationType>();
        public nationalityDetailsType nationalityDetails = new nationalityDetailsType();
    }
    
  public class bioType {
        public string value = '';
    }
    
    public class familyInformationType {
        public string value = '';
    }
    
    public class profileInformationType {
        public List<inst_extensionfieldType> extensionfield = new List<inst_extensionfieldType>(); 
        public string dateOfBirth = '';
        public string gender;
        public string highestLevelOfEducation = '';
        public string hasForeignCredits = '';
        public string learningformat = '';
        public string maritalStatus = '';
        public string statusMessage = '';
        public string ethnicity;
        public string localEthnicityRace = '';
        public string vatNumber = '';
        public string studentTaxStatus = '';
    }
    
    public class inst_extensionfieldType {
      public string key = '';
        public string value = '';
    }
    
  public class inst_AddressType {
        public string type = '';
        public string line1 = '';
        public string line2 = '';
        public string line3 = '';
        public string line4 = '';
        public string city = '';
        public string stateProvince = '';
        public string postalCode = '';
        public string country = '';
        public boolean isPrimary = false;
        public boolean isCertified = false;
    }
    
    public class inst_EmailType {
        public string type = '';
        public string emailAddress = '';
        public boolean suppressed = false;
        public string suppressionDate = '';
        public boolean isPrimary = false;
    }
    
    public class inst_NameType {
      public string type = '';
        public string firstName = '';
        public string lastName = '';
        public string middleName = '';
        public string prefix = '';
        public string suffix = '';
        public string preferredName = '';
        public boolean primary = false;
    }
    
    public class inst_PhoneType {
        public string type = '';
        public string areaCode = '';
        public string phoneNumber = '';
        public string extension = '';
        public string countryCode = '';
        public boolean isPrimary = false;
    }
    
    public class pictureType {
        public string type = '';
        public string mimeType = '';
        public string pictureSize = '';
        public string pictureLocator = '';
    }
  
    public class citizenshipType {
        public string country = 'GBR';
        public string status = 'Citizen';
    }
    
    public class socialNetworkType {
        public string type = '';
        public string userId = '';
    }
    
    public class socialEmploymentType {
        public string employerName = '';
        public string title = '';
        public string startDate = '';
        public string endDate = '';
        public string industry = '';
        public boolean isCurrent = false;
    }
    
    public class socialEducationCredentialType {
      public string institution = '';
        public string areaOfStudy = '';
        public string degree = '';
        public string startDate = '';
        public string endDate = '';
    }
    
    public class personalMarkerType {
      public string category = '';
        public string type = '';
        public string text = '';
    }
    
    public class identityBlockDTO {
        List<IdentityType> identityType = new List<IdentityType>();
    }
    
    public class IdentityType {
        public string type = '';
        public string value = '';
    }
    
    public class affiliationType {
      public string value = '';
    }
    
    public class nationalityDetailsType {
        public string nationalityStatus = '';
    }
    //********************************************
    
    //for updateProfile***************************
    public class updateProfileRequest {
        public update_profileTypeInfo updateProfileRequest = new update_profileTypeInfo();
    }
    
    public class update_profileTypeInfo {
        public update_profileType profile = new update_profileType();
        public deleteEntityDTO deleteEntity = new deleteEntityDTO();
    }
    
    public class update_profileType {
        public string profileId = '';
        public update_bioType bio = new update_bioType();
        public update_familyInformationType familyInformation = new update_familyInformationType(); 
        public update_profileInformationType profileInformation = new update_profileInformationType();
        public List<update_AddressType> address = new List<update_AddressType>();
        public List<update_EmailType> emailAddress = new List<update_EmailType>(); 
        public List<update_NameType> name = new List<update_NameType>(); 
        public List<inst_PhoneType> phone = new List<inst_PhoneType>(); 
        public List<update_pictureType> picture = new List<update_pictureType>(); 
        public update_citizenshipType citizenship = new update_citizenshipType();
        public List<update_socialNetworkType> socialNetwork = new List<update_socialNetworkType>(); 
        public List<update_personalMarkerType> personalMarker = new List<update_personalMarkerType>();
        public update_nationalityDetailsType nationalityDetails = new update_nationalityDetailsType();
        public update_identityBlockDTO identityBlock = new update_identityBlockDTO();
        public List<update_affiliationType> affiliation = new List<update_affiliationType>();
    }
    
  public class update_bioType {
        public string value = '';
    }
    
    public class update_familyInformationType {
        public string value = '';
    }
    
    public class update_profileInformationType {
        public List<extensionfieldType> extensionfield = new List<extensionfieldType>(); 
        public string dateOfBirth = '';
        public string gender;
        public string hasForeignCredits = '';
        public string ethnicity;
        public List<profileStudentInstitutionType> profileStudentInstitution = new List<profileStudentInstitutionType>(); 
        public string vatNumber = '';
        public string studentTaxStatus = '';
    }
        
    public class extensionfieldType {
        public string key = '';
        public string value = '';
    }
    
    public class profileStudentInstitutionType {
        public string SIN = '';
        public string ExaminingBody = '';
    }
    
  public class update_AddressType {
        public string type = '';
        public string line1 = '';
        public string line2 = '';
        public string line3 = '';
        public string line4 = '';
        public string city = '';
        public string stateProvince = '';
        public string postalCode = '';
        public string country = '';
        public boolean isPrimary = false;
    }
    
    public class update_EmailType {
        public string type = '';
        public string emailAddress = '';
        public boolean isPrimary = false;
    }
    
    public class update_NameType {
      public string type = '';
        public string firstName = '';
        public string lastName = '';
        public string middleName = '';
        public string prefix = '';
        public string suffix = '';
        public string preferredName = '';
        public boolean primary = false;
    }
    
    public class update_pictureType {
        public string type = '';
        public string mimeType = '';
        public string pictureSize = '';
        public string pictureLocator = '';
    }
  
    public class update_citizenshipType {
        public string country = 'GBR';
        public string status = 'Citizen';
    }
    
    public class update_socialNetworkType {
        public string type = '';
        public string userId = '';
    }
    
    public class update_personalMarkerType {
      public string category = '';
        public string type = '';
        public string text = '';
    }
    
    public class update_nationalityDetailsType {
      public string nationalityStatus = '';
    }
    
    public class update_identityBlockDTO {
        List<update_IdentityType> identityType = new List<update_IdentityType>();
    }
    
    public class update_IdentityType {
        public string type = '';
        public string value = '';
    }
    
    public class update_affiliationType {
      public string value = '';
    }
   
    public class deleteEntityDTO {
        List<entityToDeleteType> entityToDelete = new List<entityToDeleteType>();
    }
    
    public class entityToDeleteType {
        public string entityName = '';
        List<string> entityType = new List<string>();
    }
    //********************************************
    
    
    public static String CreatePersonInfo_v2(Account acc){
        string result;
        if (acc != null){
            findProfileRequest fpr = new findProfileRequest();
            
            fpr.findProfilesRequest.findProfile.name = new List<find_NameType>();
            find_NameType fnt = new find_NameType();
            if ((acc.LastName != null && acc.LastName != '') || (acc.FirstName != null && acc.FirstName != '')){ 
                fnt.lastName = acc.LastName;
                if (acc.FirstName != null && acc.FirstName != ''){
                    fnt.firstName = acc.FirstName;
                }
                fnt.type = 'Legal';
                fpr.findProfilesRequest.findProfile.name.add(fnt);      
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
                fpr.findProfilesRequest.findProfile.dateOfBirth = dob;
            }
            
            list<Address__c> find_addresses = [Select Id, Type__c, Primary__c, Street_1__c, Street_2__c, Street_3__c, Street_4__c, City__c, State_Province__c, State_Province__r.ISO_Code__c, Locality__c, Locality__r.Banner_Code__c, Zip_Postal_Code__c, Lookup_Country__c, Lookup_Country__r.ISO_CODE__c,  Active__c From Address__c Where Student__c =: acc.Id];
            if (find_addresses.size() != 0){
                fpr.findProfilesRequest.findProfile.address = new List<find_AddressType>();
                for (Address__c addr : find_addresses){
                    find_AddressType adr = new find_AddressType();
                    if (addr.Type__c != null && addr.Type__c != ''){
                        if(addr.Type__c == 'Next of Kin/Emergency/Guardian'){
                            adr.type = 'Parent';
                        }
                        else{
                            adr.type = addr.Type__c;
                        }
                    }
                    if (addr.Zip_Postal_Code__c != null && addr.Zip_Postal_Code__c != ''){
                        adr.postalCode = addr.Zip_Postal_Code__c;
                    }
                    fpr.findProfilesRequest.findProfile.address.add(adr);
                }
            }
            
            fpr.findProfilesRequest.findProfile.emailAddress = new List<find_EmailType>();
            if(acc.Personal_Email__pc != null){
              find_EmailType fet = new find_EmailType();
                fet.type = 'Personal';
                fet.emailAddress = acc.Personal_Email__pc;
                fpr.findProfilesRequest.findProfile.emailAddress.add(fet);
            }
            if(acc.Work_Email__pc != null){
              find_EmailType fet = new find_EmailType();
                fet.type = 'Work';
                fet.emailAddress = acc.Work_Email__pc;
                fpr.findProfilesRequest.findProfile.emailAddress.add(fet);
            }    
            if(acc.BPP_Email__pc != null){
                find_EmailType fet = new find_EmailType();
                fet.type = 'BPP';
                fet.emailAddress = acc.BPP_Email__pc;
                fpr.findProfilesRequest.findProfile.emailAddress.add(fet);
            } 
            if(acc.Other_Email__pc != null){
                find_EmailType fet = new find_EmailType();
                fet.type = 'Other';
                fet.emailAddress = acc.Other_Email__pc;
                fpr.findProfilesRequest.findProfile.emailAddress.add(fet);
            }    
            if(acc.Billing_Email__pc  != null){
                find_EmailType fet = new find_EmailType();
                fet.type = 'Billing';
                fet.emailAddress = acc.Billing_Email__pc ;
                fpr.findProfilesRequest.findProfile.emailAddress.add(fet);
            }    
            
            fpr.findProfilesRequest.findProfile.phone = new List<find_PhoneType>();   
            if(acc.personHomePhone != null){
              find_PhoneType fpt = BuildPhone.findBuildPhoneTypeDTO(acc.personHomePhone, 'Home');
                fpr.findProfilesRequest.findProfile.phone.add(fpt); 
            }
            if(acc.personMobilePhone != null){
                find_PhoneType fpt = BuildPhone.findBuildPhoneTypeDTO(acc.personMobilePhone, 'Mobile');
                fpr.findProfilesRequest.findProfile.phone.add(fpt); 
            }
            if(acc.Work_Phone__pc != null){
                find_PhoneType fpt = BuildPhone.findBuildPhoneTypeDTO(acc.Work_Phone__pc, 'Business');
                fpr.findProfilesRequest.findProfile.phone.add(fpt); 
            }
            if(acc.Parents_Guardian_Emergency_Phone__pc != null){
                find_PhoneType fpt = BuildPhone.findBuildPhoneTypeDTO(acc.Parents_Guardian_Emergency_Phone__pc, 'Parent');
                fpr.findProfilesRequest.findProfile.phone.add(fpt); 
            }
            if(acc.Fax != null){
                find_PhoneType fpt = BuildPhone.findBuildPhoneTypeDTO(acc.Fax, 'Fax');
                fpr.findProfilesRequest.findProfile.phone.add(fpt); 
            }
                        
           
            String jsonRequest = JSON.serialize(fpr);
            system.debug(jsonRequest +'Company Profile');
            Http http = new Http();
            //HttpRequest req = BPPIntegrationConfig.callRestService(jsonRequest, 'application/json', endPoint);
            HttpRequest req = BPPIntegrationConfig.callRestService(jsonRequest, 'application/json', endPoint_findmatch);
            
            system.debug('Test Final Find JSON: ' + req.getMethod() + ' ' + req.getEndPoint() + 'Accept-Encoding:' + req.getHeader('Accept-Encoding') +'Accept:' + req.getHeader('Accept') + 'Content-Type:' + req.getHeader('Content-Type') + 'tenantId:' + req.getHeader('tenantId') + req.getBody());
            system.debug(req.toString());
            HttpResponse res = null;
            if (Test.isRunningTest()){
                res = new HttpResponse();
                if (bFailSIS){
                    String strResponse = '{"companyId":"1234f567-bc23-42e8-924c-1234asdf5678","operation":"UPDATE"}';
                    res.setStatusCode(200);
                    res.setStatus('OK');
                    res.setBody(strResponse);
                }
                else{
                    //String strResponse = '{"self":"null","httpMethod":"DELETE","errorMessage":"Cannot find Company or Profile Record for the specified Id: 1231231231","errorCode":"PLATFORM-801","transactionId":"A563C5CD-4CA9-B1C6-392A-09377720BFAC"}';
                    String strResponse = '{"findProfilesResponse":{"result":null}}';                    
                    res.setStatusCode(200);
                    //res.setStatus('Internal Error');
                    res.setStatus('OK');
                    res.setBody(strResponse);
                }
            }
            else{
                res = http.send(req);
            }
            system.debug('Test Response:' + res.getBody());
            system.debug('Test Response:' + res.getStatus());
            
            /* Integration Log */
            Integration_Log__c intg = new Integration_Log__c();
            intg.Request__c =  jsonRequest;
            intg.Response__c = res.getBody();
            intg.Salesforce_ID__c = acc.Id;
            intg.Integration_Type__c = 'Find Matching Student';
                      
            String studentProfileId;
            String ErrorDescription;
            if (res.getStatus() == 'OK' && res.getStatusCode() == 200){
                //resp is a JSON string
                JSONParser parser = JSON.createParser(res.getBody());
                while (parser.nextToken() != null) {
                    if ((parser.getCurrentToken() == JSONToken.FIELD_NAME)){
                        String fieldName = parser.getText();
                        parser.nextToken();
                        if(fieldName == 'profileId') {
                            studentProfileId = parser.getText();
                            system.debug('studentProfileId' + studentProfileId);
                            result = 'Success';
                            break;
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
                
                List<Lead> existingLead = [select id, Name, PS_Profile_Services_ID__c from Lead where PS_Profile_Services_ID__c =: studentProfileId and PS_Profile_Services_ID__c != null and IsConverted = false];               
                List<Account> existingAccount = [Select id, Name, PS_Profile_Services_ID__pc from Account where PS_Profile_Services_ID__pc =: studentProfileId and PS_Profile_Services_ID__pc != null];
                
                if(existingLead.size()>0)
                    result = 'Potential duplicate student lead record found. Check existing lead:\n\n'+ existingLead[0].Name + ' (' + existingLead[0].PS_Profile_Services_ID__c + ')';                
        
                else if(existingAccount.size()>0)
                    result = 'Potential duplicate student account record found. Check existing account:\n\n'+ existingAccount[0].Name + ' (' + existingAccount[0].PS_Profile_Services_ID__pc + ')';                
                     
                else if (parser.nextToken() == null) {
                    //insert new student account in profile 
                  insertProfileRequest ipr = new insertProfileRequest();
                    
                    if(acc.AR_Student_Finance_England_SFE__c != null && acc.AR_Student_Finance_England_SFE__c != ''){ 
                    ipr.insertProfileRequest.profile.profileInformation.extensionfield = new List<inst_extensionfieldType>();
                    inst_extensionfieldType inst_eft = new inst_extensionfieldType();
                    inst_eft.key = 'STUDENT_FINANCE_ID';
                    inst_eft.value = acc.AR_Student_Finance_England_SFE__c;
                    ipr.insertProfileRequest.profile.profileInformation.extensionfield.add(inst_eft);      
                }
                    if (dob != null && dob != ''){
                        ipr.insertProfileRequest.profile.profileInformation.dateOfBirth = dob;
                    }
                    
                    String gender = acc.Gender__pc;
                    String gender_passed;
                    if (gender != null){
                        if (gender == 'Male')
                            gender_passed = 'M';
                        else if (gender == 'Female')
                            gender_passed = 'F';
                    }
                    ipr.insertProfileRequest.profile.profileInformation.gender = gender_passed;
                    
                    if(acc.SFDC_Ethnic_Code_Select__pc != null && acc.SFDC_Ethnic_Code_Select__pc != ''){
    					String ethnicityCode = BNR_SubmitApplication.ExtractCode(acc.SFDC_Ethnic_Code_Select__pc);
    					if(ethnicityCode != null && ethnicityCode.length() == 2){
        					ipr.insertProfileRequest.profile.profileInformation.ethnicity = ethnicityCode;
    					}
					} 
                    
                    if (acc.VAT_Code__pc != null && acc.VAT_Code__pc != ''){
                        ipr.insertProfileRequest.profile.profileInformation.vatNumber = acc.VAT_Code__pc;
                    }
                    
                    list<Address__c> addresses = [Select Id, Type__c, Primary__c, Street_1__c, Street_2__c, Street_3__c, Street_4__c, City__c, State_Province__c, State_Province__r.ISO_Code__c, Locality__c, Locality__r.Banner_Code__c, Zip_Postal_Code__c, Lookup_Country__c, Lookup_Country__r.ISO_CODE__c,  Active__c From Address__c Where Student__c =: acc.Id];
                    if (addresses.size() != 0){
                        ipr.insertProfileRequest.profile.address = new List<inst_AddressType>();
                        for (Address__c addr : addresses){
                            inst_AddressType adr = new inst_AddressType();
                            if (addr.Type__c != null && addr.Type__c != ''){
                                if(addr.Type__c == 'Next of Kin/Emergency/Guardian'){
                                    adr.type = 'Parent';
                                }
                                else{
                                    adr.type = addr.Type__c;
                                }
                            }
                            if (addr.Street_1__c != null && addr.Street_1__c != ''){
                                adr.line1 = addr.Street_1__c;
                            }
                            if (addr.Street_2__c != null && addr.Street_2__c != ''){
                                adr.line2 = addr.Street_2__c;
                            }
                            if (addr.Street_3__c != null && addr.Street_3__c != ''){
                                adr.line3 = addr.Street_3__c;
                            }
                            if (addr.Street_4__c != null && addr.Street_4__c != ''){
                                adr.line4 = addr.Street_4__c;
                            }
                            if (addr.City__c != null && addr.City__c != ''){
                                adr.city = addr.City__c;
                            }
                            if (addr.State_Province__c != null && addr.State_Province__r.ISO_CODE__c != null && 
                                addr.State_Province__r.ISO_CODE__c != ''){
                                adr.stateProvince = addr.State_Province__r.ISO_CODE__c;
                            }
                            if (addr.Zip_Postal_Code__c != null && addr.Zip_Postal_Code__c != ''){
                                adr.postalCode = addr.Zip_Postal_Code__c;
                            }
                            if (addr.Lookup_Country__c != null && addr.Lookup_Country__r.ISO_CODE__c != null && 
                                addr.Lookup_Country__r.ISO_CODE__c != ''){
                                adr.country = addr.Lookup_Country__r.ISO_CODE__c;
                            }
                            adr.isPrimary = addr.Primary__c;
                            adr.isCertified = addr.Primary__c;
                            
                            ipr.insertProfileRequest.profile.address.add(adr);
                        }
                    }
                                        
                    ipr.insertProfileRequest.profile.emailAddress = new List<inst_EmailType>();
                    if(acc.Personal_Email__pc != null){
                      if(acc.Preferred_Email__pc == 'Personal'){
                            inst_EmailType iet = new inst_EmailType();
                            iet.type = 'Personal';
                            iet.emailAddress = acc.Personal_Email__pc;
                            iet.isPrimary = true;
                            ipr.insertProfileRequest.profile.emailAddress.add(iet);
                        }
                        else {
                            inst_EmailType iet = new inst_EmailType();
                            iet.type = 'Personal';
                            iet.emailAddress = acc.Personal_Email__pc;
                            iet.isPrimary = false;
                            ipr.insertProfileRequest.profile.emailAddress.add(iet); 
                        }
                    }
                    if(acc.Work_Email__pc != null){
                      if(acc.Preferred_Email__pc == 'Work'){
                            inst_EmailType iet = new inst_EmailType();
                            iet.type = 'Work';
                            iet.emailAddress = acc.Work_Email__pc;
                            iet.isPrimary = true;
                            ipr.insertProfileRequest.profile.emailAddress.add(iet);
                        }
                        else {
                            inst_EmailType iet = new inst_EmailType();
                            iet.type = 'Work';
                            iet.emailAddress = acc.Work_Email__pc;
                            iet.isPrimary = false;
                            ipr.insertProfileRequest.profile.emailAddress.add(iet); 
                        }
                    }    
                    if(acc.BPP_Email__pc != null){
                      if(acc.Preferred_Email__pc == 'BPP'){
                            inst_EmailType iet = new inst_EmailType();
                            iet.type = 'BPP';
                            iet.emailAddress = acc.BPP_Email__pc;
                            iet.isPrimary = true;
                            ipr.insertProfileRequest.profile.emailAddress.add(iet);
                        }
                        else {
                            inst_EmailType iet = new inst_EmailType();
                            iet.type = 'BPP';
                            iet.emailAddress = acc.BPP_Email__pc;
                            iet.isPrimary = false;
                            ipr.insertProfileRequest.profile.emailAddress.add(iet); 
                        }
                    }    
                    if(acc.Other_Email__pc != null){
                      if(acc.Preferred_Email__pc == 'Other'){
                            inst_EmailType iet = new inst_EmailType();
                            iet.type = 'Other';
                            iet.emailAddress = acc.Other_Email__pc;
                            iet.isPrimary = true;
                            ipr.insertProfileRequest.profile.emailAddress.add(iet);
                        }
                        else {
                            inst_EmailType iet = new inst_EmailType();
                            iet.type = 'Other';
                            iet.emailAddress = acc.Other_Email__pc;
                            iet.isPrimary = false;
                            ipr.insertProfileRequest.profile.emailAddress.add(iet); 
                        }
                    }    
                    if(acc.Billing_Email__pc  != null){
                      if(acc.Preferred_Email__pc == 'Billing'){
                            inst_EmailType iet = new inst_EmailType();
                            iet.type = 'Billing';
                            iet.emailAddress = acc.Billing_Email__pc ;
                            iet.isPrimary = true;
                            ipr.insertProfileRequest.profile.emailAddress.add(iet);
                        }
                        else {
                            inst_EmailType iet = new inst_EmailType();
                            iet.type = 'Billing';
                            iet.emailAddress = acc.Billing_Email__pc ;
                            iet.isPrimary = false;
                            ipr.insertProfileRequest.profile.emailAddress.add(iet); 
                        }
                    }    
                    
                    ipr.insertProfileRequest.profile.name = new List<inst_NameType>();
                    inst_NameType nt = new inst_NameType();
                    if ((acc.LastName != null && acc.LastName != '') || (acc.FirstName != null && acc.FirstName != '')){ 
                  nt.lastName = acc.LastName;
                        if (acc.FirstName != null && acc.FirstName != ''){
                          nt.firstName = acc.FirstName;
                        }
                        if (acc.Middle_Name__pc != null && acc.Middle_Name__pc != ''){
                          nt.middleName = acc.Middle_Name__pc;
                        }
                        if (acc.Salutation != null && acc.Salutation != ''){
                             nt.prefix = acc.Salutation;
                        }
                        if (acc.AA_Suffix__pc != null && acc.AA_Suffix__pc != ''){
                             nt.suffix = acc.AA_Suffix__pc;
                        }
                        if (acc.Preferred_First_Name__pc != null && acc.Preferred_First_Name__pc != ''){
                          nt.preferredName = acc.Preferred_First_Name__pc;
                        }
                        nt.type = 'Legal';
                        nt.Primary = true;
                        
                        ipr.insertProfileRequest.profile.name.add(nt);      
                  }
                    
          ipr.insertProfileRequest.profile.phone = new List<inst_PhoneType>();   
                if(acc.personHomePhone != null){
                      if(acc.Preferred_Phone__pc == 'Home'){  
                            inst_PhoneType ipt = BuildPhone.InstBuildPhoneTypeDTO(acc.personHomePhone, 'Home', true);
                            ipr.insertProfileRequest.profile.phone.add(ipt); 
                        }
                        else{
                          inst_PhoneType ipt = BuildPhone.InstBuildPhoneTypeDTO(acc.personHomePhone, 'Home', false);
                            ipr.insertProfileRequest.profile.phone.add(ipt);     
                        }
                }
                    if(acc.personMobilePhone != null){
                      if(acc.Preferred_Phone__pc == 'Mobile'){
                            inst_PhoneType ipt = BuildPhone.InstBuildPhoneTypeDTO(acc.personMobilePhone, 'Mobile', true);
                            ipr.insertProfileRequest.profile.phone.add(ipt); 
                        }
                        else{
                          inst_PhoneType ipt = BuildPhone.InstBuildPhoneTypeDTO(acc.personMobilePhone, 'Mobile', false);
                            ipr.insertProfileRequest.profile.phone.add(ipt);     
                        }
                }
                    if(acc.Work_Phone__pc != null){
                      if(acc.Preferred_Phone__pc == 'Work'){
                            inst_PhoneType ipt = BuildPhone.InstBuildPhoneTypeDTO(acc.Work_Phone__pc, 'Business', true);
                            ipr.insertProfileRequest.profile.phone.add(ipt); 
                        }
                        else{
                          inst_PhoneType ipt = BuildPhone.InstBuildPhoneTypeDTO(acc.Work_Phone__pc, 'Business', false);
                            ipr.insertProfileRequest.profile.phone.add(ipt);     
                        }
                }
                    if(acc.Parents_Guardian_Emergency_Phone__pc != null){
                      if(acc.Preferred_Phone__pc == 'Parents/Guardian/Emergency'){
                            inst_PhoneType ipt = BuildPhone.InstBuildPhoneTypeDTO(acc.Parents_Guardian_Emergency_Phone__pc, 'Parent', true);
                            ipr.insertProfileRequest.profile.phone.add(ipt); 
                        }
                        else{
                          inst_PhoneType ipt = BuildPhone.InstBuildPhoneTypeDTO(acc.Parents_Guardian_Emergency_Phone__pc, 'Parent', false);
                            ipr.insertProfileRequest.profile.phone.add(ipt);     
                        }
                }
                    if(acc.Fax != null){
                      if(acc.Preferred_Phone__pc == 'Fax'){
                            inst_PhoneType ipt = BuildPhone.InstBuildPhoneTypeDTO(acc.Fax, 'Fax', true);
                            ipr.insertProfileRequest.profile.phone.add(ipt); 
                        }
                        else{
                          inst_PhoneType ipt = BuildPhone.InstBuildPhoneTypeDTO(acc.Fax, 'Fax', false);
                            ipr.insertProfileRequest.profile.phone.add(ipt);     
                        }
                }
                    
                    if (acc.Primary_Nationality__pc != null){
                        ipr.insertProfileRequest.profile.citizenship.country = acc.Primary_Nationality__pr.ISO_CODE__c;
                        ipr.insertProfileRequest.profile.citizenship.status = 'Citizen';           
                    }
                    
                    ipr.insertProfileRequest.profile.affiliation = new List<affiliationType>(); 
                    affiliationType at = new affiliationType();
                    at.value = 'Student';
                    ipr.insertProfileRequest.profile.affiliation.add(at);
                    
                    if(acc.Student_Type__pc == 'Domestic')
                      ipr.insertProfileRequest.profile.nationalityDetails.nationalityStatus = 'DOMESTIC';
                    else
                        ipr.insertProfileRequest.profile.nationalityDetails.nationalityStatus = 'INTERNATIONAL';
                    
                    //end setting values for insert call
                    
                    
                   String inst_jsonRequest = JSON.serialize(ipr);
                Http inst_http = new Http();
                    HttpRequest req_inst = BPPIntegrationConfig.callRestService(inst_jsonRequest, 'application/json', endPoint_insert);
                
                    system.debug('Test Final Insert JSON: ' + req_inst.getMethod() + ' ' + req_inst.getEndPoint() + 'Accept-Encoding:' + req_inst.getHeader('Accept-Encoding') +'Accept:' + req_inst.getHeader('Accept') + 'Content-Type:' + req_inst.getHeader('Content-Type') + 'tenantId:' + req_inst.getHeader('tenantId') + req_inst.getBody());
                    system.debug(req_inst.toString());
                    HttpResponse res_inst = null;
                    if (Test.isRunningTest()){
                        res_inst = new HttpResponse();
                        if (bFailSIS){
                            String strResponse = '{"companyId":"1234f567-bc23-42e8-924c-1234asdf5678","operation":"UPDATE"}';
                            res_inst.setStatusCode(200);
                            res_inst.setStatus('OK');
                            res_inst.setBody(strResponse);
                        }
                        else{
                            String strResponse = '{"profileId":"1234f567-bc23-42e8-924c-1234asdf5678","self":"null","httpMethod":"DELETE","errorMessage":"Cannot find Company or Profile Record for the specified Id: 1231231231","errorCode":"PLATFORM-801","transactionId":"A563C5CD-4CA9-B1C6-392A-09377720BFAC"}';
                            res_inst.setStatusCode(200);
                            res_inst.setStatus('OK');
                            res_inst.setBody(strResponse);
                        }
                    }
                    else{
                        res_inst = inst_http.send(req_inst);
                    }
                    system.debug(res_inst.getBody());
                    system.debug(res_inst.getStatus());                   
                    
                    // Integration Log 
                    Integration_Log__c intg_inst = new Integration_Log__c();
                    intg_inst.Request__c =  inst_jsonRequest;
                    intg_inst.Response__c = res_inst.getBody();
                    intg_inst.Salesforce_ID__c = acc.Id;
                    intg_inst.Integration_Type__c = 'Insert Student';
                    
                    String studentProfileId_inst;
                    if (res_inst.getStatus() == 'OK' && res_inst.getStatusCode() == 200){
        
                        JSONParser parser_inst = JSON.createParser(res_inst.getBody());
                        while (parser_inst.nextToken() != null) {
                            if ((parser_inst.getCurrentToken() == JSONToken.FIELD_NAME)){
                                String fieldName = parser_inst.getText();
                                parser_inst.nextToken();
                                if(fieldName == 'profileId') {   
                                studentProfileId_inst = parser_inst.getText();
                                    system.debug('studentProfileId_inst' + studentProfileId_inst);
                                    result = 'Success';
                                    break;
                                }
                            }
                        }
                        //update account with profile id
                        acc.PS_Profile_Services_ID__pc = studentProfileId_inst;
                        update acc;
                        
                    }
                    else{
                        //error handling for insert call
                        JSONParser jParser_inst = JSON.createParser(res_inst.getBody());
                        while(jParser_inst.nextToken() != null){
                            if((jParser_inst.getCurrentToken() == JSONToken.FIELD_NAME)){
                                string fieldN = jParser_inst.getText();
                                jParser_inst.nextToken();
                                if(fieldN == 'Description'){
                                    result = jParser_inst.getText();
                                    system.debug('errorMessage' + result);
                                    break;
                                }
                            }
                        }
                    }
                    insert intg_inst;
                }//end insert new account
                    
            }
            else{ 
                //error handling for find call
                JSONParser jParser = JSON.createParser(res.getBody());
                while(jParser.nextToken() !=null){
                    if((jParser.getCurrentToken() == JSONToken.FIELD_NAME)){
                        string fieldN = jParser.getText();
                        jParser.nextToken();
                        if(fieldN == 'Description'){
                            result = jParser.getText();
                            system.debug('errorMessage' + result);
                            break;
                        }
                    }
                }
            }
            insert intg;                    
        }
        return result;
    }
            
    
    WebService static String ProfileLeadInt_v2 (String LeadId) {
        String query = Util.getAllFieldsSOQL('Lead', 'Id = \'' + LeadId + '\'');
        Database.query(query);
        Lead ld = Database.query(query);
        String result = ProfileIntegrations_v2.CreatePersonInfo_lead_v2(ld);
        
        if(result == 'error code [20002]'){
            return 'Error: Minimum information for profile creation not available.  Minimum 3 fields are required out of: Name [First and Last],Date Of Birth,Postal code [Home,Mailing and Work], Email [Home,Personal and Work], Phone';
        }
        else         
          return result;
    }
    
    public static String CreatePersonInfo_lead_v2(Lead ld){
        string result;
        if (ld != null){
            findProfileRequest fpr = new findProfileRequest();
            
            fpr.findProfilesRequest.findProfile.name = new List<find_NameType>();
            find_NameType fnt = new find_NameType();
            if ((ld.LastName != null && ld.LastName != '') || (ld.FirstName != null && ld.FirstName != '')){ 
                fnt.lastName = ld.LastName;
                if (ld.FirstName != null && ld.FirstName != ''){
                    fnt.firstName = ld.FirstName;
                }
                fnt.type = 'Legal';
                fpr.findProfilesRequest.findProfile.name.add(fnt);      
            }
            
            Date dateOfBirth = ld.Birth_Date__c;
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
                fpr.findProfilesRequest.findProfile.dateOfBirth = dob;
            }
            
            list<Address__c> find_addresses = [Select Id, Type__c, Primary__c, Street_1__c, Street_2__c, Street_3__c, Street_4__c, City__c, State_Province__c, State_Province__r.ISO_Code__c, Locality__c, Locality__r.Banner_Code__c, Zip_Postal_Code__c, Lookup_Country__c, Lookup_Country__r.ISO_CODE__c,  Active__c From Address__c Where Lead__c =: ld.Id];
            if (find_addresses.size() != 0){
                fpr.findProfilesRequest.findProfile.address = new List<find_AddressType>();
                for (Address__c addr : find_addresses){
                    find_AddressType adr = new find_AddressType();
                    if (addr.Type__c != null && addr.Type__c != ''){
                        if(addr.Type__c == 'Next of Kin/Emergency/Guardian'){
                            adr.type = 'Parent';
                        }
                        else{
                            adr.type = addr.Type__c;
                        }
                    }
                    if (addr.Zip_Postal_Code__c != null && addr.Zip_Postal_Code__c != ''){
                        adr.postalCode = addr.Zip_Postal_Code__c;
                    }
                    fpr.findProfilesRequest.findProfile.address.add(adr);
                }
            }
            
            fpr.findProfilesRequest.findProfile.emailAddress = new List<find_EmailType>();
            if(ld.Personal_Email__c != null){
              find_EmailType fet = new find_EmailType();
                fet.type = 'Personal';
                fet.emailAddress = ld.Personal_Email__c;
                fpr.findProfilesRequest.findProfile.emailAddress.add(fet);
            }
            if(ld.Work_Email__c != null){
              find_EmailType fet = new find_EmailType();
                fet.type = 'Work';
                fet.emailAddress = ld.Work_Email__c;
                fpr.findProfilesRequest.findProfile.emailAddress.add(fet);
            }    
            if(ld.Other_Email__c != null){
                find_EmailType fet = new find_EmailType();
                fet.type = 'Other';
                fet.emailAddress = ld.Other_Email__c;
                fpr.findProfilesRequest.findProfile.emailAddress.add(fet);
            }    
            if(ld.Billing_Email__c  != null){
                find_EmailType fet = new find_EmailType();
                fet.type = 'Billing';
                fet.emailAddress = ld.Billing_Email__c ;
                fpr.findProfilesRequest.findProfile.emailAddress.add(fet);
            }    
            
            fpr.findProfilesRequest.findProfile.phone = new List<find_PhoneType>();   
            if(ld.Home_Phone__c != null){
              find_PhoneType fpt = BuildPhone.findBuildPhoneTypeDTO(ld.Home_Phone__c, 'Home');
                fpr.findProfilesRequest.findProfile.phone.add(fpt); 
            }
            if(ld.MobilePhone != null){
                find_PhoneType fpt = BuildPhone.findBuildPhoneTypeDTO(ld.MobilePhone, 'Mobile');
                fpr.findProfilesRequest.findProfile.phone.add(fpt); 
            }
            if(ld.Work_Phone__c != null){
                find_PhoneType fpt = BuildPhone.findBuildPhoneTypeDTO(ld.Work_Phone__c, 'Business');
                fpr.findProfilesRequest.findProfile.phone.add(fpt); 
            }
            if(ld.Parents_Guardian_Emergency_Phone__c != null){
                find_PhoneType fpt = BuildPhone.findBuildPhoneTypeDTO(ld.Parents_Guardian_Emergency_Phone__c, 'Parent');
                fpr.findProfilesRequest.findProfile.phone.add(fpt); 
            }
            if(ld.Fax != null){
                find_PhoneType fpt = BuildPhone.findBuildPhoneTypeDTO(ld.Fax, 'Fax');
                fpr.findProfilesRequest.findProfile.phone.add(fpt); 
            }
                        
           
            String jsonRequest = JSON.serialize(fpr);
            system.debug(jsonRequest +'Company Profile');
            Http http = new Http();
            //HttpRequest req = BPPIntegrationConfig.callRestService(jsonRequest, 'application/json', endPoint);
            HttpRequest req = BPPIntegrationConfig.callRestService(jsonRequest, 'application/json', endPoint_findmatch);
            
            system.debug('Test Final Find JSON: ' + req.getMethod() + ' ' + req.getEndPoint() + 'Accept-Encoding:' + req.getHeader('Accept-Encoding') +'Accept:' + req.getHeader('Accept') + 'Content-Type:' + req.getHeader('Content-Type') + 'tenantId:' + req.getHeader('tenantId') + req.getBody());
            system.debug(req.toString());
            HttpResponse res = null;
            if (Test.isRunningTest()){
                res = new HttpResponse();
                if (bFailSIS){
                    String strResponse = '{"companyId":"1234f567-bc23-42e8-924c-1234asdf5678","operation":"UPDATE"}';
                    res.setStatusCode(200);
                    res.setStatus('OK');
                    res.setBody(strResponse);
                }
                else{
                    String strResponse = '{"findProfilesResponse":{"result":null}}';
                    res.setStatusCode(200);
                    res.setStatus('OK');
                    res.setBody(strResponse);
                }
            }
            else{
                res = http.send(req);
            }
            system.debug('Test Response:' + res.getBody());
            system.debug('Test Response:' + res.getStatus());
            
            /* Integration Log */
            Integration_Log__c intg = new Integration_Log__c();
            intg.Request__c =  jsonRequest;
            intg.Salesforce_ID__c = ld.Id;
            intg.Integration_Type__c = 'Find Matching Student';
                      
            String studentProfileId;
            String ErrorDescription;
            if (res.getStatus() == 'OK' && res.getStatusCode() == 200){
                //resp is a JSON string
                JSONParser parser = JSON.createParser(res.getBody());
                while (parser.nextToken() != null) {
                    if ((parser.getCurrentToken() == JSONToken.FIELD_NAME)){
                        String fieldName = parser.getText();
                        parser.nextToken();
                        if(fieldName == 'profileId') {
                            studentProfileId = parser.getText();
                            system.debug('studentProfileId' + studentProfileId);
                            result = 'Success';
                            break;
                        }        
                        if(fieldName == 'Description') {
                          ErrorDescription = parser.getText();
                            system.debug('Find Error Message' + ErrorDescription);
                            intg.Response__c = ErrorDescription;
                            if(ErrorDescription.contains('error code [20002]'))
                              result = 'error code [20002]';
                            break;
                        }
                    }
                }
                
                List<Lead> existingLead = [select id, Name, PS_Profile_Services_ID__c from Lead where PS_Profile_Services_ID__c =: studentProfileId and PS_Profile_Services_ID__c != null and IsConverted = false];               
                List<Account> existingAccount = [Select id, Name, PS_Profile_Services_ID__pc from Account where PS_Profile_Services_ID__pc =: studentProfileId and PS_Profile_Services_ID__pc != null];
                
                if(existingLead.size()>0)
                    result = 'Potential duplicate student lead record found. Check existing lead:\n\n'+ existingLead[0].Name + ' (' + existingLead[0].PS_Profile_Services_ID__c + ')';                
        
                else if(existingAccount.size()>0)
                    result = 'Potential duplicate student account record found. Check existing account:\n\n'+ existingAccount[0].Name + ' (' + existingAccount[0].PS_Profile_Services_ID__pc + ')';                
                     
                else if (parser.nextToken() == null) {
                    //insert new student account in profile 
                  insertProfileRequest ipr = new insertProfileRequest();
                    if (dob != null && dob != ''){
                        ipr.insertProfileRequest.profile.profileInformation.dateOfBirth = dob;
                    }
                    
                    if (ld.Gender__c != null && ld.Gender__c != ''){
                        String gender_passed = '';
                        
                        if (ld.Gender__c == 'Male' || ld.Gender__c == 'M' || ld.Gender__c == 'm')
                            gender_passed = 'M';
                        else
                            gender_passed = 'F';
                                                
                        ipr.insertProfileRequest.profile.profileInformation.gender = gender_passed;
                    }
                                               
                    list<Address__c> addresses = [Select Id, Type__c, Primary__c, Street_1__c, Street_2__c, Street_3__c, Street_4__c, City__c, State_Province__c, State_Province__r.ISO_Code__c, Locality__c, Locality__r.Banner_Code__c, Zip_Postal_Code__c, Lookup_Country__c, Lookup_Country__r.ISO_CODE__c,  Active__c From Address__c Where Lead__c =: ld.Id];
            if (addresses.size() != 0){
                        ipr.insertProfileRequest.profile.address = new List<inst_AddressType>();
                        for (Address__c addr : addresses){
                            inst_AddressType adr = new inst_AddressType();
                            if (addr.Type__c != null && addr.Type__c != ''){
                                if(addr.Type__c == 'Next of Kin/Emergency/Guardian'){
                                    adr.type = 'Parent';
                                }
                                else{
                                    adr.type = addr.Type__c;
                                }
                            }
                            if (addr.Street_1__c != null && addr.Street_1__c != ''){
                                adr.line1 = addr.Street_1__c;
                            }
                            if (addr.Street_2__c != null && addr.Street_2__c != ''){
                                adr.line2 = addr.Street_2__c;
                            }
                            if (addr.Street_3__c != null && addr.Street_3__c != ''){
                                adr.line3 = addr.Street_3__c;
                            }
                            if (addr.Street_4__c != null && addr.Street_4__c != ''){
                                adr.line4 = addr.Street_4__c;
                            }
                            if (addr.City__c != null && addr.City__c != ''){
                                adr.city = addr.City__c;
                            }
                            if (addr.State_Province__c != null && addr.State_Province__r.ISO_CODE__c != null && 
                                addr.State_Province__r.ISO_CODE__c != ''){
                                adr.stateProvince = addr.State_Province__r.ISO_CODE__c;
                            }
                            if (addr.Zip_Postal_Code__c != null && addr.Zip_Postal_Code__c != ''){
                                adr.postalCode = addr.Zip_Postal_Code__c;
                            }
                            if (addr.Lookup_Country__c != null && addr.Lookup_Country__r.ISO_CODE__c != null && 
                                addr.Lookup_Country__r.ISO_CODE__c != ''){
                                adr.country = addr.Lookup_Country__r.ISO_CODE__c;
                            }
                            adr.isPrimary = addr.Primary__c;
                            adr.isCertified = addr.Primary__c;
                            
                            ipr.insertProfileRequest.profile.address.add(adr);
                        }
                    }
                                        
                    ipr.insertProfileRequest.profile.emailAddress = new List<inst_EmailType>();
                    if(ld.Personal_Email__c != null){
                      if(ld.Preferred_Email__c == 'Personal'){
                            inst_EmailType iet = new inst_EmailType();
                            iet.type = 'Personal';
                            iet.emailAddress = ld.Personal_Email__c;
                            iet.isPrimary = true;
                            ipr.insertProfileRequest.profile.emailAddress.add(iet);
                        }
                        else {
                            inst_EmailType iet = new inst_EmailType();
                            iet.type = 'Personal';
                            iet.emailAddress = ld.Personal_Email__c;
                            iet.isPrimary = false;
                            ipr.insertProfileRequest.profile.emailAddress.add(iet); 
                        }
                    }
                    if(ld.Work_Email__c != null){
                      if(ld.Preferred_Email__c == 'Work'){
                            inst_EmailType iet = new inst_EmailType();
                            iet.type = 'Work';
                            iet.emailAddress = ld.Work_Email__c;
                            iet.isPrimary = true;
                            ipr.insertProfileRequest.profile.emailAddress.add(iet);
                        }
                        else {
                            inst_EmailType iet = new inst_EmailType();
                            iet.type = 'Work';
                            iet.emailAddress = ld.Work_Email__c;
                            iet.isPrimary = false;
                            ipr.insertProfileRequest.profile.emailAddress.add(iet); 
                        }
                    }    
                    if(ld.Other_Email__c != null){
                      if(ld.Preferred_Email__c == 'Other'){
                            inst_EmailType iet = new inst_EmailType();
                            iet.type = 'Other';
                            iet.emailAddress = ld.Other_Email__c;
                            iet.isPrimary = true;
                            ipr.insertProfileRequest.profile.emailAddress.add(iet);
                        }
                        else {
                            inst_EmailType iet = new inst_EmailType();
                            iet.type = 'Other';
                            iet.emailAddress = ld.Other_Email__c;
                            iet.isPrimary = false;
                            ipr.insertProfileRequest.profile.emailAddress.add(iet); 
                        }
                    }    
                    if(ld.Billing_Email__c  != null){
                      if(ld.Preferred_Email__c == 'Billing'){
                            inst_EmailType iet = new inst_EmailType();
                            iet.type = 'Billing';
                            iet.emailAddress = ld.Billing_Email__c ;
                            iet.isPrimary = true;
                            ipr.insertProfileRequest.profile.emailAddress.add(iet);
                        }
                        else {
                            inst_EmailType iet = new inst_EmailType();
                            iet.type = 'Billing';
                            iet.emailAddress = ld.Billing_Email__c ;
                            iet.isPrimary = false;
                            ipr.insertProfileRequest.profile.emailAddress.add(iet); 
                        }
                    }    
                    
                    ipr.insertProfileRequest.profile.name = new List<inst_NameType>();
                    inst_NameType nt = new inst_NameType();
                    if ((ld.LastName != null && ld.LastName != '') || (ld.FirstName != null && ld.FirstName != '')){ 
                  nt.lastName = ld.LastName;
                        if (ld.FirstName != null && ld.FirstName != ''){
                          nt.firstName = ld.FirstName;
                        }
                        if (ld.Middle_Name__c != null && ld.Middle_Name__c != ''){
                          nt.middleName = ld.Middle_Name__c;
                        }
                        if (ld.Salutation != null && ld.Salutation != ''){
                             nt.prefix = ld.Salutation;
                        }
                        if (ld.Preferred_First_Name__c != null && ld.Preferred_First_Name__c != ''){
                          nt.preferredName = ld.Preferred_First_Name__c;
                        }
                        nt.type = 'Legal';
                        nt.Primary = true;
                        
                        ipr.insertProfileRequest.profile.name.add(nt);      
                  }
                    
          ipr.insertProfileRequest.profile.phone = new List<inst_PhoneType>();   
                if(ld.Home_Phone__c != null){
                      if(ld.Preferred_Phone__c == 'Home'){  
                            inst_PhoneType ipt = BuildPhone.InstBuildPhoneTypeDTO(ld.Home_Phone__c, 'Home', true);
                            ipr.insertProfileRequest.profile.phone.add(ipt); 
                        }
                        else{
                          inst_PhoneType ipt = BuildPhone.InstBuildPhoneTypeDTO(ld.Home_Phone__c, 'Home', false);
                            ipr.insertProfileRequest.profile.phone.add(ipt);     
                        }
                }
                    if(ld.MobilePhone != null){
                      if(ld.Preferred_Phone__c == 'Mobile'){
                            inst_PhoneType ipt = BuildPhone.InstBuildPhoneTypeDTO(ld.MobilePhone, 'Mobile', true);
                            ipr.insertProfileRequest.profile.phone.add(ipt); 
                        }
                        else{
                          inst_PhoneType ipt = BuildPhone.InstBuildPhoneTypeDTO(ld.MobilePhone, 'Mobile', false);
                            ipr.insertProfileRequest.profile.phone.add(ipt);     
                        }
                }
                    if(ld.Work_Phone__c != null){
                      if(ld.Preferred_Phone__c == 'Work'){
                            inst_PhoneType ipt = BuildPhone.InstBuildPhoneTypeDTO(ld.Work_Phone__c, 'Business', true);
                            ipr.insertProfileRequest.profile.phone.add(ipt); 
                        }
                        else{
                          inst_PhoneType ipt = BuildPhone.InstBuildPhoneTypeDTO(ld.Work_Phone__c, 'Business', false);
                            ipr.insertProfileRequest.profile.phone.add(ipt);     
                        }
                }
                    if(ld.Parents_Guardian_Emergency_Phone__c != null){
                      if(ld.Preferred_Phone__c == 'Parents/Guardian/Emergency'){
                            inst_PhoneType ipt = BuildPhone.InstBuildPhoneTypeDTO(ld.Parents_Guardian_Emergency_Phone__c, 'Parent', true);
                            ipr.insertProfileRequest.profile.phone.add(ipt); 
                        }
                        else{
                          inst_PhoneType ipt = BuildPhone.InstBuildPhoneTypeDTO(ld.Parents_Guardian_Emergency_Phone__c, 'Parent', false);
                            ipr.insertProfileRequest.profile.phone.add(ipt);     
                        }
                }
                    if(ld.Fax != null){
                      if(ld.Preferred_Phone__c == 'Fax'){
                            inst_PhoneType ipt = BuildPhone.InstBuildPhoneTypeDTO(ld.Fax, 'Fax', true);
                            ipr.insertProfileRequest.profile.phone.add(ipt); 
                        }
                        else{
                          inst_PhoneType ipt = BuildPhone.InstBuildPhoneTypeDTO(ld.Fax, 'Fax', false);
                            ipr.insertProfileRequest.profile.phone.add(ipt);     
                        }
                }
                                        
                    ipr.insertProfileRequest.profile.affiliation = new List<affiliationType>(); 
                    affiliationType at = new affiliationType();
                    at.value = 'Student';
                    ipr.insertProfileRequest.profile.affiliation.add(at);
                    
                    ipr.insertProfileRequest.profile.nationalityDetails.nationalityStatus = 'DOMESTIC';
                    
                    //end setting values for insert call
                    
                    
                   String inst_jsonRequest = JSON.serialize(ipr);
                Http inst_http = new Http();
                    HttpRequest req_inst = BPPIntegrationConfig.callRestService(inst_jsonRequest, 'application/json', endPoint_insert);
                
                    system.debug('Test Final Insert JSON: ' + req_inst.getMethod() + ' ' + req_inst.getEndPoint() + 'Accept-Encoding:' + req_inst.getHeader('Accept-Encoding') +'Accept:' + req_inst.getHeader('Accept') + 'Content-Type:' + req_inst.getHeader('Content-Type') + 'tenantId:' + req_inst.getHeader('tenantId') + req_inst.getBody());
                    system.debug(req_inst.toString());
                    HttpResponse res_inst = null;
                    if (Test.isRunningTest()){
                        res_inst = new HttpResponse();
                        if (bFailSIS){
                            String strResponse = '{"self":"null","httpMethod":"DELETE","errorMessage":"Cannot find Company or Profile Record for the specified Id: 1231231231","errorCode":"PLATFORM-801","transactionId":"A563C5CD-4CA9-B1C6-392A-09377720BFAC","Description":"Exception 2: Something went wrong."}';
                            res_inst.setStatusCode(500);
                            res_inst.setStatus('Error');
                            res_inst.setBody(strResponse);
                        }
                        else{
                            String strResponse = '{"profileId":"1234xxx5-xxx1-1x2x-xxx1-12345x678x9",companyId":"1234f567-bc23-42e8-924c-1234asdf5678","operation":"UPDATE"}';
                            res_inst.setStatusCode(200);
                            res_inst.setStatus('OK');
                            res_inst.setBody(strResponse);
                        }
                    }
                    else{
                        res_inst = inst_http.send(req_inst);
                    }
                    system.debug(res_inst.getBody());
                    system.debug(res_inst.getStatus());                   
                    
                    // Integration Log 
                    Integration_Log__c integLog = new Integration_Log__c();
                    integLog.Request__c =  inst_jsonRequest;
                    integLog.Salesforce_ID__c = ld.Id;
                    integLog.Integration_Type__c = 'Insert Student';
                    
                    String studentProfileId_inst;
                    if (res_inst.getStatus() == 'OK' && res_inst.getStatusCode() == 200){
                        JSONParser parser_inst = JSON.createParser(res_inst.getBody());
                        while (parser_inst.nextToken() != null) {
                            if ((parser_inst.getCurrentToken() == JSONToken.FIELD_NAME)){
                                String fieldName = parser_inst.getText();
                                parser_inst.nextToken();
                                if(fieldName == 'profileId') {   
                                    studentProfileId_inst = parser_inst.getText();
                                    system.debug('studentProfileId_inst' + studentProfileId_inst);
                                    integLog.Response__c = 'Success';
                                    result = 'Success';
                                    break;
                                }
                            }
                        }
                        //update account with profile id
                        ld.PS_Profile_Services_ID__c = studentProfileId_inst;
                        update ld;
                    }
                    else{
                        //error handling for insert call
                        JSONParser jParser_inst = JSON.createParser(res_inst.getBody());
                        while(jParser_inst.nextToken() != null){
                            if((jParser_inst.getCurrentToken() == JSONToken.FIELD_NAME)){
                                string fieldN = jParser_inst.getText();
                                jParser_inst.nextToken();
                                if(fieldN == 'Description'){
                                    integLog.Response__c = jParser_inst.getText();
                                    result = jParser_inst.getText();
                                    system.debug('errorMessage' + result);
                                    break;
                                }
                            }
                        }
                    }
                    insert integLog;
                }//end insert new account
                    
            }
            else{ 
                //error handling for find call
                JSONParser jParser = JSON.createParser(res.getBody());
                while(jParser.nextToken() !=null){
                    if((jParser.getCurrentToken() == JSONToken.FIELD_NAME)){
                        string fieldN = jParser.getText();
                        jParser.nextToken();
                        if(fieldN == 'Description'){
                            intg.Response__c = jParser.getText();
                            result = jParser.getText();
                            system.debug('errorMessage' + result);
                            break;
                        }
                    }
                }
            }
            insert intg;                    
        }
        return result;
    }
    
    
    @future(callOut=true)
    public static void UpdatePersonInfo_v2(String strProfileId, String accountId, String AddressType, Boolean AddressDeleted, List<String> listDeletedPhones, List<String> listDeletedEmails){
        if (listDeletedPhones == null) listDeletedPhones = new List<String>();
        if (listDeletedEmails == null) listDeletedEmails = new List<String>();
        string result;
        String query = Util.getAllFieldsSOQL('Account', 'Id = \'' + accountId + '\'');
        Account acc = Database.query(query);
        
        Account acct  = [Select Id, Primary_Nationality__pc, Primary_Nationality__pr.ISO_CODE__c 
                        From Account Where Id =: acc.Id Limit 1];
        if(acc.Primary_Nationality__pc != null){
            acc.Primary_Nationality__pc = acct.Primary_Nationality__pc;
            acc.Primary_Nationality__pr = acct.Primary_Nationality__pr;
            acc.Primary_Nationality__pr.ISO_Code__c = acct.Primary_Nationality__pr.ISO_Code__c;
        }
        
        if (acc != null){
          updateProfileRequest upr = new updateProfileRequest();
            
            upr.updateProfileRequest.profile.profileId = acc.PS_Profile_Services_ID__pc;
                        
            if(acc.AR_Student_Finance_England_SFE__c != null && acc.AR_Student_Finance_England_SFE__c != ''){ 
              upr.updateProfileRequest.profile.profileInformation.extensionfield = new List<extensionfieldType>();
                extensionfieldType eft = new extensionfieldType();
                eft.key = 'STUDENT_FINANCE_ID';
                eft.value = acc.AR_Student_Finance_England_SFE__c;
                upr.updateProfileRequest.profile.profileInformation.extensionfield.add(eft);      
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
                upr.updateProfileRequest.profile.profileInformation.dateOfBirth = dob;
            }
            
            String gender = acc.Gender__pc;
            String gender_passed;
            if (gender != null){
                if (gender == 'Male')
                    gender_passed = 'M';
                else if (gender == 'Female')
                    gender_passed = 'F';
            }
            upr.updateProfileRequest.profile.profileInformation.gender = gender_passed;
            
            if(acc.SFDC_Ethnic_Code_Select__pc != null && acc.SFDC_Ethnic_Code_Select__pc != ''){
    			String ethnicityCode = BNR_SubmitApplication.ExtractCode(acc.SFDC_Ethnic_Code_Select__pc);
    			if(ethnicityCode != null && ethnicityCode.length() == 2){
        			upr.updateProfileRequest.profile.profileInformation.ethnicity = ethnicityCode;
    			}
			}
            if (acc.VAT_Code__pc != null && acc.VAT_Code__pc != ''){
                upr.updateProfileRequest.profile.profileInformation.vatNumber = acc.VAT_Code__pc;
            }
            
            list<Address__c> addresses = [Select Id, Type__c, Primary__c, Street_1__c, Street_2__c, Street_3__c, Street_4__c, City__c, State_Province__c, State_Province__r.ISO_Code__c, Locality__c, Locality__r.Banner_Code__c, Zip_Postal_Code__c, Lookup_Country__c, Lookup_Country__r.ISO_CODE__c,  Active__c From Address__c Where Student__c =: acc.Id];
            if (addresses.size() != 0){
                upr.updateProfileRequest.profile.address = new List<update_AddressType>();
                for (Address__c addr : addresses){
                    update_AddressType adr = new update_AddressType();
                    if (addr.Type__c != null && addr.Type__c != ''){
                        if(addr.Type__c == 'Next of Kin/Emergency/Guardian'){
                            adr.type = 'Parent';
                        }
                        else{
                            adr.type = addr.Type__c;
                        }
                    }
                    if (addr.Street_1__c != null && addr.Street_1__c != ''){
                        adr.line1 = addr.Street_1__c;
                    }
                    if (addr.Street_2__c != null && addr.Street_2__c != ''){
                        adr.line2 = addr.Street_2__c;
                    }
                    if (addr.Street_3__c != null && addr.Street_3__c != ''){
                        adr.line3 = addr.Street_3__c;
                    }
                    if (addr.Street_4__c != null && addr.Street_4__c != ''){
                        adr.line4 = addr.Street_4__c;
                    }
                    if (addr.City__c != null && addr.City__c != ''){
                        adr.city = addr.City__c;
                    }
                    if (addr.State_Province__c != null && addr.State_Province__r.ISO_CODE__c != null && 
                        addr.State_Province__r.ISO_CODE__c != ''){
                            adr.stateProvince = addr.State_Province__r.ISO_CODE__c;
                        }
                    //if (addr.Locality__c != null && addr.Locality__r.Banner_Code__c != null && 
                    //    addr.Locality__r.Banner_Code__c != ''){
                    //    adr.locality = addr.Locality__r.Banner_Code__c;
                    //}
                    if (addr.Zip_Postal_Code__c != null && addr.Zip_Postal_Code__c != ''){
                        adr.postalCode = addr.Zip_Postal_Code__c;
                    }
                    if (addr.Lookup_Country__c != null && addr.Lookup_Country__r.ISO_CODE__c != null && 
                        addr.Lookup_Country__r.ISO_CODE__c != ''){
                            adr.country = addr.Lookup_Country__r.ISO_CODE__c;
                        }
                    adr.isPrimary = addr.Primary__c;
                   
                    upr.updateProfileRequest.profile.address.add(adr);
                }
            }
            
            upr.updateProfileRequest.profile.emailAddress = new List<update_EmailType>();
            if(acc.Personal_Email__pc != null){
                if(acc.Preferred_Email__pc == 'Personal'){
                    update_EmailType iet = new update_EmailType();
                    iet.type = 'Personal';
                    iet.emailAddress = acc.Personal_Email__pc;
                    iet.isPrimary = true;
                    upr.updateProfileRequest.profile.emailAddress.add(iet);
                }
                else {
                    update_EmailType iet = new update_EmailType();
                    iet.type = 'Personal';
                    iet.emailAddress = acc.Personal_Email__pc;
                    iet.isPrimary = false;
                    upr.updateProfileRequest.profile.emailAddress.add(iet); 
                }
            }
            if(acc.Work_Email__pc != null){
                if(acc.Preferred_Email__pc == 'Work'){
                    update_EmailType iet = new update_EmailType();
                    iet.type = 'Work';
                    iet.emailAddress = acc.Work_Email__pc;
                    iet.isPrimary = true;
                    upr.updateProfileRequest.profile.emailAddress.add(iet);
                }
                else {
                    update_EmailType iet = new update_EmailType();
                    iet.type = 'Work';
                    iet.emailAddress = acc.Work_Email__pc;
                    iet.isPrimary = false;
                    upr.updateProfileRequest.profile.emailAddress.add(iet); 
                }
            }    
            if(acc.BPP_Email__pc != null){
                if(acc.Preferred_Email__pc == 'BPP'){
                    update_EmailType iet = new update_EmailType();
                    iet.type = 'BPP';
                    iet.emailAddress = acc.BPP_Email__pc;
                    iet.isPrimary = true;
                    upr.updateProfileRequest.profile.emailAddress.add(iet);
                }
                else {
                    update_EmailType iet = new update_EmailType();
                    iet.type = 'BPP';
                    iet.emailAddress = acc.BPP_Email__pc;
                    iet.isPrimary = false;
                    upr.updateProfileRequest.profile.emailAddress.add(iet); 
                }
            }    
            if(acc.Other_Email__pc != null){
                if(acc.Preferred_Email__pc == 'Other'){
                    update_EmailType iet = new update_EmailType();
                    iet.type = 'Other';
                    iet.emailAddress = acc.Other_Email__pc;
                    iet.isPrimary = true;
                    upr.updateProfileRequest.profile.emailAddress.add(iet);
                }
                else {
                    update_EmailType iet = new update_EmailType();
                    iet.type = 'Other';
                    iet.emailAddress = acc.Other_Email__pc;
                    iet.isPrimary = false;
                    upr.updateProfileRequest.profile.emailAddress.add(iet); 
                }
            }    
            if(acc.Billing_Email__pc  != null){
                if(acc.Preferred_Email__pc == 'Billing'){
                    update_EmailType iet = new update_EmailType();
                    iet.type = 'Billing';
                    iet.emailAddress = acc.Billing_Email__pc ;
                    iet.isPrimary = true;
                    upr.updateProfileRequest.profile.emailAddress.add(iet);
                }
                else {
                    update_EmailType iet = new update_EmailType();
                    iet.type = 'Billing';
                    iet.emailAddress = acc.Billing_Email__pc ;
                    iet.isPrimary = false;
                    upr.updateProfileRequest.profile.emailAddress.add(iet); 
                }
            }    
            
            upr.updateProfileRequest.profile.name = new List<update_NameType>();
            update_NameType nt = new update_NameType();
            if ((acc.LastName != null && acc.LastName != '') || (acc.FirstName != null && acc.FirstName != '')){ 
                nt.lastName = acc.LastName;
                if (acc.FirstName != null && acc.FirstName != ''){
                    nt.firstName = acc.FirstName;
                }
                if (acc.Middle_Name__pc != null && acc.Middle_Name__pc != ''){
                    nt.middleName = acc.Middle_Name__pc;
                }
                if (acc.Salutation != null && acc.Salutation != ''){
                    nt.prefix = acc.Salutation;
                }
                if (acc.AA_Suffix__pc != null && acc.AA_Suffix__pc != ''){
                    nt.suffix = acc.AA_Suffix__pc;
                }
                if (acc.Preferred_First_Name__pc != null && acc.Preferred_First_Name__pc != ''){
                    nt.preferredName = acc.Preferred_First_Name__pc;
                }
                nt.type = 'Legal';
                nt.Primary = true;
                
                upr.updateProfileRequest.profile.name.add(nt);      
            }
            
            upr.updateProfileRequest.profile.phone = new List<inst_PhoneType>();   
            if(acc.personHomePhone != null){
                if(acc.Preferred_Phone__pc == 'Home'){  
                    inst_PhoneType ipt = BuildPhone.InstBuildPhoneTypeDTO(acc.personHomePhone, 'Home', true);
                    upr.updateProfileRequest.profile.phone.add(ipt); 
                }
                else{
                    inst_PhoneType ipt = BuildPhone.InstBuildPhoneTypeDTO(acc.personHomePhone, 'Home', false);
                    upr.updateProfileRequest.profile.phone.add(ipt);     
                }
            }
            if(acc.personMobilePhone != null){
                if(acc.Preferred_Phone__pc == 'Mobile'){
                    inst_PhoneType ipt = BuildPhone.InstBuildPhoneTypeDTO(acc.personMobilePhone, 'Mobile', true);
                    upr.updateProfileRequest.profile.phone.add(ipt); 
                }
                else{
                    inst_PhoneType ipt = BuildPhone.InstBuildPhoneTypeDTO(acc.personMobilePhone, 'Mobile', false);
                    upr.updateProfileRequest.profile.phone.add(ipt);     
                }
            }
            if(acc.Work_Phone__pc != null){
                if(acc.Preferred_Phone__pc == 'Work'){
                    inst_PhoneType ipt = BuildPhone.InstBuildPhoneTypeDTO(acc.Work_Phone__pc, 'Business', true);
                    upr.updateProfileRequest.profile.phone.add(ipt); 
                }
                else{
                    inst_PhoneType ipt = BuildPhone.InstBuildPhoneTypeDTO(acc.Work_Phone__pc, 'Business', false);
                    upr.updateProfileRequest.profile.phone.add(ipt);     
                }
            }
            if(acc.Parents_Guardian_Emergency_Phone__pc != null){
                if(acc.Preferred_Phone__pc == 'Parents/Guardian/Emergency'){
                    inst_PhoneType ipt = BuildPhone.InstBuildPhoneTypeDTO(acc.Parents_Guardian_Emergency_Phone__pc, 'Parent', true);
                    upr.updateProfileRequest.profile.phone.add(ipt); 
                }
                else{
                    inst_PhoneType ipt = BuildPhone.InstBuildPhoneTypeDTO(acc.Parents_Guardian_Emergency_Phone__pc, 'Parent', false);
                    upr.updateProfileRequest.profile.phone.add(ipt);     
                }
            }
            if(acc.Fax != null){
                if(acc.Preferred_Phone__pc == 'Fax'){
                    inst_PhoneType ipt = BuildPhone.InstBuildPhoneTypeDTO(acc.Fax, 'Fax', true);
                    upr.updateProfileRequest.profile.phone.add(ipt); 
                }
                else{
                    inst_PhoneType ipt = BuildPhone.InstBuildPhoneTypeDTO(acc.Fax, 'Fax', false);
                    upr.updateProfileRequest.profile.phone.add(ipt);     
                }
            }
            
            if (acc.Primary_Nationality__pc != null){
                upr.updateProfileRequest.profile.citizenship.country = acc.Primary_Nationality__pr.ISO_CODE__c;
                upr.updateProfileRequest.profile.citizenship.status = 'Citizen';           
            }
            
            upr.updateProfileRequest.profile.affiliation = new List<update_affiliationType>(); 
            update_affiliationType at = new update_affiliationType();
            at.value = 'Student';
            upr.updateProfileRequest.profile.affiliation.add(at);
            
            if(acc.Student_Type__pc == 'Domestic')
                upr.updateProfileRequest.profile.nationalityDetails.nationalityStatus = 'DOMESTIC';
            else
                upr.updateProfileRequest.profile.nationalityDetails.nationalityStatus = 'INTERNATIONAL';
            
            //end setting values for update call
            
            //if update is from an address being deleted
            if(AddressDeleted == true){
                upr.updateProfileRequest.deleteEntity.entityToDelete = new List<entityToDeleteType>(); 
                entityToDeleteType etd = new entityToDeleteType();
                etd.entityName = 'ADDRESS';
                etd.entityType = new List<string>();
                etd.entityType.add(AddressType);
                upr.updateProfileRequest.deleteEntity.entityToDelete.add(etd);
            }
            
            //if any phone or email addres is deleted
            if (listDeletedPhones.size() != 0 || listDeletedEmails.size() != 0){
              upr.updateProfileRequest.deleteEntity.entityToDelete = new List<entityToDeleteType>(); 
                
              //if any phone number is deleted
                if (listDeletedPhones.size() != 0){
                    entityToDeleteType phn_etd = new entityToDeleteType();
                    phn_etd.entityName = 'PHONE';
                    phn_etd.entityType = new List<string>();
                    
                    for (String PhnType : listDeletedPhones){
                        phn_etd.entityType.add(PhnType);
                    }
                    
                    upr.updateProfileRequest.deleteEntity.entityToDelete.add(phn_etd);
                }
              
                //if any email address is deleted
                if (listDeletedEmails.size() != 0){
                    entityToDeleteType eml_etd = new entityToDeleteType();
                    eml_etd.entityName = 'EMAIL';
                    eml_etd.entityType = new List<string>();
                    
                    for (String EmlType : listDeletedEmails){
                        eml_etd.entityType.add(EmlType);
                    }
                    
                    upr.updateProfileRequest.deleteEntity.entityToDelete.add(eml_etd);
                }
            }
                   
                      
            String jsonRequest = JSON.serialize(upr);
            system.debug(jsonRequest);
            Http http = new Http();
            HttpRequest req = BPPIntegrationConfig.callUpdateRestService(jsonRequest, 'application/json', endPoint_update);
            
            system.debug('Final JSON: ' + req.getMethod() + ' ' + req.getEndPoint() + 'Accept-Encoding:' + req.getHeader('Accept-Encoding') +'Accept:' + req.getHeader('Accept') + 'Content-Type:' + req.getHeader('Content-Type') + 'tenantId:' + req.getHeader('tenantId') + req.getBody());
            system.debug(req.toString());
            HttpResponse res = null;
            if (Test.isRunningTest()){
                res = new HttpResponse();
                if (bFailSIS) {
                    String strResponse = '<html><head><title>Apache Tomcat/6.0.26 - Error report</title> </head><body><h1>HTTP Status 500 - </h1><p><b>type</b> Exception report</p><p><b>message</b> <u></u></p><p><b>description</b> <u>The server encountered an internal error () that prevented it from fulfilling this request.</u></p><p><b>exception</b> <pre>org.springframework.web.util.NestedServletException: Request processing failed; nested exception is edu.apolloglobal.platform.persistence.webservice.PersistenceServerException: Service exception occurred while persisting input.\n </pre></p><p><b>root cause</b> <pre>org.hibernate.PropertyValueException: not-null property references a null or transient value: edu.apolloglobal.platform.persistence.profile.dao.entity.Issue\n';
                    res.setStatusCode(500);
                    res.setStatus('Error');
                    res.setBody(strResponse);
                }
                else {
                    String strResponse = '{"success":true,"companyId":"bfb463f9-b4c2-4ce4-a429-05818b8cae1f","operation":"UPDATE","identities":{"values":[{"id":"92a41ad1-6c4d-4361-b16f-4b43cdd7af4f","value":"BP0015638","type":"BANNER","active":true}';
                    res.setStatusCode(200);
                    res.setStatus('OK');
                    res.setBody(strResponse);
                }
            }
            else{
                res = http.send(req);
            }
            system.debug(res.getBody());
            system.debug(res.getStatus());
            
            createIntegrationLog(jsonRequest, res, acc.Id);
        }
        return;
    }
    
    private static void createIntegrationLog(String jsonRequest, HttpResponse res, String accId) {
        Integration_Log__c integLog = new Integration_Log__c();
        integLog.Request__c = jsonRequest;
        integLog.Salesforce_ID__c = accId;
        integLog.Integration_Type__c = 'Update Existing Student';
        
        try {
            JSONParser parser = JSON.createParser(res.getBody());
            while (parser.nextToken() != null) {
                if ((parser.getCurrentToken() == JSONToken.FIELD_NAME)) {
                    String fieldName = parser.getText();
                    parser.nextToken();
                    if (fieldName == 'success') {
                        integLog.Response__c = 'Success';
                        break;
                    }
                }
            }
        } catch (Exception e) {
            String errorResponse = formatErrorResponse(res.getBody());
            integLog.Response__c = errorResponse != null ? errorResponse : res.getBody();
        } finally {
            insert integLog;
        }
    }
    
    private static String formatErrorResponse(String body) {
        String responseConcat;
        List<String> splitBody = new List<String>();
        if (body.startsWith('<html>') && body.contains('root cause')) {
            splitBody = body.split('<b>root cause</b> <pre>');
            splitBody.remove(0);
            for (String str : splitBody) {
                responseConcat += str.substringBefore('\n');
            }
        }
        return responseConcat;
    }
}