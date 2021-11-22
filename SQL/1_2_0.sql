-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
--
-- VaultLedger database update - version 1.2.0
--
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
SET NOCOUNT ON

-- Make sure we're using recursive triggers
DECLARE @sql nvarchar(1000)
SET @sql = 'IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = ''SpidLogin'')'
SET @sql = @sql + ' ALTER DATABASE ' + db_name() + ' SET RECURSIVE_TRIGGERS ON'
EXECUTE sp_executesql @sql
GO

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
--
-- We should have a database version check here.  If > 1.2.0, then do not
-- perform the update.
--
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
DECLARE @doScript bit
DECLARE @thisVersion nvarchar(50)
DECLARE @currentVersion nvarchar(50)

SET NOCOUNT ON

SELECT @doScript = 1
SELECT @thisVersion = '1.2.0'

IF EXISTS
   (
   SELECT 1
   FROM   DatabaseVersion
   WHERE  @thisVersion < cast(Major as nvarchar(10)) + '.' + cast(Minor as nvarchar(10)) + '.' + cast(Revision as nvarchar(10))
   )
BEGIN
   SELECT @doScript = 0
END

-- If we get here, then install it.  It's either the latest version of the
-- database or a higher version.
IF @doScript = 1 BEGIN

DECLARE @CREATE nchar(10)
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
--
-- If we have not yet updated the existing datetimes to utc, do it here
--
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
IF EXISTS 
   (
   SELECT 1
   FROM   sysobjects so
   JOIN   syscomments sc
     ON   so.id = sc.id
   WHERE  so.name = 'defXOperator$Date' and sc.text like '%getdate()%'
   )
BEGIN
   declare @tbl1 table (RowNo int identity(1,1), tableName nvarchar(128), columnName nvarchar(128))
   declare @columnName nvarchar(128)
   declare @tableName nvarchar(128)
   declare @sql nvarchar(4000)
   declare @hrs nchar(2)
   declare @i int
   
   set nocount on
   
   set @hrs = cast(datediff(hh, getdate(), getutcdate()) as nchar(2))
   set @i = 1
   
   insert @tbl1 (tableName, columnName)
   select TABLE_NAME, COLUMN_NAME
   from   information_schema.columns
   where  TABLE_NAME LIKE 'X%' AND COLUMN_NAME = 'Date' AND DATA_TYPE = 'datetime'
   
   insert @tbl1 (tableName, columnName) values ('DatabaseVersion', 'InstallDate')
   insert @tbl1 (tableName, columnName) values ('DisasterCodeList', 'CreateDate')
   insert @tbl1 (tableName, columnName) values ('Medium', 'LastMoveDate')
   insert @tbl1 (tableName, columnName) values ('Operator', 'LastLogin')
   insert @tbl1 (tableName, columnName) values ('ProductLicense', 'Issued')
   insert @tbl1 (tableName, columnName) values ('RecallTicket', 'CreateDate')
   insert @tbl1 (tableName, columnName) values ('ReceiveList', 'CreateDate')
   insert @tbl1 (tableName, columnName) values ('ReceiveListScan', 'Compared')
   insert @tbl1 (tableName, columnName) values ('ReceiveListScan', 'CreateDate')
   insert @tbl1 (tableName, columnName) values ('SendList', 'CreateDate')
   insert @tbl1 (tableName, columnName) values ('SendListScan', 'Compared')
   insert @tbl1 (tableName, columnName) values ('SendListScan', 'CreateDate')
   insert @tbl1 (tableName, columnName) values ('SpidLogin', 'LastCall')
   insert @tbl1 (tableName, columnName) values ('VaultDiscrepancy', 'RecordedDate')
   insert @tbl1 (tableName, columnName) values ('VaultInventory', 'DownloadTime')
   
   while 1 = 1 begin
      select @tableName = tableName, @columnName = columnName
      from   @tbl1
      where  RowNo = @i
      if @@rowcount = 0 break
      -- disable trigger
      set @sql = 'ALTER TABLE ' + @tableName + ' DISABLE TRIGGER ALL'
      execute sp_executesql @sql
      -- do update
      set @sql = 'UPDATE ' + @tableName + ' SET ' + @columnName + ' = DATEADD(hh, ' + @hrs + ', ' + @columnName + ') WHERE DATEPART(yyyy, ' + @columnName + ') > 2000'
      execute sp_executesql @sql
      -- enable trigger
      set @sql = 'ALTER TABLE ' + @tableName + ' ENABLE TRIGGER ALL'
      execute sp_executesql @sql
      -- Increment
      set @i = @i + 1
   end
END

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
--
-- Indexes to speed up list creation
--
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
IF NOT EXISTS (SELECT 1 FROM sysobjects WHERE name = 'SendListItem' AND indexproperty(id, 'ixSendListItem$ListId$Status', 'IndexID') IS NOT NULL)
   CREATE NONCLUSTERED INDEX ixSendListItem$ListId$Status ON SendListItem (ListId, Status)

IF NOT EXISTS (SELECT 1 FROM sysobjects WHERE name = 'SendListItem' AND indexproperty(id, 'ixSendListItem$MediumId$Status', 'IndexID') IS NOT NULL)
   CREATE NONCLUSTERED INDEX ixSendListItem$MediumId$Status ON SendListItem (MediumId, Status)

IF NOT EXISTS (SELECT 1 FROM sysobjects WHERE name = 'ReceiveListItem' AND indexproperty(id, 'ixReceiveListItem$ListId$Status', 'IndexID') IS NOT NULL)
   CREATE NONCLUSTERED INDEX ixReceiveListItem$ListId$Status ON ReceiveListItem (ListId, Status)

IF NOT EXISTS (SELECT 1 FROM sysobjects WHERE name = 'ReceiveListItem' AND indexproperty(id, 'ixReceiveListItem$MediumId$Status', 'IndexID') IS NOT NULL)
   CREATE NONCLUSTERED INDEX ixReceiveListItem$MediumId$Status ON ReceiveListItem (MediumId, Status)
 
IF NOT EXISTS (SELECT 1 FROM sysobjects WHERE name = 'Medium' AND indexproperty(id, 'ixMedium$BSide', 'IndexID') IS NOT NULL)
   CREATE NONCLUSTERED INDEX ixMedium$BSide ON Medium (BSide)

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
--
-- Other stored procedures not related to UTC
--
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'disasterCodeListItem$getPage')
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
   SET @order1 = '' ORDER BY dli.Code asc, SerialNo asc''
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
SET @fields2 = ''ItemId, Status, SerialNo, AccountName, Code, Notes, RowVersion''
SET @fields1 = ''dli.ItemId, dli.Status, coalesce(lm.SerialNo,lc.SerialNo) as ''''SerialNo'''', coalesce(lm.AccountName,'''''''') as ''''AccountName'''', dli.Code, coalesce(lm.Notes,lc.Notes) as ''''Notes'''', dli.RowVersion''

-- Construct the tables string
SET @tables = ''DisasterCodeListItem dli JOIN DisasterCodeList dl ON dl.ListId = dli.ListId LEFT OUTER JOIN (SELECT dlim.ItemId, m.SerialNo, a.AccountName, m.Notes FROM DisasterCodeListItemMedium dlim JOIN Medium m ON m.MediumId = dlim.MediumId JOIN Account a ON a.AccountId = m.AccountId) as lm ON lm.ItemId = dli.ItemId LEFT OUTER JOIN (SELECT dlic.ItemId, sc.SerialNo, sc.Notes FROM DisasterCodeListItemCase dlic JOIN SealedCase sc ON sc.CaseId = dlic.CaseId) as lc ON lc.ItemId = dli.ItemId''

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

IF EXISTS(SELECT * FROM sysobjects WHERE name = 'disasterCodeMedium$afterDelete' AND objectproperty(id, 'ExecIsDeleteTrigger' ) = 1) 
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
DECLARE @lastMedium int
DECLARE @codeId int
DECLARE @error int

SET @rowCount = @@rowcount
IF @rowCount = 0 RETURN

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

SELECT @lastMedium = 0
WHILE 1 = 1 BEGIN
   SELECT TOP 1 @lastMedium = d.MediumId,
          @codeId = d.CodeId,
          @serialNo = m.SerialNo
   FROM   Deleted d
   JOIN   Medium m
     ON   m.MediumId = d.MediumId
   WHERE  d.MediumId > @lastMedium
   ORDER BY d.MediumId ASC
   IF @@rowCount = 0
      BREAK
   ELSE BEGIN
      SELECT @codeName = case len(Code) when 0 then ''(empty)'' else Code end
      FROM   DisasterCode 
      WHERE  CodeId = @codeId
      -- Insert the audit record   
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
         2, 
         ''Disaster code '' + @codeName + '' unassigned'', 
         dbo.string$GetSpidLogin()
      )
      SET @error = @@error
      IF @error != 0 BEGIN
         SET @msg = ''Error encountered while inserting a row into the medium audit table.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
         EXECUTE error$raise @msg, @error, @tranName
         RETURN
      END
      -- If code has no entries left, delete it
      IF NOT EXISTS(SELECT 1 FROM DisasterCodeMedium WHERE CodeId = @codeId) AND
         NOT EXISTS(SELECT 1 FROM DisasterCodeCase WHERE CodeId = @codeId)
      BEGIN
         DELETE DisasterCode 
         WHERE  CodeId = @codeId
         SET @error = @@error
         IF @error != 0 BEGIN
            SET @msg = ''Error encountered while deleting disaster code.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
            EXECUTE error$raise @msg, @error, @tranName
            RETURN
         END
      END
   END
END

-- Commit transaction
COMMIT TRANSACTION
END
'
)

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'disasterCodeList$transmit')
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
FROM   DisasterCodeList
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

IF EXISTS(SELECT * FROM sysobjects WHERE name = 'disasterCodeListItemMedium$afterInsert' AND objectproperty(id, 'ExecIsInsertTrigger' ) = 1) 
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'TRIGGER disasterCodeListItemMedium$afterInsert
ON     DisasterCodeListItemMedium
WITH ENCRYPTION
AFTER  INSERT
AS
BEGIN
DECLARE @msg nvarchar(255)        -- used to preformat error message
DECLARE @msgTag nvarchar(255)     -- used to hold first part of error message header
DECLARE @tranName nvarchar(255)   -- used to hold name of savepoint
DECLARE @listName nchar(10)       -- holds the name of the disaster code list
DECLARE @listStatus int           -- holds the status of the list
DECLARE @serialNo nvarchar(32)    -- holds the serial number of the medium
DECLARE @itemStatus nvarchar(32)  -- holds the initial status of the item
DECLARE @rowCount int             -- holds the number of rows in the Inserted table
DECLARE @rowVersion rowversion
DECLARE @accountId int            
DECLARE @status int            
DECLARE @listId int            
DECLARE @error int            

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
   SET @msg = ''Batch insert into disaster code list item table not allowed.'' + @msgTag + ''>''
   EXECUTE error$raise @msg, 0, @tranName
   RETURN
END

-- Get the caller login from the spidLogin table
IF len(dbo.string$GetSpidLogin()) = 0 BEGIN
   SET @msg = ''Login not found for auditing purposes.'' + @msgTag + ''>''
   EXECUTE error$raise @msg, 0, @tranName
   RETURN
END

-- Verify that the list to which the item was inserted has not yet been transmitted.  Also
-- make sure that the medium belongs to the same account as the list
SELECT @listId = dli.ListId,
       @listName = dl.ListName,
       @listStatus  = dl.Status,
       @accountId = dl.AccountId
FROM   DisasterCodeList dl
JOIN   DisasterCodeListItem dli
  ON   dli.ListId = dl.ListId
WHERE  dli.ItemId = (SELECT ItemId FROM Inserted)

IF @listStatus >= 4 BEGIN
   SET @msg = ''Items cannot be added to a list that has already been '' + dbo.string$statusName(4,@listStatus) + ''.'' + @msgTag + ''>''
   EXECUTE error$raise @msg, 0, @tranName
   RETURN
END
ELSE IF NOT EXISTS(SELECT 1 FROM Medium WHERE MediumId = (SELECT MediumId FROM Inserted) AND AccountId = @accountId) BEGIN
   SET @msg = ''Medium must belong to same account as the list itself.'' + @msgTag + ''>''
   EXECUTE error$raise @msg, 0, @tranName
   RETURN
END

-- Select the medium serial number from the Inserted table
SELECT @serialNo = SerialNo 
FROM   Medium 
WHERE  MediumId = (SELECT MediumId FROM Inserted)

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
   ''Medium '''''' + @serialNo + '''''' added to list'',
   dbo.string$GetSpidLogin()
)
SET @error = @@error
IF @error != 0 BEGIN
   SET @msg = ''Error encountered while inserting disaster code list item audit record.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
   EXECUTE error$raise @msg, @error, @tranName
   RETURN
END

-- Commit
COMMIT TRANSACTION
END
'
)

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
--
-- Stored Procedures for UTC time adjustment
--
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'databaseVersion$upd')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.databaseVersion$upd
(
   @major int,
   @minor int,
   @revision int
)
WITH ENCRYPTION
AS
BEGIN
DECLARE @msg as nvarchar(255)      -- used to preformat error message
DECLARE @msgTag as nvarchar(255)    -- used to hold first part of error message header
DECLARE @tranName as nvarchar(255)   -- used to hold name of savepoint
DECLARE @error as int

SET NOCOUNT ON

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=P''
SET @tranName = object_name(@@procid) + CAST(@@nestlevel as nvarchar(2))

IF NOT EXISTS
   (
   SELECT 1 
   FROM   DatabaseVersion 
   WHERE  Major = @major AND Minor = @minor AND Revision = @revision
   )
BEGIN
	BEGIN TRANSACTION
	SAVE TRANSACTION @tranName
	-- Insert the new database version if it does not yet exist
	INSERT DatabaseVersion (Major, Minor, Revision)	
   VALUES (@major, @minor, @revision)
	-- Evaluate any error
	SET @error = @@error
	IF @error != 0 BEGIN
	   ROLLBACK TRANSACTION @tranName
	   COMMIT TRANSACTION
	   SET @msg = ''Error encountered while inserting database version.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
	   EXECUTE error$raise @msg, @error
	   RETURN -100
	END
	-- Commit the transaction
	COMMIT TRANSACTION
END

-- Return
RETURN 0
END
'
)

IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'disasterCodeList$create')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.disasterCodeList$create
(
   @accountId int,
   @listName nchar(10) OUTPUT
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

-- Begin the transaction
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

-- Get the new list name
EXEC @returnValue = nextListNumber$getName ''DC'', @listName OUT
IF @returnValue != 0 BEGIN
   ROLLBACK TRANSACTION @tranName
   COMMIT TRANSACTION
   RETURN -100
END

-- Insert the new list record
INSERT DisasterCodeList
(
   ListName, 
   CreateDate, 
   AccountId
)
VALUES
(
   @listName,
   cast(convert(nchar(19),getutcdate(),120) as datetime),
   @accountId
)
SET @error = @@error
IF @error != 0 BEGIN
   ROLLBACK TRANSACTION @tranName
   COMMIT TRANSACTION
   SET @msg = ''Error encountered while inserting a new disaster code list.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
   EXECUTE error$raise @msg, @error
   RETURN -100
END

-- Commit and return
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
DECLARE @typeId as int
DECLARE @error as int

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
WHERE  AccountName = @account
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

IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'receiveList$create')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.receiveList$create
(
   @accountId int,
   @listName nchar(10) OUTPUT
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

-- Begin the transaction
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

-- Get the new list name
EXEC @returnValue = nextListNumber$getName ''RE'', @listName OUT
IF @returnValue != 0 BEGIN
   ROLLBACK TRANSACTION @tranName
   COMMIT TRANSACTION
   RETURN -100
END

-- Insert the new list record
INSERT ReceiveList
(
   ListName, 
   CreateDate, 
   AccountId
)
VALUES
(
   @listName,
   cast(convert(nchar(19),getutcdate(),120) as datetime),
   @accountId
)
SET @error = @@error
IF @error != 0 BEGIN
   ROLLBACK TRANSACTION @tranName
   COMMIT TRANSACTION
   SET @msg = ''Error encountered while inserting a new receive list.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
   EXECUTE error$raise @msg, @error
   RETURN -100
END

-- Commit and return
COMMIT TRANSACTION
RETURN 0
END
'
)

IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'receiveListScan$compare')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.receiveListScan$compare
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
   SELECT rlsi.SerialNo
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
   SELECT rlsi.SerialNo
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

IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'sendList$create')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.sendList$create
(
   @accountId int,
   @listName nchar(10) OUTPUT
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

-- Begin the transaction
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

-- Get the new list name
EXEC @returnValue = nextListNumber$getName ''SD'', @listName OUT
IF @returnValue != 0 BEGIN
   ROLLBACK TRANSACTION @tranName
   COMMIT TRANSACTION
   RETURN -100
END

-- Insert the new list record
INSERT SendList
(
   ListName, 
   CreateDate, 
   AccountId
)
VALUES
(
   @listName,
   cast(convert(nchar(19),getutcdate(),120) as datetime),
   @accountId
)
SET @error = @@error
IF @error != 0 BEGIN
   ROLLBACK TRANSACTION @tranName
   COMMIT TRANSACTION
   SET @msg = ''Error encountered while inserting a new send list.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
   EXECUTE error$raise @msg, @error
   RETURN -100
END

-- Commit and return
COMMIT TRANSACTION
RETURN 0
END
'
)

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
DECLARE @tbl2 table 
(
   ItemId int, 
   SerialNo nvarchar(32), 
   ListCase nvarchar(128), 
   ScanCase nvarchar(128)
)

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
   INSERT @tbl2 (ItemId, SerialNo, ListCase, ScanCase)
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
          same.SerialNo IS NULL AND
         (sl.ListId = @listId OR coalesce(sl.CompositeId,0) = @listId)
   --
   -- Select serial numbers from table to obtain result set
   --
   SELECT SerialNo, ListCase, ScanCase
   FROM   @tbl2
   ORDER  BY SerialNo ASC
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
LEFT   JOIN @tbl2 t2
  ON   t2.ItemId = sli.ItemId
WHERE  sli.Status NOT IN (1,256,512) AND
       t1.ItemId IS NULL AND t2.ItemId IS NULL AND
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

IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'spidLogin$del')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.spidLogin$del
(
   @allTags bit = 0
)
WITH ENCRYPTION
AS

BEGIN
DECLARE @msg as nvarchar(255)        -- used to preformat error message
DECLARE @msgTag as nvarchar(255)     -- used to hold first part of error message header
DECLARE @tranName as nvarchar(255)   -- used to hold name of savepoint
DECLARE @lastCall datetime
DECLARE @seqNo int
DECLARE @error int
DECLARE @spid int

SET NOCOUNT ON

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=P''
SET @tranName = object_name(@@procid) + CAST(@@nestlevel as nvarchar(2))

BEGIN TRANSACTION
SAVE TRANSACTION @tranName

-- Delete the spid
IF @allTags = 1 BEGIN
   DELETE SpidLogin
   WHERE  Spid = @@spid
END
ELSE BEGIN
   SELECT TOP 1 @seqNo = SeqNo
   FROM   SpidLogin
   WHERE  Spid = @@spid
   ORDER BY SeqNo DESC
   IF @@rowcount != 0 BEGIN
      DELETE SpidLogin
      WHERE  Spid = @@spid AND SeqNo = @seqNo
   END
END
SET @error = @@error
IF @error != 0 BEGIN
   SET @msg = ''Error deleting audit information.'' + @msgTag + ''>''
   EXECUTE error$raise @msg, @error, @tranName
   RETURN -100
END

-- Clean any outdated spids (three hours old or greater)
SELECT @spid = 0
WHILE 1 = 1 BEGIN
   SELECT TOP 1 @spid = Spid, @lastCall = LastCall
   FROM   SpidLogin
   WITH  (READPAST)
   WHERE  @spid >= @spid AND 
          datediff(mi, LastCall, getutcdate()) > 180
   ORDER  BY Spid ASC, SeqNo ASC
   IF @@rowCount = 0
      BREAK
   ELSE BEGIN
      DELETE SpidLogin 
      WHERE  Spid = @spid
   END
END

COMMIT TRANSACTION
RETURN 0
END
'
)

IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'spidLogin$ins')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.spidLogin$ins
(
   @login nvarchar(32),
   @newTag nvarchar(1000)
)
WITH ENCRYPTION
AS
BEGIN
DECLARE @msg as nvarchar(255)        -- used to preformat error message
DECLARE @msgTag as nvarchar(255)     -- used to hold first part of error message header
DECLARE @tranName as nvarchar(255)   -- used to hold name of savepoint
DECLARE @seqNo as int
DECLARE @error as int

SET NOCOUNT ON

-- Tweak parameters
SET @newTag = ltrim(rtrim(isnull(@newTag,'''')))
SET @seqNo = 1

-- If no login supplied, get the last one
IF len(isnull(@login,'''')) = 0 BEGIN
   SELECT TOP 1 @login = Login
   FROM   SpidLogin
   WHERE  Spid = @@spid
   ORDER  BY SeqNo DESC
   -- If still none, use empty string
   IF @@rowcount = 0 SET @login = ''''
END

-- Get the sequence number
IF EXISTS (SELECT 1 FROM SpidLogin WHERE Spid = @@spid) BEGIN
   SELECT TOP 1 @seqNo = SeqNo + 1
   FROM   SpidLogin
   WHERE  Spid = @@spid
   ORDER  BY SeqNo DESC
END

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=P''
SET @tranName = object_name(@@procid) + CAST(@@nestlevel as nvarchar(2))

-- Begin transaction
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

-- Insert a new spid login record
INSERT SpidLogin (Spid, Login, LastCall, TagInfo, SeqNo)
VALUES (@@spid, @login, getutcdate(), @newTag, @seqNo)
SET @error = @@error
IF @error != 0 BEGIN
   SET @msg = ''Error encountered while inserting spid login.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
   EXECUTE error$raise @msg, @error, @tranName
   RETURN -100
END

-- Commit the transaction
COMMIT TRANSACTION
RETURN 0
END
'
)

IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'vaultInventory$compareCases')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.vaultInventory$compareCases
(
   @inventoryId int
)
WITH ENCRYPTION
AS
BEGIN
DECLARE @i int
DECLARE @msg nvarchar(255)        -- used to preformat error message
DECLARE @msgTag nvarchar(255)     -- used to hold first part of error message header
DECLARE @tranName nvarchar(255)   -- used to hold name of savepoint
DECLARE @serialNo nvarchar(64)
DECLARE @timeNow datetime
DECLARE @error int
DECLARE @itemId int
DECLARE @rowCount int
DECLARE @returnValue int
DECLARE @tblSerial table 
(
   RowNo int PRIMARY KEY IDENTITY(1,1),
   SerialNo nvarchar(64)
)

SET NOCOUNT ON

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=P''
SET @tranName = object_name(@@procid) + CAST(@@nestlevel as nvarchar(2))
SET @timeNow = cast(convert(nvarchar(19), getutcdate(), 120) as datetime)

INSERT @tblSerial (SerialNo)
SELECT vi.SerialNo
FROM   VaultInventoryItem vi
LEFT OUTER JOIN SealedCase sc
  ON   sc.SerialNo = vi.SerialNo
WHERE  sc.SerialNo IS NULL AND
       vi.InventoryId = @inventoryId AND
       dbo.bit$IsContainerType(vi.TypeId) = 1

SELECT @i = 1, @rowCount = count(*)
FROM   @tblSerial

-- Begin the transaction
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

WHILE @i <= @rowCount BEGIN
   -- Get the next serial number
   SELECT @serialNo = SerialNo
   FROM   @tblSerial
   WHERE  RowNo = @i
   -- If it exists in the table, update the recorded date
   SELECT @itemId = ItemId 
   FROM   VaultDiscrepancyUnknownCase
   WHERE  SerialNo = @serialNo
   IF @@rowCount > 0 BEGIN
      EXECUTE @returnValue = vaultDiscrepancy$upd @itemId, @timeNow
      IF @returnValue != 0 BEGIN
         ROLLBACK TRANSACTION @tranName
         COMMIT TRANSACTION
         RETURN -100
      END
   END
   ELSE BEGIN
      INSERT VaultDiscrepancy (RecordedDate) 
      VALUES (getutcdate())
      SET @error = @@error
      IF @error != 0 BEGIN
         ROLLBACK TRANSACTION @tranName
         COMMIT TRANSACTION
         SET @msg = ''Error encountered while inserting vault discrepancy.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
         EXECUTE error$raise @msg, @error
         RETURN -100
      END
      INSERT VaultDiscrepancyUnknownCase (ItemId,SerialNo)
      VALUES (scope_identity(),@serialNo)
      SET @error = @@error
      IF @error != 0 BEGIN
         ROLLBACK TRANSACTION @tranName
         COMMIT TRANSACTION
         SET @msg = ''Error encountered while inserting vault unknown case discrepancy.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
         EXECUTE error$raise @msg, @error
         RETURN -100
      END
   END
   -- Increment counter
   SET @i = @i + 1
END

COMMIT TRANSACTION
RETURN 0
END
'
)

IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'vaultInventory$compareCaseTypes')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.vaultInventory$compareCaseTypes
(
   @inventoryId int
)
WITH ENCRYPTION
AS
BEGIN
DECLARE @i int
DECLARE @msg nvarchar(255)        -- used to preformat error message
DECLARE @msgTag nvarchar(255)     -- used to hold first part of error message header
DECLARE @tranName nvarchar(255)   -- used to hold name of savepoint
DECLARE @serialNo nvarchar(64)
DECLARE @timeNow datetime
DECLARE @error int
DECLARE @typeId int
DECLARE @itemId int
DECLARE @caseId int
DECLARE @rowCount int
DECLARE @returnValue int
DECLARE @tblType table 
(
   RowNo int PRIMARY KEY IDENTITY(1,1),
   CaseId int,
   SerialNo nvarchar(32),
   TypeId int
)

SET NOCOUNT ON

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=P''
SET @tranName = object_name(@@procid) + CAST(@@nestlevel as nvarchar(2))
SET @timeNow = cast(convert(nvarchar(19), getutcdate(), 120) as datetime)

INSERT @tblType (CaseId, SerialNo, TypeId)
SELECT sc.CaseId, sc.SerialNo, vii.TypeId
FROM   SealedCase sc
JOIN   VaultInventoryItem vii
  ON   vii.SerialNo = sc.SerialNo
WHERE  sc.TypeId != vii.TypeId AND
       vii.InventoryId = @inventoryId AND
       dbo.bit$IsContainerType(vii.TypeId) = 1

SELECT @i = 1, @rowCount = count(*)
FROM   @tblType

BEGIN TRANSACTION
SAVE TRANSACTION @tranName

WHILE @i <= @rowCount BEGIN
   -- Get the next case
   SELECT @caseId = CaseId, 
          @serialNo = SerialNo,
          @typeId = TypeId
   FROM   @tblType
   WHERE  RowNo = @i
   -- If it exists in the table, update the recorded date
   SELECT @itemId = ItemId 
   FROM   VaultDiscrepancyCaseType
   WHERE  CaseId = @caseId
   IF @@rowCount > 0 BEGIN
      EXECUTE @returnValue = vaultDiscrepancy$upd @itemId, @timeNow
      IF @returnValue != 0 BEGIN
         ROLLBACK TRANSACTION @tranName
         COMMIT TRANSACTION
         RETURN -100
      END
      ELSE BEGIN
         UPDATE VaultDiscrepancyCaseType
         SET    VaultType = @typeId
         WHERE  ItemId = @itemId
         SET @error = @@error
         IF @error != 0 BEGIN
            ROLLBACK TRANSACTION @tranName
            COMMIT TRANSACTION
            SET @msg = ''Error encountered while updating case type vault discrepancy.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
            EXECUTE error$raise @msg, @error
            RETURN -100
         END
      END
   END
   ELSE BEGIN
      INSERT VaultDiscrepancy (RecordedDate) 
      VALUES (getutcdate())
      SET @error = @@error
      IF @error != 0 BEGIN
         ROLLBACK TRANSACTION @tranName
         COMMIT TRANSACTION
         SET @msg = ''Error encountered while inserting vault discrepancy.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
         EXECUTE error$raise @msg, @error
         RETURN -100
      END
      INSERT VaultDiscrepancyCaseType (ItemId,CaseId,SerialNo,VaultType) 
      VALUES (scope_identity(),@caseId,@serialNo,@typeId)
      SET @error = @@error
      IF @error != 0 BEGIN
         ROLLBACK TRANSACTION @tranName
         COMMIT TRANSACTION
         SET @msg = ''Error encountered while inserting case type vault discrepancy.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
         EXECUTE error$raise @msg, @error
         RETURN -100
      END
   END
   -- Increment counter
   SET @i = @i + 1
END

COMMIT TRANSACTION
RETURN 0
END
'
)

IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'vaultInventory$compareMediumAccounts')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.vaultInventory$compareMediumAccounts
(
   @inventoryId int
)
WITH ENCRYPTION
AS
BEGIN
DECLARE @i int
DECLARE @msg nvarchar(255)        -- used to preformat error message
DECLARE @msgTag nvarchar(255)     -- used to hold first part of error message header
DECLARE @tranName nvarchar(255)   -- used to hold name of savepoint
DECLARE @serialNo nvarchar(64)
DECLARE @timeNow datetime
DECLARE @error int
DECLARE @typeId int
DECLARE @itemId int
DECLARE @accountId int
DECLARE @mediumId int
DECLARE @rowCount int
DECLARE @oldAccount int
DECLARE @returnValue int
DECLARE @tblAccount table 
(
   RowNo int PRIMARY KEY IDENTITY(1,1),
   MediumId int,
   SerialNo nvarchar(64),
   AccountId int
)

SET NOCOUNT ON

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=P''
SET @tranName = object_name(@@procid) + CAST(@@nestlevel as nvarchar(2))
SET @timeNow = cast(convert(nvarchar(19), getutcdate(), 120) as datetime)

INSERT @tblAccount (MediumId, SerialNo, AccountId)
SELECT m.MediumId, m.SerialNo, vi.AccountId
FROM   Medium m
JOIN   VaultInventoryItem vii
  ON   vii.SerialNo = m.SerialNo
JOIN   VaultInventory vi
  ON   vi.InventoryId = vii.InventoryId
JOIN   Account a
  ON   a.AccountId = vi.AccountId
WHERE  m.AccountId != a.AccountId AND
       vii.InventoryId = @inventoryId AND
       dbo.bit$IsContainerType(vii.TypeId) = 0

SELECT @i = 1, @rowCount = count(*)
FROM   @tblAccount

BEGIN TRANSACTION
SAVE TRANSACTION @tranName

WHILE @i <= @rowCount BEGIN
   -- Get the next medium
   SELECT @mediumId = MediumId,
          @serialNo = SerialNo,
          @accountId = AccountId
   FROM   @tblAccount
   WHERE  RowNo = @i
   -- If it exists in the table, update the recorded date
   SELECT @itemId = ItemId,
          @oldAccount = VaultAccount
   FROM   VaultDiscrepancyAccount
   WHERE  MediumId = @mediumId
   IF @@rowCount > 0 BEGIN
      EXECUTE @returnValue = vaultDiscrepancy$upd @itemId, @timeNow
      IF @returnValue != 0 BEGIN
         ROLLBACK TRANSACTION @tranName
         COMMIT TRANSACTION
         RETURN -100
      END
      -- Update the account if different
      IF @oldAccount != @accountId BEGIN
         UPDATE VaultDiscrepancyAccount
         SET    VaultAccount = @accountId
         WHERE  ItemId = @itemId
         SET @error = @@error
         IF @error != 0 BEGIN
            ROLLBACK TRANSACTION @tranName
            COMMIT TRANSACTION
            SET @msg = ''Error encountered while updating vault account discrepancy.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
            EXECUTE error$raise @msg, @error
            RETURN -100
         END
      END
   END
   ELSE BEGIN
      INSERT VaultDiscrepancy (RecordedDate) 
      VALUES (getutcdate())
      SET @error = @@error
      IF @error != 0 BEGIN
         ROLLBACK TRANSACTION @tranName
         COMMIT TRANSACTION
         SET @msg = ''Error encountered while inserting vault discrepancy.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
         EXECUTE error$raise @msg, @error
         RETURN -100
      END
      INSERT VaultDiscrepancyAccount (ItemId,MediumId,SerialNo,VaultAccount) 
      VALUES (scope_identity(),@mediumId,@serialNo,@accountId)
      SET @error = @@error
      IF @error != 0 BEGIN
         ROLLBACK TRANSACTION @tranName
         COMMIT TRANSACTION
         SET @msg = ''Error encountered while inserting vault account discrepancy.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
         EXECUTE error$raise @msg, @error
         RETURN -100
      END
   END
   -- Increment counter
   SET @i = @i + 1
END

COMMIT TRANSACTION
RETURN 0
END
'
)

IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'vaultInventory$compareMediumTypes')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.vaultInventory$compareMediumTypes
(
   @inventoryId int
)
WITH ENCRYPTION
AS
BEGIN
DECLARE @i int
DECLARE @msg nvarchar(255)        -- used to preformat error message
DECLARE @msgTag nvarchar(255)     -- used to hold first part of error message header
DECLARE @tranName nvarchar(255)   -- used to hold name of savepoint
DECLARE @serialNo nvarchar(64)
DECLARE @timeNow datetime
DECLARE @error int
DECLARE @typeId int
DECLARE @itemId int
DECLARE @rowCount int
DECLARE @mediumId int
DECLARE @returnValue int
DECLARE @tblType table 
(
   RowNo int PRIMARY KEY IDENTITY(1,1),
   MediumId int,
   SerialNo nvarchar(32),
   TypeId int
)

SET NOCOUNT ON

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=P''
SET @tranName = object_name(@@procid) + CAST(@@nestlevel as nvarchar(2))
SET @timeNow = cast(convert(nvarchar(19), getutcdate(), 120) as datetime)

INSERT @tblType (MediumId, SerialNo, TypeId)
SELECT m.MediumId, m.SerialNo, vii.TypeId
FROM   Medium m
JOIN   VaultInventoryItem vii
  ON   vii.SerialNo = m.SerialNo
WHERE  m.TypeId != vii.TypeId AND
       vii.InventoryId = @inventoryId AND
       dbo.bit$IsContainerType(vii.TypeId) = 0

SELECT @i = 1, @rowCount = count(*)
FROM   @tblType

BEGIN TRANSACTION
SAVE TRANSACTION @tranName

WHILE @i <= @rowCount BEGIN
   -- Get the next medium
   SELECT @mediumId = MediumId, 
          @serialNo = SerialNo,
          @typeId = TypeId
   FROM   @tblType
   WHERE  RowNo = @i
   -- If it exists in the table, update the recorded date
   SELECT @itemId = ItemId 
   FROM   VaultDiscrepancyMediumType
   WHERE  MediumId = @mediumId
   IF @@rowCount > 0 BEGIN
      EXECUTE @returnValue = vaultDiscrepancy$upd @itemId, @timeNow
      IF @returnValue != 0 BEGIN
         ROLLBACK TRANSACTION @tranName
         COMMIT TRANSACTION
         RETURN -100
      END
      ELSE BEGIN
         UPDATE VaultDiscrepancyMediumType
         SET    VaultType = @typeId
         WHERE  ItemId = @itemId
         SET @error = @@error
         IF @error != 0 BEGIN
            ROLLBACK TRANSACTION @tranName
            COMMIT TRANSACTION
            SET @msg = ''Error encountered while updating medium type vault discrepancy.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
            EXECUTE error$raise @msg, @error
            RETURN -100
         END
      END
   END
   ELSE BEGIN
      INSERT VaultDiscrepancy (RecordedDate) 
      VALUES (getutcdate())
      SET @error = @@error
      IF @error != 0 BEGIN
         ROLLBACK TRANSACTION @tranName
         COMMIT TRANSACTION
         SET @msg = ''Error encountered while inserting vault discrepancy.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
         EXECUTE error$raise @msg, @error
         RETURN -100
      END
      INSERT VaultDiscrepancyMediumType (ItemId,MediumId,SerialNo,VaultType) 
      VALUES (scope_identity(),@mediumId,@serialNo,@typeId)
      SET @error = @@error
      IF @error != 0 BEGIN
         ROLLBACK TRANSACTION @tranName
         COMMIT TRANSACTION
         SET @msg = ''Error encountered while inserting medium type vault discrepancy.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
         EXECUTE error$raise @msg, @error
         RETURN -100
      END
   END
   -- Increment counter
   SET @i = @i + 1
END

COMMIT TRANSACTION
RETURN 0
END
'
)

IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'vaultInventory$compareResidency')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.vaultInventory$compareResidency
(
   @inventoryId int
)
WITH ENCRYPTION
AS
BEGIN
DECLARE @i int
DECLARE @msg nvarchar(255)        -- used to preformat error message
DECLARE @msgTag nvarchar(255)     -- used to hold first part of error message header
DECLARE @tranName nvarchar(255)   -- used to hold name of savepoint
DECLARE @serialNo nvarchar(64)
DECLARE @timeNow datetime
DECLARE @exclude int
DECLARE @error int
DECLARE @itemId int
DECLARE @rowCount int
DECLARE @mediumId int
DECLARE @returnValue int
DECLARE @tblMedium table 
(
   RowNo int PRIMARY KEY IDENTITY(1,1),
   MediumId int, 
   SerialNo nvarchar(64)
)

SET NOCOUNT ON

SET @exclude = 0

-- Find out if we are excluding tapes on active lists or not
IF EXISTS (SELECT 1 FROM Preference WHERE KeyNo = 6 AND Value IN (''YES'',''TRUE''))
   SET @exclude = @exclude + 1
-- Find out if we are excluding tapes on today''s lists or not
IF EXISTS (SELECT 1 FROM Preference WHERE KeyNo = 7 AND Value IN (''YES'',''TRUE''))
   SET @exclude = @exclude + 2

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=P''
SET @tranName = object_name(@@procid) + CAST(@@nestlevel as nvarchar(2))
SET @timeNow = cast(convert(nvarchar(19), getutcdate(), 120) as datetime)

-- Residence claims by the vault pertain only to the inventory in question.  Residence
-- denials, however, deal with all inventories.  The basis for a denial is if (a) a
-- particular tape does not appear in ANY inventory file as residing at the vault, 
-- and (b) at least one inventory exists for the account currently listed as the
-- account of the tape.
IF @exclude = 0 BEGIN
	INSERT @tblMedium (MediumId, SerialNo)
	SELECT m.MediumId, m.SerialNo               -- Vault claims residence
	FROM   Medium m
	JOIN  (SELECT vii.SerialNo
	       FROM   VaultInventoryItem vii
	       WHERE  vii.InventoryId = @inventoryId AND
	              dbo.bit$IsContainerType(vii.TypeId) = 0
	       UNION
	       SELECT m.SerialNo
	       FROM   Medium m
	       JOIN   MediumSealedCase msc
	         ON   msc.MediumId = m.MediumId
	       JOIN   SealedCase sc
	         ON   sc.CaseId = msc.CaseId
	       JOIN   VaultInventoryItem vii
	         ON   vii.SerialNo = sc.SerialNo
	       WHERE  vii.InventoryId = @inventoryId AND
	              dbo.bit$IsContainerType(vii.TypeId) = 1) as atVault  -- Media at vault (specified inventory)
	  ON   atVault.SerialNo = m.SerialNo
	WHERE  m.Location = 1
	UNION
	SELECT m.MediumId, m.SerialNo               -- Vault refutes residence
	FROM   Medium m
	LEFT   JOIN
	      (SELECT vii.SerialNo
	       FROM   VaultInventoryItem vii
	       WHERE  dbo.bit$IsContainerType(vii.TypeId) = 0
	       UNION
	       SELECT m.SerialNo
	       FROM   Medium m
	       JOIN   MediumSealedCase msc
	         ON   msc.MediumId = m.MediumId
	       JOIN   SealedCase sc
	         ON   sc.CaseId = msc.CaseId
	       JOIN   VaultInventoryItem vii
	         ON   vii.SerialNo = sc.SerialNo
	       WHERE  dbo.bit$IsContainerType(vii.TypeId) = 1) as atVault  -- Media at vault (all inventories)
	  ON   atVault.SerialNo = m.SerialNo
	JOIN   VaultInventory vi
	  ON   vi.AccountId = m.AccountId
	WHERE  atVault.SerialNo IS NULL AND m.Location = 0 AND m.Missing = 0
END
ELSE IF @exclude = 1 BEGIN
	INSERT @tblMedium (MediumId, SerialNo)
	SELECT m.MediumId, m.SerialNo               -- Vault claims residence
	FROM   Medium m
	JOIN  (SELECT vii.SerialNo
	       FROM   VaultInventoryItem vii
	       WHERE  vii.InventoryId = @inventoryId AND
	              dbo.bit$IsContainerType(vii.TypeId) = 0
	       UNION
	       SELECT m.SerialNo
	       FROM   Medium m
	       JOIN   MediumSealedCase msc
	         ON   msc.MediumId = m.MediumId
	       JOIN   SealedCase sc
	         ON   sc.CaseId = msc.CaseId
	       JOIN   VaultInventoryItem vii
	         ON   vii.SerialNo = sc.SerialNo
	       WHERE  vii.InventoryId = @inventoryId AND
	              dbo.bit$IsContainerType(vii.TypeId) = 1) as atVault  -- Media at vault (specified inventory)
	  ON   atVault.SerialNo = m.SerialNo
	WHERE  m.Location = 1 AND 
          NOT EXISTS (SELECT 1 FROM SendListItem sli WHERE sli.MediumId = m.MediumId AND sli.Status NOT IN (1, 512))
	UNION
	SELECT m.MediumId, m.SerialNo               -- Vault refutes residence
	FROM   Medium m
	LEFT   JOIN
	      (SELECT vii.SerialNo
	       FROM   VaultInventoryItem vii
	       WHERE  dbo.bit$IsContainerType(vii.TypeId) = 0
	       UNION
	       SELECT m.SerialNo
	       FROM   Medium m
	       JOIN   MediumSealedCase msc
	         ON   msc.MediumId = m.MediumId
	       JOIN   SealedCase sc
	         ON   sc.CaseId = msc.CaseId
	       JOIN   VaultInventoryItem vii
	         ON   vii.SerialNo = sc.SerialNo
	       WHERE  dbo.bit$IsContainerType(vii.TypeId) = 1) as atVault  -- Media at vault (all inventories)
	  ON   atVault.SerialNo = m.SerialNo
	JOIN   VaultInventory vi
	  ON   vi.AccountId = m.AccountId
	WHERE  atVault.SerialNo IS NULL AND m.Location = 0 AND m.Missing = 0 AND 
          NOT EXISTS (SELECT 1 FROM ReceiveListItem rli WHERE rli.MediumId = m.MediumId AND rli.Status NOT IN (1, 512))
END
ELSE IF @exclude = 2 BEGIN
	INSERT @tblMedium (MediumId, SerialNo)
	SELECT m.MediumId, m.SerialNo               -- Vault claims residence
	FROM   Medium m
	JOIN  (SELECT vii.SerialNo
	       FROM   VaultInventoryItem vii
	       WHERE  vii.InventoryId = @inventoryId AND
	              dbo.bit$IsContainerType(vii.TypeId) = 0
	       UNION
	       SELECT m.SerialNo
	       FROM   Medium m
	       JOIN   MediumSealedCase msc
	         ON   msc.MediumId = m.MediumId
	       JOIN   SealedCase sc
	         ON   sc.CaseId = msc.CaseId
	       JOIN   VaultInventoryItem vii
	         ON   vii.SerialNo = sc.SerialNo
	       WHERE  vii.InventoryId = @inventoryId AND
	              dbo.bit$IsContainerType(vii.TypeId) = 1) as atVault  -- Media at vault (specified inventory)
	  ON   atVault.SerialNo = m.SerialNo
	WHERE  m.Location = 1 AND 
          not exists (select 1 from SendListItem sli join sendlist sl on sl.listid = sli.listid where sli.MediumId = m.MediumId and sli.Status != 1 and convert(nchar(10),sl.CreateDate,120) != convert(nchar(10),getutcdate(),120))
	UNION
	SELECT m.MediumId, m.SerialNo               -- Vault refutes residence
	FROM   Medium m
	LEFT   JOIN
	      (SELECT vii.SerialNo
	       FROM   VaultInventoryItem vii
	       WHERE  dbo.bit$IsContainerType(vii.TypeId) = 0
	       UNION
	       SELECT m.SerialNo
	       FROM   Medium m
	       JOIN   MediumSealedCase msc
	         ON   msc.MediumId = m.MediumId
	       JOIN   SealedCase sc
	         ON   sc.CaseId = msc.CaseId
	       JOIN   VaultInventoryItem vii
	         ON   vii.SerialNo = sc.SerialNo
	       WHERE  dbo.bit$IsContainerType(vii.TypeId) = 1) as atVault  -- Media at vault (all inventories)
	  ON   atVault.SerialNo = m.SerialNo
	JOIN   VaultInventory vi
	  ON   vi.AccountId = m.AccountId
	WHERE  atVault.SerialNo IS NULL AND m.Location = 0 AND m.Missing = 0 AND 
          not exists (select 1 from ReceiveListItem rli join receivelist rl on rl.listid = rli.listid where rli.MediumId = m.MediumId and rli.Status != 1 and convert(nchar(10),rl.CreateDate,120) != convert(nchar(10),getutcdate(),120))
END
ELSE IF @exclude = 3 BEGIN
	INSERT @tblMedium (MediumId, SerialNo)
	SELECT m.MediumId, m.SerialNo               -- Vault claims residence
	FROM   Medium m
	JOIN  (SELECT vii.SerialNo
	       FROM   VaultInventoryItem vii
	       WHERE  vii.InventoryId = @inventoryId AND
	              dbo.bit$IsContainerType(vii.TypeId) = 0
	       UNION
	       SELECT m.SerialNo
	       FROM   Medium m
	       JOIN   MediumSealedCase msc
	         ON   msc.MediumId = m.MediumId
	       JOIN   SealedCase sc
	         ON   sc.CaseId = msc.CaseId
	       JOIN   VaultInventoryItem vii
	         ON   vii.SerialNo = sc.SerialNo
	       WHERE  vii.InventoryId = @inventoryId AND
	              dbo.bit$IsContainerType(vii.TypeId) = 1) as atVault  -- Media at vault (specified inventory)
	  ON   atVault.SerialNo = m.SerialNo
	WHERE  m.Location = 1 and
          not exists (select 1 FROM SendListItem sli join SendList sl on sl.listid = sli.listid where sli.MediumId = m.MediumId and sli.Status != 1 and (sli.Status != 512 or convert(nchar(10),sl.CreateDate,120) != convert(nchar(10),getutcdate(),120)))
	UNION
	SELECT m.MediumId, m.SerialNo               -- Vault refutes residence
	FROM   Medium m
	LEFT   JOIN
	      (SELECT vii.SerialNo
	       FROM   VaultInventoryItem vii
	       WHERE  dbo.bit$IsContainerType(vii.TypeId) = 0
	       UNION
	       SELECT m.SerialNo
	       FROM   Medium m
	       JOIN   MediumSealedCase msc
	         ON   msc.MediumId = m.MediumId
	       JOIN   SealedCase sc
	         ON   sc.CaseId = msc.CaseId
	       JOIN   VaultInventoryItem vii
	         ON   vii.SerialNo = sc.SerialNo
	       WHERE  dbo.bit$IsContainerType(vii.TypeId) = 1) as atVault  -- Media at vault (all inventories)
	  ON   atVault.SerialNo = m.SerialNo
	JOIN   VaultInventory vi
	  ON   vi.AccountId = m.AccountId
	WHERE  atVault.SerialNo IS NULL AND m.Location = 0 AND m.Missing = 0 AND 
          not exists (select 1 FROM ReceiveListItem rli join ReceiveList rl on rl.listid = rli.listid where rli.MediumId = m.MediumId and rli.Status != 1 and (rli.Status != 512 or convert(nchar(10),rl.CreateDate,120) != convert(nchar(10),getutcdate(),120)))
END

-- Begin the transaction
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

SELECT @i = 1, @rowCount = count(*)
FROM   @tblMedium

WHILE @i <= @rowCount BEGIN
   -- Get the next medium
   SELECT @mediumId = MediumId,
          @serialNo = SerialNo
   FROM   @tblMedium
   WHERE  RowNo = @i
   -- If it exists in the table, update the recorded date
   SELECT @itemId = ItemId 
   FROM   VaultDiscrepancyResidency 
   WHERE  MediumId = @mediumId
   IF @@rowCount > 0 BEGIN
      EXECUTE @returnValue = vaultDiscrepancy$upd @itemId, @timeNow
      IF @returnValue != 0 BEGIN
         ROLLBACK TRANSACTION @tranName
         COMMIT TRANSACTION
         RETURN -100
      END
   END
   ELSE BEGIN
      INSERT VaultDiscrepancy (RecordedDate) 
      VALUES (getutcdate())
      SET @error = @@error
      IF @error != 0 BEGIN
         ROLLBACK TRANSACTION @tranName
         COMMIT TRANSACTION
         SET @msg = ''Error encountered while inserting vault discrepancy.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
         EXECUTE error$raise @msg, @error
         RETURN -100
      END
      INSERT VaultDiscrepancyResidency (ItemId,MediumId,SerialNo) 
      VALUES (scope_identity(),@mediumId,@serialNo)
      SET @error = @@error
      IF @error != 0 BEGIN
         ROLLBACK TRANSACTION @tranName
         COMMIT TRANSACTION
         SET @msg = ''Error encountered while inserting vault residency discrepancy.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
         EXECUTE error$raise @msg, @error
         RETURN -100
      END
   END
   -- Increment counter
   SET @i = @i + 1
END

COMMIT TRANSACTION
RETURN 0
END
'
)

IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'vaultInventory$compareResidency')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.vaultInventory$resolveMissing
(
   @inventoryId int
)
WITH ENCRYPTION
AS
BEGIN
DECLARE @lastSerial nvarchar(64)
DECLARE @msg nvarchar(255)        -- used to preformat error message
DECLARE @msgTag nvarchar(255)     -- used to hold first part of error message header
DECLARE @tranName nvarchar(255)   -- used to hold name of savepoint
DECLARE @location bit
DECLARE @error int

SET NOCOUNT ON

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=P''
SET @tranName = object_name(@@procid) + CAST(@@nestlevel as nvarchar(2))

-- Begin the transaction
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

SET @lastSerial = ''''
WHILE 1 = 1 BEGIN
   SELECT TOP 1 @lastSerial = vii.SerialNo, 
          @location = m.Location
   FROM   VaultInventoryItem vii
   JOIN   Medium m
     ON   m.SerialNo = vii.SerialNo
   WHERE  m.Missing = 1 AND 
          m.SerialNo > @lastSerial AND
          vii.InventoryId = @inventoryId AND
          dbo.bit$IsContainerType(vii.TypeId) = 0
   ORDER BY vii.SerialNo ASC
   IF @@rowCount = 0 BEGIN
      BREAK
   END
   ELSE BEGIN
      IF @location = 0 BEGIN
         UPDATE Medium
         SET    Missing = 0
         WHERE  SerialNo = @lastSerial
      END
      ELSE BEGIN
         UPDATE Medium
         SET    Missing = 0,
                Location = 0,
                LastMoveDate = cast(convert(nchar(19), getutcdate(), 120) as datetime)
         WHERE  SerialNo = @lastSerial
      END
      SET @error = @@error
      IF @error != 0 BEGIN
         ROLLBACK TRANSACTION @tranName
         COMMIT TRANSACTION
         SET @msg = ''Error encountered while revoking missing status during inventory comparison.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
         EXECUTE error$raise @msg, @error
         RETURN -100
      END
   END
END

COMMIT TRANSACTION
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
   MediumId
)
VALUES
(
   @initialStatus, 
   @listId,
   @returnDate,
   @mediumId
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
      MediumId
   )
   VALUES
   (
      @initialStatus,
      @listId, 
      @returnDate,
      @mediumId
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

IF EXISTS(SELECT * FROM sysobjects WHERE name = 'sendListItem$afterUpdate' AND objectproperty(id, 'ExecIsUpdateTrigger' ) = 1) 
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
DECLARE @lastList int
DECLARE @serialNo nvarchar(32)
DECLARE @auditAction int
DECLARE @rowVersion rowversion
DECLARE @returnDate datetime
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

-- Make sure that no medium appears active more than once
IF EXISTS
   (
   SELECT 1 
   FROM   SendListItem sli
   JOIN   Inserted i
     ON   i.MediumId = sli.MediumId
   WHERE  sli.Status > 1 AND sli.Status != 512
   GROUP  BY i.MediumId
   HAVING count(*) > 1
   )
BEGIN
   SET @msg = ''Medium may not actively appear on more than one shipping list.'' + @msgTag + ''>''
   EXECUTE error$raise @msg, 0, @tranName
   RETURN
END

-- For each list in the update where an item was updated to a status other 
-- than removed, make sure that the discrete list status is equal to 
-- the (translated) lowest status among its non-removed items.
SET @lastList = 0
WHILE 1 = 1 BEGIN
   SELECT DISTINCT TOP 1 @lastList = i.ListId,
          @rowVersion = sl.RowVersion
   FROM   Inserted i
   JOIN   Deleted d
     ON   d.ItemId = i.ItemId
   JOIN   SendList sl
     ON   sl.ListId = i.ListId
   WHERE  i.Status != 1 AND  -- power(2,0)
          d.Status != i.Status AND
          i.ListId > @lastList
   ORDER BY i.ListId ASC
   IF @@rowCount = 0
      BREAK
   ELSE BEGIN
      EXECUTE @returnValue = sendList$setStatus @lastList, @rowVersion
      IF @returnValue != 0 BEGIN
         ROLLBACK TRANSACTION @tranName
         COMMIT TRANSACTION
         RETURN
      END
   END
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
            SET @msgUpdate = ''Medium '' + @serialNo + '' removed from list.''
         END
         ELSE IF @status = 8 BEGIN -- power(2,3)
            SET @msgUpdate = ''Medium '' + @serialNo + '' verified (I).''
            SET @auditAction = 10
         END
         ELSE IF @status = 256 BEGIN -- power(2,7)
            SET @msgUpdate = ''Medium '' + @serialNo + '' verified (II).''
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

-- For each list in the update where an item was updated to removed status, 
-- delete the list if there are no more items on the list.  Otherwise, update
-- the status of the list.
SET @lastList = 0
WHILE 1 = 1 BEGIN
   SELECT TOP 1 @lastList = i.ListId,
          @rowVersion = sl.RowVersion
   FROM   Inserted i
   JOIN   Deleted d
     ON   d.ItemId = i.ItemId
   JOIN   SendList sl
     ON   sl.ListId = i.ListId
   WHERE  i.Status = 1 AND  -- power(2,0)
          d.Status != 1 AND -- power(2,0)
          i.ListId > @lastList
   ORDER BY i.ListId ASC
   IF @@rowCount = 0
      BREAK
   ELSE BEGIN
      IF EXISTS(SELECT 1 FROM SendListItem WHERE ListId = @lastList AND Status != 1) BEGIN -- power(2,0)
         EXECUTE @returnValue = sendList$setStatus @lastList, @rowVersion
      END
      ELSE BEGIN
         EXECUTE @returnValue = sendList$del @lastList, @rowVersion
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

IF @listStatus >= 4 AND EXISTS (SELECT 1 FROM ListStatusProfile WHERE ProfileId = 2 AND Statuses & 4 != 0) BEGIN
   SET @msg = ''A list may not be altered after it has been transmitted.'' + @msgTag + ''>''
   RAISERROR(@msg,16,1)
   RETURN -100
END
ELSE IF @listStatus >= 16 BEGIN
   SET @msg = ''A list may not be altered once it has attained '' + dbo.string$statusName(2,16) + '' status.'' + @msgTag + ''>''
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

IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'disasterCodeListItem$add')
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

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
--
-- Stored Procedures related to speeding up list creation
--
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
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
IF EXISTS (SELECT 1 FROM BarCodePattern WHERE Position = (SELECT min(Position) FROM BarCodePattern) AND Position < 0) BEGIN
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
   WHERE  Pattern = @serialNo
END
ELSE BEGIN
   -- Initialize @p
   SET @p = 0
   -- If we have literals, get the position of the last one
   IF EXISTS (SELECT 1 FROM BarCodePattern WHERE Position = 1 AND patindex(''%[^A-Z0-9a-z]%'', Pattern) = 0) BEGIN
      -- Get the last literal position
      SELECT TOP 1 @p = Position
      FROM   BarCodePattern
      WHERE  patindex(''%[^A-Z0-9a-z]%'', Pattern) = 0
      ORDER  BY Position DESC
   END
   -- Select the format
   SELECT TOP 1 @typeName = m.TypeName,
          @accountName = a.AccountName
   FROM   BarCodePattern b
   JOIN   MediumType m
     ON   m.TypeId = b.TypeId
   JOIN   Account a
     ON   a.AccountId = b.AccountId
   WHERE  Position > @p AND dbo.bit$RegexMatch(@serialNo,Pattern) = 1
   ORDER  BY Position ASC
   -- If no format, raise error
   IF @@rowCount = 0 BEGIN
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

IF EXISTS(SELECT * FROM sysobjects WHERE name = 'medium$afterInsert' AND objectproperty(id, 'ExecIsInsertTrigger' ) = 1) 
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
DECLARE @msgInsert nvarchar(512)  -- used to hold the insert message
DECLARE @tranName nvarchar(255)   -- used to hold name of savepoint
DECLARE @serialNo nvarchar(32)    -- serial number of inserted medium
DECLARE @bSide nvarchar(32)       -- b-side serial number of inserted medium
DECLARE @typeName nvarchar(128)
DECLARE @accountName nvarchar(128)
DECLARE @x nvarchar(128)
DECLARE @y nvarchar(128)
DECLARE @accountId int
DECLARE @location int
DECLARE @rowCount int            -- holds the number of rows in the Inserted table
DECLARE @typeId int
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
       @bSide = i.BSide 
FROM   Inserted i
JOIN   MediumType m
  ON   m.TypeId = i.TypeId
JOIN   Account a
  ON   a.AccountId = i.AccountId

-- Verify that there is no sealed case WITH that serial number
IF EXISTS(SELECT 1 FROM SealedCase WHERE SerialNo = @serialNo) BEGIN
   SET @msg = ''A sealed case WITH serial number '''''' + @serialNo + '''''' already exists.'' + @msgTag + ''>''
   EXECUTE error$raise @msg, 0, @tranName
   RETURN
END
ELSE IF EXISTS(SELECT 1 FROM SendListCase WHERE SerialNo = @serialNo AND Cleared = 0) BEGIN
   SET @msg = ''A case WITH serial number '''''' + @serialNo + '''''' exists on an active shipping list.'' + @msgTag + ''>''
   EXECUTE error$raise @msg, 0, @tranName
   RETURN
END

-- Verify that there is no medium WITH that serial number as a bside
IF EXISTS(SELECT 1 FROM Medium WHERE BSide = @serialNo) BEGIN
   SET @msg = ''A medium currently exists WITH serial number '''''' + @serialNo + '''''' as its b-side.'' + @msgTag + ''>''
   EXECUTE error$raise @msg, 0, @tranName
   RETURN
END

-- If there is a bside, make sure that it is unique and that the medium is not one-sided
-- or a container.
 IF len(@bSide) > 0 BEGIN
    IF EXISTS(SELECT 1 FROM Medium WHERE SerialNo = @bSide) BEGIN
       SET @msg = ''A medium currently exists WITH serial number '''''' + @serialNo + '''''' as its b-side.'' + @msgTag + ''>''
       EXECUTE error$raise @msg, 0, @tranName
       RETURN
    END
   IF EXISTS(SELECT 1 FROM Medium WHERE BSide = @bSide) BEGIN
      SET @msg = ''A medium currently exists WITH serial number '''''' + @bSide + '''''' as its b-side.'' + @msgTag + ''>''
      EXECUTE error$raise @msg, 0, @tranName
      RETURN
   END
   ELSE IF EXISTS(SELECT 1 FROM SealedCase WHERE SerialNo = @bSide) BEGIN
      SET @msg = ''A sealed case WITH serial number '''''' + @bSide + '''''' already exists.'' + @msgTag + ''>''
      EXECUTE error$raise @msg, 0, @tranName
      RETURN
   END
   ELSE IF EXISTS(SELECT 1 FROM SendListCase WHERE SerialNo = @bSide AND Cleared = 0) BEGIN
      SET @msg = ''A case WITH serial number '''''' + @bSide + '''''' exists on an active shipping list.'' + @msgTag + ''>''
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
EXEC barcodepattern$getdefaults @serialNo, @x out, @y out
IF @x != @typeName or @y != @accountName BEGIN
   SET @msg = ''Account and/or medium type do not accord WITH bar code formats.'' + @msgTag + ''>''
   EXECUTE error$raise @msg, 0, @tranName
   RETURN
END

-- Create the insert message
IF @location = 0 
   SET @msgInsert = ''Medium '' + @serialNo + '' created at the vault under account '' + @accountName + '' and of type '' + @typeName
ELSE
   SET @msgInsert = ''Medium '' + @serialNo + '' created at the enterprise under account '' + @accountName + '' and of type '' + @typeName

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
   @msgInsert, 
   dbo.string$GetSpidLogin()
)

SET @error = @@error
IF @error != 0 BEGIN
   SET @msg = ''Error encounterd while inserting a medium audit record.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
   EXECUTE error$raise @msg, @error, @tranName
   RETURN
END

COMMIT TRANSACTION 
END
'
)

IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'receiveList$setStatus')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.receiveList$setStatus
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
DECLARE @status as int
DECLARE @error as int
DECLARE @tbl1 table (ListId int)

SET NOCOUNT ON

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=P''
SET @tranName = object_name(@@procid) + CAST(@@nestlevel as nvarchar(2))

-- Get all the other parts of composite if list is composite
INSERT @tbl1 (ListId) VALUES (@listId)
INSERT @tbl1 (ListId) SELECT ListId FROM ReceiveList WHERE CompositeId = @listId

-- Get the minimum status for the list.
SELECT @status = min(rli.Status)
FROM   ReceiveListItem rli
JOIN   @tbl1 t
  ON   t.ListId = rli.ListId
WHERE  rli.Status != 1

-- If no active items, return zero
IF @status IS NULL RETURN 0

-- If some items have been  verified and others haven''t, set the status to partial verification.
IF @status != 16  BEGIN
   IF EXISTS 
      (
      SELECT 1 
      FROM   ReceiveListItem rli
      JOIN   @tbl1 t
        ON   t.ListId = rli.ListId
      WHERE  rli.Status = 16
      )
   BEGIN
      SET @status = 8
   END
END
IF @status NOT IN (8, 256) BEGIN 
   IF EXISTS 
      (
      SELECT 1 
      FROM   ReceiveListItem rli
      JOIN   @tbl1 t
        ON   t.ListId = rli.ListId
      WHERE  rli.Status = 256
      )
   BEGIN
      SET @status = 128
   END
END

-- Begin the transaction
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

-- Update the receive list
IF EXISTS (SELECT 1 FROM ReceiveList WHERE ListId = @listId AND Status != @status) BEGIN
   UPDATE ReceiveList
   SET    Status = @status
   WHERE  ListId = @listId AND RowVersion = @rowVersion
   SELECT @error = @@error, @rowCount = @@rowCount
   IF @rowCount = 0 BEGIN
      IF EXISTS (SELECT 1 FROM ReceiveList WHERE ListId = @listId) BEGIN
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
   ELSE IF @error != 0 BEGIN
      ROLLBACK TRANSACTION @tranName
      COMMIT TRANSACTION
      SET @msg = ''Error encountered while updating receive list status.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
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

IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'sendList$setStatus')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.sendList$setStatus
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
DECLARE @status as int
DECLARE @error as int
DECLARE @tbl1 table (ListId int)

SET NOCOUNT ON

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=P''
SET @tranName = object_name(@@procid) + CAST(@@nestlevel as nvarchar(2))

-- Get all the other parts of composite if list is composite
INSERT @tbl1 (ListId) VALUES (@listId)
INSERT @tbl1 (ListId) SELECT ListId FROM SendList WHERE CompositeId = @listId

-- Get the minimum status for the list.
SELECT @status = min(sli.Status)
FROM   SendListItem sli
JOIN   @tbl1 t
  ON   t.ListId = sli.ListId
WHERE  sli.Status != 1

-- If no active items, return zero
IF @status IS NULL RETURN 0

-- If some items have been  verified and others haven''t, set the status to partial verification.
IF @status != 8  BEGIN
   IF EXISTS 
      (
      SELECT 1 
      FROM   SendListItem sli
      JOIN   @tbl1 t
        ON   t.ListId = sli.ListId
      WHERE  sli.Status = 8
      )
   BEGIN
      SET @status = 4
   END
END
IF @status NOT IN (4, 256) BEGIN 
   IF EXISTS 
      (
      SELECT 1 
      FROM   SendListItem sli
      JOIN   @tbl1 t
        ON   t.ListId = sli.ListId
      WHERE  sli.Status = 256
      )
   BEGIN
      SET @status = 128
   END
END

-- Begin the transaction
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

-- Update the send list
IF EXISTS (SELECT 1 FROM SendList WHERE ListId = @listId AND Status != @status) BEGIN
   UPDATE SendList
   SET    Status = @status
   WHERE  ListId = @listId AND RowVersion = @rowVersion
   SELECT @error = @@error, @rowCount = @@rowCount
   IF @error != 0 BEGIN
      ROLLBACK TRANSACTION @tranName
      COMMIT TRANSACTION
      SET @msg = ''Error encountered while updating send list status'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
      EXECUTE error$raise @msg, @error
      RETURN -100
   END
   ELSE IF @rowCount = 0 BEGIN
      ROLLBACK TRANSACTION @tranName
      COMMIT TRANSACTION
      SET @msg = ''Send list has been modified since retrieval.'' + @msgTag + ''>''
      RAISERROR(@msg,16,1)
      RETURN -100
   END
END

COMMIT TRANSACTION
RETURN 0
END
'
)

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

-- Make sure that no medium appears active more than once
IF EXISTS
   (
   SELECT 1 
   FROM   ReceiveListItem
   WHERE  MediumId = (SELECT MediumId FROM Inserted) AND Status != 1 AND Status != 512
   GROUP  BY MediumId
   HAVING count(*) > 1
   )
BEGIN
   SET @msg = ''Medium may not actively appear on more than one receive list'' + @msgTag + ''>''
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

IF EXISTS(SELECT * FROM sysobjects WHERE name = 'receiveListItem$afterUpdate' AND objectproperty(id, 'ExecIsUpdateTrigger' ) = 1) 
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
            SET @msgUpdate = ''Medium '' + @serialNo + '' removed from list.''
            SET @auditAction = 5
         END
         ELSE IF @status = 16 BEGIN
            SET @msgUpdate = ''Medium '' + @serialNo + '' verified (I).''
            SET @auditAction = 10
         END
         ELSE IF @status = 256 BEGIN
            SET @msgUpdate = ''Medium '' + @serialNo + '' verified (II).''
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

IF EXISTS(SELECT * FROM sysobjects WHERE name = 'receiveList$afterUpdate' AND objectproperty(id, 'ExecIsUpdateTrigger' ) = 1) 
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'TRIGGER receiveList$afterUpdate
ON     ReceiveList
WITH ENCRYPTION
AFTER  UPDATE
AS
BEGIN
DECLARE @msg nvarchar(255)        -- used to preformat error message
DECLARE @msgTag nvarchar(255)     -- used to hold first part of error message header
DECLARE @msgUpdate nvarchar(4000) -- used to hold the updated fields
DECLARE @tranName nvarchar(255)   -- used to hold name of savepoint
DECLARE @listName nchar(10)       -- holds the name of the updated list
DECLARE @compositeName nchar(10)  -- holds the name of the composite list
DECLARE @rowCount int             -- holds the number of rows in the Deleted table
DECLARE @returnValue int
DECLARE @cid int
DECLARE @cv rowversion
DECLARE @rv rowversion
DECLARE @status int
DECLARE @lastList int
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
   SET @msg = ''Caller login not found in spid login table.'' + @msgTag + ''>''
   EXECUTE error$raise @msg, 0, @tranName
   RETURN
END

-- Audit merges
SET @lastList = 0
WHILE 1 = 1 BEGIN
   SELECT TOP 1 @listName = i.ListName,
          @lastList = i.ListId,
          @cid = i.CompositeId
   FROM   Inserted i
   JOIN   Deleted d

     ON   d.ListId = i.ListId
   WHERE  i.ListId > @lastList AND
          d.CompositeId IS NULL AND
          i.CompositeId IS NOT NULL
   ORDER BY i.ListId ASC
   IF @@rowCount = 0
      BREAK
   ELSE BEGIN
      -- Get the composite list
      SELECT @compositeName = ListName
      FROM   ReceiveList
      WHERE  ListId = @cid
      -- Make sure that the composite is not discrete
      IF EXISTS(SELECT 1 FROM ReceiveList WHERE AccountId IS NOT NULL AND ListId = @cid) BEGIN
         SET @msg = ''Lists may not be merged into other discrete lists.'' + @msgTag + ''>''
         EXECUTE error$raise @msg, 0, @tranName
         RETURN
      END
      -- Insert audit record
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
         9,
         ''List '' + @listName + '' merged into composite '' + @compositeName,
         dbo.string$GetSpidLogin()
      )
      SET @error = @@error
      IF @error != 0 BEGIN
         SET @msg = ''Error encountered while inserting receiving list audit record.'' + @msgTag + '';Error='' + cast(@error as nvarchar(9)) + ''>''
         EXECUTE error$raise @msg, @error, @tranName
         RETURN
      END
   END
END

-- Audit extractions
SET @lastList = 0
WHILE 1 = 1 BEGIN
   SELECT TOP 1 @listName = i.ListName,
          @lastList = i.ListId,
          @cid = d.CompositeId
   FROM   Inserted i
   JOIN   Deleted d
     ON   d.ListId = i.ListId
   WHERE  i.ListId > @lastList AND
          i.CompositeId IS NULL AND
          d.CompositeId IS NOT NULL
   ORDER BY i.ListId ASC
   IF @@rowCount = 0
      BREAK
   ELSE BEGIN
      -- Get the composite list
      SELECT @compositeName = ListName
      FROM   ReceiveList
      WHERE  ListId = @cid
      -- Insert audit record
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
         8,
         ''List '' + @listName + '' extracted from composite '' + @compositeName,
         dbo.string$GetSpidLogin()
      )
      SET @error = @@error
      IF @error != 0 BEGIN
         SET @msg = ''Error encountered while inserting receiving list audit record.'' + @msgTag + '';Error='' + cast(@error as nvarchar(9)) + ''>''
         EXECUTE error$raise @msg, @error, @tranName
         RETURN
      END
      -- If the composite list has no more discretes, delete it
      IF NOT EXISTS(SELECT 1 FROM ReceiveList WHERE CompositeId = @cid) BEGIN
         DELETE ReceiveList
         WHERE  ListId = @cid
         SET @error = @@error
         IF @error != 0 BEGIN
            SET @msg = ''Error encountered while deleting dissolved composite list.'' + @msgTag + '';Error='' + cast(@error as nvarchar(9)) + ''>''
            EXECUTE error$raise @msg, @error, @tranName
            RETURN
         END
      END
   END
END

-- Audit status changes
SET @lastList = 0
WHILE 1 = 1 BEGIN
   SELECT TOP 1 @listName = i.ListName,
          @lastList = i.ListId,
          @status = i.Status,
          @cid = i.CompositeId,
          @rv = i.RowVersion
   FROM   Inserted i
   JOIN   Deleted d
     ON   d.ListId = i.ListId
   WHERE  i.ListId > @lastList AND
          d.Status != i.Status
   ORDER BY i.ListId ASC
   IF @@rowCount = 0
      BREAK
   ELSE BEGIN
      -- Get the update string
      IF @status = 2
         SET @msgUpdate = ''''
      ELSE IF @status = 4
         SET @msgUpdate = ''List '' + @listName + '' transmitted''
      ELSE IF @status = 8
         SET @msgUpdate = ''List '' + @listName + '' partially verified (I)''
      ELSE IF @status = 16
         SET @msgUpdate = ''List '' + @listName + '' fully verified (I)''
      ELSE IF @status = 32
         SET @msgUpdate = ''List '' + @listName + '' marked as in transit''
      ELSE IF @status = 64
         SET @msgUpdate = ''List '' + @listName + '' marked as arrived at the enterprise''
      ELSE IF @status = 128
         SET @msgUpdate = ''List '' + @listName + '' partially verified (II)''
      ELSE IF @status = 256
         SET @msgUpdate = ''List '' + @listName + '' fully verified (II)''
      ELSE IF @status = 512
         SET @msgUpdate = ''List '' + @listName + '' processed''
      -- Insert audit record
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
         2,
         @msgUpdate,
         dbo.string$GetSpidLogin()
      )
      SET @error = @@error
      IF @error != 0 BEGIN
         SET @msg = ''Error encountered while inserting receiving list audit record.'' + @msgTag + '';Error='' + cast(@error as nvarchar(9)) + ''>''
         EXECUTE error$raise @msg, @error, @tranName
         RETURN
      END
      -- If belongs to a composite, set status of composite
      IF @cid IS NOT NULL BEGIN
         SELECT @cv = RowVersion
         FROM   ReceiveList
         WHERE  ListId = @cid         
         EXECUTE @returnValue = receiveList$setStatus @cid, @cv
         IF @returnValue != 0 BEGIN
            ROLLBACK TRANSACTION @tranName
            COMMIT TRANSACTION
            RETURN
         END
      END
      ELSE IF dbo.bit$statusEligible(2,@status,512) = 1 BEGIN
         EXECUTE @returnValue = receiveList$clear @lastList, @rv
         IF @returnValue != 0 BEGIN
            ROLLBACK TRANSACTION @tranName
            COMMIT TRANSACTION
            RETURN
         END
      END
   END
END          

-- Commit transaction
COMMIT TRANSACTION
END
'
)

IF EXISTS(SELECT * FROM sysobjects WHERE name = 'sendListItem$afterInsert' AND objectproperty(id, 'ExecIsInsertTrigger' ) = 1) 
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

-- If the medium was missing, mark it as found
IF EXISTS (SELECT 1 FROM Medium WHERE MediumId = @mediumId AND Missing = 1) BEGIN
   UPDATE Medium
   SET    Missing = 0
   WHERE  MediumId = @mediumId
   SET @error = @@error
   IF @error != 0 BEGIN
      SET @msg = ''Error encountered while inserting a new shipping list item audit record; could not reset medium missing status.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
      EXECUTE error$raise @msg, @error, @tranName
      RETURN
   END
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

IF EXISTS(SELECT * FROM sysobjects WHERE name = 'sendListItem$afterUpdate' AND objectproperty(id, 'ExecIsUpdateTrigger' ) = 1) 
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
            SET @msgUpdate = ''Medium '' + @serialNo + '' removed from list.''
         END
         ELSE IF @status = 8 BEGIN -- power(2,3)
            SET @msgUpdate = ''Medium '' + @serialNo + '' verified (I).''
            SET @auditAction = 10
         END
         ELSE IF @status = 256 BEGIN -- power(2,7)
            SET @msgUpdate = ''Medium '' + @serialNo + '' verified (II).''
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

IF EXISTS(SELECT * FROM sysobjects WHERE name = 'sendList$afterUpdate' AND objectproperty(id, 'ExecIsUpdateTrigger' ) = 1) 
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'TRIGGER sendList$afterUpdate
ON     SendList
WITH ENCRYPTION
AFTER  UPDATE
AS
BEGIN
DECLARE @msg nvarchar(255)        -- used to preformat error message
DECLARE @msgTag nvarchar(255)     -- used to hold first part of error message header
DECLARE @msgUpdate nvarchar(4000) -- used to hold the updated fields
DECLARE @tranName nvarchar(255)   -- used to hold name of savepoint
DECLARE @listName nchar(10)       -- holds the name of the updated list
DECLARE @compositeName nchar(10)  -- holds the name of the composite list
DECLARE @rowcount int             -- holds the number of rows in the Deleted table
DECLARE @returnValue int
DECLARE @status int
DECLARE @cid int
DECLARE @cv rowversion
DECLARE @rv rowversion
DECLARE @lastList int
DECLARE @error int

SET @rowcount = @@rowcount
IF @rowcount = 0 RETURN

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

-- Audit merges
SET @lastList = 0
WHILE 1 = 1 BEGIN
   SELECT TOP 1 @listName = i.ListName,
          @lastList = i.ListId,
          @cid = i.CompositeId
   FROM   Inserted i
   JOIN   Deleted d
     ON   d.ListId = i.ListId
   WHERE  i.ListId > @lastList AND
          d.CompositeId IS NULL AND
          i.CompositeId IS NOT NULL
   ORDER BY i.ListId ASC
   IF @@rowCount = 0
      BREAK
   ELSE BEGIN
      -- Get the composite list
      SELECT @compositeName = ListName
      FROM   SendList
      WHERE  ListId = @cid
      -- Make sure that the composite is not discrete
      IF EXISTS(SELECT 1 FROM SendList WHERE AccountId IS NOT NULL AND ListId = @cid) BEGIN
         SET @msg = ''Lists may not be merged into other discrete lists.'' + @msgTag + ''>''
         EXECUTE error$raise @msg, 0, @tranName
         RETURN
      END
      -- Insert audit record
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
         9,
         ''List '' + @listName + '' merged into composite '' + @compositeName,
         dbo.string$GetSpidLogin()
      )
      SET @error = @@error
      IF @error != 0 BEGIN
         SET @msg = ''Error encountered while inserting new shipping list audit record.'' + @msgTag + '';Error='' + cast(@error as nvarchar(9)) + ''>''
         EXECUTE error$raise @msg, @error, @tranName
         RETURN
      END
   END
END

-- Audit extractions
SET @lastList = 0
WHILE 1 = 1 BEGIN
   SELECT TOP 1 @listName = i.ListName,
          @lastList = i.ListId,
          @cid = d.CompositeId
   FROM   Inserted i
   JOIN   Deleted d
     ON   d.ListId = i.ListId
   WHERE  i.ListId > @lastList AND
          i.CompositeId IS NULL AND
          d.CompositeId IS NOT NULL
   ORDER BY i.ListId ASC
   IF @@rowCount = 0
      BREAK
   ELSE BEGIN
      -- Get the composite list
      SELECT @compositeName = ListName
      FROM   SendList
      WHERE  ListId = @cid
      -- Insert audit record
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
         8,
         ''List '' + @listName + '' extracted from composite '' + @compositeName,
         dbo.string$GetSpidLogin()
      )
      SET @error = @@error
      IF @error != 0 BEGIN
         SET @msg = ''Error encountered while inserting new shipping list audit record.'' + @msgTag + '';Error='' + cast(@error as nvarchar(9)) + ''>''
         EXECUTE error$raise @msg, @error, @tranName
         RETURN
      END
      -- If the composite list has no more discretes, delete it
      IF NOT EXISTS(SELECT 1 FROM SendList WHERE CompositeId = @cid) BEGIN
         DELETE SendList
         WHERE  ListId = @cid
         SET @error = @@error
         IF @error != 0 BEGIN
            SET @msg = ''Error encountered while deleting dissolved composite list.'' + @msgTag + '';Error='' + cast(@error as nvarchar(9)) + ''>''
            EXECUTE error$raise @msg, @error, @tranName
            RETURN
         END
      END
   END
END

-- Audit status changes
SET @lastList = 0
WHILE 1 = 1 BEGIN
   SELECT TOP 1 @listName = i.ListName,
          @lastList = i.ListId,
          @status = i.Status,
          @cid = i.CompositeId,
          @rv = i.RowVersion
   FROM   Inserted i
   JOIN   Deleted d
     ON   d.ListId = i.ListId
   WHERE  i.ListId > @lastList AND
          d.Status != i.Status
   ORDER BY i.ListId ASC
   IF @@rowCount = 0
      BREAK
   ELSE BEGIN
      -- Get the update string
      IF @status = 2
         SET @msgUpdate = ''''
      ELSE IF @status = 4
         SET @msgUpdate = ''List '' + @listName + '' partially verified (I)''
      ELSE IF @status = 8
         SET @msgUpdate = ''List '' + @listName + '' fully verified (I)''
      ELSE IF @status = 16
         SET @msgUpdate = ''List '' + @listName + '' transmitted''
      ELSE IF @status = 32
         SET @msgUpdate = ''List '' + @listName + '' marked as in transit''
      ELSE IF @status = 64
         SET @msgUpdate = ''List '' + @listName + '' marked as arrived at the vault''
      ELSE IF @status = 128
         SET @msgUpdate = ''List '' + @listName + '' partially verified (II)''
      ELSE IF @status = 256
         SET @msgUpdate = ''List '' + @listName + '' fully verified (II)''
      ELSE IF @status = 512
         SET @msgUpdate = ''List '' + @listName + '' processed''
      -- Insert audit record
      INSERT XSendList (Object, Action, Detail, Login)
      VALUES(@listName, 2, @msgUpdate, dbo.string$GetSpidLogin())
      SET @error = @@error
      IF @error != 0 BEGIN
         SET @msg = ''Error encountered while inserting new shipping list audit record.'' + @msgTag + '';Error='' + cast(@error as nvarchar(9)) + ''>''
         EXECUTE error$raise @msg, @error, @tranName
         RETURN
      END
      -- If belongs to a composite, set status of composite.  Otherwise, check
      -- the clear-eligibility of the list; if it is, clear it.
      IF @cid IS NOT NULL BEGIN
         SELECT @cv = RowVersion
         FROM   SendList
         WHERE  ListId = @cid         
         EXECUTE @returnValue = sendList$setStatus @cid, @cv
         IF @returnValue != 0 BEGIN
            ROLLBACK TRANSACTION @tranName
            COMMIT TRANSACTION
            RETURN
         END
      END
      ELSE IF dbo.bit$statusEligible(1,@status,512) = 1 BEGIN
         EXECUTE @returnValue = sendList$clear @lastList, @rv
         IF @returnValue != 0 BEGIN
            ROLLBACK TRANSACTION @tranName
            COMMIT TRANSACTION
            RETURN
         END
      END
   END
END          

-- Commit transaction
COMMIT TRANSACTION
END
'
)

IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'disasterCodeList$setStatus')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.disasterCodeList$setStatus
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
DECLARE @rowcount as int
DECLARE @status as int
DECLARE @error as int
DECLARE @tbl1 table (ListId int)

SET NOCOUNT ON

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=P''
SET @tranName = object_name(@@procid) + CAST(@@nestlevel as nvarchar(2))

-- Get all the other parts of composite if list is composite
INSERT @tbl1 (ListId) VALUES (@listId)
INSERT @tbl1 (ListId) SELECT ListId FROM DisasterCodeList WHERE CompositeId = @listId

-- Get the minimum status for the list.
SELECT @status = min(dli.Status)
FROM   DisasterCodeListItem dli
JOIN   @tbl1 t
  ON   t.ListId = dli.ListId
WHERE  dli.Status != 1

-- If no active items on list, return zero
IF @status IS NULL RETURN 0

-- Begin the transaction
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

-- Update the disaster code list
IF EXISTS (SELECT 1 FROM DisasterCodeList WHERE ListId = @listId AND Status != @status) BEGIN
   UPDATE DisasterCodeList
   SET    Status = @status
   WHERE  ListId = @listId AND RowVersion = @rowVersion
   SELECT @error = @@error, @rowcount = @@rowcount
   IF @error != 0 BEGIN
      ROLLBACK TRANSACTION @tranName
      COMMIT TRANSACTION
      SET @msg = ''Error encountered while updating disaster code list status'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
      EXECUTE error$raise @msg, @error
      RETURN -100
   END
   ELSE IF @rowCount = 0 BEGIN
      ROLLBACK TRANSACTION @tranName
      COMMIT TRANSACTION
      SET @msg = ''Disaster code list has been modified since retrieval.'' + @msgTag + ''>''
      RAISERROR(@msg,16,1)
      RETURN -100
   END
END

COMMIT TRANSACTION
RETURN 0
END
'
)

IF EXISTS(SELECT * FROM sysobjects WHERE name = 'disasterCodeList$afterUpdate' AND objectproperty(id, 'ExecIsUpdateTrigger' ) = 1) 
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'TRIGGER disasterCodeList$afterUpdate
ON     DisasterCodeList
WITH ENCRYPTION
AFTER  UPDATE
AS
BEGIN
DECLARE @msg nvarchar(255)        -- used to preformat error message
DECLARE @msgTag nvarchar(255)     -- used to hold first part of error message header
DECLARE @msgUpdate nvarchar(4000) -- used to hold the updated fields
DECLARE @tranName nvarchar(255)   -- used to hold name of savepoint
DECLARE @listName nchar(10)       -- holds the name of the updated list
DECLARE @compositeName nchar(10)  -- holds the name of the composite list
DECLARE @rowcount int             -- holds the number of rows in the Deleted table
DECLARE @returnValue int
DECLARE @status int
DECLARE @cid int
DECLARE @cv rowversion
DECLARE @rv rowversion
DECLARE @lastList int
DECLARE @error int

SET @rowcount = @@rowcount
IF @rowcount = 0 RETURN

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

-- Audit merges
SET @lastList = 0
WHILE 1 = 1 BEGIN
   SELECT TOP 1 @listName = i.ListName,
          @lastList = i.ListId,
          @cid = i.CompositeId
   FROM   Inserted i
   JOIN   Deleted d
     ON   d.ListId = i.ListId
   WHERE  i.ListId > @lastList AND
          d.CompositeId IS NULL AND
          i.CompositeId IS NOT NULL
   ORDER BY i.ListId ASC
   IF @@rowcount = 0
      BREAK
   ELSE BEGIN
      -- Get the composite list
      SELECT @compositeName = ListName
      FROM   DisasterCodeList
      WHERE  ListId = @cid
      -- Make sure that the composite is not discrete
      IF EXISTS(SELECT 1 FROM DisasterCodeList WHERE AccountId IS NOT NULL AND ListId = @cid) BEGIN
         SET @msg = ''Lists may not be merged into other discrete lists.'' + @msgTag + ''>''
         EXECUTE error$raise @msg, 0, @tranName
         RETURN
      END
      -- Insert audit record
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
         9,
         ''List '' + @listName + '' merged into composite '' + @compositeName,
         dbo.string$GetSpidLogin()
      )
      SET @error = @@error
      IF @error != 0 BEGIN
         SET @msg = ''Error encountered while inserting disaster recovery list audit record.'' + @msgTag + '';Error='' + cast(@error as nvarchar(9)) + ''>''
         EXECUTE error$raise @msg, @error, @tranName
         RETURN
      END
   END
END

-- Audit extractions
SET @lastList = 0
WHILE 1 = 1 BEGIN
   SELECT TOP 1 @listName = i.ListName,
          @lastList = i.ListId,
          @cid = d.CompositeId
   FROM   Inserted i
   JOIN   Deleted d
     ON   d.ListId = i.ListId
   WHERE  i.ListId > @lastList AND
          i.CompositeId IS NULL AND
          d.CompositeId IS NOT NULL
   ORDER BY i.ListId ASC
   IF @@rowcount = 0
      BREAK
   ELSE BEGIN
      -- Get the composite list.  We don''t need to update the status of the
      -- composite here, because if a list can be extracted, we know that the
      -- list has submitted status.  This is particular to disaster code lists.
      SELECT @compositeName = ListName
      FROM   DisasterCodeList
      WHERE  ListId = @cid
      -- Insert audit record
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
         8,
         ''List '' + @listName + '' extracted from composite '' + @compositeName,
         dbo.string$GetSpidLogin()
      )
      SET @error = @@error
      IF @error != 0 BEGIN
         SET @msg = ''Error encountered while inserting disaster recovery list audit record.'' + @msgTag + '';Error='' + cast(@error as nvarchar(9)) + ''>''
         EXECUTE error$raise @msg, @error, @tranName
         RETURN
      END
      -- If the composite list has no more discretes, delete it
      IF NOT EXISTS(SELECT 1 FROM DisasterCodeList WHERE CompositeId = @cid) BEGIN
         DELETE DisasterCodeList
         WHERE  ListId = @cid
         SET @error = @@error
         IF @error != 0 BEGIN
            SET @msg = ''Error encountered while deleting dissolved composite list.'' + @msgTag + '';Error='' + cast(@error as nvarchar(9)) + ''>''
            EXECUTE error$raise @msg, @error, @tranName
            RETURN
         END
      END
   END
END

-- Audit status changes
SET @lastList = 0
WHILE 1 = 1 BEGIN
   SELECT TOP 1 @listName = i.ListName,
          @lastList = i.ListId,
          @status = i.Status,
          @cid = i.CompositeId,
          @rv = i.RowVersion
   FROM   Inserted i
   JOIN   Deleted d
     ON   d.ListId = i.ListId
   WHERE  i.ListId > @lastList AND
          d.Status != i.Status
   ORDER BY i.ListId ASC
   IF @@rowcount = 0
      BREAK
   ELSE BEGIN
      -- Get the update string
      IF @status = 2
         SET @msgUpdate = ''''
      ELSE IF @status = 4
         SET @msgUpdate = ''List '' + @listName + '' transmitted''
      ELSE IF @status = 512
         SET @msgUpdate = ''List '' + @listName + '' processed''
      -- Insert audit record
      IF len(@msgUpdate) != 0 BEGIN
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
            2,
            @msgUpdate,
            dbo.string$GetSpidLogin()
         )
         SET @error = @@error
         IF @error != 0 BEGIN
            SET @msg = ''Error encountered while inserting disaster recovery list audit record.'' + @msgTag + '';Error='' + cast(@error as nvarchar(9)) + ''>''
            EXECUTE error$raise @msg, @error, @tranName
            RETURN
         END
      END
      -- If belongs to a composite, set status of composite
      IF @cid IS NOT NULL BEGIN
         SELECT @cv = RowVersion
         FROM   DisasterCodeList
         WHERE  ListId = @cid         
         EXECUTE @returnValue = disasterCodeList$setStatus @cid, @cv
         IF @returnValue != 0 BEGIN
            ROLLBACK TRANSACTION @tranName
            COMMIT TRANSACTION
            RETURN
         END
      END
      ELSE IF dbo.bit$statusEligible(4,@status,512) = 1 BEGIN
         EXECUTE @returnValue = disasterCodeList$clear @lastList, @rv
         IF @returnValue != 0 BEGIN
            ROLLBACK TRANSACTION @tranName
            COMMIT TRANSACTION
            RETURN
         END
      END
   END
END          

-- Commit transaction
COMMIT TRANSACTION
END
'
)

END
GO
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
--
-- Update default constraints to use utc times
--
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'defXDisasterCodeListItem$Date' AND objectproperty(id, 'IsDefaultCnst') = 1)
   ALTER TABLE XDisasterCodeListItem
      DROP CONSTRAINT defXDisasterCodeListItem$Date

ALTER TABLE XDisasterCodeListItem
   ADD CONSTRAINT defXDisasterCodeListItem$Date DEFAULT getutcdate() FOR Date

IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'defXVaultInventory$Date' AND objectproperty(id, 'IsDefaultCnst') = 1)
   ALTER TABLE XVaultInventory
      DROP CONSTRAINT defXVaultInventory$Date

ALTER TABLE XVaultInventory
   ADD CONSTRAINT defXVaultInventory$Date DEFAULT getutcdate() FOR Date

IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'defXVaultDiscrepancy$Date' AND objectproperty(id, 'IsDefaultCnst') = 1)
   ALTER TABLE XVaultDiscrepancy
      DROP CONSTRAINT defXVaultDiscrepancy$Date

ALTER TABLE XVaultDiscrepancy
   ADD CONSTRAINT defXVaultDiscrepancy$Date DEFAULT getutcdate() FOR Date

IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'defXBarCodePattern$Date' AND objectproperty(id, 'IsDefaultCnst') = 1)
   ALTER TABLE XBarCodePattern
      DROP CONSTRAINT defXBarCodePattern$Date

ALTER TABLE XBarCodePattern
   ADD CONSTRAINT defXBarCodePattern$Date DEFAULT getutcdate() FOR Date

IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'defXIgnoredBarCodePattern$Date' AND objectproperty(id, 'IsDefaultCnst') = 1)
   ALTER TABLE XIgnoredBarCodePattern
      DROP CONSTRAINT defXIgnoredBarCodePattern$Date

ALTER TABLE XIgnoredBarCodePattern
   ADD CONSTRAINT defXIgnoredBarCodePattern$Date DEFAULT getutcdate() FOR Date

IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'defXExternalSiteLocation$Date' AND objectproperty(id, 'IsDefaultCnst') = 1)
   ALTER TABLE XExternalSiteLocation
      DROP CONSTRAINT defXExternalSiteLocation$Date

ALTER TABLE XExternalSiteLocation
   ADD CONSTRAINT defXExternalSiteLocation$Date DEFAULT getutcdate() FOR Date

IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'defXSystemAction$Date' AND objectproperty(id, 'IsDefaultCnst') = 1)
   ALTER TABLE XSystemAction
      DROP CONSTRAINT defXSystemAction$Date

ALTER TABLE XSystemAction
   ADD CONSTRAINT defXSystemAction$Date DEFAULT getutcdate() FOR Date

IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'defXGeneralAction$Date' AND objectproperty(id, 'IsDefaultCnst') = 1)
   ALTER TABLE XGeneralAction
      DROP CONSTRAINT defXGeneralAction$Date

ALTER TABLE XGeneralAction
   ADD CONSTRAINT defXGeneralAction$Date DEFAULT getutcdate() FOR Date

IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'defXGeneralError$Date' AND objectproperty(id, 'IsDefaultCnst') = 1)
   ALTER TABLE XGeneralError
      DROP CONSTRAINT defXGeneralError$Date

ALTER TABLE XGeneralError
   ADD CONSTRAINT defXGeneralError$Date DEFAULT getutcdate() FOR Date

IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'defDatabaseVersion$InstallDate' AND objectproperty(id, 'IsDefaultCnst') = 1)
   ALTER TABLE DatabaseVersion
      DROP CONSTRAINT defDatabaseVersion$InstallDate

ALTER TABLE DatabaseVersion
   ADD CONSTRAINT defDatabaseVersion$InstallDate DEFAULT getutcdate() FOR InstallDate

IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'defSendListScan$Date' AND objectproperty(id, 'IsDefaultCnst') = 1)
   ALTER TABLE SendListScan
      DROP CONSTRAINT defSendListScan$Date

IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'defSendListScan$CreateDate' AND objectproperty(id, 'IsDefaultCnst') = 1)
   ALTER TABLE SendListScan
      DROP CONSTRAINT defSendListScan$CreateDate

ALTER TABLE SendListScan
   ADD CONSTRAINT defSendListScan$CreateDate DEFAULT convert(datetime,convert(nchar(19),getutcdate(),120)) FOR CreateDate

IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'defXMedium$Date' AND objectproperty(id, 'IsDefaultCnst') = 1)
   ALTER TABLE XMedium
      DROP CONSTRAINT defXMedium$Date

ALTER TABLE XMedium
   ADD CONSTRAINT defXMedium$Date DEFAULT getutcdate() FOR Date

IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'defXMediumMovement$Date' AND objectproperty(id, 'IsDefaultCnst') = 1)
   ALTER TABLE XMediumMovement
      DROP CONSTRAINT defXMediumMovement$Date

ALTER TABLE XMediumMovement
   ADD CONSTRAINT defXMediumMovement$Date DEFAULT getutcdate() FOR Date

IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'defXSealedCase$Date' AND objectproperty(id, 'IsDefaultCnst') = 1)
   ALTER TABLE XSealedCase
      DROP CONSTRAINT defXSealedCase$Date

ALTER TABLE XSealedCase
   ADD CONSTRAINT defXSealedCase$Date DEFAULT getutcdate() FOR Date

IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'defXAccount$Date' AND objectproperty(id, 'IsDefaultCnst') = 1)
   ALTER TABLE XAccount
      DROP CONSTRAINT defXAccount$Date

ALTER TABLE XAccount
   ADD CONSTRAINT defXAccount$Date DEFAULT getutcdate() FOR Date

IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'defXOperator$Date' AND objectproperty(id, 'IsDefaultCnst') = 1)
   ALTER TABLE XOperator
      DROP CONSTRAINT defXOperator$Date

ALTER TABLE XOperator
   ADD CONSTRAINT defXOperator$Date DEFAULT getutcdate() FOR Date

IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'defReceiveListScan$Date' AND objectproperty(id, 'IsDefaultCnst') = 1)
   ALTER TABLE ReceiveListScan
      DROP CONSTRAINT defReceiveListScan$Date

IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'defReceiveListScan$CreateDate' AND objectproperty(id, 'IsDefaultCnst') = 1)
   ALTER TABLE ReceiveListScan
      DROP CONSTRAINT defReceiveListScan$CreateDate

ALTER TABLE ReceiveListScan
   ADD CONSTRAINT defReceiveListScan$CreateDate DEFAULT convert(datetime,convert(nchar(19),getutcdate(),120)) FOR CreateDate

IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'defXSendList$Date' AND objectproperty(id, 'IsDefaultCnst') = 1)
   ALTER TABLE XSendList
      DROP CONSTRAINT defXSendList$Date

ALTER TABLE XSendList
   ADD CONSTRAINT defXSendList$Date DEFAULT getutcdate() FOR Date

IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'defXSendListItem$Date' AND objectproperty(id, 'IsDefaultCnst') = 1)
   ALTER TABLE XSendListItem
      DROP CONSTRAINT defXSendListItem$Date

ALTER TABLE XSendListItem
   ADD CONSTRAINT defXSendListItem$Date DEFAULT getutcdate() FOR Date

IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'defXSendListCase$Date' AND objectproperty(id, 'IsDefaultCnst') = 1)
   ALTER TABLE XSendListCase
      DROP CONSTRAINT defXSendListCase$Date

ALTER TABLE XSendListCase
   ADD CONSTRAINT defXSendListCase$Date DEFAULT getutcdate() FOR Date

IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'defXReceiveList$Date' AND objectproperty(id, 'IsDefaultCnst') = 1)
   ALTER TABLE XReceiveList
      DROP CONSTRAINT defXReceiveList$Date

ALTER TABLE XReceiveList
   ADD CONSTRAINT defXReceiveList$Date DEFAULT getutcdate() FOR Date

IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'defRecallTicket$CreateDate' AND objectproperty(id, 'IsDefaultCnst') = 1)
   ALTER TABLE RecallTicket
      DROP CONSTRAINT defRecallTicket$CreateDate

ALTER TABLE RecallTicket
   ADD CONSTRAINT defRecallTicket$CreateDate DEFAULT getutcdate() FOR CreateDate

IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'defXReceiveListItem$Date' AND objectproperty(id, 'IsDefaultCnst') = 1)
   ALTER TABLE XReceiveListItem
      DROP CONSTRAINT defXReceiveListItem$Date

ALTER TABLE XReceiveListItem
   ADD CONSTRAINT defXReceiveListItem$Date DEFAULT getutcdate() FOR Date

IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'defXDisasterCodeList$Date' AND objectproperty(id, 'IsDefaultCnst') = 1)
   ALTER TABLE XDisasterCodeList
      DROP CONSTRAINT defXDisasterCodeList$Date

ALTER TABLE XDisasterCodeList
   ADD CONSTRAINT defXDisasterCodeList$Date DEFAULT getutcdate() FOR Date

GO
-------------------------------------------------------------------------------
--
-- Version update
--
-------------------------------------------------------------------------------
IF NOT EXISTS(SELECT 1 FROM DatabaseVersion WHERE Major = 1 AND Minor = 2 AND Revision = 0) BEGIN
   DECLARE @x nvarchar(1000)
   EXECUTE spidLogin$ins 'System', 'Insert database version'
   INSERT DatabaseVersion (Major, Minor, Revision) VALUES (1, 2, 0)
   EXECUTE spidLogin$del
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
