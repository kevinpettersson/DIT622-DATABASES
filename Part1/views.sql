-- This file will contain all your views

-- BasicInformation(idnr, name, login, program, branch): for all students, 
-- their national identification number, name, login, their program and the branch (if any).
CREATE VIEW BasicInformation AS
SELECT s.idnr, s.name, s.login, s.program, sb.branch
FROM Students AS s
LEFT JOIN Studentbranches AS sb ON s.idnr = sb.student -- LEFT JOIN: take every record from left table (before JOIN) and 
                                                       -- then take every matching record from right table, if no match fill branch-column with null.


