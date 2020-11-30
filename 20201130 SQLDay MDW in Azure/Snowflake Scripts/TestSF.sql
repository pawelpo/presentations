USE WAREHOUSE ANALYTICS_WH;
SET MONTH = (SELECT UNIFORM(1, 12, RANDOM()));
SET YEAR = (SELECT UNIFORM(1994, 1998, RANDOM()));
SELECT
    YEAR(O_ORDERDATE),
    MONTH(O_ORDERDATE),
    SUM(O_TOTALPRICE) AS AMOUNT
FROM SNOWFLAKE_SAMPLE_DATA.TPCH_SF100.ORDERS
WHERE YEAR(O_ORDERDATE) = $YEAR AND MONTH(O_ORDERDATE) = $MONTH
GROUP BY YEAR(O_ORDERDATE),
    MONTH(O_ORDERDATE);