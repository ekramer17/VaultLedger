SET NOCOUNT ON

-- Should we run this script?
IF dbo.bit$doScript('1.3.6') = 1 BEGIN

DECLARE @CREATE nvarchar(10)

BEGIN TRANSACTION
-------------------------------------------------------------------------------
--
-- Procedure: sendListItem$ins
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

-- If the item is assigned to a case, verify that the case does not actively 
-- appear on any list outside of this batch.
IF len(@caseName) > 0 BEGIN
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
      WHERE  slc.Cleared = 0 AND
             sli.Status > 1 AND sli.Status != 512 AND
             slc.SerialNo = @caseName AND
             CHARINDEX(sl.ListName,@batchLists) = 0
      )
   BEGIN
      ROLLBACK TRANSACTION @tranName
      COMMIT TRANSACTION
      SET @msg = ''Case '''''' + @caseName + '''''' currently appears on an active send list.'' + @msgTag + ''>''
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

IF @@error != 0 GOTO ROLL_IT -- Rollback on error

-------------------------------------------------------------------------------
--
-- Procedure: sendListItem$add
--
-------------------------------------------------------------------------------
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'sendListItem$add')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.sendListItem$add
(
   @serialNo nvarchar(32),      -- medium serial number
   @initialStatus int,          -- status of the list item
   @caseName nvarchar(32),      -- name of case to which medium assigned
   @returnDate datetime,        -- return date of medium
   @notes nvarchar(1000),       -- any notes to attach to the medium
   @listId int                  -- list to which item should be added
)
WITH ENCRYPTION
AS
BEGIN
DECLARE @msg as nvarchar(255)      -- used to preformat error message
DECLARE @msgTag as nvarchar(255)    -- used to hold first part of error message header
DECLARE @tranName as nvarchar(255)   -- used to hold name of savepoint
DECLARE @error as int
DECLARE @caseId as int
DECLARE @itemId as int
DECLARE @location as bit
DECLARE @priorId as int
DECLARE @mediumId as int
DECLARE @missing as bit
DECLARE @accountId as int
DECLARE @listStatus as int
DECLARE @listAccount as int
DECLARE @returnValue as int
DECLARE @priorList as int
DECLARE @priorStatus as int
DECLARE @priorVersion as rowversion

SET NOCOUNT ON

-- Tweak parameters
SET @returnDate = cast(convert(nchar(10),@returnDate,120) as datetime)
SET @caseName = ltrim(rtrim(coalesce(@caseName,'''')))
SET @serialNo = ltrim(rtrim(coalesce(@serialNo,'''')))
SET @notes = ltrim(rtrim(coalesce(@notes,'''')))

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=P''
SET @tranName = object_name(@@procid) + CAST(@@nestlevel as nvarchar(2))

-- Verify that the list exists
SELECT @listAccount = AccountId,
       @listStatus = Status
FROM   SendList
WHERE  ListId = @listId
IF @@rowCount = 0 BEGIN
   SET @msg = ''Send list not found.'' + @msgTag + ''>''
   RAISERROR(@msg,16,1)
   RETURN -100
END
ELSE IF @listStatus >= 16 AND @listStatus != 512 BEGIN
   SET @msg = ''Send list may not be altered once it has achieved '' + dbo.string$statusName(1,16) + '' status.'' + @msgTag + ''>''
   RAISERROR(@msg,16,1)
   RETURN -100
END

-- Make sure that the medium is not already on the list.  If it does, just return.
IF EXISTS 
   (
   SELECT 1 
   FROM   SendListItem sli 
   JOIN   Medium m 
     ON   m.MediumId = sli.MediumId 
   WHERE  m.SerialNo = @serialNo AND sli.Status != 1 AND ListId = @listId
   ) 
BEGIN
   RETURN 0
END

-- The initial status must be either submitted or verified
IF @initialStatus NOT IN (2,8) BEGIN
   SET @msg = ''Invalid initial status value.'' + @msgTag + ''>''
   RAISERROR(@msg,16,1)
   RETURN -100
END

-- Begin the transaction here in case we have to add a case
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

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
   -- check current lists
   SELECT @priorId = ItemId,
          @priorStatus = Status,
          @priorVersion = RowVersion
   FROM   SendListItem
   WHERE  Status > 1 AND Status != 512 AND
          MediumId = @mediumId
   IF @@rowCount > 0 BEGIN
      IF @priorStatus > 2 BEGIN
         ROLLBACK TRANSACTION @tranName
         COMMIT TRANSACTION
         SET @msg = ''Medium '''''' + @serialNo + '''''' currently resides on an active send list.'' + @msgTag + ''>''
         RAISERROR(@msg,16,1)
         RETURN -100
      END
      ELSE BEGIN
         -- If the prior list is this list or any of the lists under this list
         -- (if it is a composite) then rollback and return.  Otherwise, remove the
         -- medium from the prior list.
         IF @priorId = @listId OR EXISTS(SELECT 1 FROM SendList WHERE ListId = @priorId AND CompositeId = @listId) BEGIN
            ROLLBACK TRANSACTION @tranName
            COMMIT TRANSACTION
            RETURN 0
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
   -- If the medium has been removed from this list, restore it
   ELSE BEGIN
      SELECT @priorId = sli.ItemId,
             @priorList = sl.ListId
      FROM   SendListItem sli
      JOIN   SendList sl
        ON   sl.ListId = sli.ListId
      WHERE  sli.Status = 1 AND
             sli.MediumId = @mediumId AND
            (sl.ListId = @listId OR coalesce(sl.CompositeId,0) = @listId)
      IF @@rowCount > 0 BEGIN
         UPDATE SendListItem
         SET    Status = @initialStatus,
                ReturnDate = @returnDate
         WHERE  ItemId = @priorId
         SET @error = @@error
         IF @error != 0 BEGIN
            ROLLBACK TRANSACTION @tranName
            COMMIT TRANSACTION
            SET @msg = ''Error encountered while restoring item to send list.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
            EXECUTE error$raise @msg, @error
            RETURN -100
         END
         ELSE BEGIN
            -- Insert into case if necessary; we don''t have to worry about removing from an old
            -- case, since when an item is removed from a list it is at that time removed from
            -- any case it may have been in.
            SET @itemId = @priorId
            GOTO UPDATECASE
         END
      END
   END
END

-- If the list is a composite, verify that there is a list within the composite
-- that has the same account as the medium.  If the list is discrete, verify
-- that it has the same account as the medium.
IF @listAccount IS NULL BEGIN
   SELECT @listId = ListId
   FROM   SendList
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

-- Insert the list item
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
IF @error = 0 BEGIN
   SET @itemId = scope_identity()
END
ELSE BEGIN
   ROLLBACK TRANSACTION @tranName
   COMMIT TRANSACTION
   SET @msg = ''Error inserting a new row into the send list item table.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
   EXECUTE error$raise @msg, @error
   RETURN -100
END

UPDATECASE:
-- If we have a case, add the item to it.
IF len(@caseName) != 0 BEGIN
   EXECUTE @returnValue = sendListItemCase$ins @itemId, @caseName
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

IF @@error != 0 GOTO ROLL_IT -- Rollback on error

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

-- Make sure that the medium does not appear actively more than once
IF EXISTS
   (
   SELECT 1 
   FROM   SendListItem
   WHERE  MediumId = (SELECT MediumId FROM Inserted) AND Status != 1 AND Status != 512
   GROUP  BY MediumId
   HAVING count(*) > 1
  )
BEGIN
   SET @msg = ''Medium may not actively appear on more than one shipping list'' + @msgTag + ''>''
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

IF @@error != 0 GOTO ROLL_IT -- Rollback on error


-------------------------------------------------------------------------------
--
-- Procedure: medium$ins
--
-------------------------------------------------------------------------------
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'medium$ins')
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
DECLARE @x as nvarchar(256)
DECLARE @y as nvarchar(256)

SET NOCOUNT ON

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=P''
SET @tranName = object_name(@@procid) + CAST(@@nestlevel as nvarchar(2))

-- If medium is at enterprise, then return date must be NULL and hot status must be 0
IF @location = 1 BEGIN
   SET @hotStatus = 0
   SET @returnDate = NULL 
END

-- If we have either no account or no medium type, get the defaults
IF len(coalesce(@accountName,'''')) = 0 OR len(coalesce(@mediumType,'''')) = 0 BEGIN
   EXECUTE @returnValue = barCodePattern$getDefaults @serialNo, @x out, @y out
   IF @returnValue = -100 BEGIN
      SET @msg = ''Unable to determine medium type and account defaults for new medium.'' + @msgTag + ''>''
      RAISERROR(@msg,16,1)
      RETURN -100
   END
   -- Medium type?
   IF len(coalesce(@mediumType,'''')) = 0 BEGIN
      SET @mediumType = @x
   END
   -- Account?
   IF len(coalesce(@accountName,'''')) = 0 BEGIN
      SET @accountName = @y
   END
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

IF @@error != 0 GOTO ROLL_IT

-------------------------------------------------------------------------------
--
-- Procedure: medium$upd
--
-------------------------------------------------------------------------------
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'medium$upd')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.medium$upd
(
   @id int,
   @serialNo nvarchar(32),       -- serial number of medium
   @location bit,                -- flag whether medium is at enterprise (1) or vault (0)
   @hotStatus bit,               -- flag indicating hot status
   @missing bit,                 -- flag indicating missing status
   @returnDate datetime,         -- date of scheduled return from vault
   @bSide nvarchar(32),          -- serial number of b-side
   @notes nvarchar(4000),        -- random notes about medium
   @mediumType nvarchar(128),    -- type of the medium
   @account nvarchar(256),       -- account to which medium belongs
   @rowVersion rowVersion
)
WITH ENCRYPTION
AS
BEGIN
DECLARE @msg as nvarchar(255)        -- used to preformat error message
DECLARE @msgTag as nvarchar(255)     -- used to hold first part of error message header
DECLARE @tranName as nvarchar(255)   -- used to hold name of savepoint
DECLARE @twoSided as bit
DECLARE @rowCount as int
DECLARE @accountId as int
DECLARE @listName as nvarchar(10)
DECLARE @status as int
DECLARE @typeId as int
DECLARE @error as int
DECLARE @loc1 as bit
DECLARE @acc1 as int

SET NOCOUNT ON

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=P''
SET @tranName = object_name(@@procid) + CAST(@@nestlevel as nvarchar(2))

-- If medium is at enterprise, then return date must be NULL and hot status must be 0
IF @location = 1 BEGIN
   SET @hotStatus = 0
   SET @returnDate = NULL
END

-- Get the account id
SELECT @accountId = AccountId
FROM   Account
WHERE  AccountName = @account
IF @@rowcount = 0 BEGIN
   SET @msg = ''Account not found.'' + @msgTag + ''>''
   RAISERROR(@msg,16,1)
   RETURN -100
END

-- Get the medium type
SELECT @typeId = TypeId
FROM   MediumType
WHERE  TypeName = @mediumType AND Container = 0
IF @@rowcount = 0 BEGIN
   SET @msg = ''Medium type not found.'' + @msgTag + ''>''
   RAISERROR(@msg,16,1)
   RETURN -100
END

-- Get the current location and account id
SELECT @loc1 = Location, @acc1 = AccountId
FROM   Medium 
WHERE  MediumId = @id

-- If the tape is beyond transmitted on an active list, then we should disallow movement and account change.
IF @loc1 != @location OR @acc1 != @accountId BEGIN
   -- Disallow movement change if a medium is active and has been transmitted on a send or receive list.
   IF EXISTS (SELECT 1 FROM SendListItem WHERE MediumId = @id AND Status IN (16,32,64,128,256)) BEGIN
      -- Get the list name and status
      SELECT @listName = sl.ListName, @status = sl.Status 
      FROM   SendList sl
      JOIN   SendListItem sli
        ON   sli.ListId = sl.ListId
      WHERE  sli.MediumId = @id AND sl.Status IN (16,32,64,128,256)
      -- Location or account?
      IF @loc1 != @location BEGIN
         -- Raise the error
         SET @msg = ''Medium '' + @serialNo + '' may not be moved because it appears on list '' + @listName + '', which has attained '' + dbo.string$statusName(1,@status) + '' status.'' + @msgTag + ''>''
         RAISERROR(@msg, 16, 1)
         RETURN -100
      END
      ELSE IF @acc1 != @accountId BEGIN
         -- Raise the error
         SET @msg = ''Medium '' + @serialNo + '' may not have its account changed because it appears on list '' + @listName + '', which has attained '' + dbo.string$statusName(1,@status) + '' status.'' + @msgTag + ''>''
         RAISERROR(@msg, 16, 1)
         RETURN -100
      END
   END
   ELSE IF EXISTS (SELECT 1 FROM ReceiveListItem WHERE MediumId = @id AND Status IN (16,32,64,128,256)) BEGIN
      -- Get the list name and status
      SELECT @listName = rl.ListName, @status = rl.Status 
      FROM   ReceiveList rl
      JOIN   ReceiveListItem rli
        ON   rli.ListId = rl.ListId
      WHERE  rli.MediumId = @id AND rl.Status IN (4,8,16,32,64,128,256)
      -- Location or account?
      IF @loc1 != @location BEGIN
         -- Raise the error
         SET @msg = ''Medium '' + @serialNo + '' may not be moved because it appears on list '' + @listName + '', which has attained '' + dbo.string$statusName(2,@status) + '' status.'' + @msgTag + ''>''
         RAISERROR(@msg, 16, 1)
         RETURN -100
      END
      ELSE IF @acc1 != @accountId BEGIN
         -- Raise the error
         SET @msg = ''Medium '' + @serialNo + '' may not have its account changed because it appears on list '' + @listName + '', which has attained '' + dbo.string$statusName(2,@status) + '' status.'' + @msgTag + ''>''
         RAISERROR(@msg, 16, 1)
         RETURN -100
      END
   END
END

-- Update medium
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

-- If the location was changed, then we should set the last moved date
IF EXISTS(SELECT 1 FROM Medium WHERE MediumId = @id AND Location != @location) BEGIN
   UPDATE Medium
   SET    SerialNo = @serialNo,
          Location = @location,
          LastMoveDate = cast(convert(nchar(19),getutcdate(),120) as datetime),
          HotStatus = @hotStatus,
          Missing = @missing,
          ReturnDate = @returnDate,
          BSide = @bSide,
          Notes = @notes,
          TypeId = @typeId,
          AccountId = @accountId
   WHERE  MediumId = @id AND
          RowVersion = @rowVersion
END
ELSE BEGIN
   UPDATE Medium
   SET    SerialNo = @serialNo,
          HotStatus = @hotStatus,
          Missing = @missing,
          ReturnDate = @returnDate,
          BSide = @bSide,
          Notes = @notes,
          TypeId = @typeId,
          AccountId = @accountId
   WHERE  MediumId = @id AND
          RowVersion = @rowVersion
END

SELECT @error = @@error, @rowCount = @@rowcount

IF @error != 0 BEGIN
   ROLLBACK TRANSACTION @tranName
   COMMIT TRANSACTION
   SET @msg = ''Error encountered while updating medium.'' + @msgTag + '';Error='' +  cast(@error as nvarchar(50)) + ''>''
   EXECUTE error$raise @msg, @error
   RETURN -100
END
ELSE IF @rowCount = 0 BEGIN
   IF EXISTS(SELECT 1 FROM Medium WHERE MediumId = @id) BEGIN
      ROLLBACK TRANSACTION @tranName
      COMMIT TRANSACTION
      SET @msg = ''Medium has been modified since retrieval.'' + @msgTag + ''>''
      RAISERROR(@msg,16,1)
      RETURN -100
   END
   ELSE BEGIN
      ROLLBACK TRANSACTION @tranName
      COMMIT TRANSACTION
      SET @msg = ''Medium does not exist.'' + @msgTag + ''>''
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
   -- If location or account has been altered, remove entries from lists of any type.
   IF @location1 != @location2 OR @aid1 != @aid2 BEGIN
      -- Remove any send list items if we''re not clearing the list
      SELECT @iid = ItemId, @rowVersion = RowVersion
      FROM   SendListItem
      WHERE  @method != 2 AND MediumId = @mid1 AND Status NOT IN (1,512)
      IF @@rowcount > 0 BEGIN
         EXECUTE @returnValue = sendListItem$remove @iid, @rowVersion, 1
         IF @returnValue != 0 BEGIN

            ROLLBACK TRANSACTION @tranName
            COMMIT TRANSACTION
            RETURN
         END
      END
      -- Remove any receive list items if we''re not clearing the list
      SELECT @iid = ItemId, @rowVersion = RowVersion
      FROM   ReceiveListItem
      WHERE  @method != 3 AND MediumId = @mid1 AND Status NOT IN (1,512)
      IF @@rowcount > 0 BEGIN
         EXECUTE @returnValue = receiveListItem$remove @iid, @rowVersion, 0, 1
         IF @returnValue != 0 BEGIN
            ROLLBACK TRANSACTION @tranName
            COMMIT TRANSACTION
            RETURN
         END
      END
      -- Remove any submitted disaster code list items
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

---------------------------------------------------------------------------------
----
---- Procedure: sealedCase$browse
----
---------------------------------------------------------------------------------
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'sealedCase$browse')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.sealedCase$browse
WITH ENCRYPTION
AS
BEGIN
DECLARE @tbl1 table (RowNo int identity(1,1), CaseId int, SerialNo nvarchar(256), TypeName nvarchar(256), Sealed bit, Location bit, ReturnDate nvarchar(10), NumTapes int, ListName nvarchar(10), Notes nvarchar(3000), HotStatus bit, RowVersion binary(8))
DECLARE @listName nvarchar(10)
DECLARE @compositeId int
DECLARE @status int
DECLARE @loc int
DECLARE @id int
DECLARE @i int

SET NOCOUNT ON

-- Get the sealed cases
INSERT @tbl1 (CaseId, SerialNo, TypeName, Sealed, Location, ReturnDate, ListName, Notes, HotStatus, RowVersion)
SELECT c.CaseId, c.SerialNo, t.TypeName, 1, 0, isnull(convert(nvarchar(10),c.ReturnDate,120),''''), '''', c.Notes, c.HotStatus, c.RowVersion
FROM   SealedCase c
JOIN   MediumType t
  ON   t.TypeId = c.TypeId

-- Get the medium counts and list names for the sealed cases
SET @i = 1
WHILE 1 = 1 BEGIN
   SELECT @id = CaseId
   FROM   @tbl1
   WHERE  RowNo = @i
   -- If no rows retrieved then break
   IF @@rowcount = 0 BREAK
   -- Get the medium count
   UPDATE @tbl1
   SET    NumTapes = (SELECT count(*) FROM MediumSealedCase WHERE CaseId = @id)
   WHERE  RowNo = @i
   -- Get the location...if the tape is on a receive list and the status
   -- is arrived or greater, then the location is at the enterprise.
   SELECT TOP 1 @listName = r.ListName, 
          @compositeId = r.CompositeId,
          @status = r.Status
   FROM   ReceiveList r
   JOIN   ReceiveListItem ri
     ON   ri.ListId = r.ListId
   JOIN   MediumSealedCase c
     ON   c.MediumId = ri.MediumId
   WHERE  c.CaseId = @id AND r.Status != 512
   IF @@rowcount != 0 BEGIN
      IF @compositeId IS NOT NULL BEGIN
         SELECT @listName = ListName
         FROM   ReceiveList
         WHERE  ListId = @compositeId
      END
      -- Set the location
--      IF @status >= 64 SET @loc = 1 ELSE SET @loc = 0
      -- Update the table
      UPDATE @tbl1
      SET    Location = isnull(@loc,0),
             ListName = @listName
      WHERE  RowNo = @i
   END
   -- Increment counter
   SET @i = @i + 1
END

-- Select results in case name order
SELECT CaseId, 
       SerialNo, 
       TypeName, 
       Sealed, 
       Location, 
       ReturnDate, 
       NumTapes, 
       ListName,
       Notes,
       HotStatus,
       RowVersion
FROM   @tbl1
ORDER  BY SerialNo ASC

END
'
)

GOTO ROLL_IT --IF @@error != 0 GOTO ROLL_IT ZZZ

-------------------------------------------------------------------------------
--
-- Procedure: inventoryConflict$resolveAccount
--
-------------------------------------------------------------------------------
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'inventoryConflict$resolveAccount')
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

-- Get the caller login from the spidLogin table
IF len(dbo.string$GetSpidLogin()) = 0 BEGIN
   SET @msg = ''Caller login not found in spid login table.'' + @msgTag + ''>''
   RAISERROR(@msg,16,1)
   RETURN -100
END

-- Begin transaction
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

-- Delete the conflict
DELETE InventoryConflict
WHERE  Id = @id
SELECT @error = @@error
IF @error != 0 BEGIN
   ROLLBACK TRANSACTION @tranName
   COMMIT TRANSACTION
   SET @msg = ''Error encountered while deleting inventory conflict.'' + @msgTag + '';Error='' +  cast(@error as nvarchar(50)) + ''>''
   RAISERROR(@msg,16,1)
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
   RAISERROR(@msg,16,1)
   RETURN -100
END

-- Commit and return
COMMIT TRANSACTION
RETURN 0
END
'
)

IF @@error != 0 GOTO ROLL_IT

-------------------------------------------------------------------------------
--
-- Procedure: inventoryConflict$resolveLocation
--
-------------------------------------------------------------------------------
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'inventoryConflict$resolveLocation')
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

-- Get the caller login from the spidLogin table
IF len(dbo.string$GetSpidLogin()) = 0 BEGIN
   SET @msg = ''Caller login not found in spid login table.'' + @msgTag + ''>''
   RAISERROR(@msg,16,1)
   RETURN -100
END

-- Begin transaction
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

-- Delete the conflict
DELETE InventoryConflict
WHERE  Id = @id
SELECT @error = @@error
IF @error != 0 BEGIN
   ROLLBACK TRANSACTION @tranName
   COMMIT TRANSACTION
   SET @msg = ''Error encountered while deleting inventory conflict.'' + @msgTag + '';Error='' +  cast(@error as nvarchar(50)) + ''>''
   RAISERROR(@msg,16,1)
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
   RAISERROR(@msg,16,1)
   RETURN -100
END

-- Commit and return
COMMIT TRANSACTION
RETURN 0
END
'
)

IF @@error != 0 GOTO ROLL_IT

-------------------------------------------------------------------------------
--
-- Procedure: inventoryConflict$resolveObjectType
--
-------------------------------------------------------------------------------
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'inventoryConflict$resolveObjectType')
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

-- Get the caller login from the spidLogin table
IF len(dbo.string$GetSpidLogin()) = 0 BEGIN
   SET @msg = ''Caller login not found in spid login table.'' + @msgTag + ''>''
   RAISERROR(@msg,16,1)
   RETURN -100
END

-- Begin transaction
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

-- Delete the conflict
DELETE InventoryConflict
WHERE  Id = @id
SELECT @error = @@error
IF @error != 0 BEGIN
   ROLLBACK TRANSACTION @tranName
   COMMIT TRANSACTION
   SET @msg = ''Error encountered while deleting inventory conflict.'' + @msgTag + '';Error='' +  cast(@error as nvarchar(50)) + ''>''
   RAISERROR(@msg,16,1)
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
   RAISERROR(@msg,16,1)
   RETURN -100
END

-- Commit and return
COMMIT TRANSACTION
RETURN 0
END
'
)

IF @@error != 0 GOTO ROLL_IT

-------------------------------------------------------------------------------
--
-- Procedure: inventoryConflict$resolveUnknownSerial
--
-------------------------------------------------------------------------------
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'inventoryConflict$resolveUnknownSerial')
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

-- Get the caller login from the spidLogin table
IF len(dbo.string$GetSpidLogin()) = 0 BEGIN
   SET @msg = ''Caller login not found in spid login table.'' + @msgTag + ''>''
   RAISERROR(@msg,16,1)
   RETURN -100
END

-- Begin transaction
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

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

IF @@error != 0 GOTO ROLL_IT

-------------------------------------------------------------------------------
--
-- Procedure: inventory$compare
--
-------------------------------------------------------------------------------
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'inventory$compare')
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
DECLARE @spidlogin nvarchar(256)
DECLARE @accountNo nvarchar(256)
DECLARE @rdate nvarchar(10)
DECLARE @tbl1 table (RowNo int identity(1,1), SerialNo nvarchar(256), Location bit)
DECLARE @tbl2 table (RowNo int identity(1,1), Id int, SerialNo nvarchar(64), Reason int)
DECLARE @tbl3 table (RowNo int identity(1,1), AccountNo nvarchar(256))

SET NOCOUNT ON

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=P''
SET @tranName = object_name(@@procid) + CAST(@@nestlevel as nvarchar(2))
SET @spidlogin = coalesce(dbo.string$getSpidLogin(),'''')

-- Make sure we have a login for the audit record to come later
IF len(@spidlogin) = 0 BEGIN
   SET @msg = ''No login specified for auditing purposes.'' + @msgTag + ''>''
   EXECUTE error$raise @msg, 0
   RETURN -100
END

-- Begin the transaction
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

-----------------------------------------------------------------------
-- Delete all the conflicts for the tapes associated with the accounts
-- that we will be comparing.  Set up a spidlogin do that the delete
-- trigger will journalize the deletions.  Afterward, delete the login.
--
-- We can do this because the comparison procedure compares all the
-- accounts for which we currently have inventories.
-----------------------------------------------------------------------
SET @i = 1
INSERT @tbl3 (AccountNo)
SELECT DISTINCT a.AccountName
FROM   Account a
JOIN   Inventory i
  ON   a.AccountId = i.AccountId

WHILE 1 = 1 BEGIN
   SELECT @accountNo = AccountNo
   FROM   @tbl3
   WHERE  RowNo = @i
   IF @@rowcount = 0 BREAK
   -- Insert journal record for deletions
   INSERT XInventoryConflict (Object, Action, Detail, Login)
   VALUES (@accountNo, 3, ''Deleting inventory conflicts for account '' + @accountNo + '' in anticipation of new comparison'', @spidlogin)
   -- Delete inventory conflicts
   DELETE  InventoryConflict
   WHERE   SerialNo IN (SELECT SerialNo FROM Medium m JOIN Inventory i ON m.AccountId = i.AccountId)
   SET @i = @i + 1
END

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

IF @@error != 0 GOTO ROLL_IT

-------------------------------------------------------------------------------
--
-- Procedure: sendListItem$getPage
--
-------------------------------------------------------------------------------
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'sendListItem$getPage')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.sendListItem$getPage
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
DECLARE @x3 nvarchar(1000)   -- Case name
DECLARE @x4 nvarchar(1000)   -- Return date
DECLARE @y1 nvarchar(1000)   -- Statuses
DECLARE @y2 nvarchar(1000)
DECLARE @y3 nvarchar(1000)
DECLARE @y4 nvarchar(1000)
DECLARE @y5 nvarchar(1000)
DECLARE @y6 nvarchar(1000)
DECLARE @y7 nvarchar(1000)
DECLARE @y8 nvarchar(1000)
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
SELECT @var = ''@x1$ nvarchar(1000), @x2$ nvarchar(1000), @x3$ nvarchar(1000), @x4$ nvarchar(1000), @y1$ nvarchar(1000), @y2$ nvarchar(1000), @y3$ nvarchar(1000), @y4$ nvarchar(1000), @y5$ nvarchar(1000), @y6$ nvarchar(1000), @y7$ nvarchar(1000), @y8$ nvarchar(1000)''
SELECT @p = -1, @p1 = -1, @i = 1

-- Set the order clause
IF @sort = 1 BEGIN
   SET @order1 = '' ORDER BY m.SerialNo asc''
   SET @order2 = '' ORDER BY SerialNo desc''
   SET @order3 = '' ORDER BY SerialNo asc''
END
ELSE IF @sort = 2 BEGIN
   SET @order1 = '' ORDER BY a.AccountName asc, m.SerialNo asc''
   SET @order2 = '' ORDER BY AccountName desc, SerialNo desc''
   SET @order3 = '' ORDER BY AccountName asc, SerialNo asc''
END
ELSE IF @sort = 3 BEGIN
   SET @order1 = '' ORDER BY ReturnDate asc, m.SerialNo asc''
   SET @order2 = '' ORDER BY ReturnDate desc, SerialNo desc''
   SET @order3 = '' ORDER BY ReturnDate asc, SerialNo asc''
END
ELSE IF @sort = 4 BEGIN
   SET @order1 = '' ORDER BY sli.Status asc, m.SerialNo asc''
   SET @order2 = '' ORDER BY Status desc, SerialNo desc''
   SET @order3 = '' ORDER BY Status asc, SerialNo asc''
END
ELSE IF @sort = 5 BEGIN
   SET @order1 = '' ORDER BY CaseName asc, m.SerialNo asc''
   SET @order2 = '' ORDER BY CaseName desc, SerialNo desc''
   SET @order3 = '' ORDER BY CaseName asc, SerialNo asc''
END
ELSE BEGIN
   SET @msg = ''Invalid sort order.'' + @msgTag + ''>''
   RAISERROR(@msg,16,1)
   RETURN -100
END

-- Construct the where clause
SET @where = '' WHERE (sl.ListId = '' + cast(@listId as nvarchar(50)) + '' OR sl.CompositeId = '' + cast(@listId as nvarchar(50)) + '')''
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
      SET @where = @where + '' AND (m.'' + left(@s, charindex(''='',@s) + 1) + '' @x1$)''
      SET @x1 = replace(ltrim(substring(@s, charindex(''='',@s) + 1, 4000)), '''''''', '''')
   END
   ELSE IF charindex(''AccountName ='', @s) = 1 BEGIN
      SET @where = @where + '' AND (a.'' + left(@s, charindex(''='',@s) + 1) + '' @x2$)''
      SET @x2 = replace(ltrim(substring(@s, charindex(''='',@s) + 1, 4000)), '''''''', '''')
   END
   ELSE IF charindex(''CaseName = '', @s) = 1 BEGIN
      SET @where = @where + '' AND ('' + replace(left(@s, charindex(''='',@s) + 1),''CaseName'',''coalesce(c.CaseName,'''''''')'') + '' @x3$)''
      SET @x3 = replace(ltrim(substring(@s, charindex(''='',@s) + 1, 4000)), '''''''', '''')
   END
   ELSE IF charindex(''ReturnDate ='', @s) = 1 BEGIN
      SET @where = @where + '' AND ('' + replace(left(@s, charindex(''='',@s) + 1),''ReturnDate'',''coalesce(c.ReturnDate,coalesce(convert(nvarchar(10),sli.ReturnDate,120),''''''''))'') + '' @x4$)''
      SET @x4 = replace(ltrim(substring(@s, charindex(''='',@s) + 1, 4000)), '''''''', '''')
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
         SET @where = @where + '' sli.Status = @y'' + cast(@i as nchar(1)) + ''$''
         -- Which variable gets assigned depends on the value of i
         IF @i = 1 SET @y1 = @s1
         ELSE IF @i = 2 SET @y2 = @s1
         ELSE IF @i = 3 SET @y3 = @s1
         ELSE IF @i = 4 SET @y4 = @s1
         ELSE IF @i = 5 SET @y5 = @s1
         ELSE IF @i = 6 SET @y6 = @s1
         ELSE IF @i = 7 SET @y7 = @s1
         ELSE IF @i = 8 SET @y8 = @s1
         -- Raise error if too many status values
         IF @i = 8 AND @p1 != 0 BEGIN
            SET @msg = ''A maximum of eight status values may be entered.'' + @msgTag + ''>''
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
      SET @msg = ''Error occurred while selecting page of shipping list items.  Invalid filter supplied.'' + @msgTag + ''>''
      EXECUTE error$raise @msg
      RETURN -100
   END
END

-- Construct the fields string
SET @fields2 = ''ItemId, SerialNo, AccountName, Status, ReturnDate, CaseName, Notes, RowVersion''
SET @fields1 = ''sli.ItemId, m.SerialNo, a.AccountName, sli.Status, coalesce(c.ReturnDate,coalesce(convert(nvarchar(10),sli.ReturnDate,120),'''''''')) as ''''ReturnDate'''', coalesce(c.CaseName,'''''''') as ''''CaseName'''', sli.Notes, sli.RowVersion''

-- Construct the tables string
SET @tables = ''SendListItem sli JOIN SendList sl ON sl.ListId = sli.ListId JOIN Medium m ON m.MediumId = sli.MediumId JOIN Account a ON a.AccountId = m.AccountId LEFT OUTER JOIN (SELECT slc.SerialNo as ''''CaseName'''', slic.ItemId as ''''ItemId'''', case slc.Sealed when 0 then null else coalesce(convert(nvarchar(10),slc.ReturnDate,120),'''''''') end as ''''ReturnDate'''' FROM SendListCase slc JOIN SendListItemCase slic ON slic.CaseId = slc.CaseId JOIN SendListItem sli ON sli.ItemId = slic.ItemId JOIN SendList sl ON sl.ListId = sli.ListId WHERE sl.ListId = '' + cast(@listId as nvarchar(50)) + '' OR sl.CompositeId = '' + cast(@listId as nvarchar(50)) + '') as c ON c.ItemId = sli.ItemId''

-- Select the total number of records that fit the criteria
CREATE TABLE #tblTemp (xyz int)
SET @sql = ''INSERT #tblTemp SELECT count(*) FROM '' + @tables + @where
EXECUTE sp_executesql @sql, @var, @x1$ = @x1, @x2$ = @x2, @x3$ = @x3, @x4$ = @x4, @y1$ = @y1, @y2$ = @y2, @y3$ = @y3, @y4$ = @y4, @y5$ = @y5, @y6$ = @y6, @y7$ = @y7, @y8$ = @y8
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
EXECUTE sp_executesql @sql, @var, @x1$ = @x1, @x2$ = @x2, @x3$ = @x3, @x4$ = @x4, @y1$ = @y1, @y2$ = @y2, @y3$ = @y3, @y4$ = @y4, @y5$ = @y5, @y6$ = @y6, @y7$ = @y7, @y8$ = @y8
SET @error = @@error
IF @error != 0 BEGIN
   SET @msg = ''Error occurred while selecting page of media.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
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

IF @@error != 0 GOTO ROLL_IT

-------------------------------------------------------------------------------
--
-- Procedure: receiveListItem$getPage
--
-------------------------------------------------------------------------------
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'receiveListItem$getPage')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.receiveListItem$getPage
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
DECLARE @x3 nvarchar(1000)   -- Case name
DECLARE @y1 nvarchar(1000)   -- Statuses
DECLARE @y2 nvarchar(1000)
DECLARE @y3 nvarchar(1000)
DECLARE @y4 nvarchar(1000)
DECLARE @y5 nvarchar(1000)
DECLARE @y6 nvarchar(1000)
DECLARE @y7 nvarchar(1000)
DECLARE @y8 nvarchar(1000)
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
SELECT @var = ''@x1$ nvarchar(1000), @x2$ nvarchar(1000), @x3$ nvarchar(1000), @y1$ nvarchar(1000), @y2$ nvarchar(1000), @y3$ nvarchar(1000), @y4$ nvarchar(1000), @y5$ nvarchar(1000), @y6$ nvarchar(1000), @y7$ nvarchar(1000), @y8$ nvarchar(1000)''
SELECT @p = -1, @p1 = -1, @i = 1

-- Set the order clause
IF @sort = 1 BEGIN
   SET @order1 = '' ORDER BY m.SerialNo asc''
   SET @order2 = '' ORDER BY SerialNo desc''
   SET @order3 = '' ORDER BY SerialNo asc''
END
ELSE IF @sort = 2 BEGIN
   SET @order1 = '' ORDER BY a.AccountName asc, m.SerialNo asc''
   SET @order2 = '' ORDER BY AccountName desc, SerialNo desc''
   SET @order3 = '' ORDER BY AccountName asc, SerialNo asc''
END
ELSE IF @sort = 3 BEGIN
   SET @order1 = '' ORDER BY rli.Status asc, m.SerialNo asc''
   SET @order2 = '' ORDER BY Status desc, SerialNo desc''
   SET @order3 = '' ORDER BY Status asc, SerialNo asc''
END
ELSE IF @sort = 4 BEGIN
   SET @order1 = '' ORDER BY CaseName asc, m.SerialNo asc''
   SET @order2 = '' ORDER BY CaseName desc, SerialNo desc''
   SET @order3 = '' ORDER BY CaseName asc, SerialNo asc''
END
ELSE BEGIN
   SET @msg = ''Invalid sort order.'' + @msgTag + ''>''
   RAISERROR(@msg,16,1)
   RETURN -100
END

-- Construct the where clause
SET @where = '' WHERE (rl.ListId = '' + cast(@listId as nvarchar(50)) + '' OR rl.CompositeId = '' + cast(@listId as nvarchar(50)) + '')''
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
      SET @where = @where + '' AND (m.'' + left(@s, charindex(''='',@s) + 1) + '' @x1$)''
      SET @x1 = replace(ltrim(substring(@s, charindex(''='',@s) + 1, 4000)), '''''''', '''')
   END
   ELSE IF charindex(''AccountName ='', @s) = 1 BEGIN
      SET @where = @where + '' AND (a.'' + left(@s, charindex(''='',@s) + 1) + '' @x2$)''
      SET @x2 = replace(ltrim(substring(@s, charindex(''='',@s) + 1, 4000)), '''''''', '''')
   END
   ELSE IF charindex(''CaseName = '', @s) = 1 BEGIN
      SET @where = @where + '' AND ('' + replace(left(@s, charindex(''='',@s) + 1),''CaseName'',''coalesce(sc.CaseName,'''''''')'') + '' @x3$)''
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
         SET @where = @where + '' rli.Status = @y'' + cast(@i as nchar(1)) + ''$''
         -- Which variable gets assigned depends on the value of i
         IF @i = 1 SET @y1 = @s1
         ELSE IF @i = 2 SET @y2 = @s1
         ELSE IF @i = 3 SET @y3 = @s1
         ELSE IF @i = 4 SET @y4 = @s1
         ELSE IF @i = 5 SET @y5 = @s1
         ELSE IF @i = 6 SET @y6 = @s1
         ELSE IF @i = 7 SET @y7 = @s1
         ELSE IF @i = 8 SET @y8 = @s1
         -- Raise error if too many status values
         IF @i = 8 AND @p1 != 0 BEGIN
            SET @msg = ''A maximum of eight status values may be entered.'' + @msgTag + ''>''
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
      SET @msg = ''Error occurred while selecting page of receiving list items.  Invalid filter supplied.'' + @msgTag + ''>''
      EXECUTE error$raise @msg
      RETURN -100
   END
END

-- Construct the fields string
SET @fields2 = ''ItemId, SerialNo, AccountName, Status, CaseName, Notes, RowVersion''
SET @fields1 = ''rli.ItemId, m.SerialNo, a.AccountName, rli.Status, coalesce(sc.CaseName,'''''''') as ''''CaseName'''', rli.Notes, rli.RowVersion''

-- Construct the tables string
SET @tables = ''ReceiveListItem rli JOIN ReceiveList rl ON rl.ListId = rli.ListId JOIN Medium m ON m.MediumId = rli.MediumId JOIN Account a ON a.AccountId = m.AccountId LEFT OUTER JOIN (SELECT sc.SerialNo as ''''CaseName'''', msc.MediumId as ''''MediumId'''' FROM SealedCase sc JOIN MediumSealedCase msc ON msc.CaseId = sc.CaseId JOIN ReceiveListItem rli ON rli.MediumId = msc.MediumId JOIN ReceiveList rl ON rl.ListId = rli.ListId WHERE rl.ListId = '' + cast(@listId as nvarchar(50)) + '' OR rl.CompositeId = '' + cast(@listId as nvarchar(50)) + '') AS sc ON sc.MediumId = m.MediumId''

-- Select the total number of records that fit the criteria
CREATE TABLE #tblTemp (xyz int)
SET @sql = ''INSERT #tblTemp SELECT count(*) FROM '' + @tables + @where
EXECUTE sp_executesql @sql, @var, @x1$ = @x1, @x2$ = @x2, @x3$ = @x3, @y1$ = @y1, @y2$ = @y2, @y3$ = @y3, @y4$ = @y4, @y5$ = @y5, @y6$ = @y6, @y7$ = @y7, @y8$ = @y8
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
EXECUTE sp_executesql @sql, @var, @x1$ = @x1, @x2$ = @x2, @x3$ = @x3, @y1$ = @y1, @y2$ = @y2, @y3$ = @y3, @y4$ = @y4, @y5$ = @y5, @y6$ = @y6, @y7$ = @y7, @y8$ = @y8
SET @error = @@error
IF @error != 0 BEGIN
   SET @msg = ''Error occurred while selecting page of media.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
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

IF @@error != 0 GOTO ROLL_IT

-------------------------------------------------------------------------------
--
-- Procedure: receiveListItem$ins
--
-------------------------------------------------------------------------------
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'receiveListItem$ins')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.receiveListItem$ins
(
   @serialNo nvarchar(32),               -- medium serial number
   @notes nvarchar(1000),                -- any notes to attach to the medium
   @batchLists nvarchar(4000) OUTPUT,    -- list names in the creation batch
   @nestLevel int = 1                    -- should never be supplied from the application
)
WITH ENCRYPTION
AS
BEGIN
DECLARE @msg as nvarchar(255)        -- used to preformat error message
DECLARE @msgTag as nvarchar(255)     -- used to hold first part of error message header
DECLARE @tranName as nvarchar(255)   -- used to hold name of savepoint
DECLARE @listName nchar(10)
DECLARE @rowCount as int
DECLARE @error as int
DECLARE @location as bit
DECLARE @mediumId as int
DECLARE @lastMedium as int
DECLARE @accountId as int
DECLARE @caseName as nvarchar(32)
DECLARE @listId as int
DECLARE @returnValue as int
DECLARE @caseId as int
DECLARE @itemId as int
DECLARE @priorId as int            -- id of list item if already on a list
DECLARE @priorStatus as int        -- status of list item if already on a list
DECLARE @priorVersion as rowversion   -- rowversion of list item already on list
DECLARE @newList as nchar(10)
DECLARE @status as int
DECLARE @level as int

SET NOCOUNT ON

-- Tweak parameters
SET @batchLists = ltrim(rtrim(coalesce(@batchLists,'''')))
SET @serialNo = ltrim(rtrim(coalesce(@serialNo,'''')))
SET @notes = ltrim(rtrim(coalesce(@notes,'''')))

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=P''
SET @tranName = object_name(@@procid) + CAST(@@nestlevel as nvarchar(2))

-- Begin transaction
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
   -- If in a case, verify that the case doesn''t lie on any list outside of
   -- this batch.  We don''t need to check the status of the case, because if
   -- it exists, we know that it is active.  (Sealed cases are deleted when
   -- their lists are cleared.)  If not in a case, verify that the medium
   -- does not actively reside on another list.  If it does, then we can
   -- remove it from the prior list only if it has not yet been transmitted.
   IF @caseId > 0 BEGIN
      SELECT @listName = rl.ListName
      FROM   MediumSealedCase msc
      JOIN   ReceiveListItem rli
        ON   rli.MediumId = msc.MediumId
      JOIN   ReceiveList rl
        ON   rl.ListId = rli.ListId
      WHERE  msc.CaseId = @caseId AND
             rli.Status NOT IN (1,512) AND
             charindex(rl.ListName,@batchLists) = 0
      IF @@rowcount != 0 BEGIN
         ROLLBACK TRANSACTION @tranName
         COMMIT TRANSACTION
         SELECT @caseName = SerialNo FROM SealedCase WHERE CaseId = @caseId
         IF EXISTS (SELECT 1 FROM ReceiveList WHERE ListName = @listName AND CompositeId IS NOT NULL) BEGIN
            SELECT @listName = ListName
            FROM   ReceiveList
            WHERE  ListId = (SELECT CompositeId FROM ReceiveList WHERE ListName = @listName)
         END
         SET @msg = ''Case '''''' + @caseName + '''''' cannot be placed on this list because it actively appears on list '' + @listName + ''.'' + @msgTag + ''>''
         RAISERROR(@msg,16,1)
         RETURN -100
      END
   END
   ELSE BEGIN   -- medium not in a case
      SELECT @priorId = rli.ItemId,
             @priorStatus = rli.Status,
             @priorVersion = rli.RowVersion,
             @listName = rl.ListName
      FROM   ReceiveListItem rli
      JOIN   ReceiveList rl
        ON   rl.ListId = rli.ListId
      WHERE  rli.Status NOT IN (1,512) AND
             rli.MediumId = @mediumId AND
             charindex(rl.ListName,@batchLists) = 0
      IF @@rowCount > 0 BEGIN
         IF @priorStatus >= 4 BEGIN
            ROLLBACK TRANSACTION @tranName
            COMMIT TRANSACTION
            IF EXISTS (SELECT 1 FROM ReceiveList WHERE ListName = @listName AND CompositeId IS NOT NULL) BEGIN
               SELECT @listName = ListName
               FROM   ReceiveList
               WHERE  ListId = (SELECT CompositeId FROM ReceiveList WHERE ListName = @listName)
            END
            SET @msg = ''Medium '''''' + @serialNo + '''''' currently resides on active receive list '' + @listName + ''.'' + @msgTag + ''>''
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

-- Check the account of the medium to see if we have already produced a list
-- for this account within this batch.  If we have, then add it to that list.
-- (If the item already appears on the list as removed, update its status to
-- to submitted.)
IF len(@batchLists) > 0 BEGIN
   SELECT @listId = ListId
   FROM   ReceiveList 
   WHERE  AccountId = @accountId AND 
          charindex(ListName,@batchLists) > 0
   IF @@rowCount > 0 BEGIN
      SELECT @itemId = ItemId,
             @status = Status
      FROM   ReceiveListItem
      WHERE  ListId = @listId AND 
             MediumId = @mediumId
      IF @@rowCount > 0 BEGIN
         IF @status != 1 BEGIN       -- Medium is already on a list within the batch
            COMMIT TRANSACTION
            RETURN 0
         END
         ELSE BEGIN
            UPDATE ReceiveListItem
            SET    Status = 2
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
   EXECUTE @returnValue = receiveList$create @accountId, @newList OUTPUT
   IF @returnValue != 0 BEGIN
      ROLLBACK TRANSACTION @tranName
      COMMIT TRANSACTION
      RETURN -100
   END
   ELSE BEGIN
      -- Get the list id 
      SELECT @listId = ListId
      FROM   ReceiveList
      WHERE  ListName = @newList
      -- Add the name of the new list to the batch
      SET @batchLists = @batchLists + @newList
   END
END

-- Add the item if it was not restored
IF @itemId IS NULL BEGIN
   INSERT ReceiveListItem
   (
      ListId, 
      MediumId,
      Notes
   )
   VALUES
   (
      @listId, 
      @mediumId,
      @notes
   )
   SET @error = @@error
   IF @error != 0 BEGIN
      ROLLBACK TRANSACTION @tranName
      COMMIT TRANSACTION
      SET @msg = ''Error encountered while inserting a receive list item.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
      EXECUTE error$raise @msg, @error
      RETURN -100
   END
END

-- If the medium is in a sealed case, then every other medium in the case must
-- be added as well.  We should only do this if the nest level is 1.  Otherwise
-- the recursion could potentially run quite deep.
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
         SELECT @serialNo = SerialNo
         FROM   Medium
         WHERE  MediumId = @lastMedium
         SELECT @level = @nestLevel + 1
         EXECUTE @returnValue = receiveListItem$ins @serialNo, '''', @batchLists OUTPUT, @level
         IF @returnValue != 0 BEGIN
            ROLLBACK TRANSACTION @tranName
            COMMIT TRANSACTION
            RETURN -100
         END
      END
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

-- Commit the transaction
COMMIT TRANSACTION
RETURN 0
END
'
)

IF @@error != 0 GOTO ROLL_IT

-------------------------------------------------------------------------------
--
-- Procedure: receiveListItem$add
--
-------------------------------------------------------------------------------
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'receiveListItem$add')
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
   MediumId,
   Notes
)
VALUES
(
   @listId, 
   @mediumId,
   @notes
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

IF @@error != 0 GOTO ROLL_IT

-------------------------------------------------------------------------------
--
-- Procedure: disasterCodeListItem$ins
--
-------------------------------------------------------------------------------
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'disasterCodeListItem$ins')
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

-- Get the medium
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

IF @@error != 0 GOTO ROLL_IT

-------------------------------------------------------------------------------
--
-- Trigger: disasterCodeListItem$afterInsert
--
-------------------------------------------------------------------------------
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

-- -- Make sure that the list is not a composite
-- IF EXISTS(SELECT 1 FROM DisasterCodeList WHERE AccountId IS NULL AND ListId = (SELECT ListId FROM Inserted)) BEGIN
--    SET @msg = ''Items may not be placed directly on a composite disaster code list.'' + @msgTag + ''>''
--    EXECUTE error$raise @msg, 0
--    RETURN
-- END
-- 
-- -- Make sure that the medium belongs to the same account as the list
-- SELECT @listName = dl.ListName,
--        @status  = dl.Status,
--        @serial1 = m.SerialNo,
--        @accountId = m.AccountId,
--        @mediumId = m.MediumId
-- FROM   DisasterCodeList dl
-- JOIN   DisasterCodeListItem dli
--   ON   dli.ListId = dl.ListId
-- JOIN   Medium m
--   ON   m.MediumId = dli.MediumId
-- WHERE  m.AccountId = dl.AccountId AND dli.ItemId = (SELECT ItemId FROM Inserted)
-- IF @@rowcount = 0 BEGIN
--    SET @msg = ''Medium must belong to same account as the list itself.'' + @msgTag + ''>''
--    EXECUTE error$raise @msg, 0
--    RETURN
-- END
-- ELSE IF @status >= 4 BEGIN
--    SET @msg = ''Items cannot be added to a list that has already been '' + dbo.string$statusName(4,@status) + ''.'' + @msgTag + ''>''
--    EXECUTE error$raise @msg, 0
--    RETURN
-- END

-- -- Make sure that the medium does not appear active more than once
-- IF EXISTS
--    (
--    SELECT 1
--    FROM   DisasterCodeListItem
--    WHERE  MediumId = (SELECT MediumId FROM Inserted) AND Status NOT IN (1,512) AND ListId != (SELECT ListId FROM Inserted)
--    )
-- BEGIN
--    SET @msg = ''Medium '' + @serial1 + '' may not appear on more than one active disaster recovery list.'' + @msgTag + ''>''
--    EXECUTE error$raise @msg, 0
--    RETURN
-- END

-- -- If the code was changed and the item is in a sealed case, make sure that no item in the sealed
-- -- case has a different disaster recovery code.
-- SELECT TOP 1 @serial2 = m.SerialNo
-- FROM   DisasterCodeListItem dli
-- JOIN   DisasterCodeList dl
--   ON   dl.ListId = dli.ListId
-- JOIN   MediumSealedCase c
--   ON   c.MediumId = dli.MediumId
-- JOIN   Medium m
--   ON   m.MediumId = c.MediumId
-- WHERE  dli.Status not in (1,512) AND
--        dli.Code != (SELECT Code FROM Inserted) AND
--        c.CaseId = (SELECT isnull(CaseId,-1) FROM MediumSealedCase WHERE MediumId = @mediumId)
-- IF @@rowcount != 0 BEGIN
--    SET @msg = ''Medium '' + @serial1 + '' and medium '' + @serial2 + '' may not be assigned different disaster recovery codes because they reside in the same sealed case.'' + @msgTag + ''>''
--    EXECUTE error$raise @msg, 0
--    RETURN
-- END

SELECT @serial1 = SerialNo
FROM   Medium
WHERE  MediumId = (SELECT MediumId FROM Inserted)

SELECT @listName = ListName
FROM   DisasterCodeList
WHERE  ListId = (SELECT ListId FROM Inserted)

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

IF @@error != 0 GOTO ROLL_IT

-------------------------------------------------------------------------------
--
-- Version update
--
-------------------------------------------------------------------------------
IF NOT EXISTS(SELECT 1 FROM DatabaseVersion WHERE Major = 1 AND Minor = 3 AND Revision = 6) BEGIN
   DECLARE @x nvarchar(1000)
   EXECUTE spidLogin$ins 'System', 'Insert database version'
   INSERT DatabaseVersion (Major, Minor, Revision) VALUES (1, 3, 6)
   EXECUTE spidLogin$del
END

GOTO COMMIT_IT

ROLL_IT:
ROLLBACK TRANSACTION
GOTO DONE

COMMIT_IT:
COMMIT TRANSACTION

DONE:
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
