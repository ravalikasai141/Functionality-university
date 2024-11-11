/**********************************************************************
Name: CopyLeadCountryValuesBatch
Purpose: Copies the value from Country of Birth and Country of Residence from old fields to new fields created                 
-------                                                             
History                                                             
-------                                                             
VERSION  AUTHOR             DATE              DETAIL                              
0.1 -   Prema Medasani     03/04/2018      INITIAL DEVELOPMENT  
***********************************************************************/
global class CopyLeadCountryValuesBatch implements Database.Batchable<Sobject>, Database.Stateful
{
    
    global Map<Id,String> countOfBirth = new Map<Id,String>();
    global Map<Id,String> countOfResi = new Map<Id,String>();
    global set<String> countrynames = new set<String>();
    global Map<String,Id> countryNameIdmap = new Map<String,Id>();
    global Map<Id,Lead> maptoupdate = new Map<Id,Lead>();
  
    global Database.QueryLocator start(Database.BatchableContext BC)
    {
        if(Test.isRunningTest())
        {
            return Database.getQueryLocator([select id, Name,Country_of_Birth_old__c,Country_of_Residence_old__c, Country_of_Birth__c, Country_of_Residence__c from Lead where ((Country_of_Birth_old__c != null and Country_of_Birth_old__c != '') and (Country_of_Residence_old__c != null and Country_of_Residence_old__c != '')) and (Name = 'Test LeadPM1' or Name = 'Test LeadPM2' or Name = 'Test LeadPM3') and isconverted=false limit 10]);
        }
        else
        {
            return Database.getQueryLocator([select id, Name,Country_of_Birth_old__c,Country_of_Residence_old__c, Country_of_Birth__c, Country_of_Residence__c from Lead where ((Country_of_Birth_old__c != null and Country_of_Birth_old__c != '') or (Country_of_Residence_old__c != null and Country_of_Residence_old__c != '')) and isconverted=false limit 40000]);
        }
    }
    global void execute(Database.BatchableContext BC, List<Lead> scope)
    {
        system.debug('scope items are'+scope);

        for(Lead lead: scope)
        {
            if(lead.Country_of_Birth_old__c != null)
            {
                countOfBirth.put(lead.Id, lead.Country_of_Birth_old__c);
                countrynames.add(lead.Country_of_Birth_old__c);
            }
            
            if(lead.Country_of_Residence_old__c != null)
            {
                countOfResi.put(lead.Id, lead.Country_of_Residence_old__c);
                countrynames.add(lead.Country_of_Residence_old__c);
            }
        }
        system.debug('countOfBirth contents:'+countOfBirth);
        system.debug('countOfResi contents:'+countOfResi);
        
        if(scope.size()>0 && countrynames.size()>0)
        { 
            system.debug('countrynames contents: '+countrynames);
            for(country_list__c country : [select id, name from country_list__c where name=:countrynames])
            {
                if(country.Name != null)
                {
                    countryNameIdmap.put(country.Name,country.Id);
                }
            }
            system.debug('countryNameIdmap contents: '+countryNameIdmap);
            
            if(countryNameIdmap.size()>0)
            {
                for(Lead lead: scope)
                {
                    if(lead.Country_of_Birth_old__c != null)
                    { 
                        if(countryNameIdmap.containskey(lead.Country_of_Birth_old__c))
                        { 
                            lead.Country_of_Birth__c = countryNameIdmap.get(lead.Country_of_Birth_old__c);
                            maptoupdate.put(lead.Id,lead);
                            system.debug('mapvalues1: '+maptoupdate);
                        }
                    }
                    
                    if(lead.Country_of_Residence_old__c != null)
                    {
                        if(countryNameIdmap.containskey(lead.Country_of_Residence_old__c))
                        {   
                            if(maptoupdate.containskey(lead.Id))
                            {
                                maptoupdate.get(lead.Id).Country_of_Residence__c = countryNameIdmap.get(lead.Country_of_Residence_old__c);
                                system.debug('mapvalues2: '+maptoupdate);
                            }
                            
                            else
                            { 
                                lead.Country_of_Residence__c = countryNameIdmap.get(lead.Country_of_Residence_old__c);
                                maptoupdate.put(lead.Id,lead);
                                system.debug('mapvalues3: '+maptoupdate);
                            }
                            
                        }
                    }
                }
            }
        } 
        
        if(maptoupdate.size()>0)
        {
            update maptoupdate.values();
        } 
    }
    global void finish(Database.BatchableContext BC)
    {
        
    }
}