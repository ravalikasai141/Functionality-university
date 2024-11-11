/**
 * Class called by Create Application Case Flow
 */
public without sharing class ApplicationCaseEmail {
    @TestVisible
    private static Messaging.SingleEmailMessage mail;

    /**
     * Sends email with passed details
     * @param  emailInfo recipient, email content and case to attatch email to
     */
    @InvocableMethod
    public static void generateEmail(List<EmailInfo> emailInfos) {
        EmailInfo emailInfo = emailInfos[0];

        EmailTemplate emailTemplate = [
            SELECT HtmlValue
            FROM EmailTemplate
            WHERE DeveloperName = 'Application_Case'
        ];

        mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(new List<String>{ emailInfo.recipient });
        mail.setWhatId(emailInfo.caseId);

        String htmlValue = emailTemplate.HtmlValue.replace('{EMAIL_BODY}', emailInfo.emailContent);
        String threadId = [SELECT Thread_Id__c FROM Case WHERE Id = :emailInfo.caseId].Thread_Id__c;
        mail.setSubject(emailInfo.subject + ' [ ' + threadId + ' ]');
        htmlValue = htmlValue.replace('{CASE_THREAD}', threadId);
        mail.setHtmlBody(htmlValue);

        String plainTextValue = stripTags(emailInfo.emailContent + threadId);
        mail.setPlainTextBody(plainTextValue);

        if (!Test.isRunningTest()) {
            Id senderEmail = [
                    SELECT Id
                    FROM OrgWideEmailAddress
                    WHERE displayName = 'Apprentice Onboarding'
                ]
                .get(0)
                .Id;

            mail.setOrgWideEmailAddressId(senderEmail);

            Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ mail });
        }
    }

    /**
     * strip html tags from text
     * @param  text text to change
     */
    private static String stripTags(String text) {
        Map<String, String> patternReplaceMap = new Map<String, String>{
            '</(br|li|h.)*>' => '\n',
            '</p>' => '\n\n',
            '<.*?>' => '',
            '&nbsp;' => ' ',
            '&amp;' => '&',
            '&lt;' => '<',
            '&gt;' => '>'
        };

        for (String regex : patternReplaceMap.keySet()) {
            String replaceWith = patternReplaceMap.get(regex);

            Pattern newlinePattern = Pattern.compile(regex);
            text = newlinePattern.matcher(text).replaceAll(replaceWith);
        }

        return text;
    }

    // class for variables passed from flow
    public class EmailInfo {
        @InvocableVariable
        public Id caseId;

        @InvocableVariable
        public String subject;

        @InvocableVariable
        public String emailContent;

        @InvocableVariable
        public String recipient;
    }
}
