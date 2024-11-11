global with sharing class UpdateSISPerson{
    public static string endPoint = '/rest/sis/person/v1';
    public static string mockResponse = '{"self":"null","httpMethod":"DELETE","errorMessage":"Cannot find Company or Profile Record for the specified Id: 1231231231","errorCode":"PLATFORM-801","transactionId":"A563C5CD-4CA9-B1C6-392A-09377720BFAC"}';
    
    WebService static String PersonInformation (String accountId, String opportunityId) {
      String result;
        Account acc = [Select Id, BNR_Banner_ID__pc,
                       Sexual_Orientation__pc, Gender_Identity__pc, Religion__pc
                       //Student_Occupation__pc, Parent_Guardian_Occupation__pc, Age__pc
                       From Account Where Id = :accountId Limit 1];
                       
        Opportunity opp = [Select Id, BNR_Term_Code_Text__c From Opportunity Where Id = :opportunityId Limit 1];               
        String strRet = sendPersonInformation(acc, opp);
                  
        result = strRet;
        return result;
    }
    
    WebService static String PersonInformationnew (Account acc, opportunity opp) {
      String result;
                     
        String strRet = sendPersonInformation(acc, opp);
                  
        result = strRet;
        return result;
    }
     
    public class personTypeInfo{
        public personType updateSISPersonRequest = new personType();
    }
        
    public class personType {
        public string sexualOrientation = '';
        //public string occupationInformation = '';
        public string genederIdentity = '';
        public string religion = '';    
        public List<QualificationType> qualifications = new List<QualificationType>();
    }
        
    public class QualificationType {
        public string opportunityId = '';
        public string termCode = '';
        public string subject = '';
        public string institution = '';
        public string grade = '';
        public string naricGrade = '';
        public string naricQualificationDate = '';
        public string naricIndicator = '';
        public string admissionsIndicator = '';
        public string status = '';
        public string mode = '';
        public string type = '';
        public string qnId = '';
        public string studentInstituteNumber = '';
        public string examiningBody = '';
        public string tariffPoints = '';
        public string description = '';
        public string recordSource = '';
        public string pYearGrade = '';
        public string startDate = '';
        public string qualificationDate = '';      
    }
       
    public static String sendPersonInformation(Account acc, Opportunity opp){
        string result;
        if (acc != null && opp != null){
            personTypeInfo pti = new personTypeInfo();
           
            /* Changes made for BPP-22230 - Removed so that values are set to null (see Dev Task for reason) */
			/* 	if (acc.Sexual_Orientation__pc != null && acc.Sexual_Orientation__pc != '' && extractCodeIntValue(acc.Sexual_Orientation__pc) < 10){
                	pti.updateSISPersonRequest.sexualOrientation = ExtractCode(acc.Sexual_Orientation__pc);   
                }
                if (acc.Gender_Identity__pc != null && acc.Gender_Identity__pc != ''){
                	pti.updateSISPersonRequest.genederIdentity = ExtractCode(acc.Gender_Identity__pc);   
                }
                if (acc.Religion__pc != null && acc.Religion__pc != '' && extractCodeIntValue(acc.Religion__pc) < 20){
                	pti.updateSISPersonRequest.religion = ExtractCode(acc.Religion__pc);   
                }
			*/
            
            /*
            if (acc.Age__pc < 21 && acc.Parent_Guardian_Occupation__pc != null && acc.Parent_Guardian_Occupation__pc != ''){
                pti.updateSISPersonRequest.occupationInformation = ExtractCode(acc.Parent_Guardian_Occupation__pc);   
            }
            else if (acc.Student_Occupation__pc != null && acc.Student_Occupation__pc != '')
              pti.updateSISPersonRequest.occupationInformation = ExtractCode(acc.Student_Occupation__pc);         
            */
            
            list<Contact> contacts = [Select Id, AccountId From Contact Where AccountId =: acc.Id];
            list<Qualification__c> qualifications = [Select Id, Student__c, Qualification_Subject__r.Subject_Code__c, Qualification_Institution__r.Institution_Code__c, 
                                                     HESA_Grade__c, NARIC_Equivalent_Grade__c, NARIC_Grade_Date__c, NARIC_Indicator__c, 
                                                     Admissions_Request__c, Status__c, Mode__c, Qualification_Type__r.Type_Code__c, 
                                                     Name, Student_Institute__c, Examing_Body__c, Tariff_Points__c, Description__c, 
                                                     Record_Source__c, Penultimate_Year_Grade__c, Start_Date__c, Qualification_Date__c
                                                     From Qualification__c Where Student__c =: contacts[0].Id];                                                            
            if (qualifications.size() != 0){
                pti.updateSISPersonRequest.qualifications = new List<QualificationType>();
                
                for (Qualification__c qualification : qualifications){
                    QualificationType qual = new QualificationType();
                    
                    if (opp.Id != null ){
                       qual.opportunityId = opp.Id;
                    }
                    if (opp.BNR_Term_Code_Text__c != null && opp.BNR_Term_Code_Text__c!= ''){
                        qual.termCode = opp.BNR_Term_Code_Text__c;
                    }
                    if (qualification.Qualification_Subject__c != null ){
                        qual.subject = qualification.Qualification_Subject__r.Subject_Code__c ;
                    }
                    if (qualification.Qualification_Institution__c != null ){
                        qual.institution = qualification.Qualification_Institution__r.Institution_Code__c;
                    }
                    if (qualification.HESA_Grade__c != null && qualification.HESA_Grade__c != ''){                        
                      /*  if (qualification.Grade__c == 'Pass')
                            qualification.Grade__c = 'P';
                        if (qualification.Grade__c == 'Ordinary')
                            qualification.Grade__c = 'ORD';  */  
                        
                        qual.grade = qualification.HESA_Grade__c;
                    }
                    if (qualification.NARIC_Equivalent_Grade__c  != null && qualification.NARIC_Equivalent_Grade__c  != ''){
                        qual.naricGrade = ExtractCode(qualification.NARIC_Equivalent_Grade__c) ;
                    }
                    if (qualification.NARIC_Grade_Date__c  != null ){
                        string naricgradedt = string.valueOf(qualification.NARIC_Grade_Date__c);
                        qual.naricQualificationDate = naricgradedt ;
                    }
                    if (qualification.NARIC_Indicator__c != null) {
                        string naricInd = string.valueof(qualification.NARIC_Indicator__c);
                        qual.naricIndicator = naricInd ;
                    }
                    if (qualification.Admissions_Request__c != null ){
                        string admissionsReq = string.valueof(qualification.Admissions_Request__c);
                        qual.admissionsIndicator = admissionsReq ;
                    }
                    if (qualification.Status__c != null && qualification.Status__c != ''){
                        if (qualification.Status__c == 'Actual')
                            qualification.Status__c = 'A';
                        if (qualification.Status__c == 'Predicted')
                            qualification.Status__c = 'P';
                        if (qualification.Status__c == 'Review')
                            qualification.Status__c = 'R';    
                        
                        qual.status = qualification.Status__c;
                    }
                    if (qualification.Mode__c != null && qualification.Mode__c != ''){
                        qual.mode = qualification.Mode__c;
                    }
                    if (qualification.Qualification_Type__c != null){
                        qual.type = qualification.Qualification_Type__r.Type_Code__c;
                    }
                    if (qualification.Name != null && qualification.Name != ''){
                        qual.qnId = qualification.Name;
                    }
                    if (qualification.Student_Institute__c != null && qualification.Student_Institute__c != ''){
                        qual.studentInstituteNumber = qualification.Student_Institute__c;
                    }
                    if (qualification.Examing_Body__c != null && qualification.Examing_Body__c != ''){
                        qual.examiningBody = qualification.Examing_Body__c;
                    }
                    if (qualification.Tariff_Points__c != null){
                        string tarpoints = string.valueOf(qualification.Tariff_Points__c);
                        qual.tariffPoints = tarpoints;
                    }
                    if (qualification.Description__c != null && qualification.Description__c != ''){
                        qual.description = qualification.Description__c;
                    }
                    if (qualification.Record_Source__c != null && qualification.Record_Source__c != ''){
                        qual.recordSource = qualification.Record_Source__c;
                    }
                    if (qualification.Penultimate_Year_Grade__c != null && qualification.Penultimate_Year_Grade__c != ''){
                        qual.pYearGrade = qualification.Penultimate_Year_Grade__c;
                    }
                    if (qualification.Start_Date__c != null){
                        string startdt = string.valueOf(qualification.Start_Date__c);
                        qual.startDate = startdt;
                    }
                    if (qualification.Qualification_Date__c != null){
                        string qualificationdt = string.valueOf(qualification.Qualification_Date__c);
                        qual.qualificationDate = qualificationdt;
                    }
                                                            
                    pti.updateSISPersonRequest.qualifications.add(qual);
                }
            }            
                    
            
            String jsonRequest = JSON.serialize(pti);
            system.debug(jsonRequest);
            Http http = new Http();
            HttpRequest req = BPPIntegrationConfig.callUpdateRestService(jsonRequest, 'application/json', endPoint +'/'+ acc.BNR_Banner_ID__pc);
                       
            system.debug('Final JSON: ' + req.getMethod() + ' ' + req.getEndPoint() + 'Accept-Encoding:' + req.getHeader('Accept-Encoding') +'Accept:' + req.getHeader('Accept') + 'Content-Type:' + req.getHeader('Content-Type') + 'tenantId:' + req.getHeader('tenantId') + req.getBody());
            system.debug(req.toString());
            HttpResponse res = null;
            if (Test.isRunningTest()) {
                res = new HttpResponse();
                res.setStatusCode(200);
                res.setStatus('OK');
                res.setBody(mockResponse);
            } else {
                res = http.send(req);
            }
            system.debug(res.getBody());
            system.debug('DebugStatus' + res.getStatus());
            system.debug('DebugStatusCode' + res.getStatusCode());
            
            /* Integration Log */
            Integration_Log__c intg = new Integration_Log__c();
            intg.Request__c =  jsonRequest;
            intg.Response__c = res.getBody();
            intg.Salesforce_ID__c = acc.Id;
            intg.Integration_Type__c = 'UpdateSISPerson';
            
            if (res.getStatus() == 'OK' && res.getStatusCode() == 200){   
              //resp is a JSON string
                JSONParser parser = JSON.createParser(res.getBody());
                while (parser.nextToken() != null) {
                    if ((parser.getCurrentToken() == JSONToken.FIELD_NAME)){
                        String fieldName = parser.getText();
                        parser.nextToken();
                        if(fieldName == 'success') {
                            if (parser.getText() == 'true') {
                              result = 'Success';
                              break;
                            }
                            else { //not successful, return error message
                                parser.nextToken();
                                fieldName = parser.getText();
                                parser.nextToken();
                                if(fieldName == 'errorMessage') {
                                  result = parser.getText();
                                break;  
                                } 
                            }
                        }
                    }
                }
            }
            else {
                JSONParser jParser = JSON.createParser(res.getBody());
                while(jParser.nextToken() != null){
                    if((jParser.getCurrentToken() == JSONToken.FIELD_NAME)){
                        string fieldN = jParser.getText();
                        jParser.nextToken();
                        if(fieldN == 'errorMessage'){
                            result = jParser.getText();
                            break;
                        }
                    }
                }
            }
            insert intg;
        }
        return result;
    }
    
    
    //new method to use with trigger  
    @future(callOut=true)  
    public static void UpdatePersonInformation(String acctId, String opptyId){
        string result;
        
        Account acc = [Select Id, BNR_Banner_ID__pc,
                       Sexual_Orientation__pc, Gender_Identity__pc, Religion__pc
                       From Account Where Id =:acctId Limit 1];
                       
        Opportunity opp = [Select Id, BNR_Term_Code_Text__c From Opportunity Where Id =:opptyId Limit 1];
                
        if (acc != null && opp != null){
            personTypeInfo pti = new personTypeInfo();
           
            /* Changes made for BPP-22230 - Removed so that values are set to null (see Dev Task for reason) */
            /* 	if (acc.Sexual_Orientation__pc != null && acc.Sexual_Orientation__pc != ''){
                    pti.updateSISPersonRequest.sexualOrientation = ExtractCode(acc.Sexual_Orientation__pc);   
                }
                if (acc.Gender_Identity__pc != null && acc.Gender_Identity__pc != ''){
                pti.updateSISPersonRequest.genederIdentity = ExtractCode(acc.Gender_Identity__pc);   
                }
                if (acc.Religion__pc != null && acc.Religion__pc != ''){
                pti.updateSISPersonRequest.religion = ExtractCode(acc.Religion__pc);   
                }
			*/
            
            /*
            if (acc.Age__pc < 21 && acc.Parent_Guardian_Occupation__pc != null && acc.Parent_Guardian_Occupation__pc != ''){
                pti.updateSISPersonRequest.occupationInformation = ExtractCode(acc.Parent_Guardian_Occupation__pc);   
            }
            else if (acc.Student_Occupation__pc != null && acc.Student_Occupation__pc != '')
              pti.updateSISPersonRequest.occupationInformation = ExtractCode(acc.Student_Occupation__pc);         
            */
            
            list<Contact> contacts = [Select Id, AccountId From Contact Where AccountId =: acc.Id];
            list<Qualification__c> qualifications = [Select Id, Student__c, Qualification_Subject__r.Subject_Code__c, Qualification_Institution__r.Institution_Code__c, 
                                                     HESA_Grade__c, NARIC_Equivalent_Grade__c, NARIC_Grade_Date__c, NARIC_Indicator__c, 
                                                     Admissions_Request__c, Status__c, Mode__c, Qualification_Type__r.Type_Code__c, 
                                                     Name, Student_Institute__c, Examing_Body__c, Tariff_Points__c, Description__c, 
                                                     Record_Source__c, Penultimate_Year_Grade__c, Start_Date__c, Qualification_Date__c
                                                     From Qualification__c Where Student__c =: contacts[0].Id];                                                            
            if (qualifications.size() != 0){
                pti.updateSISPersonRequest.qualifications = new List<QualificationType>();
                
                for (Qualification__c qualification : qualifications){
                    QualificationType qual = new QualificationType();
                    
                    if (opp.Id != null ){
                       qual.opportunityId = opp.Id;
                    }
                    if (opp.BNR_Term_Code_Text__c != null && opp.BNR_Term_Code_Text__c!= ''){
                        qual.termCode = opp.BNR_Term_Code_Text__c;
                    }
                    if (qualification.Qualification_Subject__c != null ){
                        qual.subject = qualification.Qualification_Subject__r.Subject_Code__c ;
                    }
                    if (qualification.Qualification_Institution__c != null ){
                        qual.institution = qualification.Qualification_Institution__r.Institution_Code__c;
                    }
                    if (qualification.HESA_Grade__c != null && qualification.HESA_Grade__c != ''){                        
                      /*  if (qualification.Grade__c == 'Pass')
                            qualification.Grade__c = 'P';
                        if (qualification.Grade__c == 'Ordinary')
                            qualification.Grade__c = 'ORD';    */
                        
                        qual.grade = qualification.HESA_Grade__c;
                    }
                    if (qualification.NARIC_Equivalent_Grade__c  != null && qualification.NARIC_Equivalent_Grade__c  != ''){
                        qual.naricGrade = ExtractCode(qualification.NARIC_Equivalent_Grade__c) ;
                    }
                    if (qualification.NARIC_Grade_Date__c  != null ){
                        string naricgradedt = string.valueOf(qualification.NARIC_Grade_Date__c);
                        qual.naricQualificationDate = naricgradedt ;
                    }
                    if (qualification.NARIC_Indicator__c != null) {
                        string naricInd = string.valueof(qualification.NARIC_Indicator__c);
                        qual.naricIndicator = naricInd ;
                    }
                    if (qualification.Admissions_Request__c != null ){
                        string admissionsReq = string.valueof(qualification.Admissions_Request__c);
                        qual.admissionsIndicator = admissionsReq ;
                    }
                    if (qualification.Status__c != null && qualification.Status__c != ''){
                        if (qualification.Status__c == 'Actual')
                            qualification.Status__c = 'A';
                        if (qualification.Status__c == 'Predicted')
                            qualification.Status__c = 'P';
                        if (qualification.Status__c == 'Review')
                            qualification.Status__c = 'R';    
                        
                        qual.status = qualification.Status__c;
                    }
                    if (qualification.Mode__c != null && qualification.Mode__c != ''){
                        qual.mode = qualification.Mode__c;
                    }
                    if (qualification.Qualification_Type__c != null){
                        qual.type = qualification.Qualification_Type__r.Type_Code__c;
                    }
                    if (qualification.Name != null && qualification.Name != ''){
                        qual.qnId = qualification.Name;
                    }
                    if (qualification.Student_Institute__c != null && qualification.Student_Institute__c != ''){
                        qual.studentInstituteNumber = qualification.Student_Institute__c;
                    }
                    if (qualification.Examing_Body__c != null && qualification.Examing_Body__c != ''){
                        qual.examiningBody = qualification.Examing_Body__c;
                    }
                    if (qualification.Tariff_Points__c != null){
                        string tarpoints = string.valueOf(qualification.Tariff_Points__c);
                        qual.tariffPoints = tarpoints;
                    }
                    if (qualification.Description__c != null && qualification.Description__c != ''){
                        qual.description = qualification.Description__c;
                    }
                    if (qualification.Record_Source__c != null && qualification.Record_Source__c != ''){
                        qual.recordSource = qualification.Record_Source__c;
                    }
                    if (qualification.Penultimate_Year_Grade__c != null && qualification.Penultimate_Year_Grade__c != ''){
                        qual.pYearGrade = qualification.Penultimate_Year_Grade__c;
                    }
                    if (qualification.Start_Date__c != null){
                        string startdt = string.valueOf(qualification.Start_Date__c);
                        qual.startDate = startdt;
                    }
                    if (qualification.Qualification_Date__c != null){
                        string qualificationdt = string.valueOf(qualification.Qualification_Date__c);
                        qual.qualificationDate = qualificationdt;
                    }
                                                            
                    pti.updateSISPersonRequest.qualifications.add(qual);
                }
            }            
                    
            
            String jsonRequest = JSON.serialize(pti);
            system.debug(jsonRequest);
            Http http = new Http();
            HttpRequest req = BPPIntegrationConfig.callUpdateRestService(jsonRequest, 'application/json', endPoint +'/'+ acc.BNR_Banner_ID__pc);
                       
            system.debug('Final JSON: ' + req.getMethod() + ' ' + req.getEndPoint() + 'Accept-Encoding:' + req.getHeader('Accept-Encoding') +'Accept:' + req.getHeader('Accept') + 'Content-Type:' + req.getHeader('Content-Type') + 'tenantId:' + req.getHeader('tenantId') + req.getBody());
            system.debug(req.toString());
            HttpResponse res = null;
            if (Test.isRunningTest()) {
                res = new HttpResponse();
                res.setStatusCode(200);
                res.setStatus('OK');
                res.setBody(mockResponse);
            } else {
                res = http.send(req);
            }
            system.debug(res.getBody());
            system.debug('DebugStatus' + res.getStatus());
            system.debug('DebugStatusCode' + res.getStatusCode());
            
            /* Integration Log */
            Integration_Log__c intg = new Integration_Log__c();
            intg.Request__c =  jsonRequest;
            intg.Response__c = res.getBody();
            intg.Salesforce_ID__c = acc.Id;
            intg.Integration_Type__c = 'UpdateSISPerson - bpp_dndirector';
            
            if (res.getStatus() == 'OK' && res.getStatusCode() == 200){   
              //resp is a JSON string
                JSONParser parser = JSON.createParser(res.getBody());
                while (parser.nextToken() != null) {
                    if ((parser.getCurrentToken() == JSONToken.FIELD_NAME)){
                        String fieldName = parser.getText();
                        parser.nextToken();
                        if(fieldName == 'success') {
                            if (parser.getText() == 'true') {
                              result = 'Success';
                              break;
                            }
                            else { //not successful, return error message
                                parser.nextToken();
                                fieldName = parser.getText();
                                parser.nextToken();
                                if(fieldName == 'errorMessage') {
                                  result = parser.getText();
                                break;  
                                } 
                            }
                        }
                    }
                }
            }
            else {
                JSONParser jParser = JSON.createParser(res.getBody());
                while(jParser.nextToken() != null){
                    if((jParser.getCurrentToken() == JSONToken.FIELD_NAME)){
                        string fieldN = jParser.getText();
                        jParser.nextToken();
                        if(fieldN == 'errorMessage'){
                            result = jParser.getText();
                            break;
                        }
                    }
                }
            }
            insert intg;
        }
        return;
    }
    
    public static Integer extractCodeIntValue(String displayString) {
        return Integer.valueOf(ExtractCode(displayString));
    }
    
    public static string ExtractCode(String displayString) {
        return string.valueOf(displayString).substring(0, string.valueOf(displayString).indexOf('~'));
    }
       
}