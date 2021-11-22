using System;
using System.IO;
using System.Reflection;
using System.Windows.Forms;

namespace Bandl.Utility.VaultLedger.DbUpdater
{
    public class SqeFile
    {
        private Int32 ma = 1;
        private Int32 mi = 0;
        private Int32 re = -1;
        private String dir = String.Empty;

        #region C O N S T R U C T O R S
        public SqeFile()
        {
            String u1 = Uri.UnescapeDataString(new UriBuilder(Assembly.GetExecutingAssembly().CodeBase).Path);
            // Look for file in current directory.  If not there, look in sqe subdirectory.
            if (File.Exists(Path.Combine(Path.GetDirectoryName(u1), "1_0_0.sqe")))
            {
                this.dir = Path.GetDirectoryName(u1);
            }
            else if (File.Exists(Path.Combine(Path.Combine(Directory.GetParent(Path.GetDirectoryName(u1)).FullName, "sqe"), "1_0_0.sqe")))
            {
                this.dir = Path.Combine(Directory.GetParent(Path.GetDirectoryName(u1)).FullName, "sqe");
            }
            else
            {
                throw new ApplicationException("Unable to locate initialization script");
            }
        }

        public SqeFile(Int32 ma, Int32 mi, Int32 re) : this()
        {
            this.ma = ma;
            this.mi = mi;
            this.re = re;
        }
        #endregion

        public String FileName()
        {
            return this.FileName(this.ma, this.mi, this.re);
        }

        private String FileName(Int32 ma, Int32 mi, Int32 re)
        {
            return Path.Combine(this.dir, String.Format("{0}_{1}_{2}.sqe", ma, mi, re));
        }

        public String GetContents()
        {
            return GetContents(FileName(ma, mi, re));
        }

        public static String GetContents(String inputfile)
        {
            using (StreamReader r1 = new StreamReader(inputfile))
                return Crypto.Decrypt(r1.ReadToEnd(), "qHXx3U3oZ8MA+qEvkQVbxA==");
        }

        public static String Encrypt(String f1)
        {
            using (StreamReader r1 = new StreamReader(f1))
                return Convert.ToBase64String(Crypto.Encrypt(r1.ReadToEnd(), "qHXx3U3oZ8MA+qEvkQVbxA=="));
        }

        public Boolean Exists()
        {
            return File.Exists(FileName());
        }

        public Boolean NextFile()
        {
            // Form the file name
            if (File.Exists(FileName(ma, mi, ++re)))
            {
                Tracer.Trace(FileName() + " FOUND AS NEXT FILE");
                return true;
            }
            else if (File.Exists(FileName(ma, ++mi, (re = 0))))
            {
                Tracer.Trace(FileName() + " FOUND AS NEXT FILE");
                return true;
            }
            else if (File.Exists(FileName(++ma, (mi = 0), (re = 0))))
            {
                Tracer.Trace(FileName() + " FOUND AS NEXT FILE");
                return true;
            }
            else
            {
                return false;
            }
        }
    }
}
