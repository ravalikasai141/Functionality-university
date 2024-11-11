/**
 * Schema for the Request for Information events
 */
public class RequestForInformationSchema implements EventSchema {
    /**
     * {@inheritDoc}
     */
    public static String getUniqueKey(String jsonString) {
        return null;
    }

    public String analytics_source;
    public String analytics_medium;
    public String analytics_campaign;
    public String email;
    public String phone;
    public String jobTitle;
    public String firstName;
    public String lastName;
    public String gaGclId;
    public String gaClientId;
    public String currentBppStudent;
    public String programmeOfInterest;
    public Boolean optOut;
    public String sourceTitle;
    public String subSource;
    public String leadSource;
    public String ukEuStudent;
    public String comments;
    public String recordType;
    public String formName;
    public String company;
    public String hashedEmail;
    public Boolean levyPayer;
    public String submitTimestamp;
}
