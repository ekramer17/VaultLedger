using System;
using System.IO;
using System.Windows.Forms;

namespace Bandl.Utility.VaultLedger.Installation.ShortcutCreator
{
    /// <summary>
    /// Summary description for MainObject.
    /// </summary>
    class MainObject
    {
        /// <summary>
        /// The main entry point for the application.
        /// </summary>
        [STAThread]
        static int Main(string[] args)
        {
            try
            {
                bool doUninstall = false;
                string shortcut = String.Empty;
                string fileName = String.Empty;
                string iconFile = String.Empty;
                // Get the command line arguments
                ProcessCommandLine(ref fileName, ref shortcut, ref doUninstall, ref iconFile);
                // Make sure we have all parameters
                if (fileName.Length == 0)
                    throw new ApplicationException("No file name specified.");
                else if (!doUninstall && shortcut.Length == 0)
                    throw new ApplicationException("No shortcut path specified.");
                // Create or delete the shortcut
                if (!doUninstall)
                    CreateShortcut(fileName, shortcut, iconFile);
                else
                    DeleteShortcut(fileName);
                // Return
                return 0;
            }
            catch (Exception e)
            {
                MessageBox.Show(e.Message, "Shortcut Creator", MessageBoxButtons.OK, MessageBoxIcon.Warning);
                return -100;
            }
        }
        /// <summary>
        /// Processes the command line arguments and write the connection string to the web.config
        /// file in the parent directory
        ///
        /// Command line flags: 
        /// /f:file name
        /// /s:shortcut path
        /// </summary>
        /// <param name="commandLine">
        /// Array of command line arguments
        /// </param>
        private static void ProcessCommandLine(ref string fileName, ref string shortcut, ref bool doUninstall, ref string iconFile)
        {
            // Get the command line arguments
            string[] commandLine = Environment.GetCommandLineArgs();
            // Parse the command line
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
                            fileName = s.Replace(String.Format("{0}{0}", Path.DirectorySeparatorChar), Path.DirectorySeparatorChar.ToString());
                            break;
                        case "/s":
                            shortcut = s;
                            break;
                        case "/u":
                            doUninstall = true;
                            break;
                        case "/i":
                            iconFile = s;
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
        /// Creates the shortcut
        /// </summary>
        private static void CreateShortcut(string fileName, string shortcut, string iconFile)
        {
            int i = -1;
            // If the directory does not exist, create it
            while ((i = fileName.IndexOf(Path.DirectorySeparatorChar, i+1)) != -1)
                if (!Directory.Exists(fileName.Substring(0, i)))
                    Directory.CreateDirectory(fileName.Substring(0, i));
            // Write the shortcut
            using (StreamWriter streamWriter = new StreamWriter(fileName, false))
            {
                streamWriter.WriteLine("[InternetShortcut]");
                streamWriter.WriteLine("URL={0}", shortcut);
                if (iconFile.Length != 0)
                {
                    streamWriter.WriteLine("IconFile={0}", iconFile);
                    streamWriter.WriteLine("IconIndex=0");
                }

/*
URL=http://www.someaddress.com/
WorkingDirectory=C:\WINDOWS\
ShowCommand=7
IconIndex=1
IconFile=C:\WINDOWS\SYSTEM\url.dll
Modified=20F06BA06D07BD014D
HotKey=1601
*/            }
        }
        /// <summary>
        /// Creates the shortcut
        /// </summary>5
        private static void DeleteShortcut(string fileName)
        {
            int i;
            // Delete the file
            try
            {
                File.Delete(fileName);
            }
            catch
            {
                ;
            }
            // Go upward through directory tree.  Delete any empty directories.
            while ((i = fileName.LastIndexOf(Path.DirectorySeparatorChar)) != -1)
            {
                string directoryName = fileName.Substring(0, i);
                // If the directory does not exist or is not empty, break the
                // loop.  Otherwise, delete the directory.
                if (!Directory.Exists(directoryName))
                {
                    break;
                }
                else if (Directory.GetFiles(directoryName).Length != 0 || Directory.GetDirectories(directoryName).Length != 0)
                {
                    break;
                }
                else
                {
                    Directory.Delete(directoryName);
                    fileName = directoryName;
                }
            }        
        }
    }
}
