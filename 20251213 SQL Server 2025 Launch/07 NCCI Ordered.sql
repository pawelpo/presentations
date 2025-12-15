---------------------------------------
-- Let's turn some stats on
---------------------------------------

USE [WideWorldImporters];
GO
SET STATISTICS IO ON;
SET STATISTICS TIME ON;
GO

/*
DROP TABLE Sales.OrdersBIG;

SELECT TOP 0 *
INTO Sales.OrdersBIG
FROM Sales.Orders;

ALTER TABLE Sales.OrdersBIG
ADD CONSTRAINT PK_SalesOrdersBIG PRIMARY KEY CLUSTERED (OrderID ASC);

INSERT INTO Sales.OrdersBIG (
  OrderID, CustomerID, SalespersonPersonID, PickedByPersonID, 
  ContactPersonID, BackorderOrderID, OrderDate, ExpectedDeliveryDate, 
  CustomerPurchaseOrderNumber, IsUndersupplyBackordered, Comments, 
  DeliveryInstructions, InternalComments, PickingCompletedWhen, 
  LastEditedBy, LastEditedWhen) 
SELECT 
 Orders.OrderID + (ORDERS2.OrderID * 100000) AS OrderID, 
 Orders.CustomerID, Orders.SalespersonPersonID, Orders.PickedByPersonID, Orders.ContactPersonID, 
 Orders.BackorderOrderID, Orders.OrderDate, Orders.ExpectedDeliveryDate, 
 Orders.CustomerPurchaseOrderNumber, Orders.IsUndersupplyBackordered, Orders.Comments, 
 Orders.DeliveryInstructions, Orders.InternalComments, Orders.PickingCompletedWhen, 
 Orders.LastEditedBy, Orders.LastEditedWhen 
FROM Sales.Orders 
LEFT JOIN Sales.Orders Orders2 
ON Orders2.OrderID <= 200;

CREATE NONCLUSTERED COLUMNSTORE INDEX NCCI_SalesOrdersBIG
ON Sales.OrdersBIG (OrderDate, ExpectedDeliveryDate, BackorderOrderID)  
ORDER (OrderDate);

CREATE NONCLUSTERED COLUMNSTORE INDEX NCCI_SalesOrdersBIG
ON Sales.OrdersBIG (OrderDate, ExpectedDeliveryDate, BackorderOrderID)  
ORDER (OrderDate)
WITH (DROP_EXISTING = ON, MAXDOP = 1);

*/

SELECT FORMAT(COUNT(*), '#,#') FROM Sales.OrdersBIG;

---------------------------------------
-- Let's check indexes
---------------------------------------

SELECT  
    OBJECT_SCHEMA_NAME(i.object_id) AS SchemaName,
    OBJECT_NAME(i.object_id) AS TableName,
    i.name AS IndexName,
    i.index_id AS IndexID,
    i.type_desc AS IndexType,
    ic.index_column_id AS IndexColumnID,
    c.name AS ColumnName,
    ic.key_ordinal AS KeyOrdinal,
    ic.column_store_order_ordinal AS ColumnstoreOrderOrdinal
FROM sys.indexes AS i
INNER JOIN sys.index_columns AS ic
    ON i.object_id = ic.object_id
    AND i.index_id = ic.index_id
INNER JOIN sys.columns AS c
    ON ic.object_id = c.object_id
    AND ic.column_id = c.column_id
WHERE i.object_id = OBJECT_ID('Sales.OrdersBIG')
ORDER BY SchemaName, TableName, IndexID, IndexColumnID, ic.key_ordinal;

---------------------------------------
-- Query - without columnstore
---------------------------------------

SELECT 
  OrderDate, 
  COUNT(*) AS OrderCount, 
  AVG(DATEDIFF(HOUR, OrderDate, ExpectedDeliveryDate)) AS AvgOrderDeliveryTimeHours, 
  SUM(CASE WHEN BackorderOrderID IS NOT NULL THEN 1 ELSE 0 END) AS BackorderCount 
FROM Sales.OrdersBIG WITH (INDEX(1))
WHERE OrderDate >= '20130101' AND OrderDate < '20130201' 
GROUP BY OrderDate 
ORDER BY OrderDate;

----------------------------------------
-- Query - with nonclustered columnstore 
----------------------------------------

SELECT 
  OrderDate, 
  COUNT(*) AS OrderCount, 
  AVG(DATEDIFF(HOUR, OrderDate, ExpectedDeliveryDate)) AS AvgOrderDeliveryTimeHours, 
  SUM(CASE WHEN BackorderOrderID IS NOT NULL THEN 1 ELSE 0 END) AS BackorderCount 
FROM Sales.OrdersBIG WITH (INDEX(NCCI_SalesOrdersBIG))
WHERE OrderDate >= '20130101' AND OrderDate < '20130201' 
GROUP BY OrderDate 
ORDER BY OrderDate;

-----------------------------------------
-- Let's rebuild columnstore index ONLINE 
-----------------------------------------

CREATE NONCLUSTERED COLUMNSTORE INDEX NCCI_SalesOrdersBIG
ON Sales.OrdersBIG (OrderDate, ExpectedDeliveryDate, BackorderOrderID)  
ORDER (OrderDate)
WITH (DROP_EXISTING = ON, MAXDOP = 1, ONLINE = ON);

-- *** Run our query again to see if it's blocked ***