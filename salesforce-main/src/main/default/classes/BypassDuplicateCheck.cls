public with sharing class BypassDuplicateCheck {
    public class Inputs {
        @InvocableVariable(label='Record to Save' required=true)
        public SObject recordToSave;
        @InvocableVariable(
            label='"Insert" or "Update" Action'
            required=true
            description='Switch used to determine if the save action should be insert or update'
        )
        public String insertOrUpdate;
    }

    public class Outputs {
        @InvocableVariable(label='Saved Record')
        public SObject savedRecord;
    }

    @InvocableMethod(
        label='Bypass duplicate check'
        description='Uses an apex DuplicateRuleHeader to allow update on a record that otherwise meets a duplicate rule'
    )
    public static List<BypassDuplicateCheck.Outputs> execute(List<BypassDuplicateCheck.Inputs> inputList) {
        List<BypassDuplicateCheck.OutPuts> outPutList = new List<BypassDuplicateCheck.OutPuts>();
        Map<Integer, SObject> recordsToInsert = new Map<Integer, SObject>();
        Map<Integer, SObject> recordsToUpdate = new Map<Integer, SObject>();
        for (Integer i = 0; i < inputList.size(); i++) {
            BypassDuplicateCheck.Inputs input = inputList[i];
            if (input.insertOrUpdate.toLowerCase() == 'insert') {
                recordsToInsert.put(i, input.recordToSave);
            } else if (input.insertOrUpdate.toLowerCase() == 'update') {
                recordsToUpdate.put(i, input.recordToSave);
            }
        }
        Database.DMLOptions dml = BypassDuplicateCheck.createDMLOption();
        List<Database.SaveResult> saveResultList = new List<Database.SaveResult>();

        if (recordsToInsert.size() != 0) {
            saveResultList.addAll(Database.insert(recordsToInsert.values(), dml));
        }

        if (recordsToUpdate.size() != 0) {
            saveResultList.addAll(Database.update(recordsToUpdate.values(), dml));
        }

        if (saveResultList.size() != 0) {
            BypassDuplicateCheck.debugSaveResults(saveResultList);
        }

        for (Integer i = 0; i < inputList.size(); i++) {
            BypassDuplicateCheck.Outputs output = new BypassDuplicateCheck.Outputs();

            if (recordsToInsert.containsKey(i)) {
                output.savedRecord = recordsToInsert.get(i);
            }
            if (recordsToUpdate.containsKey(i)) {
                output.savedRecord = recordsToUpdate.get(i);
            }

            outPutList.add(output);
        }

        return outPutList;
    }

    public static Database.DMLOptions createDMLOption() {
        Database.DMLOptions dml = new Database.DMLOptions();
        dml.DuplicateRuleHeader.allowSave = true;
        dml.DuplicateRuleHeader.runAsCurrentUser = true;
        return dml;
    }

    public static void debugSaveResults(List<Database.SaveResult> saveResultList) {
        for (Database.SaveResult saveRes : saveResultList) {
            if (saveRes.isSuccess()) {
                System.debug('Save Successful: ' + saveRes.getId());
            } else {
                System.debug(saveRes.getErrors());
            }
        }
    }
}
