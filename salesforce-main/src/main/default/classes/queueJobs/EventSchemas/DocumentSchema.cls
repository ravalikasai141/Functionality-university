public class DocumentSchema implements EventSchema {
    /**
     * {@inheritDoc}
     */
    public static String getUniqueKey(String jsonString) {
        return ((DocumentSchema) JSON.deserialize(jsonString, DocumentSchema.class))?.documentId;
    }

    public String documentSensitivity;
    public String authUserId;
    public DateTime created;
    public String documentCategory;
    public String documentId;
    public String documentName;
    public String documentType;
    public String contentType;
    public String version;
    public String status;
}
