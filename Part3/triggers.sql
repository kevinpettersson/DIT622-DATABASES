-- This should be your trigger file for part 3

CREATE FUNCTION register() RETURNS trigger AS $$
    DECLARE
        course_capacity INT;
        course_registrations INT;
        waiting_position INT;
        prerequisite_count INT;
        passed_prerequisite_count INT;

    BEGIN
        -- GET the course capacity
        SELECT lc.capacity INTO course_capacity 
        FROM LimitedCourses AS lc
        WHERE lc.code = NEW.course;

        -- GET the next position in queue
        SELECT COALESCE(MAX(position), 0) + 1 INTO waiting_position
        FROM WaitingList AS wl 
        WHERE wl.course = NEW.course;

        -- GET number of currently registered students, dummy value if not found.
        SELECT COUNT(r.student) INTO course_registrations
        FROM Registered AS r
        WHERE r.course = NEW.course;

        -- GET number of prerequisite courses
        SELECT COUNT(p.prerequisite) INTO prerequisite_count
        FROM Prerequisites AS p 
        WHERE p.course = NEW.course;

        -- GET number of passed prerequisite courses
        SELECT COUNT(t.course) INTO passed_prerequisite_count
        FROM Taken AS t
        JOIN Prerequisites AS p ON p.prerequisite = t.course AND p.course = NEW.course
        WHERE t.student = NEW.student AND t.grade != 'U';

        -- CHECK if student and course are give.
        IF NEW.student IS NULL THEN
            RAISE EXCEPTION 'Failure: Student cannot be null';
        END IF;
        IF NEW.course IS NULL THEN
            RAISE EXCEPTION 'Failure: Course cannot be null';
        END IF;
        
        -- CHECK if student meet the prerequisites of the course
        IF prerequisite_count != passed_prerequisite_count THEN
            RAISE EXCEPTION 'Failure: Student has not passed all the prerequisite courses.';
        END IF;
        
        -- CHECK if student already passed the course course
        IF EXISTS (
            SELECT 1
            FROM Taken AS t
            WHERE t.student = NEW.student AND t.course = NEW.course AND t.grade != 'U'
        ) 
        THEN RAISE EXCEPTION 'Failure: Student has passed course';
        END IF;

        -- CHECK if student already waiting/registrered for the course.
        IF EXISTS (
            SELECT 1 
            FROM Registrations AS r
            WHERE r.course = NEW.course AND r.student = NEW.student 
        )
        THEN RAISE EXCEPTION 'Failure: Already registered or in waiting list';
        END IF;

        -- CHECK if capacity wasn't null and is less than registrated then insert into WL otherwise R. 
        IF course_capacity IS NULL OR course_registrations < course_capacity THEN
            INSERT INTO Registered VALUES (NEW.student, NEW.course);
        ELSE
            INSERT INTO WaitingList VALUES (NEW.student, NEW.course, waiting_position);
        END IF;

        RETURN NEW;
    END;
$$ LANGUAGE plpgsql;

CREATE FUNCTION unregister() RETURNS trigger AS $$
    DECLARE
        student_next TEXT;
        student_position INT;
        course_registrations INT;
        course_capacity INT;
    BEGIN 

        -- GET next student to enter in waitinglist, used when a student is removed from registrations.
        SELECT wl.student INTO student_next
        FROM WaitingList AS wl
        WHERE wl.course = OLD.course
        ORDER BY wl.position ASC
        LIMIT 1;

        -- GET the current student position.
        SELECT position INTO student_position
        FROM WaitingList
        WHERE course = OLD.course AND student = OLD.student;

        -- GET number of currently registered students, dummy value if not found.
        SELECT COUNT(r.student) INTO course_registrations
        FROM Registered AS r
        WHERE r.course = NEW.course;

        -- GET the course capacity
        SELECT lc.capacity INTO course_capacity 
        FROM LimitedCourses AS lc
        WHERE lc.code = NEW.course;

        -- CHECK if student and course are give.
        IF OLD.student IS NULL THEN
            RAISE EXCEPTION 'Failure: Student cannot be null';
        END IF;
        IF OLD.course IS NULL THEN
            RAISE EXCEPTION 'Failure: Course cannot be null';
        END IF;

        -- CHECK if the student is in waitinglist then remove and update each row. 
        IF EXISTS (
            SELECT 1 
            FROM WaitingList AS wl 
            WHERE wl.student = OLD.student AND wl.course = OLD.course
        ) THEN 
            BEGIN
                -- first delete student from WL
                DELETE FROM WaitingList 
                WHERE WaitingList.student = OLD.student AND WaitingList.course = OLD.course;
                
                -- then update wl
                UPDATE WaitingList 
                SET position = position - 1
                WHERE course = OLD.course AND position > student_postion;
            END;
        END IF;

        -- CHECK if the student is in registered then remove and update waitinglist.
        IF EXISTS (
            SELECT 1 
            FROM Registered AS r
            WHERE r.student = OLD.student AND r.course = OLD.course
        ) THEN 
            BEGIN
                -- first delete the student from Registered.
                DELETE FROM Registered 
                WHERE Registered.student = OLD.student AND Registered.course = OLD.course;
                
                -- then if student_next != null, insert next_student into Registered.
                IF student_next IS NOT NULL AND course_capacity > course_registrations THEN
                    INSERT INTO Registered (student, course)
                    SELECT student, course
                    FROM WaitingList 
                    WHERE student = student_next AND course = OLD.course;
                            
                    -- then delete next_student from WL.
                    DELETE FROM WaitingList
                    WHERE student = student_next AND course = OLD.course;

                    -- then update WL.
                    UPDATE WaitingList 
                    SET position = position - 1
                    WHERE course = OLD.course AND position > student_position;
                END IF;  
            END;
        END IF;
        RETURN OLD;
    END;
$$ LANGUAGE plpgsql;

-- Need to use 'INSTEAD OF INSERT'-trigger with function to handle insertion logic into a view.
CREATE TRIGGER register INSTEAD OF INSERT ON Registrations
    FOR EACH ROW EXECUTE FUNCTION register();

-- Need to use 'INSTEAD OF DELETE'-trigger with function to handle deletion logic on a view.
CREATE TRIGGER unregister INSTEAD OF DELETE ON Registrations
    FOR EACH ROW EXECUTE FUNCTION unregister();

