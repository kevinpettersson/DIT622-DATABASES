SELECT json_build_object(
    'student', s.idnr,
    'name', s.name, 
    'login', s.login,
    'program', s.program,
    'branch', sb.branch,
    'finished', 
        COALESCE((SELECT json_agg(
            json_build_object(
                'course', coursename,
                'code', course,
                'credits', credits,
                'grade', grade))
        FROM FinishedCourses
        WHERE student = s.idnr), '[]'),
    'registered', 
        COALESCE((SELECT json_agg(
            json_build_object(
                'course', c.name,
                'code', r.course,
                'status', r.status,
                'position', wl.position))
        FROM Registrations AS r
        LEFT JOIN Courses AS c ON r.course = c.code
        LEFT JOIN WaitingList AS wl ON r.student = wl.student AND r.course = wl.course
        WHERE r.student = s.idnr), '[]'),
    'seminarCourses', ptg.seminarcourses,
    'mathCredits', ptg.mathcredits,
    'totalCredits', ptg.totalcredits,
    'canGraduate', ptg.qualified
    ) AS json_data
FROM Students AS s 
LEFT JOIN StudentBranches AS sb ON sb.student = s.idnr
LEFT JOIN PathToGraduation AS ptg ON ptg.student = s.idnr
WHERE s.idnr = '4444444444';
