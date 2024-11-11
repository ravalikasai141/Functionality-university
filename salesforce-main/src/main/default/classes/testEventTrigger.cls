@isTest
private class testEventTrigger {
	static testMethod void myUnitTest() {
    	Programme__c pgrm = new Programme__c();
       	pgrm.Name = 'Test Program';
       	pgrm.BNR_FieldOfStudy_Code__c = 'ELEC';
       	pgrm.Microsite_Enabled__c = true;
       	pgrm.Programme_Status__c = 'Validated';
       	pgrm.School__c = 'Test School';
       	insert pgrm;
        	
       	Campaign camnew = new Campaign();
       	camnew.StartDate   = system.today();
       	camnew.RecordTypeId=Schema.sObjectType.Campaign.getRecordTypeInfosByName().get('Campaign').getRecordTypeId();
       	camnew.Programme__c   = pgrm.Id;
       	camnew.Name = 'Test Campaign' ;
       	camnew.isActive   =  true ;
       	insert camnew;
       	camnew.Name = camnew.Name+'test';
       	update camnew;
    }
}