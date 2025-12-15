---------------------------------------
-- Reset tempdb
---------------------------------------

USE master;
GO

-- Alter tempdb data files to set size to 64MB for total of 512MB
ALTER DATABASE tempdb 
MODIFY FILE (NAME = tempdev, SIZE = 8MB);
GO

ALTER DATABASE tempdb 
MODIFY FILE (NAME = temp2, SIZE = 8MB);
GO

ALTER DATABASE tempdb 
MODIFY FILE (NAME = temp3, SIZE = 8MB);
GO

ALTER DATABASE tempdb 
MODIFY FILE (NAME = temp4, SIZE = 8MB);
GO

ALTER DATABASE tempdb 
MODIFY FILE (NAME = temp5, SIZE = 8MB);
GO

ALTER DATABASE tempdb 
MODIFY FILE (NAME = temp6, SIZE = 8MB);
GO

ALTER DATABASE tempdb 
MODIFY FILE (NAME = temp7, SIZE = 8MB);
GO

ALTER DATABASE tempdb 
MODIFY FILE (NAME = temp8, SIZE = 8MB);
GO

-- Alter tempdb log file to set size to 100MB
ALTER DATABASE tempdb 
MODIFY FILE (NAME = templog, SIZE = 8MB);
GO

DBCC SHRINKDATABASE(tempdb);
GO

---------------------------------------
-- Let's check tempdb size
---------------------------------------

USE [tempdb];
GO

-- Query to track space usage for tempdb
SELECT 
    name AS FileName,
    size / 128.0 AS CurrentSizeMB,
    size / 128.0 - CAST(FILEPROPERTY(name, 'SpaceUsed') AS INT) / 128.0 AS FreeSpaceMB,
    CAST(FILEPROPERTY(name, 'SpaceUsed') AS INT) / 128.0 AS UsedSpaceMB,
    physical_name AS PhysicalFileName
FROM 
    sys.database_files;
GO

EXEC IDontKnowSQL.sys.sp_spaceused 'dbo.BigTable';
GO

-- *** Run BudGuy's query here ***

---------------------------------------
-- Let's check tempdb usage by session
---------------------------------------

SELECT 
    ssu.session_id,
    es.program_name AS appname,
    ssu.user_objects_alloc_page_count * 8 AS user_objects_alloc_kb,
    ssu.internal_objects_alloc_page_count * 8 AS internal_objects_alloc_kb
FROM 
    sys.dm_db_session_space_usage AS ssu
JOIN 
    sys.dm_exec_sessions AS es ON ssu.session_id = es.session_id
WHERE 
    (ssu.user_objects_alloc_page_count > 0 OR ssu.internal_objects_alloc_page_count > 0);
GO

---------------------------------------
-- Let's set up RG for tempdb
---------------------------------------

ALTER RESOURCE GOVERNOR RECONFIGURE;
GO

CREATE WORKLOAD GROUP GroupForUsersWhoDontKnowSQL
WITH (GROUP_MAX_TEMPDB_DATA_MB = 50);
GO

ALTER RESOURCE GOVERNOR RECONFIGURE;
GO

USE [master];
GO

CREATE FUNCTION dbo.RGClassifier()
RETURNS SYSNAME
WITH SCHEMABINDING
AS
BEGIN
    DECLARE @WorkloadGroup SYSNAME;

    IF SUSER_SNAME() = 'BadGuy'
    BEGIN
        SET @WorkloadGroup = 'GroupForUsersWhoDontKnowSQL'; 
    END
    ELSE
    BEGIN
        SET @WorkloadGroup = 'default';
    END

    RETURN @WorkloadGroup;
END;
GO

ALTER RESOURCE GOVERNOR WITH (CLASSIFIER_FUNCTION = dbo.RGClassifier);
GO

ALTER RESOURCE GOVERNOR RECONFIGURE;
GO

-- *** Re-connect and run BudGuy's query here ***

---------------------------------------
-- Check for RG rules violation
---------------------------------------

SELECT name,
       tempdb_data_space_kb, 
       peak_tempdb_data_space_kb, 
       total_tempdb_data_limit_violation_count
FROM sys.dm_resource_governor_workload_groups
GO

---------------------------------------
-- Cleanup
---------------------------------------

USE [master];
GO
ALTER RESOURCE GOVERNOR WITH (CLASSIFIER_FUNCTION = NULL);
GO
ALTER RESOURCE GOVERNOR RECONFIGURE;
GO
DROP WORKLOAD GROUP GroupforUsersWhoDontKnowSQL;
GO
DROP FUNCTION dbo.RGClassifier;
GO
ALTER RESOURCE GOVERNOR RECONFIGURE;
GO

