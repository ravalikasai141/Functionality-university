global class AddressHistoryBatch implements Schedulable, Database.Batchable<Sobject>, Database.Stateful {
    Map<Id, List<String>> addressHistoryMap = new Map<Id, List<String>>();

    global Database.QueryLocator start(Database.BatchableContext BC) {
        String getFields = 'SELECT Id, ParentId, Parent.Name, Parent.Student__c, Parent.Student__r.Name, Parent.Student__r.ULN__pc, Parent.Student__r.PersonEmail, Parent.Student__r.PersonBirthdate, Parent.Type__c, Field, OldValue, NewValue, CreatedDate FROM Address__History';
        String whereClause = (Test.isRunningTest() ? ' LIMIT 10' : ' WHERE CreatedDate = LAST_N_DAYS:7 AND Parent.Student__r.Student_Study_Types__c INCLUDES (\'Apprenticeship\') AND Parent.Student__r.IsPersonAccount = true AND Field != \'created\' AND Parent.Type__c = \'Home\' ORDER BY CreatedDate, Parent.Student__r.Name LIMIT 49000');
        String query = getFields + whereClause;
        
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<Address__History> addressHistoryList) {
        if (addressHistoryList.size() > 0) {
			for (Address__History addressHistory : addressHistoryList) {
                List<String> addressHistoriesForMap = addressHistoryMap.get(addressHistory.Parent.Student__c);
                if (addressHistoriesForMap == null) {
                    addressHistoriesForMap = new List<String>();
                    addressHistoryMap.put(addressHistory.Parent.Student__c, addressHistoriesForMap);
                }
                String dateOfBirth = (addressHistory.Parent.Student__r.PersonBirthdate != null ? addressHistory.Parent.Student__r.PersonBirthdate.format() : null);
                addressHistoriesForMap.add(addressHistory.Parent.Student__r.ULN__pc + ';' + addressHistory.Parent.Student__r.Name + ';' + addressHistory.Parent.Student__r.PersonEmail + ';' + dateOfBirth + ';' + addressHistory.ParentId  + ';' + addressHistory.Parent.Name + ';' + addressHistory.Parent.Type__c + ';' + addressHistory.Field + ';' + addressHistory.OldValue + ';' + addressHistory.NewValue  + ';' + addressHistory.CreatedDate);
            }
        }
    }

    global void finish(Database.BatchableContext BC) {
        if (!addressHistoryMap.isEmpty()) {
            Date oneWeekAgo = System.today().addDays(-7);
            String subject = 'Address History (w/c ' + oneWeekAgo.format() + ')';
            Messaging.EmailFileAttachment csvAttachment = createAddressHistoryCSV(addressHistoryMap, subject);
            if (csvAttachment.getBody() != null) {
                sendAddressHistoyReportEmail(csvAttachment, subject);
            }
        }
    }

    public void execute(SchedulableContext SC) {
        Database.executeBatch(this);
    }

    private static Messaging.EmailFileAttachment createAddressHistoryCSV(Map<Id, List<String>> addressHistoryMap, String subject) {
        String csvHeader = 'Student Id,ULN,Student Name,Email,Date of Birth,Address Id,Address Name,Address Type,Field Changed,Old Value,New Value,Last Modified\n';
        String rows = '';
        
        for (Id studentId : addressHistoryMap.keyset()) {
            for (String addressHistory : addressHistoryMap.get(studentId)) {
                rows += studentId + ',';

                List<String> splitAddressHistory = addressHistory.split(';');
                for (Integer i = 0; i < splitAddressHistory.size(); i++) {
                    String value = (splitAddressHistory.get(i) != 'null' ? splitAddressHistory.get(i) : '');
                    rows += (i != splitAddressHistory.size()-1 ? value + ',' : value + '\n');
                }
            }
        }
        String csvFinal = (rows != '' ? csvHeader + rows : null);

        Messaging.EmailFileAttachment csvAttachment = new Messaging.EmailFileAttachment();
        if (csvFinal != null) {
            csvAttachment.setFileName(subject + '.csv');
            csvAttachment.setBody(Blob.valueOf(csvFinal));
        }
        return csvAttachment;
    }

    private static void sendAddressHistoyReportEmail(Messaging.EmailFileAttachment csvAttachment, String subject) {
        String userEmailAddressesFromLabel = Label.AddressHistoryRecipientList;
        String[] toAddresses = userEmailAddressesFromLabel.split(';');

        Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
        message.setToAddresses(toAddresses);
        message.subject = subject;
        message.setHtmlBody('To whom it may concern, <br/><br/>' + 'Please find attached Address History report.<br/><br/>Kind Regards, <br/><br/> Salesforce Admin');
        message.setFileAttachments(new Messaging.EmailFileAttachment[]{csvAttachment});

        Messaging.SingleEmailMessage[] messages = new List<Messaging.SingleEmailMessage>{message};
        System.debug('messages: ' + messages);
        if (!Test.isRunningTest()) {
            Messaging.SendEmailResult[] results = Messaging.sendEmail(messages);
        }
    }
}