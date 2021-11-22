USE master

DECLARE @dbName nvarchar(128)
DECLARE @execSql nvarchar(1000)
DECLARE @fileName1 nvarchar(512)
DECLARE @fileName2 nvarchar(512)
DECLARE @dataPath nvarchar(512)
DECLARE @error int
DECLARE @i int

SET NOCOUNT ON

-- Initialize
SELECT @dbName = 'vaultledger'
SELECT @fileName1 = ''
SELECT @fileName2 = ''
SELECT @i = 1

-- Get the data file path
SELECT TOP 1 @dataPath = left(FileName, len(FileName) - charindex('\',reverse(rtrim(FileName))) + 1) 
FROM   master.dbo.sysfiles

-- Create the database if it does not exist
IF NOT EXISTS (SELECT 1 FROM master.dbo.sysdatabases WHERE name = @dbName) BEGIN
   WHILE 1 = 1 BEGIN
      -- Name the data and log files
      SELECT @fileName1 = @dataPath + @dbName + cast(@i as varchar(2)) + '.mdf'
      SELECT @fileName2 = @dataPath + @dbName + cast(@i as varchar(2)) +  '_log.ldf'
      -- Create database
      SELECT @execSql = 'CREATE DATABASE ' + @dbName + ' ON (NAME = ' + @dbName + ', FILENAME = ''' + @fileName1 + ''') LOG ON (NAME = ' + @dbName + '_log, FILENAME = ''' + @fileName2 + ''')'
      EXECUTE sp_executesql @execSql
      SELECT @error = @@error
      -- If we could not create the database because we could not create the files,
      -- they may already exist.  Attempt to attach the database.
      IF @error = 5170 OR @error = 1802 BEGIN
         EXECUTE sp_attach_db @dbName = @dbName, @fileName1 = @fileName1, @fileName2 = @fileName2
         SELECT @error = @@error
         -- Make sure its a valid VaultLedger database.  If it isn't, detach it and set 
         -- the error to a nonzero value so that we don't attempt to alter the files.
         IF @error = 0 BEGIN
            CREATE TABLE #tblValid (ValidDb int)
            SELECT @execSql = 'INSERT #tblValid SELECT count(*) FROM ' + @dbName + '.information_schema.tables where table_name = ''xmediummovement'''
            EXECUTE sp_executesql @execSql
            IF NOT EXISTS (SELECT 1 FROM #tblValid WHERE ValidDb != 0) BEGIN
               EXECUTE sp_detach_db @dbName
               SELECT @error = -100
            END
            DROP TABLE #tblValid
         END
      END
      -- Alter the database and its files if we haven't encountered any error
      -- during the creation/attachment.
      IF @error = 0 BEGIN
         -- Set it to have recursive triggers
         SELECT @execSql = 'ALTER DATABASE ' + @dbName + ' SET RECURSIVE_TRIGGERS ON'
         EXECUTE sp_executesql @execSql
         -- Alter the database files
         CREATE TABLE #vlFiles (FileName nvarchar(512))
         SELECT @execSql = 'INSERT #vlFiles (FileName) SELECT name FROM ' + @dbName + '.dbo.sysfiles'
         EXECUTE sp_executesql @execSql
         WHILE 1 = 1 BEGIN
            SELECT TOP 1 @fileName1 = FileName
            FROM   #vlFiles
            WHERE  FileName > @fileName1
            ORDER  BY FileName Asc
            IF @@rowcount = 0
               BREAK
            ELSE BEGIN
               SELECT @execSql = 'ALTER DATABASE ' + @dbName + ' MODIFY FILE (NAME = ' + @fileName1 + ', MAXSIZE = UNLIMITED)'
               EXECUTE sp_executesql @execSql
               SELECT @execSql = 'ALTER DATABASE ' + @dbName + ' MODIFY FILE (NAME = ' + @fileName1 + ', FILEGROWTH = 10MB)'
               EXECUTE sp_executesql @execSql
            END
         END
         DROP TABLE #vlFiles
         BREAK
      END
      -- Increment counter, max out at 99 attempts
      SELECT @i = @i + 1
      IF @i = 100 BREAK
   END
END

-- Regular expressions stored procedure
IF EXISTS (SELECT 1 WHERE charindex('2000', left(@@version, charindex('-', @@version))) != 0) BEGIN
   IF NOT EXISTS (SELECT 1 FROM master.dbo.sysobjects WHERE name = 'xp_pcre_match' and objectproperty(id, 'IsExtendedProc') = 1) BEGIN
      EXECUTE sp_addextendedproc xp_pcre_match, 'xp_pcre.dll'
   END
   -- Make sure we grant permission to public on xp_pcre_match
   GRANT EXECUTE ON xp_pcre_match TO Public
END
ELSE BEGIN
   EXEC
   (
   '
   USE ' + @dbName + ';
   EXECUTE sp_configure ''clr enable'', 1;
   RECONFIGURE WITH OVERRIDE;
   IF NOT EXISTS (SELECT 1 FROM sys.assemblies WHERE Name = ''Bandl.VaultLedger'') BEGIN
      DECLARE @x1 nvarchar(4000)
      DECLARE @s1 nvarchar(4000)
      SELECT  @s1 = coalesce(''MSSQL$'' + convert(nvarchar(4000), SERVERPROPERTY(''InstanceName'')), ''MSSQLSERVER'')
      SELECT  @s1 = ''SYSTEM\CurrentControlSet\Services\'' + @s1
      EXECUTE master..xp_instance_regread ''HKEY_LOCAL_MACHINE'', @s1, ''ImagePath'', @x1 output
      SELECT  @x1 = SUBSTRING(REVERSE(SUBSTRING(REVERSE(@x1), CHARINDEX(''\'', REVERSE(@x1)), 4000)), CHARINDEX('':'', @x1) - 1, 4000) + ''Bandl.VaultLedger.Sql.dll''
      EXECUTE (''CREATE ASSEMBLY [Bandl.VaultLedger] FROM '''''' + @x1 + '''''' WITH PERMISSION_SET = SAFE'')
   END
   '
   )
END
GO
