global class SOPAttachmentBatch implements Schedulable, Database.Batchable<Sobject>, Database.Stateful {
    List<Attachment> attachmentList = new List<Attachment>();
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        String query = 'SELECT CreatedDate, Id, Name, ParentId FROM Attachment WHERE Name LIKE \'%SOP%\' AND CreatedDate = TODAY ORDER BY CreatedDate';
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<Attachment> attachments) {
        attachmentList.addAll(attachments);
    }

    global void finish(Database.BatchableContext BC) {
        if (attachmentList.size() > 0) {
            Messaging.EmailFileAttachment csvAttachment = createSOPAttachmentCSV(attachmentList);
            if (csvAttachment.getBody() != null) {
                sendSOPAttachmentCSV(csvAttachment);
            }
        }
    }

    public void execute(SchedulableContext SC) {
        Database.executeBatch(this, 200);
    }

    private static Messaging.EmailFileAttachment createSOPAttachmentCSV(List<Attachment> attachmentList) {
        String csvHeader = 'CreatedDate,Id,Name,ParentId\n';
        String csvFinal;
        String rows = '';
        for (Attachment attachment : attachmentList) {
            rows += attachment.CreatedDate + ',';
            rows += attachment.Id + ',';
            rows += attachment.Name + ',';
            rows += attachment.ParentId + '\n';
        }
        csvFinal = (rows != '' ? csvHeader + rows : null);

        Messaging.EmailFileAttachment csvAttachment = new Messaging.EmailFileAttachment();
        if (csvFinal != null) {
            csvAttachment.setFileName('SOP Uploaded Report - ' + System.today() + '.csv');
            csvAttachment.setBody(Blob.valueOf(csvFinal));
        }
        return csvAttachment;
    }

    private static void sendSOPAttachmentCSV(Messaging.EmailFileAttachment csvAttachment) {
        String userEmailAddressesFromLabel = Label.SOPReportRecipientList;
        String[] toAddresses = userEmailAddressesFromLabel.split(';');

        Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
        message.setToAddresses(toAddresses);
        message.subject = 'SOP Uploaded Report - ' + System.today();
        message.setHtmlBody('To whom it may concern, <br/><br/>' + 'Please find attached SOP Uploaded report.<br/><br/>Kind Regards, <br/><br/> Salesforce Admin');
        message.setFileAttachments(new Messaging.EmailFileAttachment[]{csvAttachment});

        Messaging.SingleEmailMessage[] messages = new List<Messaging.SingleEmailMessage>{message};
        System.debug('messages: ' + messages);
        if (!Test.isRunningTest()) {
            Messaging.SendEmailResult[] results = Messaging.sendEmail(messages);
        }
    }
}