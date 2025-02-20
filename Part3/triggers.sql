-- This should be your trigger file for part 3

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

-- REGISTER TRIGGER
/* 
RAISE EXCEPTION 'Nonexistent ID --> %', user_id
      USING HINT = 'Please check your user ID'; 
*/
do $$
BEGIN
  raise notice 'Hello World!';
END;
$$;




-- UNREGISTER TRIGGER