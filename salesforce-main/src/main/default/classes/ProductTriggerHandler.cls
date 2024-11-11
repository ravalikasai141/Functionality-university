/*
* @who   David Lovejoy <davidlovejoy@bpp.com>
* @what  Handler class for ProductTrigger
* @when  09/04/2021
*/
public with sharing class ProductTriggerHandler {
    public static void handleBeforeInsert (List<Product2> products) {
        if (products.size() == 1) {
            Product2 product = products.get(0);
            String productFactoryId = product.BPP_ProductFactoryID__c;
            String family = product.Family;
            Boolean isStandalone = product.Standalone_Material__c;
            
            List<Product2> matchProduct = [SELECT Id FROM Product2 WHERE BPP_ProductFactoryID__c != NULL AND BPP_ProductFactoryID__c =: productFactoryId AND Family =: family AND Standalone_Material__c =: isStandalone];
            
            if (matchProduct.size() > 0) {
                product.addError('We are unable to insert this Product. A duplicate Product Factory Id has been found on the following record: ' + matchProduct.get(0).Id + '.');
            }
        }
    }
}