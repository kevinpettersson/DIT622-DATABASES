-- BasicInformation(idnr, name, login, program, branch): for all students, 
-- their national identification number, name, login, their program and the branch (if any).
CREATE VIEW BasicInformation AS 
SELECT 
    s.idnr, 
    s.name, 
    s.login, 
    s.program, 
    sb.branch
FROM Students AS s
LEFT JOIN Studentbranches AS sb ON s.idnr = sb.student;

-- FinishedCourses(student, course, courseName, grade, credits): for all students, 
-- their finished courses, along with (course) codes, (course) names, grades ('U', '3', '4' or '5') and number of credits.
CREATE VIEW FinishedCourses AS
SELECT 
    s.idnr AS student, 
    c.code AS course, 
    c.name AS coursename, 
    t.grade, 
    c.credits
FROM Students AS s
INNER JOIN Taken AS t ON s.idnr = t.student
INNER JOIN Courses AS c ON c.code = t.course;

CREATE VIEW Registrations AS
SELECT 
    s.idnr AS student,
    c.code AS course,
    'registered' AS status
FROM 
    Students AS s
INNER JOIN Registered AS r ON r.student = s.idnr 
INNER JOIN Courses AS c ON r.course = c.code
UNION ALL -- since there should be no duplicates in both sets
SELECT 
    s.idnr AS student,
    c.code AS course,
    'waiting' AS status 
FROM 
    Students AS s
INNER JOIN WaitingList AS wl ON wl.student = s.idnr 
INNER JOIN Courses     AS c  ON wl.course = c.code

