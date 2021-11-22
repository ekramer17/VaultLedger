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
IF dbo.bit$doScript('1.3.4') = 1 BEGIN

DECLARE @CREATE nvarchar(10)

BEGIN TRANSACTION

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'sendList$getByMedium')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.sendList$getByMedium
(
   @serialNo nvarchar(64)
)
WITH ENCRYPTION
AS
BEGIN
DECLARE @listId int
DECLARE @compositeId int

SET NOCOUNT ON

SELECT @listId = sl.ListId,
       @compositeId = sl.CompositeId
FROM   SendList sl
JOIN   SendListItem sli
  ON   sli.ListId = sl.ListId
JOIN   Medium m
  ON   sli.MediumId = m.MediumId
WHERE  m.SerialNo = @serialNo AND sli.Status NOT IN (1,512)

IF @@rowcount != 0 BEGIN
   IF @compositeId IS NULL BEGIN
      SELECT sl.ListId,
             sl.ListName,
             sl.CreateDate,
             sl.Status,
             a.AccountName,
             sl.RowVersion
      FROM   SendList sl
      JOIN   Account a
        ON   a.AccountId = sl.AccountId
      WHERE  sl.ListId = @listId
   END
   ELSE BEGIN
      SELECT sl.ListId,
             sl.ListName,
             sl.CreateDate,
             sl.Status,
             '''' as ''AccountName'',
             sl.RowVersion
      FROM   SendList sl
      WHERE  sl.ListId = @compositeId
      -- Get the child lists
      SELECT sl.ListId,
             sl.ListName,
             sl.CreateDate,
             sl.Status,
             a.AccountName,
             sl.RowVersion
      FROM   SendList sl
      JOIN   Account a
        ON   a.AccountId = sl.AccountId
      WHERE  sl.CompositeId = @compositeId
      ORDER BY sl.ListName ASC
   END
END

END
'
)

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'receiveList$getByMedium')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.receiveList$getByMedium
(
   @serialNo nvarchar(64)
)
WITH ENCRYPTION
AS
BEGIN
DECLARE @listId int
DECLARE @compositeId int

SET NOCOUNT ON

SELECT @listId = rl.ListId,
       @compositeId = rl.CompositeId
FROM   ReceiveList rl
JOIN   ReceiveListItem rli
  ON   rli.ListId = rl.ListId
JOIN   Medium m
  ON   rli.MediumId = m.MediumId
WHERE  m.SerialNo = @serialNo AND rli.Status NOT IN (1,512)

IF @@rowcount != 0 BEGIN
   IF @compositeId IS NULL BEGIN
      SELECT rl.ListId,
             rl.ListName,
             rl.CreateDate,
             rl.Status,
             a.AccountName,
             rl.RowVersion
      FROM   ReceiveList rl
      JOIN   Account a
        ON   a.AccountId = rl.AccountId
      WHERE  rl.ListId = @listId
   END
   ELSE BEGIN
      SELECT rl.ListId,
             rl.ListName,
             rl.CreateDate,
             rl.Status,
             '''' as ''AccountName'',
             rl.RowVersion
      FROM   ReceiveList rl
      WHERE  rl.ListId = @compositeId
      -- Get the child lists
      SELECT rl.ListId,
             rl.ListName,
             rl.CreateDate,
             rl.Status,
             a.AccountName,
             rl.RowVersion
      FROM   ReceiveList rl
      JOIN   Account a
        ON   a.AccountId = rl.AccountId
      WHERE  rl.CompositeId = @compositeId
      ORDER BY rl.ListName ASC
   END
END

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
WHERE  m.TypeId not in (SELECT TypeId FROM MediumType WHERE TypeCode = (SELECT TypeCode FROM MediumType WHERE TypeId = isnull(vi.TypeId,-1)))
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
      ROLLBACK TRANSACTION @tranName
      COMMIT TRANSACTION
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

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'sendList$getByMedium')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.medium$ins
(
   @serialNo nvarchar(32),      -- serial number of medium
   @location bit,               -- flag whether medium is at enterprise (1) or vault (0)
   @hotStatus bit,              -- flag indicating hot status
   @returnDate datetime,        -- date of scheduled return from vault
   @bSide nvarchar(32),         -- serial number of b-side
   @notes nvarchar(4000),       -- random notes about medium
   @mediumType nvarchar(128),   -- type of the medium
   @accountName nvarchar(256),  -- account to which medium belongs
   @newId int OUTPUT
)
WITH ENCRYPTION
AS
BEGIN
DECLARE @msg as nvarchar(255)        -- used to preformat error message
DECLARE @msgTag as nvarchar(255)     -- used to hold first part of error message header
DECLARE @tranName as nvarchar(255)   -- used to hold name of savepoint
DECLARE @error as int
DECLARE @twoSided as bit
DECLARE @typeId as int
DECLARE @rv as binary(8)
DECLARE @id as int
DECLARE @returnValue as int
DECLARE @accountId as int

SET NOCOUNT ON

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=P''
SET @tranName = object_name(@@procid) + CAST(@@nestlevel as nvarchar(2))

-- If the medium already exists, return zero
IF EXISTS (SELECT 1 FROM Medium WHERE SerialNo = @serialNo) RETURN 0

-- If medium is at enterprise, then return date must be NULL and hot status must be 0
IF @location = 1 BEGIN
   SET @hotStatus = 0
   SET @returnDate = NULL 
END

-- Get the account id and medium type id
SELECT @accountId = AccountId
FROM   Account
WHERE  AccountName = @accountName
IF @@rowcount = 0 BEGIN
   SET @msg = ''Account not found.'' + @msgTag + ''>''
   RAISERROR(@msg,16,1)
   RETURN -100
END

SELECT @typeId = TypeId
FROM   MediumType
WHERE  TypeName = @mediumType AND Container = 0
IF @@rowcount = 0 BEGIN
   SET @msg = ''Medium type not found.'' + @msgTag + ''>''
   RAISERROR(@msg,16,1)
   RETURN -100
END

-- Insert the medium into the database
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

-- If the medium has the same serial number as an EMPTY sealed case, delete the sealed case
SELECT @id = c.CaseId, 
       @rv = c.RowVersion
FROM   SealedCase c
LEFT   JOIN MediumSealedCase m
  ON   c.CaseId = m.CaseId
WHERE  c.SerialNo = @serialNo AND m.MediumId IS NULL
IF @@rowcount != 0 BEGIN
   EXECUTE @returnValue = sealedCase$del @id, @rv
   IF @returnValue != 0 BEGIN
      ROLLBACK TRANSACTION @tranName
      COMMIT TRANSACTION
      RETURN -100
   END
END

-- Add the medium 
INSERT Medium
(
   SerialNo, 
   BSide, 
   Location,
   HotStatus, 
   ReturnDate, 
   Notes, 
   TypeId, 
   AccountId
)
VALUES
(
   @serialNo, 
   coalesce(@bSide,''''), 
   @location, 
   @hotStatus, 
   @returnDate, 
   @notes, 
   @typeId, 
   @accountId
)

SET @error = @@error

IF @error != 0 BEGIN
   ROLLBACK TRANSACTION @tranName
   COMMIT TRANSACTION
   SET @msg = ''Error encountered while inserting a new medium.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
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

-------------------------------------------------------------------------------
--
-- Version update
--
-------------------------------------------------------------------------------
IF NOT EXISTS(SELECT 1 FROM DatabaseVersion WHERE Major = 1 AND Minor = 3 AND Revision = 4) BEGIN
   DECLARE @x nvarchar(1000)
   EXECUTE spidLogin$ins 'System', 'Insert database version'
   INSERT DatabaseVersion (Major, Minor, Revision) VALUES (1, 3, 4)
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
