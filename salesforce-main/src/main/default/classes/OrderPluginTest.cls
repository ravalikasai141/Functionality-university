@isTest
public class OrderPluginTest {
    @testSetup
    static void testSetup() {
        Account account = new Account(Name = 'TestDataFactoryClient');
        account.Billing_Type__c = 'In Advance';
        account.Charge_Trigger__c = 'Instance Start Date';
        insert account;

        Opportunity opp = new Opportunity(
            AccountId = account.Id, 
            Name = 'Test Opp', 
            StageName = 'Quoting', 
            BPP_Sub_Status__c = 'Other',
            CloseDate = Date.today(), 
            RecordTypeId = Schema.Sobjecttype.Opportunity.getRecordTypeInfosByName().get('PQ Booking').getRecordTypeId()
        );
        insert opp;
    }
    static testMethod void test_OrderStartDateInAdvance() {
        Account account = [SELECT Id FROM Account LIMIT 1];
        Opportunity opportunity = [SELECT Id FROM Opportunity LIMIT 1];
        SBQQ__Quote__c quote = createQuote(account.Id, opportunity.Id, true);

        Test.startTest();
            OrderPlugin op = new OrderPlugin();
            System.assertEquals(Date.newInstance(2022, 4, 4), op.getOrderStartDate(quote.Id));
        Test.stopTest();
    }

    static testMethod void test_OrderStartDateInArrearsMonthly() {
        Account account = [SELECT Id FROM Account LIMIT 1];
        account.Billing_Type__c = 'In Arrears';
        account.Billing_Frequency__c = 'Monthly';
        update account;

        Opportunity opportunity = [SELECT Id FROM Opportunity LIMIT 1];
        SBQQ__Quote__c quote = createQuote(account.Id, opportunity.Id, false);

        Test.startTest();
            OrderPlugin op = new OrderPlugin();
            System.assertEquals(Date.newInstance(2022, 4, 1), op.getOrderStartDate(quote.Id));
        Test.stopTest();
    }

    static testMethod void test_OrderStartDateInArrearsQuarterly() {
        Account account = [SELECT Id FROM Account LIMIT 1];
        account.Billing_Type__c = 'In Arrears';
        account.Billing_Cycle_Start_Month__c = '1';
        account.Billing_Frequency__c = 'Quarterly';
        update account;

        Opportunity opportunity = [SELECT Id FROM Opportunity LIMIT 1];
        SBQQ__Quote__c quote = createQuote(account.Id, opportunity.Id, false);

        Test.startTest();
            OrderPlugin op = new OrderPlugin();
            System.assertEquals(Date.newInstance(2022, 4, 1), op.getOrderStartDate(quote.Id));
        Test.stopTest();
    }
    
    static testMethod void test_OrderStartDateInArrearsSemiannual() {
        Account account = [SELECT Id FROM Account LIMIT 1];
        account.Billing_Type__c = 'In Arrears';
        account.Billing_Cycle_Start_Month__c = '1';
        account.Billing_Frequency__c = 'Semiannual';
        update account;

        Opportunity opportunity = [SELECT Id FROM Opportunity LIMIT 1];
        SBQQ__Quote__c quote = createQuote(account.Id, opportunity.Id, false);

        Test.startTest();
            OrderPlugin op = new OrderPlugin();
            System.assertEquals(Date.newInstance(2022, 1, 1), op.getOrderStartDate(quote.Id));
        Test.stopTest();
    }
    
    static testMethod void test_OrderStartDateInArrearsAnnual() {
        Account account = [SELECT Id FROM Account LIMIT 1];
        account.Billing_Type__c = 'In Arrears';
        account.Billing_Cycle_Start_Month__c = '1';
        account.Billing_Frequency__c = 'Annual';
        update account;

        Opportunity opportunity = [SELECT Id FROM Opportunity LIMIT 1];
        SBQQ__Quote__c quote = createQuote(account.Id, opportunity.Id, false);

        Test.startTest();
            OrderPlugin op = new OrderPlugin();
            System.assertEquals(Date.newInstance(2022, 1, 1), op.getOrderStartDate(quote.Id));
        Test.stopTest();
    }

    public static SBQQ__Quote__c createQuote(Id accountId, Id opportunityId, Boolean inAdvance) {
        SBQQ__Quote__c quote = new SBQQ__Quote__c(
            SBQQ__Account__c = accountId, 
            SBQQ__Opportunity2__c = opportunityId, 
            SBQQ__Primary__c = true, 
            SBQQ__Type__c = 'Quote', 
            SBQQ__Status__c = 'Raised',
            Billing_Type__c = (inAdvance ? 'In Advance' : 'In Arrears')
        );
        insert quote;
        return quote;
    }
}