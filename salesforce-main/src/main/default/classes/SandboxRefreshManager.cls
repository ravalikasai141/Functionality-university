global class SandboxRefreshManager implements SandboxPostCopy {
    global void runApexClass(SandboxContext context) {
        System.debug(context.organizationId()+' '+context.sandboxId()+' '+context.sandboxName());
        updateCustomSetting();
        updateRemoteSiteSetting();
        recordGenerator();
        maskObjects();
    }
    
    /* Bypass all triggers */
    public static void updateCustomSetting(){
        
        List<Process_Bypasses__c >  processBypasses  =   [SELECT Id, Name, Bypass_All_Triggers__c, Bypass_Process_Builder_Handlers__c, Bypass_Record_Triggered_Flows__c FROM Process_Bypasses__c];
        for(Process_Bypasses__c  pb : processBypasses) {
            pb.Bypass_All_Triggers__c  = true;
            pb.Bypass_Process_Builder_Handlers__c  = true;
            pb.Bypass_Record_Triggered_Flows__c  = true;
        }
        update processBypasses;
        
    }
    
    /* Deactivate all remote site settings */
    public static void updateRemoteSiteSetting(){
        Database.executeBatch(new ToolingAPIServiceBatch(), 1);
    }
    
    public static void recordGenerator(){
        Map<String, Record_Generator__mdt> recordGeneratorMap = Record_Generator__mdt.getAll();
        for(String obj: recordGeneratorMap.keySet()){
            String className = recordGeneratorMap.get(obj).Class_Name__c;
            Type processorType = Type.forName(className);
            if (processorType != null) {
				RecordGenerator rg =(RecordGenerator)processorType.newInstance();
                rg.generateRecords();
            }
        }
    }

    public static void maskObjects(){
        MaskSObjectUtils.executeBatch('%');
    }
}