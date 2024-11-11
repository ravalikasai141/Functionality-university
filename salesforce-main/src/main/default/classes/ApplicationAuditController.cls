public without sharing class ApplicationAuditController {

    @AuraEnabled(cacheable=true)
    public static List<Object> fetchAudits(Id opportunityId) {
        try {
            ApplicationAudit audit = new ApplicationAudit();
            return audit.fetchAudit(opportunityId);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}
