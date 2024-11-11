public with sharing class OpportunityProductTriggerHandler {
  public static set<Id> opportunitiesNotLocked = new set<id>();
  public static set<Id> opportunitiesLocked = new set<id>();
  public static void execute(Boolean isBefore, Boolean isAfter, Boolean isInsert, 
                          Boolean isUpdate, Boolean isDelete, Boolean IsExecuting,
                          List<Opportunity_Product__c> newList, Map<Id, Opportunity_Product__c> newMap,
                          List<Opportunity_Product__c> oldList, Map<Id, Opportunity_Product__c> oldMap){
      if(isBefore && (isInsert || isUpdate || isDelete)){
        stopEditingLockedOpps(isBefore, isInsert, isUpdate, isDelete, newList, oldList);
        manageCapacity(isInsert,isUpdate,isDelete,newList,oldList,oldMap);
        if(isUpdate){
          restrictMultiPrimary(newList, newMap, oldMap);          
        } 
        if(isDelete){          
          updateSISfieldOnOppFromPrimaryProduct(isInsert, isUpdate, isDelete, newList, newMap, oldList, oldMap);
        }       
      }
      if(isAfter && isUpdate){
        updateSISfieldOnOppFromPrimaryProduct(isInsert, isUpdate, isDelete, newList, newMap, oldList, oldMap);
      }                        
  }
  
  public static void stopEditingLockedOpps(Boolean isBefore, Boolean isInsert, Boolean isUpdate, Boolean isDelete,
                      List<Opportunity_Product__c> newList, List<Opportunity_Product__c> oldList){
    set<id> newOppIds = new set<id>();   
        list<Opportunity_Product__c> fullList = new list<Opportunity_Product__c>();                 
      if (isDelete) {
        for (Opportunity_Product__c opi : oldList) {
          if (isBefore) {
            fullList.add(opi);
            if (!opportunitiesNotLocked.contains(opi.Opportunity__c) &&
              !opportunitiesLocked.contains(opi.Opportunity__c)) {
              
              newOppIds.add(opi.Opportunity__c);  
            }
          }
        }
      }
      else {
        for (Opportunity_Product__c opi : newList) {
          if (isBefore) {
            fullList.add(opi);
            if (!opportunitiesNotLocked.contains(opi.Opportunity__c) &&
              !opportunitiesLocked.contains(opi.Opportunity__c)) {
              
              newOppIds.add(opi.Opportunity__c);  
            }
          }
        }
      }
      
      if (newOppIds.size() > 0) {
        list<Opportunity> oppList = [Select Id, RecordType.Name From Opportunity Where Id IN :newOppIds];
        for (Opportunity opp : oppList) {
          if (opp.RecordType.Name == 'Locked Application') {
            opportunitiesLocked.add(opp.Id);
          }
          else {
            opportunitiesNotLocked.add(opp.Id);
          }
        }
      }
      
      for (Opportunity_Product__c opi : fullList) {
        if (opportunitiesLocked.contains(opi.Opportunity__c))
          opi.addError('Cannot modify PC Items because the Opportunity is locked');
      }
  }
  
  //Managing capacity
  public static void manageCapacity(Boolean isInsert, Boolean isUpdate, Boolean isDelete, List<Opportunity_Product__c> newList, List<Opportunity_Product__c> oldList, Map<Id, Opportunity_Product__c> oldMap){
    Set<String> pcItIds = new Set<String>();
    Set<String> prdIds = new Set<String>();
    if(isInsert || isUpdate){
      for(Opportunity_Product__c temp:newList){
        if(isInsert || isUpdate){
          prdIds.add(temp.Product__c);
        }    
      }
    }
    
    Map<Id,Product2> mPr = new Map<Id,Product2>([Select p.Id, p.BNR_Used_Capacity__c, p.BNR_Min_Capacity__c, p.BNR_Max_Capacity__c,p.Product_Type__c From Product2 p where p.Id in:prdIds]);
    Product2 p;
    List<Product2> updatePrds = new List<Product2>();
    if(isInsert || isUpdate){
      for(Opportunity_Product__c temp:newList){
        p = mPr.get(temp.Product__c);
        if(p.Product_Type__c == 'OFFERING'){
          if(p.BNR_Used_Capacity__c >= p.BNR_Max_Capacity__c){
            temp.addError('Cannot add this PC Item as the product reached maximum use capacity');
          }
        }
      }
    }
  }
  
  //Stop allowing multiple primary opportunity products
  public static void restrictMultiPrimary(List<Opportunity_Product__c> newList, Map<Id, Opportunity_Product__c> newMap, Map<Id, Opportunity_Product__c> oldMap){
    set<id> newOppIds = new set<id>();
    for(Opportunity_Product__c temp:newList){
      if(temp.Course_Focus__c == 'Primary' && oldMap.get(temp.Id).Course_Focus__c != temp.Course_Focus__c)
        newOppIds.add(temp.Opportunity__c);
    }
    
    Map<Id,Opportunity_Product__c> mIdOP = new Map<Id,Opportunity_Product__c>([Select o.Product__r.Product_Type__c, o.Product__c, o.Opportunity__c, o.Id, o.Course_Focus__c 
                            From Opportunity_Product__c o where o.Product__r.Product_Type__c ='OFFERING' and o.Course_Focus__c = 'Primary' 
                            and o.Opportunity__c in: newOppIds and o.Id not in:newMap.keyset()]);
    Map<String,String> mOppId = new Map<String,String>();
    for(Opportunity_Product__c temp: mIdOP.values()){
      mOppId.put(temp.Opportunity__c,temp.Course_Focus__c);
    }
    for(Opportunity_Product__c temp:newList){
      if(temp.Course_Focus__c == 'Primary' && oldMap.get(temp.Id).Course_Focus__c != temp.Course_Focus__c){
        if(mOppId.containsKey(temp.Opportunity__c)){
          if(temp.Course_Focus__c == mOppId.get(temp.Opportunity__c))
            temp.addError('Cannot have two offerings of type primary');
        }
      }
    }
  }
  
  public static void updateSISfieldOnOppFromPrimaryProduct(Boolean isInsert, Boolean isUpdate, Boolean isDelete,
                  List<Opportunity_Product__c> newList, Map<Id, Opportunity_Product__c> newMap, List<Opportunity_Product__c> oldList, Map<Id, Opportunity_Product__c> oldMap){
    Map<Id,Id> newOppIds = new Map<Id,Id>();
    Set<Id> prdIds = new Set<Id>();
     if(isDelete){
      for(Opportunity_Product__c temp:oldList){
        if(temp.Course_Focus__c == 'Primary'){
          newOppIds.put(temp.Opportunity__c,temp.Product__c);
          prdIds.add(temp.Product__c);
        }
      }
    }else{
      for(Opportunity_Product__c temp:newList){
        if(temp.Course_Focus__c == 'Primary' && oldMap.get(temp.Id).Course_Focus__c != temp.Course_Focus__c){
          newOppIds.put(temp.Opportunity__c,temp.Product__c);
          prdIds.add(temp.Product__c);
        }
      }
    }
    
    Map<Id,Opportunity> mOpps = new Map<Id,Opportunity>([Select Id, BNR_FieldOfStudy_Code__c, 
                     Programme_Application__c, Start_Date__c, Mode__c, Location__c, 
                     BNR_Campus_Code_Text__c, BNR_Degree_Code_Text__c, BNR_Level_Code_Text__c,
                     BNR_Program_Code_Text__c, BNR_Term_Code_Text__c,
                    SFDC_Attribute_Code_Select__c, Record_Source__c,
                                  PC_Attribute_Code__c, PC_Attribute_Code_2__c, PC_Attribute_Code_3__c                           
               From Opportunity
              Where Id in:newOppIds.keyset()]);
    Map<id, Product2> products = new Map<Id, Product2>([Select Id, Programme__c, Programme__r.BNR_FieldOfStudy_Code__c, Start_Date__c, Mode__c, Location__c,
                                                                BNR_Campus_Code__c, BNR_Degree_Code__c, BNR_Level_Code__c, 
                                                                BNR_Program_Code__c, BNR_Term_Code__c, BNR_Attribute_Code__c,IsActive, 
                                                              BNR_Attribute_Code_2__c, BNR_Attribute_Code_3__c
                                                              from Product2 
                                                                where Id in :prdIds ]);
        Product2 courseInstance;
        //List<Schema.PicklistEntry> plistValues = Opportunity.SFDC_Attribute_Code_Select__c.getDescribe().getPicklistValues();
               
        if(isDelete){
          for(Opportunity opp:mOpps.Values()){
        opp.Course_Instance__c = null;  
        opp.BNR_FieldOfStudy_Code__c = null; 
        opp.Programme_Application__c = null;
                opp.Start_Date__c = null;
                opp.Mode__c = null;
                opp.Location__c = null;
                opp.BNR_Campus_Code_Text__c = null;
                opp.BNR_Degree_Code_Text__c = null;
                opp.BNR_Level_Code_Text__c = null;
                opp.BNR_Program_Code_Text__c = null;
                opp.BNR_Term_Code_Text__c = null;
                opp.SFDC_Attribute_Code_Select__c = null;
                opp.PC_Attribute_Code__c = null;
                opp.PC_Attribute_Code_2__c = null;
                opp.PC_Attribute_Code_3__c = null;
      }
        }else{
          for(Opportunity opp:mOpps.Values()){
            courseInstance = products.get(newOppIds.get(opp.Id));
        opp.Course_Instance__c = courseInstance.Id;  
        opp.BNR_FieldOfStudy_Code__c = courseInstance.Programme__r.BNR_FieldOfStudy_Code__c; 
        opp.Programme_Application__c = courseInstance.Programme__c;
                opp.Start_Date__c = courseInstance.Start_Date__c;
                opp.Mode__c = courseInstance.Mode__c;
                opp.Location__c = courseInstance.Location__c;
                opp.BNR_Campus_Code_Text__c = courseInstance.BNR_Campus_Code__c;
                opp.BNR_Degree_Code_Text__c = courseInstance.BNR_Degree_Code__c;
                opp.BNR_Level_Code_Text__c = courseInstance.BNR_Level_Code__c;
                opp.BNR_Program_Code_Text__c = courseInstance.BNR_Program_Code__c;
                opp.BNR_Term_Code_Text__c = courseInstance.BNR_Term_Code__c;
                /*
                for (Schema.PicklistEntry pe : plistValues){
                    if (pe.getLabel().startsWith(courseInstance.BNR_Attribute_Code__c + '~')){
                        opp.SFDC_Attribute_Code_Select__c = pe.getValue();
                        break;
                    }
                }
                */
                if (courseInstance.BNR_Attribute_Code__c == null)
                    opp.PC_Attribute_Code__c = null;
                else
                  opp.PC_Attribute_Code__c = courseInstance.BNR_Attribute_Code__c;
                    
                if (courseInstance.BNR_Attribute_Code_2__c == null)
                    opp.PC_Attribute_Code_2__c = null;
                else  
                  opp.PC_Attribute_Code_2__c = courseInstance.BNR_Attribute_Code_2__c;
                    
                if (courseInstance.BNR_Attribute_Code_3__c == null)
                    opp.PC_Attribute_Code_3__c = null;
        else                    
                  opp.PC_Attribute_Code_3__c = courseInstance.BNR_Attribute_Code_3__c;
                
      }
        }
            
        Database.update(mOpps.Values(),false);     
    
  }
}