using System;
using System.Windows.Forms;
using Microsoft.Win32;
using System.Text;
using System.IO;

namespace Bandl.Utility.VaultLedger.RegistryReader
{
    class Program
    {
        private static String master = null;
        private static String outfile = null;

        static Int32 Main(string[] args)
        {
            try
            {
                ProcessCommandLine(args);
                DoRead();
                // Return
                return 0;
            }
            catch (Exception e)
            {
                MessageBox.Show(e.Message, "VaultLedger", MessageBoxButtons.OK, MessageBoxIcon.Stop);
                return -100;
            }
        }

        private static void DoRead()
        {
            // Open the VaultLedger key
            RegistryKey k1 = Registry.LocalMachine.OpenSubKey(master, false);
            // Read it, yo!
            if (k1 != null)
            {
                using (StreamWriter w1 = new StreamWriter(outfile, false))
                {
                    DoRead(k1, w1);
                }
                // Close the key
                k1.Close();
            }
        }

        private static void DoRead(RegistryKey k1, StreamWriter w1)
        {
            if (k1 == null)
            {
                return;
            }
            else
            {
                RegistryKey k2 = null;
                // Get the values for this key
                foreach (String s1 in k1.GetValueNames())
                {
                    String n1 = k1.Name.Replace(@"HKEY_LOCAL_MACHINE\", String.Empty);
                    w1.Write(String.Format("{0}<!>{1}<!>{2}<!>{3}<!!>", n1, k1.GetValueKind(s1).ToString().ToUpper(), s1, k1.GetValue(s1)));
                }
                // Read the subkeys
                foreach (String s1 in k1.GetSubKeyNames())
                {
                    try
                    {
                        k2 = k1.OpenSubKey(s1);
                        DoRead(k2, w1);
                    }
                    catch
                    {
                        k2.Close();
                    }
                }
            }
        }

        #region Command Line Processing Methods
        /// <summary>
        /// Gets the key portion of the command line switch
        /// </summary>
        private static string GetKey(string k1)
        {
            // Colon position
            int x1 = k1.IndexOf(':');
            // Get key and value
            if (x1 != -1)
            {
                return k1.Substring(0, x1).Trim();
            }
            else
            {
                return k1.Trim();
            }
        }
        /// <summary>
        /// Gets the key portion of the command line switch (empty string if none)
        /// </summary>
        private static string GetValue(string v1)
        {
            // Colon position
            int x1 = v1.IndexOf(':');
            // Need colon?
            if (x1 == -1)
            {
                throw new ApplicationException("Incorrect syntax [" + v1 + "]");
            }
            else
            {
                return x1 != -1 ? v1.Substring(x1 + 1).Trim() : String.Empty;
            }
        }
        /// <summary>
        /// Processes the command line arguments
        /// </summary>
        /// <param name="a1">
        /// Array of command line arguments
        /// </param>
        private static void ProcessCommandLine(string[] a1)
        {
            String key = null;

            try
            {
                for (int i = 0; i < a1.Length; i++)
                {
                    switch (key = GetKey(a1[i]))
                    {
                        case "/m":
                            master = GetValue(a1[i]);
                            if (master.EndsWith(@"\")) master = master.Substring(0, master.Length - 1);
                            break;
                        case "/o":
                            outfile = GetValue(a1[i]);
                            break;
                        default:
                            throw new ApplicationException("Unrecognized flag [" + key + "]");
                    }
                }
            }
            catch (Exception e)
            {
                throw new ApplicationException("Error in command line: " + e.Message);
            }
        }
        #endregion
    }
}
