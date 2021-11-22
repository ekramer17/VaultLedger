using System;
using System.IO;
using System.Net;
using System.Collections;
using System.Text;
using System.ComponentModel;
using System.Data;
using System.Xml;
using System.Windows.Forms;
using System.Data.SqlClient;
using Bandl.Library.VaultLedger.Common.Knock;

namespace Bandl.Utility.VaultLedger.Installation.ConfigReader
{
    /// <summary>
    /// Summary description for MainObject.
    /// </summary>
    class MainObject
    {
        private static string fileName = String.Empty;
        private static string application = "VaultLedger";
        private static string serverName = String.Empty;
        private static string databaseName = String.Empty;
        private static string outputFile = String.Empty;
        private static string userid = String.Empty;
        private static string password = "d4n13l";
        private static string currentUser = String.Empty;
        private static string currentPass = String.Empty;
        private static bool compilation = false;  // If true, set compilation attribute to false

        /// <summary>
        /// The main entry point for the application.
        /// </summary>
        static int Main()
        {
            try
            {
                string fileLine = String.Empty;
                // Parse the command line
                ProcessCommandLine(Environment.GetCommandLineArgs());
                // If we are setting the compilation element, do nothing else
                if (compilation == true)
                {
                    SetCompileAttribute();
                }
                else
                {
                    // Get the server name
                    if (GetSqlParameters() != -100)
                    {
                        fileLine = String.Format("{0}{1}{2}{1}{3}{1}{4}", serverName, "$NEWLINE$", databaseName, currentUser, currentPass);
                    }
                    // Get the connection string
                    if (TestConnection() != -100)
                    {
                        fileLine += String.Format("{1}{0}{1}{2}", userid, "$NEWLINE$", password);
                    }
                    // Write the connection string to the output file
                    using (StreamWriter w = new StreamWriter(outputFile, false))
                    {
                        w.WriteLine(fileLine);
                    }
                }
                // Return
                return 0;
            }
            catch
            {
                return -100;
            }
        }
        /// <summary>
        /// Processes the command line arguments and write the connection string to the web.config
        /// file in the parent directory
        ///
        /// Command line flags: 
        /// /a:applicationName
        /// /p:full path of config file
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
                    string s = String.Empty;
                    int j = commandLine[i].IndexOf(':');
                    // Split the field on the colon
                    s = commandLine[i].Substring(j + 1).Trim();
                    if (j == -1) j = s.Length;
                    // Get the value based on the first half
                    switch (commandLine[i].Substring(0,j).ToLower())
                    {
                        case "/f":
                            fileName = s;
                            break;
                        case "/a":
                            application = s.ToUpper();
                            break;
                        case "/o":
                            outputFile = s;
                            break;
                        case "/c":
                            compilation = true;
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
        }
        /// <summary>
        /// Gets the server name and the database name from the configuration file
        /// </summary>
        private static int GetSqlParameters()
        {
            try
            {
                using (StreamReader r = new StreamReader(fileName))
                {
                    string c = String.Empty;
                    // Read the rest of the file, decrypt it, and load it into an XML document
                    XmlDocument xdoc = new XmlDocument();
                    xdoc.Load(new MemoryStream(Encoding.UTF8.GetBytes(r.ReadToEnd())));
                    // Make sure that the file is intended to create a ship list
                    XmlNode x1 = xdoc.DocumentElement.SelectSingleNode("./appSettings/add[attribute::key=\"ConnString\"]");
                    XmlNode x2 = xdoc.DocumentElement.SelectSingleNode("./appSettings/add[attribute::key=\"ConnVector\"]");
                    // Make sure we have nodes
                    if (x1 == null || x1.Attributes["value"].Value.Length == 0) 
                        throw new ApplicationException("Connection string nodes not found in application configuration file.");
                    // Get the values of the nodes
                    string s1 = x1.Attributes["value"].Value;
                    string s2 = x2 != null ? x2.Attributes["value"].Value : String.Empty;
                    // Decrypt the connection string
                    if (s1.IndexOf(';') != -1)
                        c = s1;
                    else if (s2 != null && s2.Length != 0)
                        c = Balance.Exhume(Convert.FromBase64String(s1), Convert.FromBase64String(s2));
                    else
                        c = Balance.Exhume(Convert.FromBase64String(s1));
                    // Get the server and database
                    foreach (string f in c.Split(new char[] {';'}))
                    {
                        if (f.ToUpper().StartsWith("SERVER=") || f.ToUpper().StartsWith("DATA SOURCE="))
                        {
                            serverName = f.Substring(f.IndexOf('=') + 1);
                        }
                        else if (f.ToUpper().StartsWith("DATABASE=") || f.ToUpper().StartsWith("INITIAL CATALOG="))
                        {
                            databaseName = f.Substring(f.IndexOf('=') + 1);
                        }
                        else if (f.ToUpper().StartsWith("USER ID="))
                        {
                            currentUser = f.Substring(f.IndexOf('=') + 1);
                        }
                        else if (f.ToUpper().StartsWith("PASSWORD="))
                        {
                            currentPass = f.Substring(f.IndexOf('=') + 1);
                        }
                    }
                    // Return 0 if we have both server name and database name, else -100
                    return serverName.Length == 0 || databaseName.Length == 0 ? -100 : 0;
                }
            }
            catch
            {
                return -100;
            }
        }
        /// <summary>
        /// Tests the connection
        /// </summary>
        private static int TestConnection()
        {
            string c = String.Format("Server={0};Database={1};Pooling=false;Password={2};", serverName, databaseName, password);
            // Connection string to test depends on product type
            switch (application)
            {
                case "RQMM":
                case "REQUEST":
                    userid = "RMMUpdater";
                    c += "User Id=RMMUpdater";
                    break;
                case "VAULTLEDGER":
                default:
                    userid = "BLUpdater";
                    c += "User Id=BLUpdater";
                    break;
            }
            // Attempt connection
            using (SqlConnection c1 = new SqlConnection(c))
            {
                try
                {
                    // Open the connection
                    c1.Open();
                    // Test the security privileges
                    SqlCommand cmd = c1.CreateCommand();
                    cmd.CommandType = CommandType.Text;
                    cmd.CommandText = "CREATE TABLE dbo.SecurityTest (ABC int NOT NULL)";
                    cmd.ExecuteNonQuery();
                    // If successful, drop the table
                    cmd = c1.CreateCommand();
                    cmd.CommandType = CommandType.Text;
                    cmd.CommandText = "DROP TABLE dbo.SecurityTest";
                    cmd.ExecuteNonQuery();
                    // Return
                    return 0;
                }
                catch
                {
                    return -100;
                }
            }
        }
        /// <summary>
        /// Sets the debug compilation element to false.  If something goes wrong here,
        /// no worries.  It's not especially critical...things will just be slower.
        /// </summary>
        private static void SetCompileAttribute()
        {
            try
            {
                // Get the xml document
                XmlDocument doc = new XmlDocument();
                doc.Load(fileName);
                // Get the compilation node
                XmlNode currentNode = doc.SelectSingleNode("/configuration/system.web/compilation");
                // If we have it, set the debug attribute to false
                if (currentNode != null)
                {
                    currentNode.Attributes["debug"].Value = "false";
                }
                // Save the document
                doc.Save(fileName);
            }
            catch
            {
                ;
            }
        }
    }
}
