public class X3InvoiceUploaderController {
    public String nameFile {get;set;}
    public Blob contentFile {get;set;}
    static Set<Id> orderIds = new Set<Id>();
    static List<X3_Migration_Item__c> x3MigrationItemList = new List<X3_Migration_Item__c>();
    static List<Order> ordersToInsert = new List<Order>();
    static List<OrderItem> orderItemsToInsert = new List<OrderItem>();
    List<Order> newOrders;
    List<Order> updatedOrders;
    List<blng__Invoice__c> updatedInvoices;
    
    public PageReference readX3Records() {
        nameFile = blobToString(contentFile, 'ISO-8859-1');
        createX3MigrationItemRecords(nameFile);
        
        Id priceBookId = [SELECT Id FROM Pricebook2 WHERE Name = 'Standard Price Book'].Id;
        Id ukStockSiteId = [SELECT Id FROM Stock_Site__c WHERE Name = 'UK Warehouse'].Id;
        Id x3ProductId = [SELECT Id FROM Product2 WHERE Name = 'X3 Migrated Product' AND IsActive = true].Id;
        Id priceBookEntryId = [SELECT Id FROM PricebookEntry WHERE Product2Id =: x3ProductId].Id;
        for (X3_Migration_Item__c x3MigrationItem : x3MigrationItemList) {
            System.debug(x3MigrationItem);
            initialiseOrders(x3MigrationItem.Account__c, x3MigrationItem.Invoice_Reference__c, x3MigrationItem.Order_Start_Date__c, x3MigrationItem.Order_Payment_Term__c, priceBookId, ukStockSiteId);
            initialiseOrderProducts(x3MigrationItem.Order_Product_Billable_Unit_Price__c, x3MigrationItem.Order_Product_Legal_Entity__c, x3MigrationItem.Order_Product_Start_Date__c, x3MigrationItem.Order_Product_Unit_Price__c, priceBookEntryId, x3ProductId);
        }
        insertOrderAndOrderProductRecords(ordersToInsert, orderItemsToInsert);
        
        try {
            updateOrderRecords(orderIds);
        } catch (Exception e) {
            ApexPages.Message errorMessage = new ApexPages.Message(ApexPages.severity.ERROR, 'An error has occured updating the Orders: ' + e.getMessage());
            ApexPages.addMessage(errorMessage);
        }
        return null;
    }
    
    public static void createX3MigrationItemRecords(String csvAsString) {
        List<String> csvFileLines = csvAsString.split('\n'); 
        
        for (Integer i = 1; i < csvFileLines.size(); i++) {
            System.debug(csvFileLines.get(i));
            List<String> csvRecordData = csvFileLines[i].split(',');
            X3_Migration_Item__c x3MigrationItem = new X3_Migration_Item__c();
            x3MigrationItem.Account__c = csvRecordData[0];
            x3MigrationItem.Order_Start_Date__c = Date.valueOf(csvRecordData[1]);
            x3MigrationItem.Order_Payment_Term__c = csvRecordData[2];
            x3MigrationItem.Order_Product_Unit_Price__c = Decimal.valueOf(csvRecordData[3]);
            x3MigrationItem.Order_Product_Billable_Unit_Price__c = Decimal.valueOf(csvRecordData[4]);
            x3MigrationItem.Order_Product_Start_Date__c = Date.valueOf(csvRecordData[5]);
            x3MigrationItem.Order_Product_Legal_Entity__c = csvRecordData[6];
            x3MigrationItem.Invoice_Date__c = Date.valueOf(csvRecordData[7]);
            x3MigrationItem.Invoice_Reference__c = csvRecordData[8];
            x3MigrationItem.Invoice_Line_Tax__c = Decimal.valueOf(csvRecordData[9].trim());
            x3MigrationItemList.add(x3MigrationItem);
        }
        if (x3MigrationItemList.size() > 0) {
            try {
                insert x3MigrationItemList;
            } catch (Exception e) {
                ApexPages.Message errorMessage = new ApexPages.Message(ApexPages.severity.ERROR, 'An error has occured inserting the records: ' + e.getMessage());
                ApexPages.addMessage(errorMessage);
            }
        }
    }
    
    public static void initialiseOrders(String accountId, String invoiceReference, Date orderStartDate, String orderPaymentTerm, Id priceBookId, Id ukStockSiteId) {
        Order order = new Order(
            AccountId = accountId,
            Billing_Mode__c = 'Billed in Salesforce',
            Billing_Type__c = 'In Advance',
            Booking_Type__c = 'Professional qualifications bookings',
            Description = 'Migrated from X3',
            EffectiveDate = orderStartDate,
            Invoice_Comments__c = invoiceReference,
            BPP_Internal_Comments__c = 'Migrated from X3',
            Pricebook2Id = priceBookId,
            SBQQ__PaymentTerm__c = orderPaymentTerm,
            Status = 'Draft',
            Stock_Site__c = ukStockSiteId
        );
        ordersToInsert.add(order);
    }
    
    public static void initialiseOrderProducts(Decimal orderProductBillableUnitPrice, String orderProductLegalEntity, Date orderProductStartDate, Decimal orderProductUnitPrice, Id priceBookEntryId, Id x3ProductId) {
        OrderItem orderItem = new OrderItem(
            blng__BillableUnitPrice__c = orderProductBillableUnitPrice,
            blng__LegalEntity__c = orderProductLegalEntity,
            Description = 'Migrated from X3',
            Quantity = 1,
            PricebookEntryId = priceBookEntryId,
            Product2Id = x3ProductId,
            SBQQ__Status__c = 'Draft',
            ServiceDate = orderProductStartDate,
            UnitPrice = orderProductUnitPrice
        );
        orderItemsToInsert.add(orderItem);
    }
    
    public static void insertOrderAndOrderProductRecords(List<Order> ordersToInsert, List<OrderItem> orderItemsToInsert) {
        try {
            insert ordersToInsert;
            for (Integer i = 0; i < orderItemsToInsert.size(); i++) {
                orderItemsToInsert.get(i).OrderId = ordersToInsert.get(i).Id;
                orderIds.add(ordersToInsert.get(i).Id);
            }
            insert orderItemsToInsert;
        } catch (Exception e) {
            ApexPages.Message errorMessage = new ApexPages.Message(ApexPages.severity.ERROR, 'An error has occured inserting the records: ' + e.getMessage());
            ApexPages.addMessage(errorMessage);
        }
    }
    
    @future(callout = true)
    public static void updateOrderRecords(Set<Id> orderIds) {
        List<Order> orderList = [SELECT Id FROM Order WHERE Id IN: orderIds];
        for (Order order : orderList) {
            order.Status = 'Activated';
        }
        update orderList;
    }
    
    public PageReference checkForOrders() {
        newOrders = [
            SELECT Id, OrderNumber, Account.Name, Status FROM Order 
            WHERE Status = 'Activated' AND BPP_Internal_Comments__c = 'Migrated from X3' AND CreatedDate = TODAY AND CreatedById =: UserInfo.getUserId()
            AND BPP_Invoice__c = null
        ];
        updatedOrders = [
            SELECT Id, OrderNumber, Account.Name, Status, BPP_Invoice__r.Name FROM Order 
            WHERE Status = 'Activated' AND BPP_Internal_Comments__c = 'Migrated from X3' AND CreatedDate = TODAY AND CreatedById =: UserInfo.getUserId()
            AND BPP_Invoice__c != null
        ];
        return null;
    }
    
    public PageReference checkForInvoices() {
        updatedInvoices = [
            SELECT Id, Name, blng__Account__r.Name, blng__InvoiceStatus__c, blng__InvoiceDate__c, Payment_Term__c, blng__DueDate__c, blng__Subtotal__c, blng__TaxAmount__c FROM blng__Invoice__c 
            WHERE blng__InvoiceStatus__c = 'Draft' AND Created_via_X3_Migration__c = true AND External_Invoice_Number__c != null AND CreatedDate = TODAY AND CreatedById =: UserInfo.getUserId()
        ];
        return null;
    }
    
    public PageReference runCreateInvoiceBatch() {
        CreateInvoiceBatch createInvoiceBatch = new CreateInvoiceBatch();
        Database.executeBatch(createInvoiceBatch, 1);
        return null;
    }
    
    public PageReference updateInvoiceAndInvoiceLines() {
        updateInvoiceRecords();
        return null;
    }
    
    @future(callout = true)
    public static void updateInvoiceRecords() {
        Map<Id, List<X3_Migration_Item__c>> x3MigrationItemMap = createX3MigrationItemMap();
        for (Id key : x3MigrationItemMap.keyset()) {
            System.debug('key: ' + key);
            for (X3_Migration_Item__c value : x3MigrationItemMap.get(key)) {
                System.debug('value: '+ value);
            }
        }
        
        List<blng__Invoice__c> invoiceList = [
            SELECT Id, blng__Account__c, blng__Order__r.Invoice_Comments__c, (SELECT Id FROM blng__InvoiceInvoiceLines__r) FROM blng__Invoice__c 
            WHERE blng__Order__r.BPP_Internal_Comments__c = 'Migrated from X3' AND External_Invoice_Number__c = null 
            AND CreatedDate = TODAY AND CreatedById =: UserInfo.getUserId() ORDER BY Name
        ];
        List<blng__InvoiceLine__c> invoiceLineList = new List<blng__InvoiceLine__c>();
        
        for (blng__Invoice__c invoice : invoiceList) {
            X3_Migration_Item__c x3MigrationItem;
            List<X3_Migration_Item__c> x3MigrationItemList = x3MigrationItemMap.get(invoice.blng__Account__c);
            for (X3_Migration_Item__c x3MI : x3MigrationItemList) {
                if (invoice.blng__Order__r.Invoice_Comments__c == x3MI.Invoice_Reference__c && !x3MI.Processed__c) {
                    x3MigrationItem = x3MI;
                }
            }
            
            if (x3MigrationItem != null) {
                System.debug('Current x3MigrationItem: ' + x3MigrationItem);
                invoice.blng__Notes__c = 'Migrated from X3';
                invoice.blng__InvoiceDate__c = x3MigrationItem.Invoice_Date__c;
                invoice.blng__DueDate__c = InvoiceLineUtility.generateInvoiceDueDate(x3MigrationItem.Invoice_Date__c, x3MigrationItem.Order_Payment_Term__c);
                invoice.blng__TargetDate__c = x3MigrationItem.Invoice_Date__c;
                invoice.Created_via_X3_Migration__c = true;
                invoice.External_Invoice_Number__c = x3MigrationItem.Invoice_Reference__c;
                
                blng__InvoiceLine__c invoiceLine = invoice.blng__InvoiceInvoiceLines__r;
                invoiceLine.blng__TaxAmount__c = x3MigrationItem.Invoice_Line_Tax__c;
                invoiceLineList.add(invoiceLine);
                x3MigrationItem.Processed__c = true;
            }
        }
        try {
            if (invoiceLineList.size() > 0) update invoiceLineList;
            if (invoiceList.size() > 0) update invoiceList;
        } catch (Exception e) {
            System.debug('[' + e.getLineNumber() + '] ' + e.getMessage());
            throw e;
        } finally {
            List<X3_Migration_Item__c> x3MigrationItemsToDelete = new List<X3_Migration_Item__c>();
            for (List<X3_Migration_Item__c> collection : x3MigrationItemMap.values()) {
                x3MigrationItemsToDelete.addAll(collection);
            }
            delete x3MigrationItemsToDelete;
        }
    }
    
    public static Map<Id, List<X3_Migration_Item__c>> createX3MigrationItemMap() {
        Map<Id, List<X3_Migration_Item__c>> x3MigrationItemMap = new Map<Id, List<X3_Migration_Item__c>>();
        for (X3_Migration_Item__c x3MigrationItem : [
            SELECT Account__c, Invoice_Date__c, Invoice_Line_Tax__c, Invoice_Reference__c, Order_Payment_Term__c, 
            Order_Product_Billable_Unit_Price__c, Order_Product_Legal_Entity__c, Order_Product_Start_Date__c, Order_Product_Unit_Price__c, 
            Order_Start_Date__c, Processed__c FROM X3_Migration_Item__c ORDER BY Name DESC
        ]) {
            List<X3_Migration_Item__c> x3MigrationItemRecordsForMap = x3MigrationItemMap.get(x3MigrationItem.Account__c);
            if (x3MigrationItemRecordsForMap == null) {
                x3MigrationItemRecordsForMap = new List<X3_Migration_Item__c>();
                x3MigrationItemMap.put(x3MigrationItem.Account__c, x3MigrationItemRecordsForMap);
            }    
            x3MigrationItemRecordsForMap.add(x3MigrationItem);
        }
        return x3MigrationItemMap;
    }
    
    public PageReference runPostInvoiceBatch() {
        PostInvoiceBatch postInvoiceBatch = new PostInvoiceBatch();
        Database.executeBatch(postInvoiceBatch, 1);
        return null;
    }
    
    public List<Order> getordersToInsert() {
        return (ordersToInsert != null && ordersToInsert.size() > 0 ? ordersToInsert : null);
    }
    
    public List<Order> getnewOrders() {
        return (newOrders != NULL && newOrders.size() > 0 ? newOrders : null);
    }
    
    public List<Order> getupdatedOrders() {
        return (updatedOrders != NULL && updatedOrders.size() > 0 ? updatedOrders : null);
    }
    
    public List<blng__Invoice__c> getupdatedInvoices() {
        return (updatedInvoices != NULL && updatedInvoices.size() > 0 ? updatedInvoices : null);
    }
    
    public static String blobToString(Blob input, String inCharset) {
        String hex = EncodingUtil.convertToHex(input);
        System.assertEquals(0, hex.length() & 1);
        final Integer bytesCount = hex.length() >> 1;
        String[] bytes = new String[bytesCount];
        for(Integer i = 0; i < bytesCount; ++i)
            bytes[i] =  hex.mid(i << 1, 2);
        return EncodingUtil.urlDecode('%' + String.join(bytes, '%'), inCharset);
    }
}