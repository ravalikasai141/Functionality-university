@isTest
public class EmailUtilsTest {
    
    @isTest
    static void testEmailUtils() {
        Map<Id, String> userIdToMessage = new Map<Id, String>{
            UserInfo.getUserId() => 'test'
        };
        EmailUtils.sendEmailToUsers(userIdToMessage, 'test');
    }
}