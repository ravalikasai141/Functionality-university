@RestResource(urlMapping='/v1.0/InsertPaymentEvent/*')
global with sharing class InsertPaymentEvent {
	global class Response {    
        global String status { get; set; }        
        public Response(String status) {      
            this.status = status;    
        }  
    }
    
	global class PaymentEventDTO {
		public string profileId { get; set; }
		public string paymentForm { get; set; }
		public double paymentAmount { get; set; }
		public string paymentId { get; set; }
		public string paymentSegment { get; set; }
	}
	
	@HttpPost
    global static Response doPost() {
        
        RestRequest req = RestContext.request;
        String reqStr = req.requestBody.toString();
        system.debug(reqStr);
        
        list<PaymentEventDTO> paymentDetails = (list<PaymentEventDTO>)JSON.deserialize(reqStr, list<PaymentEventDTO>.class);
        map<string,PaymentEventDTO> mRecPayEvent = new map<string,PaymentEventDTO>();
        list<Payment__c> insertPayments = new list<Payment__c>();
        
        for(PaymentEventDTO temp: paymentDetails){
        	mRecPayEvent.put(temp.profileId,temp);
        }
        list<Account> lstAccs = [Select a.PS_Profile_Services_ID__pc, a.Id From Account a 
        						  where a.PS_Profile_Services_ID__pc in :mRecPayEvent.keyset()];
        for(Account tempA: lstAccs){
        	Payment__c paymentEvent = new Payment__c();
        	PaymentEventDTO currentPay = mRecPayEvent.get(tempA.PS_Profile_Services_ID__pc);
        	paymentEvent.Student__c = tempA.id;
        	paymentEvent.AR_Payment_Form__c = currentPay.paymentForm;
        	paymentEvent.AR_Payment_Amount__c = currentPay.paymentAmount;
        	paymentEvent.AR_Payment_ID__c = currentPay.paymentId;
        	paymentEvent.AR_Payment_Segment__c = currentPay.paymentSegment;
        	insertPayments.add(paymentEvent);
        	
        }
        insert insertPayments;
        //Select p.Student__c, p.Name, p.AR_Payment_Segment__c, p.AR_Payment_ID__c, p.AR_Payment_Form__c, p.AR_Payment_Amount__c From Payment__c p
        return new Response('Success');
    }	
    
    @isTest
    public static void unitTest(){
    	Account a = new Account();
        a.firstname='John';
        a.lastname='Coppedge';
        a.Salutation = 'Mr';
        a.Middle_Name__pc = 'Mex';
        a.Gender__pc = 'Male';
        a.RecordTypeId=Schema.sObjectType.Account.getRecordTypeInfosByName().get('Student Account').getRecordTypeId();
        a.Preferred_Email__pc = 'Personal';
        a.Preferred_Phone__pc = 'Mobile';
        a.Personal_Email__pc ='john@john.com';
        a.PersonMobilePhone='8015555556';
        a.PersonBirthdate=Date.valueOf('1986-02-27');
        a.PS_Profile_Services_ID__pc = '1234f567-bc23-42e8-924c-1234asdf5678';
        a.Student_Cycle__c = 'Pursue';
        a.Student_Type__pc = 'Domestic';
        insert a;
        
      	list<PaymentEventDTO> lstPaymentDTO = new list<PaymentEventDTO>();
        PaymentEventDTO peDTO = new PaymentEventDTO();
        peDTO.profileId = '1234f567-bc23-42e8-924c-1234asdf5678';
        peDTO.paymentForm = 'Check';
        peDTO.paymentAmount = 1234.30;
        lstPaymentDTO.add(peDTO);
        Restrequest req = new Restrequest();
        req.addHeader('Content-Type','application/json');
        req.requestBody = Blob.valueOf(Json.serialize(lstPaymentDTO));
        RestContext.request = req;
        InsertPaymentEvent.Response res = InsertPaymentEvent.doPost();
    }
}