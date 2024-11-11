/**
 *  @who    David Lovejoy <david.lovejoy@bpp.com>
 *  @when   18/11/2021
 *  @what   BPP-15454 - Generate Customer Statement CSV file for Account Snapshot record
 */
public class GenerateCustomerStatement {
    private static List<blng__Invoice__c> invoiceList = new List<blng__Invoice__c>();
    private static List<blng__Payment__c> paymentList = new List<blng__Payment__c>();
    private static List<blng__CreditNote__c> creditNoteList = new List<blng__CreditNote__c>();
    private static List<blng__DebitNote__c> debitNoteList = new List<blng__DebitNote__c>();
    private static String legalEntityName, vatRegNumber;
    private static String pqLegalEntity = 'BPP Professional Education Ltd';
    private static String lmLegalEntity = 'BPP Learning Media Ltd';

    @AuraEnabled  // Method that is called from the generateCustomerStatement Lightning component to generate the Customer Statement and save this as an Attachment on the target Account
    public static String generateCustomerStatement(Id recordId) {
        system.debug('@generateCustomerStatement recordId:' + recordId);
        Set<Id> accountIds = new Set<Id>{recordId};
        Account account = getAccountWithBalanceSnapshots(accountIds);
        String csvFinal = generateFinalCsv(account);
        return (csvFinal != null ? insertAttachment(recordId, account.Name, csvFinal) : 'Something went wrong');
    }

    // Gathers all data from target Account (where the 'Generate Customer Statement' button was pressed), along with the latest related Account Balance Snapshot record
    private static Account getAccountWithBalanceSnapshots(Set<Id> accountIds) {
        Account account = [
            SELECT Id, Name, BPP_Account_Number__c, 
            (SELECT Id, Name, blng__SnapshotDate__c, blng__TotalInvoiceAmount__c, blng__AccountBalance__c, blng__InvoiceAgingBucket1__c, blng__InvoiceAgingBucket2__c, blng__InvoiceAgingBucket3__c, 
            blng__InvoiceAgingBucket4__c, blng__InvoiceAgingBucket5__c, blng__InvoiceAgingBucket6__c, blng__InvoiceAgingBucket7__c, blng__InvoiceAgingBucket8__c, blng__InvoiceAgingBucket9__c, 
            blng__InvoiceAgingBucket10__c, blng__Invoices__c, blng__UnappliedPayments__c, X4C_Unapplied_Invoice_List__c, blng__UnappliedPaymentAmount__c, blng__UnappliedCreditNotes__c, 
            X4C_Unapplied_Credit_Note_List__c, blng__UnappliedDebitNoteAmount__c, blng__UnappliedDebitNotes__c, X4C_Unapplied_Debit_Note_List__c FROM blng__AccountBalanceSnapshots__r 
            ORDER BY CreatedDate DESC LIMIT 1),
            (SELECT Id, Street_1__c, Street_2__c, City__c, Zip_Postal_Code__c FROM Addresses__r WHERE Type__c = 'Billing') 
            FROM Account WHERE Id IN: accountIds
        ];
        return account;
    }

    // Retrieves the necessary information in order to create the Customer Statement. Calls separate method to generate each CSV row
    private static String generateFinalCsv(Account account) {
        if (account.blng__AccountBalanceSnapshots__r.size() == 0) {
            return null;
        } else {
            blng__AccountBalanceSnapshot__c abs = account.blng__AccountBalanceSnapshots__r.get(0);
            if (abs.blng__Invoices__c != null) {
                invoiceList = getInvoiceList(abs.blng__Invoices__c);
                legalEntityName = getLegalEntityName(invoiceList);
                vatRegNumber = (legalEntityName == 'BPP Professional Education Ltd' ? 'GB 466451629' : 'GB 115102475');
            }
            if (abs.blng__UnappliedPayments__c != null) {
                paymentList = getPaymentList(abs.blng__UnappliedPayments__c);
            }
            if (abs.blng__UnappliedCreditNotes__c != null) {
                creditNoteList = getCreditNoteList(abs.blng__UnappliedCreditNotes__c);
            }
            if (abs.blng__UnappliedDebitNotes__c != null) {
                debitNoteList = getDebitNoteList(abs.blng__UnappliedDebitNotes__c);
            }

            String csvHeader = createHeader(account, legalEntityName, vatRegNumber);
            String rows = generateCsvRows(invoiceList, paymentList, creditNoteList, debitNoteList);
            String csvFinal = csvHeader + rows;
            System.debug(csvFinal);
            return csvFinal;
        }
    }

    // Generates the CSV Header for the Customer Statement
    private static String createHeader(Account account, String legalEntityName, String vatRegNumber) {
        Address__c clientAddress = (account.Addresses__r.size() == 1 ? account.Addresses__r.get(0) : null);
        String addressLine1 = (clientAddress != null ? clientAddress.Street_1__c : null);
        String addressLine2 = (clientAddress != null ? clientAddress.Street_2__c : null);
        String city = (clientAddress != null ? clientAddress.City__c : null);
        String postCode = (clientAddress != null ? clientAddress.Zip_Postal_Code__c : null);

        String csvHeader = (legalEntityName != null ? 'BPP Company,'+ legalEntityName +',,,,,Customer Name,'+ account.Name +'\n' : 'BPP Company,'+ pqLegalEntity +',,,,,Customer Name,'+ account.Name +'\n');
        csvHeader += (addressLine1 != null ? 'BPP Address,BPP House,,,,,Customer Address,'+ addressLine1 +'\n' : 'BPP Address,BPP House\n');
        csvHeader += (addressLine2 != null ? ',142-144 Uxbridge Road,,,,,,'+ addressLine2 +'\n' : ',142-144 Uxbridge Road\n');
        csvHeader += (city != null ? ',London,,,,,,'+ city +'\n' : ',London\n');
        csvHeader += (postCode != null ? ',W12 8AA,,,,,,'+ postCode +'\n\n' : ',W12 8AA\n\n');
        csvHeader += 'Vat Reg Number,'+ (vatRegNumber != null ? vatRegNumber : 'GB 466451629') +',,,,,Customer Account No,'+ account.BPP_Account_Number__c +'\n';
        csvHeader += 'Currency,GBP,,,,,Statement Date,'+ System.today().format() +'\n\n';
        csvHeader += 'Record Number,Date,Due Date,Reference,Total (with Tax),Debit,Credit,Balance\n';

        return csvHeader;
    }

    // Using the information gathered in the previous method, generates each separate row of the CSV file
    private static String generateCsvRows(List<blng__Invoice__c> invoiceList, List<blng__Payment__c> paymentList, List<blng__CreditNote__c> creditNoteList, List<blng__DebitNote__c> debitNoteList){
        String rows = '';
        Decimal total = 0;
        for (blng__Invoice__c invoice : invoiceList) {
            rows += invoice.Name + ',' + invoice.blng__InvoiceDate__c.format() + ',' + (invoice.blng__DueDate__c != null ? invoice.blng__DueDate__c.format() : 'N/A') + ',' + (invoice.Customer_PO_Number__c != null ? invoice.Customer_PO_Number__c : 'N/A') + ',' + invoice.blng__TotalAmount__c + ',' + (invoice.blng__DebitPayments__c == null || invoice.blng__Debits__c == null ? 0 : invoice.blng__DebitPayments__c + invoice.blng__Debits__c) + ',' + (invoice.blng__Payments__c == null || invoice.blng__Credits__c == null ? 0 : invoice.blng__Payments__c + invoice.blng__Credits__c) + ',' + invoice.blng__Balance__c + '\n';
            total += invoice.blng__Balance__c;
        }
        for (blng__DebitNote__c debitNote : debitNoteList) {
            rows += debitNote.Name + ',' + debitNote.blng__DebitNoteDate__c.format() + ',N/A,Unallocated Debit Note,' + debitNote.blng__TotalAmount__c + ',' + debitNote.blng__TotalAvailableForAllocation__c + ','+ 0 +',' + debitNote.blng__Balance__c + '\n';
            total += debitNote.blng__Balance__c;
        }
        for (blng__Payment__c payment : paymentList) {
            Decimal allocations = (payment.blng__Allocations__c == null ? 0 : payment.blng__Allocations__c);
            Decimal unallocations = (payment.blng__Unallocations__c == null ? 0 : payment.blng__Unallocations__c);
            rows += payment.Name + ',' + payment.blng__PaymentDate__c.format() + ',N/A,Unallocated Payment,' + (payment.blng__Amount__c == null ? 0 : payment.blng__Amount__c * -1) + ',' + (allocations - unallocations) + ','+ 0 +',' + (payment.blng__Balance__c == null ? 0 : payment.blng__Balance__c * -1) + '\n';
            total += (payment.blng__Balance__c * -1);
        }
        for (blng__CreditNote__c creditNote : creditNoteList) {
            Decimal netAllocation = (creditNote.blng__NetAllocations__c == null ? 0 : creditNote.blng__NetAllocations__c);
            Decimal refunds = (creditNote.blng__Refunds__c == null ? 0 : creditNote.blng__Refunds__c);
            rows += creditNote.Name + ',' + creditNote.blng__CreditNoteDate__c.format() + ',N/A,Unallocated Credit Note,' + (creditNote.blng__TotalAmount__c == null ? 0 : creditNote.blng__TotalAmount__c * -1) + ',' + (netAllocation + refunds) + ','+ 0 +',' + (creditNote.blng__Balance__c == null ? 0 : creditNote.blng__Balance__c * -1) + '\n';
            total += (creditNote.blng__Balance__c * -1);
        }
        rows += ',,,,,,Total,' + total + '';
        return rows;
    }

    // Retrieves the unpaid Invoice records listed on the Account Balance Snapshot
    private static List<blng__Invoice__c> getInvoiceList(String invoices) {
        Set<String> individualInvoiceNamesFormat = formatRecordNames(invoices);
        invoiceList = [SELECT Id, Name, blng__InvoiceDate__c, blng__DueDate__c, Customer_PO_Number__c, blng__TotalAmount__c, blng__DebitPayments__c, blng__Debits__c, 
                    blng__Payments__c, blng__Credits__c, blng__Balance__c, BPP_Legal_Entity__c, BPP_Legal_Entity__r.Name FROM blng__Invoice__c WHERE Name IN: individualInvoiceNamesFormat ORDER BY CreatedDate];
        return invoiceList;
    }

    // Gets the "main" Legal Entity. If the Legal Entity = 'BPP Professional Education Ltd' on ANY of the Invoices, it returns this value, otherwise it returns 'BPP Learning Media Ltd'
    private static String getLegalEntityName(List<blng__Invoice__c> invoiceList) {
        Set<String> legalEntityNames = new Set<String>();
        for (blng__Invoice__c invoice : invoiceList) {
            legalEntityNames.add(invoice.BPP_Legal_Entity__r.Name);
        }
        return (legalEntityNames.contains(pqLegalEntity) ? pqLegalEntity : lmLegalEntity);
    }

    // Retrieves the unapplied Payments records listed on the Account Balance Snapshot
    private static List<blng__Payment__c> getPaymentList(String payments) {
        Set<String> individualPaymentNamesFormat = formatRecordNames(payments);
        paymentList = [SELECT Id, Name, blng__PaymentDate__c, blng__Amount__c, blng__Balance__c,  blng__UnallocatedfromDebitNoteLines__c, blng__UnallocatedfromInvoiceLines__c, 
                    blng__UnallocatedfromInvoices__c, blng__Allocations__c, blng__Unallocations__c, blng__LegalEntity__c FROM blng__Payment__c WHERE Name IN: individualPaymentNamesFormat ORDER BY CreatedDate];
        return paymentList;
    }

    // Retrieves the unapplied Credit Note records listed on the Account Balance Snapshot
    private static List<blng__CreditNote__c> getCreditNoteList(String creditNotes) {
        Set<String> individualCreditNoteNamesFormat = formatRecordNames(creditNotes);
        creditNoteList = [SELECT Id, Name, blng__CreditNoteDate__c, blng__TotalAmount__c, blng__Debits__c, blng__Balance__c, blng__NetAllocations__c, blng__Refunds__c FROM blng__CreditNote__c WHERE Name IN: individualCreditNoteNamesFormat 
                    ORDER BY CreatedDate];
        return creditNoteList;
    }

    // Retrieves the unapplied Debit Note records listed on the Account Balance Snapshot
    private static List<blng__DebitNote__c> getDebitNoteList(String debitNotes) {
        Set<String> individualDebitNoteNamesFormat = formatRecordNames(debitNotes);
        debitNoteList = [SELECT Id, Name, blng__DebitNoteDate__c, blng__TotalAmount__c, blng__TotalAvailableForAllocation__c, blng__Balance__c FROM blng__DebitNote__c WHERE Name IN: individualDebitNoteNamesFormat 
                    ORDER BY CreatedDate];
        return debitNoteList;
    }

    // Formats the Long Text Area Name field and returns the record Names in a Set
    private static Set<String> formatRecordNames(String nameList) {
        Set<String> individualNamesFormatted = new Set<String>();
        List<String> individualNameList = nameList.split(',');
        for (String name : individualNameList) {
            name = name.substringBefore(' ');
            individualNamesFormatted.add(name);
        }
        return individualNamesFormatted;
    }

    // After the creation of the final CSV file, this method inserts the CSV as an Attachment against the target Account record
    private static String insertAttachment(Id accountId, String accountName, String csvFinal) {
        Attachment attachment = new Attachment();
        attachment.Body = Blob.valueOf(csvFinal);
        attachment.Name = String.valueOf('Customer Statement for '+ accountName +' - '+ System.now() +'.csv');
        attachment.ParentId = accountId;

        Database.SaveResult sr = Database.insert(attachment);
        String result = (sr.isSuccess() ? 'Success!' : 'Something went wrong: ' + sr.getId() + ' - ' + sr.getErrors());
        return result;
    }
}