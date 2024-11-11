/**
 * Schema for the Application withdrew change events
 */
public class ApplicationWithdrewSchema implements EventSchema {
    /**
     * {@inheritDoc}
     */
    public static String getUniqueKey(String jsonString) {
        return ((ApplicationWithdrewSchema) JSON.deserialize(jsonString, ApplicationWithdrewSchema.class))
            ?.applicationId;
    }

    public String applicationId;
}
