/**
* @description This class is used to deactivate all remote site settings
*/
public class ToolingAPIServiceBatch implements Database.Batchable<ToolingAPIService.RemoteSiteSetting>, Database.AllowsCallouts{
    
    public List<ToolingAPIService.RemoteSiteSetting> start(Database.BatchableContext BC){
        if(!Test.isRunningTest()){
            return ToolingAPIService.getRemoteSiteSettings('', '');
        } else {
            String jsonRequest= '{"records": [{ "Id": "0rp0X0000006CucQAE", "EndpointUrl": "http://www.EndpointUrl.com", "Description": "Description 1", "IsActive": true, "SiteName": "Cloud_8_ContactWorld"}]}';
            List<ToolingAPIService.RemoteSiteSetting> testRemoteSiteSetting = new List<ToolingAPIService.RemoteSiteSetting>();
            testRemoteSiteSetting.add((ToolingAPIService.RemoteSiteSetting)JSON.deserialize(jsonRequest, ToolingAPIService.RemoteSiteSetting.class));
            return testRemoteSiteSetting;
        }
    }
    
    public void execute(Database.BatchableContext BC, List<ToolingAPIService.RemoteSiteSetting> scope){
        List<MaskSObjectError__c> maskSObjectErrorToCreate = new List<MaskSObjectError__c>();
        Boolean isSuccess;
        for(ToolingAPIService.RemoteSiteSetting rs: scope){
            isSuccess = ToolingAPIService.createUpdateRemoteSiteSetting(rs.Id, rs.SiteName, rs.Description, rs.EndpointUrl, '', '');
            if(!isSuccess){
                /* Method to create error log in Mask SObject Error */
                MaskSObjectError__c moe = new MaskSObjectError__c(Name = rs.SiteName, Error__c = 'Error', RecordId__c = rs.Id, SObject__c = rs.EndpointUrl);
                maskSObjectErrorToCreate.add(moe);
            }
        }
        if(!maskSObjectErrorToCreate.isEmpty()) Insert maskSObjectErrorToCreate;
    }
    
    public void finish(Database.BatchableContext BC){
    }
}