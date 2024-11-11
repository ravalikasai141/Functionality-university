public class LogSchema {
    public String level;
    public DateTime timestamp;
    public String message;
    public String username;

    public LogSchema(String level, String message) {
        this.level = level;
        this.timestamp = DateTime.now();
        this.message = message;
        this.username = UserInfo.getUserName();
    }
}
