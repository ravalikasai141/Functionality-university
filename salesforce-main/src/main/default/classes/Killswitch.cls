public without sharing class Killswitch {
    // variables for killswitch names
    public static final String BLOCK_INBOUND_EVENTS = 'AllInboundEvents';
    public static final String BLOCK_OUTBOUND_EVENTS = 'AllOutboundEvents';
    public static final String DOCUMENT_SERVICE_KILLSWITCH = 'BlockDocumentCallouts';
    public static final String JOIN2_DOC_KILLSWITCH = 'DocumentJOIN2';
    public static final String INTEGRATION_CONFIG_KILLSWITCH = 'LegacyBPPIntegrationConfig';

    // Used to map inbound event types to their corresponding killswitch records
    public static final Map<string, String> INBOUND_PROCESSOR_MAP = new Map<String, String>{
        'applicationCreated' => 'EventInApplicationCreate',
        'applicationUpdated' => 'EventInApplicationUpdate',
        'applicationStageChanged' => 'EventInApplicationStageChanged',
        'applicationEligibilitySubmitted' => 'EventInApplicationEligibilitySubmit',
        'userAccountUpdated' => 'EventInUserAccountUpdate',
        'requestCallbackForm' => 'EventInRequestCallbackForm'
    };

    // used to store the killswitch to allow mocking
    @TestVisible
    private static Map<String, Killswitch_Setting__mdt> killSwitchSettingByName = new Map<String, Killswitch_Setting__mdt>();

    /**
     * Checks if killswitch is enabled
     * @param  killswitchName name of killswitch to check
     * @return                return if killswitch is enabled
     */
    public static boolean isEnabled(String killswitchName) {
        Killswitch_Setting__mdt killSwitchSetting = killSwitchSettingByName.get(killswitchName);

        if (killSwitchSetting == null && !killSwitchSettingByName.containsKey(killswitchName)) {
            killSwitchSetting = Killswitch_Setting__mdt.getInstance(killswitchName);
            killSwitchSettingByName.put(killswitchName, killSwitchSetting);
        }

        if (killSwitchSetting == null) {
            return false;
        }

        return (OrgUtilities.isSandbox ? killSwitchSetting.Sandbox_Enabled__c : killSwitchSetting.Prod_Enabled__c);
    }
}
