@RestResource(urlMapping='/v1.0/CreateStudentAccount/*')

/*
{
    "stdDTO": [
        {
            "coachProfileId": "fbb4f6be-0d0a-4a3c-8136-c61322ec4c2b",
            "student": {
                "attributes": {
                    "type": "Account"
                },
                "FirstName": "Joey",
                "LastName": "JoBomber",
                "Middle_Name__pc": "James",
                "Preferred_First_Name__pc": "Joe",
                "Salutation": "Mr.",
                "AA_Suffix__pc": "III",
                "PersonTitle": "",
                "PersonBirthdate": "1979-03-23",
                "Intake__pc": "2014-03-23",
                "Business_Unit__pc": "",
                "Cost_Centre_Number__pc": "",
                "Student_Type__pc": "Domestic",
                "Gender__pc": "Male",
                "Legal_Entity__c": "",
                "VAT_Code__pc": "",
                "Work_Phone__pc": "",
                "PersonMobilePhone": "",
                "PersonOtherPhone": "",
                "PersonHomePhone": "",
                "Preferred_Phone__pc": "",
                "Home_Phone__pc": "555-555-5555",
                "Preferred_Phone__pc": "555-555-5555",
                "PS_Profile_Services_ID__pc": "fbb4f6be-0d0a-4a3c-8136-c61322ec4c2b",
                "Other_Email__pc": "JJJ@gmail.com",
                "BNR_Banner_ID__pc": "BP0038331",
                "Personal_Email__pc": "",
                "Work_Email__pc": "",
                "BPP_Email__pc": "",
                "Billing_Email__pc": "",
                "Preferred_email__pc": "JJJ@gmail.com"
            },
            "addresses": [
                {
                    "attributes": {
                        "type": "Address__c"
                    },
                    "Zip_Postal_Code__c": "",
                    "Primary__c": "",
                    "City__c": "PHOENIX",
                    "Zip_Postal_Code__c": "1714452",
                    "Text_Country__c": "USA",
                    "Text_State__c": "US-MS",
                    "Text_Locality__c": "",
                    "Type__c": "Mailing",
                    "Street_1__c": "ChangedAgn",
                    "Street_2__c": "Prt323r",
                    "Street_3__c": "Prnt333r",
                    "Street_4__c": "Homme3me3enex2 4ur STREET"
                },
                {
                    "attributes": {
                        "type": "Address__c"
                    },
                    "Primary__c": "",
                    "City__c": "PHOENIX",
                    "Zip_Postal_Code__c": "1714462",
                    "Text_Country__c": "USA",
                    "Text_State__c": "US-MS",
                    "Text_Locality__c": "",
                    "Type__c": "Billing",
                    "Street_1__c": "123",
                    "Street_2__c": "1233 ",
                    "Street_3__c": "111222",
                    "Street_4__c": "123 2 STREET"
                }
            ]
        }
    ]
}

*/

global with sharing class CreateStudentAccount {
    
    global class Response 
    {
        global String status { get; set; }
        global String code { get; set; }
        global String result { get; set; }
        global String id { get; set; }
        
        public Response(String status, String code, String result, String accountId) 
        {
            this.status = status;
            this.code = code;
            this.result=result;
            this.id=accountId;
        }
    }
    
    global class StudentDTO {
        public String coachProfileId;
        public Account student;
        public list<Address__c> addresses;
        public SponsorshipDTO sponsor;
        public list<Qualification__c> qualifications;      
    }
    
    global class SponsorshipDTO {
        public string CompanyProfileId;
        public string TrainingManagerProfileId;
    }
    
    @HttpPost
    global static Response doPost(List<StudentDTO> stdDTO) {
        return ProcessStudentAccount(stdDTO);
    }
    
    global static Response ProcessStudentAccount(List<StudentDTO> stdDTO) {
        String status = 'Success';
        String LogStatus;
        String Fresponse;
        String accountId = '0';
        String code = '201';
        String result = 'TRUE';
        RestResponse res = RestContext.response;
        res.statusCode = 200;
        
        
        try {
            Set<String> uniqueprofileIds = new Set<String>();
            for(StudentDTO stDTO: stdDTO){
                if(stDTO.student != null){
                    uniqueprofileIds.add(stDTO.student.PS_Profile_Services_ID__pc);
                }
            }
            list<Account> uniqueaccountList = [Select Id, PS_Profile_Services_ID__pc, Profile_Company_ID__c From Account Where (PS_Profile_Services_ID__pc IN :uniqueprofileIds) OR (Profile_Company_ID__c IN :uniqueprofileIds)];
            
            if(uniqueaccountList.size()>=1){
                status = 'Failure 1 : Account already exists';
                LogStatus = 'Failure 1 ' + ':\n' + status;
                result = 'False';
                code = '300';
                res.statusCode = 300;

            }
            else{
                list<Account> insertAcc = new list<Account>();
                list<Address__c> insertAdd = new list<Address__c>();
                list<Qualification__c> insertQlf = new list<Qualification__c>();
                list<Sponsorship__c> insertSpn = new list<Sponsorship__c>();
                list<Address__c> incomingAdd = new list<Address__c>();
                list<Qualification__c> incomingQlf = new list<Qualification__c>();
                
                Set<String> stdprofileIds = new Set<String>();
                Set<String> cmpprofileIds = new Set<String>();
                Set<String> TMprofileIds = new Set<String>();
                
                map<String, Id> stdaccounts = new map<String, Id>();
                map<String, Id> compaccounts = new map<String, Id>();
                map<String, Id> TManagers = new map<String, Id>();
                map<String, Id> Qualifications = new map<String, Id>();
                map<String, Id> countryCode = new map<String, Id>();
                map<String, Id> stateCode = new map<String, Id>();
                map<String, Id> localityCode = new map<String, Id>();
                
                list<Account> accountList;
                list<Contact> contactList;
                list<String> addFields;
                list<country_list__c> countries;
                list<State_Province__c> states;
                list<Locality__c> localities;
                
                
                
                list<RecordType> recordtype = [Select Id, DeveloperName From RecordType Where SobjectType = 'Account' AND DeveloperName =: 'Student_Account'];   
                
                for(StudentDTO stDTO: stdDTO){
                    if(stDTO.student != null){
                        Account acc = new Account();
                        acc = stDTO.student;
                        
                        // WEC 10/15/2014 CRM-3546 Lookup the Coach ID and assign it to the Student Account if coachProfileId is sent into the service.
                        if(stDTO.coachProfileId != null && stDTO.coachProfileId != '')
                        {
                            Faculty__c tempCoach = Util.findCoachFacultyByProfile(stDTO.coachProfileId);
                            acc.Coach__pc = tempCoach.Id;
                        }
                        
                        acc.RecordTypeId = recordtype[0].Id;
                        insertAcc.add(acc);
                        stdprofileIds.add(acc.PS_Profile_Services_ID__pc);
                    }
                    else{
                        status = 'Failure 2 : No Student information found in Request';
                        LogStatus = 'Failure 2 ' + ':\n' + status;
                    }
                    if(stDTO.sponsor != null){
                        if(stDTO.sponsor.CompanyProfileId != null){
                            cmpprofileIds.add(stDTO.sponsor.CompanyProfileId);
                        }
                        if(stDTO.sponsor.TrainingManagerProfileId != null){
                            TMprofileIds.add(stDTO.sponsor.TrainingManagerProfileId);
                        }
                    }
                    if(stDTO.addresses != null){
                        incomingAdd.addAll(stDTO.addresses);
                    }
                    if(stDTO.qualifications != null){
                        incomingQlf.addAll(stDTO.qualifications);
                    }
                }
                insert insertAcc;
                
                //Set the SFDC Account ID for the REST Response
                accountId = insertAcc[0].Id;
                
                system.debug('Incoming Student Accounts' + stdprofileIds.size());
                system.debug('Incoming Addresses' + incomingAdd.size());
                system.debug('Incoming Companies' + cmpprofileIds.size());
                system.debug('Incoming TManagers' + TMprofileIds.size());
                system.debug('Incoming Qualifications' + incomingQlf.size());
                
                if((incomingAdd.size() > 0) || (TMprofileIds.size() > 0) || (cmpprofileIds.size() > 0) || (incomingQlf.size() > 0)){
                    accountList = [Select Id, PS_Profile_Services_ID__pc, Profile_Company_ID__c From Account Where (PS_Profile_Services_ID__pc IN :stdprofileIds) OR (Profile_Company_ID__c IN :cmpprofileIds)];
                    accountList = [Select Id, PS_Profile_Services_ID__pc, Profile_Company_ID__c From Account Where (PS_Profile_Services_ID__pc IN :stdprofileIds) OR (Profile_Company_ID__c IN :cmpprofileIds)];
                    
                    for (Account accnt : accountList){
                        stdaccounts.put(accnt.PS_Profile_Services_ID__pc, accnt.Id);
                        if(accnt.Profile_Company_ID__c != null || accnt.Profile_Company_ID__c != ''){
                            compaccounts.put(accnt.Profile_Company_ID__c, accnt.Id);
                        }
                    }
                }
                if((TMprofileIds.size() > 0) || (incomingQlf.size() > 0)){
                    contactList = [Select Id, PS_Profile_Services_ID__c From Contact Where (PS_Profile_Services_ID__c IN :TMprofileIds) OR (PS_Profile_Services_ID__c IN :stdprofileIds)];
                    for (Contact cnt : contactList){
                        TManagers.put(cnt.PS_Profile_Services_ID__c, cnt.Id);
                        Qualifications.put(cnt.PS_Profile_Services_ID__c, cnt.Id);
                    }
                }
                if(incomingAdd.size() > 0){ 
                    countries = [Select Id, ISO_CODE__c From country_list__c Where ISO_CODE__c != '' AND 
                                 ISO_CODE__c != null];
                    for (country_list__c cntry : countries){
                        countryCode.put(cntry.ISO_CODE__c.toUpperCase(), cntry.Id);
                    }
                    states = [Select Id, ISO_Code__c From State_Province__c Where ISO_Code__c != '' AND 
                              ISO_Code__c != null];
                    for (State_Province__c stt : states){
                        stateCode.put(stt.ISO_Code__c.toUpperCase(), stt.Id);
                    }
                    localities = [Select Id, Banner_Code__c From Locality__c Where Banner_Code__c != '' AND 
                                  Banner_Code__c != null];
                    for (Locality__c lcty : localities){
                        localityCode.put(lcty.Banner_Code__c.toUpperCase(), lcty.Id);
                    }
                }
                for(StudentDTO stDTO: stdDTO){
                    if(stdaccounts.containsKey(stDTO.student.PS_Profile_Services_ID__pc)){
                        if(stDTO.addresses != null){
                            for(Address__c adds: stDTO.addresses){
                                Address__c add = new Address__c();
                                add = adds; 
                                add.Student__c = stdaccounts.get(stDTO.student.PS_Profile_Services_ID__pc);
                                if(add.Text_Country__c != null && add.Text_Country__c != ''){
                                    if (countryCode.containsKey(add.Text_Country__c.toUpperCase())){
                                        add.Lookup_Country__c = countryCode.get(add.Text_Country__c.toUpperCase());
                                    }
                                }
                                if(add.Text_State__c != null && add.Text_State__c != ''){
                                    if (stateCode.containsKey(add.Text_State__c.toUpperCase())){
                                        add.State_Province__c = stateCode.get(add.Text_State__c.toUpperCase());
                                    }
                                }
                                if(add.Text_Locality__c != null && add.Text_Locality__c != ''){
                                    if (localityCode.containsKey(add.Text_Locality__c.toUpperCase())){
                                        add.Locality__c = localityCode.get(add.Text_Locality__c.toUpperCase());
                                    }
                                }
                                insertAdd.add(add);
                            }
                        }
                        if(stDTO.sponsor != null){
                            Sponsorship__c spn = new Sponsorship__c();
                            spn.Active__c = true;
                            spn.Student__c = stdaccounts.get(stDTO.student.PS_Profile_Services_ID__pc);
                            spn.Company__c = compaccounts.get(stDTO.sponsor.CompanyProfileId);
                            spn.Training_Manager__c = TManagers.get(stDTO.sponsor.TrainingManagerProfileId);
                            insertSpn.add(spn);
                        }
                        if(stDTO.qualifications != null){
                            for(Qualification__c qlfs: stDTO.qualifications){
                                Qualification__c qlf = new Qualification__c();
                                qlf = qlfs;
                                qlf.Subject__c = 'TBD'; 
                                qlf.Student__c = Qualifications.get(stDTO.student.PS_Profile_Services_ID__pc);
                                insertQlf.add(qlf);
                            }
                        }
                    }
                }                
                insert insertAdd;
                insert insertSpn;
                insert insertQlf;
            }
            writeLog(stdDTO, LogStatus);
            return new Response(status,
                                code,
                                result,
                                accountId); 
        }
        catch (Exception e) {
            Fresponse =  'Failure' + ':\n' + e.getTypeName() + ' - ' + e.getMessage();
            writeLog(stdDTO, 'Failure' + ':\n' + e.getLineNumber() + ': ' + e.getTypeName() + ' - ' + e.getMessage() + '\n' + e.getStackTraceString());
            res.statusCode = 500;
            return new Response(Fresponse,
                                '500',
                                'FALSE',
                                accountId);
        }
    }
    
    
    private static void writeLog(List<StudentDTO> stdDTO, String Status){
        Integration_Log_Incoming__c log = new Integration_Log_Incoming__c();
        log.Request_Body__c = JSON.serialize(stdDTO);
        log.Request_Date__c = Datetime.now();
        log.Service_Name__c = 'CreateStudentAccount';
        log.Details__c = Status;
        insert log;
    }
}