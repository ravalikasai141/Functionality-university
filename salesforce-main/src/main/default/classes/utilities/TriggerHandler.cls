/**
 * Copyright (c) 2013 Kevin M. O'Hara
 * https://github.com/kevinohara80/sfdc-trigger-framework/
 * Released under MIT License
 */

public virtual class TriggerHandler {
    // static map of handlername, times run() was invoked
    private static Map<String, LoopCount> loopCountMap;
    private static Set<String> bypassedHandlers;

    // Map of each Trigger Handler that should only have each Trigger Context run once to the Trigger Contexts that they have run
    private static Map<String, Set<TriggerContext>> executedOperations;

    // the current context of the trigger, overridable in tests
    @TestVisible
    private TriggerContext context;

    // the current context of the trigger, overridable in tests
    @TestVisible
    private Boolean isTriggerExecuting;

    // The DateTime when the Trigger was initialised
    public static final DateTime INVOKED_AT = DateTime.now();

    // A flag to bypass all triggers regardless of type
    public static Boolean bypassAllTriggers = false;

    // static initialization
    static {
        loopCountMap = new Map<String, LoopCount>();
        bypassedHandlers = new Set<String>();
        executedOperations = new Map<String, Set<TriggerContext>>();
    }

    // constructor
    public TriggerHandler() {
        this.setTriggerContext();
    }

    /***************************************
     * public instance methods
     ***************************************/

    // main method that will be called during execution
    public void run() {
        if (!validateRun()) {
            return;
        }

        addToLoopCount();

        String handlerName = getHandlerName();

        // Track which handlers have been run
        if (executedOperations.containsKey(handlerName)) {
            executedOperations.get(handlerName).add(this.context);
        }

        // dispatch to the correct handler method
        switch on this.context {
            when BEFORE_INSERT {
                this.beforeInsert();
            }
            when BEFORE_UPDATE {
                this.beforeUpdate();
            }
            when BEFORE_DELETE {
                this.beforeDelete();
            }
            when AFTER_INSERT {
                this.afterInsert();
            }
            when AFTER_UPDATE {
                this.afterUpdate();
            }
            when AFTER_DELETE {
                this.afterDelete();
            }
            when AFTER_UNDELETE {
                this.afterUndelete();
            }
        }
    }

    public void setMaxLoopCount(Integer max) {
        String handlerName = getHandlerName();
        if (!TriggerHandler.loopCountMap.containsKey(handlerName)) {
            TriggerHandler.loopCountMap.put(handlerName, new LoopCount(max));
        } else {
            TriggerHandler.loopCountMap.get(handlerName).setMax(max);
        }
    }

    public void clearMaxLoopCount() {
        this.setMaxLoopCount(-1);
    }

    /***************************************
     * public static methods
     ***************************************/

    public static void bypass(String handlerName) {
        TriggerHandler.bypassedHandlers.add(handlerName);
    }

    public static void clearBypass(String handlerName) {
        TriggerHandler.bypassedHandlers.remove(handlerName);
    }

    public static Boolean isBypassed(String handlerName) {
        return TriggerHandler.bypassedHandlers.contains(handlerName);
    }

    public static void clearAllBypasses() {
        TriggerHandler.bypassedHandlers.clear();
    }

    /**
     * Inserts the current Handler name into the executedOperations to ensure each Trigger Operation only runs once
     * @param  handlerName The name of the Trigger Handler to insert
     */
    public static void processOnce(String handlerName) {
        if (!executedOperations.containsKey(handlerName)) {
            executedOperations.put(handlerName, new Set<TriggerContext>());
        }
    }

    /***************************************
     * private instancemethods
     ***************************************/

    @TestVisible
    private void setTriggerContext() {
        this.setTriggerContext(null, false);
    }

    @TestVisible
    private void setTriggerContext(String ctx, Boolean testMode) {
        if (!Trigger.isExecuting && !testMode) {
            this.isTriggerExecuting = false;
            return;
        } else {
            this.isTriggerExecuting = true;
        }

        if ((Trigger.isExecuting && Trigger.isBefore && Trigger.isInsert) || (ctx != null && ctx == 'before insert')) {
            this.context = TriggerContext.BEFORE_INSERT;
        } else if (
            (Trigger.isExecuting && Trigger.isBefore && Trigger.isUpdate) || (ctx != null && ctx == 'before update')
        ) {
            this.context = TriggerContext.BEFORE_UPDATE;
        } else if (
            (Trigger.isExecuting && Trigger.isBefore && Trigger.isDelete) || (ctx != null && ctx == 'before delete')
        ) {
            this.context = TriggerContext.BEFORE_DELETE;
        } else if (
            (Trigger.isExecuting && Trigger.isAfter && Trigger.isInsert) || (ctx != null && ctx == 'after insert')
        ) {
            this.context = TriggerContext.AFTER_INSERT;
        } else if (
            (Trigger.isExecuting && Trigger.isAfter && Trigger.isUpdate) || (ctx != null && ctx == 'after update')
        ) {
            this.context = TriggerContext.AFTER_UPDATE;
        } else if (
            (Trigger.isExecuting && Trigger.isAfter && Trigger.isDelete) || (ctx != null && ctx == 'after delete')
        ) {
            this.context = TriggerContext.AFTER_DELETE;
        } else if (
            (Trigger.isExecuting && Trigger.isAfter && Trigger.isUndelete) || (ctx != null && ctx == 'after undelete')
        ) {
            this.context = TriggerContext.AFTER_UNDELETE;
        }
    }

    // increment the loop count
    @TestVisible
    private void addToLoopCount() {
        String handlerName = getHandlerName();
        if (TriggerHandler.loopCountMap.containsKey(handlerName)) {
            Boolean exceeded = TriggerHandler.loopCountMap.get(handlerName).increment();
            if (exceeded) {
                Integer max = TriggerHandler.loopCountMap.get(handlerName).max;
                throw new TriggerHandlerException(
                    'Maximum loop count of ' + String.valueOf(max) + ' reached in ' + handlerName
                );
            }
        }
    }

    // make sure this trigger should continue to run
    @TestVisible
    private Boolean validateRun() {
        if (!this.isTriggerExecuting || this.context == null) {
            throw new TriggerHandlerException('Trigger handler called outside of Trigger execution');
        }

        if (bypassAllTriggers) {
            return false;
        }

        String handlerName = getHandlerName();
        Set<TriggerContext> executedContexts = executedOperations.get(handlerName);
        if (executedContexts != null && executedContexts.contains(this.context)) {
            return false;
        }

        // does the current user have all triggers disabled in the custom settings
        Process_Bypasses__c bypassSettings = Process_Bypasses__c.getInstance();
        if (bypassSettings.Bypass_All_Triggers__c == true) {
            return false;
        }

        return !TriggerHandler.bypassedHandlers.contains(handlerName);
    }

    @TestVisible
    private String getHandlerName() {
        return this.toString().substringBefore(':');
    }

    /***************************************
     * context methods
     ***************************************/

    // context-specific methods for override
    @TestVisible
    protected virtual void beforeInsert() {
    }
    @TestVisible
    protected virtual void beforeUpdate() {
    }
    @TestVisible
    protected virtual void beforeDelete() {
    }
    @TestVisible
    protected virtual void afterInsert() {
    }
    @TestVisible
    protected virtual void afterUpdate() {
    }
    @TestVisible
    protected virtual void afterDelete() {
    }
    @TestVisible
    protected virtual void afterUndelete() {
    }

    /***************************************
     * inner classes
     ***************************************/

    // inner class for managing the loop count per handler
    @TestVisible
    private class LoopCount {
        private Integer max;
        private Integer count;

        public LoopCount() {
            this.max = 5;
            this.count = 0;
        }

        public LoopCount(Integer max) {
            this.max = max;
            this.count = 0;
        }

        public Boolean increment() {
            this.count++;
            return this.exceeded();
        }

        public Boolean exceeded() {
            return this.max >= 0 && this.count > this.max;
        }

        public Integer getMax() {
            return this.max;
        }

        public Integer getCount() {
            return this.count;
        }

        public void setMax(Integer max) {
            this.max = max;
        }
    }

    // possible trigger contexts
    @TestVisible
    private enum TriggerContext {
        BEFORE_INSERT,
        BEFORE_UPDATE,
        BEFORE_DELETE,
        AFTER_INSERT,
        AFTER_UPDATE,
        AFTER_DELETE,
        AFTER_UNDELETE
    }

    // exception class
    public class TriggerHandlerException extends Exception {
    }
}
