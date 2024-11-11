public class cItransfer {
    /*
    trigger class for the web course offering object maintance 
    author: chris roberts cwestonr@me.com
    create date: sept 14 2011
    Version 1.1 sept 19 2011
    reduced amount of queries by moving them out of the main group
    */
    public cItransfer() {
    }
    public static void doXfer(List<string> Idlist) {
        Integer td = date.today().year();
        list <Web_Course_Offering__c> cwco = [SELECT Id, Course_Instance_ID__c  FROM  Web_Course_Offering__c];
        list <Campus__c> campus = [SELECT Id,Name FROM Campus__c  ];
        list <Mode__c> mode =  [SELECT Id, Name FROM Mode__c];
        list <product2> prod =  [SELECT Id, Name, Topic__c, Course_URL__c, Product_Type__c, DELETED__c, Staging_PK__c, Deposit_Amount__c, Location__c, Mode__c, Programme__c, Online_Only__c, IsActive,Level__c, start_date__c, Source_ID__c, On_Web__c, redirect_enabled__c, redirect_url__c FROM Product2  WHERE  CALENDAR_YEAR(start_date__c) >= :td AND CALENDAR_YEAR(start_date__c) <= :td+2 AND ID in:Idlist];
        list <Web_Course_Offering__c> wcolist = new  List <Web_Course_Offering__c>();
        list <Mode__c> NewMode = new list<Mode__c>();     
        for (Product2 Ci : prod){
            // create the web cource offering object
            // active flag calc
            Boolean Active = false ;
            if( Ci.on_web__c == True &&  Ci.IsActive == True) {
                Active= True;
            }
            string FoundMatch = 'false';
            string ModeExists = 'false';
            for (Web_Course_Offering__c wcoid :cwco) {
                //see if there is a match
                if(wcoid.Course_Instance_ID__c == Ci.Id){
                    FoundMatch='true';
                    wcoid.redirect_enabled__c = Ci.redirect_enabled__c;
                    wcoid.redirect_url__c = Ci.redirect_url__c; 
                    wcoid.start_date__c = Ci.start_date__c;
                    wcoid.Programme__c= Ci.Programme__c;
                    wcoid.Active__c=Active;
                    for (Mode__c mdd :mode) {
                        if (mdd.name == Ci.Mode__c) {
                            wcoid.Mode__c= mdd.Id;
                            ModeExists = 'true';
                        }
                    }
                    if ( ModeExists == 'false') {
                        String AlreadyAdded = 'false';
                        for(Mode__c NM : NewMode){
                            if (Ci.Mode__c == NM.name){
                                AlreadyAdded = 'true';
                            }
                        }
                        if (AlreadyAdded == 'false'){
                            Mode__c md = new Mode__c();
                            md.name =Ci.Mode__c;
                            insert(md);
                            wcoid.Mode__c=md.Id;
                            NewMode.add(md);
                        }
                    } 
                    // get the campus id
                    for ( Campus__c camp:campus) {
                        if (camp.name == Ci.Location__c ) {
                            wcoid.Campus__c = camp.id;
                        }
                    } 
                    wcolist.add(wcoid);
                }
            }
            //IF NO MATCH THEN ADD NEW Web Course Offering             
            if (FoundMatch== 'false'){
                //check against recently added
                Web_Course_Offering__c wco = new Web_Course_Offering__c();
                wco.redirect_enabled__c = Ci.redirect_enabled__c;
                wco.redirect_url__c = Ci.redirect_url__c; 
                wco.Course_Instance_ID__c = Ci.Id;
                wco.start_date__c = Ci.start_date__c;
                wco.Programme__c= Ci.Programme__c;
                wco.Active__c=Active;
                //mode 
                // see if the mode exists
                for (Mode__c mdd :mode) {
                    if (mdd.name == Ci.Mode__c) {
                        wco.Mode__c = mdd.Id;
                        ModeExists = 'true';
                    }
                }
                if (ModeExists == 'false') {
                    String AlreadyAdded = 'false';
                    for(Mode__c NM : NewMode){
                        if (Ci.Mode__c == NM.Name){
                            AlreadyAdded = 'true';
                        }
                    }
                    if (AlreadyAdded == 'false'){
                        Mode__c md = new Mode__c();
                        md.name = Ci.Mode__c;
                        insert(md);
                        wco.Mode__c = md.Id;
                        NewMode.add(md);
                    }
                } 
                // get the campus id
                for (Campus__c camp:campus) {
                    if (camp.name == Ci.Location__c ) {
                        wco.Campus__c = camp.id;
                    }
                }                
                wcolist.add(wco);
            }
        }    
        // do the upsert 
        upsert (wcolist);           
    }    
}