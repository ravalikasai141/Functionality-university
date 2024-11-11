public class SendAltIdCtrl {
   @AuraEnabled
   public static string SendAltId(Id recordId){ 
       System.debug('@SendAltIdCtrl SendAltId recordId: ' + recordId);
       String result;
       
       if (recordId != null) {
           result = BNR_PublishEvent.PublishEventRequest(recordId);
       }
       return result; 
   }
}