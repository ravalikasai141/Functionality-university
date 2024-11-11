@isTest
public class RegisterAttendanceTest {
    //https://bpp-13fd3e55182--noahuat.lightning.force.com/lightning/setup/ApexClasses/page?address=%2F01pg0000001jVtJ
    static RegisterAttendance.Session sessionBuilder(
        String iStartDt,
        String iEndDt,
        String iInstanceId,
        List<RegisterAttendance.Student> iStudents,
        List<RegisterAttendance.Attendance> iAttendance
    ) {
        RegisterAttendance.Session sess = new RegisterAttendance.Session();
        
        sess.startDt = iStartDt;
        sess.endDt = iEndDt;
        sess.instanceId = iInstanceId;
        sess.students = iStudents;
        sess.attendance = iAttendance;
        
        return sess;
    }
    
    static void setupASessionBooking(Instance__c inst, Session__c sess, Account student) {
        Product2 prod = new Product2();
        prod.Name = 'Product2 for session';
        insert prod;
        
        inst.Product__c = prod.Id;
        insert inst;
        
        if (sess.BPP_PF_SessionId__c == null) {
            sess.BPP_PF_SessionId__c = 'default-value-guid-here';
        }
        if (sess.Session_Capacity__c == null) {
            sess.Session_Capacity__c = 1000;
        }
        sess.Instance__c = inst.Id;
        insert sess;
        
        Database.DMLOptions dbDML = new Database.DMLOptions(); 
        dbDML.DuplicateRuleHeader.allowSave = true;
        dbDML.DuplicateRuleHeader.runAsCurrentUser = true;
        
        Account clientAccount = TestDataFactory.createAccount(false, true, null, 0);
        Database.insert(clientAccount, dbDML);
        
        Account studentAccount;
        if (student == null) {
            studentAccount = TestDataFactory.createAccount(false, true, clientAccount.Id, 1);
        } else {
            studentAccount = student;
            studentAccount.Client__c = clientAccount.Id;
        }
        Database.insert(studentAccount, dbDML);
        
        country_list__c cntry = new country_list__c(Name = 'United Kingdom', ISO_Code__c = 'GBR', country_code_2__c = 'GB');
        insert cntry;
        
        List<Address__c> addresses = new List<Address__c>();
        addresses.add(TestDataFactory.createAddress(false, 0, clientAccount, cntry, true, true));
        addresses.add(TestDataFactory.createAddress(false, 1, studentAccount, cntry, true, true));
        Database.insert(addresses, dbDML);
        
        PricebookEntry pbe = TestDataFactory.createPricebookEntry(false, prod, null);
        insert pbe;
        
        Order order = TestDataFactory.createOrder(false, 0, clientAccount, null, addresses.get(0));
        insert order;
        
        OrderItem orderItem = new OrderItem();
        orderItem.OrderId = order.Id;
        orderItem.Product2Id = prod.Id;
        orderItem.SBQQ__ChargeType__c = 'One-Time';
        orderItem.PricebookEntryId = pbe.Id;
        orderItem.UnitPrice = 1;
        orderItem.Quantity = 1;
        insert orderItem;
        
        order.Status = 'Activated';
        update order;
        
        Booking__c booking = new Booking__c();
        booking.Order__c = order.Id;
        booking.Instance__c = inst.Id;
        booking.Account__c = studentAccount.Client__c;
        booking.Student__c = studentAccount.Id;
        insert booking;
        
        Booking_Line__c bkngline = new Booking_Line__c();
        bkngline.Instance__c = inst.Id;
        bkngline.Session__c = sess.Id;
        bkngline.Booking__c = booking.Id;
        bkngline.blng_Order__c = order.Id;
        bkngline.Student__c = studentAccount.Id;
        insert bkngline;
    }
    
    static Account studentAccount(String personEmail) {
        Account acc = new Account();
        acc.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Student Account').getRecordTypeId();
        acc.FirstName = 'Test account';
        acc.LastName = 'Student';
        acc.Preferred_Phone__pc = 'Mobile';
        acc.Preferred_Email__pc = 'Personal';
        acc.PersonEmail = personEmail;
        acc.Personal_Email__pc = personEmail;
        acc.PersonMobilePhone = '+447716123748';
        return acc;
    }
    
    @isTest
    static void getSessionOneDateMatch() {
        Session__c input = new Session__c();
        input.Session_Date__c = Date.newInstance(2020, 2, 22);
        input.Start_Time__c = '10:00';
        input.End_Time__c = '11:00';
        input.Second_Session_Date__c = Date.newInstance(2020, 2, 25);
        input.Second_Session_Start_Time__c = '13:00';
        input.Second_Session_End_Time__c = '14:00';
        
        Session__c actual = RegisterAttendance.getSessionOne(input);
        System.assertEquals(input.Session_Date__c, actual.Session_Date__c, 'Did not get expected Date for first Session');
    }
    
    @isTest
    static void getSessionOneStartTimeMatch() {
        Session__c input = new Session__c();
        input.Session_Date__c = Date.newInstance(2020, 2, 22);
        input.Start_Time__c = '10:00';
        input.End_Time__c = '11:00';
        input.Second_Session_Date__c = Date.newInstance(2020, 2, 25);
        input.Second_Session_Start_Time__c = '13:00';
        input.Second_Session_End_Time__c = '14:00';
        
        Session__c actual = RegisterAttendance.getSessionOne(input);
        System.assertEquals(input.Start_Time__c, actual.Start_Time__c, 'Did not get expected StartTime for first Session');
    }
    
    @isTest
    static void getSessionOneEndTimeMatch() {
        Session__c input = new Session__c();
        input.Session_Date__c = Date.newInstance(2020, 2, 22);
        input.Start_Time__c = '10:00';
        input.End_Time__c = '11:00';
        input.Second_Session_Date__c = Date.newInstance(2020, 2, 25);
        input.Second_Session_Start_Time__c = '13:00';
        input.Second_Session_End_Time__c = '14:00';
        
        Session__c actual = RegisterAttendance.getSessionOne(input);
        System.assertEquals(input.End_Time__c, actual.End_Time__c, 'Did not get expected EndTime for first Session');
    }
    
    @isTest
    static void getSessionTwoDateMatch() {
        Session__c input = new Session__c();
        input.Session_Date__c = Date.newInstance(2020, 2, 22);
        input.Start_Time__c = '10:00';
        input.End_Time__c = '11:00';
        input.Second_Session_Date__c = Date.newInstance(2020, 2, 25);
        input.Second_Session_Start_Time__c = '13:00';
        input.Second_Session_End_Time__c = '14:00';
        
        Session__c actual = RegisterAttendance.getSessionTwo(input);
        System.assertEquals(
            input.Second_Session_Date__c,
            actual.Session_Date__c,
            'Did not get expected Date for second Session'
        );
    }
    
    @isTest
    static void getSessionTwoStartTimeMatch() {
        Session__c input = new Session__c();
        input.Session_Date__c = Date.newInstance(2020, 2, 22);
        input.Start_Time__c = '10:00';
        input.End_Time__c = '11:00';
        input.Second_Session_Date__c = Date.newInstance(2020, 2, 25);
        input.Second_Session_Start_Time__c = '13:00';
        input.Second_Session_End_Time__c = '14:00';
        
        Session__c actual = RegisterAttendance.getSessionTwo(input);
        System.assertEquals(
            input.Second_Session_Start_Time__c,
            actual.Start_Time__c,
            'Did not get expected StartTime for second Session'
        );
    }
    
    @isTest
    static void getSessionTwoEndTimeMatch() {
        Session__c input = new Session__c();
        input.Session_Date__c = Date.newInstance(2020, 2, 22);
        input.Start_Time__c = '10:00';
        input.End_Time__c = '11:00';
        input.Second_Session_Date__c = Date.newInstance(2020, 2, 25);
        input.Second_Session_Start_Time__c = '13:00';
        input.Second_Session_End_Time__c = '14:00';
        
        Session__c actual = RegisterAttendance.getSessionTwo(input);
        System.assertEquals(
            input.Second_Session_End_Time__c,
            actual.End_Time__c,
            'Did not get expected EndTime for second Session'
        );
    }
    
    @isTest
    static void timeFromStringWorks() {
        Time expected = Time.newInstance(10, 10, 10, 0);
        String input = '10:10:10';
        String regex = ':';
        
        Time actual = RegisterAttendance.timeFromString(input, regex);
        System.assertEquals(expected, actual, 'Unexpected Time parsed from String');
    }
    
    @isTest
    static void compareSessionTrueWhenOverlap() {
        RegisterAttendance.Attendance a = new RegisterAttendance.Attendance();
        a.accesstime = 1613427072; // Monday, February 15, 2021 10:11:12 PM GMT
        a.duration = 120; // 120s - two minutes
        
        Session__c session = new Session__c();
        session.Session_Date__c = Date.newInstance(2021, 2, 15);
        session.Start_Time__c = '22:11:10';
        session.End_Time__c = '22:51:10';
        
        //expect this to = true, as accesstime+duration is inside the sessions boundaries
        Boolean actual = RegisterAttendance.compareSession(a, session);
        System.assertEquals(actual, true, 'Expected attendance to be marked true');
    }
    
    @isTest
    static void compareSessionFalseWhenNoOverlap() {
        RegisterAttendance.Attendance a = new RegisterAttendance.Attendance();
        a.accesstime = 1613427072; // Monday, February 15, 2021 10:11:12 PM GMT
        a.duration = 120; // 120s - two minutes
        
        Session__c session = new Session__c();
        session.Session_Date__c = Date.newInstance(2021, 2, 15);
        session.Start_Time__c = '10:11:10';
        session.End_Time__c = '10:51:10';
        
        //expect this to fail as accesstime is PM but session is AM
        Boolean actual = RegisterAttendance.compareSession(a, session);
        System.assertEquals(actual, false, 'Expected attendance to be marked false');
    }
    
    @isTest
    static void dedupeForAttendanceWrapperRecognisedDifference() {
        RegisterAttendance.Attendance a1 = new RegisterAttendance.Attendance();
        a1.sfInstanceId = 'y';
        
        RegisterAttendance.AttendanceWrapper aw1 = new RegisterAttendance.AttendanceWrapper(a1);
        aw1.studentId = 'x';
        aw1.bookingLineId = 'z';
        
        RegisterAttendance.Attendance a2 = new RegisterAttendance.Attendance();
        a2.sfInstanceId = 'b';
        
        RegisterAttendance.AttendanceWrapper aw2 = new RegisterAttendance.AttendanceWrapper(a2);
        aw1.studentId = 'a';
        aw1.bookingLineId = 'c';
        
        System.assert(aw1.equals(aw2) == false, 'Wrappers wrongly recognised as the same');
    }
    
    @isTest
    static void dedupeForAttendanceWrapperRecognisesDifferentObject() {
        RegisterAttendance.Attendance a1 = new RegisterAttendance.Attendance();
        a1.sfInstanceId = 'y';
        
        RegisterAttendance.AttendanceWrapper aw1 = new RegisterAttendance.AttendanceWrapper(a1);
        aw1.studentId = 'x';
        aw1.bookingLineId = 'z';
        
        String other = 'hi';
        
        System.assert(aw1.equals(other) == false, 'Wrappers wrongly recognised as the same');
    }
    
    @isTest
    static void attendanceWrapperHashCodeWorks() {
        RegisterAttendance.Attendance a1 = new RegisterAttendance.Attendance();
        a1.sfInstanceId = 'y';
        
        RegisterAttendance.AttendanceWrapper aw1 = new RegisterAttendance.AttendanceWrapper(a1);
        aw1.studentId = 'x';
        aw1.bookingLineId = 'z';
        
        Integer actual = aw1.hashCode();
        
        System.assert(actual != null, 'HashCode failed to generate');
    }
    
    @isTest
    static void emptyAttendanceGivesCode204() {
        RestResponse res = new RestResponse();
        RestContext.response = res;
        
        RegisterAttendance.Response resp = RegisterAttendance.handleAttendance(
            sessionBuilder(null, null, null, null, new List<RegisterAttendance.Attendance>())
        );
        System.assertEquals(resp.statusCode, 204, 'Unexpected HttpStatus response code');
    }
    
    @isTest
    static void noInstanceGivesCode404() {
        RestResponse res = new RestResponse();
        RestContext.response = res;
        
        RegisterAttendance.Attendance a = new RegisterAttendance.Attendance();
        List<RegisterAttendance.Attendance> aa = new List<RegisterAttendance.Attendance>();
        aa.add(a);
        
        RegisterAttendance.Response resp = RegisterAttendance.handleAttendance(sessionBuilder(null, null, 'abc', null, aa));
        System.assertEquals(resp.statusCode, 404, 'Unexpected HttpStatus response code');
    }
    
    @isTest
    static void noBookingsGivesMessage() {
        RestResponse res = new RestResponse();
        RestContext.response = res;
        
        Product2 pete = new Product2();
        pete.name = 'Peter';
        insert pete;
        
        Instance__c dummy = new Instance__c();
        dummy.Instance_ID__c = 'abc';
        dummy.Product__c = pete.Id;
        insert dummy;
        
        RegisterAttendance.Attendance a = new RegisterAttendance.Attendance();
        List<RegisterAttendance.Attendance> aa = new List<RegisterAttendance.Attendance>();
        aa.add(a);
        
        RegisterAttendance.Response resp = RegisterAttendance.handleAttendance(sessionBuilder(null, null, 'abc', null, aa));
        Boolean result = resp.overallResult.startsWithIgnoreCase('No booking lines on this instance');
        System.assert(
            result,
            'Response BODY actual: ' +
            resp.overallResult +
            ' expected: No booking lines on this instance...'
        );
    }
    
    @isTest
    static void responseForMatchedInstance() {
        RestResponse res = new RestResponse();
        RestContext.response = res;
        
        Instance__c dummy = new Instance__c();
        dummy.Instance_ID__c = 'abc';
        
        Session__c session = new Session__c();
        session.Session_Date__c = Date.newInstance(2021, 2, 15);
        session.Start_Time__c = '10:11:10';
        session.End_Time__c = '10:51:10';
        
        setupASessionBooking(dummy, session, null);
        
        RegisterAttendance.Attendance a = new RegisterAttendance.Attendance();
        a.accesstime = 1613383872; // Monday, February 15, 2021 10:11:12 AM GMT
        a.duration = 120; // 120s - two minutes
        
        List<RegisterAttendance.Attendance> aa = new List<RegisterAttendance.Attendance>();
        aa.add(a);
        
        //startdt, enddt, instanceid, list<Student>, list<Attendance>
        RegisterAttendance.Response resp = RegisterAttendance.handleAttendance(sessionBuilder(null, null, 'abc', null, aa));
        for (RegisterAttendance.ResponseLine line : resp.lines) {
            String actual = line.sfInstanceId;
            System.assertEquals(dummy.Id, actual, 'Instance ID didnt match expected for a booking');
        }
    }
    
    @isTest
    static void responseForUnmatchedInstance() {
        RestResponse res = new RestResponse();
        RestContext.response = res;
        
        Instance__c dummy = new Instance__c();
        dummy.Instance_ID__c = 'abc';
        
        Session__c session = new Session__c();
        session.Session_Date__c = Date.newInstance(2021, 2, 15);
        session.Start_Time__c = '10:11:10';
        session.End_Time__c = '10:51:10';
        
        setupASessionBooking(dummy, session, null);
        
        RegisterAttendance.Attendance a = new RegisterAttendance.Attendance();
        a.accesstime = 1613383872; // Monday, February 15, 2021 10:11:12 AM GMT
        a.duration = 120; // 120s - two minutes
        
        List<RegisterAttendance.Attendance> aa = new List<RegisterAttendance.Attendance>();
        aa.add(a);
        
        //startdt, enddt, instanceid, list<Student>, list<Attendance>
        RegisterAttendance.Response resp = RegisterAttendance.handleAttendance(sessionBuilder(null, null, 'xyz', null, aa));
        for (RegisterAttendance.ResponseLine line : resp.lines) {
            String actual = line.sfInstanceId;
            System.assert(dummy.Id != actual, 'Instance ID matched when not expected to');
        }
    }
    
    @isTest
    static void responseForMatchedInstanceAndStudentByPersonEmail() {
        RestResponse res = new RestResponse();
        RestContext.response = res;
        
        Instance__c dummy = new Instance__c();
        dummy.Instance_ID__c = 'abc';
        
        Session__c session = new Session__c();
        session.Session_Date__c = Date.newInstance(2021, 2, 15);
        session.Start_Time__c = '10:11:10';
        session.End_Time__c = '10:51:10';
        
        //TODO: generate an Account with Account.PersonEmail that matches
        Account acc = studentAccount('mymatcheduser@bpp.com');
        setupASessionBooking(dummy, session, acc);
        
        RegisterAttendance.Attendance a = new RegisterAttendance.Attendance();
        a.accesstime = 1613383872; // Monday, February 15, 2021 10:11:12 AM GMT
        a.duration = 120; // 120s - two minutes
        a.username = 'mymatcheduser@bpp.com';
        
        List<RegisterAttendance.Attendance> aa = new List<RegisterAttendance.Attendance>();
        aa.add(a);
        
        //startdt, enddt, instanceid, list<Student>, list<Attendance>
        RegisterAttendance.Response resp = RegisterAttendance.handleAttendance(sessionBuilder(null, null, 'abc', null, aa));
        for (RegisterAttendance.ResponseLine line : resp.lines) {
            String actual = line.sfAccountId;
            System.assertEquals(acc.Id, actual, 'Account ID didnt match one expected for booking');
        }
    }
    
    @isTest
    static void responseForMatchedInstanceWrongTiming() {
        RestResponse res = new RestResponse();
        RestContext.response = res;
        
        Instance__c dummy = new Instance__c();
        dummy.Instance_ID__c = 'abc';
        
        // this one is not intended to match in this test
        Session__c session = new Session__c();
        session.Session_Date__c = Date.newInstance(2021, 6, 1);
        session.Start_Time__c = '10:11:10';
        session.End_Time__c = '10:51:10';
        
        Account acc = studentAccount('mymatcheduser@bpp.com');
        setupASessionBooking(dummy, session, acc);
        
        RegisterAttendance.Attendance a = new RegisterAttendance.Attendance();
        a.accesstime = 1613383872; // Monday, February 15, 2021 10:11:12 AM GMT
        a.duration = 120; // 120s - two minutes
        a.username = 'mymatcheduser@bpp.com';
        
        List<RegisterAttendance.Attendance> aa = new List<RegisterAttendance.Attendance>();
        aa.add(a);
        
        //startdt, enddt, instanceid, list<Student>, list<Attendance>
        RegisterAttendance.Response resp = RegisterAttendance.handleAttendance(sessionBuilder(null, null, 'abc', null, aa));
        for (RegisterAttendance.ResponseLine line : resp.lines) {
            for (RegisterAttendance.BookingLineResults bookingLineResult : line.allResults){
                
                RegisterAttendance.Results actual = bookingLineResult.result;
                
                System.assertEquals(
                    RegisterAttendance.Results.NOT_PRESENT,
                    actual,
                    'Student should not be registered as present'
                );
            }
        }
    }
    
    /***
    * Hub_Account__c won't be in prod when this code goes 
    * in  so not completing this test case currently but it 
    * should be done later!
    * 
    @isTest
    static void responseForMatchedInstanceAndStudentByHubAccount() {
    RestResponse res = new RestResponse();
    RestContext.response = res;
    
    Instance__c dummy = new Instance__c();
    dummy.Instance_ID__c = 'abc';
    
    Session__c session = new Session__c();
    session.Session_Date__c = Date.newInstance(2021, 2, 15);
    session.Start_Time__c = '10:11:10';
    session.End_Time__c = '10:51:10';
    
    //TODO: generate an Account with Hub_account__c that matches
    //
    setupASessionBooking(dummy, session, null);
    
    RegisterAttendance.Attendance a = new RegisterAttendance.Attendance();
    a.accesstime = 1613383872; // Monday, February 15, 2021 10:11:12 AM GMT
    a.duration = 120; // 120s - two minutes
    a.username = 'mymatcheduser@bpp.com';
    
    List<RegisterAttendance.Attendance> aa = new List<RegisterAttendance.Attendance>();
    aa.add(a);
    
    //startdt, enddt, instanceid, list<Student>, list<Attendance>
    RegisterAttendance.Response resp = RegisterAttendance.handleAttendance(sessionBuilder(null, null, 'abc', null, aa));
    for (RegisterAttendance.ResponseLine line : resp.lines) {
    String actual = line.sfInstanceId;
    System.assertEquals(dummy.Id, actual, 'Instance ID didnt match expected for a booking');
    }
    }
    */
}