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
IF dbo.bit$doScript('1.3.3') = 1 BEGIN

BEGIN TRANSACTION

IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.CHECK_CONSTRAINTS WHERE CONSTRAINT_NAME = 'chkInventoryItem$SerialNo') BEGIN

ALTER TABLE dbo.InventoryItem 
   DROP CONSTRAINT chkInventoryItem$SerialNo

ALTER TABLE dbo.InventoryItem
   ADD CONSTRAINT chkInventoryItem$SerialNo
      CHECK (dbo.bit$IsEmptyString(SerialNo) = 0 and dbo.bit$IllegalCharacters(SerialNo, '_&?%*|^~') = 0)

END

DECLARE @CREATE nvarchar(10)
-------------------------------------------------------------------------------
--
-- Add stored procedures
--
-------------------------------------------------------------------------------
IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'sendListCase$browse')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.sendListCase$browse
WITH ENCRYPTION
AS
BEGIN
DECLARE @tbl1 table (RowNo int identity(1,1), CaseId int, CaseName nvarchar(256), TypeName nvarchar(256), Sealed bit, Location bit, ReturnDate nvarchar(10), NumTapes int, ListName nvarchar(10), Notes nvarchar(3000), RowVersion binary(8))
DECLARE @listName nvarchar(10)
DECLARE @compositeId int
DECLARE @status int
DECLARE @loc int
DECLARE @id int
DECLARE @i int

SET NOCOUNT ON

-- Get the send list cases
INSERT @tbl1 (CaseId, CaseName, TypeName, Sealed, Location, ReturnDate, ListName, Notes, RowVersion)
SELECT c.CaseId, c.SerialNo, t.TypeName, c.Sealed, 1, isnull(convert(nvarchar(10),c.ReturnDate,120),''''), '''', c.Notes, c.RowVersion
FROM   SendListCase c
JOIN   MediumType t
  ON   t.TypeId = c.TypeId
WHERE  c.Cleared = 0

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
   SET    NumTapes = (SELECT count(*) 
                      FROM   SendListItemCase slic
                      JOIN   SendListItem sli
                        ON   sli.ItemId = slic.ItemId
                      JOIN   Medium m
                        ON   m.MediumId = sli.MediumId
                      WHERE  slic.CaseId = @id)
   WHERE  RowNo = @i
   -- Get the location...if the tape is on a send list and the status is 
   -- arrived or greater, then the location is at the enterprise.
   SELECT TOP 1 @listName = s.ListName, 
          @compositeId = s.CompositeId,
          @status = s.Status
   FROM   SendList s
   JOIN   SendListItem si
     ON   si.ListId = s.ListId
   JOIN   SendListItemCase c
     ON   c.ItemId = si.ItemId
   WHERE  c.CaseId = @id
   IF @@rowcount != 0 BEGIN
      IF @compositeId IS NOT NULL BEGIN
         SELECT @listName = ListName
         FROM   SendList
         WHERE  ListId = @compositeId
      END
      -- Set the location
--      IF @status >= 64 SET @loc = 0 ELSE SET @loc = 1
      -- Update the table
      UPDATE @tbl1
      SET    Location = isnull(@loc,1), 
             ListName = @listName
      WHERE  RowNo = @i
   END
   -- Increment counter
   SET @i = @i + 1
END

-- Select results in case name order
SELECT CaseId, 
       CaseName, 
       TypeName, 
       Sealed, 
       Location, 
       ReturnDate, 
       NumTapes, 
       ListName,
       Notes,
       RowVersion
FROM   @tbl1
ORDER  BY CaseName ASC

END
'
)

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'sealedCase$browse')
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
   WHERE  c.CaseId = @id
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

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'medium$ins')
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

IF EXISTS(SELECT * FROM sysobjects WHERE name = 'receiveList$afterDelete' AND objectproperty(id, 'ExecIsDeleteTrigger' ) = 1) 
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'TRIGGER receiveList$afterDelete
ON     ReceiveList
WITH ENCRYPTION
AFTER  DELETE
AS
BEGIN
DECLARE @msg nvarchar(255)        -- used to preformat error message
DECLARE @msgTag nvarchar(255)     -- used to hold first part of error message header
DECLARE @tranName nvarchar(255)   -- used to hold name of savepoint
DECLARE @msgUpdate nvarchar(4000)
DECLARE @tagInfo nvarchar(1000)          
DECLARE @login nvarchar(32)          
DECLARE @returnValue int
DECLARE @lastList int
DECLARE @listName char(10)       -- holds the name of the deleted receive list
DECLARE @rowCount int            -- holds the number of rows in the Deleted table
DECLARE @error int          
DECLARE @cid int          
DECLARE @rv binary(8)

SET @rowCount = @@rowcount
IF @rowCount = 0 RETURN

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=T''
SET @tranName = object_name(@@procid) + CAST(trigger_nestlevel(@@procid) as nvarchar(2))

-- Get the spid info
SELECT @login = dbo.string$GetSpidLogin()
SELECT @tagInfo = dbo.string$GetSpidInfo()

-- Begin transaction
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

-- Get the caller login from the spidLogin table
IF len(dbo.string$GetSpidLogin()) = 0 BEGIN
   SET @msg = ''Caller login not found in spid login table.'' + @msgTag + ''>''
   EXECUTE error$raise @msg, 0, @tranName
   RETURN
END

-- Audit
SET @lastList = 0
WHILE 1 = 1 BEGIN
   SELECT TOP 1 @lastList = ListId,
          @listName = ListName
   FROM   Deleted
   WHERE  ListId > @lastList
   ORDER BY ListId ASC
   IF @@rowCount = 0 BREAK
   -- Set the update message
   SELECT @msgUpdate = ''''
   IF CHARINDEX(''extract'',@tagInfo) > 0 BEGIN
      SELECT @msgUpdate = ''Receive list '' + @listName + '' dissolved''
   END
   ELSE IF CHARINDEX(''merge'',@tagInfo) > 0 BEGIN
      SELECT @msgUpdate = ''Receive list '' + @listName + '' deleted due to merge''
   END
   ELSE IF CHARINDEX(''delete'',@tagInfo) > 0 BEGIN
      SELECT @msgUpdate = ''Receive list '' + @listName + '' deleted''
   END
   ELSE IF NOT EXISTS (SELECT 1 FROM ReceiveListItem WHERE ListId = @lastList AND Status != 1) BEGIN
      SELECT @msgUpdate = ''Receive list '' + @listName + '' deleted''
   END
   IF len(@msgUpdate) > 0 BEGIN
      INSERT XReceiveList
      (
         Object, 
         Action, 
         Detail, 
         Login
      )
      VALUES
      (
         @listName, 
         3, 
         @msgUpdate, 
         @login
      )
      SET @error = @@error
      IF @error != 0 BEGIN
         SET @msg = ''Error inserting a row into the receive list audit table.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
         EXECUTE error$raise @msg, @error, @tranName
         RETURN
      END
   END
   -- If the list belonged to a composite, then if the composite still has active items, set its status.  If
   -- the composite has no other discrete lists, however, then delete the composite.
   SELECT @cid = isnull(CompositeId,-1)
   FROM   Deleted
   WHERE  ListId = @lastList
   IF @cid != -1 BEGIN
      -- Get the rowversion
      SELECT @rv = RowVersion
      FROM   ReceiveList
      WHERE  ListId = @cid
      -- Take appropriate action
      IF EXISTS
         (
         SELECT 1
         FROM   ReceiveListItem rli
         JOIN   ReceiveList rl
           ON   rl.ListId = rli.ListId
         WHERE  rli.Status != 1 AND rl.CompositeId = @cid
         )
      BEGIN
         EXECUTE @returnValue = receiveList$setStatus @cid, @rv
         IF @returnValue = -100 BEGIN
            ROLLBACK TRANSACTION @tranName
            COMMIT TRANSACTION
            RETURN
         END
      END
      ELSE BEGIN
         EXECUTE @returnValue = receiveList$del @cid, @rv
         IF @returnValue = -100 BEGIN
            ROLLBACK TRANSACTION @tranName
            COMMIT TRANSACTION
            RETURN
         END
      END
   END
END

COMMIT TRANSACTION
END
'
)

IF EXISTS(SELECT * FROM sysobjects WHERE name = 'sendList$afterDelete' AND objectproperty(id, 'ExecIsDeleteTrigger' ) = 1) 
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'TRIGGER sendList$afterDelete
ON     SendList
WITH ENCRYPTION
AFTER  DELETE
AS
BEGIN
DECLARE @msg nvarchar(255)        -- used to preformat error message
DECLARE @msgTag nvarchar(255)     -- used to hold first part of error message header
DECLARE @tranName nvarchar(255)   -- used to hold name of savepoint
DECLARE @msgUpdate nvarchar(4000)
DECLARE @tagInfo nvarchar(1000)          
DECLARE @login nvarchar(32)          
DECLARE @lastList int
DECLARE @tapeCount int
DECLARE @returnValue int
DECLARE @listName char(10)       -- holds the name of the deleted send list
DECLARE @rowCount int            -- holds the number of rows in the Deleted table
DECLARE @action int          
DECLARE @error int          
DECLARE @cid int          
DECLARE @rv binary(8)          

SET @rowCount = @@rowcount
IF @rowCount = 0 RETURN

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=T''
SET @tranName = object_name(@@procid) + CAST(trigger_nestlevel(@@procid) as nvarchar(2))

-- Get the spid info
SELECT @login = dbo.string$GetSpidLogin()
SELECT @tagInfo = dbo.string$GetSpidInfo()

BEGIN TRANSACTION
SAVE TRANSACTION @tranName

-- Get the caller login from the spidLogin table
IF len(dbo.string$GetSpidLogin()) = 0 BEGIN
   SET @msg = ''Caller login not found in spid login table.'' + @msgTag + ''>''
   EXECUTE error$raise @msg, 0, @tranName
   RETURN
END


-- Audit
SET @lastList = 0
WHILE 1 = 1 BEGIN
   SELECT TOP 1 @lastList = ListId,
          @listName = ListName
   FROM   Deleted
   WHERE  ListId > @lastList
   ORDER BY ListId ASC
   IF @@rowCount = 0 BREAK
   -- Set the update message
   SELECT @msgUpdate = ''''
   IF CHARINDEX(''extract'',@tagInfo) > 0 BEGIN
      SELECT @msgUpdate = ''Send list '' + @listName + '' dissolved''
   END
   ELSE IF CHARINDEX(''merge'',@tagInfo) > 0 BEGIN
      SELECT @msgUpdate = ''Send list '' + @listName + '' deleted due to merge''
   END
   ELSE IF CHARINDEX(''delete'',@tagInfo) > 0 BEGIN
      SELECT @msgUpdate = ''Send list '' + @listName + '' deleted''
   END
   ELSE IF NOT EXISTS (SELECT 1 FROM SendListItem WHERE ListId = @lastList AND Status != 1) BEGIN
      SELECT @msgUpdate = ''Send list '' + @listName + '' deleted''
   END
   IF len(@msgUpdate) > 0 BEGIN
      INSERT XSendList
      (
         Object, 
         Action, 
         Detail, 
         Login
      )
      VALUES
      (
         @listName, 
         3, 
         @msgUpdate, 
         @login
      )
      SET @error = @@error
      IF @error != 0 BEGIN
         SET @msg = ''Error inserting a row into the send list audit table.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
         EXECUTE error$raise @msg, @error, @tranName
         RETURN
      END
   END
   -- If the list belonged to a composite, then if the composite still has active items, set its status.  If
   -- the composite has no other discrete lists, however, then delete the composite.
   SELECT @cid = isnull(CompositeId,-1)
   FROM   Deleted
   WHERE  ListId = @lastList
   IF @cid != -1 BEGIN
      -- Get the rowversion
      SELECT @rv = RowVersion
      FROM   SendList
      WHERE  ListId = @cid
      -- Take appropriate action
      IF EXISTS
         (
         SELECT 1
         FROM   SendListItem sli
         JOIN   SendList sl
           ON   sl.ListId = sli.ListId
         WHERE  sli.Status != 1 AND sl.CompositeId = @cid
         )
      BEGIN
         EXECUTE @returnValue = sendList$setStatus @cid, @rv
         IF @returnValue = -100 BEGIN
            ROLLBACK TRANSACTION @tranName
            COMMIT TRANSACTION
            RETURN
         END
      END
      ELSE BEGIN
         EXECUTE @returnValue = sendList$del @cid, @rv
         IF @returnValue = -100 BEGIN
            ROLLBACK TRANSACTION @tranName
            COMMIT TRANSACTION
            RETURN
         END
      END
   END
END

COMMIT TRANSACTION
END
'
)

IF EXISTS(SELECT * FROM sysobjects WHERE name = 'disasterCodeList$afterDelete' AND objectproperty(id, 'ExecIsDeleteTrigger' ) = 1) 
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'TRIGGER disasterCodeList$afterDelete
ON     DisasterCodeList
WITH ENCRYPTION
AFTER  DELETE
AS
BEGIN
DECLARE @msg nvarchar(255)        -- used to preformat error message
DECLARE @msgTag nvarchar(255)     -- used to hold first part of error message header
DECLARE @tranName nvarchar(255)   -- used to hold name of savepoint
DECLARE @msgUpdate nvarchar(4000)
DECLARE @tagInfo nvarchar(1000)          
DECLARE @login nvarchar(32)          
DECLARE @returnValue int
DECLARE @lastList int
DECLARE @listName char(10)       -- holds the name of the deleted disaster code list
DECLARE @rowCount int            -- holds the number of rows in the Deleted table
DECLARE @error int          
DECLARE @cid int          
DECLARE @rv binary(8)

SET @rowCount = @@rowcount
IF @rowCount = 0 RETURN

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=T''
SET @tranName = object_name(@@procid) + CAST(trigger_nestlevel(@@procid) as nvarchar(2))

-- Get the spid info
SELECT @login = dbo.string$GetSpidLogin()
SELECT @tagInfo = dbo.string$GetSpidInfo()

-- Begin transaction
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

-- Get the caller login from the spidLogin table
IF len(dbo.string$GetSpidLogin()) = 0 BEGIN
   SET @msg = ''Caller login not found in spid login table.'' + @msgTag + ''>''
   EXECUTE error$raise @msg, 0, @tranName
   RETURN
END

SET @lastList = 0
WHILE 1 = 1 BEGIN
   SELECT TOP 1 @lastList = ListId,
          @listName = ListName
   FROM   Deleted
   WHERE  ListId > @lastList
   ORDER BY ListId ASC
   IF @@rowCount = 0 BREAK
   -- Set the audit message
   SELECT @msgUpdate = ''''
   IF CHARINDEX(''extract'',@tagInfo) > 0 BEGIN
      SELECT @msgUpdate = ''Disaster code list '' + @listName + '' dissolved''
   END
   ELSE IF CHARINDEX(''merge'',@tagInfo) > 0 BEGIN
      SELECT @msgUpdate = ''Disaster code list '' + @listName + '' deleted on merge''
   END
   ELSE IF CHARINDEX(''delete'',@tagInfo) > 0 BEGIN
      SELECT @msgUpdate = ''Disaster code list '' + @listName + '' deleted''
   END
   IF len(@msgUpdate) > 0 BEGIN
      INSERT XDisasterCodeList
      (
         Object, 
         Action, 
         Detail, 
         Login
      )
      VALUES
      (
         @listName, 
         3, 
         @msgUpdate, 
         @login
      )
      SET @error = @@error
      IF @error != 0 BEGIN
         ROLLBACK TRANSACTION @tranName
         COMMIT TRANSACTION
         SET @msg = ''Error inserting a row into the disaster code list audit table.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
         EXECUTE error$raise @msg, @error, @tranName
         RETURN
      END
   END
   -- If the list belonged to a composite, then if the composite still has active items, set its status.  If
   -- the composite has no other discrete lists, however, then delete the composite.
   SELECT @cid = isnull(CompositeId,-1)
   FROM   DisasterCodeList
   WHERE  ListId = @lastList
   IF @cid != -1 BEGIN
      -- Get the rowversion
      SELECT @rv = RowVersion
      FROM   Deleted
      WHERE  ListId = @cid
      -- Take appropriate action
      IF EXISTS
         (
         SELECT 1
         FROM   DisasterCodeListItem dli
         JOIN   DisasterCodeList dl
           ON   dl.ListId = dli.ListId
         WHERE  dli.Status != 1 AND dl.CompositeId = @cid
         )
      BEGIN
         EXECUTE @returnValue = disasterCodeList$setStatus @cid, @rv
         IF @returnValue = -100 BEGIN
            ROLLBACK TRANSACTION @tranName
            COMMIT TRANSACTION
            RETURN
         END
      END
      ELSE BEGIN
         EXECUTE @returnValue = disasterCodeList$del @cid, @rv
         IF @returnValue = -100 BEGIN
            ROLLBACK TRANSACTION @tranName
            COMMIT TRANSACTION
            RETURN
         END
      END
   END
END

COMMIT TRANSACTION
END
'
)

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'sealedCase$ins')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.sealedCase$ins
(
   @serialNo nvarchar(32),      -- serial number of the case
   @typeId int,                 -- type of case
   @returnDate datetime,        -- return date for case
   @notes nvarchar(4000),       -- any random information about the case
   @newId int OUTPUT            -- returns the id value for the newly created case
)
WITH ENCRYPTION
AS
BEGIN
DECLARE @msg as nvarchar(255)        -- used to preformat error message
DECLARE @msgTag as nvarchar(255)     -- used to hold first part of error message header
DECLARE @tranName as nvarchar(255)   -- used to hold name of savepoint
DECLARE @returnValue as int
DECLARE @error as int

SET NOCOUNT ON

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=P''
SET @tranName = object_name(@@procid) + CAST(@@nestlevel as nvarchar(2))

-- If the type id is incorrect, get the default
IF NOT EXISTS (SELECT 1 FROM MediumType WHERE TypeId = @typeId AND Container = 1) BEGIN
   EXECUTE @returnValue = barcodepatterncase$getdefaults @serialNo, @typeid out
   IF @returnValue != 0 RETURN -100
END

-- Insert the case record
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

INSERT SealedCase
(
   SerialNo, 
   TypeId,
   ReturnDate,
   HotStatus, 
   Notes
)
VALUES
(
   @serialNo,
   @typeId,
   @returnDate,
   0, 
   @notes
)

SET @error = @@error
IF @error != 0 BEGIN
   ROLLBACK TRANSACTION @tranName
   COMMIT TRANSACTION
   SET @msg = ''Error encountered while inserting a new sealed case.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
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
IF NOT EXISTS(SELECT 1 FROM DatabaseVersion WHERE Major = 1 AND Minor = 3 AND Revision = 3) BEGIN
   DECLARE @x nvarchar(1000)
   EXECUTE spidLogin$ins 'System', 'Insert database version'
   INSERT DatabaseVersion (Major, Minor, Revision) VALUES (1, 3, 3)
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
