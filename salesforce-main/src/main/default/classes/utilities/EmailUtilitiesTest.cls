@isTest
private class EmailUtilitiesTest {
    @isTest
    public static void itShouldSubmitAnAdminAlertEmail() {
        // GIVEN some details that should be submitted in an email
        String emailSubject = 'Test Subject';
        String emailBody = 'Test Body';

        // Run as the current user to avoid MIXED_DML errors
        System.runAs(new User(Id = UserInfo.getUserId())) {
            // AND there is at least one user added to the Admin_Alert_Recipients group
            TestUtilities.addUsersToGroup(
                new List<User>{ new User(Id = UserInfo.getUserId()) },
                'Admin_Alert_Recipients'
            );
        }

        System.Test.startTest();

        // WHEN the EmailUtilities.submitSystemAlertEmail method is called
        Messaging.SingleEmailMessage sentEmailResults = EmailUtilities.submitSystemAlertEmail(emailSubject, emailBody);

        System.Test.stopTest();

        // THEN the email which was sent should include the provided details
        Assert.areEqual(emailSubject, sentEmailResults.subject);
        Assert.areEqual(emailBody, sentEmailResults.htmlbody);
    }

    @isTest
    public static void itShouldRetrieveAlertRecipientEmailAddresses() {
        // Extract the Timezone of the executing User to avoid time based test issues
        String userTimezone = [
            SELECT TimeZoneSidKey
            FROM User
            WHERE Id = :UserInfo.getUserId()
        ]
        .TimeZoneSidKey;

        // Extract the Admin profile Id
        Id adminProfileId = [
            SELECT Id
            FROM Profile
            WHERE Name = 'System Administrator'
            LIMIT 1
        ]
        .Id;

        // Ensure the Admin Alert Recpients group has been created
        Id adminAlertGroupId = [SELECT Id FROM Group WHERE Group.DeveloperName = 'Admin_Alert_Recipients'].Id;
        Assert.isTrue(adminAlertGroupId != null);

        Integer numberOfUsersToCreate = 2;

        // GIVEN two Users in the Admin Alert Recipient group
        List<User> testUsers = new List<User>();
        for (Integer i = 0; i < numberOfUsersToCreate; i++) {
            testUsers.add(
                new User(
                    Alias = 'TstUsr' + i,
                    Email = 'bpptestuser' + i + '@bpptest.com.invalid',
                    LastName = 'Tester' + i,
                    Username = 'bpp_test_user' + i + '@bpp_test.com',
                    TimeZoneSidKey = userTimezone,
                    LocaleSidKey = 'en_US',
                    EmailEncodingKey = 'UTF-8',
                    LanguageLocaleKey = 'en_US',
                    ProfileId = adminProfileId,
                    IsActive = true
                )
            );
        }
        insert testUsers;

        insert new List<GroupMember>{
            new GroupMember(GroupId = adminAlertGroupId, UserOrGroupId = testUsers[0].Id),
            new GroupMember(GroupId = adminAlertGroupId, UserOrGroupId = testUsers[1].Id)
        };

        System.Test.startTest();

        // WHEN we retrieve the adminAlertRecipientEmails List
        List<String> adminAlertEmailResults = EmailUtilities.adminAlertRecipientEmails;

        System.Test.stopTest();

        // THEN the list returned will contain the Email Addresses of both testing Users
        for (Integer i = 0; i < numberOfUsersToCreate; i++) {
            Assert.isTrue(adminAlertEmailResults.contains('bpptestuser' + i + '@bpptest.com.invalid'));
        }
    }
}
