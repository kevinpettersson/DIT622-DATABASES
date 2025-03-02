from http.server import BaseHTTPRequestHandler, HTTPServer
from urllib.parse import urlparse, unquote
import PortalConnection

hostName = "localhost"
serverPort = 80

conn = PortalConnection.PortalConnection()

class PortalServer(BaseHTTPRequestHandler):
    def do_GET(self):
        print(self.path)
        pth = self.path
        if pth == "/":
            self.send_response(200)
            self.send_header("Content-type", "text/html")
            self.end_headers()
            self.wfile.write(bytes(
             """
                <!doctype html>
                <html lang=\"en\">
                <head>
                <link rel=\"stylesheet\" href=\"https://stackpath.bootstrapcdn.com/bootstrap/4.3.1/css/bootstrap.min.css\" integrity=\"sha384-ggOyR0iXCbMQv3Xipma34MD+dH/1fQ784/j6cY/iJTQUOhcWr7x9JvoRxT2MZw1T\" crossorigin=\"anonymous\">
                </head><body class=\"bg-light\">
                <div class=\"container\"> 
                <form action=\"run\">      
                <div class=\"mb-3\">
                <div class=\"input-group\">
                  <input type=\"text\" name=\"student\" placeholder=\"Student ID\">
                  <div class=\"input-group-append\">
                    <input type=\"submit\" value=\"run\">
                  </div>
                </div>
                </div></form>
                </div></body></html>        
                 """, "utf-8"))
        elif pth.startswith("/run"):
            self.send_response(200)
            self.send_header("Content-type", "text/html")
            self.end_headers()
            self.wfile.write(bytes(
             """
                <html lang=\"en\">
                <head>
                    <meta charset=\"UTF-8\">
                    <meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">
                    <meta http-equiv=\"X-UA-Compatible\" content=\"ie=edge\">
                    <title>Student Portal</title>
                    <link rel=\"stylesheet\" href=\"https://stackpath.bootstrapcdn.com/bootstrap/4.3.1/css/bootstrap.min.css\" integrity=\"sha384-ggOyR0iXCbMQv3Xipma34MD+dH/1fQ784/j6cY/iJTQUOhcWr7x9JvoRxT2MZw1T\" crossorigin=\"anonymous\">
                </head>
                <body class=\"bg-light\">
                <div class=\"container\">
                      <input type=\"text\" id=\"code\" placeholder=\"Course code\">
                      <button id=\"register\">Register</button>
                      <button id=\"unregister\">Unregister</button>
                      <button id=\"getData\">Refresh Info</button>
                      <p id=\"result\"></p>
                      <p id=\"info\"></p>
                </div>
                </body>
                <script>
                        document.getElementById('getData').addEventListener('click', getData);
                        document.getElementById('register').addEventListener('click', register);
                        document.getElementById('unregister').addEventListener('click', unregister);
                        getData();
                        function getData(){
                            const urlParams = new URLSearchParams(window.location.search);
                            const stu = urlParams.get('student');
                            fetch('info?student='+encodeURIComponent(stu))
                                .then(function (res) {
                                    return res.json();
                                })
                                .then(function (data) {
                                    let result = `<h2>Student Info</h2>`;
                                    
                                    result += 
                                      `<p>Student: ${data.student}</p>
                                       <p>Name: ${data.name}</p>
                                       <p>Login: ${data.login}</p>
                                       <p>Program: ${data.program}</p>
                                       <p>Branch: ${data.branch || \"not selected\"}</p>
                                       
                                       <p>Read courses:<ul>
                                       `;
                                    
                                    (data.finished ||  []).forEach((course) => {
                                      result += `<li>${course.course} (${course.code}), ${course.credits} credits, grade ${course.grade}</li>`      
                                      });
                                      
                                    result += `</ul></p>
                                               <p>Registered for courses:<ul>`;
                                    
                                    (data.registered || []).forEach((course) => {
                                        result += `<li>${course.course} (${course.code}), ${course.status}`;
                                        if (course.position)
                                            result += `, position ${course.position}`;
                                        result += ` (<a href=\"javascript:void(0)\" onclick=\"unreg('${course.code}')\">unregister</a>)`
                                        result += `</li>`;      
                                      });
                                      
                                    result += 
                                      `</ul></p>
                                       <p>Seminar courses passed: ${data.seminarCourses}</p>
                                       <p>Total math credits: ${data.mathCredits}</p>
                                       <p>Total credits: ${data.totalCredits}</p>
                                       <p>Ready for graduation: ${data.canGraduate}</p>
                                       `;
                                       
                                    document.getElementById('info').innerHTML = result;
                                }).catch(err => {
                                    alert(`There was an error: ${err}`);
                                  }
                                )
                        }
                        
                        function register(){
                            const urlParams = new URLSearchParams(window.location.search);
                            const stu = urlParams.get('student');
                            const code = document.getElementById('code').value;
                            fetch('reg?student='+encodeURIComponent(stu)+'&course='+encodeURIComponent(code))
                                .then(function (res) {
                                    return res.json();
                                })
                                .then(function (data) {
                                    let result = `<h2>Registration result</h2>`;
                                   
                                    if(data.success){
                                      result += \"Registration sucessful!\";                  
                                    } else {
                                      result += `Registration failed! Error: ${data.error}`;                  
                                    }
                                    
                                    document.getElementById('result').innerHTML = result;
                                    getData();
                                }).catch(err => {
                                    alert(`There was an error: ${err}`);
                                  }
                                )
                        }
                        
                        function unreg(code){
                            const urlParams = new URLSearchParams(window.location.search);
                            const stu = urlParams.get('student');
                            fetch('unreg?student='+encodeURIComponent(stu)+'&course='+encodeURIComponent(code))
                                .then(function (res) {
                                    return res.json();
                                })
                                .then(function (data) {
                                    let result = `<h2>Unregistration result</h2>`;
                                   
                                    if(data.success){
                                      result += \"Unregistration sucessful!\";                  
                                    } else {
                                      result += `Unregistration failed! Error: ${data.error}`;                  
                                    }
                                    
                                    document.getElementById('result').innerHTML = result;
                                    getData();
                                })
                                .catch(err => {
                                    alert(`There was an error: ${err}`);
                                  }
                                )
                        }
                        function unregister(){
                            const code = document.getElementById('code').value;
                            unreg(code);
                        }
                </script> 
                </html>       
                """, "utf-8"))
        elif pth.startswith("/info"):
            query = urlparse(self.path).query
            query_components = dict(qc.split("=") for qc in query.split("&"))
            st = query_components["student"]
            self.send_response(200)
            self.send_header("Content-type", "application/json")
            self.end_headers()
            self.wfile.write(bytes(conn.getInfo(st), "utf-8"))
            
        elif pth.startswith("/reg"):
            query = urlparse(self.path).query
            query_components = dict(qc.split("=") for qc in query.split("&"))
            st = query_components["student"]
            co = query_components["course"]
            self.send_response(200)
            self.send_header("Content-type", "application/json")
            self.end_headers()
            self.wfile.write(bytes(conn.register(st, co), "utf-8"))
        
        elif pth.startswith("/unreg"):
            query = urlparse(self.path).query
            query_components = dict(qc.split("=") for qc in query.split("&"))
            st = unquote(query_components["student"])
            co = unquote(query_components["course"])
            self.send_response(200)
            self.send_header("Content-type", "application/json")
            self.end_headers()
            self.wfile.write(bytes(conn.unregister(st, co), "utf-8"))
            
        else:
            self.send_response(404,message='Not Found')
            self.end_headers()
        

if __name__ == "__main__":        
    webServer = HTTPServer((hostName, serverPort), PortalServer)
    print("Server started http://%s:%s" % (hostName, serverPort))
    
    try:
        webServer.serve_forever()
    except KeyboardInterrupt:
        pass

    webServer.server_close()
    print("Server stopped.")