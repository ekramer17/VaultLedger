USE master

DECLARE @execSql nvarchar(1000)

SET NOCOUNT ON

-- Drop the database if it exists
IF EXISTS (SELECT 1 FROM master.dbo.sysdatabases WHERE name = '<databaseName>') BEGIN
   SELECT @execSql = 'DROP DATABASE <databaseName>'
   EXECUTE sp_executesql @execSql
END

-- Drop the logins if they have no default database
IF EXISTS
   (
   SELECT 1 
   FROM   master.dbo.sysxlogins x
   LEFT   JOIN sysdatabases d
     ON   d.dbid = x.dbid
   WHERE  x.name = '<operatorName>' AND d.dbid IS NULL
   ) 
BEGIN
   EXECUTE sp_droplogin @loginame = '<operatorName>'
END

IF EXISTS
   (
   SELECT 1 
   FROM   master.dbo.sysxlogins x
   LEFT   JOIN sysdatabases d
     ON   d.dbid = x.dbid
   WHERE  x.name = '<ownerName>' AND d.dbid IS NULL
   ) 
BEGIN
   EXECUTE sp_droplogin @loginame = '<ownerName>'
END

