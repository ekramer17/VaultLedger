using System;
using System.Windows.Forms;
using System.ServiceProcess;
using Microsoft.Win32;

namespace Bandl.Utility.VaultLedger.Installation.ServiceStarter
{
    /// <summary>
    /// Summary description for Class1.
    /// </summary>
    class MainObject
    {
        private static string serviceName = String.Empty;
        private static string appName = "VaultLedger";

        /// <summary>
        /// The main entry point for the application.
        /// </summary>
        static int Main()
        {
            try
            {
                ProcessCommandLine(Environment.GetCommandLineArgs());
                StartService();
                return 0;
            }
            catch (Exception ex)
            {
                MessageBox.Show(ex.Message, appName, MessageBoxButtons.OK, MessageBoxIcon.Stop);
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
        /// /a:applicationName
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
                            serviceName = s;
                            break;
                        case "/a":
                            appName = s;
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
        /// Starts the given service
        /// </summary>
        private static void StartService()
        {
            ServiceController x = new ServiceController();
            x.ServiceName = serviceName;
            // Start the service
            if (x.Status != ServiceControllerStatus.Running)
            {
                try
                {
                    x.Start();
                    x.WaitForStatus(ServiceControllerStatus.Running,TimeSpan.FromSeconds(10));
                }
                catch
                {
                    throw new ApplicationException("Unable to start " + serviceName + " service.");
                }
            }
        }
    }
}
