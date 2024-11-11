public with sharing class OfferingSelectorController {
        public boolean bSize {get;set;}
        
        public class ProductWrapper {
            public Product2 product { get; set; }
            public Boolean isSelected { get; set; }
        }
        
        public class BundleWrapper {
            public PC_Bundle__c bundle { get; set; }
            public Boolean isSelected { get; set; }
        }
        
        public class ItemWrapper {
            public Boolean isPrimary { get; set; }
            public Id productId { get; set; }
            public Id bundleId { get; set; }
            public Id pcItemId { get; set; }
            public Id prgId {get;set;}
            public string productType { get; set; }
            public string productName { get; set; }
            public string bundleName { get; set; }
            public String bundleExternalId { get; set; }
            public string description { get; set; }
            public string location { get; set; }
            public Date startDate { get; set; }
            public Decimal price { get; set; }
            public Decimal minCapacity { get; set; }        
            public Decimal maxCapacity { get; set; }        
            public Decimal usedCapacity { get; set; }       
            public PC_Item__c pcI {get;set;}               
        }
        
        public final Opportunity_Product__c oppItem { get; set; }
        
        public string searchText { get; set; }
        
        //Adding new search fields
        public string searchLocation {get; set;}
        public String searchProduct {get; set;}
        public Date searchDate {get; set;}
        public Date searchEndDate {get; set;}
        public list<ProductWrapper> offeringSearchResults { get; set; }
        public list<BundleWrapper> bundleSearchResults { get; set; }
        public list<ItemWrapper> bundleContents { get; set; }
        
        private boolean offeringSelectionIndex { get; set; }
        public string errorMessage { get; set; }
        
        public set<string> existingProductInstanceIds = new set<string>();
        public boolean primaryAlreadySelected { get; set; }
        
        public OfferingSelectorController(ApexPages.StandardController stdController) {
            this.bSize = false;
            this.oppItem = (Opportunity_Product__c)stdController.getRecord();
            bundleSearchResults = new list<BundleWrapper>();
            bundleContents = new list<ItemWrapper>();
            
            primaryAlreadySelected = false;
            list<Opportunity_Product__c> opiList = [Select Id, Course_Focus__c, Product__c
                                                      From Opportunity_Product__c
                                                     Where Opportunity__c = :oppItem.Opportunity__c];        
                                                                                            
            for (Opportunity_Product__c opi : opiList) {
                existingProductInstanceIds.add(opi.Product__c);
                if (opi.Course_Focus__c == 'Primary')
                    primaryAlreadySelected = true;
            }        
            system.debug(oppItem);
        }
    
    public PageReference addProducts() {
    system.debug('@@bundleContents@@'+bundleContents);
        if (bundleContents.size() > 0) {
        system.debug('@@bundleContents@@'+bundleContents);
        system.debug('@@bundleContents.size()@@'+bundleContents.size());
            List<Opportunity_Product__c> oppProdList = new List<Opportunity_Product__c>();
            try{
                ItemWrapper primaryIW = null;
                for (ItemWrapper iw : bundleContents) {
                    Opportunity_Product__c oppProd = new Opportunity_Product__c();
                    oppProd.Opportunity__c = oppItem.Opportunity__c;
                    oppProd.Product__c = iw.productId;
                    oppProd.Bundle_Name__c = iw.bundleName;
                    oppProd.Bundle_Id__c = iw.bundleExternalId;
                    if (iw.productType == 'OFFERING') {
                        if (iw.isPrimary) {
                            oppProd.Course_Focus__c = 'Primary';
                            primaryIW = iw;
                        }
                        else
                            oppProd.Course_Focus__c = 'Secondary';
                    }
                    else {
                        oppProd.Course_Focus__c = null; 
                    }
                    oppProdList.add(oppProd);
                }
                system.debug('@@oppProdList@@'+oppProdList);
                insert oppProdList;
                system.debug('@@oppItem@@'+oppItem);
                system.debug('@@oppItem.Opportunity__c@@'+oppItem.Opportunity__c);
                Opportunity opp = [Select Id, BNR_FieldOfStudy_Code__c, 
                                          Programme_Application__c, Start_Date__c, Mode__c, Location__c, 
                                          BNR_Campus_Code_Text__c, BNR_Degree_Code_Text__c, BNR_Level_Code_Text__c,
                                          BNR_Program_Code_Text__c, BNR_Term_Code_Text__c,
                                          SFDC_Attribute_Code_Select__c, Record_Source__c, SFDC_Attribute_Code_Select_v2__c,
                                         PC_Attribute_Code__c, PC_Attribute_Code_2__c, PC_Attribute_Code_3__c
                                   From Opportunity
                                   Where Id = :oppItem.Opportunity__c];
                if(primaryIW != null){
                system.debug('@@primaryIW@@'+primaryIW);
                    Product2 courseInstance = [Select Id, Programme__c, Start_Date__c, Mode__c, Location__c,
                                                      BNR_Campus_Code__c, BNR_Degree_Code__c, BNR_Level_Code__c, 
                                                      BNR_Program_Code__c, BNR_Term_Code__c, BNR_Attribute_Code__c, 
                                                      BNR_Attribute_Code_2__c, BNR_Attribute_Code_3__c
                                                 from Product2 where Id = :primaryIW.productId];
                    
                    //List<Schema.PicklistEntry> plistValues = Opportunity.SFDC_Attribute_Code_Select__c.getDescribe().getPicklistValues();
                    //List<Schema.PicklistEntry> plistValues = Opportunity.SFDC_Attribute_Code_Select_v2__c.getDescribe().getPicklistValues();
                    system.debug('@@primaryIW.productId@@'+primaryIW.productId);
                    system.debug('@@opp@@'+opp);
                    opp.Course_Instance__c = primaryIW.productId;      
                    if(opp.Record_Source__c == 'Salesforce'){
                        opp.SFDC_Admissions_ADMT_Code_Select__c = 'DI~ Direct';
                    } 
                    else if(opp.Record_Source__c == 'CAB'){
                        opp.SFDC_Admissions_ADMT_Code_Select__c = 'LC~ Law CABs';
                    } 
                    else if(opp.Record_Source__c == 'UCAS'){
                        opp.SFDC_Admissions_ADMT_Code_Select__c = '9~ UCAS';
                    } 
                    else if(opp.Record_Source__c == 'BPTC'){
                        opp.SFDC_Admissions_ADMT_Code_Select__c = 'MI~ Milkround';
                    } 
                    else if(opp.Record_Source__c == 'Direct Apps'){
                        opp.SFDC_Admissions_ADMT_Code_Select__c = 'DI~ Direct';
                    }
                    system.debug('primaryIW: ' + primaryIW);
                    if(primaryIW.prgId != null) {
                        Programme__c prgm = [Select Id, Name, BNR_FieldOfStudy_Code__c from Programme__c Where Id = :primaryIW.prgId]; 
                        opp.BNR_FieldOfStudy_Code__c = prgm.BNR_FieldOfStudy_Code__c;
                    }
                    
                    
                    //populate the oppurtunity data
                    system.debug('@@courseInstance@@'+courseInstance);
                    opp.Programme_Application__c = courseInstance.Programme__c;
                    opp.Start_Date__c = courseInstance.Start_Date__c;
                    opp.Mode__c = courseInstance.Mode__c;
                    opp.Location__c = courseInstance.Location__c;
                    opp.BNR_Campus_Code_Text__c = courseInstance.BNR_Campus_Code__c;
                    opp.BNR_Degree_Code_Text__c = courseInstance.BNR_Degree_Code__c;
                    opp.BNR_Level_Code_Text__c = courseInstance.BNR_Level_Code__c;
                    opp.BNR_Program_Code_Text__c = courseInstance.BNR_Program_Code__c;
                    opp.BNR_Term_Code_Text__c = courseInstance.BNR_Term_Code__c;
                    //opp.SFDC_Attribute_Code_Select__c = courseInstance.BNR_Attribute_Code__c;
                    //opp.SFDC_Attribute_Code_Select_v2__c = courseInstance.BNR_Attribute_Code__c;
                    /*
                    for (Schema.PicklistEntry pe : plistValues){
                        if (pe.getLabel().startsWith(courseInstance.BNR_Attribute_Code__c + '~')){
                            //opp.SFDC_Attribute_Code_Select__c = pe.getValue();
                            opp.SFDC_Attribute_Code_Select_v2__c = pe.getValue();
                            break;
                        }
                    }
                    */ 
                    if (courseInstance.BNR_Attribute_Code__c != null)
                      opp.PC_Attribute_Code__c = courseInstance.BNR_Attribute_Code__c;
                    
                    if (courseInstance.BNR_Attribute_Code_2__c != null)
                      opp.PC_Attribute_Code_2__c = courseInstance.BNR_Attribute_Code_2__c;
                    
                    if (courseInstance.BNR_Attribute_Code_3__c != null)
                      opp.PC_Attribute_Code_3__c = courseInstance.BNR_Attribute_Code_3__c;
                                      
                    system.debug('@@opp before update@@'+opp);
                    update opp; 
                }           
                return returnToOpportunity();
            }
            catch(Exception e){
               system.debug(e.getMessage());
            }                
        }
        return null;
    }
    
    public PageReference returnToOpportunity() {
        return new PageReference('/' + oppItem.Opportunity__c);
    }
    
    public void searchOfferings() {
        
        //Need to add critera to the search to allow for searching by location and start date as well.
        string selectStr = 
                'Select Id, Name, Location__c, Start_Date__c, BNR_Price__c, Description,BNR_Max_Capacity__c,BNR_Used_Capacity__c ' +
                'From Product2 Where Product_Type__c = \'OFFERING\' AND ' +
                'IsActive = true';
        Boolean hasSearchCriteria = false;
        if(searchProduct != null && !String.isBlank(searchProduct)){
            string searchCriteria = String.escapeSingleQuotes(searchProduct);

            selectStr +=                ' AND (Name Like \'%' + searchCriteria + '%\' ' +
                'OR Description Like \'%' + searchCriteria + '%\' ' +
                'OR Instance_Id__c Like \'%' + searchCriteria + '%\' ' +
                'OR Programme__r.Name Like \'%' + searchCriteria + '%\') ';
            hasSearchCriteria = true;
        
        }
        if(searchLocation != null && !String.isBlank(searchLocation)){
            selectStr += ' AND Location__c Like \'%' + String.escapeSingleQuotes(searchLocation) + '%\'';
                        hasSearchCriteria = true;

        }
        if(searchDate != null ){
            
            String dateSearch    = (searchDate + '').split(' ')[0];
            
            selectStr += ' AND Start_Date__c >= ' + dateSearch ;
                        hasSearchCriteria = true;

        }
        if(searchEndDate != null){
            String dateSearchEnd = (searchEndDate + '').split(' ')[0];
            selectStr += ' AND Start_Date__c <= '+dateSearchEnd ;
                        hasSearchCriteria = true;

        }
        if(!hasSearchCriteria){
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'You must enter search criteria.'));
                return;
        }
        
        system.debug('selectStr: ' + selectStr);
        offeringSearchResults = new list<ProductWrapper>();
        List<Product2> productList = Database.query(selectStr);
        if(productList.isEmpty()){
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'Your search criteria returned no results.'));
                return;
        }
        system.debug(productList);
        for (Product2 p : productList) {                
            if (existingProductInstanceIds.contains(p.Id))
                continue;
            
            ProductWrapper pw = new ProductWrapper();
            pw.product = p;
            pw.isSelected = false;
            offeringSearchResults.add(pw);
        }       
        bundleSearchResults = new list<BundleWrapper> ();
        bundleContents = new List<ItemWrapper>();         
    }
    
    public void offeringSelected() {
        String selectedOfferingId = System.currentPagereference().getParameters().get('selectedOfferingId');
        Product2 selectedOffering;
        for (ProductWrapper pw : offeringSearchResults) {
            if (pw.product.id == selectedOfferingId) {
                if (pw.isSelected) {
                    selectedOffering = pw.product;
                }
            }
            else {
                pw.isSelected = false;
            }
        }
        
        bundleSearchResults = new list<BundleWrapper> ();
        bundleContents = new List<ItemWrapper>();
        if (selectedOffering != null) {
            List<PC_Item__c> pcItems = [Select Id, PC_Bundle__c
                                          From PC_Item__c
                                         Where Product__c = :selectedOfferingId
                                           And PC_Bundle__c != null];
                                                               
            Set<Id> bundleIds = new Set<Id>();
            for (PC_Item__c pi : pcItems) {
                    bundleIds.add(pi.PC_Bundle__c);
            }
                                                               
            List<PC_Bundle_Extension__c> extensions = [Select Id, PC_Parent_Bundle__c
                                                        From PC_Bundle_Extension__c
                                                        Where PC_Child_Bundle__c IN :bundleIds];
            
            for (PC_Bundle_Extension__c pbe : extensions) {
                    bundleIds.add(pbe.PC_Parent_Bundle__c);
            }                                                               
            
            List<PC_Bundle__c> bundles = [Select Id, Name, Description__c, BNR_Price__c, PC_Bundle_Full_Name__c
                                            From PC_Bundle__c
                                           Where Id IN :bundleIds];
            
            boolean prepopulateBundle = false;
            if(!bundles.isEmpty() && bundles.size() ==1){
                prepopulateBundle = true;
            }
            
            for (PC_Bundle__c pb : bundles) {
                    BundleWrapper bundle = new BundleWrapper();
                    bundle.bundle = pb;
                    bundle.isSelected = false;
                    bundleSearchResults.add(bundle);
                    this.bSize = true;
                if(prepopulateBundle){
                    System.currentPagereference().getParameters().put('selectedBundleId', pb.Id);
                    bundle.isSelected = true;//defaulting to true now
                }
            }
            
    
            bundleContents = new List<ItemWrapper>();
            List<PC_Item__c> pcItems2 = [Select Id, PC_Bundle__r.Name, PC_Bundle__r.PC_Bundle_Full_Name__c, Product__r.Name, Product__r.Start_Date__c,
                                                Product__r.Location__c, Product__r.Description, Product__r.BNR_Price__c,
                                                Product__r.Product_Type__c, Product__r.Programme__c, Product__c, PC_Bundle__c,
                                                Product__r.BNR_Max_Capacity__c, Product__r.BNR_Min_Capacity__c, Product__r.BNR_Used_Capacity__c
                                           From PC_Item__c
                                          Where PC_Bundle__c = null And 
                                                PC_Bundle_Id__c = null And
                                                Product__c = :selectedOffering.id];
            
            buildBundleContents(pcItems2);
            if(prepopulateBundle){
                bundleSelected();
            }
        }
        
    }
    
    public void buildBundleContents(List<PC_Item__c> pcItems) {
        
        boolean primaryAdded = primaryAlreadySelected;
        
        for (PC_Item__c pi : pcItems) {
            ItemWrapper iw = new ItemWrapper();
            iw.productId = pi.Product__c;
            iw.bundleId = pi.PC_Bundle__c;
            iw.pcItemId = pi.Id;
            iw.bundleName = pi.PC_Bundle__r.PC_Bundle_Full_Name__c;
            iw.bundleExternalId = pi.PC_Bundle__r.PC_Bundle_Id__c;
            iw.productType = pi.Product__r.Product_Type__c;
            iw.productName = pi.Product__r.Name;
            iw.description = pi.Product__r.Description;
            iw.location = pi.Product__r.Location__c;
            iw.startDate = pi.Product__r.Start_Date__c;
            iw.price = pi.Product__r.BNR_Price__c;
            iw.prgId = pi.Product__r.Programme__c;
            if(pi.Product__r.Product_Type__c == 'OFFERING'){
                iw.maxCapacity = pi.Product__r.BNR_Max_Capacity__c;
                iw.minCapacity = pi.Product__r.BNR_Min_Capacity__c;
                iw.usedCapacity = pi.Product__r.BNR_Used_Capacity__c;
            }
            iw.isPrimary = false;
            if (iw.productType == 'OFFERING' && primaryAdded == false) {
                iw.isPrimary = true;
                primaryAdded = true;
            }
            iw.pcI = pi;
            bundleContents.add(iw);
        }
    }
    
    public void bundleSelected() {
        this.bSize=false;
        String selectedBundleId = System.currentPagereference().getParameters().get('selectedBundleId');
        PC_Bundle__c selectedBundle;
        for (BundleWrapper bw : bundleSearchResults) {
            if (bw.bundle.id == selectedBundleId) {
                if (bw.isSelected) {
                    selectedBundle = bw.bundle;
                }
            }
            else {
                bw.isSelected = false;
            }
        }
        
        bundleContents = new List<ItemWrapper>();
        if (selectedBundle != null) {
            Set<Id> bundleIds = new Set<Id>();  
            bundleIds.add(selectedBundleId);
            List<PC_Bundle_Extension__c> extensions = [Select Id, PC_Child_Bundle__c
                                                        From PC_Bundle_Extension__c
                                                        Where PC_Parent_Bundle__c IN :bundleIds];
            
            for (PC_Bundle_Extension__c pbe : extensions) {
                    bundleIds.add(pbe.PC_Child_Bundle__c);
            }
            
            List<PC_Item__c> pcItems = [Select Id, PC_Bundle__r.Name, PC_Bundle__r.PC_Bundle_Full_Name__c, Product__r.Name, Product__r.Start_Date__c, PC_Bundle__r.PC_Bundle_Id__c,
                                                Product__r.Location__c, Product__r.Description, Product__r.BNR_Price__c,
                                                Product__r.Product_Type__c, Product__r.Programme__c, Product__c, PC_Bundle__c,
                                                Product__r.BNR_Max_Capacity__c, Product__r.BNR_Min_Capacity__c, Product__r.BNR_Used_Capacity__c
                                            From PC_Item__c
                                            Where PC_Bundle__c IN :bundleIds];
                                                                    
            buildBundleContents(pcItems);   
        }
    }
    
    public Pagereference productPrimarySelected() {
        String selectedProductId = System.currentPagereference().getParameters().get('selectedProductId');
        ItemWrapper selectedItem;
        for (ItemWrapper iw : bundleContents) {
            if (iw.productId == selectedProductId) {
                if (iw.isPrimary) {
                    selectedItem = iw;
                }
            }
            else {
                iw.isPrimary = false;
            }
        }
        
        if (selectedItem != null) {
            list<Opportunity_Product__c> opiList = [Select Id, Course_Focus__c 
                                                    From Opportunity_Product__c
                                                    Where Opportunity__c = :oppItem.Opportunity__c];
            
            system.debug('opiList: ' + opiList);            
            errorMessage = null;                                                            
            for (Opportunity_Product__c opi : opiList) {
                if (opi.Course_Focus__c == 'Primary') {
                    system.debug('Should error');
                    errorMessage = 'Another offering is already set as Primary.'; 
                    selectedItem.isPrimary = false;
                    return null;
                }
            }
        }        
        return null;
    }
}