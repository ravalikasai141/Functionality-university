@isTest
public class ApplicationCaseEmailTest {
    @isTest
    static void itShouldGenerateEmail() {
        // GIVEN a case
        Case testCase = new Case(Query_Type__c = 'Additional Information');
        insert testCase;

        ApplicationCaseEmail.EmailInfo emailInfo = new ApplicationCaseEmail.EmailInfo();
        emailInfo.caseId = testCase.Id;
        emailInfo.subject = 'TEST EMAIL';
        emailInfo.emailContent = 'TEST EMAIL BODY';
        emailInfo.recipient = 'email@email.invalid';

        // WHEN generateEmail is called
        System.Test.startTest();
        ApplicationCaseEmail.generateEmail(new List<ApplicationCaseEmail.EmailInfo>{ emailInfo });
        System.Test.stopTest();

        // THEN the email is set with correct values
        Assert.isTrue(ApplicationCaseEmail.mail.subject.contains('TEST EMAIL'), 'Expect subject to contain TEST EMAIL');
        String threadId = [SELECT Thread_Id__c FROM Case WHERE Id = :testCase.Id].Thread_Id__c;
        Assert.isTrue(ApplicationCaseEmail.mail.HtmlBody.contains(threadId), 'Expect email body to contain case id');
    }
}
