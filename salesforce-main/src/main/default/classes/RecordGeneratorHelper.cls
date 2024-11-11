public class RecordGeneratorHelper {
    public static CsvReader retrieveStaticResource(String sResourceName) {
        StaticResource sr = [SELECT Id, Body FROM StaticResource WHERE Name =: sResourceName LIMIT 1];
        String srBody = sr.Body.toString();
        return new CsvReader(srBody, '|');
    }

    public static Map<String, String> createFieldTypeMap(String sObjectType, List<String> csvRows) {
        Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
        Schema.SObjectType objSchema = schemaMap.get(sObjectType);
        Map<String, Schema.SObjectField> fieldMap = objSchema.getDescribe().fields.getMap();

        Map<String, String> fieldTypeMap = new Map<String, String>();
        for (Integer i = 0; i < csvRows.size()-1; i++) {
            fieldTypeMap.put(csvRows.get(i), String.valueOf(fieldMap.get(csvRows.get(i)).getDescribe().getType()));
        }
        return fieldTypeMap;
    }

    public static Map<String, Id> populateMapFromQuery(String objectType, Map<String,Id> recordMap) {
        recordMap = recordMap != null ? recordMap : new Map<String, Id>();
        String query = 'SELECT Id, Name FROM ' + objectType;
        for (SObject obj : Database.query(query)) {
            recordMap.put((String)obj.get('Name'), obj.Id);
        }
        return recordMap;
    }

    public static void createRecordsFromCSV(String sObjectType, String resourceName, Map<String, Id> recordMap) {
        List<SObject> sObjectList = new List<SObject>();

        CsvReader csv = RecordGeneratorHelper.retrieveStaticResource(resourceName);
        Map<String, String> fieldTypeMap = RecordGeneratorHelper.createFieldTypeMap(sObjectType, csv.readLine());
        List<String> csvRows = csv.readLine();

        while (csvRows != null) {
            Integer i = 0;
            SObject obj = Schema.getGlobalDescribe().get(sObjectType).newSObject();
            for (String str : fieldTypeMap.keySet()) {
                String csvRow = csvRows.get(i);
                // System.debug(str + ' : ' + csvRow + ' ('+ fieldTypeMap.get(str) +')');
                switch on fieldTypeMap.get(str) {
                    when 'STRING', 'PICKLIST', 'TEXTAREA', 'PHONE', 'EMAIL' {
                        obj.put(str, csvRow);
                    }
                    when 'BOOLEAN' {
                        obj.put(str, cleanBoolean(csvRow));
                    }
                    when 'DOUBLE', 'PERCENT', 'CURRENCY' {
                        obj.put(str, Decimal.valueOf(csvRow));
                    } 
                    /*when 'DATE' {
                        obj.put(str, Date.valueOf(csvRow));
                    }*/
                    when 'REFERENCE' {
                        obj.put(str, recordMap.get(csvRow));
                    }
                }
                i++;
            }
            sObjectList.add(obj);
            csvRows = csv.readLine();
        }
        insert sObjectList;
    }

    public static Boolean cleanBoolean(String value) {
        return value == 'true' ? true : false;
    }
}