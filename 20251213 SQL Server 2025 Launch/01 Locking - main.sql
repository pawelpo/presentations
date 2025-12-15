---------------------------------------
-- Hey, SQL Server, introduce yourself!
---------------------------------------

SELECT @@VERSION;

---------------------------------------
-- Disable a few things
---------------------------------------

USE [master];
GO
ALTER DATABASE [AdventureWorks2025]
SET OPTIMIZED_LOCKING = OFF
WITH ROLLBACK IMMEDIATE;
ALTER DATABASE [AdventureWorks2025]
SET READ_COMMITTED_SNAPSHOT OFF
WITH ROLLBACK IMMEDIATE;
GO

----------------------------------------
-- Check requirements
----------------------------------------

SELECT
  IsOptimizedLockingOn = DATABASEPROPERTYEX('AdventureWorks2025', 'IsOptimizedLockingOn'),
  RCSI = is_read_committed_snapshot_on,
  ADR  = is_accelerated_database_recovery_on
FROM sys.databases
WHERE name = 'AdventureWorks2025';
GO

/*----------------------------------------
DEMO 1: No optimized locking
----------------------------------------*/

----------------------------------------
-- Let's do a small update
----------------------------------------

USE [AdventureWorks2025];
GO
-- Run this batch first to update 2500 rows
DECLARE @minsalesorderid INT;
SELECT @minsalesorderid = MIN(SalesOrderID) FROM Sales.SalesOrderHeader;
BEGIN TRAN
UPDATE Sales.SalesOrderHeader
SET Freight = Freight * .10
WHERE SalesOrderID <= @minsalesorderid + 2500;
GO

-- Rollback the transaction when needed
ROLLBACK TRAN;
GO

----------------------------------------
-- Let's see locks
----------------------------------------

SELECT 
    resource_type,
    resource_database_id,
    resource_associated_entity_id,
   -- resource_description,
    request_mode,
    request_session_id,
    request_status,
    COUNT(*) AS lock_count
FROM 
    sys.dm_tran_locks
WHERE resource_type != 'DATABASE'
GROUP BY 
    resource_type,
    resource_database_id,
    resource_associated_entity_id,
    request_mode,
    request_session_id,
    request_status
ORDER BY 
    resource_type,
    resource_database_id,
    resource_associated_entity_id,
    request_mode,
    request_session_id,
    request_status;
GO

----------------------------------------
-- Let's make a bigger update
----------------------------------------

USE [AdventureWorks2025];
GO
-- Run this batch first to update 10000 rows
DECLARE @minsalesorderid INT;
SELECT @minsalesorderid = MIN(SalesOrderID) FROM Sales.SalesOrderHeader;
BEGIN TRAN
UPDATE Sales.SalesOrderHeader
SET Freight = Freight * .10
WHERE SalesOrderID <= @minsalesorderid + 10000;
GO

-- *** Run another transaction here!!! ***

-- Rollback the transaction when needed
ROLLBACK TRAN;
GO

----------------------------------------
-- Let's see locks again
----------------------------------------

SELECT 
    resource_type,
    resource_database_id,
    resource_associated_entity_id,
   -- resource_description,
    request_mode,
    request_session_id,
    request_status,
    COUNT(*) AS lock_count
FROM 
    sys.dm_tran_locks
WHERE resource_type != 'DATABASE'
GROUP BY 
    resource_type,
    resource_database_id,
    resource_associated_entity_id,
    request_mode,
    request_session_id,
    request_status
ORDER BY 
    resource_type,
    resource_database_id,
    resource_associated_entity_id,
    request_mode,
    request_session_id,
    request_status;
GO

----------------------------------------
-- Check for blocking
----------------------------------------

SELECT 
    blocking_session_id AS BlockingSessionID,
    session_id AS BlockedSessionID,
    wait_type,
    wait_time,
    wait_resource,
    DB_NAME(database_id) AS DatabaseName,
    TEXT AS BlockingQuery
FROM 
    sys.dm_exec_requests
CROSS APPLY 
    sys.dm_exec_sql_text(sql_handle)
WHERE 
    blocking_session_id <> 0
ORDER BY 
    BlockingSessionID, BlockedSessionID;
GO

/*----------------------------------------
DEMO 2: Optimized locking on
----------------------------------------*/

USE [master];
GO
ALTER DATABASE [AdventureWorks2025]
SET OPTIMIZED_LOCKING = ON
WITH ROLLBACK IMMEDIATE;
GO

----------------------------------------
-- Check requirements
----------------------------------------

SELECT
  IsOptimizedLockingOn = DATABASEPROPERTYEX('AdventureWorks2025', 'IsOptimizedLockingOn'),
  RCSI = is_read_committed_snapshot_on,
  ADR  = is_accelerated_database_recovery_on
FROM sys.databases
WHERE name = 'AdventureWorks2025';
GO

----------------------------------------
-- Let's try again!
----------------------------------------

USE [AdventureWorks2025];
GO
-- Run this batch first to update 10000 rows
DECLARE @minsalesorderid INT;
SELECT @minsalesorderid = MIN(SalesOrderID) FROM Sales.SalesOrderHeader;
BEGIN TRAN
UPDATE Sales.SalesOrderHeader
SET Freight = Freight * .10
WHERE SalesOrderID <= @minsalesorderid + 10000;
GO

-- *** Run another transaction here!!! ***

-- Rollback the transaction when needed
ROLLBACK TRAN;
GO

----------------------------------------
-- Let's see locks again
----------------------------------------

SELECT 
    resource_type,
    resource_database_id,
    resource_associated_entity_id,
   -- resource_description,
    request_mode,
    request_session_id,
    request_status,
    COUNT(*) AS lock_count
FROM 
    sys.dm_tran_locks
WHERE resource_type != 'DATABASE'
GROUP BY 
    resource_type,
    resource_database_id,
    resource_associated_entity_id,
    request_mode,
    request_session_id,
    request_status
ORDER BY 
    resource_type,
    resource_database_id,
    resource_associated_entity_id,
    request_mode,
    request_session_id,
    request_status;
GO

----------------------------------------
-- Let's try something different
----------------------------------------

USE [AdventureWorks2025];
GO
-- Update a specific purchase order number
BEGIN TRAN;
UPDATE Sales.SalesOrderHeader
SET Freight = Freight * .10
WHERE PurchaseOrderNumber = 'PO522145787';
GO

-- *** Run another transaction here!!! ***

-- Rollback transaction if needed
ROLLBACK TRAN;
GO

----------------------------------------
-- Let's see locks again
----------------------------------------

SELECT 
    resource_type,
    resource_database_id,
    resource_associated_entity_id,
   -- resource_description,
    request_mode,
    request_session_id,
    request_status,
    COUNT(*) AS lock_count
FROM 
    sys.dm_tran_locks
WHERE resource_type != 'DATABASE'
GROUP BY 
    resource_type,
    resource_database_id,
    resource_associated_entity_id,
    request_mode,
    request_session_id,
    request_status
ORDER BY 
    resource_type,
    resource_database_id,
    resource_associated_entity_id,
    request_mode,
    request_session_id,
    request_status;
GO

----------------------------------------
-- Check for blocking
----------------------------------------

SELECT 
    blocking_session_id AS BlockingSessionID,
    session_id AS BlockedSessionID,
    wait_type,
    wait_time,
    wait_resource,
    DB_NAME(database_id) AS DatabaseName,
    TEXT AS BlockingQuery
FROM 
    sys.dm_exec_requests
CROSS APPLY 
    sys.dm_exec_sql_text(sql_handle)
WHERE 
    blocking_session_id <> 0
ORDER BY 
    BlockingSessionID, BlockedSessionID;
GO

---------------------------------------
-- Enable RCSI
---------------------------------------

USE [master];
GO
ALTER DATABASE [AdventureWorks2025]
SET READ_COMMITTED_SNAPSHOT ON
WITH ROLLBACK IMMEDIATE;
GO

----------------------------------------
-- Let's try something different
----------------------------------------

USE [AdventureWorks2025];
GO
-- Update a specific purchase order number
DECLARE @minsalesorderid INT;
SELECT @minsalesorderid = MIN(SalesOrderID) FROM Sales.SalesOrderHeader;
BEGIN TRAN;
UPDATE Sales.SalesOrderHeader
SET Freight = Freight * .10
WHERE PurchaseOrderNumber = 'PO522145787';
GO

-- *** Run another transaction here!!! ***

-- Rollback transaction if needed
ROLLBACK TRAN;
GO

----------------------------------------
-- Let's see locks again
----------------------------------------

SELECT 
    resource_type,
    resource_database_id,
    resource_associated_entity_id,
   -- resource_description,
    request_mode,
    request_session_id,
    request_status,
    COUNT(*) AS lock_count
FROM 
    sys.dm_tran_locks
WHERE resource_type != 'DATABASE'
GROUP BY 
    resource_type,
    resource_database_id,
    resource_associated_entity_id,
    request_mode,
    request_session_id,
    request_status
ORDER BY 
    resource_type,
    resource_database_id,
    resource_associated_entity_id,
    request_mode,
    request_session_id,
    request_status;
GO