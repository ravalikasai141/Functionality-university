/**
 * General utilities methods, not relating to specific functionality
 */
public without sharing class OrgUtilities {
    /**
     * variable for whether the current org is a sandbox
     * @return   boolean
     */
    public static Boolean isSandbox {
        get {
            if (isSandbox == null) {
                isSandbox = [SELECT IsSandbox FROM Organization LIMIT 1].IsSandbox;
            }
            return isSandbox;
        }
        set;
    }
}
