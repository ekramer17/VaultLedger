SET NOCOUNT ON

-- Should we run this script?
IF dbo.bit$doScript('1.3.2') = 1 BEGIN

IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'ExternalSiteLocation' AND COLUMN_NAME = 'AccountId') BEGIN
   ALTER TABLE ExternalSiteLocation ADD AccountId int null
END

IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS WHERE CONSTRAINT_NAME = 'fkExternalSiteLocation$Account') BEGIN
ALTER TABLE dbo.ExternalSiteLocation
   ADD CONSTRAINT fkExternalSiteLocation$Account
      FOREIGN KEY (AccountId) REFERENCES dbo.Account
         ON DELETE CASCADE
END

BEGIN TRANSACTION

-- -------------------------------------------------------------------------------
-- --
-- -- Insert tab delimiter preference
-- --
-- -------------------------------------------------------------------------------
-- IF NOT EXISTS (SELECT 1 FROM Preference WHERE KeyNo = 16) BEGIN
--    EXECUTE spidlogin$ins 'System', 'insert preference'
--    INSERT Preference (KeyNo, Value) VALUES (16, 'YES')
--    EXECUTE spidlogin$del 1
-- END

-------------------------------------------------------------------------------
--
-- Add triggers
--
-------------------------------------------------------------------------------
DECLARE @CREATE nvarchar(10)

IF EXISTS(SELECT 1 FROM sysobjects WHERE name = 'inventory$afterInsert' AND objectproperty(id, 'ExecIsInsertTrigger' ) = 1) 
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'TRIGGER inventory$afterInsert
ON     Inventory
WITH ENCRYPTION
AFTER  INSERT
AS
BEGIN
DECLARE @msg nvarchar(255)        -- used to preformat error message
DECLARE @msgTag nvarchar(255)     -- used to hold first part of error message header
DECLARE @msgUpdate nvarchar(4000) -- used to hold the updated fields
DECLARE @tranName nvarchar(255)   -- used to hold name of savepoint
DECLARE @accountNo nvarchar(256)
DECLARE @rowcount int             -- holds the number of rows in the Deleted table
DECLARE @type nvarchar(32)
DECLARE @error int

SET @rowcount = @@rowcount
IF @rowcount = 0 RETURN

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=T''
SET @tranName = object_name(@@procid) + CAST(trigger_nestlevel(@@procid) as nvarchar(2))

-- Batch insert not allowed
IF @rowcount > 1 BEGIN
   SET @msg = ''Batch insert into inventory table not allowed.'' + @msgTag + ''>''
   EXECUTE error$raise @msg, 0
   RETURN
END

-- Begin the transaction
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

-- Get the caller login from the spidLogin table
IF len(dbo.string$GetSpidLogin()) = 0 BEGIN
   SET @msg = ''Caller login not found in spid login table.'' + @msgTag + ''>''
   EXECUTE error$raise @msg, 0, @tranName
   RETURN
END

-- Get the insert message
SELECT @accountNo = a.AccountName,
       @type = case i.Location when 1 then ''Enterprise'' else ''Vault'' end,
       @msg = case i.Location when 1 then ''uploaded'' else ''downloaded'' end
FROM   Account a
JOIN   Inserted i
  ON   i.AccountId = a.AccountId

-- Insert the audit record
INSERT XInventory (Object, Action, Detail, Login)
VALUES(@accountNo, 11, @type + '' inventory '' + @msg + '' for account '' + @accountNo, dbo.string$GetSpidLogin())
SET @error = @@error
IF @error != 0 BEGIN
   SET @msg = ''Error encountered while inserting inventory audit record.'' + @msgTag + '';Error='' + cast(@error as nvarchar(9)) + ''>''
   EXECUTE error$raise @msg, @error, @tranName
   RETURN
END

COMMIT TRANSACTION
END
'
)

-------------------------------------------------------------------------------
--
-- Add procedures
--
-------------------------------------------------------------------------------
IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'inventory$ins')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.inventory$ins
(
   @account nvarchar(256),
   @location bit,
   @fileHash binary(32),
   @downloadTime datetime,
   @newId int out
)
WITH ENCRYPTION
AS
BEGIN
DECLARE @msg nvarchar(255)        -- used to preformat error message
DECLARE @msgTag nvarchar(255)     -- used to hold first part of error message header
DECLARE @tranName nvarchar(255)   -- used to hold name of savepoint
DECLARE @error int
DECLARE @accountId int

SET NOCOUNT ON

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=P''
SET @tranName = object_name(@@procid) + CAST(@@nestlevel as nvarchar(2))

SELECT @accountId = AccountId
FROM   Account
WHERE  AccountName = @account
IF @@rowCount = 0 BEGIN
   SET @msg = ''Account not found.'' + @msgTag + ''>''
   RAISERROR(@msg,16,1)
   RETURN -100
END

-- Begin the transaction
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

-- Delete any old inventories of this account
DELETE Inventory
WHERE  Location = @location AND AccountId = @accountId
SET @error = @@error
IF @error != 0 BEGIN
   ROLLBACK TRANSACTION @tranName
   COMMIT TRANSACTION
   SET @msg = ''Error encountered while deleting old inventory.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
   EXECUTE error$raise @msg, @error
   RETURN -100
END

-- Insert new record
INSERT Inventory (AccountId, Location, FileHash, DownloadTime)
VALUES (@accountId, @location, @fileHash, @downloadTime)
SET @error = @@error
IF @error != 0 BEGIN
   ROLLBACK TRANSACTION @tranName
   COMMIT TRANSACTION
   SET @msg = ''Error encountered while inserting new inventory.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
   EXECUTE error$raise @msg, @error
   RETURN -100
END

-- Commit the transaction
SET @newId = scope_identity()
COMMIT TRANSACTION
RETURN 0
END
'
)

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'inventoryItem$ins')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.inventoryItem$ins
(
   @inventoryId int,
   @serialNo nvarchar(32),
   @typeName nvarchar(128) = '''',
   @returnDate nvarchar(10) = '''',
   @hotStatus bit = 0,
   @notes nvarchar(1000) = ''''
)
WITH ENCRYPTION
AS
BEGIN
DECLARE @msg nvarchar(255)        -- used to preformat error message
DECLARE @msgTag nvarchar(255)     -- used to hold first part of error message header
DECLARE @tranName nvarchar(255)   -- used to hold name of savepoint
DECLARE @typeId int
DECLARE @error int

SET NOCOUNT ON

-- Tweak parameters
SET @typeId = -1
SET @notes = coalesce(@notes,'''')
SET @serialNo = coalesce(@serialNo,'''')
SET @typeName = coalesce(@typeName,'''')
SET @returnDate = coalesce(@returnDate,'''')

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=P''
SET @tranName = object_name(@@procid) + CAST(@@nestlevel as nvarchar(2))

-- Insert record
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

INSERT InventoryItem (SerialNo, InventoryId)
VALUES(@serialNo, @inventoryId)
SET @error = @@error
IF @error != 0 BEGIN
   ROLLBACK TRANSACTION @tranName
   COMMIT TRANSACTION
   SET @msg = ''Error encountered while inserting new inventory item ('' + @serialNo + '').'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
   EXECUTE error$raise @msg, @error
   RETURN -100
END

-- Insert vault portion if inventory is a vault inventory
IF EXISTS (SELECT 1 FROM Inventory WHERE InventoryId = @inventoryId AND Location = 0) BEGIN
   -- Get the medium type if it exists
   IF len(@typeName) != 0 BEGIN
      SELECT @typeId = TypeId
      FROM   MediumType
      WHERE  TypeName = @typeName
      IF @@rowcount = 0 BEGIN
         ROLLBACK TRANSACTION @tranName
         COMMIT TRANSACTION
         SET @msg = ''Medium type '''''' + @typeName + '''''' unknown.'' + @msgTag + ''>''
         RAISERROR(@msg,16,1)
         RETURN -100
      END
   END
   -- Insert the vault portion of the item
   INSERT VaultInventoryItem (ItemId, TypeId, HotStatus, ReturnDate, Notes)
   VALUES(scope_identity(), @typeId, @hotStatus, @returnDate, @notes)
   SET @error = @@error
   IF @error != 0 BEGIN
      ROLLBACK TRANSACTION @tranName
      COMMIT TRANSACTION
      SET @msg = ''Error encountered while inserting vault portion of new inventory item ('' + @serialNo + '').'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
      EXECUTE error$raise @msg, @error
      RETURN -100
   END
END

-- Commit the transaction
COMMIT TRANSACTION
RETURN 0
END
'
)

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'inventory$getLatest')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.inventory$getLatest
(
   @account nvarchar(256) = '''',
   @location bit = 0
)
WITH ENCRYPTION
AS
BEGIN
DECLARE @id int
DECLARE @msg nvarchar(1000)

SET NOCOUNT ON

SELECT @id = AccountId
FROM   Account
WHERE  AccountName = @account
IF @@rowcount = 0 BEGIN
   SET @msg = ''Unable to retrieve inventory.  Account '' + @account + '' not found.<'' + object_name(@@procid) + '';Type=P>''
   EXECUTE error$raise @msg
   RETURN -100
END

-- Get the items, which may or may not be vault items
SELECT i.ItemId,
       i.SerialNo,
       isnull(t.TypeName, '''') as ''TypeName'',
       isnull(v.HotStatus, 0) as ''HotStatus'',
       isnull(v.ReturnDate, '''') as ''ReturnDate'',
       isnull(v.Notes, '''') as ''Notes''
FROM   InventoryItem i
LEFT   JOIN VaultInventoryItem v
  ON   v.ItemId = i.ItemId
LEFT   JOIN MediumType t
  ON   t.TypeId = v.TypeId
WHERE  i.InventoryId = (SELECT TOP 1 InventoryId 
                        FROM   Inventory 
                        WHERE  AccountId = @id AND 
                               Location = @location 
                        ORDER BY DownloadTime DESC)

END
'
)

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'inventory$getLatestHash')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.inventory$getLatestHash
(
   @account nvarchar(256) = '''',
   @location bit = 0,
   @fileHash binary(32) out
)
WITH ENCRYPTION
AS
BEGIN
DECLARE @msg nvarchar(1000)
DECLARE @id int

SET NOCOUNT ON

SET @fileHash = NULL

SELECT @id = AccountId
FROM   Account
WHERE  AccountName = @account
IF @@rowcount = 0 BEGIN
   SET @msg = ''Unable to retrieve inventory hash.  Account '' + @account + '' not found.<'' + object_name(@@procid) + '';Type=P>''
   EXECUTE error$raise @msg
   RETURN -100
END

SELECT TOP 1 @fileHash = FileHash
FROM   Inventory
WHERE  AccountId = @id AND 
       Location = @location
ORDER BY DownloadTime DESC

END
'
)

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'inventory$returnDates')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.inventory$returnDates
WITH ENCRYPTION
AS
BEGIN
DECLARE @i int
DECLARE @msg nvarchar(255)        -- used to preformat error message
DECLARE @msgTag nvarchar(255)     -- used to hold first part of error message header
DECLARE @tranName nvarchar(255)   -- used to hold name of savepoint
DECLARE @serialNo nvarchar(64)
DECLARE @rdate nvarchar(10)
DECLARE @container bit
DECLARE @error int
DECLARE @tbl1 table (RowNo int identity(1,1), SerialNo nvarchar(64), ReturnDate nvarchar(10), Container bit)

SET NOCOUNT ON

-- Set up the transaction name
SET @tranName = object_name(@@procid) + CAST(@@nestlevel as nvarchar(2))

INSERT @tbl1 (SerialNo, ReturnDate, Container)
SELECT ii.SerialNo, vi.ReturnDate, x.Container
FROM   InventoryItem ii
JOIN   VaultInventoryItem vi
  ON   vi.ItemId = ii.ItemId
JOIN  (SELECT SerialNo, 0 as ''Container''
       FROM   Medium
       WHERE  Location = 0 AND ReturnDate IS NULL
       UNION
       SELECT SerialNo, 1
       FROM   SealedCase
       WHERE  ReturnDate IS NULL) as x
  ON   x.SerialNo = ii.SerialNo
WHERE  len(vi.ReturnDate) != 0

-- Begin the transaction
SET @i = 1
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

WHILE 1 = 1 BEGIN
   SELECT @serialNo = SerialNo, 
          @rdate = ReturnDate, 
          @container = Container
   FROM   @tbl1
   WHERE  RowNo = @i
   IF @@rowcount = 0 BREAK
   -- Update return date
   IF @container = 1 BEGIN
      UPDATE SealedCase
      SET    ReturnDate = cast(@rdate as datetime)
      WHERE  SerialNo = @serialNo
   END
   ELSE BEGIN
      UPDATE Medium 
      SET    ReturnDate = cast(@rdate as datetime)
      WHERE  SerialNo = @serialNo
   END
   -- Evaluate error
   SET @error = @@error   
   IF @error != 0 BEGIN
      ROLLBACK TRANSACTION @tranName
      COMMIT TRANSACTION
      SET @msg = ''Error encountered while updating return date of '' + @serialNo + '' via inventory.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
      EXECUTE error$raise @msg, @error
      RETURN -100
   END
   -- Increment counter
   SET @i = @i + 1
END

COMMIT TRANSACTION
RETURN 0
END
'
)

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'inventoryConflict$ins')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.inventoryConflict$ins
(
   @serialNo nvarchar(32),
   @recordedDate datetime,
   @id int out
)
WITH ENCRYPTION
AS
BEGIN
DECLARE @msg as nvarchar(255)        -- used to preformat error message
DECLARE @msgTag as nvarchar(255)     -- used to hold first part of error message header
DECLARE @tranName as nvarchar(255)   -- used to hold name of savepoint
DECLARE @error as int

SET NOCOUNT ON

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @serialNo = isnull(@serialNo,'''')
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=P''
SET @tranName = object_name(@@procid) + CAST(@@nestlevel as nvarchar(2))

-- Update the item
BEGIN TRANSACTION
SAVE TRANSACTION @tranName
   
INSERT InventoryConflict (SerialNo, RecordedDate)
VALUES (@serialNo, @recordedDate)
SET @error = @@error
IF @error != 0 BEGIN
   ROLLBACK TRANSACTION @tranName
   COMMIT TRANSACTION
   SET @msg = ''Error encountered while inserting inventory conflict.'' + @msgTag + '';Error='' +  cast(@error as nvarchar(50)) + ''>''
   EXECUTE error$raise @msg, @error
   RETURN -100
END

SET @id = scope_identity()
   
-- Commit and return
COMMIT TRANSACTION
RETURN 0
END
'
)

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'inventoryConflict$upd')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.inventoryConflict$upd
(
   @id int,
   @recordedDate datetime
)
WITH ENCRYPTION
AS
BEGIN
DECLARE @msg as nvarchar(255)        -- used to preformat error message
DECLARE @msgTag as nvarchar(255)     -- used to hold first part of error message header
DECLARE @tranName as nvarchar(255)   -- used to hold name of savepoint
DECLARE @error as int

SET NOCOUNT ON

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=P''
SET @tranName = object_name(@@procid) + CAST(@@nestlevel as nvarchar(2))

-- If the current discrepancy inventory date is greater than or equal to
-- the given inventory date, return zero.
IF EXISTS (SELECT 1 FROM InventoryConflict WHERE Id = @id AND RecordedDate >= @recordedDate) RETURN 0

-- Update the item
BEGIN TRANSACTION
SAVE TRANSACTION @tranName
   
UPDATE InventoryConflict
SET    RecordedDate = @recordedDate
WHERE  Id = @id
SET @error = @@error
IF @error != 0 BEGIN
   ROLLBACK TRANSACTION @tranName
   COMMIT TRANSACTION
   SET @msg = ''Error encountered while updating inventory conflict.'' + @msgTag + '';Error='' +  cast(@error as nvarchar(50)) + ''>''
   EXECUTE error$raise @msg, @error
   RETURN -100
END
   
-- Commit and return
COMMIT TRANSACTION
RETURN 0
END
'
)

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'inventoryConflict$resolveAccount')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.inventoryConflict$resolveAccount
(
   @id int,
   @reason int -- 1: Account changed, 2: Serial number changed, 3: Deleted, 4: Ignored
)
WITH ENCRYPTION
AS
BEGIN
DECLARE @msg as nvarchar(255)        -- used to preformat error 
DECLARE @msgTag as nvarchar(255)     -- used to hold first part of error message header
DECLARE @tranName as nvarchar(255)   -- used to hold name of savepoint
DECLARE @detail as nvarchar(4000)
DECLARE @serial as nvarchar(32)
DECLARE @error as int

SET NOCOUNT ON

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=P''
SET @tranName = object_name(@@procid) + CAST(@@nestlevel as nvarchar(2))

-- Get the serial number of the medium
SELECT @serial = c.SerialNo
FROM   InventoryConflict c
JOIN   InventoryConflictAccount a
  ON   a.Id = c.Id
WHERE  c.Id = @id
IF @@rowcount = 0 RETURN 0

-- Begin transaction
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

-- Get the caller login from the spidLogin table
IF len(dbo.string$GetSpidLogin()) = 0 BEGIN
   SET @msg = ''Caller login not found in spid login table.'' + @msgTag + ''>''
   EXECUTE error$raise @msg, 0, @tranName
   RETURN
END

-- Delete the conflict
DELETE InventoryConflict
WHERE  Id = @id
SELECT @error = @@error
IF @error != 0 BEGIN
   ROLLBACK TRANSACTION @tranName
   COMMIT TRANSACTION
   SET @msg = ''Error encountered while deleting inventory conflict.'' + @msgTag + '';Error='' +  cast(@error as nvarchar(50)) + ''>''
   EXECUTE error$raise @msg, @error
   RETURN -100
END
   
-- Insert vault discrepancy audit record
SELECT @detail = ''Inventory account conflict for serial number '' + @serial + '' has been resolved.  '' + case @reason when 1 then ''Medium account was changed.'' when 2 then ''Serial number was changed.'' when 3 then ''Medium was deleted.'' when 4 then ''Conflict was ignored.'' else ''Reason unknown.'' end
INSERT XInventoryConflict (Object, Action, Detail, Login)
VALUES(@serial, 3, @detail, dbo.string$GetSpidLogin())
SELECT @error = @@error
IF @error != 0 BEGIN
   ROLLBACK TRANSACTION @tranName
   COMMIT TRANSACTION
   SET @msg = ''Error encountered while inserting an inventory account conflict resolution record.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
   EXECUTE error$raise @msg, @error
   RETURN -100
END

-- Commit and return
COMMIT TRANSACTION
RETURN 0
END
'
)

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'inventoryConflict$resolveLocation')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.inventoryConflict$resolveLocation
(
   @id int,
   @reason int -- 1: Moved, 2: Missing, 3: Serial number changed 4: Deleted, 5: Ignored
)
WITH ENCRYPTION
AS
BEGIN
DECLARE @msg as nvarchar(255)        -- used to preformat error 
DECLARE @msgTag as nvarchar(255)     -- used to hold first part of error message header
DECLARE @tranName as nvarchar(255)   -- used to hold name of savepoint
DECLARE @detail as nvarchar(4000)
DECLARE @serial as nvarchar(32)
DECLARE @error as int

SET NOCOUNT ON

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=P''
SET @tranName = object_name(@@procid) + CAST(@@nestlevel as nvarchar(2))

-- Get the serial number of the medium
SELECT @serial = c.SerialNo
FROM   InventoryConflict c
JOIN   InventoryConflictLocation l
  ON   l.Id = c.Id
WHERE  c.Id = @id
IF @@rowcount = 0 RETURN 0

-- Begin transaction
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

-- Get the caller login from the spidLogin table
IF len(dbo.string$GetSpidLogin()) = 0 BEGIN
   SET @msg = ''Caller login not found in spid login table.'' + @msgTag + ''>''
   EXECUTE error$raise @msg, 0, @tranName
   RETURN
END

-- Delete the conflict
DELETE InventoryConflict
WHERE  Id = @id
SELECT @error = @@error
IF @error != 0 BEGIN
   ROLLBACK TRANSACTION @tranName
   COMMIT TRANSACTION
   SET @msg = ''Error encountered while deleting inventory conflict.'' + @msgTag + '';Error='' +  cast(@error as nvarchar(50)) + ''>''
   EXECUTE error$raise @msg, @error
   RETURN -100
END
   
-- Insert vault discrepancy audit record
SELECT @detail = ''Inventory location conflict for serial number '' + @serial + '' has been resolved.  '' + case @reason when 1 then ''Medium was moved.'' when 2 then ''Medium was designated missing.'' when 3 then ''Serial number was changed.'' when 4 then ''Medium was deleted.'' when 5 then ''Conflict was ignored.'' else ''Reason unknown.'' end
INSERT XInventoryConflict (Object, Action, Detail, Login)
VALUES(@serial, 3, @detail, dbo.string$GetSpidLogin())
SELECT @error = @@error
IF @error != 0 BEGIN
   ROLLBACK TRANSACTION @tranName
   COMMIT TRANSACTION
   SET @msg = ''Error encountered while inserting an inventory location conflict resolution record.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
   EXECUTE error$raise @msg, @error
   RETURN -100
END

-- Commit and return
COMMIT TRANSACTION
RETURN 0
END
'
)

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'inventoryConflict$resolveObjectType')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.inventoryConflict$resolveObjectType
(
   @id int,
   @reason int -- 1: Type changed, 2: Serial changed, 3: Deleted, 4: Ignored
)
WITH ENCRYPTION
AS
BEGIN
DECLARE @msg as nvarchar(255)        -- used to preformat error 
DECLARE @msgTag as nvarchar(255)     -- used to hold first part of error message header
DECLARE @tranName as nvarchar(255)   -- used to hold name of savepoint
DECLARE @detail as nvarchar(4000)
DECLARE @serial as nvarchar(32)
DECLARE @error as int

SET NOCOUNT ON

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=P''
SET @tranName = object_name(@@procid) + CAST(@@nestlevel as nvarchar(2))

-- Get the serial number of the medium
SELECT @serial = c.SerialNo
FROM   InventoryConflict c
JOIN   InventoryConflictObjectType o
  ON   o.Id = c.Id
WHERE  c.Id = @id
IF @@rowcount = 0 RETURN 0

-- Begin transaction
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

-- Get the caller login from the spidLogin table
IF len(dbo.string$GetSpidLogin()) = 0 BEGIN
   SET @msg = ''Caller login not found in spid login table.'' + @msgTag + ''>''
   EXECUTE error$raise @msg, 0, @tranName
   RETURN
END

-- Delete the conflict
DELETE InventoryConflict
WHERE  Id = @id
SELECT @error = @@error
IF @error != 0 BEGIN
   ROLLBACK TRANSACTION @tranName
   COMMIT TRANSACTION
   SET @msg = ''Error encountered while deleting inventory conflict.'' + @msgTag + '';Error='' +  cast(@error as nvarchar(50)) + ''>''
   EXECUTE error$raise @msg, @error
   RETURN -100
END
   
-- Insert vault discrepancy audit record
SELECT @detail = ''Inventory object type conflict for serial number '' + @serial + '' has been resolved.  '' + case @reason when 1 then ''Type was changed.'' when 2 then ''Serial number was changed.'' when 3 then ''Object was deleted.'' when 4 then ''Conflict was ignored.'' else ''Reason unknown.'' end
INSERT XInventoryConflict (Object, Action, Detail, Login)
VALUES(@serial, 3, @detail, dbo.string$GetSpidLogin())
SELECT @error = @@error
IF @error != 0 BEGIN
   ROLLBACK TRANSACTION @tranName
   COMMIT TRANSACTION
   SET @msg = ''Error encountered while inserting an inventory object type conflict resolution record.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
   EXECUTE error$raise @msg, @error
   RETURN -100
END

-- Commit and return
COMMIT TRANSACTION
RETURN 0
END
'
)

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'inventoryConflict$resolveUnknownSerial')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.inventoryConflict$resolveUnknownSerial
(
   @id int,
   @reason int -- 1: Object added, 2: Serial changed, 3: Ignored
)
WITH ENCRYPTION
AS
BEGIN
DECLARE @msg as nvarchar(255)        -- used to preformat error 
DECLARE @msgTag as nvarchar(255)     -- used to hold first part of error message header
DECLARE @tranName as nvarchar(255)   -- used to hold name of savepoint
DECLARE @detail as nvarchar(4000)
DECLARE @serial as nvarchar(32)
DECLARE @type as nvarchar(32)
DECLARE @error as int

SET NOCOUNT ON

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=P''
SET @tranName = object_name(@@procid) + CAST(@@nestlevel as nvarchar(2))

-- Get the serial number of the medium
SELECT @serial = c.SerialNo
FROM   InventoryConflict c
JOIN   InventoryConflictUnknownSerial s
  ON   s.Id = c.Id
WHERE  c.Id = @id
IF @@rowcount = 0 RETURN 0

-- Begin transaction
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

-- Get the caller login from the spidLogin table
IF len(dbo.string$GetSpidLogin()) = 0 BEGIN
   SET @msg = ''Caller login not found in spid login table.'' + @msgTag + ''>''
   EXECUTE error$raise @msg, 0, @tranName
   RETURN
END

-- Delete the conflict
DELETE InventoryConflict
WHERE  Id = @id
SELECT @error = @@error
IF @error != 0 BEGIN
   ROLLBACK TRANSACTION @tranName
   COMMIT TRANSACTION
   SET @msg = ''Error encountered while deleting inventory conflict.'' + @msgTag + '';Error='' +  cast(@error as nvarchar(50)) + ''>''
   EXECUTE error$raise @msg, @error
   RETURN -100
END
   
-- Insert vault discrepancy audit record
IF EXISTS (SELECT 1 FROM Medium WHERE SerialNo = @serial) SET @type = ''Medium'' else SET @type = ''Case''
SELECT @detail = ''Inventory unknown serial conflict for serial number '' + @serial + '' has been resolved.  '' + case @reason when 1 then @type + '' has been added.'' when 2 then ''Serial number has been changed.'' when 3 then ''Conflict was ignored.'' else ''Reason unknown.'' end
INSERT XInventoryConflict (Object, Action, Detail, Login)
VALUES(@serial, 3, @detail, dbo.string$GetSpidLogin())
SELECT @error = @@error
IF @error != 0 BEGIN
   ROLLBACK TRANSACTION @tranName
   COMMIT TRANSACTION
   SET @msg = ''Error encountered while inserting an inventory unknown serial conflict resolution record.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
   EXECUTE error$raise @msg, @error
   RETURN -100
END

-- Commit and return
COMMIT TRANSACTION
RETURN 0
END
'
)

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'inventory$compareAccount')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.inventory$compareAccount
WITH ENCRYPTION
AS
BEGIN
DECLARE @msg nvarchar(255)        -- used to preformat error message
DECLARE @msgTag nvarchar(255)     -- used to hold first part of error message header
DECLARE @tranName nvarchar(255)   -- used to hold name of savepoint
DECLARE @serialNo nvarchar(64)
DECLARE @time datetime
DECLARE @type tinyint
DECLARE @error int
DECLARE @returnValue int
DECLARE @tbl1 table (RowNo int identity(1,1), SerialNo nvarchar(64), Type tinyint, AccountId int)
DECLARE @aid int
DECLARE @id int
DECLARE @i int

SET NOCOUNT ON

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=P''
SET @tranName = object_name(@@procid) + CAST(@@nestlevel as nvarchar(2))
SET @time = cast(convert(nvarchar(19), getutcdate(), 120) as datetime)
SET @i = 1

-- Compare account of serial numbers in inventory to account numbers of media in database
INSERT @tbl1 (SerialNo, Type, AccountId)
SELECT m.SerialNo, i.Location, i.AccountId
FROM   Medium m
JOIN   InventoryItem ii
  ON   ii.Serialno = m.SerialNo
JOIN   Inventory i
  ON   i.InventoryId = ii.InventoryId
WHERE  m.AccountId != i.AccountId

-- Begin transaction
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

WHILE 1 = 1 BEGIN
   SELECT @serialNo = SerialNo, 
          @type = Type, 
          @aid = AccountId
   FROM   @tbl1
   WHERE  RowNo = @i
   IF @@rowcount = 0 BREAK
   -- Insert or update the conflict
   SELECT @id = c1.Id
   FROM   InventoryConflict c1
   JOIN   InventoryConflictAccount c2
     ON   c1.Id = c2.Id
   WHERE  c1.SerialNo = @serialNo AND c2.Type = @type
   IF @@rowcount != 0 BEGIN
      EXECUTE @returnValue = inventoryConflict$upd @id, @time
      IF @returnValue != 0 BEGIN
         ROLLBACK TRANSACTION @tranName
         COMMIT TRANSACTION
         RETURN -100
      END
      -- Update the account id of the conflict
      UPDATE InventoryConflictAccount
      SET    AccountId = @aid
      WHERE  Id = @id
      SET @error = @@error
      IF @error != 0 BEGIN
         ROLLBACK TRANSACTION @tranName
         COMMIT TRANSACTION
         SET @msg = ''Error encountered while updating inventory account conflict.'' + @msgTag + '';Error='' +  cast(@error as nvarchar(50)) + ''>''
         EXECUTE error$raise @msg, @error
         RETURN -100
      END
   END
   ELSE BEGIN
      -- Insert the conflict record
      EXECUTE @returnValue = inventoryConflict$ins @serialNo, @time, @id out
      IF @returnValue != 0 BEGIN
         ROLLBACK TRANSACTION @tranName
         COMMIT TRANSACTION
         RETURN -100
      END
      -- Insert the information specific to a location conflict
      INSERT InventoryConflictAccount (Id, Type, AccountId)
      VALUES (@id, @type, @aid)
      SET @error = @@error
      IF @error != 0 BEGIN
         ROLLBACK TRANSACTION @tranName
         COMMIT TRANSACTION
         SET @msg = ''Error encountered while inserting inventory account conflict.'' + @msgTag + '';Error='' +  cast(@error as nvarchar(50)) + ''>''
         EXECUTE error$raise @msg, @error
         RETURN -100
      END
   END
   -- Increment counter
   SET @i = @i + 1
END

-- Commit and return
COMMIT TRANSACTION
RETURN 0
END
'
)

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'inventory$compareLocation')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.inventory$compareLocation
WITH ENCRYPTION
AS
BEGIN
DECLARE @msg nvarchar(255)        -- used to preformat error message
DECLARE @msgTag nvarchar(255)     -- used to hold first part of error message header
DECLARE @tranName nvarchar(255)   -- used to hold name of savepoint
DECLARE @serialNo nvarchar(64)
DECLARE @type tinyint
DECLARE @time datetime
DECLARE @error int
DECLARE @returnValue int
DECLARE @tbl1 table (RowNo int identity(1,1), MediumId int, SerialNo nvarchar(64), Type tinyint)
DECLARE @mid int
DECLARE @ex1 bit
DECLARE @ex2 bit
DECLARE @id int
DECLARE @i int

SET NOCOUNT ON
------------------------------------------------------------------------------------------------------------------------------------
--
-- Inventory claims residence : Tape at opposite location, mentioned in inventory file (inner join)
-- Inventory refutes residence : Tape at same location, not mentioned in inventory file and not missing
--
------------------------------------------------------------------------------------------------------------------------------------

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SELECT @msgTag = ''<'' + object_name(@@procid) + '';Type=P''
SELECT @tranName = object_name(@@procid) + CAST(@@nestlevel as nvarchar(2))
SELECT @time = cast(convert(nvarchar(19), getutcdate(), 120) as datetime)
SELECT @ex1 = 0, @ex2 = 0, @i = 1

----------------------------------------------------------------------------
-- Enterprise inventory claims residence (type 1)
----------------------------------------------------------------------------
INSERT @tbl1 (MediumId, SerialNo, Type)
SELECT isnull(m.MediumId,-1), ii.SerialNo, 1
FROM   InventoryItem ii
JOIN   Inventory i
  ON   i.InventoryId = ii.InventoryId
JOIN   Medium m
  ON   m.SerialNo = ii.SerialNo
WHERE  m.Location = 0 AND i.Location = 1

----------------------------------------------------------------------------
-- Enterprise inventory refutes residence (type 2)
--
-- Note that we''re only considering tapes where an inventory for that
-- account has been taken.  If we do not have an inventory for the account
-- of a tape, then we will not designate a location conflict for the tape.
----------------------------------------------------------------------------
INSERT @tbl1 (MediumId, SerialNo, Type)
SELECT m.MediumId, m.SerialNo, 2
FROM   Medium m
JOIN   Account a
  ON   a.AccountId = m.AccountId
JOIN   Inventory i
  ON   i.AccountId = a.AccountId
LEFT   JOIN
      (SELECT ii1.SerialNo
       FROM   InventoryItem ii1
       JOIN   Inventory i1
         ON   i1.InventoryId = ii1.InventoryId
       WHERE  i1.Location = 1) as x
  ON   x.SerialNo = m.SerialNo
WHERE  m.Missing = 0 AND m.Location = 1 AND i.Location = 1 AND x.SerialNo IS NULL

----------------------------------------------------------------------------
-- Vault inventory claims residence (type 3)
----------------------------------------------------------------------------
INSERT @tbl1 (MediumId, SerialNo, Type)
SELECT isnull(m.MediumId,-1), ii.SerialNo, 3
FROM   InventoryItem ii
JOIN   Inventory i
  ON   i.InventoryId = ii.InventoryId
JOIN   Medium m
  ON   m.SerialNo = ii.SerialNo
WHERE  m.Location = 1 AND i.Location = 0

----------------------------------------------------------------------------
-- Vault inventory refutes residence (type 4)
--
-- Note that we''re only considering tapes where an inventory for that
-- account has been taken.  If we do not have an inventory for the account
-- of a tape, then we will not designate a location conflict for the tape.
----------------------------------------------------------------------------
INSERT @tbl1 (MediumId, SerialNo, Type)
SELECT m.MediumId, m.SerialNo, 4
FROM   Medium m
JOIN   Account a
  ON   a.AccountId = m.AccountId
JOIN   Inventory i
  ON   i.AccountId = a.AccountId
LEFT   JOIN
      (SELECT ii1.SerialNo
       FROM   InventoryItem ii1
       JOIN   Inventory i1
         ON   i1.InventoryId = ii1.InventoryId
       WHERE  i1.Location = 0
       UNION
       SELECT m1.SerialNo
       FROM   Medium m1
       JOIN   MediumSealedCase mc1
         ON   m1.MediumId = mc1.MediumId
       JOIN   SealedCase c1
         ON   c1.CaseId = mc1.CaseId
       JOIN   InventoryItem ii1
         ON   ii1.SerialNo = c1.SerialNo
       JOIN   Inventory i1
         ON   i1.InventoryId = ii1.InventoryId
       WHERE  i1.Location = 0) as x
  ON   x.SerialNo = m.SerialNo
WHERE  m.Missing = 0 AND m.Location = 0 AND i.Location = 0 AND x.SerialNo IS NULL

-- Get exclusion parmeters
IF EXISTS 
   (
   SELECT 1 
   FROM   Preference 
   WHERE  KeyNo = 6 AND Value IN (''YES'',''TRUE'')
   )
BEGIN
   SET @ex1 = 1 -- Active lists
END

IF EXISTS 
   (
   SELECT 1 
   FROM   Preference 
   WHERE  KeyNo = 7 AND Value IN (''YES'',''TRUE'')
   ) 
BEGIN
   SET @ex2 = 1 -- Today''s lists
END

-- Begin transaction
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

-- Record conflicts
WHILE 1 = 1 BEGIN
   SELECT @mid = MediumId, 
          @serialNo = SerialNo, 
          @type = Type
   FROM   @tbl1
   WHERE  RowNo = @i
   IF @@rowcount = 0 BREAK
   -- Excluding active lists and on active send list?
   IF @ex1 = 1 AND EXISTS (SELECT 1 FROM SendListItem WHERE MediumId = @mid AND Status not in (1,512)) GOTO NEXTROW
   -- Excluding active lists and on active receive list?
   IF @ex1 = 1 AND EXISTS (SELECT 1 FROM ReceiveListItem WHERE MediumId = @mid AND Status not in (1,512)) GOTO NEXTROW
   -- Excluding today''s lists and on today''s send list?
   IF @ex2 = 1 AND EXISTS (SELECT 1 FROM SendListItem sli JOIN SendList sl ON sl.ListId = sli.ListId AND sli.MediumId = @mid AND convert(nchar(10),sl.CreateDate,120) = convert(nchar(10),getutcdate(),120)) GOTO NEXTROW
   -- Excluding today''s lists and on today''s receive list?
   IF @ex2 = 1 AND EXISTS (SELECT 1 FROM ReceiveListItem rli JOIN ReceiveList rl ON rl.ListId = rli.ListId AND rli.MediumId = @mid AND convert(nchar(10),rl.CreateDate,120) = convert(nchar(10),getutcdate(),120)) GOTO NEXTROW
   -- Insert or update the conflict
   SELECT @id = c1.Id
   FROM   InventoryConflict c1
   JOIN   InventoryConflictLocation c2
     ON   c1.Id = c2.Id
   WHERE  c1.SerialNo = @serialNo AND c2.Type = @type
   IF @@rowcount != 0 BEGIN
      EXECUTE @returnValue = inventoryConflict$upd @id, @time
      IF @returnValue != 0 BEGIN
         ROLLBACK TRANSACTION @tranName
         COMMIT TRANSACTION
         RETURN -100
      END
   END
   ELSE BEGIN
      -- Insert the conflict record
      EXECUTE @returnValue = inventoryConflict$ins @serialNo, @time, @id out
      IF @returnValue != 0 BEGIN
         ROLLBACK TRANSACTION @tranName
         COMMIT TRANSACTION
         RETURN -100
      END
      -- Insert the information specific to a location conflict
      INSERT InventoryConflictLocation (Id, Type)
      VALUES (@id, @type)
      SET @error = @@error
      IF @error != 0 BEGIN
         ROLLBACK TRANSACTION @tranName
         COMMIT TRANSACTION
         SET @msg = ''Error encountered while inserting inventory location conflict.'' + @msgTag + '';Error='' +  cast(@error as nvarchar(50)) + ''>''
         EXECUTE error$raise @msg, @error
         RETURN -100
      END
   END
   -- Next row
   NEXTROW:
   SET @i = @i + 1
END

-- Commit and return
COMMIT TRANSACTION
RETURN 0
END
'
)

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'inventory$compareObjectType')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.inventory$compareObjectType
WITH ENCRYPTION
AS
BEGIN
DECLARE @msg nvarchar(255)        -- used to preformat error message
DECLARE @msgTag nvarchar(255)     -- used to hold first part of error message header
DECLARE @tranName nvarchar(255)   -- used to hold name of savepoint
DECLARE @serialNo nvarchar(64)
DECLARE @time datetime
DECLARE @typeId int
DECLARE @type tinyint
DECLARE @error int
DECLARE @returnValue int
DECLARE @tbl1 table (RowNo int identity(1,1), SerialNo nvarchar(64), TypeId int)
DECLARE @aid int
DECLARE @id int
DECLARE @i int

SET NOCOUNT ON

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=P''
SET @tranName = object_name(@@procid) + CAST(@@nestlevel as nvarchar(2))
SET @time = cast(convert(nvarchar(19), getutcdate(), 120) as datetime)
SET @i = 1

-- Object types are only supplied by vault inventories, and even then only sometimes
INSERT @tbl1 (SerialNo, TypeId)
SELECT m.SerialNo, vi.TypeId
FROM   Medium m
JOIN   InventoryItem ii
  ON   ii.SerialNo = m.SerialNo
JOIN   VaultInventoryItem vi
  ON   vi.ItemId = ii.ItemId
JOIN   Inventory i
  ON   i.InventoryId = ii.InventoryId
WHERE  m.TypeId != isnull(vi.TypeId,-1)
UNION
SELECT c.SerialNo, vi.TypeId
FROM   SealedCase c
JOIN   InventoryItem ii
  ON   ii.SerialNo = c.SerialNo
JOIN   VaultInventoryItem vi
  ON   vi.ItemId = ii.ItemId
JOIN   Inventory i
  ON   i.InventoryId = ii.InventoryId
WHERE  c.TypeId != isnull(vi.TypeId,-1)

-- Begin transaction
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

WHILE 1 = 1 BEGIN
   SELECT @serialNo = SerialNo, 
          @typeId = TypeId
   FROM   @tbl1
   WHERE  RowNo = @i
   IF @@rowcount = 0 BREAK
   -- Insert or update the conflict
   SELECT @id = c1.Id
   FROM   InventoryConflict c1
   JOIN   InventoryConflictObjectType c2
     ON   c1.Id = c2.Id
   WHERE  c1.SerialNo = @serialNo
   IF @@rowcount != 0 BEGIN
      EXECUTE @returnValue = inventoryConflict$upd @id, @time
      IF @returnValue != 0 BEGIN
         ROLLBACK TRANSACTION @tranName
         COMMIT TRANSACTION
         RETURN -100
      END
      -- Update the account id of the conflict
      UPDATE InventoryConflictObjectType
      SET    TypeId = @typeId
      WHERE  Id = @id
      SET @error = @@error
      IF @error != 0 BEGIN
         ROLLBACK TRANSACTION @tranName
         COMMIT TRANSACTION
         SET @msg = ''Error encountered while updating inventory object type conflict.'' + @msgTag + '';Error='' +  cast(@error as nvarchar(50)) + ''>''
         EXECUTE error$raise @msg, @error
         RETURN -100
      END
   END
   ELSE BEGIN
      -- Insert the conflict record
      EXECUTE @returnValue = inventoryConflict$ins @serialNo, @time, @id out
      IF @returnValue != 0 BEGIN
         ROLLBACK TRANSACTION @tranName
         COMMIT TRANSACTION
         RETURN -100
      END
      -- Insert the information specific to a location conflict
      INSERT InventoryConflictObjectType (Id, TypeId)
      VALUES (@id, @typeId)
      SET @error = @@error
      IF @error != 0 BEGIN
         ROLLBACK TRANSACTION @tranName
         COMMIT TRANSACTION
         SET @msg = ''Error encountered while inserting inventory object type conflict.'' + @msgTag + '';Error='' +  cast(@error as nvarchar(50)) + ''>''
         EXECUTE error$raise @msg, @error
         RETURN -100
      END
   END
   -- Increment counter
   SET @i = @i + 1
END

-- Commit and return
COMMIT TRANSACTION
RETURN 0
END
'
)

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'inventory$compareUnknownSerial')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.inventory$compareUnknownSerial
WITH ENCRYPTION
AS
BEGIN
DECLARE @msg nvarchar(255)        -- used to preformat error message
DECLARE @msgTag nvarchar(255)     -- used to hold first part of error message header
DECLARE @tranName nvarchar(255)   -- used to hold name of savepoint
DECLARE @serialNo nvarchar(64)
DECLARE @time datetime
DECLARE @type tinyint
DECLARE @error int
DECLARE @returnValue int
DECLARE @tbl1 table (RowNo int identity(1,1), SerialNo nvarchar(64), Type tinyint, Container bit)
DECLARE @container bit
DECLARE @id int
DECLARE @i int

SET NOCOUNT ON

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=P''
SET @tranName = object_name(@@procid) + CAST(@@nestlevel as nvarchar(2))
SET @time = cast(convert(nvarchar(19), getutcdate(), 120) as datetime)
SET @i = 1

-- Object types are only supplied by vault inventories, and even then only sometimes
INSERT @tbl1 (SerialNo, Type, Container)
SELECT ii.SerialNo, i.Location, isnull(dbo.bit$IsContainerType(isnull(vi.TypeId,-1)),0)
FROM   InventoryItem ii
JOIN   Inventory i
  ON   i.InventoryId = ii.InventoryId
LEFT   JOIN VaultInventoryItem vi
  ON   vi.ItemId = ii.ItemId
LEFT   JOIN
      (SELECT SerialNo
       FROM   Medium
       UNION
       SELECT SerialNo
       FROM   SealedCase
       UNION
       SELECT SerialNo
       FROM   SendListCase) as x
  ON   x.SerialNo = ii.SerialNo
WHERE  x.SerialNo IS NULL

-- Begin transaction
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

WHILE 1 = 1 BEGIN
   SELECT @serialNo = SerialNo,
          @type = Type, 
          @container = Container
   FROM   @tbl1
   WHERE  RowNo = @i
   IF @@rowcount = 0 BREAK
   -- Insert or update the conflict
   SELECT @id = c1.Id
   FROM   InventoryConflict c1
   JOIN   InventoryConflictUnknownSerial c2
     ON   c1.Id = c2.Id
   WHERE  c1.SerialNo = @serialNo AND Type = @type
   IF @@rowcount != 0 BEGIN
      EXECUTE @returnValue = inventoryConflict$upd @id, @time
      IF @returnValue != 0 BEGIN
         ROLLBACK TRANSACTION @tranName
         COMMIT TRANSACTION
         RETURN -100
      END
      -- Update the account id of the conflict
      UPDATE InventoryConflictUnknownSerial
      SET    Container = @container
      WHERE  Id = @id
      SET @error = @@error
      IF @error != 0 BEGIN
         ROLLBACK TRANSACTION @tranName
         COMMIT TRANSACTION
         SET @msg = ''Error encountered while updating inventory unknown serial conflict.'' + @msgTag + '';Error='' +  cast(@error as nvarchar(50)) + ''>''
         EXECUTE error$raise @msg, @error
         RETURN -100
      END
   END
   ELSE BEGIN
      -- Insert the conflict record
      EXECUTE @returnValue = inventoryConflict$ins @serialNo, @time, @id out
      IF @returnValue != 0 BEGIN
         ROLLBACK TRANSACTION @tranName
         COMMIT TRANSACTION
         RETURN -100
      END
      -- Insert the information specific to a location conflict
      INSERT InventoryConflictUnknownSerial (Id, Type, Container)
      VALUES (@id, @type, @container)
      SET @error = @@error
      IF @error != 0 BEGIN
         ROLLBACK TRANSACTION @tranName
         COMMIT TRANSACTION
         SET @msg = ''Error encountered while inserting inventory unknown serial conflict.'' + @msgTag + '';Error='' +  cast(@error as nvarchar(50)) + ''>''
         EXECUTE error$raise @msg, @error
         RETURN -100
      END
   END
   -- Increment counter
   SET @i = @i + 1
END

-- Commit and return
COMMIT TRANSACTION
RETURN 0
END
'
)

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'inventory$compare')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.inventory$compare
(
   @insertMedia bit = 1, -- Create media if serial number not valid
   @doResolve bit = 1  -- Perform reconciliations prior to comparison
)
WITH ENCRYPTION
AS
BEGIN
DECLARE @msg nvarchar(255)        -- used to preformat error message
DECLARE @msgTag nvarchar(255)     -- used to hold first part of error message header
DECLARE @tranName nvarchar(255)   -- used to hold name of savepoint
DECLARE @returnValue int
DECLARE @error int
DECLARE @i int
DECLARE @id int
DECLARE @loc bit
DECLARE @itemId int
DECLARE @typeId int
DECLARE @reason int
DECLARE @serialNo nvarchar(256)
DECLARE @rdate nvarchar(10)
DECLARE @tbl1 table (RowNo int identity(1,1), SerialNo nvarchar(256), Location bit)
DECLARE @tbl2 table (RowNo int identity(1,1), Id int, SerialNo nvarchar(64), Reason int)

SET NOCOUNT ON

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=P''
SET @tranName = object_name(@@procid) + CAST(@@nestlevel as nvarchar(2))

-- Make sure we have a login for the audit record to come later
IF len(dbo.string$getSpidLogin()) = 0 BEGIN
   SET @msg = ''No login specified for auditing purposes.'' + @msgTag + ''>''
   EXECUTE error$raise @msg, 0
   RETURN -100
END

-- Begin the transaction
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

--------------------------------
-- Add new media if applicable
--------------------------------
IF @insertMedia = 1 BEGIN
   INSERT @tbl1 (SerialNo, Location)
   SELECT ii.SerialNo, i.Location
   FROM   InventoryItem ii
   JOIN   Inventory i
     ON   i.InventoryId = ii.InventoryId
   LEFT   JOIN
         (SELECT SerialNo
          FROM   Medium
          UNION
          SELECT SerialNo
          FROM   SealedCase
          UNION
          SELECT SerialNo
          FROM   SendListCase) as x
     ON   x.SerialNo = ii.SerialNo
   LEFT   JOIN VaultInventoryItem vi
     ON   vi.ItemId = ii.ItemId
   WHERE  x.SerialNo IS NULL AND isnull(dbo.bit$IsContainerType(vi.TypeId),0) = 0
   -- Run through the table, adding media   
   SET @i = 1
   WHILE 1 = 1 BEGIN
      -- Get the next medium
      SELECT @serialNo = SerialNo, @loc = Location
      FROM   @tbl1
      WHERE  RowNo = @i
      IF @@rowcount = 0 BREAK
      -- Add it dynamically
      EXECUTE @returnValue = medium$addDynamic @serialNo, @loc, @id out
      IF @returnValue != 0 BEGIN
         ROLLBACK TRANSACTION @tranName
         COMMIT TRANSACTION
         RETURN -100
      END
      -- Increment counter
      SET @i = @i + 1
   END
END

----------------------
-- Compare locations
----------------------
EXECUTE @returnValue = inventory$compareLocation
IF @returnValue != 0 BEGIN
   ROLLBACK TRANSACTION @tranName
   COMMIT TRANSACTION
   RETURN -100
END

----------------------
-- Compare accounts
----------------------
EXECUTE @returnValue = inventory$compareAccount
IF @returnValue != 0 BEGIN
   ROLLBACK TRANSACTION @tranName
   COMMIT TRANSACTION
   RETURN -100
END

-------------------------
-- Compare object types
-------------------------
EXECUTE @returnValue = inventory$compareObjectType
IF @returnValue != 0 BEGIN
   ROLLBACK TRANSACTION @tranName
   COMMIT TRANSACTION
   RETURN -100
END

-----------------------------------
-- Compare unknown serial numbers
-----------------------------------
EXECUTE @returnValue = inventory$compareUnknownSerial
IF @returnValue != 0 BEGIN
   ROLLBACK TRANSACTION @tranName
   COMMIT TRANSACTION
   RETURN -100
END

---------------------
-- Set return dates
---------------------
EXECUTE @returnValue = inventory$returnDates
IF @returnValue != 0 BEGIN
   ROLLBACK TRANSACTION @tranName
   COMMIT TRANSACTION
   RETURN -100
END

------------------------------------------
-- Remove reconciled residency conflicts
------------------------------------------
IF @doResolve = 1 BEGIN
   -- Resolve location conflicts
   INSERT @tbl2 (Id, SerialNo, Reason)
   SELECT c.Id, c.SerialNo, case m.Missing when 1 then 2 else 1 end
   FROM   InventoryConflict c
   JOIN   Medium m
     ON   m.SerialNo = c.SerialNo
   JOIN   InventoryConflictLocation l
     ON   l.Id = c.Id
   WHERE (l.Type in (1,4) AND m.Location = 1) OR (l.Type in (2,3) AND m.Location = 0) OR m.Missing = 1
   -- Cycle through the resolved locations
   SELECT @i = min(RowNo) FROM @tbl2
   WHILE 1 = 1 BEGIN
      SELECT @id = Id, @serialNo = SerialNo, @reason = Reason
      FROM   @tbl2
      WHERE  RowNo = @i
      IF @@rowcount = 0 BREAK
      -- Discern the reason
      EXECUTE @returnValue = inventoryConflict$resolveLocation @id, @reason
      IF @returnValue != 0 BEGIN
         ROLLBACK TRANSACTION @tranName
         COMMIT TRANSACTION
         RETURN -100
      END
      SET @i = @i + 1
   END
   -- Clear the table
   DELETE @tbl2
   -- Resolve account discrepancies
   INSERT @tbl2 (Id)
   SELECT c.Id
   FROM   InventoryConflict c
   JOIN   Medium m
     ON   m.SerialNo = c.SerialNo
   JOIN   InventoryConflictAccount a
     ON   a.Id = c.Id
   WHERE  m.AccountId = a.AccountId
   -- Cycle through the resolved accounts
   SELECT @i = min(RowNo) FROM @tbl2
   WHILE 1 = 1 BEGIN
      SELECT @id = Id
      FROM   @tbl2
      WHERE  RowNo = @i
      IF @@rowcount = 0 BREAK
      EXECUTE @returnValue = inventoryConflict$resolveAccount @id, 1
      IF @returnValue != 0 BEGIN
         ROLLBACK TRANSACTION @tranName
         COMMIT TRANSACTION
         RETURN -100
      END
      SET @i = @i + 1
   END
   -- Clear the table
   DELETE @tbl2
   -- Resolve object type discrepancies
   INSERT @tbl2 (Id)
   SELECT c.Id
   FROM   InventoryConflict c
   JOIN  (SELECT SerialNo, TypeId
          FROM   Medium
          UNION
          SELECT SerialNo, TypeId
          FROM   SealedCase) as x
     ON   x.SerialNo = c.SerialNo
   JOIN   InventoryConflictObjectType o
     ON   o.Id = c.Id
   WHERE  x.TypeId = o.TypeId
   -- Cycle through the resolved accounts
   SELECT @i = min(RowNo) FROM @tbl2
   WHILE 1 = 1 BEGIN
      SELECT @id = Id
      FROM   @tbl2
      WHERE  RowNo = @i
      IF @@rowcount = 0 BREAK
      EXECUTE @returnValue = inventoryConflict$resolveObjectType @id, 1
      IF @returnValue != 0 BEGIN
         ROLLBACK TRANSACTION @tranName
         COMMIT TRANSACTION
         RETURN -100
      END
      SET @i = @i + 1
   END
   -- Clear the table
   DELETE @tbl2
   -- Resolve unknown serial discrepancies
   INSERT @tbl2 (Id)
   SELECT c.Id
   FROM   InventoryConflict c
   JOIN  (SELECT SerialNo
          FROM   Medium
          UNION
          SELECT SerialNo
          FROM   SealedCase
          UNION
          SELECT SerialNo
          FROM   SendListCase) as x
     ON   x.SerialNo = c.SerialNo
   JOIN   InventoryConflictUnknownSerial s
     ON   s.Id = c.Id
   -- Cycle through the resolved accounts
   SELECT @i = min(RowNo) FROM @tbl2
   WHILE 1 = 1 BEGIN
      SELECT @id = Id
      FROM   @tbl2
      WHERE  RowNo = @i
      IF @@rowcount = 0 BREAK
      EXECUTE @returnValue = inventoryConflict$resolveUnknownSerial @id, 1
      IF @returnValue != 0 BEGIN
         ROLLBACK TRANSACTION @tranName
         COMMIT TRANSACTION
         RETURN -100
      END
      SET @i = @i + 1
   END
END

-----------------------------------------------
-- Insert audit records, one for each account
-----------------------------------------------
DELETE @tbl1   -- Use tbl1, use SerialNo to hold account name
INSERT @tbl1 (SerialNo, Location)
SELECT a.AccountName, i.Location
FROM   Inventory i
JOIN   Account a
  ON   a.AccountId = i.AccountId

SELECT @i = min(RowNo) FROM @tbl1

WHILE 1 = 1 BEGIN
   SELECT @serialNo = SerialNo, @loc = Location
   FROM   @tbl1
   WHERE  RowNo = @i
   IF @@rowcount = 0 BREAK
   IF @loc = 1 BEGIN
      INSERT XInventory (Object, Action, Detail, Login)
      VALUES (@serialNo, 12, ''Enterprise inventory for account '' + @serialNo + '' compared against database'', dbo.string$getSpidLogin())
   END
   ELSE BEGIN
      INSERT XInventory (Object, Action, Detail, Login)
      VALUES (@serialNo, 12, ''Vault inventory for account '' + @serialNo + '' compared against database'', dbo.string$getSpidLogin())
   END
   SET @error = @@error
   IF @error != 0 BEGIN
      ROLLBACK TRANSACTION @tranName
      COMMIT TRANSACTION
      SET @msg = ''Error encountered while inserting inventory audit record.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
      EXECUTE error$raise @msg, @error
      RETURN -100
   END
   SET @i = @i + 1
END

-- Commit the transaction
COMMIT TRANSACTION

-- Select the number of conflicts in the database
SELECT count(*) FROM InventoryConflict

-- Return       
RETURN 0
END
'
)

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'inventoryConflict$getById')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.inventoryConflict$getById
(
   @id as int
)
WITH ENCRYPTION
AS
BEGIN

SET NOCOUNT ON

SELECT c.Id,
       c.SerialNo,
       c.RecordedDate,
       x.Details,
       x.ConflictType
FROM   InventoryConflict c
JOIN  (SELECT Id,
              case Type
              when 1 then ''Enterprise claims residence of medium''
              when 2 then ''Enterprise denies residence of medium''
              when 3 then ''Vault claims residence of medium''
              when 4 then ''Vault denies residence of medium'' end as ''Details'',
              1 as ''ConflictType''
       FROM   InventoryConflictLocation
       UNION
       SELECT o.Id,
              ''Vault asserts serial number should be of type '' + t.TypeName as ''Details'',
              2 as ''ConflictType''
       FROM   InventoryConflictObjectType o
       JOIN   MediumType t
         ON   t.TypeId = o.TypeId
       UNION
       SELECT Id,
              case Type
              when 0 then ''Vault claims residence of unrecognized '' + case Container when 0 then ''medium'' else ''sealed case'' end
              when 1 then ''Enterprise claims residence of unrecognized medium'' end as ''Details'',
              3 as ''ConflictType''
       FROM   InventoryConflictUnknownSerial
       UNION
       SELECT i.Id,
              case i.Type
              when 0 then ''Enterprise asserts that medium should belong to account '' + a.AccountName
              when 1 then ''Vault asserts that medium should belong to account '' + a.AccountName end as ''Details'',
              4 as ''ConflictType''
       FROM   InventoryConflictAccount i
       JOIN   Account a
         ON   a.AccountId = i.AccountId) as x
  ON   x.Id = c.Id
WHERE  x.Id = @id

END
'
)

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'inventoryConflict$getTable')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.inventoryConflict$getTable
WITH ENCRYPTION
AS
BEGIN

SET NOCOUNT ON

SELECT c.Id,
       c.SerialNo,
       c.RecordedDate,
       x.Details,
       x.ConflictType
FROM   InventoryConflict c
JOIN  (SELECT Id,
              case Type
              when 1 then ''Enterprise claims residence of medium''
              when 2 then ''Enterprise denies residence of medium''
              when 3 then ''Vault claims residence of medium''
              when 4 then ''Vault denies residence of medium'' end as ''Details'',
              1 as ''ConflictType''
       FROM   InventoryConflictLocation
       UNION
       SELECT o.Id,
              ''Vault asserts serial number should be of type '' + t.TypeName as ''Details'',
              2 as ''ConflictType''
       FROM   InventoryConflictObjectType o
       JOIN   MediumType t
         ON   t.TypeId = o.TypeId
       UNION
       SELECT Id,
              case Type
              when 0 then ''Vault claims residence of unrecognized '' + case Container when 0 then ''medium'' else ''sealed case'' end
              when 1 then ''Enterprise claims residence of unrecognized medium'' end as ''Details'',
              3 as ''ConflictType''
       FROM   InventoryConflictUnknownSerial
       UNION
       SELECT i.Id,
              case i.Type
              when 0 then ''Vault asserts that medium should belong to account '' + a.AccountName
              when 1 then ''Enterprise asserts that medium should belong to account '' + a.AccountName end as ''Details'',
              4 as ''ConflictType''
       FROM   InventoryConflictAccount i
       JOIN   Account a
         ON   a.AccountId = i.AccountId) as x
  ON   x.Id = c.Id
ORDER BY x.ConflictType ASC, c.RecordedDate ASC, c.SerialNo ASC

END
'
)

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'inventoryConflict$getPage')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.inventoryConflict$getPage
(
   @pageNo int,
   @pageSize int,
   @filter nvarchar(4000),
   @sort tinyint
)
WITH ENCRYPTION
AS
BEGIN
DECLARE @msg as nvarchar(255)        -- used to preformat error message
DECLARE @msgTag as nvarchar(255)     -- used to hold first part of error message header
DECLARE @tables nvarchar(4000)
DECLARE @fields1 nvarchar(4000)      -- innermost fields
DECLARE @fields2 nvarchar(4000)      -- outermost fields
DECLARE @sql nvarchar(4000)
DECLARE @var nvarchar(4000)
DECLARE @order1 nvarchar(4000)	-- innermost order clause
DECLARE @order2 nvarchar(4000)   -- middle order clause
DECLARE @order3 nvarchar(4000)   -- outermost order clause
DECLARE @where nvarchar(4000)
DECLARE @topSize int
DECLARE @display int
DECLARE @count int
DECLARE @error int
DECLARE @x1 nvarchar(1000)   -- Serial number
DECLARE @x2 nvarchar(1000)   -- Recorded date
DECLARE @x3 nvarchar(1000)   -- Type
DECLARE @s nvarchar(4000)
DECLARE @p int

SET NOCOUNT ON

-- Set the message tag
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=P''

-- Verify validity of @pageNo
IF @pageNo < 1 SET @pageNo = 1

-- Initialize variable string
SELECT @var = ''@x1$ nvarchar(1000), @x2$ nvarchar(1000), @x3$ nvarchar(1000)''
SELECT @p = -1

-- Set the order clauses
IF @sort = 1 BEGIN
   SET @order1 = '' ORDER BY i.SerialNo asc, x.ConflictType asc, i.RecordedDate asc''
   SET @order2 = '' ORDER BY SerialNo desc, ConflictType desc, RecordedDate desc''
   SET @order3 = '' ORDER BY SerialNo asc, ConflictType asc, RecordedDate asc''
END
ELSE IF @sort = 2 BEGIN
   SET @order1 = '' ORDER BY i.RecordedDate asc, x.ConflictType asc, i.SerialNo asc''
   SET @order2 = '' ORDER BY RecordedDate desc, ConflictType desc, SerialNo desc''
   SET @order3 = '' ORDER BY RecordedDate asc, ConflictType asc, SerialNo asc''
END
ELSE IF @sort = 3 BEGIN
   SET @order1 = '' ORDER BY x.ConflictType asc, i.RecordedDate asc, i.SerialNo asc''
   SET @order2 = '' ORDER BY ConflictType desc, RecordedDate desc, SerialNo desc''
   SET @order3 = '' ORDER BY ConflictType asc, RecordedDate asc, SerialNo asc''
END
ELSE BEGIN
   SET @msg = ''Invalid sort order.'' + @msgTag + ''>''
   RAISERROR(@msg,16,1)
   RETURN -100
END

-- Construct the where clause
SET @where = '' WHERE 1 = 1 ''
SET @filter = ltrim(rtrim(coalesce(@filter,'''')))
WHILE @p != 0 AND len(@filter) != 0 BEGIN
   SET @p = charindex('' AND '', @filter)
   -- Get the string fragment
   IF @p = 0
      SET @s = ltrim(rtrim(@filter))
   ELSE
      SET @s = ltrim(rtrim(substring(@filter, 1, @p)))
   -- Trim the filter
   SET @filter = substring(@filter, @p + 5, 4000)
   -- Which filter is it?
   IF charindex(''SerialNo ='', @s) = 1 BEGIN
      SET @where = @where + '' AND (i.'' + left(@s, charindex(''='',@s) + 1) + '' @x1$)''
      SET @x1 = replace(ltrim(substring(@s, charindex(''='',@s) + 1, 4000)), '''''''', '''')
   END
   ELSE IF charindex(''RecordedDate'', @s) = 1 BEGIN
      SET @where = @where + '' AND ('' + replace(left(@s, charindex(''='',@s) + 1),''RecordedDate'',''convert(nvarchar(10),i.RecordedDate,120)'') + '' @x2$)''
      SET @x2 = replace(ltrim(substring(@s, charindex(''='',@s) + 1, 4000)), '''''''', '''')
   END
   ELSE IF charindex(''ConflictType ='', @s) = 1 BEGIN
      SET @where = @where + '' AND (x.'' + left(@s, charindex(''='',@s) + 1) + '' @x3$)''
      SET @x3 = replace(ltrim(substring(@s, charindex(''='',@s) + 1, 4000)), '''''''', '''')
   END
   ELSE BEGIN
      SET @msg = ''Error occurred while selecting page of inventory conflicts.  Invalid filter supplied.'' + @msgTag + ''>''
      EXECUTE error$raise @msg
      RETURN -100
   END
END

-- Construct the fields string
SET @fields2 = ''Id, RecordedDate, SerialNo, Details, ConflictType''
SET @fields1 = ''i.Id, i.RecordedDate, i.SerialNo, x.Details, x.ConflictType''

-- Construct the tables string
SET @tables = ''InventoryConflict i JOIN (SELECT Id, case Type when 1 then ''''Enterprise claims residence of medium'''' when 2 then ''''Enterprise denies residence of medium'''' when 3 then ''''Vault claims residence of medium'''' when 4 then ''''Vault denies residence of medium'''' end as ''''Details'''', 1 as ''''ConflictType'''' FROM InventoryConflictLocation UNION SELECT o.Id, ''''Vault asserts serial number should be of type '''' + t.TypeName as ''''Details'''', 2 as ''''ConflictType'''' FROM InventoryConflictObjectType o JOIN MediumType t ON t.TypeId = o.TypeId UNION SELECT Id, case Type when 0 then ''''Vault claims residence of unrecognized '''' + case Container when 0 then ''''medium'''' else ''''sealed case'''' end when 1 then ''''Enterprise claims residence of unrecognized medium'''' end as ''''Details'''', 3 as ''''ConflictType'''' FROM InventoryConflictUnknownSerial UNION SELECT c.Id, case c.Type when 0 then ''''Vault asserts that medium should belong to account '''' + a.AccountName when 1 then ''''Enterprise asserts that medium should belong to account '''' + a.AccountName end as ''''Details'''', 4 as ''''ConflictType'''' FROM InventoryConflictAccount c JOIN Account a ON a.AccountId = c.AccountId) as x ON x.Id = i.Id''

-- Select the total number of records that fit the criteria
CREATE TABLE #tblTemp (xyz int)
SET @sql = ''INSERT #tblTemp SELECT count(*) FROM '' + @tables + @where
EXECUTE sp_executesql @sql, @var, @x1$ = @x1, @x2$ = @x2, @x3$ = @x3
SELECT @count = xyz FROM #tblTemp
DROP TABLE #tblTemp

-- If the page number is 1, then we can execute without the subqueries
-- thus increasing efficiency.
IF @pageNo = 1 BEGIN
   SET @sql = ''SELECT TOP '' + cast(@pageSize as nvarchar(50)) + '' '' + @fields1 + '' FROM '' + @tables + @where + @order1
END
ELSE BEGIN
   -- Adjust the page size if necessary
   SET @display = @count - ((@pageNo - 1) * @pageSize)
   SET @topSize = @pageSize
   IF @display <= 0
      SET @where = @where + '' AND 1 != 1''
   ELSE IF @pageSize > @display
      SET @topSize = @display
   -- Select the data
   SET @sql = ''SELECT '' + @fields2 + '' FROM ''
   SET @sql = @sql + ''(''
   SET @sql = @sql + ''SELECT TOP '' + cast(@topSize as nvarchar(50)) + '' '' + @fields2 + '' FROM ''
   SET @sql = @sql + ''   (''
   SET @sql = @sql + ''   SELECT TOP '' + cast((@pageSize * @pageNo) as nvarchar(50)) + '' '' + @fields1 + '' FROM '' + @tables + @where + @order1
   SET @sql = @sql + ''   ) as x1 ''
   SET @sql = @sql + @order2 + '') as y '' + @order3
END

-- Execute the sql
EXECUTE sp_executesql @sql, @var, @x1$ = @x1, @x2$ = @x2, @x3$ = @x3
SET @error = @@error
IF @error != 0 BEGIN
   SET @msg = ''Error occurred while selecting page of inventory conflicts.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
   EXECUTE error$raise @msg, @error
   RETURN -100
END

-- Select the total number of records that fit the criteria
SELECT @count AS ''RecordCount''

-- Return
RETURN 0
END
'
)

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'inventoryConflict$ignore')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.inventoryConflict$ignore
(
   @id int
)
WITH ENCRYPTION
AS
BEGIN
DECLARE @msg as nvarchar(255)        -- used to preformat error 
DECLARE @msgTag as nvarchar(255)     -- used to hold first part of error message header
DECLARE @tranName as nvarchar(255)   -- used to hold name of savepoint
DECLARE @returnValue int
DECLARE @detail as nvarchar(4000)
DECLARE @serial as nvarchar(32)
DECLARE @error as int

SET NOCOUNT ON

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=P''
SET @tranName = object_name(@@procid) + CAST(@@nestlevel as nvarchar(2))

-- Begin transaction
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

-- Call the correct procedure
IF EXISTS (SELECT 1 FROM InventoryConflictAccount WHERE Id = @id)
   EXECUTE @returnValue = inventoryConflict$resolveAccount @id, 4
ELSE IF EXISTS (SELECT 1 FROM InventoryConflictLocation WHERE Id = @id)
   EXECUTE @returnValue = inventoryConflict$resolveLocation @id, 5
ELSE IF EXISTS (SELECT 1 FROM InventoryConflictObjectType WHERE Id = @id)
   EXECUTE @returnValue = inventoryConflict$resolveObjectType @id, 4
ELSE IF EXISTS (SELECT 1 FROM InventoryConflictUnknownSerial WHERE Id = @id)
   EXECUTE @returnValue = inventoryConflict$resolveUnknownSerial @id, 3

-- Evaluate result
IF @returnValue != 0 BEGIN
   ROLLBACK TRANSACTION @tranName
   COMMIT TRANSACTION
   RETURN -100
END

-- Commit and return
COMMIT TRANSACTION
RETURN 0
END
'
)

-------------------------------------------------------------------------------
--
-- Recreate disaster code list item triggers
--
-------------------------------------------------------------------------------
-- Recreate delete trigger
IF EXISTS(SELECT 1 FROM sysobjects WHERE name = 'disasterCodeListItem$afterDelete' AND objectproperty(id, 'ExecIsDeleteTrigger' ) = 1) 
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'TRIGGER disasterCodeListItem$afterDelete
ON     DisasterCodeListItem
WITH ENCRYPTION
AFTER  DELETE
AS
BEGIN
DECLARE @msg nvarchar(255)         -- used to preformat error message
DECLARE @msgTag nvarchar(255)      -- used to hold first part of error message header
DECLARE @msgUpdate nvarchar(4000)  -- used to hold the updated fields
DECLARE @tranName nvarchar(255)    -- used to hold name of savepoint
DECLARE @listName nchar(10)
DECLARE @lastList int
DECLARE @lastItem int
DECLARE @serialNo nvarchar(32)
DECLARE @detail nvarchar(1000)
DECLARE @rowVersion rowversion
DECLARE @returnValue int
DECLARE @rowCount int
DECLARE @error int

SET @rowCount = @@rowcount
IF @rowCount = 0 RETURN

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=T''
SET @tranName = object_name(@@procid) + CAST(trigger_nestlevel(@@procid) as nvarchar(2))

-- Begin transaction
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

-- Get the caller login from the spidLogin table
IF len(dbo.string$GetSpidLogin()) = 0 BEGIN
   SET @msg = ''Login not found for auditing purposes.'' + @msgTag + ''>''
   EXECUTE error$raise @msg, 0, @tranName
   RETURN
END

-- For each list, if there are no active items left, delete list.  Else
-- set the status of list.
SET @lastList = 0
WHILE 1 = 1 BEGIN
   SELECT TOP 1 @lastList = d.ListId,
          @rowVersion = dl.RowVersion
   FROM   Deleted d
   JOIN   DisasterCodeList dl
     ON   dl.ListId = d.ListId
   WHERE  d.ListId > @lastList
   ORDER BY d.ListId ASC
   IF @@rowCount = 0
      BREAK
   ELSE BEGIN
      IF EXISTS(SELECT 1 FROM DisasterCodeListItem WHERE Status != 1 AND ListId = @lastList) BEGIN -- power(4,x)
         EXECUTE @returnValue = disasterCodeList$setStatus @lastlist, @rowVersion
      END
      ELSE BEGIN
         EXECUTE @returnValue = disasterCodeList$del @lastList, @rowVersion
      END
      IF @returnValue != 0 BEGIN
         ROLLBACK TRANSACTION @tranName
         COMMIT TRANSACTION
         RETURN
      END
   END
END

-- Commit transaction
COMMIT TRANSACTION
END
'
)

-- Recreate insert trigger
IF EXISTS(SELECT 1 FROM sysobjects WHERE name = 'disasterCodeListItem$afterInsert' AND objectproperty(id, 'ExecIsInsertTrigger' ) = 1) 
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'TRIGGER disasterCodeListItem$afterInsert
ON     DisasterCodeListItem
WITH ENCRYPTION
AFTER  INSERT
AS
BEGIN
DECLARE @msg nvarchar(255)         -- used to preformat error message
DECLARE @msgTag nvarchar(255)      -- used to hold first part of error message header
DECLARE @tranName nvarchar(255)    
DECLARE @rowCount int

SET @rowCount = @@rowcount
IF @rowCount = 0 RETURN

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=T''
SET @tranName = object_name(@@procid) + CAST(trigger_nestlevel(@@procid) as nvarchar(2))

-- Begin transaction
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

-- No batch insert
IF @rowCount > 1 BEGIN
   SET @msg = ''Batch insert of disaster code list items not allowed.'' + @msgTag + ''>''
   EXECUTE error$raise @msg, 0, @tranName
   RETURN
END

-- Make sure that the list is not a composite
IF EXISTS(SELECT 1 FROM DisasterCodeList WHERE AccountId IS NULL AND ListId = (SELECT ListId FROM Inserted)) BEGIN
   SET @msg = ''Items may not be placed directly on a composite disaster code list.'' + @msgTag + ''>''
   EXECUTE error$raise @msg, 0, @tranName
   RETURN
END

-- Commit transaction
COMMIT TRANSACTION
END
'
)

-- Recreate update trigger
IF EXISTS(SELECT 1 FROM sysobjects WHERE name = 'disasterCodeListItem$afterUpdate' AND objectproperty(id, 'ExecIsUpdateTrigger' ) = 1) 
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'TRIGGER disasterCodeListItem$afterUpdate
ON     DisasterCodeListItem
WITH ENCRYPTION
AFTER  UPDATE
AS
BEGIN
DECLARE @msg nvarchar(255)         -- used to preformat error message
DECLARE @msgTag nvarchar(255)      -- used to hold first part of error message header
DECLARE @msgUpdate nvarchar(4000)  -- used to hold the updated fields
DECLARE @tranName nvarchar(255)    -- used to hold name of savepoint
DECLARE @listName nchar(10)
DECLARE @lastList int
DECLARE @serialNo nvarchar(32)
DECLARE @rowVersion rowversion
DECLARE @returnDate datetime
DECLARE @caseSerial bit
DECLARE @returnValue int
DECLARE @rowCount int
DECLARE @status int
DECLARE @error int

SET @rowCount = @@rowcount
IF @rowCount = 0 RETURN

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=T''
SET @tranName = object_name(@@procid) + CAST(trigger_nestlevel(@@procid) as nvarchar(2))

-- Begin the transaction
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

-- Get the caller login from the spidLogin table
IF len(dbo.string$GetSpidLogin()) = 0 BEGIN
   SET @msg = ''Login not found for auditing purposes.'' + @msgTag + ''>''
   EXECUTE error$raise @msg, 0, @tranName
   RETURN
END

-- Audit is only necessary when there is one item being updated.  Multiple
-- items being updated means that an action was performed on the list as
-- a whole; the list audit record will suffice.
IF @rowCount = 1 BEGIN
   -- List name
   SELECT @listName = ListName
   FROM   DisasterCodeList
   WHERE  ListId = (SELECT ListId FROM Inserted)
   IF @@rowCount > 0 BEGIN
      -- Status updated
      SELECT @status = i.Status
      FROM   Inserted i
      JOIN   Deleted d
        ON   d.ItemId = i.ItemId
      WHERE  i.Status != d.Status
      -- Serial number
      SELECT @serialNo = m.SerialNo,
             @caseSerial = 0
      FROM   Inserted i
      JOIN   DisasterCodeListItemMedium dlim
        ON   dlim.ItemId = i.ItemId
      JOIN   Medium m
        ON   m.MediumId = dlim.MediumId
      IF @@rowCount = 0 BEGIN
         SELECT @serialNo = sc.SerialNo,
                @caseSerial = 1
         FROM   Inserted i
         JOIN   DisasterCodeListItemCase dlic
           ON   dlic.ItemId = i.ItemId
         JOIN   SealedCase sc
           ON   sc.CaseId = dlic.CaseId
      END
      IF @status = 1 BEGIN -- power(4,x)
         IF @caseSerial = 0
            SET @msgUpdate = ''Medium '' + @serialNo + '' removed from list''
         ELSE IF @caseSerial = 1
            SET @msgUpdate = ''Case '' + @serialNo + '' removed from list''
      END
   END
   -- Insert audit record
   IF len(coalesce(@msgUpdate,'''')) > 0 BEGIN
      INSERT XDisasterCodeListItem
      (
         Object, 
         Action, 
         Detail, 
         Login
      )
      VALUES
      (
         @listName, 
         5, 
         @msgUpdate, 
         dbo.string$GetSpidLogin()
      )
      SET @error = @@error
      IF @error != 0 BEGIN
         SET @msg = ''Error encountered while inserting disaster recovery list item audit record.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
         EXECUTE error$raise @msg, @error, @tranName
         RETURN
      END
   END
END

-- For each list in the update where an item was updated to a status other 
-- than removed, make sure that the discrete list status is equal to 
-- the lowest status among its non-removed items.
SET @lastList = 0
WHILE 1 = 1 BEGIN
   SELECT TOP 1 @lastList = i.ListId,
          @rowVersion = dl.RowVersion
   FROM   Inserted i
   JOIN   Deleted d
     ON   d.ItemId = i.ItemId
   JOIN   DisasterCodeList dl
     ON   dl.ListId = i.ListId
   WHERE  i.Status != 1 AND  -- power(4,x)
          d.Status != i.Status AND
          i.ListId > @lastList
   ORDER BY i.ListId ASC
   IF @@rowCount = 0
      BREAK
   ELSE BEGIN
      EXECUTE @returnValue = disasterCodeList$setStatus @lastList, @rowVersion
      IF @returnValue != 0 BEGIN
         ROLLBACK TRANSACTION @tranName
         COMMIT TRANSACTION
         RETURN
      END
   END
END

-- For each list in the update where an item was updated to removed status, 
-- delete the list if there are no more items on the list.  Otherwise update
-- the status of the list to change the rowversion.
SET @lastList = 0
WHILE 1 = 1 BEGIN
   SELECT TOP 1 @lastList = i.ListId,
          @rowVersion = dl.RowVersion
   FROM   Inserted i
   JOIN   Deleted d
     ON   d.ItemId = i.ItemId
   JOIN   DisasterCodeList dl
     ON   dl.ListId = i.ListId
   WHERE  i.Status = 1 AND  -- power(4,x)
          d.Status != 1 AND -- power(4,x)
          i.ListId > @lastList
   ORDER BY i.ListId ASC
   IF @@rowCount = 0
      BREAK
   ELSE BEGIN
      IF EXISTS(SELECT 1 FROM DisasterCodeListItem WHERE ListId = @lastList AND Status != 1) BEGIN -- power(4,x)
         EXECUTE @returnValue = disasterCodeList$setStatus @lastList, @rowVersion
      END
      ELSE BEGIN
         EXECUTE @returnValue = disasterCodeList$del @lastList, @rowVersion
      END
      IF @returnValue != 0 BEGIN
         ROLLBACK TRANSACTION @tranName
         COMMIT TRANSACTION
         RETURN
      END
   END
END

-- Commit
COMMIT TRANSACTION
END
'
)

-------------------------------------------------------------------------------
--
-- New disaster code procedures
--
-------------------------------------------------------------------------------
IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'disasterCodeList$clear')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.disasterCodeList$clear
(
   @listId int,
   @rowVersion rowVersion
)
WITH ENCRYPTION
AS
BEGIN
DECLARE @msg as nvarchar(255)        -- used to preformat error message
DECLARE @msgTag as nvarchar(255)     -- used to hold first part of error message header
DECLARE @tranName as nvarchar(255)   -- used to hold name of savepoint
DECLARE @listName nchar(10)
DECLARE @accountId int
DECLARE @mediumId int
DECLARE @lastList int
DECLARE @status int
DECLARE @error int
DECLARE @codeId int
DECLARE @code nvarchar(32)
DECLARE @returnValue int
DECLARE @tbl1 table (RowNo int identity(1,1), MediumId int, Code nvarchar(32))
DECLARE @rowNo int

SET NOCOUNT ON

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=P''
SET @tranName = object_name(@@procid) + CAST(@@nestlevel as nvarchar(2))

-- Get the list
SELECT @listName = ListName,
       @accountId = AccountId,
       @status = Status
FROM   DisasterCodeList
WHERE  ListId = @listId
IF @@rowcount = 0 BEGIN
   SET @msg = ''List not found.'' + @msgTag + ''>''
   RAISERROR(@msg,16,1)
   RETURN -100
END
ELSE IF NOT EXISTS (SELECT 1 FROM DisasterCodeList WHERE ListId = @listId AND RowVersion = @rowVersion) BEGIN
   SET @msg = ''Disaster recovery list has been modified since retrieval.'' + @msgTag + ''>''
   RAISERROR(@msg,16,1)
   RETURN -100
END

-- If list has been cleared, return
IF @status = 512 RETURN 0

-- Make sure it is eligible to be cleared.
IF dbo.bit$statusEligible(4,@status,512) = 0 BEGIN
   SET @msg = ''List '' + @listName + '' is not yet eligible to be processed.'' + @msgTag + ''>''
   RAISERROR(@msg,16,1)
   RETURN -100
END

-- Begin transaction
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

-- If composite, clear all the discretes.  Otherwise clear the list.
IF @accountId IS NULL BEGIN
   SET @lastList = 0
   WHILE 1 = 1 BEGIN
      SELECT TOP 1 @lastList = ListId,
             @rowVersion = RowVersion
      FROM   DisasterCodeList
      WHERE  ListId > @lastList AND
             CompositeId = @listId
      ORDER BY ListId ASC
      IF @@rowCount = 0 BREAK
      EXECUTE @returnValue = disasterCodeList$clear @lastList, @rowVersion
      IF @returnValue != 0 BEGIN
         ROLLBACK TRANSACTION @tranName
         COMMIT TRANSACTION
         RETURN -100
      END
   END
END
ELSE BEGIN
   -- Delete all the disaster codes for media in this account
   DELETE DisasterCodeMedium
   WHERE  MediumId in (SELECT MediumId FROM Medium WHERE AccountId = @accountId)
   SET @error = @@error
   IF @error != 0 BEGIN
      ROLLBACK TRANSACTION @tranName
      COMMIT TRANSACTION
      SET @msg = ''Error encountered while resetting disaster recovery codes for account.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
      EXECUTE error$raise @msg, @error
      RETURN -100
   END
   -- Get the media from the list
   INSERT @tbl1 (MediumId, Code)
   SELECT MediumId, Code
   FROM   DisasterCodeListItem
   WHERE  Status != 1 AND ListId = @listId
   ORDER BY MediumId Asc
   -- Run through the media   
   SET @rowNo = 1
   WHILE 1 = 1 BEGIN
      SELECT @mediumId = MediumId, @code = Code
      FROM   @tbl1
      WHERE  RowNo = @rowNo
      IF @@rowcount = 0 BREAK
      -- If the code does not already exist, add it
      SELECT @codeId = CodeId
      FROM   DisasterCode 
      WHERE  Code = @code
      IF @@rowcount = 0 BEGIN
         EXECUTE @returnValue = disasterCode$ins @code, '''', @codeId out
         IF @returnValue != 0 BEGIN
            ROLLBACK TRANSACTION @tranName
            COMMIT TRANSACTION
            RETURN -100
         END
      END
      -- Attach the code to the medium
      INSERT DisasterCodeMedium (CodeId, MediumId)
      VALUES (@codeId, @mediumId)
      SET @error = @@error
      IF @error != 0 BEGIN
         ROLLBACK TRANSACTION @tranName
         COMMIT TRANSACTION
         SET @msg = ''Error encountered while attaching disaster recovery code to medium.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
         EXECUTE error$raise @msg, @error
         RETURN -100
      END
      -- Increment row number
      SET @rowNo = @rowNo + 1
   END
   -- Set the status of all unremoved list items to cleared
   UPDATE DisasterCodeListItem
   SET    Status = 512
   WHERE  Status != 1 AND ListId = @listId
   SET @error = @@error
   IF @error != 0 BEGIN
      ROLLBACK TRANSACTION @tranName
      COMMIT TRANSACTION
      SET @msg = ''Error occurred while upgrading disaster recovery list item status to processed.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
      EXECUTE error$raise @msg, @error
      RETURN -100
   END
END     

-- Commit the transaction
COMMIT TRANSACTION
RETURN 0
END
'
)

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'disasterCodeList$getItems')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.disasterCodeList$getItems
(
   @listId int
)
WITH ENCRYPTION
AS
BEGIN

SET NOCOUNT ON

SELECT dli.ItemId,
       dli.Status,
       m.SerialNo,
       a.AccountName,
       dli.Code,
       dli.Notes,
       isnull(x.SerialNo,'''') as ''CaseName'',
       dli.RowVersion
FROM   DisasterCodeList dl
JOIN   DisasterCodeListItem dli
  ON   dli.ListId = dl.ListId
JOIN   Medium m
  ON   m.MediumId = dli.MediumId
JOIN   Account a
  ON   a.AccountId = m.AccountId
LEFT   JOIN 
       (
       SELECT s.SerialNo, c.MediumId
       FROM   SealedCase s
       JOIN   MediumSealedCase c
         ON   c.CaseId = s.CaseId
       ) as x
  ON   x.MediumId = m.MediumId
WHERE  dl.ListId = @listId OR dl.CompositeId = @listId
ORDER  BY m.SerialNo ASC

END
'
)

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'disasterCodeListItem$add')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.disasterCodeListItem$add
(
   @serialNo nvarchar(32),      -- medium serial number
   @code nvarchar(32),          -- disaster code
   @notes nvarchar(1000),       -- any notes to attach to the medium
   @listId int                  -- list to which item should be added
)
WITH ENCRYPTION
AS
BEGIN
DECLARE @msg as nvarchar(255)      -- used to preformat error message
DECLARE @msgTag as nvarchar(255)    -- used to hold first part of error message header
DECLARE @tranName as nvarchar(255)   -- used to hold name of savepoint
DECLARE @accountId as int
DECLARE @mediumId as int
DECLARE @priorId as int
DECLARE @priorRv as rowversion
DECLARE @returnValue as int
DECLARE @error as int
DECLARE @status as int
DECLARE @listName as nchar(10)
DECLARE @location as bit
DECLARE @tbl1 table (ListId int, AccountId int, Status int)
DECLARE @tbl2 table (RowNo int identity(1,1), SerialNo nvarchar(32))
DECLARE @i int

SET NOCOUNT ON

-- Tweak parameters
SET @code = coalesce(ltrim(rtrim(@code)), '''')
SET @notes = coalesce(ltrim(rtrim(@notes)),'''')
SET @serialNo = ltrim(rtrim(@serialNo))

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=P''
SET @tranName = object_name(@@procid) + CAST(@@nestlevel as nvarchar(2))

-- Get all relevant list (list itself or, if composite, all discretes)
INSERT @tbl1 (ListId, AccountId, Status)
SELECT ListId, AccountId, Status
FROM   DisasterCodeList
WHERE  ListId = @listId OR CompositeId = @listId

-- Verify that the list exists
IF @@rowcount = 0 BEGIN
   SET @msg = ''Disaster code list not found.'' + @msgTag + ''>''
   RAISERROR(@msg,16,1)
   RETURN -100
END

-- Begin transaction
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

-- Get the medium.  If there is no medium, check to see if it is a case.  If it is a
-- case, add all the media in the case to the list.
SELECT @mediumId = m.MediumId,
       @accountId = m.AccountId,
       @location = m.Location
FROM   Medium m
WHERE  m.SerialNo = @serialNo
IF @@rowcount != 0 BEGIN
   -- Location check
   IF @location = 1 BEGIN
      ROLLBACK TRANSACTION @tranName
      COMMIT TRANSACTION
      SET @msg = ''Medium '''''' + @serialNo + '''''' resides at the enterprise.'' + @msgTag + ''>''
      RAISERROR(@msg,16,1)
      RETURN -100
   END
   -- Make sure medium is not active beyond submitted on another list
   SELECT @listName = dl.ListName 
   FROM   DisasterCodeList dl
   JOIN   DisasterCodeListItem dli
     ON   dli.ListId = dl.ListId
   WHERE  dli.MediumId = @mediumId AND dli.Status = 4
   IF @@rowcount != 0 BEGIN
      ROLLBACK TRANSACTION @tranName
      COMMIT TRANSACTION
      SET @msg = ''Medium '' + @serialNo + '' cannot be added because it has already been transmitted on list '' + @listName + ''.'' + @msgTag + ''>''
      RAISERROR(@msg,16,1)
      RETURN -100
   END
   -- If medium already exists as submitted on one of the lists in table, return zero
   IF EXISTS 
      (
      SELECT 1 
      FROM   DisasterCodeListItem dli 
      JOIN   @tbl1 t
        ON   t.ListId = dli.ListId 
      WHERE  dli.Status = 2 AND dli.MediumId = @mediumId
      ) 
   BEGIN
      COMMIT TRANSACTION
      RETURN 0
   END
END
ELSE BEGIN
   INSERT @tbl2 (SerialNo)
   SELECT m.SerialNo
   FROM   Medium m
   JOIN   MediumSealedCase mc
     ON   mc.Mediumid = m.MediumId
   JOIN   SealedCase c
     ON   c.CaseId = mc.CaseId
   WHERE  c.SerialNo = @serialNo
   IF @@rowcount != 0 BEGIN
      SET @i = 1
      WHILE 1 = 1 BEGIN
         SELECT @serialNo = SerialNo
         FROM   @tbl2      
         WHERE  RowNo = @i
         IF @@rowcount = 0 BREAK
         EXECUTE @returnValue = disasterCodeListItem$add @serialNo, @code, @notes, @listId
         IF @returnValue = -100 BEGIN
            ROLLBACK TRANSACTION @tranName
            COMMIT TRANSACTION
            RETURN -100
         END
         -- Next iteration
         SET @i = @i + 1
      END
   END
   -- Commit and return
   COMMIT TRANSACTION
   RETURN 0
END

-- If no medium, add it.  Otherwise, if it resides as submitted on another list as submitted, remove it.
IF @mediumId IS NULL BEGIN
   EXECUTE @returnValue = medium$addDynamic @serialNo, 0, @mediumId OUTPUT
   IF @returnValue != 0 BEGIN
      ROLLBACK TRANSACTION @tranName
      COMMIT TRANSACTION
      RETURN -100
   END
   -- Get the account id
   SELECT @accountId = AccountId
   FROM   Medium
   WHERE  MediumId = @mediumId
END
ELSE BEGIN
   -- If the tape resides on another list remove it.  We only have to check 
   -- for status submitted, since any other status would mean that the medium 
   -- is on an inactive (cleared) list or removed.
   SELECT @priorId = dli.ItemId,
          @priorRv = dli.RowVersion
   FROM   DisasterCodeListItem dli
   WHERE  dli.Status = 2 AND dli.MediumId = @mediumId
   IF @@rowcount != 0 BEGIN
      EXECUTE @returnValue = disasterCodeListItem$remove @priorId, @priorRv
      IF @returnValue != 0 BEGIN
         ROLLBACK TRANSACTION @tranName
         COMMIT TRANSACTION
         RETURN -100
      END
   END
END

-- Get the list that the tape is to be placed on
SELECT TOP 1 @listId = ListId 
FROM   @tbl1 
WHERE  AccountId = @accountId
IF @@rowcount = 0 BEGIN
   SET @msg = ''Medium '' + @serialNo + '' does not belong to the account under which the list was created.'' + @msgTag + ''>''
   ROLLBACK TRANSACTION @tranName
   COMMIT TRANSACTION
   RAISERROR(@msg,16,1)
   RETURN -100
END

-- If the tape exists on a list within the table (i.e. was removed from that list) then update; otherwise insert
IF EXISTS (SELECT 1 FROM DisasterCodeListItem dli WHERE dli.MediumId = @mediumId AND ListId = @listId) BEGIN
   UPDATE DisasterCodeListItem
   SET    Code = @code, Status = 2
   WHERE  MediumId = @mediumId AND ListId = @listId
END
ELSE BEGIN
   INSERT DisasterCodeListItem (ListId, Code, MediumId, Notes)
   VALUES(@listId, @code, @mediumId, @notes)
END
SET @error = @@error
IF @error != 0 BEGIN
   ROLLBACK TRANSACTION @tranName
   COMMIT TRANSACTION
   SET @msg = ''Error encountered while adding item to existing disaster code list.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
   EXECUTE error$raise @msg, @error
   RETURN -100
END

-- Commit transaction
COMMIT TRANSACTION
RETURN 0
END
'
)

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'disasterCodeListItem$get')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.disasterCodeListItem$get
(
   @itemId int
)
WITH ENCRYPTION
AS
BEGIN

SET NOCOUNT ON

SELECT dli.ItemId,
       dli.Status,
       m.SerialNo,
       a.AccountName,
       dli.Code,
       dli.Notes,
       isnull(x.SerialNo,'''') as ''CaseName'',
       dli.RowVersion
FROM   DisasterCodeListItem dli
JOIN   Medium m
  ON   m.MediumId = dli.MediumId
JOIN   Account a
  ON   a.AccountId = m.AccountId
LEFT   JOIN 
       (
       SELECT s.SerialNo, c.MediumId
       FROM   SealedCase s
       JOIN   MediumSealedCase c
         ON   c.CaseId = s.CaseId
       ) as x
  ON   x.MediumId = m.MediumId
WHERE  dli.ItemId = @itemId

END
'
)

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'disasterCodeListItem$getPage')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.disasterCodeListItem$getPage
(
   @listId int,
   @pageNo int,
   @pageSize int,
   @filter nvarchar(4000),
   @sort tinyint
)
WITH ENCRYPTION
AS
BEGIN
DECLARE @msg as nvarchar(255)        -- used to preformat error message
DECLARE @msgTag as nvarchar(255)     -- used to hold first part of error message header
DECLARE @tables nvarchar(4000)
DECLARE @fields1 nvarchar(4000)      -- innermost fields
DECLARE @fields2 nvarchar(4000)      -- outermost fields
DECLARE @sql nvarchar(4000)
DECLARE @var nvarchar(4000)
DECLARE @order1 nvarchar(4000)	-- innermost order clause
DECLARE @order2 nvarchar(4000)   -- middle order clause
DECLARE @order3 nvarchar(4000)   -- outermost order clause
DECLARE @where nvarchar(4000)
DECLARE @x1 nvarchar(1000)   -- Serial number
DECLARE @x2 nvarchar(1000)   -- Account name
DECLARE @x3 nvarchar(1000)   -- Status
DECLARE @x4 nvarchar(1000)   -- Code
DECLARE @y1 nvarchar(1000)   -- Statuses
DECLARE @y2 nvarchar(1000)
DECLARE @y3 nvarchar(1000)
DECLARE @s nvarchar(4000)
DECLARE @s1 nvarchar(4000)
DECLARE @topSize int
DECLARE @display int
DECLARE @count int
DECLARE @error int
DECLARE @p int
DECLARE @i int
DECLARE @p1 int

SET NOCOUNT ON

-- Set the message tag
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=P''

-- Verify validity of @pageNo
IF @pageNo < 1 SET @pageNo = 1

-- Initialize variable string
SELECT @var = ''@x1$ nvarchar(1000), @x2$ nvarchar(1000), @x3$ nvarchar(1000), @y1$ nvarchar(1000), @y2$ nvarchar(1000), @y3$ nvarchar(1000)''
SELECT @p = -1, @p1 = -1, @i = 1

-- Set the order clause
IF @sort = 1 BEGIN
   SET @order1 = '' ORDER BY SerialNo asc''
   SET @order2 = '' ORDER BY SerialNo desc''
   SET @order3 = '' ORDER BY SerialNo asc''
END
ELSE IF @sort = 2 BEGIN
   SET @order1 = '' ORDER BY AccountName asc, SerialNo asc''
   SET @order2 = '' ORDER BY AccountName desc, SerialNo desc''
   SET @order3 = '' ORDER BY AccountName asc, SerialNo asc''
END
ELSE IF @sort = 3 BEGIN
   SET @order1 = '' ORDER BY Code asc, SerialNo asc''
   SET @order2 = '' ORDER BY Code desc, SerialNo desc''
   SET @order3 = '' ORDER BY Code asc, SerialNo asc''
END
ELSE BEGIN
   SET @msg = ''Invalid sort order.'' + @msgTag + ''>''
   RAISERROR(@msg,16,1)
   RETURN -100
END

-- Construct the where clause
SET @where = '' WHERE (dl.ListId = '' + cast(@listId as nvarchar(50)) + '' OR dl.CompositeId = '' + cast(@listId as nvarchar(50)) + '')''
SET @filter = ltrim(rtrim(coalesce(@filter,'''')))

WHILE @p != 0 AND len(@filter) != 0 BEGIN
   SET @p = charindex('' AND '', @filter)
   -- Get the string fragment
   IF @p = 0
      SET @s = ltrim(rtrim(@filter))
   ELSE
      SET @s = ltrim(rtrim(substring(@filter, 1, @p)))
   -- Trim the filter
   SET @filter = substring(@filter, @p + 5, 4000)
   -- Which filter is it?
   IF charindex(''SerialNo ='', @s) = 1 BEGIN
      SET @where = @where + '' AND ('' + replace(left(@s, charindex(''='',@s) + 1),''SerialNo'',''coalesce(lm.SerialNo,lc.SerialNo)'') + '' @x1$)''
      SET @x1 = replace(ltrim(substring(@s, charindex(''='',@s) + 1, 4000)), '''''''', '''')
   END
   ELSE IF charindex(''AccountName ='', @s) = 1 BEGIN
      SET @where = @where + '' AND ('' + replace(left(@s, charindex(''='',@s) + 1),''AccountName'',''coalesce(lm.AccountName,'''''''')'') + '' @x2$)''
      SET @x2 = replace(ltrim(substring(@s, charindex(''='',@s) + 1, 4000)), '''''''', '''')
   END
   ELSE IF charindex(''Code ='', @s) = 1 BEGIN
      SET @where = @where + '' AND (dli.'' + left(@s, charindex(''='',@s) + 1) + '' @x3$)''
      SET @x3 = replace(ltrim(substring(@s, charindex(''='',@s) + 1, 4000)), '''''''', '''')
   END
   ELSE IF charindex(''Status IN'', @s) = 1 BEGIN
      SET @s = ltrim(rtrim(replace(@s, ''Status IN '', '''')))
      -- Isolate from rest of where clause
      SET @where = @where + '' AND (''
      -- Loop through, adding where clauses
      WHILE @p1 != 0 BEGIN
         SET @p1 = charindex('','', @s)
         -- Get the string fragment
         IF @p1 = 0
            SET @s1 = ltrim(rtrim(@s))
         ELSE
            SET @s1 = ltrim(rtrim(substring(@s, 1, @p1 - 1)))
         -- Trim the filter
         SET @s = substring(@s, @p1 + 1, 4000)
         -- Get rid of starting left or ending right parenthesis
         IF left(@s1,1) = ''('' SET @s1 = ltrim(rtrim(substring(@s1,2,4000)))
         IF substring(@s1,len(@s1),1) = '')'' SET @s1 = ltrim(rtrim(left(@s1,len(@s1)-1)))
         -- Set the where clause
         IF @i != 1 SET @where = @where + '' OR ''
         SET @where = @where + '' dli.Status = @y'' + cast(@i as nchar(1)) + ''$''
         -- Which variable gets assigned depends on the value of i
         IF @i = 1 SET @y1 = @s1
         ELSE IF @i = 2 SET @y2 = @s1
         ELSE IF @i = 3 SET @y3 = @s1
         -- Raise error if too many status values
         IF @i = 3 AND @p1 != 0 BEGIN
            SET @msg = ''A maximum of three status values may be entered.'' + @msgTag + ''>''
            EXECUTE error$raise @msg
            RETURN -100
         END
         -- Increment the counter
         SET @i = @i + 1
      END
      -- Add terminating right parenthesis
      SET @where = @where + '')''
   END
   ELSE BEGIN
      SET @msg = ''Error occurred while selecting page of disaster recovery list items.  Invalid filter supplied.'' + @msgTag + ''>''
      EXECUTE error$raise @msg
      RETURN -100
   END
END

-- Construct the fields string
SET @fields2 = ''ItemId, Status, SerialNo, AccountName, Code, Notes, CaseName, RowVersion''
SET @fields1 = ''dli.ItemId, dli.Status, m.SerialNo as ''''SerialNo'''', a.AccountName as ''''AccountName'''', dli.Code as ''''Code'''', dli.Notes, isnull(c.SerialNo,'''''''') as ''''CaseName'''', dli.RowVersion''

-- Construct the tables string
SET @tables = ''DisasterCodeListItem dli JOIN DisasterCodeList dl ON dl.ListId = dli.ListId JOIN Medium m ON m.MediumId = dli.MediumId JOIN Account a ON a.AccountId = m.AccountId LEFT JOIN (SELECT c1.Serialno, mc1.MediumId FROM SealedCase c1 JOIN MediumSealedCase mc1 ON mc1.CaseId = c1.CaseId) as c ON c.MediumId = m.MediumId''

-- Select the total number of records that fit the criteria
CREATE TABLE #tblTemp (xyz int)
SET @sql = ''INSERT #tblTemp SELECT count(*) FROM '' + @tables + @where
EXECUTE sp_executesql @sql, @var, @x1$ = @x1, @x2$ = @x2, @x3$ = @x3, @y1$ = @y1, @y2$ = @y2, @y3$ = @y3
SELECT @count = xyz FROM #tblTemp
DROP TABLE #tblTemp

-- If the page number is 1, then we can execute without the subqueries
-- thus increasing efficiency.
IF @pageNo = 1 BEGIN
   SET @sql = ''SELECT TOP '' + cast(@pageSize as nvarchar(50)) + '' '' + @fields1 + '' FROM '' + @tables + @where + @order1
END
ELSE BEGIN
   -- Adjust the page size if necessary
   SET @display = @count - ((@pageNo - 1) * @pageSize)
   SET @topSize = @pageSize
   IF @display <= 0
      SET @where = @where + '' AND 1 != 1''
   ELSE IF @pageSize > @display
      SET @topSize = @display
   -- Select the data
   SET @sql = ''SELECT '' + @fields2 + '' FROM ''
   SET @sql = @sql + ''(''
   SET @sql = @sql + ''SELECT TOP '' + cast(@topSize as nvarchar(50)) + '' '' + @fields2 + '' FROM ''
   SET @sql = @sql + ''   (''
   SET @sql = @sql + ''   SELECT TOP '' + cast((@pageSize * @pageNo) as nvarchar(50)) + '' '' + @fields1 + '' FROM '' + @tables + @where + @order1
   SET @sql = @sql + ''   ) as x1 ''
   SET @sql = @sql + @order2 + '') as y '' + @order3
END

-- Execute the sql
EXECUTE sp_executesql @sql, @var, @x1$ = @x1, @x2$ = @x2, @x3$ = @x3, @y1$ = @y1, @y2$ = @y2, @y3$ = @y3
SET @error = @@error
IF @error != 0 BEGIN
   SET @msg = ''Error occurred while selecting page of disaster code list items.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
   EXECUTE error$raise @msg, @error
   RETURN -100
END

-- Select the total number of records that fit the criteria
SELECT @count AS ''RecordCount''

-- Return
RETURN 0
END
'
)

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'disasterCodeListItem$ins')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.disasterCodeListItem$ins
(
   @serialNo nvarchar(32),          -- medium serial number
   @code nvarchar(32),              -- disaster code
   @notes nvarchar(1000),           -- any notes to attach to the medium
   @batch nvarchar(4000) output     -- list names in the creation batch
)
WITH ENCRYPTION
AS
BEGIN
DECLARE @msg as nvarchar(255)        -- used to preformat error message
DECLARE @msgTag as nvarchar(255)     -- used to hold first part of error message header
DECLARE @tranName as nvarchar(255)   -- used to hold name of savepoint
DECLARE @error as int
DECLARE @location as bit
DECLARE @mediumId as int
DECLARE @accountId as int
DECLARE @returnValue as int
DECLARE @listId as int
DECLARE @itemId as int
DECLARE @status as int
DECLARE @priorId as int
DECLARE @priorRv as rowversion
DECLARE @tbl1 table (RowNo int identity(1,1), SerialNo nvarchar(32))
DECLARE @listName nvarchar(10)
DECLARE @i int

SET NOCOUNT ON

-- Tweak parameters
SET @batch = ltrim(rtrim(coalesce(@batch,'''')))
SET @serialNo = ltrim(rtrim(@serialNo))
SET @notes = ltrim(rtrim(@notes))
SET @code = ltrim(rtrim(@code))
SET @listName = ''''

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=P''
SET @tranName = object_name(@@procid) + CAST(@@nestlevel as nvarchar(2))

BEGIN TRANSACTION
SAVE TRANSACTION @tranName

-- Get the medium.  If there is no medium, check to see if it is a case.  If it is a
-- case, add all the media in the case to the list.
SELECT @mediumId = m.MediumId,
       @accountId = m.AccountId,
       @location = m.Location
FROM   Medium m
WHERE  m.SerialNo = @serialNo
IF @@rowcount != 0 BEGIN
   -- Location check
   IF @location = 1 BEGIN
      ROLLBACK TRANSACTION @tranName
      COMMIT TRANSACTION
      SET @msg = ''Medium '''''' + @serialNo + '''''' resides at the enterprise.'' + @msgTag + ''>''
      RAISERROR(@msg,16,1)
      RETURN -100
   END
   -- Make sure medium is not active beyond submitted on another list
   SELECT @listName = dl.ListName 
   FROM   DisasterCodeList dl
   JOIN   DisasterCodeListItem dli
     ON   dli.ListId = dl.ListId
   WHERE  dli.MediumId = @mediumId AND dli.Status = 4
   IF @@rowcount != 0 BEGIN
      ROLLBACK TRANSACTION @tranName
      COMMIT TRANSACTION
      SET @msg = ''Medium '' + @serialNo + '' cannot be added because it has already been transmitted on list '' + @listName + ''.'' + @msgTag + ''>''
      RAISERROR(@msg,16,1)
      RETURN -100
   END
   -- If medium already exists as submitted on one of the lists in the batch, return zero
   IF EXISTS 
      (
      SELECT 1 
      FROM   DisasterCodeListItem dli 
      JOIN   DisasterCodeList dl 
        ON   dl.ListId = dli.ListId 
      WHERE  dli.Status = 2 AND dli.MediumId = @mediumId AND charindex(dl.ListName,@batch) != 0
      )
   BEGIN
      RETURN 0
   END
END
ELSE BEGIN
   INSERT @tbl1 (SerialNo)
   SELECT m.SerialNo
   FROM   Medium m
   JOIN   MediumSealedCase mc
     ON   mc.Mediumid = m.MediumId
   JOIN   SealedCase c
     ON   c.CaseId = mc.CaseId
   WHERE  c.SerialNo = @serialNo
   IF @@rowcount != 0 BEGIN
      SET @i = 1
      WHILE 1 = 1 BEGIN
         SELECT @serialNo = SerialNo
         FROM   @tbl1      
         WHERE  RowNo = @i
         IF @@rowcount = 0 BREAK
         EXECUTE @returnValue = disasterCodeListItem$ins @serialNo, @code, @notes, @batch output
         IF @returnValue = -100 BEGIN
            ROLLBACK TRANSACTION @tranName
            COMMIT TRANSACTION
            RETURN -100
         END
         -- Next iteration
         SET @i = @i + 1
      END
      -- Commit and return
      COMMIT TRANSACTION
      RETURN 0
   END
END

-- If the medium doesn''t exist, then add it.  Otherwise, if the medium resides on another list (outside of batch), remove it.
IF @mediumId IS NULL BEGIN
   EXECUTE @returnValue = medium$addDynamic @serialNo, 0, @mediumId out
   IF @returnValue != 0 BEGIN
      ROLLBACK TRANSACTION @tranName
      COMMIT TRANSACTION
      RETURN -100
   END
   -- Get the account number
   SELECT @accountId = AccountId
   FROM   Medium
   WHERE  MediumId = @mediumId
END
ELSE BEGIN
   SELECT @priorId = dli.ItemId,
          @priorRv = dli.RowVersion
   FROM   DisasterCodeListItem dli
   JOIN   DisasterCodeList dl
     ON   dl.ListId = dli.ListId
   WHERE  dli.MediumId = @mediumId AND 
          dli.Status not in (1,512) AND 
          charindex(dl.ListName,@batch) = 0
   IF @@rowcount != 0 BEGIN
      EXECUTE @returnValue = disasterCodeListItem$remove @priorId, @priorRv
      IF @returnValue != 0 BEGIN
         ROLLBACK TRANSACTION @tranName
         COMMIT TRANSACTION
         RETURN -100
      END
   END
END

-- Check the account of the medium to see if we have already produced a list
-- for this account within this batch.  If we have, then add it to that list.
-- (If the item already appears on the list as removed, update its status to
-- to submitted.)
IF len (@batch) > 0 BEGIN
   SELECT @listId = ListId,
          @status = Status
   FROM   DisasterCodeList 
   WHERE  AccountId = @accountId AND charindex(ListName,@batch) > 0
   IF @@rowcount > 0 BEGIN
      IF @status > 2 BEGIN
         ROLLBACK TRANSACTION @tranName
         COMMIT TRANSACTION
         SET @msg = ''Unable to insert item into disaster recovery list that has been '' + dbo.string$statusName(4,@status) + ''.'' + @msgTag + ''>''
         EXECUTE error$raise @msg, @error
         RETURN -100
      END
      -- Make attempt to find the item on the list
      SELECT @itemId = ItemId, 
             @status = Status
      FROM   DisasterCodeListItem
      WHERE  ListId = @listId AND MediumId = @mediumId
   END
END

-- If we have no list, create one
IF @listId IS NULL BEGIN
   EXECUTE @returnValue = disasterCodeList$create @accountId, @listName OUTPUT
   IF @returnValue != 0 BEGIN
      ROLLBACK TRANSACTION @tranName
      COMMIT TRANSACTION
      RETURN -100
   END
   ELSE BEGIN
      -- Get the list id 
      SELECT @listId = ListId
      FROM   DisasterCodeList
      WHERE  ListName = @listName
      -- Add the name of the new list to the batch
      SET @batch = @batch + @listName
   END
END

-- Add the item if it was not restored
IF @itemId IS NOT NULL BEGIN
   UPDATE DisasterCodeListItem
   SET    Status = 2, 
          Code = @code
   WHERE  ItemId = @itemId
   SET @error = @@error
   IF @error != 0 BEGIN
      ROLLBACK TRANSACTION @tranName
      COMMIT TRANSACTION
      SET @msg = ''Error encountered while updating a disaster recovery list item.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
      EXECUTE error$raise @msg, @error
      RETURN -100
   END
END
ELSE BEGIN
   INSERT DisasterCodeListItem (ListId, Code, MediumId)
   VALUES(@listId, @code, @mediumId)
   SET @error = @@error
   IF @error != 0 BEGIN
      ROLLBACK TRANSACTION @tranName
      COMMIT TRANSACTION
      SET @msg = ''Error encountered while inserting a disaster recovery list item.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
      EXECUTE error$raise @msg, @error
      RETURN -100
   END
END

-- If we have notes, attach them to the medium here.  We''ll do this manually rather than go
-- through medium$upd because to do so would involve unnecessary overhead.
IF len(@notes) != 0 BEGIN
   UPDATE Medium
   SET    Notes = @notes
   WHERE  MediumId = @mediumId AND Notes != @notes
   SET @error = @@error
   IF @error != 0 BEGIN
	   ROLLBACK TRANSACTION @tranName
	   COMMIT TRANSACTION
	   SET @msg = ''Error encountered while updating medium notes.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
	   EXECUTE error$raise @msg, @error
	   RETURN -100
   END
END

-- Commit transaction
COMMIT TRANSACTION
RETURN 0
END
'
)

IF EXISTS(SELECT 1 FROM sysobjects WHERE name = 'disasterCodeListItem$afterInsert' AND objectproperty(id, 'ExecIsInsertTrigger' ) = 1) 
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'TRIGGER disasterCodeListItem$afterInsert
ON     DisasterCodeListItem
WITH ENCRYPTION
AFTER  INSERT
AS
BEGIN
DECLARE @msg nvarchar(255)         -- used to preformat error message
DECLARE @msgTag nvarchar(255)      -- used to hold first part of error message header
DECLARE @tranName nvarchar(255)    
DECLARE @serial1 nvarchar(32)
DECLARE @serial2 nvarchar(32)
DECLARE @listName nchar(10)
DECLARE @code1 nvarchar(32)
DECLARE @code2 nvarchar(32)
DECLARE @mediumId int
DECLARE @accountId int
DECLARE @rowcount int
DECLARE @status int
DECLARE @error int

SET @rowcount = @@rowcount
IF @rowcount = 0 RETURN

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=T''
SET @tranName = object_name(@@procid) + CAST(trigger_nestlevel(@@procid) as nvarchar(2))

-- No batch insert
IF @rowcount > 1 BEGIN
   SET @msg = ''Batch insert of disaster code list items not allowed.'' + @msgTag + ''>''
   EXECUTE error$raise @msg, 0
   RETURN
END

-- Make sure that the list is not a composite
IF EXISTS(SELECT 1 FROM DisasterCodeList WHERE AccountId IS NULL AND ListId = (SELECT ListId FROM Inserted)) BEGIN
   SET @msg = ''Items may not be placed directly on a composite disaster code list.'' + @msgTag + ''>''
   EXECUTE error$raise @msg, 0
   RETURN
END

-- Make sure that the medium belongs to the same account as the list
SELECT @listName = dl.ListName,
       @status  = dl.Status,
       @serial1 = m.SerialNo,
       @accountId = m.AccountId,
       @mediumId = m.MediumId
FROM   DisasterCodeList dl
JOIN   DisasterCodeListItem dli
  ON   dli.ListId = dl.ListId
JOIN   Medium m
  ON   m.MediumId = dli.MediumId
WHERE  m.AccountId = dl.AccountId AND dli.ItemId = (SELECT ItemId FROM Inserted)
IF @@rowcount = 0 BEGIN
   SET @msg = ''Medium must belong to same account as the list itself.'' + @msgTag + ''>''
   EXECUTE error$raise @msg, 0
   RETURN
END
ELSE IF @status >= 4 BEGIN
   SET @msg = ''Items cannot be added to a list that has already been '' + dbo.string$statusName(4,@status) + ''.'' + @msgTag + ''>''
   EXECUTE error$raise @msg, 0
   RETURN
END

-- Make sure that the medium does not appear active more than once
IF EXISTS
   (
   SELECT 1
   FROM   DisasterCodeListItem
   WHERE  MediumId = (SELECT MediumId FROM Inserted) AND Status != 1 AND Status != 512
   GROUP  BY MediumId
   HAVING count(*) > 1
   )
BEGIN
   SET @msg = ''Medium '' + @serial1 + '' may not appear on more than one active disaster recovery list.'' + @msgTag + ''>''
   EXECUTE error$raise @msg, 0
   RETURN
END

-- If the code was changed and the item is in a sealed case, make sure that no item in the sealed
-- case has a different disaster recovery code.
SELECT TOP 1 @serial2 = m.SerialNo
FROM   DisasterCodeListItem dli
JOIN   DisasterCodeList dl
  ON   dl.ListId = dli.ListId
JOIN   MediumSealedCase c
  ON   c.MediumId = dli.MediumId
JOIN   Medium m
  ON   m.MediumId = c.MediumId
WHERE  dli.Status not in (1,512) AND
       dli.Code != (SELECT Code FROM Inserted) AND
       c.CaseId = (SELECT isnull(CaseId,-1) FROM MediumSealedCase WHERE MediumId = @mediumId)
IF @@rowcount != 0 BEGIN
   SET @msg = ''Medium '' + @serial1 + '' and medium '' + @serial2 + '' may not be assigned different disaster recovery codes because they reside in the same sealed case.'' + @msgTag + ''>''
   EXECUTE error$raise @msg, 0
   RETURN
END

-- Begin transaction
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

-- Insert audit record
INSERT XDisasterCodeListItem
(
   Object, 
   Action, 
   Detail, 
   Login
)
VALUES
(
   @listName, 
   4, 
   ''Medium '' + @serial1 + '' added to disaster recovery list '' + @listName,
   dbo.string$GetSpidLogin()
)
SET @error = @@error
IF @error != 0 BEGIN
   SET @msg = ''Error encountered while inserting disaster code list item audit record.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
   EXECUTE error$raise @msg, @error, @tranName
   RETURN
END

-- Commit transaction
COMMIT TRANSACTION
END
'
)

IF EXISTS(SELECT 1 FROM sysobjects WHERE name = 'disasterCodeListItem$afterUpdate' AND objectproperty(id, 'ExecIsUpdateTrigger' ) = 1) 
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'TRIGGER disasterCodeListItem$afterUpdate
ON     DisasterCodeListItem
WITH ENCRYPTION
AFTER  UPDATE
AS
BEGIN
DECLARE @msg nvarchar(255)         -- used to preformat error message
DECLARE @msgTag nvarchar(255)      -- used to hold first part of error message header
DECLARE @msgUpdate nvarchar(4000)  -- used to hold the updated fields
DECLARE @tranName nvarchar(255)    -- used to hold name of savepoint
DECLARE @listName nchar(10)
DECLARE @serial1 nvarchar(32)
DECLARE @serial2 nvarchar(32)
DECLARE @rowVersion rowversion
DECLARE @returnValue int
DECLARE @mediumId int
DECLARE @rowcount int
DECLARE @error int
DECLARE @tbl1 table (RowNo int identity(1,1), ItemId int, ListId int, Status int, MediumId int)
DECLARE @tbl2 table (RowNo int identity(1,1), ListId int)
DECLARE @itemid int
DECLARE @listid int
DECLARE @status int
DECLARE @audit int
DECLARE @i int

SET @rowcount = @@rowcount
IF @rowcount = 0 RETURN

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=T''
SET @tranName = object_name(@@procid) + CAST(trigger_nestlevel(@@procid) as nvarchar(2))

-- Get the caller login from the spidLogin table
IF len(dbo.string$GetSpidLogin()) = 0 BEGIN
   SET @msg = ''Login not found for auditing purposes.'' + @msgTag + ''>''
   EXECUTE error$raise @msg, 0
   RETURN
END

-- Begin the transaction
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

-- Get all the items into the temporary table
INSERT @tbl1 (ItemId, ListId, Status, MediumId)
SELECT ItemId, ListId, Status, MediumId
FROM   Inserted

-- For each item, check the status.  Only record changes for removals and restores.
SET @i = 1
WHILE 1 = 1 BEGIN
   SELECT @itemid = i.ItemId, 
          @listId = i.ListId, 
          @status = i.Status,
          @serial1 = m.SerialNo,
          @mediumid = i.MediumId
   FROM   @tbl1 i
   JOIN   Medium m
     ON   m.MediumId = i.MediumId
   WHERE  i.RowNo = @i
   -- If nothing left, break
   IF @@rowcount = 0 BREAK
   -- Make sure that the medium does not appear active more than once
   IF EXISTS
      (
      SELECT 1
      FROM   DisasterCodeListItem
      WHERE  MediumId = @mediumId AND Status not in (1,512)
      GROUP  BY MediumId
      HAVING count(*) > 1
      )
   BEGIN
      SET @msg = ''Medium '' + @serial1 + '' may not appear on more than one active disaster recovery list.'' + @msgTag + ''>''
      EXECUTE error$raise @msg, 0, @tranName
      RETURN
   END
   -- If the status was changed, audit it
   IF EXISTS 
      (
      SELECT 1 
      FROM   Inserted i 
      JOIN   Deleted d 
        ON   d.ItemId = i.Itemid 
      WHERE  i.ItemId = @itemid AND ((i.Status = 1 AND d.Status != 1) OR (d.Status = 1 AND i.Status = 2))
      )
   BEGIN
      -- Get the list name
      SELECT @listName = dl.ListName
      FROM   DisasterCodeList dl
      JOIN   Inserted i
        ON   dl.ListId = i.ListId
      WHERE  ItemId = @itemid
      -- Create the audit message
      IF @status = 1 BEGIN
         SET @msgUpdate = ''Medium '' + @serial1 + '' removed from list '' + @listName
         SET @audit = 5
      END
      ELSE BEGIN
         SET @msgUpdate = ''Medium '' + @serial1 + '' added to list '' + @listName + ''.''   -- restored, actually
         SET @audit = 4
      END
      -- Insert the audit message
      INSERT XDisasterCodeListItem (Object, Action, Detail, Login)
      VALUES (@listName, @audit, @msgUpdate, dbo.string$GetSpidLogin())
      SET @error = @@error
      IF @error != 0 BEGIN
         SET @msg = ''Error encountered while inserting disaster recovery list item audit record.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
         EXECUTE error$raise @msg, @error, @tranName
         RETURN
      END
   END
   -- If the code was changed and the item is in a sealed case, make sure that no item in the sealed
   -- case has a different disaster recovery code.
   SELECT TOP 1 @serial2 = m.SerialNo
   FROM   DisasterCodeListItem dli
   JOIN   DisasterCodeList dl
     ON   dl.ListId = dli.ListId
   JOIN   MediumSealedCase c
     ON   c.MediumId = dli.MediumId
   JOIN   Medium m
     ON   m.MediumId = c.MediumId
   WHERE  dli.Status not in (1,512) AND
          dli.Code != (SELECT Code FROM Inserted WHERE ItemId = @itemId) AND
          c.CaseId = (SELECT isnull(CaseId,-1) FROM MediumSealedCase WHERE MediumId = @mediumId)
   IF @@rowcount != 0 BEGIN
      SET @msg = ''Medium '' + @serial1 + '' and medium '' + @serial2 + '' may not be assigned different disaster recovery codes because they reside in the same sealed case.'' + @msgTag + ''>''
      EXECUTE error$raise @msg, 0, @tranName
      RETURN
   END
   -- Next row
   SET @i = @i + 1
END

-- Collect the lists into the table
INSERT @tbl2 (ListId)
SELECT DISTINCT ListId FROM Inserted

-- For each list in the update where an item was updated to a status other 
-- than removed, make sure that the discrete list status is equal to 
-- the (translated) lowest status among its non-removed items.
SET @i = 1
WHILE 1 = 1 BEGIN
   SELECT @listId = i.ListId,
          @rowVersion = dl.RowVersion
   FROM   Inserted i
   JOIN   Deleted d
     ON   d.ItemId = i.ItemId
   JOIN   DisasterCodeList dl
     ON   dl.ListId = i.ListId
   WHERE  i.Status != 1 AND  -- power(2,0)
          d.Status != i.Status AND
          i.ListId = (SELECT ListId FROM @tbl2 WHERE RowNo = @i)
   -- Break if nothing
   IF @@rowCount = 0 BREAK
   -- Set the status
   EXECUTE @returnValue = disasterCodeList$setStatus @listId, @rowVersion
   IF @returnValue != 0 BEGIN
      ROLLBACK TRANSACTION @tranName
      COMMIT TRANSACTION
      RETURN
   END
   -- Next list
   SET @i = @i + 1
END

-- For each list in the update where an item was updated to removed status, 
-- delete the list if there are no more items on the list.  Otherwise, update
-- the status of the list.
SET @i = 1
WHILE 1 = 1 BEGIN
   SELECT TOP 1 @listId = i.ListId,
          @rowVersion = dl.RowVersion
   FROM   Inserted i
   JOIN   Deleted d
     ON   d.ItemId = i.ItemId
   JOIN   DisasterCodeList dl
     ON   dl.ListId = i.ListId
   WHERE  i.Status = 1 AND
          d.Status != 1 AND
          i.ListId = (SELECT ListId FROM @tbl2 WHERE RowNo = @i)
   -- Break if nothing
   IF @@rowCount = 0 BREAK
   -- If tapes still exist actively on the list, update its status; otherwise delete the list.
   IF EXISTS(SELECT 1 FROM DisasterCodeListItem WHERE ListId = @listId AND Status != 1) BEGIN
      EXECUTE @returnValue = disasterCodeList$setStatus @listId, @rowVersion
   END
   ELSE BEGIN
      EXECUTE @returnValue = disasterCodeList$del @listId, @rowVersion
   END
   IF @returnValue != 0 BEGIN
      ROLLBACK TRANSACTION @tranName
      COMMIT TRANSACTION
      RETURN
   END
   -- Next list
   SET @i = @i + 1
END

-- Commit
COMMIT TRANSACTION
END
'
)

IF EXISTS(SELECT 1 FROM sysobjects WHERE name = 'disasterCodeMedium$afterDelete' AND objectproperty(id, 'ExecIsDeleteTrigger' ) = 1) 
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'TRIGGER disasterCodeMedium$afterDelete
ON     DisasterCodeMedium
WITH ENCRYPTION
AFTER  DELETE
AS
BEGIN
DECLARE @msg nvarchar(255)        -- used to preformat error message
DECLARE @msgTag nvarchar(255)     -- used to hold first part of error message header
DECLARE @tranName nvarchar(255)   -- used to hold name of savepoint
DECLARE @rowCount int            -- holds the number of rows in the Deleted table
DECLARE @serialNo nvarchar(32)
DECLARE @codeName nvarchar(32)
DECLARE @mediumId int
DECLARE @codeId int
DECLARE @error int
DECLARE @tbl1 table (RowNo int identity(1,1), MediumId int, CodeId int, SerialNo nvarchar(32))
DECLARE @i int

SET @rowcount = @@rowcount
IF @rowcount = 0 RETURN

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=T''
SET @tranName = object_name(@@procid) + CAST(trigger_nestlevel(@@procid) as nvarchar(2))

-- Insert audit record
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

-- Get the caller login from the spidLogin table
IF len(dbo.string$GetSpidLogin()) = 0 BEGIN
   SET @msg = ''Caller login not found in spid login table.'' + @msgTag + ''>''
   EXECUTE error$raise @msg, 0, @tranName
   RETURN
END

-- Get the rows being deleted
INSERT @tbl1 (MediumId, CodeId, SerialNo)
SELECT d.MediumId, d.CodeId, m.SerialNo
FROM   Deleted d
JOIN   Medium m
  ON   m.MediumId = d.MediumId

-- Loop through the rows
SET @i = 1
WHILE 1 = 1 BEGIN
   SELECT @mediumId = t.MediumId,
          @codeId = t.CodeId,
          @serialNo = t.SerialNo,
          @codeName = case len(Code) when 0 then ''(empty)'' else Code end
   FROM   @tbl1 t
   JOIN   DisasterCode d
     ON   d.CodeId = t.CodeId
   WHERE  t.RowNo = @i
   IF @@rowCount = 0 BREAK
   -- Insert the audit record   
   INSERT XMedium (Object, Action, Detail, Login)
   VALUES(@serialNo, 2, ''Disaster code '' + @codeName + '' unassigned'', dbo.string$GetSpidLogin())
   -- Evaluate the error
   SET @error = @@error
   IF @error != 0 BEGIN
      SET @msg = ''Error encountered while inserting a row into the medium audit table.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
      EXECUTE error$raise @msg, @error, @tranName
      RETURN
   END
   -- If code has no entries left, delete the code
   IF NOT EXISTS (SELECT 1 FROM DisasterCodeMedium WHERE CodeId = @codeId) BEGIN
      DELETE DisasterCode 
      WHERE  CodeId = @codeId
      SET @error = @@error
      IF @error != 0 BEGIN
         SET @msg = ''Error encountered while deleting disaster code.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
         EXECUTE error$raise @msg, @error, @tranName
         RETURN
      END
   END
   -- Next medium
   SET @i = @i + 1
END

-- Commit transaction
COMMIT TRANSACTION
END
'
)

-------------------------------------------------------------------------------
--
-- Other procedures
--
-------------------------------------------------------------------------------
IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'auditTrail$getMedium')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.auditTrail$getMedium
(
   @serialNo nvarchar(32),
   @startDate datetime = null,
   @endDate datetime = null
)
WITH ENCRYPTION
AS
BEGIN
DECLARE @i int
DECLARE @listName nvarchar(10)
DECLARE @mediumLike1 nvarchar(128)
DECLARE @mediumLike2 nvarchar(128)
DECLARE @tblLists table
(
   RowNo int identity (1,1),
   ListName nvarchar(10)
)
DECLARE @tblTable table
(
   ItemId int,
   Date datetime,
   Object nvarchar(512),
   Action int,
   Detail nvarchar(2048),
   Login nvarchar(64),
   AuditType int,
   ListName nvarchar(10)
)

SET NOCOUNT ON

-- Initialize
SELECT @i = 1
SELECT @endDate = isnull(@endDate, ''9999-12-31 23:59:59'')
SELECT @startDate = isnull(@startDate, ''1900-01-01 00:00:00'')
SELECT @mediumLike1 = ''%Medium '''''' + @serialNo + ''''''%''
SELECT @mediumLike2 = ''%Medium '' + @serialNo + ''%''

-- Get regular records
INSERT @tblTable (ItemId, Date, Object, Action, Detail, Login, AuditType, ListName)
SELECT ItemId, Date, Object, Action, Detail, Login, 4096, ''''   -- Medium
FROM   XMedium
WHERE  Object = @serialNo AND Date > @startDate AND Date < @endDate
UNION
SELECT ItemId, Date, Object, Method, case Direction when 1 then ''Medium moved to enterprise'' else ''Medium moved to vault'' end, Login, 8192, ''''  -- Medium Movement
FROM   XMediumMovement
WHERE  Object = @serialNo AND Date > @startDate AND Date < @endDate
UNION
SELECT ItemId, Date, Object, Action, Detail, Login, 2048, ''''   -- Sealed case
FROM   XSealedCase
WHERE (Detail LIKE @mediumLike1 OR Detail LIKE @mediumLike2) AND Date > @startDate AND Date < @endDate
UNION
SELECT ItemId, Date, Object, Action, case patindex(''%SD-%[0-9]%'', Detail) when 0 then case charindex('' list'', Detail) when 0 then Detail + '' on list '' + Object else replace(Detail, '' list'', '' list '' + Object) end else Detail end, Login, 64, Object   -- Send list item
FROM   XSendListItem
WHERE (Detail LIKE @mediumLike1 OR Detail LIKE @mediumLike2) AND Date > @startDate AND Date < @endDate
UNION
SELECT ItemId, Date, Object, Action, case patindex(''%RE-%[0-9]%'', Detail) when 0 then case charindex('' list'', Detail) when 0 then Detail + '' on list '' + Object else replace(Detail, '' list'', '' list '' + Object) end else Detail end, Login, 128, Object  -- Receive list item
FROM   XReceiveListItem
WHERE (Detail LIKE @mediumLike1 OR Detail LIKE @mediumLike2) AND Date > @startDate AND Date < @endDate
UNION
SELECT ItemId, Date, Object, Action, case patindex(''%DC-%[0-9]%'', Detail) when 0 then case charindex('' list'', Detail) when 0 then Detail + '' on list '' + Object else replace(Detail, '' list'', '' list '' + Object) end else Detail end, Login, 256, Object  -- Disaster code list item
FROM   XDisasterCodeListItem
WHERE (Detail LIKE @mediumLike1 OR Detail LIKE @mediumLike2) AND Date > @startDate AND Date < @endDate

-- Insert lists into list table
INSERT @tblLists (ListName)
SELECT distinct ListName FROM @tblTable

WHILE 1 = 1 BEGIN
   SELECT @listName = ListName
   FROM   @tblLists
   WHERE  RowNo = @i
   IF @@rowcount = 0 BEGIN
      BREAK
   END
   ELSE IF LEFT(@listName,2) = ''SD'' BEGIN
      INSERT @tblTable (ItemId, Date, Object, Action, Detail, Login, AuditType, ListName)
      SELECT ItemId, Date, Object, Action, Detail, Login, 64, ''''
      FROM   XSendList
      WHERE  Object = @listName AND Date > @startDate AND Date < @endDate
   END
   ELSE IF LEFT (@listName,2) = ''RE'' BEGIN
      INSERT @tblTable (ItemId, Date, Object, Action, Detail, Login, AuditType, ListName)
      SELECT ItemId, Date, Object, Action, Detail, Login, 128, ''''
      FROM   XReceiveList
      WHERE  Object = @listName AND Date > @startDate AND Date < @endDate
   END
   ELSE IF LEFT (@listName,2) = ''DC'' BEGIN
      INSERT @tblTable (ItemId, Date, Object, Action, Detail, Login, AuditType, ListName)
      SELECT ItemId, Date, Object, Action, Detail, Login, 256, ''''
      FROM   XDisasterCodeList
      WHERE  Object = @listName AND Date > @startDate AND Date < @endDate
   END
   -- Increment
   SELECT @i = @i + 1
END

-- Select from table
SELECT ItemId, Date, Object, Action, Detail, Login, AuditType
FROM   @tblTable
ORDER  BY Date desc, AuditType asc, ItemId asc

RETURN 0
END
'
)

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'barCodePattern$synchronize')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.barCodePattern$synchronize
WITH ENCRYPTION
AS
BEGIN
declare @tranName nvarchar(255)   -- used to hold name of savepoint
declare @tblLiteral table (RowNo int identity(1,1), Id int, Type int, Account int)
declare @tblFormat table (RowNo int identity(1,1), Pattern nvarchar(256), Type int, Account int)
declare @tblOther table (RowNo int identity(1,1), Id int, SerialNo nvarchar(256), Type int, Account int)
declare @s nvarchar(256)
declare @id int
declare @i int
declare @t int
declare @a int
declare @t1 int
declare @a1 int

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @tranName = object_name(@@procid) + CAST(trigger_nestlevel(@@procid) as nvarchar(2))

-- Get those media that correspond to literal barcodes and
-- do not have the correct type or account
INSERT @tblLiteral (Id, Type, Account)
SELECT m.MediumId, p.TypeId, p.AccountId
FROM   Medium m
JOIN   BarCodePattern p
  ON   p.Pattern = m.SerialNo
WHERE  m.TypeId != p.TypeId OR m.AccountId != p.AccountId

-- Get those media that do not correspond to literal barcodes
INSERT @tblOther (Id, SerialNo, Type, Account)
SELECT m.MediumId, m.SerialNo, m.TypeId, m.AccountId
FROM   Medium m
LEFT   JOIN BarCodePattern p
  ON   p.Pattern = m.SerialNo
WHERE  p.Pattern IS NULL

-- Get all the non-literal bar code formats
INSERT @tblFormat (Pattern, Type, Account)
SELECT Pattern, TypeId, AccountId
FROM   BarCodePattern
WHERE  dbo.bit$RegexMatch(Pattern, ''[a-zA-Z0-9]*'') != 1
ORDER  BY Position ASC

-- Update the literals
SET @i = 1

WHILE 1 = 1 BEGIN
   SELECT @id = Id, 
          @t = Type, 
          @a = Account 
   FROM   @tblLiteral 
   WHERE  RowNo = @i
   IF @@rowcount = 0 
      BREAK
   ELSE
      UPDATE Medium SET TypeId = @t, AccountId = @a WHERE MediumId = @id
   -- Increment
   SET @i = @i + 1
END

-- Run through the non-literals
SET @i = 1

WHILE 1 = 1 BEGIN
   SELECT @id = Id, 
          @s = SerialNo, 
          @t = Type, 
          @a = Account 
   FROM   @tblOther 
   WHERE  RowNo = @i
   IF @@rowcount = 0 BREAK
   -- Get the correct type from the bar code format table
   SELECT TOP 1 @t1 = Type, @a1 = Account
   FROM   @tblFormat
   WHERE  dbo.bit$RegexMatch(@s, Pattern) = 1
   -- If the non-literal does not have the correct type or account, update it
   IF @t != @t1 OR @a != @a1 BEGIN
      BEGIN TRANSACTION
      SAVE TRANSACTION @tranName
      UPDATE Medium
      SET    TypeId = @t1,
             AccountId = @a1
      WHERE  MediumId = @id
      -- Roll back if error, but keep going
      IF @@error != 0 ROLLBACK TRAN @tranName
      -- Commit the transaction
      COMMIT TRANSACTION
   END
   -- Increment
   SET @i = @i + 1
END

-- Return
RETURN 0
END
'
)

IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'barCodePattern$getDefaults')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.barCodePattern$getDefaults
(
   @serialNo nvarchar(32),
   @typeName nvarchar(256) output,
   @accountName nvarchar(256) output
)
WITH ENCRYPTION
AS
BEGIN
DECLARE @msgTag nvarchar(255)
DECLARE @msg nvarchar(255)
DECLARE @n bit
DECLARE @p int

SET NOCOUNT ON

-- If we have a literal, use it.  If there are literals, but we don''t have one that satisfies the
-- serial number, collect the non-literals and do a top 1.  Otherwise use a straight top 1.
-- Otherwise, get rid of the literals and then use a top 1.
IF EXISTS (SELECT 1 FROM BarCodePattern WHERE Pattern = @serialNo) BEGIN
   SELECT @typeName = m.TypeName,
          @accountName = a.AccountName
   FROM   BarCodePattern b
   JOIN   MediumType m
     ON   m.TypeId = b.TypeId
   JOIN   Account a
     ON   a.AccountId = b.AccountId
   WHERE  b.Pattern = @serialNo
END
ELSE BEGIN
   -- If we have literals, find first non-literal and search from there.  Otherwise do straight retrieve.
   IF EXISTS (SELECT 1 FROM BarCodePattern WHERE Position = 1 AND patindex(''%[^A-Z0-9a-z]%'', Pattern) = 0) BEGIN
      IF EXISTS (SELECT 1 FROM BarCodePattern WHERE Position < 0) BEGIN
         SELECT TOP 1 @p = Position - 1
         FROM   BarCodePattern
--         WITH  (INDEX(akBarCodePattern$Position))
         WHERE  patindex(''%[^A-Z0-9a-z]%'', Pattern) = 0
         ORDER  BY Position ASC
         -- Select the format
         SELECT TOP 1 @typeName = m.TypeName,
                @accountName = a.AccountName
         FROM   BarCodePattern b
--         WITH  (INDEX(akBarCodePattern$Position))
         JOIN   MediumType m
           ON   m.TypeId = b.TypeId
         JOIN   Account a
           ON   a.AccountId = b.AccountId
         WHERE  b.Position <= @p AND dbo.bit$RegexMatch(@serialNo,b.Pattern) = 1
         ORDER  BY b.Position DESC
      END
      ELSE BEGIN
         SELECT TOP 1 @p = Position + 1
         FROM   BarCodePattern
         WITH  (INDEX (akBarCodePattern$Position))
         WHERE  patindex(''%[^A-Z0-9a-z]%'', Pattern) = 0
         ORDER  BY Position DESC
         -- Select the format
         SELECT TOP 1 @typeName = m.TypeName,
                @accountName = a.AccountName
         FROM   BarCodePattern b
         WITH  (INDEX (akBarCodePattern$Position))
         JOIN   MediumType m
           ON   m.TypeId = b.TypeId
         JOIN   Account a
           ON   a.AccountId = b.AccountId
         WHERE  b.Position >= @p AND dbo.bit$RegexMatch(@serialNo,b.Pattern) = 1
         ORDER  BY b.Position ASC
      END
   END
   ELSE BEGIN
      IF EXISTS (SELECT 1 FROM BarCodePattern WHERE Position < 0) BEGIN
         SELECT TOP 1 @typeName = m.TypeName,
                @accountName = a.AccountName
         FROM   BarCodePattern b
         WITH  (INDEX(akBarCodePattern$Position))
         JOIN   MediumType m
           ON   m.TypeId = b.TypeId
         JOIN   Account a
           ON   a.AccountId = b.AccountId
         WHERE  dbo.bit$RegexMatch(@serialNo,b.Pattern) = 1
         ORDER  BY b.Position DESC
      END
      ELSE BEGIN
         SELECT TOP 1 @typeName = m.TypeName,
                @accountName = a.AccountName
         FROM   BarCodePattern b
         WITH  (INDEX(akBarCodePattern$Position))
         JOIN   MediumType m
           ON   m.TypeId = b.TypeId
         JOIN   Account a
           ON   a.AccountId = b.AccountId
         WHERE  dbo.bit$RegexMatch(@serialNo,b.Pattern) = 1
         ORDER  BY b.Position ASC
      END   
   END
   -- If no format, raise error
   IF @@rowcount = 0 BEGIN
      SET @msgTag = ''<'' + object_name(@@procid) + '';Type=P''
      SET @msg = ''No default bar code pattern found.'' + @msgTag + ''>''
      RAISERROR(@msg,16,1)
      RETURN -100
   END
END

-- Return
RETURN 0
END
'
)

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'sendListItemCase$ins')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.sendListItemCase$ins
(
   @itemId int,
   @caseName nvarchar(32),
   @batchLists nvarchar(4000) = ''''
)
WITH ENCRYPTION
AS
BEGIN
DECLARE @msg as nvarchar(255)        -- used to preformat error message
DECLARE @msgTag as nvarchar(255)     -- used to hold first part of error message header
DECLARE @tranName as nvarchar(255)   -- used to hold name of savepoint
DECLARE @error as int
DECLARE @listName as nchar(10)
DECLARE @caseList as nchar(10)
DECLARE @returnValue as int
DECLARE @currentCase as nvarchar(32)
DECLARE @currentId as int
DECLARE @caseId int

SET NOCOUNT ON

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=P''
SET @tranName = object_name(@@procid) + CAST(@@nestlevel as nvarchar(2))

-- If the item is not submitted or verified, raise error.
IF EXISTS
   (
   SELECT 1
   FROM   SendListItem
   WHERE  ItemId = @itemId AND Status >= 16
   )
BEGIN
   SET @msg = ''Items may not be inserted into a case once the list on which that case appears has attained or gone beyond '' + dbo.string$statusName(1,16) + '' status.'' + @msgTag + ''>''
   RAISERROR(@msg,16,1)
   RETURN -100
END

-- Get the id of the case if it exists with uncleared status.
SELECT @caseId = CaseId 
FROM   SendListCase 
WHERE  Cleared = 0 AND SerialNo = @caseName

-- Check to see if the item already resides inside a case.  If it resides in 
-- given case, just return.  If it resides in another case, raise error.
SELECT @currentId = slc.CaseId,
       @currentCase = slc.SerialNo
FROM   SendListCase slc
JOIN   SendListItemCase slic
  ON   slic.CaseId = slc.CaseId
WHERE  slic.ItemId = @itemId
IF @@rowCount > 0 BEGIN
   IF @currentId = coalesce(@caseId,0) BEGIN
      RETURN 0
   END
   ELSE BEGIN
      SET @msg = ''Medium must be removed from case '''''' + @currentCase + '''''' before it may be inserted into a different case.'' + @msgTag + ''>''
      RAISERROR(@msg,16,1)
      RETURN -100
   END
END

-- If the case exists, raise error if any list on which the case is mentioned has transmitted status.
IF @caseId IS NOT NULL BEGIN
   IF EXISTS
      (
      SELECT 1
      FROM   SendList sl
      JOIN   SendListItem sli
        ON   sli.ListId = sl.ListId
      JOIN   SendListItemCase slic
        ON   slic.ItemId = sli.ItemId
      WHERE  slic.caseId = @caseId AND sl.Status >= 16
      )
   BEGIN
      SET @msg = ''Items may not be inserted into a case once the list on which that case appears has reached '' + dbo.string$statusName(1,16) + '' status.'' + @msgTag + ''>''
      RAISERROR(@msg,16,1)
      RETURN -100
   END
   -- Verify that the case does not actively appear on any list other than the discrete list, the composite to which the
   -- discrete list belongs, or any specific lists such as those being created in a single batch but are not yet merged.
   SELECT TOP 1 @listName = sl.ListName
   FROM   SendListItemCase slic
   JOIN   SendListItem sli
     ON   sli.ItemId = slic.ItemId
   JOIN   SendList sl
     ON   sl.ListId = sli.ListId
   LEFT   JOIN 
         (SELECT sli.ListId
          FROM   SendListItem sli
          JOIN   SendList sl
            ON   sl.ListId = sli.ListId
          WHERE  sli.ItemId = @ItemId OR
                 CompositeId = (SELECT isnull(CompositeId,-1) FROM SendList WHERE ListId = (SELECT ListId FROM SendListItem WHERE ItemId = @itemId))) as x
     ON   x.ListId = sl.ListId
   WHERE  x.ListId IS NULL AND slic.CaseId = @caseId AND 
          sli.Status not in (1,512) AND charindex(ListName,isnull(@batchLists,'''')) = 0
   IF @@rowcount != 0 BEGIN
      SET @msg = ''Medium may not be added to case '''''' + @caseName + '''''' because case currently resides on active list '' + @listName + ''.'' + @msgTag + ''>''
      RAISERROR(@msg,16,1)
      RETURN -100
   END
END

-- Begin the transaction
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

-- Add the case if it doesn''t exist
IF @caseId IS NULL BEGIN
   EXECUTE @returnValue = sendListCase$ins @caseName, @caseId OUT
   IF @returnValue != 0 BEGIN
      ROLLBACK TRANSACTION @tranName
      COMMIT TRANSACTION
      RETURN -100
   END
END

-- Add the item to the case
INSERT SendListItemCase
(
   CaseId,
   ItemId
)
VALUES
(
   @caseId,
   @itemId
)
SET @error = @@error
IF @error != 0 BEGIN
   ROLLBACK TRANSACTION @tranName
   COMMIT TRANSACTION
   SET @msg = ''Error encountered while adding medium to case on send list.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
   EXECUTE error$raise @msg, @error
   RETURN -100
END

-- Commit transaction
COMMIT TRANSACTION
RETURN 0
END
'
)

-------------------------------------------------------------------------------
--
-- Other triggers
--
-------------------------------------------------------------------------------
IF EXISTS(SELECT 1 FROM sysobjects WHERE name = 'medium$afterDelete' AND objectproperty(id, 'ExecIsDeleteTrigger' ) = 1) 
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'TRIGGER medium$afterDelete
ON     Medium
WITH ENCRYPTION
AFTER  DELETE
AS
BEGIN
DECLARE @msg nvarchar(255)         -- used to preformat error message
DECLARE @msgTag nvarchar(255)      -- used to hold first part of error message header
DECLARE @tranName nvarchar(255)    -- used to hold name of savepoint
DECLARE @serialNo nvarchar(32)
DECLARE @returnValue int
DECLARE @error int
DECLARE @tbl1 table (RowNo int identity(1,1), SerialNo nvarchar(32))
DECLARE @tbl2 table (RowNo int identity (1,1), Id int, Type int) -- 1:Location, 2:Account, 3:ObjectType, 4:UnknownSerial
DECLARE @type int
DECLARE @id int
DECLARE @i int
DECLARE @j int

IF @@rowcount = 0 RETURN
SET @i = 1

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=T''
SET @tranName = object_name(@@procid) + CAST(trigger_nestlevel(@@procid) as nvarchar(2))

-- Begin the transaction
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

-- Get the caller login from the spidLogin table
IF len(dbo.string$GetSpidLogin()) = 0 BEGIN
   SET @msg = ''No login found for auditing purposes.'' + @msgTag + ''>''
   EXECUTE error$raise @msg, 0, @tranName
   RETURN
END

-- Get all the deleted media
INSERT @tbl1 (SerialNo)
SELECT SerialNo
FROM   Deleted
ORDER  BY SerialNo ASC

-- Audit and resolve inventory conflicts
WHILE 1 = 1 BEGIN
   SELECT @serialNo = SerialNo
   FROM   @tbl1
   WHERE  RowNo = @i
   IF @@rowcount = 0 BREAK
   -- Audit message
   INSERT XMedium (Object, Action, Detail, Login)
   VALUES(@serialNo, 3, ''Medium deleted'', dbo.string$GetSpidLogin())
   SET @error = @@error
   IF @error != 0 BEGIN
      SET @msg = ''Error inserting a medium audit record.'' + @msgTag + '';Error='' + cast(@error as nvarchar(9)) + ''>''
      EXECUTE error$raise @msg, @error, @tranName
      RETURN
   END
   -- Resolve location, account, and type conflicts
   DELETE FROM @tbl2
   INSERT @tbl2 (Id, Type)   -- location
   SELECT c.Id, 1
   FROM   InventoryConflict c
   JOIN   InventoryConflictLocation l
     ON   l.Id = c.Id
   WHERE  c.SerialNo = @serialNo
   INSERT @tbl2 (Id, Type)   -- account
   SELECT c.Id, 2
   FROM   InventoryConflict c
   JOIN   InventoryConflictAccount a
     ON   a.Id = c.Id
   WHERE  c.SerialNo = @serialNo
   INSERT @tbl2 (Id, Type)   -- type
   SELECT c.Id, 3
   FROM   InventoryConflict c
   JOIN   InventoryConflictObjectType o
     ON   o.Id = c.Id
   WHERE  c.SerialNo = @serialNo
   SELECT @j = min(RowNo) FROM @tbl2
   WHILE 1 = 1 BEGIN
      SELECT @id = Id, @type = Type
      FROM   @tbl2
      WHERE  RowNo = @j
      IF @@rowcount = 0 BREAK
      IF @type = 1 BEGIN
         EXECUTE @returnValue = inventoryConflict$resolveLocation @id, 4
         IF @returnValue != 0 BEGIN
            ROLLBACK TRANSACTION @tranName
            COMMIT TRANSACTION
            RETURN
         END
      END
      ELSE IF @type = 2 BEGIN
         EXECUTE @returnValue = inventoryConflict$resolveAccount @id, 3
         IF @returnValue != 0 BEGIN
            ROLLBACK TRANSACTION @tranName
            COMMIT TRANSACTION
            RETURN
         END
      END
      ELSE IF @type = 3 BEGIN
         EXECUTE @returnValue = inventoryConflict$resolveObjectType @id, 3
         IF @returnValue != 0 BEGIN
            ROLLBACK TRANSACTION @tranName
            COMMIT TRANSACTION
            RETURN
         END
      END
      SET @j = @j + 1
   END
   -- Next counter
   SET @i = @i + 1
END

-- Commit transaction
COMMIT TRANSACTION
END
'
)

IF EXISTS(SELECT 1 FROM sysobjects WHERE name = 'medium$afterInsert' AND objectproperty(id, 'ExecIsInsertTrigger' ) = 1) 
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'TRIGGER medium$afterInsert
ON     Medium
WITH ENCRYPTION
AFTER  INSERT
AS
BEGIN
DECLARE @msg nvarchar(255)        -- used to preformat error message
DECLARE @msgTag nvarchar(255)     -- used to hold first part of error message header
DECLARE @tranName nvarchar(255)   -- used to hold name of savepoint
DECLARE @serialNo nvarchar(32)    -- serial number of inserted medium
DECLARE @bside nvarchar(32)       -- b-side serial number of inserted medium
DECLARE @typeName nvarchar(128)
DECLARE @accountName nvarchar(128)
DECLARE @x nvarchar(128)
DECLARE @y nvarchar(128)
DECLARE @returnValue int
DECLARE @accountId int
DECLARE @location int
DECLARE @rowcount int            -- holds the number of rows in the Inserted table
DECLARE @typeId int
DECLARE @error int            
DECLARE @id int

SET @rowcount = @@rowcount
IF @rowcount = 0 RETURN

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=T''
SET @tranName = object_name(@@procid) + CAST(trigger_nestlevel(@@procid) as nvarchar(2))

BEGIN TRANSACTION
SAVE TRANSACTION @tranName

-- Make sure we do not have a batch insert
IF @rowcount > 1 BEGIN
   SET @msg = ''Batch insert into medium table not allowed.'' + @msgTag + ''>''
   EXECUTE error$raise @msg, 0, @tranName
   RETURN
END

-- Get the caller login from the spidLogin table
IF len(dbo.string$GetSpidLogin()) = 0 BEGIN
   SET @msg = ''No login found for auditing purposes.'' + @msgTag + ''>''
   EXECUTE error$raise @msg, 0, @tranName
   RETURN
END

-- Select the serial number of the new medium from the Inserted table
SELECT @serialNo = i.SerialNo,
       @typeName = m.TypeName,
       @accountName = a.AccountName,
       @accountId = i.AccountId,
       @location = i.Location,
       @typeId = i.TypeId,
       @bside = i.BSide 
FROM   Inserted i
JOIN   MediumType m
  ON   m.TypeId = i.TypeId
JOIN   Account a
  ON   a.AccountId = i.AccountId

-- Verify that there is no sealed case with that serial number
IF EXISTS(SELECT 1 FROM SealedCase WHERE SerialNo = @serialNo) BEGIN
   SET @msg = ''A sealed case with serial number '''''' + @serialNo + '''''' already exists.'' + @msgTag + ''>''
   EXECUTE error$raise @msg, 0, @tranName
   RETURN
END
ELSE IF EXISTS(SELECT 1 FROM SendListCase WHERE SerialNo = @serialNo AND Cleared = 0) BEGIN
   SET @msg = ''A case with serial number '''''' + @serialNo + '''''' exists on an active shipping list.'' + @msgTag + ''>''
   EXECUTE error$raise @msg, 0, @tranName
   RETURN
END

-- Verify that there is no medium with that serial number as a bside
IF EXISTS(SELECT 1 FROM Medium WHERE BSide = @serialNo) BEGIN
   SET @msg = ''A medium currently exists with serial number '''''' + @serialNo + '''''' as its b-side.'' + @msgTag + ''>''
   EXECUTE error$raise @msg, 0, @tranName
   RETURN
END

-- If there is a bside, make sure that it is unique and that the medium is not one-sided or a container.
 IF len(@bside) > 0 BEGIN
    IF EXISTS(SELECT 1 FROM Medium WHERE SerialNo = @bside) BEGIN
       SET @msg = ''A medium currently exists with serial number '''''' + @serialNo + '''''' as its b-side.'' + @msgTag + ''>''
       EXECUTE error$raise @msg, 0, @tranName
       RETURN
    END
   IF EXISTS(SELECT 1 FROM Medium WHERE BSide = @bside) BEGIN
      SET @msg = ''A medium currently exists with serial number '''''' + @bside + '''''' as its b-side.'' + @msgTag + ''>''
      EXECUTE error$raise @msg, 0, @tranName
      RETURN
   END
   ELSE IF EXISTS(SELECT 1 FROM SealedCase WHERE SerialNo = @bside) BEGIN
      SET @msg = ''A sealed case with serial number '''''' + @bside + '''''' already exists.'' + @msgTag + ''>''
      EXECUTE error$raise @msg, 0, @tranName
      RETURN
   END
   ELSE IF EXISTS(SELECT 1 FROM SendListCase WHERE SerialNo = @bside AND Cleared = 0) BEGIN
      SET @msg = ''A case with serial number '''''' + @bside + '''''' exists on an active shipping list.'' + @msgTag + ''>''
      EXECUTE error$raise @msg, 0, @tranName
      RETURN
   END
   ELSE IF EXISTS(SELECT 1 FROM MediumType WHERE TypeId = @typeId AND (Container = 1 OR TwoSided = 0)) BEGIN
      SET @msg = ''A b-side serial number may not be assigned to a medium of one-sided type or to a container.'' + @msgTag + ''>''
      EXECUTE error$raise @msg, 0, @tranName
      RETURN
   END
END

-- Verify that the account and medium type accord with the bar code formats
EXECUTE barcodepattern$getdefaults @serialNo, @x out, @y out
IF @x != @typeName or @y != @accountName BEGIN
   SET @msg = ''Account and/or medium type do not accord with bar code formats.'' + @msgTag + ''>''
   EXECUTE error$raise @msg, 0, @tranName
   RETURN
END

-- Insert audit record
INSERT XMedium
(
   Object, 
   Action, 
   Detail, 
   Login
)
VALUES
(
   @serialNo, 
   1, 
   ''Medium '' + @serialNo + '' created at the '' + case @location when 0 then ''vault'' else ''enterprise'' end + '' under account '' + @accountName + '' and of type '' + @typeName,
   dbo.string$GetSpidLogin()
)

SET @error = @@error
IF @error != 0 BEGIN
   SET @msg = ''Error encounterd while inserting a medium audit record.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
   EXECUTE error$raise @msg, @error, @tranName
   RETURN
END

-- Remove any unknown medium inventory discrepancy that may exist
WHILE 1 = 1 BEGIN
   SELECT @id = c.Id
   FROM   InventoryConflict c
   JOIN   InventoryConflictUnknownSerial s
     ON   s.Id = c.Id
   WHERE  SerialNo = @serialNo
   IF @@rowcount = 0 BREAK
   EXECUTE @returnValue = inventoryConflict$resolveUnknownSerial @id, 1
   IF @returnValue != 0 BEGIN
      ROLLBACK TRANSACTION @tranName   
      COMMIT TRANSACTION
      RETURN
   END
END

COMMIT TRANSACTION 
END
'
)

IF EXISTS(SELECT 1 FROM sysobjects WHERE name = 'medium$afterUpdate' AND objectproperty(id, 'ExecIsUpdateTrigger' ) = 1) 
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'TRIGGER medium$afterUpdate
ON     Medium
WITH ENCRYPTION
AFTER  UPDATE
AS
BEGIN
DECLARE @msg nvarchar(255)         -- used to preformat error message
DECLARE @msgTag nvarchar(255)      -- used to hold first part of error message header
DECLARE @audit nvarchar(3000)  -- used to hold the updated fields
DECLARE @tranName nvarchar(255)    -- used to hold name of savepoint
DECLARE @tagInfo nvarchar(4000)    -- information from the SpidLogin table
DECLARE @listName nchar(10)
DECLARE @lastMove datetime    -- holds the new last move date
DECLARE @caseName nvarchar(32)
DECLARE @serialNo nvarchar(32)
DECLARE @lost bit
DECLARE @hot bit
DECLARE @mid int
DECLARE @iStatus int
DECLARE @rdate nvarchar(10)
DECLARE @bSide nvarchar(32)
DECLARE @notes nvarchar(4000)
DECLARE @listType int
DECLARE @loc bit
DECLARE @tid int
DECLARE @aid int
DECLARE @cid int
DECLARE @rowcount int             -- holds the number of rows in the Deleted table
DECLARE @moveType int           -- method by which medium was moved
DECLARE @iid int
DECLARE @caseId int
DECLARE @codeId int
DECLARE @status int
DECLARE @error int
DECLARE @lid int
DECLARE @login nvarchar(32)
DECLARE @oldSerial nvarchar(64)
DECLARE @returnValue int
DECLARE @rowVersion rowversion
DECLARE @tblMedia table (RowNo int primary key identity(1,1), SerialNo nvarchar(32))
DECLARE @tblM table (RowNo int identity (1,1), Message nvarchar(1000))
DECLARE @tbl1 table (RowNo int identity (1,1), Id int, Type int, Reason int) -- 1:Location, 2:Account, 3:ObjectType, 4:UnknownSerial
DECLARE @reason int
DECLARE @type int
DECLARE @id int
DECLARE @i int
DECLARE @j int

SET @rowcount = @@rowcount
IF @rowcount = 0 RETURN

SET NOCOUNT ON

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=T''
SET @tranName = object_name(@@procid) + CAST(trigger_nestlevel(@@procid) as nvarchar(2))

-- Begin the transaction
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

-- Get the caller login from the spidLogin table
SET @login = dbo.string$GetSpidLogin()
SET @tagInfo = dbo.string$GetSpidInfo()
IF len(@login) = 0 BEGIN
   SET @msg = ''No login found for auditing purposes.'' + @msgTag + ''>''
   EXECUTE error$raise @msg, 0, @tranName
   RETURN
END

-- Get the movement method -- if location changed, we''ll need this
SET @moveType = 1
IF CHARINDEX(''send'', @tagInfo) != 0 SET @moveType = 2                     -- send list cleared
ELSE IF CHARINDEX(''receive'', @tagInfo) != 0 SET @moveType = 3             -- receive list cleared

-- Disallow movement or account change if a medium is active and beyond unverified on a send or receive list.
SELECT TOP 1 @serialNo = i.SerialNo,
       @listName = l.ListName,
       @loc = i.Location,
       @aid = i.AccountId,
       @tid = i.TypeId,
       @mid = i.MediumId,
       @status = l.Status,
       @listType = case left(l.ListName,1) when ''S'' then 1 else 2 end
FROM   Inserted i
JOIN   Deleted d
  ON   i.MediumId = d.MediumId
JOIN   (
       SELECT TOP 1 sl.ListName as ''ListName'',
              sli.MediumId as ''MediumId'',
              sli.Status as ''Status''
       FROM   SendList sl
       JOIN   SendListItem sli
         ON   sli.ListId = sl.ListId
       WHERE  sli.Status IN (8,16,32,64,128,256) -- power(2,x)
       UNION
       SELECT TOP 1 rl.ListName,
              rli.MediumId,
              rli.Status
       FROM   ReceiveList rl
       JOIN   ReceiveListItem rli
         ON   rli.ListId = rl.ListId
       WHERE  rli.Status IN (8,16,32,64,128,256) -- power(2,x)
       )
       As l
  ON   l.MediumId = i.MediumId
WHERE  i.Location != d.Location OR i.AccountId != d.AccountId
ORDER BY i.SerialNo Asc
IF @@rowcount != 0 BEGIN
   IF EXISTS(SELECT 1 FROM Deleted WHERE MediumId = @mid AND @aid != AccountId) BEGIN
      SET @msg = ''Medium '''''' + @serialNo + '''''' may not have its account changed because it appears on list '' + @listName + '', which has attained '' + dbo.string$statusName(@listType,@status) + '' status.'' + @msgTag + ''>''
      EXECUTE error$raise @msg, 0, @tranName
      RETURN
   END
   IF EXISTS(SELECT 1 FROM Deleted WHERE MediumId = @mid AND @loc != Location) BEGIN
      -- Do not allow movement unless we are clearing a list.  This is usually cut and dried,
      -- as the user will have most of the time directly cleared a list.  There is one 
      -- exception, however, where an unrelated action will trigger a list to be cleared.
      -- This is when the last unverified tape on a send or receive list is marked missing or
      -- removed.  Since all other items are verified, the removal of the last item will
      -- trigger clearing of the list.  If the tape is on a receive list and the rest of
      -- the list is fully verified, then the list is being cleared in this manner.
      IF @moveType != 2 AND @moveType != 3 BEGIN
         IF left(@listName,2) = ''SD'' BEGIN
            SELECT @lid = sl.ListId, 
                   @cid = sl.CompositeId, 
                   @moveType = 2
            FROM   SendList sl
            JOIN   SendListItem sli
              ON   sli.ListId = sl.ListId
            WHERE  MediumId = @mid AND dbo.bit$statusEligible(1,sl.Status,512) = 1
            IF @@rowcount = 0 BEGIN
               SET @msg = ''Medium '''''' + @serialNo + '''''' may not be moved because it appears on list '' + @listName + '', which has attained '' + dbo.string$statusName(1,@status) + '' status.'' + @msgTag + ''>''
               EXECUTE error$raise @msg, 0, @tranName
               RETURN
            END
            ELSE BEGIN
               IF @cid IS NOT NULL BEGIN
                  SELECT @status = Status, @listName = ListName
                  FROM   SendList
                  WHERE  ListId = @cid
                  IF dbo.bit$statusEligible(1,@status,512) != 1 BEGIN
                     SET @msg = ''Medium '''''' + @serialNo + '''''' may not be moved because it appears on list '' + @listName + '', which has attained '' + dbo.string$statusName(1,@status) + '' status.'' + @msgTag + ''>''
                     EXECUTE error$raise @msg, 0, @tranName
                     RETURN
                  END
               END
            END
         END
         ELSE IF left(@listName,2) = ''RE'' BEGIN
            SELECT @lid = rl.ListId, 
                   @cid = rl.CompositeId, 
                   @moveType = 3
            FROM   ReceiveList rl
            JOIN   ReceiveListItem rli
              ON   rli.ListId = rl.ListId
            WHERE  MediumId = @mid AND dbo.bit$statusEligible(2,rl.Status,512) = 1
            IF @@rowcount = 0 BEGIN
               SET @msg = ''Medium '''''' + @serialNo + '''''' may not be moved because it appears on list '' + @listName + '', which has attained '' + dbo.string$statusName(2,@status) + '' status.'' + @msgTag + ''>''
               EXECUTE error$raise @msg, 0, @tranName
               RETURN
            END
            ELSE BEGIN
               IF @cid IS NOT NULL BEGIN
                  SELECT @status = Status, @listName = ListName
                  FROM   ReceiveList
                  WHERE  ListId = @cid
                  IF dbo.bit$statusEligible(2,@status,512) != 1 BEGIN
                     SET @msg = ''Medium '''''' + @serialNo + '''''' may not be moved because it appears on list '' + @listName + '', which has attained '' + dbo.string$statusName(2,@status) + '' status.'' + @msgTag + ''>''
                     EXECUTE error$raise @msg, 0, @tranName
                     RETURN
                  END
               END
            END
         END
      END
   END
END

-- Verify that any updated medium that resides inside a case has the
-- same hot status as the case itself.
SELECT TOP 1 @serialNo = i.SerialNo
FROM   Inserted i
JOIN   MediumSealedCase msc
  ON   msc.MediumId = i.MediumId
JOIN   SealedCase sc
  ON   sc.CaseId = msc.CaseId
WHERE  sc.HotStatus != i.HotStatus
ORDER BY i.SerialNo
IF @@rowcount > 0 BEGIN
   SET @msg = ''Because medium '''''' + @serialNo + '''''' is in a sealed case, it must have the same hot site status as the case itself.'' + @msgTag + ''>''
   EXECUTE error$raise @msg, 0, @tranName
   RETURN
END

-- Disallow change if tape is missing and location is changed
SELECT TOP 1 @serialNo = d.SerialNo
FROM   Inserted i
JOIN   Deleted d
  ON   d.MediumId = i.MediumId
WHERE  i.Missing = 1 AND
       i.Location != d.Location
IF @@rowcount != 0 BEGIN
   SET @msg = ''The location of medium '''''' + @serialNo + '''''' may not be changed because it is currently marked as missing.'' + @msgTag + ''>''
   EXECUTE error$raise @msg, 0, @tranName
   RETURN
END

-- Disallow change of return date if medium is in sealed case.  Because we may
-- receive a return date change even if the user did not actually change the
-- return date (i.e. the case return date is kept in the medium detail object
-- for display purposes and then submitted to the medium$upd procedure, we will
-- want to confirm, if the tape is in a sealed case, that the return date
-- submitted is the same as the return date on the sealed case.
SELECT TOP 1 @serialNo = i.SerialNo,
       @caseName = c.SerialNo
FROM   Deleted d
JOIN   Inserted i
  ON   i.MediumId = d.MediumId
JOIN   MediumSealedCase m
  ON   m.MediumId = i.MediumId
JOIN   SealedCase c
  ON   m.CaseId = c.CaseId
WHERE  coalesce(d.ReturnDate,''1900-01-01'') != coalesce(i.ReturnDate,''1900-01-01'') AND 
       coalesce(c.ReturnDate,''1900-01-01'') != coalesce(i.ReturnDate,''1900-01-01'')
IF @@rowcount > 0 BEGIN
   SET @msg = ''Medium '''''' + @serialNo + '''''' may not have its return date changed because it resides in sealed case '''''' + @caseName + ''''''.'' + @msgTag + ''>''
   EXECUTE error$raise @msg, 0, @tranName
   RETURN
END

-- If an account or medium type has changed, verify that the account and medium type accord with the bar code formats.
--
-- 2006-04-14 : Commenting this check out; takes too long
-- IF EXISTS (SELECT 1 FROM Inserted i JOIN Deleted d ON d.MediumId = i.MediumId WHERE (i.TypeId != d.TypeId OR i.AccountId != d.AccountId)) BEGIN
--    -- Check for disagreement
--    SELECT TOP 1 @serialNo = i.SerialNo
--    FROM   Inserted i
--    JOIN   Deleted d
--      ON   d.MediumId = i.MediumId
--    WHERE (i.TypeId != d.TypeId OR i.AccountId != d.AccountId) AND
--           cast(i.TypeId as nchar(15)) + ''|'' + cast(i.AccountId as nchar(15)) != (SELECT TOP 1 cast(p.TypeId as nchar(15)) + ''|'' + cast(p.AccountId as nchar(15)) FROM BarCodePattern p WHERE dbo.bit$RegexMatch(i.SerialNo,p.Pattern) = 1 ORDER BY p.Position asc)
--    -- If there is one, raise an error
--    IF @@rowcount != 0 BEGIN
--       SET @msg = ''Account and/or medium type for medium '' + @serialNo + '' do not accord with bar code formats.'' + @msgTag + ''>''
--       EXECUTE error$raise @msg, 0, @tranName
--       RETURN
--    END
-- END

-- Gather the media id numbers into the table
INSERT @tblMedia (SerialNo)
SELECT SerialNo
FROM   Inserted
ORDER  BY SerialNo Asc

-- Initialize counter
SELECT @i = 1

-- Loop through the media in the update
WHILE 1 = 1 BEGIN
   SELECT @mid = MediumId,
          @serialNo = SerialNo,
          @loc = Location,
          @lastMove = LastMoveDate,
          @hot = HotStatus,
          @lost = Missing,
          @rdate = coalesce(convert(nvarchar(10),ReturnDate,120),''(None)''),
          @bSide = BSide,
          @notes = Notes,
          @tid = TypeId,
          @aid = AccountId
   FROM   Inserted
   WHERE  SerialNo = (SELECT SerialNo FROM @tblMedia WHERE RowNo = @i)
   IF @@rowcount = 0 BREAK
   -- Clear the message table
   DELETE FROM @tblM
   -- Hot site status
   IF EXISTS (SELECT 1 FROM Deleted WHERE MediumId = @mid AND HotStatus != @hot) BEGIN
      INSERT @tblM (Message) SELECT case @hot when 1 then ''Medium regarded as at hot site'' else ''Medium no longer regarded as at hot site'' end
   END
   -- Missing status
   IF EXISTS(SELECT 1 FROM Deleted WHERE MediumId = @mid AND Missing != @lost) BEGIN
      INSERT @tblM (Message) SELECT case @lost when 1 then ''Medium marked as missing'' else ''Medium marked as found'' end
   END
   -- Return date
   IF EXISTS(SELECT 1 FROM Deleted WHERE MediumId = @mid AND coalesce(convert(nvarchar(10),ReturnDate,120),''(None)'') != @rdate) BEGIN
      INSERT @tblM (Message) SELECT ''Return date changed to '' + @rdate
   END
   -- B-Side
   IF EXISTS(SELECT 1 FROM Deleted WHERE MediumId = @mid AND BSide != @bSide) BEGIN
      -- If there is a bside, make sure that it is unique
      IF len(@bSide) > 0 BEGIN
         IF EXISTS(SELECT 1 FROM Medium WHERE SerialNo = @bSide) BEGIN
            SET @msg = ''A medium currently exists with serial number '''''' + @bside + ''''''.'' + @msgTag + ''>''
            EXECUTE error$raise @msg, 0, @tranName
            RETURN
         END
         IF EXISTS(SELECT 1 FROM Medium WHERE BSide = @bSide) BEGIN
            SET @msg = ''A medium currently exists with serial number '''''' + @bSide + '''''' as its b-side.'' + @msgTag + ''>''
            EXECUTE error$raise @msg, 0, @tranName
            RETURN
         END
         ELSE IF EXISTS(SELECT 1 FROM SealedCase WHERE SerialNo = @bSide) BEGIN
            SET @msg = ''A sealed case with serial number '''''' + @bSide + '''''' already exists.'' + @msgTag + ''>''
            EXECUTE error$raise @msg, 0, @tranName
            RETURN
         END
         ELSE IF EXISTS(SELECT 1 FROM SendListCase WHERE SerialNo = @bSide AND Cleared = 0) BEGIN
            SET @msg = ''A case with serial number '''''' + @bSide + '''''' exists on an active shipping list.'' + @msgTag + ''>''
            EXECUTE error$raise @msg, 0, @tranName
            RETURN
         END
         ELSE IF EXISTS(SELECT 1 FROM MediumType WHERE TypeId = @tid AND (Container = 1 OR TwoSided = 0)) BEGIN
            SET @msg = ''A b-side serial number may not be assigned to a medium of one-sided type or to a container.'' + @msgTag + ''>''
            EXECUTE error$raise @msg, 0, @tranName
            RETURN
         END
      END
      -- Insert audit message
      INSERT @tblM (Message) SELECT ''B-side changed to '' + @bside
   END
   -- Medium type
   IF EXISTS(SELECT 1 FROM Deleted WHERE MediumId = @mid AND TypeId != @tid) BEGIN
      INSERT @tblM (Message) SELECT ''Medium type changed to '' + (SELECT TypeName FROM MediumType WHERE TypeId = @tid)
   END
   -- Account
   IF EXISTS(SELECT 1 FROM Deleted WHERE MediumId = @mid AND AccountId != @aid) BEGIN
      INSERT @tblM (Message) SELECT ''Account changed to '' + (SELECT AccountName FROM Account WHERE AccountId = @aid)
   END
   -- Serial number
   IF EXISTS (SELECT 1 FROM Deleted WHERE mediumId = @mid AND SerialNo != @serialNo) BEGIN
      INSERT @tblM (Message) SELECT ''Serial number changed to '''''' + @serialNo + ''''''''
   END
   -- Initialize audit variables
   SELECT @j = min(RowNo) FROM @tblM
   SELECT @oldSerial = SerialNo FROM Deleted WHERE MediumId = @mid
   -- Insert audit records
   WHILE 1 = 1 BEGIN
      SELECT @audit = Message
      FROM   @tblM
      WHERE  RowNo = @j
      IF @@rowcount = 0 
         BREAK
      ELSE BEGIN
         INSERT XMedium(Object, Action, Detail, Login)
         VALUES(@oldSerial, 2, @audit, dbo.string$GetSpidLogin())
         SET @error = @@error
         IF @error != 0 BEGIN
            SET @msg = ''Error inserting a medium audit record.'' + @msgTag + '';Error='' + cast(@error as nvarchar(9)) + ''>''
            EXECUTE error$raise @msg, @error, @tranName
            RETURN
         END
      END
      -- Counter
      SET @j = @j + 1
   END
   -- If the medium is marked as missing, then we should disallow missing status if 
   -- the medium is verified on a send or receive list.  (If not verified, remove it from the list.)
   IF EXISTS (SELECT 1 FROM Deleted WHERE mediumId = @mid AND Missing != @lost) AND @lost = 1 BEGIN
      -- Check send lists or receive lists
      IF @loc = 1 BEGIN
         SELECT @iid = ItemId,
                @iStatus = Status,
                @rowVersion = RowVersion
         FROM   SendListItem
         WHERE  Status > 1 AND Status != 512 AND MediumId = @mid
         IF @@rowcount != 0 BEGIN
            IF @iStatus IN (8, 256) BEGIN
               SET @msg = ''Medium cannot be marked missing when it has been verified on an active shipping list.'' + @msgTag + ''>''
               EXECUTE error$raise @msg, 0, @tranName
               RETURN
            END
            ELSE BEGIN
               -- Remove item from send list
               EXECUTE @returnValue = sendListItem$remove @iid, @rowVersion, 1
   	         IF @returnValue != 0 BEGIN
   	            ROLLBACK TRANSACTION @tranName   
   	            COMMIT TRANSACTION
   	            RETURN
   	         END
            END
         END
      END
      ELSE BEGIN
         SELECT @iid = ItemId,
                @iStatus = Status,
                @rowVersion = RowVersion
         FROM   ReceiveListItem
         WHERE  Status > 1 AND Status != 512 AND MediumId = @mid
         IF @@rowcount != 0 BEGIN
            IF @iStatus IN (8, 256) BEGIN
               SET @msg = ''Medium cannot be marked missing when it is has been verified on an active receiving list.'' + @msgTag + ''>''
               EXECUTE error$raise @msg, 0, @tranName
               RETURN
            END
            ELSE BEGIN
               -- Remove item from receive list
	            EXECUTE @returnValue = receiveListItem$remove @iid, @rowVersion, 0, 1
		         IF @returnValue != 0 BEGIN
		            ROLLBACK TRANSACTION @tranName   
		            COMMIT TRANSACTION
		            RETURN
		         END
            END
         END
      END
   END
   -- If the location was altered, then make an entry in the special medium movement audit 
   -- table.  We should also delete any disaster code if the medium is now at the enterprise
   IF EXISTS (SELECT 1 FROM Deleted WHERE MediumId = @mid AND Location != @loc) BEGIN
      INSERT XMediumMovement(Date, Object, Direction, Method, Login)
      VALUES(@lastMove, @serialNo, @loc, @moveType, dbo.string$GetSpidLogin())
      SET @error = @@error
      IF @error != 0 BEGIN
         SET @msg = ''Error inserting a row into the XMediumMovement table.'' + @msgTag + '';Error='' + cast(@error as nvarchar(9)) + ''>''
         EXECUTE error$raise @msg, @error, @tranName
         RETURN
      END
      -- If the medium was moved to the enterprise, remove it from sealed case and remove disaster code
      IF @loc = 1 BEGIN
         SELECT @caseId = CaseId
         FROM   MediumSealedCase
         WHERE  MediumId = @mid
         IF @@rowcount > 0 BEGIN
            EXECUTE @returnValue = mediumSealedCase$del @caseId, @mid
            IF @returnValue != 0 BEGIN
               ROLLBACK TRANSACTION @tranName   
               COMMIT TRANSACTION
               RETURN
            END
         END
         SELECT @codeId = CodeId
         FROM   DisasterCodeMedium
         WHERE  MediumId = @mid
         IF @@rowcount > 0 BEGIN
            EXECUTE @returnValue = disasterCodeMedium$del @codeId, @mid
            IF @returnValue != 0 BEGIN
               ROLLBACK TRANSACTION @tranName   
               COMMIT TRANSACTION
               RETURN
            END
         END
      END
   END
   -- If location or account has been altered, remove submitted entries from lists of any type.
   IF EXISTS (SELECT 1 FROM Deleted WHERE MediumId = @mid AND (Location != @loc OR AccountId != @aid)) BEGIN
      -- Remove any unverified send list items
      SELECT @iid = ItemId, @rowVersion = RowVersion
      FROM   SendListItem
      WHERE  MediumId = @mid AND Status = 2 -- power(2,1)
      IF @@rowcount > 0 BEGIN
         EXECUTE @returnValue = sendListItem$remove @iid, @rowVersion
         IF @returnValue != 0 BEGIN
            ROLLBACK TRANSACTION @tranName
            COMMIT TRANSACTION
            RETURN
         END
      END
      -- Remove any submitted receive list items
      SELECT @iid = ItemId, @rowVersion = RowVersion
      FROM   ReceiveListItem
      WHERE  MediumId = @mid AND Status = 2 -- power(2,1)
      IF @@rowcount > 0 BEGIN
         EXECUTE @returnValue = receiveListItem$remove @iid, @rowVersion
         IF @returnValue != 0 BEGIN
            ROLLBACK TRANSACTION @tranName
            COMMIT TRANSACTION
            RETURN
         END
      END
      -- Remove any submitted disaster code list items
      SELECT @iid = ItemId, @rowVersion = RowVersion
      FROM   DisasterCodeListItem dli
      WHERE  MediumId = @mid AND Status = 2 -- power(2,1)
      IF @@rowcount > 0 BEGIN
         EXECUTE @returnValue = disasterCodeListItem$remove @iid, @rowVersion
         IF @returnValue != 0 BEGIN
            ROLLBACK TRANSACTION @tranName
            COMMIT TRANSACTION
            RETURN
         END
      END
   END
   ----------------------------------------------------------------------------
   -- Inventory conflict resolutions
   ----------------------------------------------------------------------------
   DELETE FROM @tbl1
   -- Location resolutions
   IF EXISTS (SELECT 1 FROM Inserted i JOIN Deleted d ON d.MediumId = i.MediumId WHERE i.MediumId = @mid AND i.SerialNo != d.SerialNo) BEGIN
      INSERT @tbl1 (Id, Type, Reason)
      SELECT c.Id, 1, 3
      FROM   InventoryConflict c
      JOIN   InventoryConflictLocation l
        ON   l.Id = c.Id
      WHERE  c.SerialNo = @oldSerial
   END
   ELSE IF EXISTS (SELECT 1 FROM Inserted i JOIN Deleted d ON d.MediumId = i.MediumId WHERE i.MediumId = @mid AND i.Missing = 1 AND d.Missing = 0) BEGIN
      INSERT @tbl1 (Id, Type, Reason)
      SELECT c.Id, 1, 2
      FROM   InventoryConflict c
      JOIN   InventoryConflictLocation l
        ON   l.Id = c.Id
      WHERE  c.SerialNo = @oldSerial
   END
   ELSE IF EXISTS (SELECT 1 FROM Inserted i JOIN Deleted d ON d.MediumId = i.MediumId WHERE i.MediumId = @mid AND i.Location != d.Location) BEGIN
      INSERT @tbl1 (Id, Type, Reason)
      SELECT c.Id, 1, 1
      FROM   InventoryConflict c
      JOIN   InventoryConflictLocation l
        ON   l.Id = c.Id
      WHERE  c.SerialNo = @oldSerial
   END
   -- Account resolutions
   IF EXISTS (SELECT 1 FROM Inserted i JOIN Deleted d ON d.MediumId = i.MediumId WHERE i.MediumId = @mid AND i.SerialNo != d.SerialNo) BEGIN
      INSERT @tbl1 (Id, Type, Reason)
      SELECT c.Id, 2, 2
      FROM   InventoryConflict c
      JOIN   InventoryConflictAccount a
        ON   a.Id = c.Id
      WHERE  c.SerialNo = @oldSerial
   END
   ELSE IF EXISTS (SELECT 1 FROM Inserted i JOIN Deleted d ON d.MediumId = i.MediumId WHERE i.MediumId = @mid AND i.AccountId != d.AccountId) BEGIN
      INSERT @tbl1 (Id, Type, Reason)
      SELECT c.Id, 2, 1
      FROM   InventoryConflict c
      JOIN   InventoryConflictAccount a
        ON   a.Id = c.Id
      JOIN   Inserted i
        ON   i.AccountId = a.AccountId
      WHERE  c.SerialNo = @oldSerial AND i.MediumId = @mid
   END
   -- Object type resolutions
   IF EXISTS (SELECT 1 FROM Inserted i JOIN Deleted d ON d.MediumId = i.MediumId WHERE i.MediumId = @mid AND i.SerialNo != d.SerialNo) BEGIN
      INSERT @tbl1 (Id, Type, Reason)
      SELECT c.Id, 3, 2
      FROM   InventoryConflict c
      JOIN   InventoryConflictObjectType o
        ON   o.Id = c.Id
      WHERE  c.SerialNo = @oldSerial
   END
   ELSE IF EXISTS (SELECT 1 FROM Inserted i JOIN Deleted d ON d.MediumId = i.MediumId WHERE i.MediumId = @mid AND i.TypeId != d.TypeId) BEGIN
      INSERT @tbl1 (Id, Type, Reason)
      SELECT c.Id, 3, 1
      FROM   InventoryConflict c
      JOIN   InventoryConflictObjectType o
        ON   o.Id = c.Id
      JOIN   Inserted i
        ON   i.TypeId = o.TypeId
      WHERE  c.SerialNo = @oldSerial AND i.MediumId = @mid
   END
   -- Unknown medium resolutions
   IF EXISTS (SELECT 1 FROM Inserted i JOIN Deleted d ON d.MediumId = i.MediumId WHERE i.MediumId = @mid AND i.SerialNo != d.SerialNo) BEGIN
      INSERT @tbl1 (Id, Type, Reason)
      SELECT c.Id, 4, 2
      FROM   InventoryConflict c
      JOIN   InventoryConflictUnknownSerial s
        ON   s.Id = c.Id
      WHERE  c.SerialNo = @oldSerial
   END
   -- Cycle through the discrepancies
   SELECT @j = min(RowNo) FROM @tbl1
   WHILE 1 = 1 BEGIN
      SELECT @id = Id, @type = Type, @reason = Reason
      FROM   @tbl1
      WHERE  RowNo = @j
      IF @@rowcount = 0 BREAK
      -- Resolve conflicts
      IF @type = 1 BEGIN
         EXECUTE @returnValue = inventoryConflict$resolveLocation @id, @reason
         IF @returnValue != 0 BEGIN
            ROLLBACK TRANSACTION @tranName
            COMMIT TRANSACTION
            RETURN
         END
      END
      ELSE IF @type = 2 BEGIN
         EXECUTE @returnValue = inventoryConflict$resolveAccount @id, @reason
         IF @returnValue != 0 BEGIN
            ROLLBACK TRANSACTION @tranName
            COMMIT TRANSACTION
            RETURN
         END
      END
      ELSE IF @type = 3 BEGIN
         EXECUTE @returnValue = inventoryConflict$resolveObjectType @id, @reason
         IF @returnValue != 0 BEGIN
            ROLLBACK TRANSACTION @tranName
            COMMIT TRANSACTION
            RETURN
         END
      END
      ELSE IF @type = 4 BEGIN
         EXECUTE @returnValue = inventoryConflict$resolveUnknownSerial @id, @reason
         IF @returnValue != 0 BEGIN
            ROLLBACK TRANSACTION @tranName
            COMMIT TRANSACTION
            RETURN
         END
      END
      -- Next counter
      SET @j = @j + 1
   END
   -- Increment counter
   SELECT @i = @i + 1
END

-- Commit transaction
COMMIT TRANSACTION
END
'
)

IF EXISTS(SELECT 1 FROM sysobjects WHERE name = 'receiveListItem$afterUpdate' AND objectproperty(id, 'ExecIsUpdateTrigger' ) = 1) 
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'TRIGGER receiveListItem$afterUpdate
ON     ReceiveListItem
WITH ENCRYPTION
AFTER  UPDATE
AS
BEGIN
DECLARE @msg nvarchar(255)         -- used to preformat error message
DECLARE @msgTag nvarchar(255)      -- used to hold first part of error message header
DECLARE @msgUpdate nvarchar(4000)  -- used to hold the updated fields
DECLARE @tranName nvarchar(255)    -- used to hold name of savepoint
DECLARE @listName nchar(10)
DECLARE @serialNo nvarchar(32)
DECLARE @rowVersion rowversion
DECLARE @returnDate datetime
DECLARE @returnValue int
DECLARE @auditAction int
DECLARE @rowCount int
DECLARE @status int
DECLARE @listId int
DECLARE @error int
DECLARE @i int
DECLARE @tbl1 table (RowNo int identity(1,1), ListId int)

SET @rowCount = @@rowcount
IF @rowCount = 0 RETURN

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=T''
SET @tranName = object_name(@@procid) + CAST(trigger_nestlevel(@@procid) as nvarchar(2))

-- Begin the transaction
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

-- Get the caller login from the spidLogin table
IF len(dbo.string$GetSpidLogin()) = 0 BEGIN
   SET @msg = ''Login not found for auditing purposes.'' + @msgTag + ''>''
   EXECUTE error$raise @msg, 0, @tranName
   RETURN
END

-- Make sure that no medium appears active more than once
IF EXISTS
   (
   SELECT 1
   FROM   ReceiveListItem
   WHERE  MediumId IN (SELECT MediumId FROM Inserted) AND Status != 1 AND Status != 512
   GROUP  BY MediumId
   HAVING count(*) > 1
   )
BEGIN
   SET @msg = ''Medium may not actively appear on more than one receive list'' + @msgTag + ''>''
   EXECUTE error$raise @msg, 0, @tranName
   RETURN
END

-- Audit is only necessary when there is one item being updated.  Multiple
-- items being updated means that an action was performed on the list as
-- a whole; the list audit record will suffice.
IF @rowCount = 1 BEGIN
   -- Reset update message
   SET @msgUpdate = ''''
   -- List name
   SELECT @listName = ListName
   FROM   ReceiveList
   WHERE  ListId = (SELECT ListId FROM Inserted)
   IF @@rowCount > 0 BEGIN
      -- Serial number
      SELECT @serialNo = m.SerialNo
      FROM   Inserted i
      JOIN   Medium m
        ON   m.MediumId = i.MediumId
      -- Status updated
      SELECT @status = i.Status
      FROM   Inserted i
      JOIN   Deleted d
        ON   d.ItemId = i.ItemId
      WHERE  i.Status != d.Status
      IF @@rowCount > 0 BEGIN
         IF @status = 1 BEGIN
            SET @msgUpdate = ''Medium '' + @serialNo + '' removed from list''
            SET @auditAction = 5
         END
         ELSE IF @status = 16 BEGIN
            SET @msgUpdate = ''Medium '' + @serialNo + '' verified (I)''
            SET @auditAction = 10
         END
         ELSE IF @status = 256 BEGIN
            SET @msgUpdate = ''Medium '' + @serialNo + '' verified (II)''
            SET @auditAction = 10
         END
      END
   END
   -- Insert audit record
   IF len(coalesce(@msgUpdate,'''')) > 0 BEGIN
      INSERT XReceiveListItem
      (
         Object, 
         Action, 
         Detail, 
         Login
      )
      VALUES
      (
         @listName, 
         @auditAction, 
         @msgUpdate, 
         dbo.string$GetSpidLogin()
      )
      SET @error = @@error
      IF @error != 0 BEGIN
         SET @msg = ''Error encountered while inserting receive list item audit record.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
         EXECUTE error$raise @msg, @error, @tranName
         RETURN
      END
   END
END

-- Collect the lists into the table
INSERT @tbl1 (ListId)
SELECT DISTINCT ListId FROM Inserted

-- For each list in the update where an item was updated to a status other 
-- than removed, make sure that the discrete list status is equal to 
-- the (translated) lowest status among its non-removed items.
SET @i = 1
WHILE 1 = 1 BEGIN
   SELECT @listId = i.ListId,
          @rowVersion = rl.RowVersion
   FROM   Inserted i
   JOIN   Deleted d
     ON   d.ItemId = i.ItemId
   JOIN   ReceiveList rl
     ON   rl.ListId = i.ListId
   WHERE  i.Status != 1 AND  -- power(2,0)
          d.Status != i.Status AND
          i.ListId = (SELECT ListId FROM @tbl1 WHERE RowNo = @i)
   -- Break if nothing
   IF @@rowCount = 0 BREAK
   -- Set the status
   EXECUTE @returnValue = receiveList$setStatus @listId, @rowVersion
   IF @returnValue != 0 BEGIN
      ROLLBACK TRANSACTION @tranName
      COMMIT TRANSACTION
      RETURN
   END
   -- Next list
   SET @i = @i + 1
END

-- For each list in the update where an item was updated to removed status, 
-- delete the list if there are no more items on the list.  Otherwise, update
-- the status of the list.
SET @i = 1
WHILE 1 = 1 BEGIN
   SELECT TOP 1 @listId = i.ListId,
          @rowVersion = rl.RowVersion
   FROM   Inserted i
   JOIN   Deleted d
     ON   d.ItemId = i.ItemId
   JOIN   ReceiveList rl
     ON   rl.ListId = i.ListId
   WHERE  i.Status = 1 AND
          d.Status != 1 AND
          i.ListId = (SELECT ListId FROM @tbl1 WHERE RowNo = @i)
   -- Break if nothing
   IF @@rowCount = 0 BREAK
   -- If tapes still exist actively on the list, update its status; otherwise delete the list.
   IF EXISTS(SELECT 1 FROM ReceiveListItem WHERE ListId = @listId AND Status != 1) BEGIN
      EXECUTE @returnValue = receiveList$setStatus @listId, @rowVersion
   END
   ELSE BEGIN
      EXECUTE @returnValue = receiveList$del @listId, @rowVersion, 1   -- Allow deletion even if transmitted
   END
   IF @returnValue != 0 BEGIN
      ROLLBACK TRANSACTION @tranName
      COMMIT TRANSACTION
      RETURN
   END
   -- Next list
   SET @i = @i + 1
END

-- Commit
COMMIT TRANSACTION
END
'
)

IF EXISTS(SELECT 1 FROM sysobjects WHERE name = 'sealedCase$afterDelete' AND objectproperty(id, 'ExecIsDeleteTrigger' ) = 1) 
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'TRIGGER sealedCase$afterDelete
ON     SealedCase
WITH ENCRYPTION
AFTER  DELETE
AS
BEGIN
DECLARE @msg nvarchar(255)         -- used to preformat error message
DECLARE @msgTag nvarchar(255)      -- used to hold first part of error message header
DECLARE @tranName nvarchar(255)    -- used to hold name of savepoint
DECLARE @serialNo nvarchar(32)
DECLARE @tbl1 table (RowNo int identity(1,1), SerialNo nvarchar(32))
DECLARE @tbl2 table (RowNo int identity (1,1), Id int)
DECLARE @returnValue int
DECLARE @error int
DECLARE @id int
DECLARE @i int
DECLARE @j int

SET NOCOUNT ON

IF @@rowcount = 0 RETURN
SET @i = 1

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=T''
SET @tranName = object_name(@@procid) + CAST(trigger_nestlevel(@@procid) as nvarchar(2))

-- Begin the transaction
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

-- Get the caller login from the spidLogin table
IF len(dbo.string$GetSpidLogin()) = 0 BEGIN
   SET @msg = ''Caller login not found in spid login table.'' + @msgTag + ''>''
   EXECUTE error$raise @msg, 0, @tranName
   RETURN
END

-- Get all the deleted media
INSERT @tbl1 (SerialNo)
SELECT SerialNo
FROM   Deleted
ORDER  BY SerialNo ASC

-- Audit each deletion
WHILE 1 = 1 BEGIN
   SELECT @serialNo = SerialNo
   FROM   @tbl1
   WHERE  RowNo = @i
   IF @@rowcount = 0 BREAK
   INSERT XSealedCase (Object, Action, Detail, Login)
   VALUES(@serialNo, 3, ''Sealed case deleted'', dbo.string$GetSpidLogin())
   SET @error = @@error
   IF @error != 0 BEGIN
      SET @msg = ''Error inserting a row into the sealed case audit table.'' + @msgTag + '';Error='' + cast(@error as nvarchar(9)) + ''>''
      EXECUTE error$raise @msg, @error, @tranName
      RETURN
   END
   -- Resolve type conflicts
   DELETE FROM @tbl2
   INSERT @tbl2 (Id)   -- type
   SELECT c.Id
   FROM   InventoryConflict c
   JOIN   InventoryConflictObjectType o
     ON   o.Id = c.Id
   WHERE  c.SerialNo = @serialNo
   SELECT @j = min(RowNo) FROM @tbl2
   WHILE 1 = 1 BEGIN
      SELECT @id = Id
      FROM   @tbl2
      WHERE  RowNo = @j
      IF @@rowcount = 0 BREAK
      EXECUTE @returnValue = inventoryConflict$resolveObjectType @id, 3
      IF @returnValue != 0 BEGIN
         ROLLBACK TRANSACTION @tranName
         COMMIT TRANSACTION
         RETURN
      END
      SET @j = @j + 1
   END
   -- Next counter
   SET @i = @i + 1
END

-- Commit transaction
COMMIT TRANSACTION
END
'
)

IF EXISTS(SELECT 1 FROM sysobjects WHERE name = 'sealedCase$afterInsert' AND objectproperty(id, 'ExecIsInsertTrigger' ) = 1) 
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'TRIGGER sealedCase$afterInsert
ON     SealedCase
WITH ENCRYPTION
AFTER  INSERT
AS
BEGIN
DECLARE @msg nvarchar(255)         -- used to preformat error message
DECLARE @msgTag nvarchar(255)      -- used to hold first part of error message header
DECLARE @tranName nvarchar(255)    -- used to hold name of savepoint
DECLARE @rowcount int             -- holds the number of rows in the Deleted table
DECLARE @serialNo nvarchar(32)
DECLARE @rdate nvarchar(10)
DECLARE @notes nvarchar(1000)
DECLARE @audit nvarchar(1000)
DECLARE @returnValue int
DECLARE @hotStatus bit
DECLARE @typeId int
DECLARE @caseId int
DECLARE @error int
DECLARE @id int

SET @rowcount = @@rowcount
IF @rowcount = 0 RETURN

-- Make sure we do not have a batch insert
IF @rowcount > 1 BEGIN
   SET @msg = ''Batch insert into sealed case table not allowed.'' + @msgTag + ''>''
   EXECUTE error$raise @msg, 0
   RETURN
END

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=T''
SET @tranName = object_name(@@procid) + CAST(trigger_nestlevel(@@procid) as nvarchar(2))

-- Begin the transaction
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

-- Get the caller login from the spidLogin table
IF len(dbo.string$GetSpidLogin()) = 0 BEGIN
   SET @msg = ''Caller login not found in spid login table.'' + @msgTag + ''>''
   EXECUTE error$raise @msg, 0, @tranName
   RETURN
END

-- Get the inserted data
SELECT @serialNo = SerialNo,
       @caseId = CaseId,
       @rdate = coalesce(convert(nvarchar(10),ReturnDate,120),''NONE''),
       @hotStatus = HotStatus,
       @typeId = TypeId,
       @notes = Notes
FROM   Inserted

-- Verify that there is no medium with that serial number
IF EXISTS(SELECT 1 FROM Medium WHERE SerialNo = @serialNo) BEGIN
   SET @msg = ''A medium with serial number '' + @serialNo + '' already exists.'' + @msgTag + ''>''
   EXECUTE error$raise @msg, 0, @tranName
   RETURN
END

-- Insert audit record
SELECT @audit = ''Sealed case created'' + case len(@rdate) when 0 then '''' else '' with a return date of '' + @rdate end
INSERT XSealedCase (Object, Action, Detail, Login)
VALUES(@serialNo, 1, @audit, dbo.string$GetSpidLogin())
SET @error = @@error
IF @error != 0 BEGIN
   SET @msg = ''Error inserting a row into the sealed case audit table.'' + @msgTag + '';Error='' + cast(@error as nvarchar(9)) + ''>''
   EXECUTE error$raise @msg, @error, @tranName
   RETURN
END

-- Remove any unknown medium inventory discrepancy that may exist
WHILE 1 = 1 BEGIN
   SELECT @id = c.Id
   FROM   InventoryConflict c
   JOIN   InventoryConflictUnknownSerial s
     ON   s.Id = c.Id
   WHERE  SerialNo = @serialNo
   IF @@rowcount = 0 BREAK
   EXECUTE @returnValue = inventoryConflict$resolveUnknownSerial @id, 1
   IF @returnValue != 0 BEGIN
      ROLLBACK TRANSACTION @tranName   
      COMMIT TRANSACTION
      RETURN
   END
END

-- Commit transaction
COMMIT TRANSACTION
END
'
)

IF EXISTS(SELECT 1 FROM sysobjects WHERE name = 'sealedCase$afterUpdate' AND objectproperty(id, 'ExecIsUpdateTrigger' ) = 1) 
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'TRIGGER sealedCase$afterUpdate
ON     SealedCase
WITH ENCRYPTION
AFTER  UPDATE
AS
BEGIN
DECLARE @msg nvarchar(255)         -- used to preformat error message
DECLARE @msgTag nvarchar(255)      -- used to hold first part of error message header
DECLARE @tranName nvarchar(255)    -- used to hold name of savepoint
DECLARE @audit nvarchar(4000)
DECLARE @serialNo nvarchar(32)
DECLARE @oldSerial nvarchar(32)
DECLARE @rdate nvarchar(10)
DECLARE @notes nvarchar(1000)
DECLARE @returnValue int
DECLARE @mid int
DECLARE @hot bit
DECLARE @tid int
DECLARE @cid int
DECLARE @error int
DECLARE @tblM table (RowNo int identity (1,1), Message nvarchar(1000))
DECLARE @tblC table (RowNo int identity (1,1), SerialNo nvarchar(32))
DECLARE @tbl1 table (RowNo int identity (1,1), Id int, Type int, Reason int) -- 1:Location, 2:Account, 3:ObjectType, 4:UnknownSerial
DECLARE @tbl2 table (RowNo int identity (1,1), MediumId int)
DECLARE @reason int
DECLARE @type int
DECLARE @id int
DECLARE @i int
DECLARE @j int

IF @@rowcount = 0 RETURN
SET @i = 1

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=T''
SET @tranName = object_name(@@procid) + CAST(trigger_nestlevel(@@procid) as nvarchar(2))

-- Get the caller login from the spidLogin table
IF len(dbo.string$GetSpidLogin()) = 0 BEGIN
   SET @msg = ''Caller login not found in spid login table.'' + @msgTag + ''>''
   EXECUTE error$raise @msg, 0
   RETURN
END

-- Begin the transaction
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

-- Gather the media id numbers into the table
INSERT @tblC (SerialNo)
SELECT SerialNo
FROM   Inserted
ORDER  BY SerialNo Asc

WHILE 1 = 1 BEGIN
   SELECT @serialNo = SerialNo,
          @cid = CaseId,
          @rdate = coalesce(convert(nvarchar(10),ReturnDate,120),''NONE''),
          @hot = HotStatus,
          @tid = TypeId,
          @notes = Notes
   FROM   Inserted
   WHERE  SerialNo = (SELECT SerialNo FROM @tblC WHERE RowNo = @i)
   IF @@rowcount = 0 BREAK
   -- Reset the message table
   DELETE FROM @tblM
   -- Case type
   IF EXISTS(SELECT 1 FROM Deleted WHERE CaseId = @cid AND TypeId != @tid) BEGIN
      INSERT @tblM (Message) SELECT ''Case type changed to '' + (SELECT TypeName FROM MediumType WHERE TypeId = @tid)
   END
   -- Return date
   IF EXISTS(SELECT 1 FROM Deleted WHERE CaseId = @cid AND coalesce(convert(nvarchar(10),ReturnDate,120),''NONE'') != @rdate) BEGIN
      INSERT @tblM (Message) SELECT ''Return date changed to '' + @rdate
   END
   -- Hot site status
   IF EXISTS (SELECT 1 FROM Deleted WHERE CaseId = @cid AND HotStatus != @hot) BEGIN
      INSERT @tblM (Message) SELECT case @hot when 1 then ''Case regarded as at hot site'' else ''Case no longer regarded as at hot site'' end
   END
   -- Serial number
   IF EXISTS (SELECT 1 FROM Deleted WHERE CaseId = @cid AND SerialNo != @serialNo) BEGIN
      INSERT @tblM (Message) SELECT ''Serial number changed to '' + @serialNo
   END
   -- Initialize variables used for auditing
   SELECT @j = min(RowNo) FROM @tblM
   SELECT @oldSerial = SerialNo FROM Deleted WHERE CaseId = @cid
   -- Insert audit records
   WHILE 1 = 1 BEGIN
      SELECT @audit = Message
      FROM   @tblM
      WHERE  RowNo = @j
      IF @@rowcount = 0 BREAK
      INSERT XSealedCase (Object, Action, Detail, Login)
      VALUES(@oldSerial, 2, @audit, dbo.string$GetSpidLogin())
      SET @error = @@error
      IF @error != 0 BEGIN
         SET @msg = ''Error inserting a row into the sealed case audit table.'' + @msgTag + '';Error='' + cast(@error as nvarchar(9)) + ''>''
         EXECUTE error$raise @msg, @error, @tranName
         RETURN
      END
      -- Counter
      SELECT @j = @j + 1
   END
   ----------------------------------------------------------------------------
   -- Inventory conflict resolutions (type and unknown serial)
   ----------------------------------------------------------------------------
   DELETE FROM @tbl1
   -- Object type resolutions
   IF EXISTS (SELECT 1 FROM Inserted i JOIN Deleted d ON d.CaseId = i.CaseId WHERE i.CaseId = @cid AND i.SerialNo != d.SerialNo) BEGIN
      INSERT @tbl1 (Id, Type, Reason)
      SELECT c.Id, 3, 2
      FROM   InventoryConflict c
      JOIN   InventoryConflictObjectType o
        ON   o.Id = c.Id
      WHERE  c.SerialNo = @oldSerial
   END
   ELSE IF EXISTS (SELECT 1 FROM Inserted i JOIN Deleted d ON d.CaseId = i.CaseId WHERE i.CaseId = @cid AND i.TypeId != d.TypeId) BEGIN
      INSERT @tbl1 (Id, Type, Reason)
      SELECT c.Id, 3, 1
      FROM   InventoryConflict c
      JOIN   InventoryConflictObjectType o
        ON   o.Id = c.Id
      JOIN   Inserted i
        ON   i.TypeId = o.TypeId
      WHERE  c.SerialNo = @oldSerial AND i.CaseId = @cid
   END
   -- Unknown serial resolutions
   IF EXISTS (SELECT 1 FROM Inserted i JOIN Deleted d ON d.CaseId = i.CaseId WHERE i.CaseId = @cid AND i.SerialNo != d.SerialNo) BEGIN
      INSERT @tbl1 (Id, Type, Reason)
      SELECT c.Id, 4, 2
      FROM   InventoryConflict c
      JOIN   InventoryConflictUnknownSerial s
        ON   s.Id = c.Id
      WHERE  c.SerialNo = @serialNo
   END
   -- Cycle through the discrepancies
   SELECT @j = min(RowNo) FROM @tbl1
   WHILE 1 = 1 BEGIN
      SELECT @id = Id, @type = Type, @reason = Reason
      FROM   @tbl1
      WHERE  RowNo = @j
      IF @@rowcount = 0 BREAK
      -- Resolve conflicts
      IF @type = 3 BEGIN
         EXECUTE @returnValue = inventoryConflict$resolveObjectType @id, @reason
         IF @returnValue != 0 BEGIN
            ROLLBACK TRANSACTION @tranName
            COMMIT TRANSACTION
            RETURN
         END
      END
      ELSE IF @type = 4 BEGIN
         EXECUTE @returnValue = inventoryConflict$resolveUnknownSerial @id, @reason
         IF @returnValue != 0 BEGIN
            ROLLBACK TRANSACTION @tranName
            COMMIT TRANSACTION
            RETURN
         END
      END
      -- Next counter
      SET @j = @j + 1
   END
   -- If the hot status has been modified, we must modify all the media that lay within the case accordingly.
   IF EXISTS (SELECT 1 FROM Deleted WHERE CaseId = @cid AND HotStatus != @hot) BEGIN
      DELETE @tbl2
      INSERT @tbl2 (MediumId)
      SELECT MediumId
      FROM   MediumSealedCase
      WHERE  CaseId = @cid
      SELECT @j = min(RowNo) FROM @tbl2
      WHILE 1 = 1 BEGIN
         SELECT @mid = MediumId
         FROM   @tbl2
         WHERE  RowNo = @j
         IF @@rowcount = 0 BREAK
         UPDATE Medium
         SET    HotStatus = @hot
         WHERE  MediumId = @mid
         SET @error = @@error
         IF @error != 0 BEGIN
            SET @msg = ''Error changing field of resident medium after change in sealed case field.'' + @msgTag + '';Error='' + cast(@error as nvarchar(9)) + ''>''
            EXECUTE error$raise @msg, @error, @tranName
            RETURN
         END
         SET @j = @j + 1
      END
   END
   -- Next row
   SET @i = @i + 1
END

-- Commit transaction
COMMIT TRANSACTION
END
'
)

IF EXISTS(SELECT 1 FROM sysobjects WHERE name = 'sendListCase$afterInsert' AND objectproperty(id, 'ExecIsInsertTrigger' ) = 1) 
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'TRIGGER sendListCase$afterInsert
ON     SendListCase
WITH ENCRYPTION
AFTER  INSERT
AS
BEGIN
DECLARE @msg nvarchar(255)        -- used to preformat error message
DECLARE @msgTag nvarchar(255)     -- used to hold first part of error message header
DECLARE @tranName nvarchar(255)   -- used to hold name of savepoint
DECLARE @typeName nvarchar(128)
DECLARE @caseName nvarchar(32)
DECLARE @returnValue int
DECLARE @rowcount int
DECLARE @error int            
DECLARE @id int            

SET @rowcount = @@rowcount
IF @rowcount = 0 RETURN

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=T''
SET @tranName = object_name(@@procid) + CAST(trigger_nestlevel(@@procid) as nvarchar(2))

-- Make sure we do not have a batch insert
IF @rowcount > 1 BEGIN
   SET @msg = ''Batch insert into shipping list case table not allowed.'' + @msgTag + ''>''
   EXECUTE error$raise @msg, 0
   RETURN
END

BEGIN TRANSACTION
SAVE TRANSACTION @tranName

-- Get the caller login from the spidLogin table
IF len(dbo.string$GetSpidLogin()) = 0 BEGIN
   SET @msg = ''Login not found for auditing purposes.'' + @msgTag + ''>''
   EXECUTE error$raise @msg, 0, @tranName
   RETURN
END

-- Select the case name and type from the Inserted table
SELECT @typeName = m.TypeName,
       @caseName = i.SerialNo
FROM   MediumType m
JOIN   Inserted i
  ON   i.TypeId = m.TypeId

-- Make sure that the case does not exist in the sealed case table
IF EXISTS(SELECT 1 FROM SealedCase WHERE SerialNo = @caseName) BEGIN
   SET @msg = ''Sealed case '''''' + @caseName + '''''' already resides at the vault.'' + @msgTag + ''>''
   EXECUTE error$raise @msg, 0, @tranName
   RETURN
END

-- Make sure that the case is only active once
IF EXISTS(SELECT 1 FROM SendListCase WHERE SerialNo = @caseName AND Cleared = 0 AND CaseId != (SELECT CaseId FROM Inserted)) BEGIN
   SET @msg = ''There is already a case named '''''' + @caseName + '''''' on an active shipping list.'' + @msgTag + ''>''
   EXECUTE error$raise @msg, 0, @tranName
   RETURN
END

-- Insert audit record
INSERT XSendListCase (Object, Action, Detail, Login)
VALUES(@caseName, 1, ''Case created, unsealed and of type '' + @typeName, dbo.string$GetSpidLogin())
SET @error = @@error
IF @error != 0 BEGIN
   SET @msg = ''Error encountered while inserting a new shipping list case audit record.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
   EXECUTE error$raise @msg, @error, @tranName
   RETURN
END

-- Resolve unknown serial number inventory conflict
SELECT @id = c.Id
FROM   InventoryConflict c
JOIN   InventoryConflictUnknownSerial s
  ON   s.Id = c.Id
WHERE  c.SerialNo = @caseName
IF @@rowcount != 0 BEGIN
   EXECUTE @returnValue = inventoryConflict$resolveUnknownSerial @id, 1
   IF @returnValue != 0 BEGIN
      ROLLBACK TRANSACTION @tranName
      COMMIT TRANSACTION
      RETURN
   END
END  

COMMIT TRANSACTION
END
'
)

IF EXISTS(SELECT 1 FROM sysobjects WHERE name = 'sendListCase$afterUpdate' AND objectproperty(id, 'ExecIsUpdateTrigger' ) = 1) 
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'TRIGGER sendListCase$afterUpdate
ON     SendListCase
WITH ENCRYPTION
AFTER  UPDATE
AS
BEGIN
DECLARE @msg nvarchar(255)        -- used to preformat error message
DECLARE @msgTag nvarchar(255)     -- used to hold first part of error message header
DECLARE @tranName nvarchar(255)   -- used to hold name of savepoint
DECLARE @caseName nvarchar(32)
DECLARE @rdate nvarchar(10)
DECLARE @serialNo nvarchar(32)
DECLARE @sealed bit
DECLARE @rowcount int             -- holds the number of rows in the Inserted table
DECLARE @cid int
DECLARE @error int            
DECLARE @tid int
DECLARE @returnValue int
DECLARE @tbl1 table (RowNo int identity (1,1), CaseId int)
DECLARE @tbl2 table (RowNo int identity (1,1), Id int)
DECLARE @tblM table (RowNo int identity (1,1), Message nvarchar(1000))
DECLARE @id int
DECLARE @i int
DECLARE @j int

IF @@rowcount = 0 RETURN

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=T''
SET @tranName = object_name(@@procid) + CAST(trigger_nestlevel(@@procid) as nvarchar(2))

-- Begin transaction
BEGIN TRANSACTION
SAVE TRANSACTION @tranName
      
-- Get the caller login from the spidLogin table
IF len(dbo.string$GetSpidLogin()) = 0 BEGIN
   SET @msg = ''Login not found for auditing purposes.'' + @msgTag + ''>''
   EXECUTE error$raise @msg, 0, @tranName
   RETURN
END

-- Collect the updated cases
INSERT @tbl1 (CaseId) 
SELECT DISTINCT CaseId 
FROM   Inserted

-- Insert audit messages
SET @i = 1
WHILE 1 = 1 BEGIN
   SELECT @cid = CaseId,
          @caseName = SerialNo,
          @sealed = Sealed,
          @tid = TypeId,
          @rdate = coalesce(convert(nvarchar(10),ReturnDate,120),''NONE'')
   FROM   Inserted
   WHERE  CaseId = (SELECT isnull(CaseId,-1) FROM @tbl1 WHERE RowNo = @i)
   -- If nothing then break
   IF @@rowcount = 0 BREAK
   -- Reset the message table
   DELETE FROM @tblM
   -- Sealed status
   IF EXISTS (SELECT 1 FROM Deleted WHERE CaseId = @cid AND Sealed != @sealed) BEGIN
      INSERT @tblM (Message) SELECT case @sealed when 1 then ''Case has been sealed'' else ''Case has been unsealed'' end
      -- If sealed, make sure that all tapes in the case are on the same discrete list
      IF @sealed = 1 BEGIN
         IF EXISTS 
            (
            SELECT sli.ListId
            FROM   SendListItemCase slic
            JOIN   SendListItem sli
              ON   sli.ItemId = slic.ItemId
            WHERE  slic.CaseId = @cid and 
                   sli.ListId != (SELECT TOP 1 sli1.ListId 
                                  FROM   SendListItemCase slic1
                                  JOIN   SendListItem sli1
                                  ON     sli1.ItemId = slic1.ItemId
                                  WHERE  slic1.CaseId = @cid)
            )
         BEGIN
            SET @msg = ''Case '' + @caseName + '' may not be sealed because it contains media that belong to different accounts and/or reside on different discrete lists within a composite.'' + @msgTag + ''>''
            EXECUTE error$raise @msg, 0, @tranName
            RETURN
         END
      END
   END
   -- Case type
   IF EXISTS(SELECT 1 FROM Deleted WHERE CaseId = @cid AND TypeId != @tid) BEGIN
      INSERT @tblM (Message) SELECT ''Case type changed to '' + (SELECT TypeName FROM MediumType WHERE TypeId = @tid)
   END
   -- Return date
   IF EXISTS(SELECT 1 FROM Deleted WHERE CaseId = @cid AND coalesce(convert(nvarchar(10),ReturnDate,120),''NONE'') != @rdate) BEGIN
      INSERT @tblM (Message) SELECT ''Return date changed to '' + @rdate
   END
   -- Serial number
   IF EXISTS (SELECT 1 FROM Deleted WHERE CaseId = @cid AND SerialNo != @caseName) BEGIN
      INSERT @tblM (Message) SELECT ''Serial number changed to '' + @caseName + ''''
      -- Make sure name change is legal
      IF EXISTS (SELECT 1 FROM SendListCase WHERE CaseId != @cid AND SerialNo = @caseName AND Cleared = 0) BEGIN
         SELECT @msg = ''Case '' + SerialNo + '' may not have its name changed to '' + @caseName + '' because a case named '' + @caseName + '' already exists on an active shipping list.'' + @msgTag + ''>''
         FROM   Deleted
         WHERE  CaseId = @cid
         EXECUTE error$raise @msg, 0, @tranName
         RETURN
      END
   END
   -- Initialize variables used for auditing
   SELECT @j = min(RowNo) FROM @tblM
   SELECT @serialNo = SerialNo FROM Deleted
   -- Insert audit records
   WHILE 1 = 1 BEGIN
      SELECT @msg = Message
      FROM   @tblM
      WHERE  RowNo = @j
      IF @@rowcount = 0 BREAK
      INSERT XSendListCase (Object, Action, Detail, Login)
      VALUES(@serialNo, 2, @msg, dbo.string$GetSpidLogin())
      SET @error = @@error
      IF @error != 0 BEGIN
         SET @msg = ''Error encountered while inserting a new shipping list case audit record.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
         EXECUTE error$raise @msg, @error, @tranName
         RETURN
      END
      -- Counter
      SELECT @j = @j + 1
   END
   -- Resolve any unknown serial number inventory conflicts
   INSERT @tbl2 (Id)
   SELECT c.Id
   FROM   InventoryConflict c
   JOIN   InventoryConflictUnknownSerial s
     ON   s.Id = c.Id
   WHERE  c.SerialNo = @caseName
   -- Cycle through the discrepancies
   SELECT @j = min(RowNo) FROM @tbl2
   WHILE 1 = 1 BEGIN
      SELECT @id = Id
      FROM   @tbl2
      WHERE  RowNo = @j
      IF @@rowcount = 0 BREAK
      -- Resolve conflicts
      EXECUTE @returnValue = inventoryConflict$resolveUnknownSerial @id, 2
      IF @returnValue != 0 BEGIN
         ROLLBACK TRANSACTION @tranName
         COMMIT TRANSACTION
         RETURN
      END
      -- Next counter
      SET @j = @j + 1
   END
   -- Next case
   SELECT @i = @i + 1
END

-- Commit transaction      
COMMIT TRANSACTION
END
'
)

IF EXISTS(SELECT 1 FROM sysobjects WHERE name = 'sendListItem$afterUpdate' AND objectproperty(id, 'ExecIsUpdateTrigger' ) = 1) 
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'TRIGGER sendListItem$afterUpdate
ON     SendListItem
WITH ENCRYPTION
AFTER  UPDATE
AS
BEGIN
DECLARE @msg nvarchar(255)         -- used to preformat error message
DECLARE @msgTag nvarchar(255)      -- used to hold first part of error message header
DECLARE @msgUpdate nvarchar(4000)  -- used to hold the updated fields
DECLARE @tranName nvarchar(255)    -- used to hold name of savepoint
DECLARE @listName nchar(10)
DECLARE @serialNo nvarchar(32)
DECLARE @auditAction int
DECLARE @rowVersion rowversion
DECLARE @returnDate datetime
DECLARE @returnValue int
DECLARE @rowCount int
DECLARE @listId int
DECLARE @status int
DECLARE @error int
DECLARE @i int
DECLARE @tbl1 table (RowNo int identity(1,1), ListId int)

SET @rowCount = @@rowcount
IF @rowCount = 0 RETURN

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=T''
SET @tranName = object_name(@@procid) + CAST(trigger_nestlevel(@@procid) as nvarchar(2))

-- Begin the transaction
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

-- Get the caller login from the spidLogin table
IF len(dbo.string$GetSpidLogin()) = 0 BEGIN
   SET @msg = ''Login not found for auditing purposes.'' + @msgTag + ''>''
   EXECUTE error$raise @msg, 0, @tranName
   RETURN
END

-- Make sure that no medium appears active more than once
IF EXISTS
   (
   SELECT 1 
   FROM   SendListItem
   WHERE  MediumId IN (SELECT MediumId FROM Inserted) AND Status != 1 AND Status != 512
   GROUP  BY MediumId
   HAVING count(*) > 1
   )
BEGIN
   SET @msg = ''Medium may not actively appear on more than one shipping list.'' + @msgTag + ''>''
   EXECUTE error$raise @msg, 0, @tranName
   RETURN
END

-- Audit is only necessary when there is one item being updated.  Multiple
-- items being updated means that an action was performed on the list as
-- a whole; the list audit record will suffice.
IF @rowCount = 1 BEGIN
   -- List name
   SELECT @listName = ListName
   FROM   SendList
   WHERE  ListId = (SELECT ListId FROM Inserted)
   IF @@rowCount > 0 BEGIN
      -- Serial number
      SELECT @serialNo = m.SerialNo
      FROM   Inserted i
      JOIN   Medium m
        ON   m.MediumId = i.MediumId
      -- Status will never be updated at the same time as return date
      SELECT @status = i.Status
      FROM   Inserted i
      JOIN   Deleted d
        ON   d.ItemId = i.ItemId
      WHERE  i.Status != d.Status
      IF @@rowCount > 0 BEGIN
         IF @status = 1 BEGIN -- power(2,0)
            SET @auditAction = 5
            SET @msgUpdate = ''Medium '' + @serialNo + '' removed from list''
         END
         ELSE IF @status = 8 BEGIN -- power(2,3)
            SET @msgUpdate = ''Medium '' + @serialNo + '' verified (I)''
            SET @auditAction = 10
         END
         ELSE IF @status = 256 BEGIN -- power(2,7)
            SET @msgUpdate = ''Medium '' + @serialNo + '' verified (II)''
            SET @auditAction = 10
         END
      END
      ELSE BEGIN
         SELECT @returnDate = i.ReturnDate
         FROM   Inserted i
         JOIN   Deleted d
           ON   d.ItemId = i.ItemId
         WHERE  coalesce(i.ReturnDate,''1900-01-01'') != coalesce(d.ReturnDate,''1900-01-01'')
         IF @@rowCount > 0 BEGIN
            SET @msgUpdate = ''Shipping list item '' + @serialNo + '' return date changed to '' + coalesce(convert(nchar(10),@returnDate,120),''(None)'')
            SET @auditAction = 2
         END
      END
   END
   -- Insert audit record
   IF len(coalesce(@msgUpdate,'''')) > 0 BEGIN
      INSERT XSendListItem
      (
         Object, 
         Action, 
         Detail, 
         Login
      )
      VALUES
      (
         @listName, 
         @auditAction, 
         @msgUpdate, 
         dbo.string$GetSpidLogin()
      )
      SET @error = @@error
      IF @error != 0 BEGIN
         SET @msg = ''Error encountered while inserting a new shipping list item audit record.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
         EXECUTE error$raise @msg, @error, @tranName
         RETURN
      END
   END
END

-- Collect the lists into the table
INSERT @tbl1 (ListId)
SELECT DISTINCT ListId FROM Inserted

-- For each list in the update where an item was updated to a status other 
-- than removed, make sure that the discrete list status is equal to 
-- the (translated) lowest status among its non-removed items.
SET @i = 1
WHILE 1 = 1 BEGIN
   SELECT @listId = i.ListId,
          @rowVersion = sl.RowVersion
   FROM   Inserted i
   JOIN   Deleted d
     ON   d.ItemId = i.ItemId
   JOIN   SendList sl
     ON   sl.ListId = i.ListId
   WHERE  i.Status != 1 AND  -- power(2,0)
          d.Status != i.Status AND
          i.ListId = (SELECT ListId FROM @tbl1 WHERE RowNo = @i)
   -- Break if nothing
   IF @@rowCount = 0 BREAK
   -- Set the status
   EXECUTE @returnValue = sendList$setStatus @listId, @rowVersion
   IF @returnValue != 0 BEGIN
      ROLLBACK TRANSACTION @tranName
      COMMIT TRANSACTION
      RETURN
   END
   -- Next list
   SET @i = @i + 1
END

-- For each list in the update where an item was updated to removed status, 
-- delete the list if there are no more items on the list.  Otherwise, update
-- the status of the list.
SET @i = 1
WHILE 1 = 1 BEGIN
   SELECT @listId = i.ListId,
          @rowVersion = sl.RowVersion
   FROM   Inserted i
   JOIN   Deleted d
     ON   d.ItemId = i.ItemId
   JOIN   SendList sl
     ON   sl.ListId = i.ListId
   WHERE  i.Status = 1 AND  -- power(2,0)
          d.Status != 1 AND -- power(2,0)
          i.ListId = (SELECT ListId FROM @tbl1 WHERE RowNo = @i)
   -- Break if nothing
   IF @@rowCount = 0 BREAK
   -- If tapes still exist actively on the list, update its status; otherwise delete the list.
   IF EXISTS (SELECT 1 FROM SendListItem WHERE ListId = @listId AND Status != 1) BEGIN -- power(2,0)
      EXECUTE @returnValue = sendList$setStatus @listId, @rowVersion
   END
   ELSE BEGIN
      EXECUTE @returnValue = sendList$del @listId, @rowVersion
   END
   -- Evaluate the return value
   IF @returnValue != 0 BEGIN
      ROLLBACK TRANSACTION @tranName
      COMMIT TRANSACTION
      RETURN
   END
   -- Next list
   SET @i = @i + 1
END

-- Commit
COMMIT TRANSACTION
END
'
)

IF EXISTS(SELECT 1 FROM sysobjects WHERE name = 'sendListItemCase$afterInsert' AND objectproperty(id, 'ExecIsInsertTrigger' ) = 1) 
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'TRIGGER sendListItemCase$afterInsert
ON     SendListItemCase
WITH ENCRYPTION
AFTER  INSERT
AS
BEGIN
DECLARE @msg nvarchar(255)        -- used to preformat error message
DECLARE @msgTag nvarchar(255)     -- used to hold first part of error message header
DECLARE @tranName nvarchar(255)   -- used to hold name of savepoint
DECLARE @caseName nvarchar(32)    -- holds the name of the case
DECLARE @serialNo nvarchar(32)    -- holds the serial number of the medium
DECLARE @listName nchar(10)       -- name of the send list
DECLARE @rowCount int             -- holds the number of rows in the Inserted table
DECLARE @listId int            
DECLARE @error int            

SET @rowCount = @@rowcount
IF @rowCount = 0 RETURN

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=T''
SET @tranName = object_name(@@procid) + CAST(trigger_nestlevel(@@procid) as nvarchar(2))

BEGIN TRANSACTION
SAVE TRANSACTION @tranName

-- Make sure we do not have a batch insert
IF @rowCount > 1 BEGIN
   SET @msg = ''Batch insert into shipping list item case table not allowed.'' + @msgTag + ''>''
   EXECUTE error$raise @msg, 0, @tranName
   RETURN
END

-- Get the caller login from the spidLogin table
IF len(dbo.string$GetSpidLogin()) = 0 BEGIN
   SET @msg = ''Login not found for auditing purposes.'' + @msgTag + ''>''
   EXECUTE error$raise @msg, 0, @tranName
   RETURN
END

-- Get information on the item inserted
SELECT @serialNo = m.SerialNo,
       @listName = sl.ListName,
       @caseName = c.SerialNo,
       @listId = sli.ListId
FROM   Medium m
JOIN   SendListItem sli
  ON   sli.MediumId = m.MediumId
JOIN   SendList sl
  ON   sl.ListId = sli.ListId
JOIN   Inserted i
  ON   i.ItemId = sli.ItemId
JOIN   SendListCase c
  ON   c.CaseId = i.CaseId
WHERE  sli.ItemId = (SELECT ItemId FROM Inserted)

-- If the case is sealed, it cannot be placed on any other discrete list, even if it is within the composite
SELECT TOP 1 @listName = sl.ListName
FROM   SendListItemCase slic
JOIN   SendListItem sli
  ON   sli.ItemId = slic.ItemId
JOIN   SendListCase slc
  ON   slc.CaseId = slic.CaseId
JOIN   SendList sl
  ON   sl.ListId = sli.ListId
WHERE  sli.ListId != @listId AND slc.Sealed = 1 AND slc.CaseId = (SELECT CaseId FROM Inserted) AND sli.Status not in (1,512)
IF @@rowcount != 0 BEGIN
   SET @msg = ''Medium '' + @serialNo + '' may not be added to sealed case '' + @caseName + ''w because sealed case currently resides on active discrete list '' + @listName + ''.  A sealed case may only reside on a single discrete list.'' + @msgTag + ''>''
   EXECUTE error$raise @msg, 0, @tranName
   RETURN
END

-- Insert audit record
INSERT XSendListItem
(
   Object, 
   Action, 
   Detail, 
   Login
)
VALUES
(
   @listName, 
   4, 
   ''Medium '' + @serialNo + '' inserted into case '' + @caseName, 
   dbo.string$GetSpidLogin()
)
SET @error = @@error
IF @error != 0 BEGIN
   SET @msg = ''Error encountered while inserting a new shipping list item case audit record.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
   EXECUTE error$raise @msg, @error, @tranName
   RETURN
END

COMMIT TRANSACTION
END
'
)

IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'barCodePattern$createLiteral')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.barCodePattern$createLiteral
(
   @serialNo nvarchar(256),
   @mediumType nvarchar(256) = '''',
   @accountName nvarchar(256) = '''',
   @lastLiteral bit = 0
)
WITH ENCRYPTION
AS
BEGIN
DECLARE @msg as nvarchar(255)        -- used to preformat error message
DECLARE @msgTag as nvarchar(255)     -- used to hold first part of error message header
DECLARE @tranName as nvarchar(255)   -- used to hold name of savepoint
DECLARE @x as nvarchar(255)
DECLARE @y as nvarchar(255)
DECLARE @returnValue int
DECLARE @accountId int
DECLARE @typeId int
DECLARE @error int
DECLARE @pos int
DECLARE @i int

SET NOCOUNT ON

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=P''
SET @tranName = object_name(@@procid) + CAST(@@nestlevel as nvarchar(2))

-- Adjust strings
SET @serialNo = ltrim(rtrim(isnull(@serialNo,'''')))
SET @mediumType = ltrim(rtrim(isnull(@mediumType,'''')))
SET @accountName = ltrim(rtrim(isnull(@accountName,'''')))

-- If at least one of the parameters is empty, get the defaults
IF len(@mediumType) = 0 OR len(@accountName) = 0 BEGIN
   EXECUTE @returnValue = barCodePattern$getDefaults @serialNo, @x out, @y out
   IF @returnValue != 0 RETURN -100
   IF len(@mediumType) = 0 SET @mediumType = @x
   IF len(@accountName) = 0 SET @accountName = @y
END

-- Get the medium type id
IF len(@mediumType) > 0 BEGIN
   SELECT @typeId = TypeId
   FROM   MediumType
   WHERE  TypeName = @mediumType AND Container = 0
   IF @@rowcount = 0 BEGIN
      SET @msg = ''Medium type not found.'' + @msgTag + ''>''
      RAISERROR(@msg, 16, 1)
      RETURN -100
   END
END

-- Get the account id
IF len(@accountName) > 0 BEGIN
   SELECT @accountId = AccountId
   FROM   Account
   WHERE  AccountName = @accountName
   IF @@rowcount = 0 BEGIN
      SET @msg = ''Account not found.'' + @msgTag + ''>''
      RAISERROR(@msg, 16, 1)
      RETURN -100
   END
END

-- Begin transaction
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

-- Set current positions to negative if there are no negative positions
IF NOT EXISTS (SELECT 1 FROM BarCodePattern WHERE Position = (SELECT min(Position) FROM BarCodePattern) AND Position < 0) BEGIN
   UPDATE BarCodePattern
   SET    Position = -1 * Position
   SET @error = @@error
   IF @error != 0 BEGIN
      ROLLBACK TRANSACTION @tranName
      COMMIT TRANSACTION
      SET @msg = ''Error encountered while inserting bar code literal; could not make positions negative.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
      RAISERROR(@msg, 16, 1)
      RETURN -100
   END
END

-- If the pattern exists, update its medium type and account name.  Otherwise,
-- bump the position of all the other bar codes and prepend this literal to the list.
IF EXISTS (SELECT 1 FROM BarCodePattern WHERE Pattern = @serialNo) BEGIN
   UPDATE BarCodePattern
   SET    TypeId = @typeId, AccountId = @accountId
   WHERE  Pattern = @serialNo
END
ELSE BEGIN
   -- Get the position
   SELECT @pos = count(*) FROM BarCodePattern WHERE Position > 0
   -- Insert the pattern
   INSERT BarCodePattern (Pattern, Position, TypeId, AccountId, Notes)
   VALUES (@serialNo, @pos + 1, @typeId, @accountId, '''')
END

-- Evaluate error
SET @error = @@error
IF @error != 0 BEGIN
   ROLLBACK TRANSACTION @tranName
   COMMIT TRANSACTION
   SET @msg = ''Error encountered while creating bar code literal.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
   RAISERROR(@msg, 16, 1)
   RETURN -100
END

-- If this is the last literal, reset the positions of those patterns currently negative
IF @lastLiteral = 1 BEGIN
   -- Get the number of patterns currently negative
   SELECT @i = count(*) FROM BarCodePattern WHERE Position > 0
   -- Adjust the negative number to their new positive values
   UPDATE BarCodePattern
   SET    Position = abs(Position) + @i
   WHERE  Position < 0
   -- Evaluate error
   SET @error = @@error
   IF @error != 0 BEGIN
      ROLLBACK TRANSACTION @tranName
      COMMIT TRANSACTION
      SET @msg = ''Error encountered while creating bar code literal; could not restore negative positions.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
      RAISERROR(@msg, 16, 1)
      RETURN -100
   END
END

-- Commit transaction
COMMIT TRANSACTION
RETURN 0
END
'
)

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'tabPageDefault$upd')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.tabPageDefault$upd
(
   @id int,
   @login nvarchar(32),
   @tabPage int
)
WITH ENCRYPTION
AS
BEGIN
DECLARE @msg nvarchar(255)        -- used to preformat error message
DECLARE @msgTag nvarchar(255)     -- used to hold first part of error message header
DECLARE @tranName nvarchar(255)   -- used to hold name of savepoint
DECLARE @operator int
DECLARE @error int

SET NOCOUNT ON

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=P''
SET @tranName = object_name(@@procid) + CAST(@@nestlevel as nvarchar(2))

-- Get the operator
SELECT @operator = OperatorId 
FROM   Operator 
WHERE  Login = @login

-- Begin the transaction
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

IF EXISTS (SELECT 1 FROM TabPageDefault WHERE Id = @id AND Operator = @operator) BEGIN
   UPDATE TabPageDefault
   SET    TabPage = @tabPage
   WHERE  Id = @id AND Operator = @operator
   SET @error = @@error
   IF @error != 0 BEGIN
      ROLLBACK TRANSACTION @tranName
      COMMIT TRANSACTION
      SET @msg = ''Error encountered while updating tab page default.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
      EXECUTE error$raise @msg, @error
      RETURN -100
   END
END
ELSE BEGIN
   INSERT TabPageDefault (Id, Operator, TabPage)
   VALUES (@id, @operator, @tabPage)
   SET @error = @@error
   IF @error != 0 BEGIN
      ROLLBACK TRANSACTION @tranName
      COMMIT TRANSACTION
      SET @msg = ''Error encountered while inserting tab page default.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
      EXECUTE error$raise @msg, @error
      RETURN -100
   END
END

-- Commit the transaction
COMMIT TRANSACTION
RETURN 0
END
'
)

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'tabPageDefault$get')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.tabPageDefault$get
(
   @id int,
   @login nvarchar(32)
)
WITH ENCRYPTION
AS
BEGIN
DECLARE @returnValue int

SET NOCOUNT ON

SELECT @returnValue = TabPage
FROM   TabPageDefault
WHERE  Id = @id AND Operator = (SELECT OperatorId FROM Operator WHERE Login = @login)

-- Select the value for ExecuteScalar
SELECT isnull(@returnValue, 1)

END
'
)

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'receiveListItem$add')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.receiveListItem$add
(
   @serialNo nvarchar(32),      -- medium serial number
   @notes nvarchar(1000),       -- any notes to attach to the medium
   @listId int,                 -- list to which item should be added
   @nestLevel int = 1           -- should never be supplied from the application
)
WITH ENCRYPTION
AS
BEGIN
DECLARE @msg as nvarchar(255)      -- used to preformat error message
DECLARE @msgTag as nvarchar(255)    -- used to hold first part of error message header
DECLARE @tranName as nvarchar(255)   -- used to hold name of savepoint
DECLARE @error as int
DECLARE @caseId as int
DECLARE @location as bit
DECLARE @priorId as int
DECLARE @mediumId as int
DECLARE @accountId as int
DECLARE @listStatus as int
DECLARE @listAccount as int
DECLARE @lastMedium as int
DECLARE @returnValue as int
DECLARE @priorList as int
DECLARE @priorStatus as int
DECLARE @priorVersion as rowversion
DECLARE @listName as nchar(10)
DECLARE @status as int

SET NOCOUNT ON

-- Tweak parameters
SET @serialNo = ltrim(rtrim(@serialNo))
SET @notes = ltrim(rtrim(@notes))

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=P''
SET @tranName = object_name(@@procid) + CAST(@@nestlevel as nvarchar(2))

-- Verify that the list exists
SELECT @listAccount = AccountId,
       @listStatus = Status
FROM   ReceiveList
WHERE  ListId = @listId
IF @@rowCount = 0 BEGIN
   SET @msg = ''Receive list not found.'' + @msgTag + ''>''
   RAISERROR(@msg,16,1)
   RETURN -100
END

-- Make sure that the medium is not already on the list.  If it does, just return.
IF EXISTS 
   (
   SELECT 1 
   FROM   ReceiveListItem rli 
   JOIN   Medium m 
     ON   m.MediumId = rli.MediumId 
   WHERE  m.SerialNo = @serialNo AND rli.Status != 1 AND ListId = @listId
   ) 
BEGIN
   RETURN 0
END

-- If submitted then okay...if partially verified and no transmission, then okay.
IF @listStatus != 2  AND NOT (@listStatus = 8 AND EXISTS (SELECT 1 FROM ListStatusProfile WHERE ProfileId = 2 AND Statuses & 4 != 0)) BEGIN
   SET @msg = ''A medium may not be added to a list that has '' + dbo.string$statusName(2,@listStatus) + '' status.'' + @msgTag + ''>''
   RAISERROR(@msg,16,1)
   RETURN -100
END

-- Begin the transaction here in case we have to add a medium
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

-- Get the medium
SELECT @mediumId = m.MediumId,
       @location = m.Location,
       @accountId = m.AccountId,
       @caseId = coalesce(msc.CaseId,0)
FROM   Medium m
LEFT   JOIN MediumSealedCase msc
  ON   msc.MediumId = m.MediumId
WHERE  m.SerialNo = @serialNo

-- If the medium doesn''t exist, then add it
IF @@rowCount = 0 BEGIN
   EXECUTE @returnValue = medium$addDynamic @serialNo, 0, @mediumId OUTPUT
   IF @returnValue != 0 BEGIN
      ROLLBACK TRANSACTION @tranName
      COMMIT TRANSACTION
      RETURN -100
   END
   ELSE BEGIN
      SELECT @mediumId = MediumId,
             @location = Location,
             @accountId = AccountId,
             @caseId = 0
      FROM   Medium
      WHERE  MediumId = @mediumId
   END
END
ELSE BEGIN
   -- Location check
   IF @location = 1 BEGIN
      ROLLBACK TRANSACTION @tranName
      COMMIT TRANSACTION
      SET @msg = ''Medium '''''' + @serialNo + '''''' already resides at the enterprise.'' + @msgTag + ''>''
      RAISERROR(@msg,16,1)
      RETURN -100
   END
   -- Check other lists for the presence of this medium
   SELECT @priorId = rli.ItemId,
          @priorStatus = rli.Status,
          @priorVersion = rli.RowVersion,
          @listName = rl.ListName
   FROM   ReceiveListItem rli
   JOIN   ReceiveList rl
     ON   rl.ListId = rli.ListId
   WHERE  rli.Status NOT IN (1,512) AND rli.MediumId = @mediumId
   IF @@rowcount != 0 BEGIN
      IF EXISTS (SELECT 1 FROM ReceiveList WHERE ListName = @listName AND CompositeId IS NOT NULL) BEGIN
         SELECT @listName = ListName 
         FROM   ReceiveList 
         WHERE  ListId = (SELECT CompositeId FROM ReceiveList WHERE ListName = @listName)
      END
      IF @priorStatus >= 4 BEGIN
         ROLLBACK TRANSACTION @tranName
         COMMIT TRANSACTION
         SET @msg = ''Medium '''''' + @serialNo + '''''' currently resides on active receive list '' + @listName + ''.'' + @msgTag + ''>''
         RAISERROR(@msg,16,1)
         RETURN -100
      END
      ELSE BEGIN
         -- If the prior list is this list or any of the lists under this list
         -- (if it is a composite) then rollback and return.  Otherwise, remove
         -- the medium from the prior list if it is not in a case.  If it is in 
         -- a case, raise error.
         IF @priorId = @listId OR EXISTS(SELECT 1 FROM ReceiveList WHERE ListId = @priorId AND CompositeId = @listId) BEGIN
            ROLLBACK TRANSACTION @tranName
            COMMIT TRANSACTION
            RETURN 0
         END
         ELSE BEGIN
            IF @caseId > 0 BEGIN
               ROLLBACK TRANSACTION @tranName
               COMMIT TRANSACTION
               SET @msg = ''Medium '''''' + @serialNo + '''''' is in a sealed case on active receive list '' + @listName + ''.'' + @msgTag + ''>''
               RAISERROR(@msg,16,1)
               RETURN -100
            END
            ELSE BEGIN
               EXECUTE @returnValue = receiveListItem$remove @priorId, @priorVersion
               IF @returnValue != 0 BEGIN
                  ROLLBACK TRANSACTION @tranName
                  COMMIT TRANSACTION
                  RETURN -100
               END
            END
         END
      END
   END
   -- If the medium has been removed from this list, restore it
   ELSE BEGIN
      SELECT @priorId = rli.ItemId,
             @priorList = rl.ListId
      FROM   ReceiveListItem rli
      JOIN   ReceiveList rl
        ON   rl.ListId = rli.ListId
      WHERE  rli.Status = 1 AND
             rli.MediumId = @mediumId AND
            (rl.ListId = @listId OR coalesce(rl.CompositeId,0) = @listId)
      IF @@rowcount != 0 BEGIN
         UPDATE ReceiveListItem
         SET    Status = 2
         WHERE  ItemId = @priorId
         SET @error = @@error
         IF @error != 0 BEGIN
            ROLLBACK TRANSACTION @tranName
            COMMIT TRANSACTION
            SET @msg = ''Error encountered while restoring item to receive list.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
            EXECUTE error$raise @msg, @error
            RETURN -100
         END
         ELSE IF @caseId > 0
            GOTO RESTORERESTOFCASE
         ELSE
            GOTO ATTACHNOTES
      END
   END
END

-- If the list is a composite, verify that there is a list within the composite
-- that has the same account as the medium.  If the list is discrete, verify
-- that it has the same account as the medium.
IF @listAccount IS NULL BEGIN
   SELECT @listId = ListId,
          @listAccount = AccountId      -- Note that list id is now a discrete list
   FROM   ReceiveList
   WHERE  CompositeId = @listId AND 
          AccountId = @accountId -- medium account
   IF @@rowCount = 0 BEGIN
      ROLLBACK TRANSACTION @tranName
      COMMIT TRANSACTION
      SET @msg = ''No list within the composite has the same account as medium '''''' + @serialNo + ''''''.'' + @msgTag + ''>''
      RAISERROR(@msg,16,1)
      RETURN -100
   END
END
ELSE IF @listAccount != @accountId BEGIN
   ROLLBACK TRANSACTION @tranName
   COMMIT TRANSACTION
   SET @msg = ''List does not have the same account as medium '''''' + @serialNo + ''''''.'' + @msgTag + ''>''
   RAISERROR(@msg,16,1)
   RETURN -100
END

-- Insert the item
INSERT ReceiveListItem
(
   ListId, 
   MediumId
)
VALUES
(
   @listId, 
   @mediumId
)
SET @error = @@error
IF @error != 0 BEGIN
   ROLLBACK TRANSACTION @tranName
   COMMIT TRANSACTION
   SET @msg = ''Error encountered while adding item to existing receive list.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
   EXECUTE error$raise @msg, @error
   RETURN -100
END

-- If the medium is in a sealed case, then all of the other media within the case
-- must be added to the list as well.
RESTORERESTOFCASE:
IF @caseId > 0 AND @nestLevel = 1 BEGIN
   SET @lastMedium = 0
   WHILE 1 = 1 BEGIN
      SELECT TOP 1 @lastMedium = msc.MediumId
      FROM   MediumSealedCase msc
      WHERE  msc.CaseId = @caseId AND
             msc.MediumId != @mediumId AND
             msc.MediumId > @lastMedium
      ORDER BY msc.MediumId asc
      IF @@rowCount = 0
         BREAK
      ELSE BEGIN
         SELECT @serialNo = SerialNo,
                @accountId = AccountId
         FROM   Medium
         WHERE  MediumId = @lastMedium
         -- Make sure that this list or a list within the composite has this account
         SELECT @listId = ListId
         FROM   ReceiveList
         WHERE  AccountId = @accountId AND
               (ListId = @listId OR CompositeId = (SELECT coalesce(CompositeId,0) FROM ReceiveList WHERE ListId = @listId))
         IF @@rowCount = 0 BEGIN
            ROLLBACK TRANSACTION @tranName
            COMMIT TRANSACTION
            SET @msg = ''List with required account number not found for other medium in sealed case.'' + @msgTag + ''>''
            RAISERROR(@msg,16,1)
            RETURN -100
         END
         -- Add the medium
         EXECUTE @returnValue = receiveListItem$add @serialNo, '''', @listId, 2
         IF @returnValue != 0 BEGIN
            ROLLBACK TRANSACTION @tranName
            COMMIT TRANSACTION
            RETURN -100
         END
      END
   END
END

-- If we have notes, attach them to the medium here.  We''''ll do this manually rather than go
-- through medium$upd because to do so would involve unnecessary overhead.
ATTACHNOTES:
IF len(@notes) != 0 BEGIN
   UPDATE Medium
   SET    Notes = @notes
   WHERE  MediumId = @mediumId AND Notes != @notes
   SET @error = @@error
   IF @error != 0 BEGIN
	   ROLLBACK TRANSACTION @tranName
	   COMMIT TRANSACTION
	   SET @msg = ''Error encountered while updating medium notes.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
	   EXECUTE error$raise @msg, @error
	   RETURN -100
   END
END

COMMIT TRANSACTION
RETURN 0
END
'
)

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'receiveListItem$add')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.sendListItemCase$remove
(
   @itemId int,
   @caseId int
)
WITH ENCRYPTION
AS
BEGIN
DECLARE @msg as nvarchar(255)        -- used to preformat error message
DECLARE @msgTag as nvarchar(255)     -- used to hold first part of error message header
DECLARE @tranName as nvarchar(255)   -- used to hold name of savepoint
DECLARE @returnValue as int
DECLARE @rowCount as int
DECLARE @error as int
DECLARE @status as int

SET NOCOUNT ON

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=P''
SET @tranName = object_name(@@procid) + CAST(@@nestlevel as nvarchar(2))

-- Verify the status of the item as submitted or verified
SELECT @status = Status
FROM   SendListItem
WHERE  ItemId = @itemId
IF @@rowCount = 0 BEGIN
   SET @msg = ''Send list item not found.'' + @msgTag + ''>''
   RAISERROR(@msg,16,1)
   RETURN -100
END
ELSE IF @status = 1  BEGIN
   SET @msg = ''Cannot remove item from case because it has been removed from the list.'' + @msgTag + ''>''
   RAISERROR(@msg,16,1)
   RETURN -100
END

-- Begin the transaction
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

-- Remove the item from the case
DELETE SendListItemCase
WHERE  ItemId = @itemId AND CaseId = @caseId
SET @error = @@error
IF @error != 0 BEGIN
   ROLLBACK TRANSACTION @tranName
   COMMIT TRANSACTION
   SET @msg = ''Error encountered while removing send list medium from case.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
   EXECUTE error$raise @msg, @error
   RETURN -100
END

-- Commit and return
COMMIT TRANSACTION
RETURN 0
END
'
)

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'inventoryItem$ins')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.inventoryItem$ins
(
   @inventoryId int,
   @serialNo nvarchar(32),
   @typeName nvarchar(128) = '''',
   @returnDate nvarchar(10) = '''',
   @hotStatus bit = 0,
   @notes nvarchar(1000) = ''''
)
WITH ENCRYPTION
AS
BEGIN
DECLARE @msg nvarchar(255)        -- used to preformat error message
DECLARE @msgTag nvarchar(255)     -- used to hold first part of error message header
DECLARE @tranName nvarchar(255)   -- used to hold name of savepoint
DECLARE @account nvarchar(255)
DECLARE @returnValue int
DECLARE @typeId int
DECLARE @error int

SET NOCOUNT ON

-- Tweak parameters
SET @typeId = -1
SET @notes = coalesce(@notes,'''')
SET @serialNo = coalesce(@serialNo,'''')
SET @typeName = coalesce(@typeName,'''')
SET @returnDate = coalesce(@returnDate,'''')

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=P''
SET @tranName = object_name(@@procid) + CAST(@@nestlevel as nvarchar(2))

-- Insert record
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

INSERT InventoryItem (SerialNo, InventoryId)
VALUES(@serialNo, @inventoryId)
SET @error = @@error
IF @error != 0 BEGIN
   ROLLBACK TRANSACTION @tranName
   COMMIT TRANSACTION
   SET @msg = ''Error encountered while inserting new inventory item ('' + @serialNo + '').'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
   EXECUTE error$raise @msg, @error
   RETURN -100
END

-- Insert vault portion if inventory is a vault inventory
IF EXISTS (SELECT 1 FROM Inventory WHERE InventoryId = @inventoryId AND Location = 0) BEGIN
   -- Get the medium type if it exists
   IF len(@typeName) != 0 BEGIN
      SELECT @typeId = TypeId
      FROM   MediumType
      WHERE  TypeName = @typeName
      IF @@rowcount = 0 BEGIN
         ROLLBACK TRANSACTION @tranName
         COMMIT TRANSACTION
         SET @msg = ''Medium type '''''' + @typeName + '''''' unknown.'' + @msgTag + ''>''
         RAISERROR(@msg,16,1)
         RETURN -100
      END
   END
   ELSE BEGIN
      SELECT @typeId = TypeId 
      FROM   Medium
      WHERE  SerialNo = @serialNo
      IF @@rowcount = 0 BEGIN
         EXECUTE @returnValue = barCodePattern$getDefaults @serialNo, @typeName out, @account out
         IF @returnValue != 0 BEGIN
            ROLLBACK TRANSACTION @tranName
            COMMIT TRANSACTION
            RETURN -100
         END
         ELSE BEGIN
            SELECT @typeId = TypeId
            FROM   MediumType
            WHERE  TypeName = @typeName
         END
      END
   END
   -- Insert the vault portion of the item
   INSERT VaultInventoryItem (ItemId, TypeId, HotStatus, ReturnDate, Notes)
   VALUES(scope_identity(), @typeId, @hotStatus, @returnDate, @notes)
   SET @error = @@error
   IF @error != 0 BEGIN
      ROLLBACK TRANSACTION @tranName
      COMMIT TRANSACTION
      SET @msg = ''Error encountered while inserting vault portion of new inventory item ('' + @serialNo + '').'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
      EXECUTE error$raise @msg, @error
      RETURN -100
   END
END

-- Commit the transaction
COMMIT TRANSACTION
RETURN 0
END
'
)

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'sendListCase$getMedia')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.sendListCase$getMedia
(
   @caseName nvarchar(64)
)
WITH ENCRYPTION
AS
BEGIN

SET NOCOUNT ON

SELECT m.MediumId, 
       m.SerialNo, 
       m.Location, 
       m.HotStatus,
       coalesce(convert(nvarchar(10),slc.ReturnDate,120),coalesce(convert(nvarchar(10),m.ReturnDate,120),'''')) as ''ReturnDate'',
       m.Missing, 
       coalesce(convert(nvarchar(19),m.LastMoveDate,120),'''') as ''LastMoveDate'',
       m.BSide, 
       m.Notes,
       a.AccountName, 
       t.TypeName, 
       slc.SerialNo as ''CaseName'', 
       m.RowVersion
FROM   Medium m 
JOIN   Account a 
  ON   a.AccountId = m.AccountId 
JOIN   MediumType t 
  ON   t.TypeId = m.TypeId
JOIN   SendListItem sli
  ON   sli.MediumId = m.MediumId
JOIN   SendListItemCase slic
  ON   slic.ItemId = sli.ItemId
JOIN   SendListCase slc
  ON   slic.CaseId = slc.CaseId
WHERE  slc.SerialNo = @caseName AND slc.Cleared = 0
ORDER  BY m.SerialNo ASC

END
'
)

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'sendListCase$getByName')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.sendListCase$getByName
(
   @caseName nvarchar(32)
)
WITH ENCRYPTION
AS
BEGIN

SET NOCOUNT ON

-- Select the list
SELECT TOP 1 slc.CaseId,
       mt.TypeName,
       slc.SerialNo as ''CaseName'',
       coalesce(convert(nvarchar(10),slc.ReturnDate,120),'''') as ''ReturnDate'',
       slc.Sealed,
       slc.Notes,
       slc.RowVersion
FROM   SendListCase slc
JOIN   MediumType mt
  ON   mt.TypeId = slc.TypeId
WHERE  slc.SerialNo = @caseName AND Cleared = 0

END
'
)

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'auditTrail$clean')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.auditTrail$clean
(
   @auditType int,
   @cleanDate datetime
)
WITH ENCRYPTION
AS
BEGIN

SET NOCOUNT ON

SET @cleanDate = cast(convert(nchar(10), @cleanDate, 120) as datetime)

-- Variables to hold types
DECLARE @ACCOUNT int
DECLARE @SYSTEMACTION int
DECLARE @BARCODEPATTERN int
DECLARE @EXTERNALSITE int
DECLARE @IGNOREDBARCODEPATTERN int
DECLARE @OPERATOR int
DECLARE @SENDLIST int
DECLARE @RECEIVELIST int
DECLARE @DISASTERCODELIST int
DECLARE @INVENTORY int
DECLARE @INVENTORYCONFLICT int
DECLARE @SEALEDCASE int
DECLARE @MEDIUM int
DECLARE @MEDIUMMOVEMENT int
DECLARE @GENERALACTION int

-- Assign constant values
SELECT
@ACCOUNT               = 1,
@SYSTEMACTION          = 2,
@BARCODEPATTERN        = 4,
@EXTERNALSITE          = 8,
@IGNOREDBARCODEPATTERN = 16,
@OPERATOR              = 32,
@SENDLIST              = 64,
@RECEIVELIST           = 128,
@DISASTERCODELIST      = 256,
@INVENTORY             = 512,
@INVENTORYCONFLICT     = 1024,
@SEALEDCASE            = 2048,
@MEDIUM                = 4096,
@MEDIUMMOVEMENT        = 8192,
@GENERALACTION         = 16384

-- Delete records
IF @auditType = @ACCOUNT BEGIN
   DELETE XAccount
   WHERE  Date < @cleanDate
END
ELSE IF @auditType = @SYSTEMACTION BEGIN
   DELETE XSystemAction
   WHERE  Date < @cleanDate
END
ELSE IF @auditType = @BARCODEPATTERN BEGIN
   DELETE XBarCodePattern
   WHERE  Date < @cleanDate
END
ELSE IF @auditType = @EXTERNALSITE BEGIN
   DELETE XExternalSiteLocation
   WHERE  Date < @cleanDate
END
ELSE IF @auditType = @IGNOREDBARCODEPATTERN BEGIN
   DELETE XIgnoredBarCodePattern
   WHERE  Date < @cleanDate
END
ELSE IF @auditType = @OPERATOR BEGIN
   DELETE XOperator
   WHERE  Date < @cleanDate
END
ELSE IF @auditType = @SENDLIST BEGIN
   DELETE XSendList
   WHERE  Date < @cleanDate
   DELETE XSendListItem
   WHERE  Date < @cleanDate
   DELETE XSendListCase
   WHERE  Date < @cleanDate
END
ELSE IF @auditType = @RECEIVELIST BEGIN
   DELETE XReceiveList
   WHERE  Date < @cleanDate
   DELETE XReceiveListItem
   WHERE  Date < @cleanDate
END
ELSE IF @auditType = @DISASTERCODELIST BEGIN
   DELETE XDisasterCodeList
   WHERE  Date < @cleanDate
   DELETE XDisasterCodeListItem
   WHERE  Date < @cleanDate
END
ELSE IF @auditType = @INVENTORY BEGIN
   DELETE XInventory
   WHERE  Date < @cleanDate
END
ELSE IF @auditType = @INVENTORYCONFLICT BEGIN
   DELETE XInventoryConflict
   WHERE  Date < @cleanDate
END
ELSE IF @auditType = @SEALEDCASE BEGIN
   DELETE XSealedCase
   WHERE  Date < @cleanDate
END
ELSE IF @auditType = @MEDIUM BEGIN
   DELETE XMedium
   WHERE  Date < @cleanDate
END
ELSE IF @auditType = @MEDIUMMOVEMENT BEGIN
   DELETE XMediumMovement
   WHERE  Date < @cleanDate
END
ELSE IF @auditType = @GENERALACTION BEGIN
   DELETE XGeneralAction
   WHERE  Date < @cleanDate
END

END
'
)

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'auditTrail$getPage')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.auditTrail$getPage
(
   @pageNo int,
   @pageSize int,
   @auditTypes int,
   @startDate datetime = null,
   @endDate datetime = null
)
WITH ENCRYPTION
AS
BEGIN
DECLARE @msg as nvarchar(255)        -- used to preformat error message
DECLARE @msgTag as nvarchar(255)     -- used to hold first part of error message header
DECLARE @tables nvarchar(4000)
DECLARE @fields1 nvarchar(4000)      -- innermost fields
DECLARE @fields2 nvarchar(4000)      -- outermost fields
DECLARE @sql nvarchar(4000)
DECLARE @sql1 nvarchar(4000)
DECLARE @order1 nvarchar(4000)	-- innermost order clause
DECLARE @order2 nvarchar(4000)   -- middle order clause
DECLARE @order3 nvarchar(4000)   -- outermost order clause
DECLARE @where nvarchar(4000)
DECLARE @auditType nvarchar(50)
DECLARE @topSize int
DECLARE @display int
DECLARE @count int
DECLARE @error int
DECLARE @i int
DECLARE @j int
-- Variables to hold types
DECLARE @ACCOUNT int
DECLARE @SYSTEMACTION int
DECLARE @BARCODEPATTERN int
DECLARE @EXTERNALSITE int
DECLARE @IGNOREDBARCODEPATTERN int
DECLARE @OPERATOR int
DECLARE @SENDLIST int
DECLARE @RECEIVELIST int
DECLARE @DISASTERCODELIST int
DECLARE @INVENTORY int
DECLARE @INVENTORYCONFLICT int
DECLARE @SEALEDCASE int
DECLARE @MEDIUM int
DECLARE @MEDIUMMOVEMENT int
DECLARE @GENERALACTION int
DECLARE @LASTAUDITTYPE int
SET @ACCOUNT               = 1
SET @SYSTEMACTION          = 2
SET @BARCODEPATTERN        = 4
SET @EXTERNALSITE          = 8
SET @IGNOREDBARCODEPATTERN = 16
SET @OPERATOR              = 32
SET @SENDLIST              = 64
SET @RECEIVELIST           = 128
SET @DISASTERCODELIST      = 256
SET @INVENTORY             = 512
SET @INVENTORYCONFLICT     = 1024
SET @SEALEDCASE            = 2048
SET @MEDIUM                = 4096
SET @MEDIUMMOVEMENT        = 8192
SET @GENERALACTION         = 16384
SET @LASTAUDITTYPE         = 16384

SET NOCOUNT ON

-- Initialize
SET @i = 0
SET @sql = ''''

-- Set the message tag
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=P''

-- Verify validity of @pageNo and @pageSize
IF @pageNo < 1 SET @pageNo = 1
IF @pageSize < 1 SET @pageSize = 20

-- Construct the where clause
SET @where = '' WHERE 1 = 1 ''
IF @startDate IS NOT NULL BEGIN
   SET @where = @where + '' AND convert(nchar(19), Date, 120) >= '''''' + convert(nchar(19), @startDate, 120) + ''''''''
END
IF @endDate IS NOT NULL BEGIN
   IF convert(nchar(10), @endDate, 120) = convert(nchar(19), @endDate, 120) BEGIN
      SET @endDate = dateadd(ss, 86399, cast(convert(nchar(10), @endDate, 120) as datetime))
   END
   SET @where = @where + '' AND convert(nchar(19), Date, 120) <= '''''' + convert(nchar(19), @endDate, 120) + ''''''''
END

-- Initialize the order clause
SET @order1 = '' ORDER BY Date desc, ItemId desc ''
SET @order2 = '' ORDER BY Date asc, ItemId asc ''
-- SET @order3 = '' ORDER BY Date desc, ItemId desc ''

-- Set top fields
SET @fields2 = ''ItemId, Date, Object, Action, Detail, Login, AuditType''

-- Create a table to hold record counts
CREATE TABLE #tblCount (RowNo int identity(1,1), RecordCount int)

-- Loop through, inserting records into local table and keeping track of total
WHILE power(2,@i) <= @LASTAUDITTYPE BEGIN
   IF (@auditTypes & power(2,@i)) != 0 BEGIN
      SET @auditType = cast(power(2,@i) as nvarchar(50)) + '' As ''''AuditType''''''
      -- Initialize tables and fields strings
      IF power(2,@i) = @ACCOUNT BEGIN
         SET @tables = ''XAccount''
         SET @fields1 = ''ItemId, Date, Object, Action, Detail, Login, '' + @auditType
      END
      ELSE IF power(2,@i) = @SYSTEMACTION BEGIN
         SET @tables = ''XSystemAction''
         SET @fields1 = ''ItemId, Date, '''''''' As ''''Object'''', Action, Detail, ''''SYSTEM'''' as ''''Login'''', '' + @auditType
      END
      ELSE IF power(2,@i) = @BARCODEPATTERN BEGIN
         SET @tables = ''XBarCodePattern''
         SET @fields1 = ''ItemId, Date, '''''''' As ''''Object'''', 2 As ''''Action'''', Detail, Login, '' + @auditType
      END
      ELSE IF power(2,@i) = @EXTERNALSITE BEGIN
         SET @tables = ''XExternalSiteLocation''
         SET @fields1 = ''ItemId, Date, Object, Action, Detail, Login, '' + @auditType
      END
      ELSE IF power(2,@i) = @IGNOREDBARCODEPATTERN BEGIN
         SET @tables = ''XIgnoredBarCodePattern''
         SET @fields1 = ''ItemId, Date, Object, Action, Detail, Login, '' + @auditType
      END
      ELSE IF power(2,@i) = @OPERATOR BEGIN
         SET @tables = ''XOperator''
         SET @fields1 = ''ItemId, Date, Object, Action, Detail, Login, '' + @auditType
      END
      ELSE IF power(2,@i) = @SENDLIST BEGIN
         SET @tables = ''SELECT ItemId, Date, Object, Action, Detail, Login FROM XSendList ''
                        + ''UNION ''
                        + ''SELECT ItemId, Date, Object, Action, Detail, Login FROM XSendListItem ''
                        + ''UNION ''
                        + ''SELECT ItemId, Date, Object, Action, Detail, Login FROM XSendListCase ''
         SET @tables = ''('' + @tables + '') as tblSend''
         SET @fields1 = ''ItemId, Date, Object, Action, Detail, Login, '' + @auditType
      END
      ELSE IF power(2,@i) = @RECEIVELIST BEGIN
         SET @tables = ''SELECT ItemId, Date, Object, Action, Detail, Login FROM XReceiveList ''
                        + ''UNION ''
                        + ''SELECT ItemId, Date, Object, Action, Detail, Login FROM XReceiveListItem ''
         SET @tables = ''('' + @tables + '') as tblReceive''
         SET @fields1 = ''ItemId, Date, Object, Action, Detail, Login, '' + @auditType
      END
      ELSE IF power(2,@i) = @DISASTERCODELIST BEGIN
         SET @tables = ''SELECT ItemId, Date, Object, Action, Detail, Login FROM XDisasterCodeList ''
                        + ''UNION ''
                        + ''SELECT ItemId, Date, Object, Action, Detail, Login FROM XDisasterCodeListItem ''
         SET @tables = ''('' + @tables + '') as tblReceive''
         SET @fields1 = ''ItemId, Date, Object, Action, Detail, Login, '' + @auditType
      END
      ELSE IF power(2,@i) = @INVENTORY BEGIN
         SET @tables = ''XInventory''
         SET @fields1 = ''ItemId, Date, Object, Action, Detail, Login, '' + @auditType
      END
      ELSE IF power(2,@i) = @INVENTORYCONFLICT BEGIN
         SET @tables = ''XInventoryConflict''
         SET @fields1 = ''ItemId, Date, Object, Action, Detail, Login, '' + @auditType
      END
      ELSE IF power(2,@i) = @SEALEDCASE BEGIN
         SET @tables = ''XSealedCase''
         SET @fields1 = ''ItemId, Date, Object, Action, Detail, Login, '' + @auditType
      END
      ELSE IF power(2,@i) = @MEDIUM BEGIN
         SET @tables = ''XMedium''
         SET @fields1 = ''ItemId, Date, Object, Action, Detail, Login, '' + @auditType
      END
      ELSE IF power(2,@i) = @MEDIUMMOVEMENT BEGIN
         SET @tables = ''XMediumMovement''
         SET @fields1 = ''ItemId, Date, Object, Method As ''''Action'''', CASE Direction WHEN 1 THEN ''''Medium moved to enterprise'''' ELSE ''''Medium moved to vault'''' END As ''''Detail'''', Login, '' + @auditType
      END
      ELSE IF power(2,@i) = @GENERALACTION BEGIN
         SET @tables = ''XGeneralAction''
         SET @fields1 = ''ItemId, Date, '''''''' As ''''Object'''', '''''''' As ''''Action'''', Detail, Login, '' + @auditType
      END
      -- Get the record count
      SET @sql1 = ''INSERT #tblCount (RecordCount) SELECT count(*) FROM '' + @tables + @where 
      EXECUTE sp_executesql @sql1
      SELECT TOP 1 @count = RecordCount FROM #tblCount ORDER BY RowNo Desc
      -- If we already have something, insert a union statement
      IF len(@sql) != 0 SET @sql = @sql + '' UNION ''
      -- Get all the records that qualify
      IF @pageNo = 1 BEGIN
         SET @sql = @sql + ''SELECT TOP '' + cast(@pageSize as nvarchar(50)) + '' '' + @fields1 + '' FROM '' + @tables + @where + @order1
      END
      ELSE BEGIN
	      -- Adjust the page size if necessary
		   SET @display = @count - ((@pageNo - 1) * @pageSize)
		   SET @topSize = @pageSize
		   IF @display <= 0
		      SET @where = @where + '' AND 1 != 1''
		   ELSE IF @pageSize > @display
		      SET @topSize = @display
		   -- Select the data
		   SET @sql = @sql + ''SELECT '' + @fields2 + '' FROM ''
		   SET @sql = @sql + ''(''
		   SET @sql = @sql + ''SELECT TOP '' + cast(@topSize as nvarchar(50)) + '' '' + @fields2 + '' FROM ''
		   SET @sql = @sql + ''   (''
		   SET @sql = @sql + ''   SELECT TOP '' + cast((@pageSize * @pageNo) as nvarchar(50)) + '' '' + @fields1 + '' FROM '' + @tables + @where + @order1
		   SET @sql = @sql + ''   ) as x'' + cast(@i as nvarchar(10)) + '' ''
		   SET @sql = @sql + @order2 + '') as y'' + cast(@i as nvarchar(10))
      END
   END
   -- Increment
   SET @i = @i + 1
END

-- Get the total record count and drop the table
SELECT @count = sum(RecordCount) FROM #tblCount
DROP TABLE #tblCount

-- Select from the temp table
SET @tables  = @sql
SET @fields1 = ''ItemId, Date, Object, Action, Detail, Login, AuditType''
SET @order1  = ''ORDER BY Date desc, AuditType asc, ItemId desc''

-- If the page number is 1, then we can execute without the subquery,
-- thus increasing efficiency.  No where clause necessary here, because
-- we already filtered the results.
IF @pageNo = 1 BEGIN
   SET @sql = ''SELECT TOP '' + cast(@pageSize as nvarchar(50)) + '' '' + @fields1 + '' FROM ('' + @tables + '') as z1 '' + @order1
END
ELSE BEGIN
   -- Adjust the page size if necessary
   SET @display = @count - ((@pageNo - 1) * @pageSize)
   SET @topSize = @pageSize
   IF @display <= 0
      SET @where = @where + '' AND 1 != 1''
   ELSE IF @pageSize > @display
      SET @topSize = @display
   -- Select the data
   SET @sql = ''SELECT TOP '' + cast(@topSize as nvarchar(50)) + '' '' + @fields1 + '' FROM ''
   SET @sql = @sql + ''('' + @tables + '') as z1 '' + @order1
END

-- Execute the sql
EXECUTE sp_executesql @sql
SET @error = @@error
IF @error != 0 BEGIN
   SET @msg = ''Error occurred while selecting audit records.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
   EXECUTE error$raise @msg, @error
   RETURN -100
END

-- Select the total number of records
SELECT @count as ''RecordCount''

RETURN 0
END
'
)

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'mediumType$ins')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.mediumType$ins
(
   @name nvarchar(128),           -- name of the medium type
   @twoSided bit,                 -- flag whether or not medium is two-sided
   @container bit,                -- flag whether or not type is a container
   @typeCode nvarchar(32) = '''', -- medium type code
   @newId int = NULL OUT         -- returns the id value for the newly created medium type
)
WITH ENCRYPTION
AS
BEGIN
DECLARE @msg as nvarchar(255)        -- used to preformat error message
DECLARE @msgTag as nvarchar(255)     -- used to hold first part of error message header
DECLARE @tranName as nvarchar(255)   -- used to hold name of savepoint
DECLARE @error as int

SET NOCOUNT ON

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=P''
SET @tranName = object_name(@@procid) + CAST(@@nestlevel as nvarchar(2))

BEGIN TRANSACTION
SAVE TRANSACTION @tranName

INSERT MediumType
(
   TypeName, 
   TwoSided,
   Container,
   TypeCode
)
VALUES
(
   @name, 
   @twoSided,
   @container,
   @typeCode
)

SET @error = @@error
IF @error != 0 BEGIN
   ROLLBACK TRANSACTION @tranName
   COMMIT TRANSACTION
   SET @msg = ''Error encountered while inserting a new medium type.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
   EXECUTE error$raise @msg, @error
   RETURN -100
END

-- Scope identity keeps us from getting any triggered identity values
SET @newId = scope_identity()
COMMIT TRANSACTION
RETURN 0
END
'
)

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'listAlert$getDays')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.listAlert$getDays
(
   @listType int,
   @days int out
)
WITH ENCRYPTION
AS
BEGIN

SET NOCOUNT ON

SELECT @days = Days
FROM   ListAlert
WHERE  ListType = @listType

END
'
)

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'listAlert$getTime')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.listAlert$getTime
(
   @listType int,
   @time datetime out
)
WITH ENCRYPTION
AS
BEGIN

SET NOCOUNT ON

SELECT @time = LastTime
FROM   ListAlert
WHERE  ListType = @listType

END
'
)

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'listAlert$updDays')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.listAlert$updDays
(
   @listType int,
   @days int
)
WITH ENCRYPTION
AS
BEGIN
DECLARE @msg as nvarchar(255)
DECLARE @msgTag as nvarchar(255)
DECLARE @tranName as nvarchar(255)   -- used to hold name of savepoint
DECLARE @error int

SET NOCOUNT ON

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=P''
SET @tranName = object_name(@@procid) + CAST(@@nestlevel as nvarchar(2))

-- Set up the transaction tag (nest level ensures uniqueness)
SET @tranName = object_name(@@procid) + CAST(@@nestlevel as nvarchar(2))

-- Update
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

UPDATE ListAlert
SET    Days = @days
WHERE  ListType = @listType
SET @error = @@error
IF @error != 0 BEGIN
   ROLLBACK TRANSACTION @tranName
   COMMIT TRANSACTION
   SET @msg = ''Error encountered while updating list alert profile.'' + @msgTag + '';Error='' + cast(@error as nvarchar(10)) + ''>''
   EXECUTE error$raise @msg, @error
   RETURN -100
END

-- Commit the transaction
COMMIT TRANSACTION
RETURN 0
END
'
)

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'listAlert$updTime')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.listAlert$updTime
(
   @listType int,
   @time datetime
)
WITH ENCRYPTION
AS
BEGIN
DECLARE @msg as nvarchar(255)
DECLARE @msgTag as nvarchar(255)
DECLARE @tranName as nvarchar(255)   -- used to hold name of savepoint
DECLARE @error int

SET NOCOUNT ON

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=P''
SET @tranName = object_name(@@procid) + CAST(@@nestlevel as nvarchar(2))

-- Set up the transaction tag (nest level ensures uniqueness)
SET @tranName = object_name(@@procid) + CAST(@@nestlevel as nvarchar(2))

-- Update
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

UPDATE ListAlert
SET    LastTime = @time
WHERE  ListType = @listType
SET @error = @@error
IF @error != 0 BEGIN
   ROLLBACK TRANSACTION @tranName
   COMMIT TRANSACTION
   SET @msg = ''Error encountered while updating list alert profile.'' + @msgTag + '';Error='' + cast(@error as nvarchar(10)) + ''>''
   EXECUTE error$raise @msg, @error
   RETURN -100
END

-- Commit the transaction
COMMIT TRANSACTION
RETURN 0
END
'
)

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'listAlertEmail$get')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.listAlertEmail$get
(
   @listType int
)
WITH ENCRYPTION
AS
BEGIN

SET NOCOUNT ON

SELECT e.GroupId, e.GroupName
FROM   ListAlertEmail a
JOIN   EmailGroup e
  ON   e.GroupId = a.GroupId
WHERE  a.ListType = @listType
ORDER  BY e.GroupName

END
'
)


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'listAlertEmail$ins')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.listAlertEmail$ins
(
   @listType int,
   @groupId int
)
WITH ENCRYPTION
AS
BEGIN
DECLARE @msg as nvarchar(255)        -- used to preformat error message
DECLARE @msgTag as nvarchar(255)     -- used to hold first part of error message header
DECLARE @tranName as nvarchar(255)   -- used to hold name of savepoint
DECLARE @error as int

SET NOCOUNT ON

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=P''
SET @tranName = object_name(@@procid) + CAST(@@nestlevel as nvarchar(2))

BEGIN TRANSACTION
SAVE TRANSACTION @tranName

IF NOT EXISTS (SELECT 1 FROM ListAlertEmail WHERE ListType = @listType and GroupId = @groupId) BEGIN
   INSERT ListAlertEmail (ListType, GroupId)
   VALUES (@listType, @groupId)
   SET @error = @@error
   IF @error != 0 BEGIN
      ROLLBACK TRANSACTION @tranName
      COMMIT TRANSACTION
      SET @msg = ''Error encountered while inserting a list alert email group.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
      EXECUTE error$raise @msg, @error
      RETURN -100
   END
END

COMMIT TRANSACTION
RETURN 0
END
'
)

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'listAlertEmail$del')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.listAlertEmail$del
(
   @listType int,
   @groupId int
)
WITH ENCRYPTION
AS
BEGIN
DECLARE @msg as nvarchar(255)        -- used to preformat error message
DECLARE @msgTag as nvarchar(255)     -- used to hold first part of error message header
DECLARE @tranName as nvarchar(255)   -- used to hold name of savepoint
DECLARE @error as int

SET NOCOUNT ON

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=P''
SET @tranName = object_name(@@procid) + CAST(@@nestlevel as nvarchar(2))

BEGIN TRANSACTION
SAVE TRANSACTION @tranName

DELETE ListAlertEmail
WHERE  ListType = @listType AND GroupId = @groupId
SET @error = @@error
IF @error != 0 BEGIN
   ROLLBACK TRANSACTION @tranName
   COMMIT TRANSACTION
   SET @msg = ''Error encountered while deleting a list alert email group.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
   EXECUTE error$raise @msg, @error
   RETURN -100
END

COMMIT TRANSACTION
RETURN 0
END
'
)

IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'barCodePattern$getTable')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.barCodePattern$getTable
(
   @literals bit = 1
)
WITH ENCRYPTION
AS
BEGIN

SET NOCOUNT ON

-- Select
IF @literals = 1 BEGIN
   SELECT p.Pattern,
          p.Notes,
          m.TypeName,
          a.AccountName
   FROM   BarCodePattern p
   JOIN   MediumType m
     ON   m.TypeId = p.TypeId
   JOIN   Account a
     ON   a.AccountId = p.AccountId
   ORDER BY p.Position Asc
END
ELSE BEGIN
   SELECT p.Pattern,
          p.Notes,
          m.TypeName,
          a.AccountName
   FROM   BarCodePattern p
   JOIN   MediumType m
     ON   m.TypeId = p.TypeId
   JOIN   Account a
     ON   a.AccountId = p.AccountId
   WHERE  p.Position >= (SELECT TOP 1 Position FROM BarCodePattern WHERE patindex(''%[^A-Z0-9a-z]%'', Pattern) != 0 ORDER BY Position ASC)
   ORDER  BY p.Position ASC
END
END
'
)

IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'barCodePattern$synchronizeLiterals')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.barCodePattern$synchronizeLiterals
WITH ENCRYPTION
AS
BEGIN
declare @tranName nvarchar(255)   -- used to hold name of savepoint
declare @tblLiteral table (RowNo int identity(1,1), Id int, Type int, Account int)
declare @id int
declare @i int
declare @t int
declare @a int

SET NOCOUNT ON

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @tranName = object_name(@@procid) + CAST(trigger_nestlevel(@@procid) as nvarchar(2))

-- Get those media that correspond to literal barcodes and
-- do not have the correct type or account
INSERT @tblLiteral (Id, Type, Account)
SELECT m.MediumId, p.TypeId, p.AccountId
FROM   Medium m
WITH  (INDEX(akMedium$SerialNo)) 
JOIN   BarCodePattern p
  ON   p.Pattern = m.SerialNo
WHERE  m.TypeId != p.TypeId OR m.AccountId != p.AccountId

-- Update the literals
SET @i = 1

WHILE 1 = 1 BEGIN
   SELECT @id = Id, 
          @t = Type, 
          @a = Account 
   FROM   @tblLiteral 
   WHERE  RowNo = @i
   IF @@rowcount = 0 
      BREAK
   ELSE
      UPDATE Medium SET TypeId = @t, AccountId = @a WHERE MediumId = @id
   -- Increment
   SET @i = @i + 1
END

-- Return
RETURN 0
END
'
)

IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'barCodePattern$synchronizeGet')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.barCodePattern$synchronizeGet
AS
BEGIN

SELECT m.MediumId, m.SerialNo, t.TypeName, a.AccountName 
FROM   Medium m 
WITH  (INDEX(akMedium$SerialNo)) 
JOIN   MediumType t
  ON   t.TypeId = m.TypeId
JOIN   Account a
  ON   a.AccountId = m.AccountId
LEFT   JOIN BarCodePattern p
  ON   p.Pattern = m.SerialNo 
WHERE  p.Pattern IS NULL

RETURN 0
END
'
)


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'receiveList$transit')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.receiveList$transit
(
   @listId int,
   @rowVersion rowversion
)
WITH ENCRYPTION
AS
BEGIN
DECLARE @msg as nvarchar(255)        -- used to preformat error message
DECLARE @msgTag as nvarchar(255)     -- used to hold first part of error message header
DECLARE @tranName as nvarchar(255)   -- used to hold name of savepoint
DECLARE @validStatuses int
DECLARE @compositeId int
DECLARE @listName nchar(10)
DECLARE @rowCount int
DECLARE @status int
DECLARE @error int
DECLARE @tblItems table (ItemId int PRIMARY KEY CLUSTERED)

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=P''
SET @tranName = object_name(@@procid) + CAST(@@nestlevel as nvarchar(2))

-- If the status of the item is already verified, then return.  Otherwise,
-- if it is anything besides submitted, raise error.
SELECT @status = Status,
       @listName = ListName,
       @compositeId = CompositeId
FROM   ReceiveList
WHERE  ListId = @listId AND RowVersion = @rowVersion
IF @@rowCount = 0 BEGIN
   IF EXISTS(SELECT 1 FROM ReceiveList WHERE ListId = @listId) BEGIN
      SET @msg = ''Receive list has been modified since retrieval.'' + @msgTag + ''>''
      RAISERROR(@msg,16,1)
      RETURN -100
   END
   ELSE BEGIN
      SET @msg = ''Receive list not found.'' + @msgTag + ''>''
      RAISERROR(@msg,16,1)
      RETURN -100
   END
END

-- If composite, the whole list must be marked as in transit
IF @compositeId IS NOT NULL BEGIN
   SET @msg = ''When a list is a member of a composite, the entire composite must be marked as in transit.'' + @msgTag + ''>''
   RAISERROR(@msg,16,1)
   RETURN -100
END

-- If already in transit or past this point, just return
IF @status >= 32 RETURN 0

-- Validate that list is transit-eligible
IF dbo.bit$statusEligible(2,@status,32) = 0 BEGIN
   SET @msg = ''List '' + @listName + '' is not eligible to be marked as in transit.'' + @msgTag + ''>''
   RAISERROR(@msg,16,1)
   RETURN -100
END

-- Get the list items to be marked as in transit
INSERT @tblItems (ItemId)
SELECT rli.ItemId
FROM   ReceiveListItem rli
JOIN   Medium m
  ON   rli.MediumId = m.MediumId
WHERE  m.Missing = 0 AND rli.Status != 1 AND
      (rli.ListId = @listId OR rli.ListId IN (SELECT ListId FROM ReceiveList WHERE CompositeId = @listId))

-- Upgrade the status of the item to arrived
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

UPDATE ReceiveListItem
SET    Status = 32
WHERE  ItemId IN (SELECT ItemId FROM @tblItems)
SET @error = @@error
IF @error != 0 BEGIN
   ROLLBACK TRANSACTION @tranName
   COMMIT TRANSACTION
   SET @msg = ''Error encountered while updating list to in transit status.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
   EXECUTE error$raise @msg, @error
   RETURN -100
END

-- Commit and return
COMMIT TRANSACTION
RETURN 0
END
'
)

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'sendList$transit')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.sendList$transit
(
   @listId int,
   @rowVersion rowversion
)
WITH ENCRYPTION
AS
BEGIN
DECLARE @msg as nvarchar(255)        -- used to preformat error message
DECLARE @msgTag as nvarchar(255)     -- used to hold first part of error message header
DECLARE @tranName as nvarchar(255)   -- used to hold name of savepoint
DECLARE @validStatuses int
DECLARE @compositeId int
DECLARE @listName nchar(10)
DECLARE @rowCount int
DECLARE @status int
DECLARE @error int
DECLARE @tblItems table (ItemId int PRIMARY KEY CLUSTERED)

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=P''
SET @tranName = object_name(@@procid) + CAST(@@nestlevel as nvarchar(2))

-- If the status of the item is already verified, then return.  Otherwise,
-- if it is anything besides submitted, raise error.
SELECT @status = Status,
       @listName = ListName,
       @compositeId = CompositeId
FROM   SendList
WHERE  ListId = @listId AND RowVersion = @rowVersion
IF @@rowCount = 0 BEGIN
   IF EXISTS(SELECT 1 FROM SendList WHERE ListId = @listId) BEGIN
      SET @msg = ''Send list has been modified since retrieval.'' + @msgTag + ''>''
      RAISERROR(@msg,16,1)
      RETURN -100
   END
   ELSE BEGIN
      SET @msg = ''Send list not found.'' + @msgTag + ''>''
      RAISERROR(@msg,16,1)
      RETURN -100
   END
END
ELSE IF @compositeId IS NOT NULL BEGIN
   SET @msg = ''When a list is a member of a composite, the entire composite must be marked as in transit.'' + @msgTag + ''>''
   RAISERROR(@msg,16,1)
   RETURN -100
END

-- If already in transit, just return
IF @status = 32 
   RETURN 0
ELSE IF @status > 32 BEGIN
   SET @msg = ''List '' + @listName + '' is past the point of being marked as in transit.'' + @msgTag + ''>''
   RAISERROR(@msg,16,1)
   RETURN -100
END

-- Validate that list is transit-eligible
IF dbo.bit$statusEligible(1,@status,32) = 0 BEGIN
   SET @msg = ''List '' + @listName + '' is not eligible to be marked as in trannsit.'' + @msgTag + ''>''
   RAISERROR(@msg,16,1)
   RETURN -100
END

-- Get the list items to be marked as in transit
INSERT @tblItems (ItemId)
SELECT sli.ItemId
FROM   SendListItem sli
JOIN   Medium m
  ON   m.MediumId = sli.MediumId
WHERE  m.Missing = 0 AND sli.Status != 1 AND
      (sli.ListId = @listId OR sli.ListId IN (SELECT ListId FROM SendList WHERE CompositeId = @listId))

-- Upgrade the status of the item to arrived
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

UPDATE SendListItem
SET    Status = 32
WHERE  ItemId IN (SELECT ItemId FROM @tblItems)
SET @error = @@error
IF @error != 0 BEGIN
   ROLLBACK TRANSACTION @tranName
   COMMIT TRANSACTION
   SET @msg = ''Error encountered while updating list to in transit status.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
   EXECUTE error$raise @msg, @error
   RETURN -100
END

-- Commit and return
COMMIT TRANSACTION
RETURN 0
END
'
)

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'sendList$del')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.sendList$del
(
   @listId int,
   @rowVersion rowversion
)
WITH ENCRYPTION
AS
BEGIN
DECLARE @msg as nvarchar(255)        -- used to preformat error message
DECLARE @msgTag as nvarchar(255)     -- used to hold first part of error message header
DECLARE @tranName as nvarchar(255)   -- used to hold name of savepoint
DECLARE @rowCount as int
DECLARE @error as int
DECLARE @listName as nchar(10)
DECLARE @returnValue as int
DECLARE @accountId as int
DECLARE @compositeId as int
DECLARE @status as int
DECLARE @i as int
DECLARE @itemsExist as bit
DECLARE @compositeVersion as rowversion
DECLARE @tblDiscretes table (RowNo int IDENTITY(1,1), ListId int, RowVersion binary(8))

SET NOCOUNT ON

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=P''
SET @tranName = object_name(@@procid) + CAST(@@nestlevel as nvarchar(2))

-- Check concurrency of list.  If it has been transmitted then raise error.
SELECT @listName = ListName,
       @accountId = AccountId,
       @compositeId = CompositeId,
       @status = Status
FROM   SendList 
WHERE  ListId = @listId
IF @@rowCount = 0 BEGIN
   SET @msg = ''Send list not found.'' + @msgTag + ''>''
   RAISERROR(@msg,16,1)
   RETURN -100
END
ELSE IF NOT EXISTS
   (
   SELECT 1
   FROM   SendList
   WHERE  ListId = @listId AND 
          RowVersion = @rowVersion
   )
BEGIN
   SET @msg = ''Send list '''''' + @listName + '''''' has been modified since retrieval.'' + @msgTag + ''>''
   RAISERROR(@msg,16,1)
   RETURN -100
END

-- Are there items on the list?
IF EXISTS (SELECT 1 FROM SendListItem WHERE ListId = @listId AND Status NOT IN (1,512))
   SELECT @itemsExist = 1
ELSE
   SELECT @itemsExist = 0

-- Do not allow deletion of list if there are items and status is greater than transmitted.
IF @itemsExist = 1 AND @status >= 16 and @status != 512 BEGIN
   SET @msg = ''A list may not be deleted after it has attained at least '' + dbo.string$statusName(2,16) + '' status..'' + @msgTag + ''>''
   RAISERROR(@msg,16,1)
   RETURN -100
END

-- Begin transaction
BEGIN TRANSACTION 
SAVE TRANSACTION @tranName

-- If the list is a composite, delete all its discretes
IF @accountId IS NULL BEGIN
   INSERT @tblDiscretes(ListId,RowVersion)
   SELECT ListId, RowVersion 
   FROM   SendList 
   WHERE  CompositeId = @listId
   SELECT @rowCount = @@rowCount, @i = 1
   WHILE @i <= @rowCount BEGIN
      -- Get the next discrete
      SELECT @listId = ListId, 
             @rowVersion = RowVersion 
      FROM   @tblDiscretes 
      WHERE  RowNo = @i
      -- Delete the discrete
      EXECUTE @returnValue = sendList$del @listId, @rowVersion
      IF @returnValue != 0 BEGIN
         ROLLBACK TRANSACTION @tranName
         COMMIT TRANSACTION
         RETURN -100
      END
      -- Increment counter
      SET @i = @i + 1
   END
END
ELSE BEGIN
   -- If the list is part of a composite and there items on the list, extract it first before deleting.  
   IF @compositeId IS NOT NULL AND @itemsExist = 1 BEGIN
      SELECT @compositeVersion = RowVersion
      FROM   SendList
      WHERE  ListId = @compositeId
      EXECUTE @returnValue = sendList$extract @listId, @rowVersion, @compositeId, @compositeVersion
      IF @returnValue != 0 BEGIN
         ROLLBACK TRANSACTION @tranName
         COMMIT TRANSACTION
         RETURN -100
      END
   END
END

-- Delete the list, even if it was a composite.  The composite may still exist
-- at this point, for example, in the case of merging two composites.  The
-- earlier composite will have no discretes by the time it it deleted.
DELETE SendList
WHERE  ListId = @listId
SET @error = @@error
IF @error != 0 BEGIN
   ROLLBACK TRANSACTION @tranName
   COMMIT TRANSACTION
   SET @msg = ''Error encountered while deleting send list.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
   EXECUTE error$raise @msg, @error
   RETURN -100
END

-- Commit and return
COMMIT TRANSACTION
RETURN 0
END
'
)

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'receiveList$del')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.receiveList$del
(
   @listId int,
   @rowVersion rowversion,
   @chkOverride bit = 0
)
WITH ENCRYPTION
AS
BEGIN
DECLARE @msg as nvarchar(255)        -- used to preformat error message
DECLARE @msgTag as nvarchar(255)     -- used to hold first part of error message header
DECLARE @tranName as nvarchar(255)   -- used to hold name of savepoint
DECLARE @rowCount as int
DECLARE @error as int
DECLARE @listName as nchar(10)
DECLARE @returnValue as int
DECLARE @accountId as int
DECLARE @compositeId as int
DECLARE @status as int
DECLARE @i as int
DECLARE @itemsExist as bit
DECLARE @compositeVersion as rowversion
DECLARE @tblDiscretes table (RowNo int IDENTITY(1,1), ListId int, RowVersion binary(8))

SET NOCOUNT ON

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=P''
SET @tranName = object_name(@@procid) + CAST(@@nestlevel as nvarchar(2))

-- Check concurrency of list.  If it has been transmitted then raise error.
SELECT @listName = ListName,
       @accountId = AccountId,
       @compositeId = CompositeId,
       @status = Status
FROM   ReceiveList 
WHERE  ListId = @listId AND RowVersion = @rowVersion
IF @@rowCount = 0 BEGIN
   IF EXISTS (SELECT 1 FROM ReceiveList WHERE ListId = @listId) BEGIN
      SET @msg = ''List has been modified since retrieval.'' + @msgTag + ''>''
      RAISERROR(@msg,16,1)
      RETURN -100
   END
   ELSE BEGIN
      SET @msg = ''Receive list not found.'' + @msgTag + ''>''
      RAISERROR(@msg,16,1)
      RETURN -100
   END
END

-- Are there items on the list?
IF EXISTS (SELECT 1 FROM ReceiveListItem WHERE ListId = @listId AND Status NOT IN (1,512))
   SELECT @itemsExist = 1
ELSE
   SELECT @itemsExist = 0

-- Check eligibility
IF @chkOverride != 1 AND @status != 512 BEGIN
   IF @status >= 4 AND EXISTS (SELECT 1 FROM ListStatusProfile WHERE ProfileId = 2 AND Statuses & 4 != 0) BEGIN
      SET @msg = ''A list may not be deleted after it has been transmitted.'' + @msgTag + ''>''
      RAISERROR(@msg,16,1)
      RETURN -100
   END
   ELSE IF @itemsExist = 1 AND @status >= 16 AND @status != 512 BEGIN
      SET @msg = ''A list may not be deleted once it has attained '' + dbo.string$statusName(2,16) + '' status.'' + @msgTag + ''>''
      RAISERROR(@msg,16,1)
      RETURN -100
   END
END

-- Begin transaction
BEGIN TRANSACTION 
SAVE TRANSACTION @tranName

-- If the list is a composite, delete all its discretes
IF @accountId IS NULL BEGIN
   INSERT @tblDiscretes(ListId,RowVersion)
   SELECT ListId, RowVersion 
   FROM   ReceiveList 
   WHERE  CompositeId = @listId
   SELECT @rowCount = @@rowCount, @i = 1
   WHILE @i <= @rowCount BEGIN
      -- Get the next discrete
      SELECT @listId = ListId, 
             @rowVersion = RowVersion 
      FROM   @tblDiscretes 
      WHERE  RowNo = @i
      -- Delete the discrete
      EXECUTE @returnValue = receiveList$del @listId, @rowVersion
      IF @returnValue != 0 BEGIN
         ROLLBACK TRANSACTION @tranName
         COMMIT TRANSACTION
         RETURN -100
      END
      -- Increment counter
      SET @i = @i + 1
   END
END
ELSE BEGIN
   -- If the list is part of a composite, extract it first before deleting.  
   IF @compositeId IS NOT NULL AND @itemsExist = 1 BEGIN
      SELECT @compositeVersion = RowVersion
      FROM   ReceiveList
      WHERE  ListId = @compositeId
      EXECUTE @returnValue = receiveList$extract @listId, @rowVersion, @compositeId, @compositeVersion
      IF @returnValue != 0 BEGIN
         ROLLBACK TRANSACTION @tranName
         COMMIT TRANSACTION
         RETURN -100
      END
   END
END

-- Delete the list, even if it was a composite.  The composite may still exist
-- at this point, for example, in the case of merging two composites.  The
-- earlier composite will have no discretes by the time it it deleted.
DELETE ReceiveList
WHERE  ListId = @listId
SET @error = @@error
IF @error != 0 BEGIN
   ROLLBACK TRANSACTION @tranName
   COMMIT TRANSACTION
   SET @msg = ''Error encountered while deleting receive list.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
   EXECUTE error$raise @msg, @error
   RETURN -100
END

-- Commit and return
COMMIT TRANSACTION
RETURN 0
END
'
)

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'externalSiteLocation$ins')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.externalSiteLocation$ins
(
   @siteName nvarchar(256),     -- name of the site
   @location bit,               -- enterprise (1) or vault (0)
   @accountName nvarchar(256),
   @newId int OUTPUT
)
WITH ENCRYPTION
AS
BEGIN
DECLARE @msg as nvarchar(255)      -- used to preformat error message
DECLARE @msgTag as nvarchar(255)    -- used to hold first part of error message header
DECLARE @tranName as nvarchar(255)   -- used to hold name of savepoint
DECLARE @accountId as int
DECLARE @error as int

SET NOCOUNT ON

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=P''
SET @tranName = object_name(@@procid) + CAST(@@nestlevel as nvarchar(2))
SET @accountName = isnull(@accountName,'''')

-- Get the account number
SELECT @accountId = AccountId
FROM   Account
WHERE  AccountName = @accountName

-- Insert the site map
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

INSERT ExternalSiteLocation
(
   SiteName, 
   Location,
   AccountId
)
VALUES
(
   @siteName, 
   @location,
   @accountId
)

SET @error = @@error
IF @error != 0 BEGIN
   ROLLBACK TRANSACTION @tranName
   COMMIT TRANSACTION
   SET @msg = ''Error encountered while inserting a new external site.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
   EXECUTE error$raise @msg, @error
   RETURN -100
END

-- Scope identity keeps us from getting any triggered identity values
SET @newId = scope_identity()
COMMIT TRANSACTION
RETURN 0
END
'
)

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'externalSiteLocation$upd')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.externalSiteLocation$upd
(
   @id int,
   @siteName nvarchar(256),
   @location bit,
   @accountName nvarchar(256),
   @rowVersion rowversion
)
WITH ENCRYPTION
AS
BEGIN
DECLARE @msg as nvarchar(255)        -- used to preformat error message
DECLARE @msgTag as nvarchar(255)     -- used to hold first part of error message header
DECLARE @tranName as nvarchar(255)   -- used to hold name of savepoint
DECLARE @accountId as int
DECLARE @rowCount as int
DECLARE @error as int

SET NOCOUNT ON

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=P''
SET @tranName = object_name(@@procid) + CAST(@@nestlevel as nvarchar(2))
SET @accountName = isnull(@accountName,'''')

-- Get the account number
SELECT @accountId = AccountId
FROM   Account
WHERE  AccountName = @accountName

-- Delete site
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

UPDATE ExternalSiteLocation
SET    SiteName = @siteName,
       Location = @location,
       AccountId = @accountId
WHERE  SiteId = @id AND
       RowVersion = @rowVersion

SELECT @error = @@error, @rowCount = @@rowcount

IF @error != 0 BEGIN
   ROLLBACK TRANSACTION @tranName
   COMMIT TRANSACTION
   SET @msg = ''Error encountered while updating external site.'' + @msgTag + '';Error='' +  cast(@error as nvarchar(50)) + ''>''
   EXECUTE error$raise @msg, @error
   RETURN -100
END
ELSE IF @rowCount = 0 BEGIN
   IF EXISTS(SELECT 1 FROM ExternalSiteLocation WHERE SiteId = @id) BEGIN
      ROLLBACK TRANSACTION @tranName
      COMMIT TRANSACTION
      SET @msg = ''External site record has been modified since retrieval.'' + @msgTag + ''>''
      RAISERROR(@msg,16,1)
      RETURN -100
   END
   ELSE BEGIN
      ROLLBACK TRANSACTION @tranName
      COMMIT TRANSACTION
      SET @msg = ''External site does not exist.'' + @msgTag + ''>''
      RAISERROR(@msg,16,1)
      RETURN -100
   END
END

-- Commit the transaction
COMMIT TRANSACTION
RETURN 0
END
'
)

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'externalSiteLocation$getById')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.externalSiteLocation$getById
(
   @id int
)
WITH ENCRYPTION
AS
BEGIN

SET NOCOUNT ON

-- Select
SELECT e.SiteId,
       e.SiteName,
       e.Location,
       isnull(a.AccountName,'''') as ''AccountName'',
       e.RowVersion
FROM   ExternalSiteLocation e
LEFT   JOIN Account a
  ON   a.AccountId = isnull(e.AccountId,-1)
WHERE  e.SiteId = @id

END
'
)

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'externalSiteLocation$getByName')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.externalSiteLocation$getByName
(
   @siteName nvarchar(256)
)
WITH ENCRYPTION
AS
BEGIN

SET NOCOUNT ON

-- Select
SELECT e.SiteId,
       e.SiteName,
       e.Location,
       isnull(a.AccountName,'''') as ''AccountName'',
       e.RowVersion
FROM   ExternalSiteLocation e
LEFT   JOIN Account a
  ON   a.AccountId = isnull(e.AccountId,-1)
WHERE  e.SiteName = @siteName

END
'
)

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'externalSiteLocation$getTable')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.externalSiteLocation$getTable
WITH ENCRYPTION
AS
BEGIN

SET NOCOUNT ON

-- Select
SELECT e.SiteId,
       e.SiteName,
       e.Location,
       isnull(a.AccountName,'''') as ''AccountName'',
       e.RowVersion
FROM   ExternalSiteLocation e
LEFT   JOIN Account a
  ON   a.AccountId = isnull(e.AccountId,-1)
ORDER  BY e.SiteName Asc

END
'
)

IF EXISTS(SELECT * FROM sysobjects WHERE name = 'externalSiteLocation$afterInsert' AND objectproperty(id, 'ExecIsInsertTrigger' ) = 1) 
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'TRIGGER externalSiteLocation$afterInsert
ON     ExternalSiteLocation
WITH ENCRYPTION
AFTER  INSERT
AS
BEGIN
DECLARE @msg nvarchar(255)        -- used to preformat error message
DECLARE @msgTag nvarchar(255)     -- used to hold first part of error message header
DECLARE @tranName nvarchar(255)   -- used to hold name of savepoint
DECLARE @siteName nvarchar(256)   -- holds the name of the external site
DECLARE @rowCount int            -- holds the number of rows in the Inserted table
DECLARE @accountName nvarchar(256)
DECLARE @detail nvarchar(4000)
DECLARE @error int            

SET @rowCount = @@rowcount
IF @rowCount = 0 RETURN

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=T''
SET @tranName = object_name(@@procid) + CAST(trigger_nestlevel(@@procid) as nvarchar(2))

-- Insert audit record
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

-- Make sure we do not have a batch insert
IF @rowCount > 1 BEGIN
   SET @msg = ''Batch insert into external site location table not allowed.'' + @msgTag + ''>''
   EXECUTE error$raise @msg, 0, @tranName
   RETURN
END

-- Get the caller login from the spidLogin table
IF len(dbo.string$GetSpidLogin()) = 0 BEGIN
   SET @msg = ''No login found for auditing purposes.'' + @msgTag + ''>''
   EXECUTE error$raise @msg, 0, @tranName
   RETURN
END

-- Select the name of the site from the Inserted table
SELECT @siteName = SiteName,
       @detail = case Location when 1 then ''External site created (resolves to enterprise)'' else ''External site created (resolves to vault)'' end
FROM   Inserted

-- Select the name of the site from the Inserted table
SELECT @accountName = AccountName
FROM   Account
WHERE  AccountId = (SELECT isnull(AccountId,-1) FROM Inserted)
IF @@rowcount != 0 SET @detail = @detail + '', corresponds to account '' + @accountName

INSERT XExternalSiteLocation
(
   Object, 
   Action, 
   Detail, 
   Login
)
VALUES
(
   @siteName, 
   1, 
   @detail, 
   dbo.string$GetSpidLogin()
)

SET @error = @@error
IF @error != 0 BEGIN
   SET @msg = ''Error encountered while inserting an external site audit record.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
   EXECUTE error$raise @msg, @error, @tranName
   RETURN
END

COMMIT TRANSACTION
END
'
)

IF EXISTS(SELECT * FROM sysobjects WHERE name = 'externalSiteLocation$afterUpdate' AND objectproperty(id, 'ExecIsUpdateTrigger' ) = 1) 
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'TRIGGER externalSiteLocation$afterUpdate
ON     ExternalSiteLocation
WITH ENCRYPTION
AFTER  UPDATE
AS
BEGIN
DECLARE @msg nvarchar(255)         -- used to preformat error message
DECLARE @msgTag nvarchar(255)      -- used to hold first part of error message header
DECLARE @msgUpdate nvarchar(4000)  -- used to hold the updated fields
DECLARE @tranName nvarchar(255)    -- used to hold name of savepoint
DECLARE @siteName nvarchar(256)    -- holds the name of the external site
DECLARE @rowCount int             -- holds the number of rows in the Deleted table
DECLARE @del nvarchar(4000)
DECLARE @ins nvarchar(4000)
DECLARE @accountName nvarchar(256)
DECLARE @error int
DECLARE @tblM table (RowNo int identity (1,1), Message nvarchar(1000))
DECLARE @i int

SET @rowCount = @@rowcount
IF @rowCount = 0 RETURN

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=T''
SET @tranName = object_name(@@procid) + CAST(trigger_nestlevel(@@procid) as nvarchar(2))

-- Begin transaction
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

-- Make sure we do not have a batch delete
IF @rowCount > 1 BEGIN
   SET @msg = ''Batch update on external site location table not allowed.'' + @msgTag + ''>''
   EXECUTE error$raise @msg, 0, @tranName
   RETURN
END

-- Get the caller login from the spidLogin table
IF len(dbo.string$GetSpidLogin()) = 0 BEGIN
   SET @msg = ''No login found for auditing purposes.'' + @msgTag + ''>''
   EXECUTE error$raise @msg, 0, @tranName
   RETURN
END

-- Select the name of the site from the Deleted table
SELECT @i = 1, @siteName = SiteName FROM Deleted

-- Add altered fields to audit message
IF EXISTS (SELECT 1 FROM Inserted i JOIN Deleted d on d.SiteId = i.SiteId WHERE d.Location != i.Location) BEGIN
   INSERT @tblM (Message) SELECT ''Site now resolves to '' + case Location when 1 then '' the enterprise'' else '' the vault'' end FROM Inserted
END
IF EXISTS (SELECT 1 FROM Inserted i JOIN Deleted d on d.SiteId = i.SiteId WHERE d.SiteName != i.SiteName) BEGIN
   INSERT @tblM (Message) SELECT ''Site name changed to '''''' + (SELECT SiteName FROM Inserted) + ''''''''
END
IF EXISTS (SELECT 1 FROM Inserted i JOIN Deleted d on d.SiteId = i.SiteId WHERE isnull(d.AccountId,-1) != isnull(i.AccountId,-1)) BEGIN
   SELECT isnull(@accountName,'''') FROM Account WHERE AccountId = (SELECT isnull(AccountId,-1) FROM Inserted)
   IF @@rowcount != 0 INSERT @tblM (Message) SELECT ''Corresponding account changed to '' + @accountName
END

-- Initialize counter
SELECT @i = min(RowNo) FROM @tblM

-- Insert audit records
WHILE 1 = 1 BEGIN
   SELECT @msgUpdate = Message
   FROM   @tblM
   WHERE  RowNo = @i
   IF @@rowcount = 0 
      BREAK
   ELSE BEGIN
      INSERT XExternalSiteLocation(Object, Action, Detail, Login)
      VALUES(@siteName, 2, @msgUpdate, dbo.string$GetSpidLogin())
      SET @error = @@error
      IF @error != 0 BEGIN
         SET @msg = ''Error encountered while inserting an external site audit record.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
         EXECUTE error$raise @msg, @error, @tranName
         RETURN
      END
   END
   -- Counter
   SET @i = @i + 1
END

COMMIT TRANSACTION
END
'
)

-------------------------------------------------------------------------------
--
-- Amend journal messages.  Remove periods from the end of detail strings.
--
-------------------------------------------------------------------------------
DECLARE @tableName nvarchar(256)
DECLARE @sql nvarchar(256)
SELECT @tableName = 'A'
WHILE 1 = 1 BEGIN
   SELECT TOP 1 @tableName = TABLE_NAME
   FROM   INFORMATION_SCHEMA.COLUMNS 
   WHERE  COLUMN_NAME = 'Detail' AND TABLE_NAME LIKE 'X%' AND TABLE_NAME > @tableName
   ORDER  BY TABLE_NAME ASC
   IF @@rowcount = 0 BREAK
   SELECT @sql = 'UPDATE ' + @tableName + ' SET Detail = left(Detail,len(Detail)-1) WHERE Detail LIKE ''%.'''
   EXECUTE sp_executesql @sql
END

-------------------------------------------------------------------------------
--
-- Version update
--
-------------------------------------------------------------------------------
IF NOT EXISTS(SELECT 1 FROM DatabaseVersion WHERE Major = 1 AND Minor = 3 AND Revision = 2) BEGIN
   DECLARE @x nvarchar(1000)
   EXECUTE spidLogin$ins 'System', 'Insert database version'
   INSERT DatabaseVersion (Major, Minor, Revision) VALUES (1, 3, 2)
   EXECUTE spidLogin$del
END

COMMIT TRANSACTION  -- Commit the script update transaction

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
