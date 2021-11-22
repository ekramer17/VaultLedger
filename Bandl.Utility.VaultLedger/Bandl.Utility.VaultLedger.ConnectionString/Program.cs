using System;
using System.IO;
using System.Windows.Forms;
using System.Collections.Generic;
using System.Text.RegularExpressions;
using System.Text;

namespace Bandl.Utility.VaultLedger.ConnectionString
{
    public class Program
    {
        private static Boolean _quiet = false;
        private static String _infile = null;
        private static String _string = null;   // connection string
        private static String _outfile = null;

        /// <summary>
        /// The main entry point for the application.
        /// </summary>
        [STAThread]
        static Int32 Main(String[] args)
        {
            // Process the command line
            ProcessCommandLine(Environment.GetCommandLineArgs());
            // If input file is not null, then encrypt.  Otherwise, run the updater.
            if (_quiet == false)
            {
                Application.EnableVisualStyles();
                Application.SetCompatibleTextRenderingDefault(false);
                Application.Run(new Form1());
            }
            else
            {
                try
                {
                    String s1 = null;
                    String x1 = null;
                    // Read or write?
                    if (String.IsNullOrEmpty(_string))   // read
                    {
                        WebConfigFile w1 = new WebConfigFile(_infile);
                        s1 = w1.GetAppSetting("ConnString");
                        x1 = w1.GetAppSetting("ConnVector");
                        Program.RetrieveString(String.IsNullOrEmpty(x1) ? s1 : Crypto.Decrypt(s1, x1));
                    }
                    else
                    {
                        WebConfigFile w1 = new WebConfigFile(_outfile);
                        x1 = Convert.ToBase64String(Crypto.CreateCipher());
                        s1 = Convert.ToBase64String(Crypto.Encrypt(_string, x1));
                        w1.SetAppSetting("ConnString", s1);
                        w1.SetAppSetting("ConnVector", x1);
                    }
                }
                catch (Exception e)
                {
                    MessageBox.Show(e.Message, "VaultLedger", MessageBoxButtons.OK, MessageBoxIcon.Stop);
                    return -100;
                }
            }
            // Return
            return 0;
        }

        #region C O M M A N D   L I N E   M E T H O D S
        /// <summary>
        /// Processes the command line arguments and write the connection string to the web.config
        /// file in the parent directory
        /// </summary>
        /// <param name="commandLine">
        /// Array of command line arguments
        /// </param>
        private static void ProcessCommandLine(String[] args)
        {
            String key = null;

            try
            {
                for (Int32 i = 1; i < args.Length; i++)
                {
                    switch (key = GetKey(args[i]))
                    {
                        case "/q":
                            _quiet = true;
                            break;
                        case "/i":
                            _infile = GetValue(args[i]);
                            break;
                        case "/o":
                            _outfile = GetValue(args[i]);
                            break;
                        case "/s":
                            _string = GetValue(args[i]);
                            break;
                        default:
                            throw new ApplicationException("Unknown flag [" + key + "]");
                    }
                }
            }
            catch (Exception e)
            {
                throw new ApplicationException("Error in command line: " + e.Message);
            }
        }
        /// <summary>
        /// Processes the command line arguments and write the connection string to the web.config
        /// file in the parent directory
        /// </summary>
        /// <param name="commandLine">
        /// Array of command line arguments
        /// </param>
        private static String GetKey(String arg)
        {
            // Colon position
            Int32 x1 = arg.IndexOf(':');
            // Get key and value
            if (x1 != -1)
            {
                return arg.Substring(0, x1).Trim();
            }
            else
            {
                return arg.Trim();
            }
        }
        /// <summary>
        /// Processes the command line arguments and write the connection string to the web.config
        /// file in the parent directory
        /// </summary>
        /// <param name="commandLine">
        /// Array of command line arguments
        /// </param>
        private static String GetValue(string arg)
        {
            // Colon position
            Int32 x1 = arg.IndexOf(':');
            // Need colon?
            if (x1 == -1)
            {
                throw new ApplicationException("Incorrect syntax [" + arg + "]");
            }
            else
            {
                return x1 != -1 ? arg.Substring(x1 + 1).Trim() : String.Empty;
            }
        }
        #endregion

        /// <summary>
        /// Retrieves the connection string and writes pieces to file
        /// </summary>
        /// <param name="abc1">connection string</param>
        private static void RetrieveString(String abc1)
        {
            String s1 = null; // server
            String c1 = null; // catalog
            String t1 = null; // trusted
            String u1 = null; // user id
            String p1 = null; // password

            foreach (String x1 in abc1.Split(new char[] { ';' }))
            {
                String k1 = x1.Substring(0, x1.IndexOf('=')).ToUpper();
                String v1 = x1.Substring(x1.IndexOf('=') + 1);

                if (k1 == "SERVER")
                {
                    s1 = v1;
                }
                else if (k1 == "DATABASE" || k1 == "INITIAL CATALOG")
                {
                    c1 = v1;
                }
                else if (k1 == "TRUSTED_CONNECTION" || k1 == "INTEGRATED SECURITY")
                {
                    t1 = (v1.ToUpper() == "YES" || v1.ToUpper() == "TRUE" || v1.ToUpper() == "SSPI") ? "TRUE" : "FALSE";
                }
                else if (k1 == "USER ID")
                {
                    u1 = v1;
                }
                else if (k1 == "PASSWORD" || k1 == "PWD")
                {
                    p1 = v1;
                }
            }
            // Write the results
            using (StreamWriter w2 = new StreamWriter(_outfile, false))
            {
                w2.Write(s1 + ";" + c1 + ";" + t1 + ";" + u1 + ";" + p1);
            }
        }
    }
}
