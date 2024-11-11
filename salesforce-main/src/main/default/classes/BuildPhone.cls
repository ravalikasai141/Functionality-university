public with sharing class BuildPhone {
    public static String BuildPhoneXml(String pNumber, String pType, Boolean isPrimary) {
        String xml = '';
        if (pNumber != null && pNumber != '') {
            
            String strippedNumber = pNumber.replaceAll('\\D','');
            String areaCode = '';
            String phoneNumber = '';
            String extension = '';
            if (strippedNumber.length() == 10) {
                areaCode = strippedNumber.substring(0, 3);
                phoneNumber = strippedNumber.substring(3);
            }
            else if (strippedNumber.length() > 10) {
                areaCode = strippedNumber.substring(0, 3);
                phoneNumber = strippedNumber.substring(3, 10);
                extension = strippedNumber.substring(10);
            }
            if (areaCode != '') {
                xml += '<prof:phone><phon:type>' + pType + '</phon:type><phon:areaCode>' + areaCode + '</phon:areaCode>';
                xml += '<phon:phoneNumber>' + phoneNumber + '</phon:phoneNumber>';
                if (extension != '') {
                    xml += '<phon:extension>' + extension + '</phon:extension>';    
                }
                if (isPrimary){
                    xml += '<phon:isPrimary>true</phon:isPrimary>';
                }
                else{
                    xml += '<phon:isPrimary>false</phon:isPrimary>';
                }
                xml += '</prof:phone>';
            }else{
                xml += '<prof:phone><phon:type>' + pType + '</phon:type><phon:areaCode>-</phon:areaCode>';
                xml += '<phon:phoneNumber>-</phon:phoneNumber>';
                xml += '<phon:countryCode>' + pNumber + '</phon:countryCode>';  
                if (isPrimary){
                    xml += '<phon:isPrimary>true</phon:isPrimary>';
                }
                else{
                    xml += '<phon:isPrimary>false</phon:isPrimary>';
                }
                xml += '</prof:phone>';                     
            }
        }
        return xml;
    }
    
    public static CreateCompanyProfile.PhoneType BuildPhoneTypeDTO(String pNumber, String pType, Boolean isPrimary) {
        CreateCompanyProfile.PhoneType pt = new CreateCompanyProfile.PhoneType();
        if (pNumber != null && pNumber != '') {
            String strippedNumber = pNumber.replaceAll('\\D','');
            String areaCode = '';
            String phoneNumber = '';
            String extension = '';
            if (strippedNumber.length() == 10) {
                areaCode = strippedNumber.substring(0, 3);
                phoneNumber = strippedNumber.substring(3);
            }
            else if (strippedNumber.length() > 10) {
                areaCode = strippedNumber.substring(0, 3);
                phoneNumber = strippedNumber.substring(3, 10);
                extension = strippedNumber.substring(10);
            }
            if (areaCode != '') {
                pt.type = pType;
                pt.areaCode = areaCode;
                pt.phoneNumber = phoneNumber;
                if(extension != ''){
                    pt.extension = extension;
                }
                pt.isPrimary = isPrimary;
            }else{
                pt.type = pType;
                pt.countryCode = pNumber;
                pt.isPrimary = isPrimary;
            }
        }
        return pt;
    }
    
    public static ProfileIntegrations_v2.inst_PhoneType InstBuildPhoneTypeDTO(String pNumber, String pType, Boolean isPrimary) {
        ProfileIntegrations_v2.inst_PhoneType pt = new ProfileIntegrations_v2.inst_PhoneType();
        if (pNumber != null && pNumber != '') {
            String strippedNumber = pNumber.replaceAll('\\D','');
            String areaCode = '';
            String phoneNumber = '';
            String extension = '';
            if (strippedNumber.length() == 10) {
                areaCode = strippedNumber.substring(0, 3);
                phoneNumber = strippedNumber.substring(3);
            }
            else if (strippedNumber.length() > 10) {
                areaCode = strippedNumber.substring(0, 3);
                phoneNumber = strippedNumber.substring(3, 10);
                extension = strippedNumber.substring(10);
            }
            if (areaCode != '') {
                pt.type = pType;
                pt.areaCode = areaCode;
                pt.phoneNumber = phoneNumber;
                if(extension != ''){
                    pt.extension = extension;
                }
                pt.isPrimary = isPrimary;
            }else{
                pt.type = pType;
                pt.countryCode = pNumber;
                pt.isPrimary = isPrimary;
            }
        }
        return pt;
    }
    
    public static ProfileIntegrations_v2.find_PhoneType findBuildPhoneTypeDTO(String pNumber, String pType) {
        ProfileIntegrations_v2.find_PhoneType pt = new ProfileIntegrations_v2.find_PhoneType();
        if (pNumber != null && pNumber != '') {
            String strippedNumber = pNumber.replaceAll('\\D','');
            String areaCode = '';
            String phoneNumber = '';
            //String extension = '';
            if (strippedNumber.length() == 10) {
                areaCode = strippedNumber.substring(0, 3);
                phoneNumber = strippedNumber.substring(3);
            }
            else if (strippedNumber.length() > 10) {
                areaCode = strippedNumber.substring(0, 3);
                phoneNumber = strippedNumber.substring(3, 10);
                //extension = strippedNumber.substring(10);
            }
            if (areaCode != '') {
                pt.type = pType;
                pt.areaCode = areaCode;
                pt.phoneNumber = phoneNumber;
                //if(extension != ''){
                //    pt.extension = extension;
                //}
                //pt.isPrimary = isPrimary;
            }else{
                pt.type = pType;
                pt.countryCode = pNumber;
                //pt.isPrimary = isPrimary;
            }
        }
        return pt;
    } 
}