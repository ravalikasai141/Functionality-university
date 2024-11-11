public class DocumentServiceCalloutResult {
    @AuraEnabled
    public String documentId;

    @AuraEnabled
    public String responseURL;

    @AuraEnabled
    public Boolean inserted;

    @AuraEnabled
    public String documentDetail;
}
