using System;
using System.IO;
using Microsoft.Win32;
using System.Reflection;
using System.Windows.Forms;

namespace Bandl.Utility.VaultLedger.SqlLibRemoter
{
    static class Program
    {
        static bool myTest = false;
        static bool myLocal = false;
        static string myServer = String.Empty;
        static string mySharePath = String.Empty;
        static string myInstance = String.Empty;
        const string SHARE_NAME = "VLBINSH"; //"SSBINETSH";

        /// <summary>
        /// The main entry point for the application.
        /// </summary>
        [STAThread]
        static int Main(string[] args)
        {
            // Get the parameters from the command line
            try
            {
                ProcessCommandLine(Environment.GetCommandLineArgs());
                // If local, just copy the files to the path given as the share path
                if (myLocal == true)
                {
                    return DoLocal(myInstance);
                }
                else
                {
                    return DoRemote();
                }
            }
            catch (Exception ex)
            {
                MessageBox.Show(ex.Message, "Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
                return -100;
            }
        }
        /// <summary>
        ///  Processes the command line arguments and write the connection string to the web.config
        ///  file in the parent directory
        /// </summary>
        /// <param name="commandLine">
        /// Array of command line arguments
        /// </param>
        private static void ProcessCommandLine(string[] commandLine)
        {
            // Command line flags
            //
            // /s:<server>
            // /p:<remote path>
            // /i:<instance name>
            // /t  -- only test the directory to see if it is a valid sql server binary directory
            try
            {
                for (int i = 1; i < commandLine.Length; i++)
                {
                    int x = 0;
                    string val = String.Empty;
                    // Split the field on the colon
                    if ((x = commandLine[i].IndexOf(':')) != -1)
                    {
                        val = commandLine[i].Substring(x + 1);
                    }
                    else
                    {
                        x = commandLine[i].Length;
                    }
                    // Get the value based on the first half
                    if (commandLine[i][0] == '/' || commandLine[i][0] == '-')
                    {
                        switch (commandLine[i][1].ToString().ToLower())
                        {
                            case "s":
                                myServer = val.Trim();
                                break;
                            case "i":
                                myInstance = val.Trim();
                                break;
                            case "p":
                                mySharePath = val.Replace("\"", String.Empty).Trim();
                                break;
                            case "t":
                                myTest = true;
                                break;
                            default:
                                throw new ApplicationException(String.Format("Error in command line: Invalid switch ({0})", commandLine[i].Substring(0, x)));
                        }
                    }
                    // If local then get machine name
                    if (myServer.ToUpper() == "LOCALHOST")
                    {
                        myServer = Environment.MachineName;
                    }
                }
            }
            catch (Exception ex)
            {
                throw new ApplicationException("Error in command line: " + ex.Message);
            }
        }

        /// <summary>
        /// Copies a file from one place to another
        /// </summary>
        /// <param name="x1">Local file to copy</param>
        /// <param name="x2">Remote file destination</param>
        private static void CopyFile(string x1, string x2)
        {
            try
            {
                if (!File.Exists(x2))
                {
                    File.Copy(x1, x2, true);
                }
            }
            catch (IOException e1)
            {
                // If it's being used by another process, then we already have it, so
                // we can ignore the exception if that is the case.
                if (e1.Message.IndexOf("being used by another process") != -1)
                {
                    return;
                }
                else
                {
                    throw;
                }
            }
        }

        #region Local
        /// <summary>
        /// Copies the files to a local directory
        /// </summary>
        /// <param name="i1">instance name</param>
        /// <returns>1 on success, -1 if directory is not valid SQL Server binn directory, -100 on error</returns>
        private static int DoLocal(string i1)
        {
            // Get the local path
            string p1 = GetLocalBinaryPath(i1);
            // Test the directory
            if (File.Exists(String.Format("{0}sqlboot.dll", p1)) == false)
            {
                MessageBox.Show("Local path does not represent a valid MS SQL Server binary file directory.", "Error", MessageBoxButtons.OK, MessageBoxIcon.Warning);
                return -1;
            }
            else
            {
                try
                {
                    if (myTest == false)
                    {
                        // Create the paths
                        string s1 = Path.Combine(Application.StartupPath, " ").Trim();
                        // Copy the files
//                        CopyFile(s1 + "xp_pcre.dll", p1 + "xp_pcre.dll");
//                        CopyFile(s1 + "pcre-0.dll", p1 + "pcre-0.dll");
                        CopyFile(s1 + "Bandl.VaultLedger.Sql.dll", p1 + "Bandl.VaultLedger.Sql.dll");
                    }
                    // Return
                    return 0;
                }
                catch (Exception ex)
                {
                    MessageBox.Show("Unable to copy SQL Server binaries." + Environment.NewLine + Environment.NewLine + ex.Message, "Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
                    return -100;
                }
            }
        }
        /// <summary>
        /// Gets the local binary path
        /// </summary>
        /// <param name="i1">instance name</param>
        /// <returns>local binary directory</returns>
        private static string GetLocalBinaryPath(string i1)
        {
            RegistryKey k1 = Registry.LocalMachine.OpenSubKey(@"SYSTEM\CurrentControlSet\Services\MSSQL" + (i1.Length != 0 ? "$" + i1 : "SERVER"));
            // Make sure the key exists
            if (k1 == null) throw new ApplicationException("Unable to find local service MSSQL" + (i1.Length != 0 ? "$" + i1 : "SERVER") + " in registry");
            // Read the imagepath value
            try
            {
                string p1 = (string)k1.GetValue("ImagePath");
                return p1.Substring(0, p1.LastIndexOf('\\')).Replace("\"", "") + "\\";
            }
            finally
            {
                k1.Close();
            }
        }
        #endregion

        #region Remote
        /// <summary>
        /// Moves the files to the network share
        /// </summary>
        /// <param name="serverName">Name of shared server</param>
        /// <param name="shareName">Name of network share</param>
        private static void CopySqlServerFiles()
        {
            // Create the paths
            string x1 = Path.Combine(Application.StartupPath, " ").Trim();
            string x2 = String.Format(@"\\{0}\{1}\", myServer, SHARE_NAME);
            // Copy the files
//            CopyFile(x1 + "xp_pcre.dll", x2 + "xp_pcre.dll");
//            CopyFile(x1 + "pcre-0.dll", x2 + "pcre-0.dll");
            CopyFile(x1 + "Bandl.VaultLedger.Sql.dll", x2 + "Bandl.VaultLedger.Sql.dll");
        }
        /// <summary>
        /// Copies the files to a remote directory
        /// </summary>
        /// <returns>0 on success, -1 if directory is not valid SQL Server binn directory, -100 on error</returns>
        private static int DoRemote()
        {
            // Create a new net api object
            Net32API api32 = new Net32API();
            // Adjust the server name and share path
            if (myServer.StartsWith(@"\\")) myServer = myServer.Substring(2);
            if (mySharePath.EndsWith(Path.DirectorySeparatorChar.ToString())) mySharePath = mySharePath.Substring(0, mySharePath.Length - 1);

            try
            {
                // Create the share
                try
                {
                    api32.CreateShare(myServer, mySharePath, SHARE_NAME, "Share for copying VaultLedger files to SQL Server binary directory", false);
                }
                catch (Exception ex)
                {
                    MessageBox.Show("Unable to create network share." + Environment.NewLine + Environment.NewLine + ex.Message, "Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
                    return -100;
                }
                // Test the directory
                if (File.Exists(String.Format(@"\\{0}\{1}\sqlboot.dll", myServer, SHARE_NAME)) == false)
                {
                    MessageBox.Show("Remote path does not represent a valid MS SQL Server binary file directory.", "Error", MessageBoxButtons.OK, MessageBoxIcon.Warning);
                    return -1;
                }
                // Test or move files
                if (myTest == false)
                {
                    try
                    {
                        CopySqlServerFiles();
                    }
                    catch (Exception ex)
                    {
                        MessageBox.Show("Unable to copy SQL Server binaries." + Environment.NewLine + Environment.NewLine + ex.Message, "Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
                        return -100;
                    }
                }
                // Return success
                return 0;
            }
            finally
            {
                try
                {
                    api32.DeleteShare(myServer, SHARE_NAME);
                }
                catch
                {
                    ;
                }
            }
        }
        #endregion
    }
}
