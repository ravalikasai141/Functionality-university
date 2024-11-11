/**
 * Schema for the Application Stage change events
 */
public class ApplicationStageSchema implements EventSchema {
    /**
     * {@inheritDoc}
     */
    public static String getUniqueKey(String jsonString) {
        return ((ApplicationStageSchema) JSON.deserialize(jsonString, ApplicationStageSchema.class))?.applicationId;
    }

    public String applicationId;
    public String currentStage;
    public String currentStageStatus;

    public ApplicationStageSchema() {
    }

    public ApplicationStageSchema(String applicationId, String currentStage, String currentStageStatus) {
        this.applicationId = applicationId;
        this.currentStage = currentStage;
        this.currentStageStatus = currentStageStatus;
    }
}
