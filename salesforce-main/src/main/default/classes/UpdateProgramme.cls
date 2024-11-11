@RestResource(urlMapping='/v1.0/UpdateProgramme/*')
global with sharing class UpdateProgramme {
    global class Request {
        public Programme__c programme;
        public List<Item> instances;
    }
    
    global class Item {
        public Product2 instance;
        public List<String> bundleIds;//pc items
    }
    
    global class Response {
        global String status { get; set; }
        
        public Response(String status) {
            this.status = status;
        }
    }
    
    @HttpPost
    global static Response doPost(List<Request> programmeList) {
        //List<Request> programmeList;
        Restrequest req = RestContext.request;
        String reqStr = Json.serialize(programmeList);
        String endpoint;
        if(req!=null)
            endpoint = req.requestURI; 
        String statusDetails ='Success'; 
        String srvMessage = ''; 
        String response = statusDetails;
        /*try{
            endpoint = req.requestURI; 
            reqStr = req.requestBody.toString(); 
            //programmeList = (List<Request>)JSON.deserialize(reqStr,List<Request>.class);
        }catch(Exception ex){
            system.debug(ex.getMessage());
            statusDetails ='Fail';
            srvMessage = ex.getMessage();
            response = statusDetails + ':'+srvMessage;
            Create_IntegrationLog.writeIncomingLog(endpoint, reqStr, response);  
        }*/
        if(programmeList != null){
            system.debug(programmeList);
            Map<String,Programme__c> programmes = new Map<String,Programme__c>();
            Set<String> pIds = new Set<String>();
            
            List<Product2> products = new List<Product2>();
            Set<String> bundleIds = new Set<String>();
            Map<String,Set<String>> insIdSBunIds = new Map<String,Set<String>>();
            Set<String> sBids = null;
            for (Request rT : programmeList) {
                if(rT.programme!=null){
                    programmes.put(rT.Programme.Programme_Id__c,rT.programme);
                    pIds.add(rT.programme.Programme_Id__c);
                }
                if(!rT.instances.isEmpty()){
                    for(Item i : rT.instances ){
                        products.add(i.instance);
                        if(!i.bundleIds.IsEmpty()){
                            sBids = new Set<String>();
                            sBids.addAll(i.bundleIds);
                            insIdSBunIds.put(i.instance.Instance_Id__c,sBids);                  
                            for(String b : i.bundleIds){
                                if(b != null && b != ''){
                                    bundleIds.add(b);
                                }
                            }
                        }
                    }
                }
            }  
            Schema.SObjectField externalKey = Programme__c.Fields.Programme_Id__c;
            system.debug(programmes + 'Prg1');
            if(!programmes.isEmpty()){
                Database.UpsertResult [] ur = Database.upsert(programmes.values(), externalKey, false);
                for(Database.upsertResult result:ur) {
                    //System.assert(result.isSuccess());
                   
                    List<Database.Error> e = result.getErrors();
                    if(!e.IsEmpty()){
                        if(e[0].Message != null && e[0].Message != ''){
                            if(statusDetails == 'Success')
                                statusDetails = 'Fail';
                            response = statusDetails + ':' + e[0].Message;
                        }
                    }
                }
            
            }
            externalKey = Product2.Fields.Instance_Id__c;
            for(Product2 p1: products){
                system.debug(programmes);
                if(p1.BNR_Program_Code__c!=null && p1.BNR_Program_Code__c != '')
                    if(programmes.containsKey(p1.BNR_Program_Code__c))
                        p1.Programme__c = programmes.get(p1.BNR_Program_Code__c).Id;
            }
            system.debug(products + 'Pro1');
            Database.UpsertResult [] ui = Database.upsert(products, externalKey, false);
            Set<Id> ids = new Set<Id>();
            /* Iterate over the results, asserting success and adding the new ID
             to the set for use in the comprehensive assertion phase below. */
            for(Database.upsertResult result:ui) {
                //System.assert(result.isSuccess());
                ids.add(result.getId());
                List<Database.Error> e = result.getErrors();
                if(!e.IsEmpty()){
                    if(e[0].Message != null && e[0].Message != ''){
                        if(statusDetails == 'Success')
                            statusDetails = 'Fail';
                        response = statusDetails + ':' + e[0].Message;
                    }
                }
            }
            if(ids == null){
                response = 'Fail: Failed to insert products';
            }
            system.debug(ids + 'ss10');
            List<PC_Bundle__c> lstPCB = [Select p.PC_Bundle_Id__c, p.Id From PC_Bundle__c p where p.PC_Bundle_Id__c in:bundleIds];
            Map<String,String> pcBunIdSId = new Map<String,String>();
            for(PC_Bundle__c pc : lstPCB){
                pcBunIdSId.put(pc.PC_Bundle_Id__c,pc.Id);
            }
            system.debug(pcBunIdSId + 'test ' + lstPCB);
            List<PC_Item__c> lstPCItems = new List<PC_Item__c>();
            PC_Item__c tempPCI;
            
            // check for existing pc items with the combination of instance and programme id
            List<PC_Item__c> exsPCIs = [Select Product__c, Product__r.Instance_Id__c, PC_Bundle__c, PC_Bundle_Id__c from PC_Item__c where Product__c in:ids];
            system.debug(exsPCIs + 'ss11');
            Map<String,Map<String,PC_Item__c>> proBun = new Map<String,Map<String,PC_Item__c>>();
            Map<String,PC_Item__c> bunIdPC;
            List<PC_Item__c> deletePCItems = new List<PC_Item__c>();
            for(PC_Item__c temp: exsPCIs){
                if(insIdSBunIds.containskey(temp.Product__r.Instance_Id__c)){
                    sBids = insIdSBunIds.get(temp.Product__r.Instance_Id__c);
                    if(temp.PC_Bundle_Id__c != null && temp.PC_Bundle_Id__c != ''){
                        if(!sBids.contains(temp.PC_Bundle_Id__c)){
                            deletePCItems.add(temp);
                        }
                    }
                }
                if(proBun.containsKey(temp.Product__c)){
                    bunIdPC = proBun.get(temp.Product__c);
                    bunIdPC.put(temp.PC_Bundle_Id__c,temp);
                    proBun.put(temp.Product__c,bunIdPC);                
                }else{
                    bunIdPC = new Map<String,PC_Item__c>();
                    bunIdPC.put(temp.PC_Bundle_Id__c,temp);
                    proBun.put(temp.Product__c,bunIdPC);
                }
            }
            system.debug(proBun + 'ss12');
            //-------------------- ended here
            for (Request r : programmeList) {
                Id pId = null;
                if (r.programme != null && r.programme.Id != null) 
                    pId= r.programme.Id;
                boolean blankBundleExists = false;
                boolean createPCItem = false;
                if (r.instances != null) {
                    for (Item i : r.instances) {
                        Id insId = i.instance.Id;
                        system.debug('insId' +  insId + 'prog1' + pId);
                        blankBundleExists = false;
                        if(!i.bundleIds.isEmpty()){
                            for(String b:i.bundleIds){
                                if(b != null && b != ''){
                                    createPCItem = true;
                                    if(proBun.containsKey(insId)){
                                        bunIdPC = proBun.get(insId);                                    
                                        if(bunIdPC.containsKey(b)){
                                            tempPCI = bunIdPC.get(b);
                                            tempPCI.Product__c = insId;
                                            tempPCI.Programme__c = pId;
                                            if(pcBunIdSId.containsKey(b)){
                                                tempPCI.PC_Bundle__c = pcBunIdSId.get(b);
                                            }
                                            tempPCI.PC_Bundle_Id__c = b;                            
                                            lstPCItems.add(tempPCI);
                                            createPCItem = false;
                                        }
                                    }
                                    if(createPCItem){
                                        tempPCI = new PC_Item__c();
                                        tempPCI.Product__c = insId;
                                        tempPCI.Programme__c = pId;
                                        if(pcBunIdSId.containsKey(b)){
                                            tempPCI.PC_Bundle__c = pcBunIdSId.get(b);
                                        }
                                        tempPCI.PC_Bundle_Id__c = b;                            
                                        lstPCItems.add(tempPCI);
                                    }
                                }
                            }                       
                        }
                        
                        if(proBun.containsKey(insId)){
                            bunIdPC = proBun.get(insId);                                    
                            if(bunIdPC.containsKey(null) || bunIdPC.containsKey(''))
                                blankBundleExists = true;
                        }
                        
                        if(!blankBundleExists){
                            tempPCI = new PC_Item__c();
                            tempPCI.Product__c = insId;
                            tempPCI.Programme__c = pId;
                            tempPCI.PC_Bundle_Id__c = null;
                            lstPCItems.add(tempPCI);
                        }
                    }           
                }
            }
            system.debug(lstPCItems + 'lstPCIs1');
            Database.UpsertResult [] uPI = Database.upsert(lstPCItems, false);
            
            if(!deletePCItems.IsEmpty()){
                Database.Deleteresult[] dPCs = Database.delete(deletePCItems,false);
            }
            Create_IntegrationLog.writeIncomingLog(endpoint, reqStr, response);    
        }
        return new Response(response);
    }   
}