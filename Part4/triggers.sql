-- REGISTER FUNCTION
CREATE FUNCTION insertInRegistrations()
RETURNS TRIGGER AS $$
DECLARE 
  courseCapacity int;
  numPassedPrereqs int;
  numReqPrereq int;
  inWaitingList int;
  numRegistered int;
  isCourseLimited boolean DEFAULT FALSE;
  studentHavePassedPrereqs boolean DEFAULT FALSE;
  courseHasPrereq boolean DEFAULT FALSE;

BEGIN

-- Check if the course is a limitedCourse.
IF EXISTS (
    SELECT 1 FROM LimitedCourses WHERE code = NEW.course
) THEN 
-- Assign values to courseCapacity, number of registered students, number of students in waiting list and that the course is limited.
    isCourseLimited := TRUE;
    SELECT capacity INTO courseCapacity FROM LimitedCourses WHERE code = NEW.course;
    SELECT COUNT(student) INTO numRegistered FROM Registered WHERE course = NEW.COURSE;
    SELECT COUNT(course) INTO inWaitingList FROM WaitingList WHERE course = NEW.course;
END IF;

-- Check if the course has prerequisites.
IF EXISTS(
  SELECT 1 FROM Prerequisites WHERE course = NEW.course
) THEN
-- The given course has prerequisites, check if student has passed those prerequisites.
    courseHasPrereq := TRUE;
    SELECT COUNT(prerequisite) INTO numReqPrereq FROM Prerequisites WHERE course = NEW.course;
    SELECT COUNT(course) INTO numPassedPrereqs FROM PassedCourses WHERE student = NEW.student AND course IN (SELECT prerequisite FROM Prerequisites WHERE course = NEW.course);
    IF (
      numReqPrereq = numPassedPrereqs
      ) THEN 
-- Student has passed all prerequisites.
      studentHavePassedPrereqs := TRUE;
    END IF;
END IF;

-- Raise exception if student already registered or waiting.
IF EXISTS ( 
  SELECT 1 FROM Registrations
  WHERE student = NEW.student
  AND course = NEW.course
) THEN
  RAISE EXCEPTION 'Unable to register sID % -> course %', NEW.student, NEW.course
  USING HINT = 'Already registered or waiting';
END IF;

-- Raise exception if student already has passed the course.
IF EXISTS (
  SELECT 1 FROM PassedCourses
  WHERE student = NEW.student
  AND course = NEW.course
) THEN
  RAISE EXCEPTION 'Unable to register sID % -> course %', NEW.student, NEW.course
  USING HINT = 'Already passed course';
END IF;

-- Raise exception if student is missing prerequisites.
IF (
  courseHasPrereq
) THEN
  IF NOT (
    studentHavePassedPrereqs
  ) THEN
      RAISE EXCEPTION 'Unable to register sID % -> course %', NEW.student, NEW.course
      USING HINT = 'Missing prerequisites';
  END IF;
END IF;

-- Determine whether student should be added to the waiting list or registered to the course.
IF (numRegistered >= courseCapacity)
  THEN
-- Course is full; add to the waiting list.
    INSERT INTO WaitingList VALUES (NEW.student, NEW.course, inWaitingList + 1);
    ELSE
-- Course is not full.
    INSERT INTO Registered VALUES (NEW.student, NEW.course);
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;



-- UNREGISTER FUNCTION
CREATE FUNCTION unregisterInRegistrations()
RETURNS TRIGGER AS $$
DECLARE
  courseCapacity int;
  positionInWaitingList int;
  numRegistered int;
  isCourseLimited boolean DEFAULT FALSE;
  nextStudent CHAR(10);

BEGIN

-- Check if course is limited.
IF EXISTS (
    SELECT 1 FROM LimitedCourses WHERE code = OLD.course
) THEN 
-- Course is limited, get the course's capacity and number of registered students in that course.
    isCourseLimited := TRUE;
    SELECT capacity INTO courseCapacity FROM LimitedCourses WHERE code = OLD.course;
    SELECT COUNT(student) INTO numRegistered FROM Registered WHERE course = OLD.COURSE;
END IF;

-- Check if student is in the waiting list.
IF EXISTS (
  SELECT 1 FROM WaitingList WHERE student = OLD.student AND course = OLD.course
) THEN
-- Get the position of the waiting student, delete it from the waiting list and update all positions after said student.
    SELECT position INTO positionInWaitingList FROM WaitingList WHERE student = OLD.student AND course = OLD.course;
    DELETE FROM WaitingList WHERE student = OLD.student AND course = OLD.course;
    UPDATE WaitingList SET position = position - 1 WHERE course = OLD.course AND position > positionInWaitingList;
END IF;

-- Check if student is registered to the course.
IF EXISTS (
  SELECT 1 FROM Registered WHERE student = OLD.student AND course = OLD.course
) THEN
-- Delete student from said course in registered.
    DELETE FROM Registered WHERE student = OLD.student AND course = OLD.course;
-- Check if the course is limited and if there is room for a new student.
    IF (
      isCourseLimited AND courseCapacity >= numRegistered -- Equal since number of registered is not updated after the deletion.
    ) THEN
-- Fetch the student who has waited the longest, register said student and update the rest of the waiting list.
        SELECT student INTO nextStudent FROM WaitingList WHERE course = OLD.course AND position = 1;
        IF nextStudent IS NOT NULL THEN
        INSERT INTO Registered VALUES (nextStudent, OLD.course);
        DELETE FROM WaitingList WHERE student = nextStudent AND course = OLD.course;
        UPDATE WaitingList SET position = position - 1 WHERE course = OLD.course AND position > 1;
        END IF;
    END IF;
END IF;

 RETURN OLD;
END;
$$ LANGUAGE plpgsql;


-- REGISTER TRIGGER
CREATE TRIGGER registerStudent
INSTEAD OF INSERT ON Registrations
FOR EACH ROW
EXECUTE FUNCTION insertInRegistrations();

-- UNREGISTER TRIGGER
CREATE TRIGGER unregister 
INSTEAD OF DELETE ON Registrations
FOR EACH ROW 
EXECUTE FUNCTION unregisterInRegistrations();