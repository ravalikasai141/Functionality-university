@isTest
public class TestUtilitiesTest {
    @isTest
    static void itShouldReturnStringWithLengthOfField() {
        // GIVEN a field
        // WHEN we call generateValueOfFieldLength
        Test.startTest();
        String returnedString = TestUtilities.generateValueOfFieldLength('Account', 'Name');
        Test.stopTest();

        // THEN a string of same length is returned
        Assert.areEqual(256, returnedString.length());
    }

    @isTest
    static void itShouldAddUsersToPublicGroup() {
        String groupName = 'Admin_Alert_Recipients';

        // GIVEN a Public Group with no members
        delete [SELECT Id FROM GroupMember WHERE Group.DeveloperName = :groupName];

        // AND an existing User to add to the group
        User existingUser = new User(Id = UserInfo.getUserId());

        // WHEN we call addUsersToGroup
        Test.startTest();
        TestUtilities.addUsersToGroup(new List<User>{ existingUser }, groupName);
        Test.stopTest();

        // THEN the User should have been added to the group
        List<GroupMember> groupMembers = [SELECT Id, UserOrGroupId FROM GroupMember WHERE Group.DeveloperName = :groupName];
        Assert.areEqual(1, groupMembers.size());
        Assert.areEqual(existingUser.Id, groupMembers[0].UserOrGroupId);
    }
}
