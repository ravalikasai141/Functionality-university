public class CasData {
    Header Header;
    List<CAS> CAS;

    public CasData() {
        this.Header = new Header();
        this.CAS = generateCASList();
    }

    public class Header {
        String BulkUploadFileId;
        String SchemaID;
        String TierID;
        String Category;
        String SponsorLicenceNumber;

        public Header() {
            this.BulkUploadFileId = 'oneBasicCAS';
            this.SchemaID = 'T4General Ready To Go';
            this.TierID = 'Tier 4';
            this.Category = 'General';
            this.SponsorLicenceNumber = 'DF1GYYNR3';
        }
    }

    public class CAS {
        ApplicantData ApplicantData;
        NonSponsorEducationInstitutionData NonSponsorEducationInstitutionData;
        CourseDetails CourseDetails;
        WorkPlacementDetails WorkPlacementDetails;
        Documentation Documentation;
        EvidenceDetails EvidenceDetails;
        FinancialAndAccommodationDetails FinancialAndAccommodationDetails;

        private void setApplicantData(ApplicantData applicantData) {
            this.ApplicantData = applicantData;
            this.NonSponsorEducationInstitutionData = new NonSponsorEducationInstitutionData();
        }
        private void setCourseDetails(CourseDetails courseDetails) {
            this.CourseDetails = courseDetails;
        }
        private void setWorkPlacementDetails(WorkPlacementDetails workPlacementDetails) {
            this.WorkPlacementDetails = workPlacementDetails;
        }
        private void setDocumentation(Documentation documentation) {
            this.Documentation = documentation;
        }
        private void setEvidenceDetails(EvidenceDetails evidenceDetails) {
            this.EvidenceDetails = evidenceDetails;
        }
        private void setFinancialAndAccommodationDetails(FinancialAndAccommodationDetails financialAndAccommodationDetails) {
            this.FinancialAndAccommodationDetails = financialAndAccommodationDetails;
        }
    }

    public class ApplicantData {
        String ApplicantID;
        String ApplicationId;
        String FamilyName;
        String GivenName;
        String Nationality;
        Integer Gender;
        String CountryOfBirth;
        String PlaceOfBirth;
        DateOfBirth DateOfBirth;
        String ApplicantPassportOrTravelDocumentNumber;

        public ApplicantData(String adApplicantID, String adFamilyName, String adGivenName, String adNationality, Integer adGender, String adCountryOfBirth, Date adDateOfBirth, String adApplicantPassportOrTravelDocumentNumber) {
            this.ApplicantID = adApplicantID;
            this.FamilyName = adFamilyName;
            this.GivenName = adGivenName;
            this.Nationality = adNationality;
            this.Gender = adGender;
            this.CountryOfBirth = adCountryOfBirth;
            this.ApplicantPassportOrTravelDocumentNumber = adApplicantPassportOrTravelDocumentNumber;
            this.dateOfBirth = new DateOfBirth(adDateOfBirth);
        }
    }

    public class DateOfBirth { 
        Date FullDate;

        public DateOfBirth(Date dobFullDate) {
            this.FullDate = dobFullDate;
        }
    }
    
    public class NonSponsorEducationInstitutionData {
        PartnerInstitutionDetails PartnerInstitutionDetails;

        public NonSponsorEducationInstitutionData() {
            this.PartnerInstitutionDetails = new PartnerInstitutionDetails();
        }
    }

    public class PartnerInstitutionDetails {
        String Name;
        AddressDetails AddressDetails;

        public PartnerInstitutionDetails() {
            this.Name = 'BPP University Ltd';
            this.AddressDetails = new AddressDetails();
        }
    }

    public class AddressDetails { 
        String AddressLine;
        String City;
        String CountyAreaDistrict;
        String PostCode;
        String Country;

        public AddressDetails() {
            this.AddressLine = 'BPP House Aldine Place, 142-144 Uxbridge Road, Shepherds Bush';
            this.City = 'London';
            this.CountyAreaDistrict = 'London';
            this.PostCode = 'W12 8AA';
            this.Country = 'GBR';
        }
    }

    public class CourseDetails  {
        String CourseCurriculumTitle;
        String CourseID;
        String AcademicLevel;
        String SecondaryAcademicLevel;
        Date CourseStartDate;
        Date LatestDateForAcceptanceOnCourse;
        Date ExpectedCourseEndDate;
        Boolean CourseIsFullTime;
        Integer CourseHoursPerWeek;
        Boolean ApplicantHasWorkPlacement;
        MainSiteOfStudy MainSiteOfStudy;

        public CourseDetails(String cdCourseCurriculumTitle, String cdAcademicLevel, Date cdCourseStartDate, Date cdLatestDateForAcceptanceOnCourse, Date cdExpectedCourseEndDate, Boolean cdApplicantHasWorkPlacement, MainSiteOfStudy cdMainSiteOfStudy) {
            this.CourseCurriculumTitle = cdCourseCurriculumTitle;
            this.AcademicLevel = cdAcademicLevel;
            this.CourseStartDate = cdCourseStartDate;
            this.LatestDateForAcceptanceOnCourse = cdLatestDateForAcceptanceOnCourse;
            this.ExpectedCourseEndDate = cdExpectedCourseEndDate;
            this.ApplicantHasWorkPlacement = cdApplicantHasWorkPlacement;
            this.MainSiteOfStudy = cdMainSiteOfStudy;
            this.CourseIsFullTime = true;
            this.CourseHoursPerWeek = 0;
        }
    }

    public class MainSiteOfStudy {
        public String AddressLine{get;set;}
        public String City{get;set;}
        public String CountyAreaDistrict{get;set;}
        public String PostCode{get;set;}

        public MainSiteOfStudy(String msosAddressLine, String msosCity, String msosCountyAreaDistrict, String msosPostCode) {
            this.AddressLine = msosAddressLine;
            this.City = msosCity;
            this.CountyAreaDistrict = msosCountyAreaDistrict;
            this.PostCode = msosPostCode;
        }
    }

    public class WorkPlacementDetails {
        Integer WorkPlacementPercentage;
        String WorkPlacementJustificationText;
        WorkPlacementAddress WorkPlacementAddress;

        public WorkPlacementDetails(Integer wpdWorkPlacementPercentage, String wpdWorkPlacementJustificationText) {
            this.WorkPlacementPercentage = wpdWorkPlacementPercentage;
            this.WorkPlacementJustificationText = wpdWorkPlacementJustificationText;
            this.WorkPlacementAddress = new WorkPlacementAddress();
        }
    }

    public class WorkPlacementAddress {
        String AddressLine1;
        String City;
        String CountyAreaDistrict;
        String PostCode;
        String Country;
    }

    public class Documentation {
        String DocumentsUsedToObtainOffer;
        //Boolean CourseRequiresATAS = false;
        //Boolean PostgraduateDeanCertificateRequired = false;

        public Documentation(String dDocumentsUsedToObtainOffer) {
            this.DocumentsUsedToObtainOffer = dDocumentsUsedToObtainOffer;
        }
    }

    public class EvidenceDetails {
        Boolean SELTRequired;
        String ReasonSELTNotRequired;
        String EnglishLanguageLevelAttained;
        String SELTSpeakingLevel;
        String SELTListeningLevel;
        String SELTReadingLevel;
        String SELTWritingLevel;
        String TestProvider;
        Boolean PreviousUKStudy;
        String PreviousAcademicLevel;
        String CurrentPreviousCourseLevelComparison;
        String ProgressionJustification;

        public EvidenceDetails(String edReasonSELTNotRequired, String edEnglishLanguageLevelAttained, String edSELTSpeakingLevel, String edSELTListeningLevel, String edSELTReadingLevel, String edSELTWritingLevel, Boolean edPreviousUKStudy, String edPreviousAcademicLevel, String edCurrentPreviousCourseLevelComparison, String edProgressionJustification) {
            this.SELTRequired = false;
            this.ReasonSELTNotRequired = edReasonSELTNotRequired;
            this.EnglishLanguageLevelAttained = edEnglishLanguageLevelAttained;
            this.SELTSpeakingLevel = edSELTSpeakingLevel;
            this.SELTListeningLevel = edSELTListeningLevel;
            this.SELTReadingLevel = edSELTReadingLevel;
            this.SELTWritingLevel = edSELTWritingLevel;
            this.PreviousUKStudy = edPreviousUKStudy;
            this.PreviousAcademicLevel = edPreviousAcademicLevel;
            this.CurrentPreviousCourseLevelComparison = edCurrentPreviousCourseLevelComparison;
            this.ProgressionJustification = edProgressionJustification;
        }
    }

    public class FinancialAndAccommodationDetails {
        Boolean AccomodationProvided;
        Boolean CourseFeeIncludesAccomodationCosts;
        Decimal CourseFeesForFirstYearOnly;
        Decimal CourseFeesPaidToDate;
        Integer BoardingFeesForFirstYearOnly;
        Integer BoardingFeesPaidToDate;

        public FinancialAndAccommodationDetails(Decimal faadCourseFeesForFirstYearOnly, Decimal faadCourseFeesPaidToDate) {
            this.AccomodationProvided = false;
            this.CourseFeeIncludesAccomodationCosts = false;
            this.CourseFeesForFirstYearOnly = faadCourseFeesForFirstYearOnly;
            this.CourseFeesPaidToDate = faadCourseFeesPaidToDate;
            this.BoardingFeesForFirstYearOnly = 0;
            this.BoardingFeesPaidToDate = 0;
        }
    }

    public static List<CAS> generateCASList() {
        List<CAS> todaysCASList = new List<CAS>();

        List<Opportunity> opportunityList = [
            SELECT Id, AccountId, BPP_Last_Enrolment_Date__c, Course_Instance__r.Name,  Course_Instance__r.Location__c, Course_Instance__r.Start_Date__c, 
            Course_Instance__r.End_Date__c, Course_Instance__r.Level_PQ__c, Total_Sale_Price__c, Discount_Amount__c, CAS_Progression_Justification__c, 
            BPP_CAS_Officer__c, BPP_Course_Level__c, BPP_Previous_Course_Level__c, 
            Account.PersonContactId, Account.LastName, Account.FirstName, Account.BNR_Banner_ID__pc, Account.Primary_Nationality__pr.ISO_CODE__c, 
            Account.Gender__pc, Account.SFDC_Country_of_Birth__pr.ISO_CODE__c, Account.Passport_Number__pc, Account.PersonBirthdate,  
            Account.BPP_Reason_SELT_Not_Required__c, Account.Overall_Language_Score__pc, Account.Speaking_Language_Score__pc, Account.Listening_Language_Score__pc, 
            Account.Reading_Language_Score__pc, Account.Writing_Language_Score__pc, Account.Ever_Studied_in_UK_Before__c, Account.Language_Test_Type__pc
            FROM Opportunity WHERE CAS_status__c = 'Ready to Assign' AND Course_Instance__c != null
        ];

        Set<Id> contactIds = new Set<Id>();
        Set<Id> accountIds = new Set<Id>();
        for (Opportunity opp : opportunityList) {
            contactIds.add(opp.Account.PersonContactId);
            accountIds.add(opp.AccountId);
        }

        Map<Id, List<Qualification__c>> qualificationMap = createQualificationMap(contactIds);
        Map<Id, Decimal> paymentAmountMap = createPaymentAmountMap(accountIds);

        for (Opportunity opp : opportunityList) {
            CAS cas = new CAS();

            // ApplicantData
            cas.setApplicantData(new ApplicantData(opp.Account.BNR_Banner_ID__pc,  opp.Account.LastName, opp.Account.FirstName, opp.Account.Primary_Nationality__pr.ISO_CODE__c, setGenderValue(opp.Account.Gender__pc), opp.Account.SFDC_Country_of_Birth__pr.ISO_CODE__c, opp.Account.PersonBirthdate, opp.Account.Passport_Number__pc));
            
            // CourseDetails
            MainSiteOfStudy mainSiteOfStudy = setMainSiteOfStudy(opp.Course_Instance__r.Location__c);
            Boolean applicantWorkPlacement = setApplicantWorkPlacement(opp.Course_Instance__r.Name);
            cas.setCourseDetails(new CourseDetails(opp.Course_Instance__r.Name, opp.Course_Instance__r.Level_PQ__c, opp.Course_Instance__r.Start_Date__c, opp.BPP_Last_Enrolment_Date__c, opp.Course_Instance__r.End_Date__c, applicantWorkPlacement, mainSiteOfStudy));
            
            // WorkPlacementDetails
            Integer workPlacementPercentage = setWorkPlacementPercentage(applicantWorkPlacement, opp.Course_Instance__r.Name);
            cas.setWorkPlacementDetails(new WorkPlacementDetails(workPlacementPercentage, setWorkPlacementJustificationText(applicantWorkPlacement, opp.Course_Instance__r.Name)));
            
            // Documentation
            List<Qualification__c> qualificationList = qualificationMap.get(opp.Account.PersonContactId);
            String qualificationDetails;
            if (qualificationList != null && qualificationList.size() > 0) {
                String englishDocumentUsedForOffer = setEnglishDocumentUsedForOffer(opp.Account.Language_Test_Type__pc);
                qualificationDetails = concatenateQualificationDetails(qualificationList, englishDocumentUsedForOffer);
            }
            cas.setDocumentation(new Documentation(qualificationDetails));

            // EvidenceDetails
            Boolean previousUkStudy = setPreviousUKStudy(opp.Account.Ever_Studied_in_UK_Before__c);
            String courseLevelComparison = (previousUkStudy ? setCourseLevelComparison(opp.BPP_Previous_Course_Level__c, opp.BPP_Course_Level__c) : null);
            String progressionJustification = (courseLevelComparison == 'Same' || courseLevelComparison == 'Lower' ? opp.CAS_Progression_Justification__c : null);
            cas.setEvidenceDetails(new EvidenceDetails(opp.Account.BPP_Reason_SELT_Not_Required__c, opp.Account.Overall_Language_Score__pc, opp.Account.Speaking_Language_Score__pc, opp.Account.Listening_Language_Score__pc, opp.Account.Reading_Language_Score__pc, opp.Account.Writing_Language_Score__pc, previousUkStudy, opp.BPP_Previous_Course_Level__c, courseLevelComparison, progressionJustification));

            // FinancialAndAccommodationDetails
            Decimal courseFeesPaidToDate = (paymentAmountMap.get(opp.AccountId) != null ? paymentAmountMap.get(opp.AccountId) : 0);
            cas.setFinancialAndAccommodationDetails(new FinancialAndAccommodationDetails(setCourseFeesForFirstYearOnly(opp.Total_Sale_Price__c, opp.Discount_Amount__c, opp.Course_Instance__r.Start_Date__c, opp.Course_Instance__r.End_Date__c), courseFeesPaidToDate));
            
            todaysCASList.add(cas);
        }
        return todaysCASList;
    }

    public static Map<Id, List<Qualification__c>> createQualificationMap(Set<Id> contactIds) {
        Map<Id, List<Qualification__c>> qualificationMap = new Map<Id, List<Qualification__c>>();
        for (Qualification__c record : [
            SELECT Id, Student__c, Qualification_Institution__r.Name, Description__c, Qualification_Date__c, Examing_Body__c
            FROM Qualification__c WHERE Admissions_Request__c = true AND Student__c IN: contactIds
        ]) {
            List<Qualification__c> recordsForMap = qualificationMap.get(record.Student__c);
            if (recordsForMap == null) {
                recordsForMap = new List<Qualification__c>();
                qualificationMap.put(record.Student__c, recordsForMap);
            }    
            recordsForMap.add(record);
        }
        return qualificationMap;
    }

    public static Map<Id, Decimal> createPaymentAmountMap(Set<Id> accountIds) {
        Map<Id, Decimal> paymentAmountMap = new Map<Id, Decimal>();
		DateTime threeMonthsAgo = System.today().addMonths(-3);
        List<Payment__c> paymentList = [
            SELECT AR_Payment_Amount__c, Student__c FROM Payment__c WHERE AR_Payment_Segment__c = 'First Instalment for CAS' AND Student__c IN: accountIds AND CreatedDate >: threeMonthsAgo
        ];
        if (paymentList.size() > 0) {
            for (Payment__c payment : paymentList) {
                Decimal cumulativeAmount = paymentAmountMap.get(payment.Student__c);
                if (cumulativeAmount == null) {
                    paymentAmountMap.put(payment.Student__c, payment.AR_Payment_Amount__c);
                } else {
                    cumulativeAmount += payment.AR_Payment_Amount__c;
                    paymentAmountMap.put(payment.Student__c, cumulativeAmount);
                }
            }
        }
        return paymentAmountMap;
    }

    private static Integer setGenderValue(String gender) {
        switch on gender {
            when 'Male', 'M' { return 1; }
            when 'Female', 'F' { return 2; }
            when else { return 1; }
        }
    }

    public static MainSiteOfStudy setMainSiteOfStudy(String location) {
        String addressLine, city, district, postCode;
        switch on location {
            when 'London (Waterloo)', 'London - Waterloo', 'London Waterloo' {
                addressLine = '137 Stamford Street';
                city = 'London';
                district = 'Greater London';
                postCode = 'SE1 9NN';
            }
            when 'Reading' {
                addressLine = '1st Floor, 3 Forbury Place, 23 Forbury Road';
                city = 'Reading';
                district = 'Berkshire';
                postCode = 'RG1 3JH';
            }
            when 'Newcastle' {
                addressLine = '2nd Floor Gunner House, Neville Street';
                city = 'Newcastle';
                district = 'Tyne and Wear';
                postCode = 'NE1 5DF';
            }
            when 'Birmingham', 'BPP Birmingham' {
                addressLine = '32-34 Colmore Circus';
                city = 'Birmingham';
                district = 'West Midlands';
                postCode = 'B4 6BN';
            }
            when 'London (Liverpool St)', 'London - Liverpool Street' {
                addressLine = '4th Floor, 3 London Wall Buildings';
                city = 'London';
                district = 'Greater London';
                postCode = 'EC2M 5PD';
            }
            when 'Central Milton Keynes', 'M Keynes', 'Milton Keynes' {
                addressLine = '740 South Fifth Street';
                city = 'Milton Keynes';
                district = 'Buckinghamshire';
                postCode = 'MK9 2FX';
            }
            when 'Doncaster-RDASH' {
                addressLine = 'Almond Tree Court, Tickhill Road Hospital, Tickhill Road';
                city = 'Doncaster';
                district = 'South Yorkshire';
                postCode = 'DN4 8QN';
            }
            when 'London (Shepherd\'s Bush)', 'London - Shepherds Bush' {
                addressLine = 'BPP House, Aldine Place, 142-144 Uxbridge Road';
                city = 'London';
                district = 'Greater London';
                postCode = 'W12 8AW';
            }
            when 'London (Holborn)', 'London - Red Lion Street', 'London - Red Lion Street (AO)', 'London - Red Lion Street (BCLP)', 'London - Red Lion Street (BM)', 'London - Red Lion Street (CC)' {
                addressLine = 'BPP University, London Holborn 68-70 Red Lion Street';
                city = 'London';
                district = 'Greater London';
                postCode = 'WC1R 4NY';
            }
            when 'London (City)', 'London - London City', 'London City' {
                addressLine = 'Fitzwilliam House, 2 St Mary Axe';
                city = 'London';
                district = 'Greater London';
                postCode = 'EC3A 8BF';
            }
            when 'Southampton', 'University of Southampton' {
                addressLine = 'Ground Floor, 2 Charlotte Place';
                city = 'Southampton';
                district = 'Hampshire';
                postCode = 'SO14 0TB';
            }
            when 'London (Kings Cross)', 'London - Kings Cross', 'London Kings Cross' {
                addressLine = 'Marcello House, 236-240 Pentonville Road';
                city = 'London';
                district = 'Greater London';
                postCode = 'N1 9JY';
            }
            when 'London - Portsoken' {
                addressLine = 'One Portsoken Street';
                city = 'London';
                district = 'Greater London';
                postCode = 'E1 8BT';
            }
            when 'Bristol' {
                addressLine = 'Queen Square, Grove Avenue ';
                city = 'Bristol';
                district = 'Bristol';
                postCode = 'BS1 4QY';
            }
            when 'Nottingham' {
                addressLine = 'Regus 6th floor, City Gate East, Tollhouse Hill';
                city = 'Nottingham';
                district = 'Nottinghamshire';
                postCode = 'NG1 5FS';
            }
            when 'BPP Jersey', 'Jersey' {
                addressLine = 'Regus Liberation Station, St Helier';
                city = 'Jersey';
                district = 'Channel Islands';
                postCode = 'JE2 3AS';
            }
            when 'Cambridge' {
                addressLine = 'Regus Wellington House, East Road';
                city = 'Cambridge';
                district = 'Cambridgeshire';
                postCode = 'CB1 1BH';
            }
            when 'Manchester', 'Manchester - St James', 'Manchester St James', 'St James, Manchester' {
                addressLine = 'St James Building, 79 Oxford Street';
                city = 'Manchester';
                district = 'Greater Manchester';
                postCode = 'M1 6FQ';
            }
            when 'BPP Guernsey' {
                addressLine = 'The Mallard Complex, La Villiaze';
                city = 'Guernsey';
                district = 'Channel Islands';
                postCode = 'GY8 0HG';
            }
            when 'Leeds', 'Leeds - Whitehall Quay' {
                addressLine = 'Whitehall 2, Whitehall Quay';
                city = 'Leeds';
                district = 'West Yorkshire';
                postCode = 'LS1 4HR';
            }
        }
        return new MainSiteOfStudy(addressLine, city, district, postCode);
    }

    private static Boolean setApplicantWorkPlacement(String courseName) {
        return (courseName.startsWith('BSCHN') || courseName.endsWith('PDP') ? true : false);
    }

    private static Integer setWorkPlacementPercentage(Boolean applicantWorkPlacement, String courseName) {
        if (applicantWorkPlacement) {
            if (courseName.startsWith('BSCHN')) { return 50; }
            if (courseName.endsWith('PDP')) { return 33; }
        } 
        return null;
    }

    private static String setWorkPlacementJustificationText(Boolean applicantWorkPlacement, String courseName) {
        if (applicantWorkPlacement) {
            if (courseName.startsWith('BSCHN')) { return 'Please note that this student will be undertaking a work placement as part of their course. The start and end dates, duration of the placement and hours per week are not yet confirmed, however it won\'t exceed more than 50% as per paragraph 6.6 a of the Student Guidance for Sponsors Document 2. Please note that BSc (Hons) Nursing [Pre - registration Nursing] has been validated as 50% Theory & 50% Practice course based on Nursing and Midwifery Council (NMC) requirements. Both parts (theory and practice) are fully assessed, and attendance is closely monitored.'; }
        } 
        return null;
    }

    public static String setEnglishDocumentUsedForOffer(String languageTestType) {
        String englishDocumentUsedForOffer = 'We can confirm we have assessed the English Language ability of the student at CEFR Level B2 in each of the 4 components (Speaking, Reading, Listening, and Writing)';
        switch on languageTestType {
            when 'IELTS' {
                englishDocumentUsedForOffer += ' on the basis of evidence provided from their IELTS test.';
            }
            when 'BPP ELT' {
                englishDocumentUsedForOffer += ' on the basis of the student passing BPP\'s Internal English Test.';
            }
            when 'TOEFL' {
                englishDocumentUsedForOffer += ' on the basis of evidence provided from their TOEFL test.';
            }
            when 'PTE' {
                englishDocumentUsedForOffer += ' on the basis of evidence provided from their PTE test.';
            }
            when 'GCSE/GCE', 'Other' {
                englishDocumentUsedForOffer += ' on the basis of evidence provided.';
            }
            when 'HSSC ELT Waiver' {
                englishDocumentUsedForOffer += '. The assessment is based on evidence that the student has scored 60% or above in their HSSC English and furthermore has previously been taught and completed their Bachelor studies in English Medium.';
            }
            when 'Oxford ELT Test' {
                englishDocumentUsedForOffer += ' on the basis of evidence provided from their Oxford ELT Test.';
            }
            when 'Language Cert' {
                englishDocumentUsedForOffer += ' on the basis of evidence provided from their Language Cert test.';
            }
            when 'MOI' {
                englishDocumentUsedForOffer += '. The assessment is based on evidence that the student has previously been taught and completed their studies in English Medium. Evidence provided.';
            }
            when else {
                return null;
            }
        }
        return englishDocumentUsedForOffer;
    }

    public static String concatenateQualificationDetails(List<Qualification__c> qualificationList, String englishDocumentUsedForOffer) {
        String qualificationDetails = '';
        for (Integer i = 0; i < qualificationList.size(); i++) {
            Qualification__c qualification = qualificationList.get(i);
            qualificationDetails += (qualification.Qualification_Institution__r.Name != null && qualification.Qualification_Institution__r.Name == 'Any non-UK provider' ? qualification.Examing_Body__c : qualification.Qualification_Institution__r.Name);
            qualificationDetails += (qualification.Description__c != null ? ' - ' + qualification.Description__c : '');
            qualificationDetails += (qualification.Qualification_Date__c != null ? ' - dated ' + String.valueOf(qualification.Qualification_Date__c) : '');
            qualificationDetails += (i != qualificationList.size() - 1 ? ' - ' : '');
        }
        qualificationDetails += (englishDocumentUsedForOffer != null ? ' - ' + englishDocumentUsedForOffer : '');
        return qualificationDetails;
    }

    private static Boolean setPreviousUKStudy(String studiedInUkBefore) {
        return (studiedInUkBefore == 'Yes' ? true : false);
    }

    private static String setCourseLevelComparison(String previousCourseLevel, String courseLevel) {
        if (previousCourseLevel != null && courseLevel != null) {
            Integer previousCourseLevelInt = Integer.valueOf(previousCourseLevel.right(1));
            Integer courseLevelInt = Integer.valueOf(courseLevel.right(1));
            if (courseLevelInt < previousCourseLevelInt) {
                return 'Lower';
            } else if (courseLevelInt == previousCourseLevelInt) {
                return 'Same';
            } else if (courseLevelInt > previousCourseLevelInt) {
                return 'Higher';
            }
        } else if (previousCourseLevel == null && courseLevel != null) {
            return 'Higher';
        } else if (previousCourseLevel != null && courseLevel == null) {
            return 'Lower';
        }
        return null;
    }

    public static Decimal setCourseFeesForFirstYearOnly(Decimal totalSalePrice, Decimal discountAmount, Date startDate, Date endDate) {
        if (discountAmount == null || startDate == null || endDate == null) {
            return 0;
        } else {
            Integer yearDiffCalc = (endDate.year() - startDate.year());
            Integer yearDiff = (yearDiffCalc == 0 ? 1 : yearDiffCalc);
            Decimal courseFeesForFirstYearOnly = (totalSalePrice) / yearDiff;
            return courseFeesForFirstYearOnly.setScale(2);
        }
    }
}