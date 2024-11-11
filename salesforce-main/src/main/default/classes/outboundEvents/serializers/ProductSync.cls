public without sharing class ProductSync implements Serializer {
    /**
     * A set of product ids to query
     */
    public Set<Id> productIds;

    /**
     * A set of instance ids to query
     */
    public Set<Id> instanceIds;

    /**
     * A set of programme ids to query
     */
    public Set<Id> programmeIds;

    /**
     * Default construct
     */
    public ProductSync() {
        productIds = new Set<Id>();
        instanceIds = new Set<Id>();
        programmeIds = new Set<Id>();
    }

    /**
     * Adds the id from the given record to the relevent set
     * @param record The sObject record to send
     */
    public void addRecord(SObject record) {
        switch on record.getSObjectType().getDescribe().getName() {
            when 'Product2' {
                productIds.add(record.Id);
            }
            when 'Instance__c' {
                instanceIds.add(record.Id);
            }
            when 'Term_Date__c' {
                productIds.add((Id) record.get('Product__c'));
            }
            when 'Programme__c' {
                programmeIds.add(record.Id);
            }
        }
    }

    /**
     * Queries both products and instance where they are set and builds up
     * the payloads to be sent out
     * @return  A list of payloads
     */
    public List<Map<String, Object>> serialize() {
        List<Map<String, Object>> payloads = new List<Map<String, Object>>();

        if (!productIds.isEmpty() || !programmeIds.isEmpty()) {
            payloads.addAll(fetchProductPayloads());
        }

        if (!instanceIds.isEmpty()) {
            payloads.addAll(fetchInstancePayloads());
        }

        return payloads;
    }

    /**
     * Creates payloads for products
     * @return  A list of payloads
     */
    private List<Map<String, Object>> fetchProductPayloads() {
        List<Map<String, Object>> payloads = new List<Map<String, Object>>();

        for (Product2 product : [
            SELECT
                Programme__r.Programme_Id__c,
                Programme__r.Name,
                Instance_Id__c,
                Name,
                Mode__c,
                Location__c,
                Start_Date__c,
                End_Date__c,
                Eligible_For_Automated_Holiday_Letter__c,
                (SELECT Name, Start_Date__c, End_Date__c FROM Term_Dates__r)
            FROM Product2
            WHERE Programme__c != NULL AND (Id IN :productIds OR Programme__c IN :programmeIds)
        ]) {
            Date startDate = product.Start_Date__c;
            String cohortYearFormatted;
            if (startDate != null) {
                Datetime dt = Datetime.newInstance(startDate.year(), startDate.month(), startDate.day());
                cohortYearFormatted = dt.format('MMMM yyyy');
            }

            Map<String, Object> payload = new Map<String, Object>{
                'productId' => product.Programme__r.Programme_Id__c,
                'productName' => product.Programme__r.Name,
                'instanceId' => product.Instance_Id__c,
                'productType' => 'University',
                'curriculum' => product.Name,
                'mode' => product.Mode__c,
                'cohortYear' => cohortYearFormatted,
                'location' => product.Location__c,
                'startDate' => product.Start_Date__c,
                'expectedEndDate' => product.End_Date__c,
                'eligibleForHolidayLetter' => product.Eligible_For_Automated_Holiday_Letter__c
            };

            List<Map<String, Object>> termDatesList = new List<Map<String, Object>>();
            for (Term_Date__c term : product.Term_Dates__r) {
                termDatesList.add(
                    new Map<String, Object>{
                        'name' => term.Name,
                        'startDate' => term.Start_Date__c,
                        'endDate' => term.End_Date__c
                    }
                );
            }
            payload.put('termDates', termDatesList);

            payloads.add(payload);
        }

        return payloads;
    }

    /**
     * Creates payloads for instances
     * @return  A list of payloads
     */
    private List<Map<String, Object>> fetchInstancePayloads() {
        List<Map<String, Object>> payloads = new List<Map<String, Object>>();

        for (Instance__c instance : [
            SELECT Product_Factory_Product_ID__c, Instance_ID__c, Qualification__c
            FROM Instance__c
            WHERE Id IN :instanceIds
        ]) {
            Map<String, Object> payload = new Map<String, Object>{
                'productId' => instance.Product_Factory_Product_ID__c,
                'instanceId' => instance.Instance_ID__c,
                'productName' => instance.Qualification__c,
                'productType' => 'PQ'
            };

            payloads.add(payload);
        }

        return payloads;
    }
}
