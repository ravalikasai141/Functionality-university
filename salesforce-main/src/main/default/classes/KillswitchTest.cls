@isTest
public class KillswitchTest {
    @isTest
    static void itShouldHandleKillswitchOn() {
        // GIVEN a killswitch
        TestUtilities.mockKillswitch('Test On', true);

        // WHEN Killwitch isEnabled is called
        Test.startTest();
        boolean isEnabled = Killswitch.isEnabled('Test On');
        Test.stopTest();

        // THEN its enabled
        Assert.isTrue(isEnabled);
    }

    @isTest
    static void itShouldHandleNoMatch() {
        // GIVEN we don't have a killswitch
        // WHEN Killwitch isEnabled is called
        Test.startTest();
        boolean isEnabled = Killswitch.isEnabled('Test');
        Test.stopTest();

        // THEN false is returned
        Assert.isFalse(isEnabled);
    }
}
