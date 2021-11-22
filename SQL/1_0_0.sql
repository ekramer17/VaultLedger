-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
--
-- VaultLedger database - version 1.0.0
--
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
DECLARE @CREATE nchar(10)

SET NOCOUNT ON

IF EXISTS(SELECT 1 FROM INFORMATION_SCHEMA.ROUTINES WHERE SPECIFIC_NAME = 'bit$RegexMatch')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(  
   @CREATE + 'FUNCTION dbo.bit$RegexMatch
   ( 
    	@input varchar(4000),      -- Must be varchar type
    	@regex varchar(4000)       -- Must be varchar type
   )
   RETURNS bit
   WITH ENCRYPTION
   AS
   BEGIN
   DECLARE @match char(1)             -- Must be char type
   DECLARE @lastChar char(1)         
   DECLARE @firstChar char(1)         
   DECLARE @pattern varchar(4000)     -- Must be varchar type
   
   SELECT @firstChar = substring(@regex, 1, 1)
   SELECT @lastChar = substring(@regex, len(@regex), 1)
   -- Many expressions will start with an alphanumeric; if so, it is more
   -- efficient to check the first character of the string for non-matches
   -- before handing control over to the regex match processor.
   IF ((@firstChar >= ''A'' AND @firstChar <= ''Z'') OR (@firstChar >= ''0'' AND @firstChar <= ''9'')) BEGIN
      IF @firstChar != substring(@input, 1, 1) BEGIN
         RETURN 0
      END
   END
   -- Many expressions will end with an alphanumeric; if so, it is more
   -- efficient to check the last character of the string for non-matches
   -- before handing control over to the regex match processor.
   IF ((@lastChar >= ''A'' AND @lastChar <= ''Z'') OR (@lastChar >= ''0'' AND @lastChar <= ''9'')) BEGIN
      IF @lastChar != substring(@input, len(@input), 1) BEGIN
         RETURN 0
      END
   END
   -- If the entire pattern is alphanumeric (plus underscore), treat it as a 
   -- literal; only an exact pattern matches
   IF patindex(''%[^A-Z0-9_]%'', @regex) = 0 BEGIN
      IF @regex != @input
         RETURN 0
      ELSE
         RETURN 1
   END
   -- Hand over to the regular expression match function
   SET @pattern = ''^'' + @regex + ''$''
   EXEC master.dbo.xp_pcre_match @input, @pattern, @match OUT 
   -- Evaluate the result
   IF @match = ''1'' RETURN 1
   RETURN 0
   END
   '
)

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
--
-- Function: bit$IllegalCharacters
-- Summary:  Specifies characters that are not allowed in a string.  Generally
--           used in conjuction with bit$LegalCharacters in order to allow 
--           only a subset of the characters within one of the defined sets.
--
-- Given:    @string - string to check
--           @chars  - individual characters that should not be allowed
-- Returns:  1 if at least one disallowed character appears in string, else 0
--
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE SPECIFIC_NAME = 'bit$IllegalCharacters')
BEGIN
EXECUTE 
(  '
   CREATE FUNCTION dbo.bit$IllegalCharacters
   ( 
      @string nvarchar(4000),
      @chars  nvarchar(4000)
   )
   RETURNS bit
   WITH ENCRYPTION
   AS
   BEGIN
      DECLARE @return bit
      DECLARE @i int

      IF @string IS NULL
         SET @return = 0
      ELSE BEGIN
         SET @i = 1
         SET @return = 0
         -- Eliminate NULL data so that we may work with the strings
         SET @chars = COALESCE( @chars, '''' )
         -- For each character in the string, check to see if it matches one of
         -- the specified individual characters.  If it does, return one.
         WHILE @i <= LEN(RTRIM(@string)) BEGIN
            IF CHARINDEX( SUBSTRING(@string,@i,1), @chars ) != 0 BEGIN
              SET @return = 1
              BREAK
            END
            SET @i = @i + 1
         END
      END
      -- Return
      return @return
   END
   '
)
END

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
--
-- Function: bit$IsContainerType
-- Summary:  Tests whether a medium type is a container type
--
-- Given:    @id - id of medium type to check
-- Returns:  1 if medium type is a container type, i.e. case type, else 0
--
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE SPECIFIC_NAME = 'bit$IsContainerType')
BEGIN
EXECUTE 
(  '
   CREATE FUNCTION dbo.bit$IsContainerType
   ( 
      @typeId int
   )
   RETURNS bit
   WITH ENCRYPTION
   AS
   BEGIN
      DECLARE @return bit
      SELECT @return = Container
      FROM   MediumType
      WHERE  TypeId = @typeId
      -- Return
      RETURN @return
   END
   '
)
END

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
--
-- Function: bit$IsEmailAddress
-- Summary:  Makes sure that a given string conforms to a valid email address
--
-- Given:    @string - string to check
-- Returns:  1 if the string has a valid email address format, else 0
--
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE SPECIFIC_NAME = 'bit$IsEmailAddress')
BEGIN
EXECUTE
(  '
   CREATE FUNCTION dbo.bit$IsEmailAddress
   ( 
      @string nvarchar(4000) 
   )
   RETURNS bit
   WITH ENCRYPTION
   AS
   BEGIN
     DECLARE @return bit
     DECLARE @trim nvarchar(4000)
     SET @return = 1
     SET @trim = LTRIM(RTRIM(@string))
     -- There are a number of rules that determine whether a string conforms
     -- to a valid email format:
     -- 1. No embedded spaces
     -- 2. ''@'' cannot be the first character of an email address
     -- 3. ''.'' cannot be the last character of an email address
     -- 4. There must be a ''.'' after ''@''
     -- 5. Only one ''@'' sign is allowed
     -- 6. Domain name should end with at least 2 character extension
     -- 7. Cannot have patterns like ''.@'' and ''..'' and ''@.''
     IF @string IS NULL
        SET @return = 0
     ELSE BEGIN
        IF CHARINDEX('' '',@trim) != 0 OR
           LEFT(@trim,1) = ''@'' OR
           RIGHT(@trim,1) = ''.'' OR
           CHARINDEX(''.'',@string,CHARINDEX(''@'',@string)) - CHARINDEX(''@'',@string) = 0 OR
           LEN(LTRIM(RTRIM(@string))) - LEN(REPLACE(@trim,''@'','''')) != 1 OR
           CHARINDEX(''.'',REVERSE(@trim)) < 3 OR
           CHARINDEX(''.@'',@string) != 0 OR
           CHARINDEX(''@.'',@string) != 0 OR
           CHARINDEX(''..'',@string) != 0
           SET @return = 0
        ELSE
           SET @return = 1
     END
     -- Return
     RETURN @return
   END
   '
)
END

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
--
-- Function: bit$IsEmptyString
-- Summary:  Tests whether a string is neither empty nor NULL
--
-- Given:    @string - string to check
-- Returns:  1 if string is empty or NULL, else 0
--
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE SPECIFIC_NAME = 'bit$IsEmptyString')
BEGIN
EXECUTE 
(  '
   CREATE FUNCTION dbo.bit$IsEmptyString
   ( 
      @string nvarchar(4000) 
   )
   RETURNS bit
   WITH ENCRYPTION
   AS
   BEGIN
      DECLARE @return bit
      -- Trim the string value and add characters.  This is safer than just
      -- checking the length of rtrim, which will be NULL is the string is NULL.
      IF ( ''E'' + COALESCE(RTRIM(@string),'''') + ''K'' ) = ''EK''
         SET @return = 1
      ELSE
         SET @return = 0
      -- Return
      RETURN @return
   END
   '
)
END

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
--
-- Function: bit$IsPhoneNumber
-- Summary:  Makes sure that a given string conforms to a valid phone number
--
-- Given:    @string - string to check
-- Returns:  1 if the string has a phone number format, else 0
--
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE SPECIFIC_NAME = 'bit$IsPhoneNumber')
BEGIN
EXECUTE
(  '
   CREATE FUNCTION dbo.bit$IsPhoneNumber
   ( 
      @string nvarchar(4000) 
   )
   RETURNS bit
   WITH ENCRYPTION
   AS
   BEGIN
     DECLARE @return bit
     DECLARE @num varchar(64)
     DECLARE @c char(1)
     DECLARE @i int

     SET @i = 1
     -- Cannot be empty string
     IF dbo.bit$IsEmptyString(@string) = 1 GOTO NOPHONE
     -- Only valid characters are: ''('','')'',''+'',''-'','' '',''x'',''.'',digits
     IF dbo.bit$LegalCharacters(@string,''WHITENUMERIC'',''()+-x.'' ) = 0 GOTO NOPHONE
     -- Must start with ''('', ''+'', or digit
     IF dbo.bit$LegalCharacters(LEFT(@string,1),''NUMERIC'',''(+'' ) = 0 GOTO NOPHONE
     -- Must end with a digit
     IF ISNUMERIC(LEFT(REVERSE(@string),1)) = 0 GOTO NOPHONE
     -- No more than two sets of parentheses or two hyphens or two periods
     IF LEN(@string) - LEN(REPLACE(@string,''('','''')) > 2 GOTO NOPHONE
     IF LEN(@string) - LEN(REPLACE(@string,''-'','''')) > 2 GOTO NOPHONE
     IF LEN(@string) - LEN(REPLACE(@string,''.'','''')) > 2 GOTO NOPHONE
     -- Cannot consist of both hyphens and periods
     IF CHARINDEX(''-'',@string) > 0 AND CHARINDEX(''.'',@string) > 0 GOTO NOPHONE
     -- Go through the string character by character
     WHILE @i < LEN(@string) BEGIN
        SET @c = SUBSTRING(@string,@i,1)
        IF @c = ''('' BEGIN
           -- 1. Right parenthesis must occur after left
           -- 2. Value between the parentheses must be numeric, positive, and
           --    no more than three digits in length
           IF CHARINDEX('')'',@string,@i) = 0 GOTO NOPHONE
           SET @num = SUBSTRING(@string,@i,CHARINDEX('')'',@string,@i)-@i-1)
           IF ISNUMERIC(@num) = 0 OR CAST(@num AS int) < 0 OR CAST(@num AS int) > 999 GOTO NOPHONE
        END
        ELSE IF @c = '')'' BEGIN
           -- A left parenthesis must appear before a right parenthesis
           IF CHARINDEX(''('',SUBSTRING(@string,1,@i)) = 0 GOTO NOPHONE
        END
        ELSE IF @c = ''+'' BEGIN
           -- 1. Character after plus must be a digit
           -- 2. Plus may be either first or second character.  If second,
           --    then first character must be a left parenthesis.
           IF ISNUMERIC(SUBSTRING(@string,@i+1,1)) = 0 GOTO NOPHONE
           IF @i > 2 OR (@i = 2 AND SUBSTRING(@string,1,1) != ''('') GOTO NOPHONE
        END
        ELSE IF @c = ''-'' OR @c = ''.'' BEGIN
           -- 1. No parenthesis may occur after the first hyphen or period
           -- 2. Hyphen must have a digit on either side
           IF CHARINDEX(''('',@string,@i) > 0 GOTO NOPHONE 
           IF ISNUMERIC(SUBSTRING(@string,@i-1,1)) = 0 GOTO NOPHONE
           IF ISNUMERIC(SUBSTRING(@string,@i+1,1)) = 0 GOTO NOPHONE
        END
        ELSE IF @c = '' '' BEGIN
           -- Whitespace must be followed by a left parenthesis or a digit
           IF ISNUMERIC(SUBSTRING(@string,@i+1,1)) = 0 
              AND SUBSTRING(@string,@i+1,1) != ''('' 
              GOTO NOPHONE
        END
        ELSE IF @c = ''x'' BEGIN
           -- Only digits may follow an extension character
           IF ISNUMERIC(SUBSTRING(@string,@i+1,99)) = 0 GOTO NOPHONE
        END
        SET @i = @i+1
     END
     -- Return
     SET @return = 1
     GOTO LEAVEUDF
     NOPHONE:
     SET @return = 0
     LEAVEUDF:
     RETURN @return
   END
   '
)
END

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
--
-- Function: bit$LegalCharacters
-- Summary:  Makes sure that a given string only contains certain characters
--
-- Given:    @string - string to check
--           @codes  - codes thst correspond to particular sets of characters:
--                     WHITE - whitespace
--                     ALPHA - alphas (A-Z, a-z)
--                     NUMERIC - numerics (0-9)
--           @chars  - individual characters that do not appear in the defined 
--                     sets but should still be allowed
-- Returns:  1 if only allowed characters appear in string, else 0
--
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE SPECIFIC_NAME = 'bit$LegalCharacters')
BEGIN
EXECUTE 
(  '
   CREATE FUNCTION dbo.bit$LegalCharacters
   ( 
      @string nvarchar(4000),
      @codes  nvarchar(4000),
      @chars  nvarchar(4000)
   )
   RETURNS bit
   WITH ENCRYPTION
   AS
   BEGIN
      DECLARE @return bit
      DECLARE @alpha bit
      DECLARE @digit bit
      DECLARE @white bit
      DECLARE @c char(1)
      DECLARE @i int

      IF @string IS NULL
         SET @return = 0
      ELSE BEGIN
         SET @i = 1
         SET @return = 1
         -- Eliminate NULL data so that we may work with the strings
         SET @codes = COALESCE( @codes, '''' )
         SET @chars = COALESCE( @chars, '''' )
         -- Set the flags for the character set codes
         IF CHARINDEX( ''ALPHA'', @codes ) = 0
            SET @alpha = 0
         ELSE
            SET @alpha = 1
         IF CHARINDEX( ''NUMERIC'', @codes ) = 0
            SET @digit = 0
         ELSE
            SET @digit = 1
         IF CHARINDEX( ''WHITE'', @codes ) = 0
            SET @white = 0
         ELSE
            SET @white = 1
         -- For each character in the string, check to see if it matches one of
         -- the specified individual characters.  If it does not, check it
         -- against the character code sets.  If it does not fall within an
         -- allowed set, then return zero.  Note that when comparing characters
         -- we only need to specify uppercase due to case-insensitivity.
         WHILE @i <= LEN(RTRIM(@string)) BEGIN
            SET @c = SUBSTRING(@string,@i,1)
            IF CHARINDEX( @c, @chars ) = 0 BEGIN
              IF @c >= ''A'' AND @c <= ''Z'' BEGIN
                 IF @alpha = 0 BEGIN
                    SET @return = 0
                    BREAK
                 END
              END
              ELSE IF @c >= ''0'' AND @c <= ''9'' BEGIN
                 IF @digit = 0 BEGIN
                    SET @return = 0
                    BREAK
                 END
              END
              ELSE IF @c = '' '' BEGIN
                 IF @white = 0 BEGIN
                    SET @return = 0
                    BREAK
                 END
              END
              ELSE BEGIN
                 SET @return = 0
                 BREAK
              END
            END
            -- Increment i
            SET @i = @i + 1
         END
      END
      -- Return
      return @return
   END
   '
)
END

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
--
-- Function: int$max
-- Summary:  Returns the larger of two integers
--
-- Given:    @integer1 - first integer
--           @integer2 - second integer
--           
--
-- Returns:  The larger of the two integers
--
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
IF NOT EXISTS(SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE SPECIFIC_NAME = 'int$max')
   SET @CREATE = 'CREATE '
ELSE
   SET @CREATE = 'ALTER '

EXECUTE
(  
   @CREATE + ' FUNCTION dbo.int$max
   (
      @integer1 int,
      @integer2 int
   )
   RETURNS int
   WITH ENCRYPTION
   AS
   BEGIN
   IF @integer1 > @integer2 RETURN @integer1
   RETURN @integer2
   END
   '
)

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
--
-- Function: int$min
-- Summary:  Returns the larger of two integers
--
-- Given:    @integer1 - first integer
--           @integer2 - second integer
--           
--
-- Returns:  The larger of the two integers
--
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
IF NOT EXISTS(SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE SPECIFIC_NAME = 'int$min')
   SET @CREATE = 'CREATE '
ELSE
   SET @CREATE = 'ALTER '

EXECUTE
(  
   @CREATE + ' FUNCTION dbo.int$min
   (
      @integer1 int,
      @integer2 int
   )
   RETURNS int
   WITH ENCRYPTION
   AS
   BEGIN
   IF @integer1 < @integer2 RETURN @integer1
   RETURN @integer2
   END
   '
)

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
--
-- Function: string$GetSpidInfo
-- Summary:  Retrieves the tag string of the row in the SpidLogin table for
--           the current @@spid.
--
-- Given:    Nothing
-- Returns:  String from the SpidLogin table on success, else empty string
--
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
IF NOT EXISTS(SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE SPECIFIC_NAME = 'string$GetSpidInfo')
   SET @CREATE = 'CREATE '
ELSE
   SET @CREATE = 'ALTER '

EXECUTE
(  
   @CREATE + ' FUNCTION dbo.string$GetSpidInfo()
   RETURNS nvarchar(1000)
   WITH ENCRYPTION
   AS
   BEGIN
   DECLARE @info nvarchar(1000)
   SELECT @info = TagInfo
   FROM   SpidLogin
   WHERE  Spid = @@spid
   RETURN coalesce(@info,'''')
   END
   '
)

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
--
-- Function: string$GetSpidLogin
-- Summary:  Gets the ancillary information associated with the current spid
--
-- Given:    Nothing
-- Returns:  1 if login exists, else 0
--
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
IF NOT EXISTS(SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE SPECIFIC_NAME = 'string$GetSpidLogin')
   SET @CREATE = 'CREATE '
ELSE
   SET @CREATE = 'ALTER '

EXECUTE
(  
   @CREATE + 'FUNCTION dbo.string$GetSpidLogin()
   RETURNS nvarchar(32)
   WITH ENCRYPTION
   AS
   BEGIN
   DECLARE @login nvarchar(32)
   SELECT @login = Login
   FROM   SpidLogin
   WHERE  Spid = @@spid
   IF @@rowcount = 0 RETURN ''''
   RETURN @login
   END
   '
)
GO

SET NOCOUNT ON
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
--
-- Table Declarations
--
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'SpidLogin') BEGIN
CREATE TABLE dbo.SpidLogin
(
-- Attributes
   Spid        int               NOT NULL  CONSTRAINT pkSpidLogin PRIMARY KEY CLUSTERED,
   Login       nvarchar(32)      NOT NULL,
   LastCall    datetime          NOT NULL,
   TagInfo     nvarchar(1000)    NOT NULL  CONSTRAINT defSpidLogin$TagInfo DEFAULT ''
)
END
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'Subscription') BEGIN
CREATE TABLE dbo.Subscription
(
-- Attributes
   Number  nvarchar(40)  NOT NULL
)
END
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'Preference') BEGIN
CREATE TABLE dbo.Preference
(
-- Attributes
   KeyNo  int           NOT NULL  CONSTRAINT pkPreference PRIMARY KEY CLUSTERED,
   Value  nvarchar(64)  NOT NULL  CONSTRAINT defPreference$Value DEFAULT ''
)
END
GO

-- Insert default preferences
INSERT SpidLogin (Spid, Login, LastCall) VALUES (@@spid, 'System', getdate())
IF NOT EXISTS (SELECT 1 FROM Preference WHERE KeyNo = 1) INSERT Preference (KeyNo, Value) VALUES (1, 'YES')     -- TMS return dates
IF NOT EXISTS (SELECT 1 FROM Preference WHERE KeyNo = 2) INSERT Preference (KeyNo, Value) VALUES (2, 'YES')     -- Ignore unknown sites
IF NOT EXISTS (SELECT 1 FROM Preference WHERE KeyNo = 3) INSERT Preference (KeyNo, Value) VALUES (3, 'REPLACE') -- Data set notes
IF NOT EXISTS (SELECT 1 FROM Preference WHERE KeyNo = 4) INSERT Preference (KeyNo, Value) VALUES (4, 'YES')     -- Do not ignore cases when verifying send lists
IF NOT EXISTS (SELECT 1 FROM Preference WHERE KeyNo = 5) INSERT Preference (KeyNo, Value) VALUES (5, 'YES')     -- Use standard bar code editing
IF NOT EXISTS (SELECT 1 FROM Preference WHERE KeyNo = 6) INSERT Preference (KeyNo, Value) VALUES (6, 'YES')     -- Exclude active lists from inventory reconciling
IF NOT EXISTS (SELECT 1 FROM Preference WHERE KeyNo = 7) INSERT Preference (KeyNo, Value) VALUES (7, 'YES')     -- Exclude today's lists from inventory reconciling
DELETE SpidLogin WHERE Spid = @@spid
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'Account') BEGIN
CREATE TABLE dbo.Account
(
-- Attributes
   AccountId       int             NOT NULL  CONSTRAINT pkAccount             PRIMARY KEY CLUSTERED IDENTITY(1,1),
   AccountName     nvarchar(256)   NOT NULL  CONSTRAINT akAccount$AccountName UNIQUE NONCLUSTERED,
   Global          bit             NOT NULL  CONSTRAINT defAccount$Global     DEFAULT 0,
   Address1        nvarchar(256)   NOT NULL  CONSTRAINT defAccount$Address1   DEFAULT '',
   Address2        nvarchar(256)   NOT NULL  CONSTRAINT defAccount$Address2   DEFAULT '',
   City            nvarchar(128)   NOT NULL  CONSTRAINT defAccount$City       DEFAULT '',
   State           nvarchar(128)   NOT NULL  CONSTRAINT defAccount$State      DEFAULT '',
   ZipCode         nvarchar(32)    NOT NULL  CONSTRAINT defAccount$ZipCode    DEFAULT '',
   Country         nvarchar(128)   NOT NULL  CONSTRAINT defAccount$Country    DEFAULT '',
   Contact         nvarchar(256)   NOT NULL  CONSTRAINT defAccount$Contact    DEFAULT '',
   PhoneNo         nvarchar(64)    NOT NULL  CONSTRAINT defAccount$PhoneNo    DEFAULT '',
   Email           nvarchar(256)   NOT NULL  CONSTRAINT defAccount$Email      DEFAULT '',
   Notes           nvarchar(1000)  NOT NULL  CONSTRAINT defAccount$Notes      DEFAULT '',
   Deleted         bit             NOT NULL  CONSTRAINT defAccount$Deleted    DEFAULT 0,
-- Concurrency
   RowVersion      rowversion      NOT NULL
)
END
GO

-- Must have a name, which may not contain pipes (used as escpae character)
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.CHECK_CONSTRAINTS WHERE CONSTRAINT_NAME = 'chkAccount$AccountName')
   ALTER TABLE Account ADD CONSTRAINT chkAccount$AccountName
      CHECK (dbo.bit$IsEmptyString(AccountName) = 0 AND dbo.bit$IllegalCharacters(AccountName, '|' ) = 0)
GO

-- Must have an address
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.CHECK_CONSTRAINTS WHERE CONSTRAINT_NAME = 'chkAccount$Address1')
   ALTER TABLE Account ADD CONSTRAINT chkAccount$Address1 CHECK (dbo.bit$IsEmptyString(Address1) = 0)
GO

-- Must have a city
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.CHECK_CONSTRAINTS WHERE CONSTRAINT_NAME = 'chkAccount$City')
   ALTER TABLE Account ADD CONSTRAINT chkAccount$City CHECK (dbo.bit$IsEmptyString(City) = 0)
GO

-- Must have a country
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.CHECK_CONSTRAINTS WHERE CONSTRAINT_NAME = 'chkAccount$Country')
   ALTER TABLE Account ADD CONSTRAINT chkAccount$Country CHECK (dbo.bit$IsEmptyString(Country) = 0)
GO

-- Must have a correct phone number format
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.CHECK_CONSTRAINTS WHERE CONSTRAINT_NAME = 'chkAccount$PhoneNo')
   ALTER TABLE Account ADD CONSTRAINT chkAccount$PhoneNo CHECK (dbo.bit$IsPhoneNumber(PhoneNo) = 1 OR dbo.bit$IsEmptyString(PhoneNo) = 1)
GO

-- Must have a correct email address format
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.CHECK_CONSTRAINTS WHERE CONSTRAINT_NAME = 'chkAccount$Email')
   ALTER TABLE Account ADD CONSTRAINT chkAccount$Email CHECK (dbo.bit$IsEmailAddress(Email) = 1 OR dbo.bit$IsEmptyString(Email) = 1)
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'Operator') BEGIN
CREATE TABLE dbo.Operator
(
-- Attributes
   OperatorId    int             NOT NULL  CONSTRAINT pkOperator          PRIMARY KEY CLUSTERED  IDENTITY(1,1),
   OperatorName  nvarchar(256)   NOT NULL,
   Login         nvarchar(32)    NOT NULL  CONSTRAINT akOperator$Login    UNIQUE NONCLUSTERED,
   Password      nvarchar(128)   NOT NULL,
   Salt          nvarchar(20)    NOT NULL,
   Role          int             NOT NULL, -- (10 - Viewer, 20 - Operator, 30 - Auditor, 40 - Administrator)
   PhoneNo       nvarchar(64)    NOT NULL  CONSTRAINT defOperator$PhoneNo DEFAULT '',
   Email         nvarchar(256)   NOT NULL  CONSTRAINT defOperator$Email   DEFAULT '',
   Notes         nvarchar(1000)  NOT NULL  CONSTRAINT defOperator$Notes   DEFAULT '',
-- Concurrency
   RowVersion    rowversion      NOT NULL
)
END
GO

-- Logins may not contain pipes (used as escpae character)
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.CHECK_CONSTRAINTS WHERE CONSTRAINT_NAME = 'chkOperator$Login')
   ALTER TABLE Operator ADD CONSTRAINT chkOperator$Login
      CHECK (dbo.bit$IsEmptyString(Login) = 0 AND dbo.bit$IllegalCharacters(Login, '!') = 0)
GO

-- Login cannot be the reserved words 'System' or 'VaultLedger'
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.CHECK_CONSTRAINTS WHERE CONSTRAINT_NAME = 'chkOperator$System')
   ALTER TABLE Operator ADD CONSTRAINT chkOperator$System CHECK (Login != 'System' AND Login != 'VaultLedger')
GO

-- Original user must have administrator privileges
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.CHECK_CONSTRAINTS WHERE CONSTRAINT_NAME = 'chkOperator$Admin')
   ALTER TABLE Operator ADD CONSTRAINT chkOperator$Admin CHECK (OperatorId != 1 OR Role = 32768)
GO

-- User names may not contain pipes (used as escpae character)
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.CHECK_CONSTRAINTS WHERE CONSTRAINT_NAME = 'chkOperator$Name')
   ALTER TABLE Operator ADD CONSTRAINT chkOperator$Name CHECK (dbo.bit$IllegalCharacters(OperatorName, '|' ) = 0)
GO

-- Acceptable role values
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.CHECK_CONSTRAINTS WHERE CONSTRAINT_NAME = 'chkOperator$Role')
   ALTER TABLE Operator ADD CONSTRAINT chkOperator$Role CHECK (Role IN (8, 128, 2048, 32768))
GO

-- Email addresses must be of email format
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.CHECK_CONSTRAINTS WHERE CONSTRAINT_NAME = 'chkOperator$Email')
   ALTER TABLE Operator ADD CONSTRAINT chkOperator$Email CHECK (dbo.bit$IsEmailAddress(Email) = 1 OR dbo.bit$IsEmptyString(Email) = 1)
GO

-- Insert initial operator
 IF NOT EXISTS (SELECT 1 FROM Operator WHERE OperatorId = 1) BEGIN
   INSERT SpidLogin (Spid, Login, LastCall) VALUES (@@spid, 'System', getdate())
   INSERT Operator (OperatorName, Login, Password, Salt, Role)
   VALUES ('Administrator', 'Administrator', 'E23512B9731C2B52367931AD04C20E20FE4FB2A6', 'kAeYquc=', 32768)
   DELETE SpidLogin WHERE Spid = @@spid
END
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'RecallTicket') BEGIN
CREATE TABLE dbo.RecallTicket
(
-- Attributes
   OperatorId  int               NOT NULL  CONSTRAINT pkRecallTicket PRIMARY KEY CLUSTERED,  -- No foreign key
   Ticket      uniqueidentifier  NOT NULL,
   CreateDate  datetime          NOT NULL  CONSTRAINT defRecallTicket$CreateDate DEFAULT getdate()
)
END
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'MediumType') BEGIN
CREATE TABLE dbo.MediumType
(
-- Attributes
   TypeId       int            NOT NULL  CONSTRAINT pkMediumType             PRIMARY KEY CLUSTERED  IDENTITY(1,1),
   TypeName     nvarchar(128)  NOT NULL  CONSTRAINT akMediumType$TypeName    UNIQUE NONCLUSTERED,
   TwoSided     bit            NOT NULL  CONSTRAINT defMediumType$TwoSided   DEFAULT 0,
   Container    bit            NOT NULL  CONSTRAINT defMediumType$Container  DEFAULT 0,
   Deleted      bit            NOT NULL  CONSTRAINT defMediumType$Deleted    DEFAULT 0,
-- Concurrency
   RowVersion   rowversion     NOT NULL
)
END
GO

IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.CHECK_CONSTRAINTS WHERE CONSTRAINT_NAME = 'chkMediumType$Name')
   ALTER TABLE MediumType ADD CONSTRAINT chkMediumType$Name CHECK (dbo.bit$IsEmptyString(TypeName) = 0)
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'RecallCode') BEGIN
CREATE TABLE dbo.RecallCode
(
-- Attributes   
   Code    nchar(2)  NOT NULL  CONSTRAINT akRecallCode$TypeCode UNIQUE NONCLUSTERED,
-- Relationships
   TypeId  int       NOT NULL  CONSTRAINT pkRecallCode PRIMARY KEY CLUSTERED
)
END
GO

IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.CHECK_CONSTRAINTS WHERE CONSTRAINT_NAME = 'chkRecallCode$Code')
   ALTER TABLE RecallCode ADD CONSTRAINT chkRecallCode$Code CHECK (dbo.bit$IsEmptyString(Code) = 0)
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS WHERE CONSTRAINT_NAME = 'fkRecallCode$MediumType') BEGIN
ALTER TABLE dbo.RecallCode
   ADD CONSTRAINT fkRecallCode$MediumType
      FOREIGN KEY (TypeId) REFERENCES dbo.MediumType
         ON DELETE CASCADE
END
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'SealedCase') BEGIN
CREATE TABLE dbo.SealedCase
(
-- Attributes
   CaseId      int             NOT NULL  CONSTRAINT pkSealedCase            PRIMARY KEY CLUSTERED  IDENTITY(1,1),
   SerialNo    nvarchar(32)    NOT NULL  CONSTRAINT akSealedCase$SerialNo   UNIQUE NONCLUSTERED,
   ReturnDate  datetime        NULL,
   HotStatus   bit             NOT NULL  CONSTRAINT defSealedCase$HotStatus DEFAULT 0,
   Notes       nvarchar(1000)  NOT NULL  CONSTRAINT defSealedCase$Notes     DEFAULT '',
-- Relationships
   TypeId      int             NOT NULL,
-- Concurrency
   RowVersion  rowversion      NOT NULL
)
END
GO

-- Case serial numbers may only consist of alphanumerics
IF NOT EXISTS(SELECT 1 FROM INFORMATION_SCHEMA.CHECK_CONSTRAINTS WHERE CONSTRAINT_NAME = 'chkSealedCase$SerialNo')
   ALTER TABLE SealedCase ADD CONSTRAINT chkSealedCase$SerialNo
      CHECK (dbo.bit$IsEmptyString(SerialNo) = 0 AND dbo.bit$LegalCharacters(SerialNo, 'ALPHANUMERIC', '.-_$[]%+' ) = 1 )
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS WHERE CONSTRAINT_NAME = 'fkSealedCase$Type') BEGIN
ALTER TABLE dbo.SealedCase
   ADD CONSTRAINT fkSealedCase$Type
      FOREIGN KEY (TypeId) REFERENCES dbo.MediumType
END
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'Medium') BEGIN
CREATE TABLE dbo.Medium
(
-- Attributes
   MediumId      int            NOT NULL  CONSTRAINT pkMedium               PRIMARY KEY CLUSTERED  IDENTITY(1,1),
   SerialNo      nvarchar(32)   NOT NULL  CONSTRAINT akMedium$SerialNo      UNIQUE NONCLUSTERED,
   Location      bit            NOT NULL,
   LastMoveDate  datetime       NULL,
   HotStatus     bit            NOT NULL  CONSTRAINT defMedium$HotStatus    DEFAULT 0,
   Missing       bit            NOT NULL  CONSTRAINT defMedium$Missing      DEFAULT 0,
   ReturnDate    datetime       NULL,
   BSide         nvarchar(32)   NOT NULL  CONSTRAINT defMedium$BSide        DEFAULT '',
   Notes         nvarchar(1000) NOT NULL  CONSTRAINT defMedium$Notes        DEFAULT '',
-- Relationships
   TypeId        int            NOT NULL,
   AccountId     int            NOT NULL,
-- Concurrency
   RowVersion    rowversion     NOT NULL,
)
END
GO

-- Serial numbers may only include certain characters
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.CHECK_CONSTRAINTS WHERE CONSTRAINT_NAME = 'chkMedium$SerialNo')
   ALTER TABLE Medium ADD CONSTRAINT chkMedium$SerialNo
      CHECK (dbo.bit$IsEmptyString(SerialNo) = 0 AND dbo.bit$LegalCharacters(SerialNo, 'ALPHANUMERIC', '.-_$[]%+' ) = 1)
GO

-- B-side serial number may only consist of alphanumerics
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.CHECK_CONSTRAINTS WHERE CONSTRAINT_NAME = 'chkMedium$BSide')
   ALTER TABLE Medium ADD CONSTRAINT chkMedium$BSide CHECK (dbo.bit$LegalCharacters(BSide, 'ALPHANUMERIC', '.-_$[]%+' ) = 1)
GO

-- A medium at the enterprise may not have a return date nor be designated as at the hot site
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.CHECK_CONSTRAINTS WHERE CONSTRAINT_NAME = 'chkMedium$Location')
   ALTER TABLE Medium ADD CONSTRAINT chkMedium$Location
      CHECK (NOT(Location = 1 AND (HotStatus = 1 OR ReturnDate IS NOT NULL)))
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS WHERE CONSTRAINT_NAME = 'fkMedium$Type') BEGIN
ALTER TABLE dbo.Medium 
   ADD CONSTRAINT fkMedium$Type
      FOREIGN KEY (TypeId) REFERENCES dbo.MediumType
END
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS WHERE CONSTRAINT_NAME = 'fkMedium$Account') BEGIN
ALTER TABLE dbo.Medium
   ADD CONSTRAINT fkMedium$Account 
      FOREIGN KEY (AccountId) REFERENCES dbo.Account
END
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'MediumSealedCase') BEGIN
CREATE TABLE dbo.MediumSealedCase
(
-- Relationships
   CaseId      int         NOT NULL,
   MediumId    int         NOT NULL CONSTRAINT pkMediumSealedCase PRIMARY KEY CLUSTERED,
)
END
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS WHERE CONSTRAINT_NAME = 'fkMediumSealedCase$SealedCase') BEGIN
ALTER TABLE dbo.MediumSealedCase
   ADD CONSTRAINT fkMediumSealedCase$SealedCase
      FOREIGN KEY (CaseId) REFERENCES dbo.SealedCase
         ON DELETE CASCADE
END
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS WHERE CONSTRAINT_NAME = 'fkMediumSealedCase$Medium') BEGIN
ALTER TABLE dbo.MediumSealedCase
   ADD CONSTRAINT fkMediumSealedCase$Medium
      FOREIGN KEY (MediumId) REFERENCES dbo.Medium
        ON DELETE CASCADE
END
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'DisasterCode') BEGIN
CREATE TABLE dbo.DisasterCode
(
-- Attributes
   CodeId      int             NOT NULL  CONSTRAINT pkDisasterCode        PRIMARY KEY CLUSTERED  IDENTITY(1,1),
   Code        nvarchar(32)    NOT NULL  CONSTRAINT akDisasterCode$Code   UNIQUE NONCLUSTERED,
   Notes       nvarchar(1000)  NOT NULL  CONSTRAINT defDisasterCode$Notes DEFAULT '',
-- Concurrency
   RowVersion  rowversion     NOT NULL
)
END
GO

-- Disaster code may only consist of alphanumerics
IF NOT EXISTS(SELECT 1 FROM INFORMATION_SCHEMA.CHECK_CONSTRAINTS WHERE CONSTRAINT_NAME = 'chkDisasterCode$Code')
   ALTER TABLE DisasterCode ADD CONSTRAINT chkDisasterCode$Code
      CHECK (dbo.bit$IsEmptyString(Code) = 0 AND dbo.bit$LegalCharacters(Code, 'ALPHANUMERIC', NULL ) = 1)
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'DisasterCodeMedium') BEGIN
CREATE TABLE dbo.DisasterCodeMedium
(
-- Relationships
   CodeId     int  NOT NULL,
   MediumId   int  NOT NULL  CONSTRAINT akDisasterCodeMedium$Medium UNIQUE NONCLUSTERED,
-- Composite Constraints
   CONSTRAINT pkDisasterCodeMedium PRIMARY KEY CLUSTERED (CodeId,MediumId)
)
END
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS WHERE CONSTRAINT_NAME = 'fkDisasterCodeMedium$DisasterCode') BEGIN
ALTER TABLE dbo.DisasterCodeMedium
   ADD CONSTRAINT fkDisasterCodeMedium$DisasterCode
      FOREIGN KEY (CodeId) REFERENCES dbo.DisasterCode
         ON DELETE CASCADE
END
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS WHERE CONSTRAINT_NAME = 'fkDisasterCodeMedium$Medium') BEGIN
ALTER TABLE dbo.DisasterCodeMedium
   ADD CONSTRAINT fkDisasterCodeMedium$Medium
      FOREIGN KEY (MediumId) REFERENCES dbo.Medium
         ON DELETE CASCADE
END
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'DisasterCodeCase') BEGIN
CREATE TABLE dbo.DisasterCodeCase
(
-- Relationships
   CodeId  int  NOT NULL,
   CaseId  int  NOT NULL  CONSTRAINT akDisasterCodeCase$Medium UNIQUE NONCLUSTERED,
-- Composite Constraints
   CONSTRAINT pkDisasterCodeCase PRIMARY KEY CLUSTERED (CodeId,CaseId)
)
END
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS WHERE CONSTRAINT_NAME = 'fkDisasterCodeCase$DisasterCode') BEGIN
ALTER TABLE dbo.DisasterCodeCase
   ADD CONSTRAINT fkDisasterCodeCase$DisasterCode
      FOREIGN KEY (CodeId) REFERENCES dbo.DisasterCode
         ON DELETE CASCADE
END
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS WHERE CONSTRAINT_NAME = 'fkDisasterCodeCase$SealedCase') BEGIN
ALTER TABLE dbo.DisasterCodeCase
   ADD CONSTRAINT fkDisasterCodeCase$SealedCase
      FOREIGN KEY (CaseId) REFERENCES dbo.SealedCase
         ON DELETE CASCADE
END
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'NextListNumber') BEGIN
CREATE TABLE dbo.NextListNumber
(
-- Attributes
   ListType    nchar(2)     NOT NULL  CONSTRAINT pkNextListNumber PRIMARY KEY NONCLUSTERED,
   Numeral     int          NOT NULL,
-- Concurrency
   RowVersion  rowversion   NOT NULL
)
END
GO

IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.CHECK_CONSTRAINTS WHERE CONSTRAINT_NAME = 'chkNextListNumber$ListType')
   ALTER TABLE NextListNumber ADD CONSTRAINT chkNextListNumber$ListType CHECK (ListType IN ('SD','RE','DC'))
GO

IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.CHECK_CONSTRAINTS WHERE CONSTRAINT_NAME = 'chkNextListNumber$Numeral')
   ALTER TABLE NextListNumber ADD CONSTRAINT chkNextListNumber$Numeral CHECK (Numeral > 0)
GO

IF NOT EXISTS(SELECT 1 FROM NextListNumber WHERE ListType = 'SD')
   INSERT NextListNumber (ListType, Numeral) VALUES ('SD', 1)
GO

IF NOT EXISTS(SELECT 1 FROM NextListNumber WHERE ListType = 'RE')
   INSERT NextListNumber (ListType, Numeral) VALUES ('RE', 1)
GO

IF NOT EXISTS(SELECT 1 FROM NextListNumber WHERE ListType = 'DC')
   INSERT NextListNumber (ListType, Numeral) VALUES ('DC', 1)
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'SendList') BEGIN
CREATE TABLE dbo.SendList
(
-- Attributes
   ListId       int             NOT NULL  CONSTRAINT pkSendList PRIMARY KEY CLUSTERED  IDENTITY(1,1),
   ListName     nchar(10)       NOT NULL  CONSTRAINT akSendList$akListName UNIQUE NONCLUSTERED,
   CreateDate   datetime        NOT NULL,
   Status       int             NOT NULL  CONSTRAINT defSendList$Status DEFAULT 4, -- power(4,x)
   Notes        nvarchar(1000)  NOT NULL  CONSTRAINT defSendList$Notes DEFAULT '', 
-- Relationships
   AccountId    int             NULL,
   CompositeId  int             NULL,
-- Concurrency
   RowVersion   rowversion      NOT NULL
)
END
GO

-- List name format: SD-0000000
IF NOT EXISTS(SELECT * FROM INFORMATION_SCHEMA.CHECK_CONSTRAINTS WHERE CONSTRAINT_NAME = 'chkSendList$ListName')
   ALTER TABLE SendList ADD CONSTRAINT chkSendList$ListName
      CHECK (LEFT(ListName,3) = 'SD-' AND dbo.bit$LegalCharacters(SUBSTRING(ListName,4,7), 'NUMERIC', NULL ) = 1)
GO

-- Valid status values
IF NOT EXISTS(SELECT * FROM INFORMATION_SCHEMA.CHECK_CONSTRAINTS WHERE CONSTRAINT_NAME = 'chkSendList$Status')
   ALTER TABLE SendList ADD CONSTRAINT chkSendList$Status CHECK (Status IN (4, 16, 64, 256, 1024)) -- power(4,x)
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS WHERE CONSTRAINT_NAME = 'fkSendList$Account') BEGIN
ALTER TABLE dbo.SendList
   ADD CONSTRAINT fkSendList$Account
      FOREIGN KEY (AccountId) REFERENCES dbo.Account
END
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS WHERE CONSTRAINT_NAME = 'fkSendList$Composite') BEGIN
ALTER TABLE dbo.SendList
   ADD CONSTRAINT fkSendList$Composite
      FOREIGN KEY (CompositeId) REFERENCES dbo.SendList
         -- Cannot cascasde delete due to possible circular implications
END
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'SendListItem') BEGIN
CREATE TABLE dbo.SendListItem
(
-- Attributes
   ItemId      int             NOT NULL  CONSTRAINT pkSendListItem PRIMARY KEY CLUSTERED  IDENTITY(1,1),
   Status      int             NOT NULL,
   ReturnDate  datetime        NULL,
   Notes       nvarchar(1000)  NOT NULL  CONSTRAINT defSendListItem$Notes DEFAULT '', 
-- Relationships
   ListId      int             NOT NULL,
   MediumId    int             NOT NULL,
-- Concurrency
   RowVersion  rowversion      NOT NULL
-- Composite Constraints
   CONSTRAINT akSendListItem$ListMedium UNIQUE NONCLUSTERED (ListId,MediumId)
)
END
GO

-- Valid status values
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.CHECK_CONSTRAINTS WHERE CONSTRAINT_NAME = 'chkSendListItem$Status')
   ALTER TABLE SendListItem ADD CONSTRAINT chkSendListItem$Status CHECK (Status IN (1, 4, 64, 256, 1024)) -- power(4,x) // 16 is skipped to keep consistent with list status (no partially verified)
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS WHERE CONSTRAINT_NAME = 'fkSendListItem$SendList') BEGIN
ALTER TABLE dbo.SendListItem
   ADD CONSTRAINT fkSendListItem$SendList
      FOREIGN KEY (ListId) REFERENCES dbo.SendList
         ON DELETE CASCADE
END
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS WHERE CONSTRAINT_NAME = 'fkSendListItem$Medium') BEGIN
ALTER TABLE dbo.SendListItem
   ADD CONSTRAINT fkSendListItem$Medium
      FOREIGN KEY (MediumId) REFERENCES dbo.Medium
         ON DELETE CASCADE
END
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'SendListCase') BEGIN
CREATE TABLE dbo.SendListCase
(
-- Attributes
   CaseId       int             NOT NULL  CONSTRAINT pkSendListCase PRIMARY KEY CLUSTERED  IDENTITY(1,1),
   SerialNo     nvarchar(32)    NOT NULL,
   ReturnDate   datetime        NULL,
   Sealed       bit             NOT NULL  CONSTRAINT defSendListCase$Sealed DEFAULT 0,
   Cleared      bit             NOT NULL  CONSTRAINT defSendListCase$Cleared DEFAULT 0,
   Notes        nvarchar(1000)  NOT NULL  CONSTRAINT defSendListCase$Notes DEFAULT '',
-- Relationships
   TypeId       int             NOT NULL,
-- Concurrency
   RowVersion   rowversion      NOT NULL
)
END
GO

IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.CHECK_CONSTRAINTS WHERE CONSTRAINT_NAME = 'chkSendListCase$SerialNo')
   ALTER TABLE SendListCase ADD CONSTRAINT chkSendListCase$SerialNo
      CHECK (dbo.bit$IsEmptyString(SerialNo) = 0 AND dbo.bit$LegalCharacters(SerialNo, 'ALPHANUMERIC', '.-_$[]%+' ) = 1 )
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS WHERE CONSTRAINT_NAME = 'fkSendListCase$Type') BEGIN
ALTER TABLE dbo.SendListCase
   ADD CONSTRAINT fkSendListCase$Type
      FOREIGN KEY (TypeId) REFERENCES dbo.MediumType
END
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'SendListItemCase') BEGIN
CREATE TABLE dbo.SendListItemCase
(
-- Relationships
   ItemId       int         NOT NULL  CONSTRAINT pkSendListItemCase PRIMARY KEY CLUSTERED,
   CaseId       int         NOT NULL
)
END
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS WHERE CONSTRAINT_NAME = 'fkSendListItemCase$SendListItem') BEGIN
ALTER TABLE dbo.SendListItemCase
   ADD CONSTRAINT fkSendListItemCase$SendListItem
      FOREIGN KEY (ItemId) REFERENCES dbo.SendListItem
         ON DELETE CASCADE
END
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS WHERE CONSTRAINT_NAME = 'fkSendListItemCase$SendListCase') BEGIN
ALTER TABLE dbo.SendListItemCase
   ADD CONSTRAINT fkSendListItemCase$SendListCase
      FOREIGN KEY (CaseId) REFERENCES dbo.SendListCase
END
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'SendListScan') BEGIN
CREATE TABLE dbo.SendListScan
(
-- Attributes
   ScanId        int            NOT NULL  CONSTRAINT pkSendListScan PRIMARY KEY CLUSTERED  IDENTITY(1,1),
   ScanName      nvarchar(256)  NOT NULL  CONSTRAINT akSendListScan$Name UNIQUE NONCLUSTERED,
   CreateDate    datetime       NOT NULL  CONSTRAINT defSendListScan$Date DEFAULT cast(convert(nchar(19),getdate(),120) as datetime),
   Compared      datetime       NULL,
-- Relationships
   ListId        int            NULL
)
END
GO

IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.CHECK_CONSTRAINTS WHERE CONSTRAINT_NAME = 'chkSendListScan$Name')
   ALTER TABLE SendListScan ADD CONSTRAINT chkSendListScan$Name
      CHECK (dbo.bit$IsEmptyString(ScanName) = 0 AND dbo.bit$IllegalCharacters(ScanName, '_%' ) = 0 )
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS WHERE CONSTRAINT_NAME = 'fkSendListScan$SendList') BEGIN
ALTER TABLE dbo.SendListScan
   ADD CONSTRAINT fkSendListScan$SendList
      FOREIGN KEY (ListId) REFERENCES dbo.SendList
         ON DELETE CASCADE
END
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'SendListScanItem') BEGIN
CREATE TABLE dbo.SendListScanItem
(
-- Attributes
   ItemId       int           NOT NULL  CONSTRAINT pkSendListScanItem PRIMARY KEY CLUSTERED  IDENTITY(1,1),
   SerialNo     nvarchar(32)  NOT NULL,
   CaseName     nvarchar(32)  NOT NULL,
   Ignored      bit           NOT NULL  CONSTRAINT defSendListScanItem$Ignored DEFAULT 0,
-- Relationships
   ScanId       int           NOT NULL,
-- Composite Constraints
   CONSTRAINT akSendListScanItem$SerialNo UNIQUE NONCLUSTERED (ScanId,SerialNo)
)
END
GO

IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.CHECK_CONSTRAINTS WHERE CONSTRAINT_NAME = 'chkSendListScanItem$SerialNo')
   ALTER TABLE SendListScanItem ADD CONSTRAINT chkSendListScanItem$SerialNo
      CHECK (dbo.bit$IsEmptyString(SerialNo) = 0 AND dbo.bit$LegalCharacters(SerialNo, 'ALPHANUMERIC', '.-_$[]%+' ) = 1 )
GO

IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.CHECK_CONSTRAINTS WHERE CONSTRAINT_NAME = 'chkSendListScanItem$CaseName')
   ALTER TABLE SendListScanItem ADD CONSTRAINT chkSendListScanItem$CaseName
      CHECK (dbo.bit$LegalCharacters(CaseName, 'ALPHANUMERIC', '.-_$[]%+' ) = 1 )
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS WHERE CONSTRAINT_NAME = 'fkSendListScanItem$SendListScan') BEGIN
ALTER TABLE dbo.SendListScanItem
   ADD CONSTRAINT fkSendListScanItem$SendListScan
      FOREIGN KEY (ScanId) REFERENCES dbo.SendListScan
         ON DELETE CASCADE
END
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'ReceiveList') BEGIN
CREATE TABLE dbo.ReceiveList
(
-- Attributes
   ListId       int             NOT NULL  CONSTRAINT pkReceiveList PRIMARY KEY CLUSTERED  IDENTITY(1,1),
   ListName     nchar(10)       NOT NULL  CONSTRAINT akReceiveList$akListName UNIQUE NONCLUSTERED,
   CreateDate   datetime        NOT NULL,
   Status       int             NOT NULL  CONSTRAINT defReceiveList$Status DEFAULT 4, -- power(4,x)
   Notes        nvarchar(1000)  NOT NULL  CONSTRAINT defReceiveList$Notes DEFAULT '', 
-- Relationships
   AccountId    int             NULL,
   CompositeId  int             NULL,
-- Concurrency
   RowVersion   rowversion      NOT NULL
)
END
GO

-- List name format: RE-0000000
IF NOT EXISTS(SELECT * FROM INFORMATION_SCHEMA.CHECK_CONSTRAINTS WHERE CONSTRAINT_NAME = 'chkReceiveList$ListName')
   ALTER TABLE ReceiveList ADD CONSTRAINT chkReceiveList$ListName
      CHECK (LEFT(ListName,3) = 'RE-' AND dbo.bit$LegalCharacters(SUBSTRING(ListName,4,7), 'NUMERIC', NULL ) = 1)
GO

-- Valid status values
IF NOT EXISTS(SELECT * FROM INFORMATION_SCHEMA.CHECK_CONSTRAINTS WHERE CONSTRAINT_NAME = 'chkReceiveList$Status')
   ALTER TABLE ReceiveList ADD CONSTRAINT chkReceiveList$Status CHECK (Status IN (4, 16, 64, 256, 1024)) -- power(4,x)
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS WHERE CONSTRAINT_NAME = 'fkReceiveList$Account') BEGIN
ALTER TABLE dbo.ReceiveList
   ADD CONSTRAINT fkReceiveList$Account
      FOREIGN KEY (AccountId) REFERENCES dbo.Account
END
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS WHERE CONSTRAINT_NAME = 'fkReceiveList$Composite') BEGIN
ALTER TABLE dbo.ReceiveList
   ADD CONSTRAINT fkReceiveList$Composite
      FOREIGN KEY (CompositeId) REFERENCES dbo.ReceiveList
         -- Cannot cascasde delete due to possible circular implications
END
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'ReceiveListItem') BEGIN
CREATE TABLE dbo.ReceiveListItem
(
-- Attributes
   ItemId      int             NOT NULL  CONSTRAINT pkReceiveListItem PRIMARY KEY CLUSTERED  IDENTITY(1,1),
   Status      int             NOT NULL  CONSTRAINT defReceiveListItem$Status DEFAULT 4, -- power(4,x)
   Notes       nvarchar(1000)  NOT NULL  CONSTRAINT defReceiveListItem$Notes DEFAULT '', 
-- Relationships
   ListId      int             NOT NULL,
   MediumId    int             NOT NULL,
-- Concurrency
   RowVersion  rowversion      NOT NULL
-- Composite Constraints
   CONSTRAINT akReceiveListItem$ListMedium UNIQUE NONCLUSTERED (ListId,MediumId)
)
END
GO

-- Valid status values
IF NOT EXISTS(SELECT * FROM INFORMATION_SCHEMA.CHECK_CONSTRAINTS WHERE CONSTRAINT_NAME = 'chkReceiveListItem$Status')
   ALTER TABLE ReceiveListItem ADD CONSTRAINT chkReceiveListItem$Status CHECK (Status IN (1, 4, 16, 256, 1024)) -- power(4,x) // 64 is skipped to keep consistent with list status (no partially verified)
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS WHERE CONSTRAINT_NAME = 'fkReceiveListItem$ReceiveList') BEGIN
ALTER TABLE dbo.ReceiveListItem
   ADD CONSTRAINT fkReceiveListItem$ReceiveList
      FOREIGN KEY (ListId) REFERENCES dbo.ReceiveList
         ON DELETE CASCADE
END
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS WHERE CONSTRAINT_NAME = 'fkReceiveListItem$Medium') BEGIN
ALTER TABLE dbo.ReceiveListItem
   ADD CONSTRAINT fkReceiveListItem$Medium
      FOREIGN KEY (MediumId) REFERENCES dbo.Medium
         ON DELETE CASCADE
END
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'ReceiveListScan') BEGIN
CREATE TABLE dbo.ReceiveListScan
(
-- Attributes
   ScanId        int            NOT NULL  CONSTRAINT pkReceiveListScan PRIMARY KEY CLUSTERED  IDENTITY(1,1),
   ScanName      nvarchar(256)  NOT NULL  CONSTRAINT akReceiveListScan$Name UNIQUE NONCLUSTERED,
   CreateDate    datetime       NOT NULL  CONSTRAINT defReceiveListScan$Date DEFAULT cast(convert(nchar(19),getdate(),120) as datetime),
   Compared      datetime       NULL,
-- Relationships
   ListId        int            NULL
)
END
GO

IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.CHECK_CONSTRAINTS WHERE CONSTRAINT_NAME = 'chkReceiveListScan$Name')
   ALTER TABLE ReceiveListScan ADD CONSTRAINT chkReceiveListScan$Name
      CHECK (dbo.bit$IsEmptyString(ScanName) = 0 AND dbo.bit$IllegalCharacters(ScanName, '_%' ) = 0 )
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS WHERE CONSTRAINT_NAME = 'fkReceiveListScan$ReceiveList') BEGIN
ALTER TABLE dbo.ReceiveListScan
   ADD CONSTRAINT fkReceiveListScan$ReceiveList
      FOREIGN KEY (ListId) REFERENCES dbo.ReceiveList
         ON DELETE CASCADE
END
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'ReceiveListScanItem') BEGIN
CREATE TABLE dbo.ReceiveListScanItem
(
-- Attributes
   ItemId       int           NOT NULL  CONSTRAINT pkReceiveListScanItem PRIMARY KEY CLUSTERED  IDENTITY(1,1),
   SerialNo     nvarchar(32)  NOT NULL,
   Ignored      bit           NOT NULL  CONSTRAINT defReceiveListScanItem$Ignored DEFAULT 0,
-- Relationships
   ScanId       int           NOT NULL,
-- Composite Constraints
   CONSTRAINT akReceiveListScanItem$SerialNo UNIQUE NONCLUSTERED (ScanId,SerialNo)
)
END
GO

IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.CHECK_CONSTRAINTS WHERE CONSTRAINT_NAME = 'chkReceiveListScanItem$SerialNo')
   ALTER TABLE ReceiveListScanItem ADD CONSTRAINT chkReceiveListScanItem$SerialNo
      CHECK (dbo.bit$IsEmptyString(SerialNo) = 0 AND dbo.bit$LegalCharacters(SerialNo, 'ALPHANUMERIC', '.-_$[]%+' ) = 1 )
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS WHERE CONSTRAINT_NAME = 'fkReceiveListScanItem$ReceiveListScan') BEGIN
ALTER TABLE dbo.ReceiveListScanItem
   ADD CONSTRAINT fkReceiveListScanItem$ReceiveListScan
      FOREIGN KEY (ScanId) REFERENCES dbo.ReceiveListScan
         ON DELETE CASCADE
END
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'DisasterCodeList') BEGIN
CREATE TABLE dbo.DisasterCodeList
(
-- Attributes
   ListId       int             NOT NULL  CONSTRAINT pkDisasterCodeList PRIMARY KEY CLUSTERED IDENTITY(1,1),
   ListName     nchar(10)       NOT NULL  CONSTRAINT akDisasterCodeList$akListName UNIQUE NONCLUSTERED,
   CreateDate   datetime        NOT NULL,
   Status       int             NOT NULL  CONSTRAINT defDisasterCodeList$Status DEFAULT 4, -- power(4,x)
   Notes        nvarchar(1000)  NOT NULL  CONSTRAINT defDisasterCodeList$Notes DEFAULT '', 
-- Relationships
   AccountId    int             NULL,
   CompositeId  int             NULL,
-- Concurrency
   RowVersion   rowversion      NOT NULL
)
END
GO

-- List name format: DC-0000000
IF NOT EXISTS(SELECT * FROM INFORMATION_SCHEMA.CHECK_CONSTRAINTS WHERE CONSTRAINT_NAME = 'chkDisasterCodeList$ListName')
   ALTER TABLE DisasterCodeList ADD CONSTRAINT chkDisasterCodeList$ListName
      CHECK (LEFT(ListName,3) = 'DC-' AND dbo.bit$LegalCharacters(SUBSTRING(ListName,4,7), 'NUMERIC', NULL ) = 1)
GO

-- Valid status values
IF NOT EXISTS(SELECT * FROM INFORMATION_SCHEMA.CHECK_CONSTRAINTS WHERE CONSTRAINT_NAME = 'chkDisasterCodeList$Status')
   ALTER TABLE DisasterCodeList ADD CONSTRAINT chkDisasterCodeList$Status CHECK (Status IN (4, 16, 64)) -- power(4,x)
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS WHERE CONSTRAINT_NAME = 'fkDisasterCodeList$Account') BEGIN
ALTER TABLE dbo.DisasterCodeList
   ADD CONSTRAINT fkDisasterCodeList$Account
      FOREIGN KEY (AccountId) REFERENCES dbo.Account
END
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS WHERE CONSTRAINT_NAME = 'fkDisasterCodeList$Composite') BEGIN
ALTER TABLE dbo.DisasterCodeList
   ADD CONSTRAINT fkDisasterCodeList$Composite
      FOREIGN KEY (CompositeId) REFERENCES dbo.DisasterCodeList
         -- Cannot cascasde delete due to possible circular implications
END
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'DisasterCodeListItem') BEGIN
CREATE TABLE dbo.DisasterCodeListItem
(
-- Attributes
   ItemId      int             NOT NULL  CONSTRAINT pkDisasterCodeListItem PRIMARY KEY CLUSTERED  IDENTITY(1,1),
   Status      int             NOT NULL  CONSTRAINT defDisasterCodeListItem$Status DEFAULT 4, -- power(4,x)
   Code        nvarchar(32)    NOT NULL,
   Notes       nvarchar(1000)  NOT NULL  CONSTRAINT defDisasterCodeListItem$Notes DEFAULT '', 
-- Relationships
   ListId      int             NOT NULL,
-- Concurrency
   RowVersion  rowversion      NOT NULL
)
END
GO

-- Valid code values
IF NOT EXISTS(SELECT * FROM INFORMATION_SCHEMA.CHECK_CONSTRAINTS WHERE CONSTRAINT_NAME = 'chkDisasterCodeListItem$Code')
   ALTER TABLE DisasterCodeListItem ADD CONSTRAINT chkDisasterCodeListItem$Code
      CHECK (dbo.bit$IsEmptyString(Code) = 0 AND dbo.bit$LegalCharacters(Code, 'ALPHANUMERICWHITE', NULL ) = 1)
GO

-- Valid status values
IF NOT EXISTS(SELECT * FROM INFORMATION_SCHEMA.CHECK_CONSTRAINTS WHERE CONSTRAINT_NAME = 'chkDisasterCodeListItem$Status')
   ALTER TABLE DisasterCodeListItem ADD CONSTRAINT chkDisasterCodeListItem$Status CHECK (Status IN (1, 4, 16, 64)) -- power(4,x)
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS WHERE CONSTRAINT_NAME = 'fkDisasterCodeListItem$DisasterCodeList') BEGIN
ALTER TABLE dbo.DisasterCodeListItem
   ADD CONSTRAINT fkDisasterCodeListItem$DisasterCodeList
      FOREIGN KEY (ListId) REFERENCES dbo.DisasterCodeList
         ON DELETE CASCADE
END
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'DisasterCodeListItemMedium') BEGIN
CREATE TABLE dbo.DisasterCodeListItemMedium
(
-- Attributes
   ItemId    int  NOT NULL  CONSTRAINT pkDisasterCodeListItemMedium PRIMARY KEY CLUSTERED,
-- Relationships
   MediumId  int  NOT NULL
)
END
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS WHERE CONSTRAINT_NAME = 'fkDisasterCodeListItemMedium$Item') BEGIN
ALTER TABLE dbo.DisasterCodeListItemMedium
   ADD CONSTRAINT fkDisasterCodeListItemMedium$Item
      FOREIGN KEY (ItemId) REFERENCES dbo.DisasterCodeListItem
         ON DELETE CASCADE
END
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS WHERE CONSTRAINT_NAME = 'fkDisasterCodeListItemMedium$Medium') BEGIN
ALTER TABLE dbo.DisasterCodeListItemMedium
   ADD CONSTRAINT fkDisasterCodeListItemMedium$Medium
      FOREIGN KEY (MediumId) REFERENCES dbo.Medium
         ON DELETE CASCADE
END
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'DisasterCodeListItemCase') BEGIN
CREATE TABLE dbo.DisasterCodeListItemCase
(
-- Attributes
   ItemId  int  NOT NULL  CONSTRAINT pkDisasterCodeListItemCase PRIMARY KEY CLUSTERED,
-- Relationships
   CaseId  int  NOT NULL
)
END
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS WHERE CONSTRAINT_NAME = 'fkDisasterCodeListItemCase$Item') BEGIN
ALTER TABLE dbo.DisasterCodeListItemCase
   ADD CONSTRAINT fkDisasterCodeListItemCase$Item
      FOREIGN KEY (ItemId) REFERENCES dbo.DisasterCodeListItem
         ON DELETE CASCADE
END
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS WHERE CONSTRAINT_NAME = 'fkDisasterCodeListItemCase$SealedCase') BEGIN
ALTER TABLE dbo.DisasterCodeListItemCase
   ADD CONSTRAINT fkDisasterCodeListItemCase$SealedCase
      FOREIGN KEY (CaseId) REFERENCES dbo.SealedCase
         ON DELETE CASCADE
END
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'VaultInventory') BEGIN
CREATE TABLE dbo.VaultInventory
(
-- Attributes
   InventoryId   int         NOT NULL  CONSTRAINT pkVaultInventory PRIMARY KEY CLUSTERED  IDENTITY(1,1),
   FileHash      binary(32)  NOT NULL,
   DownloadTime  datetime    NOT NULL,
-- Relationships
   AccountId     int         NOT NULL
)
END
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS WHERE CONSTRAINT_NAME = 'fkVaultInventory$Account') BEGIN
ALTER TABLE dbo.VaultInventory
   ADD CONSTRAINT fkVaultInventory$Account
      FOREIGN KEY (AccountId) REFERENCES dbo.Account
         ON DELETE CASCADE
END
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'VaultInventoryItem') BEGIN
CREATE TABLE dbo.VaultInventoryItem
(
-- Attributes
   ItemId       int           NOT NULL  CONSTRAINT pkVaultInventoryItem PRIMARY KEY CLUSTERED  IDENTITY(1,1),
   SerialNo     nvarchar(32)  NOT NULL,
   HotStatus    bit           NOT NULL,
-- Relationships
   TypeId       int           NOT NULL,
   InventoryId  int           NOT NULL
)
END
GO

IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.CHECK_CONSTRAINTS WHERE CONSTRAINT_NAME = 'chkVaultInventoryItem$SerialNo')
   ALTER TABLE VaultInventoryItem ADD CONSTRAINT chkVaultInventoryItem$SerialNo
      CHECK (dbo.bit$IsEmptyString(SerialNo) = 0 AND dbo.bit$LegalCharacters(SerialNo, 'ALPHANUMERIC', '.-_$[]%+' ) = 1 )
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS WHERE CONSTRAINT_NAME = 'fkVaultInventoryItem$Inventory') BEGIN
ALTER TABLE dbo.VaultInventoryItem
   ADD CONSTRAINT fkVaultInventoryItem$Inventory
      FOREIGN KEY (InventoryId) REFERENCES dbo.VaultInventory
         ON DELETE CASCADE
END
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS WHERE CONSTRAINT_NAME = 'fkVaultInventoryItem$MediumType') BEGIN
ALTER TABLE dbo.VaultInventoryItem
   ADD CONSTRAINT fkVaultInventoryItem$MediumType
      FOREIGN KEY (TypeId) REFERENCES dbo.MediumType
         ON DELETE CASCADE
END
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'VaultDiscrepancy') BEGIN
CREATE TABLE dbo.VaultDiscrepancy
(
-- Attributes
   ItemId        int       NOT NULL  CONSTRAINT pkVaultDiscrepancy PRIMARY KEY CLUSTERED  IDENTITY(1,1),
   RecordedDate  datetime  NOT NULL,
)
END
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'VaultDiscrepancyResidency') BEGIN
CREATE TABLE dbo.VaultDiscrepancyResidency
(
-- Relationships
   ItemId    int  NOT NULL  CONSTRAINT pkVaultDiscrepancyResidency PRIMARY KEY CLUSTERED,
   MediumId  int  NOT NULL  CONSTRAINT akVaultDiscrepancyResidency$Medium UNIQUE NONCLUSTERED,
   SerialNo  nvarchar(32)  NOT NULL
)
END
GO

IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.CHECK_CONSTRAINTS WHERE CONSTRAINT_NAME = 'chkVaultDiscrepancyResidency$SerialNo')
   ALTER TABLE VaultDiscrepancyResidency ADD CONSTRAINT chkVaultDiscrepancyResidency$SerialNo
      CHECK (dbo.bit$IsEmptyString(SerialNo) = 0 AND dbo.bit$LegalCharacters(SerialNo, 'ALPHANUMERIC', '.-_$[]%+' ) = 1 )
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS WHERE CONSTRAINT_NAME = 'fkVaultDiscrepancyResidency$Discrepancy') BEGIN
ALTER TABLE dbo.VaultDiscrepancyResidency
   ADD CONSTRAINT fkVaultDiscrepancyResidency$Discrepancy
      FOREIGN KEY (ItemId) REFERENCES dbo.VaultDiscrepancy
         ON DELETE CASCADE
END
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS WHERE CONSTRAINT_NAME = 'fkVaultDiscrepancyResidency$Medium') BEGIN
ALTER TABLE dbo.VaultDiscrepancyResidency
   ADD CONSTRAINT fkVaultDiscrepancyResidency$Medium
      FOREIGN KEY (MediumId) REFERENCES dbo.Medium
         ON DELETE CASCADE
END
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'VaultDiscrepancyMediumType') BEGIN
CREATE TABLE dbo.VaultDiscrepancyMediumType
(
-- Relationships
   ItemId     int           NOT NULL  CONSTRAINT pkVaultDiscrepancyMediumType PRIMARY KEY CLUSTERED,
   MediumId   int           NOT NULL  CONSTRAINT akVaultDiscrepancyMediumType$Medium UNIQUE NONCLUSTERED,
   SerialNo   nvarchar(32)  NOT NULL,
   VaultType  int           NOT NULL
)
END
GO

IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.CHECK_CONSTRAINTS WHERE CONSTRAINT_NAME = 'chkVaultDiscrepancyMediumType$SerialNo')
   ALTER TABLE VaultDiscrepancyMediumType ADD CONSTRAINT chkVaultDiscrepancyMediumType$SerialNo
      CHECK (dbo.bit$IsEmptyString(SerialNo) = 0 AND dbo.bit$LegalCharacters(SerialNo, 'ALPHANUMERIC', '.-_$[]%+' ) = 1 )
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS WHERE CONSTRAINT_NAME = 'fkVaultDiscrepancyMediumType$Discrepancy') BEGIN
ALTER TABLE dbo.VaultDiscrepancyMediumType
   ADD CONSTRAINT fkVaultDiscrepancyMediumType$Discrepancy
      FOREIGN KEY (ItemId) REFERENCES dbo.VaultDiscrepancy
         ON DELETE CASCADE
END
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS WHERE CONSTRAINT_NAME = 'fkVaultDiscrepancyMediumType$Medium') BEGIN
ALTER TABLE dbo.VaultDiscrepancyMediumType
   ADD CONSTRAINT fkVaultDiscrepancyMediumType$Medium
      FOREIGN KEY (MediumId) REFERENCES dbo.Medium
         ON DELETE CASCADE
END
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS WHERE CONSTRAINT_NAME = 'fkVaultDiscrepancyMediumType$MediumType') BEGIN
ALTER TABLE dbo.VaultDiscrepancyMediumType
   ADD CONSTRAINT fkVaultDiscrepancyMediumType$MediumType
      FOREIGN KEY (VaultType) REFERENCES dbo.MediumType
         ON DELETE CASCADE
END
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'VaultDiscrepancyCaseType') BEGIN
CREATE TABLE dbo.VaultDiscrepancyCaseType
(
-- Relationships
   ItemId     int           NOT NULL  CONSTRAINT pkVaultDiscrepancyCaseType PRIMARY KEY CLUSTERED,
   CaseId     int           NOT NULL  CONSTRAINT akVaultDiscrepancyCaseType$Case UNIQUE NONCLUSTERED,
   SerialNo   nvarchar(32)  NOT NULL,
   VaultType  int           NOT NULL
)
END
GO

IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.CHECK_CONSTRAINTS WHERE CONSTRAINT_NAME = 'chkVaultDiscrepancyCaseType$SerialNo')
   ALTER TABLE VaultDiscrepancyCaseType ADD CONSTRAINT chkVaultDiscrepancyCaseType$SerialNo
      CHECK (dbo.bit$IsEmptyString(SerialNo) = 0 AND dbo.bit$LegalCharacters(SerialNo, 'ALPHANUMERIC', '.-_$[]%+' ) = 1 )
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS WHERE CONSTRAINT_NAME = 'fkVaultDiscrepancyCaseType$Discrepancy') BEGIN
ALTER TABLE dbo.VaultDiscrepancyCaseType
   ADD CONSTRAINT fkVaultDiscrepancyCaseType$Discrepancy
      FOREIGN KEY (ItemId) REFERENCES dbo.VaultDiscrepancy
         ON DELETE CASCADE
END
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS WHERE CONSTRAINT_NAME = 'fkVaultDiscrepancyCaseType$SealedCase') BEGIN
ALTER TABLE dbo.VaultDiscrepancyCaseType
   ADD CONSTRAINT fkVaultDiscrepancyCaseType$SealedCase
      FOREIGN KEY (CaseId) REFERENCES dbo.SealedCase
         ON DELETE CASCADE
END
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS WHERE CONSTRAINT_NAME = 'fkVaultDiscrepancyCaseType$CaseType') BEGIN
ALTER TABLE dbo.VaultDiscrepancyCaseType
   ADD CONSTRAINT fkVaultDiscrepancyCaseType$CaseType
      FOREIGN KEY (VaultType) REFERENCES dbo.MediumType
         ON DELETE CASCADE
END
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'VaultDiscrepancyUnknownCase') BEGIN
CREATE TABLE dbo.VaultDiscrepancyUnknownCase
(
-- Attributes
   SerialNo  nvarchar(32)  NOT NULL  CONSTRAINT akVaultDiscrepancyUnknownCase$SerialNo UNIQUE NONCLUSTERED,
-- Relationships
   ItemId    int           NOT NULL  CONSTRAINT pkVaultDiscrepancyUnknownCase PRIMARY KEY CLUSTERED
)
END
GO

IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.CHECK_CONSTRAINTS WHERE CONSTRAINT_NAME = 'chkVaultDiscrepancyUnknownCase$SerialNo')
   ALTER TABLE VaultDiscrepancyUnknownCase ADD CONSTRAINT chkVaultDiscrepancyUnknownCase$SerialNo
      CHECK (dbo.bit$IsEmptyString(SerialNo) = 0 AND dbo.bit$LegalCharacters(SerialNo, 'ALPHANUMERIC', '.-_$[]%+' ) = 1 )
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS WHERE CONSTRAINT_NAME = 'fkVaultDiscrepancyUnknownCase$Discrepancy') BEGIN
ALTER TABLE dbo.VaultDiscrepancyUnknownCase
   ADD CONSTRAINT fkVaultDiscrepancyUnknownCase$Discrepancy
      FOREIGN KEY (ItemId) REFERENCES dbo.VaultDiscrepancy
         ON DELETE CASCADE
END
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'VaultDiscrepancyAccount') BEGIN
CREATE TABLE dbo.VaultDiscrepancyAccount
(
-- Relationships
   ItemId        int           NOT NULL  CONSTRAINT pkVaultDiscrepancyAccount PRIMARY KEY CLUSTERED,
   MediumId      int           NOT NULL  CONSTRAINT akVaultDiscrepancyAccount$Medium UNIQUE NONCLUSTERED,
   SerialNo      nvarchar(32)  NOT NULL,
   VaultAccount  int           NOT NULL
)
END
GO

-- Adding this instruction because the chkVaultDiscrepancyAccount$SerialNo constraint
-- was present but incorrect in the original database script
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.CHECK_CONSTRAINTS WHERE CONSTRAINT_NAME = 'chkVaultDiscrepancyAccount$SerialNo')
   ALTER TABLE VaultDiscrepancyAccount DROP CONSTRAINT chkVaultDiscrepancyAccount$SerialNo
GO

IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.CHECK_CONSTRAINTS WHERE CONSTRAINT_NAME = 'chkVaultDiscrepancyAccount$SerialNo')
   ALTER TABLE VaultDiscrepancyAccount ADD CONSTRAINT chkVaultDiscrepancyAccount$SerialNo
      CHECK (dbo.bit$IsEmptyString(SerialNo) = 0 AND dbo.bit$LegalCharacters(SerialNo, 'ALPHANUMERIC', '.-_$[]%+' ) = 1)
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS WHERE CONSTRAINT_NAME = 'fkVaultDiscrepancyAccount$Discrepancy') BEGIN
ALTER TABLE dbo.VaultDiscrepancyAccount
   ADD CONSTRAINT fkVaultDiscrepancyAccount$Discrepancy
      FOREIGN KEY (ItemId) REFERENCES dbo.VaultDiscrepancy
         ON DELETE CASCADE
END
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS WHERE CONSTRAINT_NAME = 'fkVaultDiscrepancyAccount$Medium') BEGIN
ALTER TABLE dbo.VaultDiscrepancyAccount
   ADD CONSTRAINT fkVaultDiscrepancyAccount$Medium
      FOREIGN KEY (MediumId) REFERENCES dbo.Medium
         ON DELETE CASCADE
END
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS WHERE CONSTRAINT_NAME = 'fkVaultDiscrepancyAccount$Account') BEGIN
ALTER TABLE dbo.VaultDiscrepancyAccount
   ADD CONSTRAINT fkVaultDiscrepancyAccount$Account
      FOREIGN KEY (VaultAccount) REFERENCES dbo.Account
         ON DELETE CASCADE
END
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'BarCodePattern') BEGIN
CREATE TABLE dbo.BarCodePattern
(
-- Attributes
   PatId       int             NOT NULL  CONSTRAINT pkBarCodePattern          PRIMARY KEY NONCLUSTERED  IDENTITY(1,1),
   Pattern     nvarchar(256)   NOT NULL  CONSTRAINT akBarCodePattern$Pattern  UNIQUE NONCLUSTERED,
   Position    int             NOT NULL  CONSTRAINT akBarCodePattern$Position UNIQUE CLUSTERED,
   Notes       nvarchar(1000)  NOT NULL  CONSTRAINT defBarCodePattern$Notes   DEFAULT '',
-- Relationships
   TypeId      int            NOT NULL,
   AccountId   int            NOT NULL
)
END
GO

-- Regular expression characters only
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.CHECK_CONSTRAINTS WHERE CONSTRAINT_NAME = 'chkBarCodePattern$Pattern')
   ALTER TABLE BarCodePattern ADD CONSTRAINT chkBarCodePattern$Pattern
      CHECK (dbo.bit$IsEmptyString(Pattern) = 0 AND dbo.bit$LegalCharacters(Pattern, 'ALPHANUMERIC', '*.[-]{,}' ) = 1)
GO

-- Position must be greater than zero
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.CHECK_CONSTRAINTS WHERE CONSTRAINT_NAME = 'chkBarCodePattern$Position')
   ALTER TABLE BarCodePattern ADD CONSTRAINT chkBarCodePattern$Position CHECK (Position > 0)
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS WHERE CONSTRAINT_NAME = 'fkBarCodePattern$Account') BEGIN
ALTER TABLE dbo.BarCodePattern
   ADD CONSTRAINT fkBarCodePattern$Account
      FOREIGN KEY (AccountId) REFERENCES dbo.Account
         ON DELETE CASCADE
END
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS WHERE CONSTRAINT_NAME = 'fkBarCodePattern$MediumType') BEGIN
ALTER TABLE dbo.BarCodePattern
   ADD CONSTRAINT fkBarCodePattern$MediumType
      FOREIGN KEY (TypeId) REFERENCES dbo.MediumType
         ON DELETE CASCADE
END
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'BarCodePatternCase') BEGIN
CREATE TABLE dbo.BarCodePatternCase
(
-- Attributes
   PatId       int             NOT NULL  CONSTRAINT pkBarCodePatternCase          PRIMARY KEY NONCLUSTERED  IDENTITY(1,1),
   Pattern     nvarchar(256)   NOT NULL  CONSTRAINT akBarCodePatternCase$Pattern  UNIQUE NONCLUSTERED,
   Position    int             NOT NULL  CONSTRAINT akBarCodePatternCase$Position UNIQUE CLUSTERED,
   Notes       nvarchar(1000)  NOT NULL  CONSTRAINT defBarCodePatternCase$Notes   DEFAULT '',
-- Relationships
   TypeId      int             NOT NULL
)
END
GO

-- Regular expression characters only
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.CHECK_CONSTRAINTS WHERE CONSTRAINT_NAME = 'chkBarCodePatternCase$Pattern')
   ALTER TABLE BarCodePattern ADD CONSTRAINT chkBarCodePatternCase$Pattern
      CHECK (dbo.bit$IsEmptyString(Pattern) = 0 AND dbo.bit$LegalCharacters(Pattern, 'ALPHANUMERIC', '*.[-]{,}' ) = 1)
GO

-- Position must be greater than zero
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.CHECK_CONSTRAINTS WHERE CONSTRAINT_NAME = 'chkBarCodePatternCase$Position')
   ALTER TABLE BarCodePatternCase ADD CONSTRAINT chkBarCodePatternCase$Position CHECK (Position > 0)
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS WHERE CONSTRAINT_NAME = 'fkBarCodePatternCase$CaseType') BEGIN
ALTER TABLE dbo.BarCodePatternCase
   ADD CONSTRAINT fkBarCodePatternCase$CaseType
      FOREIGN KEY (TypeId) REFERENCES dbo.MediumType
         ON DELETE CASCADE
END
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'ExternalSiteLocation') BEGIN
CREATE TABLE dbo.ExternalSiteLocation
(
-- Attributes
   SiteId     int            NOT NULL  CONSTRAINT pkExternalSiteLocation          PRIMARY KEY NONCLUSTERED  IDENTITY(1,1),
   SiteName   nvarchar(256)  NOT NULL  CONSTRAINT akExternalSiteLocation$SiteName UNIQUE CLUSTERED,
   Location   bit            NOT NULL,
-- Concurrency
   RowVersion  rowversion    NOT NULL
)
END
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'IgnoredBarCodePattern') BEGIN
CREATE TABLE dbo.IgnoredBarCodePattern
(
-- Attributes
   Id          int             NOT NULL  CONSTRAINT pkIgnoredBarCodePattern        PRIMARY KEY NONCLUSTERED  IDENTITY(1,1),
   Pattern     nvarchar(256)   NOT NULL  CONSTRAINT akIgnoredBarCodePattern$String UNIQUE NONCLUSTERED,
   Systems     binary(8)       NOT NULL, 
   Notes       nvarchar(1000)  NOT NULL  CONSTRAINT defIgnoredBarCodePattern$Notes DEFAULT '',
-- Concurrency
   RowVersion  rowversion      NOT NULL
)
END
GO

-- Regular expression characters only
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.CHECK_CONSTRAINTS WHERE CONSTRAINT_NAME = 'chkIgnoredBarCodePattern$Pattern')
   ALTER TABLE IgnoredBarCodePattern ADD CONSTRAINT chkIgnoredBarCodePattern$Pattern
      CHECK (dbo.bit$IsEmptyString(Pattern) = 0 AND dbo.bit$LegalCharacters(Pattern, 'ALPHANUMERIC', '*.[-]{,}' ) = 1)
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'DatabaseVersion') BEGIN
CREATE TABLE dbo.DatabaseVersion
(
-- Attributes
   Major        int       NOT NULL,
   Minor        int       NOT NULL,
   Revision     int       NOT NULL,
   InstallDate  datetime  NOT NULL  CONSTRAINT defDatabaseVersion$InstallDate DEFAULT getdate()
-- Composite Constraints
   CONSTRAINT akDatabaseVersion$Version UNIQUE NONCLUSTERED (Major,Minor,Revision)
)
END
GO

IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.CHECK_CONSTRAINTS WHERE CONSTRAINT_NAME = 'chkDatabaseVersion$Major')
   ALTER TABLE DatabaseVersion ADD CONSTRAINT chkDatabaseVersion$Major CHECK (Major > 0)
GO

IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.CHECK_CONSTRAINTS WHERE CONSTRAINT_NAME = 'chkDatabaseVersion$Minor')
   ALTER TABLE DatabaseVersion ADD CONSTRAINT chkDatabaseVersion$Minor CHECK (Minor >= 0)
GO

IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.CHECK_CONSTRAINTS WHERE CONSTRAINT_NAME = 'chkDatabaseVersion$Major')
   ALTER TABLE DatabaseVersion ADD CONSTRAINT chkDatabaseVersion$Revision CHECK (Revision >= 0)
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'ProductLicense') BEGIN
CREATE TABLE dbo.ProductLicense
(
-- Attributes
   TypeId  int            NOT NULL  CONSTRAINT pkProductLicense PRIMARY KEY CLUSTERED,
   Value   nvarchar(256)  NOT NULL,
   Issued  datetime       NOT NULL,
   Rayval  nvarchar(64)   NOT NULL
)
END
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'ListPurgeDetail') BEGIN
CREATE TABLE dbo.ListPurgeDetail
(
-- Attributes
   Type     int  NOT NULL  CONSTRAINT pkListPurgeDetail          PRIMARY KEY CLUSTERED,
   Days     int  NOT NULL,
   Archive  bit  NOT NULL  CONSTRAINT defListPurgeDetail$Archive DEFAULT 0,
-- Concurrency
   RowVersion  rowversion  NOT NULL
)
END
GO

IF NOT EXISTS(SELECT 1 FROM ListPurgeDetail WHERE Type = 1)
   INSERT dbo.ListPurgeDetail (Type, Days, Archive) VALUES (1, 90, 0)

IF NOT EXISTS(SELECT 1 FROM ListPurgeDetail WHERE Type = 2)
   INSERT dbo.ListPurgeDetail (Type, Days, Archive) VALUES (2, 90, 0)

IF NOT EXISTS(SELECT 1 FROM ListPurgeDetail WHERE Type = 4)
   INSERT dbo.ListPurgeDetail (Type, Days, Archive) VALUES (4, 90, 0)
GO

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
--
-- Audit-related tables
--
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'XCategoryExpiration') BEGIN
CREATE TABLE dbo.XCategoryExpiration
(
-- Attributes
   Category    int         NOT NULL  CONSTRAINT pkXCategoryExpiration          PRIMARY KEY CLUSTERED,
   Days        int         NOT NULL,
   Archive     bit         NOT NULL  CONSTRAINT defXCategoryExpiration$Archive DEFAULT 0,
-- Concurrency
   RowVersion  rowversion  NOT NULL
)
END
GO

IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.CHECK_CONSTRAINTS WHERE CONSTRAINT_NAME = 'chkXCategoryExpiration$Category')
   ALTER TABLE XCategoryExpiration ADD CONSTRAINT chkXCategoryExpiration$Category CHECK (Category IN (1,2,4,8,16,32,64,128,256,512,1024,2048,4096,8192))
GO

IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.CHECK_CONSTRAINTS WHERE CONSTRAINT_NAME = 'chkXCategoryExpiration$Days')
   ALTER TABLE XCategoryExpiration ADD CONSTRAINT chkXCategoryExpiration$Days CHECK (Days >= 0)
GO

IF NOT EXISTS(SELECT 1 FROM XCategoryExpiration WHERE Category = 1)
   INSERT dbo.XCategoryExpiration (Category, Days, Archive) VALUES (1, 30, 0)

IF NOT EXISTS(SELECT 1 FROM XCategoryExpiration WHERE Category = 2)
   INSERT dbo.XCategoryExpiration (Category, Days, Archive) VALUES (2, 30, 0)

IF NOT EXISTS(SELECT 1 FROM XCategoryExpiration WHERE Category = 4)
   INSERT dbo.XCategoryExpiration (Category, Days, Archive) VALUES (4, 30, 0)

IF NOT EXISTS(SELECT 1 FROM XCategoryExpiration WHERE Category = 8)
   INSERT dbo.XCategoryExpiration (Category, Days, Archive) VALUES (8, 30, 0)

IF NOT EXISTS(SELECT 1 FROM XCategoryExpiration WHERE Category = 16)
   INSERT dbo.XCategoryExpiration (Category, Days, Archive) VALUES (16, 30, 0)

IF NOT EXISTS(SELECT 1 FROM XCategoryExpiration WHERE Category = 32)
   INSERT dbo.XCategoryExpiration (Category, Days, Archive) VALUES (32, 30, 0)

IF NOT EXISTS(SELECT 1 FROM XCategoryExpiration WHERE Category = 64)
   INSERT dbo.XCategoryExpiration (Category, Days, Archive) VALUES (64, 30, 0)

IF NOT EXISTS(SELECT 1 FROM XCategoryExpiration WHERE Category = 128)
   INSERT dbo.XCategoryExpiration (Category, Days, Archive) VALUES (128, 30, 0)

IF NOT EXISTS(SELECT 1 FROM XCategoryExpiration WHERE Category = 256)
   INSERT dbo.XCategoryExpiration (Category, Days, Archive) VALUES (256, 30, 0)

IF NOT EXISTS(SELECT 1 FROM XCategoryExpiration WHERE Category = 512)
   INSERT dbo.XCategoryExpiration (Category, Days, Archive) VALUES (512, 30, 0)

IF NOT EXISTS(SELECT 1 FROM XCategoryExpiration WHERE Category = 1024)
   INSERT dbo.XCategoryExpiration (Category, Days, Archive) VALUES (1024, 30, 0)

IF NOT EXISTS(SELECT 1 FROM XCategoryExpiration WHERE Category = 2048)
   INSERT dbo.XCategoryExpiration (Category, Days, Archive) VALUES (2048, 30, 0)

IF NOT EXISTS(SELECT 1 FROM XCategoryExpiration WHERE Category = 4096)
   INSERT dbo.XCategoryExpiration (Category, Days, Archive) VALUES (4096, 30, 0)

IF NOT EXISTS(SELECT 1 FROM XCategoryExpiration WHERE Category = 8192)
   INSERT dbo.XCategoryExpiration (Category, Days, Archive) VALUES (8192, 30, 0)
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'XMedium') BEGIN
CREATE TABLE dbo.XMedium
(
-- Attributes
   ItemId   int             NOT NULL  CONSTRAINT pkXMedium         PRIMARY KEY CLUSTERED  IDENTITY(1,1),
   Date     datetime        NOT NULL  CONSTRAINT defXMedium$Date   DEFAULT GETDATE(),
   Object   nvarchar(32)    NOT NULL,
   Action   int             NOT NULL,
   Detail   nvarchar(3000)  NOT NULL  CONSTRAINT defXMedium$Detail DEFAULT '',
   Login    nvarchar(32)    NOT NULL  CONSTRAINT defXMedium$Login  DEFAULT 'SYSTEM'
)
END
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'XMediumMovement') BEGIN
CREATE TABLE dbo.XMediumMovement
(
-- Attributes
   ItemId     int           NOT NULL  CONSTRAINT pkXMediumMovement        PRIMARY KEY CLUSTERED  IDENTITY(1,1),
   Date       datetime      NOT NULL  CONSTRAINT defXMediumMovement$Date  DEFAULT GETDATE(),
   Object     nvarchar(32)  NOT NULL,
   Direction  bit           NOT NULL,
   Method     int           NOT NULL,
   Login      nvarchar(32)  NOT NULL  CONSTRAINT defXMediumMovement$Login DEFAULT 'SYSTEM'
)
END
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'XSealedCase') BEGIN
CREATE TABLE dbo.XSealedCase
(
-- Attributes
   ItemId   int             NOT NULL  CONSTRAINT pkXSealedCase         PRIMARY KEY CLUSTERED  IDENTITY(1,1),
   Date     datetime        NOT NULL  CONSTRAINT defXSealedCase$Date   DEFAULT GETDATE(),
   Object   nvarchar(32)    NOT NULL,
   Action   int             NOT NULL,
   Detail   nvarchar(3000)  NOT NULL  CONSTRAINT defXSealedCase$Detail DEFAULT '',
   Login    nvarchar(32)    NOT NULL  CONSTRAINT defXSealedCase$Login  DEFAULT 'SYSTEM'
)
END
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'XAccount') BEGIN
CREATE TABLE dbo.XAccount
(
-- Attributes
   ItemId   int             NOT NULL  CONSTRAINT pkXAccount         PRIMARY KEY CLUSTERED  IDENTITY(1,1),
   Date     datetime        NOT NULL  CONSTRAINT defXAccount$Date   DEFAULT GETDATE(),
   Object   nvarchar(32)    NOT NULL,
   Action   int             NOT NULL,
   Detail   nvarchar(3000)  NOT NULL  CONSTRAINT defXAccount$Detail DEFAULT '',
   Login    nvarchar(32)    NOT NULL  CONSTRAINT defXAccount$Login  DEFAULT 'SYSTEM'
)
END
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'XOperator') BEGIN
CREATE TABLE dbo.XOperator
(
-- Attributes
   ItemId   int             NOT NULL  CONSTRAINT pkXOperator         PRIMARY KEY CLUSTERED  IDENTITY(1,1),
   Date     datetime        NOT NULL  CONSTRAINT defXOperator$Date   DEFAULT GETDATE(),
   Object   nvarchar(32)    NOT NULL,
   Action   int             NOT NULL,
   Detail   nvarchar(3000)  NOT NULL  CONSTRAINT defXOperator$Detail DEFAULT '',
   Login    nvarchar(32)    NOT NULL  CONSTRAINT defXOperator$Login  DEFAULT 'SYSTEM'
)
END
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'XSendList') BEGIN
CREATE TABLE dbo.XSendList
(
-- Attributes
   ItemId   int             NOT NULL  CONSTRAINT pkXSendList         PRIMARY KEY CLUSTERED  IDENTITY(1,1),
   Date     datetime        NOT NULL  CONSTRAINT defXSendList$Date   DEFAULT GETDATE(),
   Object   nvarchar(32)    NOT NULL,
   Action   int             NOT NULL,
   Detail   nvarchar(3000)  NOT NULL  CONSTRAINT defXSendList$Detail DEFAULT '',
   Login    nvarchar(32)    NOT NULL  CONSTRAINT defXSendList$Login  DEFAULT 'SYSTEM'
)
END
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'XSendListItem') BEGIN
CREATE TABLE dbo.XSendListItem
(
-- Attributes
   ItemId   int             NOT NULL  CONSTRAINT pkXSendListItem         PRIMARY KEY CLUSTERED  IDENTITY(1,1),
   Date     datetime        NOT NULL  CONSTRAINT defXSendListItem$Date   DEFAULT GETDATE(),
   Object   nvarchar(32)    NOT NULL,
   Action   int             NOT NULL,
   Detail   nvarchar(3000)  NOT NULL  CONSTRAINT defXSendListItem$Detail DEFAULT '',
   Login    nvarchar(32)    NOT NULL  CONSTRAINT defXSendListItem$Login  DEFAULT 'SYSTEM'
)
END
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'XSendListCase') BEGIN
CREATE TABLE dbo.XSendListCase
(
-- Attributes
   ItemId   int             NOT NULL  CONSTRAINT pkXSendListCase         PRIMARY KEY CLUSTERED  IDENTITY(1,1),
   Date     datetime        NOT NULL  CONSTRAINT defXSendListCase$Date   DEFAULT GETDATE(),
   Object   nvarchar(32)    NOT NULL,
   Action   int             NOT NULL,
   Detail   nvarchar(3000)  NOT NULL  CONSTRAINT defXSendListCase$Detail DEFAULT '',
   Login    nvarchar(32)    NOT NULL  CONSTRAINT defXSendListCase$Login  DEFAULT 'SYSTEM'
)
END
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'XReceiveList') BEGIN
CREATE TABLE dbo.XReceiveList
(
-- Attributes
   ItemId   int             NOT NULL  CONSTRAINT pkXReceiveList         PRIMARY KEY CLUSTERED  IDENTITY(1,1),
   Date     datetime        NOT NULL  CONSTRAINT defXReceiveList$Date   DEFAULT GETDATE(),
   Object   nvarchar(32)    NOT NULL,
   Action   int             NOT NULL,
   Detail   nvarchar(3000)  NOT NULL  CONSTRAINT defXReceiveList$Detail DEFAULT '',
   Login    nvarchar(32)    NOT NULL  CONSTRAINT defXReceiveList$Login  DEFAULT 'SYSTEM'
)
END
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'XReceiveListItem') BEGIN
CREATE TABLE dbo.XReceiveListItem
(
-- Attributes
   ItemId   int             NOT NULL  CONSTRAINT pkXReceiveListItem         PRIMARY KEY CLUSTERED  IDENTITY(1,1),
   Date     datetime        NOT NULL  CONSTRAINT defXReceiveListItem$Date   DEFAULT GETDATE(),
   Object   nvarchar(32)    NOT NULL,
   Action   int             NOT NULL,
   Detail   nvarchar(3000)  NOT NULL  CONSTRAINT defXReceiveListEntrty$Detail DEFAULT '',
   Login    nvarchar(32)    NOT NULL  CONSTRAINT defXReceiveListEntrty$Login  DEFAULT 'SYSTEM'
)
END
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'XDisasterCodeList') BEGIN
CREATE TABLE dbo.XDisasterCodeList
(
-- Attributes
   ItemId   int             NOT NULL  CONSTRAINT pkXDisasterCodeList         PRIMARY KEY CLUSTERED  IDENTITY(1,1),
   Date     datetime        NOT NULL  CONSTRAINT defXDisasterCodeList$Date   DEFAULT GETDATE(),
   Object   nvarchar(32)    NOT NULL,
   Action   int             NOT NULL,
   Detail   nvarchar(3000)  NOT NULL  CONSTRAINT defXDisasterCodeList$Detail DEFAULT '',
   Login    nvarchar(32)    NOT NULL  CONSTRAINT defXDisasterCodeList$Login  DEFAULT 'SYSTEM'
)
END
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'XDisasterCodeListItem') BEGIN
CREATE TABLE dbo.XDisasterCodeListItem
(
-- Attributes
   ItemId   int             NOT NULL  CONSTRAINT pkXDisasterCodeListItem         PRIMARY KEY CLUSTERED  IDENTITY(1,1),
   Date     datetime        NOT NULL  CONSTRAINT defXDisasterCodeListItem$Date   DEFAULT GETDATE(),
   Object   nvarchar(32)    NOT NULL,
   Action   int             NOT NULL,
   Detail   nvarchar(3000)  NOT NULL  CONSTRAINT defXDisasterCodeListItem$Detail DEFAULT '',
   Login    nvarchar(32)    NOT NULL  CONSTRAINT defXDisasterCodeListItem$Login  DEFAULT 'SYSTEM'
)
END
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'XVaultInventory') BEGIN
CREATE TABLE dbo.XVaultInventory
(
-- Attributes
   ItemId   int             NOT NULL  CONSTRAINT pkXVaultInventory         PRIMARY KEY CLUSTERED  IDENTITY(1,1),
   Date     datetime        NOT NULL  CONSTRAINT defXVaultInventory$Date   DEFAULT GETDATE(),
   Object   nvarchar(256)   NOT NULL,
   Action   int             NOT NULL,
   Detail   nvarchar(3000)  NOT NULL  CONSTRAINT defXVaultInventory$Detail DEFAULT '',
   Login    nvarchar(32)    NOT NULL  CONSTRAINT defXVaultInventory$Login  DEFAULT 'SYSTEM'
)
END
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'XVaultDiscrepancy') BEGIN
CREATE TABLE dbo.XVaultDiscrepancy
(
-- Attributes
   ItemId   int             NOT NULL  CONSTRAINT pkXVaultDiscrepancy         PRIMARY KEY CLUSTERED  IDENTITY(1,1),
   Date     datetime        NOT NULL  CONSTRAINT defXVaultDiscrepancy$Date   DEFAULT GETDATE(),
   Object   nvarchar(256)   NOT NULL,
   Action   int             NOT NULL,
   Detail   nvarchar(3000)  NOT NULL  CONSTRAINT defXVaultDiscrepancy$Detail DEFAULT '',
   Login    nvarchar(32)    NOT NULL  CONSTRAINT defXVaultDiscrepancy$Login  DEFAULT 'SYSTEM'
)
END
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'XBarCodePattern') BEGIN
CREATE TABLE dbo.XBarCodePattern
(
-- Attributes
   ItemId   int             NOT NULL  CONSTRAINT pkXBarCodePattern         PRIMARY KEY CLUSTERED  IDENTITY(1,1),
   Date     datetime        NOT NULL  CONSTRAINT defXBarCodePattern$Date   DEFAULT GETDATE(),
   Detail   nvarchar(3000)  NOT NULL  CONSTRAINT defXBarCodePattern$Detail DEFAULT '',
   Login    nvarchar(32)    NOT NULL  CONSTRAINT defXBarCodePattern$Login  DEFAULT 'SYSTEM'
)
END
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'XIgnoredBarCodePattern') BEGIN
CREATE TABLE dbo.XIgnoredBarCodePattern
(
-- Attributes
   ItemId   int             NOT NULL  CONSTRAINT pkXIgnoredBarCodePattern         PRIMARY KEY CLUSTERED  IDENTITY(1,1),
   Date     datetime        NOT NULL  CONSTRAINT defXIgnoredBarCodePattern$Date   DEFAULT GETDATE(),
   Object   nvarchar(32)    NOT NULL,
   Action   int             NOT NULL,
   Detail   nvarchar(3000)  NOT NULL  CONSTRAINT defXIgnoredBarCodePattern$Detail DEFAULT '',
   Login    nvarchar(32)    NOT NULL  CONSTRAINT defXIgnoredBarCodePattern$Login  DEFAULT 'SYSTEM'
)
END
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'XExternalSiteLocation') BEGIN
CREATE TABLE dbo.XExternalSiteLocation
(
-- Attributes
   ItemId   int             NOT NULL  CONSTRAINT pkXExternalSiteLocation         PRIMARY KEY CLUSTERED  IDENTITY(1,1),
   Date     datetime        NOT NULL  CONSTRAINT defXExternalSiteLocation$Date   DEFAULT GETDATE(),
   Object   nvarchar(32)    NOT NULL,
   Action   int             NOT NULL,
   Detail   nvarchar(3000)  NOT NULL  CONSTRAINT defXExternalSiteLocation$Detail DEFAULT '',
   Login    nvarchar(32)    NOT NULL  CONSTRAINT defXExternalSiteLocation$Login  DEFAULT 'SYSTEM'
)
END
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'XSystemAction') BEGIN
CREATE TABLE dbo.XSystemAction
(
-- Attributes
   ItemId   int             NOT NULL  CONSTRAINT pkXSystemAction         PRIMARY KEY CLUSTERED  IDENTITY(1,1),
   Date     datetime        NOT NULL  CONSTRAINT defXSystemAction$Date   DEFAULT GETDATE(),
   Action   int             NOT NULL,
   Detail   nvarchar(3000)  NOT NULL  CONSTRAINT defXSystemAction$Detail DEFAULT '',
)
END
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'XGeneralAction') BEGIN
CREATE TABLE dbo.XGeneralAction
(
-- Attributes
   ItemId   int             NOT NULL  CONSTRAINT pkXGeneralAction         PRIMARY KEY CLUSTERED  IDENTITY(1,1),
   Date     datetime        NOT NULL  CONSTRAINT defXGeneralAction$Date   DEFAULT GETDATE(),
   Detail   nvarchar(3000)  NOT NULL  CONSTRAINT defXGeneralAction$Detail DEFAULT '',
   Login    nvarchar(32)    NOT NULL  CONSTRAINT defXGeneralAction$Login  DEFAULT 'SYSTEM'
)
END
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'XGeneralError') BEGIN
CREATE TABLE dbo.XGeneralError
(
-- Attributes
   ItemId   int             NOT NULL  CONSTRAINT pkXGeneralError         PRIMARY KEY CLUSTERED  IDENTITY(1,1),
   Date     datetime        NOT NULL  CONSTRAINT defXGeneralError$Date   DEFAULT GETDATE(),
   Detail   nvarchar(3000)  NOT NULL  CONSTRAINT defXGeneralError$Detail DEFAULT '',
   Login    nvarchar(32)    NOT NULL  CONSTRAINT defXGeneralError$Login  DEFAULT 'SYSTEM'
)
END
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'FtpProfile') BEGIN
CREATE TABLE dbo.FtpProfile
(
-- Attributes
   ProfileId    int             NOT NULL  CONSTRAINT pkFtpProfile PRIMARY KEY CLUSTERED  IDENTITY(1,1),
   ProfileName  nvarchar(256)   NOT NULL  CONSTRAINT akFtpProfile$ProfileName UNIQUE NONCLUSTERED,
   Server       nvarchar(256)   NOT NULL,
   Login        nvarchar(64)    NOT NULL,
   Password     nvarchar(128)   NOT NULL,
   FilePath     nvarchar(256)   NOT NULL,
   FileFormat   smallint        NOT NULL,  -- 1:: Iron Mountain, 2: VRI, 3: Recall
   Passive      bit             NOT NULL,
   Secure       bit             NOT NULL,
-- Concurrency   
   RowVersion   rowversion      NOT NULL
)
END
GO

-- Profile names may not contain pipes (used as escpae character)
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.CHECK_CONSTRAINTS WHERE CONSTRAINT_NAME = 'chkFtpProfile$Name')
   ALTER TABLE FtpProfile ADD CONSTRAINT chkFtpProfile$Name CHECK (dbo.bit$IsEmptyString(ProfileName) = 0 AND dbo.bit$IllegalCharacters(ProfileName, '|' ) = 0)
GO

-- Server cannot be an empty string
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.CHECK_CONSTRAINTS WHERE CONSTRAINT_NAME = 'chkFtpProfile$Server')
   ALTER TABLE FtpProfile ADD CONSTRAINT chkFtpProfile$Server CHECK (dbo.bit$IsEmptyString(Server) = 0)
GO

-- Login cannot be an empty string
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.CHECK_CONSTRAINTS WHERE CONSTRAINT_NAME = 'chkFtpProfile$Login')
   ALTER TABLE FtpProfile ADD CONSTRAINT chkFtpProfile$Login CHECK (dbo.bit$IsEmptyString(Login) = 0)
GO

-- File path cannot be an empty string
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.CHECK_CONSTRAINTS WHERE CONSTRAINT_NAME = 'chkFtpProfile$FilePath')
   ALTER TABLE FtpProfile ADD CONSTRAINT chkFtpProfile$FilePath CHECK (dbo.bit$IsEmptyString(FilePath) = 0)
GO

-- File format may only contain certain values
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.CHECK_CONSTRAINTS WHERE CONSTRAINT_NAME = 'chkFtpProfile$FileFormat')
   ALTER TABLE FtpProfile ADD CONSTRAINT chkFtpProfile$FileFormat CHECK (FileFormat IN (1,2,3))
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'FtpAccount') BEGIN
CREATE TABLE dbo.FtpAccount
(
-- Relationships
   ProfileId     int  NOT NULL,
   AccountId     int  NOT NULL  CONSTRAINT pkFtpAccount PRIMARY KEY CLUSTERED
)
END
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS WHERE CONSTRAINT_NAME = 'fkFtpAccount$Profile') BEGIN
ALTER TABLE dbo.FtpAccount
   ADD CONSTRAINT fkFtpAccount$Profile
      FOREIGN KEY (ProfileId) REFERENCES dbo.FtpProfile
         ON DELETE CASCADE
END
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS WHERE CONSTRAINT_NAME = 'fkFtpAccount$Account') BEGIN
ALTER TABLE dbo.FtpAccount
   ADD CONSTRAINT fkFtpAccount$Account
      FOREIGN KEY (AccountId) REFERENCES dbo.Account
         ON DELETE CASCADE
END
GO

SET NOCOUNT ON
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
--
-- We should have a database version check here.  If > 1.0.0, then do not
-- perform the update.  Future scripts should check should check to make sure
--
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
DECLARE @maj int  -- Current major version of database
DECLARE @min int  -- Current minor version of database
DECLARE @rev int  -- Current revision version of database
DECLARE @thisMaj int -- Major version of this script
DECLARE @thisMin int -- Minor version of this script
DECLARE @thisRev int -- Revision version of this script
DECLARE @runScript int  -- Current revision version of database

SET @thisMaj = 1
SET @thisMin = 0
SET @thisRev = 0
SET @runScript = 1

SELECT @maj = max(Major) 
FROM   DatabaseVersion
IF @maj IS NOT NULL BEGIN
   IF @maj > @thisMaj BEGIN
     SET @runScript = 0
   END
   ELSE IF @maj = @thisMaj BEGIN
     SELECT @min = max(Minor)
     FROM   DatabaseVersion 
     WHERE  Major = @maj
     IF @min > @thisMin BEGIN
        SET @runScript = 0
     END
     ELSE IF @min = @thisMin BEGIN
        SELECT @rev = max(Revision)
        FROM   DatabaseVersion 
        WHERE  Major = @maj AND Minor = @min
        IF @rev > @thisRev BEGIN
           SET @runScript = 0
        END
     END
   END
END

-- If we get here, then install it.  It's either the latest version of the
-- database or a higher version.
IF @runScript = 1 BEGIN

DECLARE @CREATE nchar(10)
DECLARE @exec nvarchar(2000)
DECLARE @id int

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
--
-- Stored Procedures
--
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'error$raise')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.error$raise
(
   @msg as nvarchar(4000),
   @error as int = 0,
   @tranName as nvarchar(512) = null,
   @severity as int = 16,
   @state as int = 1
)
AS
BEGIN

-- If the transaction name is not null, roll it back and commit it
IF @tranName IS NOT NULL BEGIN
   ROLLBACK TRANSACTION @tranName
   COMMIT TRANSACTION
END

-- Raise an error only if the error is less than 50000
IF @error < 50000 BEGIN
   RAISERROR(@msg,16,1)
END

END
'
)

-------------------------------------------------------------------------------
--
-- Stored Procedures -- Spid Login
--
-------------------------------------------------------------------------------
IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'spidLogin$del')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '
EXECUTE
(
@CREATE + 'PROCEDURE dbo.spidLogin$del
(
   @login nvarchar(32)
)
WITH ENCRYPTION
AS
BEGIN
DECLARE @msg as nvarchar(255)        -- used to preformat error message
DECLARE @msgTag as nvarchar(255)     -- used to hold first part of error message header
DECLARE @tranName as nvarchar(255)   -- used to hold name of savepoint
DECLARE @lastCall datetime
DECLARE @error int
DECLARE @spid int

SET NOCOUNT ON

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=P''
SET @tranName = object_name(@@procid) + CAST(@@nestlevel as nvarchar(2))

BEGIN TRANSACTION
SAVE TRANSACTION @tranName

DELETE SpidLogin
WHERE  Spid = @@spid AND Login = @login
SET @error = @@error
IF @error != 0 BEGIN
   SET @msg = ''Error deleting audit information.'' + @msgTag + ''>''
   EXECUTE error$raise @msg, @error, @tranName
   RETURN -100
END

-- Clean any outdated spids
SET @spid = 0
WHILE 1 = 1 BEGIN
   SELECT TOP 1 @spid = Spid, @lastCall = LastCall
   FROM   SpidLogin
   WITH  (READPAST)
   WHERE  @spid >= @spid AND 
          LastCall < DATEADD(dd, -1, getdate())
   ORDER  BY Spid ASC
   IF @@rowCount = 0
      BREAK
   ELSE BEGIN
      DELETE SpidLogin 
      WHERE  Spid = @spid AND LastCall = @lastCall
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
   @newTag nvarchar(1000),
   @oldTag nvarchar(1000) OUT
)
AS
BEGIN
DECLARE @msg as nvarchar(255)        -- used to preformat error message
DECLARE @msgTag as nvarchar(255)     -- used to hold first part of error message header
DECLARE @tranName as nvarchar(255)   -- used to hold name of savepoint
DECLARE @error as int

SET NOCOUNT ON

-- Tweak parameters
SET @newTag = ltrim(rtrim(@newTag))
SET @oldTag = ''''

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=P''
SET @tranName = object_name(@@procid) + CAST(@@nestlevel as nvarchar(2))

-- Begin transaction
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

-- Delete old login if it exists, after getting old tag
IF EXISTS(SELECT 1 FROM SpidLogin WHERE Spid = @@spid) BEGIN
   -- Get the old tag if the spid and login are same as given
   SELECT @oldTag = TagInfo
   FROM   SpidLogin
   WHERE  Spid = @@spid AND Login = @login
   -- Delete the record
   DELETE SpidLogin 
   WHERE  Spid = @@spid
END

-- Insert a new spid login record
INSERT SpidLogin
(
   Spid, 
   Login, 
   LastCall,
   TagInfo
)
VALUES
(
   @@spid, 
   @login, 
   getdate(),
   @newTag
)
SET @error = @@error
IF @error != 0 BEGIN
   SET @msg = ''Error encountered while inserting spid login.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
   EXECUTE error$raise @msg, @error, @tranName
   RETURN -100
END

-- Delete all unlocked spid login records over three hours old.  Very important
-- to skip over locked records.  Could case frequent deadlocks.
DELETE SpidLogin
WHERE  Spid IN (SELECT Spid 
                FROM   SpidLogin WITH (READPAST) 
                WHERE  datediff(mi, LastCall, getdate()) > 180)
SET @error = @@error
IF @error != 0 BEGIN
   SET @msg = ''Error encountered while deleting old audit logins.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
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
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.spidLogin$setInfo
(
   @info nvarchar(1000)
)
WITH ENCRYPTION
AS
BEGIN
UPDATE SpidLogin
SET    TagInfo = @info
WHERE  Spid = @@spid
IF @@rowcount = 0 OR @@error != 0 
   RETURN -100
ELSE
   RETURN 1
END
'
)

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'spidLogin$upd')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.spidLogin$upd
(
   @login nvarchar(32)
)
WITH ENCRYPTION
AS
BEGIN
DECLARE @tranName as nvarchar(255)   -- used to hold name of savepoint

SET NOCOUNT ON

-- Tweak parameters
SET @login = ltrim(rtrim(coalesce(@login,'''')))

-- Set up the transaction tag (nest level ensures uniqueness)
SET @tranName = object_name(@@procid) + CAST(@@nestlevel as nvarchar(2))

-- Update the login in the table
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

UPDATE SpidLogin
SET    Login = @login
WHERE  Spid = @@spid
IF @@error != 0 BEGIN
   ROLLBACK TRAN @tranName
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
-- Stored Procedures - Preference
--
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'preference$get')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.preference$get
(
   @keyNo int
)
WITH ENCRYPTION
AS
BEGIN

SET NOCOUNT ON

-- Select
SELECT KeyNo,
       Value
FROM   Preference
WHERE  KeyNo = @keyNo

END
'
)


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'preference$getTable')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.preference$getTable
WITH ENCRYPTION
AS
BEGIN

SET NOCOUNT ON

-- Select
SELECT KeyNo,
       Value
FROM   Preference
ORDER BY KeyNo Asc

END
'
)


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'preference$upd')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.preference$upd
(
   @keyNo int,
   @value nvarchar(64)
)
WITH ENCRYPTION
AS
BEGIN
DECLARE @msg as nvarchar(255)
DECLARE @msgTag as nvarchar(255)
DECLARE @tranName as nvarchar(255)   -- used to hold name of savepoint
DECLARE @error int

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=P''
SET @tranName = object_name(@@procid) + CAST(@@nestlevel as nvarchar(2))

SET NOCOUNT ON

-- Tweak parameters
SET @value = ltrim(rtrim(coalesce(@value,'''')))

-- Set up the transaction tag (nest level ensures uniqueness)
SET @tranName = object_name(@@procid) + CAST(@@nestlevel as nvarchar(2))

-- Update the login in the table
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

IF EXISTS(SELECT 1 FROM Preference WHERE KeyNo = @keyNo) BEGIN
   UPDATE Preference
   SET    Value = @value
   WHERE  KeyNo = @keyNo
END
ELSE BEGIN
   INSERT Preference(KeyNo, Value)
   VALUES(@keyNo, @value)
END

SET @error = @@error

IF @error != 0 BEGIN
   ROLLBACK TRANSACTION @tranName
   COMMIT TRANSACTION
   SET @msg = ''Error encountered while updating preference.'' + @msgTag + '';Error='' + cast(@error as nvarchar(10)) + ''>''
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
--
-- Triggers - Preference
--
-------------------------------------------------------------------------------
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
DECLARE @keyNo int

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
SELECT @keyNo = KeyNo, @value = Value FROM Inserted

-- Insert audit record
INSERT XGeneralAction
(
   Detail, 
   Login
)
VALUES
(
   ''Preference updated : Key='' + cast(@keyNo as nvarchar(10)) + '';Value='' + @value,
   dbo.string$GetSpidLogin()
)

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
DECLARE @keyNo int

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
SELECT @keyNo = KeyNo, @value = Value FROM Inserted

-- Insert audit record
INSERT XGeneralAction
(
   Detail, 
   Login
)
VALUES
(
   ''Preference updated : Key='' + cast(@keyNo as nvarchar(10)) + '';Value='' + @value,
   dbo.string$GetSpidLogin()
)

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

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'barCodePatternCase$getDefaults')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.barCodePatternCase$getDefaults
(
   @serialNo nvarchar(32),
   @typeId int OUT
)
WITH ENCRYPTION
AS
BEGIN
DECLARE @msgTag nvarchar(255)
DECLARE @msg nvarchar(255)

SET NOCOUNT ON

-- Select the defaults
SELECT @typeId = TypeId
FROM   BarCodePatternCase
WHERE  Position = (SELECT min(Position) 
                   FROM   BarCodePatternCase
                   WHERE  dbo.bit$RegexMatch(@serialNo,Pattern) = 1)

-- If no rows, then generate error
IF @@rowCount = 0 BEGIN
   SET @msgTag = ''<'' + object_name(@@procid) + '';Type=P''
   SET @msg = ''No default bar code case pattern found.'' + @msgTag + ''>''
   RAISERROR(@msg,16,1)
   RETURN -100
END

RETURN 0
END
'
)

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'nextListNumber$getName')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.nextListNumber$getName
(
   @listType nchar(2),
   @listName nchar(10) OUT
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

-- Get the list name
SELECT @listName = @listType + ''-'' + replace(str(Numeral,7),'' '',''0'')
FROM   NextListNumber WITH (TABLOCKX)
WHERE  ListType = @listType
IF @@rowCount = 0 BEGIN
   SET @msg = ''List type not found.'' + @msgTag + ''>''
   RAISERROR(@msg,16,1)
   RETURN -100
END

-- Increment the list number
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

UPDATE NextListNumber
SET    Numeral = Numeral + 1
WHERE  ListType = @listType
SET @error = @@error
IF @error != 0 BEGIN
   ROLLBACK TRANSACTION @tranName
   COMMIT TRANSACTION
   SET @msg = ''Error encountered while incrementing list number.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
   EXECUTE error$raise @msg, @error
   RETURN -100
END

COMMIT TRANSACTION
RETURN 0
END
'
)

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'barCodePattern$getDefaults')
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

SET NOCOUNT ON

-- Select the defaults
SELECT TOP 1 @typeName = m.TypeName,
       @accountName = a.AccountName
FROM   BarCodePattern b
JOIN   MediumType m
  ON   m.TypeId = b.TypeId
JOIN   Account a
  ON   a.AccountId = b.AccountId
WHERE  dbo.bit$RegexMatch(@serialNo,Pattern) = 1
ORDER  BY Position Asc

-- If no rows, then generate error
IF @@rowCount = 0 BEGIN
   SET @msgTag = ''<'' + object_name(@@procid) + '';Type=P''
   SET @msg = ''No default bar code pattern found.'' + @msgTag + ''>''
   RAISERROR(@msg,16,1)
   RETURN -100
END

RETURN 0
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
WHERE  TypeName = @mediumType
IF @@rowcount = 0 BEGIN
   SET @msg = ''Medium type not found.'' + @msgTag + ''>''
   RAISERROR(@msg,16,1)
   RETURN -100
END

-- Insert the medium into the database
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

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

SET NOCOUNT ON

-- Get the account and medium type
EXECUTE @returnValue = barCodePattern$GetDefaults @serialNo, @typeName OUT, @accountName OUT
IF @returnValue != 0 RETURN -100

-- Insert a medium record
EXECUTE @returnValue = medium$ins @serialNo, @location, 0, NULL, '''', '''', @typeName, @accountName, @newId OUT
IF @returnValue != 0 
   RETURN -100
ELSE
   RETURN 0
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
DECLARE @msg nvarchar(255)        -- used to preformat error message
DECLARE @msgTag nvarchar(255)     -- used to hold first part of error message header
DECLARE @tranName nvarchar(255)   -- used to hold name of savepoint
DECLARE @serialNo nvarchar(64)
DECLARE @lastMedium int
DECLARE @accountId int
DECLARE @typeId int
DECLARE @error int
DECLARE @rowNo int
DECLARE @tblMedium table (RowNo int PRIMARY KEY IDENTITY(1,1), MediumId int, SerialNo nvarchar(32))

SET NOCOUNT ON

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=P''
SET @tranName = object_name(@@procid) + CAST(@@nestlevel as nvarchar(2))

-- Update all the media in the system to have the correct medium types 
-- and account numbers
INSERT @tblMedium (MediumId, SerialNo)
SELECT m.MediumId,
       m.SerialNo
FROM   Medium m
WHERE  cast(m.TypeId as nvarchar(32)) + '' '' + cast(m.AccountId as nvarchar(32)) != 
          (SELECT TOP 1 cast(p.TypeId as nvarchar(32)) + '' '' + cast(p.AccountId as nvarchar(32))
           FROM   BarCodePattern p
           WHERE  dbo.bit$RegexMatch(m.SerialNo, p.Pattern) = 1
           ORDER  BY p.Position ASC)

SELECT @rowNo = 1

WHILE 1 = 1 BEGIN
   SELECT @lastMedium = MediumId,
          @serialNo = SerialNo
   FROM   @tblMedium
   WHERE  RowNo = @rowNo
   IF @@rowCount = 0
      BREAK
   ELSE BEGIN
      BEGIN TRANSACTION
      SAVE TRANSACTION @tranName
      -- Update to the correct account number
      SELECT TOP 1 @typeId = TypeId,
             @accountId = AccountId
      FROM   BarCodePattern
      WHERE  dbo.bit$RegexMatch(@serialNo, Pattern) = 1
      ORDER  BY Position Asc 
      -- If no pattern fits, then error.  Otherwise, update the medium.
      UPDATE Medium
      SET    TypeId = @typeId,
             AccountId = @accountId
      WHERE  MediumId = @lastMedium
      SET @error = @@error
      IF @error != 0 BEGIN
         ROLLBACK TRANSACTION @tranName
         SET @msg = ''Error encountered while updating medium '''''' + @serialNo + ''''''.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
         EXECUTE error$raise @msg, @error
      END
      -- Commit the transaction
      COMMIT TRANSACTION
   END
   -- Incremement row number
   SELECT @rowNo = @rowNo + 1
END
END
'
)

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'vaultDiscrepancyUnknownCase$resolve')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.vaultDiscrepancyUnknownCase$resolve
(
   @itemId int,
   @reason int -- 1. Case added, 2. Case name changed, 3. Ignored
)
WITH ENCRYPTION
AS
BEGIN
DECLARE @msg as nvarchar(255)        -- used to preformat error 
DECLARE @msgTag as nvarchar(255)     -- used to hold first part of error message header
DECLARE @tranName as nvarchar(255)   -- used to hold name of savepoint
DECLARE @detail as nvarchar(4000)
DECLARE @serial as nvarchar(32)
DECLARE @rowCount as int
DECLARE @returnValue as int
DECLARE @error as int

SET NOCOUNT ON

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=P''
SET @tranName = object_name(@@procid) + CAST(@@nestlevel as nvarchar(2))

-- Get the serial number of the medium
SELECT @serial = SerialNo 
FROM   VaultDiscrepancyUnknownCase
WHERE  ItemId = @itemId
IF @@rowCount = 0 RETURN 0

-- Make sure that the reason is either 1 or 2
IF @reason = 1
   SET @detail = ''Vault discrepancy (unknown case) resolved;Reason=Added''
ELSE IF @reason = 2
   SET @detail = ''Vault discrepancy (unknown case) resolved;Reason=NameChange''
ELSE IF @reason = 3
   SET @detail = ''Vault discrepancy (unknown case) ignored''
ELSE BEGIN
   SET @msg = ''Reason for vault discrepancy resolution is invalid.'' + @msgTag + ''>''
   RAISERROR(@msg,16,1)
   RETURN -100
END

-- Delete the discrepancy
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

DELETE VaultDiscrepancy 
WHERE  ItemId = @itemId
SELECT @error = @@error
IF @error != 0 BEGIN
   ROLLBACK TRANSACTION @tranName
   COMMIT TRANSACTION
   SET @msg = ''Error encountered while deleting vault discrepancy.'' + @msgTag + '';Error='' +  cast(@error as nvarchar(50)) + ''>''
   EXECUTE error$raise @msg, @error
   RETURN -100
END
   
-- Insert vault discrepancy audit record
INSERT XVaultDiscrepancy (Object, Action, Detail, Login)
VALUES(@serial, 3, @detail, dbo.string$GetSpidLogin())
SELECT @error = @@error
IF @error != 0 BEGIN
   ROLLBACK TRANSACTION @tranName
   COMMIT TRANSACTION
   SET @msg = ''Error encountered while inserting a vault discrepancy resolution record.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
   EXECUTE error$raise @msg, @error
   RETURN -100
END

-- Commit and return
COMMIT TRANSACTION
RETURN 0
END
'
)

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'vaultDiscrepancyCaseType$resolve')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.vaultDiscrepancyCaseType$resolve
(
   @itemId int,
   @reason int -- 1. Type change, 2. Ignored
)
WITH ENCRYPTION
AS
BEGIN
DECLARE @msg as nvarchar(255)        -- used to preformat error 
DECLARE @msgTag as nvarchar(255)     -- used to hold first part of error message header
DECLARE @tranName as nvarchar(255)   -- used to hold name of savepoint
DECLARE @detail as nvarchar(4000)
DECLARE @serial as nvarchar(32)
DECLARE @rowCount as int
DECLARE @returnValue as int
DECLARE @error as int

SET NOCOUNT ON

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=P''
SET @tranName = object_name(@@procid) + CAST(@@nestlevel as nvarchar(2))

-- Get the serial number of the case
SELECT @serial = SerialNo
FROM   VaultDiscrepancyCaseType
WHERE  ItemId = @itemId
IF @@rowCount = 0 RETURN 0

-- Make sure that the reason is either 1 or 2
IF @reason = 1
   SET @detail = ''Vault discrepancy (case type) resolved;Reason=TypeChange''
ELSE IF @reason = 2
   SET @detail = ''Vault discrepancy (case type) ignored''
ELSE BEGIN
   SET @msg = ''Reason for vault discrepancy resolution is invalid.'' + @msgTag + ''>''
   RAISERROR(@msg,16,1)
   RETURN -100
END

-- Delete the discrepancy
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

DELETE VaultDiscrepancy 
WHERE  ItemId = @itemId
SELECT @error = @@error
IF @error != 0 BEGIN
   ROLLBACK TRANSACTION @tranName
   COMMIT TRANSACTION
   SET @msg = ''Error encountered while deleting vault discrepancy.'' + @msgTag + '';Error='' +  cast(@error as nvarchar(50)) + ''>''
   EXECUTE error$raise @msg, @error
   RETURN -100
END
   
-- Insert vault discrepancy audit record
INSERT XVaultDiscrepancy (Object, Action, Detail, Login)
VALUES(@serial, 3, @detail, dbo.string$GetSpidLogin())
SELECT @error = @@error
IF @error != 0 BEGIN
   ROLLBACK TRANSACTION @tranName
   COMMIT TRANSACTION
   SET @msg = ''Error encountered while inserting a vault discrepancy resolution record.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
   EXECUTE error$raise @msg, @error
   RETURN -100
END

-- Commit and return
COMMIT TRANSACTION
RETURN 0
END
'
)

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'vaultDiscrepancyMediumType$resolve')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.vaultDiscrepancyMediumType$resolve
(
   @itemId int,
   @reason int -- 1. Type change, 2. Ignored
)
WITH ENCRYPTION
AS
BEGIN
DECLARE @msg as nvarchar(255)        -- used to preformat error 
DECLARE @msgTag as nvarchar(255)     -- used to hold first part of error message header
DECLARE @tranName as nvarchar(255)   -- used to hold name of savepoint
DECLARE @detail as nvarchar(4000)
DECLARE @serial as nvarchar(32)
DECLARE @rowCount as int
DECLARE @returnValue as int
DECLARE @error as int

SET NOCOUNT ON

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=P''
SET @tranName = object_name(@@procid) + CAST(@@nestlevel as nvarchar(2))

-- Get the serial number of the medium
SELECT @serial = SerialNo 
FROM   VaultDiscrepancyMediumType
WHERE  ItemId = @itemId
IF @@rowCount = 0 RETURN 0

-- Make sure that the reason is either 1 or 2
IF @reason = 1
   SET @detail = ''Vault discrepancy (medium type) resolved;Reason=TypeChange''
ELSE IF @reason = 2
   SET @detail = ''Vault discrepancy (medium type) ignored''
ELSE BEGIN
   SET @msg = ''Reason for vault discrepancy resolution is invalid.'' + @msgTag + ''>''
   RAISERROR(@msg,16,1)
   RETURN -100
END

-- Delete the discrepancy
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

DELETE VaultDiscrepancy 
WHERE  ItemId = @itemId
SELECT @error = @@error
IF @error != 0 BEGIN
   ROLLBACK TRANSACTION @tranName
   COMMIT TRANSACTION
   SET @msg = ''Error encountered while deleting vault discrepancy.'' + @msgTag + '';Error='' +  cast(@error as nvarchar(50)) + ''>''
   EXECUTE error$raise @msg, @error
   RETURN -100
END
   
-- Insert vault discrepancy audit record
INSERT XVaultDiscrepancy (Object, Action, Detail, Login)
VALUES(@serial, 3, @detail, dbo.string$GetSpidLogin())
SELECT @error = @@error
IF @error != 0 BEGIN
   ROLLBACK TRANSACTION @tranName
   COMMIT TRANSACTION
   SET @msg = ''Error encountered while inserting a vault discrepancy resolution record.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
   EXECUTE error$raise @msg, @error
   RETURN -100
END

-- Commit and return
COMMIT TRANSACTION
RETURN 0
END
'
)

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'vaultDiscrepancyResidency$resolve')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.vaultDiscrepancyResidency$resolve
(
   @itemId int,
   @reason int -- 1: Moved, 2: Missing, 3: Ignored
)
WITH ENCRYPTION
AS
BEGIN
DECLARE @msg as nvarchar(255)        -- used to preformat error 
DECLARE @msgTag as nvarchar(255)     -- used to hold first part of error message header
DECLARE @tranName as nvarchar(255)   -- used to hold name of savepoint
DECLARE @detail as nvarchar(4000)
DECLARE @serial as nvarchar(32)
DECLARE @rowCount as int
DECLARE @returnValue as int
DECLARE @error as int

SET NOCOUNT ON

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=P''
SET @tranName = object_name(@@procid) + CAST(@@nestlevel as nvarchar(2))

-- Get the serial number of the medium
SELECT @serial = SerialNo 
FROM   VaultDiscrepancyResidency
WHERE  ItemId = @itemId
IF @@rowCount = 0 RETURN 0

-- Make sure that the reason is either 1 or 2
IF @reason = 1
   SET @detail = ''Vault discrepancy (residency) resolved;Reason=Moved''
ELSE IF @reason = 2
   SET @detail = ''Vault discrepancy (residency) resolved;Reason=Missing''
ELSE IF @reason = 3
   SET @detail = ''Vault discrepancy (residency) ignored''
ELSE BEGIN
   SET @msg = ''Reason for vault discrepancy resolution is invalid.'' + @msgTag + ''>''
   RAISERROR(@msg,16,1)
   RETURN -100
END

-- Delete the discrepancy
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

DELETE VaultDiscrepancy 
WHERE  ItemId = @itemId
SELECT @error = @@error
IF @error != 0 BEGIN
   ROLLBACK TRANSACTION @tranName
   COMMIT TRANSACTION
   SET @msg = ''Error encountered while deleting vault discrepancy.'' + @msgTag + '';Error='' +  cast(@error as nvarchar(50)) + ''>''
   EXECUTE error$raise @msg, @error
   RETURN -100
END
   
-- Insert vault discrepancy audit record
INSERT XVaultDiscrepancy (Object, Action, Detail, Login)
VALUES(@serial, 3, @detail, dbo.string$GetSpidLogin())
SELECT @error = @@error
IF @error != 0 BEGIN
   ROLLBACK TRANSACTION @tranName
   COMMIT TRANSACTION
   SET @msg = ''Error encountered while inserting a vault discrepancy resolution record.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
   EXECUTE error$raise @msg, @error
   RETURN -100
END

-- Commit and return
COMMIT TRANSACTION
RETURN 0
END
'
)

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'vaultDiscrepancyAccount$resolve')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.vaultDiscrepancyAccount$resolve
(
   @itemId int,
   @reason int -- 1. Type change, 2. Ignored
)
WITH ENCRYPTION
AS
BEGIN
DECLARE @msg as nvarchar(255)        -- used to preformat error 
DECLARE @msgTag as nvarchar(255)     -- used to hold first part of error message header
DECLARE @tranName as nvarchar(255)   -- used to hold name of savepoint
DECLARE @detail as nvarchar(4000)
DECLARE @serial as nvarchar(32)
DECLARE @rowCount as int
DECLARE @returnValue as int
DECLARE @error as int

SET NOCOUNT ON

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=P''
SET @tranName = object_name(@@procid) + CAST(@@nestlevel as nvarchar(2))

-- Get the serial number of the medium
SELECT @serial = SerialNo 
FROM   VaultDiscrepancyAccount
WHERE  ItemId = @itemId
IF @@rowCount = 0 RETURN 0

-- Make sure that the reason is either 1 or 2
IF @reason = 1
   SET @detail = ''Vault discrepancy (account) resolved;Reason=AccountChange''
ELSE IF @reason = 2
   SET @detail = ''Vault discrepancy (account) ignored''
ELSE BEGIN
   SET @msg = ''Reason for vault discrepancy resolution is invalid.'' + @msgTag + ''>''
   RAISERROR(@msg,16,1)
   RETURN -100
END

-- Delete the discrepancy
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

DELETE VaultDiscrepancy 
WHERE  ItemId = @itemId
SELECT @error = @@error
IF @error != 0 BEGIN
   ROLLBACK TRANSACTION @tranName
   COMMIT TRANSACTION
   SET @msg = ''Error encountered while deleting vault discrepancy.'' + @msgTag + '';Error='' +  cast(@error as nvarchar(50)) + ''>''
   EXECUTE error$raise @msg, @error
   RETURN -100
END
   
-- Insert vault discrepancy audit record
INSERT XVaultDiscrepancy (Object, Action, Detail, Login)
VALUES(@serial, 3, @detail, dbo.string$GetSpidLogin())
SELECT @error = @@error
IF @error != 0 BEGIN
   ROLLBACK TRANSACTION @tranName
   COMMIT TRANSACTION
   SET @msg = ''Error encountered while inserting a vault discrepancy resolution record.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
   EXECUTE error$raise @msg, @error
   RETURN -100
END

-- Commit and return
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
DECLARE @rowCount as int
DECLARE @error as int
DECLARE @listName as nchar(10)
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
FROM   DisasterCodeList 
WHERE  ListId = @compositeId
IF @@rowCount = 0 BEGIN
   SET @msg = ''Disaster code list not found.'' + @msgTag + ''>''
   RAISERROR(@msg,16,1)
   RETURN -100
END
ELSE IF NOT EXISTS
   (
   SELECT 1
   FROM   DisasterCodeList
   WHERE  ListId = @compositeId AND RowVersion = @compositeVersion
   )
BEGIN
   SET @msg = ''Disaster code list '''''' + @compositeName + '''''' has been modified since retrieval.'' + @msgTag + ''>''
   RAISERROR(@msg,16,1)
   RETURN -100
END
ELSE IF EXISTS
   (
   SELECT 1
   FROM   DisasterCodeList
   WHERE  ListId = @compositeId AND AccountId IS NOT NULL
   )
BEGIN
   SET @msg = ''Disaster code list '''''' + @compositeName + '''''' is not a composite list.'' + @msgTag + ''>''
   RAISERROR(@msg,16,1)
   RETURN -100
END
ELSE IF @status >= 16 BEGIN -- power(4,x)
   SET @msg = ''Lists may not be extracted after they have been transmitted.'' + @msgTag + ''>''
   RAISERROR(@msg,16,1)
   RETURN -100
END

-- Check concurrency of discrete, and verify that it actually belongs to the
-- given composite list
SELECT @listName = ListName
FROM   DisasterCodeList 
WHERE  ListId = @listId
IF @@rowCount = 0 BEGIN
   SET @msg = ''Disaster code list not found.'' + @msgTag + ''>''
   RAISERROR(@msg,16,1)
   RETURN -100
END
ELSE IF NOT EXISTS
   (
   SELECT 1
   FROM   DisasterCodeList
   WHERE  ListId = @listId AND RowVersion = @listVersion
   )
BEGIN
   SET @msg = ''Disaster code list '''''' + @listName + '''''' has been modified since retrieval.'' + @msgTag + ''>''
   RAISERROR(@msg,16,1)
   RETURN -100
END
ELSE IF NOT EXISTS
   (
   SELECT 1
   FROM   DisasterCodeList
   WHERE  ListId = @listId AND CompositeId = @compositeId
   )
BEGIN
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
WHERE  ListId = @listId
IF @@rowCount = 0 BEGIN
   SET @msg = ''Disaster code list not found.'' + @msgTag + ''>''
   RAISERROR(@msg,16,1)
   RETURN -100
END
ELSE IF @status = 16 BEGIN -- power(4,x)
   SET @msg = ''Lists may not be deleted after they have been transmitted.'' + @msgTag + ''>''
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
   SET @msg = ''Disaster code list '''''' + @listName + '''''' has been modified since retrieval.'' + @msgTag + ''>''
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
ELSE IF @status >= 256 BEGIN -- power(4,4)
   SET @msg = ''Lists may not be extracted after they have been transmitted.'' + @msgTag + ''>''
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
ELSE IF @status = 256 BEGIN -- power(4,4)
   SET @msg = ''Lists may not be deleted after they have been transmitted.'' + @msgTag + ''>''
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
FROM   ReceiveList 
WHERE  ListId = @compositeId
IF @@rowCount = 0 BEGIN
   SET @msg = ''Receive list not found.'' + @msgTag + ''>''
   RAISERROR(@msg,16,1)
   RETURN -100
END
ELSE IF NOT EXISTS
   (
   SELECT 1
   FROM   ReceiveList
   WHERE  ListId = @compositeId AND RowVersion = @compositeVersion
   )
BEGIN
   SET @msg = ''Receive list '''''' + @compositeName + '''''' has been modified since retrieval.'' + @msgTag + ''>''
   RAISERROR(@msg,16,1)
   RETURN -100
END
ELSE IF EXISTS
   (
   SELECT 1
   FROM   ReceiveList
   WHERE  ListId = @compositeId AND AccountId IS NOT NULL
   )
BEGIN
   SET @msg = ''Receive list '''''' + @compositeName + '''''' is not a composite list.'' + @msgTag + ''>''
   RAISERROR(@msg,16,1)
   RETURN -100
END
ELSE IF @status >= 16 BEGIN -- power(4,2)
   SET @msg = ''Lists may not be extracted after they have been transmitted.'' + @msgTag + ''>''
   RAISERROR(@msg,16,1)
   RETURN -100
END

-- Check concurrency of discrete, and verify that it actually belongs to the
-- given composite list
SELECT @listName = ListName
FROM   ReceiveList 
WHERE  ListId = @listId
IF @@rowCount = 0 BEGIN
   SET @msg = ''Receive list not found.'' + @msgTag + ''>''
   RAISERROR(@msg,16,1)
   RETURN -100
END
ELSE IF NOT EXISTS
   (
   SELECT 1
   FROM   ReceiveList
   WHERE  ListId = @listId AND RowVersion = @listVersion
   )
BEGIN
   SET @msg = ''Receive list '''''' + @listName + '''''' has been modified since retrieval.'' + @msgTag + ''>''
   RAISERROR(@msg,16,1)
   RETURN -100
END
ELSE IF NOT EXISTS
   (
   SELECT 1
   FROM   ReceiveList
   WHERE  ListId = @listId AND CompositeId = @compositeId
   )
BEGIN
   SET @msg = ''Receive list '''''' + @listName + '''''' is not part of composite list '''''' + @compositeName + ''''''.'' + @msgTag + ''>''
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
   SET @msg = ''Receive list '''''' + @listName + '''''' may not be extracted because case '''''' + @caseName + '''''' also appears on another list within the same composite.'' + @msgTag + ''>''
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
WHERE  ListId = @listId
IF @@rowCount = 0 BEGIN
   SET @msg = ''Receive list not found.'' + @msgTag + ''>''
   RAISERROR(@msg,16,1)
   RETURN -100
END
ELSE IF @status IN (16, 64, 256) AND @chkOverride != 1 BEGIN -- power(4,2)
   SET @msg = ''Lists may not be deleted after they have been transmitted.'' + @msgTag + ''>''
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
   SET @msg = ''Receive list '''''' + @listName + '''''' has been modified since retrieval.'' + @msgTag + ''>''
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

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'disasterCodeList$create')
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
   cast(convert(nchar(19),getdate(),120) as datetime),
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
ELSE BEGIN
   IF @status = 1 -- power(4,x)
      RETURN 0
   ELSE IF @status != 4 BEGIN -- power(4,x)
      SET @msg = ''Item has been transmitted.'' + @msgTag + ''>''
      RAISERROR(@msg,16,1)
      RETURN -100
   END
END

-- Begin the transaction
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

-- Update the status of the disaster code list item to removed
UPDATE DisasterCodeListItem
SET    Status = 1 -- power(4,x)
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
WHERE  dli.Status IN (4, 16) AND  -- power(4,x)
       dlic.CaseId = @caseId
IF @@rowCount > 0 BEGIN
   IF @priorStatus = 16 BEGIN -- power(4,x)
      ROLLBACK TRANSACTION @tranName
      COMMIT TRANSACTION
      SET @msg = ''Case '''''' + @serialNo + '''''' is on an active disaster code list that has been transmitted.'' + @msgTag + ''>''
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
   WHERE  dli.Status = 1 AND  -- power(4,x)
          dlic.CaseId = @caseId AND
         (dl.ListId = @listId OR coalesce(dl.CompositeId,0) = @listId)
   IF @@rowCount > 0 BEGIN
      UPDATE DisasterCodeListItem
      SET    Status = 4, -- power(4,x)
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
IF EXISTS (SELECT 1 FROM DisasterCodeList WHERE ListId = @listId AND AccountId IS NULL) BEGIN
   SELECT TOP 1 @listId = ListId
   FROM   DisasterCodeList dcl
   JOIN   Account a
     ON   a.AccountId = dcl.AccountId
   JOIN   Medium m
     ON   m.AccountId = a.AccountId
   JOIN   MediumSealedCase msc
     ON   msc.MediumId = m.MediumId
   WHERE  msc.CaseId = @caseId AND 
          dcl.CompositeId = @listId
   ORDER BY a.AccountName Asc
   IF @@rowCount = 0 BEGIN
      ROLLBACK TRANSACTION @tranName
      COMMIT TRANSACTION
      SET @msg = ''No list within composite has same account as any of the media within sealed case '''''' + @caseName + ''''''.'' + @msgTag + ''>''
      EXECUTE error$raise @msg, 0
      RETURN -100
   END
END
ELSE BEGIN
   IF NOT EXISTS
      (
      SELECT 1
      FROM   DisasterCodeList dl
      JOIN   Medium m
        ON   m.AccountId = dl.AccountId
      JOIN   MediumSealedCase msc
        ON   msc.MediumId = m.MediumId
      WHERE  msc.CaseId = @caseId AND
             dl.ListId = @listId
      )
   IF @@rowCount = 0 BEGIN
      ROLLBACK TRANSACTION @tranName
      COMMIT TRANSACTION
      SET @msg = ''List does not have same account as any of the media within sealed case '''''' + @caseName + ''''''.'' + @msgTag + ''>''
      EXECUTE error$raise @msg, 0
      RETURN -100
   END
END -- Insert the item
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
WHERE  dli.Status IN (4, 16) AND -- power(4,x)
       dlic.CaseId = @caseId AND
       charindex(dl.ListName,@batchLists) = 0
IF @@rowCount > 0 BEGIN
   IF @priorStatus = 16 BEGIN -- power(4,x)
      ROLLBACK TRANSACTION @tranName
      COMMIT TRANSACTION
      SET @msg = ''Medium '''''' + @serialNo + '''''' has been transmitted on another active disaster code list.'' + @msgTag + ''>''
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
      IF @itemStatus = 1 BEGIN -- power(4,x)
         UPDATE DisasterCodeListItem
         SET    Status = 4, Code = @code -- power(4,x)
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
DECLARE @listAccount as int
DECLARE @mediumAccount as int
DECLARE @serialNo as nvarchar(32)
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
       @mediumAccount = m.AccountId
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
WHERE  dli.Status IN (4,16) AND dlim.MediumId = @mediumId -- power(4,x)
IF @@rowCount > 0 BEGIN
   IF @priorStatus = 16 BEGIN -- power(4,x)
      ROLLBACK TRANSACTION @tranName
      COMMIT TRANSACTION
      SET @msg = ''Medium '''''' + @serialNo + '''''' is on an active disaster code list that has been transmitted.'' + @msgTag + ''>''
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
   WHERE  dli.Status = 1 AND  -- power(4,x)
          dlim.MediumId = @mediumId AND
         (dl.ListId = @listId OR coalesce(dl.CompositeId,0) = @listId)
   IF @@rowCount > 0 BEGIN
      UPDATE DisasterCodeListItem
      SET    Status = 4, -- power(4,x)
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
SELECT @listAccount = AccountId
FROM   DisasterCodeList
WHERE  ListId = @listId AND 
       AccountId IS NOT NULL
IF @@rowCount = 0 BEGIN
   SELECT @listId = ListId
   FROM   DisasterCodeList
   WHERE  CompositeId = @listId AND 
          AccountId = @mediumAccount
   IF @@rowCount = 0 BEGIN
      ROLLBACK TRANSACTION @tranName
      COMMIT TRANSACTION
      SET @msg = ''No list within the composite has the same account as medium '''''' + @serialNo + ''''''.'' + @msgTag + ''>''
      RAISERROR(@msg,16,1)
      RETURN -100
   END
END
ELSE IF @listAccount != @mediumAccount BEGIN
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
WHERE  dli.Status IN (4,16) AND -- power(4,x)
       dlim.MediumId = @mediumId AND
       charindex(dl.ListName,@batchLists) = 0
IF @@rowCount > 0 BEGIN
   IF @priorStatus = 16 BEGIN -- power(4,x)
      ROLLBACK TRANSACTION @tranName
      COMMIT TRANSACTION
      SET @msg = ''Medium '''''' + @serialNo + '''''' has been transmitted on another active disaster code list.'' + @msgTag + ''>''
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
      IF @itemStatus = 1 BEGIN -- power(4,x)
         UPDATE DisasterCodeListItem
         SET    Status = 4, Code = @code -- power(4,x)
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

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'sendList$create')
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
   cast(convert(nchar(19),getdate(),120) as datetime),
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
   IF @status NOT IN (4,64) BEGIN -- power(4,x)
      SET @msg = ''Cannot remove from case because send list item has been removed, transmitted, or cleared.'' + @msgTag + ''>''
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

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'sendListItem$remove')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.sendListItem$remove
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
   IF @status = 1 BEGIN -- power(4,0)
      RETURN
   END
   ELSE IF @status > 64 BEGIN -- power(4,x)
      SET @msg = ''Send list item may not be removed from list after it has been transmitted.'' + @msgTag + ''>''
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
SET    Status = 1 -- power(4,0)
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

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'sendListCase$ins')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.sendListCase$ins
(
   @caseName nvarchar(32),
   @caseId int OUTPUT
)
WITH ENCRYPTION
AS
BEGIN
DECLARE @msg as nvarchar(255)        -- used to preformat error message
DECLARE @msgTag as nvarchar(255)     -- used to hold first part of error message header
DECLARE @tranName as nvarchar(255)   -- used to hold name of savepoint
DECLARE @returnValue as int
DECLARE @typeId as int
DECLARE @error as int

SET NOCOUNT ON

-- Tweak parameter
SET @caseName = ltrim(rtrim(@caseName))

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=P''
SET @tranName = object_name(@@procid) + CAST(@@nestlevel as nvarchar(2))

-- Verify that the case does not exist in the sealed case table and that there
-- is no medium with the case name.
IF EXISTS(SELECT 1 FROM SealedCase WHERE SerialNo = @caseName) BEGIN
   SET @msg = ''Case '''''' + @caseName + '''''' currently resides at vault.'' + @msgTag + ''>''
   RAISERROR(@msg,16,1)
   RETURN -100
END
ELSE IF EXISTS(SELECT 1 FROM Medium WHERE SerialNo = @caseName) BEGIN
   SET @msg = ''A medium with serial number '''''' + @caseName + '''''' already exists.'' + @msgTag + ''>''
   RAISERROR(@msg,16,1)
   RETURN -100
END

-- Add the case if it does already exist in the send list case table
SELECT @caseId = CaseId 
FROM   SendListCase 
WHERE  SerialNo = @caseName AND Cleared = 0
IF @@rowCount != 0 RETURN 0

-- Get the type for the case
EXECUTE @returnValue = barCodePatternCase$getDefaults @caseName, @typeId OUT
IF @returnValue != 0 RETURN -100

-- Begin the transaction
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

-- Insert the record
INSERT SendListCase
(
   SerialNo,
   TypeId
)
VALUES
(
   @caseName,
   @typeId
)

-- Check the error   
SET @error = @@error
IF @error != 0 BEGIN
   ROLLBACK TRANSACTION @tranName
   COMMIT TRANSACTION
   SET @msg = ''Error encountered while inserting a new send list case.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
   EXECUTE error$raise @msg, @error
   RETURN -100
END

-- Commit
SET @caseId = scope_identity()
COMMIT TRANSACTION

-- Return
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
   WHERE  ItemId = @itemId AND Status NOT IN (4,64) -- power(4,x)
   )
BEGIN
   SET @msg = ''Item may not be inserted into case if it has been transmitted, cleared, or removed from list.'' + @msgTag + ''>''
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
      WHERE  slic.caseId = @caseId AND sl.Status = 256 -- power(4,4)
      )
   BEGIN
      SET @msg = ''Item may not be inserted into case currently marked as transmitted.'' + @msgTag + ''>''
      RAISERROR(@msg,16,1)
      RETURN -100
   END
   -- Verify that the case does not actively appear (itemStatus = 4, 64, 256) on -- power(4,x)
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
          sli.Status IN (4,64,256) AND -- power(4,x)
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

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'mediumSealedCase$del')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.mediumSealedCase$del
(
   @caseId int,
   @mediumId int
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

-- Delete sealed case
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

DELETE MediumSealedCase
WHERE  CaseId = @caseId AND
       MediumId = @mediumId
SELECT @error = @@error
       
IF @error != 0 BEGIN
   ROLLBACK TRANSACTION @tranName
   COMMIT TRANSACTION
   SET @msg = ''Error occurred deleting sealed case medium record.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
   EXECUTE error$raise @msg, @error
   RETURN -100
END

COMMIT TRANSACTION
RETURN 0
END
'
)

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'receiveList$create')
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
   cast(convert(nchar(19),getdate(),120) as datetime),
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
   @caseOthers int = 0      -- remove others from sealed case
)
WITH ENCRYPTION
AS
BEGIN
DECLARE @msg as nvarchar(255)        -- used to preformat error message
DECLARE @msgTag as nvarchar(255)     -- used to hold first part of error message header
DECLARE @tranName as nvarchar(255)   -- used to hold name of savepoint
DECLARE @returnValue as int
DECLARE @mediumId as int
DECLARE @missing as bit
DECLARE @rowCount as int
DECLARE @error as int
DECLARE @status as int
DECLARE @caseId as int

SET NOCOUNT ON

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=P''
SET @tranName = object_name(@@procid) + CAST(@@nestlevel as nvarchar(2))

-- Get the missing status of the medium to which the list item corresponds
-- SELECT @missing = m.Missing 
-- FROM   Medium m
-- JOIN   ReceiveListItem rli
--   ON   rli.MediumId = m.MediumId
-- WHERE  rli.ItemId = @itemId

-- Verify the status of the item as submitted or transmitted
SELECT @status = Status,
       @mediumId = MediumId
FROM   ReceiveListItem
WHERE  ItemId = @itemId AND
       RowVersion = @rowVersion
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
ELSE BEGIN
   IF @status = 1 BEGIN -- power(4,0)
      RETURN
   END
   ELSE IF @status >= 256 BEGIN -- power(4,1)
      SET @msg = ''Medium on receive list cannot be removed after it has been verified.'' + @msgTag + ''>''
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
SET    Status = 1 -- power(4,0)
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
LEFT
OUTER
JOIN   MediumSealedCase msc
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
      IF EXISTS
         (
         SELECT 1
         FROM   MediumSealedCase msc
         JOIN   ReceiveListItem rli
           ON   rli.MediumId = msc.MediumId
         JOIN   ReceiveList rl
           ON   rl.ListId = rli.ListId
         WHERE  msc.CaseId = @caseId AND
                rli.Status IN (4,16,256) AND -- power(4,x)
                charindex(rl.ListName,@batchLists) = 0
         )
      BEGIN
         ROLLBACK TRANSACTION @tranName
         COMMIT TRANSACTION
         SELECT @caseName = SerialNo FROM SealedCase WHERE CaseId = @caseId
         SET @msg = ''Case '''''' + @caseName + '''''' actively appears on list outside of batch.'' + @msgTag + ''>''
         RAISERROR(@msg,16,1)
         RETURN -100
      END
   END
   ELSE BEGIN   -- medium not in a case
      SELECT @priorId = rli.ItemId,
             @priorStatus = rli.Status,
             @priorVersion = rli.RowVersion
      FROM   ReceiveListItem rli
      JOIN   ReceiveList rl
        ON   rl.ListId = rli.ListId
      WHERE  rli.Status IN (4,16,256) AND -- power(4,x)
             rli.MediumId = @mediumId AND
             charindex(rl.ListName,@batchLists) = 0
      IF @@rowCount > 0 BEGIN
         IF @priorStatus IN (16,256) BEGIN -- power(4,x)
            ROLLBACK TRANSACTION @tranName
            COMMIT TRANSACTION
            SET @msg = ''Medium '''''' + @serialNo + '''''' has been transmitted on another active receive list.'' + @msgTag + ''>''
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
         IF @status != 1 BEGIN       -- Medium is already on a list within the batch -- power(4,0)
            COMMIT TRANSACTION
            RETURN 0
         END
         ELSE BEGIN
            UPDATE ReceiveListItem
            SET    Status = 4 -- power(4,1)
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
ELSE IF @listStatus > 4 BEGIN -- power(4,1)
   SET @msg = ''Receive list may not be altered after it has been transmitted.'' + @msgTag + ''>''
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
LEFT
OUTER
JOIN   MediumSealedCase msc
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
   SELECT @priorId = ItemId,
          @priorStatus = Status,
          @priorVersion = RowVersion
   FROM   ReceiveListItem
   WHERE  Status IN (4,16,256) AND  -- power(4,x)
          MediumId = @mediumId
   IF @@rowCount > 0 BEGIN
      IF @priorStatus IN (16,256) BEGIN -- power(4,x)
         ROLLBACK TRANSACTION @tranName
         COMMIT TRANSACTION
         SET @msg = ''Medium '''''' + @serialNo + '''''' is on an active receive list that has been transmitted.'' + @msgTag + ''>''
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
               SET @msg = ''Medium '''''' + @serialNo + '''''' is in a sealed case on an active receive list.'' + @msgTag + ''>''
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
      WHERE  rli.Status = 1 AND  -- power(4,0)
             rli.MediumId = @mediumId AND
            (rl.ListId = @listId OR coalesce(rl.CompositeId,0) = @listId)
      IF @@rowCount > 0 BEGIN
         UPDATE ReceiveListItem
         SET    Status = 4 -- power(4,1)
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
                (
                   ListId = @listId OR
                   CompositeId = (SELECT coalesce(CompositeId,0) FROM ReceiveList WHERE ListId = @listId)
                )
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

-- HERE!

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
--
-- Stored Procedures - Account
--
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'account$del')
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

-- Default bar code pattern cannot have this account!
IF EXISTS
   (
   SELECT 1 
   FROM   BarCodePattern 
   WHERE  AccountId = @id AND
          Position = (SELECT max(Position) FROM BarCodePattern)
   )
BEGIN
   SET @msg = ''Account belongs to the catch-all bar code format and may not be deleted.'' + @msgTag + ''>''
   EXECUTE error$raise @msg, @error
   RETURN -100
END

BEGIN TRANSACTION
SAVE TRANSACTION @tranName

-- Delete any send lists with this account regardless of status
SET @listId = 0
WHILE 1 = 1 BEGIN
   SELECT TOP 1 @listId = ListId,
          @listName = ListName,
          @listVersion = RowVersion
   FROM   SendList
   WHERE  AccountId = @id AND ListId > @listId
   ORDER  BY ListId ASC
   IF @@rowCount = 0
      BREAK
   ELSE BEGIN
      EXECUTE @returnValue = sendList$del @listId, @listVersion
      IF @returnValue != 0 BEGIN
         ROLLBACK TRANSACTION @tranName
         COMMIT TRANSACTION
         RETURN -100
      END
   END
END

-- Delete any receive lists with this account regardless of status
SET @listId = 0
WHILE 1 = 1 BEGIN
   SELECT TOP 1 @listId = ListId,
          @listName = ListName,
          @listVersion = RowVersion
   FROM   ReceiveList
   WHERE  AccountId = @id AND ListId > @listId
   ORDER  BY ListId ASC
   IF @@rowCount = 0
      BREAK
   ELSE BEGIN
      EXECUTE @returnValue = receiveList$del @listId, @listVersion
      IF @returnValue != 0 BEGIN
         ROLLBACK TRANSACTION @tranName
         COMMIT TRANSACTION
         RETURN -100
      END
   END
END

-- Delete any disaster code lists with this account regardless of status
SET @listId = 0
WHILE 1 = 1 BEGIN
   SELECT TOP 1 @listId = ListId,
          @listName = ListName,
          @listVersion = RowVersion
   FROM   DisasterCodeList
   WHERE  AccountId = @id AND ListId > @listId
   ORDER  BY ListId ASC
   IF @@rowCount = 0
      BREAK
   ELSE BEGIN
      EXECUTE @returnValue = disasterCodeList$del @listId, @listVersion
      IF @returnValue != 0 BEGIN
         ROLLBACK TRANSACTION @tranName
         COMMIT TRANSACTION
         RETURN -100
      END
   END
END

-- Delete the bar code formats.  Note that we''re better off, in the middle layer,
-- adjusting the bar codes before deleting accounts.  The reason for this is because
-- if we are deleting more than one account, we are going to synchronize all the
-- media in the database, which is a lengthy process, more than once.
IF EXISTS(SELECT 1 FROM BarCodePattern WHERE AccountId = @id) BEGIN
   DELETE BarCodePattern WHERE AccountId = @id
   SET @error = @@error
   IF @error = 0 BEGIN
	   ROLLBACK TRANSACTION @tranName
	   COMMIT TRANSACTION
	   SET @msg = ''Error encountered while deleting bar code pattern.'' + @msgTag + '';Error='' + cast(@error as nvarchar(10)) + ''>''
	   EXECUTE error$raise @msg, @error
	   RETURN -100
   END
   -- Adjust positions of the remaining barcode patterns
   SELECT @pos = 1, 
          @rowCount = count(*) 
   FROM BarCodePattern
	WHILE @pos <= @rowCount BEGIN
      IF NOT EXISTS (SELECT 1 FROM BarCodePattern WHERE Position = @pos) BEGIN
         UPDATE BarCodePattern
         SET    Position = @pos
         WHERE  PatId = (SELECT TOP 1 PatId 
                         FROM   BarCodePattern
                         WHERE  Position > @pos
                         ORDER  BY Position ASC)
         SET @error = @@error
			IF @error != 0 BEGIN
			   ROLLBACK TRANSACTION @tranName
			   COMMIT TRANSACTION
			   SET @msg = ''Error encountered while updating bar code pattern positions.'' + @msgTag + '';Error='' + cast(@error as nvarchar(10)) + ''>''
			   EXECUTE error$raise @msg, @error
			   RETURN -100
			END
      END
      -- Increment position
      SET @pos = @pos + 1
   END
	-- Synchronize the media with the bar code patterns
   EXECUTE barCodePattern$synchronize
END

-- Delete the account record
DELETE Account 
WHERE  AccountId = @id AND 
       RowVersion = @rowVersion

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

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'account$getCount')
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

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'account$getById')
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
FROM   Account a
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

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'account$getByName')
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
FROM   Account a
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

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'account$getTable')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.account$getTable
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
'
)

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'account$ins')
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

INSERT Account
(
   AccountName, 
   Global, 
   Address1, 
   Address2, 
   City, 
   State, 
   ZipCode, 
   Country, 
   Contact, 
   PhoneNo, 
   Email, 
   Notes
)
VALUES
(
   @name, 
   @global, 
   @address1, 
   @address2, 
   @city, 
   @state, 
   @zipCode, 
   @country, 
   @contact, 
   @phoneNo, 
   @email, 
   @notes
)

SET @error = @@error
IF @error != 0 BEGIN
   ROLLBACK TRANSACTION @tranName
   COMMIT TRANSACTION
   SET @msg = ''Error encountered while inserting new account.'' + @msgTag + '';Error'' + cast(@error as nvarchar(50)) + ''>''
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

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'account$upd')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.account$upd
(
   @id int,
   @name nvarchar(256),          -- name of the account
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

-- Update account
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

UPDATE Account
SET    AccountName = @name,
       Global = @global,
       Address1 = @address1,
       Address2 = @address2,
       City = @city,
       State = @state,
       ZipCode = @zipCode,
       Country = @country,
       Contact = @contact,
       PhoneNo = @phoneNo,
       Email = @email,
       Notes = @notes
WHERE  AccountId = @id AND
       RowVersion = @rowVersion

SELECT @error = @@error, @rowCount = @@rowcount

IF @error != 0 BEGIN
   ROLLBACK TRANSACTION @tranName
   COMMIT TRANSACTION
   SET @msg = ''Error encountered while updating account.'' + @msgTag + '';Error='' +  cast(@error as nvarchar(10)) + ''>''
   EXECUTE error$raise @msg, @error
   RETURN -100
END
ELSE IF @rowCount = 0 BEGIN
   IF EXISTS(SELECT 1 FROM Account WHERE AccountId = @id) BEGIN
      ROLLBACK TRANSACTION @tranName
      COMMIT TRANSACTION
      SET @msg = ''Account has been modified since retrieval.'' + @msgTag + ''>''
      EXECUTE error$raise @msg, 0
      RETURN -100
   END
   ELSE BEGIN
      ROLLBACK TRANSACTION @tranName
      COMMIT TRANSACTION
      SET @msg = ''Account record does not exist.'' + @msgTag + ''>''
      EXECUTE error$raise @msg, 0
      RETURN -100
   END
END

-- Commit the transaction
COMMIT TRANSACTION
RETURN 0

END
'
)

-------------------------------------------------------------------------------
--
-- Triggers - Account
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
WITH ENCRYPTION
AFTER  INSERT
AS
BEGIN
DECLARE @msg nvarchar(255)        -- used to preformat error message
DECLARE @msgTag nvarchar(255)     -- used to hold first part of error message header
DECLARE @tranName nvarchar(255)   -- used to hold name of savepoint
DECLARE @account nvarchar(256)    -- name of added account
DECLARE @rowCount int             -- holds the number of rows in the Inserted table
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

COMMIT TRANSACTION
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

-- Select the account name from the Deleted table
SELECT @account = accountName FROM Deleted
SET @msgUpdate = ''Account '' + @account + '' updated''

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
   IF EXISTS(SELECT 1 FROM SendList WHERE AccountId = @id AND Status IN (4, 16, 64, 256)) BEGIN -- power(4,x)
      SET @msg = ''This account may not be deleted because it is attached to an active send list.'' + @msgTag + ''>''
      EXECUTE error$raise @msg, 0, @tranName
      RETURN
   END
   IF EXISTS(SELECT 1 FROM ReceiveList WHERE AccountId = @id AND Status IN (4, 16, 64, 256)) BEGIN -- power(4,x)
      SET @msg = ''This account may not be deleted because it is attached to an active receive list.'' + @msgTag + ''>''
      EXECUTE error$raise @msg, 0, @tranName
      RETURN
   END
   IF EXISTS(SELECT 1 FROM DisasterCodeList WHERE AccountId = @id AND Status IN (4, 16)) BEGIN -- power(4,x)
      SET @msg = ''This account may not be deleted because it is attached to an active disaster code list.'' + @msgTag + ''>''
      EXECUTE error$raise @msg, 0, @tranName
      RETURN
   END
END

-- Add altered fields to audit message.  Certain fields may only
-- be altered by the system.
IF UPDATE(AccountName) BEGIN
   SELECT @del = AccountName FROM Deleted
   SELECT @ins = AccountName FROM Inserted
   IF @del != @ins SET @msgUpdate = @msgUpdate + '';Name='' + @ins
END
IF UPDATE(Global) BEGIN
   SELECT @del = CASE Global WHEN 1 THEN ''TRUE'' ELSE ''FALSE'' END FROM Deleted
   SELECT @ins = CASE Global WHEN 1 THEN ''TRUE'' ELSE ''FALSE'' END FROM Inserted
   IF @del != @ins SET @msgUpdate = @msgUpdate + '';Global='' + @ins
END
IF UPDATE(Address1) BEGIN
   SELECT @del = Address1 FROM Deleted
   SELECT @ins = Address1 FROM Inserted
   IF @del != @ins SET @msgUpdate = @msgUpdate + '';Address1='' + @ins
END
IF UPDATE(Address2) BEGIN
   SELECT @del = Address2 FROM Deleted
   SELECT @ins = Address2 FROM Inserted
   IF @del != @ins SET @msgUpdate = @msgUpdate + '';Address2='' + @ins
END
IF UPDATE(City) BEGIN
   SELECT @del = City FROM Deleted
   SELECT @ins = City FROM Inserted
   IF @del != @ins SET @msgUpdate = @msgUpdate + '';City='' + @ins
END
IF UPDATE(State) BEGIN
   SELECT @del = State FROM Deleted
   SELECT @ins = State FROM Inserted
   IF @del != @ins SET @msgUpdate = @msgUpdate + '';State='' + @ins
END
IF UPDATE(ZipCode) BEGIN
   SELECT @del = ZipCode FROM Deleted
   SELECT @ins = ZipCode FROM Inserted
   IF @del != @ins SET @msgUpdate = @msgUpdate + '';ZipCode='' + @ins
END
IF UPDATE(Country) BEGIN
   SELECT @del = Country FROM Deleted
   SELECT @ins = Country FROM Inserted
   IF @del != @ins SET @msgUpdate = @msgUpdate + '';Country='' + @ins
END
IF UPDATE(Contact) BEGIN
   SELECT @del = Contact FROM Deleted
   SELECT @ins = Contact FROM Inserted
   IF @del != @ins SET @msgUpdate = @msgUpdate + '';Contact='' + @ins
END
IF UPDATE(PhoneNo) BEGIN
   SELECT @del = PhoneNo FROM Deleted
   SELECT @ins = PhoneNo FROM Inserted
   IF @del != @ins SET @msgUpdate = @msgUpdate + '';Phone='' + @ins
END
IF UPDATE(Email) BEGIN
   SELECT @del = Email FROM Deleted
   SELECT @ins = Email FROM Inserted
   IF @del != @ins SET @msgUpdate = @msgUpdate + '';Email='' + @ins
END
IF UPDATE(Notes) BEGIN
   SELECT @del = Notes FROM Deleted
   SELECT @ins = Notes FROM Inserted
   IF @del != @ins SET @msgUpdate = @msgUpdate + '';Notes''
END

-- Insert audit record if at least one field has been modified.  We
-- can tell this if a semicolon appears after ''updated'' in the message.
IF CHARINDEX(''updated;'', @msgUpdate) > 0 BEGIN
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
      2, 
      @msgUpdate, 
      dbo.string$GetSpidLogin()
   )
   SET @error = @@error
   IF @error != 0 BEGIN
      SET @msg = ''Error encountered while inserting an account audit record.'' + @msgTag + '';Error='' + cast(@error as nvarchar(10)) + ''>''
      EXECUTE error$raise @msg, @error, @tranName
      RETURN
   END
END
ELSE IF EXISTS (SELECT 1 FROM Deleted d JOIN Inserted i ON i.AccountId = d.AccountId WHERE d.Deleted != i.Deleted) BEGIN
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
      3, 
      ''Account deleted'', 
      dbo.string$GetSpidLogin()
   )
   SET @error = @@error
   IF @error != 0 BEGIN
      SET @msg = ''Error encountered while inserting an account audit record.'' + @msgTag + '';Error='' + cast(@error as nvarchar(10)) + ''>''
      EXECUTE error$raise @msg, @error, @tranName
      RETURN
   END
END

COMMIT TRANSACTION
END
'
)

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
--
-- Stored Procedures - Bar Code Patterns
--
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'barCodePattern$getTable')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.barCodePattern$getTable
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
JOIN   MediumType m
  ON   m.TypeId = p.TypeId
JOIN   Account a
  ON   a.AccountId = p.AccountId
ORDER BY p.Position Asc

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
      substring(@nextPattern, 1, @pos1 - 1),
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

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'barCodePattern$updNotes')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.barCodePattern$updNotes
(
   @pattern nvarchar(256),
   @notes nvarchar(1000)
)
WITH ENCRYPTION
AS
BEGIN
DECLARE @msg nvarchar(255)        -- used to preformat error message
DECLARE @msgTag nvarchar(255)     -- used to hold first part of error message header
DECLARE @tranName nvarchar(255)   -- used to hold name of savepoint
DECLARE @rowCount int
DECLARE @error int

SET NOCOUNT ON

SET @notes = coalesce(@notes,'''')

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=P''
SET @tranName = object_name(@@procid) + CAST(@@nestlevel as nvarchar(2))

BEGIN TRANSACTION
SAVE TRANSACTION @tranName

UPDATE BarCodePattern
SET    Notes = @notes
WHERE  Pattern = @pattern
SELECT @error = @@error, @rowCount = @@rowCount
IF @error != 0 BEGIN
   ROLLBACK TRANSACTION @tranName
   COMMIT TRANSACTION
   SET @msg = ''Error encountered while updating medium bar code pattern.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
   RAISERROR(@msg, 16, 1)
   RETURN -100
END
ELSE IF @rowCount = 0 BEGIN
   ROLLBACK TRANSACTION @tranName
   COMMIT TRANSACTION
   SET @msg = ''Medium bar code pattern not found.'' + @msgTag + ''>''
   RAISERROR(@msg, 16, 1)
   RETURN -100
END

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
   INSERT XBarCodePattern
   (
      Detail,
      Login
   )
   VALUES
   (
      ''(Medium) Pattern='' + @pattern + '';MediumType='' + @mediumType + '';Account='' + @accountName,
      @login
   )
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

-- Dropped trigger so that barcodepattern$updNotes may update bar code patterns
IF EXISTS(SELECT * FROM sysobjects WHERE name = 'barCodePattern$afterUpdate' AND objectproperty(id, 'ExecIsUpdateTrigger' ) = 1) BEGIN
   EXECUTE ('DROP TRIGGER barCodePattern$afterUpdate')
END

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'barCodePatternCase$getTable')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.barCodePatternCase$getTable
WITH ENCRYPTION
AS
BEGIN

SET NOCOUNT ON

-- Select
SELECT p.Pattern,
       p.Notes,
       m.TypeName
FROM   BarCodePatternCase p
JOIN   MediumType m
  ON   m.TypeId = p.TypeId
ORDER BY p.Position Asc

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
      substring(@nextPattern, 1, @semi - 1),
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
DECLARE @msg nvarchar(255)        -- used to preformat error message
DECLARE @msgTag nvarchar(255)     -- used to hold first part of error message header
DECLARE @tranName nvarchar(255)   -- used to hold name of savepoint
DECLARE @serialNo nvarchar(64)
DECLARE @lastCase int
DECLARE @typeId int
DECLARE @error int

SET NOCOUNT ON

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=P''
SET @tranName = object_name(@@procid) + CAST(@@nestlevel as nvarchar(2))

-- Update all the sealed cases in the system to have the correct case types 
SET @lastCase = 0
WHILE 1 = 1 BEGIN
   SELECT TOP 1 @lastCase = c.CaseId,
          @serialNo = c.SerialNo
   FROM   SealedCase c -- WITH (READPAST)
   WHERE  c.CaseId > @lastCase AND
          c.TypeId != (SELECT TOP 1 p.TypeId
                       FROM   BarCodePatternCase p
                       WHERE  dbo.bit$RegexMatch(c.SerialNo, p.Pattern) = 1)
   ORDER  BY c.CaseId ASC
   IF @@rowCount = 0 BEGIN
      BREAK
   END
   ELSE BEGIN
      BEGIN TRANSACTION
      SAVE TRANSACTION @tranName
      -- Update to the correct case type
      SELECT TOP 1 @typeId = TypeId
      FROM   BarCodePatternCase
      WHERE  dbo.bit$RegexMatch(@serialNo, Pattern) = 1
      ORDER  BY Position Asc 
      -- If no pattern fits, then error.  Otherwise, update the medium.
      UPDATE SealedCase
      SET    TypeId = @typeId
      WHERE  CaseId = @lastCase
      SET @error = @@error
      IF @error != 0 BEGIN
         ROLLBACK TRANSACTION @tranName
         SET @msg = ''Error encountered while updating sealed case '''''' + @serialNo + ''''''.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
         EXECUTE error$raise @msg, @error
      END
      -- Commit the transaction
      COMMIT TRANSACTION
   END
END

-- Update all the send list cases in the system to have the correct types
SET @lastCase = 0
WHILE 1 = 1 BEGIN
   SELECT TOP 1 @lastCase = c.CaseId,
          @serialNo = c.SerialNo
   FROM   SendListCase c -- WITH (READPAST)
   WHERE  c.CaseId > @lastCase AND
          c.TypeId != (SELECT TOP 1 p.TypeId
                       FROM   BarCodePatternCase p
                       WHERE  dbo.bit$RegexMatch(c.SerialNo, p.Pattern) = 1)
   ORDER  BY c.CaseId ASC
   IF @@rowCount = 0 BEGIN
      BREAK
   END
   ELSE BEGIN
      BEGIN TRANSACTION
      SAVE TRANSACTION @tranName
      -- Update to the correct case type
      SELECT TOP 1 @typeId = TypeId
      FROM   BarCodePatternCase
      WHERE  dbo.bit$RegexMatch(@serialNo, Pattern) = 1
      ORDER  BY Position Asc 
      -- If no pattern fits, then error.  Otherwise, update the medium.
      UPDATE SendListCase
      SET    TypeId = @typeId
      WHERE  CaseId = @lastCase
      SET @error = @@error
      IF @error != 0 BEGIN
         ROLLBACK TRANSACTION @tranName
         SET @msg = ''Error encountered while updating send list case '''''' + @serialNo + ''''''.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
         EXECUTE error$raise @msg, @error
      END
      -- Commit the transaction
      COMMIT TRANSACTION
   END
END
END
'
)

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'barCodePatternCase$updNotes')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.barCodePatternCase$updNotes
(
   @pattern nvarchar(256),
   @notes nvarchar(1000)
)
WITH ENCRYPTION
AS
BEGIN
DECLARE @msg nvarchar(255)        -- used to preformat error message
DECLARE @msgTag nvarchar(255)     -- used to hold first part of error message header
DECLARE @tranName nvarchar(255)   -- used to hold name of savepoint
DECLARE @rowCount int
DECLARE @error int

SET NOCOUNT ON

SET @notes = coalesce(@notes,'''')

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=P''
SET @tranName = object_name(@@procid) + CAST(@@nestlevel as nvarchar(2))

BEGIN TRANSACTION
SAVE TRANSACTION @tranName

UPDATE BarCodePatternCase
SET    Notes = @notes
WHERE  Pattern = @pattern
SELECT @error = @@error, @rowCount = @@rowCount
IF @error != 0 BEGIN
   ROLLBACK TRANSACTION @tranName
   COMMIT TRANSACTION
   SET @msg = ''Error encountered while updating case bar code pattern.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
   RAISERROR(@msg, 16, 1)
   RETURN -100
END
ELSE IF @rowCount = 0 BEGIN
   ROLLBACK TRANSACTION @tranName
   COMMIT TRANSACTION
   SET @msg = ''Case bar code pattern not found.'' + @msgTag + ''>''
   RAISERROR(@msg, 16, 1)
   RETURN -100
END

COMMIT TRANSACTION
RETURN 0
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
   INSERT XBarCodePattern
   (
      Detail,
      Login
   )
   VALUES
   (
      ''(Case) Pattern='' + @pattern + '';MediumType='' + @mediumType,
      @login
   )
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


-- Dropped trigger so that barcodepatterncase$updNotes may update bar code patterns
IF EXISTS(SELECT * FROM sysobjects WHERE name = 'barCodePatternCase$afterUpdate' AND objectproperty(id, 'ExecIsUpdateTrigger' ) = 1) BEGIN
   EXECUTE ('DROP TRIGGER barCodePatternCase$afterUpdate')
END

-------------------------------------------------------------------------------
--
-- Stored Procedures - Subscription
--
-------------------------------------------------------------------------------
IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'subscription$get')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.subscription$get
WITH ENCRYPTION
AS
BEGIN

SET NOCOUNT ON

IF NOT EXISTS (SELECT 1 FROM Subscription)
   SELECT ''''
ELSE
   SELECT TOP 1 Number FROM Subscription	-- Should only be one, this makes sure

END
'
)

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'subscription$ins')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.subscription$ins
(
   @number nvarchar(40)
)
WITH ENCRYPTION
AS
BEGIN
DECLARE @msg nvarchar(255)        -- used to preformat error message
DECLARE @msgTag nvarchar(255)     -- used to hold first part of error message header
DECLARE @tranName nvarchar(255)   -- used to hold name of savepoint
DECLARE @detail nvarchar(255)
DECLARE @error int            

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=T''
SET @tranName = object_name(@@procid) + CAST(trigger_nestlevel(@@procid) as nvarchar(2))

-- Begin transaction
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

SET NOCOUNT ON

-- Delete all subscription rows, just in case
DELETE Subscription

-- Insert the subscription number
INSERT Subscription (Number) VALUES (@number)
SET @error = @@error
IF @error != 0 BEGIN
   ROLLBACK TRANSACTION @tranName
   COMMIT TRANSACTION
   SET @msg = ''Error encountered while inserting subscription number.'' + @msgTag + '';Error='' + cast(@error as nvarchar(10)) + ''>''
   EXECUTE error$raise @msg, @error
   RETURN -100
END

-- Insert an audit record
SELECT @detail = ''Subscription inserted: '' + @number
INSERT XSystemAction (Action, Detail) VALUES (1, @detail)
IF @error != 0 BEGIN
   ROLLBACK TRANSACTION @tranName
   COMMIT TRANSACTION
   SET @msg = ''Error encountered while inserting a system action (subscription insert) audit record.'' + @msgTag + '';Error='' + cast(@error as nvarchar(10)) + ''>''
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
-- Stored Procedures - Database version
--
-------------------------------------------------------------------------------
IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'databaseVersion$get')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.databaseVersion$get
WITH ENCRYPTION
AS
BEGIN

SET NOCOUNT ON

SELECT Major, 
       Minor,
       Revision
FROM   DatabaseVersion
ORDER BY Major Desc, Minor Desc, Revision Desc

END
'
)

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'databaseVersion$upd')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.databaseVersion$upd
(
   @major int,
   @minor int,
   @revision int,
   @installDate datetime
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
SET @installDate = cast(convert(nchar(19), getdate(), 120) as datetime)

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
	SELECT @installDate = cast(convert(nchar(19), @installDate, 120) as datetime)
	INSERT DatabaseVersion (Major, Minor, Revision)	VALUES (@major, @minor, @revision)
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

-------------------------------------------------------------------------------
--
-- Trigger - Database version
--
-------------------------------------------------------------------------------
IF EXISTS(SELECT * FROM sysobjects WHERE name = 'databaseVersion$afterInsert' AND objectproperty(id, 'ExecIsInsertTrigger' ) = 1) 
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'TRIGGER databaseVersion$afterInsert
ON     DatabaseVersion
WITH ENCRYPTION
AFTER  INSERT
AS
BEGIN
DECLARE @msg nvarchar(255)        -- used to preformat error message
DECLARE @msgTag nvarchar(255)     -- used to hold first part of error message header
DECLARE @tranName nvarchar(255)   -- used to hold name of savepoint
DECLARE @rowCount int             -- holds the number of rows in the Inserted table
DECLARE @major nvarchar(50)
DECLARE @minor nvarchar(50)
DECLARE @revision nvarchar(50)
DECLARE @ins nvarchar(4000)
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
   SET @msg = ''Batch insert into database version table not allowed.'' + @msgTag + ''>''
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
   SET @msg = ''Only the system may alter the database version.'' + @msgTag + ''>''
   EXECUTE error$raise @msg, 0, @tranName
   RETURN
END

-- Select the name of the new account from the Inserted table
SELECT @major = cast(Major as nvarchar(50)),
       @minor = cast(Minor as nvarchar(50)),
       @revision = cast(Revision as nvarchar(50))
FROM   Inserted

-- Insert audit record
INSERT XSystemAction
(
   Action, 
   Detail 
)
VALUES
(
   1, 
   ''Version='' + @major + ''.'' + @minor + ''.'' + @revision
)

SET @error = @@error
IF @error != 0 BEGIN
   SET @msg = ''Error encountered while inserting a system audit record.'' + @msgTag + '';Error='' + cast(@error as nvarchar(10)) + ''>''
   EXECUTE error$raise @msg, @error, @tranName
   RETURN
END

COMMIT TRANSACTION
END
'
)

-------------------------------------------------------------------------------
--
-- Stored Procedures - Disaster Code
--
-------------------------------------------------------------------------------
IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'disasterCode$del')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.disasterCode$del
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
DECLARE @rowCount as int
DECLARE @error as int

SET NOCOUNT ON

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=P''
SET @tranName = object_name(@@procid) + CAST(@@nestlevel as nvarchar(2))

-- Delete disaster code.  Medium disaster codes will be deleted on cascade.
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

DELETE DisasterCode
WHERE  CodeId = @id AND rowVersion = @rowVersion

SELECT @error = @@error, @rowCount = @@rowcount

IF @error != 0 BEGIN
   ROLLBACK TRANSACTION @tranName
   COMMIT TRANSACTION
   SET @msg = ''Error occurred deleting disaster code record.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
   EXECUTE error$raise @msg, @error
   RETURN -100
END
ELSE IF @rowCount = 0 BEGIN
   IF EXISTS(SELECT 1 FROM DisasterCode WHERE CodeId = @id) BEGIN
      ROLLBACK TRANSACTION @tranName
      COMMIT TRANSACTION
      SET @msg = ''Disaster code record has been modified since retrieval.'' + @msgTag + ''>''
      RAISERROR(@msg,16,1)
      RETURN -100
   END
   -- No notification if record does not exist.  It''s not a bad thing if
   -- we try to delete a record that does not exist.
END

COMMIT TRANSACTION
RETURN 0
END
'
)

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'disasterCode$ins')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.disasterCode$ins
(
   @code nvarchar(32),          -- disaster code
   @notes nvarchar(4000),       -- informational text about disaster code
   @codeId int output
)
WITH ENCRYPTION
AS
BEGIN
DECLARE @msg as nvarchar(255)        -- used to preformat error message
DECLARE @msgTag as nvarchar(255)     -- used to hold first part of error message header
DECLARE @tranName as nvarchar(255)   -- used to hold name of savepoint
DECLARE @error as int

SET NOCOUNT ON

-- Tweak parameters
SET @code = ltrim(rtrim(@code))
SET @notes = ltrim(rtrim(coalesce(@notes,'''')))

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=P''
SET @tranName = object_name(@@procid) + CAST(@@nestlevel as nvarchar(2))

BEGIN TRANSACTION
SAVE TRANSACTION @tranName

INSERT DisasterCode
(
   Code, 
   Notes
)
VALUES
(
   @code, 
   @notes
)

SET @error = @@error
IF @error != 0 BEGIN
   ROLLBACK TRANSACTION @tranName
   COMMIT TRANSACTION
   SET @msg = ''Error inserting a new row into the disaster code table.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
   EXECUTE error$raise @msg, @error
   RETURN -100
END

-- Scope identity keeps us from getting any triggered identity values
SET @codeId = scope_identity()
COMMIT TRANSACTION
RETURN 0
END
'
)

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'disasterCode$upd')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.disasterCode$upd
(
   @id int,
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
DECLARE @error as int

SET NOCOUNT ON

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=P''
SET @tranName = object_name(@@procid) + CAST(@@nestlevel as nvarchar(2))

-- Delete disaster code
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

UPDATE DisasterCode
SET    Code = @code,
       Notes = @notes
WHERE  CodeId = @id AND
       RowVersion = @rowVersion

SELECT @error = @@error, @rowCount = @@rowcount
       
IF @error != 0 BEGIN
   ROLLBACK TRANSACTION @tranName
   COMMIT TRANSACTION
   SET @msg = ''Error occurred updating disaster code record.'' + @msgTag + '';Error='' +  cast(@error as nvarchar(50)) + ''>''
   EXECUTE error$raise @msg, @error
   RETURN -100
END
ELSE IF @rowCount = 0 BEGIN
   IF EXISTS(SELECT 1 FROM DisasterCode WHERE CodeId = @id) BEGIN
      ROLLBACK TRANSACTION @tranName
      COMMIT TRANSACTION
      SET @msg = ''Disaster code record has been modified since retrieval.'' + @msgTag + ''>''
      RAISERROR(@msg,16,1)
      RETURN -100
   END
   ELSE BEGIN
      ROLLBACK TRANSACTION @tranName
      COMMIT TRANSACTION
      SET @msg = ''Disaster code record does not exist.'' + @msgTag + ''>''
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

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'disasterCodeCase$del')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.disasterCodeCase$del
(
   @codeId int,
   @caseId int
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

-- Delete sealed case
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

DELETE DisasterCodeCase
WHERE  CodeId = @codeId AND
       CaseId = @caseId
SELECT @error = @@error
       
IF @error != 0 BEGIN
   ROLLBACK TRANSACTION @tranName
   COMMIT TRANSACTION
   SET @msg = ''Error encountered while deleting disaster code case record.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
   EXECUTE error$raise @msg, @error
   RETURN -100
END

COMMIT TRANSACTION
RETURN 0
END
'
)

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'disasterCodeCase$ins')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.disasterCodeCase$ins
(
   @codeId int,
   @caseId int
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

-- Insert the case record
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

INSERT DisasterCodeCase
(
   CodeId, 
   CaseId
)
VALUES
(
   @codeId, 
   @caseId
)

SET @error = @@error
IF @error != 0 BEGIN
   ROLLBACK TRANSACTION @tranName
   COMMIT TRANSACTION
   SET @msg = ''Error inserting a new row into the disaster code case table.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
   EXECUTE error$raise @msg, @error
   RETURN -100
END

--Commit the transaction
COMMIT TRANSACTION
RETURN 0
END
'
)

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'disasterCodeMedium$del')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.disasterCodeMedium$del
(
   @codeId int,
   @mediumId int
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

-- Delete sealed case
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

DELETE DisasterCodeMedium
WHERE  CodeId = @codeId AND
       MediumId = @mediumId
SELECT @error = @@error
       
IF @error != 0 BEGIN
   ROLLBACK TRANSACTION @tranName
   COMMIT TRANSACTION
   SET @msg = ''Error occurred deleting medium disaster code record.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
   EXECUTE error$raise @msg, @error
   RETURN -100
END

COMMIT TRANSACTION
RETURN 0
END
'
)

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'disasterCodeMedium$ins')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.disasterCodeMedium$ins
(
   @codeId int,
   @mediumId int
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

-- Insert the case record
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

INSERT DisasterCodeMedium
(
   CodeId, 
   MediumId
)
VALUES
(
   @codeId, 
   @mediumId
)

SET @error = @@error
IF @error != 0 BEGIN
   ROLLBACK TRANSACTION @tranName
   COMMIT TRANSACTION
   SET @msg = ''Error inserting a new row into the disaster code medium table.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
   EXECUTE error$raise @msg, @error
   RETURN -100
END

--Commit the transaction
COMMIT TRANSACTION
RETURN 0
END
'
)

-------------------------------------------------------------------------------
--
-- Triggers - Disaster Code
--
-------------------------------------------------------------------------------
IF EXISTS(SELECT * FROM sysobjects WHERE name = 'disasterCodeCase$afterDelete' AND objectproperty(id, 'ExecIsDeleteTrigger' ) = 1) 
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'TRIGGER disasterCodeCase$afterDelete
ON     DisasterCodeCase
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
DECLARE @lastCase int
DECLARE @codeId int
DECLARE @error int

SET @rowCount = @@rowcount
IF @rowCount = 0 RETURN

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=T''
SET @tranName = object_name(@@procid) + CAST(trigger_nestlevel(@@procid) as nvarchar(2))

-- Begin transaction
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

-- Get the caller login from the spidLogin table
IF len(dbo.string$GetSpidLogin()) = 0 BEGIN
   SET @msg = ''Caller login not found in spid login table.'' + @msgTag + ''>''
   EXECUTE error$raise @msg, 0, @tranName
   RETURN
END

-- Insert audit record
SELECT @lastCase = 0
WHILE 1 = 1 BEGIN
   SELECT TOP 1 @lastCase = CaseId,
          @codeId = CodeId
   FROM   Deleted
   WHERE  CaseId > @lastCase
   ORDER BY CaseId
   IF @@rowCount = 0
      BREAK
   ELSE BEGIN
      SELECT @serialNo = SerialNo FROM SealedCase WHERE CaseId = @lastCase
      SELECT @codeName = Code FROM DisasterCode WHERE CodeId = @codeId
      -- Insert the audit record   
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
         2, 
         ''Disaster code '''''' + @codeName + '''''' unassigned'', 
         dbo.string$GetSpidLogin()
      )
      SET @error = @@error
      IF @error != 0 BEGIN
         SET @msg = ''Error encountered while inserting a row into the sealed case audit table.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
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

IF EXISTS(SELECT * FROM sysobjects WHERE name = 'disasterCodeCase$AfterInsert' AND objectproperty(id, 'ExecIsInsertTrigger' ) = 1) 
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'TRIGGER disasterCodeCase$AfterInsert
ON     DisasterCodeCase
WITH ENCRYPTION
AFTER  INSERT
AS
BEGIN
DECLARE @msg nvarchar(255)        -- used to preformat error message
DECLARE @msgTag nvarchar(255)     -- used to hold first part of error message header
DECLARE @tranName nvarchar(255)   -- used to hold name of savepoint
DECLARE @rowCount int            -- holds the number of rows in the Inserted table
DECLARE @serialNo nvarchar(32)
DECLARE @codeName nvarchar(32)
DECLARE @lastCase int
DECLARE @codeId int
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

SET @lastCase = 0
WHILE 1 = 1 BEGIN
   SELECT TOP 1 @lastCase = CaseId,
          @codeId = CodeId
   FROM   Inserted
   WHERE  CaseId > @lastCase
   ORDER BY CaseId
   IF @@rowCount = 0
      BREAK
   ELSE BEGIN
      SELECT @serialNo = SerialNo FROM SealedCase WHERE CaseId = @lastCase
      SELECT @codeName = Code FROM DisasterCode WHERE CodeId = @codeId
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
         2, 
         ''Disaster code '''''' + @codeName + '''''' assigned'',
         dbo.string$GetSpidLogin()
      )
      SET @error = @@error
      IF @error != 0 BEGIN
         SET @msg = ''Error inserting a row into the sealed case audit table.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
         EXECUTE error$raise @msg, @error, @tranName
         RETURN
      END
   END
END

-- Commit transaction
COMMIT TRANSACTION
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
   SELECT TOP 1 @lastMedium = MediumId,
          @codeId = CodeId
   FROM   Deleted
   WHERE  MediumId > @lastMedium
   ORDER BY MediumId
   IF @@rowCount = 0
      BREAK
   ELSE BEGIN
      SELECT @serialNo = SerialNo FROM Medium WHERE MediumId = @lastMedium
      SELECT @codeName = Code FROM DisasterCode WHERE CodeId = @codeId
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
         ''Disaster code '''''' + @codeName + '''''' unassigned'', 
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

IF EXISTS(SELECT * FROM sysobjects WHERE name = 'disasterCodeMedium$AfterInsert' AND objectproperty(id, 'ExecIsInsertTrigger' ) = 1) 
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'TRIGGER disasterCodeMedium$AfterInsert
ON     DisasterCodeMedium
WITH ENCRYPTION
AFTER  INSERT
AS
BEGIN
DECLARE @msg nvarchar(255)        -- used to preformat error message
DECLARE @msgTag nvarchar(255)     -- used to hold first part of error message header
DECLARE @tranName nvarchar(255)   -- used to hold name of savepoint
DECLARE @rowCount int            -- holds the number of rows in the Inserted table
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

-- Begin the transaction
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

-- Get the caller login from the spidLogin table
IF len(dbo.string$GetSpidLogin()) = 0 BEGIN
   SET @msg = ''Caller login not found in spid login table.'' + @msgTag + ''>''
   EXECUTE error$raise @msg, 0, @tranName
   RETURN
END

SET @lastMedium = 0
WHILE 1 = 1 BEGIN
   SELECT TOP 1 @lastMedium = MediumId,
          @codeId = CodeId
   FROM   Inserted
   WHERE  MediumId > @lastMedium
   ORDER BY MediumId
   IF @@rowCount = 0
      BREAK
   ELSE BEGIN
      SELECT @serialNo = SerialNo FROM Medium WHERE MediumId = @lastMedium
      SELECT @codeName = Code FROM DisasterCode WHERE CodeId = @codeId
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
         2, 
         ''Disaster code '''''' + @codeName + '''''' assigned'',
         dbo.string$GetSpidLogin()
      )
      SET @error = @@error
      IF @error != 0 BEGIN
         SET @msg = ''Error inserting a row into the medium audit table.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
         EXECUTE error$raise @msg, @error, @tranName
         RETURN
      END
   END
END

-- Commit transaction
COMMIT TRANSACTION
END
'
)

-------------------------------------------------------------------------------
--
-- Stored Procedures - External Sites
--
-------------------------------------------------------------------------------
IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'externalSiteLocation$del')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.externalSiteLocation$del
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
DECLARE @rowCount as int
DECLARE @error as int

SET NOCOUNT ON

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=P''
SET @tranName = object_name(@@procid) + CAST(@@nestlevel as nvarchar(2))

-- Delete record
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

DELETE ExternalSiteLocation
WHERE  SiteId = @id AND
       rowVersion = @rowVersion

SELECT @error = @@error, @rowCount = @@rowcount

IF @error != 0 BEGIN
   ROLLBACK TRANSACTION @tranName
   COMMIT TRANSACTION
   SET @msg = ''Error encountered while deleting external site.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
   EXECUTE error$raise @msg, @error
   RETURN -100
END
ELSE IF @rowCount = 0 BEGIN
   IF EXISTS(SELECT 1 FROM ExternalSiteLocation WHERE SiteId = @id) BEGIN
      ROLLBACK TRANSACTION @tranName
      COMMIT TRANSACTION
      SET @msg = ''External site has been modified since retrieval.'' + @msgTag + ''>''
      RAISERROR(@msg,16,1)
      RETURN -100
   END
   -- No notification if record does not exist.  It''s not a bad thing if
   -- we try to delete a record that does not exist.
END

COMMIT TRANSACTION
RETURN 0
END
'
)

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'externalSiteLocation$exists')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.externalSiteLocation$exists
(
   @siteName nvarchar(256)
)
WITH ENCRYPTION
AS
BEGIN

IF EXISTS
   (
   SELECT 1
   FROM   ExternalSiteLocation
   WHERE  SiteName = @siteName
   )
   SELECT 1
ELSE
   SELECT 0

END
'
)

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'externalSiteLocation$getById')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.externalSiteLocation$getById
(
   @id int
)
WITH ENCRYPTION
AS
BEGIN

SET NOCOUNT ON

-- Select
SELECT SiteId,
       siteName,
       Location,
       RowVersion
FROM   ExternalSiteLocation
WHERE  SiteId = @id

END
'
)

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'externalSiteLocation$getByName')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.externalSiteLocation$getByName
(
   @siteName nvarchar(256)
)
WITH ENCRYPTION
AS
BEGIN

SET NOCOUNT ON

-- Select
SELECT SiteId,
       SiteName,
       Location,
       RowVersion
FROM   ExternalSiteLocation
WHERE  SiteName = @siteName

END
'
)

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'externalSiteLocation$getTable')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.externalSiteLocation$getTable
WITH ENCRYPTION
AS
BEGIN

SET NOCOUNT ON

-- Select
SELECT SiteId,
       SiteName,
       Location,
       RowVersion
FROM   ExternalSiteLocation
ORDER BY SiteName Asc

END
'
)

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'externalSiteLocation$ins')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.externalSiteLocation$ins
(
   @siteName nvarchar(256),     -- name of the site
   @location bit,               -- enterprise (1) or vault (0)
   @newId int OUTPUT
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

BEGIN TRANSACTION
SAVE TRANSACTION @tranName

INSERT ExternalSiteLocation
(
   SiteName, 
   Location
)
VALUES
(
   @siteName, 
   @location
)

SET @error = @@error
IF @error != 0 BEGIN
   ROLLBACK TRANSACTION @tranName
   COMMIT TRANSACTION
   SET @msg = ''Error encountered while inserting a new external site.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
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

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'externalSiteLocation$upd')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.externalSiteLocation$upd
(
   @id int,
   @siteName nvarchar(256),
   @location bit,
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

-- Delete site
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

UPDATE ExternalSiteLocation
SET    SiteName = @siteName,
       Location = @location
WHERE  SiteId = @id AND
       RowVersion = @rowVersion

SELECT @error = @@error, @rowCount = @@rowcount

IF @error != 0 BEGIN
   ROLLBACK TRANSACTION @tranName
   COMMIT TRANSACTION
   SET @msg = ''Error encountered while updating external site.'' + @msgTag + '';Error='' +  cast(@error as nvarchar(50)) + ''>''
   EXECUTE error$raise @msg, @error
   RETURN -100
END
ELSE IF @rowCount = 0 BEGIN
   IF EXISTS(SELECT 1 FROM ExternalSiteLocation WHERE SiteId = @id) BEGIN
      ROLLBACK TRANSACTION @tranName
      COMMIT TRANSACTION
      SET @msg = ''External site record has been modified since retrieval.'' + @msgTag + ''>''
      RAISERROR(@msg,16,1)
      RETURN -100
   END
   ELSE BEGIN
      ROLLBACK TRANSACTION @tranName
      COMMIT TRANSACTION
      SET @msg = ''External site does not exist.'' + @msgTag + ''>''
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

-------------------------------------------------------------------------------
--
-- Triggers - External Site Locations
--
-------------------------------------------------------------------------------
IF EXISTS(SELECT * FROM sysobjects WHERE name = 'externalSiteLocation$afterDelete' AND objectproperty(id, 'ExecIsDeleteTrigger' ) = 1) 
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'TRIGGER externalSiteLocation$afterDelete
ON     ExternalSiteLocation
WITH ENCRYPTION
AFTER  DELETE
AS
BEGIN
DECLARE @msg nvarchar(255)        -- used to preformat error message
DECLARE @msgTag nvarchar(255)     -- used to hold first part of error message header
DECLARE @tranName nvarchar(255)   -- used to hold name of savepoint
DECLARE @siteName nvarchar(256)   -- holds the name of the deleted site
DECLARE @rowCount int            -- holds the number of rows in the Deleted table
DECLARE @error int          

SET @rowCount = @@rowcount
IF @rowCount = 0 RETURN

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=T''
SET @tranName = object_name(@@procid) + CAST(trigger_nestlevel(@@procid) as nvarchar(2))

-- Insert audit record
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

-- Make sure we do not have a batch delete
IF @rowCount > 1 BEGIN
   SET @msg = ''Batch delete from external site location table not allowed.'' + @msgTag + ''>''
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
SELECT @siteName = SiteName FROM Deleted

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
   3, 
   ''External site '' + @siteName + '' deleted'', 
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
SELECT @siteName = SiteName FROM Inserted

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
   ''External site '' + @siteName + '' created'', 
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
SELECT @siteName = SiteName FROM Deleted
SET @msgUpdate = ''External site '' + @siteName + '' updated''

-- Add altered fields to audit message
IF UPDATE(SiteName) BEGIN
   SELECT @del = SiteName FROM Deleted
   SELECT @ins = SiteName FROM Inserted
   IF @del != @ins SET @msgUpdate = @msgUpdate + '';Site='' + @ins
END
IF UPDATE(Location) BEGIN
   SELECT @del = CASE Location WHEN 1 THEN ''Enterprise'' ELSE ''Vault'' END FROM Deleted
   SELECT @ins = CASE Location WHEN 1 THEN ''Enterprise'' ELSE ''Vault'' END FROM Inserted
   IF @del != @ins SET @msgUpdate = @msgUpdate + '';Location='' + @ins
END

-- Insert audit record if at least one field has been modified.  We
-- can tell this if a semicolon appears after ''updated'' in the message.
IF CHARINDEX(''updated;'', @msgUpdate) > 0 BEGIN
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
      2, 
      @msgUpdate, 
      dbo.string$GetSpidLogin()
   )
   SET @error = @@error
   IF @error != 0 BEGIN
      SET @msg = ''Error encountered while inserting an external site audit record.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
      EXECUTE error$raise @msg, @error, @tranName
      RETURN
   END
END

COMMIT TRANSACTION
END
'
)

-------------------------------------------------------------------------------
--
-- Stored Procedures - Ignored Bar Code Patterns
--
-------------------------------------------------------------------------------
IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'ignoredBarCodePattern$del')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.ignoredBarCodePattern$del
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
DECLARE @rowCount as int
DECLARE @error as int

SET NOCOUNT ON

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=P''
SET @tranName = object_name(@@procid) + CAST(@@nestlevel as nvarchar(2))

-- Delete expression
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

DELETE IgnoredBarCodePattern
WHERE  Id = @id AND
       rowVersion = @rowVersion

SELECT @error = @@error, @rowCount = @@rowcount

IF @error != 0 BEGIN
   ROLLBACK TRANSACTION @tranName
   COMMIT TRANSACTION
   SET @msg = ''Error encountered while deleting ignored bar code pattern.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
   EXECUTE error$raise @msg, @error
   RETURN -100
END
ELSE IF @rowCount = 0 BEGIN
   IF EXISTS(SELECT 1 FROM IgnoredBarCodePattern WHERE Id = @id) BEGIN
      ROLLBACK TRANSACTION @tranName
      COMMIT TRANSACTION
      SET @msg = ''Ignored bar code pattern has been modified since retrieval.'' + @msgTag + ''>''
      RAISERROR(@msg,16,1)
      RETURN -100
   END
   -- No notification if record does not exist.  It''s not a bad thing if
   -- we try to delete a record that does not exist.
END

COMMIT TRANSACTION
RETURN 0
END
'
)

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'ignoredBarCodePattern$getById')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.ignoredBarCodePattern$getById
(
   @id int
)
WITH ENCRYPTION
AS
BEGIN

SET NOCOUNT ON

-- Select
SELECT Id,
       Pattern,
       Systems,
       Notes,
       RowVersion
FROM   IgnoredBarCodePattern
WHERE  Id = @id

END
'
)

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'ignoredBarCodePattern$getByPattern')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.ignoredBarCodePattern$getByPattern
(
   @pattern nvarchar(256)
)
WITH ENCRYPTION
AS
BEGIN

SET NOCOUNT ON

-- Select
SELECT Id,
       Pattern,
       Systems,
       Notes,
       RowVersion
FROM   IgnoredBarCodePattern
WHERE  Pattern = @pattern

END
'
)

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'ignoredBarCodePattern$getTable')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.ignoredBarCodePattern$getTable
WITH ENCRYPTION
AS
BEGIN

SET NOCOUNT ON

SELECT Id,
       Pattern,
       Systems,
       Notes,
       RowVersion
FROM   IgnoredBarCodePattern
ORDER BY Id Asc

END
'
)


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'ignoredBarCodePattern$ins')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.ignoredBarCodePattern$ins
(
   @pattern nvarchar(256),       -- expression string
   @systems binary(8),           -- programs to which the expression applies
   @notes nvarchar(1000),        -- random information about format
   @newId int OUTPUT             -- returns the id value for the newly created format
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

-- Insert new external serial expression
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

INSERT IgnoredBarCodePattern
(
   Pattern, 
   Systems, 
   Notes
)
VALUES
(
   @pattern, 
   @systems, 
   @notes
)

SET @error = @@error
IF @error != 0 BEGIN
   ROLLBACK TRANSACTION @tranName
   COMMIT TRANSACTION
   SET @msg = ''Error inserting a new ignored bar code pattern.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
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


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'ignoredBarCodePattern$upd')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.ignoredBarCodePattern$upd
(
   @id int,
   @pattern nvarchar(256),
   @systems binary(8),
   @notes nvarchar(4000),
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

BEGIN TRANSACTION
SAVE TRANSACTION @tranName

-- Perform the rest of the update
UPDATE IgnoredBarCodePattern
SET    Pattern = @pattern,
       Systems = @systems,
       Notes = @notes
WHERE  Id = @id AND
       RowVersion = @rowVersion

SET @error = @@error
IF @error != 0 BEGIN
   ROLLBACK TRANSACTION @tranName
   COMMIT TRANSACTION
   SET @msg = ''Error encountered while updating ignored bar code pattern.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
   EXECUTE error$raise @msg, @error
   RETURN -100
END
ELSE IF @rowCount = 0 BEGIN
   IF EXISTS(SELECT 1 FROM IgnoredBarCodePattern WHERE Id = @id) BEGIN
      ROLLBACK TRANSACTION @tranName
      COMMIT TRANSACTION
      SET @msg = ''Ignored bar code pattern has been modified since retrieval.'' + @msgTag + ''>''
      RAISERROR(@msg,16,1)
      RETURN -100
   END
   ELSE BEGIN
      ROLLBACK TRANSACTION @tranName
      COMMIT TRANSACTION
      SET @msg = ''Ignored bar code pattern does not exist.'' + @msgTag + ''>''
      RAISERROR(@msg,16,1)
      RETURN -100
   END
END

-- Commit the transaction and get the new rowVersion value
COMMIT TRANSACTION
RETURN 0
END
'
)

-------------------------------------------------------------------------------
--
-- Triggers - Ignored Bar Code Patterns
--
-------------------------------------------------------------------------------
IF EXISTS(SELECT * FROM sysobjects WHERE name = 'ignoredBarCodePattern$afterDelete' AND objectproperty(id, 'ExecIsDeleteTrigger' ) = 1) 
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'TRIGGER ignoredBarCodePattern$afterDelete
ON     IgnoredBarCodePattern
WITH ENCRYPTION
AFTER  DELETE
AS
BEGIN
DECLARE @msg nvarchar(255)        -- used to preformat error message
DECLARE @msgTag nvarchar(255)     -- used to hold first part of error message header
DECLARE @tranName nvarchar(255)   -- used to hold name of savepoint
DECLARE @pattern nvarchar(256)     -- holds the expression string
DECLARE @rowCount int            -- holds the number of rows in the Deleted table
DECLARE @error int          

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
   SET @msg = ''Batch delete from ignored bar code pattern table not allowed.'' + @msgTag + ''>''
   EXECUTE error$raise @msg, 0, @tranName
   RETURN
END

-- Get the caller login from the spidLogin table
IF len(dbo.string$GetSpidLogin()) = 0 BEGIN
   SET @msg = ''No login found for auditing purposes.'' + @msgTag + ''>''
   EXECUTE error$raise @msg, 0, @tranName
   RETURN
END

-- Select the expression string from the Deleted table
SELECT @pattern = Pattern FROM Deleted

-- Insert audit record
INSERT XIgnoredBarCodePattern
(
   Object,
   Action, 
   Detail, 
   Login
)
VALUES
(
   @pattern,
   3, 
   ''Ignored bar code pattern '''''' + @pattern + '''''' deleted'', 
   dbo.string$GetSpidLogin()
)

SET @error = @@error
IF @error != 0 BEGIN
   SET @msg = ''Error inserting an ignored bar code pattern audit record.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
   EXECUTE error$raise @msg, @error, @tranName
   RETURN
END

COMMIT TRANSACTION
END
'
)

IF EXISTS(SELECT * FROM sysobjects WHERE name = 'ignoredBarCodePattern$afterInsert' AND objectproperty(id, 'ExecIsInsertTrigger' ) = 1) 
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'TRIGGER ignoredBarCodePattern$afterInsert
ON     IgnoredBarCodePattern
WITH ENCRYPTION
AFTER  INSERT
AS
BEGIN
DECLARE @msg nvarchar(255)        -- used to preformat error message
DECLARE @msgTag nvarchar(255)     -- used to hold first part of error message header
DECLARE @tranName nvarchar(255)   -- used to hold name of savepoint
DECLARE @pattern nvarchar(256)     -- holds the expression string
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
   SET @msg = ''Batch insert into ignored bar code pattern table not allowed.'' + @msgTag + ''>''
   EXECUTE error$raise @msg, 0, @tranName
   RETURN
END

-- Get the caller login from the spidLogin table
IF len(dbo.string$GetSpidLogin()) = 0 BEGIN
   SET @msg = ''No login found for auditing purposes.'' + @msgTag + ''>''
   EXECUTE error$raise @msg, 0, @tranName
   RETURN
END

-- Select the new expression from the Inserted table
SELECT @pattern = Pattern FROM Inserted

-- Insert audit record
INSERT XIgnoredBarCodePattern
(
   Object, 
   Action, 
   Detail, 
   Login
)
VALUES
(
   @pattern, 
   1, 
   ''Ignored bar code pattern '''''' + @pattern + '''''' created'', 
   dbo.string$GetSpidLogin()
)

SET @error = @@error
IF @error != 0 BEGIN
   SET @msg = ''Error inserting an ignored bar code pattern audit record.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
   EXECUTE error$raise @msg, @error, @tranName
   RETURN
END

COMMIT TRANSACTION
END
'
)

IF EXISTS(SELECT * FROM sysobjects WHERE name = 'ignoredBarCodePattern$afterUpdate' AND objectproperty(id, 'ExecIsUpdateTrigger' ) = 1) 
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'TRIGGER ignoredBarCodePattern$afterUpdate
ON     IgnoredBarCodePattern
WITH ENCRYPTION
AFTER  UPDATE
AS
BEGIN
DECLARE @msg nvarchar(255)        -- used to preformat error message
DECLARE @msgTag nvarchar(255)     -- used to hold first part of error message header
DECLARE @msgUpdate nvarchar(4000) -- used to hold the updated fields
DECLARE @tranName nvarchar(255)   -- used to hold name of savepoint
DECLARE @pattern nvarchar(256)     -- holds the expression string
DECLARE @rowCount int            -- holds the number of rows in the Deleted table
DECLARE @ins nvarchar(4000)
DECLARE @del nvarchar(4000)
DECLARE @error int

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
   SET @msg = ''Batch update on ignored bar code pattern table not allowed.'' + @msgTag + ''>''
   EXECUTE error$raise @msg, 0, @tranName
   RETURN
END

-- Get the caller login from the spidLogin table
IF len(dbo.string$GetSpidLogin()) = 0 BEGIN
   SET @msg = ''Login not found for auditing purposes.'' + @msgTag + ''>''
   EXECUTE error$raise @msg, 0, @tranName
   RETURN
END

-- Select the expression from the Deleted table
SELECT @pattern = Pattern FROM Deleted
SET @msgUpdate = ''Ignored bar code pattern '''''' + @pattern + '''''' updated''

-- Add altered fields to audit message
IF UPDATE(Pattern) BEGIN
   SELECT @ins = Pattern 
   FROM   Inserted
   IF NOT EXISTS(SELECT 1 FROM Deleted WHERE Pattern = @ins) BEGIN
      SET @msgUpdate = @msgUpdate + '';Pattern='' + @ins
   END
END
IF UPDATE(Systems) BEGIN
   IF NOT EXISTS
      (
      SELECT 1 
      FROM   Deleted d
      JOIN   Inserted i
        ON   i.Systems = d.Systems
      )
   BEGIN
      SELECT @ins = cast(cast(Systems as bigint) as nvarchar(4000)) 
      FROM   Inserted
      SET @msgUpdate = @msgUpdate + '';Systems='' + @ins
   END
END
IF UPDATE(Notes) BEGIN
   IF NOT EXISTS
      (
      SELECT 1 
      FROM   Deleted
      WHERE  Notes = (SELECT Notes FROM Inserted)
      ) 
   BEGIN
      SET @msgUpdate = @msgUpdate + '';Notes''
   END
END

-- Insert audit record if at least one field has been modified.  We
-- can tell this if a semicolon appears after ''updated'' in the message.
IF CHARINDEX(''updated;'', @msgUpdate) > 0 BEGIN
   INSERT XIgnoredBarCodePattern
   (
      Object,
      Action, 
      Detail, 
      Login
   )
   VALUES
   (
      @pattern,
      2, 
      @msgUpdate, 
      dbo.string$GetSpidLogin()
   )
   SET @error = @@error
   IF @error != 0 BEGIN
      SET @msg = ''Error encountered while inserting an ignored bar code pattern audit record.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
      EXECUTE error$raise @msg, @error, @tranName
      RETURN
   END
END

COMMIT TRANSACTION
END
'
)

-------------------------------------------------------------------------------
--
-- Stored Procedures - Medium Sealed Case
--
-------------------------------------------------------------------------------
IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'mediumSealedCase$ins')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.mediumSealedCase$ins
(
   @caseId int,
   @mediumId int
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

-- Insert the case record
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

INSERT MediumSealedCase
(
   CaseId, 
   MediumId
)
VALUES
(
   @caseId, 
   @mediumId
)

SET @error = @@error
IF @error != 0 BEGIN
   ROLLBACK TRANSACTION @tranName
   COMMIT TRANSACTION
   SET @msg = ''Error inserting a new row into the sealed case medium table.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
   EXECUTE error$raise @msg, @error
   RETURN -100
END

--Commit the transaction
COMMIT TRANSACTION
RETURN 0
END
'
)

-------------------------------------------------------------------------------
--
-- Triggers - Medium Sealed Case
--
-------------------------------------------------------------------------------
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
            ''Medium '''''' + @lastSerial + '''''' removed from case'',
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
   ''Medium '''''' + @mediumSerial + '''''' inserted into case'',
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

-------------------------------------------------------------------------------
--
-- Stored Procedures - Medium Type
--
-------------------------------------------------------------------------------
IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'mediumType$del')
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
DECLARE @patternString as nvarchar(4000)
DECLARE @rowCount as int
DECLARE @patId as int
DECLARE @error as int
DECLARE @pos as int

SET NOCOUNT ON

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=P''
SET @tranName = object_name(@@procid) + CAST(@@nestlevel as nvarchar(2))

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

BEGIN TRANSACTION
SAVE TRANSACTION @tranName

-- Delete the bar code formats.  Note that we''re better off, in the middle layer,
-- adjusting the bar codes before deleting types.  The reason for this is because
-- if we are deleting more than one account, we are going to synchronize all the
-- media in the database, which is a lengthy process, more than once.
IF EXISTS(SELECT 1 FROM BarCodePattern WHERE TypeId = @id) BEGIN
   DELETE BarCodePattern WHERE TypeId = @id
   SET @error = @@error
   IF @error = 0 BEGIN
	   ROLLBACK TRANSACTION @tranName
	   COMMIT TRANSACTION
	   SET @msg = ''Error encountered while deleting bar code pattern.'' + @msgTag + '';Error='' + cast(@error as nvarchar(10)) + ''>''
	   EXECUTE error$raise @msg, @error
	   RETURN -100
   END
   -- Adjust positions of the remaining barcode patterns
   SELECT @pos = 1, 
          @rowCount = count(*) 
   FROM BarCodePattern
	WHILE @pos <= @rowCount BEGIN
      IF NOT EXISTS (SELECT 1 FROM BarCodePatternm WHERE Position = @pos) BEGIN
         UPDATE BarCodePattern
         SET    Position = @pos
         WHERE  PatId = (SELECT TOP 1 PatId 
                         FROM   BarCodePattern
                         WHERE  Position > @pos
                         ORDER  BY Position ASC)
         SET @error = @@error
			IF @error != 0 BEGIN
			   ROLLBACK TRANSACTION @tranName
			   COMMIT TRANSACTION
			   SET @msg = ''Error encountered while updating bar code pattern positions.'' + @msgTag + '';Error='' + cast(@error as nvarchar(10)) + ''>''
			   EXECUTE error$raise @msg, @error
			   RETURN -100
			END
      END
      -- Increment position
      SET @pos = @pos + 1
   END
	-- Synchronize the media with the bar code patterns
   EXECUTE barCodePattern$synchronize
END

-- Delete the bar code case formats.  Note that we''re better off, in the middle layer,
-- adjusting the bar codes before deleting types.  The reason for this is because
-- if we are deleting more than one type, we are going to synchronize all the
-- cases in the database, which is a lengthy process, more than once.
IF EXISTS(SELECT 1 FROM BarCodePatternCase WHERE TypeId = @id) BEGIN
   DELETE BarCodePatternCase WHERE TypeId = @id
   SET @error = @@error
   IF @error = 0 BEGIN
	   ROLLBACK TRANSACTION @tranName
	   COMMIT TRANSACTION
	   SET @msg = ''Error encountered while deleting case bar code pattern.'' + @msgTag + '';Error='' + cast(@error as nvarchar(10)) + ''>''
	   EXECUTE error$raise @msg, @error
	   RETURN -100
   END
   -- Adjust positions of the remaining barcode patterns
   SELECT @pos = 1, 
          @rowCount = count(*) 
   FROM   BarCodePatternCase
	WHILE @pos <= @rowCount BEGIN
      IF NOT EXISTS (SELECT 1 FROM BarCodePatternCase WHERE Position = @pos) BEGIN
         UPDATE BarCodePatternCase
         SET    Position = @pos
         WHERE  PatId = (SELECT TOP 1 PatId 
                         FROM   BarCodePatternCase
                         WHERE  Position > @pos
                         ORDER  BY Position ASC)
         SET @error = @@error
			IF @error != 0 BEGIN
			   ROLLBACK TRANSACTION @tranName
			   COMMIT TRANSACTION
			   SET @msg = ''Error encountered while updating case bar code pattern positions.'' + @msgTag + '';Error='' + cast(@error as nvarchar(10)) + ''>''
			   EXECUTE error$raise @msg, @error
			   RETURN -100
			END
      END
      -- Increment position
      SET @pos = @pos + 1
   END
	-- Synchronize the media with the bar code patterns
   EXECUTE barCodePatternCase$synchronize
END

-- Delete the medium type record.  There should be no media of this type left in the system, as
-- the bar code synchronization should have changed types on the fly.
DELETE FROM MediumType
WHERE  TypeId = @id AND
       RowVersion = @rowVersion

SELECT @error = @@error, @rowCount = @@rowcount

IF @error != 0 BEGIN
   ROLLBACK TRANSACTION @tranName
   COMMIT TRANSACTION
   SET @msg = ''Error encounterd while deleting medium type.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
   EXECUTE error$raise @msg, @error
   RETURN -100
END
ELSE IF @rowCount = 0 BEGIN
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

COMMIT TRANSACTION
RETURN 0
END
'
)

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'mediumType$getCount')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.mediumType$getCount
(
   @container bit
)
WITH ENCRYPTION
AS
BEGIN

SET NOCOUNT ON

SELECT count(*) 
FROM   MediumType
WHERE  Container = @container

END
'
)

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'mediumType$getById')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.mediumType$getById
(
   @id int
)
WITH ENCRYPTION
AS
BEGIN

SET NOCOUNT ON

-- Select
SELECT    m.TypeId,
          m.TypeName,
          m.TwoSided,
          m.Container,
          isnull(r.Code, '''') as ''Code'',
          m.RowVersion
FROM      MediumType m
LEFT JOIN RecallCode r
  ON      r.TypeId = m.TypeId
WHERE     m.TypeId = @id

END
'
)

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'mediumType$getByName')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.mediumType$getByName
(
   @name nvarchar(128)
)
WITH ENCRYPTION
AS
BEGIN

SET NOCOUNT ON

-- Select
SELECT    m.TypeId,
          m.TypeName,
          m.TwoSided,
          m.Container,
          isnull(r.Code, '''') as ''Code'',
          m.RowVersion
FROM      MediumType m
LEFT JOIN RecallCode r
  ON      r.TypeId = m.TypeId
WHERE     m.TypeName = @name

END
'
)

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'mediumType$getTableRecall')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.mediumType$getTableRecall
WITH ENCRYPTION
AS
BEGIN

SET NOCOUNT ON

-- Select
SELECT   m.TypeId,
         m.TypeName,
         m.TwoSided,
         m.Container,
         r.Code,
         m.RowVersion
FROM     MediumType m
JOIN     RecallCode r
  ON     r.TypeId = m.TypeId
ORDER BY m.TypeName ASC

END
'
)

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'mediumType$getTable')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.mediumType$getTable
(
   @vaultCode int = 1
)
WITH ENCRYPTION
AS
BEGIN
DECLARE @msg as nvarchar(255)        -- used to preformat error message
DECLARE @msgTag as nvarchar(255)     -- used to hold first part of error message header

SET NOCOUNT ON

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=P''

SET NOCOUNT ON

IF @vaultCode = 0 BEGIN
   SELECT    TypeId,
             TypeName,
             TwoSided,
             Container,
             '''' as ''Code'',
             RowVersion
   FROM      MediumType
   ORDER BY  TypeName ASC
END
IF @vaultCode = 1 BEGIN
   EXECUTE mediumType$getTableRecall
END
ELSE BEGIN
   SET @msg = ''Invalid vault code.'' + @msgTag + ''>''
   RAISERROR(@msg,16,1)
   RETURN -100
END

RETURN 0
END
'
)

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'mediumType$ins')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.mediumType$ins
(
   @name nvarchar(128),         -- name of the medium type
   @twoSided bit,               -- flag whether or not medium is two-sided
   @container bit,              -- flag whether or not type is a container
   @newId int = NULL OUT        -- returns the id value for the newly created medium type
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

INSERT MediumType
(
   TypeName, 
   TwoSided,
   Container
)
VALUES
(
   @name, 
   @twoSided,
   @container
)

SET @error = @@error
IF @error != 0 BEGIN
   ROLLBACK TRANSACTION @tranName
   COMMIT TRANSACTION
   SET @msg = ''Error encountered while inserting a new medium type.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
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

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'mediumType$upd')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.mediumType$upd
(
   @id int,
   @name nvarchar(128),
   @twoSided bit,
   @container bit,
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

-- Update the medium type, then the Recall code
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

UPDATE MediumType
SET    TypeName = @name,
       TwoSided = @twoSided,
       Container = @container
WHERE  TypeId = @id AND RowVersion = @rowVersion

SELECT @error = @@error, @rowCount = @@rowcount

IF @error != 0 BEGIN
   ROLLBACK TRANSACTION @tranName
   COMMIT TRANSACTION
   SET @msg = ''Error encountered while updating medium type.'' + @msgTag + '';Error='' +  cast(@error as nvarchar(50)) + ''>''
   EXECUTE error$raise @msg, @error
   RETURN -100
END
ELSE IF @rowCount = 0 BEGIN
   IF EXISTS(SELECT 1 FROM MediumType WHERE TypeId = @id) BEGIN
      ROLLBACK TRANSACTION @tranName
      COMMIT TRANSACTION
      SET @msg = ''Medium type has been modified since retrieval.'' + @msgTag + ''>''
      RAISERROR(@msg,16,1)
      RETURN -100
   END
   ELSE BEGIN
      ROLLBACK TRANSACTION @tranName
      COMMIT TRANSACTION
      SET @msg = ''Medium type does not exist.'' + @msgTag + ''>''
      RAISERROR(@msg,16,1)
      RETURN -100
   END
END

-- Commit the transaction and get the new rowVersion value
COMMIT TRANSACTION
RETURN 0
END
'
)

-------------------------------------------------------------------------------
--
-- Triggers - Medium Type
--
-------------------------------------------------------------------------------
IF EXISTS(SELECT * FROM sysobjects WHERE name = 'mediumType$afterDelete' AND objectproperty(id, 'ExecIsDeleteTrigger' ) = 1) 
   EXECUTE ('DROP TRIGGER mediumType$afterDelete')

IF EXISTS(SELECT * FROM sysobjects WHERE name = 'mediumType$afterInsert' AND objectproperty(id, 'ExecIsInsertTrigger' ) = 1) 
   EXECUTE ('DROP TRIGGER mediumType$afterInsert')

IF EXISTS(SELECT * FROM sysobjects WHERE name = 'mediumType$afterUpdate' AND objectproperty(id, 'ExecIsUpdateTrigger' ) = 1) 
   EXECUTE ('DROP TRIGGER mediumType$afterUpdate')

-------------------------------------------------------------------------------
--
-- Stored Procedures - Next List Number
--
-------------------------------------------------------------------------------
IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'nextListNumber$upd')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.nextListNumber$upd
(
   @listType char(2),
   @numeral int,
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

-- Update list number
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

UPDATE NextListNumber
SET    Numeral = @numeral
WHERE  ListType = @listType AND
       RowVersion = @rowVersion

SELECT @error = @@error, @rowCount = @@rowcount      

IF @error != 0 BEGIN
   ROLLBACK TRANSACTION @tranName
   COMMIT TRANSACTION
   SET @msg = ''Error occurred updating next list number record.'' + @msgTag + '';Error='' +  cast(@error as nvarchar(50)) + ''>''
   EXECUTE error$raise @msg, @error
   RETURN -100
END
ELSE IF @rowCount = 0 BEGIN
   IF EXISTS(SELECT 1 FROM NextListNumber WHERE ListType = @listType) BEGIN
      ROLLBACK TRANSACTION @tranName
      COMMIT TRANSACTION
      SET @msg = ''Next list number record has been modified since retrieval.'' + @msgTag + ''>''
      RAISERROR(@msg,16,1)
      RETURN -100
   END
   ELSE BEGIN
      ROLLBACK TRANSACTION @tranName
      COMMIT TRANSACTION
      SET @msg = ''Next list number record does not exist.'' + @msgTag + ''>''
      RAISERROR(@msg,16,1)
      RETURN -100
   END
END

COMMIT TRANSACTION
RETURN 0
END
'
)

-------------------------------------------------------------------------------
--
-- Stored Procedures - Operator
--
-------------------------------------------------------------------------------
IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'operator$del')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.operator$del
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
DECLARE @rowCount as int
DECLARE @error as int

SET NOCOUNT ON

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=P''
SET @tranName = object_name(@@procid) + CAST(@@nestlevel as nvarchar(2))

-- Make sure that the operator being deleted is not the operator
-- calling this procedure.  An operator cannot delete himself.
IF EXISTS
   (
   SELECT 1 
   FROM   SpidLogin sl
   JOIN   Operator op
   ON     sl.Login = op.OperatorName
   WHERE  sl.Spid = @@spid AND op.OperatorId = @id
   )
BEGIN
   SET @msg = ''You may not delete the operator under which you are currently logged in.'' + @msgTag + ''>''
   RAISERROR(@msg,16,1)
   RETURN -100
END

-- Delete operator
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

DELETE Operator
WHERE  OperatorId = @id AND
       rowVersion = @rowVersion

SELECT @error = @@error, @rowCount = @@rowcount

IF @error != 0 BEGIN
   ROLLBACK TRANSACTION @tranName
   COMMIT TRANSACTION
   SET @msg = ''Error encountered while deleting operator.'' + @msgTag + '';Error='' + cast(@error as nvarchar(10)) + ''>''
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
   -- No notification if operator does not exist.  It''s not a bad thing if
   -- we try to delete a record that does not exist.
END

COMMIT TRANSACTION
RETURN 0
END
'
)

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'operator$getCount')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.operator$getCount
WITH ENCRYPTION
AS
BEGIN

SET NOCOUNT ON

SELECT count(*) 
FROM   Operator

END
'
)

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
       RowVersion
FROM   Operator
ORDER BY
       Login asc

END
'
)

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'operator$ins')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.operator$ins
(
   @name nvarchar(256),          -- name of the operator
   @login nvarchar(32),          -- authentication login
   @password nvarchar(128),      -- hash of password
   @salt nvarchar(20),           -- salt value for password hash
   @role int,                    -- security role to which operator belongs
   @phoneNo nvarchar(64),        -- phone number where operator can be reached
   @email nvarchar(256),         -- email of operator
   @notes nvarchar(1000),        -- informational text about operator
   @newId int OUTPUT             -- returns the id value for the newly created operator
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

-- Insert operator
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

INSERT Operator
(
   OperatorName, 
   Login, 
   Password, 
   Salt, 
   Role, 
   PhoneNo, 
   Email, 
   Notes
)
VALUES
(
   @name, 
   @login, 
   @password, 
   @salt, 
   @role, 
   @phoneNo, 
   @email, 
   @notes
)

SET @error = @@error
IF @error != 0 BEGIN
   ROLLBACK TRANSACTION @tranName
   COMMIT TRANSACTION
   SET @msg = ''Error encountered while inserting a new operator.'' + @msgTag + '';Error='' + cast(@error as nvarchar(10)) + ''>''
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
       Notes = @notes
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

-------------------------------------------------------------------------------
--
-- Triggers - Operator
--
-------------------------------------------------------------------------------
IF EXISTS(SELECT * FROM sysobjects WHERE name = 'operator$afterDelete' AND objectproperty(id, 'ExecIsDeleteTrigger' ) = 1) 
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'TRIGGER operator$afterDelete
ON     Operator
WITH ENCRYPTION
AFTER  DELETE
AS
BEGIN
DECLARE @msg nvarchar(255)        -- used to preformat error message
DECLARE @msgTag nvarchar(255)     -- used to hold first part of error message header
DECLARE @tranName nvarchar(255)   -- used to hold name of savepoint
DECLARE @login nvarchar(32)       -- holds the name of the deleted operator  
DECLARE @rowCount int             -- holds the number of rows in the Deleted table
DECLARE @error int          
DECLARE @id int          

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
   SET @msg = ''Batch delete from operator table not allowed.'' + @msgTag + ''>''
   EXECUTE error$raise @msg, 0, @tranName
   RETURN
END

-- Get the caller login from the spidLogin table
IF len(dbo.string$GetSpidLogin()) = 0 BEGIN
   SET @msg = ''No login found for auditing purposes.'' + @msgTag + ''>''
   EXECUTE error$raise @msg, 0, @tranName
   RETURN
END

-- If the operator has an id of ''1'', then it may not be deleted.  This
-- is the administrator id that ships with the system.
SELECT @id = OperatorId 
FROM   Deleted
IF @id = 1 BEGIN
   SET @msg = ''This operator may not be deleted.'' + @msgTag +  ''>''
   EXECUTE error$raise @msg, 0, @tranName
   RETURN
END

-- Select the login of the operator from the Deleted table
SELECT @login = Login FROM Deleted

-- Insert audit record
INSERT XOperator
(
   Object, 
   Action, 
   Detail, 
   Login
)
VALUES
(
   @login, 
   3, 
   ''Operator '' + @login + '' deleted'', 
   dbo.string$GetSpidLogin()
)

SET @error = @@error
IF @error != 0 BEGIN
   SET @msg = ''Error inserting an operator audit record.'' + @msgTag + '';Error='' + cast(@error as nvarchar(10)) + ''>''
   EXECUTE error$raise @msg, @error, @tranName
   RETURN
END

COMMIT TRANSACTION
END
'
)

IF EXISTS(SELECT * FROM sysobjects WHERE name = 'operator$afterInsert' AND objectproperty(id, 'ExecIsInsertTrigger' ) = 1) 
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'TRIGGER operator$afterInsert
ON     Operator
WITH ENCRYPTION
AFTER  INSERT
AS
BEGIN
DECLARE @msg nvarchar(255)        -- used to preformat error message
DECLARE @msgTag nvarchar(255)     -- used to hold first part of error message header
DECLARE @tranName nvarchar(255)   -- used to hold name of savepoint
DECLARE @login nvarchar(32)       -- holds the name of the new operator login
DECLARE @rowCount int             -- holds the number of rows in the Inserted table
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
   SET @msg = ''Batch insert into operator table not allowed.'' + @msgTag + ''>''
   EXECUTE error$raise @msg, 0, @tranName
   RETURN
END

-- Get the caller login from the spidLogin table
IF len(dbo.string$GetSpidLogin()) = 0 BEGIN
   SET @msg = ''No login found for auditing purposes.'' + @msgTag + ''>''
   EXECUTE error$raise @msg, 0, @tranName
   RETURN
END

-- Get the login name
SELECT @login = Login FROM Inserted

-- Insert audit record
INSERT XOperator
(
   Object, 
   Action, 
   Detail, 
   Login
)
VALUES
(
   @login, 
   1, 
   ''Operator '' + @login + '' created'', 
   dbo.string$GetSpidLogin()
)

SET @error = @@error
IF @error != 0 BEGIN
   SET @msg = ''Error encountered while inserting an operator audit record.'' + @msgTag + '';Error='' + cast(@error as nvarchar(10)) + ''>''
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
DECLARE @del nvarchar(4000)
DECLARE @ins nvarchar(4000)
DECLARE @error int

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

-- Select the login of the operator from the Deleted table
SELECT @login = Login FROM Deleted
SET @msgUpdate = ''Operator '' + @login + '' updated''

-- Add altered fields to audit message
IF UPDATE(Login) BEGIN
   SELECT @del = Login FROM Deleted
   SELECT @ins = Login FROM Inserted
   IF @del != @ins SET @msgUpdate = @msgUpdate + '';Login='' + @ins
END
IF UPDATE(OperatorName) BEGIN
   SELECT @del = OperatorName FROM Deleted
   SELECT @ins = OperatorName FROM Inserted
   IF @del != @ins SET @msgUpdate = @msgUpdate + '';Name='' + @ins
END
IF UPDATE(Password) OR UPDATE(Salt) BEGIN
   SELECT @del = Password FROM Deleted
   SELECT @ins = Password FROM Inserted
   IF @del != @ins 
      SET @msgUpdate = @msgUpdate + '';Password''
   ELSE BEGIN
      SELECT @del = Salt FROM Deleted
      SELECT @ins = Salt FROM Inserted
      IF @del != @ins SET @msgUpdate = @msgUpdate + '';Password''
   END
END
IF UPDATE(Role) BEGIN
   SELECT @del = cast(Role as nvarchar(10)) FROM Deleted
   SELECT @ins = cast(Role as nvarchar(10)) FROM Inserted
   IF @del != @ins SET @msgUpdate = @msgUpdate + '';Role='' + @ins
END
IF UPDATE(PhoneNo) BEGIN
   SELECT @del = PhoneNo FROM Deleted
   SELECT @ins = PhoneNo FROM Inserted
   IF @del != @ins SET @msgUpdate = @msgUpdate + '';Phone='' + @ins
END
IF UPDATE(Email) BEGIN
   SELECT @del = Email FROM Deleted
   SELECT @ins = Email FROM Inserted
   IF @del != @ins SET @msgUpdate = @msgUpdate + '';Email='' + @ins
END
IF UPDATE(Notes) BEGIN
   SELECT @del = Notes FROM Deleted
   SELECT @ins = Notes FROM Inserted
   IF @del != @ins SET @msgUpdate = @msgUpdate + '';Notes''
END

-- Insert audit record if at least one field has been modified.  We
-- can tell this if a semicolon appears after ''updated'' in the message.
IF CHARINDEX(''updated;'', @msgUpdate) > 0 BEGIN
   INSERT XOperator
   (
      Object, 
      Action, 
      Detail, 
      Login
   )
   VALUES
   (
      @login, 
      2, 
      @msgUpdate, 
      dbo.string$GetSpidLogin()
   )

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

-------------------------------------------------------------------------------
--
-- Stored Procedures - Product License
--
-------------------------------------------------------------------------------
IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'productLicense$del')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.productLicense$del
(
   @id int
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

-- Delete license
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

DELETE ProductLicense
WHERE  TypeId = @id

SELECT @error = @@error

IF @error != 0 BEGIN
   ROLLBACK TRANSACTION @tranName
   COMMIT TRANSACTION
   SET @msg = ''Error occurred deleting product license record.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
   EXECUTE error$raise @msg, @error
   RETURN -100
END

COMMIT TRANSACTION
RETURN 0
END
'
)

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'productLicense$getById')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.productLicense$getById
(
   @id int
)
WITH ENCRYPTION
AS
BEGIN

SET NOCOUNT ON

SELECT TypeId,
       Value,
       Issued,
       Rayval
FROM   ProductLicense
WHERE  TypeId = @id

END
'
)

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'productLicense$getTable')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.productLicense$getTable
WITH ENCRYPTION
AS
BEGIN

SET NOCOUNT ON

SELECT TypeId,
       Value,
       Issued,
       Rayval
FROM   ProductLicense
ORDER BY TypeId

END
'
)

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'productLicense$ins')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.productLicense$ins
(
   @id int,
   @value nvarchar(256),
   @issued datetime,
   @rayval nvarchar(64)
)
WITH ENCRYPTION
AS
BEGIN
DECLARE @msg as nvarchar(255)      -- used to preformat error message
DECLARE @msgTag as nvarchar(255)    -- used to hold first part of error message header
DECLARE @tranName as nvarchar(255)   -- used to hold name of savepoint
DECLARE @error as int

SET NOCOUNT ON

-- Parameters
SET @value = coalesce(@value,'''')
SET @rayval = coalesce(@rayval,'''')

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=P''
SET @tranName = object_name(@@procid) + CAST(@@nestlevel as nvarchar(2))

BEGIN TRANSACTION
SAVE TRANSACTION @tranName

INSERT ProductLicense
(
   TypeId, 
   Value, 
   Issued, 
   Rayval
)
VALUES
(
   @id, 
   @value, 
   @issued, 
   @rayval
)

SET @error = @@error
IF @error != 0 BEGIN
   ROLLBACK TRANSACTION @tranName
   COMMIT TRANSACTION
   SET @msg = ''Error encountered while inserting new product license.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
   EXECUTE error$raise @msg, @error
   RETURN -100
END

COMMIT TRANSACTION
RETURN 0

END
'
)

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'productLicense$upd')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.productLicense$upd
(
   @id int,
   @value nvarchar(256),
   @issued datetime,
   @rayval nvarchar(64)
)
WITH ENCRYPTION
AS
BEGIN
DECLARE @msg as nvarchar(255)      -- used to preformat error message
DECLARE @msgTag as nvarchar(255)    -- used to hold first part of error message header
DECLARE @tranName as nvarchar(255)   -- used to hold name of savepoint
DECLARE @rowCount as int
DECLARE @error as int

SET NOCOUNT ON

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=P''
SET @tranName = object_name(@@procid) + CAST(@@nestlevel as nvarchar(2))

BEGIN TRANSACTION
SAVE TRANSACTION @tranName

UPDATE ProductLicense
SET    Value = @value,
       Issued = @issued,
       Rayval = @rayval
WHERE  TypeId = @id

SELECT @error = @@error, @rowCount = @@rowCount
IF @error != 0 BEGIN
   ROLLBACK TRANSACTION @tranName
   COMMIT TRANSACTION
   SET @msg = ''Error encountered while updating product license.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
   EXECUTE error$raise @msg, @error
   RETURN -100
END
ELSE IF @rowCount = 0 BEGIN
   ROLLBACK TRANSACTION @tranName
   COMMIT TRANSACTION
   SET @msg = ''Product license not found.'' + @msgTag + ''>''
   EXECUTE error$raise @msg, 0
   RETURN -100
END

COMMIT TRANSACTION
RETURN 0
END
'
)

-------------------------------------------------------------------------------
--
-- Triggers - Product License
--
-------------------------------------------------------------------------------
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
DECLARE @value nvarchar(256)
DECLARE @ray nvarchar(64)
DECLARE @error int            

SET @rowCount = @@rowcount
IF @rowCount = 0 RETURN

-- Make sure we do not have a batch insert
IF @rowCount > 1 BEGIN
   SET @msg = ''Batch insert into system action audit table not allowed.'' + @msgTag + ''>''
   EXECUTE error$raise @msg, 0
   RETURN
END

-- Make sure the type is not 6
SELECT @typeId = cast(TypeId as nvarchar(64)) FROM Inserted
IF @typeId = 6 RETURN

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
SELECT @typeId = cast(TypeId as nvarchar(64)),
       @value = Value,
       @issueDate = convert(nvarchar(10),Issued,120),
       @ray = RayVal
FROM   Inserted

-- Insert audit record
INSERT XSystemAction
(
   Action, 
   Detail
)
VALUES
(
   2, 
   ''License inserted;Type='' + @typeId + '';IssueDate='' + @issueDate
)

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
DECLARE @value nvarchar(256)
DECLARE @ray nvarchar(64)
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
SELECT TOP 1 @typeId = cast(TypeId as nvarchar(50)),
       @value = Value,
       @issueDate = convert(nvarchar(10),Issued,120),
       @ray = RayVal
FROM   Inserted

-- Insert audit record
INSERT XSystemAction
(
   Action, 
   Detail
)
VALUES
(
   3, 
   ''License updated;Type='' + @typeId + '';IssueDate='' + @issueDate
)

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

-------------------------------------------------------------------------------
--
-- Stored Procedures - Recall Codes
--
-------------------------------------------------------------------------------
IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'recallCode$ins')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.recallCode$ins
(
   @code nchar(2),              -- recall code
   @typeId int                  -- medium type to which code corresponds
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

INSERT RecallCode
(
   Code, 
   TypeId
)
VALUES
(
   @code, 
   @typeId
)

SET @error = @@error
IF @error != 0 BEGIN
   SET @msg = ''Error encountered while attaching a new Recall code.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
   EXECUTE error$raise @msg, @error, @tranName
   RETURN -100
END

COMMIT TRANSACTION
RETURN 0
END
'
)

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'recallCode$upd')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.recallCode$upd
(
   @code nchar(3),
   @typeId int

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

-- Update the medium type, then the Recall code
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

UPDATE RecallCode
SET    Code = @code
WHERE  TypeId = @typeId

SELECT @error = @@error, @rowCount = @@rowcount

IF @error != 0 BEGIN
   ROLLBACK TRANSACTION @tranName
   COMMIT TRANSACTION
   SET @msg = ''Error encountered while updating Recall code.'' + @msgTag + '';Error='' +  cast(@error as nvarchar(50)) + ''>''
   EXECUTE error$raise @msg, @error
   RETURN -100
END
ELSE IF @rowCount = 0 BEGIN
   ROLLBACK TRANSACTION @tranName
   COMMIT TRANSACTION
   SET @msg = ''Recall code does not exist.'' + @msgTag + ''>''
   RAISERROR(@msg,16,1)
   RETURN -100
END

-- Commit the transaction
COMMIT TRANSACTION
RETURN 0
END
'
)

-------------------------------------------------------------------------------
--
-- Triggers - Recall Codes
--
-------------------------------------------------------------------------------
IF EXISTS(SELECT * FROM sysobjects WHERE name = 'recallCode$afterDelete' AND objectproperty(id, 'ExecIsDeleteTrigger' ) = 1) 
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'TRIGGER recallCode$afterDelete
ON     RecallCode
WITH ENCRYPTION
AFTER  DELETE
AS
BEGIN

DECLARE @msg nvarchar(255)        -- used to preformat error message
DECLARE @tranName nvarchar(255)

IF @@rowCount = 0 RETURN

SET @tranName = object_name(@@procid) + CAST(@@nestlevel as nvarchar(2))

BEGIN TRANSACTION
SAVE TRANSACTION @tranName

-- Only the system may insert a medium type code
IF NOT EXISTS
   (
   SELECT 1 
   FROM   SpidLogin
   WHERE  Spid = @@spid AND Login = ''System''
   )
BEGIN
   SET @msg = ''Only the system may delete a medium type code.<'' + object_name(@@procid) + '';Type=T'' + ''>''
   EXECUTE error$raise @msg, 0, @tranName
   RETURN
END

COMMIT TRANSACTION
END
'
)

IF EXISTS(SELECT * FROM sysobjects WHERE name = 'recallCode$afterInsert' AND objectproperty(id, 'ExecIsInsertTrigger' ) = 1) 
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'TRIGGER recallCode$afterInsert
ON     RecallCode
WITH ENCRYPTION
AFTER  INSERT
AS
BEGIN

DECLARE @msg nvarchar(255)        -- used to preformat error message
DECLARE @tranName nvarchar(255)

SET @tranName = object_name(@@procid) + CAST(@@nestlevel as nvarchar(2))

BEGIN TRANSACTION
SAVE TRANSACTION @tranName

-- Only the system may insert a medium type code
IF NOT EXISTS
   (
   SELECT 1 
   FROM   SpidLogin
   WHERE  Spid = @@spid AND Login = ''System''
   )
BEGIN
   SET @msg = ''Only the system may insert a medium type code.<'' + object_name(@@procid) + '';Type=T'' + ''>''
   EXECUTE error$raise @msg, 0, @tranName
   RETURN
END

COMMIT TRANSACTION
END
'
)

IF EXISTS(SELECT * FROM sysobjects WHERE name = 'recallCode$afterUpdate' AND objectproperty(id, 'ExecIsUpdateTrigger' ) = 1) 
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'TRIGGER recallCode$afterUpdate
ON     RecallCode
WITH ENCRYPTION
AFTER  UPDATE
AS
BEGIN

DECLARE @msg nvarchar(255)        -- used to preformat error message
DECLARE @tranName nvarchar(255)

SET @tranName = object_name(@@procid) + CAST(@@nestlevel as nvarchar(2))

BEGIN TRANSACTION
SAVE TRANSACTION @tranName

-- Only the system may insert a medium type code
IF NOT EXISTS
   (
   SELECT 1 
   FROM   SpidLogin
   WHERE  Spid = @@spid AND Login = ''System''
   )
BEGIN
   SET @msg = ''Only the system may update a medium type code.<'' + object_name(@@procid) + '';Type=T'' + ''>''
   EXECUTE error$raise @msg, 0, @tranName
   RETURN
END

COMMIT TRANSACTION
END
'
)

-------------------------------------------------------------------------------
--
-- Stored Procedures - Sealed Case
--
-------------------------------------------------------------------------------
IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'sealedCase$del')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.sealedCase$del
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
DECLARE @rowCount as int
DECLARE @error as int

SET NOCOUNT ON

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=P''
SET @tranName = object_name(@@procid) + CAST(@@nestlevel as nvarchar(2))

-- Delete sealed case
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

DELETE SealedCase
WHERE  CaseId = @id AND
       rowVersion = @rowVersion
SELECT @error = @@error, @rowCount = @@rowcount
       
IF @error != 0 BEGIN
   ROLLBACK TRANSACTION @tranName
   COMMIT TRANSACTION
   SET @msg = ''Error occurred deleting sealed case record.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
   EXECUTE error$raise @msg, @error
   RETURN -100
END
ELSE IF @rowCount = 0 BEGIN
   IF EXISTS(SELECT 1 FROM SealedCase WHERE CaseId = @id) BEGIN
      ROLLBACK TRANSACTION @tranName
      COMMIT TRANSACTION
      SET @msg = ''Sealed case record has been modified since retrieval.'' + @msgTag + ''>''
      RAISERROR(@msg,16,1)
      RETURN -100
   END
   -- No notification if case does not exist.  It''s not a bad thing if
   -- we try to delete a record that does not exist.
END

COMMIT TRANSACTION
RETURN 0
END
'
)

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'sealedCase$getById')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.sealedCase$getById
(
   @caseId int
)
WITH ENCRYPTION
AS
BEGIN

SET NOCOUNT ON

SELECT s.CaseId,
       s.SerialNo,
       isnull(convert(nchar(10),s.ReturnDate,120),'''') as ''ReturnDate'',
       s.HotStatus,
       s.Notes,
       m.TypeName,
       s.RowVersion
FROM   SealedCase s
JOIN   MediumType m
  ON   s.TypeId = m.TypeId
WHERE  s.CaseId = @caseId

END
'
)

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'sealedCase$getByName')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.sealedCase$getByName
(
   @serialNo nvarchar(32)
)
WITH ENCRYPTION
AS
BEGIN

SET NOCOUNT ON

SELECT s.CaseId,
       s.SerialNo,
       isnull(convert(nchar(10),s.ReturnDate,120),'''') as ''ReturnDate'',
       s.HotStatus,
       s.Notes,
       m.TypeName,
       s.RowVersion
FROM   SealedCase s
JOIN   MediumType m
  ON   s.TypeId = m.TypeId
WHERE  s.SerialNo = @serialNo

END
'
)

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'sealedCase$getMedia')
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
FROM   Medium m 
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

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'sealedCase$getRecallCode')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.sealedCase$getRecallCode
(
   @serialNo nvarchar(32)
)
WITH ENCRYPTION
AS
BEGIN

SET NOCOUNT ON

SELECT rc.Code
FROM   RecallCode rc
JOIN   SealedCase sc
  ON   sc.TypeId = rc.TypeId
WHERE  sc.SerialNo = @serialNo

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
WHERE  rli.Status = 256 AND 
       sc.SerialNo = @caseName
ORDER BY m.SerialNo ASC

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
DECLARE @error as int

SET NOCOUNT ON

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=P''
SET @tranName = object_name(@@procid) + CAST(@@nestlevel as nvarchar(2))

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

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'sealedCase$upd')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.sealedCase$upd
(
   @id int,
   @serialNo nvarchar(32),      -- serial number of the case
   @returnDate datetime,        -- return date of the case from the vault
   @hotStatus bit,              -- hot status of the case
   @notes nvarchar(4000),       -- any random information about the case
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

-- Update the case
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

UPDATE SealedCase
SET    SerialNo = @serialNo,
       returnDate = @returnDate,
       HotStatus = @hotStatus,
       Notes = @notes
WHERE  CaseId = @id AND
       RowVersion = @rowVersion

SELECT @error = @@error, @rowCount = @@rowcount

IF @error != 0 BEGIN
   ROLLBACK TRANSACTION @tranName
   COMMIT TRANSACTION
   SET @msg = ''Error encountered while updating sealed case.'' + @msgTag + '';Error='' +  cast(@error as nvarchar(50)) + ''>''
   EXECUTE error$raise @msg, @error
   RETURN -100
END
ELSE IF @rowCount = 0 BEGIN
   IF EXISTS(SELECT 1 FROM SealedCase WHERE CaseId = @id) BEGIN
      ROLLBACK TRANSACTION @tranName
      COMMIT TRANSACTION
      SET @msg = ''Sealed case record has been modified since retrieval.'' + @msgTag + ''>''
      EXECUTE error$raise @msg, 0
      RETURN -100
   END
   ELSE BEGIN
      ROLLBACK TRANSACTION @tranName
      COMMIT TRANSACTION
      SET @msg = ''Sealed case record does not exist.'' + @msgTag + ''>''
      RAISERROR(@msg,16,1)
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
--
-- Triggers - Sealed Case
--
-------------------------------------------------------------------------------
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
   SET @msg = ''A medium with serial number '''''' + @serialNo + '''''' already exists.'' + @msgTag + ''>''
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
   ''Sealed case created;ReturnDate='' + @returnDate, 
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
      -- Initialize the update message
      SELECT @msgUpdate = ''Case '''''' + SerialNo + '''''' updated''
      FROM   Deleted
      -- Serial number
      IF EXISTS(SELECT 1 FROM Deleted WHERE CaseId = @caseId AND SerialNo != @lastSerial) BEGIN
         SET @msgUpdate = @msgUpdate + '';Name='' + @lastSerial
      END
      -- Case type
      IF EXISTS(SELECT 1 FROM Deleted WHERE CaseId = @caseId AND TypeId != @typeId) BEGIN
         SELECT @msgUpdate = @msgUpdate + '';CaseType='' + TypeName
         FROM   MediumType
         WHERE  TypeId = @typeId
      END
      -- Return date
      IF EXISTS(SELECT 1 FROM Deleted WHERE CaseId = @caseId AND coalesce(convert(nvarchar(10),ReturnDate,120),''NONE'') != @returnDate) BEGIN
         SET @msgUpdate = @msgUpdate + '';ReturnDate='' + @returnDate
      END
      -- Hot site status
      IF EXISTS(SELECT 1 FROM Deleted WHERE CaseId = @caseId AND hotStatus != @hotStatus) BEGIN
         IF @hotStatus = 1
            SET @msgUpdate = @msgUpdate + '';HotSite=TRUE''
         ELSE
            SET @msgUpdate = @msgUpdate + '';HotSite=FALSE''
      END
      -- Notes
      IF EXISTS(SELECT 1 FROM Deleted WHERE CaseId = @caseId AND Notes != @notes) BEGIN
         SET @msgUpdate = @msgUpdate + '';Notes''
      END
      -- Insert audit record if at least one field has been modified.  We
      -- can tell this if a semicolon appears after ''updated'' in the message.
      IF CHARINDEX(''updated;'', @msgUpdate) > 0 BEGIN
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
            2, 
            @msgUpdate, 
            dbo.string$GetSpidLogin()
         )
         SET @error = @@error
         IF @error != 0 BEGIN
            SET @msg = ''Error inserting a row into the sealed case audit table.'' + @msgTag + '';Error='' + cast(@error as nvarchar(9)) + ''>''
            EXECUTE error$raise @msg, @error, @tranName
            RETURN
         END
      END
      -- If the case serial number was changed, then we should delete any type 
      -- inventory discrepancies for the case and check to see if we have 
      -- resolved an unknown case discrepancy.
      IF charindex('';Name='',@msgUpdate) > 0 BEGIN
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
      IF charindex('';CaseType='',@msgUpdate) > 0 BEGIN
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
      IF charindex('';HotSite='',@msgUpdate) > 0 BEGIN
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

IF EXISTS(SELECT * FROM sysobjects WHERE name = 'sealedCase$afterDelete' AND objectproperty(id, 'ExecIsDeleteTrigger' ) = 1) 
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'TRIGGER sealedCase$afterDelete
ON     SealedCase
WITH ENCRYPTION
AFTER  DELETE
AS
BEGIN
DECLARE @msg nvarchar(255)         -- used to preformat error message
DECLARE @msgTag nvarchar(255)      -- used to hold first part of error message header
DECLARE @tranName nvarchar(255)    -- used to hold name of savepoint
DECLARE @lastSerial nvarchar(32)
DECLARE @error int

IF @@rowcount = 0 RETURN

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

-- Audit each deletion
SELECT @lastSerial = ''''
WHILE 1 = 1 BEGIN
   SELECT TOP 1 @lastSerial = SerialNo
   FROM   Deleted
   WHERE  SerialNo > @lastSerial
   ORDER BY SerialNo Asc
   IF @@rowCount = 0 BEGIN
      BREAK
   END
   ELSE BEGIN
      INSERT XSealedCase
      (
         Object, 
         Action, 
         Detail, 
         Login
      )
      VALUES
      (
         @lastSerial,
         3, 
         ''Sealed case deleted'',
         dbo.string$GetSpidLogin()
      )
      SET @error = @@error
      IF @error != 0 BEGIN
         SET @msg = ''Error inserting a row into the sealed case audit table.'' + @msgTag + '';Error='' + cast(@error as nvarchar(9)) + ''>''
         EXECUTE error$raise @msg, @error, @tranName
         RETURN
      END
   END
END

-- Commit transaction
COMMIT TRANSACTION
END
'
)

-------------------------------------------------------------------------------
--
-- Stored Procedures - Recall Tickets
--
-------------------------------------------------------------------------------
IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'recallTicket$del')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.recallTicket$del
(
   @login nvarchar(32)
) 
WITH ENCRYPTION
AS
BEGIN
DECLARE @tranName as nvarchar(255)   -- used to hold name of savepoint
DECLARE @error as int

SET NOCOUNT ON

-- Set up the transaction tag (nest level ensures uniqueness)
SET @tranName = object_name(@@procid) + CAST(@@nestlevel as nvarchar(2))

-- Begin the transaction
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

DELETE RecallTicket
WHERE  OperatorId = (SELECT OperatorId 
                     FROM   Operator 
                     WHERE  Login = @login)
SET @error = @@error
IF @error != 0 BEGIN
   ROLLBACK TRANSACTION @tranName
   COMMIT TRANSACTION
   RETURN -100
END

COMMIT TRANSACTION
RETURN 0
END
'
)

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'recallTicket$get')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.recallTicket$get
(
   @login nvarchar(32)
)
WITH ENCRYPTION
AS
BEGIN

SET NOCOUNT ON

SELECT t.Ticket
FROM   RecallTicket t
JOIN   Operator o
  ON   o.OperatorId = t.OperatorId
WHERE  o.Login = @login

END
'
)

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'recallTicket$ins')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.recallTicket$ins
(
   @login nvarchar(32),
   @ticket uniqueidentifier
)
WITH ENCRYPTION
AS
BEGIN
DECLARE @msg as nvarchar(255)        -- used to preformat error message
DECLARE @msgTag as nvarchar(255)     -- used to hold first part of error message header
DECLARE @tranName as nvarchar(255)   -- used to hold name of savepoint
DECLARE @operatorId int
DECLARE @error as int

SET NOCOUNT ON

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=P''
SET @tranName = object_name(@@procid) + CAST(@@nestlevel as nvarchar(2))

-- Get the operator id
SELECT @operatorId = OperatorId
FROM   Operator
WHERE  Login = @login
IF @@rowCount = 0 BEGIN
   SET @msg = ''Operator not found.'' + @msgTag + ''>''
   RAISERROR(@msg,16,1)
   RETURN -100
END

-- Begin the transaction
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

-- If the operator already exists, update the ticket
IF EXISTS(SELECT 1 FROM RecallTicket WHERE OperatorId = @operatorId) BEGIN
   UPDATE RecallTicket
   SET    Ticket = @ticket
   WHERE  OperatorId = @operatorId
END
ELSE BEGIN
   INSERT RecallTicket (OperatorId, Ticket)
   VALUES (@operatorId, @ticket)
END

SET @error = @@error
IF @error != 0 BEGIN
   ROLLBACK TRANSACTION @tranName
   COMMIT TRANSACTION
   SET @msg = ''Error encountered while inserting recall ticket.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
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
-- Stored Procedures -- Vault Discrepancies
--
-------------------------------------------------------------------------------
-- 2005-06-15 : vaultDiscrepancy$del no longer necessary; it merely deleted the
-- record of the vault discrepancy.  No checks or anything similar.  Delete
-- statements used instead, which facilitates batch deletes.
IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'vaultDiscrepancy$del')
   EXECUTE ('DROP PROCEDURE vaultDiscrepancy$del')

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'vaultDiscrepancy$getById')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.vaultDiscrepancy$getById
(
   @itemId as int
)
WITH ENCRYPTION
AS
BEGIN

SET NOCOUNT ON

SELECT v.ItemId,
       v.RecordedDate,
       s.SerialNo,
       s.Details,
       s.Type
FROM   VaultDiscrepancy v
JOIN  (SELECT v.ItemId, 
              v.SerialNo,
              case m.Location
                 when 1 then ''Vault claims residence of medium''
                 else ''Vault denies residence of medium''
              end as ''Details'',
              1 as ''Type''
       FROM   VaultDiscrepancyResidency v
       JOIN   Medium m
         ON   m.MediumId = v.MediumId
       UNION  
       SELECT ItemId, 
              SerialNo,
              ''Vault claims residence of locally unknown container'' as ''Details'',
              3 as ''Type''
       FROM   VaultDiscrepancyUnknownCase
       UNION
       SELECT v.ItemId, 
              v.SerialNo, 
              ''Vault asserts medium should be of type '''''' + mt.TypeName + '''''''' as ''Details'',
              2 as ''Type''
       FROM   VaultDiscrepancyMediumType v
       JOIN   MediumType mt
         ON   v.VaultType = mt.TypeId
       UNION
       SELECT v.ItemId, 
              v.SerialNo, 
              ''Vault asserts container should be of type '''''' + mt.TypeName + '''''''' as ''Details'',
              4 as ''Type''
       FROM   VaultDiscrepancyCaseType v
       JOIN   MediumType mt
         ON   v.VaultType = mt.TypeId
       UNION
       SELECT v.ItemId, 
              v.SerialNo, 
              ''Vault asserts medium should belong to account '''''' + a.AccountName + '''''''' as ''Details'',
              5 as ''Type''
       FROM   VaultDiscrepancyAccount v
       JOIN   Account a
         ON   v.VaultAccount = a.AccountId) as s
  ON   s.ItemId = v.ItemId
WHERE  v.ItemId = @ItemId

END
'
)

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'vaultDiscrepancy$getCount')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.vaultDiscrepancy$getCount
WITH ENCRYPTION
AS
BEGIN

SELECT count(*)
FROM   VaultDiscrepancy

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
SET @tables = ''VaultDiscrepancy v JOIN (SELECT v.ItemId, v.SerialNo, case m.Location when 1 then ''''Vault claims residence of medium'''' else ''''Vault denies residence of medium'''' end as ''''Details'''', 1 as ''''Type'''' FROM VaultDiscrepancyResidency v JOIN Medium m ON m.MediumId = v.MediumId UNION SELECT ItemId, SerialNo, ''''Vault claims residence of locally unknown container'''' as ''''Details'''', 3 as ''''Type'''' FROM VaultDiscrepancyUnknownCase UNION SELECT v.ItemId, v.SerialNo, ''''Vault asserts medium should be of type '''''''''''' + mt.TypeName + '''''''''''''''' as ''''Details'''', 2 as ''''Type'''' FROM VaultDiscrepancyMediumType v JOIN MediumType mt ON v.VaultType = mt.TypeId UNION SELECT v.ItemId, v.SerialNo, ''''Vault asserts container should be of type '''''''''''' + mt.TypeName + '''''''''''''''' as ''''Details'''', 4 as ''''Type'''' FROM VaultDiscrepancyCaseType v JOIN MediumType mt ON v.VaultType = mt.TypeId UNION SELECT v.ItemId, v.SerialNo, ''''Vault asserts medium should belong to account '''''''''''' + a.AccountName + '''''''''''''''' as ''''Details'''', 5 as ''''Type'''' FROM VaultDiscrepancyAccount v JOIN Account a ON v.VaultAccount = a.AccountId) as s ON s.ItemId = v.ItemId''

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

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'vaultDiscrepancy$getTable')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.vaultDiscrepancy$getTable
WITH ENCRYPTION
AS
BEGIN

SET NOCOUNT ON

SELECT v.ItemId,
       v.RecordedDate,
       s.SerialNo,
       s.Details,
       s.Type
FROM   VaultDiscrepancy v
JOIN  (SELECT v.ItemId, 
              v.SerialNo,
              case m.Location
                 when 1 then ''Vault claims residence of medium''
                 else ''Vault denies residence of medium''
              end as ''Details'',
              1 as ''Type''
       FROM   VaultDiscrepancyResidency v
       JOIN   Medium m
         ON   m.MediumId = v.MediumId
       UNION  
       SELECT ItemId, 
              SerialNo,
              ''Vault claims residence of locally unknown container'' as ''Details'',
              3 as ''Type''
       FROM   VaultDiscrepancyUnknownCase
       UNION
       SELECT v.ItemId, 
              v.SerialNo, 
              ''Vault asserts medium should be of type '''''' + mt.TypeName + '''''''' as ''Details'',
              2 as ''Type''
       FROM   VaultDiscrepancyMediumType v
       JOIN   MediumType mt
         ON   v.VaultType = mt.TypeId
       UNION
       SELECT v.ItemId, 
              v.SerialNo, 
              ''Vault asserts container should be of type '''''' + mt.TypeName + '''''''' as ''Details'',
              4 as ''Type''
       FROM   VaultDiscrepancyCaseType v
       JOIN   MediumType mt
         ON   v.VaultType = mt.TypeId
       UNION
       SELECT v.ItemId, 
              v.SerialNo, 
              ''Vault asserts medium should belong to account '''''' + a.AccountName + '''''''' as ''Details'',
              5 as ''Type''
       FROM   VaultDiscrepancyAccount v
       JOIN   Account a
         ON   v.VaultAccount = a.AccountId) as s
  ON   s.ItemId = v.ItemId
ORDER BY s.Type Asc, 
         v.RecordedDate Asc, 
         s.SerialNo Asc
END
'
)

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'vaultDiscrepancy$ignore')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.vaultDiscrepancy$ignore
(
   @itemId int
)
WITH ENCRYPTION
AS
BEGIN
DECLARE @msg as nvarchar(255)        -- used to preformat error 
DECLARE @msgTag as nvarchar(255)     -- used to hold first part of error message header
DECLARE @tranName as nvarchar(255)   -- used to hold name of savepoint
DECLARE @returnValue as int
DECLARE @error as int

SET NOCOUNT ON

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @returnValue = 0
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=P''
SET @tranName = object_name(@@procid) + CAST(@@nestlevel as nvarchar(2))

-- Begin transaction
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

-- Find the subcategory
IF EXISTS(SELECT 1 FROM VaultDiscrepancyResidency WHERE ItemId = @itemId)
   EXECUTE @returnValue = vaultDiscrepancyResidency$resolve @itemId, 3
ELSE IF EXISTS(SELECT 1 FROM VaultDiscrepancyMediumType WHERE ItemId = @itemId)
   EXECUTE @returnValue = vaultDiscrepancyMediumType$resolve @itemId, 2
ELSE IF EXISTS(SELECT 1 FROM VaultDiscrepancyUnknownCase WHERE ItemId = @itemId)
   EXECUTE @returnValue = vaultDiscrepancyUnknownCase$resolve @itemId, 3
ELSE IF EXISTS(SELECT 1 FROM VaultDiscrepancyCaseType WHERE ItemId = @itemId)
   EXECUTE @returnValue = vaultDiscrepancyCaseType$resolve @itemId, 2
ELSE IF EXISTS(SELECT 1 FROM VaultDiscrepancyAccount WHERE ItemId = @itemId)
   EXECUTE @returnValue = vaultDiscrepancyAccount$resolve @itemId, 2

-- Check the return value
IF @returnValue != 0 BEGIN
   ROLLBACK TRANSACTION @tranName
   COMMIT TRANSACTION
   RETURN -100
END
   
-- Commit and return
COMMIT TRANSACTION
RETURN 0
END
'
)

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'vaultDiscrepancy$upd')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.vaultDiscrepancy$upd
(
   @itemId int,
   @RecordedDate datetime
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

-- If the current discrepancy inventory date is greater than or equal to
-- the given inventory date, return zero.
IF NOT EXISTS
   (
   SELECT 1
   FROM   VaultDiscrepancy
   WHERE  ItemId = @itemId AND
          RecordedDate >= @recordedDate
   )
BEGIN
   -- Update 
   BEGIN TRANSACTION
   SAVE TRANSACTION @tranName
   
   UPDATE VaultDiscrepancy
   SET    RecordedDate = @recordedDate
   WHERE  ItemId = @itemId
   
   SELECT @error = @@error, @rowCount = @@rowcount
   
   IF @error != 0 BEGIN
      ROLLBACK TRANSACTION @tranName
      COMMIT TRANSACTION
      SET @msg = ''Error encountered while updating vault discrepancy.'' + @msgTag + '';Error='' +  cast(@error as nvarchar(50)) + ''>''
      EXECUTE error$raise @msg, @error
      RETURN -100
   END
   ELSE IF @rowCount = 0 BEGIN
      ROLLBACK TRANSACTION @tranName
      COMMIT TRANSACTION
      SET @msg = ''Vault discrepancy record does not exist.'' + @msgTag + ''>''
      RAISERROR(@msg,16,1)
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

-------------------------------------------------------------------------------
--
-- Triggers -- Vault Discrepancy
--
-------------------------------------------------------------------------------
IF EXISTS(SELECT * FROM sysobjects WHERE name = 'vaultDiscrepancyAccount$afterDelete' AND objectproperty(id, 'ExecIsDeleteTrigger' ) = 1) 
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'TRIGGER vaultDiscrepancyAccount$afterDelete
ON     VaultDiscrepancyAccount
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
DECLARE @mediumSerial nvarchar(32)
DECLARE @serialNo nvarchar(32)
DECLARE @lastItem int
DECLARE @rowCount int            -- holds the number of rows in the Deleted table
DECLARE @error int          

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
IF len(@login) = 0 BEGIN
   SET @msg = ''Caller login not found in spid login table.'' + @msgTag + ''>''
   EXECUTE error$raise @msg, 0, @tranName
   RETURN
END

-- Audit only if the vault discrepancy record still exists.  If it does not
-- exist, then the discrepancy was actively resolved.
SET @lastItem = 0
WHILE 1 = 1 BEGIN
   SELECT TOP 1 @lastItem = d.ItemId,
          @serialNo = d.SerialNo
   FROM   Deleted d
   JOIN   VaultDiscrepancy v
     ON   v.ItemId = d.ItemId
   WHERE  d.ItemId > @lastItem
   ORDER BY d.ItemId
   IF @@rowCount = 0
      BREAK
   ELSE BEGIN
      SELECT @mediumSerial = m.SerialNo
      FROM   Medium m 
      JOIN   Deleted d 
        ON   d.MediumId = m.MediumId
      IF @@rowCount = 0 
         SET @msgUpdate = ''Automatic removal of account discrepancy (medium deleted)''
      ELSE IF @mediumSerial != @serialNo
         SET @msgUpdate = ''Automatic removal of account discrepancy (serial number change)''
      ELSE
         SET @msgUpdate = ''Automatic removal of account discrepancy''
      INSERT XVaultDiscrepancy
      (
         Object, 
         Action, 
         Detail, 
         Login
      )
      VALUES
      (
         @serialNo, 
         3, 
         @msgUpdate, 
         @login
      )
      SET @error = @@error
      IF @error != 0 BEGIN
         SET @msg = ''Error inserting a row into vault discrepancy list audit table.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
         EXECUTE error$raise @msg, @error, @tranName
         RETURN
      END
   END
END

-- Delete the vault discrepancies if they exist
SET @lastItem = 0
WHILE 1 = 1 BEGIN
   SELECT TOP 1 @lastItem = ItemId
   FROM   Deleted
   WHERE  ItemId > @lastItem
   ORDER BY ItemId ASC
   IF @@rowCount = 0 BEGIN
      BREAK
   END
   ELSE BEGIN
      DELETE VaultDiscrepancy 
      WHERE  ItemId = @lastItem
      SET @error = @@error
      IF @error != 0 BEGIN
         SET @msg = ''Error encountered while deleting vault discrepancies.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
         EXECUTE error$raise @msg, @error, @tranName
         RETURN
      END
   END
END

-- Commit transaction
COMMIT TRANSACTION
END
'
)

IF EXISTS(SELECT * FROM sysobjects WHERE name = 'vaultDiscrepancyCaseType$afterDelete' AND objectproperty(id, 'ExecIsDeleteTrigger' ) = 1) 
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'TRIGGER vaultDiscrepancyCaseType$afterDelete
ON     VaultDiscrepancyCaseType
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
DECLARE @caseName nvarchar(32)
DECLARE @auditAction int
DECLARE @lastItem int
DECLARE @rowCount int            -- holds the number of rows in the Deleted table
DECLARE @error int          

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
IF len(@login) = 0 BEGIN
   SET @msg = ''Caller login not found in spid login table.'' + @msgTag + ''>''
   EXECUTE error$raise @msg, 0, @tranName
   RETURN
END

-- Delete the vault discrepancies if they exist
SET @lastItem = 0
WHILE 1 = 1 BEGIN
   SELECT TOP 1 @lastItem = ItemId
   FROM   Deleted
   WHERE  ItemId > @lastItem
   ORDER BY ItemId ASC
   IF @@rowCount = 0 BEGIN
      BREAK
   END
   ELSE BEGIN
      DELETE VaultDiscrepancy 
      WHERE  ItemId = @lastItem
      SET @error = @@error
      IF @error != 0 BEGIN
         SET @msg = ''Error encountered while deleting vault discrepancies.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
         EXECUTE error$raise @msg, @error, @tranName
         RETURN
      END
   END
END

SET @lastItem = 0
WHILE 1 = 1 BEGIN
   SELECT TOP 1 @lastItem = d.ItemId,
          @caseName = coalesce(sc.SerialNo,''<case deleted>'')
   FROM   Deleted d
   LEFT OUTER JOIN SealedCase sc
     ON   sc.CaseId = d.CaseId
   WHERE  d.ItemId > @lastItem
   ORDER BY d.ItemId
   IF @@rowCount = 0
      BREAK
   ELSE BEGIN
      IF charindex(''ignore'',@tagInfo) > 0 BEGIN
         SET @msgUpdate = ''Case type vault inventory discrepancy ignored''
         SET @auditAction = 6
      END
      ELSE BEGIN
         SET @msgUpdate = ''Case type vault inventory discrepancy resolved''
         SET @auditAction = 7
      END
      INSERT XVaultDiscrepancy
      (
         Object, 
         Action, 
         Detail, 
         Login
      )
      VALUES
      (
         @caseName, 
         @auditAction, 
         @msgUpdate, 
         @login
      )
      SET @error = @@error
      IF @error != 0 BEGIN
         SET @msg = ''Error inserting a row into vault discrepancy list audit table.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
         EXECUTE error$raise @msg, @error, @tranName
         RETURN
      END
   END
END

COMMIT TRANSACTION
END
'
)

IF EXISTS(SELECT * FROM sysobjects WHERE name = 'vaultDiscrepancyMediumType$afterDelete' AND objectproperty(id, 'ExecIsDeleteTrigger' ) = 1) 
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'TRIGGER vaultDiscrepancyMediumType$afterDelete
ON     VaultDiscrepancyMediumType
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
DECLARE @mediumSerial nvarchar(32)
DECLARE @serialNo nvarchar(32)
DECLARE @lastItem int
DECLARE @rowCount int            -- holds the number of rows in the Deleted table
DECLARE @error int          

SET @rowCount = @@rowcount
IF @rowCount = 0 RETURN

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=T''
SET @tranName = object_name(@@procid) + CAST(trigger_nestlevel(@@procid) as nvarchar(2))

-- Begin transaction
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

-- Get the spid info
SELECT @login = dbo.string$GetSpidLogin()
SELECT @tagInfo = dbo.string$GetSpidInfo()

-- Get the caller login from the spidLogin table
IF len(@login) = 0 BEGIN
   SET @msg = ''Caller login not found in spid login table.'' + @msgTag + ''>''
   EXECUTE error$raise @msg, 0, @tranName
   RETURN
END

-- Audit only if the vault discrepancy record still exists.  If it does not
-- exist, then the discrepancy was actively resolved.
SET @lastItem = 0
WHILE 1 = 1 BEGIN
   SELECT TOP 1 @lastItem = d.ItemId,
          @serialNo = d.SerialNo
   FROM   Deleted d
   JOIN   VaultDiscrepancy v
     ON   v.ItemId = d.ItemId
   WHERE  d.ItemId > @lastItem
   ORDER BY d.ItemId
   IF @@rowCount = 0
      BREAK
   ELSE BEGIN
      SELECT @mediumSerial = m.SerialNo 
      FROM   Medium m 
      JOIN   Deleted d 
        ON   d.MediumId = m.MediumId
      IF @@rowCount = 0 
         SET @msgUpdate = ''Automatic removal of residency discrepancy (medium deleted)''
      ELSE IF @mediumSerial != @serialNo
         SET @msgUpdate = ''Automatic removal of residency discrepancy (serial number change)''
      ELSE
         SET @msgUpdate = ''Automatic removal of residency discrepancy''
      INSERT XVaultDiscrepancy
      (
         Object, 
         Action, 
         Detail, 
         Login
      )
      VALUES
      (
         @serialNo, 
         3, 
         @msgUpdate, 
         @login
      )
      SET @error = @@error
      IF @error != 0 BEGIN
         SET @msg = ''Error inserting a row into vault discrepancy list audit table.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
         EXECUTE error$raise @msg, @error, @tranName
         RETURN
      END
   END
END

-- Delete the vault discrepancies if they exist
SET @lastItem = 0
WHILE 1 = 1 BEGIN
   SELECT TOP 1 @lastItem = ItemId
   FROM   Deleted
   WHERE  ItemId > @lastItem
   ORDER BY ItemId ASC
   IF @@rowCount = 0 BEGIN
      BREAK
   END
   ELSE BEGIN
      DELETE VaultDiscrepancy 
      WHERE  ItemId = @lastItem
      SET @error = @@error
      IF @error != 0 BEGIN
         SET @msg = ''Error encountered while deleting vault discrepancies.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
         EXECUTE error$raise @msg, @error, @tranName
         RETURN
      END
   END
END

-- Commit transaction
COMMIT TRANSACTION
END
'
)

IF EXISTS(SELECT * FROM sysobjects WHERE name = 'vaultDiscrepancyResidency$afterDelete' AND objectproperty(id, 'ExecIsDeleteTrigger' ) = 1) 
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'TRIGGER vaultDiscrepancyResidency$afterDelete
ON     VaultDiscrepancyResidency
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
DECLARE @mediumSerial nvarchar(32)
DECLARE @serialNo nvarchar(32)
DECLARE @lastItem int
DECLARE @rowCount int            -- holds the number of rows in the Deleted table
DECLARE @error int          

SET @rowCount = @@rowcount
IF @rowCount = 0 RETURN

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=T''
SET @tranName = object_name(@@procid) + CAST(trigger_nestlevel(@@procid) as nvarchar(2))

-- Begin transaction
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

-- Get the spid info
SELECT @login = dbo.string$GetSpidLogin()

-- Get the caller login from the spidLogin table
IF len(@login) = 0 BEGIN
   SET @msg = ''Caller login not found in spid login table.'' + @msgTag + ''>''
   EXECUTE error$raise @msg, 0, @tranName
   RETURN
END

-- Audit only if the vault discrepancy record still exists.  If it does not
-- exist, then the discrepancy was actively resolved.
SET @lastItem = 0
WHILE 1 = 1 BEGIN
   SELECT TOP 1 @lastItem = d.ItemId,
          @serialNo = d.SerialNo
   FROM   Deleted d
   JOIN   VaultDiscrepancy v
     ON   v.ItemId = d.ItemId
   WHERE  d.ItemId > @lastItem
   ORDER BY d.ItemId
   IF @@rowCount = 0
      BREAK
   ELSE BEGIN
      SELECT @mediumSerial = m.SerialNo 
      FROM   Medium m 
      JOIN   Deleted d 
        ON   d.MediumId = m.MediumId
      IF @@rowCount = 0 
         SET @msgUpdate = ''Automatic removal of residency discrepancy (medium deleted)''
      ELSE IF @mediumSerial != @serialNo
         SET @msgUpdate = ''Automatic removal of residency discrepancy (serial number change)''
      ELSE
         SET @msgUpdate = ''Automatic removal of residency discrepancy''
      INSERT XVaultDiscrepancy
      (
         Object, 
         Action, 
         Detail, 
         Login
      )
      VALUES
      (
         @serialNo, 
         3, 
         @msgUpdate, 
         @login
      )
      SET @error = @@error
      IF @error != 0 BEGIN
         SET @msg = ''Error inserting a row into vault discrepancy list audit table.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
         EXECUTE error$raise @msg, @error, @tranName
         RETURN
      END
   END
END

-- Delete the vault discrepancies if they exist
SET @lastItem = 0
WHILE 1 = 1 BEGIN
   SELECT TOP 1 @lastItem = ItemId
   FROM   Deleted
   WHERE  ItemId > @lastItem
   ORDER BY ItemId ASC
   IF @@rowCount = 0 BEGIN
      BREAK
   END
   ELSE BEGIN
      DELETE VaultDiscrepancy 
      WHERE  ItemId = @lastItem
      SET @error = @@error
      IF @error != 0 BEGIN
         SET @msg = ''Error encountered while deleting vault discrepancies.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
         EXECUTE error$raise @msg, @error, @tranName
         RETURN
      END
   END
END

-- Commit transaction
COMMIT TRANSACTION
END
'
)

-------------------------------------------------------------------------------
--
-- Stored Procedures -- Vault Inventory
--
-------------------------------------------------------------------------------
IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'vaultInventory$removeReconciled')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.vaultInventory$removeReconciled
WITH ENCRYPTION
AS
BEGIN
DECLARE @msg nvarchar(255)        -- used to preformat error message
DECLARE @msgTag nvarchar(255)     -- used to hold first part of error message header
DECLARE @tranName nvarchar(255)   -- used to hold name of savepoint
DECLARE @error int

SET NOCOUNT ON

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=P''
SET @tranName = object_name(@@procid) + CAST(@@nestlevel as nvarchar(2))

-- Begin the transaction
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

-- Remove media residency discrepancies that are now resolved
DELETE FROM VaultDiscrepancy
WHERE  ItemId IN (SELECT vdr.ItemId
                  FROM   VaultDiscrepancyResidency vdr
                  JOIN   Medium m
                    ON   vdr.SerialNo = m.SerialNo
                  JOIN   VaultInventoryItem vii
                    ON   vdr.SerialNo = vii.SerialNo
                  WHERE  m.Location = 0
                  UNION
                  SELECT vdr.ItemId
                  FROM   VaultDiscrepancyResidency vdr
                  JOIN   Medium m
                    ON   m.SerialNo = vdr.SerialNo
                  JOIN   MediumSealedCase msc
                    ON   msc.MediumId = m.MediumId
                  JOIN   SealedCase sc
                    ON   sc.CaseId = msc.CaseId
                  JOIN   VaultInventoryItem vii
                    ON   sc.SerialNo = vii.SerialNo
                  WHERE  m.Location = 0 				-- superfluous (sealed cases by definition are at the vault; therefore media in sealed cases must be at vault)
                  UNION
                  SELECT vdr.ItemId
                  FROM   VaultDiscrepancyResidency vdr
                  JOIN   Medium m
                    ON   vdr.SerialNo = m.SerialNo
                  LEFT OUTER JOIN VaultInventoryItem vii
                    ON   vdr.SerialNo = vii.SerialNo
                  WHERE  m.Location = 1 AND 
                         vii.SerialNo IS NULL)                          -- no need to deal with cases, since tapes at the enterprise cannot be in cases
SET @error = @@error
IF @error != 0 BEGIN
   ROLLBACK TRANSACTION @tranName
   COMMIT TRANSACTION
   SET @msg = ''Error encountered while automatically resolving residency inventory discrepancies.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
   EXECUTE error$raise @msg, @error
   RETURN -100
END

-- Remove all the medium type discrepancies where the medium types now agree
-- and where the medium no longer appears in the vault inventory
DELETE FROM VaultDiscrepancy
WHERE  ItemId IN (SELECT vdmt.ItemId
                  FROM   VaultDiscrepancyMediumType vdmt
                  JOIN   Medium m
                    ON   m.SerialNo = vdmt.SerialNo
                  JOIN   VaultInventoryItem vii
                    ON   vii.SerialNo = m.SerialNo
                  WHERE  vii.TypeId = m.TypeId			-- medium types now agree
                  UNION
                  SELECT vdmt.ItemId
                  FROM   VaultDiscrepancyMediumType vdmt
                  JOIN   Medium m
                    ON   m.SerialNo = vdmt.SerialNo
                  LEFT OUTER JOIN VaultInventoryItem vii
                    ON   vii.SerialNo = m.SerialNo
                  WHERE  vii.SerialNo IS NULL)                  -- medium no longer in vault inventory, so no way to judge
SET @error = @@error
IF @error != 0 BEGIN
   ROLLBACK TRANSACTION @tranName
   COMMIT TRANSACTION
   SET @msg = ''Error encountered while automatically resolving medium type inventory discrepancies.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
   EXECUTE error$raise @msg, @error
   RETURN -100
END

-- Remove all the case type discrepancies where the case types now agree
-- and where the case no longer appears in the vault inventory
DELETE FROM VaultDiscrepancy
WHERE  ItemId IN (SELECT vdct.ItemId
                  FROM   VaultDiscrepancyCaseType vdct
                  JOIN   SealedCase sc
                    ON   sc.SerialNo = vdct.SerialNo
                  JOIN   VaultInventoryItem vii
                    ON   vii.SerialNo = sc.SerialNo
                  WHERE  vii.TypeId = sc.TypeId			-- case types now agree
                  UNION
                  SELECT vdct.ItemId
                  FROM   VaultDiscrepancyCaseType vdct
                  JOIN   SealedCase sc
                    ON   sc.SerialNo = vdct.SerialNo
                  LEFT OUTER JOIN VaultInventoryItem vii
                    ON   vii.SerialNo = sc.SerialNo
                  WHERE  vii.SerialNo IS NULL)                  -- case no longer in vault inventory, so no way to judge
SET @error = @@error
IF @error != 0 BEGIN
   ROLLBACK TRANSACTION @tranName
   COMMIT TRANSACTION
   SET @msg = ''Error encountered while automatically resolving case type inventory discrepancies.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
   EXECUTE error$raise @msg, @error
   RETURN -100
END

-- Remove all the medium account discrepancies where the accounts now agree
DELETE FROM VaultDiscrepancy
WHERE  ItemId IN (SELECT vda.ItemId
                  FROM   VaultDiscrepancyAccount vda
                  JOIN   Medium m
                    ON   m.SerialNo = vda.SerialNo
                  JOIN   VaultInventoryItem vii
                    ON   vii.ItemId = vda.ItemId
                  JOIN   VaultInventory vi
                    ON   vi.InventoryId = vii.InventoryId
                  WHERE  vi.AccountId = m.AccountId)
SET @error = @@error
IF @error != 0 BEGIN
   ROLLBACK TRANSACTION @tranName
   COMMIT TRANSACTION
   SET @msg = ''Error encountered while automatically resolving account inventory discrepancies.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
   EXECUTE error$raise @msg, @error
   RETURN -100
END

COMMIT TRANSACTION
RETURN 0
END
'
)

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'vaultInventory$insertNew')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.vaultInventory$insertNew
(
   @inventoryId int
)
WITH ENCRYPTION
AS
BEGIN
DECLARE @i int
DECLARE @rowCount int
DECLARE @mediumId int
DECLARE @serialNo nvarchar(64)
DECLARE @tranName nvarchar(255)
DECLARE @returnValue int
DECLARE @tblNewMedia table
(
   RowNo int IDENTITY(1,1),
   SerialNo nvarchar(64)
)

SET NOCOUNT ON

-- Set up the transaction name
SET @tranName = object_name(@@procid) + CAST(@@nestlevel as nvarchar(2))

-- Begin the transaction
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

INSERT @tblNewMedia (SerialNo)
SELECT vii.SerialNo
FROM   VaultInventoryItem vii
LEFT OUTER JOIN Medium m
  ON   m.SerialNo = vii.SerialNo
WHERE  m.SerialNo IS NULL AND
       vii.InventoryId = @inventoryId AND
       dbo.bit$IsContainerType(vii.TypeId) = 0

SET @rowCount = @@rowCount
SET @i = 1

WHILE @i <= @rowCount BEGIN
   -- Get the next medium
   SELECT @serialNo = SerialNo
   FROM   @tblNewMedia
   WHERE  RowNo = @i
   -- Add it dynamically
   EXECUTE @returnValue = medium$addDynamic @serialNo, 0, @mediumId out
   IF @returnValue != 0 BEGIN
      ROLLBACK TRANSACTION @tranName
      COMMIT TRANSACTION
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
   SELECT TOP 1 @lastSerial = vii.SerialNo
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
      UPDATE Medium
      SET    Missing = 0,
             Location = 0
      WHERE  SerialNo = @lastSerial
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
DECLARE @exclude bit
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

-- Find out if we are excluding tapes on lists or not
IF EXISTS (SELECT 1 FROM Preference WHERE KeyNo = 6 AND Value IN (''YES'',''TRUE''))
   SET @exclude = 1
ELSE
   SET @exclude = 0

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
ELSE BEGIN
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
          NOT EXISTS (SELECT 1 FROM SendListItem sli WHERE sli.MediumId = m.MediumId AND sli.Status NOT IN (1, 1024))
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
          NOT EXISTS (SELECT 1 FROM ReceiveListItem rli WHERE rli.MediumId = m.MediumId AND rli.Status NOT IN (1, 1024))
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

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'vaultInventory$compareCases')
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
SET @timeNow = cast(convert(nvarchar(19), getdate(), 120) as datetime)

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
      VALUES (getdate())
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

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'vaultInventory$compareMediumTypes')
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
SET @timeNow = cast(convert(nvarchar(19), getdate(), 120) as datetime)

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
      VALUES (getdate())
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

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'vaultInventory$compareCaseTypes')
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
SET @timeNow = cast(convert(nvarchar(19), getdate(), 120) as datetime)

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
      VALUES (getdate())
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

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'vaultInventory$compareMediumAccounts')
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
SET @timeNow = cast(convert(nvarchar(19), getdate(), 120) as datetime)

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
      VALUES (getdate())
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

-------------------------------------------------------------------------------
--
-- vaultInventory$compare
--
--
-- Four types of discrepancies: (a) residency - 1, (b) unknown case - 2, 
-- (c) medium type disagreement - 3, (d) hot site status disagreement - 4
--
-- First, add all the media (not cases) that appear in the inventory but
-- do not appear in the medium table to the system.
--
-- Second, get all the media that do not appear in the inventory and do not
-- appear in a sealed case mentioned in the inventory.
--
-- Third, get all the cases that do not appear in the sealed case table
--
-- Fourth, get all the media/cases in the inventory that do not have the
-- same media type as their counterparts in the system.
--
-- Fifth, get all the media and cases that have a different hot status
-- than mentioned in the inventory.  NOTE: This is being ignored for now,
-- as Recall does not include hot site status in its inventory files.
--
-------------------------------------------------------------------------------
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

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'vaultInventory$getLatestFileHash')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.vaultInventory$getLatestFileHash
(
   @account nvarchar(256) = null,
   @fileHash binary(32) out
)
WITH ENCRYPTION
AS
BEGIN

SET NOCOUNT ON

SET @fileHash = NULL

IF @account IS NULL BEGIN
   SELECT TOP 1 @account = AccountName
   FROM   Account
   WHERE  Global = 1
END

SELECT TOP 1 @fileHash = i.FileHash
FROM   VaultInventory i
JOIN   Account a
  ON   a.AccountId = i.AccountId
WHERE  a.AccountName = @account
ORDER BY i.DownloadTime Desc

END
'
)

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'vaultInventory$getLatestInventory')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.vaultInventory$getLatestInventory
(
   @account nvarchar(256) = null
)
WITH ENCRYPTION
AS
BEGIN

SET NOCOUNT ON

IF @account IS NULL BEGIN
   SELECT TOP 1 @account = AccountName
   FROM   Account
   WHERE  Global = 1
END

SELECT ItemId,
       SerialNo,
       TypeId,
       HotStatus
FROM   VaultInventoryItem
WHERE  InventoryId = (SELECT TOP 1 v.InventoryId
                      FROM   VaultInventory v
                      JOIN   Account a
                        ON   a.AccountId = v.AccountId
                      WHERE  a.AccountName = @account
                      ORDER BY v.DownloadTime Desc)

END
'
)

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'vaultInventory$ins')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.vaultInventory$ins
(
   @account nvarchar(256),
   @fileHash binary(32),
   @downloadTime datetime,
   @newId int out
)
WITH ENCRYPTION
AS
BEGIN
DECLARE @msg nvarchar(255)        -- used to preformat error message
DECLARE @msgTag nvarchar(255)     -- used to hold first part of error message header
DECLARE @tranName nvarchar(255)   -- used to hold name of savepoint
DECLARE @error int
DECLARE @accountId int

SET NOCOUNT ON

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=P''
SET @tranName = object_name(@@procid) + CAST(@@nestlevel as nvarchar(2))

SELECT @accountId = AccountId
FROM   Account
WHERE  AccountName = @account
IF @@rowCount = 0 BEGIN
   SET @msg = ''Account not found.'' + @msgTag + ''>''
   RAISERROR(@msg,16,1)
   RETURN -100
END

-- Begin the transaction
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

-- Delete any old inventories of this account
DELETE VaultInventory
WHERE  AccountId = @accountId

SET @error = @@error
IF @error != 0 BEGIN
   ROLLBACK TRANSACTION @tranName
   COMMIT TRANSACTION
   SET @msg = ''Error encountered while deleting old vault inventory.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
   EXECUTE error$raise @msg, @error
   RETURN -100
END

-- Insert new record
INSERT VaultInventory
(
   AccountId,
   FileHash,
   DownloadTime
)
VALUES
(
   @accountId,
   @fileHash,
   @downloadTime
)

SET @error = @@error
IF @error != 0 BEGIN
   ROLLBACK TRANSACTION @tranName
   COMMIT TRANSACTION
   SET @msg = ''Error encountered while inserting new vault inventory.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
   EXECUTE error$raise @msg, @error
   RETURN -100
END

-- Commit the transaction
SET @newId = scope_identity()
COMMIT TRANSACTION
RETURN 0
END
'
)

IF EXISTS(SELECT * FROM sysobjects WHERE name = 'vaultInventory$afterInsert' AND objectproperty(id, 'ExecIsInsertTrigger' ) = 1) 
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'TRIGGER vaultInventory$afterInsert
ON     VaultInventory
WITH ENCRYPTION
AFTER  INSERT
AS
BEGIN
DECLARE @msg nvarchar(255)        -- used to preformat error message
DECLARE @msgTag nvarchar(255)     -- used to hold first part of error message header
DECLARE @msgUpdate nvarchar(4000) -- used to hold the updated fields
DECLARE @tranName nvarchar(255)   -- used to hold name of savepoint
DECLARE @accountName nvarchar(256)
DECLARE @rowCount int             -- holds the number of rows in the Deleted table
DECLARE @error int

SET @rowCount = @@rowcount
IF @rowCount = 0 RETURN

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=T''
SET @tranName = object_name(@@procid) + CAST(trigger_nestlevel(@@procid) as nvarchar(2))

-- Batch insert not allowed
IF @rowCount > 1 BEGIN
   SET @msg = ''Batch insert into vault inventory table not allowed.'' + @msgTag + ''>''
   EXECUTE error$raise @msg, 0
   RETURN
END

-- Begin the transaction
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

-- Get the caller login from the spidLogin table
IF len(dbo.string$GetSpidLogin()) = 0 BEGIN
   SET @msg = ''Caller login not found in spid login table.'' + @msgTag + ''>''
   EXECUTE error$raise @msg, 0, @tranName
   RETURN
END

-- Get the account name
SELECT @accountName = AccountName
FROM   Account
WHERE  AccountId = (SELECT AccountId FROM Inserted)

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
   11,
   ''Inventory downloaded for account '' + @accountName,
   dbo.string$GetSpidLogin()
)

SET @error = @@error
IF @error != 0 BEGIN
   SET @msg = ''Error encountered while inserting disaster code list audit record.'' + @msgTag + '';Error='' + cast(@error as nvarchar(9)) + ''>''
   EXECUTE error$raise @msg, @error, @tranName
   RETURN
END

COMMIT TRANSACTION
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
   InventoryId
)
VALUES
(
   @serialNo,
   @typeId,
   @hotStatus,
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

-------------------------------------------------------------------------------
--
-- Stored Procedures -- Disaster Code List
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
DECLARE @lastList int
DECLARE @lastCase int
DECLARE @lastMedium int
DECLARE @code nvarchar(32)
DECLARE @codeId int
DECLARE @status int
DECLARE @error int
DECLARE @returnValue int

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
   SET @msg = ''Disaster code list not found.'' + @msgTag + ''>''
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
ELSE BEGIN
   IF @status = 64 BEGIN -- power(4,x)
      RETURN 0
   END
   ELSE IF @status = 4 BEGIN -- power(4,x)
      SET @msg = ''Disaster code list has not yet been transmitted.'' + @msgTag + ''>''
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
   -- For each medium on the list, create the disaster code if it does not
   -- exist.  Then attach the medium to it.
   SET @lastMedium = 0
   WHILE 1 = 1 BEGIN
      -- Get the medium and the code
      SELECT TOP 1 @lastMedium = dclim.MediumId,
             @code = dcli.Code
      FROM   DisasterCodeListItemMedium dclim
      JOIN   DisasterCodeListItem dcli
        ON   dcli.ItemId = dclim.ItemId
      WHERE  dcli.Status != 1 AND -- power(4,x)
             dcli.ListId = @listId AND
             dclim.MediumId > @lastMedium
      ORDER BY dclim.MediumId Asc
      IF @@rowCount = 0
         BREAK
      ELSE BEGIN
         -- Delete any current disaster code entry for the medium
         DELETE DisasterCodeMedium
         WHERE  MediumId = @lastMedium
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
         EXECUTE @returnValue = disasterCodeMedium$ins @codeId, @lastMedium
         IF @returnValue != 0 BEGIN
            ROLLBACK TRANSACTION @tranName
            COMMIT TRANSACTION
            RETURN 0
         END
      END
   END
   -- For each case on the list, create the disaster code if it does not
   -- exist.  Then attach the case to it.
   SET @lastCase = 0
   WHILE 1 = 1 BEGIN
      -- Get the case and the code
      SELECT TOP 1 @lastCase = dclic.CaseId,
             @code = dcli.Code
      FROM   DisasterCodeListItemCase dclic
      JOIN   DisasterCodeListItem dcli
        ON   dcli.ItemId = dclic.ItemId
      WHERE  dcli.Status != 1 AND -- power(4,x)
             dcli.ListId = @listId AND
             dclic.CaseId > @lastCase
      ORDER BY dclic.CaseId Asc
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
         EXECUTE @returnValue = disasterCodeCase$ins @codeId, @lastCase
         IF @returnValue != 0 BEGIN
            ROLLBACK TRANSACTION @tranName
            COMMIT TRANSACTION
            RETURN 0
         END
      END
   END
   -- Set the status of all unremoved list items to cleared
   UPDATE DisasterCodeListItem
   SET    Status = 64 -- power(4,x)
   WHERE  Status != 1 AND ListId = @listId -- power(4,x)
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
WHERE  ListId = @listId
IF @@rowCount = 0 BEGIN
   SET @msg = ''Disaster code list not found.'' + @msgTag + ''>''
   RAISERROR(@msg,16,1)
   RETURN -100
END
ELSE IF @accountId IS NOT NULL BEGIN
   SET @msg = ''Disaster code list '''''' + @listName + '''''' is not a composite list.'' + @msgTag + ''>''
   RAISERROR(@msg,16,1)
   RETURN -100
END
ELSE IF @status >= 16 BEGIN -- power(4,x)
   SET @msg = ''Lists may not be extracted after they have been transmitted.'' + @msgTag + ''>''
   RAISERROR(@msg,16,1)
   RETURN -100
END
ELSE IF NOT EXISTS
   (
   SELECT 1
   FROM   DisasterCodeList
   WHERE  ListId = @listId AND RowVersion = @listVersion
   )
BEGIN
   SET @msg = ''Disaster code list '''''' + @listName + '''''' has been modified since retrieval.'' + @msgTag + ''>''
   RAISERROR(@msg,16,1)
   RETURN -100
END

-- Begin the transaction
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

-- Update all the discretes to have no composite.  This will cause the list
-- composite to be deleted in the trigger.
-- Update all the discretes to have no composite
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
ORDER BY ListName Asc

END
'
)

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'disasterCodeList$getById')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.disasterCodeList$getById
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
FROM   DisasterCodeList dl
LEFT OUTER JOIN Account a
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
   FROM   DisasterCodeList dl
   JOIN   Account a
     ON   a.AccountId = dl.AccountId
   WHERE  dl.CompositeId = @id
   ORDER BY dl.ListName
END

END
'
)

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'disasterCodeList$getByName')
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
FROM   DisasterCodeList dl
LEFT 
OUTER 
JOIN   Account a
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
   FROM   DisasterCodeList dl
   JOIN   Account a
     ON   a.AccountId = dl.AccountId
   WHERE  dl.CompositeId = @id
   ORDER BY dl.ListName
END

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
WHERE  dl.Status = 64 AND
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
WHERE  dl.Status = 64 AND
       dl.AccountId IS NULL AND
       EXISTS(SELECT 1 
              FROM   DisasterCodeList dl2
              WHERE  CompositeId = dl.ListId AND
                     convert(nchar(10),dl2.CreateDate,120) <= @dateString)
ORDER BY ListName Asc

END
'
)

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'disasterCodeList$getItemCount')
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
   JOIN   DisasterCodeList dl
     ON   dl.ListId = dli.ListId
   WHERE  dli.Status != 1 AND -- power(4,x)
         (dl.ListId = @listId OR dl.CompositeId = @listId)
END
ELSE BEGIN
   SELECT count(*)
   FROM   DisasterCodeListItem dli
   JOIN   DisasterCodeList dl
     ON   dl.ListId = dli.ListId
   WHERE  dli.Status = @status AND
         (dl.ListId = @listId OR dl.CompositeId = @listId)
END

END
'
)

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'disasterCodeList$getItems')
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
       dli.Code,
       dli.Status,
       dli.Notes,
       m.SerialNo,
       1 as ''ItemType'',
       dli.RowVersion
FROM   DisasterCodeList dl
JOIN   DisasterCodeListItem dli
  ON   dli.ListId = dl.ListId
JOIN   DisasterCodeListItemMedium dlim
  ON   dlim.ItemId = dli.ItemId
JOIN   Medium m
  ON   m.MediumId = dlim.MediumId
WHERE  dl.ListId = @listId OR dl.CompositeId = @listId

UNION

SELECT dli.ItemId,
       dli.Code,
       dli.Status,
       dli.Notes,
       sc.SerialNo,
       2 as ''ItemType'',
       dli.RowVersion
FROM   DisasterCodeList dl
JOIN   DisasterCodeListItem dli
  ON   dli.ListId = dl.ListId
JOIN   DisasterCodeListItemCase dlic
  ON   dlic.ItemId = dli.ItemId
JOIN   SealedCase sc
  ON   sc.CaseId = dlic.CaseId
WHERE  dl.ListId = @listId OR dl.CompositeId = @listId

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
DECLARE @order1 nvarchar(4000)	-- innermost order clause
DECLARE @order2 nvarchar(4000)   -- middle order clause
DECLARE @order3 nvarchar(4000)   -- outermost order clause
DECLARE @where nvarchar(4000)
DECLARE @tableName nvarchar(4000)
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
IF len(ltrim(rtrim(coalesce(@filter,'''')))) > 0 BEGIN
   SET @filter = replace(@filter,''ListName'',''dl.ListName'')
   SET @filter = replace(@filter,''CreateDate'',''dl.CreateDate'')
   SET @filter = replace(@filter,''Status'',''dl.Status'')
   SET @filter = replace(@filter,''AccountName'',''coalesce(a.AccountName,'''''''')'')
   SET @where = @where + '' AND ('' + @filter + '')''
END

-- Construct the fields string
SET @fields2 = ''ListId, ListName, CreateDate, Status, AccountName, RowVersion''
SET @fields1 = ''dl.ListId, dl.ListName, dl.CreateDate, dl.Status, coalesce(a.AccountName,'''''''') as ''''AccountName'''', dl.RowVersion''

-- Construct the tables string
SET @tables = ''DisasterCodeList dl LEFT OUTER JOIN Account a ON dl.AccountId = a.AccountId''

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
FROM   DisasterCodeList
WHERE  ListId = @listId1
IF @@rowCount = 0 BEGIN
   SET @msg = ''Disaster code list not found.'' + @msgTag + ''>''
   RAISERROR(@msg,16,1)
   RETURN -100
END
ELSE IF NOT EXISTS
   (
   SELECT 1
   FROM   DisasterCodeList
   WHERE  ListId = @listId1 AND RowVersion = @rowVersion1
   )
BEGIN
   SET @msg = ''Disaster code list '''''' + @listName1 + '''''' has been modified since retrieval.'' + @msgTag + ''>''
   RAISERROR(@msg,16,1)
   RETURN -100
END
ELSE IF EXISTS
   (
   SELECT 1 
   FROM   DisasterCodeList
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
FROM   DisasterCodeList 
WHERE  ListId = @listId2
IF @@rowCount = 0 BEGIN
   SET @msg = ''Disaster code list not found.'' + @msgTag + ''>''
   RAISERROR(@msg,16,1)
   RETURN -100
END
ELSE IF NOT EXISTS
   (
   SELECT 1
   FROM   DisasterCodeList
   WHERE  ListId = @listId2 AND RowVersion = @rowVersion2
   )
BEGIN
   SET @msg = ''Disaster code list '''''' + @listName2 + '''''' has been modified since retrieval.'' + @msgTag + ''>''
   RAISERROR(@msg,16,1)
   RETURN -100
END
ELSE IF EXISTS
   (
   SELECT 1 
   FROM   DisasterCodeList
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
   FROM   DisasterCodeList 
   WHERE  ListId IN (@listId1,@listId2) AND Status >= 16 -- power(4,x)
   )
BEGIN
   SET @msg = ''Only lists that have not yet been transmitted may be merged.'' + @msgTag + ''>''
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
IF @accountId1 IS NOT NULL AND @accountId1 IS NOT NULL BEGIN
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
          ListId IN (@listId1,@listId2)
   UPDATE DisasterCodeList
   SET    CompositeId = @compositeId
   WHERE  ListId = (SELECT ListId
                    FROM   DisasterCodeList
                    WHERE  ListId != @compositeId AND
                           ListId IN (@listId2, @listId2))
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
WHERE  ListId = @listId AND Status != 1 -- power(4,x)
IF @status IS NULL RETURN 0

-- Begin the transaction
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

-- Update the disaster code list
UPDATE DisasterCodeList
SET    Status = @status
WHERE  ListId = @listId AND RowVersion = @rowVersion
SELECT @error = @@error, @rowCount = @@rowCount
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
DECLARE @lastItem int
DECLARE @rowCount int
DECLARE @status int
DECLARE @error int

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=P''
SET @tranName = object_name(@@procid) + CAST(@@nestlevel as nvarchar(2))

-- If the status of the list is already transmitted, then return.  Otherwise,
-- if it is anything besides submitted, return.
SELECT @status = Status
FROM   DisasterCodeList
WHERE  ListId = @listId AND
       RowVersion = @rowVersion
IF @@rowCount = 0 BEGIN
   IF EXISTS(SELECT 1 FROM DisasterCodeList WHERE ListId = @listId) BEGIN
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
ELSE IF @status > 4 BEGIN -- power(4,x)
   RETURN 0
END 

-- Upgrade the status of all the unremoved items on the list to transmitted
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

SET @lastItem = 0
WHILE 1 = 1 BEGIN
   SELECT TOP 1 @lastItem = dli.ItemId
   FROM   DisasterCodeListItem dli
   JOIN   DisasterCodeList dl
     ON   dl.ListId = dli.ListId
   WHERE  dli.Status != 1 AND -- power(4,x)
          dli.ItemId > @lastItem AND
         (dl.ListId = @listId OR dl.CompositeId = @listId)
   ORDER BY dli.ItemId ASC
   IF @@rowCount = 0 BEGIN
      BREAK
   END
   ELSE BEGIN
      UPDATE DisasterCodeListItem
      SET    Status = 16 -- power(4,x)
      WHERE  ItemId = @lastItem
      SET @error = @@error
      IF @error != 0 BEGIN
         ROLLBACK TRANSACTION @tranName
         COMMIT TRANSACTION
         SET @msg = ''Error encountered while upgrading disaster code list item to transmitted.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
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
SELECT @status = Status
FROM   DisasterCodeList
WHERE  ListId = @listId
IF @@rowCount = 0 BEGIN
   SET @msg = ''Disaster code list not found.'' + @msgTag + ''>''
   RAISERROR(@msg,16,1)
   RETURN -100
END
ELSE IF @status > 4 BEGIN -- power(4,x)
   SET @msg = ''Disaster code list may not be altered after it has been transmitted.'' + @msgTag + ''>''
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

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'disasterCodeListItem$get')
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

IF EXISTS(SELECT 1 FROM DisasterCodeListItemMedium WHERE ItemId = @itemId) BEGIN
   SELECT dli.ItemId,
          dli.Code,
          dli.Status,
          dli.Notes,
          m.SerialNo,
          1 as ''ItemType'',
          dli.RowVersion
   FROM   DisasterCodeListItem dli
   JOIN   DisasterCodeListItemMedium dlim
     ON   dlim.ItemId = dli.ItemId
   JOIN   Medium m
     ON   m.MediumId = dlim.MediumId
   WHERE  dli.ItemId = @itemId
END
ELSE BEGIN
   SELECT dli.ItemId,
          dli.Code,
          dli.Status,
          dli.Notes,
          sc.SerialNo,
          2 as ''ItemType'',
          dli.RowVersion
   FROM   DisasterCodeListItem dli
   JOIN   DisasterCodeListItemCase dlic
     ON   dlic.ItemId = dli.ItemId
   JOIN   SealedCase sc
     ON   sc.CaseId = dlic.CaseId
   WHERE  dli.ItemId = @itemId
END

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
IF len(ltrim(rtrim(coalesce(@filter,'''')))) > 0 BEGIN
	SET @filter = replace(@filter,''SerialNo'',''coalesce(lm.SerialNo,lc.SerialNo)'')
	SET @filter = replace(@filter,''Account'', ''coalesce(lm.AccountName,'''''''')'')
	SET @filter = replace(@filter,''Status'',''dli.Status'')
	SET @filter = replace(@filter,''Code'',''dli.Code'')
   SET @where = @where + '' AND ('' + @filter + '')''
END

-- Construct the fields string
SET @fields2 = ''ItemId, Status, SerialNo, AccountName, Code, Notes, RowVersion''
SET @fields1 = ''dli.ItemId, dli.Status, coalesce(lm.SerialNo,lc.SerialNo) as ''''SerialNo'''', coalesce(lm.AccountName,'''''''') as ''''AccountName'''', dli.Code, lm.Notes, dli.RowVersion''

-- Construct the tables string
SET @tables = ''DisasterCodeListItem dli JOIN DisasterCodeList dl ON dl.ListId = dli.ListId LEFT OUTER JOIN (SELECT dlim.ItemId, m.SerialNo, a.AccountName, m.Notes FROM DisasterCodeListItemMedium dlim JOIN Medium m ON m.MediumId = dlim.MediumId JOIN Account a ON a.AccountId = m.AccountId) as lm ON lm.ItemId = dli.ItemId LEFT OUTER JOIN (SELECT dlic.ItemId, sc.SerialNo FROM DisasterCodeListItemCase dlic JOIN SealedCase sc ON sc.CaseId = dlic.CaseId) as lc ON lc.ItemId = dli.ItemId''

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

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'disasterCodeListItem$ins')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.disasterCodeListItem$ins
(
   @serialNo nvarchar(32),               -- medium serial number
   @code nvarchar(32),                   -- disaster code
   @notes nvarchar(1000),                -- any notes to attach to the medium
   @batchLists nvarchar(4000),           -- list names in the creation batch
   @newList nvarchar(10) OUTPUT          -- name of list if created
)
WITH ENCRYPTION
AS
BEGIN
DECLARE @msg as nvarchar(255)        -- used to preformat error message
DECLARE @msgTag as nvarchar(255)     -- used to hold first part of error message header
DECLARE @tranName as nvarchar(255)   -- used to hold name of savepoint
DECLARE @error as int
DECLARE @mediumId as int
DECLARE @returnValue as int
DECLARE @caseId as int
DECLARE @caseSerial nvarchar(32)

SET NOCOUNT ON

-- Tweak parameters
SET @batchLists = ltrim(rtrim(coalesce(@batchLists,'''')))
SET @serialNo = ltrim(rtrim(@serialNo))
SET @notes = ltrim(rtrim(@notes))
SET @code = ltrim(rtrim(@code))
SET @newList = ''''

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=P''
SET @tranName = object_name(@@procid) + CAST(@@nestlevel as nvarchar(2))

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
   EXECUTE @returnValue = disasterCodeListItemCase$ins @caseId, @code, @notes, @batchLists, @newList out
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
   EXECUTE @returnValue = disasterCodeListItemMedium$ins @mediumId, @code, @notes, @batchLists, @newList out
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
DECLARE @error as int

SET NOCOUNT ON

-- Tweak parameters
SET @code = ltrim(rtrim(@code))
SET @notes = ltrim(rtrim(@notes))

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=P''
SET @tranName = object_name(@@procid) + CAST(@@nestlevel as nvarchar(2))

-- If the list is not submitted, raise error.  
IF EXISTS
   (
   SELECT 1 
   FROM   DisasterCodeList
   WHERE  Status != 4 AND -- power(4,x)
          ListId = (SELECT ListId FROM DisasterCodeListItem WHERE ItemId = @itemId)
   )
BEGIN
   SET @msg = ''Changes may not be made to a disaster code list after it has been transmitted.'' + @msgTag + ''>''
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
      SET @msg = ''Disaster code list item has been modified since retrieval.'' + @msgTag + ''>''
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

-------------------------------------------------------------------------------
--
-- Triggers - Disaster Code Lists
--
-------------------------------------------------------------------------------
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
DECLARE @lastList int
DECLARE @listName char(10)       -- holds the name of the deleted disaster code list
DECLARE @rowCount int            -- holds the number of rows in the Deleted table
DECLARE @error int          

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
   IF @@rowCount = 0
      BREAK
   ELSE BEGIN
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
   END
END

COMMIT TRANSACTION
END
'
)

IF EXISTS(SELECT * FROM sysobjects WHERE name = 'disasterCodeList$AfterInsert' AND objectproperty(id, 'ExecIsInsertTrigger' ) = 1) 
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'TRIGGER disasterCodeList$AfterInsert
ON     DisasterCodeList
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

-- Begin transaction
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

-- Make sure we do not have a batch insert
IF @rowCount > 1 BEGIN
   SET @msg = ''Batch insert into disaster code list table not allowed.'' + @msgTag + ''>''
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
SET @msgUpdate = ''Disaster code list '' + @listName + '' created''

-- Get the account name
SELECT @account = AccountName
FROM   Account
WHERE  AccountId = (SELECT AccountId FROM Inserted)
IF @@rowcount > 0
   SET @msgUpdate = @msgUpdate + '';Account='' + @account

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
   @msgUpdate,
   dbo.string$GetSpidLogin()
)

SET @error = @@error
IF @error != 0 BEGIN
   SET @msg = ''Error encountered while inserting a disaster code list audit record.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
   EXECUTE error$raise @msg, @error, @tranName
   RETURN
END

COMMIT TRANSACTION
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
   SET @msg = ''Status of disaster code list may not be reduced.'' + @msgTag + ''>''
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
      IF @status = 4  -- power(4,x)
         SET @msgUpdate = ''List '''''' + @listName + '''''' updated;Status=Submitted''
      ELSE IF @status = 16 -- power(4,x)
         SET @msgUpdate = ''List '''''' + @listName + '''''' updated;Status=Transmitted''
      ELSE IF @status = 64 -- power(4,x)
         SET @msgUpdate = ''List '''''' + @listName + '''''' updated;Status=Cleared''
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
         2,
         @msgUpdate,
         dbo.string$GetSpidLogin()
      )
      SET @error = @@error
      IF @error != 0 BEGIN
         SET @msg = ''Error encountered while inserting disaster code list audit record.'' + @msgTag + '';Error='' + cast(@error as nvarchar(9)) + ''>''
         EXECUTE error$raise @msg, @error, @tranName
         RETURN
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
               SET @msg = ''Error encountered while updating composite disaster code list status.'' + @msgTag + '';Error='' + cast(@error as nvarchar(9)) + ''>''
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
         ''List '''''' + @listName + '''''' merged into composite '''''' + @compositeName + '''''''',
         dbo.string$GetSpidLogin()
      )
      SET @error = @@error
      IF @error != 0 BEGIN
         SET @msg = ''Error encountered while inserting disaster code list audit record.'' + @msgTag + '';Error='' + cast(@error as nvarchar(9)) + ''>''
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
         ''List '''''' + @listName + '''''' extracted from composite '''''' + @compositeName + '''''''',
         dbo.string$GetSpidLogin()
      )
      SET @error = @@error
      IF @error != 0 BEGIN
         SET @msg = ''Error encountered while inserting disaster code list audit record.'' + @msgTag + '';Error='' + cast(@error as nvarchar(9)) + ''>''
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

IF EXISTS(SELECT * FROM sysobjects WHERE name = 'disasterCodeListItem$afterDelete' AND objectproperty(id, 'ExecIsDeleteTrigger' ) = 1) 
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'TRIGGER disasterCodeListItem$afterDelete
ON     DisasterCodeListItem
WITH ENCRYPTION
AFTER  DELETE
AS
BEGIN
DECLARE @msg nvarchar(255)         -- used to preformat error message
DECLARE @msgTag nvarchar(255)      -- used to hold first part of error message header
DECLARE @msgUpdate nvarchar(4000)  -- used to hold the updated fields
DECLARE @tranName nvarchar(255)    -- used to hold name of savepoint
DECLARE @listName nchar(10)
DECLARE @lastList int
DECLARE @lastItem int
DECLARE @serialNo nvarchar(32)
DECLARE @detail nvarchar(1000)
DECLARE @rowVersion rowversion
DECLARE @returnValue int
DECLARE @rowCount int
DECLARE @error int

SET @rowCount = @@rowcount
IF @rowCount = 0 RETURN

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=T''
SET @tranName = object_name(@@procid) + CAST(trigger_nestlevel(@@procid) as nvarchar(2))

-- Begin transaction
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

-- Get the caller login from the spidLogin table
IF len(dbo.string$GetSpidLogin()) = 0 BEGIN
   SET @msg = ''Login not found for auditing purposes.'' + @msgTag + ''>''
   EXECUTE error$raise @msg, 0, @tranName
   RETURN
END

-- For each list, if there are no active items left, delete list.  Else
-- set the status of list.
SET @lastList = 0
WHILE 1 = 1 BEGIN
   SELECT TOP 1 @lastList = d.ListId,
          @rowVersion = dl.RowVersion
   FROM   Deleted d
   JOIN   DisasterCodeList dl
     ON   dl.ListId = d.ListId
   WHERE  d.ListId > @lastList
   ORDER BY d.ListId ASC
   IF @@rowCount = 0
      BREAK
   ELSE BEGIN
      IF EXISTS(SELECT 1 FROM DisasterCodeListItem WHERE Status != 1 AND ListId = @lastList) BEGIN -- power(4,x)
         EXECUTE @returnValue = disasterCodeList$setStatus @lastlist, @rowVersion
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

-- Commit transaction
COMMIT TRANSACTION
END
'
)

IF EXISTS(SELECT * FROM sysobjects WHERE name = 'disasterCodeListItem$afterInsert' AND objectproperty(id, 'ExecIsInsertTrigger' ) = 1) 
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
DECLARE @rowCount int

SET @rowCount = @@rowcount
IF @rowCount = 0 RETURN

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=T''
SET @tranName = object_name(@@procid) + CAST(trigger_nestlevel(@@procid) as nvarchar(2))

-- Begin transaction
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

-- No batch insert
IF @rowCount > 1 BEGIN
   SET @msg = ''Batch insert of disaster code list items not allowed.'' + @msgTag + ''>''
   EXECUTE error$raise @msg, 0, @tranName
   RETURN
END

-- Make sure that the list is not a composite
IF EXISTS(SELECT 1 FROM DisasterCodeList WHERE AccountId IS NULL AND ListId = (SELECT ListId FROM Inserted)) BEGIN
   SET @msg = ''Items may not be placed directly on a composite disaster code list.'' + @msgTag + ''>''
   EXECUTE error$raise @msg, 0, @tranName
   RETURN
END

-- Commit transaction
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
            SET @msgUpdate = ''Medium '''''' + @serialNo + '''''' removed from list.''
         ELSE IF @caseSerial = 1
            SET @msgUpdate = ''Case '''''' + @serialNo + '''''' removed from list.''
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
         SET @msg = ''Error encountered while inserting disaster code list item audit record.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
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
IF @listStatus >= 16 BEGIN -- power(4,x)
   SET @msg = ''Items cannot be added to a list that has already been transmitted.'' + @msgTag + ''>''
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
   ''Case '''''' + @serialNo + '''''' added to disaster code list'',
   dbo.string$GetSpidLogin()
)
SET @error = @@error
IF @error != 0 BEGIN
   SET @msg = ''Error encountered while inserting disaster code list item audit record.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
   EXECUTE error$raise @msg, @error, @tranName
   RETURN
END

-- Make sure that the discrete list status is equal to the lowest status among
-- We don''t have to translate here, as disaster code item status values are 
-- equal to disaster code list status values.
SELECT @rowVersion = RowVersion FROM DisasterCodeList WHERE ListId = @listId
EXECUTE disasterCodeList$setStatus @listId, @rowVersion

-- Commit
COMMIT TRANSACTION
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
IF @listStatus >= 16 BEGIN -- power(4,x)
   SET @msg = ''Items cannot be added to a list that has already been transmitted.'' + @msgTag + ''>''
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
   ''Medium '''''' + @serialNo + '''''' added to disaster code list'',
   dbo.string$GetSpidLogin()
)
SET @error = @@error
IF @error != 0 BEGIN
   SET @msg = ''Error encountered while inserting disaster code list item audit record.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
   EXECUTE error$raise @msg, @error, @tranName
   RETURN
END

-- Make sure that the discrete list status is equal to the lowest status among
-- We don''t have to translate here, as disaster code item status values are 
-- equal to disaster code list status values.
SELECT @rowVersion = RowVersion FROM DisasterCodeList WHERE ListId = @listId
EXECUTE disasterCodeList$setStatus @listId, @rowVersion

-- Commit
COMMIT TRANSACTION
END
'
)

-------------------------------------------------------------------------------
--
-- Stored Procedures - Receive Lists
--
-------------------------------------------------------------------------------
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
DECLARE @lastMedium int
DECLARE @lastList int
DECLARE @status int
DECLARE @error int
DECLARE @returnValue int

SET NOCOUNT ON

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=P''
SET @tranName = object_name(@@procid) + CAST(@@nestlevel as nvarchar(2))

-- If the list is not fully verified, raise error.  If the list 
-- has cleared status, return.  Also check concurrency.
SELECT @listName = ListName,
       @accountId = AccountId,
       @status = Status
FROM   ReceiveList
WHERE  ListId = @listId
IF @@rowCount = 0 BEGIN
   SET @msg = ''Receive list not found.'' + @msgTag + ''>''
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
ELSE BEGIN
   IF @status = 1024 -- power(4,x)
      RETURN 0
   ELSE IF @status < 256 BEGIN -- power(4,x)
      SET @msg = ''Receive list has not yet been fully verified.'' + @msgTag + ''>''
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
   SET @lastMedium = 0
   WHILE 1 = 1 BEGIN
      SELECT TOP 1 @lastMedium = MediumId
      FROM   ReceiveListItem
      WHERE  Status != 1 AND -- power(4,x)
             ListId = @listId AND
             MediumId > @lastMedium
      ORDER BY MediumId Asc
      IF @@rowCount = 0 BEGIN
         BREAK
      END
      ELSE BEGIN
         -- Delete the medium sealed case entries
         DELETE MediumSealedCase
         WHERE  MediumId = @lastMedium
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
         WHERE  MediumId = @lastMedium
         SET @error = @@error
         IF @error != 0 BEGIN
            ROLLBACK TRANSACTION @tranName
            COMMIT TRANSACTION
            SET @msg = ''Error encountered while returning media from vault.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
            EXECUTE error$raise @msg, @error
            RETURN -100
         END
      END
   END
   -- Set the status of all unremoved list items to cleared
   UPDATE ReceiveListItem
   SET    Status = 1024 -- power(4,5)
   WHERE  Status != 1 AND -- power(4,0)
          ListId = @listId
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

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'receiveList$clearVerified')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.receiveList$clearVerified
WITH ENCRYPTION
AS
BEGIN
DECLARE @tranName as nvarchar(255)   -- used to hold name of savepoint
DECLARE @lastList as int
DECLARE @rowVersion as rowversion
DECLARE @returnValue as int

SET NOCOUNT ON

-- Set up the transaction tag (nest level ensures uniqueness)
SET @tranName = object_name(@@procid) + CAST(@@nestlevel as nvarchar(2))

-- Update account
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

SET @lastList = 0
WHILE 1 = 1 BEGIN
   SELECT TOP 1 @lastList = ListId,
          @rowVersion = RowVersion
   FROM   ReceiveList WITH (READPAST)
   WHERE  Status = 256 AND -- power(4,4)
          CompositeId IS NULL AND
          ListId > @lastList
   ORDER BY ListId Asc
   IF @@rowCount = 0 BEGIN
      BREAK
   END
   ELSE BEGIN
      EXECUTE @returnValue = receiveList$clear @lastList, @rowVersion
      IF @returnValue != 0 BEGIN
         ROLLBACK TRANSACTION @tranName
         COMMIT TRANSACTION
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
DECLARE @lastSerial nvarchar(32)
DECLARE @returnValue int
DECLARE @rowCount as int
DECLARE @error as int

SET NOCOUNT ON

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
SET @lastSerial = ''''
SET @batchLists = ''''
WHILE 1 = 1 BEGIN
   SELECT TOP 1 @lastSerial = m.SerialNo
   FROM   Medium m
   LEFT OUTER JOIN
          (
          SELECT rli.MediumId
          FROM   ReceiveListItem rli
          WHERE  rli.Status IN (4, 16, 256) -- power(4,x)
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
          m.SerialNo > @lastSerial AND
          coalesce(convert(nchar(10),coalesce(c.ReturnDate,m.ReturnDate),120),''2999-01-01'') <= convert(nchar(10),@listDate,120)
   ORDER BY m.SerialNo asc
   IF @@rowCount = 0
      BREAK
   ELSE BEGIN
      EXECUTE @returnValue = receiveListItem$ins @lastSerial, '''', @batchLists output
      IF @returnValue != 0 BEGIN
         ROLLBACK TRANSACTION @tranName
         COMMIT TRANSACTION
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
WHERE  ListId = @listId
IF @@rowCount = 0 BEGIN
   SET @msg = ''Receive list not found.'' + @msgTag + ''>''
   RAISERROR(@msg,16,1)
   RETURN -100
END
ELSE IF @accountId IS NOT NULL BEGIN
   SET @msg = ''Receive list '''''' + @listName + '''''' is not a composite list.'' + @msgTag + ''>''
   RAISERROR(@msg,16,1)
   RETURN -100
END
ELSE IF @status >= 16 BEGIN -- power(4,2)
   SET @msg = ''Lists may not be extracted after they have been transmitted.'' + @msgTag + ''>''
   RAISERROR(@msg,16,1)
   RETURN -100
END
ELSE IF NOT EXISTS
   (
   SELECT 1
   FROM   ReceiveList
   WHERE  ListId = @listId AND RowVersion = @listVersion
   )
BEGIN
   SET @msg = ''Receive list '''''' + @listName + '''''' has been modified since retrieval.'' + @msgTag + ''>''
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
ORDER BY ListName Asc

END
'
)

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'receiveList$getById')
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
FROM   ReceiveList rl
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
   FROM   ReceiveList rl
   JOIN   Account a
     ON   a.AccountId = rl.AccountId
   WHERE  rl.CompositeId = @id
   ORDER BY rl.ListName
END

END
'
)

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'receiveList$getByName')
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
FROM   ReceiveList rl
LEFT 
OUTER 
JOIN   Account a
  ON   a.AccountId = rl.AccountId
WHERE  rl.ListName = @listName

-- If the list is a composite then get the child lists as well
SELECT @id = ListId 
FROM   ReceiveList 
WHERE  ListName = @listName

IF EXISTS(SELECT 1 FROM ReceiveList WHERE CompositeId = @id) BEGIN
   SELECT rl.ListId,
          rl.ListName,
          rl.CreateDate,
          rl.Status,
          a.AccountName,
          rl.RowVersion
   FROM   ReceiveList rl
   JOIN   Account a
     ON   a.AccountId = rl.AccountId
   WHERE  rl.CompositeId = @id
   ORDER BY rl.ListName
END

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
   @serialNo nvarchar(32)
)
WITH ENCRYPTION
AS
BEGIN

SET NOCOUNT ON

-- Select the list discrete only)
SELECT rl.ListId,
       rl.ListName,
       rl.CreateDate,
       rl.Status,
       coalesce(a.AccountName,'''') as ''AccountName'',
       rl.RowVersion
FROM   ReceiveList rl
JOIN   ReceiveListItem rli
  ON   rli.ListId = rl.ListId
JOIN   Medium m
  ON   m.MediumId = rli.MediumId
JOIN   Account a
  ON   a.AccountId = rl.AccountId
WHERE  m.SerialNo = @serialNo

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
WHERE  rl.Status = 1024 AND 
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
WHERE  rl.Status = 1024 AND
       rl.AccountId IS NULL AND
       EXISTS(SELECT 1 
              FROM   ReceiveList rl2
              WHERE  CompositeId = rl.ListId AND
                     convert(nchar(10),rl2.CreateDate,120) <= @dateString)
ORDER BY ListName Asc

END
'
)

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'receiveList$getItemCount')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.receiveList$getItemCount
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
   FROM   ReceiveListItem rli
   JOIN   ReceiveList rl
     ON   rl.ListId = rli.ListId
   WHERE  rli.Status != 1 AND -- power(4,0)
         (rl.ListId = @listId OR rl.CompositeId = @listId)
END
ELSE BEGIN
   SELECT count(*)
   FROM   ReceiveListItem rli
   JOIN   ReceiveList rl
     ON   rl.ListId = rli.ListId
   WHERE  rli.Status = @status AND
         (rl.ListId = @listId OR rl.CompositeId = @listId)
END

END
'
)

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'receiveList$getItems')
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
FROM   ReceiveList rl
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
DECLARE @order1 nvarchar(4000)	-- innermost order clause
DECLARE @order2 nvarchar(4000)   -- middle order clause
DECLARE @order3 nvarchar(4000)   -- outermost order clause
DECLARE @where nvarchar(4000)
DECLARE @tableName nvarchar(4000)
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
IF len(ltrim(rtrim(coalesce(@filter,'''')))) > 0 BEGIN
   SET @filter = replace(@filter,''ListName'',''rl.ListName'')
   SET @filter = replace(@filter,''CreateDate'',''rl.CreateDate'')
   SET @filter = replace(@filter,''Status'',''rl.Status'')
   SET @filter = replace(@filter,''AccountName'',''coalesce(a.AccountName,'''''''')'')
   SET @where = @where + '' AND ('' + @filter + '')''
END

-- Construct the fields string
SET @fields2 = ''ListId, ListName, CreateDate, Status, AccountName, RowVersion''
SET @fields1 = ''rl.ListId, rl.ListName, rl.CreateDate, rl.Status, coalesce(a.AccountName,'''''''') as ''''AccountName'''', rl.RowVersion''

-- Construct the tables string
SET @tables = ''ReceiveList rl LEFT OUTER JOIN Account a ON rl.AccountId = a.AccountId''

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
WHERE  ListId = @listId1
IF @@rowCount = 0 BEGIN
   SET @msg = ''Receive list not found.'' + @msgTag + ''>''
   RAISERROR(@msg,16,1)
   RETURN -100
END
ELSE IF NOT EXISTS
   (
   SELECT 1
   FROM   ReceiveList
   WHERE  ListId = @listId1 AND RowVersion = @rowVersion1
   )
BEGIN
   SET @msg = ''Receive list '''''' + @listName1 + '''''' has been modified since retrieval.'' + @msgTag + ''>''
   RAISERROR(@msg,16,1)
   RETURN -100
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
WHERE  ListId = @listId2
IF @@rowCount = 0 BEGIN
   SET @msg = ''Receive list not found.'' + @msgTag + ''>''
   RAISERROR(@msg,16,1)
   RETURN -100
END
ELSE IF NOT EXISTS
   (
   SELECT 1
   FROM   ReceiveList
   WHERE  ListId = @listId2 AND RowVersion = @rowVersion2
   )
BEGIN
   SET @msg = ''Receive list '''''' + @listName2 + '''''' has been modified since retrieval.'' + @msgTag + ''>''
   RAISERROR(@msg,16,1)
   RETURN -100
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

-- Make sure that neither list has yet been transmitted
IF EXISTS
   (
   SELECT 1 
   FROM   ReceiveList 
   WHERE  ListId IN (@listId1,@listId2) AND Status >= 16 -- power(4,2)
   )
BEGIN
   SET @msg = ''Only lists that have not yet been transmitted may be merged.'' + @msgTag + ''>''
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
IF @accountId1 IS NOT NULL AND @accountId1 IS NOT NULL BEGIN
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
          ListId IN (@listId1,@listId2)
   UPDATE ReceiveList
   SET    CompositeId = @compositeId
   WHERE  ListId = (SELECT ListId
                    FROM   ReceiveList
                    WHERE  ListId != @compositeId AND
                           ListId IN (@listId2, @listId2))
   SET @error = @@error
   IF @error != 0 BEGIN
      ROLLBACK TRANSACTION @tranName
      COMMIT TRANSACTION
      SET @msg = ''Error encountered while merging a discrete receive list into an existing composite.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
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
WHERE  ListId = @listId AND Status != 1 -- power(4,0)

-- If no status exists, return
IF @status IS NULL RETURN 0

-- If the minimum item status is transmitted, check to see if any items have been
-- verified.  If they have, set the list status to partially verified.  Otherwise
-- leave the status as the minimum item status.
IF @status = 16 BEGIN  -- power (4,2)
  IF EXISTS (SELECT 1 FROM ReceiveListItem WHERE ListId = @listId AND Status > 16) BEGIN
     SET @status = 64  -- power (4,3)
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
IF @error != 0 BEGIN
   ROLLBACK TRANSACTION @tranName
   COMMIT TRANSACTION
   SET @msg = ''Error encountered while updating receive list status'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
   EXECUTE error$raise @msg, @error
   RETURN -100
END
ELSE IF @rowCount = 0 BEGIN
   ROLLBACK TRANSACTION @tranName
   COMMIT TRANSACTION
   SET @msg = ''Receive list has been modified since retrieval.'' + @msgTag + ''>''
   RAISERROR(@msg,16,1)
   RETURN -100
END

-- If the list is fully verified, clear it.  Note that if the list is
-- part of a composite, then we have to check the list items for the
-- all the discrete lists within the composite.
IF @status = 256 BEGIN
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
      IF @status = 256 BEGIN
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

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=P''
SET @tranName = object_name(@@procid) + CAST(@@nestlevel as nvarchar(2))

-- If the status of the list is already transmitted, then return.  Otherwise,
-- if it is anything besides submitted, raise error.
SELECT @status = Status
FROM   ReceiveList
WHERE  ListId = @listId AND
       RowVersion = @rowVersion
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
ELSE IF @status > 4 BEGIN -- power(4,1)
   RETURN 0
END 

-- Upgrade the status of all the unremoved items on the list to transmitted
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

SET @lastItem = 0
WHILE 1 = 1 BEGIN
   SELECT TOP 1 @lastItem = rli.ItemId
   FROM   ReceiveListItem rli
   JOIN   ReceiveList rl
     ON   rl.ListId = rli.ListId
   WHERE  rli.Status != 1 AND -- power(4,0)
          rli.ItemId > @lastItem AND
         (rl.ListId = @listId OR rl.CompositeId = @listId)
   ORDER BY rli.ItemId ASC
   IF @@rowCount = 0 BEGIN
      BREAK
   END
   ELSE BEGIN
      UPDATE ReceiveListItem
      SET    Status = 16 -- power(4,2)
      WHERE  ItemId = @lastItem
      SET @error = @@error
      IF @error != 0 BEGIN
         ROLLBACK TRANSACTION @tranName
         COMMIT TRANSACTION
         SET @msg = ''Error encountered while upgrading receive list item to transmitted.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
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

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'receiveListItem$get')
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
WHERE  rli.ItemId = @itemId

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
IF len(ltrim(rtrim(coalesce(@filter,'''')))) > 0 BEGIN
	SET @filter = replace(@filter,''SerialNo'',''m.SerialNo'')
	SET @filter = replace(@filter,''Account'', ''a.AccountName'')
	SET @filter = replace(@filter,''Status'',''rli.Status'')
	SET @filter = replace(@filter,''CaseName'', ''coalesce(sc.CaseName,'''''''')'')
   SET @where = @where + '' AND ('' + @filter + '')''
END

-- Construct the fields string
SET @fields2 = ''ItemId, SerialNo, AccountName, Status, CaseName, Notes, RowVersion''
SET @fields1 = ''rli.ItemId, m.SerialNo, a.AccountName, rli.Status, coalesce(sc.CaseName,'''''''') as ''''CaseName'''', m.Notes, rli.RowVersion''

-- Construct the tables string
SET @tables = ''ReceiveListItem rli JOIN ReceiveList rl ON rl.ListId = rli.ListId JOIN Medium m ON m.MediumId = rli.MediumId JOIN Account a ON a.AccountId = m.AccountId LEFT OUTER JOIN (SELECT sc.SerialNo as ''''CaseName'''', msc.MediumId as ''''MediumId'''' FROM SealedCase sc JOIN MediumSealedCase msc ON msc.CaseId = sc.CaseId JOIN ReceiveListItem rli ON rli.MediumId = msc.MediumId JOIN ReceiveList rl ON rl.ListId = rli.ListId WHERE rl.ListId = '' + cast(@listId as nvarchar(50)) + '' OR rl.CompositeId = '' + cast(@listId as nvarchar(50)) + '') AS sc ON sc.MediumId = m.MediumId''

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
   @caseOthers int = 0      -- remove others from sealed case
)
WITH ENCRYPTION
AS
BEGIN
DECLARE @msg as nvarchar(255)        -- used to preformat error message
DECLARE @msgTag as nvarchar(255)     -- used to hold first part of error message header
DECLARE @tranName as nvarchar(255)   -- used to hold name of savepoint
DECLARE @returnValue as int
DECLARE @mediumId as int
DECLARE @missing as bit
DECLARE @rowCount as int
DECLARE @error as int
DECLARE @status as int
DECLARE @caseId as int

SET NOCOUNT ON

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=P''
SET @tranName = object_name(@@procid) + CAST(@@nestlevel as nvarchar(2))

-- Get the missing status of the medium to which the list item corresponds
-- SELECT @missing = m.Missing 
-- FROM   Medium m
-- JOIN   ReceiveListItem rli
--   ON   rli.MediumId = m.MediumId
-- WHERE  rli.ItemId = @itemId

-- Verify the status of the item as submitted or transmitted
SELECT @status = Status,
       @mediumId = MediumId
FROM   ReceiveListItem
WHERE  ItemId = @itemId AND
       RowVersion = @rowVersion
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
ELSE BEGIN
   IF @status = 1 BEGIN -- power(4,0)
      RETURN
   END
   ELSE IF @status >= 256 BEGIN -- power(4,1)
      SET @msg = ''Medium on receive list cannot be removed after it has been verified.'' + @msgTag + ''>''
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
SET    Status = 1 -- power(4,0)
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

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'receiveListItem$upd')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.receiveListItem$upd
(
   @itemId int,
   @notes nvarchar(1000),
   @rowVersion rowversion
)
WITH ENCRYPTION
AS
BEGIN
-- OBSOLETE:  The only thing that can change for a receive list item are its notes, and as of
-- 5/20/2005, list items will not longer be using their notes fields.
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
DECLARE @error int

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=P''
SET @tranName = object_name(@@procid) + CAST(@@nestlevel as nvarchar(2))

-- If the status of the item is already verified, then return.  Otherwise,
-- if it is anything besides transmitted, raise error.
SELECT @status = Status
FROM   ReceiveListItem 
WHERE  ItemId = @itemId AND
       RowVersion = @rowVersion
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
ELSE BEGIN
   IF @status = 256 BEGIN -- power(4,4)
      RETURN 0
   END 
   ELSE IF @status != 16 BEGIN -- power(4,2)
      SET @msg = ''Invalid item status value.'' + @msgTag + ''>''
      RAISERROR(@msg,16,1)
      RETURN -100
   END
END

BEGIN TRANSACTION
SAVE TRANSACTION @tranName

-- If the medium in the item was marked as missing, mark it found
UPDATE Medium
SET    Missing = 0
WHERE  Missing = 1 AND
       MediumId = (SELECT MediumId FROM ReceiveListItem WHERE ItemId = @itemId)
SET @error = @@error
IF @error != 0 BEGIN
   ROLLBACK TRANSACTION @tranName
   COMMIT TRANSACTION
   SET @msg = ''Error encountered while removing ''''missing'''' status from medium.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
   EXECUTE error$raise @msg, @error
   RETURN -100
END

-- Upgrade the status of the item to verified
UPDATE ReceiveListItem
SET    Status = 256 -- power(4,4)
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

-------------------------------------------------------------------------------
--
-- receiveListScan$compare
--
-- Compares one or more scans to a receive list.  Returns either two sets of 
-- results: (1) media that were on the list but not in the scan, (2) media that 
-- were in the scan but not on the list.
--
-- When comparing lists against scans, only those media marked as not yet
-- verified will be considered.  All other media are ignored and will not
-- be returned in any result set regardless of whether or not they are present
-- within the scan.
--
-------------------------------------------------------------------------------
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
DECLARE @currentTime as datetime
DECLARE @returnValue as int
DECLARE @lastList as int
DECLARE @rowcount int
DECLARE @itemId as int
DECLARE @listId int
DECLARE @status int
DECLARE @rowNo int
DECLARE @error int
DECLARE @tblVerify table
(
   RowNo int NOT NULL PRIMARY KEY CLUSTERED IDENTITY (1,1),
   SerialNo nvarchar(32) NOT NULL,
   ItemId int NOT NULL,
   RowVersion binary(8) NOT NULL
)

SET NOCOUNT ON

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=P;Call=(Select)''
SET @tranName = object_name(@@procid) + CAST(@@nestlevel as nvarchar(2))

-- Verify that the list exists.  Also, if the list is fully verified or better,
-- then there is no need to compare the list.
SELECT @listId = ListId,
       @status = Status
FROM   ReceiveList
WHERE  ListName = @listName
IF @@rowCount = 0 BEGIN
   SET @msg = ''Receive list not found.'' + @msgTag + ''>''
   RAISERROR(@msg,16,1)
   RETURN -100
END
ELSE IF @status > 64 BEGIN -- power(4,3)
   SET @msg = ''Receive list is already fully verified.'' + @msgTag + ''>''
   RAISERROR(@msg,16,1)
   RETURN -100
END

-- Obtain the first result set of media on the list but not in the scans
SELECT m.SerialNo
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
       WHERE  rl.ListId = @listId OR 
              coalesce(rl.CompositeId,0) = @listId
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
       WHERE  rl.ListId = @listId OR 
              coalesce(rl.CompositeId,0) = @listId) AS scanMedia
  ON   scanMedia.SerialNo = m.SerialNo   
WHERE  rli.Status = 16 AND -- power(4,2)
       scanMedia.SerialNo IS NULL AND
      (rl.ListId = @listId OR coalesce(rl.CompositeId,0) = @listId)
ORDER BY m.SerialNo

-- Obtain the second result set of media in the scans but not on the list
SELECT rlsi.SerialNo
FROM   ReceiveListScanItem rlsi
JOIN   ReceiveListScan rls
  ON   rls.ScanId = rlsi.ScanId
JOIN   ReceiveList rl
  ON   rl.ListId = rls.ListId
LEFT OUTER JOIN
      (SELECT m.SerialNo    -- standalone medium serial numbers
       FROM   Medium m
       JOIN   ReceiveListItem rli
         ON   rli.MediumId = m.MediumId
       JOIN   ReceiveList rl
         ON   rl.ListId = rli.ListId
       WHERE  rli.Status != 1 AND -- power(4,0)
             (rl.ListId = @listId OR 
              coalesce(rl.CompositeId,0) = @listId)
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
              coalesce(rl.CompositeId,0) = @listId) as listMedia
  ON   listMedia.SerialNo = rlsi.SerialNo
WHERE  listMedia.SerialNo IS NULL AND
      (rl.ListId = @listId OR coalesce(rl.CompositeId,0) = @listId)
ORDER BY rlsi.SerialNo

-- Select all the media to be verified
INSERT @tblVerify (SerialNo, ItemId, RowVersion)
SELECT m.SerialNo,
       rli.ItemId,
       rli.RowVersion
FROM   Medium m
JOIN   ReceiveListItem rli
  ON   rli.MediumId = m.MediumId
JOIN   ReceiveList rl
  ON   rl.ListId = rli.ListId
LEFT OUTER JOIN
      (SELECT m.MediumId
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
              WHERE  rl.ListId = @listId OR 
                     coalesce(rl.CompositeId,0) = @listId
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
              WHERE  rl.ListId = @listId OR 
                     coalesce(rl.CompositeId,0) = @listId) AS scanMedia
         ON   scanMedia.SerialNo = m.SerialNo   
       WHERE  rli.Status = 16 AND -- power(4,2)
              scanMedia.SerialNo IS NULL AND
             (rl.ListId = @listId OR coalesce(rl.CompositeId,0) = @listId)) as listDiscrepancies
  ON   listDiscrepancies.MediumId = m.MediumId
WHERE  rli.Status = 16 AND -- power(4,2)
       listDiscrepancies.MediumId IS NULL AND
      (rl.ListId = @listId OR coalesce(rl.CompositeId,0) = @listId)
ORDER BY m.SerialNo

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
   -- Verify the item.
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
SET @lastList = 0
SET @currentTime = cast(convert(nchar(19),getdate(),120) as datetime)
WHILE 1 = 1 BEGIN
   SELECT TOP 1 @lastList = ListId
   FROM   ReceiveList
   WHERE  ListId > @lastList AND
         (ListId = @listId OR CompositeId = @listId)
   ORDER BY ListId ASC
   IF @@rowCount = 0 BEGIN
      BREAK
   END
   ELSE BEGIN
      UPDATE ReceiveListScan
      SET    Compared = @currentTime
      WHERE  ListId = @lastList
      SET @error = @@error
      IF @error != 0 BEGIN
         ROLLBACK TRANSACTION @tranName
         COMMIT TRANSACTION
         SET @msg = ''Error encountered while updating comparison history.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
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

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'receiveListScan$del')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.receiveListScan$del
(
   @scanId int
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

-- Cannot be deleted if compared
IF EXISTS (SELECT 1 FROM ReceiveListScan WHERE ScanId = @scanId AND Compared IS NOT NULL) BEGIN
   SET @msg = ''Cannot delete a compare file after it has been compared against its list.'' + @msgTag + ''>''
   RAISERROR(@msg,16,1)
   RETURN -100
END

-- Begin the transaction
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

-- Delete the scan
DELETE ReceiveListScan
WHERE  ScanId = @scanId
SET @error = @@error
IF @error != 0 BEGIN
   ROLLBACK TRANSACTION @tranName
   COMMIT TRANSACTION
   SET @msg = ''Error encountered while deleting receive list scan.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
   EXECUTE error$raise @msg, @error
   RETURN -100
END

-- Commit and return
COMMIT TRANSACTION
RETURN 0
END
'
)

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'receiveListScan$getById')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.receiveListScan$getById
(
   @id int
)
WITH ENCRYPTION
AS
BEGIN

SET NOCOUNT ON

-- Select the scan
SELECT r.ScanId,
       r.ScanName,
       r.CreateDate,
       coalesce(rl.ListName,'''') as ''ListName'',
       coalesce(convert(nvarchar(19),r.Compared,120),'''') as ''Compared''
FROM   ReceiveListScan r
LEFT OUTER JOIN ReceiveList rl
  ON   rl.ListId = r.ListId
WHERE  r.ScanId = @id

-- Get the scan items
SELECT ItemId,
       SerialNo
FROM   ReceiveListScanItem
WHERE  ScanId = @id
ORDER BY SerialNo

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
   @listName nchar(10)
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
WHERE  rl.ListName = @listName

END
'
)

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'receiveListScan$getByName')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.receiveListScan$getByName
(
   @scanName nvarchar(256)
)
WITH ENCRYPTION
AS
BEGIN

SET NOCOUNT ON

-- Select the scan
SELECT r.ScanId,
       r.ScanName,
       r.CreateDate,
       coalesce(rl.ListName,'''') as ''ListName'',
       coalesce(convert(nvarchar(19),r.Compared,120),'''') as ''Compared''
FROM   ReceiveListScan r
LEFT OUTER JOIN ReceiveList rl
  ON   r.ListId = rl.ListId
WHERE  r.ScanName = @scanName

-- Get the scan items
SELECT ItemId,
       SerialNo
FROM   ReceiveListScanItem
WHERE  ScanId = (SELECT ScanId FROM ReceiveListScan WHERE ScanName = @scanName)
ORDER BY SerialNo

END
'
)

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'receiveListScan$getItems')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.receiveListScan$getItems
(
   @scanId int
)
WITH ENCRYPTION
AS
BEGIN

SET NOCOUNT ON

-- Select the scan items
SELECT ItemId,
       SerialNo
FROM   ReceiveListScanItem
WHERE  ScanId = @scanId
ORDER BY SerialNo Asc

END
'
)

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'receiveListScan$getTable')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.receiveListScan$getTable
WITH ENCRYPTION
AS
BEGIN

SET NOCOUNT ON

-- Select the scan
SELECT r.ScanId,
       r.ScanName,
       r.CreateDate,
       coalesce(rl.ListName,'''') as ''ListName'',
       coalesce(convert(nvarchar(19),r.Compared,120),'''') as ''Compared'',
       i.ItemCount
FROM   ReceiveListScan r
LEFT OUTER JOIN ReceiveList rl
  ON   rl.ListId = r.ListId
JOIN   (SELECT ScanId, count(*) as ''ItemCount'' 
        FROM   ReceiveListScanItem
        GROUP BY ScanId) as i
  ON    i.ScanId = r.ScanId
ORDER BY r.ScanName

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
ELSE IF @status > 64 BEGIN -- power(4,3)
   SET @msg = ''List is already fully verified.'' + @msgTag + ''>''
   RAISERROR(@msg,16,1)
   RETURN -100
END

-- Begin the transaction
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

-- Insert the record
INSERT ReceiveListScan(ScanName, ListId)
VALUES(@scanName, @listId)
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

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'receiveListScanItem$del')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.receiveListScanItem$del
(
   @itemId int
)
WITH ENCRYPTION
AS
BEGIN
DECLARE @msg as nvarchar(255)        -- used to preformat error message
DECLARE @msgTag as nvarchar(255)     -- used to hold first part of error message header
DECLARE @tranName as nvarchar(255)   -- used to hold name of savepoint
DECLARE @error as int

SET NOCOUNT ON

-- Set up the transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=P''
SET @tranName = object_name(@@procid) + CAST(@@nestlevel as nvarchar(2))

-- Cannot be altered if compared
IF EXISTS 
   (
   SELECT 1 
   FROM   ReceiveListScan
   WHERE  ScanId = (SELECT ScanId FROM ReceiveListScanItem WHERE ItemId = @itemId) AND Compared IS NOT NULL
   ) 
BEGIN
   SET @msg = ''Cannot alter a compare file after it has been compared against its list.'' + @msgTag + ''>''
   RAISERROR(@msg,16,1)
   RETURN -100
END

-- Begin the transaction
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

-- Update the item to be ignored
UPDATE ReceiveListScanItem
SET    Ignored = 1
WHERE  ItemId = @itemId
SET @error = @@error
IF @error != 0 BEGIN
   ROLLBACK TRANSACTION @tranName
   COMMIT TRANSACTION
   SET @msg = ''Error encountered while marking a receive list scan item to be ignored.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
   EXECUTE error$raise @msg, @error
   RETURN -100
END

-- Commit and return
COMMIT TRANSACTION
RETURN 0
END
'
)

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'receiveListScanItem$get')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.receiveListScanItem$get
(
   @itemId int
)
WITH ENCRYPTION
AS
BEGIN

SET NOCOUNT ON

-- Select the scan item
SELECT ItemId,
       SerialNo
FROM   ReceiveListScanItem
WHERE  ItemId = @itemId

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
   SET @msg = ''File has already been used in a comparison.'' + @msgTag + ''>''
   RAISERROR(@msg,16,1)
   RETURN -100
END

-- If the list has been fully verified, items may not be inserted
SELECT @status = Status
FROM   ReceiveList rl
JOIN   ReceiveListScan rls
  ON   rls.ListId = rl.ListId
WHERE  rls.ScanId = @scanId
IF @status > 64 BEGIN -- power(4,3)
   SET @msg = ''List is already fully verified.'' + @msgTag + ''>''
   RAISERROR(@msg,16,1)
   RETURN -100
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

-------------------------------------------------------------------------------
--
-- Triggers - Receive List
--
-------------------------------------------------------------------------------
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
DECLARE @lastList int
DECLARE @listName char(10)       -- holds the name of the deleted receive list
DECLARE @rowCount int            -- holds the number of rows in the Deleted table
DECLARE @error int          

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
   IF @@rowCount = 0
      BREAK
   ELSE BEGIN
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
   END
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
   SET @msg = ''Batch insert into receive list table not allowed.'' + @msgTag + ''>''
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
SET @msgUpdate = ''Receive list '' + @listName + '' created''

-- Get the account name
SELECT @account = AccountName
FROM   Account
WHERE  AccountId = (SELECT AccountId FROM Inserted)
IF @@rowcount > 0
   SET @msgUpdate = @msgUpdate + '';Account='' + @account

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
   @msgUpdate,
   dbo.string$GetSpidLogin()
)

SET @error = @@error
IF @error != 0 BEGIN
   SET @msg = ''Error encountered while inserting a receive list audit record.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
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
   SET @msg = ''Status of receive list may not be reduced.'' + @msgTag + ''>''
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
      IF @status = 4  -- power(4,1)
         SET @msgUpdate = ''List '''''' + @listName + '''''' updated;Status=Submitted''
      ELSE IF @status = 16 -- power(4,x)
         SET @msgUpdate = ''List '''''' + @listName + '''''' updated;Status=Transmitted''
      ELSE IF @status = 64 -- power(4,x)
         SET @msgUpdate = ''List '''''' + @listName + '''''' updated;Status=Partially Verified''
      ELSE IF @status = 256 -- power(4,x)
         SET @msgUpdate = ''List '''''' + @listName + '''''' updated;Status=Fully Verified''
      ELSE IF @status = 1024 -- power(4,x)
         SET @msgUpdate = ''List '''''' + @listName + '''''' updated;Status=Cleared''
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
         SET @msg = ''Error encountered while inserting receive list audit record.'' + @msgTag + '';Error='' + cast(@error as nvarchar(9)) + ''>''
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
               SET @msg = ''Error encountered while updating composite receive list status.'' + @msgTag + '';Error='' + cast(@error as nvarchar(9)) + ''>''
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
         ''List '''''' + @listName + '''''' merged into composite '''''' + @compositeName + '''''''',
         dbo.string$GetSpidLogin()
      )
      SET @error = @@error
      IF @error != 0 BEGIN
         SET @msg = ''Error encountered while inserting receive list audit record.'' + @msgTag + '';Error='' + cast(@error as nvarchar(9)) + ''>''
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
         ''List '''''' + @listName + '''''' extracted from composite '''''' + @compositeName + '''''''',
         dbo.string$GetSpidLogin()
      )
      SET @error = @@error
      IF @error != 0 BEGIN
         SET @msg = ''Error encountered while inserting receive list audit record.'' + @msgTag + '';Error='' + cast(@error as nvarchar(9)) + ''>''
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

IF EXISTS(SELECT * FROM sysobjects WHERE name = 'receiveListItem$afterDelete' AND objectproperty(id, 'ExecIsDeleteTrigger' ) = 1) 
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'TRIGGER receiveListItem$afterDelete
ON     ReceiveListItem
WITH ENCRYPTION
AFTER  DELETE
AS
BEGIN
DECLARE @msg nvarchar(255)         -- used to preformat error message
DECLARE @msgTag nvarchar(255)      -- used to hold first part of error message header
DECLARE @msgUpdate nvarchar(4000)  -- used to hold the updated fields
DECLARE @tranName nvarchar(255)    -- used to hold name of savepoint
DECLARE @listName nchar(10)
DECLARE @lastList int
DECLARE @serialNo nvarchar(32)
DECLARE @lastSerial nvarchar(32)
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

-- Begin transaction
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

-- Get the caller login from the spidLogin table
IF len(dbo.string$GetSpidLogin()) = 0 BEGIN
   SET @msg = ''Login not found for auditing purposes.'' + @msgTag + ''>''
   EXECUTE error$raise @msg, 0, @tranName
   RETURN
END

-- For each list, if there are no active items left, delete list.  Else
-- set the status of list.
SET @lastList = 0
WHILE 1 = 1 BEGIN
   SELECT TOP 1 @lastList = d.ListId,
          @rowVersion = rl.RowVersion
   FROM   Deleted d
   JOIN   ReceiveList rl
     ON   rl.ListId = d.ListId
   WHERE  d.ListId > @lastList
   ORDER BY d.ListId ASC
   IF @@rowCount = 0
      BREAK
   ELSE BEGIN
      IF EXISTS(SELECT 1 FROM ReceiveListItem WHERE Status != 1 AND ListId = @lastList) BEGIN -- power(4,0)
          EXECUTE @returnValue = receiveList$setStatus @lastlist, @rowVersion
      END
      ELSE BEGIN
         EXECUTE @returnValue = receiveList$del @lastList, @rowVersion
      END
      IF @returnValue != 0 BEGIN
         ROLLBACK TRANSACTION @tranName
         COMMIT TRANSACTION
         RETURN
      END
   END
END

-- Commit transaction
COMMIT TRANSACTION
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
IF @listStatus >= 16 BEGIN -- power(4,2)
   SET @msg = ''Items cannot be added to a list that has already been transmitted.'' + @msgTag + ''>''
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
   WHERE  rli.Status IN (4,16,256) -- power(4,x)
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
   ''Medium '''''' + @serialNo + '''''' added to receive list'',
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
   WHERE  rli.Status IN (4,16,256) -- power(4,x)
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
         IF @status = 1 BEGIN -- power(4,0)
            SET @msgUpdate = ''Medium '''''' + @serialNo + '''''' removed from list.''
            SET @auditAction = 5
         END
         ELSE IF @status = 256 BEGIN -- power(4,4)
            SET @msgUpdate = ''Medium '''''' + @serialNo + '''''' verified.''
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
   WHERE  i.Status != 1 AND  -- power(4,0)
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
   WHERE  i.Status = 1 AND  -- power(4,0)
          d.Status != 1 AND -- power(4,0)
          i.ListId > @lastList
   ORDER BY i.ListId ASC
   IF @@rowCount = 0
      BREAK
   ELSE BEGIN
      IF EXISTS(SELECT 1 FROM ReceiveListItem WHERE ListId = @lastList AND Status != 1) BEGIN -- power(4,0)
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

IF EXISTS(SELECT * FROM sysobjects WHERE name = 'receiveListScanItem$afterDelete' AND objectproperty(id, 'ExecIsDeleteTrigger' ) = 1) 
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'TRIGGER receiveListScanItem$afterDelete
ON    ReceiveListScanItem
WITH ENCRYPTION
AFTER DELETE
AS
BEGIN
DECLARE @msg nvarchar(255)           -- used to preformat error message
DECLARE @msgTag nvarchar(255)        -- used to hold first part of error message header
DECLARE @tranName as nvarchar(255)   -- used to hold name of savepoint
DECLARE @rowCount int                -- holds the number of rows in the Inserted table
DECLARE @lastScan int
DECLARE @error int            

-- Set up the error message tag
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=T''
SET @tranName = object_name(@@procid) + CAST(@@nestlevel as nvarchar(2))

BEGIN TRANSACTION
SAVE TRANSACTION @tranName

-- Delete any scans that have no records left
SET @lastScan = 0
WHILE 1 = 1 BEGIN
   SELECT DISTINCT TOP 1 @lastScan = d.ScanId
   FROM   Deleted d
   LEFT OUTER JOIN ReceiveListScanItem rlsi
     ON   rlsi.ScanId = d.ScanId
   WHERE  rlsi.ScanId IS NULL AND
          d.ScanId > @lastScan
   ORDER BY d.ScanId ASC
   IF @@rowCount = 0 BEGIN
      BREAK
   END
   ELSE BEGIN
      DELETE ReceiveListScan
      WHERE  ScanId = @lastScan
      SET @error = @@error
      IF @error != 0 BEGIN
         SET @msg = ''Error encountered while deleting empty receive list scan.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
         EXECUTE error$raise @msg, @error, @tranName
         RETURN
      END
   END
END

COMMIT TRANSACTION
END      
'
)

-------------------------------------------------------------------------------
--
-- Stored Procedures - Send List
--
-------------------------------------------------------------------------------
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
   IF @status = 1024 -- power(4,5)
      RETURN 0
   ELSE IF @status IN (16,64) BEGIN -- power(4,x)
      SET @msg = ''Send list has not yet been transmitted.'' + @msgTag + ''>''
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
      WHERE  sli.Status != 1 AND -- power(4,0)
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
         WHERE  MediumId = @mediumId
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
   SET    Status = 1024 -- power(4,5)
   WHERE  Status != 1 AND -- power(4,0)
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
ELSE IF @status >= 256 BEGIN -- power(4,4)
   SET @msg = ''Lists may not be extracted after they have been transmitted.'' + @msgTag + ''>''
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
ORDER BY ListName Asc
END
'
)

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'sendList$getById')
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
FROM   SendList sl
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
   FROM   SendList sl
   JOIN   Account a
     ON   a.AccountId = sl.AccountId
   WHERE  sl.CompositeId = @id
   ORDER BY sl.ListName
END

END
'
)

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'sendList$getByName')
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
FROM   SendList sl
LEFT 
OUTER 
JOIN   Account a
  ON   a.AccountId = sl.AccountId
WHERE  sl.ListName = @listName

-- If the list is a composite then get the child lists as well
SELECT @id = ListId 
FROM   SendList 
WHERE  ListName = @listName

IF EXISTS(SELECT 1 FROM SendList WHERE CompositeId = @id) BEGIN
   SELECT sl.ListId,
          sl.ListName,
          sl.CreateDate,
          sl.Status,
          a.AccountName,
          sl.RowVersion
   FROM   SendList sl
   JOIN   Account a
     ON   a.AccountId = sl.AccountId
   WHERE  sl.CompositeId = @id
   ORDER BY sl.ListName
END

END
'
)

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'sendList$getCases')
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
JOIN   SendList sl
  ON   sl.ListId = sli.ListId
JOIN   MediumType mt
  ON   mt.TypeId = slc.TypeId
WHERE  sl.ListId = @listId OR coalesce(CompositeId,0) = @listId

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
WHERE  sl.Status = 1024 AND 
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
WHERE  sl.Status = 1024 AND 
       sl.AccountId IS NULL AND
       EXISTS(SELECT 1 
              FROM   SendList sl2
              WHERE  CompositeId = sl.ListId AND
                     convert(nchar(10),sl2.CreateDate,120) <= @dateString)
ORDER BY ListName Asc
END
'
)

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'sendList$getItemCount')
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
   JOIN   SendList sl
     ON   sl.ListId = sli.ListId
   WHERE  sli.Status != 1 AND -- power(4,0)
         (sl.ListId = @listId OR sl.CompositeId = @listId)
END
ELSE BEGIN
   SELECT count(*)
   FROM   SendListItem sli
   JOIN   SendList sl
     ON   sl.ListId = sli.ListId
   WHERE  sli.Status = @status AND
         (sl.ListId = @listId OR sl.CompositeId = @listId)
END

END
'
)

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'sendList$getItems')
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
JOIN   SendList sl
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
IF len(ltrim(rtrim(coalesce(@filter,'''')))) > 0 BEGIN
   SET @filter = replace(@filter,''ListName'',''sl.ListName'')
   SET @filter = replace(@filter,''CreateDate'',''sl.CreateDate'')
   SET @filter = replace(@filter,''Status'',''sl.Status'')
   SET @filter = replace(@filter,''AccountName'',''coalesce(a.AccountName,'''''''')'')
   SET @where = @where + '' AND ('' + @filter + '')''
END

-- Construct the fields string
SET @fields2 = ''ListId, ListName, CreateDate, Status, AccountName, RowVersion''
SET @fields1 = ''sl.ListId, sl.ListName, sl.CreateDate, sl.Status, coalesce(a.AccountName,'''''''') as ''''AccountName'''', sl.RowVersion''

-- Construct the tables string
SET @tables = ''SendList sl LEFT OUTER JOIN Account a ON sl.AccountId = a.AccountId''

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
   WHERE  ListId IN (@listId1,@listId2) AND Status >= 256 -- power(4,4)
   )
BEGIN
   SET @msg = ''Only lists that have not yet been transmitted may be merged.'' + @msgTag + ''>''
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
IF @accountId1 IS NOT NULL AND @accountId1 IS NOT NULL BEGIN
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
WHERE  ListId = @listId AND Status != 1 -- power(4,0)

-- If no status exists, return
IF @status IS NULL RETURN 0

-- If the minimum item status is submitted, check to see if any items have been
-- verified.  If they have, set the list status to partially verified.  Otherwise
-- leave the status as the minimum item status.
IF @status = 4 BEGIN  -- power (4,1)
  IF EXISTS (SELECT 1 FROM SendListItem WHERE ListId = @listId AND Status > 4) BEGIN
     SET @status = 16  -- power (4,2)
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
DECLARE @lastItem int
DECLARE @rowCount int
DECLARE @status int
DECLARE @error int

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=P''
SET @tranName = object_name(@@procid) + CAST(@@nestlevel as nvarchar(2))

-- If the status of the list is already transmitted, then return.  Otherwise,
-- if it is anything besides submitted, raise error.
SELECT @status = Status
FROM   SendList
WHERE  ListId = @listId AND
       RowVersion = @rowVersion
IF @@rowCount = 0 BEGIN
   IF EXISTS(SELECT 1 FROM SendList WHERE ListId = @listId) BEGIN
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
   IF @status IN (256,1024) BEGIN -- power(4,x)
      RETURN 0
   END 
   ELSE IF @status != 64 BEGIN -- power(4,3)
      SET @msg = ''Send list must be completely verified to be transmitted.'' + @msgTag + ''>''
      RAISERROR(@msg,16,1)
      RETURN -100
   END
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
   WHERE  sli.Status != 1 AND -- power(4,0)
          sli.ItemId > @lastItem AND
         (sl.ListId = @listId OR sl.CompositeId = @listId)
   ORDER BY sli.ItemId ASC
   IF @@rowCount = 0 BEGIN
      BREAK
   END
   ELSE BEGIN
      UPDATE SendListItem
      SET    Status = 256 -- power(4,4)
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

-- Verify that the case does not appear on any lists that have been 
-- transmitted or cleared.
IF EXISTS
   (
   SELECT 1
   FROM   SendListCase slc
   JOIN   SendListItemCase slic
     ON   slic.CaseId = slc.CaseId
   JOIN   SendListItem sli
     ON   sli.ItemId = slic.ItemId
   WHERE  slc.CaseId = @caseId AND sli.Status IN (256,1024) -- power(4,x)
   )
BEGIN
   SET @msg = ''Send list case may not be altered after being tranmsmitted or cleared.'' + @msgTag + ''>''
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

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'sendListCase$getById')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.sendListCase$getById
(
   @id int
)
WITH ENCRYPTION
AS
BEGIN

SET NOCOUNT ON

-- Select the list
SELECT slc.CaseId,
       mt.TypeName,
       slc.SerialNo as ''CaseName'',
       coalesce(convert(nvarchar(10),slc.ReturnDate,120),'''') as ''ReturnDate'',
       slc.Sealed,
       slc.Notes,
       slc.RowVersion
FROM   SendListCase slc
JOIN   MediumType mt
  ON   mt.TypeId = slc.TypeId
WHERE  slc.CaseId = @id

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
      SET @msg = ''A cleared send list case may not be altered.'' + @msgTag + ''>''
      RAISERROR(@msg,16,1)
      RETURN -100
   END
END

-- Verify that the case does not appear on any lists that have been 
-- transmitted or cleared.
IF EXISTS
   (
   SELECT 1
   FROM   SendListCase slc
   JOIN   SendListItemCase slic
     ON   slic.CaseId = slc.CaseId
   JOIN   SendListItem sli
     ON   sli.ItemId = slic.ItemId
   WHERE  slc.CaseId = @caseId AND sli.Status IN (256,1024) -- power(4,x)
   )
BEGIN
   SET @msg = ''Send list case may not be altered after being tranmsmitted or cleared.'' + @msgTag + ''>''
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
WHERE  TypeName = @typeName
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
ELSE IF @listStatus NOT IN (4,16,64) BEGIN -- power(4,x)
   SET @msg = ''Send list may not be altered after it has been transmitted.'' + @msgTag + ''>''
   RAISERROR(@msg,16,1)
   RETURN -100
END

-- The initial status must be either submitted or verified
IF @initialStatus NOT IN (4,64) BEGIN -- power(4,x)
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
   WHERE  Status IN (4,64,256) AND  -- power(4,x)
          MediumId = @mediumId
   IF @@rowCount > 0 BEGIN
      IF @priorStatus IN (64,256) BEGIN -- power(4,x)
         ROLLBACK TRANSACTION @tranName
         COMMIT TRANSACTION
         SET @msg = ''Medium '''''' + @serialNo + '''''' has been verified on an active send list.'' + @msgTag + ''>''
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
      WHERE  sli.Status = 1 AND  -- power(4,0)
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

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'sendListItem$get')
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
WHERE  sli.ItemId = @itemId

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
IF len(ltrim(rtrim(coalesce(@filter,'''')))) > 0 BEGIN
	SET @filter = replace(@filter,''SerialNo'',''m.SerialNo'')
	SET @filter = replace(@filter,''Account'',''a.AccountName'')
	SET @filter = replace(@filter,''ReturnDate'', ''coalesce(c.ReturnDate,coalesce(convert(nvarchar(10),sli.ReturnDate,120),''''''''))'')
	SET @filter = replace(@filter,''Status'',''sli.Status'')
	SET @filter = replace(@filter,''CaseName'', ''coalesce(c.CaseName,'''''''')'')
   SET @where = @where + '' AND ('' + @filter + '')''
END

-- Construct the fields string
SET @fields2 = ''ItemId, SerialNo, AccountName, Status, ReturnDate, CaseName, Notes, RowVersion''
SET @fields1 = ''sli.ItemId, m.SerialNo, a.AccountName, sli.Status, coalesce(c.ReturnDate,coalesce(convert(nvarchar(10),sli.ReturnDate,120),'''''''')) as ''''ReturnDate'''', coalesce(c.CaseName,'''''''') as ''''CaseName'''', m.Notes, sli.RowVersion''

-- Construct the tables string
SET @tables = ''SendListItem sli JOIN SendList sl ON sl.ListId = sli.ListId JOIN Medium m ON m.MediumId = sli.MediumId JOIN Account a ON a.AccountId = m.AccountId LEFT OUTER JOIN (SELECT slc.SerialNo as ''''CaseName'''', slic.ItemId as ''''ItemId'''', case slc.Sealed when 0 then null else coalesce(convert(nvarchar(10),slc.ReturnDate,120),'''''''') end as ''''ReturnDate'''' FROM SendListCase slc JOIN SendListItemCase slic ON slic.CaseId = slc.CaseId JOIN SendListItem sli ON sli.ItemId = slic.ItemId JOIN SendList sl ON sl.ListId = sli.ListId WHERE sl.ListId = '' + cast(@listId as nvarchar(50)) + '' OR sl.CompositeId = '' + cast(@listId as nvarchar(50)) + '') as c ON c.ItemId = sli.ItemId''

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
IF @initialStatus NOT IN (4,256) BEGIN -- power(4,x)
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
             sli.Status IN (4,64,256) AND -- power(4,x)
             slc.SerialNo = @caseName AND
             CHARINDEX(sl.ListName,@batchLists) = 0
      )
   BEGIN
      ROLLBACK TRANSACTION @tranName
      COMMIT TRANSACTION
      SET @msg = ''Case '''''' + @caseName + '''''' actively appears on list outside of batch.'' + @msgTag + ''>''
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
   WHERE  sli.Status IN (4,64,256) AND  -- power(4,x)
          sli.MediumId = @mediumId AND
          CHARINDEX(sl.ListName,@batchLists) = 0
   IF @@rowCount > 0 BEGIN
      IF @priorStatus IN (64,256) BEGIN -- power(4,x)
         ROLLBACK TRANSACTION @tranName
         COMMIT TRANSACTION
         SET @msg = ''Medium '''''' + @serialNo + '''''' has been verified on another active send list.'' + @msgTag + ''>''
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
-- to submitted.)
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
         IF @status != 1 BEGIN -- power(4,0)
            ROLLBACK TRANSACTION @tranName
            COMMIT TRANSACTION
            SET @msg = ''Medium '''''' + @serialNo + '''''' is already on a list within this batch.'' + @msgTag + ''>''
            RAISERROR(@msg,16,1)
            RETURN -100
         END
         ELSE BEGIN
            UPDATE SendListItem
            SET    Status = 4, -- power(4,1)
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
DECLARE @returnValue int
DECLARE @currentCase nvarchar(32)
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
IF EXISTS
   (
   SELECT 1 
   FROM   SendListItem
   WHERE  ItemId = @itemId AND Status != 4 -- power(4,1)
   )
BEGIN
   SET @msg = ''Changes may not be made to a send list item after it has been verified.'' + @msgTag + ''>''
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
DECLARE @error int

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=P''
SET @tranName = object_name(@@procid) + CAST(@@nestlevel as nvarchar(2))

-- If the status of the item is already verified, then return.  Otherwise,
-- if it is anything besides submitted, raise error.
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
   IF @status = 64 BEGIN -- power(4,3)
      RETURN 0
   END 
   ELSE IF @status != 4 BEGIN -- power(4,1)
      SET @msg = ''Invalid status value.'' + @msgTag + ''>''
      RAISERROR(@msg,16,1)
      RETURN -100
   END
END

-- Upgrade the status of the item to verified
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

UPDATE SendListItem
SET    Status = 64 -- power(4,3)
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

-------------------------------------------------------------------------------
--
-- sendListScan$compare
--
-- Compares one or more scans to a send list.  Always returns three sets of 
-- results: (1) media that were on the list but not in the scan, (2) media that 
-- were in the scan but not on the list, and (3) media that were both in the 
-- list and on the scan but differed on the name of the associated case.
--
-- When comparing lists against scans, only those media marked as not yet
-- verified will be considered.  All other media are ignored and will not
-- be returned in any result set regardless of whether or not they are present
-- within the scan.
--
-------------------------------------------------------------------------------
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
DECLARE @lastSerial as nvarchar(32)
DECLARE @rowVersion as rowversion
DECLARE @currentTime as datetime
DECLARE @returnValue as int
DECLARE @rowcount as int
DECLARE @lastList as int
DECLARE @itemId as int
DECLARE @listId int
DECLARE @status int
DECLARE @error int
DECLARE @rowNo int
DECLARE @tblVerify table
(
   RowNo int NOT NULL PRIMARY KEY CLUSTERED IDENTITY (1,1),
   SerialNo nvarchar(32) NOT NULL,
   ItemId int NOT NULL,
   RowVersion binary(8) NOT NULL
)

SET NOCOUNT ON

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=P''
SET @tranName = object_name(@@procid) + CAST(@@nestlevel as nvarchar(2))

-- Verify that the list exists.  Also, if the list is fully verified or better,
-- then there is no need to compare the list.
SELECT @listId = ListId,
       @status = Status
FROM   SendList
WHERE  ListName = @listName
IF @@rowCount = 0 BEGIN
   SET @msg = ''Send list not found.'' + @msgTag + ''>''
   RAISERROR(@msg,16,1)
   RETURN -100
END
ELSE IF @status > 16 BEGIN -- power(4,2)
   SET @msg = ''Send list is already fully verified.'' + @msgTag + ''>''
   RAISERROR(@msg,16,1)
   RETURN -100
END

-- Obtain the first result set of media on the list but not in the scans
SELECT m.SerialNo
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
       WHERE  sl.ListId = @listId OR 
              coalesce(sl.CompositeId,0) = @listId) as scanMedia
  ON   scanMedia.SerialNo = m.SerialNo   
WHERE  sli.Status = 4 AND -- power(4,1)
       scanMedia.SerialNo IS NULL AND
      (sl.ListId = @listId OR coalesce(sl.CompositeId,0) = @listId)
ORDER BY m.SerialNo

-- Obtain the second result set of media in the scans but not on the list
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
       WHERE  sli.Status != 1 AND -- power(4,0)
             (sl.ListId = @listId OR 
              coalesce(sl.CompositeId,0) = @listId)) as listMedia
  ON   listMedia.SerialNo = slsi.SerialNo
WHERE  listMedia.SerialNo IS NULL AND
      (sl.ListId = @listId OR coalesce(sl.CompositeId,0) = @listId)
ORDER BY slsi.SerialNo

-- Obtain the third result set of differing cases.  We have to do a little
-- more work here, because a tape may be in the wrong case on one scan but
-- in the right case in another.  Since it is correct in the second scan,
-- we have to make sure not to include that medium in the result set.  So
-- what we really want to do is get the media from the list that do not 
-- have a serial number/case name combination that matches any of the scan 
-- entries.  Also, for those media, we only want to get one scan case (there
-- may be more than one scan entry with a particular medium, and they may
-- have different case names).
SELECT m.SerialNo,
       isnull(listCases.CaseName,'''') as ''ListCase'',
       minScanCase.CaseName as ''ScanCase''
FROM   Medium m
JOIN   SendListItem sli
  ON   sli.MediumId = m.MediumId
JOIN   SendList sl
  ON   sl.ListId = sli.ListId
LEFT OUTER JOIN   -- Gets the list case name
      (SELECT slic.ItemId, slc.SerialNo as ''CaseName''
       FROM   SendListItemCase slic
       JOIN   SendListCase slc
         ON   slc.CaseId = slic.CaseId) as listCases
  ON   listCases.ItemId = sli.ItemId
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
                ON   slic.CaseId = slc.CaseId) as listCases
         ON   listCases.ItemId = sli.ItemId
       WHERE  sl.ListId = sls.ListId AND
              coalesce(listCases.CaseName,'''') = slsi.CaseName AND
             (sl.ListId = @listId OR coalesce(sl.CompositeId,0) = @listId)) as sameCases
  ON   sameCases.SerialNo = m.SerialNo
JOIN  (SELECT   slsi.SerialNo,        -- Makes sure we only get one scan case per serial number
                min(slsi.CaseName) as ''CaseName''
       FROM     SendListScanItem slsi
       JOIN     SendListScan sls
         ON     sls.ScanId = slsi.ScanId
       JOIN     SendList sl
         ON     sl.ListId = sls.ListId
       WHERE   (sl.ListId = @listId OR coalesce(sl.CompositeId,0) = @listId) 
       GROUP BY slsi.SerialNo) as minScanCase
  ON   minScanCase.SerialNo = m.SerialNo
WHERE  sli.Status = 4 AND -- power(4,1)
       sameCases.SerialNo IS NULL AND
      (sl.ListId = @listId OR coalesce(sl.CompositeId,0) = @listId)


-- Select all the media to be verified
INSERT @tblVerify (SerialNo, ItemId, RowVersion)
SELECT m.SerialNo,
       sli.ItemId,
       sli.RowVersion
FROM   Medium m
JOIN   SendListItem sli
  ON   sli.MediumId = m.MediumId
JOIN   SendList sl
  ON   sl.ListId = sli.ListId
LEFT OUTER JOIN
      (SELECT m.MediumId as ''MediumId'' -- result #1
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
              WHERE  sl.ListId = @listId OR 
                     coalesce(sl.CompositeId,0) = @listId) as scanMedia
         ON   scanMedia.SerialNo = m.SerialNo   
       WHERE  sli.Status = 4 AND -- power(4,1)
              scanMedia.SerialNo IS NULL AND
             (sl.ListId = @listId OR coalesce(sl.CompositeId,0) = @listId)
       
       UNION

       SELECT m.MediumId -- result #3 (we don''t need result #2)
       FROM   Medium m
       JOIN   SendListItem sli
         ON   sli.MediumId = m.MediumId
       JOIN   SendList sl
         ON   sl.ListId = sli.ListId
       LEFT OUTER JOIN   -- Gets the list case name
             (SELECT slic.ItemId, slc.SerialNo as ''CaseName''
              FROM   SendListItemCase slic
              JOIN   SendListCase slc
                ON   slc.CaseId = slic.CaseId) as listCases
         ON   listCases.ItemId = sli.ItemId
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
                       ON   slic.CaseId = slc.CaseId) as listCases
                ON   listCases.ItemId = sli.ItemId
              WHERE  sl.ListId = sls.ListId AND
                     coalesce(listCases.CaseName,'''') = slsi.CaseName AND
                    (sl.ListId = @listId OR coalesce(sl.CompositeId,0) = @listId)) as sameCases
         ON   sameCases.SerialNo = m.SerialNo
       JOIN  (SELECT   slsi.SerialNo,        -- Makes sure we only get one scan case per serial number
                       min(slsi.CaseName) as ''CaseName''
              FROM     SendListScanItem slsi
              JOIN     SendListScan sls
                ON     sls.ScanId = slsi.ScanId
              JOIN     SendList sl
                ON     sl.ListId = sls.ListId
              WHERE   (sl.ListId = @listId OR coalesce(sl.CompositeId,0) = @listId) 
              GROUP BY slsi.SerialNo) as minScanCase
         ON   minScanCase.SerialNo = m.SerialNo
       WHERE  sli.Status = 4 AND -- power(4,1)
              sameCases.SerialNo IS NULL AND
             (sl.ListId = @listId OR coalesce(sl.CompositeId,0) = @listId)) as listDiscrepancies
  ON   listDiscrepancies.MediumId = m.MediumId
WHERE  sli.Status = 4 AND -- power(4,1)
       listDiscrepancies.MediumId IS NULL AND
      (sl.ListId = @listId OR coalesce(sl.CompositeId,0) = @listId)
ORDER BY m.SerialNo ASC

-- Remember the rowcount
SELECT @rowNo = 1, @rowcount = @@rowcount

-- Begin transaction
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

WHILE @rowNo <= @rowCount BEGIN
   SELECT @lastSerial = SerialNo,
          @itemId = ItemId,
          @rowVersion = RowVersion
   FROM   @tblVerify
   WHERE  RowNo = @rowNo
   -- Verify the item.
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
SET @lastList = 0
SET @currentTime = cast(convert(nchar(19),getdate(),120) as datetime)
WHILE 1 = 1 BEGIN
   SELECT TOP 1 @lastList = ListId
   FROM   SendList
   WHERE  ListId > @lastList AND
         (ListId = @listId OR CompositeId = @listId)
   ORDER BY ListId ASC
   IF @@rowCount = 0 BEGIN
      BREAK
   END
   ELSE BEGIN
      UPDATE SendListScan
      SET    Compared = @currentTime
      WHERE  ListId = @lastList
      SET @error = @@error
      IF @error != 0 BEGIN
         ROLLBACK TRANSACTION @tranName
         COMMIT TRANSACTION
         SET @msg = ''Error encountered while updating comparison history.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
         EXECUTE error$raise @msg,@error
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

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'sendListScan$del')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.sendListScan$del
(
   @scanId int
)
WITH ENCRYPTION
AS
BEGIN
DECLARE @msg as nvarchar(255)        -- used to preformat error message
DECLARE @msgTag as nvarchar(255)     -- used to hold first part of error message header
DECLARE @tranName as nvarchar(255)   -- used to hold name of savepoint
DECLARE @mediumId int
DECLARE @returnValue int
DECLARE @error as int

SET NOCOUNT ON

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=P''
SET @tranName = object_name(@@procid) + CAST(@@nestlevel as nvarchar(2))

-- Cannot be deleted if compared
IF EXISTS (SELECT 1 FROM SendListScan WHERE ScanId = @scanId AND Compared IS NOT NULL) BEGIN
   SET @msg = ''Cannot delete a compare file after it has been compared against its list.'' + @msgTag + ''>''
   RAISERROR(@msg,16,1)
   RETURN -100
END

-- Begin the transaction
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

-- Delete the scan
DELETE SendListScan
WHERE  ScanId = @scanId
SET @error = @@error
IF @error != 0 BEGIN
   ROLLBACK TRANSACTION @tranName
   COMMIT TRANSACTION
   SET @msg = ''Error encountered while deleting send list scan.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
   EXECUTE error$raise @msg, @error
   RETURN -100
END

-- Commit and return
COMMIT TRANSACTION
RETURN 0
END
'
)

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'sendListScan$getById')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.sendListScan$getById
(
   @id int
)
WITH ENCRYPTION
AS
BEGIN

SET NOCOUNT ON

-- Select the scan
SELECT s.ScanId,
       s.ScanName,
       s.CreateDate,
       coalesce(sl.ListName,'''') as ''ListName'',
       coalesce(convert(nvarchar(19),s.Compared,120),'''') as ''Compared''
FROM   SendListScan s
LEFT OUTER JOIN SendList sl
  ON   sl.ListId = s.ListId
WHERE  s.ScanId = @id

-- Get the scan items
SELECT ItemId,
       SerialNo,
       CaseName
FROM   SendListScanItem
WHERE  ScanId = @id
ORDER BY SerialNo

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
   @listName nchar(10)
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
WHERE  sl.ListName = @listName

END
'
)

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'sendListScan$getByName')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.sendListScan$getByName
(
   @scanName nvarchar(256)
)
WITH ENCRYPTION
AS
BEGIN

SET NOCOUNT ON

-- Select the scan
SELECT s.ScanId,
       s.ScanName,
       s.CreateDate,
       coalesce(sl.ListName,'''') as ''ListName'',
       coalesce(convert(nvarchar(19),s.Compared,120),'''') as ''Compared''
FROM   SendListScan s
LEFT OUTER JOIN SendList sl
  ON   s.ListId = sl.ListId
WHERE  s.ScanName = @scanName

-- Get the scan items
SELECT ItemId,
       SerialNo,
       CaseName
FROM   SendListScanItem
WHERE  ScanId = (SELECT ScanId FROM SendListScan WHERE ScanName = @scanName)
ORDER BY SerialNo

END
'
)

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'sendListScan$getItems')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.sendListScan$getItems
(
   @scanId int
)
WITH ENCRYPTION
AS
BEGIN

SET NOCOUNT ON

-- Select the scan items
SELECT ItemId,
       SerialNo,
       CaseName
FROM   SendListScanItem
WHERE  ScanId = @scanId
ORDER BY SerialNo Asc

END
'
)

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'sendListScan$getTable')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.sendListScan$getTable
WITH ENCRYPTION
AS
BEGIN

SET NOCOUNT ON

-- Select the scan
SELECT s.ScanId,
       s.ScanName,
       s.CreateDate,
       coalesce(sl.ListName,'''') as ''ListName'',
       coalesce(convert(nvarchar(19),s.Compared,120),'''') as ''Compared'',
       i.ItemCount
FROM   SendListScan s
LEFT OUTER JOIN SendList sl
  ON   sl.ListId = s.ListId
JOIN   (SELECT ScanId, count(*) as ''ItemCount'' 
        FROM   SendListScanItem
        GROUP BY ScanId) as i
  ON    i.ScanId = s.ScanId
ORDER BY s.ScanName

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
FROM   SendList
WHERE  ListName = @listName
IF @@rowCount = 0 BEGIN
   SET @msg = ''List not found.'' + @msgTag + ''>''
   RAISERROR(@msg,16,1)
   RETURN -100
END
ELSE IF @status > 16 BEGIN -- power(4,2)
   SET @msg = ''List is already fully verified.'' + @msgTag + ''>''
   RAISERROR(@msg,16,1)
   RETURN -100
END

-- Begin the transaction
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

-- Insert the record
INSERT SendListScan (ScanName, ListId)
VALUES (@scanName, @listId)

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

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'sendListScanItem$get')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.sendListScanItem$get
(
   @itemId int
)
WITH ENCRYPTION
AS
BEGIN

SET NOCOUNT ON

-- Select the scan items
SELECT ItemId,
       SerialNo,
       CaseName
FROM   SendListScanItem
WHERE  ItemId = @itemId

END
'
)

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'sendListScanItem$del')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.sendListScanItem$del
(
   @itemId int
)
WITH ENCRYPTION
AS
BEGIN
DECLARE @msg as nvarchar(255)        -- used to preformat error message
DECLARE @msgTag as nvarchar(255)     -- used to hold first part of error message header
DECLARE @tranName as nvarchar(255)   -- used to hold name of savepoint
DECLARE @error as int

SET NOCOUNT ON

-- Set up the transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=P''
SET @tranName = object_name(@@procid) + CAST(@@nestlevel as nvarchar(2))

-- Cannot be altered if compared
IF EXISTS 
   (
   SELECT 1 
   FROM   SendListScan
   WHERE  ScanId = (SELECT ScanId FROM SendListScanItem WHERE ItemId = @itemId) AND Compared IS NOT NULL
   ) 
BEGIN
   SET @msg = ''Cannot alter a compare file after it has been compared against its list.'' + @msgTag + ''>''
   RAISERROR(@msg,16,1)
   RETURN -100
END

-- Begin the transaction
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

-- Update the item to be ignored
UPDATE SendListScanItem
SET    Ignored = 1
WHERE  ItemId = @itemId
SET @error = @@error
IF @error != 0 BEGIN
   ROLLBACK TRANSACTION @tranName
   COMMIT TRANSACTION
   SET @msg = ''Error encountered while marking send list compare item as ignored.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
   EXECUTE error$raise @msg, @error
   RETURN -100
END

-- Commit and return
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
   SET @msg = ''File has already been used in a comparison.'' + @msgTag + ''>''
   RAISERROR(@msg,16,1)
   RETURN -100
END

-- If the list against which has been fully verified, items may not be inserted
SELECT @status = Status
FROM   SendList sl
JOIN   SendListScan sls
  ON   sls.ListId = sl.ListId
WHERE  sls.ScanId = @scanId
IF @status > 16 BEGIN -- power(4,2)
   SET @msg = ''List is already fully verified.'' + @msgTag + ''>''
   RAISERROR(@msg,16,1)
   RETURN -100
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

-------------------------------------------------------------------------------
--
-- Triggers - Send List
--
-------------------------------------------------------------------------------
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
DECLARE @listName char(10)       -- holds the name of the deleted send list
DECLARE @rowCount int            -- holds the number of rows in the Deleted table
DECLARE @action int          
DECLARE @error int          

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
   IF @@rowCount = 0
      BREAK
   ELSE BEGIN
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
   END
END

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
   SET @msg = ''Batch insert into send list table not allowed.'' + @msgTag + ''>''
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
SET @msgUpdate = ''Send list '' + @listName + '' created''

-- Get the account name
SELECT @account = AccountName
FROM   Account
WHERE  AccountId = (SELECT AccountId FROM Inserted)
IF @@rowcount > 0 SET @msgUpdate = @msgUpdate + '';Account='' + @account

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
   SET @msg = ''Error encountered while inserting a new send list audit record.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
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

-- If the list has been transmitted, then the status cannot be reduced
IF EXISTS
   (
   SELECT 1
   FROM   Deleted d
   JOIN   Inserted i
     ON   i.ListId = d.ListId
   WHERE  d.Status >= 256 AND i.Status < d.Status -- power(4,4)
   )
BEGIN
   SET @msg = ''Status of transmitted send list may not be reduced.'' + @msgTag + ''>''
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
      IF @status = 4  -- power(4,1)
         SET @msgUpdate = ''List '''''' + @listName + '''''' updated;Status=Submitted''
      ELSE IF @status = 16 -- power(4,x)
         SET @msgUpdate = ''List '''''' + @listName + '''''' updated;Status=Partially Verified''
      ELSE IF @status = 64 -- power(4,x)
         SET @msgUpdate = ''List '''''' + @listName + '''''' updated;Status=Fully Verified''
      ELSE IF @status = 256 -- power(4,x)
         SET @msgUpdate = ''List '''''' + @listName + '''''' updated;Status=Transmitted''
      ELSE IF @status = 1024 -- power(4,x)
         SET @msgUpdate = ''List '''''' + @listName + '''''' updated;Status=Cleared''
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
         2,
         @msgUpdate,
         dbo.string$GetSpidLogin()
      )
      SET @error = @@error
      IF @error != 0 BEGIN
         SET @msg = ''Error encountered while inserting new send list audit record.'' + @msgTag + '';Error='' + cast(@error as nvarchar(9)) + ''>''
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
               SET @msg = ''Error encountered while updating composite send list status.'' + @msgTag + '';Error='' + cast(@error as nvarchar(9)) + ''>''
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
         ''List '''''' + @listName + '''''' merged into composite '''''' + @compositeName + '''''''',
         dbo.string$GetSpidLogin()
      )
      SET @error = @@error
      IF @error != 0 BEGIN
         SET @msg = ''Error encountered while inserting new send list audit record.'' + @msgTag + '';Error='' + cast(@error as nvarchar(9)) + ''>''
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
         ''List '''''' + @listName + '''''' extracted from composite '''''' + @compositeName + '''''''',
         dbo.string$GetSpidLogin()
      )
      SET @error = @@error
      IF @error != 0 BEGIN
         SET @msg = ''Error encountered while inserting new send list audit record.'' + @msgTag + '';Error='' + cast(@error as nvarchar(9)) + ''>''
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
   SET @msg = ''Batch insert into send list case table not allowed.'' + @msgTag + ''>''
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
   SET @msg = ''There is already a case named '''''' + @caseName + '''''' on an active send list.'' + @msgTag + ''>''
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
   ''Case '''''' + @caseName + '''''' created;Sealed=False;Type='' + @typeName,
   dbo.string$GetSpidLogin()
)

SET @error = @@error
IF @error != 0 BEGIN
   SET @msg = ''Error encountered while inserting a new send list case audit record.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
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

SET @rowCount = @@rowcount
IF @rowCount = 0 RETURN

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=T''
SET @tranName = object_name(@@procid) + CAST(trigger_nestlevel(@@procid) as nvarchar(2))

-- Begin transaction
BEGIN TRANSACTION
SAVE TRANSACTION @tranName
      
-- Get the caller login from the spidLogin table
IF len(dbo.string$GetSpidLogin()) = 0 BEGIN
   SET @msg = ''Login not found for auditing purposes.'' + @msgTag + ''>''
   EXECUTE error$raise @msg, 0, @tranName
   RETURN
END

SET @lastCase = 0
WHILE 1 = 1 BEGIN
   SELECT TOP 1 @lastCase = CaseId
   FROM   Deleted
   WHERE  CaseId > @lastCase
   ORDER BY CaseId ASC
   IF @@rowCount = 0 BREAK

   -- Construct the update message
   SELECT @serialNo = SerialNo FROM Deleted WHERE CaseId = @lastCase
   SELECT @msgUpdate = ''Case '''''' + @serialNo + '''''' updated''
   
   SELECT @caseName = i.SerialNo 
   FROM   Inserted i
   JOIN   Deleted d
     ON   d.CaseId = i.CaseId
   WHERE  d.SerialNo != i.SerialNo AND d.CaseId = @lastCase
   IF @@rowCount > 0 SET @msgUpdate = @msgUpdate + '';Name='' + @caseName
   
   SELECT @sealed = case i.Sealed when 1 then ''TRUE'' else ''FALSE'' end
   FROM   Inserted i
   JOIN   Deleted d
     ON   d.CaseId = i.CaseId
   WHERE  d.Sealed != i.Sealed AND d.CaseId = @lastCase
   IF @@rowCount > 0 SET @msgUpdate = @msgUpdate + '';Sealed='' + @sealed
   
   SELECT @typeName = m.TypeName
   FROM   MediumType m
   JOIN   Inserted i
     ON   i.TypeId = m.TypeId
   JOIN   Deleted d
     ON   d.CaseId = i.CaseId
   WHERE  d.TypeId != i.TypeId AND d.CaseId = @lastCase
   IF @@rowCount > 0 SET @msgUpdate = @msgUpdate + '';Type='' + @typeName
   
   SELECT @returnDate = coalesce(convert(nchar(10),i.ReturnDate,120),''(None)'')
   FROM   Inserted i
   JOIN   Deleted d
     ON   d.CaseId = i.CaseId
   WHERE  d.ReturnDate != i.ReturnDate AND d.CaseId = @lastCase
   IF @@rowCount > 0 SET @msgUpdate = @msgUpdate + '';ReturnDate='' + @returnDate
   
   -- Make sure that the case does not exist in the sealed case table
   IF EXISTS(SELECT 1 FROM SealedCase WHERE SerialNo = @caseName) BEGIN
      SET @msg = ''Sealed case '''''' + @caseName + '''''' already resides at the vault.'' + @msgTag + ''>''
      EXECUTE error$raise @msg, 0, @tranName
      RETURN
   END
   
   -- Make sure that the case is only active once
   IF EXISTS(SELECT 1 FROM SendListCase WHERE SerialNo = @caseName AND Cleared = 0 AND CaseId != @lastCase) BEGIN
      SET @msg = ''There is already a case named '''''' + @caseName + '''''' on an active send list.'' + @msgTag + ''>''
      EXECUTE error$raise @msg, 0, @tranName
      RETURN
   END
   
   -- Insert audit record
   IF CHARINDEX('';'',@msgUpdate) > 0 BEGIN
      INSERT XSendListCase
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
         @msgUpdate,
         dbo.string$GetSpidLogin()
      )
      
      SET @error = @@error
      IF @error != 0 BEGIN
         SET @msg = ''Error encountered while inserting a new send list case audit record.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
         EXECUTE error$raise @msg, @error, @tranName
         RETURN
      END
   END
END

-- Commit transaction      
COMMIT TRANSACTION
END
'
)

IF EXISTS(SELECT * FROM sysobjects WHERE name = 'sendListItem$afterDelete' AND objectproperty(id, 'ExecIsDeleteTrigger' ) = 1) 
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'TRIGGER sendListItem$afterDelete
ON     SendListItem
WITH ENCRYPTION
AFTER  DELETE
AS
BEGIN
DECLARE @msg nvarchar(255)         -- used to preformat error message
DECLARE @msgTag nvarchar(255)      -- used to hold first part of error message header
DECLARE @msgUpdate nvarchar(4000)  -- used to hold the updated fields
DECLARE @tranName nvarchar(255)    -- used to hold name of savepoint
DECLARE @listName nchar(10)
DECLARE @lastList int
DECLARE @serialNo nvarchar(32)
DECLARE @lastSerial nvarchar(32)
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

-- Begin transaction
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

-- Get the caller login from the spidLogin table
IF len(dbo.string$GetSpidLogin()) = 0 BEGIN
   SET @msg = ''Login not found for auditing purposes.'' + @msgTag + ''>''
   EXECUTE error$raise @msg, 0, @tranName
   RETURN
END

-- For each list, if there are no active items left, delete list.  Else
-- set the status of list.
SET @lastList = 0
WHILE 1 = 1 BEGIN
   SELECT TOP 1 @lastList = d.ListId,
          @rowVersion = sl.RowVersion
   FROM   Deleted d
   JOIN   SendList sl
     ON   sl.ListId = d.ListId
   WHERE  d.ListId > @lastList
   ORDER BY d.ListId ASC
   IF @@rowCount = 0
      BREAK
   ELSE BEGIN
      IF EXISTS(SELECT 1 FROM SendListItem WHERE Status != 1 AND ListId = @lastList) BEGIN -- power(4,0)
          EXECUTE @returnValue = sendList$setStatus @lastlist, @rowVersion
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
   SET @msg = ''Batch insert into send list item table not allowed.'' + @msgTag + ''>''
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
   SET @msg = ''Items may not be placed directly on a composite send list.'' + @msgTag + ''>''
   EXECUTE error$raise @msg, 0, @tranName
   RETURN
END

-- Verify that the list to which the item was inserted has not yet been transmitted.
SELECT @listStatus = Status,
       @accountId = AccountId
FROM   SendList
WHERE  ListId = (SELECT ListId FROM Inserted)
IF @listStatus >= 256 BEGIN -- power(4,4)
   SET @msg = ''Items cannot be added to a list that has already been transmitted or cleared.'' + @msgTag + ''>''
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
   SET @msg = ''Medium must reside at the enterprise in order to be placed on a send list.'' + @msgTag + ''>''
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
   WHERE  sli.Status IN (4,64,256) -- power(4,x)
   GROUP  BY i.MediumId
   HAVING count(*) > 1
   )
BEGIN
   SET @msg = ''Medium may not actively appear on more than one send list'' + @msgTag + ''>''
   EXECUTE error$raise @msg, 0, @tranName
   RETURN
END

-- Select the name of the list and the medium serial number from the Inserted table
SELECT @listId = i.ListId,
       @mediumId = i.MediumId,
       @serialNo = m.SerialNo,
       @listName = sl.ListName,
       @itemStatus = case i.Status when 4 then ''Unverified'' when 64 then ''Verified'' end -- power(4,x)
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
      SET @msg = ''Error encountered while inserting a new send list item audit record; could not reset medium missing status.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
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
   ''Medium '''''' + @serialNo + '''''' added to send list;Status='' + @itemStatus,
   dbo.string$GetSpidLogin()
)
SET @error = @@error
IF @error != 0 BEGIN
   SET @msg = ''Error encountered while inserting a new send list item audit record.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
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
   WHERE  sli.Status IN (4,64,256) -- power(4,x)
   GROUP  BY i.MediumId
   HAVING count(*) > 1
   )
BEGIN
   SET @msg = ''Medium may not actively appear on more than one send list'' + @msgTag + ''>''
   EXECUTE error$raise @msg, 0, @tranName
   RETURN
END

-- For each list in the update where an item was updated to a status other 
-- than removed, make sure that the discrete list status is equal to 
-- the (translated) lowest status among its non-removed items.
SET @lastList = 0
WHILE 1 = 1 BEGIN
   SELECT TOP 1 @lastList = i.ListId,
          @rowVersion = sl.RowVersion
   FROM   Inserted i
   JOIN   Deleted d
     ON   d.ItemId = i.ItemId
   JOIN   SendList sl
     ON   sl.ListId = i.ListId
   WHERE  i.Status != 1 AND  -- power(4,0)
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
         IF @status = 1 BEGIN -- power(4,0)
            SET @auditAction = 5
            SET @msgUpdate = ''Medium '''''' + @serialNo + '''''' removed from list.''
         END
         ELSE IF @status = 64 BEGIN -- power(4,3)
            SET @msgUpdate = ''Medium '''''' + @serialNo + '''''' verified.''
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
            SET @msgUpdate = ''Item updated;Serial='' + @serialNo + '';ReturnDate='' + coalesce(convert(nchar(10),@returnDate,120),''(None)'')
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
         SET @msg = ''Error encountered while inserting a new send list item audit record.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
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
   WHERE  i.Status = 1 AND  -- power(4,0)
          d.Status != 1 AND -- power(4,0)
          i.ListId > @lastList
   ORDER BY i.ListId ASC
   IF @@rowCount = 0
      BREAK
   ELSE BEGIN
      IF EXISTS(SELECT 1 FROM SendListItem WHERE ListId = @lastList AND Status != 1) BEGIN -- power(4,0)
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
         SET @msg = ''Error deleting empty send list case.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
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
            ''Medium '''''' + @serialNo + '''''' removed from case'',
            dbo.string$GetSpidLogin()
         )
         SET @error = @@error
         IF @error != 0 BEGIN
            SET @msg = ''Error encountered while inserting a new send list case audit record.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
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
   SET @msg = ''Batch insert into send list item case table not allowed.'' + @msgTag + ''>''
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
   ''Medium '''''' + @serialNo + '''''' inserted into case '''''' + @caseName + '''''''', 
   dbo.string$GetSpidLogin()
)
SET @error = @@error
IF @error != 0 BEGIN
   SET @msg = ''Error encountered while inserting a new send list item case audit record.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
   EXECUTE error$raise @msg, @error, @tranName
   RETURN
END

COMMIT TRANSACTION
END
'
)

IF EXISTS(SELECT * FROM sysobjects WHERE name = 'sendListScanItem$afterDelete' AND objectproperty(id, 'ExecIsDeleteTrigger' ) = 1) 
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'TRIGGER sendListScanItem$afterDelete
ON    SendListScanItem
WITH ENCRYPTION
AFTER DELETE
AS
BEGIN
DECLARE @msg nvarchar(255)           -- used to preformat error message
DECLARE @msgTag nvarchar(255)        -- used to hold first part of error message header
DECLARE @tranName as nvarchar(255)   -- used to hold name of savepoint
DECLARE @lastScan int
DECLARE @rowCount int                -- holds the number of rows in the Inserted table
DECLARE @error int            

-- Set up the error message tag
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=T''
SET @tranName = object_name(@@procid) + CAST(@@nestlevel as nvarchar(2))

BEGIN TRANSACTION
SAVE TRANSACTION @tranName

-- Delete any scans that have no records left
SET @lastScan = 0
WHILE 1 = 1 BEGIN
   SELECT DISTINCT TOP 1 @lastScan = d.ScanId
   FROM   Deleted d
   LEFT OUTER JOIN SendListScanItem slsi
     ON   slsi.ScanId = d.ScanId
   WHERE  d.ScanId > @lastScan AND slsi.ScanId IS NULL
   ORDER BY d.ScanId ASC
   IF @@rowCount = 0 BEGIN
      BREAK
   END
   ELSE BEGIN
      DELETE SendListScan
      WHERE  ScanId = @lastScan
      SET @error = @@error
      IF @error != 0 BEGIN
         SET @msg = ''Error encountered while deleting empty send list scan.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
         EXECUTE error$raise @msg, @error, @tranName
         RETURN
      END
   END
END

COMMIT TRANSACTION
END      
'
)

-------------------------------------------------------------------------------
--
-- Stored Procedures - Medium
--
-------------------------------------------------------------------------------

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'medium$del')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.medium$del
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
DECLARE @rowCount as int
DECLARE @error as int

SET NOCOUNT ON

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=P''
SET @tranName = object_name(@@procid) + CAST(@@nestlevel as nvarchar(2))

-- Delete medium
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

DELETE FROM Medium
WHERE  MediumId = @id AND
       rowVersion = @rowVersion

SELECT @error = @@error, @rowCount = @@rowcount

IF @error != 0 BEGIN
   ROLLBACK TRANSACTION @tranName
   COMMIT TRANSACTION
   SET @msg = ''Error encountered while deleting medium.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
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
   -- No notification if medium does not exist.  It''s not a bad thing if
   -- we try to delete a record that does not exist.
END

COMMIT TRANSACTION
RETURN 0
END
'
)

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'medium$delBySerial')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.medium$delBySerial
(
   @serialNo nvarchar(32)
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

-- Delete medium
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

DELETE FROM Medium
WHERE  SerialNo = @serialNo

SELECT @error = @@error

IF @error != 0 BEGIN
   ROLLBACK TRANSACTION @tranName
   COMMIT TRANSACTION
   SET @msg = ''Error encountered while deleting medium.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
   EXECUTE error$raise @msg, @error
   RETURN -100
END

COMMIT TRANSACTION
RETURN 0
END
'
)

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'medium$exists')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.medium$exists
(
   @serialNo nvarchar(32)
)
WITH ENCRYPTION
AS
BEGIN

IF EXISTS(SELECT 1 FROM Medium WHERE SerialNo = @serialNo)
   SELECT 1
ELSE
   SELECT 0

END
'
)

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'medium$getCount')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.medium$getCount
WITH ENCRYPTION
AS
BEGIN

SET NOCOUNT ON

SELECT count(*) 
FROM   Medium

END
'
)

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'medium$getById')
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
FROM   Medium m 
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

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'medium$getBySerialNo')
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
FROM   Medium m 
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

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'medium$getByCase')
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
FROM   Medium m 
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
IF len(ltrim(rtrim(coalesce(@filter,'''')))) > 0 BEGIN
	SET @filter = replace(@filter,''SerialNo'',''m.SerialNo'')
	SET @filter = replace(@filter,''Location'',''m.Location'')
	SET @filter = replace(@filter,''ReturnDate'',''case len(coalesce(convert(nvarchar(10),c.ReturnDate,120),'''''''')) when 0 then coalesce(convert(nvarchar(10),m.ReturnDate,120),'''''''') else coalesce(convert(nvarchar(10),c.ReturnDate,120),'''''''') end'')
	SET @filter = replace(@filter,''Missing'',''m.Missing'')
	SET @filter = replace(@filter,''LastMoveDate'',''coalesce(convert(nvarchar(19),m.LastMoveDate,120),'''''''')'')
	SET @filter = replace(@filter,''Account'',''a.AccountName'')
	SET @filter = replace(@filter,''MediumType'',''t.TypeName'')
	SET @filter = replace(@filter,''CaseName'',''c.CaseName'')
	SET @filter = replace(@filter,''Notes'',''m.Notes'')
   SET @where = @where + '' AND ('' + @filter + '')''
END

-- Construct the fields string
SET @fields2 = ''MediumId, SerialNo, Location, HotStatus, ReturnDate, Missing, LastMoveDate, BSide, Notes, AccountName, TypeName, CaseName, RowVersion''
SET @fields1 = ''m.MediumId, m.SerialNo, m.Location, m.HotStatus, case len(coalesce(convert(nvarchar(10),c.ReturnDate,120),'''''''')) when 0 then coalesce(convert(nvarchar(10),m.ReturnDate,120),'''''''') else convert(nvarchar(10),c.ReturnDate,120) end as ''''ReturnDate'''', m.Missing, coalesce(convert(nvarchar(19),m.LastMoveDate,120),'''''''') as ''''LastMoveDate'''', m.BSide, m.Notes, a.AccountName, t.TypeName, coalesce(c.CaseName,'''''''') as ''''CaseName'''', m.RowVersion''

-- Construct the tables string
SET @tables = ''Medium m JOIN Account a ON a.AccountId = m.AccountId JOIN MediumType t ON t.TypeId = m.TypeId LEFT OUTER JOIN (SELECT sc.SerialNo as ''''CaseName'''', msc.MediumId as ''''MediumId'''', sc.ReturnDate as ''''ReturnDate'''' FROM SealedCase sc JOIN MediumSealedCase msc ON msc.CaseId = sc.CaseId) as c ON c.MediumId = m.MediumId''

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

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'medium$getRecallCode')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.medium$getRecallCode
(
   @serialNo nvarchar(32)
)
WITH ENCRYPTION
AS
BEGIN

SET NOCOUNT ON

SELECT rc.Code
FROM   RecallCode rc
JOIN   Medium m
  ON   m.TypeId = rc.TypeId
WHERE  m.SerialNo = @serialNo

END
'
)

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'medium$upd')
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
WHERE  TypeName = @mediumType
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
          LastMoveDate = cast(convert(nchar(19),getdate(),120) as datetime),
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

-------------------------------------------------------------------------------
--
-- Triggers - Medium
--
-------------------------------------------------------------------------------
IF EXISTS(SELECT * FROM sysobjects WHERE name = 'medium$afterDelete' AND objectproperty(id, 'ExecIsDeleteTrigger' ) = 1) 
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'TRIGGER medium$afterDelete
ON     Medium
WITH ENCRYPTION
AFTER  DELETE
AS
BEGIN
DECLARE @msg nvarchar(255)         -- used to preformat error message
DECLARE @msgTag nvarchar(255)      -- used to hold first part of error message header
DECLARE @msgUpdate nvarchar(3000)  -- used to hold the updated fields
DECLARE @tranName nvarchar(255)    -- used to hold name of savepoint
DECLARE @lastSerial nvarchar(32)
DECLARE @login nvarchar(32)
DECLARE @returnValue int
DECLARE @rowCount int
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
   SET @msg = ''No login found for auditing purposes.'' + @msgTag + ''>''
   EXECUTE error$raise @msg, 0, @tranName
   RETURN
END

-- Get the tag value from spid login
SET @login = dbo.string$GetSpidLogin()

-- Audit deletes
SET @lastSerial = ''''
WHILE 1 = 1 BEGIN
   SELECT TOP 1 @lastSerial = SerialNo
   FROM   Deleted
   WHERE  SerialNo > @lastSerial
   ORDER BY SerialNo ASC
   IF @@rowCount = 0
      BREAK
   ELSE BEGIN
      INSERT XMedium
      (
         Object, 
         Action, 
         Detail, 
         Login
      )
      VALUES
      (
         @lastSerial, 
         3, 
         ''Medium '''''' + @lastSerial + '''''' deleted'',
         @login
      )
      SET @error = @@error
      IF @error != 0 BEGIN
         SET @msg = ''Error inserting a medium audit record.'' + @msgTag + '';Error='' + cast(@error as nvarchar(9)) + ''>''
         EXECUTE error$raise @msg, @error, @tranName
         RETURN
      END
   END
END

-- Commit transaction
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
   SET @msg = ''A case with serial number '''''' + @serialNo + '''''' exists on an active send list.'' + @msgTag + ''>''
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
      SET @msg = ''A case with serial number '''''' + @bSide + '''''' exists on an active send list.'' + @msgTag + ''>''
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
SET @msgInsert = ''Medium '''''' + @serialNo + '''''' created''
IF len(ltrim(rtrim(@bSide))) > 0 
   SET @msgInsert = @msgInsert + '';BSide='' + @bSide
IF @location = 1
   SET @msgInsert = @msgInsert + '';Location=Local''
ELSE
   SET @msgInsert = @msgInsert + '';Location=Vault''

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
DECLARE @msgUpdate nvarchar(3000)  -- used to hold the updated fields
DECLARE @tranName nvarchar(255)    -- used to hold name of savepoint
DECLARE @tagInfo nvarchar(1000)   -- information from the SpidLogin table
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
DECLARE @location bit
DECLARE @typeId int
DECLARE @accountId int
DECLARE @vaultDiscrepancy int     -- holds the id of any vault discrepancy that should be resolved
DECLARE @rowCount int             -- holds the number of rows in the Deleted table
DECLARE @moveType int           -- method by which medium was moved
DECLARE @itemId int
DECLARE @caseId int
DECLARE @error int
DECLARE @login nvarchar(32)
DECLARE @returnValue int
DECLARE @rowVersion rowversion
DECLARE @tblMedia table (RowNo int primary key identity(1,1), SerialNo nvarchar(32))
DECLARE @i int

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

-- Disallow movement or account, change if a medium is active and 
-- beyond unverified on a send or receive list.
SELECT TOP 1 @serialNo = i.SerialNo,
       @listName = lists.ListName,
       @location = i.Location,
       @accountId = i.AccountId,
       @typeId = i.TypeId,
       @mediumId = i.MediumId
FROM   Inserted i
JOIN   Deleted d
  ON   i.MediumId = d.MediumId
JOIN   (
       SELECT TOP 1 sl.ListName as ''ListName'',
              sli.MediumId as ''MediumId''
       FROM   SendList sl
       JOIN   SendListItem sli
         ON   sli.ListId = sl.ListId
       WHERE  sli.Status IN (64,256) -- power(4,x)
       UNION
       SELECT TOP 1 rl.ListName,
              rli.MediumId
       FROM   ReceiveList rl
       JOIN   ReceiveListItem rli
         ON   rli.ListId = rl.ListId
       WHERE  rli.Status IN (16,256) -- power(4,x)
       )
       As lists
  ON   lists.MediumId = i.MediumId
WHERE  i.Location != d.Location OR 
       i.AccountId != d.AccountId
ORDER BY i.SerialNo Asc
IF @@rowCount > 0 BEGIN
   IF EXISTS(SELECT 1 FROM Deleted WHERE MediumId = @mediumId AND @accountId != AccountId) BEGIN
      SET @msg = ''Medium '''''' + @serialNo + '''''' may not have its account changed because it is has been verified and/or transmitted on list '' + @listName + ''.'' + @msgTag + ''>''
      EXECUTE error$raise @msg, 0, @tranName
      RETURN
   END
   ELSE IF EXISTS(SELECT 1 FROM Deleted WHERE MediumId = @mediumId AND @typeId != TypeId) BEGIN
      SET @msg = ''Medium '''''' + @serialNo + '''''' may not have its type changed because it is has been verified and/or transmitted on list '' + @listName + ''.'' + @msgTag + ''>''
      EXECUTE error$raise @msg, 0, @tranName
      RETURN
   END
   IF EXISTS(SELECT 1 FROM Deleted WHERE MediumId = @mediumId AND @location != Location) BEGIN
      -- Do not allow movement unless we are clearing a list.  This is usually cut and dried,
      -- as the user will have most of the time directly cleared a list.  There is one 
      -- exception, however, where an unrelated action will trigger a list to be cleared.
      -- This is when the last unverified tape on a receive list is marked missing or
      -- deleted.  Since all other items are verified, the removal of the last item will
      -- trigger clearing of the list.  If the tape is on a receive list and the rest of
      -- the list is fully verified, then the list is being cleared in this manner.
      IF @moveType NOT IN (2,3) BEGIN
         IF EXISTS (SELECT 1 FROM ReceiveListItem rli JOIN ReceiveList rl ON rl.ListId = rli.ListId WHERE MediumId = @mediumId AND rl.Status = 256)
            SET @moveType = 3
         ELSE BEGIN
            SET @msg = ''Medium '''''' + @serialNo + '''''' may not be moved because it is has been verified and/or transmitted on list '' + @listName + ''.'' + @msgTag + ''>''
            EXECUTE error$raise @msg, 0, @tranName
            RETURN
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

-- Gather the media id numbers into the table
INSERT @tblMedia (SerialNo)
SELECT SerialNo
FROM   Inserted
ORDER  BY SerialNo Asc

-- Initialize counter
SELECT @i = 1

-- Loop through the media in the update
WHILE 1 = 1 BEGIN
   SELECT TOP 1 @mediumId = MediumId,
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
   -- Initialize the update message
   SELECT @msgUpdate = ''Medium '''''' + SerialNo + '''''' updated''
   FROM   Deleted
   WHERE  MediumId = @mediumId
   -- Serial number
   IF EXISTS(SELECT 1 FROM Deleted WHERE MediumId = @mediumId AND SerialNo != @lastSerial) BEGIN
      SET @msgUpdate = @msgUpdate + '';SerialNo='' + @lastSerial
   END
   -- Hot site status
   IF EXISTS(SELECT 1 FROM Deleted WHERE MediumId = @mediumId AND HotStatus != @hotStatus) BEGIN
      IF @hotStatus = 1
         SET @msgUpdate = @msgUpdate + '';HotSite=TRUE''
      ELSE
         SET @msgUpdate = @msgUpdate + '';HotSite=FALSE''
   END
   -- Missing status
   IF EXISTS(SELECT 1 FROM Deleted WHERE MediumId = @mediumId AND Missing != @missing) BEGIN
      IF @missing = 1
         SET @msgUpdate = @msgUpdate + '';Missing=TRUE''
      ELSE
         SET @msgUpdate = @msgUpdate + '';Missing=FALSE''
   END
   -- Return date
   IF EXISTS(SELECT 1 FROM Deleted d WHERE MediumId = @mediumId AND coalesce(convert(nvarchar(10),ReturnDate,120),''(None)'') != @returnDate) BEGIN
      SET @msgUpdate = @msgUpdate + '';ReturnDate='' + @returnDate
   END
   -- B-Side
   IF EXISTS(SELECT 1 FROM Deleted d WHERE MediumId = @mediumId AND BSide != @bSide) BEGIN
      SET @msgUpdate = @msgUpdate + '';B-Side='' + @bSide
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
            SET @msg = ''A case with serial number '''''' + @bSide + '''''' exists on an active send list.'' + @msgTag + ''>''
            EXECUTE error$raise @msg, 0, @tranName
            RETURN
         END
         ELSE IF EXISTS(SELECT 1 FROM MediumType WHERE TypeId = @typeId AND (Container = 1 OR TwoSided = 0)) BEGIN
            SET @msg = ''A b-side serial number may not be assigned to a medium of one-sided type or to a container.'' + @msgTag + ''>''
            EXECUTE error$raise @msg, 0, @tranName
            RETURN
         END
      END
   END
   -- Medium type
   IF EXISTS(SELECT 1 FROM Deleted WHERE MediumId = @mediumId AND TypeId != @typeId) BEGIN
      SELECT @msgUpdate = @msgUpdate + '';MediumType='' + TypeName
      FROM   MediumType
      WHERE  TypeId = @typeId
   END
   -- Account
   IF EXISTS(SELECT 1 FROM Deleted WHERE MediumId = @mediumId AND AccountId != @accountId) BEGIN
      SELECT @msgUpdate = @msgUpdate + '';Account='' + AccountName
      FROM   Account
      WHERE  AccountId = @accountId
   END
   -- Notes
   IF EXISTS(SELECT 1 FROM Deleted WHERE MediumId = @mediumId AND Notes != @notes) BEGIN
      SET @msgUpdate = @msgUpdate + '';Notes''
   END
   -- If the account or medium type has changed, verify that the account 
   -- and medium type accord with the bar code formats.
   IF charindex(@msgUpdate,'';Account'') > 0 OR charindex(@msgUpdate,'';MediumType'') > 0 BEGIN
      IF NOT EXISTS
         (
         SELECT 1
         FROM   BarCodePattern
         WHERE  TypeId = @typeId AND
                AccountId = @accountId AND
                Position = (SELECT min(Position) 
                            FROM   BarCodePattern
                            WHERE  dbo.bit$RegexMatch(@lastSerial,Pattern) = 1)
         )
      BEGIN
         SET @msg = ''Account and/or medium type do not accord with bar code formats.'' + @msgTag + ''>''
         EXECUTE error$raise @msg, 0, @tranName
         RETURN
      END
   END
   -- Insert audit record if at least one field has been modified.  We
   -- can tell this if a semicolon appears after ''updated'' in the message.
   IF CHARINDEX(''updated;'', @msgUpdate) > 0 BEGIN
      INSERT XMedium
      (
         Object, 
         Action, 
         Detail, 
         Login
      )
      VALUES
      (
         @lastSerial, 
         2, 
         @msgUpdate, 
         dbo.string$GetSpidLogin()
      )
      SET @error = @@error
      IF @error != 0 BEGIN
         SET @msg = ''Error inserting a medium audit record.'' + @msgTag + '';Error='' + cast(@error as nvarchar(9)) + ''>''
         EXECUTE error$raise @msg, @error, @tranName
         RETURN
      END
   END
   -- If the medium serial number was changed, then we should delete any inventory
   -- discrepancies for the medium
   IF charindex('';SerialNo='',@msgUpdate) > 0 BEGIN
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
   IF charindex('';MediumType='',@msgUpdate) > 0 BEGIN
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
   IF charindex('';Account='',@msgUpdate) > 0 BEGIN
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
   -- disallow missing status if the medium has already been verified on a
   -- send or receive list.
   IF charindex('';Missing=TRUE'',@msgUpdate) > 0 BEGIN
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
      -- Check send lists
      SELECT @itemId = ItemId,
             @itemStatus = Status,
             @rowVersion = RowVersion
      FROM   SendListItem
      WHERE  Status IN (4, 64, 256) AND MediumId = @mediumId
      IF @@rowCount != 0 BEGIN
         IF @itemStatus IN (64,256) BEGIN
            SET @msg = ''Medium cannot be marked missing when it has been verified on an active send list.'' + @msgTag + ''>''
            EXECUTE error$raise @msg, 0, @tranName
            RETURN
         END
         ELSE BEGIN
            -- Remove item from send list
            EXECUTE @returnValue = sendListItem$remove @itemId, @rowVersion
	         IF @returnValue != 0 BEGIN
	            ROLLBACK TRANSACTION @tranName   
	            COMMIT TRANSACTION
	            RETURN
	         END
         END
      END
      -- If the receive list item has been verified, then disallow missing status.  If the item has
      -- been transmitted, remove it from the receive list.  We do this because if a medium is
      -- being marked missing when its receive list item has a status of transmitted, then the
      -- list is most likely being reconciled, and the user will want to remove the item
      -- from the list after marking it missing.  If the item is merely submitted, remove it.
      ELSE BEGIN
         SELECT @itemId = ItemId,
                @itemStatus = Status,
                @rowVersion = RowVersion
         FROM   ReceiveListItem
         WHERE  Status IN (4, 16, 256) AND MediumId = @mediumId
         IF @@rowCount != 0 BEGIN
            IF @itemStatus = 256 BEGIN
               SET @msg = ''Medium cannot be marked missing when it is has been verified on an active receive list.'' + @msgTag + ''>''
               EXECUTE error$raise @msg, 0, @tranName
               RETURN
            END
            ELSE BEGIN
	            -- Remove item from send list
	            EXECUTE @returnValue = receiveListItem$remove @itemId, @rowVersion
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
      INSERT XMediumMovement
      (
         Date, 
         Object, 
         Direction, 
         Method, 
         Login
      )
      VALUES
      (
         @lastMoveDate,
         @lastSerial, 
         @location, 
         @moveType, 
         dbo.string$GetSpidLogin()
      )
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
      WHERE  MediumId = @mediumId AND Status = 4 -- power(4,1)
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
      WHERE  MediumId = @mediumId AND Status = 4 -- power(4,1)
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
      WHERE  dlim.MediumId = @mediumId AND dli.Status = 4 -- power(4,1)
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

-------------------------------------------------------------------------------
--
-- Stored Procedures - Audit Trails
--
-------------------------------------------------------------------------------
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
SET @LASTAUDITTYPE         = 8192

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
         SET @fields1 = ''ItemId, Date, '''''''' As ''''Object'''', Action, Detail, ''''SYSTEM'''', '' + @auditType
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
@MEDIUMMOVEMENT        = 8192

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

END
'
)

IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'auditTrail$getExpiration')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.auditTrail$getExpiration
(
   @auditType int
)
WITH ENCRYPTION
AS
BEGIN

SET NOCOUNT ON

SELECT Category,
       Archive,
       Days,
       RowVersion
FROM   XCategoryExpiration
WHERE  Category = @auditType

END
'
)

IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'auditTrail$updateExpiration')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.auditTrail$updateExpiration
(
   @auditType int,
   @archive bit,
   @days int,
   @rowVersion rowVersion
)
WITH ENCRYPTION
AS
BEGIN
DECLARE @msg nvarchar(255)        -- used to preformat error message
DECLARE @msgTag nvarchar(255)     -- used to hold first part of error message header
DECLARE @tranName nvarchar(255)
DECLARE @rowCount int
DECLARE @error int

SET NOCOUNT ON

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=P''
SET @tranName = object_name(@@procid) + CAST(@@nestlevel as nvarchar(2))

BEGIN TRANSACTION
SAVE TRANSACTION @tranName

UPDATE XCategoryExpiration
SET    Archive = @archive,
       Days = @days
WHERE  Category = @auditType AND RowVersion = @rowVersion

SELECT @error = @@error, @rowCount = @@rowcount

IF @error != 0 BEGIN
   ROLLBACK TRANSACTION @tranName
   COMMIT TRANSACTION
   SET @msg = ''Error encountered while updating audit trail expiration.'' + @msgTag + '';Error='' +  cast(@error as nvarchar(10)) + ''>''
   EXECUTE error$raise @msg, @error
   RETURN -100
END
ELSE IF @rowCount = 0 BEGIN
   IF EXISTS(SELECT 1 FROM XCategoryExpiration WHERE Category = @auditType) BEGIN
      ROLLBACK TRANSACTION @tranName
      COMMIT TRANSACTION
      SET @msg = ''Expiration has been modified since retrieval.'' + @msgTag + ''>''
      EXECUTE error$raise @msg, 0
      RETURN -100
   END
   ELSE BEGIN
      ROLLBACK TRANSACTION @tranName
      COMMIT TRANSACTION
      SET @msg = ''Audit trail type does not exist.'' + @msgTag + ''>''
      EXECUTE error$raise @msg, 0
      RETURN -100
   END
END

COMMIT TRANSACTION
RETURN 0
END
'
)

IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'listPurgeDetail$get')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.listPurgeDetail$get
(
   @listType int
)
WITH ENCRYPTION
AS
BEGIN

SET NOCOUNT ON

SELECT Type,
       Archive,
       Days,
       RowVersion
FROM   ListPurgeDetail
WHERE  Type = @listType
END
'
)

IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'listPurgeDetail$getTable')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.listPurgeDetail$getTable
WITH ENCRYPTION
AS
BEGIN

SET NOCOUNT ON

SELECT Type,
       Archive,
       Days,
       RowVersion
FROM   ListPurgeDetail
ORDER BY Type ASC
END
'
)

IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'listPurgeDetail$upd')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.listPurgeDetail$upd
(
   @listType int,   -- 1 = SEND, 2 = RECEIVE, 3 = DISASTER CODE
   @archive bit,
   @days int,
   @rowVersion rowVersion
)
WITH ENCRYPTION
AS
BEGIN
DECLARE @msg nvarchar(255)        -- used to preformat error message
DECLARE @msgTag nvarchar(255)     -- used to hold first part of error message header
DECLARE @tranName nvarchar(255)
DECLARE @rowCount int
DECLARE @error int

SET NOCOUNT ON

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=P''
SET @tranName = object_name(@@procid) + CAST(@@nestlevel as nvarchar(2))

BEGIN TRANSACTION
SAVE TRANSACTION @tranName

UPDATE ListPurgeDetail
SET    Archive = @archive,
       Days = @days
WHERE  Type = @listType AND RowVersion = @rowVersion

SELECT @error = @@error, @rowCount = @@rowcount

IF @error != 0 BEGIN
   ROLLBACK TRANSACTION @tranName
   COMMIT TRANSACTION
   SET @msg = ''Error encountered while updating list purge parameter.'' + @msgTag + '';Error='' +  cast(@error as nvarchar(10)) + ''>''
   EXECUTE error$raise @msg, @error
   RETURN -100
END
ELSE IF @rowCount = 0 BEGIN
   IF EXISTS(SELECT 1 FROM ListPurgeDetail WHERE Type = @listType) BEGIN
      ROLLBACK TRANSACTION @tranName
      COMMIT TRANSACTION
      SET @msg = ''List purge detail has been modified since retrieval.'' + @msgTag + ''>''
      EXECUTE error$raise @msg, 0
      RETURN -100
   END
   ELSE BEGIN
      ROLLBACK TRANSACTION @tranName
      COMMIT TRANSACTION
      SET @msg = ''List purge detail type does not exist.'' + @msgTag + ''>''
      EXECUTE error$raise @msg, 0
      RETURN -100
   END
END

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
   WHERE  Status = 1024 AND CreateDate < @cleanDate
END

-- Receive lists
IF @listType & 2 = 2 BEGIN
   DELETE ReceiveList
   WHERE  Status = 1024 AND CreateDate < @cleanDate
END

-- Disaster code lists
IF @listType & 4 = 4 BEGIN
   DELETE DisasterCodeList
   WHERE  Status = 64 AND CreateDate < @cleanDate
END

END
'
)

-------------------------------------------------------------------------------
--
-- FTP Procedures
--
-------------------------------------------------------------------------------
IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'ftpProfile$del')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.ftpProfile$del
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
DECLARE @rowCount as int
DECLARE @error as int

SET NOCOUNT ON

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=P''
SET @tranName = object_name(@@procid) + CAST(@@nestlevel as nvarchar(2))

-- Delete profile
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

DELETE FtpProfile
WHERE  ProfileId = @id AND
       rowVersion = @rowVersion

SELECT @error = @@error, @rowCount = @@rowcount

IF @error != 0 BEGIN
   ROLLBACK TRANSACTION @tranName
   COMMIT TRANSACTION
   SET @msg = ''Error encountered while deleting FTP profile.'' + @msgTag + '';Error='' + cast(@error as nvarchar(10)) + ''>''
   EXECUTE error$raise @msg, @error
   RETURN -100
END
ELSE IF @rowCount = 0 BEGIN
   IF EXISTS(SELECT 1 FROM FtpProfile WHERE ProfileId = @id) BEGIN
      ROLLBACK TRANSACTION @tranName
      COMMIT TRANSACTION
      SET @msg = ''FTP profile has been modified since retrieval.'' + @msgTag + ''>''
      RAISERROR(@msg,16,1)
      RETURN -100
   END
END

COMMIT TRANSACTION
RETURN 0
END
'
)

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'ftpProfile$getById')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.ftpProfile$getById
(
   @id int
)
WITH ENCRYPTION
AS
BEGIN

SET NOCOUNT ON

-- Select
SELECT  ProfileId,
        ProfileName,
        Server,
        Login,
        Password,
        FilePath,
        FileFormat,
        Passive,
        Secure,
        RowVersion
FROM    FtpProfile
WHERE   ProfileId = @id

END
'
)

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'ftpProfile$getByName')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.ftpProfile$getByName
(
   @profileName nvarchar(256)
)
WITH ENCRYPTION
AS
BEGIN

SET NOCOUNT ON

-- Select
SELECT  ProfileId,
        ProfileName,
        Server,
        Login,
        Password,
        FilePath,
        FileFormat,
        Passive,
        Secure,
        RowVersion
FROM    FtpProfile
WHERE   ProfileName = @profileName

END
'
)

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'ftpProfile$getByAccount')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.ftpProfile$getByAccount
(
   @accountName nvarchar(256)
)
WITH ENCRYPTION
AS
BEGIN

SET NOCOUNT ON

-- Select
SELECT  p.ProfileId,
        p.ProfileName,
        p.Server,
        p.Login,
        p.Password,
        p.FilePath,
        p.FileFormat,
        p.Passive,
        p.Secure,
        p.RowVersion
FROM    FtpProfile p
JOIN    FtpAccount fa
  ON    p.ProfileId = fa.ProfileId
JOIN    Account a
  ON    a.AccountId = fa.AccountId 
WHERE   a.AccountName = @accountName

END
'
)

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'ftpProfile$getTable')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.ftpProfile$getTable
WITH ENCRYPTION
AS
BEGIN

SET NOCOUNT ON

-- Select
SELECT ProfileId,
       ProfileName,
       Server,
       Login,
       Password,
       FilePath,
       FileFormat,
       Passive,
       Secure,
       RowVersion
FROM   FtpProfile
ORDER  BY ProfileName
END
'
)

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'ftpProfile$ins')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.ftpProfile$ins
(
   @name       nvarchar(256),
   @server     nvarchar(256),
   @login      nvarchar(64),
   @password   nvarchar(128),
   @filePath   nvarchar(256),
   @fileFormat smallint,
   @passive    bit,
   @secure     bit,
   @newId      int  OUTPUT
)

WITH ENCRYPTION
AS
BEGIN
DECLARE @msg as nvarchar(255)        -- used to preformat error message
DECLARE @msgTag as nvarchar(255)     -- used to hold first part of error message header
DECLARE @tranName as nvarchar(255)   -- used to hold name of savepoint
DECLARE @error as int

SET NOCOUNT ON

SET @name   = isnull(@name, '''')
SET @server = isnull(@server, '''')
SET @login  = isnull(@login, '''')
SET @password  = isnull(@password, '''')
SET @filePath  = isnull(@filePath, '''')

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=P''
SET @tranName = object_name(@@procid) + CAST(@@nestlevel as nvarchar(2))

-- Insert the account
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

INSERT FtpProfile
(
   ProfileName,
   Server,
   Login,
   Password,
   FilePath,
   FileFormat,
   Passive,
   Secure
)
VALUES
(
   @name, 
   @server, 
   @login, 
   @password, 
   @filePath, 
   @fileFormat,
   @passive,
   @secure
)

SET @error = @@error
IF @error != 0 BEGIN
   ROLLBACK TRANSACTION @tranName
   COMMIT TRANSACTION
   SET @msg = ''Error encountered while inserting new FTP profile.'' + @msgTag + '';Error'' + cast(@error as nvarchar(50)) + ''>''
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

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'ftpProfile$upd')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.ftpProfile$upd
(
   @id         int,
   @name       nvarchar(256),
   @server     nvarchar(256),
   @login      nvarchar(64),
   @password   nvarchar(128),
   @filePath   nvarchar(256),
   @fileFormat smallint,
   @passive    bit,
   @secure     bit,
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

SET @name   = isnull(@name, '''')
SET @server = isnull(@server, '''')
SET @login  = isnull(@login, '''')
SET @password  = isnull(@password, '''')
SET @filePath  = isnull(@filePath, '''')

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=P''
SET @tranName = object_name(@@procid) + CAST(@@nestlevel as nvarchar(2))

-- Update account
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

UPDATE FtpProfile
SET    ProfileName = @name,
       Server = @server,
       Login = @login,
       Password = @password,
       FilePath = @filePath,
       FileFormat = @fileFormat,
       Passive = @passive,
       Secure = @secure
WHERE  ProfileId = @id AND
       RowVersion = @rowVersion

SELECT @error = @@error, @rowCount = @@rowcount

IF @error != 0 BEGIN
   ROLLBACK TRANSACTION @tranName
   COMMIT TRANSACTION
   SET @msg = ''Error encountered while updating FTP profile.'' + @msgTag + '';Error='' +  cast(@error as nvarchar(10)) + ''>''
   EXECUTE error$raise @msg, @error
   RETURN -100
END
ELSE IF @rowCount = 0 BEGIN
   IF EXISTS(SELECT 1 FROM FtpProfile WHERE ProfileId = @id) BEGIN
      ROLLBACK TRANSACTION @tranName
      COMMIT TRANSACTION
      SET @msg = ''FTP profile has been modified since retrieval.'' + @msgTag + ''>''
      EXECUTE error$raise @msg, 0
      RETURN -100
   END
   ELSE BEGIN
      ROLLBACK TRANSACTION @tranName
      COMMIT TRANSACTION
      SET @msg = ''FTP profile record does not exist.'' + @msgTag + ''>''
      EXECUTE error$raise @msg, 0
      RETURN -100
   END
END

-- Commit the transaction
COMMIT TRANSACTION
RETURN 0

END
'
)

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'ftpAccount$del')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.ftpAccount$del
(
   @accountId int
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

-- Delete profile
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

DELETE FtpAccount
WHERE  AccountId = @accountId

SET @error = @@error
IF @error != 0 BEGIN
   ROLLBACK TRANSACTION @tranName
   COMMIT TRANSACTION
   SET @msg = ''Error encountered while deleting FTP account.'' + @msgTag + '';Error='' + cast(@error as nvarchar(10)) + ''>''
   EXECUTE error$raise @msg, @error
   RETURN -100
END

COMMIT TRANSACTION
RETURN 0
END
'
)

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'ftpAccount$upd')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.ftpAccount$upd
(
   @accountId int,
   @profileName nvarchar(256)
)
WITH ENCRYPTION
AS
BEGIN
DECLARE @msg as nvarchar(255)        -- used to preformat error message
DECLARE @msgTag as nvarchar(255)     -- used to hold first part of error message header
DECLARE @tranName as nvarchar(255)   -- used to hold name of savepoint
DECLARE @profileId as int
DECLARE @error as int

SET NOCOUNT ON

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=P''
SET @tranName = object_name(@@procid) + CAST(@@nestlevel as nvarchar(2))

-- Get the profile id number
SELECT @profileId = ProfileId
FROM   FtpProfile
WHERE  ProfileName = @profileName
IF @@rowCount = 0 BEGIN
   SET @msg = ''Error encountered while inserting/updating FTP account.  Profile not found.'' + @msgTag + '';Error='' + cast(@error as nvarchar(10)) + ''>''
   EXECUTE error$raise @msg, @error
   RETURN -100
END

-- Insert the profile if it does not exist.  Update otherwise.
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

IF EXISTS(SELECT 1 FROM FtpAccount WHERE AccountId = @accountId) BEGIN
   UPDATE FtpAccount
   SET    ProfileId = @profileId
   WHERE  AccountId = @accountId
END
ELSE BEGIN
   INSERT FtpAccount (ProfileId, AccountId)
   VALUES(@profileId, @accountId)
END

SELECT @error = @@error

IF @error != 0 BEGIN
   ROLLBACK TRANSACTION @tranName
   COMMIT TRANSACTION
   SET @msg = ''Error encountered while inserting/updating FTP account.'' + @msgTag + '';Error='' + cast(@error as nvarchar(10)) + ''>''
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
-- Database Version
--
-------------------------------------------------------------------------------
EXECUTE
(
'
IF NOT EXISTS(SELECT 1 FROM DatabaseVersion WHERE Major = 1 AND Minor = 0 AND Revision = 0) BEGIN
   DECLARE @x nvarchar(1000)
   EXECUTE spidLogin$ins ''System'', ''Insert database version'', @x out
   INSERT DatabaseVersion (Major, Minor, Revision) VALUES (1, 0, 0)
   EXECUTE spidLogin$del ''System''
END
'
)

END

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- ENBRIGDE ADAPTATION
--
-- The following code became necessary in response to a Recall client wanting
-- to track containers as media.
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- Remove index from type name alone and create index on type name and container bit
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS WHERE CONSTRAINT_NAME = 'akMediumType$TypeName') BEGIN
   ALTER TABLE MediumType DROP CONSTRAINT akMediumType$TypeName
END

IF INDEXPROPERTY(object_id('MediumType'), 'akMediumType$NameContainer' , 'IndexId') IS NULL BEGIN
   CREATE UNIQUE NONCLUSTERED INDEX akMediumType$NameContainer ON MediumType (TypeName ASC, Container ASC)
END

-- Add a TypeCode column to the MediumType table
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'MediumType' AND COLUMN_NAME = 'TypeCode') BEGIN
   ALTER TABLE MediumType ADD TypeCode nvarchar(32) NOT NULL CONSTRAINT defMediumType$TypeCode DEFAULT ''
END

-- If the RecallCode table exists, copy its medium code to the TypeCode column
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'RecallCode') BEGIN
   CREATE TABLE #tblRows (x int)
   SET  @exec = 'INSERT #tblRows SELECT count(*) FROM RecallCode'
   EXEC sp_executesql @exec
   IF EXISTS (SELECT 1 FROM #tblRows WHERE x != 0) BEGIN
	   SET @id = 0
	   WHILE 1 = 1 BEGIN
	      SELECT TOP 1 @id = TypeId
	      FROM   MediumType
	      WHERE  TypeId > @id
	      ORDER  BY TypeId ASC
	      IF @@rowcount = 0
	         BREAK
	      ELSE BEGIN
	         SET  @exec = 'DECLARE @x nvarchar(1000)
                          SET NOCOUNT ON
                          IF EXISTS (SELECT 1 FROM RecallCode WHERE TypeId = ' + cast(@id as nvarchar(50)) + ') BEGIN
                             EXEC spidLogin$ins ''System'', ''Move vault medium type codes'', @x out                          
                             UPDATE MediumType 
                             SET    TypeCode = isnull((SELECT Code FROM RecallCode WHERE TypeId = ' + cast(@id as nvarchar(50)) + '), '''') 
                             WHERE  TypeId = ' + cast(@id as nvarchar(50)) + '
                             EXEC spidLogin$del ''System''
                          END'
	         EXEC sp_executesql @exec
	      END
	   END
   END
   DROP TABLE #tblRows
   -- Drop the Recall table, which will drop all constraints and triggers
   DROP TABLE RecallCode
END

-------------------------------------------------------------------------------
--
-- Triggers - MediumType
--
-------------------------------------------------------------------------------
IF (SELECT objectproperty(object_id('mediumType$afterInsert'), 'ExecIsInsertTrigger')) = 1
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'TRIGGER mediumType$afterInsert
ON    MediumType
WITH  ENCRYPTION
AFTER INSERT
AS
BEGIN
DECLARE @msg nvarchar(255)        -- used to preformat error message
DECLARE @msgTag nvarchar(255)     -- used to hold first part of error message header
DECLARE @tranName nvarchar(255)   -- used to hold name of savepoint
DECLARE @typeCode nvarchar(32)
DECLARE @typeName nvarchar(128)
DECLARE @rowcount int
DECLARE @typeId int
DECLARE @error int
DECLARE @id int

SET @rowcount = @@rowcount
IF @rowcount = 0 RETURN

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=T''
SET @tranName = object_name(@@procid) + CAST(trigger_nestlevel(@@procid) as nvarchar(2))

-- Begin transaction
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

-- Make sure we do not have a batch insert
IF @rowCount > 1 BEGIN
   SET @msg = ''Batch insert into medium type table not allowed.'' + @msgTag + ''>''
   EXECUTE error$raise @msg, 0, @tranName
   RETURN
END

-- Get the caller login from the spidLogin table
IF len(dbo.string$GetSpidLogin()) = 0 BEGIN
   SET @msg = ''No login found for auditing purposes.'' + @msgTag + ''>''
   EXECUTE error$raise @msg, 0, @tranName
   RETURN
END

-- Get the type code and type name
SELECT @typeId = TypeId,
       @typeName = TypeName,
       @typeCode = TypeCode
FROM   Inserted

-- If the TypeCode is not an empty string, make sure that any other type with this code has the same type name 
IF EXISTS (SELECT 1 FROM MediumType WHERE TypeCode = @typeCode AND TypeName != @typeName AND len(@typeCode) != 0) BEGIN
   SET @msg = ''A different medium type already has type code '''' + @typeName + '''' attached to it.'' + @msgTag + ''>''
   EXECUTE error$raise @msg, 0, @tranName
   RETURN
END

-- If there is another medium type of the same type name, then we have to update so that they all
-- have the same.  To do this, if the new type code is not the empty string, then update the
-- other entries to have this type code.  Otherwise, get the first type code of the same type name
-- that is not the empty string, and update the other media types of the same name with it.
IF EXISTS (SELECT 1 FROM MediumType WHERE TypeCode != @typeCode AND TypeName = @typeName) BEGIN
   IF len(@typeCode) != 0 BEGIN
	   UPDATE MediumType
	   SET    TypeCode = @typeCode
	   WHERE  TypeName = @typeName AND TypeId != @typeId
   END
   ELSE BEGIN
      UPDATE MediumType
      SET    TypeCode = (SELECT TOP 1 TypeCode FROM MediumType WHERE TypeName = @typeName AND len(TypeCode) != 0)
      WHERE  TypeId = @typeId
   END
	SET @error = @@error
	IF @error != 0 BEGIN
	   SET @msg = ''Error encountered while updating similarly named media types with type code.'' + @msgTag + '';Error='' + cast(@error as nvarchar(10)) + ''>''
	   EXECUTE error$raise @msg, @error, @tranName
	   RETURN
	END
END

COMMIT TRANSACTION
END
'
)

IF (SELECT objectproperty(object_id('mediumType$afterUpdate'), 'ExecIsUpdateTrigger')) = 1
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'TRIGGER mediumType$afterUpdate
ON    MediumType
WITH  ENCRYPTION
AFTER UPDATE
AS
BEGIN
DECLARE @msg nvarchar(255)        -- used to preformat error message
DECLARE @msgTag nvarchar(255)     -- used to hold first part of error message header
DECLARE @tranName nvarchar(255)   -- used to hold name of savepoint
DECLARE @typeCode nvarchar(32)
DECLARE @typeName nvarchar(128)
DECLARE @rowcount int
DECLARE @typeId int
DECLARE @error int            

SET @rowcount = @@rowcount
IF @rowcount = 0 RETURN

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=T''
SET @tranName = object_name(@@procid) + CAST(trigger_nestlevel(@@procid) as nvarchar(2))

-- Begin transaction
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

-- Make sure we do not have a batch update
IF @rowCount > 1 BEGIN
   SET @msg = ''Batch update of medium type table not allowed.'' + @msgTag + ''>''
   EXECUTE error$raise @msg, 0, @tranName
   RETURN
END

-- Get the caller login from the spidLogin table
IF len(dbo.string$GetSpidLogin()) = 0 BEGIN
   SET @msg = ''No login found for auditing purposes.'' + @msgTag + ''>''
   EXECUTE error$raise @msg, 0, @tranName
   RETURN
END

-- Make sure that, if there are multiple entries of the same type code (e.g. a large case type
-- is listed once as a container and once as a medium type), they have the same type name.
SELECT @typeCode = TypeCode
FROM   MediumType
WHERE  len(rtrim(TypeCode)) != 0
GROUP  BY TypeCode
HAVING count(distinct TypeName) > 1
IF @@rowcount != 0 BEGIN
   SET @msg = ''Types of the same type code must have the same medium type name.'' + @msgTag + ''>''
   EXECUTE error$raise @msg, 0, @tranName
   RETURN
END

-- Make sure that, if there are multiple entries of the same name (e.g. a large case type
-- is listed once as a container and once as a medium type), they have the same medium code
SET @typeName = ''''
WHILE 1 = 1 BEGIN
	SELECT TOP 1 @typeName = TypeName
	FROM   MediumType
	WHERE  len(rtrim(TypeCode)) != 0 AND TypeName > @typeName
	GROUP  BY TypeName
	HAVING count(distinct TypeCode) > 1
   ORDER  BY TypeName ASC
	IF @@rowcount = 0
      BREAK
   ELSE BEGIN
      UPDATE MediumType
      SET    TypeCode = (SELECT TOP 1 TypeCode FROM MediumType WHERE TypeName = @typeName AND len(TypeCode) != 0)
      WHERE  TypeId = @typeId
		SET @error = @@error
		IF @error != 0 BEGIN
		   SET @msg = ''Error encountered while updating similarly named media types with type code.'' + @msgTag + '';Error='' + cast(@error as nvarchar(10)) + ''>''
		   EXECUTE error$raise @msg, @error, @tranName
		   RETURN
		END
   END
END

COMMIT TRANSACTION
END
'
)

-------------------------------------------------------------------------------
--
-- Functions - MediumType
--
-------------------------------------------------------------------------------
-- Change references to RecallCode in sprocs to reference MediumType.TypeCode
IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'mediumType$getById')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.mediumType$getById
(
   @id int
)
WITH ENCRYPTION
AS
BEGIN

SET NOCOUNT ON

-- Select
SELECT TypeId,
       TypeName,
       TwoSided,
       Container,
       TypeCode as ''Code'',	-- For backward compatibility
       RowVersion
FROM   MediumType
WHERE  TypeId = @id

END
'
)

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'mediumType$getByName')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.mediumType$getByName
(
   @name nvarchar(128),
   @container int = -1	-- Default, for prior to removing unique status from Name field
)
WITH ENCRYPTION
AS
BEGIN
DECLARE @isContainer bit

SET NOCOUNT ON

IF @container = 0
   SET @isContainer = 0
ELSE IF @container = 1
   SET @isContainer = 1

IF @container = -1 BEGIN
	SELECT TOP 1 TypeId,
	       TypeName,
	       TwoSided,
	       Container,
	       TypeCode as ''Code'',	-- For backward compatibility
	       RowVersion
	FROM   MediumType
	WHERE  TypeName = @name
END
ELSE BEGIN
	SELECT TypeId,
	       TypeName,
	       TwoSided,
	       Container,
	       TypeCode as ''Code'',	-- For backward compatibility
	       RowVersion
	FROM   MediumType
	WHERE  TypeName = @name AND Container = @isContainer
END

END
'
)

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'mediumType$getTableRecall') BEGIN
   EXEC ('DROP PROCEDURE mediumType$getTableRecall')
END

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'mediumType$getTable')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.mediumType$getTable
(
   @vaultCode int = 0  -- Parameter obsolete; present for backward compatibility
)
WITH ENCRYPTION
AS
BEGIN
DECLARE @msg as nvarchar(255)        -- used to preformat error message
DECLARE @msgTag as nvarchar(255)     -- used to hold first part of error message header

SET NOCOUNT ON

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=P''

SET NOCOUNT ON

-- Select
SELECT   TypeId,
         TypeName,
         TwoSided,
         Container,
         TypeCode as ''Code'',  -- For backward compatibility
         RowVersion
FROM     MediumType m
ORDER BY TypeName ASC

END
'
)

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'mediumType$ins')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.mediumType$ins
(
   @name nvarchar(128),           -- name of the medium type
   @twoSided bit,                 -- flag whether or not medium is two-sided
   @container bit,                -- flag whether or not type is a container
   @typeCode nvarchar(32) = '''', -- medium type code
   @newId int = NULL OUT         -- returns the id value for the newly created medium type
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

INSERT MediumType
(
   TypeName, 
   TwoSided,
   Container
)
VALUES
(
   @name, 
   @twoSided,
   @container
)

SET @error = @@error
IF @error != 0 BEGIN
   ROLLBACK TRANSACTION @tranName
   COMMIT TRANSACTION
   SET @msg = ''Error encountered while inserting a new medium type.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
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

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'mediumType$upd')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.mediumType$upd
(
   @id int,
   @name nvarchar(128),
   @twoSided bit,
   @container bit,
   @typeCode nvarchar(32) = '''',
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

-- Update the medium type, then the Recall code
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

UPDATE MediumType
SET    TypeName = @name,
       TwoSided = @twoSided,
       Container = @container,
       TypeCode = @typeCode
WHERE  TypeId = @id AND RowVersion = @rowVersion

SELECT @error = @@error, @rowCount = @@rowcount

IF @error != 0 BEGIN
   ROLLBACK TRANSACTION @tranName
   COMMIT TRANSACTION
   SET @msg = ''Error encountered while updating medium type.'' + @msgTag + '';Error='' +  cast(@error as nvarchar(50)) + ''>''
   EXECUTE error$raise @msg, @error
   RETURN -100
END
ELSE IF @rowCount = 0 BEGIN
   IF EXISTS(SELECT 1 FROM MediumType WHERE TypeId = @id) BEGIN
      ROLLBACK TRANSACTION @tranName
      COMMIT TRANSACTION
      SET @msg = ''Medium type has been modified since retrieval.'' + @msgTag + ''>''
      RAISERROR(@msg,16,1)
      RETURN -100
   END
   ELSE BEGIN
      ROLLBACK TRANSACTION @tranName
      COMMIT TRANSACTION
      SET @msg = ''Medium type does not exist.'' + @msgTag + ''>''
      RAISERROR(@msg,16,1)
      RETURN -100
   END
END

-- Commit the transaction and get the new rowVersion value
COMMIT TRANSACTION
RETURN 0
END
'
)

-------------------------------------------------------------------------------
--
-- Functions - Recall Code
--
-------------------------------------------------------------------------------
IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'recallCode$ins')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.recallCode$ins
(
   @code nvarchar(32),          -- recall code
   @typeId int                  -- medium type to which code corresponds
)
WITH ENCRYPTION
AS
BEGIN
DECLARE @msg as nvarchar(255)        -- used to preformat error message
DECLARE @msgTag as nvarchar(255)     -- used to hold first part of error message header
DECLARE @tranName as nvarchar(255)   -- used to hold name of savepoint
DECLARE @error as int

SET NOCOUNT ON

-- Trim the code
SET @code = ltrim(rtrim(isnull(@code,'''')))

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=P''
SET @tranName = object_name(@@procid) + CAST(@@nestlevel as nvarchar(2))

BEGIN TRANSACTION
SAVE TRANSACTION @tranName

UPDATE MediumType
SET    TypeCode = @code
WHERE  TypeId = @typeId

SET @error = @@error
IF @error != 0 BEGIN
   SET @msg = ''Error encountered while attaching a new Recall code.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
   EXECUTE error$raise @msg, @error, @tranName
   RETURN -100
END

COMMIT TRANSACTION
RETURN 0
END
'
)

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'recallCode$upd')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.recallCode$upd
(
   @code nvarchar(32),
   @typeId int

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

-- Trim the code
SET @code = ltrim(rtrim(isnull(@code,'''')))

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=P''
SET @tranName = object_name(@@procid) + CAST(@@nestlevel as nvarchar(2))

-- Update the medium type, then the Recall code
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

UPDATE MediumType
SET    TypeCode = @code
WHERE  TypeId = @typeId

SELECT @error = @@error, @rowCount = @@rowcount

IF @error != 0 BEGIN
   ROLLBACK TRANSACTION @tranName
   COMMIT TRANSACTION
   SET @msg = ''Error encountered while updating Recall code.'' + @msgTag + '';Error='' +  cast(@error as nvarchar(50)) + ''>''
   EXECUTE error$raise @msg, @error
   RETURN -100
END
ELSE IF @rowCount = 0 BEGIN
   ROLLBACK TRANSACTION @tranName
   COMMIT TRANSACTION
   SET @msg = ''Recall code does not exist.'' + @msgTag + ''>''
   RAISERROR(@msg,16,1)
   RETURN -100
END

-- Commit the transaction
COMMIT TRANSACTION
RETURN 0
END
'
)

-------------------------------------------------------------------------------
--
-- Functions - Medium
--
-------------------------------------------------------------------------------
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

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'medium$upd')
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
          LastMoveDate = cast(convert(nchar(19),getdate(),120) as datetime),
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

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'medium$addLiteral')
   SET @CREATE = 'ALTER '
ELSE
   SET @CREATE = 'CREATE '

EXECUTE
(
@CREATE + 'PROCEDURE dbo.medium$addLiteral
(
   @serialNo nvarchar(32),           -- medium serial number
   @location bit,                    -- where to add medium
   @mediumType nvarchar(256) = '''',   -- type of medium
   @accountName nvarchar(256) = '''',  -- account for medium
   @mediumId int out
)
WITH ENCRYPTION
AS
BEGIN
DECLARE @msg as nvarchar(255)      -- used to preformat error message
DECLARE @msgTag as nvarchar(255)    -- used to hold first part of error message header
DECLARE @tranName as nvarchar(255)   -- used to hold name of savepoint
DECLARE @systemType nvarchar(256)    -- the medium type recommended by the system
DECLARE @systemAccount nvarchar(256)    -- the account recommended by the system
DECLARE @returnValue int
DECLARE @accountId int
DECLARE @typeId int
DECLARE @error int
DECLARE @pos int

SET NOCOUNT ON

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=P''
SET @tranName = object_name(@@procid) + CAST(@@nestlevel as nvarchar(2))

-- Tweak parameters
SET @serialNo = ltrim(rtrim(coalesce(@serialNo,'''')))
SET @mediumType = ltrim(rtrim(coalesce(@mediumType,'''')))
SET @accountName = ltrim(rtrim(coalesce(@accountName,'''')))
SET @mediumId = 0

-- If no serial number, raise error
IF len(@serialNo) = 0 BEGIN
   SET @msg = ''Serial number not supplied.'' + @msgTag + ''>''
   RAISERROR(@msg,16,1)
   RETURN -100
END

-- Get the system recommended defaults
execute barCodePattern$getDefaults @serialNo, @systemType out, @systemAccount out
IF len(@mediumType) = 0 SET @mediumType = @systemType
IF len(@accountName) = 0 SET @accountName = @systemAccount

-- Get the medium type id and account id
SELECT @typeId = TypeId 
FROM   MediumType 
WHERE  TypeName = @mediumType
IF @@rowcount = 0 BEGIN
   SET @msg = ''Medium type '' + @mediumType + '' not found.'' + @msgTag + ''>''
   RAISERROR(@msg,16,1)
   RETURN -100
END
SELECT @accountId = AccountId
FROM   Account
WHERE  AccountName = @accountName
IF @@rowcount = 0 BEGIN
   SET @msg = ''Account '' + @accountName + '' not found.'' + @msgTag + ''>''
   RAISERROR(@msg,16,1)
   RETURN -100
END

-- Get the medium id
SELECT @mediumId = MediumId
FROM   Medium
WHERE  SerialNo = @serialNo
  
-- Begin transaction
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

-- We only need to add a bar code pattern if either the type name differs
-- or the account name differs.
IF @mediumType != @systemType or @accountName != @systemAccount BEGIN
   -- Place a table lock on the bar code pattern table, to prevent
   -- multiple connection from updaating at the same time
   SELECT 1
   FROM   BarCodePattern
   WITH  (UPDLOCK TABLOCK HOLDLOCK)
   -- If the bar code pattern exists, remove it and decrease the position
   -- of all the formats above it.
   IF EXISTS (SELECT 1 FROM BarCodePattern WHERE Pattern = @serialNo) BEGIN
      -- Select the position of the bar code format to be moved and remove it
      SELECT @pos = Position
      FROM   BarCodePattern
      WHERE  Pattern = @serialNo
      DELETE BarCodePattern
      WHERE  Position = @pos
      -- Update the position of patterns with positions higher than that
      UPDATE BarCodePattern
      SET    Position = Position - 1
      WHERE  Position > @pos
      -- Evaluate the error
      SET @error = @@error
      IF @error != 0 BEGIN
         ROLLBACK TRANSACTION @tranName
         COMMIT TRANSACTION
         SET @msg = ''Error encountered while decreasing bar code format positions.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
         EXECUTE error$raise @msg, @error
         RETURN -100
      END
   END
   -- Going to need to insert a literal bar code pattern.  Make room at the top
   -- by incrementing all positions.
   UPDATE BarCodePattern
   SET    Position = Position + 1
   -- Evaluate the error
   SET @error = @@error
   IF @error != 0 BEGIN
      ROLLBACK TRANSACTION @tranName
      COMMIT TRANSACTION
      SET @msg = ''Error encountered while increasing bar code format positions.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
      EXECUTE error$raise @msg, @error
      RETURN -100
   END
   -- Insert the bar code pattern
   INSERT BarCodePattern (Pattern, Position, TypeId, AccountId)
   VALUES(@serialNo, 1, @typeId, @accountId)
   -- Evaluate the error
   SET @error = @@error
   IF @error != 0 BEGIN
      ROLLBACK TRANSACTION @tranName
      COMMIT TRANSACTION
      SET @msg = ''Error encountered while inserting literal bar code format.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
      EXECUTE error$raise @msg, @error
      RETURN -100
   END
   -- If the medium exists, update it
   IF @mediumId != 0 BEGIN
      UPDATE Medium
      SET    TypeId = @typeId,
             AccountId = @accountId
      WHERE  MediumId = @mediumId
      -- Evaluate the error
      SET @error = @@error
      IF @error != 0 BEGIN
         ROLLBACK TRANSACTION @tranName
         COMMIT TRANSACTION
         SET @msg = ''Error encountered while updating medium to accord with literal bar code format.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
         EXECUTE error$raise @msg, @error
         RETURN -100
      END
   END
END

-- Add the medium if it does not exist
IF @mediumId = 0 BEGIN
   EXECUTE @returnValue = medium$addDynamic @serialNo, @location, @mediumId out
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
--
-- Functions - Send List Case
--
-------------------------------------------------------------------------------
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
      SET @msg = ''A cleared send list case may not be altered.'' + @msgTag + ''>''
      RAISERROR(@msg,16,1)
      RETURN -100
   END
END

-- Verify that the case does not appear on any lists that have been 
-- transmitted or cleared.
IF EXISTS
   (
   SELECT 1
   FROM   SendListCase slc
   JOIN   SendListItemCase slic
     ON   slic.CaseId = slc.CaseId
   JOIN   SendListItem sli
     ON   sli.ItemId = slic.ItemId
   WHERE  slc.CaseId = @caseId AND sli.Status IN (256,1024) -- power(4,x)
   )
BEGIN
   SET @msg = ''Send list case may not be altered after being tranmsmitted or cleared.'' + @msgTag + ''>''
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

-------------------------------------------------------------------------------
--
-- Functions - Vault Inventory Item
--
-------------------------------------------------------------------------------
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
DECLARE @typeCount int
DECLARE @mediumId int
DECLARE @location bit
DECLARE @typeId int
DECLARE @error int

SET NOCOUNT ON

-- Tweak parameters
SET @notes = coalesce(@notes,'''')
SET @serialNo = coalesce(@serialNo,'''')
SET @typeName = coalesce(@typeName,'''')

-- Set up the error message tag and transaction tag (nest level ensures uniqueness)
SET @msgTag = ''<'' + object_name(@@procid) + '';Type=P''
SET @tranName = object_name(@@procid) + CAST(@@nestlevel as nvarchar(2))

-- Get the number of types with the same type name.  There may be at most two: one
-- container and one non-container.  If there are two, then if the serial number
-- is known as a medium, add the item with the non-container type; otherwise add
-- the item with a container type.
SELECT @typeCount = count(*)
FROM   MediumType
WHERE  TypeName = @typeName
IF @typeCount = 0 BEGIN
   SET @msg = ''Medium type unknown.'' + @msgTag + '';Type='' + @typeName + ''>''
   RAISERROR(@msg,16,1)
   RETURN -100
END
ELSE IF @typeCount = 1 BEGIN
	SELECT @typeId = TypeId
	FROM   MediumType
	WHERE  TypeName = @typeName
END
ELSE BEGIN
   IF EXISTS (SELECT 1 FROM Medium WHERE SerialNo = @serialNo) BEGIN
		SELECT @typeId = TypeId
		FROM   MediumType
		WHERE  TypeName = @typeName AND Container = 0
   END
   ELSE BEGIN
		SELECT @typeId = TypeId
		FROM   MediumType
		WHERE  TypeName = @typeName AND Container = 1
   END
END

-- Insert record
BEGIN TRANSACTION
SAVE TRANSACTION @tranName

INSERT VaultInventoryItem
(
   SerialNo,
   TypeId,
   HotStatus,
   InventoryId
)
VALUES
(
   @serialNo,
   @typeId,
   @hotStatus,
   @inventoryId
)

SET @error = @@error
IF @error != 0 BEGIN
   ROLLBACK TRANSACTION @tranName
   COMMIT TRANSACTION
   SET @msg = ''Error encountered while inserting new vault inventory item.'' + @msgTag + '';Error='' + cast(@error as nvarchar(50)) + ''>''
   EXECUTE error$raise @msg, @error
   RETURN -100
END

-- If the type is a non-container type and the serial number does not
-- exist in the medium table, create it at the vault.
IF EXISTS (SELECT 1 FROM MediumType WHERE TypeId = @typeId AND Container = 0) BEGIN
   SELECT @mediumId = MediumId 
   FROM   Medium 
   WHERE  SerialNo = @serialNo
   IF @@rowcount = 0 BEGIN
	   EXECUTE @returnValue = medium$addDynamic @serialNo, 0, @mediumId OUT
	   IF @returnValue != 0 BEGIN
	      ROLLBACK TRANSACTION @tranName
	      COMMIT TRANSACTION
	      RETURN -100
	   END
   END
	-- Update the medium notes if we have an inventory item note, there are 
	-- no current notes on the medium, and the medium is at the vault.
	IF len(@notes) != 0 AND EXISTS (SELECT 1 FROM Medium WHERE MediumId = @mediumId AND len(Notes) = 0 AND Location = 0) BEGIN
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
GO

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- DISASTER CODE ADAPTATION
--
-- The following code became necessary in response to the necessity to allow
-- the empty string as a valid disaster code.
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
IF NOT EXISTS
   (
   SELECT 1 
   FROM   INFORMATION_SCHEMA.CHECK_CONSTRAINTS 
   WHERE  CONSTRAINT_NAME = 'chkDisasterCode$Code' AND 
          CHARINDEX('[bit$IsEmptyString]([Code]) = 1',CHECK_CLAUSE) != 0 AND
          CHARINDEX('[bit$LegalCharacters]([Code], ''ALPHANUMERIC'', null) = 1',CHECK_CLAUSE) != 0
   )
BEGIN
   EXECUTE ('ALTER TABLE DisasterCode DROP CONSTRAINT chkDisasterCode$Code')
   ALTER TABLE DisasterCode ADD CONSTRAINT chkDisasterCode$Code
       CHECK (dbo.bit$IsEmptyString(Code) = 1 OR dbo.bit$LegalCharacters(Code, 'ALPHANUMERIC', NULL ) = 1)
END
GO

IF NOT EXISTS
   (
   SELECT 1 
   FROM   INFORMATION_SCHEMA.CHECK_CONSTRAINTS 
   WHERE  CONSTRAINT_NAME = 'chkDisasterCodeListItem$Code' AND 
          CHARINDEX('[bit$IsEmptyString]([Code]) = 1',CHECK_CLAUSE) != 0 AND
          CHARINDEX('[bit$LegalCharacters]([Code], ''ALPHANUMERIC'', null) = 1',CHECK_CLAUSE) != 0
   )
BEGIN
   EXECUTE ('ALTER TABLE DisasterCodeListItem DROP CONSTRAINT chkDisasterCodeListItem$Code')
   ALTER TABLE DisasterCodeListItem ADD CONSTRAINT chkDisasterCodeListItem$Code
      CHECK (dbo.bit$IsEmptyString(Code) = 1 OR dbo.bit$LegalCharacters(Code, 'ALPHANUMERIC', NULL ) = 1)
END
GO

-------------------------------------------------------------------------------
--
-- Constraints for the TypeCode column
--
-------------------------------------------------------------------------------
-- Originally the default constraint on the medium type table was misnamed
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS WHERE TABLE_NAME = 'MediumType' AND CONSTRAINT_NAME = 'MediumType$TypeCode') BEGIN
   ALTER TABLE MediumType DROP CONSTRAINT MediumType$TypeCode
   ALTER TABLE MediumType ADD  CONSTRAINT defMediumType$TypeCode DEFAULT '' FOR TypeCode
END

-- Add a check to the medium type code
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.CHECK_CONSTRAINTS WHERE CONSTRAINT_NAME = 'chkMediumType$TypeCode') BEGIN
   ALTER TABLE MediumType ADD CONSTRAINT chkMediumType$TypeCode 
      CHECK (dbo.bit$IsEmptyString(TypeCode) = 1 OR dbo.bit$LegalCharacters(TypeCode,'ALPHANUMERIC','') = 1)
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
