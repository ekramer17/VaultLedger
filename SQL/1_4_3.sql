-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
--
-- VaultLedger database update - version 1.4.3
--
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
SET NOCOUNT ON

DECLARE @CREATE nvarchar(10)

IF dbo.bit$doScript('1.4.3') = 1 BEGIN
--
-- Destroyed column (Medium table)
--
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE COLUMN_NAME = 'Destroyed' AND TABLE_NAME = 'Medium')
   EXECUTE ('ALTER TABLE Medium ADD Destroyed BIT NOT NULL CONSTRAINT deMedium$Destroyed DEFAULT 0')
--
-- Functions
--
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.ROUTINES WHERE SPECIFIC_NAME = 'int$version')
EXECUTE
(
'
CREATE FUNCTION dbo.int$version()
RETURNS INT
AS
BEGIN
RETURN CAST(SUBSTRING(CONVERT(nvarchar(100), SERVERPROPERTY(''ProductVersion'')), 1, charindex(''.'',CONVERT(nvarchar(100), SERVERPROPERTY(''ProductVersion''))) - 1) as INT)
END
'
)

IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.ROUTINES WHERE SPECIFIC_NAME = 'table$split$string') BEGIN

IF dbo.int$version() > 8 BEGIN

   EXECUTE
   (
   '
   CREATE FUNCTION dbo.table$split$string
   (
      @s1 nvarchar(4000),
      @d1 nvarchar(10)
   )
   RETURNS @tb11 table (Position int identity(1,1), Value nvarchar(3000))
   WITH ENCRYPTION
   AS
   BEGIN

   IF coalesce(@s1, '''') != '''' BEGIN
      -- Recursive function
      WITH x1 (p1, p2) 
      AS 
      (
         SELECT 1, charindex(@d1, @s1)
         UNION  ALL
         SELECT p2 + len(@d1), charindex(@d1, @s1, p2 + len(@d1))
         FROM   x1
         WHERE  p2 > 0
      )
      INSERT @tb11 (Value)
      SELECT SUBSTRING(@s1, p1, CASE WHEN p2 > 0 THEN p2 - p1 ELSE 512 END)
      FROM   x1
      OPTION (MAXRECURSION 32767) 
   END

   -- Return
   RETURN

   END
   '
   )

END
ELSE BEGIN

   EXECUTE
   (
   '
   CREATE FUNCTION dbo.table$split$string
   (
      @s1 nvarchar(4000),
      @d1 nvarchar(10)
   )
   RETURNS @returnTable TABLE (Position int identity(1,1), Value nvarchar(3000))
   WITH ENCRYPTION
   AS
   BEGIN
   DECLARE @i int

   IF coalesce(@s1, '''') != '''' BEGIN

      WHILE 1 = 1 BEGIN

         SELECT @i = charindex(@d1, @s1)
         -- Anything?
         IF @i = 0 BEGIN
            INSERT @returnTable (Value) VALUES (@s1)
            BREAK
         END
         -- Yup
         INSERT @returnTable (Value) SELECT SUBSTRING(@s1, 1, @i - 1)
         -- Move up
         SELECT @s1 = SUBSTRING(@s1, @i + LEN(@d1), LEN(@s1))

      END

   END

   RETURN

   END
   '
   )

END

END
--
-- Triggers
--
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

-- Get the caller login from the spidLogin table
SET @login = dbo.string$GetSpidLogin()
IF len(isnull(@login,'''')) = 0 BEGIN
   SET @msg = ''No login found for auditing purposes.'' + @msgTag + ''>''
   RAISERROR(@msg, 16, 1)
   RETURN
END

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=T''

-- Make sure that no types are container types
IF NOT EXISTS(SELECT 1 FROM Inserted i JOIN MediumType m ON i.TypeId = m.TypeId WHERE m.Container = 0) BEGIN
   SET @msg = ''Type id given may not be of a container type.'' + @msgTag + ''>''
   RAISERROR(@msg, 16, 1)
   RETURN
END

-- Insert audit records
INSERT XBarCodePattern(Detail, Login)
SELECT ''Bar code format '' + i1.Pattern + '' uses medium type '' + m1.TypeName + '' and account '' + a1.AccountName, @login
FROM   Inserted i1
JOIN   MediumType m1
  ON   m1.TypeId = i1.TypeId
JOIN   Account a1
  ON   a1.AccountId = i1.AccountId
SET @error = @@error
IF @error != 0 BEGIN
   SET @msg = ''Error encountered while inserting bar code pattern audit record.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
   RAISERROR(@msg, 16, 1)
END

END
'
)

IF EXISTS(SELECT 1 FROM sysobjects WHERE name = 'medium$afterInsert' AND objectproperty(id, 'ExecIsInsertTrigger' ) = 1) 
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'TRIGGER dbo.medium$afterInsert
ON     dbo.Medium
 
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

-- Only administrators?
IF EXISTS (SELECT * FROM PREFERENCE WHERE KEYNO = 24 AND LEFT(VALUE, 1) = ''Y'') BEGIN
   IF EXISTS (SELECT * FROM OPERATOR WHERE LOGIN = dbo.string$GetSpidLogin() AND ROLE < 32768) BEGIN
      SET @msg = ''Medium not found and only administrators may add media.'' + @msgTag + ''>''
      EXECUTE error$raise @msg, 0, @tranName
      RETURN
   END
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

--
-- Procedures
--
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'medium$destroy')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.medium$destroy
(
   @id nvarchar(4000) -- id list (comma-delimited)
)
WITH ENCRYPTION
AS
BEGIN
DECLARE @msg as nvarchar(255)        -- used to preformat error message
DECLARE @msgTag as nvarchar(255)     -- used to hold first part of error message header
DECLARE @tranName as nvarchar(255)   -- used to hold name of savepoint
DECLARE @x1 nvarchar(4000)
DECLARE @n1 nvarchar(4000)
DECLARE @p1 int
DECLARE @t1 int

SET NOCOUNT ON

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=P''
SET @tranName = object_name(@@procid) + CAST(@@nestlevel as nvarchar(2))

-- Create table
CREATE TABLE #tbl1(RowNo int identity(1,1) primary key clustered, Id int, Serial nvarchar(64))

-- Populate table
WHILE COALESCE(@p1, 1) != 0 BEGIN
   SET @p1 = CHARINDEX('','', @id)
   IF @p1 = 0
      SET @x1 = @id
   ELSE BEGIN
      SET @x1 = LEFT(@id, @p1 - 1)
      SET @id = SUBSTRING(@id, @p1 + 1, 4000)
   END
   -- Insert
   INSERT #tbl1 (Id, Serial)
   SELECT CAST(@x1 as int), SerialNo
   FROM   Medium
   WHERE  MediumId = CAST(@x1 as int)
END

-- Make sure no medium is on an active list
SELECT TOP 1 @x1 = t1.Serial, @p1 = a1.ListId, @t1 = a1.Type
FROM   #tbl1 t1
JOIN   (
       SELECT MediumId, ListId, Type = 1
       FROM   SendListItem
       WHERE  Status NOT IN (1, 512)
       UNION
       SELECT MediumId, ListId, Type = 2
       FROM   ReceiveListItem
       WHERE  Status NOT IN (1, 512)
       UNION
       SELECT MediumId, ListId, Type = 4
       FROM   DisasterCodeListItem
       WHERE  Status NOT IN (1, 512)
       )
  AS   a1
  ON   a1.MediumId = t1.Id
IF @@rowcount != 0 BEGIN
   DROP TABLE #tbl1
   SET @msg = ''Medium '' + @x1 + '' cannot be destroyed because it appears on active list '' + dbo.string$listname(@t1, @p1) + ''.'' + @msgTag + ''>''
   RAISERROR (@msg,16,1)
   RETURN -100
END

-- Transaction
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

-- Update the medium records
UPDATE x1
SET    Destroyed = 1
FROM   Medium x1
JOIN   #tbl1 t1
  ON   x1.MediumId = t1.Id
IF @@error != 0 RETURN 

-- Journalize
SELECT @p1 = 1, @n1 = dbo.string$GetSpidLogin()

WHILE 1 = 1 BEGIN
   SELECT @x1 = Serial
   FROM   #tbl1
   WHERE  RowNo = @p1
   IF @@rowcount = 0 BREAK
   -- Insert the message
   INSERT XMedium(Object, Action, Detail, Login)
   VALUES(@x1, 2, ''Medium destroyed'', @n1)
   -- Increment
   SET @p1 = @p1 + 1
END  

-- Drop table
DROP TABLE #tbl1

-- Commit the transaction
COMMIT TRANSACTION
RETURN 0

ROLL_IT:
ROLLBACK TRANSACTION @tranName
COMMIT TRANSACTION
DROP TABLE #tbl1
RETURN -100

END
'
)

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'medium$upd$account')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + ' PROCEDURE dbo.medium$upd$account
(
   @serials nvarchar(4000),         -- medium serial numbers
   @account nvarchar(256),          -- account number
   @location bit                    -- where to add medium (if addition necessary)
)
WITH ENCRYPTION
AS
BEGIN
DECLARE @msg as nvarchar(255)      -- used to preformat error message
DECLARE @msgTag as nvarchar(255)    -- used to hold first part of error message header
DECLARE @tranName as nvarchar(255)   -- used to hold name of savepoint
DECLARE @r1 int
DECLARE @p1 int
DECLARE @s1 nvarchar(1000)
DECLARE @i1 int
DECLARE @a1 int

SET NOCOUNT ON

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=P''
SET @tranName = object_name(@@procid) + CAST(@@nestlevel as nvarchar(2))

-- Get account id
SELECT @a1 = AccountId
FROM   Account
WHERE  AccountName = @account
IF @@rowcount = 0 BEGIN
   SET @msg = ''Account '' + @account + '' not found.'' + @msgTag + ''>''
   RAISERROR(@msg,16,1)
   RETURN -100
END

CREATE TABLE #tbl1 (Position int, Serial nvarchar(32), ID int)

INSERT #tbl1 (Position, Serial, ID)
SELECT x1.Position, x1.Value, coalesce(m1.MediumId, 0)
FROM   dbo.table$split$string(@serials, '','') x1
LEFT   JOIN Medium m1
  ON   m1.SerialNo = x1.Value

-- Begin transaction
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

-- Add the media that do not exist
WHILE 1 = 1 BEGIN
   -- Get next
   SELECT TOP 1 @p1 = Position, @s1 = Serial
   FROM   #tbl1
   WHERE  Position > coalesce(@p1, 0) AND ID = 0
   ORDER  BY 1 ASC
   -- Anything?
   IF @@ROWCOUNT = 0 BREAK
   -- Add medium
   EXECUTE @r1 = medium$adddynamic @s1, @location, @i1 out
   IF @r1 != 0 BEGIN
      ROLLBACK TRANSACTION @tranName
      COMMIT TRANSACTION
      DROP TABLE #tbl1
      RETURN -100
   END
   ELSE BEGIN
      UPDATE #tbl1
      SET    ID = @i1
      WHERE  Position = @p1
   END
END

-- Alter account
UPDATE m1
SET    m1.AccountId = @a1
FROM   Medium m1
JOIN   #tbl1 t1
  ON   t1.Id = m1.MediumId
WHERE  m1.AccountId != @a1
-- Error?
IF @@error != 0 BEGIN
   ROLLBACK TRANSACTION @tranName
   COMMIT TRANSACTION
   DROP TABLE #tbl1
   RETURN -100
END

-- Commit transaction
COMMIT TRANSACTION
DROP TABLE #tbl1
RETURN 0
END
'
)

EXECUTE
(
'
ALTER PROCEDURE dbo.receivelist$createbydate
(
   @listDate datetime,
   @accounts nvarchar(4000), -- id list (comma-delimited)
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
DECLARE @q1 as nvarchar(4000)
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

-- Create account table
CREATE TABLE #tblAccount (Id int)

IF coalesce(@accounts, '''') = '''' BEGIN
   INSERT #tblAccount (Id) SELECT AccountId FROM Account$View
END
ELSE BEGIN
   SET @q1 = ''INSERT #tblAccount (Id) SELECT AccountId FROM Account$View WHERE AccountId IN ('' + @accounts + '')''
PRINT @q1
   EXEC (@q1)
END

-- Get all media at the vault, not currently on another list, with a return 
-- date earlier or equal to the given date.  Recall that if a medium is in a
-- sealed case it must use the return date of the sealed case.  Even if the
-- case return date is null, the medium in the case should not use its own
-- return date (if it has one).  Entities using null return dates should
-- never appear on the created list(s).
INSERT @tblSerial (SerialNo)
SELECT m.SerialNo
FROM   Medium$View m
JOIN   #tblAccount a1
  ON   m.AccountId = a1.Id
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

-- Drop table
DROP TABLE #tblAccount

-- Commit the transaction
COMMIT TRANSACTION
RETURN 0
END
'
)

EXECUTE
(
'
ALTER TRIGGER productLicense$afterUpdate
ON    ProductLicense
WITH ENCRYPTION
AFTER  UPDATE
AS
BEGIN
DECLARE @msg nvarchar(255)        -- used to preformat error message
DECLARE @msgTag nvarchar(255)     -- used to hold first part of error message header
DECLARE @tranName nvarchar(255)   -- used to hold name of savepoint
DECLARE @rowCount int             -- holds the number of rows in the Inserted table
DECLARE @typeId nvarchar(50)
DECLARE @issueDate nvarchar(10)
DECLARE @licenseType nvarchar(64)
DECLARE @error int            

SET @rowCount = @@rowcount
IF @rowCount = 0 RETURN

-- No need to audit if failure key
IF EXISTS (SELECT 1 FROM Inserted WHERE TypeId = 6) RETURN

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=T''
SET @tranName = object_name(@@procid) + CAST(trigger_nestlevel(@@procid) as nvarchar(2))

-- Begin transaction
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

-- Make sure we do not have a batch update
IF @rowCount > 1 BEGIN
   SET @msg = ''Batch update on product license table not allowed.'' + @msgTag + ''>''
   EXECUTE error$raise @msg, 0, @tranName
   RETURN
END

-- Get the caller login from the spidLogin table
IF len(dbo.string$GetSpidLogin()) = 0 BEGIN
   SET @msg = ''No login found for auditing purposes.'' + @msgTag + ''>''
   EXECUTE error$raise @msg, 0, @tranName
   RETURN
END
ELSE IF dbo.string$GetSpidLogin() != ''System'' BEGIN
   SET @msg = ''No authority to update license codes.'' + @msgTag + ''>''
   EXECUTE error$raise @msg, 0, @tranName
   RETURN
END

-- Select the parameters
SELECT @licenseType = case TypeId
                    when 1 then ''Operator''
                    when 2 then ''Media''
                    when 3 then ''Days''
                    else ''Miscellaneous'' end,
       @issueDate = convert(nvarchar(10),Issued,120)
FROM   Inserted

-- Insert audit record
INSERT XSystemAction(Action, Detail)
VALUES(3, @licenseType + '' license updated, issued on '' + @issueDate)

-- Evaluate error
SET @error = @@error
IF @error != 0 BEGIN
   SET @msg = ''Error encountered while inserting a system action audit record.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
   EXECUTE error$raise @msg, @error, @tranName
   RETURN
END

COMMIT TRANSACTION
END
'
)

EXECUTE
(
'
ALTER PROCEDURE dbo.inventory$compareUnknownSerial
(
   @accounts nvarchar(4000) -- comma-delimited list of account id numbers
)
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
DECLARE @container bit
DECLARE @q1 nvarchar(4000)
DECLARE @id int
DECLARE @i int

SET NOCOUNT ON

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=P''
SET @tranName = object_name(@@procid) + CAST(@@nestlevel as nvarchar(2))
SET @time = cast(convert(nvarchar(19), getutcdate(), 120) as datetime)
SET @i = 1

CREATE TABLE #icus
(
   RowNo int identity(1,1), SerialNo nvarchar(64), Type tinyint, Container bit
)

-- Object types are only supplied by vault inventories, and even then only sometimes
SET @q1 = 
''
INSERT #icus (SerialNo, Type, Container)
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
WHERE  x.SerialNo IS NULL AND i.AccountId IN ('' + @accounts + '')
''
EXECUTE sp_executesql @q1

-- Begin transaction
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

WHILE 1 = 1 BEGIN
   SELECT @serialNo = SerialNo,
          @type = Type, 
          @container = Container
   FROM   #icus
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
      IF @returnValue != 0 GOTO ROLL_IT
      -- Update the account id of the conflict
      UPDATE InventoryConflictUnknownSerial
      SET    Container = @container
      WHERE  Id = @id
      SET @error = @@error
      IF @error != 0 BEGIN
         SET @msg = ''Error encountered while updating inventory unknown serial conflict.'' + @msgTag + '';Error='' +  cast(@error as nvarchar(50)) + ''>''
         EXECUTE error$raise @msg, @error
         GOTO ROLL_IT
      END
   END
   ELSE BEGIN
      -- Insert the conflict record
      EXECUTE @returnValue = inventoryConflict$ins @serialNo, @time, @id out
      IF @returnValue != 0 GOTO ROLL_IT
      -- Insert the information specific to a location conflict
      INSERT InventoryConflictUnknownSerial (Id, Type, Container)
      VALUES (@id, @type, @container)
      SET @error = @@error
      IF @error != 0 BEGIN
         SET @msg = ''Error encountered while inserting inventory unknown serial conflict.'' + @msgTag + '';Error='' +  cast(@error as nvarchar(50)) + ''>''
         EXECUTE error$raise @msg, @error
         GOTO ROLL_IT
      END
   END
   -- Increment counter
   SET @i = @i + 1
END

-- Commit and return
COMMIT TRANSACTION
DROP TABLE #icus
RETURN 0

ROLL_IT:
ROLLBACK TRANSACTION @tranName
COMMIT TRANSACTION
DROP TABLE #icus
RETURN -100

END
'
)

EXECUTE
(
'
ALTER PROCEDURE dbo.inventory$returnDates
(
   @accounts nvarchar(4000) -- comma-delimited list of account id numbers
)
WITH ENCRYPTION
AS
BEGIN
DECLARE @i int
DECLARE @msg nvarchar(255)        -- used to preformat error message
DECLARE @msgTag nvarchar(255)     -- used to hold first part of error message header
DECLARE @tranName nvarchar(255)   -- used to hold name of savepoint
DECLARE @serialNo nvarchar(64)
DECLARE @rdate nvarchar(10)
DECLARE @q1 nvarchar(4000)
DECLARE @container bit
DECLARE @error int

SET NOCOUNT ON

-- Set up the transaction name
SET @tranName = object_name(@@procid) + CAST(@@nestlevel as nvarchar(2))

CREATE TABLE #ird 
(
   RowNo int identity(1,1), SerialNo nvarchar(64), ReturnDate nvarchar(10), Container bit
)

SET @q1=
''
INSERT #ird (SerialNo, ReturnDate, Container)
SELECT ii.SerialNo, vi.ReturnDate, x.Container
FROM   InventoryItem ii
JOIN   Inventory i
  ON   ii.InventoryId = i.InventoryId
JOIN   VaultInventoryItem vi
  ON   vi.ItemId = ii.ItemId
JOIN  (SELECT SerialNo, 0 as ''''Container''''
       FROM   Medium
       WHERE  Location = 0 AND ReturnDate IS NULL
       UNION
       SELECT SerialNo, 1
       FROM   SealedCase
       WHERE  ReturnDate IS NULL) as x
  ON   x.SerialNo = ii.SerialNo
WHERE  len(vi.ReturnDate) != 0 AND i.AccountId IN ('' + @accounts + '')
''
EXECUTE sp_executesql @q1

-- Begin the transaction
SET @i = 1
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

WHILE 1 = 1 BEGIN
   SELECT @serialNo = SerialNo, 
          @rdate = ReturnDate, 
          @container = Container
   FROM   #ird
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
      SET @msg = ''Error encountered while updating return date of '' + @serialNo + '' via inventory.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
      EXECUTE error$raise @msg, @error
      GOTO ROLL_IT
   END
   -- Increment counter
   SET @i = @i + 1
END

COMMIT TRANSACTION
DROP TABLE #ird
RETURN 0

ROLL_IT:
ROLLBACK TRANSACTION @tranName
COMMIT TRANSACTION
DROP TABLE #ird
RETURN -100

END
'
)

EXECUTE
(
'
ALTER PROCEDURE dbo.inventory$compareObjectType
(
   @accounts nvarchar(4000) -- comma-delimited list of account id numbers
)
WITH ENCRYPTION
AS
BEGIN
DECLARE @msg nvarchar(255)        -- used to preformat error message
DECLARE @msgTag nvarchar(255)     -- used to hold first part of error message header
DECLARE @tranName nvarchar(255)   -- used to hold name of savepoint
DECLARE @serialNo nvarchar(64)
DECLARE @q1 nvarchar(4000)
DECLARE @time datetime
DECLARE @typeId int
DECLARE @type tinyint
DECLARE @error int
DECLARE @returnValue int
DECLARE @aid int
DECLARE @id int
DECLARE @i int

SET NOCOUNT ON

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=P''
SET @tranName = object_name(@@procid) + CAST(@@nestlevel as nvarchar(2))
SET @time = cast(convert(nvarchar(19), getutcdate(), 120) as datetime)
SET @i = 1

CREATE TABLE #icot
(
   RowNo int identity(1,1), SerialNo nvarchar(64), TypeId int
)

-- Object types are only supplied by vault inventories, and even then only sometimes
SET @q1 = 
''
INSERT #icot (SerialNo, TypeId)
SELECT m.SerialNo, vi.TypeId
FROM   Medium m
JOIN   InventoryItem ii
  ON   ii.SerialNo = m.SerialNo
JOIN   VaultInventoryItem vi
  ON   vi.ItemId = ii.ItemId
JOIN   Inventory i
  ON   i.InventoryId = ii.InventoryId
WHERE  i.AccountId IN ('' + @accounts + '') AND m.TypeId NOT IN (SELECT TypeId FROM MediumType WHERE TypeCode = (SELECT TypeCode FROM MediumType WHERE TypeId = isnull(vi.TypeId,-1)))
UNION
SELECT c.SerialNo, vi.TypeId
FROM   SealedCase c
JOIN   InventoryItem ii
  ON   ii.SerialNo = c.SerialNo
JOIN   VaultInventoryItem vi
  ON   vi.ItemId = ii.ItemId
JOIN   Inventory i
  ON   i.InventoryId = ii.InventoryId
WHERE  c.TypeId != isnull(vi.TypeId,-1) AND i.AccountId IN ('' + @accounts + '')
''
EXECUTE sp_executesql @q1

-- Begin transaction
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

WHILE 1 = 1 BEGIN
   SELECT @serialNo = SerialNo, 
          @typeId = TypeId
   FROM   #icot
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
      IF @returnValue != 0 GOTO ROLL_IT
      -- Update the account id of the conflict
      UPDATE InventoryConflictObjectType
      SET    TypeId = @typeId
      WHERE  Id = @id
      SET @error = @@error
      IF @error != 0 BEGIN
         SET @msg = ''Error encountered while updating inventory object type conflict.'' + @msgTag + '';Error='' +  cast(@error as nvarchar(50)) + ''>''
         EXECUTE error$raise @msg, @error
         GOTO ROLL_IT
      END
   END
   ELSE BEGIN
      -- Insert the conflict record
      EXECUTE @returnValue = inventoryConflict$ins @serialNo, @time, @id out
      IF @returnValue != 0 GOTO ROLL_IT
      -- Insert the information specific to a location conflict
      INSERT InventoryConflictObjectType (Id, TypeId)
      VALUES (@id, @typeId)
      SET @error = @@error
      IF @error != 0 BEGIN
         SET @msg = ''Error encountered while inserting inventory object type conflict.'' + @msgTag + '';Error='' +  cast(@error as nvarchar(50)) + ''>''
         EXECUTE error$raise @msg, @error
         GOTO ROLL_IT
      END
   END
   -- Increment counter
   SET @i = @i + 1
END

-- Commit and return
COMMIT TRANSACTION
DROP TABLE #icot
RETURN 0

ROLL_IT:
ROLLBACK TRANSACTION @tranName
COMMIT TRANSACTION
DROP TABLE #icot
RETURN -100
END
'
)

EXECUTE
(
'
ALTER PROCEDURE dbo.inventory$compareLocation
(
   @accounts nvarchar(4000) -- comma-delimited list of account id numbers
)
WITH ENCRYPTION
AS
BEGIN
DECLARE @msg nvarchar(255)        -- used to preformat error message
DECLARE @msgTag nvarchar(255)     -- used to hold first part of error message header
DECLARE @tranName nvarchar(255)   -- used to hold name of savepoint
DECLARE @serialNo nvarchar(64)
DECLARE @q1 nvarchar(4000)
DECLARE @type tinyint
DECLARE @time datetime
DECLARE @error int
DECLARE @returnValue int
DECLARE @mid int
DECLARE @ex1 bit
DECLARE @ex2 bit
DECLARE @id int
DECLARE @i int

SET NOCOUNT ON

CREATE TABLE #icl
(
   RowNo int identity(1,1), MediumId int, SerialNo nvarchar(64), Type tinyint
)

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
SET @q1 = 
''
INSERT #icl (MediumId, SerialNo, Type)
SELECT isnull(m.MediumId,-1), ii.SerialNo, 1
FROM   InventoryItem ii
JOIN   Inventory i
  ON   i.InventoryId = ii.InventoryId
JOIN   Medium m
  ON   m.SerialNo = ii.SerialNo
WHERE  m.Location = 0 AND i.Location = 1 AND i.AccountId IN ('' + @accounts + '')
''
EXECUTE sp_executesql @q1

----------------------------------------------------------------------------
-- Enterprise inventory refutes residence (type 2)
--
-- Note that we''re only considering tapes where an inventory for that
-- account has been taken.  If we do not have an inventory for the account
-- of a tape, then we will not designate a location conflict for the tape.
----------------------------------------------------------------------------
SET @q1 = 
''
INSERT #icl (MediumId, SerialNo, Type)
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
WHERE  m.Missing = 0 AND m.Location = 1 AND i.Location = 1 AND x.SerialNo IS NULL AND i.AccountId IN ('' + @accounts + '')
''
EXECUTE sp_executesql @q1

----------------------------------------------------------------------------
-- Vault inventory claims residence (type 3)
----------------------------------------------------------------------------
SET @q1 = 
''
INSERT #icl (MediumId, SerialNo, Type)
SELECT isnull(m.MediumId,-1), ii.SerialNo, 3
FROM   InventoryItem ii
JOIN   Inventory i
  ON   i.InventoryId = ii.InventoryId
JOIN   Medium m
  ON   m.SerialNo = ii.SerialNo
WHERE  m.Location = 1 AND i.Location = 0 AND i.AccountId IN ('' + @accounts + '')
''
EXECUTE sp_executesql @q1

----------------------------------------------------------------------------
-- Vault inventory refutes residence (type 4)
--
-- Note that we''re only considering tapes where an inventory for that
-- account has been taken.  If we do not have an inventory for the account
-- of a tape, then we will not designate a location conflict for the tape.
----------------------------------------------------------------------------
SET @q1 = 
''
INSERT #icl (MediumId, SerialNo, Type)
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
WHERE  i.Location = 0
  AND  x.SerialNo IS NULL
  AND  m.Missing = 0
  AND  m.Location = 0
  AND  c.MediumId IS NULL
  AND  i.AccountId IN ('' + @accounts + '')
''
EXECUTE sp_executesql @q1

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
   FROM   #icl
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
      IF @returnValue != 0 GOTO ROLL_IT
   END
   ELSE BEGIN
      -- Insert the conflict record
      EXECUTE @returnValue = inventoryConflict$ins @serialNo, @time, @id out
      IF @returnValue != 0 GOTO ROLL_IT
      -- Insert the information specific to a location conflict
      INSERT InventoryConflictLocation (Id, Type)
      VALUES (@id, @type)
      SET @error = @@error
      IF @error != 0 BEGIN
         SET @msg = ''Error encountered while inserting inventory location conflict.'' + @msgTag + '';Error='' +  cast(@error as nvarchar(50)) + ''>''
         EXECUTE error$raise @msg, @error
         GOTO ROLL_IT
      END
   END
   -- Next row
   NEXTROW:
   SET @i = @i + 1
END

-- Commit and return
COMMIT TRANSACTION
DROP TABLE #icl
RETURN 0

ROLL_IT:
ROLLBACK TRANSACTION @tranName
COMMIT TRANSACTION
DROP TABLE #icl
RETURN -100
END
'
)

EXECUTE
(
'
ALTER PROCEDURE dbo.inventory$compareAccount
(
   @accounts nvarchar(4000) -- comma-delimited list of account id numbers
)
WITH ENCRYPTION
AS
BEGIN
DECLARE @msg nvarchar(255)        -- used to preformat error message
DECLARE @msgTag nvarchar(255)     -- used to hold first part of error message header
DECLARE @tranName nvarchar(255)   -- used to hold name of savepoint
DECLARE @serialNo nvarchar(64)
DECLARE @q1 nvarchar(4000)
DECLARE @time datetime
DECLARE @type tinyint
DECLARE @error int
DECLARE @returnValue int
DECLARE @aid int
DECLARE @id int
DECLARE @i int

SET NOCOUNT ON

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=P''
SET @tranName = object_name(@@procid) + CAST(@@nestlevel as nvarchar(2))
SET @time = cast(convert(nvarchar(19), getutcdate(), 120) as datetime)
SET @i = 1

CREATE TABLE #ica
(
   RowNo int identity(1,1), SerialNo nvarchar(64), Type tinyint, AccountId int
)

-- Compare account of serial numbers in inventory to account numbers of media in database
SET @q1  = 
''
INSERT #ica (SerialNo, Type, AccountId)
SELECT m.SerialNo, i.Location, i.AccountId
FROM   Medium m
JOIN   InventoryItem ii
  ON   ii.Serialno = m.SerialNo
JOIN   Inventory i
  ON   i.InventoryId = ii.InventoryId
WHERE  m.AccountId != i.AccountId AND i.AccountId IN ('' + @accounts + '')
''
EXECUTE sp_executesql @q1

-- Begin transaction
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

WHILE 1 = 1 BEGIN
   SELECT @serialNo = SerialNo, 
          @type = Type, 
          @aid = AccountId
   FROM   #ica
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
      IF @returnValue != 0 GOTO ROLL_IT
      -- Update the account id of the conflict
      UPDATE InventoryConflictAccount
      SET    AccountId = @aid
      WHERE  Id = @id
      SET @error = @@error
      IF @error != 0 BEGIN
         SET @msg = ''Error encountered while updating inventory account conflict.'' + @msgTag + '';Error='' +  cast(@error as nvarchar(50)) + ''>''
         EXECUTE error$raise @msg, @error
         GOTO ROLL_IT
      END
   END
   ELSE BEGIN
      -- Insert the conflict record
      EXECUTE @returnValue = inventoryConflict$ins @serialNo, @time, @id out
      IF @returnValue != 0 GOTO ROLL_IT
      -- Insert the information specific to a location conflict
      INSERT InventoryConflictAccount (Id, Type, AccountId)
      VALUES (@id, @type, @aid)
      SET @error = @@error
      IF @error != 0 BEGIN
         SET @msg = ''Error encountered while inserting inventory account conflict.'' + @msgTag + '';Error='' +  cast(@error as nvarchar(50)) + ''>''
         EXECUTE error$raise @msg, @error
         GOTO ROLL_IT
      END
   END
   -- Increment counter
   SET @i = @i + 1
END

-- Commit and return
COMMIT TRANSACTION
DROP TABLE #ica
RETURN 0

ROLL_IT:
ROLLBACK TRANSACTION @tranName
COMMIT TRANSACTION
DROP TABLE #ica
RETURN -100
END
'
)

EXECUTE
(
'
ALTER PROCEDURE dbo.inventory$compare
(
   @accounts nvarchar(4000), -- comma-delimited list of account id numbers
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
DECLARE @accountId int
DECLARE @accountNo nvarchar(256)
DECLARE @serialNo nvarchar(256)
DECLARE @spidlogin nvarchar(256)
DECLARE @typeName nvarchar(256)
DECLARE @rdate nvarchar(10)
DECLARE @q1 nvarchar(4000)

SET NOCOUNT ON

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=P''
SET @tranName = ''ABC1''
SET @spidlogin = coalesce(dbo.string$getSpidLogin(),'''')

-- Make sure we have a login for the audit record to come later
IF len(@spidlogin) = 0 BEGIN
   SET @msg = ''No login specified for auditing purposes.'' + @msgTag + ''>''
   EXECUTE error$raise @msg, 0
   RETURN -100
END

-- Create tables
CREATE TABLE #tbl1 (RowNo int identity(1,1), SerialNo nvarchar(256), Location bit, TypeId int, AccountId int)
CREATE TABLE #tbl2 (RowNo int identity(1,1), Id int, SerialNo nvarchar(64), Reason int)
CREATE TABLE #tbl3 (RowNo int identity(1,1), AccountNo nvarchar(256))
CREATE TABLE #tbl4 (RowNo int identity(1,1), Pattern nvarchar(256), TypeId int, AccountId int) -- bar code patterns

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
SET @q1 = 
''
INSERT #tbl3 (AccountNo)
SELECT DISTINCT a.AccountName
FROM   Account a
JOIN   Inventory i
  ON   a.AccountId = i.AccountId AND i.AccountId IN ('' + @accounts + '')
''
EXECUTE sp_executesql @q1

WHILE 1 = 1 BEGIN
   SELECT @accountNo = AccountNo
   FROM   #tbl3
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
   SET @q1 = 
   ''
   INSERT #tbl1 (SerialNo, Location, TypeId, AccountId)
   SELECT ii.SerialNo, i.Location, coalesce(vi.TypeId, -1), i.AccountId
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
   WHERE  x.SerialNo IS NULL AND isnull(dbo.bit$IsContainerType(vi.TypeId),0) = 0 AND i.AccountId IN ('' + @accounts + '')
   ''
   EXECUTE sp_executesql @q1
   -- Run through the table, adding media   
   SET @i = 1
   WHILE 1 = 1 BEGIN
      -- Get the next medium
      SELECT @serialNo = SerialNo, @loc = Location, @typeid = TypeId, @accountId = AccountId
      FROM   #tbl1
      WHERE  RowNo = @i
      IF @@rowcount = 0 BREAK
      -- Add it dynamically
      IF NOT EXISTS (SELECT 1 FROM Medium WHERE SerialNo = @serialNo) BEGIN
         -- Must get default type?
         IF @typeid = -1 BEGIN
            EXECUTE barcodepattern$getdefaults @serialNo, @typeName out, @q1 out
            SELECT @typeid = TypeId FROM MediumType WHERE TypeName = @typeName
         END
         -- Add medium
         INSERT Medium (SerialNo, Location, HotStatus, Missing, BSide, Notes, Destroyed, TypeId, AccountId)
         VALUES (@serialNo, @loc, 0, 0, '''', '''', 0, @typeid, @accountid)
         IF @@error != 0 GOTO ROLL_IT
         -- Record bar code
         INSERT #tbl4 (Pattern, TypeId, AccountId)
         SELECT @serialNo, @typeid, AccountId
         FROM   Account
         WHERE  AccountName = @accountNo
      END
      -- Increment counter
      SET @i = @i + 1
   END
   -- Pattern literals?
   IF EXISTS (SELECT * FROM #tbl4) BEGIN
      -- Part 1 : delete existing
      DELETE x1
      FROM   BarCodePattern x1
      JOIN   #tbl4 y1
        ON   y1.Pattern  = x1.Pattern
      -- Part 2 : copy others
      INSERT #tbl4 (Pattern, TypeId, AccountId)
      SELECT Pattern, TypeId, AccountId
      FROM   BarCodePattern
      ORDER  BY Position ASC
      -- Part 3 : truncate
      TRUNCATE TABLE BarCodePattern
      -- Part 4 : insert
      INSERT BarCodePattern (Position, Pattern, TypeId, AccountId, Notes)
      SELECT RowNo, Pattern, TypeId, AccountId, ''''
      FROM   #tbl4
      ORDER  BY RowNo ASC
   END
END

----------------------
-- Compare locations
----------------------
EXECUTE @returnValue = inventory$compareLocation @accounts
IF @returnValue != 0 GOTO ROLL_IT

----------------------
-- Compare accounts
----------------------
EXECUTE @returnValue = inventory$compareAccount @accounts
IF @returnValue != 0 GOTO ROLL_IT

-------------------------
-- Compare object types
-------------------------
EXECUTE @returnValue = inventory$compareObjectType @accounts
IF @returnValue != 0 GOTO ROLL_IT

-----------------------------------
-- Compare unknown serial numbers
-----------------------------------
EXECUTE @returnValue = inventory$compareUnknownSerial @accounts
IF @returnValue != 0 GOTO ROLL_IT

---------------------
-- Set return dates
---------------------
EXECUTE @returnValue = inventory$returnDates @accounts
IF @returnValue != 0 GOTO ROLL_IT

------------------------------------------
-- Remove reconciled residency conflicts
------------------------------------------
IF @doResolve = 1 BEGIN
   -- Resolve location conflicts
   INSERT #tbl2 (Id, SerialNo, Reason)
   SELECT c.Id, c.SerialNo, case m.Missing when 1 then 2 else 1 end
   FROM   InventoryConflict c
   JOIN   Medium m
     ON   m.SerialNo = c.SerialNo
   JOIN   InventoryConflictLocation l
     ON   l.Id = c.Id
   WHERE (l.Type in (1,4) AND m.Location = 1) OR (l.Type in (2,3) AND m.Location = 0) OR m.Missing = 1
   -- Cycle through the resolved locations
   SELECT @i = min(RowNo) FROM #tbl2
   WHILE 1 = 1 BEGIN
      SELECT @id = Id, @serialNo = SerialNo, @reason = Reason
      FROM   #tbl2
      WHERE  RowNo = @i
      IF @@rowcount = 0 BREAK
      -- Discern the reason
      EXECUTE @returnValue = inventoryConflict$resolveLocation @id, @reason
      IF @returnValue != 0 GOTO ROLL_IT
      SET @i = @i + 1
   END
   -- Clear the table
   TRUNCATE TABLE #tbl2
   -- Resolve account discrepancies
   INSERT #tbl2 (Id)
   SELECT c.Id
   FROM   InventoryConflict c
   JOIN   Medium m
     ON   m.SerialNo = c.SerialNo
   JOIN   InventoryConflictAccount a
     ON   a.Id = c.Id
   WHERE  m.AccountId = a.AccountId
   -- Cycle through the resolved accounts
   SELECT @i = min(RowNo) FROM #tbl2
   WHILE 1 = 1 BEGIN
      SELECT @id = Id
      FROM   #tbl2
      WHERE  RowNo = @i
      IF @@rowcount = 0 BREAK
      EXECUTE @returnValue = inventoryConflict$resolveAccount @id, 1
      IF @returnValue != 0 GOTO ROLL_IT
      SET @i = @i + 1
   END
   -- Clear the table
   TRUNCATE TABLE #tbl2
   -- Resolve object type discrepancies
   INSERT #tbl2 (Id)
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
   SELECT @i = min(RowNo) FROM #tbl2
   WHILE 1 = 1 BEGIN
      SELECT @id = Id
      FROM   #tbl2
      WHERE  RowNo = @i
      IF @@rowcount = 0 BREAK
      EXECUTE @returnValue = inventoryConflict$resolveObjectType @id, 1
      IF @returnValue != 0 GOTO ROLL_IT
      SET @i = @i + 1
   END
   -- Clear the table
   TRUNCATE TABLE #tbl2
   -- Resolve unknown serial discrepancies
   INSERT #tbl2 (Id)
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
   SELECT @i = min(RowNo) FROM #tbl2
   WHILE 1 = 1 BEGIN
      SELECT @id = Id
      FROM   #tbl2
      WHERE  RowNo = @i
      IF @@rowcount = 0 BREAK
      EXECUTE @returnValue = inventoryConflict$resolveUnknownSerial @id, 1
      IF @returnValue != 0 GOTO ROLL_IT
      SET @i = @i + 1
   END
END

-----------------------------------------------
-- Insert audit records, one for each account
-----------------------------------------------
TRUNCATE TABLE #tbl1   -- Use tbl1, use SerialNo to hold account name
INSERT #tbl1 (SerialNo, Location)
SELECT a.AccountName, i.Location
FROM   Inventory i
JOIN   Account a
  ON   a.AccountId = i.AccountId

SELECT @i = min(RowNo) FROM #tbl1

WHILE 1 = 1 BEGIN
   SELECT @serialNo = SerialNo, @loc = Location
   FROM   #tbl1
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
      SET @msg = ''Error encountered while inserting inventory audit record.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
      EXECUTE error$raise @msg, @error
      GOTO ROLL_IT
   END
   SET @i = @i + 1
END

-- Commit the transaction
COMMIT TRANSACTION

-- Select the number of conflicts in the database
SELECT count(*) FROM InventoryConflict

-- Drop tables
DROP TABLE #tbl1
DROP TABLE #tbl2
DROP TABLE #tbl3
DROP TABLE #tbl4

-- Return       
RETURN 0

ROLL_IT:
ROLLBACK TRANSACTION @tranName
COMMIT TRANSACTION
DROP TABLE #tbl1
DROP TABLE #tbl2
DROP TABLE #tbl3
DROP TABLE #tbl4

END
'
)

EXEC
(
'
ALTER PROCEDURE dbo.inventoryConflict$getPage
(
   @pageNo int,
   @pageSize int,
   @accounts nvarchar(4000), -- list of account id numbers (comma-delimited)
   @filter nvarchar(4000),
   @sort tinyint
)
WITH ENCRYPTION
AS
BEGIN
DECLARE @msg as nvarchar(255)        -- used to preformat error message
DECLARE @msgTag as nvarchar(255)     -- used to hold first part of error message header
DECLARE @tables nvarchar(4000)
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
DECLARE @s nvarchar(4000)
DECLARE @p int

SET NOCOUNT ON

-- Set the message tag
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=P''

-- Verify validity of @pageNo
IF @pageNo < 1 SET @pageNo = 1

-- Initialize variable string
SELECT @var = ''@x1$ nvarchar(1000), @x2$ nvarchar(1000)''
SELECT @p = -1

-- Set the order clauses
IF @sort = 1 BEGIN
   SET @order1 = '' ORDER BY SerialNo asc, ConflictType asc, RecordedDate asc''
   SET @order2 = '' ORDER BY SerialNo desc, ConflictType desc, RecordedDate desc''
   SET @order3 = '' ORDER BY SerialNo asc, ConflictType asc, RecordedDate asc''
END
ELSE IF @sort = 2 BEGIN
   SET @order1 = '' ORDER BY RecordedDate asc, ConflictType asc, SerialNo asc''
   SET @order2 = '' ORDER BY RecordedDate desc, ConflictType desc, SerialNo desc''
   SET @order3 = '' ORDER BY RecordedDate asc, ConflictType asc, SerialNo asc''
END
ELSE IF @sort = 3 BEGIN
   SET @order1 = '' ORDER BY ConflictType asc, RecordedDate asc, SerialNo asc''
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
      SET @where = @where + '' AND ('' + left(@s, charindex(''='',@s) + 1) + '' @x1$)''
      SET @x1 = replace(ltrim(substring(@s, charindex(''='',@s) + 1, 4000)), '''''''', '''')
   END
   ELSE IF charindex(''RecordedDate'', @s) = 1 BEGIN
      SET @where = @where + '' AND ('' + replace(left(@s, charindex(''='',@s) + 1),''RecordedDate'',''convert(nvarchar(10),RecordedDate,120)'') + '' @x2$)''
      SET @x2 = replace(ltrim(substring(@s, charindex(''='',@s) + 1, 4000)), '''''''', '''')
   END
   ELSE IF charindex(''ConflictType IN'', @s) = 1 BEGIN
      SET @where = @where + '' AND ('' + @s + '')''
   END
   ELSE BEGIN
      SET @msg = ''Error occurred while selecting page of inventory conflicts.  Invalid filter supplied.'' + @msgTag + ''>''
      EXECUTE error$raise @msg
      RETURN -100
   END
END

-- Construct the tables string
SET @tables = 
''
(
SELECT i1.SerialNo, i1.RecordedDate, a1.AccountName, x1.*
FROM   InventoryConflict i1
JOIN   Medium$View m1
  ON   m1.SerialNo = i1.SerialNo
JOIN   Account a1
  ON   a1.AccountId = m1.AccountId
JOIN   (
       SELECT Id, 
              case Type when 1 then ''''Enterprise claims residence of medium'''' when 2 then ''''Enterprise denies residence of medium'''' when 3 then ''''Vault claims residence of medium'''' when 4 then ''''Vault denies residence of medium'''' end as ''''Details'''', 
              1 as ''''ConflictType'''' 
       FROM   InventoryConflictLocation
       UNION
       SELECT o.Id, 
              ''''Vault asserts serial number should be of type '''' + t.TypeName as ''''Details'''',
              2 as ''''ConflictType'''' 
       FROM   InventoryConflictObjectType o 
       JOIN   MediumType t 
         ON   t.TypeId = o.TypeId 
       UNION
       SELECT c.Id, 
              case c.Type when 0 then ''''Vault asserts that medium should belong to account '''' + a.AccountName when 1 then ''''Enterprise asserts that medium should belong to account '''' + a.AccountName end as ''''Details'''',
              8 as ''''ConflictType'''' 
       FROM   InventoryConflictAccount c 
       JOIN   Account a ON a.AccountId = c.AccountId
       )
  AS   x1 
  ON   x1.Id = i1.Id
WHERE  m1.AccountId IN ('' + @accounts + '')
UNION
SELECT i1.SerialNo, i1.RecordedDate, ''''N/A'''', x1.*
FROM   InventoryConflict i1
JOIN   (
       SELECT Id, 
              case Type when 0 then ''''Vault claims residence of unrecognized '''' + case Container when 0 then ''''medium'''' else ''''sealed case'''' end when 1 then ''''Enterprise claims residence of unrecognized medium'''' end as ''''Details'''', 
              4 as ''''ConflictType'''' 
       FROM   InventoryConflictUnknownSerial
       ) 
  AS   x1
  ON   x1.Id = i1.Id
)
AS y1
''

-- Select the total number of records that fit the criteria
CREATE TABLE #tblTemp (xyz int)
SET @sql = ''INSERT #tblTemp SELECT count(*) FROM '' + @tables + @where
EXECUTE sp_executesql @sql, @var, @x1$ = @x1, @x2$ = @x2
SELECT @count = xyz FROM #tblTemp
DROP TABLE #tblTemp

-- If the page number is 1, then we can execute without the subqueries
-- thus increasing efficiency.
IF @pageNo = 1 BEGIN
   SET @sql = ''SELECT TOP '' + cast(@pageSize as nvarchar(50)) + '' * FROM '' + @tables + @where + @order1
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
   SET @sql = ''SELECT * FROM ''
   SET @sql = @sql + ''(''
   SET @sql = @sql + ''SELECT TOP '' + cast(@topSize as nvarchar(50)) + '' * FROM ''
   SET @sql = @sql + ''   (''
   SET @sql = @sql + ''   SELECT TOP '' + cast((@pageSize * @pageNo) as nvarchar(50)) + '' * FROM '' + @tables + @where + @order1
   SET @sql = @sql + ''   ) as x1 ''
   SET @sql = @sql + @order2 + '') as y1 '' + @order3
END

-- Execute the sql
EXECUTE sp_executesql @sql, @var, @x1$ = @x1, @x2$ = @x2
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

EXECUTE
(
'
ALTER PROCEDURE dbo.sendListItem$ins
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
DECLARE @statusThreshold as int    -- status beyond which tape dynamically move to another list
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

-- Medium may not be destroyed
IF EXISTS (SELECT 1 FROM Medium WHERE SerialNo = @serialNo AND Destroyed = 1) BEGIN
   SET @msg = ''Medium '' + @serialNo + '' cannot be placed on a list because it has been destroyed.'' + @msgTag + ''>''
   RAISERROR (@msg,16,1)
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
   -- Get the status threshold
   IF EXISTS (SELECT * FROM PREFERENCE WHERE [KEYNO] = 23 AND LEFT(VALUE,1) = ''N'')
      SET @statusThreshold = 1
   ELSE
      SET @statusThreshold = 2
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
   -- Anything?          
   IF @@rowCount > 0 BEGIN
      IF @priorStatus > @statusThreshold BEGIN
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
--            SET @msg = ''Medium '''''' + @serialNo + '''''' already appears on a list within this batch.'' + @msgTag + ''>''
--            RAISERROR(@msg,16,1)
            RETURN 0
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

EXECUTE
(
'
ALTER PROCEDURE dbo.sendListItem$add
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
DECLARE @statusThreshold as int    -- status beyond which tape dynamically move to another list

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

-- Medium may not be destroyed
IF EXISTS (SELECT 1 FROM Medium WHERE SerialNo = @serialNo AND Destroyed = 1) BEGIN
   SET @msg = ''Medium '' + @serialNo + '' cannot be placed on a list because it has been destroyed.'' + @msgTag + ''>''
   RAISERROR (@msg,16,1)
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
   -- Get the status threshold
   IF EXISTS (SELECT * FROM PREFERENCE WHERE [KEYNO] = 23 AND LEFT(VALUE,1) = ''N'')
      SET @statusThreshold = 1
   ELSE
      SET @statusThreshold = 2
   -- check current lists
   SELECT @priorId = ItemId,
          @priorStatus = Status,
          @priorVersion = RowVersion
   FROM   SendListItem
   WHERE  Status > 1 AND Status != 512 AND
          MediumId = @mediumId
   IF @@rowCount > 0 BEGIN
      IF @priorStatus > @statusThreshold BEGIN
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

EXECUTE
(
'
ALTER PROCEDURE dbo.receiveListItem$ins
(
   @serialNo nvarchar(32),               -- medium serial number
   @notes nvarchar(1000),                -- any notes to attach to the medium
   @batchLists nvarchar(4000) OUTPUT,    -- list names in the creation batch
   @nestLevel int = 1                    -- should never be supplied from the application
)
 
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
DECLARE @statusThreshold as int    -- status beyond which tape dynamically move to another list
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

-- Medium may not be destroyed
IF EXISTS (SELECT 1 FROM Medium WHERE SerialNo = @serialNo AND Destroyed = 1) BEGIN
   SET @msg = ''Medium '' + @serialNo + '' cannot be placed on a list because it has been destroyed.'' + @msgTag + ''>''
   RAISERROR (@msg,16,1)
   RETURN -100
END

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
       -- Get the status threshold
      IF EXISTS (SELECT * FROM PREFERENCE WHERE [KEYNO] = 23 AND LEFT(VALUE,1) = ''N'')
         SET @statusThreshold = 2
      ELSE
         SET @statusThreshold = 4
      -- On active list?
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
         IF @priorStatus >= @statusThreshold BEGIN
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
            ROLLBACK TRANSACTION @tranName
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

EXECUTE
(
'
ALTER PROCEDURE dbo.receiveListItem$add
(
   @serialNo nvarchar(32),      -- medium serial number
   @notes nvarchar(1000),       -- any notes to attach to the medium
   @listId int,                 -- list to which item should be added
   @nestLevel int = 1           -- should never be supplied from the application
)
 
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
DECLARE @statusThreshold as int    -- status beyond which tape dynamically move to another list
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

-- Medium may not be destroyed
IF EXISTS (SELECT 1 FROM Medium WHERE SerialNo = @serialNo AND Destroyed = 1) BEGIN
   SET @msg = ''Medium '' + @serialNo + '' cannot be placed on a list because it has been destroyed.'' + @msgTag + ''>''
   RAISERROR (@msg,16,1)
   RETURN -100
END

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
   -- Get the status threshold
   IF EXISTS (SELECT * FROM PREFERENCE WHERE [KEYNO] = 23 AND LEFT(VALUE,1) = ''N'')
      SET @statusThreshold = 2
   ELSE
      SET @statusThreshold = 4
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
      IF @priorStatus >= @statusThreshold BEGIN
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

EXECUTE
(
'
ALTER PROCEDURE dbo.disasterCodeListItem$ins
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

-- Medium may not be destroyed
IF EXISTS (SELECT 1 FROM Medium WHERE SerialNo = @serialNo AND Destroyed = 1) BEGIN
   SET @msg = ''Medium '' + @serialNo + '' cannot be placed on a list because it has been destroyed.'' + @msgTag + ''>''
   RAISERROR (@msg,16,1)
   RETURN -100
END

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

EXECUTE
(
'
ALTER PROCEDURE dbo.disasterCodeListItem$add
(
   @serialNo nvarchar(32),      -- medium serial number
   @code nvarchar(32),          -- disaster code
   @notes nvarchar(1000),       -- any notes to attach to the medium
   @listId int                 -- list to which item should be added
)
WITH ENCRYPTION
AS
BEGIN
DECLARE @msg as nvarchar(255)      -- used to preformat error message
DECLARE @msgTag as nvarchar(255)    -- used to hold first part of error message header
DECLARE @tranName as nvarchar(255)   -- used to hold name of savepoint
DECLARE @listAccount as int
DECLARE @listStatus as int
DECLARE @error as int
DECLARE @caseId as int
DECLARE @mediumId as int
DECLARE @status as int
DECLARE @returnValue as int
DECLARE @caseSerial bit

SET NOCOUNT ON

-- Tweak parameters
SET @notes = coalesce(ltrim(rtrim(@notes)),'''')
SET @serialNo = ltrim(rtrim(@serialNo))
SET @code = ltrim(rtrim(@code))

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=P''
SET @tranName = object_name(@@procid) + CAST(@@nestlevel as nvarchar(2))

-- Verify that the list exists
SELECT @listAccount = AccountId,
       @listStatus = Status
FROM   DisasterCodeList
WHERE  ListId = @listId
IF @@rowCount = 0 BEGIN
   SET @msg = ''Disaster code list not found.'' + @msgTag + ''>''
   RAISERROR(@msg,16,1)
   RETURN -100
END

-- Make sure that the medium or caseis not already on the list.  If it does, just return.
IF EXISTS 
   (
   SELECT 1 
   FROM   DisasterCodeListItemMedium dlim 
   JOIN   DisasterCodeListItem dli
     ON   dli.ItemId = dlim.ItemId
   JOIN   Medium m 
     ON   m.MediumId = dlim.MediumId 
   WHERE  m.SerialNo = @serialNo AND dli.Status != 1 AND dli.ListId = @listId
   ) 
BEGIN
   RETURN 0
END
ELSE IF EXISTS 
   (
   SELECT 1 
   FROM   DisasterCodeListItemCase dlic 
   JOIN   DisasterCodeListItem dli
     ON   dli.ItemId = dlic.ItemId
   JOIN   SealedCase c 
     ON   c.CaseId = dlic.CaseId
   WHERE  c.SerialNo = @serialNo AND dli.Status != 1 AND dli.ListId = @listId
   ) 
BEGIN
   RETURN 0
END

IF @listStatus = 4 BEGIN
   SET @msg = ''Changes may not be made to a disaster code list after it has been transmitted.'' + @msgTag + ''>''
   RAISERROR(@msg,16,1)
   RETURN -100
END
ELSE IF @listStatus = 512 BEGIN
   SET @msg = ''Changes may not be made to a processed disaster code list.'' + @msgTag + ''>''
   RAISERROR(@msg,16,1)
   RETURN -100
END

-- Check to see if the given serial number is of a case.  If not, and if the
-- medium exists, see if it resides in a sealed case
SELECT @caseId = CaseId
FROM   SealedCase 
WHERE  SerialNo = @serialNo
IF @@rowCount > 0 
   SET @caseSerial = 1
ELSE BEGIN
   SELECT @caseId = sc.CaseId
   FROM   SealedCase sc
   JOIN   MediumSealedCase msc
     ON   msc.CaseId = sc.CaseId
   JOIN   Medium m
     ON   m.MediumId = msc.MediumId
   WHERE  m.SerialNo = @serialNo
   IF @@rowCount > 0
      SET @caseSerial = 1
   ELSE
      SET @caseSerial = 0
END

-- Medium may not be destroyed
IF EXISTS (SELECT 1 FROM Medium WHERE SerialNo = @serialNo AND Destroyed = 1) BEGIN
   SET @msg = ''Medium '' + @serialNo + '' cannot be placed on a list because it has been destroyed.'' + @msgTag + ''>''
   RAISERROR (@msg,16,1)
   RETURN -100
END

-- Begin transaction
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

-- Add case or medium
IF @caseSerial = 1 BEGIN
   EXECUTE @returnValue = disasterCodeListItemCase$add @caseId, @code, @notes, @listId
   IF @returnValue != 0 BEGIN
      ROLLBACK TRANSACTION @tranName
      COMMIT TRANSACTION
      RETURN -100
   END
END
ELSE BEGIN
   -- If the medium does not exist, then add it
   SELECT @mediumId = MediumId 
   FROM   Medium 
   WHERE  SerialNo = @serialNo
   IF @@rowCount = 0 BEGIN
      EXECUTE @returnValue = medium$addDynamic @serialNo, 0, @mediumId OUTPUT
      IF @returnValue != 0 BEGIN
         ROLLBACK TRANSACTION @tranName
         COMMIT TRANSACTION
         RETURN -100
      END
   END
   -- Add the medium to the list
   EXECUTE @returnValue = disasterCodeListItemMedium$add @mediumId, @code, @notes, @listId
   IF @returnValue != 0 BEGIN
      ROLLBACK TRANSACTION @tranName
      COMMIT TRANSACTION
      RETURN -100
   END
END

-- Commit transaction
COMMIT TRANSACTION
RETURN 0
END
'
)

EXECUTE
(
'
ALTER PROCEDURE dbo.medium$getPage
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
SET @var = ''@x1$ nvarchar(1000), @x2$ nvarchar(1000), @x3$ nvarchar(1000)''
SET @var = @var + '', @x4$ nvarchar(1000), @x5$ nvarchar(1000), @x6$ nvarchar(1000), @x7$ nvarchar(1000), @x8$ nvarchar(1000)''
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
   ELSE IF charindex(''Destroyed ='', @s) = 1 BEGIN
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
   ELSE IF charindex(''Disaster LIKE '', @s) = 1 BEGIN
      SET @where = @where + '' AND (d.Code LIKE @x8$)''
      SET @x8 = replace(ltrim(substring(@s, charindex(''LIKE'',@s) + 4, 4000)), '''''''', '''')
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
SET @fields2 = ''MediumId, SerialNo, Location, HotStatus, ReturnDate, Missing, LastMoveDate, BSide, Notes, AccountName, TypeName, CaseName, Disaster, Destroyed, RowVersion''
SET @fields1 = ''m.MediumId, m.SerialNo, m.Location, m.HotStatus, case len(coalesce(convert(nvarchar(10),c.ReturnDate,120),'''''''')) when 0 then coalesce(convert(nvarchar(10),m.ReturnDate,120),'''''''') else convert(nvarchar(10),c.ReturnDate,120) end as ''''ReturnDate'''', m.Missing, coalesce(convert(nvarchar(19),m.LastMoveDate,120),'''''''') as ''''LastMoveDate'''', m.BSide, m.Notes, a.AccountName, t.TypeName, coalesce(c.CaseName,'''''''') as ''''CaseName'''', coalesce(d.Code,'''''''') as ''''Disaster'''', m.Destroyed, m.RowVersion''

-- Construct the tables string
SET @tables = 
''
Medium m 
JOIN Account a
  ON a.AccountId = m.AccountId 
JOIN MediumType t 
  ON t.TypeId = m.TypeId 
LEFT JOIN (SELECT sc.SerialNo as ''''CaseName'''', msc.MediumId as ''''MediumId'''', sc.ReturnDate as ''''ReturnDate'''' FROM SealedCase sc JOIN MediumSealedCase msc ON msc.CaseId = sc.CaseId) as c 
  ON c.MediumId = m.MediumId
LEFT JOIN (SELECT c2.Code, m2.MediumId FROM DisasterCode c2 JOIN DisasterCodeMedium m2 ON c2.CodeId = m2.CodeId) as d
  ON  d.MediumId = m.MediumId
''

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
WHERE  m.SerialNo = @serialNo AND sli.Status NOT IN (1,512)

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
WHERE  m.SerialNo = @serialNo AND rli.Status NOT IN (1,512)

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
         DELETE ReceiveList WHERE ListId = @cid
--         EXECUTE @returnValue = receiveList$del @cid, @rv
         IF @@error != 0 BEGIN
--         IF @returnValue = -100 BEGIN
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
         DELETE SendList WHERE ListId = @cid
--         EXECUTE @returnValue = sendList$del @cid, @rv
         IF @@ERROR != 0 BEGIN
--         IF @returnValue = -100 BEGIN
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
         DELETE DisasterCodeList WHERE ListId = @cid
--         EXECUTE @returnValue = disasterCodeList$del @cid, @rv
         IF @@ERROR != 0 BEGIN
--         IF @returnValue = -100 BEGIN
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
      DELETE RECEIVELIST WHERE LISTID = @listId1
--      EXECUTE @returnValue = receiveList$del @listId1, @rowVersion1
   ELSE
      DELETE RECEIVELIST WHERE LISTID = @listId2
--      EXECUTE @returnValue = receiveList$del @listId2, @rowVersion2
--   IF @returnValue != 0 BEGIN
   IF @@ERROR != 0 BEGIN
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
      DELETE SENDLIST WHERE LISTID = @listId1
--      EXECUTE @returnValue = sendList$del @listId1, @rowVersion1
   ELSE
      DELETE SENDLIST WHERE LISTID = @listId2
--      EXECUTE @returnValue = sendList$del @listId2, @rowVersion2
--   IF @returnValue != 0 BEGIN
   IF @@ERROR != 0 BEGIN
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

IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'sendlist$merge')
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
AS
BEGIN
DECLARE @msg nvarchar(255)        -- used to preformat error message
DECLARE @msgTag nvarchar(255)     -- used to hold first part of error message header
DECLARE @tranName nvarchar(255)   -- used to hold name of savepoint
DECLARE @returnValue int
DECLARE @typeId int
DECLARE @default int
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
   -- Hold onto the default
   SELECT TOP 1 @default = b1.TypeId
   FROM   BarCodePattern b1
   WITH  (NOLOCK INDEX(akBarCodePattern$Position))
   ORDER  BY b1.Position DESC
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
      FROM   (
             SELECT SerialNo, TypeId FROM Medium
             UNION
             SELECT SerialNo, TypeId FROM SealedCase
             UNION
             SELECT SerialNo, TypeId FROM SendListCase
             )
        AS   x1
      WHERE  SerialNo = @serialNo
      -- Already exists?
      IF @@rowcount = 0 BEGIN
         -- Bar code format?
         SELECT TOP 1 @typeId = b1.TypeId
         FROM   BarCodePattern b1
         WITH  (NOLOCK INDEX(akBarCodePattern$Position))
         WHERE  b1.Pattern != ''.*'' AND dbo.bit$RegexMatch(@serialNo, b1.Pattern) = 1
         ORDER  BY b1.Position ASC
         -- If default, then check case formats
         IF @@rowcount = 0 BEGIN
            SELECT TOP 1 @typeId = b1.TypeId
            FROM   BarCodePatternCase b1
            WHERE  b1.Pattern != ''.*'' AND dbo.bit$RegexMatch(@serialNo, b1.Pattern) = 1
            ORDER  BY b1.Position ASC
            -- If still nothing, get the default bar code pattern
            IF @@rowcount = 0 SET @typeId = @default
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
DECLARE @i1 as int
DECLARE @i2 as int

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

-- Initialize
SELECT @i = 1

WHILE 1 = 1 BEGIN
   SELECT @p = COALESCE(min(Position),-1)
   FROM   BarCodePattern
   WHERE  Position >= @i
   IF @p = -1 BREAK
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
   SELECT @p = COALESCE(min(Position),-1)
   FROM   BarCodePatternCase
   WHERE  Position >= @i
   IF @p = -1 BREAK
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

-- If the medium is in a sealed case, then make sure the return date does not change
IF EXISTS (SELECT 1 FROM MediumSealedCase WHERE MediumId = @id) BEGIN
   SELECT @returndate = ReturnDate
   FROM   Medium
   WHERE  MediumId = @id
END

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

IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'auditTrail$getPage')
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
   @endDate datetime = null,
   @object nvarchar(512),
   @login nvarchar(64)
)
WITH ENCRYPTION 
AS
BEGIN
DECLARE @msg as nvarchar(255)        -- used to preformat error message
DECLARE @msgTag as nvarchar(255)     -- used to hold first part of error message header
DECLARE @tables nvarchar(4000)
DECLARE @fields1 nvarchar(4000)      -- innermost fields
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
SET @count = 0

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
IF @login != '''' BEGIN
   SET @where = @where + '' AND LOGIN = '''''' + @login + ''''''''
END   
IF @object != '''' BEGIN
   SET @where = @where + '' AND [OBJECT] = '''''' + @object + ''''''''
END   

-- Initialize the order clause
SET @order1 = '' ORDER BY Date desc, ItemId desc ''
SET @order2 = '' ORDER BY Date asc, ItemId asc ''

-- Create a table to hold record counts
CREATE TABLE #tbl1
(
   ItemId int,
   Date datetime,
   Object nvarchar(256),
   Action int,
   Detail nvarchar(3000),
   Login nvarchar(32),
   AuditType int,
   CONSTRAINT pk1 PRIMARY KEY CLUSTERED (Date DESC, AuditType ASC, Itemid DESC)
)

-- Loop through, inserting records into local table and keeping track of total
WHILE power(2,@i) <= @LASTAUDITTYPE BEGIN
   IF (@auditTypes & power(2,@i)) != 0 BEGIN
      -- Get audit type
      SET @auditType = cast(power(2, @i) as nvarchar(50)) --+ '' As ''''AuditType''''''
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
         SET @tables = ''(SELECT * FROM XSendList UNION SELECT * FROM XSendListItem UNION SELECT * FROM XSendListCase) AS s1''
         SET @fields1 = ''ItemId, Date, Object, Action, Detail, Login, '' + @auditType
      END
      ELSE IF power(2,@i) = @RECEIVELIST BEGIN
         SET @tables = ''(SELECT * FROM XReceiveList UNION SELECT * FROM XReceiveListItem) AS r1''
         SET @fields1 = ''ItemId, Date, Object, Action, Detail, Login, '' + @auditType
      END
      ELSE IF power(2,@i) = @DISASTERCODELIST BEGIN
         SET @tables = ''(SELECT * FROM XDisasterCodeList UNION SELECT * FROM XDisasterCodeListItem) AS c1''
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
      -- Insert into temp table
      SET @sql = ''INSERT #tbl1 (ItemId, Date, Object, Action, Detail, Login, AuditType) SELECT TOP '' + cast(@pageNo * @pageSize as nvarchar(20)) + '' '' + @fields1 + '' FROM '' + @tables + @where + @order1
      EXEC sp_executesql @sql
      -- Update the count
      SELECT @count = @count + @@rowcount
   END
   -- Increment
   SET @i = @i + 1
END

-- Select from the temp table
SET @tables  = @sql
SET @fields1 = ''ItemId, Date, Object, Action, Detail, Login, AuditType''
SET @order1  = ''ORDER BY Date desc, AuditType asc, ItemId desc''

-- If the page number is 1, then we can execute without the subquery,
-- thus increasing efficiency.  No where clause necessary here, because
-- we already filtered the results.
IF @pageNo = 1 BEGIN
   -- Rowcount
   SET ROWCOUNT @pageSize
   -- Select
   SELECT *
   FROM   #tbl1
   ORDER  BY Date DESC, AuditType ASC, ItemId DESC
   -- Rowcount
   SET ROWCOUNT 0
END
ELSE BEGIN
   SET @sql = 
   ''
   SELECT *
   FROM   (
          SELECT TOP '' + cast(@pageSize as nvarchar(20)) + '' *
          FROM   (
                 SELECT TOP '' + cast(@pageNo * @pageSize as nvarchar(20)) + '' *
                 FROM   #tbl1
                 ORDER  BY Date DESC, AuditType ASC, ItemId DESC
                 ) x1
          ORDER  BY Date ASC, AuditType DESC, ItemId ASC
          )
   ORDER  BY Date DESC, AuditType ASC, ItemId DESC
   ''
   -- Execute
   EXECUTE sp_executesql @sql
END
-- Drop table
SET @error = @@error
DROP TABLE #tbl1
-- Error?
IF @error != 0 BEGIN
   SET @msg = ''Error occurred while selecting audit records.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
   EXECUTE error$raise @msg, @error
   RETURN -100
END
-- Get the total record count and drop the table
SELECT @count as ''RecordCount''
-- Return
RETURN 0
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

IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'receivelist$clear')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.receivelist$clear
(
   @listId int,
   @rowVersion rowVersion
)
 
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

DECLARE @assignAccount nvarchar(3)
DECLARE @serialNo nvarchar(32)
DECLARE @mtype nvarchar(256)
DECLARE @aname nvarchar(256)
DECLARE @aid int

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
   -- Dissolve the list?
   IF EXISTS (SELECT 1 FROM Preference WHERE KeyNo = 18 AND Value = ''YES'') BEGIN
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
END
ELSE BEGIN
   -- Get the preference for assigning accounts
   SELECT @assignAccount = [VALUE]
   FROM   PREFERENCE
   WHERE  KEYNO = 25
   IF @@ROWCOUNT = 0 SET @assignAccount = ''NO''
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
		 -- Update medium
         IF @assignAccount = ''YES'' BEGIN
		    -- Get serial number
			SELECT @serialNo = SerialNo
			FROM   Medium
			WHERE  MediumID = @MediumID
			-- Get account default
            EXECUTE barCodePattern$getDefaults @serialNo, @mtype output, @aname output
			SELECT @aid = AccountID FROM ACCOUNT WHERE AccountName = @aname
			-- Update medium
			 UPDATE Medium
			 SET    Location = 1,
					HotStatus = 0,
					AccountID = @aid,
					ReturnDate = NULL,
					LastMoveDate = cast(convert(nchar(19),getutcdate(),120) as datetime)
			 WHERE  MediumId = @MediumId AND Missing = 0
			 -- Get error
             SET @error = @@error
         END
		 ELSE BEGIN
		     -- Update medium
             UPDATE Medium
             SET    Location = 1,
                    HotStatus = 0,
                    ReturnDate = NULL,
                    LastMoveDate = cast(convert(nchar(19),getutcdate(),120) as datetime)
             WHERE  MediumId = @MediumId AND Missing = 0
			 -- Get error
             SET @error = @@error
		 END
         -- Evaluate error
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

END
GO
-------------------------------------------------------------------------------
--
-- Constraint update
--
-------------------------------------------------------------------------------
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'XInventory' AND COLUMN_NAME = 'Date' AND CHARINDEX('getdate', COLUMN_DEFAULT) != 0)
   EXEC ('ALTER TABLE dbo.XInventory DROP CONSTRAINT defXInventory$Date')
GO
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'XInventory' AND COLUMN_NAME = 'Date' AND COLUMN_DEFAULT IS NULL)
   EXEC ('ALTER TABLE dbo.XInventory ADD CONSTRAINT defXInventory$Date DEFAULT getutcdate() FOR Date')
GO
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'XInventoryConflict' AND COLUMN_NAME = 'Date' AND CHARINDEX('getdate', COLUMN_DEFAULT) != 0)
   EXEC ('ALTER TABLE dbo.XInventoryConflict DROP CONSTRAINT defXInventoryConflict$Date')
GO
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'XInventoryConflict' AND COLUMN_NAME = 'Date' AND COLUMN_DEFAULT IS NULL)
   EXEC ('ALTER TABLE dbo.XInventoryConflict ADD CONSTRAINT defXInventoryConflict$Date DEFAULT getutcdate() FOR Date')
GO
IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.CHECK_CONSTRAINTS WHERE CONSTRAINT_NAME = 'chkFtpProfile$FileFormat')
   EXEC ('ALTER TABLE FTPPROFILE DROP CONSTRAINT chkFtpProfile$FileFormat')
GO

-------------------------------------------------------------------------------
--
-- Version update
--
-------------------------------------------------------------------------------
IF dbo.bit$doScript('1.4.3') = 1 BEGIN

IF NOT EXISTS(SELECT 1 FROM DatabaseVersion WHERE Major = 1 AND Minor = 4 AND Revision = 3) BEGIN
   DECLARE @x nvarchar(1000)
   EXECUTE spidLogin$ins 'System', 'Insert database version'
   INSERT DatabaseVersion (Major, Minor, Revision) VALUES (1, 4, 3)
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
