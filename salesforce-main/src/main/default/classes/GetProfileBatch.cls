public with sharing class GetProfileBatch implements Database.Batchable<SObject>, Database.AllowsCallouts, Database.Stateful {
    private String query;

    private Map<Id, String> errors;

    public GetProfileBatch(String query) {
        this.query = query;
        this.errors = new Map<Id, String>();
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext bc, List<Opportunity> opps) {
        for (Opportunity opp : opps) {
            try {
                String result = GetProfileIdController.performProfileIdCallout(opp.AccountId);
                if (result != 'Success' && result != null) {
                    errors.put(opp.AccountId, result);
                }
            } catch (Exception e) {
                errors.put(opp.AccountId, 'Unexpected error: ' + e.getMessage());
            }
        }
    }

    public void finish(Database.BatchableContext bc) {
        if (!errors.isEmpty()) {
            createErrorFile();
        }
    }

    private void createErrorFile() {
        String filename = 'GetProfleFailures_' + DateTime.now();
        String fileData = 'AccountId, Error\n';

        for (Id accId : errors.keySet()) {
            fileData += String.format('{0}, {1}\n', new List<String>{ accId, errors.get(accId) });
        }

        ContentVersion version = new ContentVersion();
        version.ContentLocation = 'S';
        version.Title = filename;
        version.pathOnClient = filename + '.csv';
        version.VersionData = Blob.valueOf(fileData);

        insert version;
    }
}
