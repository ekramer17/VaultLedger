-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
--
-- VaultLedger database update - version 1.1.2
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

IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'ListFileCharacter') BEGIN
CREATE TABLE dbo.ListFileCharacter
(
-- Attributes
   ListType   int       NOT NULL,
   Vendor     int       NOT NULL,
   Character  nchar(1)  NOT NULL,
-- Composite constraint
   CONSTRAINT akListFileCharacter$listVendor UNIQUE CLUSTERED (ListType,Vendor)
)
END
GO

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
--
-- We should have a database version check here.  If > 1.1.2, then do not
-- perform the update.
--
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
DECLARE @doScript bit
DECLARE @thisVersion nvarchar(50)
DECLARE @currentVersion nvarchar(50)

SET NOCOUNT ON

SELECT @doScript = 1
SELECT @thisVersion = '1.1.2'

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

-- Delete any empty send list cases.  They may exist due to the prior bug.
DELETE SendListCase
WHERE  CaseId NOT IN (SELECT CaseId FROM SendListItemCase)
 
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
--
-- Update check constraints
--
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.CHECK_CONSTRAINTS WHERE CONSTRAINT_NAME = 'chkBarCodePattern$Position')
   ALTER TABLE BarCodePattern DROP CONSTRAINT chkBarCodePattern$Position

IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.CHECK_CONSTRAINTS WHERE CONSTRAINT_NAME = 'chkAccount$AccountName')
   ALTER TABLE Account DROP CONSTRAINT chkAccount$AccountName

ALTER TABLE Account ADD CONSTRAINT chkAccount$AccountName
   CHECK (dbo.bit$IsEmptyString(AccountName) = 0 and dbo.bit$IllegalCharacters(AccountName, '|&?%*^') = 0) 

IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.CHECK_CONSTRAINTS WHERE CONSTRAINT_NAME = 'chkMedium$SerialNo')
   ALTER TABLE Medium DROP CONSTRAINT chkMedium$SerialNo

ALTER TABLE Medium ADD CONSTRAINT chkMedium$SerialNo
   CHECK (dbo.bit$IsEmptyString(SerialNo) = 0 and dbo.bit$LegalCharacters(SerialNo, 'ALPHANUMERIC', '.-_$+[]') = 1)

IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.CHECK_CONSTRAINTS WHERE CONSTRAINT_NAME = 'chkOperator$Login')
   ALTER TABLE Operator DROP CONSTRAINT chkOperator$Login

ALTER TABLE Operator ADD CONSTRAINT chkOperator$Login
   CHECK (dbo.bit$IsEmptyString(Login) = 0 and dbo.bit$IllegalCharacters(Login, '!|&?%*^') = 0)

IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.CHECK_CONSTRAINTS WHERE CONSTRAINT_NAME = 'chkOperator$OperatorName')
   ALTER TABLE Operator DROP CONSTRAINT chkOperator$OperatorName

ALTER TABLE Operator ADD CONSTRAINT chkOperator$OperatorName
   CHECK (dbo.bit$IllegalCharacters(OperatorName, '!|&?%*^') = 0)

IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.CHECK_CONSTRAINTS WHERE CONSTRAINT_NAME = 'chkReceiveListScan$Name')
   ALTER TABLE ReceiveListScan DROP CONSTRAINT chkReceiveListScan$Name

ALTER TABLE ReceiveListScan ADD CONSTRAINT chkReceiveListScan$Name
   CHECK (dbo.bit$IsEmptyString(ScanName) = 0 and dbo.bit$IllegalCharacters(ScanName, '%&?*^') = 0)

IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.CHECK_CONSTRAINTS WHERE CONSTRAINT_NAME = 'chkReceiveListScanItem$SerialNo')
   ALTER TABLE ReceiveListScanItem DROP CONSTRAINT chkReceiveListScanItem$SerialNo

ALTER TABLE ReceiveListScanItem ADD CONSTRAINT chkReceiveListScanItem$SerialNo
   CHECK (dbo.bit$IsEmptyString(SerialNo) = 0 and dbo.bit$LegalCharacters(SerialNo, 'ALPHANUMERIC', '.-_$+[]') = 1)

IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.CHECK_CONSTRAINTS WHERE CONSTRAINT_NAME = 'chkSealedCase$SerialNo')
   ALTER TABLE SealedCase DROP CONSTRAINT chkSealedCase$SerialNo

ALTER TABLE SealedCase ADD CONSTRAINT chkSealedCase$SerialNo
   CHECK (dbo.bit$IsEmptyString(SerialNo) = 0 and dbo.bit$LegalCharacters(SerialNo, 'ALPHANUMERIC', '.-_$+[]') = 1)

IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.CHECK_CONSTRAINTS WHERE CONSTRAINT_NAME = 'chkSendListCase$SerialNo')
   ALTER TABLE SendListCase DROP CONSTRAINT chkSendListCase$SerialNo

ALTER TABLE SendListCase ADD CONSTRAINT chkSendListCase$SerialNo
   CHECK (dbo.bit$IsEmptyString(SerialNo) = 0 and dbo.bit$LegalCharacters(SerialNo, 'ALPHANUMERIC', '.-_$+[]') = 1)

IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.CHECK_CONSTRAINTS WHERE CONSTRAINT_NAME = 'chkSendListScan$Name')
   ALTER TABLE SendListScan DROP CONSTRAINT chkSendListScan$Name

ALTER TABLE SendListScan ADD CONSTRAINT chkSendListScan$Name
   CHECK (dbo.bit$IsEmptyString(ScanName) = 0 and dbo.bit$IllegalCharacters(ScanName, '%&?*^') = 0)

IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.CHECK_CONSTRAINTS WHERE CONSTRAINT_NAME = 'chkSendListScanItem$CaseName')
   ALTER TABLE SendListScanItem DROP CONSTRAINT chkSendListScanItem$CaseName

ALTER TABLE SendListScanItem ADD CONSTRAINT chkSendListScanItem$CaseName
   CHECK (dbo.bit$LegalCharacters(CaseName, 'ALPHANUMERIC', '.-_$+[]') = 1)

IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.CHECK_CONSTRAINTS WHERE CONSTRAINT_NAME = 'chkSendListScanItem$SerialNo')
   ALTER TABLE SendListScanItem DROP CONSTRAINT chkSendListScanItem$SerialNo

ALTER TABLE SendListScanItem ADD CONSTRAINT chkSendListScanItem$SerialNo
   CHECK (dbo.bit$IsEmptyString(SerialNo) = 0 and dbo.bit$LegalCharacters(SerialNo, 'ALPHANUMERIC', '.-_$+[]') = 1)

IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.CHECK_CONSTRAINTS WHERE CONSTRAINT_NAME = 'chkVaultDiscrepancyAccount$SerialNo')
   ALTER TABLE VaultDiscrepancyAccount DROP CONSTRAINT chkVaultDiscrepancyAccount$SerialNo

ALTER TABLE VaultDiscrepancyAccount ADD CONSTRAINT chkVaultDiscrepancyAccount$SerialNo
   CHECK (dbo.bit$IsEmptyString(SerialNo) = 0 and dbo.bit$LegalCharacters(SerialNo, 'ALPHANUMERIC', '.-_$+[]') = 1)

IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.CHECK_CONSTRAINTS WHERE CONSTRAINT_NAME = 'chkVaultDiscrepancyCaseType$SerialNo')
   ALTER TABLE VaultDiscrepancyCaseType DROP CONSTRAINT chkVaultDiscrepancyCaseType$SerialNo

ALTER TABLE VaultDiscrepancyCaseType ADD CONSTRAINT chkVaultDiscrepancyCaseType$SerialNo
   CHECK (dbo.bit$IsEmptyString(SerialNo) = 0 and dbo.bit$LegalCharacters(SerialNo, 'ALPHANUMERIC', '.-_$+[]') = 1)

IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.CHECK_CONSTRAINTS WHERE CONSTRAINT_NAME = 'chkVaultDiscrepancyMediumType$SerialNo')
   ALTER TABLE VaultDiscrepancyMediumType DROP CONSTRAINT chkVaultDiscrepancyMediumType$SerialNo

ALTER TABLE VaultDiscrepancyMediumType ADD CONSTRAINT chkVaultDiscrepancyMediumType$SerialNo
   CHECK (dbo.bit$IsEmptyString(SerialNo) = 0 and dbo.bit$LegalCharacters(SerialNo, 'ALPHANUMERIC', '.-_$+[]') = 1)

IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.CHECK_CONSTRAINTS WHERE CONSTRAINT_NAME = 'chkVaultDiscrepancyResidency$SerialNo')
   ALTER TABLE VaultDiscrepancyResidency DROP CONSTRAINT chkVaultDiscrepancyResidency$SerialNo

ALTER TABLE VaultDiscrepancyResidency ADD CONSTRAINT chkVaultDiscrepancyResidency$SerialNo
   CHECK (dbo.bit$IsEmptyString(SerialNo) = 0 and dbo.bit$LegalCharacters(SerialNo, 'ALPHANUMERIC', '.-_$+[]') = 1)

IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.CHECK_CONSTRAINTS WHERE CONSTRAINT_NAME = 'chkVaultDiscrepancyUnknownCase$SerialNo')
   ALTER TABLE VaultDiscrepancyUnknownCase DROP CONSTRAINT chkVaultDiscrepancyUnknownCase$SerialNo

ALTER TABLE VaultDiscrepancyUnknownCase ADD CONSTRAINT chkVaultDiscrepancyUnknownCase$SerialNo
   CHECK (dbo.bit$IsEmptyString(SerialNo) = 0 and dbo.bit$LegalCharacters(SerialNo, 'ALPHANUMERIC', '.-_$+[]') = 1)

IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.CHECK_CONSTRAINTS WHERE CONSTRAINT_NAME = 'chkVaultInventoryItem$SerialNo')
   ALTER TABLE VaultInventoryItem DROP CONSTRAINT chkVaultInventoryItem$SerialNo

ALTER TABLE VaultInventoryItem ADD CONSTRAINT chkVaultInventoryItem$SerialNo
   CHECK (dbo.bit$IsEmptyString(SerialNo) = 0 and dbo.bit$LegalCharacters(SerialNo, 'ALPHANUMERIC', '.-_$+[]') = 1)

IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.CHECK_CONSTRAINTS WHERE CONSTRAINT_NAME = 'chkMedium$BSide')
   ALTER TABLE Medium DROP CONSTRAINT chkMedium$BSide

ALTER TABLE Medium ADD CONSTRAINT chkMedium$BSide
   CHECK (dbo.bit$LegalCharacters(BSide, 'ALPHANUMERIC', '.-_$+[]') = 1)

IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.CHECK_CONSTRAINTS WHERE CONSTRAINT_NAME = 'chkEmailGroup$GroupName')
   ALTER TABLE EmailGroup DROP CONSTRAINT chkEmailGroup$GroupName

ALTER TABLE EmailGroup ADD CONSTRAINT chkEmailGroup$GroupName
   CHECK (dbo.bit$IsEmptyString(GroupName) = 0 and dbo.bit$IllegalCharacters(GroupName, '|&?%*^') = 0)

IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.CHECK_CONSTRAINTS WHERE CONSTRAINT_NAME = 'chkFtpProfile$Name')
   ALTER TABLE FtpProfile DROP CONSTRAINT chkFtpProfile$Name

ALTER TABLE FtpProfile ADD CONSTRAINT chkFtpProfile$Name
   CHECK (dbo.bit$IsEmptyString(ProfileName) = 0 and dbo.bit$IllegalCharacters(ProfileName, '|&?%*^') = 0)

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
--
-- Update audit trails WITH better messages
--
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
UPDATE XSendList
SET    Detail = replace(detail, 'transmitted verified', 'transmitted')
WHERE  Detail LIKE '%transmitted verified%'

UPDATE XSendList
SET    Detail = replace(detail, 'upgraded to partially verified (I) status', 'partially verified (I)')
WHERE  Detail LIKE '%upgraded to partially verified (I) status%'

UPDATE XSendList
SET    Detail = replace(detail, 'upgraded to fully verified (I) status', 'fully verified (I)')
WHERE  Detail LIKE '%upgraded to fully verified (I) status%'

UPDATE XSendList
SET    Detail = replace(detail, 'upgraded to transmitted status', 'transmitted')
WHERE  Detail LIKE '%upgraded to transmitted status%'

UPDATE XSendList
SET    Detail = replace(detail, 'upgraded to transit status', 'marked as in transit')
WHERE  Detail LIKE '%upgraded to transit status%'

UPDATE XSendList
SET    Detail = replace(detail, 'upgraded to arrived status', 'marked as arrived at the vault')
WHERE  Detail LIKE '%upgraded to arrived status%'

UPDATE XSendList
SET    Detail = replace(detail, 'upgraded to partially verified (II) status', 'partially verified (II)')
WHERE  Detail LIKE '%upgraded to partially verified (II) status%'

UPDATE XSendList
SET    Detail = replace(detail, 'upgraded to fully verified (II) status', 'fully verified (II)')
WHERE  Detail LIKE '%upgraded to fully verified (II) status%'

UPDATE XSendList
SET    Detail = replace(detail, 'upgraded to processed status', 'processed')
WHERE  Detail LIKE '%upgraded to processed status%'

UPDATE XSendListItem
SET    Detail = replace(detail, ').', ')')
WHERE  Detail LIKE '%).%'

UPDATE XReceiveList
SET    Detail = replace(detail, 'upgraded to transmitted status', 'transmitted')
WHERE  Detail LIKE '%upgraded to transmitted status%'

UPDATE XReceiveList
SET    Detail = replace(detail, 'upgraded to partially verified (I) status', 'partially verified (I)')
WHERE  Detail LIKE '%upgraded to partially verified (I) status%'

UPDATE XReceiveList
SET    Detail = replace(detail, 'upgraded to fully verified (I) status', 'fully verified (I)')
WHERE  Detail LIKE '%upgraded to fully verified (I) status%'

UPDATE XReceiveList
SET    Detail = replace(detail, 'upgraded to transit status', 'marked as in transit')
WHERE  Detail LIKE '%upgraded to transit status%'

UPDATE XReceiveList
SET    Detail = replace(detail, 'upgraded to arrived status', 'marked as arrived at the enterprise')
WHERE  Detail LIKE '%upgraded to arrived status%'

UPDATE XReceiveList
SET    Detail = replace(detail, 'upgraded to partially verified (II) status', 'partially verified (II)')
WHERE  Detail LIKE '%upgraded to partially verified (II) status%'

UPDATE XReceiveList
SET    Detail = replace(detail, 'upgraded to fully verified (II) status', 'fully verified (II)')
WHERE  Detail LIKE '%upgraded to fully verified (II) status%'

UPDATE XReceiveList
SET    Detail = replace(detail, 'upgraded to processed status', 'processed')
WHERE  Detail LIKE '%upgraded to processed status%'

UPDATE XReceiveListItem
SET    Detail = replace(detail, ').', ')')
WHERE  Detail LIKE '%).%'

UPDATE XDisasterCodeList
SET    Detail = replace(detail, 'upgraded to transmitted status', 'transmitted')
WHERE  Detail LIKE '%upgraded to transmitted status%'

UPDATE XDisasterCodeList
SET    Detail = replace(detail, 'upgraded to processed status', 'processed')
WHERE  Detail LIKE '%upgraded to processed status%'

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
--
-- Stored Procedures
--
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
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
WHERE  Status != 1 AND (ListId = @listId OR ListId IN (SELECT ListId FROM ReceiveList WHERE CompositeId = @listId))

-- If no active items, return zero
IF @status IS NULL RETURN 0

-- If some items have been  verified and others haven''t, set the status to partial verification.
IF @status != 16  BEGIN
   IF EXISTS 
      (
      SELECT 1 
      FROM   ReceiveListItem 
      WHERE  Status = 16 AND (ListId = @listId OR ListId IN (SELECT ListId FROM ReceiveList WHERE CompositeId = @listId))
      )
   BEGIN
      SET @status = 8
   END
END
IF @status NOT IN (8, 256) BEGIN 
   IF EXISTS 
      (
      SELECT 1 
      FROM   ReceiveListItem 
      WHERE  Status = 256 AND (ListId = @listId OR ListId IN (SELECT ListId FROM ReceiveList WHERE CompositeId = @listId))
      )
   BEGIN
      SET @status = 128
   END
END

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
-- all the discrete lists WITHin the composite.
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

-- Audit status changes.  Also, if the list is a discrete that belongs to a
-- composite, set the status of the composite to change the rowversion.
SET @lastList = 0
WHILE 1 = 1 BEGIN
   SELECT TOP 1 @listName = i.ListName,
          @lastList = i.ListId,
          @status = i.Status,
          @cid = i.CompositeId
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
   END
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


COMMIT TRANSACTION
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
WHERE  Status != 1 AND (ListId = @listId OR ListId IN (SELECT ListId FROM SendList WHERE CompositeId = @listId))

-- If no active items, return zero
IF @status IS NULL RETURN 0

-- If some items have been  verified and others haven''t, set the status to partial verification.
IF @status != 8  BEGIN
   IF EXISTS 
      (
      SELECT 1 
      FROM   SendListItem 
      WHERE  Status = 8 AND (ListId = @listId OR ListId IN (SELECT ListId FROM SendList WHERE CompositeId = @listId))
      )
   BEGIN
      SET @status = 4
   END
END
IF @status NOT IN (4, 256) BEGIN 
   IF EXISTS 
      (
      SELECT 1 
      FROM   SendListItem 
      WHERE  Status = 256 AND (ListId = @listId OR ListId IN (SELECT ListId FROM SendList WHERE CompositeId = @listId))
      )
   BEGIN
      SET @status = 128
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
-- all the discrete lists WITHin the composite.
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

IF EXISTS(SELECT 1 FROM sysobjects WHERE name = 'sendList$afterUpdate' AND objectproperty(id, 'ExecIsUpdateTrigger' ) = 1) 
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

-- Audit status changes.  Also, if the list is a discrete that belongs to a
-- composite, set the status of the composite.
SET @lastList = 0
WHILE 1 = 1 BEGIN
   SELECT TOP 1 @listName = i.ListName,
          @lastList = i.ListId,
          @status = i.Status,
          @cid = i.CompositeId
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
      -- If belongs to a composite, set status of composite
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
   END
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
WHERE  Status != 1 AND (ListId = @listId OR ListId IN (SELECT ListId FROM DisasterCodeList WHERE CompositeId = @listId))

-- If no active items on list, return zero
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
-- then we have to check the list items for the all the discrete lists WITHin the composite.
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
DECLARE @rowcount int             -- holds the number of rows in the Deleted table
DECLARE @returnValue int
DECLARE @status int
DECLARE @cid int
DECLARE @cv rowversion
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
          @cid = i.CompositeId
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
         FROM   SendList
         WHERE  ListId = @cid         
         EXECUTE @returnValue = disasterCodeList$setStatus @cid, @cv
         IF @returnValue != 0 BEGIN
            ROLLBACK TRANSACTION @tranName
            COMMIT TRANSACTION
            RETURN
         END
      END
   END
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

COMMIT TRANSACTION
END
'
)

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
DECLARE @msgInsert nvarchar(512)  -- used to hold the insert message
DECLARE @tranName nvarchar(255)   -- used to hold name of savepoint
DECLARE @serialNo nvarchar(32)    -- serial number of inserted medium
DECLARE @bSide nvarchar(32)       -- b-side serial number of inserted medium
DECLARE @typeName nvarchar(128)
DECLARE @accountName nvarchar(128)
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

-- Verify that the account and medium type accord WITH the bar code formats
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

IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'auditTrail$getMedium')
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
DECLARE @mediumLike1 nvarchar(128)
DECLARE @mediumLike2 nvarchar(128)
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
SELECT @mediumLike1 = ''%Medium '''''' + @serialNo + ''''''%''
SELECT @mediumLike2 = ''%Medium '' + @serialNo + ''%''

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
WHERE (Detail LIKE @mediumLike1 OR Detail LIKE @mediumLike2) AND Date > @startDate AND Date < @endDate
UNION
SELECT ItemId, Date, Object, Action, case charindex('' list'', Detail) when 0 then Detail + '' on list '' + Object else replace(Detail, '' list'', '' list '' + Object) end, Login, 64, Object   -- Send list item
FROM   XSendListItem
WHERE (Detail LIKE @mediumLike1 OR Detail LIKE @mediumLike2) AND Date > @startDate AND Date < @endDate
UNION
SELECT ItemId, Date, Object, Action, case charindex('' list'', Detail) when 0 then Detail + '' on list '' + Object else replace(Detail, '' list'', '' list '' + Object) end, Login, 128, Object   -- Receive list item
FROM   XReceiveListItem
WHERE (Detail LIKE @mediumLike1 OR Detail LIKE @mediumLike2) AND Date > @startDate AND Date < @endDate
UNION
SELECT ItemId, Date, Object, Action, case charindex('' list'', Detail) when 0 then Detail + '' on list '' + Object else replace(Detail, '' list'', '' list '' + Object) end, Login, 256, Object   -- Disaster code list item
FROM   XDisasterCodeListItem
WHERE (Detail LIKE @mediumLike1 OR Detail LIKE @mediumLike2) AND Date > @startDate AND Date < @endDate

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
      SELECT ItemId, Date, Object, Action, Detail, Login, 256, ''''
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
END

IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'sendList$del')
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
ELSE IF @status >= 16 and @status != 512 BEGIN
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

IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'receiveList$del')
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
IF @chkOverride != 1 AND @status != 512 BEGIN
   IF @status >= 4 AND EXISTS (SELECT 1 FROM ListStatusProfile WHERE ProfileId = 2 AND Statuses & 4 != 0) BEGIN
      SET @msg = ''A list may not be deleted after it has been transmitted.'' + @msgTag + ''>''
      RAISERROR(@msg,16,1)
      RETURN -100
   END
   ELSE IF @status >= 16 AND @status != 512 BEGIN
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

-- If any bar code pattern uses this account, we cannot delete it.  No need to check
-- for media, because if no bar code pattern uses this account, then no media use it.
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

-- Checks for bar codes and lists are done in account$del, so no need to do them here

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

IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'account$del')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.account$ins
(
   @name nvarchar(256),			   -- name of the account
   @global bit,                  -- global account flag
   @address1 nvarchar(256),      -- first line of address
   @address2 nvarchar(256),      -- second line of address
   @city nvarchar(128),          -- address city
   @state nvarchar(128),         -- address state
   @zipCode nvarchar(32),        -- address zip code
   @country nvarchar(128),       -- address country
   @contact nvarchar(256),       -- contact name
   @phoneNo nvarchar(64),        -- contact phone number
   @email nvarchar(256),         -- contact email address
   @notes nvarchar(1000),        -- random notes
   @newId int OUTPUT             -- returns the id value for the newly created account
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

-- Insert the account
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

IF NOT EXISTS (SELECT 1 FROM Account WHERE AccountName = @name) BEGIN
   INSERT Account (AccountName, Global, Address1, Address2, City, State, ZipCode, Country, Contact, PhoneNo, Email, Notes)
   VALUES (@name, @global, @address1, @address2, @city, @state, @zipCode, @country, @contact, @phoneNo, @email, @notes)
   SET @error = @@error
   IF @error != 0 BEGIN
      ROLLBACK TRANSACTION @tranName
      COMMIT TRANSACTION
      SET @msg = ''Error encountered while inserting new account.'' + @msgTag + '';Error'' + cast(@error as nvarchar(50)) + ''>''
      EXECUTE error$raise @msg, @error
      RETURN -100
   END
   -- Get the scope identity
   SET @newId = scope_identity()
END
ELSE IF EXISTS (SELECT 1 FROM Account WHERE AccountName = @name AND Deleted = 1) BEGIN
   UPDATE Account
   SET    Global = @global, 
          Address1 = @address1, 
          Address2 = @address2, 
          City = @city, 
          State = @state, 
          ZipCode = @zipcode, 
          Country = @country, 
          Contact = @contact, 
          PhoneNo = @phoneNo, 
          Email = @email, 
          Notes = @notes,
          Deleted = 0
   WHERE  AccountName = @name
   SET @error = @@error
   IF @error != 0 BEGIN
      ROLLBACK TRANSACTION @tranName
      COMMIT TRANSACTION
      SET @msg = ''Error encountered while restoring account '' + @name + ''.'' + @msgTag + '';Error'' + cast(@error as nvarchar(50)) + ''>''
      EXECUTE error$raise @msg, @error
      RETURN -100
   END
   -- Get the identity
   SELECT @newId = AccountId FROM Account WHERE AccountName = @name
END
ELSE BEGIN
   ROLLBACK TRANSACTION @tranName
   COMMIT TRANSACTION
   SET @msg = ''Account '' + @name + '' already exists.'' + @msgTag + '';Error'' + cast(@error as nvarchar(50)) + ''>''
   EXECUTE error$raise @msg, @error
   RETURN -100
END

-- Return
COMMIT TRANSACTION
RETURN 0
END
'
)

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
IF NOT EXISTS (SELECT 1 FROM BarCodePattern WHERE Position < 0) BEGIN
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
   EXECUTE error$raise @msg, 0, @tranName
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

IF EXISTS(SELECT 1 FROM sysobjects WHERE name = 'barCodePattern$afterUpdate' AND objectproperty(id, 'ExecIsUpdateTrigger' ) = 1) 
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'TRIGGER barCodePattern$afterUpdate
ON     BarCodePattern
WITH ENCRYPTION
AFTER  UPDATE
AS
BEGIN
DECLARE @msg nvarchar(255)        -- used to preformat error message
DECLARE @msgTag nvarchar(255)     -- used to hold first part of error message header
DECLARE @tranName nvarchar(255)   -- used to hold name of savepoint
DECLARE @accountNo nvarchar(256)
DECLARE @mediumType nvarchar(256)
DECLARE @pattern nvarchar(256)
DECLARE @login nvarchar(256)
DECLARE @error int

IF @@rowcount != 1 RETURN

SET NOCOUNT ON

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=T''
SET @tranName = object_name(@@procid) + CAST(trigger_nestlevel(@@procid) as nvarchar(2))

-- Patterns are not allowed to change; only positions, medium types, and accounts
IF EXISTS (SELECT 1 FROM Inserted i JOIN Deleted d ON i.PatId = d.PatId WHERE i.Pattern != d.Pattern) BEGIN
   SET @msg = ''Format strings may not be updated.'' + @msgTag + ''>''
   RAISERROR(@msg, 16, 1)
   RETURN
END

-- Get the altered parameters
SELECT @pattern = i.Pattern,
       @mediumType = t.TypeName,
       @accountNo = a.AccountName
FROM   Inserted i
JOIN   Deleted d
  ON   d.PatId = i.PatId
JOIN   MediumType t
  ON   t.TypeId = i.TypeId
JOIN   Account a
  ON   a.AccountId = i.AccountId
WHERE  d.AccountId != i.AccountId OR d.TypeId != i.TypeId

-- If no rows then return; nothing to audit
IF @@rowcount = 0 RETURN

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

-- Insert the audit record
INSERT XBarCodePattern(Detail,Login)
VALUES(''Bar code format '' + @pattern + '' updated to use medium type '' + @mediumType + '' and account '' + @accountNo, @login)
SET @error = @@error
IF @error != 0 BEGIN
   SET @msg = ''Error encountered while inserting bar code pattern update audit record.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
   EXECUTE error$raise @msg, @error, @tranName
   RETURN
END

-- Commit and return
COMMIT TRANSACTION
END
'
)

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

SET NOCOUNT ON

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
DECLARE @pos int
DECLARE @i int

SET NOCOUNT ON

-- If we have a literal, use it.  If there are no literals, use a ''top 1'' statement.
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
   -- Find the first non-literal
   SELECT TOP 1 @pos = Position
   FROM   BarCodePattern
   WHERE  patindex(''%[^A-Z0-9a-z]%'', Pattern) != 0
   ORDER  BY Position ASC
   -- Select the defaults
   SELECT TOP 1 @typeName = m.TypeName,
          @accountName = a.AccountName
   FROM   BarCodePattern b
   JOIN   MediumType m
     ON   m.TypeId = b.TypeId
   JOIN   Account a
     ON   a.AccountId = b.AccountId
   WHERE  Position >= @pos AND dbo.bit$RegexMatch(@serialNo,Pattern) = 1
   ORDER  BY Position ASC
   -- If no rows, then generate error
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

IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'barCodePattern$getTable')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.barCodePattern$getTable
(
   @literals bit = 1
)
WITH ENCRYPTION
AS
BEGIN

SET NOCOUNT ON

-- Select
IF @literals = 1 BEGIN
   SELECT p.Pattern,
          p.Notes,
          m.TypeName,
          a.AccountName
   FROM   BarCodePattern p
   JOIN   MediumType m
     ON   m.TypeId = p.TypeId
   JOIN   Account a
     ON   a.AccountId = p.AccountId
   ORDER BY p.Position Asc
END
ELSE BEGIN
   SELECT p.Pattern,
          p.Notes,
          m.TypeName,
          a.AccountName
   FROM   BarCodePattern p
   JOIN   MediumType m
     ON   m.TypeId = p.TypeId
   JOIN   Account a
     ON   a.AccountId = p.AccountId
   WHERE  p.Position >= (SELECT TOP 1 Position FROM BarCodePattern WHERE patindex(''%[^A-Z0-9a-z]%'', Pattern) != 0)
   ORDER  BY p.Position ASC
END
END
'
)

IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'listFileCharacter$get')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.listFileCharacter$get
(
   @listType int,
   @vendor int
)
WITH ENCRYPTION
AS
BEGIN

SET NOCOUNT ON

-- Iron mountain makes no distiction on list type
IF @vendor = 2 SET @listType = 1

-- Get the character
SELECT Character
FROM   ListFileCharacter
WHERE  ListType = @listType AND Vendor = @vendor

END
'
)

IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'listFileCharacter$upd')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.listFileCharacter$upd
(
   @listType int,
   @vendor int,   
   @c nchar(1)
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

-- Iron mountain makes no distiction on list type
IF @vendor = 2 SET @listType = 1

-- Begin the transaction
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

-- Update the character
IF EXISTS (SELECT 1 FROM ListFileCharacter WHERE ListType = @listType AND Vendor = @vendor) BEGIN
   UPDATE ListFileCharacter 
   SET    Character = @c
   WHERE  ListType = @listType AND Vendor = @vendor
END
ELSE BEGIN
   INSERT listFileCharacter (ListType, Vendor, Character) 
   VALUES (@listType, @vendor, @c)
END

-- Evaluate the error
SET @error = @@error
IF @error != 0 BEGIN
   ROLLBACK TRANSACTION @tranName
   COMMIT TRANSACTION
   SET @msg = ''Error encountered while updating list file character.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
   EXECUTE error$raise @msg, @error
   RETURN -100
END

-- Commit and return
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
   WHERE  m.SerialNo = @serialNo AND sli.Status != 1
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
   WHERE  m.SerialNo = @serialNo AND rli.Status != 1
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
   WHERE  m.SerialNo = @serialNo AND dli.Status != 1
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
   WHERE  c.SerialNo = @serialNo AND dli.Status != 1
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
   SELECT TOP 1 @lastCase = d.CaseId
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

IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'sendListItem$upd')
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
DECLARE @doDate bit

SET NOCOUNT ON

-- Tweak parameters
SET @doDate = 1
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
      -- Check if the current case is sealed.  If it is, we can''t change
      -- the return date of the item; it will be the return date of
      -- the case; not the return date of the item.
      IF EXISTS (SELECT 1 FROM SendListCase WHERE SerialNo = @currentCase AND Sealed = 1) BEGIN
         SET @doDate = 0
      END
      -- Now remove from the case
      EXECUTE @returnValue = sendListItemCase$remove @itemId, @caseId
      IF @returnValue != 0 BEGIN
         ROLLBACK TRANSACTION @tranName
         COMMIT TRANSACTION
         RETURN -100
      END
   END
   -- Insert into new case if necessary
   IF len(@caseName) > 0 BEGIN
      EXECUTE @returnValue = sendListItemCase$ins @itemId, @caseName, NULL
      IF @returnValue != 0 BEGIN
         ROLLBACK TRANSACTION @tranName
         COMMIT TRANSACTION
         RETURN -100
      END
   END
END

-- Change the return date if allowed
IF @doDate = 1 BEGIN
   IF NOT EXISTS
      (
      SELECT 1
      FROM   SendListItem
      WHERE  ItemId = @itemId AND ReturnDate = @returnDate
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
          @cid = i.CompositeId
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
   END
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

COMMIT TRANSACTION
END
'
)

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
          @cid = i.CompositeId
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
   END
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

COMMIT TRANSACTION
END
'
)

GO
-------------------------------------------------------------------------------
--
-- Version update
--
-------------------------------------------------------------------------------
IF NOT EXISTS(SELECT 1 FROM DatabaseVersion WHERE Major = 1 AND Minor = 1 AND Revision = 2) BEGIN
   DECLARE @x nvarchar(1000)
   EXECUTE spidLogin$ins 'System', 'Insert database version'
   INSERT DatabaseVersion (Major, Minor, Revision) VALUES (1, 1, 2)
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
