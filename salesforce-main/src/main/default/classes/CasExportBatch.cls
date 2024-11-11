global class CasExportBatch implements Schedulable, Database.Batchable<Sobject>, Database.Stateful {
    List<Opportunity> opportunityList = new List<Opportunity>();

    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator([SELECT Id FROM Opportunity WHERE CAS_status__c = 'Ready to Assign' LIMIT 49000]);
    }

    global void execute(Database.BatchableContext BC, List<Opportunity> retrievedOpportunities) {
        System.debug('@CasExportBatch Opportunities to process: ' + retrievedOpportunities.size());
        opportunityList.addAll(retrievedOpportunities);
    }

    global void finish(Database.BatchableContext BC) {
        if (opportunityList.size() > 0) {
            Messaging.EmailFileAttachment attachment = createCasXmlFile();
            if (attachment.getBody() != null) {
                sendCASEmail(attachment);
            }
        }
    }

    public void execute(SchedulableContext SC) {
        Database.executeBatch(this);
    }

    private static Messaging.EmailFileAttachment createCasXmlFile() {
        String startTag = '<?xml version="1.0" encoding="ISO-8859-1" standalone="yes"?><ns2:BulkFileUploadGeneralRootElement xmlns:ns2="http://homeoffice.gov.uk/immigration/migrant/cas/bulk-cas-upload-200910" xmlns="http://homeoffice.gov.uk/immigration/migrant/cas/bulk-cas-common-200910">';
        String endTag = '</ns2:BulkFileUploadGeneralRootElement>';
        
        CasData casData = new CasData();
        XMLSerializer serializer = new XMLSerializer();
        String serializedXML = serializer.serialize(casData, true, null);
        String xmlFinal = startTag + serializedXML + endTag;

        Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
        attachment.setFileName('CASImport.xml');
        attachment.setBody(Blob.valueOf(xmlFinal));
        return attachment;
    }

    private static void sendCASEmail(Messaging.EmailFileAttachment attachment) {
        String userEmailAddressesFromLabel = Label.CasExportRecipientList;
        List<String> toAddresses = userEmailAddressesFromLabel.split(';');
        String orgName = UserHelper.getOrgName();

        Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
        message.setToAddresses(toAddresses);
        message.subject = orgName + 'CAS Export - ' + String.valueOf(Date.today()).removeEnd(' 00:00:00');
        message.setHtmlBody('To whom it may concern, <br/><br/>' + 'Please find attached CAS Export file.<br/><br/>Kind Regards, <br/><br/> Salesforce Admin');
        message.setFileAttachments(new Messaging.EmailFileAttachment[]{attachment});

        Messaging.SingleEmailMessage[] messages = new List<Messaging.SingleEmailMessage>{message};
        if (!Test.isRunningTest()) {
            Messaging.SendEmailResult[] results = Messaging.sendEmail(messages);
        }
    }
}