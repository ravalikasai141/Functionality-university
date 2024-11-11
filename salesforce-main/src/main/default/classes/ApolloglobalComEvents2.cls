public class ApolloglobalComEvents2 {
   
    public class EventSOAP {
        public String endpoint_x = 'https://staging.bpp.com/web-service/EventService/services/Event/';
        public Map<String,String> inputHttpHeaders_x;
        public Map<String,String> outputHttpHeaders_x;
        public String clientCertName_x;
        public String clientCert_x;
        public String clientCertPasswd_x;
        public Integer timeout_x;
        private String[] ns_map_type_info = new String[]{'http://apolloglobal.com/events', 'apolloglobalComEvents2', 'http://www.apolloglobal.com/events/', 'ApolloglobalComEvents2'};
        
        public ApolloglobalComEvents2.Response  AddEvent(String eventId,String eventName,String eventDescription,String eventType,String eventProductLevel,String eventQualification,String eventSchool,String eventMaxCapacity,String eventCurrentCapacity,String evemtDate,string evemtTime,string evemtDuration,String evemtLocation,String evemtSubLocation) {
          
            ApolloglobalComEvents2.Event request_x = new ApolloglobalComEvents2.Event();
            ApolloglobalComEvents2.Response response_x;
            request_x.eventId = eventId;
            request_x.eventName = eventName;
            request_x.eventDescription = eventDescription;
            request_x.eventType = eventType;
            request_x.eventProductLevel = eventProductLevel;
            request_x.eventQualification = eventQualification;
            request_x.eventSchool = eventSchool;
            request_x.eventMaxCapacity = eventMaxCapacity;
            request_x.eventCurrentCapacity = eventCurrentCapacity;
            request_x.evemtDate = evemtDate;
            request_x.evemtTime = evemtTime;
            request_x.evemtDuration = evemtDuration;
            request_x.evemtLocation = evemtLocation;
            request_x.evemtSubLocation = evemtSubLocation;
            Map<String, ApolloglobalComEvents2.Response> response_map_x = new Map<String, ApolloglobalComEvents2.Response>();
            response_map_x.put('response_x', response_x);
            WebServiceCallout.invoke(
              this,
              request_x,
              response_map_x,
              new String[]{endpoint_x,
              'http://www.apolloglobal.com/events/AddEvent',
              'http://apolloglobal.com/events',
              'EventMessage',
              'http://apolloglobal.com/events',
              'ResponseMessage',
              'apolloglobalComEvents2.Response'}
            );
            
            response_x = response_map_x.get('response_x');
            return response_x;
        }
    
    }
    
    
    public class Event {
        public String eventId;
        public String eventName;
        public String eventDescription;
        public String eventType;
        public String eventProductLevel;
        public String eventQualification;
        public String eventSchool;
        public String eventMaxCapacity;
        public String eventCurrentCapacity;
        public String evemtDate;
        public String evemtTime;
        public String evemtDuration;
        public String evemtLocation;
        public String evemtSubLocation;
        private String[] eventId_type_info = new String[]{'eventId','http://www.w3.org/2001/XMLSchema','string','1','1','false'};
        private String[] eventName_type_info = new String[]{'eventName','http://www.w3.org/2001/XMLSchema','string','1','1','false'};
        private String[] eventDescription_type_info = new String[]{'eventDescription','http://www.w3.org/2001/XMLSchema','string','1','1','false'};
        private String[] eventType_type_info = new String[]{'eventType','http://www.w3.org/2001/XMLSchema','string','1','1','false'};
        private String[] eventProductLevel_type_info = new String[]{'eventProductLevel','http://www.w3.org/2001/XMLSchema','string','1','1','false'};
        private String[] eventQualification_type_info = new String[]{'eventQualification','http://www.w3.org/2001/XMLSchema','string','1','1','false'};
        private String[] eventSchool_type_info = new String[]{'eventSchool','http://www.w3.org/2001/XMLSchema','string','1','1','false'};
        private String[] eventMaxCapacity_type_info = new String[]{'eventMaxCapacity','http://www.w3.org/2001/XMLSchema','int','1','1','false'};
        private String[] eventCurrentCapacity_type_info = new String[]{'eventCurrentCapacity','http://www.w3.org/2001/XMLSchema','int','1','1','false'};
        private String[] evemtDate_type_info = new String[]{'evemtDate','http://www.w3.org/2001/XMLSchema','date','1','1','false'};
        private String[] evemtTime_type_info = new String[]{'evemtTime','http://www.w3.org/2001/XMLSchema','time','1','1','false'};
        private String[] evemtDuration_type_info = new String[]{'evemtDuration','http://www.w3.org/2001/XMLSchema','time','1','1','false'};
        private String[] evemtLocation_type_info = new String[]{'evemtLocation','http://www.w3.org/2001/XMLSchema','string','1','1','false'};
        private String[] evemtSubLocation_type_info = new String[]{'evemtSubLocation','http://www.w3.org/2001/XMLSchema','string','1','1','false'};
        private String[] apex_schema_type_info = new String[]{'http://apolloglobal.com/events','true','false'};
        private String[] field_order_type_info = new String[]{'eventId','eventName','eventDescription','eventType','eventProductLevel','eventQualification','eventSchool','eventMaxCapacity','eventCurrentCapacity','evemtDate','evemtTime','evemtDuration','evemtLocation','evemtSubLocation'};
    }
    
    public class Response {
        public String StatusCode;
        public String Message;
        private String[] StatusCode_type_info = new String[]{'StatusCode','http://www.w3.org/2001/XMLSchema','string','1','1','false'};
        private String[] Message_type_info = new String[]{'Message','http://www.w3.org/2001/XMLSchema','string','1','1','false'};
        private String[] apex_schema_type_info = new String[]{'http://apolloglobal.com/events','true','false'};
        private String[] field_order_type_info = new String[]{'StatusCode','Message'};
    }
    
    }