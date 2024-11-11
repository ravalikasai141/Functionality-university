public with sharing class EmailUtilities {
    @testVisible
    private static Messaging.SingleEmailMessage ResultingEmailMessage;

    /**
     * Generates an email using the provided Subject and Body parameters and then sends it to any Active users in the Admin Alert Recipients group
     *
     * @param  subject  The Subject to be used in the email
     * @param  body  The body to be used in the email
     *
     * @return The email which was generated and sent
     */
    public static Messaging.SingleEmailMessage submitSystemAlertEmail(String subject, String body) {
        // If there is no recipients to submit an email to, return
        if (adminAlertRecipientEmails == null || adminAlertRecipientEmails.isEmpty()) {
            return null;
        }

        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setSubject(subject);
        email.setToAddresses(adminAlertRecipientEmails);
        email.setHtmlBody(body);

        if (!Test.isRunningTest()) {
            try {
                Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ email });
            } catch (Exception ex) {
                return null;
            }
        } else {
            ResultingEmailMessage = email;
        }

        return email;
    }

    /**
     * Retrieves any active Users added to the "Admin Alert Recipients" Public Group, extracts and then returns their email addresses
     *
     * @return A list of all Active Admin Alert Recipients email addresses
     */
    public static List<String> adminAlertRecipientEmails {
        get {
            if (adminAlertRecipientEmails == null) {
                adminAlertRecipientEmails = new List<String>();

                for (User currentRecipient : [
                    SELECT Email
                    FROM User
                    WHERE
                        isActive = TRUE
                        AND Id IN (
                            SELECT UserOrGroupId
                            FROM GroupMember
                            WHERE Group.DeveloperName = 'Admin_Alert_Recipients'
                        )
                ]) {
                    adminAlertRecipientEmails.add(currentRecipient.Email);
                }
            }
            return adminAlertRecipientEmails;
        }
        set;
    }
}
