----------------------------------------
-- Update just one row with max ID
----------------------------------------

USE [AdventureWorks2025];
GO
-- Update the highest salesorderid
DECLARE @maxsalesorderid INT;
SELECT @maxsalesorderid = MAX(SalesOrderID) FROM Sales.SalesOrderHeader;
BEGIN TRAN
UPDATE Sales.SalesOrderHeader
SET Freight = Freight * .10
WHERE SalesOrderID = @maxsalesorderid;
GO

-- Rollback the transaction when needed
ROLLBACK TRAN;
GO

---------------------------------------
-- Run another transaction
---------------------------------------

USE [AdventureWorks2025];
GO
-- Update a specific purchase order number
BEGIN TRAN;
UPDATE Sales.SalesOrderHeader
SET Freight = Freight * .10
WHERE PurchaseOrderNumber = 'PO18850127500';
GO

-- Rollback transaction if needed
ROLLBACK TRAN;
GO