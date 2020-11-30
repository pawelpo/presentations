-- Execute in master
CREATE LOGIN Loader WITH PASSWORD = 'P@ssw0rd';

-- Execute in SQLPoolTPCH
CREATE USER Loader FROM LOGIN Loader;

-- GRANT CONTROL for CTAS
GRANT CONTROL ON DATABASE::SQLPool1 TO Loader;

-- Old-school workload management (resource classes)
SELECT name
FROM   sys.database_principals
WHERE  name LIKE '%rc%' AND type_desc = 'DATABASE_ROLE';
GO

EXEC sp_addrolemember 'largerc', 'Reader';
GO

-- Workload management
CREATE WORKLOAD GROUP wgELT
 WITH (   
     MIN_PERCENTAGE_RESOURCE = 20,
     CAP_PERCENTAGE_RESOURCE = 100, 
     REQUEST_MIN_RESOURCE_GRANT_PERCENT = 5,
     REQUEST_MAX_RESOURCE_GRANT_PERCENT = 20
 );

CREATE WORKLOAD CLASSIFIER wcELT  
WITH (   
    WORKLOAD_GROUP = 'wgELT',
    MEMBERNAME = 'Loader'
);

CREATE WORKLOAD CLASSIFIER wcDBO
WITH (   
    WORKLOAD_GROUP = 'wgELT',
    MEMBERNAME = 'dbo'
);

SELECT * FROM sys.workload_management_workload_groups;
SELECT * FROM sys.workload_management_workload_classifiers;
SELECT * FROM sys.workload_management_workload_classifier_details;