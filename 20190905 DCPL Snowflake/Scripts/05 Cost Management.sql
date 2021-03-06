--------------------------------------------------------------------------------------------
-- Cost Management (monitoring)
-- UTIL_DB.PUBLIC.VW_SF_WAREHOUSE_METERING_HISTORY - function to return credit usage details
-- *** IMPORTANT: Run as ACCOUNTADMIN or grant necessary permissions ***
--------------------------------------------------------------------------------------------

CREATE OR REPLACE VIEW UTIL_DB.PUBLIC.VW_SF_WAREHOUSE_METERING_HISTORY
AS
SELECT 
  START_TIME,
  END_TIME,
  WAREHOUSE_ID,
  WAREHOUSE_NAME,
  CREDITS_USED,
  TO_DATE(START_TIME) AS START_DATE,
  DATEDIFF(HOUR, START_TIME, END_TIME) AS WAREHOUSE_OPERATION_HOURS,
  HOUR(START_TIME) AS TIME_OF_DAY
FROM SNOWFLAKE.ACCOUNT_USAGE.WAREHOUSE_METERING_HISTORY;

CREATE OR REPLACE VIEW UTIL_DB.PUBLIC.VW_SF_STORAGE_USAGE_MONTHLY_HISTORY
AS
SELECT 
    DATE_TRUNC(month, USAGE_DATE) AS USAGE_MONTH
  , AVG(STORAGE_BYTES + STAGE_BYTES + FAILSAFE_BYTES) / POWER(1024, 3) AS TOTAL_BILLABLE_STORAGE_GB
  , AVG(STORAGE_BYTES ) / POWER(1024, 3) AS STORAGE_BILLABLE_STORAGE_GB
  , AVG(STAGE_BYTES ) / POWER(1024, 3) AS STAGE_BILLABLE_STORAGE_GB
  , AVG(FAILSAFE_BYTES ) / POWER(1024, 3) AS FAILSAFE_BILLABLE_STORAGE_GB
FROM SNOWFLAKE.ACCOUNT_USAGE.STORAGE_USAGE
GROUP BY DATE_TRUNC(month, USAGE_DATE) 
ORDER BY DATE_TRUNC(month, USAGE_DATE);

USE WAREHOUSE DEMO_WH_DCPL;

SELECT * FROM UTIL_DB.PUBLIC.VW_SF_WAREHOUSE_METERING_HISTORY LIMIT 10;

SELECT * FROM UTIL_DB.PUBLIC.VW_SF_STORAGE_USAGE_MONTHLY_HISTORY;

SELECT 400 - SUM(CREDITS_USED) AS CREDITS_LEFT FROM UTIL_DB.PUBLIC.VW_SF_WAREHOUSE_METERING_HISTORY;

