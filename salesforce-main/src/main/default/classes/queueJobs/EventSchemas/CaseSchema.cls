public class CaseSchema implements EventSchema {
    /**
     * {@inheritDoc}
     */
    public static String getUniqueKey(String jsonString) {
        return ((CaseSchema) JSON.deserialize(jsonString, CaseSchema.class))?.auth0Id;
    }

    public String auth0Id;
    public String school;
    public String productId;
    public String instanceId;
    public String queryType;
    public String subQueryType;
    public String queryDescription;
    public String queryId;
}
