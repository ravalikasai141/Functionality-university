@RestResource(urlMapping='/v1.0/UpdateDemographics')
global with sharing class UpdateDemographics {
    
    global class Response {
        global String status { get; set; }
        global String code { get; set; }
        global String result { get; set; }
        
        
        public Response(String status, String code, String result) {
            this.status = status;
            this.code = code;
            this.result=result;
            
        }
    }
     
    global class StudentDTO {
        global Contact student;
        global Account studentAcc;
        global list<Address__c> addresses;
        global list<Qualification__c> qualifications;    
    }
    
    @HttpPost
    global static Response doPost(List<StudentDTO> stdDTO) {
         return ProcessDemographicUpdate(stdDTO);
    }
    
    global static Response ProcessDemographicUpdate(List<StudentDTO> stdDTO) {
        // Get List of Contacts
        map<String, Contact> contactsFromJSON = new map<String, Contact>();
        // Get List of Accounts
        map<String, Account> accountsFromJSON = new map<String, Account>();
        // Get List of addresses for contacts
        map<String, list<Address__c>> addressFromJSON = new map<String, list<Address__c>>();
        // Get List of Qualifications
        Map<String, list<Qualification__c>> qualificationFromJSON = new Map<String, list<Qualification__c>>();
        
        // Loop through JSON
        list<Account> accountList = new list<Account>();
        list<Address__c> addressList;
        list<Qualification__c> qualificationList;
        String Fresponse;
        try{
            list<String> contactFields = Util.getUpdateableFields('Contact');
            list<String> accountFields = Util.getUpdateableFields('Account');
            Set<String> includedFields = new Set<String>();
            String contactQuery = 'SELECT Id';
            String accountQuery = 'SELECT Id ';
        
            for (StudentDTO stDTO : stdDTO){
                if (stDTO == null || stDTO.student == null || stDTO.student.PS_Profile_Services_ID__c == null || 
                    stDTO.student.PS_Profile_Services_ID__c == ''){
                    writeLog(stdDTO, accountList, 'Failure 1');
                    return new Response('Failure 1 : stDTO, student or the Profile_Service_Id was null. JSON failed content validation. Please review and try again.',
                    '400',
                    'FALSE');
                }
                contactsFromJSON.put(stDTO.student.PS_Profile_Services_ID__c, stDTO.student);
                if (stDTO.studentAcc != null){
                    accountsFromJSON.put(stDTO.student.PS_Profile_Services_ID__c, stDTO.studentAcc);
                }
                if (stDTO.addresses != null){
                    addressFromJSON.put(stDTO.student.PS_Profile_Services_ID__c, stDTO.addresses);
                }
                if (stDTO.qualifications != null){
                    qualificationFromJSON.put(stDTO.student.PS_Profile_Services_ID__c, stDTO.qualifications);
                }
                for (String field : contactFields) {
                    if (!includedFields.contains(field)) {
                        if (stDTO.student.get(field) != null) {
                            contactQuery += ', ' + field;
                            includedFields.add(field);
                        }
                    }
                }
                Set<String> accFields = new Set<String>();
                for (String field : accountFields){
                    if (stDTO.studentAcc == null){
                        break;
                    }
                    if (stDTO.studentAcc.get(field) != null){
                        accFields.add(field);
                    }
                }
                if (accFields.size() > 0){
                    List<String> tempList = new List<String>();
                    tempList.addAll(accFields);
                    accountQuery += ', PS_Profile_Services_ID__pc, ' + String.join(tempList, ',');
                }
            }
        
            Set<String> contactProfileSet = contactsFromJSON.keySet();
            contactQuery += ' , RecordTypeId FROM Contact WHERE PS_Profile_Services_ID__c IN :contactProfileSet';
            accountQuery += ' From Account Where PS_Profile_Services_ID__pc IN :contactProfileSet';
            list<Contact> realContactList = Database.query(contactQuery);
            list<Account> realAccountList = Database.query(accountQuery);
            String tmRecordTypeId = Schema.Sobjecttype.Contact.getRecordTypeInfosByName().get('Training Manager').getRecordTypeId();
            list<Contact> contactWithAccountIdList = [Select Id, RecordTypeId, AccountId From Contact Where PS_Profile_Services_ID__c IN :contactProfileSet];
            map<Id, Id> contactToAccountIdMap = new Map<Id, Id>();
            Set<Id> accountIds = new Set<Id>();
            Set<Id> contactIds = new Set<Id>();
            Set<Id> cntIds = new Set<Id>();
            for (Contact c : contactWithAccountIdList) {
                if(c.RecordTypeId == tmRecordTypeId){
                    contactIds.add(c.Id);
                    contactToAccountIdMap.put(c.Id, c.Id);
                }
                else{
                    accountIds.add(c.AccountId);
                    cntIds.add(c.Id);
                    contactToAccountIdMap.put(c.Id, c.AccountId);
                }
            }
            
            map<Id, list<Qualification__c>> qualificationMap = new Map<Id, list<Qualification__c>>();
            accountList = Database.query(Util.getAllFieldsSOQL('Account', 'Id IN :accountIds'));
            Map<Id, Account> accountMap = new Map<Id, Account>();
            for (Account acc : accountList) {
                accountMap.put(acc.Id, acc);
            }
            list<String> addressFields = Util.getUpdateableFields('Address__c');
            map<Id, list<Address__c>> addressMap = new Map<Id, list<Address__c>>();
            if(accountIds.size()>0){
                addressList = Database.query(Util.getAllFieldsSOQL('Address__c', 'Student__c IN :accountIds'));
                system.debug('Account addresses: ' + addressList.size());
                for (Address__c add : addressList) {
                    if (addressMap.containsKey(add.Student__c)){
                        addressMap.get(add.Student__c).add(add);
                    }
                    else{
                        list<Address__c> lstAdd = new list<Address__c>();
                        lstAdd.add(add);
                        addressMap.put(add.Student__c, lstAdd);
                    }
                }
                
                qualificationList = [Select Id, Student__c, Institution__c, Student_Institute__c, Examing_Body__c, Mode__c,
                                     Tariff_Points__c, Description__c, Subject__c, Type__c, Status__c, Penultimate_Year_Grade__c,
                                     Grade__c, Start_Date__c, Qualification_Date__c, Record_Source__c From Qualification__c 
                                     Where Student__c IN :cntIds];
                for (Qualification__c qlf : qualificationList) {
                    if (qualificationMap.containsKey(qlf.Student__c)){
                        qualificationMap.get(qlf.Student__c).add(qlf);
                    }
                    else{
                        list<Qualification__c> lstqlf = new list<Qualification__c>();
                        lstqlf.add(qlf);
                        qualificationMap.put(qlf.Student__c, lstqlf);
                    }
                }
            }
            if(contactIds.size()>0){
                addressList = Database.query(Util.getAllFieldsSOQL('Address__c', 'Training_Manager__c IN :contactIds'));
                System.debug('Training Manager addresses: ' + addressList.size());
                for (Address__c add : addressList) {
                    if (addressMap.containsKey(add.Training_Manager__c)){
                        addressMap.get(add.Training_Manager__c).add(add);
                    }
                    else{
                        List<Address__c> lstAdd = new List<Address__c>();
                        lstAdd.add(add);
                        addressMap.put(add.Training_Manager__c, lstAdd);
                    }
                }
            }
            map<String, Id> countryCode = new map<String, Id>();
            list<country_list__c> countries = [Select Id, ISO_CODE__c From country_list__c Where ISO_CODE__c != '' AND 
                                               ISO_CODE__c != null];
            for (country_list__c cntry : countries){
                countryCode.put(cntry.ISO_CODE__c.toUpperCase(), cntry.Id);
            }
            map<String, Id> stateCode = new map<String, Id>();
            list<State_Province__c> states = [Select Id, ISO_Code__c From State_Province__c Where ISO_Code__c != '' AND 
                                              ISO_Code__c != null];
            for (State_Province__c stt : states){
                stateCode.put(stt.ISO_Code__c.toUpperCase(), stt.Id);
            }
            map<String, Id> localityCode = new map<String, Id>();
            list<Locality__c> localities = [Select Id, Banner_Code__c From Locality__c Where Banner_Code__c != '' AND 
                                            Banner_Code__c != null];
            for (Locality__c lcty : localities){
                localityCode.put(lcty.Banner_Code__c.toUpperCase(), lcty.Id);
            }
            
            list<Address__c> insertAddress = new list<Address__c>();
            list<Address__c> updateAddress = new list<Address__c>();
            list<Address__c> deleteaddress = new list<Address__c>();
            list<Qualification__c> insertQualification = new list<Qualification__c>();
            list<Qualification__c> updateQualification = new list<Qualification__c>();
            
            Set<String> realProfileIds = new Set<String>();
            list<Schema.PicklistEntry> plistValues = Contact.SFDC_Ethnic_Code_Select__c.getDescribe().getPicklistValues();
            for (Contact ct : realContactList){
                list<Address__c> addressNotFound = new list<Address__c>();
                System.debug('readContactList size: ' + realContactList.size());
                Contact newContact = contactsFromJSON.get(ct.PS_Profile_Services_ID__c);
                realProfileIds.add(ct.PS_Profile_Services_ID__c);
                if (newContact == null)
                    return new Response('Failure 2 : Contact was null due to PS_Profile_Services_ID__c being null. JSON failed content validation. Please review and try again.',
                    '400',
                    'FALSE');
            
                for (String field : contactFields) {
                    if (field.toLowerCase().equals('id')) continue;
                
                    if (newContact.get(field) != null) {
                        /*if (field.equalsIgnoreCase('SFDC_Ethnic_Code_Select__c')){
                            for (Schema.PicklistEntry pe : plistValues){
                                if (pe.getLabel().startsWith(newContact.SFDC_Ethnic_Code_Select__c + '~')){
                                    newContact.SFDC_Ethnic_Code_Select__c = pe.getValue();
                                    break;
                                }
                            }
                            ct.put(field, newContact.get(field));
                        }
                        else{
                            system.debug('FROM DTO: ' + field + ' -> ' + newContact.get(field));
                            ct.put(field, newContact.get(field));
                        }*/
                        if (!field.equalsIgnoreCase('SFDC_Ethnic_Code_Select__c')){
                            system.debug('FROM DTO: ' + field + ' -> ' + newContact.get(field));
                            ct.put(field, newContact.get(field));
                        }
                    }
                }
                
                list<Address__c> newAddressList = new list<Address__c>();
                list<Address__c> existingAddress = new list<Address__c>();
                if(addressFromJSON.containskey(ct.PS_Profile_Services_ID__c)){
                    newAddressList = addressFromJSON.get(ct.PS_Profile_Services_ID__c);
                    system.debug('Contact ' + ct.Id + ' new addresses: ' + newAddressList.size());
                }
                if(contactToAccountIdMap.containskey(ct.Id)){
                    if(addressMap.containskey(contactToAccountIdMap.get(ct.Id))){
                        existingAddress = addressMap.get(contactToAccountIdMap.get(ct.Id));
                    }
                }
                if (existingAddress != null){
                    system.debug('Contact ' + ct.Id + ' existing addresses: ' + existingAddress.size());
                }
                Set<Address__c> foundAddress = new Set<Address__c>();
                for (Address__c newAdrs : newAddressList){
                    Boolean bFound = false;
                    if (existingAddress != null && existingAddress.size() > 0){
                        // update address
                        for (Address__c adrs : existingAddress){
                            if (newAdrs.Type__c.equalsIgnoreCase(adrs.Type__c)){
                                for(String adrsField : addressFields){
                                    if (newAdrs.get(adrsField) != null) {
                                        if (adrsField.equalsIgnoreCase('id')) continue;
                                        system.debug('FROM DTO: ' + adrsField + ' -> ' + newAdrs.get(adrsField));
                                        if (adrsField.equalsIgnoreCase('Text_Country__c')){
                                            if (countryCode.containsKey(newAdrs.Text_Country__c.toUpperCase())){
                                                //newAdrs.Lookup_Country__c = countryCode.get(newAdrs.Text_Country__c.toUpperCase());
                                                //***Line below added to fix issue with country lookup field not populating/updating (CRM-6273)***
                                                adrs.Lookup_Country__c = countryCode.get(newAdrs.Text_Country__c.toUpperCase());   
                                            }
                                            //adrs.put(adrsField, newAdrs.Lookup_Country__c);
                                        }
                                        else if (adrsField.equalsIgnoreCase('Text_State__c')){
                                            if (stateCode.containsKey(newAdrs.Text_State__c.toUpperCase())){
                                                newAdrs.State_Province__c = stateCode.get(newAdrs.Text_State__c.toUpperCase());
                                            }
                                            adrs.put(adrsField, newAdrs.State_Province__c);
                                        }
                                        else if (adrsField.equalsIgnoreCase('Text_Locality__c')){
                                            if (localityCode.containsKey(newAdrs.Text_Locality__c.toUpperCase())){
                                                newAdrs.Locality__c = localityCode.get(newAdrs.Text_Locality__c.toUpperCase());
                                            }
                                            adrs.put(adrsField, newAdrs.Locality__c);
                                        }
                                        else{
                                            adrs.put(adrsField, newAdrs.get(adrsField));
                                        }
                                    }
                                }
                                updateAddress.add(adrs);
                                foundAddress.add(adrs);
                                bFound = true;
                                break;
                            }
                        }
                        if (bFound == false)
                        addressNotFound.add(newAdrs);    
                    }
                    else{
                        addressNotFound.add(newAdrs);
                    }
                }
                if (existingAddress != null && existingAddress.size() > 0){
                    for (Address__c adrs : existingAddress) {
                        if (!foundAddress.contains(adrs)) {
                            deleteaddress.add(adrs);
                        }
                    }
                }
                // insert address
                for (Address__c newAdrs : addressNotFound){
                    Address__c adrs = new Address__c();
                    adrs = newAdrs;
                    if(ct.RecordTypeId == tmRecordTypeId){
                        adrs.Training_Manager__c = contactToAccountIdMap.get(ct.Id);
                    }
                    else{
                        adrs.Student__c = contactToAccountIdMap.get(ct.Id);
                    }
                    if (countryCode.containsKey(adrs.Text_Country__c.toUpperCase())){
                        adrs.Lookup_Country__c = countryCode.get(adrs.Text_Country__c.toUpperCase());
                    }
                    if (stateCode.containsKey(adrs.Text_State__c.toUpperCase())){
                        adrs.State_Province__c = stateCode.get(adrs.Text_State__c.toUpperCase());
                    }
                    if (localityCode.containsKey(adrs.Text_Locality__c.toUpperCase())){
                        adrs.Locality__c = localityCode.get(adrs.Text_Locality__c.toUpperCase());
                    }            
                    insertAddress.add(adrs);
                }
                list<Qualification__c> newQualificationList = new list<Qualification__c>();
                list<Qualification__c> existingqualification = new list<Qualification__c>();
                if(qualificationFromJSON.containskey(ct.PS_Profile_Services_ID__c)){
                    newQualificationList = qualificationFromJSON.get(ct.PS_Profile_Services_ID__c);
                }
                //system.debug('Contact ' + ct.Id + ' new qualification: ' + newQualificationList.size());
                if(qualificationMap.containskey(ct.Id)){
                    existingqualification = qualificationMap.get(ct.Id);
                }
                list<Qualification__c> qualificationNotFound = new list<Qualification__c>();
                system.debug('qualificationList' + qualificationList);
                system.debug('qualificationMap' + qualificationMap);
                system.debug('Existingqualification' + existingqualification);
                system.debug('Newqualification' + newQualificationList);
                
                for (Qualification__c newqlfs : newQualificationList){
                    Boolean bqFound = false;
                    if (existingqualification != null && existingqualification.size() > 0){
                        // update qualification
                        for (Qualification__c qlfs : existingqualification){
                            system.debug('Checking Values' + newqlfs.Examing_Body__c.equalsIgnoreCase(qlfs.Examing_Body__c));
                            if (newqlfs.Examing_Body__c.equalsIgnoreCase(qlfs.Examing_Body__c)){
                                qlfs.Student_Institute__c = newqlfs.Student_Institute__c;
                                updateQualification.add(qlfs);
                                bqFound = true;
                                break;
                            }
                        }
                        if (bqFound == false)
                        qualificationNotFound.add(newqlfs);    
                    }
                    else{
                        qualificationNotFound.add(newqlfs);
                    }
                }
                system.debug('qualificationNotFound' + qualificationNotFound);
                if(qualificationNotFound.size()>0){
                    for (Qualification__c newqlfs : qualificationNotFound){
                        Qualification__c qlfs = new Qualification__c();
                        qlfs = newqlfs;
                        if(qlfs.Subject__c == null || qlfs.Subject__c == ''){
                            qlfs.Subject__c = 'TBD';
                        }
                        qlfs.Student__c = ct.Id;
                        insertQualification.add(qlfs);
                    }
                }
            }
            if (!realProfileIds.containsAll(contactProfileSet)){
                writeLog(stdDTO, accountList, 'Failure 3 ');
                return new Response('Failure 3 : Contact or retireved Profileid was null causing an inability to update the record. JSON failed content validation. Please review and try again.',
                '400',
                'FALSE');
            }
            
            if (accountsFromJSON.size()>0){
                for (account ac : realAccountlist){
                    Account newAccount = accountsFromJSON.get(ac.PS_Profile_Services_ID__pc);
                    for (String field : accountFields) {
                        if (field.toLowerCase().equals('id')) continue;
                
                        if (newAccount.get(field) != null) {
                            system.debug('FROM DTO: ' + field + ' -> ' + newAccount.get(field));
                            ac.put(field, newAccount.get(field));
                        }
                    }
                }
            }
            
            update realContactList;
            if (realAccountList.size() > 0){
                update realAccountList;
            }
            update updateAddress;
            insert insertAddress;
            delete deleteaddress;
            update updateQualification;
            insert insertQualification;
            writeLog(stdDTO, accountList, 'Success : Update of demographics was successful.');
            return new Response('Success',
                    '201',
                    'TRUE');
        }
        catch(Exception e) {
            Fresponse =  'Failure' + ':\n' + e.getTypeName() + ' - ' + e.getMessage();
            writeLog(stdDTO, accountList, 'Failure' + ':\n' + e.getLineNumber() + ': ' + e.getTypeName() + ' - ' + e.getMessage() + '\n' + e.getStackTraceString());
            return new Response('Failure 4 : ' + Fresponse,
                    '500',
                    'FALSE');
        }
    }
    
    private static void writeLog(list<UpdateDemographics.StudentDTO> stdDTO, list<Account> accountList, String Status){
        Integration_Log_Incoming__c log = new Integration_Log_Incoming__c();
        log.Request_Body__c = JSON.serialize(stdDTO);
        log.Request_Date__c = Datetime.now();
        log.Service_Name__c = 'UpdateDemographics';
        
        String details = Status + ':\n';
        for (Account acc : accountList) {
            details += 'ACCOUNT ID: ' + acc.Id + '\n';
            details += 'BEFORE\n---------------\n';
            details += JSON.serialize(acc);
            details += '\n---------------\n';   
        }
        log.Details__c = details;
        insert log;
    }
    
    @isTest
    public static void unitTest1(){
        List<UpdateDemographics.StudentDTO> stdDTO = new List<UpdateDemographics.StudentDTO>();
        UpdateDemographics.StudentDTO std = new UpdateDemographics.StudentDTO();
        country_list__c cntry = CreateTestData.createCountry1();
        State_Province__c stt = new State_Province__c(Name = 'Unit TestState', ISO_Code__c = '1234');
        insert stt;
        Locality__c lct = new Locality__c(Name = 'Unit TestState', Banner_Code__c = '12345');
        insert lct;
        
        Account a1 = new Account();
        a1.Name = 'Test Company';
        a1.Phone = '4325768903';
        a1.Account_Category__c = 'Customer - Middle Market';
        a1.Sector_Level_1__c = 'Financial Services';
        a1.Sector_Level_2__c = 'Accountancy';
        a1.Acronym_short_title__c = 'Test'; 
        a1.VAT_number__c = '1234567890';
        a1.EU_Tax_registered__c = true;
        a1.Customer_Type__c = 'Key Client';
        a1.Legal_Entity__c = 'UC~COL';
        a1.Industry_Type_SIC__c = 'B~ Mining and quarrying';
        a1.Use_This_One__c = true;
        a1.RecordTypeId=Schema.sObjectType.Account.getRecordTypeInfosByName().get('Business Development Account').getRecordTypeId();
        a1.Profile_Company_ID__c = '1234f567-bc23-42e8-924c-asdf12345678';
        a1.SIS_Company_ID__c = 'BP0015424';
        a1.Sponsor_Contact__c = 'Term';
        a1.Invoice_Method__c = 'Email';
        a1.Invoice_Delivery__c = 'Email';
        a1.Booking_Requirements__c = 'Passport';
        a1.Correspondence_Detail__c = 'Email';
        a1.Payment_Terms__c = '40 Days';
        a1.Credit_Limit__c = 7500;
        a1.Website = 'www.test.com';
        a1.Discount__c = 25;
        a1.Reporting_Required__c = true;
        insert a1;
        
        List<Address__c> adds = new List<Address__c>();
        Address__c add = new Address__c();
        add.Type__c = 'Home';
        add.Street_1__c = '123 S Test Dr';
        add.Street_2__c = '123';
        add.Street_3__c = '12';
        add.Street_4__c = '1';
        add.City__c = 'Chicago';
        add.State_Province__c = stt.Id;
        add.Locality__c = lct.Id;
        add.Zip_Postal_Code__c = '12345';
        add.Lookup_Country__c = cntry.Id;
        add.Student__c = a1.Id;
        insert add;
        adds.add(add);
        
        Contact c = new Contact();
        c.RecordTypeId = Schema.sObjectType.Contact.getRecordTypeInfosByName().get('Training Manager').getRecordTypeId();
        c.LastName = 'testc';
        c.FirstName = 'testfi';
        c.AccountId = a1.Id;
        c.Phone = '3126608787';
        c.Email = 'testc@con.com';
        c.Birthdate = Date.newInstance(1986, 4, 5);
        c.Preferred_Email__c = 'Personal';
        c.Personal_Email__c ='john@johnyy.com';
        c.PS_Profile_Services_ID__c = '12300567-bc23-42e8-924c-asdf12345678';
        c.Active__c = false;
        insert c;
        
        std.student = c;
        std.studentAcc = a1;
        std.addresses = adds;
        
        UpdateDemographics.Response res = UpdateDemographics.doPost(stdDTO);
    } 
    
    @isTest
    public static void unitTest2(){
        List<UpdateDemographics.StudentDTO> stdDTO = new List<UpdateDemographics.StudentDTO>();
        UpdateDemographics.StudentDTO std = new UpdateDemographics.StudentDTO();
        Contact con = new Contact();
        con.PS_Profile_Services_ID__c = '123456789-abcd-1234-ab9876-987654321';
        std.student = con;
        
        Account Acc = new Account();
        acc.AR_Student_Finance_England_SFE__c = 'AAAA12345678A';
        std.studentAcc = acc;
        stdDTO.add(std);
        
        UpdateDemographics.Response res = UpdateDemographics.doPost(stdDTO);
    }
    
    @isTest
    public static void unitTest3(){
        List<UpdateDemographics.StudentDTO> stdDTO = new List<UpdateDemographics.StudentDTO>();
        UpdateDemographics.StudentDTO std = new UpdateDemographics.StudentDTO();
        List<Address__c> adds = new List<Address__c>();
        Address__c add1 = new Address__c();
        add1.Type__c = 'Billing';
        add1.Street_1__c = '123 S Test Dr';
        add1.Street_2__c = '12345';
        add1.Street_3__c = '1234';
        add1.Street_4__c = '123';
        add1.City__c = 'Test City';
        add1.Text_Locality__c = '12345';
        add1.Text_State__c = '1234';
        add1.Zip_Postal_Code__c = '12345';
        add1.Text_Country__c = '123';
        adds.add(add1);
        stdDTO.add(std);
        
        UpdateDemographics.Response res = UpdateDemographics.doPost(stdDTO);
    }
    
    @isTest
    public static void unitTest4(){
        country_list__c cntry = CreateTestData.createCountry1();
        State_Province__c stt = new State_Province__c(Name = 'Unit TestState', ISO_Code__c = '1234');
        insert stt;
        Locality__c lct = new Locality__c(Name = 'Unit TestState', Banner_Code__c = '12345');
        insert lct;
        
        Account a1 = new Account();
        a1.Name = 'Test Company';
        a1.Phone = '4325768903';
        a1.Account_Category__c = 'Customer - Middle Market';
        a1.Sector_Level_1__c = 'Financial Services';
        a1.Sector_Level_2__c = 'Accountancy';
        a1.Acronym_short_title__c = 'Test'; 
        a1.VAT_number__c = '1234567890';
        a1.EU_Tax_registered__c = true;
        a1.Customer_Type__c = 'Key Client';
        a1.Legal_Entity__c = 'UC~COL';
        a1.Industry_Type_SIC__c = 'B~ Mining and quarrying';
        a1.Use_This_One__c = true;
        a1.RecordTypeId=Schema.sObjectType.Account.getRecordTypeInfosByName().get('Business Development Account').getRecordTypeId();
        a1.Profile_Company_ID__c = '1234f567-bc23-42e8-924c-asdf12345678';
        a1.SIS_Company_ID__c = 'BP0015424';
        a1.Sponsor_Contact__c = 'Term';
        a1.Invoice_Method__c = 'Email';
        a1.Invoice_Delivery__c = 'Email';
        a1.Booking_Requirements__c = 'Passport';
        a1.Correspondence_Detail__c = 'Email';
        a1.Payment_Terms__c = '40 Days';
        a1.Credit_Limit__c = 7500;
        a1.Website = 'www.test.com';
        a1.Discount__c = 25;
        a1.Reporting_Required__c = true;
        insert a1;
        
        Address__c add = new Address__c();
        add.Type__c = 'Home';
        add.Street_1__c = '123 S Test Dr';
        add.Street_2__c = '123';
        add.Street_3__c = '12';
        add.Street_4__c = '1';
        add.City__c = 'Chicago';
        add.State_Province__c = stt.Id;
        add.Locality__c = lct.Id;
        add.Zip_Postal_Code__c = '12345';
        add.Lookup_Country__c = cntry.Id;
        add.Student__c = a1.Id;
        insert add;
        
        Contact c = new Contact();
        c.RecordTypeId = Schema.sObjectType.Contact.getRecordTypeInfosByName().get('Training Manager').getRecordTypeId();
        c.LastName = 'testc';
        c.FirstName = 'testfi';
        c.AccountId = a1.Id;
        c.Phone = '3126608787';
        c.Email = 'testc@con.com';
        c.Birthdate = Date.newInstance(1986, 4, 5);
        c.Preferred_Email__c = 'Personal';
        c.Personal_Email__c ='john@johnyy.com';
        c.PS_Profile_Services_ID__c = '12300567-bc23-42e8-924c-asdf12345678';
        c.Active__c = false;
        insert c;
        
        Address__c add1 = new Address__c();
        add1.Type__c = 'Home';
        add1.Street_1__c = '123 S Test Dr';
        add1.Street_2__c = '123';
        add1.Street_3__c = '12';
        add1.Street_4__c = '1';
        add1.City__c = 'Chicago';
        add1.State_Province__c = stt.Id;
        add1.Locality__c = lct.Id;
        add1.Zip_Postal_Code__c = '12345';
        add1.Lookup_Country__c = cntry.Id;
        add1.Training_Manager__c = c.Id;
        insert add1;
        
        List<UpdateDemographics.StudentDTO> stdDTO = new List<UpdateDemographics.StudentDTO>();
        UpdateDemographics.StudentDTO std = new UpdateDemographics.StudentDTO();
        Contact con1 = new Contact();
        con1.PS_Profile_Services_ID__c = '12300567-bc23-42e8-924c-asdf12345678';
        con1.SFDC_Ethnic_Code_Select__c = '15';
        std.student = con1;
        std.studentAcc = a1;
        
        List<Address__c> adds = new List<Address__c>();
        Address__c add2 = new Address__c();
        add2.Type__c = 'Billing';
        add2.Street_1__c = '123 S Test Dr';
        add2.Street_2__c = '12345';
        add2.Street_3__c = '1234';
        add2.Street_4__c = '123';
        add2.City__c = 'Test City';
        add2.Text_Locality__c = '12345';
        add2.Text_State__c = '1234';
        add2.Zip_Postal_Code__c = '12345';
        add2.Text_Country__c = '123';
        adds.add(add2);
        std.addresses = adds;
        
        List<Qualification__c> qlfs = new List<Qualification__c>();
        Qualification__c qlf1 = new Qualification__c();
        qlf1.Examing_Body__c = 'ACCA';
        qlf1.Student_Institute__c = '1234567890';
        qlf1.Student__c = c.Id;
        qlfs.add(qlf1);
        std.qualifications = qlfs;
        
        stdDTO.add(std);
            
        UpdateDemographics.Response res = UpdateDemographics.doPost(stdDTO);
    }
}