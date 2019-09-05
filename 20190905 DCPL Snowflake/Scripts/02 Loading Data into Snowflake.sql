--------------------------------------------------------------------------------------------
-- Loading Data into Snowflake
--------------------------------------------------------------------------------------------

----------------------------------------------------------------
-- Batch Loading
-- Data taken from: https://s3.amazonaws.com/tripdata/index.html
----------------------------------------------------------------

USE ROLE SYSADMIN;

USE DEMO_DB_DCPL;

USE SCHEMA PUBLIC;

-- *** Create a stage here from UI ***

DESCRIBE STAGE DEMO_STAGE_DCPL;

LIST @DEMO_STAGE_DCPL;

USE WAREHOUSE ETL_WH;

CREATE OR REPLACE TABLE TRIPS  
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

DESCRIBE TABLE TRIPS;

SELECT COUNT(*) FROM TRIPS;

-- *** Create a file format from UI ***

COPY INTO TRIPS FROM @DEMO_STAGE_DCPL
FILE_FORMAT = DEMO_FORMAT_DCPL;

SELECT * FROM TABLE(VALIDATE(TRIPS, job_id => '_last'));

SELECT *
FROM TABLE(
  INFORMATION_SCHEMA.COPY_HISTORY(
    TABLE_NAME=>'TRIPS', START_TIME=> DATEADD(hours, -1, CURRENT_TIMESTAMP())
  )
);

SELECT *
FROM TABLE(
  INFORMATION_SCHEMA.WAREHOUSE_LOAD_HISTORY(
    DATE_RANGE_START=>DATEADD('hour',-1,CURRENT_TIMESTAMP())
  )
);

SELECT * FROM INFORMATION_SCHEMA.LOAD_HISTORY
WHERE SCHEMA_NAME=CURRENT_SCHEMA() 
AND TABLE_NAME='TRIPS';

/*
COPY INTO TRIPS FROM @DEMO_STAGE_DCPL
FILE_FORMAT= (
  TYPE='CSV' 
  FIELD_DELIMITER = ',' 
  SKIP_HEADER = 1,
  FIELD_OPTIONALLY_ENCLOSED_BY = '"'  
)
PATTERN= '.*.csv';
*/

SELECT COUNT(*) FROM TRIPS;

SELECT * FROM TRIPS LIMIT 10;

SELECT AVG(TRIPDURATION) AS AVG_TRIP_DURATION, DAYNAME(STARTTIME) AS WEEKDAY, EXTRACT(weekday FROM STARTTIME) AS DAYNUM
FROM TRIPS
GROUP BY DAYNAME(STARTTIME), EXTRACT(weekday FROM STARTTIME)
ORDER BY EXTRACT(weekday FROM STARTTIME);

SELECT 
  DATE_TRUNC('HOUR', STARTTIME) AS DATE,
  COUNT(*) AS "NUM TRIPS",
  AVG(TRIPDURATION)/60 AS "AVG DURATION (MINS)", 
  AVG(HAVERSINE(START_STATION_LATITUDE, START_STATION_LONGITUDE, END_STATION_LATITUDE, END_STATION_LONGITUDE)) AS "AVG DISTANCE (KM)" 
FROM TRIPS
GROUP BY 1 ORDER BY 1;