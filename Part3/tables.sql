-- This should be your tables file from part 2

CREATE TABLE Departments (
    name TEXT PRIMARY KEY,
    abbr TEXT NOT NULL,
    UNIQUE (abbr)
);

CREATE TABLE Programs (
    name TEXT PRIMARY KEY,
    abbr TEXT NOT NULL
);

CREATE TABLE ProgramsHosts (
    program TEXT,
    department TEXT,
    FOREIGN KEY (program) REFERENCES Programs (name),
    FOREIGN KEY (department) REFERENCES Departments (name),
    PRIMARY KEY (program, department)  
);

CREATE TABLE Branches (
    name TEXT,
    program TEXT,
    FOREIGN KEY (program) REFERENCES Programs (name),
    PRIMARY KEY (name, program)
);

CREATE TABLE Students (
    idnr CHAR(10) PRIMARY KEY,
    name TEXT NOT NULL,
    login TEXT NOT NULL,
    program TEXT NOT NULL,
    branch TEXT,
    FOREIGN KEY (program) REFERENCES Programs (name), -- ensures program exists in program table
    FOREIGN KEY (branch, program) REFERENCES Branches (name, program), -- ensures the (branch,program)-pair exists in the branches table. thus a student can't chose a branch not part of a program.
    UNIQUE (login)
);

CREATE TABLE StudentBranches (
    student CHAR(10) PRIMARY KEY,
    branch TEXT NOT NULL,
    program TEXT NOT NULL,
    FOREIGN KEY (student) REFERENCES Students (idnr),
    FOREIGN KEY (program) REFERENCES Programs (name),
    FOREIGN KEY (branch, program) REFERENCES Branches (name, program)
);

CREATE TABLE Courses (
    code CHAR(6) PRIMARY KEY,
    name TEXT NOT NULL,
    credits FLOAT NOT NULL,
    department TEXT NOT NULL,
    CONSTRAINT credits_nonnegative check (credits >=0),
    FOREIGN KEY (department) REFERENCES Departments (name)
);

CREATE TABLE Prerequisites (
    course CHAR(6),
    prerequisite CHAR(6),
    FOREIGN KEY (course) REFERENCES Courses (code),
    FOREIGN KEY (prerequisite) REFERENCES Courses (code),
    PRIMARY KEY (course, prerequisite)
);

CREATE TABLE LimitedCourses (
    code CHAR(6) PRIMARY KEY,
    capacity INT NOT NULL,
    CONSTRAINT capacity_nonnegative check (capacity >=0),
    FOREIGN KEY (code) REFERENCES Courses (code)
);

CREATE TABLE Classifications (
    name TEXT PRIMARY KEY
);

CREATE TABLE Classified (
    course CHAR(6),
    classification TEXT,
    FOREIGN KEY (course) REFERENCES Courses (code),
    FOREIGN KEY (classification) REFERENCES Classifications (name),
    PRIMARY KEY (course, classification)
);

CREATE TABLE MandatoryProgram (
    course CHAR(6),
    program TEXT,
    FOREIGN KEY (course) REFERENCES Courses (code),
    FOREIGN KEY (program) REFERENCES Programs (name),
    PRIMARY KEY (course, program)
);

CREATE TABLE MandatoryBranch (
    course CHAR(6),
    branch TEXT,
    program TEXT NOT NULL,
    FOREIGN KEY (course) REFERENCES Courses (code),
    FOREIGN KEY (branch, program) REFERENCES Branches (name, program),
    PRIMARY KEY (course, branch)
);

CREATE TABLE RecommendedBranch (
    course CHAR(6),
    branch TEXT,
    program TEXT NOT NULL,
    FOREIGN KEY (course) REFERENCES Courses (code),
    FOREIGN KEY (branch, program) REFERENCES Branches (name, program),
    PRIMARY KEY (course, branch)
);

CREATE TABLE Registered (
    student CHAR(10),
    course CHAR(6),
    FOREIGN KEY (student) REFERENCES Students (idnr),
    FOREIGN KEY (course) REFERENCES Courses (code),
    PRIMARY KEY (student, course)
);

CREATE TABLE Taken (
    student CHAR(10),
    course CHAR(6),
    grade CHAR(1) NOT NULL, -- CHAR(1) DEFAULT 'U' // grade CHAR(1) NOT NULL CHECK (....) ???
    FOREIGN KEY (student) REFERENCES Students (idnr),
    FOREIGN KEY (course) REFERENCES Courses (code),
    CONSTRAINT okgrade CHECK (grade IN ('U', '3', '4', '5')),
    PRIMARY KEY (student, course)
);

CREATE TABLE WaitingList(
    student CHAR(10),
    course CHAR (6),
    position INT NOT NULL CHECK (position > 0),
    FOREIGN KEY (student) REFERENCES Students (idnr),
    FOREIGN KEY (course) REFERENCES LimitedCourses (code),
    PRIMARY KEY (student, course),
    UNIQUE(course, position)
);
