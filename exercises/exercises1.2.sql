-- Deletes everything to make this file re-runnable
\set QUIET true
SET client_min_messages TO NOTICE;
DROP SCHEMA public CASCADE;
CREATE SCHEMA public;
GRANT ALL ON SCHEMA public TO postgres;
\set QUIET false

--Items(_itemname_, price)
CREATE TABLE Items (
    itemname CHAR(20) PRIMARY KEY,
    price INT NOT NULL CHECK (price > 0)
);

--Categories(_catname_)
CREATE TABLE Categories (
    catname CHAR(10) PRIMARY KEY
);

--Categorized(_item_, category)
--category → Categories.catname
--item → Items.itemname
CREATE TABLE Categorized (
    item CHAR(20), 
    category CHAR(10) NOT NULL,
    FOREIGN KEY (item) REFERENCES Items (itemname),
    FOREIGN KEY (category) REFERENCES Categories (catname),
    PRIMARY KEY (item)
);

--Discounts (_category_, pricefactor)
--category → Categories.catname
CREATE TABLE Discounts (
    category CHAR(10),
    pricefactor FLOAT NOT NULL CHECK (pricefactor >= 0 AND pricefactor <= 1),
    FOREIGN KEY (category) REFERENCES Categories (catname),
    PRIMARY KEY (category)
);

