/**********************************************************************
Name: SendCASAutoReply
Purpose: SendCASAutoReply apex class is for CAS issued letter with PDF attachment for BPP-24827/BPP-24590                 
-------                                                             
History                                                             
-------                                                             
VERSION  AUTHOR             DATE              DETAIL                              
0.1 -   Swayanprava Sahoo     06/02/2023      INITIAL DEVELOPMENT  
***********************************************************************/
public class SendCASAutoReply {
    @future(callout = true)
    public static void sendEmailWithPDfAttachment(String oppId,String accName, String casStatus,String email){
        
        Messaging.SingleEmailMessage emailTobeSent = new Messaging.SingleEmailMessage();
        PageReference PDf = null;
        String messageBody;
        
        System.debug('@OpportunityId@@'+oppId);
        System.debug('@accName@@'+accName);
        System.debug('@casStatus@@'+casStatus);
        System.debug('@Email@@'+email);
        
        if(casStatus == 'Issued'){
        	PDf =  Page.CASLetterPDF;
        }
        
        if(PDf != null) {
            PDf.getParameters().put('Id',oppId);
            PDf.getParameters().put('accName',accName);
            PDf.getParameters().put('casStatus',casStatus);
            PDf.getParameters().put('email',email);
         	PDf.setRedirect(true);
            
            Attachment attach = new Attachment();
            Blob b ;
            if(Test.isRunningTest()) {
                b = blob.valueOf('Unit.Test');
            }
            else{
                b = PDf.getContent();
            }
            attach.Body = b;
            attach.Name = 'Confirmation of Acceptance for Studies Letter';
            attach.IsPrivate = false;
            attach.ParentId = oppId;
            insert attach;
            
            Messaging.EmailFileAttachment efa = new Messaging.EmailFileAttachment();
            efa.setFileName('Confirmation of Acceptance for Studies Letter.PDF');
            messageBody = '<html><body>Dear '+accName+',<br/><br/>We hope you are well. Please find attached your CAS letter which you can use for your Student Visa application.<br/><br/> As mentioned in our previous email, please ensure you review our <a href="https://international.bpp.com/p/5?_ga=2.220889051.257797375.1673531698-492957110.1665062235&_gl=1*16c9gd9*_ga*NDkyOTU3MTEwLjE2NjUwNjIyMzU.*_ga_2Z3N5LJX8F*MTY3MzUzMTY5Ny40NC4xLjE2NzM1MzE2OTcuMC4wLjA">Visa and Immigration Guidance page</a> on our website. This will provide useful information for you regarding your visa application, as well as additional information on how to comply with the conditions of your visa. There is also information about Student Life at BPP and information about Coming to the UK.<br/><br/>You will receive further contact in regards to your arrivals plans in the UK along with our international arrivals survey.<br/><br/>We look forward to you starting your programme with us.<br/><br/>Kind regards,<br/><br/>BPP Visa Compliance Department </body> </html>';
			efa.setBody(b);

            List<string> sendTo = new List<string>();
            sendTo.add(email);
            emailTobeSent.setToAddresses(sendTo);
            emailTobeSent.setSubject('Important Please Read: Your CAS Letter and Guidance');
            emailTobeSent.setOrgWideEmailAddressId(system.label.CAS_Sponsership);//cassponsorship@bpp.com

            emailTobeSent.setHtmlBody(messageBody);
            emailTobeSent.setFileAttachments(new Messaging.EmailFileAttachment[] {efa}); // Sends the email
            
            if (!Test.isRunningTest()) {
                Messaging.SendEmailResult [] r1 = Messaging.sendEmail(new Messaging.SingleEmailMessage[] {emailTobeSent});
            }

            Opportunity oppVar = [select id, CAS_Letter_Sent__c, CAS_status__c from Opportunity where Id=:oppId];
            oppVar.CAS_Letter_Sent__c = true;
            update oppVar;
            System.debug('Email sent successfully');
        }
    }
}