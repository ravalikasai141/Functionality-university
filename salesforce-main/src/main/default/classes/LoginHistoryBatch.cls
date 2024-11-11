/**********************************************************************
Name: LoginHistoryBatch
Purpose: Generates LoginHistory csv and emails to specified Users
-------                                                             
History                                                             
-------                                                             
VERSION  AUTHOR             DATE              DETAIL                              
0.1 -   David Lovejoy     03/03/2022      INITIAL DEVELOPMENT - BPP-19967
0.2 -   David Lovejoy     16/06/2022      UPDATE - BPP-20387
***********************************************************************/
global class LoginHistoryBatch implements Schedulable, Database.Batchable<Sobject>, Database.Stateful {
    List<UserLoginHistory> userLoginHistoryList = new List<UserLoginHistory>();
    public String query, enteredFromDateStr, enteredToDateStr;

    public LoginHistoryBatch(Date fromDate, Date toDate) {
        String excludedUsers1 = Label.LoginHisoryExclusionList;
        String excludedUsers2 = Label.LoginHisoryExclusionList2;
        String[] excludedUsersSplit1 = excludedUsers1.split(';');
        String[] excludedUsersSplit2 = excludedUsers2.split(';');
        
        List<User> excludedUserList = [SELECT Id FROM User WHERE Username IN: excludedUsersSplit1 OR Username IN: excludedUsersSplit2];
        String userIds = '';
        for (User u : excludedUserList) {
            if (u != null) {
            	userIds += '\'' + u.Id + '\',';
            }
        }
        userIds = userIds.removeEnd(',');

        enteredFromDateStr = fromDate.format();
        DateTime startDateTime = fromDate;
        String unformattedStartDateTimeStr = String.valueOf(startDateTime);
        String startDateTimeStr = formatString(unformattedStartDateTimeStr);
        
        enteredToDateStr = toDate.format();
        DateTime endDateTime = toDate;
        String unformattedEndDateTimeStr = String.valueOf(endDateTime);
        String endDateTimeStr = formatString(unformattedEndDateTimeStr);
        String buildQuery = (Test.isRunningTest()
            ? 'SELECT LoginTime, LoginType, Status, UserId FROM LoginHistory WHERE LoginTime >= {0} AND LoginTime < {1} ORDER BY LoginTime DESC LIMIT 50'
            : 'SELECT LoginTime, LoginType, Status, UserId FROM LoginHistory WHERE LoginTime >= {0} AND LoginTime < {1} AND UserID NOT IN ({2}) ORDER BY LoginTime DESC');
        query = String.format(buildQuery, new List<String>{ startDateTimeStr, endDateTimeStr, userIds });
        System.debug('@LoginHistoryBatch query: ' + query);
    }

    global Database.QueryLocator start(Database.BatchableContext BC) {
        Database.QueryLocator queryLocator = Database.getQueryLocator(query);
        System.debug('@LoginHistoryBatch queryLocator: ' + queryLocator);
        return queryLocator;
    }

    global void execute(Database.BatchableContext BC, List<LoginHistory> loginHistoryList) {
        if (loginHistoryList.size() > 0) {
            Set<Id> userIds = new Set<Id>();
            for (LoginHistory loginHistory : loginHistoryList) {
                if (loginHistory.UserId != null) {
                	userIds.add(loginHistory.UserId);
                }
            }

            Map<Id, User> userMap = new Map<Id, User>([SELECT Username, FirstName, LastName FROM User WHERE Id IN: userIds AND IsActive = true]);
            System.debug(userMap.size());
            for (LoginHistory loginHistory : loginHistoryList) {
                User u = userMap.get(loginHistory.UserId);
                if (u != null) {
                    UserLoginHistory userLoginHistory = new UserLoginHistory();
                    userLoginHistory.userName = u.Username;
                    userLoginHistory.firstName = u.FirstName;
                    userLoginHistory.lastName = u.LastName;
                    userLoginHistory.loginTime = loginHistory.LoginTime;
                    userLoginHistory.loginType = loginHistory.LoginType;
                    userLoginHistory.status = loginHistory.Status;
                    userLoginHistoryList.add(userLoginHistory);
                }
            }
        }
    }

    global void finish(Database.BatchableContext BC) {
        if (userLoginHistoryList.size() > 0) {
            String dateRange = enteredFromDateStr + ' - ' + enteredToDateStr;
            String subject = 'Login History report (' + dateRange + ')';
            Messaging.EmailFileAttachment csvAttachment = createLoginHistoryCSV(userLoginHistoryList, subject);
            if (csvAttachment.getBody() != null) {
                sendLoginHistoyReportEmail(csvAttachment, subject, dateRange);
            }
        }
    }

    public void execute(SchedulableContext SC) {
        Database.executeBatch(this, 2000);
    }

    private static Messaging.EmailFileAttachment createLoginHistoryCSV(List<UserLoginHistory> userLoginHistoryList, String subject) {
        String csvHeader = 'Username,First Name,Last Name,Login Time,Login Type,Status\n';
        String csvFinal;
        String rows = '';
        for (UserLoginHistory userLoginHistory : userLoginHistoryList) {
            rows += userLoginHistory.userName + ',';
            rows += userLoginHistory.firstName + ',';
            rows += userLoginHistory.lastName + ',';
            rows += userLoginHistory.loginTime + ',';
            rows += userLoginHistory.loginType + ',';
            rows += userLoginHistory.status + '\n';
        }
        csvFinal = (rows != '' ? csvHeader + rows : null);

        Messaging.EmailFileAttachment csvAttachment = new Messaging.EmailFileAttachment();
        if (csvFinal != null) {
            csvAttachment.setFileName(subject + '.csv');
            csvAttachment.setBody(Blob.valueOf(csvFinal));
        }
        return csvAttachment;
    }

    private static void sendLoginHistoyReportEmail(Messaging.EmailFileAttachment csvAttachment, String subject, String dateRange) {
        String userEmailAddressesFromLabel = Label.LoginHisoryRecipientList;
        String[] toAddresses = userEmailAddressesFromLabel.split(';');

        Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
        message.setToAddresses(toAddresses);
        message.subject = subject;
        message.setHtmlBody('To whom it may concern, <br/><br/>' + 'Please find attached Login History report (' + dateRange + ').<br/><br/>Kind Regards, <br/><br/> Salesforce Admin');
        message.setFileAttachments(new Messaging.EmailFileAttachment[]{csvAttachment});

        Messaging.SingleEmailMessage[] messages = new List<Messaging.SingleEmailMessage>{message};
        System.debug('messages: ' + messages);
        if (!Test.isRunningTest()) {
            Messaging.SendEmailResult[] results = Messaging.sendEmail(messages);
        }
    }

    private static String formatString(String input) {
        String output;
        output = input.replace(' ', 'T');
        output = output + 'Z';
        return output;
    }

    class UserLoginHistory {
        String userName, firstName, lastName, loginType, status;
        DateTime loginTime;
    }
}