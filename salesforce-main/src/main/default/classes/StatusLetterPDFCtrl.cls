public class StatusLetterPDFCtrl{

public Case caserecord{get;set;}
public Account acc{get;set;}
public Opportunity opptoshow{get;set;}
public List<Term_Date__c> termDatesOnProduct{get;set;}
public Address__c addr{get;set;}
public Address__c homeAddr{get;set;}
public integer currday{get;set;}
public string currmonth{get;set;}
public integer curryear{get;set;}
public integer nextyear{get;set;}    
public string dateofbirth{get;set;}
public string todayDateFormat{get;set;}    
public string letterValidUntil{get;set;}
public integer coursestartdate{get;set;}
public string coursestartmonth{get;set;}
public integer coursestartyear{get;set;}
public integer courseenddate{get;set;}
public string courseendmonth{get;set;}
public integer courseendyear{get;set;}
public string bankname{get;set;}
public string subvalue{get;set;}

public List<Case> caserecords = new list<Case>();

    public StatusLetterPDFCtrl(){
        Id caseId = apexpages.Currentpage().getparameters().get('Id');
        Id oppId = apexpages.Currentpage().getparameters().get('oppId');
        Id addId = apexpages.Currentpage().getparameters().get('addId');
        Id homeAddId = apexpages.Currentpage().getparameters().get('homeAddId');
        subvalue = apexpages.Currentpage().getparameters().get('subquery');
        system.debug('@@caseId@'+caseId);
        system.debug('@@oppId@'+oppId);
        system.debug('@@addId@'+addId);
        system.debug('@@homeAddId@'+homeAddId);
        system.debug('@@subvalue@'+subvalue);

        if(caseId!= null && oppId!=null && addId!=null)
        {
            caserecord = [Select id, Status, contactId, Query_Subtype__c, Bank_Name__c,Bank_Name_Text__c from Case where id=:caseId]; 
           // caserecords= withoutsharinghelper.getSObjects('select id,caseNumber from Case where PersonContactId =\'' + bAccId + '\' limit 1');
           
           if(caserecord.Query_Subtype__c == 'Bank')
           {
               if(caserecord.Bank_Name__c != 'other')
               {
                   bankname = caserecord.Bank_Name__c;
               }
               else if(caserecord.Bank_Name__c == 'other')
               {
                   bankname = caserecord.Bank_Name_Text__c;
               }
           }
            
            if(caserecord.contactId != null)
            {
                acc = [Select id, name, firstname, lastname, BNR_Banner_ID__pc,PersonBirthdate from Account where PersonContactId =:caserecord.contactId];
                if(acc.Id != null)
                {
                    dateofbirth = acc.PersonBirthdate.format();
                    currday = System.now().day();
                    curryear = System.now().year();
                    nextyear = System.now().addYears(1).year();
                    DateTime dt = DateTime.now();
                    currmonth= dt.format('MMMMM');
                    System.debug('Month Name : ' + currmonth);
                    Date todayDate = Date.today();
                    todayDateFormat = todayDate.format();
                    Date todayDate_plus_90days = todayDate.addDays(90);
                    letterValidUntil = todayDate_plus_90days.format();
                    system.debug('todayDateFormat: ' + todayDateFormat);
                    system.debug('letterValidUntil: ' + letterValidUntil);

                    opptoshow = [Select id,name,Location__c,Mode__c,Programme_Application__r.name,BNR_Curriculum_Status_Code__c,Course_Instance__c,Course_Instance__r.Name,Course_Instance__r.id,Course_Instance__r.End_Date__c,Course_Instance__r.Start_Date__c from Opportunity where Id =:oppId];
                    if(opptoshow!=null)
                    {
                        system.debug('@opp@'+opptoshow.Course_Instance__r.Start_Date__c);
                        system.debug('@opp@'+opptoshow.Course_Instance__r.Start_Date__c.format());
                        date coursedate = opptoshow.Course_Instance__r.Start_Date__c;
                        coursestartdate = coursedate.day();
                        coursestartyear = coursedate.year();
                       
                        DateTime dtConverted = Datetime.newInstance(coursedate.year(), coursedate.month(),coursedate.day(),0,0,0);
                        system.debug('@opp111@'+dtConverted.format('MMMM'));
                        coursestartmonth = dtConverted.format('MMMM');
                        
                        date coursedate2 = opptoshow.Course_Instance__r.End_Date__c;
                        courseenddate = coursedate2.day();
                        courseendyear = coursedate2.year();
                        
                        DateTime temp = Datetime.newInstance(coursedate2.year(), coursedate2.month(),coursedate2.day(),0,0,0);
                        courseendmonth = temp.format('MMMM');
                        if(opptoshow.Course_Instance__r.id != null){
                        	termDatesOnProduct = [SELECT id, Name, Start_Date__c, End_Date__c,product__c FROM Term_Date__c where product__c=:opptoshow.Course_Instance__r.id ORDER BY Start_Date__c ASC NULLS LAST];
                            System.debug('Term Dates on Product'+termDatesOnProduct);
                        }
                    }
                    addr = [Select id,Type__c,Street_1__c,Street_2__c,Street_3__c,Street_4__c,Zip_Postal_Code__c,Locality__r.name,State_Province__r.name,Lookup_Country__r.name,City__c from Address__c where Id =:addId and Type__c='Mailing' and Active__c = true];   
                    if (homeAddId!= null) {
                        homeAddr = [Select id,Type__c,Street_1__c,Street_2__c,Street_3__c,Street_4__c,Zip_Postal_Code__c,Locality__r.name,State_Province__r.name,Lookup_Country__r.name,City__c from Address__c where Id =:homeAddId and Type__c='Home' and Active__c = true];
                        System.debug('Home Address'+homeAddr);
                    }
                }
                
            }

        }
    }
}