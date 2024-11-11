@isTest
public class TestUtilities {
    /**
     * creates string with length of a given field
     * @param  sObjectType the sObject the field is on
     * @param  fieldName   the field to get length from
     * @return             string with length of field
     */
    public static String generateValueOfFieldLength(String sObjectType, String fieldName) {
        Integer fieldLength = Schema.getGlobalDescribe()
            .get(sObjectType)
            .getDescribe()
            .fields
            .getMap()
            .get(fieldName)
            .getDescribe()
            .getLength();

        return generateValueOfLength(fieldLength + 1);
    }

    /**
     * generates string of given length
     * @param  length length to use
     * @return     string of length
     */
    public static String generateValueOfLength(Integer length) {
        String fieldValue = '';

        for (Integer i = 0; i < length; i++) {
            fieldValue += 'a';
        }
        return fieldValue;
    }

    /**
     * Queries out a Public Group with the provided Group Name and adds all given users
     * @param  usersToAdd  List of Users to add to the group
     * @param  groupName  The developer name of the group that should be added to
     */
    public static void addUsersToGroup(List<User> usersToAdd, String groupName) {
        Id groupIdToAddTo = [SELECT Id FROM Group WHERE DeveloperName = :groupName LIMIT 1].Id;

        List<GroupMember> groupMembersToInsert = new List<GroupMember>();
        for (User currentUser : usersToAdd) {
            groupMembersToInsert.add(new GroupMember(GroupId = groupIdToAddTo, UserOrGroupId = currentUser.Id));
        }

        insert groupMembersToInsert;
    }

    /**
     * Adds a killswitch record to the Killswitch map for mocking in tests
     * @param  killswitchName  The name of the killswitch to mock
     * @param  isActive  Whether the Killswitch is enabled or not
     */
    public static void mockKillswitch(String killswitchName, Boolean isActive) {
        Killswitch.killSwitchSettingByName.put(
            killswitchName,
            new Killswitch_Setting__mdt(
                DeveloperName = killswitchName,
                Prod_Enabled__c = isActive,
                Sandbox_Enabled__c = isActive
            )
        );
    }
}
