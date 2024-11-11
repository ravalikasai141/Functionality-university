/**
 * Schema for the Application events
 */
public class ApplicationSchema implements EventSchema {
    /**
     * {@inheritDoc}
     */
    public static String getUniqueKey(String jsonString) {
        return ((ApplicationSchema) JSON.deserialize(jsonString, ApplicationSchema.class))?.applicationId;
    }

    public String apprenticeshipType;
    public String applicationId;
    public String applicantId;
    public String applicationType;
    public String applicationReference;
    public String awardingBody;
    public String productId;
    public List<Stage> stages = new List<Stage>();
    public DateTime createdAt;
    public String createdBy;
    public DateTime updatedAt;
    public String updatedBy;
    public String currentStage;
    public Product product = new Product();
    public String status;
    public PersonalDetail personalDetails = new PersonalDetail();
    public DateTime submissionDeadline;
    public DateTime offerDeadline;
    public String programmeId;
    public EmployerInformation employerInformation = new EmployerInformation();
    public Nationality nationality = new Nationality();
    public BackgroundInformation backgroundInformation = new BackgroundInformation();
    public EducationAndSkills educationAndSkills = new EducationAndSkills();
    public DocumentAndEvidence documentsAndEvidence = new DocumentAndEvidence();
    public PrivacyTermsConditions privacyTermsAndConditions = new PrivacyTermsConditions();
    public LineManagerReviewConfirmation lineManagerReviewConfirmation = new LineManagerReviewConfirmation();
    public AcademicReference academicReference = new AcademicReference();
    public PersonalStatement personalStatement = new PersonalStatement();
    public TuitionFees tuitionFees = new TuitionFees();
    public String clientName;

    public class CodeDetail {
        public String code;
        public String name;
    }

    public class PersonalDetail {
        public PersonalInfo personalInfo = new PersonalInfo();
        public Address address = new Address();
        public EmergencyContact emergencyContact = new EmergencyContact();
    }

    public class PersonalInfo {
        public String title;
        public String firstName;
        public String lastName;
        public String middleName;
        public String emailAddress;
        public String mobilePhone;
        public Date dateOfBirth;
        public String niNumber;
        public GuardianInfo guardianInfo = new GuardianInfo();
    }

    public class Address {
        public String line1;
        public String line2;
        public String line3;
        public String city;
        public String county;
        public String postalCode;
        public CodeDetail country = new CodeDetail();
    }

    public class BackgroundInformation {
        public EqualityAndDiversity equalityAndDiversity = new EqualityAndDiversity();
        public Nationality nationality = new Nationality();
    }

    public class EqualityAndDiversity {
        public CareExperience careExperience = new CareExperience();
        public LearningNeeds learningNeeds = new LearningNeeds();
        public CodeDetail sexualOrientation = new CodeDetail();
        public CodeDetail religion = new CodeDetail();
        public Ethnicity ethnicity = new Ethnicity();
        public CodeDetail gender = new CodeDetail();
        public CodeDetail sameGenderAsBirth = new CodeDetail();
        public Boolean isCriminalConviction;
        public String criminalConvictionDescription;
    }

    public class CareExperience {
        public String isLocalAuthorityCare;
        public String careExperienceLevel;
        public Boolean isInformEmployer;
        public Boolean isRequestCareLeaverBursary;
        public Boolean isAlreadyReceivedCareLeaverBursary;
    }

    public class EmergencyContact {
        public Boolean sameAsGuardianInfo;
        public String relationship;
        public String firstName;
        public String lastName;
        public String emailAddress;
        public String mobilePhone;
    }

    public class GuardianInfo {
        public String firstName;
        public String lastName;
        public String emailAddress;
        public String mobilePhone;
        public String relationship;
    }

    public class EmployerInformation {
        public CompanyInformation companyInformation = new CompanyInformation();
        public LineManagerInformation lineManagerInformation = new LineManagerInformation();
        public Role role = new Role();
    }

    public class CompanyInformation {
        public string companyName;
        public string line1;
        public string line2;
        public string line3;
        public string city;
        public string postalCode;
        public CodeDetail country = new CodeDetail();
    }

    public class LineManagerInformation {
        public String firstName;
        public String lastName;
        public String jobTitle;
        public String emailAddress;
        public String mobilePhone;
    }

    public class LineManagerReviewConfirmation {
        public LmrAnswers lmrAnswers = new LmrAnswers();
    }

    public class LmrAnswers {
        public Boolean isApplicantInRoleLessThan9Month;
        public Boolean isFewerThan50Employees;
    }

    public class Role {
        public string jobTitle;
        public string jobDescription;
        public Date jobStartDate;
        public Double weeklyContractedHours;
        public String safetyQueryKnowledge;
        public Double overallOffTheJobTrainingHours;
    }

    public class Stage {
        public String code;
        public String duration;
        public String status;
        public DateTime startedOn;
        public DateTime completedOn;
        public List<Section> sections = new List<Section>();
    }

    public class Section {
        public String code;
        public String status;
        public List<SubSection> subsections = new List<SubSection>();
    }

    public class SubSection {
        public String code;
        public String status;
    }

    public class Nationality {
        public CodeDetail countryOfBirth = new CodeDetail();
        public CodeDetail countryOfNationality = new CodeDetail();
        public CodeDetail countryOfPermanentResidency = new CodeDetail();
    }

    public class LearningNeeds {
        public List<CodeDetail> secondaryDifficulty = new List<CodeDetail>();
        public CodeDetail primaryDifficulty = new CodeDetail();
        public CodeDetail isLearningNeed = new CodeDetail();
        public CodeDetail receiptEducationCarePlan = new CodeDetail();
        public CodeDetail highLevelSpecialNeeds = new CodeDetail();
        public String primaryDifficultyOther;
        public string secondaryDifficultyOther;
    }

    public class EducationAndSkills {
        public EducationHistory educationHistory = new EducationHistory();
        public SelfAssessment selfAssessment = new SelfAssessment();
    }

    public class EducationHistory {
        public List<Qualification> qualifications = new List<Qualification>();
    }

    public class Qualification {
        public String grade;
        public String yearCompletedExpected;
        public String otherSubjectDetail;
        public String otherAwardingInstitutionDetail;
        public CodeDetail country = new CodeDetail();
        public CodeDetail awardingInstitution = new CodeDetail();
        public CodeDetail type = new CodeDetail();
        public CodeDetail subject = new CodeDetail();
        public String examiningBody;
    }

    public class SelfAssessment {
        public List<KSBS> ksbs = new List<KSBS>();
    }

    public class KSBS {
        public String code;
        public String question;
        public String answer;
        public String experienceInfo;
        public Boolean isModifiedByLM;
        public String description;
        public String lmWorkplaceActivity;
    }

    public class DocumentAndEvidence {
        public DocumentsInformation backgroundInformation = new DocumentsInformation();
    }

    public class DocumentsInformation {
        public List<DocumentInformation> generalDocuments = new List<DocumentInformation>();
        public List<DocumentInformation> educationHistoryDocuments = new List<DocumentInformation>();
        public DocumentInformation nameChanged;
    }

    public class DocumentInformation {
        public Boolean notAvailable;
        public List<Document> documents = new List<Document>();
        public String categoryCode;
        public CodeDetail awardingInstitution = new CodeDetail();
        public CodeDetail type = new CodeDetail(); // qualification type
        public CodeDetail country = new CodeDetail();
        public Boolean isNameSameAsApplication;
    }

    public class Document {
        public String documentId;

        public Document(String documentId) {
            this.documentId = documentId;
        }
    }

    public class PrivacyTermsConditions {
        public PrivacyNotice privacyNotice = new privacyNotice();
        public TermsAndConditions applicantTermsAndConditions = new TermsAndConditions();
        public TermsAndConditions lmrTermsAndConditions = new TermsAndConditions();
        public ContactPreferences contactPreferences = new ContactPreferences();
    }

    public class ContactPreferences {
        public List<String> contactChannel = new List<String>();
        public List<String> contactType = new List<String>();
    }

    public class PrivacyNotice {
        public Boolean hasRead;
    }

    public class TermsAndConditions {
        public Date readOn;
    }

    public class Product {
        public Integer EPA;
        public String EPAO;
        public String academicLevel;
        public DateTime startOn;
        public DateTime endOn;
    }

    public class Ethnicity {
        public String name;
        public String codeESFA;
        public String codeHESA;
    }

    public class AcademicReference {
        public String firstName;
        public String lastName;
        public String mobilePhone;
        public String emailAddress;
        public String relationship;
    }

    public class PersonalStatement {
        public String statement;
    }

    public class TuitionFees {
        public String fundingType;
        public SponsorInfo sponsorInfo = new SponsorInfo();
    }

    public class SponsorInfo {
        public String firstName;
        public String lastName;
        public String emailAddress;
        public String organisationName;
        public String mobilePhone;
        public String purchaseOrderNumber;
    }
}
