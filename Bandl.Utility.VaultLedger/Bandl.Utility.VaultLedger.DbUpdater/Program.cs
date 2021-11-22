using System;
using System.IO;
using System.Collections.Generic;
using System.Linq;
using System.Windows.Forms;

namespace Bandl.Utility.VaultLedger.DbUpdater
{
    static class Program
    {
        private enum Modes { Normal = 0, Encrypt = 1, Create = 2, Update = 3, Connect = 4, Permissions = 5, Owner = 6, Binary = 7 }

        private static Modes Mode = Modes.Normal;
        private static String inputFile = null;
        private static String outputFile = null;
        private static String server = null;
        private static String database = null;
        private static String password = null;
        private static String login = null;
        private static Boolean quiet = false;
        private static List<String> arguments = new List<String>();

        /// <summary>
        /// The main entry point for the application.
        /// </summary>
        [STAThread]
        static Int32 Main()
        {
            Int32 x1 = 0;
            // Process the command line
            ProcessCommandLine(Environment.GetCommandLineArgs());
            // Mode?
            if (Program.Mode == Modes.Normal)
            {
                Application.EnableVisualStyles();
                Application.SetCompatibleTextRenderingDefault(false);
                Application.Run(new Form1());
            }
            else
            {
                try
                {
                    switch (Program.Mode)
                    {
                        case Modes.Encrypt:
                            Encrypt(inputFile, outputFile);
                            break;
                        case Modes.Create:
                            new SqlServer(server, "master", login, password).CreateDatabase(database);
                            break;
                        case Modes.Update:
                            Update(inputFile);
                            break;
                        case Modes.Connect:
                            new SqlServer(server, database, login, password).Connect();
                            break;
                        case Modes.Permissions:
                            x1 = CheckPermissions() ? 0 : -100;
                            break;
                        case Modes.Owner:
                            new SqlServer(server, database, login, password).CreateOwner(arguments[0], arguments[1]);
                            break;
                        case Modes.Binary:
                            GetBinary();
                            break;
                    }
                }
                catch (Exception e1)
                {
                    x1 = -100;
                    if (!quiet) MessageBox.Show(e1.Message, "VaultLedger Database Updater", MessageBoxButtons.OK, MessageBoxIcon.Stop);
                }
            }
            // Return
            return x1;
        }

        #region C O M M A N D   L I N E   M E T H O D S
        /// <summary>
        /// Processes the command line arguments and write the connection string to the web.config
        /// file in the parent directory
        /// </summary>
        /// <param name="commandLine">
        /// Array of command line arguments
        /// </param>
        private static void ProcessCommandLine(string[] a1)
        {
            String k1 = null;
            String x1 = null;

            try
            {
                for (Int32 i1 = 1; i1 < a1.Length; i1++)
                {
                    k1 = GetKey(a1[i1]);
                    // Value?
                    if (k1 != "/q") x1 = GetValue(a1[i1]);
                    // Key?
                    switch (k1 = GetKey(a1[i1]))
                    {
                        case "/q":
                            quiet = true;
                            break;
                        case "/s":
                            server = x1;
                            break;
                        case "/d":
                            database = x1;
                            break;
                        case "/u":
                            login = x1;
                            break;
                        case "/p":
                            password = x1;
                            break;
                        case "/i":
                            inputFile = x1;
                            break;
                        case "/o":
                            outputFile = x1;
                            break;
                        case "/m":
                            Program.Mode = GetMode(x1);
                            break;
                        case "/a":
                            arguments.Add(x1);
                            break;
                        case "/r":
                            Replacer.Add(x1.Split(new char[] { ';' }));
                            break;
                        default:
                            throw new ApplicationException("Unknown flag [" + k1 + "]");
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
        private static string GetKey(string arg)
        {
            // Colon position
            int x1 = arg.IndexOf(':');
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
        private static string GetValue(string arg)
        {
            // Colon position
            int x1 = arg.IndexOf(':');
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
        /// <summary>
        /// Get program mode
        /// </summary>
        /// <param name="s1"></param>
        /// <returns></returns>
        private static Modes GetMode(String s1)
        {
            switch (s1.ToUpper()[0])
            {
                case 'E':
                    return Modes.Encrypt;
                case 'N':
                    return Modes.Create;
                case 'C':
                    return Modes.Connect;
                case 'P':
                    return Modes.Permissions;
                case 'U':
                    return Modes.Update;
                case 'O':
                    return Modes.Owner;
                case 'B':
                    return Modes.Binary;
                default:
                    break;
            }
            // None -- try parsing as integer
            try
            {
                return (Modes)Enum.ToObject(typeof(Modes), Int32.Parse(s1));
            }
            catch
            {
                return Modes.Normal;
            }
        }
        #endregion

        /// <summary>
        /// Checks the database permissions for the given login
        /// </summary>
        private static bool CheckPermissions()
        {
            try
            {
                new SqlServer(server, login, password).CheckPermissions();
                return true;
            }
            catch (Exception e1)
            {
                MessageBox.Show(e1.Message, "VaultLedger Database Updater", MessageBoxButtons.OK, MessageBoxIcon.Exclamation);
                return false;
            }
        }

        /// <summary>
        /// Encrypts the input file and write to the output file
        /// </summary>
        private static void Encrypt(String f1, String o1)
        {
            string p1 = String.Empty;
            // Need an input file
            if (String.IsNullOrEmpty(f1.Trim()))
            {
                throw new ApplicationException("No input file supplied.");
            }
            else if (!File.Exists(f1 = Path.GetFullPath(f1)))
            {
                throw new ApplicationException("File '" + f1 + "' not found.");
            }
            // If no output file, construct the name
            if (o1 == null || 0 == o1.Length)
            {
                if (f1.EndsWith(".sql"))
                {
                    o1 = f1.Substring(0, f1.Length - 4) + ".sqe";
                }
                else
                {
                    o1 = f1.Substring(0, f1.LastIndexOf(@"\") + 1) + "encrypted.txt";
                }
            }
            // Write to the output file
            using (StreamWriter w1 = new StreamWriter(o1))
            {
                w1.Write(SqeFile.Encrypt(f1));
            }
            // Success
            MessageBox.Show("File '" + f1 + "' successfully encrypted as '" + o1 + "'.", "Success!");
        }

        /// <summary>
        /// Performs a quiet update on database
        /// </summary>
        private static void Update(String f1)
        {
            String q1 = null;
            // Get contents
            if (String.IsNullOrEmpty(f1))
            {
                if (quiet == false)
                {
                    throw new ApplicationException("Update mode specified but no input file given");
                }
                else
                {
                    new SqlServer(server, database, login, password).Update();
                }
            }
            else
            {
                if (f1.EndsWith(".sqe"))
                {
                    q1 = SqeFile.GetContents(f1);
                }
                else
                {
                    StreamReader r1 = new StreamReader(f1);
                    q1 = r1.ReadToEnd();
                    r1.Close();
                }
                // Perform update
                new SqlServer(server, database, login, password).Update(q1);
            }
        }

        private static void GetBinary()
        {
            using (StreamWriter w1 = new StreamWriter(outputFile))
            {
                String s1 = new SqlServer(server, "master", login, password).GetBinary();
                w1.Write(s1);
            }
        }
    }
}
