/**
 * Schema for Application Eligibility Submitted events
 */
public class EligibilitySchema implements EventSchema {
    /**
     * {@inheritDoc}
     */
    public static String getUniqueKey(String jsonString) {
        return ((EligibilitySchema) JSON.deserialize(jsonString, EligibilitySchema.class))?.applicationId;
    }

    public String applicationId;
    public Eligibility eligibility;

    public class Eligibility {
        public String isEligible;
        public List<Answer> answers = new List<Answer>();
        public DateTime submittedOn;
        public String templateCode;
        public String summaryText;
    }

    public class Answer {
        public String question;
        public String stepCode;
        public Boolean eligible;
        public String summaryText;
    }
}
