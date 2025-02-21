-- This should be your trigger file for part 3

CREATE FUNCTION register() RETURNS trigger AS $$
    DECLARE
        course_capacity INT;
        course_registrations INT;
        waiting_position INT;

    BEGIN
        -- Check that student and course are given
        IF NEW.student IS NULL THEN
            RAISE EXCEPTION 'studentr cannot be null';
        END IF;
        IF NEW.course IS NULL THEN
            RAISE EXCEPTION 'course cannot be null';
        END IF;

        -- Check if student already waiting/registrered for the course.
        IF EXISTS (
            SELECT 1 
            FROM Registrations AS r
            WHERE r.course = NEW.course AND r.student = NEW.student 
        )
        THEN RAISE EXCEPTION '% Is already waiting or registrered for the course.', NEW.student;
        END IF;

        -- Get the course capacity, dummy value if not found.
        SELECT COALESCE(lc.capacity, -1) INTO course_capacity 
        FROM LimitedCourses AS lc
        WHERE lc.code = NEW.course;

        -- Get the next position in queue
        SELECT COALESCE(MAX(position), 0) + 1 INTO waiting_position
        FROM WaitingList AS wl 
        WHERE wl.course = NEW.course;

        -- Get number of currently registered students, dummy value if not found.
        SELECT COALESCE(COUNT(r.student), 0) INTO course_registrations
        FROM Registered AS r
        WHERE r.course = NEW.course;

        -- If capacity wasn't null and is less than registrated then insert into WL otherwise R. 
        IF course_capacity > 0 AND course_registrations >= course_capacity THEN
            INSERT INTO WaitingList VALUES (NEW.student, NEW.course, waiting_position);
        ELSE
            INSERT INTO Registered VALUES (NEW.student, NEW.course);
        END IF;

        RETURN NEW;
    END;
$$ LANGUAGE plpgsql;

-- Need to use 'INSTEAD OF INSERT'-trigger with function to handle insertion logic into a view.
CREATE TRIGGER register INSTEAD OF INSERT ON Registrations
    FOR EACH ROW EXECUTE FUNCTION register();