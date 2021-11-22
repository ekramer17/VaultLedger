-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
--
-- VaultLedger database update - version 1.1.1
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

-- Rename the alternate keys that were misnamed to begin with
IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'akDisasterCodeList$akListName' AND objectproperty(id,'IsUniqueCnst') = 1)
   ALTER TABLE DisasterCodeList DROP CONSTRAINT akDisasterCodeList$akListName

IF NOT EXISTS (SELECT 1 FROM sysobjects WHERE name = 'akDisasterCodeList$ListName' AND objectproperty(id,'IsUniqueCnst') = 1)
   ALTER TABLE DisasterCodeList ADD CONSTRAINT akDisasterCodeList$ListName UNIQUE NONCLUSTERED (ListName)

IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'akReceiveList$akListName' AND objectproperty(id,'IsUniqueCnst') = 1)
   ALTER TABLE ReceiveList DROP CONSTRAINT akReceiveList$akListName

IF NOT EXISTS (SELECT 1 FROM sysobjects WHERE name = 'akReceiveList$ListName' AND objectproperty(id,'IsUniqueCnst') = 1)
   ALTER TABLE ReceiveList ADD CONSTRAINT akReceiveList$ListName UNIQUE NONCLUSTERED (ListName)

IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'akSendList$akListName' AND objectproperty(id,'IsUniqueCnst') = 1)
   ALTER TABLE SendList DROP CONSTRAINT akSendList$akListName

IF NOT EXISTS (SELECT 1 FROM sysobjects WHERE name = 'akSendList$ListName' AND objectproperty(id,'IsUniqueCnst') = 1)
   ALTER TABLE SendList ADD CONSTRAINT akSendList$ListName UNIQUE NONCLUSTERED (ListName)

IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'akDisasterCodeCase$Medium' AND objectproperty(id,'IsUniqueCnst') = 1)
   ALTER TABLE DisasterCodeCase DROP CONSTRAINT akDisasterCodeCase$Medium

IF NOT EXISTS (SELECT 1 FROM sysobjects WHERE name = 'akDisasterCodeCase$Case' AND objectproperty(id,'IsUniqueCnst') = 1)
   ALTER TABLE DisasterCodeCase ADD CONSTRAINT akDisasterCodeCase$Case UNIQUE NONCLUSTERED (CaseId)
GO

-- Check constraint assigned to wrong table
IF EXISTS (SELECT 1 FROM sysobjects so1 JOIN sysobjects so2 ON so1.parent_obj = so2.id WHERE so1.name = 'chkBarCodePatternCase$Pattern' and so2.name = 'BarCodePattern')
   ALTER TABLE BarCodePattern DROP CONSTRAINT chkBarCodePatternCase$Pattern

IF NOT EXISTS (SELECT 1 FROM sysobjects so1 JOIN sysobjects so2 ON so1.parent_obj = so2.id WHERE so1.name = 'chkBarCodePatternCase$Pattern' and so2.name = 'BarCodePatternCase')
   ALTER TABLE BarCodePatternCase ADD CONSTRAINT chkBarCodePatternCase$Pattern
      CHECK (dbo.bit$IsEmptyString(Pattern) = 0 AND dbo.bit$LegalCharacters(Pattern, 'ALPHANUMERIC', '*.[-]{,}' ) = 1)
GO

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
--
-- We should have a database version check here.  If > 1.1.1, then do not
-- perform the update.
--
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
DECLARE @doScript bit
DECLARE @thisVersion nvarchar(50)
DECLARE @currentVersion nvarchar(50)

SELECT @doScript = 1
SELECT @thisVersion = '1.1.1'

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
-- Stored Procedures
--
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'receiveList$removeCase')
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
FROM   ReceiveList
WHERE  ListId = @listId AND RowVersion = @rowVersion
IF @@rowCount = 0 BEGIN
   IF EXISTS(SELECT 1 FROM ReceiveList WHERE ListId = @listId) BEGIN
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

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'medium$getPage')
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
SET @var = @var + '', @x3$ nvarchar(1000), @x4$ nvarchar(1000), @x5$ nvarchar(1000), @x6$ nvarchar(1000), @x7$ nvarchar(1000)''
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
SET @fields2 = ''MediumId, SerialNo, Location, HotStatus, ReturnDate, Missing, LastMoveDate, BSide, Notes, AccountName, TypeName, CaseName, RowVersion''
SET @fields1 = ''m.MediumId, m.SerialNo, m.Location, m.HotStatus, case len(coalesce(convert(nvarchar(10),c.ReturnDate,120),'''''''')) when 0 then coalesce(convert(nvarchar(10),m.ReturnDate,120),'''''''') else convert(nvarchar(10),c.ReturnDate,120) end as ''''ReturnDate'''', m.Missing, coalesce(convert(nvarchar(19),m.LastMoveDate,120),'''''''') as ''''LastMoveDate'''', m.BSide, m.Notes, a.AccountName, t.TypeName, coalesce(c.CaseName,'''''''') as ''''CaseName'''', m.RowVersion''

-- Construct the tables string
SET @tables = ''Medium m JOIN Account a ON a.AccountId = m.AccountId JOIN MediumType t ON t.TypeId = m.TypeId LEFT OUTER JOIN (SELECT sc.SerialNo as ''''CaseName'''', msc.MediumId as ''''MediumId'''', sc.ReturnDate as ''''ReturnDate'''' FROM SealedCase sc JOIN MediumSealedCase msc ON msc.CaseId = sc.CaseId) as c ON c.MediumId = m.MediumId''

-- Select the total number of records that fit the criteria
CREATE TABLE #tblTemp (xyz int)
SET @sql = ''INSERT #tblTemp SELECT count(*) FROM '' + @tables + @where
EXECUTE sp_executesql @sql, @var, @x1$ = @x1, @x2$ = @x2, @x3$ = @x3, @x4$ = @x4, @x5$ = @x5, @x6$ = @x6, @x7$ = @x7, @y0$ = @y0, @y1$ = @y1, @y2$ = @y2, @y3$ = @y3, @y4$ = @y4, @y5$ = @y5, @y6$ = @y6, @y7$ = @y7, @y8$ = @y8, @y9$ = @y9
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
EXECUTE sp_executesql @sql, @var, @x1$ = @x1, @x2$ = @x2, @x3$ = @x3, @x4$ = @x4, @x5$ = @x5, @x6$ = @x6, @x7$ = @x7, @y0$ = @y0, @y1$ = @y1, @y2$ = @y2, @y3$ = @y3, @y4$ = @y4, @y5$ = @y5, @y6$ = @y6, @y7$ = @y7, @y8$ = @y8, @y9$ = @y9
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

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'disasterCodeList$getPage')
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
SET @tables = ''DisasterCodeList dl LEFT OUTER JOIN Account a ON dl.AccountId = a.AccountId''

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

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'disasterCodeListItem$getPage')
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
SET @fields1 = ''dli.ItemId, dli.Status, coalesce(lm.SerialNo,lc.SerialNo) as ''''SerialNo'''', coalesce(lm.AccountName,'''''''') as ''''AccountName'''', dli.Code, lm.Notes, dli.RowVersion''

-- Construct the tables string
SET @tables = ''DisasterCodeListItem dli JOIN DisasterCodeList dl ON dl.ListId = dli.ListId LEFT OUTER JOIN (SELECT dlim.ItemId, m.SerialNo, a.AccountName, m.Notes FROM DisasterCodeListItemMedium dlim JOIN Medium m ON m.MediumId = dlim.MediumId JOIN Account a ON a.AccountId = m.AccountId) as lm ON lm.ItemId = dli.ItemId LEFT OUTER JOIN (SELECT dlic.ItemId, sc.SerialNo FROM DisasterCodeListItemCase dlic JOIN SealedCase sc ON sc.CaseId = dlic.CaseId) as lc ON lc.ItemId = dli.ItemId''

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

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'receiveList$getPage')
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

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'receiveListItem$getPage')
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
SET @fields1 = ''rli.ItemId, m.SerialNo, a.AccountName, rli.Status, coalesce(sc.CaseName,'''''''') as ''''CaseName'''', m.Notes, rli.RowVersion''

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

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'sendList$getPage')
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

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'sendListItem$getPage')
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
SET @fields1 = ''sli.ItemId, m.SerialNo, a.AccountName, sli.Status, coalesce(c.ReturnDate,coalesce(convert(nvarchar(10),sli.ReturnDate,120),'''''''')) as ''''ReturnDate'''', coalesce(c.CaseName,'''''''') as ''''CaseName'''', m.Notes, sli.RowVersion''

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

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'vaultDiscrepancy$getPage')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.vaultDiscrepancy$getPage
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
   SET @order1 = '' ORDER BY s.SerialNo asc, s.Type asc, v.RecordedDate asc''
   SET @order2 = '' ORDER BY SerialNo desc, Type desc, RecordedDate desc''
   SET @order3 = '' ORDER BY SerialNo asc, Type asc, RecordedDate asc''
END
ELSE IF @sort = 2 BEGIN
   SET @order1 = '' ORDER BY v.RecordedDate asc, s.Type asc, s.SerialNo asc''
   SET @order2 = '' ORDER BY RecordedDate desc, Type desc, SerialNo desc''
   SET @order3 = '' ORDER BY RecordedDate asc, Type asc, SerialNo asc''
END
ELSE IF @sort = 3 BEGIN
   SET @order1 = '' ORDER BY s.Type asc, v.RecordedDate asc, m.SerialNo asc''
   SET @order2 = '' ORDER BY Type desc, RecordedDate desc, SerialNo desc''
   SET @order3 = '' ORDER BY Type asc, RecordedDate asc, SerialNo asc''
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
      SET @where = @where + '' AND (s.'' + left(@s, charindex(''='',@s) + 1) + '' @x1$)''
      SET @x1 = replace(ltrim(substring(@s, charindex(''='',@s) + 1, 4000)), '''''''', '''')
   END
   ELSE IF charindex(''RecordedDate'', @s) = 1 BEGIN
      SET @where = @where + '' AND ('' + replace(left(@s, charindex(''='',@s) + 1),''RecordedDate'',''convert(nvarchar(10),v.RecordedDate,120)'') + '' @x2$)''
      SET @x2 = replace(ltrim(substring(@s, charindex(''='',@s) + 1, 4000)), '''''''', '''')
   END
   ELSE IF charindex(''Type ='', @s) = 1 BEGIN
      SET @where = @where + '' AND (s.'' + left(@s, charindex(''='',@s) + 1) + '' @x3$)''
      SET @x3 = replace(ltrim(substring(@s, charindex(''='',@s) + 1, 4000)), '''''''', '''')
   END
   ELSE BEGIN
      SET @msg = ''Error occurred while selecting page of receiving lists.  Invalid filter supplied.'' + @msgTag + ''>''
      EXECUTE error$raise @msg
      RETURN -100
   END
END

-- Construct the fields string
SET @fields2 = ''ItemId, RecordedDate, SerialNo, Details, Type''
SET @fields1 = ''v.ItemId, v.RecordedDate, s.SerialNo, s.Details, s.Type''

-- Construct the tables string
SET @tables = ''VaultDiscrepancy v JOIN (SELECT v.ItemId, v.SerialNo, case m.Location when 1 then ''''Vault claims residence of medium'''' else ''''Vault denies residence of medium'''' end as ''''Details'''', 1 as ''''Type'''' FROM VaultDiscrepancyResidency v JOIN Medium m ON m.MediumId = v.MediumId UNION SELECT ItemId, SerialNo, ''''Vault claims residence of locally unknown case'''' as ''''Details'''', 3 as ''''Type'''' FROM VaultDiscrepancyUnknownCase UNION SELECT v.ItemId, v.SerialNo, ''''Vault asserts medium should be of type '''''''''''' + mt.TypeName + '''''''''''''''' as ''''Details'''', 2 as ''''Type'''' FROM VaultDiscrepancyMediumType v JOIN MediumType mt ON v.VaultType = mt.TypeId UNION SELECT v.ItemId, v.SerialNo, ''''Vault asserts container should be of type '''''''''''' + mt.TypeName + '''''''''''''''' as ''''Details'''', 4 as ''''Type'''' FROM VaultDiscrepancyCaseType v JOIN MediumType mt ON v.VaultType = mt.TypeId UNION SELECT v.ItemId, v.SerialNo, ''''Vault asserts medium should belong to account '''''''''''' + a.AccountName + '''''''''''''''' as ''''Details'''', 5 as ''''Type'''' FROM VaultDiscrepancyAccount v JOIN Account a ON v.VaultAccount = a.AccountId) as s ON s.ItemId = v.ItemId''

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
   SET @msg = ''Error occurred while selecting page of vault discrepancies.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
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

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'vaultInventory$resolveMissing')
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
                LastMoveDate = cast(convert(nchar(19), getdate(), 120) as datetime)
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

END

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'barCodePattern$ins')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.barCodePattern$ins
(
   @pattern nvarchar(256),
   @position int,
   @mediumType nvarchar(256),
   @accountName nvarchar(256)
)
WITH ENCRYPTION
AS
BEGIN
DECLARE @msg as nvarchar(255)        -- used to preformat error message
DECLARE @msgTag as nvarchar(255)     -- used to hold first part of error message header
DECLARE @tranName as nvarchar(255)   -- used to hold name of savepoint
DECLARE @accountId int
DECLARE @error as int
DECLARE @typeId int

SET NOCOUNT ON

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=P''
SET @tranName = object_name(@@procid) + CAST(@@nestlevel as nvarchar(2))

-- Adjust strings
SET @pattern = ltrim(rtrim(isnull(@pattern,'''')))
SET @mediumType = ltrim(rtrim(isnull(@mediumType,'''')))
SET @accountName = ltrim(rtrim(isnull(@accountName,'''')))

-- Get the medium type id
SELECT @typeId = TypeId
FROM   MediumType
WHERE  TypeName = @mediumType AND Container = 0
IF @@rowcount = 0 BEGIN
   SET @msg = ''Medium type not found.'' + @msgTag + ''>''
   RAISERROR(@msg, 16, 1)
   RETURN -100
END

-- Get the account id
SELECT @accountId = AccountId
FROM   Account
WHERE  AccountName = @accountName
IF @@rowcount = 0 BEGIN
   SET @msg = ''Account not found.'' + @msgTag + ''>''
   RAISERROR(@msg, 16, 1)
   RETURN -100
END

-- Begin transaction
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

-- Insert the fields into the table variable
INSERT BarCodePattern (Pattern, Position, TypeId, AccountId, Notes)
VALUES (@pattern, @position, @typeId, @accountId, '''')

-- Evaluate error
SET @error = @@error
IF @error != 0 BEGIN
   ROLLBACK TRANSACTION @tranName
   COMMIT TRANSACTION
   SET @msg = ''Error encountered while inserting bar code format.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
   RAISERROR(@msg, 16, 1)
   RETURN -100
END

-- Commit transaction
COMMIT TRANSACTION
RETURN 0
END
'
)

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'barCodePattern$del')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.barCodePattern$del
WITH ENCRYPTION
AS
BEGIN
DECLARE @msg as nvarchar(255)        -- used to preformat error message
DECLARE @msgTag as nvarchar(255)     -- used to hold first part of error message header
DECLARE @tranName as nvarchar(255)   -- used to hold name of savepoint
DECLARE @error as int

BEGIN TRANSACTION
SAVE TRANSACTION @tranName

-- Delete the barcode formats
DELETE FROM BarCodePattern

-- Evaluate error
SET @error = @@error
IF @error != 0 BEGIN
   ROLLBACK TRANSACTION @tranName
   COMMIT TRANSACTION
   SET @msg = ''Error encountered while deleting bar code formats.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
   RAISERROR(@msg, 16, 1)
   RETURN -100
END

-- Commit transaction
COMMIT TRANSACTION
RETURN 0
END
'
)

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'barCodePatternCase$del')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.barCodePatternCase$del
WITH ENCRYPTION
AS
BEGIN
DECLARE @msg as nvarchar(255)        -- used to preformat error message
DECLARE @msgTag as nvarchar(255)     -- used to hold first part of error message header
DECLARE @tranName as nvarchar(255)   -- used to hold name of savepoint
DECLARE @error as int

BEGIN TRANSACTION
SAVE TRANSACTION @tranName

-- Delete the barcode formats
DELETE FROM BarCodePatternCase

-- Evaluate error
SET @error = @@error
IF @error != 0 BEGIN
   ROLLBACK TRANSACTION @tranName
   COMMIT TRANSACTION
   SET @msg = ''Error encountered while deleting case formats.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
   RAISERROR(@msg, 16, 1)
   RETURN -100
END

-- Commit transaction
COMMIT TRANSACTION
RETURN 0
END
'
)

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'barCodePatternCase$ins')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.barCodePatternCase$ins
(
   @pattern nvarchar(256),
   @position int,
   @caseType nvarchar(256)
)
WITH ENCRYPTION
AS
BEGIN
DECLARE @msg as nvarchar(255)        -- used to preformat error message
DECLARE @msgTag as nvarchar(255)     -- used to hold first part of error message header
DECLARE @tranName as nvarchar(255)   -- used to hold name of savepoint
DECLARE @accountId int
DECLARE @error as int
DECLARE @typeId int

SET NOCOUNT ON

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=P''
SET @tranName = object_name(@@procid) + CAST(@@nestlevel as nvarchar(2))

-- Adjust strings
SET @pattern = ltrim(rtrim(isnull(@pattern,'''')))
SET @caseType = ltrim(rtrim(isnull(@caseType,'''')))

-- Get the medium type id
SELECT @typeId = TypeId
FROM   MediumType
WHERE  TypeName = @caseType AND Container = 1
IF @@rowcount = 0 BEGIN
   SET @msg = ''Medium type not found.'' + @msgTag + ''>''
   RAISERROR(@msg, 16, 1)
   RETURN -100
END

-- Begin transaction
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

-- Insert the fields into the table variable
INSERT BarCodePatternCase (Pattern, Position, TypeId, Notes)
VALUES (@pattern, @position, @typeId, '''')

-- Evaluate error
SET @error = @@error
IF @error != 0 BEGIN
   ROLLBACK TRANSACTION @tranName
   COMMIT TRANSACTION
   SET @msg = ''Error encountered while inserting case format.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
   RAISERROR(@msg, 16, 1)
   RETURN -100
END

-- Commit transaction
COMMIT TRANSACTION
RETURN 0
END
'
)

IF EXISTS(SELECT * FROM sysobjects WHERE name = 'barCodePattern$afterInsert' AND objectproperty(id, 'ExecIsInsertTrigger' ) = 1) 
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
   EXECUTE error$raise @msg, 0, @tranName
   RETURN
END

-- Make sure that no types are container types
IF NOT EXISTS(SELECT 1 FROM Inserted i JOIN MediumType m ON i.TypeId = m.TypeId WHERE m.Container = 0) BEGIN
   SET @msg = ''Type id given may not be of a container type.'' + @msgTag + ''>''
   RAISERROR(@msg, 16, 1)
   RETURN
END

-- Make sure that the maximum position value in the table is equal to the number of rows
IF EXISTS (SELECT 1 FROM BarCodePattern WHERE Position > (SELECT count(*) FROM BarCodePattern)) BEGIN
   SET @msg = ''Position value must be equal to number of bar code pattern records.'' + @msgTag + ''>''
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

IF EXISTS(SELECT * FROM sysobjects WHERE name = 'barCodePatternCase$afterInsert' AND objectproperty(id, 'ExecIsInsertTrigger' ) = 1) 
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
   EXECUTE error$raise @msg, 0, @tranName
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

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'barCodePattern$synchronize')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.barCodePattern$synchronize
WITH ENCRYPTION
AS
BEGIN
declare @tranName nvarchar(255)   -- used to hold name of savepoint
declare @tblLiteral table (RowNo int identity(1,1), Id int, Type int, Account int)
declare @tblFormat table (RowNo int identity(1,1), Pattern nvarchar(256), Type int, Account int)
declare @tblOther table (RowNo int identity(1,1), Id int, SerialNo nvarchar(256), Type int, Account int)
declare @s nvarchar(256)
declare @id int
declare @i int
declare @t int
declare @a int
declare @t1 int
declare @a1 int

-- Get those media that correspond to literal barcodes and
-- do not have the correct type or account
INSERT @tblLiteral (Id, Type, Account)
SELECT m.MediumId, p.TypeId, p.AccountId
FROM   Medium m
JOIN   BarCodePattern p
  ON   p.Pattern = m.SerialNo
WHERE  m.TypeId != p.TypeId OR m.AccountId != p.AccountId

-- Get those media that do not correspond to literal barcodes
INSERT @tblOther (Id, SerialNo, Type, Account)
SELECT m.MediumId, m.SerialNo, m.TypeId, m.AccountId
FROM   Medium m
LEFT   JOIN BarCodePattern p
  ON   p.Pattern = m.SerialNo
WHERE  p.Pattern IS NULL

-- Get all the non-literal bar code formats
INSERT @tblFormat (Pattern, Type, Account)
SELECT Pattern, TypeId, AccountId
FROM   BarCodePattern
WHERE  dbo.bit$RegexMatch(Pattern, ''[a-zA-Z0-9]*'') != 1
ORDER  BY Position ASC

-- Update the literals
SET @i = 1

WHILE 1 = 1 BEGIN
   SELECT @id = Id, 
          @t = Type, 
          @a = Account 
   FROM   @tblLiteral 
   WHERE  RowNo = @i
   IF @@rowcount = 0 
      BREAK
   ELSE
      UPDATE Medium SET TypeId = @t, AccountId = @a WHERE MediumId = @id
   -- Increment
   SET @i = @i + 1
END

-- Run through the non-literals
SET @i = 1

WHILE 1 = 1 BEGIN
   SELECT @id = Id, 
          @s = SerialNo, 
          @t = Type, 
          @a = Account 
   FROM   @tblOther 
   WHERE  RowNo = @i
   IF @@rowcount = 0 BREAK
   -- Get the correct type from the bar code format table
   SELECT TOP 1 @t1 = Type, @a1 = Account
   FROM   @tblFormat
   WHERE  dbo.bit$RegexMatch(@s, Pattern) = 1
   -- If the non-literal does not have the correct type or account, update it
   IF @t != @t1 OR @a != @a1 BEGIN
      BEGIN TRANSACTION
      SAVE TRANSACTION @tranName
      UPDATE Medium
      SET    TypeId = @t1,
             AccountId = @a1
      WHERE  MediumId = @id
      -- Roll back if error, but keep going
      IF @@error != 0 ROLLBACK TRAN @tranName
      -- Commit the transaction
      COMMIT TRANSACTION
   END
   -- Increment
   SET @i = @i + 1
END

-- Return
RETURN 0
END
'
)

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'barCodePatternCase$synchronize')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.barCodePatternCase$synchronize
WITH ENCRYPTION
AS
BEGIN
declare @tranName nvarchar(255)   -- used to hold name of savepoint
declare @tblLiteral table (RowNo int identity(1,1), Id int, Type int, Send bit)
declare @tblFormat table (RowNo int identity(1,1), Pattern nvarchar(256), Type int)
declare @tblOther table (RowNo int identity(1,1), Id int, SerialNo nvarchar(256), Type int, Send bit)
declare @s nvarchar(256)
declare @id int
declare @i int
declare @t int
declare @t1 int
declare @x bit

-- Get all the non-literal bar code formats
INSERT @tblFormat (Pattern, Type)
SELECT Pattern, TypeId
FROM   BarCodePatternCase
WHERE  dbo.bit$RegexMatch(Pattern, ''[a-zA-Z0-9]*'') != 1
ORDER  BY Position ASC

-- Get those cases that correspond to literal barcodes and
-- do not have the correct type or account
INSERT @tblLiteral (Id, Type, Send)
SELECT c.CaseId, p.TypeId, 0
FROM   SealedCase c
JOIN   BarCodePatternCase p
  ON   p.Pattern = c.SerialNo
WHERE  c.TypeId != p.TypeId
UNION
SELECT c.CaseId, p.TypeId, 1
FROM   SendListCase c
JOIN   BarCodePatternCase p
  ON   p.Pattern = c.SerialNo
WHERE  c.TypeId != p.TypeId

-- Get those cases that do not correspond to literal barcodes
INSERT @tblOther (Id, SerialNo, Type, Send)
SELECT c.CaseId, c.SerialNo, c.TypeId, 0
FROM   SealedCase c
LEFT   JOIN BarCodePatternCase p
  ON   p.Pattern = c.SerialNo
WHERE  p.Pattern IS NULL
UNION
SELECT c.CaseId, c.SerialNo, c.TypeId, 1
FROM   SendListCase c
LEFT   JOIN BarCodePatternCase p
  ON   p.Pattern = c.SerialNo
WHERE  p.Pattern IS NULL

-- Update the literals
SET @i = 1

WHILE 1 = 1 BEGIN
   SELECT @id = Id, 
          @t = Type,
          @x = Send
   FROM   @tblLiteral 
   WHERE  RowNo = @i
   IF @@rowcount = 0 
      BREAK
   ELSE IF @x = 0 BEGIN
      UPDATE SealedCase 
      SET    TypeId = @t
      WHERE  CaseId = @id
   END
   ELSE BEGIN
      UPDATE SendListCase 
      SET    TypeId = @t
      WHERE  CaseId = @id
   END
   -- Increment
   SET @i = @i + 1
END

-- Run through the non-literals
SET @i = 1

WHILE 1 = 1 BEGIN
   SELECT @id = Id, 
          @s = SerialNo, 
          @t = Type, 
          @x = Send
   FROM   @tblOther 
   WHERE  RowNo = @i
   IF @@rowcount = 0 BREAK
   -- Get the correct type from the bar code format table
   SELECT TOP 1 @t1 = Type
   FROM   @tblFormat
   WHERE  dbo.bit$RegexMatch(@s, Pattern) = 1
   -- If the non-literal does not have the correct type or account, update it
   IF @t != @t1 BEGIN
      BEGIN TRANSACTION
      SAVE TRANSACTION @tranName
      IF @x = 0 BEGIN
         UPDATE SealedCase
         SET    TypeId = @t1
         WHERE  CaseId = @id
      END
      ELSE BEGIN
         UPDATE SendListCase
         SET    TypeId = @t1
         WHERE  CaseId = @id
      END
      -- Roll back if error, but keep going
      IF @@error != 0 ROLLBACK TRAN @tranName
      -- Commit the transaction
      COMMIT TRANSACTION
   END
   -- Increment
   SET @i = @i + 1
END

-- Return
RETURN 0
END
'
)

GO
-------------------------------------------------------------------------------
--
-- Version update
--
-------------------------------------------------------------------------------
IF NOT EXISTS(SELECT 1 FROM DatabaseVersion WHERE Major = 1 AND Minor = 1 AND Revision = 1) BEGIN
   DECLARE @x nvarchar(1000)
   EXECUTE spidLogin$ins 'System', 'Insert database version'
   INSERT DatabaseVersion (Major, Minor, Revision) VALUES (1, 1, 1)
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
