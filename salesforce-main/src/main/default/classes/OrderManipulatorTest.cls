/*
* Who Patrick Duncan <patrick.duncan@weare4c.com> 
* What Test class for OrderManipulator
* When 10/8/20
*/
@isTest
public class OrderManipulatorTest {
	
    /*@testSetup
    static void setup(){
        Account monthlyAccount = TestDataFactory.createAccount(false, false, 1);
        monthlyAccount.Billing_Frequency__c = 'Monthly';
        monthlyAccount.Billing_Type__c = 'In Arrears';
        Account quaterlyAccount = TestDataFactory.createAccount(false, false, 2);
        quaterlyAccount.Billing_Frequency__c = 'Quarterly';
        quaterlyAccount.Billing_Cycle_Start_Month__c = '6';
        quaterlyAccount.Billing_Type__c = 'In Arrears';
        Account semiAnnualAccount = TestDataFactory.createAccount(false, false, 3);
        semiAnnualAccount.Billing_Frequency__c = 'Semiannual';
        semiAnnualAccount.Billing_Cycle_Start_Month__c = '6';
        semiAnnualAccount.Billing_Type__c = 'In Arrears';
        Account annualAccount = TestDataFactory.createAccount(false, false, 4);
        annualAccount.Billing_Frequency__c = 'Annual';
        annualAccount.Billing_Cycle_Start_Month__c = '6';
        annualAccount.Billing_Type__c = 'In Arrears';
        insert new List<Account>{monthlyAccount, quaterlyAccount, semiAnnualAccount, annualAccount};
    }

    
    *
    * Method backDateOrders
    * Case When inserting an order with a created date that is before its parent account's billing cycle start that also has a monthly billing frequency
    * Result Expect the Order's EffectiveDate to be the start of the created month
    *
    @isTest
    static void createdAfterMonthlyCycle(){
        Account quaterlyAccount = [SELECT Id FROM Account WHERE Name LIKE '%1'];
        Order order = new Order(AccountId=quaterlyAccount.Id);
        order.EffectiveDate = Date.today();
        order.Status = 'Draft';
        OrderCreatedDateMock.mockCreationDate = Date.newInstance(2020, 11, 7);

        Test.startTest();
            insert order;
        Test.stopTest();

        Order updatedOrder = [SELECT EffectiveDate FROM Order WHERE Id = :order.Id];

        System.assertEquals(Date.newInstance(2020, 11, 1), updatedOrder.EffectiveDate);

    }

    *
    * Method backDateOrders
    * Case When inserting an order with a created date that is after its parent account's billing cycle start that also has a monthly billing frequency
    * Result Expect the Order's EffectiveDate to be the start of the created month
    *
    @isTest
    static void createdBeforeMonthlyCycle(){
        Account quaterlyAccount = [SELECT Id FROM Account WHERE Name LIKE '%1'];
        Order order = new Order(AccountId=quaterlyAccount.Id);
        order.EffectiveDate = Date.today();
        order.Status = 'Draft';
        OrderCreatedDateMock.mockCreationDate = Date.newInstance(2021, 1, 7);

        Test.startTest();
            insert order;
        Test.stopTest();

        Order updatedOrder = [SELECT EffectiveDate FROM Order WHERE Id = :order.Id];

        System.assertEquals(Date.newInstance(2021, 1, 1), updatedOrder.EffectiveDate);

    }

    *
    * Method backDateOrders
    * Case When inserting an order with a created date that is before its parent account's billing cycle start that also has a quaterly billing frequency
    * Result Expect the Order's EffectiveDate to be the start of the quaterly period
    *
    @isTest
    static void createdBeforeQuaterlyCycle(){
        Account quaterlyAccount = [SELECT Id FROM Account WHERE Name LIKE '%2'];
        Order order = new Order(AccountId=quaterlyAccount.Id);
        order.EffectiveDate = Date.today();
        order.Status = 'Draft';
        OrderCreatedDateMock.mockCreationDate = Date.newInstance(2021, 3, 1);

        Test.startTest();
            insert order;
        Test.stopTest();

        Order updatedOrder = [SELECT EffectiveDate FROM Order WHERE Id = :order.Id];

        System.assertEquals(Date.newInstance(2021, 3, 1), updatedOrder.EffectiveDate);

    }

    *
    * Method backDateOrders
    * Case When inserting an order with a created date that is after its parent account's billing cycle start that also has a quaterly billing frequency
    * Result Expect the Order's EffectiveDate to be the start of the current quaterly period
    *
    @isTest
    static void createdAfterQuaterlyCycle(){
        Account quaterlyAccount = [SELECT Id FROM Account WHERE Name LIKE '%2'];
        Order order = new Order(AccountId=quaterlyAccount.Id);
        order.EffectiveDate = Date.today();
        order.Status = 'Draft';
        OrderCreatedDateMock.mockCreationDate = Date.newInstance(2020, 8, 1);

        Test.startTest();
            insert order;
        Test.stopTest();

        Order updatedOrder = [SELECT EffectiveDate FROM Order WHERE Id = :order.Id];

        System.assertEquals(Date.newInstance(2020, 6, 1), updatedOrder.EffectiveDate);

    }

    *
    * Method backDateOrders
    * Case When inserting an order with a created date that is after its parent account's billing cycle start that also has a semi-annual billing frequency
    * Result Expect the Order's EffectiveDate to be the start of the current quaterly period
    *
    @isTest
    static void createdBeforeSemiAnnualCycle(){
        Account quaterlyAccount = [SELECT Id FROM Account WHERE Name LIKE '%3'];
        Order order = new Order(AccountId=quaterlyAccount.Id);
        order.EffectiveDate = Date.today();
        order.Status = 'Draft';
        OrderCreatedDateMock.mockCreationDate = Date.newInstance(2021, 4, 18);

        Test.startTest();
            insert order;
        Test.stopTest();

        Order updatedOrder = [SELECT EffectiveDate FROM Order WHERE Id = :order.Id];

        System.assertEquals(Date.newInstance(2020, 12, 1), updatedOrder.EffectiveDate);

    }

    *
    * Method backDateOrders
    * Case When inserting an order with a created date that is after its parent account's billing cycle start that also has a semi-annual billing frequency
    * Result Expect the Order's EffectiveDate to be the start of the current quaterly period
    *
    @isTest
    static void createdAfterSemiAnnualCycle(){
        Account quaterlyAccount = [SELECT Id FROM Account WHERE Name LIKE '%3'];
        Order order = new Order(AccountId=quaterlyAccount.Id);
        order.EffectiveDate = Date.today();
        order.Status = 'Draft';
        OrderCreatedDateMock.mockCreationDate = Date.newInstance(2020, 8, 1);

        Test.startTest();
            insert order;
        Test.stopTest();

        Order updatedOrder = [SELECT EffectiveDate FROM Order WHERE Id = :order.Id];

        System.assertEquals(Date.newInstance(2020, 6, 1), updatedOrder.EffectiveDate);

    }

    *
    * Method backDateOrders
    * Case When inserting an order with a created date that is after its parent account's billing cycle start that also has a annual billing frequency
    * Result Expect the Order's EffectiveDate to be the start of the current quaterly period
    *
    @isTest
    static void createdBeforeAnnualCycle(){
        Account quaterlyAccount = [SELECT Id FROM Account WHERE Name LIKE '%4'];
        Order order = new Order(AccountId=quaterlyAccount.Id);
        order.EffectiveDate = Date.today();
        order.Status = 'Draft';
        OrderCreatedDateMock.mockCreationDate = Date.newInstance(2020, 5, 17);

        Test.startTest();
            insert order;
        Test.stopTest();

        Order updatedOrder = [SELECT EffectiveDate FROM Order WHERE Id = :order.Id];

        System.assertEquals(Date.newInstance(2019, 6, 1), updatedOrder.EffectiveDate);

    }

    *
    * Method backDateOrders
    * Case When inserting an order with a created date that is after its parent account's billing cycle start that also has a annual billing frequency
    * Result Expect the Order's EffectiveDate to be the start of the current quaterly period
    *
    @isTest
    static void createdAfterAnnualCycle(){
        Account quaterlyAccount = [SELECT Id FROM Account WHERE Name LIKE '%4'];
        Order order = new Order(AccountId=quaterlyAccount.Id);
        order.EffectiveDate = Date.today();
        order.Status = 'Draft';
        OrderCreatedDateMock.mockCreationDate = Date.newInstance(2020, 12, 21);

        Test.startTest();
            insert order;
        Test.stopTest();

        Order updatedOrder = [SELECT EffectiveDate FROM Order WHERE Id = :order.Id];

        System.assertEquals(Date.newInstance(2020, 6, 1), updatedOrder.EffectiveDate);

    }*/

   
}