-- Deletes everything to make this file re-runnable
\set QUIET true
SET client_min_messages TO NOTICE;
DROP SCHEMA public CASCADE;
CREATE SCHEMA public;
GRANT ALL ON SCHEMA public TO postgres;
\set QUIET false

-- a) 

-- Periods(_pname_, started, ended)
CREATE TABLE Periods (
    pname TEXT PRIMARY KEY,
    started INT NOT NULL,
    ended INT NOT NULL,
    CHECK(started <= ended)
);

-- Events(_ename_, year)
CREATE TABLE Events (
    ename TEXT PRIMARY KEY,
    year INT NOT NULL
);

-- example/test inserts
INSERT INTO Periods VALUES ('P1', 1950, 2050);
INSERT INTO Periods VALUES ('P2', 1975, 2150);
INSERT INTO Periods VALUES ('P3', 1920, 1975);

INSERT INTO Events VALUES ('E1', 1925); -- In P3 only
INSERT INTO Events VALUES ('E2', 2150); -- In P2 only
INSERT INTO Events VALUES ('E3', 1975); -- In P1, P2 and P3
INSERT INTO Events VALUES ('The GCHD', 2000); -- In P1 and P2

-- b)

-- a view for finding all periods the event is in and a query to show the view.
CREATE VIEW FindAllPeriods AS (
SELECT pname, ename
FROM Periods, Events
WHERE started <= year AND year <= ended);

-- query for showing FindAllPeriods
SELECT *
FROM FindAllPeriods
ORDER BY pname, ename;

-- a query that finds the names of all events that occurred during any of the same historical periods as “The Great Collapsing Hrung Disaster”
WITH InPeriods AS (
    SELECT pname 
    FROM FindAllPeriods
    WHERE ename = 'The GCHD'
)
SELECT DISTINCT ename
FROM FindAllPeriods
WHERE pname IN (SELECT pname FROM InPeriods);

-- c)

-- a query that finds the name of the most eventful historical period(s).
WITH CountEvents AS (
    SELECT pname, COUNT(ename) AS events 
    FROM FindAllPeriods
    GROUP BY pname
)
SELECT pname 
FROM CountEvents
WHERE events = (SELECT MAX(events) FROM CountEvents);