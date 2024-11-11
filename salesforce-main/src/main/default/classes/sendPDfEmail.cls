public class sendPDfEmail
{
@future(callout = true)
    public static void sendPDf(String caseNumber,String threadId,String caseid,String Email, String accname,String oppid, String addressid, String homeAddressid, String subquery)
    {
        System.debug('@caseid@@'+caseid);
        System.debug('@Email@@'+Email);
        System.debug('@accname@@'+accname);
        System.debug('@oppid@@'+oppid);
        System.debug('@addressid@@'+addressid);
        System.debug('@homeAddressid@@'+homeAddressid);
        
        Messaging.SingleEmailMessage emailTobeSent = new Messaging.SingleEmailMessage();
        PageReference PDf = null;
        if(subquery == 'I would like to request a Bank, Status or Council Tax letter')
        {
        	PDf =  Page.StatusLetterPDF;
        }
        else if(subquery == 'I would like to request a holiday letter' || subquery == 'Holiday'){
            PDf =  Page.HolidayLetterPDF;
            System.debug('HolidayLetterPDF' +PDf);
        }
        
        if (PDf != null) {
            PDf.getParameters().put('Id',caseid);
            PDf.getParameters().put('oppId',oppid);
            PDf.getParameters().put('addId',addressid);
            if(String.isNotEmpty(homeAddressid)) {
                PDf.getParameters().put('homeAddId',homeAddressid);
            }
            PDf.getParameters().put('subquery',subquery);
     
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
           if(subquery == 'I would like to request a Bank, Status or Council Tax letter')
           	{
                attach.Name = 'BPP University Student Status Letter';
            }
            if(subquery == 'I would like to request a holiday letter' || subquery == 'Holiday')
            {
                attach.Name = 'BPP University Holiday Letter';
            }
            attach.IsPrivate = false;
            attach.ParentId = caseid;
            insert attach;
            Messaging.EmailFileAttachment efa = new Messaging.EmailFileAttachment();
            String messageBody;
            if(subquery == 'I would like to request a Bank, Status or Council Tax letter')
            {
            efa.setFileName('BPP University Student Status Letter.PDF');
            //emailTobeSent.setSubject('BPP University Status Letter');
            emailTobeSent.setSubject('Your case reference caseNumber - threadId');
            messageBody = '<html><body>Hi ' +accname+'<br/><br/>Please see attached your student status certificate which can be used for opening a student bank account, requesting student council tax exemption and for the purpose of confirming your student status as required.<br/> Please reply to this email within 24 hours should you think that the details on the issued letter are incorrect. You are advised to send the received letter back as an attachment to us clearly explaining which details are incorrect and provide us with your correct details for the relevant team to assist you as soon as possible.<br/><br/>Please do not hesitate to contact us should you need any further assistance.<br/><br/>Yours Sincerely,<br/>University Central Administration Team </body> </html>';
        	}
            else if(subquery == 'I would like to request a holiday letter' || subquery == 'Holiday')
            {
                efa.setFileName('BPP University Holiday Letter.PDF');
                //emailTobeSent.setSubject('BPP University Status Letter');
                emailTobeSent.setSubject('Your case reference caseNumber - threadId');
               messageBody = '<html><body>Dear ' +accname+',<br/><br/>Thank you for your query.<br/><br/>Please find attached your requested letter which allows you to prove your Study Term and Holiday Periods. Please note that if you have changed your Programme, Study Mode, Study Location or moved Address since you enrolled, then these details may not be up to date in the letter and you should reply to this email to notify us. We will then manually send you a letter.<br/><br/>Kind regards,<br/><br/>BPP University</body> </html>';
            }
            efa.setBody(b);
            //List<String> EmailIds = 'premamedasani@bpp.com'.split(',');
            List<string> sendTo = new List<string>();
            sendTo.add(Email);
            emailTobeSent.setToAddresses(sendTo);
            emailTobeSent.setSubject('Your case reference '+caseNumber+' - '+threadId);
            emailTobeSent.setOrgWideEmailAddressId(system.label.BPP_Student_Queries_orgId); 
            
            emailTobeSent.setHtmlBody(messageBody);
            emailTobeSent.setFileAttachments(new Messaging.EmailFileAttachment[] {efa}); // Sends the email
            if (!Test.isRunningTest()) {
                Messaging.SendEmailResult [] r1 = Messaging.sendEmail(new Messaging.SingleEmailMessage[] {emailTobeSent});
            }
            
            Case casevar = [select id, caseNumber,Thread_Id__c,status, Status_Letter_Sent__c,Bank_Letter_Sent__c from Case where Id=:caseid];
            system.debug(casevar);

            if(subquery == 'I would like to request a Bank, Status or Council Tax letter' || subquery == 'I would like to request a holiday letter' || subquery == 'Holiday')
            {
                casevar.Status_Letter_Sent__c = true;
            }
            update casevar;
        }    
    }
}