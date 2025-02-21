-- This should be your trigger file for part 3


-- YOU NEED TO WRITE THE TRIGGERS ON THE VIEW REGISTRATIONS INSTEAD OF ON THE TABLES THEMSELVES

/*
A study administrator can override both course prerequisite requirements and size restrictions
and add a student directly as registered to a course.

Student need all prereqCourses, not already read course, not registered already to register.
If course full, add to waitinglist in FIFO order.

-- psuedologic according to domain desc.
if (sAdmin) {register.()}
else
 if (passedPrereq && notReadAlready && notRegisteredAlready)
 return appropriateError
      if (waitinglist.empty && courseNotFull) {register.()}
      else {waitinglist.add()}
*/

CREATE FUNCTION insertInRegistrations()
RETURNS TRIGGER AS $$
DECLARE 
  maxpos int;
  courseCapacity int;

BEGIN

  -- Assign value to maxpos
  maxpos := (
    SELECT COUNT(*)
    FROM Registrations
    WHERE course = NEW.course
  );

  -- Raise exception if student already registered or waiting
  IF EXISTS ( 
    SELECT 1 FROM Registrations
    WHERE student = NEW.student
    AND course = NEW.course
  ) THEN
    RAISE EXCEPTION 'Unable to register sID % -> course %', NEW.student, NEW.course
    USING HINT = 'Already registered or waiting';
  END IF;

  IF NOT (
      ( -- Raise exception if student haven't
      SELECT COUNT(*) 
      FROM passedcourses
      WHERE student = NEW.student 
      AND course IN (
        SELECT prerequisite
        FROM prerequisites
        WHERE course = NEW.course
      ) 
      ) = (
      SELECT COUNT(*) 
      FROM prerequisites 
      WHERE course = NEW.course
      )
  ) THEN
      RAISE EXCEPTION 'Unable to register sID % -> course %', NEW.student, NEW.course
      USING HINT = 'Missing prerequisites';
  END IF;

  IF EXISTS ( -- If the course is a limitedcourse
    SELECT 1
    FROM LimitedCourses
    WHERE course = NEW.course
  ) THEN -- check if full
    SELECT capacity INTO courseCapacity
    FROM LimitedCourses 
    WHERE code = NEW.course;
  END IF;
    
  
  IF (
    maxpos >= courseCapacity
  ) THEN
      INSERT INTO Registrations 
      VALUES (NEW.student, NEW.course, 'waiting');
      RETURN NEW;
  END IF;

  INSERT INTO Registrations
    VALUES (NEW.student, NEW.course, 'registered');


  -- No conflict -> insert
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- REGISTER TRIGGER
CREATE TRIGGER registerStudent
INSTEAD OF INSERT ON Registrations
FOR EACH ROW
EXECUTE FUNCTION insertInRegistrations();



/*
if (waitinglist.contains(student))
       delete;
       updatewaitinglist?;
       return;
       
       else
       if(registered)
       delete
       tryTo register firstIn waitinglist
*/
-- UNREGISTER TRIGGER