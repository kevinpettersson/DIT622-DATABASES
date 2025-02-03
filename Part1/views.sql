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
JOIN Taken AS t ON s.idnr = t.student
JOIN Courses AS c ON c.code = t.course;

-- Registrations
CREATE VIEW Registrations AS
SELECT 
    s.idnr AS student,
    c.code AS course,
    'registered' AS status
FROM 
    Students AS s
JOIN Registered AS r ON r.student = s.idnr 
JOIN Courses AS c ON r.course = c.code

UNION
 
SELECT 
    s.idnr AS student,
    c.code AS course,
    'waiting' AS status 
FROM 
    Students AS s
JOIN WaitingList AS wl ON wl.student = s.idnr 
JOIN Courses     AS c  ON wl.course = c.code;

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
);

-- RecommendedCourses
CREATE VIEW RecommendedCourses AS 
SELECT 
    pc.student AS student,
    rb.course AS course,
    pc.credits AS credits
FROM PassedCourses AS pc 
JOIN StudentBranches AS sb ON pc.student = sb.student
JOIN RecommendedBranch AS rb ON sb.branch = rb.branch 
                             AND sb.program = rb.program 
                             AND pc.course = rb.course;

-- PathToGraduation
CREATE VIEW PathToGraduation AS
WITH TotalCredits AS(
    SELECT
        pc.student AS student,
        SUM(pc.credits) AS totalcredits
    FROM PassedCourses AS pc
    GROUP BY pc.student
), 
MandatoryLeft AS (
    SELECT
        um.student, 
        COUNT(um.course) AS mandatoryleft
    FROM UnreadMandatory AS um
    GROUP BY um.student
),
MathAndSeminar AS (
    SELECT 
        pc.student AS student,
        SUM(CASE WHEN c.classification = 'math' THEN pc.credits END) AS mathcredits,
        COUNT(CASE WHEN c.classification = 'seminar' THEN 1 END) AS seminarcourses
    FROM PassedCourses AS pc
    LEFT JOIN Classified AS c ON pc.course = c.course
    GROUP BY pc.student
)
SELECT 
    s.idnr AS student,
    COALESCE(tc.totalcredits, 0) AS totalcredits,
    COALESCE(ml.mandatoryleft, 0) AS mandatoryleft,
    COALESCE(ms.mathcredits, 0) AS mathcredits,
    COALESCE(ms.seminarcourses, 0) AS seminarcourses,
    -- qualified
    COALESCE(tc.totalcredits, 0) > 30 
    AND COALESCE(ms.mathcredits, 0) > 20 
    AND COALESCE(ms.seminarcourses, 0) >= 1
    AND COALESCE(ml.mandatoryleft, 0) = 0
    AND COALESCE(rc.credits, 0) >= 10 AS qualified
FROM Students AS s 
LEFT JOIN TotalCredits AS tc ON s.idnr = tc.student
LEFT JOIN MandatoryLeft AS ml ON s.idnr = ml.student
LEFT JOIN MathAndSeminar AS ms ON s.idnr = ms.student
LEFT JOIN RecommendedCourses AS rc ON s.idnr = rc.student
ORDER BY s.idnr;




