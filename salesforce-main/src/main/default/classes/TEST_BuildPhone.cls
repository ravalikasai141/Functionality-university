@isTest()
public class TEST_BuildPhone 
{
    static testMethod void myUnitTest() {
        Test.startTest(); 
        String Result = BuildPhone.BuildPhoneXml('5557779999', 'Home', True);
        Test.stopTest();
    }   
}