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

-- REGISTER TRIGGER
do $$
BEGIN
  raise notice 'Hello World!';
END;
$$;




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