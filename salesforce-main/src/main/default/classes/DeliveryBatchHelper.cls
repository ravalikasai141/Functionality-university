/**
 *  @who    David Lovejoy <davidlovejoy@bpp.com>
 *  @when   24/06/2021
 *  @what   Helper class for DeliveryUpdateBatch and EDeliveryUpdateBatch classes
 */
public with sharing class DeliveryBatchHelper {
    public static List<String> updateDeliveryRecords(List<Delivery__c> deliveryList) {
        List<String> saveErrors = new List<String>();

        List<Database.SaveResult> resultsList = Database.update(deliveryList, false);
        for(Integer i = 0; i <= resultsList.size() - 1; i++){
            Database.SaveResult sr = resultsList.get(i);
            Delivery__c currentDelivery = deliveryList.get(i);

            if (!sr.isSuccess()) {
                for(Database.Error err : sr.getErrors()) {
                    saveErrors.add('Delivery Id: ' + currentDelivery.Id.to15() + ', Error Message: ' + err.getStatusCode() + ': ' + err.getMessage() + '<br/>');
                }
            }
        }
        return saveErrors;
    }

    public static void sendFailedDeliveryUpdateEmail(String deliveryType, List<String> saveErrors) {
        String userEmailAddressesFromLabel = Label.DeliveryUpdateUsers;
        String[] toAddresses = userEmailAddressesFromLabel.split(';');

        Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
        message.setToAddresses(toAddresses);

        String subject = deliveryType + ' Update';
        String body = 'To whom it may concern, <br/><br/>' + 'Please find attached ' + deliveryType + ' records that are Ready for Fulfilment.<br/><br/>';
        if (saveErrors != null) {
            subject += ' - with errors';
            body += 'There has been an issue updating the following Delivery records: <br/><br/>';
            for (String error : saveErrors) {
                body += error + '<br/>';
            }
            body += '<br/><br/>';
        }
        body += '<br/><br/>Kind Regards, <br/><br/> Salesforce Admin';
        message.setHtmlBody(body);
        message.subject = subject;

        Messaging.EmailFileAttachment csvAttachment = createDeliveryCSV(deliveryType);
        if (csvAttachment.getBody() != null) {
            message.setFileAttachments(new Messaging.EmailFileAttachment[]{csvAttachment});
        }

        Messaging.SingleEmailMessage[] messages = new List<Messaging.SingleEmailMessage>{message};
        System.debug('messages: ' + messages);
        if (!Test.isRunningTest()) {
            Messaging.SendEmailResult[] results = Messaging.sendEmail(messages);
        }
    }

    public static Messaging.EmailFileAttachment createDeliveryCSV(String deliveryType) {
        String wildcardDeliveryType = '%' + deliveryType + '%';
        DateTime previousFireTime = (Test.isRunningTest() ? System.now().addDays(-1) : [SELECT PreviousFireTime FROM CronTrigger WHERE CronJobDetail.Name LIKE: wildcardDeliveryType].PreviousFireTime);
        DateTime currentTime = System.now();
        
        String getFields = 'SELECT Fulfilment_Id__c, Name, Recipient_Name__c, Email__c, Phone__c, Consolidated_Address__c, City__c, Postal_Code__c, Country__c, Country__r.Name, Country_Code__c, Requested_Delivery_Date__c, BPP_Shipping_Method__c, Material_Product_Code__c, Quantity__c, EORI_Number__c, Stock_Site__r.Name, Id, BPP_Delivery_Line_Total_Price__c, Order_Product__r.ListPrice, Order_Product__r.BPP_Discount_Amount__c, Order_Product__r.BPP_Discount_Percent__c, BPP_Division__c, BPP_Cost_Center__c, BPP_Project__c, BPP_Product__c, Account__r.Name FROM Delivery__c';
        String whereClause = (Test.isRunningTest() ? 
        ' WHERE LastModifiedDate >=: previousFireTime AND LastModifiedDate <=: currentTime AND Delivery_Status__c = \'Sent for Fulfilment\'' :
        ' WHERE LastModifiedBy.UserRole.Name = \'System Administrator\' AND LastModifiedDate >=: previousFireTime AND LastModifiedDate <=: currentTime AND Delivery_Status__c = \'Sent for Fulfilment\' AND RecordType.Name =: deliveryType LIMIT 49000');
        String query = getFields + whereClause;
        List<Delivery__c> recentlyUpdatedDeliveryList = Database.query(query);

        String csvHeader = (deliveryType == 'Physical Delivery' ? 'Fulfilment Id,Delivery: Delivery Id,Delivery Id,Recipient Name,Email,Phone,Consolidated Address,City,Postal Code,Country,Country Code,Requested Delivery Date,Shipping Method,Material Product Code,Quantity,EORI Number,Stock Site,Delivery: ID,Delivery Line Total Price,Order Product: List Price,Order Product: Discount Amount,Order Product: Discount %,Division,Cost Center,Project,Product\n' : 'Fulfilment Id,Delivery: Delivery Id,Delivery: ID,Account,Email,Material Product Code\n');
        String csvFinal;
        String rows = '';
        for (Delivery__c delivery : recentlyUpdatedDeliveryList) {
            if (deliveryType == 'Physical Delivery') {
                rows += delivery.Fulfilment_Id__c + ',';
                rows += delivery.Name + ',';
                rows += delivery.Name.remove('DEL-') + ',';
                rows += (delivery.Recipient_Name__c != null ? delivery.Recipient_Name__c: '') + ',';
                rows += (delivery.Email__c != null ? delivery.Email__c : '') + ',';
                rows += (delivery.Phone__c != null ? delivery.Phone__c : '') + ',';
                rows += (delivery.Consolidated_Address__c != null ? delivery.Consolidated_Address__c: '') + ',';
                rows += (delivery.City__c != null ? delivery.City__c : '') + ',';
                rows += (delivery.Postal_Code__c != null ? delivery.Postal_Code__c : '') + ',';
                rows += (delivery.Country__c != null ? delivery.Country__r.Name : '') + ',';
                rows += (delivery.Country_Code__c != null ? delivery.Country_Code__c : '') + ',';
                rows += (delivery.Requested_Delivery_Date__c != null ? delivery.Requested_Delivery_Date__c.format() : '') + ',';
                rows += delivery.BPP_Shipping_Method__c + ',';
                rows += (delivery.Material_Product_Code__c != null ? delivery.Material_Product_Code__c : '') + ',';
                rows += delivery.Quantity__c + ',';
                rows += (delivery.EORI_Number__c != null ? delivery.EORI_Number__c : '') + ',';
                rows += delivery.Stock_Site__r.Name + ',';
                rows += delivery.Id + ',';
                rows += delivery.BPP_Delivery_Line_Total_Price__c + ',';
                rows += delivery.Order_Product__r.ListPrice + ',';
                rows += delivery.Order_Product__r.BPP_Discount_Amount__c + ',';
                rows += delivery.Order_Product__r.BPP_Discount_Percent__c + ',';
                rows += (delivery.BPP_Division__c != null ? delivery.BPP_Division__c : '') + ',';
                rows += (delivery.BPP_Cost_Center__c != null ? delivery.BPP_Cost_Center__c : '') + ',';
                rows += (delivery.BPP_Project__c != null ? delivery.BPP_Project__c : '') + ',';
                rows += (delivery.BPP_Product__c != null ? delivery.BPP_Product__c : '') + '\n';
            } else {
                rows += delivery.Fulfilment_Id__c + ',';
                rows += delivery.Name + ',';
                rows += delivery.Id + ',';
                rows += delivery.Account__r.Name + ',';
                rows += (delivery.Email__c != null ? delivery.Email__c : '') + ',';
                rows += (delivery.Material_Product_Code__c != null ? delivery.Material_Product_Code__c : '') + '\n';
            }
        }
        csvFinal = (rows != '' ? csvHeader + rows : null);

        Messaging.EmailFileAttachment csvAttachment = new Messaging.EmailFileAttachment();
        if (csvFinal != null) {
            String csvName = (deliveryType == 'Physical Delivery' ? 'Deliveries - Ready for Fulfilment.csv' : 'E-Deliveries - Ready for Fulfilment.csv');
            csvAttachment.setFileName(csvName);
            csvAttachment.setBody(Blob.valueOf(csvFinal));
        }
        return csvAttachment;
    }
}