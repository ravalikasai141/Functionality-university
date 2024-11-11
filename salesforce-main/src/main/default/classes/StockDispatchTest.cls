@isTest
public class StockDispatchTest {
    static Delivery__c buildDelivery(Account studentAccount, OrderItem orderProduct, Stock_Site__c stockSite, Integer quantity, Address__c address) {
        return new Delivery__c(
            Account__c = studentAccount.Id,
            Delivery_Status__c = 'Awaiting Allocation',
            Quantity__c = quantity,
            Stock_Allocated__c = false,
            Added_To_Shortage__c = false,
            Order_Product__c = orderProduct.Id,
            Stock_Site__c = stockSite.Id,
            Address_Line_1__c = address.Street_1__c,
            City__c = address.City__c,
            Postal_Code__c = address.Zip_Postal_Code__c,
            Country__c = address.Lookup_Country__c
        );
    }

    static Stock_Site__c buildStockSite() {
        return new Stock_Site__c(
            Name = 'UK Warehouse', 
            BPP_Product_Factory_ID__c = '9bc37088-2483-46f7-b4a4-62a83fefd662'
        );
    }

    static Stock_Management__c buildStockManagement(Product2 material, Stock_Site__c stockSite, Integer totalStock) {
        return new Stock_Management__c(
            Available_From__c = Date.newInstance(2021,1,1),
            Expiry_Date__c = Date.newInstance(2099,1,1),
            Product_Standalone__c = material.Id,
            Product_Factory_Product_ID__c = material.BPP_ProductFactoryID__c,
            Production_Method__c = 'Managed',
            Stock_Site__c = stockSite.Id,
            Total__c = totalStock
        );
    }

    static Product2 buildStandaloneMaterial() {
        return new Product2(
            Name='Test product', 
            IsActive = true, 
            Family = 'Materials',
            Format__c = 'Physical',
            BPP_ProductFactoryID__c = '8a72e11d-e1b0-43b1-adae-4e0690369bf9',
            Standalone_Material__c = true
        );
    }

    static Order buildOrder(Account account) {
        Stock_Site__c stockSite = TestDataFactory.buildDefaultStockSite();
        insert stockSite;

        return new Order(
            AccountId = account.Id,
            Status = 'Draft', 
            EffectiveDate = Date.newInstance(2021,1,1),
            blng__BillingDayOfMonth__c = '1',
            Pricebook2Id = Test.getStandardPricebookId(),
            Stock_Site__c = stockSite.Id
        );
    }

    static OrderItem buildOrderProduct(Product2 product, Order order, PricebookEntry pricebookEntry) {
        return new OrderItem(
            OrderId = order.Id, 
            Product2Id = product.Id,
            SBQQ__ChargeType__c = 'One-Time',
            PricebookEntryId = pricebookEntry.Id,
            UnitPrice = 10,
            Quantity = 1
        );
    }

    static Delivery__c getDelivery() {
        return [
            SELECT 
                Id, 
                Delivery_Status__c, 
                Quantity__c, 
                Allocation_Date__c, 
                Stock_Allocated__c, 
                Added_To_Shortage__c, 
                Stock_Management__c, 
                Auto_Allocate__c, 
                Dispatch_Reference__c, 
                Dispatched_Date__c 
            FROM Delivery__c
        ];
    }

    static Stock_Management__c getStockManagement() {
        return [SELECT Id, Allocated__c, Total__c, Available__c, Shortage__c FROM Stock_Management__c];
    }

    static void setupTestData(Integer totalStock, Integer deliveryQty) {
        // Create Student Account
        Account studentAccount = TestDataFactory.createAccount(true,false,null,0);

        // Create Address
        country_list__c cntry = CreateTestData.createCountry1();
        Address__c address = TestDataFactory.createAddress(true,0,studentAccount,cntry,true,true);

        // Create Product
        Product2 material = buildStandaloneMaterial();
        insert material;

        // Create Order
        Order order = buildOrder(studentAccount);
        insert order;
        PriceBookEntry pricebookEntry = TestDataFactory.createPricebookEntry(true, material, null);
        OrderItem orderProduct = buildOrderProduct(material, order, pricebookEntry);
        insert orderProduct;
       
        // Create Stock Site  
        Stock_Site__c stockSite = buildStockSite();
        insert stockSite;

        // Create Stock Management
		Stock_Management__c stockManagement = buildStockManagement(material, stockSite, totalStock);
        insert stockManagement;

        // Create Courier to avoid hardcoded Id in Process Builder
        Courier__c testCourier = TestDataFactory.buildDefaultCourier();
        insert testCourier;

        // Create Delivery
        Delivery__c delivery = buildDelivery(studentAccount, orderProduct, stockSite, deliveryQty, address);
        delivery.Courier__c = testCourier.Id;
        insert delivery;
    }
    
    @isTest
    static void dispatchStock_AlreadyAllocated_Dispatches() {
        // ARRANGE
        Integer totalStock = 10;
        Integer deliveryQty = 6;
        setupTestData(totalStock, deliveryQty);
        Delivery__c delivery = getDelivery();
        delivery.Delivery_Status__c = 'Sent for Fulfilment';
        update delivery;

        // PRE-ASSERT
        delivery = getDelivery();
        Stock_Management__c stockManagement = getStockManagement();
        System.assertEquals('Sent for Fulfilment', delivery.Delivery_Status__c);
        System.assertNotEquals(null, delivery.Stock_Management__c);
        System.assertEquals(6, stockManagement.Allocated__c);
        System.assertEquals(10, stockManagement.Total__c);

        // ACT
        // NOTE: The Delivery Status, Reference and Date are updated by the Dataloader.  This mimics this process.
        delivery.Delivery_Status__c = 'Dispatched';
        delivery.Dispatch_Reference__c = 'Reference12345';
        delivery.Dispatched_Date__c = System.today();
        update delivery;

        // NOTE: Triggers Process that fires StockDispatch APEX class

        // ASSERT
        delivery = getDelivery();
        stockManagement = getStockManagement();
        System.assertEquals(null, delivery.Stock_Management__c, 'Test Stock Management is Removed');
        System.assertEquals(false, delivery.Stock_Allocated__c, 'Test Stock is no longer Allocated');
        System.assertEquals(System.today(), delivery.Dispatched_Date__c, 'Test Dispatch Date remains as Today');
        System.assertEquals('Dispatched', delivery.Delivery_Status__c, 'Test Delivery Status remains as Dispatched');
        System.assertEquals('Reference12345', delivery.Dispatch_Reference__c, 'Test Dispatch Reference remains');

        System.assertEquals(0, stockManagement.Allocated__c, 'Test Allocated Level is Updated');
        System.assertEquals(4, stockManagement.Total__c, 'Test Total Level is Updated');
    }
}