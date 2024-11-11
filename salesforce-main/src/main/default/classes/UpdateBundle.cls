@RestResource(urlMapping='/v1.0/UpdateBundle/*')
global with sharing class UpdateBundle{
    global class Bundle {
        public String name;
        public String bundleId;
        public String description;
        public decimal price;
        public List<String> itemIds;
        public List<String> childBundleIds;
    }
    
    global class Response {
        global String status { get; set; }
        
        public Response(String status) {
            this.status = status;
        }
    }
    
    @HttpPost
    global static Response doPost(List<Bundle> bundlesList) {
        //List<Bundle> bundlesList;
        Restrequest req = RestContext.request;
        String reqStr = Json.serialize(bundlesList);
        String endpoint;
        if(req!=null)
            endpoint = req.requestURI; 
        String statusDetails ='Success'; 
        String srvMessage = ''; 
        String response = statusDetails;
        system.debug(req+'here1');
        /*try{
            endpoint = req.requestURI; 
            reqStr = req.requestBody.toString(); 
            //bundlesList = (List<Bundle>)JSON.deserialize(reqStr,List<Bundle>.class);
        }catch(Exception ex){
            system.debug(ex.getMessage());
            statusDetails ='Fail';
            srvMessage = ex.getMessage();
            response = statusDetails + ':'+srvMessage;
            Create_IntegrationLog.writeIncomingLog(endpoint, reqStr, response);  
        }*/
        if(bundlesList != null){
            system.debug(bundlesList);
            List<PC_Bundle__c> upsertPCBundles = new List<PC_Bundle__c>();
            Map<String,List<String>> parentChildBundleIds = new Map<String,List<String>>();
            Set<String> cBundleIds = new Set<String>();
            Set<String> parBundleIds = new Set<String>();
            Set<String> instanceIds = new Set<String>();
            Boolean hasChildBundles = false;
            for(Bundle b: bundlesList){
                if(b.bundleId!=null){
                    parentChildBundleIds.put(b.bundleId,b.childBundleIds);
                    cBundleIds.add(b.bundleId);
                    parBundleIds.add(b.bundleId);
                    if(b.childBundleIds != null){
                        cBundleIds.addAll(b.childBundleIds);
                        hasChildBundles = true; 
                    }
                    if(b.itemIds != null)
                        instanceIds.addAll(b.itemIds);
                    PC_Bundle__c p = new PC_Bundle__c();
                    p.PC_Bundle_Full_Name__c = b.name;                  
                    p.PC_Bundle_Id__c = b.bundleId;
                    p.Description__c = b.description;
                    p.BNR_Price__c = b.price;
                    upsertPCBundles.add(p);
                }
            }
            
            Schema.SObjectField externalKey = PC_Bundle__c.Fields.PC_Bundle_Id__c;
            system.debug(upsertPCBundles);
            if(upsertPCBundles.isEmpty())
                return new Response('Fail: No valid bundle Ids');
            Database.UpsertResult[] ur = Database.upsert(upsertPCBundles, externalKey, false);
            system.debug(upsertPCBundles + 'After Insert');
            for(Database.upsertResult result:ur) {
                //System.assert(result.isSuccess());
                system.debug(result.getId() + 'upsert id');
                system.debug(result.getErrors() + 'upsert fails');
                List<Database.Error> e = result.getErrors();
                if(!e.IsEmpty()){
                    if(e[0].Message != null && e[0].Message != ''){
                        if(statusDetails == 'Success')
                            statusDetails = 'Fail';
                        response = statusDetails + ':' + e[0].Message;
                    }
                }
                    
            }
            Map<String,String> bundleSFId = new Map<String,String>();
            //List<PC_Bundle__c> upsertPCBundles1 = [Select PC_Bundle_Id__c,Id from PC_Bundle__c where PC_Bundle_Id__c in:cBundleIds];
            for(PC_Bundle__c temp: upsertPCBundles){
                bundleSFId.put(temp.PC_Bundle_Id__c,temp.Id);
            }
            
            /* Query for all the instance Ids and check if they have a pc items with this bundle id
             * if yes fill in the look up or else create one
             */
            List<PC_Item__c> upsertPCItems = new List<PC_Item__c>();
            Map<Id,Product2> mProducts = new Map<Id,Product2>([Select p.Instance_Id__c, p.Id,p.Programme__c From Product2 p where p.Instance_Id__c in: instanceIds]);
            Map<String,Product2> mInstanceSFId = new Map<String,Product2>();
            for(Product2 temp: mProducts.values()){
                mInstanceSFId.put(temp.Instance_Id__c,temp);
            }
            
            // filling existing pc items with bundle ids but no look up value to PC bundle object.
            List<PC_Item__c> lstFillLKItems = [Select p.Product__c, p.PC_Bundle__c, p.PC_Bundle_Id__c, p.Id From PC_Item__c p
                                            where p.PC_Bundle_Id__c in: bundleSFId.keyset()];
            
            Database.Deleteresult[] dr = Database.delete(lstFillLKItems,false);
            /*for(PC_Item__c temp : lstFillLKItems){
                temp.PC_Bundle__c = bundleSFId.get(temp.PC_Bundle_Id__c);
                upsertPCItems.add(temp);
            }
            
             //Checking if the combination of bundle and instance already exists in the PC Items
            List<PC_Item__c> lstPCItems = [Select p.Product__c, p.PC_Bundle__c, p.PC_Bundle_Id__c, p.Id, p.Programme__c  From PC_Item__c p
                                            where p.Product__c in: mProducts.keyset()];
            Map<String,Set<String>> mBuPrPcs = new Map<String,Set<String>>();
            for(PC_Item__c temp: lstPCItems){ 
                if(temp.PC_Bundle_Id__c != null){
                    Set<String> s;          
                    if(!mBuPrPcs.containsKey(temp.PC_Bundle_Id__c)){
                        s = new Set<String>();              
                    }else{
                        s = mBuPrPcs.get(temp.PC_Bundle_Id__c);
                    }
                    s.add(temp.Product__c);
                    mBuPrPcs.put(temp.PC_Bundle_Id__c,s); 
                }           
            }*/
            
            for(Bundle b: bundlesList){
                system.debug(bundleSFId + 'sr1');
                //system.debug(mBuPrPcs + 'sr2');
                Set<String> prdIds = new Set<string>();
                if(b.itemIds != null){
                    for(String s: b.itemIds){
                        if(mInstanceSFId.containsKey(s)){
                            //system.debug(prdIds + 'sr3');
                            system.debug(mInstanceSFId.get(s));
                           /* if(mBuPrPcs.containsKey(b.bundleId)){
                                prdIds = mBuPrPcs.get(b.bundleId);                      
                            }
                            if(!prdIds.contains(mInstanceSFId.get(s).Id)){*/
                                PC_Item__c tempPCI = new PC_Item__c();
                                tempPCI.Product__c = mInstanceSFId.get(s).Id;
                                tempPCI.PC_Bundle_Id__c = b.bundleId;
                                tempPCI.PC_Bundle__c = bundleSFId.get(b.bundleId);
                                tempPCI.Programme__c = mInstanceSFId.get(s).Programme__c; 
                                upsertPCItems.add(tempPCI);
                            //}
                        }
                    }
                }
            }
            Database.UpsertResult[] urPCI = Database.upsert(upsertPCItems, false);
            
            /* Getting Ids of all child and parent bundles. Checking if
             * they already have a relation between them, if not then creating a relation.      
             */
            if(hasChildBundles){
                List<PC_Bundle_Extension__c> upsertPCEx = new List<PC_Bundle_Extension__c>();
                
                List<PC_Bundle__c> allPCBs = [Select PC_Bundle_Id__c,Id from PC_Bundle__c where PC_Bundle_Id__c in: cBundleIds];
                Map<String,String> pcbExtSFId = new Map<String,String>();
                for(PC_Bundle__c temp: allPCBs){
                    pcbExtSFId.put(temp.PC_Bundle_Id__c,temp.Id);
                }
                system.debug(pcbExtSFId + 'here 1' + parBundleIds);
                
                
                List<PC_Bundle_Extension__c> deletePCBEx = [Select Id,PC_Parent_Bundle__c, PC_Child_Bundle__c, PC_Parent_Bundle__r.PC_Bundle_Id__c, PC_Child_Bundle__r.PC_Bundle_Id__c,PC_Child_Bundle_Id__c from PC_Bundle_Extension__c 
                                                          where PC_Parent_Bundle__r.PC_Bundle_Id__c in:parBundleIds];
                Database.Deleteresult[] dPCB = Database.delete(deletePCBEx,false);
                
                List<PC_Bundle_Extension__c> parentAsCBEx = [Select Id,PC_Parent_Bundle__c, PC_Child_Bundle__c, PC_Parent_Bundle__r.PC_Bundle_Id__c, PC_Child_Bundle__r.PC_Bundle_Id__c,PC_Child_Bundle_Id__c from PC_Bundle_Extension__c 
                                                          where PC_Child_Bundle_Id__c in:parBundleIds and PC_Child_Bundle__c = null];
                Map<String,Set<String>> parentSetChild = new Map<String,Set<String>>();
                for(PC_Bundle_Extension__c temp: parentAsCBEx){
                    system.debug(temp.PC_Child_Bundle_Id__c + 'here 2');
                    if(pcbExtSFId.containsKey(temp.PC_Child_Bundle_Id__c)) {
                        if(temp.PC_Child_Bundle__c == null){
                            temp.PC_Child_Bundle__c = pcbExtSFId.get(temp.PC_Child_Bundle_Id__c);
                            system.debug(pcbExtSFId.get(temp.PC_Child_Bundle_Id__c) + 'here 2');
                            upsertPCEx.add(temp);
                        }
                    }       
                }
                /*
                List<PC_Bundle_Extension__c> allPCBEx = [Select Id,PC_Parent_Bundle__c, PC_Child_Bundle__c, PC_Parent_Bundle__r.PC_Bundle_Id__c, PC_Child_Bundle__r.PC_Bundle_Id__c,PC_Child_Bundle_Id__c from PC_Bundle_Extension__c 
                                                          where PC_Parent_Bundle__r.PC_Bundle_Id__c in:parentChildBundleIds.keyset() or PC_Child_Bundle_Id__c in:parBundleIds];
                Map<String,Set<String>> parentSetChild = new Map<String,Set<String>>();
                for(PC_Bundle_Extension__c temp: allPCBEx){
                    Set<String> s;
                    if(!parentSetChild.containskey(temp.PC_Parent_Bundle__r.PC_Bundle_Id__c)){
                        s = new Set<String>();
                    }else{
                        s = parentSetChild.get(temp.PC_Parent_Bundle__r.PC_Bundle_Id__c);
                    }
                    s.add(temp.PC_Child_Bundle_Id__c);
                    parentSetChild.put(temp.PC_Parent_Bundle__r.PC_Bundle_Id__c,s);  
                    system.debug(temp.PC_Child_Bundle_Id__c + 'here 2');
                    if(pcbExtSFId.containsKey(temp.PC_Child_Bundle_Id__c)) {
                        if(temp.PC_Child_Bundle__c == null){
                            temp.PC_Child_Bundle__c = pcbExtSFId.get(temp.PC_Child_Bundle_Id__c);
                            system.debug(pcbExtSFId.get(temp.PC_Child_Bundle_Id__c) + 'here 2');
                            upsertPCEx.add(temp);
                        }
                    }       
                }
                */      
                Boolean insertParentChildRelation = true;
                Set<String> childSet;
                for(Bundle b : bundlesList){
                    if(pcbExtSFId.containsKey(b.bundleId)){   
                        if(b.childBundleIds!=null){             
                            for(String s: b.childBundleIds){
                                if(s != null && s != ''){
                                    insertParentChildRelation = true;
                                    if(parentSetChild.containsKey(b.bundleId)){
                                        childSet = parentSetChild.get(b.bundleId);
                                        if(childSet.contains(s)){
                                            insertParentChildRelation = false;
                                        }
                                    }
                                    if(pcbExtSFId.containsKey(s)){                              
                                        if(insertParentChildRelation){
                                            PC_Bundle_Extension__c pcEx = new PC_Bundle_Extension__c();
                                            pcEx.PC_Parent_Bundle__c = pcbExtSFId.get(b.bundleId);
                                            pcEx.PC_Child_Bundle__c = pcbExtSFId.get(s);
                                            pcEx.PC_Child_Bundle_Id__c = s;
                                            upsertPCEx.add(pcEx);
                                        }
                                    }else{
                                        if(insertParentChildRelation ){
                                            PC_Bundle_Extension__c pcEx = new PC_Bundle_Extension__c();
                                            pcEx.PC_Parent_Bundle__c = pcbExtSFId.get(b.bundleId);
                                            pcEx.PC_Child_Bundle_Id__c = s;
                                            upsertPCEx.add(pcEx);
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                
                if(!upsertPCEx.isEmpty())
                    Database.UpsertResult[] PCEx = Database.upsert(upsertPCEx, false);//upsert upsertPCEx;
            }
            Create_IntegrationLog.writeIncomingLog(endpoint, reqStr, response);   
        }
        return new Response(response);
    }
}