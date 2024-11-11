/**
 * Used to prevent trigger recursion across trigger type and operation type
 */
public without sharing class TriggerExecute {
    /**
     * Stores the trigger operation types against an identifier
     */
    @TestVisible
    private static Map<String, Set<System.TriggerOperation>> executedOperations = new Map<String, Set<System.TriggerOperation>>();

    /**
     * When set to true it will ignore recursion
     * this should only be used in tests.
     */
    @TestVisible
    public static Boolean bypassTrigger = false;

    /**
     * Checks against the identifier and trigger type to see if this is a
     * recursive run of the given trigger
     * @param identifier The trigger identifier
     * @return  False if this trigger operation has already processed
     */
    public static Boolean canExecute(String identifier) {
        if (bypassTrigger) {
            return true;
        }

        if (!executedOperations.containsKey(identifier)) {
            executedOperations.put(identifier, new Set<System.TriggerOperation>());
        }

        if (executedOperations.get(identifier).contains(Trigger.operationType)) {
            return false;
        }

        executedOperations.get(identifier).add(Trigger.operationType);
        return true;
    }

    /**
     * Allow variables to be reset for test classes
     */
    @TestVisible
    private static void reset() {
        bypassTrigger = false;
        executedOperations = new Map<String, Set<System.TriggerOperation>>();
    }
}
