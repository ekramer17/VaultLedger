using System;
using System.IO;
using System.Reflection;
using System.Windows.Forms;

namespace Bandl.Service.VaultLedger.Loader
{
    public class Logger
    {
        public static string FileName
        {
            get { return "activity.log"; }
        }

        public static void Write(string message)
        {
            try
            {
                using (StreamWriter w = new StreamWriter(Path.Combine(Application.StartupPath, FileName), true))
                {
                    w.WriteLine(DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss") + " : " + message);
                }
            }
            catch
            {
                ;
            }
        }
    }

    public class Tracer
    {
        public static void Trace(string message)
        {
            try
            {
                using (StreamWriter w = new StreamWriter(Path.Combine(Application.StartupPath, "trace.log"), true))
                {
                    w.WriteLine(DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss.fff") + " : " + message);
                }
            }
            catch
            {
                ;
            }
        }

        public static void Trace(Exception e1)
        {
            Tracer.Trace(e1.Message + " :: " + e1.StackTrace);
        }
    }
}
