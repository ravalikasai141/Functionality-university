@RestResource(urlMapping='/v1.0/RegisterAttendance/*')
@TestVisible
global without sharing class RegisterAttendance {
    @HttpPost
    global static Response handleAttendance(Session session) {
        // skip processing for an empty submission
        if (session.attendance.size() == 0) {
            return new Response(204, 'No attendance data in the message');
        }
        
        // make sure the instance reference in the request exists on Salesforce
        List<Instance__c> instances = getInstanceByPfRef(session.instanceId);
        if (instances.size() == 0) {
            return new Response(404, 'Instance not found - ' + session.instanceId);
        }
        String instanceId = instances[0].Id;
        
        // check there are Booking_Line__c's for the instance to be marked attended
        Integer bookingLineCount = [SELECT COUNT() FROM Booking_Line__c WHERE Instance__c = :instanceId];
        if (bookingLineCount == 0) {
            return new Response(404, 'No booking lines on this instance ' + instanceId + '/' + session.instanceId);
        }
        
        // loop through incoming attendances to get student account id for each
        List<AttendanceWrapper> matchedAttendances = new List<AttendanceWrapper>();
        for (Attendance att : session.attendance) {
            att.sfInstanceId = instanceId;
            matchedAttendances.addAll(matchAttendanceToAccountIds(att));
        }
        
        // work through the data we've collected thus far to do the attendance marking
        Set<Id> instanceIds = new Set<Id>();
        Set<Id> studentIds = new Set<Id>();
        for (AttendanceWrapper aw : matchedAttendances) {
            instanceIds.add(aw.attendance.sfInstanceId);
            studentIds.add(aw.studentId);
        }
        
        List<Booking_Line__c> bookingLines = [
            SELECT Id, Instance__c, Student__c, Attended__c, Second_Session_Attended__c, Session__r.Session_Date__c, Session__r.Start_Time__c, Session__r.End_Time__c, 
            Session__r.Second_Session_Date__c, Session__r.Second_Session_End_Time__c, Session__r.Second_Session_Start_Time__c 
            FROM Booking_Line__c 
            WHERE Instance__c IN: instanceIds
            AND Student__c IN: studentIds 
            AND (
                (Session__c != NULL AND Session__r.Session_Date__c != NULL AND Attended__c = false) 
                OR 
                (Session__c != NULL AND Session__r.Second_Session_Date__c != NULL AND Second_Session_Attended__c = false)
            )
        ];
        
        if(bookingLines.size() == 0){
            return buildNothingToMarkResponse(matchedAttendances);
        }
        
        // build a Map of Attendance Wrapper objects, each of which could link to multiple Booking Lines
        Map<AttendanceWrapper, List<Booking_Line__c>> attendanceBookingLineMap = generateAttendanceBookingMap(matchedAttendances, bookingLines);
        markAttendance(attendanceBookingLineMap);
        return buildResponseFromMap(attendanceBookingLineMap);
    }
    
    private static void markAttendance(Map<AttendanceWrapper, List<Booking_Line__c>> attendanceBookingLineMap){
        Map<id, Booking_Line__c> bookingLineMap = new Map<id, Booking_Line__c>();
        
        for (AttendanceWrapper attendance : attendanceBookingLineMap.keyset()) {
            if (attendance.studentId == null) {
                //attendance.result = Results.ACCOUNT_NOT_FOUND;
                attendance.storeResult(Results.ACCOUNT_NOT_FOUND, null, null);
                continue;
            } 

            for (Booking_Line__c lineBeingMarked : attendanceBookingLineMap.get(attendance)) {
                if (lineBeingMarked == null) {
                    //attendance.result = Results.NO_UNMARKED_SESSIONS_FOUND;
                    attendance.storeResult(Results.NO_UNMARKED_SESSIONS_FOUND, null, null);
                    continue;
                } 

                if (markOneBooking(attendance, lineBeingMarked)) { 
                    maintainBookingLineMap(lineBeingMarked, bookingLineMap);
                }
            }
        }
        
        if (!bookingLineMap.isEmpty()) {
            List<Id> erroredIds = updateBookingLines(bookingLineMap.values());
            
            if (erroredIds.size() > 0) {
                updateAttendanceMapWithDbErrors(erroredIds, attendanceBookingLineMap);
            }
        }
    }
    
    private static void updateAttendanceMapWithDbErrors(List<Id> erroredIds, Map<AttendanceWrapper, List<Booking_Line__c>> attendanceBookingLineMap){
        for (AttendanceWrapper aw : attendanceBookingLineMap.keyset()) {
            if (erroredIds.contains(aw.bookingLineId)) {
                //aw.result = Results.UPDATE_FAILED;
                aw.storeResult(Results.UPDATE_FAILED, aw.bookingLineId, null);
                aw.debugString = 'Update failed on Booking_Line__c ' + aw.bookingLineId;
            }
        }
    }
    
    private static Map<AttendanceWrapper, List<Booking_Line__c>> generateAttendanceBookingMap(List<AttendanceWrapper> attendancesWithStudents, List<Booking_Line__c> allBookingLines){
        Map<AttendanceWrapper, List<Booking_Line__c>> attendanceBookingLineMap = new Map<AttendanceWrapper, List<Booking_Line__c>>();
        
        for (AttendanceWrapper attendance : attendancesWithStudents) {
            List<Booking_Line__c> bookingLinesForAttendance = new List<Booking_Line__c>();
            for (Booking_Line__c line : allBookingLines) {
                if (attendance.attendance.sfInstanceId == line.Instance__c && attendance.studentId == line.Student__c) {
                    bookingLinesForAttendance.add(line);
                }
            }
            
            attendanceBookingLineMap.put(attendance, bookingLinesForAttendance);
        }
        
        for (AttendanceWrapper attendance : attendanceBookingLineMap.keyset()) {
            System.debug('key: ' + attendance + ' : value: ' + attendanceBookingLineMap.get(attendance));
        }
        
        return attendanceBookingLineMap;
    }
    
    private static void maintainBookingLineMap(Booking_Line__c lineBeingMarked, Map<id, Booking_Line__c> bookingLineMap){
        if(!bookingLineMap.containsKey(lineBeingMarked.Id)){
            bookingLineMap.put(lineBeingMarked.Id, lineBeingMarked);
            return;
        }
        
        Booking_Line__c bookingFromMap = bookingLineMap.get(lineBeingMarked.Id);
        if(lineBeingMarked.Attended__c == true){
            bookingFromMap.Attended__c = true;
        }
        
        if(lineBeingMarked.Second_Session_Attended__c == true){
            bookingFromMap.Second_Session_Attended__c = true;
        }
    }
    
    private static void updateAttendanceWrapperWithErrors(List<Id> erroredIds, List<AttendanceWrapper> attendanceWrappersToBeUpdated){
        for (AttendanceWrapper aw : attendanceWrappersToBeUpdated) {
            if (erroredIds.contains(aw.bookingLineId)) {
                //aw.result = Results.UPDATE_FAILED;
                aw.storeResult(Results.UPDATE_FAILED, aw.bookingLineId, null);
                aw.debugString = 'Update failed on Booking_Line__c ' + aw.bookingLineId;
            }
        }
    }
    
    private static Boolean markOneBooking(AttendanceWrapper aw, Booking_Line__c bookingLine) {
        if (bookingLine.Student__c != aw.studentId) {
            //aw.result = Results.SESSION_BOOKING_NOT_MATCHED;
            aw.storeResult(Results.SESSION_BOOKING_NOT_MATCHED, bookingLine.Id, null);
            return false;
        } 
        
        Session__c sessOne = getSessionOne(bookingLine.Session__r);
        Session__c sessTwo = getSessionTwo(bookingLine.Session__r);
        System.debug('@markOneBooking - sessOne: ' + sessOne);
        System.debug('@markOneBooking - sessTwo: ' + sessTwo);
        
        if (aw.debugString == null) { aw.debugString = ''; }

        aw.bookingLineId = bookingLine.Id;
        aw.debugString += 'Booking Line Id: ' + aw.bookingLineId + ' ';
        
        Boolean sessionOnePresent = false;
        if (sessOne != null) {
            sessionOnePresent = compareSession(aw.attendance, sessOne);
            System.debug('@markOneBooking - sessionOnePresent: ' + sessionOnePresent);
            if (sessionOnePresent) {
                bookingLine.Attended__c = true;
                //aw.result = Results.REGISTERED_S1;
                aw.storeResult(Results.REGISTERED_S1, aw.bookingLineId, 1);
            } else {
                System.debug('bookingLine.Id / aw.bookingLineId' + bookingLine.Id + '/' + aw.bookingLineId);
                aw.storeResult(Results.NOT_PRESENT, aw.bookingLineId, 1);
            }
            
            aw.debugString += 'Sess 1 - ' + sessionOnePresent;
        }
        
        Boolean sessionTwoPresent = false;
        if (sessTwo != null) {
            sessionTwoPresent = compareSession(aw.attendance, sessTwo);
            System.debug('@markOneBooking - sessionTwoPresent: ' + sessionTwoPresent);
            if (sessionTwoPresent) {
                bookingLine.Second_Session_Attended__c = true;
                //aw.result = Results.REGISTERED_S2;
                aw.storeResult(Results.REGISTERED_S2, aw.bookingLineId, 2);
            } else {
                aw.storeResult(Results.NOT_PRESENT, aw.bookingLineId, 2);
            }
            
            aw.debugString += ' Sess 2 - ' + sessionTwoPresent;
        } else {
            aw.debugString += ' (no Sess 2)';
        }
        
        aw.debugString += ' ';
        aw.debugString.trim();
        
        Boolean sessionPresent = (sessionOnePresent || sessionTwoPresent);
        System.debug('@markOneBooking - sessionPresent: ' + sessionPresent);
        return (sessionPresent);
    }
    
    public static List<Id> updateBookingLines(List<Booking_Line__c> bookingLines) {
        List<Id> erroredIds = new List<Id>();
        List<Database.SaveResult> resultsList = Database.update(bookingLines, false);
        
        for (Integer i = 0; i <= resultsList.size() - 1; i++) {
            Database.SaveResult sr = resultsList.get(i);
            Id currentBookingLineId = bookingLines.get(i).Id;
            if (!sr.isSuccess()) {
                for (Database.Error err : sr.getErrors()) {
                    System.debug('@RegisterAttendance updateBookingLines: Booking Line Id: ' + currentBookingLineId + ', Error Message: ' + err.getStatusCode() + ': ' + err.getMessage());
                    erroredIds.add(currentBookingLineId);
                }
            }
        }
        
        return erroredIds;
    }
    
    @TestVisible
    private static Boolean compareSession(Attendance a, Session__c session) {
        DateTime attendanceStart = DateTime.newInstance(a.accesstime * 1000L);
        DateTime attendanceEnd = DateTime.newInstance((a.accesstime * 1000L) + (a.duration * 1000L));
        
        DateTime sessionStart = DateTime.newInstance(session.Session_Date__c, timeFromString(session.Start_Time__c, ':'));
        DateTime sessionEnd = DateTime.newInstance(session.Session_Date__c, timeFromString(session.End_Time__c, ':'));
        
        System.debug('@compareSession - attendanceStart: ' + attendanceStart);
        System.debug('@compareSession - attendanceEnd: ' + attendanceEnd);
        System.debug('@compareSession - sessionStart: ' + sessionStart);
        System.debug('@compareSession - sessionEnd: ' + sessionEnd);
        if (attendanceStart <= sessionEnd && sessionStart <= attendanceEnd) {
            return true;
        }
        
        return false;
    }
    
    @TestVisible
    private static Session__c getSessionOne(Session__c session) {
        Session__c sessionOne = null;
        if (session.Session_Date__c != null) {
            sessionOne = new Session__c();
            sessionOne.Session_Date__c = session.Session_Date__c;
            sessionOne.Start_Time__c = session.Start_Time__c;
            sessionOne.End_Time__c = session.End_Time__c;
        }
        return sessionOne;
    }
    
    @TestVisible
    private static Session__c getSessionTwo(Session__c session) {
        Session__c sessionTwo = null;
        if (session.Second_Session_Date__c != null) {
            sessionTwo = new Session__c();
            sessionTwo.Session_Date__c = session.Second_Session_Date__c;
            sessionTwo.Start_Time__c = session.Second_Session_Start_Time__c;
            sessionTwo.End_Time__c = session.Second_Session_End_Time__c;
        }
        return sessionTwo;
    }
    
    @TestVisible
    private static Time timeFromString(String str, String regex) {
        String[] splitString = str.split(regex);
        Integer hrs = Integer.valueOf(splitString[0]);
        Integer mins = Integer.valueOf(splitString[1]);
        Integer secs = Integer.valueOf(splitString[2]);
        Time t = Time.newInstance(hrs, mins, secs, 0);
        return t;
    }
    
    @TestVisible
    enum Results {
            ACCOUNT_NOT_FOUND,
            SESSION_BOOKING_NOT_MATCHED,
            NO_UNMARKED_SESSIONS_FOUND,
            REGISTERED_S1,
            REGISTERED_S2,
            NOT_PRESENT,
            UPDATE_FAILED
            }
    
    global class Response {
        @TestVisible
        Integer statusCode;
        @TestVisible
        String overallResult;
        @TestVisible
        List<ResponseLine> lines = new List<ResponseLine>();
        
        Response(Integer statusCode, String body) {
            this.overallResult = body;
            this.statusCode = statusCode;
            
            RestResponse res = RestContext.response;
            res.statusCode = statusCode;
        }
    }
    
    private static Response buildNothingToMarkResponse(List<AttendanceWrapper> aw){
        return new Response(200, 'Processed but everyone was already marked');
    }
    
    private static Response buildResponseFromMap(Map<AttendanceWrapper, List<Booking_Line__c>> attendanceBookingLineMap){
        Response response = new Response(200, 'Processed');
        
        for(AttendanceWrapper a : attendanceBookingLineMap.keyset()){
            for (Booking_Line__c lineBeingMarked : attendanceBookingLineMap.get(a)) {
                ResponseLine rl = new ResponseLine();
                rl.attendanceId = a.attendance.id;
                rl.username = a.attendance.username;
                // rl.result = a.result;
                rl.allResults = a.allResults;
                rl.debugString = a.debugString;
                rl.sfAccountId = a.studentId;
                rl.sfInstanceId = a.instanceId;
                rl.sfBookingId = lineBeingMarked.Id;
                
                response.lines.add(rl);
            }
        }
        
        return response;
    }
    
    @TestVisible
    class ResponseLine {
        @TestVisible
        private Integer attendanceId;
        @TestVisible
        private String username;
        @TestVisible
        private String sfAccountId;
        @TestVisible
        private String sfInstanceId;
        @TestVisible
        private String sfBookingId;
        // @TestVisible
        // private Results result;
        @TestVisible
        private List<BookingLineResults> allResults;
        @TestVisible
        private String debugString;
    }
    
    private static List<AttendanceWrapper> findAccountsByHubAccount(String lookupEmail, Attendance att) {
        List<AttendanceWrapper> hubAccountMatches = new List<AttendanceWrapper>();
        
        List<String> idsFromHubAccount = getAccountIdsByHubAccountEmail(lookupEmail);
        for (String idFromHubAccount : idsFromHubAccount) {
            if (idFromHubAccount != null) {
                AttendanceWrapper link = new AttendanceWrapper(att);
                link.studentId = idFromHubAccount;
                hubAccountMatches.add(link);
            }
        }
        
        return hubAccountMatches;
    }
       
    private static List<AttendanceWrapper> findAccountsByPersonEmail(String lookupEmail, Attendance att) {
        List<AttendanceWrapper> accountMatches = new List<AttendanceWrapper>();
        
        List<String> idsFromAccount = getAccountIdsByPreferredEmail(lookupEmail, att.sfInstanceId);
        for (String idFromAccount : idsFromAccount) {
            if (idFromAccount != null) {
                AttendanceWrapper link = new AttendanceWrapper(att);
                link.studentId = idFromAccount;
                accountMatches.add(link);
            }
        }
        
        return accountMatches;
    }
    
    private static Set<AttendanceWrapper> matchAttendanceToAccountIds(Attendance att) {
        Set<AttendanceWrapper> matches = new Set<AttendanceWrapper>();
        
        // all checks will use the same email address from incoming message
        String lookupEmail = att.username;
        
        // work through student lookup rules, returning each match
        // HubAccount object may not be in prod yet so check if it is accessible before running rule#1
        Boolean hubAccountObjectExists = Type.forName('Hub_Account__c') != null;
        if (hubAccountObjectExists) {
            // Rule#1 matches by Hub_Account__c Username
            matches.addAll(findAccountsByHubAccount(lookupEmail, att));
        }
        
        // Rule#2 matches by Account.PersonEmail (preferred email indicated on UI)
        matches.addAll(findAccountsByPersonEmail(lookupEmail, att));
        
        // return all matched records, or an empty list0
        return matches;
    }
    
    private static List<String> getAccountIdsByHubAccountEmail(String email) {

        String query = 'select Student__c from Hub_Account__c where Hub_Username__c = :email';
        List<Hub_Account__c> matches = Database.query(String.escapeSingleQuotes(query));
        
        List<String> accountIds = new List<String>();
        for (Hub_Account__c match : matches) {
        accountIds.add(match.Student__c);
        }
        
        return accountIds;
    }
    
    private static List<String> getAccountIdsByPreferredEmail(String email, String instanceId) {
        String query = 'select Id from Account where Id in (select Student__c from Booking_Line__c where Instance__c = :instanceId) and PersonEmail =  :email';
        List<Account> matches = Database.query(String.escapeSingleQuotes(query));
        
        List<String> accountIds = new List<String>();
        for (Account match : matches) {
            accountIds.add(match.Id);
        }
        
        return accountIds;
    }
      
    private static List<Instance__c> getInstanceByPfRef(String pfRef) {
        String query = 'SELECT Id, Instance_ID__c FROM Instance__c where Instance_ID__c = :pfRef';
        List<Instance__c> instances = Database.query(String.escapeSingleQuotes(query));
        return instances;
    }
    
    @TestVisible
    class AttendanceWrapper {
        @TestVisible
        AttendanceWrapper(Attendance a) {
            this.attendance = a;
            this.instanceId = a.sfInstanceId;
        }
        
        @TestVisible
        Attendance attendance;
        @TestVisible
        String studentId;
        @TestVisible
        String instanceId;
        @TestVisible
        String bookingLineId;
        String debugString;

        //Results result;
        List<BookingLineResults> allResults = new List<BookingLineResults>();

        public void storeResult(Results result, String bookingLineId, Integer sessionNumber){
            allResults.add(new BookingLineResults(result, bookingLineId, sessionNumber));
        }
        
        @TestVisible
        public Boolean equals(Object obj) {
            if (obj instanceof AttendanceWrapper) {
                AttendanceWrapper o = (AttendanceWrapper) obj;
                if ((studentId == o.studentId) && (instanceId == o.instanceId) && (bookingLineId == o.bookingLineId)) {
                    return attendance.accesstime == o.attendance.accesstime;
                }
            }
            
            return false;
        }
        
        @TestVisible
        public Integer hashCode() {
            String hashString = (String) studentId + '|' + (String) instanceId + '|' + (String) bookingLineId;
            return System.hashCode(hashString);
        }
    }

    @TestVisible
    global class BookingLineResults {

        @TestVisible
        Results result;
        @TestVisible
        String bookingLineId;
        @TestVisible
        Integer sessionNumber;

        BookingLineResults(Results result, String bookingLineId, Integer sessionNumber){
            this.result = result;
            this.bookingLineId = bookingLineId;
            this.sessionNumber = sessionNumber;
        }
    }
    
    global class Session {
        @TestVisible
        String startDt;
        @TestVisible
        String endDt;
        @TestVisible
        String instanceId;
        @TestVisible
        List<Student> students;
        @TestVisible
        List<Attendance> attendance;
    }
    
    @TestVisible
    class Student {
        String username;
    }
    
    @TestVisible
    class Attendance {
        @TestVisible
        transient String sfInstanceId;
        String firstname;
        String lastname;
        @TestVisible
        String username;
        Integer id;
        String idnumber;
        @TestVisible
        Integer accesstime;
        @TestVisible
        Integer duration;
    }
}