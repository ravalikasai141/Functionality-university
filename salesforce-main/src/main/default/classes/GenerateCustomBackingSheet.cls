/**
 *  @who    David Lovejoy <david.lovejoy@bpp.com>
 *  @when   14/10/2021
 *  @what   BPP-17243 - Generate Custom Backing Sheet CSV file for Invoice record
 */
public class GenerateCustomBackingSheet {
    @AuraEnabled  // Method that is called from the generateCustomBackingSheet Lightning component to generate the Custom Backing Sheet and save this as an Attachment on the target Invoice
    public static String generateCustomBackingSheet(Id recordId) {
        system.debug('@generateCustomBackingSheet recordId:' + recordId);
        Set<Id> invoiceIds = new Set<Id>{recordId};
        blng__Invoice__c invoice = getInvoiceWithLines(invoiceIds);
        String csvFinal = generateFinalCsv(invoice);
        return insertAttachment(recordId, invoice.blng__Account__r.Name, csvFinal);
    }

    // Gathers all data from target Invoice (where the 'Generate Custom Backing Sheet' button was pressed), along with all related Invoice Lines & Invoice Backing Sheet records
    private static blng__Invoice__c getInvoiceWithLines(Set<Id> invoiceIds) {
        blng__Invoice__c invoice = [
            SELECT Id, Customer_PO_Number__c, blng__Account__r.Name, blng__Account__r.BPP_Account_Number__c, blng__Account__r.Client__r.Name, blng__Account__r.Client__r.BPP_Account_Number__c, 
            (SELECT blng__Quantity__c, BPP_Level__c, BPP_Qualification__c, BPP_Paper__c, blng__Product__r.Course_Type__c, blng__Product__r.Sitting__c, blng__Product__r.Family, blng__Product__r.Name, blng__Product__r.SBQQ__NonDiscountable__c, blng__Subtotal__c, Total_Discount_Given__c, Tax_Code_Invoice_Print__c, blng__TaxAmount__c, BPP_Discount_Percent__c FROM blng__InvoiceInvoiceLines__r),
            (SELECT Student_Name__c, BPP_Account_Number__c, Cost_Centre__c, Business_Unit__c, Function__c, Booking__r.CreatedDate, Booking__r.Name, Instance__c, Instance__r.Sitting__c, Instance__r.Start_Date__c, Instance__r.Study_Mode__c, Instance__r.Study_Location__r.Name, Instance__r.Qualification__c, Instance__r.Level__c, Instance__r.Paper__c, Instance__r.Course_Type__c FROM Invoiceheader_Details__r)
            FROM blng__Invoice__c WHERE Id IN: invoiceIds
        ];
        return invoice;
    }

    // Retrieves the necessary information in order to group each CSV row by Student > Paper > Course Type. Calls separate method to generate each CSV row
    private static String generateFinalCsv(blng__Invoice__c invoice) {
        String csvHeader = 'Booking Created Date,Booking Name,PO Number,Business Account Name,Business Account Number,Student Name,Student Account Number,Cost Centre,Function,Institute Number,Department Code,Level,Body,Paper,Course Type,Study Type,Sitting,Study Location,Instance Start Date,Study Mode,VAT type,Discount Applied %,Net Amount (TUITION),Net Amount (BPP MATERIALS),Net Amount (INSTITUTE MATERIALS),Net Amount (CBA),Net Amount (POSTAGE),VAT Value,Gross Price \n';
        List<Instance__c> instanceList = getInstanceList(invoice.Invoiceheader_Details__r);
        Map<Id, List<Id>> instanceProductOptionMap = createInstanceProductOptionMap(instanceList);
        Map<String, List<Instance__c>> studentCourseMap = createStudentCourseMap(invoice.Invoiceheader_Details__r, instanceList);
        Set<String> studyTypeSet = createStudyTypeSet(studentCourseMap, invoice.Invoiceheader_Details__r);
        String rows = generateCsvRows(studentCourseMap, invoice, studyTypeSet, instanceProductOptionMap);
        String csvFinal = csvHeader + rows;
        System.debug(csvFinal);
        return csvFinal;
    }

    // Using the information gathered in the previous method, generates each separate row of the CSV file with the requested grouping (Student > Paper > Course Type)
    private static String generateCsvRows(Map<String, List<Instance__c>> studentCourseMap, blng__Invoice__c invoice, Set<String> studyTypeSet, Map<Id, List<Id>> instanceProductOptionMap) {
        String rows = '';
        Map<String, List<Institute_Body__c>> instituteBodyMap = createInstituteBodyMap(invoice.Invoiceheader_Details__r);
        for (String student : studentCourseMap.keyset()) {
            for (Invoiceheader_Details__c invoiceBackingDetail : invoice.Invoiceheader_Details__r) {
                if (invoiceBackingDetail.Student_Name__c == student) {
                    for (Instance__c instance : studentCourseMap.get(student)) {
                        if (instance.id == invoiceBackingDetail.Instance__c) {
                            String instanceStudyType = formatStudyType(instance.Course_Type__c);
                            for (String studyType : studyTypeSet) {
                                if (instanceStudyType == studyType) {
                                    BackingSheetInfo bsi = createBackingSheetInfoObject(invoice, studyType, invoiceBackingDetail, instanceProductOptionMap.get(instance.id), instituteBodyMap.get(invoiceBackingDetail.BPP_Account_Number__c));
                                    rows += createBackingSheetRow(bsi);
                                }
                            }
                        }
                    }
                }
            }
        }
        return rows;
    }

    // Returns a List of Instance records related to each Invoice Backing Detail record
    private static List<Instance__c> getInstanceList(List<Invoiceheader_details__c> invoiceBackingDetailList) {
        Set<Id> instanceIds = new Set<Id>();
        for (Invoiceheader_details__c ibd : invoiceBackingDetailList) {
            instanceIds.add(ibd.Instance__c);
        }
        return new List<Instance__c>([SELECT Id, RecordTypeId, Name, Course_Type__c, Product__c FROM Instance__c WHERE Id IN: instanceIds]);
    }

    // Returns a Map where the key = Instance Id and the values = a List of Product Ids. These Ids are the SBQQ__OptionalSKU__c value from each Product Option (associated to the Product that is linked to the Instance)
    private static Map<Id, List<Id>> createInstanceProductOptionMap(List<Instance__c> instanceList) {
        Map<Id, List<Id>> instanceProductOptionMap = new Map<Id, List<Id>>();
        Set<Id> courseIds = new Set<Id>();
        for (Instance__c instance : instanceList) {
            courseIds.add(instance.Product__c);
        }

        List<Product2> productList = [SELECT Id, (SELECT SBQQ__ConfiguredSKU__c, SBQQ__OptionalSKU__c FROM SBQQ__Options__r) FROM Product2 WHERE Id IN: courseIds];
        for (Instance__c instance : instanceList) {
            List<Id> productOptionIdList = new List<Id>();
            for (Product2 product : productList) {
                for (SBQQ__ProductOption__c prodOption : product.SBQQ__Options__r) {
                    if (instance.Product__c == prodOption.SBQQ__ConfiguredSKU__c) {
                        productOptionIdList.add(prodOption.SBQQ__OptionalSKU__c);
                    }
                }
            }
            instanceProductOptionMap.put(instance.Id, productOptionIdList);
        }
        return instanceProductOptionMap;
    }

    // Returns a Map where the key = Student Name and the values = a List of the Instances that the Student has been booked onto
    private static Map<String, List<Instance__c>> createStudentCourseMap(List<Invoiceheader_details__c> invoiceBackingDetailList, List<Instance__c> instanceList) {
        Set<String> students = new Set<String>();
        Map<String, List<Instance__c>> studentCourseMap = new Map<String, List<Instance__c>>();
        for (Invoiceheader_details__c ibd : invoiceBackingDetailList) {
            students.add(ibd.Student_Name__c);
        }

        for (String student : students) {
            List<Instance__c> relatedInstances = new List<Instance__c>();
            for (Invoiceheader_details__c ibd : invoiceBackingDetailList) {
                for (Instance__c instance : instanceList) {
                    if (ibd.Student_Name__c == student && ibd.Instance__c == instance.Id) {
                        relatedInstances.add(instance);
                    }
                }
            }
            studentCourseMap.put(student, relatedInstances);
        }
        return studentCourseMap;
    }

    // Returns a Set of Strings taken from the formatted Course_Type__c value from each related Instance
    private static Set<String> createStudyTypeSet(Map<String, List<Instance__c>> studentCourseMap, List<Invoiceheader_details__c> invoiceBackingDetailList) {
        Set<String> studyTypeSet = new Set<String>();
        for (String student : studentCourseMap.keyset()) {
            for (Invoiceheader_Details__c invoiceBackingDetail : invoiceBackingDetailList) {
                if (invoiceBackingDetail.Student_Name__c == student) {
                    for (Instance__c instance : studentCourseMap.get(student)) {
                        String studyType = formatStudyType(instance.Course_Type__c);
                        studyTypeSet.add(studyType);
                    }
                }
            }
        }
        return studyTypeSet;
    }

    // Returns a Map of Institute Body record that relate to a Student to pass the correct Institute Number for each Student to the Backing Sheet
    private static Map<String, List<Institute_Body__c>> createInstituteBodyMap(List<Invoiceheader_details__c> invoiceBackingDetailList) {
        Map<String, List<Institute_Body__c>> instituteBodyMap = new Map<String, List<Institute_Body__c>>();
        Set<String> studentAccountNumbers = new Set<String>();
        for (Invoiceheader_Details__c invoiceBackingDetail : invoiceBackingDetailList) {
            studentAccountNumbers.add(invoiceBackingDetail.BPP_Account_Number__c);
        }

        List<Institute_Body__c> instituteBodyList = [SELECT Student__r.BPP_Account_Number__c, Institute_Body__c, Institute_Number__c FROM Institute_Body__c WHERE Student__r.BPP_Account_Number__c IN: studentAccountNumbers];
        for (String studentAccountNumber : studentAccountNumbers) {
            List<Institute_Body__c> instituteBodyPerStudent = new List<Institute_Body__c>();
            for (Institute_Body__c instituteBody : instituteBodyList) {
                if (studentAccountNumber == instituteBody.Student__r.BPP_Account_Number__c) {
                    instituteBodyPerStudent.add(instituteBody);
                }
            }
            instituteBodyMap.put(studentAccountNumber, instituteBodyPerStudent);
        }
        return instituteBodyMap;
    }

    // Returns the formatted String value of the provided Course Type value. Typically, the Course Type value is of this format: "xxx - xxx". This method returns the first part of the Course Type (before the hypen), where possible
    private static String formatStudyType(String courseType) {
        if (courseType == null) {
            courseType = 'Computer Based Assessment';
        } else {
            if (courseType.contains(' -')) {
                List<String> parts = courseType.split(' -');
                return parts[0];
            }
        }
        return courseType;
    }

    // Generates a BackingSheetInfo object, populating each variable with the relevant information needed to populate each column of the CSV file
    private static BackingSheetInfo createBackingSheetInfoObject(blng__Invoice__c invoice, String studyType, Invoiceheader_Details__c invoiceBackingDetail, List<Id> productOptionIdList, List<Institute_Body__c> instituteBodyList) {
        Set<Id> processedProductIds = new Set<Id>();
        Instance__c ibdInstance = invoiceBackingDetail.Instance__r;
        blng__InvoiceLine__c chosenInvoiceLine = new blng__InvoiceLine__c();
        for (blng__InvoiceLine__c il : invoice.blng__InvoiceInvoiceLines__r) {
            if ((il.BPP_Qualification__c == ibdInstance.Qualification__c && il.BPP_Paper__c == ibdInstance.Paper__c && il.BPP_Level__c == ibdInstance.Level__c) || 
                (ibdInstance.Qualification__c == null && ibdInstance.Paper__c == null && ibdInstance.Level__c == null && ibdInstance.Sitting__c == il.blng__Product__r.Sitting__c)) {
                chosenInvoiceLine = il;
                break;
            }
        }
        
        String instituteNumber;
        if (instituteBodyList.size() > 0) {
            for (Institute_Body__c ib : instituteBodyList) {
                if (chosenInvoiceLine.BPP_Qualification__c != null && ib.Institute_Body__c == chosenInvoiceLine.BPP_Qualification__c) {
                    instituteNumber = ib.Institute_Number__c;
                }
            }
        }
        
        BackingSheetInfo bsi = new BackingSheetInfo();
        bsi.bookingCreatedDate = (invoiceBackingDetail.Booking__r.CreatedDate != null ? String.valueOf(invoiceBackingDetail.Booking__r.CreatedDate) : 'N/A');
        bsi.bookingName = (invoiceBackingDetail.Booking__r.Name != null ? invoiceBackingDetail.Booking__r.Name : 'N/A'); // Booking Name
        bsi.poNumber = (invoice.Customer_PO_Number__c != null ? invoice.Customer_PO_Number__c : 'N/A'); // PO Number
        bsi.clientName = (invoice.blng__Account__r.Client__c != null ? invoice.blng__Account__r.Client__r.Name : invoice.blng__Account__r.Name); // Business Account Name
        bsi.clientNumber = (invoice.blng__Account__r.Client__c != null ? invoice.blng__Account__r.Client__r.BPP_Account_Number__c : invoice.blng__Account__r.BPP_Account_Number__c); // Business Account Account Number
        bsi.studentName = invoiceBackingDetail.Student_Name__c; // Student Name
        bsi.studentNumber = (invoiceBackingDetail.BPP_Account_Number__c != null ? invoiceBackingDetail.BPP_Account_Number__c : 'N/A'); // Student Account Number
        bsi.costCentre = (invoiceBackingDetail.Cost_Centre__c != null ? invoiceBackingDetail.Cost_Centre__c : 'N/A'); // Cost Centre
        bsi.function = (invoiceBackingDetail.Function__c != null ? invoiceBackingDetail.Function__c : 'N/A'); // Function
        bsi.departmentCode = (invoiceBackingDetail.Business_Unit__c != null ? invoiceBackingDetail.Business_Unit__c : 'N/A'); // Business Unit
        bsi.instituteNumber = (instituteNumber != null ? instituteNumber : 'N/A'); // Institute Number
        bsi.level = (chosenInvoiceLine.BPP_Level__c != null ? chosenInvoiceLine.BPP_Level__c : 'N/A'); // Level
        bsi.body = (chosenInvoiceLine.BPP_Qualification__c  != null ? chosenInvoiceLine.BPP_Qualification__c  : 'N/A'); // Body
        bsi.paper = (chosenInvoiceLine.BPP_Paper__c != null ? chosenInvoiceLine.BPP_Paper__c : 'N/A'); // Paper
        bsi.courseType = (ibdInstance.Course_Type__c != null ? ibdInstance.Course_Type__c : studyType); // Course Type
        bsi.studyTypeRow = studyType; // Study Type
        bsi.sitting = (chosenInvoiceLine.blng__Product__r.Sitting__c != null ? chosenInvoiceLine.blng__Product__r.Sitting__c : 'N/A'); // Sitting
        bsi.studyLocation = (ibdInstance.Study_Location__r.Name != null ? ibdInstance.Study_Location__r.Name : 'N/A'); // Study Location Name
        bsi.instanceStartDate = (ibdInstance.Start_Date__c != null ? String.valueOf(ibdInstance.Start_Date__c) : 'N/A'); // Instance Start Date
        bsi.studyMode = (ibdInstance.Study_Mode__c != null ? ibdInstance.Study_Mode__c : 'N/A'); // Study Mode
        bsi.vatType = (chosenInvoiceLine.Tax_Code_Invoice_Print__c != null ? chosenInvoiceLine.Tax_Code_Invoice_Print__c : 'N/A'); // VAT type
        bsi.discountApplied = (chosenInvoiceLine.BPP_Discount_Percent__c != null && chosenInvoiceLine.BPP_Discount_Percent__c > 0 ? (chosenInvoiceLine.BPP_Discount_Percent__c * 100) : 0); // Discount Applied
        for (blng__InvoiceLine__c indivInvoiceLine : invoice.blng__InvoiceInvoiceLines__r) {
            if (productOptionIdList.size() > 0) {
                for (Id productOptionId : productOptionIdList) {
                    if (!processedProductIds.contains(productOptionId) && indivInvoiceLine.blng__Product__c == productOptionId) {
                        bsi.tuitionPrice += (indivInvoiceLine.blng__Product__r.Family.contains('Session') ? indivInvoiceLine.blng__Subtotal__c / indivInvoiceLine.blng__Quantity__c : 0); // Net Amount (TUITION)
                        bsi.bppMaterialPrice += (indivInvoiceLine.blng__Product__r.Family == 'Materials' && !indivInvoiceLine.blng__Product__r.SBQQ__NonDiscountable__c ? indivInvoiceLine.blng__Subtotal__c / indivInvoiceLine.blng__Quantity__c : 0); // Net Amount (BPP MATERIALS)
                        bsi.instituteMaterialPrice += (indivInvoiceLine.blng__Product__r.Family == 'Materials' && indivInvoiceLine.blng__Product__r.SBQQ__NonDiscountable__c ? indivInvoiceLine.blng__Subtotal__c / indivInvoiceLine.blng__Quantity__c : 0); // Net Amount (INSTITUTE MATERIALS)
                        bsi.cbaPrice += (indivInvoiceLine.blng__Product__r.Family == 'Exam' ? indivInvoiceLine.blng__Subtotal__c / indivInvoiceLine.blng__Quantity__c : 0); // Net Amount (CBA)
                        bsi.vatValue += (indivInvoiceLine.blng__TaxAmount__c != null ? indivInvoiceLine.blng__TaxAmount__c / indivInvoiceLine.blng__Quantity__c : 0); // VAT Value
                        processedProductIds.add(productOptionId);
                    } else {
                        continue;
                    }
                }
                bsi.postagePrice += (indivInvoiceLine.blng__Product__r.Name != null && indivInvoiceLine.blng__Product__r.Name.contains('Postage') && indivInvoiceLine.blng__Subtotal__c != null ? indivInvoiceLine.blng__Subtotal__c : 0); // Net Amount (POSTAGE)
            } else {
                bsi.cbaPrice += (indivInvoiceLine.blng__Product__r.Family == 'Exam' ? indivInvoiceLine.blng__Subtotal__c / indivInvoiceLine.blng__Quantity__c : 0); // Net Amount (CBA)
            }
        }
        bsi.grossPrice = (bsi.tuitionPrice + bsi.bppMaterialPrice + bsi.instituteMaterialPrice + bsi.cbaPrice + bsi.postagePrice + bsi.vatValue); // Gross Price
        return bsi;
    }

    // Using the object created in the previous method, this method returns a String made up of each of the BackingSheetInfo's variables. This String functions as a single row in the CSV file
    private static String createBackingSheetRow(BackingSheetInfo bsi) {
        String row = '';
        row += bsi.bookingCreatedDate + ',';
        row += bsi.bookingName + ',';
        row += bsi.poNumber + ',';
        row += bsi.clientName + ',';
        row += bsi.clientNumber + ',';
        row += bsi.studentName + ',';
        row += bsi.studentNumber + ',';
        row += bsi.costCentre + ',';
        row += bsi.function + ',';
        row += bsi.instituteNumber + ',';
        row += bsi.departmentCode + ',';
        row += bsi.level + ',';
        row += bsi.body + ',';
        row += bsi.paper + ',';
        row += bsi.courseType + ',';
        row += bsi.studyTypeRow + ',';
        row += bsi.sitting + ',';
        row += bsi.studyLocation + ',';
        row += bsi.instanceStartDate + ',';
        row += bsi.studyMode + ',';
        row += bsi.vatType + ',';
        row += bsi.discountApplied + ',';
        row += bsi.tuitionPrice + ',';
        row += bsi.bppMaterialPrice + ',';
        row += bsi.instituteMaterialPrice + ',';
        row += bsi.cbaPrice + ',';
        row += bsi.postagePrice + ',';
        row += bsi.vatValue + ',';
        row += bsi.grossPrice +' \n';
        return row;
    }

    // After the creation of the final CSV file, this method inserts the CSV as an Attachment against the target Invoice record
    private static String insertAttachment(Id invoiceId, String invoiceAccountName, String csvFinal) {
        Attachment attachment = new Attachment();
        attachment.Body = Blob.valueOf(csvFinal);
        attachment.Name = String.valueOf('Backing Sheet for '+ invoiceAccountName +' - '+ System.now() +'.csv');
        attachment.ParentId = invoiceId;

        Database.SaveResult sr = Database.insert(attachment);
        String result = (sr.isSuccess() ? 'Success!' : 'Something went wrong: ' + sr.getId() + ' - ' + sr.getErrors());
        return result;
    }

    // Object used to map variables to CSV columns
    class BackingSheetInfo {
        String bookingCreatedDate, bookingName, poNumber, clientName, clientNumber, studentName, studentNumber, costCentre, function, instituteNumber, departmentCode, level, body, paper, courseType, studyTypeRow, sitting, studyLocation, instanceStartDate, studyMode, vatType;
        Decimal discountApplied = 0, tuitionPrice = 0, bppMaterialPrice = 0, instituteMaterialPrice = 0, cbaPrice = 0, postagePrice = 0, vatValue = 0, grossPrice = 0;
    }
}