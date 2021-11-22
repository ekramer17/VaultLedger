-------------------------------------------------------------------------------
--
-- Grant access to the two users.  Add the sys user to the dbowner role; 
-- create a operations role and add the ops user to it.
--
-------------------------------------------------------------------------------
DECLARE @dbName nvarchar(128)
--DECLARE @roleName nvarchar(128)
--DECLARE @ownerUid nvarchar(128)
--DECLARE @ownerPwd nvarchar(128)
DECLARE @operatorUid nvarchar(128)
DECLARE @operatorPwd nvarchar(128)

SELECT @dbName = db_name()
--SELECT @roleName = '<roleName>'
--SELECT @ownerUid = '<ownerLogin>'
--SELECT @ownerPwd = '<ownerPassword>'
SELECT @operatorUid = '<operatorLogin>'
SELECT @operatorPwd = '<operatorPassword>'

-- Add the logins
IF NOT EXISTS(SELECT 1 FROM master.dbo.syslogins WHERE name = @operatorUid) BEGIN
   EXECUTE sp_addlogin @loginame = @operatorUid, @passwd = @operatorPwd, @defdb = @dbName
END

-- If the operator login already exists in the current database, drop it
IF EXISTS(SELECT 1 FROM sysusers WHERE name = @operatorUid) BEGIN
   IF EXISTS(SELECT 1 FROM master.dbo.syslogins WHERE name = @operatorUid) BEGIN
      EXECUTE sp_revokedbaccess @operatorUid
   END
END

-- Grant operator access to the database
EXECUTE sp_grantdbaccess @loginame = @operatorUid
EXECUTE sp_addrolemember @rolename = 'db_owner', @membername = @operatorUid

-- Change the default database
EXECUTE sp_defaultdb @operatorUid, @dbName

---- Add the operator role if it does not already exist
--IF NOT EXISTS(SELECT 1 FROM sysusers WHERE name = @roleName) BEGIN
--   EXECUTE sp_addrole @rolename = @roleName, @ownername = 'dbo'
--END
--
---- Add the operator to the role and change its default database
--EXECUTE sp_addrolemember @rolename = @roleName, @membername = @operatorUid
--EXECUTE sp_defaultdb @operatorUid, @dbName
--
---- If the owner login already exists in the current database, drop it
--IF EXISTS(SELECT 1 FROM sysusers WHERE name = @ownerUid) BEGIN
--   IF EXISTS(SELECT 1 FROM master.dbo.syslogins WHERE name = @ownerUid) BEGIN
--      EXECUTE sp_revokedbaccess @ownerUid
--   END
--END
--
---- Grant the owner login database access and add it to the db_owner role
--EXECUTE sp_grantdbaccess @loginame = @ownerUid
--EXECUTE sp_addrolemember @rolename = 'db_owner', @membername = @ownerUid
--
---- Change the owner's default database
--EXECUTE sp_defaultdb @ownerUid, @dbName
GO
