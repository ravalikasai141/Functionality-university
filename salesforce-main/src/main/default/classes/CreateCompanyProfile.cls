global with sharing class CreateCompanyProfile{
    //public static string endPoint = '/rest/company/v1/companies/createUpdateCompanyInfo';
    public static string endPoint_findmatch = '/rest/company/v2/companies/findMatchingCompany';
    public static string endPoint_insert = '/rest/company/v1/companies';
    public static string endPoint_update = '/rest/company/v2/companies';
    
    public static Boolean bFailSIS = false;
    
    WebService static String CompanyInformation(String accountId){
        String result;
        Account acc = [Select Id, Acronym_short_title__c, Name, VAT_number__c, EU_Tax_registered__c, Reporting_Required__c, 
                              Correspondence_Detail__c, Customer_Type__c, Profile_Company_ID__c, Industry_Type_SIC__c, Use_This_One__c,
                              Phone, Invoice_Email_Address__c, Fax,
                                  (Select Id, Type__c, Street_1__c, Street_2__c, Street_3__c, Street_4__c, City__c, State_Province__r.ISO_CODE__c, 
                                  Zip_Postal_Code__c, Lookup_Country__r.ISO_CODE__c, Locality__r.Banner_Code__c, Primary__c From Addresses__r Where Active__c = true) 
                                  From Account Where Id = :accountId Limit 1];
        String strRet = sendCompanyInformation(acc);
        
        result = strRet;
        return result;
    }
     
    public class companyTypeInfo{
        public companyType company = new companyType();
    }
    
    public class UpdatecompanyTypeInfo{
        public companyType company = new companyType();
        //public string profileId;
        public DeleteEntityType deleteEntity;
    }
    
    public class companyType {
        public companyInformationType companyInformation = new companyInformationType();
        public CustType customerType = new CustType();
        public AddressDTO addresses = new AddressDTO();
        
        public EmailDTO emails = new EmailDTO();
        public PhoneDTO phones = new PhoneDTO();
        //public Identity identities = new Identity();
    }
    
    public class companyInformationType {
        public string shortName = '';
        public string companyName = '';
        public string taxId = '';
        public string euTaxRegistered = '';
        public boolean poRequired = false;
        public string isoCountryCode = '';
        public string preferredMethodOfCorrespondence = '';
    }
    
    public class CustType {
        public string value = '';
    }
    
    public class AddressDTO {
        List<AddressType> values = new List<AddressType>();
    }
    
    public class AddressType {
        public string type = '';
        public string line1 = '';
        public string line2 = '';
        public string line3 = '';
        public string line4 = '';
        public string city = '';
        public string stateProvince = '';
        public string locality = '';
        public string postalCode = '';
        public string country = '';
        public boolean isPrimary = false;
        public boolean isCertified = false;
    }
    
    public class EmailDTO {
        List<EmailType> values = new List<EmailType>();
    }
    
    public class EmailType {
        public string type = '';
        public string emailAddress = '';
        public boolean isPrimary = false;
    }
    
    public class PhoneDTO {
        List<PhoneType> values = new List<PhoneType>();
    }
    
    public class PhoneType {
        public string type = '';
        public string areaCode = '';
        public string phoneNumber = '';
        public string extension = '';
        public string countryCode = '';
        public boolean isPrimary = false;
    }
    
    /*public class Identity {
        List<IdentityType> values = new List<IdentityType>();
    }
    
    public class IdentityType {
        public string value = '';
        public string type = '';
        public boolean active = false;
    }*/
    
    public class DeleteEntityType {
        public DeleteAddressDTO addresses = new DeleteAddressDTO(); 
        public DeleteEmailDTO emails = new DeleteEmailDTO();   
        public DeletePhoneDTO phones = new DeletePhoneDTO(); 
    }
    
    public class DeleteAddressDTO {
        List<DeleteAddressType> values = new List<DeleteAddressType>();
    }    
    
    public class DeleteAddressType {
        public string type = '';
    }
     
    public class DeleteEmailDTO {
        List<DeleteEmailType> values = new List<DeleteEmailType>();
    }   
    
    public class DeleteEmailType {
        public string type = '';
    }
    
    public class DeletePhoneDTO {
        List<DeletePhoneType> values = new List<DeletePhoneType>();
    }   
    
    public class DeletePhoneType {
        public string type = '';
    }
    
    
    public static String sendCompanyInformation(Account acc){
        string result;
        if (acc != null){
            CompanyTypeInfo cti = new CompanyTypeInfo();
            
            if (acc.Acronym_short_title__c != null && acc.Acronym_short_title__c != ''){
                cti.company.companyInformation.shortName = acc.Acronym_short_title__c;
            }
            if (acc.Name != null && acc.Name != ''){
                cti.company.companyInformation.companyName = acc.Name;
            }
            if (acc.VAT_number__c != null && acc.VAT_number__c != ''){
                cti.company.companyInformation.taxId = acc.VAT_number__c;
            }
            if (acc.EU_Tax_registered__c != null){
                cti.company.companyInformation.euTaxRegistered = acc.EU_Tax_registered__c ? '1' : '0';
            }
            if (acc.Reporting_Required__c != null){
                cti.company.companyInformation.poRequired = acc.Reporting_Required__c;
            }
            if (acc.Correspondence_Detail__c != null && acc.Correspondence_Detail__c != ''){
                cti.company.companyInformation.preferredMethodOfCorrespondence = acc.Correspondence_Detail__c;
            }
            if (acc.Customer_Type__c != null && acc.Customer_Type__c != ''){
                cti.company.customerType.value = acc.Customer_Type__c;
            }
            
            cti.company.addresses.values = new List<AddressType>();
            for (Address__c addr : acc.Addresses__r){
                AddressType adr = new AddressType();
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
                if (addr.Locality__c != null && addr.Locality__r.Banner_Code__c != null && 
                    addr.Locality__r.Banner_Code__c != ''){
                    adr.locality = addr.Locality__r.Banner_Code__c;
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
                
                cti.company.addresses.values.add(adr);
            }
            
            cti.company.emails.values = new List<EmailType>();
            if(acc.Invoice_Email_Address__c!= null){
                EmailType et = new EmailType();
                et.type = 'Billing';
                et.emailAddress = acc.Invoice_Email_Address__c;
                et.isPrimary = true;
                cti.company.emails.values.add(et);
            }
            cti.company.phones.values = new List<PhoneType>();
            if(acc.Phone != null){
                PhoneType pt = BuildPhone.BuildPhoneTypeDTO(acc.Phone, 'Business', true);
                cti.company.phones.values.add(pt);              
            }
            if(acc.Fax != null){
                PhoneType pt = BuildPhone.BuildPhoneTypeDTO(acc.Fax, 'Fax', false);
                cti.company.phones.values.add(pt);
            }
            
            String jsonRequest = JSON.serialize(cti);
            system.debug(jsonRequest +'Company Profile');
            Http http = new Http();
            //HttpRequest req = BPPIntegrationConfig.callRestService(jsonRequest, 'application/json', endPoint);
            HttpRequest req = BPPIntegrationConfig.callRestService(jsonRequest, 'application/json', endPoint_findmatch);
            
            system.debug('Final JSON: ' + req.getMethod() + ' ' + req.getEndPoint() + 'Accept-Encoding:' + req.getHeader('Accept-Encoding') +'Accept:' + req.getHeader('Accept') + 'Content-Type:' + req.getHeader('Content-Type') + 'tenantId:' + req.getHeader('tenantId') + req.getBody());
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
                    String strResponse = '{"self":"null","httpMethod":"DELETE","errorMessage":"Cannot find Company or Profile Record for the specified Id: 1231231231","errorCode":"PLATFORM-801","transactionId":"A563C5CD-4CA9-B1C6-392A-09377720BFAC"}';
                    res.setStatusCode(200);
                    res.setStatus('Internal Error');
                    res.setBody(strResponse);
                }
            }
            else{
                res = http.send(req);
            }
            system.debug(res.getBody());
            system.debug(res.getStatus());
            
            /* Integration Log */
            Integration_Log__c intg = new Integration_Log__c();
            intg.Request__c =  jsonRequest;
            intg.Response__c = res.getBody();
            intg.Salesforce_ID__c = acc.Id;
            intg.Integration_Type__c = 'Find Matching Company';
            
            String companyProfile;
            if (res.getStatus() == 'OK' && res.getStatusCode() == 200){
                //resp is a JSON string
                JSONParser parser = JSON.createParser(res.getBody());
                while (parser.nextToken() != null) {
                    if ((parser.getCurrentToken() == JSONToken.FIELD_NAME)){
                        String fieldName = parser.getText();
                        parser.nextToken();
                        if(fieldName == 'id') {
                            companyProfile = parser.getText();
                            system.debug('CompanyProfile' + companyProfile);
                            result = 'Success';
                            break;
                        }
                    }
                }
                
                list<Account> chkDupe = [Select id,Profile_Company_ID__c,Name from Account where Profile_Company_ID__c =: companyProfile and Profile_Company_ID__c != null];
                if(chkDupe.size()>0)
                    result = 'Potential duplicate company record. Check existing account:\n\n'+ chkDupe[0].Name;
                
                else if (parser.nextToken() == null) {
                    //insert new company account in profile   
                    HttpRequest req_inst = BPPIntegrationConfig.callRestService(jsonRequest, 'application/json', endPoint_insert);
                
                    system.debug('Final JSON: ' + req_inst.getMethod() + ' ' + req_inst.getEndPoint() + 'Accept-Encoding:' + req_inst.getHeader('Accept-Encoding') +'Accept:' + req_inst.getHeader('Accept') + 'Content-Type:' + req_inst.getHeader('Content-Type') + 'tenantId:' + req_inst.getHeader('tenantId') + req_inst.getBody());
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
                        String strResponse = '{"self":"null","httpMethod":"DELETE","errorMessage":"Cannot find Company or Profile Record for the specified Id: 1231231231","errorCode":"PLATFORM-801","transactionId":"A563C5CD-4CA9-B1C6-392A-09377720BFAC"}';
                          res_inst.setStatusCode(200);
                          res_inst.setStatus('OK');
                          res_inst.setBody(strResponse);
                      }
                    }
                    else{
                        res_inst = http.send(req_inst);
                    }
                    system.debug(res_inst.getBody());
                    system.debug(res_inst.getStatus());                   
                    
                    /* Integration Log */
                    Integration_Log__c intg_inst = new Integration_Log__c();
                    intg_inst.Request__c =  jsonRequest;
                    intg_inst.Response__c = res_inst.getBody();
                    intg_inst.Salesforce_ID__c = acc.Id;
                    intg_inst.Integration_Type__c = 'Insert Company';
                    
                    String companyProfile_inst;
                    if (res_inst.getStatus() == 'OK' && res_inst.getStatusCode() == 200){
        
                        JSONParser parser_inst = JSON.createParser(res_inst.getBody());
                        while (parser_inst.nextToken() != null) {
                            if ((parser_inst.getCurrentToken() == JSONToken.FIELD_NAME)){
                                String fieldName = parser_inst.getText();
                                parser_inst.nextToken();
                                if(fieldName == 'companyId') {   
                                companyProfile_inst = parser_inst.getText();
                                    system.debug('CompanyProfileDebug' + companyProfile_inst);
                                    result = 'Success';
                                    break;
                                }
                            }
                        }
                        //update account with profile id
                        acc.Profile_Company_ID__c = companyProfile_inst;
                        update acc;
                
                    }
                    else{
                        //error handling for insert call
                        JSONParser jParser_inst = JSON.createParser(res_inst.getBody());
                        while(jParser_inst.nextToken() != null){
                            if((jParser_inst.getCurrentToken() == JSONToken.FIELD_NAME)){
                                string fieldN = jParser_inst.getText();
                                jParser_inst.nextToken();
                                if(fieldN == 'errorMessage'){
                                    result = jParser_inst.getText();
                                    system.debug('errorMessage' + result);
                                    break;
                                }
                            }
                        }
                    }
                    insert intg_inst;
                }//end insert new company account
                    
            }
            else{ 
                //error handling for find company call
                JSONParser jParser = JSON.createParser(res.getBody());
                while(jParser.nextToken() !=null){
                    if((jParser.getCurrentToken() == JSONToken.FIELD_NAME)){
                        string fieldN = jParser.getText();
                        jParser.nextToken();
                        if(fieldN == 'errorMessage'){
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
    public static void UpdateCompanyInformation(String strProfileId, String AccountId, String AddressType, Boolean AddressDeleted){
        Account acc = [Select Id, Acronym_short_title__c, Name, VAT_number__c, EU_Tax_registered__c, Reporting_Required__c, 
                                  Correspondence_Detail__c, Customer_Type__c, Profile_Company_ID__c, Industry_Type_SIC__c, Use_This_One__c,
                                  Phone, Invoice_Email_Address__c, Fax,
                                  (Select Id, Type__c, Street_1__c, Street_2__c, Street_3__c, Street_4__c, City__c, State_Province__r.ISO_CODE__c, 
                                  Zip_Postal_Code__c, Lookup_Country__r.ISO_CODE__c, Locality__r.Banner_Code__c, Primary__c From Addresses__r Where Active__c = true) 
                                  From Account Where Id = :AccountId Limit 1];
        string result;
        if (acc != null){
            UpdatecompanyTypeInfo cti = new UpdatecompanyTypeInfo();
            //cti.profileId = strProfileId;
            
            if (acc.Acronym_short_title__c != null && acc.Acronym_short_title__c != ''){
                cti.company.companyInformation.shortName = acc.Acronym_short_title__c;
            }
            if (acc.Name != null && acc.Name != ''){
                cti.company.companyInformation.companyName = acc.Name;
            }
            if (acc.VAT_number__c != null && acc.VAT_number__c != ''){
                cti.company.companyInformation.taxId = acc.VAT_number__c;
            }
            if (acc.EU_Tax_registered__c != null){
                cti.company.companyInformation.euTaxRegistered = acc.EU_Tax_registered__c ? '1' : '0';
            }
            if (acc.Reporting_Required__c != null){
                cti.company.companyInformation.poRequired = acc.Reporting_Required__c;
            }
            if (acc.Correspondence_Detail__c != null && acc.Correspondence_Detail__c != ''){
                cti.company.companyInformation.preferredMethodOfCorrespondence = acc.Correspondence_Detail__c;
            }
            if (acc.Customer_Type__c != null && acc.Customer_Type__c != ''){
                cti.company.customerType.value = acc.Customer_Type__c;
            }
            
            cti.company.addresses.values = new List<AddressType>();
            for (Address__c addr : acc.Addresses__r){
                AddressType adr = new AddressType();
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
                if (addr.Locality__c != null && addr.Locality__r.Banner_Code__c != null && 
                    addr.Locality__r.Banner_Code__c != ''){
                    adr.locality = addr.Locality__r.Banner_Code__c;
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
                
                cti.company.addresses.values.add(adr);
            }
            
            cti.company.emails.values = new List<EmailType>();
            if(acc.Invoice_Email_Address__c!= null){
                EmailType et = new EmailType();
                et.type = 'Billing';
                et.emailAddress = acc.Invoice_Email_Address__c;
                et.isPrimary = true;
                cti.company.emails.values.add(et);
            }
            cti.company.phones.values = new List<PhoneType>();
            if(acc.Phone != null){
                PhoneType pt = BuildPhone.BuildPhoneTypeDTO(acc.Phone, 'Business', true);
                cti.company.phones.values.add(pt);              
            }
            if(acc.Fax != null){
                PhoneType pt = BuildPhone.BuildPhoneTypeDTO(acc.Fax, 'Fax', false);
                cti.company.phones.values.add(pt);
            }
            /*cti.company.identities.values = new List<IdentityType>(); 
            IdentityType it = new IdentityType();
            it.value = strProfileId;
            it.type = 'ProfileID';
            if (acc.Use_This_One__c != null){
                it.active = acc.Use_This_One__c;
            }
            cti.company.identities.values.add(it);
            */
            
            //if update is from an address being deleted
            if(AddressDeleted == true){
                cti.deleteEntity = new DeleteEntityType();  
                DeleteAddressType adr = new DeleteAddressType();
                adr.type = AddressType;
                cti.deleteEntity.addresses.values.add(adr);  
            }
                     
            String jsonRequest = JSON.serialize(cti);
            system.debug(jsonRequest);
            Http http = new Http();
            HttpRequest req = BPPIntegrationConfig.callUpdateRestService(jsonRequest, 'application/json', endPoint_update +'/'+ strProfileId);
            
            system.debug('Final JSON: ' + req.getMethod() + ' ' + req.getEndPoint() + 'Accept-Encoding:' + req.getHeader('Accept-Encoding') +'Accept:' + req.getHeader('Accept') + 'Content-Type:' + req.getHeader('Content-Type') + 'tenantId:' + req.getHeader('tenantId') + req.getBody());
            system.debug(req.toString());
            HttpResponse res = null;
            if (Test.isRunningTest()){
                res = new HttpResponse();
                if (bFailSIS){
                    String strResponse = '{"companyId":"bfb463f9-b4c2-4ce4-a429-05818b8cae1f","operation":"UPDATE","identities":{"values":[{"id":"92a41ad1-6c4d-4361-b16f-4b43cdd7af4f","value":"BP0015638","type":"BANNER","active":true}';
                    res.setStatusCode(200);
                    res.setStatus('OK');
                    res.setBody(strResponse);
                }
                else{
                    String strResponse = '{"self":"null","httpMethod":"DELETE","errorMessage":"Cannot find Company or Profile Record for the specified Id: 1231231231","errorCode":"PLATFORM-801","transactionId":"A563C5CD-4CA9-B1C6-392A-09377720BFAC"}';
                    res.setStatusCode(200);
                    res.setStatus('Internal Error');
                    res.setBody(strResponse);
                }
            }
            else{
                res = http.send(req);
            }
            system.debug(res.getBody());
            system.debug(res.getStatus());
            
            /* Integration Log */
            Integration_Log__c intg = new Integration_Log__c();
            intg.Request__c =  jsonRequest;
            intg.Response__c = res.getBody();
            intg.Salesforce_ID__c = acc.Id;
            intg.Integration_Type__c = 'Update Existing Company';
            
            String companyProfile;
            if (res.getStatus() == 'OK' && res.getStatusCode() == 200){
                //resp is a JSON string
                JSONParser parser = JSON.createParser(res.getBody());
                while (parser.nextToken() != null) {
                    if ((parser.getCurrentToken() == JSONToken.FIELD_NAME)){
                        String fieldName = parser.getText();
                        parser.nextToken();
                        if(fieldName == 'companyId') {
                            companyProfile = parser.getText();
                            system.debug('CompanyProfile' + companyProfile);
                            result = 'Success';
                            break;
                        }
                    }
                }
            }
            else{
                JSONParser jParser = JSON.createParser(res.getBody());
                while(jParser.nextToken() !=null){
                    if((jParser.getCurrentToken() == JSONToken.FIELD_NAME)){
                        string fieldN = jParser.getText();
                        jParser.nextToken();
                        if(fieldN == 'errorMessage'){
                            result = jParser.getText();
                            system.debug('errorMessage' + result);
                            break;
                        }
                    }
                }
            }
            insert intg;
        }
        return;
    }
}