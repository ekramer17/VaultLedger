SET NOCOUNT ON

-- Should we run this script?
IF dbo.bit$doScript('1.3.8') = 1 BEGIN

DECLARE @CREATE nvarchar(10)
DECLARE @i int

BEGIN TRANSACTION

-------------------------------------------------------------------------------
--
-- Drop all the bar code literals
--
-------------------------------------------------------------------------------
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'barcodepattern')
EXEC
(
'
DECLARE @x int
DECLARE @i int
SET @x = 1000000
SET @i = 1

-- Disable the triggers on the bar code pattern table
ALTER TABLE BarCodePattern DISABLE TRIGGER ALL

-- Delete the bar code patterns not in @tbl1 (MUST use NOT IN)
DELETE BarCodePattern 
WHERE  Pattern NOT IN (SELECT Pattern FROM BarCodePattern WHERE PATINDEX(''%[^A-Z0-9a-z]%'', Pattern) != 0)

-- Enlarge the positions to eliminate duplicates
UPDATE BarCodePattern SET Position = Position + @x

-- Set the positions
WHILE 1 = 1 BEGIN
   UPDATE BarCodePattern
   SET    Position = @i
   WHERE  Position = (SELECT min(Position) FROM BarCodePattern WHERE Position > @x)
   IF @@rowcount = 0 BREAK
   SET @i = @i + 1
END

-- Enable the triggers on the bar code pattern table
ALTER TABLE BarCodePattern ENABLE TRIGGER ALL
'
)

-------------------------------------------------------------------------------
--
-- Do the same for case patterns
--
-------------------------------------------------------------------------------
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'barcodepatterncase')
EXEC
(
'
DECLARE @x int
DECLARE @i int
SET @x = 1000000
SET @i = 1

-- Disable the triggers on the bar code pattern table
ALTER TABLE BarCodePatternCase DISABLE TRIGGER ALL

-- Delete the bar code patterns not in @tbl1 (MUST use NOT IN)
DELETE BarCodePatternCase
WHERE  Pattern NOT IN (SELECT Pattern FROM BarCodePatternCase WHERE PATINDEX(''%[^A-Z0-9a-z]%'', Pattern) != 0)

-- Enlarge the positions to eliminate duplicates
UPDATE BarCodePatternCase SET Position = Position + @x

-- Set the positions
WHILE 1 = 1 BEGIN
   UPDATE BarCodePatternCase
   SET    Position = @i
   WHERE  Position = (SELECT min(Position) FROM BarCodePatternCase WHERE Position > @x)
   IF @@rowcount = 0 BREAK
   SET @i = @i + 1
END

-- Enable the triggers on the bar code pattern table
ALTER TABLE BarCodePatternCase ENABLE TRIGGER ALL
'
)

-------------------------------------------------------------------------------
--
-- Drop procedures no longer used
--
-------------------------------------------------------------------------------
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'barcodepattern$createliteral')
   EXECUTE ('DROP PROCEDURE dbo.barcodepattern$createliteral')

IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'barcodepattern$synchronizeget')
   EXECUTE ('DROP PROCEDURE dbo.barcodepattern$synchronizeget')

IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'barcodepattern$synchronizeliterals')
   EXECUTE ('DROP PROCEDURE dbo.barcodepattern$synchronizeliterals')

IF @@error != 0 GOTO ROLL_IT -- Rollback on error

-------------------------------------------------------------------------------
--
-- Procedure: barCodePattern$getDefaults
--
-------------------------------------------------------------------------------
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

SELECT TOP 1 
       @typeName = m.TypeName,
       @accountName = a.AccountName
FROM   BarCodePattern b
WITH  (NOLOCK INDEX(akBarCodePattern$Position))
JOIN   MediumType m
  ON   m.TypeId = b.TypeId
JOIN   Account a
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

IF @@error != 0 GOTO ROLL_IT -- Rollback on error

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
   @literals bit = 1   -- As of this version this is an obsolete parameter
)
WITH ENCRYPTION
AS
BEGIN

SET NOCOUNT ON

-- Select
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
ORDER  BY p.Position ASC

RETURN 0
END
'
)

IF @@error != 0 GOTO ROLL_IT

-------------------------------------------------------------------------------
--
-- Procedure: barCodePattern$synchronize
--
-------------------------------------------------------------------------------
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'barCodePattern$synchronize')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.barCodePattern$synchronize
(
   @everyTape bit = 1
)
WITH ENCRYPTION
AS
BEGIN
declare @tranName nvarchar(255)   -- used to hold name of savepoint
declare @s nvarchar(256)
declare @id int
declare @t int
declare @a int
declare @t1 int
declare @a1 int

-- Initialize
SET @id = -1

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @tranName = object_name(@@procid) + CAST(trigger_nestlevel(@@procid) as nvarchar(2))

-- Loop through the media
WHILE 1 = 1 BEGIN
   IF @everyTape = 1 BEGIN
      SELECT TOP 1
             @id = MediumId,
             @a = AccountId,
             @s = SerialNo,
             @t = TypeId
      FROM   Medium
      WHERE  MediumId > @id
      ORDER  BY MediumId ASC
   END
   ELSE BEGIN
      SELECT TOP 1
             @id = m.MediumId,
             @a = m.AccountId,
             @s = m.SerialNo,
             @t = m.TypeId
      FROM   Medium m
      LEFT   JOIN BarCodePattern p
        ON   p.TypeId = m.TypeId
      WHERE  MediumId > @id AND p.TypeId IS NULL
      ORDER  BY MediumId ASC
   END
   -- If no more media then break
   IF @@rowcount = 0 BREAK
   -- Find the bar code pattern
   SELECT TOP 1 @t1 = TypeId, @a1 = AccountId
   FROM   BarCodePattern
   WHERE  dbo.bit$RegexMatch(@s, Pattern) = 1
   -- If the medium type or account don''t match, update medium
   IF @t != @t1 OR @a != @a1 BEGIN
      -- Begin transaction
      BEGIN TRANSACTION
      SAVE TRANSACTION @tranName
      -- Update the medium
      UPDATE Medium
      SET    TypeId = @t1,
             AccountId = @a1
      WHERE  MediumId = @id
      -- Roll back if error, but keep going
      IF @@error != 0 BEGIN
         ROLLBACK TRAN @tranName
      END
      ELSE BEGIN
         COMMIT TRANSACTION
      END
   END
END

-- Return
RETURN 0
END
'
)

IF @@error != 0 GOTO ROLL_IT

-------------------------------------------------------------------------------
--
-- Procedure: barCodePatternCase$synchronize
--
-------------------------------------------------------------------------------
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'barCodePatternCase$synchronize')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.barCodePatternCase$synchronize
(
   @everyCase bit = 1
)
WITH ENCRYPTION
AS
BEGIN
declare @tranName nvarchar(255)   -- used to hold name of savepoint
declare @s nvarchar(256)
declare @id int
declare @i int
declare @t int
declare @t1 int
declare @x bit

-- Initialize
SET @id = -1

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @tranName = object_name(@@procid) + CAST(trigger_nestlevel(@@procid) as nvarchar(2))

-- Loop through the sealed cases
WHILE 1 = 1 BEGIN
   IF @everyCase = 1 BEGIN
      SELECT TOP 1
             @id = CaseId,
             @s = SerialNo,
             @t = TypeId
      FROM   SealedCase
      WHERE  CaseId > @id
      ORDER  BY CaseId ASC
   END
   ELSE BEGIN
      SELECT TOP 1
             @id = c.CaseId,
             @s = c.SerialNo,
             @t = c.TypeId
      FROM   SealedCase c
      LEFT   JOIN BarCodePatternCase p
        ON   p.TypeId = c.TypeId
      WHERE  CaseId > @id AND p.TypeId IS NULL
      ORDER  BY CaseId ASC
   END
   -- If no more cases then break
   IF @@rowcount = 0 BREAK
   -- Find the bar code pattern
   SELECT TOP 1 @t1 = TypeId
   FROM   BarCodePatternCase
   WHERE  dbo.bit$RegexMatch(@s, Pattern) = 1
   -- If the type doesn''t match, update case
   IF @t != @t1 BEGIN
      -- Begin transaction
      BEGIN TRANSACTION
      SAVE TRANSACTION @tranName
      -- Update the case
      UPDATE SealedCase
      SET    TypeId = @t1
      WHERE  CaseId = @id
      -- Roll back if error, but keep going
      IF @@error != 0 BEGIN
         ROLLBACK TRAN @tranName
      END
      ELSE BEGIN
         COMMIT TRANSACTION
      END
   END
END

-- Reset id number
SET @id = -1

-- Loop through the send list cases
WHILE 1 = 1 BEGIN
   IF @everyCase = 1 BEGIN
      SELECT TOP 1
             @id = CaseId,
             @s = SerialNo,
             @t = TypeId
      FROM   SendListCase
      WHERE  CaseId > @id
      ORDER  BY CaseId ASC
   END
   ELSE BEGIN
      SELECT TOP 1
             @id = c.CaseId,
             @s = c.SerialNo,
             @t = c.TypeId
      FROM   SendListCase c
      LEFT   JOIN BarCodePatternCase p
        ON   p.TypeId = c.TypeId
      WHERE  CaseId > @id AND p.TypeId IS NULL
      ORDER  BY CaseId ASC
   END
   -- If no more cases then break
   IF @@rowcount = 0 BREAK
   -- Find the bar code pattern
   SELECT TOP 1 @t1 = TypeId
   FROM   BarCodePatternCase
   WHERE  dbo.bit$RegexMatch(@s, Pattern) = 1
   -- If the type doesn''t match, update case
   IF @t != @t1 BEGIN
      -- Begin transaction
      BEGIN TRANSACTION
      SAVE TRANSACTION @tranName
      -- Update the case
      UPDATE SendListCase
      SET    TypeId = @t1
      WHERE  CaseId = @id
      -- Roll back if error, but keep going
      IF @@error != 0 BEGIN
         ROLLBACK TRAN @tranName
      END
      ELSE BEGIN
         COMMIT TRANSACTION
      END
   END
END

-- Return
RETURN 0
END
'
)

IF @@error != 0 GOTO ROLL_IT

-------------------------------------------------------------------------------
--
-- Procedure: account$del
--
-------------------------------------------------------------------------------
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
FROM   Account
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

IF @@error != 0 GOTO ROLL_IT

-------------------------------------------------------------------------------
--
-- Procedure: mediumType$del
--
-------------------------------------------------------------------------------
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'mediumType$del')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.mediumType$del
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
DECLARE @pattern as nvarchar(4000)
DECLARE @rowcount as int
DECLARE @typeName as nvarchar(256)
DECLARE @error as int
DECLARE @p as int
DECLARE @i as int

SET NOCOUNT ON

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=P''
SET @tranName = object_name(@@procid) + CAST(@@nestlevel as nvarchar(2))

-- Get the type name
SELECT @typeName = TypeName
FROM   MediumType
WHERE  TypeId = @id
IF @@rowcount = 0 RETURN 0

-- Default bar code pattern cannot have this medium type
IF EXISTS
   (
   SELECT 1 
   FROM   BarCodePattern 
   WHERE  TypeId = @id AND
          Position = (SELECT max(Position) FROM BarCodePattern)
   )
BEGIN
   SET @msg = ''Medium type belongs to the catch-all bar code format and may not be deleted.'' + @msgTag + ''>''
   EXECUTE error$raise @msg, @error
   RETURN -100
END

-- Default bar code case pattern cannot have this medium type
IF EXISTS
   (
   SELECT 1 
   FROM   BarCodePatternCase
   WHERE  TypeId = @id AND
          Position = (SELECT max(Position) FROM BarCodePatternCase)
   )
BEGIN
   SET @msg = ''Case type belongs to the catch-all bar code format and may not be deleted.'' + @msgTag + ''>''
   EXECUTE error$raise @msg, @error
   RETURN -100
END

-- Begin transaction
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

-- Delete the bar code patterns and bar code case patterns
DELETE BarCodePattern WHERE TypeId = @id
DELETE BarCodePatternCase WHERE TypeId = @id

-- Initialize counter
SELECT @i = 1

-- Update the bar code positions
WHILE 1 = 1 BEGIN
   SELECT @p = min(Position)
   FROM   BarCodePattern
   WHERE  Position >= @i
   IF @@rowcount = 0 BREAK
   -- Update
   UPDATE BarCodePattern
   SET    Position = @i
   WHERE  Position = @p
   -- Increment
   SET @i = @i + 1
END

-- Reinitialize counter
SELECT @i = 1
   
-- Update the bar code case positions
WHILE 1 = 1 BEGIN
   SELECT @p = min(Position)
   FROM   BarCodePatternCase
   WHERE  Position >= @i
   IF @@rowcount = 0 BREAK
   -- Update
   UPDATE BarCodePatternCase
   SET    Position = @i
   WHERE  Position = @p
   -- Increment
   SET @i = @i + 1
END

-- Delete the medium type record.  There should be no media of this type left in the system, as
-- the bar code synchronization should have changed types on the fly.
DELETE FROM MediumType
WHERE  TypeId = @id AND RowVersion = @rowVersion
SELECT @error = @@error, @rowcount = @@rowcount
IF @error != 0 BEGIN
   ROLLBACK TRANSACTION @tranName
   COMMIT TRANSACTION
   SET @msg = ''Error encountered while deleting medium type.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
   EXECUTE error$raise @msg, @error
   RETURN -100
END
ELSE IF @rowcount = 0 BEGIN
   IF EXISTS(SELECT 1 FROM MediumType WHERE TypeId = @id) BEGIN
      ROLLBACK TRANSACTION @tranName
      COMMIT TRANSACTION
      SET @msg = ''Medium type has been modified since retrieval.'' + @msgTag + ''>''
      RAISERROR(@msg,16,1)
      RETURN -100
   END
   -- No notification if medium type does not exist.  It''s not a bad thing if
   -- we try to delete a record that does not exist.
END
ELSE BEGIN  -- Synchronize only those media and cases that do not have current have valid types
   EXECUTE barCodePattern$synchronize 0
   EXECUTE barCodePatternCase$synchronize 0
END

COMMIT TRANSACTION
RETURN 0
END
'
)

IF @@error != 0 GOTO ROLL_IT

-------------------------------------------------------------------------------
--
-- Trigger: barCodePattern$afterInsert
--
-------------------------------------------------------------------------------
IF EXISTS(SELECT 1 FROM sysobjects WHERE name = 'barCodePattern$afterInsert' AND objectproperty(id, 'ExecIsInsertTrigger' ) = 1) 
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'TRIGGER barCodePattern$afterInsert
ON     BarCodePattern
WITH ENCRYPTION
AFTER  INSERT
AS
BEGIN
DECLARE @msg nvarchar(255)        -- used to preformat error message
DECLARE @msgTag nvarchar(255)     -- used to hold first part of error message header
DECLARE @tranName nvarchar(255)   -- used to hold name of savepoint
DECLARE @accountName nvarchar(256)
DECLARE @mediumType nvarchar(256)
DECLARE @serialNo nvarchar(32)
DECLARE @pattern nvarchar(256)
DECLARE @login nvarchar(256)
DECLARE @lastMedium int
DECLARE @accountId int
DECLARE @rowCount int
DECLARE @typeId int
DECLARE @maxPos int
DECLARE @error int
DECLARE @i int

SET @rowCount = @@rowcount
IF @rowCount = 0 RETURN

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=T''
SET @tranName = object_name(@@procid) + CAST(trigger_nestlevel(@@procid) as nvarchar(2))

-- Make sure we do not have a batch insert
IF @rowCount > 1 BEGIN
   SET @msg = ''Batch insert into disaster code list item table not allowed.'' + @msgTag + ''>''
   RAISERROR(@msg, 16, 1)
   RETURN
END

-- Make sure that no types are container types
IF NOT EXISTS(SELECT 1 FROM Inserted i JOIN MediumType m ON i.TypeId = m.TypeId WHERE m.Container = 0) BEGIN
   SET @msg = ''Type id given may not be of a container type.'' + @msgTag + ''>''
   RAISERROR(@msg, 16, 1)
   RETURN
END

-- Get the caller login from the spidLogin table
SET @login = dbo.string$GetSpidLogin()
IF len(isnull(@login,'''')) = 0 BEGIN
   SET @msg = ''No login found for auditing purposes.'' + @msgTag + ''>''
   RAISERROR(@msg, 16, 1)
   RETURN
END

-- Begin transaction
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

-- Create audit string
SELECT @pattern = i.Pattern,
       @mediumType = m.TypeName,
       @accountName = a.AccountName
FROM   Inserted i
JOIN   MediumType m
  ON   m.TypeId = i.TypeId
JOIN   Account a
  ON   a.AccountId = i.AccountId

-- Insert the record
INSERT XBarCodePattern(Detail,Login)
VALUES(''Bar code format '' + @pattern + '' uses medium type '' + @mediumType + '' and account '' + @accountName, @login)
SET @error = @@error
IF @error != 0 BEGIN
   SET @msg = ''Error encountered while inserting bar code pattern audit record.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
   EXECUTE error$raise @msg, @error, @tranName
   RETURN
END

-- Commit and return
COMMIT TRANSACTION
END
'
)

IF @@error != 0 GOTO ROLL_IT

-------------------------------------------------------------------------------
--
-- Trigger: barCodePattern$afterInsert
--
-------------------------------------------------------------------------------
IF EXISTS(SELECT 1 FROM sysobjects WHERE name = 'barCodePattern$afterInsert' AND objectproperty(id, 'ExecIsInsertTrigger' ) = 1) 
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'TRIGGER barCodePatternCase$afterInsert
ON     BarCodePatternCase
WITH ENCRYPTION
AFTER  INSERT
AS
BEGIN
DECLARE @msg nvarchar(255)        -- used to preformat error message
DECLARE @msgTag nvarchar(255)     -- used to hold first part of error message header
DECLARE @tranName nvarchar(255)   -- used to hold name of savepoint
DECLARE @mediumType nvarchar(256)
DECLARE @serialNo nvarchar(256)
DECLARE @pattern nvarchar(256)
DECLARE @login nvarchar(256)
DECLARE @lastCase int
DECLARE @rowCount int
DECLARE @typeId int
DECLARE @maxPos int
DECLARE @error int

SET @rowCount = @@rowcount
IF @rowCount = 0 RETURN

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=T''
SET @tranName = object_name(@@procid) + CAST(trigger_nestlevel(@@procid) as nvarchar(2))

-- Make sure we do not have a batch insert
IF @rowCount > 1 BEGIN
   SET @msg = ''Batch insert into disaster code list item table not allowed.'' + @msgTag + ''>''
   RAISERROR(@msg, 16, 1)
   RETURN
END

-- Make sure that no types are non-container types
IF NOT EXISTS(SELECT 1 FROM Inserted i JOIN MediumType m ON i.TypeId = m.TypeId WHERE m.Container = 1) BEGIN
   SET @msg = ''Type id given must be of a container type.'' + @msgTag + ''>''
   RAISERROR(@msg, 16, 1)
   RETURN
END

-- Get the caller login from the spidLogin table
SET @login = dbo.string$GetSpidLogin()
IF len(isnull(@login,'''')) = 0 BEGIN
   SET @msg = ''No login found for auditing purposes.'' + @msgTag + ''>''
   RAISERROR(@msg, 16, 1)
   RETURN
END

-- Make sure that the maximum position value in the table is equal to the number of rows
IF EXISTS (SELECT 1 FROM BarCodePatternCase WHERE Position > (SELECT count(*) FROM BarCodePatternCase)) BEGIN
   SET @msg = ''Position value must be equal to number of case pattern records.'' + @msgTag + ''>''
   RAISERROR(@msg, 16, 1)
   RETURN
END

-- Begin transaction
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

-- Create audit string
SELECT @pattern = i.Pattern,
       @mediumType = m.TypeName
FROM   Inserted i
JOIN   MediumType m
  ON   m.TypeId = i.TypeId

-- Insert the record
INSERT XBarCodePattern(Detail,Login)
VALUES(''Case bar code format '' + @pattern + '' uses medium type '' + @mediumType, @login)
SET @error = @@error
IF @error != 0 BEGIN
   SET @msg = ''Error encountered while inserting bar code pattern audit record.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
   EXECUTE error$raise @msg, @error, @tranName
   RETURN
END

-- Commit and return
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
WITH   ENCRYPTION
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

-- Initialize
SET @method = 1
SET @delimiter = ''$|$''

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
      IF CHARINDEX(''clear send'', @tagInfo) != 0 
         SET @method = 2                     -- send list cleared
      ELSE IF CHARINDEX(''clear receive'', @tagInfo) != 0 
         SET @method = 3                     -- receive list cleared
      ELSE IF CHARINDEX(''clear disaster'', @tagInfo) != 0 
         SET @method = 4                     -- disaster code list cleared
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

IF @@error != 0 GOTO ROLL_IT

-------------------------------------------------------------------------------
--
-- Trigger: medium$afterInsert
--
-------------------------------------------------------------------------------
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

IF @@error != 0 GOTO ROLL_IT

-------------------------------------------------------------------------------
--
-- Version update
--
-------------------------------------------------------------------------------
IF NOT EXISTS(SELECT 1 FROM DatabaseVersion WHERE Major = 1 AND Minor = 3 AND Revision = 8) BEGIN
   EXECUTE spidLogin$ins 'System', 'Insert database version'
   INSERT DatabaseVersion (Major, Minor, Revision) VALUES (1, 3, 8)
   EXECUTE spidLogin$del 1
END
ELSE BEGIN
   UPDATE DatabaseVersion 
   SET    InstallDate = getutcdate() 
   WHERE  Major = 1 AND Minor = 3 AND Revision = 8
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
