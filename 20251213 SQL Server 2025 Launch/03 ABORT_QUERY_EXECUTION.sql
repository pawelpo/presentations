---------------------------------------
-- Query store setup
---------------------------------------

USE [master];
GO
-- Enable the query store
ALTER DATABASE [AdventureWorks2025]
SET QUERY_STORE = ON;
GO
-- Clear the query store
ALTER DATABASE [AdventureWorks2025] 
SET QUERY_STORE CLEAR;
GO

---------------------------------------
-- Let's run some poor quality query
---------------------------------------

USE [AdventureWorks2025];
GO
WITH LargeDataSet AS (
    SELECT 
        p.ProductID, p.Name, p.ProductNumber, p.Color, 
        s.SalesOrderID, s.OrderQty, s.UnitPrice, s.LineTotal, 
        c.CustomerID, c.AccountNumber,
        (SELECT AVG(UnitPrice) FROM Sales.SalesOrderDetail WHERE ProductID = p.ProductID) AS AvgUnitPrice,
        (SELECT COUNT(*) FROM Sales.SalesOrderDetail WHERE ProductID = p.ProductID) AS OrderCount,
        (SELECT SUM(LineTotal) FROM Sales.SalesOrderDetail WHERE ProductID = p.ProductID) AS TotalSales,
        (SELECT MAX(OrderDate) FROM Sales.SalesOrderHeader WHERE CustomerID = c.CustomerID) AS LastOrderDate,
        r.ReviewCount
    FROM 
        Production.Product p
    JOIN 
        Sales.SalesOrderDetail s ON p.ProductID = s.ProductID
    JOIN 
        Sales.SalesOrderHeader h ON s.SalesOrderID = h.SalesOrderID
    JOIN 
        Sales.Customer c ON h.CustomerID = c.CustomerID
    JOIN 
        (SELECT 
             ProductID, COUNT(*) AS ReviewCount 
         FROM 
             Production.ProductReview 
         GROUP BY 
             ProductID) r ON p.ProductID = r.ProductID
     CROSS JOIN 
       (SELECT TOP 1000 * FROM Sales.SalesOrderDetail) s2
)
SELECT 
    ld.ProductID, ld.Name, ld.ProductNumber, ld.Color, 
    ld.SalesOrderID, ld.OrderQty, ld.UnitPrice, ld.LineTotal, 
    ld.CustomerID, ld.AccountNumber, ld.AvgUnitPrice, ld.OrderCount, ld.TotalSales, ld.LastOrderDate, ld.ReviewCount
FROM 
    LargeDataSet ld
ORDER BY 
    ld.OrderQty DESC, ld.ReviewCount ASC;
GO

---------------------------------------
-- Queries with top duration
---------------------------------------

USE [AdventureWorks2025];
GO
SELECT 
    qsqt.query_sql_text,
    qsp.plan_id,
    qsp.query_id,
    rs.avg_duration,
    rs.count_executions
FROM 
    sys.query_store_query_text AS qsqt
JOIN 
    sys.query_store_query AS qsq
    ON qsqt.query_text_id = qsq.query_text_id
JOIN 
    sys.query_store_plan AS qsp
    ON qsq.query_id = qsp.query_id
JOIN 
    sys.query_store_runtime_stats AS rs
    ON qsp.plan_id = rs.plan_id
GROUP BY qsqt.query_sql_text, qsp.plan_id, qsp.query_id, rs.avg_duration, rs.count_executions
ORDER BY 
    rs.avg_duration DESC;
GO

---------------------------------------
-- Let's ban this query!
---------------------------------------

USE [AdventureWorks2025];
GO
EXEC sys.sp_query_store_set_hints
 @query_id = 1,
 @query_hints = N'OPTION (USE HINT (''ABORT_QUERY_EXECUTION''))';
GO

---------------------------------------
-- Poor quality query again... Oops!
---------------------------------------

USE [AdventureWorks2025];
GO
WITH LargeDataSet AS (
    SELECT 
        p.ProductID, p.Name, p.ProductNumber, p.Color, 
        s.SalesOrderID, s.OrderQty, s.UnitPrice, s.LineTotal, 
        c.CustomerID, c.AccountNumber,
        (SELECT AVG(UnitPrice) FROM Sales.SalesOrderDetail WHERE ProductID = p.ProductID) AS AvgUnitPrice,
        (SELECT COUNT(*) FROM Sales.SalesOrderDetail WHERE ProductID = p.ProductID) AS OrderCount,
        (SELECT SUM(LineTotal) FROM Sales.SalesOrderDetail WHERE ProductID = p.ProductID) AS TotalSales,
        (SELECT MAX(OrderDate) FROM Sales.SalesOrderHeader WHERE CustomerID = c.CustomerID) AS LastOrderDate,
        r.ReviewCount
    FROM 
        Production.Product p
    JOIN 
        Sales.SalesOrderDetail s ON p.ProductID = s.ProductID
    JOIN 
        Sales.SalesOrderHeader h ON s.SalesOrderID = h.SalesOrderID
    JOIN 
        Sales.Customer c ON h.CustomerID = c.CustomerID
    JOIN 
        (SELECT 
             ProductID, COUNT(*) AS ReviewCount 
         FROM 
             Production.ProductReview 
         GROUP BY 
             ProductID) r ON p.ProductID = r.ProductID
     CROSS JOIN 
       (SELECT TOP 1000 * FROM Sales.SalesOrderDetail) s2
)
SELECT 
    ld.ProductID, ld.Name, ld.ProductNumber, ld.Color, 
    ld.SalesOrderID, ld.OrderQty, ld.UnitPrice, ld.LineTotal, 
    ld.CustomerID, ld.AccountNumber, ld.AvgUnitPrice, ld.OrderCount, ld.TotalSales, ld.LastOrderDate, ld.ReviewCount
FROM 
    LargeDataSet ld
ORDER BY 
    ld.OrderQty DESC, ld.ReviewCount ASC;
GO

---------------------------------------
-- Allow the query to run again
---------------------------------------

USE [AdventureWorks2025];
GO
EXEC sys.sp_query_store_clear_hints @query_id = 1;
GO