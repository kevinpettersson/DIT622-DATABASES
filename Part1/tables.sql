-- This file will contain all your tables

CREATE TABLE Students (
    idnr CHAR(10) PRIMARY KEY,
    name TEXT NOT NULL,
    login TEXT NOT NULL,
    program TEXT NOT NULL
);

CREATE TABLE Branches (
    name TEXT,
    program TEXT,
    PRIMARY KEY (name, program)
);

CREATE TABLE Courses (
    code CHAR(6) PRIMARY KEY,
    name TEXT NOT NULL,
    credits FLOAT NOT NULL,
    department TEXT NOT NULL
);

CREATE TABLE LimitedCourses (
    code CHAR(6) PRIMARY KEY,
    capacity INT NOT NULL,
    FOREIGN KEY (code) REFERENCES Courses (code)
);

CREATE TABLE StudentBranches (
    student CHAR(10) PRIMARY KEY,
    branch TEXT NOT NULL,
    program TEXT NOT NULL,
    FOREIGN KEY (student) REFERENCES Students (idnr),
    FOREIGN KEY (branch, program) REFERENCES Branches (name, program)
);

CREATE TABLE Classifications (
    name TEXT PRIMARY KEY
);


CREATE TABLE Classified (
    code CHAR(6),
    classification TEXT,
    FOREIGN KEY (code) REFERENCES Courses (code),
    FOREIGN KEY (classification) REFERENCES Classifications (name),
    PRIMARY KEY (code, classification)
);

CREATE TABLE MandatoryProgram (
    course CHAR(6),
    program TEXT,
    FOREIGN KEY (course) REFERENCES Courses (code),
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
    PRIMARY KEY (student, course)
);