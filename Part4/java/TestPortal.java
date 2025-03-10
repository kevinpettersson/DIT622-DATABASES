import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;

public class TestPortal {

   // enable this to make pretty printing a bit more compact
   private static final boolean COMPACT_OBJECTS = false;

   // This class creates a portal connection and runs a few operation

   public static void main(String[] args) {
      int nextTest = 2;
      try{
         PortalConnection c = new PortalConnection();
   
         // Write your tests here. Add/remove calls to pause() as desired. 
         // Use println instead of prettyPrint to get more compact output (if your raw JSON is already readable)

         //1
         System.out.println("\nTest 1");
         System.out.println((c.getInfo("1111111111")));
         System.out.print("\nTest " + (nextTest++) + " - " );
         pause();

         //2 
         System.out.println("\nTest 2 - Successful register " + c.register("1111111111", "CCC111"));
         System.out.println((c.getInfo("1111111111")));
         System.out.print("\nTest " + (nextTest++) + " - " );
         pause();

         //3
         System.out.println("\nTest 3");
         System.out.println("Unsuccessful register " + c.register("1111111111", "CCC111"));
         System.out.print("\nTest " + (nextTest++) + " - " );
         pause();

         //4
         System.out.println("\nTest 4");
         System.out.println("Successful unregister " + c.unregister("1111111111", "CCC111"));
         System.out.println((c.getInfo("1111111111")));
         System.out.println("Unsuccessful unregister " + c.unregister("1111111111", "CCC111"));
         System.out.print("\nTest " + (nextTest++) + " - " );
         pause();

         //5
         System.out.println("\nTest 5");
         System.out.println("Unsuccessful register " + c.register("1111111111", "CCC444"));
         System.out.print("\nTest " + (nextTest++) + " - " );
         pause();

         //6
         System.out.println("\nTest 6");
         System.out.println("Successful register s1   " + c.register("1111111111", "CCC222"));
         System.out.println("Successful register s2   " + c.register("2222222222", "CCC222"));
         System.out.println("Successful register s3   " + c.register("3333333333", "CCC222"));
         System.out.println("Successful unregister s1 " + c.unregister("1111111111", "CCC222"));
         System.out.println("Successful register s1   " + c.register("1111111111", "CCC222"));
         System.out.println((c.getInfo("1111111111")));
         System.out.print("\nTest " + (nextTest++) + " - " );
         pause();

         //7
         System.out.println("\nTest 7");
         System.out.println("Successful unregister s1 " + c.unregister("1111111111", "CCC222"));
         System.out.println("Successful register s1   " + c.register("1111111111", "CCC222"));
         System.out.println((c.getInfo("1111111111")));
         System.out.print("\nTest " + (nextTest++) + " - " );
         pause();

         //8
         System.out.println("\nTest 8");
/*
### CCC333 capacity is 2
student    | course |   status
------------+--------+------------
1111111111 | CCC333 | registered
2222222222 | CCC333 | registered
3333333333 | CCC333 | registered
*/
         System.out.println("Successful WLregister s5 " + c.register("5555555555", "CCC333"));
         System.out.println("Successful unregister s1 " + c.unregister("1111111111", "CCC333"));
         System.out.println((c.getInfo("5555555555")));
         System.out.print("\nTest " + (nextTest++) + " - " );
         pause();

         //9 - Unregister with the SQL injection you introduced, causing all (or almost all?) registrations to disappear.
         System.out.println("\nTest 9");
         System.out.println(c.unregister("' OR 1=1 --", "noobDown"));

      } catch (ClassNotFoundException e) {
         System.err.println("ERROR!\nYou do not have the Postgres JDBC driver (e.g. postgresql-42.5.1.jar) in your runtime classpath!");
      } catch (Exception e) {
         e.printStackTrace();
      }
   }
   
   
   
   public static void pause() throws Exception{
     System.out.println("PRESS ENTER");
     while(System.in.read() != '\n');
   }
   
   // This is a truly horrible and bug-riddled hack for printing JSON. 
   // It is used only to avoid relying on additional libraries.
   // If you are a student, please avert your eyes.
   public static void prettyPrint(String json){
      System.out.print("Raw JSON:");
      System.out.println(json);
      System.out.println("Pretty-printed (possibly broken):");
      
      int indent = 0;
      json = json.replaceAll("\\r?\\n", " ");
      json = json.replaceAll(" +", " "); // This might change JSON string values :(
      json = json.replaceAll(" *, *", ","); // So can this
      
      for(char c : json.toCharArray()){
        if (c == '}' || c == ']') {
          indent -= 2;
          breakline(indent); // This will break string values with } and ]
        }
        
        System.out.print(c);
        
        if (c == '[' || c == '{') {
          indent += 2;
          breakline(indent);
        } else if (c == ',' && !COMPACT_OBJECTS) 
           breakline(indent);
      }
      
      System.out.println();
   }
   
   public static void breakline(int indent){
     System.out.println();
     for(int i = 0; i < indent; i++)
       System.out.print(" ");
   }   
}
