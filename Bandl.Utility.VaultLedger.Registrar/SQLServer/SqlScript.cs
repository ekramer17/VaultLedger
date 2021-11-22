using System;
using System.IO;
using System.Web;
using Bandl.Utility.VaultLedger.Registrar.Model;
using Bandl.Library.VaultLedger.Common.Knock;

namespace Bandl.Utility.VaultLedger.Registrar.SQLServer
{
	/// <summary>
	/// Summary description for SqlScript.
	/// </summary>
    public class SqlScript
    {
        private int ma = 1;
        private int mi = 0;
        private int re = -1;
        private string dirName = null;
        private string v = "qHXx3U3oZ8MA+qEvkQVbxA==";

        public SqlScript() {}

        private string DirName
        {
            get
            {
                if (dirName != null) return dirName;
                char c = Path.DirectorySeparatorChar;
                string p = Configurator.BaseDirectory;
                return String.Format("{0}bin{1}", p[p.Length-1] != c ? p += c.ToString() : p, c);
            }
        }

        public string CurrentFile
        {
            get {return FileName(ma, mi, re);}
        }

        public string FirstFile
        {
            get {return FileName(1, 0, 0);}
        }

        private string FileName(int v1, int v2, int v3)
        {
            return String.Format("{0}_{1}_{2}.sqe", v1, v2, v3);
        }

        public string NextFileContent()
        {
            bool x = false;
            // Form the file name
            if (File.Exists(DirName + FileName(ma, mi, ++re)))
            {
                x = true;
            }
            else if (FileName(ma, mi, re) == FileName(1, 0, 0))
            {
                throw new ApplicationException("Table and stored procedure creation file not found");
            }
            else if (File.Exists(DirName + FileName(ma, ++mi, (re = 0))))
            {
                x = true;
            }
            else if (File.Exists(DirName + FileName(++ma, (mi = 0), (re = 0))))
            {
                x = true;
            }
            // If no file, return empty string; otherwise return the text
            if (x == false)
                return String.Empty;
            else
                using (StreamReader r = new StreamReader(DirName + FileName(ma, mi, re)))
                    return Balance.Exhume(Convert.FromBase64String(r.ReadToEnd()), Convert.FromBase64String(v));
        }
	}
}
