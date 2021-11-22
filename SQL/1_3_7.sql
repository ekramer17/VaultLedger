SET NOCOUNT ON

-- Should we run this script?
IF dbo.bit$doScript('1.3.7') = 1 BEGIN

DECLARE @CREATE nvarchar(10)

BEGIN TRANSACTION

-------------------------------------------------------------------------------
--
-- Procedure: listPurgeDetail$getTable
--
-------------------------------------------------------------------------------
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'listPurgeDetail$getTable')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.listPurgeDetail$getTable
WITH ENCRYPTION
AS
BEGIN

SET NOCOUNT ON

SELECT Type,
       Archive,
       Days,
       RowVersion
FROM   ListPurgeDetail
WITH  (NOLOCK)
ORDER BY Type ASC
END
'
)

IF @@error != 0 GOTO ROLL_IT -- Rollback on error

-------------------------------------------------------------------------------
--
-- Procedure: listPurgeDetail$get
--
-------------------------------------------------------------------------------
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'listPurgeDetail$get')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.listPurgeDetail$get
(
   @listType int
)
WITH ENCRYPTION
AS
BEGIN

SET NOCOUNT ON

SELECT Type,
       Archive,
       Days,
       RowVersion
FROM   ListPurgeDetail
WITH  (NOLOCK)
WHERE  Type = @listType
END
'
)

IF @@error != 0 GOTO ROLL_IT

-------------------------------------------------------------------------------
--
-- Procedure: sendList$getCleared
--
-------------------------------------------------------------------------------
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'sendList$getCleared')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.sendList$getCleared
(
   @createDate datetime
)
WITH ENCRYPTION
AS
BEGIN
DECLARE @dateString nchar(10)

SET NOCOUNT ON

SET @dateString = convert(nchar(10),@createDate,120)

-- Select standalone discrete lists and composites where at least one
-- of the constituent discretes has the given create date.
SELECT sl.ListId,
       sl.ListName as ''ListName'',
       sl.CreateDate,
       sl.Status,
       a.AccountName,
       sl.RowVersion
FROM   SendList sl
WITH  (NOLOCK)
JOIN   Account a
  ON   a.AccountId = sl.AccountId
WHERE  sl.Status = 512 AND 
       sl.CompositeId IS NULL AND
       convert(nchar(10),sl.CreateDate,120) <= @dateString
UNION
SELECT sl.ListId,
       sl.ListName,
       sl.CreateDate,
       sl.Status,
       '''',
       sl.RowVersion
FROM   SendList sl
WITH  (NOLOCK)
WHERE  sl.Status = 512 AND 
       sl.AccountId IS NULL AND
       EXISTS(SELECT 1 
              FROM   SendList sl2
              WHERE  CompositeId = sl.ListId AND
                     convert(nchar(10),sl2.CreateDate,120) <= @dateString)
ORDER BY ListName Asc
END
'
)

IF @@error != 0 GOTO ROLL_IT

-------------------------------------------------------------------------------
--
-- Procedure: receiveList$getCleared
--
-------------------------------------------------------------------------------
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'receiveList$getCleared')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.receiveList$getCleared
(
   @createDate datetime
)
WITH ENCRYPTION
AS
BEGIN
DECLARE @dateString nchar(10)

SET NOCOUNT ON

SET @dateString = convert(nchar(10),@createDate,120)

-- Select standalone discrete lists and composites where at least one
-- of the constituent discretes has the given create date.
SELECT rl.ListId,
       rl.ListName as ''ListName'',
       rl.CreateDate,
       rl.Status,
       a.AccountName,
       rl.RowVersion
FROM   ReceiveList rl
WITH  (NOLOCK)
JOIN   Account a
  ON   a.AccountId = rl.AccountId
WHERE  rl.Status = 512 AND 
       rl.CompositeId IS NULL AND
       convert(nchar(10),rl.CreateDate,120) <= @dateString
UNION
SELECT rl.ListId,
       rl.ListName,
       rl.CreateDate,
       rl.Status,
       '''',
       rl.RowVersion
FROM   ReceiveList rl
WITH  (NOLOCK)
WHERE  rl.Status = 512 AND
       rl.AccountId IS NULL AND
       EXISTS(SELECT 1 
              FROM   ReceiveList rl2
              WITH  (NOLOCK)
              WHERE  CompositeId = rl.ListId AND
                     convert(nchar(10),rl2.CreateDate,120) <= @dateString)
ORDER BY ListName Asc
END
'
)

IF @@error != 0 GOTO ROLL_IT

-------------------------------------------------------------------------------
--
-- Procedure: disasterCodeList$getCleared
--
-------------------------------------------------------------------------------
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'disasterCodeList$getCleared')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.disasterCodeList$getCleared
(
   @createDate datetime
)
WITH ENCRYPTION
AS
BEGIN
DECLARE @dateString nchar(10)

SET NOCOUNT ON

SET @dateString = convert(nchar(10),@createDate,120)

-- Select standalone discrete lists and composites where at least one
-- of the constituent discretes has the given create date.
SELECT dl.ListId,
       dl.ListName as ''ListName'',
       dl.CreateDate,
       dl.Status,
       a.AccountName,
       dl.RowVersion
FROM   DisasterCodeList dl
WITH  (NOLOCK)
JOIN   Account a
  ON   a.AccountId = dl.AccountId
WHERE  dl.Status = 512 AND
       dl.CompositeId IS NULL AND
       convert(nchar(10),dl.CreateDate,120) <= @dateString
UNION
SELECT dl.ListId,
       dl.ListName,
       dl.CreateDate,
       dl.Status,
       '''',
       dl.RowVersion
FROM   DisasterCodeList dl
WITH  (NOLOCK)
WHERE  dl.Status = 512 AND
       dl.AccountId IS NULL AND
       EXISTS(SELECT 1 
              FROM   DisasterCodeList dl2
              WITH  (NOLOCK)
              WHERE  CompositeId = dl.ListId AND
                     convert(nchar(10),dl2.CreateDate,120) <= @dateString)
ORDER BY ListName Asc
END
'
)

IF @@error != 0 GOTO ROLL_IT

-------------------------------------------------------------------------------
--
-- Procedure: barCodePattern$getFinal
--
-------------------------------------------------------------------------------
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'barCodePattern$getFinal')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.barCodePattern$getFinal
WITH ENCRYPTION
AS
BEGIN

SET NOCOUNT ON

SELECT TOP 1 p.Pattern,
       p.Notes,
       m.TypeName,
       a.AccountName
FROM   BarCodePattern p
JOIN   MediumType m
  ON   m.TypeId = p.TypeId
JOIN   Account a
  ON   a.AccountId = p.AccountId
ORDER  BY p.Position Desc
END
'
)

IF @@error != 0 GOTO ROLL_IT

-------------------------------------------------------------------------------
--
-- Procedure: barCodePatternCase$getFinal
--
-------------------------------------------------------------------------------
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'barCodePatternCase$getFinal')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.barCodePatternCase$getFinal
WITH ENCRYPTION
AS
BEGIN

SET NOCOUNT ON

SELECT TOP 1 p.Pattern,
       p.Notes,
       m.TypeName
FROM   BarCodePatternCase p
JOIN   MediumType m
  ON   m.TypeId = p.TypeId
ORDER  BY p.Position Desc

END
'
)

IF @@error != 0 GOTO ROLL_IT

-------------------------------------------------------------------------------
--
-- Procedure: barCodePattern$getTable
--
-------------------------------------------------------------------------------
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
   WITH  (NOLOCK)
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
   WITH  (NOLOCK)
   JOIN   MediumType m
     ON   m.TypeId = p.TypeId
   JOIN   Account a
     ON   a.AccountId = p.AccountId
   WHERE  p.Position >= (SELECT TOP 1 Position FROM BarCodePattern WITH (NOLOCK) WHERE patindex(''%[^A-Z0-9a-z]%'', Pattern) != 0 ORDER BY Position ASC)
   ORDER  BY p.Position ASC
END
END
'
)

IF @@error != 0 GOTO ROLL_IT

-------------------------------------------------------------------------------
--
-- Procedure: barCodePatternCase$getTable
--
-------------------------------------------------------------------------------
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'barCodePatternCase$getTable')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.barCodePatternCase$getTable
WITH ENCRYPTION
AS
BEGIN

SET NOCOUNT ON

-- Select
SELECT p.Pattern,
       p.Notes,
       m.TypeName
FROM   BarCodePatternCase p
WITH  (NOLOCK)
JOIN   MediumType m
  ON   m.TypeId = p.TypeId
ORDER BY p.Position Asc

END
'
)

IF @@error != 0 GOTO ROLL_IT

-------------------------------------------------------------------------------
--
-- Trigger: sendListCase$afterInsert
--
-------------------------------------------------------------------------------
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

IF @@error != 0 GOTO ROLL_IT

-------------------------------------------------------------------------------
--
-- Procedure: sendListCase$ins
--
-------------------------------------------------------------------------------
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'sendListCase$ins')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.sendListCase$ins
(
   @caseName nvarchar(32),
   @caseId int OUTPUT
)
WITH ENCRYPTION
AS
BEGIN
DECLARE @msg as nvarchar(255)        -- used to preformat error message
DECLARE @msgTag as nvarchar(255)     -- used to hold first part of error message header
DECLARE @tranName as nvarchar(255)   -- used to hold name of savepoint
DECLARE @returnValue as int
DECLARE @delete as bit
DECLARE @typeId as int
DECLARE @error as int

SET NOCOUNT ON

-- Tweak parameter
SET @caseName = ltrim(rtrim(@caseName))
SET @delete = 0
 
-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=P''
SET @tranName = object_name(@@procid) + CAST(@@nestlevel as nvarchar(2))

-- If the case already exists in the send list case table then just return
SELECT @caseId = CaseId 
FROM   SendListCase 
WHERE  SerialNo = @caseName AND Cleared = 0
IF @@rowCount != 0 RETURN 0

-- Verify that there is no medium with the case name.
IF EXISTS(SELECT 1 FROM Medium WHERE SerialNo = @caseName) BEGIN
   SET @msg = ''A medium with serial number '''''' + @caseName + '''''' already exists.'' + @msgTag + ''>''
   RAISERROR(@msg,16,1)
   RETURN -100
END

-- Make sure that the case does not exist in the sealed case table, 
-- unless it is empty, in which case we''ll delete it.
IF EXISTS 
   (
   SELECT 1 
   FROM   MediumSealedCase 
   WHERE  CaseId = (SELECT CaseId FROM SealedCase WHERE SerialNo = @caseName)
   )
BEGIN
   SET @msg = ''Case '''''' + @caseName + '''''' already resides at the vault and contains media.'' + @msgTag + ''>''
   RETURN -100
END
ELSE IF EXISTS (SELECT 1 FROM SealedCase WHERE SerialNo = @caseName) BEGIN
   SET @delete = 1
END

-- Get the type for the case
EXECUTE @returnValue = barCodePatternCase$getDefaults @caseName, @typeId OUT
IF @returnValue != 0 RETURN -100

-- Begin the transaction
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

-- Delete the sealed case if requested
IF @delete = 1 BEGIN
   DELETE SealedCase
   WHERE  SerialNo = @caseName
   SET @error = @@error
   IF @error != 0 BEGIN
      ROLLBACK TRANSACTION @tranName
      COMMIT TRANSACTION
      SET @msg = ''Error encountered while deleting an empty sealed case.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
      EXECUTE error$raise @msg, @error
      RETURN -100
   END
END

-- Insert the record
INSERT SendListCase (SerialNo, TypeId) 
VALUES (@caseName, @typeId)

-- Check the error   
SET @error = @@error
IF @error != 0 BEGIN
   ROLLBACK TRANSACTION @tranName
   COMMIT TRANSACTION
   SET @msg = ''Error encountered while inserting a new send list case.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
   EXECUTE error$raise @msg, @error
   RETURN -100
END

-- Commit
SET @caseId = scope_identity()
COMMIT TRANSACTION

-- Return
RETURN 0
END
'
)

IF @@error != 0 GOTO ROLL_IT

-------------------------------------------------------------------------------
--
-- Trigger: sendListItem$afterUpdate
--
-------------------------------------------------------------------------------
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

-- Make sure that media do not actively appear on more than one shipping list
IF EXISTS
   (
   SELECT 1
   FROM   SendListItem sli
   JOIN   Inserted i
     ON   i.MediumId = sli.MediumId
   WHERE  i.ItemId != sli.ItemId and i.Status != 1 and sli.Status not in (1, 512)
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

IF @@error != 0 GOTO ROLL_IT

-------------------------------------------------------------------------------
--
-- Trigger: sendListItem$afterInsert
--
-------------------------------------------------------------------------------
IF EXISTS(SELECT 1 FROM sysobjects WHERE name = 'sendListItem$afterInsert' AND objectproperty(id, 'ExecIsInsertTrigger' ) = 1) 
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'TRIGGER sendListItem$afterInsert
ON     SendListItem
WITH ENCRYPTION
AFTER  INSERT
AS
BEGIN
DECLARE @msg nvarchar(255)        -- used to preformat error message
DECLARE @msgTag nvarchar(255)     -- used to hold first part of error message header
DECLARE @tranName nvarchar(255)   -- used to hold name of savepoint
DECLARE @listName nchar(10)       -- holds the name of the send list
DECLARE @listStatus int           -- holds the status of the list
DECLARE @serialNo nvarchar(32)    -- holds the serial number of the medium
DECLARE @itemStatus nvarchar(32)  -- holds the initial status of the item
DECLARE @auditMsg nvarchar(1000)
DECLARE @rowVersion rowversion
DECLARE @rowCount int             -- holds the number of rows in the Inserted table
DECLARE @accountId int            
DECLARE @mediumId int            
DECLARE @status int            
DECLARE @listId int            
DECLARE @error int            
DECLARE @x int            

SET @rowCount = @@rowcount
IF @rowCount = 0 RETURN

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=T''
SET @tranName = object_name(@@procid) + CAST(trigger_nestlevel(@@procid) as nvarchar(2))

BEGIN TRANSACTION
SAVE TRANSACTION @tranName

-- Make sure we do not have a batch insert
IF @rowCount > 1 BEGIN
   SET @msg = ''Batch insert into shipping list item table not allowed.'' + @msgTag + ''>''
   EXECUTE error$raise @msg, 0, @tranName
   RETURN
END

-- Get the caller login from the spidLogin table
IF len(dbo.string$GetSpidLogin()) = 0 BEGIN
   SET @msg = ''Login not found for auditing purposes.'' + @msgTag + ''>''
   EXECUTE error$raise @msg, 0, @tranName
   RETURN
END

-- Make sure that the list is not a composite
IF EXISTS(SELECT 1 FROM SendList WHERE AccountId IS NULL AND ListId = (SELECT ListId FROM Inserted)) BEGIN
   SET @msg = ''Items may not be placed directly on a composite shipping list.'' + @msgTag + ''>''
   EXECUTE error$raise @msg, 0, @tranName
   RETURN
END

-- Verify that the list to which the item was inserted has not yet been transmitted.
SELECT @listStatus = Status,
       @accountId = AccountId
FROM   SendList
WHERE  ListId = (SELECT ListId FROM Inserted)
IF @listStatus >= 16 BEGIN
   SET @msg = ''Items cannot be added to a list that has obtained '' + dbo.string$statusName(1,16) + '' status.'' + @msgTag + ''>''
   EXECUTE error$raise @msg, 0, @tranName
   RETURN
END
ELSE IF NOT EXISTS(SELECT 1 FROM Medium WHERE MediumId = (SELECT MediumId FROM Inserted) AND AccountId = @accountId) BEGIN
   SET @msg = ''Medium must belong to same account as the list itself.'' + @msgTag + ''>''
   EXECUTE error$raise @msg, 0, @tranName
   RETURN
END

-- Make sure that the medium is at the enterprise
IF NOT EXISTS(SELECT 1 FROM Medium WHERE MediumId = (SELECT MediumId FROM Inserted) AND Location = 1) BEGIN
   SET @msg = ''Medium must reside at the enterprise in order to be placed on a shipping list.'' + @msgTag + ''>''
   EXECUTE error$raise @msg, 0, @tranName
   RETURN
END

-- Make sure that medium does not actively appear on more than one shipping list
IF EXISTS
   (
   SELECT 1
   FROM   SendListItem sli
   JOIN   Inserted i
     ON   i.MediumId = sli.MediumId
   WHERE  i.ItemId != sli.ItemId and i.Status != 1 and sli.Status not in (1, 512)
   )
BEGIN
   SET @msg = ''Medium may not actively appear on more than one shipping list.'' + @msgTag + ''>''
   EXECUTE error$raise @msg, 0, @tranName
   RETURN
END

-- Select the name of the list and the medium serial number from the Inserted table
SELECT @listId = i.ListId,
       @mediumId = i.MediumId,
       @serialNo = m.SerialNo,
       @listName = sl.ListName,
       @itemStatus = case i.Status when 2 then '''' when 8 then '' with verified (I) status'' end
FROM   Inserted i
JOIN   SendList sl
  ON   sl.ListId = i.ListId
JOIN   Medium m
  ON   m.MediumId = i.MediumId

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
   ''Medium '' + @serialNo + '' added to shipping list '' + @listName,
   dbo.string$GetSpidLogin()
)
SET @error = @@error
IF @error != 0 BEGIN
   SET @msg = ''Error encountered while inserting a new shipping list item audit record.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
   EXECUTE error$raise @msg, @error, @tranName
   RETURN
END

-- Make sure that the discrete list status is equal to the (translated) lowest status among its non-removed items.
SELECT @rowVersion = RowVersion 
FROM   SendList 
WHERE  ListId = @listId
EXECUTE sendList$setStatus @listId, @rowVersion

-- Commit
COMMIT TRANSACTION
END
'
)

-------------------------------------------------------------------------------
--
-- Trigger: receiveListItem$afterUpdate
--
-------------------------------------------------------------------------------
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

-- Make sure that media do not actively appear on more than one list
IF EXISTS
   (
   SELECT 1
   FROM   ReceiveListItem rli
   JOIN   Inserted i
     ON   i.MediumId = rli.MediumId
   WHERE  i.ItemId != rli.ItemId and i.Status != 1 and rli.Status not in (1, 512)
   )
BEGIN
   SET @msg = ''Medium may not actively appear on more than one receiving list.'' + @msgTag + ''>''
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

IF @@error != 0 GOTO ROLL_IT

-------------------------------------------------------------------------------
--
-- Trigger: receiveListItem$afterInsert
--
-------------------------------------------------------------------------------
IF EXISTS(SELECT * FROM sysobjects WHERE name = 'receiveListItem$afterInsert' AND objectproperty(id, 'ExecIsInsertTrigger' ) = 1) 
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'TRIGGER receiveListItem$afterInsert
ON     ReceiveListItem
WITH ENCRYPTION
AFTER  INSERT
AS
BEGIN
DECLARE @msg nvarchar(255)        -- used to preformat error message
DECLARE @msgTag nvarchar(255)     -- used to hold first part of error message header
DECLARE @tranName nvarchar(255)   -- used to hold name of savepoint
DECLARE @listName nchar(10)       -- holds the name of the receive list
DECLARE @listStatus int           -- holds the status of the list
DECLARE @serialNo nvarchar(32)    -- holds the serial number of the medium
DECLARE @itemStatus nvarchar(32)  -- holds the initial status of the item
DECLARE @rowVersion rowversion
DECLARE @accountId int            
DECLARE @mediumId int            
DECLARE @rowCount int             -- holds the number of rows in the Inserted table
DECLARE @status int            
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
   SET @msg = ''Batch insert into receive list item table not allowed.'' + @msgTag + ''>''
   EXECUTE error$raise @msg, 0, @tranName
   RETURN
END

-- Get the caller login from the spidLogin table
IF len(dbo.string$GetSpidLogin()) = 0 BEGIN
   SET @msg = ''Login not found for auditing purposes.'' + @msgTag + ''>''
   EXECUTE error$raise @msg, 0, @tranName
   RETURN
END

-- Make sure that the list is not a composite
IF EXISTS(SELECT 1 FROM ReceiveList WHERE AccountId IS NULL AND ListId = (SELECT ListId FROM Inserted)) BEGIN
   SET @msg = ''Items may not be placed directly on a composite receive list.'' + @msgTag + ''>''
   EXECUTE error$raise @msg, 0, @tranName
   RETURN
END

-- Verify that the list to which the item was inserted has not yet been transmitted, and
-- that the account of the list is the same as that of the medium.
SELECT @listStatus = Status,
       @accountId = AccountId
FROM   ReceiveList
WHERE  ListId = (SELECT ListId FROM Inserted)
IF @listStatus >= 4 BEGIN
   SET @msg = ''Items cannot be added to a list that has attained '' + dbo.string$statusName(2,4) + '' status.'' + @msgTag + ''>''
   EXECUTE error$raise @msg, 0, @tranName
   RETURN
END
ELSE IF NOT EXISTS(SELECT 1 FROM Medium WHERE MediumId = (SELECT MediumId FROM Inserted) AND AccountId = @accountId) BEGIN
   SET @msg = ''Medium must belong to same account as the list itself.'' + @msgTag + ''>''
   EXECUTE error$raise @msg, 0, @tranName
   RETURN
END

-- Make sure that the medium is at the vault
IF NOT EXISTS(SELECT 1 FROM Medium WHERE MediumId = (SELECT MediumId FROM Inserted) AND Location = 0) BEGIN
   SET @msg = ''Medium must reside at the vault in order to be placed on a receive list.'' + @msgTag + ''>''
   EXECUTE error$raise @msg, 0, @tranName
   RETURN
END

-- Make sure that medium does not actively appear on more than one list
IF EXISTS
   (
   SELECT 1
   FROM   ReceiveListItem rli
   JOIN   Inserted i
     ON   i.MediumId = rli.MediumId
   WHERE  i.ItemId != rli.ItemId and i.Status != 1 and rli.Status not in (1, 512)
   )
BEGIN
   SET @msg = ''Medium may not actively appear on more than one receiving list.'' + @msgTag + ''>''
   EXECUTE error$raise @msg, 0, @tranName
   RETURN
END

-- Select the name of the list and the medium serial number from the Inserted table
SELECT @listId = i.ListId,
       @mediumId = i.MediumId,
       @serialNo = m.SerialNo,
       @listName = rl.ListName 
FROM   Inserted i
JOIN   ReceiveList rl
  ON   rl.ListId = i.ListId
JOIN   Medium m
  ON   m.MediumId = i.MediumId

-- If the medium was missing, mark it as found
IF EXISTS (SELECT 1 FROM Medium WHERE MediumId = @mediumId AND Missing = 1) BEGIN
   UPDATE Medium
   SET    Missing = 0
   WHERE  MediumId = @mediumId
   SET @error = @@error
   IF @error != 0 BEGIN
      SET @msg = ''Error encountered while inserting a new receive list item audit record; could not reset medium missing status.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
      EXECUTE error$raise @msg, @error, @tranName
      RETURN
   END
END

-- Insert audit record
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
   4, 
   ''Medium '' + @serialNo + '' added to receiving list '' + @listName,
   dbo.string$GetSpidLogin()
)
SET @error = @@error
IF @error != 0 BEGIN
   SET @msg = ''Error encountered while inserting receive list item audit record.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
   EXECUTE error$raise @msg, @error, @tranName
   RETURN
END

-- Make sure that the discrete list status is equal to the 
-- (translated) lowest status among its non-removed items.
SELECT @rowVersion = RowVersion FROM ReceiveList WHERE ListId = @listId
EXECUTE receiveList$setStatus @listId, @rowVersion

-- Commit
COMMIT TRANSACTION
END
'
)

IF @@error != 0 GOTO ROLL_IT

-------------------------------------------------------------------------------
--
-- Trigger: medium$afterUpdate
--
-------------------------------------------------------------------------------
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
DECLARE @tranName nvarchar(255)    -- used to hold name of savepoint
DECLARE @audit nvarchar(3000)  -- used to hold the updated fields
DECLARE @tagInfo nvarchar(4000)    -- information from the SpidLogin table
DECLARE @caseName nvarchar(32)
DECLARE @iStatus int
DECLARE @rowcount int             -- holds the number of rows in the Deleted table
DECLARE @method int           -- method by which medium was moved
DECLARE @iid int
DECLARE @caseId int
DECLARE @codeId int
DECLARE @error int
DECLARE @login nvarchar(32)
DECLARE @returnValue int
DECLARE @messages nvarchar(4000)
DECLARE @delimiter nvarchar(10)
DECLARE @rowVersion rowversion
DECLARE @reason int
DECLARE @type int
DECLARE @id int
DECLARE @p1 int
DECLARE @i int
DECLARE @j int
-- Medium attribute variables
DECLARE @mid1 int
DECLARE @serial1 nvarchar(32)
DECLARE @location1 bit
DECLARE @hotStatus1 bit
DECLARE @missing1 bit
DECLARE @rdate1 nvarchar(10)
DECLARE @bside1 nvarchar(32)
DECLARE @tid1 int
DECLARE @aid1 int
DECLARE @serial2 nvarchar(32)
DECLARE @location2 bit
DECLARE @hotStatus2 bit
DECLARE @missing2 bit
DECLARE @rdate2 nvarchar(10)
DECLARE @bside2 nvarchar(32)
DECLARE @tid2 int
DECLARE @aid2 int
-- Table for medium differences
DECLARE @tbl1 table 
(
   RowNo int primary key clustered identity(1,1),
   Mid1 int,
   Serial1 nvarchar(32),
   Location1 bit,
   HotStatus1 bit,
   Missing1 bit,
   Rdate1 nvarchar(10),
   BSide1 nvarchar(32),
   Tid1 int,
   Aid1 int,
   Serial2 nvarchar(32),
   Location2 bit,
   HotStatus2 bit,
   Missing2 bit,
   Rdate2 nvarchar(10),
   BSide2 nvarchar(32),
   Tid2 int,
   Aid2 int
)
-- Table for inventory reconciliations
DECLARE @tbl2 table 
(
   RowNo int identity (1,1), 
   Id int, 
   Type int,  -- 1:Location, 2:Account, 3:ObjectType, 4:UnknownSerial
   Reason int
)

SET @rowcount = @@rowcount
IF @rowcount = 0 RETURN

SET NOCOUNT ON

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @delimiter = ''$|$''
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

-- -- Verify that any updated medium that resides inside a case has the
-- -- same hot status as the case itself.
-- SELECT TOP 1 @serialNo = i.SerialNo
-- FROM   Inserted i
-- JOIN   MediumSealedCase msc
--   ON   msc.MediumId = i.MediumId
-- JOIN   SealedCase sc
--   ON   sc.CaseId = msc.CaseId
-- WHERE  sc.HotStatus != i.HotStatus
-- ORDER BY i.SerialNo
-- IF @@rowcount > 0 BEGIN
--    SET @msg = ''Because medium '''''' + @serialNo + '''''' is in a sealed case, it must have the same hot site status as the case itself.'' + @msgTag + ''>''
--    EXECUTE error$raise @msg, 0, @tranName
--    RETURN
-- END

-- Disallow change of return date if medium is in sealed case.  Because we may
-- receive a return date change even if the user did not actually change the
-- return date (i.e. the case return date is kept in the medium detail object
-- for display purposes and then submitted to the medium$upd procedure, we will
-- want to confirm, if the tape is in a sealed case, that the return date
-- submitted is the same as the return date on the sealed case.
SELECT TOP 1 @serial1 = i.SerialNo,
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
   SET @msg = ''Medium '''''' + @serial1 + '''''' may not have its return date changed because it resides in sealed case '''''' + @caseName + ''''''.'' + @msgTag + ''>''
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

-- Gather media information into the temp table
INSERT @tbl1 (Mid1, Serial1, Location1, HotStatus1, Missing1, Rdate1, BSide1, Tid1, Aid1, Serial2, Location2, HotStatus2, Missing2, Rdate2, BSide2, Tid2, Aid2)
SELECT d.MediumId,
       d.SerialNo,
       d.Location,
       d.HotStatus,
       d.Missing,
       coalesce(convert(nvarchar(10),d.ReturnDate,120),''(None)''),
       d.BSide,
       d.TypeId,
       d.AccountId,
       i.SerialNo,
       i.Location,
       i.HotStatus,
       i.Missing,
       coalesce(convert(nvarchar(10),i.ReturnDate,120),''(None)''),
       i.BSide,
       i.TypeId,
       i.AccountId
FROM   Deleted d
JOIN   Inserted i
  ON   i.MediumId = d.MediumId
ORDER  BY d.SerialNo ASC

-- Initialize counter
SELECT @i = 1

-- Loop through the media in the update
WHILE 1 = 1 BEGIN
   SELECT @mid1 = Mid1,
          @serial1 = Serial1,
          @location1 = Location1,
          @hotStatus1 = HotStatus1,
          @missing1 = Missing1,
          @rdate1 = Rdate1,
          @bside1 = BSide1,
          @tid1 = Tid1,
          @aid1 = Aid1,
          @serial2 = Serial2,
          @location2 = Location2,
          @hotStatus2 = HotStatus2,
          @missing2 = Missing2,
          @rdate2 = Rdate2,
          @bside2 = BSide2,
          @tid2 = Tid2,
          @aid2 = Aid2
   FROM   @tbl1
   WHERE  RowNo = @i
   IF @@rowcount = 0 BREAK
   -- Clear the message table
   SELECT @messages = ''''
   -- Hot site status
   IF @hotStatus1 != @hotStatus2 BEGIN
      SELECT @messages = @messages + case @hotStatus2 when 1 then ''Medium regarded as at hot site'' else ''Medium no longer regarded as at hot site'' end + @delimiter
   END
   -- Missing status
   IF @missing1 != @missing2 BEGIN
      SELECT @messages = @messages + case @missing2 when 1 then ''Medium marked as missing'' else ''Medium marked as found'' end + @delimiter
   END
   -- Return date
   IF @rdate1 != @rdate2 BEGIN
      SELECT @messages = @messages + ''Return date changed to '' + @rdate2 + @delimiter
   END
   -- B-Side
   IF @bside1 != @bside2 BEGIN
      -- If there is a bside, make sure that it is unique
      IF len(@bside2) > 0 BEGIN
         IF EXISTS(SELECT 1 FROM Medium WHERE SerialNo = @bside2) BEGIN
            SET @msg = ''A medium currently exists with serial number '''''' + @bside2 + ''''''.'' + @msgTag + ''>''
            EXECUTE error$raise @msg, 0, @tranName
            RETURN
         END
         IF EXISTS(SELECT 1 FROM Medium WHERE BSide = @bside2) BEGIN
            SET @msg = ''A medium currently exists with serial number '''''' + @bside2 + '''''' as its b-side.'' + @msgTag + ''>''
            EXECUTE error$raise @msg, 0, @tranName
            RETURN
         END
         ELSE IF EXISTS(SELECT 1 FROM SealedCase WHERE SerialNo = @bside2) BEGIN
            SET @msg = ''A sealed case with serial number '''''' + @bside2 + '''''' already exists.'' + @msgTag + ''>''
            EXECUTE error$raise @msg, 0, @tranName
            RETURN
         END
         ELSE IF EXISTS(SELECT 1 FROM SendListCase WHERE SerialNo = @bside2 AND Cleared = 0) BEGIN
            SET @msg = ''A case with serial number '''''' + @bside2 + '''''' exists on an active shipping list.'' + @msgTag + ''>''
            EXECUTE error$raise @msg, 0, @tranName
            RETURN
         END
         ELSE IF EXISTS(SELECT 1 FROM MediumType WHERE TypeId = @tid2 AND (Container = 1 OR TwoSided = 0)) BEGIN
            SET @msg = ''A b-side serial number may not be assigned to a medium of one-sided type or to a container.'' + @msgTag + ''>''
            EXECUTE error$raise @msg, 0, @tranName
            RETURN
         END
      END
      -- Insert audit message
      SELECT @messages = @messages + ''B-side changed to '' + @bside2 + @delimiter
   END
   -- Medium type
   IF @tid1 != @tid2 BEGIN
      SELECT @messages = @messages + ''Medium type changed to '' + (SELECT TypeName FROM MediumType WHERE TypeId = @tid2) + @delimiter
   END
   -- Account
   IF @aid1 != @aid2 BEGIN
      SELECT @messages = @messages + ''Account changed to '' + (SELECT AccountName FROM Account WHERE AccountId = @aid2) + @delimiter
   END
   -- Serial number
   IF @serial1 != @serial2 BEGIN
      SELECT @messages = @messages + ''Serial number changed to '''''' + @serial2 + '''''''' + @delimiter
   END
   -- Insert audit records
   WHILE 1 = 1 BEGIN
      -- Get the position of the next delimiter
      SET @p1 = charindex(@delimiter, @messages)
      -- If no delimiter and no message, then break
      IF @p1 = 0 BEGIN
         IF len(@messages) = 0 BEGIN
            BREAK
         END
         ELSE BEGIN
            SELECT @msg = @messages
            SELECT @messages = ''''
         END
      END
      ELSE BEGIN
         SELECT @msg = left(@messages, @p1 - 1)
         SELECT @messages = substring(@messages, @p1 + len(@delimiter), 4000)
      END
      -- Insert the message
      INSERT XMedium(Object, Action, Detail, Login)
      VALUES(@serial1, 2, @msg, dbo.string$GetSpidLogin())
      SET @error = @@error
      IF @error != 0 BEGIN
         SET @msg = ''Error inserting a medium audit record.'' + @msgTag + '';Error='' + cast(@error as nvarchar(9)) + ''>''
         EXECUTE error$raise @msg, @error, @tranName
         RETURN
      END
   END
   -- If the medium is marked as missing, then we should disallow missing status if 
   -- the medium is verified on a send or receive list.  (If not verified, remove it from the list.)
   IF @missing1 = 0 AND @missing2 = 1 BEGIN
      -- Check send lists or receive lists
      IF @location2 = 1 BEGIN
         SELECT @iid = ItemId,
                @iStatus = Status,
                @rowVersion = RowVersion
         FROM   SendListItem
         WHERE  Status > 1 AND Status != 512 AND MediumId = @mid1
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
         WHERE  Status > 1 AND Status != 512 AND MediumId = @mid1
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
   IF @location1 != @location2 BEGIN
      -- Get the movement method
      IF CHARINDEX(''send'', @tagInfo) != 0 
         SET @method = 2                     -- send list cleared
      ELSE IF CHARINDEX(''receive'', @tagInfo) != 0 
         SET @method = 3                     -- receive list cleared
      ELSE IF CHARINDEX(''disaster'', @tagInfo) != 0 
         SET @method = 4                     -- receive list cleared
      ELSE
         SET @method = 1
      -- Insert the audit record
      INSERT XMediumMovement(Date, Object, Direction, Method, Login)
      VALUES(getutcdate(), @serial2, @location2, @method, dbo.string$GetSpidLogin())
      SET @error = @@error
      IF @error != 0 BEGIN
         SET @msg = ''Error inserting a row into the XMediumMovement table.'' + @msgTag + '';Error='' + cast(@error as nvarchar(9)) + ''>''
         EXECUTE error$raise @msg, @error, @tranName
         RETURN
      END
      -- If the medium was moved to the enterprise, remove it from sealed case and remove disaster code
      IF @location2 = 1 BEGIN
         SELECT @caseId = CaseId
         FROM   MediumSealedCase
         WHERE  MediumId = @mid1
         IF @@rowcount > 0 BEGIN
            EXECUTE @returnValue = mediumSealedCase$del @caseId, @mid1
            IF @returnValue != 0 BEGIN
               ROLLBACK TRANSACTION @tranName   
               COMMIT TRANSACTION
               RETURN
            END
         END
         SELECT @codeId = CodeId
         FROM   DisasterCodeMedium
         WHERE  MediumId = @mid1
         IF @@rowcount > 0 BEGIN
            EXECUTE @returnValue = disasterCodeMedium$del @codeId, @mid1
            IF @returnValue != 0 BEGIN
               ROLLBACK TRANSACTION @tranName   
               COMMIT TRANSACTION
               RETURN
            END
         END
      END
      -- If the tape is marked as missing, then remove the missing status
      IF @missing2 = 1 BEGIN
         UPDATE Medium
         SET    Missing = 0
         WHERE  MediumId = @mid1
         SET @error = @@error
         IF @error != 0 BEGIN
            SET @msg = ''Error removing missing status from medium that has had its location changed.'' + @msgTag + '';Error='' + cast(@error as nvarchar(9)) + ''>''
            EXECUTE error$raise @msg, @error, @tranName
            RETURN
         END
      END
   END
   -- If the account or location has been altered, remove entries from lists where appropriate.  If
   -- location was altered, make sure that it''s not because a move list was being cleared.
   IF @aid1 != @aid2 OR (@location1 != @location2 AND @method not in (2,3)) BEGIN
      -- Remove any send list items if we''re not clearing the list
      IF @method != 2 BEGIN
         SELECT @iid = ItemId, @rowVersion = RowVersion
         FROM   SendListItem
         WHERE  MediumId = @mid1 AND Status NOT IN (1,512)
         IF @@rowcount > 0 BEGIN
            EXECUTE @returnValue = sendListItem$remove @iid, @rowVersion, 1
            IF @returnValue != 0 BEGIN
   
               ROLLBACK TRANSACTION @tranName
               COMMIT TRANSACTION
               RETURN
            END
         END
      END
      -- Remove any receive list items if we''re not clearing the list
      IF @method != 3 BEGIN
         SELECT @iid = ItemId, @rowVersion = RowVersion
         FROM   ReceiveListItem
         WHERE  MediumId = @mid1 AND Status NOT IN (1,512)
         IF @@rowcount > 0 BEGIN
            EXECUTE @returnValue = receiveListItem$remove @iid, @rowVersion, 0, 1
            IF @returnValue != 0 BEGIN
               ROLLBACK TRANSACTION @tranName
               COMMIT TRANSACTION
               RETURN
            END
         END
      END
      -- Remove any submitted disaster code list items
      IF @method != 4 BEGIN
         SELECT @iid = ItemId, @rowVersion = RowVersion
         FROM   DisasterCodeListItem dli
         WHERE  MediumId = @mid1 AND Status NOT IN (1,512)
         IF @@rowcount > 0 BEGIN
            EXECUTE @returnValue = disasterCodeListItem$remove @iid, @rowVersion
            IF @returnValue != 0 BEGIN
               ROLLBACK TRANSACTION @tranName
               COMMIT TRANSACTION
               RETURN
            END
         END
      END
   END
   ----------------------------------------------------------------------------
   -- Inventory conflict resolutions
   ----------------------------------------------------------------------------
   DELETE FROM @tbl2
   -- Location resolutions
   IF @serial1 != @serial2 BEGIN
      INSERT @tbl2 (Id, Type, Reason)
      SELECT c.Id, 1, 3
      FROM   InventoryConflict c
      JOIN   InventoryConflictLocation l
        ON   l.Id = c.Id
      WHERE  c.SerialNo = @serial1
   END
   ELSE IF @missing1 != @missing2 BEGIN
      INSERT @tbl2 (Id, Type, Reason)
      SELECT c.Id, 1, 2
      FROM   InventoryConflict c
      JOIN   InventoryConflictLocation l
        ON   l.Id = c.Id
      WHERE  c.SerialNo = @serial1
   END
   ELSE IF @location1 != @location2 BEGIN
      INSERT @tbl2 (Id, Type, Reason)
      SELECT c.Id, 1, 1
      FROM   InventoryConflict c
      JOIN   InventoryConflictLocation l
        ON   l.Id = c.Id
      WHERE  c.SerialNo = @serial1
   END
   -- Account resolutions
   IF @serial1 != @serial2 BEGIN
      INSERT @tbl2 (Id, Type, Reason)
      SELECT c.Id, 2, 2
      FROM   InventoryConflict c
      JOIN   InventoryConflictAccount a
        ON   a.Id = c.Id
      WHERE  c.SerialNo = @serial1
   END
   ELSE IF @aid1 != @aid2 BEGIN
      INSERT @tbl2 (Id, Type, Reason)
      SELECT c.Id, 2, 1
      FROM   InventoryConflict c
      JOIN   InventoryConflictAccount a
        ON   a.Id = c.Id
      JOIN   Inserted i
        ON   i.AccountId = a.AccountId
      WHERE  c.SerialNo = @serial1 AND i.MediumId = @mid1
   END
   -- Object type resolutions
   IF @serial1 != @serial2 BEGIN
      INSERT @tbl2 (Id, Type, Reason)
      SELECT c.Id, 3, 2
      FROM   InventoryConflict c
      JOIN   InventoryConflictObjectType o
        ON   o.Id = c.Id
      WHERE  c.SerialNo = @serial1
   END
   ELSE IF @tid1 != @tid2 BEGIN
      INSERT @tbl2 (Id, Type, Reason)
      SELECT c.Id, 3, 1
      FROM   InventoryConflict c
      JOIN   InventoryConflictObjectType o
        ON   o.Id = c.Id
      JOIN   Inserted i
        ON   i.TypeId = o.TypeId
      WHERE  c.SerialNo = @serial1 AND i.MediumId = @mid1
   END
   -- Unknown medium resolutions
   IF @serial1 != @serial2 BEGIN
      INSERT @tbl2 (Id, Type, Reason)
      SELECT c.Id, 4, 2
      FROM   InventoryConflict c
      JOIN   InventoryConflictUnknownSerial s
        ON   s.Id = c.Id
      WHERE  c.SerialNo = @serial1
   END
   -- Cycle through the discrepancies
   SELECT @j = min(RowNo) FROM @tbl2
   WHILE 1 = 1 BEGIN
      SELECT @id = Id, @type = Type, @reason = Reason
      FROM   @tbl2
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

IF @@error != 0 GOTO ROLL_IT

-------------------------------------------------------------------------------
--
-- Procedure: sendListCase$ins
--
-------------------------------------------------------------------------------
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'sendListItem$ins')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.sendListItem$ins
(
   @serialNo nvarchar(32),       -- medium serial number
   @initialStatus int,           -- status of the list item upon addition
   @caseName nvarchar(32),       -- name of case to which medium assigned
   @returnDate datetime,         -- return date of medium
   @notes nvarchar(1000),        -- any notes to attach to the medium
   @batchLists nvarchar(4000),   -- lists to any of which we would prefer to add this medium
   @newList nvarchar(10) OUTPUT  -- name of new list, empty string if no new list produced
)
WITH ENCRYPTION
AS
BEGIN
DECLARE @msg as nvarchar(255)        -- used to preformat error message
DECLARE @msgTag as nvarchar(255)     -- used to hold first part of error message header
DECLARE @tranName as nvarchar(255)   -- used to hold name of savepoint
DECLARE @rowCount as int
DECLARE @error as int
DECLARE @missing as bit
DECLARE @location as bit
DECLARE @mediumId as int
DECLARE @accountId as int
DECLARE @listId as int
DECLARE @returnValue as int
DECLARE @caseId as int
DECLARE @itemId as int
DECLARE @priorId as int            -- id of list item if already on a list
DECLARE @priorStatus as int        -- status of list item if already on a list
DECLARE @priorVersion rowversion   -- rowversion of list item already on list
DECLARE @rowVersion rowversion
DECLARE @status rowversion

SET NOCOUNT ON

-- Tweak parameters
SET @returnDate = cast(convert(nchar(10),@returnDate,120) as datetime)
SET @batchLists = ltrim(rtrim(coalesce(@batchLists,'''')))
SET @caseName = ltrim(rtrim(coalesce(@caseName,'''')))
SET @notes = ltrim(rtrim(coalesce(@notes,'''')))
SET @serialNo = ltrim(rtrim(@serialNo))
SET @newList = ''''

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=P''
SET @tranName = object_name(@@procid) + CAST(@@nestlevel as nvarchar(2))

-- The initial status must be either submitted or verified
IF @initialStatus NOT IN (2,8) BEGIN
   SET @msg = ''Invalid initial status value.'' + @msgTag + ''>''
   RAISERROR(@msg,16,1)
   RETURN -100
END

-- Begin the transaction here in case we have to add a case
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

-- Is the medium being assigned to a case?
IF len(@caseName) > 0 BEGIN
   -- Verify that the case does not actively appear on any list outside of this batch.
   IF EXISTS
      (
      SELECT 1
      FROM   SendListCase slc
      JOIN   SendListItemCase slic
        ON   slic.CaseId = slc.CaseId
      JOIN   SendListItem sli
        ON   sli.ItemId = slic.Itemid
      JOIN   SendList sl
        ON   sli.ListId = sl.ListId
      WHERE  slc.Cleared = 0 AND sli.Status not in (1,512) AND slc.SerialNo = @caseName AND CHARINDEX(sl.ListName,@batchLists) = 0
      )
   BEGIN
      ROLLBACK TRANSACTION @tranName
      COMMIT TRANSACTION
      SET @msg = ''Case '' + @caseName + '' currently appears on an active send list.'' + @msgTag + ''>''
      RAISERROR(@msg,16,1)
      RETURN -100
   END
   -- If there is a non-empty sealed case of the same name at the vault, then raise an error
   IF EXISTS
     (
     SELECT 1
     FROM   SealedCase c
     JOIN   MediumSealedCase m
       ON   m.CaseId = c.CaseId
     WHERE  c.SerialNo = @caseName
     )
   BEGIN
      ROLLBACK TRANSACTION @tranName
      COMMIT TRANSACTION
      SET @msg = ''Case '' + @caseName + '' is currently at the vault as a populated sealed case.'' + @msgTag + ''>''
      RAISERROR(@msg,16,1)
      RETURN -100
   END
END

-- If the medium exists, get its id, location, and account.  Otherwise 
-- add the medium dynamically.  If the medium exists raise an error if
-- the location is at the vault or if the medium actively appears on
-- another send list as verified or transmitted.  If it appears as
-- submitted, remove it from the prior list.
SELECT @mediumId = MediumId,
       @location = Location,
       @missing = Missing,
       @accountId = AccountId
FROM   Medium
WHERE  SerialNo = @serialNo
IF @@rowCount = 0 BEGIN
   EXECUTE @returnValue = medium$addDynamic @serialNo, 1, @mediumId OUTPUT
   IF @returnValue != 0 BEGIN
      ROLLBACK TRANSACTION @tranName
      COMMIT TRANSACTION
      RETURN -100
   END
   ELSE BEGIN
      SELECT @mediumId = MediumId,
             @location = Location,
             @accountId = AccountId
      FROM   Medium
      WHERE  MediumId = @mediumId
   END
END
ELSE BEGIN
   -- location check
   IF @location = 0 BEGIN
      ROLLBACK TRANSACTION @tranName
      COMMIT TRANSACTION
      SET @msg = ''Medium '''''' + @serialNo + '''''' is already at the vault.'' + @msgTag + ''>''
      RAISERROR(@msg,16,1)
      RETURN -100
   END
   -- If the medium was missing, mark it as found
   IF @missing = 1 BEGIN
      UPDATE Medium
      SET    Missing = 0
      WHERE  MediumId = @mediumId
      SET @error = @@error
      IF @error != 0 BEGIN
         ROLLBACK TRANSACTION @tranName
         COMMIT TRANSACTION
         SET @msg = ''Unable to restore missing status of medium '''''' + @serialNo + ''''''.'' + @msgTag + ''>''
         RAISERROR(@msg,16,1)
         RETURN -100
      END
   END
   -- check other lists
   SELECT @priorId = sli.ItemId,
          @priorStatus = sli.Status,
          @priorVersion = sli.RowVersion
   FROM   SendListItem sli
   JOIN   SendList sl
     ON   sl.ListId = sli.ListId
   WHERE  sli.Status > 1 AND sli.Status != 512 AND
          sli.MediumId = @mediumId AND
          CHARINDEX(sl.ListName,@batchLists) = 0
   IF @@rowCount > 0 BEGIN
      IF @priorStatus > 2 BEGIN
         ROLLBACK TRANSACTION @tranName
         COMMIT TRANSACTION
         SET @msg = ''Medium '''''' + @serialNo + '''''' resides on another active send list.'' + @msgTag + ''>''
         RAISERROR(@msg,16,1)
         RETURN -100
      END
      ELSE BEGIN
         EXECUTE @returnValue = sendListItem$remove @priorId, @priorVersion
         IF @returnValue != 0 BEGIN
            ROLLBACK TRANSACTION @tranName
            COMMIT TRANSACTION
            RETURN -100
         END
      END
   END
END

-- Check the account of the medium to see if we have already produced a list
-- for this account within this batch.  If we have, then add it to that list.
-- (If the item already appears on the list as removed, update its status to
-- to the initial status.)
IF len(@batchLists) > 0 BEGIN
   SELECT @listId = ListId
   FROM   SendList 
   WHERE  AccountId = @accountId AND CHARINDEX(ListName,@batchLists) > 0
   IF @@rowCount > 0 BEGIN
      SELECT @itemId = ItemId,
             @status = Status
      FROM   SendListItem
      WHERE  ListId = @listId AND MediumId = @mediumId
      IF @@rowCount > 0 BEGIN
         IF @status != 1 BEGIN
            ROLLBACK TRANSACTION @tranName
            COMMIT TRANSACTION
            SET @msg = ''Medium '''''' + @serialNo + '''''' already appears on a list within this batch.'' + @msgTag + ''>''
            RAISERROR(@msg,16,1)
            RETURN -100
         END
         ELSE BEGIN
            UPDATE SendListItem
            SET    Status = @initialStatus,
                   ReturnDate = @returnDate
            WHERE  ItemId = @itemId
            SET @error = @@error
            IF @error != 0 BEGIN
               ROLLBACK TRANSACTION @tranName
               COMMIT TRANSACTION
               SET @msg = ''Error encountered while restoring previously removed medium on list.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
               EXECUTE error$raise @msg, @error
               RETURN -100
            END
         END
      END
   END
END

-- If we have no list, create one
IF @listId IS NULL BEGIN
   EXECUTE @returnValue = sendList$create @accountId, @newList OUTPUT
   IF @returnValue != 0 BEGIN
      ROLLBACK TRANSACTION @tranName
      COMMIT TRANSACTION
      RETURN -100
   END
   ELSE BEGIN
      SELECT @listId = ListId
      FROM   SendList
      WHERE  ListName = @newList
   END
END

-- Add the item if it was not restored
IF @itemId IS NULL BEGIN
   INSERT SendListItem
   (
      Status, 
      ListId,
      ReturnDate,
      MediumId,
      Notes
   )
   VALUES
   (
      @initialStatus,
      @listId, 
      @returnDate,
      @mediumId,
      @notes
   )
   SET @error = @@error
   IF @error = 0
      SET @itemId = scope_identity()
   ELSE BEGIN
      ROLLBACK TRANSACTION @tranName
      COMMIT TRANSACTION
      SET @msg = ''Error inserting a new row into the send list item table.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
      EXECUTE error$raise @msg, @error
      RETURN -100
   END
END

-- If we have a case, add the item to it.
IF len(@caseName) != 0 BEGIN
   EXECUTE @returnValue = sendListItemCase$ins @itemId, @caseName, @batchLists
   IF @returnValue != 0 BEGIN
      ROLLBACK TRANSACTION @tranName
      COMMIT TRANSACTION
      RETURN -100
   END
END

-- Attach notes to the medium here.  We''ll do this manually rather than go
-- through medium$upd because to do so would involve unnecessary overhead.  Unlike
-- with a receive list, we will allow blank notes to overwrite existing notes.
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

-- Commit the transaction
COMMIT TRANSACTION
RETURN 0
END
'
)

IF @@error != 0 GOTO ROLL_IT

-------------------------------------------------------------------------------
--
-- Version update
--
-------------------------------------------------------------------------------
IF NOT EXISTS(SELECT 1 FROM DatabaseVersion WHERE Major = 1 AND Minor = 3 AND Revision = 7) BEGIN
   EXECUTE spidLogin$ins 'System', 'Insert database version'
   INSERT DatabaseVersion (Major, Minor, Revision) 
   VALUES (1, 3, 7)
   EXECUTE spidLogin$del
END
ELSE BEGIN
   UPDATE DatabaseVersion 
   SET    InstallDate = getutcdate() 
   WHERE  Major = 1 AND Minor = 3 AND Revision = 7
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
