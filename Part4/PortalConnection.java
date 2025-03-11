
import java.sql.*; // JDBC stuff.
import java.util.Properties;

public class PortalConnection {

    // Set this to e.g. "portal" if you have created a database named portal
    // Leave it blank to use the default database of your database user
    static final String DBNAME = "portal";
    // For connecting to the portal database on your local machine
    static final String DATABASE = "jdbc:postgresql://localhost/"+DBNAME;
    static final String USERNAME = "postgres";
    static final String PASSWORD = "postgres";

    // This is the JDBC connection object you will be using in your methods.
    private Connection conn;

    public PortalConnection() throws SQLException, ClassNotFoundException {
        this(DATABASE, USERNAME, PASSWORD);  
    }

    // Initializes the connection, no need to change anything here
    public PortalConnection(String db, String user, String pwd) throws SQLException, ClassNotFoundException {
        Class.forName("org.postgresql.Driver");
        Properties props = new Properties();
        props.setProperty("user", user);
        props.setProperty("password", pwd);
        conn = DriverManager.getConnection(db, props);
    }


    // Register a student on a course, returns a tiny JSON document (as a String)
    public String register(String student, String courseCode){
      try(PreparedStatement ps = conn.prepareStatement(
        "INSERT INTO Registrations (student, course) VALUES (?, ?)");){

        ps.setString(1, student);
        ps.setString(2, courseCode);
        ps.executeUpdate();

        return "{\"success\":true}";

      } catch (SQLException e) {
        return "{\"success\":false, \"error\":\""+getError(e)+"\"}";
      }
    }

    // Unregister a student from a course, returns a tiny JSON document (as a String)
    public String unregister(String student, String courseCode){
      // in webapp, write ' OR 1=1;-- for student id, ' OR 1=1;-- for course code
      try(PreparedStatement ps = conn.prepareStatement(
        "DELETE FROM Registrations WHERE student=? AND course=?")){

        ps.setString(1, student);
        ps.setString(2, courseCode);
        int r = ps.executeUpdate();

        if(r > 0){
          return "{\"success\":true}";
        }else{
          return "{\"success\":false, \"error\":\"student not registrered on course\"}";
        }
      } catch (SQLException e) {
        return "{\"success\":false, \"error\":\""+getError(e)+"\"}";
      }
    }

    // Return a JSON document containing lots of information about a student, it should validate against the schema found in information_schema.json
    public String getInfo(String student) throws SQLException{
        // "SELECT jsonb_build_object('student',idnr,'name',name) AS jsondata FROM BasicInformation WHERE idnr=?"
        try(PreparedStatement st = conn.prepareStatement("SELECT json_build_object(\r\n" + //
                    "    'student', s.idnr,\r\n" + //
                    "    'name', s.name, \r\n" + //
                    "    'login', s.login,\r\n" + //
                    "    'program', s.program,\r\n" + //
                    "    'branch', sb.branch,\r\n" + //
                    "    'finished', \r\n" + //
                    "        (SELECT json_agg(\r\n" + //
                    "            json_build_object(\r\n" + //
                    "                'course', coursename,\r\n" + //
                    "                'code', course,\r\n" + //
                    "                'credits', credits,\r\n" + //
                    "                'grade', grade))\r\n" + //
                    "        FROM FinishedCourses\r\n" + //
                    "        WHERE student = s.idnr),\r\n" + //
                    "    'registered', \r\n" + //
                    "        (SELECT json_agg(\r\n" + //
                    "            json_build_object(\r\n" + //
                    "                'course', c.name,\r\n" + //
                    "                'code', r.course,\r\n" + //
                    "                'status', r.status,\r\n" + //
                    "                'position', wl.position))\r\n" + //
                    "        FROM Registrations AS r\r\n" + //
                    "        LEFT JOIN Courses AS c ON r.course = c.code\r\n" + //
                    "        LEFT JOIN WaitingList AS wl ON r.student = wl.student AND r.course = wl.course\r\n" + //
                    "        WHERE r.student = s.idnr),\r\n" + //
                    "    'seminarCourses', ptg.seminarcourses,\r\n" + //
                    "    'mathCredits', ptg.mathcredits,\r\n" + //
                    "    'totalCredits', ptg.totalcredits,\r\n" + //
                    "    'canGraduate', ptg.qualified\r\n" + //
                    "    ) AS jsondata\r\n" + //
                    "FROM Students AS s \r\n" + //
                    "LEFT JOIN StudentBranches AS sb ON sb.student = s.idnr\r\n" + //
                    "LEFT JOIN PathToGraduation AS ptg ON ptg.student = s.idnr\r\n" + //
                    "WHERE s.idnr=?;"
);){
            st.setString(1, student);
            
            ResultSet rs = st.executeQuery();
            
            if(rs.next())
              return rs.getString("jsondata");
            else
              return "{\"student\":\"does not exist :(\"}"; 
            
        } 
    }

    // This is a hack to turn an SQLException into a JSON string error message. No need to change.
    public static String getError(SQLException e){
       String message = e.getMessage();
       int ix = message.indexOf('\n');
       if (ix > 0) message = message.substring(0, ix);
       message = message.replace("\"","\\\"");
       return message;
    }
}