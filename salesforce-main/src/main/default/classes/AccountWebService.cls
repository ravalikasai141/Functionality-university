@RestResource(urlMapping='/v1.0/AccountWebService/*')
global with sharing class AccountWebService {

    @HttpPost
    global static String[] queryAccountREST(String aid) {
        return queryAccount(aid);
    }        

    webService static String [] queryAccount(String aid) {         
        string Prefix = aid.substring(0,3);
        String [] results = new String[14];
        if (Prefix == '001'){  //start is account
            Account wsr = [Select a.FirstName, a.LastName, a.PersonEmail, a.PersonMailingCity, a.PersonMailingCountry, a.PersonMailingPostalCode, a.PersonMailingState, a.PersonMailingStreet, a.PersonMobilePhone, a.PersonTitle, a.Phone 
                           	 from Account a WHERE a.Id=:aid];
            system.debug('Accounts' +wsr);               	 
            Address__c add = [Select a.Zip_Postal_Code__c, a.Type__c, a.Street_1__c, a.State_Province__c, a.Street_4__c, a.Street_3__c, a.Street_2__c,
                               a.State_Province__r.ISO_Code__c, a.State_Province__r.Name, a.Locality__c, a.Locality__r.Banner_Code__c, a.Name, 
                               a.Lookup_Country__c, a.Lookup_Country__r.ISO_CODE__c, a.Lookup_Country__r.Name ,a.Id, a.City__c, a.Active__c 
                               From Address__c a WHERE a.Student__c =:aid and a.Type__c = 'Mailing' and a.Active__c = true];   
            system.debug('Addresses' +add);                         	 
            results[0] = wsr.FirstName;
            results[1] = wsr.LastName;
            results[2] = wsr.PersonEmail;
            results[3] = add.City__c;
            results[4] = add.Lookup_Country__r.Name;
            results[5] = add.Zip_Postal_Code__c;
            results[6] = add.State_Province__r.Name;
            results[7] = add.Street_1__c;
            results[8] = add.Street_2__c;
            results[9] = add.Street_3__c;
            results[10] = add.Street_4__c;
            results[11] = wsr.PersonMobilePhone; 
            results[12] = wsr.PersonTitle;
            results[13] = wsr.Phone;
            system.debug('Final Result' +results);
            return results;
       } //end is account
       else {//start not account       
        if (Prefix == '00Q') {  //start is lead
            Lead wsrl = [Select l.FirstName, l.LastName, l.Email, l.City, l.Country, l.PostalCode, l.State, l.Street, l.MobilePhone, l.Title, l.Phone 
                           from Lead l WHERE l.Id=:aid];
            Address__c add1 = [Select a.Zip_Postal_Code__c, a.Type__c, a.Street_1__c, a.Name,a.State_Province__c, a.State_Province__r.ISO_Code__c,
                                a.State_Province__r.Name, a.Locality__c, a.Locality__r.Banner_Code__c, a.Lookup_Country__c,a.Street_4__c, a.Street_3__c, a.Street_2__c, 
                                a.Lookup_Country__r.ISO_CODE__c, a.Lookup_Country__r.Name, a.Id, a.City__c, a.Active__c 
                                From Address__c a WHERE a.Lead__c =:wsrl.id and a.Type__c = 'Mailing' and a.Active__c = true];    
                                           	 
                results[0] = wsrl.FirstName;
                results[1] = wsrl.LastName;
                results[2] = wsrl.Email;
                results[3] = add1.City__c;
                results[4] = add1.Lookup_Country__r.Name;
                results[5] = add1.Zip_Postal_Code__c;
                results[6] = add1.State_Province__r.Name;
                results[7] = add1.Street_1__c;
                results[8] = add1.Street_2__c;
                results[9] = add1.Street_3__c;
                results[10] = add1.Street_4__c;
                results[11] = wsrl.MobilePhone;
            	results[12] = wsrl.Title;
           		results[13] = wsrl.Phone;
            
                return results;
           }//end is lead
           else{ //not lead
               
                results[0] = '';
                results[1] = '';
                results[2] = '';
                results[3] = '';
                results[4] = '';
                results[5] = '';
                results[6] = '';
                results[7] = '';
                results[8] = '';
                results[9] = '';
                results[10] = '';
                results[11] = '';
            	results[12] = '';
           		results[13] = '';
            
                return results;
               } // end not lead
         } //end not account
       }
  //Test methods
    
    testMethod static   void testQueryAccount() {
      //start test
     test.starttest();
        Database.DMLOptions dbDML = new Database.DMLOptions(); 
        dbDML.DuplicateRuleHeader.allowSave = true;
        dbDML.DuplicateRuleHeader.runAsCurrentUser = true;
        
        country_list__c con = CreateTestData.createCountry1();
        
        State_Province__c st = new State_Province__c();
        st.Name = 'Kent';
        st.ISO_Code__c = 'GB-KEN';
        insert st;
        
  		Account a = new Account();
        a.FirstName = 'test';
        a.LastName='test1';
        a.PersonTitle='Mr';
        a.Preferred_Email__pc = 'Personal';
        a.PersonEmail='dlsd@lsdkf.com';
        a.Personal_Email__pc = 'dlsd@lsdkf.com';
        a.Preferred_Phone__pc = 'Mobile';
        a.Phone='4353243';
        a.PersonMobilePhone ='4353243';
        Database.insert(a, dbDML);
        
        Address__c add = new Address__c();
        add.City__c = 'schaumburg';
        add.Active__c = true;
        add.Lookup_Country__c = con.Id;
        add.State_Province__c = st.Id;
        add.Street_1__c = 'Test street';
        add.Student__c = a.Id;
        add.Type__c = 'Mailing';
        Database.insert(add, dbDML);
        
        Account ta = [Select Id FROM Account limit 1];
        AccountWebService info = new AccountWebService();
        string[] s = queryAccountREST(ta.id);
        queryAccount(ta.Id);
        Lead l = new Lead();
        l.FirstName= 'test';l.LastName='test1';l.Email='dlsd@lsdkf.com';
        l.MobilePhone='3243223';l.Title='Mr';l.Phone='4353243';l.Preferred_Phone__c = 'Mobile';
        Database.insert(l, dbDML);
        
        Address__c add1 = new Address__c();
        add1.City__c = 'schaumburg';
        add1.Active__c = true;
        add1.Lookup_Country__c = con.Id;
        add1.State_Province__c = st.Id;
        add1.Street_1__c = 'Test street';
        add1.Lead__c = l.Id;
        add1.Type__c = 'Mailing';
        Database.insert(add1, dbDML);
        
        Lead tl = [Select Id FROM Lead limit 1];
        queryAccount(tl.Id);
        queryAccount('tl.Id');
    }
}