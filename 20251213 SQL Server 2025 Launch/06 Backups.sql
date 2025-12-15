---------------------------------------
-- Real tough guys don't do backups!
---------------------------------------
PRINT '*** Just a backup ***';
BACKUP DATABASE [AdventureWorks2025] 
TO DISK = N'D:\Temp\AW-basic.bak';
GO

PRINT '*** Backup with compression ***';
BACKUP DATABASE [AdventureWorks2025] 
TO DISK = N'D:\Temp\AW-MS_EXPRESS.bak' 
WITH COMPRESSION;
GO

PRINT '*** Backup with ZSTD compression ***';
BACKUP DATABASE [AdventureWorks2025] 
TO DISK = N'D:\Temp\AW-ZSTD.bak' 
WITH COMPRESSION (ALGORITHM = ZSTD);
GO

PRINT '*** Backup with high level ZSTD compression ***';
BACKUP DATABASE [AdventureWorks2025] 
TO DISK = N'D:\Temp\AW-ZSTD_HIGH.bak' 
WITH COMPRESSION (ALGORITHM = ZSTD, LEVEL = HIGH);
GO

RESTORE HEADERONLY
FROM DISK = N'D:\Temp\WWI-ZSTD_HIGH.bak';
GO

---------------------------------------
-- New configuration option
---------------------------------------

SELECT * FROM sys.configurations WHERE name LIKE 'backup compression%';

EXECUTE sp_configure 'backup compression algorithm', 3;
RECONFIGURE;