/*
* @who   Patrick Duncan <patrick.duncan@weare4c.com>
* @what  Class for emailing invoice pdfs to related records
* @when  30/4/2020
*/
public with sharing class InvoiceSender {
	public static final String INVOICE_ACCOUNT_LOOKUP_API_NAME = 'blng__Account__c';
	public static final String CONTENT_DOCUMENT_LINK_CONTENT_DOCUMENT_LOOKUP_API_NAME = 'ContentDocumentId';
	public static final String CONTENT_DOCUMENT_LINK_LINKED_ENTITY_LOOKUP_API_NAME = 'LinkedEntityId';


	/*
	*  @description    				Main method for for extracting the invoice pdf attached to an invoice after insertion and 
									emailing it to that invoice's account's primary contact if certain criteria are met
   	*  @param  invoiceMap  			Map of invoice id -> invoice
	*/
	public static void sendInvoices(Map<Id,blng__Invoice__c> invoiceMap){
		Map<Id,Account> accountMap = queryAccounts(invoiceMap);
		Map<Id,InvoiceSend> filteredInvoiceIdToInvoiceSend = filterInvoices(invoiceMap, accountMap);
		addContentVersionsToInvoiceSends(filteredInvoiceIdToInvoiceSend);
		sendEmails(filteredInvoiceIdToInvoiceSend);
	}

	/*
	*  @description    				Method to query each related account and it's primary contact for each invoice in invoiceMap
   	*  @param  invoiceMap  			Map of invoice id -> invoice 
   	*  @return    					Map of account id -> account
	*/
	private static Map<Id,Account> queryAccounts(Map<Id,blng__Invoice__c> invoiceMap){
		List<String> accountIds = (List<String>) SObjectUtil.getFieldValuesFromSObjectList(invoiceMap.values(), INVOICE_ACCOUNT_LOOKUP_API_NAME);
		return new Map<Id,Account>([SELECT Id, Send_Invoice_Automatically__c, Billing_Type__c, Invoice_Consolidation__c, Customer_Group__c, (SELECT Email, Account.Name FROM Contacts WHERE Primary_Billing_Contact__c = TRUE) FROM Account WHERE Id IN :accountIds]);
	}

	/*
	*  @description    				Method to filter down the invoices which are to be sent and create InvoiceSend inner class objects of those that meet criteria
   	*  @param  invoiceMap  			Map of invoice id -> invoice 
   	*  @param  accountMap  			Map of account id -> account 
   	*  @return    					Map of invoice id -> InvoiceSend
	*/
	private static Map<Id,InvoiceSend> filterInvoices(Map<Id,blng__Invoice__c> invoiceMap, Map<Id,Account> accountMap){
		Map<Id,InvoiceSend> invoiceIdToInvoiceSend = new Map<Id,InvoiceSend>();
		for(blng__Invoice__c invoice:invoiceMap.values()){
			Account parentAccount = accountMap.get(invoice.blng__Account__c);
			if(invoiceMeetsCriteriaForSend(invoice, parentAccount)){
				invoiceIdToInvoiceSend.put(invoice.Id, new InvoiceSend(parentAccount.Contacts.get(0)));
			}
		}  
		return invoiceIdToInvoiceSend;
	}

	/*
	*  @description    				Method which decides whether an invoice is to be emailed based on the object and its related account
   	*  @param  invoice  			Invoice to check
   	*  @param  parentAccount  		Invoice's related account
   	*  @return    					Boolean whether the invoice meets critera for emailing
	*/
	private static Boolean invoiceMeetsCriteriaForSend(blng__Invoice__c invoice, Account parentAccount){
		if(invoice.blng__InvoiceDate__c == Date.today() && invoice.blng__InvoiceStatus__c == 'Posted' && parentAccount.Customer_Group__c == 'Tier 1 - Key Clients' 
				&& parentAccount.Send_Invoice_Automatically__c == TRUE && parentAccount.Billing_Type__c == 'In Advance' && parentAccount.Invoice_Consolidation__c == TRUE
				&& !parentAccount.Contacts.IsEmpty() && validateEmail(parentAccount.Contacts.get(0).Email)){
			return true;
		}
		else{
			return false;
		}
	}

	/*
	*  @description    				Method which determines whether an email address is valid
   	*  @param  email  				Email to validate
   	*  @return    					Boolean whether the email is valid
	*/
	private static Boolean validateEmail(String email) {
		Boolean result = true;
		String emailRegex = '^[a-zA-Z0-9._|\\\\%#~`=?&/$^*!}{+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,4}$'; 
		Pattern MyPattern = Pattern.compile(emailRegex);
		Matcher MyMatcher = MyPattern.matcher(email);

		if (!MyMatcher.matches()){ 
		    result = false;
		}
		return result;	
	}

	/*
	*  @description    							Method which finds the invoice pdf as a content version associated with each invoice and adds it to that invoice's invoice send object
   	*  @param  filteredInvoiceIdToInvoiceSend  	Map invoice id -> invoice send
	*/
	private static void addContentVersionsToInvoiceSends(Map<Id,InvoiceSend> filteredInvoiceIdToInvoiceSend){
		
		List<ContentDocumentLink> contentDocumentLinks = [SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId IN :filteredInvoiceIdToInvoiceSend.keySet()];
		System.debug('contentDocumentLinks: '+contentDocumentLinks);
		Map<Id,Id> contentDocumentIdToInvoiceId = SObjectUtil.createSObjectFieldValuesMap(contentDocumentLinks, CONTENT_DOCUMENT_LINK_CONTENT_DOCUMENT_LOOKUP_API_NAME, CONTENT_DOCUMENT_LINK_LINKED_ENTITY_LOOKUP_API_NAME);
		List<ContentVersion> contentVersions = [SELECT VersionData, ContentDocumentId FROM ContentVersion WHERE IsLatest = TRUE AND FileType = 'PDF' AND ContentDocumentId IN :contentDocumentIdToInvoiceId.keySet()];
		
		for(ContentVersion contentVersion:contentVersions){	
			Id invoiceId = contentDocumentIdToInvoiceId.get(contentVersion.ContentDocumentId);
			InvoiceSend invoiceSend = filteredInvoiceIdToInvoiceSend.get(invoiceId);
			invoiceSend.invoiceContentVersionToSend = contentVersion;
			
		}
	}

	/*
	*  @description    							Method which sends emails with attached invoice pdfs using a list of InvoiceSends
   	*  @param  filteredInvoiceIdToInvoiceSend  	Map invoice id -> invoice send
	*/
	private static void sendEmails(Map<Id,InvoiceSend> filteredInvoiceIdToInvoiceSend){
		List<Messaging.SingleEmailMessage> emailsToSend = new List<Messaging.SingleEmailMessage>();

		for(InvoiceSend invoiceSend:filteredInvoiceIdToInvoiceSend.values()){
			emailsToSend.add(createEmail(invoiceSend.contactToEmail,invoiceSend.invoiceContentVersionToSend));
		}

        if (!Test.isRunningTest()) {
            Messaging.sendEmail(emailsToSend);
        }
	}

	/*
	*  @description    			Method which creates a single Email object with the correct toAddress and the attatched email pdf
   	*  @param  contact  		Contact to send email to
   	*  @param  contentVersion  	File to attatch to email
	*  @return 					Email to send
	*/
	private static Messaging.SingleEmailMessage createEmail(Contact contact, ContentVersion contentVersion){
		Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
		mail.setToAddresses(new List<String>{contact.Email});

		mail.setSenderDisplayName('BPP University');
		mail.setSubject('Your Invoice');
		mail.setPlainTextBody('Please find attatched your invoice' + '\n' + '\n' + 'Regards BPP');

		Messaging.Emailfileattachment attatchment = new Messaging.Emailfileattachment();
        attatchment.setFileName('Invoice' + '-' + contact.Account.Name + '-' + Date.today());
        attatchment.setContentType('PDF');
        attatchment.setBody(contentVersion.VersionData);

   		mail.setFileAttachments(new List<Messaging.Emailfileattachment>{attatchment});
   		return mail;
	}

	/*
	*  @description Inner class to encapsulate data needed to send an invoice
	*/
	private class InvoiceSend{
		private Contact contactToEmail;
		private ContentVersion invoiceContentVersionToSend;

		private InvoiceSend(Contact contactToEmail){
			this.contactToEmail = contactToEmail;
		}
	}
    
}