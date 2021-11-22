SET NOCOUNT ON

-- Should we run this script?
IF dbo.bit$doScript('1.3.1') = 1 BEGIN

BEGIN TRANSACTION
-------------------------------------------------------------------------------
--
-- Add medium id column to the disaster code list item table
--
-------------------------------------------------------------------------------
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'DisasterCodeListItem' AND COLUMN_NAME = 'MediumId') BEGIN
   CREATE TABLE dbo.DisasterCodeListItemTemp
   (
   -- Attributes
      ItemId      int             NOT NULL  CONSTRAINT pkDisasterCodeListItemTemp PRIMARY KEY CLUSTERED IDENTITY(1,1),
      Status      int             NOT NULL,
      Code        nvarchar(32)    NOT NULL,
      Notes       nvarchar(1000)  NOT NULL,
   -- Relationships
      ListId      int             NOT NULL,
      MediumId    int             NOT NULL
   )

   -- Insert the medium records as is  
   SET IDENTITY_INSERT DisasterCodeListItemTemp ON
   EXECUTE
   (
   '
   INSERT DisasterCodeListItemTemp (ItemId, Status, Code, Notes, ListId, MediumId)
   SELECT d.ItemId, d.Status, d.Code, d.Notes, d.ListId, m.MediumId
   FROM   DisasterCodeListItem d
   JOIN   DisasterCodeListItemMedium m
   ON   d.ItemId = m.ItemId
   ORDER  BY d.ItemId ASC
   '
   )
   SET IDENTITY_INSERT DisasterCodeListItemTemp OFF

   -- Reseed the temp table
   DBCC CHECKIDENT ('DisasterCodeListItemTemp', 'RESEED')

   -- Insert the media from case records with new itemid values
   EXECUTE
   (
   '
   INSERT DisasterCodeListItemTemp (Status, Code, Notes, ListId, MediumId)
   SELECT d.Status, d.Code, d.Notes, d.ListId, m.MediumId
   FROM   DisasterCodeListItem d
   JOIN   DisasterCodeListItemCase c
     ON   d.ItemId = c.ItemId
   JOIN   SealedCase s
     ON   s.CaseId = c.CaseId
   JOIN   MediumSealedCase m
     ON   m.CaseId = c.CaseId
   ORDER  BY d.ItemId ASC
   '
   )

   -- Drop tables
   EXECUTE ('DROP TABLE DisasterCodeListItemMedium')
   EXECUTE ('DROP TABLE DisasterCodeListItemCase')
   EXECUTE ('DROP TABLE DisasterCodeListItem')

   -- Add table back with medium column
   CREATE TABLE dbo.DisasterCodeListItem
   (
   -- Attributes
      ItemId      int             NOT NULL  CONSTRAINT pkDisasterCodeListItem PRIMARY KEY CLUSTERED  IDENTITY(1,1),
      Status      int             NOT NULL  CONSTRAINT defDisasterCodeListItem$Status DEFAULT 2, -- power(4,x)
      Code        nvarchar(32)    NOT NULL,
      Notes       nvarchar(1000)  NOT NULL  CONSTRAINT defDisasterCodeListItem$Notes DEFAULT '', 
   -- Relationships
      ListId      int             NOT NULL,
      MediumId    int             NOT NULL,
   -- Concurrency
      RowVersion  rowversion      NOT NULL
   )
   
   -- Constraints
   ALTER TABLE DisasterCodeListItem
      ADD CONSTRAINT chkDisasterCodeListItem$Code
         CHECK (dbo.bit$IsEmptyString(Code) = 1 OR dbo.bit$LegalCharacters(Code, 'ALPHANUMERIC', NULL ) = 1)
   
   ALTER TABLE DisasterCodeListItem
      ADD CONSTRAINT chkDisasterCodeListItem$Status 
         CHECK (Status IN (1, 2, 4, 512)) -- power(4,x)
   
   ALTER TABLE dbo.DisasterCodeListItem
      ADD CONSTRAINT fkDisasterCodeListItem$DisasterCodeList
         FOREIGN KEY (ListId) REFERENCES dbo.DisasterCodeList
            ON DELETE CASCADE

   ALTER TABLE dbo.DisasterCodeListItem
      ADD CONSTRAINT fkDisasterCodeListItem$Medium
         FOREIGN KEY (MediumId) REFERENCES dbo.Medium
            ON DELETE CASCADE

   -- Add the data back
   SET IDENTITY_INSERT DisasterCodeListItem ON
   EXECUTE
   (
   '
   INSERT DisasterCodeListItem (ItemId, Status, Code, Notes, ListId, MediumId)
   SELECT ItemId, Status, Code, Notes, ListId, MediumId
   FROM   DisasterCodeListItemTemp
   ORDER  BY ItemId ASC
   '
   )
   SET IDENTITY_INSERT DisasterCodeListItem OFF

   -- Drop the temp table
   EXECUTE ('DROP TABLE DisasterCodeListItemTemp')
   IF @@error != 0 GOTO COMMIT_IT

   -- Reseed the new table
   DBCC CHECKIDENT ('DisasterCodeListItem', 'RESEED')
   IF @@error != 0 GOTO COMMIT_IT

   -- Place all disaster code case media in disaster code medium table
   EXECUTE
   (
   '
   EXECUTE spidlogin$ins ''System'', ''disaster code medium''
   INSERT DisasterCodeMedium (CodeId, MediumId)
   SELECT c.CodeId, m.MediumId
   FROM   DisasterCodeCase c
   JOIN   MediumSealedCase m
     ON   m.CaseId = c.CaseId
   EXECUTE spidlogin$del 1
   '
   )

   -- Drop the disaster code case table
   EXECUTE ('DROP TABLE DisasterCodeCase')
   IF @@error != 0 GOTO COMMIT_IT
END

-------------------------------------------------------------------------------
--
-- Version update
--
-------------------------------------------------------------------------------
IF NOT EXISTS(SELECT 1 FROM DatabaseVersion WHERE Major = 1 AND Minor = 3 AND Revision = 1) BEGIN
   DECLARE @x nvarchar(1000)
   EXECUTE spidLogin$ins 'System', 'Insert database version'
   INSERT DatabaseVersion (Major, Minor, Revision) VALUES (1, 3, 1)
   EXECUTE spidLogin$del
END

GOTO COMMIT_IT

ROLL_IT:
ROLLBACK TRANSACTION

COMMIT_IT:
COMMIT TRANSACTION

END -- End should we run this script
GO

-------------------------------------------------------------------------------
--
-- Permissions
--
-------------------------------------------------------------------------------
DECLARE @objectName nvarchar(1000)
DECLARE @objectType tinyint
DECLARE @tblLogin table (RowNo int identity(1,1), Login nvarchar(32))
DECLARE @tblObject table (RowNo int identity(1,1), ObjectName nvarchar(1000), ObjectType tinyint) -- 1: table, 2: routine, 3: table-valued function
DECLARE @s1 nvarchar(128)
DECLARE @s2 nvarchar(128)
DECLARE @x  int
DECLARE @y  int

SET NOCOUNT ON

-- Initialize
SET @x = 1

-- Populate login table
INSERT @tblLogin (Login)
SELECT Name
FROM   sysusers
WHERE  Name IN ('BLOperator', 'BLRole', 'RMMOperator', 'RMMRole')

-- Populate the object table
INSERT @tblObject (ObjectName, ObjectType)
SELECT TABLE_NAME, 1
FROM   INFORMATION_SCHEMA.TABLES
WHERE  objectproperty(object_id(TABLE_NAME),'IsMSShipped') = 0
UNION
SELECT ROUTINE_NAME, case objectproperty(object_id(ROUTINE_NAME),'IsTableFunction') when 0 then 2 else 3 end
FROM   INFORMATION_SCHEMA.ROUTINES
WHERE  objectproperty(object_id(ROUTINE_NAME),'IsMSShipped') = 0

-- Loop through objects
WHILE 1 = 1 BEGIN
   SELECT @objectName = ObjectName, 
          @objectType = ObjectType, 
          @y = 1
   FROM   @tblObject
   WHERE  RowNo = @x
   -- Anything?
   IF @@rowcount = 0 BREAK
   -- Loop through logins
   WHILE 1 = 1 BEGIN
      SELECT @s1 = case u.issqlrole when 1 then 'GRANT' else 'REVOKE' end,
             @s2 = @objectName + case u.issqlrole when 1 then ' TO ' else ' FROM ' end + l.Login
      FROM   @tblLogin l
      JOIN   sysusers u
        ON   u.name = l.Login
      WHERE  l.RowNo = @y
      -- Anything?
      IF @@rowcount = 0 BREAK
      -- Revoke from Public role
      IF @objectType = 1 BEGIN
         -- Revoke from public
         EXEC ('REVOKE SELECT ON ' + @objectName + ' FROM PUBLIC')
         EXEC ('REVOKE INSERT ON ' + @objectName + ' FROM PUBLIC')
         EXEC ('REVOKE UPDATE ON ' + @objectName + ' FROM PUBLIC')
         EXEC ('REVOKE DELETE ON ' + @objectName + ' FROM PUBLIC')
         -- Grant to role, revoke from user
         EXEC (@s1 + ' SELECT ON ' + @s2)
         EXEC (@s1 + ' INSERT ON ' + @s2)
         EXEC (@s1 + ' UPDATE ON ' + @s2)
         EXEC (@s1 + ' DELETE ON ' + @s2)
      END
      ELSE IF @objectType = 2 BEGIN
         EXEC ('REVOKE EXECUTE ON ' + @objectName + ' FROM PUBLIC')
         EXEC (@s1 + ' EXECUTE ON ' + @s2)
      END
      ELSE IF @objectType = 3 BEGIN
         -- Revoke from public, user, grant to role
         EXEC ('REVOKE SELECT ON ' + @objectName + ' FROM PUBLIC')
         EXEC (@s1 + ' SELECT ON ' + @s2)
      END
      -- Increment
      SET @y = @y + 1
   END
   -- Increment row
   SET @x = @x + 1
END
GO
