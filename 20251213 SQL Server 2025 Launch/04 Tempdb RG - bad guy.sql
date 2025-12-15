----------------------------------------------
-- "No matter what always copy to temp table!"
----------------------------------------------

USE IDontKnowSQL;
SELECT * INTO #TempTable FROM BigTable;
GO