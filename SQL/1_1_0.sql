-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
--
-- VaultLedger database update - version 1.0.1
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

-- Expiration for general actions
IF NOT EXISTS(SELECT 1 FROM XCategoryExpiration WHERE Category = 16384) BEGIN
   ALTER TABLE XCategoryExpiration DROP CONSTRAINT chkXCategoryExpiration$Category
   INSERT dbo.XCategoryExpiration (Category, Days, Archive) VALUES (16384, 30, 0)
   ALTER TABLE XCategoryExpiration ADD CONSTRAINT chkXCategoryExpiration$Category CHECK (Category IN (1,2,4,8,16,32,64,128,256,512,1024,2048,4096,8192,16384))
END
GO

-- Insert new preferences
INSERT SpidLogin (Spid, Login, LastCall) VALUES (@@spid, 'System', getdate())
IF NOT EXISTS (SELECT 1 FROM Preference WHERE KeyNo = 8) INSERT Preference (KeyNo, Value) VALUES (8, 'NO')
IF NOT EXISTS (SELECT 1 FROM Preference WHERE KeyNo = 9) INSERT Preference (KeyNo, Value) VALUES (9, '20')
DELETE SpidLogin WHERE Spid = @@spid
GO
-------------------------------------------------------------------------------
--
-- Major update beginning here.  Changing list statuses.
--
-------------------------------------------------------------------------------
-- If we see 1024 in the send list constraint, then we need to do list status value manipulation
CREATE TABLE #tblStatus (DoData bit)
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.CHECK_CONSTRAINTS WHERE CONSTRAINT_NAME = 'chkSendList$Status' AND charindex('1024',CHECK_CLAUSE) != 0)
   INSERT #tblStatus VALUES (1)
GO

--=======================================================
-- Drop check constraints so that we can manipulate data
--=======================================================
IF EXISTS(SELECT 1 FROM INFORMATION_SCHEMA.CHECK_CONSTRAINTS WHERE CONSTRAINT_NAME = 'chkSendList$Status')
   ALTER TABLE SendList DROP CONSTRAINT chkSendList$Status
GO

IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.CHECK_CONSTRAINTS WHERE CONSTRAINT_NAME = 'chkSendListItem$Status')
   ALTER TABLE SendListItem DROP CONSTRAINT chkSendListItem$Status
GO

IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'defSendList$Status' and objectproperty(object_id(name),'isdefaultcnst') = 1)
   ALTER TABLE SendList DROP CONSTRAINT defSendList$Status
GO

IF EXISTS(SELECT 1 FROM INFORMATION_SCHEMA.CHECK_CONSTRAINTS WHERE CONSTRAINT_NAME = 'chkReceiveList$Status')
   ALTER TABLE ReceiveList DROP CONSTRAINT chkReceiveList$Status
GO

IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'defReceiveList$Status' and objectproperty(object_id(name),'isdefaultcnst') = 1)
   ALTER TABLE ReceiveList DROP CONSTRAINT defReceiveList$Status
GO

IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.CHECK_CONSTRAINTS WHERE CONSTRAINT_NAME = 'chkReceiveListItem$Status') 
   ALTER TABLE ReceiveListItem DROP CONSTRAINT chkReceiveListItem$Status
GO

IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'defReceiveListItem$Status' and objectproperty(object_id(name),'isdefaultcnst') = 1)
   ALTER TABLE ReceiveListItem DROP CONSTRAINT defReceiveListItem$Status
GO

IF EXISTS(SELECT 1 FROM INFORMATION_SCHEMA.CHECK_CONSTRAINTS WHERE CONSTRAINT_NAME = 'chkDisasterCodeList$Status')
   ALTER TABLE DisasterCodeList DROP CONSTRAINT chkDisasterCodeList$Status
GO

IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'defDisasterCodeList$Status' and objectproperty(object_id(name),'isdefaultcnst') = 1)
   ALTER TABLE DisasterCodeList DROP CONSTRAINT defDisasterCodeList$Status
GO

IF EXISTS(SELECT 1 FROM INFORMATION_SCHEMA.CHECK_CONSTRAINTS WHERE CONSTRAINT_NAME = 'chkDisasterCodeListItem$Status')
   ALTER TABLE DisasterCodeListItem DROP CONSTRAINT chkDisasterCodeListItem$Status
GO

IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'defDisasterCodeListItem$Status' and objectproperty(object_id(name),'isdefaultcnst') = 1)
   ALTER TABLE DisasterCodeListItem DROP CONSTRAINT defDisasterCodeListItem$Status
GO
--==============================
-- Manipulate status value data
--==============================
IF EXISTS (SELECT 1 FROM #tblStatus WHERE DoData = 1) BEGIN
   -- Send list
   ALTER TABLE SendList DISABLE TRIGGER sendList$afterUpdate
   UPDATE SendList SET Status = 2 WHERE Status = 4
   UPDATE SendList SET Status = 4 WHERE Status = 16
   UPDATE SendList SET Status = 8 WHERE Status = 64
   UPDATE SendList SET Status = 16 WHERE Status = 256
   UPDATE SendList SET Status = 512 WHERE Status = 1024
   ALTER TABLE SendList ENABLE TRIGGER sendList$afterUpdate
   -- Send list items
   ALTER TABLE SendListItem DISABLE TRIGGER sendListItem$afterUpdate
   UPDATE SendListItem SET Status = 2 WHERE Status = 4
   UPDATE SendListItem SET Status = 8 WHERE Status = 64
   UPDATE SendListItem SET Status = 16 WHERE Status = 256
   UPDATE SendListItem SET Status = 512 WHERE Status = 1024
   ALTER TABLE SendListItem ENABLE TRIGGER sendListItem$afterUpdate
   -- Receive list
   ALTER TABLE ReceiveList DISABLE TRIGGER receiveList$afterUpdate
   UPDATE ReceiveList SET Status = 2 WHERE Status = 4
   UPDATE ReceiveList SET Status = 4 WHERE Status = 16
   UPDATE ReceiveList SET Status = 128 WHERE Status = 64
   UPDATE ReceiveList SET Status = 512 WHERE Status = 1024
   ALTER TABLE ReceiveList ENABLE TRIGGER receiveList$afterUpdate
   -- Receive list items
   ALTER TABLE ReceiveListItem DISABLE TRIGGER receiveListItem$afterUpdate
   UPDATE ReceiveListItem SET Status = 2 WHERE Status = 4
   UPDATE ReceiveListItem SET Status = 4 WHERE Status = 16
   UPDATE ReceiveListItem SET Status = 512 WHERE Status = 1024
   ALTER TABLE ReceiveListItem ENABLE TRIGGER receiveListItem$afterUpdate
   -- Disaster code list
   ALTER TABLE DisasterCodeList DISABLE TRIGGER disasterCodeList$afterUpdate
   UPDATE DisasterCodeList SET Status = 2 WHERE Status = 4
   UPDATE DisasterCodeList SET Status = 4 WHERE Status = 16
   UPDATE DisasterCodeList SET Status = 8 WHERE Status = 64
   ALTER TABLE DisasterCodeList ENABLE TRIGGER disasterCodeList$afterUpdate
   -- Disaster code list items
   ALTER TABLE DisasterCodeListItem DISABLE TRIGGER disasterCodeListItem$afterUpdate
   UPDATE DisasterCodeListItem SET Status = 2 WHERE Status = 4
   UPDATE DisasterCodeListItem SET Status = 4 WHERE Status = 16
   UPDATE DisasterCodeListItem SET Status = 8 WHERE Status = 64
   ALTER TABLE DisasterCodeListItem ENABLE TRIGGER disasterCodeListItem$afterUpdate
END
-- Drop the table
DROP TABLE #tblStatus
--==============================
-- Reintroduce the constraints
--==============================
ALTER TABLE SendList ADD CONSTRAINT chkSendList$Status CHECK (Status IN (2, 4, 8, 16, 32, 64, 128, 256, 512))
GO

ALTER TABLE SendListItem ADD CONSTRAINT chkSendListItem$Status CHECK (Status IN (1, 2, 8, 16, 32, 64, 256, 512))
GO

ALTER TABLE SendList ADD CONSTRAINT defSendList$Status DEFAULT 2 FOR Status
GO

ALTER TABLE ReceiveList ADD CONSTRAINT chkReceiveList$Status CHECK (Status IN (2, 4, 8, 16, 32, 64, 128, 256, 512))
GO

ALTER TABLE ReceiveListItem ADD CONSTRAINT chkReceiveListItem$Status CHECK (Status IN (1, 2, 4, 16, 32, 64, 256, 512))
GO

ALTER TABLE ReceiveList ADD CONSTRAINT defReceiveList$Status DEFAULT 2 FOR Status
GO

ALTER TABLE ReceiveListItem ADD CONSTRAINT defReceiveListItem$Status DEFAULT 2 FOR Status
GO

ALTER TABLE DisasterCodeList ADD CONSTRAINT chkDisasterCodeList$Status CHECK (Status IN (2, 4, 512))
GO

ALTER TABLE DisasterCodeListItem ADD CONSTRAINT chkDisasterCodeListItem$Status CHECK (Status IN (1, 2, 4, 512))
GO

ALTER TABLE DisasterCodeList ADD CONSTRAINT defDisasterCodeList$Status DEFAULT 2 FOR Status
GO

ALTER TABLE DisasterCodeListItem ADD CONSTRAINT defDisasterCodeListItem$Status DEFAULT 2 FOR Status
GO
--===========================
-- Add Stage field for scans
--===========================
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'SendListScan' AND COLUMN_NAME = 'Stage')
   ALTER TABLE SendListScan ADD Stage int NOT NULL CONSTRAINT defSendListScan$Stage DEFAULT 1
GO

IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'ReceiveListScan' AND COLUMN_NAME = 'Stage')
   ALTER TABLE ReceiveListScan ADD Stage int NOT NULL CONSTRAINT defReceiveListScan$Stage DEFAULT 1
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'ListStatusProfile') BEGIN
CREATE TABLE dbo.ListStatusProfile
(
-- Attributes
   ProfileId   int  NOT NULL  CONSTRAINT pkListStatusProfile PRIMARY KEY CLUSTERED, -- 1 - Send, 2 - Receive, 4 - Disaster
   Statuses    int  NOT NULL  -- Sum of selected among: 
                              -- Send     : 8=VerifiedI, 16=Transmitted, 32=InTransit, 64=Arrived, 256=VerifiedII
                              -- Receive  : 4=Transmitted, 16=VerifiedI, 32=InTransit, 64=Arrived, 256=VerifiedII
                              -- Disaster : 4=Transmitted
                              -- NOTE: 2 is always submitted, and 512 is always processed; every type uses both
)
END
GO

IF NOT EXISTS (SELECT 1 FROM ListStatusProfile WHERE ProfileId = 1)
   INSERT ListStatusProfile (ProfileId, Statuses) VALUES (1, 24)   -- Verified(I) and Transmitted
IF NOT EXISTS (SELECT 1 FROM ListStatusProfile WHERE ProfileId = 2)
   INSERT ListStatusProfile (ProfileId, Statuses) VALUES (2, 260)  -- Transmitted and Verified(II)
IF NOT EXISTS (SELECT 1 FROM ListStatusProfile WHERE ProfileId = 4)
   INSERT ListStatusProfile (ProfileId, Statuses) VALUES (4, 4)   -- Transmitted
GO

IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'SpidLogin' AND COLUMN_NAME = 'SeqNo') BEGIN
   ALTER TABLE SpidLogin DROP CONSTRAINT pkSpidLogin
   ALTER TABLE SpidLogin ADD SeqNo int NOT NULL CONSTRAINT defSpidLogin$SeqNo DEFAULT 1
   ALTER TABLE SpidLogin ADD CONSTRAINT pkSpidLogin PRIMARY KEY (Spid, SeqNo)
END

-- Last login column
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'Operator' AND COLUMN_NAME = 'LastLogin')
   ALTER TABLE Operator ADD LastLogin datetime NOT NULL CONSTRAINT defOperator$LastLogin DEFAULT '1900-01-01'
GO

--================================
-- Get rid of phone number checks
--================================
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.CHECK_CONSTRAINTS WHERE CONSTRAINT_NAME = 'chkAccount$PhoneNo')
   ALTER TABLE Account DROP CONSTRAINT chkAccount$PhoneNo
GO

IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.CHECK_CONSTRAINTS WHERE CONSTRAINT_NAME = 'chkOperator$PhoneNo')
   ALTER TABLE Operator DROP CONSTRAINT chkOperator$PhoneNo
GO

IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.ROUTINES WHERE SPECIFIC_NAME = 'bit$IsPhoneNumber')
   DROP FUNCTION dbo.bit$IsPhoneNumber
GO

-------------------------------------------------------------------------------
--
-- Recall FTP Format
--
-------------------------------------------------------------------------------
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'FtpRecall') BEGIN
CREATE TABLE dbo.FtpRecall
(
-- Attributes
   SendNo      int  NOT NULL  CONSTRAINT defFtpRecall$SendNo DEFAULT 0,
   ReceiveNo   int  NOT NULL  CONSTRAINT defFtpRecall$ReceiveNo DEFAULT 0,
   DisasterNo  int  NOT NULL  CONSTRAINT defFtpRecall$DisasterNo DEFAULT 0,
-- Relationships
   AccountId   int  NOT NULL  CONSTRAINT pkFtpRecall PRIMARY KEY CLUSTERED
)
END
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS WHERE CONSTRAINT_NAME = 'fkFtpRecall$Account') BEGIN
ALTER TABLE dbo.FtpRecall
   ADD CONSTRAINT fkFtpRecall$Account
      FOREIGN KEY (AccountId) REFERENCES dbo.Account
         ON DELETE CASCADE
END
GO
-------------------------------------------------------------------------------
--
-- Email Groups
--
-------------------------------------------------------------------------------
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'EmailServer') BEGIN
CREATE TABLE dbo.EmailServer
(
-- Attributes
   ServerName   nvarchar(256) NOT NULL,
   FromAddress  nvarchar(256) NOT NULL
)
END
GO

-- Email addresses must be of email format
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.CHECK_CONSTRAINTS WHERE CONSTRAINT_NAME = 'chkEmailServer$FromAddress')
   ALTER TABLE EmailServer ADD CONSTRAINT chkEmailServer$FromAddress CHECK (dbo.bit$IsEmailAddress(FromAddress) = 1 OR dbo.bit$IsEmptyString(FromAddress) = 1)
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'EmailGroup') BEGIN
CREATE TABLE dbo.EmailGroup
(
-- Attributes
   GroupId   int           NOT NULL  CONSTRAINT pkEmailGroup PRIMARY KEY CLUSTERED IDENTITY(1,1),
   GroupName nvarchar(256) NOT NULL  CONSTRAINT akEmailGroup$Name UNIQUE NONCLUSTERED
)
END
GO

-- Must have a name, which may not contain pipes (used as escape character)
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.CHECK_CONSTRAINTS WHERE CONSTRAINT_NAME = 'chkEmailGroup$GroupName')
   ALTER TABLE EmailGroup ADD CONSTRAINT chkEmailGroup$GroupName
      CHECK (dbo.bit$IsEmptyString(GroupName) = 0 AND dbo.bit$IllegalCharacters(GroupName, '%_*?|' ) = 0)
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'EmailGroupOperator') BEGIN
CREATE TABLE dbo.EmailGroupOperator
(
-- Relationships
   GroupId    int  NOT NULL,
   OperatorId int  NOT NULL
)
END
GO

IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS WHERE TABLE_NAME = 'EmailGroupOperator' AND CONSTRAINT_NAME = 'pkEmailGroupOperator') BEGIN
   ALTER TABLE EmailGroupOperator ADD CONSTRAINT pkEmailGroupOperator PRIMARY KEY CLUSTERED (GroupId, OperatorId)
END
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS WHERE CONSTRAINT_NAME = 'fkEmailGroupOperator$EmailGroup') BEGIN
ALTER TABLE dbo.EmailGroupOperator
   ADD CONSTRAINT fkEmailGroupOperator$EmailGroup
      FOREIGN KEY (GroupId) REFERENCES dbo.EmailGroup
         ON DELETE CASCADE
END
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS WHERE CONSTRAINT_NAME = 'fkEmailGroupOperator$Operator') BEGIN
ALTER TABLE dbo.EmailGroupOperator
   ADD CONSTRAINT fkEmailGroupOperator$Operator
      FOREIGN KEY (OperatorId) REFERENCES dbo.Operator
         ON DELETE CASCADE
END
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'ListStatusEmail') BEGIN
CREATE TABLE dbo.ListStatusEmail
(
-- Attributes
   ListType   int  NOT NULL,
   Status     int  NOT NULL,
-- Relationships
   GroupId    int  NOT NULL
)
END
GO

IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS WHERE TABLE_NAME = 'ListStatusEmail' AND CONSTRAINT_NAME = 'pkListStatusEmail') BEGIN
   ALTER TABLE ListStatusEmail ADD CONSTRAINT pkListStatusEmail PRIMARY KEY CLUSTERED (ListType, Status, GroupId)
END
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS WHERE CONSTRAINT_NAME = 'fkListStatusEmail$EmailGroup') BEGIN
ALTER TABLE dbo.ListStatusEmail
   ADD CONSTRAINT fkListStatusEmail$EmailGroup
      FOREIGN KEY (GroupId) REFERENCES dbo.EmailGroup
         ON DELETE CASCADE
END
GO

-- Add a return date column to vaultinventoryitem
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'VaultInventoryItem' AND COLUMN_NAME = 'ReturnDate')
   ALTER TABLE VaultInventoryItem ADD ReturnDate nvarchar(10) NOT NULL CONSTRAINT defVaultInventoryItem$ReturnDate DEFAULT ''
GO

-- Add a check to the return date column
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.CHECK_CONSTRAINTS WHERE CONSTRAINT_NAME = 'chkVaultInventoryItem$ReturnDate')
   ALTER TABLE VaultInventoryItem ADD CONSTRAINT chkVaultInventoryItem$ReturnDate CHECK (dbo.bit$IsEmptyString(ReturnDate) = 1 or IsDate(ReturnDate) = 1)
GO
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
--
-- We should have a database version check here.  If > 1.0.1, then do not
-- perform the update.  Future scripts should check should check to make sure
--
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
DECLARE @doScript bit
DECLARE @thisVersion nvarchar(50)
DECLARE @currentVersion nvarchar(50)

SELECT @doScript = 1
SELECT @thisVersion = '1.1.0'

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
IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'ftpRecall$del')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.ftpRecall$del
(
   @accountName nvarchar(256)
)
WITH ENCRYPTION
AS
BEGIN
DECLARE @msg as nvarchar(255)        -- used to preformat error message
DECLARE @msgTag as nvarchar(255)     -- used to hold first part of error message header
DECLARE @tranName as nvarchar(255)   -- used to hold name of savepoint
DECLARE @error as int

SET NOCOUNT ON

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=P''
SET @tranName = object_name(@@procid) + CAST(@@nestlevel as nvarchar(2))

-- Delete operator
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

DELETE FtpRecall
WHERE  AccountId = (SELECT AccountId FROM Account WHERE AccountName = @accountName)

SELECT @error = @@error

IF @error != 0 BEGIN
   ROLLBACK TRANSACTION @tranName
   COMMIT TRANSACTION
   SET @msg = ''Error encountered while deleting Recall ftp parameters.'' + @msgTag + '';Error='' + cast(@error as nvarchar(10)) + ''>''
   EXECUTE error$raise @msg, @error
   RETURN -100
END

-- Commit transaction
COMMIT TRANSACTION
RETURN 0
END
'
)

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'ftpRecall$get')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.ftpRecall$get
(
   @accountName nvarchar(256)
)
WITH ENCRYPTION
AS
BEGIN

SET NOCOUNT ON

-- Select
SELECT AccountId,
       SendNo,
       ReceiveNo,
       DisasterNo
FROM   FtpRecall
WHERE  AccountId = (SELECT AccountId FROM Account WHERE AccountName = @accountName)
END
'
)

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'ftpRecall$ins')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.ftpRecall$ins
(
   @accountName nvarchar(256),
   @sendNo int = 0,
   @receiveNo int = 0,
   @disasterNo int = 0
)
WITH ENCRYPTION
AS
BEGIN
DECLARE @msg as nvarchar(255)      -- used to preformat error message
DECLARE @msgTag as nvarchar(255)    -- used to hold first part of error message header
DECLARE @tranName as nvarchar(255)   -- used to hold name of savepoint
DECLARE @accountId as int
DECLARE @error as int

SET NOCOUNT ON

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=P''
SET @tranName = object_name(@@procid) + CAST(@@nestlevel as nvarchar(2))

-- Get the account number
SELECT @accountId = AccountId FROM Account WHERE AccountName = @accountName

-- Insert or update recall ftp parameters
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

IF EXISTS (SELECT 1 FROM FtpRecall WHERE AccountId = @accountId) BEGIN
   UPDATE FtpRecall
   SET    SendNo = @sendNo,
          ReceiveNo = @receiveNo,
          DisasterNo = @disasterNo
   WHERE  AccountId = @accountId
END
ELSE BEGIN
   INSERT FtpRecall (AccountId, SendNo, ReceiveNo, DisasterNo)
   VALUES(@accountId, @sendNo, @receiveNo, @disasterNo)
END

SET @error = @@error
IF @error != 0 BEGIN
   ROLLBACK TRANSACTION @tranName
   COMMIT TRANSACTION
   SET @msg = ''Error encountered while inserting/updating Recall ftp parameters.'' + @msgTag + '';Error='' + cast(@error as nvarchar(10)) + ''>''
   EXECUTE error$raise @msg, @error
   RETURN -100
END

-- Commit transaction
COMMIT TRANSACTION
RETURN 0
END
'
)

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'auditTrail$getMedium')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.auditTrail$getMedium
(
   @serialNo nvarchar(32),
   @startDate datetime = null,
   @endDate datetime = null
)
WITH ENCRYPTION
AS
BEGIN
DECLARE @i int
DECLARE @listName nvarchar(10)
DECLARE @tblLists table
(
   RowNo int identity (1,1),
   ListName nvarchar(10)
)
DECLARE @tblTable table
(
   ItemId int,
   Date datetime,
   Object nvarchar(512),
   Action int,
   Detail nvarchar(2048),
   Login nvarchar(64),
   AuditType int,
   ListName nvarchar(10)
)

SET NOCOUNT ON

-- Initialize
SELECT @i = 1
SELECT @endDate = isnull(@endDate, ''9999-12-31 23:59:59'')
SELECT @startDate = isnull(@startDate, ''1900-01-01 00:00:00'')

-- Get regular records
INSERT @tblTable (ItemId, Date, Object, Action, Detail, Login, AuditType, ListName)
SELECT ItemId, Date, Object, Action, Detail, Login, 4096, ''''   -- Medium
FROM   XMedium
WHERE  Object = @serialNo AND Date > @startDate AND Date < @endDate
UNION
SELECT ItemId, Date, Object, Method, case Direction when 1 then ''Medium moved to enterprise'' else ''Medium moved to vault'' end, Login, 8192, ''''  -- Medium Movement
FROM   XMediumMovement
WHERE  Object = @serialNo AND Date > @startDate AND Date < @endDate
UNION
SELECT ItemId, Date, Object, Action, Detail, Login, 2048, ''''   -- Sealed case
FROM   XSealedCase
WHERE  Detail LIKE ''%Medium '''''' + @serialNo + ''''''%'' AND Date > @startDate AND Date < @endDate
UNION
SELECT ItemId, Date, Object, Action, case charindex('' list'', Detail) when 0 then Detail + '';list='' + Object else replace(Detail, '' list'', '' list '' + Object) end, Login, 64, Object   -- Send list item
FROM   XSendListItem
WHERE  Detail LIKE ''%Medium '''''' + @serialNo + ''''''%'' AND Date > @startDate AND Date < @endDate
UNION
SELECT ItemId, Date, Object, Action, case charindex('' list'', Detail) when 0 then Detail + '';list='' + Object else replace(Detail, '' list'', '' list '' + Object) end, Login, 128, Object   -- Receive list item
FROM   XReceiveListItem
WHERE  Detail LIKE ''%Medium '''''' + @serialNo + ''''''%'' AND Date > @startDate AND Date < @endDate
UNION
SELECT ItemId, Date, Object, Action, case charindex('' list'', Detail) when 0 then Detail + '';list='' + Object else replace(Detail, '' list'', '' list '' + Object) end, Login, 256, Object   -- Disaster code list item
FROM   XDisasterCodeListItem
WHERE  Detail LIKE ''%Medium '''''' + @serialNo + ''''''%'' AND Date > @startDate AND Date < @endDate

-- Insert lists into list table
INSERT @tblLists (ListName)
SELECT distinct ListName FROM @tblTable

WHILE 1 = 1 BEGIN
   SELECT @listName = ListName
   FROM   @tblLists
   WHERE  RowNo = @i
   IF @@rowcount = 0 BEGIN
      BREAK
   END
   ELSE IF LEFT(@listName,2) = ''SD'' BEGIN
      INSERT @tblTable (ItemId, Date, Object, Action, Detail, Login, AuditType, ListName)
      SELECT ItemId, Date, Object, Action, Detail, Login, 64, ''''
      FROM   XSendList
      WHERE  Object = @listName AND Date > @startDate AND Date < @endDate
   END
   ELSE IF LEFT (@listName,2) = ''RE'' BEGIN
      INSERT @tblTable (ItemId, Date, Object, Action, Detail, Login, AuditType, ListName)
      SELECT ItemId, Date, Object, Action, Detail, Login, 128, ''''
      FROM   XReceiveList
      WHERE  Object = @listName AND Date > @startDate AND Date < @endDate
   END
   ELSE IF LEFT (@listName,2) = ''DC'' BEGIN
      INSERT @tblTable (ItemId, Date, Object, Action, Detail, Login, AuditType, ListName)
      SELECT ItemId, Date, Object, Action, Detail, Login, 128, ''''
      FROM   XDisasterCodeList
      WHERE  Object = @listName AND Date > @startDate AND Date < @endDate
   END
   -- Increment
   SELECT @i = @i + 1
END

-- Select from table
SELECT ItemId, Date, Object, Action, Detail, Login, AuditType
FROM   @tblTable
ORDER  BY Date desc, AuditType asc, ItemId asc

RETURN 0
END
'
)

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'sendListItem$getByMedium')
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
WHERE  m.SerialNo = @serialNo AND sli.Status NOT IN (1,1024)

END
'
)

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'sendList$getByMedium')
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
FROM   SendList sl
JOIN   SendListItem sli
  ON   sli.ListId = sl.ListId
JOIN   Medium m
  ON   sli.MediumId = m.MediumId
WHERE  m.SerialNo = @serialNo AND sli.Status NOT IN (1,1024)

IF @@rowcount != 0 BEGIN
   IF @compositeId IS NULL BEGIN
      SELECT sl.ListId,
             sl.ListName,
             sl.CreateDate,
             sl.Status,
             a.AccountName,
             sl.RowVersion
      FROM   SendList sl
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
      FROM   SendList sl
      WHERE  sl.ListId = @compositeId
      -- Get the child lists
      SELECT sl.ListId,
             sl.ListName,
             sl.CreateDate,
             sl.Status,
             a.AccountName,
             sl.RowVersion
      FROM   SendList sl
      JOIN   Account a
        ON   a.AccountId = sl.AccountId
      WHERE  sl.CompositeId = @compositeId
      ORDER BY sl.ListName ASC
   END
END

END
'
)

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'receiveListItem$getByMedium')
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
WHERE  m.SerialNo = @serialNo AND rli.Status NOT IN (1,1024)

END
'
)

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'receiveList$getByMedium')
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
FROM   ReceiveList rl
JOIN   ReceiveListItem rli
  ON   rli.ListId = rl.ListId
JOIN   Medium m
  ON   rli.MediumId = m.MediumId
WHERE  m.SerialNo = @serialNo AND rli.Status NOT IN (1,1024)

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

IF EXISTS(SELECT 1 FROM sysobjects WHERE name = 'listStatusProfile$afterUpdate' AND objectproperty(id, 'ExecIsUpdateTrigger' ) = 1) 
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'TRIGGER listStatusProfile$afterUpdate
ON     ListStatusProfile
WITH ENCRYPTION
AFTER  UPDATE
AS
BEGIN
DECLARE @msg nvarchar(255)         -- used to preformat error message
DECLARE @msgTag nvarchar(255)      -- used to hold first part of error message header
DECLARE @tranName nvarchar(255)    -- used to hold name of savepoint
DECLARE @rowCount int              -- holds the number of rows in the Deleted table
DECLARE @login nvarchar(32)
DECLARE @statuses int
DECLARE @i int
DECLARE @id int
DECLARE @status int
DECLARE @doUpdate bit
DECLARE @error int 
DECLARE @listType int 
DECLARE @returnValue int
DECLARE @rowversion binary(8)
DECLARE @auditMsg nvarchar(4000) 
DECLARE @tblClear table (RowNo int primary key identity(1,1), Id int, RowVersion binary(8))
DECLARE @tblLists table (RowNo int primary key identity(1,1), Id int, Status int, DoUpdate bit)

SET @rowCount = @@rowcount
IF @rowCount = 0 RETURN
SET @i = 1

-- Make sure we do not have a batch update
IF @rowCount > 1 BEGIN
   SET @msg = ''Batch update on list status profile table not allowed.'' + @msgTag + ''>''
   EXECUTE error$raise @msg, 0
   RETURN
END

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=T''
SET @tranName = object_name(@@procid) + CAST(trigger_nestlevel(@@procid) as nvarchar(2))

-- Get the caller login from the spidLogin table
SELECT @login = Login
FROM   SpidLogin
WHERE  Spid = @@spid
IF len(@login) = 0 OR @login IS NULL BEGIN
   SET @msg = ''No login found for auditing purposes.'' + @msgTag + ''>''
   EXECUTE error$raise @msg, 0
   RETURN
END

-- Get the list type and the current statuses
SELECT @listType = ProfileId, @statuses = Statuses FROM Inserted

-- Audit messages
IF @listType = 1 BEGIN
  SET @auditMsg = ''Employed shipping lists statuses changed to: submitted''
  IF @statuses & 8 != 0 SET @auditMsg = @auditMsg + '', verified (I)''
  IF @statuses & 16 != 0 SET @auditMsg = @auditMsg + '', transmitted''
  IF @statuses & 32 != 0 SET @auditMsg = @auditMsg + '', in transit''
  IF @statuses & 64 != 0 SET @auditMsg = @auditMsg + '', arrived''
  IF @statuses & 256 != 0 SET @auditMsg = @auditMsg + '', verified (II)''
  SET @auditMsg = @auditMsg + '', processed''
END
ELSE IF @listType = 2 BEGIN
  SET @auditMsg = ''Employed receiving lists statuses changed to Submitted''
  IF @statuses & 4 != 0 SET @auditMsg = @auditMsg + '', transmitted''
  IF @statuses & 16 != 0 SET @auditMsg = @auditMsg + '', verified (I)''
  IF @statuses & 32 != 0 SET @auditMsg = @auditMsg + '', in transit''
  IF @statuses & 64 != 0 SET @auditMsg = @auditMsg + '', arrived''
  IF @statuses & 256 != 0 SET @auditMsg = @auditMsg + '', verified (II)''
  SET @auditMsg = @auditMsg + '', processed''
END
ELSE BEGIN
  SET @auditMsg = ''Employed disaster recovery lists statuses changed to Submitted''
  IF @statuses & 4 != 0 SET @auditMsg = @auditMsg + '', transmitted''
  SET @auditMsg = @auditMsg + '', processed''
END

-- Get all the lists eligible for clearing
IF @listType = 1 BEGIN
   INSERT @tblClear (Id, RowVersion)
   SELECT ListId, RowVersion
   FROM   SendList
   WHERE  CompositeId IS NULL AND dbo.bit$statusEligible(1,Status,512) = 1
END
ELSE IF @listType = 2 BEGIN
   INSERT @tblClear (Id, RowVersion)
   SELECT ListId, RowVersion
   FROM   ReceiveList
   WHERE  CompositeId IS NULL AND dbo.bit$statusEligible(2,Status,512) = 1
END
ELSE IF @listType = 4 BEGIN
   INSERT @tblClear (Id, RowVersion)
   SELECT ListId, RowVersion
   FROM   DisasterCodeList
   WHERE  CompositeId IS NULL AND dbo.bit$statusEligible(4,Status,512) = 1
END

-- Begin transaction
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

-- Audit message
IF len(@auditMsg) != 0 BEGIN
   INSERT XGeneralAction (Detail, Login) VALUES (@auditMsg, @login)
   SET @error = @@error
   IF @error != 0 BEGIN
      SET @msg = ''Error encountered while inserting general action audit record.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
      EXECUTE error$raise @msg, @error, @tranName
      RETURN
   END
END

-- Insert the clear audit tag
IF @listType = 1
   EXECUTE spidLogin$ins @login, ''clear send list''
ELSE IF @listType = 2
   EXECUTE spidLogin$ins @login, ''clear receive list''
ELSE IF @listType = 4
   EXECUTE spidLogin$ins @login, ''clear disaster code list''

-- Clear the lists
WHILE 1 = 1 BEGIN
   SELECT @id = Id, @rowversion = RowVersion
   FROM   @tblClear
   WHERE  RowNo = @i
   IF @@rowcount = 0 
      BREAK
   ELSE BEGIN
      IF @listType = 1
         EXECUTE @returnValue = sendList$clear @id, @rowversion
      ELSE IF @listType = 2
         EXECUTE @returnValue = receiveList$clear @id, @rowversion
      ELSE IF @listType = 4
         EXECUTE @returnValue = disasterCodeList$clear @id, @rowversion
      -- Evaluate return value
      IF @returnValue != 0 BEGIN
         ROLLBACK TRANSACTION @tranName
         COMMIT TRANSACTION
         RETURN
      END
   END
   -- Increment counter
   SELECT @i = @i + 1
END

-- Remove the clear audit tag
EXECUTE spidLogin$del 0

-- Insert status adjustment tag
EXECUTE spidLogin$ins @login, ''status adjustment due to change in statuses employed''

-- Reset the counter
SELECT @i = 1

-- For any list where the status is no longer used, slide it down to the
-- highest status now used lower than the current status. (Disaster code
-- lists do not need to be manipulated.
IF @listType = 1 BEGIN
   INSERT @tblLists(Id, Status, DoUpdate)
   SELECT ListId, Status, 0
   FROM   SendList
   WHERE  AccountId IS NOT NULL AND Status > 2 AND Status < 256
   -- Partially verified (II) status
   IF @statuses & 256 = 0 UPDATE @tblLists SET Status = 64, DoUpdate = 1 WHERE Status = 128
   -- Arrived status
   IF @statuses & 64 = 0 UPDATE @tblLists SET Status = 32, DoUpdate = 1 WHERE Status = 64
   -- In transit status
   IF @statuses & 32 = 0 UPDATE @tblLists SET Status = 16, DoUpdate = 1 WHERE Status = 32
   -- Transmitted status
   IF @statuses & 16 = 0 UPDATE @tblLists SET Status = 8, DoUpdate = 1 WHERE Status = 16
   -- Fully and partially verified (I) status
   IF @statuses & 8 = 0 UPDATE @tblLists SET Status = 2, DoUpdate = 1 WHERE Status in (4,8)
   -- Update the lists
   WHILE 1 = 1 BEGIN
      SELECT @id = Id, @status = Status, @doUpdate = DoUpdate
      FROM   @tblLists
      WHERE  RowNo = @i
      IF @@rowcount = 0 
         BREAK
      ELSE IF @doUpdate = 1 BEGIN
         UPDATE SendListItem
         SET    Status = @status
         WHERE  ListId = @id AND Status != 1
         SET @error = @@error
         IF @error != 0 BEGIN
            ROLLBACK TRANSACTION @tranName
            COMMIT TRANSACTION
            RETURN
         END
      END
      -- Increment counter
      SELECT @i = @i + 1
   END
END
ELSE IF @listType = 2 BEGIN
   INSERT @tblLists(Id, Status, DoUpdate)
   SELECT ListId, Status, 0
   FROM   ReceiveList
   WHERE  AccountId IS NOT NULL AND Status > 2 AND Status < 256
   -- Partially verified (II) status
   IF @statuses & 256 = 0 UPDATE @tblLists SET Status = 64, DoUpdate = 1 WHERE Status = 128
   -- Arrived status
   IF @statuses & 64 = 0 UPDATE @tblLists SET Status = 32, DoUpdate = 1 WHERE Status = 64
   -- In transit status
   IF @statuses & 32 = 0 UPDATE @tblLists SET Status = 16, DoUpdate = 1 WHERE Status = 32
   -- Fully and partially verified (I) status
   IF @statuses & 16 = 0 UPDATE @tblLists SET Status = 4, DoUpdate = 1 WHERE Status in (8,16)
   -- Fully and partially verified (I) status
   IF @statuses & 4 = 0 UPDATE @tblLists SET Status = 2, DoUpdate = 1 WHERE Status = 4
   -- Update the lists
   WHILE 1 = 1 BEGIN
      SELECT @id = Id, @status = Status, @doUpdate = DoUpdate
      FROM   @tblLists
      WHERE  RowNo = @i
      IF @@rowcount = 0 
         BREAK
      ELSE IF @doUpdate = 1 BEGIN
         UPDATE ReceiveListItem
         SET    Status = @status
         WHERE  ListId = @id AND Status != 1
         SET @error = @@error
         IF @error != 0 BEGIN
            ROLLBACK TRANSACTION @tranName
            COMMIT TRANSACTION
            RETURN
         END
      END
      -- Increment counter
      SELECT @i = @i + 1
   END
END

-- Remove the status adjustment tag
EXECUTE spidLogin$del 0

-- Commit transaction
COMMIT TRANSACTION
END
'
)

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'listStatusProfile$getById')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.listStatusProfile$getById
(
   @profileId int
)
WITH ENCRYPTION
AS
BEGIN

SET NOCOUNT ON

SELECT ProfileId,
       Statuses
FROM   ListStatusProfile
WHERE  ProfileId = @profileId

END
'
)

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'listStatusProfile$upd')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.listStatusProfile$upd
(
   @profileId int,
   @statuses int
)
WITH ENCRYPTION
AS
BEGIN
DECLARE @msg as nvarchar(255)
DECLARE @msgTag as nvarchar(255)
DECLARE @tranName as nvarchar(255)   -- used to hold name of savepoint
DECLARE @error int

SET NOCOUNT ON

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=P''
SET @tranName = object_name(@@procid) + CAST(@@nestlevel as nvarchar(2))

-- Set up the transaction tag (nest level ensures uniqueness)
SET @tranName = object_name(@@procid) + CAST(@@nestlevel as nvarchar(2))

-- Update
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

UPDATE ListStatusProfile
SET    Statuses = @statuses
WHERE  ProfileId = @profileId
SET @error = @@error
IF @error != 0 BEGIN
   ROLLBACK TRANSACTION @tranName
   COMMIT TRANSACTION
   SET @msg = ''Error encountered while updating list status profile.'' + @msgTag + '';Error='' + cast(@error as nvarchar(10)) + ''>''
   EXECUTE error$raise @msg, @error
   RETURN -100
END

-- Commit the transaction
COMMIT TRANSACTION
RETURN 0
END
'
)

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
--
-- Function: string$statusName
-- Summary:  Gets the string representation of a list status or, if not used,
--           the next higher employed status.  This function is intended for
--           use only with send and receive lists.
--
-- Given:    @statusValue
--
-- Returns:  name of status
--
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE SPECIFIC_NAME = 'string$statusName')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'FUNCTION dbo.string$statusName
   (
      @listType int,
      @statusValue int
   )
   RETURNS nvarchar(32)
   WITH ENCRYPTION
   AS
   BEGIN
      DECLARE @x int
      DECLARE @statuses int
      DECLARE @returnValue nvarchar(50)
      -- Initialize
      SET @x = -1
      SET @returnValue = ''[ERROR: Unknown Status]''
      -- Everyone uses submitted and processed status
      IF @statusValue IN (2,512)
         SET @x = @statusValue
      ELSE BEGIN
         SELECT @statuses = Statuses
         FROM   ListStatusProfile
         WHERE  ProfileId = @listType
         IF @@rowcount = 1 BEGIN
            SET @x = @statusValue
            WHILE 1 = 1 BEGIN
               IF @x >= 1024 OR @x & @statuses != 0
                  BREAK
               ELSE
                  SET @x = @x * 2
            END
         END
      END
      -- Translate the value
      IF @x = 2
         SET @returnValue = ''submitted''
      ELSE IF @x = 512
         SET @returnValue = ''processed''
      ELSE IF @listType = 1 BEGIN  -- Send list
         IF @x = 4
            SET @returnValue = ''partially verified (I)''
         ELSE IF @x = 8
            SET @returnValue = ''fully verified (I)''
         ELSE IF @x = 16
            SET @returnValue = ''transmitted''
         ELSE IF @x = 32
            SET @returnValue = ''in transit''
         ELSE IF @x = 64
            SET @returnValue = ''arrived''
         ELSE IF @x = 128
            SET @returnValue = ''partially verified (II)''
         ELSE IF @x = 256
            SET @returnValue = ''fully verified (II)''
      END
      ELSE IF @listType = 2 BEGIN  -- Receive list
         IF @x = 4
            SET @returnValue = ''transmitted''
         ELSE IF @x = 8
            SET @returnValue = ''partially verified (I)''
         ELSE IF @x = 16
            SET @returnValue = ''fully verified (I)''
         ELSE IF @x = 32
            SET @returnValue = ''in transit''
         ELSE IF @x = 64
            SET @returnValue = ''arrived''
         ELSE IF @x = 128
            SET @returnValue = ''partially verified (II)''
         ELSE IF @x = 256
            SET @returnValue = ''fully verified (II)''
      END
      ELSE IF @listType = 4 BEGIN  -- Disaster list
         IF @x = 4
            SET @returnValue = ''transmitted''
      END
      -- Return
      RETURN @returnValue
   END
   '
)

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
--
-- Function: bit$statusEligible
-- Summary:  Determines whether a list of the specified type with the
--           specified status is eligible to be moved to the desired status.
--
-- Given:    @profileNo - profile number
--           @statusValue - current status value
--           @desiredValue - desired status value
--
-- Returns:  prior status value on success, else 0
--
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE SPECIFIC_NAME = 'bit$statusEligible')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'FUNCTION dbo.bit$statusEligible
   ( 
      @listType int,
      @statusValue int,
      @desiredStatus int
   )
   RETURNS bit
   WITH ENCRYPTION
   AS
   BEGIN
      DECLARE @x int
      DECLARE @i int
      DECLARE @statuses int
      DECLARE @returnValue bit
      DECLARE @partialOne int
      DECLARE @fullyOne int
      -- Initialize
      SELECT @i = 2
      SELECT @returnValue = 0
      SELECT @x = @desiredStatus / 2
      SELECT @partialOne = case @listType when 1 then 4 else 8 end
      -- Get the statuses from the profile
      SELECT @statuses = Statuses
      FROM   ListStatusProfile
      WHERE  ProfileId = @listType
      -- Check validity of parameters
      IF (@listType IN (1,2) AND @desiredStatus NOT IN (4,8,16,32,64,256,512)) OR
         (@listType = 4 AND @desiredStatus NOT IN (4,512)) OR
         (@statusValue NOT IN (2,4,8,16,32,64,128,256)) OR
         (@statusValue >= @desiredStatus) OR
         (@listType NOT IN (1,2,4))
      BEGIN
         SET @returnValue = 0
      END
      ELSE IF @listType = 4 BEGIN   -- Disaster lists
         IF @desiredStatus = 4 BEGIN
            IF @statuses & 4 = 0
               SET @returnValue = 0
            ELSE
               SET @returnValue = 1
         END
         ELSE IF @desiredStatus = 512  BEGIN
            IF @statusValue = 4 OR @statuses & 4 = 0
               SET @returnValue = 1
         END
      END
      ELSE IF @listType = 1 OR @listType = 2 BEGIN
         WHILE @i <= 512 BEGIN
            -- If @i not in desired status, move to the next value
            IF @i & @desiredStatus = 0 GOTO NEXT
            -- If the desired status is not being employed, go to the next value
            IF @i != 512 AND @i & @statuses = 0 GOTO NEXT
            -- If the current status is partially verified and we desire to be fully
            -- verified, then return 1
            IF @statusValue = @partialOne AND @desiredStatus = @partialOne * 2 BEGIN
               SET @returnValue = 1
               BREAK
            END
            ELSE IF @statusValue = 128 AND @desiredStatus = 256 BEGIN
               SET @returnValue = 1
               BREAK
            END
            -- If the current status is greater than the @i status, go to the next value
            IF @statusValue > @i GOTO NEXT
            -- Run through the statuses
            WHILE @x > 1 BEGIN
               -- Skip partial verification values
               IF @x = @partialOne OR @x = 128 SET @x = @x / 2
               -- If x is now equal to the current status value, return true
               IF @x <= @statusValue BEGIN
                  SET @returnValue = 1
                  SET @i = 512   -- To break outer loop
                  BREAK
               END
               -- If the @x status is used, break the loop
               IF @x & @statuses != 0 BEGIN
                  SET @i = 512
                  BREAK
               END
               -- Go down one status value
               SET @x = @x / 2
            END
            -- Next value
            NEXT:
            SET @i = @i * 2
         END
      END
      -- Return
      return @returnValue
   END
   '
)

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
--
-- Function: dbo.string$listName
-- Summary:  Given a list id, gets the list name for that list if it is not
--           a composite, otherwise the name of the composite
--
-- Given:    @listType - type of list
--           @listId - list id
--
-- Returns:  list name
--
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE SPECIFIC_NAME = 'string$listName')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'FUNCTION dbo.string$listName
   (
      @listType int,
      @listId int
   )
   RETURNS nvarchar(10)
   WITH ENCRYPTION
   AS
   BEGIN
      DECLARE @listName nvarchar(10)
      DECLARE @cid int
      IF @listType = 1 BEGIN
         SELECT @cid = CompositeId
         FROM   SendList
         WHERE  ListId = @listId
         IF @cid IS NOT NULL BEGIN
            SELECT @listName = ListName
            FROM   SendList
            WHERE  ListId = @cid
         END
         ELSE BEGIN
            SELECT @listName = ListName
            FROM   SendList
            WHERE  ListId = @listId
         END
      END
      ELSE IF @listType = 2 BEGIN
         SELECT @cid = CompositeId
         FROM   ReceiveList
         WHERE  ListId = @listId
         IF @cid IS NOT NULL BEGIN
            SELECT @listName = ListName
            FROM   ReceiveList
            WHERE  ListId = @cid
         END
         ELSE BEGIN
            SELECT @listName = ListName
            FROM   ReceiveList
            WHERE  ListId = @listId
         END
      END
      ELSE IF @listType = 4 BEGIN
         SELECT @cid = CompositeId
         FROM   DisasterCodeList
         WHERE  ListId = @listId
         IF @cid IS NOT NULL BEGIN
            SELECT @listName = ListName
            FROM   DisasterCodeList
            WHERE  ListId = @cid
         END
         ELSE BEGIN
            SELECT @listName = ListName
            FROM   DisasterCodeList
            WHERE  ListId = @listId
         END
      END
      -- Return
      RETURN @listName
   END
   '
)

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'receiveList$caseVerified')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.receiveList$caseVerified
(
   @caseName nvarchar(64),
   @serialNo nvarchar(64)
)
WITH ENCRYPTION
AS
BEGIN

SET NOCOUNT ON

-- Checks to see if any media in the given sealed case, besides 
-- the given medium, have been initially verified on an active 
-- receive list.
IF EXISTS 
   (
   SELECT 1
   FROM   Medium m 
   JOIN   MediumSealedCase msc
     ON   msc.MediumId = m.MediumId
   JOIN   SealedCase sc
     ON   msc.CaseId = sc.CaseId
   JOIN   ReceiveListItem rli
     ON   rli.MediumId = m.MediumId
   WHERE  rli.Status >= 8 AND 
          rli.Status != 512 AND 
          m.SerialNo != @serialNo AND 
          sc.SerialNo = @caseName
   )
   SELECT 1
ELSE
   SELECT 0

END
'
)

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
--
-- SpidLogin functions and procedures
--
-------------------------------------------------------------------------------
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
   SELECT @x = '''', @i = 0
   WHILE 1 = 1 BEGIN
      SELECT TOP 1 @y = isnull(TagInfo,''''), @i = SeqNo
      FROM   SpidLogin
      WHERE  Spid = @@spid AND SeqNo > @i
      ORDER  BY SeqNo ASC
      IF @@rowcount = 0 BREAK
      SELECT @x = CASE len(@x) WHEN 0 THEN @y ELSE @x + '';'' + @y END
   END
   RETURN @x
   END
   '
)

IF NOT EXISTS(SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE SPECIFIC_NAME = 'string$getSpidLogin')
   SET @CREATE = 'CREATE '
ELSE
   SET @CREATE = 'ALTER '

EXECUTE
(  
   @CREATE + 'FUNCTION dbo.string$getSpidLogin()
   RETURNS nvarchar(32)
   WITH ENCRYPTION
   AS
   BEGIN
   DECLARE @login nvarchar(32)
   SELECT TOP 1 @login = Login
   FROM   SpidLogin
   WHERE  Spid = @@spid
   ORDER  BY SeqNo DESC
   IF @@rowcount = 0 SELECT @login = ''''
   RETURN @login
   END
   '
)

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'spidLogin$del')
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
          datediff(mi, LastCall, getdate()) > 180
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

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'spidLogin$ins')
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
VALUES (@@spid, @login, getdate(), @newTag, @seqNo)
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

IF EXISTS(SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE SPECIFIC_NAME = 'spidLogin$setInfo')
   EXECUTE ('DROP PROCEDURE spidLogin$setInfo')

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'spidLogin$upd')
   EXECUTE ('DROP PROCEDURE dbo.spidLogin$upd')

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
DECLARE @lastList int
DECLARE @caseId int
DECLARE @mediumId int
DECLARE @code nvarchar(32)
DECLARE @codeId int
DECLARE @status int
DECLARE @error int
DECLARE @returnValue int
DECLARE @rowNo int
DECLARE @tblCase table (RowNo int identity(1,1), CaseId int, Code nvarchar(32))
DECLARE @tblMedium table (RowNo int identity(1,1), MediumId int, Code nvarchar(32))

SET NOCOUNT ON

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=P''
SET @tranName = object_name(@@procid) + CAST(@@nestlevel as nvarchar(2))

-- If the list is not transmitted, raise error.  If the list 
-- has cleared status, return.  Also check concurrency.
SELECT @listName = ListName,
       @accountId = AccountId,
       @status = Status
FROM   DisasterCodeList
WHERE  ListId = @listId
IF @@rowCount = 0 BEGIN
   SET @msg = ''List not found.'' + @msgTag + ''>''
   RAISERROR(@msg,16,1)
   RETURN -100
END
ELSE IF NOT EXISTS
   (
   SELECT 1
   FROM   DisasterCodeList
   WHERE  ListId = @listId AND
          RowVersion = @rowVersion
   )
BEGIN
   SET @msg = ''Disaster code list has been modified since retrieval.'' + @msgTag + ''>''
   RAISERROR(@msg,16,1)
   RETURN -100
END

-- If the list has already been cleared, return.  Otherwise, make sure
-- it is eligible to be cleared.
IF @status = 512 RETURN 0

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
      IF @@rowCount = 0
         BREAK
      ELSE BEGIN
         EXECUTE @returnValue = disasterCodeList$clear @lastList, @rowVersion
         IF @returnValue != 0 BEGIN
            ROLLBACK TRANSACTION @tranName
            COMMIT TRANSACTION
            RETURN -100
         END
      END
   END
END
ELSE BEGIN
   SELECT @rowNo = 1
   INSERT @tblMedium (MediumId, Code)
   SELECT dclim.MediumId,
          dcli.Code
   FROM   DisasterCodeListItemMedium dclim
   JOIN   DisasterCodeListItem dcli
     ON   dcli.ItemId = dclim.ItemId
   WHERE  dcli.Status != 1 AND dcli.ListId = @listId
   ORDER  BY dclim.MediumId ASC
   -- For each medium on the list, create the disaster code if it does not
   -- exist.  Then attach the medium to it.
   WHILE 1 = 1 BEGIN
      -- Get the medium and the code
      SELECT @mediumId = MediumId, @code = Code
      FROM   @tblMedium
      WHERE  RowNo = @rowNo
      IF @@rowCount = 0
         BREAK
      ELSE BEGIN
         -- Delete any current disaster code entry for the medium
         DELETE DisasterCodeMedium
         WHERE  MediumId = @mediumId
         SET @error = @@error
         IF @error != 0 BEGIN
            ROLLBACK TRANSACTION @tranName
            COMMIT TRANSACTION
            SET @msg = ''Error encountered deleting current disaster code entries.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
            EXECUTE error$raise @msg, @error
            RETURN -100
          END
         -- Find the disaster code id.  If it doesn''t exist, create it.
         SELECT @codeId = CodeId 
         FROM   DisasterCode
         WHERE  Code = @code
         IF @@rowCount = 0 BEGIN
            EXECUTE @returnValue = disasterCode$ins @code, '''', @codeId OUTPUT
            IF @returnValue != 0 BEGIN
               ROLLBACK TRANSACTION @tranName
               COMMIT TRANSACTION
               RETURN 0
            END
         END
         -- Insert the item
         EXECUTE @returnValue = disasterCodeMedium$ins @codeId, @mediumId
         IF @returnValue != 0 BEGIN
            ROLLBACK TRANSACTION @tranName
            COMMIT TRANSACTION
            RETURN 0
         END
      END
      -- Increment row number
      SELECT @rowNo = @rowNo + 1
   END
   -- For each case on the list, create the disaster code if it does not
   -- exist.  Then attach the case to it.
   SELECT @rowNo = 1
   INSERT @tblCase (CaseId, Code)
   SELECT dclic.CaseId,
          dcli.Code
   FROM   DisasterCodeListItemCase dclic
   JOIN   DisasterCodeListItem dcli
     ON   dcli.ItemId = dclic.ItemId
   WHERE  dcli.Status != 1 AND dcli.ListId = @listId
   ORDER BY dclic.CaseId ASC
   WHILE 1 = 1 BEGIN
      -- Get the case and the code
      SELECT @caseId = CaseId, @code = Code
      FROM   @tblCase
      WHERE  RowNo = @rowNo
      IF @@rowCount = 0
         BREAK
      ELSE BEGIN
         -- Find the disaster code id.  If it doesn''t exist, create it.
         SELECT @codeId = CodeId 
         FROM   DisasterCode
         WHERE  Code = @code
         IF @@rowCount = 0 BEGIN
            EXECUTE @returnValue = disasterCode$ins @code, '''', @codeId OUTPUT
            IF @returnValue != 0 BEGIN
               ROLLBACK TRANSACTION @tranName
               COMMIT TRANSACTION
               RETURN 0
            END
         END
         -- Insert the item
         EXECUTE @returnValue = disasterCodeCase$ins @codeId, @caseId
         IF @returnValue != 0 BEGIN
            ROLLBACK TRANSACTION @tranName
            COMMIT TRANSACTION
            RETURN 0
         END
      END
      -- Increment row number
      SELECT @rowNo = @rowNo + 1
   END
   -- Set the status of all unremoved list items to cleared
   UPDATE DisasterCodeListItem
   SET    Status = 512
   WHERE  Status != 1 AND ListId = @listId
   SET @error = @@error
   IF @error != 0 BEGIN
      ROLLBACK TRANSACTION @tranName
      COMMIT TRANSACTION
      SET @msg = ''Error occurred while upgrading disaster code list item status to cleared.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
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

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'disasterCodeList$del')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.disasterCodeList$del
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
DECLARE @compositeVersion as rowversion
DECLARE @tblDiscretes table
(
   RowNo int IDENTITY(1,1),
   ListId int,
   RowVersion binary(8)
)

SET NOCOUNT ON

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=P''
SET @tranName = object_name(@@procid) + CAST(@@nestlevel as nvarchar(2))

-- Check concurrency of list.  If it has been transmitted then raise error.
SELECT @listName = ListName,
       @accountId = AccountId,
       @compositeId = CompositeId,
       @status = Status
FROM   DisasterCodeList 
WHERE  ListId = @listId AND RowVersion = @rowVersion
IF @@rowCount = 0 BEGIN
   IF EXISTS (SELECT 1 FROM DisasterCodeList WHERE ListId = @listId) BEGIN
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

-- Eligible?
IF @status = 4 BEGIN
   SET @msg = ''A list may not be deleted once it has been transmitted.'' + @msgTag + ''>''
   RAISERROR(@msg,16,1)
   RETURN -100
END
ELSE IF @status = 512 BEGIN
   SET @msg = ''A list may not be deleted once it has been processed.'' + @msgTag + ''>''
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
   FROM   DisasterCodeList 
   WHERE  CompositeId = @listId
   SELECT @rowCount = @@rowCount, @i = 1
   WHILE @i <= @rowCount BEGIN
      -- Get the next discrete
      SELECT @listId = ListId, 
             @rowVersion = RowVersion 
      FROM   @tblDiscretes 
      WHERE  RowNo = @i
      -- Delete the discrete
      EXECUTE @returnValue = disasterCodeList$del @listId, @rowVersion
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
   IF @compositeId IS NOT NULL BEGIN
      SELECT @compositeVersion = RowVersion
      FROM   DisasterCodeList
      WHERE  ListId = @compositeId
      EXECUTE @returnValue = disasterCodeList$extract @listId, @rowVersion, @compositeId, @compositeVersion
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
DELETE DisasterCodeList
WHERE  ListId = @listId
SET @error = @@error
IF @error != 0 BEGIN
   ROLLBACK TRANSACTION @tranName
   COMMIT TRANSACTION
   SET @msg = ''Error encountered while deleting disaster code list.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
   EXECUTE error$raise @msg, @error
   RETURN -100
END

-- Commit and return
COMMIT TRANSACTION
RETURN 0
END
'
)

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'disasterCodeList$dissolve')
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
FROM   DisasterCodeList 
WHERE  ListId = @listId AND RowVersion = @listVersion
IF @@rowCount = 0 BEGIN
   IF EXISTS (SELECT 1 FROM DisasterCodeList WHERE ListId = @listId) BEGIN
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

-- Eligible?
IF @status = 4 BEGIN
   SET @msg = ''A list may not be extracted once it has been transmitted.'' + @msgTag + ''>''
   RAISERROR(@msg,16,1)
   RETURN -100
END
ELSE IF @status = 512 BEGIN
   SET @msg = ''A list may not be extracted once it has been processed.'' + @msgTag + ''>''
   RAISERROR(@msg,16,1)
   RETURN -100
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

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'disasterCodeList$extract')
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
FROM   DisasterCodeList 
WHERE  ListId = @compositeId AND RowVersion = @compositeVersion
IF @@rowCount = 0 BEGIN
   IF EXISTS (SELECT 1 FROM DisasterCodeList WHERE ListId = @compositeId) BEGIN
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

-- Eligible?
IF @status = 4 BEGIN
   SET @msg = ''A list may not be extracted once it has been transmitted.'' + @msgTag + ''>''
   RAISERROR(@msg,16,1)
   RETURN -100
END
ELSE IF @status = 512 BEGIN
   SET @msg = ''A list may not be extracted once it has been processed.'' + @msgTag + ''>''
   RAISERROR(@msg,16,1)
   RETURN -100
END

-- Check concurrency of discrete, and verify that it actually belongs to the composite
SELECT @listName = ListName,
       @cid = isnull(CompositeId,0),
       @status = Status
FROM   DisasterCodeList 
WHERE  ListId = @listId AND RowVersion = @listVersion
IF @@rowCount = 0 BEGIN
   IF EXISTS (SELECT 1 FROM DisasterCodeList WHERE ListId = @listId) BEGIN
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

-- Eligible?
IF @status = 4 BEGIN
   SET @msg = ''A list may not be extracted once it has been transmitted.'' + @msgTag + ''>''
   RAISERROR(@msg,16,1)
   RETURN -100
END
ELSE IF @status = 512 BEGIN
   SET @msg = ''A list may not be extracted once it has been processed.'' + @msgTag + ''>''
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

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'disasterCodeList$getCleared')
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
WHERE  dl.Status = 512 AND
       dl.AccountId IS NULL AND
       EXISTS(SELECT 1 
              FROM   DisasterCodeList dl2
              WHERE  CompositeId = dl.ListId AND
                     convert(nchar(10),dl2.CreateDate,120) <= @dateString)
ORDER BY ListName Asc

END
'
)

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'disasterCodeList$merge')
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
FROM   DisasterCodeList
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
FROM   DisasterCodeList 
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

-- Make sure that neither list has yet been transmitted
IF @status1 = 4 BEGIN
   SET @msg = ''List '''''' + @listName1 + '''''' may not be merged because it has already been transmitted.'' + @msgTag + ''>''
   RAISERROR(@msg,16,1)
   RETURN -100
END
ELSE IF @status1 = 512 BEGIN
   SET @msg = ''List '''''' + @listName1 + '''''' may not be merged because it has been processed.'' + @msgTag + ''>''
   RAISERROR(@msg,16,1)
   RETURN -100
END
ELSE IF @status2 = 4 BEGIN
   SET @msg = ''List '''''' + @listName2 + '''''' may not be merged because it has already been transmitted.'' + @msgTag + ''>''
   RAISERROR(@msg,16,1)
   RETURN -100
END
ELSE IF @status2 = 512 BEGIN
   SET @msg = ''List '''''' + @listName2 + '''''' may not be merged because it has been processed.'' + @msgTag + ''>''
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

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'disasterCodeList$setStatus')
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
DECLARE @returnValue as int
DECLARE @compositeId as int
DECLARE @rowCount as int
DECLARE @status as int
DECLARE @error as int

SET NOCOUNT ON

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=P''
SET @tranName = object_name(@@procid) + CAST(@@nestlevel as nvarchar(2))

-- Get the minimum status for the list.
SELECT @status = min(Status)
FROM   DisasterCodeListItem
WHERE  ListId = @listId AND Status != 1

-- If no active items on list, return (no composites can use this function)
IF @status IS NULL RETURN 0

-- Begin the transaction
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

-- Update the disaster code list
UPDATE DisasterCodeList
SET    Status = @status
WHERE  ListId = @listId AND RowVersion = @rowVersion
SELECT @error = @@error, @rowCount = @@rowCount
IF @rowCount = 0 BEGIN
   IF EXISTS (SELECT 1 FROM DisasterCodeList WHERE ListId = @listId) BEGIN
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
   SET @msg = ''Error encountered while updating disaster code list status.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
   EXECUTE error$raise @msg, @error
   RETURN -100
END

-- Clear the list if necessary.  Note that if the list is part of a composite, 
-- then we have to check the list items for the all the discrete lists within the composite.
IF dbo.bit$statusEligible(4,@status,512) = 1 BEGIN
   SELECT @compositeId = CompositeId,
          @rowVersion = RowVersion 
   FROM   DisasterCodeList   
   WHERE  ListId = @listId
   IF @compositeId IS NULL BEGIN
      EXECUTE @returnValue = disasterCodeList$clear @listId, @rowVersion
      IF @returnValue != 0 BEGIN
         ROLLBACK TRANSACTION @tranName
         COMMIT TRANSACTION
         RETURN -100
      END
   END
   ELSE BEGIN
      SELECT @status = min(dli.Status)
      FROM   DisasterCodeListItem dli
      JOIN   DisasterCodeList dl
        ON   dl.ListId = dli.ListId
      WHERE  dli.Status != 1 AND
             dl.CompositeId = @compositeId
      IF dbo.bit$statusEligible(4,@status,512) = 1 BEGIN
         SELECT @listId = ListId, 
                @rowVersion = RowVersion 
         FROM   DisasterCodeList   
         WHERE  ListId = @compositeId
         IF @@rowCount != 0 BEGIN
            EXECUTE @returnValue = disasterCodeList$clear @listId, @rowVersion
            IF @returnValue != 0 BEGIN
               ROLLBACK TRANSACTION @tranName
               COMMIT TRANSACTION
               RETURN -100
            END
         END
      END
   END
END

COMMIT TRANSACTION
RETURN 0
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

IF EXISTS (SELECT 1 FROM ReceiveList WHERE CompositeId = @listId) BEGIN
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

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'disasterCodeListItem$add')
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

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'disasterCodeListItem$remove')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.disasterCodeListItem$remove
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
DECLARE @returnValue as int
DECLARE @lastItem as int
DECLARE @rowCount as int
DECLARE @error as int
DECLARE @status as int
DECLARE @caseId as int

SET NOCOUNT ON

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=P''
SET @tranName = object_name(@@procid) + CAST(@@nestlevel as nvarchar(2))

-- Verify the status of the item as submitted
SELECT @status = Status
FROM   DisasterCodeListItem
WHERE  ItemId = @itemId AND
       RowVersion = @rowVersion
IF @@rowCount = 0 BEGIN
   IF EXISTS(SELECT 1 FROM DisasterCodeListItem WHERE ItemId = @itemId) BEGIN
      SET @msg = ''Disaster code list item has been modified since retrieval.'' + @msgTag + ''>''
      RAISERROR(@msg,16,1)
      RETURN -100
   END
   ELSE BEGIN
      SET @msg = ''Disaster code list item not found.'' + @msgTag + ''>''
      RAISERROR(@msg,16,1)
      RETURN -100
   END
END

-- If already removed, just return
IF @status = 1 RETURN 0

-- If past transmitted, cannot actively remove the item
IF @status = 4 BEGIN
   SET @msg = ''Items cannot be removed once it has been transmitted.'' + @msgTag + ''>''
   RAISERROR(@msg,16,1)
   RETURN -1
END
ELSE IF @status = 512 BEGIN
   SET @msg = ''Items cannot be removed from a processed list.'' + @msgTag + ''>''
   RAISERROR(@msg,16,1)
   RETURN -1
END

-- Begin the transaction
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

-- Update the status of the disaster code list item to removed
UPDATE DisasterCodeListItem
SET    Status = 1
WHERE  ItemId = @itemId
SELECT @error = @@error
IF @error != 0 BEGIN
   ROLLBACK TRANSACTION @tranName
   COMMIT TRANSACTION
   SET @msg = ''Error encountered while removing item from disaster code list.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
   EXECUTE error$raise @msg, @error
   RETURN -100
END

-- Commit transaction
COMMIT TRANSACTION
RETURN 0
END
'
)

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'disasterCodeListItem$upd')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.disasterCodeListItem$upd
(
   @itemId int,
   @code nvarchar(32),
   @notes nvarchar(1000),
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

SET NOCOUNT ON

-- Tweak parameters
SET @code = ltrim(rtrim(@code))
SET @notes = ltrim(rtrim(@notes))

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=P''
SET @tranName = object_name(@@procid) + CAST(@@nestlevel as nvarchar(2))

-- If the list is not submitted, raise error.  
SELECT @status = dl.Status 
FROM   DisasterCodeList dl
JOIN   DisasterCodeListItem dli
  ON   dli.ListId = dl.ListId
WHERE  dl.Status != 2 AND dli.ItemId = @itemId
IF @@rowcount > 0 BEGIN
   SET @msg = ''Changes may not be made to a disaster code list after it has been '' + dbo.string$statusName(4,@status) + ''.'' + @msgTag + ''>''
   RAISERROR(@msg,16,1)
   RETURN -100
END

-- Update return date and description.
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

-- Update the item if something has changed
UPDATE DisasterCodeListItem
SET    Code = @code, 
       Notes = @notes
WHERE  ItemId = @itemId AND 
       RowVersion = @rowVersion
SELECT @error = @@error, @rowCount = @@rowCount
IF @error != 0 BEGIN
   ROLLBACK TRANSACTION @tranName
   COMMIT TRANSACTION
   SET @msg = ''Error encountered while updating disaster code list item.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
   EXECUTE error$raise @msg, @error
   RETURN -100
END
ELSE IF @rowCount = 0 BEGIN
   IF EXISTS(SELECT 1 FROM DisasterCodeListItem WHERE ItemId = @itemId) BEGIN
      ROLLBACK TRANSACTION @tranName
      COMMIT TRANSACTION
      SET @msg = ''List item has been modified since retrieval.'' + @msgTag + ''>''
      RAISERROR(@msg,16,1)
      RETURN -100
   END
   ELSE BEGIN
      ROLLBACK TRANSACTION @tranName
      COMMIT TRANSACTION
      SET @msg = ''Disaster code list item not found.'' + @msgTag + ''>''
      RAISERROR(@msg,16,1)
      RETURN -100
   END
END

-- Commit and return
COMMIT TRANSACTION
RETURN 0
END
'
)

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'disasterCodeListItemCase$add')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.disasterCodeListItemCase$add
(
   @caseId int,            -- medium serial number
   @code nvarchar(32),     -- disaster code
   @notes nvarchar(1000),  -- any notes to attach to the medium
   @listId int             -- list to which item should be added
)
WITH ENCRYPTION
AS
BEGIN
DECLARE @msg as nvarchar(255)      -- used to preformat error message
DECLARE @msgTag as nvarchar(255)    -- used to hold first part of error message header
DECLARE @tranName as nvarchar(255)   -- used to hold name of savepoint
DECLARE @error as int
DECLARE @priorId as int
DECLARE @accountId as int
DECLARE @listName as nchar(10)
DECLARE @priorList as int
DECLARE @priorStatus as int
DECLARE @returnValue as int
DECLARE @priorVersion as rowversion
DECLARE @serialNo as nvarchar(32)
DECLARE @caseName as nvarchar(32)

SET NOCOUNT ON

-- Tweak parameters
SET @notes = coalesce(ltrim(rtrim(@notes)),'''')
SET @code = ltrim(rtrim(@code))

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=P''
SET @tranName = object_name(@@procid) + CAST(@@nestlevel as nvarchar(2))

-- Get the case name
SELECT @caseName = SerialNo
FROM   SealedCase
WHERE  CaseId = @caseId

-- Begin transaction
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

-- Check other lists for the presence of this case
SELECT @priorId = dli.ItemId,
       @priorStatus = dli.Status,
       @priorVersion = dli.RowVersion,
       @serialNo = sc.SerialNo
FROM   DisasterCodeListItemCase dlic
JOIN   DisasterCodeListItem dli
  ON   dli.ItemId = dlic.ItemId
JOIN   SealedCase sc
  ON   sc.CaseId = dlic.CaseId
WHERE  dli.Status IN (2,4) AND dlic.CaseId = @caseId
IF @@rowCount > 0 BEGIN
   IF @priorStatus = 4 BEGIN
      ROLLBACK TRANSACTION @tranName
      COMMIT TRANSACTION
      SET @msg = ''Case '''''' + @serialNo + '''''' currently resides on another active disaster code list that has been transmitted.'' + @msgTag + ''>''
      RAISERROR(@msg,16,1)
      RETURN -100
   END
   ELSE BEGIN
      -- If the prior list is this list or any of the lists under this list
      -- (if it is a composite) then rollback and return.  Otherwise, remove
      -- the medium from the prior list.
      IF @priorId = @listId OR EXISTS(SELECT 1 FROM DisasterCodeList WHERE ListId = @priorId AND CompositeId = @listId) BEGIN
         ROLLBACK TRANSACTION @tranName
         COMMIT TRANSACTION
         RETURN 0
      END
      ELSE BEGIN
         EXECUTE @returnValue = disasterCodeListItem$remove @priorId, @priorVersion
         IF @returnValue != 0 BEGIN
            ROLLBACK TRANSACTION @tranName
            COMMIT TRANSACTION
            RETURN -100
         END
      END
   END
END
-- If the case has been removed from this list, restore it
ELSE BEGIN
   SELECT @priorId = dli.ItemId,
          @priorList = dl.ListId
   FROM   DisasterCodeListItemCase dlic
   JOIN   DisasterCodeListItem dli
     ON   dli.ItemId = dlic.ItemId
   JOIN   DisasterCodeList dl
     ON   dl.ListId = dli.ListId
   WHERE  dli.Status = 1 AND
          dlic.CaseId = @caseId AND
         (dl.ListId = @listId OR coalesce(dl.CompositeId,0) = @listId)
   IF @@rowCount > 0 BEGIN
      UPDATE DisasterCodeListItem
      SET    Status = 2,
             Code = @code,
             Notes = @notes
      WHERE  ItemId = @priorId
      SET @error = @@error
      IF @error != 0 BEGIN
         ROLLBACK TRANSACTION @tranName
         COMMIT TRANSACTION
         SET @msg = ''Error encountered while restoring item to disaster code list.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
         EXECUTE error$raise @msg, @error
         RETURN -100
      END
      ELSE BEGIN
         COMMIT TRANSACTION
         RETURN 0
      END
   END
END

-- If the list is a composite, get the first discrete on the list with the same
-- account as one of the media in the case.  Otherwise, make sure that the list
-- has the same account as at least one of the media within the case.
SELECT @listName = ListName,
       @accountId = AccountId
FROM   DisasterCodeList
WHERE  ListId = @listId
IF @accountId IS NULL BEGIN
   -- Find any media on the list that do not belong to any accounts within the composite
   SELECT TOP 1 @serialNo = m.SerialNo
   FROM   Medium m
   JOIN   MediumSealedCase msc
     ON   msc.MediumId = m.MediumId
   LEFT   OUTER JOIN DisasterCodeList dl
     ON   dl.AccountId = m.AccountId
   WHERE  dl.CompositeId = @listId AND msc.CaseId = @caseId AND dl.AccountId IS NULL
   IF @@rowcount != 0 BEGIN
      ROLLBACK TRANSACTION @tranName
      COMMIT TRANSACTION
      SET @msg = ''No list within the composite list '' + @listName + '' has same account as medium '' + @serialNo + '' in sealed case '' + @caseName + ''.'' + @msgTag + ''>''
      EXECUTE error$raise @msg, 0
      RETURN -100
   END
END
ELSE BEGIN
   SELECT TOP 1 @serialNo = m.SerialNo
   FROM   Medium m
   JOIN   MediumSealedCase msc
     ON   msc.MediumId = m.MediumId
   JOIN   DisasterCodeList dl
     ON   dl.AccountId = m.AccountId
   WHERE  dl.ListId = @listId AND
          msc.CaseId = @caseId AND
          m.AccountId != dl.AccountId
   IF @@rowcount != 0 BEGIN
      ROLLBACK TRANSACTION @tranName
      COMMIT TRANSACTION
      SET @msg = ''Medium '' + @serialNo + '' in sealed case '' + @caseName + '' does not have the same account as list '' + @listName + ''.'' + @msgTag + ''>''
      EXECUTE error$raise @msg, 0
      RETURN -100
   END
END 

-- Insert the item
INSERT DisasterCodeListItem
(
   ListId, 
   Code,
   Notes
)
VALUES
(
   @listId, 
   @code,
   @notes
)
SET @error = @@error
IF @error != 0 BEGIN
   ROLLBACK TRANSACTION @tranName
   COMMIT TRANSACTION
   SET @msg = ''Error encountered while adding item to existing disaster code list.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
   EXECUTE error$raise @msg, @error
   RETURN -100
END

INSERT DisasterCodeListItemCase
(
   ItemId, 
   CaseId
)
VALUES
(
   scope_identity(), 
   @caseId
)
SET @error = @@error
IF @error != 0 BEGIN
   ROLLBACK TRANSACTION @tranName
   COMMIT TRANSACTION
   SET @msg = ''Error encountered while adding item to existing disaster code list.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
   EXECUTE error$raise @msg, @error
   RETURN -100
END

-- Commit the transaction
COMMIT TRANSACTION
RETURN 0
END
'
)

IF EXISTS(SELECT * FROM sysobjects WHERE name = 'disasterCodeListItemCase$afterInsert' AND objectproperty(id, 'ExecIsInsertTrigger' ) = 1) 
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'TRIGGER disasterCodeListItemCase$afterInsert
ON     DisasterCodeListItemCase
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

-- Verify that the list to which the item was inserted has not yet been transmitted.
SELECT @listId = dli.ListId,
       @listName = dl.ListName,
       @listStatus  = dl.Status
FROM   DisasterCodeList dl
JOIN   DisasterCodeListItem dli
  ON   dli.ListId = dli.ListId
WHERE  dli.ItemId = (SELECT ItemId FROM Inserted)
IF @listStatus >= 4 BEGIN
   SET @msg = ''Items cannot be added to a list that has already been '' + dbo.string$statusName(4,@listStatus) + ''.'' + @msgTag + ''>''
   EXECUTE error$raise @msg, 0, @tranName
   RETURN
END

-- Select the case serial number from the Inserted table
SELECT @serialNo = SerialNo 
FROM   SealedCase 
WHERE  CaseId = (SELECT CaseId FROM Inserted)

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
   ''Case '''''' + @serialNo + '''''' added to list'',
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

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'disasterCodeListItemCase$ins')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.disasterCodeListItemCase$ins
(
   @caseId int,            -- case id number
   @code nvarchar(32),     -- disaster code
   @notes nvarchar(1000),  -- any notes to attach to the medium
   @batchLists nvarchar(4000),
   @newList nvarchar(10) output
)
WITH ENCRYPTION
AS
BEGIN
DECLARE @msg as nvarchar(255)      -- used to preformat error message
DECLARE @msgTag as nvarchar(255)    -- used to hold first part of error message header
DECLARE @tranName as nvarchar(255)   -- used to hold name of savepoint
DECLARE @error as int
DECLARE @priorId as int
DECLARE @priorList as int
DECLARE @priorStatus as int
DECLARE @returnValue as int
DECLARE @priorVersion as rowversion
DECLARE @serialNo as nvarchar(32)
DECLARE @itemStatus as int
DECLARE @accountId as int
DECLARE @listId as int
DECLARE @itemId as int

SET NOCOUNT ON

-- Tweak parameters
SET @notes = coalesce(ltrim(rtrim(@notes)),'''')
SET @code = ltrim(rtrim(@code))

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=P''
SET @tranName = object_name(@@procid) + CAST(@@nestlevel as nvarchar(2))

-- Begin transaction
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

-- Verify that the case does not actively reside on another list.  If 
-- it does, then we can remove it from the prior list only if it has not 
-- yet been transmitted.
SELECT @priorId = dli.ItemId,
       @priorStatus = dli.Status,
       @priorVersion = dli.RowVersion
FROM   DisasterCodeListItemCase dlic
JOIN   DisasterCodeListItem dli
  ON   dli.ItemId = dlic.ItemId
JOIN   DisasterCodeList dl
  ON   dl.ListId = dli.ListId
WHERE  dli.Status IN (2,4) AND
       dlic.CaseId = @caseId AND
       charindex(dl.ListName,@batchLists) = 0
IF @@rowCount > 0 BEGIN
   IF @priorStatus = 4 BEGIN
      ROLLBACK TRANSACTION @tranName
      COMMIT TRANSACTION
      SET @msg = ''Case '''''' + @serialNo + '''''' currently resides on another active disaster code list.'' + @msgTag + ''>''
      RAISERROR(@msg,16,1)
      RETURN -100
   END
   ELSE BEGIN
      EXECUTE @returnValue = disasterCodeListItem$remove @priorId, @priorVersion
      IF @returnValue != 0 BEGIN
         ROLLBACK TRANSACTION @tranName
         COMMIT TRANSACTION
         RETURN -100
      END
   END
END

-- If we already produced one list in this batch, see if there is a list for an
-- account of one of the media in the case.
IF len(@batchLists) > 0 BEGIN
   -- See if the case already lies within the batch.  If so, restore
   -- if removed.  Return.  Otherwise, look for a list with the same
   -- account as a medium in the case.
   SELECT @itemId = dli.ItemId,
          @itemStatus = dli.Status
   FROM   DisasterCodeList dl
   JOIN   DisasterCodeListItem dli
     ON   dli.ListId = dl.ListId
   JOIN   DisasterCodeListItemCase dlic
     ON   dlic.ItemId = dli.ItemId
   WHERE  dlic.CaseId = @caseId AND
         (dl.ListId = @listId OR dl.CompositeId = @listId)
   IF @@rowCount > 0 BEGIN
      IF @itemStatus = 1 BEGIN
         UPDATE DisasterCodeListItem
         SET    Status = 2, 
                Code = @code
         WHERE  ItemId = @itemId
      END
      COMMIT TRANSACTION
      RETURN 0
   END
   ELSE BEGIN
      SELECT TOP 1 @listId = dl.ListId
      FROM   DisasterCodeList dl
      JOIN   Account a
        ON   a.AccountId = dl.AccountId
      JOIN   Medium m
        ON   m.AccountId = a.AccountId
      JOIN   MediumSealedCase msc
        ON   msc.MediumId = m.MediumId
      WHERE  msc.CaseId = @caseId AND
             charindex(dl.ListName,@batchLists) > 0
   END
END      

-- If we have no list, create one
IF @listId IS NULL BEGIN
   SELECT TOP 1 @accountId = m.AccountId
   FROM   Medium m
   JOIN   MediumSealedCase msc
     ON   msc.MediumId = m.MediumId
   WHERE  msc.CaseId = @caseId
   IF @@rowCount = 0 BEGIN
      ROLLBACK TRANSACTION @tranName
      COMMIT TRANSACTION
      SET @msg = ''No media found within sealed case.'' + @msgTag + ''>''
      RAISERROR(@msg,16,1)
      RETURN -100
   END
   ELSE BEGIN  
      EXECUTE @returnValue = disasterCodeList$create @accountId, @newList OUTPUT
      IF @returnValue != 0 BEGIN
         ROLLBACK TRANSACTION @tranName
         COMMIT TRANSACTION
         RETURN -100
      END
      ELSE BEGIN
         SELECT @listId = ListId
         FROM   DisasterCodeList
         WHERE  ListName = @newList
      END
   END 
END

-- Insert the item
INSERT DisasterCodeListItem
(
   ListId, 
   Code,
   Notes
)
VALUES
(
   @listId, 
   @code,
   @notes
)
SET @error = @@error
IF @error != 0 BEGIN
   ROLLBACK TRANSACTION @tranName
   COMMIT TRANSACTION
   SET @msg = ''Error encountered while adding item to existing disaster code list.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
   EXECUTE error$raise @msg, @error
   RETURN -100
END

INSERT DisasterCodeListItemCase
(
   ItemId, 
   CaseId
)
VALUES
(
   scope_identity(), 
   @caseId
)
SET @error = @@error
IF @error != 0 BEGIN
   ROLLBACK TRANSACTION @tranName
   COMMIT TRANSACTION
   SET @msg = ''Error encountered while adding item to existing disaster code list.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
   EXECUTE error$raise @msg, @error
   RETURN -100
END

-- Commit the transaction
COMMIT TRANSACTION
RETURN 0
END
'
)

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'disasterCodeList$getByDate')
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
FROM   DisasterCodeList dl
JOIN   Account a
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
FROM   DisasterCodeList dl
WHERE  AccountId IS NULL AND
       EXISTS(SELECT 1 
              FROM   DisasterCodeList dl2
              WHERE  CompositeId = dl.ListId AND
                     convert(nchar(10),dl2.CreateDate,120) = @dateString)
ORDER BY ListName Desc

END
'
)

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'receiveList$getByDate')
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
FROM   ReceiveList rl
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
FROM   ReceiveList rl
WHERE  AccountId IS NULL AND
       EXISTS(SELECT 1 
              FROM   ReceiveList rl2
              WHERE  CompositeId = rl.ListId AND
                     convert(nchar(10),rl2.CreateDate,120) = @dateString)
ORDER BY ListName Desc

END
'
)

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'sendList$getByDate')
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
FROM   SendList sl
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
FROM   SendList sl
WHERE  sl.AccountId IS NULL AND
       EXISTS(SELECT 1 
              FROM   SendList sl2
              WHERE  CompositeId = sl.ListId AND
                     convert(nchar(10),sl2.CreateDate,120) = @dateString)
ORDER BY ListName Desc
END
'
)

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'disasterCodeListItemMedium$add')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.disasterCodeListItemMedium$add
(
   @mediumId int,               -- medium id
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
DECLARE @error as int
DECLARE @location as bit
DECLARE @priorId as int
DECLARE @listStatus as int
DECLARE @accountL as int
DECLARE @accountM as int
DECLARE @serialNo as nvarchar(32)
DECLARE @listName as nchar(10)
DECLARE @returnValue as int
DECLARE @priorList as int
DECLARE @priorStatus as int
DECLARE @priorVersion as rowversion

SET NOCOUNT ON

-- Tweak parameters
SET @notes = coalesce(ltrim(rtrim(@notes)),'''')
SET @serialNo = ltrim(rtrim(@serialNo))
SET @code = ltrim(rtrim(@code))

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=P''
SET @tranName = object_name(@@procid) + CAST(@@nestlevel as nvarchar(2))

-- Get the medium
SELECT @serialNo = m.SerialNo,
       @location = m.Location,
       @accountM = m.AccountId
FROM   Medium m
WHERE  m.MediumId = @mediumId

-- Location check
IF @location = 1 BEGIN
   SET @msg = ''Medium '''''' + @serialNo + '''''' resides at the enterprise.'' + @msgTag + ''>''
   RAISERROR(@msg,16,1)
   RETURN -100
END

-- Begin transaction
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

-- Check other lists for the presence of this medium.  If it is not on any
-- other lists, check to see if it was removed from this list.  If so,
-- restore it.
SELECT @priorId = dli.ItemId,
       @priorStatus = dli.Status,
       @priorVersion = dli.RowVersion
FROM   DisasterCodeListItem dli
JOIN   DisasterCodeListItemMedium dlim
  ON   dlim.Itemid = dli.ItemId
WHERE  dli.Status IN (2,4) AND dlim.MediumId = @mediumId
IF @@rowCount > 0 BEGIN
   IF @priorStatus = 4 BEGIN
      ROLLBACK TRANSACTION @tranName
      COMMIT TRANSACTION
      SET @msg = ''Medium '''''' + @serialNo + '''''' currently resides on another active disaster code list that has been transmitted.'' + @msgTag + ''>''
      RAISERROR(@msg,16,1)
      RETURN -100
   END
   ELSE BEGIN
      -- If the prior list is this list or any of the lists under this list
      -- (if it is a composite) then rollback and return.  Otherwise, remove
      -- the medium from the prior list.
      IF @priorId = @listId OR EXISTS(SELECT 1 FROM DisasterCodeList WHERE ListId = @priorId AND CompositeId = @listId) BEGIN
         ROLLBACK TRANSACTION @tranName
         COMMIT TRANSACTION
         RETURN 0
      END
      ELSE BEGIN
         EXECUTE @returnValue = disasterCodeListItem$remove @priorId, @priorVersion
         IF @returnValue != 0 BEGIN
            ROLLBACK TRANSACTION @tranName
            COMMIT TRANSACTION
            RETURN -100
         END
      END
   END
END
ELSE BEGIN 
   SELECT @priorId = dli.ItemId,
          @priorList = dl.ListId
   FROM   DisasterCodeListItemMedium dlim
   JOIN   DisasterCodeListItem dli
     ON   dli.ItemId = dlim.ItemId
   JOIN   DisasterCodeList dl
     ON   dl.ListId = dli.ListId
   WHERE  dli.Status = 1 AND
          dlim.MediumId = @mediumId AND
         (dl.ListId = @listId OR coalesce(dl.CompositeId,0) = @listId)
   IF @@rowCount > 0 BEGIN
      UPDATE DisasterCodeListItem
      SET    Status = 2,
             Code = @code,
             Notes = @notes
      WHERE  ItemId = @priorId
      SET @error = @@error
      IF @error != 0 BEGIN
         ROLLBACK TRANSACTION @tranName
         COMMIT TRANSACTION
         SET @msg = ''Error encountered while restoring item to disaster code list.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
         EXECUTE error$raise @msg, @error
         RETURN -100
      END
      ELSE BEGIN
         COMMIT TRANSACTION
         RETURN 0
      END
   END
END

-- If the list is a composite, verify that there is a list within the composite
-- that has the same account as the medium.  If the list is discrete, verify
-- that it has the same account as the medium.
SELECT @listName = ListName,
       @accountL = AccountId
FROM   DisasterCodeList
WHERE  ListId = @listId
-- SELECT @listAccount = AccountId
-- FROM   DisasterCodeList
-- WHERE  ListId = @listId AND 
--        AccountId IS NOT NULL
IF @accountL IS NULL BEGIN
   SELECT @listId = ListId
   FROM   DisasterCodeList
   WHERE  CompositeId = @listId AND AccountId = @accountM
   IF @@rowcount = 0 BEGIN
      ROLLBACK TRANSACTION @tranName
      COMMIT TRANSACTION
      SET @msg = ''No list within the composite list '' + @listName + '' has the same account as medium '' + @serialNo + ''.'' + @msgTag + ''>''
      RAISERROR(@msg,16,1)
      RETURN -100
   END
END
ELSE IF @accountL != @accountM BEGIN
   ROLLBACK TRANSACTION @tranName
   COMMIT TRANSACTION
   SET @msg = ''List does not have the same account as medium '''''' + @serialNo + ''''''.'' + @msgTag + ''>''
   RAISERROR(@msg,16,1)
   RETURN -100
END

-- Insert he item
INSERT DisasterCodeListItem
(
   ListId, 
   Code,
   Notes
)
VALUES
(
   @listId, 
   @code,
   @notes
)
SET @error = @@error
IF @error != 0 BEGIN
   ROLLBACK TRANSACTION @tranName
   COMMIT TRANSACTION
   SET @msg = ''Error encountered while adding item to existing disaster code list.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
   EXECUTE error$raise @msg, @error
   RETURN -100
END

INSERT DisasterCodeListItemMedium
(
   ItemId, 
   MediumId
)
VALUES
(
   scope_identity(), 
   @mediumId
)
SET @error = @@error
IF @error != 0 BEGIN
   ROLLBACK TRANSACTION @tranName
   COMMIT TRANSACTION
   SET @msg = ''Error encountered while adding item to existing disaster code list.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
   EXECUTE error$raise @msg, @error
   RETURN -100
END

-- Commit the transaction
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
  ON   dli.ListId = dli.ListId
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

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'disasterCodeListItemMedium$ins')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.disasterCodeListItemMedium$ins
(
   @mediumId int,          -- medium id number
   @code nvarchar(32),     -- disaster code
   @notes nvarchar(1000),  -- any notes to attach to the medium
   @batchLists nvarchar(4000),
   @newList nvarchar(10) output
)
WITH ENCRYPTION
AS
BEGIN
DECLARE @msg as nvarchar(255)      -- used to preformat error message
DECLARE @msgTag as nvarchar(255)    -- used to hold first part of error message header
DECLARE @tranName as nvarchar(255)   -- used to hold name of savepoint
DECLARE @error as int
DECLARE @priorId as int
DECLARE @priorList as int
DECLARE @priorStatus as int
DECLARE @returnValue as int
DECLARE @priorVersion as rowversion
DECLARE @serialNo as nvarchar(32)
DECLARE @accountId as int
DECLARE @location as bit
DECLARE @listId as int
DECLARE @itemId as int
DECLARE @itemStatus as int

SET NOCOUNT ON

-- Tweak parameters
SET @notes = coalesce(ltrim(rtrim(@notes)),'''')
SET @code = ltrim(rtrim(@code))

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=P''
SET @tranName = object_name(@@procid) + CAST(@@nestlevel as nvarchar(2))

-- Get the serial number of the medium
SELECT @serialNo = SerialNo,
       @location = Location,
       @accountId = AccountId
FROM   Medium
WHERE  MediumId = @mediumId

-- Location check
IF @location = 1 BEGIN
   SET @msg = ''Medium '''''' + @serialNo + '''''' resides at the enterprise.'' + @msgTag + ''>''
   RAISERROR(@msg,16,1)
   RETURN -100
END

-- Begin transaction
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

-- Verify that the medium does not actively reside on another list.  If 
-- it does, then we can remove it from the prior list only if it has not 
-- yet been transmitted.
SELECT @priorId = dli.ItemId,
       @priorStatus = dli.Status,
       @priorVersion = dli.RowVersion
FROM   DisasterCodeListItemMedium dlim
JOIN   DisasterCodeListItem dli
  ON   dli.ItemId = dlim.ItemId
JOIN   DisasterCodeList dl
  ON   dl.ListId = dli.ListId
WHERE  dli.Status IN (2,4) AND
       dlim.MediumId = @mediumId AND
       charindex(dl.ListName,@batchLists) = 0
IF @@rowCount > 0 BEGIN
   IF @priorStatus = 4 BEGIN
      ROLLBACK TRANSACTION @tranName
      COMMIT TRANSACTION
      SET @msg = ''Medium '''''' + @serialNo + '''''' currently resides on another active disaster code list.'' + @msgTag + ''>''
      RAISERROR(@msg,16,1)
      RETURN -100
   END
   ELSE BEGIN
      EXECUTE @returnValue = disasterCodeListItem$remove @priorId, @priorVersion
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
IF len(@batchLists) > 0 BEGIN
   -- See if the medium already lies within the batch.  If so, restore
   -- if removed.  Return.  Otherwise, look for a list with the same
   -- account as a medium in the case.
   SELECT @itemId = dli.ItemId,
          @itemStatus = dli.Status
   FROM   DisasterCodeList dl
   JOIN   DisasterCodeListItem dli
     ON   dli.ListId = dl.ListId
   JOIN   DisasterCodeListItemMedium dlim
     ON   dlim.ItemId = dli.ItemId
   WHERE  dlim.MediumId = @mediumId AND
         (dl.ListId = @listId OR dl.CompositeId = @listId)
   IF @@rowCount > 0 BEGIN
      IF @itemStatus = 1 BEGIN
         UPDATE DisasterCodeListItem
         SET    Status = 2, 
                Code = @code
         WHERE  ItemId = @itemId
      END
      COMMIT TRANSACTION
      RETURN 0
   END
   ELSE BEGIN
      SELECT @listId = dl.ListId
      FROM   DisasterCodeList dl
      WHERE  dl.AccountId = @accountId AND
             charindex(dl.ListName,@batchLists) > 0
   END
END      

-- If we have no list, create one
IF @listId IS NULL BEGIN
   EXECUTE @returnValue = disasterCodeList$create @accountId, @newList OUTPUT
   IF @returnValue != 0 BEGIN
      ROLLBACK TRANSACTION @tranName
      COMMIT TRANSACTION
      RETURN -100
   END
   ELSE BEGIN
      SELECT @listId = ListId
      FROM   DisasterCodeList
      WHERE  ListName = @newList
   END
END

-- Add the item
INSERT DisasterCodeListItem
(
   ListId, 
   Code,
   Notes
)
VALUES
(
   @listId, 
   @code,
   @notes
)
SET @error = @@error
IF @error != 0 BEGIN
   ROLLBACK TRANSACTION @tranName
   COMMIT TRANSACTION
   SET @msg = ''Error encountered while inserting a disaster code list item.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
   EXECUTE error$raise @msg, @error
   RETURN -100
END

INSERT DisasterCodeListItemMedium
(
   ItemId, 
   MediumId
)
VALUES
(
   scope_identity(), 
   @mediumId
)
SET @error = @@error
IF @error != 0 BEGIN
   ROLLBACK TRANSACTION @tranName
   COMMIT TRANSACTION
   SET @msg = ''Error encountered while inserting a disaster code list item.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
   EXECUTE error$raise @msg, @error
   RETURN -100
END

-- Commit the transaction
COMMIT TRANSACTION
RETURN 0
END
'
)

IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'lists$purgeCleared')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.lists$purgeCleared
(
   @listType int,
   @cleanDate datetime
)
WITH ENCRYPTION
AS
BEGIN

SET NOCOUNT ON

SET @cleanDate = cast(convert(nchar(10), @cleanDate, 120) as datetime)

-- Send lists
IF @listType & 1 = 1 BEGIN
   DELETE SendList
   WHERE  Status = 512 AND CreateDate < @cleanDate
END

-- Receive lists
IF @listType & 2 = 2 BEGIN
   DELETE ReceiveList
   WHERE  Status = 512 AND CreateDate < @cleanDate
END

-- Disaster code lists
IF @listType & 4 = 4 BEGIN
   DELETE DisasterCodeList
   WHERE  Status = 8 AND CreateDate < @cleanDate
END

END
'
)

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'receiveList$arrive')
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

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'receiveList$clear')
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
                LastMoveDate = cast(convert(nchar(19),getdate(),120) as datetime)
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
FROM   Medium m
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

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'receiveList$del')
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
DECLARE @compositeVersion as rowversion
DECLARE @tblDiscretes table
(
   RowNo int IDENTITY(1,1),
   ListId int,
   RowVersion binary(8)
)

SET NOCOUNT ON

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=P''
SET @tranName = object_name(@@procid) + CAST(@@nestlevel as nvarchar(2))

-- Check concurrency of list.  If it has been transmitted then raise error.
SELECT @listName = ListName,
       @accountId = AccountId,
       @compositeId = CompositeId,
       @status = Status
FROM   ReceiveList 
WHERE  ListId = @listId AND RowVersion = @rowVersion
IF @@rowCount = 0 BEGIN
   IF EXISTS (SELECT 1 FROM ReceiveList WHERE ListId = @listId) BEGIN
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

-- Check eligibility
IF @chkOverride != 1 BEGIN
   IF @status >= 4 AND EXISTS (SELECT 1 FROM ListStatusProfile WHERE ProfileId = 2 AND Statuses & 4 != 0) BEGIN
      SET @msg = ''A list may not be deleted after it has been transmitted.'' + @msgTag + ''>''
      RAISERROR(@msg,16,1)
      RETURN -100
   END
   ELSE IF @status >= 16 BEGIN
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
   IF @compositeId IS NOT NULL BEGIN
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

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'receiveList$dissolve')
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
FROM   ReceiveList 
WHERE  ListId = @listId AND RowVersion = @listVersion
IF @@rowCount = 0 BEGIN
   IF EXISTS (SELECT 1 FROM ReceiveList WHERE ListId = @listId) BEGIN
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

-- Eligible?
IF @status >= 4 AND EXISTS (SELECT 1 FROM ListStatusProfile WHERE ProfileId = 2 AND Statuses & 4 != 0) BEGIN
   SET @msg = ''A list may not be extracted after it has been transmitted.'' + @msgTag + ''>''
   RAISERROR(@msg,16,1)
   RETURN -100
END
ELSE IF @status >= 16 BEGIN
   SET @msg = ''A list may not be extracted once it has attained '' + dbo.string$statusName(2,16) + '' status.'' + @msgTag + ''>''
   RAISERROR(@msg,16,1)
   RETURN -100
END

-- Check for a case that exists on more than one list within the composite.
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

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'receiveList$extract')
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
FROM   ReceiveList 
WHERE  ListId = @compositeId AND RowVersion = @compositeVersion
IF @@rowCount = 0 BEGIN
   IF NOT EXISTS (SELECT 1 FROM ReceiveList WHERE ListId = @compositeId) BEGIN
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

-- Eligible?
IF @status >= 4 AND EXISTS (SELECT 1 FROM ListStatusProfile WHERE ProfileId = 2 AND Statuses & 4 != 0) BEGIN
   SET @msg = ''A list may not be extracted after it has been transmitted.'' + @msgTag + ''>''
   RAISERROR(@msg,16,1)
   RETURN -100
END
ELSE IF @status >= 16 BEGIN
   SET @msg = ''A list may not be extracted once it has attained '' + dbo.string$statusName(2,16) + '' status.'' + @msgTag + ''>''
   RAISERROR(@msg,16,1)
   RETURN -100
END

-- Check concurrency of discrete, and verify that it actually belongs to the given composite
SELECT @listName = ListName
FROM   ReceiveList 
WHERE  ListId = @listId AND RowVersion = @listVersion
IF @@rowCount = 0 BEGIN
   IF NOT EXISTS (SELECT 1 FROM ReceiveList WHERE ListId = @listId) BEGIN
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

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'receiveList$getByItem')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.receiveList$getByItem
(
   @itemId int
)
WITH ENCRYPTION
AS
BEGIN
DECLARE @compositeId int

SET NOCOUNT ON

SELECT @compositeId = rl.CompositeId
FROM   ReceiveList rl
JOIN   ReceiveListItem rli
  ON   rli.ListId = rl.ListId
WHERE  rli.ItemId = @itemId AND 
       rl.CompositeId IS NOT NULL

IF @@rowcount = 0 BEGIN
   SELECT rl.ListId,
          rl.ListName,
          rl.CreateDate,
          rl.Status,
          a.AccountName,
          rl.RowVersion
   FROM   ReceiveList rl
   JOIN   ReceiveListItem rli
     ON   rli.ListId = rl.ListId
   JOIN   Account a
     ON   a.AccountId = rl.AccountId
   WHERE  rli.ItemId = @itemId
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
   -- Get the kids
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
'
)

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'receiveList$getCleared')
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
WHERE  rl.Status = 512 AND
       rl.AccountId IS NULL AND
       EXISTS(SELECT 1 
              FROM   ReceiveList rl2
              WHERE  CompositeId = rl.ListId AND
                     convert(nchar(10),rl2.CreateDate,120) <= @dateString)
ORDER BY ListName Asc

END
'
)

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'receiveList$merge')
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
FROM   ReceiveList
WHERE  ListId = @listId1 AND RowVersion = @rowVersion1
IF @@rowCount = 0 BEGIN
   IF EXISTS (SELECT 1 FROM ReceiveList WHERE ListId = @listId1) BEGIN
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
FROM   ReceiveList 
WHERE  ListId = @listId2 AND RowVersion = @rowVersion2
IF @@rowCount = 0 BEGIN
   IF EXISTS (SELECT 1 FROM ReceiveList WHERE ListId = @listId2) BEGIN
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

-- Both eligible?
IF @status1 >= 4 AND EXISTS (SELECT 1 FROM ListStatusProfile WHERE ProfileId = 2 AND Statuses & 4 != 0) BEGIN
   SET @msg = ''A list may not be merged after it has been transmitted.'' + @msgTag + ''>''
   RAISERROR(@msg,16,1)
   RETURN -100
END
ELSE IF @status1 >= 16 BEGIN
   SET @msg = ''A list may not be merged once it has attained '' + dbo.string$statusName(2,16) + '' status.'' + @msgTag + ''>''
   RAISERROR(@msg,16,1)
   RETURN -100
END
ELSE IF @status2 >= 4 AND EXISTS (SELECT 1 FROM ListStatusProfile WHERE ProfileId = 2 AND Statuses & 4 != 0) BEGIN
   SET @msg = ''A list may not be merged after it has been transmitted.'' + @msgTag + ''>''
   RAISERROR(@msg,16,1)
   RETURN -100
END
ELSE IF @status2 >= 16 BEGIN
   SET @msg = ''A list may not be merged once it has attained '' + dbo.string$statusName(2,16) + '' status.'' + @msgTag + ''>''
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

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'receiveList$setStatus')
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
DECLARE @returnValue as int
DECLARE @compositeId as int
DECLARE @rowCount as int
DECLARE @status as int
DECLARE @error as int

SET NOCOUNT ON

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=P''
SET @tranName = object_name(@@procid) + CAST(@@nestlevel as nvarchar(2))

-- Get the minimum status for the list.
SELECT @status = min(Status)
FROM   ReceiveListItem
WHERE  ListId = @listId AND Status != 1

-- If no active items on list, return (no composites can use this function)
IF @status IS NULL RETURN 0

-- If some items have been  verified and others haven''t, set the status to partial verification.
IF @status != 16 AND EXISTS (SELECT 1 FROM ReceiveListItem WHERE ListId = @listId AND Status = 16)
   SET @status = 8
ELSE IF @status != 256 AND EXISTS (SELECT 1 FROM ReceiveListItem WHERE ListId = @listId AND Status = 256)
   SET @status = 128

-- Begin the transaction
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

-- Update the receive list
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

-- If the clear-eligible, clear it.  Note that if the list is
-- part of a composite, then we have to check the list items for the
-- all the discrete lists within the composite.
IF dbo.bit$statusEligible(2,@status,512) = 1 BEGIN
   SELECT @compositeId = CompositeId,
          @rowVersion = RowVersion 
   FROM   ReceiveList   
   WHERE  ListId = @listId
   IF @compositeId IS NULL BEGIN
      EXECUTE @returnValue = receiveList$clear @listId, @rowVersion
      IF @returnValue != 0 BEGIN
         ROLLBACK TRANSACTION @tranName
         COMMIT TRANSACTION
         RETURN -100
      END
   END
   ELSE BEGIN
      SELECT @status = min(rli.Status)
      FROM   ReceiveListItem rli
      JOIN   ReceiveList rl
        ON   rl.ListId = rli.ListId
      WHERE  rli.Status != 1 AND
             rl.CompositeId = @compositeId
      IF dbo.bit$statusEligible(2,@status,512) = 1 BEGIN
         SELECT @listId = ListId, 
                @rowVersion = RowVersion 
         FROM   ReceiveList   
         WHERE  ListId = @compositeId
         IF @@rowCount != 0 BEGIN
            EXECUTE @returnValue = receiveList$clear @listId, @rowVersion
            IF @returnValue != 0 BEGIN
               ROLLBACK TRANSACTION @tranName
               COMMIT TRANSACTION
               RETURN -100
            END
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

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'receiveList$transit')
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
   SET @msg = ''List '' + @listName + '' is not eligible to be marked as in trannsit.'' + @msgTag + ''>''
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

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'receiveList$transmit')
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
FROM   ReceiveList
WHERE  ListId = @listId AND RowVersion = @rowVersion
IF @@rowCount = 0 BEGIN
   IF EXISTS(SELECT 1 FROM ReceiveList WHERE ListId = @listId) BEGIN
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

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'receiveListItem$add')
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
   FROM   ReceiveListItem rli
   JOIN   Inserted i
     ON   i.MediumId = rli.MediumId
   WHERE  rli.Status > 1 AND rli.Status != 512
   GROUP  BY i.MediumId
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
   ''Medium '' + @serialNo + '' added to receive list'',
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
DECLARE @lastList int
DECLARE @serialNo nvarchar(32)
DECLARE @rowVersion rowversion
DECLARE @returnDate datetime
DECLARE @returnValue int
DECLARE @auditAction int
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
   FROM   ReceiveListItem rli
   JOIN   Inserted i
     ON   i.MediumId = rli.MediumId
   WHERE  rli.Status > 1 AND rli.Status != 512
   GROUP  BY i.MediumId
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

-- For each list in the update where an item was updated to a status other 
-- than removed, make sure that the discrete list status is equal to 
-- the (translated) lowest status among its non-removed items.
SET @lastList = 0
WHILE 1 = 1 BEGIN
   SELECT TOP 1 @lastList = i.ListId,
          @rowVersion = rl.RowVersion
   FROM   Inserted i
   JOIN   Deleted d
     ON   d.ItemId = i.ItemId
   JOIN   ReceiveList rl
     ON   rl.ListId = i.ListId
   WHERE  i.Status != 1 AND
          d.Status != i.Status AND
          i.ListId > @lastList
   ORDER BY i.ListId ASC
   IF @@rowCount = 0
      BREAK
   ELSE BEGIN
      EXECUTE @returnValue = receiveList$setStatus @lastList, @rowVersion
      IF @returnValue != 0 BEGIN
         ROLLBACK TRANSACTION @tranName
         COMMIT TRANSACTION
         RETURN
      END
   END
END

-- For each list in the update where an item was updated to removed status, 
-- delete the list if there are no more items on the list.  Update the 
-- list status to change the rowversion.
SET @lastList = 0
WHILE 1 = 1 BEGIN
   SELECT TOP 1 @lastList = i.ListId,
          @rowVersion = rl.RowVersion
   FROM   Inserted i
   JOIN   Deleted d
     ON   d.ItemId = i.ItemId
   JOIN   ReceiveList rl
     ON   rl.ListId = i.ListId
   WHERE  i.Status = 1 AND
          d.Status != 1 AND
          i.ListId > @lastList
   ORDER BY i.ListId ASC
   IF @@rowCount = 0
      BREAK
   ELSE BEGIN
      IF EXISTS(SELECT 1 FROM ReceiveListItem WHERE ListId = @lastList AND Status != 1) BEGIN
         EXECUTE @returnValue = receiveList$setStatus @lastList, @rowVersion
      END
      ELSE BEGIN
         EXECUTE @returnValue = receiveList$del @lastList, @rowVersion, 1   -- Allow deletion even if transmitted
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

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'receiveListItem$ins')
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

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'receiveListItem$remove')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.receiveListItem$remove
(
   @itemId int,
   @rowVersion rowversion,
   @caseOthers bit = 0,
   @disregardStatus bit = 0
)
WITH ENCRYPTION
AS
BEGIN
DECLARE @msg as nvarchar(255)        -- used to preformat error message
DECLARE @msgTag as nvarchar(255)     -- used to hold first part of error message header
DECLARE @tranName as nvarchar(255)   -- used to hold name of savepoint
DECLARE @returnValue as int
DECLARE @mediumId as int
DECLARE @rowCount as int
DECLARE @error as int
DECLARE @status as int
DECLARE @caseId as int

SET NOCOUNT ON

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=P''
SET @tranName = object_name(@@procid) + CAST(@@nestlevel as nvarchar(2))

-- Verify the status of the item as submitted or transmitted
SELECT @status = Status,
       @mediumId = MediumId
FROM   ReceiveListItem
WHERE  ItemId = @itemId AND RowVersion = @rowVersion
IF @@rowCount = 0 BEGIN
   IF EXISTS(SELECT 1 FROM ReceiveListItem WHERE ItemId = @itemId) BEGIN
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

-- If already removed, just return
IF @status = 1 RETURN 0

-- If past transmitted, cannot actively remove the item
IF @disregardStatus = 0 BEGIN
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
END

-- Begin the transaction
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

-- Remove the item from the case if it was in one
SELECT @caseId = msc.CaseId
FROM   MediumSealedCase msc
JOIN   ReceiveListItem rli
  ON   rli.MediumId = msc.MediumId
WHERE  rli.ItemId = @itemId
IF @@rowCount != 0 BEGIN
   EXECUTE @returnValue = mediumSealedCase$del @caseId, @mediumId
	IF @returnValue != 0 BEGIN
      ROLLBACK TRANSACTION @tranName
      COMMIT TRANSACTION
      RETURN -100
   END   
END

-- Update the status of the receive list item to removed
UPDATE ReceiveListItem
SET    Status = 1
WHERE  ItemId = @itemId
SELECT @error = @@error
IF @error != 0 BEGIN
   ROLLBACK TRANSACTION @tranName
   COMMIT TRANSACTION
   SET @msg = ''Error encountered while removing item from receive list.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
   EXECUTE error$raise @msg, @error
   RETURN -100
END

-- If the item is in a sealed case and we''re instructed to remove all the other
-- tapes from that case, then do so.
IF @caseOthers = 1 AND @caseId IS NOT NULL BEGIN
   SET @itemId = 0
   WHILE 1 = 1 BEGIN
      SELECT TOP 1 @itemId = rli.ItemId,
             @rowVersion = rli.RowVersion
      FROM   ReceiveListItem rli
      JOIN   MediumSealedCase msc
        ON   msc.MediumId = rli.MediumId
      WHERE  msc.CaseId = @caseId AND 
             rli.ItemId > @itemId AND
             rli.MediumId != @mediumId
      ORDER BY rli.ItemId asc
      IF @@rowCount = 0
         BREAK
      ELSE BEGIN
         EXECUTE @returnValue = receiveListItem$remove @itemId, @rowVersion, 0
         IF @returnValue != 0 BEGIN
            ROLLBACK TRANSACTION @tranName
            COMMIT TRANSACTION
            RETURN -100
         END
      END
   END
END

-- Commit transaction
COMMIT TRANSACTION
RETURN 0
END
'
)

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
DECLARE @status int
DECLARE @value int
DECLARE @error int
DECLARE @id int

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=P''
SET @tranName = object_name(@@procid) + CAST(@@nestlevel as nvarchar(2))

-- If the status of the item is already verified, then return.  Otherwise,
-- if it is anything besides transmitted, raise error.
SELECT @id = ListId, @status = Status
FROM   ReceiveListItem 
WHERE  ItemId = @itemId AND RowVersion = @rowVersion
IF @@rowCount = 0 BEGIN
   IF EXISTS(SELECT 1 FROM ReceiveListItem WHERE ItemId = @itemId) BEGIN
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

-- If the item belongs to a composite list, get the status of the composite
IF EXISTS (SELECT 1 FROM ReceiveList WHERE ListId = @id AND CompositeId IS NOT NULL) BEGIN
   SELECT @id = ListId, @status = Status
   FROM   ReceiveList
   WHERE  ListId = (SELECT CompositeId FROM ReceiveList WHERE ListId = @id)
END

-- Check eligibility
IF dbo.bit$statusEligible(2,@status,16) = 1
   SET @value = 16
ELSE IF dbo.bit$statusEligible(2,@status,256) = 1
   SET @value = 256
ELSE IF @status = 16 OR @status = 256
   RETURN 0
ELSE BEGIN
   SET @msg = ''List is not currently verification-eligible.'' + @msgTag + ''>''
   RAISERROR(@msg,16,1)
   RETURN -100
END

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

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'receiveListScan$compare')
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
SET    Compared = cast(convert(nchar(19),getdate(),120) as datetime)
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

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'receiveListScan$getByList')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.receiveListScan$getByList
(
   @listName nchar(10),
   @stage int
)
WITH ENCRYPTION
AS
BEGIN

SET NOCOUNT ON

-- Select the scan
SELECT r.ScanId,
       r.ScanName,
       r.CreateDate,
       rl.ListName,
       coalesce(convert(nvarchar(19),r.Compared,120),'''') as ''Compared''
FROM   ReceiveListScan r
JOIN   ReceiveList rl
  ON   r.ListId = rl.ListId
WHERE  rl.ListName = @listName AND Stage = @stage

END
'
)

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'receiveListScan$ins')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.receiveListScan$ins
(
   @listName nchar(10),
   @scanName nvarchar(128),
   @newId int OUTPUT
)
WITH ENCRYPTION
AS
BEGIN
DECLARE @msg as nvarchar(255)        -- used to preformat error message
DECLARE @msgTag as nvarchar(255)     -- used to hold first part of error message header
DECLARE @tranName as nvarchar(255)   -- used to hold name of savepoint
DECLARE @status int
DECLARE @listId int
DECLARE @stage int
DECLARE @returnValue int
DECLARE @error as int

SET NOCOUNT ON

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=P''
SET @tranName = object_name(@@procid) + CAST(@@nestlevel as nvarchar(2))

-- Tweak parameters
SET @scanName = ltrim(rtrim(coalesce(@scanName,'''')))

-- Verify that the list exists and has not yet been fully verified
SELECT @listId = ListId,
       @status = Status
FROM   ReceiveList
WHERE  ListName = @listName
IF @@rowCount = 0 BEGIN
   SET @msg = ''List not found.'' + @msgTag + ''>''
   RAISERROR(@msg,16,1)
   RETURN -100
END

-- If there is a composite, get it
IF EXISTS (SELECT 1 FROM ReceiveList WHERE ListId = @listId AND CompositeId IS NOT NULL) BEGIN
   SELECT @listId = ListId,
          @status = Status,
          @listName = ListName
   FROM   ReceiveList
   WHERE  ListId = (SELECT CompositeId FROM ReceiveList WHERE ListId = @listId)          
END

-- Eligible?
IF dbo.bit$statusEligible(2, @status, 16) = 1
   SET @stage = 1
ELSE IF dbo.bit$statusEligible(2, @status, 256) = 1
   SET @stage = 2
ELSE BEGIN
   IF @status = 16 OR @status = 256 BEGIN
      SET @msg = ''Scan may not be created; list '' + @listName + '' has already been fully verified.'' + @msgTag + ''>''
      RAISERROR(@msg,16,1)
      RETURN -100
   END
   ELSE BEGIN
      SET @msg = ''List is not currently verification-eligible.'' + @msgTag + ''>''
      RAISERROR(@msg,16,1)
      RETURN -100
   END
END

-- Begin the transaction
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

-- Insert the record
INSERT ReceiveListScan(ScanName, ListId, Stage)
VALUES(@scanName, @listId, @stage)
SET @error = @@error
IF @error != 0 BEGIN
   ROLLBACK TRANSACTION @tranName
   COMMIT TRANSACTION
   SET @msg = ''Error encountered while creating a new receive list scan.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
   EXECUTE error$raise @msg, @error
   RETURN -100
END

-- Commit and return
SET @newId = scope_identity()
COMMIT TRANSACTION
RETURN 0
END
'
)

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'receiveListScanItem$ins')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.receiveListScanItem$ins
(
   @scanId int,                     -- unique id number of the scan
   @serialNo nvarchar(32)           -- serial number of the medium
)
WITH ENCRYPTION
AS
BEGIN
DECLARE @msg as nvarchar(255)        -- used to preformat error message
DECLARE @msgTag as nvarchar(255)     -- used to hold first part of error message header
DECLARE @tranName as nvarchar(255)   -- used to hold name of savepoint
DECLARE @listName nchar(10)
DECLARE @status int
DECLARE @returnValue int
DECLARE @error as int

SET NOCOUNT ON

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=P''
SET @tranName = object_name(@@procid) + CAST(@@nestlevel as nvarchar(2))

-- Cannot be altered if compared
IF EXISTS 
   (
   SELECT 1 
   FROM   ReceiveListScan
   WHERE  ScanId = @scanId AND Compared IS NOT NULL
   ) 
BEGIN
   SET @msg = ''Cannot alter a compare file after it has been compared against its list.'' + @msgTag + ''>''
   RAISERROR(@msg,16,1)
   RETURN -100
END

-- Tweak parameters
SET @serialNo = ltrim(rtrim(coalesce(@serialNo,'''')))

-- If the scan has been compared against, it may not take on new items
IF EXISTS(SELECT 1 FROM ReceiveListScan WHERE ScanId = @scanId AND Compared IS NOT NULL) BEGIN
   SET @msg = ''Scan has already been used in a comparison.'' + @msgTag + ''>''
   RAISERROR(@msg,16,1)
   RETURN -100
END

-- Test that list is verification-eligible
SELECT @status = rl.Status,
       @listName = rl.ListName 
FROM   ReceiveList rl
JOIN   ReceiveListScan rls
  ON   rls.ListId = rl.ListId
WHERE  rls.ScanId = @scanId

-- Eligible?
IF @status = 256 BEGIN
   SET @msg = ''Items may not be added to this compare file because list '' + @listName + '' has already been fully verified.'' + @msgTag + ''>''
   RAISERROR(@msg,16,1)
   RETURN -100
END
ELSE IF dbo.bit$statusEligible(2,@status,16) = 0 AND dbo.bit$statusEligible(2,@status,256) = 0 BEGIN
   IF @status = 16 BEGIN -- verified (I)
      SET @msg = ''Items may not be added to this compare file because list '' + @listName + '' has already been fully verified.'' + @msgTag + ''>''
      RAISERROR(@msg,16,1)
      RETURN -100
   END
   ELSE BEGIN
      SET @msg = ''Items may not be added to this compare file because list '' + @listName + '' is not currently verification-eligible.'' + @msgTag + ''>''
      RAISERROR(@msg,16,1)
      RETURN -100
   END
END

-- Begin the transaction
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

-- Insert the scan list item
INSERT ReceiveListScanItem
(
   ScanId,
   SerialNo
)
VALUES
(
   @scanId,
   @serialNo
)
SET @error = @@error
IF @error != 0 BEGIN
   ROLLBACK TRANSACTION @tranName
   COMMIT TRANSACTION
   SET @msg = ''Error encountered inserting receive list scan item.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
   EXECUTE error$raise @msg, @error
   RETURN -100
END

-- Commit the transaction
COMMIT TRANSACTION
RETURN 0
END
'
)

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'sealedCase$getVerified')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.sealedCase$getVerified
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
FROM   Medium m 
JOIN   Account a 
  ON   a.AccountId = m.AccountId 
JOIN   MediumType t 
  ON   t.TypeId = m.TypeId
JOIN   MediumSealedCase msc
  ON   msc.MediumId = m.MediumId
JOIN   SealedCase sc
  ON   msc.CaseId = sc.CaseId
JOIN   ReceiveListItem rli
  ON   rli.MediumId = m.MediumId
WHERE  rli.Status >= 16 AND 
       sc.SerialNo = @caseName
ORDER BY m.SerialNo ASC

END
'
)

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'sendList$arrive')
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
FROM   SendList
WHERE  ListId = @listId AND RowVersion = @rowVersion
IF @@rowCount = 0 BEGIN
   IF EXISTS(SELECT 1 FROM SendList WHERE ListId = @listId) BEGIN
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

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'sendList$clear')
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
                LastMoveDate = cast(convert(nchar(19),getdate(),120) as datetime)
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

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'sendList$del')
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
DECLARE @compositeVersion as rowversion
DECLARE @tblDiscretes table
(
   RowNo int IDENTITY(1,1),
   ListId int,
   RowVersion binary(8)
)

SET NOCOUNT ON

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=P''
SET @tranName = object_name(@@procid) + CAST(@@nestlevel as nvarchar(2))

-- Check concurrency of list.  If it has been transmitted then raise error.
SELECT @listName = ListName,
       @accountId = AccountId,
       @compositeId = CompositeId,
       @status = Status
FROM   SendList 
WHERE  ListId = @listId
IF @@rowCount = 0 BEGIN
   SET @msg = ''Send list not found.'' + @msgTag + ''>''
   RAISERROR(@msg,16,1)
   RETURN -100
END
ELSE IF @status >= 16 BEGIN
   SET @msg = ''A list may not be deleted after it has attained at least '' + dbo.string$statusName(2,16) + '' status..'' + @msgTag + ''>''
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
   SET @msg = ''Send list '''''' + @listName + '''''' has been modified since retrieval.'' + @msgTag + ''>''
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
   -- If the list is part of a composite, extract it first before deleting.  
   IF @compositeId IS NOT NULL BEGIN
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

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'sendList$dissolve')
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
FROM   SendList 
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
ELSE IF @status >= 16 BEGIN
   SET @msg = ''A list that has reached at least '' + dbo.string$statusName(1,16) + '' status may not be dissolved.'' + @msgTag + ''>''
   RAISERROR(@msg,16,1)
   RETURN -100
END
ELSE IF NOT EXISTS
   (
   SELECT 1
   FROM   SendList
   WHERE  ListId = @listId AND RowVersion = @listVersion
   )
BEGIN
   SET @msg = ''Send list '''''' + @listName + '''''' has been modified since retrieval.'' + @msgTag + ''>''
   RAISERROR(@msg,16,1)
   RETURN -100
END

-- Check for a case that exists on more than one list within the composite.
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

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'sendList$extract')
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
FROM   SendList 
WHERE  ListId = @compositeId
IF @@rowCount = 0 BEGIN
   SET @msg = ''Send list not found.'' + @msgTag + ''>''
   RAISERROR(@msg,16,1)
   RETURN -100
END
ELSE IF NOT EXISTS
   (
   SELECT 1
   FROM   SendList
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
   FROM   SendList
   WHERE  ListId = @compositeId AND AccountId IS NOT NULL
   )
BEGIN
   SET @msg = ''Send list '''''' + @compositeName + '''''' is not a composite list.'' + @msgTag + ''>''
   RAISERROR(@msg,16,1)
   RETURN -100
END
ELSE IF @status >= 16 BEGIN
   SET @msg = ''A list may not be extracted after it has attained at least '' + dbo.string$statusName(1,16) + '' status..'' + @msgTag + ''>''
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
   FROM   SendList
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
   FROM   SendList
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

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'sendList$getByItem')
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
FROM   SendList sl
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
   FROM   SendList sl
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
   FROM   SendList sl
   WHERE  sl.ListId = @compositeId
   -- Get the kids
   SELECT sl.ListId,
          sl.ListName,
          sl.CreateDate,
          sl.Status,
          a.AccountName,
          sl.RowVersion
   FROM   SendList sl
   JOIN   Account a
     ON   a.AccountId = sl.AccountId
   WHERE  sl.CompositeId = @compositeId
   ORDER BY sl.ListName ASC
END

END
'
)

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'sendList$getCleared')
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

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'sendList$merge')
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
FROM   SendList 
WHERE  ListId = @listId1
IF @@rowCount = 0 BEGIN
   SET @msg = ''Send list not found.'' + @msgTag + ''>''
   RAISERROR(@msg,16,1)
   RETURN -100
END
ELSE IF NOT EXISTS
   (
   SELECT 1
   FROM   SendList
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
   FROM   SendList
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
FROM   SendList 
WHERE  ListId = @listId2
IF @@rowCount = 0 BEGIN
   SET @msg = ''Send list not found.'' + @msgTag + ''>''
   RAISERROR(@msg,16,1)
   RETURN -100
END
ELSE IF NOT EXISTS
   (
   SELECT 1
   FROM   SendList
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
   FROM   SendList
   WHERE  ListId = @listId2 AND CompositeId IS NOT NULL
   )
BEGIN
   SET @msg = ''List '''''' + @listName2 + '''''' must first be extracted from its current composite.'' + @msgTag + ''>''
   RAISERROR(@msg,16,1)
   RETURN -100
END

-- Make sure that neither list has yet been transmitted
IF EXISTS
   (
   SELECT 1 
   FROM   SendList 
   WHERE  ListId IN (@listId1,@listId2) AND Status >= 16
   )
BEGIN
   SET @msg = ''Lists that have reached at least '' + dbo.string$statusName(1,16) + '' status may not be merged.'' + @msgTag + ''>''
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

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'sendList$setStatus')
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
DECLARE @returnValue as int
DECLARE @compositeId as int
DECLARE @rowCount as int
DECLARE @status as int
DECLARE @error as int

SET NOCOUNT ON

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=P''
SET @tranName = object_name(@@procid) + CAST(@@nestlevel as nvarchar(2))

-- Get the minimum status for the list.
SELECT @status = min(Status)
FROM   SendListItem
WHERE  ListId = @listId AND Status != 1

-- If no status exists, return.  Otherwise, if some items have been 
-- verified and others haven''t, set the status to partial verification.
IF @status IS NULL BEGIN
   RETURN 0
END
ELSE IF EXISTS (SELECT 1 FROM SendListItem WHERE ListId = @listId AND Status = 8) BEGIN
   IF EXISTS (SELECT 1 FROM SendListItem WHERE ListId = @listId AND Status NOT IN (1,8)) BEGIN
      SELECT @status = 4
   END
END
ELSE IF EXISTS (SELECT 1 FROM SendListItem WHERE ListId = @listId AND Status = 256) BEGIN
   IF EXISTS (SELECT 1 FROM SendListItem WHERE ListId = @listId AND Status NOT IN (1,256)) BEGIN
      SELECT @status = 128
   END
END

-- Begin the transaction
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

-- Update the send list
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

-- If the list is fully verified, clear it.  Note that if the list is
-- part of a composite, then we have to check the list items for the
-- all the discrete lists within the composite.
IF dbo.bit$statusEligible(1,@status,512) = 1 BEGIN
   SELECT @compositeId = CompositeId,
          @rowVersion = RowVersion 
   FROM   SendList   
   WHERE  ListId = @listId
   IF @compositeId IS NULL BEGIN
      EXECUTE @returnValue = sendList$clear @listId, @rowVersion
      IF @returnValue != 0 BEGIN
         ROLLBACK TRANSACTION @tranName
         COMMIT TRANSACTION
         RETURN -100
      END
   END
   ELSE BEGIN
      SELECT @status = min(sli.Status)
      FROM   SendListItem sli
      JOIN   SendList sl
        ON   sl.ListId = sli.ListId
      WHERE  sli.Status != 1 AND
             sl.CompositeId = @compositeId
      IF dbo.bit$statusEligible(1,@status,512) = 1 BEGIN
         SELECT @listId = ListId, 
                @rowVersion = RowVersion 
         FROM   SendList   
         WHERE  ListId = @compositeId
         IF @@rowCount != 0 BEGIN
            EXECUTE @returnValue = sendList$clear @listId, @rowVersion
            IF @returnValue != 0 BEGIN
               ROLLBACK TRANSACTION @tranName
               COMMIT TRANSACTION
               RETURN -100
            END
         END
      END
   END
END

COMMIT TRANSACTION
RETURN 0
END
'
)

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'sendList$transit')
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
FROM   SendList
WHERE  ListId = @listId AND RowVersion = @rowVersion
IF @@rowCount = 0 BEGIN
   IF EXISTS(SELECT 1 FROM SendList WHERE ListId = @listId) BEGIN
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

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'sendList$transmit')
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
FROM   SendList
WHERE  ListId = @listId AND
       RowVersion = @rowVersion
IF @@rowCount = 0 BEGIN
   IF EXISTS(SELECT 1 FROM SendList WHERE ListId = @listId) BEGIN
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

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'sendListCase$del')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.sendListCase$del
(
   @caseId int,
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

SET NOCOUNT ON

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=P''
SET @tranName = object_name(@@procid) + CAST(@@nestlevel as nvarchar(2))

-- Verify that the case does not appear on any lists that 
-- have been at least transmitted
IF EXISTS
   (
   SELECT 1
   FROM   SendListCase slc
   JOIN   SendListItemCase slic
     ON   slic.CaseId = slc.CaseId
   JOIN   SendListItem sli
     ON   sli.ItemId = slic.ItemId
   WHERE  slc.CaseId = @caseId AND sli.Status >= 16
   )
BEGIN
   SET @msg = ''Items may not be removed from a case on an active shipping list once that shipping list has reached '' + dbo.string$statusName(1,16) + '' status.'' + @msgTag + ''>''
   RAISERROR(@msg,16,1)
   RETURN -100
END

-- Perform delete
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

DELETE SendListCase
WHERE  CaseId = @caseId AND
       RowVersion = @rowVersion
SELECT @error = @@error, @rowCount = @@rowCount
IF @error != 0 BEGIN
   ROLLBACK TRANSACTION @tranName
   COMMIT TRANSACTION
   SET @msg = ''Error encountered while deleting send list case.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
   EXECUTE error$raise @msg, @error
   RETURN -100
END
ELSE IF @rowCount = 0 BEGIN
   IF EXISTS(SELECT 1 FROM SendListCase WHERE CaseId = @caseId) BEGIN
      ROLLBACK TRANSACTION @tranName
      COMMIT TRANSACTION
      SET @msg = ''Case has been modified since retrieval.'' + @msgTag + ''>''
      RAISERROR(@msg,16,1)
      RETURN -100
   END
END

-- Commit and return
COMMIT TRANSACTION
RETURN 0
END
'
)

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'sendListCase$upd')
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

-- If the case is to be unsealed, set the return date to null.  Otherwise,
-- verify that the given return date is later than today.
IF @sealed = 0 
   SET @returnDate = NULL
ELSE IF @returnDate IS NOT NULL BEGIN
   IF @returnDate <= getdate() BEGIN
      SET @msg = ''Return date must be later than today.'' + @msgTag + ''>''
      RAISERROR(@msg,16,1)
      RETURN -100
   END
END
   
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

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'sendListItem$add')
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

-- The initial status must be either submitted or verified
IF @initialStatus NOT IN (2,8) BEGIN
   SET @msg = ''Invalid initial status value.'' + @msgTag + ''>''
   RAISERROR(@msg,16,1)
   RETURN -100
END

-- If a return date is specified, verify that it is later than today
IF coalesce(@returnDate,''2999-01-01'') <= getdate() BEGIN
   SET @msg = ''Return date must be later than current date.'' + @msgTag + ''>''
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

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'sendListItem$ins')
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

-- If a return date is specified, verify that it is later than today
IF coalesce(@returnDate,''2999-01-01'') <= getdate() BEGIN
   SET @msg = ''Return date must be later than current date.'' + @msgTag + ''>''
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

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'sendListItem$remove')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.sendListItem$remove
(
   @itemId int,
   @rowVersion rowversion,
   @disregardStatus bit = 0
)
WITH ENCRYPTION
AS
BEGIN
DECLARE @msg as nvarchar(255)        -- used to preformat error message
DECLARE @msgTag as nvarchar(255)     -- used to hold first part of error message header
DECLARE @tranName as nvarchar(255)   -- used to hold name of savepoint
DECLARE @returnValue as int
DECLARE @rowCount as int
DECLARE @error as int
DECLARE @status as int
DECLARE @caseId as int

SET NOCOUNT ON

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=P''
SET @tranName = object_name(@@procid) + CAST(@@nestlevel as nvarchar(2))

-- Verify that the item has not yet been transmitted
SELECT @status = Status
FROM   SendListItem
WHERE  ItemId = @itemId AND
       RowVersion = @rowVersion
IF @@rowCount = 0 BEGIN
   IF EXISTS(SELECT 1 FROM SendListItem WHERE ItemId = @itemId) BEGIN
      SET @msg = ''Send list item has been modified since retrieval.'' + @msgTag + ''>''
      RAISERROR(@msg,16,1)
      RETURN -100
   END
   ELSE BEGIN
      SET @msg = ''Send list item not found.'' + @msgTag + ''>''
      RAISERROR(@msg,16,1)
      RETURN -100
   END
END
ELSE BEGIN
   IF @status = 1 BEGIN
      RETURN
   END
   ELSE IF @status >= 16 AND @disregardStatus = 0 BEGIN
      SET @msg = ''Medium may not be removed from a list that has attained '' + dbo.string$statusName(1,16) + '' status.'' + @msgTag + ''>''
      RAISERROR(@msg,16,1)
      RETURN -100
   END
END

-- Begin the transaction
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

-- Remove item from case
SELECT @caseId = CaseId
FROM   SendListItemCase
WHERE  ItemId = @itemId
IF @@rowCount > 0 BEGIN
   EXECUTE @returnValue = sendListItemCase$remove @itemId, @caseId
   IF @returnValue != 0 BEGIN
      ROLLBACK TRANSACTION @tranName
      COMMIT TRANSACTION
      RETURN -100
   END
END

-- Update the status of the send list item to removed
UPDATE SendListItem
SET    Status = 1
WHERE  ItemId = @itemId
SELECT @error = @@error
IF @error != 0 BEGIN
   ROLLBACK TRANSACTION @tranName
   COMMIT TRANSACTION
   SET @msg = ''Error encountered while removing item from send list.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
   EXECUTE error$raise @msg, @error
   RETURN -100
END

-- Commit
COMMIT TRANSACTION
RETURN 0
END
'
)

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'sendListItem$upd')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.sendListItem$upd
(
   @itemId int,
   @returnDate datetime,
   @notes nvarchar(1000),
   @caseName nvarchar(32),
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
DECLARE @status as int
DECLARE @returnValue int
DECLARE @currentCase nvarchar(32)
DECLARE @serialNo nvarchar(32)
DECLARE @caseId int

SET NOCOUNT ON

-- Tweak parameters
SET @notes = coalesce(ltrim(rtrim(@notes)),'''')
SET @caseName = coalesce(ltrim(rtrim(@caseName)),'''')
SET @returnDate = cast(convert(nchar(10),@returnDate,120) as datetime)

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=P''
SET @tranName = object_name(@@procid) + CAST(@@nestlevel as nvarchar(2))

-- If the item has been verified, raise error
SELECT @serialNo = m.SerialNo, 
       @status = sli.Status
FROM   SendListItem sli
JOIN   Medium m
  ON   m.MediumId = sli.MediumId
WHERE  sli.ItemId = @itemId AND sli.Status NOT IN (2,8)
IF @@rowcount != 0 BEGIN
   SET @msg = ''Items on a list may not be changed once that list has attained or gone beyond '' + dbo.string$statusName(1,16) + '' status.'' + @msgTag + ''>''
   RAISERROR(@msg,16,1)
   RETURN -100
END

-- Update return date and description.
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

-- Handle the case logic.  If the item''s current case is equal to the
-- given case, do nothing.  Otherwise, if the item has a current case,
-- remove it from the case.  If the item is to be placed in a new case,
-- do so here.
SELECT @currentCase = coalesce(c.CaseName,''''),
       @caseId = c.CaseId
FROM   SendListItem sli
LEFT 
OUTER
JOIN   (SELECT slc.SerialNo as ''CaseName'',
               slc.CaseId as ''CaseId'',
               slic.ItemId as ''ItemId''
        FROM   SendListCase slc
        JOIN   SendListItemCase slic
          ON   slic.CaseId = slc.CaseId) as c
  ON    c.ItemId = sli.ItemId
WHERE   sli.ItemId = @itemId
IF @currentCase != @caseName BEGIN
   -- Remove from current case
   IF len(@currentCase) > 0 BEGIN
      EXECUTE @returnValue = sendListItemCase$remove @itemId, @caseId
      IF @returnValue != 0 BEGIN
         ROLLBACK TRANSACTION @tranName
         COMMIT TRANSACTION
         RETURN -100
      END
   END
   -- Insert into new case
   IF len(@caseName) > 0 BEGIN
      EXECUTE @returnValue = sendListItemCase$ins @itemId, @caseName, NULL
      IF @returnValue != 0 BEGIN
         ROLLBACK TRANSACTION @tranName
         COMMIT TRANSACTION
         RETURN -100
      END
   END
END

-- Update the item if something has changed
IF NOT EXISTS
   (
   SELECT 1
   FROM   SendListItem
   WHERE  ItemId = @itemId AND
          ReturnDate = @returnDate
   )
BEGIN
   UPDATE SendListItem
   SET    ReturnDate = @returnDate
   WHERE  ItemId = @itemId AND
          RowVersion = @rowVersion
   SELECT @error = @@error, @rowCount = @@rowCount
   IF @error != 0 BEGIN
      ROLLBACK TRANSACTION @tranName
      COMMIT TRANSACTION
      SET @msg = ''Error encountered while updating send list item.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
      EXECUTE error$raise @msg, @error
      RETURN -100
   END
   ELSE IF @rowCount = 0 BEGIN
      IF EXISTS(SELECT 1 FROM SendListItem WHERE ItemId = @itemId) BEGIN
         ROLLBACK TRANSACTION @tranName
         COMMIT TRANSACTION
         SET @msg = ''Send list item has been modified since retrieval.'' + @msgTag + ''>''
         RAISERROR(@msg,16,1)
         RETURN -100
      END
      ELSE BEGIN
         ROLLBACK TRANSACTION @tranName
         COMMIT TRANSACTION
         SET @msg = ''Send list item not found.'' + @msgTag + ''>''
         RAISERROR(@msg,16,1)
         RETURN -100
      END
   END
END

-- Attach notes to the medium here.  We''ll do this manually rather than go
-- through medium$upd because to do so would involve unnecessary overhead.  Unlike
-- with a receive list, we will allow blank notes to overwrite existing notes.
UPDATE Medium
SET    Notes = @notes
WHERE  Notes != @notes AND
       MediumId = (SELECT m.MediumId FROM Medium m JOIN SendListItem sli ON sli.MediumId = m.MediumId WHERE sli.ItemId = @itemId)
SET @error = @@error
IF @error != 0 BEGIN
   ROLLBACK TRANSACTION @tranName
   COMMIT TRANSACTION
   SET @msg = ''Error encountered while updating medium notes.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
   EXECUTE error$raise @msg, @error
   RETURN -100
END

-- Commit and return
COMMIT TRANSACTION
RETURN 0
END
'
)

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
DECLARE @status int
DECLARE @value int
DECLARE @error int
DECLARE @id int

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=P''
SET @tranName = object_name(@@procid) + CAST(@@nestlevel as nvarchar(2))

-- If the status of the item is already verified, then return.  Otherwise,
-- if it is anything besides submitted, raise error.
SELECT @id = ListId, @status = Status
FROM   SendListItem 
WHERE  ItemId = @itemId AND RowVersion = @rowVersion
IF @@rowCount = 0 BEGIN
   IF EXISTS(SELECT 1 FROM SendListItem WHERE ItemId = @itemId) BEGIN
      SET @msg = ''Send list item has been modified since retrieval.'' + @msgTag + ''>''
      RAISERROR(@msg,16,1)
      RETURN -100
   END
   ELSE BEGIN
      SET @msg = ''Send list item not found.'' + @msgTag + ''>''
      RAISERROR(@msg,16,1)
      RETURN -100
   END
END

-- If the item belongs to a composite list, get the status of the composite
IF EXISTS (SELECT 1 FROM SendList WHERE ListId = @id AND CompositeId IS NOT NULL) BEGIN
   SELECT @id = ListId, @status = Status
   FROM   SendList
   WHERE  ListId = (SELECT CompositeId FROM SendList WHERE ListId = @id)
END

-- Check eligibility
IF dbo.bit$statusEligible(1,@status,8) = 1
   SET @value = 8
ELSE IF dbo.bit$statusEligible(1,@status,256) = 1
   SET @value = 256
ELSE IF @status = 8 OR @status = 256
   RETURN 0
ELSE BEGIN
   SET @msg = ''List is not currently verification-eligible.'' + @msgTag + ''>''
   RAISERROR(@msg,16,1)
   RETURN -100
END

-- Upgrade the status of the item to verified
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

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'sendListItemCase$ins')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.sendListItemCase$ins
(
   @itemId int,
   @caseName nvarchar(32),
   @batchLists nvarchar(4000) = ''''
)
WITH ENCRYPTION
AS
BEGIN
DECLARE @msg as nvarchar(255)        -- used to preformat error message
DECLARE @msgTag as nvarchar(255)     -- used to hold first part of error message header
DECLARE @tranName as nvarchar(255)   -- used to hold name of savepoint
DECLARE @error as int
DECLARE @listName as nchar(10)
DECLARE @listId as int
DECLARE @caseList as nchar(10)
DECLARE @returnValue as int
DECLARE @currentCase as nvarchar(32)
DECLARE @currentId as int
DECLARE @caseId int

SET NOCOUNT ON

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=P''
SET @tranName = object_name(@@procid) + CAST(@@nestlevel as nvarchar(2))

-- If the item is not submitted or verified, raise error.
IF EXISTS
   (
   SELECT 1
   FROM   SendListItem
   WHERE  ItemId = @itemId AND Status >= 16
   )
BEGIN
   SET @msg = ''Items may not be inserted into a case once the list on which that case appears has attained or gone beyond '' + dbo.string$statusName(1,16) + '' status.'' + @msgTag + ''>''
   RAISERROR(@msg,16,1)
   RETURN -100
END

-- Get the id of the case if it exists with uncleared status.
SELECT @caseId = CaseId 
FROM   SendListCase 
WHERE  Cleared = 0 AND SerialNo = @caseName

-- Check to see if the item already resides inside a case.  If it resides in 
-- given case, just return.  If it resides in another case, raise error.
SELECT @currentId = slc.CaseId,
       @currentCase = slc.SerialNo
FROM   SendListCase slc
JOIN   SendListItemCase slic
  ON   slic.CaseId = slc.CaseId
WHERE  slic.ItemId = @itemId
IF @@rowCount > 0 BEGIN
   IF @currentId = coalesce(@caseId,0) BEGIN
      RETURN 0
   END
   ELSE BEGIN
      SET @msg = ''Medium must be removed from case '''''' + @currentCase + '''''' before it may be inserted into a different case.'' + @msgTag + ''>''
      RAISERROR(@msg,16,1)
      RETURN -100
   END
END

-- If the case exists, raise error if any list on which the case is mentioned
-- has transmitted status.
IF @caseId IS NOT NULL BEGIN
   IF EXISTS
      (
      SELECT 1
      FROM   SendList sl
      JOIN   SendListItem sli
        ON   sli.ListId = sl.ListId
      JOIN   SendListItemCase slic
        ON   slic.ItemId = sli.ItemId
      WHERE  slic.caseId = @caseId AND sl.Status >= 16
      )
   BEGIN
      SET @msg = ''Items may not be inserted into a case once the list on which that case appears has reached '' + dbo.string$statusName(1,16) + '' status.'' + @msgTag + ''>''
      RAISERROR(@msg,16,1)
      RETURN -100
   END
   -- Verify that the case does not actively appear on 
   -- any list other than the discrete list, the composite to which the
   -- discrete list belongs, or any specific lists such as those being
   -- created in a single batch but are not yet merged.
   SELECT @listId = ListId 
   FROM   SendListItem 
   WHERE  ItemId = @itemId
   SELECT TOP 1 @listName = sl.ListName
   FROM   SendListItemCase slic
   JOIN   SendListItem sli
     ON   sli.ItemId = slic.ItemId
   JOIN   SendList sl
     ON   sl.ListId = sli.ListId
   WHERE  sl.ListId != @listId AND
          slic.CaseId = @caseId AND
          sli.Status NOT IN (1,512) AND
          coalesce(sl.CompositeId,0) != @listId AND
          charindex(sl.ListName,coalesce(@batchLists,'''')) = 0
   IF @@rowCount > 0 BEGIN
      SET @msg = ''Item may not be added to case '''''' + @caseName + '''''' because case actively resides on unrelated list '''''' + @listName + ''''''.'' + @msgTag + ''>''
      RAISERROR(@msg,16,1)
      RETURN -100
   END
END

-- Begin the transaction
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

-- Add the case if it doesn''t exist
IF @caseId IS NULL BEGIN
   EXECUTE @returnValue = sendListCase$ins @caseName, @caseId OUT
   IF @returnValue != 0 BEGIN
      ROLLBACK TRANSACTION @tranName
      COMMIT TRANSACTION
      RETURN -100
   END
END

-- Add the item to the case
INSERT SendListItemCase
(
   CaseId,
   ItemId
)
VALUES
(
   @caseId,
   @itemId
)
SET @error = @@error
IF @error != 0 BEGIN
   ROLLBACK TRANSACTION @tranName
   COMMIT TRANSACTION
   SET @msg = ''Error encountered while adding medium to case on send list.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
   EXECUTE error$raise @msg, @error
   RETURN -100
END

-- Commit transaction
COMMIT TRANSACTION
RETURN 0
END
'
)

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'sendListItemCase$remove')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.sendListItemCase$remove
(
   @itemId int,
   @caseId int
)
WITH ENCRYPTION
AS
BEGIN
DECLARE @msg as nvarchar(255)        -- used to preformat error message
DECLARE @msgTag as nvarchar(255)     -- used to hold first part of error message header
DECLARE @tranName as nvarchar(255)   -- used to hold name of savepoint
DECLARE @returnValue as int
DECLARE @rowCount as int
DECLARE @error as int
DECLARE @status as int

SET NOCOUNT ON

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=P''
SET @tranName = object_name(@@procid) + CAST(@@nestlevel as nvarchar(2))

-- Verify the status of the item as submitted or verified
SELECT @status = Status
FROM   SendListItem
WHERE  ItemId = @itemId
IF @@rowCount = 0 BEGIN
   SET @msg = ''Send list item not found.'' + @msgTag + ''>''
   RAISERROR(@msg,16,1)
   RETURN -100
END
ELSE BEGIN
   IF @status = 1  BEGIN
      SET @msg = ''Cannot remove item from case because it has been removed from the list.'' + @msgTag + ''>''
      RAISERROR(@msg,16,1)
      RETURN -100
   END
   ELSE IF @status >= 16 BEGIN
      SET @msg = ''Items may not be removed from a case once the list on which that case appears has attained or gone beyond '' + dbo.string$statusName(1,16) + '' status.'' + @msgTag + ''>''
      RAISERROR(@msg,16,1)
      RETURN -100
   END
END

-- Begin the transaction
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

-- Remove the item from the case
DELETE SendListItemCase
WHERE  ItemId = @itemId AND CaseId = @caseId
SET @error = @@error
IF @error != 0 BEGIN
   ROLLBACK TRANSACTION @tranName
   COMMIT TRANSACTION
   SET @msg = ''Error encountered while removing send list medium from case.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
   EXECUTE error$raise @msg, @error
   RETURN -100
END

-- Commit and return
COMMIT TRANSACTION
RETURN 0
END
'
)

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'sendListScan$compare')
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
SET    Compared = cast(convert(nchar(19),getdate(),120) as datetime)
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

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'sendListScan$getByList')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.sendListScan$getByList
(
   @listName nchar(10),
   @stage int
)
WITH ENCRYPTION
AS
BEGIN

SET NOCOUNT ON

-- Select the scan
SELECT s.ScanId,
       s.ScanName,
       s.CreateDate,
       sl.ListName,
       coalesce(convert(nvarchar(19),s.Compared,120),'''') as ''Compared''
FROM   SendListScan s
JOIN   SendList sl
  ON   s.ListId = sl.ListId
WHERE  sl.ListName = @listName AND Stage = @stage

END
'
)

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'sendListScan$ins')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.sendListScan$ins
(
   @listName nchar(10),
   @scanName nvarchar(128),
   @newId int OUTPUT
)
WITH ENCRYPTION
AS
BEGIN
DECLARE @msg as nvarchar(255)        -- used to preformat error message
DECLARE @msgTag as nvarchar(255)     -- used to hold first part of error message header
DECLARE @tranName as nvarchar(255)   -- used to hold name of savepoint
DECLARE @listId int
DECLARE @status int
DECLARE @returnValue int
DECLARE @error int
DECLARE @stage int

SET NOCOUNT ON

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=P''
SET @tranName = object_name(@@procid) + CAST(@@nestlevel as nvarchar(2))

-- Tweak parameters
SET @scanName = ltrim(rtrim(coalesce(@scanName,'''')))

-- Verify that the list exists and has not yet been fully verified
SELECT @listId = ListId,
       @status = Status
FROM   SendList
WHERE  ListName = @listName
IF @@rowCount = 0 BEGIN
   SET @msg = ''List not found.'' + @msgTag + ''>''
   RAISERROR(@msg,16,1)
   RETURN -100
END

-- If there is a composite, get it
IF EXISTS (SELECT 1 FROM SendList WHERE ListId = @listId AND CompositeId IS NOT NULL) BEGIN
   SELECT @listId = ListId,
          @status = Status,
          @listName = ListName
   FROM   SendList
   WHERE  ListId = (SELECT CompositeId FROM SendList WHERE ListId = @listId)          
END

-- Eligible?
IF dbo.bit$statusEligible(1, @status, 8) = 1
   SET @stage = 1
ELSE IF dbo.bit$statusEligible(1, @status, 256) = 1
   SET @stage = 2
ELSE BEGIN
   IF @status = 8 OR @status = 256 BEGIN
      SET @msg = ''Scan may not be created; list '' + @listName + '' has already been fully verified.'' + @msgTag + ''>''
      RAISERROR(@msg,16,1)
      RETURN -100
   END
   ELSE BEGIN
      SET @msg = ''List is not currently verification-eligible.'' + @msgTag + ''>''
      RAISERROR(@msg,16,1)
      RETURN -100
   END
END

-- Begin the transaction
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

-- Insert the record
INSERT SendListScan (ScanName, ListId, Stage)
VALUES (@scanName, @listId, @stage)

SET @error = @@error
IF @error != 0 BEGIN
   ROLLBACK TRANSACTION @tranName
   COMMIT TRANSACTION
   SET @msg = ''Error encountered while creating a new send list scan.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
   EXECUTE error$raise @msg, @error
   RETURN -100
END

-- Commit and return
SET @newId = scope_identity()
COMMIT TRANSACTION
RETURN 0
END
'
)

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'sendListScanItem$ins')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.sendListScanItem$ins
(
   @scanId int,                     -- unique id number of the scan
   @serialNo nvarchar(32),          -- serial number of the medium
   @caseName nvarchar(32)           -- serial number of the case
)
WITH ENCRYPTION
AS
BEGIN
DECLARE @msg as nvarchar(255)        -- used to preformat error message
DECLARE @msgTag as nvarchar(255)     -- used to hold first part of error message header
DECLARE @tranName as nvarchar(255)   -- used to hold name of savepoint
DECLARE @listName as char(10)
DECLARE @status as int
DECLARE @error as int

SET NOCOUNT ON

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=P''
SET @tranName = object_name(@@procid) + CAST(@@nestlevel as nvarchar(2))

-- Cannot be altered if compared
IF EXISTS 
   (
   SELECT 1 
   FROM   SendListScan
   WHERE  ScanId = @scanId AND Compared IS NOT NULL
   ) 
BEGIN
   SET @msg = ''Cannot alter a compare file after it has been compared against its list.'' + @msgTag + ''>''
   RAISERROR(@msg,16,1)
   RETURN -100
END

-- Tweak parameters
SET @serialNo = ltrim(rtrim(coalesce(@serialNo,'''')))
SET @caseName = ltrim(rtrim(coalesce(@caseName,'''')))

-- If the scan has been compared against, it may not be modified
IF EXISTS(SELECT 1 FROM SendListScan WHERE ScanId = @scanId AND Compared IS NOT NULL) BEGIN
   SET @msg = ''Scan has already been used in a comparison.'' + @msgTag + ''>''
   RAISERROR(@msg,16,1)
   RETURN -100
END

-- See if the list is verification-eligible
SELECT @status = sl.Status,
       @listName = sl.ListName
FROM   SendList sl
JOIN   SendListScan sls
  ON   sls.ListId = sl.ListId
WHERE  sls.ScanId = @scanId

IF @status = 256 BEGIN
   SET @msg = ''Items may not be added to this compare file because list '' + @listName + '' has already been fully verified.'' + @msgTag + ''>''
   RAISERROR(@msg,16,1)
   RETURN -100
END
ELSE IF dbo.bit$statusEligible(1,@status,8) = 0 AND dbo.bit$statusEligible(1,@status,256) = 0 BEGIN
   IF @status = 8 BEGIN -- verified (I)
      SET @msg = ''Items may not be added to this compare file because list '' + @listName + '' has already been fully verified.'' + @msgTag + ''>''
      RAISERROR(@msg,16,1)
      RETURN -100
   END
   ELSE BEGIN
      SET @msg = ''Items may not be added to this compare file because list '' + @listName + '' is not currently verification-eligible.'' + @msgTag + ''>''
      RAISERROR(@msg,16,1)
      RETURN -100
   END
END

-- Begin the transaction
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

-- Insert the scan list item
INSERT SendListScanItem
(
   ScanId,
   SerialNo,
   CaseName
)
VALUES
(
   @scanId,
   @serialNo,
   @caseName
)
SET @error = @@error
IF @error != 0 BEGIN
   ROLLBACK TRANSACTION @tranName
   COMMIT TRANSACTION
   SET @msg = ''Error encountered inserting send list compare item.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
   EXECUTE error$raise @msg, @error
   RETURN -100
END

-- Commit the transaction
COMMIT TRANSACTION
RETURN 0
END
'
)

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'vaultInventory$compareResidency')
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
SET @timeNow = cast(convert(nvarchar(19), getdate(), 120) as datetime)

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
          not exists (select 1 from SendListItem sli join sendlist sl on sl.listid = sli.listid where sli.MediumId = m.MediumId and sli.Status != 1 and convert(nchar(10),sl.CreateDate,120) != convert(nchar(10),getdate(),120))
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
          not exists (select 1 from ReceiveListItem rli join receivelist rl on rl.listid = rli.listid where rli.MediumId = m.MediumId and rli.Status != 1 and convert(nchar(10),rl.CreateDate,120) != convert(nchar(10),getdate(),120))
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
          not exists (select 1 FROM SendListItem sli join SendList sl on sl.listid = sli.listid where sli.MediumId = m.MediumId and sli.Status != 1 and (sli.Status != 512 or convert(nchar(10),sl.CreateDate,120) != convert(nchar(10),getdate(),120)))
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
          not exists (select 1 FROM ReceiveListItem rli join ReceiveList rl on rl.listid = rli.listid where rli.MediumId = m.MediumId and rli.Status != 1 and (rli.Status != 512 or convert(nchar(10),rl.CreateDate,120) != convert(nchar(10),getdate(),120)))
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
      VALUES (getdate())
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

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'barCodePattern$ins')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.barCodePattern$ins
(
   @patternString nvarchar(4000)
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
DECLARE @pipe int
DECLARE @pos1 int
DECLARE @pos2 int
DECLARE @nextPattern nvarchar(512)
DECLARE @tblPatterns table
(
   Pattern nvarchar(256),
   Position int identity (1,1),
   AccountId int,
   TypeId  int
)

SET NOCOUNT ON

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=P''
SET @tranName = object_name(@@procid) + CAST(@@nestlevel as nvarchar(2))

-- Entries are separated by pipes, fields by semicolons.  Field order is 
-- pattern followed by type id followed by account id
WHILE len(@patternString) != 0  BEGIN
   SET @pos1 = charindex('';'', @patternString)
   SET @pos2 = charindex('';'', @patternString, @pos1 + 1)
   IF @pos1 = 0 OR @pos2 = 0 BEGIN
      SET @msg = ''String was not submitted correctly to database.'' + @msgTag + ''>''
      RAISERROR(@msg, 16, 1)
      RETURN -100
   END
   -- Find the entry separator
   SET @pipe = charindex(''|'', @patternString, @pos2 + 1)
   IF @pipe = 0 BEGIN
      SET @nextPattern = @patternString
      SET @patternString = ''''
   END
   ELSE BEGIN
      SET @nextPattern = substring(@patternString, 1, @pipe - 1)
      SET @patternString = substring(@patternString, @pipe + 1, len(@patternString) - @pipe)
   END
   -- Verify that the second and third fields are numeric
   IF isnumeric(substring(@nextPattern, @pos1 + 1, @pos2 - @pos1 - 1)) = 0 BEGIN
      SET @msg = ''Given medium type id field not numeric.'' + @msgTag + ''>''
      RAISERROR(@msg, 16, 1)
      RETURN -100
   END
   ELSE IF isnumeric(substring(@nextPattern, @pos2 + 1, len(@nextPattern) - @pos2)) = 0 BEGIN
      SET @msg = ''Given account id field not numeric.'' + @msgTag + ''>''
      RAISERROR(@msg, 16, 1)
      RETURN -100
   END
   -- Set the type id and verify that the type to which it corresponds is not
   -- a container
   SET @typeId = cast(substring(@nextPattern, @pos1 + 1, @pos2 - @pos1 - 1) as int)
   SET @accountId = cast(substring(@nextPattern, @pos2 + 1, len(@nextPattern) - @pos2) as int)
   IF NOT EXISTS(SELECT 1 FROM MediumType WHERE TypeId = @typeId AND Container = 0) BEGIN
      SET @msg = ''Type id given may not be of a container type.'' + @msgTag + ''>''
      RAISERROR(@msg, 16, 1)
      RETURN -100
   END
   -- Insert the fields into the table variable
   INSERT @tblPatterns
   (
      Pattern,
      TypeId,
      AccountId
   )
   VALUES
   (
      ltrim(rtrim(substring(@nextPattern, 1, @pos1 - 1))),
      @typeId,
      @accountId
   )
   SET @error = @@error
   IF @error != 0 BEGIN
      SET @msg = ''Error encountered while inserting record into table variable.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
      RAISERROR(@msg, 16, 1)
      RETURN -100
   END
END

-- Begin transaction
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

-- Truncate the bar code table
DELETE FROM BarCodePattern

-- Insert all the records into the database at once.  This allows
-- the trigger to fire only once, which creates only one audit record.
INSERT BarCodePattern (Pattern, Position, TypeId, AccountId, Notes)
SELECT Pattern, Position, TypeId, AccountId, ''''
FROM   @tblPatterns
ORDER  BY Position
SET @error = @@error
IF @error != 0 BEGIN
   ROLLBACK TRANSACTION @tranName
   COMMIT TRANSACTION
   SET @msg = ''Error encountered while inserting medium bar code patterns.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
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
   @patternString nvarchar(4000)
)
WITH ENCRYPTION
AS
BEGIN
DECLARE @msg as nvarchar(255)        -- used to preformat error message
DECLARE @msgTag as nvarchar(255)     -- used to hold first part of error message header
DECLARE @tranName as nvarchar(255)   -- used to hold name of savepoint
DECLARE @error as int
DECLARE @typeId int
DECLARE @pipe int
DECLARE @semi int
DECLARE @nextPattern nvarchar(512)
DECLARE @tblPatterns table
(
   Pattern nvarchar(256),
   Position int identity (1,1),
   TypeId int
)

SET NOCOUNT ON

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=P''
SET @tranName = object_name(@@procid) + CAST(@@nestlevel as nvarchar(2))

-- Entries are separated by pipes, fields by semicolons.  Field order is 
-- pattern followed by type id followed by account id
WHILE len(@patternString) != 0  BEGIN
   -- Split into fields
   SET @semi = charindex('';'', @patternString)
   IF @semi = 0 BEGIN
      SET @msg = ''String was not submitted correctly to database.'' + @msgTag + ''>''
      RAISERROR(@msg, 16, 1)
      RETURN -100
   END
   -- Find the entry separator
   SET @pipe = charindex(''|'', @patternString, @semi + 1)
   IF @pipe = 0 BEGIN
      SET @nextPattern = @patternString
      SET @patternString = ''''
   END
   ELSE BEGIN
      SET @nextPattern = substring(@patternString, 1, @pipe - 1)
      SET @patternString = substring(@patternString, @pipe + 1, len(@patternString) - @pipe)
   END
   -- Verify that the second field is numeric
   IF isnumeric(substring(@nextPattern, @semi + 1, len(@nextPattern) - @semi)) = 0 BEGIN
      SET @msg = ''Given case type id field not numeric.'' + @msgTag + ''>''
      RAISERROR(@msg, 16, 1)
      RETURN -100
   END
   -- Set the type id and verify that the type to which it corresponds is a
   -- container
   SET @typeId = cast(substring(@nextPattern, @semi + 1, len(@nextPattern) - @semi) as int)
   IF NOT EXISTS(SELECT 1 FROM MediumType WHERE TypeId = @typeId AND Container = 1) BEGIN
      SET @msg = ''Type id given is not of a container type.'' + @msgTag + ''>''
      RAISERROR(@msg, 16, 1)
      RETURN -100
   END
   -- Insert the fields into the table variable
   INSERT @tblPatterns
   (
      Pattern,
      TypeId
   )
   VALUES
   (
      ltrim(rtrim(substring(@nextPattern, 1, @semi - 1))),
      @typeId
   )
   SET @error = @@error
   IF @error != 0 BEGIN
      SET @msg = ''Error encountered while inserting record into table variable.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
      RAISERROR(@msg, 16, 1)
      RETURN -100
   END
END

-- Begin transaction
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

-- Truncate the bar code table
DELETE FROM BarCodePatternCase

-- Insert all the records into the database at once.  This allows
-- the trigger to fire only once, which creates only one audit record.
INSERT BarCodePatternCase (Pattern, Position, TypeId, Notes)
SELECT Pattern, Position, TypeId, ''''
FROM   @tblPatterns
ORDER  BY Position
SET @error = @@error
IF @error != 0 BEGIN
   ROLLBACK TRANSACTION @tranName
   COMMIT TRANSACTION
   SET @msg = ''Error encountered while inserting case bar code patterns.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
   RAISERROR(@msg, 16, 1)
   RETURN -100
END

-- Commit transaction
COMMIT TRANSACTION
RETURN 0
END
'
)

IF EXISTS(SELECT * FROM sysobjects WHERE name = 'emailGroupOperator$afterDelete' AND objectproperty(id, 'ExecIsDeleteTrigger' ) = 1) 
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'TRIGGER emailGroupOperator$afterDelete
ON     EmailGroupOperator
WITH ENCRYPTION
AFTER  DELETE
AS
BEGIN
DECLARE @msg nvarchar(255)        -- used to preformat error message
DECLARE @msgTag nvarchar(255)     -- used to hold first part of error message header
DECLARE @tranName nvarchar(255)   -- used to hold name of savepoint
DECLARE @error int
DECLARE @id int

IF @@rowcount = 0 RETURN
SET @id = 0

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=T''
SET @tranName = object_name(@@procid) + CAST(trigger_nestlevel(@@procid) as nvarchar(2))

-- Get the caller login from the spidLogin table
IF len(dbo.string$GetSpidLogin()) = 0 BEGIN
   SET @msg = ''No login found for auditing purposes.'' + @msgTag + ''>''
   EXECUTE error$raise @msg, 0
   RETURN
END

-- Begin transaction
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

WHILE 1 = 1 BEGIN
   SELECT TOP 1 @id = GroupId
   FROM   Deleted
   WHERE  GroupId > @id
   ORDER  BY GroupId ASC
   IF @@rowcount = 0 
      BREAK
   ELSE IF NOT EXISTS (SELECT 1 FROM EmailGroupOperator WHERE GroupId = @id) BEGIN
      DELETE EmailGroup WHERE GroupId = @id
      SET @error = @@error
      IF @error != 0 BEGIN
         SET @msg = ''Error encountered while deleting an email group.'' + @msgTag + '';Error='' + cast(@error as nvarchar(10)) + ''>''
         EXECUTE error$raise @msg, @error, @tranName
         RETURN
      END
   END
END

COMMIT TRANSACTION
END
'
)

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'emailGroup$getById')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.emailGroup$getById
(
   @groupId int
)
WITH ENCRYPTION
AS
BEGIN

SET NOCOUNT ON

SELECT GroupId, GroupName
FROM   EmailGroup
WHERE  GroupId = @groupId

END   
'
)

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'emailGroup$getByName')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.emailGroup$getByName
(
   @groupName nvarchar(256)
)
WITH ENCRYPTION
AS
BEGIN

SET NOCOUNT ON

SELECT GroupId, GroupName
FROM   EmailGroup
WHERE  GroupName = @groupName

END   
'
)

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'emailGroup$getTable')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.emailGroup$getTable
WITH ENCRYPTION
AS
BEGIN

SET NOCOUNT ON

SELECT GroupId, GroupName
FROM   EmailGroup
ORDER  BY GroupName

END
'
)

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'emailGroup$ins')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.emailGroup$ins
(
   @groupName nvarchar(256),
   @newId int = NULL OUT
)
WITH ENCRYPTION
AS
BEGIN
DECLARE @msg as nvarchar(255)        -- used to preformat error message
DECLARE @msgTag as nvarchar(255)     -- used to hold first part of error message header
DECLARE @tranName as nvarchar(255)   -- used to hold name of savepoint
DECLARE @error as int

SET NOCOUNT ON

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=P''
SET @tranName = object_name(@@procid) + CAST(@@nestlevel as nvarchar(2))

BEGIN TRANSACTION
SAVE TRANSACTION @tranName

INSERT EmailGroup
(
   GroupName
)
VALUES
(
   @groupName
)

SET @error = @@error
IF @error != 0 BEGIN
   ROLLBACK TRANSACTION @tranName
   COMMIT TRANSACTION
   SET @msg = ''Error encountered while inserting a new email group.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
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

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'emailGroup$upd')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.emailGroup$upd
(
   @groupId int,
   @groupName nvarchar(256)
)
WITH ENCRYPTION
AS
BEGIN
DECLARE @msg as nvarchar(255)        -- used to preformat error message
DECLARE @msgTag as nvarchar(255)     -- used to hold first part of error message header
DECLARE @tranName as nvarchar(255)   -- used to hold name of savepoint
DECLARE @error as int

SET NOCOUNT ON

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=P''
SET @tranName = object_name(@@procid) + CAST(@@nestlevel as nvarchar(2))

BEGIN TRANSACTION
SAVE TRANSACTION @tranName

UPDATE EmailGroup
SET    GroupName = @groupName
WHERE  GroupId = @groupId
SET @error = @@error
IF @error != 0 BEGIN
   ROLLBACK TRANSACTION @tranName
   COMMIT TRANSACTION
   SET @msg = ''Error encountered while updating an email group.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
   EXECUTE error$raise @msg, @error
   RETURN -100
END

COMMIT TRANSACTION
RETURN 0
END
'
)

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'emailGroup$del')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.emailGroup$del
(
   @groupId int
)
WITH ENCRYPTION
AS
BEGIN
DECLARE @msg as nvarchar(255)        -- used to preformat error message
DECLARE @msgTag as nvarchar(255)     -- used to hold first part of error message header
DECLARE @tranName as nvarchar(255)   -- used to hold name of savepoint
DECLARE @error as int

SET NOCOUNT ON

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=P''
SET @tranName = object_name(@@procid) + CAST(@@nestlevel as nvarchar(2))

BEGIN TRANSACTION
SAVE TRANSACTION @tranName

DELETE EmailGroup
WHERE  GroupId = @groupId
SET @error = @@error
IF @error != 0 BEGIN
   ROLLBACK TRANSACTION @tranName
   COMMIT TRANSACTION
   SET @msg = ''Error encountered while deleting an email group.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
   EXECUTE error$raise @msg, @error
   RETURN -100
END

COMMIT TRANSACTION
RETURN 0
END
'
)

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'emailGroup$getOperators')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.emailGroup$getOperators
(
   @groupId int
)
WITH ENCRYPTION
AS
BEGIN

SET NOCOUNT ON

SELECT o.OperatorId,
       o.OperatorName,
       o.Login,
       o.Password,
       o.Salt,
       o.Role,
       o.PhoneNo,
       o.Email,
       o.Notes,
       o.LastLogin,
       o.RowVersion
FROM   Operator o
JOIN   EmailGroupOperator eo
  ON   eo.OperatorId = o.OperatorId
JOIN   EmailGroup e
  ON   e.GroupId = eo.groupid
WHERE  e.GroupId = @groupId
ORDER  BY o.OperatorName ASC

END
'
)

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'emailGroupOperator$ins')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.emailGroupOperator$ins
(
   @groupId int,
   @operatorId int
)
WITH ENCRYPTION
AS
BEGIN
DECLARE @msg as nvarchar(255)        -- used to preformat error message
DECLARE @msgTag as nvarchar(255)     -- used to hold first part of error message header
DECLARE @tranName as nvarchar(255)   -- used to hold name of savepoint
DECLARE @error as int

SET NOCOUNT ON

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=P''
SET @tranName = object_name(@@procid) + CAST(@@nestlevel as nvarchar(2))

IF NOT EXISTS (SELECT 1 FROM EmailGroupOperator WHERE GroupId = @groupId AND OperatorId = @operatorId) BEGIN
   BEGIN TRANSACTION
   SAVE TRANSACTION @tranName
   -- Insert the group operator   
   INSERT EmailGroupOperator
   (
      GroupId,
      OperatorId
   )
   VALUES
   (
      @groupId, 
      @operatorId
   )
   -- Evaluate the error
   SET @error = @@error
   IF @error != 0 BEGIN
      ROLLBACK TRANSACTION @tranName
      COMMIT TRANSACTION
      SET @msg = ''Error encountered while inserting a new email group operator.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
      EXECUTE error$raise @msg, @error
      RETURN -100
   END
   
   COMMIT TRANSACTION
END

RETURN 0
END
'
)

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'emailGroupOperator$del')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.emailGroupOperator$del
(
   @groupId int,
   @operatorId int
)
WITH ENCRYPTION
AS
BEGIN
DECLARE @msg as nvarchar(255)        -- used to preformat error message
DECLARE @msgTag as nvarchar(255)     -- used to hold first part of error message header
DECLARE @tranName as nvarchar(255)   -- used to hold name of savepoint
DECLARE @error as int

SET NOCOUNT ON

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=P''
SET @tranName = object_name(@@procid) + CAST(@@nestlevel as nvarchar(2))

BEGIN TRANSACTION
SAVE TRANSACTION @tranName

DELETE EmailGroupOperator
WHERE  GroupId = @groupId AND OperatorId = @operatorId
SET @error = @@error
IF @error != 0 BEGIN
   ROLLBACK TRANSACTION @tranName
   COMMIT TRANSACTION
   SET @msg = ''Error encountered while deleting an email group operator.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
   EXECUTE error$raise @msg, @error
   RETURN -100
END

COMMIT TRANSACTION
RETURN 0
END
'
)

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'listStatusEmail$ins')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.listStatusEmail$ins
(
   @listType int,
   @status int,
   @groupId int
)
WITH ENCRYPTION
AS
BEGIN
DECLARE @msg as nvarchar(255)        -- used to preformat error message
DECLARE @msgTag as nvarchar(255)     -- used to hold first part of error message header
DECLARE @tranName as nvarchar(255)   -- used to hold name of savepoint
DECLARE @error as int

SET NOCOUNT ON

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=P''
SET @tranName = object_name(@@procid) + CAST(@@nestlevel as nvarchar(2))

IF NOT EXISTS (SELECT 1 FROM ListStatusEmail WHERE ListType = @listType AND Status = @status AND GroupId = @groupId) BEGIN
   BEGIN TRANSACTION
   SAVE TRANSACTION @tranName
   INSERT ListStatusEmail
   (
      ListType,
      Status,
      GroupId
   )
   VALUES
   (
      @listType, 
      @status,
      @groupId
   )
   SET @error = @@error
   IF @error != 0 BEGIN
      ROLLBACK TRANSACTION @tranName
      COMMIT TRANSACTION
      SET @msg = ''Error encountered while inserting a new list status email group.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
      EXECUTE error$raise @msg, @error
      RETURN -100
   END
   COMMIT TRANSACTION
END
RETURN 0
END
'
)

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'listStatusEmail$del')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.listStatusEmail$del
(
   @listType int,
   @status int,
   @groupId int
)
WITH ENCRYPTION
AS
BEGIN
DECLARE @msg as nvarchar(255)        -- used to preformat error message
DECLARE @msgTag as nvarchar(255)     -- used to hold first part of error message header
DECLARE @tranName as nvarchar(255)   -- used to hold name of savepoint
DECLARE @error as int

SET NOCOUNT ON

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=P''
SET @tranName = object_name(@@procid) + CAST(@@nestlevel as nvarchar(2))

BEGIN TRANSACTION
SAVE TRANSACTION @tranName

DELETE ListStatusEmail
WHERE  ListType = @listType AND Status = @status AND GroupId = @groupId
SET @error = @@error
IF @error != 0 BEGIN
   ROLLBACK TRANSACTION @tranName
   COMMIT TRANSACTION
   SET @msg = ''Error encountered while deleting a list status email group.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
   EXECUTE error$raise @msg, @error
   RETURN -100
END

COMMIT TRANSACTION
RETURN 0
END
'
)

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'listStatusEmail$getTable')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.listStatusEmail$getTable
WITH ENCRYPTION
AS
BEGIN

SET NOCOUNT ON

SELECT s.ListType, s.Status, e.GroupName
FROM   ListStatusEmail s
JOIN   EmailGroup e
  ON   e.GroupId = s.GroupId
ORDER  BY s.ListType, e.GroupName

END
'
)

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'listStatusEmail$get')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.listStatusEmail$get
(
   @listType int,
   @status int
)
WITH ENCRYPTION
AS
BEGIN

SET NOCOUNT ON

SELECT e.GroupId, e.GroupName
FROM   ListStatusEmail s
JOIN   EmailGroup e
  ON   e.GroupId = s.GroupId
WHERE  s.ListType = @listType AND s.Status = @status
ORDER  BY e.GroupName ASC

END
'
)

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'emailServer$get')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.emailServer$get
WITH ENCRYPTION
AS
BEGIN

SET NOCOUNT ON

SELECT TOP 1 ServerName, 
       FromAddress
FROM   EmailServer
ORDER  BY ServerName

END
'
)

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'emailServer$upd')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.emailServer$upd
(
   @serverName nvarchar(256),
   @fromAddress nvarchar(256)
)
WITH ENCRYPTION
AS
BEGIN
DECLARE @msg as nvarchar(255)        -- used to preformat error message
DECLARE @msgTag as nvarchar(255)     -- used to hold first part of error message header
DECLARE @tranName as nvarchar(255)   -- used to hold name of savepoint
DECLARE @error as int

SET NOCOUNT ON

SET @serverName = isnull(@serverName, '''')
SET @fromAddress = isnull(@fromAddress, '''')

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=P''
SET @tranName = object_name(@@procid) + CAST(@@nestlevel as nvarchar(2))

BEGIN TRANSACTION
SAVE TRANSACTION @tranName

-- Delete all the rows from the email server
DELETE EmailServer
SET @error = @@error
IF @error != 0 BEGIN
   ROLLBACK TRANSACTION @tranName
   COMMIT TRANSACTION
   SET @msg = ''Error encountered while updating email server.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
   EXECUTE error$raise @msg, @error
   RETURN -100
END

-- Insert the server
INSERT EmailServer (ServerName, FromAddress)
VALUES(@serverName, @fromAddress)
SET @error = @@error
IF @error != 0 BEGIN
   ROLLBACK TRANSACTION @tranName
   COMMIT TRANSACTION
   SET @msg = ''Error encountered while inserting an email server.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
   EXECUTE error$raise @msg, @error
   RETURN -100
END

COMMIT TRANSACTION
RETURN 0
END
'
)
END

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'operator$getById')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.operator$getById
(
   @id int
)
WITH ENCRYPTION
AS
BEGIN

SET NOCOUNT ON

-- Select
SELECT OperatorId,
       OperatorName,
       Login,
       Password,
       Salt,
       Role,
       PhoneNo,
       Email,
       Notes,
       LastLogin,
       RowVersion
FROM   Operator
WHERE  OperatorId = @id

END
'
)

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'operator$getByLogin')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.operator$getByLogin
(
   @login nvarchar(32)
)
WITH ENCRYPTION
AS
BEGIN

SET NOCOUNT ON

-- Data integrity
IF @login IS NULL SET @login = ''''

-- Select
SELECT OperatorId,
       OperatorName,
       Login,
       Password,
       Salt,
       Role,
       PhoneNo,
       Email,
       Notes,
       LastLogin,
       RowVersion
FROM   Operator
WHERE  Login = @login

END
'
)

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'operator$getTable')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.operator$getTable
WITH ENCRYPTION
AS
BEGIN

SET NOCOUNT ON

SELECT OperatorId,
       OperatorName,
       Login,
       Password,
       Salt,
       Role,
       PhoneNo,
       Email,
       Notes,
       LastLogin,
       RowVersion
FROM   Operator
ORDER BY
       Login asc

END
'
)

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'operator$upd')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.operator$upd
(
   @id int,
   @name nvarchar(256),
   @login nvarchar(32),
   @password nvarchar(128),
   @salt nvarchar(20),
   @role int,
   @phoneNo nvarchar(64),
   @email nvarchar(256),
   @notes nvarchar(1000),
   @lastLogin datetime,
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

SET NOCOUNT ON

-- Trim strings
SET @name = ltrim(rtrim(@name))
SET @login = ltrim(rtrim(@login))
SET @password = ltrim(rtrim(@password))
SET @phoneNo = ltrim(rtrim(@phoneNo))
SET @email = ltrim(rtrim(@email))
SET @notes = ltrim(rtrim(@notes))
SET @lastLogin = cast(convert(nchar(19), @lastLogin, 120) as datetime)

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=P''
SET @tranName = object_name(@@procid) + CAST(@@nestlevel as nvarchar(2))

-- Update operator
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

UPDATE Operator
SET    OperatorName = @name,
       Login = @login,
       Password = @password,
       Salt = @salt,
       Role = @role,
       PhoneNo = @phoneNo,
       Email = @email,
       Notes = @notes,
       LastLogin = @lastLogin
WHERE  OperatorId = @id AND
       RowVersion = @rowVersion

SELECT @error = @@error, @rowCount = @@rowcount

IF @error != 0 BEGIN
   ROLLBACK TRANSACTION @tranName
   COMMIT TRANSACTION
   SET @msg = ''Error encountered while updating operator.'' + @msgTag + '';Error='' +  cast(@error as nvarchar(10)) + ''>''
   EXECUTE error$raise @msg, @error
   RETURN -100
END
ELSE IF @rowCount = 0 BEGIN
   IF EXISTS(SELECT 1 FROM Operator WHERE OperatorId = @id) BEGIN
      ROLLBACK TRANSACTION @tranName
      COMMIT TRANSACTION
      SET @msg = ''Operator has been modified since retrieval.'' + @msgTag + ''>''
      RAISERROR(@msg,16,1)
      RETURN -100
   END
   ELSE BEGIN
      ROLLBACK TRANSACTION @tranName
      COMMIT TRANSACTION
      SET @msg = ''Operator does not exist.'' + @msgTag + ''>''
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

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'vaultInventoryItem$ins')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.vaultInventoryItem$ins
(
   @inventoryId int,
   @serialNo nvarchar(32),
   @typeName nvarchar(128),
   @hotStatus bit,
   @returnDate nvarchar(10) = '''',
   @notes nvarchar(1000) = ''''
)
WITH ENCRYPTION
AS
BEGIN
DECLARE @msg nvarchar(255)        -- used to preformat error message
DECLARE @msgTag nvarchar(255)     -- used to hold first part of error message header
DECLARE @tranName nvarchar(255)   -- used to hold name of savepoint
DECLARE @currentNote nvarchar(1000)
DECLARE @returnValue int
DECLARE @container int
DECLARE @mediumId int
DECLARE @location bit
DECLARE @typeId int
DECLARE @error int

SET NOCOUNT ON

-- Tweak parameters
SET @notes = coalesce(@notes,'''')
SET @serialNo = coalesce(@serialNo,'''')
SET @typeName = coalesce(@typeName,'''')
SET @returnDate = coalesce(@returnDate,'''')

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=P''
SET @tranName = object_name(@@procid) + CAST(@@nestlevel as nvarchar(2))

-- Get the medium type
SELECT @typeId = TypeId,
       @container = Container
FROM   MediumType
WHERE  TypeName = @typeName
IF @@rowCount = 0 BEGIN
   SET @msg = ''Medium type unknown.'' + @msgTag + '';Type='' + @typeName + ''>''
   RAISERROR(@msg,16,1)
   RETURN -100
END

-- Insert record
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

INSERT VaultInventoryItem
(
   SerialNo,
   TypeId,
   HotStatus,
   ReturnDate,
   InventoryId
)
VALUES
(
   @serialNo,
   @typeId,
   @hotStatus,
   @returnDate,
   @inventoryId
)

SET @error = @@error
IF @error != 0 BEGIN
   ROLLBACK TRANSACTION @tranName
   COMMIT TRANSACTION
   SET @msg = ''Error encountered while inserting new vault inventory item ('' + @serialNo + '').'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
   EXECUTE error$raise @msg, @error
   RETURN -100
END

-- If the medium does not exist, add it at the vault
IF @container = 0 BEGIN
	SET @location = 0
	SET @currentNote = ''''
	SELECT @mediumId = MediumId,
	       @location = Location,
	       @currentNote = Notes
	FROM   Medium
	WHERE  SerialNo = @serialNo
	IF @@rowCount = 0 BEGIN
	   EXECUTE @returnValue = medium$addDynamic @serialNo, 0, @mediumId OUT
	   IF @returnValue != 0 BEGIN
	      ROLLBACK TRANSACTION @tranName
	      COMMIT TRANSACTION
	      RETURN -100
	   END
	END
	-- Update the medium notes if we have an inventory item note, there are 
	-- no current notes on the medium, and the medium is at the vault.
	IF LEN(@currentNote) = 0 AND LEN(@notes) != 0 AND @location = 0 BEGIN
	   UPDATE Medium
	   SET    Notes = @notes
	   WHERE  MediumId = @mediumId
	END
END

-- Commit the transaction
COMMIT TRANSACTION
RETURN 0
END
'
)

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'vaultInventory$updateReturnDates')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.vaultInventory$updateReturnDates
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
DECLARE @returnDate nvarchar(10)
DECLARE @container bit
DECLARE @rowcount int
DECLARE @error int
DECLARE @tblDates table
(
   RowNo int IDENTITY(1,1),
   SerialNo nvarchar(64),
   ReturnDate nvarchar(10),
   Container bit
)

SET NOCOUNT ON

-- Set up the transaction name
SET @tranName = object_name(@@procid) + CAST(@@nestlevel as nvarchar(2))

-- Begin the transaction
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

INSERT @tblDates (SerialNo, ReturnDate, Container)
SELECT vii.SerialNo, vii.ReturnDate, dbo.bit$IsContainerType(vii.TypeId)
FROM   VaultInventoryItem vii
JOIN   Medium m
  ON   m.SerialNo = vii.SerialNo
WHERE  vii.InventoryId = @inventoryId AND len(vii.ReturnDate) != 0

SELECT @rowcount = @@rowcount, @i = 1

WHILE @i <= @rowcount BEGIN
   -- Get the next serial number
   SELECT @serialNo = SerialNo,
          @returnDate = ReturnDate,
          @container = Container
   FROM   @tblDates
   WHERE  RowNo = @i
   -- If a container, update the return date on the sealed case.  Otherwise,
   -- update the return date on the medium.
   IF @container = 1 BEGIN
      IF EXISTS (SELECT 1 FROM SealedCase WHERE SerialNo = @serialNo AND len(ReturnDate) = 0) BEGIN
         UPDATE SealedCase
         SET    ReturnDate = @returnDate
         WHERE  SerialNo = @serialNo
      END
   END
   ELSE BEGIN
      IF EXISTS (SELECT 1 FROM Medium WHERE SerialNo = @serialNo AND len(ReturnDate) = 0) BEGIN
         UPDATE Medium
         SET    ReturnDate = @returnDate
         WHERE  SerialNo = @serialNo
      END
   END
   -- Evaluate error
   SET @error = @@error   
   IF @error != 0 BEGIN
      ROLLBACK TRANSACTION @tranName
      COMMIT TRANSACTION
      SET @msg = ''Error encountered while updating return date off vault inventory item ('' + @serialNo + '').'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
      EXECUTE error$raise @msg, @error
      RETURN -100
   END
   -- Increment counter
   SET @i = @i + 1
END

COMMIT TRANSACTION
RETURN 0
END
'
)

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'vaultInventory$compare')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.vaultInventory$compare
(
   @accountName nvarchar(256),
   @autoResolve bit = 1  -- Perform account-independent reconciliation
)
WITH ENCRYPTION
AS
BEGIN
DECLARE @msg nvarchar(255)        -- used to preformat error message
DECLARE @msgTag nvarchar(255)     -- used to hold first part of error message header
DECLARE @tranName nvarchar(255)   -- used to hold name of savepoint
DECLARE @returnValue int
DECLARE @inventoryId int
DECLARE @accountId int
DECLARE @error int

SET NOCOUNT ON

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=P''
SET @tranName = object_name(@@procid) + CAST(@@nestlevel as nvarchar(2))

-- Get the inventory id
SELECT TOP 1 @inventoryId = v.InventoryId,
       @accountId = v.AccountId
FROM   VaultInventory v
JOIN   Account a
  ON   a.AccountId = v.AccountId
WHERE  a.AccountName = @accountName
ORDER BY v.DownloadTime Desc
IF @@rowCount = 0 BEGIN
   SET @msg = ''No inventory exists for account '' + @accountName + ''.'' + @msgTag + ''>''
   EXECUTE error$raise @msg, 0
   RETURN -100
END

-- Begin the transaction
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

-- Account-independent comparisons
IF @autoResolve = 1 BEGIN
	EXECUTE @returnValue = vaultInventory$removeReconciled
	IF @returnValue != 0 BEGIN
   	ROLLBACK TRANSACTION @tranName
	   COMMIT TRANSACTION
   	RETURN -100
	END
END

-- Other comparisons
EXECUTE @returnValue = vaultInventory$insertNew @inventoryId
IF @returnValue != 0 BEGIN
   ROLLBACK TRANSACTION @tranName
   COMMIT TRANSACTION
   RETURN -100
END

EXECUTE @returnValue = vaultInventory$updateReturnDates @inventoryId
IF @returnValue != 0 BEGIN
   ROLLBACK TRANSACTION @tranName
   COMMIT TRANSACTION
   RETURN -100
END

EXECUTE @returnValue = vaultInventory$resolveMissing @inventoryId
IF @returnValue != 0 BEGIN
   ROLLBACK TRANSACTION @tranName
   COMMIT TRANSACTION
   RETURN -100
END

EXECUTE @returnValue = vaultInventory$compareResidency @inventoryId
IF @returnValue != 0 BEGIN
   ROLLBACK TRANSACTION @tranName
   COMMIT TRANSACTION
   RETURN -100
END

EXECUTE @returnValue = vaultInventory$compareCases @inventoryId
IF @returnValue != 0 BEGIN
   ROLLBACK TRANSACTION @tranName
   COMMIT TRANSACTION
   RETURN -100
END

EXECUTE @returnValue = vaultInventory$compareMediumTypes @inventoryId
IF @returnValue != 0 BEGIN
   ROLLBACK TRANSACTION @tranName
   COMMIT TRANSACTION
   RETURN -100
END

EXECUTE @returnValue = vaultInventory$compareCaseTypes @inventoryId
IF @returnValue != 0 BEGIN
   ROLLBACK TRANSACTION @tranName
   COMMIT TRANSACTION
   RETURN -100
END

EXECUTE @returnValue = vaultInventory$compareMediumAccounts @inventoryId
IF @returnValue != 0 BEGIN
   ROLLBACK TRANSACTION @tranName
   COMMIT TRANSACTION
   RETURN -100
END

-- Get the inventory id
SELECT TOP 1 @inventoryId = v.InventoryId,
       @accountId = v.AccountId
FROM   VaultInventory v
JOIN   Account a
  ON   a.AccountId = v.AccountId
WHERE  a.AccountName = @accountName
ORDER BY v.DownloadTime Desc
IF @@rowCount = 0 BEGIN
   SET @msg = ''No inventory exists for account '' + @accountName + ''.'' + @msgTag + ''>''
   EXECUTE error$raise @msg, 0
   RETURN -100
END

-- Insert an audit record
IF len(dbo.string$getSpidLogin()) = 0 BEGIN
   ROLLBACK TRANSACTION @tranName
   COMMIT TRANSACTION
   SET @msg = ''No login specified for auditing purposes.'' + @msgTag + ''>''
   EXECUTE error$raise @msg, 0
   RETURN -100
END
ELSE BEGIN
   INSERT XVaultInventory
   (
      Object,
      Action,
      Detail,
      Login
   )
   VALUES
   (
      @accountName,
      12,
      ''Vault inventory for account '' + @accountName + '' compared against database'',
      dbo.string$getSpidLogin()
   )
   SET @error = @@error
   IF @error != 0 BEGIN
      ROLLBACK TRANSACTION @tranName
      COMMIT TRANSACTION
      SET @msg = ''Error encountered while inserting vault inventory audit record.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
      EXECUTE error$raise @msg, @error
      RETURN -100
   END
END

-- Commit the transaction
COMMIT TRANSACTION

-- Select the number of discrepancies in the database
SELECT count(*) FROM VaultDiscrepancy

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
DECLARE @order1 nvarchar(4000)	-- innermost order clause
DECLARE @order2 nvarchar(4000)   -- middle order clause
DECLARE @order3 nvarchar(4000)   -- outermost order clause
DECLARE @where nvarchar(4000)
DECLARE @topSize int
DECLARE @display int
DECLARE @count int
DECLARE @error int

SET NOCOUNT ON

-- Set the message tag
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=P''

-- Verify validity of @pageNo
IF @pageNo < 1 SET @pageNo = 1

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
IF len(ltrim(rtrim(coalesce(@filter,'''')))) > 0 BEGIN
	SET @filter = replace(@filter,''SerialNo'',''s.SerialNo'')
	SET @filter = replace(@filter,''RecordedDate'',''v.RecordedDate'')
	SET @filter = replace(@filter,''Type'',''s.Type'')
   SET @where = @where + '' AND ('' + @filter + '')''
END

-- Construct the fields string
SET @fields2 = ''ItemId, RecordedDate, SerialNo, Details, Type''
SET @fields1 = ''v.ItemId, v.RecordedDate, s.SerialNo, s.Details, s.Type''

-- Construct the tables string
SET @tables = ''VaultDiscrepancy v JOIN (SELECT v.ItemId, v.SerialNo, case m.Location when 1 then ''''Vault claims residence of medium'''' else ''''Vault denies residence of medium'''' end as ''''Details'''', 1 as ''''Type'''' FROM VaultDiscrepancyResidency v JOIN Medium m ON m.MediumId = v.MediumId UNION SELECT ItemId, SerialNo, ''''Vault claims residence of locally unknown case'''' as ''''Details'''', 3 as ''''Type'''' FROM VaultDiscrepancyUnknownCase UNION SELECT v.ItemId, v.SerialNo, ''''Vault asserts medium should be of type '''''''''''' + mt.TypeName + '''''''''''''''' as ''''Details'''', 2 as ''''Type'''' FROM VaultDiscrepancyMediumType v JOIN MediumType mt ON v.VaultType = mt.TypeId UNION SELECT v.ItemId, v.SerialNo, ''''Vault asserts container should be of type '''''''''''' + mt.TypeName + '''''''''''''''' as ''''Details'''', 4 as ''''Type'''' FROM VaultDiscrepancyCaseType v JOIN MediumType mt ON v.VaultType = mt.TypeId UNION SELECT v.ItemId, v.SerialNo, ''''Vault asserts medium should belong to account '''''''''''' + a.AccountName + '''''''''''''''' as ''''Details'''', 5 as ''''Type'''' FROM VaultDiscrepancyAccount v JOIN Account a ON v.VaultAccount = a.AccountId) as s ON s.ItemId = v.ItemId''

-- Select the total number of records that fit the criteria
CREATE TABLE #tblTemp (xyz int)
SET @sql = ''INSERT #tblTemp SELECT count(*) FROM '' + @tables + @where
EXECUTE sp_executesql @sql
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
EXECUTE sp_executesql @sql
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
DECLARE @VAULTINVENTORY int
DECLARE @VAULTDISCREPANCY int
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
SET @VAULTINVENTORY        = 512
SET @VAULTDISCREPANCY      = 1024
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
         SET @tables = ''XAccount''
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
         SET @tables = ''SELECT ItemId, Date, Object, Action, Detail, Login FROM XSendList ''
                        + ''UNION ''
                        + ''SELECT ItemId, Date, Object, Action, Detail, Login FROM XSendListItem ''
                        + ''UNION ''
                        + ''SELECT ItemId, Date, Object, Action, Detail, Login FROM XSendListCase ''
         SET @tables = ''('' + @tables + '') as tblSend''
         SET @fields1 = ''ItemId, Date, Object, Action, Detail, Login, '' + @auditType
      END
      ELSE IF power(2,@i) = @RECEIVELIST BEGIN
         SET @tables = ''SELECT ItemId, Date, Object, Action, Detail, Login FROM XReceiveList ''
                        + ''UNION ''
                        + ''SELECT ItemId, Date, Object, Action, Detail, Login FROM XReceiveListItem ''
         SET @tables = ''('' + @tables + '') as tblReceive''
         SET @fields1 = ''ItemId, Date, Object, Action, Detail, Login, '' + @auditType
      END
      ELSE IF power(2,@i) = @DISASTERCODELIST BEGIN
         SET @tables = ''SELECT ItemId, Date, Object, Action, Detail, Login FROM XDisasterCodeList ''
                        + ''UNION ''
                        + ''SELECT ItemId, Date, Object, Action, Detail, Login FROM XDisasterCodeListItem ''
         SET @tables = ''('' + @tables + '') as tblReceive''
         SET @fields1 = ''ItemId, Date, Object, Action, Detail, Login, '' + @auditType
      END
      ELSE IF power(2,@i) = @VAULTINVENTORY BEGIN
         SET @tables = ''XVaultInventory''
         SET @fields1 = ''ItemId, Date, Object, Action, Detail, Login, '' + @auditType
      END
      ELSE IF power(2,@i) = @VAULTDISCREPANCY BEGIN
         SET @tables = ''XVaultDiscrepancy''
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

IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'auditTrail$clean')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.auditTrail$clean
(
   @auditType int,
   @cleanDate datetime
)
WITH ENCRYPTION
AS
BEGIN

SET NOCOUNT ON

SET @cleanDate = cast(convert(nchar(10), @cleanDate, 120) as datetime)

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
DECLARE @VAULTINVENTORY int
DECLARE @VAULTDISCREPANCY int
DECLARE @SEALEDCASE int
DECLARE @MEDIUM int
DECLARE @MEDIUMMOVEMENT int
DECLARE @GENERALACTION int

-- Assign constant values
SELECT
@ACCOUNT               = 1,
@SYSTEMACTION          = 2,
@BARCODEPATTERN        = 4,
@EXTERNALSITE          = 8,
@IGNOREDBARCODEPATTERN = 16,
@OPERATOR              = 32,
@SENDLIST              = 64,
@RECEIVELIST           = 128,
@DISASTERCODELIST      = 256,
@VAULTINVENTORY        = 512,
@VAULTDISCREPANCY      = 1024,
@SEALEDCASE            = 2048,
@MEDIUM                = 4096,
@MEDIUMMOVEMENT        = 8192,
@GENERALACTION         = 16384

-- Delete records
IF @auditType = @ACCOUNT BEGIN
   DELETE XAccount
   WHERE  Date < @cleanDate
END
ELSE IF @auditType = @SYSTEMACTION BEGIN
   DELETE XSystemAction
   WHERE  Date < @cleanDate
END
ELSE IF @auditType = @BARCODEPATTERN BEGIN
   DELETE XBarCodePattern
   WHERE  Date < @cleanDate
END
ELSE IF @auditType = @EXTERNALSITE BEGIN
   DELETE XExternalSiteLocation
   WHERE  Date < @cleanDate
END
ELSE IF @auditType = @IGNOREDBARCODEPATTERN BEGIN
   DELETE XIgnoredBarCodePattern
   WHERE  Date < @cleanDate
END
ELSE IF @auditType = @OPERATOR BEGIN
   DELETE XOperator
   WHERE  Date < @cleanDate
END
ELSE IF @auditType = @SENDLIST BEGIN
   DELETE XSendList
   WHERE  Date < @cleanDate
   DELETE XSendListItem
   WHERE  Date < @cleanDate
   DELETE XSendListCase
   WHERE  Date < @cleanDate
END
ELSE IF @auditType = @RECEIVELIST BEGIN
   DELETE XReceiveList
   WHERE  Date < @cleanDate
   DELETE XReceiveListItem
   WHERE  Date < @cleanDate
END
ELSE IF @auditType = @DISASTERCODELIST BEGIN
   DELETE XDisasterCodeList
   WHERE  Date < @cleanDate
   DELETE XDisasterCodeListItem
   WHERE  Date < @cleanDate
END
ELSE IF @auditType = @VAULTINVENTORY BEGIN
   DELETE XVaultInventory
   WHERE  Date < @cleanDate
END
ELSE IF @auditType = @VAULTDISCREPANCY BEGIN
   DELETE XVaultDiscrepancy
   WHERE  Date < @cleanDate
END
ELSE IF @auditType = @SEALEDCASE BEGIN
   DELETE XSealedCase
   WHERE  Date < @cleanDate
END
ELSE IF @auditType = @MEDIUM BEGIN
   DELETE XMedium
   WHERE  Date < @cleanDate
END
ELSE IF @auditType = @MEDIUMMOVEMENT BEGIN
   DELETE XMediumMovement
   WHERE  Date < @cleanDate
END
ELSE IF @auditType = @GENERALACTION BEGIN
   DELETE XGeneralAction
   WHERE  Date < @cleanDate
END

END
'
)

-------------------------------------------------------------------------------
--
-- Triggers with updated audit strings
--
-------------------------------------------------------------------------------
IF EXISTS(SELECT 1 FROM sysobjects WHERE name = 'account$afterUpdate' AND objectproperty(id, 'ExecIsUpdateTrigger' ) = 1) 
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

-- Make sure that no media, bar codes, or active lists are using this account
-- if it is being deleted.
SELECT @id = i.AccountId
FROM   Inserted i
JOIN   Deleted d
  ON   d.AccountId = i.AccountId
WHERE  d.Deleted = 0 AND i.Deleted = 1
IF @@rowCount = 1 BEGIN
   IF EXISTS(SELECT 1 FROM BarCodePattern WHERE AccountId = @id) BEGIN
      SET @msg = ''This account is currently attached to at least one medium bar code pattern and may not be deleted.'' + @msgTag + ''>''
      EXECUTE error$raise @msg, 0, @tranName
      RETURN
   END
   IF EXISTS(SELECT 1 FROM Medium WHERE AccountId = @id) BEGIN
      SET @msg = ''This account may not be deleted because there are media registered to it.'' + @msgTag + ''>''
      EXECUTE error$raise @msg, 0, @tranName
      RETURN
   END
   IF EXISTS(SELECT 1 FROM SendList WHERE AccountId = @id AND Status NOT IN (1, 512)) BEGIN
      SET @msg = ''This account may not be deleted because it is attached to an active shipping list.'' + @msgTag + ''>''
      EXECUTE error$raise @msg, 0, @tranName
      RETURN
   END
   IF EXISTS(SELECT 1 FROM ReceiveList WHERE AccountId = @id AND Status IN (1,512)) BEGIN
      SET @msg = ''This account may not be deleted because it is attached to an active receiving list.'' + @msgTag + ''>''
      EXECUTE error$raise @msg, 0, @tranName
      RETURN
   END
   IF EXISTS(SELECT 1 FROM DisasterCodeList WHERE AccountId = @id AND Status NOT IN (1, 8)) BEGIN
      SET @msg = ''This account may not be deleted because it is attached to an active disaster recovery list.'' + @msgTag + ''>''
      EXECUTE error$raise @msg, 0, @tranName
      RETURN
   END
END

-- Add altered fields to audit message.  Certain fields may only be altered by the system.  Account name change should be last.
IF EXISTS (SELECT 1 FROM Inserted i JOIN Deleted d on d.AccountId = i.AccountId WHERE d.Global != i.Global) BEGIN
   INSERT @tblM (Message) SELECT case Global when 1 then ''Account granted global status'' else ''Global status revoked'' end FROM Inserted
END
IF EXISTS (SELECT 1 FROM Inserted i JOIN Deleted d on d.AccountId = i.AccountId WHERE d.Address1 != d.Address1) BEGIN
   INSERT @tblM (Message) SELECT ''Address (line 1) changed to '' + (SELECT Address1 FROM Inserted) 
END
IF EXISTS (SELECT 1 FROM Inserted i JOIN Deleted d on d.AccountId = i.AccountId WHERE d.Address2 != d.Address2) BEGIN
   INSERT @tblM (Message) SELECT case Len(Address2) when 0 then ''Address (line 2) removed'' else ''Address (line 2) changed to '' + Address2 end FROM Inserted
END
IF EXISTS (SELECT 1 FROM Inserted i JOIN Deleted d on d.AccountId = i.AccountId WHERE d.City != d.City) BEGIN
   INSERT @tblM (Message) SELECT case Len(City) when 0 then ''City removed'' else ''City changed to '' + City end FROM Inserted
END
IF EXISTS (SELECT 1 FROM Inserted i JOIN Deleted d on d.AccountId = i.AccountId WHERE d.State != d.State) BEGIN
   INSERT @tblM (Message) SELECT case Len(State) when 0 then ''State removed'' else ''State changed to '' + State end FROM Inserted
END
IF EXISTS (SELECT 1 FROM Inserted i JOIN Deleted d on d.AccountId = i.AccountId WHERE d.ZipCode != d.ZipCode) BEGIN
   INSERT @tblM (Message) SELECT case Len(ZipCode) when 0 then ''Zip code removed'' else ''Zip code changed to '' + ZipCode end FROM Inserted
END
IF EXISTS (SELECT 1 FROM Inserted i JOIN Deleted d on d.AccountId = i.AccountId WHERE d.Country != d.Country) BEGIN
   INSERT @tblM (Message) SELECT case Len(Country) when 0 then ''Country removed'' else ''Country changed to '' + Country end FROM Inserted
END
IF EXISTS (SELECT 1 FROM Inserted i JOIN Deleted d on d.AccountId = i.AccountId WHERE d.Contact != d.Contact) BEGIN
   INSERT @tblM (Message) SELECT case Len(Contact) when 0 then ''Contact removed'' else ''Contact changed to '' + Contact end FROM Inserted
END
IF EXISTS (SELECT 1 FROM Inserted i JOIN Deleted d on d.AccountId = i.AccountId WHERE d.PhoneNo != d.PhoneNo) BEGIN
   INSERT @tblM (Message) SELECT case Len(PhoneNo) when 0 then ''Phone number removed'' else ''Phone number changed to '' + PhoneNo end FROM Inserted
END
IF EXISTS (SELECT 1 FROM Inserted i JOIN Deleted d on d.AccountId = i.AccountId WHERE d.Email != d.Email) BEGIN
   INSERT @tblM (Message) SELECT case Len(Email) when 0 then ''Email address removed'' else ''Email address changed to '' + Email end FROM Inserted
END
IF EXISTS (SELECT 1 FROM Inserted i JOIN Deleted d on d.AccountId = i.AccountId WHERE d.Deleted != d.Deleted) BEGIN
   INSERT @tblM (Message, Detail) SELECT case Deleted when 0 then ''Account deleted'' else ''Account restored'' end, 3 FROM Inserted
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

-- Make sure that no types are container types
IF EXISTS(SELECT 1 FROM Inserted i JOIN MediumType m ON i.TypeId = m.TypeId WHERE m.Container = 1) BEGIN
   SET @msg = ''Type id given may not be of a container type.'' + @msgTag + ''>''
   RAISERROR(@msg, 16, 1)
   RETURN
END

-- If the largest position is not equal to the number of rows in the table,
-- raise an error
SELECT @maxPos = max(Position) 
FROM   Inserted
IF @rowCount != @maxPos BEGIN
   SET @msg = ''Maximum position value must be equal to number of bar code pattern records.'' + @msgTag + ''>''
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

-- Create audit strings
SET @i = 1
WHILE 1 = 1 BEGIN
   -- Get the string from the table
   SELECT @pattern = i.Pattern,
          @mediumType = m.TypeName,
          @accountName = a.AccountName
   FROM   Inserted i
   JOIN   MediumType m
     ON   m.TypeId = i.TypeId
   JOIN   Account a
     ON   a.AccountId = i.AccountId
   WHERE  i.Position = @i
   IF @@rowCount = 0 BREAK
   -- Insert the record
   INSERT XBarCodePattern(Detail,Login)
   VALUES(''Bar code format '' + @pattern + '' uses medium type '' + @mediumType + '' and account '' + @accountName, @login)
   SET @error = @@error
   IF @error != 0 BEGIN
      SET @msg = ''Error encountered while inserting bar code pattern audit record.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
      EXECUTE error$raise @msg, @error, @tranName
      RETURN
   END
   -- Increment counter
   SET @i = @i + 1
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
DECLARE @i int

SET @rowCount = @@rowcount
IF @rowCount = 0 RETURN

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=T''
SET @tranName = object_name(@@procid) + CAST(trigger_nestlevel(@@procid) as nvarchar(2))

-- Make sure that no types are non-container types
IF EXISTS(SELECT 1 FROM Inserted i JOIN MediumType m ON i.TypeId = m.TypeId WHERE m.Container = 0) BEGIN
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

-- Begin transaction
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

-- If the largest position is not equal to the number of rows in the table,
-- raise an error
SELECT @maxPos = max(Position) 
FROM   Inserted
IF @rowCount != @maxPos BEGIN
   SET @msg = ''Maximum position value must be equal to number of bar code pattern records.'' + @msgTag + ''>''
   EXECUTE error$raise @msg, 0, @tranName
   RETURN
END

-- Create audit strings
SET @i = 1
WHILE 1 = 1 BEGIN
   -- Get the string from the table
   SELECT @pattern = i.Pattern,
          @mediumType = m.TypeName
   FROM   Inserted i
   JOIN   MediumType m
     ON   m.TypeId = i.TypeId
   WHERE  i.Position = @i
   IF @@rowCount = 0 BREAK
   -- Insert the record
   INSERT XBarCodePattern(Detail,Login)
   VALUES(''Case bar code format '' + @pattern + '' uses medium type '' + @mediumType, @login)
   SET @error = @@error
   IF @error != 0 BEGIN
      SET @msg = ''Error encountered while inserting bar code pattern audit record.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
      EXECUTE error$raise @msg, @error, @tranName
      RETURN
   END
   -- Increment counter
   SET @i = @i + 1
END

-- Commit and return
COMMIT TRANSACTION
END
'
)

IF EXISTS(SELECT * FROM sysobjects WHERE name = 'disasterCodeList$afterInsert' AND objectproperty(id, 'ExecIsInsertTrigger' ) = 1) 
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'TRIGGER disasterCodeList$afterInsert
ON     DisasterCodeList
WITH ENCRYPTION
AFTER  INSERT
AS
BEGIN
DECLARE @msg nvarchar(255)        -- used to preformat error message
DECLARE @msgTag nvarchar(255)     -- used to hold first part of error message header
DECLARE @tranName nvarchar(255)   -- used to hold name of savepoint
DECLARE @audit nvarchar(1000)
DECLARE @account nvarchar(256)
DECLARE @listName nvarchar(10)
DECLARE @rowCount int            -- holds the number of rows in the Inserted table
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
   SET @msg = ''Batch insert into disaster recovery list table not allowed.'' + @msgTag + ''>''
   EXECUTE error$raise @msg, 0, @tranName
   RETURN
END

-- Get the caller login from the spidLogin table
IF len(dbo.string$GetSpidLogin()) = 0 BEGIN
   SET @msg = ''Login not found for auditing purposes.'' + @msgTag + ''>''
   EXECUTE error$raise @msg, 0, @tranName
   RETURN
END

-- Select the name from the Inserted table
SELECT @listName = ListName FROM Inserted
SELECT @audit = ''Disaster recovery list '' + @listName + '' created''

-- Get the account name
SELECT @account = AccountName
FROM   Account
WHERE  AccountId = (SELECT AccountId FROM Inserted)
IF @@rowcount != 0
   SET @audit = @audit + '' (account: '' + @account + '')''
ELSE
   SET @audit = @audit + '' (composite)''

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
   1, 
   @audit,
   dbo.string$GetSpidLogin()
)

SET @error = @@error
IF @error != 0 BEGIN
   SET @msg = ''Error encountered while inserting a disaster recovery list audit record.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
   EXECUTE error$raise @msg, @error, @tranName
   RETURN
END

COMMIT TRANSACTION
END
'
)

IF EXISTS(SELECT 1 FROM sysobjects WHERE name = 'disasterCodeList$afterUpdate' AND objectproperty(id, 'ExecIsUpdateTrigger' ) = 1) 
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
DECLARE @rowCount int             -- holds the number of rows in the Deleted table
DECLARE @status int
DECLARE @compositeId int
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

-- Status cannot be reduced
IF EXISTS
   (
   SELECT 1
   FROM   Deleted d
   JOIN   Inserted i
     ON   i.ListId = d.ListId
   WHERE  i.Status < d.Status
   )
BEGIN
   SET @msg = ''Status of disaster recovery list may not be reduced.'' + @msgTag + ''>''
   EXECUTE error$raise @msg, 0, @tranName
   RETURN
END

-- Get the caller login from the spidLogin table
IF len(dbo.string$GetSpidLogin()) = 0 BEGIN
   SET @msg = ''Caller login not found in spid login table.'' + @msgTag + ''>''
   EXECUTE error$raise @msg, 0, @tranName
   RETURN
END

-- Audit status changes.  Also, if the list is a discrete that belongs to a
-- composite, set the status of the composite.
SET @lastList = 0
WHILE 1 = 1 BEGIN
   SELECT TOP 1 @listName = i.ListName,
          @lastList = i.ListId,
          @status = i.Status,
          @compositeId = i.CompositeId
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
         SET @msgUpdate = ''List '' + @listName + '' upgraded to transmitted status''
      ELSE IF @status = 512
         SET @msgUpdate = ''List '' + @listName + '' upgraded to processed status''
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
      IF @compositeId IS NOT NULL BEGIN
         SELECT @status = min(Status)
         FROM   DisasterCodeList
         WHERE  CompositeId = @compositeId
         IF @status IS NOT NULL BEGIN
            UPDATE DisasterCodeList
            SET    Status = @status
            WHERE  ListId = @compositeId
            SET @error = @@error
            IF @error != 0 BEGIN
               SET @msg = ''Error encountered while updating composite disaster recovery list status.'' + @msgTag + '';Error='' + cast(@error as nvarchar(9)) + ''>''
               EXECUTE error$raise @msg, @error, @tranName
               RETURN
            END
         END
      END
   END
END          

-- Audit merges
SET @lastList = 0
WHILE 1 = 1 BEGIN
   SELECT TOP 1 @listName = i.ListName,
          @lastList = i.ListId,
          @compositeId = i.CompositeId
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
      FROM   DisasterCodeList
      WHERE  ListId = @compositeId
      -- Make sure that the composite is not discrete
      IF EXISTS(SELECT 1 FROM DisasterCodeList WHERE AccountId IS NOT NULL AND ListId = @compositeId) BEGIN
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
          @compositeId = d.CompositeId
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
      -- Get the composite list.  We don''t need to update the status of the
      -- composite here, because if a list can be extracted, we know that the
      -- list has submitted status.  This is particular to disaster code lists.
      SELECT @compositeName = ListName
      FROM   DisasterCodeList
      WHERE  ListId = @compositeId
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
      IF NOT EXISTS(SELECT 1 FROM DisasterCodeList WHERE CompositeId = @compositeId) BEGIN
         DELETE DisasterCodeList
         WHERE  ListId = @compositeId
         SET @error = @@error
         IF @error != 0 BEGIN
            SET @msg = ''Error encountered while deleting dissolved composite list.'' + @msgTag + '';Error='' + cast(@error as nvarchar(9)) + ''>''
            EXECUTE error$raise @msg, @error, @tranName
            RETURN
         END
      END
   END
END

COMMIT TRANSACTION
END
'
)

IF EXISTS(SELECT * FROM sysobjects WHERE name = 'disasterCodeListItem$afterUpdate' AND objectproperty(id, 'ExecIsUpdateTrigger' ) = 1) 
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
DECLARE @lastList int
DECLARE @serialNo nvarchar(32)
DECLARE @rowVersion rowversion
DECLARE @returnDate datetime
DECLARE @caseSerial bit
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

-- Audit is only necessary when there is one item being updated.  Multiple
-- items being updated means that an action was performed on the list as
-- a whole; the list audit record will suffice.
IF @rowCount = 1 BEGIN
   -- List name
   SELECT @listName = ListName
   FROM   DisasterCodeList
   WHERE  ListId = (SELECT ListId FROM Inserted)
   IF @@rowCount > 0 BEGIN
      -- Status updated
      SELECT @status = i.Status
      FROM   Inserted i
      JOIN   Deleted d
        ON   d.ItemId = i.ItemId
      WHERE  i.Status != d.Status
      -- Serial number
      SELECT @serialNo = m.SerialNo,
             @caseSerial = 0
      FROM   Inserted i
      JOIN   DisasterCodeListItemMedium dlim
        ON   dlim.ItemId = i.ItemId
      JOIN   Medium m
        ON   m.MediumId = dlim.MediumId
      IF @@rowCount = 0 BEGIN
         SELECT @serialNo = sc.SerialNo,
                @caseSerial = 1
         FROM   Inserted i
         JOIN   DisasterCodeListItemCase dlic
           ON   dlic.ItemId = i.ItemId
         JOIN   SealedCase sc
           ON   sc.CaseId = dlic.CaseId
      END
      IF @status = 1 BEGIN -- power(4,x)
         IF @caseSerial = 0
            SET @msgUpdate = ''Medium '' + @serialNo + '' removed from list''
         ELSE IF @caseSerial = 1
            SET @msgUpdate = ''Case '' + @serialNo + '' removed from list''
      END
   END
   -- Insert audit record
   IF len(coalesce(@msgUpdate,'''')) > 0 BEGIN
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
         5, 
         @msgUpdate, 
         dbo.string$GetSpidLogin()
      )
      SET @error = @@error
      IF @error != 0 BEGIN
         SET @msg = ''Error encountered while inserting disaster recovery list item audit record.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
         EXECUTE error$raise @msg, @error, @tranName
         RETURN
      END
   END
END

-- For each list in the update where an item was updated to a status other 
-- than removed, make sure that the discrete list status is equal to 
-- the lowest status among its non-removed items.
SET @lastList = 0
WHILE 1 = 1 BEGIN
   SELECT TOP 1 @lastList = i.ListId,
          @rowVersion = dl.RowVersion
   FROM   Inserted i
   JOIN   Deleted d
     ON   d.ItemId = i.ItemId
   JOIN   DisasterCodeList dl
     ON   dl.ListId = i.ListId
   WHERE  i.Status != 1 AND  -- power(4,x)
          d.Status != i.Status AND
          i.ListId > @lastList
   ORDER BY i.ListId ASC
   IF @@rowCount = 0
      BREAK
   ELSE BEGIN
      EXECUTE @returnValue = disasterCodeList$setStatus @lastList, @rowVersion
      IF @returnValue != 0 BEGIN
         ROLLBACK TRANSACTION @tranName
         COMMIT TRANSACTION
         RETURN
      END
   END
END

-- For each list in the update where an item was updated to removed status, 
-- delete the list if there are no more items on the list.  Otherwise update
-- the status of the list to change the rowversion.
SET @lastList = 0
WHILE 1 = 1 BEGIN
   SELECT TOP 1 @lastList = i.ListId,
          @rowVersion = dl.RowVersion
   FROM   Inserted i
   JOIN   Deleted d
     ON   d.ItemId = i.ItemId
   JOIN   DisasterCodeList dl
     ON   dl.ListId = i.ListId
   WHERE  i.Status = 1 AND  -- power(4,x)
          d.Status != 1 AND -- power(4,x)
          i.ListId > @lastList
   ORDER BY i.ListId ASC
   IF @@rowCount = 0
      BREAK
   ELSE BEGIN
      IF EXISTS(SELECT 1 FROM DisasterCodeListItem WHERE ListId = @lastList AND Status != 1) BEGIN -- power(4,x)
         EXECUTE @returnValue = disasterCodeList$setStatus @lastList, @rowVersion
      END
      ELSE BEGIN
         EXECUTE @returnValue = disasterCodeList$del @lastList, @rowVersion
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

IF EXISTS(SELECT * FROM sysobjects WHERE name = 'externalSiteLocation$afterInsert' AND objectproperty(id, 'ExecIsInsertTrigger' ) = 1) 
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'TRIGGER externalSiteLocation$afterInsert
ON     ExternalSiteLocation
WITH ENCRYPTION
AFTER  INSERT
AS
BEGIN
DECLARE @msg nvarchar(255)        -- used to preformat error message
DECLARE @msgTag nvarchar(255)     -- used to hold first part of error message header
DECLARE @tranName nvarchar(255)   -- used to hold name of savepoint
DECLARE @siteName nvarchar(256)   -- holds the name of the external site
DECLARE @rowCount int            -- holds the number of rows in the Inserted table
DECLARE @location bit
DECLARE @detail nvarchar(1000)            
DECLARE @error int            

SET @rowCount = @@rowcount
IF @rowCount = 0 RETURN

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=T''
SET @tranName = object_name(@@procid) + CAST(trigger_nestlevel(@@procid) as nvarchar(2))

-- Insert audit record
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

-- Make sure we do not have a batch insert
IF @rowCount > 1 BEGIN
   SET @msg = ''Batch insert into external site location table not allowed.'' + @msgTag + ''>''
   EXECUTE error$raise @msg, 0, @tranName
   RETURN
END

-- Get the caller login from the spidLogin table
IF len(dbo.string$GetSpidLogin()) = 0 BEGIN
   SET @msg = ''No login found for auditing purposes.'' + @msgTag + ''>''
   EXECUTE error$raise @msg, 0, @tranName
   RETURN
END

-- Select the name of the site from the Inserted table
SELECT @siteName = SiteName,
       @detail = case @location when 1 then ''External site created (resolves to enterprise)'' else ''External site created (resolves to vault)'' end
FROM   Inserted

INSERT XExternalSiteLocation
(
   Object, 
   Action, 
   Detail, 
   Login
)
VALUES
(
   @siteName, 
   1, 
   @detail,
   dbo.string$GetSpidLogin()
)

SET @error = @@error
IF @error != 0 BEGIN
   SET @msg = ''Error encountered while inserting an external site audit record.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
   EXECUTE error$raise @msg, @error, @tranName
   RETURN
END

COMMIT TRANSACTION
END
'
)

IF EXISTS(SELECT * FROM sysobjects WHERE name = 'externalSiteLocation$afterUpdate' AND objectproperty(id, 'ExecIsUpdateTrigger' ) = 1) 
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'TRIGGER externalSiteLocation$afterUpdate
ON     ExternalSiteLocation
WITH ENCRYPTION
AFTER  UPDATE
AS
BEGIN
DECLARE @msg nvarchar(255)         -- used to preformat error message
DECLARE @msgTag nvarchar(255)      -- used to hold first part of error message header
DECLARE @msgUpdate nvarchar(4000)  -- used to hold the updated fields
DECLARE @tranName nvarchar(255)    -- used to hold name of savepoint
DECLARE @siteName nvarchar(256)    -- holds the name of the external site
DECLARE @rowCount int             -- holds the number of rows in the Deleted table
DECLARE @del nvarchar(4000)
DECLARE @ins nvarchar(4000)
DECLARE @error int
DECLARE @tblM table (RowNo int identity (1,1), Message nvarchar(1000))
DECLARE @i int

SET @rowCount = @@rowcount
IF @rowCount = 0 RETURN

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=T''
SET @tranName = object_name(@@procid) + CAST(trigger_nestlevel(@@procid) as nvarchar(2))

-- Begin transaction
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

-- Make sure we do not have a batch delete
IF @rowCount > 1 BEGIN
   SET @msg = ''Batch update on external site location table not allowed.'' + @msgTag + ''>''
   EXECUTE error$raise @msg, 0, @tranName
   RETURN
END

-- Get the caller login from the spidLogin table
IF len(dbo.string$GetSpidLogin()) = 0 BEGIN
   SET @msg = ''No login found for auditing purposes.'' + @msgTag + ''>''
   EXECUTE error$raise @msg, 0, @tranName
   RETURN
END

-- Select the name of the site from the Deleted table
SELECT @i = 1, @siteName = SiteName FROM Deleted

-- Add altered fields to audit message
IF EXISTS (SELECT 1 FROM Inserted i JOIN Deleted d on d.SiteId = i.SiteId WHERE d.Location != i.Location) BEGIN
   INSERT @tblM (Message) SELECT ''Site now resolves to '' + case Location when 1 then '' the enterprise'' else '' the vault'' end FROM Inserted
END
IF EXISTS (SELECT 1 FROM Inserted i JOIN Deleted d on d.SiteId = i.SiteId WHERE d.SiteName != i.SiteName) BEGIN
   INSERT @tblM (Message) SELECT ''Site name changed to '''''' + (SELECT SiteName FROM Inserted) + ''''''''
END

-- Initialize counter
SELECT @i = min(RowNo) FROM @tblM

-- Insert audit records
WHILE 1 = 1 BEGIN
   SELECT @msgUpdate = Message
   FROM   @tblM
   WHERE  RowNo = @i
   IF @@rowcount = 0 
      BREAK
   ELSE BEGIN
      INSERT XExternalSiteLocation(Object, Action, Detail, Login)
      VALUES(@siteName, 2, @msgUpdate, dbo.string$GetSpidLogin())
      SET @error = @@error
      IF @error != 0 BEGIN
         SET @msg = ''Error encountered while inserting an external site audit record.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
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
SELECT @serialNo = SerialNo,
       @accountId = AccountId,
       @location = Location,
       @typeId = TypeId,
       @bSide = BSide 
FROM   Inserted

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

-- If there is a bside, make sure that it is unique and that the medium is not one-sided
-- or a container.
 IF len(@bSide) > 0 BEGIN
    IF EXISTS(SELECT 1 FROM Medium WHERE SerialNo = @bSide) BEGIN
       SET @msg = ''A medium currently exists with serial number '''''' + @serialNo + '''''' as its b-side.'' + @msgTag + ''>''
       EXECUTE error$raise @msg, 0, @tranName
       RETURN
    END
   IF EXISTS(SELECT 1 FROM Medium WHERE BSide = @bSide) BEGIN
      SET @msg = ''A medium currently exists with serial number '''''' + @bSide + '''''' as its b-side.'' + @msgTag + ''>''
      EXECUTE error$raise @msg, 0, @tranName
      RETURN
   END
   ELSE IF EXISTS(SELECT 1 FROM SealedCase WHERE SerialNo = @bSide) BEGIN
      SET @msg = ''A sealed case with serial number '''''' + @bSide + '''''' already exists.'' + @msgTag + ''>''
      EXECUTE error$raise @msg, 0, @tranName
      RETURN
   END
   ELSE IF EXISTS(SELECT 1 FROM SendListCase WHERE SerialNo = @bSide AND Cleared = 0) BEGIN
      SET @msg = ''A case with serial number '''''' + @bSide + '''''' exists on an active shipping list.'' + @msgTag + ''>''
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
IF NOT EXISTS
   (
   SELECT 1
   FROM   BarCodePattern
   WHERE  TypeId = @typeId AND
          AccountId = @accountId AND
          Position = (SELECT min(Position) 
                      FROM   BarCodePattern
                      WHERE  dbo.bit$RegexMatch(@serialNo,Pattern) = 1)
   )
BEGIN
   SET @msg = ''Account and/or medium type do not accord with bar code formats.'' + @msgTag + ''>''
   EXECUTE error$raise @msg, 0, @tranName
   RETURN
END

-- Create the insert message
IF @location = 0 
   SET @msgInsert = ''Medium '' + @serialNo + '' created at the vault''
ELSE
   SET @msgInsert = ''Medium '' + @serialNo + '' created at the enterprise''

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

IF EXISTS(SELECT * FROM sysobjects WHERE name = 'medium$afterUpdate' AND objectproperty(id, 'ExecIsUpdateTrigger' ) = 1) 
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
DECLARE @audit nvarchar(3000)  -- used to hold the updated fields
DECLARE @tranName nvarchar(255)    -- used to hold name of savepoint
DECLARE @tagInfo nvarchar(4000)    -- information from the SpidLogin table
DECLARE @listName nchar(10)
DECLARE @lastMoveDate datetime    -- holds the new last move date
DECLARE @caseName nvarchar(32)
DECLARE @serialNo nvarchar(32)
DECLARE @lastSerial nvarchar(32)
DECLARE @mediumId int
DECLARE @missing bit
DECLARE @hotStatus bit
DECLARE @itemStatus int
DECLARE @returnDate nvarchar(10)
DECLARE @bSide nvarchar(32)
DECLARE @notes nvarchar(4000)
DECLARE @listType int
DECLARE @location bit
DECLARE @typeId int
DECLARE @accountId int
DECLARE @compositeId int
DECLARE @vaultDiscrepancy int     -- holds the id of any vault discrepancy that should be resolved
DECLARE @rowCount int             -- holds the number of rows in the Deleted table
DECLARE @moveType int           -- method by which medium was moved
DECLARE @itemId int
DECLARE @caseId int
DECLARE @status int
DECLARE @error int
DECLARE @listId int
DECLARE @login nvarchar(32)
DECLARE @object nvarchar(64)
DECLARE @returnValue int
DECLARE @rowVersion rowversion
DECLARE @tblMedia table (RowNo int primary key identity(1,1), SerialNo nvarchar(32))
DECLARE @tblM table (RowNo int identity (1,1), Message nvarchar(1000))
DECLARE @i int
DECLARE @j int

SET @rowCount = @@rowcount
IF @rowCount = 0 RETURN

-- Initialize
SET @moveType = 1

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

-- Get the movement method -- if location changed, we''ll need this
IF CHARINDEX(''send'',@tagInfo) != 0 BEGIN
   SET @moveType = 2                     -- send list cleared
END
ELSE IF CHARINDEX(''receive'',@tagInfo) != 0 BEGIN
   SET @moveType = 3                     -- receive list cleared
END
ELSE IF CHARINDEX(''vault'',@tagInfo) != 0 BEGIN
   SET @moveType = 4                     -- vault inventory discrepancy resolved
END
ELSE IF CHARINDEX(''local'',@tagInfo) != 0 BEGIN
   SET @moveType = 5                     -- local inventory discrepancy resolved
END

-- Disallow movement or account change if a medium is active and 
-- beyond unverified on a send or receive list.
SELECT TOP 1 @serialNo = i.SerialNo,
       @listName = l.ListName,
       @location = i.Location,
       @accountId = i.AccountId,
       @typeId = i.TypeId,
       @mediumId = i.MediumId,
       @status = l.Status,
       @listType = case left(l.ListName,1) when ''S'' then 1 else 2 end
FROM   Inserted i
JOIN   Deleted d
  ON   i.MediumId = d.MediumId
JOIN   (
       SELECT TOP 1 sl.ListName as ''ListName'',
              sli.MediumId as ''MediumId'',
              sli.Status as ''Status''
       FROM   SendList sl
       JOIN   SendListItem sli
         ON   sli.ListId = sl.ListId
       WHERE  sli.Status IN (8,16,32,64,128,256) -- power(2,x)
       UNION
       SELECT TOP 1 rl.ListName,
              rli.MediumId,
              rli.Status
       FROM   ReceiveList rl
       JOIN   ReceiveListItem rli
         ON   rli.ListId = rl.ListId
       WHERE  rli.Status IN (8,16,32,64,128,256) -- power(2,x)
       )
       As l
  ON   l.MediumId = i.MediumId
WHERE  i.Location != d.Location OR i.AccountId != d.AccountId
ORDER BY i.SerialNo Asc
IF @@rowCount > 0 BEGIN
   IF EXISTS(SELECT 1 FROM Deleted WHERE MediumId = @mediumId AND @accountId != AccountId) BEGIN
      SET @msg = ''Medium '''''' + @serialNo + '''''' may not have its account changed because it appears on list '' + @listName + '', which has attained '' + dbo.string$statusName(@listType,@status) + '' status.'' + @msgTag + ''>''
      EXECUTE error$raise @msg, 0, @tranName
      RETURN
   END
   ELSE IF EXISTS(SELECT 1 FROM Deleted WHERE MediumId = @mediumId AND @location != Location) BEGIN
      -- Do not allow movement unless we are clearing a list.  This is usually cut and dried,
      -- as the user will have most of the time directly cleared a list.  There is one 
      -- exception, however, where an unrelated action will trigger a list to be cleared.
      -- This is when the last unverified tape on a send or receive list is marked missing or
      -- removed.  Since all other items are verified, the removal of the last item will
      -- trigger clearing of the list.  If the tape is on a receive list and the rest of
      -- the list is fully verified, then the list is being cleared in this manner.
      IF @moveType != 2 AND @moveType != 3 BEGIN
         IF left(@listName,2) = ''SD'' BEGIN
            SELECT @listId = sl.ListId, 
                   @compositeId = sl.CompositeId, 
                   @moveType = 2
            FROM   SendList sl
            JOIN   SendListItem sli
              ON   sli.ListId = sl.ListId
            WHERE  MediumId = @mediumId AND dbo.bit$statusEligible(1,sl.Status,512) = 1
            IF @@rowcount = 0 BEGIN
               SET @msg = ''Medium '''''' + @serialNo + '''''' may not be moved because it appears on list '' + @listName + '', which has attained '' + dbo.string$statusName(1,@status) + '' status.'' + @msgTag + ''>''
               EXECUTE error$raise @msg, 0, @tranName
               RETURN
            END
            ELSE BEGIN
               IF @compositeId IS NOT NULL BEGIN
                  SELECT @status = Status, @listName = ListName
                  FROM   SendList
                  WHERE  ListId = @compositeId
                  IF dbo.bit$statusEligible(1,@status,512) != 1 BEGIN
                     SET @msg = ''Medium '''''' + @serialNo + '''''' may not be moved because it appears on list '' + @listName + '', which has attained '' + dbo.string$statusName(1,@status) + '' status.'' + @msgTag + ''>''
                     EXECUTE error$raise @msg, 0, @tranName
                     RETURN
                  END
               END
            END
         END
         ELSE IF left(@listName,2) = ''RE'' BEGIN
            SELECT @listId = rl.ListId, 
                   @compositeId = rl.CompositeId, 
                   @moveType = 3
            FROM   ReceiveList rl
            JOIN   ReceiveListItem rli
              ON   rli.ListId = rl.ListId
            WHERE  MediumId = @mediumId AND dbo.bit$statusEligible(2,rl.Status,512) = 1
            IF @@rowcount = 0 BEGIN
               SET @msg = ''Medium '''''' + @serialNo + '''''' may not be moved because it appears on list '' + @listName + '', which has attained '' + dbo.string$statusName(2,@status) + '' status.'' + @msgTag + ''>''
               EXECUTE error$raise @msg, 0, @tranName
               RETURN
            END
            ELSE BEGIN
               IF @compositeId IS NOT NULL BEGIN
                  SELECT @status = Status, @listName = ListName
                  FROM   ReceiveList
                  WHERE  ListId = @compositeId
                  IF dbo.bit$statusEligible(2,@status,512) != 1 BEGIN
                     SET @msg = ''Medium '''''' + @serialNo + '''''' may not be moved because it appears on list '' + @listName + '', which has attained '' + dbo.string$statusName(2,@status) + '' status.'' + @msgTag + ''>''
                     EXECUTE error$raise @msg, 0, @tranName
                     RETURN
                  END
               END
            END
         END
      END
   END
END

-- Verify that any updated medium that resides inside a case has the
-- same hot status as the case itself.
SELECT TOP 1 @serialNo = i.SerialNo
FROM   Inserted i
JOIN   MediumSealedCase msc
  ON   msc.MediumId = i.MediumId
JOIN   SealedCase sc
  ON   sc.CaseId = msc.CaseId
WHERE  sc.HotStatus != i.HotStatus
ORDER BY i.SerialNo
IF @@rowCount > 0 BEGIN
   SET @msg = ''Because medium '''''' + @serialNo + '''''' is in a sealed case, it must have the same hot site status as the case itself.'' + @msgTag + ''>''
   EXECUTE error$raise @msg, 0, @tranName
   RETURN
END

-- Disallow change if tape is missing and location is changed
SELECT TOP 1 @serialNo = d.SerialNo
FROM   Inserted i
JOIN   Deleted d
  ON   d.MediumId = i.MediumId
WHERE  i.Missing = 1 AND
       i.Location != d.Location
IF @@rowCount != 0 BEGIN
   SET @msg = ''The location of medium '''''' + @serialNo + '''''' may not be changed because it is currently marked as missing.'' + @msgTag + ''>''
   EXECUTE error$raise @msg, 0, @tranName
   RETURN
END

-- Disallow change of return date if medium is in sealed case.  Because we may
-- receive a return date change even if the user did not actually change the
-- return date (i.e. the case return date is kept in the medium detail object
-- for display purposes and then submitted to the medium$upd procedure, we will
-- want to confirm, if the tape is in a sealed case, that the return date
-- submitted is the same as the return date on the sealed case.
SELECT TOP 1 @serialNo = i.SerialNo,
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
IF @@rowCount > 0 BEGIN
   SET @msg = ''Medium '''''' + @serialNo + '''''' may not have its return date changed because it resides in sealed case '''''' + @caseName + ''''''.'' + @msgTag + ''>''
   EXECUTE error$raise @msg, 0, @tranName
   RETURN
END

-- If an account or medium type has changed, verify that the account and medium type accord with the bar code formats.
IF EXISTS (SELECT 1 FROM Inserted i JOIN Deleted d ON d.MediumId = i.MediumId WHERE (i.TypeId != d.TypeId OR i.AccountId != d.AccountId)) BEGIN
   -- Check for disagreement
   SELECT TOP 1 @serialNo = i.SerialNo
   FROM   Inserted i
   JOIN   Deleted d
     ON   d.MediumId = i.MediumId
   WHERE (i.TypeId != d.TypeId OR i.AccountId != d.AccountId) AND
          cast(i.TypeId as nchar(15)) + ''|'' + cast(i.AccountId as nchar(15)) != (SELECT TOP 1 cast(p.TypeId as nchar(15)) + ''|'' + cast(p.AccountId as nchar(15)) FROM BarCodePattern p WHERE dbo.bit$RegexMatch(i.SerialNo,p.Pattern) = 1 ORDER BY p.Position asc)
   -- If there is one, raise an error
   IF @@rowcount != 0 BEGIN
      SET @msg = ''Account and/or medium type for medium '' + @serialNo + '' do not accord with bar code formats.'' + @msgTag + ''>''
      EXECUTE error$raise @msg, 0, @tranName
      RETURN
   END
END

-- Gather the media id numbers into the table
INSERT @tblMedia (SerialNo)
SELECT SerialNo
FROM   Inserted
ORDER  BY SerialNo Asc

-- Initialize counter
SELECT @i = 1

-- Loop through the media in the update
WHILE 1 = 1 BEGIN
   SELECT @mediumId = MediumId,
          @lastSerial = SerialNo,
          @location = Location,
          @lastMoveDate = LastMoveDate,
          @hotStatus = HotStatus,
          @missing = Missing,
          @returnDate = coalesce(convert(nvarchar(10),ReturnDate,120),''(None)''),
          @bSide = BSide,
          @notes = Notes,
          @typeId = TypeId,
          @accountId = AccountId
   FROM   Inserted
   WHERE  SerialNo = (SELECT SerialNo FROM @tblMedia WHERE RowNo = @i)
   IF @@rowCount = 0 BREAK
   -- Clear the message table
   DELETE FROM @tblM
   -- Hot site status
   IF EXISTS (SELECT 1 FROM Deleted WHERE MediumId = @mediumId AND HotStatus != @hotStatus) BEGIN
      INSERT @tblM (Message) SELECT case @hotStatus when 1 then ''Medium regarded as at hot site'' else ''Medium no longer regarded as at hot site'' end
   END
   -- Missing status
   IF EXISTS(SELECT 1 FROM Deleted WHERE MediumId = @mediumId AND Missing != @missing) BEGIN
      INSERT @tblM (Message) SELECT case @missing when 1 then ''Medium marked as missing'' else ''Medium marked as found'' end
   END
   -- Return date
   IF EXISTS(SELECT 1 FROM Deleted WHERE MediumId = @mediumId AND coalesce(convert(nvarchar(10),ReturnDate,120),''(None)'') != @returnDate) BEGIN
      INSERT @tblM (Message) SELECT ''Return date changed to '' + @returnDate
   END
   -- B-Side
   IF EXISTS(SELECT 1 FROM Deleted WHERE MediumId = @mediumId AND BSide != @bSide) BEGIN
      -- If there is a bside, make sure that it is unique
      IF len(@bSide) > 0 BEGIN
         IF EXISTS(SELECT 1 FROM Medium WHERE SerialNo = @bSide) BEGIN
            SET @msg = ''A medium currently exists with serial number '''''' + @serialNo + '''''' as its b-side.'' + @msgTag + ''>''
            EXECUTE error$raise @msg, 0, @tranName
            RETURN
         END
         IF EXISTS(SELECT 1 FROM Medium WHERE BSide = @bSide) BEGIN
            SET @msg = ''A medium currently exists with serial number '''''' + @bSide + '''''' as its b-side.'' + @msgTag + ''>''
            EXECUTE error$raise @msg, 0, @tranName
            RETURN
         END
         ELSE IF EXISTS(SELECT 1 FROM SealedCase WHERE SerialNo = @bSide) BEGIN
            SET @msg = ''A sealed case with serial number '''''' + @bSide + '''''' already exists.'' + @msgTag + ''>''
            EXECUTE error$raise @msg, 0, @tranName
            RETURN
         END
         ELSE IF EXISTS(SELECT 1 FROM SendListCase WHERE SerialNo = @bSide AND Cleared = 0) BEGIN
            SET @msg = ''A case with serial number '''''' + @bSide + '''''' exists on an active shipping list.'' + @msgTag + ''>''
            EXECUTE error$raise @msg, 0, @tranName
            RETURN
         END
         ELSE IF EXISTS(SELECT 1 FROM MediumType WHERE TypeId = @typeId AND (Container = 1 OR TwoSided = 0)) BEGIN
            SET @msg = ''A b-side serial number may not be assigned to a medium of one-sided type or to a container.'' + @msgTag + ''>''
            EXECUTE error$raise @msg, 0, @tranName
            RETURN
         END
      END
      -- Insert audit message
      INSERT @tblM (Message) SELECT ''B-side changed to '' + @bside
   END
   -- Medium type
   IF EXISTS(SELECT 1 FROM Deleted WHERE MediumId = @mediumId AND TypeId != @typeId) BEGIN
      INSERT @tblM (Message) SELECT ''Medium type changed to '' + (SELECT TypeName FROM MediumType WHERE TypeId = @typeId)
   END
   -- Account
   IF EXISTS(SELECT 1 FROM Deleted WHERE MediumId = @mediumId AND AccountId != @accountId) BEGIN
      INSERT @tblM (Message) SELECT ''Account changed to '' + (SELECT AccountName FROM Account WHERE AccountId = @accountId)
   END
   -- Serial number
   IF EXISTS (SELECT 1 FROM Deleted WHERE mediumId = @mediumId AND SerialNo != @lastSerial) BEGIN
      INSERT @tblM (Message) SELECT ''Serial number changed to '''''' + @lastSerial + ''''''''
   END
   -- Initialize audit variables
   SELECT @j = min(RowNo) FROM @tblM
   SELECT @object = SerialNo FROM Deleted
   -- Insert audit records
   WHILE 1 = 1 BEGIN
      SELECT @audit = Message
      FROM   @tblM
      WHERE  RowNo = @j
      IF @@rowcount = 0 
         BREAK
      ELSE BEGIN
         INSERT XMedium(Object, Action, Detail, Login)
         VALUES(@object, 2, @audit, dbo.string$GetSpidLogin())
         SET @error = @@error
         IF @error != 0 BEGIN
            SET @msg = ''Error inserting a medium audit record.'' + @msgTag + '';Error='' + cast(@error as nvarchar(9)) + ''>''
            EXECUTE error$raise @msg, @error, @tranName
            RETURN
         END
      END
      -- Counter
      SET @j = @j + 1
   END
   -- If the medium serial number was changed, then we should delete any inventory
   -- discrepancies for the medium
   IF EXISTS (SELECT 1 FROM Deleted WHERE mediumId = @mediumId AND SerialNo != @lastSerial) BEGIN
      DELETE VaultDiscrepancyResidency
      WHERE  MediumId = @mediumId
      SET @error = @@error
      IF @error != 0 BEGIN
         SET @msg = ''Error encountered while deleting a residency vault inventory discrepancy.'' + @msgTag + '';Error='' + cast(@error as nvarchar(9)) + ''>''
         EXECUTE error$raise @msg, @error, @tranName
         RETURN
      END
      DELETE VaultDiscrepancyMediumType
      WHERE  MediumId = @mediumId
      SET @error = @@error
      IF @error != 0 BEGIN
         SET @msg = ''Error encountered while deleting a medium type vault inventory discrepancy.'' + @msgTag + '';Error='' + cast(@error as nvarchar(9)) + ''>''
         EXECUTE error$raise @msg, @error, @tranName
         RETURN
      END
      DELETE VaultDiscrepancyAccount
      WHERE  MediumId = @mediumId
      SET @error = @@error
      IF @error != 0 BEGIN
         ROLLBACK TRANSACTION @tranName
         COMMIT TRANSACTION
         SET @msg = ''Error encountered while deleting an account vault inventory discrepancy.'' + @msgTag + '';Error='' + cast(@error as nvarchar(9)) + ''>''
         EXECUTE error$raise @msg, @error, @tranName
         RETURN
      END
   END
   -- If the medium type was altered, then we may resolve a medium type vault discrepancy
   IF EXISTS (SELECT 1 FROM Deleted WHERE mediumId = @mediumId AND TypeId != @typeId) BEGIN
      SELECT @vaultDiscrepancy = vdm.ItemId
      FROM   VaultDiscrepancyMediumType vdm
      JOIN   Inserted i
        ON   vdm.VaultType = i.TypeId
      WHERE  vdm.MediumId = @mediumId
      IF @@rowCount != 0 BEGIN
         EXECUTE @returnValue = vaultDiscrepancyMediumType$resolve @vaultDiscrepancy, 1
         IF @returnValue != 0 BEGIN
            ROLLBACK TRANSACTION @tranName   
            COMMIT TRANSACTION
            RETURN
         END
      END
   END
   -- If the account was altered, then we may resolve an account vault discrepancy
   IF EXISTS (SELECT 1 FROM Deleted WHERE mediumId = @mediumId AND AccountId != @accountId) BEGIN
      SELECT @vaultDiscrepancy = vda.ItemId
      FROM   VaultDiscrepancyAccount vda
      JOIN   Inserted i
        ON   vda.VaultAccount = i.AccountId
      WHERE  vda.MediumId = @mediumId
      IF @@rowCount != 0 BEGIN
         EXECUTE @returnValue = vaultDiscrepancyAccount$resolve @vaultDiscrepancy, 1
         IF @returnValue != 0 BEGIN
            ROLLBACK TRANSACTION @tranName   
            COMMIT TRANSACTION
            RETURN
         END
      END
   END
   -- If the medium is marked as missing, then we should resolve any 
   -- residency inventory discrepancy for this medium.  We should also
   -- disallow missing status if the medium his verified on a send or 
   -- receive list.  (If not verified, remove it from the list.)
   IF EXISTS (SELECT 1 FROM Deleted WHERE mediumId = @mediumId AND Missing != @missing) AND @missing = 1 BEGIN
      SELECT @vaultDiscrepancy = ItemId
      FROM   VaultDiscrepancyResidency
      WHERE  MediumId = @mediumId
      IF @@rowCount != 0 BEGIN
         EXECUTE @returnValue = vaultDiscrepancyResidency$resolve @vaultDiscrepancy, 2
         IF @returnValue != 0 BEGIN
            ROLLBACK TRANSACTION @tranName   
            COMMIT TRANSACTION
            RETURN
         END
      END
      -- Check send lists or receive lists
      IF @location = 1 BEGIN
         SELECT @itemId = ItemId,
                @itemStatus = Status,
                @rowVersion = RowVersion
         FROM   SendListItem
         WHERE  Status > 1 AND Status != 512 AND MediumId = @mediumId
         IF @@rowCount != 0 BEGIN
            IF @itemStatus IN (8, 256) BEGIN
               SET @msg = ''Medium cannot be marked missing when it has been verified on an active shipping list.'' + @msgTag + ''>''
               EXECUTE error$raise @msg, 0, @tranName
               RETURN
            END
            ELSE BEGIN
               -- Remove item from send list
               EXECUTE @returnValue = sendListItem$remove @itemId, @rowVersion, 1
   	         IF @returnValue != 0 BEGIN
   	            ROLLBACK TRANSACTION @tranName   
   	            COMMIT TRANSACTION
   	            RETURN
   	         END
            END
         END
      END
      ELSE BEGIN
         SELECT @itemId = ItemId,
                @itemStatus = Status,
                @rowVersion = RowVersion
         FROM   ReceiveListItem
         WHERE  Status > 1 AND Status != 512 AND MediumId = @mediumId
         IF @@rowCount != 0 BEGIN
            IF @itemStatus IN (8, 256) BEGIN
               SET @msg = ''Medium cannot be marked missing when it is has been verified on an active receiving list.'' + @msgTag + ''>''
               EXECUTE error$raise @msg, 0, @tranName
               RETURN
            END
            ELSE BEGIN
               -- Remove item from receive list
	            EXECUTE @returnValue = receiveListItem$remove @itemId, @rowVersion, 0, 1
		         IF @returnValue != 0 BEGIN
		            ROLLBACK TRANSACTION @tranName   
		            COMMIT TRANSACTION
		            RETURN
		         END
            END
         END
      END
   END
   -- If the location was altered, then make an entry in the special 
   -- medium movement audit table.  We should also resolve any inventory
   -- discrepancy for this medium.
   IF EXISTS (SELECT 1 FROM Deleted WHERE MediumId = @mediumId AND Location != @location) BEGIN
      INSERT XMediumMovement(Date, Object, Direction, Method, Login)
      VALUES(@lastMoveDate, @lastSerial, @location, @moveType, dbo.string$GetSpidLogin())
      SET @error = @@error
      IF @error != 0 BEGIN
         SET @msg = ''Error inserting a row into the XMediumMovement table.'' + @msgTag + '';Error='' + cast(@error as nvarchar(9)) + ''>''
         EXECUTE error$raise @msg, @error, @tranName
         RETURN
      END
      -- If the medium was moved to the enterprise,
      -- remove it from sealed case.
      IF @location = 1 BEGIN
         SELECT @caseId = CaseId
         FROM   MediumSealedCase
         WHERE  MediumId = @mediumId
         IF @@rowCount > 0 BEGIN
            EXECUTE @returnValue = mediumSealedCase$del @caseId, @mediumId
            IF @returnValue != 0 BEGIN
               ROLLBACK TRANSACTION @tranName   
               COMMIT TRANSACTION
               RETURN
            END
         END
      END
      -- Resolve vault discrepancy
      SELECT @vaultDiscrepancy = ItemId
      FROM   VaultDiscrepancyResidency
      WHERE  MediumId = @mediumId
      IF @@rowCount != 0 BEGIN
         EXECUTE @returnValue = vaultDiscrepancyResidency$resolve @vaultDiscrepancy, 1
         IF @returnValue != 0 BEGIN
            ROLLBACK TRANSACTION @tranName   
            COMMIT TRANSACTION
            RETURN
         END
      END
   END
   -- If location or account has been altered, remove submitted entries 
   -- from lists of any type.
   IF EXISTS
      (
      SELECT 1
      FROM   Deleted
      WHERE  MediumId = @mediumId AND (Location != @location OR AccountId != @accountId)
      )
   BEGIN
      -- Remove any unverified send list items
      SELECT @itemId = ItemId, @rowVersion = RowVersion
      FROM   SendListItem
      WHERE  MediumId = @mediumId AND Status = 2 -- power(2,1)
      IF @@rowCount > 0 BEGIN
         EXECUTE @returnValue = sendListItem$remove @itemId, @rowVersion
         IF @returnValue != 0 BEGIN
            ROLLBACK TRANSACTION @tranName
            COMMIT TRANSACTION
            RETURN
         END
      END
      -- Remove any submitted receive list items
      SELECT @itemId = ItemId, @rowVersion = RowVersion
      FROM   ReceiveListItem
      WHERE  MediumId = @mediumId AND Status = 2 -- power(2,1)
      IF @@rowCount > 0 BEGIN
         EXECUTE @returnValue = receiveListItem$remove @itemId, @rowVersion
         IF @returnValue != 0 BEGIN
            ROLLBACK TRANSACTION @tranName
            COMMIT TRANSACTION
            RETURN
         END
      END
      -- Remove any submitted disaster code list items
      SELECT @itemId = dli.ItemId, @rowVersion = dli.RowVersion
      FROM   DisasterCodeListItem dli
      JOIN   DisasterCodeListItemMedium dlim
        ON   dlim.ItemId = dli.ItemId
      WHERE  dlim.MediumId = @mediumId AND dli.Status = 2 -- power(2,1)
      IF @@rowCount > 0 BEGIN
         EXECUTE @returnValue = disasterCodeListItem$remove @itemId, @rowVersion
         IF @returnValue != 0 BEGIN
            ROLLBACK TRANSACTION @tranName
            COMMIT TRANSACTION
            RETURN
         END
      END
   END
   -- Increment counter
   SELECT @i = @i + 1
END

-- Commit transaction
COMMIT TRANSACTION
END
'
)

IF EXISTS(SELECT * FROM sysobjects WHERE name = 'mediumSealedCase$afterDelete' AND objectproperty(id, 'ExecIsDeleteTrigger' ) = 1) 
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'TRIGGER mediumSealedCase$afterDelete
ON     MediumSealedCase
WITH ENCRYPTION
AFTER  DELETE
AS
BEGIN
DECLARE @msg nvarchar(255)        -- used to preformat error message
DECLARE @msgTag nvarchar(255)     -- used to hold first part of error message header
DECLARE @tranName nvarchar(255)   -- used to hold name of savepoint
DECLARE @caseName nvarchar(32)
DECLARE @lastSerial nvarchar(32)
DECLARE @login nvarchar(32)
DECLARE @rowCount int             -- holds the number of rows in the Inserted table
DECLARE @lastCase int
DECLARE @error int

SET @rowCount = @@rowcount
IF @rowCount = 0 RETURN

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=T''
SET @tranName = object_name(@@procid) + CAST(trigger_nestlevel(@@procid) as nvarchar(2))

-- Begin the transaction
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

-- Only insert audit record if not clearing a list
IF charindex(''clear'', dbo.string$GetSpidInfo()) = 0 BEGIN
   -- Get the caller login from the spidLogin table
   SELECT @login = dbo.string$GetSpidLogin()
   IF len(@login) = 0 BEGIN
      SET @msg = ''Login not found for auditing purposes.'' + @msgTag + ''>''
      EXECUTE error$raise @msg, 0, @tranName
      RETURN
   END
   -- For each item, mark it as removed from list
   SET @lastSerial = ''''
   WHILE 1 = 1 BEGIN
      SELECT TOP 1 @lastSerial = m.SerialNo,
             @caseName = s.SerialNo
      FROM   Medium m
      JOIN   Deleted d
        ON   d.MediumId = m.MediumId
      JOIN   SealedCase s
        ON   s.CaseId = d.CaseId
      WHERE  m.SerialNo > @lastSerial
      ORDER BY m.SerialNo asc
      IF @@rowCount = 0
         BREAK
      ELSE BEGIN
         -- Insert audit record
         INSERT XSealedCase
         (
            Object, 
            Action, 
            Detail, 
            Login
         )
         VALUES
         (
            @caseName, 
            5, 
            ''Medium '' + @lastSerial + '' removed from case'',
            @login
         )
         SET @error = @@error
         IF @error != 0 BEGIN
            SET @msg = ''Error encountered while inserting sealed case audit record.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
            EXECUTE error$raise @msg, @error, @tranName
            RETURN
         END
      END
   END
END

-- For each case mentioned, if no items are left in the case then 
-- delete the case.
SET @lastCase = 0
WHILE 1 = 1 BEGIN
   SELECT TOP 1 @lastCase = CaseId 
   FROM   Deleted 
   WHERE  CaseId > @lastCase
   ORDER BY CaseId
   IF @@rowCount = 0
      BREAK
   ELSE BEGIN
      IF NOT EXISTS(SELECT 1 FROM MediumSealedCase WHERE CaseId = @lastCase) BEGIN
         DELETE SealedCase 
         WHERE  CaseId = @lastCase
         SELECT @error = @@error
         IF @error != 0 BEGIN
            SET @msg = ''Error encountered while deleting empty sealed case.'' + '';Error='' + cast(@error as nvarchar(50)) + ''>''
            EXECUTE error$raise @msg, @error, @tranName
            RETURN
         END
      END
   END
END

-- Commit the transaction
COMMIT TRANSACTION
END
'
)

IF EXISTS(SELECT * FROM sysobjects WHERE name = 'mediumSealedCase$afterInsert' AND objectproperty(id, 'ExecIsInsertTrigger' ) = 1) 
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'TRIGGER mediumSealedCase$afterInsert
ON     MediumSealedCase
WITH ENCRYPTION
AFTER  INSERT
AS
BEGIN
DECLARE @msg nvarchar(255)        -- used to preformat error message
DECLARE @msgTag nvarchar(255)     -- used to hold first part of error message header
DECLARE @tranName nvarchar(255)   -- used to hold name of savepoint
DECLARE @rowCount int            -- holds the number of rows in the Inserted table
DECLARE @mediumSerial nvarchar(32)
DECLARE @caseSerial nvarchar(32)
DECLARE @mediumId int
DECLARE @caseId int
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
   SET @msg = ''Batch insert into sealed case medium table not allowed.'' + @msgTag + ''>''
   EXECUTE error$raise @msg, 0, @tranName
   RETURN
END

-- Get the caller login from the spidLogin table
IF len(dbo.string$GetSpidLogin()) = 0 BEGIN
   SET @msg = ''Caller login not found in spid login table.'' + @msgTag + ''>''
   EXECUTE error$raise @msg, 0, @tranName
   RETURN
END

-- Select the case name and medium serial number
SELECT @caseId = CaseId FROM Inserted
SELECT @mediumId = MediumId FROM Inserted
SELECT @caseSerial = SerialNo FROM SealedCase WHERE CaseId = @caseId
SELECT @mediumSerial = SerialNo FROM Medium WHERE MediumId = @mediumId

-- Insert audit record
INSERT XSealedCase
(
   Object, 
   Action, 
   Detail, 
   Login
)
VALUES
(
   @caseSerial, 
   4, 
   ''Medium '' + @mediumSerial + '' inserted into case'',
   dbo.string$GetSpidLogin()
)

SET @error = @@error
IF @error != 0 BEGIN
   SET @msg = ''Error inserting a row into the sealed case audit table.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
   EXECUTE error$raise @msg, @error, @tranName
   RETURN
END

-- Update the medium so that its hot status is that of the sealed case
UPDATE Medium
SET    HotStatus = (SELECT HotStatus 
                    FROM   SealedCase 
                    WHERE  CaseId = @caseId)
WHERE  MediumId = @mediumId
SET @error = @@error
IF @error != 0 BEGIN
   SET @msg = ''Error updating hot status when inserting medium into sealed case.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
   EXECUTE error$raise @msg, @error, @tranName
   RETURN
END

COMMIT TRANSACTION
END
'
)

IF EXISTS(SELECT * FROM sysobjects WHERE name = 'operator$afterUpdate' AND objectproperty(id, 'ExecIsUpdateTrigger' ) = 1) 
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'TRIGGER operator$afterUpdate
ON     Operator
WITH ENCRYPTION
AFTER  UPDATE
AS
BEGIN
DECLARE @msg nvarchar(255)         -- used to preformat error message
DECLARE @msgTag nvarchar(255)      -- used to hold first part of error message header
DECLARE @msgUpdate nvarchar(3000)  -- used to hold the updated fields
DECLARE @tranName nvarchar(255)    -- used to hold name of savepoint
DECLARE @login nvarchar(32)        -- holds the name of the updated operator  
DECLARE @rowCount int              -- holds the number of rows in the Deleted table
DECLARE @operatorName nvarchar(256)
DECLARE @error int
DECLARE @tblM table (RowNo int identity (1,1), Message nvarchar(1000))
DECLARE @i int

SET @rowCount = @@rowcount
IF @rowCount = 0 RETURN

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=T''
SET @tranName = object_name(@@procid) + CAST(trigger_nestlevel(@@procid) as nvarchar(2))

-- Begin transaction
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

-- Make sure we do not have a batch delete
IF @rowCount > 1 BEGIN
   SET @msg = ''Batch update on operator table not allowed.'' + @msgTag + ''>''
   EXECUTE error$raise @msg, 0, @tranName
   RETURN
END

-- Get the caller login from the spidLogin table
IF len(dbo.string$GetSpidLogin()) = 0 BEGIN
   SET @msg = ''Caller login not found in spid login table.'' + @msgTag + ''>''
   EXECUTE error$raise @msg, 0, @tranName
   RETURN
END

-- Add altered fields to audit message
IF EXISTS (SELECT 1 FROM Inserted i JOIN Deleted d on d.OperatorId = i.OperatorId WHERE d.OperatorName != i.OperatorName) BEGIN
   INSERT @tblM (Message) SELECT ''Operator name changed to '''''' + (SELECT OperatorName FROM Inserted) + ''''''''
END
IF EXISTS (SELECT 1 FROM Inserted i JOIN Deleted d on d.OperatorId = i.OperatorId WHERE d.Password != i.Password OR d.Salt != i.Salt) BEGIN
   INSERT @tblM (Message) SELECT ''Password changed''
END
IF EXISTS (SELECT 1 FROM Inserted i JOIN Deleted d on d.OperatorId = i.OperatorId WHERE d.Role != i.Role) BEGIN
   INSERT @tblM (Message) SELECT ''Security role changed to '' + case Role when 8 then ''Viewer'' when 128 then ''Auditor'' when 2048 then ''Librarian'' when 32768 then ''Administrator'' else ''???'' end FROM Inserted
END
IF EXISTS (SELECT 1 FROM Inserted i JOIN Deleted d on d.OperatorId = i.OperatorId WHERE d.PhoneNo != i.PhoneNo) BEGIN
   INSERT @tblM (Message) SELECT ''Phone number changed to '''''' + (SELECT PhoneNo FROM Inserted) + ''''''''
END
IF EXISTS (SELECT 1 FROM Inserted i JOIN Deleted d on d.OperatorId = i.OperatorId WHERE d.Email != i.Email) BEGIN
   INSERT @tblM (Message) SELECT ''Email address changed to '''''' + (SELECT Email FROM Inserted) + ''''''''
END
IF EXISTS (SELECT 1 FROM Inserted i JOIN Deleted d on d.OperatorId = i.OperatorId WHERE d.Login != i.Login) BEGIN
   INSERT @tblM (Message) SELECT ''Login changed to '''''' + (SELECT Login FROM Inserted) + ''''''''
END

-- Select the login of the operator from the Deleted table
SELECT @i = min(RowNo) FROM @tblM
SELECT @login = Login FROM Deleted

-- Insert audit records
WHILE 1 = 1 BEGIN
   SELECT @msgUpdate = Message
   FROM   @tblM
   WHERE  RowNo = @i
   IF @@rowcount = 0 
      BREAK
   ELSE BEGIN
      INSERT XOperator (Object, Action, Detail, Login)
      VALUES(@login, 2, @msgUpdate, dbo.string$GetSpidLogin())
      SET @error = @@error
      IF @error != 0 BEGIN
         SET @msg = ''Error encountered while inserting an operator audit record.'' + @msgTag + '';Error='' + cast(@error as nvarchar(10)) + ''>''
         EXECUTE error$raise @msg, @error, @tranName
         RETURN
      END
   END
   -- Counter
   SET @i = @i + 1
END

-- Login update
IF EXISTS (SELECT 1 FROM Inserted i JOIN Deleted d ON d.OperatorId = i.OperatorId WHERE d.LastLogin != i.LastLogin) BEGIN
   SELECT @login = Login, @msgUpdate = Login + '' ('' + OperatorName + '') '' + ''logged in'' FROM Inserted
   INSERT XOperator(Object, Action, Detail, Login)
   VALUES(@login, 13, @msgUpdate, @login)
   SET @error = @@error
   IF @error != 0 BEGIN
      SET @msg = ''Error encountered while inserting an operator audit record.'' + @msgTag + '';Error='' + cast(@error as nvarchar(10)) + ''>''
      EXECUTE error$raise @msg, @error, @tranName
      RETURN
   END
END

COMMIT TRANSACTION
END
'
)

IF EXISTS(SELECT * FROM sysobjects WHERE name = 'preference$afterInsert' AND objectproperty(id, 'ExecIsInsertTrigger' ) = 1)
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'TRIGGER preference$afterInsert
ON     Preference
WITH ENCRYPTION
AFTER  INSERT
AS
BEGIN
DECLARE @msg nvarchar(255)        -- used to preformat error message
DECLARE @msgTag nvarchar(255)     -- used to hold first part of error message header
DECLARE @tranName nvarchar(255)   -- used to hold name of savepoint
DECLARE @value nvarchar(64)            
DECLARE @rowCount int             -- holds the number of rows in the Inserted table
DECLARE @error int            
DECLARE @audit nvarchar(1000)
DECLARE @key nvarchar(1000)

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
   SET @msg = ''Batch insert into preference table not allowed.'' + @msgTag + ''>''
   EXECUTE error$raise @msg, 0, @tranName
   RETURN
END

-- Get the caller login from the spidLogin table
IF len(dbo.string$GetSpidLogin()) = 0 BEGIN
   SET @msg = ''No login found for auditing purposes.'' + @msgTag + ''>''
   EXECUTE error$raise @msg, 0, @tranName
   RETURN
END

-- Select the key and value from the Inserted table
SELECT @value = Value,
       @key = case KeyNo
              when 1 then ''Employ TMS return dates on shipping lists''
              when 2 then ''Ignore unrecognized external sites''
              when 3 then ''Write TMS data set name to Notes field''
              when 4 then ''Consider cases on shipping list verification''
              when 5 then ''Employ standard vault bar code editing''
              when 6 then ''Exclude media on active lists during reconcile''
              when 7 then ''Exclude media on today''''s lists during reconcile''
              when 8 then ''Declare accounts when creating lists''
              when 9 then ''Line items to display per page''
              else '''' end
FROM   Inserted

-- Insert audit record
INSERT XGeneralAction(Detail, Login)
VALUES(''Preference ('' + @key + '') set to '' + @value, dbo.string$GetSpidLogin())

SET @error = @@error
IF @error != 0 BEGIN
   SET @msg = ''Error encountered while inserting a general action audit record.'' + @msgTag + '';Error='' + cast(@error as nvarchar(10)) + ''>''
   EXECUTE error$raise @msg, @error, @tranName
   RETURN
END

COMMIT TRANSACTION
END
'
)

IF EXISTS(SELECT * FROM sysobjects WHERE name = 'preference$afterUpdate' AND objectproperty(id, 'ExecIsUpdateTrigger' ) = 1) 
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'TRIGGER preference$afterUpdate
ON     Preference
WITH ENCRYPTION
AFTER  UPDATE
AS
BEGIN
DECLARE @msg nvarchar(255)        -- used to preformat error message
DECLARE @msgTag nvarchar(255)     -- used to hold first part of error message header
DECLARE @tranName nvarchar(255)   -- used to hold name of savepoint
DECLARE @value nvarchar(64)            
DECLARE @rowCount int             -- holds the number of rows in the Inserted table
DECLARE @error int            
DECLARE @key nvarchar(1000)

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
   SET @msg = ''Batch update on preference table not allowed.'' + @msgTag + ''>''
   EXECUTE error$raise @msg, 0, @tranName
   RETURN
END

-- Get the caller login from the spidLogin table
IF len(dbo.string$GetSpidLogin()) = 0 BEGIN
   SET @msg = ''No login found for auditing purposes.'' + @msgTag + ''>''
   EXECUTE error$raise @msg, 0, @tranName
   RETURN
END

-- Select the key and value from the Inserted table
SELECT @value = i.Value,
       @key = case i.KeyNo
              when 1 then ''Employ TMS return dates on shipping lists''
              when 2 then ''Ignore unrecognized external sites''
              when 3 then ''Write TMS data set name to Notes field''
              when 4 then ''Consider cases on shipping list verification''
              when 5 then ''Employ standard vault bar code editing''
              when 6 then ''Exclude media on active lists during reconcile''
              when 7 then ''Exclude media on today''''s lists during reconcile''
              when 8 then ''Declare accounts when creating lists''
              when 9 then ''Line items to display per page''
              else '''' end
FROM   Inserted i
JOIN   Deleted d
  ON   d.KeyNo = i.KeyNo
WHERE  d.Value != i.Value

-- Insert audit record
IF len(@key) != 0 BEGIN
   INSERT XGeneralAction(Detail, Login)
   VALUES(''Preference ('' + @key + '') set to '' + @value, dbo.string$GetSpidLogin())
   
   SET @error = @@error
   IF @error != 0 BEGIN
      SET @msg = ''Error encountered while updating a general action audit record.'' + @msgTag + '';Error='' + cast(@error as nvarchar(10)) + ''>''
      EXECUTE error$raise @msg, @error, @tranName
      RETURN
   END
END

COMMIT TRANSACTION
END
'
)

IF EXISTS(SELECT * FROM sysobjects WHERE name = 'productLicense$AfterInsert' AND objectproperty(id, 'ExecIsInsertTrigger' ) = 1) 
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'TRIGGER productLicense$AfterInsert
ON     ProductLicense
WITH ENCRYPTION
AFTER  INSERT
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

-- Make sure we do not have a batch insert
IF @rowCount > 1 BEGIN
   SET @msg = ''Batch insert into product license table not allowed.'' + @msgTag + ''>''
   EXECUTE error$raise @msg, 0
   RETURN
END

-- Make sure the type is not 4,5,6
SELECT @typeId = cast(TypeId as nvarchar(64)) FROM Inserted
IF @typeId IN (4,5,6) RETURN

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=T''
SET @tranName = object_name(@@procid) + CAST(trigger_nestlevel(@@procid) as nvarchar(2))

-- Begin transaction
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

-- Get the caller login from the spidLogin table
IF len(dbo.string$GetSpidLogin()) = 0 BEGIN
   SET @msg = ''No login found for auditing purposes.'' + @msgTag + ''>''
   EXECUTE error$raise @msg, 0, @tranName
   RETURN
END
ELSE IF dbo.string$GetSpidLogin() != ''System'' BEGIN
   SET @msg = ''No authority to insert license codes.'' + @msgTag + ''>''
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
VALUES(2, @licenseType + '' license inserted, issued on '' + @issueDate)

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

IF EXISTS(SELECT * FROM sysobjects WHERE name = 'productLicense$afterUpdate' AND objectproperty(id, 'ExecIsUpdateTrigger' ) = 1) 
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'TRIGGER productLicense$afterUpdate
ON     ProductLicense
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

IF EXISTS(SELECT * FROM sysobjects WHERE name = 'receiveList$afterInsert' AND objectproperty(id, 'ExecIsInsertTrigger' ) = 1) 
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'TRIGGER receiveList$AfterInsert
ON     ReceiveList
WITH ENCRYPTION
AFTER  INSERT
AS
BEGIN
DECLARE @msg nvarchar(255)        -- used to preformat error message
DECLARE @msgTag nvarchar(255)     -- used to hold first part of error message header
DECLARE @tranName nvarchar(255)   -- used to hold name of savepoint
DECLARE @listName nchar(10)       -- name of the newly created list
DECLARE @audit nvarchar(500)
DECLARE @account nvarchar(256)
DECLARE @rowCount int            -- holds the number of rows in the Inserted table
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
   SET @msg = ''Batch insert into receiving list table not allowed.'' + @msgTag + ''>''
   EXECUTE error$raise @msg, 0, @tranName
   RETURN
END

-- Get the caller login from the spidLogin table
IF len(dbo.string$GetSpidLogin()) = 0 BEGIN
   SET @msg = ''Login not found for auditing purposes.'' + @msgTag + ''>''
   EXECUTE error$raise @msg, 0, @tranName
   RETURN
END

-- Select the name from the Inserted table
SELECT @listName = ListName FROM Inserted
SELECT @audit = ''Receiving list '' + @listName + '' created''

-- Get the account name
SELECT @account = AccountName
FROM   Account
WHERE  AccountId = (SELECT AccountId FROM Inserted)
IF @@rowcount != 0
   SET @audit = @audit + '' (account: '' + @account + '')''
ELSE
   SET @audit = @audit + '' (composite)''

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
   1, 
   @audit,
   dbo.string$GetSpidLogin()
)

SET @error = @@error
IF @error != 0 BEGIN
   SET @msg = ''Error encountered while inserting a receiving list audit record.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
   EXECUTE error$raise @msg, @error, @tranName
   RETURN
END

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
DECLARE @rowVersion rowversion
DECLARE @status int
DECLARE @compositeId int
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

-- Audit status changes.  Also, if the list is a discrete that belongs to a
-- composite, set the status of the composite to change the rowversion.
SET @lastList = 0
WHILE 1 = 1 BEGIN
   SELECT TOP 1 @listName = i.ListName,
          @lastList = i.ListId,
          @status = i.Status,
          @compositeId = i.CompositeId
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
         SET @msgUpdate = ''List '' + @listName + '' upgraded to transmitted status''
      ELSE IF @status = 8
         SET @msgUpdate = ''List '' + @listName + '' upgraded to partially verified (I) status''
      ELSE IF @status = 16
         SET @msgUpdate = ''List '' + @listName + '' upgraded to fully verified (I) status''
      ELSE IF @status = 32
         SET @msgUpdate = ''List '' + @listName + '' upgraded to transit status''
      ELSE IF @status = 64
         SET @msgUpdate = ''List '' + @listName + '' upgraded to arrived status''
      ELSE IF @status = 128
         SET @msgUpdate = ''List '' + @listName + '' upgraded to partially verified (II) status''
      ELSE IF @status = 256
         SET @msgUpdate = ''List '' + @listName + '' upgraded to fully verified (II) status''
      ELSE IF @status = 512
         SET @msgUpdate = ''List '' + @listName + '' upgraded to processed status''
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
      IF @compositeId IS NOT NULL BEGIN
         SELECT @status = min(Status)
         FROM   ReceiveList
         WHERE  CompositeId = @compositeId
         IF @status IS NOT NULL BEGIN
            UPDATE ReceiveList
            SET    Status = @status
            WHERE  ListId = @compositeId
            SET @error = @@error
            IF @error != 0 BEGIN
               SET @msg = ''Error encountered while updating composite receiving list status.'' + @msgTag + '';Error='' + cast(@error as nvarchar(9)) + ''>''
               EXECUTE error$raise @msg, @error, @tranName
               RETURN
            END
         END
      END
   END
END          

-- Audit merges
SET @lastList = 0
WHILE 1 = 1 BEGIN
   SELECT TOP 1 @listName = i.ListName,
          @lastList = i.ListId,
          @compositeId = i.CompositeId
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
      WHERE  ListId = @compositeId
      -- Make sure that the composite is not discrete
      IF EXISTS(SELECT 1 FROM ReceiveList WHERE AccountId IS NOT NULL AND ListId = @compositeId) BEGIN
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
          @compositeId = d.CompositeId
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
      WHERE  ListId = @compositeId
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
      IF NOT EXISTS(SELECT 1 FROM ReceiveList WHERE CompositeId = @compositeId) BEGIN
         DELETE ReceiveList
         WHERE  ListId = @compositeId
         SET @error = @@error
         IF @error != 0 BEGIN
            SET @msg = ''Error encountered while deleting dissolved composite list.'' + @msgTag + '';Error='' + cast(@error as nvarchar(9)) + ''>''
            EXECUTE error$raise @msg, @error, @tranName
            RETURN
         END
      END
   END
END


COMMIT TRANSACTION
END
'
)

IF EXISTS(SELECT * FROM sysobjects WHERE name = 'sealedCase$afterInsert' AND objectproperty(id, 'ExecIsInsertTrigger' ) = 1) 
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'TRIGGER sealedCase$afterInsert
ON     SealedCase
WITH ENCRYPTION
AFTER  INSERT
AS
BEGIN
DECLARE @msg nvarchar(255)         -- used to preformat error message
DECLARE @msgTag nvarchar(255)      -- used to hold first part of error message header
DECLARE @msgUpdate nvarchar(4000)  -- used to hold the updated fields
DECLARE @tranName nvarchar(255)    -- used to hold name of savepoint
DECLARE @rowCount int             -- holds the number of rows in the Deleted table
DECLARE @serialNo nvarchar(32)
DECLARE @returnDate nvarchar(10)
DECLARE @notes nvarchar(1000)
DECLARE @audit nvarchar(1000)
DECLARE @vaultDiscrepancy int
DECLARE @returnValue int
DECLARE @hotStatus bit
DECLARE @typeId int
DECLARE @caseId int
DECLARE @error int

SET @rowCount = @@rowcount
IF @rowCount = 0 RETURN

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=T''
SET @tranName = object_name(@@procid) + CAST(trigger_nestlevel(@@procid) as nvarchar(2))

-- Begin the transaction
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

-- Make sure we do not have a batch insert
IF @rowCount > 1 BEGIN
   SET @msg = ''Batch insert into sealed case table not allowed.'' + @msgTag + ''>''
   EXECUTE error$raise @msg, 0, @tranName
   RETURN
END

-- Get the caller login from the spidLogin table
IF len(dbo.string$GetSpidLogin()) = 0 BEGIN
   SET @msg = ''Caller login not found in spid login table.'' + @msgTag + ''>''
   EXECUTE error$raise @msg, 0, @tranName
   RETURN
END

-- Get the inserted data
SELECT @serialNo = SerialNo,
       @caseId = CaseId,
       @returnDate = coalesce(convert(nvarchar(10),ReturnDate,120),''NONE''),
       @hotStatus = HotStatus,
       @typeId = TypeId,
       @notes = Notes
FROM   Inserted

-- Verify that there is no medium with that serial number
IF EXISTS(SELECT 1 FROM Medium WHERE SerialNo = @serialNo) BEGIN
   SET @msg = ''A medium with serial number '' + @serialNo + '' already exists.'' + @msgTag + ''>''
   EXECUTE error$raise @msg, 0, @tranName
   RETURN
END

-- Check to see if we have an unknown case discrepancy resolution
SELECT @vaultDiscrepancy = ItemId
FROM   VaultDiscrepancyUnknownCase
WHERE  SerialNo = @serialNo
IF @@rowCount != 0 BEGIN
   EXECUTE @returnValue = VaultDiscrepancyUnknownCase$resolve @vaultDiscrepancy, 1
   IF @returnValue != 0 BEGIN
      ROLLBACK TRANSACTION @tranName   
      COMMIT TRANSACTION
      RETURN
   END
END

-- Set the audit string
SELECT @audit = ''Sealed case created'' + case len(@returnDate) when 0 then '''' else '' with a return date of '' + @returnDate end

-- Insert audit record
INSERT XSealedCase
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
   @audit,
   dbo.string$GetSpidLogin()
)
SET @error = @@error
IF @error != 0 BEGIN
   SET @msg = ''Error inserting a row into the sealed case audit table.'' + @msgTag + '';Error='' + cast(@error as nvarchar(9)) + ''>''
   EXECUTE error$raise @msg, @error, @tranName
   RETURN
END

-- Commit transaction
COMMIT TRANSACTION
END
'
)

IF EXISTS(SELECT * FROM sysobjects WHERE name = 'sealedCase$afterUpdate' AND objectproperty(id, 'ExecIsUpdateTrigger' ) = 1) 
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'TRIGGER sealedCase$afterUpdate
ON     SealedCase
WITH ENCRYPTION
AFTER  UPDATE
AS
BEGIN
DECLARE @msg nvarchar(255)         -- used to preformat error message
DECLARE @msgTag nvarchar(255)      -- used to hold first part of error message header
DECLARE @msgUpdate nvarchar(4000)  -- used to hold the updated fields
DECLARE @tranName nvarchar(255)    -- used to hold name of savepoint
DECLARE @rowCount int              -- holds the number of rows in the Deleted table
DECLARE @serialNo nvarchar(32)
DECLARE @lastSerial nvarchar(32)
DECLARE @returnDate nvarchar(10)
DECLARE @notes nvarchar(1000)
DECLARE @vaultDiscrepancy int
DECLARE @returnValue int
DECLARE @lastMedium int
DECLARE @hotStatus bit
DECLARE @typeId int
DECLARE @caseId int
DECLARE @error int
DECLARE @tblM table (RowNo int identity (1,1), Message nvarchar(1000))
DECLARE @i int

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

SET @lastSerial = ''''
WHILE 1 = 1 BEGIN
   SELECT TOP 1 @lastSerial = SerialNo,
          @caseId = CaseId,
          @returnDate = coalesce(convert(nvarchar(10),ReturnDate,120),''NONE''),
          @hotStatus = HotStatus,
          @typeId = TypeId,
          @notes = Notes
   FROM   Inserted
   WHERE  SerialNo > @lastSerial
   ORDER BY SerialNo Asc
   IF @@rowCount = 0
      BREAK
   ELSE BEGIN
      -- Reset the message table
      DELETE FROM @tblM
      -- Case type
      IF EXISTS(SELECT 1 FROM Deleted WHERE CaseId = @caseId AND TypeId != @typeId) BEGIN
         INSERT @tblM (Message) SELECT ''Case type changed to '' + (SELECT TypeName FROM MediumType WHERE TypeId = @typeId)
      END
      -- Return date
      IF EXISTS(SELECT 1 FROM Deleted WHERE CaseId = @caseId AND coalesce(convert(nvarchar(10),ReturnDate,120),''NONE'') != @returnDate) BEGIN
         INSERT @tblM (Message) SELECT ''Return date changed to '' + @returnDate
      END
      -- Hot site status
      IF EXISTS (SELECT 1 FROM Deleted WHERE CaseId = @caseId AND HotStatus != @hotStatus) BEGIN
         INSERT @tblM (Message) SELECT case @hotStatus when 1 then ''Case regarded as at hot site'' else ''Case no longer regarded as at hot site'' end
      END
      -- Serial number
      IF EXISTS (SELECT 1 FROM Deleted WHERE CaseId = @caseId AND SerialNo != @lastSerial) BEGIN
         INSERT @tblM (Message) SELECT ''Serial number changed to '' + @lastSerial + ''''
      END
      -- Initialize variables used for auditing
      SELECT @i = min(RowNo) FROM @tblM
      SELECT @serialNo = SerialNo FROM Deleted
      -- Insert audit records
      WHILE 1 = 1 BEGIN
         SELECT @msgUpdate = Message
         FROM   @tblM
         WHERE  RowNo = @i
         IF @@rowcount = 0 
            BREAK
         ELSE BEGIN
            INSERT XSealedCase (Object, Action, Detail, Login)
            VALUES(@serialNo, 2, @msgUpdate, dbo.string$GetSpidLogin())
            SET @error = @@error
            IF @error != 0 BEGIN
               SET @msg = ''Error inserting a row into the sealed case audit table.'' + @msgTag + '';Error='' + cast(@error as nvarchar(9)) + ''>''
               EXECUTE error$raise @msg, @error, @tranName
               RETURN
            END
         END
         -- Counter
         SELECT @i = @i + 1
      END
      -- If the case serial number was changed, then we should delete any type 
      -- inventory discrepancies for the case and check to see if we have 
      -- resolved an unknown case discrepancy.
      IF EXISTS (SELECT 1 FROM Deleted WHERE CaseId = @caseId AND SerialNo != @lastSerial) BEGIN
         DELETE VaultDiscrepancyCaseType
         WHERE  CaseId = @caseId
         SET @error = @@error
         IF @error != 0 BEGIN
            SET @msg = ''Error encountered while deleting a case type vault inventory discrepancy.'' + @msgTag + '';Error='' + cast(@error as nvarchar(9)) + ''>''
            EXECUTE error$raise @msg, @error, @tranName
            RETURN
         END
         SELECT @vaultDiscrepancy = ItemId
         FROM   VaultDiscrepancyUnknownCase
         WHERE  SerialNo = @lastSerial
         IF @@rowCount != 0 BEGIN
            EXECUTE @returnValue = VaultDiscrepancyUnknownCase$resolve @vaultDiscrepancy, 2
            IF @returnValue != 0 BEGIN
               ROLLBACK TRANSACTION @tranName   
               COMMIT TRANSACTION
               RETURN
            END
         END
      END
      -- If the case type was altered, then we may resolve a case type vault discrepancy
      IF EXISTS(SELECT 1 FROM Deleted WHERE CaseId = @caseId AND TypeId != @typeId) BEGIN
         SELECT @vaultDiscrepancy = vdc.ItemId
         FROM   VaultDiscrepancyCaseType vdc
         JOIN   Inserted i
           ON   vdc.VaultType = i.TypeId
         WHERE  vdc.CaseId = @caseId
         IF @@rowCount != 0 BEGIN
            EXECUTE @returnValue = vaultDiscrepancyCaseType$resolve @vaultDiscrepancy, 1
            IF @returnValue != 0 BEGIN
               ROLLBACK TRANSACTION @tranName   
               COMMIT TRANSACTION
               RETURN
            END
         END
      END
      -- If the hot status has been modified, we must modify all the media that lay within the case accordingly.
      IF EXISTS (SELECT 1 FROM Deleted WHERE CaseId = @caseId AND HotStatus != @hotStatus) BEGIN
         SET @lastMedium = 0
         WHILE 1 = 1 BEGIN
            SELECT TOP 1 @lastMedium = MediumId 
            FROM   MediumSealedCase 
            WHERE  CaseId = @caseId AND
                   MediumId > @lastMedium
            ORDER BY MediumId ASC
            IF @@rowCount = 0 BEGIN
               BREAK
            END
            ELSE BEGIN
               UPDATE Medium
               SET    HotStatus = @hotStatus
               WHERE  MediumId = @lastMedium
               SET @error = @@error
               IF @error != 0 BEGIN
                  SET @msg = ''Error changing field of resident medium after change in sealed case field.'' + @msgTag + '';Error='' + cast(@error as nvarchar(9)) + ''>''
                  EXECUTE error$raise @msg, @error, @tranName
                  RETURN
               END
            END
         END
      END
   END
END

-- Commit transaction
COMMIT TRANSACTION
END
'
)

IF EXISTS(SELECT * FROM sysobjects WHERE name = 'sendList$afterInsert' AND objectproperty(id, 'ExecIsInsertTrigger' ) = 1) 
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'TRIGGER sendList$AfterInsert
ON     SendList
WITH ENCRYPTION
AFTER  INSERT
AS
BEGIN
DECLARE @msg nvarchar(255)        -- used to preformat error message
DECLARE @msgTag nvarchar(255)     -- used to hold first part of error message header
DECLARE @tranName nvarchar(255)   -- used to hold name of savepoint
DECLARE @listName nchar(10)       -- name of the newly created list
DECLARE @msgUpdate nvarchar(500)
DECLARE @account nvarchar(256)
DECLARE @rowCount int            -- holds the number of rows in the Inserted table
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
   SET @msg = ''Batch insert into shipping list table not allowed.'' + @msgTag + ''>''
   EXECUTE error$raise @msg, 0, @tranName
   RETURN
END

-- Get the caller login from the spidLogin table
IF len(dbo.string$GetSpidLogin()) = 0 BEGIN
   SET @msg = ''Login not found for auditing purposes.'' + @msgTag + ''>''
   EXECUTE error$raise @msg, 0, @tranName
   RETURN
END

-- Select the name from the Inserted table
SELECT @listName = ListName FROM Inserted
SELECT @msgUpdate = ''Shipping list '' + @listName + '' created''

-- Get the account name
SELECT @account = AccountName
FROM   Account
WHERE  AccountId = (SELECT AccountId FROM Inserted)
IF @@rowcount != 0
   SET @msgUpdate = @msgUpdate + '' (account: '' + @account + '')''
ELSE
   SET @msgUpdate = @msgUpdate + '' (composite)''

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
   1, 
   @msgUpdate,
   dbo.string$GetSpidLogin()
)

SET @error = @@error
IF @error != 0 BEGIN
   SET @msg = ''Error encountered while inserting a new shipping list audit record.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
   EXECUTE error$raise @msg, @error, @tranName
   RETURN
END

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
DECLARE @rowCount int             -- holds the number of rows in the Deleted table
DECLARE @status int
DECLARE @compositeId int
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

-- Audit status changes.  Also, if the list is a discrete that belongs to a
-- composite, set the status of the composite.
SET @lastList = 0
WHILE 1 = 1 BEGIN
   SELECT TOP 1 @listName = i.ListName,
          @lastList = i.ListId,
          @status = i.Status,
          @compositeId = i.CompositeId
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
         SET @msgUpdate = ''List '' + @listName + '' upgraded to partially verified (I) status''
      ELSE IF @status = 8
         SET @msgUpdate = ''List '' + @listName + '' upgraded to fully verified (I) status''
      ELSE IF @status = 16
         SET @msgUpdate = ''List '' + @listName + '' upgraded to transmitted verified status''
      ELSE IF @status = 32
         SET @msgUpdate = ''List '' + @listName + '' upgraded to transit status''
      ELSE IF @status = 64
         SET @msgUpdate = ''List '' + @listName + '' upgraded to arrived status''
      ELSE IF @status = 128
         SET @msgUpdate = ''List '' + @listName + '' upgraded to partially verified (II) status''
      ELSE IF @status = 256
         SET @msgUpdate = ''List '' + @listName + '' upgraded to fully verified (II) status''
      ELSE IF @status = 512
         SET @msgUpdate = ''List '' + @listName + '' upgraded to processed status''
      -- Insert audit record
      INSERT XSendList (Object, Action, Detail, Login)
      VALUES(@listName, 2, @msgUpdate, dbo.string$GetSpidLogin())
      SET @error = @@error
      IF @error != 0 BEGIN
         SET @msg = ''Error encountered while inserting new shipping list audit record.'' + @msgTag + '';Error='' + cast(@error as nvarchar(9)) + ''>''
         EXECUTE error$raise @msg, @error, @tranName
         RETURN
      END
      -- If belongs to a composite, set status of composite
      IF @compositeId IS NOT NULL BEGIN
         SELECT @status = min(Status)
         FROM   SendList
         WHERE  CompositeId = @compositeId
         IF @status IS NOT NULL BEGIN
            UPDATE SendList
            SET    Status = @status
            WHERE  ListId = @compositeId
            SET @error = @@error
            IF @error != 0 BEGIN
               SET @msg = ''Error encountered while updating composite shipping list status.'' + @msgTag + '';Error='' + cast(@error as nvarchar(9)) + ''>''
               EXECUTE error$raise @msg, @error, @tranName
               RETURN
            END
         END
      END
   END
END          

-- Audit merges
SET @lastList = 0
WHILE 1 = 1 BEGIN
   SELECT TOP 1 @listName = i.ListName,
          @lastList = i.ListId,
          @compositeId = i.CompositeId
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
      WHERE  ListId = @compositeId
      -- Make sure that the composite is not discrete
      IF EXISTS(SELECT 1 FROM SendList WHERE AccountId IS NOT NULL AND ListId = @compositeId) BEGIN
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
          @compositeId = d.CompositeId
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
      WHERE  ListId = @compositeId
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
      IF NOT EXISTS(SELECT 1 FROM SendList WHERE CompositeId = @compositeId) BEGIN
         DELETE SendList
         WHERE  ListId = @compositeId
         SET @error = @@error
         IF @error != 0 BEGIN
            SET @msg = ''Error encountered while deleting dissolved composite list.'' + @msgTag + '';Error='' + cast(@error as nvarchar(9)) + ''>''
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

IF EXISTS(SELECT * FROM sysobjects WHERE name = 'sendListCase$afterInsert' AND objectproperty(id, 'ExecIsInsertTrigger' ) = 1) 
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
DECLARE @rowCount int             -- holds the number of rows in the Inserted table
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
   SET @msg = ''Batch insert into shipping list case table not allowed.'' + @msgTag + ''>''
   EXECUTE error$raise @msg, 0, @tranName
   RETURN
END

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

-- Make sure that the case does not exist in the sealed case table
IF EXISTS(SELECT 1 FROM SealedCase WHERE SerialNo = @caseName) BEGIN
   SET @msg = ''Sealed case '''''' + @caseName + '''''' already resides at the vault.'' + @msgTag + ''>''
   EXECUTE error$raise @msg, 0, @tranName
   RETURN
END

-- Make sure that the case is only active once
IF EXISTS(SELECT 1 FROM SendListCase WHERE SerialNo = @caseName AND Cleared = 0 AND CaseId != (SELECT CaseId FROM Inserted)) BEGIN
   SET @msg = ''There is already a case named '''''' + @caseName + '''''' on an active shipping list.'' + @msgTag + ''>''
   EXECUTE error$raise @msg, 0, @tranName
   RETURN
END

-- Insert audit record
INSERT XSendListCase
(
   Object, 
   Action, 
   Detail, 
   Login
)
VALUES
(
   @caseName, 
   1, 
   ''Case '' + @caseName + '', unsealed and of type '' + @typeName,
   dbo.string$GetSpidLogin()
)

SET @error = @@error
IF @error != 0 BEGIN
   SET @msg = ''Error encountered while inserting a new shipping list case audit record.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
   EXECUTE error$raise @msg, @error, @tranName
   RETURN
END

COMMIT TRANSACTION
END
'
)

IF EXISTS(SELECT * FROM sysobjects WHERE name = 'sendListCase$afterUpdate' AND objectproperty(id, 'ExecIsUpdateTrigger' ) = 1) 
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'TRIGGER sendListCase$afterUpdate
ON     SendListCase
WITH ENCRYPTION
AFTER  UPDATE
AS
BEGIN
DECLARE @msg nvarchar(255)        -- used to preformat error message
DECLARE @msgTag nvarchar(255)     -- used to hold first part of error message header
DECLARE @tranName nvarchar(255)   -- used to hold name of savepoint
DECLARE @caseName nvarchar(32)
DECLARE @msgUpdate nvarchar(255)
DECLARE @returnDate nvarchar(10)
DECLARE @typeName nvarchar(128)
DECLARE @serialNo nvarchar(32)
DECLARE @sealed nvarchar(5)
DECLARE @lastCase int
DECLARE @rowCount int             -- holds the number of rows in the Inserted table
DECLARE @caseId int
DECLARE @error int            
DECLARE @tblM table (RowNo int identity (1,1), Message nvarchar(1000))
DECLARE @typeId int
DECLARE @i int

SET @rowCount = @@rowcount
IF @rowCount = 0 RETURN

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=T''
SET @tranName = object_name(@@procid) + CAST(trigger_nestlevel(@@procid) as nvarchar(2))

-- Begin transaction
BEGIN TRANSACTION
SAVE TRANSACTION @tranName
      
-- Make sure that the case does not exist in the sealed case table
SELECT TOP 1 @caseName = c.SerialNo
FROM   SealedCase c
JOIN   Inserted i
  ON   c.SerialNo = i.SerialNo
WHERE  i.Cleared = 0
IF @@rowcount != 0 BEGIN
   SET @msg = ''Case '' + @caseName + '' already resides, sealed, at the vault.'' + @msgTag + ''>''
   EXECUTE error$raise @msg, 0, @tranName
   RETURN
END

-- Make sure that the case is only active once
SELECT TOP 1 @caseName = c.SerialNo
FROM   SendListCase c
JOIN   Inserted i
  ON   i.SerialNo = c.SerialNo
WHERE  c.Cleared = 0 AND c.CaseId != i.CaseId
IF @@rowcount != 0 BEGIN
   SET @msg = ''There is already a case named '''''' + @caseName + '''''' on an active shipping list.'' + @msgTag + ''>''
   EXECUTE error$raise @msg, 0, @tranName
   RETURN
END

-- Get the caller login from the spidLogin table
IF len(dbo.string$GetSpidLogin()) = 0 BEGIN
   SET @msg = ''Login not found for auditing purposes.'' + @msgTag + ''>''
   EXECUTE error$raise @msg, 0, @tranName
   RETURN
END

SET @lastCase = 0
WHILE 1 = 1 BEGIN
   SELECT TOP 1 @lastCase = CaseId,
          @caseName = SerialNo,
          @sealed = Sealed,
          @typeId = TypeId,
          @returnDate = coalesce(convert(nvarchar(10),ReturnDate,120),''NONE'')
   FROM   Inserted
   WHERE  CaseId > @lastCase
   ORDER BY CaseId ASC
   IF @@rowCount = 0 BREAK
   -- Reset the message table
   DELETE FROM @tblM
   -- Sealed status
   IF EXISTS (SELECT 1 FROM Deleted WHERE CaseId = @lastCase AND Sealed != @sealed) BEGIN
      INSERT @tblM (Message) SELECT case @sealed when 1 then ''Case has been sealed'' else ''Case has been unsealed'' end
   END
   -- Case type
   IF EXISTS(SELECT 1 FROM Deleted WHERE CaseId = @lastCase AND TypeId != @typeId) BEGIN
      INSERT @tblM (Message) SELECT ''Case type changed to '' + (SELECT TypeName FROM MediumType WHERE TypeId = @typeId)
   END
   -- Return date
   IF EXISTS(SELECT 1 FROM Deleted WHERE CaseId = @lastCase AND coalesce(convert(nvarchar(10),ReturnDate,120),''NONE'') != @returnDate) BEGIN
      INSERT @tblM (Message) SELECT ''Return date changed to '' + @returnDate
   END
   -- Serial number
   IF EXISTS (SELECT 1 FROM Deleted WHERE CaseId = @lastCase AND SerialNo != @caseName) BEGIN
      INSERT @tblM (Message) SELECT ''Serial number changed to '' + @caseName + ''''
   END
   -- Initialize variables used for auditing
   SELECT @i = min(RowNo) FROM @tblM
   SELECT @serialNo = SerialNo FROM Deleted
   -- Insert audit records
   WHILE 1 = 1 BEGIN
      SELECT @msgUpdate = Message
      FROM   @tblM
      WHERE  RowNo = @i
      IF @@rowcount = 0 
         BREAK
      ELSE BEGIN
         INSERT XSendListCase (Object, Action, Detail, Login)
         VALUES(@serialNo, 2, @msgUpdate, dbo.string$GetSpidLogin())
         SET @error = @@error
         IF @error != 0 BEGIN
            SET @msg = ''Error encountered while inserting a new shipping list case audit record.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
            EXECUTE error$raise @msg, @error, @tranName
            RETURN
         END
      END
      -- Counter
      SELECT @i = @i + 1
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
   ''Medium '' + @serialNo + '' added to shipping list'' + @itemStatus,
   dbo.string$GetSpidLogin()
)
SET @error = @@error
IF @error != 0 BEGIN
   SET @msg = ''Error encountered while inserting a new shipping list item audit record.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
   EXECUTE error$raise @msg, @error, @tranName
   RETURN
END

-- Make sure that the discrete list status is equal to the 
-- (translated) lowest status among its non-removed items.
SELECT @rowVersion = RowVersion FROM SendList WHERE ListId = @listId
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

-- If return date specified, verify that it is later than today.
IF EXISTS
   (
   SELECT 1
   FROM   Deleted d
   JOIN   Inserted i
     ON   i.ItemId = d.ItemId
   WHERE  i.ReturnDate IS NOT NULL AND
          coalesce(d.ReturnDate,''1900-01-01'') != i.ReturnDate AND
          i.ReturnDate < cast(convert(nchar(10),getdate(),120) as datetime)
   )
BEGIN
   SET @msg = ''Return date must be later than today.'' + @msgTag + ''>''
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

IF EXISTS(SELECT * FROM sysobjects WHERE name = 'sendListItemCase$afterDelete' AND objectproperty(id, 'ExecIsDeleteTrigger' ) = 1) 
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'TRIGGER sendListItemCase$afterDelete
ON     SendListItemCase
WITH ENCRYPTION
AFTER  DELETE
AS
BEGIN
DECLARE @msg nvarchar(255)        -- used to preformat error message
DECLARE @msgTag nvarchar(255)     -- used to hold first part of error message header
DECLARE @tranName nvarchar(255)   -- used to hold name of savepoint
DECLARE @caseName nvarchar(32)
DECLARE @serialNo nvarchar(32)
DECLARE @rowCount int             -- holds the number of rows in the Inserted table
DECLARE @lastCase int
DECLARE @error int            

SET @rowCount = @@rowcount
IF @rowCount = 0 RETURN

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=T''
SET @tranName = object_name(@@procid) + CAST(trigger_nestlevel(@@procid) as nvarchar(2))

-- Begin the transaction
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

-- For each case mentioned, if no items are left in the case then 
-- delete the case.
SET @lastCase = 0
WHILE 1 = 1 BEGIN
   SELECT DISTINCT @lastCase = d.CaseId
   FROM   Deleted d
   WHERE  d.CaseId > @lastCase AND 
          NOT EXISTS (SELECT 1 FROM SendListItemCase slic WHERE slic.CaseId = d.CaseId)
   ORDER BY d.CaseId ASC
   IF @@rowCount = 0
      BREAK
   ELSE BEGIN
      DELETE SendListCase
      WHERE  CaseId = @lastCase
      SELECT @error = @@error
      IF @error != 0 BEGIN
         SET @msg = ''Error deleting empty shipping list case.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
         EXECUTE error$raise @msg, @error, @tranName
         RETURN
      END
   END
END


-- Only insert audit record if single row and if list is not cleared
IF @rowCount = 1 BEGIN
   IF NOT EXISTS
      (
      SELECT 1
      FROM   SendList sl
      JOIN   SendListItem sli
        ON   sli.ListId = sl.ListId
      WHERE  sl.Status != 1024 AND sli.ItemId = (SELECT ItemId FROM Deleted) -- power(4,5)
      )
   BEGIN
      -- Get the caller login from the spidLogin table
      IF len(dbo.string$GetSpidLogin()) = 0 BEGIN
         SET @msg = ''Login not found for auditing purposes.'' + @msgTag + ''>''
         EXECUTE error$raise @msg, 0, @tranName
         RETURN
      END
      -- Select the case name
      SELECT @caseName = c.SerialNo
      FROM   Deleted d
      JOIN   SendListCase c
        ON   c.CaseId = d.CaseId
      -- Select the medium serial number
      SELECT @serialNo = m.SerialNo
      FROM   Deleted d
      JOIN   SendListItem s
        ON   s.Itemid = d.ItemId
      JOIN   Medium m
        ON   m.MediumId = s.MediumId
      -- Insert audit record
      IF @@rowCount > 0 BEGIN
         INSERT XSendListCase
         (
            Object, 
            Action, 
            Detail, 
            Login
         )
         VALUES
         (
            @caseName, 
            5, 
            ''Medium '' + @serialNo + '' removed from case'',
            dbo.string$GetSpidLogin()
         )
         SET @error = @@error
         IF @error != 0 BEGIN
            SET @msg = ''Error encountered while inserting a new shipping list case audit record.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
            EXECUTE error$raise @msg, @error, @tranName
            RETURN
         END
      END
   END
END

-- Commit the transaction
COMMIT TRANSACTION
END
'
)

IF EXISTS(SELECT * FROM sysobjects WHERE name = 'sendListItemCase$afterInsert' AND objectproperty(id, 'ExecIsInsertTrigger' ) = 1) 
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'TRIGGER sendListItemCase$afterInsert
ON     SendListItemCase
WITH ENCRYPTION
AFTER  INSERT
AS
BEGIN
DECLARE @msg nvarchar(255)        -- used to preformat error message
DECLARE @msgTag nvarchar(255)     -- used to hold first part of error message header
DECLARE @tranName nvarchar(255)   -- used to hold name of savepoint
DECLARE @caseName nvarchar(32)    -- holds the name of the case
DECLARE @serialNo nvarchar(32)    -- holds the serial number of the medium
DECLARE @listName nchar(10)       -- name of the send list
DECLARE @rowCount int             -- holds the number of rows in the Inserted table
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
   SET @msg = ''Batch insert into shipping list item case table not allowed.'' + @msgTag + ''>''
   EXECUTE error$raise @msg, 0, @tranName
   RETURN
END

-- Get the caller login from the spidLogin table
IF len(dbo.string$GetSpidLogin()) = 0 BEGIN
   SET @msg = ''Login not found for auditing purposes.'' + @msgTag + ''>''
   EXECUTE error$raise @msg, 0, @tranName
   RETURN
END

-- Get the name of the case, the serial number of the medium, and the name of the send list
SELECT @caseName = SerialNo 
FROM   SendListCase 
WHERE  CaseId = (SELECT CaseId FROM Inserted)
--
SELECT @serialNo = m.SerialNo,
       @listName = sl.ListName
FROM   Medium m
JOIN   SendListItem sli
  ON   sli.MediumId = m.MediumId
JOIN   SendList sl
  ON   sl.ListId = sli.ListId
WHERE  sli.ItemId = (SELECT ItemId FROM Inserted)

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
   ''Medium '' + @serialNo + '' inserted into case '' + @caseName, 
   dbo.string$GetSpidLogin()
)
SET @error = @@error
IF @error != 0 BEGIN
   SET @msg = ''Error encountered while inserting a new shipping list item case audit record.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
   EXECUTE error$raise @msg, @error, @tranName
   RETURN
END

COMMIT TRANSACTION
END
'
)

GO
-------------------------------------------------------------------------------
--
-- Disaster code check constraint
--
-------------------------------------------------------------------------------
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.CHECK_CONSTRAINTS WHERE CONSTRAINT_NAME = 'chkDisasterCode$Code' AND CHECK_CLAUSE LIKE '%bit$IsEmptyString%') BEGIN
   -- Drop it
   ALTER TABLE DisasterCode DROP CONSTRAINT chkDisasterCode$Code
   -- Add it, allowing the empty string
   ALTER TABLE DisasterCode ADD CONSTRAINT chkDisasterCode$Code 
      CHECK (dbo.bit$LegalCharacters(Code, 'ALPHANUMERIC', NULL ) = 1)
END

GO
-------------------------------------------------------------------------------
--
-- Version update
--
-------------------------------------------------------------------------------
IF NOT EXISTS(SELECT 1 FROM DatabaseVersion WHERE Major = 1 AND Minor = 1 AND Revision = 0) BEGIN
   DECLARE @x nvarchar(1000)
   EXECUTE spidLogin$ins 'System', 'Insert database version'
   INSERT DatabaseVersion (Major, Minor, Revision) VALUES (1, 1, 0)
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
