public with sharing class EmailUtils {

    public static void sendEmailToUsers(Map<Id, String> userIdToMessageMap, String processName) {
        List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
        for(String userId : userIdToMessageMap.keySet()) {
            String body = userIdToMessageMap.get(userId);
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setTargetObjectId(userId);
            mail.setSenderDisplayName(processName);
            mail.setSubject(processName + ' Results [Org ID: ' + UserInfo.getOrganizationId() +']');
            mail.setPlainTextBody(body);
            mail.setSaveAsActivity(false);
            mails.add(mail);
        }
        if (!Test.isRunningTest()) {
            Messaging.sendEmail(mails);
        }
    }
}