@isTest
public class cItransferTest{

// test mehods
    static testMethod void cItransferTest1() {
        Programme__c pgrm = CreateTestData.createProgram();
        
        Campus__c campus = new Campus__c();
        campus.Name = 'Test Campus';
        campus.Display_Name__c = 'Test Campus';
        insert campus;
        
        Mode__c mode = new Mode__c();
        mode.Name = 'Flex Name';
        insert mode;
        
        Product2 tpprod = new Product2();
        tpprod.Name = 'TestInstance';
        tpprod.on_web__c = True;
        tpprod.IsActive = True;
        tpprod.Start_Date__c = Date.newInstance(2021,1,23);
        insert tpprod;
        
        Web_Course_Offering__c wco = new Web_Course_Offering__c();
        wco.Programme__c = pgrm.Id;
        wco.Mode__c = mode.Id;
        wco.Campus__c = campus.Id;
        wco.Course_Instance_ID__c = tpprod.Id;
        insert wco;
        
        tpprod.Mode__c = 'Flex Name';
        update tpprod;

        List <string> testd = new List <string>();
        //testd.add(tpdt.Id);
        //testd.add(tpprod.Id);        
        //cItransfer.doXfer(testd);             
        
    }  
    
    
    static testMethod void cItransferTest2() {
        Programme__c pgrm = CreateTestData.createProgram();
        
        Campus__c campus = new Campus__c();
        campus.Name = 'Test Campus';
        campus.Display_Name__c = 'Test Campus';
        insert campus;
        
        Mode__c mode = new Mode__c();
        mode.Name = 'Flex Name';
        insert mode;
        
        Product2 tpprod = new Product2();
        tpprod.Name = 'TestInstance';
        tpprod.on_web__c = True;
        tpprod.IsActive = True;
        tpprod.Start_Date__c = Date.newInstance(2021,1,23);
        insert tpprod;
        
        Web_Course_Offering__c wco = new Web_Course_Offering__c();
        wco.Programme__c = pgrm.Id;
        wco.Mode__c = mode.Id;
        wco.Campus__c = campus.Id;
        wco.Course_Instance_ID__c = tpprod.Id;
        insert wco;
        
        tpprod.Mode__c = 'Full Time';
        update tpprod;          
        
    } 
    
    static testMethod void cItransferTest3() {
        Programme__c pgrm = CreateTestData.createProgram();
        
        Campus__c campus = new Campus__c();
        campus.Name = 'Test Campus';
        campus.Display_Name__c = 'Test Campus';
        insert campus;
        
        Mode__c mode = new Mode__c();
        mode.Name = 'Flex Name';
        insert mode;
        
        Product2 tpprod1 = new Product2();
        tpprod1.Name = 'TestInstance';
        tpprod1.on_web__c = True;
        tpprod1.IsActive = True;
        tpprod1.Start_Date__c = Date.newInstance(2021,1,23);
        insert tpprod1;
        
        Product2 tpprod = new Product2();
        tpprod.Name = 'TestInstance';
        tpprod.on_web__c = True;
        tpprod.IsActive = True;
        tpprod.Start_Date__c = Date.newInstance(2020,1,23);
        tpprod.BPP_ProductFactoryID__c = 'asdasdasdasdasdasd009109';
        tpprod.Family = 'Course';
        insert tpprod;
        
        Web_Course_Offering__c wco = new Web_Course_Offering__c();
        wco.Programme__c = pgrm.Id;
        wco.Mode__c = mode.Id;
        wco.Campus__c = campus.Id;
        wco.Course_Instance_ID__c = tpprod1.Id;
        insert wco;
        
        tpprod.Mode__c = 'Full Time';
        update tpprod;          
        
    } 
    
    static testMethod void cItransferTest4() {
        Programme__c pgrm = CreateTestData.createProgram();
        
        Campus__c campus = new Campus__c();
        campus.Name = 'Test Campus';
        campus.Display_Name__c = 'Test Campus';
        insert campus;
        
        Mode__c mode = new Mode__c();
        mode.Name = 'Flex Name';
        insert mode;
        
        Product2 tpprod1 = new Product2();
        tpprod1.Name = 'TestInstance';
        tpprod1.on_web__c = True;
        tpprod1.IsActive = True;
        tpprod1.Start_Date__c = Date.newInstance(2021,1,23);
        insert tpprod1;
        
        Product2 tpprod = new Product2();
        tpprod.Name = 'TestInstance';
        tpprod.on_web__c = True;
        tpprod.IsActive = True;
        tpprod.Start_Date__c = Date.newInstance(2021,1,23);
        tpprod.BPP_ProductFactoryID__c = 'asdasdasdasdasdasd009109';
        tpprod.Family = 'Course';
        insert tpprod;
        
        Web_Course_Offering__c wco = new Web_Course_Offering__c();
        wco.Programme__c = null;
        wco.Mode__c = null;
        wco.Campus__c = null;
        wco.Course_Instance_ID__c = null;
        insert wco;
        
        tpprod.Mode__c = 'Full Time';
        update tpprod;          
        
    } 

}