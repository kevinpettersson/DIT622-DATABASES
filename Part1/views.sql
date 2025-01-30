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
INNER JOIN Courses     AS c  ON wl.course = c.code;

-- Helper Views --

-- creates a subset of FinishedCourses but keeping only the ones with a grade other than U.
CREATE VIEW PassedCourses AS
SELECT * FROM FinishedCourses
WHERE FinishedCourses.grade <> 'U';

-- returns a view of (student, courses) that have mandatory courses not yet passed
CREATE VIEW UnreadMandatory AS
SELECT
    s.idnr AS student, 
    mp.course AS course
FROM Students AS s
JOIN MandatoryProgram AS mp ON s.program = mp.program
WHERE mp.course NOT IN (
    SELECT pc.course
    FROM PassedCourses AS pc
    WHERE pc.student = s.idnr
)

UNION

SELECT
    s.idnr AS student,
    mb.course
FROM Students AS s
JOIN StudentBranches AS sb ON s.idnr = sb.student
JOIN MandatoryBranch AS mb ON sb.branch = mb.branch AND sb.program = mb.program
WHERE mb.course NOT IN (
    SELECT pc.course
    FROM PassedCourses AS pc
    WHERE pc.student = s.idnr
)

