SET NOCOUNT ON

-- Should we run this script?
IF dbo.bit$doScript('1.3.5') = 1 BEGIN

DECLARE @CREATE nvarchar(10)

BEGIN TRANSACTION

-------------------------------------------------------------------------------
--
-- Allow for vault operator role
--
-------------------------------------------------------------------------------
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.CHECK_CONSTRAINTS WHERE CONSTRAINT_NAME = 'chkOperator$Role') BEGIN
   EXEC ('ALTER TABLE Operator DROP CONSTRAINT chkOperator$Role')
   EXEC ('ALTER TABLE Operator ADD CONSTRAINT chkOperator$Role CHECK (Role = 32768 or Role = 8192 or Role = 2048 or Role = 128 or Role = 8)')
END

-------------------------------------------------------------------------------
--
-- In 1.3.2 we set a preference with key = 16 to 'YES'.  The key should have
-- been 15.  So what we will do is, if the key 16 exists with a value equal
-- to 'YES', we will delete it.  We can do this b/c the value associated with
-- key 16 should be a numerical value. (The preference in 1.3.2 has since
-- been commented out.)
--
-------------------------------------------------------------------------------
IF EXISTS (SELECT 1 FROM Preference WHERE KeyNo = 16 AND Value = 'YES') BEGIN
   EXECUTE spidlogin$ins 'System', 'delete preference'
   DELETE  Preference WHERE KeyNo = 16
   EXECUTE spidlogin$del 1
END

-------------------------------------------------------------------------------
--
-- Stored procedures and triggers
--
-------------------------------------------------------------------------------
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'sendListScan$compare')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.sendListScan$compare
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
IF dbo.bit$statusEligible(1,@status,8) = 1
   SET @stage = 1
ELSE IF dbo.bit$statusEligible(1,@status,256) = 1
   SET @stage = 2
ELSE BEGIN
   IF @status = 8 OR @status = 256 BEGIN
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
   SELECT slsi.SerialNo
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
   WHERE  sli.Status = 2 AND
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
   SELECT slsi.SerialNo
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
DECLARE @serialNo nvarchar(32)
DECLARE @rowVersion rowversion
DECLARE @returnValue int
DECLARE @mediumId int
DECLARE @rowcount int
DECLARE @error int
DECLARE @tbl1 table (RowNo int identity(1,1), ItemId int, Status int, MediumId int, ListName nvarchar(10))
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

-- Get all the restored items into the temporary table.  If there is another
-- item on an active list with the same serial number, cry foul.
INSERT @tbl1 (ItemId, MediumId)
SELECT i.ItemId, i.MediumId
FROM   Inserted i
JOIN   Deleted d
  ON   d.ItemId = i.ItemId
WHERE  d.Status = 1 AND i.Status != 1
IF @@rowcount != 0 BEGIN
   -- Get the first row number
   SELECT @i = min(RowNo) 
   FROM   @tbl1
   -- Loop through the results
   WHILE 1 = 1 BEGIN
      SELECT @itemId = i.Itemid,
             @mediumId = i.MediumId
      FROM   @tbl1 i
      WHERE  RowNo = @i
      IF @@rowcount = 0 BREAK
      -- Make sure no other item exists
      IF EXISTS 
         (
         SELECT 1 
         FROM   DisasterCodeListItem
         WHERE  Status not in (1,512) and MediumId = @mediumId and ItemId != @itemId
         )
      BEGIN
         SELECT @serialNo = SerialNo FROM Medium WHERE MediumId = @mediumId
         SET @msg = ''Medium '' + @serialNo + '' may not appear on more than one active disaster recovery list.'' + @msgTag + ''>''
         EXECUTE error$raise @msg
         RETURN
      END
      -- Increment counter
      SET @i = @i + 1
   END
   -- Reset the temporary table for the next operation
   DELETE FROM @tbl1
END

-- Begin the transaction
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

-- Get all the removed and restored items into the temporary table
INSERT @tbl1 (ItemId, Status, Mediumid, ListName)
SELECT i.ItemId, i.Status, i.MediumId, dl.ListName
FROM   Inserted i
JOIN   Deleted d
  ON   d.ItemId = i.ItemId
JOIN   DisasterCodeList dl
  ON   dl.Listid = i.ListId
WHERE  i.Status in (1,2) AND d.Status != i.Status
IF @@rowcount != 0 BEGIN
   -- Get the first row number
   SELECT @i = min(RowNo) 
   FROM   @tbl1
   -- Loop through the results
   WHILE 1 = 1 BEGIN
      SELECT @itemid = i.ItemId, 
             @status = i.Status,
             @serialNo = m.SerialNo,
             @listName = i.ListName
      FROM   @tbl1 i
      JOIN   Medium m
        ON   m.MediumId = i.MediumId
      WHERE  i.RowNo = @i
      -- If nothing left, break
      IF @@rowcount = 0 BREAK
      -- Create the audit message
      IF @status = 1
         SELECT @audit = 5, @msgUpdate = ''Medium '' + @serialNo + '' removed from list '' + @listName
      ELSE IF @status = 2
         SELECT @audit = 4, @msgUpdate = ''Medium '' + @serialNo + '' added to list '' + @listName + ''.''   -- restored, actually
      -- Insert the audit message
      INSERT XDisasterCodeListItem (Object, Action, Detail, Login)
      VALUES (@listName, @audit, @msgUpdate, dbo.string$GetSpidLogin())
      SET @error = @@error
      IF @error != 0 BEGIN
         SET @msg = ''Error encountered while inserting disaster recovery list item audit record.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
         EXECUTE error$raise @msg, @error, @tranName
         RETURN
      END
      -- Next row
      SET @i = @i + 1
   END
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

IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'sendList$getByStatusAndDate')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.sendList$getByStatusAndDate
(
   @status int,
   @createDate datetime
)
WITH ENCRYPTION
AS
BEGIN
DECLARE @dateString nchar(10)

SET NOCOUNT ON

SET @dateString = convert(nchar(10),@createDate,120)

-- Select standalone discrete lists and composites where at least one
-- of the constituent discretes has the given status.
SELECT sl.ListId,
       sl.ListName as ''ListName'',
       sl.CreateDate,
       sl.Status,
       a.AccountName,
       sl.RowVersion
FROM   SendList sl
JOIN   Account a 
  ON   a.AccountId = sl.AccountId
WHERE  sl.CompositeId IS NULL And 
       sl.Status = (sl.Status & @status) And 
       convert(nchar(10),sl.CreateDate,120) = @dateString
UNION
SELECT sl.ListId,
       sl.ListName,
       sl.CreateDate,
       sl.Status,
       '''',
       sl.RowVersion
FROM   SendList sl
WHERE  sl.AccountId IS NULL And
       EXISTS (SELECT 1 
               FROM   SendList sl2
               WHERE  CompositeId = sl.ListId And 
                      sl2.Status = (sl2.Status & @Status) And 
                      convert(nchar(10),sl2.CreateDate,120) = @dateString)
ORDER  BY ListName Desc

END
'
)

-- 
-- Modification to procedure sendList$getPage
--
-- Who	When	    What
-- ---	--------    -----------------------------------------------------
-- JJF   02/12/07    Added support for a filter containing 'Status &'
--
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'sendList$getPage')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.sendList$getPage
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
DECLARE @x1 nvarchar(1000)   -- List name
DECLARE @x2 nvarchar(1000)   -- Create date
DECLARE @x3 nvarchar(1000)   -- Status
DECLARE @x4 nvarchar(1000)   -- Account
DECLARE @s nvarchar(4000)
DECLARE @p int

SET NOCOUNT ON

-- Set the message tag
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=P''

-- Verify validity of @pageNo
IF @pageNo < 1 SET @pageNo = 1

-- Initialize variable string
SELECT @var = ''@x1$ nvarchar(1000), @x2$ nvarchar(1000), @x3$ nvarchar(1000), @x4$ nvarchar(1000)''
SELECT @p = -1

-- Set the order clauses
IF @sort = 1 BEGIN
   SET @order1 = '' ORDER BY sl.ListName desc''
   SET @order2 = '' ORDER BY ListName asc''
   SET @order3 = '' ORDER BY ListName desc''
END
ELSE IF @sort = 2 BEGIN
   SET @order1 = '' ORDER BY sl.CreateDate desc, sl.ListName desc''
   SET @order2 = '' ORDER BY CreateDate asc, ListName asc''
   SET @order3 = '' ORDER BY CreateDate desc, ListName desc''
END
ELSE IF @sort = 3 BEGIN
   SET @order1 = '' ORDER BY sl.Status asc, sl.ListName desc''
   SET @order2 = '' ORDER BY Status desc, ListName asc''
   SET @order3 = '' ORDER BY Status asc, ListName desc''
END
ELSE IF @sort = 4 BEGIN
   SET @order1 = '' ORDER BY a.AccountName asc, sl.ListName desc''
   SET @order2 = '' ORDER BY AccountName desc, ListName asc''
   SET @order3 = '' ORDER BY AccountName asc, ListName desc''
END
ELSE BEGIN
   SET @msg = ''Invalid sort order.'' + @msgTag + ''>''
   RAISERROR(@msg,16,1)
   RETURN -100
END

-- Construct the where clause
SET @where = '' WHERE sl.CompositeId IS NULL ''   -- Get only the top level lists
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
   IF charindex(''ListName ='', @s) = 1 BEGIN
      SET @where = @where + '' AND (sl.'' + left(@s, charindex(''='',@s) + 1) + '' @x1$)''
      SET @x1 = replace(ltrim(substring(@s, charindex(''='',@s) + 1, 4000)), '''''''', '''')
   END
   ELSE IF charindex(''CreateDate ='', @s) = 1 BEGIN
      SET @where = @where + '' AND ('' + replace(left(@s, charindex(''='',@s) + 1),''CreateDate'',''coalesce(convert(nvarchar(10),sl.CreateDate,120),'''''''')'') + '' @x2$)''
      SET @x2 = replace(ltrim(substring(@s, charindex(''='',@s) + 1, 4000)), '''''''', '''')
   END
   ELSE IF charindex(''Status ='', @s) = 1 BEGIN
      SET @where = @where + '' AND (sl.'' + left(@s, charindex(''='',@s) + 1) + '' @x3$)''
      SET @x3 = replace(ltrim(substring(@s, charindex(''='',@s) + 1, 4000)), '''''''', '''')
   END
   ELSE IF charindex(''Status &'', @s) = 1 BEGIN
      SET @where = @where + '' AND (sl.Status = (sl.'' + left(@s, charindex(''&'',@s) + 1) + '' @x3$))''
      SET @x3 = replace(ltrim(substring(@s, charindex(''&'',@s) + 1, 4000)), '''''''', '''')
   END
   ELSE IF charindex(''AccountName ='', @s) = 1 BEGIN
      SET @where = @where + '' AND ('' + replace(left(@s, charindex(''='',@s) + 1),''AccountName'',''coalesce(a.AccountName,'''''''')'') + '' @x4$)''
      SET @x4 = replace(ltrim(substring(@s, charindex(''='',@s) + 1, 4000)), '''''''', '''')
   END
   ELSE BEGIN
      SET @msg = ''Error occurred while selecting page of shipping lists.  Invalid filter supplied.'' + @msgTag + ''>''
      EXECUTE error$raise @msg
      RETURN -100
   END
END

-- Construct the fields string
SET @fields2 = ''ListId, ListName, CreateDate, Status, AccountName, RowVersion''
SET @fields1 = ''sl.ListId, sl.ListName, sl.CreateDate, sl.Status, coalesce(a.AccountName,'''''''') as ''''AccountName'''', sl.RowVersion''

-- Construct the tables string
SET @tables = ''SendList sl LEFT OUTER JOIN Account a ON sl.AccountId = a.AccountId''

-- Select the total number of records that fit the criteria
CREATE TABLE #tblTemp (xyz int)
SET @sql = ''INSERT #tblTemp SELECT count(*) FROM '' + @tables + @where
EXECUTE sp_executesql @sql, @var, @x1$ = @x1, @x2$ = @x2, @x3$ = @x3, @x4$ = @x4
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
print @sql
-- Execute the sql
EXECUTE sp_executesql @sql, @var, @x1$ = @x1, @x2$ = @x2, @x3$ = @x3, @x4$ = @x4
SET @error = @@error
IF @error != 0 BEGIN
   SET @msg = ''Error occurred while selecting lists to display.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
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

IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'receiveList$getByStatusAndDate')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.receiveList$getByStatusAndDate
(
   @status int,
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
JOIN   Account a
  ON   a.AccountId = rl.AccountId
WHERE  CompositeId IS NULL And 
       rl.Status = (rl.Status & @status) And 
       convert(nchar(10),rl.CreateDate,120) = @dateString
UNION
SELECT rl.ListId,
       rl.ListName,
       rl.CreateDate,
       rl.Status,
       '''',
       rl.RowVersion
FROM   ReceiveList rl
WHERE  AccountId IS NULL And EXISTS (SELECT 1 
                                     FROM   ReceiveList rl2 
                                     WHERE  CompositeId = rl.ListId And 
                                            rl2.Status = (rl2.Status & @Status) And 
                                            convert(nchar(10),rl2.CreateDate,120) = @dateString)
ORDER  BY ListName Desc

END
'
)

IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'receiveList$getPage')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.receiveList$getPage
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
DECLARE @tableName nvarchar(4000)
DECLARE @topSize int
DECLARE @display int
DECLARE @count int
DECLARE @error int
DECLARE @x1 nvarchar(1000)   -- List name
DECLARE @x2 nvarchar(1000)   -- Create date
DECLARE @x3 nvarchar(1000)   -- Status
DECLARE @x4 nvarchar(1000)   -- Account
DECLARE @s nvarchar(4000)
DECLARE @p int

SET NOCOUNT ON

-- Set the message tag
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=P''

-- Verify validity of @pageNo
IF @pageNo < 1 SET @pageNo = 1

-- Initialize variable string
SELECT @var = ''@x1$ nvarchar(1000), @x2$ nvarchar(1000), @x3$ nvarchar(1000), @x4$ nvarchar(1000)''
SELECT @p = -1

-- Set the order clauses
IF @sort = 1 BEGIN
   SET @order1 = '' ORDER BY rl.ListName desc''
   SET @order2 = '' ORDER BY ListName asc''
   SET @order3 = '' ORDER BY ListName desc''
END
ELSE IF @sort = 2 BEGIN
   SET @order1 = '' ORDER BY rl.CreateDate desc, rl.ListName desc''
   SET @order2 = '' ORDER BY CreateDate asc, ListName asc''
   SET @order3 = '' ORDER BY CreateDate desc, ListName desc''
END
ELSE IF @sort = 3 BEGIN
   SET @order1 = '' ORDER BY rl.Status asc, rl.ListName desc''
   SET @order2 = '' ORDER BY Status desc, ListName asc''
   SET @order3 = '' ORDER BY Status asc, ListName desc''
END
ELSE IF @sort = 4 BEGIN
   SET @order1 = '' ORDER BY a.AccountName asc, rl.ListName desc''
   SET @order2 = '' ORDER BY AccountName desc, ListName asc''
   SET @order3 = '' ORDER BY AccountName asc, ListName desc''
END
ELSE BEGIN
   SET @msg = ''Invalid sort order.'' + @msgTag + ''>''
   RAISERROR(@msg,16,1)
   RETURN -100
END

-- Construct the where clause
SET @where = '' WHERE rl.CompositeId IS NULL ''   -- Get only the top level lists
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
   IF charindex(''ListName ='', @s) = 1 BEGIN
      SET @where = @where + '' AND (rl.'' + left(@s, charindex(''='',@s) + 1) + '' @x1$)''
      SET @x1 = replace(ltrim(substring(@s, charindex(''='',@s) + 1, 4000)), '''''''', '''')
   END
   ELSE IF charindex(''CreateDate ='', @s) = 1 BEGIN
      SET @where = @where + '' AND ('' + replace(left(@s, charindex(''='',@s) + 1),''CreateDate'',''coalesce(convert(nvarchar(10),rl.CreateDate,120),'''''''')'') + '' @x2$)''
      SET @x2 = replace(ltrim(substring(@s, charindex(''='',@s) + 1, 4000)), '''''''', '''')
   END
   ELSE IF charindex(''Status ='', @s) = 1 BEGIN
      SET @where = @where + '' AND (rl.'' + left(@s, charindex(''='',@s) + 1) + '' @x3$)''
      SET @x3 = replace(ltrim(substring(@s, charindex(''='',@s) + 1, 4000)), '''''''', '''')
   END
   ELSE IF charindex(''Status &'', @s) = 1 BEGIN
      SET @where = @where + '' AND (rl.Status = (rl.'' + left(@s, charindex(''&'',@s) + 1) + '' @x3$))''
      SET @x3 = replace(ltrim(substring(@s, charindex(''&'',@s) + 1, 4000)), '''''''', '''')
   END
   ELSE IF charindex(''AccountName ='', @s) = 1 BEGIN
      SET @where = @where + '' AND ('' + replace(left(@s, charindex(''='',@s) + 1),''AccountName'',''coalesce(a.AccountName,'''''''')'') + '' @x4$)''
      SET @x4 = replace(ltrim(substring(@s, charindex(''='',@s) + 1, 4000)), '''''''', '''')
   END
   ELSE BEGIN
      SET @msg = ''Error occurred while selecting page of receiving lists.  Invalid filter supplied.'' + @msgTag + ''>''
      EXECUTE error$raise @msg
      RETURN -100
   END
END

-- Construct the fields string
SET @fields2 = ''ListId, ListName, CreateDate, Status, AccountName, RowVersion''
SET @fields1 = ''rl.ListId, rl.ListName, rl.CreateDate, rl.Status, coalesce(a.AccountName,'''''''') as ''''AccountName'''', rl.RowVersion''

-- Construct the tables string
SET @tables = ''ReceiveList rl LEFT OUTER JOIN Account a ON rl.AccountId = a.AccountId''

-- Select the total number of records that fit the criteria
CREATE TABLE #tblTemp (xyz int)
SET @sql = ''INSERT #tblTemp SELECT count(*) FROM '' + @tables + @where
EXECUTE sp_executesql @sql, @var, @x1$ = @x1, @x2$ = @x2, @x3$ = @x3, @x4$ = @x4
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
EXECUTE sp_executesql @sql, @var, @x1$ = @x1, @x2$ = @x2, @x3$ = @x3, @x4$ = @x4
SET @error = @@error
IF @error != 0 BEGIN
   SET @msg = ''Error occurred while selecting lists to display.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
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

IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'sendListCase$upd')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.sendListCase$upd
(
   @caseId int,
   @typeName nvarchar(128),
   @caseName nvarchar(32),
   @sealed bit,
   @returnDate datetime,
   @notes nvarchar(32),
   @rowVersion rowversion
)
WITH ENCRYPTION
AS
BEGIN
DECLARE @msg as nvarchar(255)        -- used to preformat error message
DECLARE @msgTag as nvarchar(255)     -- used to hold first part of error message header
DECLARE @tranName as nvarchar(255)   -- used to hold name of savepoint
DECLARE @returnValue as int
DECLARE @status as int
DECLARE @typeId as int
DECLARE @error as int
DECLARE @clear as bit

SET NOCOUNT ON

-- Tweak parameters
SET @returnDate = cast(convert(nchar(10),@returnDate,120) as datetime)
IF datepart(yyyy,@returndate) = 1900 set @returnDate = NULL
SET @notes = ltrim(rtrim(@notes))

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=P''
SET @tranName = object_name(@@procid) + CAST(@@nestlevel as nvarchar(2))

-- Verify that the case has not been altered since retrieval
SELECT @clear = Cleared
FROM   SendListCase
WHERE  CaseId = @caseId AND
       RowVersion = @rowVersion
IF @@rowCount = 0 BEGIN
   IF EXISTS(SELECT 1 FROM SendListCase WHERE CaseId = @caseId) BEGIN
      SET @msg = ''Send list case has been modified since retrieval.'' + @msgTag + ''>''
      RAISERROR(@msg,16,1)
      RETURN -100
   END
   ELSE BEGIN
      SET @msg = ''Send list case not found.'' + @msgTag + ''>''
      RAISERROR(@msg,16,1)
      RETURN -100
   END
END
ELSE BEGIN
   IF @clear = 1 BEGIN
      SET @msg = ''A send list case that has already been processed may not be altered.'' + @msgTag + ''>''
      RAISERROR(@msg,16,1)
      RETURN -100
   END
END

-- Verify that the case does not appear on any lists that have been 
-- transmitted or beyond (but cleared is okay).
SELECT @status = sl.Status
FROM   SendListCase slc
JOIN   SendListItemCase slic
  ON   slic.CaseId = slc.CaseId
JOIN   SendListItem sli
  ON   sli.ItemId = slic.ItemId
JOIN   SendList sl
  ON   sl.ListId = sli.ListId
WHERE  slc.CaseId = @caseId AND sli.Status >= 16 AND sli.Status != 512 -- power(2,x)
IF @@rowcount != 0 BEGIN
   SET @msg = ''Send list case may not be altered once the list on which it appears has reached '' + dbo.string$statusName(1,16) + '' status.'' + @msgTag + ''>''
   RAISERROR(@msg,16,1)
   RETURN -100
END

-- If the case is to be unsealed, set the return date to null.  Return date
-- should be later than today, but this check will be done in the middle layer.
IF @sealed = 0 SET @returnDate = NULL
   
-- Get the type for the case
SELECT @typeId = TypeId
FROM   MediumType
WHERE  TypeName = @typeName AND Container = 1
IF @@rowCount = 0 BEGIN
   SET @msg = ''Invalid case type.'' + @msgTag + ''>''
   RAISERROR(@msg,16,1)
   RETURN -100
END

-- Perform update
BEGIN TRANSACTION
SAVE TRANSACTION @tranName
UPDATE SendListCase
SET    SerialNo = @caseName,
       TypeId = @typeId,
       Sealed = @sealed,
       ReturnDate = @returnDate,
       Notes = @notes
WHERE  CaseId = @caseId
SET @error = @@error
IF @error != 0 BEGIN
   ROLLBACK TRANSACTION @tranName
   COMMIT TRANSACTION
   SET @msg = ''Error encountered while updating send list case.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
   EXECUTE error$raise @msg, @error
   RETURN -100
END
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
IF NOT EXISTS(SELECT 1 FROM DatabaseVersion WHERE Major = 1 AND Minor = 3 AND Revision = 5) BEGIN
   DECLARE @x nvarchar(1000)
   EXECUTE spidLogin$ins 'System', 'Insert database version'
   INSERT DatabaseVersion (Major, Minor, Revision) VALUES (1, 3, 5)
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
