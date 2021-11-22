-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
--
-- VaultLedger database update - version 1.4.1
--
-- Lloyds security update
--
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
SET NOCOUNT ON


IF dbo.bit$doScript('1.4.1') = 1

-- Upgrade RMMOperator to owner of database (RQMM ONLY)
IF EXISTS (SELECT 1 FROM sysusers WHERE name = 'RMMOperator') BEGIN

   IF NOT EXISTS
      (
      SELECT 1
      FROM   sysmembers 
      WHERE  memberuid = (SELECT uid FROM sysusers WHERE name = 'RMMOperator') AND groupuid = (SELECT uid FROM sysusers WHERE name = 'db_owner')
      )
   BEGIN
      EXECUTE sp_addrolemember @rolename = 'db_owner', @membername = 'RMMOperator'
   END

END
GO

-- Get all the accounts ... for each account that does not have a default, create one
IF dbo.bit$doScript('1.4.1') = 1
   IF INDEXPROPERTY(object_id('BarCodePattern'), 'akBarCodePattern$Pattern' , 'IndexId') IS NOT NULL
      IF INDEXPROPERTY(object_id('BarCodePattern'), 'akBarCodePattern$Pattern' , 'IsUnique') = 1
         EXECUTE ('ALTER TABLE BarCodePattern DROP CONSTRAINT akBarCodePattern$Pattern')
GO

IF dbo.bit$doScript('1.4.1') = 1
   IF INDEXPROPERTY(object_id('BarCodePattern'), 'akBarCodePattern$Pattern' , 'IndexId') IS NULL
      CREATE NONCLUSTERED INDEX akBarCodePattern$Pattern ON BarCodePattern (Pattern, AccountId) WITH FILLFACTOR = 80
GO

IF dbo.bit$doScript('1.4.1') = 1 BEGIN

DECLARE @a1 int
DECLARE @t1 int
DECLARE @p1 int
DECLARE @n1 nvarchar(1000)

SET @a1 = -1
SET @n1 = ''

SELECT TOP 1 @t1 = TypeId
FROM   BarCodePattern
WHERE  Pattern = '.*'
ORDER  BY PatId DESC
IF @@rowcount = 0 BEGIN
   SELECT TOP 1 @t1 = TypeId
   FROM   MediumType
   ORDER  BY 1 ASC
END

ALTER TABLE BarCodePattern DISABLE TRIGGER ALL

WHILE 1 = 1 BEGIN
   -- Get account
   SELECT TOP 1 @a1 = AccountId, 
          @n1 = AccountName
   FROM   Account
   WHERE  AccountName > @n1
   ORDER  BY 2 ASC
   IF @@rowcount = 0 BREAK
   -- Insert bar code pattern
   IF NOT EXISTS (SELECT 1 FROM BarCodePattern WHERE Pattern = '.*' AND AccountId = @a1) BEGIN
      -- Get position
      SELECT @p1 = coalesce(max(Position),0) + 1
      FROM   BarCodePattern
      -- Do insert
      INSERT BarCodePattern (Pattern, Position, TypeId, AccountId)
      VALUES ('.*', @p1, @t1, @a1)
   END   
END

ALTER TABLE BarCodePattern ENABLE TRIGGER ALL

END
GO

DECLARE @CREATE nvarchar(10)
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
--
-- Procedures / Triggers
--
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
IF dbo.bit$doScript('1.4.1') = 1 BEGIN

-------------------------------------------------------------------------------
--
-- Triggers : account$afterinsert
--
-------------------------------------------------------------------------------
IF EXISTS(SELECT * FROM sysobjects WHERE name = 'account$afterInsert' AND objectproperty(id, 'ExecIsInsertTrigger' ) = 1) 
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'TRIGGER account$afterInsert
ON     Account
--WITH ENCRYPTION
AFTER  INSERT
AS
BEGIN
DECLARE @msg nvarchar(255)        -- used to preformat error message
DECLARE @msgTag nvarchar(255)     -- used to hold first part of error message header
DECLARE @tranName nvarchar(255)   -- used to hold name of savepoint
DECLARE @account nvarchar(256)    -- name of added account
DECLARE @rowCount int             -- holds the number of rows in the Inserted table
DECLARE @error int            
DECLARE @t1 int

SET @rowCount = @@rowcount
IF @rowCount = 0 RETURN

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=T''
SET @tranName = object_name(@@procid) + CAST(trigger_nestlevel(@@procid) as nvarchar(2))

-- Begin transaction
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

-- Make sure we do not have a batch insert
IF @rowCount > 1 BEGIN
   SET @msg = ''Batch insert into account table not allowed.'' + @msgTag + ''>''
   EXECUTE error$raise @msg, 0, @tranName
   RETURN
END

-- Get the caller login from the spidLogin table
IF len(dbo.string$GetSpidLogin()) = 0 BEGIN
   SET @msg = ''No login found for auditing purposes.'' + @msgTag + ''>''
   EXECUTE error$raise @msg, 0, @tranName
   RETURN
END

-- Select the name of the new account from the Inserted table
SELECT @account = AccountName FROM Inserted

-- Insert audit record
INSERT XAccount
(
   Object, 
   Action, 
   Detail, 
   Login
)
VALUES
(
   @account, 
   1, 
   ''Account '' + @account + '' created'', 
   dbo.string$GetSpidLogin()
)

SET @error = @@error
IF @error != 0 BEGIN
   SET @msg = ''Error encountered while inserting an account audit record.'' + @msgTag + '';Error='' + cast(@error as nvarchar(10)) + ''>''
   EXECUTE error$raise @msg, @error, @tranName
   RETURN
END

-- Attach security to all administrator accounts
INSERT Operator$Account (Operator, Account)
SELECT o1.OperatorId, (SELECT AccountId FROM Inserted)
FROM   Operator o1
WHERE  o1.Role = 32768

-- Get type for inserting default bar code pattern
SELECT TOP 1 @t1 = TypeId
FROM   BarCodePattern
WHERE  Pattern = ''.*''
ORDER  BY PatId DESC
IF @@rowcount = 0 BEGIN
   SELECT TOP 1 @t1 = TypeId
   FROM   MediumType
   ORDER  BY 1 ASC
END

-- Insert default pattern
INSERT BarCodePattern(Pattern, Position, TypeId, AccountId)
SELECT ''.*'', coalesce(max(Position),0) + 1, @t1, (SELECT AccountId FROM Inserted)
FROM   BarCodePattern

-- Commit
COMMIT TRANSACTION

END
'
)

IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'account$del')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.account$del
(
   @id int,
   @rowVersion rowversion
)
WITH ENCRYPTION
AS
BEGIN
DECLARE @msg as nvarchar(255)        -- used to preformat error message
DECLARE @msgTag as nvarchar(255)     -- used to hold first part of error message header
DECLARE @tranName as nvarchar(255)   -- used to hold name of savepoint
DECLARE @listVersion as rowversion
DECLARE @patternString as nvarchar(4000)
DECLARE @accountName as nchar(256)
DECLARE @returnValue as int
DECLARE @listName as nchar(10)
DECLARE @rowCount as int
DECLARE @listId as int
DECLARE @patId as int
DECLARE @error as int
DECLARE @pos as int

SET NOCOUNT ON

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=P''
SET @tranName = object_name(@@procid) + CAST(@@nestlevel as nvarchar(2))

-- Get the account name
SELECT @accountName = AccountName
FROM   Account$View
WHERE  AccountId = @id
IF @@rowcount = 0 RETURN 0

-- If any bar code pattern uses this account, we cannot delete it
SELECT TOP 1 @patternString = b.Pattern, 
       @accountName = a.AccountName
FROM   BarCodePattern b
JOIN   Account a
  ON   a.AccountId = b.AccountId
WHERE  b.AccountId = @id
IF @@rowcount != 0 BEGIN
   SET @msg = ''Account '' + @accountName + '' may not be deleted because it is utilized by a bar code pattern ('' + @patternString + '').'' + @msgTag + ''>''
   EXECUTE error$raise @msg, @error
   RETURN -100
END

-- If any medium uses this account, we cannot delete it
IF EXISTS (SELECT 1 FROM Medium WHERE AccountId = @id) BEGIN
   SET @msg = ''Account '' + @accountName + '' may not be deleted because it is utilized by one or more media.'' + @msgTag + ''>''
   EXECUTE error$raise @msg, @error
   RETURN -100
END

-- If there are any active lists created under this account, we cannot delete it.
SELECT TOP 1 @listName = ListName
FROM  (SELECT TOP 1 ListName
       FROM   SendList
       WHERE  AccountId = @id AND Status != 512
       UNION  
       SELECT ListName
       FROM   ReceiveList
       WHERE  AccountId = @id AND Status != 512
       UNION  
       SELECT ListName
       FROM   DisasterCodeList
       WHERE  AccountId = @id AND Status != 512) as x
ORDER  BY ListName DESC
IF @@rowcount != 0 BEGIN
   SET @msg = ''Account '' + @accountName + '' may not be deleted because it is utilized by active list '' + @listName + ''.'' + @msgTag + ''>''
   EXECUTE error$raise @msg, @error
   RETURN -100
END

-- Begin transaction
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

-- Update the account record as deleted
UPDATE Account
SET    Deleted = 1
WHERE  AccountId = @id AND RowVersion = @rowVersion
SELECT @error = @@error, @rowCount = @@rowCount
IF @error != 0 BEGIN
   ROLLBACK TRANSACTION @tranName
   COMMIT TRANSACTION
   SET @msg = ''Error encountered while deleting account.'' + @msgTag + '';Error='' + cast(@error as nvarchar(10)) + ''>''
   EXECUTE error$raise @msg, @error
   RETURN -100
END
ELSE IF @rowCount = 0 BEGIN
   IF EXISTS(SELECT 1 FROM Account WHERE AccountId = @id) BEGIN
      ROLLBACK TRANSACTION @tranName
      COMMIT TRANSACTION
      SET @msg = ''Account has been modified since retrieval.'' + @msgTag + ''>''
      RAISERROR(@msg,16,1)
      RETURN -100
   END
   -- No notification if account does not exist.  It''s not a bad thing if
   -- we try to delete a record that does not exist.
END

-- Commit the transaction
COMMIT TRANSACTION
RETURN 0
END
'
)

IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'account$getbyid')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.account$getById
(
   @id int
)
WITH ENCRYPTION
AS
BEGIN

SET NOCOUNT ON

-- Select
SELECT a.AccountId,
       a.AccountName,
       a.Global,
       a.Address1,
       a.Address2,
       a.City,
       a.State,
       a.ZipCode,
       a.Country,
       a.Contact,
       a.PhoneNo,
       a.Email,
       a.Notes,
       isnull(ftp.ProfileName,'''') as ''FtpProfile'',
       a.RowVersion
FROM   Account$View a
LEFT JOIN
       (
       SELECT f1.ProfileName, f2.AccountId
       FROM   FtpProfile f1
       JOIN   FtpAccount f2
         ON   f2.ProfileId = f1.ProfileId
       ) AS ftp
  ON   ftp.AccountId = a.AccountId
WHERE  a.AccountId = @id AND a.Deleted = 0

END
'
)

IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'account$getbyname')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.account$getByName
(
   @name nvarchar(256)
)
WITH ENCRYPTION
AS
BEGIN

SET NOCOUNT ON

-- Select
SELECT a.AccountId,
       a.AccountName,
       a.Global,
       a.Address1,
       a.Address2,
       a.City,
       a.State,
       a.ZipCode,
       a.Country,
       a.Contact,
       a.PhoneNo,
       a.Email,
       a.Notes,
       isnull(ftp.ProfileName,'''') as ''FtpProfile'',
       a.RowVersion
FROM   Account$View a
LEFT JOIN
       (
       SELECT f1.ProfileName, f2.AccountId
       FROM   FtpProfile f1
       JOIN   FtpAccount f2
         ON   f2.ProfileId = f1.ProfileId
       ) AS ftp
  ON   ftp.AccountId = a.AccountId
WHERE  a.AccountName = @name AND Deleted = 0

END
'
)


IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'account$getcount')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.account$getCount
WITH ENCRYPTION
AS
BEGIN

SET NOCOUNT ON

SELECT count(*) 
FROM   Account
WHERE  Deleted = 0

END
'
)

IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'account$gettable')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.account$getTable
(
@filter bit = 1
)
WITH ENCRYPTION
AS
BEGIN

SET NOCOUNT ON

-- Select
IF @filter = 1 BEGIN
SELECT a.AccountId,
       a.AccountName,
       a.Global,
       a.Address1,
       a.Address2,
       a.City,
       a.State,
       a.ZipCode,
       a.Country,
       a.Contact,
       a.PhoneNo,
       a.Email,
       a.Notes,
       isnull(ftp.ProfileName,'''') as ''FtpProfile'',
       a.RowVersion
FROM   Account$View a
LEFT JOIN
       (
       SELECT f1.ProfileName, f2.AccountId
       FROM   FtpProfile f1
       JOIN   FtpAccount f2
         ON   f2.ProfileId = f1.ProfileId
       ) AS ftp
  ON   ftp.AccountId = a.AccountId
WHERE  a.Deleted = 0
ORDER BY a.AccountName Asc
END
ELSE BEGIN
SELECT a.AccountId,
       a.AccountName,
       a.Global,
       a.Address1,
       a.Address2,
       a.City,
       a.State,
       a.ZipCode,
       a.Country,
       a.Contact,
       a.PhoneNo,
       a.Email,
       a.Notes,
       isnull(ftp.ProfileName,'''') as ''FtpProfile'',
       a.RowVersion
FROM   Account a
LEFT JOIN
       (
       SELECT f1.ProfileName, f2.AccountId
       FROM   FtpProfile f1
       JOIN   FtpAccount f2
         ON   f2.ProfileId = f1.ProfileId
       ) AS ftp
  ON   ftp.AccountId = a.AccountId
WHERE  a.Deleted = 0
ORDER BY a.AccountName Asc
END

END
'
)

IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'disastercodelist$clear')
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
DECLARE @r1 binary(8)
DECLARE @rowNo int

SET NOCOUNT ON

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=P''
SET @tranName = object_name(@@procid) + CAST(@@nestlevel as nvarchar(2))

-- Get the list
SELECT @listName = ListName,
       @accountId = AccountId,
       @status = Status
FROM   DisasterCodeList$View
WHERE  ListId = @listId
IF @@rowcount = 0 BEGIN
   SET @msg = ''List not found.'' + @msgTag + ''>''
   RAISERROR(@msg,16,1)
   RETURN -100
END
ELSE IF NOT EXISTS (SELECT 1 FROM DisasterCodeList$View WHERE ListId = @listId AND RowVersion = @rowVersion) BEGIN
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
   -- Dissolve the list
   SELECT @r1 = RowVersion
   FROM   DisasterCodeList
   WHERE  ListId = @listId
   EXECUTE @returnValue = disasterCodeList$dissolve @listId, @r1
   IF @returnValue != 0 BEGIN
      ROLLBACK TRANSACTION @tranName
      COMMIT TRANSACTION
      RETURN -100
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

IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'disastercodelist$dissolve')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.disasterCodeList$dissolve
(
   @listId int,         -- id of the composite
   @listVersion rowversion
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
DECLARE @lastList int
DECLARE @returnValue as int
DECLARE @accountId as int
DECLARE @status as int

SET NOCOUNT ON

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=P''
SET @tranName = object_name(@@procid) + CAST(@@nestlevel as nvarchar(2))

-- Check concurrency of composite, and verify that it actually is a composite
SELECT @listName = ListName,
       @accountId = AccountId,
       @status = Status
FROM   DisasterCodeList$View 
WHERE  ListId = @listId AND RowVersion = @listVersion
IF @@rowCount = 0 BEGIN
   IF EXISTS (SELECT 1 FROM DisasterCodeList$View WHERE ListId = @listId) BEGIN
      SET @msg = ''List has been modified since retrieval.'' + @msgTag + ''>''
      RAISERROR(@msg,16,1)
      RETURN -100
   END
   ELSE BEGIN
      SET @msg = ''List not found.'' + @msgTag + ''>''
      RAISERROR(@msg,16,1)
      RETURN -100
   END
END

-- Begin the transaction
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

-- Update all the discretes to have no composite.  This will cause the list
-- composite to be deleted in the trigger.
SET @lastList = 0
WHILE 1 = 1 BEGIN
   SELECT TOP 1 @lastList = ListId
   FROM   DisasterCodeList
   WHERE  CompositeId = @listId AND
          ListId > @lastList
   ORDER BY ListId ASC
   IF @@rowCount = 0 BEGIN
      BREAK
   END
   ELSE BEGIN
      UPDATE DisasterCodeList
      SET    CompositeId = NULL
      WHERE  ListId = @lastList
      SET @error = @@error
      IF @error != 0 BEGIN
         ROLLBACK TRANSACTION @tranName
         COMMIT TRANSACTION
         SET @msg = ''Error encountered while dissolving composite disaster code list.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
         EXECUTE error$raise @msg, @error
         RETURN -100
      END
   END
END

-- Commit the transaction
COMMIT TRANSACTION
RETURN 0
END
'
)

IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'disastercodelist$extract')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.disasterCodeList$extract
(
   @listId int,              -- id of the list to be extracted
   @listVersion rowversion,
   @compositeId int,         -- id of the composite
   @compositeVersion rowversion
)
WITH ENCRYPTION
AS
BEGIN
DECLARE @msg as nvarchar(255)        -- used to preformat error message
DECLARE @msgTag as nvarchar(255)     -- used to hold first part of error message header
DECLARE @tranName as nvarchar(255)   -- used to hold name of savepoint
DECLARE @caseName as nvarchar(128)
DECLARE @accountId as int
DECLARE @rowCount as int
DECLARE @error as int
DECLARE @listName as nchar(10)
DECLARE @compositeName as nchar(10)
DECLARE @returnValue as int
DECLARE @status as int
DECLARE @cid as int

SET NOCOUNT ON

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=P''
SET @tranName = object_name(@@procid) + CAST(@@nestlevel as nvarchar(2))

-- Check concurrency of composite, and verify that it actually is a composite
SELECT @compositeName = ListName,
       @accountId = AccountId,
       @status = Status
FROM   DisasterCodeList$View 
WHERE  ListId = @compositeId AND RowVersion = @compositeVersion
IF @@rowCount = 0 BEGIN
   IF EXISTS (SELECT 1 FROM DisasterCodeList$View WHERE ListId = @compositeId) BEGIN
      SET @msg = ''List has been modified since retrieval.'' + @msgTag + ''>''
      RAISERROR(@msg,16,1)
      RETURN -100
   END
   ELSE BEGIN
      SET @msg = ''List not found.'' + @msgTag + ''>''
      RAISERROR(@msg,16,1)
      RETURN -100
   END
END
ELSE IF @accountId IS NOT NULL BEGIN
   SET @msg = ''List '' + @compositeName + '' is not a composite list.'' + @msgTag + ''>''
   RAISERROR(@msg,16,1)
   RETURN -100
END

-- Check concurrency of discrete, and verify that it actually belongs to the composite
SELECT @listName = ListName,
       @cid = isnull(CompositeId,0),
       @status = Status
FROM   DisasterCodeList$View 
WHERE  ListId = @listId AND RowVersion = @listVersion
IF @@rowCount = 0 BEGIN
   IF EXISTS (SELECT 1 FROM DisasterCodeList$View WHERE ListId = @listId) BEGIN
      SET @msg = ''List has been modified since retrieval.'' + @msgTag + ''>''
      RAISERROR(@msg,16,1)
      RETURN -100
   END
   ELSE BEGIN
      SET @msg = ''List not found.'' + @msgTag + ''>''
      RAISERROR(@msg,16,1)
      RETURN -100
   END
END
ELSE IF @cid != @compositeId BEGIN
   SET @msg = ''Disaster code list '''''' + @listName + '''''' is not part of composite list '''''' + @compositeName + ''''''.'' + @msgTag + ''>''
   RAISERROR(@msg,16,1)
   RETURN -100
END

-- Begin the transaction
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

-- Remove the discrete from the composite
UPDATE DisasterCodeList
SET    CompositeId = NULL
WHERE  ListId = @listId
SET @error = @@error
IF @error != 0 BEGIN
   ROLLBACK TRANSACTION @tranName
   COMMIT TRANSACTION
   SET @msg = ''Error encountered while extracting disaster code list.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
   EXECUTE error$raise @msg, @error
   RETURN -100
END

-- If there are no discretes left in the composite, the composite will have
-- been deleted in the trigger.  No need to delete it here, so just commit
-- and return.

-- Commit and return
COMMIT TRANSACTION
RETURN 0
END
'
)

IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'disastercodelist$getbydate')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.disasterCodeList$getByDate
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
FROM   DisasterCodeList$View dl
JOIN   Account a    -- view not necessary
  ON   a.AccountId = dl.AccountId
WHERE  CompositeId IS NULL AND
       convert(nchar(10),dl.CreateDate,120) = @dateString
UNION
SELECT dl.ListId,
       dl.ListName,
       dl.CreateDate,
       dl.Status,
       '''',
       dl.RowVersion
FROM   DisasterCodeList$View dl
WHERE  AccountId IS NULL AND
       EXISTS(SELECT 1 
              FROM   DisasterCodeList$View dl2
              WHERE  CompositeId = dl.ListId AND
                     convert(nchar(10),dl2.CreateDate,120) = @dateString)
ORDER BY ListName Desc

END
'
)

IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'disastercodelist$getbyid')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE disasterCodeList$getById
(
   @id int
)
WITH ENCRYPTION
AS
BEGIN

SET NOCOUNT ON

-- Select the list
SELECT dl.ListId,
       dl.ListName,
       dl.CreateDate,
       dl.Status,
       coalesce(a.AccountName,'''') as ''AccountName'',
       dl.RowVersion
FROM   DisasterCodeList$View dl
LEFT OUTER JOIN Account a -- view not necessary
  ON   a.AccountId = dl.AccountId
WHERE  dl.ListId = @id

-- If the list is a composite then get the child lists as well
IF EXISTS(SELECT 1 FROM DisasterCodeList WHERE CompositeId = @id) BEGIN
   SELECT dl.ListId,
          dl.ListName,
          dl.CreateDate,
          dl.Status,
          a.AccountName,
          dl.RowVersion
   FROM   DisasterCodeList$View dl
   JOIN   Account a  -- view not necessary
     ON   a.AccountId = dl.AccountId
   WHERE  dl.CompositeId = @id
   ORDER BY dl.ListName
END

END
'
)

IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'disastercodelist$getbyname')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.disasterCodeList$getByName
(
   @listName nchar(10)
)
WITH ENCRYPTION
AS
BEGIN
DECLARE @id int

SET NOCOUNT ON

-- Select the list
SELECT dl.ListId,
       dl.ListName,
       dl.CreateDate,
       dl.Status,
       coalesce(a.AccountName,'''') as ''AccountName'',
       dl.RowVersion
FROM   DisasterCodeList$View dl
LEFT   JOIN Account a -- view not necessary
  ON   a.AccountId = dl.AccountId
WHERE  dl.ListName = @listName

-- If the list is a composite then get the child lists as well
SELECT @id = ListId 
FROM   DisasterCodeList 
WHERE  ListName = @listName

IF EXISTS(SELECT 1 FROM DisasterCodeList WHERE CompositeId = @id) BEGIN
   SELECT dl.ListId,
          dl.ListName,
          dl.CreateDate,
          dl.Status,
          a.AccountName,
          dl.RowVersion
   FROM   DisasterCodeList$View dl
   JOIN   Account a -- view not necessary
     ON   a.AccountId = dl.AccountId
   WHERE  dl.CompositeId = @id
   ORDER BY dl.ListName
END

END
'
)

IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'disastercodelist$getcleared')
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
FROM   DisasterCodeList$View dl
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
FROM   DisasterCodeList$View dl
WITH  (NOLOCK)
WHERE  dl.Status = 512 AND
       dl.AccountId IS NULL AND
       EXISTS(SELECT 1 
              FROM   DisasterCodeList$View dl2
              WITH  (NOLOCK)
              WHERE  CompositeId = dl.ListId AND
                     convert(nchar(10),dl2.CreateDate,120) <= @dateString)
ORDER BY ListName Asc
END
'
)

IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'disastercodelist$getitemcount')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.disasterCodeList$getItemCount
(
   @listId int,
   @status int -- -1 = all items, else a certain status
)
WITH ENCRYPTION
AS
BEGIN

SET NOCOUNT ON

-- Select the items on list
IF @status = -1 BEGIN
   SELECT count(*)
   FROM   DisasterCodeListItem dli
   JOIN   DisasterCodeList$View dl
     ON   dl.ListId = dli.ListId
   WHERE  dli.Status != 1 AND -- power(4,x)
         (dl.ListId = @listId OR dl.CompositeId = @listId)
END
ELSE BEGIN
   SELECT count(*)
   FROM   DisasterCodeListItem dli
   JOIN   DisasterCodeList$View dl
     ON   dl.ListId = dli.ListId
   WHERE  dli.Status = @status AND
         (dl.ListId = @listId OR dl.CompositeId = @listId)
END

END
'
)

IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'disastercodelist$getitems')
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
FROM   DisasterCodeList$View dl
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

IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'disastercodelist$getpage')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.disasterCodeList$getPage
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
DECLARE @x1 nvarchar(1000)   -- List name
DECLARE @x2 nvarchar(1000)   -- Create date
DECLARE @x3 nvarchar(1000)   -- Status
DECLARE @x4 nvarchar(1000)   -- Account
DECLARE @s nvarchar(4000)
DECLARE @topSize int
DECLARE @display int
DECLARE @count int
DECLARE @error int
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
   SET @order1 = '' ORDER BY dl.ListName desc''
   SET @order2 = '' ORDER BY ListName asc''
   SET @order3 = '' ORDER BY ListName desc''
END
ELSE IF @sort = 2 BEGIN
   SET @order1 = '' ORDER BY dl.CreateDate desc, dl.ListName desc''
   SET @order2 = '' ORDER BY CreateDate asc, ListName asc''
   SET @order3 = '' ORDER BY CreateDate desc, ListName desc''
END
ELSE IF @sort = 3 BEGIN
   SET @order1 = '' ORDER BY dl.Status asc, dl.ListName desc''
   SET @order2 = '' ORDER BY Status desc, ListName asc''
   SET @order3 = '' ORDER BY Status asc, ListName desc''
END
ELSE IF @sort = 4 BEGIN
   SET @order1 = '' ORDER BY a.AccountName asc, dl.ListName desc''
   SET @order2 = '' ORDER BY AccountName desc, ListName asc''
   SET @order3 = '' ORDER BY AccountName asc, ListName desc''
END
ELSE BEGIN
   SET @msg = ''Invalid sort order.'' + @msgTag + ''>''
   RAISERROR(@msg,16,1)
   RETURN -100
END

-- Construct the where clause
SET @where = '' WHERE dl.CompositeId IS NULL ''   -- Get only the top level lists
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
      SET @where = @where + '' AND (dl.'' + left(@s, charindex(''='',@s) + 1) + '' @x1$)''
      SET @x1 = replace(ltrim(substring(@s, charindex(''='',@s) + 1, 4000)), '''''''', '''')
   END
   ELSE IF charindex(''CreateDate ='', @s) = 1 BEGIN
      SET @where = @where + '' AND ('' + replace(left(@s, charindex(''='',@s) + 1),''CreateDate'',''coalesce(convert(nvarchar(10),dl.CreateDate,120),'''''''')'') + '' @x2$)''
      SET @x2 = replace(ltrim(substring(@s, charindex(''='',@s) + 1, 4000)), '''''''', '''')
   END
   ELSE IF charindex(''Status ='', @s) = 1 BEGIN
      SET @where = @where + '' AND (dl.'' + left(@s, charindex(''='',@s) + 1) + '' @x3$)''
      SET @x3 = replace(ltrim(substring(@s, charindex(''='',@s) + 1, 4000)), '''''''', '''')
   END
   ELSE IF charindex(''AccountName ='', @s) = 1 BEGIN
      SET @where = @where + '' AND ('' + replace(left(@s, charindex(''='',@s) + 1),''AccountName'',''coalesce(a.AccountName,'''''''')'') + '' @x4$)''
      SET @x4 = replace(ltrim(substring(@s, charindex(''='',@s) + 1, 4000)), '''''''', '''')
   END
   ELSE BEGIN
      SET @msg = ''Error occurred while selecting page of disaster recovery lists.  Invalid filter supplied.'' + @msgTag + ''>''
      EXECUTE error$raise @msg
      RETURN -100
   END
END

-- Construct the fields string
SET @fields2 = ''ListId, ListName, CreateDate, Status, AccountName, RowVersion''
SET @fields1 = ''dl.ListId, dl.ListName, dl.CreateDate, dl.Status, coalesce(a.AccountName,'''''''') as ''''AccountName'''', dl.RowVersion''

-- Construct the tables string
SET @tables = ''DisasterCodeList$View dl LEFT OUTER JOIN Account a ON dl.AccountId = a.AccountId''

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

IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'disastercodelist$merge')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.disasterCodeList$merge
(
   @listId1 int,
   @rowVersion1 rowVersion,
   @listId2 int,
   @rowVersion2 rowVersion,
   @compositeId int OUTPUT     -- id of composite list
)
WITH ENCRYPTION
AS
BEGIN
DECLARE @msg as nvarchar(255)        -- used to preformat error message
DECLARE @msgTag as nvarchar(255)     -- used to hold first part of error message header
DECLARE @tranName as nvarchar(255)   -- used to hold name of savepoint
DECLARE @rowCount as int
DECLARE @error as int
DECLARE @accountId1 as int
DECLARE @accountId2 as int
DECLARE @status1 as int
DECLARE @status2 as int
DECLARE @listName1 as nchar(10)
DECLARE @listName2 as nchar(10)
DECLARE @returnValue as int
DECLARE @checkVersion as rowversion
DECLARE @compositeName as nchar(10)
DECLARE @cid as int

SET NOCOUNT ON

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=P''
SET @tranName = object_name(@@procid) + CAST(@@nestlevel as nvarchar(2))

-- Get the name of the first list and test its concurrency.  Also make sure
-- that it is not a discrete list currently belonging to another composite.
SELECT @status1 = Status,
       @listName1 = ListName,
       @accountId1 = AccountId,
       @checkVersion = RowVersion,
       @cid = CompositeId
FROM   DisasterCodeList$View
WHERE  ListId = @listId1
IF @@rowCount = 0 BEGIN
   SET @msg = ''List not found.'' + @msgTag + ''>''
   RAISERROR(@msg,16,1)
   RETURN -100
END
ELSE IF @checkVersion != @rowVersion1 BEGIN
   SET @msg = ''Disaster code list '''''' + @listName1 + '''''' has been modified since retrieval.'' + @msgTag + ''>''
   RAISERROR(@msg,16,1)
   RETURN -100
END
ELSE IF @cid IS NOT NULL BEGIN
   SET @msg = ''List '''''' + @listName1 + '''''' must first be extracted from its current composite.'' + @msgTag + ''>''
   RAISERROR(@msg,16,1)
   RETURN -100
END

-- Get the name of the second list and test its concurrency.  Also make sure
-- that it is not a discrete list currently belonging to another composite.
SELECT @status2 = Status,
       @listName2 = ListName,
       @accountId2 = AccountId,
       @checkVersion = RowVersion,
       @cid = CompositeId
FROM   DisasterCodeList$View 
WHERE  ListId = @listId2
IF @@rowCount = 0 BEGIN
   SET @msg = ''List not found.'' + @msgTag + ''>''
   RAISERROR(@msg,16,1)
   RETURN -100
END
ELSE IF @checkVersion != @rowVersion2 BEGIN
   SET @msg = ''Disaster code list '''''' + @listName2 + '''''' has been modified since retrieval.'' + @msgTag + ''>''
   RAISERROR(@msg,16,1)
   RETURN -100
END
ELSE IF @cid IS NOT NULL BEGIN
   SET @msg = ''List '''''' + @listName2 + '''''' must first be extracted from its current composite.'' + @msgTag + ''>''
   RAISERROR(@msg,16,1)
   RETURN -100
END

-- There are three possibilites.  Either we have (a) two discrete lists, or
-- (b) two composite lists, or (c) one of each.  In case (a) we create a new 
-- composite list and attach the two discretes to it.  In case (b) we take
-- all of the discrete lists from the list with the lower number, move
-- them into the other composite, and delete the now empty composite.  In
-- case (c) we merge the discrete into the existing composite.

-- Begin the transaction
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

-- If we have two discrete lists, create a composite and merge the two
-- discrete lists into it.
IF @accountId1 IS NOT NULL AND @accountId2 IS NOT NULL BEGIN
   -- Create the composite send list
   EXEC @returnValue = disasterCodeList$create NULL, @compositeName OUT
   IF @returnValue != 0 BEGIN
      ROLLBACK TRANSACTION @tranName
      COMMIT TRANSACTION
      RETURN -100
   END
   ELSE BEGIN
      SELECT @compositeId = ListId
      FROM   DisasterCodeList
      WHERE  ListName = @compositeName
   END
   -- Assign the the two discretes to the new composite
   UPDATE DisasterCodeList
   SET    CompositeId = @compositeId
   WHERE  ListId = @listId1 OR ListId = @listId2
   SET @error = @@error
   IF @error != 0 BEGIN
      ROLLBACK TRANSACTION @tranName
      COMMIT TRANSACTION
      SET @msg = ''Error encountered while merging lists into composite.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
      EXECUTE error$raise @msg, @error
      RETURN -100
   END 
END
-- If we have two composites, move all the discrete that belong to the 
-- lower numbered composite to the higher numbered composite.  Then
-- delete the lower numbered composite.
ELSE IF @accountId1 IS NULL AND @accountId2 IS NULL BEGIN
   -- Get the id of the surviving composite
   SELECT @compositeId = dbo.int$max(@listId1,@listId2)
   -- Take all the discretes from the lower and assign to the higher
   UPDATE DisasterCodeList
   SET    CompositeId = @compositeId
   WHERE  CompositeId = dbo.int$min(@listId1,@listId2)
   SET @error = @@error
   IF @error != 0 BEGIN
      ROLLBACK TRANSACTION @tranName
      COMMIT TRANSACTION
      SET @msg = ''Error encountered while merging lists from two composite disaster code lists.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
      EXECUTE error$raise @msg, @error
      RETURN -100
   END 
   -- Delete the now empty composite list record
   IF @listId1 < @listId2
      EXECUTE @returnValue = disasterCodeList$del @listId1, @rowVersion1
   ELSE
      EXECUTE @returnValue = disasterCodeList$del @listId2, @rowVersion2
   IF @returnValue != 0 BEGIN
      ROLLBACK TRANSACTION @tranName
      COMMIT TRANSACTION
      RETURN -100
   END 
END
-- If we have one discrete and one composite, merge the discrete
-- into the composite.
ELSE BEGIN
   SELECT @compositeId = ListId
   FROM   DisasterCodeList 
   WHERE  AccountId IS NULL AND 
          ListId  = @listId1 OR ListId = @listId2
   UPDATE DisasterCodeList
   SET    CompositeId = @compositeId
   WHERE  ListId IN (@listId2, @listId2) AND ListId != @compositeId
   SET @error = @@error
   IF @error != 0 BEGIN
      ROLLBACK TRANSACTION @tranName
      COMMIT TRANSACTION
      SET @msg = ''Error encountered while merging a discrete disaster code list into an existing composite.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
      EXECUTE error$raise @msg, @error
      RETURN -100
   END 
END

-- We do not have to update the status of the composite list (like we do
-- with send lists) because the lists could only be merged in the first
-- place if they were both of submitted status.

-- Commit the transaction
COMMIT TRANSACTION
RETURN 0
END
'
)

IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'disastercodelist$transmit')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.disasterCodeList$transmit
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
DECLARE @listName nchar(10)
DECLARE @lock rowversion
DECLARE @lastItem int
DECLARE @rowCount int
DECLARE @status int
DECLARE @error int

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=P''
SET @tranName = object_name(@@procid) + CAST(@@nestlevel as nvarchar(2))

-- If the status of the list is already transmitted, then return.  Otherwise,
-- if it is anything besides submitted, return.
SELECT @listName = ListName,
       @status = Status,
       @lock = RowVersion
FROM   DisasterCodeList$View
WHERE  ListId = @listId
IF @@rowCount = 0 BEGIN
   SET @msg = ''Disaster code list item not found.'' + @msgTag + ''>''
   RAISERROR(@msg,16,1)
   RETURN -100
END
ELSE IF @lock != @rowVersion BEGIN
   SET @msg = ''List '' + @listName + '' has been modified since retrieval.'' + @msgTag + ''>''
   RAISERROR(@msg,16,1)
   RETURN -100
END

-- If already transmitted, just return
IF @status >= 4 RETURN 0

-- Upgrade the status of all the unremoved items on the list to transmitted
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

IF EXISTS (SELECT 1 FROM DisasterCodeList WHERE CompositeId = @listId) BEGIN
   UPDATE DisasterCodeListItem
   SET    Status = 4
   WHERE  Status != 1 AND ListId = (SELECT ListId FROM DisasterCodeList WHERE CompositeId = @listId)
END
ELSE BEGIN
   UPDATE DisasterCodeListItem
   SET    Status = 4
   WHERE  Status != 1 AND ListId = @listId
END
SET @error = @@error
IF @error != 0 BEGIN
   ROLLBACK TRANSACTION @tranName
   COMMIT TRANSACTION
   SET @msg = ''Error encountered while upgrading disaster code list items to transmitted.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
   EXECUTE error$raise @msg, @error
   RETURN -100
END

-- Commit and return
COMMIT TRANSACTION
RETURN 0
END
'
)

IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'disastercodelistitem$add')
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
FROM   DisasterCodeList$View
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

IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'disastercodelistitem$get')
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
JOIN   Medium$View m
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

IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'disastercodelistitem$getpage')
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
SET @tables = ''DisasterCodeListItem dli JOIN DisasterCodeList$View dl ON dl.ListId = dli.ListId JOIN Medium m ON m.MediumId = dli.MediumId JOIN Account a ON a.AccountId = m.AccountId LEFT JOIN (SELECT c1.Serialno, mc1.MediumId FROM SealedCase c1 JOIN MediumSealedCase mc1 ON mc1.CaseId = c1.CaseId) as c ON c.MediumId = m.MediumId''

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

IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'medium$getbycase')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.medium$getByCase
(
   @caseName nvarchar(32)
)
WITH ENCRYPTION
AS
BEGIN

SET NOCOUNT ON

SELECT m.MediumId, 
       m.SerialNo, 
       m.Location, 
       m.HotStatus, 
       coalesce(convert(nvarchar(10),sc.ReturnDate,120),'''') as ''ReturnDate'',
       m.Missing, 
       coalesce(convert(nvarchar(19),m.LastMoveDate,120),'''') as ''LastMoveDate'',
       m.BSide, 
       m.Notes,
       a.AccountName, 
       t.TypeName, 
       sc.SerialNo as ''CaseName'', 
       m.RowVersion
FROM   Medium$View m 
JOIN   Account a 
  ON   a.AccountId = m.AccountId 
JOIN   MediumType t 
  ON   t.TypeId = m.TypeId 
JOIN   MediumSealedCase msc
  ON   msc.MediumId = m.MediumId
JOIN   SealedCase sc
  ON   msc.CaseId = sc.CaseId
WHERE  sc.SerialNo = @caseName
ORDER BY m.SerialNo Asc

END
'
)

IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'medium$getbycase')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.medium$getById
(
   @id int
)
WITH ENCRYPTION
AS
BEGIN

SET NOCOUNT ON

SELECT m.MediumId, 
       m.SerialNo, 
       m.Location, 
       m.HotStatus, 
       case len(coalesce(c.CaseName,''''))
          when 0 then coalesce(convert(nvarchar(10),m.ReturnDate,120),'''')
          else coalesce(convert(nvarchar(10),c.ReturnDate,120),'''')
       end as ''ReturnDate'',
       m.Missing, 
       coalesce(convert(nvarchar(19),m.LastMoveDate,120),'''') as ''LastMoveDate'',
       m.BSide, 
       m.Notes,
       a.AccountName, 
       t.TypeName, 
       coalesce(c.CaseName,'''') as ''CaseName'', 
       m.RowVersion
FROM   Medium$View m 
JOIN   Account a 
  ON   a.AccountId = m.AccountId 
JOIN   MediumType t 
  ON   t.TypeId = m.TypeId 
LEFT OUTER JOIN 
      (
      SELECT sc.SerialNo as ''CaseName'',
             msc.MediumId as ''MediumId'',
             sc.ReturnDate as ''ReturnDate''
      FROM   SealedCase sc 
      JOIN   MediumSealedCase msc 
        ON msc.CaseId = sc.CaseId 
      ) 
      AS c 
  ON  c.MediumId = m.MediumId
WHERE m.MediumId = @id

END
'
)

IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'medium$getbyserialno')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.medium$getBySerialNo
(
   @serialNo nvarchar(32)
)
WITH ENCRYPTION
AS
BEGIN

SET NOCOUNT ON

SELECT m.MediumId, 
       m.SerialNo, 
       m.Location, 
       m.HotStatus, 
       case len(coalesce(c.CaseName,''''))
          when 0 then coalesce(convert(nvarchar(10),m.ReturnDate,120),'''')
          else coalesce(convert(nvarchar(10),c.ReturnDate,120),'''')
       end as ''ReturnDate'',
       m.Missing, 
       coalesce(convert(nvarchar(19),m.LastMoveDate,120),'''') as ''LastMoveDate'',
       m.BSide,
       m.Notes,
       a.AccountName, 
       t.TypeName, 
       coalesce(c.CaseName,'''') as ''CaseName'', 
       m.RowVersion
FROM   Medium$View m 
JOIN   Account a 
  ON   a.AccountId = m.AccountId 
JOIN   MediumType t 
  ON   t.TypeId = m.TypeId 
LEFT OUTER JOIN 
      (
      SELECT sc.SerialNo as ''CaseName'', 
             msc.MediumId as ''MediumId'',
             sc.ReturnDate as ''ReturnDate''
      FROM   SealedCase sc 
      JOIN   MediumSealedCase msc 
        ON msc.CaseId = sc.CaseId 
      ) 
      AS c 
  ON  c.MediumId = m.MediumId
WHERE m.SerialNo = @serialNo

END
'
)

IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'medium$getpage')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.medium$getPage
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
DECLARE @x1 nvarchar(4000)   -- Serial number start
DECLARE @x2 nvarchar(4000)   -- Serial number end
DECLARE @x3 nvarchar(4000)   -- Return Date
DECLARE @x4 nvarchar(4000)   -- Account
DECLARE @x5 nvarchar(4000)   -- Medium type
DECLARE @x6 nvarchar(4000)   -- Case name
DECLARE @x7 nvarchar(4000)   -- Notes
DECLARE @x8 nvarchar(4000)   -- Disaster code
DECLARE @y0 nvarchar(4000)   -- Serial numbers when multiple wildcard strings
DECLARE @y1 nvarchar(4000)
DECLARE @y2 nvarchar(4000)
DECLARE @y3 nvarchar(4000)
DECLARE @y4 nvarchar(4000)
DECLARE @y5 nvarchar(4000)
DECLARE @y6 nvarchar(4000)
DECLARE @y7 nvarchar(4000)
DECLARE @y8 nvarchar(4000)
DECLARE @y9 nvarchar(4000)
DECLARE @s nvarchar(4000)
DECLARE @p int
DECLARE @i int
DECLARE @s1 nvarchar(4000)
DECLARE @p1 int

SET NOCOUNT ON

-- Set the message tag
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=P''

-- Initialize
IF @pageNo < 1 SET @pageNo = 1
SELECT @i = 0, @p = -1, @p1 = -1

-- Declare the parameter string
SET @var = ''@x1$ nvarchar(1000), @x2$ nvarchar(1000)''
SET @var = @var + '', @x3$ nvarchar(1000), @x4$ nvarchar(1000), @x5$ nvarchar(1000), @x6$ nvarchar(1000), @x7$ nvarchar(1000), @x8$ nvarchar(1000)''
SET @var = @var + '', @y0$ nvarchar(1000), @y1$ nvarchar(1000), @y2$ nvarchar(1000), @y3$ nvarchar(1000), @y4$ nvarchar(1000)''
SET @var = @var + '', @y5$ nvarchar(1000), @y6$ nvarchar(1000), @y7$ nvarchar(1000), @y8$ nvarchar(1000), @y9$ nvarchar(1000)''

-- Set the order clauses
IF @sort = 1 BEGIN
   SET @order1 = '' ORDER BY m.SerialNo asc''
   SET @order2 = '' ORDER BY SerialNo desc''
   SET @order3 = '' ORDER BY SerialNo asc''
END
ELSE IF @sort = 2 BEGIN
   SET @order1 = '' ORDER BY m.Location desc, m.SerialNo asc'' -- Location is descending because 0 = Vault and 1 = Local (opposite order alphabetically)
   SET @order2 = '' ORDER BY Location asc, SerialNo desc''
   SET @order3 = '' ORDER BY Location desc, SerialNo asc''
END
ELSE IF @sort = 3 BEGIN
   SET @order1 = '' ORDER BY ReturnDate asc, m.SerialNo asc''
   SET @order2 = '' ORDER BY ReturnDate desc, SerialNo desc''
   SET @order3 = '' ORDER BY ReturnDate asc, SerialNo asc''
END
ELSE IF @sort = 4 BEGIN
   SET @order1 = '' ORDER BY m.Missing asc, m.SerialNo asc''
   SET @order2 = '' ORDER BY Missing desc, SerialNo desc''
   SET @order3 = '' ORDER BY Missing asc, SerialNo asc''
END
ELSE IF @sort = 5 BEGIN
   SET @order1 = '' ORDER BY LastMoveDate asc, m.SerialNo asc''
   SET @order2 = '' ORDER BY LastMoveDate desc, SerialNo desc''
   SET @order3 = '' ORDER BY LastMoveDate asc, SerialNo asc''
END
ELSE IF @sort = 6 BEGIN
   SET @order1 = '' ORDER BY a.AccountName asc, m.SerialNo asc''
   SET @order2 = '' ORDER BY AccountName desc, SerialNo desc''
   SET @order3 = '' ORDER BY AccountName asc, SerialNo asc''
END
ELSE IF @sort = 7 BEGIN
   SET @order1 = '' ORDER BY t.TypeName asc, m.SerialNo asc''
   SET @order2 = '' ORDER BY TypeName desc, SerialNo desc''
   SET @order3 = '' ORDER BY TypeName asc, SerialNo asc''
END
ELSE IF @sort = 8 BEGIN
   SET @order1 = '' ORDER BY CaseName asc, m.SerialNo asc''
   SET @order2 = '' ORDER BY CaseName desc, SerialNo desc''
   SET @order3 = '' ORDER BY CaseName asc, SerialNo asc''
END
ELSE IF @sort = 9 BEGIN
   SET @order1 = '' ORDER BY m.Notes asc, m.SerialNo asc'' 
   SET @order2 = '' ORDER BY Notes desc, SerialNo desc'' 
   SET @order3 = '' ORDER BY Notes asc, SerialNo asc'' 
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
   IF charindex(''SerialNo ='', @s) = 1 or charindex(''SerialNo >='', @s) = 1 BEGIN
      SET @where = @where + '' AND (m.'' + left(@s, charindex(''='',@s) + 1) + '' @x1$)''
      SET @x1 = replace(ltrim(substring(@s, charindex(''='',@s) + 1, 4000)), '''''''', '''')
   END
   ELSE IF charindex(''SerialNo <='', @s) = 1 BEGIN
      SET @where = @where + '' AND (m.'' + left(@s, charindex(''='',@s) + 1) + '' @x2$)''
      SET @x2 = replace(ltrim(substring(@s, charindex(''='',@s) + 1, 4000)), '''''''', '''')
   END
   ELSE IF charindex(''Location ='', @s) = 1 BEGIN
      SET @where = @where + '' AND (m.'' + @s + '')''
   END
   ELSE IF charindex(''convert(nvarchar(10),ReturnDate,120)'', @s) = 1 BEGIN   -- Obsolete
      SET @where = @where + '' AND ('' + replace(left(@s, charindex(''='',@s) + 1),''ReturnDate'',''case len(coalesce(convert(nvarchar(10),c.ReturnDate,120),'''''''')) when 0 then coalesce(convert(nvarchar(10),m.ReturnDate,120),'''''''') else coalesce(convert(nvarchar(10),c.ReturnDate,120),'''''''') end'') + '' @x3$)''
      SET @x3 = replace(ltrim(substring(@s, charindex(''='',@s) + 1, 4000)), '''''''', '''')
   END
   ELSE IF charindex(''ReturnDate ='', @s) = 1 BEGIN
      SET @where = @where + '' AND ('' + replace(left(@s, charindex(''='',@s) + 1),''ReturnDate'',''convert(nvarchar(10),case len(coalesce(convert(nvarchar(10),c.ReturnDate,120),'''''''')) when 0 then coalesce(convert(nvarchar(10),m.ReturnDate,120),'''''''') else coalesce(convert(nvarchar(10),c.ReturnDate,120),'''''''') end,120)'') + '' @x3$)''
      SET @x3 = replace(ltrim(substring(@s, charindex(''='',@s) + 1, 4000)), '''''''', '''')
   END
   ELSE IF charindex(''Missing ='', @s) = 1 BEGIN
      SET @where = @where + '' AND (m.'' + @s + '')''
   END
   ELSE IF charindex(''LastMoveDate ='', @s) = 1 BEGIN
      SET @where = @where + '' AND ('' + replace(@s,''LastMoveDate'',''coalesce(convert(nvarchar(10),m.LastMoveDate,120),'''''''')'') + '')''
   END
   ELSE IF charindex(''Account ='', @s) = 1 BEGIN
      SET @where = @where + '' AND (a.'' + replace(left(@s, charindex(''='',@s) + 1),''Account'',''AccountName'') + '' @x4$)''
      SET @x4 = replace(ltrim(substring(@s, charindex(''='',@s) + 1, 4000)), '''''''', '''')
   END
   ELSE IF charindex(''MediumType ='', @s) = 1 BEGIN
      SET @where = @where + '' AND (t.'' + replace(left(@s, charindex(''='',@s) + 1),''MediumType'',''TypeName'') + '' @x5$)''
      SET @x5 = replace(ltrim(substring(@s, charindex(''='',@s) + 1, 4000)), '''''''', '''')
   END
   ELSE IF charindex(''CaseName ='', @s) = 1 BEGIN
      SET @where = @where + '' AND (c.'' + left(@s, charindex(''='',@s) + 1) + '' @x6$)''
      SET @x6 = replace(ltrim(substring(@s, charindex(''='',@s) + 1, 4000)), '''''''', '''')
   END
   ELSE IF charindex(''Notes ='', @s) = 1 BEGIN
      SET @where = @where + '' AND (m.'' + left(@s, charindex(''='',@s) + 1) + '' @x7$)''
      SET @x7 = replace(ltrim(substring(@s, charindex(''='',@s) + 1, 4000)), '''''''', '''')
   END
   ELSE IF charindex(''Notes LIKE '', @s) = 1 BEGIN
      SET @where = @where + '' AND (m.'' + left(@s, charindex(''LIKE'',@s) + 4) + '' @x7$)''
      SET @x7 = replace(ltrim(substring(@s, charindex(''LIKE'',@s) + 4, 4000)), '''''''', '''')
   END
   ELSE IF charindex(''Disaster ='', @s) = 1 BEGIN
      SET @where = @where + '' AND (d.Code = @x8$)''
      SET @x8 = replace(ltrim(substring(@s, charindex(''='',@s) + 1, 4000)), '''''''', '''')
   END
   ELSE IF charindex(''SerialNo LIKE '', @s) = 1 OR charindex(''SerialNo LIKE '', @s) = 2 BEGIN
      -- Isolate from rest of where clause
      SET @where = @where + '' AND (''
      -- Loop through, adding where clauses
      WHILE @p1 != 0 BEGIN
         SET @p1 = charindex('' OR '', @s)
         -- Get the string fragment
         IF @p1 = 0
            SET @s1 = ltrim(rtrim(@s))
         ELSE
            SET @s1 = ltrim(rtrim(substring(@s, 1, @p1)))
         -- Trim the filter
         SET @s = substring(@s, @p1 + 4, 4000)
         -- Get rid of starting left or ending right parenthesis
         IF left(@s1,1) = ''('' SET @s1 = substring(@s1,2,4000)
         IF substring(@s1,len(@s1),1) = '')'' SET @s1 = left(@s1,len(@s1)-1)
         -- Set the where clause
         IF @i = 0
            SET @where = @where + '' m.'' + left(@s1, charindex(''LIKE'',@s1) + 4) + '' @y'' + cast(@i as nchar(1)) + ''$''
         ELSE
            SET @where = @where + '' OR m.'' + left(@s1, charindex(''LIKE'',@s1) + 4) + '' @y'' + cast(@i as nchar(1)) + ''$''
         -- Get serial number value
         SET @s1 = replace(ltrim(substring(@s1, charindex(''LIKE'',@s1) + 4, 4000)), '''''''', '''')
         -- Which variable gets assigned depends on the value of i
         IF @i = 0 SET @y0 = @s1
         ELSE IF @i = 1 SET @y1 = @s1
         ELSE IF @i = 2 SET @y2 = @s1
         ELSE IF @i = 3 SET @y3 = @s1
         ELSE IF @i = 4 SET @y4 = @s1
         ELSE IF @i = 5 SET @y5 = @s1
         ELSE IF @i = 6 SET @y6 = @s1
         ELSE IF @i = 7 SET @y7 = @s1
         ELSE IF @i = 8 SET @y8 = @s1
         ELSE IF @i = 9 SET @y9 = @s1
         -- Raise error if too many status values
         IF @i = 9 AND @p1 != 0 BEGIN
            SET @msg = ''A maximum of ten wildcarded serial number search strings may be entered.'' + @msgTag + ''>''
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
      SET @msg = ''Error occurred while selecting page of media.  Invalid filter supplied.'' + @msgTag + ''>''
      EXECUTE error$raise @msg
      RETURN -100
   END
END

-- Construct the fields string
SET @fields2 = ''MediumId, SerialNo, Location, HotStatus, ReturnDate, Missing, LastMoveDate, BSide, Notes, AccountName, TypeName, CaseName, Disaster, RowVersion''
SET @fields1 = ''m.MediumId, m.SerialNo, m.Location, m.HotStatus, case len(coalesce(convert(nvarchar(10),c.ReturnDate,120),'''''''')) when 0 then coalesce(convert(nvarchar(10),m.ReturnDate,120),'''''''') else convert(nvarchar(10),c.ReturnDate,120) end as ''''ReturnDate'''', m.Missing, coalesce(convert(nvarchar(19),m.LastMoveDate,120),'''''''') as ''''LastMoveDate'''', m.BSide, m.Notes, a.AccountName, t.TypeName, coalesce(c.CaseName,'''''''') as ''''CaseName'''', ''''Disaster'''' = coalesce(d.Code,''''''''), m.RowVersion''

-- Construct the tables string
SET @tables = ''Medium$View m JOIN Account a ON a.AccountId = m.AccountId JOIN MediumType t ON t.TypeId = m.TypeId LEFT OUTER JOIN (SELECT sc.SerialNo as ''''CaseName'''', msc.MediumId as ''''MediumId'''', sc.ReturnDate as ''''ReturnDate'''' FROM SealedCase sc JOIN MediumSealedCase msc ON msc.CaseId = sc.CaseId) as c ON c.MediumId = m.MediumId LEFT JOIN (SELECT x1.Code, x2.MediumId FROM DisasterCode x1 JOIN DisasterCodeMedium x2 ON x2.CodeId = x1.CodeId) as d ON d.MediumId = m.MediumId''

-- Select the total number of records that fit the criteria
CREATE TABLE #tblTemp (xyz int)
SET @sql = ''INSERT #tblTemp SELECT count(*) FROM '' + @tables + @where
EXECUTE sp_executesql @sql, @var, @x1$ = @x1, @x2$ = @x2, @x3$ = @x3, @x4$ = @x4, @x5$ = @x5, @x6$ = @x6, @x7$ = @x7, @x8$ = @x8, @y0$ = @y0, @y1$ = @y1, @y2$ = @y2, @y3$ = @y3, @y4$ = @y4, @y5$ = @y5, @y6$ = @y6, @y7$ = @y7, @y8$ = @y8, @y9$ = @y9
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
EXECUTE sp_executesql @sql, @var, @x1$ = @x1, @x2$ = @x2, @x3$ = @x3, @x4$ = @x4, @x5$ = @x5, @x6$ = @x6, @x7$ = @x7, @x8$ = @x8, @y0$ = @y0, @y1$ = @y1, @y2$ = @y2, @y3$ = @y3, @y4$ = @y4, @y5$ = @y5, @y6$ = @y6, @y7$ = @y7, @y8$ = @y8, @y9$ = @y9
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
FROM   Account$View
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
FROM   Account$View
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

IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'receivelist$arrive')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.receiveList$arrive
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

-- Get the list
SELECT @status = Status,
       @listName = ListName,
       @compositeId = CompositeId
FROM   ReceiveList$View
WHERE  ListId = @listId AND RowVersion = @rowVersion
IF @@rowCount = 0 BEGIN
   IF EXISTS(SELECT 1 FROM ReceiveList$View WHERE ListId = @listId) BEGIN
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

-- If composite, the whole list must be marked as arrived
IF @compositeId IS NOT NULL BEGIN
   SET @msg = ''When a list is a member of a composite, the entire composite must be marked as arrived.'' + @msgTag + ''>''
   RAISERROR(@msg,16,1)
   RETURN -100
END

-- If already arrived or past this point, just return
IF @status = 64 RETURN 0

-- Validate that list is arrive-eligible
IF dbo.bit$statusEligible(2,@status,64) = 0 BEGIN
   SET @msg = ''List '' + @listName + '' is not eligible to be marked as arrived.'' + @msgTag + ''>''
   RAISERROR(@msg,16,1)
   RETURN -100
END

-- Get the list items to be marked as arrived
INSERT @tblItems (ItemId)
SELECT rli.ItemId
FROM   ReceiveListItem rli
JOIN   Medium m
  ON   m.MediumId = rli.MediumId
WHERE  m.Missing = 0 AND rli.Status != 1 AND
      (rli.ListId = @listId OR rli.ListId IN (SELECT ListId FROM ReceiveList WHERE CompositeId = @listId))

-- Upgrade the status of the item to arrived
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

UPDATE ReceiveListItem
SET    Status = 64
WHERE  ItemId IN (SELECT ItemId FROM @tblItems)
SET @error = @@error
IF @error != 0 BEGIN
   ROLLBACK TRANSACTION @tranName
   COMMIT TRANSACTION
   SET @msg = ''Error encountered while updating list to arrived status.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
   EXECUTE error$raise @msg, @error
   RETURN -100
END

-- Commit and return
COMMIT TRANSACTION
RETURN 0
END
'
)

IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'receivelist$clear')
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
DECLARE @r1 binary(8)

SET NOCOUNT ON

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=P''
SET @tranName = object_name(@@procid) + CAST(@@nestlevel as nvarchar(2))

-- Get the list
SELECT @listName = ListName,
       @accountId = AccountId,
       @status = Status
FROM   ReceiveList$View
WHERE  ListId = @listId
IF @@rowCount = 0 BEGIN
   SET @msg = ''List not found.'' + @msgTag + ''>''
   RAISERROR(@msg,16,1)
   RETURN -100
END
ELSE IF NOT EXISTS
   (
   SELECT 1
   FROM   ReceiveList$View
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
   -- Dissolve the list
   SELECT @r1 = RowVersion
   FROM   ReceiveList
   WHERE  ListId = @listId
   EXECUTE @returnValue = receiveList$dissolve @listId, @r1
   IF @returnValue != 0 BEGIN
      ROLLBACK TRANSACTION @tranName
      COMMIT TRANSACTION
      RETURN -100
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

IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'receivelist$del')
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
FROM   ReceiveList$View 
WHERE  ListId = @listId AND RowVersion = @rowVersion
IF @@rowCount = 0 BEGIN
   IF EXISTS (SELECT 1 FROM ReceiveList$View WHERE ListId = @listId) BEGIN
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

IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'receivelist$dissolve')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.receiveList$dissolve
(
   @listId int,         -- id of the composite
   @listVersion rowversion
)
WITH ENCRYPTION
AS
BEGIN
DECLARE @msg as nvarchar(255)        -- used to preformat error message
DECLARE @msgTag as nvarchar(255)     -- used to hold first part of error message header
DECLARE @tranName as nvarchar(255)   -- used to hold name of savepoint
DECLARE @rowCount as int
DECLARE @error as int
DECLARE @caseId as int
DECLARE @caseName as nvarchar(32)
DECLARE @listName as nchar(10)
DECLARE @lastList as int
DECLARE @returnValue as int
DECLARE @accountId as int
DECLARE @status as int
DECLARE @count as int

SET NOCOUNT ON

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=P''
SET @tranName = object_name(@@procid) + CAST(@@nestlevel as nvarchar(2))

-- Check concurrency of composite, and verify that it actually is a composite
SELECT @listName = ListName,
       @accountId = AccountId,
       @status = Status
FROM   ReceiveList$View 
WHERE  ListId = @listId AND RowVersion = @listVersion
IF @@rowCount = 0 BEGIN
   IF EXISTS (SELECT 1 FROM ReceiveList$View WHERE ListId = @listId) BEGIN
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
ELSE IF @accountId IS NOT NULL BEGIN
   SET @msg = ''Receive list '''''' + @listName + '''''' is not a composite list.'' + @msgTag + ''>''
   RAISERROR(@msg,16,1)
   RETURN -100
END

-- Check for a case that exists on more than one list within the composite.
IF @status != 512 BEGIN
   SELECT TOP 1 @caseId = msc.CaseId
   FROM   MediumSealedCase msc
   JOIN   ReceiveListItem rli
     ON   rli.MediumId = msc.MediumId
   JOIN   ReceiveList rl
     ON   rl.ListId = rli.ListId
   WHERE  rl.CompositeId = @listId
   GROUP BY msc.CaseId
   HAVING count(DISTINCT rli.ListId) > 1
   IF @@rowCount > 0 BEGIN
      SELECT @caseName = SerialNo FROM SealedCase WHERE CaseId = @caseId
      SET @msg = ''Cannot extract lists because case '''''' + @caseName + '''''' appears on multiple lists within the composite.'' + @msgTag + ''>''
      RAISERROR(@msg,16,1)
      RETURN -100
   END
END

-- Begin the transaction
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

-- Update all the discretes to have no composite
SET @lastList = 0
WHILE 1 = 1 BEGIN
   SELECT TOP 1 @lastList = ListId
   FROM   ReceiveList
   WHERE  CompositeId = @listId AND
          ListId > @lastList
   ORDER BY ListId ASC
   IF @@rowCount = 0 BEGIN
      BREAK
   END
   ELSE BEGIN
      UPDATE ReceiveList
      SET    CompositeId = NULL
      WHERE  ListId = @lastList
      SET @error = @@error
      IF @error != 0 BEGIN
         ROLLBACK TRANSACTION @tranName
         COMMIT TRANSACTION
         SET @msg = ''Error encountered while dissolving composite receive list.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
         EXECUTE error$raise @msg, @error
         RETURN -100
      END
   END
END

-- Commit the transaction
COMMIT TRANSACTION
RETURN 0
END
'
)

IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'receivelist$extract')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.receiveList$extract
(
   @listId int,              -- id of the list to be extracted
   @listVersion rowversion,
   @compositeId int,         -- id of the composite
   @compositeVersion rowversion
)
WITH ENCRYPTION
AS
BEGIN
DECLARE @msg as nvarchar(255)        -- used to preformat error message
DECLARE @msgTag as nvarchar(255)     -- used to hold first part of error message header
DECLARE @tranName as nvarchar(255)   -- used to hold name of savepoint
DECLARE @rowCount as int
DECLARE @error as int
DECLARE @caseId as int
DECLARE @accountId as int
DECLARE @listName as nchar(10)
DECLARE @caseName as nvarchar(32)
DECLARE @compositeName as nchar(10)
DECLARE @returnValue as int
DECLARE @status as int

SET NOCOUNT ON

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=P''
SET @tranName = object_name(@@procid) + CAST(@@nestlevel as nvarchar(2))

-- Check concurrency of composite, and verify that it actually is a composite
SELECT @compositeName = ListName,
       @accountId = AccountId,
       @status = Status
FROM   ReceiveList$View 
WHERE  ListId = @compositeId AND RowVersion = @compositeVersion
IF @@rowCount = 0 BEGIN
   IF NOT EXISTS (SELECT 1 FROM ReceiveList$View WHERE ListId = @compositeId) BEGIN
      SET @msg = ''Receive list not found.'' + @msgTag + ''>''
      RAISERROR(@msg,16,1)
      RETURN -100
   END
   ELSE BEGIN
      SET @msg = ''List has been modified since retrieval.'' + @msgTag + ''>''
      RAISERROR(@msg,16,1)
      RETURN -100
   END
END
ELSE IF @accountId IS NOT NULL BEGIN
   SET @msg = ''List '''''' + @compositeName + '''''' is not a composite list.'' + @msgTag + ''>''
   RAISERROR(@msg,16,1)
   RETURN -100
END

-- Check concurrency of discrete, and verify that it actually belongs to the given composite
SELECT @listName = ListName
FROM   ReceiveList$View 
WHERE  ListId = @listId AND RowVersion = @listVersion
IF @@rowCount = 0 BEGIN
   IF NOT EXISTS (SELECT 1 FROM ReceiveList$View WHERE ListId = @listId) BEGIN
      SET @msg = ''List not found.'' + @msgTag + ''>''
      RAISERROR(@msg,16,1)
      RETURN -100
   END
   ELSE BEGIN
      SET @msg = ''List has been modified since retrieval.'' + @msgTag + ''>''
      RAISERROR(@msg,16,1)
      RETURN -100
   END
END
ELSE IF NOT EXISTS (SELECT 1 FROM ReceiveList WHERE ListId = @listId AND CompositeId = @compositeId) BEGIN
   SET @msg = ''List '''''' + @listName + '''''' is not part of composite list '''''' + @compositeName + ''''''.'' + @msgTag + ''>''
   RAISERROR(@msg,16,1)
   RETURN -100
END

-- If a medium in a sealed case appears on another discrete list within
-- the composite, then the list may not be extracted.
SELECT TOP 1 @caseId = msc.CaseId
FROM   MediumSealedCase msc
JOIN   ReceiveListItem rli
  ON   rli.MediumId = msc.MediumId
JOIN   ReceiveList rl
  ON   rl.ListId = rli.ListId
JOIN   (SELECT msc1.CaseId
        FROM   MediumSealedCase msc1
        JOIN   ReceiveListItem rli1
          ON   rli1.MediumId = msc1.MediumId
        WHERE  rli1.ListId = @listId) as c
  ON   c.CaseId = msc.CaseId
WHERE  rl.CompositeId = @compositeId
GROUP BY msc.CaseId
HAVING count(DISTINCT rli.ListId) > 1
IF @@rowCount > 0 BEGIN
   SELECT @caseName = SerialNo 
   FROM   SealedCase 
   WHERE  CaseId = @caseId
   SET @msg = ''List '''''' + @listName + '''''' may not be extracted because case '''''' + @caseName + '''''' also appears on another list within its composite.'' + @msgTag + ''>''
   RAISERROR(@msg,16,1)
   RETURN -100
END

-- Begin the transaction
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

-- Remove the discrete from the composite
UPDATE ReceiveList
SET    CompositeId = NULL
WHERE  ListId = @listId
SET @error = @@error
IF @error != 0 BEGIN
   ROLLBACK TRANSACTION @tranName
   COMMIT TRANSACTION
   SET @msg = ''Error encountered while extracting receive list.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
   EXECUTE error$raise @msg, @error
   RETURN -100
END

-- If there are no discretes left in the composite, the composite will have
-- been deleted in the trigger.  No need to delete it here, so just commit
-- and return.
COMMIT TRANSACTION
RETURN 0
END
'
)

IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'receivelist$getbydate')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.receiveList$getByDate
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
FROM   ReceiveList$View rl
JOIN   Account a
  ON   a.AccountId = rl.AccountId
WHERE  CompositeId IS NULL AND
       convert(nchar(10),rl.CreateDate,120) = @dateString
UNION
SELECT rl.ListId,
       rl.ListName,
       rl.CreateDate,
       rl.Status,
       '''',
       rl.RowVersion
FROM   ReceiveList$View rl
WHERE  AccountId IS NULL AND
       EXISTS(SELECT 1 
              FROM   ReceiveList rl2
              WHERE  CompositeId = rl.ListId AND
                     convert(nchar(10),rl2.CreateDate,120) = @dateString)
ORDER BY ListName Desc

END
'
)

IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'receivelist$getbyid')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.receiveList$getById
(
   @id int
)
WITH ENCRYPTION
AS
BEGIN

SET NOCOUNT ON

-- Select the list
SELECT rl.ListId,
       rl.ListName,
       rl.CreateDate,
       rl.Status,
       coalesce(a.AccountName,'''') as ''AccountName'',
       rl.RowVersion
FROM   ReceiveList$View rl
LEFT 
OUTER 
JOIN   Account a
  ON   a.AccountId = rl.AccountId
WHERE  rl.ListId = @id

-- If the list is a composite then get the child lists as well
IF EXISTS(SELECT 1 FROM ReceiveList WHERE CompositeId = @id) BEGIN
   SELECT rl.ListId,
          rl.ListName,
          rl.CreateDate,
          rl.Status,
          a.AccountName,
          rl.RowVersion
   FROM   ReceiveList$View rl
   JOIN   Account a
     ON   a.AccountId = rl.AccountId
   WHERE  rl.CompositeId = @id
   ORDER BY rl.ListName
END

END
'
)

IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'receivelist$getbymedium')
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
FROM   ReceiveList$View rl
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

IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'receivelist$getbyname')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.receiveList$getByName
(
   @listName nchar(10)
)
WITH ENCRYPTION
AS
BEGIN
DECLARE @id int

SET NOCOUNT ON

-- Select the list
SELECT rl.ListId,
       rl.ListName,
       rl.CreateDate,
       rl.Status,
       coalesce(a.AccountName,'''') as ''AccountName'',
       rl.RowVersion
FROM   ReceiveList$View rl
LEFT 
OUTER 
JOIN   Account a
  ON   a.AccountId = rl.AccountId
WHERE  rl.ListName = @listName

-- If the list is a composite then get the child lists as well
SELECT @id = ListId 
FROM   ReceiveList$View 
WHERE  ListName = @listName

IF EXISTS(SELECT 1 FROM ReceiveList$View WHERE CompositeId = @id) BEGIN
   SELECT rl.ListId,
          rl.ListName,
          rl.CreateDate,
          rl.Status,
          a.AccountName,
          rl.RowVersion
   FROM   ReceiveList$View rl
   JOIN   Account a
     ON   a.AccountId = rl.AccountId
   WHERE  rl.CompositeId = @id
   ORDER BY rl.ListName
END

END
'
)

IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'receivelist$getbystatusanddate')
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
FROM   ReceiveList$View rl
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
FROM   ReceiveList$View rl
WHERE  AccountId IS NULL AND EXISTS (SELECT 1 
                                     FROM   ReceiveList$View rl2 
                                     WHERE  CompositeId = rl.ListId And 
                                            rl2.Status = (rl2.Status & @Status) And 
                                            convert(nchar(10),rl2.CreateDate,120) = @dateString)
ORDER  BY ListName Desc

END
'
)

IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'receivelist$getcleared')
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
FROM   ReceiveList$View rl
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
FROM   ReceiveList$View rl
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

IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'receivelist$getitems')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.receiveList$getItems
(
   @listId int
)
WITH ENCRYPTION
AS
BEGIN

SET NOCOUNT ON

-- Select the items on list
SELECT rli.ItemId,
       rli.Status,
       m.Notes,
       m.SerialNo,
       coalesce(sc.CaseName,'''') as ''CaseName'',
       rli.RowVersion
FROM   ReceiveList$View rl
JOIN   ReceiveListItem rli
  ON   rli.ListId = rl.ListId
JOIN   Medium m
  ON   m.MediumId = rli.MediumId
LEFT OUTER JOIN 
       (
       SELECT sc1.SerialNo as ''CaseName'', 
              msc1.MediumId as ''MediumId''
       FROM   SealedCase sc1
       JOIN   MediumSealedCase msc1
         ON   msc1.CaseId = sc1.CaseId
       )
       AS sc
  ON   sc.MediumId = m.MediumId 
WHERE  rl.ListId = @listId OR rl.CompositeId = @listId

END
'
)

IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'receivelist$getpage')
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
SET @tables = ''ReceiveList$View rl LEFT OUTER JOIN Account a ON rl.AccountId = a.AccountId''

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

IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'receivelist$merge')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.receiveList$merge
(
   @listId1 int,
   @rowVersion1 rowVersion,
   @listId2 int,
   @rowVersion2 rowVersion,
   @compositeId int OUTPUT     -- id of composite list
)
WITH ENCRYPTION
AS
BEGIN
DECLARE @msg as nvarchar(255)        -- used to preformat error message
DECLARE @msgTag as nvarchar(255)     -- used to hold first part of error message header
DECLARE @tranName as nvarchar(255)   -- used to hold name of savepoint
DECLARE @rowCount as int
DECLARE @error as int
DECLARE @accountId1 as int
DECLARE @accountId2 as int
DECLARE @status1 as int
DECLARE @status2 as int
DECLARE @listName1 as nchar(10)
DECLARE @listName2 as nchar(10)
DECLARE @returnValue as int
DECLARE @compositeName as nchar(10)

SET NOCOUNT ON

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=P''
SET @tranName = object_name(@@procid) + CAST(@@nestlevel as nvarchar(2))

-- Get the name of the first list and test its concurrency.  Also make sure
-- that it is not a discrete list currently belonging to another composite.
SELECT @status1 = Status,
       @listName1 = ListName,
       @accountId1 = AccountId
FROM   ReceiveList$View
WHERE  ListId = @listId1 AND RowVersion = @rowVersion1
IF @@rowCount = 0 BEGIN
   IF EXISTS (SELECT 1 FROM ReceiveList$View WHERE ListId = @listId1) BEGIN
      SET @msg = ''List has been modified since retrieval.'' + @msgTag + ''>''
      RAISERROR(@msg,16,1)
      RETURN -100
   END
   ELSE BEGIN
      SET @msg = ''List not found.'' + @msgTag + ''>''
      RAISERROR(@msg,16,1)
      RETURN -100
   END
END
ELSE IF EXISTS
   (
   SELECT 1 
   FROM   ReceiveList
   WHERE  ListId = @listId1 AND CompositeId IS NOT NULL
   )
BEGIN
   SET @msg = ''List '''''' + @listName1 + '''''' must first be extracted from its current composite.'' + @msgTag + ''>''
   RAISERROR(@msg,16,1)
   RETURN -100
END

-- Get the name of the second list and test its concurrency.  Also make sure
-- that it is not a discrete list currently belonging to another composite.
SELECT @status2 = Status,
       @listName2 = ListName,
       @accountId2 = AccountId
FROM   ReceiveList$View 
WHERE  ListId = @listId2 AND RowVersion = @rowVersion2
IF @@rowCount = 0 BEGIN
   IF EXISTS (SELECT 1 FROM ReceiveList$View WHERE ListId = @listId2) BEGIN
      SET @msg = ''List has been modified since retrieval.'' + @msgTag + ''>''
      RAISERROR(@msg,16,1)
      RETURN -100
   END
   ELSE BEGIN
      SET @msg = ''List not found.'' + @msgTag + ''>''
      RAISERROR(@msg,16,1)
      RETURN -100
   END
END
ELSE IF EXISTS
   (
   SELECT 1 
   FROM   ReceiveList
   WHERE  ListId = @listId2 AND CompositeId IS NOT NULL
   )
BEGIN
   SET @msg = ''List '''''' + @listName2 + '''''' must first be extracted from its current composite.'' + @msgTag + ''>''
   RAISERROR(@msg,16,1)
   RETURN -100
END

-- There are three possibilites.  Either we have (a) two discrete lists, or
-- (b) two composite lists, or (c) one of each.  In case (a) we create a new 
-- composite list and attach the two discretes to it.  In case (b) we take
-- all of the discrete lists from the list with the lower number, move
-- them into the other composite, and delete the now empty composite.  In
-- case (c) we merge the discrete into the existing composite.

-- Begin the transaction
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

-- If we have two discrete lists, create a composite and merge the two
-- discrete lists into it.
IF @accountId1 IS NOT NULL AND @accountId2 IS NOT NULL BEGIN
   -- Create the composite send list
   EXEC @returnValue = receiveList$create NULL, @compositeName OUT
   IF @returnValue != 0 BEGIN
      ROLLBACK TRANSACTION @tranName
      COMMIT TRANSACTION
      RETURN -100
   END
   ELSE BEGIN
      SELECT @compositeId = ListId
      FROM   ReceiveList
      WHERE  ListName = @compositeName
   END
   -- Assign the the two discretes to the new composite
   UPDATE ReceiveList
   SET    CompositeId = @compositeId
   WHERE  ListId = @listId1 OR ListId = @listId2
   SET @error = @@error
   IF @error != 0 BEGIN
      ROLLBACK TRANSACTION @tranName
      COMMIT TRANSACTION
      SET @msg = ''Error encountered while merging lists into composite.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
      EXECUTE error$raise @msg, @error
      RETURN -100
   END 
END
-- If we have two composites, move all the discrete that belong to the 
-- lower numbered composite to the higher numbered composite.  Then
-- delete the lower numbered composite.
ELSE IF @accountId1 IS NULL AND @accountId2 IS NULL BEGIN
   -- Get the id of the surviving composite
   SELECT @compositeId = dbo.int$max(@listId1,@listId2)
   -- Take all the discretes from the lower and assign to the higher
   UPDATE ReceiveList
   SET    CompositeId = @compositeId
   WHERE  CompositeId = dbo.int$min(@listId1,@listId2)
   SET @error = @@error
   IF @error != 0 BEGIN
      ROLLBACK TRANSACTION @tranName
      COMMIT TRANSACTION
      SET @msg = ''Error encountered while merging lists from two composite receive lists.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
      EXECUTE error$raise @msg, @error
      RETURN -100
   END 
   -- Delete the now empty composite list record
   IF @listId1 < @listId2
      EXECUTE @returnValue = receiveList$del @listId1, @rowVersion1
   ELSE
      EXECUTE @returnValue = receiveList$del @listId2, @rowVersion2
   IF @returnValue != 0 BEGIN
      ROLLBACK TRANSACTION @tranName
      COMMIT TRANSACTION
      RETURN -100
   END 
END
-- If we have one discrete and one composite, merge the discrete
-- into the composite.
ELSE BEGIN
   SELECT @compositeId = ListId
   FROM   ReceiveList 
   WHERE  AccountId IS NULL AND 
          ListId = @listId1 OR ListId  = @listId2
   UPDATE ReceiveList
   SET    CompositeId = @compositeId
   WHERE  ListId IN (@listId1, @listId2) AND ListId != @compositeId
   SET @error = @@error
   IF @error != 0 BEGIN
      ROLLBACK TRANSACTION @tranName
      COMMIT TRANSACTION
      SET @msg = ''Error encountered while merging a discrete receive list into an existing composite.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
      EXECUTE error$raise @msg, @error
      RETURN -100
   END 
END

-- Set the status of the composite list
UPDATE ReceiveList
SET    Status = dbo.int$min(@status1,@status2)
WHERE  ListId = @compositeId
SET @error = @@error
IF @error != 0 BEGIN
   ROLLBACK TRANSACTION @tranName
   COMMIT TRANSACTION
   SET @msg = ''Error encountered while setting status of new composite list.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
   EXECUTE error$raise @msg, @error
   RETURN -100
END 

-- Commit the transaction
COMMIT TRANSACTION
RETURN 0
END
'
)

IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'receivelist$removecase')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.receiveList$removeCase
(
   @listId int,
   @caseName nvarchar(32),
   @rowversion rowversion
)
WITH ENCRYPTION
AS
BEGIN
DECLARE @msg as nvarchar(255)        -- used to preformat error message
DECLARE @msgTag as nvarchar(255)     -- used to hold first part of error message header
DECLARE @tranName as nvarchar(255)   -- used to hold name of savepoint
DECLARE @compositeId as int
DECLARE @status as int
DECLARE @caseId as int
DECLARE @error as int

SET NOCOUNT ON

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=P''
SET @tranName = object_name(@@procid) + CAST(@@nestlevel as nvarchar(2))

-- Get the list
SELECT @status = Status,
       @compositeId = isnull(CompositeId,-1)
FROM   ReceiveList$View
WHERE  ListId = @listId AND RowVersion = @rowVersion
IF @@rowCount = 0 BEGIN
   IF EXISTS(SELECT 1 FROM ReceiveList$View WHERE ListId = @listId) BEGIN
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

-- Get the case
SELECT @caseId = CaseId
FROM   SealedCase
WHERE  SerialNo = @caseName
IF @@rowCount = 0 BEGIN
   SET @msg = ''Sealed case not found.'' + @msgTag + ''>''
   RAISERROR(@msg,16,1)
   RETURN -100
END

-- If already removed, just return
IF @status = 1 RETURN 0

-- If past transmitted, cannot actively remove the item
IF @status >= 4 AND EXISTS (SELECT 1 FROM ListStatusProfile WHERE ProfileId = 2 AND Statuses & 4 != 0) BEGIN
   SET @msg = ''Items may not be removed from a list once that list has been transmitted.'' + @msgTag + ''>''
   RAISERROR(@msg,16,1)
   RETURN -100
END
ELSE IF @status >= 16 BEGIN
   SET @msg = ''Items may not be removed from a list once it has attained '' + dbo.string$statusName(2,16) + '' status.'' + @msgTag + ''>''
   RAISERROR(@msg,16,1)
   RETURN -100
END

-- Delete operator
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

UPDATE ReceiveListItem
SET    Status = 1
WHERE  ItemId IN (SELECT rli.ItemId
                  FROM   ReceiveListItem rli
                  JOIN   ReceiveList rl
                    ON   rl.ListId = rli.ListId
                  JOIN   MediumSealedCase msc
                    ON   msc.MediumId = rli.MediumId
                  WHERE (rl.ListId = @listId OR rl.CompositeId = @compositeId) AND msc.CaseId = @caseId AND rli.Status != 1)

SELECT @error = @@error

IF @error != 0 BEGIN
   ROLLBACK TRANSACTION @tranName
   COMMIT TRANSACTION
   SET @msg = ''Error encountered while removing sealed case '' + @caseName + '' from list.'' + @msgTag + '';Error='' + cast(@error as nvarchar(10)) + ''>''
   EXECUTE error$raise @msg, @error
   RETURN -100
END

-- Commit transaction
COMMIT TRANSACTION
RETURN 0
END
'
)

IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'receivelist$transit')
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
FROM   ReceiveList$View
WHERE  ListId = @listId AND RowVersion = @rowVersion
IF @@rowCount = 0 BEGIN
   IF EXISTS(SELECT 1 FROM ReceiveList$View WHERE ListId = @listId) BEGIN
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

IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'receivelist$transmit')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.receiveList$transmit
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
DECLARE @lastItem int
DECLARE @rowCount int
DECLARE @status int
DECLARE @error int
DECLARE @tblMedium table (RowNo int identity(1,1), ItemId int)

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=P''
SET @tranName = object_name(@@procid) + CAST(@@nestlevel as nvarchar(2))

-- If the status of the list is already transmitted, then return.  Otherwise,
-- if it is anything besides submitted, raise error.
SELECT @status = Status
FROM   ReceiveList$View
WHERE  ListId = @listId AND RowVersion = @rowVersion
IF @@rowCount = 0 BEGIN
   IF EXISTS(SELECT 1 FROM ReceiveList$View WHERE ListId = @listId) BEGIN
      SET @msg = ''Receive list item has been modified since retrieval.'' + @msgTag + ''>''
      RAISERROR(@msg,16,1)
      RETURN -100
   END
   ELSE BEGIN
      SET @msg = ''Receive list item not found.'' + @msgTag + ''>''
      RAISERROR(@msg,16,1)
      RETURN -100
   END
END

-- If already transmitted, just return.  Otherwise, the only other status
-- that the list may have is 2 (submitted), which is always available to
-- be transmitted.
IF @status >= 4 RETURN 0

-- Upgrade the status of all the unremoved items on the list to transmitted
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

IF EXISTS (SELECT 1 FROM ReceiveList WHERE CompositeId = @listId) BEGIN
   UPDATE ReceiveListItem
   SET    Status = 4
   WHERE  Status != 1 AND ListId = (SELECT ListId FROM ReceiveList WHERE CompositeId = @listId)
END
ELSE BEGIN
   UPDATE ReceiveListItem
   SET    Status = 4
   WHERE  Status != 1 AND ListId = @listId
END
SET @error = @@error
IF @error != 0 BEGIN
   ROLLBACK TRANSACTION @tranName
   COMMIT TRANSACTION
   SET @msg = ''Error encountered while upgrading receive list items to transmitted.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
   EXECUTE error$raise @msg, @error
   RETURN -100
END

-- Commit and return
COMMIT TRANSACTION
RETURN 0
END
'
)

IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'receivelistitem$add')
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
FROM   ReceiveList$View
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

IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'receivelistitem$get')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.receiveListItem$get
(
   @itemId int
)
WITH ENCRYPTION
AS
BEGIN

SET NOCOUNT ON

-- Select the items on list
SELECT rli.ItemId,
       rli.Status,
       m.Notes,
       m.SerialNo,
       coalesce(sc.CaseName,'''') as ''CaseName'',
       rli.RowVersion
FROM   ReceiveListItem rli
JOIN   Medium$View m
  ON   m.MediumId = rli.MediumId
LEFT OUTER JOIN 
       (
       SELECT sc1.SerialNo as ''CaseName'', 
              msc1.MediumId as ''MediumId''
       FROM   SealedCase sc1
       JOIN   MediumSealedCase msc1
         ON   msc1.CaseId = sc1.CaseId
       )
       AS sc
  ON   sc.MediumId = m.MediumId 
WHERE  rli.ItemId = @itemId

END
'
)

IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'receivelistitem$getbymedium')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.receiveListItem$getByMedium
(
   @serialNo nvarchar(64)
)
WITH ENCRYPTION
AS
BEGIN

SET NOCOUNT ON

-- Select the items on list
SELECT rli.ItemId,
       rli.Status,
       m.Notes,
       m.SerialNo,
       coalesce(sc.CaseName,'''') as ''CaseName'',
       rli.RowVersion
FROM   ReceiveListItem rli
JOIN   Medium$View m
  ON   m.MediumId = rli.MediumId
LEFT OUTER JOIN 
       (
       SELECT sc1.SerialNo as ''CaseName'', 
              msc1.MediumId as ''MediumId''
       FROM   SealedCase sc1
       JOIN   MediumSealedCase msc1
         ON   msc1.CaseId = sc1.CaseId
       )
       AS sc
  ON   sc.MediumId = m.MediumId 
WHERE  m.SerialNo = @serialNo AND rli.Status NOT IN (1,1024)

END
'
)

IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'receivelistitem$getpage')
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
SET @fields2 = ''ItemId, SerialNo, AccountName, Status, CaseName, Notes, RowVersion, MediumType''
SET @fields1 = ''rli.ItemId, m.SerialNo, a.AccountName, rli.Status, coalesce(sc.CaseName,'''''''') as ''''CaseName'''', rli.Notes, rli.RowVersion, MediumType = t.TypeName''

-- Construct the tables string
SET @tables = ''ReceiveListItem rli JOIN ReceiveList$View rl ON rl.ListId = rli.ListId JOIN Medium m ON m.MediumId = rli.MediumId JOIN MediumType t ON t.TypeId = m.TypeId JOIN Account a ON a.AccountId = m.AccountId LEFT OUTER JOIN (SELECT sc.SerialNo as ''''CaseName'''', msc.MediumId as ''''MediumId'''' FROM SealedCase sc JOIN MediumSealedCase msc ON msc.CaseId = sc.CaseId JOIN ReceiveListItem rli ON rli.MediumId = msc.MediumId JOIN ReceiveList rl ON rl.ListId = rli.ListId WHERE rl.ListId = '' + cast(@listId as nvarchar(50)) + '' OR rl.CompositeId = '' + cast(@listId as nvarchar(50)) + '') AS sc ON sc.MediumId = m.MediumId''

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

IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'receivelistitem$ins')
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
FROM   Medium$View m
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

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'receiveList$createByDate')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.receiveList$createByDate
(
   @listDate datetime,
   @batchLists nvarchar(4000) output
)
WITH ENCRYPTION
AS
BEGIN
DECLARE @msg as nvarchar(255)        -- used to preformat error message
DECLARE @msgTag as nvarchar(255)     -- used to hold first part of error message header
DECLARE @tranName as nvarchar(255)   -- used to hold name of savepoint
DECLARE @serialNo nvarchar(32)
DECLARE @returnValue int
DECLARE @rowCount as int
DECLARE @error as int
DECLARE @i as int
DECLARE @tblSerial table (RowNo int identity(1,1) primary key clustered, SerialNo nvarchar(64))

SET NOCOUNT ON

-- Initialize
SET @i = 1
SET @batchLists = ''''

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=P''
SET @tranName = object_name(@@procid) + CAST(@@nestlevel as nvarchar(2))

-- Begin the transaction
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

-- Get all media at the vault, not currently on another list, with a return 
-- date earlier or equal to the given date.  Recall that if a medium is in a
-- sealed case it must use the return date of the sealed case.  Even if the
-- case return date is null, the medium in the case should not use its own
-- return date (if it has one).  Entities using null return dates should
-- never appear on the created list(s).
INSERT @tblSerial (SerialNo)
SELECT m.SerialNo
FROM   Medium$View m
LEFT OUTER JOIN
       (
       SELECT rli.MediumId
       FROM   ReceiveListItem rli
       WHERE  rli.Status NOT IN (1,512)
       )
       AS r
  ON   r.MediumId = m.MediumId
LEFT OUTER JOIN 
       (
       SELECT coalesce(sc.ReturnDate,''2999-01-01'') as ''ReturnDate'',
              msc.MediumId as ''MediumId''
       FROM   SealedCase sc
       JOIN   MediumSealedCase msc
         ON   msc.CaseId = sc.CaseId
       )
       AS c
  ON   c.MediumId = m.MediumId
WHERE  m.Location = 0 AND
       r.MediumId IS NULL AND
       coalesce(convert(nchar(10),coalesce(c.ReturnDate,m.ReturnDate),120),''2999-01-01'') <= convert(nchar(10),@listDate,120)
ORDER BY m.SerialNo asc

-- Run through the serial numbers
WHILE 1 = 1 BEGIN
   SELECT @serialNo = SerialNo
   FROM   @tblSerial
   WHERE  RowNo = @i
   IF @@rowCount = 0
      BREAK
   ELSE BEGIN
      EXECUTE @returnValue = receiveListItem$ins @serialNo, '''', @batchLists output
      IF @returnValue != 0 BEGIN
         ROLLBACK TRANSACTION @tranName
         COMMIT TRANSACTION
         RETURN -100
      END
   END
   -- Increment counter
   SET @i = @i + 1
END

-- Commit the transaction
COMMIT TRANSACTION
RETURN 0
END
'
)

IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'receivelistitem$verify')
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
JOIN   ReceiveList$View r
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

IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'sealedcase$getmedia')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.sealedCase$getMedia
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
       coalesce(convert(nvarchar(10),sc.ReturnDate,120),'''') as ''ReturnDate'',
       m.Missing, 
       coalesce(convert(nvarchar(19),m.LastMoveDate,120),'''') as ''LastMoveDate'',
       m.BSide, 
       m.Notes,
       a.AccountName, 
       t.TypeName, 
       sc.SerialNo as ''CaseName'', 
       m.RowVersion
FROM   Medium$View m 
JOIN   Account a 
  ON   a.AccountId = m.AccountId 
JOIN   MediumType t 
  ON   t.TypeId = m.TypeId
JOIN   MediumSealedCase msc
  ON   msc.MediumId = m.MediumId
JOIN   SealedCase sc
  ON   msc.CaseId = sc.CaseId
WHERE  sc.SerialNo = @caseName
ORDER BY m.SerialNo ASC

END
'
)

IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'sendlist$arrive')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.sendList$arrive
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
FROM   SendList$View
WHERE  ListId = @listId AND RowVersion = @rowVersion
IF @@rowCount = 0 BEGIN
   IF EXISTS(SELECT 1 FROM SendList$View WHERE ListId = @listId) BEGIN
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
   SET @msg = ''When a list is a member of a composite, the entire composite must be marked as arrived.'' + @msgTag + ''>''
   RAISERROR(@msg,16,1)
   RETURN -100
END

-- If already arrived, just return
IF @status = 64 
   RETURN 0
ELSE IF @status > 64 BEGIN
   SET @msg = ''List '' + @listName + '' is past the point of being marked as arrived.'' + @msgTag + ''>''
   RAISERROR(@msg,16,1)
   RETURN -100
END

-- Validate that list is arrive-eligible
IF dbo.bit$statusEligible(1,@status,64) = 0 BEGIN
   SET @msg = ''List '' + @listName + '' is not eligible to be marked as arrived.'' + @msgTag + ''>''
   RAISERROR(@msg,16,1)
   RETURN -100
END

-- Get the list items to be marked as arrived
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
SET    Status = 64
WHERE  ItemId IN (SELECT ItemId FROM @tblItems)
SET @error = @@error
IF @error != 0 BEGIN
   ROLLBACK TRANSACTION @tranName
   COMMIT TRANSACTION
   SET @msg = ''Error encountered while updating list to arrived status.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
   EXECUTE error$raise @msg, @error
   RETURN -100
END

-- Commit and return
COMMIT TRANSACTION
RETURN 0
END
'
)

IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'sendlist$clear')
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
DECLARE @r1 binary(8)

SET NOCOUNT ON

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=P''
SET @tranName = object_name(@@procid) + CAST(@@nestlevel as nvarchar(2))

-- If the list has submitted or verified status, raise error.  If the list 
-- has cleared status, return.  Also check concurrency.
SELECT @listName = ListName,
       @accountId = AccountId,
       @status = Status
FROM   SendList$View
WHERE  ListId = @listId
IF @@rowCount = 0 BEGIN
   SET @msg = ''Send list not found.'' + @msgTag + ''>''
   RAISERROR(@msg,16,1)
   RETURN -100
END
ELSE IF NOT EXISTS
   (
   SELECT 1
   FROM   SendList$View
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
   -- Dissolve the list
   SELECT @r1 = RowVersion
   FROM   SendList
   WHERE  ListId = @listId
   EXECUTE @returnValue = sendList$dissolve @listId, @r1
   IF @returnValue != 0 BEGIN
      ROLLBACK TRANSACTION @tranName
      COMMIT TRANSACTION
      RETURN -100
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

IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'sendlist$del')
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
FROM   SendList$View
WHERE  ListId = @listId
IF @@rowCount = 0 BEGIN
   SET @msg = ''Send list not found.'' + @msgTag + ''>''
   RAISERROR(@msg,16,1)
   RETURN -100
END
ELSE IF NOT EXISTS
   (
   SELECT 1
   FROM   SendList$View
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

IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'sendlist$dissolve')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.sendList$dissolve
(
   @listId int,         -- id of the composite
   @listVersion rowversion
)
WITH ENCRYPTION
AS
BEGIN
DECLARE @msg as nvarchar(255)        -- used to preformat error message
DECLARE @msgTag as nvarchar(255)     -- used to hold first part of error message header
DECLARE @tranName as nvarchar(255)   -- used to hold name of savepoint
DECLARE @rowCount as int
DECLARE @caseId as int
DECLARE @error as int
DECLARE @caseName as nvarchar(32)
DECLARE @listName as nchar(10)
DECLARE @lastList as int
DECLARE @returnValue as int
DECLARE @accountId as int
DECLARE @status as int
DECLARE @count as int

SET NOCOUNT ON

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=P''
SET @tranName = object_name(@@procid) + CAST(@@nestlevel as nvarchar(2))

-- Check concurrency of composite, and verify that it actually is a composite
SELECT @listName = ListName,
       @accountId = AccountId,
       @status = Status
FROM   SendList$View
WHERE  ListId = @listId
IF @@rowCount = 0 BEGIN
   SET @msg = ''Send list not found.'' + @msgTag + ''>''
   RAISERROR(@msg,16,1)
   RETURN -100
END
ELSE IF @accountId IS NOT NULL BEGIN
   SET @msg = ''Send list '''''' + @listName + '''''' is not a composite list.'' + @msgTag + ''>''
   RAISERROR(@msg,16,1)
   RETURN -100
END
ELSE IF NOT EXISTS
   (
   SELECT 1
   FROM   SendList$View
   WHERE  ListId = @listId AND RowVersion = @listVersion
   )
BEGIN
   SET @msg = ''Send list '''''' + @listName + '''''' has been modified since retrieval.'' + @msgTag + ''>''
   RAISERROR(@msg,16,1)
   RETURN -100
END

-- Check for a case that exists on more than one list within the composite.
IF @status != 512 BEGIN
   SELECT TOP 1 @caseId = slic.CaseId
   FROM   SendListItemCase slic
   JOIN   SendListItem sli
     ON   sli.ItemId = slic.ItemId
   JOIN   SendList sl
     ON   sl.ListId = sli.ListId
   WHERE  sl.CompositeId = @listId
   GROUP BY slic.CaseId
   HAVING count(DISTINCT sli.ListId) > 1
   IF @@rowCount > 0 BEGIN
      SELECT @caseName = SerialNo FROM SendListCase WHERE CaseId = @caseId
      SET @msg = ''Cannot extract lists because case '''''' + @caseName + '''''' appears on multiple lists within the composite.'' + @msgTag + ''>''
      RAISERROR(@msg,16,1)
      RETURN -100
   END
END

-- Begin the transaction
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

-- Update all the discretes to have no composite
SET @lastList = 0
WHILE 1 = 1 BEGIN
   SELECT TOP 1 @lastList = ListId
   FROM   SendList
   WHERE  CompositeId = @listId AND
          ListId > @lastList
   ORDER BY ListId ASC
   IF @@rowCount = 0 BEGIN
      BREAK
   END
   ELSE BEGIN
      UPDATE SendList
      SET    CompositeId = NULL
      WHERE  ListId = @lastList
      SET @error = @@error
      IF @error != 0 BEGIN
         ROLLBACK TRANSACTION @tranName
         COMMIT TRANSACTION
         SET @msg = ''Error encountered while dissolving composite send list.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
         EXECUTE error$raise @msg, @error
         RETURN -100
      END
   END
END

-- Commit the transaction
COMMIT TRANSACTION
RETURN 0
END
'
)

IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'sendlist$extract')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.sendList$extract
(
   @listId int,              -- id of the list to be extracted
   @listVersion rowversion,
   @compositeId int,         -- id of the composite
   @compositeVersion rowversion
)
WITH ENCRYPTION
AS
BEGIN
DECLARE @msg as nvarchar(255)        -- used to preformat error message
DECLARE @msgTag as nvarchar(255)     -- used to hold first part of error message header
DECLARE @tranName as nvarchar(255)   -- used to hold name of savepoint
DECLARE @rowCount as int
DECLARE @caseId as int
DECLARE @error as int
DECLARE @listName as nchar(10)
DECLARE @caseName as nvarchar(32)
DECLARE @compositeName as nchar(10)
DECLARE @returnValue as int
DECLARE @status as int

SET NOCOUNT ON

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=P''
SET @tranName = object_name(@@procid) + CAST(@@nestlevel as nvarchar(2))

-- Check concurrency of composite, and verify that it actually is a composite
SELECT @compositeName = ListName,
       @status = Status
FROM   SendList$View 
WHERE  ListId = @compositeId
IF @@rowCount = 0 BEGIN
   SET @msg = ''Send list not found.'' + @msgTag + ''>''
   RAISERROR(@msg,16,1)
   RETURN -100
END
ELSE IF NOT EXISTS
   (
   SELECT 1
   FROM   SendList$View
   WHERE  ListId = @compositeId AND RowVersion = @compositeVersion
   )
BEGIN
   SET @msg = ''Send list '''''' + @compositeName + '''''' has been modified since retrieval.'' + @msgTag + ''>''
   RAISERROR(@msg,16,1)
   RETURN -100
END
ELSE IF EXISTS
   (
   SELECT 1
   FROM   SendList$View
   WHERE  ListId = @compositeId AND AccountId IS NOT NULL
   )
BEGIN
   SET @msg = ''Send list '''''' + @compositeName + '''''' is not a composite list.'' + @msgTag + ''>''
   RAISERROR(@msg,16,1)
   RETURN -100
END

-- Check concurrency of discrete, and verify that it actually belongs to the
-- given composite list
SELECT @listName = ListName
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
   FROM   SendList$View
   WHERE  ListId = @listId AND RowVersion = @listVersion
   )
BEGIN
   SET @msg = ''Send list '''''' + @listName + '''''' has been modified since retrieval.'' + @msgTag + ''>''
   RAISERROR(@msg,16,1)
   RETURN -100
END
ELSE IF NOT EXISTS
   (
   SELECT 1
   FROM   SendList$View
   WHERE  ListId = @listId AND CompositeId = @compositeId
   )
BEGIN
   SET @msg = ''Send list '''''' + @listName + '''''' is not part of composite list '''''' + @compositeName + ''''''.'' + @msgTag + ''>''
   RAISERROR(@msg,16,1)
   RETURN -100
END

-- Check for a case that exists on another list within the composite.
SELECT TOP 1 @caseId = slic.CaseId
FROM   SendListItemCase slic
JOIN   SendListItem sli
  ON   sli.ItemId = slic.ItemId
JOIN   SendList sl
  ON   sl.ListId = sli.ListId
JOIN   (SELECT slic1.CaseId
        FROM   SendListItemCase slic1
        JOIN   SendListItem sli1
          ON   sli1.ItemId = slic1.ItemId
        WHERE  sli1.ListId = @listId) as c
  ON   c.CaseId = slic.CaseId
WHERE  sl.CompositeId = @compositeId
GROUP BY slic.CaseId
HAVING count(DISTINCT sli.ListId) > 1
IF @@rowCount > 0 BEGIN
   SELECT @caseName = SerialNo FROM SendListCase WHERE CaseId = @caseId
   SET @msg = ''Send list '''''' + @listName + '''''' may not be extracted because case '''''' + @caseName + '''''' also appears on another list within the same composite.'' + @msgTag + ''>''
   RAISERROR(@msg,16,1)
   RETURN -100
END


-- Begin the transaction
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

-- Remove the discrete from the composite
UPDATE SendList
SET    CompositeId = NULL
WHERE  ListId = @listId
SET @error = @@error
IF @error != 0 BEGIN
   ROLLBACK TRANSACTION @tranName
   COMMIT TRANSACTION
   SET @msg = ''Error encountered while extracting send list.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
   EXECUTE error$raise @msg, @error
   RETURN -100
END

-- If there are no discretes left in the composite, the composite will have
-- been deleted in the trigger.  Otherwise, update the composite status to 
-- the lowest of its remaining consituents.
SELECT @status = min(Status)
FROM   SendList
WHERE  CompositeId = @compositeId
IF @status IS NOT NULL BEGIN
   UPDATE SendList
   SET    Status = @status
   WHERE  ListId = @compositeId
   SET @error = @@error
   IF @error != 0 BEGIN
      ROLLBACK TRANSACTION @tranName
      COMMIT TRANSACTION
      SET @msg = ''Error encountered while updating status of composite.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
      EXECUTE error$raise @msg, @error
      RETURN -100
   END
END

-- Commit and return
COMMIT TRANSACTION
RETURN 0
END
'
)

IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'sendlist$getbydate')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.sendList$getByDate
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
FROM   SendList$View sl
JOIN   Account a
  ON   a.AccountId = sl.AccountId
WHERE  sl.CompositeId IS NULL AND
       convert(nchar(10),sl.CreateDate,120) = @dateString
UNION
SELECT sl.ListId,
       sl.ListName,
       sl.CreateDate,
       sl.Status,
       '''',
       sl.RowVersion
FROM   SendList$View sl
WHERE  sl.AccountId IS NULL AND
       EXISTS(SELECT 1 
              FROM   SendList$View sl2
              WHERE  CompositeId = sl.ListId AND
                     convert(nchar(10),sl2.CreateDate,120) = @dateString)
ORDER BY ListName Desc
END
'
)

IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'sendlist$getbyid')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.sendList$getById
(
   @id int
)
WITH ENCRYPTION
AS
BEGIN

SET NOCOUNT ON

-- Select the list
SELECT sl.ListId,
       sl.ListName,
       sl.CreateDate,
       sl.Status,
       coalesce(a.AccountName,'''') as ''AccountName'',
       sl.RowVersion
FROM   SendList$View sl
LEFT 
OUTER 
JOIN   Account a
  ON   a.AccountId = sl.AccountId
WHERE  sl.ListId = @id

-- If the list is a composite then get the child lists as well
IF EXISTS(SELECT 1 FROM SendList WHERE CompositeId = @id) BEGIN
   SELECT sl.ListId,
          sl.ListName,
          sl.CreateDate,
          sl.Status,
          a.AccountName,
          sl.RowVersion
   FROM   SendList$View sl
   JOIN   Account a
     ON   a.AccountId = sl.AccountId
   WHERE  sl.CompositeId = @id
   ORDER BY sl.ListName
END

END
'
)

IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'sendlist$getbyitem')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.sendList$getByItem
(
   @itemId int
)
WITH ENCRYPTION
AS
BEGIN
DECLARE @compositeId int

SET NOCOUNT ON

SELECT @compositeId = sl.CompositeId
FROM   SendList$View sl
JOIN   SendListItem sli
  ON   sli.ListId = sl.ListId
WHERE  sli.ItemId = @itemId AND sl.CompositeId IS NOT NULL

IF @@rowcount = 0 BEGIN
   SELECT sl.ListId,
          sl.ListName,
          sl.CreateDate,
          sl.Status,
          a.AccountName,
          sl.RowVersion
   FROM   SendList$View sl
   JOIN   SendListItem sli
     ON   sli.ListId = sl.ListId
   JOIN   Account a
     ON   a.AccountId = sl.AccountId
   WHERE  sli.ItemId = @itemId
END
ELSE BEGIN
   SELECT sl.ListId,
          sl.ListName,
          sl.CreateDate,
          sl.Status,
          '''' as ''AccountName'',
          sl.RowVersion
   FROM   SendList$View sl
   WHERE  sl.ListId = @compositeId
   -- Get the kids
   SELECT sl.ListId,
          sl.ListName,
          sl.CreateDate,
          sl.Status,
          a.AccountName,
          sl.RowVersion
   FROM   SendList$View sl
   JOIN   Account a
     ON   a.AccountId = sl.AccountId
   WHERE  sl.CompositeId = @compositeId
   ORDER BY sl.ListName ASC
END

END
'
)

IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'sendlist$getbymedium')
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
FROM   SendList$View sl
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
      FROM   SendList$View sl
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
      FROM   SendList$View sl
      WHERE  sl.ListId = @compositeId
      -- Get the child lists
      SELECT sl.ListId,
             sl.ListName,
             sl.CreateDate,
             sl.Status,
             a.AccountName,
             sl.RowVersion
      FROM   SendList$View sl
      JOIN   Account a
        ON   a.AccountId = sl.AccountId
      WHERE  sl.CompositeId = @compositeId
      ORDER BY sl.ListName ASC
   END
END

END
'
)

IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'sendlist$getbyname')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.sendList$getByName
(
   @listName nchar(10)
)
WITH ENCRYPTION
AS
BEGIN
DECLARE @id int

SET NOCOUNT ON

-- Select the list
SELECT sl.ListId,
       sl.ListName,
       sl.CreateDate,
       sl.Status,
       coalesce(a.AccountName,'''') as ''AccountName'',
       sl.RowVersion
FROM   SendList$View sl
LEFT 
OUTER 
JOIN   Account a
  ON   a.AccountId = sl.AccountId
WHERE  sl.ListName = @listName

-- If the list is a composite then get the child lists as well
SELECT @id = ListId 
FROM   SendList$View 
WHERE  ListName = @listName

IF EXISTS(SELECT 1 FROM SendList WHERE CompositeId = @id) BEGIN
   SELECT sl.ListId,
          sl.ListName,
          sl.CreateDate,
          sl.Status,
          a.AccountName,
          sl.RowVersion
   FROM   SendList$View sl
   JOIN   Account a
     ON   a.AccountId = sl.AccountId
   WHERE  sl.CompositeId = @id
   ORDER BY sl.ListName
END

END
'
)

IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'sendlist$getbystatusanddate')
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
FROM   SendList$View sl
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
FROM   SendList$View sl
WHERE  sl.AccountId IS NULL And
       EXISTS (SELECT 1 
               FROM   SendList$View sl2
               WHERE  CompositeId = sl.ListId And 
                      sl2.Status = (sl2.Status & @Status) And 
                      convert(nchar(10),sl2.CreateDate,120) = @dateString)
ORDER  BY ListName Desc

END
'
)

IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'sendlist$getcases')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.sendList$getCases
(
   @listId int
)
WITH ENCRYPTION
AS
BEGIN

SET NOCOUNT ON

-- Select the cases on list
SELECT distinct slc.CaseId,
       mt.TypeName,
       slc.SerialNo as ''CaseName'',
       coalesce(convert(nvarchar(10),slc.ReturnDate,120),'''') as ''ReturnDate'',
       slc.Sealed,
       slc.Notes,
       slc.RowVersion
FROM   SendListCase slc
JOIN   SendListItemCase slic
  ON   slic.CaseId = slc.CaseId
JOIN   SendListItem sli
  ON   sli.ItemId = slic.ItemId
JOIN   SendList$View sl
  ON   sl.ListId = sli.ListId
JOIN   MediumType mt
  ON   mt.TypeId = slc.TypeId
WHERE  sl.ListId = @listId OR coalesce(CompositeId,0) = @listId

END
'
)

IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'sendlist$getcleared')
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
FROM   SendList$View sl
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
FROM   SendList$View sl
WITH  (NOLOCK)
WHERE  sl.Status = 512 AND 
       sl.AccountId IS NULL AND
       EXISTS(SELECT 1 
              FROM   SendList$View sl2
              WHERE  CompositeId = sl.ListId AND
                     convert(nchar(10),sl2.CreateDate,120) <= @dateString)
ORDER BY ListName Asc
END
'
)

IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'sendlist$getitemcount')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.sendList$getItemCount
(
   @listId int,
   @status int -- -1 = all items, else a certain status
)
WITH ENCRYPTION
AS
BEGIN

SET NOCOUNT ON

-- Select the items on list
IF @status = -1 BEGIN
   SELECT count(*)
   FROM   SendListItem sli
   JOIN   SendList$View sl
     ON   sl.ListId = sli.ListId
   WHERE  sli.Status != 1 AND -- power(4,0)
         (sl.ListId = @listId OR sl.CompositeId = @listId)
END
ELSE BEGIN
   SELECT count(*)
   FROM   SendListItem sli
   JOIN   SendList$View sl
     ON   sl.ListId = sli.ListId
   WHERE  sli.Status = @status AND
         (sl.ListId = @listId OR sl.CompositeId = @listId)
END

END
'
)

IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'sendlist$getitems')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.sendList$getItems
(
   @listId int
)
WITH ENCRYPTION
AS
BEGIN

SET NOCOUNT ON

-- Select the items on list
SELECT sli.ItemId,
       sli.Status,
       coalesce(convert(nvarchar(10),coalesce(c.ReturnDate,sli.ReturnDate),120),'''') as ''ReturnDate'',
       m.Notes,
       m.SerialNo,
       coalesce(c.CaseName,'''') as ''CaseName'',
       sli.RowVersion
FROM   SendListItem sli
JOIN   SendList$View sl
  ON   sl.ListId = sli.ListId
JOIN   Medium m
  ON   m.MediumId = sli.MediumId
LEFT
OUTER
JOIN   (SELECT slc.SerialNo as ''CaseName'',
               slic.ItemId as ''ItemId'',
               case slc.Sealed when 0 then null else slc.ReturnDate end as ''ReturnDate''
        FROM   SendListCase slc
        JOIN   SendListItemCase slic
          ON   slic.CaseId = slc.CaseId) as c
  ON    c.ItemId = sli.ItemId
WHERE  sl.ListId = @listId OR sl.CompositeId = @listId
ORDER BY m.SerialNo

END
'
)

IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'sendlist$getpage')
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
SET @tables = ''SendList$View sl LEFT OUTER JOIN Account a ON sl.AccountId = a.AccountId''

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

IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'sendlist$merge')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.sendList$merge
(
   @listId1 int,
   @rowVersion1 rowVersion,
   @listId2 int,
   @rowVersion2 rowVersion,
   @compositeId int OUTPUT     -- id of composite list
)
WITH ENCRYPTION
AS
BEGIN
DECLARE @msg as nvarchar(255)        -- used to preformat error message
DECLARE @msgTag as nvarchar(255)     -- used to hold first part of error message header
DECLARE @tranName as nvarchar(255)   -- used to hold name of savepoint
DECLARE @rowCount as int
DECLARE @error as int
DECLARE @accountId1 as int
DECLARE @accountId2 as int
DECLARE @status1 as int
DECLARE @status2 as int
DECLARE @listName1 as nchar(10)
DECLARE @listName2 as nchar(10)
DECLARE @returnValue as int
DECLARE @compositeName as nchar(10)

SET NOCOUNT ON

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=P''
SET @tranName = object_name(@@procid) + CAST(@@nestlevel as nvarchar(2))

-- Get the name of the first list and test its concurrency.  Also make sure
-- that it is not a discrete list currently belonging to another composite.
SELECT @status1 = Status,
       @listName1 = ListName,
       @accountId1 = AccountId
FROM   SendList$View 
WHERE  ListId = @listId1
IF @@rowCount = 0 BEGIN
   SET @msg = ''Send list not found.'' + @msgTag + ''>''
   RAISERROR(@msg,16,1)
   RETURN -100
END
ELSE IF NOT EXISTS
   (
   SELECT 1
   FROM   SendList$View
   WHERE  ListId = @listId1 AND RowVersion = @rowVersion1
   )
BEGIN
   SET @msg = ''Send list '''''' + @listName1 + '''''' has been modified since retrieval.'' + @msgTag + ''>''
   RAISERROR(@msg,16,1)
   RETURN -100
END
ELSE IF EXISTS
   (
   SELECT 1 
   FROM   SendList$View
   WHERE  ListId = @listId1 AND CompositeId IS NOT NULL
   )
BEGIN
   SET @msg = ''List '''''' + @listName1 + '''''' must first be extracted from its current composite.'' + @msgTag + ''>''
   RAISERROR(@msg,16,1)
   RETURN -100
END

-- Get the name of the second list and test its concurrency.  Also make sure
-- that it is not a discrete list currently belonging to another composite.
SELECT @status2 = Status,
       @listName2 = ListName,
       @accountId2 = AccountId
FROM   SendList$View
WHERE  ListId = @listId2
IF @@rowCount = 0 BEGIN
   SET @msg = ''Send list not found.'' + @msgTag + ''>''
   RAISERROR(@msg,16,1)
   RETURN -100
END
ELSE IF NOT EXISTS
   (
   SELECT 1
   FROM   SendList$View
   WHERE  ListId = @listId2 AND RowVersion = @rowVersion2
   )
BEGIN
   SET @msg = ''Send list '''''' + @listName2 + '''''' has been modified since retrieval.'' + @msgTag + ''>''
   RAISERROR(@msg,16,1)
   RETURN -100
END
ELSE IF EXISTS
   (
   SELECT 1 
   FROM   SendList$View
   WHERE  ListId = @listId2 AND CompositeId IS NOT NULL
   )
BEGIN
   SET @msg = ''List '''''' + @listName2 + '''''' must first be extracted from its current composite.'' + @msgTag + ''>''
   RAISERROR(@msg,16,1)
   RETURN -100
END

-- There are three possibilites.  Either we have (a) two discrete lists, or
-- (b) two composite lists, or (c) one of each.  In case (a) we create a new 
-- composite list and attach the two discretes to it.  In case (b) we take
-- all of the discrete lists from the list with the lower number, move
-- them into the other composite, and delete the now empty composite.  In
-- case (c) we merge the discrete into the existing composite.

-- Begin the transaction
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

-- If we have two discrete lists, create a composite and merge the two
-- discrete lists into it.
IF @accountId1 IS NOT NULL AND @accountId2 IS NOT NULL BEGIN
   -- Create the composite send list
   EXEC @returnValue = sendList$create NULL, @compositeName OUT
   IF @returnValue != 0 BEGIN
      ROLLBACK TRANSACTION @tranName
      COMMIT TRANSACTION
      RETURN -100
   END
   ELSE BEGIN
      SELECT @compositeId = ListId
      FROM   SendList
      WHERE  ListName = @compositeName
   END
   -- Assign the the two discretes to the new composite
   UPDATE SendList
   SET    CompositeId = @compositeId
   WHERE  ListId IN (@listId1, @listId2)
   SET @error = @@error
   IF @error != 0 BEGIN
      ROLLBACK TRANSACTION @tranName
      COMMIT TRANSACTION
      SET @msg = ''Error encountered while merging lists into composite.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
      EXECUTE error$raise @msg, @error
      RETURN -100
   END 
END
-- If we have two composites, move all the discrete that belong to the 
-- lower numbered composite to the higher numbered composite.  Then
-- delete the lower numbered composite.
ELSE IF @accountId1 IS NULL AND @accountId2 IS NULL BEGIN
   -- Get the id of the surviving composite
   SELECT @compositeId = dbo.int$max(@listId1,@listId2)
   -- Take all the discretes from the lower and assign to the higher
   UPDATE SendList
   SET    CompositeId = @compositeId
   WHERE  CompositeId = dbo.int$min(@listId1,@listId2)
   SET @error = @@error
   IF @error != 0 BEGIN
      ROLLBACK TRANSACTION @tranName
      COMMIT TRANSACTION
      SET @msg = ''Error encountered while merging lists from two composite send lists.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
      EXECUTE error$raise @msg, @error
      RETURN -100
   END 
   -- Delete the now empty composite list record
   IF @listId1 < @listId2
      EXECUTE @returnValue = sendList$del @listId1, @rowVersion1
   ELSE
      EXECUTE @returnValue = sendList$del @listId2, @rowVersion2
   IF @returnValue != 0 BEGIN
      ROLLBACK TRANSACTION @tranName
      COMMIT TRANSACTION
      RETURN -100
   END 
END
-- If we have one discrete and one composite, merge the discrete
-- into the composite.
ELSE BEGIN
   SELECT @compositeId = ListId
   FROM   SendList 
   WHERE  AccountId IS NULL AND 
          ListId IN (@listId1,@listId2)
   UPDATE SendList
   SET    CompositeId = @compositeId
   WHERE  ListId = (SELECT ListId
                    FROM   SendList
                    WHERE  ListId != @compositeId AND
                           ListId IN (@listId2, @listId2))
   SET @error = @@error
   IF @error != 0 BEGIN
      ROLLBACK TRANSACTION @tranName
      COMMIT TRANSACTION
      SET @msg = ''Error encountered while merging a discrete send list into an existing composite.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
      EXECUTE error$raise @msg, @error
      RETURN -100
   END 
END

-- Set the status of the composite list
UPDATE SendList
SET    Status = dbo.int$min(@status1,@status2)
WHERE  ListId = @compositeId
SET @error = @@error
IF @error != 0 BEGIN
   ROLLBACK TRANSACTION @tranName
   COMMIT TRANSACTION
   SET @msg = ''Error encountered while setting status of new composite list.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
   EXECUTE error$raise @msg, @error
   RETURN -100
END 

-- Commit the transaction
COMMIT TRANSACTION
RETURN 0
END
'
)

IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'sendlist$transit')
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
FROM   SendList$View
WHERE  ListId = @listId AND RowVersion = @rowVersion
IF @@rowCount = 0 BEGIN
   IF EXISTS(SELECT 1 FROM SendList$View WHERE ListId = @listId) BEGIN
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

IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'sendlist$transmit')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.sendList$transmit
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
DECLARE @listName nchar(10)
DECLARE @lastItem int
DECLARE @rowCount int
DECLARE @status int
DECLARE @error int

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=P''
SET @tranName = object_name(@@procid) + CAST(@@nestlevel as nvarchar(2))

-- If the status of the list is already transmitted, then return.  Otherwise,
-- if it is anything besides submitted, raise error.
SELECT @listName = ListName,
       @status = Status
FROM   SendList$View
WHERE  ListId = @listId AND
       RowVersion = @rowVersion
IF @@rowCount = 0 BEGIN
   IF EXISTS(SELECT 1 FROM SendList$View WHERE ListId = @listId) BEGIN
      SET @msg = ''List has been modified since retrieval.'' + @msgTag + ''>''
      RAISERROR(@msg,16,1)
      RETURN -100
   END
   ELSE BEGIN
      SET @msg = ''List not found.'' + @msgTag + ''>''
      RAISERROR(@msg,16,1)
      RETURN -100
   END
END

-- If already transmitted, just return
IF @status >= 16 RETURN 0

-- Otherwise, make sure the list is eligible for transmission
IF dbo.bit$StatusEligible(1,@status,16) = 0 BEGIN
   SET @msg = ''List '' + @listName + '' is not currently eligible for transmission.'' + @msgTag + ''>''
   RAISERROR(@msg,16,1)
   RETURN -100
END

-- Upgrade the status of all the unremoved items on the list to transmitted
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

SET @lastItem = 0
WHILE 1 = 1 BEGIN
   SELECT TOP 1 @lastItem = sli.ItemId
   FROM   SendListItem sli
   JOIN   SendList sl
     ON   sl.ListId = sli.ListId
   WHERE  sli.Status != 1 AND
          sli.ItemId > @lastItem AND
         (sl.ListId = @listId OR sl.CompositeId = @listId)
   ORDER BY sli.ItemId ASC
   IF @@rowCount = 0 BEGIN
      BREAK
   END
   ELSE BEGIN
      UPDATE SendListItem
      SET    Status = 16
      WHERE  ItemId = @lastItem
      SET @error = @@error
      IF @error != 0 BEGIN
         ROLLBACK TRANSACTION @tranName
         COMMIT TRANSACTION
         SET @msg = ''Error encountered while upgrading send list item to transmitted.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
         EXECUTE error$raise @msg, @error
         RETURN -100
      END
   END
END

-- Commit and return
COMMIT TRANSACTION
RETURN 0
END
'
)

IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'sendlistcase$getmedia')
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
FROM   Medium$View m 
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

IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'sendlistitem$add')
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
FROM   SendList$View
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

IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'sendlistitem$get')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.sendListItem$get
(
   @itemId int
)
WITH ENCRYPTION
AS
BEGIN

SET NOCOUNT ON

SELECT sli.ItemId,
       sli.Status,
       coalesce(convert(nvarchar(10),coalesce(c.ReturnDate,sli.ReturnDate),120),'''') as ''ReturnDate'',
       m.Notes,
       m.SerialNo,
       coalesce(c.CaseName,'''') as ''CaseName'',
       sli.RowVersion
FROM   SendListItem sli
JOIN   Medium$View m
  ON   m.MediumId = sli.MediumId
LEFT
OUTER
JOIN   (SELECT slc.SerialNo as ''CaseName'',
               slic.ItemId as ''ItemId'',
               case slc.Sealed when 0 then null else slc.ReturnDate end as ''ReturnDate''
        FROM   SendListCase slc
        JOIN   SendListItemCase slic
          ON   slic.CaseId = slc.CaseId) as c
  ON    c.ItemId = sli.ItemId
WHERE  sli.ItemId = @itemId

END
'
)

IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'sendlistitem$getbymedium')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.sendListItem$getByMedium
(
   @serialNo nvarchar(64)
)
WITH ENCRYPTION
AS
BEGIN

SET NOCOUNT ON

SELECT sli.ItemId,
       sli.Status,
       coalesce(convert(nvarchar(10),coalesce(c.ReturnDate,sli.ReturnDate),120),'''') as ''ReturnDate'',
       m.Notes,
       m.SerialNo,
       coalesce(c.CaseName,'''') as ''CaseName'',
       sli.RowVersion
FROM   SendListItem sli
JOIN   Medium$View m
  ON   m.MediumId = sli.MediumId
LEFT
OUTER
JOIN   (SELECT slc.SerialNo as ''CaseName'',
               slic.ItemId as ''ItemId'',
               case slc.Sealed when 0 then null else slc.ReturnDate end as ''ReturnDate''
        FROM   SendListCase slc
        JOIN   SendListItemCase slic
          ON   slic.CaseId = slc.CaseId) as c
  ON    c.ItemId = sli.ItemId
WHERE  m.SerialNo = @serialNo AND sli.Status NOT IN (1,1024)

END
'
)

IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'sendlistitem$getpage')
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
SET @fields2 = ''ItemId, SerialNo, AccountName, Status, ReturnDate, CaseName, Notes, RowVersion, MediumType''
SET @fields1 = ''sli.ItemId, m.SerialNo, a.AccountName, sli.Status, coalesce(c.ReturnDate,coalesce(convert(nvarchar(10),sli.ReturnDate,120),'''''''')) as ''''ReturnDate'''', coalesce(c.CaseName,'''''''') as ''''CaseName'''', sli.Notes, sli.RowVersion, MediumType = t.TypeName''

-- Construct the tables string
SET @tables = ''SendListItem sli JOIN SendList$View sl ON sl.ListId = sli.ListId JOIN Medium m ON m.MediumId = sli.MediumId JOIN MediumType t ON t.TypeId = m.TypeId JOIN Account a ON a.AccountId = m.AccountId LEFT OUTER JOIN (SELECT slc.SerialNo as ''''CaseName'''', slic.ItemId as ''''ItemId'''', case slc.Sealed when 0 then null else coalesce(convert(nvarchar(10),slc.ReturnDate,120),'''''''') end as ''''ReturnDate'''' FROM SendListCase slc JOIN SendListItemCase slic ON slic.CaseId = slc.CaseId JOIN SendListItem sli ON sli.ItemId = slic.ItemId JOIN SendList sl ON sl.ListId = sli.ListId WHERE sl.ListId = '' + cast(@listId as nvarchar(50)) + '' OR sl.CompositeId = '' + cast(@listId as nvarchar(50)) + '') as c ON c.ItemId = sli.ItemId''

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

IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'sendlistitem$ins')
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
FROM   Medium$View
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

IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'sendlistitem$verify')
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
JOIN   SendList$View s
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
   FROM   SendList$View
   WHERE  ListId = @id AND CompositeId IS NOT NULL
   ) 
BEGIN
   SELECT @id = ListId, 
          @status2 = Status
   FROM   SendList$View
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

IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'barcodepattern$getdefaults')
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

SELECT TOP 1 
       @typeName = m.TypeName,
       @accountName = a.AccountName
FROM   BarCodePattern b
WITH  (NOLOCK INDEX(akBarCodePattern$Position))
JOIN   MediumType m
  ON   m.TypeId = b.TypeId
JOIN   Account$View a
  ON   a.AccountId = b.AccountId
WHERE  dbo.bit$RegexMatch(@serialNo,b.Pattern) = 1
ORDER  BY b.Position ASC

-- If no format, raise error
IF @@rowcount = 0 BEGIN
   SET @msgTag = ''<'' + object_name(@@procid) + '';Type=P''
   SET @msg = ''No default bar code pattern found.'' + @msgTag + ''>''
   RAISERROR(@msg,16,1)
   RETURN -100
END

-- Return
RETURN 0
END
'
)

IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'inventoryConflict$getPage')
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
SET @tables = ''InventoryConflict i JOIN Medium$View m ON m.SerialNo = i.SerialNo JOIN (SELECT Id, case Type when 1 then ''''Enterprise claims residence of medium'''' when 2 then ''''Enterprise denies residence of medium'''' when 3 then ''''Vault claims residence of medium'''' when 4 then ''''Vault denies residence of medium'''' end as ''''Details'''', 1 as ''''ConflictType'''' FROM InventoryConflictLocation UNION SELECT o.Id, ''''Vault asserts serial number should be of type '''' + t.TypeName as ''''Details'''', 2 as ''''ConflictType'''' FROM InventoryConflictObjectType o JOIN MediumType t ON t.TypeId = o.TypeId UNION SELECT Id, case Type when 0 then ''''Vault claims residence of unrecognized '''' + case Container when 0 then ''''medium'''' else ''''sealed case'''' end when 1 then ''''Enterprise claims residence of unrecognized medium'''' end as ''''Details'''', 3 as ''''ConflictType'''' FROM InventoryConflictUnknownSerial UNION SELECT c.Id, case c.Type when 0 then ''''Vault asserts that medium should belong to account '''' + a.AccountName when 1 then ''''Enterprise asserts that medium should belong to account '''' + a.AccountName end as ''''Details'''', 4 as ''''ConflictType'''' FROM InventoryConflictAccount c JOIN Account a ON a.AccountId = c.AccountId) as x ON x.Id = i.Id''

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

IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'audittrail$getpage')
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
         SET @tables = ''(SELECT a1.* FROM XAccount a1 JOIN Account$View a2 ON a2.AccountName = a1.Object) as a1''
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
         SET @tables = ''
                       (
                       SELECT s1.* FROM XSendList s1 JOIN SendList$View s2 ON s2.ListName = s1.Object
                       UNION
                       SELECT s1.* FROM XSendListItem s1 JOIN SendList$View s2 ON s2.ListName = s1.Object
                       UNION
                       SELECT s1.* FROM XSendListCase s1 JOIN SendList$View s2 ON s2.ListName = s1.Object
                       )
                       AS s1
                       ''
         SET @fields1 = ''ItemId, Date, Object, Action, Detail, Login, '' + @auditType
      END
      ELSE IF power(2,@i) = @RECEIVELIST BEGIN
         SET @tables = ''
                       (
                       SELECT r1.* FROM XReceiveList r1 JOIN ReceiveList$View r2 ON r2.ListName = r1.Object
                       UNION
                       SELECT r1.* FROM XReceiveListItem r1 JOIN ReceiveList$View r2 ON r2.ListName = r1.Object
                       )
                       AS r1
                       ''
         SET @fields1 = ''ItemId, Date, Object, Action, Detail, Login, '' + @auditType
      END
      ELSE IF power(2,@i) = @DISASTERCODELIST BEGIN
         SET @tables = ''
                       (
                       SELECT c1.* FROM XDisasterCodeList c1 JOIN DisasterCodeList$View c2 ON c2.ListName = c1.Object
                       UNION
                       SELECT c1.* FROM XDisasterCodeListItem c1 JOIN DisasterCodeList$View c2 ON c2.ListName = c1.Object
                       )
                       AS c1
                       ''
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
         SET @tables = ''(SELECT m1.* FROM XMedium m1 JOIN Medium$View m2 ON m2.SerialNo = m1.Object) as m1''
         SET @fields1 = ''ItemId, Date, Object, Action, Detail, Login, '' + @auditType
      END
      ELSE IF power(2,@i) = @MEDIUMMOVEMENT BEGIN
         SET @tables = ''(SELECT m1.* FROM XMediumMovement m1 JOIN Medium$View m2 ON m2.SerialNo = m1.Object) as m2''
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

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'medium$addDynamic')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.medium$addDynamic
(
   @serialNo nvarchar(32),
   @location bit,
   @newId int OUTPUT
)
WITH ENCRYPTION
AS
BEGIN
DECLARE @error as int
DECLARE @rowCount as int
DECLARE @accountName as nvarchar(256)
DECLARE @typeName as nvarchar(128)
DECLARE @returnValue as int
DECLARE @e1 as nvarchar(1000)

SET NOCOUNT ON

-- Get the account and medium type
EXECUTE @returnValue = barCodePattern$GetDefaults @serialNo, @typeName OUT, @accountName OUT
IF @returnValue != 0 RETURN -100

-- Does it exist?
IF EXISTS (SELECT 1 FROM Medium WHERE SerialNo = @serialNo) BEGIN
   IF NOT EXISTS (SELECT 1 FROM Medium$View WHERE SerialNo = @serialNo) BEGIN
      SET @e1 = ''Serial number '' + @serialNo + '' already exists, possibly under an account to which you do not have access''
      RAISERROR(@e1, 16, 1)
      RETURN -100   
   END
END

-- Insert a medium record
EXECUTE @returnValue = medium$ins @serialNo, @location, 0, NULL, '''', '''', @typeName, @accountName, @newId OUT
IF @returnValue != 0 
   RETURN -100
ELSE
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
LEFT   JOIN InventoryItem x
  ON   x.SerialNo = m.SerialNo AND x.InventoryId = i.InventoryId
LEFT   JOIN MediumSealedCase c
  ON   c.MediumId = m.MediumId
WHERE  x.SerialNo IS NULL
  AND  m.Missing = 0
  AND  m.Location = 0
  AND  c.MediumId IS NULL

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

END
GO

-------------------------------------------------------------------------------
--
-- Version update
--
-------------------------------------------------------------------------------
IF dbo.bit$doScript('1.4.1') = 1 BEGIN

IF NOT EXISTS(SELECT 1 FROM DatabaseVersion WHERE Major = 1 AND Minor = 4 AND Revision = 1) BEGIN
   DECLARE @x nvarchar(1000)
   EXECUTE spidLogin$ins 'System', 'Insert database version'
   INSERT DatabaseVersion (Major, Minor, Revision) VALUES (1, 4, 1)
   EXECUTE spidLogin$del
END

END
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
