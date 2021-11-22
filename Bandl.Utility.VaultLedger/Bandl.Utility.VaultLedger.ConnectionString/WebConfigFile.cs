using System;
using System.IO;
using System.Reflection;
using System.Collections.Generic;
using System.Text;
using System.Xml;

namespace Bandl.Utility.VaultLedger.ConnectionString
{
    internal class WebConfigFile
    {
        private String _f1 = null;

        public WebConfigFile()
        {
            String u1 = Uri.UnescapeDataString(new UriBuilder(Assembly.GetExecutingAssembly().CodeBase).Path);
            this._f1 = Path.Combine(Directory.GetParent(Path.GetDirectoryName(u1)).FullName, "Web.config");
        }

        public WebConfigFile(String f1)
        {
            this._f1 = f1;
        }

        public String GetAppSetting(String k1) // k1
        {
            try
            {
                XmlDocument x1 = new XmlDocument();
                // Load
                x1.Load(this._f1);
                // Find element
                String s1 = String.Format("/configuration/appSettings/add[translate(@key,'{0}','{1}')='{1}']", k1.ToLower(), k1.ToUpper());
                // Get attribute value
                return x1.SelectSingleNode(s1).Attributes["value"].InnerText;
            }
            catch
            {
                return String.Empty;
            }
        }

        public void SetAppSetting(String k1, String s1)  // key , value
        {
            if (File.Exists(this._f1) == false)
            {
                throw new ApplicationException("Web configuration file not found");
            }
            else
            {
                // Load document
                XmlDocument x1 = new XmlDocument();
                x1.Load(this._f1);
                // Create the new node
                XmlElement n1 = x1.CreateElement("add");
                n1.SetAttribute("key", k1);
                n1.SetAttribute("value", s1);
                // Get the k1 node
                XmlNode o1 = x1.SelectSingleNode(String.Format("/configuration/appSettings/add[@key=\"{0}\"]", k1));
                // Replace the node if it exists, otherwise append it
                if (o1 != null)
                {
                    x1.SelectSingleNode("/configuration/appSettings").ReplaceChild(n1, o1);
                }
                else
                {
                    x1.SelectSingleNode("/configuration/appSettings").AppendChild(n1);
                }
                // Get the file information
                FileInfo i1 = new FileInfo(this._f1);
                Boolean b1 = i1.IsReadOnly;
                // Alter from read-only?
                if (b1) i1.Attributes &= ~FileAttributes.ReadOnly;
                // Save the document
                x1.Save(this._f1);
                // Back to read only?
                if (b1) i1.Attributes |= FileAttributes.ReadOnly;
            }
        }
    }
}
