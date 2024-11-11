/*
 * @who   Patrick Duncan <patrick.duncan@weare4c.com>
 * @what  Data factory class for creating SObjects in test classes
 * @when  14/1/2020
 */
public with sharing class TestDataFactory {
    public static final String BOOKING_SUMMARY_MATCHING_ID = '123456789';

    /**
     * Generates an Stock Site record populated with default values
     * @return The resulting Stock Site
     */
    @testVisible
    private static Stock_Site__c buildDefaultStockSite() {
        return new Stock_Site__c(Name = 'Default Test Stock Site', BPP_Product_Factory_ID__c = 'TEST-1234');
    }

    /**
     * Generates a Courier record populated with default values
     * @return The resulting Courier
     */
    @testVisible
    private static Courier__c buildDefaultCourier() {
        return new Courier__c(Name = 'Default Test Courier', Export_Code__c = 'TEST-1234');
    }

    /**
     * Generates a Legal Entity record populated with default values
     * @return The resulting Legal Entity
     */
    @testVisible
    private static blng__LegalEntity__c buildDefaultLegalEntity() {
        return new blng__LegalEntity__c(
            blng__Active__c = true,
            BPP_Is_Parent__c = true,
            Name = 'BPP Learning Media Ltd',
            External_Id__c = 'BPP Learning Media Ltd'
        );
    }

    /**
     * Generates an Order record populated with default value
     * @param  account  The Account to link the Order to
     * @param  pricebook  The Pricebook to link the Order to
     * @param  stockSite  The Stock Site to link the Order to
     * @return The resulting default Order
     */
    @testVisible
    private static Order buildDefaultOrder(Account account, Pricebook2 pricebook) {
        return new Order(
            Name = 'Default Test Order',
            Status = 'Draft',
            EffectiveDate = Date.today(),
            blng__BillingDayOfMonth__c = '1',
            Billing_Mode__c = 'Billed in Salesforce',
            AccountId = account?.Id,
            Pricebook2Id = pricebook == null ? Test.getStandardPricebookId() : pricebook.Id
        );
    }

    public static List<Account> createAccounts(
        Integer requiredCount,
        String recordTypeName,
        Boolean doInsert,
        Map<String, Object> additionalFields
    ) {
        List<Account> accountList = new List<Account>();

        for (Integer i = 0; i < requiredCount; i++) {
            String uniqueString = TestDataFactory.generateUniqueString();
            Account newAccount = new Account(
                RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
                    .get(recordTypeName)
                    .getRecordTypeId(),
                Name = 'Test ' + recordTypeName + ': ' + uniqueString,
                Phone = '0123456789' + i
            );

            if (additionalFields.size() != 0) {
                for (String fieldName : additionalFields.keySet()) {
                    newAccount.put(fieldName, additionalFields.get(fieldName));
                }
            }

            accountList.add(newAccount);
        }

        if (doInsert) {
            Database.insert(accountList);
        }

        return accountList;
    }

    public static Account createAccount(Boolean doInsert, Boolean personAccount, Integer index) {
        Account acc = new Account();
        if (personAccount) {
            acc.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName()
                .get('Student Account')
                .getRecordTypeId();
            acc.FirstName = 'Test account ' + index;
            acc.LastName = 'Student';
            acc.Preferred_Email__pc = 'Personal';
            acc.Preferred_Phone__pc = 'Mobile';
            acc.PersonEmail = 'john@john.com';
            acc.Personal_Email__pc = 'john@john.com';
            acc.PersonMobilePhone = '+447716123748';
        } else {
            acc.Name = 'Test account ' + index;
        }
        if (doInsert)
            insert acc;
        return acc;
    }

    public static Account createAccount(Boolean doInsert, Boolean personAccount, Id clientId, Integer index) {
        Account acc = new Account();
        if (personAccount) {
            acc.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName()
                .get('Student Account')
                .getRecordTypeId();
            acc.FirstName = 'Test account ' + index;
            acc.LastName = 'Student';
            acc.Preferred_Email__pc = 'Personal';
            acc.Preferred_Phone__pc = 'Mobile';
            acc.PersonEmail = 'john@john.com';
            acc.Personal_Email__pc = 'john@john.com';
            acc.PersonMobilePhone = '+447716123748';
            acc.PersonBirthdate = date.today().addYears(-18);
            if (clientId != null) {
                acc.Client__c = clientId;
            }
        } else {
            acc.Name = 'Test account ' + index;
            acc.Billing_Type__c = 'In Advance';
            acc.Charge_Trigger__c = 'Instance Start Date';
        }
        if (doInsert) {
            insert acc;
        }
        return acc;
    }

    public static Account createAccount(
        String firstName,
        String lastName,
        String preferredEmail,
        String preferredPhone,
        String gender,
        String salutation,
        Id countryId,
        Boolean hasProfileId,
        Boolean initialRecord
    ) {
        String testEmail = 'qwertyui123@test.com';
        String testPhone = '0182938271';

        Account account = new Account();
        account.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
            .get('Student_Account')
            .getRecordTypeId();
        account.FirstName = firstName;
        account.LastName = lastName;
        account.Preferred_Email__pc = preferredEmail;
        account.Preferred_Phone__pc = preferredPhone;
        account.Salutation = salutation;
        account.Personal_Email__pc = initialRecord ? 'email1@mail.com' : 'john@john.com';
        account.Work_Email__pc = initialRecord ? 'email2@mail.com' : testEmail;
        account.BPP_Email__pc = initialRecord ? 'email3@mail.com' : testEmail;
        account.Other_Email__pc = initialRecord ? 'email4@mail.com' : testEmail;
        account.Billing_Email__pc = initialRecord ? 'email5@mail.com' : testEmail;
        account.PersonMobilePhone = initialRecord ? '4626141424' : '+447716123748';
        account.PersonHomePhone = initialRecord ? '42535522454' : testPhone;
        account.Work_Phone__pc = initialRecord ? '46225252454' : testPhone;
        account.Parents_Guardian_Emergency_Phone__pc = initialRecord ? '46265253454' : testPhone;
        account.Fax = initialRecord ? '46265235454' : testPhone;
        account.Preferred_First_Name__pc = 'Test';
        account.Gender__pc = gender;
        account.Middle_Name__pc = 'Greta';
        account.AA_Suffix__pc = 'E';
        account.PersonBirthdate = Date.valueOf('1986-02-07');
        account.Primary_Nationality__pc = countryId;
        account.SFDC_Ethnic_Code_Select__pc = '90~ Not known';
        account.AR_Student_Finance_England_SFE__c = 'AAAA12349876F';
        account.VAT_Code__pc = 'Test';
        if (hasProfileId) {
            account.PS_Profile_Services_ID__pc = '1234xxx5-xxx1-1x2x-xxx1-12345x678x9';
            account.Student_Type__pc = 'Domestic';
        }

        Database.DMLOptions dbDML = new Database.DMLOptions();
        dbDML.DuplicateRuleHeader.allowSave = true;
        Database.insert(account, dbDML);
        return account;
    }

    public static List<Contact> createContacts(
        Integer requiredCount,
        String recordTypeName,
        Boolean doInsert,
        Map<String, Object> additionalFields
    ) {
        List<Contact> contactList = new List<Contact>();
        for (Integer i = 0; i < requiredCount; i++) {
            String uniqueString = TestDataFactory.generateUniqueString();
            Contact newContact = new Contact(
                RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName()
                    .get(recordTypeName)
                    .getRecordTypeId(),
                FirstName = 'Test ' + recordTypeName + ' Contact ' + uniqueString,
                LastName = 'Test ' + recordTypeName + ' Contact ' + i,
                Phone = '+4423456789' + i,
                Email = 'emailTestAddress' + uniqueString + '@mail.com'
            );

            if (additionalFields.size() != 0) {
                newContact = (Contact) TestDataFactory.mapAdditionalFields(newContact, additionalFields);
            }

            contactList.add(newContact);
        }

        if (doInsert) {
            Database.insert(contactList);
        }
        return contactList;
    }

    public static Contact createContact(Boolean doInsert, Integer index, Account acc, String additionalFields) {
        Contact con = new Contact(
            LastName = 'Test contact ' + index,
            Email = 'testcon' + index + '@test.com',
            AccountId = acc.Id
        );

        if (additionalFields != null) {
            Map<String, Object> fieldsMap = (Map<String, Object>) JSON.deserializeUntyped(additionalFields);
            for (String fieldName : fieldsMap.keySet()) {
                con.put(fieldName, fieldsMap.get(fieldName));
            }
        }

        return con;
    }

    public static List<Sponsorship__c> createSponsorships(
        Integer requiredCount,
        Boolean doInsert,
        Map<String, Object> additionalFields
    ) {
        List<Sponsorship__c> sponsorshipList = new List<Sponsorship__c>();
        for (Integer i = 0; i < requiredCount; i++) {
            Sponsorship__c newSponsorShip = new Sponsorship__c(Active__c = true);

            if (additionalFields.size() != 0) {
                for (String fieldName : additionalFields.keySet()) {
                    newSponsorShip.put(fieldName, additionalFields.get(fieldName));
                }
            }

            sponsorshipList.add(newSponsorShip);
        }

        if (doInsert) {
            Database.insert(sponsorshipList);
        }
        return sponsorshipList;
    }

    /* START OF - Changes made by David Lovejoy - 01/11/2020 - method added for BPP-7144/8234/8651/10399 */
    public static Address__c createAddress(
        Boolean doInsert,
        Integer index,
        Account account,
        Country_list__c cntry,
        Boolean primaryDelivery,
        Boolean primary
    ) {
        Address__c address = new Address__c(
            Student__c = account.Id,
            Street_1__c = '1' + index + ' Test Street',
            City__c = 'Manchester',
            County_State__c = 'Cheshire',
            Zip_Postal_Code__c = 'M' + index + ' 1AD',
            Lookup_Country__c = cntry.Id,
            Active__c = true,
            Primary_Delivery__c = primaryDelivery,
            Primary__c = primary
        );
        if (doInsert)
            insert address;
        return address;
    }
    /* END OF - Changes made by David Lovejoy */

    public static void createAddress(Id accountId, Id leadId, Id countryId, String type) {
        Address__c address = new Address__c();
        if (accountId != null) {
            address.Student__c = accountId;
        }
        if (leadId != null) {
            address.Lead__c = leadId;
        }
        address.Type__c = type;
        address.Street_1__c = '329 S Tonne Dr';
        address.Street_2__c = '123';
        address.Street_3__c = '456';
        address.Street_4__c = '789';
        address.City__c = 'Chicago';
        address.Zip_Postal_Code__c = '12345';
        address.Lookup_Country__c = countryId;
        insert address;
    }

    public static Lead createLead(
        String firstName,
        String lastName,
        String preferredEmail,
        String preferredPhone,
        String gender,
        Id countryId
    ) {
        String testEmail = 'qwertyui123@test.com';
        String testPhone = '0182938271';

        Lead lead = new Lead();
        lead.RecordTypeId = Schema.sObjectType.Lead.getRecordTypeInfosByDeveloperName()
            .get('Prospective_Student')
            .getRecordTypeId();
        lead.LastName = lastName;
        lead.Birth_Date__c = Date.today().addYears(-20);
        lead.rfi_Are_you_EU_UK__c = 'UK (EU) Student';
        lead.Country_of_Residence__c = countryId;
        lead.Preferred_Email__c = preferredEmail;
        lead.Personal_Email__c = testEmail;
        lead.FirstName = firstName;
        lead.Work_Email__c = testEmail;
        lead.Other_Email__c = testEmail;
        lead.Billing_Email__c = testEmail;
        lead.MobilePhone = testPhone;
        lead.Work_Phone__c = testPhone;
        lead.Parents_Guardian_Emergency_Phone__c = testPhone;
        lead.Home_Phone__c = testPhone;
        lead.Fax = testPhone;
        lead.Preferred_Phone__c = preferredPhone;
        lead.Gender__c = gender;
        lead.Middle_Name__c = 'mid';
        lead.Salutation = 'sal';
        lead.Preferred_First_Name__c = 'pref';

        Database.DMLOptions dbDML = new Database.DMLOptions();
        dbDML.DuplicateRuleHeader.allowSave = true;
        Database.insert(lead, dbDML);
        return lead;
    }

    public static List<Lead> createLeads(Integer recordCount, Boolean doInsert, Map<String, Object> additionalFields) {
        List<Lead> leadList = new List<Lead>();
        for (Integer i = 0; i < recordCount; i++) {
            String uniqueString = TestDataFactory.generateUniqueString();
            Lead newLead = new Lead(FirstName = 'Test Lead ' + uniqueString, LastName = 'Test Lead ' + uniqueString);
            if (additionalFields.size() != 0) {
                newLead = (Lead) TestDataFactory.mapAdditionalFields(newLead, additionalFields);
            }
            leadList.add(newLead);
        }

        if (doInsert) {
            Database.insert(leadList);
        }

        return leadList;
    }

    /**
     * Generates an Order record populated with given values
     * @param  doInsert  Whether the Order should be inserted before returning
     * @param  index  An indexing integer for use in creating unique Orders
     * @param  acc  The Account to link to the Order
     * @param  pricebook  The Pricebook to link to the Order
     * @return The resulting default Order
     */
    public static Order createOrder(Boolean doInsert, Integer index, Account acc, Pricebook2 pricebook) {
        return createOrder(doInsert, index, acc, pricebook, null);
    }

    /**
     * Generates an Order record populated with given values
     * @param  doInsert  Whether the Order should be inserted before returning
     * @param  index  An indexing integer for use in creating unique Orders
     * @param  acc  The Account to link to the Order
     * @param  pricebook  The Pricebook to link to the Order
     * @param  address  The Address to link to the Order
     * @return The resulting default Order
     */
    public static Order createOrder(
        Boolean doInsert,
        Integer index,
        Account acc,
        Pricebook2 pricebook,
        Address__c address
    ) {
        Stock_Site__c testStockSite = buildDefaultStockSite();
        Order testOrder = buildDefaultOrder(acc, pricebook);

        if (index != null) {
            String indexSuffix = ' ' + index;
            testStockSite.Name += indexSuffix;
            testStockSite.BPP_Product_Factory_ID__c += indexSuffix;
            testOrder.Name += indexSuffix;
        }
        insert testStockSite;

        testOrder.Ship_To_Address__c = address?.Id;
        testOrder.Stock_Site__c = testStockSite.Id;

        if (doInsert) {
            insert testOrder;
        }

        return testOrder;
    }

    public static Product2 createProduct(
        Boolean doInsert,
        Integer index,
        blng__BillingRule__c billingRule,
        blng__RevenueRecognitionRule__c revenueRecognitionRule,
        blng__TaxRule__c taxRule
    ) {
        Product2 product = new Product2(
            Name = 'Test product ' + index,
            IsActive = true,
            blng__BillingRule__c = billingRule.Id,
            blng__RevenueRecognitionRule__c = revenueRecognitionRule.Id,
            blng__TaxRule__c = taxRule.Id
        );
        if (doInsert)
            insert product;
        return product;
    }

    public static Stock_Management__c createStockManagement(
        Boolean doInsert,
        Integer index,
        Date availableFrom,
        Date expiryDate,
        Id product,
        Id productStandalone,
        String productFactoryId,
        Id stockSite
    ) {
        Stock_Management__c stockManagement = new Stock_Management__c(
            Available_From__c = availableFrom,
            Expiry_Date__c = expiryDate,
            Product__c = product,
            Product_Standalone__c = productStandalone,
            Product_Factory_Product_ID__c = productFactoryId,
            Production_Method__c = 'Managed',
            Stock_Site__c = stockSite
        );
        if (doInsert)
            insert stockManagement;
        return stockManagement;
    }

    /* START OF - Changes made by David Lovejoy - 01/11/2020 - method added for BPP-7144/8234/8651/10399 */
    public static SBQQ__ProductOption__c createProductOption(
        Boolean doInsert,
        Product2 configuredSKU,
        Product2 optionalSKU,
        SBQQ__ProductFeature__c productFeature,
        String deliveryDefault
    ) {
        SBQQ__ProductOption__c productOption = new SBQQ__ProductOption__c(
            SBQQ__Number__c = 10,
            SBQQ__ConfiguredSKU__c = configuredSKU.Id,
            SBQQ__OptionalSKU__c = optionalSKU.Id,
            SBQQ__Feature__c = productFeature.Id,
            Delivery_Default__c = deliveryDefault
        );
        if (doInsert)
            insert productOption;
        return productOption;
    }
    /* END OF - Changes made by David Lovejoy */

    public static PricebookEntry createPricebookEntry(Boolean doInsert, Product2 product, Pricebook2 pricebook) {
        PricebookEntry priceBookEntry = new PricebookEntry(IsActive = true, Product2Id = product.Id, UnitPrice = 10);
        priceBookEntry.Pricebook2Id = pricebook == null ? Test.getStandardPricebookId() : pricebook.Id;
        if (doInsert)
            insert priceBookEntry;
        return priceBookEntry;
    }

    public static blng__BillingRule__c createBillingRule(Boolean doInsert) {
        blng__BillingRule__c billingRule = new blng__BillingRule__c(
            blng__Active__c = true,
            blng__GenerateInvoices__c = 'Yes',
            blng__InitialBillingTrigger__c = 'Order Product Activation Date',
            Name = 'Test billing rule'
        );
        if (doInsert)
            insert billingRule;
        return billingRule;
    }

    public static blng__FinanceBook__c createBillingFinanceBook(Boolean doInsert) {
        blng__FinanceBook__c billingFinanceBook = new blng__FinanceBook__c(
            blng__Active__c = true,
            blng__PeriodType__c = 'Accounting'
        );
        if (doInsert)
            insert billingFinanceBook;
        return billingFinanceBook;
    }

    public static blng__BillingTreatment__c createBillingTreatment(
        Boolean doInsert,
        blng__BillingRule__c billingRule,
        blng__FinanceBook__c billingFinanceBook
    ) {
        blng__BillingTreatment__c billingTreatment = new blng__BillingTreatment__c(
            blng__BillingRule__c = billingRule.Id,
            blng__BillingFinanceBook__c = billingFinanceBook.Id
        );
        if (doInsert)
            insert billingTreatment;
        return billingTreatment;
    }

    public static blng__RevenueRecognitionRule__c createRevenueRecognitionRule(Boolean doInsert) {
        blng__RevenueRecognitionRule__c revenueRecognitionRule = new blng__RevenueRecognitionRule__c(
            blng__Active__c = true,
            blng__CreateRevenueSchedule__c = 'Yes'
        );
        if (doInsert)
            insert revenueRecognitionRule;
        return revenueRecognitionRule;
    }

    public static blng__TaxRule__c createTaxRule(Boolean doInsert) {
        blng__TaxRule__c taxRule = new blng__TaxRule__c(blng__Active__c = true);
        if (doInsert)
            insert taxRule;
        return taxRule;
    }

    public static OrderItem createOrderLine(
        Boolean doInsert,
        Order order,
        Product2 product,
        OrderItem parentOrderLine,
        PricebookEntry priceBookEntry,
        blng__BillingRule__c billingRule,
        blng__RevenueRecognitionRule__c revenueRecognitionRule,
        blng__TaxRule__c taxRule,
        String family
    ) {
        OrderItem orderLine = new OrderItem(
            OrderId = order.Id,
            PricebookEntryId = priceBookEntry.Id,
            SBQQ__Activated__c = true,
            Product2Id = product.Id,
            SBQQ__ChargeType__c = 'One-Time',
            UnitPrice = 10,
            blng__BillingRule__c = billingRule.Id,
            Family__c = family,
            blng__RevenueRecognitionRule__c = revenueRecognitionRule.Id,
            blng__TaxRule__c = taxRule.Id,
            Quantity = 1,
            SBQQ__QuotedQuantity__c = 1
        );
        if (parentOrderLine != null) {
            orderLine.SBQQ__RequiredBy__c = parentOrderLine.Id;
        }
        if (doInsert)
            insert orderLine;
        return orderLine;
    }

    /* START OF - Changes made by David Lovejoy - 01/11/2020 - method added for BPP-7144/8234/8651/10399 */
    public static Study_Location__c createStudyLocation(Boolean doInsert, Integer index, Country_list__c cntry) {
        Study_Location__c studyLocation = new Study_Location__c(
            Name = 'Study Location ' + index,
            Active__c = true,
            Address_1__c = '79 Oxford Street',
            Address_2__c = 'Address Line 2',
            Address_3__c = 'Address Line 3',
            City__c = 'Manchester',
            Postal_Code__c = 'M1 6FQ',
            Country__c = cntry.Id
        );
        if (doInsert)
            insert studyLocation;
        return studyLocation;
    }
    /* END OF - Changes made by David Lovejoy */

    public static Instance__c createInstance(Boolean doInsert, Integer index, Product2 product) {
        Instance__c instance = new Instance__c(
            Product__c = product.Id,
            Instance_ID__c = 'ABCDEFG1234567' + index,
            Instance_Name__c = 'Test instance ' + index,
            Start_Date__c = Date.today(),
            End_Date__c = Date.today().addDays(5),
            BPP_Instance_Status__c = 'Active'
        );
        if (doInsert)
            insert instance;
        return instance;
    }

    /* START OF - Changes made by David Lovejoy - 01/11/2020 - method added for BPP-7144/8234/8651/10399 */
    public static Instance__c createInstance(
        Boolean doInsert,
        Integer index,
        Product2 product,
        Study_Location__c studyLocation
    ) {
        Instance__c instance = new Instance__c(
            Product__c = product.Id,
            Instance_ID__c = 'ABCDEFG1234567' + index,
            Instance_Name__c = 'Test instance ' + index,
            Start_Date__c = Date.today(),
            End_Date__c = Date.today().addDays(5),
            Study_Location__c = studyLocation.Id,
            BPP_Instance_Status__c = 'Active'
        );
        if (doInsert)
            insert instance;
        return instance;
    }
    /* END OF - Changes made by David Lovejoy */

    public static Session__c createSession(
        Boolean doInsert,
        Integer index,
        Instance__c instance,
        Product2 product,
        Integer booked,
        Integer capacity
    ) {
        Session__c session = new Session__c(
            Instance__c = instance.Id,
            BPP_PF_SessionId__c = String.valueOf(index),
            Session_Date__c = Date.today(),
            Session_Product__c = product.Id,
            Start_Time__c = '10:00:00',
            End_Time__c = '12:00:00',
            Booked__c = booked,
            Session_Capacity__c = capacity
        );
        if (doInsert)
            insert session;
        return session;
    }

    public static blng__UsageSummary__c createBookingSummary(Boolean doInsert, OrderItem orderLine) {
        blng__UsageSummary__c bookingSummary = new blng__UsageSummary__c(
            blng__OrderProduct__c = orderLine.Id,
            blng__SummaryStartDate__c = Date.today(),
            blng__SummaryEndDate__c = Date.today().addDays(7),
            blng__MatchingId__c = BOOKING_SUMMARY_MATCHING_ID
        );
        if (doInsert)
            insert bookingSummary;
        return bookingSummary;
    }

    public static Booking__c createBooking(
        Boolean doInsert,
        Instance__c instance,
        Order order,
        Account studentAccount
    ) {
        Booking__c booking = new Booking__c(
            Instance__c = instance.Id,
            Order__c = order.Id,
            Status__c = 'On Hold',
            On_Hold_Reason__c = 'Test Reason'
        );
        if (studentAccount != null) {
            booking.Account__c = studentAccount.Client__c;
            booking.Student__c = studentAccount.Id;
        }
        if (doInsert)
            insert booking;
        return booking;
    }

    public static Booking__c createBookingMB(
        Boolean doInsert,
        Instance__c instance,
        Order order,
        Account studentAccount,
        Id RecordTypeId
    ) {
        Booking__c booking = new Booking__c(
            Instance__c = instance.Id,
            Order__c = order.Id,
            Status__c = 'On Hold',
            On_Hold_Reason__c = 'MB test',
            RecordTypeId = RecordTypeId
        );
        if (studentAccount != null) {
            booking.Account__c = studentAccount.Client__c;
            booking.Student__c = studentAccount.Id;
        }
        if (doInsert)
            insert booking;
        return booking;
    }

    public static blng__Invoice__c createInvoice(Boolean doInsert, Account account) {
        blng__Invoice__c invoice = new blng__Invoice__c(blng__Account__c = account.Id);

        if (doInsert)
            insert invoice;
        return invoice;
    }

    /* START OF - Changes made by David Lovejoy - 07/12 - BPP-8082/9693 */
    public static Authorisation_Token__c createAuthorisationToken(Boolean doInsert) {
        Authorisation_Token__c authorisationToken = new Authorisation_Token__c(
            Access_Token__c = 'eyJhbGciOiJSUzI1NkKidue73dHIkpXVCIsImtpZCI6IlFqazRRVVZCTmtJMU1USkZO',
            Expires_In__c = 1,
            Scope__c = 'create:hub-user enrol:hub-user',
            Authorisation_Type__c = 'BPP API Gateway'
        );
        if (doInsert)
            insert authorisationToken;
        return authorisationToken;
    }
    /* END OF - Changes made by David Lovejoy */

    public static string generateUniqueString() {
        Blob cryptoBlob = Crypto.GenerateAESKey(128);
        String hexBlobString = EncodingUtil.ConvertTohex(cryptoBlob);
        String uniqueString = hexBlobString.SubString(0, 8);

        return uniqueString;
    }

    public static SObject mapAdditionalFields(SObject newRecord, Map<String, Object> additionalFields) {
        for (String fieldName : additionalFields.keySet()) {
            newRecord.put(fieldName, additionalFields.get(fieldName));
        }

        return newRecord;
    }
}
