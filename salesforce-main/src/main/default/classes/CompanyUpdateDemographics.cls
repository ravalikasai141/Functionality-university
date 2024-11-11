@RestResource(urlMapping='/v1.0/CompanyUpdateDemographics')
global with sharing class CompanyUpdateDemographics {
    global class Response {
        global String status { get; set; }
        
        public Response(String status) {
            this.status = status;
        }
    }
     
    global class CompanyDTO {
        global Account Company;
        global List<Address__c> addresses;    
    }
    
    @HttpPost
    global static Response doPost(List<CompanyDTO> cmpDTO) {
         return ProcessDemographicUpdate(cmpDTO);
    }
    
    global static Response ProcessDemographicUpdate(List<CompanyDTO> cmpDTO) {
        // Get List of Companies
        Map<String, Account> accountsFromJSON = new Map<String, Account>();
        // Get List of addresses for Comapanies
        Map<String, List<Address__c>> addressFromJSON = new Map<String, List<Address__c>>();
        
        // Loop through JSON Companies
        List<Account> accountList = new List<Account>();
        List<Address__c> addressList;
        try{
        	List<String> accountFields = Util.getUpdateableFields('Account');
        	Set<String> includedFields = new Set<String>();
        	String accountQuery = 'SELECT Id';
        
        	for (CompanyDTO cmDTO : cmpDTO){
            	if (cmDTO == null || cmDTO.Company == null || cmDTO.Company.Profile_Company_ID__c == null || 
                	cmDTO.Company.Profile_Company_ID__c == ''){
                	writeLog(cmpDTO, accountList, 'Failure');
             		return new Response('Failure');
            	}
            	accountsFromJSON.put(cmDTO.Company.Profile_Company_ID__c, cmDTO.Company);
            	for (String field : accountFields) {
                	if (!includedFields.contains(field)) {
                    	if (cmDTO.Company.get(field) != null) {
                        	accountQuery += ', ' + field;
                        	includedFields.add(field);
                    	}
                	}
            	}
            	addressFromJSON.put(cmDTO.Company.Profile_Company_ID__c, cmDTO.addresses);
        	}
        
        	Set<String> companyProfileSet = accountsFromJSON.keySet();
			accountQuery += '  FROM Account WHERE Profile_Company_ID__c IN : companyProfileSet';
			List<Account> realAccountList = Database.query(accountQuery);
			Set<Id> accountIds = new Set<Id>();
			for (Account acc : realAccountList) {
            	accountIds.add(acc.Id);
        	}
			List<String> addressFields = Util.getUpdateableFields('Address__c');
        	addressList = Database.query(Util.getAllFieldsSOQL('Address__c', 'Student__c IN : accountIds'));
        	Map<Id, List<Address__c>> addressMap = new Map<Id, List<Address__c>>();
        	for (Address__c addr : addressList) {
            	if (addressMap.containsKey(addr.Student__c)){
                	list<Address__c> a = addressMap.get(addr.Student__c);
                	a.add(addr);
                	addressMap.put(addr.Student__c, a);
            	}
            	else{
                	List<Address__c> lstAdd = new List<Address__c>();
                	lstAdd.add(addr);
                	addressMap.put(addr.Student__c, lstAdd);
            	}
        	}
        	Map<String, Id> countryCode = new Map<String, Id>();
        	List<country_list__c> countries = [Select Id, ISO_CODE__c From country_list__c Where ISO_CODE__c != '' AND 
            	                                    ISO_CODE__c != null];
            for (country_list__c cntry : countries){
               	countryCode.put(cntry.ISO_CODE__c.toUpperCase(), cntry.Id);
            }
        	Map<String, Id> stateCode = new Map<String, Id>();
        	List<State_Province__c> states = [Select Id, ISO_Code__c From State_Province__c Where ISO_Code__c != '' AND 
                                              ISO_Code__c != null];
            for (State_Province__c stt : states){
               	stateCode.put(stt.ISO_Code__c.toUpperCase(), stt.Id);
            }
        	Map<String, Id> localityCode = new Map<String, Id>();
        	List<Locality__c> localities = [Select Id, Banner_Code__c From Locality__c Where Banner_Code__c != '' AND 
                                                 Banner_Code__c != null];
            for (Locality__c lcty : localities){
               	localityCode.put(lcty.Banner_Code__c.toUpperCase(), lcty.Id);
            }
        	List<Address__c> insertAddress = new List<Address__c>();
        	List<Address__c> updateAddress = new List<Address__c>();
        	List<Address__c> addressNotFound = new List<Address__c>();
        	List<Address__c> deleteaddress = new List<Address__c>();
        	Set<String> realProfileIds = new Set<String>();
        	for (Account acct : realAccountList){
            	Account newAccount = accountsFromJSON.get(acct.Profile_Company_ID__c);
            	realProfileIds.add(acct.Profile_Company_ID__c);
            	if (newAccount == null)
                	return new Response('Failure');
            
            	for (String field : accountFields) {
                	if (field.toLowerCase().equals('id')) continue;
                
                	if (newAccount.get(field) != null) {
                    	system.debug('FROM DTO: ' + field + ' -> ' + newAccount.get(field));
                    	acct.put(field, newAccount.get(field));
                	}
            	}
            
            	List<Address__c> newAddressList = addressFromJSON.get(acct.Profile_Company_ID__c);
            	List<Address__c> existingAddress = addressMap.get(acct.Id);
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
                                            	newAdrs.Lookup_Country__c = countryCode.get(newAdrs.Text_Country__c.toUpperCase());
                                        	}
                                        	adrs.put(adrsField, newAdrs.Lookup_Country__c);
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
                	adrs.Student__c = acct.Id;
                	for(String adrsField : addressFields){
                    	if (newAdrs.get(adrsField) != null) {
                        	if (adrsField.equalsIgnoreCase('id')) continue;
                        	
                        	system.debug('FROM DTO: ' + adrsField + ' -> ' + newAdrs.get(adrsField));
                        	if (adrsField.equalsIgnoreCase('Text_Country__c')){
                            	if (countryCode.containsKey(newAdrs.Text_Country__c.toUpperCase())){
                                	newAdrs.Lookup_Country__c = countryCode.get(newAdrs.Text_Country__c.toUpperCase());
                            	}
                            	adrs.put(adrsField, newAdrs.Lookup_Country__c);
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
                	insertAddress.add(adrs);
            	}
        	}
        	if (!realProfileIds.containsAll(companyProfileSet)){
            	writeLog(cmpDTO, accountList, 'Failure');
            	return new Response('Failure');
        	}
        	writeLog(cmpDTO, accountList, 'Success');
        	update realAccountList;
        	update updateAddress;
        	insert insertAddress;
        	delete deleteaddress;
        	return new Response('Success');
        }
        catch(Exception e) {
            writeLog(cmpDTO, accountList, 'Failure' + e.getLineNumber() + ': ' + e.getTypeName() + ' - ' + e.getMessage() + '\n' + e.getStackTraceString());
            return new Response('Failure');
        }
    }
    
    private static void writeLog(List<CompanyUpdateDemographics.CompanyDTO> cmpDTO, List<Account> accountList, String Status){
        Integration_Log_Incoming__c log = new Integration_Log_Incoming__c();
        log.Request_Body__c = JSON.serialize(cmpDTO);
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
        add.Student__c = a1.Id;
        add.Type__c = 'Home';
        add.Street_1__c = '329 S Tonne Dr';
        add.Street_2__c = '123';
        add.Street_3__c = '123';
        add.Street_4__c = '12';
        add.City__c = 'Chicago';
        add.Locality__c = lct.Id;
        add.State_Province__c = stt.Id;
        add.Zip_Postal_Code__c = '12345';
        add.Lookup_Country__c = cntry.Id;
        insert add;
        
        Address__c add1 = new Address__c();
        add1.Student__c = a1.Id;
        add1.Type__c = 'Mailing';
        add1.Street_1__c = '329 S Tonne Dr';
        add1.Street_2__c = '123';
        add1.Street_3__c = '123';
        add1.Street_4__c = '12';
        add1.City__c = 'Chicago';
        add1.Locality__c = lct.Id;
        add1.State_Province__c = stt.Id;
        add1.Zip_Postal_Code__c = '12345';
        add1.Lookup_Country__c = cntry.Id;
        insert add1;
        
        List<CompanyUpdateDemographics.CompanyDTO> cmpDTO = new List<CompanyUpdateDemographics.CompanyDTO>();
        CompanyUpdateDemographics.CompanyDTO cmp = new CompanyUpdateDemographics.CompanyDTO();
        Account acc = new Account();
        acc.Profile_Company_ID__c = '1234f567-bc23-42e8-924c-asdf12345678';
        cmp.Company = acc;
        
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
    	Address__c add3 = new Address__c();
    	add3.Type__c = 'Mailing';
    	add3.Street_1__c = '4321 S Test Dr';
    	add3.Street_2__c = '4321';
    	add3.Street_3__c = '321';
    	add3.Street_4__c = '32';
    	add3.City__c = 'Test City';
    	add3.Text_Locality__c = '12345';
    	add3.Text_State__c = '1234';
    	add3.Zip_Postal_Code__c = '12345';
    	add3.Text_Country__c = '123';
    	adds.add(add3);
        cmp.addresses = adds;
        
        cmpDTO.add(cmp);
        StopRecursion.Dorun = true;
        CompanyUpdateDemographics.Response res = CompanyUpdateDemographics.doPost(cmpDTO);
    } 
    
    @isTest
    public static void unitTest2(){
        List<CompanyUpdateDemographics.CompanyDTO> cmpDTO = new List<CompanyUpdateDemographics.CompanyDTO>();
        CompanyUpdateDemographics.CompanyDTO cmp = new CompanyUpdateDemographics.CompanyDTO();
        Account acc = new Account();
        acc.Profile_Company_ID__c = '1234f567-bc23-42e8-924c-12345678aabcd90';
        cmp.Company = acc;
        cmpDTO.add(cmp);
        
        CompanyUpdateDemographics.Response res = CompanyUpdateDemographics.doPost(cmpDTO);
    }
    
    @isTest
    public static void unitTest3(){
        List<CompanyUpdateDemographics.CompanyDTO> cmpDTO = new List<CompanyUpdateDemographics.CompanyDTO>();
        CompanyUpdateDemographics.CompanyDTO cmp = new CompanyUpdateDemographics.CompanyDTO();
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
    	cmpDTO.add(cmp);
        
        CompanyUpdateDemographics.Response res = CompanyUpdateDemographics.doPost(cmpDTO);
    }
}