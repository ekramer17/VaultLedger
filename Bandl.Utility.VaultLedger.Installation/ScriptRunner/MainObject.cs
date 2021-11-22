using System;
using System.IO;
using System.Net;
using System.Drawing;
using System.Collections;
using System.ComponentModel;
using System.Windows.Forms;
using System.Data;
using System.Data.SqlClient;
using Bandl.Library.VaultLedger.Common.Knock;

namespace Bandl.Utility.VaultLedger.Installation.ScriptRunner
{
    /// <summary>
    /// Summary description for Class1.
    /// </summary>
    class MainObject
    {
        private static string serverName = Guid.NewGuid().ToString();
        private static string databaseName = Guid.NewGuid().ToString();
        private static string userId = String.Empty;
        private static string password = String.Empty;
        private static string fileName = String.Empty;
        private static string directory = String.Empty;
        private static string connectionString = String.Empty;
        private static string encryptVector = String.Empty;
        private static string commandText = String.Empty;
        private static string applicationName = String.Empty;	// product type
        private static ArrayList fileNames = new ArrayList();

        /// <summary>
        /// The main entry point for the application.
        /// </summary>
        static int Main()
        {
            try
            {   
                // Process the command line
                ProcessCommandLine(Environment.GetCommandLineArgs());
                // Execute command(s) as necessary
                if (commandText.Length != 0)
                {
                    ExecuteText();
                }
                else 
                {
                    if (directory.Length != 0)
                    {
                        fileNames = GetFiles(directory);
                    }
                    else if (fileName.Length != 0) 
                    {
                        fileNames.Add(fileName);
                    }
                    // Execute the script(s)
                    ExecuteScript();
                }
                // Return
                return 0;
            }
            catch (Exception ex)
            {
                MessageBox.Show(ex.Message, applicationName == "BANDL" ? "VaultLedger" : "ReQuest Media Manager", MessageBoxButtons.OK, MessageBoxIcon.Stop);
                return -100;
            }
        }
        /// <summary>
        /// Processes the command line arguments and write the connection string to the web.config
        /// file in the parent directory
        ///
        /// Command line flags: 
        /// /s:serverName
        /// /db:databaseName
        /// /id:loginId
        /// /pwd:password
        /// /p:productName
        /// </summary>
        /// <param name="commandLine">
        /// Array of command line arguments
        /// </param>
        private static void ProcessCommandLine(string[] commandLine)
        {
            try
            {
                for (int i = 1; i < commandLine.Length; i++)
                {
                    int j = commandLine[i].IndexOf(':');
                    // Make sure we have a colon
                    if (j == -1)
                        throw new ApplicationException("Incorrect syntax (" + commandLine[i] + ")");
                    // Split the field on the colon
                    string s = commandLine[i].Substring(j + 1).Trim();
                    // Get the value based on the first half
                    switch (commandLine[i].Substring(0,j).ToLower())
                    {
                        case "/s":
                            serverName = s.EndsWith(@"\") ? s.Substring(0,s.Length-1) : s;
                            break;
                        case "/db":
                            databaseName = s;
                            break;
                        case "/id":
                            userId = s;
                            break;
                        case "/pwd":
                            password = s;
                            break;
                        case "/a":
                            applicationName = s;
                            break;
                        case "/f":
                            fileName = s;
                            break;
                        case "/d":
                            directory = s.Replace(@"\.", String.Empty);  // directory has to end with self-referential period to avoid messing up command line
                            break;
                        case "/v":
                            encryptVector = s;
                            break;
                        case "/t":
                            commandText = s;
                            break;
                        default:
                            throw new ApplicationException(String.Format("Unknown flag ({0})", s[0]));
                    }
                }
            }
            catch (Exception ex)
            {
                throw new ApplicationException("Error in command line: " + ex.Message);
            }
            // Create the connection string
            if (password.Length != 0)
            {
                connectionString = String.Format("Server={0};Database={1};User Id={2};Password={3};Pooling=False", serverName, databaseName, userId, password);
            }
            else
            {
                connectionString = String.Format("Server={0};Database={1};User Id={2};Pooling=False", serverName, databaseName, userId);
            }
        }

        #region Script Execution Methods
        /// <summary>
        /// Executes the script
        /// </summary>
        /// <param name="connectString">
        /// Connection string to use
        /// </param>
        /// <param name="fileName">
        /// Name of script file to execute
        /// </param>
        private static void ExecuteText()
        {
            // Execute the commands
            using (SqlConnection c = new SqlConnection(connectionString))
            {
                // Open the connection
                c.Open();
                // Run the command
                try
                {
                    SqlCommand cmd = c.CreateCommand();
                    cmd.CommandType = CommandType.Text;
                    cmd.CommandText = commandText;
                    cmd.CommandTimeout = 300;
                    cmd.ExecuteNonQuery();
                }
                catch (SqlException ex)
                {
                    throw new ApplicationException("Error " + ex.Number.ToString() + ": " + ex.Message);
                }
            }
        }
        /// <summary>
        /// Executes the script
        /// </summary>
        /// <param name="connectString">
        /// Connection string to use
        /// </param>
        /// <param name="isUpdate">
        /// Whether or not we're employing update scripts.  Update scripts are numbered (i.e.
        /// </param>
        private static void ExecuteScript()
        {
            string q = null;
            bool b = directory == String.Empty;
            // Get the first update script to run.  Only valid if we have an update script.  Update scripts end in ".sqe".
            string recentVersion = GetMostRecentScriptVersion();
            // For each file in the array list, execute the script
            foreach (string fileName in fileNames)
            {
                // If it's an update script and we have not yet reached the most recent version number, go to next iteration
                if (fileName.EndsWith(".sqe") && GetScriptVersion(fileName).CompareTo(recentVersion) < 0) continue;
                // Get the encrypted SQL commands
                using (StreamReader r = new StreamReader(fileName))
                {
                    q = r.ReadToEnd();
                }
                // If it was encrypted, decrypt it
                if (fileName.EndsWith(".sqe") && encryptVector.Length != 0)
                {
                    q = Balance.Exhume(Convert.FromBase64String(q), Convert.FromBase64String(encryptVector));
                }
                // Replace any script necessary
                q = ReplaceScript(q, applicationName);
                // Put a space before any GOTO commands at the beginning of a line, so that they will 
                // not get confused with the GO commands at the beginning of a line.
                q = q.Replace("\nGOTO", "\n GOTO");
                // Execute the commands
                using (SqlConnection c = new SqlConnection(connectionString))
                {
                    int x = 0, y = 0;
                    string text = String.Empty;
                    // Open the connection
                    c.Open();
                    // Run the commands
                    while ((x = q.IndexOf("\nGO", y)) != -1 && y < q.Length )
                    {
                        // Get the command text
                        text = q.Substring(y, x - y).Trim();
                        // Move the bookmark pointer up past "\nGO"
                        y = x + 3;
                        // Execute the command
                        SqlCommand cmd = c.CreateCommand();
                        cmd.CommandType = CommandType.Text;
                        cmd.CommandText = text;
                        cmd.CommandTimeout = 300;
                        try
                        {
                            cmd.ExecuteNonQuery();
                        }
                        catch (SqlException ex)
                        {
                            if (ex.Number != 5170 && ex.Number != 1802)
                            {
                                throw new ApplicationException("Error " + ex.Number.ToString() + ": " + ex.Message);
                            }
                        }
                    }
                }
            }
        }
        #endregion

        #region Utility Methods
        /// <summary>
        /// Gets an ordered list of the sqe files in a given directory
        /// </summary>
        /// <param name="directory">directory in which to search for .sqe files</param>
        /// <returns>List of .sqe files, in numerical order</returns>
        private static ArrayList GetFiles(string directory)
        {
            int ma = 1, mi = 0, re = -1;
            ArrayList fileList = new ArrayList();
            // Order the script files
            while (true)
            {
                if (File.Exists(SqeFileName(directory, ma, mi, ++re)))
                {
                    fileList.Add(SqeFileName(directory, ma, mi, re));
                }
                else if (File.Exists(SqeFileName(directory, ma, ++mi, (re = 0))))
                {
                    fileList.Add(SqeFileName(directory, ma, mi, re));
                }
                else if (File.Exists(SqeFileName(directory, ++ma, (mi = 0), (re = 0))))
                {
                    fileList.Add(SqeFileName(directory, ma, mi, re));
                }
                else
                {
                    return fileList;
                }
            }
        }
        /// <summary>
        /// Consolidates the parameters into a sqe file name
        /// </summary>
        /// <param name="directory">directory in which to search for the file</param>
        /// <param name="ma">major version number</param>
        /// <param name="mi">minor version number</param>
        /// <param name="re">revision version number</param>
        /// <returns></returns>
        private static string SqeFileName(string directory, int ma, int mi, int re)
        {
            return Path.Combine(directory, String.Format("{0}_{1}_{2}.sqe", ma, mi, re)).Trim();
        }
        /// <summary>
        /// Executes the script
        /// </summary>
        /// <param name="fileName">
        /// Name of script file
        /// </param>
        /// <param name="productType">
        /// Product type
        /// </param>
        private static string ReplaceScript(string sql, string productType)
        {
            // Text strings based on product
            switch (productType.ToUpper())
            {
                case "BANDL":
                    sql = sql.Replace("<databaseName>", "VaultLedger");
//                    sql = sql.Replace("<operatorLogin>", "BLOperator");
//                    sql = sql.Replace("<operatorPassword>", "A1!s0n?K");
//                    sql = sql.Replace("<ownerLogin>", "BLUpdater");
//                    sql = sql.Replace("<ownerPassword>", "d4n13!");
//                    sql = sql.Replace("<roleName>", "BLRole");
                    break;
                case "RECALL":
                    sql = sql.Replace("<databaseName>", "ReQuest");
//                    sql = sql.Replace("<operatorLogin>", "RMMOperator");
//                    sql = sql.Replace("<operatorPassword>", "A1!s0n?K");
//                    sql = sql.Replace("<ownerLogin>", "RMMUpdater");
//                    sql = sql.Replace("<ownerPassword>", "d4n13!");
//                    sql = sql.Replace("<roleName>", "RMMRole");
                    break;
            }
            // Return the script
            return sql;
        }
        /// <summary>
        /// Gets the first script file to be run against the database.  This will be either the current
        /// version of the database or, if the database has not yet been initialized, the first script.
        /// </summary>
        /// <returns>
        /// First version on which to execute update
        /// </returns>
        private static string GetMostRecentScriptVersion()
        {
            using (SqlConnection c = new SqlConnection(connectionString))
            {
                c.Open();
                SqlCommand cmd = c.CreateCommand();
                cmd.CommandType = CommandType.Text;
                cmd.CommandText = "IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'DatabaseVersion') ";
                cmd.CommandText += "SELECT TOP 1 Major, Minor, Revision FROM DatabaseVersion ORDER BY Major DESC, Minor DESC, Revision DESC";
                using (SqlDataReader r = cmd.ExecuteReader())
                {
                    if (r.HasRows == false) 
                    {
                        return "1.0.0";
                    }
                    else
                    {
                        r.Read();
                        return String.Format("{0}.{1}.{2}", r.GetInt32(0), r.GetInt32(1), r.GetInt32(2));
                    }
                }
            }
        }
        /// <summary>
        /// Gets the file name from a full path
        /// </summary>
        /// <param name="path"></param>
        /// <returns></returns>
        private static string GetScriptVersion(string filePath)
        {
            int i = -1;
            if ((i = filePath.LastIndexOf(Path.DirectorySeparatorChar)) != 0)
                return filePath.Substring(i + 1).Replace("_",".").Replace(".sqe",String.Empty);
            else
                return filePath.Replace("_",".").Replace(".sqe",String.Empty);
        }
        #endregion
    }
}
