-- This will be based on tables.sql from part 1,
-- extended and corrected to match your final schema.
-- This file will contain all your tables

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
    FOREIGN KEY (program) REFERENCES Programs (name),
    UNIQUE (login)
);

CREATE TABLE StudentBranches (
    student CHAR(10),
    branch TEXT,
    program TEXT,
    FOREIGN KEY (student) REFERENCES Students (idnr),
    FOREIGN KEY (program) REFERENCES Programs (name),
    FOREIGN KEY (branch, program) REFERENCES Branches (name, program),
    PRIMARY KEY (student, branch, program)
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
    program TEXT,
    FOREIGN KEY (course) REFERENCES Courses (code),
    FOREIGN KEY (branch, program) REFERENCES Branches (name, program),
    PRIMARY KEY (course, branch, program)
);

CREATE TABLE RecommendedBranch (
    course CHAR(6),
    branch TEXT,
    program TEXT,
    FOREIGN KEY (course) REFERENCES Courses (code),
    FOREIGN KEY (branch, program) REFERENCES Branches (name, program),
    PRIMARY KEY (course, branch, program)
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