public class QualificationsTriggerHandler {
    public static void handleChangeInRank(List<Qualification__c> newQualList, List<Qualification__c> oldQualList, Boolean qualDeleted) {
        List<Id> studentId = new List<Id>();
        List<Id> qualId = new List<Id>();
        System.debug('@Inside handleChangeInRank method!!!!');
        System.debug('@New Qualification List: ' + newQualList);
        System.debug('@Old Qualification List: ' + oldQualList);
        System.debug('@qualDeleted: ' + qualDeleted);
        decimal lowestRank = null;
        String highestQualificationCode = null;
        List<Qualification__c> qualList = qualDeleted ? oldQualList : newQualList;
        System.debug('@Qualification List: ' + qualList);
        for (Qualification__c qualRecord : qualList) {
            System.debug('@Qualification List: 1' + qualRecord);
            studentId.add(qualRecord.Student__c);
            qualId.add(qualRecord.id);

            if(!qualDeleted && qualRecord.Status__c == 'Actual') {
                System.debug('@Qualification List: 3' + qualRecord);
            	lowestRank = qualRecord.Rank__c;  
                System.debug('Default lowest rank ' + lowestRank );
            }
        }

        //Get contact from qualification and all related qualifications from that contact
        system.debug(studentId.size());

        if(studentId.size() > 0) {
            for(Qualification__c qual : [select id, name, Rank__c, Student__r.name, status__c from Qualification__c where Student__c =:studentId[0] and Status__c = 'Actual']){
                System.debug('Student Name:' + qual.Student__r.name + 'Qualification Id: ' + qual.Id + ', Qualification Name: ' + qual.name + 'Rank: ' + qual.Rank__c + 'Qual Status: ' + qual.Status__c);
                if((lowestRank == null || lowestRank > qual.Rank__c) && !qualId.contains(qual.id)){
                    lowestRank = qual.Rank__c;
                    System.debug('lowest rank ' + lowestRank );
                }
            }
            
            if(lowestRank != null) {
            	for(Highest_Qualification__c highestRank: [select id, name, code__c, Rank__c from Highest_Qualification__c where rank__c=:lowestRank limit 1]){
                    system.debug(highestRank.code__c);
                    system.debug(highestRank.Rank__c);
                    highestQualificationCode = highestRank.code__c;
                }    
            }
            
            for(Contact con : [select id,name,Highest_Qualification_Code__c from contact where id=:studentId[0] limit 1]){
                con.Highest_Qualification_Code__c = highestQualificationCode;
                update con;
            }
        }
    }

    /**
     * sync Subject_Name__c with Subject lookup
     * @param  newQualList updated values
     * @param  oldQualMap  prior values
     */
    public static void syncSubject(List<Qualification__c> newQualList, Map<Id, Qualification__c> oldQualMap) {
        List<Id> subjectsToQuery = new List<Id>();
        for (Qualification__c qual : newQualList) {
            Qualification__c oldQual = oldQualMap?.get(qual.id);

            if (oldQual == null || qual.Qualification_Subject__c != oldQual.Qualification_Subject__c) {
                subjectsToQuery.add(qual.Qualification_Subject__c);
            }
        }

        if (!subjectsToQuery.isEmpty()) {
            Map<Id, Qualification_Subject__c> subjectMap = new Map<Id, Qualification_Subject__c>(
                [SELECT Name FROM Qualification_Subject__c WHERE Id IN :subjectsToQuery]
            );

            for (Qualification__c qual : newQualList) {
                if (subjectMap.containsKey(qual.Qualification_Subject__c)) {
                    qual.Subject_Name__c = subjectMap.get(qual.Qualification_Subject__c)?.Name;
                }
            }
        }
    }
}
