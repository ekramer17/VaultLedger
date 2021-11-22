SET NOCOUNT ON

-- Should we run this script?
IF dbo.bit$doScript('1.3.9') = 1 BEGIN

DECLARE @CREATE nvarchar(10)

BEGIN TRANSACTION

IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'XExternalSiteLocation' AND COLUMN_NAME = 'Object' AND CHARACTER_MAXIMUM_LENGTH < 256)
   ALTER TABLE dbo.XExternalSiteLocation ALTER COLUMN Object nvarchar(256) NOT NULL

-------------------------------------------------------------------------------
--
-- Procedure: receiveListItem$verify
--
-------------------------------------------------------------------------------
IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'receiveListItem$verify')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.receiveListItem$verify
(
   @itemId int,
   @rowVersion rowversion
)
WITH ENCRYPTION
AS
BEGIN
DECLARE @msg as nvarchar(255)        -- used to preformat error message
DECLARE @msgTag as nvarchar(255)     -- used to hold first part of error message header
DECLARE @tranName as nvarchar(255)   -- used to hold name of savepoint
DECLARE @rowCount int
DECLARE @status1 int
DECLARE @status2 int
DECLARE @value int
DECLARE @error int
DECLARE @r binary(8)
DECLARE @id int

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=P''
SET @tranName = object_name(@@procid) + CAST(@@nestlevel as nvarchar(2))

-- Get the item and list status
SELECT @id = i.ListId, 
       @status1 = i.Status,
       @status2 = r.Status,
       @r = i.Rowversion
FROM   ReceiveListItem i
JOIN   ReceiveList r
  ON   i.ListId = r.ListId
WHERE  ItemId = @itemId
IF @@rowCount = 0 BEGIN
   SET @msg = ''Receive list item not found.'' + @msgTag + ''>''
   RAISERROR(@msg,16,1)
   RETURN -100
END

-- If the item belongs to a composite list, get the status of the composite
IF EXISTS 
   (
   SELECT 1 
   FROM   ReceiveList 
   WHERE  ListId = @id AND CompositeId IS NOT NULL
   ) 
BEGIN
   SELECT @id = ListId, 
          @status2 = Status
   FROM   ReceiveList
   WHERE  ListId = (SELECT CompositeId FROM ReceiveList WHERE ListId = @id)
END

-- Check list verification eligibility
IF dbo.bit$statusEligible(2, @status2, 16) = 1
   SET @value = 16
ELSE IF dbo.bit$statusEligible(2, @status2, 256) = 1
   SET @value = 256
ELSE IF @status2 = 16
   RETURN 0
ELSE IF @status2 = 256
   RETURN 0
ELSE IF @status2 = 512
   RETURN 0
ELSE BEGIN
   SET @msg = ''List is not currently verification-eligible.'' + @msgTag + ''>''
   RAISERROR(@msg,16,1)
   RETURN -100
END

-- If the status of the item matches the value for verification, just return
IF @status1 = @value 
   RETURN 0
ELSE IF @r != @rowversion BEGIN
   SET @msg = ''Receive list item has been modified since retrieval.'' + @msgTag + ''>''
   RAISERROR(@msg,16,1)
   RETURN -100
END

-- Begin transaction
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

-- If the medium in the item was marked as missing, mark it found
UPDATE Medium
SET    Missing = 0
WHERE  Missing = 1 AND MediumId = (SELECT MediumId FROM ReceiveListItem WHERE ItemId = @itemId)
SET @error = @@error
IF @error != 0 BEGIN
   ROLLBACK TRANSACTION @tranName
   COMMIT TRANSACTION
   SET @msg = ''Error encountered while removing ''''missing'''' status from medium.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
   EXECUTE error$raise @msg, @error
   RETURN -100
END

-- Stage 1 or stage 2?
UPDATE ReceiveListItem
SET    Status = @value
WHERE  ItemId = @itemId
SET @error = @@error
IF @error != 0 BEGIN
   ROLLBACK TRANSACTION @tranName
   COMMIT TRANSACTION
   SET @msg = ''Error encountered while verifying receive list item.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
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
-- Procedure: sendListItem$verify
--
-------------------------------------------------------------------------------
IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'sendListItem$verify')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.sendListItem$verify
(
   @itemId int,
   @rowVersion rowversion
)
WITH ENCRYPTION
AS
BEGIN
DECLARE @msg as nvarchar(255)        -- used to preformat error message
DECLARE @msgTag as nvarchar(255)     -- used to hold first part of error message header
DECLARE @tranName as nvarchar(255)   -- used to hold name of savepoint
DECLARE @rowCount int
DECLARE @status1 int
DECLARE @status2 int
DECLARE @value int
DECLARE @error int
DECLARE @r binary(8)
DECLARE @id int

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=P''
SET @tranName = object_name(@@procid) + CAST(@@nestlevel as nvarchar(2))

-- Get the item and list status
SELECT @id = i.ListId, 
       @status1 = i.Status,
       @status2 = s.Status,
       @r = i.Rowversion
FROM   SendListItem i
JOIN   SendList s
  ON   i.ListId = s.ListId
WHERE  ItemId = @itemId
IF @@rowcount = 0 BEGIN
   SET @msg = ''Shipping list item not found.'' + @msgTag + ''>''
   RAISERROR(@msg,16,1)
   RETURN -100
END

-- If the item belongs to a composite list, get the status of the composite
IF EXISTS 
   (
   SELECT 1 
   FROM   SendList 
   WHERE  ListId = @id AND CompositeId IS NOT NULL
   ) 
BEGIN
   SELECT @id = ListId, 
          @status2 = Status
   FROM   SendList
   WHERE  ListId = (SELECT CompositeId FROM SendList WHERE ListId = @id)
END

-- Check list verification eligibility
IF dbo.bit$statusEligible(1, @status2, 8) = 1
   SET @value = 8
ELSE IF dbo.bit$statusEligible(1, @status2, 256) = 1
   SET @value = 256
ELSE IF @status2 = 8
   RETURN 0
ELSE IF @status2 = 256
   RETURN 0
ELSE IF @status2 = 512
   RETURN 0
ELSE BEGIN
   SET @msg = ''List is not currently verification-eligible.'' + @msgTag + ''>''
   RAISERROR(@msg,16,1)
   RETURN -100
END

-- If the status of the item matches the value for verification, just return
IF @status1 = @value 
   RETURN 0
ELSE IF @r != @rowversion BEGIN
   SET @msg = ''Shipping list item has been modified since retrieval.'' + @msgTag + ''>''
   RAISERROR(@msg,16,1)
   RETURN -100
END

-- Begin transaction
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

UPDATE SendListItem
SET    Status = @value
WHERE  ItemId = @itemId
SET @error = @@error
IF @error != 0 BEGIN
   ROLLBACK TRANSACTION @tranName
   COMMIT TRANSACTION
   SET @msg = ''Error encountered while verifying send list item.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
   EXECUTE error$raise @msg, @error
   RETURN -100
END

-- If the medium in the item was marked as missing, mark it found
UPDATE Medium
SET    Missing = 0
WHERE  Missing = 1 AND
       MediumId = (SELECT MediumId FROM SendListItem WHERE ItemId = @itemId)
SET @error = @@error
IF @error != 0 BEGIN
   ROLLBACK TRANSACTION @tranName
   COMMIT TRANSACTION
   SET @msg = ''Error encountered while removing ''''missing'''' status from medium.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
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
-- Procedure: receiveList$clear
--
-------------------------------------------------------------------------------
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'receiveList$clear')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.receiveList$clear
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
DECLARE @returnValue int
DECLARE @tblMedium table (RowNo int identity(1,1), MediumId int)
DECLARE @rowNo int

SET NOCOUNT ON

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=P''
SET @tranName = object_name(@@procid) + CAST(@@nestlevel as nvarchar(2))

-- Get the list
SELECT @listName = ListName,
       @accountId = AccountId,
       @status = Status
FROM   ReceiveList
WHERE  ListId = @listId
IF @@rowCount = 0 BEGIN
   SET @msg = ''List not found.'' + @msgTag + ''>''
   RAISERROR(@msg,16,1)
   RETURN -100
END
ELSE IF NOT EXISTS
   (
   SELECT 1
   FROM   ReceiveList
   WHERE  ListId = @listId AND
          RowVersion = @rowVersion
   )
BEGIN
   SET @msg = ''Receive list has been modified since retrieval.'' + @msgTag + ''>''
   RAISERROR(@msg,16,1)
   RETURN -100
END

-- If the list has already been cleared, return.  Otherwise, make sure
-- it is eligible to be cleared.
IF @status = 512 BEGIN
   RETURN 0
END
ELSE IF dbo.bit$statusEligible(2,@status,512) = 0 BEGIN
   SET @msg = ''List '' + @listName + '' is not yet eligible to be processed.'' + @msgTag + ''>''
   RAISERROR(@msg,16,1)
   RETURN -100
END


-- Begin transaction
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

-- Insert audit trail so that medium$afterupdate trigger knows that we are clearing a list
EXECUTE spidlogin$ins '''', ''clear receive list''

-- If composite, clear all the discretes.  Otherwise clear the list.
IF @accountId IS NULL BEGIN
   SET @lastList = 0
   WHILE 1 = 1 BEGIN
      SELECT TOP 1 @lastList = ListId,
             @rowVersion = RowVersion
      FROM   ReceiveList
      WHERE  ListId > @lastList AND
             CompositeId = @listId
      ORDER BY ListId ASC
      IF @@rowCount = 0
         BREAK
      ELSE BEGIN
         EXECUTE @returnValue = receiveList$clear @lastList, @rowVersion
         IF @returnValue != 0 BEGIN
            ROLLBACK TRANSACTION @tranName
            COMMIT TRANSACTION
            RETURN -100
         END
      END
   END
END
ELSE BEGIN
   -- Set the status of all unremoved list items to cleared
   UPDATE ReceiveListItem
   SET    Status = 512
   WHERE  Status != 1 AND ListId = @listId
   SET @error = @@error
   IF @error != 0 BEGIN
      ROLLBACK TRANSACTION @tranName
      COMMIT TRANSACTION
      SET @msg = ''Error occurred while upgrading receive list item status to cleared.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
      EXECUTE error$raise @msg, @error
      RETURN -100
   END
   -- Update the medium locations
   INSERT @tblMedium (MediumId)
   SELECT MediumId
   FROM   ReceiveListItem
   WHERE  Status != 1 AND ListId = @listId
   ORDER BY MediumId Asc
   -- Run through the media   
   SET @rowNo = 1
   WHILE 1 = 1 BEGIN
      SELECT @mediumId = MediumId
      FROM   @tblMedium
      WHERE  RowNo = @rowNo
      IF @@rowCount = 0 BEGIN
         BREAK
      END
      ELSE BEGIN
         -- Delete the medium sealed case entries
         DELETE MediumSealedCase
         WHERE  MediumId = @MediumId
         SET @error = @@error
         IF @error != 0 BEGIN
            ROLLBACK TRANSACTION @tranName
            COMMIT TRANSACTION
            SET @msg = ''Error encountered while removing media from sealed cases.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
            EXECUTE error$raise @msg, @error
            RETURN -100
         END
         -- Update all the media on the list as moved to the enterprise
         UPDATE Medium
         SET    Location = 1,
                HotStatus = 0,
                ReturnDate = NULL,
                LastMoveDate = cast(convert(nchar(19),getutcdate(),120) as datetime)
         WHERE  MediumId = @MediumId AND Missing = 0
         SET @error = @@error
         IF @error != 0 BEGIN
            ROLLBACK TRANSACTION @tranName
            COMMIT TRANSACTION
            SET @msg = ''Error encountered while returning media from vault.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
            EXECUTE error$raise @msg, @error
            RETURN -100
         END
      END
      -- Increment row number
      SET @rowNo = @rowNo + 1
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
-- Procedure: sendList$clear
--
-------------------------------------------------------------------------------
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'sendList$clear')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.sendList$clear
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
DECLARE @caseName nvarchar(32)
DECLARE @listName nchar(10)
DECLARE @lastMedium int
DECLARE @accountId int
DECLARE @lastList int
DECLARE @lastCase int
DECLARE @caseId int
DECLARE @status int
DECLARE @error int
DECLARE @returnValue int
DECLARE @returnDate datetime
DECLARE @notes nvarchar(1000)
DECLARE @lastSerial nvarchar(32)
DECLARE @mediumId int
DECLARE @typeId int

SET NOCOUNT ON

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=P''
SET @tranName = object_name(@@procid) + CAST(@@nestlevel as nvarchar(2))

-- If the list has submitted or verified status, raise error.  If the list 
-- has cleared status, return.  Also check concurrency.
SELECT @listName = ListName,
       @accountId = AccountId,
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
   SET @msg = ''Send list has been modified since retrieval.'' + @msgTag + ''>''
   RAISERROR(@msg,16,1)
   RETURN -100
END
ELSE BEGIN
   IF @status = 512 BEGIN
      RETURN 0
   END
   ELSE IF dbo.bit$statusEligible(1,@status,512) = 0 BEGIN
      SET @msg = ''Shipping list has not yet reached processing-eligible status.'' + @msgTag + ''>''
      RAISERROR(@msg,16,1)
      RETURN -100
   END
END

-- Begin transaction
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

-- Insert audit trail so that medium$afterupdate trigger knows that we are clearing a list
EXECUTE spidlogin$ins '''', ''clear send list''

-- If composite, clear all the discretes.  Otherwise clear the list.
IF @accountId IS NULL BEGIN
   SET @lastList = 0
   WHILE 1 = 1 BEGIN
      SELECT TOP 1 @lastList = ListId,
             @rowVersion = RowVersion
      FROM   SendList
      WHERE  ListId > @lastList AND
             CompositeId = @listId
      ORDER BY ListId ASC
      IF @@rowCount = 0
         BREAK
      ELSE BEGIN
         EXECUTE @returnValue = sendList$clear @lastList, @rowVersion
         IF @returnValue != 0 BEGIN
            ROLLBACK TRANSACTION @tranName
            COMMIT TRANSACTION
            RETURN -100
         END
      END
   END
   -- Clear all the send list cases
   SET @lastCase = 0
   WHILE 1 = 1 BEGIN
      SELECT DISTINCT TOP 1 @lastCase = slic.CaseId
      FROM   SendListItemCase slic
      JOIN   SendListItem sli
        ON   sli.ItemId = slic.ItemId
      JOIN   SendList sl
        ON   sl.ListId = sli.ListId
      WHERE  sl.CompositeId = @listId AND 
             slic.CaseId > @lastCase
      ORDER BY slic.CaseId Asc
      IF @@rowCount = 0 BEGIN
         BREAK
      END
      ELSE BEGIN
         UPDATE SendListCase
         SET    Cleared = 1
         WHERE  CaseId = @lastCase
         SET @error = @@error
         IF @error != 0 BEGIN
            ROLLBACK TRANSACTION @tranName
            COMMIT TRANSACTION
            SET @msg = ''Error encountered while clearing send list cases.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
            EXECUTE error$raise @msg, @error
            RETURN -100
         END
      END
   END
END
ELSE BEGIN
   -- Set the status of all unremoved list items to cleared
   UPDATE SendListItem
   SET    Status = 512
   WHERE  Status != 1 AND
          ListId = @listId
   SET @error = @@error
   IF @error != 0 BEGIN
      ROLLBACK TRANSACTION @tranName
      COMMIT TRANSACTION
      SET @msg = ''Error occurred while upgrading send list item status to cleared.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
      EXECUTE error$raise @msg, @error
      RETURN -100
   END
   -- Set the medium locations
   SET @lastSerial = ''''
   WHILE 1 = 1 BEGIN
      SELECT TOP 1 @mediumId = m.MediumId,
             @lastSerial = m.SerialNo,
             @returnDate = sli.ReturnDate
      FROM   Medium m
      JOIN   SendListItem sli
        ON   sli.MediumId = m.MediumId
      WHERE  m.Missing = 0 AND
             sli.Status != 1 AND
             sli.ListId = @listId AND
             m.SerialNo > @lastSerial
      ORDER BY m.SerialNo asc
      IF @@rowCount = 0
         BREAK
      ELSE BEGIN
         UPDATE Medium
         SET    Location = 0,
                ReturnDate = @returnDate,
                LastMoveDate = cast(convert(nchar(19),getutcdate(),120) as datetime)
         WHERE  MediumId = @mediumId AND Missing = 0
         SET @error = @@error
         IF @error != 0 BEGIN
            ROLLBACK TRANSACTION @tranName
            COMMIT TRANSACTION
            SET @msg = ''Error encountered while moving media to vault.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
            EXECUTE error$raise @msg, @error
            RETURN -100
         END
      END
   END
   -- For each case in the list marked as sealed, create it if it
   -- doesn''t already exist.  (It may already exist if it also appears
   -- on another discrete within the same composite.)
   SET @lastCase = 0
   WHILE 1 = 1 BEGIN
      SELECT TOP 1 @lastCase = slc.CaseId,
             @typeId = slc.TypeId,
             @caseName = slc.SerialNo,
             @returnDate = slc.ReturnDate,
             @notes = slc.Notes
      FROM   SendListCase slc
      JOIN   SendListItemCase slic
        ON   slic.CaseId = slc.CaseId
      JOIN   SendListItem sli
        ON   sli.ItemId = slic.ItemId
      LEFT OUTER JOIN SealedCase sc
        ON   sc.SerialNo = slc.SerialNo
      WHERE  slc.Sealed = 1 AND
             sc.SerialNo IS NULL AND
             sli.ListId = @listId AND
             slc.CaseId > @lastCase
      ORDER BY slc.CaseId ASC
      IF @@rowCount = 0 
         BREAK
      ELSE BEGIN
         EXECUTE @returnValue = sealedCase$ins @caseName, @typeId, @returnDate, @notes, @caseId OUT
         IF @returnValue != 0 BEGIN
            ROLLBACK TRANSACTION @tranName
            COMMIT TRANSACTION
            RETURN -100
         END
      END
   END
   -- Add a record for each medium inside a sealed case
   SET @lastMedium = 0
   WHILE 1 = 1 BEGIN
      SELECT TOP 1 @caseName = slc.SerialNo,
             @lastMedium = sli.MediumId
      FROM   SendListItem sli
      JOIN   SendListItemCase slic
        ON   slic.ItemId = sli.ItemId
      JOIN   SendListCase slc
        ON   slc.CaseId = slic.CaseId
      WHERE  slc.Sealed = 1 AND
             sli.ListId = @listId AND
             sli.MediumId > @lastMedium
      ORDER BY sli.MediumId ASC
      IF @@rowCount = 0 
         BREAK
      ELSE BEGIN
         SELECT @caseId = CaseId
         FROM   SealedCase
         WHERE  SerialNo = @caseName
         IF @@rowCount = 0 BEGIN
            ROLLBACK TRANSACTION @tranName
            COMMIT TRANSACTION
            SET @msg = ''Sealed case '''''' + @caseName + '''''' not found.'' + @msgTag + ''>''
            RAISERROR(@msg,16,1)
            RETURN -100
         END
         ELSE BEGIN
            EXECUTE @returnValue = mediumSealedCase$ins @caseId, @lastMedium
            IF @returnValue != 0 BEGIN
               ROLLBACK TRANSACTION @tranName
               COMMIT TRANSACTION
               RETURN -100
            END
         END
      END
   END
   -- Clear all cases if the list does not belong to a composite
   SET @lastCase = 0
   WHILE 1 = 1 BEGIN
      SELECT DISTINCT TOP 1 @lastCase = slic.CaseId
      FROM   SendListItemCase slic
      JOIN   SendListItem sli
        ON   sli.ItemId = slic.ItemId
      WHERE  sli.ListId = @listId AND 
             slic.CaseId > @lastCase
      ORDER BY slic.CaseId Asc
      IF @@rowCount = 0 BEGIN
         BREAK
      END
      ELSE BEGIN
         UPDATE SendListCase
         SET    Cleared = 1
         WHERE  CaseId = @lastCase
         SET @error = @@error
         IF @error != 0 BEGIN
            ROLLBACK TRANSACTION @tranName
            COMMIT TRANSACTION
            SET @msg = ''Error encountered while clearing send list cases.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
            EXECUTE error$raise @msg, @error
            RETURN -100
         END
      END
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
-- Procedure: disasterCodeList$clear
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

-- Insert audit trail so that medium$afterupdate trigger knows that we are clearing a list
EXECUTE spidlogin$ins '''', ''clear disaster code list''

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
-- Function: string$getSpidInfo
--
-------------------------------------------------------------------------------
IF NOT EXISTS(SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE SPECIFIC_NAME = 'string$getSpidInfo')
   SET @CREATE = 'CREATE '
ELSE
   SET @CREATE = 'ALTER '

EXECUTE
(  
   @CREATE + ' FUNCTION dbo.string$getSpidInfo()
   RETURNS nvarchar(4000)
   WITH ENCRYPTION
   AS
   BEGIN
   DECLARE @x nvarchar(4000)
   DECLARE @y nvarchar(4000)
   DECLARE @i int
   -- Initialize
   SET @x = ''''
   SET @i = 0
   -- Create string
   WHILE 1 = 1 BEGIN
      SELECT TOP 1 @i = SeqNo,
             @y = isnull(TagInfo,'''')
      FROM   SpidLogin
      WHERE  Spid = @@spid AND SeqNo > @i
      ORDER  BY SeqNo ASC
      -- If no more rows then break
      IF @@rowcount = 0 BREAK
      -- Create string
      IF @x = ''''
         SET @x = @y
      ELSE
         SET @x = @x + '';'' + @y
   END
   -- Return
   RETURN @x
   END
   '
)

IF @@error != 0 GOTO ROLL_IT
-------------------------------------------------------------------------------
--
-- Trigger : account$afterUpdate
--
-------------------------------------------------------------------------------
IF EXISTS(SELECT * FROM sysobjects WHERE name = 'account$afterUpdate' AND objectproperty(id, 'ExecIsUpdateTrigger' ) = 1) 
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'TRIGGER account$afterUpdate
ON     Account
WITH ENCRYPTION
AFTER  UPDATE
AS
BEGIN
DECLARE @msg nvarchar(255)         -- used to preformat error message
DECLARE @msgTag nvarchar(255)      -- used to hold first part of error message header
DECLARE @msgUpdate nvarchar(3000)  -- used to hold the updated fields
DECLARE @tranName nvarchar(255)    -- used to hold name of savepoint
DECLARE @account nvarchar(32)      -- holds the name of the updated account
DECLARE @rowCount int              -- holds the number of rows in the Deleted table
DECLARE @ins nvarchar(4000)
DECLARE @del nvarchar(4000)
DECLARE @login nvarchar(32)
DECLARE @error int
DECLARE @id int
DECLARE @detail int
DECLARE @tblM table (RowNo int identity (1,1), Message nvarchar(1000), Detail int default 2)
DECLARE @i int

SET @rowCount = @@rowcount
IF @rowCount = 0 RETURN

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=T''
SET @tranName = object_name(@@procid) + CAST(trigger_nestlevel(@@procid) as nvarchar(2))

-- Begin transaction
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

-- Make sure we do not have a batch update
IF @rowCount > 1 BEGIN
   SET @msg = ''Batch update on account table not allowed.'' + @msgTag + ''>''
   EXECUTE error$raise @msg, 0, @tranName
   RETURN
END

-- Get the caller login from the spidLogin table
SELECT @login = Login
FROM   SpidLogin
WHERE  Spid = @@spid
IF len(@login) = 0 OR @login IS NULL BEGIN
   SET @msg = ''No login found for auditing purposes.'' + @msgTag + ''>''
   EXECUTE error$raise @msg, 0, @tranName
   RETURN
END

-- Checks for bar codes and lists are done in account$del, so no need to do them here

-- Add altered fields to audit message.  Certain fields may only be altered by the system.  Account name change should be last.
IF EXISTS (SELECT 1 FROM Inserted i JOIN Deleted d on d.AccountId = i.AccountId WHERE d.Global != i.Global) BEGIN
   INSERT @tblM (Message) SELECT case Global when 1 then ''Account granted global status'' else ''Global status revoked'' end FROM Inserted
END
IF EXISTS (SELECT 1 FROM Inserted i JOIN Deleted d on d.AccountId = i.AccountId WHERE d.Address1 != i.Address1) BEGIN
   INSERT @tblM (Message) SELECT ''Address (line 1) changed to '' + (SELECT Address1 FROM Inserted) 
END
IF EXISTS (SELECT 1 FROM Inserted i JOIN Deleted d on d.AccountId = i.AccountId WHERE d.Address2 != i.Address2) BEGIN
   INSERT @tblM (Message) SELECT case Len(Address2) when 0 then ''Address (line 2) removed'' else ''Address (line 2) changed to '' + Address2 end FROM Inserted
END
IF EXISTS (SELECT 1 FROM Inserted i JOIN Deleted d on d.AccountId = i.AccountId WHERE d.City != i.City) BEGIN
   INSERT @tblM (Message) SELECT case Len(City) when 0 then ''City removed'' else ''City changed to '' + City end FROM Inserted
END
IF EXISTS (SELECT 1 FROM Inserted i JOIN Deleted d on d.AccountId = i.AccountId WHERE d.State != i.State) BEGIN
   INSERT @tblM (Message) SELECT case Len(State) when 0 then ''State removed'' else ''State changed to '' + State end FROM Inserted
END
IF EXISTS (SELECT 1 FROM Inserted i JOIN Deleted d on d.AccountId = i.AccountId WHERE d.ZipCode != i.ZipCode) BEGIN
   INSERT @tblM (Message) SELECT case Len(ZipCode) when 0 then ''Zip code removed'' else ''Zip code changed to '' + ZipCode end FROM Inserted
END
IF EXISTS (SELECT 1 FROM Inserted i JOIN Deleted d on d.AccountId = i.AccountId WHERE d.Country != i.Country) BEGIN
   INSERT @tblM (Message) SELECT case Len(Country) when 0 then ''Country removed'' else ''Country changed to '' + Country end FROM Inserted
END
IF EXISTS (SELECT 1 FROM Inserted i JOIN Deleted d on d.AccountId = i.AccountId WHERE d.Contact != i.Contact) BEGIN
   INSERT @tblM (Message) SELECT case Len(Contact) when 0 then ''Contact removed'' else ''Contact changed to '' + Contact end FROM Inserted
END
IF EXISTS (SELECT 1 FROM Inserted i JOIN Deleted d on d.AccountId = i.AccountId WHERE d.PhoneNo != i.PhoneNo) BEGIN
   INSERT @tblM (Message) SELECT case Len(PhoneNo) when 0 then ''Phone number removed'' else ''Phone number changed to '' + PhoneNo end FROM Inserted
END
IF EXISTS (SELECT 1 FROM Inserted i JOIN Deleted d on d.AccountId = i.AccountId WHERE d.Email != i.Email) BEGIN
   INSERT @tblM (Message) SELECT case Len(Email) when 0 then ''Email address removed'' else ''Email address changed to '' + Email end FROM Inserted
END
IF EXISTS (SELECT 1 FROM Inserted i JOIN Deleted d on d.AccountId = i.AccountId WHERE d.Deleted != i.Deleted) BEGIN
   INSERT @tblM (Message, Detail) SELECT case Deleted when 0 then ''Account deleted'' else ''Account restored'' end, 3 FROM Inserted
   IF EXISTS (SELECT 1 FROM Inserted WHERE Deleted = 1) DELETE Inventory WHERE AccountId = (SELECT AccountId FROM Inserted)   
END
IF EXISTS (SELECT 1 FROM Inserted i JOIN Deleted d on d.AccountId = i.AccountId WHERE d.AccountName != i.AccountName) BEGIN
   INSERT @tblM (Message) SELECT ''Account name changed to '''''' + (SELECT AccountName FROM Inserted) + ''''''''
END

-- Select the account name from the Deleted table
SELECT @i = min(RowNo) FROM @tblM
SELECT @account = accountName FROM Deleted

-- Insert audit records
WHILE 1 = 1 BEGIN
   SELECT @msgUpdate = Message, @detail = Detail
   FROM   @tblM
   WHERE  RowNo = @i
   IF @@rowcount = 0 
      BREAK
   ELSE BEGIN
      INSERT XAccount (Object, Action, Detail, Login)
      VALUES(@account, @detail, @msgUpdate, dbo.string$GetSpidLogin())
      SET @error = @@error
      IF @error != 0 BEGIN
         SET @msg = ''Error encountered while inserting an account audit record.'' + @msgTag + '';Error='' + cast(@error as nvarchar(10)) + ''>''
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

IF @@error != 0 GOTO ROLL_IT
-------------------------------------------------------------------------------
--
-- Procedure : inventory$compare
--
-------------------------------------------------------------------------------
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
   SELECT distinct ii.SerialNo, i.Location
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
-- Procedure : sendlistscan$compare
--
-------------------------------------------------------------------------------
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'sendlistscan$compare')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.sendlistscan$compare
(
   @listName nchar(10)
)
WITH ENCRYPTION
AS
BEGIN
DECLARE @msg as nvarchar(255)        -- used to preformat error message
DECLARE @msgTag as nvarchar(255)     -- used to hold first part of error message header
DECLARE @tranName as nvarchar(255)   -- used to hold name of savepoint
DECLARE @rowVersion as rowversion
DECLARE @returnValue as int
DECLARE @rowcount as int
DECLARE @itemId as int
DECLARE @listId int
DECLARE @status int
DECLARE @error int
DECLARE @rowNo int
DECLARE @stage int
DECLARE @tblVerify table (RowNo int PRIMARY KEY CLUSTERED IDENTITY(1,1), ItemId int, RowVersion binary(8))
DECLARE @tbl1 table (ItemId int, SerialNo nvarchar(32))

SET NOCOUNT ON

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=P''
SET @tranName = object_name(@@procid) + CAST(@@nestlevel as nvarchar(2))

-- Verify that the list exists.  Also, the list must be 
SELECT @listId = ListId,
       @status = Status
FROM   SendList
WHERE  ListName = @listName
IF @@rowCount = 0 BEGIN
   SET @msg = ''Send list not found.'' + @msgTag + ''>''
   RAISERROR(@msg,16,1)
   RETURN -100
END

-- Eligible?
IF dbo.bit$statusEligible(1,@status,256) = 1
   SET @stage = 2
ELSE IF @status <= 8
   SET @stage = 1
ELSE BEGIN
   SET @msg = ''List is not currently verification-eligible.'' + @msgTag + ''>''
   RAISERROR(@msg,16,1)
   RETURN -100
END

-- What we obtain here depends on the stage.  In stage 1, all tapes must be verified
-- and case discrepancies checked.  In stage 2, tapes can be verified by the 
-- mention of the (sealed) case they''re in, and case discrepancies are not checked.
IF @stage = 1 BEGIN
   --
   -- Result 1: Media in list but not in scans
   --
   INSERT @tbl1 (ItemId, SerialNo)
   SELECT sli.ItemId, m.SerialNo
   FROM   Medium m
   JOIN   SendListItem sli
     ON   sli.MediumId = m.MediumId
   JOIN   SendList sl
     ON   sl.ListId = sli.ListId
   LEFT OUTER JOIN 
         (SELECT slsi.SerialNo
          FROM   SendListScanItem slsi
          JOIN   SendListScan sls
            ON   slsi.ScanId = sls.ScanId
          JOIN   SendList sl
            ON   sl.ListId = sls.ListId
          WHERE  sls.Stage = @stage AND 
                (sl.ListId = @listId OR coalesce(sl.CompositeId,0) = @listId)) as x
     ON   x.SerialNo = m.SerialNo   
   WHERE  sli.Status = 2 AND 
          x.SerialNo IS NULL AND
         (sl.ListId = @listId OR coalesce(sl.CompositeId,0) = @listId)
   ORDER BY m.SerialNo ASC
   --
   -- Select serial numbers from table to obtain result set
   --
   SELECT SerialNo 
   FROM   @tbl1
   ORDER  BY SerialNo ASC
   --
   -- Result 2: Media in the scans but not on the list (does not need to go in table)
   --
   SELECT distinct slsi.SerialNo
   FROM   SendListScanItem slsi
   JOIN   SendListScan sls
     ON   sls.ScanId = slsi.ScanId
   JOIN   SendList sl
     ON   sl.ListId = sls.ListId
   LEFT OUTER JOIN
         (SELECT m.SerialNo
          FROM   Medium m
          JOIN   SendListItem sli
            ON   sli.MediumId = m.MediumId
          JOIN   SendList sl
            ON   sl.ListId = sli.ListId
          WHERE  sli.Status != 1 AND
                (sl.ListId = @listId OR coalesce(sl.CompositeId,0) = @listId)
          UNION
          SELECT slc.SerialNo
          FROM   SendListCase slc
          JOIN   SendListItemCase slic
            ON   slic.CaseId = slc.CaseId
          JOIN   SendListItem sli
            ON   sli.ItemId = slic.ItemId
          JOIN   SendList sl
            ON   sl.ListId = sli.ListId
          WHERE  sli.Status != 1 AND
                (sl.ListId = @listId OR coalesce(sl.CompositeId,0) = @listId)) as x
     ON   x.SerialNo = slsi.SerialNo
   WHERE  sls.Stage = @stage AND 
          x.SerialNo IS NULL AND
         (sl.ListId = @listId OR coalesce(sl.CompositeId,0) = @listId)
   ORDER BY slsi.SerialNo
   --
   -- Result 3: Tapes in both scan and list that disagree on case
   --
   SELECT sli.ItemId, 
          m.SerialNo,
          lc.CaseName as ''ListCase'',
          single.CaseName as ''ScanCase''
   FROM   Medium m
   JOIN   SendListItem sli
     ON   sli.MediumId = m.MediumId
   JOIN   SendList sl
     ON   sl.ListId = sli.ListId
   JOIN  (SELECT sli.ItemId, isnull(slc.SerialNo,'''') as ''CaseName''
          FROM   SendListItem sli
          LEFT JOIN SendListItemCase slic
            ON   slic.ItemId = sli.ItemId
          LEFT JOIN SendListCase slc
            ON   slc.CaseId = slic.CaseId) as lc   -- list cases
     ON   lc.ItemId = sli.ItemId
   LEFT OUTER JOIN   -- Serial numbers that have at least one entry with the same case in the list and scan
         (SELECT slsi.SerialNo
          FROM   SendListScanItem slsi
          JOIN   SendListScan sls
            ON   sls.ScanId = slsi.ScanId
          JOIN   Medium m
            ON   m.SerialNo = slsi.SerialNo
          JOIN   SendListItem sli
            ON   sli.MediumId = m.MediumId
          JOIN   SendList sl
            ON   sl.ListId = sli.ListId
          LEFT OUTER JOIN
                (SELECT slc.SerialNo as ''CaseName'',
                        slic.ItemId
                 FROM   SendListCase slc
                 JOIN   SendListItemCase slic
                   ON   slic.CaseId = slc.CaseId) as lc1
            ON   lc1.ItemId = sli.ItemId
          WHERE  sls.Stage = @stage AND
                 sl.ListId = sls.ListId AND
                 coalesce(lc1.CaseName,'''') = slsi.CaseName AND
                (sl.ListId = @listId OR coalesce(sl.CompositeId,0) = @listId)) as same
     ON   same.SerialNo = m.SerialNo
   JOIN  (SELECT   slsi.SerialNo,        -- Makes sure we only get one scan case per serial number
                   min(slsi.CaseName) as ''CaseName''
          FROM     SendListScanItem slsi
          JOIN     SendListScan sls
            ON     sls.ScanId = slsi.ScanId
          JOIN     SendList sl
            ON     sl.ListId = sls.ListId
          WHERE    sls.Stage = @stage AND (sl.ListId = @listId OR coalesce(sl.CompositeId,0) = @listId) 
          GROUP BY slsi.SerialNo) as single
     ON   single.SerialNo = m.SerialNo
   WHERE  sli.Status in (2,8) AND
          lc.CaseName != single.CaseName AND
         (sl.ListId = @listId OR coalesce(sl.CompositeId,0) = @listId)
END
ELSE BEGIN
   --
   -- Result 1: Tapes on list but not in scan plus tapes on list in sealed cases not mentioned in scan
   --
   INSERT @tbl1 (ItemId, SerialNo)
   SELECT sli.ItemId, m.SerialNo
   FROM   Medium m
   JOIN   SendListItem sli
     ON   sli.MediumId = m.MediumId
   JOIN   SendList sl
     ON   sl.ListId = sli.ListId
   LEFT OUTER JOIN 
         (SELECT slsi.SerialNo
          FROM   SendListScanItem slsi
          JOIN   SendListScan sls
            ON   slsi.ScanId = sls.ScanId
          JOIN   SendList sl
            ON   sl.ListId = sls.ListId
          WHERE  sls.Stage = @stage AND 
                (sl.ListId = @listId OR coalesce(sl.CompositeId,0) = @listId)
          UNION
          SELECT m.SerialNo
          FROM   Medium m
          JOIN   SendListItem sli
            ON   sli.MediumId = m.MediumId
          JOIN   SendListItemCase slic
            ON   slic.ItemId = sli.ItemId
          JOIN   SendListCase slc
            ON   slc.CaseId = slic.CaseId
          JOIN   SendList sl
            ON   sl.ListId = sli.ListId
          JOIN   SendListScan sls
            ON   sls.ScanId = sl.ListId
          JOIN   SendListScanItem slsi
            ON   slsi.ScanId = sls.ScanId
          WHERE  slsi.CaseName = slc.SerialNo AND 
                 slc.Sealed = 1 AND
                 sls.Stage = @stage AND 
                (sl.ListId = @listId OR coalesce(sl.CompositeId,0) = @listId)) as x
     ON   x.SerialNo = m.SerialNo   
   WHERE  x.SerialNo IS NULL AND 
          sli.Status NOT IN (1,256,512) AND 
         (sl.ListId = @listId OR coalesce(sl.CompositeId,0) = @listId)
   ORDER BY m.SerialNo ASC
   --
   -- Select the result set
   --
   SELECT SerialNo
   FROM   @tbl1
   ORDER  BY SerialNo ASC
   --
   -- Result 2: Media in the scans but not on the list (a) straight media, (b) cases
   --
   SELECT distinct slsi.SerialNo
   FROM   SendListScanItem slsi
   JOIN   SendListScan sls
     ON   sls.ScanId = slsi.ScanId
   JOIN   SendList sl
     ON   sl.ListId = sls.ListId
   LEFT OUTER JOIN
         (SELECT m.SerialNo
          FROM   Medium m
          JOIN   SendListItem sli
            ON   sli.MediumId = m.MediumId
          JOIN   SendList sl
            ON   sl.ListId = sli.ListId
          JOIN   SendListScan sls
            ON   sls.ListId = sl.ListId
          JOIN   SendListScanItem slsi
            ON   slsi.ScanId = sls.ScanId
          WHERE  m.SerialNo = slsi.SerialNo AND
                 sls.Stage = @stage AND
                 sli.Status != 1 AND
                (sl.ListId = @listId OR coalesce(sl.CompositeId,0) = @listId)
          UNION
          SELECT slc.SerialNo
          FROM   SendListCase slc
          JOIN   SendListItemCase slic
            ON   slic.CaseId = slc.CaseId
          JOIN   SendListItem sli
            ON   sli.ItemId = slic.ItemId
          JOIN   SendList sl
            ON   sl.ListId = sli.ListId
          JOIN   SendListScan sls
            ON   sls.ListId = sl.ListId
          JOIN   SendListScanItem slsi
            ON   slsi.ScanId = sls.ScanId
          WHERE  slc.SerialNo = slsi.SerialNo AND
                 sls.Stage = @stage AND
                 sli.Status != 1 AND
                (sl.ListId = @listId OR coalesce(sl.CompositeId,0) = @listId)) as x
     ON   x.SerialNo = slsi.SerialNo
   WHERE  x.SerialNo IS NULL AND
          sls.Stage = @stage AND
         (sl.ListId = @listId OR coalesce(sl.CompositeId,0) = @listId)
END

-- Select all the media to be verified
INSERT @tblVerify (ItemId, RowVersion)
SELECT sli.ItemId,
       sli.RowVersion
FROM   SendListItem sli
JOIN   SendList sl
  ON   sl.ListId = sli.ListId
LEFT   JOIN @tbl1 t1
  ON   t1.ItemId = sli.ItemId
WHERE  sli.Status NOT IN (1,256,512) AND t1.ItemId IS NULL AND
      (sl.ListId = @listId OR coalesce(sl.CompositeId,0) = @listId)

-- Remember the rowcount
SELECT @rowNo = 1, @rowcount = @@rowcount

-- Begin transaction
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

WHILE @rowNo <= @rowCount BEGIN
   SELECT @itemId = ItemId,
          @rowVersion = RowVersion
   FROM   @tblVerify
   WHERE  RowNo = @rowNo
   -- Verify the item
   EXECUTE @returnValue = sendListItem$verify @itemId, @rowVersion
   IF @returnValue != 0 BEGIN
       ROLLBACK TRANSACTION @tranName
       COMMIT TRANSACTION
       RETURN -100
   END
   -- Increment the row number
   SET @rowNo = @rowNo + 1
END       

-- Update the compare date for all scans of the list
UPDATE SendListScan
SET    Compared = cast(convert(nchar(19),getutcdate(),120) as datetime)
WHERE  Stage = @stage AND ListId IN (SELECT ListId FROM SendList WHERE ListId = @listId OR CompositeId = @listId)
SET @error = @@error
IF @error != 0 BEGIN
   ROLLBACK TRANSACTION @tranName
   COMMIT TRANSACTION
   SET @msg = ''Error encountered while updating comparison history.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
   EXECUTE error$raise @msg,@error
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
-- Procedure : receivelistscan$compare
--
-------------------------------------------------------------------------------
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'receivelistscan$compare')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.receivelistscan$compare
(
   @listName nchar(10)
)
WITH ENCRYPTION
AS
BEGIN
DECLARE @msg as nvarchar(255)        -- used to preformat error message
DECLARE @msgTag as nvarchar(255)     -- used to hold first part of error message header
DECLARE @tranName as nvarchar(255)   -- used to hold name of savepoint
DECLARE @rowVersion as rowversion
DECLARE @returnValue as int
DECLARE @rowcount int
DECLARE @itemId as int
DECLARE @listId int
DECLARE @status int
DECLARE @stage int
DECLARE @rowNo int
DECLARE @error int
DECLARE @tbl1 table (ItemId int, SerialNo nvarchar(32))
DECLARE @tblVerify table (RowNo int PRIMARY KEY CLUSTERED IDENTITY(1,1), ItemId int, RowVersion binary(8))

SET NOCOUNT ON

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=P;Call=(Select)''
SET @tranName = object_name(@@procid) + CAST(@@nestlevel as nvarchar(2))

-- Verify that the list exists.  Also, if the list is fully verified or better,
-- then there is no need to compare the list.
SELECT @listId = ListId, @status = Status
FROM   ReceiveList
WHERE  ListName = @listName
IF @@rowCount = 0 BEGIN
   SET @msg = ''Receive list not found.'' + @msgTag + ''>''
   RAISERROR(@msg,16,1)
   RETURN -100
END

-- Eligible?
IF dbo.bit$statusEligible(2,@status, 16) = 1
   SET @stage = 1
ELSE IF dbo.bit$statusEligible(2,@status, 256) = 1
   SET @stage = 2
ELSE BEGIN
   IF @status = 16 OR @status = 256 BEGIN
      SET @msg = ''List '' + @listName + '' has already been fully verified.'' + @msgTag + ''>''
      RAISERROR(@msg,16,1)
      RETURN -100
   END
   ELSE BEGIN
      SET @msg = ''List is not currently verification-eligible.'' + @msgTag + ''>''
      RAISERROR(@msg,16,1)
      RETURN -100
   END
END

-- In the first stage, we should be verifying tapes and sealed cases.  In the
-- second stage, all tapes should be verified individually.
IF @stage = 1 BEGIN
   --
   -- Result 1: Media on the list but not in the scans
   --
   INSERT @tbl1 (ItemId, SerialNo)
   SELECT rli.ItemId, m.SerialNo
   FROM   Medium m
   JOIN   ReceiveListItem rli
     ON   rli.MediumId = m.MediumId
   JOIN   ReceiveList rl
     ON   rl.ListId = rli.ListId
   LEFT OUTER JOIN 
         (SELECT rlsi.SerialNo   -- medium serial numbers
          FROM   ReceiveListScanItem rlsi
          JOIN   ReceiveListScan rls
            ON   rlsi.ScanId = rls.ScanId
          JOIN   ReceiveList rl
            ON   rl.ListId = rls.ListId
          WHERE  rls.Stage = @stage AND (rl.ListId = @listId OR coalesce(rl.CompositeId,0) = @listId)
          UNION
          SELECT m.SerialNo     -- case serial numbers
          FROM   Medium m
          JOIN   MediumSealedCase msc
            ON   msc.MediumId = m.MediumId
          JOIN   SealedCase sc
            ON   sc.CaseId = msc.CaseId
          JOIN   ReceiveListScanItem rlsi
            ON   rlsi.SerialNo = sc.SerialNo
          JOIN   ReceiveListScan rls
            ON   rls.ScanId = rlsi.ScanId
          JOIN   ReceiveList rl
            ON   rl.ListId = rls.ListId
          WHERE  rls.Stage = @stage AND (rl.ListId = @listId OR coalesce(rl.CompositeId,0) = @listId)) as x
     ON   x.SerialNo = m.SerialNo
   WHERE  x.SerialNo IS NULL AND rli.Status IN (2,4) AND
         (rl.ListId = @listId OR coalesce(rl.CompositeId,0) = @listId)
   ORDER BY m.SerialNo
   --
   -- Select the result set
   --
   SELECT SerialNo 
   FROM   @tbl1
   ORDER  BY SerialNo ASC
   --
   -- Result 2: Media in the scan but not on the list
   --
   SELECT distinct rlsi.SerialNo
   FROM   ReceiveListScanItem rlsi
   JOIN   ReceiveListScan rls
     ON   rls.ScanId = rlsi.ScanId
   JOIN   ReceiveList rl
     ON   rl.ListId = rls.ListId
   LEFT OUTER JOIN
         (SELECT m.SerialNo
          FROM   Medium m
          JOIN   ReceiveListItem rli
            ON   rli.MediumId = m.MediumId
          JOIN   ReceiveList rl
            ON   rl.ListId = rli.ListId
          WHERE  rli.Status != 1 AND
                (rl.ListId = @listId OR coalesce(rl.CompositeId,0) = @listId)
          UNION
          SELECT sc.SerialNo   -- sealed case serial numbers
          FROM   SealedCase sc
          JOIN   MediumSealedCase msc
            ON   msc.CaseId = sc.CaseId
          JOIN   ReceiveListItem rli
            ON   rli.MediumId = msc.MediumId
          JOIN   ReceiveList rl
            ON   rl.ListId = rli.ListId
          WHERE  rl.ListId = @listId OR 
                 coalesce(rl.CompositeId,0) = @listId) as x
     ON   x.SerialNo = rlsi.SerialNo
   WHERE  rls.Stage = @stage AND x.SerialNo IS NULL AND
         (rl.ListId = @listId OR coalesce(rl.CompositeId,0) = @listId)
   ORDER BY rlsi.SerialNo
END
ELSE BEGIN
   --
   -- Result 1: Media on the list but not in the scans
   --
   INSERT @tbl1 (ItemId, SerialNo)
   SELECT rli.ItemId, m.SerialNo
   FROM   Medium m
   JOIN   ReceiveListItem rli
     ON   rli.MediumId = m.MediumId
   JOIN   ReceiveList rl
     ON   rl.ListId = rli.ListId
   LEFT OUTER JOIN 
         (SELECT rlsi.SerialNo   -- medium serial numbers
          FROM   ReceiveListScanItem rlsi
          JOIN   ReceiveListScan rls
            ON   rlsi.ScanId = rls.ScanId
          JOIN   ReceiveList rl
            ON   rl.ListId = rls.ListId
          WHERE  rls.Stage = @stage AND (rl.ListId = @listId OR coalesce(rl.CompositeId,0) = @listId)) as x
     ON   x.SerialNo = m.SerialNo   
   WHERE  x.SerialNo IS NULL AND rli.Status NOT IN (1,256,512) AND
         (rl.ListId = @listId OR coalesce(rl.CompositeId,0) = @listId)
   ORDER BY m.SerialNo ASC
   --
   -- Select the result set
   --
   SELECT SerialNo 
   FROM   @tbl1
   ORDER  BY SerialNo ASC
   --
   -- Result 2: Media on the scans but not in the list
   --
   SELECT distinct rlsi.SerialNo
   FROM   ReceiveListScanItem rlsi
   JOIN   ReceiveListScan rls
     ON   rls.ScanId = rlsi.ScanId
   JOIN   ReceiveList rl
     ON   rl.ListId = rls.ListId
   LEFT OUTER JOIN
         (SELECT m.SerialNo
          FROM   Medium m
          JOIN   ReceiveListItem rli
            ON   rli.MediumId = m.MediumId
          JOIN   ReceiveList rl
            ON   rl.ListId = rli.ListId
          WHERE  rli.Status != 1 AND
                (rl.ListId = @listId OR coalesce(rl.CompositeId,0) = @listId)
          UNION
          SELECT sc.SerialNo   -- sealed case serial numbers
          FROM   SealedCase sc
          JOIN   MediumSealedCase msc
            ON   msc.CaseId = sc.CaseId
          JOIN   ReceiveListItem rli
            ON   rli.MediumId = msc.MediumId
          JOIN   ReceiveList rl
            ON   rl.ListId = rli.ListId
          WHERE  rl.ListId = @listId OR 
                 coalesce(rl.CompositeId,0) = @listId) as x
     ON   x.SerialNo = rlsi.SerialNo
   WHERE  rls.Stage = @stage AND x.SerialNo IS NULL AND
         (rl.ListId = @listId OR coalesce(rl.CompositeId,0) = @listId)
   ORDER BY rlsi.SerialNo ASC
END


-- Select all the media to be verified
INSERT @tblVerify (ItemId, RowVersion)
SELECT rli.ItemId,
       rli.RowVersion
FROM   ReceiveListItem rli
JOIN   ReceiveList rl
  ON   rl.ListId = rli.ListId
LEFT   JOIN @tbl1 t1
  ON   t1.ItemId = rli.ItemId
WHERE  rli.Status NOT IN (1,256,512) AND t1.ItemId IS NULL AND
      (rl.ListId = @listId OR coalesce(rl.CompositeId,0) = @listId)

-- Remember the rowcount
SELECT @rowNo = 1, @rowcount = @@rowcount

-- Begin transaction
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

WHILE @rowNo <= @rowCount BEGIN
   SELECT @itemId = ItemId,
          @rowVersion = RowVersion
   FROM   @tblVerify
   WHERE  RowNo = @rowNo
   -- Verify the item
   EXECUTE @returnValue = receiveListItem$verify @itemId, @rowVersion
   IF @returnValue != 0 BEGIN
       ROLLBACK TRANSACTION @tranName
       COMMIT TRANSACTION
       RETURN -100
   END
   -- Increment the row number
   SET @rowNo = @rowNo + 1
END

-- Update the compare date for all scans of the list
UPDATE ReceiveListScan
SET    Compared = cast(convert(nchar(19),getutcdate(),120) as datetime)
WHERE  Stage = @stage AND ListId IN (SELECT ListId FROM SendList WHERE ListId = @listId OR CompositeId = @listId)
SET @error = @@error
IF @error != 0 BEGIN
   ROLLBACK TRANSACTION @tranName
   COMMIT TRANSACTION
   SET @msg = ''Error encountered while updating comparison history.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
   EXECUTE error$raise @msg,@error
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
-- Procedure : sendListScanItem$getCase
--
-------------------------------------------------------------------------------
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'sendListScanItem$getCase')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.sendListScanItem$getCase
(
   @listId int,
   @serialNo nvarchar(128)
)
WITH ENCRYPTION
AS
BEGIN

SET NOCOUNT ON

SELECT x1.CaseName
FROM   SendListScanItem x1
JOIN   SendListScan x2
  ON   x2.ScanId = x1.ScanId
WHERE  x2.ListId = @listId AND x1.SerialNo = @serialNo

END
'
)

IF @@error != 0 GOTO ROLL_IT

-------------------------------------------------------------------------------
--
-- Version update
--
-------------------------------------------------------------------------------
IF NOT EXISTS(SELECT 1 FROM DatabaseVersion WHERE Major = 1 AND Minor = 3 AND Revision = 9) BEGIN
   EXECUTE spidLogin$ins 'System', 'Insert database version'
   INSERT DatabaseVersion (Major, Minor, Revision) VALUES (1, 3, 9)
   EXECUTE spidLogin$del 1
END
ELSE BEGIN
   UPDATE DatabaseVersion 
   SET    InstallDate = getutcdate() 
   WHERE  Major = 1 AND Minor = 3 AND Revision = 9
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
