SELECT @@VERSION;
GO

----------------------------------------------
-- Switch to master to check database versions
----------------------------------------------

SELECT  
	db.name [Database],
	ds.edition [Edition],
	ds.service_objective [Service Objective]
FROM sys.database_service_objectives   AS ds
JOIN sys.databases                     AS db 
ON ds.database_id = db.database_id;
GO

-----------------------------
-- Star Schema - Reservations
-----------------------------

DROP TABLE dbo.FactReservation;
GO

SELECT FORMAT(COUNT(*), '#,#') FROM dbo.reservations;

CREATE TABLE dbo.FactReservation 
WITH (DISTRIBUTION = HASH(ReservationID))
AS
SELECT TOP (100000000)
	ROW_NUMBER() OVER (ORDER BY (SELECT 1)) AS ReservationID,
	customer AS CustomerKey,
	location_from AS LocationFromKey,
	location_to AS LocationToKey,
	price AS Price,
	CONVERT(int, CONVERT(varchar(8), created_date, 112)) AS DateKey
FROM dbo.reservations
OPTION (LABEL = 'CTAS : create table FactReservation');
GO

SELECT *
FROM sys.dm_pdw_exec_requests
WHERE [label] LIKE 'CTAS%';
GO

SELECT FORMAT(COUNT_BIG(*), '#,#') FROM dbo.FactReservation;
GO

DBCC PDW_SHOWSPACEUSED('dbo.FactReservation');
GO

CREATE TABLE dbo.DimCustomer
WITH (DISTRIBUTION = REPLICATE)
AS
SELECT DISTINCT
	customer AS CustomerKey,
	customer AS CustomerID,
	CONCAT('Customer #', customer) AS CustomerName
FROM dbo.reservations;

CREATE TABLE dbo.DimLocation
WITH (DISTRIBUTION = REPLICATE)
AS
SELECT DISTINCT
	location_from AS LocationKey,
	location_from AS LocationID,
	CONCAT('Location #', location_from) AS LocationName
FROM dbo.reservations;

CREATE TABLE dbo.DimTime 
WITH (DISTRIBUTION = REPLICATE)
AS
SELECT DISTINCT
	CONVERT(int, CONVERT(varchar(8), created_date, 112)) AS DateKey,
	CONVERT(date, created_date) AS Date,
	YEAR(created_date) AS Year,
	CONCAT(YEAR(created_date), '-Q', DATEPART(quarter, created_date)) AS Quarter,
	CONVERT(varchar(7), created_date, 120) AS Month,
	DATENAME(month, created_date) AS MonthName,
	DATEPART(week, created_date) AS Week,
	DATENAME(weekday, created_date) AS Weekday
FROM dbo.reservations;

DBCC DROPCLEANBUFFERS;
DBCC FREEPROCCACHE;
DBCC DROPRESULTSETCACHE;
SET RESULT_SET_CACHING OFF;
GO

SELECT
	lf.LocationKey AS StartingLocationKey,
	lf.LocationName AS StartingLocation,
	t.Year,
	t.Month,
	COUNT_BIG(r.ReservationID) AS Reservations,
	SUM(r.Price) AS SalesAmount
FROM dbo.FactReservation AS r
INNER JOIN dbo.DimTime AS t
ON r.DateKey = t.DateKey
INNER JOIN dbo.DimLocation AS lf
ON r.LocationFromKey = lf.LocationKey
GROUP BY lf.LocationKey, lf.LocationName, t.Year, t.Month
ORDER BY lf.LocationName, t.Month;

DBCC SHOW_STATISTICS('dbo.FactReservation', stats_FactReservation_DateKey);

ALTER DATABASE SQLPool1
SET AUTO_CREATE_STATISTICS ON;

CREATE STATISTICS stats_FactReservation_DateKey ON dbo.FactReservation(DateKey) WITH FULLSCAN;
CREATE STATISTICS stats_FactReservation_LocationFromKey ON dbo.FactReservation(LocationFromKey) WITH FULLSCAN;

-------------------------
-- Materialized view
-------------------------

DROP VIEW dbo.vFactReservation;
GO
CREATE MATERIALIZED VIEW dbo.vFactReservation 
WITH (DISTRIBUTION = HASH(StartingLocationKey))
AS
SELECT
	lf.LocationKey AS StartingLocationKey,
	lf.LocationName AS StartingLocation,
	t.Year,
	t.Month,
	COUNT_BIG(r.ReservationID) AS Reservations,
	SUM(r.Price) AS SalesAmount
FROM dbo.FactReservation AS r
INNER JOIN dbo.DimTime AS t
ON r.DateKey = t.DateKey
INNER JOIN dbo.DimLocation AS lf
ON r.LocationFromKey = lf.LocationKey
GROUP BY lf.LocationKey, lf.LocationName, t.Year, t.Month;
GO

-------------------------
-- Generate index REBUILD
-------------------------

SELECT DISTINCT
	'ALTER INDEX ALL ON ' + s.[name] + '.' + t.[name] + ' REBUILD;' AS [T-SQL to Rebuild Index]
FROM 
	[sys].[pdw_nodes_column_store_row_groups] rg
	JOIN [sys].[pdw_nodes_tables] pt
		ON rg.[object_id] = pt.[object_id] AND rg.[pdw_node_id] = pt.[pdw_node_id] AND pt.[distribution_id] = rg.[distribution_id]
	JOIN sys.[pdw_table_mappings] tm 
		ON pt.[name] = tm.[physical_name]
	INNER JOIN [sys].[tables] t 
		ON tm.[object_id] = t.[object_id]
	INNER JOIN [sys].[schemas] s
		ON t.[schema_id] = s.[schema_id]
ORDER BY
	1;

ALTER INDEX ALL ON dbo.DimCustomer REBUILD;
ALTER INDEX ALL ON dbo.DimLocation REBUILD;
ALTER INDEX ALL ON dbo.DimTime REBUILD;
ALTER INDEX ALL ON dbo.FactReservation REBUILD;

--------------------------
-- Monitoring: concurrency
--------------------------

SELECT
	SUM(CASE WHEN r.[status] ='Running'   THEN 1 ELSE 0 END)							[running_queries],
	SUM(CASE WHEN r.[status] ='Running'   THEN rw.concurrency_slots_used ELSE 0 END)	[running_queries_slots],
	SUM(CASE WHEN r.[status] ='Suspended' THEN 1 ELSE 0 END)							[queued_queries],
	SUM(CASE WHEN rw.[state] ='Queued'    THEN rw.concurrency_slots_used ELSE 0 END)	[queued_queries_slots]
FROM
	sys.dm_pdw_exec_requests r 
	JOIN sys.dm_pdw_resource_waits rw on rw.request_id = r.request_id
WHERE
	( (r.[status] = 'Running' AND r.resource_class IS NOT NULL ) OR r.[status] ='Suspended' )
	AND rw.[type] ='UserConcurrencyResourceType';

--------------------------
-- Monitoring: data skew
--------------------------

SELECT * FROM microsoft.vw_tables_with_skew;