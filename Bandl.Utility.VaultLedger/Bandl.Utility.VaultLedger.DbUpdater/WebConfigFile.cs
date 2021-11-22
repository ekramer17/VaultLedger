using System;
using System.IO;
using System.Reflection;
using System.Collections.Generic;
using System.Text;
using System.Xml;

namespace Bandl.Utility.VaultLedger.DbUpdater
{
    public class WebConfigFile
    {
        private String _f1 = null;

        public WebConfigFile()
        {
            String u1 = Uri.UnescapeDataString(new UriBuilder(Assembly.GetExecutingAssembly().CodeBase).Path);
            this._f1 = Path.Combine(Directory.GetParent(Path.GetDirectoryName(u1)).FullName, "Web.config");
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
    }
}
