--------------------------------------------------------------------------------------------
-- Unique Features
--------------------------------------------------------------------------------------------

------------------------------
-- Time Travel
------------------------------

USE ROLE SYSADMIN;

USE WAREHOUSE DEMO_WH_DCPL;

USE DEMO_DB_DCPL;

USE SCHEMA PUBLIC;

SELECT COUNT(*) FROM TRIPS;

DELETE FROM TRIPS WHERE STARTTIME >= '2018-03-15';

SELECT COUNT(*) FROM TRIPS AT (OFFSET => -60*3);
SELECT COUNT(*) FROM TRIPS AT (STATEMENT => '018ea248-0087-f567-0000-0000125db179');

TRUNCATE TABLE TRIPS;

INSERT INTO TRIPS
SELECT * FROM TRIPS AT(OFFSET => -60*3);

SELECT COUNT(*) FROM TRIPS;

DROP TABLE TRIPS;

SELECT * FROM TRIPS LIMIT 10;

UNDROP TABLE TRIPS;

SELECT * FROM TRIPS LIMIT 10;

CREATE TABLE TRIPS_CLONE CLONE TRIPS;

SELECT * FROM TRIPS_CLONE LIMIT 10;

CREATE OR REPLACE DATABASE DEMO_DB_DCPL_CLONE CLONE DEMO_DB_DCPL;

------------------------------
-- Semi-structured Data (JSON)
------------------------------

CREATE OR REPLACE STAGE DEMO_STAGE_NYC_WEATHER_DCPL
URL = 's3://snowflake-workshop-lab/weather-nyc';

LIST @DEMO_STAGE_NYC_WEATHER_DCPL;

SHOW STAGES;

CREATE OR REPLACE TABLE JSON_WEATHER_DATA (v variant);

COPY INTO JSON_WEATHER_DATA 
FROM @DEMO_STAGE_NYC_WEATHER_DCPL 
FILE_FORMAT = (
  TYPE = JSON
);

SELECT * FROM JSON_WEATHER_DATA LIMIT 10;

CREATE OR REPLACE VIEW JSON_WEATHER_DATA_VIEW AS
SELECT
  v:time::timestamp AS OBSERVATION_TIME,
  v:city.id::int AS CITY_ID,
  v:city.name::string AS CITY_NAME,
  v:city.country::string AS COUNTRY,
  v:city.coord.lat::float AS CITY_LAT,
  v:city.coord.lon::float AS CITY_LON,
  v:clouds.all::int AS CLOUDS,
  (v:main.temp::float)-273.15 AS TEMP_AVG,
  (v:main.temp_min::float)-273.15 AS TEMP_MIN,
  (v:main.temp_max::float)-273.15 AS TEMP_MAX,
  v:weather[0].main::string AS WEATHER,
  v:weather[0].description::string AS WEATHER_DESC,
  v:weather[0].icon::string AS WEATHER_ICON,
  v:wind.deg::float AS WIND_DIR,
  v:wind.speed::float AS WIND_SPEED
FROM JSON_WEATHER_DATA
WHERE CITY_ID = 5128638;

SELECT * FROM JSON_WEATHER_DATA_VIEW
WHERE DATE_TRUNC('month', OBSERVATION_TIME) = '2018-01-01' 
LIMIT 10;

SELECT 
  WEATHER AS CONDITIONS
  ,COUNT(*) AS NUM_TRIPS
FROM TRIPS 
LEFT OUTER JOIN JSON_WEATHER_DATA_VIEW
ON DATE_TRUNC('hour', OBSERVATION_TIME) = DATE_TRUNC('hour', STARTTIME)
WHERE CONDITIONS IS NOT NULL
GROUP BY 1 ORDER BY 2 DESC;

CREATE OR REPLACE TABLE GOOGLE_ANALYTICS (log variant);

-- *** Load data from local file here ***

SELECT * FROM GOOGLE_ANALYTICS LIMIT 10;

WITH CTE AS (
  SELECT 
    GA.log:date::string AS DATE,
    h.value:hour::integer AS HOUR 
  FROM 
    GOOGLE_ANALYTICS GA,
    LATERAL FLATTEN (input => GA.log:hits) h
)
SELECT DATE, HOUR, COUNT(*) AS HITS
FROM CTE
GROUP BY DATE, HOUR;
  
------------------------------
-- Secure Data Sharing
------------------------------

USE ROLE ACCOUNTADMIN;

CREATE OR REPLACE SHARE "DEMO_SHARE_DCPL" COMMENT='Demo share';
GRANT USAGE ON DATABASE "DEMO_DB_DCPL" TO SHARE "DEMO_SHARE_DCPL";
GRANT USAGE ON SCHEMA "DEMO_DB_DCPL"."PUBLIC" TO SHARE "DEMO_SHARE_DCPL";
GRANT SELECT ON VIEW "DEMO_DB_DCPL"."PUBLIC"."TRIPS" TO SHARE "DEMO_SHARE_DCPL";

SHOW GRANTS TO SHARE DEMO_SHARE_DCPL;

ALTER SHARE "DEMO_SHARE_DCPL" ADD ACCOUNTS = sq03996;

SHOW GRANTS OF SHARE DEMO_SHARE_DCPL;
