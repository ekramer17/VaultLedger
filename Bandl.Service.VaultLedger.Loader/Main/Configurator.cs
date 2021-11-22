using System;
using System.IO;
using System.Xml;
using System.Text;
using System.Reflection;
using System.Configuration;
using System.Security.Cryptography;

namespace Bandl.Service.VaultLedger.Loader
{
    public class Configurator
    {
        private static byte[] x1 = {243, 101, 150, 203, 16, 115, 22, 166, 45, 23, 157, 179, 115, 115, 254, 96, 102, 145, 194, 162, 17, 9, 165, 213, 128, 111, 208, 54, 69, 175, 105, 13};
        private static byte[] x2 = {64, 173, 200, 168, 30, 1, 107, 249, 202, 73, 79, 25, 154, 239, 137, 137};

        public static string AutoXmit
        {
            get
            {
                string s = ConfigurationManager.AppSettings["Xmit"];
                // Which?
                if (s == null || s.Length == 0)
                {
                    return String.Empty;
                }
                else if (s[0] == 'R')
                {
                    return "R";
                }
                else if (s[0] == 'S')
                {
                    return "S";
                }
                else if (s[0] == 'B')
                {
                    return "B";
                }
                else
                {
                    return String.Empty;
                }
            }
        }

        public static string BaseUrl
        {
            get
            {
                string s = ConfigurationManager.AppSettings["Url"];
                return s != null ? s.Substring(0, s.LastIndexOf('/') + 1) : String.Empty;
            }
        }

        public static string NetworkCredentials
        {
            get
            {
                return ConfigurationManager.AppSettings["NetworkCredentials"];
            }
        }

        public static string EmailServer
        {
            get
            {
                return ConfigurationManager.AppSettings["EmailServer"];
            }
        }

        public static string EmailRecipients
        {
            get
            {
                String s1 = ConfigurationManager.AppSettings["EmailRecipients"];
                return s1 == null || s1 == String.Empty ? "" : s1;
            }
        }

        public static string ProductName
        {
            get
            {
                String s1 = ConfigurationManager.AppSettings["Product"];
                return s1 == null || s1 == String.Empty ? "VaultLedger" : s1;
            }
        }

        public static string Suffix
        {
            get
            {
                string s1 = ConfigurationManager.AppSettings["Client"];
                // Empty?
                if (s1 == null || s1 == String.Empty)
                {
                    return String.Empty;
                }
                else
                {
                    return String.Format(" ({0})", s1);
                }
            }
        }

        public static string[] Ignores
        {
            get
            {
                string s = ConfigurationManager.AppSettings["Ignores"];
                if (s == null || s.Trim().Length == 0)
                    return new string[0];
                else
                    return s.Split(new char[] { ';' }, StringSplitOptions.RemoveEmptyEntries);
            }
        }

        public static string Login
        {
            get
            {
				string s1 = ConfigurationManager.AppSettings["Login"];
                return s1 != null ? s1 : String.Empty;
            }
        }

        public static string Password
        {
            get
            {
				try
				{
					string p1 = ConfigurationManager.AppSettings["Password"];
					byte[] b1 = Convert.FromBase64String(p1);
					// Create rijndael object
					RijndaelManaged r1 = new RijndaelManaged();
					r1.Key = x1;
					r1.IV = x2;
					// Get a decryptor
					ICryptoTransform e1 = r1.CreateDecryptor(r1.Key, r1.IV);
					// Decrypt the data
					MemoryStream m1 = new MemoryStream();
					CryptoStream c1 = new CryptoStream(m1, e1, CryptoStreamMode.Write);
					// Write all data to the crypto stream and flush it.
					c1.Write(b1, 0, b1.Length);
					c1.FlushFinalBlock();
					// Get string
					return Encoding.UTF8.GetString(m1.ToArray());
				}
				catch
				{
					throw new ApplicationException("Password in configuration file does not appear to be encrypted.  Please run from the command line: loader.exe /p <PASSWORD>");
				}
            }
            set
            {
                RijndaelManaged r1 = new RijndaelManaged();
                r1.Key = x1;
                r1.IV = x2;
                // Get an encryptor
                ICryptoTransform e1 = r1.CreateEncryptor(r1.Key, r1.IV);
                // Encrypt the data
                MemoryStream m1 = new MemoryStream();
                CryptoStream c1 = new CryptoStream(m1, e1, CryptoStreamMode.Write);
                // Convert the data to a byte array.
                byte[] b1 = Encoding.UTF8.GetBytes(value);
                // Write all data to the crypto stream and flush it.
                c1.Write(b1, 0, b1.Length);
                c1.FlushFinalBlock();
                // Get encrypted array of bytes.
                ModifyAppSetting("Password", Convert.ToBase64String(m1.ToArray()));
            }
        }

        private static void ModifyAppSetting(string key, string val)
        {
            XmlDocument doc = new XmlDocument();
            String n1 = Assembly.GetExecutingAssembly().GetFiles()[0].Name + ".config";
            // Load the configuration file
            doc.Load(n1);
            // Create the new node
            XmlElement newNode = doc.CreateElement("add"); 
            newNode.SetAttribute("key", key);
            newNode.SetAttribute("value", val);
            // Get the key node
            XmlNode oldNode = doc.SelectSingleNode(String.Format("/configuration/appSettings/add[@key=\"{0}\"]", key));
            // Replace the node if it exists, otherwise append it
            if (oldNode != null)
                doc.SelectSingleNode("/configuration/appSettings").ReplaceChild(newNode, oldNode);
            else
                doc.SelectSingleNode("/configuration/appSettings").AppendChild(newNode);
            // Save the document
            doc.Save(n1);
        }
    }
}
