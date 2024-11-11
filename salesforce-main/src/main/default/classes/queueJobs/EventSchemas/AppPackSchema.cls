public class AppPackSchema implements EventSchema {
    /**
     * {@inheritDoc}
     */
    public static String getUniqueKey(String jsonString) {
        return ((AppPackSchema) JSON.deserialize(jsonString, AppPackSchema.class))?.applicationId;
    }

    public String applicationId;
    public String appPackDocumentId;
    public String status;
    public String errorMessage;
}
