public class BannerApplicationBatch implements Database.Batchable<SObject>, Database.AllowsCallouts, Database.Stateful {
    private String query;

    private Map<Id, String> errors;

    public BannerApplicationBatch(String query) {
        this.query = query;
        this.errors = new Map<Id, String>();
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext bc, List<Opportunity> opps) {
        for (Opportunity opp : opps) {
            try {
                String result = submitAppBController.submitApp(opp.Id);
                if (result != 'Success' && result != null) {
                    errors.put(opp.Id, result);
                }
            } catch (Exception e) {
                errors.put(opp.Id, 'Unexpected error: ' + e.getMessage());
            }
        }
    }

    public void finish(Database.BatchableContext bc) {
        if (!errors.isEmpty()) {
            createErrorFile();
        }
    }

    private void createErrorFile() {
        String filename = 'BannerSubmissionFailures_' + DateTime.now();
        String fileData = 'OpportunityId, Error\n';

        for (Id oppId : errors.keySet()) {
            fileData += String.format('{0}, {1}\n', new List<String>{ oppId, errors.get(oppId) });
        }

        ContentVersion version = new ContentVersion();
        version.ContentLocation = 'S';
        version.Title = filename;
        version.pathOnClient = filename + '.csv';
        version.VersionData = Blob.valueOf(fileData);

        insert version;
    }
}
