/**
 * Schema for User Account Updated events
 */
public class UserAccountUpdatedSchema implements EventSchema {
    /**
     * {@inheritDoc}
     */
    public static String getUniqueKey(String jsonString) {
        UserAccountUpdatedSchema eventDetails = (UserAccountUpdatedSchema) JSON.deserialize(
            jsonString,
            UserAccountUpdatedSchema.class
        );

        if (eventDetails.userIds == null || eventDetails.userIds.isEmpty()) {
            return null;
        }
        return eventDetails.userIds[0];
    }

    public List<String> userIds = new List<String>();
    public PersonalInfo personalInfo = new PersonalInfo();
    public List<Address> addresses = new List<Address>();
    public EmergencyContact emergencyContact = new EmergencyContact();
    public Set<String> marketingPreferences = new Set<String>();
    public List<Qualification> professionalQualifications = new List<Qualification>();

    public class PersonalInfo {
        public String title;
        public String firstName;
        public String lastName;
        public String middleName;
        public String preferredName;
        public String preferredPronouns;
        public String emailAddress;
        public Date dateOfBirth;
        public String mobilePhone;
        public String workPhone;
        public String homePhone;
    }

    public class Address {
        public String type;
        public String line1;
        public String line2;
        public String line3;
        public String town;
        public String county;
        public String postalCode;
        public String country;
    }

    public class EmergencyContact {
        public String relationship;
        public String firstName;
        public String lastName;
        public String emailAddress;
        public String mobilePhone;
    }

    public class Qualification {
        public String awardingBody;
        public String reference;
    }
}
