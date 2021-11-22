using System;
using System.IO;
using Microsoft.Win32;
using System.Windows.Forms;

namespace Bandl.Utility.VaultLedger.Installation.RegistryReader
{
    /// <summary>
    /// Summary description for Class1.
    /// </summary>
    class MainObject
    {
        private static string keyName = String.Empty;
        private static string valueName = String.Empty;
        private static string text = String.Empty;
        private static string fileName = String.Empty;
        private static bool delete = false;
        private static bool write = false;
        /// <summary>
        /// The main entry point for the application.
        /// </summary>
        static int Main() 
        {
            try
            {
                // Parse the command line
                ProcessCommandLine(Environment.GetCommandLineArgs());
                // If we're writing, set the value.  If reading get it and write it to file.
                if (write == true)
                {
                    Registry.LocalMachine.OpenSubKey(keyName, true).SetValue(valueName, text);
                }
                else if (delete == true)
                {
                    // Truncate the key name at the last slash
                    string deleteThis = keyName.Substring(keyName.LastIndexOf(@"\") + 1);
                    keyName = keyName.Substring(0, keyName.LastIndexOf(@"\"));
                    // Open the key
                    RegistryKey key = Registry.LocalMachine.OpenSubKey(keyName, true);
                    // Delete the subkey
                    key.DeleteSubKeyTree(deleteThis);
                    // Close the key
                    key.Close();
                }
                else
                {
                    using (StreamWriter w = new StreamWriter(fileName))
                    {
                        w.WriteLine((string)Registry.LocalMachine.OpenSubKey(keyName).GetValue(valueName, String.Empty));
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
        /// /r:read
        /// /k:key name
        /// /v:value name
        /// /o:output file
        /// /t:text
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
                    if (j == -1) throw new ApplicationException("Incorrect syntax (" + commandLine[i] + ")");
                    // Split the field on the colon
                    string s = commandLine[i].Substring(j + 1).Trim();
                    // Get the value based on the first half
                    switch (commandLine[i].Substring(0,j).ToLower())
                    {
                        case "/r":
                            write = s.ToUpper() == "FALSE";
                            break;
                        case "/d":
                            delete = s.ToUpper() == "TRUE";
                            break;
                        case "/k":
                            keyName = s;
                            break;
                        case "/v":
                            valueName = s;
                            break;
                        case "/o":
                            fileName = s;
                            break;
                        case "/t":
                            text = s;
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
    }
}
