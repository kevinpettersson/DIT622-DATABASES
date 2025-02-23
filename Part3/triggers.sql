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
        SELECT capacity INTO course_capacity 
        FROM LimitedCourses
        WHERE code = NEW.course;

        -- GET the next position in queue
        SELECT COALESCE(MAX(position), 0) + 1 INTO waiting_position
        FROM WaitingList 
        WHERE course = NEW.course;

        -- GET number of currently registered students, dummy value if not found.
        SELECT COUNT(student) INTO course_registrations
        FROM Registered 
        WHERE course = NEW.course;

        -- GET number of prerequisite courses
        SELECT COUNT(prerequisite) INTO prerequisite_count
        FROM Prerequisites 
        WHERE course = NEW.course;

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
            FROM Taken
            WHERE student = NEW.student AND course = NEW.course AND grade != 'U'
        ) 
        THEN RAISE EXCEPTION 'Failure: Student has passed course';
        END IF;

        -- CHECK if student already waiting/registrered for the course.
        IF EXISTS (
            SELECT 1 
            FROM Registrations
            WHERE course = NEW.course AND student = NEW.student 
        )
        THEN RAISE EXCEPTION 'Failure: Already registered or in waiting list';
        END IF;

        -- CHECK if capacity wasn't null and is less than registrated then insert into R otherwise WL. 
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
        -- GET next student in WaitingList and their position (can be null).
        SELECT student, position INTO student_next, student_position
        FROM WaitingList
        WHERE course = OLD.course
        ORDER BY position ASC
        LIMIT 1;

        -- GET number of currently registered students.
        SELECT COUNT(student) INTO course_registrations
        FROM Registered
        WHERE course = OLD.course;

        -- GET the course capacity
        SELECT capacity INTO course_capacity 
        FROM LimitedCourses
        WHERE code = OLD.course;

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
            WHERE student = OLD.student AND course = OLD.course
        ) THEN 
            -- first delete student from WL
            DELETE FROM WaitingList 
            WHERE student = OLD.student AND course = OLD.course;
            
            -- then update wl
            UPDATE WaitingList 
            SET position = position - 1
            WHERE course = OLD.course AND position > student_position;
        END IF;

        -- CHECK if the student is in registered then remove and update waitinglist.
        IF EXISTS (
            SELECT 1 
            FROM Registered
            WHERE student = OLD.student AND course = OLD.course
        ) THEN 
            -- first delete the student from Registered.
            DELETE FROM Registered 
            WHERE student = OLD.student AND course = OLD.course;
            
            -- then if student_next != null, insert next_student into Registered.
            IF student_next IS NOT NULL AND course_capacity >= course_registrations THEN

                INSERT INTO Registered VALUES (student_next, OLD.course);
                        
                -- then delete next_student from WL.
                DELETE FROM WaitingList 
                WHERE student = student_next AND course = OLD.course;

                --then update WL.
                UPDATE WaitingList 
                SET position = position - 1
                WHERE course = OLD.course AND position > student_position;
            END IF;  
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

