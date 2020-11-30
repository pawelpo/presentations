-- Create a database for SQL on-demand
CREATE DATABASE DemoOnDemand;

-- Basic query on top of data lake
SELECT FORMAT(COUNT(*), '#,#')
FROM
    OPENROWSET(
        BULK 'https://synapsedemopp1adls.dfs.core.windows.net/datalake/nyc/*.parquet',
        FORMAT='PARQUET'
    ) AS [r];

-- Simple aggregation
SELECT
    DATEPART(hour, TPEPPICKUPDATETIME) AS PickupHour,
    COUNT(*) AS Trips
FROM
    OPENROWSET(
        BULK 'https://synapsedemopp1adls.dfs.core.windows.net/datalake/nyc/*.parquet',
        FORMAT='PARQUET'
    ) AS [r]
GROUP BY DATEPART(hour, TPEPPICKUPDATETIME)
ORDER BY PickupHour;

-- A bit more complex aggregation
SELECT
    YEAR(TPEPPICKUPDATETIME) AS Year,
    CONCAT(YEAR(TPEPPICKUPDATETIME), '-', RIGHT(CONCAT('0', MONTH(TPEPPICKUPDATETIME)), 2)) AS Month,
    DATEPART(hour, TPEPPICKUPDATETIME) AS Hour,
    SUM(PASSENGERCOUNT) AS Passengers,
    COUNT(*) AS Trips,
    SUM(TIPAMOUNT) AS Tips
FROM
    OPENROWSET(
        BULK 'https://synapsedemopp1adls.dfs.core.windows.net/datalake/nyc/*.parquet',
        FORMAT='PARQUET'
    ) AS [r]
GROUP BY 
    YEAR(TPEPPICKUPDATETIME),
    CONCAT(YEAR(TPEPPICKUPDATETIME), '-', RIGHT(CONCAT('0', MONTH(TPEPPICKUPDATETIME)), 2)),
    DATEPART(hour, TPEPPICKUPDATETIME)
ORDER BY Month, Hour;

-- See how much data processed overall
SELECT * FROM sys.configurations WHERE name LIKE 'Data processed%';

SELECT Type, FORMAT(Data_processed_mb/1000., '#,#.00') AS Processed_GB 
FROM sys.dm_external_data_processed;
