--------------------------------------------------------------------------------------------
-- Key Concept & Architecture
--------------------------------------------------------------------------------------------

-- Let's see if there are any credits left ;-)

USE WAREHOUSE COMPUTE_WH_1;

USE ROLE ACCOUNTADMIN;

SELECT 400 - SUM(CREDITS_USED) AS CREDITS_LEFT FROM UTIL_DB.PUBLIC.VW_SF_WAREHOUSE_METERING_HISTORY;

----------------------------------
-- Data Warehouse
----------------------------------

USE ROLE SYSADMIN;

CREATE OR REPLACE WAREHOUSE DEMO_WH_DCPL
WITH 
    WAREHOUSE_SIZE = 'XSMALL' 
    AUTO_SUSPEND = 300 
    AUTO_RESUME = TRUE 
    MIN_CLUSTER_COUNT = 1 
    MAX_CLUSTER_COUNT = 2 
    SCALING_POLICY = 'ECONOMY' 
    COMMENT = 'Demo warehouse for purpose of 127. meeting of Data Community Poland in Warsaw';
    
USE WAREHOUSE DEMO_WH_DCPL;

----------------------------------
-- Database
----------------------------------
 
CREATE OR REPLACE DATABASE DEMO_DB_DCPL 
COMMENT = 'Demo database for purpose of 127. meeting of Data Community Poland in Warsaw';

USE DEMO_DB_DCPL;

USE SCHEMA PUBLIC;

----------------------------------
-- Some queries on metadata
----------------------------------

SELECT CURRENT_WAREHOUSE(), CURRENT_DATABASE(), CURRENT_SCHEMA();

DESCRIBE TABLE "SNOWFLAKE_SAMPLE_DATA"."TPCH_SF1000"."ORDERS";

SELECT TO_VARCHAR(COUNT(*), '999,999,999,999,999') FROM "SNOWFLAKE_SAMPLE_DATA"."TPCH_SF1000"."ORDERS";

-----------------------------------
-- Performance demo - scale-up/down
-----------------------------------

SELECT
    L_ORDERKEY,
    SUM(L_EXTENDEDPRICE * (1 - L_DISCOUNT)) AS REVENUE,
    O_ORDERDATE,
    O_SHIPPRIORITY
FROM
    SNOWFLAKE_SAMPLE_DATA.TPCH_SF1000.CUSTOMER,
    SNOWFLAKE_SAMPLE_DATA.TPCH_SF1000.ORDERS,
    SNOWFLAKE_SAMPLE_DATA.TPCH_SF1000.LINEITEM
WHERE
    C_MKTSEGMENT = 'BUILDING'
    AND C_CUSTKEY = O_CUSTKEY
    AND L_ORDERKEY = O_ORDERKEY
    AND O_ORDERDATE < DATE '1995-03-15'
    AND L_SHIPDATE > DATE '1995-03-15'
GROUP BY
    L_ORDERKEY,
    O_ORDERDATE,
    O_SHIPPRIORITY
ORDER BY
    REVENUE DESC,
    O_ORDERDATE
LIMIT 20;

----------------------------------
-- Auto-scaling demo
----------------------------------

USE WAREHOUSE COMPUTE_WH_2;
SET MONTH = (SELECT UNIFORM(1, 12, RANDOM()));
SET YEAR = (SELECT UNIFORM(1994, 1998, RANDOM()));
SELECT
    YEAR(O_ORDERDATE),
    MONTH(O_ORDERDATE),
    SUM(O_TOTALPRICE) AS AMOUNT
FROM SNOWFLAKE_SAMPLE_DATA.TPCH_SF1000.ORDERS
WHERE YEAR(O_ORDERDATE) = $YEAR AND MONTH(O_ORDERDATE) = $MONTH
GROUP BY YEAR(O_ORDERDATE),
    MONTH(O_ORDERDATE);


    

