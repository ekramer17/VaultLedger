SET NOCOUNT ON

DECLARE @C1 nvarchar(10)

IF EXISTS(SELECT 1 FROM INFORMATION_SCHEMA.ROUTINES WHERE SPECIFIC_NAME = 'bit$doScript')
   SET @C1 = 'ALTER '
ELSE
   SET @C1 = 'CREATE '

EXECUTE
(  
   @C1 + 'FUNCTION dbo.bit$doScript
   ( 
    	@thisVersion nvarchar(32)
   )
   RETURNS bit
   WITH ENCRYPTION
   AS
   BEGIN
   DECLARE @returnValue bit
   SET @returnValue = 1
   IF EXISTS
      (
      SELECT 1
      FROM   DatabaseVersion
      WHERE  @thisVersion < cast(Major as nvarchar(10)) + ''.'' + cast(Minor as nvarchar(10)) + ''.'' + cast(Revision as nvarchar(10))
      )
   BEGIN
      SET @returnValue = 0
   END
   -- Return
   RETURN @returnValue
   END
   '
)
GO

-- Should we run this script?
IF dbo.bit$doScript('1.3.0') = 1 BEGIN

BEGIN TRANSACTION
-------------------------------------------------------------------------------
--
-- Add inventory table
--
-------------------------------------------------------------------------------
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'Inventory') BEGIN
CREATE TABLE dbo.Inventory
(
-- Attributes
   InventoryId   int         NOT NULL  CONSTRAINT pkInventory PRIMARY KEY CLUSTERED  IDENTITY(1,1),
   Location      bit         NOT NULL,
   FileHash      binary(32)  NOT NULL,
   DownloadTime  datetime    NOT NULL,
-- Relationships
   AccountId     int         NOT NULL
)

-- Foreign key constraint for account
ALTER TABLE dbo.Inventory
   ADD CONSTRAINT fkInventory$Account
      FOREIGN KEY (AccountId) REFERENCES dbo.Account
         ON DELETE CASCADE

-- Move rows from vault inventory table to inventory table
SET IDENTITY_INSERT Inventory ON
INSERT Inventory (InventoryId, Location, FileHash, DownloadTime, AccountId)
SELECT InventoryId, 0, FileHash, DownloadTime, AccountId
FROM   VaultInventory
ORDER  BY InventoryId ASC
-- Error evaluation
IF @@error != 0 GOTO ROLL_IT
-- Restore identity
SET IDENTITY_INSERT Inventory OFF
DBCC CHECKIDENT ('Inventory', 'RESEED')


-------------------------------------------------------------------------------
--
-- Add inventory item table
--
-------------------------------------------------------------------------------
CREATE TABLE dbo.InventoryItem
(
-- Attributes
   ItemId        int           NOT NULL  CONSTRAINT pkInventoryItem PRIMARY KEY CLUSTERED IDENTITY(1,1),
   SerialNo      nvarchar(32)  NOT NULL,
-- Relationships
   InventoryId   int           NOT NULL
)

-- -- Add index on the serial number / inventory combination
-- CREATE UNIQUE NONCLUSTERED INDEX akInventoryItem$SerialInventory ON InventoryItem (InventoryId, SerialNo)

-- Foreign key constraint
ALTER TABLE dbo.InventoryItem
   ADD CONSTRAINT fkInventoryItem$Inventory
      FOREIGN KEY (InventoryId) REFERENCES dbo.Inventory
         ON DELETE CASCADE

-- Check constraint
ALTER TABLE dbo.InventoryItem
   ADD CONSTRAINT chkInventoryItem$SerialNo
      CHECK (dbo.bit$IsEmptyString(SerialNo) = 0 and dbo.bit$IllegalCharacters(SerialNo, '_&?%*') = 0)

-- Move rows from vault inventory item table
EXECUTE 
(
'
SET IDENTITY_INSERT InventoryItem ON
INSERT InventoryItem (ItemId, SerialNo, InventoryId)
SELECT ItemId, SerialNo, InventoryId
FROM   VaultInventoryItem
ORDER  BY ItemId ASC
SET IDENTITY_INSERT InventoryItem OFF
'
)

-- Error evaluation
IF @@error != 0 GOTO ROLL_IT

CREATE TABLE dbo.VaultInventoryItemTemp
(
   ItemId       int             NOT NULL  CONSTRAINT pkVaultInventoryItemTemp PRIMARY KEY CLUSTERED,
   TypeId       int             NOT NULL,
   ReturnDate   nvarchar(10)    NOT NULL  CONSTRAINT defVaultInventoryItemTemp$ReturnDate DEFAULT '',
   HotStatus    bit             NOT NULL  CONSTRAINT defVaultInventoryItemTemp$HotStatus DEFAULT 0,
   Notes        nvarchar(1000)  NOT NULL  CONSTRAINT defVaultInventoryItemTemp$Notes DEFAULT ''
)

INSERT VaultInventoryItemTemp (ItemId, TypeId, ReturnDate, HotStatus, Notes)
SELECT ItemId, TypeId, ReturnDate, HotStatus, ''
FROM   VaultInventoryItem
ORDER  BY ItemId ASC

-- Error evaluation
IF @@error != 0 GOTO ROLL_IT

-- Drop the old table
DROP TABLE VaultInventoryItem

-- Error evaluation
IF @@error != 0 GOTO ROLL_IT

-- Rename the new
EXECUTE sp_rename 'VaultInventoryItemTemp', 'VaultInventoryItem'
EXECUTE sp_rename 'pkVaultInventoryItemTemp', 'pkVaultInventoryItem'
EXECUTE sp_rename 'defVaultInventoryItemTemp$Notes', 'defVaultInventoryItem$Notes'
EXECUTE sp_rename 'defVaultInventoryItemTemp$HotStatus', 'defVaultInventoryItem$HotStatus'
EXECUTE sp_rename 'defVaultInventoryItemTemp$ReturnDate', 'defVaultInventoryItem$ReturnDate'

ALTER TABLE VaultInventoryItem 
   ADD CONSTRAINT chkVaultInventoryItem$ReturnDate CHECK 
      (dbo.bit$IsEmptyString(ReturnDate) = 1 or isdate(ReturnDate) = 1)

-- Add foreign key constraint
ALTER TABLE dbo.VaultInventoryItem
   ADD CONSTRAINT fkVaultInventoryItem$InventoryItem
      FOREIGN KEY (ItemId) REFERENCES dbo.InventoryItem
         ON DELETE CASCADE

-------------------------------------------------------------------------------
--
-- Add inventory audit table
--
-------------------------------------------------------------------------------
CREATE TABLE dbo.XInventory
(
-- Attributes
   ItemId   int             NOT NULL  CONSTRAINT pkXInventory         PRIMARY KEY CLUSTERED  IDENTITY(1,1),
   Date     datetime        NOT NULL  CONSTRAINT defXInventory$Date   DEFAULT GETDATE(),
   Object   nvarchar(256)   NOT NULL,
   Action   int             NOT NULL,
   Detail   nvarchar(3000)  NOT NULL  CONSTRAINT defXInventory$Detail DEFAULT '',
   Login    nvarchar(32)    NOT NULL  CONSTRAINT defXInventory$Login  DEFAULT 'SYSTEM'
)

-- Move rows from XVaultInventory
SET IDENTITY_INSERT XInventory ON
INSERT XInventory (ItemId, Date, Object, Action, Detail, Login)
SELECT ItemId, Date, Object, Action, Detail, Login
FROM   XVaultInventory
ORDER  BY ItemId ASC
-- Error evaluation
IF @@error != 0 GOTO ROLL_IT
-- Restore identity
SET IDENTITY_INSERT XInventory OFF
DBCC CHECKIDENT ('XInventory', 'RESEED')

CREATE TABLE dbo.XInventoryConflict
(
-- Attributes
   ItemId   int             NOT NULL  CONSTRAINT pkXInventoryConflict         PRIMARY KEY CLUSTERED  IDENTITY(1,1),
   Date     datetime        NOT NULL  CONSTRAINT defXInventoryConflict$Date   DEFAULT GETDATE(),
   Object   nvarchar(256)   NOT NULL,
   Action   int             NOT NULL,
   Detail   nvarchar(3000)  NOT NULL  CONSTRAINT defXInventoryConflict$Detail DEFAULT '',
   Login    nvarchar(32)    NOT NULL  CONSTRAINT defXInventoryConflict$Login  DEFAULT 'SYSTEM'
)

-- Move rows from XVaultInventory
SET IDENTITY_INSERT XInventoryConflict ON
INSERT XInventoryConflict (ItemId, Date, Object, Action, Detail, Login)
SELECT ItemId, Date, Object, Action, Detail, Login
FROM   XVaultDiscrepancy
ORDER  BY ItemId ASC
-- Error evaluation
IF @@error != 0 GOTO ROLL_IT
-- Restore identity
SET IDENTITY_INSERT XInventoryConflict OFF
DBCC CHECKIDENT ('XInventoryConflict', 'RESEED')

-------------------------------------------------------------------------------
--
-- Add inventory conflict tables
--
-------------------------------------------------------------------------------
CREATE TABLE dbo.InventoryConflict
(
-- Attributes
   Id            int          NOT NULL  CONSTRAINT pkInventoryConflict PRIMARY KEY CLUSTERED  IDENTITY(1,1),
   SerialNo      nvarchar(32) NOT NULL,
   RecordedDate  datetime     NOT NULL
)

-- Move discrepancies
SET IDENTITY_INSERT InventoryConflict ON
INSERT InventoryConflict (Id, SerialNo, RecordedDate)
SELECT d.ItemId, x.SerialNo, d.RecordedDate
FROM   VaultDiscrepancy d
JOIN  (SELECT ItemId, SerialNo
       FROM   VaultDiscrepancyAccount
       UNION
       SELECT ItemId, SerialNo
       FROM   VaultDiscrepancyCaseType
       UNION
       SELECT ItemId, SerialNo
       FROM   VaultDiscrepancyMediumType
       UNION
       SELECT ItemId, SerialNo
       FROM   VaultDiscrepancyResidency
       UNION
       SELECT ItemId, SerialNo
       FROM   VaultDiscrepancyUnknownCase) as x
  ON   x.ItemId = d.ItemId
ORDER  BY d.ItemId ASC
-- Error evaluation
IF @@error != 0 GOTO ROLL_IT
-- Restore identity
SET IDENTITY_INSERT InventoryConflict OFF

--------------------------
-- Account discrepancies
--------------------------
CREATE TABLE dbo.InventoryConflictAccount
(
-- Attributes
   Id         int      NOT NULL  CONSTRAINT pkInventoryConflictAccount PRIMARY KEY CLUSTERED,
   Type       tinyint  NOT NULL, -- 0 if vault inventory asserts account, 1 if enterprise inventory asserts account
   AccountId  int      NOT NULL
)

-- Add foreign key constraints
ALTER TABLE dbo.InventoryConflictAccount
   ADD CONSTRAINT fkInventoryConflictAccount$InventoryConflict
      FOREIGN KEY (Id) REFERENCES dbo.InventoryConflict
         ON DELETE CASCADE

ALTER TABLE dbo.InventoryConflictAccount
   ADD CONSTRAINT fkInventoryConflictAccount$Account
      FOREIGN KEY (AccountId) REFERENCES dbo.Account
         ON DELETE CASCADE

-- Move data
EXECUTE
(
'
INSERT InventoryConflictAccount (Id, Type, AccountId)
SELECT ItemId, 0, VaultAccount
FROM   VaultDiscrepancyAccount
ORDER  BY ItemId ASC
'
)

-- Error evaluation
IF @@error != 0 GOTO ROLL_IT

-------------------------------------------
-- Type discrepancies (vault only)
-------------------------------------------
CREATE TABLE dbo.InventoryConflictObjectType
(
-- Attributes
   Id      int  NOT NULL  CONSTRAINT pkInventoryConflictObjectType PRIMARY KEY CLUSTERED,
   TypeId  int  NOT NULL  -- Type asserted by inventory
)

-- Add foreign key constraints
ALTER TABLE dbo.InventoryConflictObjectType
   ADD CONSTRAINT fkInventoryConflictObjectType$InventoryConflict
      FOREIGN KEY (Id) REFERENCES dbo.InventoryConflict
         ON DELETE CASCADE

ALTER TABLE dbo.InventoryConflictObjectType
   ADD CONSTRAINT fkInventoryConflictObjectType$Type
      FOREIGN KEY (TypeId) REFERENCES dbo.MediumType
         ON DELETE CASCADE

-- Move data
EXECUTE
(
'
INSERT InventoryConflictObjectType (Id, TypeId)
SELECT ItemId, VaultType
FROM   VaultDiscrepancyCaseType
UNION
SELECT ItemId, VaultType
FROM   VaultDiscrepancyMediumType
ORDER  BY ItemId ASC
'
)

-- Error evaluation
IF @@error != 0 GOTO ROLL_IT

-------------------------------------------
-- Location discrepancies
-------------------------------------------
CREATE TABLE dbo.InventoryConflictLocation
(
-- Attributes
   Id    int      NOT NULL  CONSTRAINT pkInventoryConflictLocation PRIMARY KEY CLUSTERED,
   Type  tinyint  NOT NULL  -- 1:Enterprise inventory claims residence, 2:Enterprise inventory refutes residence, 3:Vault inventory claims residence, 4:Vault inventory refutes residence
)

-- Add foreign key constraints
ALTER TABLE dbo.InventoryConflictLocation
   ADD CONSTRAINT fkInventoryConflictLocation$InventoryConflict
      FOREIGN KEY (Id) REFERENCES dbo.InventoryConflict
         ON DELETE CASCADE

-- Move data
EXECUTE
(
'
INSERT InventoryConflictLocation (Id, Type)
SELECT d.ItemId, case m.Location when 1 then 3 else 4 end
FROM   VaultDiscrepancyResidency d
JOIN   Medium m
  ON   m.MediumId = d.MediumId
ORDER  BY ItemId ASC
'
)

-- Error evaluation
IF @@error != 0 GOTO ROLL_IT

-------------------------------------------
-- Unknown serial discrepancies
-------------------------------------------
CREATE TABLE dbo.InventoryConflictUnknownSerial
(
-- Attributes
   Id         int      NOT NULL  CONSTRAINT pkInventoryConflictUnknownSerial PRIMARY KEY CLUSTERED,
   Type       tinyint  NOT NULL, -- 1 if enterprise inventory declared conflict, 0 if vault inventory
   Container  bit      NOT NULL  -- 1 if inventory says that the type is a container, else 0
)

-- Add foreign key constraints
ALTER TABLE dbo.InventoryConflictUnknownSerial
   ADD CONSTRAINT fkInventoryConflictUnknownSerial$InventoryConflict
      FOREIGN KEY (Id) REFERENCES dbo.InventoryConflict
         ON DELETE CASCADE

-- Move data
EXECUTE
(
'
INSERT InventoryConflictUnknownSerial (Id, Type, Container)
SELECT ItemId, 0, 1
FROM   VaultDiscrepancyUnknownCase
ORDER  BY ItemId ASC
'
)

-- Error evaluation
IF @@error != 0 GOTO ROLL_IT

-- Drop old tables (not vault inventory item; it is still used)
EXECUTE ('DROP TABLE VaultDiscrepancyUnknownCase')
IF @@error != 0 GOTO ROLL_IT
EXECUTE ('DROP TABLE VaultDiscrepancyMediumType')
IF @@error != 0 GOTO ROLL_IT
EXECUTE ('DROP TABLE VaultDiscrepancyResidency')
IF @@error != 0 GOTO ROLL_IT
EXECUTE ('DROP TABLE VaultDiscrepancyCaseType')
IF @@error != 0 GOTO ROLL_IT
EXECUTE ('DROP TABLE VaultDiscrepancyAccount')
IF @@error != 0 GOTO ROLL_IT
EXECUTE ('DROP TABLE XVaultDiscrepancy')
IF @@error != 0 GOTO ROLL_IT
EXECUTE ('DROP TABLE VaultDiscrepancy')
IF @@error != 0 GOTO ROLL_IT
EXECUTE ('DROP TABLE XVaultInventory')
IF @@error != 0 GOTO ROLL_IT
EXECUTE ('DROP TABLE VaultInventory')
IF @@error != 0 GOTO ROLL_IT

-- Drop the inventory related stored procedures
DECLARE @e int
DECLARE @r int
DECLARE @routineName nvarchar(256)
WHILE 1 = 1 BEGIN
   SELECT TOP 1 @routineName = ROUTINE_NAME
   FROM   INFORMATION_SCHEMA.ROUTINES
   WHERE  ROUTINE_NAME LIKE 'vaultDiscrepancy%' OR ROUTINE_NAME LIKE 'vaultInventory%'
   SELECT @e = @@error, @r = @@rowcount
   IF @e != 0 GOTO ROLL_IT
   IF @r = 0 BREAK
   EXECUTE ('DROP PROCEDURE ' + @routineName)
   IF @@error != 0 GOTO ROLL_IT
END

END

-------------------------------------------------------------------------------
--
-- Add tab page preference table
--
-------------------------------------------------------------------------------
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'TabPageDefault') BEGIN
CREATE TABLE dbo.TabPageDefault
(
-- Attributes
   Id        int      NOT NULL,
   Operator  int      NOT NULL,
   TabPage   int      NOT NULL  -- 1 : New shipping list
                                -- 2 : New receiving list
)

-- Create the composite index
ALTER TABLE dbo.TabPageDefault ADD CONSTRAINT pkTabPageDefault PRIMARY KEY CLUSTERED (Id, Operator)

-- Add foreign key constraint
ALTER TABLE dbo.TabPageDefault
   ADD CONSTRAINT fkTabPageDefault$Operator
      FOREIGN KEY (Operator) REFERENCES dbo.Operator
         ON DELETE CASCADE
END

-------------------------------------------------------------------------------
--
-- Add list alert tables
--
-------------------------------------------------------------------------------
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'ListAlert') BEGIN
CREATE TABLE dbo.ListAlert
(
-- Attributes
   ListType  int       NOT NULL  CONSTRAINT pkListAlert PRIMARY KEY CLUSTERED, -- 1 - Send, 2 - Receive, 4 - Disaster
   Days      int       NOT NULL,
   LastTime  datetime  NOT NULL  CONSTRAINT defListAlert$LastTime DEFAULT '1900-01-01'
)
END

IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.CHECK_CONSTRAINTS WHERE CONSTRAINT_NAME = 'chkListAlert$ListType')
   ALTER TABLE dbo.ListAlert 
      ADD CONSTRAINT chkListAlert$ListType CHECK (ListType in (1,2,4))

IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.CHECK_CONSTRAINTS WHERE CONSTRAINT_NAME = 'chkListAlert$Days')
   ALTER TABLE dbo.ListAlert
      ADD CONSTRAINT chkListAlert$Days CHECK (Days >= 0)

-- Insert default list alert entries
IF NOT EXISTS (SELECT 1 FROM ListAlert WHERE ListType = 1) INSERT ListAlert (ListType, Days) VALUES (1, 0)
IF NOT EXISTS (SELECT 1 FROM ListAlert WHERE ListType = 2) INSERT ListAlert (ListType, Days) VALUES (2, 0)
IF NOT EXISTS (SELECT 1 FROM ListAlert WHERE ListType = 4) INSERT ListAlert (ListType, Days) VALUES (4, 0)

IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'ListAlertEmail') BEGIN
CREATE TABLE dbo.ListAlertEmail
(
-- Attributes
   ListType  int  NOT NULL,
   GroupId   int  NOT NULL
)
END

IF INDEXPROPERTY(object_id('ListAlertEmail'), 'pkListAlertEmail$ListGroup' , 'IndexId') IS NULL
   CREATE UNIQUE CLUSTERED INDEX pkListAlertEmail$ListGroup ON ListAlertEmail (ListType, GroupId)

IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS WHERE CONSTRAINT_NAME = 'fkListAlertEmail$ListAlert')
ALTER TABLE dbo.ListAlertEmail
   ADD CONSTRAINT fkListAlertEmail$ListAlert
      FOREIGN KEY (ListType) REFERENCES dbo.ListAlert
         ON DELETE CASCADE

IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS WHERE CONSTRAINT_NAME = 'fkListAlertEmail$EmailGroup')
ALTER TABLE dbo.ListAlertEmail
   ADD CONSTRAINT fkListAlertEmail$EmailGroup
      FOREIGN KEY (GroupId) REFERENCES dbo.EmailGroup
         ON DELETE CASCADE

-------------------------------------------------------------------------------
--
-- Version update
--
-------------------------------------------------------------------------------
IF NOT EXISTS(SELECT 1 FROM DatabaseVersion WHERE Major = 1 AND Minor = 3 AND Revision = 0) BEGIN
   DECLARE @x nvarchar(1000)
   EXECUTE spidLogin$ins 'System', 'Insert database version'
   INSERT DatabaseVersion (Major, Minor, Revision) VALUES (1, 3, 0)
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
