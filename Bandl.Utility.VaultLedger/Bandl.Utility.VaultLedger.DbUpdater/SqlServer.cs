using System;
using System.Data;
using System.Data.Sql;
using System.Data.SqlClient;
using System.Collections.Generic;
using System.Runtime.InteropServices;
using System.Linq;
using System.Text;
using System.Windows.Forms;

namespace Bandl.Utility.VaultLedger.DbUpdater
{
    public class SqlServer
    {
        #region O D B C   3 2
        [DllImport("odbc32.dll")]
        private static extern short SQLAllocHandle(short handleType, IntPtr inputHandle, out IntPtr outputHandlePtr);
        [DllImport("odbc32.dll")]
        private static extern short SQLSetEnvAttr(IntPtr environmentHandle, int attribute, IntPtr valuePtr, int stringLength);
        [DllImport("odbc32.dll")]
        private static extern short SQLFreeHandle(short hType, IntPtr Handle);
        [DllImport("odbc32.dll", CharSet = CharSet.Ansi)]
        private static extern short SQLBrowseConnect(IntPtr handleConnection, StringBuilder inConnection, short stringLength, StringBuilder outConnection, short bufferLength, out short stringLength2Ptr);
        // Constants
        private const Int16 SQL_HANDLE_ENV = 1;
        private const Int16 SQL_HANDLE_DBC = 2;
        private const Int32 SQL_ATTR_ODBC_VERSION = 200;
        private const Int32 SQL_OV_ODBC3 = 3;
        private const Int16 SQL_SUCCESS = 0;
        private const Int16 SQL_NEED_DATA = 99;
        private const Int16 DEFAULT_RESULT_SIZE = 1024;
        #endregion

        #region P R I V A T E   F I E L D S
        private String server;
        private String database;
        private String password;
        private String userid;
        private Boolean trusted;
        private SqlConnection sqlconnection;
        #endregion

        #region P R I V A T E   P R O P E R T I E S
        private String ConnectString
        {
            get
            {
                StringBuilder b1 = new StringBuilder();
                // Serverf
                b1.AppendFormat("SERVER={0};POOLING=FALSE", this.server);
                // Database?
                if (!String.IsNullOrEmpty(this.database.Trim()))
                {
                    b1.AppendFormat(";DATABASE={0}", this.database);
                }
                // Trusted?
                if (this.trusted)
                {
                    b1.Append(";INTEGRATED SECURITY=SSPI");
                }
                else if (String.IsNullOrEmpty(this.password))
                {
                    b1.AppendFormat(";USER ID={0}", this.userid);
                }
                else
                {
                    b1.AppendFormat(";USER ID={0};PASSWORD={1}", this.userid, this.password);
                }
                // Return
                return b1.ToString();
            }
        }
        #endregion

        #region C O N S T R U C T O R S
        public SqlServer(String server) : this(server, null, null, null) { }
        public SqlServer(String server, String database) : this(server, database, null, null) { }
        public SqlServer(String server, String login, String password) : this(server, null, login, password) { }
        public SqlServer(String server, String database, String login, String password)
        {
            this.server = server;
            this.database = String.IsNullOrEmpty(database) ? "master" : database;
            this.trusted = String.IsNullOrEmpty(login.Trim());
            this.password = password;
            this.userid = login;
        }
        #endregion

        #region P U B L I C   S T A T I C   M E T H O D S
        public static String[] GetSqlServers()
        {
            IntPtr h1 = IntPtr.Zero;
            IntPtr h2 = IntPtr.Zero;

            try
            {
                StringBuilder inString = new StringBuilder("DRIVER=SQL SERVER");
                StringBuilder outString = new StringBuilder(DEFAULT_RESULT_SIZE);
                short inStringLength = (short)inString.Length;
                short lenNeeded = 0;
                // Do
                if (SQL_SUCCESS != SQLAllocHandle(SQL_HANDLE_ENV, h1, out h1))
                {
                    throw new ApplicationException("Unable to allocate ODBC environment handle during discovery phase");
                }
                else if (SQL_SUCCESS != SQLSetEnvAttr(h1, SQL_ATTR_ODBC_VERSION, (IntPtr)SQL_OV_ODBC3, 0))
                {
                    throw new ApplicationException("Unable to set ODBC environment attribute during discovery phase");
                }
                else if (SQL_SUCCESS != SQLAllocHandle(SQL_HANDLE_DBC, h1, out h2))
                {
                    throw new ApplicationException("Unable to allocate ODBC connection handle during discovery phase");
                }
                else if (SQL_NEED_DATA != SQLBrowseConnect(h2, inString, inStringLength, outString, DEFAULT_RESULT_SIZE, out lenNeeded))
                {
                    throw new ApplicationException("Failure during initial browse invocation");
                }
                else if (DEFAULT_RESULT_SIZE < lenNeeded)   // more capacity needed
                {
                    outString.Capacity = lenNeeded;

                    if (SQL_NEED_DATA != SQLBrowseConnect(h2, inString, inStringLength, outString, lenNeeded, out lenNeeded))
                    {
                        throw new ApplicationException("Failure during second browse invocation");
                    }
                }
                // Parse
                String x1 = outString.ToString();
                Int32 i1 = x1.IndexOf("{") + 1;
                Int32 i2 = x1.IndexOf("}") - i1;
                // Split
                x1 = (i1 != -1 && i2 != -1) ? x1.Substring(i1, i2) : String.Empty;
                // Return
                return x1.Split(new char[] { ',' });
            }
            finally
            {
                if (h2 != IntPtr.Zero) SQLFreeHandle(SQL_HANDLE_DBC, h2);
                if (h1 != IntPtr.Zero) SQLFreeHandle(SQL_HANDLE_ENV, h1);
            }
        }
        #endregion

        #region P U B L I C   I N S T A N C E   M E T H O D S
        /// <summary>
        /// Test connection
        /// </summary>
        public void Connect()
        {
            using (SqlConnection c1 = new SqlConnection(ConnectString))
            {
                c1.Open();
            }
        }

        /// <summary>
        /// Get the version of the database
        /// </summary>
        /// <param name="c1"></param>
        /// <param name="ma"></param>
        /// <param name="mi"></param>
        /// <param name="re"></param>
        public void GetDatabaseVersion(out Int32 ma, out Int32 mi, out Int32 re)
        {
            ma = 1;
            mi = 0;
            re = 0;
            // Any tables?
            SqlCommand c2 = this.sqlconnection.CreateCommand();
            c2.CommandType = CommandType.Text;
            c2.CommandText = "SELECT CASE WHEN EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES) THEN 1 ELSE 0 END";
            // If so, get from version
            if (Convert.ToInt32(c2.ExecuteScalar()) == 1)
            {
                c2 = this.sqlconnection.CreateCommand();
                c2.CommandType = CommandType.Text;
                c2.CommandText = "SELECT TOP 1 MAJOR, MINOR, REVISION FROM DATABASEVERSION ORDER BY MAJOR DESC, MINOR DESC, REVISION DESC";
                using (SqlDataReader r1 = c2.ExecuteReader())
                {
                    if (r1.HasRows)
                    {
                        r1.Read();
                        ma = r1.GetInt32(0);
                        mi = r1.GetInt32(1);
                        re = r1.GetInt32(2);
                    }
                }
            }
        }

        /// <summary>
        /// Get list of VaultLedger databases
        /// </summary>
        /// <returns></returns>
        public List<String> GetVaultLedgerDatabases()
        {
            List<String> n1 = new List<String>();
            // Get the databases
            using (SqlConnection c1 = new SqlConnection(this.ConnectString))
            {
                c1.Open();
                this.sqlconnection = c1;
                // Set command
                SqlCommand c2 = c1.CreateCommand();
                c2.CommandType = CommandType.StoredProcedure;
                c2.CommandText = "sp_databases";
                using (SqlDataReader r1 = c2.ExecuteReader())
                {
                    while (r1.Read())
                    {
                        n1.Add(r1.GetString(0));
                    }
                }
                // Run through each database, testing validity
                for (Int32 i = n1.Count - 1; i > -1; i -= 1)
                {
                    c1.ChangeDatabase(n1[i]);
                    // Test database validity
                    if (this.Valid() == false) n1.RemoveAt(i);
                }
            }
            // Return
            return n1;
        }

        /// <summary>
        /// Updates the VaultLedger database
        /// </summary>
        /// <returns></returns>
        public void Update()
        {
            using (SqlConnection c1 = new SqlConnection(this.ConnectString))
            {
                c1.Open();
                this.sqlconnection = c1;
                // Initialize
                Int32 ma, mi, re;
                String q1 = null;
                // Valid?
                if (this.Valid() == false)
                    throw new ApplicationException(String.Format("Database '{0}' is not a valid VaultLedger database.", this.database));
                // Get the current version
                this.GetDatabaseVersion(out ma, out mi, out re);
                // Create the update file object
                SqeFile dbf = new SqeFile(ma, mi, re);
                // Start with the last update
                Boolean b1 = dbf.Exists() ? true : dbf.NextFile();
                // Update
                while (b1)
                {
                    // Execute
                    if ((q1 = dbf.GetContents()).Length != 0)
                        ExecuteCommands(q1.Replace("\nGOTO", "\n GOTO"));   // insert a space in the GOTO commands so that they will not cause a split in ExecuteCommands()
                    // Next
                    b1 = dbf.NextFile();
                }
            }
        }

        public void Update(String q1)
        {
            using (SqlConnection c1 = new SqlConnection(this.ConnectString))
            {
                c1.Open();
                this.sqlconnection = c1;
                ExecuteCommands(q1.Replace("\nGOTO", "\n GOTO"));   // insert a space in the GOTO commands so that they will not cause a split in ExecuteCommands()
            }
        }

        public void CreateDatabase(String database)
        {
            String b1 = @"DECLARE @x1 nvarchar(128)
                          DECLARE @q1 nvarchar(1000)
                          DECLARE @f1 nvarchar(512)
                          DECLARE @f2 nvarchar(512)
                          DECLARE @p1 nvarchar(512)
                          DECLARE @e1 int
                          DECLARE @c1 int

                          SET NOCOUNT ON

                          -- Initialize
                          SELECT @x1 = '" + database + @"'
                          SELECT @f1 = ''
                          SELECT @f2 = ''

                          -- Create the database if it does not exist
                          IF NOT EXISTS (SELECT 1 FROM master.dbo.sysdatabases WHERE name = @x1) BEGIN

                             -- Get the data file path
                             SELECT TOP 1 @p1 = left(FileName, len(FileName) - charindex('\\',reverse(rtrim(FileName))) + 1) 
                             FROM   master.dbo.sysfiles

                             -- Form file names
                             SELECT @f1 = @p1 + @x1 + '.mdf'
                             SELECT @f2 = @p1 + @x1 + '.ldf'

                             -- Do the files exist?
                             EXECUTE master.dbo.xp_fileexist @f1, @c1 output

                             -- Initialize statement
                             SELECT @q1 = 'CREATE DATABASE [' + @x1 + '] ON (NAME = ' + @x1 + ', FILENAME = ''' + @f1 + ''') LOG ON (NAME = ' + @x1 + '_Log, FILENAME = ''' + @f2 + ''')'

                             -- Attach?

                             IF @c1 = 1 SET @q1 = @q1 + ' FOR ATTACH'

                             -- Execute
                             EXECUTE sp_executesql @q1

                              -- Alter database files
                             IF @@error = 0 BEGIN
                                -- Set it to have recursive triggers
                                SELECT @q1 = 'ALTER DATABASE [' + @x1 + '] SET RECURSIVE_TRIGGERS ON'
                                EXECUTE sp_executesql @q1
                                -- Create temp table of files
                                CREATE TABLE #t1 (FileName nvarchar(512))
                                SELECT @q1 = 'INSERT #t1 (FileName) SELECT name FROM ' + @x1 + '.dbo.sysfiles', @f1 = ''
                                EXECUTE sp_executesql @q1
                                -- Alter the database files
                                WHILE 1 = 1 BEGIN
                                   SELECT TOP 1 @f1 = FileName
                                   FROM   #t1
                                   WHERE  FileName > @f1
                                   ORDER  BY FileName ASC
                                   IF @@rowcount = 0 BREAK
                                   SELECT @q1 = 'ALTER DATABASE [' + @x1 + '] MODIFY FILE (NAME = ' + @f1 + ', MAXSIZE = UNLIMITED)'
                                   EXECUTE sp_executesql @q1
                                   SELECT @q1 = 'ALTER DATABASE [' + @x1 + '] MODIFY FILE (NAME = ' + @f1 + ', FILEGROWTH = 10MB)'
                                   EXECUTE sp_executesql @q1
                                END
                                -- Drop table
                                DROP TABLE #t1
                             END

                          END";

            // Perform query
            using (SqlConnection c1 = new SqlConnection(this.ConnectString))
            {
                c1.Open();
                SqlCommand c2 = c1.CreateCommand();
                c2.CommandType = CommandType.Text;
                c2.CommandText = b1;
                c2.CommandTimeout = 0;
                c2.ExecuteNonQuery();

                c1.ChangeDatabase(database);

                c2 = c1.CreateCommand();
                c2.CommandType = CommandType.Text;
                c2.CommandText = @"EXEC
                                   (
                                   '
                                   EXECUTE sp_configure ''clr enable'', 1;
                                   RECONFIGURE WITH OVERRIDE;
                                   IF NOT EXISTS (SELECT 1 FROM sys.assemblies WHERE Name = ''Bandl.VaultLedger'') BEGIN
                                      DECLARE @x1 nvarchar(4000)
                                      DECLARE @s1 nvarchar(4000)
                                      SELECT  @s1 = coalesce(''MSSQL$'' + convert(nvarchar(4000), SERVERPROPERTY(''InstanceName'')), ''MSSQLSERVER'')
                                      SELECT  @s1 = ''SYSTEM\CurrentControlSet\Services\'' + @s1
                                      EXECUTE master..xp_instance_regread ''HKEY_LOCAL_MACHINE'', @s1, ''ImagePath'', @x1 output
                                      SELECT  @x1 = SUBSTRING(REVERSE(SUBSTRING(REVERSE(@x1), CHARINDEX(''\'', REVERSE(@x1)), 4000)), CHARINDEX('':'', @x1) - 1, 4000) + ''Bandl.VaultLedger.Sql.dll''
                                      EXECUTE (''CREATE ASSEMBLY [Bandl.VaultLedger] FROM '''''' + @x1 + '''''' WITH PERMISSION_SET = SAFE'')
                                   END
                                   '
                                   )";
                c2.CommandTimeout = 0;
                c2.ExecuteNonQuery();
            }
        }

        public void CreateOwner(String login, String password)
        {
            String b1 = @"DECLARE @database nvarchar(128)
                          DECLARE @login nvarchar(128)
                          DECLARE @password nvarchar(128)
                          DECLARE @q1 nvarchar(2048)

                          SELECT @database = db_name()
                          SELECT @login = @p1
                          SELECT @password = @p2

                          -- Add the login if it does not exist
                          SET @q1 = 'CREATE LOGIN ' + @login + ' WITH PASSWORD = ''' + @password + ''', CHECK_POLICY = OFF, DEFAULT_DATABASE = [' + @database + ']'
                          IF NOT EXISTS (SELECT 1 FROM master.dbo.syslogins WHERE name = @login) EXECUTE sp_executesql @q1

                          -- Alter the password
                          SET @q1 = 'ALTER LOGIN ' + @login + ' WITH PASSWORD = ''' + @password + ''', CHECK_POLICY = OFF, DEFAULT_DATABASE = [' + @database + ']'
                          EXECUTE sp_executesql @q1

                          -- Create the user
                          SET @q1 = 'CREATE USER ' + @login + ' FOR LOGIN ' + @login + ' WITH DEFAULT_SCHEMA = dbo'
                          IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = @login) EXECUTE sp_executesql @q1

                          -- If not member of db_owner, make it so
                          IF NOT EXISTS
                             (
                             SELECT u1.name
                             FROM   sys.sysusers u1
                             JOIN   sys.sysmembers m1
                               ON   m1.memberuid = u1.uid
                             JOIN   sys.sysusers u2
                               ON   u2.uid = m1.groupuid
                             WHERE  u1.name = @login AND u2.name = 'db_owner'
                             )
                          BEGIN
                            EXECUTE sp_addrolemember @rolename = 'db_owner', @membername = @login
                          END";

            using (SqlConnection c1 = new SqlConnection(this.ConnectString))
            {
                c1.Open();
                SqlCommand c2 = c1.CreateCommand();
                c2.CommandType = CommandType.Text;
                c2.CommandText = b1;
                c2.Parameters.AddWithValue("@p1", login);
                c2.Parameters.AddWithValue("@p2", password);
                c2.CommandTimeout = 0;
                c2.ExecuteNonQuery();
            }
        }

        public void CheckPermissions()
        {
            using (SqlConnection c1 = new SqlConnection(this.ConnectString))
            {
                try
                {
                    c1.Open();
                }
                catch
                {
                    throw new ApplicationException(String.Format("Failed to connect to {0} using {1}.", this.server, this.trusted ? "a trusted connection" : "user '" + this.userid + "'"));
                }
                // Set up the command
                SqlCommand c2 = c1.CreateCommand();
                c2.CommandType = CommandType.Text;
                c2.CommandText = "SELECT count(*) FROM fn_my_permissions(NULL, 'SERVER') WHERE permission_name IN ('CREATE ANY DATABASE', 'ALTER ANY LOGIN')";
                // Both should be present
                if (Convert.ToInt32(c2.ExecuteScalar()) != 2)
                {
                    throw new ApplicationException(String.Format("{0} does not have the permissions required for installation.  The supplied user must be granted both the CREATE ANY DATABASE permission and the ALTER ANY LOGIN permission.", this.trusted ? "The trusted connection" : "User '" + this.userid + "'"));
                }
            }
        }

        public String GetBinary()
        {
            using (SqlConnection c1 = new SqlConnection(this.ConnectString))
            {
                // Open
                c1.Open();
                // Get the path
                SqlCommand c2 = c1.CreateCommand();
                c2.CommandType = CommandType.Text;
                c2.CommandText = @"DECLARE @x1 nvarchar(128)
                                   EXEC MASTER.DBO.XP_INSTANCE_REGREAD N'HKEY_LOCAL_MACHINE', N'Software\Microsoft\MSSQLServer\Setup', N'SQLBinRoot', @x1 OUTPUT
                                   SELECT @x1";
                return Convert.ToString(c2.ExecuteScalar());
            }
        }
        #endregion

        #region P R I V A T E   I N S T A N C E   M E T H O D S
        /// <summary>
        /// Test validity of databases (i.e., is it an VaultLedger database?)
        /// </summary>
        private Boolean Valid()
        {
            try
            {
                SqlCommand c1 = this.sqlconnection.CreateCommand();
                c1.CommandType = CommandType.Text;
                c1.CommandText = "SELECT CASE WHEN EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES) THEN 1 ELSE 0 END";
                // If no tables, return true
                if (Convert.ToInt32(c1.ExecuteScalar()) != 1) return true;
                // Have particular table?
                c1 = this.sqlconnection.CreateCommand();
                c1.CommandType = CommandType.Text;
                c1.CommandText = "SELECT CASE WHEN EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'INVENTORYCONFLICTUNKNOWNSERIAL') THEN 1 ELSE 0 END";
                return Convert.ToInt32(c1.ExecuteScalar()) != 0;
            }
            catch
            {
                return false;
            }
        }

        private void ExecuteCommands(String q1)
        {
            // Insert a space in the GOTO commands so that they will not be used to truncate where a GO command is used to truncate
            String[] q2 = Replacer.Replace(q1).Split(new String[] { "\nGO" }, StringSplitOptions.None);
            // Execute the commands one by one
            for (int i = 0; i < q2.Length; i += 1)
            {
                if (q2[i].Trim().Length != 0)
                {
                    SqlCommand c2 = this.sqlconnection.CreateCommand();
                    c2.CommandType = CommandType.Text;
                    c2.CommandText = q2[i];
                    c2.CommandTimeout = 0;
                    c2.ExecuteNonQuery();
                }
            }
        }
        #endregion
    }
}
