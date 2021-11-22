using System;
using System.IO;
using System.Xml;
using System.Text;
using Microsoft.Win32;
using System.Text.RegularExpressions;
using System.Collections.Generic;
using System.Windows.Forms;

namespace Bandl.Utility.VaultLedger.AppSettings
{
    class Program
    {
        private static String datafile = null;  // file for input or output
        private static Boolean write = false;   // read or write?
        private static String webfile = null;  // web.config file
        private static String key = null;
        private static String value = null;

        static Int32 Main(string[] args)
        {
            try
            {
                ProcessCommandLine(args);
                // File?
                if (File.Exists(webfile))
                {
                    if (key != null)
                    {
                        WriteAppSetting(webfile, key, value);
                    }
                    else if (write)
                    {
                        WriteAppSettings(webfile, datafile);
                    }
                    else
                    {
                        ReadAppSettings(webfile, datafile);
                    }
                }
                // Return
                return 0;
            }
            catch (Exception e)
            {
                MessageBox.Show(e.Message, "VaultLedger", MessageBoxButtons.OK, MessageBoxIcon.Stop);
                return -100;
            }
        }

        private static void WriteAppSetting(String webfile, String key, String value)
        {
            XmlNode n1 = null;
            // Load document
            XmlDocument x1 = new XmlDocument();
            x1.Load(webfile);
            // Create the new node
            XmlElement e1 = x1.CreateElement("add");
            e1.SetAttribute("key", key);
            e1.SetAttribute("value", value);
            // If the node already exists, replace it ... otherwise append it
            if ((n1 = x1.SelectSingleNode(String.Format("/configuration/appSettings/add[@key=\"{0}\"]", key))) != null)
            {
                n1.ParentNode.ReplaceChild(e1, n1);
            }
            else
            {
                x1.SelectSingleNode("/configuration/appSettings").AppendChild(e1);
            }
            // Save the file
            SaveFile(webfile, x1);
        }

        private static void WriteAppSettings(String webfile, String datafile)
        {
            // Dictionary to hold all keys
            Dictionary<String, String> s1 = new Dictionary<String, String>();
            Dictionary<String, String> s2 = new Dictionary<String, String>();
            // Create list of defaults
            s1.Add("Idle", "20");
            s1.Add("DBMS", "SQLServer");
            s1.Add("XmitMethod", "FTP");
            s1.Add("DbCmdTimeout", "60");
            s1.Add("ProductType", "bandl");
            s1.Add("ConnString", String.Empty);
            s1.Add("ConnVector", String.Empty);
            s1.Add("Bandl.Library.VaultLedger.Gateway.Bandl.Bandl.BandlService", "http://na1.vaultledger.com/service/vaultledger.asmx");
            // Fill other dictionary with keys and values from data file
            if (File.Exists(datafile))
            {
                using (StreamReader r1 = new StreamReader(datafile))
                {
                    String y1 = null;
                    while ((y1 = r1.ReadLine()) != null)
                    {
                        String[] y2 = Regex.Split(y1, "<!>");
                        s2.Add(y2[0], y2[1]);
                    }
                }
            }
            // Load document
            XmlDocument x1 = new XmlDocument();
            x1.Load(webfile);
            // Get the node
            XmlNode n1 = x1.SelectSingleNode("/configuration/appSettings");
            // Remove all children
            n1.RemoveAll();
            // Add all the keys (using default if nothing present)
            foreach (String k1 in s1.Keys)
            {
                XmlElement e1 = x1.CreateElement("add");
                e1.SetAttribute("key", k1);
                e1.SetAttribute("value", s2.ContainsKey(k1) ? s2[k1] : s1[k1]);
                n1.AppendChild(e1);
            }
            // Add any keys that do not exist in s1
            foreach (String k2 in s2.Keys)
            {
                if (s1.ContainsKey(k2) == false)
                {
                    XmlElement e1 = x1.CreateElement("add");
                    e1.SetAttribute("key", k2);
                    e1.SetAttribute("value", s2[k2]);
                    n1.AppendChild(e1);
                }
            }
            // Replace the node
            XmlNode o1 = x1.SelectSingleNode("/configuration/appSettings");
            o1.ParentNode.ReplaceChild(n1, o1);
            // Save the file
            SaveFile(webfile, x1);
        }

        private static void SaveFile(String f1, XmlDocument x1)
        {
            // Get the file information
            FileInfo i1 = new FileInfo(f1);
            bool b1 = i1.IsReadOnly;
            // Alter from read-only?
            if (b1) i1.Attributes &= ~FileAttributes.ReadOnly;
            // Save the document
            x1.Save(f1);
            // Back to read only?
            if (b1) i1.Attributes |= FileAttributes.ReadOnly;
        }

        private static void ReadAppSettings(String webfile, String datafile)
        {
            using (StreamWriter w1 = new StreamWriter(datafile, false))
            {
                XmlDocument x1 = new XmlDocument();
                // Load document
                x1.Load(webfile);
                // Get the node
                XmlNode n1 = x1.SelectSingleNode("/configuration/appSettings");
                // Loop through the children
                foreach (XmlNode n2 in n1.ChildNodes)
                {
                    String a1 = n2.Attributes["key"].Value;
                    String a2 = n2.Attributes["value"].Value;
                    w1.WriteLine(String.Format("{0}<!>{1}", a1, a2));
                }
            }
        }

        #region C O M M A N D   L I N E   M E T H O D S
        /// <summary>
        /// Processes the command line arguments
        /// </summary>
        /// <param name="a1">
        /// Array of command line arguments
        /// </param>
        private static void ProcessCommandLine(string[] a1)
        {
            String k1 = null;

            try
            {
                for (int i = 0; i < a1.Length; i++)
                {
                    switch (k1 = GetKey(a1[i]))
                    {
                        case "/f":
                            datafile = GetValue(a1[i]);
                            break;
                        case "/c":
                            webfile = GetValue(a1[i]);
                            break;
                        case "/w":
                            write = true;
                            break;
                        case "/k":
                            key = GetValue(a1[i]);
                            break;
                        case "/v":
                            value = GetValue(a1[i]);
                            break;
                        default:
                            throw new ApplicationException("Unrecognized flag [" + k1 + "]");
                    }
                }
            }
            catch (Exception e)
            {
                throw new ApplicationException("Error in command line: " + e.Message);
            }
        }
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
        #endregion
    }
}
