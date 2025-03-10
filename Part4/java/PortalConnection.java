
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
        "INSERT INTO Registrations (student, course) VALUES (?, ?)");) {
          ps.setString(1, student);
          ps.setString(2, courseCode);
          int rowsAffected = ps.executeUpdate();

          if (rowsAffected > 0) {
            return "{\"success\":true}";
          } else {
            return "{\"success\":false, \"error\":\"No rows affected\"}";
          }
        } catch (SQLException e) {
          return "{\"success\":false, \"error\":\""+getError(e)+"\"}";
       }          
    }

// Unregister a student from a course, returns a tiny JSON document (as a String)
public String unregister(String student, String courseCode){
  // in webapp, write ' OR 1=1;-- for student id, ' OR 1=1;-- for course code then unregister.
  try(PreparedStatement ps = conn.prepareStatement(
    "DELETE FROM Registrations WHERE student="+student+" AND course="+courseCode);){

    //ps.setString(1, student);
    //ps.setString(2, courseCode);
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
    public String getInfo(String student) throws SQLException {
      String sql = "SELECT jsonb_build_object(" +
                   "'student', b.idnr," +
                   "'name', b.name," +
                   "'login', b.login," +
                   "'program', b.program," +
                   "'branch', b.branch," +
                   "'finished', COALESCE((" +
                       "SELECT jsonb_agg(jsonb_build_object(" +
                           "'course', c.name, " +
                           "'code', c.code, " +
                           "'credits', c.credits, " +
                           "'grade', g.grade)) " +
                       "FROM FinishedCourses g " +
                       "JOIN Courses c ON g.course = c.code " +
                       "WHERE g.student = b.idnr), '[]'::jsonb)," +
                   "'registered', COALESCE((" +
                       "SELECT jsonb_agg(jsonb_build_object(" +
                           "'course', c.name, " +
                           "'code', c.code, " +
                           "'status', r.status, " +
                           "'position', COALESCE(w.position, NULL))) " +  // Hämtar position från waitinglist
                       "FROM Registrations r " +
                       "LEFT JOIN waitinglist w ON r.student = w.student AND r.course = w.course " + // JOIN mot waitinglist
                       "JOIN Courses c ON r.course = c.code " +
                       "WHERE r.student = b.idnr), '[]'::jsonb)," +
                   "'seminarCourses', COALESCE(pg.seminarCourses, 0)," +
                   "'mathCredits', COALESCE(pg.mathCredits, 0.0)," +
                   "'totalCredits', COALESCE(pg.totalCredits, 0.0)," +
                   "'canGraduate', COALESCE(pg.qualified, false)) AS jsondata " +
                   "FROM BasicInformation b " +
                   "LEFT JOIN PathToGraduation pg ON b.idnr = pg.student " +
                   "WHERE b.idnr = ?;";
  
      try (PreparedStatement ps = conn.prepareStatement(sql)) {
          ps.setString(1, student);
          ResultSet rs = ps.executeQuery();
  
          if (rs.next()) {
              return rs.getString("jsondata");
          } else {
              return "{\"success\":false, \"error\":\"Student not found\"}";
          }
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