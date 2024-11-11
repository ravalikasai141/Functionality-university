@RestResource(urlMapping='/learners/')
global with sharing class LearnerService {
    global class Response {
        public Response() {
        }
        global String response { get; set; }
        global String accountId { get; set; }
        global String contactId { get; set; }

        public Response(String response, String accountId, String contactId) {
            this.response = response;
            this.accountId = accountId;
            this.contactId = contactId;
        }
    }

    private static List<Address__c> addressList = new List<Address__c>();

    public class RequestWrapper {
        public String careExperienceStatusCode;
        public String countryOfResidence;
        public String countryOfBirth;
        public String countryOfPermanentAddress;
        public String dateEnteredUK;
        public String dateOfBirth;
        public String disabilities;
        public String disabilityFurtherDetails;
        public String ethnicityCode;
        public String firstName;
        public String gender;
        public String genderSameAsBirth;
        public String homePhone;
        public Boolean marketingEmailOptIn;
        public Boolean marketingPostOptIn;
        public Boolean marketingSmsOptIn;
        public String mobilePhone;
        public String nationality;
        public String parentsHaveHigherEducation;
        public String passportExpiryDate;
        public String passportIssueDate;
        public String passportNumber;
        public String passportPlaceOfIssue;
        public String personalEmail;
        public String preferredFirstName;
        public String previousSurname;
        public String recordSource;
        public String religionCode;
        public String scottishCandidateNumber;
        public String secondaryNationality;
        public String sexualOrientationCode;
        public String studentType;
        public String surname;
        public String title;
        public String ucasNumber;
        public String uln;
        public String mailingLine1;
        public String mailingLine2;
        public String mailingCity;
        public String mailingCounty;
        public String mailingPostcode;
        public String mailingCountryCode;
        public String homeLine1;
        public String homeLine2;
        public String homeCity;
        public String homeCounty;
        public String homePostcode;
        public String homeCountryCode;
    }

    @HttpPost
    global static Response doPost() {
        try {
            Blob body = RestContext.request.requestBody;
            RequestWrapper rw = (RequestWrapper) JSON.deserialize(body.toString(), RequestWrapper.class);
            System.debug(rw);
            cleanUp(rw);

            String result;
            String accountId = lookForAccountId(rw);
            if (accountId != null) {
                result = updateAccount(accountId, rw);
                if (result != null && result.startsWith('001')) {
                    handleAddressLogic(true, accountId, rw);
                    Id contactId = [SELECT Id FROM Contact WHERE AccountId = :result].Id;
                    return new Response('LearnerService Success: Account - ' + result + ' updated', result, contactId);
                } else {
                    return new Response('LearnerService Account Update Error: ' + result, null, null);
                }
            }

            result = createAccount(rw);
            if (result != null && result.startsWith('001')) {
                handleAddressLogic(false, result, rw);
                Id contactId = [SELECT Id FROM Contact WHERE AccountId = :result].Id;
                return new Response('LearnerService Success: Account - ' + result + ' created', result, contactId);
            } else {
                return new Response('LearnerService Account Create Error: ' + result, null, null);
            }
        } catch (Exception e) {
            return new Response('LearnerService Error: [' + e.getLineNumber() + '] ' + e.getMessage(), null, null);
        }
    }

    private static void cleanUp(RequestWrapper rw) {
        rw.careExperienceStatusCode = DedupeHelper.verifyPostInput(rw.careExperienceStatusCode);
        rw.countryOfBirth = DedupeHelper.verifyPostInput(rw.countryOfBirth);
        rw.countryOfPermanentAddress = DedupeHelper.verifyPostInput(rw.countryOfPermanentAddress);
        rw.countryOfResidence = DedupeHelper.verifyPostInput(rw.countryOfResidence);
        rw.dateEnteredUK = DedupeHelper.verifyPostInput(rw.dateEnteredUK);
        rw.dateOfBirth = DedupeHelper.verifyPostInput(rw.dateOfBirth);
        rw.disabilities = DedupeHelper.verifyPostInput(rw.disabilities);
        rw.disabilityFurtherDetails = DedupeHelper.verifyPostInput(rw.disabilityFurtherDetails);
        rw.ethnicityCode = DedupeHelper.verifyPostInput(rw.ethnicityCode);
        rw.firstName = DedupeHelper.verifyPostInput(rw.firstName);
        rw.gender = DedupeHelper.verifyPostInput(rw.gender);
        rw.genderSameAsBirth = DedupeHelper.verifyPostInput(rw.genderSameAsBirth);
        rw.homePhone = DedupeHelper.verifyPostInput(rw.homePhone);
        rw.mobilePhone = DedupeHelper.verifyPostInput(rw.mobilePhone);
        rw.nationality = DedupeHelper.verifyPostInput(rw.nationality);
        rw.parentsHaveHigherEducation = DedupeHelper.verifyPostInput(rw.parentsHaveHigherEducation);
        rw.passportExpiryDate = DedupeHelper.verifyPostInput(rw.passportExpiryDate);
        rw.passportIssueDate = DedupeHelper.verifyPostInput(rw.passportIssueDate);
        rw.passportNumber = DedupeHelper.verifyPostInput(rw.passportNumber);
        rw.passportPlaceOfIssue = DedupeHelper.verifyPostInput(rw.passportPlaceOfIssue);
        rw.personalEmail = DedupeHelper.verifyPostInput(rw.personalEmail);
        rw.preferredFirstName = DedupeHelper.verifyPostInput(rw.preferredFirstName);
        rw.previousSurname = DedupeHelper.verifyPostInput(rw.previousSurname);
        rw.recordSource = DedupeHelper.verifyPostInput(rw.recordSource);
        rw.religionCode = DedupeHelper.verifyPostInput(rw.religionCode);
        rw.scottishCandidateNumber = DedupeHelper.verifyPostInput(rw.scottishCandidateNumber);
        rw.secondaryNationality = DedupeHelper.verifyPostInput(rw.secondaryNationality);
        rw.sexualOrientationCode = DedupeHelper.verifyPostInput(rw.sexualOrientationCode);
        rw.surname = DedupeHelper.verifyPostInput(rw.surname);
        rw.title = DedupeHelper.verifyPostInput(rw.title);
        rw.ucasNumber = DedupeHelper.verifyPostInput(rw.ucasNumber);
        rw.uln = DedupeHelper.verifyPostInput(rw.uln);
        rw.mailingLine1 = DedupeHelper.verifyPostInput(rw.mailingLine1);
        rw.mailingLine2 = DedupeHelper.verifyPostInput(rw.mailingLine2);
        rw.mailingCity = DedupeHelper.verifyPostInput(rw.mailingCity);
        rw.mailingCounty = DedupeHelper.verifyPostInput(rw.mailingCounty);
        rw.mailingPostcode = DedupeHelper.verifyPostInput(rw.mailingPostcode);
        rw.mailingCountryCode = DedupeHelper.verifyPostInput(rw.mailingCountryCode);
        rw.homeLine1 = DedupeHelper.verifyPostInput(rw.homeLine1);
        rw.homeLine2 = DedupeHelper.verifyPostInput(rw.homeLine2);
        rw.homeCity = DedupeHelper.verifyPostInput(rw.homeCity);
        rw.homeCounty = DedupeHelper.verifyPostInput(rw.homeCounty);
        rw.homePostcode = DedupeHelper.verifyPostInput(rw.homePostcode);
        rw.homeCountryCode = DedupeHelper.verifyPostInput(rw.homeCountryCode);

        rw.careExperienceStatusCode = (rw.careExperienceStatusCode != null
            ? setDropdownValueFromCode(rw.careExperienceStatusCode, 'Care_Experience_Status__c', 'Account')
            : null);
        rw.disabilities = (rw.disabilities != null
            ? setDropdownValueFromCode(rw.disabilities, 'SFDC_Disability_Type_Code_Select__pc', 'Account')
            : null);
        rw.ethnicityCode = (rw.ethnicityCode != null
            ? setDropdownValueFromCode(rw.ethnicityCode, 'SFDC_Ethnic_Code_Select__pc', 'Account')
            : null);
        rw.genderSameAsBirth = (rw.genderSameAsBirth != null
            ? setDropdownValueFromCode(rw.genderSameAsBirth, 'Gender_Identity__pc', 'Account')
            : null);
        rw.parentsHaveHigherEducation = (rw.parentsHaveHigherEducation != null
            ? setDropdownValueFromCode(
                  rw.parentsHaveHigherEducation,
                  'Parents_have_HE_Quals__c',
                  'Account'
              )
            : null);
        rw.religionCode = (rw.religionCode != null
            ? setDropdownValueFromCode(rw.religionCode, 'Religion__pc', 'Account')
            : null);
        rw.sexualOrientationCode = (rw.sexualOrientationCode != null
            ? setDropdownValueFromCode(rw.sexualOrientationCode, 'Sexual_Orientation__pc', 'Account')
            : null);

        if (rw.marketingSmsOptIn == null) {
            rw.marketingSmsOptIn = false;
        }
        if (rw.marketingPostOptIn == null) {
            rw.marketingPostOptIn = false;
        }
        if (rw.marketingEmailOptIn == null) {
            rw.marketingEmailOptIn = false;
        }

        rw.studentType = setStudentType(rw.nationality);
        rw.countryOfBirth = populateCountryData(rw.countryOfBirth, true);
        rw.countryOfPermanentAddress = populateCountryData(rw.countryOfPermanentAddress, true);
        rw.nationality = populateCountryData(rw.nationality, true);
        rw.homeCountryCode = populateCountryData(rw.homeCountryCode, true);
        rw.mailingCountryCode = populateCountryData(rw.mailingCountryCode, true);
        rw.countryOfResidence = populateCountryData(rw.countryOfResidence, false);
        rw.secondaryNationality = populateCountryData(rw.secondaryNationality, false);
    }

    private static String populateCountryData(String str, Boolean requiresId) {
        if (str != null) {
            List<Country_List__c> countryList = [
                SELECT Id, Name
                FROM Country_List__c
                WHERE Country_Code_2__c = :str
                LIMIT 1
            ];
            if (countryList.size() > 0) {
                if (requiresId) {
                    return countryList.get(0).Id;
                } else {
                    return countryList.get(0).Name;
                }
            }
        }
        return null;
    }

    private static String lookForAccountId(RequestWrapper rw) {
        DedupeAccount.CheckAccount account = new DedupeAccount.CheckAccount();
        account.firstname = rw.firstName;
        account.lastname = rw.surname;
        account.email = rw.personalEmail;
        account.phone = firstNonNull(rw.mobilePhone, rw.homePhone);
        if (rw.dateOfBirth != null) {
            account.dob = rw.dateOfBirth;
        }
        DedupeAccount.Response checkAccountExists = DedupeAccount.doPost(account);

        if (String.valueOf(checkAccountExists).contains('001')) {
            return DedupeHelper.formatResponseId(String.valueOf(checkAccountExists));
        }
        return null;
    }

    private static void handleAddressLogic(Boolean accountFound, Id accountId, RequestWrapper rw) {
        if (accountFound) {
            Address__c homeAddress;
            if (rw.homeLine1 != null && rw.homePostcode != null) {
                homeAddress = lookForAddress(accountId, rw.homeLine1, rw.homePostcode, 'Home');
                if (homeAddress != null) {
                    updateAddressValues(homeAddress, rw, 'Home');
                } else {
                    if (rw.homeCountryCode != null) {
                        initialiseNewAddress(accountId, rw, 'Home');
                    }
                }
            }

            Address__c mailingAddress;
            if (rw.mailingLine1 != null && rw.mailingPostcode != null) {
                mailingAddress = lookForAddress(accountId, rw.mailingLine1, rw.mailingPostcode, 'Mailing');
                if (mailingAddress != null) {
                    updateAddressValues(mailingAddress, rw, 'Mailing');
                } else {
                    if (rw.mailingCountryCode != null) {
                        initialiseNewAddress(accountId, rw, 'Mailing');
                    }
                }
            }
        } else {
            if (rw.homeLine1 != null && rw.homePostcode != null && rw.homeCountryCode != null) {
                initialiseNewAddress(accountId, rw, 'Home');
            }
            if (rw.mailingLine1 != null && rw.mailingPostcode != null && rw.mailingCountryCode != null) {
                initialiseNewAddress(accountId, rw, 'Mailing');
            }
        }

        if (addressList.size() > 0) {
            upsertAddressRecords(addressList);
        }
    }

    private static Address__c lookForAddress(Id studentId, String addressLine1, String postCode, String addressType) {
        if (addressLine1 != null && postCode != null && addressType != null) {
            List<Address__c> addressList = [
                SELECT
                    Id,
                    City__c,
                    County_State__c,
                    Lookup_Country__c,
                    Street_1__c,
                    Street_2__c,
                    Student__c,
                    Type__c,
                    Zip_Postal_Code__c
                FROM Address__c
                WHERE
                    Student__c = :studentId
                    AND ((Street_1__c = :addressLine1
                    AND Zip_Postal_Code__c = :postCode
                    AND Type__c = :addressType)
                    OR Type__c = :addressType)
                LIMIT 1
            ];
            if (addressList.size() > 0) {
                return addressList.get(0);
            }
        }
        return null;
    }

    private static void updateAddressValues(Address__c address, RequestWrapper rw, String addressType) {
        if (addressType == 'Home') {
            if (DedupeHelper.updateFieldDecision(address.City__c, rw.homeCity)) {
                address.City__c = rw.homeCity;
            }
            if (DedupeHelper.updateFieldDecision(address.County_State__c, rw.homeCounty)) {
                address.County_State__c = rw.homeCounty;
            }
            if (DedupeHelper.updateFieldDecision(address.Lookup_Country__c, rw.homeCountryCode)) {
                address.Lookup_Country__c = rw.homeCountryCode;
            }
            if (DedupeHelper.updateFieldDecision(address.Street_1__c, rw.homeLine1)) {
                address.Street_1__c = rw.homeLine1;
            }
            if (DedupeHelper.updateFieldDecision(address.Street_2__c, rw.homeLine2)) {
                address.Street_2__c = rw.homeLine2;
            }
            if (DedupeHelper.updateFieldDecision(address.Zip_Postal_Code__c, rw.homePostcode)) {
                address.Zip_Postal_Code__c = rw.homePostcode;
            }
        } else if (addressType == 'Mailing') {
            if (DedupeHelper.updateFieldDecision(address.City__c, rw.mailingCity)) {
                address.City__c = rw.mailingCity;
            }
            if (DedupeHelper.updateFieldDecision(address.County_State__c, rw.mailingCounty)) {
                address.County_State__c = rw.mailingCounty;
            }
            if (DedupeHelper.updateFieldDecision(address.Lookup_Country__c, rw.mailingCountryCode)) {
                address.Lookup_Country__c = rw.mailingCountryCode;
            }
            if (DedupeHelper.updateFieldDecision(address.Street_1__c, rw.mailingLine1)) {
                address.Street_1__c = rw.mailingLine1;
            }
            if (DedupeHelper.updateFieldDecision(address.Street_2__c, rw.mailingLine2)) {
                address.Street_2__c = rw.mailingLine2;
            }
            if (DedupeHelper.updateFieldDecision(address.Zip_Postal_Code__c, rw.mailingPostcode)) {
                address.Zip_Postal_Code__c = rw.mailingPostcode;
            }
        }
        addressList.add(address);
    }

    private static void initialiseNewAddress(Id studentId, RequestWrapper rw, String addressType) {
        Address__c address = new Address__c();
        address.Active__c = true;
        address.City__c = (addressType == 'Home' ? rw.homeCity : rw.mailingCity);
        address.County_State__c = (addressType == 'Home' ? rw.homeCounty : rw.mailingCounty);
        address.Lookup_Country__c = (addressType == 'Home' ? rw.homeCountryCode : rw.mailingCountryCode);
        address.Street_1__c = (addressType == 'Home' ? rw.homeLine1 : rw.mailingLine1);
        address.Street_2__c = (addressType == 'Home' ? rw.homeLine2 : rw.mailingLine2);
        address.Zip_Postal_Code__c = (addressType == 'Home' ? rw.homePostcode : rw.mailingPostcode);
        address.Student__c = studentId;
        address.Type__c = addressType;
        addressList.add(address);
    }

    private static void upsertAddressRecords(List<Address__c> addressList) {
        try {
            for (Address__c address : addressList) {
                System.debug('Address: ' + address);
            }
            upsert addressList;
        } catch (Exception e) {
            System.debug('LearnerService - Address Upsert Error: [' + e.getLineNumber() + '] ' + e.getMessage());
        }
    }

    private static String updateAccount(Id id, RequestWrapper rw) {
        String result;
        String fields = 'Id, BPP_Scottish_Candidate_Number_SCN__c, Care_Experience_Status__c, Country_of_Birth__pc, Country_of_Permanent_Address__c, Country_of_Residence__pc, Criminal_Conviction__pc, Disability_Needs__pc, Email_Opt_In__pc, FirstName, Gender_Identity__pc, Gender__pc, LastName, Legal_Entity__c, Parents_have_HE_Quals__c, Passport_Exp_Date__pc, Passport_Issue_Date__pc, Passport_Number__pc, Passport_Place_of_Issue__pc, PersonBirthdate, PersonContactId, PersonHomePhone, PersonMobilePhone, Personal_Email__pc, Post_Opt_In__pc, Preferred_First_Name__pc, Previous_Surname__pc, Primary_Nationality__pc, Record_Source__pc, Religion__pc, SFDC_Disability_Type_Code_Select__pc, SFDC_Ethnic_Code_Select__pc, SMS_Opt_In__pc, Salutation, Secondary_Nationality__pc, Sexual_Orientation__pc, SFDC_Country_of_Birth__pc, Special_Circumstances__c, Special_Needs_Disability_Support__pc, Student_Type__pc, UCAS_Number__pc, UK_First_Entry_Date__pc, ULN__pc';
        String query = 'SELECT ' + fields + ' FROM Account WHERE Id = :id';

        Account account = Database.query(String.escapeSingleQuotes(query));
        if (account != null) {
            if (DedupeHelper.updateFieldDecision(account.Salutation, rw.title)) {
                account.Salutation = rw.title;
            }
            if (DedupeHelper.updateFieldDecision(account.FirstName, rw.firstName)) {
                account.FirstName = rw.firstName;
            }
            if (DedupeHelper.updateFieldDecision(account.LastName, rw.surname)) {
                account.LastName = rw.surname;
            }
            if (DedupeHelper.updateFieldDecision(String.valueOf(account.PersonBirthdate), rw.dateOfBirth)) {
                account.PersonBirthdate = Date.valueOf(rw.dateOfBirth);
            }
            if (
                DedupeHelper.updateFieldDecision(
                    account.BPP_Scottish_Candidate_Number_SCN__c,
                    rw.scottishCandidateNumber
                )
            ) {
                account.BPP_Scottish_Candidate_Number_SCN__c = rw.scottishCandidateNumber;
            }
            if (DedupeHelper.updateFieldDecision(account.Care_Experience_Status__c, rw.careExperienceStatusCode)) {
                account.Care_Experience_Status__c = rw.careExperienceStatusCode;
            }
            if (DedupeHelper.updateFieldDecision(account.Country_of_Residence__pc, rw.countryOfResidence)) {
                account.Country_of_Residence__pc = rw.countryOfResidence;
            }
            if (DedupeHelper.updateFieldDecision(account.Gender__pc, rw.gender)) {
                account.Gender__pc = rw.gender;
            }
            if (DedupeHelper.updateFieldDecision(account.Gender_Identity__pc, rw.genderSameAsBirth)) {
                account.Gender_Identity__pc = rw.genderSameAsBirth;
            }
            if (DedupeHelper.updateFieldDecision(account.Parents_have_HE_Quals__c, rw.parentsHaveHigherEducation)) {
                account.Parents_have_HE_Quals__c = rw.parentsHaveHigherEducation;
            }
            if (
                DedupeHelper.updateFieldDecision(String.valueOf(account.Passport_Exp_Date__pc), rw.passportExpiryDate)
            ) {
                account.Passport_Exp_Date__pc = Date.valueOf(rw.passportExpiryDate);
            }
            if (
                DedupeHelper.updateFieldDecision(String.valueOf(account.Passport_Issue_Date__pc), rw.passportIssueDate)
            ) {
                account.Passport_Issue_Date__pc = Date.valueOf(rw.passportIssueDate);
            }
            if (DedupeHelper.updateFieldDecision(account.Passport_Number__pc, rw.passportNumber)) {
                account.Passport_Number__pc = rw.passportNumber;
            }
            if (DedupeHelper.updateFieldDecision(account.Passport_Place_of_Issue__pc, rw.passportPlaceOfIssue)) {
                account.Passport_Place_of_Issue__pc = rw.passportPlaceOfIssue;
            }
            if (DedupeHelper.updateFieldDecision(account.Preferred_First_Name__pc, rw.preferredFirstName)) {
                account.Preferred_First_Name__pc = rw.preferredFirstName;
            }
            if (DedupeHelper.updateFieldDecision(account.Primary_Nationality__pc, rw.nationality)) {
                account.Primary_Nationality__pc = rw.nationality;
            }
            if (DedupeHelper.updateFieldDecision(account.Previous_Surname__pc, rw.previousSurname)) {
                account.Previous_Surname__pc = rw.previousSurname;
            }
            if (DedupeHelper.updateFieldDecision(account.Religion__pc, rw.religionCode)) {
                account.Religion__pc = rw.religionCode;
            }
            if (DedupeHelper.updateFieldDecision(account.Secondary_Nationality__pc, rw.secondaryNationality)) {
                account.Secondary_Nationality__pc = rw.secondaryNationality;
            }
            if (DedupeHelper.updateFieldDecision(account.Sexual_Orientation__pc, rw.sexualOrientationCode)) {
                account.Sexual_Orientation__pc = rw.sexualOrientationCode;
            }
            if (DedupeHelper.updateFieldDecision(account.SFDC_Country_of_Birth__pc, rw.countryOfBirth)) {
                account.SFDC_Country_of_Birth__pc = rw.countryOfBirth;
            }
            if (
                DedupeHelper.updateFieldDecision(account.Country_of_Permanent_Address__c, rw.countryOfPermanentAddress)
            ) {
                account.Country_of_Permanent_Address__c = rw.countryOfPermanentAddress;
            }
            if (DedupeHelper.updateFieldDecision(account.SFDC_Disability_Type_Code_Select__pc, rw.disabilities)) {
                account.SFDC_Disability_Type_Code_Select__pc = rw.disabilities;
            }
            if (DedupeHelper.updateFieldDecision(account.SFDC_Ethnic_Code_Select__pc, rw.ethnicityCode)) {
                account.SFDC_Ethnic_Code_Select__pc = rw.ethnicityCode;
            }
            if (DedupeHelper.updateFieldDecision(account.Special_Circumstances__c, rw.disabilityFurtherDetails)) {
                account.Special_Circumstances__c = rw.disabilityFurtherDetails;
            }
            if (DedupeHelper.updateFieldDecision(String.valueOf(account.UK_First_Entry_Date__pc), rw.dateEnteredUK)) {
                account.UK_First_Entry_Date__pc = Date.valueOf(rw.dateEnteredUK);
            }
            if (DedupeHelper.updateFieldDecision(account.ULN__pc, rw.uln)) {
                account.ULN__pc = rw.uln;
            }
            if (DedupeHelper.updateFieldDecision(account.Personal_Email__pc, rw.personalEmail)) {
                account.Personal_Email__pc = rw.personalEmail;
            }
            if (DedupeHelper.updateFieldDecision(account.PersonMobilePhone, rw.mobilePhone)) {
                account.PersonMobilePhone = rw.mobilePhone;
            }
            if (DedupeHelper.updateFieldDecision(account.PersonHomePhone, rw.homePhone)) {
                account.PersonHomePhone = rw.homePhone;
            }
            if (DedupeHelper.updateFieldDecision(account.Student_Type__pc, rw.studentType)) {
                account.Student_Type__pc = rw.studentType;
            }
            if (account.Legal_Entity__c == null) {
                account.Legal_Entity__c = 'UC~COL';
            }
            if (account.PersonMobilePhone != null) {
                account.Preferred_Phone__pc = 'Mobile';
            } else if (account.PersonHomePhone != null) {
                account.Preferred_Phone__pc = 'Home';
            }
            if (account.Email_Opt_In__pc != rw.marketingEmailOptIn) {
                account.Email_Opt_In__pc = rw.marketingEmailOptIn;
            }
            if (account.Post_Opt_In__pc != rw.marketingPostOptIn) {
                account.Post_Opt_In__pc = rw.marketingPostOptIn;
            }
            if (account.SMS_Opt_In__pc != rw.marketingSmsOptIn) {
                account.SMS_Opt_In__pc = rw.marketingSmsOptIn;
            }
            if (rw.ucasNumber != null && rw.recordSource != null) {
                if (rw.recordSource == 'UCAS' && account.UCAS_Number__pc != rw.ucasNumber) {
                    account.UCAS_Number__pc = rw.ucasNumber;
                }
                if (account.Record_Source__pc != 'UCAS') {
                    account.Record_Source__pc = 'UCAS';
                }
            }

            try {
                Database.DMLOptions dbDML = new Database.DMLOptions();
                dbDML.DuplicateRuleHeader.allowSave = true;
                Database.update(account, dbDML);
                result = account.Id;
            } catch (Exception e) {
                result = 'LearnerService - Account Update Error: [' + e.getLineNumber() + '] ' + e.getMessage();
            }
        }
        return result;
    }

    private static String createAccount(RequestWrapper rw) {
        String result;
        Account account = new Account();
        if (rw.firstName != null && rw.surname != null && rw.personalEmail != null) {
            account.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
                .get('Student_Account')
                .getRecordTypeId();
            account.Salutation = rw.title;
            account.FirstName = rw.firstName;
            account.LastName = rw.surname;
            account.PersonBirthdate = (rw.dateOfBirth != null ? Date.valueOf(rw.dateOfBirth) : null);
            account.Personal_Email__pc = rw.personalEmail;
            account.Preferred_Email__pc = (account.Personal_Email__pc != null ? 'Personal' : null);
            account.PersonMobilePhone = rw.mobilePhone;
            account.PersonHomePhone = rw.homePhone;

            if (account.PersonMobilePhone != null) {
                account.Preferred_Phone__pc = 'Mobile';
            } else if (account.PersonHomePhone != null) {
                account.Preferred_Phone__pc = 'Home';
            }

            account.Record_Source__pc = rw.recordSource;
            account.BPP_Scottish_Candidate_Number_SCN__c = rw.scottishCandidateNumber;
            account.Care_Experience_Status__c = rw.careExperienceStatusCode;
            account.Country_of_Permanent_Address__c = rw.countryOfPermanentAddress;
            account.Country_of_Residence__pc = rw.countryOfResidence;
            account.Email_Opt_In__pc = rw.marketingEmailOptIn;
            account.Gender__pc = rw.gender;
            account.Gender_Identity__pc = rw.genderSameAsBirth;
            account.Legal_Entity__c = 'UC~COL';
            account.Parents_have_HE_Quals__c = rw.parentsHaveHigherEducation;
            account.Passport_Exp_Date__pc = (rw.passportExpiryDate != null
                ? Date.valueOf(rw.passportExpiryDate)
                : null);
            account.Passport_Issue_Date__pc = (rw.passportIssueDate != null
                ? Date.valueOf(rw.passportIssueDate)
                : null);
            account.Passport_Number__pc = rw.passportNumber;
            account.Passport_Place_of_Issue__pc = rw.passportPlaceOfIssue;
            account.Post_Opt_In__pc = rw.marketingPostOptIn;
            account.Preferred_First_Name__pc = rw.preferredFirstName;
            account.Previous_Surname__pc = rw.previousSurname;
            account.Primary_Nationality__pc = rw.nationality;
            account.Religion__pc = rw.religionCode;
            account.Secondary_Nationality__pc = rw.secondaryNationality;
            account.Sexual_Orientation__pc = rw.sexualOrientationCode;
            account.SFDC_Country_of_Birth__pc = rw.countryOfBirth;
            account.SFDC_Disability_Type_Code_Select__pc = rw.disabilities;
            account.SFDC_Ethnic_Code_Select__pc = rw.ethnicityCode;
            account.SMS_Opt_In__pc = rw.marketingSmsOptIn;
            account.Special_Circumstances__c = rw.disabilityFurtherDetails;
            account.UCAS_Number__pc = rw.ucasNumber;
            account.UK_First_Entry_Date__pc = (rw.dateEnteredUK != null ? Date.valueOf(rw.dateEnteredUK) : null);
            account.ULN__pc = rw.uln;
            account.Student_Type__pc = rw.studentType;
            account.OwnerId = (account.Student_Type__pc == 'International'
                ? AssignmentUsers__c.getInstance().Default_International_Owner__c
                : AssignmentUsers__c.getInstance().Default_Admissions_Owner__c);

            // These ones are currently Booleans but the Salesforce fields are picklists. Needs clarification
            //account.Criminal_Conviction__pc = rw.hasCriminalConvictions;

            try {
                insert account;
                result = account.Id;
            } catch (Exception e) {
                result = 'LearnerService - Account Insert Error: [' + e.getLineNumber() + '] ' + e.getMessage();
            }
        }
        return result;
    }

    private static String firstNonNull(String preferred, String fallback) {
        return (preferred != null ? preferred : fallback);
    }

    private static String setStudentType(String countryCode) {
        if (countryCode != null) {
            Country_List__c country = [
                SELECT country_code_2__c
                FROM Country_List__c
                WHERE country_code_2__c = :countryCode
                LIMIT 1
            ];
            if (country != null) {
                switch on country.country_code_2__c {
                    when 'GB', 'XK' {
                        return 'Domestic';
                    }
                    when 'AT',
                        'BE',
                        'BG',
                        'HR',
                        'XA',
                        'CZ',
                        'DK',
                        'EE',
                        'FI',
                        'FR',
                        'GF',
                        'DE',
                        'GR',
                        'HU',
                        'IE',
                        'IT',
                        'LV',
                        'LT',
                        'LU',
                        'MT',
                        'NL',
                        'PL',
                        'PT',
                        'RO',
                        'SK',
                        'SI',
                        'ES',
                        'SE' {
                        return 'EU';
                    }
                    when else {
                        return 'International';
                    }
                }
            }
        }
        return null;
    }

    public static String setDropdownValueFromCode(String value, String fieldName, String objectName) {
        String returnValue;
        Schema.SObjectType objSobjectType = Schema.getGlobalDescribe().get(objectName);
        Schema.DescribeSObjectResult objDescribeSobject = objSobjectType.getDescribe();
        Map<String, Schema.SObjectField> fields = objDescribeSobject.fields.getMap();
        Schema.DescribeFieldResult fieldResult = fields.get(fieldName).getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for (Schema.PicklistEntry pickListVal : ple) {
            String pickListValStr = String.valueOf(pickListVal.getLabel());
            if (pickListValStr.subStringBefore('~') == value) {
                returnValue = pickListValStr;
            }
        }
        return returnValue;
    }
}
