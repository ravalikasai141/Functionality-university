public with sharing class AttachmentUploadController {
/* generic upload controller for notes and attachments
  Author: Chris Roberts Ph.D cwestonr@me.com
  
 */ 
 // constructor
 public AttachmentUploadController(ApexPages.StandardController controller) {
     //get record id to attach to
     ob_id = ApexPages.currentPage().getParameters().get('ob_id');
     //optional file extension to limit to
     ftype = ApexPages.currentPage().getParameters().get('ftype');
 }
 
 
 // getters and setters
 // record id to attrach to
  public string ob_id {get; set;}
  // optional filetype to limit to
  public string ftype {get; set;}
  //attachment record
  public Attachment attachment {
  get {
      if (attachment == null)
        attachment = new Attachment();
      return attachment;
    }
  set;
  }
 
 // upload method
  public PageReference upload() {
 
    attachment.OwnerId = UserInfo.getUserId();// current user
    attachment.ParentId = ob_id; // the record the file is attached to
    attachment.IsPrivate = false;
    string fname = attachment.name;
    
   if ( fname.contains('.pdf') == False ){
         ApexPages.addMessage(new ApexPages.message(ApexPages.severity.FATAL,'File Type Must be of .PDF type'));
   } else {
        try {
          insert attachment;
        } catch (DMLException e) {
          ApexPages.addMessage(new ApexPages.message(ApexPages.severity.FATAL,'Error uploading attachment'));
          return null;
        } finally {
        ApexPages.addMessage(new ApexPages.message(ApexPages.severity.INFO,'Attachment uploaded successfully'));
          attachment = new Attachment(); 
        }
    }
    return null;
  }
  
  // test method
 static testMethod  void AttachmentUploadControllerTest1() {
    insert new Account(
        FirstName = 'AttUploadContTest',
        LastName = 'AttUploadContTester',
        Personal_Email__pc = 'testAttUploadContTest@bpp.com.invalid',
        Preferred_Email__pc = 'testAttUploadContTest@bpp.com.invalid'
    );

      //start test
     test.starttest();
      account act = [select id from account limit 1];
       
       PageReference pageRef1 = new PageReference('/apex/attachmentuploader?ob_id='+act.id);
       Test.setCurrentPage(pageRef1); 
       //create controller object instance to test against
        ApexPages.StandardController con = new ApexPages.StandardController(new attachment());               
        AttachmentUploadController Ctlr = new AttachmentUploadController(con);
        // point the test instance to a page 
        //Ctlr.upload();
         Ctlr.ob_id= act.id;
         Ctlr.attachment.name='test.txt';
         blob bl = blob.valueof('test');
         Ctlr.attachment.body =bl;
         Ctlr.attachment.description='test method';
         Ctlr.upload();
        test.stoptest(); 
   }
  static testMethod  void AttachmentUploadControllerTest2() {
    insert new Account(
        FirstName = 'AttUploadContTest',
        LastName = 'AttUploadContTester',
        Personal_Email__pc = 'testAttUploadContTest@bpp.com.invalid',
        Preferred_Email__pc = 'testAttUploadContTest@bpp.com.invalid'
    );

      //start test
     test.starttest();
      account act = [select id from account limit 1];
       
       PageReference pageRef1 = new PageReference('/apex/attachmentuploader?ob_id='+act.id);
       Test.setCurrentPage(pageRef1); 
       //create controller object instance to test against
        ApexPages.StandardController con = new ApexPages.StandardController(new attachment());               
        AttachmentUploadController Ctlr = new AttachmentUploadController(con);
        // point the test instance to a page 
        //Ctlr.upload();
         Ctlr.ob_id= act.id;
         Ctlr.attachment.name='test.pdf';
         blob bl = blob.valueof('test');
         Ctlr.attachment.body =bl;
         Ctlr.attachment.description='test method';
         Ctlr.upload();
        test.stoptest(); 
   }
 
}