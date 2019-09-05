--------------------------------------------------------------------------------------------
-- SQL Surface
--------------------------------------------------------------------------------------------

------------------------------
-- Multi-table INSERT
------------------------------

USE ROLE SYSADMIN;

USE WAREHOUSE DEMO_WH_DCPL;

USE DEMO_DB_DCPL;

USE SCHEMA PUBLIC;

CREATE OR REPLACE TABLE TRIPS_201801
(
  TRIPDURATION integer,
  STARTTIME timestamp,
  STOPTIME timestamp,
  START_STATION_ID integer,
  START_STATION_NAME string,
  START_STATION_LATITUDE float,
  START_STATION_LONGITUDE float,
  END_STATION_ID integer,
  END_STATION_NAME string,
  END_STATION_LATITUDE float,
  END_STATION_LONGITUDE float,
  BIKEID integer,
  USERTYPE string,
  BIRTH_YEAR integer,
  GENDER integer
);

CREATE OR REPLACE TABLE TRIPS_201802 LIKE TRIPS;

SELECT COUNT(*) FROM TRIPS_201801;
SELECT COUNT(*) FROM TRIPS_201802;

INSERT ALL
WHEN EXTRACT(month FROM STARTTIME) = 1 THEN
    INTO TRIPS_201801
WHEN EXTRACT(month FROM STARTTIME) = 2 THEN
    INTO TRIPS_201802
SELECT * FROM TRIPS;

------------------------------
-- Stored procedures
------------------------------

CREATE OR REPLACE PROCEDURE SP_TRIPS_TOP3_STATIONS()
RETURNS string
LANGUAGE JAVASCRIPT
AS
$$
try {   
    var stmt1 = snowflake.createStatement( { sqlText: "SELECT START_STATION_NAME, COUNT(*) FROM TRIPS GROUP BY START_STATION_NAME ORDER BY 2 DESC LIMIT 3" } );  
    var rs1 = stmt1.execute();
    var stations = "Top 3 start stations: ";
   
    while (rs1.next()) {
        stations += rs1.START_STATION_NAME + ", ";
    }

    return stations.slice(0, -2);
}
catch (err) {

    return "FAILED (Exception):   " + err;

}
$$;

CALL SP_TRIPS_TOP3_STATIONS();

------------------------------
-- CONNECT BY
------------------------------

CREATE OR REPLACE TABLE EMPLOYEES (
  TITLE varchar NOT NULL, 
  EMPLOYEE_ID integer NOT NULL, 
  MANAGER_ID integer NULL
);

INSERT INTO EMPLOYEES (TITLE, EMPLOYEE_ID, MANAGER_ID) 
VALUES
  ('President', 1, NULL),  -- The President has no manager.
  ('Vice President Engineering', 10, 1),
  ('Programmer', 100, 10),
  ('QA Engineer', 101, 10),
  ('Vice President HR', 20, 1),
  ('Health Insurance Analyst', 200, 20);
  
SELECT 
  EMPLOYEE_ID, 
  MANAGER_ID, 
  TITLE,
  SYS_CONNECT_BY_PATH(TITLE, ' -> ') AS PATH
FROM EMPLOYEES
START WITH TITLE = 'President'
CONNECT BY
  MANAGER_ID = PRIOR EMPLOYEE_ID
ORDER BY EMPLOYEE_ID;