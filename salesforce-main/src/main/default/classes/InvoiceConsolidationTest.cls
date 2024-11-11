/**
 *  @who    Duy Vu <duy.vu@weare4c.com>
 *  @when   18/08/2020
 *  @what   Test class for InvoiceConsolidation
 */

@isTest
public class InvoiceConsolidationTest {
    @TestSetup
    static void makeData(){
        Account account = TestDataFactory.createAccount(true, false, null, 1);
        Order order = TestDataFactory.createOrder(true, 1, account, null);

        blng__BillingRule__c billingRule = TestDataFactory.createBillingRule(true);
		blng__FinanceBook__c billingFinanceBook = TestDataFactory.createBillingFinanceBook(true);
		blng__BillingTreatment__c billingTreatment = TestDataFactory.createBillingTreatment(true, billingRule, billingFinanceBook);
		blng__RevenueRecognitionRule__c revenueRecognitionRule = TestDataFactory.createRevenueRecognitionRule(true);
		blng__TaxRule__c taxRule = TestDataFactory.createTaxRule(true);

        Product2 product = TestDataFactory.createProduct(false,1,billingRule,revenueRecognitionRule,taxRule);
        product.Sitting__c = '2020';
        product.Qualification__c = 'ACCA';
        product.Paper__c = 'BA1';
        product.Level_PQ__c = 'Diploma';
        insert product;

        PricebookEntry priceBookEntry = TestDataFactory.createPricebookEntry(true, product, null);

        List<OrderItem> orderLines = new List<OrderItem>();
        orderLines.add(TestDataFactory.createOrderLine(false, order, product, null,
            priceBookEntry, billingRule, revenueRecognitionRule, taxRule, 'Materials'));
        orderLines.add(TestDataFactory.createOrderLine(false, order, product, null,
            priceBookEntry, billingRule, revenueRecognitionRule, taxRule, 'Session'));
        orderLines.add(TestDataFactory.createOrderLine(false,order,product,null,
            priceBookEntry, billingRule, revenueRecognitionRule, taxRule, 'Online Session'));
		insert orderLines;
    }

    @isTest
    static void generateInvoiceGroupIdFornewOrderProductWithEmptyInvoiceSeparation() {
        Order order = [SELECT Id FROM Order];
        order.blng__InvoiceBatch__c = 'Proforma';
        order.Status = 'Activated';
        
        Test.startTest();
        update order;
        Test.stopTest();

        List<OrderItem> orderLines = [SELECT Id, blng__InvoiceGroupId__c, blng__InvoiceGrouping__c FROM OrderItem];
        for (OrderItem orderLine : orderLines) {
            System.assertEquals(null, orderLine.blng__InvoiceGroupId__c, 'InvoiceGroupId should be empty when Invoice Separation in Account is not set');
            System.assertEquals(null, orderLine.blng__InvoiceGrouping__c, 'Invoice Grouping field should be empty when Invoice Separation in Account is not set');
        }
    }

    @isTest
    static void generateInvoiceGroupIdFornewOrderProductWithSitting() {
        Account account = [SELECT Id FROM Account];
        account.Invoice_Separation__c = 'Sitting';
        update account;

        Order order = [SELECT Id FROM Order];
        order.blng__InvoiceBatch__c = 'Proforma';
        order.Status = 'Activated';
        
        Test.startTest();
        update order;
        Test.stopTest();

        List<OrderItem> orderLines = [SELECT Id, blng__InvoiceGroupId__c, blng__InvoiceGrouping__c FROM OrderItem];
        for (OrderItem orderLine : orderLines) {
            System.assertEquals('2020', orderLine.blng__InvoiceGroupId__c, 'InvoiceGroupId should contain just Sitting');
            System.assertEquals('Invoice Group ID', orderLine.blng__InvoiceGrouping__c, 'Invoice Grouping field should be Invoice Group ID');
        }
    }

    @isTest
    static void generateInvoiceGroupIdForPerviouslyManualInvoicingOrder() {
        Account account = [SELECT Id FROM Account];
        account.Invoice_Separation__c = 'Sitting';
        update account;

        Order order = [SELECT Id FROM Order];
        order.blng__InvoiceBatch__c = 'Manual';
        order.Status = 'Activated';
        update order;
        
        order.blng__InvoiceBatch__c = 'Proforma';
    
        Test.startTest();
        update order;
        Test.stopTest();

        order = [SELECT Id, Invoice_Consolidation__c FROM Order];

        List<OrderItem> orderLines = [SELECT Id, blng__InvoiceGroupId__c, blng__InvoiceGrouping__c FROM OrderItem];
        for (OrderItem orderLine : orderLines) {
            System.assertEquals('2020', orderLine.blng__InvoiceGroupId__c, 'InvoiceGroupId should contain just Sitting');
            System.assertEquals('Invoice Group ID', orderLine.blng__InvoiceGrouping__c, 'Invoice Grouping field should be Invoice Group ID');
        }
    }

    @isTest
    static void generateInvoiceGroupIdFornewOrderProductWithSittingQualification() {
        Account account = [SELECT Id FROM Account];
        account.Invoice_Separation__c = 'Sitting;Qualification';
        update account;

        Order order = [SELECT Id FROM Order];
        order.blng__InvoiceBatch__c = 'Proforma';
        order.Status = 'Activated';
        
        Test.startTest();
        update order;
        Test.stopTest();

        List<OrderItem> orderLines = [SELECT Id, blng__InvoiceGroupId__c, blng__InvoiceGrouping__c FROM OrderItem];
        for (OrderItem orderLine : orderLines) {
            System.assertEquals('2020ACCA', orderLine.blng__InvoiceGroupId__c, 'InvoiceGroupId should contain Sitting and Qualification');
            System.assertEquals('Invoice Group ID', orderLine.blng__InvoiceGrouping__c, 'Invoice Grouping field should be Invoice Group ID');
        }
    }

    @isTest
    static void generateInvoiceGroupIdFornewOrderProductWithSittingQualificationPaperLevel() {
        Account account = [SELECT Id FROM Account];
        account.Invoice_Separation__c = 'Sitting;Qualification;Level';
        update account;

        Order order = [SELECT Id FROM Order];
        order.blng__InvoiceBatch__c = 'Proforma';
        order.Status = 'Activated';
        
        Test.startTest();
        update order;
        Test.stopTest();

        List<OrderItem> orderLines = [SELECT Id, blng__InvoiceGroupId__c, blng__InvoiceGrouping__c FROM OrderItem];
        for (OrderItem orderLine : orderLines) {
            System.assertEquals('2020ACCADiploma', orderLine.blng__InvoiceGroupId__c, 'InvoiceGroupId should contain Sitting, Qualification, Paper and Level');
            System.assertEquals('Invoice Group ID', orderLine.blng__InvoiceGrouping__c, 'Invoice Grouping field should be Invoice Group ID');
        }
    }

    @isTest
    static void generateInvoiceGroupIdFornewOrderProductWithSittingQualificationPaperLevelCustomGroup() {
        Account account = [SELECT Id FROM Account];
        account.Invoice_Separation__c = 'Sitting;Qualification;Level';
        update account;

        List<OrderItem> orderLines = [SELECT Id FROM OrderItem];
        for (OrderItem orderLine : orderLines) {
            orderLine.Custom_Group__c = 'CUSTOMGROUP';
        }
        update orderLines;

        Order order = [SELECT Id FROM Order];
        order.blng__InvoiceBatch__c = 'Proforma';
        order.Status = 'Activated';
        
        Test.startTest();
        update order;
        Test.stopTest();

        orderLines = [SELECT Id, blng__InvoiceGroupId__c, blng__InvoiceGrouping__c FROM OrderItem];
        for (OrderItem orderLine : orderLines) {
            System.assertEquals('2020ACCADiplomaCUSTOMGROUP', orderLine.blng__InvoiceGroupId__c, 'InvoiceGroupId should contain Sitting, Qualification, Paper, Level and CustomGroup');
            System.assertEquals('Invoice Group ID', orderLine.blng__InvoiceGrouping__c, 'Invoice Grouping field should be Invoice Group ID');
        }
    }

    @isTest
    static void generateInvoiceGroupIdFornewOrderProductWithCustomGroup() {
        List<OrderItem> orderLines = [SELECT Id FROM OrderItem];
        for (OrderItem orderLine : orderLines) {
            orderLine.Custom_Group__c = 'CUSTOMGROUP';
        }
        update orderLines;
        
        Order order = [SELECT Id FROM Order];
        order.blng__InvoiceBatch__c = 'Proforma';
        order.Status = 'Activated';

        Test.startTest();
        update order;
        Test.stopTest();

        orderLines = [SELECT Id, blng__InvoiceGroupId__c, blng__InvoiceGrouping__c FROM OrderItem];
        for (OrderItem orderLine : orderLines) {
            System.assertEquals('CUSTOMGROUP', orderLine.blng__InvoiceGroupId__c, 'InvoiceGroupId should contain just CustomGroup');
            System.assertEquals('Invoice Group ID', orderLine.blng__InvoiceGrouping__c, 'Invoice Grouping field should be Invoice Group ID');
        }
    }

    /*@isTest
    static void generateInvoiceGroupIdWhenUpdateAccountWithSittingQualificationPaperLevel() {
        Order order = [SELECT Id FROM Order];
        order.blng__InvoiceBatch__c = 'Proforma';
        order.Status = 'Activated';
        update order;

        Account account = [SELECT Id FROM Account];
        account.Invoice_Separation__c = 'Sitting;Qualification;Level';
        
        Test.startTest();
        update account;
        Test.stopTest();

        List<OrderItem> orderLines = [SELECT Id, blng__InvoiceGroupId__c, blng__InvoiceGrouping__c FROM OrderItem];
        for (OrderItem orderLine : orderLines) {
            System.assertEquals('2020ACCADiploma', orderLine.blng__InvoiceGroupId__c, 'InvoiceGroupId should contain Sitting, Qualification, Paper, and Level');
            System.assertEquals('Invoice Group ID', orderLine.blng__InvoiceGrouping__c, 'Invoice Grouping field should be Invoice Group ID');
        }
    }*/

    /*@isTest
    static void emptyInvoiceGroupIdWhenUpdateAccountWithEmptyInvoiceSeparation() {
        Account account = [SELECT Id FROM Account];
        account.Invoice_Separation__c = 'Sitting;Qualification;Level';
        update account;

        Order order = [SELECT Id FROM Order];
        order.blng__InvoiceBatch__c = 'Proforma';
        order.Status = 'Activated';
        update order;

        account = [SELECT Id FROM Account];
        account.Invoice_Separation__c = '';
        
        Test.startTest();
        update account;
        Test.stopTest();

        List<OrderItem> orderLines = [SELECT Id, blng__InvoiceGroupId__c, blng__InvoiceGrouping__c FROM OrderItem];
        for (OrderItem orderLine : orderLines) {
            System.assertEquals(null, orderLine.blng__InvoiceGroupId__c, 'InvoiceGroupId should be empty when Invoice Separation in Account is not set');
            System.assertEquals(null, orderLine.blng__InvoiceGrouping__c, 'Invoice Grouping field should be empty when Invoice Separation in Account is not set');
        }
    }*/

    /*@isTest
    static void generateInvoiceGroupIdWhenUpdateAccountWithEmptyInvoiceSeparationButCustomGroup() {
        Account account = [SELECT Id FROM Account];
        account.Invoice_Separation__c = 'Sitting;Qualification;Level';
        update account;

        List<OrderItem> orderLines = [SELECT Id FROM OrderItem];
        for (OrderItem orderLine : orderLines) {
            orderLine.Custom_Group__c = 'CUSTOMGROUP';
        }
        update orderLines;

        Order order = [SELECT Id FROM Order];
        order.blng__InvoiceBatch__c = 'Proforma';
        order.Status = 'Activated';
        update order;

        account.Invoice_Separation__c = '';
        
        Test.startTest();
        update account;
        Test.stopTest();

        orderLines = [SELECT Id, blng__InvoiceGroupId__c, blng__InvoiceGrouping__c FROM OrderItem];
        for (OrderItem orderLine : orderLines) {
            System.assertEquals('CUSTOMGROUP', orderLine.blng__InvoiceGroupId__c, 'InvoiceGroupId should contain just CustomGroup');
            System.assertEquals('Invoice Group ID', orderLine.blng__InvoiceGrouping__c, 'Invoice Grouping field should be Invoice Group ID');
        }
    }*/

    @isTest
    static void removeGroupingForManualInvoicing() {
        Account account = [SELECT Id FROM Account];
        account.Invoice_Separation__c = 'Sitting;Qualification;Level';
        update account;

        Order order = [SELECT Id FROM Order];
        order.blng__InvoiceBatch__c = 'Proforma';
        order.Status = 'Activated';
        update order;

        order.blng__InvoiceBatch__c = 'Manual';
        Test.startTest();
        update order;
        Test.stopTest();

        List<OrderItem> orderLines = [SELECT Id, blng__InvoiceGroupId__c, blng__InvoiceGrouping__c FROM OrderItem];
        for (OrderItem orderLine : orderLines) {
            System.assertEquals(null, orderLine.blng__InvoiceGroupId__c, 'InvoiceGroupId should be null if order is manual invoicing');
            System.assertEquals(null, orderLine.blng__InvoiceGrouping__c, 'Invoice Grouping field should be null if order is manual invoicing');
        }
    }

}